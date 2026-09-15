-- Personal Resource Bar
-- Interface Options panel. Every control writes to PersonalResourceBarDB
-- and re-applies it through PRB_ApplyLayout / PRB_RefreshSecondary.

local TEXTURES = {
	{ name = "Smooth", path = "Interface\\TargetingFrame\\UI-StatusBar" },
	{ name = "Flat",   path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

local DROPDOWN_NAME = "PersonalResourceBarTextureDropdown"

local panel = CreateFrame("Frame", "PersonalResourceBarOptionsPanel", UIParent)
panel.name = "Personal Resource Bar"
panel:Hide()

-- Set while the panel pushes saved values into its widgets, so the
-- widgets' own handlers don't write those values straight back.
local refreshing = false

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Personal Resource Bar")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", 16, -44)
subtitle:SetWidth(520)
subtitle:SetJustifyH("LEFT")
subtitle:SetText("Unlock the bar to drag it into place. Combo points and runes appear automatically for the classes that use them.")

local function CreateCheckbox(name, label, y)
	local check = CreateFrame("CheckButton", name, panel, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", 16, y)
	_G[name .. "Text"]:SetText(label)
	return check
end

local function CreateSlider(name, label, y, minVal, maxVal, step)
	local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", 20, y)
	slider:SetWidth(220)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	_G[name .. "Text"]:SetText(label)
	_G[name .. "Low"]:SetText(tostring(minVal))
	_G[name .. "High"]:SetText(tostring(maxVal))
	return slider
end

local lockCheck = CreateCheckbox("PersonalResourceBarLockCheck", "Lock bar position", -88)
local textCheck = CreateCheckbox("PersonalResourceBarTextCheck", "Show text (current / max)", -114)
local secondaryCheck = CreateCheckbox("PersonalResourceBarSecondaryCheck", "Show combo points / runes", -140)

local widthSlider = CreateSlider("PersonalResourceBarWidthSlider", "Width", -190, 100, 400, 1)
local heightSlider = CreateSlider("PersonalResourceBarHeightSlider", "Height", -238, 10, 50, 1)
local scaleSlider = CreateSlider("PersonalResourceBarScaleSlider", "Scale", -286, 0.5, 2.0, 0.05)

local textureLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
textureLabel:SetPoint("TOPLEFT", 20, -330)
textureLabel:SetText("Bar texture")

local textureDropdown = CreateFrame("Frame", DROPDOWN_NAME, panel, "UIDropDownMenuTemplate")
textureDropdown:SetPoint("TOPLEFT", 4, -350)

local colorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
colorLabel:SetPoint("TOPLEFT", 20, -400)
colorLabel:SetText("Color for the current resource")

local colorSwatch = CreateFrame("Button", "PersonalResourceBarColorSwatch", panel)
colorSwatch:SetPoint("TOPLEFT", 240, -394)
colorSwatch:SetWidth(24)
colorSwatch:SetHeight(24)
colorSwatch.color = colorSwatch:CreateTexture(nil, "ARTWORK")
colorSwatch.color:SetAllPoints(colorSwatch)

local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetButton:SetPoint("TOPLEFT", 20, -440)
resetButton:SetWidth(160)
resetButton:SetHeight(22)
resetButton:SetText("Reset all settings")

-- ===== Behavior =====

-- The dropdown's label is set directly instead of through
-- UIDropDownMenu_SetText, whose argument order differs between 3.3.5a
-- and later clients.
local function SetDropdownLabel(text)
	local label = _G[DROPDOWN_NAME .. "Text"]
	if label then
		label:SetText(text)
	end
end

local function UpdateSwatch()
	local r, g, b = PRB_GetPowerColor(PRB.powerToken or "MANA")
	colorSwatch.color:SetTexture(r, g, b, 1)
end

local function OpenColorPicker()
	local token = PRB.powerToken or "MANA"
	local r, g, b = PRB_GetPowerColor(token)

	local function Apply()
		local nr, ng, nb = ColorPickerFrame:GetColorRGB()
		PersonalResourceBarDB.colors[token] = { r = nr, g = ng, b = nb }
		PRB_ApplyColor()
		UpdateSwatch()
	end

	local function Cancel(previous)
		if previous then
			PersonalResourceBarDB.colors[token] = { r = previous.r, g = previous.g, b = previous.b }
			PRB_ApplyColor()
			UpdateSwatch()
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
end

UIDropDownMenu_Initialize(textureDropdown, function()
	for _, t in ipairs(TEXTURES) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = t.name
		info.checked = (PersonalResourceBarDB.texture == t.path)
		info.func = function()
			PersonalResourceBarDB.texture = t.path
			SetDropdownLabel(t.name)
			PRB_ApplyLayout()
		end
		UIDropDownMenu_AddButton(info)
	end
end)

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
textCheck:SetScript("OnClick", BoolSetter("showText", PRB_ApplyLayout))
secondaryCheck:SetScript("OnClick", BoolSetter("showSecondary", PRB_RefreshSecondary))

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
heightSlider:SetScript("OnValueChanged", NumberSetter("height", true))
scaleSlider:SetScript("OnValueChanged", NumberSetter("scale", false))

colorSwatch:SetScript("OnClick", OpenColorPicker)

resetButton:SetScript("OnClick", function()
	PRB_ResetSettings()
	PRB_RefreshPanel()
end)

function PRB_RefreshPanel()
	local db = PRB_EnsureDB()
	refreshing = true

	lockCheck:SetChecked(db.locked)
	textCheck:SetChecked(db.showText)
	secondaryCheck:SetChecked(db.showSecondary)
	widthSlider:SetValue(db.width)
	heightSlider:SetValue(db.height)
	scaleSlider:SetValue(db.scale)

	local textureName = TEXTURES[1].name
	for _, t in ipairs(TEXTURES) do
		if t.path == db.texture then
			textureName = t.name
		end
	end
	SetDropdownLabel(textureName)
	UpdateSwatch()

	refreshing = false
end

panel:SetScript("OnShow", PRB_RefreshPanel)

InterfaceOptions_AddCategory(panel)

function PRB_OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(panel)
	-- Known Blizzard quirk: the first call only opens the parent list.
	InterfaceOptionsFrame_OpenToCategory(panel)
end
