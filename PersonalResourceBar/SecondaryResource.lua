-- Personal Resource Bar
-- Secondary resources drawn as orbs in sockets: Rogue / Cat Form Druid
-- combo points, and Death Knight runes colored by rune type. Only one row
-- is ever visible, chosen by class.

local MEDIA = "Interface\\AddOns\\PersonalResourceBar\\Media\\"
local ORB_SOCKET = MEDIA .. "orb-socket.tga"
local ORB_FILL = MEDIA .. "orb-fill.tga"

-- The fill texture carries its own glow, which is meant to spill over the
-- socket rim, so it is drawn at very nearly the full orb size.
local FILL_SCALE = 0.95

local MAX_COMBO_POINTS = 5
local MAX_RUNES = 6
local RUNE_POLL_INTERVAL = 0.1

-- Parented to the bars so it inherits scale and hides with them.
local container = CreateFrame("Frame", "PersonalResourceBar_Secondary", PRB.anchor)

local playerClass
local mode

local function CreateOrb(parent, withCooldown)
	local orb = CreateFrame("Frame", nil, parent)

	orb.socket = orb:CreateTexture(nil, "BACKGROUND")
	orb.socket:SetAllPoints(orb)
	orb.socket:SetTexture(ORB_SOCKET)

	orb.fill = orb:CreateTexture(nil, "ARTWORK")
	orb.fill:SetTexture(ORB_FILL)
	orb.fill:SetPoint("CENTER", orb, "CENTER", 0, 0)
	orb.fill:Hide()

	if withCooldown then
		orb.cooldown = CreateFrame("Cooldown", nil, orb, "CooldownFrameTemplate")
		orb.cooldown:SetAllPoints(orb)
		orb.cooldown:Hide()
	end

	return orb
end

-- ===== Combo points =====

local comboRow = CreateFrame("Frame", nil, container)
comboRow:SetPoint("CENTER", container, "CENTER", 0, 0)
comboRow:Hide()

local comboOrbs = {}
for i = 1, MAX_COMBO_POINTS do
	comboOrbs[i] = CreateOrb(comboRow, false)
end

local function UpdateCombo()
	local points = GetComboPoints("player", "target") or 0
	local r, g, b = PRB_GetPowerColor("COMBO")
	for i = 1, MAX_COMBO_POINTS do
		local orb = comboOrbs[i]
		if i <= points then
			orb.fill:SetVertexColor(r, g, b)
			orb.fill:SetAlpha(1)
			orb.fill:Show()
		else
			orb.fill:Hide()
		end
	end
end

-- ===== Death Knight runes =====

local runeRow = CreateFrame("Frame", nil, container)
runeRow:SetPoint("CENTER", container, "CENTER", 0, 0)
runeRow:Hide()

local runeOrbs = {}
for i = 1, MAX_RUNES do
	runeOrbs[i] = CreateOrb(runeRow, true)
end

local function UpdateRune(i)
	local orb = runeOrbs[i]
	local color = PRB_RuneColors[GetRuneType(i)] or PRB_RuneColors[1]
	orb.fill:SetVertexColor(color.r, color.g, color.b)
	orb.fill:Show()

	local start, duration, ready = GetRuneCooldown(i)
	if ready or not start or not duration or duration <= 0 then
		orb.cooldown:Hide()
		orb.fill:SetAlpha(1)
	else
		orb.cooldown:SetCooldown(start, duration)
		orb.cooldown:Show()
		orb.fill:SetAlpha(0.25)
	end
end

local function UpdateAllRunes()
	for i = 1, MAX_RUNES do
		UpdateRune(i)
	end
end

-- ===== Layout =====

local function LayoutOrbRow(row, orbs, count, size, spacing)
	row:SetWidth(count * size + spacing * (count - 1))
	row:SetHeight(size)
	for i = 1, count do
		local orb = orbs[i]
		orb:ClearAllPoints()
		orb:SetWidth(size)
		orb:SetHeight(size)
		if i == 1 then
			orb:SetPoint("LEFT", row, "LEFT", 0, 0)
		else
			orb:SetPoint("LEFT", orbs[i - 1], "RIGHT", spacing, 0)
		end
		orb.fill:SetWidth(size * FILL_SCALE)
		orb.fill:SetHeight(size * FILL_SCALE)
	end
end

function PRB_UpdateSecondaryLayout()
	local db = PersonalResourceBarDB
	local size = db.orbSize
	if size < 6 then
		size = 6
	end
	local spacing = math.floor(size * 0.22 + 0.5)
	if spacing < 2 then
		spacing = 2
	end

	container:ClearAllPoints()
	container:SetPoint("TOP", PRB.anchor, "BOTTOM", 0, -3)
	container:SetWidth(db.width)
	container:SetHeight(size)

	LayoutOrbRow(comboRow, comboOrbs, MAX_COMBO_POINTS, size, spacing)
	LayoutOrbRow(runeRow, runeOrbs, MAX_RUNES, size, spacing)
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

	comboRow:Hide()
	runeRow:Hide()
	container:SetScript("OnUpdate", nil)

	if mode == "combo" then
		comboRow:Show()
		UpdateCombo()
	elseif mode == "runes" then
		runeRow:Show()
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
