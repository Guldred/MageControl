-- Initialize MageControl.UI.BuffDisplay namespace
MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.BuffDisplay = MageControl.UI.BuffDisplay or {}

local initializeBuffPositions = function()
    if not MageControlDB.buffPositions then
        MageControlDB.buffPositions = {}
        for buffName, pos in pairs(MageControl.UI.BuffDisplay.defaultPositions) do
            MageControlDB.buffPositions[buffName] = { x = pos.x, y = pos.y }
        end
    end

    if MageControlDB.buffDisplayLocked == nil then
        MageControlDB.buffDisplayLocked = true
    end
    MageControl.UI.BuffDisplay.isLocked = MageControlDB.buffDisplayLocked
end

MageControl.UI.BuffDisplay = {
    frames = {},
    isLocked = true,
    updateInterval = 0.1,
    lastUpdate = 0,
    iconPlaceholder = "Interface\\Icons\\INV_Misc_QuestionMark",

    trackedBuffs = {
        "Arcane Power",
        "Mind Quickening",
        "Enlightened State",
        "Arcane Rupture",
        "Wisdom of the Mak'aru"
    },

    defaultPositions = {
        ["Arcane Power"] = { x = 100, y = -100 },
        ["Mind Quickening"] = { x = 100, y = -140 },
        ["Enlightened State"] = { x = 100, y = -180 },
        ["Arcane Rupture"] = { x = 100, y = -220 },
        ["Wisdom of the Mak'aru"] = { x = 100, y = -260 }
    }
}

local createBuffFrame = function(buffName)
    local frameName = "MageControlBuff_" .. string.gsub(buffName, " ", "")
    local frame = CreateFrame("Frame", frameName, UIParent)

    frame:SetWidth(48)
    frame:SetHeight(48)
    frame:SetFrameStrata("HIGH")

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetWidth(32)
    frame.icon:SetHeight(32)
    frame.icon:SetPoint("CENTER", frame, "CENTER", 0, 0)

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetVertexColor(0, 0, 0, 0.8)

    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetAllPoints(frame)
    frame.border:SetVertexColor(1, 1, 1, 0.8)

    frame.timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.timerText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.timerText:SetTextColor(1, 1, 1, 1)
    frame.timerText:SetText("0")

    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.nameText:SetPoint("CENTER", frame, "CENTER", 0, -10)
    frame.nameText:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.nameText:SetText(buffName)
    frame.nameText:Hide()

    frame.stackText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.stackText:SetPoint("BOTTOMLEFT", frame.icon, "BOTTOMLEFT", 2, 2)
    frame.stackText:SetTextColor(1, 1, 1, 1)
    frame.stackText:SetText("")

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function()
        if not MageControl.UI.BuffDisplay.isLocked then
            this:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function()
        if not MageControl.UI.BuffDisplay.isLocked then
            this:StopMovingOrSizing()

            local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
            MageControlDB.buffPositions[buffName] = { x = xOfs, y = yOfs }
        end
    end)

    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(buffName)
        if not MageControl.UI.BuffDisplay.isLocked then
            GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local pos = MageControlDB.buffPositions[buffName] or MageControl.UI.BuffDisplay.defaultPositions[buffName]
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)

    frame:Hide()

    return frame
end

local initializeBuffFrames = function()
    for _, buffName in ipairs(MageControl.UI.BuffDisplay.trackedBuffs) do
        if not MageControl.UI.BuffDisplay.frames[buffName] then
            MageControl.UI.BuffDisplay.frames[buffName] = createBuffFrame(buffName)
        end
    end
end

