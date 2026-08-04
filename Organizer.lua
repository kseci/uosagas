--- Organizer.lua
--- @author Kalen
--- @version 1.0.1
--- @description
--- Handles item organization tasks:
--- - restocking requested item types from configured containers
--- - offloading excess items
--- - moving items between containers
--- 
--- CHANGELOG:
--- 1.0.1 - Introduced beta test (restock2) for nested bag support and no Settings.lua needed.
--- 1.0.0 - First release
--- 
--- Requires:
--- Logger.lua, Utils.lua, and Settings.lua (Personal file) to be imported in the script that uses this module.
--- 
--- Usage:
--- local Organizer = Import('Organizer')
--- Organizer.restock({0x0F7A, 0x0F7B}, 10) -- Restock 10 of each type from the main restock containerSerial specified in Settings.MainRestockContainerId
--- 
--- Organizer.restock({0x0F7A, 0x0F7B}, 10, 0x4422A028) -- Restock 10 of each type from a specific containerSerial
--- 
--- Organizer.restock({0x0F7A, 0x0F7B}, 10, {0x4422A028, 0x44DF8A82}) -- Restock 10 of each type from a list of containers (will open them in order). Last one should be the container to restock from.
---
--- Organizer.restock({0x0F7A, 0x0F7B}, 10, nil, 0x0000) -- Restock 10 of each type from the main restock containerSerial, but only items with hue 0x0000
---
--- Organizer.offload({0x0F7A, 0x0F7B}, 5) -- Offload all of each type, keeping 5 in backpackCount
--- 
--- Organizer.offload({0x0F7A, 0x0F7B}, 0) -- Offload all of each type, keeping 0 in backpackCount
--- 
--- Organizer.offload({0x0F7A, 0x0F7B}, 5, 0x4422A028) -- Offload all of each type, keeping 5 in backpackCount, to a specific containerSerial 
--- 
--- For different amount just call the Organizer.offload() or Organizer.restock() again with the new amount for another typeId/graphicId.

---@type UtilsModule
-- ===== BEGIN Utils =====
--- Utils.lua
--- @author Kalen
--- @version 1.0.0
--- @description
--- Contains a collection of utility functions that can be used in other scripts. 

---@class UtilsModule
---@field setTimeout fun(delay: integer, callback: fun())
---@field runTimers fun()
---@field contains fun(list: table, value: any): boolean
---@field excludeContainers fun(list: table, containerIds: integer[]): table
---@field filterByRootContainers fun(list: table, containerIds: integer[]): table
---@field filterByType fun(list: table, typeToFilterBy: string): table
---@field filterNonLayeredItems fun(list: table): table
---@field filterByContainers fun(list: table, containerIds: integer[]): table
---@field findByProperty fun(list: table, key: string, value: any): table|nil
---@field getTotalAmountOfItems fun(items: table): integer

---@type LoggerModule
-- ===== BEGIN Logger =====
--- Logger.lua
--- @author Kalen
--- @version 1.0.0
--- @description
--- Contains a collection of logging functions that can be used in other scripts.

---@type ColorsModule
-- ===== BEGIN Colors =====
--- Colors.lua
--- @author Kalen
--- @version 1.0.0
--- @description
--- Contains a collection of color constants that can be used in other scripts.

---@class ColorsModule
---@field GREY integer
---@field PURPLE integer
---@field RED integer
---@field ORANGE integer
---@field YELLOW integer
---@field GREEN integer
---@field BLUE integer

---@type ColorsModule
Colors = {
    GREY = 2,
    PURPLE = 24,
    RED = 38,
    ORANGE = 43,
    YELLOW = 54,
    GREEN = 68,
    BLUE = 88
}
Colors = Colors
-- ===== END Colors =====


---@class LoggerModule
---@field Overhead LoggerOverheadModule
---@field info fun(msg: string)
---@field warn fun(msg: string)
---@field error fun(msg: string)
---@field debug fun(msg: string)

---@class LoggerOverheadModule
---@field info fun(msg: string, color: integer|nil)
---@field warn fun(msg: string, color: integer|nil)
---@field error fun(msg: string, color: integer|nil)
---@field debug fun(msg: string, color: integer|nil)

