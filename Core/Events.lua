-- Events handler for MageControl unified system
-- All MC.* references converted to MageControl.* expert modules

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
        MageControl.ConfigValidation.initializeSettings()
        MageControl.UI.BuffDisplay.initBuffFrames()
        MageControl.UI.ActionDisplay.initActionFrames()
        MageControl.Logger.info("MageControl loaded.", "Events")

    elseif event == "SPELLCAST_CHANNEL_START" then
        MageControl.StateManager.current.isChanneling = true
        MageControl.StateManager.current.channelFinishTime = GetTime() + ((arg1 - 0)/1000)
        MageControl.StateManager.current.channelDurationInSeconds = MageControl.StateManager.current.channelFinishTime - GetTime()
        MageControl.StateManager.current.expectedCastFinishTime = MageControl.StateManager.current.channelFinishTime
        MageControl.StateManager.current.CURRENT_BUFFS = MageControl.StateManager.getBuffs()
        MageControl.ArcaneSpecific.ARCANE_MISSILES_FIRE_TIMES = MageControl.ArcaneSpecific.calculateArcaneMissileFireTimes(arg1)

    elseif event == "SPELLCAST_CHANNEL_STOP" then
        MageControl.StateManager.current.isChanneling = false
        MageControl.StateManager.current.expectedCastFinishTime = 0

    elseif event == "SPELLCAST_START" then
        if arg1 == "Arcane Rupture" then
            MageControl.StateManager.current.isCastingArcaneRupture = true
            MageControl.StateManager.current.expectedCastFinishTime = GetTime() + (arg2/1000)
        end

    elseif event == "SPELLCAST_STOP" then
        MageControl.StateManager.current.isCastingArcaneRupture = false
        MageControl.StateManager.current.expectedCastFinishTime = GetTime()

    elseif event == "SPELL_CAST_EVENT" then
        MageControl.StateManager.current.lastSpellCast = MageControl.StringUtils.getSpellNameById(arg2)
        MageControl.Logger.debug("Spell cast: " .. tostring(MageControl.StateManager.current.lastSpellCast) .. " with ID: " .. tostring(arg2), "Events")
        MageControl.StateManager.current.globalCooldownActive = true
        MageControl.StateManager.current.globalCooldownStart = GetTime()
        MageControl.StateManager.current.expectedCastFinishTime = GetTime() + MageControl.ConfigDefaults.values.timing.GLOBAL_COOLDOWN_IN_SECONDS

        if (MageControl.SpellData.SPELL_INFO.ARCANE_SURGE.id == arg2) then
            MageControl.StateManager.current.surgeActiveTill = 0
        end

    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        MageControl.StateManager.current.isChanneling = false
        MageControl.StateManager.current.isCastingArcaneRupture = false
        MageControl.StateManager.current.expectedCastFinishTime = 0

        local earliestAllowedTimeToRepeatSpell = MageControl.StateManager.current.lastRuptureRepeatTime + 1
        if (MageControl.StateManager.current.lastSpellCast == "Arcane Rupture" and (earliestAllowedTimeToRepeatSpell <= GetTime())) then
            MageControl.StateManager.current.lastRuptureRepeatTime = GetTime()
            MageControl.Logger.debug("Arcane Rupture failed, repeating cast", "Events")
            MageControl.RotationEngine.executeArcaneRotation()
        end
    elseif event == "PLAYER_AURAS_CHANGED" then
        MageControl.Logger.debug("Player auras changed, updating buffs", "Events")
        MageControl.StateManager.current.CURRENT_BUFFS = MageControl.StateManager.getBuffs()
        MageControl.Core.UpdateManager.forceUpdate()
    elseif event == "PLAYER_TARGET_CHANGED" then
        MageControl.Logger.debug("Player target changed, updating current target", "Events")
        MageControl.StateManager.updateCurrentTarget()
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        --if not (MageControl.StateManager.current.lastSpellHitTime + 0.1 > GetTime()) then
        if string.find(arg1, "resisted") then
            MageControl.StateManager.current.surgeActiveTill = GetTime() + 3.9
        end
        --MageControl.StateManager.current.lastSpellHitTime = GetTime()
        --end
    end

    MageControlFrame:SetScript("OnUpdate", function()
        MageControl.Core.UpdateManager.update()
    end)
end)