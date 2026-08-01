--- Logger.lua
--- @author Kalen
--- @version 1.0.0
--- @description
--- Contains a collection of logging functions that can be used in other scripts.

---@type ColorsModule
Colors = Import('Colors')


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

return Logger