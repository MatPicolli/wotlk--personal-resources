-- Personal Resource Bar
-- Color tables. We mirror Blizzard's own PowerBarColor values so every
-- power bar matches the color the player already knows from unit frames,
-- with a hardcoded fallback in case a private server's FrameXML strips it.

PRB_PowerColors = {
	MANA        = { r = 0,    g = 0,    b = 1    },
	RAGE        = { r = 1,    g = 0,    b = 0    },
	FOCUS       = { r = 1,    g = 0.5,  b = 0.25 },
	ENERGY      = { r = 1,    g = 1,    b = 0    },
	RUNIC_POWER = { r = 0,    g = 0.82, b = 1    },
	HAPPINESS   = { r = 0.98, g = 0.98, b = 0.1  },
}

-- Death Knight rune colors, matching Blizzard's default rune bar.
-- Rune type ids returned by GetRuneType(): 1 Blood, 2 Unholy, 3 Frost, 4 Death.
PRB_RuneColors = {
	[1] = { r = 0.82, g = 0.09, b = 0.09 }, -- Blood
	[2] = { r = 0.09, g = 0.58, b = 0.13 }, -- Unholy
	[3] = { r = 0.15, g = 0.65, b = 0.91 }, -- Frost
	[4] = { r = 0.66, g = 0.35, b = 0.97 }, -- Death (converted rune)
}

function PRB_GetPowerColor(powerToken)
	local blizzard = _G.PowerBarColor and _G.PowerBarColor[powerToken]
	local color = blizzard or PRB_PowerColors[powerToken]
	if not color then
		return 0.5, 0.5, 0.5
	end
	return color.r, color.g, color.b
end
