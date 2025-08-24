SuperWoW features list as of 11/04/2024:

Healing appears on floating combat text.
Chatbubbles appear at 60 yard range instead of 20, and they can appear with nameplates activated
Chatbubbles work for raid, bg, whisper chat
Chat links of spells & crafting recipes now supported by client, can be grabbed directly from wowhead.
Fully absorbed damage is now correctly shown in combat log instead of saying "unit absorbs the attack".
Macros character limit increased from 255 to 510.
Your personal buff bar now shows all your buffs including ones that don't normally have an icon.
Added "UNIT_CASTEVENT" event that tracks units cast starts, finishes, interrupts, channels, and swings (differentiates mainhand & offhand) arg1: casterGUID. arg2: targetGUID. arg3: event type ("START", "CAST", "FAIL", "CHANNEL", "MAINHAND", "OFFHAND"). arg4: spell id. arg5: cast duration.
Added "RAW_COMBATLOG" event that signals the RAW version of all combat log events. arg1: original event name. arg2: event text with GUIDs
Raw combat log events are logged into WoWRawCombatLog.txt concurrently with original WoWCombatLog.txt if logging is enabled.
Combat log now appends owner name to combat log messages that have a owned unit such as a pet or totem.
The default event SPELLCAST_START now triggers on ranged weapon abilities like Aimed Shot & Multishot.
Removed range limit on seeing friendly players equipped items. This is to allow addons such as AdvancedVanillaCombatLog to build profiles of raid members without requiring every individual raid member to download a helper addon and communicate the information to each other.
Targeting circle spells such as Blizzard or Flamestrike no longer show the "I can't cast this ability while moving error" to stop from entering their targeting circle mode.
New CVar "BackgroundSound" to enable or disable background sound while tabbed out (default = "0", can be "0" or "1")
New CVar "UncapSounds". set to "1" to remove the hardcoded soundchannels limit. If you want true uncapped sound experience you still have accompany this CVAR with setting "SoundSoftwareChannels" and "SoundMaxHardwareChannels" to a high number (either by lua function, config.wtf edit or using VanillaTweaks)
New CVar "FoV" to set camera field of view (default = "1.57", can be any value from "0.1" to "3.14")
New CVar "SelectionCircleStyle" to set a different appearance for the target circle.
New CVar "LootSparkle" to toggle Sparkling effect on lootable treasure.
Function changes:

CastSpellByName function now can take unit as 2nd argument in addition to true/false OnSelf flag
UnitExists now also returns GUID of unit
UnitDebuff and UnitBuff now additionally return the id of the aura
Using UnitMana("player") as a druid now always returns your current form power and caster form mana at the same time.
frame:GetName(1) can now be used on nameplate frames to return the GUID of the attached unit.
SetRaidTarget now accepts 3rd argument "local" flag to assign a mark to your own client. This allows using target markers while solo.
LootSlot(slotid) that was previously used only to confirm "are you sure you want to loot this item" now has the usage format LootSlot(slotid [, forceloot]). LootSlot(slotid, 1) can now be used to actually loot a slot.
GetContainerItemInfo now returns item's charges instead of stacks if the item is not stackable & has charges. Charges are given as a negative number.
GetWeaponEnchantInfo() now can accept a friendly player (ex: party1) as argument. If used in this way, it gives the name of the temporary enchant on that player's mainhand & offhand. Old functionality is preserved for own player's enchant duration & stacks.
Macros can now be treated by the game as an item or a spell action by starting the macro with: "/tooltip spell:spellid" or "/tooltip item:itemid" respectively.
GetActionCount, GetActionCooldown, and ActionIsConsumable now work for macros returning the result of the linked spell or item. For example, you can create a macro that starts with "/tooltip item:18641" and all of these functions will treat it as if it's the item 18641 (dense dynamite), even if the macro will cast a different action on press.
GetActionText(actionButton) now additionally returns action type ("MACRO", "ITEM", "SPELL") and its id, or for macro, its index. a macro's index is the value used by GetMacroInfo(index). This allows you to differentiate between two macros on your actionbar that have the same name, or to find the id of an item or spell that is on your bar.
New functions:

GetPlayerBuffID(buffindex) function that returns id of the aura.

CombatLogAdd("text"[, addToRawLog]) function that prints a message directly to the combatlog file. If flag is set, prints the message to the raw combatlog file instead.

SpellInfo(spellid) function that returns information about a spell id (name, rank, texture file, minrange, max range to target).

TrackUnit(unitid) function that adds a friendly unit to the minimap.

UnitPosition(unitid) function that returns coordinates of a friendly unit.

SetMouseoverUnit(unitid) function that sets as current hovered unit. Usage for unitframe addon makers: do SetMouseoverUnit(frameUnit) on enter, and SetMouseoverUnit() on leave to clear. This allows "mouseover" of other functions to work on that currently hovered frame's unit.

Clickthrough(0/1) to turn off/on Clickthrough mode, Clickthrough() to simply return whether it's on. Clickthrough mode allows you to click through creature corpses that have no loot, to loot the creatures that are under them & covered by them.

SetAutoloot(0/1) to turn off/on autoloot, SetAutoloot() to simply return whether it's on. The hardcoded activation of autoloot by holding shift has been removed. You now turn it on or off through this function).

ImportFile("filename") reads a txt file in gamedirectory\imports and returns a string of its contents.

ExportFile("filename", "text") creates a txt file in gamedirectory\imports and writes text in it.

all functions that accept a unit as argument ("player", "target", "mouseover") now can accept an additional suffix "owner" which returns the owner of the unit (example, if you target a totem and do UnitName("targetowner") you'll get the name of the shaman).

all functions taht accept a unit as argument ("player, "target", "mouseover") now can accept "mark1" to "mark8" as argument which returns the unit with the corresponding marker index.

all functions that accept a unit as argument ("player", "target", "mouseover") now can accept the GUID of the unit, which can be obtained from UnitExists or GetName(1) on its nameplate. Suffixes can still be appended at the end of that string.

Global variables SUPERWOW_STRING and SUPERWOW_VERSION give mod info for addons.