# Arcane Mage Helper

_A high-performance World of Warcraft addon for Arcane Mages on Turtle WoW._

> **This addon enhances your single-target damage output by efficiently managing spell rotations and reducing downtime.**

---

## ✨ Features

- **Optimal Arcane DPS Rotation** — Single-target spell sequence to maximize throughput.
- **Instant Arcane Explosion Queuing** — Fast AoE casting with minimal downtime.
- **User-Friendly UI Options** — Configure your spell action bar slots with a native options panel.

---

## ⚡ Commands

| Command         | Description                                                                                                                                                                                                                                      |
|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/mc options`   | Opens settings to configure action bar spell slots.                                                                                                                                                                                              |
| `/mc arcane`    | Starts the optimized single-target Arcane rotation.                                                                                                                                                                                              |
| `/mc explosion` | Queues Arcane Explosion for instant AoE.                                                                                                                                                                                                         |
| `/mc arcaneinc` | Single Target variant for Incantagos (Kara40). Automatically switching to Frostbolt (Blue Affinity) and Fireball (Red Affinity) for the respective target                                                                                        |
| `/mc trinket`   | This activates both trinkets and arcane power, but only 1 of them per macro use. The order can be set in options. Please note: Things on cooldown, trinkets without activation and arcane power while below minimum mana setting will be ignored |
| `/mc reset`     | Resets settings and duration frames. Use if you get errors or problems.                                                                                                                                                                          |

---

## 🔗 Dependency

This addon **requires** [`nampower`](https://github.com/pepopo978/nampower) and [`superwow`](https://github.com/balakethelock/SuperWoW).

_Nampower is needed for instant spell queuing and zero-lag rotations.  
SuperWoW is needed for efficient buff fetching without the use of GameTooltips.
Please ensure both are installed before use._

---

## 📦 Installation

1. Download the addon folder and place it into your World of Warcraft interface addons directory:
    ```
    Interface/AddOns/MageControl
    ```
2. Install [`nampower`](https://github.com/pepopo978/nampower).
3. Install [`superwow`](https://github.com/balakethelock/SuperWoW).
4. Restart WoW.
5. Use `/mc options`
6. Set up the actionbar slot numbers of Fireblast, Arcane Rupture, Arcane Surge and Arcane Power (this is absolutely required, addon won't work otherwise). UPDATE 1.6.2: You can now let the addon search for the correct actionbar slots by clicking the button in the options menu.
7. Optionally, you can change settings for Cooldown priority for the /mc trinket functionality. Also, there is a slider to set minimum mana for Arcane Power activation via /mc trinket.
8. Use the unlock button to move the CD Buff Duration Frames to the place you want them to be. See below for a list of frames with explanation.
9. Use the lock button to lock them in place. They will only show if the buff is running
10. Done!

---

## 📦 Buff Duration Frames
- `Arcane Power`: Shows Arcane Power Buff with remaining duration
- `Mind Quickening`: Shows the Mind Quickening Buff with remaining duration (upon using the Mind Quickening Gem trinket)
- `Arcane Rupture`: Shows the remaining Rupture Debuff duration
- `Wisdom of the Mak'aru`: Shows stacks and duration of the [`Sphere of the Endless Gulch`](https://database.turtle-wow.org/?item=55501)
- `Enlightened State`: Shows the 20% haste buff of [`Sphere of the Endless Gulch`](https://database.turtle-wow.org/?item=55501) once you collected 8 stacks of `Wisdom of the Mak'aru`

Please Note: You can have `Wisdom of the Mak'aru` and `Enlightened State` at the same time, so putting those 2 frames on top of each other is not recommended. I might add functionality in the future to unify this.

---

## 🆘 Support

- **Bugs & Requests:**  
  Open an [issue](../../issues) on GitHub for bug reports or feature suggestions.

---

> _Happy casting, and may your Clearcasting procs never run dry!_
