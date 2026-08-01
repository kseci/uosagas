--- Organizer.lua
--- @author Kalen
--- @version 1.0.0
--- @description
--- Handles item organization tasks:
--- - restocking requested item types from configured containers
--- - offloading excess items
--- - moving items between containers
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
Utils = Import('Utils')
---@type LoggerModule
Logger = Import('Logger')
---@type SettingsModule
Settings = Import('Settings')


---@class OrganizerModule
---@field restock fun(types: integer[], totalAmountToFill: integer, containerIdOverride: integer|integer[]|nil, hues: integer|nil)
---@field offload fun(types: integer[], keepAmount: integer, containerIdOverride: integer|nil)
---@field restockItem fun(type: integer, amount: integer, containerIdOverride: integer|nil, hues: integer|nil)
---@field moveItem fun(item: table, amount: integer, containerId: integer)
---@field moveToContainer fun(item: table, containerId: integer, amount: integer|nil)

---@type OrganizerModule
local Organizer = {
    restock = function(types, totalAmountToFill, containerIdOverride, hues)
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
    end,

    offload = function(types, keepAmount, containerIdOverride)
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
    end,

    restockItem = function(type, amount, containerIdOverride, hues)
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
    end,

    moveItem = function(item, amount, containerId)
        Logger.info('Moving item: '..tostring(item.Name)..' of amount: '..tostring(amount)..' to container: '..tostring(containerId)..'')
        Player.PickUp(item.Serial, amount)
        Player.DropInContainer(containerId)
        Pause(Settings.ServerGCD + Settings.ServerLatency)
    end,

    moveToContainer = function(item, containerId, amount)
        Logger.info('Moving item: '..tostring(item.Name)..' of amount: '..tostring(amount or item.Amount)..' to container: '..tostring(containerId)..'')
        Player.PickUp(item.Serial, amount or item.Amount)
        Player.DropInContainer(containerId)
        Pause(Settings.ServerGCD + Settings.ServerLatency)
    end
}

return Organizer