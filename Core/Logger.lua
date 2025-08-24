-- MageControl Logging System
-- Provides consistent logging and debug functionality

MC = MC or {}

-- Create Logger table first
local Logger = {
    -- Log levels
    LEVELS = {
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4
    },
    
    -- Log level names
    LEVEL_NAMES = {"DEBUG", "INFO", "WARN", "ERROR"},
    
    -- Current log level (can be configured)
    currentLevel = 2, -- INFO by default
    
    -- Enable/disable debug mode
    debugEnabled = false
}

-- Add the log function after Logger is defined
Logger.log = function(level, message, module)
    -- Early exit for debug messages when debug is disabled
    if level == Logger.LEVELS.DEBUG and not Logger.debugEnabled then
        return
    end
    
    -- Early exit if level is below current threshold
    if level < Logger.currentLevel then
        return
    end
    
    -- Optimized message formatting with minimal string operations
    local prefix = Logger.LEVEL_NAMES[level] or "UNKNOWN"
    local moduleText = module and (" [" .. module .. "]") or ""
    local fullMessage = "[MageControl] " .. prefix .. moduleText .. ": " .. tostring(message)
    
    -- Optimized color selection and output
    if level >= Logger.LEVELS.ERROR then
        DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 0.3, 0.3)
    elseif level >= Logger.LEVELS.WARN then
        DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 1.0, 0.3)
    elseif level >= Logger.LEVELS.INFO then
        DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 1.0, 1.0)
    else
        -- Debug messages - already checked above, so just output
        DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 0.7, 0.7, 1.0)
    end
end

-- Add convenience methods after Logger is defined
Logger.debug = function(message, module)
    if Logger.debugEnabled then
        Logger.log(Logger.LEVELS.DEBUG, message, module)
    end
end

Logger.info = function(message, module)
    Logger.log(Logger.LEVELS.INFO, message, module)
end

Logger.warn = function(message, module)
    Logger.log(Logger.LEVELS.WARN, message, module)
end

Logger.error = function(message, module)
    Logger.log(Logger.LEVELS.ERROR, message, module)
end

-- Optimized debug state check
Logger.isDebugEnabled = function()
    return Logger.debugEnabled
end

-- Toggle debug mode
Logger.toggleDebug = function()
    Logger.debugEnabled = not Logger.debugEnabled
    local status = Logger.debugEnabled and "enabled" or "disabled"
    Logger.info("Debug mode " .. status)
    return Logger.debugEnabled
end

-- Set log level
Logger.setLevel = function(level)
    if level >= 1 and level <= 4 then
        Logger.currentLevel = level
        Logger.info("Log level set to " .. level)
    else
        Logger.error("Invalid log level: " .. tostring(level))
    end
end

-- Export Logger to MC namespace
MC.Logger = Logger

-- Backward compatibility with existing MC.printMessage and MC.debugPrint
MC.printMessage = function(message)
    Logger.info(message)
end

MC.debugPrint = function(message)
    Logger.debug(message)
end

-- Legacy debug toggle
MC.DEBUG = false

-- Backward compatibility
MageControl = MageControl or {}
MageControl.Logger = Logger
