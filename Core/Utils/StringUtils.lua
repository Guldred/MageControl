-- MageControl String Utilities (Direct Access)
-- Expert module for string operations, normalization, and spell name lookups
-- Location: Core/Utils/StringUtils.lua (find string operations here)

MageControl = MageControl or {}
MageControl.StringUtils = {}

-- Pre-compiled pattern for better string performance
local SPELL_NAME_PATTERN = "%l+"

--[[
    Normalize spell name to lowercase for consistent comparisons
    
    @param name string: Spell name to normalize
    @return string: Normalized spell name
]]
MageControl.StringUtils.normSpellName = function(name)
    if not name or name == "" then 
        return "" 
    end
    return string.lower(name)
end

--[[
    Get buff name by ID from buff info
    
    @param buffID number: ID of buff to lookup
    @return string: Name of buff or "Untracked Buff" if not found
]]
MageControl.StringUtils.getBuffNameByID = function(buffID)
    for _, info in pairs(MC.BUFF_INFO) do
        if info.id == buffID then
            return info.name
        end
    end

    return "Untracked Buff"
end

--[[
    Get spell ID by name lookup
    
    @param spellName string: Name of spell to retrieve ID for
    @return number: ID of spell or nil if not found
]]
MageControl.StringUtils.getSpellIdByName = function(spellName)
    local normalizedName = MageControl.StringUtils.normSpellName(spellName)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if MageControl.StringUtils.normSpellName(spellInfo.name) == normalizedName then
            return spellInfo.id
        end
    end
    return nil
end

--[[
    Get spell name by ID lookup
    
    @param spellId number: ID of spell to retrieve name for
    @return string: Name of spell or spell ID as string if not found
]]
MageControl.StringUtils.getSpellNameById = function(spellId)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if spellInfo.id == spellId then
            return spellInfo.name
        end
    end
    return tostring(spellId)
end

-- No backward compatibility exports - use MageControl.StringUtils.* directly
