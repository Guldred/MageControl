-- MageControl State Manager
-- Manages all addon state including channeling, cooldowns, buffs, and combat state

MC = MC or {}
MC.Core = MC.Core or {}

-- Create the StateManager module
local StateManager = MC.createModule("StateManager", {"ConfigManager", "Logger"})

-- Initialize the state manager
StateManager.initialize = function()
    StateManager._initializeState()
    MC.Logger.debug("State Manager initialized", "StateManager")
end

-- Core addon state
StateManager.state = {
    isChanneling = false,
    channelFinishTime = 0,
    channelDurationInSeconds = 0,
    isCastingArcaneRupture = false,
    globalCooldownActive = false,
    globalCooldownStart = 0,
    lastSpellCast = "",
    lastRuptureRepeatTime = 0,
    expectedCastFinishTime = 0,
    surgeActiveTill = 0,
    lastSpellHitTime = 0,
    -- Buff caching
    buffsCache = nil,
    buffsCacheTime = 0
}

-- Current buffs and target tracking
StateManager.currentBuffs = {}
StateManager.currentTarget = ""
StateManager.debugMode = MC.DEBUG or false

-- Initialize state with default values
StateManager._initializeState = function()
    StateManager.state.isChanneling = false
    StateManager.state.channelFinishTime = 0
    StateManager.state.channelDurationInSeconds = 0
    StateManager.state.isCastingArcaneRupture = false
    StateManager.state.globalCooldownActive = false
    StateManager.state.globalCooldownStart = 0
    StateManager.state.lastSpellCast = ""
    StateManager.state.lastRuptureRepeatTime = 0
    StateManager.state.expectedCastFinishTime = 0
    StateManager.state.surgeActiveTill = 0
    StateManager.state.lastSpellHitTime = 0
    StateManager.state.buffsCache = nil
    StateManager.state.buffsCacheTime = 0
    
    StateManager.currentBuffs = {}
    StateManager.currentTarget = ""
    StateManager.debugMode = MC.DEBUG or false
end

-- Update channeling state
StateManager.updateChannelingState = function(isChanneling, finishTime, duration)
    StateManager.state.isChanneling = isChanneling or false
    StateManager.state.channelFinishTime = finishTime or 0
    StateManager.state.channelDurationInSeconds = duration or 0
    
    MC.Logger.debug("Channeling state updated: " .. tostring(isChanneling), "StateManager")
end

-- Update global cooldown state
StateManager.updateGlobalCooldownState = function(active, startTime)
    StateManager.state.globalCooldownActive = active or false
    StateManager.state.globalCooldownStart = startTime or GetTime()
    
    if active then
        MC.Logger.debug("Global cooldown started", "StateManager")
    end
end

-- Update casting state
StateManager.updateCastingState = function(spellName, expectedFinishTime)
    StateManager.state.lastSpellCast = spellName or ""
    StateManager.state.expectedCastFinishTime = expectedFinishTime or 0
    StateManager.state.isCastingArcaneRupture = (spellName == "Arcane Rupture")
    
    MC.Logger.debug("Casting state updated: " .. tostring(spellName), "StateManager")
end

-- Update Arcane Surge state
StateManager.updateSurgeState = function(activeTill)
    StateManager.state.surgeActiveTill = activeTill or 0
    
    if activeTill and activeTill > GetTime() then
        MC.Logger.debug("Arcane Surge active until: " .. activeTill, "StateManager")
    end
end

-- Update buff cache
StateManager.updateBuffCache = function(buffs)
    StateManager.state.buffsCache = buffs
    StateManager.state.buffsCacheTime = GetTime()
    StateManager.currentBuffs = buffs or {}
    
    MC.Logger.debug("Buff cache updated with " .. table.getn(StateManager.currentBuffs) .. " buffs", "StateManager")
end

-- Update target state
StateManager.updateTargetState = function(targetName)
    StateManager.currentTarget = targetName or ""
    
    if targetName and targetName ~= "" then
        MC.Logger.debug("Target updated: " .. targetName, "StateManager")
    end
end

-- Check if buff cache is valid
StateManager.isBuffCacheValid = function()
    local cacheAge = GetTime() - StateManager.state.buffsCacheTime
    local maxCacheAge = MC.ConfigManager.get("buffs.cacheMaxAge") or 0.1
    
    return StateManager.state.buffsCache and cacheAge < maxCacheAge
end

-- Get current state snapshot
StateManager.getStateSnapshot = function()
    return {
        isChanneling = StateManager.state.isChanneling,
        channelFinishTime = StateManager.state.channelFinishTime,
        channelDurationInSeconds = StateManager.state.channelDurationInSeconds,
        isCastingArcaneRupture = StateManager.state.isCastingArcaneRupture,
        globalCooldownActive = StateManager.state.globalCooldownActive,
        globalCooldownStart = StateManager.state.globalCooldownStart,
        lastSpellCast = StateManager.state.lastSpellCast,
        expectedCastFinishTime = StateManager.state.expectedCastFinishTime,
        surgeActiveTill = StateManager.state.surgeActiveTill,
        currentBuffs = StateManager.currentBuffs,
        currentTarget = StateManager.currentTarget,
        debugMode = StateManager.debugMode,
        timestamp = GetTime()
    }
end

-- Reset state (for testing or reinitialization)
StateManager.resetState = function()
    MC.Logger.info("Resetting addon state", "StateManager")
    StateManager._initializeState()
end

-- Validate state integrity
StateManager.validateState = function()
    local issues = {}
    
    if type(StateManager.state.isChanneling) ~= "boolean" then
        table.insert(issues, "isChanneling must be boolean")
    end
    
    if type(StateManager.state.globalCooldownActive) ~= "boolean" then
        table.insert(issues, "globalCooldownActive must be boolean")
    end
    
    if type(StateManager.currentBuffs) ~= "table" then
        table.insert(issues, "currentBuffs must be table")
    end
    
    if table.getn(issues) > 0 then
        MC.Logger.error("State validation failed: " .. table.concat(issues, ", "), "StateManager")
        return false, issues
    end
    
    return true, {}
end

-- Get state statistics
StateManager.getStats = function()
    local valid, issues = StateManager.validateState()
    
    return {
        stateValid = valid,
        validationIssues = issues,
        buffsCount = table.getn(StateManager.currentBuffs),
        buffCacheAge = GetTime() - StateManager.state.buffsCacheTime,
        buffCacheValid = StateManager.isBuffCacheValid(),
        isChanneling = StateManager.state.isChanneling,
        globalCooldownActive = StateManager.state.globalCooldownActive,
        currentTarget = StateManager.currentTarget,
        debugMode = StateManager.debugMode
    }
end

-- Register the module
MC.ModuleSystem.registerModule("StateManager", StateManager)

-- Backward compatibility
MC.state = StateManager.state
MC.CURRENT_BUFFS = StateManager.currentBuffs
MC.CURRENT_TARGET = StateManager.currentTarget
MC.DEBUG = StateManager.debugMode

-- Export for other modules
MC.Core.StateManager = StateManager
