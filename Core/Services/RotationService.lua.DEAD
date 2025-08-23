-- MageControl Rotation Business Service
-- Pure business logic for rotation decisions, separated from WoW API and data concerns

MageControl = MageControl or {}
MageControl.Services = MageControl.Services or {}

-- Rotation Service Interface
local IRotationService = {
    -- Main rotation logic
    executeRotation = function() end,
    evaluateSpellPriority = function(gameState) end,
    shouldCastSpell = function(spellName, gameState) end,
    
    -- Rotation state management
    updateRotationState = function() end,
    getRotationState = function() end,
    resetRotationState = function() end,
    
    -- Spell evaluation
    canCastArcaneRupture = function(gameState) end,
    canCastArcaneSurge = function(gameState) end,
    canCastFireBlast = function(gameState) end,
    shouldCancelMissiles = function(gameState) end,
    
    -- Cooldown management
    shouldActivateTrinkets = function(gameState) end,
    shouldActivateArcanePower = function(gameState) end,
    getPriorityAction = function(gameState) end
}

-- Rotation Service Implementation
local RotationService = {}

-- Dependencies (injected)
RotationService._wowApi = nil
RotationService._dataRepo = nil
RotationService._events = nil

-- Rotation state
RotationService._state = {
    lastExecutionTime = 0,
    executionInterval = 0.1,
    currentBuffs = {},
    lastSpellCast = nil,
    rotationActive = false
}

-- Initialize the service with dependencies
RotationService.initialize = function()
    RotationService._wowApi = MageControl.Services.Registry.get("WoWApiService")
    RotationService._dataRepo = MageControl.Services.Registry.get("DataRepository")
    RotationService._events = MageControl.Services.Registry.get("EventService")
    
    if not RotationService._wowApi or not RotationService._dataRepo or not RotationService._events then
        MageControl.Logger.error("Failed to initialize RotationService - missing dependencies", "RotationService")
        return false
    end
    
    -- Subscribe to relevant events
    RotationService._events.subscribe(RotationService._events.EVENTS.SPELL_CAST_SUCCESS, RotationService._onSpellCastSuccess, 10)
    RotationService._events.subscribe(RotationService._events.EVENTS.PLAYER_COMBAT_ENTERED, RotationService._onCombatEntered, 10)
    RotationService._events.subscribe(RotationService._events.EVENTS.PLAYER_COMBAT_LEFT, RotationService._onCombatLeft, 10)
    
    MageControl.Logger.debug("Rotation Service initialized", "RotationService")
    return true
end

-- Main rotation execution
RotationService.executeRotation = function()
    -- Throttle execution
    local currentTime = RotationService._wowApi.getCurrentTime()
    if currentTime - RotationService._state.lastExecutionTime < RotationService._state.executionInterval then
        return false
    end
    RotationService._state.lastExecutionTime = currentTime
    
    -- Gather current game state
    local gameState = RotationService._gatherGameState()
    
    -- Evaluate spell priority and execute
    local action = RotationService.evaluateSpellPriority(gameState)
    if action then
        local success = RotationService._executeAction(action, gameState)
        if success then
            RotationService._events.publish(RotationService._events.EVENTS.ROTATION_ACTION_TAKEN, {
                action = action,
                gameState = gameState,
                timestamp = currentTime
            })
        end
        return success
    end
    
    return false
end

-- Evaluate spell priority based on game state
RotationService.evaluateSpellPriority = function(gameState)
    if not gameState then
        return nil
    end
    
    -- Check if we're in a valid state to cast
    if not RotationService._canCastAnything(gameState) then
        return nil
    end
    
    -- Priority 1: Cancel missiles if needed
    if RotationService.shouldCancelMissiles(gameState) then
        return { type = "cancel", spell = "Arcane Missiles" }
    end
    
    -- Priority 2: Arcane Rupture maintenance
    if RotationService.canCastArcaneRupture(gameState) and RotationService._needsArcaneRupture(gameState) then
        return { type = "cast", spell = "Arcane Rupture", slot = RotationService._dataRepo.getActionBarSlots().ARCANE_RUPTURE }
    end
    
    -- Priority 3: Arcane Surge for damage
    if RotationService.canCastArcaneSurge(gameState) and RotationService._shouldCastArcaneSurge(gameState) then
        return { type = "cast", spell = "Arcane Surge", slot = RotationService._dataRepo.getActionBarSlots().ARCANE_SURGE }
    end
    
    -- Priority 4: Fire Blast for instant damage
    if RotationService.canCastFireBlast(gameState) and RotationService._shouldCastFireBlast(gameState) then
        return { type = "cast", spell = "Fire Blast", slot = RotationService._dataRepo.getActionBarSlots().FIREBLAST }
    end
    
    -- Priority 5: Arcane Missiles for sustained damage
    if RotationService._shouldCastArcaneMissiles(gameState) then
        return { type = "cast", spell = "Arcane Missiles" }
    end
    
    return nil
