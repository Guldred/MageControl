SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

MC = {
    GLOBAL_COOLDOWN_IN_SECONDS = 1.5,

    TIMING = {
        CAST_FINISH_THRESHOLD = 0.75,
        GCD_REMAINING_THRESHOLD = 0.75,
        GCD_BUFFER = 1.6,
        ARCANE_RUPTURE_MIN_DURATION = 2
    },

    SPELL_INFO = {
        FIREBLAST = {
            id = 10199,
            name = "Fireblast",
            cost = 340
        },
        ARCANE_SURGE = {
            id = 51936,
            name = "Arcane Surge",
            cost = 170
        },
        ARCANE_EXPLOSION = {
            id = 10202,
            name = "Arcane Explosion",
            cost = 390
        },
        ARCANE_MISSILES = {
            id = 25345,
            name = "Arcane Missiles",
            cost = 655
        },
        ARCANE_RUPTURE = {
            id = 51954,
            name = "Arcane Rupture",
            cost = 390
        },
        FROSTBOLT_1 = {
            id = 116,
            name = "Frostbolt (Rank 1)",
            cost = 0
        },
        FROSTBOLT = {
            id = 25304,
            name = "Frostbolt",
            cost = 0
        },
        FIREBALL = {
            id = 25306,
            name = "Fireball",
            cost = 0
        },
        AMP_MAGIC_DEBUFF = {
            id = 8455,
            name = "Amplify Magic",
            cost = 0
        }
    },

    DEFAULT_ACTIONBAR_SLOT = {
        FIREBLAST = 1,
        ARCANE_RUPTURE = 2,
        ARCANE_SURGE = 5
    },

    BUFF_INFO = {
        CLEARCASTING = {
            id   = 12536,
            name = "Clearcasting",
        },
        TEMPORAL_CONVERGENCE = {
            id   = 51961,
            name = "Temporal Convergence",
        },
        ARCANE_POWER = {
            id                        = 12042,
            name                      = "Arcane Power",
            mana_drain_per_second     = 1,
            death_threshold           = 10,
            safety_buffer             = 5,
            proc_cost_percent         = 2,
        },
        ARCANE_RUPTURE = {
            id   = 52502,
            name = "Arcane Rupture",
        },
        MIND_QUICKENING = {
            id   = 23723,
            name = "Mind Quickening",
        },
        WISDOM_OF_THE_MAKARU = {
            id   = 51271,
            name = "Wisdom of the Mak'aru",
        },
        ENLIGHTENED_STATE = {
            id   = 51270,
            name = "Enlightened State",
        },
        SULFURON_BLAZE = {
            id   = 42027,
            name = "Sulfuron Blaze",
        },
    },

    SPELL_MODIFIERS = {
        ARCANE_MISSILES_RUPTURE_MULTIPLIER = 1.25,
        PROC_DAMAGE_COST_PERCENT = 2
    },

    HASTE = {
        HASTE_THRESHOLD = 30,
        BASE_VALUE = 10
    },

    CURRENT_BUFFS = {
    },

    UpdateFunctions = {
    },

    OnUpdate = function()
        for _, func in ipairs(MC.UpdateFunctions) do
            if (GetTime() - func.lastUpdate >= func.interval) then
                func.f()
                func.lastUpdate = GetTime()
            end
        end
    end,

    forceUpdate = function()
        for _, func in ipairs(MC.UpdateFunctions) do
            func.f()
            func.lastUpdate = GetTime()
        end
    end,

    registerUpdateFunction = function(func, interval)
        if type(func) == "function" then
            table.insert(MC.UpdateFunctions, {
                f = func,
                lastUpdate = 0,
                interval = interval or 0.1,
            })
        else
            error("MageControl: registerUpdateFunction expects a function and an interval (optional)")
        end
    end,

    unregisterUpdateFunction = function(func)
        for i, updateFunc in ipairs(MC.UpdateFunctions) do
            if updateFunc.f == func then
                table.remove(MC.UpdateFunctions, i)
                return
            end
        end
        error("MageControl: unregisterUpdateFunction could not find the specified function")
    end,

    DEBUG = false
}

MageControlDB = MageControlDB or {}

