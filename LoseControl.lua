--[[ Code Credits - to the people whose code I borrowed and learned from:
Wowwiki
Kollektiv
Tuller
ckknight
The authors of Nao!!
And of course, Blizzard

Thanks! :)
]]

local L = "LoseControl"

local function log(msg)	DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience

local CC      = LOSECONTROL_CC
local Silence = LOSECONTROL_SILENCE
local Disarm  = LOSECONTROL_DISARM
local Root    = LOSECONTROL_ROOT
local Snare   = LOSECONTROL_SNARE

local spellIds = {
	-- Death Knight
	[47481] = CC,		-- Gnaw
	[51209] = CC,		-- Hungering Cold
	[47476] = Silence,	-- Strangulate
	[45524] = Snare,	-- Chains of Ice
	[58617] = Snare,	-- Glyph of Blood Boil
	-- Druid
	[5211]  = CC,		-- Bash
	[33786] = CC,		-- Cyclone
	[2637]  = CC,		-- Hibernate (works against Druids in most forms and Shamans using Ghost Wolf)
	[22570] = CC,		-- Maim
	[9005]  = CC,		-- Pounce
	[339]   = Root,		-- Entangling Roots
	[19675] = Root,		-- Feral Charge Effect (immobilize with interrupt [spell lockout, not silence])
	[58179] = Snare,	-- Infected Wounds
	-- Hunter
	[1499]  = CC,		-- Freezing Trap
	[24394] = CC,		-- Intimidation
	[1513]  = CC,		-- Scare Beast (works against Druids in most forms and Shamans using Ghost Wolf)
	[19503] = CC,		-- Scatter Shot
	[56338] = CC,		-- T.N.T.
	[19386] = CC,		-- Wyvern Sting
	[34490] = Silence,	-- Silencing Shot
	[53359] = Disarm,	-- Chimera Shot - Scorpid
	[19306] = Root,		-- Counterattack
	[19185] = Root,		-- Entrapment
	[19229] = Root,		-- Improved Wing Clip
	[35101] = Snare,	-- Concussive Barrage
	[5116]  = Snare,	-- Concussive Shot
	--[13810] = Snare,	-- Frost Trap Aura (no duration, lasts as long as you stand in it)
	[61394] = Snare,	-- Glyph of Freezing Trap
	[2974]  = Snare,	-- Wing Clip
	-- Mage
	[44572] = CC,		-- Deep Freeze
	[31661] = CC,		-- Dragon's Breath
	[12355] = CC,		-- Impact
	[118]   = CC,		-- Polymorph
	[18469] = Silence,	-- Silenced - Improved Counterspell
	[33395] = Root,		-- Freeze (Water Elemental)
	[122]   = Root,		-- Frost Nova
	[11071] = Root,		-- Frostbite
	[55080] = Root,		-- Shattered Barrier
	[11113] = Snare,	-- Blast Wave
	[6136]  = Snare,	-- Chilled (generic effect, used by lots of spells [looks weird on Improved Blizzard, might want to comment out])
	[120]   = Snare,	-- Cone of Cold
	[116]   = Snare,	-- Frostbolt
	[31589] = Snare,	-- Slow
	-- Paladin
	[853]   = CC,		-- Hammer of Justice
	[2812]  = CC,		-- Holy Wrath (works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	[20066] = CC,		-- Repentance
	[20170] = CC,		-- Stun (Seal of Justice proc)
	[10326] = CC,		-- Turn Evil (works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	--[20184] = Snare,	-- Judgement of Justice (not really a slow, druids might want this though)
	-- Priest
	[15269] = CC,		-- Blackout
	[605]   = CC,		-- Mind Control
	[8122]  = CC,		-- Psychic Scream
	[9484]  = CC,		-- Shackle Undead (works against Death Knights using Lichborne)
	[15487] = Silence,	-- Silence
	[15407] = Snare,	-- Mind Flay
	-- Rogue
	[2094]  = CC,		-- Blind
	[1833]  = CC,		-- Cheap Shot
	[1776]  = CC,		-- Gouge
	[408]   = CC,		-- Kidney Shot
	[6770]  = CC,		-- Sap
	[1330]  = Silence,	-- Garrote - Silence
	[18425] = Silence,	-- Silenced - Improved Kick
	[51722] = Disarm,	-- Dismantle
	[31125] = Snare,	-- Blade Twisting
	[3409]  = Snare,	-- Crippling Poison
	[26679] = Snare,	-- Deadly Throw
	-- Shaman
	[51880] = CC,		-- Improved Fire Nova Totem
	[39796] = CC,		-- Stoneclaw Stun
	[51514] = CC,		-- Hex (although effectively a silence+disarm effect, it is conventionally thought of as a CC, plus you can trinket out of it)
	--[3600]  = Snare,	-- Earthbind (no duration, lasts as long as you stand in it)
	[8056]  = Snare,	-- Frost Shock
	[8034]  = Snare,	-- Frostbrand Attack
	-- Warlock
	[710]   = CC,		-- Banish (works against Warlocks using Metamorphasis and Druids using Tree Form)
	[6789]  = CC,		-- Death Coil
	[5782]  = CC,		-- Fear
	[5484]  = CC,		-- Howl of Terror
	[18093] = CC,		-- Pyroclasm
	[6358]  = CC,		-- Seduction (Succubus)
	[30283] = CC,		-- Shadowfury
	[24259] = Silence,	-- Spell Lock
	[18118] = Snare,	-- Aftermath
	[18223] = Snare,	-- Curse of Exhaustion
	-- Warrior
	[7922]  = CC,		-- Charge Stun
	[12809] = CC,		-- Concussion Blow
	[20253] = CC,		-- Intercept
	[5246]  = CC,		-- Intimidating Shout
	[12798] = CC,		-- Revenge Stun
	[46968] = CC,		-- Shockwave
	[18498] = Silence,	-- Silenced - Gag Order
	[676]   = Disarm,	-- Disarm
	[58373] = Root,		-- Glyph of Hamstring
	[23694] = Root,		-- Improved Hamstring
	[1715]  = Snare,	-- Hamstring
	[12323] = Snare,	-- Piercing Howl
	-- Other
	[30217] = CC,		-- Adamantite Grenade
	[30216] = CC,		-- Fel Iron Bomb
	[20549] = CC,		-- War Stomp
	[25046] = Silence,	-- Arcane Torrent
	[55536] = Root,		-- Frostweave Net
	[13099] = Root,		-- Net-o-Matic
	[29703] = Snare,	-- Dazed
}
local tracking
local abilities = {} -- localized names are saved here
for key,value in pairs(spellIds) do
	abilities[GetSpellInfo(key)] = value
end

-- Default settings
local DBdefaults = {
	Version = 1.3,
	Size = 36,
	Alpha = 1,
	position = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 0,
		y = 0
	},
	noCooldownCount = false,
	tracking = {
		[CC]      = true,
		[Silence] = true,
		[Disarm]  = true,
		[Root]    = false,
		[Snare]   = false
	}
}

LoseControlDB = CopyTable(DBdefaults) -- this gets overwritten later when the SavedVariables load

-- Create the main frame
local f = CreateFrame("Cooldown", L.."Frame") -- Cooldown exposes the SetCooldown method
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
		log(LOSECONTROL_RESET)
	end
	self:SetWidth(LoseControlDB.Size)
	self:SetHeight(LoseControlDB.Size)
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:SetPoint(LoseControlDB.position.point, UIParent, LoseControlDB.position.relativePoint, LoseControlDB.position.x, LoseControlDB.position.y)
	self:SetAlpha(LoseControlDB.Alpha)
	self.noCooldownCount = LoseControlDB.noCooldownCount
	tracking = LoseControlDB.tracking
end

-- This is the main event
function f:UNIT_AURA(arg1) -- fired when a (de)buff is gained/lost
	if arg1 ~= "player" then return end

	local maxExpirationTime = 0
	local maxDuration, maxIcon

	for i=1, 40 do
		local name, rank, icon, count, debuffType, duration, expirationTime =  UnitDebuff("player", i)

		if not name then break end -- no more debuffs, terminate the loop
		--log(i .. ") " .. name .. " | " .. rank .. " | " .. icon .. " | " .. count .. " | " .. debuffType .. " | " .. duration .. " | " .. expirationTime )

		if tracking[abilities[name]] and expirationTime > maxExpirationTime and not (debuffType == "Poison" and duration == 6) then -- hack for Wyvern Sting
			maxExpirationTime = expirationTime
			maxDuration = duration
			maxIcon = icon
		end
	end

	if maxExpirationTime == 0 then -- no debuffs found
		self.maxExpirationTime = 0
		self:Hide()
	elseif maxExpirationTime ~= self.maxExpirationTime then -- this is a different debuff, so initialize the cooldown
		self.maxExpirationTime = maxExpirationTime
		self.texture:SetTexture(maxIcon)
		self:Show()
		self:SetCooldown( maxExpirationTime - maxDuration, maxDuration )
		self:SetAlpha(LoseControlDB.Alpha) -- hack to apply the alpha to the cooldown timer
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
local O = L .. "OptionsPanel"

local OptionsPanel = CreateFrame("Frame", O)
OptionsPanel.name = L

local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(L)

local subText = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subText:SetText(LOSECONTROL_DESCRIPTION)

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

local SizeSlider = CreateSlider(LOSECONTROL_SIZE, OptionsPanel, 16, 512, 4)
SizeSlider:SetScript("OnValueChanged", function(self, value)
	self.valText:SetText(value .. "px")
	LoseControlDB.Size = value
	f:SetWidth(value)
	f:SetHeight(value)
end)

local AlphaSlider = CreateSlider(LOSECONTROL_ALPHA, OptionsPanel, 0, 100, 5) -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
AlphaSlider:SetScript("OnValueChanged", function(self, value)
	self.valText:SetText(value .. "%")
	LoseControlDB.Alpha = value / 100 -- the real alpha value
	f:SetAlpha(LoseControlDB.Alpha)
end)

BlizzardOptionsPanel_Slider_Disable(SizeSlider) -- disabled by default til unlock
BlizzardOptionsPanel_Slider_Disable(AlphaSlider) -- disabled by default til unlock

-- "Unlock" checkbox - allows the frame to be moved
local Unlock = CreateFrame("CheckButton", O.."Unlock", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."UnlockText"]:SetText(LOSECONTROL_UNLOCK)
Unlock:SetScript("OnClick", function(self)
	if self:GetChecked() then
		_G[O.."UnlockText"]:SetText(LOSECONTROL_UNLOCK .. LOSECONTROL_UNLOCK2)
		BlizzardOptionsPanel_Slider_Enable(SizeSlider)
		BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		f:UnregisterEvent("UNIT_AURA")
		f:SetMovable(true)
		f:RegisterForDrag("LeftButton")
		f:EnableMouse(true)
		f.texture:SetTexture("Interface\\Icons\\Spell_Holy_SealOfMight")
		f:Show();
		f:SetCooldown( GetTime(), 30 )
		f:SetAlpha(LoseControlDB.Alpha) -- hack to apply the alpha to the cooldown timer
	else
		_G[O.."UnlockText"]:SetText(LOSECONTROL_UNLOCK)
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

local DisableCooldownCount = CreateFrame("CheckButton", O.."DisableCooldownCount", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."DisableCooldownCountText"]:SetText(LOSECONTROL_COOLDOWNCOUNT)
DisableCooldownCount:SetScript("OnClick", function(self)
	LoseControlDB.noCooldownCount = self:GetChecked()
	f.noCooldownCount = LoseControlDB.noCooldownCount
end)

local TrackCCs = CreateFrame("CheckButton", O.."TrackCCs", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackCCsText"]:SetText(LOSECONTROL_TRACK .. CC)
TrackCCs:SetScript("OnClick", function(self)
	LoseControlDB.tracking[CC] = self:GetChecked()
end)

local TrackSilences = CreateFrame("CheckButton", O.."TrackSilences", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackSilencesText"]:SetText(LOSECONTROL_TRACK .. Silence)
TrackSilences:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Silence] = self:GetChecked()
end)

local TrackDisarms = CreateFrame("CheckButton", O.."TrackDisarms", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackDisarmsText"]:SetText(LOSECONTROL_TRACK .. Disarm)
TrackDisarms:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Disarm] = self:GetChecked()
end)

local TrackRoots = CreateFrame("CheckButton", O.."TrackRoots", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackRootsText"]:SetText(LOSECONTROL_TRACK .. Root)
TrackRoots:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Root] = self:GetChecked()
end)

