-- Initialize MageControl.RotationEngine namespace
MageControl = MageControl or {}
MageControl.RotationEngine = MageControl.RotationEngine or {}

-----------------------------
-- HELPERS
-----------------------------

local isMissilesInterruptionRequiredAfterNextMissileForSurge = function()
    -- Early exits for better performance
    if not MageControl.StateManager.current.isChanneling or MageControl.CacheUtils.isHighHasteActive() then
        return false
    end

    local earliestCancelPoint = MageControlDB.minMissilesForSurgeCancel or 4
    if not MageControl.ArcaneSpecific.isInLastPossibleMissileWindow() then
        return false
    end

    local currentTime = GetTime()
    local missileTimes = MageControl.ArcaneSpecific.ARCANE_MISSILES_FIRE_TIMES
    local missileCount = table.getn(missileTimes)
    
    -- Optimized missile index calculation using binary search
    local currentMissileIndex = 0
    local low, high = 1, missileCount
    
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if currentTime >= missileTimes[mid] then
            currentMissileIndex = mid
            low = mid + 1
        else
            high = mid - 1
        end
    end

    -- Early exit if not enough missiles fired
    if currentMissileIndex < earliestCancelPoint then
        return false
    end

    -- Use action bar slots from saved variables
    local actionBarSlots = MageControlDB.actionBarSlots
    local arcaneSurgeCooldownRemaining = MageControl.TimingCalculations.getActionSlotCooldownInSeconds(actionBarSlots.ARCANE_SURGE)

    local nextMissileIndex = currentMissileIndex + 1
    if nextMissileIndex > missileCount then
        return false -- No next missile
    end

    local nextMissileTime = missileTimes[nextMissileIndex]
    local timeToNextMissile = nextMissileTime - currentTime

    return timeToNextMissile >= arcaneSurgeCooldownRemaining
end

-- Restored original rebuff interruption logic
local isMissilesInterruptionRequiredForRuptureRebuff = function(spells, buffStates)
    -- Must be channeling missiles to interrupt
    if not MageControl.StateManager.current.isChanneling then
        return false
    end

    -- Check for high haste condition - cancel while high haste if no rupture buff and rupture is ready
    local shouldCancelWhileHighHaste = MageControl.CacheUtils.isHighHasteActive()
            and not buffStates.arcaneRupture
            and spells.arcaneRuptureReady

    -- Check for low haste condition - cancel while low haste if no rupture buff, rupture is ready,
    -- and surge is not ready soon (to avoid using rupture right before surge)
    local shouldCancelWhileLowHaste = not MageControl.CacheUtils.isHighHasteActive()
            and not buffStates.arcaneRupture
            and spells.arcaneRuptureReady
            and not MageControl.TimingCalculations.isActionSlotCooldownReadyAndUsableInSeconds(MageControlDB.actionBarSlots.ARCANE_SURGE, 1)
            -- Last check ensures we don't use Rupture right before Surge becomes available
            -- Ideally, we want to use Surge first, then rupture for maximum missile time

    return shouldCancelWhileHighHaste or shouldCancelWhileLowHaste
end

local handleMissilesInterruptionForRuptureRebuff = function(spells, buffs, buffStates)
    ChannelStopCastingNextTick()
    if spells.arcaneSurgeReady and not MageControl.CacheUtils.isHighHasteActive() then
        MageControl.SpellCasting.safeQueueSpell("Arcane Surge", buffs, buffStates)
    else
        MageControl.SpellCasting.safeQueueSpell("Arcane Rupture", buffs, buffStates)
    end
    return true
end

local handleMissilesInterruptionForSurge = function(buffs, buffStates)
    ChannelStopCastingNextTick()
    MageControl.SpellCasting.safeQueueSpell("Arcane Surge", buffs, buffStates)
    return true
end

-----------------------------
-- PERFORMANCE OPTIMIZED HELPERS
-----------------------------

-- Cache for frequently accessed values
local _actionBarSlotsCache = nil
local _lastActionBarUpdate = 0
local ACTION_BAR_CACHE_DURATION = 5 -- Cache action bar slots for 5 seconds

-- Optimized action bar slots caching
local function getCachedActionBarSlots()
    local currentTime = GetTime()
    if not _actionBarSlotsCache or (currentTime - _lastActionBarUpdate) > ACTION_BAR_CACHE_DURATION then
        _actionBarSlotsCache = MageControlDB.actionBarSlots or {}
        _lastActionBarUpdate = currentTime
    end
    return _actionBarSlotsCache
end

-----------------------------
-- MAIN PRIO LOGIC
-----------------------------

