-- MageControl State Manager (Direct Access)
-- Manages all addon state including channeling, cooldowns, buffs, and combat state
-- Location: Core/StateManager.lua (find state management here)

MageControl = MageControl or {}
MageControl.StateManager = {}

-- Initialize the state manager
MageControl.StateManager.initialize = function()
    MageControl.StateManager._initializeState()
    MageControl.Logger.debug("State Manager initialized", "StateManager")
end

-- Core addon state
MageControl.StateManager.state = {
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
MageControl.StateManager.currentBuffs = {}
MageControl.StateManager.currentTarget = ""
MageControl.StateManager.debugMode = false -- Debug mode controlled by MageControl.Logger

-- Initialize state with default values
MageControl.StateManager._initializeState = function()
    MageControl.StateManager.state.isChanneling = false
    MageControl.StateManager.state.channelFinishTime = 0
    MageControl.StateManager.state.channelDurationInSeconds = 0
    MageControl.StateManager.state.isCastingArcaneRupture = false
    MageControl.StateManager.state.globalCooldownActive = false
    MageControl.StateManager.state.globalCooldownStart = 0
    MageControl.StateManager.state.lastSpellCast = ""
    MageControl.StateManager.state.lastRuptureRepeatTime = 0
    MageControl.StateManager.state.expectedCastFinishTime = 0
    MageControl.StateManager.state.surgeActiveTill = 0
    MageControl.StateManager.state.lastSpellHitTime = 0
    MageControl.StateManager.state.buffsCache = nil
    MageControl.StateManager.state.buffsCacheTime = 0
    
    MageControl.StateManager.currentBuffs = {}
    MageControl.StateManager.currentTarget = ""
    MageControl.StateManager.debugMode = false -- Debug mode controlled by MageControl.Logger
end

-- Update channeling state
MageControl.StateManager.updateChannelingState = function(isChanneling, finishTime, duration)
    MageControl.StateManager.state.isChanneling = isChanneling or false
    MageControl.StateManager.state.channelFinishTime = finishTime or 0
    MageControl.StateManager.state.channelDurationInSeconds = duration or 0
    
    MageControl.Logger.debug("Channeling state updated: " .. tostring(isChanneling), "StateManager")
end

-- Update global cooldown state
MageControl.StateManager.updateGlobalCooldownState = function(active, startTime)
    MageControl.StateManager.state.globalCooldownActive = active or false
    MageControl.StateManager.state.globalCooldownStart = startTime or GetTime()
    
    if active then
        MageControl.Logger.debug("Global cooldown started", "StateManager")
    end
end

-- Update casting state
MageControl.StateManager.updateCastingState = function(spellName, expectedFinishTime)
    MageControl.StateManager.state.lastSpellCast = spellName or ""
    MageControl.StateManager.state.expectedCastFinishTime = expectedFinishTime or 0
    MageControl.StateManager.state.isCastingArcaneRupture = (spellName == "Arcane Rupture")
    
    MageControl.Logger.debug("Casting state updated: " .. tostring(spellName), "StateManager")
end

-- Update Arcane Surge state
MageControl.StateManager.updateSurgeState = function(activeTill)
    MageControl.StateManager.state.surgeActiveTill = activeTill or 0
    
    if activeTill and activeTill > GetTime() then
        MageControl.Logger.debug("Arcane Surge active until: " .. activeTill, "StateManager")
    end
end

-- Update buff cache
MageControl.StateManager.updateBuffCache = function(buffs)
    MageControl.StateManager.state.buffsCache = buffs
    MageControl.StateManager.state.buffsCacheTime = GetTime()
    MageControl.StateManager.currentBuffs = buffs or {}
    
    MageControl.Logger.debug("Buff cache updated with " .. table.getn(MageControl.StateManager.currentBuffs) .. " buffs", "StateManager")
end

-- Update target state
MageControl.StateManager.updateTargetState = function(targetName)
    MageControl.StateManager.currentTarget = targetName or ""
    
    if targetName and targetName ~= "" then
        MageControl.Logger.debug("Target updated: " .. targetName, "StateManager")
    end
end

-- Check if buff cache is valid
MageControl.StateManager.isBuffCacheValid = function()
    local cacheAge = GetTime() - MageControl.StateManager.state.buffsCacheTime
    local maxCacheAge = MageControl.ConfigValidation.get("buffs.cacheMaxAge") or 0.1
    
    return MageControl.StateManager.state.buffsCache and cacheAge < maxCacheAge
end

-- Get current state snapshot
MageControl.StateManager.getStateSnapshot = function()
    return {
        isChanneling = MageControl.StateManager.state.isChanneling,
        channelFinishTime = MageControl.StateManager.state.channelFinishTime,
        channelDurationInSeconds = MageControl.StateManager.state.channelDurationInSeconds,
        isCastingArcaneRupture = MageControl.StateManager.state.isCastingArcaneRupture,
        globalCooldownActive = MageControl.StateManager.state.globalCooldownActive,
        globalCooldownStart = MageControl.StateManager.state.globalCooldownStart,
        lastSpellCast = MageControl.StateManager.state.lastSpellCast,
        expectedCastFinishTime = MageControl.StateManager.state.expectedCastFinishTime,
        surgeActiveTill = MageControl.StateManager.state.surgeActiveTill,
        currentBuffs = MageControl.StateManager.currentBuffs,
        currentTarget = MageControl.StateManager.currentTarget,
        debugMode = MageControl.StateManager.debugMode,
        timestamp = GetTime()
    }
end

-- Reset state (for testing or reinitialization)
MageControl.StateManager.resetState = function()
    MageControl.Logger.info("Resetting addon state", "StateManager")
    MageControl.StateManager._initializeState()
end

-- Validate state integrity
MageControl.StateManager.validateState = function()
    local issues = {}
    
    if type(MageControl.StateManager.state.isChanneling) ~= "boolean" then
        table.insert(issues, "isChanneling must be boolean")
    end
    
    if type(MageControl.StateManager.state.globalCooldownActive) ~= "boolean" then
        table.insert(issues, "globalCooldownActive must be boolean")
    end
    
    if type(MageControl.StateManager.currentBuffs) ~= "table" then
        table.insert(issues, "currentBuffs must be table")
    end
    
    if table.getn(issues) > 0 then
        MageControl.Logger.error("State validation failed: " .. table.concat(issues, ", "), "StateManager")
        return false, issues
    end
    
    return true, {}
end

-- Update current target information
MageControl.StateManager.updateCurrentTarget = function()
    local targetExists = UnitExists("target")
    local targetName = targetExists and UnitName("target") or nil
    local targetHealth = targetExists and UnitHealth("target") or 0
    local targetMaxHealth = targetExists and UnitHealthMax("target") or 1
    
    MageControl.StateManager.currentTarget = {
        exists = targetExists,
        name = targetName,
        health = targetHealth,
        maxHealth = targetMaxHealth,
        healthPercent = targetMaxHealth > 0 and (targetHealth / targetMaxHealth) * 100 or 0
    }
    
    MageControl.Logger.debug("Target updated: " .. (targetName or "No Target") .. 
        (targetExists and (" (" .. MageControl.StateManager.currentTarget.healthPercent .. "% HP)") or ""), "StateManager")
end

-- Get state statistics
MageControl.StateManager.getStats = function()
    local valid, issues = MageControl.StateManager.validateState()
    
    return {
        stateValid = valid,
        validationIssues = issues,
        buffsCount = table.getn(MageControl.StateManager.currentBuffs),
        buffCacheAge = GetTime() - MageControl.StateManager.state.buffsCacheTime,
        buffCacheValid = MageControl.StateManager.isBuffCacheValid(),
        isChanneling = MageControl.StateManager.state.isChanneling,
        globalCooldownActive = MageControl.StateManager.state.globalCooldownActive,
        currentTarget = MageControl.StateManager.currentTarget,
        debugMode = MageControl.StateManager.debugMode
    }
end

-- Register the module
MageControl.ModuleSystem.registerModule("MageControl.StateManager", MageControl.StateManager)

-- StateManager converted to MageControl.StateManager unified system
-- All MC.* references converted to MageControl.* expert modules
