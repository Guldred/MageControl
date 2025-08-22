-- MageControl Logging System
-- Provides consistent logging and debug functionality

MageControl = MageControl or {}

MageControl.Logger = {
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
    debugEnabled = false,
    
    -- Performance optimized logging with reduced overhead
    log = function(level, message, module)
        -- Early exit for debug messages when debug is disabled
        if level == MageControl.Logger.LEVELS.DEBUG and not MageControl.Logger.debugEnabled then
            return
        end
        
        -- Early exit if level is below current threshold
        if level < MageControl.Logger.currentLevel then
            return
        end
        
        -- Optimized message formatting with minimal string operations
        local prefix = MageControl.Logger.LEVEL_NAMES[level] or "UNKNOWN"
        local moduleText = module and (" [" .. module .. "]") or ""
        local fullMessage = "[MageControl] " .. prefix .. moduleText .. ": " .. tostring(message)
        
        -- Optimized color selection and output
        if level >= MageControl.Logger.LEVELS.ERROR then
            DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 0.3, 0.3)
        elseif level >= MageControl.Logger.LEVELS.WARN then
            DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 1.0, 0.3)
        elseif level >= MageControl.Logger.LEVELS.INFO then
            DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 1.0, 1.0)
        else
            -- Debug messages - already checked above, so just output
            DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 0.7, 0.7, 1.0)
        end
    end,
    
    -- Optimized convenience methods with early exits
    debug = function(message, module)
        if MageControl.Logger.debugEnabled then
            MageControl.Logger.log(MageControl.Logger.LEVELS.DEBUG, message, module)
        end
    end,
    
    info = function(message, module)
        MageControl.Logger.log(MageControl.Logger.LEVELS.INFO, message, module)
    end,
    
    warn = function(message, module)
        MageControl.Logger.log(MageControl.Logger.LEVELS.WARN, message, module)
    end,
    
    error = function(message, module)
        MageControl.Logger.log(MageControl.Logger.LEVELS.ERROR, message, module)
    end,
    
    -- Optimized debug state check
    isDebugEnabled = function()
        return MageControl.Logger.debugEnabled
    end,
    
    -- Toggle debug mode
    toggleDebug = function()
        MageControl.Logger.debugEnabled = not MageControl.Logger.debugEnabled
        local status = MageControl.Logger.debugEnabled and "enabled" or "disabled"
        MageControl.Logger.info("Debug mode " .. status)
        return MageControl.Logger.debugEnabled
    end,
    
    -- Set log level
    setLevel = function(level)
        if level >= 1 and level <= 4 then
            MageControl.Logger.currentLevel = level
            MageControl.Logger.info("Log level set to " .. level)
        else
            MageControl.Logger.error("Invalid log level: " .. tostring(level))
        end
    end
}

-- Backward compatibility with existing MC.printMessage and MC.debugPrint
MC.printMessage = function(message)
    MageControl.Logger.info(message)
end

MC.debugPrint = function(message)
    MageControl.Logger.debug(message)
end

-- Legacy debug toggle
MC.DEBUG = false
