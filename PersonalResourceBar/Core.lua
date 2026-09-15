-- Personal Resource Bar
-- A health bar stacked over the active power bar (mana, rage, energy,
-- runic power, ...), both colored to match, with the per-class secondary
-- resource orbs underneath.

PRB = CreateFrame("Frame", "PersonalResourceBarAddon", UIParent)
PRB.version = "1.2.0"

local DEFAULTS = {
	point = "CENTER",
	relPoint = "CENTER",
	x = 0,
	y = -200,
	width = 220,
	healthHeight = 18,
	powerHeight = 14,
	barSpacing = 2,
	orbSize = 14,
	scale = 1.0,
	locked = true,
	showHealth = true,
	showSecondary = true,
	showSpark = true,
	healthText = "auto",
	powerText = "auto",
	texture = "Interface\\TargetingFrame\\UI-StatusBar",
}

local UPDATE_INTERVAL = 0.1
local SPARK_TEXTURE = "Interface\\CastingBar\\UI-CastingBar-Spark"

local function Print(msg)
	print("|cff33ff99Personal Resource Bar|r: " .. msg)
end

function PRB_EnsureDB()
	local db = PersonalResourceBarDB or {}
	for k, v in pairs(DEFAULTS) do
		if db[k] == nil then
			db[k] = v
		end
	end
	-- Built here instead of in DEFAULTS so each character gets its own
	-- table rather than a shared reference to the defaults.
	if type(db.colors) ~= "table" then
		db.colors = {}
	end
	PersonalResourceBarDB = db
	return db
end

-- ===== Frames =====

-- Everything lives in this container, so dragging moves the whole set.
local anchor = CreateFrame("Frame", "PersonalResourceBar_Anchor", UIParent)
PRB.anchor = anchor
anchor:SetFrameStrata("MEDIUM")
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)

-- 3.3.5a has no BackdropTemplate, so borders are four thin textures.
local function AddBorder(frame)
	local inset = 1
	local edges = {
		{"TOPLEFT", "TOPLEFT", -inset, inset, "TOPRIGHT", "TOPRIGHT", inset, inset, "height"},
		{"BOTTOMLEFT", "BOTTOMLEFT", -inset, -inset, "BOTTOMRIGHT", "BOTTOMRIGHT", inset, -inset, "height"},
		{"TOPLEFT", "TOPLEFT", -inset, inset, "BOTTOMLEFT", "BOTTOMLEFT", -inset, -inset, "width"},
		{"TOPRIGHT", "TOPRIGHT", inset, inset, "BOTTOMRIGHT", "BOTTOMRIGHT", inset, -inset, "width"},
	}
	for _, e in ipairs(edges) do
		local t = frame:CreateTexture(nil, "BORDER")
		t:SetTexture(0, 0, 0, 1)
		t:SetPoint(e[1], frame, e[2], e[3], e[4])
		t:SetPoint(e[5], frame, e[6], e[7], e[8])
		if e[9] == "height" then
			t:SetHeight(inset)
		else
			t:SetWidth(inset)
		end
	end
end

local function CreateBar(name)
	local b = CreateFrame("StatusBar", name, anchor)

	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints(b)
	b.bg:SetTexture(0.18, 0.18, 0.18, 0.85)

	AddBorder(b)

	b.spark = b:CreateTexture(nil, "OVERLAY")
	b.spark:SetTexture(SPARK_TEXTURE)
	b.spark:SetBlendMode("ADD")
	b.spark:Hide()

	b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	b.text:SetPoint("RIGHT", b, "RIGHT", -4, 0)
	b.text:SetJustifyH("RIGHT")

	return b
end

local healthBar = CreateBar("PersonalResourceBar_HealthBar")
local powerBar = CreateBar("PersonalResourceBar_PowerBar")
PRB.healthBar = healthBar
PRB.powerBar = powerBar

