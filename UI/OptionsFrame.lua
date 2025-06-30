MC.optionsFrame = nil
MC.priorityUiDisplayItems = {}

MC.showOptionsMenu = function()
    if MageControlOptionsFrame and MageControlOptionsFrame:IsVisible() then
        MageControlOptionsFrame:Hide()
    else
        MC.optionsShow()
    end
end

MC.checkDependencies = function()
    local output = "SuperWoW: "

    if SUPERWOW_VERSION then
        output = output .. " Version " .. tostring(SUPERWOW_VERSION)
    else
        output = output .. "Not found!"
    end

    output = output .. ".\nNampower: "

    if GetNampowerVersion and GetNampowerVersion() then
        local major, minor, patch = GetNampowerVersion()

        if major and minor and patch then
            output = output .. "Version " .. tostring(major) .. "." .. tostring(minor) .. "." .. tostring(patch)
        else
            output = output .. "Version unknown (still ok)"
        end
    else
        output = output .. "Not found!"
    end

    return output
end

MC.findSpellSlots = function()
    local foundSlots = {}
    local spellIds = {
        FIREBLAST = 10199,
        ARCANE_RUPTURE = 51954,
        ARCANE_SURGE = 51936,
        ARCANE_POWER = 12042
    }

    for slot = 1, 120 do
        if HasAction(slot) then
            local text, type, id = GetActionText(slot)
            text = text or ""
            type = type or ""
            id = id or 0
            for spellKey, targetId in pairs(spellIds) do
                if id == targetId and not foundSlots[spellKey] then
                    foundSlots[spellKey] = slot
                end
            end
        end
    end

    return foundSlots
end

MC.autoDetectSlots = function()
    local foundSlots = MC.findSpellSlots()
    local updated = false
    local messages = {}
    local optionsMessage = ""

    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {}
    end

    for spellKey, slot in pairs(foundSlots) do
        MageControlDB.actionBarSlots[spellKey] = slot
        updated = true
        table.insert(messages, spellKey .. " -> Slot " .. slot)
    end

    local requiredSpells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE", "ARCANE_POWER"}
    local missingSpells = {}
    for _, spellKey in ipairs(requiredSpells) do
        if not foundSlots[spellKey] then
            table.insert(missingSpells, spellKey)
        end
    end

    if updated and table.getn(missingSpells) == 0 then
        return "All required spells found in Action Bars!"
    end

    if table.getn(missingSpells) > 0 then
        optionsMessage = optionsMessage .. "Missing in Action Bars: "
        for _, spellKey in ipairs(missingSpells) do
            optionsMessage = optionsMessage .. "  " .. spellKey
        end
        MC.printMessage(optionsMessage)
    end

    if not updated and table.getn(missingSpells) == 0 then
        optionsMessage = "All required spells found in Action Bars!"
    end

    return optionsMessage
end

MC.optionsShow = function()
    if not MC.optionsFrame then
        MC.optionsCreateFrame()
    end

    MC.optionsLoadValues()
    MC.optionsFrame:Show()
end

