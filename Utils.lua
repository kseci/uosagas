
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
Logger = Import('Logger')

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



return Utils