local function initializeSettings()
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MC.DEFAULT_ACTIONBAR_SLOT.FIREBLAST,
            ARCANE_RUPTURE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_RUPTURE,
            ARCANE_SURGE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_SURGE
        }
        MageControlDB.haste = {
            BASE_VALUE = MC.HASTE.BASE_VALUE,
            HASTE_THRESHOLD = MC.HASTE.HASTE_THRESHOLD
        }
    end
end

local function getActionBarSlots()
    return MageControlDB.actionBarSlots
end

local function printMessage(text)
    DEFAULT_CHAT_FRAME:AddMessage(text, 1.0, 1.0, 0.0)
end

local state = {
    isChanneling = false,
    channelFinishTime = 0,
    isCastingArcaneRupture = false,
    globalCooldownActive = false,
    globalCooldownStart = 0,
    lastSpellCast = "",
    lastRuptureRepeatTime = 0,
    expectedCastFinishTime = 0,
    -- Buff caching
    buffsCache = nil,
    buffsCacheTime = 0
}

local function debugPrint(message)
    if MC.DEBUG then
        printMessage("MageControl Debug: " .. message)
    end
end

local function isValidActionSlot(slot)
    return slot and slot > 0 and slot <= 120
end

local function getCurrentManaPercent()
    local maxMana = UnitManaMax("player")
    if maxMana and maxMana > 0 then
        return (UnitMana("player") / maxMana) * 100
    else
        return 0
    end
end

local function normSpellName(name)
    if not name then return "" end
    return string.lower(name)
end

local function getSpellCostByName(spellName)
    local normalizedName = normSpellName(spellName)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if normSpellName(spellInfo.name) == normalizedName then
            return spellInfo.cost
        end
    end
    return 0
end

local function getModifiedSpellManaCost(spellName, buffStates)
    if buffStates and buffStates.clearcasting then
        return 0
    end
    local baseCost = getSpellCostByName(spellName)
    if normSpellName(spellName) == "arcane missiles" and buffStates and buffStates.arcaneRupture then
        return baseCost * MC.SPELL_MODIFIERS.ARCANE_MISSILES_RUPTURE_MULTIPLIER
    end

    return baseCost
end

local function getBuffNameByID(buffID)
    for _, info in pairs(MC.BUFF_INFO) do
        if info.id == buffID then
            return info.name
        end
    end

    return "Untracked Buff"
end

local function getSpellCostPercent(spellName, buffStates)
    local manaCost = getModifiedSpellManaCost(spellName, buffStates)
    local maxMana = UnitManaMax("player")
    if maxMana and manaCost and manaCost > 0 then
        return (manaCost / maxMana) * 100
    end
    return 0
end

-- Buff parsing: Caching for 0.1s, updated only if needed
local function getBuffs()
    local now = GetTime()
    if state.buffsCache and (now - state.buffsCacheTime < 0.1) then
        debugPrint("Returning Cached buffs!")
        return state.buffsCache
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
            local buffName = getBuffNameByID(buffId)
            local stacks = GetPlayerBuffApplications(buffIndex, "HELPFUL|PASSIVE") or 1
            local icon = GetPlayerBuffTexture(buffIndex, "HELPFUL|PASSIVE") or "Interface\\Icons\\INV_Misc_QuestionMark"

            debugPrint("Checking buff: " .. buffName .. " with ID: " .. tostring(buffId) .. " has " .. tostring(stacks) .. " stacks and icon: " .. tostring(icon))

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
            local buffName = getBuffNameByID(buffId)
            local stacks = GetPlayerBuffApplications(buffIndex, "HARMFUL") or 1
            local icon = GetPlayerBuffTexture(buffIndex, "HARMFUL") or "Interface\\Icons\\INV_Misc_QuestionMark"

            debugPrint("Checking debuff: " .. buffName .. " with ID: " .. tostring(buffId) .. " has " .. tostring(stacks) .. " stacks")

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

    state.buffsCache = buffs
    state.buffsCacheTime = now
    return buffs
end

local function findBuff(buffs, buffName)
    for i, buff in ipairs(buffs) do
        if buff.name == buffName then
            return buff
        end
    end
    return nil
end

local function getArcanePowerTimeLeft(buffs)
    local arcanePower = findBuff(buffs, MC.BUFF_INFO.ARCANE_POWER.name)
    return arcanePower and arcanePower:duration() or 0
end

