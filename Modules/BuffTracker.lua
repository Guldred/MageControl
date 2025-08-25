-- BuffTracker converted to MageControl.StateManager unified system
-- All MC.* references converted to MageControl.* expert modules

MageControl.StateManager.getBuffs = function()
    local now = GetTime()
    if MageControl.StateManager.state.buffsCache and (now - MageControl.StateManager.state.buffsCacheTime < 0.1) then
        MageControl.Logger.debug("Returning Cached buffs!", "BuffTracker")
        return MageControl.StateManager.state.buffsCache
    end
    local buffs = {}
    local relevantBuffs = {
        [MageControl.BuffData.BUFF_INFO.CLEARCASTING.name] = true,
        [MageControl.BuffData.BUFF_INFO.TEMPORAL_CONVERGENCE.name] = true,
        [MageControl.BuffData.BUFF_INFO.ARCANE_POWER.name] = true,
        [MageControl.BuffData.BUFF_INFO.MIND_QUICKENING.name] = true,
        [MageControl.BuffData.BUFF_INFO.ENLIGHTENED_STATE.name] = true,
        [MageControl.BuffData.BUFF_INFO.SULFURON_BLAZE.name] = true,
        [MageControl.BuffData.BUFF_INFO.WISDOM_OF_THE_MAKARU.name] = true
    }

    for i = 0, 31 do
        local buffIndex = GetPlayerBuff(i, "HELPFUL|PASSIVE")
        if buffIndex >= 0 then
            local buffId = GetPlayerBuffID(buffIndex, "HELPFUL|PASSIVE")
            local buffName = MageControl.StringUtils.getBuffNameByID(buffId)
            local stacks = GetPlayerBuffApplications(buffIndex, "HELPFUL|PASSIVE") or 1
            local icon = GetPlayerBuffTexture(buffIndex, "HELPFUL|PASSIVE") or "Interface\\Icons\\INV_Misc_QuestionMark"

            --MageControl.Logger.debug("Checking buff: " .. buffName .. " with ID: " .. tostring(buffId) .. " has " .. tostring(stacks) .. " stacks and icon: " .. tostring(icon), "BuffTracker")

            if relevantBuffs[buffName] then
                local duration = GetPlayerBuffTimeLeft(buffIndex, "HELPFUL|PASSIVE")
                table.insert(buffs, {
                    name = buffName,
                    stacks = stacks,
                    icon = icon,
                    timeFinished = GetTime() + duration,
                    duration = function(self)
                        return self.timeFinished - GetTime()
                    end,
                    durationAfterCurrentSpellCast = function(self)
                        return MageControl.TimingCalculations.calculateRemainingTimeAfterCurrentCast(self:duration())
                    end
                })
            end
        end
    end

    for i = 0, 31 do
        local buffIndex = GetPlayerBuff(i, "HARMFUL")
        if buffIndex >= 0 then
            local buffId = GetPlayerBuffID(buffIndex, "HARMFUL")
            local buffName = MageControl.StringUtils.getBuffNameByID(buffId)
            local stacks = GetPlayerBuffApplications(buffIndex, "HARMFUL") or 1
            local icon = GetPlayerBuffTexture(buffIndex, "HARMFUL") or "Interface\\Icons\\INV_Misc_QuestionMark"

            MageControl.Logger.debug("Checking debuff: " .. buffName .. " with ID: " .. tostring(buffId) .. " has " .. tostring(stacks) .. " stacks", "BuffTracker")

            if buffName == MageControl.BuffData.BUFF_INFO.ARCANE_RUPTURE.name then
                local duration = GetPlayerBuffTimeLeft(buffIndex, "HARMFUL")
                table.insert(buffs, {
                    name = buffName,
                    stacks = stacks,
                    icon = icon,
                    timeFinished = GetTime() + duration,
                    duration = function(self)
                        return self.timeFinished - GetTime()
                    end,
                    durationAfterCurrentSpellCast = function(self)
                        return MageControl.TimingCalculations.calculateRemainingTimeAfterCurrentCast(self:duration())
                    end
                })
            end
        end
    end

    MageControl.StateManager.state.buffsCache = buffs
    MageControl.StateManager.state.buffsCacheTime = now
    return buffs
end

MageControl.StateManager.findBuff = function(buffs, buffName)
    for i, buff in ipairs(buffs) do
        if buff.name == buffName then
            return buff
        end
    end
    return nil
end