MC.optionsCreateFrame = function()
    if MC.optionsFrame then return end

    MC.optionsFrame = CreateFrame("Frame", "MageControlOptionsFrame", UIParent)
    MC.optionsFrame:SetWidth(400)
    MC.optionsFrame:SetHeight(740)
    MC.optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    MC.optionsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    MC.optionsFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    MC.optionsFrame:SetBackdropBorderColor(0.3, 0.4, 0.6, 1)
    MC.optionsFrame:SetMovable(true)
    MC.optionsFrame:EnableMouse(true)
    MC.optionsFrame:RegisterForDrag("LeftButton")
    MC.optionsFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    MC.optionsFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    tinsert(UISpecialFrames, "MageControlOptionsFrame")

    -- Header-Bereich
    local title = MC.optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", MC.optionsFrame, "TOP", 0, -20)
    title:SetText("🔮 MageControl Options")
    title:SetTextColor(0.8, 0.9, 1, 1)

    local closeButton = CreateFrame("Button", nil, MC.optionsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", MC.optionsFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() MC.optionsFrame:Hide() end)

    local dependencyInfo = MC.optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dependencyInfo:SetPoint("TOP", title, "BOTTOM", 0, -10)
    dependencyInfo:SetText("📋 " .. MC.checkDependencies())
    dependencyInfo:SetTextColor(0.7, 0.8, 0.9, 1)

    -- Setup-Bereich erstellen
    local setupPanel = CreateFrame("Frame", nil, MC.optionsFrame)
    setupPanel:SetWidth(380)
    setupPanel:SetHeight(100)
    setupPanel:SetPoint("TOP", dependencyInfo, "BOTTOM", 0, -15)
    setupPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    setupPanel:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
    setupPanel:SetBackdropBorderColor(0.4, 0.5, 0.7, 1)

    local setupTitle = setupPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    setupTitle:SetPoint("TOPLEFT", setupPanel, "TOPLEFT", 15, -15)
    setupTitle:SetText("Setup")
    setupTitle:SetTextColor(0.9, 0.9, 0.3, 1)

    -- Setup-Buttons - horizontal zentriert
    local buttonsWidth = 120 + 20 + 90 + 20 + 90
    local startX = (380 - buttonsWidth) / 2

    local autoDetectButton = CreateFrame("Button", nil, setupPanel, "GameMenuButtonTemplate")
    autoDetectButton:SetWidth(120)
    autoDetectButton:SetHeight(28)
    autoDetectButton:SetPoint("TOPLEFT", setupPanel, "TOPLEFT", startX, -40)
    autoDetectButton:SetText("Detect Spell Slots")
    MC.applyModernButtonStyle(autoDetectButton, {r=0.2, g=0.6, b=0.8})

    local autoDetectHelp = setupPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    autoDetectHelp:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -4)
    autoDetectHelp:SetWidth(120)
    autoDetectHelp:SetText("Find spells in action bars")
    autoDetectHelp:SetTextColor(0.7, 0.8, 0.9, 1)

    autoDetectButton:SetScript("OnClick", function()
        local optionsMessage = MC.autoDetectSlots()
        autoDetectHelp:SetText(optionsMessage)
        MC.optionsLoadValues()
    end)

    local lockButton = CreateFrame("Button", nil, setupPanel, "GameMenuButtonTemplate")
    lockButton:SetWidth(90)
    lockButton:SetHeight(28)
    lockButton:SetPoint("LEFT", autoDetectButton, "RIGHT", 20, 0)
    lockButton:SetText("Lock Frames")
    MC.applyModernButtonStyle(lockButton, {r=0.6, g=0.4, b=0.2})
    lockButton:SetScript("OnClick", function()
        MC.lockFrames()
        MC.lockActionFrames()
    end)

    local unlockButton = CreateFrame("Button", nil, setupPanel, "GameMenuButtonTemplate")
    unlockButton:SetWidth(90)
    unlockButton:SetHeight(28)
    unlockButton:SetPoint("LEFT", lockButton, "RIGHT", 20, 0)
    unlockButton:SetText("Unlock Frames")
    MC.applyModernButtonStyle(unlockButton, {r=0.2, g=0.6, b=0.4})
    unlockButton:SetScript("OnClick", function()
        MC.unlockFrames()
        MC.unlockActionFrames()
    end)

    -- Hauptkonfigurationspanel
    local configPanel = CreateFrame("Frame", nil, MC.optionsFrame)
    configPanel:SetWidth(380)
    configPanel:SetHeight(530)
    configPanel:SetPoint("TOP", setupPanel, "BOTTOM", 0, -15)
    configPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    configPanel:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
    configPanel:SetBackdropBorderColor(0.4, 0.5, 0.7, 1)

    local configTitle = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    configTitle:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 15, -15)
    configTitle:SetText("Configuration")
    configTitle:SetTextColor(0.9, 0.9, 0.3, 1)

    -- Unterbereich 1: Priority Group
    local priorityGroup = CreateFrame("Frame", nil, configPanel)
    priorityGroup:SetWidth(360)
    priorityGroup:SetHeight(200)
    priorityGroup:SetPoint("TOP", configPanel, "TOP", 0, -40)
    priorityGroup:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    priorityGroup:SetBackdropColor(0.15, 0.15, 0.2, 0.7)
    priorityGroup:SetBackdropBorderColor(0.4, 0.5, 0.7, 0.7)

    -- Unterbereichstitel
    local priorityTitle = priorityGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    priorityTitle:SetPoint("TOPLEFT", priorityGroup, "TOPLEFT", 10, -10)
    priorityTitle:SetText("Trinket Priority")
    priorityTitle:SetTextColor(0.9, 0.8, 0.5, 1)

    -- Priority Frame
    local priorityFrame = MC.createPriorityFrame(priorityGroup)
    priorityFrame:ClearAllPoints()
    priorityFrame:SetPoint("TOP", priorityGroup, "TOP", 0, -30)

    MC.priorityUiDisplayItems = {
        TRINKET1 = MC.createPriorityItem(priorityFrame, "🔮 TRINKET1", {r=0.3, g=0.8, b=0.3}, 1),
        TRINKET2 = MC.createPriorityItem(priorityFrame, "💎 TRINKET2", {r=0.3, g=0.3, b=0.8}, 2),
        ARCANE_POWER = MC.createPriorityItem(priorityFrame, "⚡ ARCANE_POWER", {r=0.8, g=0.3, b=0.8}, 3)
    }
    MC.updatePriorityDisplay()

    local priorityHelpFrame = priorityGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    priorityHelpFrame:SetPoint("TOP", priorityFrame, "BOTTOM", 0, -5)
    priorityHelpFrame:SetWidth(340)
    priorityHelpFrame:SetJustifyH("CENTER")
    priorityHelpFrame:SetText("Higher priority items are used first with /mc trinket")
    priorityHelpFrame:SetTextColor(0.7, 0.8, 0.9, 1)

    -- Unterbereich 2: Mana Schwellenwert
    local manaGroup = CreateFrame("Frame", nil, configPanel)
    manaGroup:SetWidth(360)
    manaGroup:SetHeight(100)
    manaGroup:SetPoint("TOP", priorityGroup, "BOTTOM", 0, -15)
    manaGroup:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    manaGroup:SetBackdropColor(0.15, 0.15, 0.2, 0.7)
    manaGroup:SetBackdropBorderColor(0.4, 0.5, 0.7, 0.7)

    local manaTitle = manaGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    manaTitle:SetPoint("TOPLEFT", manaGroup, "TOPLEFT", 10, -10)
    manaTitle:SetText("Arcane Power Settings")
    manaTitle:SetTextColor(0.9, 0.8, 0.5, 1)

    local minimumManaSlider = CreateFrame("Slider", nil, manaGroup, "OptionsSliderTemplate")
    minimumManaSlider:SetWidth(200)
    minimumManaSlider:SetHeight(20)
    minimumManaSlider:SetPoint("TOP", manaGroup, "TOP", 0, -50)
    minimumManaSlider:SetOrientation("HORIZONTAL")
    minimumManaSlider:SetMinMaxValues(0, 100)
    minimumManaSlider:SetValueStep(1)
    minimumManaSlider:SetValue(MageControlDB.minManaForArcanePowerUse or 50)

    local sliderLabel = minimumManaSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sliderLabel:SetPoint("BOTTOM", minimumManaSlider, "TOP", 0, 5)
    sliderLabel:SetText("Minimum Mana for Arcane Power Use")
    sliderLabel:SetTextColor(0.8, 0.9, 1, 1)

    local valueDisplay = minimumManaSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueDisplay:SetPoint("TOP", minimumManaSlider, "BOTTOM", 0, -5)
    valueDisplay:SetText("Min Mana: " .. (MageControlDB.minManaForArcanePowerUse or 50) .. "%")
    valueDisplay:SetTextColor(0.9, 0.9, 0.9, 1)

    minimumManaSlider:SetScript("OnValueChanged", function()
        local v = math.floor(this:GetValue() + 0.5)
        valueDisplay:SetText("Min Mana: " .. v .. "%")
        MageControlDB.minManaForArcanePowerUse = v
    end)

    -- Unterbereich 3: Missiles Surge
    local missileGroup = CreateFrame("Frame", nil, configPanel)
    missileGroup:SetWidth(360)
    missileGroup:SetHeight(150)
    missileGroup:SetPoint("TOP", manaGroup, "BOTTOM", 0, -15)
    missileGroup:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    missileGroup:SetBackdropColor(0.15, 0.15, 0.2, 0.7)
    missileGroup:SetBackdropBorderColor(0.4, 0.5, 0.7, 0.7)

    local missileTitle = missileGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    missileTitle:SetPoint("TOPLEFT", missileGroup, "TOPLEFT", 10, -10)
    missileTitle:SetText("Arcane Surge Settings")
    missileTitle:SetTextColor(0.9, 0.8, 0.5, 1)

    local missilesSurgeSlider = CreateFrame("Slider", nil, missileGroup, "OptionsSliderTemplate")
    missilesSurgeSlider:SetWidth(200)
    missilesSurgeSlider:SetHeight(20)
    missilesSurgeSlider:SetPoint("TOP", missileGroup, "TOP", 0, -50)
    missilesSurgeSlider:SetOrientation("HORIZONTAL")
    missilesSurgeSlider:SetMinMaxValues(1, 6)
    missilesSurgeSlider:SetValueStep(1)
    missilesSurgeSlider:SetValue(MageControlDB.minMissilesForSurgeCancel or 4)

    local missileLabel = missilesSurgeSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    missileLabel:SetPoint("BOTTOM", missilesSurgeSlider, "TOP", 0, 5)
    missileLabel:SetText("Missiles for Surge Cancel")
    missileLabel:SetTextColor(0.8, 0.9, 1, 1)

    local missileValueDisplay = missilesSurgeSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    missileValueDisplay:SetPoint("TOP", missilesSurgeSlider, "BOTTOM", 0, -5)
    missileValueDisplay:SetText("Min. " .. (MageControlDB.minMissilesForSurgeCancel or 4) .. " missiles")
    missileValueDisplay:SetTextColor(0.9, 0.9, 0.9, 1)

    missilesSurgeSlider:SetScript("OnValueChanged", function()
        local v = math.floor(this:GetValue() + 0.5)
        missileValueDisplay:SetText("Min. " .. v .. " missiles")
        MageControlDB.minMissilesForSurgeCancel = v
    end)

    local missilesSurgeDesc = missileGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    missilesSurgeDesc:SetPoint("TOP", missileValueDisplay, "BOTTOM", 0, -10)
    missilesSurgeDesc:SetWidth(340)
    missilesSurgeDesc:SetJustifyH("CENTER")
    missilesSurgeDesc:SetText("If Arcane Surge is ready while channeling Arcane Missiles, MageControl will cancel Missiles at the last tick before Arcane Surge becomes inactive.")
    missilesSurgeDesc:SetTextColor(0.7, 0.8, 0.9, 1)

    MC.optionsFrame:Hide()