---@type LoggerModule
local Logger = {
    info = function(msg)
        Messages.Print(msg, Colors.GREEN)
    end,
    warn = function(msg)
        Messages.Print('WARN: '..msg, Colors.YELLOW)
    end,
    error = function(msg)
        Messages.Print('ERROR: '..msg, Colors.RED)
    end,
    debug = function(msg)
        if DEBUG == true then
            Messages.Print('DEBUG: '..msg, Colors.PURPLE)
        end
    end,
    ---@type LoggerOverheadModule
    Overhead = {
    info = function(msg, color)
        if color == nil then
            color = Colors.GREEN
        end
        Messages.OverheadMobile(Player.Serial, msg, color)
    end,
    warn = function(msg, color)
        if color == nil then
            color = Colors.YELLOW
        end
        Messages.OverheadMobile(Player.Serial, msg, color)
    end,
    error = function(msg, color)
        if color == nil then
            color = Colors.RED
        end
        Messages.OverheadMobile(Player.Serial, msg, color)
    end,
    debug = function(msg, color)
        if DEBUG == true then
            if color == nil then
                color = Colors.PURPLE
            end
            Messages.OverheadMobile(Player.Serial, msg, color)
        end
    end
    }
}
Logger = Logger
-- ===== END Logger =====

---@type UtilsModule
Utils = {}

local timers = {}

local function getWallTimeSeconds()
    return os.time()
end

function Utils.setTimeout(delay, callback)
    local start = getWallTimeSeconds()
    local co = coroutine.create(function()
        while getWallTimeSeconds() - start < delay do
            coroutine.yield()
        end
        callback()
    end)
    table.insert(timers, co)
end

function Utils.runTimers()
    for i = #timers, 1, -1 do
        local co = timers[i]
        local ok, err = coroutine.resume(co)
        if coroutine.status(co) == "dead" then
            table.remove(timers, i)
        end
    end
end