end

-- Spell evaluation methods
RotationService.canCastArcaneRupture = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    local slot = RotationService._dataRepo.getActionBarSlots().ARCANE_RUPTURE
    if not slot or not RotationService._wowApi.hasAction(slot) then
        return false
    end
    
    -- Check cooldown
    local start, duration = RotationService._wowApi.getActionCooldown(slot)
    if start > 0 and duration > 0 then
        return false
    end
    
    -- Check mana cost (estimated)
    if gameState.player.mana < 200 then
        return false
    end
    
    -- Check global cooldown
    if gameState.globalCooldownActive then
        return false
    end
    
    return true
end

RotationService.canCastArcaneSurge = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    local slot = RotationService._dataRepo.getActionBarSlots().ARCANE_SURGE
    if not slot or not RotationService._wowApi.hasAction(slot) then
        return false
    end
    
    -- Check cooldown
    local start, duration = RotationService._wowApi.getActionCooldown(slot)
    if start > 0 and duration > 0 then
        return false
    end
    
    -- Check mana cost (estimated)
    if gameState.player.mana < 300 then
        return false
    end
    
    -- Check global cooldown
    if gameState.globalCooldownActive then
        return false
    end
    
    return true
end

RotationService.canCastFireBlast = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    local slot = RotationService._dataRepo.getActionBarSlots().FIREBLAST
    if not slot or not RotationService._wowApi.hasAction(slot) then
        return false
    end
    
    -- Check cooldown
    local start, duration = RotationService._wowApi.getActionCooldown(slot)
    if start > 0 and duration > 0 then
        return false
    end
    
    -- Check mana cost (estimated)
    if gameState.player.mana < 150 then
        return false
    end
    
    -- Check global cooldown
    if gameState.globalCooldownActive then
        return false
    end
    
    return true
end

RotationService.shouldCancelMissiles = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    -- Only cancel if we're channeling missiles
    if not gameState.player.isChanneling or not gameState.player.castingInfo or 
       not string.find(gameState.player.castingInfo.spell or "", "Arcane Missiles") then
        return false
    end
    
    local minMissiles = RotationService._dataRepo.getMinMissilesForCancel()
    
    -- Calculate missiles fired (simplified logic)
    local channelDuration = (gameState.player.castingInfo.endTime - gameState.player.castingInfo.startTime) / 1000
    local missilesFired = math.floor(channelDuration / 1.0) -- Assume 1 missile per second
    
    return missilesFired >= minMissiles
end

-- Cooldown management
RotationService.shouldActivateTrinkets = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    -- Only activate in combat
    if not gameState.player.inCombat then
        return false
    end
    
    -- Check if we have a target
    if not gameState.target or not gameState.target.exists then
        return false
    end
    
    return true
end

RotationService.shouldActivateArcanePower = function(gameState)
    if not gameState or not gameState.player then
        return false
    end
    
    -- Check mana threshold
    local minMana = RotationService._dataRepo.getMinManaForArcanePower()
    local manaPercent = (gameState.player.mana / gameState.player.maxMana) * 100
    
    if manaPercent < minMana then
        return false
    end
    
    -- Only activate in combat
    if not gameState.player.inCombat then
        return false
    end
    
    -- Check if we have a target
    if not gameState.target or not gameState.target.exists then
        return false
    end
    
    return true
end

