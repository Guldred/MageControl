local optionsFrame = nil

local function findSpellSlots()
    local foundSlots = {}
    local spellIds = {
        FIREBLAST = 10199,
        ARCANE_RUPTURE = 51954,
        ARCANE_SURGE = 51936
    }

    for slot = 1, 120 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id then
            -- Prüfe ob es einer unserer gesuchten Spells ist
            for spellKey, targetId in pairs(spellIds) do
                if id == targetId then
                    foundSlots[spellKey] = slot
                end
            end
        end
    end
    
    return foundSlots
end

local function autoDetectSlots()
    local foundSlots = findSpellSlots()
    local updated = false
    local messages = {}
    
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {}
    end

    for spellKey, slot in pairs(foundSlots) do
        MageControlDB.actionBarSlots[spellKey] = slot
        updated = true
        table.insert(messages, spellKey .. " -> Slot " .. slot)
    end

    local requiredSpells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE"}
    local missingSpells = {}
    for _, spellKey in ipairs(requiredSpells) do
        if not foundSlots[spellKey] then
            table.insert(missingSpells, spellKey)
        end
    end

    if updated then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Spells automatisch erkannt:", 0.0, 1.0, 0.0)
        for _, msg in ipairs(messages) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. msg, 1.0, 1.0, 0.0)
        end
    end
    
    if table.getn(missingSpells) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Folgende Spells wurden NICHT gefunden:", 1.0, 0.5, 0.0)
        for _, spellKey in ipairs(missingSpells) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. spellKey .. " - Stelle sicher, dass der Spell in deiner Actionbar ist!", 1.0, 0.5, 0.0)
        end
    end
    
    if not updated and table.getn(missingSpells) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Keine Spells in den Actionbars gefunden.", 1.0, 0.5, 0.0)
    end
    
    return foundSlots
end

function MageControlOptions_Show()
    if not optionsFrame then
        MageControlOptions_CreateFrame()
    end

    MageControlOptions_LoadValues()
    optionsFrame:Show()
end