-- Shown only while unlocked, so an empty bar is still grabbable.
anchor.moveOverlay = anchor:CreateTexture(nil, "OVERLAY")
anchor.moveOverlay:SetAllPoints(anchor)
anchor.moveOverlay:SetTexture(0, 1, 0, 0.25)
anchor.moveOverlay:Hide()

anchor:RegisterForDrag("LeftButton")
anchor:SetScript("OnDragStart", function(self)
	if not PersonalResourceBarDB.locked then
		self:StartMoving()
	end
end)
anchor:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	local db = PersonalResourceBarDB
	db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
end)

-- ===== Values =====

local function FormatValue(mode, current, max, token)
	if mode == "none" then
		return ""
	end
	if mode == "auto" then
		-- Matches how the game reads these: pools as a percentage,
		-- generated resources as the number itself.
		mode = (token == "HEALTH" or token == "MANA") and "percent" or "value"
	end

	local percent = math.floor(current / max * 100 + 0.5)
	if mode == "percent" then
		return percent .. "%"
	elseif mode == "both" then
		return current .. "  " .. percent .. "%"
	end
	return tostring(current)
end

local function UpdateBar(bar, current, max, textMode, token)
	if max <= 0 then
		max = 1
	end
	if current > max then
		current = max
	end

	bar:SetMinMaxValues(0, max)
	bar:SetValue(current)
	bar.text:SetText(FormatValue(textMode, current, max, token))

	if PersonalResourceBarDB.showSpark and current > 0 then
		bar.spark:ClearAllPoints()
		bar.spark:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * (current / max), 0)
		bar.spark:Show()
	else
		bar.spark:Hide()
	end
end

function PRB_ApplyColors()
	local hr, hg, hb = PRB_GetPowerColor("HEALTH")
	healthBar:SetStatusBarColor(hr, hg, hb)
	local pr, pg, pb = PRB_GetPowerColor(PRB.powerToken or "MANA")
	powerBar:SetStatusBarColor(pr, pg, pb)
end

local lastHealth, lastHealthMax
local lastPower, lastPowerMax, lastToken

local function UpdateHealth(force)
	local current = UnitHealth("player") or 0
	local max = UnitHealthMax("player") or 0
	if not force and current == lastHealth and max == lastHealthMax then
		return
	end
	lastHealth, lastHealthMax = current, max
	UpdateBar(healthBar, current, max, PersonalResourceBarDB.healthText, "HEALTH")
end

local function UpdatePower(force)
	local token = PRB_GetPowerToken(UnitPowerType("player"))
	local current = UnitPower("player") or 0
	local max = UnitPowerMax("player") or 0

	if not force and current == lastPower and max == lastPowerMax and token == lastToken then
		return
	end
	lastPower, lastPowerMax, lastToken = current, max, token

	if token ~= PRB.powerToken then
		PRB.powerToken = token
		PRB_ApplyColors()
	end
	UpdateBar(powerBar, current, max, PersonalResourceBarDB.powerText, token)
end

local function UpdateAll(force)
	UpdateHealth(force)
	UpdatePower(force)
end
PRB.UpdateAll = UpdateAll

-- ===== Layout =====

local function StyleBar(bar, height)
	local db = PersonalResourceBarDB
	bar:SetWidth(db.width)
	bar:SetHeight(height)
	-- Setting the texture clears the bar's color, so colors are applied
	-- again afterwards in PRB_ApplyLayout.
	bar:SetStatusBarTexture(db.texture)

	bar.spark:SetWidth(16)
	bar.spark:SetHeight(height * 2.2)

	local path, size = bar.text:GetFont()
	local target = math.floor(height * 0.62 + 0.5)
	if target < 8 then
		target = 8
	elseif target > 16 then
		target = 16
	end
	bar.text:SetFont(path, target, "OUTLINE")
end