local function isSafeToCast(spellName, buffs, buffStates)
    local arcanePowerTimeLeft = getArcanePowerTimeLeft(buffs)

    if arcanePowerTimeLeft <= 0 then
        return true
    end

    local currentManaPercent = getCurrentManaPercent()
    local spellCostPercent = getSpellCostPercent(spellName, buffStates)
    local procCostPercent = 0

    if string.find(spellName, "Arcane") then
        procCostPercent = MC.BUFF_INFO.ARCANE_POWER.proc_cost_percent
    end

    local projectedManaPercent = currentManaPercent - spellCostPercent - procCostPercent
    local safetyThreshold = MC.BUFF_INFO.ARCANE_POWER.death_threshold + MC.BUFF_INFO.ARCANE_POWER.safety_buffer
    if projectedManaPercent < safetyThreshold then
        printMessage(string.format("|cffff0000MageControl WARNING: %s could drop mana to %.1f%% (Death at 10%%) - BLOCKED!|r",
            spellName, projectedManaPercent))
        return false
    end

    return true
end

local function safeQueueSpell(spellName, buffs, buffStates)
    if not spellName or spellName == "" then
        printMessage("MageControl: Invalid spell name")
        return false
    end

    -- If spell name is unknown, debug it
    if getSpellCostByName(spellName) == 0 then
        debugPrint("Unknown spell in safeQueueSpell: [" .. tostring(spellName) .. "]")
    end

    if not isSafeToCast(spellName, buffs, buffStates) then
        debugPrint("Not safe to cast: " .. spellName)
        return false
    end

    debugPrint("Queueing spell: " .. spellName)
    QueueSpellByName(spellName)
    return true
end

local function checkChannelFinished()
    if (state.channelFinishTime < GetTime()) then
        state.isChanneling = false
    end
end

local function getCurrentBuffs(buffs)
    return {
        clearcasting = findBuff(buffs, MC.BUFF_INFO.CLEARCASTING.name),
        temporalConvergence = findBuff(buffs, MC.BUFF_INFO.TEMPORAL_CONVERGENCE.name),
        arcaneRupture = findBuff(buffs, MC.BUFF_INFO.ARCANE_RUPTURE.name),
        arcanePower = findBuff(buffs, MC.BUFF_INFO.ARCANE_POWER.name)
    }
end

local function queueArcaneExplosion()
    local gcdRemaining = MC.GLOBAL_COOLDOWN_IN_SECONDS - (GetTime() - state.globalCooldownStart)
    if(gcdRemaining < MC.TIMING.GCD_REMAINING_THRESHOLD) then
        local buffs = MC.CURRENT_BUFFS
        local buffStates = getCurrentBuffs(buffs)
        safeQueueSpell("Arcane Explosion", buffs, buffStates)
    end
end

local function IsActionSlotCooldownReady(slot)
    if not isValidActionSlot(slot) then
        return false
    end

    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable then
        return false
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    local remaining = (start + duration) - currentTime
    local isJustGlobalCooldown = false
    if remaining > 0 and state.globalCooldownActive then
        local remainingGlobalCd = MC.TIMING.GCD_BUFFER - (GetTime() - state.globalCooldownStart)
        if remainingGlobalCd >= remaining then
            isJustGlobalCooldown = true
        end
    end

    return remaining <= 0 or isJustGlobalCooldown
end

local function getActionSlotCooldownInMilliseconds(slot)
    if not isValidActionSlot(slot) then
        return 0
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    return (start + duration) - currentTime
end

local function isArcaneRuptureOneGlobalAway(slot)
    local cooldown = getActionSlotCooldownInMilliseconds(slot)
    return (cooldown < MC.TIMING.GCD_BUFFER and cooldown > 0)
end

local function getSpellAvailability()
    local slots = getActionBarSlots()
    return {
        arcaneRuptureReady = IsActionSlotCooldownReady(slots.ARCANE_RUPTURE),
        arcaneSurgeReady = IsActionSlotCooldownReady(slots.ARCANE_SURGE),
        fireblastReady = IsActionSlotCooldownReady(slots.FIREBLAST) and 
                        (IsSpellInRange(MC.SPELL_INFO.FIREBLAST.id) == 1)
    }
end

local function shouldWaitForCast()
    local timeToCastFinish = state.expectedCastFinishTime - GetTime()
    return timeToCastFinish > MC.TIMING.CAST_FINISH_THRESHOLD