function Utils.contains(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

function Utils.excludeContainers(list, containerIds)
    local filteredList = {}
    for _, item in ipairs(list) do
        local isQualified = true
        for _, containerId in ipairs(containerIds) do
            if item.Container == containerId then
                isQualified = false
            end
        end
        if isQualified then
            table.insert(filteredList, item)
        end
    end
    return filteredList
end

function Utils.filterByRootContainers(list, containerIds)
    local filteredList = {}
    for _, item in ipairs(list) do
        local isQualified = false
        for _, containerId in ipairs(containerIds) do
            if item.RootContainer == containerId then
                isQualified = true
            end
        end
        if isQualified then
            table.insert(filteredList, item)
        end
    end
    return filteredList
end

function Utils.filterByType(list, typeToFilterBy)
    local filteredList = {}
    for _, item in ipairs(list) do
        if type(item) == typeToFilterBy then
                table.insert(filteredList,item)
        end
    end
    return filteredList
end

function Utils.filterNonLayeredItems(list)
    local listWithoutLayeredItems = {}
    for _,item in ipairs(list) do
        if not item.Layer or item.Layer == 'Invalid' then
            table.insert(listWithoutLayeredItems, item)
        end
    end
    return listWithoutLayeredItems
end

function Utils.filterByContainers(list, containerIds)
    local filteredList = {}
    for _, item in ipairs(list) do
        local isQualified = false
        for _, containerId in ipairs(containerIds) do
            if item.Container == containerId then
                isQualified = true
            end
        end
        if isQualified then
            table.insert(filteredList, item)
        end
    end
    return filteredList
end

function Utils.findByProperty(list, key, value)
    for _, item in ipairs(list) do
        if item[key] == value then
            return item
        end
    end
    return nil
end

function Utils.getTotalAmountOfItems(items)
    local count = 0
    for _, item in ipairs(items) do
        if item ~= nil and item.Amount then
            count = count + item.Amount
        end
    end
    return count
end
Utils = Utils
-- ===== END Utils =====
---@type LoggerModule
Logger = Logger  -- Logger already inlined
---@type SettingsModule
-- ===== BEGIN Settings =====
---@class SettingsModule
---@field MainRestockContainerId number
---@field MainOffloadContainerId number
---@field TrashBarrel number
---@field ServerGCD number
---@field ServerLatency number
---@field IgnoredOffloadingContainers number[]

---@type SettingsModule
local Settings = {
    MainRestockContainerId = 0x4422A028,
    MainOffloadContainerId = 0x4422A028,
    TrashBarrel = 0x4AB65232,
    ServerGCD = 500,
    ServerLatency = 50,
    IgnoredOffloadingContainers = {
        0x4AB56EDD, -- Sara
        0x4AAF0490, -- Peace
        0x4B953E76 -- Diddy
    }
}
Settings = Settings
-- ===== END Settings =====

---@class NestedBag
---@field serial number
---@field path number[]

---@class RestockOptions
---@field fill? boolean -- Default: true
---@field hue? number -- Default: all hues
---@field targetBag? NestedBag -- Default: Your main backpack

---@class OrganizerModule
---@field restock fun(types: integer[], totalAmountToFill: integer, containerIdOverride: integer|integer[]|nil, hues: integer|nil)
---@field restock2 fun (types: integer|integer[], amount: integer, sources: integer|integer[]|NestedBag|NestedBag[], options: RestockOptions)
---@field offload fun(types: integer[], keepAmount: integer, containerIdOverride: integer|nil)
---@field restockItem fun(type: integer, amount: integer, containerIdOverride: integer|nil, hues: integer|nil)
---@field moveItem fun(item: table, amount: integer, containerId: integer)
---@field moveToContainer fun(item: table, containerId: integer, amount: integer|nil)

---@type OrganizerModule
---@diagnostic disable-next-line: missing-fields
local Organizer = {}

local SERVER_GCD = 500
if not SERVER_LATENCY then
    SERVER_LATENCY = 200
end

local function gcdPause()
    Pause(SERVER_GCD + SERVER_LATENCY)
end

local function isInMemory(serial)
    if serial == nil then
        Logger.warn("Organizer: isInMemory called with nil serial.")
        return false
    end
    local item = Items.FindBySerial(serial)
    return item ~= nil
end

local function getBackpackCount(graphic, hue)
    local count = 0
    if type(hue) == "number" then
        count = Items.CountType(graphic, hue)
    else
        count = Items.CountType(graphic)
    end
    return count
end

local function convertSourcesInputToNestedBagList(sources)
    local newSources = {}
    if type(sources) == "table" and sources.serial then
        Logger.debug('Organizer: Source is a nested bag with serial '..tostring(sources.serial)..'')
        table.insert(newSources, sources)
    elseif type(sources) == "table" and #sources > 0 then
        for _, source in ipairs(sources) do
            if type(source) == "table" and source.serial then
                Logger.debug('Organizer: Source is a nested bag with serial '..tostring(source.serial)..'')
                table.insert(newSources, source)
            elseif type(source) == "number" then
                table.insert(newSources, {serial = source, path = {}})
            else
                Logger.warn('Organizer: Invalid source provided. Must be a serial number or a table with a Serial field.')
            end
        end
    elseif type(sources) == "number" then
        table.insert(newSources, {serial = sources, path = {}})
    else
        Logger.warn('Organizer: Invalid sources input. Must be a number, a table of numbers, a table with Serial field or a table of such tables.')
    end

    return newSources
end

local function isTableOfNumbers(t)
    if type(t) ~= 'table' then
        return false
    end
    for _, v in pairs(t) do
        if type(v) ~= 'number' then
            return false
        end
    end
    return true
end

local function isBagInMemoryAndContainsItems(serial)
    if serial == nil then
        Logger.warn("Organizer: isBagInMemoryAndContainsItems called with nil serial.")
        return false
    end
    local item = Items.FindBySerial(serial)
    if item == nil then
        return false
    end
    local itemsInContainer = Items.FindByFilter({container=serial})
    return #itemsInContainer > 0
end

local function openAllBagsInPath(path)
    for _, serial in ipairs(path) do
        Logger.debug("Organizer: Opening bag: "..tostring(serial))
        Player.UseObject(serial)
        gcdPause()
    end
end

local function openAllContainersIfNotInMemoryOrHasZeroItems(nestedBag)
    local containerPath = {}
    for _, serial in ipairs(nestedBag.path or {}) do
        table.insert(containerPath, serial)
    end
    if nestedBag.serial then
        table.insert(containerPath, nestedBag.serial)
    else
        Logger.warn("Organizer: Aborting openAllContainersIfNotInMemoryOrHasZeroItems for type "..tostring(nestedBag.graphic)..'')
        Logger.warn("Organizer: nestedBag.serial is nil. Please provide a valid serial for the target bag.")
        return
    end

    if #containerPath == 0 then
        Logger.warn("Organizer: openAllContainersIfNotInMemoryOrHasZeroItems called with empty container path.")
        return
    end

   if not isBagInMemoryAndContainsItems(nestedBag.serial) then
        Logger.debug("Organizer: Target bag "..tostring(nestedBag.serial).." has zero items. Opening all containers in path.")
        openAllBagsInPath(containerPath)
    else
        Logger.debug("Organizer: Target bag "..tostring(nestedBag.serial).." has items. No need to open containers in path.")
    end
end


function Organizer.restock(types, totalAmountToFill, containerIdOverride, hues)
    local containerId = Settings.MainRestockContainerId
    if containerIdOverride ~= nil then
        if type(containerIdOverride) == 'table' then
            -- Last element should be the container to restock from. The rest are containers to open before.
            containerId = containerIdOverride[#containerIdOverride]
        else
            containerId = containerIdOverride
        end
    end
    -- Open all containers but the last if it's a list
    if type(containerIdOverride) == 'table' then
        for idx, id in ipairs(containerIdOverride) do
            if idx ~= #containerIdOverride then
                Player.UseObject(id)
                Pause(Settings.ServerGCD + Settings.ServerLatency)
            end
        end
    end
    Player.UseObject(containerId)
    Pause(Settings.ServerGCD + Settings.ServerLatency)
    for _, typeToRestock in ipairs(types) do
        allItemsNearbyOfType = Items.FindByFilter({graphics=typeToRestock, hues=hues})
        itemsInBackpack = Utils.filterByContainers(allItemsNearbyOfType, {Player.Backpack.Serial})
        Logger.debug('itemsInBackpack: '..tostring(#itemsInBackpack)..'')

        itemInRestockContainer = Utils.findByProperty(allItemsNearbyOfType, 'Container', containerId)
        if itemInRestockContainer ~= nil then
            local restockAmount = 0
            if itemsInBackpack ~= nil then
                Logger.debug('amountInBackpack: '..Utils.getTotalAmountOfItems(itemsInBackpack))
                restockAmount = totalAmountToFill - Utils.getTotalAmountOfItems(itemsInBackpack)
            else
                restockAmount = totalAmountToFill
            end
            if itemInRestockContainer ~= nil and restockAmount > 0 then
                Logger.debug('Restocking type: '..tostring(typeToRestock)..' with amount: '..tostring(restockAmount)..' from container: '..tostring(containerId)..'')
                Organizer.restockItem(typeToRestock, restockAmount, containerId, hues)
            end
        end
    end
end

function Organizer.restock2(types, amount, source, options)
    local targetBagPath = options and options.targetBag and options.targetBag.path or {}
    local targetBagSerial = options and options.targetBag and options.targetBag.serial or nil
    if not isTableOfNumbers(targetBagPath) then
        Logger.error("Organizer: options.targetBagPath is not a table of numbers. It should be a list of container serials (numbers) leading to the target container.")
    end
    Logger.debug('Organizer.restock: Opening containers in path: '..table.concat(targetBagPath, ', '))
    if targetBagSerial ~= nil then
        openAllContainersIfNotInMemoryOrHasZeroItems({serial = targetBagSerial, path = targetBagPath})
    end
    if type(types) == 'number' then
        types = {types}
    elseif not isTableOfNumbers(types) then
        Logger.error('Organizer.restock: types must be a number or a table of numbers.')
        return
    end
    for _, type in ipairs(types) do
        restockGraphic(type, amount, source, options)
    end
end

function Organizer.offload(types, keepAmount, containerIdOverride)
    local containerId = Settings.MainOffloadContainerId
    if containerIdOverride ~= nil then
        containerId = containerIdOverride
    end
    local typesAsOnlyNumbers = Utils.filterByType(types, 'number')
    for _, typeToOffload in ipairs(typesAsOnlyNumbers) do
        Logger.debug('Offloading typeid: '..tostring(typeToOffload))
        local amountMoved = 0
        local allItemsNearbyOfType = Items.FindByFilter({graphics={typeToOffload}})
        local allItemsNearbyOfTypeThatIsNotLayered = Utils.filterNonLayeredItems(allItemsNearbyOfType)
        -- Only keep the items in players backpack (bank is included, be warned)
        local allItemsOfTypeOnPlayerNotLayered = Utils.filterByRootContainers(allItemsNearbyOfTypeThatIsNotLayered, {Player.Serial})
        local allItemsOfTypeThatShouldBeMoved = Utils.excludeContainers(allItemsOfTypeOnPlayerNotLayered, Settings.IgnoredOffloadingContainers)
        local currentAmountOfItems = Utils.getTotalAmountOfItems(allItemsOfTypeThatShouldBeMoved)

        local OFFLOAD_AMOUNT = currentAmountOfItems - keepAmount
        while amountMoved < OFFLOAD_AMOUNT do
            for _, stackOfItemType in ipairs(allItemsOfTypeThatShouldBeMoved) do
                local amountToMove = OFFLOAD_AMOUNT - amountMoved
                local itemCountForItem = 1
                if stackOfItemType.Amount ~= nil then
                    itemCountForItem = stackOfItemType.Amount
                end
                if amountToMove >= stackOfItemType.Amount then
                    Organizer.moveItem(stackOfItemType, itemCountForItem, containerId)
                    amountMoved = amountMoved + itemCountForItem
                elseif amountToMove > 0 and amountToMove < itemCountForItem then
                    Organizer.moveItem(stackOfItemType, amountToMove, containerId)
                    amountMoved = amountMoved + amountToMove
                end
            end
        end
    end
end

function Organizer.restockItem(type, amount, containerIdOverride, hues)
    local containerId = Settings.MainRestockContainerId
    if containerIdOverride ~= nil then
        containerId = containerIdOverride
    end
    local restockCounter = 0
    local items = Items.FindByFilter({rangemin=1, graphics=type, hues=hues})
    for idx, item in ipairs(items) do
        if item ~= nil and item.Container == containerId and restockCounter < amount then
            local amountToRestock = item.Amount - restockCounter
            if item.Amount == 1 then
                amountToRestock = 1
            else
                amountToRestock = amount - restockCounter
            end
            Logger.debug('Total Amount To Restock: '..amountToRestock)
            Logger.debug('Already restocked: '..restockCounter)
            Logger.debug('Item serial: '..tostring(item.Serial))
            Logger.info('Restocking: ' .. tostring(amountToRestock) .. ', item: ' .. tostring(item.Graphic) .. ', container: ' .. tostring(containerId))
            Player.PickUp(item.Serial, amountToRestock)
            Player.DropInBackpack()
            Pause(Settings.ServerGCD + Settings.ServerLatency)
            restockCounter = restockCounter + amountToRestock
        end
    end
end

function Organizer.moveItem(item, amount, containerId)
    Logger.info('Moving item: '..tostring(item.Name)..' of amount: '..tostring(amount)..' to container: '..tostring(containerId)..'')
    Player.PickUp(item.Serial, amount)
    Player.DropInContainer(containerId)
    Pause(Settings.ServerGCD + Settings.ServerLatency)
end

function Organizer.moveToContainer(item, containerId, amount)
    Logger.info('Moving item: '..tostring(item.Name)..' of amount: '..tostring(amount or item.Amount)..' to container: '..tostring(containerId)..'')
    Player.PickUp(item.Serial, amount or item.Amount)
    Player.DropInContainer(containerId)
    Pause(Settings.ServerGCD + Settings.ServerLatency)
end


function restockGraphic(graphic, amount, sources, options)
    local amountRestocked = 0
    local shouldFill = not (options and options.fill == false) -- Default to fill if not specified
    Logger.debug('Should fill: '..tostring(shouldFill)..'')
    local targetBagSerial = options and options.targetBag and options.targetBag.serial or nil
    if targetBagSerial ~= nil and not isInMemory(targetBagSerial) then
        Logger.warn('Organizer: Cant find target bag. Check if you have the correct path and serial. Target bag serial: '..tostring(targetBagSerial)..'')
        Logger.warn('Organizer: Aborting restock for type '..tostring(graphic)..'')
        return
    end
    local hue = options and options.hue or nil
    if type(hue) ~= "number" and type(hue) ~= "nil" then
        Logger.warn('Organizer: Invalid hue provided. It should be a number or nil. Provided hue: '..tostring(hue)..'')
        Logger.warn('Organizer: Aborting restock for type '..tostring(graphic)..'')
        return
    end
    if type(hue) == "number" then
        Logger.debug('Organizer: Restocking only items of type '..tostring(graphic)..' with hue '..tostring(hue)..'')
    else
        Logger.debug('Organizer: Restocking all hues for type '..tostring(graphic)..'')
    end
    local amountInBackpack = getBackpackCount(graphic, hue)
    Logger.debug('Current amount of type '..graphic..' in backpack: '..amountInBackpack..'')
    local amountToRestock = shouldFill and (amount - amountInBackpack) or amount
    Logger.debug('Should fill: '..tostring(shouldFill)..', amount to restock: '..amount..', amount to actually restock: '..amountToRestock..'')
    Logger.debug('Source is of type: '..type(sources)..'')
    sources = convertSourcesInputToNestedBagList(sources)
    if #sources == 0 then
        Logger.debug('Organizer: No valid sources supplied')
    end
    Logger.debug("Organizer: number of sources to check: "..tostring(#sources).."")
    for _, sourceItem in pairs(sources) do
        local containerSerial = nil
        if type(sourceItem) == "table" and sourceItem.serial then
            containerSerial = sourceItem.serial
            openAllContainersIfNotInMemoryOrHasZeroItems(sourceItem)
        else
            Logger.error("Organizer: Failed to convert input to nested bag list. Invalid source item: "..tostring(sourceItem).."")
            Logger.error("Organizer: Aborting restock for type "..tostring(graphic)..'')
            return
        end
        if not containerSerial then
            Logger.error("Organizer: Invalid source item provided. Must be a serial number or a table with a 'serial' field.")
            return
        elseif not isInMemory(containerSerial) then
            Logger.error("Organizer: Bag not found in memory: "..tostring(containerSerial) ..". Please check if path is correct.")
            return
        end
        local itemsInContainer = Items.FindByFilter({graphics={graphic}, container=containerSerial, hues={hue}})
        Logger.debug('Organizer: Found '..tostring(#itemsInContainer)..' items of type '..tostring(graphic)..' in container '..tostring(containerSerial)..'')
        for _, item in ipairs(itemsInContainer) do
        local amountToPickUp = math.min(amountToRestock - amountRestocked, item.Amount)
           if amountRestocked < amountToRestock then
                if amountToPickUp <= 0 then
                    Logger.debug('No more items of type '..graphic..' to restock from container '..containerSerial..'')
                    return
                end
                Logger.info('Restocking ' .. amountToPickUp .. ' from stack ' .. item.Name ..'')
                Player.PickUp(item.Serial, amountToPickUp)
                if targetBagSerial ~= nil then
                   Player.DropInContainer(targetBagSerial)
                else
                    Player.DropInBackpack()
                end
                gcdPause()
                amountRestocked = amountRestocked + amountToPickUp
           end
        end
    end
    if amountRestocked >= amountToRestock then
        if amountToRestock <= 0 and amountRestocked == 0 then
            Logger.info('No restocking needed for type '..graphic..'. Is already at or above target amount.')
        else
            Logger.info('Restocked '..amountRestocked..' of type '..graphic..'. Target amount reached.')
        end
    else
        Logger.warn('Restocked '..amountRestocked..' of type '..graphic..'. Target amount NOT reached. Check if there are enough items in the source containers.')
    end

    Logger.Overhead.info('*** Restocking ***')
end

return Organizer