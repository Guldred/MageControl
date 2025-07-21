-- MageControl Spell Slot Detector
-- Handles automatic detection of spells in action bars

MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.Options = MageControl.UI.Options or {}

-- Create the SpellSlotDetector module
local SpellSlotDetector = MageControl.createModule("SpellSlotDetector", {"ConfigManager", "Logger"})

-- Spell ID mappings for detection
SpellSlotDetector.spellIds = {
    FIREBLAST = 10199,
    ARCANE_RUPTURE = 51954,
    ARCANE_SURGE = 51936,
    ARCANE_POWER = 12042
}

-- Required spells for the addon to function
SpellSlotDetector.requiredSpells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE", "ARCANE_POWER"}

-- Initialize the detector
SpellSlotDetector.initialize = function()
    MageControl.Logger.debug("Spell Slot Detector initialized", "SpellSlotDetector")
end

-- Find all spells in action bars
SpellSlotDetector.findSpellSlots = function()
    local foundSlots = {}
    
    for slot = 1, 120 do
        if HasAction(slot) then
            local text, actionType, id = GetActionText(slot)
            text = text or ""
            actionType = actionType or ""
            id = id or 0
            
            for spellKey, targetId in pairs(SpellSlotDetector.spellIds) do
                if id == targetId and not foundSlots[spellKey] then
                    foundSlots[spellKey] = slot
                    MageControl.Logger.debug("Found " .. spellKey .. " in slot " .. slot, "SpellSlotDetector")
                end
            end
        end
    end

    return foundSlots
end

-- Auto-detect and update configuration
SpellSlotDetector.autoDetectSlots = function()
    local foundSlots = SpellSlotDetector.findSpellSlots()
    local updated = false
    local messages = {}
    local optionsMessage = ""

    -- Ensure action bar slots config exists
    local currentSlots = MageControl.ConfigManager.get("actionBarSlots") or {}

    -- Update found slots
    for spellKey, slot in pairs(foundSlots) do
        MageControl.ConfigManager.set("actionBarSlots." .. spellKey, slot)
        updated = true
        table.insert(messages, spellKey .. " -> Slot " .. slot)
    end

    -- Check for missing spells
    local missingSpells = {}
    for _, spellKey in ipairs(SpellSlotDetector.requiredSpells) do
        if not foundSlots[spellKey] then
            table.insert(missingSpells, spellKey)
        end
    end

    -- Generate status message
    if updated and table.getn(missingSpells) == 0 then
        optionsMessage = "All required spells found in Action Bars!"
        MageControl.Logger.info("Auto-detection successful: " .. table.getn(foundSlots) .. " spells found", "SpellSlotDetector")
    elseif table.getn(missingSpells) > 0 then
        optionsMessage = "Missing in Action Bars: "
        for _, spellKey in ipairs(missingSpells) do
            optionsMessage = optionsMessage .. "  " .. spellKey
        end
        MageControl.Logger.warn("Missing spells: " .. table.getn(missingSpells), "SpellSlotDetector")
    elseif not updated and table.getn(missingSpells) == 0 then
        optionsMessage = "All required spells found in Action Bars!"
    else
        optionsMessage = "No spells detected in action bars"
    end

    return optionsMessage
end

-- Validate current spell slot configuration
SpellSlotDetector.validateConfiguration = function()
    local actionBarSlots = MageControl.ConfigManager.get("actionBarSlots")
    if not actionBarSlots then
        return false, "No action bar slots configured"
    end

    local issues = {}
    
    for _, spellKey in ipairs(SpellSlotDetector.requiredSpells) do
        local slot = actionBarSlots[spellKey]
        if not slot then
            table.insert(issues, spellKey .. " not configured")
        elseif type(slot) ~= "number" or slot < 1 or slot > 120 then
            table.insert(issues, spellKey .. " has invalid slot: " .. tostring(slot))
        end
    end

    if table.getn(issues) > 0 then
        return false, table.concat(issues, ", ")
    end

    return true, "All spell slots configured correctly"
end

-- Get status of spell detection
SpellSlotDetector.getStatus = function()
    local foundSlots = SpellSlotDetector.findSpellSlots()
    local configuredSlots = MageControl.ConfigManager.get("actionBarSlots") or {}
    
    local status = {
        foundSpells = {},
        missingSpells = {},
        configuredSpells = {},
        totalFound = 0,
        totalRequired = table.getn(SpellSlotDetector.requiredSpells)
    }

    -- Check what's found vs required
    for _, spellKey in ipairs(SpellSlotDetector.requiredSpells) do
        if foundSlots[spellKey] then
            table.insert(status.foundSpells, {spell = spellKey, slot = foundSlots[spellKey]})
            status.totalFound = status.totalFound + 1
        else
            table.insert(status.missingSpells, spellKey)
        end
        
        if configuredSlots[spellKey] then
            table.insert(status.configuredSpells, {spell = spellKey, slot = configuredSlots[spellKey]})
        end
    end

    return status
end

-- Register the module
MageControl.ModuleSystem.registerModule("SpellSlotDetector", SpellSlotDetector)

-- Backward compatibility
MC.findSpellSlots = function()
    return SpellSlotDetector.findSpellSlots()
end

MC.autoDetectSlots = function()
    return SpellSlotDetector.autoDetectSlots()
end

-- Export for other modules
MageControl.UI.Options.SpellSlotDetector = SpellSlotDetector