end

local function getCurrentHasteValue()
    local hastePercent = MageControlDB.haste.BASE_VALUE

    local hasteBuffs = {
        [MC.BUFF_INFO.ARCANE_POWER.name] = 30,
        [MC.BUFF_INFO.MIND_QUICKENING.name] = 33,
        [MC.BUFF_INFO.ENLIGHTENED_STATE.name] = 20,
        [MC.BUFF_INFO.SULFURON_BLAZE.name] = 5
    }

    for buffName, buffHaste in pairs(hasteBuffs) do
        if findBuff(MC.CURRENT_BUFFS, buffName) ~= nil then
            hastePercent = hastePercent + buffHaste
        end
    end

    return hastePercent
end

local function isHighHasteActive()
    local isAboveHasteThreshold = getCurrentHasteValue() > MageControlDB.haste.HASTE_THRESHOLD
    return isAboveHasteThreshold
end

local function handleChannelInterruption(spells, buffStates, buffs)
    if (state.isChanneling and not buffStates.arcaneRupture and spells.arcaneRuptureReady) then
        ChannelStopCastingNextTick()
        if (spells.arcaneSurgeReady) then
            safeQueueSpell("Arcane Surge", buffs, buffStates)
        else
            safeQueueSpell("Arcane Rupture", buffs, buffStates)
        end
        return true
    end
    return false
end

local function isMissilesWorthCasting(buffStates)
    local ruptureBuff = buffStates.arcaneRupture

    if not ruptureBuff then
        return false
    end

    local remainingDuration = ruptureBuff:duration()
    debugPrint("Arcane Rupture remaining duration by calculation: " .. remainingDuration)
    local hastePercent = getCurrentHasteValue() / 100
    local channelTime = 6 / (1 + hastePercent)
    local requiredTime = channelTime * 0.6

    return remainingDuration >= requiredTime
end

