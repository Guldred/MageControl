-- MageControl Spell Casting (Direct Access)
-- Expert on spell safety checks, queuing, and casting validation
-- Location: Core/Actions/SpellCasting.lua (find spell casting logic here)

MageControl = MageControl or {}
MageControl.SpellCasting = {}

-- Check if it's safe to cast a spell (mana safety checks)
MageControl.SpellCasting.isSafeToCast = function(spellName, buffs, buffStates)
    local arcanePowerTimeLeft = MageControl.StateManager.getArcanePowerTimeLeft(buffs)

    if arcanePowerTimeLeft <= 0 then
        return true
    end

    local currentManaPercent = MageControl.ManaUtils.getCurrentManaPercent()
    local spellCostPercent = MageControl.ManaUtils.getSpellCostPercent(spellName, buffStates)
    local procCostPercent = 0

    if string.find(spellName, "Arcane") then
        procCostPercent = MageControl.BuffData.BUFF_INFO.ARCANE_POWER.proc_cost_percent
    end

    local projectedManaPercent = currentManaPercent - spellCostPercent - procCostPercent
    local safetyThreshold = MageControl.BuffData.BUFF_INFO.ARCANE_POWER.death_threshold + MageControl.BuffData.BUFF_INFO.ARCANE_POWER.safety_buffer
    
    if projectedManaPercent < safetyThreshold then
        MageControl.Logger.warn(string.format("Spell %s could drop mana to %.1f%% (Death at 10%%) - BLOCKED!", 
                spellName, projectedManaPercent), "SpellCasting")
        MageControl.Logger.info(string.format("|cffff0000MageControl WARNING: %s could drop mana to %.1f%% (Death at 10%%) - BLOCKED!|r",
                spellName, projectedManaPercent))
        return false
    end

    return true
end

-- Safely queue a spell with all safety checks
MageControl.SpellCasting.safeQueueSpell = function(spellName, buffs, buffStates)
    if not spellName or spellName == "" then
        MageControl.Logger.error("Invalid spell name provided", "SpellCasting")
        MageControl.Logger.info("MageControl: Invalid spell name")
        return false
    end

    -- Debug unknown spells
    if MageControl.ManaUtils.getSpellCostByName(spellName) == 0 then
        MageControl.Logger.debug("Unknown spell in safeQueueSpell: [" .. tostring(spellName) .. "]", "SpellCasting")
    end

    -- Safety check
    if not MageControl.SpellCasting.isSafeToCast(spellName, buffs, buffStates) then
        MageControl.Logger.debug("Not safe to cast: " .. spellName, "SpellCasting")
        return false
    end

    -- Queue the spell
    local success, error = MageControl.ErrorHandler.safeCall(
        function()
            QueueSpellByName(spellName)
        end,
        MageControl.ErrorHandler.TYPES.SPELL,
        {module = "SpellCasting", spell = spellName}
    )
    
    if success then
        MageControl.Logger.debug("Queueing spell: " .. spellName, "SpellCasting")
        return true
    else
        MageControl.Logger.error("Failed to queue spell " .. spellName .. ": " .. tostring(error), "SpellCasting")
        return false
    end
end

-- Validate spell casting parameters
MageControl.SpellCasting.validateParams = function(spellName, buffs, buffStates)
    if not spellName or type(spellName) ~= "string" or spellName == "" then
        return false, "Invalid spell name"
    end
    
    if buffs and type(buffs) ~= "table" then
        return false, "Buffs must be a table"
    end
    
    if buffStates and type(buffStates) ~= "table" then
        return false, "BuffStates must be a table"
    end
    
    return true, "Parameters are valid"
end

-- Get spell availability information
MageControl.SpellCasting.getSpellAvailability = function()
    local slots = MageControl.SpellCasting.getActionBarSlots()
    MageControl.Logger.info("slots.ARCANE_RUPTURE: " .. slots.ARCANE_RUPTURE)
    MageControl.Logger.info("slots.ARCANE_SURGE: " .. slots.ARCANE_SURGE)
    MageControl.Logger.info("slots.FIREBLAST: " .. slots.FIREBLAST)
    return {
        arcaneRuptureReady = MageControl.TimingCalculations.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_RUPTURE, 0),
        arcaneSurgeReady = MageControl.TimingCalculations.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_SURGE, 0),
        fireblastReady = MageControl.TimingCalculations.isActionSlotCooldownReadyAndUsableInSeconds(slots.FIREBLAST, 0) and
                (IsSpellInRange(MageControl.SpellData.SPELL_INFO.FIREBLAST.id) == 1)
    }
end

-- Initialize spell casting system
MageControl.SpellCasting.initialize = function()
    MageControl.Logger.debug("Spell Casting system initialized", "SpellCasting")
end

--[[
    Get spell availability status for all configured spells
    Moved from Core.lua to eliminate MC.* duplication
    
    @return table: Availability status for each spell
]]
MageControl.SpellCasting.getSpellAvailability = function()
    local slots = MageControlDB.actionBarSlots
    return {
        arcaneRuptureReady = MageControl.TimingCalculations.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_RUPTURE, 0),
        arcaneSurgeReady = MageControl.TimingCalculations.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_SURGE, 0),
        fireblastReady = MageControl.TimingCalculations.isActionSlotCooldownReadyAndUsableInSeconds(slots.FIREBLAST, 0) and
                (IsSpellInRange(MageControl.SpellData.SPELL_INFO.FIREBLAST.id) == 1) -- Converted to MageControl.SpellData
    }
end

-- No backward compatibility exports - use MageControl.SpellCasting.* directly
