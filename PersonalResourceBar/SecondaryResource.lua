-- Personal Resource Bar
-- Secondary resource widgets: Rogue/feral-Druid combo points (pips) and
-- Death Knight runes (6 colored, cooldown-swiped squares). Only one of
-- these is ever shown, decided by class (and, for Druids, current form).

local _, playerClass = UnitClass("player")

local container = CreateFrame("Frame", "PersonalResourceBar_Secondary", UIParent)
container:SetFrameStrata("MEDIUM")

-- ===== Combo points (up to 5 pips) =====

local MAX_COMBO_POINTS = 5
local comboFrame = CreateFrame("Frame", nil, container)
comboFrame:SetPoint("CENTER", container, "CENTER", 0, 0)
local comboPips = {}
for i = 1, MAX_COMBO_POINTS do
	local pip = comboFrame:CreateTexture(nil, "ARTWORK")
	pip:SetTexture(1, 0.82, 0, 1) -- solid gold square; avoids depending on a Blizzard atlas path
	if i == 1 then
		pip:SetPoint("LEFT", comboFrame, "LEFT", 0, 0)
	else
		pip:SetPoint("LEFT", comboPips[i - 1], "RIGHT", 2, 0)
	end
	comboPips[i] = pip
end

local function LayoutCombo(size)
	for i = 1, MAX_COMBO_POINTS do
		comboPips[i]:SetSize(size, size)
	end
	comboFrame:SetSize(size * MAX_COMBO_POINTS + 2 * (MAX_COMBO_POINTS - 1), size)
end

local function UpdateCombo()
	local points = GetComboPoints("player", "target") or 0
	for i = 1, MAX_COMBO_POINTS do
		if i <= points then
			comboPips[i]:SetAlpha(1)
		else
			comboPips[i]:SetAlpha(0.25)
		end
	end
end

-- ===== Death Knight runes (6 runes) =====

local MAX_RUNES = 6
local runeFrame = CreateFrame("Frame", nil, container)
runeFrame:SetPoint("CENTER", container, "CENTER", 0, 0)
local runes = {}
for i = 1, MAX_RUNES do
	local rune = CreateFrame("Frame", nil, runeFrame)
	rune.bg = rune:CreateTexture(nil, "BACKGROUND")
	rune.bg:SetAllPoints(rune)
	rune.bg:SetTexture(1, 1, 1, 1)

	rune.cooldown = CreateFrame("Cooldown", nil, rune, "CooldownFrameTemplate")
	rune.cooldown:SetAllPoints(rune)

	if i == 1 then
		rune:SetPoint("LEFT", runeFrame, "LEFT", 0, 0)
	else
		rune:SetPoint("LEFT", runes[i - 1], "RIGHT", 3, 0)
	end
	runes[i] = rune
end

local function LayoutRunes(size)
	for i = 1, MAX_RUNES do
		runes[i]:SetSize(size, size)
	end
	runeFrame:SetSize(size * MAX_RUNES + 3 * (MAX_RUNES - 1), size)
end

local function UpdateRune(i)
	local rune = runes[i]
	local runeType = GetRuneType(i)
	local color = PRB_RuneColors[runeType] or PRB_RuneColors[1]
	rune.bg:SetTexture(color.r, color.g, color.b, 1)

	local start, duration, ready = GetRuneCooldown(i)
	if ready or not start or duration == 0 then
		rune.cooldown:Hide()
	else
		rune.cooldown:SetCooldown(start, duration)
		rune.cooldown:Show()
	end
end

local function UpdateAllRunes()
	for i = 1, MAX_RUNES do
		UpdateRune(i)
	end
end

-- ===== Mode selection =====

local mode = "none" -- "none" | "combo" | "runes"

local function SetMode(newMode)
	if newMode == mode then
		return
	end
	mode = newMode
	comboFrame:Hide()
	runeFrame:Hide()
	if mode == "combo" then
		comboFrame:Show()
		UpdateCombo()
	elseif mode == "runes" then
		runeFrame:Show()
		UpdateAllRunes()
	end
end

local function DesiredMode()
	local db = PersonalResourceBarDB
	if not db.showSecondary then
		return "none"
	end

	local defaults = PRB_GetClassDefaults(playerClass)
	if defaults.secondary == "none" then
		return "none"
	end

	if playerClass == "DRUID" then
		-- Druids only generate combo points in Cat Form, and Cat Form is
		-- the only Druid form powered by Energy, so that's the reliable
		-- signal to use rather than guessing at shapeshift form ids.
		local _, token = UnitPowerType("player")
		if token == "ENERGY" then
			return "combo"
		end
		return "none"
	end

	return defaults.secondary
end

function PRB_RefreshSecondary()
	SetMode(DesiredMode())
end

function PRB_UpdateSecondaryLayout()
	local db = PersonalResourceBarDB
	local size = db.height
	LayoutCombo(size)
	LayoutRunes(size)

	container:ClearAllPoints()
	container:SetPoint("TOP", PRB.bar, "BOTTOM", 0, -4)
	container:SetScale(db.scale)
	container:SetSize(db.width, size)
end

function PRB_InitSecondary()
	PRB_UpdateSecondaryLayout()
	PRB_RefreshSecondary()
end

-- ===== Events =====

container:RegisterEvent("UNIT_COMBO_POINTS")
container:RegisterEvent("RUNE_POWER_UPDATE")
container:RegisterEvent("RUNE_TYPE_UPDATE")
container:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
container:RegisterEvent("PLAYER_ENTERING_WORLD")

container:SetScript("OnEvent", function(self, event, arg1)
	if event == "UNIT_COMBO_POINTS" then
		if mode == "combo" then
			UpdateCombo()
		end
	elseif event == "RUNE_POWER_UPDATE" then
		if mode == "runes" then
			if arg1 then
				UpdateRune(arg1)
			else
				UpdateAllRunes()
			end
		end
	elseif event == "RUNE_TYPE_UPDATE" then
		if mode == "runes" and arg1 then
			UpdateRune(arg1)
		end
	elseif event == "UPDATE_SHAPESHIFT_FORM" then
		PRB_RefreshSecondary()
	elseif event == "PLAYER_ENTERING_WORLD" then
		PRB_RefreshSecondary()
	end
end)