RotationService.getPriorityAction = function(gameState)
    local priorityList = RotationService._dataRepo.getTrinketPriority()
    
    for i, item in ipairs(priorityList) do
        if item.type == "trinket" then
            if RotationService._isTrinketAvailable(item.slot, gameState) then
                return { type = "trinket", slot = item.slot, name = item.name }
            end
        elseif item.type == "spell" and item.spellName == "Arcane Power" then
            if RotationService.shouldActivateArcanePower(gameState) then
                return { type = "spell", spell = "Arcane Power", name = item.name }
            end
        end
    end
    
    return nil
end

-- Helper methods
RotationService._gatherGameState = function()
    local wowApi = RotationService._wowApi
    
    return {
        timestamp = wowApi.getCurrentTime(),
        player = {
            mana = wowApi.getPlayerMana(),
            maxMana = wowApi.getPlayerMaxMana(),
            health = wowApi.getPlayerHealth(),
            maxHealth = wowApi.getPlayerMaxHealth(),
            inCombat = wowApi.isPlayerInCombat(),
            isChanneling = wowApi.isPlayerChanneling(),
            castingInfo = wowApi.getPlayerCastingInfo(),
            buffs = wowApi.getPlayerBuffs()
        },
        target = {
            exists = wowApi.hasTarget(),
            health = wowApi.getTargetHealth(),
            isEnemy = wowApi.isTargetEnemy()
        },
        globalCooldownActive = wowApi.isGlobalCooldownActive()
    }
end

RotationService._canCastAnything = function(gameState)
    return gameState.player.inCombat and 
           gameState.target.exists and 
           gameState.target.isEnemy and
           not gameState.globalCooldownActive
end

RotationService._needsArcaneRupture = function(gameState)
    -- Check if Arcane Rupture buff is missing or about to expire
    -- This is simplified - would need buff tracking in practice
    return true
end

RotationService._shouldCastArcaneSurge = function(gameState)
    -- Cast Arcane Surge when we have high mana and target health > 30%
    local manaPercent = (gameState.player.mana / gameState.player.maxMana) * 100
    return manaPercent > 60 and gameState.target.health > 1000
end

RotationService._shouldCastFireBlast = function(gameState)
    -- Use Fire Blast for instant damage when other spells are on cooldown
    return gameState.target.health > 0
end

RotationService._shouldCastArcaneMissiles = function(gameState)
    -- Cast Arcane Missiles as filler spell
    local manaPercent = (gameState.player.mana / gameState.player.maxMana) * 100
    return manaPercent > 30
end

RotationService._isTrinketAvailable = function(slot, gameState)
    local start, duration = RotationService._wowApi.getInventoryItemCooldown(slot)
    return start == 0 or duration == 0
end

RotationService._executeAction = function(action, gameState)
    if not action then
        return false
    end
    
    local success = false
    
    if action.type == "cast" then
        if action.slot then
            success = RotationService._wowApi.useAction(action.slot)
        else
            success = RotationService._wowApi.castSpellByName(action.spell)
        end
    elseif action.type == "trinket" then
        success = RotationService._wowApi.useInventoryItem(action.slot)
    elseif action.type == "cancel" then
        SpellStopCasting() -- Direct WoW API call for canceling
        success = true
    end
    
    if success then
        RotationService._state.lastSpellCast = action.spell
        MageControl.Logger.debug("Executed action: " .. (action.spell or action.type), "RotationService")
    end
    
    return success
end

-- Event handlers
RotationService._onSpellCastSuccess = function(eventData)
    if eventData and eventData.spell then
        RotationService._state.lastSpellCast = eventData.spell
    end
end

RotationService._onCombatEntered = function(eventData)
    RotationService._state.rotationActive = true
    MageControl.Logger.debug("Rotation activated - combat started", "RotationService")
end

RotationService._onCombatLeft = function(eventData)
    RotationService._state.rotationActive = false
    MageControl.Logger.debug("Rotation deactivated - combat ended", "RotationService")
end

-- State management
RotationService.getRotationState = function()
    return RotationService._state
end

RotationService.resetRotationState = function()
    RotationService._state.lastSpellCast = nil
    RotationService._state.currentBuffs = {}
    MageControl.Logger.debug("Rotation state reset", "RotationService")
end

-- Register the service interface and implementation
MageControl.Services.Registry.registerInterface("IRotationService", IRotationService)
MageControl.Services.Registry.register("RotationService", RotationService)

-- Export for direct access
MageControl.Services.Rotation = RotationService
