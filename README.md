# Synapse (TurtleWoW, Vanilla 1.12.x)

**Synapse** is a modular combat/rotation assistant for Vanilla/Turtle WoW. 

---

## Features
- Modular class system (`Modules/<Class>.lua`)
- Safe click driver: `/synapse click` or keybind
- Level-aware rotations (skips spells you haven’t learned yet)
- Basic cast-detection for interrupts (chat-sniff heuristic)
- Lightweight event router (target change, auras)
- Debug toggle: `/synapse debug on|off|toggle`

---

## Installation
1. Download/clone the repo folder **Synapse** into:
   - `World of Warcraft\Interface\AddOns\Synapse\`
2. Verify the TOC lists:
   - `Synapse.lua`
   - `Core\Utils.lua`
   - `Core\Engine.lua`
   - `Core\Events.lua`
   - `Modules\Rogue.lua`
   - `Bindings.lua`
   - `Bindings.xml`
3. Launch the game or `/reload`.

---

## Usage
- Open **Key Bindings** → find the **Synapse** header → bind **Synapse Cast** to a key.
- Or use the slash command:  
- `/synapse click` — perform one rotation “click”
- Recommended: put the bound key on a comfortable repeat key (manual spam).

---

## Slash Commands
- `/synapse` — status + help
- `/synapse click` — force a single rotation click
- `/synapse debug on|off|toggle` — debug logging
- `/synapse module` — show active module info
- `/synapse repair` — adopt pending modules now
- `/synapse diag` — show diagnostic flags & registered modules

---

## Classes

**Rogue**
1. Combat [work in progress]
     - Stealth opener → *Cheap Shot* (if learned)
     - Priority: Kick (if target casting), Ghostly Strike (if known), builder (*Sinister Strike*), then finishers (*Slice and Dice*, *Rupture*, *Eviscerate*) as learned.
     - Bleed-immune memory (by mob name)
2. Subtlety [no]
3. Assissination [no]

**Warrior**
1. Basic rotation for my testing. Don't use.
     - Pummel on casts (if known), Execute ≤20% (if known), optional Rend/Sunder, Heroic Strike filler, Bloodrage to bootstrap.

**Mage**
1. Basic rotation for my testing. Don't use.
     - Counterspell on casts (if known), Frost Nova in melee (if known), Fire Blast instant, then Frostbolt/Fireball or Arcane Missiles.

---

## Notes
- Interrupts rely on Vanilla/Turtle chat lines (no modern combat log).

---

