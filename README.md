# Personal Resource Bar

A modern-style personal resource bar for WotLK 3.3.5a private servers.

It shows your character's active power — mana, rage, energy, runic power —
in a movable bar, colored to match the resource: blue mana, red rage,
yellow energy, light-blue runic power. The color follows the live power
type, so a Druid's bar switches from blue to yellow to red as it shifts
forms, with no setup.

Classes with a secondary resource get it automatically, as a segmented row
under the main bar:

- **Rogue** — 5 combo points
- **Druid** — 5 combo points, only while in Cat Form
- **Death Knight** — 6 runes colored by type (Blood / Unholy / Frost / Death), with a cooldown swipe while recharging

Every other class (Warrior, Paladin, Hunter, Priest, Shaman, Mage,
Warlock) gets just the main bar in the right color.

The 3.3.5a client has no API for attaching frames to nameplates, so the
bar sits wherever you put it on screen rather than under your character's
feet.

## Install

Copy the `PersonalResourceBar` folder into `Interface/AddOns/` in your
3.3.5a client, then enable it on the character-select AddOns screen.

## Usage

- `/prb` — open the options panel (also under Interface → AddOns)
- `/prb unlock` — unlock the bar, then drag it (it highlights green while unlocked)
- `/prb lock` — lock it back in place
- `/prb reset` — reset position, size and colors
- `/prb help` — list the commands

The options panel covers width, height, scale, bar texture, the
current/max text, the combo point and rune display, and a color picker
that recolors whichever resource you're currently using. Settings are
saved per character.

## Compatibility

Written against the 3.3.5a API only. It avoids calls added in later
expansions (`UNIT_POWER`, `SetShown`, `BackdropTemplate` and friends), and
polls the player's power ten times a second alongside the power events, so
it keeps working on cores that don't fire every event reliably.
