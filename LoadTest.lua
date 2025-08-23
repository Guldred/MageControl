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

-- Test 3: Verify key functions exist
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

-- Test 4: Verify working rotation engine still exists
if MC and MC.arcaneRotation then
    print("✅ MC.arcaneRotation function exists (main rotation entry point)")
else
    print("❌ ERROR: MC.arcaneRotation function missing")
end

if MC and MC.executeArcaneRotation then
    print("✅ MC.executeArcaneRotation function exists")
else
    print("❌ ERROR: MC.executeArcaneRotation function missing")
end

-- Test 5: Verify service registry was properly eliminated
if MageControl.Services and MageControl.Services.Registry then
    print("❌ WARNING: Services.Registry still exists - should have been eliminated")
else
    print("✅ Services.Registry successfully eliminated")
end

-- Test 6: Verify simplified services still exist for initialization
if MageControl.Services and MageControl.Services.WoWApi then
    print("✅ Simplified MageControl.Services.WoWApi exists")
else
    print("❌ ERROR: Simplified WoWApi service missing")
end

print("=== Load Test Complete ===")
print("If all tests show ✅, the addon cleanup was successful!")
print("If any tests show ❌, there are issues that need fixing.")
