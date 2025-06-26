MC.getBuffs = function()
    local now = GetTime()
    if MC.state.buffsCache and (now - MC.state.buffsCacheTime < 0.1) then
        MC.debugPrint("Returning Cached buffs!")
        return MC.state.buffsCache
    end
    local buffs = {}
    local relevantBuffs = {
        [MC.BUFF_INFO.CLEARCASTING.name] = true,
        [MC.BUFF_INFO.TEMPORAL_CONVERGENCE.name] = true,
        [MC.BUFF_INFO.ARCANE_POWER.name] = true,
        [MC.BUFF_INFO.MIND_QUICKENING.name] = true,
        [MC.BUFF_INFO.ENLIGHTENED_STATE.name] = true,
        [MC.BUFF_INFO.SULFURON_BLAZE.name] = true,
        [MC.BUFF_INFO.WISDOM_OF_THE_MAKARU.name] = true
    }

    for i = 0, 31 do
        local buffIndex = GetPlayerBuff(i, "HELPFUL|PASSIVE")
        if buffIndex >= 0 then
            local buffId = GetPlayerBuffID(buffIndex, "HELPFUL|PASSIVE")
            local buffName = MC.getBuffNameByID(buffId)
            local stacks = GetPlayerBuffApplications(buffIndex, "HELPFUL|PASSIVE") or 1
            local icon = GetPlayerBuffTexture(buffIndex, "HELPFUL|PASSIVE") or "Interface\\Icons\\INV_Misc_QuestionMark"

            MC.debugPrint("Checking buff: " .. buffName .. " with ID: " .. tostring(buffId) .. " has " .. tostring(stacks) .. " stacks and icon: " .. tostring(icon))

            if relevantBuffs[buffName] then
                local duration = GetPlayerBuffTimeLeft(buffIndex, "HELPFUL|PASSIVE")
                table.insert(buffs, {
                    name = buffName,
                    stacks = stacks,
                    icon = icon,
                    timeFinished = GetTime() + duration,
                    duration = function(self)
                        return self.timeFinished - GetTime()
                    end
                })
            end
        end
    end

    for i = 0, 31 do
        local buffIndex = GetPlayerBuff(i, "HARMFUL")
        if buffIndex >= 0 then
            local buffId = GetPlayerBuffID(buffIndex, "HARMFUL")
            local buffName = MC.getBuffNameByID(buffId)
            local stacks = GetPlayerBuffApplications(buffIndex, "HARMFUL") or 1
            local icon = GetPlayerBuffTexture(buffIndex, "HARMFUL") or "Interface\\Icons\\INV_Misc_QuestionMark"

            MC.debugPrint("Checking debuff: " .. buffName .. " with ID: " .. tostring(buffId) .. " has " .. tostring(stacks) .. " stacks")

            if buffName == MC.BUFF_INFO.ARCANE_RUPTURE.name then
                local duration = GetPlayerBuffTimeLeft(buffIndex, "HARMFUL")
                table.insert(buffs, {
                    name = buffName,
                    stacks = stacks,
                    icon = icon,
                    timeFinished = GetTime() + duration,
                    duration = function(self)
                        return self.timeFinished - GetTime()
                    end
                })
            end
        end
    end

    MC.state.buffsCache = buffs
    MC.state.buffsCacheTime = now
    return buffs
end

MC.findBuff = function(buffs, buffName)
    for i, buff in ipairs(buffs) do
        if buff.name == buffName then
            return buff
        end
    end
    return nil
end