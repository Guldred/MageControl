-- MageControl Arcane-Specific Actions (Direct Access)
-- Expert on Arcane Explosion GCD timing, Arcane Missiles logic, and Arcane-specific mechanics
-- Location: Core/Actions/ArcaneSpecific.lua (find Arcane spell logic here)

MageControl = MageControl or {}
MageControl.ArcaneSpecific = {}

-- Track last Arcane Explosion cast time for proper GCD timing
local lastArcaneExplosionCastTime = 0
local ARCANE_EXPLOSION_GCD = 1.5 -- GCD duration for Arcane Explosion
local ARCANE_EXPLOSION_QUEUE_THRESHOLD = 0.75 -- Can queue when this much time remains on GCD

-- Queue Arcane Explosion with GCD check
MageControl.ArcaneSpecific.queueArcaneExplosion = function()
    local stateManager = MageControl.StateManager
    if not stateManager then
        MageControl.Logger.error("StateManager not found", "ArcaneSpecific")
        return false
    end
    
    local currentTime = GetTime()
    local timeSinceLastCast = currentTime - lastArcaneExplosionCastTime
    local gcdRemaining = ARCANE_EXPLOSION_GCD - timeSinceLastCast
    
    MageControl.Logger.debug(string.format(
        "Arcane Explosion queue attempt: currentTime=%.3f, lastCastTime=%.3f, timeSince=%.3f, gcdRemaining=%.3f, threshold=%.3f",
        currentTime, lastArcaneExplosionCastTime, timeSinceLastCast, gcdRemaining, ARCANE_EXPLOSION_QUEUE_THRESHOLD
    ), "ArcaneSpecific")
    
    if timeSinceLastCast < ARCANE_EXPLOSION_GCD - ARCANE_EXPLOSION_QUEUE_THRESHOLD then
        MageControl.Logger.debug(string.format(
            "Arcane Explosion blocked: GCD remaining %.3fs > threshold %.3fs", 
            gcdRemaining, ARCANE_EXPLOSION_QUEUE_THRESHOLD
        ), "ArcaneSpecific")
        return false
    end
    
    local buffs = stateManager.currentBuffs
    local buffStates = MageControl.StateManager.getCurrentBuffs(buffs)
    if MageControl.SpellCasting.safeQueueSpell("Arcane Explosion", buffs, buffStates) then
        lastArcaneExplosionCastTime = currentTime
        MageControl.Logger.debug(string.format(
            "Arcane Explosion queued successfully at time %.3f", 
            currentTime
        ), "ArcaneSpecific")
        return true
    end
    
    MageControl.Logger.debug("Arcane Explosion failed to queue (safeQueueSpell returned false)", "ArcaneSpecific")
    return false
end

-- Reset Arcane Explosion timing (for testing or manual resets)
MageControl.ArcaneSpecific.resetArcaneExplosionTiming = function()
    lastArcaneExplosionCastTime = 0
    MageControl.Logger.debug("Arcane Explosion timing reset", "ArcaneSpecific")
end

-- Get Arcane Explosion timing information
MageControl.ArcaneSpecific.getArcaneExplosionTimingInfo = function()
    local currentTime = GetTime()
    local timeSinceLastCast = currentTime - lastArcaneExplosionCastTime
    local gcdRemaining = ARCANE_EXPLOSION_GCD - timeSinceLastCast
    
    return {
        currentTime = currentTime,
        lastCastTime = lastArcaneExplosionCastTime,
        timeSinceLastCast = timeSinceLastCast,
        gcdRemaining = gcdRemaining,
        canQueue = timeSinceLastCast >= (ARCANE_EXPLOSION_GCD - ARCANE_EXPLOSION_QUEUE_THRESHOLD)
    }
end

-- Initialize Arcane-specific settings and configurations
MageControl.ArcaneSpecific.initializeSettings = function()
    -- Initialize action bar slots if not set
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MageControl.ConfigManager.get("actionBarSlots.FIREBLAST"),
            ARCANE_RUPTURE = MageControl.ConfigManager.get("actionBarSlots.ARCANE_RUPTURE"),
            ARCANE_SURGE = MageControl.ConfigManager.get("actionBarSlots.ARCANE_SURGE")
        }
    end
    
    -- Initialize haste settings for Arcane spells
    if not MageControlDB.haste then
        MageControlDB.haste = {
            BASE_VALUE = MageControl.ConfigManager.get("haste.BASE_VALUE"),
            HASTE_THRESHOLD = MageControl.ConfigManager.get("haste.HASTE_THRESHOLD")
        }
    end
    
    -- Initialize cooldown priority for Arcane Power
    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER" }
    end
    
    -- Initialize mana threshold for Arcane Power
    if not MageControlDB.minManaForArcanePowerUse then
        MageControlDB.minManaForArcanePowerUse = 50
    end
    
    -- Set Fireblast timing based on talent rank (affects Arcane rotation)
    local timingByRank = {
        [0] = 1.5,
        [1] = 1.35,
        [2] = 1.2,
        [3] = 1.0
    }
    local fireblastTiming = timingByRank[MageControl.CacheUtils.getTalentRank(2,5)] or 1.5
    MageControl.ConfigManager.set("timing.GCD_BUFFER_FIREBLAST", fireblastTiming)
    MageControl.Logger.debug("Set Fireblast Timing to " .. tostring(fireblastTiming) .. " seconds", "ArcaneSpecific")
end

-- Get Arcane-specific statistics
MageControl.ArcaneSpecific.getStats = function()
    local timingInfo = MageControl.ArcaneSpecific.getArcaneExplosionTimingInfo()
    
    return {
        arcaneExplosionTiming = timingInfo,
        settingsInitialized = (MageControlDB.actionBarSlots ~= nil),
        fireblastTiming = MageControl.ConfigManager.get("timing.GCD_BUFFER_FIREBLAST"),
        minManaForAP = MageControlDB.minManaForArcanePowerUse,
        cooldownPriorityCount = table.getn(MageControlDB.cooldownPriorityMap or {})
    }
end

-- Initialize Arcane-specific system
MageControl.ArcaneSpecific.initialize = function()
    MageControl.ArcaneSpecific.initializeSettings()
    MageControl.Logger.debug("Arcane-Specific system initialized", "ArcaneSpecific")
end

-- ArcaneSpecific converted to MageControl.ArcaneSpecific unified system
-- All MC.* references converted to MageControl.* expert modules
