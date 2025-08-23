-- MageControl Configuration Data Direct Access
-- Simple, direct access to configuration data and settings
-- Location: Core/ConfigData.lua (no service registry, no interfaces)

MageControl = MageControl or {}
MageControl.ConfigData = {}

-- Trinket Priority Configuration
MageControl.ConfigData.getTrinketPriority = function()
    return MageControlDB.trinketPriority or {
        "ToEP", -- Talisman of Ephemeral Power
        "ZHC",  -- Zandalarian Hero Charm  
        "ROIDS" -- R.O.I.D.S
    }
end

MageControl.ConfigData.setTrinketPriority = function(priority)
    if not priority or type(priority) ~= "table" then
        MageControl.Logger.error("setTrinketPriority: priority must be a table", "ConfigData")
        return false
    end
    
    MageControlDB.trinketPriority = priority
    return true
end

-- Mana Thresholds
MageControl.ConfigData.getMinManaForArcanePower = function()
    return MageControlDB.minManaForArcanePower or 70
end

MageControl.ConfigData.setMinManaForArcanePower = function(threshold)
    if not threshold or threshold < 0 or threshold > 100 then
        MageControl.Logger.error("setMinManaForArcanePower: threshold must be between 0-100", "ConfigData")
        return false
    end
    
    MageControlDB.minManaForArcanePower = threshold
    return true
end

MageControl.ConfigData.getMinManaForSurge = function()
    return MageControlDB.minManaForSurge or 40
end

MageControl.ConfigData.setMinManaForSurge = function(threshold)
    if not threshold or threshold < 0 or threshold > 100 then
        MageControl.Logger.error("setMinManaForSurge: threshold must be between 0-100", "ConfigData")
        return false
    end
    
    MageControlDB.minManaForSurge = threshold
    return true
end

-- Missile Configuration
MageControl.ConfigData.getMinMissilesForSurgeCancel = function()
    return MageControlDB.minMissilesForSurgeCancel or 4
end

MageControl.ConfigData.setMinMissilesForSurgeCancel = function(count)
    if not count or count < 1 or count > 5 then
        MageControl.Logger.error("setMinMissilesForSurgeCancel: count must be between 1-5", "ConfigData")
        return false
    end
    
    MageControlDB.minMissilesForSurgeCancel = count  
    return true
end

-- Boss Encounter Configuration
MageControl.ConfigData.isBossEncounterEnabled = function(encounterName)
    if not encounterName then
        return false
    end
    
    if not MageControlDB.bossEncounters then
        return false
    end
    
    local encounter = MageControlDB.bossEncounters[encounterName]
    return encounter and encounter.enabled == true
end

MageControl.ConfigData.setBossEncounterEnabled = function(encounterName, enabled)
    if not encounterName then
        MageControl.Logger.error("setBossEncounterEnabled: encounterName is required", "ConfigData")
        return false
    end
    
    MageControlDB.bossEncounters = MageControlDB.bossEncounters or {}
    MageControlDB.bossEncounters[encounterName] = MageControlDB.bossEncounters[encounterName] or {}
    MageControlDB.bossEncounters[encounterName].enabled = enabled == true
    
    return true
end

-- Training Dummy Configuration
MageControl.ConfigData.isTrainingDummyEnabled = function()
    return MageControlDB.bossEncounters and MageControlDB.bossEncounters.enableTrainingDummies == true
end

MageControl.ConfigData.setTrainingDummyEnabled = function(enabled)
    MageControlDB.bossEncounters = MageControlDB.bossEncounters or {}
    MageControlDB.bossEncounters.enableTrainingDummies = enabled == true
    return true
end

-- UI Configuration
MageControl.ConfigData.isDebugEnabled = function()
    return MageControlDB.ui and MageControlDB.ui.debugEnabled == true
end

MageControl.ConfigData.setDebugEnabled = function(enabled)
    MageControlDB.ui = MageControlDB.ui or {}
    MageControlDB.ui.debugEnabled = enabled == true
    return true
end

-- General Configuration Get/Set
MageControl.ConfigData.get = function(path, defaultValue)
    if not path then
        return defaultValue
    end
    
    local keys = {}
    local iterator = string.gfind(path, "[^%.]+")
    while true do
        local key = iterator()
        if not key then break end
        table.insert(keys, key)
    end
    
    local current = MageControlDB
    for i, key in ipairs(keys) do
        if not current or type(current) ~= "table" then
            return defaultValue
        end
        current = current[key]
    end
    
    return current ~= nil and current or defaultValue
end

MageControl.ConfigData.set = function(path, value)
    if not path then
        MageControl.Logger.error("set: path is required", "ConfigData")
        return false
    end
    
    local keys = {}
    local iterator = string.gfind(path, "[^%.]+")
    while true do
        local key = iterator()
        if not key then break end
        table.insert(keys, key)
    end
    
    if table.getn(keys) == 0 then
        return false
    end
    
    local current = MageControlDB
    for i = 1, table.getn(keys) - 1 do
        local key = keys[i]
        if not current[key] or type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[table.getn(keys)]] = value
    return true
end

-- Backward compatibility - direct global access for easy discoverability
MC.ConfigData = MageControl.ConfigData
