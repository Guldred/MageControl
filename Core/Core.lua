MC.CURRENT_BUFFS = {}
MC.UpdateFunctions = {}

MC.OnUpdate = function()
    for _, func in ipairs(MC.UpdateFunctions) do
        if (GetTime() - func.lastUpdate >= func.interval) then
            func.f()
            func.lastUpdate = GetTime()
        end
    end
end

MC.forceUpdate = function()
    for _, func in ipairs(MC.UpdateFunctions) do
        func.f()
        func.lastUpdate = GetTime()
    end
end

MC.registerUpdateFunction = function(func, interval)
    if type(func) == "function" then
        table.insert(MC.UpdateFunctions, {
            f = func,
            lastUpdate = 0,
            interval = interval or 0.1,
        })
    else
        error("MageControl: registerUpdateFunction expects a function and an interval (optional)")
    end
end

MC.unregisterUpdateFunction = function(func)
    for i, updateFunc in ipairs(MC.UpdateFunctions) do
        if updateFunc.f == func then
            table.remove(MC.UpdateFunctions, i)
            return
        end
    end
    error("MageControl: unregisterUpdateFunction could not find the specified function")
end

MC.state = {
    isChanneling = false,
    channelFinishTime = 0,
    isCastingArcaneRupture = false,
    globalCooldownActive = false,
    globalCooldownStart = 0,
    lastSpellCast = "",
    lastRuptureRepeatTime = 0,
    expectedCastFinishTime = 0,
    -- Buff caching
    buffsCache = nil,
    buffsCacheTime = 0
}

MC.printMessage = function(text)
    DEFAULT_CHAT_FRAME:AddMessage(text, 1.0, 1.0, 0.0)
end

MC.debugPrint = function(message)
    if MC.DEBUG then
        MC.printMessage("MageControl Debug: " .. message)
    end
end

MC.CURRENT_TARGET = ""

MC.DEBUG = false

MC.initializeSettings = function()
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MC.DEFAULT_ACTIONBAR_SLOT.FIREBLAST,
            ARCANE_RUPTURE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_RUPTURE,
            ARCANE_SURGE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_SURGE
        }
        MageControlDB.haste = {
            BASE_VALUE = MC.HASTE.BASE_VALUE,
            HASTE_THRESHOLD = MC.HASTE.HASTE_THRESHOLD
        }
    end
    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER" }
    end
    if not MageControlDB.minManaForArcanePowerUse then
        MageControlDB.minManaForArcanePowerUse = 50
    end
    local timingByRank = {
        [0] = 1.5,
        [1] = 1.35,
        [2] = 1.2,
        [3] = 1.0
    }
    MC.TIMING.GCD_BUFFER_FIREBLAST = timingByRank[MC.getTalentRank(2,5)] or 1.5
    MC.debugPrint("Set Fireblast Timing to " .. tostring(MC.TIMING.GCD_BUFFER_FIREBLAST) .. " seconds")
end

MC.getArcanePowerTimeLeft = function(buffs)
    local arcanePower = MC.findBuff(buffs, MC.BUFF_INFO.ARCANE_POWER.name)
    return arcanePower and arcanePower:duration() or 0
end

MC.isSafeToCast = function(spellName, buffs, buffStates)
    local arcanePowerTimeLeft = MC.getArcanePowerTimeLeft(buffs)

    if arcanePowerTimeLeft <= 0 then
        return true
    end

    local currentManaPercent = MC.getCurrentManaPercent()
    local spellCostPercent = MC.getSpellCostPercent(spellName, buffStates)
    local procCostPercent = 0

    if string.find(spellName, "Arcane") then
        procCostPercent = MC.BUFF_INFO.ARCANE_POWER.proc_cost_percent
    end

    local projectedManaPercent = currentManaPercent - spellCostPercent - procCostPercent
    local safetyThreshold = MC.BUFF_INFO.ARCANE_POWER.death_threshold + MC.BUFF_INFO.ARCANE_POWER.safety_buffer
    if projectedManaPercent < safetyThreshold then
        MC.printMessage(string.format("|cffff0000MageControl WARNING: %s could drop mana to %.1f%% (Death at 10%%) - BLOCKED!|r",
                spellName, projectedManaPercent))
        return false
    end

    return true
end

MC.safeQueueSpell = function(spellName, buffs, buffStates)
    if not spellName or spellName == "" then
        MC.printMessage("MageControl: Invalid spell name")
        return false
    end

    -- If spell name is unknown, debug it
    if MC.getSpellCostByName(spellName) == 0 then
        MC.debugPrint("Unknown spell in safeQueueSpell: [" .. tostring(spellName) .. "]")
    end

    if not MC.isSafeToCast(spellName, buffs, buffStates) then
        MC.debugPrint("Not safe to cast: " .. spellName)
        return false
    end

    MC.debugPrint("Queueing spell: " .. spellName)
    QueueSpellByName(spellName)
    return true
