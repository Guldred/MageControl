-- MageControl Rotation Logic (Direct Access)
-- Core rotation decision logic with intuitive naming for easy navigation
-- Location: Core/RotationLogic.lua (find rotation logic here)

MageControl = MageControl or {}
MageControl.RotationLogic = {}

-- Import our direct access modules
-- These are defined in Core/WoWApi.lua and Core/ConfigData.lua for easy discovery
local WoWApi = MageControl.WoWApi
local ConfigData = MageControl.ConfigData

-- Rotation State Management
MageControl.RotationLogic.state = {
    lastExecutionTime = 0,
    executionInterval = 0.1,
    lastSpellCast = "",
    rotationActive = false,
    debugMode = false
}

-- Main Rotation Decision Logic
MageControl.RotationLogic.shouldCastArcaneRupture = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    -- Check mana threshold
    local manaPercent = (gameState.player.mana / gameState.player.maxMana) * 100
    if manaPercent < 30 then
        return false
    end
    
    -- Check if we're in combat and have a target
    if not gameState.player.inCombat or not gameState.target.exists then
        return false
    end
    
    -- Check global cooldown
    if gameState.globalCooldownActive then
        return false
    end
    
    return true
end

MageControl.RotationLogic.shouldCastArcaneSurge = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    -- Check mana threshold (higher requirement for Surge)
    local minMana = ConfigData.getMinManaForSurge()
    local manaPercent = (gameState.player.mana / gameState.player.maxMana) * 100
    
    if manaPercent < minMana then
        return false
    end
    
    -- Check if we're in combat and have a target
    if not gameState.player.inCombat or not gameState.target.exists then
        return false
    end
    
    -- Check global cooldown
    if gameState.globalCooldownActive then
        return false
    end
    
    return true
end

MageControl.RotationLogic.shouldInterruptMissiles = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    -- Only consider interruption if we're channeling missiles
    if not gameState.player.isChanneling then
        return false
    end
    
    -- Check minimum missiles requirement
    local minMissiles = ConfigData.getMinMissilesForSurgeCancel()
    
    -- Simplified missile count calculation
    local castingInfo = gameState.player.castingInfo
    if not castingInfo or not string.find(castingInfo.spell or "", "Arcane Missiles") then
        return false
    end
    
    local channelDuration = (castingInfo.endTime - castingInfo.startTime) / 1000
    local missilesFired = math.floor(channelDuration / 1.0) -- Assume 1 missile per second
    
    return missilesFired >= minMissiles
end

MageControl.RotationLogic.shouldActivateCooldowns = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    -- Check mana threshold for Arcane Power
    local minMana = ConfigData.getMinManaForArcanePower()
    local manaPercent = (gameState.player.mana / gameState.player.maxMana) * 100
    
    if manaPercent < minMana then
        return false
    end
    
    -- Only activate in combat with target
    return gameState.player.inCombat and gameState.target.exists and gameState.target.isEnemy
end

-- Game State Gathering
MageControl.RotationLogic.gatherGameState = function()
    return {
        timestamp = WoWApi.getCurrentTime(),
        player = {
            mana = WoWApi.getPlayerMana(),
            maxMana = WoWApi.getPlayerMaxMana(),
            health = WoWApi.getPlayerHealth(),
            maxHealth = WoWApi.getPlayerMaxHealth(),
            inCombat = WoWApi.isPlayerInCombat(),
            isChanneling = WoWApi.isPlayerChanneling(),
            castingInfo = WoWApi.getPlayerCastingInfo(),
            buffs = WoWApi.getPlayerBuffs()
        },
        target = {
            exists = WoWApi.hasTarget(),
            isEnemy = WoWApi.isTargetEnemy()
        },
        globalCooldownActive = false -- Simplified for now
    }
end

-- Priority System Integration
MageControl.RotationLogic.evaluateNextAction = function()
    local gameState = MageControl.RotationLogic.gatherGameState()
    
    -- Priority 1: Interrupt missiles if needed
    if MageControl.RotationLogic.shouldInterruptMissiles(gameState) then
        return { type = "interrupt", spell = "Arcane Missiles" }
    end
    
    -- Priority 2: Activate cooldowns if conditions are met
    if MageControl.RotationLogic.shouldActivateCooldowns(gameState) then
        return { type = "cooldowns" }
    end
    
    -- Priority 3: Cast Arcane Rupture for buff maintenance
    if MageControl.RotationLogic.shouldCastArcaneRupture(gameState) then
        return { type = "cast", spell = "Arcane Rupture" }
    end
    
    -- Priority 4: Cast Arcane Surge for damage
    if MageControl.RotationLogic.shouldCastArcaneSurge(gameState) then
        return { type = "cast", spell = "Arcane Surge" }
    end
    
    -- Priority 5: Default to Arcane Missiles
    if gameState.player.inCombat and gameState.target.exists then
        return { type = "cast", spell = "Arcane Missiles" }
    end
    
    return nil
end

-- Initialize the rotation logic
MageControl.RotationLogic.initialize = function()
    MageControl.RotationLogic.state.debugMode = ConfigData.isDebugEnabled()
    MageControl.Logger.debug("Rotation Logic initialized", "RotationLogic")
end

-- Backward compatibility - direct global access for easy discoverability
MC.RotationLogic = MageControl.RotationLogic
