-- MageControl Mana Utilities (Direct Access)
-- Expert module for mana calculations, spell costs, and mana percentage tracking
-- Location: Core/Utils/ManaUtils.lua (find mana calculations here)

MageControl = MageControl or {}
MageControl.ManaUtils = {}

-- Cache for frequently accessed mana values to reduce expensive WoW API calls
local _manaCache = { value = 0, maxValue = 1, lastUpdate = 0 }
local _spellCostCache = {}
local CACHE_DURATION = 0.5 -- Cache mana for 0.5 seconds to balance accuracy vs performance

--[[
    Optimized mana percentage calculation with intelligent caching
    
    This function caches mana values for CACHE_DURATION seconds to reduce
    expensive UnitMana/UnitManaMax API calls during high-frequency rotation checks.
    
    @return number: Current mana percentage (0-100)
]]
MageControl.ManaUtils.getCurrentManaPercent = function()
    local currentTime = GetTime()
    
    -- Only update cache if expired to reduce API overhead
    if (currentTime - _manaCache.lastUpdate) > CACHE_DURATION then
        _manaCache.maxValue = UnitManaMax("player") or 1
        _manaCache.value = UnitMana("player") or 0
        _manaCache.lastUpdate = currentTime
    end
    
    return _manaCache.maxValue > 0 and (_manaCache.value / _manaCache.maxValue) * 100 or 0
end

--[[
    Get spell mana cost by name with caching
    
    @param spellName string: Name of spell to get cost for
    @return number: Mana cost of spell
]]
MageControl.ManaUtils.getSpellCostByName = function(spellName)
    if not spellName then
        return 0
    end
    
    -- Check permanent cache first - spell costs don't change
    if _spellCostCache[spellName] then
        return _spellCostCache[spellName]
    end
    
    local normalizedName = MageControl.StringUtils.normSpellName(spellName)
    local spellInfo = MC.SPELL_INFO
    
    -- Optimized lookup with direct iteration
    for spellKey, spell in pairs(spellInfo) do
        if MageControl.StringUtils.normSpellName(spell.name) == normalizedName then
            _spellCostCache[spellName] = spell.cost or 0
            return spell.cost or 0
        end
    end
    
    -- Cache negative results to prevent repeated lookups
    _spellCostCache[spellName] = 0
    return 0
end

--[[
    Get modified spell mana cost with buff considerations
    
    @param spellName string: Name of spell
    @param buffStates table: Current buff states
    @return number: Modified mana cost
]]
MageControl.ManaUtils.getModifiedSpellManaCost = function(spellName, buffStates)
    if buffStates and buffStates.clearcasting then
        return 0
    end
    local baseCost = MageControl.ManaUtils.getSpellCostByName(spellName)
    if MageControl.StringUtils.normSpellName(spellName) == "arcane missiles" and buffStates and buffStates.arcaneRupture then
        return baseCost * MC.SPELL_MODIFIERS.ARCANE_MISSILES_RUPTURE_MULTIPLIER
    end

    return baseCost
end

--[[
    Get spell cost as percentage of max mana
    
    @param spellName string: Name of spell
    @param buffStates table: Current buff states
    @return number: Cost as percentage (0-100)
]]
MageControl.ManaUtils.getSpellCostPercent = function(spellName, buffStates)
    local manaCost = MageControl.ManaUtils.getModifiedSpellManaCost(spellName, buffStates)
    local maxMana = UnitManaMax("player")
    if maxMana and manaCost and manaCost > 0 then
        return (manaCost / maxMana) * 100
    end
    return 0
end

--[[
    Check for mana warning during Arcane Power
    
    @param buffs table: Current buffs
]]
MageControl.ManaUtils.checkManaWarning = function(buffs)
    local arcanePowerTimeLeft = MageControl.ManaUtils.getArcanePowerTimeLeft(buffs)
    if arcanePowerTimeLeft > 0 then
        local currentMana = MageControl.ManaUtils.getCurrentManaPercent()
        local projectedMana = currentMana - (arcanePowerTimeLeft * MC.BUFF_INFO.ARCANE_POWER.mana_drain_per_second)

        if projectedMana < 15 and projectedMana > 10 then
            MC.printMessage("|cffffff00MageControl: LOW MANA WARNING - " .. math.floor(projectedMana) .. "% projected!|r")
        end
    end
end

--[[
    Get remaining time on Arcane Power buff
    
    @param buffs table: Current buffs
    @return number: Time left on arcane power buff
]]
MageControl.ManaUtils.getArcanePowerTimeLeft = function(buffs)
    local arcanePower = MC.findBuff(buffs, MC.BUFF_INFO.ARCANE_POWER.name)
    return arcanePower and arcanePower:duration() or 0
end

-- No backward compatibility exports - use MageControl.ManaUtils.* directly
