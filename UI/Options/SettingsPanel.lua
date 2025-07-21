-- MageControl Settings Panel
-- Handles the settings tab in the options interface

MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.Options = MageControl.UI.Options or {}

-- Create the SettingsPanel module
local SettingsPanel = MageControl.createModule("SettingsPanel", {"ConfigManager", "Logger"})

-- Panel state
SettingsPanel.panel = nil
SettingsPanel.manaSlider = nil
SettingsPanel.missileSlider = nil

-- Initialize the settings panel
SettingsPanel.initialize = function()
    MageControl.Logger.debug("Settings Panel initialized", "SettingsPanel")
end

-- Create the settings panel UI
SettingsPanel.create = function(parent)
    if SettingsPanel.panel then return end
    
    SettingsPanel.panel = parent
    
    -- Create Arcane Power settings group
    SettingsPanel._createManaGroup()
    
    -- Create Arcane Surge settings group
    SettingsPanel._createMissileGroup()
end

-- Create mana/Arcane Power settings group
SettingsPanel._createManaGroup = function()
    local manaGroup = CreateFrame("Frame", nil, SettingsPanel.panel)
    manaGroup:SetWidth(360)
    manaGroup:SetHeight(100)
    manaGroup:SetPoint("TOP", SettingsPanel.panel, "TOP", 0, -10)

    local manaTitle = manaGroup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    manaTitle:SetPoint("TOPLEFT", manaGroup, "TOPLEFT", 15, -5)
    manaTitle:SetText("Arcane Power Settings")
    manaTitle:SetTextColor(0.9, 0.8, 0.5, 1)

    -- Minimum mana slider
    SettingsPanel.manaSlider = CreateFrame("Slider", nil, manaGroup, "OptionsSliderTemplate")
    SettingsPanel.manaSlider:SetWidth(200)
    SettingsPanel.manaSlider:SetHeight(20)
    SettingsPanel.manaSlider:SetPoint("TOP", manaGroup, "TOP", 0, -50)
    SettingsPanel.manaSlider:SetOrientation("HORIZONTAL")
    SettingsPanel.manaSlider:SetMinMaxValues(0, 100)
    SettingsPanel.manaSlider:SetValueStep(1)
    SettingsPanel.manaSlider:SetValue(MageControl.ConfigManager.get("rotation.minManaForArcanePowerUse") or 50)

    local sliderLabel = SettingsPanel.manaSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sliderLabel:SetPoint("BOTTOM", SettingsPanel.manaSlider, "TOP", 0, 5)
    sliderLabel:SetText("Minimum Mana for Arcane Power Use")
    sliderLabel:SetTextColor(0.8, 0.9, 1, 1)

    local valueDisplay = SettingsPanel.manaSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueDisplay:SetPoint("TOP", SettingsPanel.manaSlider, "BOTTOM", 0, -5)
    valueDisplay:SetText("Min Mana: " .. (MageControl.ConfigManager.get("rotation.minManaForArcanePowerUse") or 50) .. "%")
    valueDisplay:SetTextColor(0.9, 0.9, 0.9, 1)

    SettingsPanel.manaSlider:SetScript("OnValueChanged", function()
        local v = math.floor(this:GetValue() + 0.5)
        valueDisplay:SetText("Min Mana: " .. v .. "%")
        MageControl.ConfigManager.set("rotation.minManaForArcanePowerUse", v)
    end)

    SettingsPanel.manaGroup = manaGroup
end