end

MC.optionsLoadValues = function()
    if not MageControlDB or not MageControlDB.actionBarSlots then
        return
    end
    if not MageControlDB.haste then
        MageControlDB.haste = { HASTE_THRESHOLD = 30, BASE_VALUE = 10 }
    end
    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end

    if MC.priorityUiDisplayItems and table.getn(MC.priorityUiDisplayItems) > 0 then
        MC.updatePriorityDisplay()
    end

    if MageControlDB.minMissilesForSurgeCancel == nil then
        MageControlDB.minMissilesForSurgeCancel = 4
    end
end

MC.optionsSave = function()
    -- TODO: See if the save button is still required in the future. Currently it does nothing.
    MC.debugPrint("MageControl: Priority Order saved:", 1.0, 1.0, 0.0)
    for i, priority in ipairs(MageControlDB.cooldownPriorityMap) do
        MC.debugPrint("  " .. i .. ". " .. priority, 0.8, 0.8, 0.8)
    end

    MC.debugPrint("MageControl: Settings saved! ✨", 1.0, 1.0, 0.0)
    --if optionsFrame then optionsFrame:Hide() end
end

MC.optionsReset = function()
    if MageControlDB and MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots.FIREBLAST = 1
        MageControlDB.actionBarSlots.ARCANE_RUPTURE = 2
        MageControlDB.actionBarSlots.ARCANE_SURGE = 3
    end
    if MageControlDB and MageControlDB.haste then
        MageControlDB.haste.BASE_VALUE = 10
        MageControlDB.haste.HASTE_THRESHOLD = 30
    end
    if MageControlDB then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end

    MC.MageControlOptions_LoadValues()
end