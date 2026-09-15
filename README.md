# Personal Resource Bar

A modern-style "personal resource bar" addon for WotLK 3.3.5a private servers.

It shows your character's primary power (mana, rage, energy, focus, runic
power...) in a small bar right under your character, colored automatically
to match the resource — blue mana, red rage, yellow energy, light-blue
runic power — using the game's own color table, so it's correct on any
3.3.5a server without per-class setup.

Classes that use a secondary resource get it for free, no configuration
needed:

- **Rogue** — 5 combo point pips
- **Druid** — 5 combo point pips, shown automatically only while shapeshifted into Cat Form
- **Death Knight** — 6 runes, colored by type (Blood / Unholy / Frost / Death) with a cooldown swipe while recharging

Every other class (Warrior, Paladin, Hunter, Priest, Shaman, Mage, Warlock)
just gets the main power bar, correctly colored.

## Install

Copy the `PersonalResourceBar` folder into `Interface/AddOns/` in your WotLK
3.3.5a client, then enable it at the character-select AddOns screen.

## Usage

- `/prb` — opens the options panel (also reachable from Interface Options)
- `/prb unlock` — unlocks the bar so you can drag it to a new position
- `/prb lock` — locks it back in place
- `/prb reset` — resets position, size and scale to defaults

The options panel lets you resize, rescale, change the bar texture, toggle
the current/max text, and toggle the combo point / rune display.

All settings are saved per character.
