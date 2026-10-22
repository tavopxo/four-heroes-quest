# Four Heroes Quest 🎮

A fully original, feature-complete 2D platformer adventure built with **Godot Engine 4.7**.

---

## 🌟 Game Overview

**Four Heroes Quest** is an original character-driven action platformer. Choose from four distinct heroes—each featuring unique mobility stats and special mechanics—to navigate dangerous obstacle courses, shatter breakable supply crates, gather delicious fruit ingredients, conquer dynamic mechanical hazards, and reach the Grand Goal Trophy!

---

## 🦸 The Four Heroes

| Hero | Title | Max HP | Agility & Signature Perk |
| :--- | :--- | :---: | :--- |
| **Ninja Frog** | *The Shinobi Acrobat* | 3 | **High sprint speed & Wall Cling**. Can cling to walls and execute high, angled wall leaps to scale narrow vertical shafts. |
| **Pink Man** | *The Featherweight* | 3 | **Floaty Double Jump & Feather Glide**. Holding the Jump button while falling slows descent by 55%, letting you glide over massive chasms. |
| **Virtual Guy** | *The Cyber Sprinter* | 3 | **Cyber Dash (`Shift` / `K`)**. Rapidly surges forward with ghost trails and dust particles, bypassing hazards and clearing wide gaps. |
| **Mask Dude** | *The Heavyweight* | 4 | **4 Hearts & Ground Pound (`Down` in air)**. Slams downward at high velocity, shattering crates in a single strike and launching skyward off trampolines. |

---

## 🕹️ Controls

| Action | Keyboard | Gamepad |
| :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` or `Left` / `Right` Arrow | Left Stick / D-Pad |
| **Jump / Double Jump / Wall Jump** | `Space` / `W` / `Up` Arrow | Button A (South) |
| **Special Ability (Cyber Dash)** | `Shift` / `K` / `J` | Button B / X |
| **Ground Pound (Mask Dude)** | `S` / `Down` Arrow in air | Left Stick Down |
| **Pause / Resume** | `Escape` / `P` | Start / Options |
| **Quick Restart** | `R` | Select / Back |

---

## ⚙️ Game Features & Systems

- **4 Handcrafted Adventure Levels & 1 Infinite Procedural Gauntlet**:
  - **Level 1: Emerald Meadows** – Introduces core movement, fruit collecting, breakable crates, trampoline springs, and falling platforms.
  - **Level 2: Clockwork Foundry** – Features spinning saws, moving chain platforms, vertical fan updrafts, swinging spiked pendulums, and rhythmic fire burners.
  - **Level 3: Sunken Caverns** – Slippery stone, slamming Spike Heads & Rock Heads, multi-tier crates, and vertical wall-climb shafts.
  - **Level 4: Apex Gauntlet** – The ultimate master test demanding the combined mastery of timing, trampolines, dashing, and hazard avoidance.
  - **∞ Endless Gauntlet (Procedural Mode)** – Dynamically stitches randomized platforming chunks, trap sequences, floating islands, and fruit formations in real-time as you run forward. Tracks distance, fruits collected, high score records, and milestone checkpoints every 100 meters!
- **Heart & Checkpoint System**:
  - 3 hearts per run (4 for Mask Dude).
  - Invulnerability frames with visual blinking on hit.
  - Checkpoint flags that unfurl with animated waving when activated.
  - Respawn with full health at the latest activated checkpoint.
- **Dynamic Hazards & Traps**:
  - **Trampoline**: Spring pad with compression and high-bounce launch.
  - **Fan**: Floor blower generating a vertical wind column and upward lift.
  - **Fire Trap**: 3-stage periodic hazard (Off -> Warning sparks -> Active flame).
  - **Falling Platform**: Shakes on contact, drops under gravity, and regenerates.
  - **Moving Platform**: Smooth back-and-forth transit with chain links.
  - **Slammer Traps (Spike Head & Rock Head)**: Sleeps until player crosses its path, slams down at high speed, shakes the screen, and returns.
  - **Spiked Ball Pendulum**: Realistic swinging pendulum hazard.
  - **Floor & Wall Spikes**: Classic precision platforming hazards.
- **Collectibles & Crates**:
  - 8 distinct fruit ingredients with 17-frame floating/spinning animations and sound feedback:
    *Apple, Bananas, Cherries, Kiwi, Melon, Orange, Pineapple, Strawberry*.
  - 3 breakable crate types with hit wobble and shattering debris, dropping bonus fruits.
- **Complete Menu & UI Suite**:
  - **Main Menu**: Animated hero preview, level select, character select, settings, and quit options.
  - **Character Select**: Inspect stats, lore, and signature abilities of each hero.
  - **Level Select**: Grid of completed levels with earned star ratings and best records.
  - **HUD**: Dynamic heart containers, fruit counter, live millisecond timer, and hero badge.
  - **Pause Menu, Game Over Screen, and Level Complete Screen** with animated Confetti and 3-Star scoring.
- **Procedural Retro Audio Engine**:
  - Complete set of 11 synthesized 16-bit sound effects (jump, double jump, wall leap, fruit pickup, crate shatter, trampoline bounce, hit, stomp, dash, checkpoint chime, victory fanfare).
  - Catchy 8-bit chiptune background music loop.
- **Progress Persistence**:
  - Automatically saves unlocked levels, best times, and star ratings to `user://game_save.json` (with graceful local fallback).

---

## 🚀 Running the Game

Open the project directly in **Godot 4.7** or execute from the terminal:

```bash
# Launch the game
/Applications/Godot.app/Contents/MacOS/Godot --path .
```