function PRB_ApplyLayout()
	local db = PersonalResourceBarDB

	local totalHeight = db.powerHeight
	if db.showHealth then
		totalHeight = totalHeight + db.healthHeight + db.barSpacing
	end

	anchor:ClearAllPoints()
	anchor:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
	anchor:SetWidth(db.width)
	anchor:SetHeight(totalHeight)
	anchor:SetScale(db.scale)

	StyleBar(healthBar, db.healthHeight)
	StyleBar(powerBar, db.powerHeight)

	healthBar:ClearAllPoints()
	powerBar:ClearAllPoints()
	if db.showHealth then
		healthBar:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
		healthBar:Show()
		powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -db.barSpacing)
	else
		healthBar:Hide()
		powerBar:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
	end

	PRB_ApplyColors()

	-- A locked bar must not take mouse input, or it swallows clicks meant
	-- for the world behind it.
	if db.locked then
		anchor:EnableMouse(false)
		anchor.moveOverlay:Hide()
	else
		anchor:EnableMouse(true)
		anchor.moveOverlay:Show()
	end

	PRB_UpdateSecondaryLayout()
	UpdateAll(true)
end

function PRB_ResetSettings()
	local db = PersonalResourceBarDB
	for k, v in pairs(DEFAULTS) do
		db[k] = v
	end
	db.colors = {}
	PRB_ApplyLayout()
	PRB_RefreshSecondary()
end

-- ===== Events =====

-- 3.3.5a predates the unified UNIT_POWER event, so each power type has
-- its own event here.
local UNIT_EVENTS = {
	"UNIT_HEALTH", "UNIT_MAXHEALTH",
	"UNIT_MANA", "UNIT_MAXMANA",
	"UNIT_RAGE", "UNIT_MAXRAGE",
	"UNIT_FOCUS", "UNIT_MAXFOCUS",
	"UNIT_ENERGY", "UNIT_MAXENERGY",
	"UNIT_RUNIC_POWER", "UNIT_MAXRUNIC_POWER",
}

PRB:RegisterEvent("PLAYER_LOGIN")
PRB:RegisterEvent("PLAYER_ENTERING_WORLD")
PRB:RegisterEvent("UNIT_DISPLAYPOWER")
for _, event in ipairs(UNIT_EVENTS) do
	PRB:RegisterEvent(event)
end

PRB:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_LOGIN" then
		PRB_EnsureDB()
		PRB_InitSecondary()
		PRB_ApplyLayout()
	elseif event == "PLAYER_ENTERING_WORLD" then
		UpdateAll(true)
		PRB_RefreshSecondary()
	elseif event == "UNIT_DISPLAYPOWER" then
		if unit == "player" then
			UpdateAll(true)
			PRB_RefreshSecondary()
		end
	elseif unit == "player" then
		UpdateAll()
	end
end)

-- Private-server cores don't all fire the unit events reliably, so the
-- bars are also polled at a low rate to stay in sync.
local sinceLastUpdate = 0
anchor:SetScript("OnUpdate", function(self, elapsed)
	sinceLastUpdate = sinceLastUpdate + elapsed
	if sinceLastUpdate >= UPDATE_INTERVAL then
		sinceLastUpdate = 0
		UpdateAll()
	end
end)

-- ===== Slash commands =====

SLASH_PERSONALRESOURCEBAR1 = "/prb"
SlashCmdList["PERSONALRESOURCEBAR"] = function(msg)
	msg = string.gsub(string.lower(msg or ""), "^%s*(.-)%s*$", "%1")
	local db = PersonalResourceBarDB

	if msg == "lock" then
		db.locked = true
		PRB_ApplyLayout()
		Print("locked.")
	elseif msg == "unlock" then
		db.locked = false
		PRB_ApplyLayout()
		Print("unlocked - drag the bars to move them.")
	elseif msg == "reset" then
		PRB_ResetSettings()
		Print("settings reset to defaults.")
	elseif msg == "help" then
		Print("/prb - open options")
		Print("/prb unlock - unlock the bars so they can be dragged")
		Print("/prb lock - lock them back in place")
		Print("/prb reset - reset position, size and colors")
	else
		PRB_OpenOptions()
	end
end
