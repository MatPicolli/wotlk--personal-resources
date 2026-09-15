-- Personal Resource Bar
-- Main resource bar: a modern-style "personal resource bar" that tracks
-- the player's primary power (mana/rage/energy/runic power/...) and
-- colors itself automatically, plus hosts the per-class secondary
-- resource widget (combo points, runes) defined in Classes.lua.

PRB = CreateFrame("Frame", "PersonalResourceBarAddon", UIParent)
PRB.version = "1.0.0"

local DEFAULTS = {
	point = "CENTER",
	relPoint = "CENTER",
	x = 0,
	y = -220,
	width = 220,
	height = 22,
	scale = 1.0,
	locked = true,
	showText = true,
	showSecondary = true,
	texture = "Interface\\TargetingFrame\\UI-StatusBar",
}

local function CopyDefaults(dst, src)
	for k, v in pairs(src) do
		if dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end

function PRB_EnsureDB()
	PersonalResourceBarDB = PersonalResourceBarDB or {}
	CopyDefaults(PersonalResourceBarDB, DEFAULTS)
	return PersonalResourceBarDB
end

-- ===== Main bar =====

local bar = CreateFrame("StatusBar", "PersonalResourceBar_MainBar", UIParent)
PRB.bar = bar

bar:SetFrameStrata("MEDIUM")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)

bar.bg = bar:CreateTexture(nil, "BACKGROUND")
bar.bg:SetAllPoints(bar)
bar.bg:SetTexture(0, 0, 0, 0.6)

-- 3.3.5 has no BackdropTemplate (that's a Legion+ addition), so the
-- border is just four thin textures pinned around the bar.
local function AddBorder(frame)
	local t = {}
	local inset = 1
	t.top = frame:CreateTexture(nil, "BORDER")
	t.top:SetTexture(0, 0, 0, 1)
	t.top:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
	t.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", inset, inset)
	t.top:SetHeight(inset)

	t.bottom = frame:CreateTexture(nil, "BORDER")
	t.bottom:SetTexture(0, 0, 0, 1)
	t.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -inset, -inset)
	t.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
	t.bottom:SetHeight(inset)

	t.left = frame:CreateTexture(nil, "BORDER")
	t.left:SetTexture(0, 0, 0, 1)
	t.left:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
	t.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -inset, -inset)
	t.left:SetWidth(inset)

	t.right = frame:CreateTexture(nil, "BORDER")
	t.right:SetTexture(0, 0, 0, 1)
	t.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", inset, inset)
	t.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
	t.right:SetWidth(inset)
end
AddBorder(bar)

bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)

bar:EnableMouse(true)
bar:SetMovable(true)
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", function(self)
	if not PersonalResourceBarDB.locked then
		self:StartMoving()
	end
end)
bar:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local point, _, relPoint, x, y = self:GetPoint()
	PersonalResourceBarDB.point = point
	PersonalResourceBarDB.relPoint = relPoint
	PersonalResourceBarDB.x = x
	PersonalResourceBarDB.y = y
end)

-- ===== Layout / appearance =====

function PRB_ApplyLayout()
	local db = PersonalResourceBarDB
	bar:ClearAllPoints()
	bar:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
	bar:SetSize(db.width, db.height)
	bar:SetScale(db.scale)
	bar:SetStatusBarTexture(db.texture)
	bar.bg:SetTexture(0, 0, 0, 0.6)
	-- SetShown() doesn't exist on the 3.3.5 client (it's a later addition),
	-- so toggle visibility with Show/Hide instead.
	if db.showText then
		bar.text:Show()
	else
		bar.text:Hide()
	end

	if db.locked then
		bar:SetAlpha(1)
	end

	if PRB_UpdateSecondaryLayout then
		PRB_UpdateSecondaryLayout()
	end
end

-- ===== Power tracking =====

local currentToken = nil

local function UpdatePower()
	local unit = "player"
	local _, token = UnitPowerType(unit)
	local cur = UnitPower(unit)
	local max = UnitPowerMax(unit)

	if max <= 0 then
		max = 1
	end

	bar:SetMinMaxValues(0, max)
	bar:SetValue(cur)

	if token ~= currentToken then
		currentToken = token
		local r, g, b = PRB_GetPowerColor(token)
		bar:SetStatusBarColor(r, g, b)
	end

	if PersonalResourceBarDB.showText then
		bar.text:SetText(string.format("%d / %d", cur, max))
	end
end
PRB.UpdatePower = UpdatePower

-- ===== Events =====

PRB:RegisterEvent("PLAYER_LOGIN")
PRB:RegisterEvent("PLAYER_ENTERING_WORLD")
PRB:RegisterEvent("UNIT_POWER")
PRB:RegisterEvent("UNIT_MAXPOWER")
PRB:RegisterEvent("UNIT_DISPLAYPOWER")

PRB:SetScript("OnEvent", function(self, event, unit, ...)
	if event == "PLAYER_LOGIN" then
		PRB_EnsureDB()
		PRB_ApplyLayout()
		currentToken = nil
		UpdatePower()
		if PRB_InitSecondary then
			PRB_InitSecondary()
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		currentToken = nil
		UpdatePower()
		if PRB_RefreshSecondary then
			PRB_RefreshSecondary()
		end
	elseif event == "UNIT_POWER" or event == "UNIT_MAXPOWER" then
		if unit == "player" then
			UpdatePower()
		end
	elseif event == "UNIT_DISPLAYPOWER" then
		if unit == "player" then
			currentToken = nil
			UpdatePower()
			if PRB_RefreshSecondary then
				PRB_RefreshSecondary()
			end
		end
	end
end)

-- ===== Slash command =====

SLASH_PERSONALRESOURCEBAR1 = "/prb"
SlashCmdList["PERSONALRESOURCEBAR"] = function(msg)
	msg = strtrim((msg or ""):lower())
	local db = PersonalResourceBarDB
	if msg == "lock" then
		db.locked = true
		print("|cff33ff99Personal Resource Bar|r: locked.")
	elseif msg == "unlock" then
		db.locked = false
		print("|cff33ff99Personal Resource Bar|r: unlocked, drag the bar to move it.")
	elseif msg == "reset" then
		for k, v in pairs(DEFAULTS) do
			db[k] = v
		end
		PRB_ApplyLayout()
		print("|cff33ff99Personal Resource Bar|r: position and size reset.")
	else
		if PRB_OpenOptions then
			PRB_OpenOptions()
		end
	end
end
