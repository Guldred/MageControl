SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

SlashCmdList["MAGECONTROL"] = function(msg)
    local command = string.lower(msg)

    if command == "atk" then
        print("Empty")
    elseif command == "arcane" then
        print("Empty")
    else
        print("MageControl: Unknown command. Available commands: arcane")
    end
end

local FIREBLAST_ID = 10199
local ARCANE_SURGE_ID = 51936

local lastTimeCast = 0;


local MageControlFrame = CreateFrame("Frame")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
MageControlFrame:RegisterEvent("SPELLCAST_START")
MageControlFrame:RegisterEvent("SPELLCAST_STOP")
MageControlFrame:RegisterEvent("SPELL_CAST_EVENT")

MageControlFrame:SetScript("OnEvent", function()
    if event == "SPELLCAST_CHANNEL_START" then
        print("SPELLCAST_CHANNEL_START")
        print(arg1 .. " " .. arg2)
        --arg1 = castTime, arg2 = "Channeling"
    elseif event == "SPELLCAST_START" then
        print("SPELLCAST_START")
        print(arg1 .. " " .. arg2)
        --arg1 = name, arg2 = castTime
    elseif event == "SPELL_CAST_EVENT" then
        print("SPELL_CAST_EVENT")
        print(arg1 .. " " .. arg2 .. " " .. arg3 .. " " .. arg4 .. " " .. arg5)
        -- arg2 = spellId 
        --> FireBlast = 10199
        --> Arcane Surge = 51936
   end  
end)

MageControlFrame:SetScript("OnUpdate", function(self, elapsed)
    local castId,visId,autoId,casting,channeling,onswing,autoattack=GetCurrentCastingInfo();
    --print(castId);
    --print(visId);
    --print(autoId);
    --print(casting);
    --print(channeling);
    --print(onswing);
    --print(autoattack);
    if (GetTime() - lastTimeCast > 5) then
        testCast()
        lastTimeCast = GetTime();
    end
end)

function testCast()
    print("Trying to cast Frostbolt")
    QueueSpellByName("Frostbolt");
end