function MageControlOptions_CreateFrame()
    if optionsFrame then return end -- Prevent duplicate creation

    optionsFrame = CreateFrame("Frame", "MageControlOptionsFrame", UIParent)
    optionsFrame:SetWidth(300)
    optionsFrame:SetHeight(350)
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    optionsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    optionsFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    -- [ESC] to close
    tinsert(UISpecialFrames, "MageControlOptionsFrame")

    local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", optionsFrame, "TOP", 0, -15)
    title:SetText("MageControl Options")

    local closeButton = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() optionsFrame:Hide() end)

    local autoDetectButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    autoDetectButton:SetWidth(200)
    autoDetectButton:SetHeight(25)
    autoDetectButton:SetPoint("TOP", optionsFrame, "TOP", 0, -45)
    autoDetectButton:SetText("Auto-Detect Spell Slots")
    autoDetectButton:SetScript("OnClick", function()
        local foundSlots = autoDetectSlots()
        MageControlOptions_LoadValues()
    end)

    local autoDetectHelp = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    autoDetectHelp:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -5)
    autoDetectHelp:SetText("Sucht automatisch nach Spells in deinen Actionbars")
    autoDetectHelp:SetTextColor(0.7, 0.7, 0.7)

    local fireblastLabel = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fireblastLabel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 20, -95)
    fireblastLabel:SetText("Fireblast Slot:")

    local fireblastEditBox = CreateFrame("EditBox", "MageControlFireblastSlot", optionsFrame, "InputBoxTemplate")
    fireblastEditBox:SetWidth(50)
    fireblastEditBox:SetHeight(20)
    fireblastEditBox:SetPoint("LEFT", fireblastLabel, "RIGHT", 10, 0)
    fireblastEditBox:SetAutoFocus(false)
    fireblastEditBox:SetNumeric(true)
    fireblastEditBox:SetMaxLetters(3)

    fireblastEditBox:SetScript("OnTextChanged", function()
        local value = tonumber(this:GetText())
        if value and (value < 1 or value > 120) then
            this:SetTextColor(1, 0, 0)
        else
            this:SetTextColor(1, 1, 1)
        end
    end)

    fireblastEditBox:SetScript("OnEnterPressed", function() MageControlOptions_Save() end)

    local ruptureLabel = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ruptureLabel:SetPoint("TOPLEFT", fireblastLabel, "BOTTOMLEFT", 0, -25)
    ruptureLabel:SetText("Arcane Rupture Slot:")

    local ruptureEditBox = CreateFrame("EditBox", "MageControlRuptureSlot", optionsFrame, "InputBoxTemplate")
    ruptureEditBox:SetWidth(50)
    ruptureEditBox:SetHeight(20)
    ruptureEditBox:SetPoint("LEFT", ruptureLabel, "RIGHT", 10, 0)
    ruptureEditBox:SetAutoFocus(false)
    ruptureEditBox:SetNumeric(true)
    ruptureEditBox:SetMaxLetters(3)
    ruptureEditBox:SetScript("OnTextChanged", function()
        local value = tonumber(this:GetText())
        if value and (value < 1 or value > 120) then
            this:SetTextColor(1, 0, 0)
        else
            this:SetTextColor(1, 1, 1)
        end
    end)

    ruptureEditBox:SetScript("OnEnterPressed", function() MageControlOptions_Save() end)

    local surgeLabel = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    surgeLabel:SetPoint("TOPLEFT", ruptureLabel, "BOTTOMLEFT", 0, -25)
    surgeLabel:SetText("Arcane Surge Slot:")

    local surgeEditBox = CreateFrame("EditBox", "MageControlSurgeSlot", optionsFrame, "InputBoxTemplate")
    surgeEditBox:SetWidth(50)
    surgeEditBox:SetHeight(20)
    surgeEditBox:SetPoint("LEFT", surgeLabel, "RIGHT", 10, 0)
    surgeEditBox:SetAutoFocus(false)
    surgeEditBox:SetNumeric(true)
    surgeEditBox:SetMaxLetters(3)
    surgeEditBox:SetScript("OnTextChanged", function()
        local value = tonumber(this:GetText())
        if value and (value < 1 or value > 120) then
            this:SetTextColor(1, 0, 0)
        else
            this:SetTextColor(1, 1, 1)
        end
    end)
    surgeEditBox:SetScript("OnEnterPressed", function() MageControlOptions_Save() end)

    local hasteBaseValueLabel = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hasteBaseValueLabel:SetPoint("TOPLEFT", surgeLabel, "BOTTOMLEFT", 0, -25)
    hasteBaseValueLabel:SetText("Haste Base Value:")

    local hasteBaseValueEditBox = CreateFrame("EditBox", "MageControlHasteBaseValue", optionsFrame, "InputBoxTemplate")
    hasteBaseValueEditBox:SetWidth(50)
    hasteBaseValueEditBox:SetHeight(20)
    hasteBaseValueEditBox:SetPoint("LEFT", hasteBaseValueLabel, "RIGHT", 10, 0)
    hasteBaseValueEditBox:SetAutoFocus(false)
    hasteBaseValueEditBox:SetNumeric(true)
    hasteBaseValueEditBox:SetMaxLetters(2)
    hasteBaseValueEditBox:SetScript("OnTextChanged", function()
        local value = tonumber(this:GetText())
        if value and value < 0 then
            this:SetTextColor(1, 0, 0)
        else
            this:SetTextColor(1, 1, 1)
        end
    end)
    hasteBaseValueEditBox:SetScript("OnEnterPressed", function() MageControlOptions_Save() end)

    local hasteThresholdLabel = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hasteThresholdLabel:SetPoint("TOPLEFT", hasteBaseValueLabel, "BOTTOMLEFT", 0, -25)
    hasteThresholdLabel:SetText("Haste Threshold:")

    local hasteThresholdEditBox = CreateFrame("EditBox", "MageControlHasteThreshold", optionsFrame, "InputBoxTemplate")
    hasteThresholdEditBox:SetWidth(50)
    hasteThresholdEditBox:SetHeight(20)
    hasteThresholdEditBox:SetPoint("LEFT", hasteThresholdLabel, "RIGHT", 10, 0)
    hasteThresholdEditBox:SetAutoFocus(false)
    hasteThresholdEditBox:SetNumeric(true)
    hasteThresholdEditBox:SetMaxLetters(2)
    hasteThresholdEditBox:SetScript("OnTextChanged", function()
        local value = tonumber(this:GetText())
        if value and value < 0 then
            this:SetTextColor(1, 0, 0)
        else
            this:SetTextColor(1, 1, 1)
        end
    end)
    hasteThresholdEditBox:SetScript("OnEnterPressed", function() MageControlOptions_Save() end)

    local saveButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    saveButton:SetWidth(80)
    saveButton:SetHeight(25)
    saveButton:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 20, 20)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", MageControlOptions_Save)

    local resetButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    resetButton:SetWidth(80)
    resetButton:SetHeight(25)
    resetButton:SetPoint("BOTTOM", optionsFrame, "BOTTOM", 0, 20)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        MageControlOptions_Reset()
        MageControlOptions_Save()
    end)

    local cancelButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    cancelButton:SetWidth(80)
    cancelButton:SetHeight(25)
    cancelButton:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -20, 20)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function() optionsFrame:Hide() end)

    optionsFrame:Hide()