local updateBuffDisplay = function(buffName, frame)
    -- Debug: Check what's preventing updates
    if not MC then
        MageControl.Logger.debug("MC not available for buff display", "BuffDisplay")
        return
    end
    if not MageControl.StateManager.current.CURRENT_BUFFS then
        MageControl.Logger.debug("MageControl.StateManager.current.CURRENT_BUFFS not available for buff display", "BuffDisplay")
        return
    end
    if not MageControl.UI.BuffDisplay.isLocked then
        -- Frames are unlocked (config mode), don't show real buff data
        return
    end

    local buff = nil
    for _, buffData in ipairs(MageControl.StateManager.current.CURRENT_BUFFS) do
        if buffData.name == buffName then
            buff = buffData
            break
        end
    end

    if buff then
        local timeLeft = buff:duration()
        if timeLeft > 0 then
            frame:Show()
            frame.icon:SetTexture(buff.icon)
            if timeLeft >= 60 then
                frame.timerText:SetText(string.format("%.0fm", timeLeft / 60))
            else
                frame.timerText:SetText(string.format("%.0f", timeLeft))
            end

            if timeLeft <= 3 then
                frame.timerText:SetTextColor(1, 0.2, 0.2, 1) -- red
            elseif timeLeft <= 10 then
                frame.timerText:SetTextColor(1, 1, 0.2, 1) -- yellow
            else
                frame.timerText:SetTextColor(0.2, 1, 0.2, 1) -- green
            end

            if buff.stacks and buff.stacks > 1 then
                frame.stackText:SetText(buff.stacks)
                frame.stackText:Show()
            else
                frame.stackText:Hide()
            end
        else
            frame:Hide()
        end
    else
        frame:Hide()
    end
end

local updateAllBuffDisplays = function()
    for buffName, frame in pairs(MageControl.UI.BuffDisplay.frames) do
        updateBuffDisplay(buffName, frame)
    end
end

MageControl.UI.BuffDisplay.lockFrames = function()
    MageControl.UI.BuffDisplay.isLocked = true
    MageControlDB.buffDisplayLocked = MageControl.UI.BuffDisplay.isLocked
    for buffName, frame in pairs(MageControl.UI.BuffDisplay.frames) do
        frame.nameText:Hide()
    end
end

MageControl.UI.BuffDisplay.unlockFrames = function()
    MageControl.UI.BuffDisplay.isLocked = false
    MageControlDB.buffDisplayLocked = MageControl.UI.BuffDisplay.isLocked
    for buffName, frame in pairs(MageControl.UI.BuffDisplay.frames) do
        frame.nameText:Show()
        frame.icon:SetTexture(MageControl.UI.BuffDisplay.iconPlaceholder)
        frame.timerText:SetText("0")
        frame:Show()
    end
end

MageControl.UI.BuffDisplay.toggleLock = function()
    MageControl.UI.BuffDisplay.isLocked = not MageControl.UI.BuffDisplay.isLocked
    MageControlDB.buffDisplayLocked = MageControl.UI.BuffDisplay.isLocked

    if MageControl.UI.BuffDisplay.isLocked then
        MageControl.UI.BuffDisplay.lockFrames()
    else
        MageControl.UI.BuffDisplay.unlockFrames()
    end

    if MageControl.UI.BuffDisplay.isLocked then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Buff-Frame locked", 1.0, 1.0, 0.0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Buff-Frame unlocked - Drag to move", 1.0, 1.0, 0.0)
    end
end

MageControl.UI.BuffDisplay.resetPositions = function()
    MageControlDB.buffPositions = MageControlDB.buffPositions or {}
    for buffName, defaultPos in pairs(MageControl.UI.BuffDisplay.defaultPositions) do
        MageControlDB.buffPositions[buffName] = { x = defaultPos.x, y = defaultPos.y }
        if MageControl.UI.BuffDisplay.frames[buffName] then
            MageControl.UI.BuffDisplay.frames[buffName]:ClearAllPoints()
            MageControl.UI.BuffDisplay.frames[buffName]:SetPoint("CENTER", UIParent, "CENTER", defaultPos.x, defaultPos.y)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Buff-Position reset", 1.0, 1.0, 0.0)
end

MageControl.UI.BuffDisplay.initBuffFrames = function()
    initializeBuffPositions()
    initializeBuffFrames()
    MageControl.UI.BuffDisplay.lockFrames()
    MageControl.UpdateManager.registerUpdateFunction(updateAllBuffDisplays, 0.2)
end