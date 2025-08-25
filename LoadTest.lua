-- MageControl Load Test
-- Simple test to verify addon structure after major cleanup
-- Run this in WoW to verify everything loads properly

print("=== MageControl Load Test ===")

-- Test 1: Verify main addon namespace exists
if MageControl then
    print("✅ MageControl namespace exists")
else
    print("❌ ERROR: MageControl namespace missing")
    return
end

-- Test 2: Verify direct access modules are loaded
if MageControl.WoWApi then
    print("✅ MageControl.WoWApi module loaded")
else
    print("❌ ERROR: MageControl.WoWApi module missing")
end

if MageControl.ConfigData then
    print("✅ MageControl.ConfigData module loaded")
else
    print("❌ ERROR: MageControl.ConfigData module missing")
end

if MageControl.RotationLogic then
    print("✅ MageControl.RotationLogic module loaded")
else
    print("❌ ERROR: MageControl.RotationLogic module missing")
end

if MageControl.StateManager then
    print("✅ MageControl.StateManager module loaded (converted to direct access)")
else
    print("❌ ERROR: MageControl.StateManager module missing")
end

-- Test 2b: Verify new expert modules are loaded
if MageControl.ConfigDefaults then
    print("✅ MageControl.ConfigDefaults expert module loaded")
else
    print("❌ ERROR: MageControl.ConfigDefaults expert module missing")
end

if MageControl.ConfigValidation then
    print("✅ MageControl.ConfigValidation expert module loaded")
else
    print("❌ ERROR: MageControl.ConfigValidation expert module missing")
end

if MageControl.ManaUtils then
    print("✅ MageControl.ManaUtils expert module loaded")
else
    print("❌ ERROR: MageControl.ManaUtils expert module missing")
end

if MageControl.StringUtils then
    print("✅ MageControl.StringUtils expert module loaded")
else
    print("❌ ERROR: MageControl.StringUtils expert module missing")
end

if MageControl.CacheUtils then
    print("✅ MageControl.CacheUtils expert module loaded")
else
    print("❌ ERROR: MageControl.CacheUtils expert module missing")
end

if MageControl.SpellCasting then
    print("✅ MageControl.SpellCasting expert module loaded")
else
    print("❌ ERROR: MageControl.SpellCasting expert module missing")
end

if MageControl.TimingCalculations then
    print("✅ MageControl.TimingCalculations expert module loaded")
else
    print("❌ ERROR: MageControl.TimingCalculations expert module missing")
end

if MageControl.ArcaneSpecific then
    print("✅ MageControl.ArcaneSpecific expert module loaded")
else
    print("❌ ERROR: MageControl.ArcaneSpecific expert module missing")
end

-- Test 3: Verify key functions exist in direct access modules
if MageControl.WoWApi and MageControl.WoWApi.getPlayerMana then
    print("✅ WoWApi.getPlayerMana function exists")
else
    print("❌ ERROR: WoWApi.getPlayerMana function missing")
end

if MageControl.ConfigData and MageControl.ConfigData.get then
    print("✅ ConfigData.get function exists")
else
    print("❌ ERROR: ConfigData.get function missing")
end

-- Test 3b: Verify expert module functions exist
if MageControl.ManaUtils and MageControl.ManaUtils.getCurrentManaPercent then
    print("✅ ManaUtils.getCurrentManaPercent function exists")
else
    print("❌ ERROR: ManaUtils.getCurrentManaPercent function missing")
end

if MageControl.StringUtils and MageControl.StringUtils.normSpellName then
    print("✅ StringUtils.normSpellName function exists")
else
    print("❌ ERROR: StringUtils.normSpellName function missing")
end

if MageControl.SpellCasting and MageControl.SpellCasting.isSpellSafe then
    print("✅ SpellCasting.isSpellSafe function exists")
else
    print("❌ ERROR: SpellCasting.isSpellSafe function missing")
end

if MageControl.ConfigDefaults and MageControl.ConfigDefaults.get then
    print("✅ ConfigDefaults.get function exists")
else
    print("❌ ERROR: ConfigDefaults.get function missing")
end

if MageControl.ConfigValidation and MageControl.ConfigValidation.get then
    print("✅ ConfigValidation.get function exists")
else
    print("❌ ERROR: ConfigValidation.get function missing")
end

-- Test 4: Verify unified MageControl rotation engine exists
if MageControl.RotationEngine and MageControl.RotationEngine.execute then
    print("✅ MageControl.RotationEngine.execute function exists (unified rotation entry point)")
else
    print("❌ ERROR: MageControl.RotationEngine.execute function missing")
end

if MageControl.RotationLogic and MageControl.RotationLogic.getNextAction then
    print("✅ MageControl.RotationLogic.getNextAction function exists")
else
    print("❌ ERROR: MageControl.RotationLogic.getNextAction function missing")
end

-- Test 5: Verify dead code was properly eliminated
if MageControl.Services and MageControl.Services.Registry then
    print("❌ WARNING: Services.Registry still exists - should have been eliminated")
else
    print("✅ Services.Registry successfully eliminated")
end

if MageControl.Services and MageControl.Services.Events then
    print("❌ WARNING: EventService still exists - should have been eliminated as dead code")
else
    print("✅ EventService successfully eliminated (was over-engineered dead code)")
end

-- Test 6: Verify unified MageControl utility modules work
if MageControl.ManaUtils and MageControl.ManaUtils.getCurrentManaPercent then
    print("✅ Unified system: MageControl.ManaUtils.getCurrentManaPercent exists")
else
    print("❌ ERROR: MageControl.ManaUtils.getCurrentManaPercent missing")
end

if MageControl.StringUtils and MageControl.StringUtils.normSpellName then
    print("✅ Unified system: MageControl.StringUtils.normSpellName exists")
else
    print("❌ ERROR: MageControl.StringUtils.normSpellName missing")
end

print("=== Load Test Complete ===")
print("If all tests show ✅, the addon cleanup was successful!")
print("If any tests show ❌, there are issues that need fixing.")
