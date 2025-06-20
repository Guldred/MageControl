local optionsFrame = nil
local priorityItems = {} -- Global reference

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

-- Priority System Functions
local function createPriorityFrame(parent, yOffset)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(260)
    frame:SetHeight(120)
    frame:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.2)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Title
    local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetPoint("TOP", frame, "TOP", 0, -8)
    titleText:SetText("Cooldown Priority Order")
    titleText:SetTextColor(1, 1, 1)
    
    return frame
end

-- Neue Struktur: Statt Frames zu bewegen, ändern wir nur den Inhalt
local priorityData = {
    "🔮 Trinket 1",
    "💎 Trinket 2",
    "⚡ Arcane Power"
}

local function updatePriorityDisplay()
    for i, item in ipairs(priorityItems) do
        -- Aktualisiere den Text basierend auf der aktuellen Reihenfolge
        item.priorityText:SetText(tostring(i))
        item.text:SetText(priorityData[i])
        item.itemName = priorityData[i]  -- WICHTIG: Auch itemName aktualisieren!
        
        -- Show/Hide buttons based on position
        if i == 1 then
            item.upButton:Hide()
            item.downButton:Show()
        elseif i == table.getn(priorityItems) then
            item.upButton:Show()
            item.downButton:Hide()
        else
            item.upButton:Show()
            item.downButton:Show()
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Priority updated - current order:", 1.0, 1.0, 0.0)
    for i, name in ipairs(priorityData) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. name, 0.8, 0.8, 0.8)
    end
end

local function moveItemUp(position)
    if position > 1 then
        -- Swap with previous item in data array
        local temp = priorityData[position]
        priorityData[position] = priorityData[position - 1]
        priorityData[position - 1] = temp
        updatePriorityDisplay()
    end
end

local function moveItemDown(position)
    if position < table.getn(priorityData) then
        -- Swap with next item in data array
        local temp = priorityData[position]
        priorityData[position] = priorityData[position + 1]
        priorityData[position + 1] = temp
        updatePriorityDisplay()
    end
end

local function createPriorityItem(parent, itemName, color, position)
    local item = CreateFrame("Frame", nil, parent)
    item:SetWidth(180)
    item:SetHeight(22)
    item:SetPoint("TOP", parent, "TOP", -30, -25 - (position-1) * 24)
    
    -- Background
    item:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    item:SetBackdropColor(color.r, color.g, color.b, 0.3)
    item:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)
    
    -- Priority number
    local priorityText = item:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    priorityText:SetPoint("LEFT", item, "LEFT", 8, 0)
    priorityText:SetText(tostring(position))
    priorityText:SetTextColor(1, 1, 0)
    
    -- Text
    local text = item:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", priorityText, "RIGHT", 8, 0)
    text:SetText(itemName)
    text:SetTextColor(1, 1, 1)
    
    -- Up Button
    local upButton = CreateFrame("Button", nil, item)
    upButton:SetWidth(16)
    upButton:SetHeight(16)
    upButton:SetPoint("RIGHT", item, "RIGHT", -25, 0)
    upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
    upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
    upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    
    -- Down Button
    local downButton = CreateFrame("Button", nil, item)
    downButton:SetWidth(16)
    downButton:SetHeight(16)
    downButton:SetPoint("RIGHT", item, "RIGHT", -5, 0)
    downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    
    -- Set up button callbacks - verwende Position statt Item-Referenz
    upButton:SetScript("OnClick", function()
        DEFAULT_CHAT_FRAME:AddMessage("Up button clicked for position: " .. position, 0.0, 1.0, 0.0)
        moveItemUp(position)
    end)
    
    downButton:SetScript("OnClick", function()
        DEFAULT_CHAT_FRAME:AddMessage("Down button clicked for position: " .. position, 0.0, 1.0, 0.0)
        moveItemDown(position)
    end)
    
    item.text = text
    item.priorityText = priorityText
    item.itemName = itemName
    item.upButton = upButton
    item.downButton = downButton
    item.position = position
    
    return item
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
    optionsFrame:SetHeight(480)
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

    -- Priority System hinzufügen
    local priorityFrame = createPriorityFrame(optionsFrame, -180)
    
    -- Create priority items - diese ändern sich nie in der Position
    priorityItems = {
        createPriorityItem(priorityFrame, "🔮 Trinket 1", {r=0.2, g=0.8, b=0.2}, 1),
        createPriorityItem(priorityFrame, "💎 Trinket 2", {r=0.2, g=0.2, b=0.8}, 2),
        createPriorityItem(priorityFrame, "⚡ Arcane Power", {r=0.8, g=0.2, b=0.8}, 3)
    }
    
    updatePriorityDisplay()

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
    if not MageControlDB.priorities then
        MageControlDB.priorities = {"TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end

    -- Load priority order into our data array
    local priorityMap = {
        TRINKET1 = "🔮 Trinket 1",
        TRINKET2 = "💎 Trinket 2", 
        ARCANE_POWER = "⚡ Arcane Power"
    }
    
    for i, priorityKey in ipairs(MageControlDB.priorities) do
        if priorityMap[priorityKey] then
            priorityData[i] = priorityMap[priorityKey]
        end
    end
    
    if priorityItems and table.getn(priorityItems) > 0 then
        updatePriorityDisplay()
    end
end

function MageControlOptions_Save()
    -- Save priority order based on our data array
    local priorityOrder = {}
    local itemMap = {
        ["🔮 Trinket 1"] = "TRINKET1",
        ["💎 Trinket 2"] = "TRINKET2",
        ["⚡ Arcane Power"] = "ARCANE_POWER"
    }
    
    for _, name in ipairs(priorityData) do
        local key = itemMap[name]
        if key then
            table.insert(priorityOrder, key)
        end
    end
    
    MageControlDB.priorities = priorityOrder
    
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Priority Order saved:", 1.0, 1.0, 0.0)
    for i, priority in ipairs(priorityOrder) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. priority, 0.8, 0.8, 0.8)
    end

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
    if MageControlDB then
        MageControlDB.priorities = {"TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end
    
    -- Reset priority data
    priorityData = {
        "🔮 Trinket 1",
        "💎 Trinket 2",
        "⚡ Arcane Power"
    }
    
    -- Reset priority display
    MageControlOptions_LoadValues()
end