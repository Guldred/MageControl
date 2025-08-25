-- PriorityList converted to MageControl.UI.PriorityList unified system
-- All MC.* references converted to MageControl.* expert modules

MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.PriorityList = {}

MageControl.UI.PriorityList.createPriorityFrame = function(parent, relativeToFrame, yOffset)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(280)
    frame:SetHeight(130)
    frame:SetPoint("TOP", relativeToFrame, "BOTTOM", 0, yOffset)

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

MageControl.UI.PriorityList.reorderPriorityItems = function(priorityItems)
    local reorderedItems = {}
    for index, key in ipairs(MageControlDB.cooldownPriorityMap) do
        if priorityItems[key] then
            table.insert(reorderedItems, priorityItems[key])
        end
    end
    return reorderedItems
end

MageControl.UI.PriorityList.updatePriorityDisplay = function()
    local reorderedItems = MageControl.UI.PriorityList.reorderPriorityItems(MageControl.UI.PriorityList.priorityUiDisplayItems)

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

    MageControl.Logger.debug("Priority updated - current order:", "PriorityList")
    for i, name in ipairs(MageControlDB.cooldownPriorityMap) do
        MageControl.Logger.debug("  " .. i .. ". " .. name, "PriorityList")
    end
end

MageControl.UI.PriorityList.moveItemUp = function(position)
    if position > 1 then
        local temp = MageControlDB.cooldownPriorityMap[position]
        MageControlDB.cooldownPriorityMap[position] = MageControlDB.cooldownPriorityMap[position - 1]
        MageControlDB.cooldownPriorityMap[position - 1] = temp
        MageControl.UI.PriorityList.updatePriorityDisplay()
        -- MageControlDB automatically persists changes
    end
end

MageControl.UI.PriorityList.moveItemDown = function(position)
    if position < table.getn(MageControlDB.cooldownPriorityMap) then
        local temp = MageControlDB.cooldownPriorityMap[position]
        MageControlDB.cooldownPriorityMap[position] = MageControlDB.cooldownPriorityMap[position + 1]
        MageControlDB.cooldownPriorityMap[position + 1] = temp
        MageControl.UI.PriorityList.updatePriorityDisplay()
        -- MageControlDB automatically persists changes
    end
end

MageControl.UI.PriorityList.createPriorityItem = function(parent, itemName, color, position)
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
        MageControl.Logger.debug("Up button clicked for position: " .. item.position, "PriorityList")
        MageControl.UI.PriorityList.moveItemUp(item.position)
    end)

    downButton:SetScript("OnClick", function()
        MageControl.Logger.debug("Down button clicked for position: " .. item.position, "PriorityList")
        MageControl.UI.PriorityList.moveItemDown(item.position)
    end)

    item.text = text
    item.priorityText = priorityText
    item.upButton = upButton
    item.downButton = downButton

    return item
end