-- Personal Resource Bar
-- Interface Options panel. Every control writes to PersonalResourceBarDB
-- and re-applies it through PRB_ApplyLayout / PRB_RefreshSecondary.

local TEXTURES = {
	{ value = "Interface\\TargetingFrame\\UI-StatusBar", text = "Smooth" },
	{ value = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", text = "Flat" },
}

local TEXT_MODES = {
	{ value = "auto",    text = "Auto" },
	{ value = "percent", text = "Percent" },
	{ value = "value",   text = "Value" },
	{ value = "both",    text = "Value + percent" },
	{ value = "none",    text = "Hidden" },
}

local LEFT, RIGHT = 16, 330

local panel = CreateFrame("Frame", "PersonalResourceBarOptionsPanel", UIParent)
panel.name = "Personal Resource Bar"
panel:Hide()

-- Set while the panel pushes saved values into its widgets, so the
-- widgets' own handlers don't write those values straight back.
local refreshing = false

local dropdowns = {}

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", LEFT, -16)
title:SetText("Personal Resource Bar")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", LEFT, -40)
subtitle:SetWidth(560)
subtitle:SetJustifyH("LEFT")
subtitle:SetText("Unlock the bars to drag them. Combo points and runes appear automatically for the classes that use them.")

local function CreateCheckbox(name, label, y)
	local check = CreateFrame("CheckButton", name, panel, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", LEFT, y)
	_G[name .. "Text"]:SetText(label)
	return check
end

local function CreateSlider(name, label, y, minVal, maxVal, step)
	local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", LEFT + 4, y)
	slider:SetWidth(220)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	_G[name .. "Text"]:SetText(label)
	_G[name .. "Low"]:SetText(tostring(minVal))
	_G[name .. "High"]:SetText(tostring(maxVal))
	return slider
end

-- The dropdown label is set directly instead of through
-- UIDropDownMenu_SetText, whose argument order differs between 3.3.5a and
-- later clients.
local function SetDropdownLabel(name, text)
	local label = _G[name .. "Text"]
	if label then
		label:SetText(text)
	end
end

local function CreateDropdown(name, label, y, entries, key, onChange)
	local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	heading:SetPoint("TOPLEFT", RIGHT, y)
	heading:SetText(label)

	local dropdown = CreateFrame("Frame", name, panel, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", RIGHT - 16, y - 18)

	UIDropDownMenu_Initialize(dropdown, function()
		for _, entry in ipairs(entries) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = entry.text
			info.checked = (PersonalResourceBarDB[key] == entry.value)
			info.func = function()
				PersonalResourceBarDB[key] = entry.value
				SetDropdownLabel(name, entry.text)
				onChange()
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	dropdowns[#dropdowns + 1] = { name = name, entries = entries, key = key }
	return dropdown
end

local function CreateColorSwatch(name, label, y, tokenFor)
	local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	heading:SetPoint("TOPLEFT", RIGHT, y)
	heading:SetText(label)

	local swatch = CreateFrame("Button", name, panel)
	swatch:SetPoint("TOPLEFT", RIGHT + 230, y - 4)
	swatch:SetWidth(24)
	swatch:SetHeight(24)
	swatch.color = swatch:CreateTexture(nil, "ARTWORK")
	swatch.color:SetAllPoints(swatch)
	swatch.tokenFor = tokenFor

	swatch:SetScript("OnClick", function(self)
		local token = self.tokenFor()
		local r, g, b = PRB_GetPowerColor(token)

		local function Apply()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB()
			PersonalResourceBarDB.colors[token] = { r = nr, g = ng, b = nb }
			PRB_ApplyColors()
			PRB_RefreshPanel()
		end

		local function Cancel(previous)
			if previous then
				PersonalResourceBarDB.colors[token] = { r = previous.r, g = previous.g, b = previous.b }
				PRB_ApplyColors()
				PRB_RefreshPanel()
			end
		end

		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.func = Apply
		ColorPickerFrame.opacityFunc = Apply
		ColorPickerFrame.cancelFunc = Cancel
		ColorPickerFrame.previousValues = { r = r, g = g, b = b }
		ColorPickerFrame:SetColorRGB(r, g, b)
		-- Re-show so the picker refreshes if it was already open.
		ColorPickerFrame:Hide()
		ColorPickerFrame:Show()
	end)

	return swatch
end

-- ===== Controls =====

local lockCheck = CreateCheckbox("PersonalResourceBarLockCheck", "Lock position", -74)
local healthCheck = CreateCheckbox("PersonalResourceBarHealthCheck", "Show health bar", -98)
local secondaryCheck = CreateCheckbox("PersonalResourceBarSecondaryCheck", "Show combo points / runes", -122)
local sparkCheck = CreateCheckbox("PersonalResourceBarSparkCheck", "Show spark on bar edge", -146)

local widthSlider = CreateSlider("PersonalResourceBarWidthSlider", "Width", -184, 100, 400, 1)
local healthHeightSlider = CreateSlider("PersonalResourceBarHealthHeightSlider", "Health bar height", -228, 6, 40, 1)
local powerHeightSlider = CreateSlider("PersonalResourceBarPowerHeightSlider", "Power bar height", -272, 6, 40, 1)
local orbSizeSlider = CreateSlider("PersonalResourceBarOrbSizeSlider", "Combo point / rune size", -316, 8, 32, 1)
local scaleSlider = CreateSlider("PersonalResourceBarScaleSlider", "Scale", -360, 0.5, 2.0, 0.05)

local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetButton:SetPoint("TOPLEFT", LEFT, -404)
resetButton:SetWidth(160)
resetButton:SetHeight(22)
resetButton:SetText("Reset all settings")

CreateDropdown("PersonalResourceBarTextureDropdown", "Bar texture", -74, TEXTURES, "texture", function()
	PRB_ApplyLayout()
end)
CreateDropdown("PersonalResourceBarHealthTextDropdown", "Health text", -140, TEXT_MODES, "healthText", function()
	PRB_ApplyLayout()
end)
CreateDropdown("PersonalResourceBarPowerTextDropdown", "Resource text", -206, TEXT_MODES, "powerText", function()
	PRB_ApplyLayout()
end)

local healthSwatch = CreateColorSwatch("PersonalResourceBarHealthSwatch", "Health bar color", -280, function()
	return "HEALTH"
end)
local powerSwatch = CreateColorSwatch("PersonalResourceBarPowerSwatch", "Current resource color", -320, function()
	return PRB.powerToken or "MANA"
end)

-- ===== Behavior =====

-- GetChecked() returns 1 or nil on 3.3.5a; these are normalized to real
-- booleans so an unchecked box saves as false instead of nil, which the
-- defaults would otherwise fill back in on the next login.
local function BoolSetter(key, after)
	return function(self)
		PersonalResourceBarDB[key] = self:GetChecked() and true or false
		after()
	end
end

lockCheck:SetScript("OnClick", BoolSetter("locked", PRB_ApplyLayout))
healthCheck:SetScript("OnClick", BoolSetter("showHealth", PRB_ApplyLayout))
secondaryCheck:SetScript("OnClick", BoolSetter("showSecondary", PRB_RefreshSecondary))
sparkCheck:SetScript("OnClick", BoolSetter("showSpark", PRB_ApplyLayout))

local function NumberSetter(key, round)
	return function(self, value)
		if refreshing then
			return
		end
		PersonalResourceBarDB[key] = round and math.floor(value + 0.5) or value
		PRB_ApplyLayout()
	end
end

widthSlider:SetScript("OnValueChanged", NumberSetter("width", true))
healthHeightSlider:SetScript("OnValueChanged", NumberSetter("healthHeight", true))
powerHeightSlider:SetScript("OnValueChanged", NumberSetter("powerHeight", true))
orbSizeSlider:SetScript("OnValueChanged", NumberSetter("orbSize", true))
scaleSlider:SetScript("OnValueChanged", NumberSetter("scale", false))

resetButton:SetScript("OnClick", function()
	PRB_ResetSettings()
	PRB_RefreshPanel()
end)

function PRB_RefreshPanel()
	local db = PRB_EnsureDB()
	refreshing = true

	lockCheck:SetChecked(db.locked)
	healthCheck:SetChecked(db.showHealth)
	secondaryCheck:SetChecked(db.showSecondary)
	sparkCheck:SetChecked(db.showSpark)

	widthSlider:SetValue(db.width)
	healthHeightSlider:SetValue(db.healthHeight)
	powerHeightSlider:SetValue(db.powerHeight)
	orbSizeSlider:SetValue(db.orbSize)
	scaleSlider:SetValue(db.scale)

	for _, entry in ipairs(dropdowns) do
		local label = entry.entries[1].text
		for _, option in ipairs(entry.entries) do
			if option.value == db[entry.key] then
				label = option.text
			end
		end
		SetDropdownLabel(entry.name, label)
	end

	local hr, hg, hb = PRB_GetPowerColor("HEALTH")
	healthSwatch.color:SetTexture(hr, hg, hb, 1)
	local pr, pg, pb = PRB_GetPowerColor(PRB.powerToken or "MANA")
	powerSwatch.color:SetTexture(pr, pg, pb, 1)

	refreshing = false
end

panel:SetScript("OnShow", PRB_RefreshPanel)

InterfaceOptions_AddCategory(panel)

function PRB_OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(panel)
	-- Known Blizzard quirk: the first call only opens the parent list.
	InterfaceOptionsFrame_OpenToCategory(panel)
end
