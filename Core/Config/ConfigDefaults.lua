-- MageControl Configuration Defaults (Direct Access)
-- Expert module for all default configuration values and constants
-- Location: Core/Config/ConfigDefaults.lua (find config defaults here)

MageControl = MageControl or {}
MageControl.ConfigDefaults = {}

-- Default configuration values organized by category
MageControl.ConfigDefaults.values = {
    -- Action bar slots defaults
    actionBarSlots = {
        FIREBLAST = 1,
        ARCANE_RUPTURE = 2,
        ARCANE_SURGE = 5
    },
    
    -- Timing configuration defaults
    timing = {
        CAST_FINISH_THRESHOLD = 0.75,
        GCD_REMAINING_THRESHOLD = 0.75,
        GCD_BUFFER = 1.5,
        GCD_BUFFER_FIREBLAST = 1.5,
        ARCANE_RUPTURE_MIN_DURATION = 2
    },
    
    -- Haste configuration defaults
    haste = {
        BASE_VALUE = 10,
        HASTE_THRESHOLD = 30
    },
    
    -- UI configuration defaults
    ui = {
        debugEnabled = false,
        showBuffDisplay = true,
        showActionDisplay = true,
        lockFrames = false
    },
    
    -- Rotation settings defaults
    rotation = {
        minMissilesForSurgeCancel = 4,
        minManaForArcanePowerUse = 50,
        enableAutoRotation = true,
        enableAutoTarget = true,
        preferredSpells = {"Arcane Missiles", "Arcane Rupture"}
    },
    
    -- Boss encounters configuration defaults
    bossEncounters = {
        incantagos = {
            enabled = false,
            description = "Automatically pick correct spell for adds on Incantagos"
        }
    },
    
    -- Trinket and cooldown settings defaults
    trinkets = {
        priorityList = {
            {type = "trinket", slot = 13, name = "Trinket Slot 1", id = "trinket1"},
            {type = "trinket", slot = 14, name = "Trinket Slot 2", id = "trinket2"},
            {type = "spell", name = "Arcane Power", spellId = 12042, id = "arcane_power"}
        }
    },
    
    -- Missile settings defaults
    missiles = {
        count = 6,
        lagBuffer = 0.05
    },
    
    -- Buff settings defaults
    buffs = {
        cacheMaxAge = 0.1
    },
    
    -- Core constants
    constants = {
        GLOBAL_COOLDOWN_IN_SECONDS = 1.5
    }
}

--[[
    Get default value for a configuration path
    
    @param path string: Configuration path (e.g., "timing.GCD_BUFFER")
    @return any: Default value or nil if not found
]]
MageControl.ConfigDefaults.get = function(path)
    if not path then
        return MageControl.ConfigDefaults.values
    end
    
    local keys = {}
    for key in string.gfind(path, "[^.]+") do  -- Lua 5.0 compatible
        table.insert(keys, key)
    end
    
    local value = MageControl.ConfigDefaults.values
    for i = 1, table.getn(keys) do  -- Lua 5.0 compatible
        local key = keys[i]
        if type(value) == "table" and value[key] ~= nil then
            value = value[key]
        else
            return nil
        end
    end
    
    return value
end

--[[
    Deep copy utility for default values
    
    @param original table: Table to copy
    @return table: Deep copy of original
]]
MageControl.ConfigDefaults.deepCopy = function(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = MageControl.ConfigDefaults.deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

--[[
    Get all default values (deep copy)
    
    @return table: Complete copy of default configuration
]]
MageControl.ConfigDefaults.getAllDefaults = function()
    return MageControl.ConfigDefaults.deepCopy(MageControl.ConfigDefaults.values)
end

-- No backward compatibility exports - use MageControl.ConfigDefaults.* directly