-- Create missile/Arcane Surge settings group
SettingsPanel._createMissileGroup = function()
    local missileGroup = CreateFrame("Frame", nil, SettingsPanel.panel)
    missileGroup:SetWidth(360)
    missileGroup:SetHeight(150)
    missileGroup:SetPoint("TOP", SettingsPanel.manaGroup, "BOTTOM", 0, -25)

    local missileTitle = missileGroup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    missileTitle:SetPoint("TOPLEFT", missileGroup, "TOPLEFT", 15, -5)
    missileTitle:SetText("Arcane Surge Settings")
    missileTitle:SetTextColor(0.9, 0.8, 0.5, 1)

    -- Missiles for surge cancel slider
    SettingsPanel.missileSlider = CreateFrame("Slider", nil, missileGroup, "OptionsSliderTemplate")
    SettingsPanel.missileSlider:SetWidth(200)
    SettingsPanel.missileSlider:SetHeight(20)
    SettingsPanel.missileSlider:SetPoint("TOP", missileGroup, "TOP", 0, -50)
    SettingsPanel.missileSlider:SetOrientation("HORIZONTAL")
    SettingsPanel.missileSlider:SetMinMaxValues(1, 6)
    SettingsPanel.missileSlider:SetValueStep(1)
    SettingsPanel.missileSlider:SetValue(MageControl.ConfigManager.get("rotation.minMissilesForSurgeCancel") or 4)

    local missileLabel = SettingsPanel.missileSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    missileLabel:SetPoint("BOTTOM", SettingsPanel.missileSlider, "TOP", 0, 5)
    missileLabel:SetText("Missiles for Surge Cancel")
    missileLabel:SetTextColor(0.8, 0.9, 1, 1)

    local missileValueDisplay = SettingsPanel.missileSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    missileValueDisplay:SetPoint("TOP", SettingsPanel.missileSlider, "BOTTOM", 0, -5)
    missileValueDisplay:SetText("Min. " .. (MageControl.ConfigManager.get("rotation.minMissilesForSurgeCancel") or 4) .. " missiles")
    missileValueDisplay:SetTextColor(0.9, 0.9, 0.9, 1)

    SettingsPanel.missileSlider:SetScript("OnValueChanged", function()
        local v = math.floor(this:GetValue() + 0.5)
        missileValueDisplay:SetText("Min. " .. v .. " missiles")
        MageControl.ConfigManager.set("rotation.minMissilesForSurgeCancel", v)
    end)

    -- Description text
    local missilesSurgeDesc = missileGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    missilesSurgeDesc:SetPoint("TOP", missileValueDisplay, "BOTTOM", 0, -10)
    missilesSurgeDesc:SetWidth(340)
    missilesSurgeDesc:SetJustifyH("CENTER")
    missilesSurgeDesc:SetText("If Arcane Surge is ready while channeling Arcane Missiles, MageControl will cancel Missiles at the last tick before Arcane Surge becomes inactive.")
    missilesSurgeDesc:SetTextColor(0.7, 0.8, 0.9, 1)

    SettingsPanel.missileGroup = missileGroup
end

-- Load current values
SettingsPanel.loadValues = function()
    -- Update mana slider
    if SettingsPanel.manaSlider then
        local manaValue = MageControl.ConfigManager.get("rotation.minManaForArcanePowerUse") or 50
        SettingsPanel.manaSlider:SetValue(manaValue)
    end
    
    -- Update missile slider
    if SettingsPanel.missileSlider then
        local missileValue = MageControl.ConfigManager.get("rotation.minMissilesForSurgeCancel") or 4
        SettingsPanel.missileSlider:SetValue(missileValue)
    end
    
    MageControl.Logger.debug("Settings panel values loaded", "SettingsPanel")
end

-- Save settings
SettingsPanel.save = function()
    -- Values are saved automatically via slider OnValueChanged handlers
    MageControl.Logger.info("Settings saved", "SettingsPanel")
end

-- Reset panel to defaults
SettingsPanel.reset = function()
    MageControl.ConfigManager.resetSection("rotation")
    SettingsPanel.loadValues()
    MageControl.Logger.info("Settings panel reset to defaults", "SettingsPanel")
end

-- Get current settings
SettingsPanel.getSettings = function()
    return {
        minManaForArcanePowerUse = MageControl.ConfigManager.get("rotation.minManaForArcanePowerUse") or 50,
        minMissilesForSurgeCancel = MageControl.ConfigManager.get("rotation.minMissilesForSurgeCancel") or 4
    }
end

-- Validate settings
SettingsPanel.validateSettings = function()
    local settings = SettingsPanel.getSettings()
    local issues = {}
    
    if settings.minManaForArcanePowerUse < 0 or settings.minManaForArcanePowerUse > 100 then
        table.insert(issues, "Mana percentage must be between 0-100")
    end
    
    if settings.minMissilesForSurgeCancel < 1 or settings.minMissilesForSurgeCancel > 6 then
        table.insert(issues, "Missiles count must be between 1-6")
    end
    
    if table.getn(issues) > 0 then
        return false, table.concat(issues, ", ")
    end
    
    return true, "Settings are valid"
end

-- Register the module
MageControl.ModuleSystem.registerModule("SettingsPanel", SettingsPanel)

-- Export for other modules
MageControl.UI.Options.SettingsPanel = SettingsPanel
