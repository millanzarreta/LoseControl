--[[ Code Credits - to the people whose code I borrowed and learned from:
Wowwiki
Kollektiv
Tuller
ckknight
The authors of Nao!!
And of course, Blizzard

Thanks! :)
]]

local function log(msg)	DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience

local abilities = LoseControlAbilities -- set by the localization files

-- Default settings
local DBdefaults = {
	Version = 1,
	Size = 36,
	Alpha = 1,
	position = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 0,
		y = 0
	}
}

LoseControlDB = CopyTable(DBdefaults) -- this gets overwritten later when the SavedVariables load

-- Create the main frame
local f = CreateFrame("Cooldown", "LoseControlFrame") -- Cooldown exposes the SetCooldown method
f.texture = f:CreateTexture(nil, "BACKGROUND") -- displays the debuff
f.texture:SetAllPoints(f) -- anchor the texture to the frame
f:SetFrameStrata("LOW") -- so the icon appears underneath combat text
f:SetReverse(true) -- makes the cooldown shade from light to dark instead of dark to light

-- Handle events
f:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end) -- if you call ANY function in "object:method"-style it's first parameter will be "object"
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("UNIT_AURA")

-- This function gets reused to update the frame when the defaults are set
function f:VARIABLES_LOADED() -- fired after all addons and savedvariables are loaded
	if LoseControlDB.Version < DBdefaults.Version then
		LoseControlDB = CopyTable(DBdefaults)
		log("LoseControl reset.")
	end
	self:SetWidth(LoseControlDB.Size)
	self:SetHeight(LoseControlDB.Size)
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:SetPoint(LoseControlDB.position.point, UIParent, LoseControlDB.position.relativePoint, LoseControlDB.position.x, LoseControlDB.position.y)
	self:SetAlpha(LoseControlDB.Alpha)
end

-- This is the main event
function f:UNIT_AURA(arg1) -- fired when a (de)buff is gained/lost
	if arg1 == "player" then
		local maxExpirationTime = 0
		local debuffTexture

		for i=1, DEBUFF_MAX_DISPLAY do -- Iterating through all the debuffs via index should be faster than checking specifically for each debuff above, because typically there aren't that many debuffs on the player.
			local name, _, icon, _, _, _, expirationTime = UnitDebuff("player", i)
			if not name then break end -- no more debuffs, terminate the loop
			--log(i .. ") " .. name .. " | " .. expirationTime )

			if abilities[name] and expirationTime > maxExpirationTime then -- see if the name exists as a key in our table first
				maxExpirationTime = expirationTime
				debuffTexture = icon
			end
		end

		if maxExpirationTime > 0 then
			if self.texture:GetTexture() ~= debuffTexture then -- this is a new debuff, so initialize the cooldown
				self.texture:SetTexture(debuffTexture)
				self:Show()
				self:SetCooldown( GetTime(), maxExpirationTime - GetTime() )
				self:SetAlpha(LoseControlDB.Alpha) -- hack to apply the alpha to the cooldown timer
			end
		else
			self.texture:SetTexture(nil)
			self:Hide()
		end
	end
end

-- Handle mouse dragging
f:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)

f:SetScript("OnDragStop", function(self)
	local point, _, relativePoint, x, y = self:GetPoint()
	LoseControlDB.position.point = point
	LoseControlDB.position.relativePoint = relativePoint
	LoseControlDB.position.x = x
	LoseControlDB.position.y = y
	self:StopMovingOrSizing()
end)

-- Add Interface Options
local LoseControlOptionsPanel = CreateFrame("Frame", "LoseControlOptionsPanel")
LoseControlOptionsPanel.name = "LoseControl"

local title = LoseControlOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(LoseControlOptionsPanel.name)

local subText = LoseControlOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subText:SetText("Displays the duration of CC effects on your character")

-- Slider helper function
local function CreateSlider(text, parent, low, high, step)
	local name = parent:GetName() .. text
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(160)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	_G[name .. "Text"]:SetText(text)
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)

	-- text slightly to the right of the slider to display the actual value
	slider.valText = slider:CreateFontString(nil, "BACKGROUND")
	slider.valText:SetFontObject("GameFontHighlightSmall")
	slider.valText:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	slider.valText:SetPoint("CENTER", slider, "RIGHT", 24, 1)

	return slider
end

local SizeSlider = CreateSlider("Size", LoseControlOptionsPanel, 16, 512, 4)
SizeSlider:SetScript("OnValueChanged", function(self, value)
	self.valText:SetText(value .. "px")
	LoseControlDB.Size = value
	f:SetWidth(value)
	f:SetHeight(value)
end)

local AlphaSlider = CreateSlider("Alpha", LoseControlOptionsPanel, 0, 100, 5) -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
AlphaSlider:SetScript("OnValueChanged", function(self, value)
	self.valText:SetText(value .. "%")
	LoseControlDB.Alpha = value / 100 -- the real alpha value
	f:SetAlpha(LoseControlDB.Alpha)
end)

BlizzardOptionsPanel_Slider_Disable(SizeSlider) -- disabled by default til unlock
BlizzardOptionsPanel_Slider_Disable(AlphaSlider) -- disabled by default til unlock

-- "Unlock" checkbox - allows the frame to be moved
local Unlock = CreateFrame("CheckButton", "LoseControlOptionsPanelUnlock", LoseControlOptionsPanel, "OptionsCheckButtonTemplate")
LoseControlOptionsPanelUnlockText:SetText("Unlock")
Unlock:SetScript("OnClick", function(self)
	if self:GetChecked() then
		BlizzardOptionsPanel_Slider_Enable(SizeSlider)
		BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		f:UnregisterEvent("UNIT_AURA")
		f:SetMovable(true)
		f:RegisterForDrag("LeftButton")
		f:EnableMouse(true)
		f.texture:SetTexture("Interface\\Icons\\spell_nature_polymorph")
		f:Show();
		f:SetCooldown( GetTime(), 60 )
		f:SetAlpha(LoseControlDB.Alpha) -- hack to apply the alpha to the cooldown timer
	else
		BlizzardOptionsPanel_Slider_Disable(SizeSlider)
		BlizzardOptionsPanel_Slider_Disable(AlphaSlider)
		f:RegisterEvent("UNIT_AURA")
		f:SetMovable(false)
		f:RegisterForDrag()
		f:EnableMouse(false)
		f.texture:SetTexture(nil);
		f:Hide();
	end
end)

-- Arrange them all neatly
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
Unlock:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
SizeSlider:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -16)
AlphaSlider:SetPoint("TOPLEFT", SizeSlider, "BOTTOMLEFT", 0, -16)

LoseControlOptionsPanel.default = function() -- This method will run when the player clicks "defaults".
	LoseControlDB.Version = 0
	f:VARIABLES_LOADED()
end

LoseControlOptionsPanel.refresh = function() -- This method will run when the Interface Options frame calls its OnShow function and after defaults have been applied via the panel.default method described above.
	SizeSlider:SetValue(LoseControlDB.Size)
	AlphaSlider:SetValue(LoseControlDB.Alpha * 100)
end

InterfaceOptions_AddCategory(LoseControlOptionsPanel)