MageControl.RotationEngine.arcaneRotationPriority = {
    {
        name = "Channel Interruption for Rebuff",
        condition = function(state)
            return isMissilesInterruptionRequiredForRuptureRebuff(state.spells, state.buffStates)
        end,
        action = function(state)
            handleMissilesInterruptionForRuptureRebuff(state.spells, state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Channel Interruption for Surge at last second",
        condition = function(state)
            return isMissilesInterruptionRequiredAfterNextMissileForSurge()
        end,
        action = function(state)
            MageControl.Logger.debug("Arcane Missiles need to be interrupted to fire Surge while available", "RotationEngine")
            --TODO: This might cause empty channel interrupts if Arcane Surge not available
            handleMissilesInterruptionForSurge(state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Wait for Cast",
        condition = function(state)
            return MageControl.TimingCalculations.shouldWaitForCast()
        end,
        action = function(state)
            MageControl.Logger.debug("Ignored input since current cast is more than .75s away from finishing", "RotationEngine")
            return true
        end
    },
    {
        name = "Arcane Surge (Low Haste)",
        condition = function(state)
            return state.spells.arcaneSurgeReady and not MageControl.CacheUtils.isHighHasteActive()
        end,
        action = function(state)
            MageControl.Logger.debug("Trying to cast Arcane Surge", "RotationEngine")
            MageControl.SpellCasting.safeQueueSpell("Arcane Surge", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Clearcasting Missiles",
        condition = function(state)
            return state.buffStates.clearcasting and state.missilesWorthCasting
        end,
        action = function(state)
            MageControl.Logger.debug("Clearcasting active and Arcane Missiles worth casting", "RotationEngine")
            MageControl.SpellCasting.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture Maintenance",
        condition = function(state)
            return state.spells.arcaneRuptureReady and 
                   not state.missilesWorthCasting and 
                   not MageControl.StateManager.current.isCastingArcaneRupture
        end,
        action = function(state)
            MageControl.Logger.debug("Arcane Rupture ready and not casting", "RotationEngine")
            MageControl.SpellCasting.safeQueueSpell("Arcane Rupture", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Missiles Worth Casting",
        condition = function(state)
            return state.missilesWorthCasting
        end,
        action = function(state)
            MageControl.Logger.debug("Arcane Missiles worth casting", "RotationEngine")
            MageControl.SpellCasting.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture One GCD Away (Arcane Surge)",
        condition = function(state)
            return MageControl.TimingCalculations.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, MageControl.ConfigDefaults.values.timing.GCD_BUFFER) and
                    state.spells.arcaneSurgeReady and
                    not MageControl.CacheUtils.isHighHasteActive()
        end,
        action = function(state)
            MageControl.Logger.debug("Arcane Rupture is one GCD away, casting Arcane Surge", "RotationEngine")
            MageControl.SpellCasting.safeQueueSpell("Arcane Surge", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture One GCD Away (Fire Blast)",
        condition = function(state)
            return MageControl.TimingCalculations.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, MageControl.ConfigDefaults.values.timing.GCD_BUFFER_FIREBLAST) and
                    state.spells.fireblastReady and
                    not MageControl.CacheUtils.checkImmunity("fire") and
                    not MageControl.CacheUtils.isHighHasteActive()
        end,
        action = function(state)
            MageControl.Logger.debug("Arcane Rupture is one Fireblast GCD away, casting Fire Blast", "RotationEngine")
            MageControl.SpellCasting.safeQueueSpell("Fire Blast", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Default Missiles",
        condition = function(state)
            return true -- Always true - this is the fallback
        end,
        action = function(state)
            MageControl.Logger.debug("Defaulting to Arcane Missiles", "RotationEngine")
            MageControl.SpellCasting.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    }
}

MageControl.RotationEngine.cooldownActions = {
    TRINKET1 = {
        name = "First Trinket",
        isAvailable = function()
            local start, cooldown, enabled = GetInventoryItemCooldown("player", 13)
            return cooldown == 0 and enabled == 1
        end,
        execute = function()
            UseInventoryItem(13)
        end
    },
    TRINKET2 = {
        name = "Second Trinket",
        isAvailable = function()
            local start, cooldown, enabled = GetInventoryItemCooldown("player", 14)
            return cooldown == 0 and enabled == 1
        end,
        execute = function()
            UseInventoryItem(14)
        end
    },
    ARCANE_POWER = {
        name = "Arcane Power",
        isAvailable = function()
            local arcanePowerSlot = MageControlDB.actionBarSlots.ARCANE_POWER
            if not arcanePowerSlot or arcanePowerSlot <= 0 then
                return false
            end
            
            local start, duration = GetActionCooldown(arcanePowerSlot)
            local isCooldownReady = start == 0 or (start + duration <= GetTime())
            local hasSufficientMana = MageControlDB.minManaForArcanePowerUse <= MageControl.ManaUtils.getCurrentManaPercent()
            
            return isCooldownReady and hasSufficientMana
        end,
        execute = function()
            CastSpellByName("Arcane Power")
        end
    }
}

MageControl.RotationEngine.stopChannelAndCastSurge = function()
    local spells = MageControl.SpellCasting.getSpellAvailability()

    if (spells.arcaneSurgeReady) then
        ChannelStopCastingNextTick()
        QueueSpellByName("Arcane Surge")
    end
end

local function updateGlobalCooldownState()
    if (GetTime() - MageControl.StateManager.current.globalCooldownStart > MageControl.ConfigDefaults.values.timing.GLOBAL_COOLDOWN_IN_SECONDS) then
        MageControl.StateManager.current.globalCooldownActive = false
    end
end

local function gatherRotationState()
    local buffs = MageControl.StateManager.getBuffs()
    local spells = MageControl.SpellCasting.getSpellAvailability()
    local buffStates = MageControl.StateManager.getCurrentBuffs(buffs)
    local slots = MageControlDB.actionBarSlots
    local missilesWorthCasting = MageControl.ArcaneSpecific.isMissilesWorthCasting(buffStates)
    
    return {
        buffs = buffs,
        spells = spells,
        buffStates = buffStates,
        slots = slots,
        missilesWorthCasting = missilesWorthCasting
    }
end

MageControl.RotationEngine.executeArcaneRotation = function()
    updateGlobalCooldownState()
    
    local state = gatherRotationState()
    
    MageControl.Logger.debug("Evaluating spell priority", "RotationEngine")

    for i, priority in ipairs(MageControl.RotationEngine.arcaneRotationPriority) do
        if priority.condition(state) then
            MageControl.Logger.debug("Executing priority: " .. priority.name, "RotationEngine")
            priority.action(state)
            return
        end
    end

    MageControl.Logger.error("ERROR: No rotation priority matched!", "RotationEngine")
end

MageControl.RotationEngine.arcaneRotation = function()
    -- Check for boss encounter settings first
    local shouldUseEncounterLogic = MageControlDB.bossEncounters and 
                                   MageControlDB.bossEncounters.incantagos and 
                                   MageControlDB.bossEncounters.incantagos.enabled
    
    if shouldUseEncounterLogic then
        local targetName = UnitName("target")
        if targetName and targetName ~= "" then
            local spellToQueue = nil
            
            -- Check for Incantagos encounter spells first
            spellToQueue = MageControl.SpellData.INCANTAGOS_SPELL_MAP[targetName]
            
            -- Check for training dummy spells if enabled and no Incantagos spell found
            if not spellToQueue and MageControlDB.bossEncounters and MageControlDB.bossEncounters.enableTrainingDummies then
                spellToQueue = MageControl.SpellData.TRAINING_DUMMY_SPELL_MAP[targetName]
            end
            
            if spellToQueue then
                -- Found a boss-specific spell, use it
                local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
                local isArcaneSpell = channeling == 1 or castId == MageControl.SpellData.SPELL_INFO.ARCANE_RUPTURE.id
                
                if isArcaneSpell then
                    SpellStopCasting()
                end
                
                QueueSpellByName(spellToQueue)
                return
            end
        end
    end
    
    -- Default arcane rotation behavior
    MageControl.StateManager.current.CURRENT_BUFFS = MageControl.StateManager.getBuffs()
    MageControl.StateManager.checkManaWarning(MageControl.StateManager.current.CURRENT_BUFFS)
    MageControl.StateManager.checkChannelFinished()
    MageControl.RotationEngine.executeArcaneRotation()
end

MageControl.RotationEngine.arcaneIncantagos = function()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return
    end
    
    local spellToQueue = nil
    
    -- Check for Incantagos encounter spells first
    if MageControlDB.bossEncounters and MageControlDB.bossEncounters.incantagos and MageControlDB.bossEncounters.incantagos.enabled then
        spellToQueue = MageControl.SpellData.INCANTAGOS_SPELL_MAP[targetName]
    end
    
    -- Check for training dummy spells if enabled and no Incantagos spell found
    if not spellToQueue and MageControlDB.bossEncounters and MageControlDB.bossEncounters.enableTrainingDummies then
        spellToQueue = MageControl.SpellData.TRAINING_DUMMY_SPELL_MAP[targetName]
    end
    
    if spellToQueue then
        local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
        local isArcaneSpell = channeling == 1 or castId == MageControl.SpellData.SPELL_INFO.ARCANE_RUPTURE.id
        
        if isArcaneSpell then
            SpellStopCasting()
        end
        
        QueueSpellByName(spellToQueue)
    else
        MageControl.RotationEngine.arcaneRotation()
    end
end