end

function MageControlOptions_LoadValues()
    if not MageControlDB or not MageControlDB.actionBarSlots then
        return
    end
    if not MageControlDB.haste then
        MageControlDB.haste = { HASTE_THRESHOLD = 30, BASE_VALUE = 10 }
    end

    local slots = MageControlDB.actionBarSlots
    local fBox = getglobal("MageControlFireblastSlot")
    local rBox = getglobal("MageControlRuptureSlot")
    local sBox = getglobal("MageControlSurgeSlot")
    local bBox = getglobal("MageControlHasteBaseValue")
    local hBox = getglobal("MageControlHasteThreshold")
    if fBox then fBox:SetText(tostring(slots.FIREBLAST or 1)) end
    if rBox then rBox:SetText(tostring(slots.ARCANE_RUPTURE or 2)) end
    if sBox then sBox:SetText(tostring(slots.ARCANE_SURGE or 5)) end
    if bBox then bBox:SetText(tostring(MageControlDB.haste.BASE_VALUE or 10)) end
    if hBox then hBox:SetText(tostring(MageControlDB.haste.HASTE_THRESHOLD or 30)) end
end

function MageControlOptions_Save()
    local fBox = getglobal("MageControlFireblastSlot")
    local rBox = getglobal("MageControlRuptureSlot")
    local sBox = getglobal("MageControlSurgeSlot")
    local bBox = getglobal("MageControlHasteBaseValue")
    local hBox = getglobal("MageControlHasteThreshold")
    local fireblastSlot = tonumber(fBox and fBox:GetText() or "1") or 1
    local ruptureSlot = tonumber(rBox and rBox:GetText() or "2") or 2
    local surgeSlot = tonumber(sBox and sBox:GetText() or "5") or 5
    local hasteBaseValue = tonumber(bBox and bBox:GetText() or "10") or 10
    local hasteThreshold = tonumber(hBox and hBox:GetText() or "30") or 30

    if not fireblastSlot or fireblastSlot < 1 or fireblastSlot > 120 then
        message("Invalid Fireblast slot. Must be between 1 and 120.")
        return
    end

    if not ruptureSlot or ruptureSlot < 1 or ruptureSlot > 120 then
        message("Invalid Arcane Rupture slot. Must be between 1 and 120.")
        return
    end

    if not surgeSlot or surgeSlot < 1 or surgeSlot > 120 then
        message("Invalid Arcane Surge slot. Must be between 1 and 120.")
        return
    end

    if not hasteBaseValue or hasteBaseValue < 0 then
        message("Invalid Haste Base Value. Must be a non-negative number.")
        return
    end

    if not hasteThreshold or hasteThreshold < 0 then
        message("Invalid Haste Threshold. Must be a positive number.")
        return
    end

    if not MageControlDB.actionBarSlots then MageControlDB.actionBarSlots = {} end
    if not MageControlDB.haste then MageControlDB.haste = {} end

    MageControlDB.actionBarSlots.FIREBLAST = math.floor(fireblastSlot)
    MageControlDB.actionBarSlots.ARCANE_RUPTURE = math.floor(ruptureSlot)
    MageControlDB.actionBarSlots.ARCANE_SURGE = math.floor(surgeSlot)
    MageControlDB.haste.BASE_VALUE = math.floor(hasteBaseValue)
    MageControlDB.haste.HASTE_THRESHOLD = math.floor(hasteThreshold)

    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Settings saved!", 1.0, 1.0, 0.0)
    if optionsFrame then optionsFrame:Hide() end
end

function MageControlOptions_Reset()
    if MageControlDB and MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots.FIREBLAST = 1
        MageControlDB.actionBarSlots.ARCANE_RUPTURE = 2
        MageControlDB.actionBarSlots.ARCANE_SURGE = 5
    end
    if MageControlDB and MageControlDB.haste then
        MageControlDB.haste.BASE_VALUE = 10
        MageControlDB.haste.HASTE_THRESHOLD = 30
    end

    local fBox = getglobal("MageControlFireblastSlot")
    local rBox = getglobal("MageControlRuptureSlot")
    local sBox = getglobal("MageControlSurgeSlot")
    local bBox = getglobal("MageControlHasteBaseValue")
    local hBox = getglobal("MageControlHasteThreshold")
    if fBox then fBox:SetText("1") end
    if rBox then rBox:SetText("2") end
    if sBox then sBox:SetText("5") end
    if bBox then bBox:SetText("10") end
    if hBox then hBox:SetText("30") end
end