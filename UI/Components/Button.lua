MC.applyModernButtonStyle = function(button, color)
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