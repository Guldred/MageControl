-----------------------------
-- HELPERS
-----------------------------

local isMissilesInterruptionRequiredAfterNextMissileForSurge = function()
    -- Early exits for better performance
    if not MC.state.isChanneling or MC.isHighHasteActive() then
        return false
    end

    local earliestCancelPoint = MageControlDB.minMissilesForSurgeCancel or 4
    if not MC.isInLastPossibleMissileWindow() then
        return false
    end

    local currentTime = GetTime()
    local missileTimes = MC.ARCANE_MISSILES_FIRE_TIMES
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

    -- Use action bar slots from ConfigManager
    local actionBarSlots = MC.getActionBarSlots()
    local arcaneSurgeCooldownRemaining = MC.getActionSlotCooldownInSeconds(actionBarSlots.ARCANE_SURGE)

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
    if not MC.state.isChanneling then
        return false
    end

    -- Check for high haste condition - cancel while high haste if no rupture buff and rupture is ready
    local shouldCancelWhileHighHaste = MC.isHighHasteActive()
            and not buffStates.arcaneRupture
            and spells.arcaneRuptureReady

    -- Check for low haste condition - cancel while low haste if no rupture buff, rupture is ready,
    -- and surge is not ready soon (to avoid using rupture right before surge)
    local shouldCancelWhileLowHaste = not MC.isHighHasteActive()
            and not buffStates.arcaneRupture
            and spells.arcaneRuptureReady
            and not MC.isActionSlotCooldownReadyAndUsableInSeconds(MC.getActionBarSlots().ARCANE_SURGE, 1)
            -- Last check ensures we don't use Rupture right before Surge becomes available
            -- Ideally, we want to use Surge first, then rupture for maximum missile time

    return shouldCancelWhileHighHaste or shouldCancelWhileLowHaste
end

local handleMissilesInterruptionForRuptureRebuff = function(spells, buffs, buffStates)
    ChannelStopCastingNextTick()
    if spells.arcaneSurgeReady and not MC.isHighHasteActive() then
        MC.safeQueueSpell("Arcane Surge", buffs, buffStates)
    else
        MC.safeQueueSpell("Arcane Rupture", buffs, buffStates)
    end
    return true
end

local handleMissilesInterruptionForSurge = function(buffs, buffStates)
    ChannelStopCastingNextTick()
    MC.safeQueueSpell("Arcane Surge", buffs, buffStates)
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

