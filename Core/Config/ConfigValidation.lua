-- MageControl Configuration Validation (Direct Access)
-- Expert module for configuration management, validation, and path operations
-- Location: Core/Config/ConfigValidation.lua (find config validation here)

MageControl = MageControl or {}
MageControl.ConfigValidation = {}

-- Current configuration (merged with saved data)
MageControl.ConfigValidation.current = {}

-- Performance optimized configuration access with path caching
local _pathCache = {}

--[[
    Optimized path parsing with caching (Lua 5.1+ compatible)
    
    @param path string: Dot-separated path
    @return table: Array of path components
]]
local function parsePath(path)
    if _pathCache[path] then
        return _pathCache[path]
    end
    
    local keys = {}
    for key in string.gfind(path, "[^.]+") do  -- Lua 5.0 compatible
        table.insert(keys, key)
    end
    
    _pathCache[path] = keys
    return keys
end

--[[
    Get configuration value with optimized caching
    
    @param path string: Configuration path (e.g., "timing.GCD_BUFFER")
    @return any: Configuration value or nil if not found
]]
MageControl.ConfigValidation.get = function(path)
    if not path then
        return MageControl.ConfigValidation.current
    end
    
    local keys = parsePath(path)
    local value = MageControl.ConfigValidation.current
    
    -- Optimized table traversal (Lua 5.1+ compatible)
    for i = 1, table.getn(keys) do  -- Lua 5.0 compatible
        local key = keys[i]
        if type(value) == "table" and value[key] ~= nil then
            value = value[key]
        else
            -- Only log warnings in debug mode to reduce overhead
            if MageControl.Logger and MageControl.Logger.isDebugEnabled() then
                MageControl.Logger.warn("Configuration path not found: " .. path, "ConfigValidation")
            end
            return nil
        end
    end
    
    return value
end

--[[
    Set configuration value with validation
    
    @param path string: Configuration path
    @param value any: Value to set
    @return boolean: True if successful
]]
MageControl.ConfigValidation.set = function(path, value)
    if not path then
        if MageControl.Logger then
            MageControl.Logger.error("Cannot set empty configuration path", "ConfigValidation")
        end
        return false
    end
    
    local keys = parsePath(path)
    local current = MageControl.ConfigValidation.current
    
    -- Navigate to parent and set value efficiently (Lua 5.1+ compatible)
    local keyCount = table.getn(keys)  -- Lua 5.0 compatible
    for i = 1, keyCount - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    local finalKey = keys[keyCount]
    local oldValue = current[finalKey]
    current[finalKey] = value
    
    -- Only log in debug mode for performance
    if MageControl.Logger and MageControl.Logger.isDebugEnabled() then
        MageControl.Logger.debug("Config set: " .. path .. " = " .. tostring(value), "ConfigValidation")
    end
    
    return true
end

--[[
    Deep merge utility for combining configurations
    
    @param defaults table: Default configuration
    @param saved table: Saved configuration
    @return table: Merged configuration
]]
local function deepMerge(defaults, saved)
    local result = MageControl.ConfigDefaults.deepCopy(defaults)
    
    if type(saved) ~= "table" then
        return result
    end
    
    for key, value in pairs(saved) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = deepMerge(result[key], value)
        else
            result[key] = value
        end
    end
    
    return result
end

--[[
    Initialize configuration system
]]
MageControl.ConfigValidation.initialize = function()
    -- Ensure saved variables exist
    MageControlDB = MageControlDB or {}
    
    -- Debug: Log what's in MageControlDB before merge (Lua 5.1+ compatible)
    if MageControlDB.trinkets and MageControlDB.trinkets.priorityList then
        local count = table.getn(MageControlDB.trinkets.priorityList)  -- Lua 5.0 compatible
        if MageControl.Logger then
            MageControl.Logger.debug("Found saved trinkets.priorityList with " .. count .. " items", "ConfigValidation")
        end
    else
        if MageControl.Logger then
            MageControl.Logger.debug("No saved trinkets.priorityList found, will use defaults", "ConfigValidation")
        end
    end
    
    -- Special handling for trinkets.priorityList to preserve user settings (Lua 5.1+ compatible)
    local savedTrinketList = nil
    if MageControlDB.trinkets and MageControlDB.trinkets.priorityList and table.getn(MageControlDB.trinkets.priorityList) > 0 then
        savedTrinketList = MageControlDB.trinkets.priorityList
        if MageControl.Logger then
            MageControl.Logger.debug("Preserving user's saved trinket priority list", "ConfigValidation")
        end
    end
    
    -- Merge defaults with saved configuration
    MageControl.ConfigValidation.current = deepMerge(
        MageControl.ConfigDefaults.values,
        MageControlDB
    )
    
    -- Restore saved trinket list if it existed (prevent overwrite by defaults)
    if savedTrinketList then
        MageControl.ConfigValidation.current.trinkets.priorityList = savedTrinketList
        if MageControl.Logger then
            MageControl.Logger.debug("Restored user's trinket priority list", "ConfigValidation")
        end
    end
    
    -- Debug: Log what's in current after merge (Lua 5.1+ compatible)
    local currentList = MageControl.ConfigValidation.current.trinkets.priorityList
    if currentList then
        local count = table.getn(currentList)  -- Lua 5.0 compatible
        if MageControl.Logger then
            MageControl.Logger.debug("After merge, trinkets.priorityList has " .. count .. " items", "ConfigValidation")
            for i, item in ipairs(currentList) do
                MageControl.Logger.debug("  Priority " .. i .. ": " .. (item.name or "unknown"), "ConfigValidation")
            end
        end
    end
    
    -- Validate configuration
    MageControl.ConfigValidation.validateConfig()
    
    if MageControl.Logger then
        MageControl.Logger.info("Configuration system initialized", "ConfigValidation")
    end