end

MC.queueArcaneExplosion = function()
    local gcdRemaining = MC.GLOBAL_COOLDOWN_IN_SECONDS - (GetTime() - MC.state.globalCooldownStart)
    if(gcdRemaining < MC.TIMING.GCD_REMAINING_THRESHOLD) then
        local buffs = MC.CURRENT_BUFFS
        local buffStates = MC.getCurrentBuffs(buffs)
        MC.safeQueueSpell("Arcane Explosion", buffs, buffStates)
    end
end

MC.isArcaneRuptureOneGlobalAway = function(slot, timing)
    local cooldown = MC.getActionSlotCooldownInMilliseconds(slot)
    return (cooldown < timing and cooldown > 0)
end

MC.isArcaneRuptureOneGlobalAwayAfterCurrentCast = function(slot, timing)
    local cooldownInSeconds = MC.getActionSlotCooldownInMilliseconds(slot)
    local cooldownAfterCurrentCast = MC.calculateRemainingTimeAfterCurrentCast(cooldownInSeconds)
    return (cooldownAfterCurrentCast < timing and cooldownAfterCurrentCast > 0)
end

MC.calculateRemainingTimeAfterCurrentCast = function(time)
    local currentCastTimeRemaining = MC.state.expectedCastFinishTime - GetTime()
    if currentCastTimeRemaining < 0 then
        currentCastTimeRemaining = 0
    end
    local calculatedCooldownAfterCurrentCast = time - currentCastTimeRemaining
    if calculatedCooldownAfterCurrentCast < 0 then
        calculatedCooldownAfterCurrentCast = 0
    end
    MC.debugPrint("Cooldown right now: " .. time .. " --- Cooldown after current cast: " .. calculatedCooldownAfterCurrentCast .. " seconds")
    return calculatedCooldownAfterCurrentCast
end

MC.getSpellAvailability = function()
    local slots = MC.getActionBarSlots()
    return {
        arcaneRuptureReady = MC.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_RUPTURE, 0),
        arcaneSurgeReady = MC.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_SURGE, 0),
        fireblastReady = MC.isActionSlotCooldownReadyAndUsableInSeconds(slots.FIREBLAST, 0) and
                (IsSpellInRange(MC.SPELL_INFO.FIREBLAST.id) == 1)
    }
end

MC.shouldWaitForCast = function()
    local timeToCastFinish = MC.state.expectedCastFinishTime - GetTime()
    return timeToCastFinish > MC.TIMING.CAST_FINISH_THRESHOLD
end

MC.isInterruptionRequired = function(spells, buffStates)
    local shouldCancelWhileHighHaste = MC.isHighHasteActive()
                                        and MC.state.isChanneling and
                                        not buffStates.arcaneRupture and
                                        spells.arcaneRuptureReady
    if (shouldCancelWhileHighHaste) then
        return true
    end
    local shouldCancelWhileNoHighHaste = not MC.isHighHasteActive()
                                        and MC.state.isChanneling and
                                        buffStates.arcaneRupture and
                                        spells.arcaneRuptureReady and
                                        not MC.isActionSlotCooldownReadyAndUsableInSeconds(MC.getActionBarSlots().ARCANE_SURGE, 1)
    if (shouldCancelWhileNoHighHaste) then
        return true
    end
    return false
end

MC.handleChannelInterruption = function(spells, buffs, buffStates)
    ChannelStopCastingNextTick()
    if (spells.arcaneSurgeReady) then
        MC.safeQueueSpell("Arcane Surge", buffs, buffStates)
    else
        MC.safeQueueSpell("Arcane Rupture", buffs, buffStates)
    end
    return true
end

MC.checkManaWarning = function(buffs)
    local arcanePowerTimeLeft = MC.getArcanePowerTimeLeft(buffs)
    if arcanePowerTimeLeft > 0 then
        local currentMana = MC.getCurrentManaPercent()
        local projectedMana = currentMana - (arcanePowerTimeLeft * MC.BUFF_INFO.ARCANE_POWER.mana_drain_per_second)

        if projectedMana < 15 and projectedMana > 10 then
            MC.printMessage("|cffffff00MageControl: LOW MANA WARNING - " .. math.floor(projectedMana) .. "% projected!|r")
        end
    end
end

MC.stopChannelAndCastSurge = function()
    local spells = MC.getSpellAvailability()

    if (spells.arcaneSurgeReady) then
        ChannelStopCastingNextTick()
        QueueSpellByName("Arcane Surge")
    end
end

MC.updateCurrentTarget = function()
    MC.CURRENT_TARGET = UnitName("target") or "none"
    MC.debugPrint("New target ist: " .. MC.CURRENT_TARGET)
end