MC.arcaneRotationPriority = {
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
            MC.debugPrint("Arcane Missiles need to be interrupted to fire Surge while available")
            --TODO: This might cause empty channel interrupts if Arcane Surge not available
            handleMissilesInterruptionForSurge(state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Wait for Cast",
        condition = function(state)
            return MC.shouldWaitForCast()
        end,
        action = function(state)
            MC.debugPrint("Ignored input since current cast is more than .75s away from finishing")
            return true
        end
    },
    {
        name = "Arcane Surge (Low Haste)",
        condition = function(state)
            return state.spells.arcaneSurgeReady and not MC.isHighHasteActive()
        end,
        action = function(state)
            MC.debugPrint("Trying to cast Arcane Surge")
            MC.safeQueueSpell("Arcane Surge", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Clearcasting Missiles",
        condition = function(state)
            return state.buffStates.clearcasting and state.missilesWorthCasting
        end,
        action = function(state)
            MC.debugPrint("Clearcasting active and Arcane Missiles worth casting")
            MC.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture Maintenance",
        condition = function(state)
            return state.spells.arcaneRuptureReady and 
                   not state.missilesWorthCasting and 
                   not MC.state.isCastingArcaneRupture
        end,
        action = function(state)
            MC.debugPrint("Arcane Rupture ready and not casting")
            MC.safeQueueSpell("Arcane Rupture", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Missiles Worth Casting",
        condition = function(state)
            return state.missilesWorthCasting
        end,
        action = function(state)
            MC.debugPrint("Arcane Missiles worth casting")
            MC.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture One GCD Away (Arcane Surge)",
        condition = function(state)
            return MC.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, MC.TIMING.GCD_BUFFER) and
                    state.spells.arcaneSurgeReady and
                    not MC.isHighHasteActive()
        end,
        action = function(state)
            MC.debugPrint("Arcane Rupture is one GCD away, casting Arcane Surge")
            MC.safeQueueSpell("Arcane Surge", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture One GCD Away (Fire Blast)",
        condition = function(state)
            return MC.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, MC.TIMING.GCD_BUFFER_FIREBLAST) and
                    state.spells.fireblastReady and
                    not MC.checkImmunity("fire") and
                    not MC.isHighHasteActive()
        end,
        action = function(state)
            MC.debugPrint("Arcane Rupture is one Fireblast GCD away, casting Fire Blast")
            MC.safeQueueSpell("Fire Blast", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Default Missiles",
        condition = function(state)
            return true -- Always true - this is the fallback
        end,
        action = function(state)
            MC.debugPrint("Defaulting to Arcane Missiles")
            MC.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    }
}

MC.cooldownActions = {
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
            local hasSufficientMana = MageControlDB.minManaForArcanePowerUse <= MC.getCurrentManaPercent()
            
            return isCooldownReady and hasSufficientMana
        end,
        execute = function()
            CastSpellByName("Arcane Power")
        end
    }
}

MC.stopChannelAndCastSurge = function()
    local spells = MC.getSpellAvailability()

    if (spells.arcaneSurgeReady) then
        ChannelStopCastingNextTick()
        QueueSpellByName("Arcane Surge")
    end
end

local function updateGlobalCooldownState()
    if (GetTime() - MC.state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        MC.state.globalCooldownActive = false
    end
end

local function gatherRotationState()
    local buffs = MC.getBuffs()
    local spells = MC.getSpellAvailability()
    local buffStates = MC.getCurrentBuffs(buffs)
    local slots = MC.getActionBarSlots()
    local missilesWorthCasting = MC.isMissilesWorthCasting(buffStates)
    
    return {
        buffs = buffs,
        spells = spells,
        buffStates = buffStates,
        slots = slots,
        missilesWorthCasting = missilesWorthCasting
    }
end

MC.executeArcaneRotation = function()
    updateGlobalCooldownState()
    
    local state = gatherRotationState()
    
    MC.debugPrint("Evaluating spell priority")

    for i, priority in ipairs(MC.arcaneRotationPriority) do
        if priority.condition(state) then
            MC.debugPrint("Executing priority: " .. priority.name)
            priority.action(state)
            return
        end
    end

    MC.debugPrint("ERROR: No rotation priority matched!")
end

MC.arcaneRotation = function()
    -- Check for boss encounter settings first
    local shouldUseEncounterLogic = MageControlDB.bossEncounters and 
                                   MageControlDB.bossEncounters.incantagos and 
                                   MageControlDB.bossEncounters.incantagos.enabled
    
    if shouldUseEncounterLogic then
        local targetName = UnitName("target")
        if targetName and targetName ~= "" then
            local spellToQueue = nil
            
            -- Check for Incantagos encounter spells first
            spellToQueue = MC.INCANTAGOS_SPELL_MAP[targetName]
            
            -- Check for training dummy spells if enabled and no Incantagos spell found
            if not spellToQueue and MageControlDB.bossEncounters and MageControlDB.bossEncounters.enableTrainingDummies then
                spellToQueue = MC.TRAINING_DUMMY_SPELL_MAP[targetName]
            end
            
            if spellToQueue then
                -- Found a boss-specific spell, use it
                local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
                local isArcaneSpell = channeling == 1 or castId == MC.SPELL_INFO.ARCANE_RUPTURE.id
                
                if isArcaneSpell then
                    SpellStopCasting()
                end
                
                QueueSpellByName(spellToQueue)
                return
            end
        end
    end
    
    -- Default arcane rotation behavior
    MC.CURRENT_BUFFS = MC.getBuffs()
    MC.checkManaWarning(MC.CURRENT_BUFFS)
    MC.checkChannelFinished()
    MC.executeArcaneRotation()
end

MC.arcaneIncantagos = function()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return
    end
    
    local spellToQueue = nil
    
    -- Check for Incantagos encounter spells first
    if MageControlDB.bossEncounters and MageControlDB.bossEncounters.incantagos and MageControlDB.bossEncounters.incantagos.enabled then
        spellToQueue = MC.INCANTAGOS_SPELL_MAP[targetName]
    end
    
    -- Check for training dummy spells if enabled and no Incantagos spell found
    if not spellToQueue and MageControlDB.bossEncounters and MageControlDB.bossEncounters.enableTrainingDummies then
        spellToQueue = MC.TRAINING_DUMMY_SPELL_MAP[targetName]
    end
    
    if spellToQueue then
        local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
        local isArcaneSpell = channeling == 1 or castId == MC.SPELL_INFO.ARCANE_RUPTURE.id
        
        if isArcaneSpell then
            SpellStopCasting()
        end
        
        QueueSpellByName(spellToQueue)
    else
        MC.arcaneRotation()
    end
end
