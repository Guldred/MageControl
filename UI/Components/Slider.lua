MC.createSlider = function(parentFrame, relativePointFrame, label, minValue, maxValue, step, defaultValue, dbKey)
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