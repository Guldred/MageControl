-- MageControl Update Manager
-- Manages update cycles, timers, and periodic function execution

MageControl = MageControl or {}
MageControl.Core = MageControl.Core or {}

-- Create the UpdateManager module
local UpdateManager = MageControl.createModule("UpdateManager", {"StateManager", "Logger"})

-- Initialize the update manager
UpdateManager.initialize = function()
    UpdateManager.updateFunctions = {}
    UpdateManager.isRunning = false
    MageControl.Logger.debug("Update Manager initialized", "UpdateManager")
end

-- Registered update functions
UpdateManager.updateFunctions = {}
UpdateManager.isRunning = false

-- Main update loop - called by WoW's OnUpdate
UpdateManager.onUpdate = function()
    if not UpdateManager.isRunning then
        return
    end
    
    local currentTime = GetTime()
    
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc and (currentTime - updateFunc.lastUpdate >= updateFunc.interval) then
            local success, error = MageControl.ErrorHandler.safeCall(
                updateFunc.f,
                MageControl.ErrorHandler.TYPES.UPDATE,
                {module = "UpdateManager", functionName = updateFunc.name or "unknown"}
            )
            
            if success then
                updateFunc.lastUpdate = currentTime
            else
                MageControl.Logger.error("Update function failed: " .. tostring(error), "UpdateManager")
            end
        end
    end
end

-- Force update all registered functions
UpdateManager.forceUpdate = function()
    MageControl.Logger.debug("Forcing update of all registered functions", "UpdateManager")
    
    local currentTime = GetTime()
    
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc then
            local success, error = MageControl.ErrorHandler.safeCall(
                updateFunc.f,
                MageControl.ErrorHandler.TYPES.UPDATE,
                {module = "UpdateManager", functionName = updateFunc.name or "unknown"}
            )
            
            if success then
                updateFunc.lastUpdate = currentTime
                MageControl.Logger.debug("Force updated: " .. (updateFunc.name or "unknown"), "UpdateManager")
            else
                MageControl.Logger.error("Force update failed for " .. (updateFunc.name or "unknown") .. ": " .. tostring(error), "UpdateManager")
            end
        end
    end
end

-- Register a function to be called periodically
UpdateManager.registerUpdateFunction = function(func, interval, name)
    if type(func) ~= "function" then
        MageControl.Logger.error("registerUpdateFunction expects a function", "UpdateManager")
        return false
    end
    
    local updateEntry = {
        f = func,
        lastUpdate = 0,
        interval = interval or 0.1,
        name = name or "unnamed_function",
        registeredAt = GetTime()
    }
    
    table.insert(UpdateManager.updateFunctions, updateEntry)
    
    MageControl.Logger.debug("Registered update function: " .. updateEntry.name .. " (interval: " .. updateEntry.interval .. "s)", "UpdateManager")
    return true
end

-- Unregister an update function
UpdateManager.unregisterUpdateFunction = function(func)
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc and updateFunc.f == func then
            local name = updateFunc.name or "unknown"
            table.remove(UpdateManager.updateFunctions, i)
            MageControl.Logger.debug("Unregistered update function: " .. name, "UpdateManager")
            return true
        end
    end
    
    MageControl.Logger.warn("Could not find function to unregister", "UpdateManager")
    return false
end

-- Unregister update function by name
UpdateManager.unregisterUpdateFunctionByName = function(name)
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc and updateFunc.name == name then
            table.remove(UpdateManager.updateFunctions, i)
            MageControl.Logger.debug("Unregistered update function by name: " .. name, "UpdateManager")
            return true
        end
    end
    
    MageControl.Logger.warn("Could not find function with name: " .. name, "UpdateManager")
    return false
end

-- Start the update system
UpdateManager.start = function()
    UpdateManager.isRunning = true
    MageControl.Logger.info("Update system started", "UpdateManager")
end

-- Stop the update system
UpdateManager.stop = function()
    UpdateManager.isRunning = false
    MageControl.Logger.info("Update system stopped", "UpdateManager")
end

-- Pause/resume update system
UpdateManager.pause = function()
    UpdateManager.isRunning = false
    MageControl.Logger.debug("Update system paused", "UpdateManager")
end

UpdateManager.resume = function()
    UpdateManager.isRunning = true
    MageControl.Logger.debug("Update system resumed", "UpdateManager")
end

-- Clear all registered update functions
UpdateManager.clearAllUpdateFunctions = function()
    local count = table.getn(UpdateManager.updateFunctions)
    UpdateManager.updateFunctions = {}
    MageControl.Logger.info("Cleared " .. count .. " update functions", "UpdateManager")
end

-- Get update function information
UpdateManager.getUpdateFunctionInfo = function(name)
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc and updateFunc.name == name then
            return {
                name = updateFunc.name,
                interval = updateFunc.interval,
                lastUpdate = updateFunc.lastUpdate,
                registeredAt = updateFunc.registeredAt,
                timeSinceLastUpdate = GetTime() - updateFunc.lastUpdate,
                index = i
            }
        end
    end
    
    return nil
end

-- Update function interval
UpdateManager.setUpdateFunctionInterval = function(name, newInterval)
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc and updateFunc.name == name then
            local oldInterval = updateFunc.interval
            updateFunc.interval = newInterval or 0.1
            MageControl.Logger.debug("Updated interval for " .. name .. ": " .. oldInterval .. "s -> " .. updateFunc.interval .. "s", "UpdateManager")
            return true
        end
    end
    
    MageControl.Logger.warn("Could not find function to update interval: " .. name, "UpdateManager")
    return false
end

-- Get update system statistics
UpdateManager.getStats = function()
    local totalFunctions = table.getn(UpdateManager.updateFunctions)
    local currentTime = GetTime()
    local overdueFunctions = 0
    local averageInterval = 0
    
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc then
            averageInterval = averageInterval + updateFunc.interval
            
            if (currentTime - updateFunc.lastUpdate) > (updateFunc.interval * 2) then
                overdueFunctions = overdueFunctions + 1
            end
        end
    end
    
    if totalFunctions > 0 then
        averageInterval = averageInterval / totalFunctions
    end
    
    return {
        isRunning = UpdateManager.isRunning,
        totalFunctions = totalFunctions,
        overdueFunctions = overdueFunctions,
        averageInterval = averageInterval,
        functions = UpdateManager._getFunctionList()
    }
end

-- Get list of registered functions (for debugging)
UpdateManager._getFunctionList = function()
    local functions = {}
    local currentTime = GetTime()
    
    for i, updateFunc in ipairs(UpdateManager.updateFunctions) do
        if updateFunc then
            table.insert(functions, {
                name = updateFunc.name,
                interval = updateFunc.interval,
                timeSinceLastUpdate = currentTime - updateFunc.lastUpdate,
                overdue = (currentTime - updateFunc.lastUpdate) > (updateFunc.interval * 2)
            })
        end
    end
    
    return functions
end

-- Register the module
MageControl.ModuleSystem.registerModule("UpdateManager", UpdateManager)

-- Backward compatibility
MC.UpdateFunctions = UpdateManager.updateFunctions
MC.OnUpdate = function()
    UpdateManager.onUpdate()
end
MC.forceUpdate = function()
    UpdateManager.forceUpdate()
end
MC.registerUpdateFunction = function(func, interval)
    return UpdateManager.registerUpdateFunction(func, interval, "legacy_function")
end
MC.unregisterUpdateFunction = function(func)
    return UpdateManager.unregisterUpdateFunction(func)
end

-- Export for other modules
MageControl.Core.UpdateManager = UpdateManager
