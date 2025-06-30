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

    if updated then
        optionsMessage = optionsMessage .. "Spells detected:\n"
        for _, msg in ipairs(messages) do
            optionsMessage = optionsMessage .. msg .. "\n"
        end
    end

    if table.getn(missingSpells) > 0 then
        optionsMessage = optionsMessage .. "The following spells were not found:\n"
        for _, spellKey in ipairs(missingSpells) do
            optionsMessage = optionsMessage .. "  " .. spellKey .. "\nPlease make sure they are in one of your actionsbars!\n"
        end
    end

    if not updated and table.getn(missingSpells) == 0 then
        optionsMessage = optionsMessage .. "MageControl: No Spells found in Actionbars."
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
    MC.optionsFrame:SetHeight(620)
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

    -- [ESC] to close
    tinsert(UISpecialFrames, "MageControlOptionsFrame")

    local title = MC.optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", MC.optionsFrame, "TOP", 0, -20)
    title:SetText("🔮 MageControl Options")
    title:SetTextColor(0.8, 0.9, 1, 1)

    local closeButton = CreateFrame("Button", nil, MC.optionsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", MC.optionsFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() MC.optionsFrame:Hide() end)

    local dependencyInfo = MC.optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dependencyInfo:SetPoint("TOP", MC.optionsFrame, "TOP", 0, -50)
    dependencyInfo:SetText("📋 " .. MC.checkDependencies())
    dependencyInfo:SetTextColor(0.7, 0.8, 0.9, 1)

    local optionsMessage = ""
    local autoDetectHelp = MC.optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")

    local autoDetectButton = CreateFrame("Button", nil, MC.optionsFrame, "GameMenuButtonTemplate")
    autoDetectButton:SetWidth(140)
    autoDetectButton:SetHeight(28)
    autoDetectButton:SetPoint("TOP", MC.optionsFrame, "TOP", 0, -75)
    autoDetectButton:SetText("Detect Spell Slots")
    MC.applyModernButtonStyle(autoDetectButton, {r=0.2, g=0.6, b=0.8})
    autoDetectButton:SetScript("OnClick", function()
        optionsMessage = MC.autoDetectSlots()
        autoDetectHelp:SetText(optionsMessage)
        MC.optionsLoadValues()
    end)

    autoDetectHelp:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -8)
    autoDetectHelp:SetText("Automatically detects spells in your action bars.\nMake sure required spells are placed first.")
    autoDetectHelp:SetTextColor(0.7, 0.8, 0.9, 1)

    local priorityFrame = MC.createPriorityFrame(MC.optionsFrame, autoDetectHelp, -15)

    MC.priorityUiDisplayItems = {
        TRINKET1 = MC.createPriorityItem(priorityFrame, "🔮 TRINKET1", {r=0.3, g=0.8, b=0.3}, 1),
        TRINKET2 = MC.createPriorityItem(priorityFrame, "💎 TRINKET2", {r=0.3, g=0.3, b=0.8}, 2),
        ARCANE_POWER = MC.createPriorityItem(priorityFrame, "⚡ ARCANE_POWER", {r=0.8, g=0.3, b=0.8}, 3)
    }

    MC.updatePriorityDisplay()

    local priorityHelpFrame = MC.optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    priorityHelpFrame:SetPoint("TOP", priorityFrame, "BOTTOM", 0, -8)
    priorityHelpFrame:SetText("Higher priority items are used first with /mc trinket")
    priorityHelpFrame:SetTextColor(0.7, 0.8, 0.9, 1)

    local minimumManaSlider = MC.createSlider(
            MC.optionsFrame,
            priorityHelpFrame,
            "Minimum Mana for Arcane Power Use",
            0,
            100,
            1,
            MageControlDB.minManaForArcanePowerUse or 50,
            "minManaForArcanePowerUse",
            -40,
            "Min Mana: ",
            "%"
    )

    local missilesSurgeSlider = MC.createSlider(
            MC.optionsFrame,
            minimumManaSlider,
            "Missiles for Surge Cancel",
            1,
            6,
            1,
            MageControlDB.minMissilesForSurgeCancel or 4,
            "minMissilesForSurgeCancel",
            -50,
            "Min. ",
            " missiles"
    )

    local missilesSurgeDesc = MC.optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    missilesSurgeDesc:SetPoint("TOP", missilesSurgeSlider, "BOTTOM", 0, -20)
    missilesSurgeDesc:SetWidth(300)
    missilesSurgeDesc:SetJustifyH("LEFT")
    missilesSurgeDesc:SetTextColor(0.7, 0.8, 0.9, 1)

    local lockButton = CreateFrame("Button", nil, MC.optionsFrame, "GameMenuButtonTemplate")
    lockButton:SetWidth(100)
    lockButton:SetHeight(28)
    lockButton:SetPoint("BOTTOMLEFT", MC.optionsFrame, "BOTTOMLEFT", 25, 25)
    lockButton:SetText("🔒 Lock Frames")
    MC.applyModernButtonStyle(lockButton, {r=0.6, g=0.4, b=0.2})
    lockButton:SetScript("OnClick", function()
        MC.lockFrames()
        MC.lockActionFrames()
    end)

    local unlockButton = CreateFrame("Button", nil, MC.optionsFrame, "GameMenuButtonTemplate")
    unlockButton:SetWidth(100)
    unlockButton:SetHeight(28)
    unlockButton:SetPoint("BOTTOMRIGHT", MC.optionsFrame, "BOTTOMRIGHT", -25, 25)
    unlockButton:SetText("🔓 Unlock Frames")
    MC.applyModernButtonStyle(unlockButton, {r=0.2, g=0.6, b=0.4})
    unlockButton:SetScript("OnClick", function()
        MC.unlockFrames()
        MC.unlockActionFrames()
    end)

    --[[local saveButton = CreateFrame("Button", nil, MC.optionsFrame, "GameMenuButtonTemplate")
    saveButton:SetWidth(90)
    saveButton:SetHeight(30)
    saveButton:SetPoint("BOTTOMLEFT", MC.optionsFrame, "BOTTOMLEFT", 25, 25)
    saveButton:SetText("💾 Save")
    MC.applyModernButtonStyle(saveButton, {r=0.2, g=0.7, b=0.3})
    saveButton:SetScript("OnClick", MageControlOptions_Save)

    local resetButton = CreateFrame("Button", nil, MC.optionsFrame, "GameMenuButtonTemplate")
    resetButton:SetWidth(90)
    resetButton:SetHeight(30)
    resetButton:SetPoint("BOTTOM", MC.optionsFrame, "BOTTOM", 0, 25)
    resetButton:SetText("🔄 Reset")
    MC.applyModernButtonStyle(resetButton, {r=0.7, g=0.5, b=0.2})
    resetButton:SetScript("OnClick", function()
        MageControlOptions_Reset()
        MageControlOptions_Save()
    end)

    local cancelButton = CreateFrame("Button", nil, MC.optionsFrame, "GameMenuButtonTemplate")
    cancelButton:SetWidth(90)
    cancelButton:SetHeight(30)
    cancelButton:SetPoint("BOTTOMRIGHT", MC.optionsFrame, "BOTTOMRIGHT", -25, 25)
    cancelButton:SetText("❌ Cancel")
    MC.applyModernButtonStyle(cancelButton, {r=0.7, g=0.3, b=0.3})
    cancelButton:SetScript("OnClick", function() MC.optionsFrame:Hide() end)]]

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