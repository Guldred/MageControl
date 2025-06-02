# Arcane Mage Helper

An optimized World of Warcraft addon specifically designed for Arcane Mages playing on the Turtle WoW private server. This addon enhances your single-target damage output by efficiently managing spell rotations and reducing downtime.

---

## Features

* **Single Target Rotation Optimization**: Execute the perfect Arcane rotation to maximize your DPS.
* **Arcane Explosion Queueing**: Efficiently manage your Arcane Explosion casts, ensuring minimal downtime.

---

## Commands

| Command         | Description                                                                                                                   |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `/mc options`   | Opens settings to configure your spell positions on the action bar (essential for tracking spell cooldowns and availability). |
| `/mc arcane`    | Initiates the optimized single-target Arcane spell rotation.                                                                  |
| `/mc explosion` | Initiates Arcane Explosion queuing for efficient AoE casting.                                                                 |

---

## Dependencies

**Required**:

* [`nampower`](https://github.com/pepopo978/nampower): Ensures efficient spell queuing, significantly reducing dead-time between spells by leveraging its Queue Spell functionality. This dependency must be loaded for proper addon operation.

---

## Installation

1. Download the addon folder and place it into your World of Warcraft interface addons directory:

   ```
   /Interface/AddOns/
   ```
2. Ensure `nampower` is installed and active.
3. Restart WoW or reload your UI to activate the addon.

---

## Support & Feedback

For any issues, feature requests, or general feedback, please open an issue in the repository or contact the developer directly.

Happy casting!
