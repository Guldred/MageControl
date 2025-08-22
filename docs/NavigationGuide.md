# MageControl Navigation Guide
**Quick reference for finding code in the simplified architecture**

## 🎯 **Quick Navigation by Task**

### **"I want to find..."**

#### **WoW API Calls** 
→ `Core/WoWApi.lua`
- `MageControl.WoWApi.getPlayerMana()`
- `MageControl.WoWApi.castSpellByName()`  
- `MageControl.WoWApi.hasPlayerBuff()`
- All direct WoW API interactions

#### **Configuration/Settings**
→ `Core/ConfigData.lua`
- `MageControl.ConfigData.getMinManaForArcanePower()`
- `MageControl.ConfigData.getTrinketPriority()`
- `MageControl.ConfigData.get()` / `set()`
- All addon settings and persistence

#### **Rotation Logic/Decisions**
→ `Core/RotationLogic.lua`
- `MageControl.RotationLogic.shouldCastArcaneRupture()`
- `MageControl.RotationLogic.shouldInterruptMissiles()`
- `MageControl.RotationLogic.evaluateNextAction()`
- Business logic for rotation decisions

#### **Main Rotation Execution**  
→ `Modules/RotationEngine.lua`
- `MC.arcaneRotation()` - Main entry point
- `MC.executeArcaneRotation()` - Core execution
- Working, stable rotation implementation

#### **Slash Commands**
→ `MageControl.lua` 
- `/mc arcane` command handlers
- All user-facing commands

#### **State Management**
→ `Core/StateManager.lua`
- `MC.state` - Current addon state
- State updates and validation

#### **Spell/Buff Data**
→ `Data/SpellData.lua` & `Data/BuffData.lua`
- Spell IDs, mana costs, buff textures
- Game constants and mappings

---

## 🏗️ **Architecture Overview**

### **Direct Access Pattern (NEW)**
```lua
// ✅ GOOD - Intuitive naming tells you exactly where to look
MageControl.WoWApi.getPlayerMana()     // → Core/WoWApi.lua  
MageControl.ConfigData.get()           // → Core/ConfigData.lua
MageControl.RotationLogic.shouldCast() // → Core/RotationLogic.lua
```

### **Legacy Service Pattern (ELIMINATED)**
```lua
// ❌ REMOVED - Hard to navigate, complex
local service = MageControl.Services.Registry.get("StateService") 
// Where is StateService? Who knows!
```

---

## 📁 **File Organization**

### **Core/** - Essential addon functionality
- **WoWApi.lua** - Direct WoW API access (🆕 SIMPLIFIED)
- **ConfigData.lua** - Configuration management (🆕 SIMPLIFIED)  
- **RotationLogic.lua** - Rotation decision logic (🆕 SIMPLIFIED)
- **StateManager.lua** - Addon state tracking
- **Services/** - Legacy service files (simplified, no registry)

### **Modules/** - Feature implementations
- **RotationEngine.lua** - Main working rotation (✅ STABLE)
- **BuffTracker.lua** - Buff monitoring
- **Rotation/** - Modular rotation components

### **Data/** - Game constants  
- **SpellData.lua** - Spell IDs, costs, etc.
- **BuffData.lua** - Buff textures, effects
- **ImmunityData.lua** - Boss immunities

### **UI/** - User interface
- **Components/** - Reusable UI elements
- **Options/** - Settings interface

---

## 🎯 **Common Development Tasks**

### **Add a new WoW API call**
1. Add function to `Core/WoWApi.lua`
2. Follow naming pattern: `MageControl.WoWApi.functionName()`
3. Export to `MC.WoWApi` for backward compatibility

### **Add rotation logic**
1. Add decision function to `Core/RotationLogic.lua` 
2. Use `WoWApi` and `ConfigData` modules for data
3. Integrate with `RotationEngine.lua` execution

### **Change addon settings**
1. Modify `Core/ConfigData.lua` functions
2. Settings persist to `MageControlDB` automatically
3. Add UI in `UI/Options/` if needed

### **Debug rotation issues** 
1. Check `Modules/RotationEngine.lua` - main execution
2. Check `Core/RotationLogic.lua` - decision logic  
3. Use `/mc debug` command for logging
4. Run `LoadTest.lua` to verify structure

---

## ⚡ **Quick Reference**

### **Main Entry Points**
- `/mc arcane` → `MC.arcaneRotation()` in `RotationEngine.lua`
- `/mc cooldown` → `MC.activateTrinketAndAP()` 
- `/mc debug` → Toggle debug logging

### **Global Namespaces**
- `MageControl.*` - Main addon namespace  
- `MC.*` - Backward compatibility shortcuts
- `MageControlDB` - Saved variables

### **Key State Variables**
- `MC.state.isChanneling` - Player channeling status
- `MC.CURRENT_BUFFS` - Active player buffs  
- `MC.DEBUG` - Debug mode flag

---

## 🧹 **What Was Cleaned Up**

### **Removed (700+ lines of complexity)**
- ❌ `RotationService.lua` (429 lines) - Over-engineered service
- ❌ `RotationManager.lua` (184 lines) - Conflicted with RotationEngine
- ❌ `ServiceRegistry.lua` (69 lines) - Entire registry pattern
- ❌ Interface stubs (100+ lines) - Empty documentation  
- ❌ All `Services.Registry.get()` calls - Hard to navigate

### **Added (Clean, intuitive modules)**  
- ✅ `Core/WoWApi.lua` - Direct API access
- ✅ `Core/ConfigData.lua` - Direct config access
- ✅ `Core/RotationLogic.lua` - Business logic
- ✅ This navigation guide!

---

## 🎉 **Result: Clean, Maintainable Architecture**

**Before:** Complex service registry pattern with hard-to-find code  
**After:** Intuitive direct access with clear file naming that tells you exactly where to look!

Perfect for Lua development without IDE "go to definition" support. 🎯
