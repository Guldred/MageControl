local optionsFrame = nil
local priorityUiDisplayItems = {}

local function debugPrint(message)
    if MC.DEBUG then
        printMessage("MageControl Debug: " .. message)
    end
end

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

-- Modern Button Creation Function
local function createModernButton(parent, width, height, text, color)
    color = color or {r=0.2, g=0.5, b=0.8}
    
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    
    -- Modern rounded background
    button:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    button:SetBackdropColor(color.r, color.g, color.b, 0.8)
    button:SetBackdropBorderColor(color.r * 1.2, color.g * 1.2, color.b * 1.2, 1)
    
    -- Button text
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
    buttonText:SetText(text)
    buttonText:SetTextColor(1, 1, 1, 1)
    button.text = buttonText
    
    -- Hover effects
    button:SetScript("OnEnter", function()
        button:SetBackdropColor(color.r * 1.3, color.g * 1.3, color.b * 1.3, 0.9)
        button:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    
    button:SetScript("OnLeave", function()
        button:SetBackdropColor(color.r, color.g, color.b, 0.8)
        button:SetBackdropBorderColor(color.r * 1.2, color.g * 1.2, color.b * 1.2, 1)
    end)
    
    -- Click effect
    button:SetScript("OnMouseDown", function()
        button:SetBackdropColor(color.r * 0.7, color.g * 0.7, color.b * 0.7, 0.9)
    end)
    
    button:SetScript("OnMouseUp", function()
        button:SetBackdropColor(color.r * 1.3, color.g * 1.3, color.b * 1.3, 0.9)
    end)
    
    return button
end

-- Modern Section Frame Creation
local function createModernSection(parent, width, height, title, yOffset)
    local section = CreateFrame("Frame", nil, parent)
    section:SetWidth(width)
    section:SetHeight(height)
    section:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    -- Modern gradient background
    section:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 2,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    section:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
    section:SetBackdropBorderColor(0.3, 0.4, 0.6, 1)
    
    -- Section title with modern styling
    local titleText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", section, "TOP", 0, -12)
    titleText:SetText(title)
    titleText:SetTextColor(0.8, 0.9, 1, 1)
    
    -- Title underline
    local underline = section:CreateTexture(nil, "ARTWORK")
    underline:SetHeight(1)
    underline:SetWidth(width - 40)
    underline:SetPoint("TOP", titleText, "BOTTOM", 0, -4)
    underline:SetColorTexture(0.3, 0.4, 0.6, 0.8)
    
    return section
end

-- Priority System Functions
local function createPriorityFrame(parent, yOffset)
    return createModernSection(parent, 280, 130, "⚡ Cooldown Priority Order", yOffset)
end

local function reorderPriorityItems(priorityItems)
    local reorderedItems = {}
    for index, key in ipairs(MageControlDB.cooldownPriorityMap) do
        if priorityItems[key] then
            table.insert(reorderedItems, priorityItems[key])
        end
    end
    return reorderedItems
end

local function updatePriorityDisplay()
    local reorderedItems = reorderPriorityItems(priorityUiDisplayItems)

    for i, item in ipairs(reorderedItems) do
        -- Update position and text
        item:SetPoint("TOP", item:GetParent(), "TOP", -30, -35 - (i - 1) * 28)
        item.priorityText:SetText(tostring(i))
        item.position = i

        -- Update button visibility
        if i == 1 then
            item.upButton:Hide()
            item.downButton:Show()
        elseif i == table.getn(reorderedItems) then
            item.upButton:Show()
            item.downButton:Hide()
        else
            item.upButton:Show()
            item.downButton:Show()
        end
    end

    debugPrint("Priority updated - current order:", 1.0, 1.0, 0.0)
    for i, name in ipairs(MageControlDB.cooldownPriorityMap) do
        debugPrint("  " .. i .. ". " .. name, 0.8, 0.8, 0.8)
    end
end

local function moveItemUp(position)
    if position > 1 then
        local temp = MageControlDB.cooldownPriorityMap[position]
        MageControlDB.cooldownPriorityMap[position] = MageControlDB.cooldownPriorityMap[position - 1]
        MageControlDB.cooldownPriorityMap[position - 1] = temp
        updatePriorityDisplay()
        MageControlOptions_Save()
    end
end

local function moveItemDown(position)
    if position < table.getn(MageControlDB.cooldownPriorityMap) then
        local temp = MageControlDB.cooldownPriorityMap[position]
        MageControlDB.cooldownPriorityMap[position] = MageControlDB.cooldownPriorityMap[position + 1]
        MageControlDB.cooldownPriorityMap[position + 1] = temp
        updatePriorityDisplay()
        MageControlOptions_Save()
    end
end

local function createPriorityItem(parent, itemName, color, position)
    local item = CreateFrame("Frame", nil, parent)
    item.position = position
    item.color = color
    item.itemName = itemName
    item:SetWidth(220)
    item:SetHeight(24)
    item:SetPoint("TOP", parent, "TOP", -30, -35 - (position-1) * 28)
    
    -- Modern item background with gradient
    item:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    item:SetBackdropColor(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.4)
    item:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)
    
    -- Priority number with modern styling
    local priorityText = item:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    priorityText:SetPoint("LEFT", item, "LEFT", 12, 0)
    priorityText:SetText(tostring(position))
    priorityText:SetTextColor(1, 0.9, 0.3, 1)
    
    -- Text with better positioning
    local text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", priorityText, "RIGHT", 12, 0)
    text:SetText(itemName)
    text:SetTextColor(0.9, 0.9, 0.9, 1)
    
    -- Modern arrow buttons
    local upButton = CreateFrame("Button", nil, item)
    upButton:SetWidth(20)
    upButton:SetHeight(20)
    upButton:SetPoint("RIGHT", item, "RIGHT", -35, 0)
    
    -- Custom up arrow
    upButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    upButton:SetBackdropColor(0.2, 0.4, 0.2, 0.8)
    upButton:SetBackdropBorderColor(0.4, 0.8, 0.4, 1)
    
    local upArrow = upButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    upArrow:SetPoint("CENTER", upButton, "CENTER", 0, 0)
    upArrow:SetText("▲")
    upArrow:SetTextColor(0.8, 1, 0.8, 1)
    
    local downButton = CreateFrame("Button", nil, item)
    downButton:SetWidth(20)
    downButton:SetHeight(20)
    downButton:SetPoint("RIGHT", item, "RIGHT", -10, 0)
    
    -- Custom down arrow
    downButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    downButton:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
    downButton:SetBackdropBorderColor(0.8, 0.4, 0.4, 1)
    
    local downArrow = downButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    downArrow:SetPoint("CENTER", downButton, "CENTER", 0, 0)
    downArrow:SetText("▼")
    downArrow:SetTextColor(1, 0.8, 0.8, 1)

    -- Button hover effects
    upButton:SetScript("OnEnter", function()
        upButton:SetBackdropColor(0.3, 0.6, 0.3, 1)
    end)
    upButton:SetScript("OnLeave", function()
        upButton:SetBackdropColor(0.2, 0.4, 0.2, 0.8)
    end)
    
    downButton:SetScript("OnEnter", function()
        downButton:SetBackdropColor(0.6, 0.3, 0.3, 1)
    end)
    downButton:SetScript("OnLeave", function()
        downButton:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
    end)

    upButton:SetScript("OnClick", function()
        debugPrint("Up button clicked for position: " .. item.position, 0.0, 1.0, 0.0)
        moveItemUp(item.position)
    end)
    
    downButton:SetScript("OnClick", function()
        debugPrint("Down button clicked for position: " .. item.position, 0.0, 1.0, 0.0)
        moveItemDown(item.position)
    end)
    
    item.text = text
    item.priorityText = priorityText
    item.upButton = upButton
    item.downButton = downButton
    
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
    if optionsFrame then return end

    optionsFrame = CreateFrame("Frame", "MageControlOptionsFrame", UIParent)
    optionsFrame:SetWidth(360)
    optionsFrame:SetHeight(520)
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Modern main window styling
    optionsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 3,
        insets = { left = 12, right = 12, top = 12, bottom = 12 }
    })
    optionsFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    optionsFrame:SetBackdropBorderColor(0.3, 0.4, 0.6, 1)
    
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    optionsFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    tinsert(UISpecialFrames, "MageControlOptionsFrame")

    -- Modern title with glow effect
    local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", optionsFrame, "TOP", 0, -20)
    title:SetText("🔮 MageControl Settings")
    title:SetTextColor(0.8, 0.9, 1, 1)

    -- Modern close button
    local closeButton = createModernButton(optionsFrame, 24, 24, "✕", {r=0.8, g=0.2, b=0.2})
    closeButton:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -15, -15)
    closeButton:SetScript("OnClick", function() optionsFrame:Hide() end)

    -- Spell Detection Section
    local spellSection = createModernSection(optionsFrame, 320, 80, "🎯 Spell Detection", -60)
    
    local autoDetectButton = createModernButton(spellSection, 220, 28, "🔍 Auto-Detect Spell Slots", {r=0.2, g=0.6, b=0.8})
    autoDetectButton:SetPoint("TOP", spellSection, "TOP", 0, -35)
    autoDetectButton:SetScript("OnClick", function()
        local foundSlots = autoDetectSlots()
        MageControlOptions_LoadValues()
    end)

    local autoDetectHelp = spellSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoDetectHelp:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -8)
    autoDetectHelp:SetText("Automatically finds spells in your action bars")
    autoDetectHelp:SetTextColor(0.7, 0.8, 0.9, 1)

    -- Priority Section
    local priorityFrame = createPriorityFrame(optionsFrame, -150)

    priorityUiDisplayItems = {
        TRINKET1 = createPriorityItem(priorityFrame, "🔮 Trinket 1", {r=0.3, g=0.8, b=0.3}, 1),
        TRINKET2 = createPriorityItem(priorityFrame, "💎 Trinket 2", {r=0.3, g=0.3, b=0.8}, 2),
        ARCANE_POWER = createPriorityItem(priorityFrame, "⚡ Arcane Power", {r=0.8, g=0.3, b=0.8}, 3)
    }
    
    updatePriorityDisplay()

    local priorityHelp = priorityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priorityHelp:SetPoint("BOTTOM", priorityFrame, "BOTTOM", 0, 8)
    priorityHelp:SetText("Higher priority items are used first")
    priorityHelp:SetTextColor(0.7, 0.8, 0.9, 1)

    -- Buff Management Section
    local buffSection = createModernSection(optionsFrame, 320, 60, "📊 Buff Frame Controls", -290)
    
    local lockButton = createModernButton(buffSection, 140, 26, "🔒 Lock Frames", {r=0.6, g=0.4, b=0.2})
    lockButton:SetPoint("TOPLEFT", buffSection, "TOPLEFT", 20, -30)
    lockButton:SetScript("OnClick", function() lockFrames() end)

    local unlockButton = createModernButton(buffSection, 140, 26, "🔓 Unlock Frames", {r=0.2, g=0.6, b=0.4})
    unlockButton:SetPoint("TOPRIGHT", buffSection, "TOPRIGHT", -20, -30)
    unlockButton:SetScript("OnClick", function() unlockFrames() end)

    -- Bottom Action Buttons
    local saveButton = createModernButton(optionsFrame, 90, 30, "💾 Save", {r=0.2, g=0.7, b=0.3})
    saveButton:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 25, 25)
    saveButton:SetScript("OnClick", MageControlOptions_Save)

    local resetButton = createModernButton(optionsFrame, 90, 30, "🔄 Reset", {r=0.7, g=0.5, b=0.2})
    resetButton:SetPoint("BOTTOM", optionsFrame, "BOTTOM", 0, 25)
    resetButton:SetScript("OnClick", function()
        MageControlOptions_Reset()
        MageControlOptions_Save()
    end)

    local cancelButton = createModernButton(optionsFrame, 90, 30, "❌ Cancel", {r=0.7, g=0.3, b=0.3})
    cancelButton:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -25, 25)
    cancelButton:SetScript("OnClick", function() optionsFrame:Hide() end)

    optionsFrame:Hide()
end

-- Rest of the existing functions remain the same
function MageControlOptions_LoadValues()
    if not MageControlDB or not MageControlDB.actionBarSlots then
        return
    end
    if not MageControlDB.haste then
        MageControlDB.haste = { HASTE_THRESHOLD = 30, BASE_VALUE = 10 }
    end
    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = {"TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end

    if priorityUiDisplayItems and table.getn(priorityUiDisplayItems) > 0 then
        updatePriorityDisplay()
    end
end

function MageControlOptions_Save()
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Settings saved! ✨", 0.2, 1.0, 0.2)
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
        MageControlDB.cooldownPriorityMap = {"TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end
    
    MageControlOptions_LoadValues()
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Settings reset! 🔄", 1.0, 0.8, 0.2)
end