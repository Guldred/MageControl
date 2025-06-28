local MageControlFrame = CreateFrame("Frame")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
MageControlFrame:RegisterEvent("SPELLCAST_START")
MageControlFrame:RegisterEvent("SPELLCAST_STOP")
MageControlFrame:RegisterEvent("SPELL_CAST_EVENT")
MageControlFrame:RegisterEvent("SPELLCAST_FAILED")
MageControlFrame:RegisterEvent("SPELLCAST_INTERRUPTED")
MageControlFrame:RegisterEvent("ADDON_LOADED")
MageControlFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
MageControlFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
MageControlFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

MageControlFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "MageControl" then
        MC.initializeSettings()
        MC.initBuffFrames()
        MC.initActionFrames()
        MC.printMessage("MageControl loaded.")

    elseif event == "SPELLCAST_CHANNEL_START" then
        MC.state.isChanneling = true
        MC.state.channelFinishTime = GetTime() + ((arg1 - 0)/1000)
        MC.state.expectedCastFinishTime = MC.state.channelFinishTime
        MC.CURRENT_BUFFS = MC.getBuffs()

    elseif event == "SPELLCAST_CHANNEL_STOP" then
        MC.state.isChanneling = false
        MC.state.expectedCastFinishTime = 0

    elseif event == "SPELLCAST_START" then
        if arg1 == "Arcane Rupture" then
            MC.state.isCastingArcaneRupture = true
            MC.state.expectedCastFinishTime = GetTime() + (arg2/1000)
        end

    elseif event == "SPELLCAST_STOP" then
        MC.state.isCastingArcaneRupture = false
        MC.state.expectedCastFinishTime = GetTime()

    elseif event == "SPELL_CAST_EVENT" then
        MC.state.lastSpellCast = MC.getSpellNameById(arg2)
        MC.debugPrint("Spell cast: " .. tostring(MC.state.lastSpellCast) .. " with ID: " .. tostring(arg2))
        MC.state.globalCooldownActive = true
        MC.state.globalCooldownStart = GetTime()
        MC.state.expectedCastFinishTime = GetTime() + MC.GLOBAL_COOLDOWN_IN_SECONDS

        if (MC.SPELL_INFO.ARCANE_SURGE.id == arg2) then
            MC.state.surgeActiveTill = 0
        end

    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        MC.state.isChanneling = false
        MC.state.isCastingArcaneRupture = false
        MC.state.expectedCastFinishTime = 0

        local earliestAllowedTimeToRepeatSpell = MC.state.lastRuptureRepeatTime + 1
        if (MC.state.lastSpellCast == "Arcane Rupture" and (earliestAllowedTimeToRepeatSpell <= GetTime())) then
            MC.state.lastRuptureRepeatTime = GetTime()
            MC.debugPrint("Arcane Rupture failed, repeating cast")
            MC.executeArcaneRotation()
        end
    elseif event == "PLAYER_AURAS_CHANGED" then
        MC.debugPrint("Player auras changed, updating buffs")
        MC.CURRENT_BUFFS = MC.getBuffs()
        MC.forceUpdate()
    elseif event == "PLAYER_TARGET_CHANGED" then
        MC.debugPrint("Player target changed, updating current target")
        MC.updateCurrentTarget()
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        if string.sub(arg1, -9) == "resisted)" then
            MC.state.surgeActiveTill = GetTime() + 3.9
        end
    end

    MageControlFrame:SetScript("OnUpdate", function()
        MC.OnUpdate()
    end)
end)