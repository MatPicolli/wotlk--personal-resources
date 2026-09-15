-- Personal Resource Bar
-- Which secondary resource each class gets out of the box. Classes not
-- listed here only get the main power bar, which is already correct for
-- them because its color follows the live power type.
--
-- Druids are listed as "combo" but only actually show combo points in Cat
-- Form; SecondaryResource.lua checks the active power type for that.

PRB_ClassSecondary = {
	ROGUE       = "combo",
	DRUID       = "combo",
	DEATHKNIGHT = "runes",
}
