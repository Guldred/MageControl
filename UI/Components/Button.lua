MC.applyModernButtonStyle = function(button, color)
    color = color or {r=0.2, g=0.5, b=0.8}

    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    button:GetNormalTexture():SetVertexColor(color.r, color.g, color.b, 0.7)

    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    button:GetHighlightTexture():SetAlpha(0.5)

    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    button:GetPushedTexture():SetVertexColor(color.r, color.g, color.b, 0.85)

    local text = button:GetFontString()
    if text then
        text:SetTextColor(1, 1, 1)
        text:SetShadowOffset(1, -1)
        text:SetShadowColor(0, 0, 0, 0.8)
    end

    button:SetScript("OnEnter", function()
        if button:IsEnabled() then
            button:GetNormalTexture():SetVertexColor(color.r + 0.1, color.g + 0.1, color.b + 0.1, 0.9)
            if text then
                text:SetTextColor(1, 1, 1)
            end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(button:GetText())
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        button:GetNormalTexture():SetVertexColor(color.r, color.g, color.b, 0.7)
        if text then
            text:SetTextColor(1, 1, 1)
        end
        GameTooltip:Hide()
    end)

    button:SetScript("OnMouseDown", function()
        if button:IsEnabled() then
            if text then
                text:SetPoint("CENTER", 1, -1)
            end
        end
    end)

    button:SetScript("OnMouseUp", function()
        if button:IsEnabled() then
            if text then
                text:SetPoint("CENTER", 0, 0)
            end
        end
    end)
end

MC.createTabButton = function(parent, id, text, width, height)
    local tabButton = CreateFrame("Button", "MageControlTab"..id, parent)
    tabButton:SetID(id)
    tabButton:SetWidth(width or 100)
    tabButton:SetHeight(height or 25)

    tabButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })

    tabButton:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
    tabButton:SetBackdropBorderColor(0.4, 0.5, 0.7, 0.7)

    local tabText = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabButton.text = tabText
    tabText:SetPoint("CENTER", 0, 0)
    tabText:SetText(text)
    tabText:SetTextColor(0.8, 0.8, 0.8, 1)

    function tabButton:SetActive()
        local bd = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 0 }
        }
        self:SetBackdrop(bd)
        self:SetBackdropColor(0.2, 0.2, 0.3, 1.0)
        self:SetBackdropBorderColor(0.6, 0.7, 0.9, 1.0)
        self.text:SetTextColor(1, 1, 1, 1)
    end

    function tabButton:SetInactive()
        local bd = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        }
        self:SetBackdrop(bd)
        self:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
        self:SetBackdropBorderColor(0.4, 0.5, 0.7, 0.7)
        self.text:SetTextColor(0.8, 0.8, 0.8, 1)
    end

    tabButton:SetScript("OnEnter", function()
        if this.isActive ~= true then
            this:SetBackdropColor(0.15, 0.15, 0.25, 0.9)
        end
    end)

    tabButton:SetScript("OnLeave", function()
        if this.isActive ~= true then
            this:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
        end
    end)

    return tabButton
end

MC.setupTabSystem = function(parent, tabContainer, tabInfo)
    local tabs = {}
    local tabButtons = {}

    for i, info in ipairs(tabInfo) do
        tabs[i] = CreateFrame("Frame", parent:GetName().."Tab"..i, tabContainer)
        tabs[i]:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 10, -10)
        tabs[i]:SetPoint("BOTTOMRIGHT", tabContainer, "BOTTOMRIGHT", -10, 10)
        tabs[i]:Hide()

        local tabButton = MC.createTabButton(parent, i, info.title)

        if i == 1 then
            tabButton:SetPoint("BOTTOMLEFT", tabContainer, "TOPLEFT", 6, 0)
        else
            tabButton:SetPoint("LEFT", tabButtons[i-1], "RIGHT", 2, 0)
        end

        tabButtons[i] = tabButton
        tabButton.isActive = (i == 1)
    end

    for i = 1, table.getn(tabButtons) do
        tabButtons[i]:SetScript("OnClick", function()
            for j = 1, table.getn(tabs) do
                tabs[j]:Hide()
                tabButtons[j]:SetInactive()
                tabButtons[j].isActive = false
            end
            tabs[this:GetID()]:Show()
            this:SetActive()
            this.isActive = true
        end)
    end

    tabs[1]:Show()
    tabButtons[1]:SetActive()

    return {
        tabs = tabs,
        buttons = tabButtons
    }
end