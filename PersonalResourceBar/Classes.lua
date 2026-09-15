-- Personal Resource Bar
-- Per-class defaults: which secondary resource widget (if any) a class
-- gets out of the box. The main bar's color/power type is always derived
-- live from UnitPowerType(), so it's correct even through Druid shapeshifts.

PRB_ClassDefaults = {
	WARRIOR     = { secondary = "none"   },
	PALADIN     = { secondary = "none"   },
	HUNTER      = { secondary = "none"   },
	ROGUE       = { secondary = "combo"  },
	PRIEST      = { secondary = "none"   },
	DEATHKNIGHT = { secondary = "runes"  },
	SHAMAN      = { secondary = "none"   },
	MAGE        = { secondary = "none"   },
	WARLOCK     = { secondary = "none"   },
	-- Druids only show combo points while shapeshifted into Cat Form;
	-- SecondaryResource.lua checks the current form dynamically.
	DRUID       = { secondary = "combo", dynamic = true },
}

function PRB_GetClassDefaults(class)
	return PRB_ClassDefaults[class] or { secondary = "none" }
end
