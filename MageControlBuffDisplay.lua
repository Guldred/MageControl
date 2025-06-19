local BuffDisplay = {
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

local function initializeBuffPositions()
    if not MageControlDB.buffPositions then
        MageControlDB.buffPositions = {}
        for buffName, pos in pairs(BuffDisplay.defaultPositions) do
            MageControlDB.buffPositions[buffName] = { x = pos.x, y = pos.y }
        end
    end

    if MageControlDB.buffDisplayLocked == nil then
        MageControlDB.buffDisplayLocked = true
    end
    BuffDisplay.isLocked = MageControlDB.buffDisplayLocked
end

local function createBuffFrame(buffName)
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
        if not BuffDisplay.isLocked then
            this:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function()
        if not BuffDisplay.isLocked then
            this:StopMovingOrSizing()

            local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
            MageControlDB.buffPositions[buffName] = { x = xOfs, y = yOfs }
        end
    end)

    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(buffName)
        if not BuffDisplay.isLocked then
            GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local pos = MageControlDB.buffPositions[buffName] or BuffDisplay.defaultPositions[buffName]
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)

    frame:Hide()

    return frame
end

local function initializeBuffFrames()
    for _, buffName in ipairs(BuffDisplay.trackedBuffs) do
        if not BuffDisplay.frames[buffName] then
            BuffDisplay.frames[buffName] = createBuffFrame(buffName)
        end
    end
end


local function updateBuffDisplay(buffName, frame)
    if not MC or not MC.CURRENT_BUFFS or not BuffDisplay.isLocked then return end

    local buff = nil
    for _, buffData in ipairs(MC.CURRENT_BUFFS) do
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
            elseif timeLeft >= 10 then
                frame.timerText:SetText(string.format("%.0f", timeLeft))
            else
                frame.timerText:SetText(string.format("%.1f", timeLeft))
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

local function updateAllBuffDisplays()
    for buffName, frame in pairs(BuffDisplay.frames) do
        updateBuffDisplay(buffName, frame)
    end
end

function lockFrames()
    BuffDisplay.isLocked = true
    MageControlDB.buffDisplayLocked = BuffDisplay.isLocked
    for buffName, frame in pairs(BuffDisplay.frames) do
        frame.nameText:Hide()
    end
end

function unlockFrames()
    BuffDisplay.isLocked = false
    MageControlDB.buffDisplayLocked = BuffDisplay.isLocked
    for buffName, frame in pairs(BuffDisplay.frames) do
        frame.nameText:Show()
        frame.icon:SetTexture(BuffDisplay.iconPlaceholder)
        frame.timerText:SetText("0")
        frame:Show()
    end
end

function BuffDisplay_ToggleLock()
    BuffDisplay.isLocked = not BuffDisplay.isLocked
    MageControlDB.buffDisplayLocked = BuffDisplay.isLocked

    if BuffDisplay.isLocked then
        lockFrames()
    else
        unlockFrames()
    end

    if BuffDisplay.isLocked then
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Buff-Frame locked", 1.0, 1.0, 0.0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("MageControl: Buff-Frame unlocked - Drag to move", 1.0, 1.0, 0.0)
    end
end

function BuffDisplay_ResetPositions()
    for buffName, defaultPos in pairs(BuffDisplay.defaultPositions) do
        MageControlDB.buffPositions[buffName] = { x = defaultPos.x, y = defaultPos.y }
        if BuffDisplay.frames[buffName] then
            BuffDisplay.frames[buffName]:ClearAllPoints()
            BuffDisplay.frames[buffName]:SetPoint("CENTER", UIParent, "CENTER", defaultPos.x, defaultPos.y)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("MageControl: Buff-Position reset", 1.0, 1.0, 0.0)
end

local BuffDisplayFrame = CreateFrame("Frame")
BuffDisplayFrame:RegisterEvent("ADDON_LOADED")
BuffDisplayFrame:RegisterEvent("PLAYER_AURAS_CHANGED")

BuffDisplayFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "MageControl" then
        initializeBuffPositions()
        initializeBuffFrames()
        lockFrames()
        MC.registerUpdateFunction(updateAllBuffDisplays, 0.2)
    elseif event == "PLAYER_AURAS_CHANGED" then
        MC.forceUpdate()
    end
end)
