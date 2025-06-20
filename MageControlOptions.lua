local optionsFrame = nil

local function findSpellSlots()
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

    local requiredSpells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE", "ARCANE_POWER"}
    local missingSpells = {}
    for _, spellKey in ipairs(requiredSpells) do
        if not foundSlots[spellKey] then
            table.insert(missingSpells, spellKey)
        end
    end

    if updated then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Spells detected:", 0.0, 1.0, 0.0)
        for _, msg in ipairs(messages) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. msg, 1.0, 1.0, 0.0)
        end
    end
    
    if table.getn(missingSpells) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: The following spells were not found:", 1.0, 0.5, 0.0)
        for _, spellKey in ipairs(missingSpells) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. spellKey .. " - Please make sure they are in one of your actionsbars!", 1.0, 0.5, 0.0)
        end
    end
    
    if not updated and table.getn(missingSpells) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: No Spells found in Actionbars.", 1.0, 0.5, 0.0)
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
    autoDetectHelp:SetText("Lookup Spell Slots in Actionbars automatically")
    autoDetectHelp:SetTextColor(0.7, 0.7, 0.7)




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
end

function MageControlOptions_Save()
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Settings saved!", 1.0, 1.0, 0.0)
    if optionsFrame then optionsFrame:Hide() end
end

function MageControlOptions_Reset()
    if MageControlDB and MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots.FIREBLAST = 1
        MageControlDB.actionBarSlots.ARCANE_RUPTURE = 2
        MageControlDB.actionBarSlots.ARCANE_SURGE = 3
    end
    if MageControlDB and MageControlDB.haste then
        MageControlDB.haste.BASE_VALUE = 10
        MageControlDB.haste.HASTE_THRESHOLD = 30
    end
end