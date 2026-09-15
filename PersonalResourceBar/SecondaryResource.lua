-- Personal Resource Bar
-- Secondary resources: Rogue / Cat Form Druid combo points and Death
-- Knight runes. Both are laid out as a segmented row spanning the width
-- of the main bar. Only one is ever visible, chosen by class.

local MAX_COMBO_POINTS = 5
local MAX_RUNES = 6
local SPACING = 2
local RUNE_POLL_INTERVAL = 0.1

-- Parented to the main bar so it inherits scale and hides with it.
local container = CreateFrame("Frame", "PersonalResourceBar_Secondary", PRB.bar)

local playerClass
local mode

-- ===== Combo points =====

local comboFrame = CreateFrame("Frame", nil, container)
comboFrame:SetAllPoints(container)
comboFrame:Hide()

local comboPips = {}
for i = 1, MAX_COMBO_POINTS do
	local pip = comboFrame:CreateTexture(nil, "ARTWORK")
	local c = PRB_ComboPointColor
	pip:SetTexture(c.r, c.g, c.b, 1)
	comboPips[i] = pip
end

local function UpdateCombo()
	local points = GetComboPoints("player", "target") or 0
	for i = 1, MAX_COMBO_POINTS do
		comboPips[i]:SetAlpha(i <= points and 1 or 0.2)
	end
end

-- ===== Death Knight runes =====

local runeFrame = CreateFrame("Frame", nil, container)
runeFrame:SetAllPoints(container)
runeFrame:Hide()

local runes = {}
for i = 1, MAX_RUNES do
	local rune = CreateFrame("Frame", nil, runeFrame)
	rune.bg = rune:CreateTexture(nil, "ARTWORK")
	rune.bg:SetAllPoints(rune)
	rune.cooldown = CreateFrame("Cooldown", nil, rune, "CooldownFrameTemplate")
	rune.cooldown:SetAllPoints(rune)
	runes[i] = rune
end

local function UpdateRune(i)
	local rune = runes[i]
	local color = PRB_RuneColors[GetRuneType(i)] or PRB_RuneColors[1]
	rune.bg:SetTexture(color.r, color.g, color.b, 1)

	local start, duration, ready = GetRuneCooldown(i)
	if ready or not start or not duration or duration <= 0 then
		rune.cooldown:Hide()
		rune:SetAlpha(1)
	else
		rune.cooldown:SetCooldown(start, duration)
		rune.cooldown:Show()
		rune:SetAlpha(0.5)
	end
end

local function UpdateAllRunes()
	for i = 1, MAX_RUNES do
		UpdateRune(i)
	end
end

-- ===== Layout =====

local function LayoutRow(parent, items, count, totalWidth, height)
	local itemWidth = (totalWidth - SPACING * (count - 1)) / count
	if itemWidth < 1 then
		itemWidth = 1
	end
	for i = 1, count do
		local item = items[i]
		item:ClearAllPoints()
		item:SetWidth(itemWidth)
		item:SetHeight(height)
		if i == 1 then
			item:SetPoint("LEFT", parent, "LEFT", 0, 0)
		else
			item:SetPoint("LEFT", items[i - 1], "RIGHT", SPACING, 0)
		end
	end
end

function PRB_UpdateSecondaryLayout()
	local db = PersonalResourceBarDB
	local height = math.floor(db.height * 0.45 + 0.5)
	if height < 5 then
		height = 5
	end

	container:ClearAllPoints()
	container:SetPoint("TOP", PRB.bar, "BOTTOM", 0, -3)
	container:SetWidth(db.width)
	container:SetHeight(height)

	LayoutRow(comboFrame, comboPips, MAX_COMBO_POINTS, db.width, height)
	LayoutRow(runeFrame, runes, MAX_RUNES, db.width, height)
end

-- ===== Mode selection =====

local function DesiredMode()
	local db = PersonalResourceBarDB
	if not db or not db.showSecondary or not playerClass then
		return "none"
	end

	local secondary = PRB_ClassSecondary[playerClass]
	if not secondary then
		return "none"
	end

	if playerClass == "DRUID" then
		-- Cat Form is the only Druid form that generates combo points, and
		-- the only one powered by Energy, which is a far more reliable
		-- signal than the shapeshift form index.
		if PRB_GetPowerToken(UnitPowerType("player")) == "ENERGY" then
			return "combo"
		end
		return "none"
	end

	return secondary
end

local sinceRunePoll = 0
local function RunePoll(self, elapsed)
	sinceRunePoll = sinceRunePoll + elapsed
	if sinceRunePoll >= RUNE_POLL_INTERVAL then
		sinceRunePoll = 0
		UpdateAllRunes()
	end
end

function PRB_RefreshSecondary()
	local newMode = DesiredMode()
	if newMode == mode then
		return
	end
	mode = newMode

	comboFrame:Hide()
	runeFrame:Hide()
	container:SetScript("OnUpdate", nil)

	if mode == "combo" then
		comboFrame:Show()
		UpdateCombo()
	elseif mode == "runes" then
		runeFrame:Show()
		UpdateAllRunes()
		-- Runes recharge continuously, so they're polled while visible
		-- rather than trusting every core to fire RUNE_POWER_UPDATE.
		sinceRunePoll = 0
		container:SetScript("OnUpdate", RunePoll)
	end
end

function PRB_InitSecondary()
	local _, class = UnitClass("player")
	playerClass = class
	PRB_UpdateSecondaryLayout()
	PRB_RefreshSecondary()
end

-- ===== Events =====

container:RegisterEvent("UNIT_COMBO_POINTS")
container:RegisterEvent("PLAYER_TARGET_CHANGED")
container:RegisterEvent("RUNE_POWER_UPDATE")
container:RegisterEvent("RUNE_TYPE_UPDATE")
container:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

container:SetScript("OnEvent", function(self, event, arg1)
	if event == "UNIT_COMBO_POINTS" or event == "PLAYER_TARGET_CHANGED" then
		if mode == "combo" then
			UpdateCombo()
		end
	elseif event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE" then
		if mode == "runes" then
			if arg1 then
				UpdateRune(arg1)
			else
				UpdateAllRunes()
			end
		end
	elseif event == "UPDATE_SHAPESHIFT_FORM" then
		PRB_RefreshSecondary()
	end
end)
