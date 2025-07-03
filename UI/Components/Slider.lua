MC.createSlider = function(parentFrame, relativePointFrame, label, minValue, maxValue, step, defaultValue, dbKey, verticalDistance, valuePrefix, valueSuffix)
    local slider = CreateFrame("Slider", nil, parentFrame, "OptionsSliderTemplate")
    slider:SetWidth(200)
    slider:SetHeight(20)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetValue(defaultValue)
    slider:SetPoint("TOP", relativePointFrame, "BOTTOM", 0, verticalDistance)

    local sliderLabel = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sliderLabel:SetPoint("BOTTOM", slider, "TOP", 0, 5)
    sliderLabel:SetText(label)
    sliderLabel:SetTextColor(0.8, 0.9, 1, 1)

    local valueDisplay = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    valueDisplay:SetPoint("TOP", slider, "BOTTOM", 0, -5)
    valueDisplay:SetText(valuePrefix .. tostring(defaultValue) .. valueSuffix)
    valueDisplay:SetTextColor(0.9, 0.9, 0.9, 1)

    slider:SetScript("OnValueChanged", function()
        local v = math.floor(this:GetValue() + 0.5)
        valueDisplay:SetText(valuePrefix .. v .. valueSuffix)
        MageControlDB[dbKey] = v
    end)

    return slider
end