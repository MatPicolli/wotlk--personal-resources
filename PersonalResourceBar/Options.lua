-- Personal Resource Bar
-- Interface Options panel: lock/unlock, text, secondary widget, size,
-- scale and texture. Everything here just edits PersonalResourceBarDB
-- and re-applies it through PRB_ApplyLayout / PRB_RefreshSecondary.

local TEXTURES = {
	{ name = "Smooth",  path = "Interface\\TargetingFrame\\UI-StatusBar" },
	{ name = "Flat",    path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

local panel = CreateFrame("Frame", "PersonalResourceBarOptionsPanel", UIParent)
panel.name = "Personal Resource Bar"
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Personal Resource Bar")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetWidth(500)
subtitle:SetJustifyH("LEFT")
subtitle:SetText("Move the bar with /prb unlock, then drag it. Combo points and runes show up automatically for the classes that use them.")

local function CreateCheckbox(name, labelText, anchorTo, yOffset)
	local check = CreateFrame("CheckButton", name, panel, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, yOffset)
	check.Text = _G[name .. "Text"]
	check.Text:SetText(labelText)
	return check
end

local lockCheck = CreateCheckbox("PersonalResourceBarLockCheck", "Lock bar position", subtitle, -16)
local textCheck = CreateCheckbox("PersonalResourceBarTextCheck", "Show text (current / max)", lockCheck, -4)
local secondaryCheck = CreateCheckbox("PersonalResourceBarSecondaryCheck", "Show combo points / runes", textCheck, -4)

local function CreateSlider(name, labelText, anchorTo, yOffset, minVal, maxVal, step)
	local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 12, yOffset - 8)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	slider:SetWidth(220)
	_G[name .. "Text"]:SetText(labelText)
	_G[name .. "Low"]:SetText(tostring(minVal))
	_G[name .. "High"]:SetText(tostring(maxVal))
	return slider
end

local widthSlider = CreateSlider("PersonalResourceBarWidthSlider", "Width", secondaryCheck, -8, 100, 400, 1)
local heightSlider = CreateSlider("PersonalResourceBarHeightSlider", "Height", widthSlider, -16, 12, 50, 1)
local scaleSlider = CreateSlider("PersonalResourceBarScaleSlider", "Scale", heightSlider, -16, 0.5, 2.0, 0.05)

local textureLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
textureLabel:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", -12, -24)
textureLabel:SetText("Bar texture")

local textureDropdown = CreateFrame("Frame", "PersonalResourceBarTextureDropdown", panel, "UIDropDownMenuTemplate")
textureDropdown:SetPoint("TOPLEFT", textureLabel, "BOTTOMLEFT", -16, -4)

local function SetTexture(path, name)
	PersonalResourceBarDB.texture = path
	UIDropDownMenu_SetText(textureDropdown, name)
	PRB_ApplyLayout()
end

UIDropDownMenu_Initialize(textureDropdown, function()
	for _, t in ipairs(TEXTURES) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = t.name
		info.func = function() SetTexture(t.path, t.name) end
		UIDropDownMenu_AddButton(info)
	end
end)

local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetButton:SetPoint("TOPLEFT", textureDropdown, "BOTTOMLEFT", 16, -16)
resetButton:SetSize(140, 22)
resetButton:SetText("Reset position/size")
resetButton:SetScript("OnClick", function()
	SlashCmdList["PERSONALRESOURCEBAR"]("reset")
	PRB_RefreshPanel()
end)

lockCheck:SetScript("OnClick", function(self)
	PersonalResourceBarDB.locked = self:GetChecked()
	PRB_ApplyLayout()
end)

textCheck:SetScript("OnClick", function(self)
	PersonalResourceBarDB.showText = self:GetChecked()
	PRB_ApplyLayout()
end)

secondaryCheck:SetScript("OnClick", function(self)
	PersonalResourceBarDB.showSecondary = self:GetChecked()
	PRB_RefreshSecondary()
end)

widthSlider:SetScript("OnValueChanged", function(self, value)
	PersonalResourceBarDB.width = value
	PRB_ApplyLayout()
end)

heightSlider:SetScript("OnValueChanged", function(self, value)
	PersonalResourceBarDB.height = value
	PRB_ApplyLayout()
end)

scaleSlider:SetScript("OnValueChanged", function(self, value)
	PersonalResourceBarDB.scale = value
	PRB_ApplyLayout()
end)

function PRB_RefreshPanel()
	local db = PersonalResourceBarDB
	lockCheck:SetChecked(db.locked)
	textCheck:SetChecked(db.showText)
	secondaryCheck:SetChecked(db.showSecondary)
	widthSlider:SetValue(db.width)
	heightSlider:SetValue(db.height)
	scaleSlider:SetValue(db.scale)

	local textureName = "Smooth"
	for _, t in ipairs(TEXTURES) do
		if t.path == db.texture then
			textureName = t.name
		end
	end
	UIDropDownMenu_SetText(textureDropdown, textureName)
end

panel:SetScript("OnShow", function()
	PRB_EnsureDB()
	PRB_RefreshPanel()
end)

if InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(panel)
end

function PRB_OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(panel)
	-- Blizzard's own panels need this called twice the first time a
	-- category is opened in a session, or the list stays on "General".
	InterfaceOptionsFrame_OpenToCategory(panel)
end
