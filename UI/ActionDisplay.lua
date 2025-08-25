-- Initialize MageControl.UI.ActionDisplay namespace
MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.ActionDisplay = MageControl.UI.ActionDisplay or {}

local initializeActionPositions = function()
    if not MageControlDB.actionPositions then
        MageControlDB.actionPositions = {}
        MageControlDB.actionPositions["Arcane Surge"] = { x = 100, y = -300 }
    end

    if MageControlDB.actionDisplayLocked == nil then
        MageControlDB.actionDisplayLocked = true
    end
    MageControl.UI.ActionDisplay.isLocked = MageControlDB.actionDisplayLocked
end

MageControl.UI.ActionDisplay = {
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
    frame.icon:SetTexture(MageControl.UI.ActionDisplay.icons[actionName])

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
        if not MageControl.UI.ActionDisplay.isLocked then
            this:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function()
        if not MageControl.UI.ActionDisplay.isLocked then
            this:StopMovingOrSizing()

            local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
            MageControlDB.actionPositions[actionName] = { x = xOfs, y = yOfs }
        end
    end)

    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(actionName)
        if not MageControl.UI.ActionDisplay.isLocked then
            GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local pos = MageControlDB.actionPositions[actionName] or MageControl.UI.ActionDisplay.defaultPositions[actionName]
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)

    frame:Hide()

    return frame
end



local updateSurgeFrame = function(frame)
    local timeLeft = MageControl.StateManager.current.surgeActiveTill - GetTime()
    if (timeLeft > 0 and IsUsableAction(MageControlDB.actionBarSlots.ARCANE_SURGE) == 1) then
        frame:Show()
        frame.icon:SetTexture(MageControl.UI.ActionDisplay.icons["Arcane Surge"])
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
    if not MC or not MageControl.UI.ActionDisplay.isLocked then return end
    updateFunctions[actionName](frame)
end

local updateAllActionDisplays = function()
    for actionName, frame in pairs(MageControl.UI.ActionDisplay.frames) do
        updateActionDisplay(actionName, frame)
    end
end

local initializeActionFrames = function()
    for _, actionName in ipairs(MageControl.UI.ActionDisplay.trackedActions) do
        if not MageControl.UI.ActionDisplay.frames[actionName] then
            MageControl.UI.ActionDisplay.frames[actionName] = createActionFrame(actionName)
        end
    end
end

MageControl.UI.ActionDisplay.lockFrames = function()
    MageControl.UI.ActionDisplay.isLocked = true
    MageControlDB.actionDisplayLocked = MageControl.UI.ActionDisplay.isLocked
    for actionName, frame in pairs(MageControl.UI.ActionDisplay.frames) do
        frame.nameText:Hide()
    end
end

MageControl.UI.ActionDisplay.unlockFrames = function()
    MageControl.UI.ActionDisplay.isLocked = false
    MageControlDB.actionDisplayLocked = MageControl.UI.ActionDisplay.isLocked
    for actionName, frame in pairs(MageControl.UI.ActionDisplay.frames) do
        frame.nameText:Show()
        frame.icon:SetTexture("Interface\\Icons\\INV_Enchant_EssenceMysticalLarge")
        frame.timerText:SetText("0")
        frame:Show()
    end
end

MageControl.UI.ActionDisplay.initActionFrames = function()
    initializeActionPositions()
    initializeActionFrames()
    MageControl.UI.ActionDisplay.lockFrames()
    MageControl.UpdateManager.registerUpdateFunction(updateAllActionDisplays, 0.1)
end

MageControl.UI.ActionDisplay.toggleLock = function()
    MageControl.UI.ActionDisplay.isLocked = not MageControl.UI.ActionDisplay.isLocked
    MageControlDB.actionDisplayLocked = MageControl.UI.ActionDisplay.isLocked

    if MageControl.UI.ActionDisplay.isLocked then
        MageControl.UI.ActionDisplay.lockFrames()
    else
        MageControl.UI.ActionDisplay.unlockFrames()
    end

    if MageControl.UI.ActionDisplay.isLocked then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Action-Frame locked", 1.0, 1.0, 0.0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Action-Frame unlocked - Drag to move", 1.0, 1.0, 0.0)
    end
end

MageControl.UI.ActionDisplay.resetPositions = function()
    MageControlDB.actionPositions = MageControlDB.actionPositions or {}
    for buffName, defaultPos in pairs(MageControl.UI.ActionDisplay.defaultPositions) do
        MageControlDB.actionPositions[buffName] = { x = defaultPos.x, y = defaultPos.y }
        if MageControl.UI.ActionDisplay.frames[buffName] then
            MageControl.UI.ActionDisplay.frames[buffName]:ClearAllPoints()
            MageControl.UI.ActionDisplay.frames[buffName]:SetPoint("CENTER", UIParent, "CENTER", defaultPos.x, defaultPos.y)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Action-Position reset", 1.0, 1.0, 0.0)
end