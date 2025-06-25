local optionsFrame = nil
local priorityUiDisplayItems = {}

local function debugPrint(message)
    if MC.DEBUG then
        printMessage("MageControl Debug: " .. message)
    end
end

local function checkDependencies()
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

local function applyModernButtonStyle(button, color)
    color = color or {r=0.2, g=0.5, b=0.8}

    button:SetScript("OnEnter", function()
        if button:IsEnabled() then
            button:SetAlpha(0.9)
        end
    end)
    
    button:SetScript("OnLeave", function()
        button:SetAlpha(1.0)
    end)
end

local function createPriorityFrame(parent, yOffset)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(280)
    frame:SetHeight(130)
    frame:SetPoint("TOP", parent, "TOP", 0, yOffset)

    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    frame:SetBackdropColor(0.08, 0.08, 0.12, 0.85)
    frame:SetBackdropBorderColor(0.3, 0.4, 0.6, 1)

    local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetPoint("TOP", frame, "TOP", 0, -10)
    titleText:SetText("⚡ Cooldown Priority Order")
    titleText:SetTextColor(0.8, 0.9, 1, 1)
    
    return frame
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
        item:SetPoint("TOP", item:GetParent(), "TOP", 0, -30 - (i - 1) * 26)
        item.priorityText:SetText(tostring(i))
        item.position = i

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
    item:SetPoint("TOP", parent, "TOP", 0, -30 - (position-1) * 26)

    item:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    item:SetBackdropColor(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.4)
    item:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)

    local priorityText = item:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    priorityText:SetPoint("LEFT", item, "LEFT", 10, 0)
    priorityText:SetText(tostring(position))
    priorityText:SetTextColor(1, 0.9, 0.3, 1)

    local text = item:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", priorityText, "RIGHT", 12, 0)
    text:SetText(itemName)
    text:SetTextColor(0.9, 0.9, 0.9, 1)

    local upButton = CreateFrame("Button", nil, item)
    upButton:SetWidth(18)
    upButton:SetHeight(18)
    upButton:SetPoint("RIGHT", item, "RIGHT", -30, 0)
    upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
    upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
    upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

    local downButton = CreateFrame("Button", nil, item)
    downButton:SetWidth(18)
    downButton:SetHeight(18)
    downButton:SetPoint("RIGHT", item, "RIGHT", -8, 0)
    downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

    upButton:SetScript("OnEnter", function()
        upButton:SetAlpha(0.8)
    end)
    upButton:SetScript("OnLeave", function()
        upButton:SetAlpha(1.0)
    end)
    
    downButton:SetScript("OnEnter", function()
        downButton:SetAlpha(0.8)
    end)
    downButton:SetScript("OnLeave", function()
        downButton:SetAlpha(1.0)
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

local function createSlider(parentFrame, relativePointFrame, label, minValue, maxValue, step, defaultValue, dbKey)
    local slider = CreateFrame("Slider", nil, parentFrame, "OptionsSliderTemplate")
    slider:SetWidth(200)
    slider:SetHeight(20)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetValue(defaultValue)
    slider:SetPoint("BOTTOM", relativePointFrame, "BOTTOM", 0, -40)

    local sliderLabel = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sliderLabel:SetPoint("BOTTOM", slider, "TOP", 0, 5)
    sliderLabel:SetText("⚙️ " .. label)
    sliderLabel:SetTextColor(0.8, 0.9, 1, 1)

    local valueDisplay = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueDisplay:SetPoint("TOP", slider, "BOTTOM", 0, -5)
    valueDisplay:SetText(tostring(defaultValue) .. "%")
    valueDisplay:SetTextColor(0.9, 0.9, 0.9, 1)

    slider:SetScript("OnValueChanged", function()
        local v = math.floor(this:GetValue() + 0.5)
        valueDisplay:SetText(v .. "%")
        MageControlDB[dbKey] = v
    end)

    return slider
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
    optionsFrame:SetWidth(380)
    optionsFrame:SetHeight(520)
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    optionsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 15, right = 15, top = 15, bottom = 15 }
    })
    optionsFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    optionsFrame:SetBackdropBorderColor(0.3, 0.4, 0.6, 1)
    
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    optionsFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    -- [ESC] to close
    tinsert(UISpecialFrames, "MageControlOptionsFrame")

    local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", optionsFrame, "TOP", 0, -20)
    title:SetText("🔮 MageControl Options")
    title:SetTextColor(0.8, 0.9, 1, 1)

    local closeButton = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() optionsFrame:Hide() end)

    local dependencyInfo = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dependencyInfo:SetPoint("TOP", optionsFrame, "TOP", 0, -50)
    dependencyInfo:SetText("📋 " .. checkDependencies())
    dependencyInfo:SetTextColor(0.7, 0.8, 0.9, 1)

    local optionsMessage = ""
    local autoDetectHelp = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")

    local autoDetectButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    autoDetectButton:SetWidth(220)
    autoDetectButton:SetHeight(28)
    autoDetectButton:SetPoint("TOP", optionsFrame, "TOP", 0, -75)
    autoDetectButton:SetText("🔍 Auto-Detect Spell Slots")
    applyModernButtonStyle(autoDetectButton, {r=0.2, g=0.6, b=0.8})
    autoDetectButton:SetScript("OnClick", function()
        optionsMessage = autoDetectSlots()
        autoDetectHelp:SetText(optionsMessage)
        MageControlOptions_LoadValues()
    end)

    autoDetectHelp:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -8)
    autoDetectHelp:SetText("Automatically detects spells in your action bars.\nMake sure required spells are placed first.")
    autoDetectHelp:SetTextColor(0.7, 0.8, 0.9, 1)

    local priorityFrame = createPriorityFrame(optionsFrame, -170)

    priorityUiDisplayItems = {
        TRINKET1 = createPriorityItem(priorityFrame, "🔮 TRINKET1", {r=0.3, g=0.8, b=0.3}, 1),
        TRINKET2 = createPriorityItem(priorityFrame, "💎 TRINKET2", {r=0.3, g=0.3, b=0.8}, 2),
        ARCANE_POWER = createPriorityItem(priorityFrame, "⚡ ARCANE_POWER", {r=0.8, g=0.3, b=0.8}, 3)
    }
    
    updatePriorityDisplay()

    local priorityHelpFrame = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    priorityHelpFrame:SetPoint("TOP", priorityFrame, "BOTTOM", 0, -8)
    priorityHelpFrame:SetText("Higher priority items are used first with /mc trinket")
    priorityHelpFrame:SetTextColor(0.7, 0.8, 0.9, 1)

    local slider = createSlider(
            optionsFrame,
            priorityHelpFrame,
            "Minimum Mana for Arcane Power Use",
            0,
            100,
            1,
            MageControlDB.minManaForArcanePowerUse or 50,
            "minManaForArcanePowerUse"
    )

    local lockButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    lockButton:SetWidth(140)
    lockButton:SetHeight(28)
    lockButton:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 25, 70)
    lockButton:SetText("🔒 Lock Buff Frames")
    applyModernButtonStyle(lockButton, {r=0.6, g=0.4, b=0.2})
    lockButton:SetScript("OnClick", function()
        lockFrames()
    end)

    local unlockButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    unlockButton:SetWidth(140)
    unlockButton:SetHeight(28)
    unlockButton:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -25, 70)
    unlockButton:SetText("🔓 Unlock Buff Frames")
    applyModernButtonStyle(unlockButton, {r=0.2, g=0.6, b=0.4})
    unlockButton:SetScript("OnClick", function()
        unlockFrames()
    end)

    local saveButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    saveButton:SetWidth(90)
    saveButton:SetHeight(30)
    saveButton:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 25, 25)
    saveButton:SetText("💾 Save")
    applyModernButtonStyle(saveButton, {r=0.2, g=0.7, b=0.3})
    saveButton:SetScript("OnClick", MageControlOptions_Save)

    local resetButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    resetButton:SetWidth(90)
    resetButton:SetHeight(30)
    resetButton:SetPoint("BOTTOM", optionsFrame, "BOTTOM", 0, 25)
    resetButton:SetText("🔄 Reset")
    applyModernButtonStyle(resetButton, {r=0.7, g=0.5, b=0.2})
    resetButton:SetScript("OnClick", function()
        MageControlOptions_Reset()
        MageControlOptions_Save()
    end)

    local cancelButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    cancelButton:SetWidth(90)
    cancelButton:SetHeight(30)
    cancelButton:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -25, 25)
    cancelButton:SetText("❌ Cancel")
    applyModernButtonStyle(cancelButton, {r=0.7, g=0.3, b=0.3})
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
    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end
    
    if priorityUiDisplayItems and table.getn(priorityUiDisplayItems) > 0 then
        updatePriorityDisplay()
    end
end

function MageControlOptions_Save()
    -- TODO: See if the save button is still required in the future. Currently it does nothing.
    debugPrint("MageControl: Priority Order saved:", 1.0, 1.0, 0.0)
    for i, priority in ipairs(MageControlDB.cooldownPriorityMap) do
        debugPrint("  " .. i .. ". " .. priority, 0.8, 0.8, 0.8)
    end

    debugPrint("MageControl: Settings saved! ✨", 1.0, 1.0, 0.0)
    --if optionsFrame then optionsFrame:Hide() end
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
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end

    MageControlOptions_LoadValues()
end