end

--[[
    Reset configuration to defaults
]]
MageControl.ConfigValidation.reset = function()
    MageControlDB = MageControl.ConfigDefaults.getAllDefaults()
    MageControl.ConfigValidation.current = MageControl.ConfigDefaults.getAllDefaults()
    if MageControl.Logger then
        MageControl.Logger.info("Configuration reset to defaults", "ConfigValidation")
    end
end

--[[
    Reset specific configuration section
    
    @param section string: Section name to reset
]]
MageControl.ConfigValidation.resetSection = function(section)
    if MageControl.ConfigDefaults.values[section] then
        MageControl.ConfigValidation.current[section] = MageControl.ConfigDefaults.deepCopy(MageControl.ConfigDefaults.values[section])
        MageControlDB[section] = MageControl.ConfigDefaults.deepCopy(MageControl.ConfigDefaults.values[section])
        if MageControl.Logger then
            MageControl.Logger.info("Configuration section reset: " .. section, "ConfigValidation")
        end
    else
        if MageControl.Logger then
            MageControl.Logger.error("Unknown configuration section: " .. section, "ConfigValidation")
        end
    end
end

--[[
    Get all current configuration
    
    @return table: Complete current configuration
]]
MageControl.ConfigValidation.getAll = function()
    return MageControl.ConfigValidation.current
end

--[[
    Validate current configuration
]]
MageControl.ConfigValidation.validateConfig = function()
    local config = MageControl.ConfigValidation.current
    
    -- Validate action bar slots
    if config.actionBarSlots then
        for spell, slot in pairs(config.actionBarSlots) do
            if type(slot) ~= "number" or slot < 1 or slot > 120 then
                if MageControl.Logger then
                    MageControl.Logger.warn("Invalid action bar slot for " .. spell .. ": " .. tostring(slot), "ConfigValidation")
                end
                config.actionBarSlots[spell] = MageControl.ConfigDefaults.values.actionBarSlots[spell]
            end
        end
    end
    
    -- Validate percentage values
    if config.rotation and config.rotation.minManaForArcanePowerUse then
        local mana = config.rotation.minManaForArcanePowerUse
        if type(mana) ~= "number" or mana < 0 or mana > 100 then
            if MageControl.Logger then
                MageControl.Logger.warn("Invalid mana percentage: " .. tostring(mana), "ConfigValidation")
            end
            config.rotation.minManaForArcanePowerUse = MageControl.ConfigDefaults.values.rotation.minManaForArcanePowerUse
        end
    end
end

--[[
    Initialize default settings in saved variables
    Moved from Core.lua to eliminate MC.* duplication
]]
MageControl.ConfigValidation.initializeSettings = function()
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MageControl.ConfigDefaults.values.actionBarSlots.FIREBLAST,
            ARCANE_RUPTURE = MageControl.ConfigDefaults.values.actionBarSlots.ARCANE_RUPTURE,
            ARCANE_SURGE = MageControl.ConfigDefaults.values.actionBarSlots.ARCANE_SURGE
        }
        MageControlDB.haste = {
            BASE_VALUE = MageControl.ConfigDefaults.values.haste.BASE_VALUE,
            HASTE_THRESHOLD = MageControl.ConfigDefaults.values.haste.HASTE_THRESHOLD
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
    -- Note: This still references MC.getTalentRank - will be converted to MageControl.CacheUtils.getTalentRank
    local fireblastTiming = timingByRank[MageControl.CacheUtils.getTalentRank(2,5)] or 1.5
    MageControl.ConfigValidation.current.timing.GCD_BUFFER_FIREBLAST = fireblastTiming
    if MageControl.Logger then
        MageControl.Logger.debug("Set Fireblast Timing to " .. tostring(fireblastTiming) .. " seconds", "ConfigValidation")
    end
end

-- No backward compatibility exports - use MageControl.ConfigValidation.* directly