executeArcaneRotation = function()
    if (GetTime() - state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        state.globalCooldownActive = false
    end

    local buffs = MC.CURRENT_BUFFS
    local spells = getSpellAvailability()
    local buffStates = getCurrentBuffs(buffs)
    local slots = getActionBarSlots()
    local missilesWorthCasting = isMissilesWorthCasting(buffStates)

    debugPrint("Evaluating spell priority")

    if handleChannelInterruption(spells, buffStates, buffs) then
        return
    end

    if shouldWaitForCast() then
        debugPrint("Ignored input since current cast is more than .75s away from finishing")
        return
    end

    if (spells.arcaneSurgeReady and not isHighHasteActive()) then
        debugPrint("Trying to cast Arcane Surge")
        safeQueueSpell("Arcane Surge", buffs, buffStates)
        return
    end

    if (buffStates.clearcasting and missilesWorthCasting) then
        debugPrint("Clearcasting active and Arcane Missiles worth casting")
        safeQueueSpell("Arcane Missiles", buffs, buffStates)
        return
    end

    if (spells.arcaneRuptureReady and not missilesWorthCasting and not state.isCastingArcaneRupture) then
        debugPrint("Arcane Rupture ready and not casting")
        safeQueueSpell("Arcane Rupture", buffs, buffStates)
        return
    end

    if (missilesWorthCasting) then
        debugPrint("Arcane Missiles worth casting")
        safeQueueSpell("Arcane Missiles", buffs, buffStates)
        return
    end

    if (isArcaneRuptureOneGlobalAway(slots.ARCANE_RUPTURE)) then
        if (spells.arcaneSurgeReady) then
            debugPrint("Arcane Rupture is one GCD away, casting Arcane Surge")
            safeQueueSpell("Arcane Surge", buffs, buffStates)
            return
        elseif (spells.fireblastReady) then
            debugPrint("Arcane Rupture is one GCD away, casting Fire Blast")
            safeQueueSpell("Fire Blast", buffs, buffStates)
            return
        end
    end

    debugPrint("Defaulting to Arcane Missiles")
    safeQueueSpell("Arcane Missiles", buffs, buffStates)
end

local function checkManaWarning(buffs)
    local arcanePowerTimeLeft = getArcanePowerTimeLeft(buffs)
    if arcanePowerTimeLeft > 0 then
        local currentMana = getCurrentManaPercent()
        local projectedMana = currentMana - (arcanePowerTimeLeft * MC.BUFF_INFO.ARCANE_POWER.mana_drain_per_second)

        if projectedMana < 15 and projectedMana > 10 then
            printMessage("|cffffff00MageControl: LOW MANA WARNING - " .. math.floor(projectedMana) .. "% projected!|r")
        end
    end
end

local function stopChannelAndCastSurge()
    local spells = getSpellAvailability()

    if (spells.arcaneSurgeReady) then
        ChannelStopCastingNextTick()
        QueueSpellByName("Arcane Surge")
    end
end

local function showOptionsMenu()
    if MageControlOptionsFrame and MageControlOptionsFrame:IsVisible() then
        MageControlOptionsFrame:Hide()
    else
        MageControlOptions_Show()
    end
end

local function setActionBarSlot(spellType, slot)
    local slotNum = tonumber(slot)
    if not slotNum or not isValidActionSlot(slotNum) then
        printMessage("MageControl: Invalid slot number. Must be between 1 and 120.")
        return
    end

    spellType = string.upper(spellType)
    if MageControlDB.actionBarSlots[spellType] then
        MageControlDB.actionBarSlots[spellType] = slotNum
        printMessage("MageControl: " .. spellType .. " slot set to " .. slotNum)
    else
        printMessage("MageControl: Unknown spell type. Use: FIREBLAST, ARCANE_RUPTURE, or ARCANE_SURGE")
    end
end

local function showCurrentConfig()
    local slots = getActionBarSlots()
    printMessage("MageControl - Current Configuration:")
    printMessage("  Fireblast: Slot " .. slots.FIREBLAST)
    printMessage("  Arcane Rupture: Slot " .. slots.ARCANE_RUPTURE)
    printMessage("  Arcane Surge: Slot " .. slots.ARCANE_SURGE)
end

local function getSpellIdByName(spellName)
    local normalizedName = normSpellName(spellName)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if normSpellName(spellInfo.name) == normalizedName then
            return spellInfo.id
        end
    end
    return nil
end

local function getSpellNameById(spellId)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if spellInfo.id == spellId then
            return spellInfo.name
        end
    end
    return tostring(spellId)
end

local function hasAmplifyMagic()
    if not UnitExists("target") then return false end

    for i = 1, 30 do
        local name, _, _, id = UnitDebuff("target", i)
        if not id then
            break
        end
        debugPrint("Checking debuff: " .. name .. " " .. id)
        if id == MC.SPELL_INFO.AMP_MAGIC_DEBUFF.id then
            return true
        end
    end

    return false
end

local function arcaneRotation()
    MC.CURRENT_BUFFS = getBuffs()
    checkManaWarning(MC.CURRENT_BUFFS)
    checkChannelFinished()
    executeArcaneRotation()
end

local function arcaneIncantagos()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return
    end

    local targetSpellMap = {
        ["Heroic Training Dummy"] = "Fireball",
        ["Expert Training Dummy"] = "Frostbolt",
        ["Red Affinity"] = "Fireball",
        ["Blue Affinity"] = "Frostbolt"
    }

    local spellToQueue = targetSpellMap[targetName]
    if spellToQueue then
        QueueSpellByName(spellToQueue)
    else
        arcaneRotation()
    end
end

local function checkDependencies()
    local output = "Checking SuperWoW... "

    -- Nil-sicher für SUPERWOW_VERSION
    if SUPERWOW_VERSION then
        output = output .. "found Version " .. tostring(SUPERWOW_VERSION)
    else
        output = output .. "not found"
    end

    output = output .. ". Checking Nampower... "

    if GetNampowerVersion and GetNampowerVersion() then
        local major, minor, patch = GetNampowerVersion()

        if major and minor and patch then
            output = output .. "found Version " .. tostring(major) .. "." .. tostring(minor) .. "." .. tostring(patch)
        else
            output = output .. "found (version info incomplete)"
        end
    else
        output = output .. "not found"
    end

    return output
end

local function activateTrinketAndAP()
    local start, duration, enabled = GetInventoryItemCooldown("player", 14)
    if enabled == 0 then
        debugPrint("Trinket has no activation!")
    elseif duration == 0 then
        debugPrint("Activating Trinket")
        UseInventoryItem(14)
    else
        debugPrint("Activating Arcane Power")
        QueueSpellByName("Arcane Power")
    end
end

SlashCmdList["MAGECONTROL"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end

    local command = args[1] or ""

    if command == "explosion" then
        queueArcaneExplosion()
    elseif command == "arcane" then
        arcaneRotation()
    elseif command == "surge" then
        stopChannelAndCastSurge()
    elseif command == "haste" then
        printMessage("Current haste: " .. tostring(getCurrentHasteValue()))
    elseif command == "debug" then
        MC.DEBUG = not MC.DEBUG
        printMessage("MageControl Debug: " .. (MC.DEBUG and "enabled" or "disabled"))
    elseif command == "options" or command == "config" then
        showOptionsMenu()
    elseif command == "set" and args[2] and args[3] then
        setActionBarSlot(args[2], args[3])
    elseif command == "show" then
        showCurrentConfig()
    elseif command == "arcaneinc" then
        arcaneIncantagos()
    elseif command == "trinket" then
        activateTrinketAndAP()
    elseif command == "toggle" then
        BuffDisplay_ToggleLock()
    elseif command == "lock" then
        lockFrames()
    elseif command == "unlock" then
        unlockFrames()
    elseif command == "reset" then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MC.DEFAULT_ACTIONBAR_SLOT.FIREBLAST,
            ARCANE_RUPTURE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_RUPTURE,
            ARCANE_SURGE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_SURGE,
        }
        MageControlDB.haste = {
            BASE_VALUE = MC.HASTE.BASE_VALUE,
            HASTE_THRESHOLD = MC.HASTE.HASTE_THRESHOLD
        }
        BuffDisplay_ResetPositions()
        printMessage("MageControl: Configuration reset to defaults")
    else
        printMessage("MageControl Commands:")
        printMessage("  /mc arcane - Cast arcane attack sequence")
        printMessage("  /mc explosion - Queue arcane explosion")
        printMessage("  /mc options - Show options menu")
        printMessage("  /mc set <spell> <slot> - Set actionbar slot")
        printMessage("  /mc show - Show current configuration")
        printMessage("  /mc reset - Reset to default slots")
        printMessage("  /mc debug - Toggle debug mode")
    end
end

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

MageControlFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "MageControl" then
        initializeSettings()
        printMessage("MageControl loaded. " .. checkDependencies())

    elseif event == "SPELLCAST_CHANNEL_START" then
        state.isChanneling = true
        state.channelFinishTime = GetTime() + ((arg1 - 0)/1000)
        state.expectedCastFinishTime = state.channelFinishTime
        MC.CURRENT_BUFFS = getBuffs()

    elseif event == "SPELLCAST_CHANNEL_STOP" then
        state.isChanneling = false
        state.expectedCastFinishTime = 0

    elseif event == "SPELLCAST_START" then
        if arg1 == "Arcane Rupture" then
            state.isCastingArcaneRupture = true
            state.expectedCastFinishTime = GetTime() + (arg2/1000)
        end

    elseif event == "SPELLCAST_STOP" then
        state.isCastingArcaneRupture = false
        state.expectedCastFinishTime = GetTime()

    elseif event == "SPELL_CAST_EVENT" then
        state.lastSpellCast = getSpellNameById(arg2)
        debugPrint("Spell cast: " .. tostring(state.lastSpellCast) .. " with ID: " .. tostring(arg2))
        state.globalCooldownActive = true
        state.globalCooldownStart = GetTime()
        state.expectedCastFinishTime = GetTime() + MC.GLOBAL_COOLDOWN_IN_SECONDS

    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        state.isChanneling = false
        state.isCastingArcaneRupture = false
        state.expectedCastFinishTime = 0

        local earliestAllowedTimeToRepeatSpell = state.lastRuptureRepeatTime + 1
        if (state.lastSpellCast == "Arcane Rupture" and (earliestAllowedTimeToRepeatSpell <= GetTime())) then
            state.lastRuptureRepeatTime = GetTime()
            debugPrint("Arcane Rupture failed, repeating cast")
            executeArcaneRotation()
        end
    elseif event == "PLAYER_AURAS_CHANGED" then
        debugPrint("Player auras changed, updating buffs")
        MC.CURRENT_BUFFS = getBuffs()
    end

    MageControlFrame:SetScript("OnUpdate", function()
        MC.OnUpdate()
    end)
end)

