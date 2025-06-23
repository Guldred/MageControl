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
        item:SetPoint("TOP", item:GetParent(), "TOP", -30, -25 - (i - 1) * 24)
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
    item:SetBackdropColor(item.color.r, item.color.g, item.color.b, 0.3)
    item:SetBackdropBorderColor(item.color.r, item.color.g, item.color.b, 0.8)
    
    -- Priority number
    local priorityText = item:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    priorityText:SetPoint("LEFT", item, "LEFT", 8, 0)
    priorityText:SetText(tostring(position))
    priorityText:SetTextColor(1, 1, 0)
    
    -- Text
    local text = item:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", priorityText, "RIGHT", 8, 0)
    text:SetText(item.itemName)
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
    if optionsFrame then return end -- Prevent duplicate creation

    optionsFrame = CreateFrame("Frame", "MageControlOptionsFrame", UIParent)
    optionsFrame:SetWidth(350)
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

    local dependencyInfo = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dependencyInfo:SetPoint("TOP", optionsFrame, "TOP", 0, -40)
    dependencyInfo:SetText(checkDependencies())
    dependencyInfo:SetTextColor(0.7, 0.7, 0.7)

    local optionsMessage = ""
    local autoDetectHelp = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")

    local autoDetectButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    autoDetectButton:SetWidth(200)
    autoDetectButton:SetHeight(25)
    autoDetectButton:SetPoint("TOP", optionsFrame, "TOP", 0, -65)
    autoDetectButton:SetText("Auto-Detect Spell Slots")
    autoDetectButton:SetScript("OnClick", function()
        optionsMessage = autoDetectSlots()
        autoDetectHelp:SetText(optionsMessage)
        MageControlOptions_LoadValues()
    end)

    autoDetectHelp:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -5)
    autoDetectHelp:SetText("Lookup Spell Slots in Actionbars automatically.\n" ..
                           "Make sure the following spells are in your actionbars:\n" ..
                           "FIREBLAST, ARCANE RUPTURE,\nARCANE SURGE, ARCANE POWER\n" ..
                            "then click the button above to auto-detect them.")
    autoDetectHelp:SetTextColor(0.7, 0.7, 0.7)

    local priorityFrame = createPriorityFrame(optionsFrame, -180)

    priorityUiDisplayItems = {
        TRINKET1 = createPriorityItem(priorityFrame, "TRINKET1", {r=0.2, g=0.8, b=0.2}, 1),
        TRINKET2 = createPriorityItem(priorityFrame, "TRINKET2", {r=0.2, g=0.2, b=0.8}, 2),
        ARCANE_POWER = createPriorityItem(priorityFrame, "ARCANE_POWER", {r=0.8, g=0.2, b=0.8}, 3)
    }
    
    updatePriorityDisplay()

    local PriorityHelp = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    PriorityHelp:SetPoint("TOP", priorityFrame, "BOTTOM", 0, -5)
    PriorityHelp:SetText("Set priority for /mc trinket command\n" ..
                        "The highest priority action is done per \n" ..
                        "macro use. Items without usage or things\n" ..
                        "on cooldown will be ignored.")
    PriorityHelp:SetTextColor(0.7, 0.7, 0.7)

    local lockButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    lockButton:SetWidth(130)
    lockButton:SetHeight(25)
    lockButton:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 20, 65)
    lockButton:SetText("Lock Buff Frames")
    lockButton:SetScript("OnClick", function()
        lockFrames()
    end)

    local unlockButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    unlockButton:SetWidth(130)
    unlockButton:SetHeight(25)
    unlockButton:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -20, 65)
    unlockButton:SetText("Unlock Buff Frames")
    unlockButton:SetScript("OnClick", function()
        unlockFrames()
    end)

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

    debugPrint("MageControl: Settings saved!", 1.0, 1.0, 0.0)
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