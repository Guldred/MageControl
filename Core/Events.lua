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
        -- Step 1: Register all modules now that all files are guaranteed loaded
        MageControl.ModuleRegistration.registerAllModules()
        
        -- Step 2: Initialize ConfigValidation first to populate current.timing structure
        MageControl.ConfigValidation.initialize()
        MageControl.ConfigValidation.initializeSettings()
        
        -- Step 3: Initialize UI components
        MageControl.UI.BuffDisplay.initBuffFrames()
        MageControl.UI.ActionDisplay.initActionFrames()
        
        MageControl.Logger.info("MageControl loaded with event-driven initialization.", "Events")

    elseif event == "SPELLCAST_CHANNEL_START" then
        MageControl.StateManager.state.isChanneling = true
        MageControl.StateManager.state.channelFinishTime = GetTime() + ((arg1 - 0)/1000)
        MageControl.StateManager.state.channelDurationInSeconds = MageControl.StateManager.state.channelFinishTime - GetTime()
        MageControl.StateManager.state.expectedCastFinishTime = MageControl.StateManager.state.channelFinishTime
        MageControl.StateManager.state.CURRENT_BUFFS = MageControl.StateManager.getBuffs()
        MageControl.ArcaneSpecific.ARCANE_MISSILES_FIRE_TIMES = MageControl.ArcaneSpecific.calculateArcaneMissileFireTimes(arg1)

    elseif event == "SPELLCAST_CHANNEL_STOP" then
        MageControl.StateManager.state.isChanneling = false
        MageControl.StateManager.state.expectedCastFinishTime = 0

    elseif event == "SPELLCAST_START" then
        if arg1 == "Arcane Rupture" then
            MageControl.StateManager.state.isCastingArcaneRupture = true
            MageControl.StateManager.state.expectedCastFinishTime = GetTime() + (arg2/1000)
        end

    elseif event == "SPELLCAST_STOP" then
        MageControl.StateManager.state.isCastingArcaneRupture = false
        MageControl.StateManager.state.expectedCastFinishTime = GetTime()

    elseif event == "SPELL_CAST_EVENT" then
        MageControl.StateManager.state.lastSpellCast = MageControl.StringUtils.getSpellNameById(arg2)
        MageControl.Logger.debug("Spell cast: " .. tostring(MageControl.StateManager.state.lastSpellCast) .. " with ID: " .. tostring(arg2), "Events")
        MageControl.StateManager.state.globalCooldownActive = true
        MageControl.StateManager.state.globalCooldownStart = GetTime()
        MageControl.StateManager.state.expectedCastFinishTime = GetTime() + MageControl.ConfigDefaults.values.timing.GLOBAL_COOLDOWN_IN_SECONDS

        if (MageControl.SpellData.SPELL_INFO.ARCANE_SURGE.id == arg2) then
            MageControl.StateManager.state.surgeActiveTill = 0
        end

    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        MageControl.StateManager.state.isChanneling = false
        MageControl.StateManager.state.isCastingArcaneRupture = false
        MageControl.StateManager.state.expectedCastFinishTime = 0

        local earliestAllowedTimeToRepeatSpell = MageControl.StateManager.state.lastRuptureRepeatTime + 1
        if (MageControl.StateManager.state.lastSpellCast == "Arcane Rupture" and (earliestAllowedTimeToRepeatSpell <= GetTime())) then
            MageControl.StateManager.state.lastRuptureRepeatTime = GetTime()
            MageControl.Logger.debug("Arcane Rupture failed, repeating cast", "Events")
            MageControl.RotationEngine.executeArcaneRotation()
        end
    elseif event == "PLAYER_AURAS_CHANGED" then
        MageControl.Logger.debug("Player auras changed, updating buffs", "Events")
        MageControl.StateManager.state.CURRENT_BUFFS = MageControl.StateManager.getBuffs()
        MageControl.Core.UpdateManager.forceUpdate()
    elseif event == "PLAYER_TARGET_CHANGED" then
        MageControl.Logger.debug("Player target changed, updating current target", "Events")
        MageControl.StateManager.updateCurrentTarget()
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        --if not (MageControl.StateManager.state.lastSpellHitTime + 0.1 > GetTime()) then
        if string.find(arg1, "resisted") then
            MageControl.StateManager.state.surgeActiveTill = GetTime() + 3.9
        end
        --MageControl.StateManager.state.lastSpellHitTime = GetTime()
        --end
    end

    MageControlFrame:SetScript("OnUpdate", function()
        MageControl.Core.UpdateManager.update()
    end)
end)