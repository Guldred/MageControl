# MageControl - Advanced Arcane Mage Addon

_A high-performance, modular World of Warcraft addon for Arcane Mages on Turtle WoW with intelligent boss encounter adaptations._

> **This addon enhances your single-target damage output by efficiently managing spell rotations, reducing downtime, and providing intelligent spell selection for boss encounters.**

---

## ✨ Features

### **Core Rotation System**
- **Optimal Arcane DPS Rotation** — Single-target spell sequence to maximize throughput with intelligent priority management
- **Instant Arcane Explosion Queuing** — Fast AoE casting with minimal downtime
- **Smart Cooldown Management** — Configurable trinket and Arcane Power activation priority system

### **Intelligent Boss Encounters**
- **Incantagos Support** — Automatically casts Fireball on Red Affinity and Frostbolt on Blue Affinity targets
- **Training Dummy Testing** — Test intelligent spell selection using training dummies (Heroic → Fireball, Expert → Frostbolt, Apprentice → Arcane Missiles)
- **Extensible Framework** — Easy to add more boss-specific behaviors

### **Smart Spell Detection**
- **Auto-Detection System** — Automatically scans all 120 action bar slots to find and configure spells
- **Conflict Resolution** — Intelligently handles duplicate spells by selecting optimal slots based on accessibility
- **Real-Time Validation** — Continuous monitoring with color-coded status indicators

### **Professional Options UI**
- **Modular Interface** — Clean, organized tabs: Setup, Priority, Settings, Encounters, Info
- **Enhanced User Experience** — Optimized layout with centered elements and professional styling
- **Persistent Configuration** — All settings save automatically and persist across sessions

---

## ⚡ Commands

| Command         | Description                                                                                           |
|-----------------|-------------------------------------------------------------------------------------------------------|
| `/mc options`   | Opens the comprehensive settings interface with tabbed organization                                   |
| `/mc arcane`    | Starts the optimized single-target Arcane rotation with intelligent boss encounter adaptations        |
| `/mc explosion` | Queues Arcane Explosion for instant AoE casting                                                       |
| `/mc surge`     | Queues Arcane Surge and cancels missiles after next tick                                              |
| `/mc cooldown`  | Activates trinkets and Arcane Power based on configured priority order (replaces old trinket command) |
| `/mc cooldowns` | Alternative cooldown activation command                                                               |
| `/mc cd`        | Short cooldown activation command                                                                     |
| `/mc trinket`   | **[DEPRECATED]** Legacy trinket command (still works but shows warning)                               |
| `/mc reset`     | Resets settings and duration frames if you encounter errors                                           |
| `/mc debug`     | Toggles debug logging for troubleshooting                                                             |

---

## 🎯 Boss Encounter System

### **Incantagos (Karazhan 40)**
- **Automatic Target Detection** — Recognizes Red Affinity and Blue Affinity targets
- **Smart Spell Selection** — Casts Fireball on Red Affinity, Frostbolt on Blue Affinity
- **Configurable** — Enable/disable via Boss Encounters tab in options

### **Training Dummy Testing**
- **Heroic Training Dummy** → Automatically casts Fireball
- **Expert Training Dummy** → Automatically casts Frostbolt  
- **Apprentice Training Dummy** → Automatically casts Arcane Missiles
- **Perfect for Testing** — Test boss encounter logic without needing actual encounters

---

## 🎮 Smart Spell Detection

### **One-Click Setup**
1. Open `/mc options` → Setup tab
2. Click "Auto-Detect" button
3. System scans all 120 action bar slots automatically
4. Configures Fire Blast, Arcane Rupture, Arcane Surge, and Arcane Power

### **Intelligent Features**
- **Duplicate Resolution** — Automatically selects best slot when multiple instances exist
- **Priority System** — Prefers main bar > shift bar > ctrl bar > alt bar > other bars
- **Real-Time Validation** — Shows current status with color-coded indicators
- **Manual Override** — Can still manually configure if needed

---

## 🔧 Trinket Priority System

### **Configurable Activation Order**
- **Priority Panel** — Simple up/down buttons to reorder activation sequence
- **Three Options** — Trinket Slot 1, Trinket Slot 2, Arcane Power
- **Smart Activation** — Skips items on cooldown or without activation
- **Persistent Settings** — Priority order saves across sessions

### **Usage**
1. Configure priority in `/mc options` → Priority tab
2. Use `/mc cooldown` to activate highest priority available item
3. System automatically skips unavailable items and moves to next priority

---

## 🔗 Dependencies

This addon **requires** [`nampower`](https://github.com/pepopo978/nampower) and [`superwow`](https://github.com/balakethelock/SuperWoW).

- **Nampower** — Needed for instant spell queuing and zero-lag rotations
- **SuperWoW** — Needed for efficient buff fetching without GameTooltips

_Please ensure both are installed before use._

---

## 📦 Installation

1. Download the addon folder and place it into your World of Warcraft interface addons directory:
    ```
    Interface/AddOns/MageControl
    ```
2. Install [`nampower`](https://github.com/pepopo978/nampower)
3. Install [`superwow`](https://github.com/balakethelock/SuperWoW)
4. Restart WoW
5. Use `/mc options` to configure settings
6. **Quick Setup**: Use the Auto-Detect button in Setup tab for automatic configuration
7. **Manual Setup**: Configure action bar slots for Fire Blast, Arcane Rupture, Arcane Surge, and Arcane Power
8. Create a macro for `/mc arcane` and bind it to a keybind of your choice. This is you main single target button.
9. Create a macro for `/mc surge` and bind it to a keybind of your choice. Using this button will end current Arcane Missiles after the next tick and then cast Surge immeditelly (so you don't lose tick time of missiles)
10. Create a macro for `/mc explosion` and bind it to a keybind of your choice. This is your AoE button. It will Queue one Arcane Explosion if your GCD is at 0.75s maximum to instantly fire the next once the current GCD is ready
11. Create a macro for `/mc cooldown` and bind it to a keybind of your choice. You can activate both trinkets and arcane power with this command (1 per click, configured in options) 

---

## 🏗️ Architecture

### **Modern Modular Design**
- **Service Layer** — Dependency injection and clean separation of concerns
- **Event-Driven** — Efficient event handling and async processing
- **Abstracted APIs** — Clean separation between business logic and WoW API
- **Error Handling** — Comprehensive error management and logging system

### **Performance Optimized**
- **Efficient Scanning** — Smart action bar detection with minimal API calls
- **Optimized UI** — Responsive interface with proper memory management
- **WoW 1.12.1 Compatible** — Full compatibility with classic WoW API limitations

---

## 🐛 Support

- **Bugs & Requests** — Open an [issue](../../issues) on GitHub for bug reports or feature suggestions
- **Debug Mode** — Use `/mc debug` to enable detailed logging for troubleshooting
- **Reset Function** — Use `/mc reset` if you encounter persistent issues

---

**Enjoy your optimized Arcane Mage experience on Turtle WoW!** 🧙‍♂️✨