local TrackSnares = CreateFrame("CheckButton", O.."TrackSnares", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."TrackSnaresText"]:SetText(LOSECONTROL_TRACK .. Snare)
TrackSnares:SetScript("OnClick", function(self)
	LoseControlDB.tracking[Snare] = self:GetChecked()
end)

-- Arrange them all neatly
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
Unlock:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
SizeSlider:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -16)
AlphaSlider:SetPoint("TOPLEFT", SizeSlider, "BOTTOMLEFT", 0, -16)
DisableCooldownCount:SetPoint("TOPLEFT", AlphaSlider, "BOTTOMLEFT", 0, -24)
TrackCCs:SetPoint("TOPLEFT", DisableCooldownCount, "BOTTOMLEFT", 0, -24)
TrackSilences:SetPoint("TOPLEFT", TrackCCs, "BOTTOMLEFT", 0, -8)
TrackDisarms:SetPoint("TOPLEFT", TrackSilences, "BOTTOMLEFT", 0, -8)
TrackRoots:SetPoint("TOPLEFT", TrackDisarms, "BOTTOMLEFT", 0, -8)
TrackSnares:SetPoint("TOPLEFT", TrackRoots, "BOTTOMLEFT", 0, -8)

OptionsPanel.default = function() -- This method will run when the player clicks "defaults".
	LoseControlDB.Version = 0
	f:VARIABLES_LOADED()
end

OptionsPanel.refresh = function() -- This method will run when the Interface Options frame calls its OnShow function and after defaults have been applied via the panel.default method described above.
	SizeSlider:SetValue(LoseControlDB.Size)
	AlphaSlider:SetValue(LoseControlDB.Alpha * 100)
	DisableCooldownCount:SetChecked(LoseControlDB.noCooldownCount)
	TrackCCs:SetChecked(LoseControlDB.tracking[CC])
	TrackSilences:SetChecked(LoseControlDB.tracking[Silence])
	TrackDisarms:SetChecked(LoseControlDB.tracking[Disarm])
	TrackRoots:SetChecked(LoseControlDB.tracking[Root])
	TrackSnares:SetChecked(LoseControlDB.tracking[Snare])
end

InterfaceOptions_AddCategory(OptionsPanel)

SlashCmdList[L] = function() InterfaceOptionsFrame_OpenToCategory(OptionsPanel) end
SLASH_LoseControl1 = "/lc"
SLASH_LoseControl2 = "/losecontrol"
