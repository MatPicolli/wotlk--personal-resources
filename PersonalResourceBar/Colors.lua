-- Personal Resource Bar
-- Power tokens and colors.

-- Power type ids as returned by UnitPowerType() on 3.3.5a. We map the id
-- ourselves rather than using the function's second return value, because
-- not every 3.3.5a core hands back the power token string.
PRB_PowerTokens = {
	[0] = "MANA",
	[1] = "RAGE",
	[2] = "FOCUS",
	[3] = "ENERGY",
	[4] = "HAPPINESS",
	[5] = "RUNES",
	[6] = "RUNIC_POWER",
}

-- Tuned to read like the modern personal resource bar rather than the
-- flat primary colors the 3.3.5a client uses for its own unit frames.
PRB_DefaultPowerColors = {
	MANA        = { r = 0.20, g = 0.45, b = 0.95 },
	RAGE        = { r = 0.85, g = 0.15, b = 0.15 },
	FOCUS       = { r = 1.00, g = 0.60, b = 0.25 },
	ENERGY      = { r = 1.00, g = 0.88, b = 0.20 },
	HAPPINESS   = { r = 0.00, g = 0.71, b = 0.30 },
	RUNES       = { r = 0.50, g = 0.50, b = 0.50 },
	RUNIC_POWER = { r = 0.30, g = 0.80, b = 0.95 },
}

PRB_ComboPointColor = { r = 1.00, g = 0.82, b = 0.20 }

-- Rune type ids from GetRuneType(): 1 Blood, 2 Unholy, 3 Frost, 4 Death.
PRB_RuneColors = {
	[1] = { r = 0.82, g = 0.09, b = 0.09 },
	[2] = { r = 0.09, g = 0.58, b = 0.13 },
	[3] = { r = 0.15, g = 0.65, b = 0.91 },
	[4] = { r = 0.66, g = 0.35, b = 0.97 },
}

function PRB_GetPowerToken(powerType)
	return PRB_PowerTokens[powerType] or "MANA"
end

function PRB_GetPowerColor(token)
	local db = PersonalResourceBarDB
	local color = (db and db.colors and db.colors[token])
		or PRB_DefaultPowerColors[token]
		or PRB_DefaultPowerColors.MANA
	return color.r, color.g, color.b
end
