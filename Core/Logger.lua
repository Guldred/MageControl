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
    
    -- Current log level (can be configured)
    currentLevel = 2, -- INFO by default
    
    -- Enable/disable debug mode
    debugEnabled = false,
    
    -- Log message with level
    log = function(level, message, module)
        if level < MageControl.Logger.currentLevel then
            return
        end
        
        local levelNames = {"DEBUG", "INFO", "WARN", "ERROR"}
        local levelName = levelNames[level] or "UNKNOWN"
        local modulePrefix = module and ("[" .. module .. "] ") or ""
        local timestamp = date("%H:%M:%S")
        
        local fullMessage = "[" .. timestamp .. "] [MageControl:" .. levelName .. "] " .. modulePrefix .. message
        
        -- Output to appropriate channel based on level
        if level >= MageControl.Logger.LEVELS.ERROR then
            -- Errors always show
            DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 0.3, 0.3)
        elseif level >= MageControl.Logger.LEVELS.WARN then
            -- Warnings show in yellow
            DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 1.0, 0.3)
        elseif level >= MageControl.Logger.LEVELS.INFO then
            -- Info messages in white
            DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 1.0, 1.0, 1.0)
        else
            -- Debug messages only if debug is enabled
            if MageControl.Logger.debugEnabled then
                DEFAULT_CHAT_FRAME:AddMessage(fullMessage, 0.7, 0.7, 1.0)
            end
        end
    end,
    
    -- Convenience methods
    debug = function(message, module)
        MageControl.Logger.log(MageControl.Logger.LEVELS.DEBUG, message, module)
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
