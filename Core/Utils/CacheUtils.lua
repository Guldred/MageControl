-- MageControl Cache Utilities (Direct Access)
-- Expert module for caching mechanisms, talent lookups, and performance optimizations
-- Location: Core/Utils/CacheUtils.lua (find caching systems here)

MageControl = MageControl or {}
MageControl.CacheUtils = {}

-- Cache for frequently accessed values to reduce expensive WoW API calls
local _talentCache = {}

--[[
    Optimized talent rank lookup with long-term caching
    
    Talents don't change frequently, so we cache them for 30 seconds
    to dramatically reduce GetTalentInfo API calls.
    
    @param tab number: Talent tab (1-3)
    @param num number: Talent number within tab
    @return number: Current talent rank (0-5)
]]
MageControl.CacheUtils.getTalentRank = function(tab, num)
    local cacheKey = tab .. "_" .. num
    local currentTime = GetTime()
    
    -- Check cache first - talents change infrequently
    if _talentCache[cacheKey] and (currentTime - _talentCache[cacheKey].lastUpdate) < 30 then
        return _talentCache[cacheKey].rank
    end
    
    -- Fetch from WoW API and cache result
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, num)
    
    _talentCache[cacheKey] = {
        rank = rank or 0,
        lastUpdate = currentTime
    }
    
    return rank or 0
end

--[[
    Check if channeling finished based on cached state
]]
MageControl.CacheUtils.checkChannelFinished = function()
    if (MageControl.StateManager.state.channelFinishTime < GetTime()) then
        MageControl.StateManager.state.isChanneling = false
    end
end

--[[
    Get current buffs in structured format
    
    @param buffs table: Current buff list
    @return table: Structured buff states
]]
MageControl.CacheUtils.getCurrentBuffs = function(buffs)
    return {
        clearcasting = MageControl.StateManager.findBuff(buffs, MageControl.BuffData.CLEARCASTING.name),
        temporalConvergence = MageControl.StateManager.findBuff(buffs, MageControl.BuffData.TEMPORAL_CONVERGENCE.name),
        arcaneRupture = MageControl.StateManager.findBuff(buffs, MageControl.BuffData.ARCANE_RUPTURE.name),
        arcanePower = MageControl.StateManager.findBuff(buffs, MageControl.BuffData.ARCANE_POWER.name)
    }
end

--[[
    Get current haste value with buff calculations
    
    @return number: Total haste percentage
]]
MageControl.CacheUtils.getCurrentHasteValue = function()
    local hastePercent = MageControlDB.haste.BASE_VALUE

    local hasteBuffs = {
        [MageControl.BuffData.ARCANE_POWER.name] = 30,
        [MageControl.BuffData.MIND_QUICKENING.name] = 33,
        [MageControl.BuffData.ENLIGHTENED_STATE.name] = 20,
        [MageControl.BuffData.SULFURON_BLAZE.name] = 5
    }

    local activeBuffs = {}
    for buffName, buffHaste in pairs(hasteBuffs) do
        local buff = MageControl.StateManager.findBuff(MageControl.StateManager.CURRENT_BUFFS, buffName)
        if buff ~= nil then
            hastePercent = hastePercent + buffHaste
            table.insert(activeBuffs, buffName .. " (+" .. buffHaste .. "%)")
        end
    end

    if table.getn(activeBuffs) > 0 then
        MageControl.Logger.debug("Active haste buffs: " .. table.concat(activeBuffs, ", ") .. " | Total haste: " .. hastePercent .. "%", "CacheUtils")
    else
        MageControl.Logger.debug("No haste buffs active | Base haste: " .. hastePercent .. "%", "CacheUtils")
    end

    return hastePercent
end

--[[
    Check if high haste is currently active
    
    @return boolean: True if haste is above threshold
]]
MageControl.CacheUtils.isHighHasteActive = function()
    local currentHaste = MageControl.CacheUtils.getCurrentHasteValue()
    local threshold = MageControlDB.haste.HASTE_THRESHOLD
    local isAboveHasteThreshold = currentHaste >= threshold
    
    MageControl.Logger.debug("High haste check: " .. currentHaste .. "% >= " .. threshold .. "% = " .. (isAboveHasteThreshold and "YES" or "NO"), "CacheUtils")
    
    return isAboveHasteThreshold
end

-- No backward compatibility exports - use MageControl.CacheUtils.* directly
