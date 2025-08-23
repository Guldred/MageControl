local initializeActionPositions = function()
    if not MageControlDB.actionPositions then
        MageControlDB.actionPositions = {}
        MageControlDB.actionPositions["Arcane Surge"] = { x = 100, y = -300 }
    end

    if MageControlDB.actionDisplayLocked == nil then
        MageControlDB.actionDisplayLocked = true
    end
    MC.actionDisplay.isLocked = MageControlDB.actionDisplayLocked
end

MC.actionDisplay = {
    frames = {},
    isLocked = true,
    updateInterval = 0.2,
    lastUpdate = 0,
    iconPlaceholder = "Interface\\Icons\\INV_Misc_QuestionMark",

    trackedActions = {
        "Arcane Surge"
    },

    defaultPositions = {
        ["Arcane Surge"] = { x = 160, y = -100 }
    },

    icons = {
        ["Arcane Surge"] = "Interface\\Icons\\INV_Enchant_EssenceMysticalLarge"
    }
}

local createActionFrame = function(actionName)
    local frameName = "MageControlAction_" .. string.gsub(actionName, " ", "")
    local frame = CreateFrame("Frame", frameName, UIParent)

    frame:SetWidth(48)
    frame:SetHeight(48)
    frame:SetFrameStrata("HIGH")

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetWidth(32)
    frame.icon:SetHeight(32)
    frame.icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.icon:SetTexture(MC.actionDisplay.icons[actionName])

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetVertexColor(0, 0, 0, 0.8)

    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetAllPoints(frame)
    frame.border:SetVertexColor(0.7, 0.3, 1, 0.8) -- Lila für Arcane

    frame.timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.timerText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.timerText:SetTextColor(1, 1, 1, 1)
    frame.timerText:SetText("0")

    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.nameText:SetPoint("CENTER", frame, "CENTER", 0, -10)
    frame.nameText:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.nameText:SetText(actionName)
    frame.nameText:Hide()

    -- Bewegbarkeit einrichten
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function()
        if not MC.actionDisplay.isLocked then
            this:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function()
        if not MC.actionDisplay.isLocked then
            this:StopMovingOrSizing()

            local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
            MageControlDB.actionPositions[actionName] = { x = xOfs, y = yOfs }
        end
    end)

    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(actionName)
        if not MC.actionDisplay.isLocked then
            GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local pos = MageControlDB.actionPositions[actionName] or MC.actionDisplay.defaultPositions[actionName]
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)

    frame:Hide()

    return frame
end



local updateSurgeFrame = function(frame)
    local timeLeft = MC.state.surgeActiveTill - GetTime()
    if (timeLeft > 0 and IsUsableAction(MC.getActionBarSlots().ARCANE_SURGE) == 1) then
        frame:Show()
        frame.icon:SetTexture(MC.actionDisplay.icons["Arcane Surge"])
        frame.timerText:SetText(string.format("%.1f", timeLeft))

        if timeLeft <= 1.5 then
            frame.timerText:SetTextColor(1, 0.2, 0.2, 1) -- red
        elseif timeLeft <= 3 then
            frame.timerText:SetTextColor(1, 1, 0.2, 1) -- yellow
        else
            frame.timerText:SetTextColor(0.2, 1, 0.2, 1) -- green
        end

    else
        frame:Hide()
    end
end

local updateFunctions = {
    ["Arcane Surge"] = function(frame)
        updateSurgeFrame(frame)
    end
}

local updateActionDisplay = function(actionName, frame)
    if not MC or not MC.actionDisplay.isLocked then return end
    updateFunctions[actionName](frame)
end

local updateAllActionDisplays = function()
    for actionName, frame in pairs(MC.actionDisplay.frames) do
        updateActionDisplay(actionName, frame)
    end
end

local initializeActionFrames = function()
    for _, actionName in ipairs(MC.actionDisplay.trackedActions) do
        if not MC.actionDisplay.frames[actionName] then
            MC.actionDisplay.frames[actionName] = createActionFrame(actionName)
        end
    end
end

MC.lockActionFrames = function()
    MC.actionDisplay.isLocked = true
    MageControlDB.actionDisplayLocked = MC.actionDisplay.isLocked
    for actionName, frame in pairs(MC.actionDisplay.frames) do
        frame.nameText:Hide()
    end
end

MC.unlockActionFrames = function()
    MC.actionDisplay.isLocked = false
    MageControlDB.actionDisplayLocked = MC.actionDisplay.isLocked
    for actionName, frame in pairs(MC.actionDisplay.frames) do
        frame.nameText:Show()
        frame.icon:SetTexture("Interface\\Icons\\INV_Enchant_EssenceMysticalLarge")
        frame.timerText:SetText("0")
        frame:Show()
    end
end

MC.initActionFrames = function()
    initializeActionPositions()
    initializeActionFrames()
    MC.lockActionFrames()
    MC.registerUpdateFunction(updateAllActionDisplays, 0.1)
end

MC.ActionDisplay_ToggleLock = function()
    MC.actionDisplay.isLocked = not MC.actionDisplay.isLocked
    MageControlDB.actionDisplayLocked = MC.actionDisplay.isLocked

    if MC.actionDisplay.isLocked then
        MC.lockActionFrames()
    else
        MC.unlockActionFrames()
    end

    if MC.actionDisplay.isLocked then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Action-Frame locked", 1.0, 1.0, 0.0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Action-Frame unlocked - Drag to move", 1.0, 1.0, 0.0)
    end
end

MC.ActionDisplay_ResetPositions = function()
    MageControlDB.actionPositions = MageControlDB.actionPositions or {}
    for buffName, defaultPos in pairs(MC.actionDisplay.defaultPositions) do
        MageControlDB.actionPositions[buffName] = { x = defaultPos.x, y = defaultPos.y }
        if MC.actionDisplay.frames[buffName] then
            MC.actionDisplay.frames[buffName]:ClearAllPoints()
            MC.actionDisplay.frames[buffName]:SetPoint("CENTER", UIParent, "CENTER", defaultPos.x, defaultPos.y)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Action-Position reset", 1.0, 1.0, 0.0)
end