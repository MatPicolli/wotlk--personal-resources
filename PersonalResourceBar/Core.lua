-- Personal Resource Bar
-- Main power bar: tracks the player's active power (mana, rage, energy,
-- runic power, ...), colors itself to match, and anchors the per-class
-- secondary resource widget underneath.

PRB = CreateFrame("Frame", "PersonalResourceBarAddon", UIParent)
PRB.version = "1.1.0"

local DEFAULTS = {
	point = "CENTER",
	relPoint = "CENTER",
	x = 0,
	y = -200,
	width = 220,
	height = 20,
	scale = 1.0,
	locked = true,
	showText = true,
	showSecondary = true,
	texture = "Interface\\TargetingFrame\\UI-StatusBar",
}

local UPDATE_INTERVAL = 0.1

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

-- ===== Main bar =====

local bar = CreateFrame("StatusBar", "PersonalResourceBar_MainBar", UIParent)
PRB.bar = bar

bar:SetFrameStrata("MEDIUM")
bar:SetMovable(true)
bar:SetClampedToScreen(true)
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)

bar.bg = bar:CreateTexture(nil, "BACKGROUND")
bar.bg:SetAllPoints(bar)
bar.bg:SetTexture(0, 0, 0, 0.6)

-- 3.3.5a has no BackdropTemplate, so the border is four thin textures.
local function AddBorder(frame)
	local inset = 1
	local top = frame:CreateTexture(nil, "BORDER")
	top:SetTexture(0, 0, 0, 1)
	top:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
	top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", inset, inset)
	top:SetHeight(inset)

	local bottom = frame:CreateTexture(nil, "BORDER")
	bottom:SetTexture(0, 0, 0, 1)
	bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -inset, -inset)
	bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
	bottom:SetHeight(inset)

	local left = frame:CreateTexture(nil, "BORDER")
	left:SetTexture(0, 0, 0, 1)
	left:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
	left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -inset, -inset)
	left:SetWidth(inset)

	local right = frame:CreateTexture(nil, "BORDER")
	right:SetTexture(0, 0, 0, 1)
	right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", inset, inset)
	right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
	right:SetWidth(inset)
end
AddBorder(bar)

bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)

-- Shown only while the bar is unlocked, so an empty bar is still grabbable.
bar.moveOverlay = bar:CreateTexture(nil, "OVERLAY")
bar.moveOverlay:SetAllPoints(bar)
bar.moveOverlay:SetTexture(0, 1, 0, 0.25)
bar.moveOverlay:Hide()

bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", function(self)
	if not PersonalResourceBarDB.locked then
		self:StartMoving()
	end
end)
bar:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	local db = PersonalResourceBarDB
	db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
end)

-- ===== Power tracking =====

function PRB_ApplyColor()
	local r, g, b = PRB_GetPowerColor(PRB.powerToken or "MANA")
	bar:SetStatusBarColor(r, g, b)
end

local lastPower, lastMax, lastToken

local function UpdatePower(force)
	local token = PRB_GetPowerToken(UnitPowerType("player"))
	local power = UnitPower("player") or 0
	local max = UnitPowerMax("player") or 0
	if max <= 0 then
		max = 1
	end

	if not force and power == lastPower and max == lastMax and token == lastToken then
		return
	end
	lastPower, lastMax, lastToken = power, max, token

	if token ~= PRB.powerToken then
		PRB.powerToken = token
		PRB_ApplyColor()
	end

	bar:SetMinMaxValues(0, max)
	bar:SetValue(power)
	bar.text:SetText(power .. " / " .. max)
end
PRB.UpdatePower = UpdatePower

-- ===== Layout / appearance =====

function PRB_ApplyLayout()
	local db = PersonalResourceBarDB
	bar:ClearAllPoints()
	bar:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
	bar:SetWidth(db.width)
	bar:SetHeight(db.height)
	bar:SetScale(db.scale)
	-- Setting the texture clears the bar's color, so re-apply it after.
	bar:SetStatusBarTexture(db.texture)
	PRB_ApplyColor()

	if db.showText then
		bar.text:Show()
	else
		bar.text:Hide()
	end

	-- A locked bar must not take mouse input, or it swallows clicks meant
	-- for the world behind it.
	if db.locked then
		bar:EnableMouse(false)
		bar.moveOverlay:Hide()
	else
		bar:EnableMouse(true)
		bar.moveOverlay:Show()
	end

	PRB_UpdateSecondaryLayout()
	UpdatePower(true)
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
local POWER_EVENTS = {
	"UNIT_MANA", "UNIT_MAXMANA",
	"UNIT_RAGE", "UNIT_MAXRAGE",
	"UNIT_FOCUS", "UNIT_MAXFOCUS",
	"UNIT_ENERGY", "UNIT_MAXENERGY",
	"UNIT_RUNIC_POWER", "UNIT_MAXRUNIC_POWER",
}

PRB:RegisterEvent("PLAYER_LOGIN")
PRB:RegisterEvent("PLAYER_ENTERING_WORLD")
PRB:RegisterEvent("UNIT_DISPLAYPOWER")
for _, event in ipairs(POWER_EVENTS) do
	PRB:RegisterEvent(event)
end

PRB:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_LOGIN" then
		PRB_EnsureDB()
		PRB_InitSecondary()
		PRB_ApplyLayout()
	elseif event == "PLAYER_ENTERING_WORLD" then
		UpdatePower(true)
		PRB_RefreshSecondary()
	elseif event == "UNIT_DISPLAYPOWER" then
		if unit == "player" then
			UpdatePower(true)
			PRB_RefreshSecondary()
		end
	elseif unit == "player" then
		UpdatePower()
	end
end)

-- Private-server cores don't all fire the power events reliably, so the
-- bar is also polled at a low rate to stay in sync.
local sinceLastUpdate = 0
bar:SetScript("OnUpdate", function(self, elapsed)
	sinceLastUpdate = sinceLastUpdate + elapsed
	if sinceLastUpdate >= UPDATE_INTERVAL then
		sinceLastUpdate = 0
		UpdatePower()
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
		Print("unlocked - drag the bar to move it.")
	elseif msg == "reset" then
		PRB_ResetSettings()
		Print("settings reset to defaults.")
	elseif msg == "help" then
		Print("/prb - open options")
		Print("/prb unlock - unlock the bar so it can be dragged")
		Print("/prb lock - lock the bar back in place")
		Print("/prb reset - reset position, size and colors")
	else
		PRB_OpenOptions()
	end
end
