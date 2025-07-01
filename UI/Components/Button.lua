MC.applyModernButtonStyle = function(button, color)
    color = color or {r=0.2, g=0.5, b=0.8}

    -- Button-Hintergrund und Rahmen anpassen
    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    button:GetNormalTexture():SetVertexColor(color.r, color.g, color.b, 0.7)

    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    button:GetHighlightTexture():SetAlpha(0.5)

    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    button:GetPushedTexture():SetVertexColor(color.r, color.g, color.b, 0.85)

    -- Text-Stil anpassen
    local text = button:GetFontString()
    if text then
        text:SetTextColor(1, 1, 1)
        text:SetShadowOffset(1, -1)
        text:SetShadowColor(0, 0, 0, 0.8)
    end

    -- Hover-Effekte
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

    -- Klick-Effekt
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