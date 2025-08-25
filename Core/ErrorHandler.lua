-- MageControl Error Handling System
-- Provides consistent error handling and recovery

-- MageControl Error Handler - Unified Namespace
-- All MC.* references converted to MageControl.* expert modules
MageControl = MageControl or {}

local ErrorHandler = {
    -- Error types
    TYPES = {
        CONFIG = "CONFIG",
        MODULE = "MODULE", 
        SPELL = "SPELL",
        UI = "UI",
        UNKNOWN = "UNKNOWN"
    },
    
    -- Error history for debugging
    errorHistory = {},
    maxHistorySize = 50,
    
    -- Handle an error with context
    handle = function(errorType, message, context, canRecover)
        local timestamp = GetTime()
        local errorInfo = {
            type = errorType or ErrorHandler.TYPES.UNKNOWN,
            message = message or "Unknown error",
            context = context or {},
            timestamp = timestamp,
            canRecover = canRecover or false
        }
        
        -- Add to error history
        table.insert(ErrorHandler.errorHistory, errorInfo)
        if table.getn(ErrorHandler.errorHistory) > ErrorHandler.maxHistorySize then
            table.remove(ErrorHandler.errorHistory, 1)
        end
        
        -- Log the error
        local contextStr = ""
        if context and context.module then
            contextStr = " [" .. context.module .. "]"
        end
        
        MageControl.Logger.error(errorType .. ": " .. message .. contextStr, "ErrorHandler")
        
        -- Attempt recovery if possible
        if canRecover and context and context.recoveryAction then
            MageControl.Logger.info("Attempting error recovery...", "ErrorHandler")
            local success, recoveryError = pcall(context.recoveryAction)
            if success then
                MageControl.Logger.info("Error recovery successful", "ErrorHandler")
            else
                MageControl.Logger.error("Error recovery failed: " .. tostring(recoveryError), "ErrorHandler")
            end
        end
        
        return errorInfo
    end,
    
    -- Safe function call wrapper
    safeCall = function(func, errorType, context, arg1, arg2, arg3, arg4, arg5)
        if type(func) ~= "function" then
            ErrorHandler.handle(
                errorType or ErrorHandler.TYPES.UNKNOWN,
                "Attempted to call non-function",
                context
            )
            return false, nil
        end
        
        local success, result = pcall(func, arg1, arg2, arg3, arg4, arg5)
        if not success then
            ErrorHandler.handle(
                errorType or ErrorHandler.TYPES.UNKNOWN,
                "Function call failed: " .. tostring(result),
                context
            )
            return false, result
        end
        
        return true, result
    end,
    
    -- Validate function parameters
    validateParams = function(params, expectedTypes, functionName)
        if not params or not expectedTypes then
            return false, "Missing parameters or type definitions"
        end
        
        for i, expectedType in ipairs(expectedTypes) do
            local param = params[i]
            local actualType = type(param)
            
            if expectedType ~= "any" and actualType ~= expectedType then
                local error = string.format(
                    "Parameter %d in %s: expected %s, got %s",
                    i,
                    functionName or "unknown function",
                    expectedType,
                    actualType
                )
                return false, error
            end
        end
        
        return true, nil
    end,
    
    -- Get error history
    getErrorHistory = function(errorType)
        if not errorType then
            return ErrorHandler.errorHistory
        end
        
        local filtered = {}
        for _, error in ipairs(ErrorHandler.errorHistory) do
            if error.type == errorType then
                table.insert(filtered, error)
            end
        end
        return filtered
    end,
    
    -- Clear error history
    clearHistory = function()
        ErrorHandler.errorHistory = {}
        MageControl.Logger.info("Error history cleared", "ErrorHandler")
    end,
    
    -- Check if there are recent errors of a specific type
    hasRecentErrors = function(errorType, timeWindow)
        local currentTime = GetTime()
        timeWindow = timeWindow or 30 -- Default 30 seconds
        
        for _, error in ipairs(ErrorHandler.errorHistory) do
            if (not errorType or error.type == errorType) and 
               (currentTime - error.timestamp) <= timeWindow then
                return true
            end
        end
        return false
    end
}

-- Export ErrorHandler to MC namespace
MageControl.ErrorHandler = ErrorHandler

-- Convenience functions for different error types
ErrorHandler.handleConfigError = function(message, context)
    return ErrorHandler.handle(ErrorHandler.TYPES.CONFIG, message, context)
end

ErrorHandler.handleModuleError = function(message, context)
    return ErrorHandler.handle(ErrorHandler.TYPES.MODULE, message, context)
end

ErrorHandler.handleSpellError = function(message, context)
    return ErrorHandler.handle(ErrorHandler.TYPES.SPELL, message, context)
end

ErrorHandler.handleUIError = function(message, context)
    return ErrorHandler.handle(ErrorHandler.TYPES.UI, message, context)
end

-- Backward compatibility
MageControl = MageControl or {}
MageControl.ErrorHandler = ErrorHandler
