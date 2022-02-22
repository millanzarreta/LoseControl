--[[
-------------------------------------------
-- Addon: LoseControl Classic
-- Version: 1.11
-- Authors: millanzarreta, Kouri
-------------------------------------------

]]

local addonName, L = ...
local _G = _G				-- it's faster to keep local references to frequently used global vars
local _
local UIParent = UIParent
local UnitAura = UnitAura
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitHealth = UnitHealth
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetInventoryItemID = GetInventoryItemID
local GetInstanceInfo = GetInstanceInfo
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local SetPortraitToTexture = SetPortraitToTexture
local COMBATLOG_OBJECT_CONTROL_NPC = _G.COMBATLOG_OBJECT_CONTROL_NPC
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type
local select = select
local tonumber = tonumber
local strfind = string.find
local strgmatch = string.gmatch
local tblinsert = table.insert
local mathfloor = math.floor
local mathabs = math.abs
local bit_band = bit.band
local SetScript = SetScript
local OnEvent = OnEvent
local CreateFrame = CreateFrame
local SetTexture = SetTexture
local SetCooldown = SetCooldown
local SetAlpha, SetPoint = SetAlpha, SetPoint
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local playerGUID, playerClass
local print = print
local debug = false -- type "/lc debug on" if you want to see UnitAura info logged to the console
local LCframes = {}
local LCframeplayer2
local InterruptAuras = { }
local origSpellIdsChanged = { }
local LoseControlCompactRaidFramesHooked
local LCHookedCompactRaidFrames = { }
local LibClassicDurations = LibStub("LibClassicDurations")
local Masque = LibStub("Masque", true)
LibClassicDurations:Register(addonName)
local LCUnitPendingUnitWatchFrames = {}
local LCCombatLockdownDelayFrame = CreateFrame("Frame")
local RefreshPendingUnitWatchState = function() end
local delayFunc_RefreshPendingUnitWatchState = false
LCCombatLockdownDelayFrame:SetScript("OnEvent", function(self,event)
	if event=="PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		if (delayFunc_RefreshPendingUnitWatchState) then
			delayFunc_RefreshPendingUnitWatchState = false
			RefreshPendingUnitWatchState()
		end
	end
end)

-------------------------------------------------------------------------------
-- Thanks to all the people on the Curse.com and WoWInterface forums who help keep this list up to date :)

local interruptsIds = {
	-- Player Interrupts
	[72]     = {6, 1},					-- Shield Bash (rank 1) (Warrior)
	[1671]   = {6, 2},					-- Shield Bash (rank 2) (Warrior)
	[1672]   = {6, 3},					-- Shield Bash (rank 3) (Warrior)
	[1766]   = {5, 1},					-- Kick (rank 1) (Rogue)
	[1767]   = {5, 2},					-- Kick (rank 2) (Rogue)
	[1768]   = {5, 3},					-- Kick (rank 3) (Rogue)
	[1769]   = {5, 4},					-- Kick (rank 4) (Rogue)
	[2139]   = {10, 1},					-- Counterspell (Mage)
	[6552]   = {4, 1},					-- Pummel (rank 1) (Warrior)
	[6554]   = {4, 2},					-- Pummel (rank 2) (Warrior)
	[8042]   = {2, 1},					-- Earth Shock (rank 1) (Shaman)
	[8044]   = {2, 2},					-- Earth Shock (rank 2) (Shaman)
	[8045]   = {2, 3},					-- Earth Shock (rank 3) (Shaman)
	[8046]   = {2, 4},					-- Earth Shock (rank 4) (Shaman)
	[10412]  = {2, 5},					-- Earth Shock (rank 5) (Shaman)
	[10413]  = {2, 6},					-- Earth Shock (rank 6) (Shaman)
	[10414]  = {2, 7},					-- Earth Shock (rank 7) (Shaman)
	[13491]  = {5, -1},					-- Pummel (Iron Knuckles Item)
	[19244]  = {6, 1},					-- Spell Lock (felhunter) (rank 1) (Warlock)
	[19647]  = {8, 2},					-- Spell Lock (felhunter) (rank 2) (Warlock)
	[19675]  = {4, 1},					-- Feral Charge (Druid)
	[29443]  = {10, -1},				-- Counterspell (Clutch of Foresight)
	-- NPC Interrupts
	[5133]   = {30, -20, true},			-- Interrupt (PT)
	[8714]   = {5, -20, true},			-- Overwhelming Musk
	[10887]  = {5, -20, true},			-- Crowd Pummel
	[11972]  = {8, -20, true},			-- Shield Bash
	[19129]  = {2, -20, true},			-- Massive Tremor
	[21832]  = {10, -20, true},			-- Boulder
	[25788]  = {5, -20, true},			-- Head Butt
	[27620]  = {4, -20, true},			-- Snap Kick
	[11978]  = {6, -16, true},			-- Kick
	[15610]  = {6, -17, true},			-- Kick
	[15614]  = {6, -18, true},			-- Kick
	[27613]  = {6, -19, true},			-- Kick
	[27814]  = {6, -20, true},			-- Kick
	[12555]  = {5, -18, true},			-- Pummel
	[15615]  = {5, -19, true},			-- Pummel
	[19639]  = {5, -20, true},			-- Pummel
	[13281]  = {2, -13, true},			-- Earth Shock
	[13728]  = {2, -14, true},			-- Earth Shock
	[15501]  = {2, -15, true},			-- Earth Shock
	[22885]  = {2, -16, true},			-- Earth Shock
	[23114]  = {2, -17, true},			-- Earth Shock
	[25025]  = {2, -18, true},			-- Earth Shock
	[26194]  = {2, -19, true},			-- Earth Shock
	[24685]  = {4, -20, true, 10309},	-- Earth Shock
	[15122]  = {15, -17, true},			-- Counterspell
	[20537]  = {15, -18, true},			-- Counterspell
	[19715]  = {10, -19, true, 10409},	-- Counterspell
	[20788]  = {0.001, -20, true}		-- Counterspell
}
local interruptsSpellIdByName = { }
local coldSnapSpellName

local spellIds = {
	----------------
	-- Druid
	----------------
	[339]    = "Root",				-- Entangling Roots (rank 1)
	[1062]   = "Root",				-- Entangling Roots (rank 2)
	[5195]   = "Root",				-- Entangling Roots (rank 3)
	[5196]   = "Root",				-- Entangling Roots (rank 4)
	[9852]   = "Root",				-- Entangling Roots (rank 5)
	[9853]   = "Root",				-- Entangling Roots (rank 6)
	[9005]   = "CC",				-- Pounce (rank 1)
	[9823]   = "CC",				-- Pounce (rank 2)
	[9827]   = "CC",				-- Pounce (rank 3)
	[5211]   = "CC",				-- Bash (rank 1)
	[6798]   = "CC",				-- Bash (rank 2)
	[8983]   = "CC",				-- Bash (rank 3)
	[2637]   = "CC",				-- Hibernate (rank 1)
	[18657]  = "CC",				-- Hibernate (rank 2)
	[18658]  = "CC",				-- Hibernate (rank 3)
	[19975]  = "Root",				-- Entangling Roots (rank 1) (Nature's Grasp talent)
	[19974]  = "Root",				-- Entangling Roots (rank 2) (Nature's Grasp talent)
	[19973]  = "Root",				-- Entangling Roots (rank 3) (Nature's Grasp talent)
	[19972]  = "Root",				-- Entangling Roots (rank 4) (Nature's Grasp talent)
	[19971]  = "Root",				-- Entangling Roots (rank 5) (Nature's Grasp talent)
	[19970]  = "Root",				-- Entangling Roots (rank 6) (Nature's Grasp talent)
	[22570]  = "CC",				-- Mangle (rank 1)
	[16922]  = "CC",				-- Starfire Stun (Improved Starfire talent)
	[19675]  = "Root",				-- Feral Charge Effect (Feral Charge talent)
	[17116]  = "Other",				-- Nature's Swiftness (talent)
	[16689]  = "Other",				-- Nature's Grasp (rank 1)
	[16810]  = "Other",				-- Nature's Grasp (rank 2)
	[16811]  = "Other",				-- Nature's Grasp (rank 3)
	[16812]  = "Other",				-- Nature's Grasp (rank 4)
	[16813]  = "Other",				-- Nature's Grasp (rank 5)
	[17329]  = "Other",				-- Nature's Grasp (rank 6)
	[22812]  = "Other",				-- Barkskin
	[29166]  = "Other",				-- Innervate

	----------------
	-- Hunter
	----------------
	[1513]   = "CC",				-- Scare Beast (rank 1)
	[14326]  = "CC",				-- Scare Beast (rank 2)
	[14327]  = "CC",				-- Scare Beast (rank 3)
	[3355]   = "CC",				-- Freezing Trap (rank 1)
	[14308]  = "CC",				-- Freezing Trap (rank 2)
	[14309]  = "CC",				-- Freezing Trap (rank 3)
	[19386]  = "CC",				-- Wyvern Sting (talent) (rank 1)
	[24132]  = "CC",				-- Wyvern Sting (talent) (rank 2)
	[24133]  = "CC",				-- Wyvern Sting (talent) (rank 3)
	[19410]  = "CC",				-- Improved Concussive Shot (talent)
	[28445]  = "CC",				-- Improved Concussive Shot (talent)
	[19503]  = "CC",				-- Scatter Shot (talent)
	[19306]  = "Root",				-- Counterattack (talent) (rank 1)
	[20909]  = "Root",				-- Counterattack (talent) (rank 2)
	[20910]  = "Root",				-- Counterattack (talent) (rank 3)
	[19229]  = "Root",				-- Improved Wing Clip (talent)
	[19185]  = "Root",				-- Entrapment (talent)
	[2974]   = "Snare",				-- Wing Clip (rank 1)
	[14267]  = "Snare",				-- Wing Clip (rank 2)
	[14268]  = "Snare",				-- Wing Clip (rank 3)
	[5116]   = "Snare",				-- Concussive Shot
	[15571]  = "Snare",				-- Dazed (Aspect of the Cheetah and Aspect of the Pack)
	[13809]  = "Snare",				-- Frost Trap
	[13810]  = "Snare",				-- Frost Trap Aura
	[19263]  = "Other",				-- Deterrence (dodge and Parry chance increased by 25%)
	[19574]  = "ImmuneSpell",		-- Bestial Wrath (talent) (not immuune to spells, only immune to some CC's)
	[5384]   = "Other",				-- Feign Death
	
		----------------
		-- Hunter Pets
		----------------
		[4167]   = "Root",				-- Web
		[4168]   = "Root",				-- Web II
		[4169]   = "Root",				-- Web III
		[24394]  = "CC",				-- Intimidation (talent)
		[25999]  = "Root",				-- Boar Charge (Boar)
		[26064]  = "Immune",			-- Shell Shield (damage taken reduced 50%) (Turtle)

	----------------
	-- Mage
	----------------
	[118]    = "CC",				-- Polymorph (rank 1)
	[12824]  = "CC",				-- Polymorph (rank 2)
	[12825]  = "CC",				-- Polymorph (rank 3)
	[12826]  = "CC",				-- Polymorph (rank 4)
	[28270]  = "CC",				-- Polymorph: Cow
	[28271]  = "CC",				-- Polymorph: Turtle
	[28272]  = "CC",				-- Polymorph: Pig
	[12355]  = "CC",				-- Impact (talent)
	[18469]  = "Silence",			-- Counterspell - Silenced (Improved Counterspell talent)
	[11958]  = "Immune",			-- Ice Block (talent)
	[122]    = "Root",				-- Frost Nova (rank 1)
	[865]    = "Root",				-- Frost Nova (rank 2)
	[6131]   = "Root",				-- Frost Nova (rank 3)
	[10230]  = "Root",				-- Frost Nova (rank 4)
	[12494]  = "Root",				-- Frostbite (talent)
	[12484]  = "Snare",				-- Chilled (rank 1) (Improved Blizzard talent)
	[12485]  = "Snare",				-- Chilled (rank 2) (Improved Blizzard talent)
	[12486]  = "Snare",				-- Chilled (rank 3) (Improved Blizzard talent)
	[120]    = "Snare",				-- Cone of Cold (rank 1)
	[8492]   = "Snare",				-- Cone of Cold (rank 2)
	[10159]  = "Snare",				-- Cone of Cold (rank 3)
	[10160]  = "Snare",				-- Cone of Cold (rank 4)
	[10161]  = "Snare",				-- Cone of Cold (rank 5)
	[116]    = "Snare",				-- Frostbolt (rank 1)
	[205]    = "Snare",				-- Frostbolt (rank 2)
	[837]    = "Snare",				-- Frostbolt (rank 3)
	[7322]   = "Snare",				-- Frostbolt (rank 4)
	[8406]   = "Snare",				-- Frostbolt (rank 5)
	[8407]   = "Snare",				-- Frostbolt (rank 6)
	[8408]   = "Snare",				-- Frostbolt (rank 7)
	[10179]  = "Snare",				-- Frostbolt (rank 8)
	[10180]  = "Snare",				-- Frostbolt (rank 9)
	[10181]  = "Snare",				-- Frostbolt (rank 10)
	[25304]  = "Snare",				-- Frostbolt (rank 11)
	--[6136]   = "Snare",				-- Chilled (Frost Armor)
	--[7321]   = "Snare",				-- Chilled (Ice Armor)
	[11113]  = "Snare",				-- Blast Wave (talent) (rank 1)
	[13018]  = "Snare",				-- Blast Wave (talent) (rank 2)
	[13019]  = "Snare",				-- Blast Wave (talent) (rank 3)
	[13020]  = "Snare",				-- Blast Wave (talent) (rank 4)
	[13021]  = "Snare",				-- Blast Wave (talent) (rank 5)
	[12043]  = "Other",				-- Presence of Mind (talent)
	[12042]  = "Other",				-- Arcane Power (talent)

	----------------
	-- Paladin
	----------------
	[642]    = "Immune",			-- Divine Shield (rank 1)
	[1020]   = "Immune",			-- Divine Shield (rank 2)
	[498]    = "Immune",			-- Divine Protection (rank 1)
	[5573]   = "Immune",			-- Divine Protection (rank 2)
	[19753]  = "Immune",			-- Divine Intervention
	[1022]   = "ImmunePhysical",	-- Blessing of Protection (rank 1)
	[5599]   = "ImmunePhysical",	-- Blessing of Protection (rank 2)
	[10278]  = "ImmunePhysical",	-- Blessing of Protection (rank 3)
	[853]    = "CC",				-- Hammer of Justice (rank 1)
	[5588]   = "CC",				-- Hammer of Justice (rank 2)
	[5589]   = "CC",				-- Hammer of Justice (rank 3)
	[10308]  = "CC",				-- Hammer of Justice (rank 4)
	[20170]  = "CC",				-- Stun (Seal of Justice)
	[2878]   = "CC",				-- Turn Undead (rank 1)
	[5627]   = "CC",				-- Turn Undead (rank 2)
	[10326]  = "CC",				-- Turn Undead (rank 3)
	[20066]  = "CC",				-- Repentance (talent)
	[1044]   = "Other",				-- Blessing of Freedom
	[20216]  = "Other",				-- Divine Favor

	----------------
	-- Priest
	----------------
	[15487]  = "Silence",			-- Silence (talent)
	[10060]  = "Other",				-- Power Infusion (talent)
	[15269]  = "CC",				-- Blackout (talent)
	[6346]   = "Other",				-- Fear Ward
	[605]    = "CC",				-- Mind Control (rank 1)
	[10911]  = "CC",				-- Mind Control (rank 2)
	[10912]  = "CC",				-- Mind Control (rank 3)
	[8122]   = "CC",				-- Psychic Scream (rank 1)
	[8124]   = "CC",				-- Psychic Scream (rank 2)
	[10888]  = "CC",				-- Psychic Scream (rank 3)
	[10890]  = "CC",				-- Psychic Scream (rank 4)
	[9484]   = "CC",				-- Shackle Undead (rank 1)
	[9485]   = "CC",				-- Shackle Undead (rank 2)
	[10955]  = "CC",				-- Shackle Undead (rank 3)
	[14751]  = "Other",				-- Inner Focus
	[15407]  = "Snare",				-- Mind Flay (talent) (rank 1)
	[17311]  = "Snare",				-- Mind Flay (talent) (rank 2)
	[17312]  = "Snare",				-- Mind Flay (talent) (rank 3)
	[17313]  = "Snare",				-- Mind Flay (talent) (rank 4)
	[17314]  = "Snare",				-- Mind Flay (talent) (rank 5)
	[18807]  = "Snare",				-- Mind Flay (talent) (rank 6)

	----------------
	-- Rogue
	----------------
	[2094]   = "CC",				-- Blind
	[408]    = "CC",				-- Kidney Shot (rank 1)
	[8643]   = "CC",				-- Kidney Shot (rank 2)
	[1833]   = "CC",				-- Cheap Shot
	[6770]   = "CC",				-- Sap (rank 1)
	[2070]   = "CC",				-- Sap (rank 2)
	[11297]  = "CC",				-- Sap (rank 3)
	[1776]   = "CC",				-- Gouge (rank 1)
	[1777]   = "CC",				-- Gouge (rank 2)
	[8629]   = "CC",				-- Gouge (rank 3)
	[11285]  = "CC",				-- Gouge (rank 4)
	[11286]  = "CC",				-- Gouge (rank 5)
	[5530]   = "CC",				-- Mace Stun (talent)
	[14251]  = "Disarm",			-- Riposte (talent)
	[18425]  = "Silence",			-- Kick - Silenced (talent)
	[3409]   = "Snare",				-- Crippling Poison (rank 1)
	[11201]  = "Snare",				-- Crippling Poison (rank 2)
	[5277]   = "ImmunePhysical",	-- Evasion (dodge chance increased 50%)
	[14177]  = "Other",				-- Cold Blood (talent)
	[13877]  = "Other",				-- Blade Flurry
	[13750]  = "Other",				-- Adrenaline Rush

	----------------
	-- Shaman
	----------------
	[8178]   = "ImmuneSpell",		-- Grounding Totem Effect (Grounding Totem)
	[8056]   = "Snare",				-- Frost Shock (rank 1)
	[8058]   = "Snare",				-- Frost Shock (rank 2)
	[10472]  = "Snare",				-- Frost Shock (rank 3)
	[10473]  = "Snare",				-- Frost Shock (rank 4)
	[3600]   = "Snare",				-- Earthbind (Earthbind Totem)
	[16166]  = "Other",				-- Elemental Mastery (talent)
	[16188]  = "Other",				-- Nature's Swiftness (talent)

	----------------
	-- Warlock
	----------------
	[710]    = "CC",				-- Banish (rank 1)
	[18647]  = "CC",				-- Banish (rank 2)
	[5782]   = "CC",				-- Fear (rank 1)
	[6213]   = "CC",				-- Fear (rank 2)
	[6215]   = "CC",				-- Fear (rank 3)
	[5484]   = "CC",				-- Howl of Terror (rank 1)
	[17928]  = "CC",				-- Howl of Terror (rank 2)
	[6789]   = "CC",				-- Death Coil (rank 1)
	[17925]  = "CC",				-- Death Coil (rank 2)
	[17926]  = "CC",				-- Death Coil (rank 3)
	[22703]  = "CC",				-- Inferno Effect
	[18093]  = "CC",				-- Pyroclasm (talent)
	[18708]  = "Other",				-- Fel Domination (talent)
	[18223]  = "Snare",				-- Curse of Exhaustion (talent)
	[18118]  = "Snare",				-- Aftermath (talent)

		----------------
		-- Warlock Pets
		----------------
		[24259]  = "Silence",		-- Spell Lock (Felhunter)
		[6358]   = "CC",			-- Seduction (Succubus)
		[4511]   = "Immune",		-- Phase Shift (Imp)
		[19482]  = "CC",			-- War Stomp (Doomguard)
		[89]     = "Snare",			-- Cripple (Doomguard)

	----------------
	-- Warrior
	----------------
	[7922]   = "CC",				-- Charge (rank 1/2/3)
	[20253]  = "CC",				-- Intercept (rank 1)
	[20614]  = "CC",				-- Intercept (rank 2)
	[20615]  = "CC",				-- Intercept (rank 3)
	[5246]   = "CC",				-- Intimidating Shout
	[20511]  = "CC",				-- Intimidating Shout
	[12798]  = "CC",				-- Revenge Stun (Improved Revenge talent)
	[12809]  = "CC",				-- Concussion Blow (talent)
	[676]    = "Disarm",			-- Disarm
	[871]    = "Immune",			-- Shield Wall (not immune, 75% damage reduction)
	[23694]  = "Root",				-- Improved Hamstring (talent)
	[18498]  = "Silence",			-- Shield Bash - Silenced (Improved Shield Bash talent)
	[1715]   = "Snare",				-- Hamstring (rank 1)
	[7372]   = "Snare",				-- Hamstring (rank 2)
	[7373]   = "Snare",				-- Hamstring (rank 3)
	[12705]  = "Snare",				-- Long Daze (Improved Pummel)
	[12323]  = "Snare",				-- Piercing Howl (talent)
	[2565]   = "Other",				-- Shield Block
	[12328]  = "Other",				-- Death Wish (talent)
	[12976]  = "Other",				-- Last Stand (talent)
	[20230]  = "Other",				-- Retaliation
	[18499]  = "Other",				-- Berserker Rage
	[1719]   = "Other",				-- Recklessness

	----------------
	-- Other
	----------------
	[56]     = "CC",				-- Stun (some weapons proc)
	[835]    = "CC",				-- Tidal Charm (trinket)
	[775]    = "CC",				-- Tree Form
	[4159]   = "CC",				-- Tight Pinch
	[8312]   = "Root",				-- Trap (Hunting Net trinket)
	[17308]  = "CC",				-- Stun (Hurd Smasher fist weapon)
	[23454]  = "CC",				-- Stun (The Unstoppable Force weapon)
	[9179]   = "CC",				-- Stun (Tigule and Foror's Strawberry Ice Cream item)
	[7744]   = "Other",				-- Will of the Forsaken	(undead racial)
	[26635]  = "Other",				-- Berserking (troll racial)
	[20594]  = "Other",				-- Stoneform (dwarf racial)
	[13327]  = "CC",				-- Reckless Charge (Goblin Rocket Helmet)
	[20549]  = "CC",				-- War Stomp (tauren racial)
	--[23230]  = "Other",				-- Blood Fury (orc racial)
	[13181]  = "CC",				-- Gnomish Mind Control Cap (Gnomish Mind Control Cap helmet)
	[26740]  = "CC",				-- Gnomish Mind Control Cap (Gnomish Mind Control Cap helmet)
	[8345]   = "CC",				-- Control Machine (Gnomish Universal Remote trinket)
	[13235]  = "CC",				-- Forcefield Collapse (Gnomish Harm Prevention belt)
	[13158]  = "CC",				-- Rocket Boots Malfunction (Engineering Rocket Boots)
	[8893]   = "CC",				-- Rocket Boots Malfunction (Engineering Rocket Boots)
	[13466]  = "CC",				-- Goblin Dragon Gun (engineering trinket malfunction)
	[8224]   = "CC",				-- Cowardice (Savory Deviate Delight effect)
	[8225]   = "CC",				-- Run Away! (Savory Deviate Delight effect)
	[23131]  = "ImmuneSpell",		-- Frost Reflector (Gyrofreeze Ice Reflector trinket) (only reflect frost spells)
	[23097]  = "ImmuneSpell",		-- Fire Reflector (Hyper-Radiant Flame Reflector trinket) (only reflect fire spells)
	[23132]  = "ImmuneSpell",		-- Shadow Reflector (Ultra-Flash Shadow Reflector trinket) (only reflect shadow spells)
	[30003]  = "ImmuneSpell",		-- Sheen of Zanza
	[23444]  = "CC",				-- Transporter Malfunction
	[23447]  = "CC",				-- Transporter Malfunction
	[23456]  = "CC",				-- Transporter Malfunction
	[23457]  = "CC",				-- Transporter Malfunction
	[8510]   = "CC",				-- Large Seaforium Backfire
	[8511]   = "CC",				-- Small Seaforium Backfire
	[7144]   = "ImmunePhysical",	-- Stone Slumber
	[12843]  = "Immune",			-- Mordresh's Shield
	[27619]  = "Immune",			-- Ice Block
	[21892]  = "Immune",			-- Arcane Protection
	[13237]  = "CC",				-- Goblin Mortar
	[13238]  = "CC",				-- Goblin Mortar
	[5134]   = "CC",				-- Flash Bomb
	[4064]   = "CC",				-- Rough Copper Bomb
	[4065]   = "CC",				-- Large Copper Bomb
	[4066]   = "CC",				-- Small Bronze Bomb
	[4067]   = "CC",				-- Big Bronze Bomb
	[4068]   = "CC",				-- Iron Grenade
	[4069]   = "CC",				-- Big Iron Bomb
	[12543]  = "CC",				-- Hi-Explosive Bomb
	[12562]  = "CC",				-- The Big One
	[12421]  = "CC",				-- Mithril Frag Bomb
	[19784]  = "CC",				-- Dark Iron Bomb
	[19769]  = "CC",				-- Thorium Grenade
	[13808]  = "CC",				-- M73 Frag Grenade
	[21188]  = "CC",				-- Stun Bomb Attack
	[9159]   = "CC",				-- Sleep (Green Whelp Armor chest)
	[19821]  = "Silence",			-- Arcane Bomb
	--[9774]   = "Other",				-- Immune Root (spider belt)
	[18278]  = "Silence",			-- Silence (Silent Fang sword)
	[8346]   = "Root",				-- Mobility Malfunction (trinket)
	[13099]  = "Root",				-- Net-o-Matic (trinket)
	[13119]  = "Root",				-- Net-o-Matic (trinket)
	[13138]  = "Root",				-- Net-o-Matic (trinket)
	[16566]  = "Root",				-- Net-o-Matic (trinket)
	[23723]  = "Other",				-- Mind Quickening (Mind Quickening Gem trinket)
	[15752]  = "Disarm",			-- Linken's Boomerang (trinket)
	[15753]  = "CC",				-- Linken's Boomerang (trinket)
	[15535]  = "CC",				-- Enveloping Winds (Six Demon Bag trinket)
	[23103]  = "CC",				-- Enveloping Winds (Six Demon Bag trinket)
	[15534]  = "CC",				-- Polymorph (Six Demon Bag trinket)
	[16470]  = "CC",				-- Gift of Stone
	[700]    = "CC",				-- Sleep (Slumber Sand item)
	[1090]   = "CC",				-- Sleep
	[12098]  = "CC",				-- Sleep
	[20663]  = "CC",				-- Sleep
	[20669]  = "CC",				-- Sleep
	[20989]  = "CC",				-- Sleep
	[24004]  = "CC",				-- Sleep
	[8064]   = "CC",				-- Sleepy
	[17446]  = "CC",				-- The Black Sleep
	[29124]  = "CC",				-- Polymorph
	[14621]  = "CC",				-- Polymorph
	[27760]  = "CC",				-- Polymorph
	[28406]  = "CC",				-- Polymorph Backfire
	[851]    = "CC",				-- Polymorph: Sheep
	[16707]  = "CC",				-- Hex
	[16708]  = "CC",				-- Hex
	[16709]  = "CC",				-- Hex
	[18503]  = "CC",				-- Hex
	[20683]  = "CC",				-- Highlord's Justice
	[17286]  = "CC",				-- Crusader's Hammer
	[17820]  = "Other",				-- Veil of Shadow
	[12096]  = "CC",				-- Fear
	[27641]  = "CC",				-- Fear
	[29168]  = "CC",				-- Fear
	[30002]  = "CC",				-- Fear
	[15398]  = "CC",				-- Psychic Scream
	[26042]  = "CC",				-- Psychic Scream
	[27610]  = "CC",				-- Psychic Scream
	[10794]  = "CC",				-- Spirit Shock
	[9915]   = "Root",				-- Frost Nova
	[14907]  = "Root",				-- Frost Nova
	[22645]  = "Root",				-- Frost Nova
	[15091]  = "Snare",				-- Blast Wave
	[17277]  = "Snare",				-- Blast Wave
	[23039]  = "Snare",				-- Blast Wave
	[23113]  = "Snare",				-- Blast Wave
	[12548]  = "Snare",				-- Frost Shock
	[22582]  = "Snare",				-- Frost Shock
	[23115]  = "Snare",				-- Frost Shock
	[19133]  = "Snare",				-- Frost Shock
	[21030]  = "Snare",				-- Frost Shock
	[21401]  = "Snare",				-- Frost Shock
	[11538]  = "Snare",				-- Frostbolt
	[21369]  = "Snare",				-- Frostbolt
	[20297]  = "Snare",				-- Frostbolt
	[20806]  = "Snare",				-- Frostbolt
	[20819]  = "Snare",				-- Frostbolt
	[12737]  = "Snare",				-- Frostbolt
	[20792]  = "Snare",				-- Frostbolt
	[20822]  = "Snare",				-- Frostbolt
	[17503]  = "Snare",				-- Frostbolt
	[23412]  = "Snare",				-- Frostbolt
	[24942]  = "Snare",				-- Frostbolt
	[15497]  = "Snare",				-- Frostbolt
	[23102]  = "Snare",				-- Frostbolt
	[20828]  = "Snare",				-- Cone of Cold
	[22746]  = "Snare",				-- Cone of Cold
	[20717]  = "Snare",				-- Sand Breath
	[16568]  = "Snare",				-- Mind Flay
	[16094]  = "Snare",				-- Frost Breath
	[16340]  = "Snare",				-- Frost Breath
	[17174]  = "Snare",				-- Concussive Shot
	[27634]  = "Snare",				-- Concussive Shot
	[20654]  = "Root",				-- Entangling Roots
	[22127]  = "Root",				-- Entangling Roots
	[22800]  = "Root",				-- Entangling Roots
	[20699]  = "Root",				-- Entangling Roots
	[18546]  = "Root",				-- Overdrive
	[22935]  = "Root",				-- Planted
	[22707]  = "Root",				-- Root
	[24170]  = "Root",				-- Whipweed Entangle
	[24152]  = "Root",				-- Whipweed Roots
	[12520]  = "Root",				-- Teleport from Azshara Tower
	[12521]  = "Root",				-- Teleport from Azshara Tower
	[12509]  = "Root",				-- Teleport from Azshara Tower
	[12024]  = "Root",				-- Net
	[12023]  = "Root",				-- Web
	[13608]  = "Root",				-- Hooked Net
	[10017]  = "Root",				-- Frost Hold
	[23279]  = "Root",				-- Crippling Clip
	[3542]   = "Root",				-- Naraxis Web
	[5567]   = "Root",				-- Miring Mud
	[5424]   = "Root",				-- Claw Grasp
	[4246]   = "Root",				-- Clenched Pinchers
	[5219]   = "Root",				-- Draw of Thistlenettle
	[9576]   = "Root",				-- Lock Down
	[7950]   = "Root",				-- Pause
	[7761]   = "Root",				-- Shared Bonds
	[6714]   = "Root",				-- Test of Faith
	[6716]   = "Root",				-- Test of Faith
	[4932]   = "ImmuneSpell",		-- Ward of Myzrael
	[7383]   = "ImmunePhysical",	-- Water Bubble
	[25]     = "CC",				-- Stun
	[101]    = "CC",				-- Trip
	[2880]   = "CC",				-- Stun
	[5648]   = "CC",				-- Stunning Blast
	[5649]   = "CC",				-- Stunning Blast
	[5726]   = "CC",				-- Stunning Blow
	[5727]   = "CC",				-- Stunning Blow
	[5703]   = "CC",				-- Stunning Strike
	[5918]   = "CC",				-- Shadowstalker Stab
	[3446]   = "CC",				-- Ravage
	[3109]   = "CC",				-- Presence of Death
	[3143]   = "CC",				-- Glacial Roar
	[5403]   = "CC",				-- Crash of Waves
	[3260]   = "CC",				-- Violent Shield Effect
	[3263]   = "CC",				-- Touch of Ravenclaw
	[3271]   = "CC",				-- Fatigued
	[5106]   = "CC",				-- Crystal Flash
	[6266]   = "CC",				-- Kodo Stomp
	[6730]   = "CC",				-- Head Butt
	[6982]   = "CC",				-- Gust of Wind
	[6749]   = "CC",				-- Wide Swipe
	[6754]   = "CC",				-- Slap!
	[6927]   = "CC",				-- Shadowstalker Slash
	[7961]   = "CC",				-- Azrethoc's Stomp
	[8151]   = "CC",				-- Surprise Attack
	[3635]   = "CC",				-- Crystal Gaze
	[6772]   = "CC",				-- Trip
	[9992]   = "CC",				-- Dizzy
	[6614]   = "CC",				-- Cowardly Flight
	[5543]   = "CC",				-- Fade Out
	[6664]   = "CC",				-- Survival Instinct
	[6669]   = "CC",				-- Survival Instinct
	[5951]   = "CC",				-- Knockdown
	[4538]   = "CC",				-- Extract Essence
	[6580]   = "CC",				-- Pierce Ankle
	[6894]   = "CC",				-- Death Bed
	[7184]   = "CC",				-- Lost Control
	[8901]   = "CC",				-- Gas Bomb
	[8902]   = "CC",				-- Gas Bomb
	[9454]   = "CC",				-- Freeze
	[7082]   = "CC",				-- Barrel Explode
	[6537]   = "CC",				-- Call of the Forest
	[8672]   = "CC",				-- Challenger is Dazed
	[6409]   = "CC",				-- Cheap Shot
	[14902]  = "CC",				-- Cheap Shot
	[8338]   = "CC",				-- Defibrillated!
	[23055]  = "CC",				-- Defibrillated!
	[8646]   = "CC",				-- Snap Kick
	[27620]  = "Silence",			-- Snap Kick
	[27814]  = "Silence",			-- Kick
	[11650]  = "CC",				-- Head Butt
	[21990]  = "CC",				-- Tornado
	[19725]  = "CC",				-- Turn Undead
	[19469]  = "CC",				-- Poison Mind
	[10134]  = "CC",				-- Sand Storm
	[12613]  = "CC",				-- Dark Iron Taskmaster Death
	[13488]  = "CC",				-- Firegut Fear Storm
	[17738]  = "CC",				-- Curse of the Plague Rat
	[20019]  = "CC",				-- Engulfing Flames
	[24057]  = "CC",				-- Confused
	[16420]  = "CC",				-- Crypt Scarab Confuse
	[20507]  = "CC",				-- Magmakin Confuse
	[19136]  = "CC",				-- Stormbolt
	[20685]  = "CC",				-- Storm Bolt
	[16803]  = "CC",				-- Flash Freeze
	[14100]  = "CC",				-- Terrifying Roar
	[17276]  = "CC",				-- Scald
	[18812]  = "CC",				-- Knockdown
	[13360]  = "CC",				-- Knockdown
	[11430]  = "CC",				-- Slam
	[28335]  = "CC",				-- Whirlwind
	[16451]  = "CC",				-- Judge's Gavel
	[23601]  = "CC",				-- Scatter Shot
	[25260]  = "CC",				-- Wings of Despair
	[23275]  = "CC",				-- Dreadful Fright
	[24919]  = "CC",				-- Nauseous
	[21167]  = "CC",				-- Snowball
	[26641]  = "CC",				-- Aura of Fear
	[28315]  = "CC",				-- Aura of Fear
	[21898]  = "CC",				-- Warlock Terror
	[20672]  = "CC",				-- Fade
	[31365]  = "CC",				-- Self Fear
	[29111]  = "CC",				-- Permafear
	[25815]  = "CC",				-- Frightening Shriek
	[12134]  = "CC",				-- Atal'ai Corpse Eat
	[22427]  = "CC",				-- Concussion Blow
	[16096]  = "CC",				-- Cowering Roar
	[27177]  = "CC",				-- Defile
	[18395]  = "CC",				-- Dismounting Shot
	[28323]  = "CC",				-- Flameshocker's Revenge
	[28314]  = "CC",				-- Flameshocker's Touch
	[28127]  = "CC",				-- Flash
	[17011]  = "CC",				-- Freezing Claw
	[14102]  = "CC",				-- Head Smash
	[15652]  = "CC",				-- Head Smash
	[23269]  = "CC",				-- Holy Blast
	[22357]  = "CC",				-- Icebolt
	[10451]  = "CC",				-- Implosion
	[15252]  = "CC",				-- Keg Trap
	[27615]  = "CC",				-- Kidney Shot
	[24213]  = "CC",				-- Ravage
	[21936]  = "CC",				-- Reindeer
	[11444]  = "CC",				-- Shackle Undead
	[14871]  = "CC",				-- Shadow Bolt Misfire
	[25056]  = "CC",				-- Stomp
	[24647]  = "CC",				-- Stun
	[17691]  = "CC",				-- Time Out
	[11481]  = "CC",				-- TWEEP
	[22787]  = "CC",				-- Irritating Spores
	[20310]  = "CC",				-- Stun
	[23775]  = "CC",				-- Stun Forever
	[26222]  = "CC",				-- Super Invis
	[24700]  = "CC",				-- Vanish
	[23676]  = "CC",				-- Minigun (chance to hit reduced by 50%)
	[11983]  = "CC",				-- Steam Jet (chance to hit reduced by 30%)
	[9612]   = "CC",				-- Ink Spray (chance to hit reduced by 50%)
	[4150]   = "CC",				-- Eye Peck (chance to hit reduced by 47%)
	[6530]   = "CC",				-- Sling Dirt (chance to hit reduced by 40%)
	[5101]   = "CC",				-- Dazed
	[4320]   = "Silence",			-- Trelane's Freezing Touch
	[4243]   = "Silence",			-- Pester Effect
	[6942]   = "Silence",			-- Overwhelming Stench
	[9552]   = "Silence",			-- Searing Flames
	[10576]  = "Silence",			-- Piercing Howl
	[12943]  = "Silence",			-- Fell Curse Effect
	[23417]  = "Silence",			-- Smother
	[10851]  = "Disarm",			-- Grab Weapon
	[27581]  = "Disarm",			-- Disarm
	[25057]  = "Disarm",			-- Dropped Weapon
	[25655]  = "Disarm",			-- Dropped Weapon
	[14180]  = "Disarm",			-- Sticky Tar
	[5376]   = "Disarm",			-- Hand Snap
	[6576]   = "CC",				-- Intimidating Growl
	[7093]   = "CC",				-- Intimidation
	[8715]   = "CC",				-- Terrifying Howl
	[8817]   = "CC",				-- Smoke Bomb
	[9458]   = "CC",				-- Smoke Cloud
	[3442]   = "CC",				-- Enslave
	[4952]   = "CC",				-- Helcular's Ward
	[3389]   = "ImmuneSpell",		-- Ward of the Eye
	[3651]   = "ImmuneSpell",		-- Shield of Reflection
	[20223]  = "ImmuneSpell",		-- Magic Reflection
	[27546]  = "ImmuneSpell",		-- Faerie Dragon Form (not immune, 50% magical damage reduction)
	[17177]  = "ImmunePhysical",	-- Seal of Protection
	[25772]  = "CC",				-- Mental Domination
	[16053]  = "CC",				-- Dominion of Soul (Orb of Draconic Energy)
	[15859]  = "CC",				-- Dominate Mind
	[20740]  = "CC",				-- Dominate Mind
	[11446]  = "CC",				-- Mind Control
	[20668]  = "CC",				-- Sleepwalk
	[21330]  = "CC",				-- Corrupted Fear (Deathmist Raiment set)
	[27868]  = "Root",				-- Freeze (Magister's and Sorcerer's Regalia sets)
	[17333]  = "Root",				-- Spider's Kiss (Spider's Kiss set)
	[26108]  = "CC",				-- Glimpse of Madness (Dark Edge of Insanity axe)
	[18803]  = "Other",				-- Focus (Hand of Edward the Odd mace)
	[1604]   = "Snare",				-- Dazed
	[9462]   = "Snare",				-- Mirefin Fungus
	[19137]  = "Snare",				-- Slow
	[24753]  = "CC",				-- Trick
	[21847]  = "CC",				-- Snowman
	[21848]  = "CC",				-- Snowman
	[21980]  = "CC",				-- Snowman
	[27880]  = "CC",				-- Stun
	[23010]  = "CC",				-- Tendrils of Air
	[6724]   = "Immune",			-- Light of Elune
	[13007]  = "Immune",			-- Divine Protection
	[13835]  = "Immune",			-- Unkillable Off
	[24360]  = "CC",				-- Greater Dreamless Sleep Potion
	[15822]  = "CC",				-- Dreamless Sleep Potion
	[15283]  = "CC",				-- Stunning Blow (Dark Iron Pulverizer weapon)
	[21152]  = "CC",				-- Earthshaker (Earthshaker weapon)
	[16600]  = "CC",				-- Might of Shahram (Blackblade of Shahram sword)
	[16597]  = "Snare",				-- Curse of Shahram (Blackblade of Shahram sword)
	[13496]  = "Snare",				-- Dazed (Mug O' Hurt mace)
	[21066]  = "Snare",				-- Void Bolt
	[3238]   = "Other",				-- Nimble Reflexes
	[5990]   = "Other",				-- Nimble Reflexes
	[6615]   = "Other",				-- Free Action Potion
	[11359]  = "Other",				-- Restorative Potion
	[24364]  = "Other",				-- Living Free Action Potion
	[23505]  = "Other",				-- Berserking
	[24378]  = "Other",				-- Berserking
	[19135]  = "Other",				-- Avatar
	[12248]  = "Other",				-- Amplify Damage
	[12738]  = "Other",				-- Amplify Damage
	[26198]  = "CC",				-- Whisperings of C'Thun
	[26195]  = "CC",				-- Whisperings of C'Thun
	[26197]  = "CC",				-- Whisperings of C'Thun
	[26258]  = "CC",				-- Whisperings of C'Thun
	[26259]  = "CC",				-- Whisperings of C'Thun
	[3169]   = "ImmunePhysical",	-- Limited Invulnerability Potion
	[17624]  = "Immune",			-- Flask of Petrification
	[13534]  = "Disarm",			-- Disarm (The Shatterer weapon)
	[11879]  = "Disarm",			-- Disarm (Shoni's Disarming Tool weapon)
	[13439]  = "Snare",				-- Frostbolt (some weapons)
	[16621]  = "ImmunePhysical",	-- Self Invulnerability (Invulnerable Mail)
	[27559]  = "Silence",			-- Silence (Jagged Obsidian Shield)
	[13907]  = "CC",				-- Smite Demon (Enchant Weapon - Demonslaying)
	[18798]  = "CC",				-- Freeze (Freezing Band)
	[17500]  = "CC",				-- Malown's Slam (Malown's Slam weapon)
	--[16927]  = "Snare",				-- Chilled (Frostguard weapon)
	--[20005]  = "Snare",				-- Chilled (Enchant Weapon - Icy Chill)

	-- PvE
	--[123456] = "PvE",				-- This is just an example, not a real spell
	------------------------
	---- PVE CLASSIC SEASON OF MASTERY
	------------------------
	[367873] = "CC",				-- Blinding Ash (chance to hit reduced by 50%)
	[367928] = "CC",				-- Corrupted Slam
	[367888] = "CC",				-- Dream Breath
	[367728] = "CC",				-- Dream Fog
	[367476] = "CC",				-- Faulty Wiring
	[368136] = "CC",				-- Faulty Wiring
	[367741] = "CC",				-- Frozen Solid
	[368724] = "CC",				-- Static Overload
	[367701] = "CC",				-- Time Stop
	[365122] = "Other",				-- Berserk
	[368388] = "Other",				-- Berserk
	[368329] = "Root",				-- Nightmare Brambles
	[369077] = "Root",				-- Wing Buffet
	[367897] = "Snare",				-- Dream Breath
	[367724] = "Snare",				-- Dream Fog
	------------------------
	---- PVE CLASSIC
	------------------------
	-- Molten Core Raid
	-- -- Trash
	[19364]  = "CC",				-- Ground Stomp
	[19369]  = "CC",				-- Ancient Despair
	[19641]  = "CC",				-- Pyroclast Barrage
	[20276]  = "CC",				-- Knockdown
	[19393]  = "Silence",			-- Soul Burn
	[19636]  = "Root",				-- Fire Blossom
	-- -- Lucifron
	[20604]  = "CC",				-- Dominate Mind
	-- -- Magmadar
	[19408]  = "CC",				-- Panic
	-- -- Gehennas
	[20277]  = "CC",				-- Fist of Ragnaros
	[19716]  = "Other",				-- Gehennas' Curse
	-- -- Garr
	[19496]  = "Snare",				-- Magma Shackles
	-- -- Shazzrah
	[19714]  = "ImmuneSpell",		-- Deaden Magic (not immune, 50% magical damage reduction)
	-- -- Baron Geddon
	[19695]  = "CC",				-- Inferno
	[20478]  = "CC",				-- Armageddon
	-- -- Golemagg the Incinerator
	[19820]  = "Snare",				-- Mangle
	[22689]  = "Snare",				-- Mangle
	-- -- Sulfuron Harbinger
	[19780]  = "CC",				-- Hand of Ragnaros
	-- -- Majordomo Executus
	[20619]  = "ImmuneSpell",		-- Magic Reflection (not immune, 50% chance reflect spells)
	[20229]  = "Snare",				-- Blast Wave
	------------------------
	-- Onyxia's Lair Raid
	-- -- Onyxia
	[18431]  = "CC",				-- Bellowing Roar
	------------------------
	-- Blackwing Lair Raid
	-- -- Trash
	[24375]  = "CC",				-- War Stomp
	[22289]  = "CC",				-- Brood Power: Green
	[22291]  = "CC",				-- Brood Power: Bronze
	[22561]  = "CC",				-- Brood Power: Green
	[22247]  = "Snare",				-- Suppression Aura
	[22424]  = "Snare",				-- Blast Wave
	[15548]  = "Snare",				-- Thunderclap
	-- -- Razorgore the Untamed
	[19872]  = "CC",				-- Calm Dragonkin
	[23023]  = "CC",				-- Conflagration
	[15593]  = "CC",				-- War Stomp
	[16740]  = "CC",				-- War Stomp
	[28725]  = "CC",				-- War Stomp
	[14515]  = "CC",				-- Dominate Mind
	[22274]  = "CC",				-- Greater Polymorph
	[13747]  = "Snare",				-- Slow
	-- -- Broodlord Lashlayer
	[23331]  = "Snare",				-- Blast Wave
	[25049]  = "Snare",				-- Blast Wave
	-- -- Chromaggus
	[23310]  = "CC",				-- Time Lapse
	[23312]  = "CC",				-- Time Lapse
	[23174]  = "CC",				-- Chromatic Mutation
	[23171]  = "CC",				-- Time Stop (Brood Affliction: Bronze)
	[23153]  = "Snare",				-- Brood Affliction: Blue
	[23169]  = "Other",				-- Brood Affliction: Green
	-- -- Nefarian
	[22666]  = "Silence",			-- Silence
	[22667]  = "CC",				-- Shadow Command
	[22663]  = "Immune",			-- Nefarian's Barrier
	[22686]  = "CC",				-- Bellowing Roar
	[22678]  = "CC",				-- Fear
	[23603]  = "CC",				-- Wild Polymorph
	[23364]  = "CC",				-- Tail Lash
	[23365]  = "Disarm",			-- Dropped Weapon
	[23415]  = "ImmunePhysical",	-- Improved Blessing of Protection
	[23414]  = "Root",				-- Paralyze
	[22687]  = "Other",				-- Veil of Shadow
	------------------------
	-- Zul'Gurub Raid
	-- -- Trash
	[24619]  = "Silence",			-- Soul Tap
	[24048]  = "CC",				-- Whirling Trip
	[24600]  = "CC",				-- Web Spin
	[24335]  = "CC",				-- Wyvern Sting
	[24020]  = "CC",				-- Axe Flurry
	[24671]  = "CC",				-- Snap Kick
	[24333]  = "CC",				-- Ravage
	[6869]   = "CC",				-- Fall down
	[24053]  = "CC",				-- Hex
	[24021]  = "ImmuneSpell",		-- Anti-Magic Shield
	[24674]  = "Other",				-- Veil of Shadow
	[13737]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[3604]   = "Snare",				-- Tendon Rip
	[24002]  = "Snare",				-- Tranquilizing Poison
	[24003]  = "Snare",				-- Tranquilizing Poison
	-- -- High Priestess Jeklik
	[23918]  = "Silence",			-- Sonic Burst
	[22884]  = "CC",				-- Psychic Scream
	[22911]  = "CC",				-- Charge
	[23919]  = "CC",				-- Swoop
	[26044]  = "CC",				-- Mind Flay
	-- -- High Priestess Mar'li
	[24110]  = "Silence",			-- Enveloping Webs
	-- -- High Priest Thekal
	[21060]  = "CC",				-- Blind
	[12540]  = "CC",				-- Gouge
	[24193]  = "CC",				-- Charge
	-- -- Bloodlord Mandokir & Ohgan
	[24408]  = "CC",				-- Charge
	-- -- Gahz'ranka
	[16099]  = "Snare",				-- Frost Breath
	-- -- Jin'do the Hexxer
	[17172]  = "CC",				-- Hex
	[24261]  = "CC",				-- Brain Wash
	-- -- Edge of Madness: Gri'lek, Hazza'rah, Renataki, Wushoolay
	[24648]  = "Root",				-- Entangling Roots
	[24664]  = "CC",				-- Sleep
	-- -- Hakkar
	[24687]  = "Silence",			-- Aspect of Jeklik
	[24686]  = "CC",				-- Aspect of Mar'li
	[24690]  = "CC",				-- Aspect of Arlokk
	[24327]  = "CC",				-- Cause Insanity
	[24178]  = "CC",				-- Will of Hakkar
	[24322]  = "CC",				-- Blood Siphon
	[24323]  = "CC",				-- Blood Siphon
	[24324]  = "CC",				-- Blood Siphon
	------------------------
	-- Ruins of Ahn'Qiraj Raid
	-- -- Trash
	[25371]  = "CC",				-- Consume
	[26196]  = "CC",				-- Consume
	[25654]  = "CC",				-- Tail Lash
	[25515]  = "CC",				-- Bash
	[26382]  = "CC",				-- Burrow
	[25756]  = "CC",				-- Purge
	[25374]  = "Root",				-- Consume
	[25187]  = "Snare",				-- Hive'Zara Catalyst
	-- -- Kurinnaxx
	[25656]  = "CC",				-- Sand Trap
	-- -- General Rajaxx
	[19134]  = "CC",				-- Intimidating Shout
	[29544]  = "CC",				-- Intimidating Shout
	[25425]  = "CC",				-- Shockwave
	[25282]  = "Immune",			-- Shield of Rajaxx
	-- -- Moam
	[25685]  = "CC",				-- Energize
	[28450]  = "CC",				-- Arcane Explosion
	-- -- Ayamiss the Hunter
	[25852]  = "CC",				-- Lash
	[6608]   = "Disarm",			-- Dropped Weapon
	[25725]  = "CC",				-- Paralyze
	-- -- Ossirian the Unscarred
	[25189]  = "CC",				-- Enveloping Winds
	------------------------
	-- Temple of Ahn'Qiraj Raid
	-- -- Trash
	[7670]   = "CC",				-- Explode
	[18327]  = "Silence",			-- Silence
	[26069]  = "Silence",			-- Silence
	[26070]  = "CC",				-- Fear
	[26072]  = "CC",				-- Dust Cloud
	[25698]  = "CC",				-- Explode
	[26079]  = "CC",				-- Cause Insanity
	[26049]  = "CC",				-- Mana Burn
	[26552]  = "CC",				-- Nullify
	[26787]  = "CC",				-- Nullify
	[26071]  = "Root",				-- Entangling Roots
	--[13022]  = "ImmuneSpell",		-- Fire and Arcane Reflect (only reflect fire and arcane spells)
	--[19595]  = "ImmuneSpell",		-- Shadow and Frost Reflect (only reflect shadow and frost spells)
	[1906]   = "Snare",				-- Debilitating Charge
	[25809]  = "Snare",				-- Crippling Poison
	[26078]  = "Snare",				-- Vekniss Catalyst
	-- -- The Prophet Skeram
	[785]    = "CC",				-- True Fulfillment
	-- -- Bug Trio: Yauj, Vem, Kri
	[3242]   = "CC",				-- Ravage
	[26580]  = "CC",				-- Fear
	[19128]  = "CC",				-- Knockdown
	[25989]  = "Snare",				-- Toxin
	-- -- Fankriss the Unyielding
	[720]    = "CC",				-- Entangle
	[731]    = "CC",				-- Entangle
	[1121]   = "CC",				-- Entangle
	-- -- Viscidus
	[25937]  = "CC",				-- Viscidus Freeze
	-- -- Princess Huhuran
	[26180]  = "CC",				-- Wyvern Sting
	[26053]  = "Silence",			-- Noxious Poison
	-- -- Twin Emperors: Vek'lor & Vek'nilash
	[800]    = "CC",				-- Twin Teleport
	[804]    = "Root",				-- Explode Bug
	[568]    = "Snare",				-- Arcane Burst
	[12241]  = "Root",				-- Twin Colossals Teleport
	[12242]  = "Root",				-- Twin Colossals Teleport
	-- -- Ouro
	[26102]  = "CC",				-- Sand Blast
	-- -- C'Thun
	[26156]  = "Immune",			-- Carapace of C'Thun
	[23953]  = "Snare",				-- Mind Flay
	[26211]  = "Snare",				-- Hamstring
	[26141]  = "Snare",				-- Hamstring
	------------------------
	-- Naxxramas (Classic) Raid
	-- -- Trash
	[6605]   = "CC",				-- Terrifying Screech
	[27758]  = "CC",				-- War Stomp
	[27990]  = "CC",				-- Fear
	[28412]  = "CC",				-- Death Coil
	[29848]  = "CC",				-- Polymorph
	[28995]  = "Immune",			-- Stoneskin
	[29849]  = "Root",				-- Frost Nova
	[30094]  = "Root",				-- Frost Nova
	[28350]  = "Other",				-- Veil of Darkness (immune to direct healing)
	[28440]  = "Other",				-- Veil of Shadow
	[18328]  = "Snare",				-- Incapacitating Shout
	[28310]  = "Snare",				-- Mind Flay
	[30092]  = "Snare",				-- Blast Wave
	[30095]  = "Snare",				-- Cone of Cold
	-- -- Anub'Rekhan
	[28786]  = "CC",				-- Locust Swarm
	[25821]  = "CC",				-- Charge
	[28991]  = "Root",				-- Web
	-- -- Grand Widow Faerlina
	[30225]  = "Silence",			-- Silence
	[28732]  = "Other",				-- Widow's Embrace (prevents enraged and silenced nature spells)
	-- -- Maexxna
	[28622]  = "CC",				-- Web Wrap
	[29484]  = "CC",				-- Web Spray
	[28776]  = "Other",				-- Necrotic Poison (healing taken reduced by 90%)
	-- -- Noth the Plaguebringer
	[29212]  = "Snare",				-- Cripple
	-- -- Heigan the Unclean
	[30112]  = "CC",				-- Frenzied Dive
	[30109]  = "Snare",				-- Slime Burst
	-- -- Instructor Razuvious
	[29061]  = "Immune",			-- Shield Wall (not immune, 75% damage reduction)
	[29125]  = "Other",				-- Hopeless (increases damage taken by 5000%)
	-- -- Gothik the Harvester
	[11428]  = "CC",				-- Knockdown
	[27993]  = "Snare",				-- Stomp
	-- -- Gluth
	[29685]  = "CC",				-- Terrifying Roar
	-- -- Sapphiron
	[28522]  = "CC",				-- Icebolt
	[28547]  = "Snare",				-- Chill
	-- -- Kel'Thuzad
	[28410]  = "CC",				-- Chains of Kel'Thuzad
	[27808]  = "CC",				-- Frost Blast
	[28478]  = "Snare",				-- Frostbolt
	[28479]  = "Snare",				-- Frostbolt
	------------------------
	-- Classic World Bosses
	-- -- Azuregos
	[23186]  = "CC",				-- Aura of Frost
	[21099]  = "CC",				-- Frost Breath
	[22067]  = "ImmuneSpell",		-- Reflection
	[27564]  = "ImmuneSpell",		-- Reflection
	[21098]  = "Snare",				-- Chill
	-- -- Doom Lord Kazzak & Highlord Kruul
	[8078]   = "Snare",				-- Thunderclap
	[23931]  = "Snare",				-- Thunderclap
	-- -- Dragons of Nightmare
	[25043]  = "CC",				-- Aura of Nature
	[24778]  = "CC",				-- Sleep (Dream Fog)
	[24811]  = "CC",				-- Draw Spirit
	[25806]  = "CC",				-- Creature of Nightmare
	[12528]  = "Silence",			-- Silence
	[23207]  = "Silence",			-- Silence
	[29943]  = "Silence",			-- Silence
	------------------------
	-- Classic Dungeons
	-- -- Ragefire Chasm
	[8242]   = "CC",				-- Shield Slam
	-- -- The Deadmines
	[6304]   = "CC",				-- Rhahk'Zor Slam
	[6713]   = "Disarm",			-- Disarm
	[7399]   = "CC",				-- Terrify
	[5213]   = "Snare",				-- Molten Metal
	[6435]   = "CC",				-- Smite Slam
	[6432]   = "CC",				-- Smite Stomp
	[6264]   = "Other",				-- Nimble Reflexes (chance to parry increased by 75%)
	[113]    = "Root",				-- Chains of Ice
	[512]    = "Root",				-- Chains of Ice
	[5159]   = "Snare",				-- Melt Ore
	[228]    = "CC",				-- Polymorph: Chicken
	[6466]   = "CC",				-- Axe Toss
	-- -- Wailing Caverns
	[8040]   = "CC",				-- Druid's Slumber
	[8147]   = "Snare",				-- Thunderclap
	[8142]   = "Root",				-- Grasping Vines
	[5164]   = "CC",				-- Knockdown
	[7967]   = "CC",				-- Naralex's Nightmare
	[6271]   = "CC",				-- Naralex's Awakening
	[8150]   = "CC",				-- Thundercrack
	-- -- Shadowfang Keep
	[7295]   = "Root",				-- Soul Drain
	[7587]   = "Root",				-- Shadow Port
	[7136]   = "Root",				-- Shadow Port
	[7586]   = "Root",				-- Shadow Port
	[7139]   = "CC",				-- Fel Stomp
	[13005]  = "CC",				-- Hammer of Justice
	[9080]   = "Snare",				-- Hamstring
	[7621]   = "CC",				-- Arugal's Curse
	[7068]   = "Other",				-- Veil of Shadow
	[23224]  = "Other",				-- Veil of Shadow
	[7803]   = "CC",				-- Thundershock
	[7074]   = "Silence",			-- Screams of the Past
	-- -- Blackfathom Deeps
	[246]    = "Snare",				-- Slow
	[15531]  = "Root",				-- Frost Nova
	[6533]   = "Root",				-- Net
	[8399]   = "CC",				-- Sleep
	[8379]   = "Disarm",			-- Disarm
	[18972]  = "Snare",				-- Slow
	[9672]   = "Snare",				-- Frostbolt
	[8398]   = "Snare",				-- Frostbolt Volley
	[8391]   = "CC",				-- Ravage
	[7645]   = "CC",				-- Dominate Mind
	[15043]  = "Snare",				-- Frostbolt
	-- -- The Stockade
	[3419]   = "Other",				-- Improved Blocking
	[7964]   = "CC",				-- Smoke Bomb
	[6253]   = "CC",				-- Backhand
	-- -- Gnomeregan
	[10737]  = "CC",				-- Hail Storm
	[15878]  = "CC",				-- Ice Blast
	[10856]  = "CC",				-- Link Dead
	[10831]  = "ImmuneSpell",		-- Reflection Field
	[11820]  = "Root",				-- Electrified Net
	[10852]  = "Root",				-- Battle Net
	[10734]  = "Snare",				-- Hail Storm
	[11264]  = "Root",				-- Ice Blast
	[10730]  = "CC",				-- Pacify
	-- -- Razorfen Kraul
	[8281]   = "Silence",			-- Sonic Burst
	[8359]   = "CC",				-- Left for Dead
	[8285]   = "CC",				-- Rampage
	[8361]   = "Immune",			-- Purity
	[8377]   = "Root",				-- Earthgrab
	[6984]   = "Snare",				-- Frost Shot
	[6985]   = "Snare",				-- Frost Shot
	[18802]  = "Snare",				-- Frost Shot
	[6728]   = "CC",				-- Enveloping Winds
	[3248]   = "Other",				-- Improved Blocking
	[6524]   = "CC",				-- Ground Tremor
	-- -- Scarlet Monastery
	[9438]   = "Immune",			-- Arcane Bubble
	[13323]  = "CC",				-- Polymorph
	[8988]   = "Silence",			-- Silence
	[8989]   = "ImmuneSpell",		-- Whirlwind
	[13874]  = "Immune",			-- Divine Shield
	[9256]   = "CC",				-- Deep Sleep
	[3639]   = "Other",				-- Improved Blocking
	[6146]   = "Snare",				-- Slow
	-- -- Razorfen Downs
	[12252]  = "Root",				-- Web Spray
	[15530]  = "Snare",				-- Frostbolt
	[12946]  = "Silence",			-- Putrid Stench
	[745]    = "Root",				-- Web
	[11443]  = "Snare",				-- Cripple
	[11436]  = "Snare",				-- Slow
	[12531]  = "Snare",				-- Chilling Touch
	[12748]  = "Root",				-- Frost Nova
	-- -- Uldaman
	[11876]  = "CC",				-- War Stomp
	[3636]   = "CC",				-- Crystalline Slumber
	[9906]   = "ImmuneSpell",		-- Reflection
	[6726]   = "Silence",			-- Silence
	[10093]  = "Silence",			-- Harsh Winds
	[25161]  = "Silence",			-- Harsh Winds
	-- -- Maraudon
	[12747]  = "Root",				-- Entangling Roots
	[21331]  = "Root",				-- Entangling Roots
	[21909]  = "Root",				-- Dust Field
	[21793]  = "Snare",				-- Twisted Tranquility
	[21808]  = "CC",				-- Summon Shardlings
	[29419]  = "CC",				-- Flash Bomb
	[22592]  = "CC",				-- Knockdown
	[21869]  = "CC",				-- Repulsive Gaze
	[16790]  = "CC",				-- Knockdown
	[21748]  = "CC",				-- Thorn Volley
	[21749]  = "CC",				-- Thorn Volley
	[11922]  = "Root",				-- Entangling Roots
	-- -- Zul'Farrak
	[11020]  = "CC",				-- Petrify
	[22692]  = "CC",				-- Petrify
	[13704]  = "CC",				-- Psychic Scream
	[11089]  = "ImmunePhysical",	-- Theka Transform (also immune to shadow damage)
	[12551]  = "Snare",				-- Frost Shot
	[11836]  = "CC",				-- Freeze Solid
	[11131]  = "Snare",				-- Icicle
	[11641]  = "CC",				-- Hex
	-- -- The Temple of Atal'Hakkar (Sunken Temple)
	[12888]  = "CC",				-- Cause Insanity
	[12480]  = "CC",				-- Hex of Jammal'an
	[12483]  = "CC",				-- Hex of Jammal'an
	[12890]  = "CC",				-- Deep Slumber
	[6607]   = "CC",				-- Lash
	[25774]  = "CC",				-- Mind Shatter
	[7992]   = "Snare",				-- Slowing Poison
	-- -- Blackrock Depths
	[8994]   = "CC",				-- Banish
	[15588]  = "Snare",				-- Thunderclap
	[12674]  = "Root",				-- Frost Nova
	[12675]  = "Snare",				-- Frostbolt
	[15244]  = "Snare",				-- Cone of Cold
	[15636]  = "ImmuneSpell",		-- Avatar of Flame
	[7121]   = "ImmuneSpell",		-- Anti-Magic Shield
	[15471]  = "Silence",			-- Enveloping Web
	[3609]   = "CC",				-- Paralyzing Poison
	[15474]  = "Root",				-- Web Explosion
	[17492]  = "CC",				-- Hand of Thaurissan
	[12169]  = "Other",				-- Shield Block
	[15062]  = "Immune",			-- Shield Wall (not immune, 75% damage reduction)
	[14030]  = "Root",				-- Hooked Net
	[14870]  = "CC",				-- Drunken Stupor
	[13902]  = "CC",				-- Fist of Ragnaros
	[15063]  = "Root",				-- Frost Nova
	[6945]   = "CC",				-- Chest Pains
	[3551]   = "CC",				-- Skull Crack
	[15621]  = "CC",				-- Skull Crack
	[11831]  = "Root",				-- Frost Nova
	[15499]  = "Snare",				-- Frost Shock
	-- -- Blackrock Spire
	[16097]  = "CC",				-- Hex
	[22566]  = "CC",				-- Hex
	[15618]  = "CC",				-- Snap Kick
	[16075]  = "CC",				-- Throw Axe
	[16045]  = "CC",				-- Encage
	[16104]  = "CC",				-- Crystallize
	[16508]  = "CC",				-- Intimidating Roar
	[15609]  = "Root",				-- Hooked Net
	[16497]  = "CC",				-- Stun Bomb
	[5276]   = "CC",				-- Freeze
	[18763]  = "CC",				-- Freeze
	[16805]  = "CC",				-- Conflagration
	[13579]  = "CC",				-- Gouge
	[24698]  = "CC",				-- Gouge
	[28456]  = "CC",				-- Gouge
	[16046]  = "Snare",				-- Blast Wave
	[15744]  = "Snare",				-- Blast Wave
	[16249]  = "Snare",				-- Frostbolt
	[16469]  = "Root",				-- Web Explosion
	[15532]  = "Root",				-- Frost Nova
	-- -- Stratholme
	[17398]  = "CC",				-- Balnazzar Transform Stun
	[17405]  = "CC",				-- Domination
	[17246]  = "CC",				-- Possessed
	[19832]  = "CC",				-- Possess
	[15655]  = "CC",				-- Shield Slam
	[19645]  = "ImmuneSpell",		-- Anti-Magic Shield
	[16799]  = "Snare",				-- Frostbolt
	[16798]  = "CC",				-- Enchanting Lullaby
	[12542]  = "CC",				-- Fear
	[12734]  = "CC",				-- Ground Smash
	[17293]  = "CC",				-- Burning Winds
	[4962]   = "Root",				-- Encasing Webs
	[13322]  = "Snare",				-- Frostbolt
	[15089]  = "Snare",				-- Frost Shock
	[12557]  = "Snare",				-- Cone of Cold
	[16869]  = "CC",				-- Ice Tomb
	[17244]  = "CC",				-- Possess
	[17307]  = "CC",				-- Knockout
	[15970]  = "CC",				-- Sleep
	[14897]  = "Snare",				-- Slowing Poison
	[3589]   = "Silence",			-- Deafening Screech
	-- -- Dire Maul
	[27553]  = "CC",				-- Maul
	[17145]  = "Snare",				-- Blast Wave
	[22651]  = "CC",				-- Sacrifice
	[22419]  = "Disarm",			-- Riptide
	[22691]  = "Disarm",			-- Disarm
	[22833]  = "CC",				-- Booze Spit (chance to hit reduced by 75%)
	[22856]  = "CC",				-- Ice Lock
	[16727]  = "CC",				-- War Stomp
	--[22735]  = "ImmuneSpell",		-- Spirit of Runn Tum (not immune, 50% chance reflect spells)
	[22994]  = "Root",				-- Entangle
	[22924]  = "Root",				-- Grasping Vines
	[22914]  = "Snare",				-- Concussive Shot
	[22915]  = "CC",				-- Improved Concussive Shot
	[22919]  = "Snare",				-- Mind Flay
	[22909]  = "Snare",				-- Eye of Immol'thar
	[28858]  = "Root",				-- Entangling Roots
	[22415]  = "Root",				-- Entangling Roots
	[22744]  = "Root",				-- Chains of Ice
	[16856]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[12611]  = "Snare",				-- Cone of Cold
	[16838]  = "Silence",			-- Banshee Shriek
	[22519]  = "CC",				-- Ice Nova
	[22356]  = "Snare",				-- Slow
	-- -- Scholomance
	[5708]   = "CC",				-- Swoop
	[18144]  = "CC",				-- Swoop
	[18103]  = "CC",				-- Backhand
	[8208]   = "CC",				-- Backhand
	[12461]  = "CC",				-- Backhand
	[8140]   = "Other",				-- Befuddlement
	[8611]   = "Immune",			-- Phase Shift
	[17651]  = "Immune",			-- Image Projection
	[27565]  = "CC",				-- Banish
	[18099]  = "Snare",				-- Chill Nova
	[16350]  = "CC",				-- Freeze
	[17165]  = "Snare",				-- Mind Flay
	[22643]  = "Snare",				-- Frostbolt Volley
	[18101]  = "Snare",				-- Chilled (Frost Armor)
}

if debug then
	for k in pairs(spellIds) do
		local name, _, icon = GetSpellInfo(k)
		if not name then print(addonName, ": No spell name", k) end
		if not icon then print(addonName, ": No spell icon", k) end
	end
end

-- Helper function to access to global variables with dynamic names that allow fields
local function _GF(f)
	if (f==nil or f=="" or type(f)~="string") then return nil end
	local v = _G
	for w in strgmatch(f, "[^%.]+") do
		if (type(v) == "table") then
			v = v[w]
		else
			v = nil
			break
		end
	end
	return v
end

-------------------------------------------------------------------------------
-- Global references for attaching icons to various unit frames
local anchors = {
	None = {}, -- empty but necessary
	Blizzard = {
		player       = "PlayerPortrait",
		pet          = "PetPortrait",
		target       = "TargetFramePortrait",
		targettarget = "TargetFrameToTPortrait",
		party1       = "PartyMemberFrame1Portrait",
		party2       = "PartyMemberFrame2Portrait",
		party3       = "PartyMemberFrame3Portrait",
		party4       = "PartyMemberFrame4Portrait",
		--party1pet    = "PartyMemberFrame1PetFramePortrait",
		--party2pet    = "PartyMemberFrame2PetFramePortrait",
		--party3pet    = "PartyMemberFrame3PetFramePortrait",
		--party4pet    = "PartyMemberFrame4PetFramePortrait",
	},
	BlizzardRaidFrames = {
		raid1        = "CompactRaidFrame1",
		raid2        = "CompactRaidFrame2",
		raid3        = "CompactRaidFrame3",
		raid4        = "CompactRaidFrame4",
		raid5        = "CompactRaidFrame5",
		raid6        = "CompactRaidFrame6",
		raid7        = "CompactRaidFrame7",
		raid8        = "CompactRaidFrame8",
		raid9        = "CompactRaidFrame9",
		raid10       = "CompactRaidFrame10",
		raid11       = "CompactRaidFrame11",
		raid12       = "CompactRaidFrame12",
		raid13       = "CompactRaidFrame13",
		raid14       = "CompactRaidFrame14",
		raid15       = "CompactRaidFrame15",
		raid16       = "CompactRaidFrame16",
		raid17       = "CompactRaidFrame17",
		raid18       = "CompactRaidFrame18",
		raid19       = "CompactRaidFrame19",
		raid20       = "CompactRaidFrame20",
		raid21       = "CompactRaidFrame21",
		raid22       = "CompactRaidFrame22",
		raid23       = "CompactRaidFrame23",
		raid24       = "CompactRaidFrame24",
		raid25       = "CompactRaidFrame25",
		raid26       = "CompactRaidFrame26",
		raid27       = "CompactRaidFrame27",
		raid28       = "CompactRaidFrame28",
		raid29       = "CompactRaidFrame29",
		raid30       = "CompactRaidFrame30",
		raid31       = "CompactRaidFrame31",
		raid32       = "CompactRaidFrame32",
		raid33       = "CompactRaidFrame33",
		raid34       = "CompactRaidFrame34",
		raid35       = "CompactRaidFrame35",
		raid36       = "CompactRaidFrame36",
		raid37       = "CompactRaidFrame37",
		raid38       = "CompactRaidFrame38",
		raid39       = "CompactRaidFrame39",
		raid40       = "CompactRaidFrame40",
	},
	Perl = {
		player       = "Perl_Player_PortraitFrame",
		pet          = "Perl_Player_Pet_PortraitFrame",
		target       = "Perl_Target_PortraitFrame",
		targettarget = "Perl_Target_Target_PortraitFrame",
		party1       = "Perl_Party_MemberFrame1_PortraitFrame",
		party2       = "Perl_Party_MemberFrame2_PortraitFrame",
		party3       = "Perl_Party_MemberFrame3_PortraitFrame",
		party4       = "Perl_Party_MemberFrame4_PortraitFrame",
	},
	XPerl = {	-- and Z-Perl
		player       = "XPerl_PlayerportraitFrameportrait",
		pet          = "XPerl_Player_PetportraitFrameportrait",
		target       = "XPerl_TargetportraitFrameportrait",
		targettarget = "XPerl_TargettargetportraitFrameportrait",
		party1       = "XPerl_party1portraitFrameportrait",
		party2       = "XPerl_party2portraitFrameportrait",
		party3       = "XPerl_party3portraitFrameportrait",
		party4       = "XPerl_party4portraitFrameportrait",
	},
	LUI = {
		player       = "oUF_LUI_player",
		pet          = "oUF_LUI_pet",
		target       = "oUF_LUI_target",
		targettarget = "oUF_LUI_targettarget",
		party1       = "oUF_LUI_partyUnitButton1",
		party2       = "oUF_LUI_partyUnitButton2",
		party3       = "oUF_LUI_partyUnitButton3",
		party4       = "oUF_LUI_partyUnitButton4",
	},
	SUF = {
		player       = "SUFUnitplayer.portrait",
		pet          = "SUFUnitpet.portrait",
		target       = "SUFUnittarget.portrait",
		targettarget = "SUFUnittargettarget.portrait",
		party1       = "SUFHeaderpartyUnitButton1.portrait",
		party2       = "SUFHeaderpartyUnitButton2.portrait",
		party3       = "SUFHeaderpartyUnitButton3.portrait",
		party4       = "SUFHeaderpartyUnitButton4.portrait",
	},
	LUF = {
		player       = "LUFUnitplayer.StatusPortrait.model",
		pet          = "LUFUnitpet.StatusPortrait.model",
		target       = "LUFUnittarget.StatusPortrait.model",
		targettarget = "LUFUnittargettarget.StatusPortrait.model",
		party1       = "LUFHeaderpartyUnitButton1.StatusPortrait.model",
		party2       = "LUFHeaderpartyUnitButton2.StatusPortrait.model",
		party3       = "LUFHeaderpartyUnitButton3.StatusPortrait.model",
		party4       = "LUFHeaderpartyUnitButton4.StatusPortrait.model",
	},
	PitBullUF = {
		player       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Player"]..".Portrait" or nil,
		pet          = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Player's pet"]..".Portrait" or nil,
		target       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Target"]..".Portrait" or nil,
		targettarget = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["%s's target"]:format(LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Target"])..".Portrait" or nil,
		party1       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton1"..".Portrait" or nil,
		party2       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton2"..".Portrait" or nil,
		party3       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton3"..".Portrait" or nil,
		party4       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton4"..".Portrait" or nil,
	},
	SpartanUI_2D = {
		player       = "SUI_UF_player.Portrait2D",
		pet          = "SUI_UF_pet.Portrait2D",
		target       = "SUI_UF_target.Portrait2D",
		targettarget = "SUI_UF_targettarget.Portrait2D",
	},
	SpartanUI_3D = {
		player       = "SUI_UF_player.Portrait3D",
		pet          = "SUI_UF_pet.Portrait3D",
		target       = "SUI_UF_target.Portrait3D",
		targettarget = "SUI_UF_targettarget.Portrait3D",
	},
	SpartanUI_2D_PlayerInParty = {
		party1       = "SUI_partyFrameHeaderUnitButton2.Portrait2D",
		party2       = "SUI_partyFrameHeaderUnitButton3.Portrait2D",
		party3       = "SUI_partyFrameHeaderUnitButton4.Portrait2D",
		party4       = "SUI_partyFrameHeaderUnitButton5.Portrait2D",
	},
	SpartanUI_2D_NoPlayerInParty = {
		party1       = "SUI_partyFrameHeaderUnitButton1.Portrait2D",
		party2       = "SUI_partyFrameHeaderUnitButton2.Portrait2D",
		party3       = "SUI_partyFrameHeaderUnitButton3.Portrait2D",
		party4       = "SUI_partyFrameHeaderUnitButton4.Portrait2D",
	},
	SpartanUI_3D_PlayerInParty = {
		party1       = "SUI_partyFrameHeaderUnitButton2.Portrait3D",
		party2       = "SUI_partyFrameHeaderUnitButton3.Portrait3D",
		party3       = "SUI_partyFrameHeaderUnitButton4.Portrait3D",
		party4       = "SUI_partyFrameHeaderUnitButton5.Portrait3D",
	},
	SpartanUI_3D_NoPlayerInParty = {
		party1       = "SUI_partyFrameHeaderUnitButton1.Portrait3D",
		party2       = "SUI_partyFrameHeaderUnitButton2.Portrait3D",
		party3       = "SUI_partyFrameHeaderUnitButton3.Portrait3D",
		party4       = "SUI_partyFrameHeaderUnitButton4.Portrait3D",
	},
	GW2 = {
		player       = "GwPlayerUnitFrame.portrait",
		pet          = "GwPlayerPetFrame.portrait",
		target       = "GwTargetUnitFrame.portrait",
		party1       = "GwPartyFrame1.portrait",
		party2       = "GwPartyFrame2.portrait",
		party3       = "GwPartyFrame3.portrait",
		party4       = "GwPartyFrame4.portrait",
	},
	nUI = {
		player       = "nUI_PartyUnit_Player_Portrait",
		target       = "nUI_PartyUnit_Target_Portrait",
		party1       = "nUI_PartyUnit_Party1_Portrait",
		party2       = "nUI_PartyUnit_Party2_Portrait",
		party3       = "nUI_PartyUnit_Party3_Portrait",
		party4       = "nUI_PartyUnit_Party4_Portrait",
	},
	Tukui = {
		player       = "TukuiPlayerFrame.Portrait",
		target       = "TukuiTargetFrame.Portrait",
	},
	ElvUI = {
		player       = "ElvUF_Player.Portrait",
		pet          = "ElvUF_Pet.Portrait",
		target       = "ElvUF_Target.Portrait",
		targettarget = "ElvUF_TargetTarget.Portrait",
	},
	ElvUI_PlayerInParty = {
		party1       = "ElvUF_PartyGroup1UnitButton2.Portrait",
		party2       = "ElvUF_PartyGroup1UnitButton3.Portrait",
		party3       = "ElvUF_PartyGroup1UnitButton4.Portrait",
		party4       = "ElvUF_PartyGroup1UnitButton5.Portrait",
	},
	ElvUI_NoPlayerInParty = {
		party1       = "ElvUF_PartyGroup1UnitButton1.Portrait",
		party2       = "ElvUF_PartyGroup1UnitButton2.Portrait",
		party3       = "ElvUF_PartyGroup1UnitButton2.Portrait",
		party4       = "ElvUF_PartyGroup1UnitButton3.Portrait",
	}
	-- more to come here?
}

-------------------------------------------------------------------------------
-- Default settings
local DBdefaults = {
	version = 1.6, -- This is the settings version, not necessarily the same as the LoseControl version
	noCooldownCount = false,
	noGetExtraAuraDurationInformation = false,
	noGetEnemiesBuffsInformation = false,
	noBlizzardCooldownCount = true,
	disablePartyInBG = true,
	disablePartyInRaid = true,
	disableRaidInBG = false,
	disablePlayerTargetTarget = false,
	disableTargetTargetTarget = false,
	disablePlayerTargetPlayerTargetTarget = true,
	disableTargetDeadTargetTarget = true,
	showNPCInterruptsTarget = true,
	showNPCInterruptsTargetTarget = true,
	duplicatePlayerPortrait = true,
	showPartyplayerIcon = true,
	lastIncompatibilitiesAskedTimestamp = 0,
	customSpellIds = { },
	priority = {		-- higher numbers have more priority; 0 = disabled
		PvE = 90,
		Immune = 80,
		ImmuneSpell	= 70,
		ImmunePhysical = 65,
		CC = 60,
		Silence = 50,
		Interrupt = 40,
		Disarm = 30,
		Other = 10,
		Root = 0,
		Snare = 0,
	},
	frames = {
		player = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "None",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = false, ImmuneSpell = false, ImmunePhysical = false, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = false, ImmuneSpell = false, ImmunePhysical = false, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		player2 = {
			enabled = true,
			size = 56,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		pet = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		target = {
			enabled = true,
			size = 56,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true,
					enemy    = true
				}
			}
		},
		targettarget = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true,
					enemy    = true
				}
			}
		},
		party1 = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		party2 = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		party3 = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		party4 = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		partyplayer = {
			enabled = false,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "None",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					friendly = true
				}
			}
		},
		raid1 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid2 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid3 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid4 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid5 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid6 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid7 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid8 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid9 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid10 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid11 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid12 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid13 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid14 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid15 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid16 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid17 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid18 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid19 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid20 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid21 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid22 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid23 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid24 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid25 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid26 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid27 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid28 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid29 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid30 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid31 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid32 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid33 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid34 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid35 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid36 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid37 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid38 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid39 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid40 = {
			enabled = true,
			size = 20,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardRaidFrames",
			x = 0,
			y = 1,
			categoriesEnabled = {
				buff =      { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = true } },
				debuff =    { friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true } },
				interrupt = { friendly = true }
			}
		},
	},
}
local LoseControlDB -- local reference to the addon settings. this gets initialized when the ADDON_LOADED event fires

-------------------------------------------------------------------------------
-- Create the main class
local LoseControl = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate") -- Exposes the SetCooldown method

function LoseControl:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
LoseControl:SetScript("OnEvent", LoseControl.OnEvent)

-- Function to register/unregister a frame for UnitWatch
RefreshPendingUnitWatchState = function()
	for frame, register in pairs(LCUnitPendingUnitWatchFrames) do
		if (register) then
			RegisterUnitWatch(frame, true)
		else
			UnregisterUnitWatch(frame)
		end
		LCUnitPendingUnitWatchFrames[frame] = nil
	end
end

-- Utility function to handle registering for unit events
function LoseControl:RegisterUnitEvents(enabled)
	local unitId = self.unitId
	if debug then print("RegisterUnitEvents", unitId, enabled) end
	if enabled then
		if unitId == "target" then
			self:RegisterUnitEvent("UNIT_AURA", unitId)
			self:RegisterEvent("PLAYER_TARGET_CHANGED")
		elseif unitId == "targettarget" then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:RegisterEvent("PLAYER_TARGET_CHANGED")
			self:RegisterUnitEvent("UNIT_TARGET", "target")
			self:RegisterEvent("UNIT_AURA")
			if InCombatLockdown() then
				LCUnitPendingUnitWatchFrames[self] = true
				delayFunc_RefreshPendingUnitWatchState = true
				if (not LCCombatLockdownDelayFrame:IsEventRegistered("PLAYER_REGEN_ENABLED")) then
					LCCombatLockdownDelayFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
				end
			else
				LCUnitPendingUnitWatchFrames[self] = nil
				RegisterUnitWatch(self, true)
			end
			if (not TARGETTOTARGET_ANCHORTRIGGER_UNIT_AURA_HOOK) then
				-- Update unit frecuently when exists
				self.UpdateStateFuncCache = function() self:UpdateState(true) end
				function self:UpdateState(autoCall)
					if not autoCall and self.timerActive then return end
					if (self.frame.enabled and not self.unlockMode and UnitExists(self.unitId)) then
						self.unitGUID = UnitGUID(self.unitId)
						self:UNIT_AURA(self.unitId, 300)
						self.timerActive = true
						C_Timer.After(0.5, self.UpdateStateFuncCache)
					else
						self.timerActive = false
					end
				end
				-- Attribute state-unitexists from RegisterUnitWatch
				self:SetScript("OnAttributeChanged", function(self, name, value)
					if (self.frame.enabled and not self.unlockMode) then
						self.unitGUID = UnitGUID(self.unitId)
						self:UNIT_AURA(self.unitId, 200)
					end
					if value then
						self:UpdateState()
					end
				end)
				-- TargetTarget Blizzard Frame Show
				TargetFrameToT:HookScript("OnShow", function()
					if (self.frame.enabled and not self.unlockMode) then
						self.unitGUID = UnitGUID(self.unitId)
						if self.frame.anchor == "Blizzard" then
							self:UNIT_AURA(self.unitId, -30)
						else
							self:UNIT_AURA(self.unitId, 30)
						end
					end
				end)
				-- TargetTarget Blizzard Debuff Show/Hide
				for i = 1, 4 do
					local TframeToTDebuff = _G["TargetFrameToTDebuff"..i]
					if (TframeToTDebuff ~= nil) then
						TframeToTDebuff:HookScript("OnShow", function()
							if (self.frame.enabled) then
								local timeCombatLogAuraEvent = GetTime()
								C_Timer.After(0.01, function()	-- execute in some close next frame to depriorize this event
									if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < timeCombatLogAuraEvent)) then
										self.unitGUID = UnitGUID(self.unitId)
										self:UNIT_AURA(self.unitId, 40)
									end
								end)
							end
						end)
						TframeToTDebuff:HookScript("OnHide", function()
							if (self.frame.enabled) then
								local timeCombatLogAuraEvent = GetTime()
								C_Timer.After(0.01, function()	-- execute in some close next frame to depriorize this event
									if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < timeCombatLogAuraEvent)) then
										self.unitGUID = UnitGUID(self.unitId)
										self:UNIT_AURA(self.unitId, 43)
									end
								end)
							end
						end)
					end
				end
				TARGETTOTARGET_ANCHORTRIGGER_UNIT_AURA_HOOK = true
			end
		elseif unitId == "pet" then
			self:RegisterUnitEvent("UNIT_AURA", unitId)
			self:RegisterUnitEvent("UNIT_PET", "player")
		else
			self:RegisterUnitEvent("UNIT_AURA", unitId)
		end
	else
		if unitId == "target" then
			self:UnregisterEvent("UNIT_AURA")
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		elseif unitId == "targettarget" then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
			self:UnregisterEvent("UNIT_TARGET")
			self:UnregisterEvent("UNIT_AURA")
			if InCombatLockdown() then
				LCUnitPendingUnitWatchFrames[self] = false
				delayFunc_RefreshPendingUnitWatchState = true
				if (not LCCombatLockdownDelayFrame:IsEventRegistered("PLAYER_REGEN_ENABLED")) then
					LCCombatLockdownDelayFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
				end
			else
				LCUnitPendingUnitWatchFrames[self] = nil
				UnregisterUnitWatch(self)
			end
		elseif unitId == "pet" then
			self:UnregisterEvent("UNIT_AURA")
			self:UnregisterEvent("UNIT_PET")
		else
			self:UnregisterEvent("UNIT_AURA")
		end
		if not self.unlockMode then
			self:Hide()
			self:GetParent():Hide()
		end
	end
	if (LoseControlDB.priority.Interrupt > 0) then
		local someFrameEnabled = false
		for _, v in pairs(LCframes) do
			if v.frame and v.frame.enabled then
				someFrameEnabled = true
				break
			end
		end
		if someFrameEnabled then
			LCframes["target"]:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			LCframes["target"]:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	else
		LCframes["target"]:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

-- Function to update spellIds table with customSpellIds from user
function LoseControl:UpdateSpellIdsTableWithCustomSpellIds()
	for oSpellId, oPriority  in pairs(origSpellIdsChanged) do
		if (oPriority == "None") then
			spellIds[oSpellId] = nil
		else
			spellIds[oSpellId] = oPriority
		end
	end
	origSpellIdsChanged = { }
	for cSpellId, cPriority in pairs(LoseControlDB.customSpellIds) do
		if (cPriority == "None") then
			local oPriority = spellIds[cSpellId]
			origSpellIdsChanged[cSpellId] = (oPriority == nil) and "None" or oPriority
			spellIds[cSpellId] = nil
		elseif (LoseControlDB.priority[cPriority]) then
			local oPriority = spellIds[cSpellId]
			origSpellIdsChanged[cSpellId] = (oPriority == nil) and "None" or oPriority
			spellIds[cSpellId] = cPriority
		end
	end
end

-- Function to check and clean customSpellIds table
function LoseControl:CheckAndCleanCustomSpellIdsTable()
	for cSpellId, cPriority in pairs(LoseControlDB.customSpellIds) do
		if (cPriority == "None") then
			if (origSpellIdsChanged[cSpellId] == "None") then
				LoseControlDB.customSpellIds[cSpellId] = nil
				print(addonName, "|cff00ff00["..cSpellId.."]->("..cPriority..")|r Removed from custom list. Reason: This spellId is no longer present in the addon's default spellId list")
			end
		elseif (LoseControlDB.priority[cPriority]) then
			if (origSpellIdsChanged[cSpellId] == cPriority) then
				LoseControlDB.customSpellIds[cSpellId] = nil
				print(addonName, "|cff00ff00["..cSpellId.."]->("..cPriority..")|r Removed from custom list. Reason: This spellId is already added with the same priority category in the addon's default spellId list")
			end
		else
			LoseControlDB.customSpellIds[cSpellId] = nil
			print(addonName, "|cff00ff00["..cSpellId.."]->("..cPriority..")|r Removed from custom list. Reason: This spellId has an invalid associated category")
		end
	end
	print(addonName, "Finished the check-and-clean of custom list")
	LoseControl:UpdateSpellIdsTableWithCustomSpellIds()
end

-- Function to get the enabled/disabled status of LoseControl frame
function LoseControl:GetEnabled()
	local inInstance, instanceType = IsInInstance()
	local enabled = self.frame.enabled and not (
		inInstance and instanceType == "pvp" and (
			( LoseControlDB.disablePartyInBG and strfind((self.fakeUnitId or self.unitId), "party") ) or
			( LoseControlDB.disableRaidInBG and strfind((self.fakeUnitId or self.unitId), "raid") )
		)
	) and not (
		IsInRaid() and LoseControlDB.disablePartyInRaid and strfind((self.fakeUnitId or self.unitId), "party") and not (inInstance and instanceType=="pvp")
	) and not (
		not(IsInGroup()) and (self.fakeUnitId == "partyplayer")
	)
	return enabled
end

-- Function to enable/disable the enemies buff tracking
function LoseControl:UpdateGetEnemiesBuffInformationOptionState()
	if LoseControlDB.noGetEnemiesBuffsInformation then
		LibClassicDurations.UnregisterCallback(addonName, "UNIT_BUFF")
	else
		LibClassicDurations.RegisterCallback(addonName, "UNIT_BUFF", function(event, unitId)
			local icon = LCframes[unitId]
			if icon then
				if icon:GetEnabled() and not icon.unlockMode then
					icon:UNIT_AURA(unitId, -1)
				end
			end
		end)
	end
end

-- Function to update the interruptsSpellIdByName table
function LoseControl:UpdateInterruptsSpellIdByNameTable()
	for k, v in pairs(interruptsIds) do
		local spellName = GetSpellInfo(k)
		if (spellName ~= nil) then
			if (interruptsSpellIdByName[spellName] ~= nil) then
				local pos = 1
				for _, w in ipairs(interruptsSpellIdByName[spellName]) do
					if (v[2] > w[3]) then
						break
					end
					pos = pos + 1
				end
				tblinsert(interruptsSpellIdByName[spellName], pos, { k, v[1], v[2], v[3] or false, v[4] or nil })
			else
				interruptsSpellIdByName[spellName] = { [1] = { k, v[1], v[2], v[3] or false, v[4] or nil } }
			end
		end
	end
end

-- Function to set the size of the schoolinterrupt icons based on the size of the main icon
local function SetInterruptIconsSize(iconFrame, iconSize)
	local interruptIconSize = (iconSize * 0.88) / 3
	local interruptIconOffset = (iconSize * 0.06)
	if iconFrame.frame.anchor == "Blizzard" then
		iconFrame.interruptIconOrderPos = {
			[1] = {-interruptIconOffset-interruptIconSize, interruptIconOffset},						-- Center, Bottom
			[2] = {-interruptIconOffset, interruptIconOffset+interruptIconSize},						-- Right, Center
			[3] = {-interruptIconOffset-interruptIconSize, interruptIconOffset+interruptIconSize},		-- Center, Center
			[4] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset+interruptIconSize},	-- Left, Center
			[5] = {-interruptIconOffset, interruptIconOffset+interruptIconSize*2},						-- Right, Top
			[6] = {-interruptIconOffset-interruptIconSize, interruptIconOffset+interruptIconSize*2},	-- Center, Top
			[7] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset+interruptIconSize*2},	-- Left, Top
			[8] = {-interruptIconOffset, interruptIconOffset},											-- Right, Bottom
			[9] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset}						-- Left, Bottom
		}
	else
		iconFrame.interruptIconOrderPos = {
			[1] = {-interruptIconOffset, interruptIconOffset},											-- Right, Bottom
			[2] = {-interruptIconOffset-interruptIconSize, interruptIconOffset},						-- Center, Bottom
			[3] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset},						-- Left, Bottom
			[4] = {-interruptIconOffset, interruptIconOffset+interruptIconSize},						-- Right, Center
			[5] = {-interruptIconOffset-interruptIconSize, interruptIconOffset+interruptIconSize},		-- Center, Center
			[6] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset+interruptIconSize},	-- Left, Center
			[7] = {-interruptIconOffset, interruptIconOffset+interruptIconSize*2},						-- Right, Top
			[8] = {-interruptIconOffset-interruptIconSize, interruptIconOffset+interruptIconSize*2},	-- Center, Top
			[9] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset+interruptIconSize*2}	-- Left, Top
		}
	end
	iconFrame.iconInterruptBackground:SetWidth(iconSize)
	iconFrame.iconInterruptBackground:SetHeight(iconSize)
	local i = 1
	for _, v in pairs(iconFrame.iconInterruptList) do
		v:SetWidth(interruptIconSize)
		v:SetHeight(interruptIconSize)
		v:SetPoint("BOTTOMRIGHT", iconFrame.interruptIconOrderPos[v.interruptIconOrder or i][1], iconFrame.interruptIconOrderPos[v.interruptIconOrder or i][2])
		i = i + 1
	end
end

-- Callback function called when user changes the background interrupt color in color picker frame
local function InterruptBackgroundColorPickerChangeCallback()
	local frames = ColorPickerFrame.colourBox and ColorPickerFrame.colourBox.frames or nil
	local newR, newG, newB = ColorPickerFrame:GetColorRGB()
	if (type(frames) == "table" and frames[1] ~= nil and newR ~= nil and newG ~= nil and newB ~= nil) then
		local pframe = ColorPickerFrame.colourBox and ColorPickerFrame.colourBox.pframe or nil
		if (pframe ~= nil) then
			local ColorPickerBackgroundInterruptREditBox = _G['LoseControlOptionsPanel'..pframe..'ColorPickerBackgroundInterruptREditBox']
			if (ColorPickerBackgroundInterruptREditBox ~= nil) then
				ColorPickerBackgroundInterruptREditBox:SetText(mathfloor(newR * 255 + 0.5))
			end
			local ColorPickerBackgroundInterruptGEditBox = _G['LoseControlOptionsPanel'..pframe..'ColorPickerBackgroundInterruptGEditBox']
			if (ColorPickerBackgroundInterruptGEditBox ~= nil) then
				ColorPickerBackgroundInterruptGEditBox:SetText(mathfloor(newG * 255 + 0.5))
			end
			local ColorPickerBackgroundInterruptBEditBox = _G['LoseControlOptionsPanel'..pframe..'ColorPickerBackgroundInterruptBEditBox']
			if (ColorPickerBackgroundInterruptBEditBox ~= nil) then
				ColorPickerBackgroundInterruptBEditBox:SetText(mathfloor(newB * 255 + 0.5))
			end
		end
		ColorPickerFrame.colourBox:SetVertexColor(newR, newG, newB)
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].interruptBackgroundVertexColor.r, LoseControlDB.frames[frame].interruptBackgroundVertexColor.g, LoseControlDB.frames[frame].interruptBackgroundVertexColor.b = newR, newG, newB
			LCframes[frame].iconInterruptBackground:SetVertexColor(newR, newG, newB)
			if (LCframes[frame].unlockMode) then
				if (ColorPickerFrame:IsShown()) then
					LCframes[frame].iconInterruptBackground:Show()
				else
					LCframes[frame].iconInterruptBackground:Hide()
				end
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.interruptBackgroundVertexColor.r, LoseControlDB.frames.player2.interruptBackgroundVertexColor.g, LoseControlDB.frames.player2.interruptBackgroundVertexColor.b = newR, newG, newB
				LCframeplayer2.iconInterruptBackground:SetVertexColor(newR, newG, newB)
				if (LCframeplayer2.unlockMode) then
					if (ColorPickerFrame:IsShown()) then
						LCframeplayer2.iconInterruptBackground:Show()
					else
						LCframeplayer2.iconInterruptBackground:Show()
					end
				end
			end
		end
	end
end

-- Callback function called when user cancels the selection of the background interrupt color in color picker frame
local function InterruptBackgroundColorPickerCancelCallback()
	local frames = ColorPickerFrame.colourBox and ColorPickerFrame.colourBox.frames or nil
	if (type(frames) == "table" and frames[1] ~= nil and ColorPickerFrame.previousValues ~= nil) then
		local oldR, oldG, oldB = unpack(ColorPickerFrame.previousValues)
		if (oldR ~= nil and oldG ~= nil and oldB ~= nil) then
			local pframe = ColorPickerFrame.colourBox and ColorPickerFrame.colourBox.pframe or nil
			if (pframe ~= nil) then
				local ColorPickerBackgroundInterruptREditBox = _G['LoseControlOptionsPanel'..pframe..'ColorPickerBackgroundInterruptREditBox']
				if (ColorPickerBackgroundInterruptREditBox ~= nil) then
					ColorPickerBackgroundInterruptREditBox:SetText(mathfloor(oldR * 255 + 0.5))
				end
				local ColorPickerBackgroundInterruptGEditBox = _G['LoseControlOptionsPanel'..pframe..'ColorPickerBackgroundInterruptGEditBox']
				if (ColorPickerBackgroundInterruptGEditBox ~= nil) then
					ColorPickerBackgroundInterruptGEditBox:SetText(mathfloor(oldG * 255 + 0.5))
				end
				local ColorPickerBackgroundInterruptBEditBox = _G['LoseControlOptionsPanel'..pframe..'ColorPickerBackgroundInterruptBEditBox']
				if (ColorPickerBackgroundInterruptBEditBox ~= nil) then
					ColorPickerBackgroundInterruptBEditBox:SetText(mathfloor(oldB * 255 + 0.5))
				end
			end
			ColorPickerFrame.colourBox:SetVertexColor(oldR, oldG, oldB)
			for _, frame in ipairs(frames) do
				LoseControlDB.frames[frame].interruptBackgroundVertexColor.r, LoseControlDB.frames[frame].interruptBackgroundVertexColor.g, LoseControlDB.frames[frame].interruptBackgroundVertexColor.b = oldR, oldG, oldB
				LCframes[frame].iconInterruptBackground:SetVertexColor(oldR, oldG, oldB)
				if (LCframes[frame].unlockMode) then
					LCframes[frame].iconInterruptBackground:Hide()
				end
				if (frame == "player") then
					LoseControlDB.frames.player2.interruptBackgroundVertexColor.r, LoseControlDB.frames.player2.interruptBackgroundVertexColor.g, LoseControlDB.frames.player2.interruptBackgroundVertexColor.b = oldR, oldG, oldB
					LCframeplayer2.iconInterruptBackground:SetVertexColor(oldR, oldG, oldB)
					if (LCframeplayer2.unlockMode) then
						LCframeplayer2.iconInterruptBackground:Hide()
					end
				end
			end
		end
	end
end

-- Function to hide the color picker frame
local function HideColorPicker()
	if (ColorPickerFrame:IsShown()) then
		HideUIPanel(ColorPickerFrame)
		if ColorPickerFrame.cancelFunc then
			ColorPickerFrame.cancelFunc(ColorPickerFrame.previousValues)
		end
	end
end

-- Function to show the color picker frame
local function ShowColorPicker(colourBox, r, g, b, a, changedCallback, cancelCallback)
	HideColorPicker()
	ColorPickerFrame.colourBox = colourBox
	ColorPickerFrame.previousValues = {r, g, b, a}
	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
	ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, cancelCallback
	ColorPickerFrame:Hide()	-- Need to run the OnShow handler.
	ColorPickerFrame:Show()
end

local function LoseControl_CheckIncompatibilities(version)
	if (ClassicAuraDurationsDB and (ClassicAuraDurationsDB.portraitIcon or ClassicAuraDurationsDB.playerPortraitIcon)) then
		local textCILC_Opt1 = L["LOSECONTROL_CHECKINCOMPATIBILITIES_OPT_1A"]
		if (ClassicAuraDurationsDB.portraitIcon and ClassicAuraDurationsDB.playerPortraitIcon) then
			textCILC_Opt1 = L["LOSECONTROL_CHECKINCOMPATIBILITIES_OPT_1B"]
		end
		local textCILC =  "LoseControl " .. version .. "\n----------------------\n\n" .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L1"]
		if (ClassicAuraDurationsDB.portraitIcon and ClassicAuraDurationsDB.playerPortraitIcon) then
			textCILC = textCILC .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L2A"]
		elseif (ClassicAuraDurationsDB.portraitIcon) then
			textCILC = textCILC .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L2B"]
		else
			textCILC = textCILC .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L2C"]
		end
		textCILC = textCILC .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L3"] .. "\n" ..
			L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L4"] .. textCILC_Opt1 .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L5"] .. "\n" ..
			L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L6"] .. textCILC_Opt1 .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L7"] .. "\n" ..
			L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L8"] .. textCILC_Opt1 .. L["LOSECONTROL_CHECKINCOMPATIBILITIES_MSG_L9"]
		StaticPopupDialogs["LOSECONTROL_CHECK_INCOMPATIBILITIES"] = {
			text = textCILC,
			button1 = L["Yes (recomended)"],
			button2 = L["No"],
			OnAccept = function()
				ClassicAuraDurationsDB.portraitIcon = false
				ClassicAuraDurationsDB.playerPortraitIcon = false
				LoseControlDB.lastIncompatibilitiesAskedTimestamp = time()
			end,
			OnCancel = function()
				LoseControlDB.lastIncompatibilitiesAskedTimestamp = time()
			end,	
			timeout = 0,
			whileDead = true,
			hideOnEscape = false,
			preferredIndex = STATICPOPUP_NUMDIALOGS or 3,	-- avoid some UI taint
		}
		StaticPopup_Show("LOSECONTROL_CHECK_INCOMPATIBILITIES")
	end
end

-- Function to update the Blizzard anchors of the raid icons with their corresponding CompactRaidFrame
local function UpdateRaidIconsAnchorCompactRaidFrame(compactRaidFrame, key, value)
	if compactRaidFrame:IsForbidden() then return end
	local name = compactRaidFrame:GetName()
	if not name or not name:match("^Compact") then return end
	if (key == nil or key == "unit") then
		local anchorUnitId = value or compactRaidFrame.displayedUnit or compactRaidFrame.unit
		if (anchorUnitId ~= nil and strfind(anchorUnitId, "raid")) then
			local icon = LCframes[anchorUnitId]
			if (icon ~= nil) then
				local frame = icon.frame or LoseControlDB.frames[anchorUnitId]
				if (frame ~= nil) then
					anchors.BlizzardRaidFrames[anchorUnitId] = name
					if (frame.anchor == "BlizzardRaidFrames") then
						icon.anchor = compactRaidFrame
						icon.parent:SetParent(icon.anchor:GetParent())
						icon.defaultFrameStrata = icon:GetFrameStrata()
						icon:ClearAllPoints()
						icon:GetParent():ClearAllPoints()
						icon:SetPoint(
							frame.point or "CENTER",
							icon.anchor,
							frame.relativePoint or "CENTER",
							frame.x or 0,
							frame.y or 0
						)
						icon:GetParent():SetPoint(
							frame.point or "CENTER",
							icon.anchor,
							frame.relativePoint or "CENTER",
							frame.x or 0,
							frame.y or 0
						)
					end
					if (icon.frame and icon.frame.anchor == "BlizzardRaidFrames") then
						icon:UNIT_AURA(icon.unitId, -80)
					end
				end
			end
		end
	end
end

-- Function to hook the raid frame and anchors the LoseControl raid frames to their corresponding blizzard raid frame
local function HookCompactRaidFrame(compactRaidFrame)
	if (LCHookedCompactRaidFrames[compactRaidFrame] == nil) then
		if compactRaidFrame:IsForbidden() then
			LCHookedCompactRaidFrames[compactRaidFrame] = false
		else
			compactRaidFrame:HookScript("OnAttributeChanged", function(self, key, value)
				if self:IsForbidden() then return end
				UpdateRaidIconsAnchorCompactRaidFrame(self, key, value)
			end)
			compactRaidFrame:HookScript("OnShow", function(self)
				if self:IsForbidden() then return end
				UpdateRaidIconsAnchorCompactRaidFrame(self)
			end)
			compactRaidFrame:HookScript("OnHide", function(self)
				if self:IsForbidden() then return end
				UpdateRaidIconsAnchorCompactRaidFrame(self)
			end)
			LCHookedCompactRaidFrames[compactRaidFrame] = true
		end
	end
end

-- Function to hook the raid frames and anchors the LoseControl raid frames to their corresponding blizzard raid frame
local function MainHookCompactRaidFrames()
	if not LoseControlCompactRaidFramesHooked then
		local someRaidEnabledAndBlizzAnchored = false
		for i = 1, 40 do
			if LoseControlDB.frames["raid"..i].enabled and LoseControlDB.frames["raid"..i].anchor == "BlizzardRaidFrames" then
				someRaidEnabledAndBlizzAnchored = true
				break
			end
		end
		if someRaidEnabledAndBlizzAnchored then
			for i = 1, 40 do
				local compactRaidFrame = _G["CompactRaidFrame"..i]
				if (compactRaidFrame ~= nil) then
					HookCompactRaidFrame(compactRaidFrame)
					UpdateRaidIconsAnchorCompactRaidFrame(compactRaidFrame)
				end
			end
			for i = 1, 8 do
				for j = 1, 5 do
					local compactRaidFrame = _G["CompactRaidGroup"..i.."Member"..j]
					if (compactRaidFrame ~= nil) then
						HookCompactRaidFrame(compactRaidFrame)
						UpdateRaidIconsAnchorCompactRaidFrame(compactRaidFrame)
					end
				end
			end
			hooksecurefunc("CompactUnitFrame_OnLoad", function(self)
				HookCompactRaidFrame(self)
				UpdateRaidIconsAnchorCompactRaidFrame(self)
			end)
			LoseControlCompactRaidFramesHooked = true
		end
	end
end

-- Handle default settings
function LoseControl:ADDON_LOADED(arg1)
	if arg1 == addonName then
		if (_G.LoseControlDB == nil) or (_G.LoseControlDB.version == nil) then
			_G.LoseControlDB = CopyTable(DBdefaults)
			print(L["LoseControl reset."])
		end
		if _G.LoseControlDB.version < DBdefaults.version or _G.LoseControlDB.version >= 2.0 then
			for j, u in pairs(DBdefaults) do
				if (_G.LoseControlDB[j] == nil) then
					_G.LoseControlDB[j] = u
				elseif (type(u) == "table") then
					for k, v in pairs(u) do
						if (_G.LoseControlDB[j][k] == nil) then
							_G.LoseControlDB[j][k] = v
						elseif (type(v) == "table") then
							for l, w in pairs(v) do
								if (_G.LoseControlDB[j][k][l] == nil) then
									_G.LoseControlDB[j][k][l] = w
								elseif (type(w) == "table") then
									for m, x in pairs(w) do
										if (_G.LoseControlDB[j][k][l][m] == nil) then
											_G.LoseControlDB[j][k][l][m] = x
										elseif (type(x) == "table") then
											for n, y in pairs(x) do
												if (_G.LoseControlDB[j][k][l][m][n] == nil) then
													_G.LoseControlDB[j][k][l][m][n] = y
												elseif (type(y) == "table") then
													for o, z in pairs(y) do
														if (_G.LoseControlDB[j][k][l][m][n][o] == nil) then
															_G.LoseControlDB[j][k][l][m][n][o] = z
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
			_G.LoseControlDB.version = DBdefaults.version
		end
		LoseControlDB = _G.LoseControlDB
		self.VERSION = "1.11"
		self.noCooldownCount = LoseControlDB.noCooldownCount
		self.noBlizzardCooldownCount = LoseControlDB.noBlizzardCooldownCount
		self.noGetExtraAuraDurationInformation = LoseControlDB.noGetExtraAuraDurationInformation
		self.noGetEnemiesBuffsInformation = LoseControlDB.noGetEnemiesBuffsInformation
		if (LoseControlDB.duplicatePlayerPortrait and LoseControlDB.frames.player.anchor == "Blizzard") then
			LoseControlDB.duplicatePlayerPortrait = false
		end
		LoseControlDB.frames.player2.enabled = LoseControlDB.duplicatePlayerPortrait and LoseControlDB.frames.player.enabled
		LoseControlDB.showPartyplayerIcon = LoseControlDB.frames.partyplayer.enabled
		if LoseControlDB.noCooldownCount then
			self:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
			for _, v in pairs(LCframes) do
				v:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
			end
			LCframeplayer2:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
		else
			self:SetHideCountdownNumbers(true)
			for _, v in pairs(LCframes) do
				v:SetHideCountdownNumbers(true)
			end
			LCframeplayer2:SetHideCountdownNumbers(true)
		end
		self:UpdateSpellIdsTableWithCustomSpellIds()
		self:UpdateGetEnemiesBuffInformationOptionState()
		self:UpdateInterruptsSpellIdByNameTable()
		playerGUID = UnitGUID("player")
		_, _, playerClass = UnitClass("player")
		coldSnapSpellName = GetSpellInfo(12472) or "-1"
		if ((not LoseControlDB.lastIncompatibilitiesAskedTimestamp) or (LoseControlDB.lastIncompatibilitiesAskedTimestamp <= 0) or (time() - LoseControlDB.lastIncompatibilitiesAskedTimestamp > 10368000)) then	-- check again after 4 months
			C_Timer.After(8, function()	-- delay checking to make sure all variables of the other addons are loaded
				LoseControl_CheckIncompatibilities(self.VERSION)
			end)
		end
		MainHookCompactRaidFrames()
		if Masque then
			for _, v in pairs(LCframes) do
				v.MasqueGroup = Masque:Group(addonName, (v.fakeUnitId or v.unitId))
				if (LoseControlDB.frames[(v.fakeUnitId or v.unitId)].anchor ~= "Blizzard") then
					v.MasqueGroup:AddButton(v:GetParent(), {
						FloatingBG = false,
						Icon = v.texture,
						Cooldown = v,
						Flash = _G[v:GetParent():GetName().."Flash"],
						Pushed = v:GetParent():GetPushedTexture(),
						Normal = v:GetParent():GetNormalTexture(),
						Disabled = v:GetParent():GetDisabledTexture(),
						Checked = false,
						Border = _G[v:GetParent():GetName().."Border"],
						AutoCastable = false,
						Highlight = v:GetParent():GetHighlightTexture(),
						Hotkey = _G[v:GetParent():GetName().."HotKey"],
						Count = _G[v:GetParent():GetName().."Count"],
						Name = _G[v:GetParent():GetName().."Name"],
						Duration = false,
						Shine = _G[v:GetParent():GetName().."Shine"],
					}, "Button", true)
					if v.MasqueGroup then
						v.MasqueGroup:ReSkin()
					end
				end
			end
			LCframeplayer2.MasqueGroup = Masque:Group(addonName, LCframeplayer2.fakeUnitId)
			if (LoseControlDB.frames[LCframeplayer2.fakeUnitId].anchor ~= "Blizzard") then
				LCframeplayer2.MasqueGroup:AddButton(LCframeplayer2:GetParent(), {
					FloatingBG = false,
					Icon = LCframeplayer2.texture,
					Cooldown = LCframeplayer2,
					Flash = _G[LCframeplayer2:GetParent():GetName().."Flash"],
					Pushed = LCframeplayer2:GetParent():GetPushedTexture(),
					Normal = LCframeplayer2:GetParent():GetNormalTexture(),
					Disabled = LCframeplayer2:GetParent():GetDisabledTexture(),
					Checked = false,
					Border = _G[LCframeplayer2:GetParent():GetName().."Border"],
					AutoCastable = false,
					Highlight = LCframeplayer2:GetParent():GetHighlightTexture(),
					Hotkey = _G[LCframeplayer2:GetParent():GetName().."HotKey"],
					Count = _G[LCframeplayer2:GetParent():GetName().."Count"],
					Name = _G[LCframeplayer2:GetParent():GetName().."Name"],
					Duration = false,
					Shine = _G[LCframeplayer2:GetParent():GetName().."Shine"],
				}, "Button", true)
				if LCframeplayer2.MasqueGroup then
					LCframeplayer2.MasqueGroup:ReSkin()
				end
			end
		end
	end
end

LoseControl:RegisterEvent("ADDON_LOADED")

function LoseControl:CheckAnchor(forceCheck)
	if (strfind((self.fakeUnitId or self.unitId), "raid")) then return end
	if ((self.frame.anchor ~= "None") and (forceCheck or self.anchor == UIParent or self.anchor == nil)) then
		local anchorObj = anchors[self.frame.anchor]
		if anchorObj ~= nil then
			local updateFrame = false
			local newAnchor = _G[anchorObj[self.unitId]]
			if (newAnchor and self.anchor ~= newAnchor) then
				self.anchor = newAnchor
				updateFrame = true
			end
			if (type(anchorObj[self.unitId])=="string") then
				newAnchor = _GF(anchorObj[self.unitId])
				if (newAnchor and self.anchor ~= newAnchor) then
					self.anchor = newAnchor
					updateFrame = true
				end
			elseif (type(anchorObj[self.unitId])=="table") then
				newAnchor = anchorObj[self.unitId]
				if (newAnchor and self.anchor ~= newAnchor) then
					self.anchor = newAnchor
					updateFrame = true
				end
			end
			if (newAnchor ~= nil and updateFrame) then
				local frame = self.frame
				self.parent:SetParent(self.anchor:GetParent())
				self.defaultFrameStrata = self:GetFrameStrata()
				self:ClearAllPoints()
				self:GetParent():ClearAllPoints()
				self:SetPoint(
					frame.point or "CENTER",
					self.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
				self:GetParent():SetPoint(
					frame.point or "CENTER",
					self.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
				local PositionXEditBox, PositionYEditBox, FrameLevelEditBox
				if strfind(self.unitId, "party") then
					if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
						FrameLevelEditBox = _G['LoseControlOptionsPanelpartyFrameLevelEditBox']
					end
				elseif strfind(self.unitId, "raid") then
					if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
						FrameLevelEditBox = _G['LoseControlOptionsPanelraidFrameLevelEditBox']
					end
				elseif self.fakeUnitId ~= "player2" then
					PositionXEditBox = _G['LoseControlOptionsPanel'..self.unitId..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..self.unitId..'PositionYEditBox']
					FrameLevelEditBox = _G['LoseControlOptionsPanel'..self.unitId..'FrameLevelEditBox']
				end
				if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
					PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
					PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
					FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
					if (frame.anchor ~= "Blizzard") then
						if frame.enabled then
							PositionXEditBox:Enable()
							PositionYEditBox:Enable()
							FrameLevelEditBox:Enable()
						end
					else
						PositionXEditBox:Disable()
						PositionYEditBox:Disable()
						FrameLevelEditBox:Disable()
					end
					PositionXEditBox:SetCursorPosition(0)
					PositionYEditBox:SetCursorPosition(0)
					FrameLevelEditBox:SetCursorPosition(0)
				end
				if (frame.frameStrata ~= nil) then
					self:GetParent():SetFrameStrata(frame.frameStrata)
					self:SetFrameStrata(frame.frameStrata)
				end
				local frameLevel = (self.anchor:GetParent() and (self.anchor:GetParent() and (self.anchor:GetParent() and self.anchor:GetParent():GetFrameLevel() or self.anchor:GetFrameLevel()) or self.anchor:GetFrameLevel()) or self.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
				if frameLevel < 0 then frameLevel = 0 end
				self:GetParent():SetFrameLevel(frameLevel)
				self:SetFrameLevel(frameLevel)
			end
		end
	end
end

-- Initialize a frame's position and register for events
function LoseControl:PLAYER_ENTERING_WORLD()
	local unitId = self.unitId
	self.frame = LoseControlDB.frames[self.fakeUnitId or unitId] -- store a local reference to the frame's settings
	local frame = self.frame
	local enabled = self:GetEnabled()
	C_Timer.After(8, function()	-- delay checking to make sure all variables of the other addons are loaded
		self:CheckAnchor(true)
	end)
	self.unitGUID = UnitGUID(unitId)
	self.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][unitId])=="string") and _GF(anchors[frame.anchor][unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][unitId])=="table") and anchors[frame.anchor][unitId] or UIParent))
	self.parent:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
	self.defaultFrameStrata = self:GetFrameStrata()
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:GetParent():ClearAllPoints()
	self:SetWidth(frame.size)
	self:SetHeight(frame.size)
	self:GetParent():SetWidth(frame.size)
	self:GetParent():SetHeight(frame.size)
	self:RegisterUnitEvents(enabled)
	
	self:SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	self:GetParent():SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	local PositionXEditBox, PositionYEditBox, FrameLevelEditBox
	if strfind((self.fakeUnitId or unitId), "party") then
		if ((self.fakeUnitId or unitId) == ((_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'] ~= nil) and UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown']) or "party1")) then
			PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
			FrameLevelEditBox = _G['LoseControlOptionsPanelpartyFrameLevelEditBox']
		end
	elseif strfind((self.fakeUnitId or unitId), "raid") then
		if ((self.fakeUnitId or unitId) == ((_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'] ~= nil) and UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown']) or "raid1")) then
			PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
			FrameLevelEditBox = _G['LoseControlOptionsPanelraidFrameLevelEditBox']
		end
	elseif self.fakeUnitId ~= "player2" then
		PositionXEditBox = _G['LoseControlOptionsPanel'..(self.fakeUnitId or unitId)..'PositionXEditBox']
		PositionYEditBox = _G['LoseControlOptionsPanel'..(self.fakeUnitId or unitId)..'PositionYEditBox']
		FrameLevelEditBox = _G['LoseControlOptionsPanel'..(self.fakeUnitId or unitId)..'FrameLevelEditBox']
	end
	if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
		PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
		PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
		FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
		PositionXEditBox:SetCursorPosition(0)
		PositionYEditBox:SetCursorPosition(0)
		FrameLevelEditBox:SetCursorPosition(0)
	end
	if (frame.frameStrata ~= nil) then
		self:GetParent():SetFrameStrata(frame.frameStrata)
		self:SetFrameStrata(frame.frameStrata)
	end
	local frameLevel = (self.anchor:GetParent() and (self.anchor:GetParent() and (self.anchor:GetParent() and self.anchor:GetParent():GetFrameLevel() or self.anchor:GetFrameLevel()) or self.anchor:GetFrameLevel()) or self.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
	if frameLevel < 0 then frameLevel = 0 end
	self:GetParent():SetFrameLevel(frameLevel)
	self:SetFrameLevel(frameLevel)
	if self.MasqueGroup then
		self.MasqueGroup:ReSkin()
	end
	
	SetInterruptIconsSize(self, frame.size)
	
	self.iconInterruptBackground:SetAlpha(frame.interruptBackgroundAlpha)
	self.iconInterruptBackground:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
	for _, v in pairs(self.iconInterruptList) do
		v:SetAlpha(frame.interruptMiniIconsAlpha)
	end
	
	if frame.anchor == "Blizzard" then
		if self.textureicon then
			SetPortraitToTexture(self.texture, self.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
		end
		self:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
		self:SetSwipeColor(0, 0, 0, 0.6)
		self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
	else
		if self.textureicon then
			self.texture:SetTexture(self.textureicon)
		end
		self:SetSwipeColor(0, 0, 0, 0.8)
		self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
	end
	
	--self:SetAlpha(frame.alpha) -- doesn't seem to work; must manually set alpha after the cooldown is displayed, otherwise it doesn't apply.
	self:Hide()
	self:GetParent():Hide()
	
	if enabled and not self.unlockMode then
		self.maxExpirationTime = 0
		self:UNIT_AURA(self.unitId, 0)
	end
end

function LoseControl:GROUP_ROSTER_UPDATE()
	local unitId = self.unitId
	local frame = self.frame
	if (frame == nil) or (unitId == nil) or not(strfind((self.fakeUnitId or unitId), "party") or (strfind((self.fakeUnitId or unitId), "raid"))) then
		return
	end
	local enabled = self:GetEnabled()
	self:RegisterUnitEvents(enabled)
	self.unitGUID = UnitGUID(unitId)
	if (self.fakeUnitId ~= "partyplayer") then
		self:CheckAnchor(frame.anchor ~= "Blizzard")
	end
	if enabled and not self.unlockMode then
		self.maxExpirationTime = 0
		self:UNIT_AURA(unitId, 0)
	end
end

function LoseControl:GROUP_JOINED()
	self:GROUP_ROSTER_UPDATE()
end

function LoseControl:GROUP_LEFT()
	self:GROUP_ROSTER_UPDATE()
end

local function UpdateUnitAuraByUnitGUID(unitGUID, typeUpdate)
	for k, v in pairs(LCframes) do
		local enabled = v:GetEnabled()
		if enabled and not v.unlockMode then
			if v.unitGUID == unitGUID then
				v:UNIT_AURA(v.unitId, typeUpdate)
				if (k == "player") and LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, typeUpdate)
				end
			end
		end
	end
end

-- This event check interrupts and targettarget unit aura trigger
function LoseControl:COMBAT_LOG_EVENT_UNFILTERED()
	if self.unitId == "target" then
		-- Check Interrupts
		local _, event, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _, spellId, spellName, _, _, _, spellSchool = CombatLogGetCurrentEventInfo()
		if (destGUID ~= nil and destGUID ~= "") then
			if (event == "SPELL_INTERRUPT") then
				if (spellId == 0) then
					local spellTable = interruptsSpellIdByName[spellName]
					if (spellTable) then
						if ((sourceFlags == nil) or strfind(sourceGUID, "^Player-") or ((bit_band(sourceFlags, COMBATLOG_OBJECT_CONTROL_NPC) <= 0) and not(strfind(sourceGUID, "^Creature-")))) then
							for _, v in ipairs(spellTable) do
								if (not v[4]) then
									spellId = v[1]
									break
								end
							end
							if (spellId == 0) then
								spellId = spellTable[1][1]
							end
							-- exception for Iron Knuckles Pummel (spellId=13491), Warrior Pummel has higher priority (Warrior Pummel spellId=6554)
							if ((spellId == 6554) and (playerGUID ~= nil) and (sourceGUID ~= nil)) then
								if (playerGUID == sourceGUID) then
									if ((playerClass ~= nil) and (playerClass > 1)) then
										local itemIdMainHand = GetInventoryItemID("player", 16)
										local itemIdOffHand = GetInventoryItemID("player", 17)
										if ((itemIdMainHand == 2942) or (itemIdOffHand == 2942)) then
											spellId = 13491
										end
									end
								elseif strfind(sourceGUID, "^Player-") then
									local _, engClass = GetPlayerInfoByGUID(sourceGUID)
									if ((engClass ~= nil) and (engClass ~= "WARRIOR")) then
										spellId = 13491
									end
								end
							end
						else
							local needZoneFilter = { false, false }
							for _, v in ipairs(spellTable) do
								if (v[4] and v[5]) then
									if (v[5] < 10000) then
										needZoneFilter[1] = true
									else
										needZoneFilter[2] = true
									end
								end
							end
							if (needZoneFilter[1] or needZoneFilter[2]) then
								local mapID
								local instanceMapId
								if (needZoneFilter[1]) then
									mapId = GetBestMapForUnit("player")
								end
								if (needZoneFilter[2]) then
									_, _, _, _, _, _, _, instanceMapId = GetInstanceInfo()
								end
								for _, v in ipairs(spellTable) do
									if (v[4] and v[5]) then
										if (v[5] >= 10000) then
											if ((instanceMapId ~= nil) and ((v[5]-10000) == instanceMapId)) then
												spellId = v[1]
												break
											end
										else
											if ((mapId ~= nil) and (v[5] == mapId)) then
												spellId = v[1]
												break
											end
										end
									end
								end
								if (spellId == 0) then
									for _, v in ipairs(spellTable) do
										if (v[4]) then
											spellId = v[1]
											break
										end
									end
								end
							else
								for _, v in ipairs(spellTable) do
									if (v[4]) then
										spellId = v[1]
										break
									end
								end
							end
							if (spellId == 0) then
								spellId = spellTable[1][1]
							end
						end
					end
				end
				if (spellId > 0) then
					local infoInterrupt = interruptsIds[spellId]
					if (infoInterrupt ~= nil) then
						local duration = infoInterrupt[1]
						local expirationTime = GetTime() + duration
						if debug then print("interrupt", ")", destGUID, "|", spellName, "|", duration, "|", expirationTime, "|", spellId) end
						local priority = LoseControlDB.priority.Interrupt
						local _, _, icon = GetSpellInfo(spellId)
						if (InterruptAuras[destGUID] == nil) then
							InterruptAuras[destGUID] = {}
						end
						tblinsert(InterruptAuras[destGUID], { ["spellId"] = spellId, ["duration"] = duration, ["expirationTime"] = expirationTime, ["priority"] = priority, ["icon"] = (icon or 134400), ["spellSchool"] = spellSchool })
						UpdateUnitAuraByUnitGUID(destGUID, -20)
					end
				end
			elseif (((event == "UNIT_DIED") or (event == "UNIT_DESTROYED") or (event == "UNIT_DISSIPATES")) and (select(2, GetPlayerInfoByGUID(destGUID)) ~= "HUNTER")) then
				if (InterruptAuras[destGUID] ~= nil) then
					InterruptAuras[destGUID] = nil
					UpdateUnitAuraByUnitGUID(destGUID, -21)
				end
			end
		end
		-- Check Cold Snap use
		if ((sourceGUID ~= nil) and (event == "SPELL_CAST_SUCCESS") and ((spellId == 12472) or (spellName == coldSnapSpellName))) then
			local needUpdateUnitAura = false
			if (InterruptAuras[sourceGUID] ~= nil) then
				for k, v in pairs(InterruptAuras[sourceGUID]) do
					if (bit_band(v.spellSchool, 16) >= 16) then
						needUpdateUnitAura = true
						if (v.spellSchool > 16) then
							InterruptAuras[sourceGUID][k].spellSchool = InterruptAuras[sourceGUID][k].spellSchool - 16
						else
							InterruptAuras[sourceGUID][k] = nil
						end
					end
				end
				if (next(InterruptAuras[sourceGUID]) == nil) then
					InterruptAuras[sourceGUID] = nil
				end
			end
			if needUpdateUnitAura then
				UpdateUnitAuraByUnitGUID(sourceGUID, -22)
			end
		end
	elseif self.unitId == "targettarget" and self.unitGUID ~= nil and (not(LoseControlDB.disablePlayerTargetTarget) or (self.unitGUID ~= playerGUID)) and (not(LoseControlDB.disableTargetTargetTarget) or (self.unitGUID ~= LCframes.target.unitGUID)) then
		-- Manage targettarget UNIT_AURA trigger
		local _, event, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
		if (destGUID ~= nil and destGUID == self.unitGUID) then
			if (event == "SPELL_AURA_APPLIED") or (event == "SPELL_PERIODIC_AURA_APPLIED") or
			 (event == "SPELL_AURA_REMOVED") or (event == "SPELL_PERIODIC_AURA_REMOVED") or
			 (event == "SPELL_AURA_APPLIED_DOSE") or (event == "SPELL_PERIODIC_AURA_APPLIED_DOSE") or
			 (event == "SPELL_AURA_REMOVED_DOSE") or (event == "SPELL_PERIODIC_AURA_REMOVED_DOSE") or
			 (event == "SPELL_AURA_REFRESH") or (event == "SPELL_PERIODIC_AURA_REFRESH") or
			 (event == "SPELL_AURA_BROKEN") or (event == "SPELL_PERIODIC_AURA_BROKEN") or
			 (event == "SPELL_AURA_BROKEN_SPELL") or (event == "SPELL_PERIODIC_AURA_BROKEN_SPELL") or
			 (event == "UNIT_DIED") or (event == "UNIT_DESTROYED") or (event == "UNIT_DISSIPATES") then
				local timeCombatLogAuraEvent = GetTime()
				C_Timer.After(0.01, function()	-- execute in some close next frame to accurate use of UnitAura function
					if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent ~= timeCombatLogAuraEvent)) then
						self:UNIT_AURA(self.unitId, 3)
					end
				end)
			end
		end
	end
end

-- This is the main event. Check for (de)buffs and update the frame icon and cooldown.
function LoseControl:UNIT_AURA(unitId, typeUpdate) -- fired when a (de)buff is gained/lost
	if (((typeUpdate ~= nil and typeUpdate > 0) or (typeUpdate == nil and self.unitId == "targettarget")) and (self.lastTimeUnitAuraEvent == GetTime())) then return end
	if (self.unitId == "targettarget" and (not UnitIsUnit(unitId, self.unitId))) then return end
	local priority = LoseControlDB.priority
	local maxPriority = 1
	local maxExpirationTime = 0
	local maxPriorityIsInterrupt = false
	local Icon, Duration
	local forceEventUnitAuraAtEnd = false
	self.lastTimeUnitAuraEvent = GetTime()

	if ((self.anchor ~= nil and self.anchor:IsVisible() and (self.anchor ~= UIParent or self.frame.anchor == "None")) or (self.frame.anchor ~= "None" and self.frame.anchor ~= "Blizzard" and self.frame.anchor ~= "BlizzardRaidFrames" and self.anchor ~= UIParent)) and UnitExists(self.unitId) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetPlayerTargetTarget) or not(UnitIsUnit("player", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetTarget) or not(UnitIsUnit("targettarget", "player")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetTargetTarget) or not(UnitIsUnit("targettarget", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetDeadTargetTarget) or (UnitHealth("target") > 0))) then
		local reactionToPlayer = ((self.unitId == "target" or self.unitId == "targettarget") and UnitCanAttack("player", unitId)) and "enemy" or "friendly"
		-- Check debuffs
		for i = 1, 120 do
			local localForceEventUnitAuraAtEnd = false
			local name, icon, _, _, duration, expirationTime, unitCaster, _, _, spellId = UnitAura(unitId, i, "HARMFUL")
			if not spellId then break end -- no more debuffs, terminate the loop
			
			if duration == 0 and expirationTime == 0 then
				if not LoseControlDB.noGetExtraAuraDurationInformation then
					local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unitId, spellId, unitCaster, name)
					if durationNew then
						duration = durationNew
						expirationTime = expirationTimeNew
						if (expirationTime < GetTime()) then
							expirationTime = 0
						end
					end
					if duration == 0 and expirationTime == 0 then
						expirationTime = GetTime() + 1 -- normal expirationTime = 0
					elseif expirationTime > 0 then
						localForceEventUnitAuraAtEnd = true
					end
				else
					expirationTime = GetTime() + 1 -- normal expirationTime = 0
				end
			elseif expirationTime > 0 then
				localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
			end
			if debug then print(unitId, "debuff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
			
			local spellCategory = spellIds[spellId]
			local Priority = priority[spellCategory]
			if self.frame.categoriesEnabled.debuff[reactionToPlayer] and self.frame.categoriesEnabled.debuff[reactionToPlayer][spellCategory] then
				if Priority then
					if Priority == maxPriority and expirationTime > maxExpirationTime then
						maxExpirationTime = expirationTime
						Duration = duration
						Icon = icon
						forceEventUnitAuraAtEnd = localForceEventUnitAuraAtEnd
					elseif Priority > maxPriority then
						maxPriority = Priority
						maxExpirationTime = expirationTime
						Duration = duration
						Icon = icon
						forceEventUnitAuraAtEnd = localForceEventUnitAuraAtEnd
					end
				end
			end
		end

		-- Check buffs
		for i = 1, 120 do
			local localForceEventUnitAuraAtEnd = false
			local newCategory
			local name, icon, duration, expirationTime, spellId
			if LoseControlDB.noGetEnemiesBuffsInformation then
				name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i, "HELPFUL")
				if not spellId then break end -- no more buffs, terminate the loop
				
				if duration == 0 and expirationTime == 0 then
					if not LoseControlDB.noGetExtraAuraDurationInformation then
						local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unitId, spellId, unitCaster, name)
						if durationNew then
							duration = durationNew
							expirationTime = expirationTimeNew
							if (expirationTime < GetTime()) then
								expirationTime = 0
							end
						end
						if duration == 0 and expirationTime == 0 then
							expirationTime = GetTime() + 1 -- normal expirationTime = 0
						elseif expirationTime > 0 then
							localForceEventUnitAuraAtEnd = true
						end
					else
						expirationTime = GetTime() + 1 -- normal expirationTime = 0
					end
				elseif expirationTime > 0 then
					localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
				end
				if debug then print(unitId, "buff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
				
			else
				name, icon, _, _, duration, expirationTime, _, _, _, spellId = LibClassicDurations:UnitAura(unitId, i, "HELPFUL")
				if not spellId then break end -- no more buffs, terminate the loop
				
				if debug then print(unitId, "buff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
				
				if duration == 0 and expirationTime == 0 then
					expirationTime = GetTime() + 1 -- normal expirationTime = 0
				elseif expirationTime > 0 then
					localForceEventUnitAuraAtEnd = true
				end
			end
			
			-- exceptions
			if (spellId == 605) or (spellId == 10911) or (spellId == 10912) or (spellId == 24020) then	-- Mind Control and Axe Flurry
				spellId = 1
			elseif (spellId == 19574 and (self.unitId == "pet" or (playerClass ~= 1 and playerClass ~= 2 and playerClass ~= 5 and playerClass ~= 9))) then	-- Bestial Wrath
				newCategory = "Other"
			end
			
			local spellCategory = newCategory or spellIds[spellId]
			local Priority = priority[spellCategory]
			if self.frame.categoriesEnabled.buff[reactionToPlayer] and self.frame.categoriesEnabled.buff[reactionToPlayer][spellCategory] then
				if Priority then
					if Priority == maxPriority and expirationTime > maxExpirationTime then
						maxExpirationTime = expirationTime
						Duration = duration
						Icon = icon
						forceEventUnitAuraAtEnd = localForceEventUnitAuraAtEnd
					elseif Priority > maxPriority then
						maxPriority = Priority
						maxExpirationTime = expirationTime
						Duration = duration
						Icon = icon
						forceEventUnitAuraAtEnd = localForceEventUnitAuraAtEnd
					end
				end
			end
		end
		
		-- Check interrupts
		if ((self.unitGUID ~= nil) and (priority.Interrupt > 0) and self.frame.categoriesEnabled.interrupt[reactionToPlayer] and (UnitIsPlayer(self.unitId) or (((self.unitId ~= "target") or (LoseControlDB.showNPCInterruptsTarget)) and ((self.unitId ~= "targettarget") or (LoseControlDB.showNPCInterruptsTargetTarget))))) then
			local spellSchoolInteruptsTable = {
				[1] = {false, 0},	-- Physical
				[2] = {false, 0},	-- Holy
				[4] = {false, 0},	-- Fire
				[8] = {false, 0},	-- Nature
				[16] = {false, 0},	-- Frost
				[32] = {false, 0},	-- Shadow
				[64] = {false, 0}	-- Arcane
			}
			if (InterruptAuras[self.unitGUID] ~= nil) then
				for k, v in pairs(InterruptAuras[self.unitGUID]) do
					local Priority = v.priority
					local expirationTime = v.expirationTime
					local duration = v.duration
					local icon = v.icon
					local spellSchool = v.spellSchool
					if (expirationTime < GetTime()) then
						InterruptAuras[self.unitGUID][k] = nil
						if (next(InterruptAuras[self.unitGUID]) == nil) then
							InterruptAuras[self.unitGUID] = nil
						end
					else
						if Priority then
							for schoolIntId, _ in pairs(spellSchoolInteruptsTable) do
								if (bit_band(spellSchool, schoolIntId) >= schoolIntId) then
									spellSchoolInteruptsTable[schoolIntId][1] = true
									if expirationTime > spellSchoolInteruptsTable[schoolIntId][2] then
										spellSchoolInteruptsTable[schoolIntId][2] = expirationTime
									end
								end
							end
							local nextTimerUpdate = expirationTime - GetTime() + 0.05
							if nextTimerUpdate < 0.05 then
								nextTimerUpdate = 0.05
							end
							C_Timer.After(nextTimerUpdate, function()
								if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < (GetTime() - 0.04))) then
									self:UNIT_AURA(self.unitId, 20)
								end
								for e, f in pairs(InterruptAuras) do
									for g, h in pairs(f) do
										if (h.expirationTime < GetTime()) then
											InterruptAuras[e][g] = nil
										end
									end
									if (next(InterruptAuras[e]) == nil) then
										InterruptAuras[e] = nil
									end
								end
							end)
							if Priority == maxPriority and expirationTime > maxExpirationTime then
								maxExpirationTime = expirationTime
								Duration = duration
								Icon = icon
								maxPriorityIsInterrupt = true
								forceEventUnitAuraAtEnd = false
							elseif Priority > maxPriority then
								maxPriority = Priority
								maxExpirationTime = expirationTime
								Duration = duration
								Icon = icon
								maxPriorityIsInterrupt = true
								forceEventUnitAuraAtEnd = false
							end
						end
					end
				end
			end
			for schoolIntId, schoolIntFrame in pairs(self.iconInterruptList) do
				if spellSchoolInteruptsTable[schoolIntId][1] then
					if (not schoolIntFrame:IsShown()) then
						schoolIntFrame:Show()
					end
					local orderInt = 1
					for schoolInt2Id, schoolInt2Info in pairs(spellSchoolInteruptsTable) do
						if ((schoolInt2Info[1]) and ((spellSchoolInteruptsTable[schoolIntId][2] < schoolInt2Info[2]) or ((spellSchoolInteruptsTable[schoolIntId][2] == schoolInt2Info[2]) and (schoolIntId > schoolInt2Id)))) then
							orderInt = orderInt + 1
						end
					end
					schoolIntFrame:SetPoint("BOTTOMRIGHT", self.interruptIconOrderPos[orderInt][1], self.interruptIconOrderPos[orderInt][2])
					schoolIntFrame.interruptIconOrder = orderInt
				elseif schoolIntFrame:IsShown() then
					schoolIntFrame.interruptIconOrder = nil
					schoolIntFrame:Hide()
				end
			end
		end
	end
	
	if maxExpirationTime == 0 then -- no (de)buffs found
		self.maxExpirationTime = 0
		if self.anchor ~= UIParent and self.drawlayer then
			self.anchor:SetDrawLayer(self.drawlayer) -- restore the original draw layer
		end
		if self.iconInterruptBackground:IsShown() then
			self.iconInterruptBackground:Hide()
		end
		self:Hide()
		self:GetParent():Hide()
	elseif maxExpirationTime ~= self.maxExpirationTime then -- this is a different (de)buff, so initialize the cooldown
		self.maxExpirationTime = maxExpirationTime
		if self.anchor ~= UIParent then
			local frameLevel = (self.anchor:GetParent() and (self.anchor:GetParent() and (self.anchor:GetParent() and self.anchor:GetParent():GetFrameLevel() or self.anchor:GetFrameLevel()) or self.anchor:GetFrameLevel()) or self.anchor:GetFrameLevel())+((self.frame.anchor ~= "Blizzard") and (12 + self.frame.frameLevel) or 0) -- must be dynamic, frame level changes all the time
			if frameLevel < 0 then frameLevel = 0 end
			self:GetParent():SetFrameLevel(frameLevel)
			self:SetFrameLevel(frameLevel)
			if not self.drawlayer and self.anchor.GetDrawLayer then
				self.drawlayer = self.anchor:GetDrawLayer() -- back up the current draw layer
			end
			if self.drawlayer and self.anchor.SetDrawLayer then
				self.anchor:SetDrawLayer("BACKGROUND") -- Temporarily put the portrait texture below the debuff texture. This is the only reliable method I've found for keeping the debuff texture visible with the cooldown spiral on top of it.
			end
		end
		if maxPriorityIsInterrupt then
			if self.frame.anchor == "Blizzard" then
				self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
			else
				self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
			end
			if (not self.iconInterruptBackground:IsShown()) then
				self.iconInterruptBackground:Show()
			end
		else
			if self.iconInterruptBackground:IsShown() then
				self.iconInterruptBackground:Hide()
			end
		end
		self.textureicon = Icon
		if self.frame.anchor == "Blizzard" then
			SetPortraitToTexture(self.texture, Icon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
			self:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
			self:SetSwipeColor(0, 0, 0, 0.6)	-- Adjust the alpha of this mask to similar levels of the normal swipe cooldown texture
		else
			self.texture:SetTexture(Icon)
			self:SetSwipeColor(0, 0, 0, 0.8)	-- This is the default alpha of the normal swipe cooldown texture
		end
		if forceEventUnitAuraAtEnd and maxExpirationTime > 0 and Duration > 0 then
			local nextTimerUpdate = maxExpirationTime - GetTime() + 0.10
			if nextTimerUpdate < 0.10 then
				nextTimerUpdate = 0.10
			end
			C_Timer.After(nextTimerUpdate, function()
				if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < (GetTime() - 0.08))) then
					self:UNIT_AURA(self.unitId, 4)
				end
			end)
		end
		self:Show()
		self:GetParent():Show()
		if Duration > 0 then
			if not self:GetDrawSwipe() then
				self:SetDrawSwipe(true)
			end
			self:SetCooldown( maxExpirationTime - Duration, Duration )
		else
			if self:GetDrawSwipe() then
				self:SetDrawSwipe(false)
			end
			self:SetCooldown(GetTime(), 0)
			self:SetCooldown(GetTime(), 0)	--needs execute two times (or the icon can dissapear; yes, it's weird...)
		end
		--UIFrameFadeOut(self, Duration, self.frame.alpha, 0)
		self:GetParent():SetAlpha(self.frame.alpha) -- hack to apply transparency to the cooldown timer
	end
end

function LoseControl:PLAYER_TARGET_CHANGED()
	--if (debug) then print("PLAYER_TARGET_CHANGED") end
	if (self.unitId == "target" or self.unitId == "targettarget") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -11)
		end
	end
end

function LoseControl:UNIT_TARGET(unitId)
	--if (debug) then print("UNIT_TARGET", unitId) end
	if (self.unitId == "targettarget") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -12)
		end
	end
end

function LoseControl:UNIT_PET(unitId)
	--if (debug) then print("UNIT_PET", unitId) end
	if (self.unitId == "pet") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -13)
		end
	end
end

-- Function to hide the default skin of button frame
local function HideTheButtonDefaultSkin(bt)
	if bt:GetPushedTexture() ~= nil then bt:GetPushedTexture():SetAlpha(0) bt:GetPushedTexture():Hide() end
	if bt:GetNormalTexture() ~= nil then bt:GetNormalTexture():SetAlpha(0) bt:GetNormalTexture():Hide() end
	if bt:GetDisabledTexture() ~= nil then bt:GetDisabledTexture():SetAlpha(0) bt:GetDisabledTexture():Hide() end
	if bt:GetHighlightTexture() ~= nil then bt:GetHighlightTexture():SetAlpha(0) bt:GetHighlightTexture():Hide() end
	if (bt:GetName() ~= nil) then
		if _G[bt:GetName().."Shine"] ~= nil then _G[bt:GetName().."Shine"]:SetAlpha(0) _G[bt:GetName().."Shine"]:Hide() end
		if _G[bt:GetName().."Count"] ~= nil then _G[bt:GetName().."Count"]:SetAlpha(0) _G[bt:GetName().."Count"]:Hide() end
		if _G[bt:GetName().."HotKey"] ~= nil then _G[bt:GetName().."HotKey"]:SetAlpha(0) _G[bt:GetName().."HotKey"]:Hide() end
		if _G[bt:GetName().."Flash"] ~= nil then _G[bt:GetName().."Flash"]:SetAlpha(0) _G[bt:GetName().."Flash"]:Hide() end
		if _G[bt:GetName().."Name"] ~= nil then _G[bt:GetName().."Name"]:SetAlpha(0) _G[bt:GetName().."Name"]:Hide() end
		if _G[bt:GetName().."Border"] ~= nil then _G[bt:GetName().."Border"]:SetAlpha(0) _G[bt:GetName().."Border"]:Hide() end
		if _G[bt:GetName().."Icon"] ~= nil then _G[bt:GetName().."Icon"]:SetAlpha(0) _G[bt:GetName().."Icon"]:Hide() end
	end
end

-- Handle mouse dragging StartMoving
hooksecurefunc(LoseControl, "StartMoving", function(self)
	if (self.frame.anchor == "Blizzard") then
		self.texture:SetTexture(self.textureicon)
		self:SetSwipeColor(0, 0, 0, 0.8)
		self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
	end
end)

-- Handle mouse dragging StopMoving
function LoseControl:StopMoving()
	local frame = LoseControlDB.frames[self.fakeUnitId or self.unitId]
	frame.point, frame.anchor, frame.relativePoint, frame.x, frame.y = self:GetPoint()
	if not frame.anchor then
		frame.anchor = "None"
		local AnchorDropDown = _G['LoseControlOptionsPanel'..(self.fakeUnitId or self.unitId)..'AnchorDropDown']
		if (AnchorDropDown) then
			UIDropDownMenu_Initialize(AnchorDropDown, AnchorDropDown.initialize)
			UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
		end
		if self.MasqueGroup then
			self.MasqueGroup:RemoveButton(self:GetParent())
			HideTheButtonDefaultSkin(self:GetParent())
			self.MasqueGroup:AddButton(self:GetParent(), {
				FloatingBG = false,
				Icon = self.texture,
				Cooldown = self,
				Flash = _G[self:GetParent():GetName().."Flash"],
				Pushed = self:GetParent():GetPushedTexture(),
				Normal = self:GetParent():GetNormalTexture(),
				Disabled = self:GetParent():GetDisabledTexture(),
				Checked = false,
				Border = _G[self:GetParent():GetName().."Border"],
				AutoCastable = false,
				Highlight = self:GetParent():GetHighlightTexture(),
				Hotkey = _G[self:GetParent():GetName().."HotKey"],
				Count = _G[self:GetParent():GetName().."Count"],
				Name = _G[self:GetParent():GetName().."Name"],
				Duration = false,
				Shine = _G[self:GetParent():GetName().."Shine"],
			}, "Button", true)
		end
	end
	self.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][self.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][self.unitId])=="string") and _GF(anchors[frame.anchor][self.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][self.unitId])=="table") and anchors[frame.anchor][self.unitId] or UIParent))
	self.parent:SetParent(self.anchor:GetParent())
	self.defaultFrameStrata = self:GetFrameStrata()
	self:ClearAllPoints()
	self:GetParent():ClearAllPoints()
	self:SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	self:GetParent():SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	local PositionXEditBox, PositionYEditBox, FrameLevelEditBox, AnchorPointDropDown, AnchorIconPointDropDown, AnchorFrameStrataDropDown
	if strfind((self.fakeUnitId or self.unitId), "party") then
		if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'])) then
			PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
			FrameLevelEditBox = _G['LoseControlOptionsPanelpartyFrameLevelEditBox']
			AnchorPointDropDown = _G['LoseControlOptionsPanelpartyAnchorPointDropDown']
			AnchorIconPointDropDown = _G['LoseControlOptionsPanelpartyAnchorIconPointDropDown']
			AnchorFrameStrataDropDown = _G['LoseControlOptionsPanelpartyAnchorFrameStrataDropDown']
		end
	elseif strfind((self.fakeUnitId or self.unitId), "raid") then
		if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'])) then
			PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
			FrameLevelEditBox = _G['LoseControlOptionsPanelraidFrameLevelEditBox']
			AnchorPointDropDown = _G['LoseControlOptionsPanelraidAnchorPointDropDown']
			AnchorIconPointDropDown = _G['LoseControlOptionsPanelraidAnchorIconPointDropDown']
			AnchorFrameStrataDropDown = _G['LoseControlOptionsPanelraidAnchorFrameStrataDropDown']
		end
	elseif self.fakeUnitId ~= "player2" then
		PositionXEditBox = _G['LoseControlOptionsPanel'..(self.fakeUnitId or self.unitId)..'PositionXEditBox']
		PositionYEditBox = _G['LoseControlOptionsPanel'..(self.fakeUnitId or self.unitId)..'PositionYEditBox']
		FrameLevelEditBox = _G['LoseControlOptionsPanel'..(self.fakeUnitId or self.unitId)..'FrameLevelEditBox']
		AnchorPointDropDown = _G['LoseControlOptionsPanel'..(self.fakeUnitId or self.unitId)..'AnchorPointDropDown']
		AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..(self.fakeUnitId or self.unitId)..'AnchorIconPointDropDown']
		AnchorFrameStrataDropDown = _G['LoseControlOptionsPanel'..(self.fakeUnitId or self.unitId)..'AnchorFrameStrataDropDown']
	end
	if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
		PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
		PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
		FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
		if (frame.anchor ~= "Blizzard") then
			PositionXEditBox:Enable()
			PositionYEditBox:Enable()
			FrameLevelEditBox:Enable()
		end
		PositionXEditBox:SetCursorPosition(0)
		PositionYEditBox:SetCursorPosition(0)
		FrameLevelEditBox:SetCursorPosition(0)
	end
	if (AnchorPointDropDown) then
		UIDropDownMenu_Initialize(AnchorPointDropDown, AnchorPointDropDown.initialize)
		UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, frame.relativePoint or "CENTER")
		if (frame.anchor ~= "Blizzard") then
			UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
		end
	end
	if (AnchorIconPointDropDown) then
		UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
		UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
		if (frame.anchor ~= "Blizzard") then
			UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
		end
	end
	if (AnchorFrameStrataDropDown) then
		UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
		UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
		if (frame.anchor ~= "Blizzard") then
			UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
		end
	end
	if self.MasqueGroup then
		self.MasqueGroup:ReSkin()
	end
	self:StopMovingOrSizing()
end

-- Constructor method
function LoseControl:new(unitId)
	local o = CreateFrame("Cooldown", addonName .. unitId, nil, 'CooldownFrameTemplate') --, UIParent)
	local op = CreateFrame("Button", addonName .. "ButtonParent" .. unitId, nil, 'ActionButtonTemplate')
	op:EnableMouse(false)
	HideTheButtonDefaultSkin(op)
	
	setmetatable(o, self)
	self.__index = self
	
	o:SetParent(op)
	o.parent = op
	
	o:SetDrawEdge(false)

	-- Init class members
	if unitId == "player2" then
		o.unitId = "player" -- ties the object to a unit
		o.fakeUnitId = unitId
	elseif unitId == "partyplayer" then
		o.unitId = "player" -- ties the object to a unit
		o.fakeUnitId = unitId
	else
		o.unitId = unitId -- ties the object to a unit
	end
	o:SetAttribute("unit", o.unitId)
	o.texture = o:CreateTexture(nil, "BORDER") -- displays the debuff; draw layer should equal "BORDER" because cooldown spirals are drawn in the "ARTWORK" layer.
	o.texture:SetAllPoints(o) -- anchor the texture to the frame
	o:SetReverse(true) -- makes the cooldown shade from light to dark instead of dark to light

	o.text = o:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	o.text:SetText(L[o.fakeUnitId or o.unitId] or (o.fakeUnitId or o.unitId))
	o.text:SetPoint("BOTTOM", o, "BOTTOM")
	o.text:Hide()

	-- Rufio's code to make the frame border pretty. Maybe use this somehow to mask cooldown corners in Blizzard frames.
	--o.overlay = o:CreateTexture(nil, "OVERLAY") -- displays the alpha mask for making rounded corners
	--o.overlay:SetTexture("\\MINIMAP\UI-Minimap-Background")
	--o.overlay:SetTexture("Interface\\AddOns\\LoseControl\\gloss")
	--SetPortraitToTexture(o.overlay, "Textures\\MinimapMask")
	--o.overlay:SetBlendMode("BLEND") -- maybe ALPHAKEY or ADD?
	--o.overlay:SetAllPoints(o) -- anchor the texture to the frame
	--o.overlay:SetPoint("TOPLEFT", -1, 1)
	--o.overlay:SetPoint("BOTTOMRIGHT", 1, -1)
	--o.overlay:SetVertexColor(0.25, 0.25, 0.25)
	o:Hide()
	op:Hide()

	-- Create and initialize Interrupt Mini Icons
	o.iconInterruptBackground = o:CreateTexture(addonName .. unitId .. "InterruptIconBackground", "ARTWORK", nil, -2)
	o.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
	o.iconInterruptBackground:SetPoint("CENTER", 0, 0)
	o.iconInterruptBackground:Hide()
	o.iconInterruptPhysical = o:CreateTexture(addonName .. unitId .. "InterruptIconPhysical", "ARTWORK", nil, -1)
	o.iconInterruptPhysical:SetTexture("Interface\\Icons\\Ability_meleedamage")
	o.iconInterruptHoly = o:CreateTexture(addonName .. unitId .. "InterruptIconHoly", "ARTWORK", nil, -1)
	o.iconInterruptHoly:SetTexture("Interface\\Icons\\Spell_holy_holybolt")
	o.iconInterruptFire = o:CreateTexture(addonName .. unitId .. "InterruptIconFire", "ARTWORK", nil, -1)
	o.iconInterruptFire:SetTexture("Interface\\Icons\\Spell_fire_selfdestruct")
	o.iconInterruptNature = o:CreateTexture(addonName .. unitId .. "InterruptIconNature", "ARTWORK", nil, -1)
	o.iconInterruptNature:SetTexture("Interface\\Icons\\Spell_nature_protectionformnature")
	o.iconInterruptFrost = o:CreateTexture(addonName .. unitId .. "InterruptIconFrost", "ARTWORK", nil, -1)
	o.iconInterruptFrost:SetTexture("Interface\\Icons\\Spell_frost_icestorm")
	o.iconInterruptShadow = o:CreateTexture(addonName .. unitId .. "InterruptIconShadow", "ARTWORK", nil, -1)
	o.iconInterruptShadow:SetTexture("Interface\\Icons\\Spell_shadow_antishadow")
	o.iconInterruptArcane = o:CreateTexture(addonName .. unitId .. "InterruptIconArcane", "ARTWORK", nil, -1)
	o.iconInterruptArcane:SetTexture("Interface\\Icons\\Spell_nature_wispsplode")
	o.iconInterruptList = {
		[1] = o.iconInterruptPhysical,
		[2] = o.iconInterruptHoly,
		[4] = o.iconInterruptFire,
		[8] = o.iconInterruptNature,
		[16] = o.iconInterruptFrost,
		[32] = o.iconInterruptShadow,
		[64] = o.iconInterruptArcane
	}
	for _, v in pairs(o.iconInterruptList) do
		v:Hide()
		SetPortraitToTexture(v, v:GetTexture())
		v:SetTexCoord(0.08,0.92,0.08,0.92)
	end
	
	-- Handle events
	o:SetScript("OnEvent", self.OnEvent)
	o:SetScript("OnDragStart", self.StartMoving) -- this function is already built into the Frame class
	o:SetScript("OnDragStop", self.StopMoving) -- this is a custom function

	o:RegisterEvent("PLAYER_ENTERING_WORLD")
	o:RegisterEvent("GROUP_ROSTER_UPDATE")
	o:RegisterEvent("GROUP_JOINED")
	o:RegisterEvent("GROUP_LEFT")

	return o
end

-- Create new object instance for each frame
for k in pairs(DBdefaults.frames) do
	if (k ~= "player2") then
		LCframes[k] = LoseControl:new(k)
	end
end
LCframeplayer2 = LoseControl:new("player2")

-------------------------------------------------------------------------------
-- EditBox helper function
local function CreateEditBox(text, parent, width, maxLetters, globalName)
	local name = globalName or (parent:GetName() .. text)
	local editbox = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
	editbox:SetAutoFocus(false)
	editbox:SetSize(width, 25)
	editbox:SetAltArrowKeyMode(false)
	editbox:ClearAllPoints()
	editbox:SetPoint("LEFT", parent, "RIGHT", 10, 0)
	editbox:SetMaxLetters(maxLetters or 256)
	editbox:SetMovable(false)
	editbox:SetMultiLine(false)
	return editbox
end

-------------------------------------------------------------------------------
-- Slider helper function, thanks to Kollektiv
local function CreateSlider(text, parent, low, high, step, width, createBox, globalName)
	local name = globalName or (parent:GetName() .. text)
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(width)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	--_G[name .. "Text"]:SetText(text)
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)
	if createBox then
		slider.editbox = CreateEditBox("EditBox", slider, 25, 3)
		slider.editbox:SetScript("OnEnterPressed", function(self)
			local val = self:GetText()
			if tonumber(val) then
				val = mathfloor(val+0.5)
				self:SetText(val)
				self:GetParent():SetValue(val)
				self:ClearFocus()
			else
				self:SetText(mathfloor(self:GetParent():GetValue()+0.5))
				self:ClearFocus()
			end
		end)
		slider.editbox:SetScript("OnDisable", function(self)
			self:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		end)
		slider.editbox:SetScript("OnEnable", function(self)
			self:SetTextColor(1, 1, 1)
		end)
	end
	return slider
end

-------------------------------------------------------------------------------
-- DropDownMenu helper function
local function AddItem(owner, text, value)
	local info = UIDropDownMenu_CreateInfo()
	info.owner = owner
	info.func = owner.OnClick
	info.text = text
	info.value = value
	info.checked = nil -- initially set the menu item to being unchecked
	UIDropDownMenu_AddButton(info)
end

-------------------------------------------------------------------------------
-- Add main Interface Option Panel
local O = addonName .. "OptionsPanel"

local OptionsPanel = CreateFrame("Frame", O)
OptionsPanel.name = addonName

OptionsPanel.scrollframe = OptionsPanel.scrollframe or CreateFrame("ScrollFrame", OptionsPanel:GetName().."ScrollFrame", OptionsPanel, "UIPanelScrollFrameTemplate")
OptionsPanel.scrollchild = OptionsPanel.scrollchild or CreateFrame("Frame", OptionsPanel:GetName().."ScrollChild")

OptionsPanel.scrollbar = _G[OptionsPanel.scrollframe:GetName().."ScrollBar"]
OptionsPanel.scrollupbutton = _G[OptionsPanel.scrollframe:GetName().."ScrollBarScrollUpButton"]
OptionsPanel.scrolldownbutton = _G[OptionsPanel.scrollframe:GetName().."ScrollBarScrollDownButton"]
OptionsPanel.scrollupbutton:ClearAllPoints()
OptionsPanel.scrollupbutton:SetPoint("TOPRIGHT", OptionsPanel.scrollframe, "TOPRIGHT", -2, -2)
OptionsPanel.scrolldownbutton:ClearAllPoints()
OptionsPanel.scrolldownbutton:SetPoint("BOTTOMRIGHT", OptionsPanel.scrollframe, "BOTTOMRIGHT", -2, 2)
 
OptionsPanel.scrollbar:ClearAllPoints()
OptionsPanel.scrollbar:SetPoint("TOP", OptionsPanel.scrollupbutton, "BOTTOM", 0, -2)
OptionsPanel.scrollbar:SetPoint("BOTTOM", OptionsPanel.scrolldownbutton, "TOP", 0, 2)
 
OptionsPanel.scrollframe:SetScrollChild(OptionsPanel.scrollchild)
OptionsPanel.scrollframe:SetAllPoints(OptionsPanel)
OptionsPanel.scrollchild:SetSize(623, 568)

OptionsPanel.container = OptionsPanel.container or CreateFrame("Frame", OptionsPanel.scrollchild:GetName().."Container", OptionsPanel.scrollchild)
OptionsPanel.container:SetAllPoints(OptionsPanel.scrollchild)

local title = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(addonName)

local subText = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
local notes = GetAddOnMetadata(addonName, "Notes-" .. GetLocale())
if not notes then
	notes = GetAddOnMetadata(addonName, "Notes")
end
subText:SetText(notes)

-- "Unlock" checkbox - allow the frames to be moved
local Unlock = CreateFrame("CheckButton", O.."Unlock", OptionsPanel.container, "OptionsCheckButtonTemplate")
_G[O.."UnlockText"]:SetText(L["Unlock"])
Unlock.nextUnlockLoopTime = 0
function Unlock:LoopFunction()
	if (not self) then
		self = Unlock or _G[O.."Unlock"]
		if (not self) then return end
	end
	if (mathabs(GetTime()-self.nextUnlockLoopTime) < 1) then
		self:OnClick()
	end
end
function Unlock:OnClick()
	if self:GetChecked() then
		_G[O.."UnlockText"]:SetText(L["Unlock"] .. L[" (drag an icon to move)"])
		local onlyOneUnlockLoop = true
		local keys = {} -- for random icon sillyness
		for k in pairs(spellIds) do
			tinsert(keys, k)
		end
		for k, v in pairs(LCframes) do
			v.maxExpirationTime = 0
			v.unlockMode = true
			local frame = LoseControlDB.frames[k]
			if frame.enabled and ((anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][k]]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][k])=="string") and _GF(anchors[frame.anchor][k]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][k])=="table") and anchors[frame.anchor][k] or frame.anchor == "None"))) then -- only unlock frames whose anchor exists
				v:RegisterUnitEvents(false)
				v.textureicon = select(3, GetSpellInfo(keys[random(#keys)]))
				if frame.anchor == "Blizzard" then
					SetPortraitToTexture(v.texture, v.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
					v:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
					v:SetSwipeColor(0, 0, 0, 0.6)
					v.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
				else
					v.texture:SetTexture(v.textureicon)
					v:SetSwipeColor(0, 0, 0, 0.8)
					v.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
				end
				v.parent:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
				if (frame.frameStrata ~= nil) then
					v:GetParent():SetFrameStrata(frame.frameStrata)
					v:SetFrameStrata(frame.frameStrata)
				end
				local frameLevel = (v.anchor:GetParent() and v.anchor:GetParent():GetFrameLevel() or v.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
				if frameLevel < 0 then frameLevel = 0 end
				v:GetParent():SetFrameLevel(frameLevel)
				v:SetFrameLevel(frameLevel)
				v.text:Show()
				v:Show()
				v:GetParent():Show()
				v:SetDrawSwipe(true)
				v:SetCooldown( GetTime(), 30 )
				if (onlyOneUnlockLoop) then
					self.nextUnlockLoopTime = GetTime()+30
					C_Timer.After(30, Unlock.LoopFunction)
					onlyOneUnlockLoop = false
				end
				v:GetParent():SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
				v:SetMovable(true)
				v:RegisterForDrag("LeftButton")
				v:EnableMouse(true)
			else
				v:EnableMouse(false)
				v:RegisterForDrag()
				v:SetMovable(false)
				v.text:Hide()
				v:PLAYER_ENTERING_WORLD()
			end
		end
		LCframeplayer2.maxExpirationTime = 0
		LCframeplayer2.unlockMode = true
		local frame = LoseControlDB.frames.player2
		if frame.enabled and ((anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][LCframeplayer2.unitId]]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframeplayer2.unitId])=="string") and _GF(anchors[frame.anchor][LCframeplayer2.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframeplayer2.unitId])=="table") and anchors[frame.anchor][LCframeplayer2.unitId] or frame.anchor == "None"))) then -- only unlock frames whose anchor exists
			LCframeplayer2:RegisterUnitEvents(false)
			LCframeplayer2.textureicon = select(3, GetSpellInfo(keys[random(#keys)]))
			if frame.anchor == "Blizzard" then
				SetPortraitToTexture(LCframeplayer2.texture, LCframeplayer2.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
				LCframeplayer2:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
				LCframeplayer2:SetSwipeColor(0, 0, 0, 0.6)
				LCframeplayer2.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
			else
				LCframeplayer2.texture:SetTexture(LCframeplayer2.textureicon)
				LCframeplayer2:SetSwipeColor(0, 0, 0, 0.8)
				LCframeplayer2.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
			end
			LCframeplayer2.parent:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
			if (frame.frameStrata ~= nil) then
				LCframeplayer2:GetParent():SetFrameStrata(frame.frameStrata)
				LCframeplayer2:SetFrameStrata(frame.frameStrata)
			end
			local frameLevel = (LCframeplayer2.anchor:GetParent() and LCframeplayer2.anchor:GetParent():GetFrameLevel() or LCframeplayer2.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
			if frameLevel < 0 then frameLevel = 0 end
			LCframeplayer2:GetParent():SetFrameLevel(frameLevel)
			LCframeplayer2:SetFrameLevel(frameLevel)
			LCframeplayer2.text:Show()
			LCframeplayer2:Show()
			LCframeplayer2:GetParent():Show()
			LCframeplayer2:SetDrawSwipe(true)
			LCframeplayer2:SetCooldown( GetTime(), 30 )
			LCframeplayer2:GetParent():SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
		else
			LCframeplayer2.text:Hide()
			LCframeplayer2:PLAYER_ENTERING_WORLD()
		end
	else
		_G[O.."UnlockText"]:SetText(L["Unlock"])
		for _, v in pairs(LCframes) do
			v.unlockMode = false
			v:EnableMouse(false)
			v:RegisterForDrag()
			v:SetMovable(false)
			v.text:Hide()
			v:PLAYER_ENTERING_WORLD()
		end
		LCframeplayer2.unlockMode = false
		LCframeplayer2.text:Hide()
		LCframeplayer2:PLAYER_ENTERING_WORLD()
	end
end
Unlock:SetScript("OnClick", Unlock.OnClick)

local DisableGetEnemiesBuffsInformation = CreateFrame("CheckButton", O.."DisableGetEnemiesBuffsInformation", OptionsPanel.container, "OptionsCheckButtonTemplate")
_G[O.."DisableGetEnemiesBuffsInformationText"]:SetText(L["Disable Get Enemies Buff Information"])
function DisableGetEnemiesBuffsInformation:Check(value)
	LoseControlDB.noGetEnemiesBuffsInformation = self:GetChecked()
	LoseControl.noGetEnemiesBuffsInformation = LoseControlDB.noGetEnemiesBuffsInformation
	LoseControl:UpdateGetEnemiesBuffInformationOptionState()
end
DisableGetEnemiesBuffsInformation:SetScript("OnClick", function(self)
	DisableGetEnemiesBuffsInformation:Check(self:GetChecked())
end)

local DisableGetExtraDurationInformation = CreateFrame("CheckButton", O.."DisableGetExtraDurationInformation", OptionsPanel.container, "OptionsCheckButtonTemplate")
_G[O.."DisableGetExtraDurationInformationText"]:SetText(L["Disable Get Extra Aura Duration Information"])
DisableGetExtraDurationInformation:SetScript("OnClick", function(self)
	LoseControlDB.noGetExtraAuraDurationInformation = self:GetChecked()
	LoseControl.noGetExtraAuraDurationInformation = LoseControlDB.noGetExtraAuraDurationInformation
	if self:GetChecked() then
		DisableGetEnemiesBuffsInformation:Disable()
		_G[O.."DisableGetEnemiesBuffsInformationText"]:SetTextColor(0.5,0.5,0.5)
		DisableGetEnemiesBuffsInformation:SetChecked(true)
		DisableGetEnemiesBuffsInformation:Check(true)
	else
		DisableGetEnemiesBuffsInformation:Enable()
		_G[O.."DisableGetEnemiesBuffsInformationText"]:SetTextColor(_G[O.."DisableGetExtraDurationInformationText"]:GetTextColor())
	end
end)

local DisableBlizzardCooldownCount = CreateFrame("CheckButton", O.."DisableBlizzardCooldownCount", OptionsPanel.container, "OptionsCheckButtonTemplate")
_G[O.."DisableBlizzardCooldownCountText"]:SetText(L["Disable Blizzard Countdown"])
function DisableBlizzardCooldownCount:Check(value)
	LoseControlDB.noBlizzardCooldownCount = value
	LoseControl.noBlizzardCooldownCount = LoseControlDB.noBlizzardCooldownCount
	LoseControl:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
	for _, v in pairs(LCframes) do
		v:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
	end
	LCframeplayer2:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
end
DisableBlizzardCooldownCount:SetScript("OnClick", function(self)
	DisableBlizzardCooldownCount:Check(self:GetChecked())
end)

local DisableCooldownCount = CreateFrame("CheckButton", O.."DisableCooldownCount", OptionsPanel.container, "OptionsCheckButtonTemplate")
_G[O.."DisableCooldownCountText"]:SetText(L["Disable OmniCC Support"])
DisableCooldownCount:SetScript("OnClick", function(self)
	LoseControlDB.noCooldownCount = self:GetChecked()
	LoseControl.noCooldownCount = LoseControlDB.noCooldownCount
	if self:GetChecked() then
		DisableBlizzardCooldownCount:Enable()
		_G[O.."DisableBlizzardCooldownCountText"]:SetTextColor(_G[O.."DisableCooldownCountText"]:GetTextColor())
	else
		DisableBlizzardCooldownCount:Disable()
		_G[O.."DisableBlizzardCooldownCountText"]:SetTextColor(0.5,0.5,0.5)
		DisableBlizzardCooldownCount:SetChecked(true)
		DisableBlizzardCooldownCount:Check(true)
	end
end)

local Priority = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
Priority:SetText(L["Priority"])

local PriorityDescription = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
PriorityDescription:SetText(L["PriorityDescription"])
PriorityDescription:SetJustifyH("LEFT")

local PrioritySlider = {}
for k in pairs(DBdefaults.priority) do
	PrioritySlider[k] = CreateSlider(L[k], OptionsPanel.container, 0, 100, 5, 160, false, "Priority"..k.."Slider")
	PrioritySlider[k]:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value/5)*5
		_G[self:GetName() .. "Text"]:SetText(L[k] .. " (" .. value .. ")")
		LoseControlDB.priority[k] = value
		if k == "Interrupt" then
			local enable = LCframes["target"].frame.enabled
			LCframes["target"]:RegisterUnitEvents(enable)
		end
	end)
end

-------------------------------------------------------------------------------
-- Arrange all the options neatly
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

Unlock:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
DisableGetExtraDurationInformation:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -2)
DisableGetEnemiesBuffsInformation:SetPoint("TOPLEFT", DisableGetExtraDurationInformation, "BOTTOMLEFT", 0, -2)
DisableCooldownCount:SetPoint("TOPLEFT", DisableGetEnemiesBuffsInformation, "BOTTOMLEFT", 0, -2)
DisableBlizzardCooldownCount:SetPoint("TOPLEFT", DisableCooldownCount, "BOTTOMLEFT", 0, -2)

Priority:SetPoint("TOPLEFT", DisableBlizzardCooldownCount, "BOTTOMLEFT", 0, -12)
PriorityDescription:SetPoint("TOPLEFT", Priority, "BOTTOMLEFT", 0, -8)
PrioritySlider.PvE:SetPoint("TOPLEFT", PriorityDescription, "BOTTOMLEFT", 0, -24)
PrioritySlider.Immune:SetPoint("TOPLEFT", PrioritySlider.PvE, "BOTTOMLEFT", 0, -24)
PrioritySlider.ImmuneSpell:SetPoint("TOPLEFT", PrioritySlider.Immune, "BOTTOMLEFT", 0, -24)
PrioritySlider.ImmunePhysical:SetPoint("TOPLEFT", PrioritySlider.ImmuneSpell, "BOTTOMLEFT", 0, -24)
PrioritySlider.CC:SetPoint("TOPLEFT", PrioritySlider.ImmunePhysical, "BOTTOMLEFT", 0, -24)
PrioritySlider.Silence:SetPoint("TOPLEFT", PrioritySlider.CC, "BOTTOMLEFT", 0, -24)
PrioritySlider.Interrupt:SetPoint("TOPLEFT", PrioritySlider.Silence, "BOTTOMLEFT", 0, -24)
PrioritySlider.Disarm:SetPoint("TOPLEFT", PrioritySlider.PvE, "TOPRIGHT", 40, 0)
PrioritySlider.Root:SetPoint("TOPLEFT", PrioritySlider.Disarm, "BOTTOMLEFT", 0, -24)
PrioritySlider.Snare:SetPoint("TOPLEFT", PrioritySlider.Root, "BOTTOMLEFT", 0, -24)
PrioritySlider.Other:SetPoint("TOPLEFT", PrioritySlider.Snare, "BOTTOMLEFT", 0, -24)

-------------------------------------------------------------------------------
OptionsPanel.default = function() -- This method will run when the player clicks "defaults".
	_G.LoseControlDB = nil
	LoseControl:ADDON_LOADED(addonName)
	for _, v in pairs(LCframes) do
		v:PLAYER_ENTERING_WORLD()
	end
	LCframeplayer2:PLAYER_ENTERING_WORLD()
end

OptionsPanel.refresh = function() -- This method will run when the Interface Options frame calls its OnShow function and after defaults have been applied via the panel.default method described above.
	DisableGetExtraDurationInformation:SetChecked(LoseControlDB.noGetExtraAuraDurationInformation)
	DisableGetEnemiesBuffsInformation:SetChecked(LoseControlDB.noGetEnemiesBuffsInformation)
	DisableCooldownCount:SetChecked(LoseControlDB.noCooldownCount)
	DisableBlizzardCooldownCount:SetChecked(LoseControlDB.noBlizzardCooldownCount)
	if not LoseControlDB.noCooldownCount then
		DisableBlizzardCooldownCount:Disable()
		_G[O.."DisableBlizzardCooldownCountText"]:SetTextColor(0.5,0.5,0.5)
		DisableBlizzardCooldownCount:SetChecked(true)
		DisableBlizzardCooldownCount:Check(true)
	else
		DisableBlizzardCooldownCount:Enable()
		_G[O.."DisableBlizzardCooldownCountText"]:SetTextColor(_G[O.."DisableCooldownCountText"]:GetTextColor())
	end
	if LoseControlDB.noGetExtraAuraDurationInformation then
		DisableGetEnemiesBuffsInformation:Disable()
		_G[O.."DisableGetEnemiesBuffsInformationText"]:SetTextColor(0.5,0.5,0.5)
		DisableGetEnemiesBuffsInformation:SetChecked(true)
		DisableGetEnemiesBuffsInformation:Check(true)
	else
		DisableGetEnemiesBuffsInformation:Enable()
		_G[O.."DisableGetEnemiesBuffsInformationText"]:SetTextColor(_G[O.."DisableGetExtraDurationInformationText"]:GetTextColor())
	end
	local priority = LoseControlDB.priority
	for k in pairs(priority) do
		PrioritySlider[k]:SetValue(priority[k])
	end
end

InterfaceOptions_AddCategory(OptionsPanel)

-------------------------------------------------------------------------------
-- Create sub-option frames
for _, v in ipairs({ "player", "pet", "target", "targettarget", "party", "raid" }) do
	local OptionsPanelFrame = CreateFrame("Frame", O..v)
	OptionsPanelFrame.parent = addonName
	OptionsPanelFrame.name = L[v]
	
	OptionsPanelFrame.scrollframe = OptionsPanelFrame.scrollframe or CreateFrame("ScrollFrame", OptionsPanelFrame:GetName().."ScrollFrame", OptionsPanelFrame, "UIPanelScrollFrameTemplate")
	OptionsPanelFrame.scrollchild = OptionsPanelFrame.scrollchild or CreateFrame("Frame", OptionsPanelFrame:GetName().."ScrollChild")

	OptionsPanelFrame.scrollbar = _G[OptionsPanelFrame.scrollframe:GetName().."ScrollBar"]
	OptionsPanelFrame.scrollupbutton = _G[OptionsPanelFrame.scrollframe:GetName().."ScrollBarScrollUpButton"]
	OptionsPanelFrame.scrolldownbutton = _G[OptionsPanelFrame.scrollframe:GetName().."ScrollBarScrollDownButton"]
	OptionsPanelFrame.scrollupbutton:ClearAllPoints()
	OptionsPanelFrame.scrollupbutton:SetPoint("TOPRIGHT", OptionsPanelFrame.scrollframe, "TOPRIGHT", -2, -2)
	OptionsPanelFrame.scrolldownbutton:ClearAllPoints()
	OptionsPanelFrame.scrolldownbutton:SetPoint("BOTTOMRIGHT", OptionsPanelFrame.scrollframe, "BOTTOMRIGHT", -2, 2)
	 
	OptionsPanelFrame.scrollbar:ClearAllPoints()
	OptionsPanelFrame.scrollbar:SetPoint("TOP", OptionsPanelFrame.scrollupbutton, "BOTTOM", 0, -2)
	OptionsPanelFrame.scrollbar:SetPoint("BOTTOM", OptionsPanelFrame.scrolldownbutton, "TOP", 0, 2)
	 
	OptionsPanelFrame.scrollframe:SetScrollChild(OptionsPanelFrame.scrollchild)
	OptionsPanelFrame.scrollframe:SetAllPoints(OptionsPanelFrame)
	OptionsPanelFrame.scrollchild:SetSize(623, 668)

	OptionsPanelFrame.container = OptionsPanelFrame.container or CreateFrame("Frame", OptionsPanelFrame.scrollchild:GetName().."Container", OptionsPanelFrame.scrollchild)
	OptionsPanelFrame.container:SetAllPoints(OptionsPanelFrame.scrollchild)

	local AnchorDropDownLabel = OptionsPanelFrame.container:CreateFontString(O..v.."AnchorDropDownLabel", "ARTWORK", "GameFontNormal")
	AnchorDropDownLabel:SetText(L["Anchored to:"])
	local AnchorPointDropDownLabel = OptionsPanelFrame.container:CreateFontString(O..v.."AnchorPointDropDownLabel", "ARTWORK", "GameFontNormal")
	AnchorPointDropDownLabel:SetText(L["anchor:"])
	local AnchorIconPointDropDownLabel = OptionsPanelFrame.container:CreateFontString(O..v.."AnchorIconPointDropDownLabel", "ARTWORK", "GameFontNormal")
	AnchorIconPointDropDownLabel:SetText(L["icon anchor:"])
	local AnchorFrameStrataDropDownLabel = OptionsPanelFrame.container:CreateFontString(O..v.."AnchorFrameStrataDropDownLabel", "ARTWORK", "GameFontNormal")
	AnchorFrameStrataDropDownLabel:SetText(L["frame strata:"])
	local AnchorDropDown2Label
	if v == "player" then
		AnchorDropDown2Label = OptionsPanelFrame.container:CreateFontString(O..v.."AnchorDropDown2Label", "ARTWORK", "GameFontNormal")
		AnchorDropDown2Label:SetText(L["Anchored to:"])
	end
	local PositionEditBoxLabel = OptionsPanelFrame.container:CreateFontString(O..v.."PositionEditBoxLabel", "ARTWORK", "GameFontNormal")
	PositionEditBoxLabel:SetText(L["Position:"])
	local PositionXEditBoxLabel = OptionsPanelFrame.container:CreateFontString(O..v.."PositionXEditBoxLabel", "ARTWORK", "GameFontNormal")
	PositionXEditBoxLabel:SetText(L["x:"])
	local PositionYEditBoxLabel = OptionsPanelFrame.container:CreateFontString(O..v.."PositionYEditBoxLabel", "ARTWORK", "GameFontNormal")
	PositionYEditBoxLabel:SetText(L["y:"])
	local FrameLevelEditBoxLabel = OptionsPanelFrame.container:CreateFontString(O..v.."FrameLevelEditBoxLabel", "ARTWORK", "GameFontNormal")
	FrameLevelEditBoxLabel:SetText(L["frame level:"])
	local ColorPickerBackgroundInterruptREditBoxLabel = OptionsPanelFrame.container:CreateFontString(O..v.."ColorPickerBackgroundInterruptREditBoxLabel", "ARTWORK", "GameFontNormal")
	ColorPickerBackgroundInterruptREditBoxLabel:SetText(L["r:"])
	local ColorPickerBackgroundInterruptGEditBoxLabel = OptionsPanelFrame.container:CreateFontString(O..v.."ColorPickerBackgroundInterruptGEditBoxLabel", "ARTWORK", "GameFontNormal")
	ColorPickerBackgroundInterruptGEditBoxLabel:SetText(L["g:"])
	local ColorPickerBackgroundInterruptBEditBoxLabel = OptionsPanelFrame.container:CreateFontString(O..v.."ColorPickerBackgroundInterruptBEditBoxLabel", "ARTWORK", "GameFontNormal")
	ColorPickerBackgroundInterruptBEditBoxLabel:SetText(L["b:"])
	local CategoriesEnabledLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoriesEnabledLabel", "ARTWORK", "GameFontNormal")
	CategoriesEnabledLabel:SetText(L["CategoriesEnabledLabel"])
	CategoriesEnabledLabel:SetJustifyH("LEFT")
	local CategoryEnabledInterruptLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledInterruptLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledInterruptLabel:SetText(L["Interrupt"]..":")
	local CategoryEnabledPvELabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledPvELabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledPvELabel:SetText(L["PvE"]..":")
	local CategoryEnabledImmuneLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledImmuneLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledImmuneLabel:SetText(L["Immune"]..":")
	local CategoryEnabledImmuneSpellLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledImmuneSpellLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledImmuneSpellLabel:SetText(L["ImmuneSpell"]..":")
	local CategoryEnabledImmunePhysicalLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledImmunePhysicalLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledImmunePhysicalLabel:SetText(L["ImmunePhysical"]..":")
	local CategoryEnabledCCLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledCCLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledCCLabel:SetText(L["CC"]..":")
	local CategoryEnabledSilenceLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledSilenceLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledSilenceLabel:SetText(L["Silence"]..":")
	local CategoryEnabledDisarmLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledDisarmLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledDisarmLabel:SetText(L["Disarm"]..":")
	local CategoryEnabledRootLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledRootLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledRootLabel:SetText(L["Root"]..":")
	local CategoryEnabledSnareLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledSnareLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledSnareLabel:SetText(L["Snare"]..":")
	local CategoryEnabledOtherLabel = OptionsPanelFrame.container:CreateFontString(O..v.."CategoryEnabledOtherLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledOtherLabel:SetText(L["Other"]..":")
	local AdditionalOptionsLabel = OptionsPanelFrame.container:CreateFontString(O..v.."AdditionalOptionsLabel", "ARTWORK", "GameFontNormal")
	AdditionalOptionsLabel:SetText(L["AdditionalOptionsLabel"])
	AdditionalOptionsLabel:SetJustifyH("LEFT")
	local InterruptBackgroundColorLabel = OptionsPanelFrame.container:CreateFontString(O..v.."InterruptBackgroundColorLabel", "ARTWORK", "GameFontNormal")
	InterruptBackgroundColorLabel:SetText(L["InterruptBackgroundColor"]..":")
	InterruptBackgroundColorLabel:SetJustifyH("LEFT")
	local CategoriesLabels = {
		["Interrupt"] = CategoryEnabledInterruptLabel,
		["PvE"] = CategoryEnabledPvELabel,
		["Immune"] = CategoryEnabledImmuneLabel,
		["ImmuneSpell"] = CategoryEnabledImmuneSpellLabel,
		["ImmunePhysical"] = CategoryEnabledImmunePhysicalLabel,
		["CC"] = CategoryEnabledCCLabel,
		["Silence"] = CategoryEnabledSilenceLabel,
		["Disarm"] = CategoryEnabledDisarmLabel,
		["Root"] = CategoryEnabledRootLabel,
		["Snare"] = CategoryEnabledSnareLabel,
		["Other"] = CategoryEnabledOtherLabel
	}
	
	local AnchorDropDown = CreateFrame("Frame", O..v.."AnchorDropDown", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
	function AnchorDropDown:OnClick()
		UIDropDownMenu_SetSelectedValue(AnchorDropDown, self.value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if (unitId ~= "partyplayer") then
				frame.anchor = self.value
			else
				frame.anchor = "None"
			end
			icon.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][icon.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][icon.unitId])=="string") and _GF(anchors[frame.anchor][icon.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][icon.unitId])=="table") and anchors[frame.anchor][icon.unitId] or UIParent))
			icon.parent:SetParent(icon.anchor:GetParent())
			icon.defaultFrameStrata = icon:GetFrameStrata()
			if frame.anchor ~= "None" then -- reset the frame position so it centers on the anchor frame
				frame.point = (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].point) or nil
				frame.relativePoint = (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].relativePoint) or nil
				frame.frameStrata = (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].frameStrata) or nil
				frame.frameLevel = (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].frameLevel) or 0
				frame.x = (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].x) or nil
				frame.y = (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].y) or nil
			end
			if frame.anchor == "Blizzard" then
				local portrSizeValue = 36
				if (unitId == "player" or unitId == "target") then
					portrSizeValue = 56
				end
				if (unitId == "player") and LoseControlDB.duplicatePlayerPortrait then
					local DuplicatePlayerPortrait = _G['LoseControlOptionsPanel'..unitId..'DuplicatePlayerPortrait']
					if DuplicatePlayerPortrait then
						DuplicatePlayerPortrait:SetChecked(false)
						DuplicatePlayerPortrait:Check(false)
					end
				end
				frame.size = portrSizeValue
				icon:SetWidth(portrSizeValue)
				icon:SetHeight(portrSizeValue)
				icon:GetParent():SetWidth(portrSizeValue)
				icon:GetParent():SetHeight(portrSizeValue)
				SetPortraitToTexture(icon.texture, icon.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
				icon:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
				icon:SetSwipeColor(0, 0, 0, 0.6)
				icon.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
				if icon.MasqueGroup then
					icon.MasqueGroup:RemoveButton(icon:GetParent())
					HideTheButtonDefaultSkin(icon:GetParent())
				end
				_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"]:SetValue(portrSizeValue)
				_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"].editbox:SetText(portrSizeValue)
				_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"].editbox:SetCursorPosition(0)
			else
				icon.texture:SetTexture(icon.textureicon)
				icon:SetSwipeColor(0, 0, 0, 0.8)
				icon.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
				if icon.MasqueGroup then
					icon.MasqueGroup:RemoveButton(icon:GetParent())
					HideTheButtonDefaultSkin(icon:GetParent())
					icon.MasqueGroup:AddButton(icon:GetParent(), {
						FloatingBG = false,
						Icon = icon.texture,
						Cooldown = icon,
						Flash = _G[icon:GetParent():GetName().."Flash"],
						Pushed = icon:GetParent():GetPushedTexture(),
						Normal = icon:GetParent():GetNormalTexture(),
						Disabled = icon:GetParent():GetDisabledTexture(),
						Checked = false,
						Border = _G[icon:GetParent():GetName().."Border"],
						AutoCastable = false,
						Highlight = icon:GetParent():GetHighlightTexture(),
						Hotkey = _G[icon:GetParent():GetName().."HotKey"],
						Count = _G[icon:GetParent():GetName().."Count"],
						Name = _G[icon:GetParent():GetName().."Name"],
						Duration = false,
						Shine = _G[icon:GetParent():GetName().."Shine"],
					}, "Button", true)
				end
			end
			SetInterruptIconsSize(icon, frame.size)
			icon:ClearAllPoints() -- if we don't do this then the frame won't always move
			icon:GetParent():ClearAllPoints()
			icon:SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			icon:GetParent():SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			local PositionXEditBox, PositionYEditBox, FrameLevelEditBox, AnchorPointDropDown, AnchorIconPointDropDown, AnchorFrameStrataDropDown
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
					FrameLevelEditBox = _G['LoseControlOptionsPanel'..v..'FrameLevelEditBox']
					AnchorPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorPointDropDown']
					AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
					AnchorFrameStrataDropDown = _G['LoseControlOptionsPanel'..v..'AnchorFrameStrataDropDown']
				end
			elseif v == "raid" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])) then
					PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
					FrameLevelEditBox = _G['LoseControlOptionsPanel'..v..'FrameLevelEditBox']
					AnchorPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorPointDropDown']
					AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
					AnchorFrameStrataDropDown = _G['LoseControlOptionsPanel'..v..'AnchorFrameStrataDropDown']
				end
			else
				PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
				PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
				FrameLevelEditBox = _G['LoseControlOptionsPanel'..v..'FrameLevelEditBox']
				AnchorPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorPointDropDown']
				AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
				AnchorFrameStrataDropDown = _G['LoseControlOptionsPanel'..v..'AnchorFrameStrataDropDown']
			end
			if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
					FrameLevelEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
					FrameLevelEditBox:Disable()
				end
				PositionXEditBox:SetCursorPosition(0)
				PositionYEditBox:SetCursorPosition(0)
				FrameLevelEditBox:SetCursorPosition(0)
				PositionXEditBox:ClearFocus()
				PositionYEditBox:ClearFocus()
				FrameLevelEditBox:ClearFocus()
			end
			if (AnchorPointDropDown) then
				UIDropDownMenu_Initialize(AnchorPointDropDown, AnchorPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, frame.relativePoint or "CENTER")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorDropDown, AnchorDropDown.initialize)
			end
			if (AnchorIconPointDropDown) then
				UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorDropDown, AnchorDropDown.initialize)
			end
			if (AnchorFrameStrataDropDown) then
				UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown)
				end
				UIDropDownMenu_Initialize(AnchorDropDown, AnchorDropDown.initialize)
			end
			if (frame.frameStrata ~= nil) then
				icon:GetParent():SetFrameStrata(frame.frameStrata)
				icon:SetFrameStrata(frame.frameStrata)
			end
			local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
			if frameLevel < 0 then frameLevel = 0 end
			icon:GetParent():SetFrameLevel(frameLevel)
			icon:SetFrameLevel(frameLevel)
			if icon.MasqueGroup then
				icon.MasqueGroup:ReSkin()
			end
			if v == "raid" and frame.anchor == "BlizzardRaidFrames" then
				MainHookCompactRaidFrames()
			end
			if icon:GetEnabled() and not icon.unlockMode then
				icon.maxExpirationTime = 0
				icon:UNIT_AURA(icon.unitId, 0)
			end
		end
	end

	local AnchorDropDown2
	if v == "player" then
		AnchorDropDown2	= CreateFrame("Frame", O..v.."AnchorDropDown2", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
		function AnchorDropDown2:OnClick()
			UIDropDownMenu_SetSelectedValue(AnchorDropDown2, self.value)
			local frame = LoseControlDB.frames.player2
			local icon = LCframeplayer2
			frame.anchor = self.value
			icon.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][LCframes.player.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframes.player.unitId])=="string") and _GF(anchors[frame.anchor][LCframes.player.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframes.player.unitId])=="table") and anchors[frame.anchor][LCframes.player.unitId] or UIParent))
			icon.parent:SetParent(icon.anchor:GetParent())
			icon.defaultFrameStrata = icon:GetFrameStrata()
			if frame.anchor ~= "None" then -- reset the frame position so it centers on the anchor frame
				frame.point = (DBdefaults.frames.player2 and frame.anchor == DBdefaults.frames.player2.anchor and DBdefaults.frames.player2.point) or nil
				frame.relativePoint = (DBdefaults.frames.player2 and frame.anchor == DBdefaults.frames.player2.anchor and DBdefaults.frames.player2.relativePoint) or nil
				frame.frameStrata = (DBdefaults.frames.player2 and frame.anchor == DBdefaults.frames.player2.anchor and DBdefaults.frames.player2.frameStrata) or nil
				frame.frameLevel = (DBdefaults.frames.player2 and frame.anchor == DBdefaults.frames.player2.anchor and DBdefaults.frames.player2.frameLevel) or 0
				frame.x = (DBdefaults.frames.player2 and frame.anchor == DBdefaults.frames.player2.anchor and DBdefaults.frames.player2.x) or nil
				frame.y = (DBdefaults.frames.player2 and frame.anchor == DBdefaults.frames.player2.anchor and DBdefaults.frames.player2.y) or nil
			end
			if frame.anchor == "Blizzard" then
				local portrSizeValue = 56
				frame.size = portrSizeValue
				icon:SetWidth(portrSizeValue)
				icon:SetHeight(portrSizeValue)
				icon:GetParent():SetWidth(portrSizeValue)
				icon:GetParent():SetHeight(portrSizeValue)
				SetPortraitToTexture(icon.texture, icon.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
				icon:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
				icon:SetSwipeColor(0, 0, 0, 0.6)
				icon.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
				if icon.MasqueGroup then
					icon.MasqueGroup:RemoveButton(icon:GetParent())
					HideTheButtonDefaultSkin(icon:GetParent())
				end
				_G[OptionsPanelFrame:GetName() .. "IconSizeSlider2"]:SetValue(portrSizeValue)
				_G[OptionsPanelFrame:GetName() .. "IconSizeSlider2"].editbox:SetText(portrSizeValue)
				_G[OptionsPanelFrame:GetName() .. "IconSizeSlider2"].editbox:SetCursorPosition(0)
			else
				icon.texture:SetTexture(icon.textureicon)
				icon:SetSwipeColor(0, 0, 0, 0.8)
				icon.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
				if icon.MasqueGroup then
					icon.MasqueGroup:RemoveButton(icon:GetParent())
					HideTheButtonDefaultSkin(icon:GetParent())
					icon.MasqueGroup:AddButton(icon:GetParent(), {
						FloatingBG = false,
						Icon = icon.texture,
						Cooldown = icon,
						Flash = _G[icon:GetParent():GetName().."Flash"],
						Pushed = icon:GetParent():GetPushedTexture(),
						Normal = icon:GetParent():GetNormalTexture(),
						Disabled = icon:GetParent():GetDisabledTexture(),
						Checked = false,
						Border = _G[icon:GetParent():GetName().."Border"],
						AutoCastable = false,
						Highlight = icon:GetParent():GetHighlightTexture(),
						Hotkey = _G[icon:GetParent():GetName().."HotKey"],
						Count = _G[icon:GetParent():GetName().."Count"],
						Name = _G[icon:GetParent():GetName().."Name"],
						Duration = false,
						Shine = _G[icon:GetParent():GetName().."Shine"],
					}, "Button", true)
				end
			end
			SetInterruptIconsSize(icon, frame.size)
			icon:ClearAllPoints() -- if we don't do this then the frame won't always move
			icon:GetParent():ClearAllPoints()
			icon:SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			icon:GetParent():SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			if (frame.frameStrata ~= nil) then
				icon:GetParent():SetFrameStrata(frame.frameStrata)
				icon:SetFrameStrata(frame.frameStrata)
			end
			local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
			if frameLevel < 0 then frameLevel = 0 end
			icon:GetParent():SetFrameLevel(frameLevel)
			icon:SetFrameLevel(frameLevel)
			if icon.MasqueGroup then
				icon.MasqueGroup:ReSkin()
			end
			if icon:GetEnabled() and not icon.unlockMode then
				icon.maxExpirationTime = 0
				icon:UNIT_AURA(icon.unitId, 0)
			end
		end
	end
	
	local AnchorPositionPartyDropDown
	if v == "party" then
		AnchorPositionPartyDropDown	= CreateFrame("Frame", O..v.."AnchorPositionPartyDropDown", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
		function AnchorPositionPartyDropDown:OnClick()
			local value = self.value or UIDropDownMenu_GetSelectedValue(AnchorPositionPartyDropDown)
			UIDropDownMenu_SetSelectedValue(AnchorPositionPartyDropDown, value)
			local unitId = value
			local frame = LoseControlDB.frames[unitId]
			local PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
			local PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
			local FrameLevelEditBox = _G['LoseControlOptionsPanel'..v..'FrameLevelEditBox']
			if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
					FrameLevelEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
					FrameLevelEditBox:Disable()
				end
				PositionXEditBox:SetCursorPosition(0)
				PositionYEditBox:SetCursorPosition(0)
				FrameLevelEditBox:SetCursorPosition(0)
				PositionXEditBox:ClearFocus()
				PositionYEditBox:ClearFocus()
				FrameLevelEditBox:ClearFocus()
			end
			local AnchorPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorPointDropDown']
			if (AnchorPointDropDown) then
				UIDropDownMenu_Initialize(AnchorPointDropDown, AnchorPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, frame.relativePoint or "CENTER")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorPositionPartyDropDown, AnchorPositionPartyDropDown.initialize)
			end
			local AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
			if (AnchorIconPointDropDown) then
				UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorPositionPartyDropDown, AnchorPositionPartyDropDown.initialize)
			end
			local AnchorFrameStrataDropDown = _G['LoseControlOptionsPanel'..v..'AnchorFrameStrataDropDown']
			if (AnchorFrameStrataDropDown) then
				UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown)
				end
				UIDropDownMenu_Initialize(AnchorPositionPartyDropDown, AnchorPositionPartyDropDown.initialize)
			end
		end
	end
	
	local AnchorPositionRaidDropDown
	if v == "raid" then
		AnchorPositionRaidDropDown = CreateFrame("Frame", O..v.."AnchorPositionRaidDropDown", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
		function AnchorPositionRaidDropDown:OnClick()
			UIDropDownMenu_SetSelectedValue(AnchorPositionRaidDropDown, self.value)
			local unitId = self.value
			local frame = LoseControlDB.frames[unitId]
			local PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
			local PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
			local FrameLevelEditBox = _G['LoseControlOptionsPanel'..v..'FrameLevelEditBox']
			if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
					FrameLevelEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
					FrameLevelEditBox:Disable()
				end
				PositionXEditBox:SetCursorPosition(0)
				PositionYEditBox:SetCursorPosition(0)
				FrameLevelEditBox:SetCursorPosition(0)
				PositionXEditBox:ClearFocus()
				PositionYEditBox:ClearFocus()
				FrameLevelEditBox:ClearFocus()
			end
			local AnchorPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorPointDropDown']
			if (AnchorPointDropDown) then
				UIDropDownMenu_Initialize(AnchorPointDropDown, AnchorPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, frame.relativePoint or "CENTER")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorPositionRaidDropDown, AnchorPositionRaidDropDown.initialize)
			end
			local AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
			if (AnchorIconPointDropDown) then
				UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorPositionRaidDropDown, AnchorPositionRaidDropDown.initialize)
			end
			local AnchorFrameStrataDropDown = _G['LoseControlOptionsPanel'..v..'AnchorFrameStrataDropDown']
			if (AnchorFrameStrataDropDown) then
				UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
				if (frame.anchor ~= "Blizzard") then
					UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown)
				end
				UIDropDownMenu_Initialize(AnchorPositionRaidDropDown, AnchorPositionRaidDropDown.initialize)
			end
		end
	end

	local PositionXEditBox = CreateEditBox(L["Position"], OptionsPanelFrame.container, 55, 20, OptionsPanelFrame:GetName() .. "PositionXEditBox")
	PositionXEditBox.labelObj = PositionXEditBoxLabel
	PositionXEditBox:SetScript("OnEnterPressed", function(self, value)
		local val = self:GetText()
		local unitId = v
		if v == "party" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])
		elseif v == "raid" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])
		end
		local frame = LoseControlDB.frames[unitId]
		local icon = LCframes[unitId]
		if tonumber(val) then
			val = mathfloor(val+0.5)
			self:SetText(val)
			frame.x = val
			icon:ClearAllPoints()
			icon:GetParent():ClearAllPoints()
			icon:SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			icon:GetParent():SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			if icon.MasqueGroup then
				icon.MasqueGroup:ReSkin()
			end
			self:ClearFocus()
		else
			self:SetText(mathfloor((frame.x or 0)+0.5))
			self:ClearFocus()
		end
	end)
	PositionXEditBox:SetScript("OnDisable", function(self)
		self:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		self.labelObj:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end)
	PositionXEditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
		self.labelObj:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end)
	
	local PositionYEditBox = CreateEditBox(L["Position"], OptionsPanelFrame.container, 55, 20, OptionsPanelFrame:GetName() .. "PositionYEditBox")
	PositionYEditBox.labelObj = PositionYEditBoxLabel
	PositionYEditBox:SetScript("OnEnterPressed", function(self, value)
		local val = self:GetText()
		local unitId = v
		if v == "party" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])
		elseif v == "raid" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])
		end
		local frame = LoseControlDB.frames[unitId]
		local icon = LCframes[unitId]
		if tonumber(val) then
			val = mathfloor(val+0.5)
			self:SetText(val)
			frame.y = val
			icon:ClearAllPoints()
			icon:GetParent():ClearAllPoints()
			icon:SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			icon:GetParent():SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			if icon.MasqueGroup then
				icon.MasqueGroup:ReSkin()
			end
			self:ClearFocus()
		else
			self:SetText(mathfloor((frame.y or 0)+0.5))
			self:ClearFocus()
		end
	end)
	PositionYEditBox:SetScript("OnDisable", function(self)
		self:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		self.labelObj:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end)
	PositionYEditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
		self.labelObj:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end)

	local AnchorPointDropDown = CreateFrame("Frame", O..v.."AnchorPointDropDown", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
	function AnchorPointDropDown:OnClick()
		UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, self.value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon, AnchorIconPointDropDown
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					icon = LCframes[unitId]
					AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
				end
			elseif v == "raid" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])) then
					icon = LCframes[unitId]
					AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
				end
			else
				icon = LCframes[unitId]
				AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
			end
			if (frame and icon) then
				frame.relativePoint = self.value
				if (AnchorIconPointDropDown) then
					frame.point = self.value
				end
				icon:ClearAllPoints()
				icon:GetParent():ClearAllPoints()
				icon:SetPoint(
					frame.point or "CENTER",
					icon.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
				icon:GetParent():SetPoint(
					frame.point or "CENTER",
					icon.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
			end
			if (AnchorIconPointDropDown and frame) then
				UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
				UIDropDownMenu_Initialize(AnchorPointDropDown, AnchorPointDropDown.initialize)
			end
		end
	end
	
	local AnchorIconPointDropDown = CreateFrame("Frame", O..v.."AnchorIconPointDropDown", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
	function AnchorIconPointDropDown:OnClick()
		UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, self.value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					icon = LCframes[unitId]
				end
			elseif v == "raid" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])) then
					icon = LCframes[unitId]
				end
			else
				icon = LCframes[unitId]
			end
			if (frame and icon) then
				frame.point = self.value
				icon:ClearAllPoints()
				icon:GetParent():ClearAllPoints()
				icon:SetPoint(
					frame.point or "CENTER",
					icon.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
				icon:GetParent():SetPoint(
					frame.point or "CENTER",
					icon.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
			end
		end
	end
	
	local AnchorFrameStrataDropDown = CreateFrame("Frame", O..v.."AnchorFrameStrataDropDown", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
	function AnchorFrameStrataDropDown:OnClick()
		UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, self.value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					icon = LCframes[unitId]
				end
			elseif v == "raid" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])) then
					icon = LCframes[unitId]
				end
			else
				icon = LCframes[unitId]
			end
			if (frame and icon) then
				frame.frameStrata = (self.value ~= "AUTO") and self.value or nil
				if (frame.frameStrata == nil) then
					icon:GetParent():SetFrameStrata(icon.defaultFrameStrata or "MEDIUM")
					icon:SetFrameStrata(icon.defaultFrameStrata or "MEDIUM")
				else
					icon:GetParent():SetFrameStrata(frame.frameStrata)
					icon:SetFrameStrata(frame.frameStrata)
				end
				local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
				if frameLevel < 0 then frameLevel = 0 end
				icon:GetParent():SetFrameLevel(frameLevel)
				icon:SetFrameLevel(frameLevel)
			end
		end
	end
	
	local FrameLevelEditBox = CreateEditBox(nil, OptionsPanelFrame.container, 55, 20, OptionsPanelFrame:GetName() .. "FrameLevelEditBox")
	FrameLevelEditBox.labelObj = FrameLevelEditBoxLabel
	FrameLevelEditBox:SetScript("OnEnterPressed", function(self, value)
		local val = self:GetText()
		local unitId = v
		if v == "party" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])
		elseif v == "raid" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])
		end
		local frame = LoseControlDB.frames[unitId]
		local icon = LCframes[unitId]
		if tonumber(val) then
			val = mathfloor(val+0.5)
			self:SetText(val)
			frame.frameLevel = val
			local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
			if frameLevel < 0 then frameLevel = 0 end
			icon:GetParent():SetFrameLevel(frameLevel)
			icon:SetFrameLevel(frameLevel)
			self:ClearFocus()
		else
			self:SetText(mathfloor((frame.frameLevel or 0)+0.5))
			self:ClearFocus()
		end
	end)
	FrameLevelEditBox:SetScript("OnDisable", function(self)
		self:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		self.labelObj:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end)
	FrameLevelEditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
		self.labelObj:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end)

	local SizeSlider = CreateSlider(L["Icon Size"], OptionsPanelFrame.container, 4, 256, 1, 160, true, OptionsPanelFrame:GetName() .. "IconSizeSlider")
	SizeSlider:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["Icon Size"] .. " (" .. value .. "px)")
		self.editbox:SetText(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].size = value
			LCframes[frame]:SetWidth(value)
			LCframes[frame]:SetHeight(value)
			LCframes[frame]:GetParent():SetWidth(value)
			LCframes[frame]:GetParent():SetHeight(value)
			if LCframes[frame].MasqueGroup then
				LCframes[frame].MasqueGroup:ReSkin()
			end
			SetInterruptIconsSize(LCframes[frame], value)
		end
	end)
	
	local SizeSlider2
	if v == "player" then
		SizeSlider2 = CreateSlider(L["Icon Size"], OptionsPanelFrame.container, 4, 256, 1, 160, true, OptionsPanelFrame:GetName() .. "IconSizeSlider2")
		SizeSlider2:SetScript("OnValueChanged", function(self, value)
			value = mathfloor(value+0.5)
			_G[self:GetName() .. "Text"]:SetText(L["Icon Size"] .. " (" .. value .. "px)")
			self.editbox:SetText(value)
			if v == "player" then
				LoseControlDB.frames.player2.size = value
				LCframeplayer2:SetWidth(value)
				LCframeplayer2:SetHeight(value)
				LCframeplayer2:GetParent():SetWidth(value)
				LCframeplayer2:GetParent():SetHeight(value)
				if LCframeplayer2.MasqueGroup then
					LCframeplayer2.MasqueGroup:ReSkin()
				end
				SetInterruptIconsSize(LCframeplayer2, value)
			end
		end)
	end

	local AlphaSlider = CreateSlider(L["Opacity"], OptionsPanelFrame.container, 0, 100, 1, 160, true, OptionsPanelFrame:GetName() .. "OpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSlider:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["Opacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].alpha = value / 100 -- the real alpha value
			LCframes[frame]:GetParent():SetAlpha(value / 100)
		end
	end)

	local AlphaSlider2
	if v == "player" then
		AlphaSlider2 = CreateSlider(L["Opacity"], OptionsPanelFrame.container, 0, 100, 1, 160, true, OptionsPanelFrame:GetName() .. "Opacity2Slider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
		AlphaSlider2:SetScript("OnValueChanged", function(self, value)
			value = mathfloor(value+0.5)
			_G[self:GetName() .. "Text"]:SetText(L["Opacity"] .. " (" .. value .. "%)")
			self.editbox:SetText(value)
			if v == "player" then
				LoseControlDB.frames.player2.alpha = value / 100 -- the real alpha value
				LCframeplayer2:GetParent():SetAlpha(value / 100)
			end
		end)
	end

	local DisableInBG
	if v == "party" then
		DisableInBG = CreateFrame("CheckButton", O..v.."DisableInBG", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInBGText"]:SetText(L["DisableInBG"])
		DisableInBG:SetScript("OnClick", function(self)
			LoseControlDB.disablePartyInBG = self:GetChecked()
			local frames = { "party1", "party2", "party3", "party4", "partyplayer" }
			for _, frame in ipairs(frames) do
				local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
				LCframes[frame].maxExpirationTime = 0
				LCframes[frame]:RegisterUnitEvents(enable)
				if enable and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
				end
			end
		end)
	elseif v == "raid" then
		DisableInBG = CreateFrame("CheckButton", O..v.."DisableInBG", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInBGText"]:SetText(L["DisableInBG"])
		DisableInBG:SetScript("OnClick", function(self)
			LoseControlDB.disableRaidInBG = self:GetChecked()
			local frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
			for _, frame in ipairs(frames) do
				local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
				LCframes[frame].maxExpirationTime = 0
				LCframes[frame]:RegisterUnitEvents(enable)
				if enable and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
				end
			end
		end)
	end

	local DisableInRaid
	if v == "party" then
		DisableInRaid = CreateFrame("CheckButton", O..v.."DisableInRaid", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInRaidText"]:SetText(L["DisableInRaid"])
		DisableInRaid:SetScript("OnClick", function(self)
			LoseControlDB.disablePartyInRaid = self:GetChecked()
			local frames = { "party1", "party2", "party3", "party4", "partyplayer" }
			for _, frame in ipairs(frames) do
				local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
				LCframes[frame].maxExpirationTime = 0
				LCframes[frame]:RegisterUnitEvents(enable)
				if enable and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
				end
			end
		end)
	end

	local ShowNPCInterrupts
	if v == "target" or v == "targettarget" then
		ShowNPCInterrupts = CreateFrame("CheckButton", O..v.."ShowNPCInterrupts", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."ShowNPCInterruptsText"]:SetText(L["ShowNPCInterrupts"])
		ShowNPCInterrupts:SetScript("OnClick", function(self)
			if v == "target" then
				LoseControlDB.showNPCInterruptsTarget = self:GetChecked()
			elseif v == "targettarget" then
				LoseControlDB.showNPCInterruptsTargetTarget = self:GetChecked()
			end
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
			end
		end)
	end

	local DisablePlayerTargetTarget
	if v == "targettarget" then
		DisablePlayerTargetTarget = CreateFrame("CheckButton", O..v.."DisablePlayerTargetTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisablePlayerTargetTargetText"]:SetText(L["DisablePlayerTargetTarget"])
		DisablePlayerTargetTarget:SetScript("OnClick", function(self)
			LoseControlDB.disablePlayerTargetTarget = self:GetChecked()
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
			end
		end)
	end

	local DisableTargetTargetTarget
	if v == "targettarget" then
		DisableTargetTargetTarget = CreateFrame("CheckButton", O..v.."DisableTargetTargetTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableTargetTargetTargetText"]:SetText(L["DisableTargetTargetTarget"])
		DisableTargetTargetTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableTargetTargetTarget = self:GetChecked()
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
			end
		end)
	end

	local DisablePlayerTargetPlayerTargetTarget
	if v == "targettarget" then
		DisablePlayerTargetPlayerTargetTarget = CreateFrame("CheckButton", O..v.."DisablePlayerTargetPlayerTargetTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisablePlayerTargetPlayerTargetTargetText"]:SetText(L["DisablePlayerTargetPlayerTargetTarget"])
		DisablePlayerTargetPlayerTargetTarget:SetScript("OnClick", function(self)
			LoseControlDB.disablePlayerTargetPlayerTargetTarget = self:GetChecked()
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
			end
		end)
	end

	local DisableTargetDeadTargetTarget
	if v == "targettarget" then
		DisableTargetDeadTargetTarget = CreateFrame("CheckButton", O..v.."DisableTargetDeadTargetTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableTargetDeadTargetTargetText"]:SetText(L["DisableTargetDeadTargetTarget"])
		DisableTargetDeadTargetTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableTargetDeadTargetTarget = self:GetChecked()
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
			end
		end)
	end

	local AlphaSliderBackgroundInterrupt = CreateSlider(L["InterruptBackgroundOpacity"], OptionsPanelFrame.container, 0, 100, 1, 200, true, OptionsPanelFrame:GetName() .. "InterruptBackgroundOpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSliderBackgroundInterrupt:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["InterruptBackgroundOpacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].interruptBackgroundAlpha = value / 100 -- the real alpha value
			LCframes[frame].iconInterruptBackground:SetAlpha(value / 100)
			if (self.timerEnabled and LCframes[frame].unlockMode) then
				LCframes[frame].iconInterruptBackground:Show()
				LCframes[frame].timerIconInterruptBackgroundShow = GetTime() + 2
				C_Timer.After(2.1, function()
					if (GetTime() > LCframes[frame].timerIconInterruptBackgroundShow) then
						HideColorPicker()
						LCframes[frame].iconInterruptBackground:Hide()
					end
				end)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.interruptBackgroundAlpha = value / 100 -- the real alpha value
				LCframeplayer2.iconInterruptBackground:SetAlpha(value / 100)
				if (self.timerEnabled and LCframeplayer2.unlockMode) then
					LCframeplayer2.iconInterruptBackground:Show()
					LCframeplayer2.timerIconInterruptBackgroundShow = GetTime() + 2
					C_Timer.After(2.1, function()
						if (GetTime() > LCframeplayer2.timerIconInterruptBackgroundShow) then
							HideColorPicker()
							LCframeplayer2.iconInterruptBackground:Hide()
						end
					end)
				end
			end
		end
	end)
	
	local AlphaSliderInterruptMiniIcons = CreateSlider(L["InterruptMiniIconsOpacity"], OptionsPanelFrame.container, 0, 100, 1, 200, true, OptionsPanelFrame:GetName() .. "InterruptMiniIconsOpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSliderInterruptMiniIcons:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["InterruptMiniIconsOpacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].interruptMiniIconsAlpha = value / 100 -- the real alpha value
			local i = 1
			for _, w in pairs(LCframes[frame].iconInterruptList) do
				w:SetAlpha(value / 100)
				if (self.timerEnabled and LCframes[frame].unlockMode and (i < 5)) then
					w:SetPoint("BOTTOMRIGHT", LCframes[frame].interruptIconOrderPos[i][1], LCframes[frame].interruptIconOrderPos[i][2])
					i = i + 1
					w:Show()
					w.timerInterruptMiniIconsAlphaShow = GetTime() + 2
					C_Timer.After(2.1, function()
						if (GetTime() > w.timerInterruptMiniIconsAlphaShow) then
							w:Hide()
						end
					end)
				end
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.interruptMiniIconsAlpha = value / 100 -- the real alpha value
				local i = 1
				for _, w in pairs(LCframeplayer2.iconInterruptList) do
					w:SetAlpha(value / 100)
					if (self.timerEnabled and LCframeplayer2.unlockMode and (i < 5)) then
						w:SetPoint("BOTTOMRIGHT", LCframeplayer2.interruptIconOrderPos[i][1], LCframeplayer2.interruptIconOrderPos[i][2])
						i = i + 1
						w:Show()
						w.timerInterruptMiniIconsAlphaShow = GetTime() + 2
						C_Timer.After(2.1, function()
							if (GetTime() > w.timerInterruptMiniIconsAlphaShow) then
								w:Hide()
							end
						end)
					end
				end
			end
		end
	end)
	
	local ColorPickerBackgroundInterrupt = CreateFrame("Button", OptionsPanelFrame:GetName() .. "ColorPickerBackgroundInterrupt", OptionsPanelFrame.container, "GlowBoxTemplate")
	ColorPickerBackgroundInterrupt:SetSize(25, 25)
	ColorPickerBackgroundInterrupt:SetPoint("LEFT")
	ColorPickerBackgroundInterrupt.texture = ColorPickerBackgroundInterrupt:CreateTexture()
	ColorPickerBackgroundInterrupt.texture:SetAllPoints()
	ColorPickerBackgroundInterrupt.texture:SetTexture("Interface/Buttons/WHITE8x8")
	ColorPickerBackgroundInterrupt:SetScript("OnClick", function(self)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		self.texture.frames = frames
		self.texture.pframe = v
		for _, frame in ipairs(frames) do
			LCframes[frame].iconInterruptBackground:Show()
			C_Timer.After(0.01, function()	-- execute in some close next frame
				LCframes[frame].iconInterruptBackground:Show()
			end)
			if (frame == "player") then
				LCframeplayer2.iconInterruptBackground:Show()
				C_Timer.After(0.01, function()	-- execute in some close next frame
					LCframeplayer2.iconInterruptBackground:Show()
				end)
			end
		end
		ShowColorPicker(self.texture, LoseControlDB.frames[frames[1]].interruptBackgroundVertexColor.r, LoseControlDB.frames[frames[1]].interruptBackgroundVertexColor.g, LoseControlDB.frames[frames[1]].interruptBackgroundVertexColor.b, nil, InterruptBackgroundColorPickerChangeCallback, InterruptBackgroundColorPickerCancelCallback)
	end)
	
	local ColorPickerBackgroundInterruptREditBox = CreateEditBox(nil, OptionsPanelFrame.container, 30, 3, OptionsPanelFrame:GetName() .. "ColorPickerBackgroundInterruptREditBox")
	ColorPickerBackgroundInterruptREditBox.labelObj = ColorPickerBackgroundInterruptREditBoxLabel
	ColorPickerBackgroundInterruptREditBox:SetScript("OnEnterPressed", function(self, value)
		local val = self:GetText()
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if tonumber(val) then
				val = mathfloor(val+0.5)
				if (val > 255) then val = 255 elseif (val < 0) then val = 0 end
				self:SetText(val)
				HideColorPicker()
				frame.interruptBackgroundVertexColor.r = val / 255
				icon.iconInterruptBackground:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
				ColorPickerBackgroundInterrupt.texture:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
				if (icon.unlockMode) then
					icon.iconInterruptBackground:Show()
					icon.timerIconInterruptBackgroundShow = GetTime() + 2
					C_Timer.After(2.1, function()
						if (GetTime() > icon.timerIconInterruptBackgroundShow) then
							HideColorPicker()
							icon.iconInterruptBackground:Hide()
						end
					end)
				end
				if (unitId == "player") then
					LoseControlDB.frames.player2.interruptBackgroundVertexColor.r = val / 255
					LCframeplayer2.iconInterruptBackground:SetVertexColor(LoseControlDB.frames.player2.interruptBackgroundVertexColor.r, LoseControlDB.frames.player2.interruptBackgroundVertexColor.g, LoseControlDB.frames.player2.interruptBackgroundVertexColor.b)
					if (LCframeplayer2.unlockMode) then
						LCframeplayer2.iconInterruptBackground:Show()
						LCframeplayer2.timerIconInterruptBackgroundShow = GetTime() + 2
						C_Timer.After(2.1, function()
							if (GetTime() > LCframeplayer2.timerIconInterruptBackgroundShow) then
								HideColorPicker()
								LCframeplayer2.iconInterruptBackground:Hide()
							end
						end)
					end
				end
				self:ClearFocus()
			else
				self:SetText(mathfloor(((frame.interruptBackgroundVertexColor.r * 255) or 0)+0.5))
				self:ClearFocus()
			end
		end
	end)
	ColorPickerBackgroundInterruptREditBox:SetScript("OnDisable", function(self)
		self:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		self.labelObj:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end)
	ColorPickerBackgroundInterruptREditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
		self.labelObj:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end)
	
	local ColorPickerBackgroundInterruptGEditBox = CreateEditBox(nil, OptionsPanelFrame.container, 30, 3, OptionsPanelFrame:GetName() .. "ColorPickerBackgroundInterruptGEditBox")
	ColorPickerBackgroundInterruptGEditBox.labelObj = ColorPickerBackgroundInterruptGEditBoxLabel
	ColorPickerBackgroundInterruptGEditBox:SetScript("OnEnterPressed", function(self, value)
		local val = self:GetText()
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if tonumber(val) then
				val = mathfloor(val+0.5)
				if (val > 255) then val = 255 elseif (val < 0) then val = 0 end
				self:SetText(val)
				HideColorPicker()
				frame.interruptBackgroundVertexColor.g = val / 255
				icon.iconInterruptBackground:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
				ColorPickerBackgroundInterrupt.texture:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
				if (icon.unlockMode) then
					icon.iconInterruptBackground:Show()
					icon.timerIconInterruptBackgroundShow = GetTime() + 2
					C_Timer.After(2.1, function()
						if (GetTime() > icon.timerIconInterruptBackgroundShow) then
							HideColorPicker()
							icon.iconInterruptBackground:Hide()
						end
					end)
				end
				if (unitId == "player") then
					LoseControlDB.frames.player2.interruptBackgroundVertexColor.g = val / 255
					LCframeplayer2.iconInterruptBackground:SetVertexColor(LoseControlDB.frames.player2.interruptBackgroundVertexColor.r, LoseControlDB.frames.player2.interruptBackgroundVertexColor.g, LoseControlDB.frames.player2.interruptBackgroundVertexColor.b)
					if (LCframeplayer2.unlockMode) then
						LCframeplayer2.iconInterruptBackground:Show()
						LCframeplayer2.timerIconInterruptBackgroundShow = GetTime() + 2
						C_Timer.After(2.1, function()
							if (GetTime() > LCframeplayer2.timerIconInterruptBackgroundShow) then
								HideColorPicker()
								LCframeplayer2.iconInterruptBackground:Hide()
							end
						end)
					end
				end
				self:ClearFocus()
			else
				self:SetText(mathfloor(((frame.interruptBackgroundVertexColor.g * 255) or 0)+0.5))
				self:ClearFocus()
			end
		end
	end)
	ColorPickerBackgroundInterruptGEditBox:SetScript("OnDisable", function(self)
		self:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		self.labelObj:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end)
	ColorPickerBackgroundInterruptGEditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
		self.labelObj:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end)
	
	local ColorPickerBackgroundInterruptBEditBox = CreateEditBox(nil, OptionsPanelFrame.container, 30, 3, OptionsPanelFrame:GetName() .. "ColorPickerBackgroundInterruptBEditBox")
	ColorPickerBackgroundInterruptBEditBox.labelObj = ColorPickerBackgroundInterruptBEditBoxLabel
	ColorPickerBackgroundInterruptBEditBox:SetScript("OnEnterPressed", function(self, value)
		local val = self:GetText()
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if tonumber(val) then
				val = mathfloor(val+0.5)
				if (val > 255) then val = 255 elseif (val < 0) then val = 0 end
				self:SetText(val)
				HideColorPicker()
				frame.interruptBackgroundVertexColor.b = val / 255
				icon.iconInterruptBackground:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
				ColorPickerBackgroundInterrupt.texture:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
				if (icon.unlockMode) then
					icon.iconInterruptBackground:Show()
					icon.timerIconInterruptBackgroundShow = GetTime() + 2
					C_Timer.After(2.1, function()
						if (GetTime() > icon.timerIconInterruptBackgroundShow) then
							HideColorPicker()
							icon.iconInterruptBackground:Hide()
						end
					end)
				end
				if (unitId == "player") then
					LoseControlDB.frames.player2.interruptBackgroundVertexColor.b = val / 255
					LCframeplayer2.iconInterruptBackground:SetVertexColor(LoseControlDB.frames.player2.interruptBackgroundVertexColor.r, LoseControlDB.frames.player2.interruptBackgroundVertexColor.g, LoseControlDB.frames.player2.interruptBackgroundVertexColor.b)
					if (LCframeplayer2.unlockMode) then
						LCframeplayer2.iconInterruptBackground:Show()
						LCframeplayer2.timerIconInterruptBackgroundShow = GetTime() + 2
						C_Timer.After(2.1, function()
							if (GetTime() > LCframeplayer2.timerIconInterruptBackgroundShow) then
								HideColorPicker()
								LCframeplayer2.iconInterruptBackground:Hide()
							end
						end)
					end
				end
				self:ClearFocus()
			else
				self:SetText(mathfloor(((frame.interruptBackgroundVertexColor.b * 255) or 0)+0.5))
				self:ClearFocus()
			end
		end
	end)
	ColorPickerBackgroundInterruptBEditBox:SetScript("OnDisable", function(self)
		self:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		self.labelObj:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end)
	ColorPickerBackgroundInterruptBEditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
		self.labelObj:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end)
	
	function ColorPickerBackgroundInterrupt.texture:UpdateColor(frame)
		self:SetVertexColor(frame.interruptBackgroundVertexColor.r, frame.interruptBackgroundVertexColor.g, frame.interruptBackgroundVertexColor.b)
		ColorPickerBackgroundInterruptREditBox:SetText(mathfloor(frame.interruptBackgroundVertexColor.r * 255 + 0.5))
		ColorPickerBackgroundInterruptREditBox:SetCursorPosition(0)
		ColorPickerBackgroundInterruptGEditBox:SetText(mathfloor(frame.interruptBackgroundVertexColor.g * 255 + 0.5))
		ColorPickerBackgroundInterruptGEditBox:SetCursorPosition(0)
		ColorPickerBackgroundInterruptBEditBox:SetText(mathfloor(frame.interruptBackgroundVertexColor.b * 255 + 0.5))
		ColorPickerBackgroundInterruptBEditBox:SetCursorPosition(0)
	end

	local catListEnChecksButtons = { "PvE", "Immune", "ImmuneSpell", "ImmunePhysical", "CC", "Silence", "Disarm", "Root", "Snare", "Other" }
	local CategoriesCheckButtons = { }
	local FriendlyInterrupt = CreateFrame("CheckButton", O..v.."FriendlyInterrupt", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
	FriendlyInterrupt:SetHitRectInsets(0, -36, 0, 0)
	_G[O..v.."FriendlyInterruptText"]:SetText(L["CatFriendly"])
	FriendlyInterrupt:SetScript("OnClick", function(self)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].categoriesEnabled.interrupt.friendly = self:GetChecked()
			LCframes[frame].maxExpirationTime = 0
			if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
			end
		end
	end)
	tblinsert(CategoriesCheckButtons, { frame = FriendlyInterrupt, auraType = "interrupt", reaction = "friendly", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = 140, yPos = 5 })
	if v == "target" or v == "targettarget" then
		local EnemyInterrupt = CreateFrame("CheckButton", O..v.."EnemyInterrupt", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		EnemyInterrupt:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."EnemyInterruptText"]:SetText(L["CatEnemy"])
		EnemyInterrupt:SetScript("OnClick", function(self)
			LoseControlDB.frames[v].categoriesEnabled.interrupt.enemy = self:GetChecked()
			LCframes[v].maxExpirationTime = 0
			if LoseControlDB.frames[v].enabled and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
			end
		end)
		tblinsert(CategoriesCheckButtons, { frame = EnemyInterrupt, auraType = "interrupt", reaction = "enemy", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = 270, yPos = 5 })
	end
	for _, cat in pairs(catListEnChecksButtons) do
		local FriendlyBuff = CreateFrame("CheckButton", O..v.."Friendly"..cat.."Buff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		FriendlyBuff:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."Friendly"..cat.."BuffText"]:SetText(L["CatFriendlyBuff"])
		FriendlyBuff:SetScript("OnClick", function(self)
			local frames = { v }
			if v == "party" then
				frames = { "party1", "party2", "party3", "party4", "partyplayer" }
			elseif v == "raid" then
				frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
			end
			for _, frame in ipairs(frames) do
				LoseControlDB.frames[frame].categoriesEnabled.buff.friendly[cat] = self:GetChecked()
				LCframes[frame].maxExpirationTime = 0
				if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
				end
			end
		end)
		tblinsert(CategoriesCheckButtons, { frame = FriendlyBuff, auraType = "buff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 140, yPos = 5 })
		local FriendlyDebuff = CreateFrame("CheckButton", O..v.."Friendly"..cat.."Debuff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		FriendlyDebuff:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."Friendly"..cat.."DebuffText"]:SetText(L["CatFriendlyDebuff"])
		FriendlyDebuff:SetScript("OnClick", function(self)
			local frames = { v }
			if v == "party" then
				frames = { "party1", "party2", "party3", "party4", "partyplayer" }
			elseif v == "raid" then
				frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
			end
			for _, frame in ipairs(frames) do
				LoseControlDB.frames[frame].categoriesEnabled.debuff.friendly[cat] = self:GetChecked()
				LCframes[frame].maxExpirationTime = 0
				if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
				end
			end
		end)
		tblinsert(CategoriesCheckButtons, { frame = FriendlyDebuff, auraType = "debuff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 205, yPos = 5 })
		if v == "target" or v == "targettarget" then
			local EnemyBuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Buff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			EnemyBuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Enemy"..cat.."BuffText"]:SetText(L["CatEnemyBuff"])
			EnemyBuff:SetScript("OnClick", function(self)
				LoseControlDB.frames[v].categoriesEnabled.buff.enemy[cat] = self:GetChecked()
				LCframes[v].maxExpirationTime = 0
				if LoseControlDB.frames[v].enabled and not LCframes[v].unlockMode then
					LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = EnemyBuff, auraType = "buff", reaction = "enemy", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 270, yPos = 5 })
		end
		if v == "target" or v == "targettarget" then
			local EnemyDebuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Debuff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			EnemyDebuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Enemy"..cat.."DebuffText"]:SetText(L["CatEnemyDebuff"])
			EnemyDebuff:SetScript("OnClick", function(self)
				LoseControlDB.frames[v].categoriesEnabled.debuff.enemy[cat] = self:GetChecked()
				LCframes[v].maxExpirationTime = 0
				if LoseControlDB.frames[v].enabled and not LCframes[v].unlockMode then
					LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = EnemyDebuff, auraType = "debuff", reaction = "enemy", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 335, yPos = 5 })
		end
	end

	local CategoriesCheckButtonsPlayer2
	if (v == "player") then
		CategoriesCheckButtonsPlayer2 = { }
		local FriendlyInterruptPlayer2 = CreateFrame("CheckButton", O..v.."FriendlyInterruptPlayer2", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		FriendlyInterruptPlayer2:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."FriendlyInterruptPlayer2Text"]:SetText(L["CatFriendly"].."|cfff28614(Icon2)|r")
		FriendlyInterruptPlayer2:SetScript("OnClick", function(self)
			LoseControlDB.frames.player2.categoriesEnabled.interrupt.friendly = self:GetChecked()
			LCframeplayer2.maxExpirationTime = 0
			if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
				LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
			end
		end)
		tblinsert(CategoriesCheckButtonsPlayer2, { frame = FriendlyInterruptPlayer2, auraType = "interrupt", reaction = "friendly", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = 310, yPos = 5 })
		for _, cat in pairs(catListEnChecksButtons) do
			local FriendlyBuffPlayer2 = CreateFrame("CheckButton", O..v.."Friendly"..cat.."BuffPlayer2", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			FriendlyBuffPlayer2:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."BuffPlayer2Text"]:SetText(L["CatFriendlyBuff"].."|cfff28614(Icon2)|r")
			FriendlyBuffPlayer2:SetScript("OnClick", function(self)
				LoseControlDB.frames.player2.categoriesEnabled.buff.friendly[cat] = self:GetChecked()
				LCframeplayer2.maxExpirationTime = 0
				if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
				end
			end)
			tblinsert(CategoriesCheckButtonsPlayer2, { frame = FriendlyBuffPlayer2, auraType = "buff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 310, yPos = 5 })
			local FriendlyDebuffPlayer2 = CreateFrame("CheckButton", O..v.."Friendly"..cat.."DebuffPlayer2", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			FriendlyDebuffPlayer2:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."DebuffPlayer2Text"]:SetText(L["CatFriendlyDebuff"].."|cfff28614(Icon2)|r")
			FriendlyDebuffPlayer2:SetScript("OnClick", function(self)
				LoseControlDB.frames.player2.categoriesEnabled.debuff.friendly[cat] = self:GetChecked()
				LCframeplayer2.maxExpirationTime = 0
				if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
				end
			end)
			tblinsert(CategoriesCheckButtonsPlayer2, { frame = FriendlyDebuffPlayer2, auraType = "debuff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 419, yPos = 5 })
		end
	end

	local DuplicatePlayerPortrait
	if v == "player" then
		DuplicatePlayerPortrait = CreateFrame("CheckButton", O..v.."DuplicatePlayerPortrait", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DuplicatePlayerPortraitText"]:SetText(L["DuplicatePlayerPortrait"])
		function DuplicatePlayerPortrait:Check(value)
			LoseControlDB.duplicatePlayerPortrait = self:GetChecked()
			local enable = LoseControlDB.duplicatePlayerPortrait and LoseControlDB.frames.player.enabled
			if AlphaSlider2 then
				if enable then
					BlizzardOptionsPanel_Slider_Enable(AlphaSlider2)
					if AlphaSlider2.editbox then AlphaSlider2.editbox:Enable() end
				else
					BlizzardOptionsPanel_Slider_Disable(AlphaSlider2)
					if AlphaSlider2.editbox then AlphaSlider2.editbox:Disable() end
				end
			end
			if SizeSlider2 then
				if enable then
					BlizzardOptionsPanel_Slider_Enable(SizeSlider2)
					if SizeSlider2.editbox then SizeSlider2.editbox:Enable() end
				else
					BlizzardOptionsPanel_Slider_Disable(SizeSlider2)
					if SizeSlider2.editbox then SizeSlider2.editbox:Disable() end
				end
			end
			if AnchorDropDown2 then
				if enable then
					UIDropDownMenu_EnableDropDown(AnchorDropDown2)
				else
					UIDropDownMenu_DisableDropDown(AnchorDropDown2)
				end
			end
			if CategoriesCheckButtonsPlayer2 then
				if enable then
					for _, checkbuttonframeplayer2 in pairs(CategoriesCheckButtonsPlayer2) do
						BlizzardOptionsPanel_CheckButton_Enable(checkbuttonframeplayer2.frame)
					end
				else
					for _, checkbuttonframeplayer2 in pairs(CategoriesCheckButtonsPlayer2) do
						BlizzardOptionsPanel_CheckButton_Disable(checkbuttonframeplayer2.frame)
					end
				end
			end
			LoseControlDB.frames.player2.enabled = enable
			LCframeplayer2.maxExpirationTime = 0
			LCframeplayer2:RegisterUnitEvents(enable)
			if self:GetChecked() and LoseControlDB.frames.player.anchor ~= "None" then
				local frame = LoseControlDB.frames["player"]
				frame.anchor = "None"
				local AnchorDropDown = _G['LoseControlOptionsPanel'..LCframes.player.unitId..'AnchorDropDown']
				if (AnchorDropDown) then
					UIDropDownMenu_Initialize(AnchorDropDown, AnchorDropDown.initialize)
					UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
				end
				LCframes.player.texture:SetTexture(LCframes.player.textureicon)
				LCframes.player:SetSwipeColor(0, 0, 0, 0.8)
				LCframes.player.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
				if LCframes.player.MasqueGroup then
					LCframes.player.MasqueGroup:RemoveButton(LCframes.player:GetParent())
					HideTheButtonDefaultSkin(LCframes.player:GetParent())
					LCframes.player.MasqueGroup:AddButton(LCframes.player:GetParent(), {
						FloatingBG = false,
						Icon = LCframes.player.texture,
						Cooldown = LCframes.player,
						Flash = _G[LCframes.player:GetParent():GetName().."Flash"],
						Pushed = LCframes.player:GetParent():GetPushedTexture(),
						Normal = LCframes.player:GetParent():GetNormalTexture(),
						Disabled = LCframes.player:GetParent():GetDisabledTexture(),
						Checked = false,
						Border = _G[LCframes.player:GetParent():GetName().."Border"],
						AutoCastable = false,
						Highlight = LCframes.player:GetParent():GetHighlightTexture(),
						Hotkey = _G[LCframes.player:GetParent():GetName().."HotKey"],
						Count = _G[LCframes.player:GetParent():GetName().."Count"],
						Name = _G[LCframes.player:GetParent():GetName().."Name"],
						Duration = false,
						Shine = _G[LCframes.player:GetParent():GetName().."Shine"],
					}, "Button", true)
				end
				LCframes.player.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][LCframes.player.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframes.player.unitId])=="string") and _GF(anchors[frame.anchor][LCframes.player.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframes.player.unitId])=="table") and anchors[frame.anchor][LCframes.player.unitId] or UIParent))
				LCframes.player.parent:SetParent(LCframes.player.anchor:GetParent())
				LCframes.player.defaultFrameStrata = LCframes.player:GetFrameStrata()
				LCframes.player:ClearAllPoints()
				LCframes.player:SetPoint(
					"CENTER",
					LCframes.player.anchor,
					"CENTER",
					0,
					0
				)
				LCframes.player:GetParent():SetPoint(
					"CENTER",
					LCframes.player.anchor,
					"CENTER",
					0,
					0
				)
				local PositionXEditBox = _G['LoseControlOptionsPanel'..LCframes.player.unitId..'PositionXEditBox']
				local PositionYEditBox = _G['LoseControlOptionsPanel'..LCframes.player.unitId..'PositionYEditBox']
				local FrameLevelEditBox = _G['LoseControlOptionsPanel'..LCframes.player.unitId..'FrameLevelEditBox']
				if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
					PositionXEditBox:SetText(0)
					PositionYEditBox:SetText(0)
					FrameLevelEditBox:SetText(0)
					if (frame.anchor ~= "Blizzard") then
						PositionXEditBox:Enable()
						PositionYEditBox:Enable()
						FrameLevelEditBox:Enable()
					end
					PositionXEditBox:SetCursorPosition(0)
					PositionYEditBox:SetCursorPosition(0)
					FrameLevelEditBox:SetCursorPosition(0)
				end
				local AnchorPointDropDown = _G['LoseControlOptionsPanel'..LCframes.player.unitId..'AnchorPointDropDown']
				if (AnchorPointDropDown) then
					UIDropDownMenu_Initialize(AnchorPointDropDown, AnchorPointDropDown.initialize)
					UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, "CENTER")
					if (frame.anchor ~= "Blizzard") then
						UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
					end
				end
				local AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..LCframes.player.unitId..'AnchorIconPointDropDown']
				if (AnchorIconPointDropDown) then
					UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
					UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, "CENTER")
					if (frame.anchor ~= "Blizzard") then
						UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
					end
				end
				local AnchorFrameStrataDropDown = _G['LoseControlOptionsPanel'..LCframes.player.unitId..'AnchorFrameStrataDropDown']
				if (AnchorFrameStrataDropDown) then
					UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
					UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, "AUTO")
					if (frame.anchor ~= "Blizzard") then
						UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
					end
				end
				if (frame.frameStrata ~= nil) then
					LCframes.player:GetParent():SetFrameStrata(frame.frameStrata)
					LCframes.player:SetFrameStrata(frame.frameStrata)
				end
				local frameLevel = (LCframes.player.anchor:GetParent() and LCframes.player.anchor:GetParent():GetFrameLevel() or LCframes.player.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard") and (12 + frame.frameLevel) or 0)
				if frameLevel < 0 then frameLevel = 0 end
				LCframes.player:GetParent():SetFrameLevel(frameLevel)
				LCframes.player:SetFrameLevel(frameLevel)
				if LCframes.player.MasqueGroup then
					LCframes.player.MasqueGroup:ReSkin()
				end
			end
			if enable and not LCframeplayer2.unlockMode then
				LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
			elseif Unlock:GetChecked() then
				Unlock:OnClick()
			end
		end
		DuplicatePlayerPortrait:SetScript("OnClick", function(self)
			DuplicatePlayerPortrait:Check(self:GetChecked())
		end)
	end

	local EnabledPartyPlayerIcon
	if v == "party" then
		EnabledPartyPlayerIcon = CreateFrame("CheckButton", O..v.."EnabledPartyPlayerIcon", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."EnabledPartyPlayerIconText"]:SetText(L["EnabledPartyPlayerIcon"])
		function EnabledPartyPlayerIcon:Check(value)
			local enabled = self:GetChecked()
			LoseControlDB.showPartyplayerIcon = enabled
			LoseControlDB.frames.partyplayer.enabled = enabled
			local enable = enabled and LCframes.partyplayer:GetEnabled()
			LCframes.partyplayer.maxExpirationTime = 0
			LCframes.partyplayer:RegisterUnitEvents(enable)
			if ((AnchorPositionPartyDropDown ~= nil) and (UIDropDownMenu_GetSelectedValue(AnchorPositionPartyDropDown)==LCframes.partyplayer.fakeUnitId)) then
				UIDropDownMenu_Initialize(AnchorPositionPartyDropDown, AnchorPositionPartyDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorPositionPartyDropDown, "party1")
				AnchorPositionPartyDropDown:OnClick()
			end
			if enable and not LCframes.partyplayer.unlockMode then
				LCframes.partyplayer:UNIT_AURA(LCframes.partyplayer.unitId, 0)
			elseif Unlock:GetChecked() then
				Unlock:OnClick()
			end
		end
		EnabledPartyPlayerIcon:SetScript("OnClick", function(self)
			EnabledPartyPlayerIcon:Check(self:GetChecked())
		end)
	end

	local function EnableInterfaceFrames(frame)
		if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
		if DisableInRaid then BlizzardOptionsPanel_CheckButton_Enable(DisableInRaid) end
		if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Enable(ShowNPCInterrupts) end
		if DisablePlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisablePlayerTargetTarget) end
		if DisableTargetTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisableTargetTargetTarget) end
		if DisablePlayerTargetPlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisablePlayerTargetPlayerTargetTarget) end
		if DisableTargetDeadTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisableTargetDeadTargetTarget) end
		if DuplicatePlayerPortrait then BlizzardOptionsPanel_CheckButton_Enable(DuplicatePlayerPortrait) end
		if EnabledPartyPlayerIcon then BlizzardOptionsPanel_CheckButton_Enable(EnabledPartyPlayerIcon) end
		for _, checkbuttonframe in pairs(CategoriesCheckButtons) do
			BlizzardOptionsPanel_CheckButton_Enable(checkbuttonframe.frame)
		end
		if CategoriesCheckButtonsPlayer2 then
			if LoseControlDB.duplicatePlayerPortrait then
				for _, checkbuttonframeplayer2 in pairs(CategoriesCheckButtonsPlayer2) do
					BlizzardOptionsPanel_CheckButton_Enable(checkbuttonframeplayer2.frame)
				end
			else
				for _, checkbuttonframeplayer2 in pairs(CategoriesCheckButtonsPlayer2) do
					BlizzardOptionsPanel_CheckButton_Disable(checkbuttonframeplayer2.frame)
				end
			end
		end
		CategoriesEnabledLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledInterruptLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledPvELabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledImmuneLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledImmuneSpellLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledImmunePhysicalLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledCCLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledSilenceLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledDisarmLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledRootLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledSnareLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		CategoryEnabledOtherLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		PositionEditBoxLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		AdditionalOptionsLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		InterruptBackgroundColorLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		BlizzardOptionsPanel_Slider_Enable(SizeSlider)
		BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		BlizzardOptionsPanel_Slider_Enable(AlphaSliderBackgroundInterrupt)
		BlizzardOptionsPanel_Slider_Enable(AlphaSliderInterruptMiniIcons)
		ColorPickerBackgroundInterrupt:Enable()
		ColorPickerBackgroundInterruptREditBox:Enable()
		ColorPickerBackgroundInterruptGEditBox:Enable()
		ColorPickerBackgroundInterruptBEditBox:Enable()
		SizeSlider.editbox:Enable()
		AlphaSlider.editbox:Enable()
		AlphaSliderBackgroundInterrupt.editbox:Enable()
		AlphaSliderInterruptMiniIcons.editbox:Enable()
		UIDropDownMenu_EnableDropDown(AnchorDropDown)
		if LoseControlDB.duplicatePlayerPortrait then
			if AlphaSlider2 then
				BlizzardOptionsPanel_Slider_Enable(AlphaSlider2)
				if AlphaSlider2.editbox then AlphaSlider2.editbox:Enable() end
			end
			if SizeSlider2 then
				BlizzardOptionsPanel_Slider_Enable(SizeSlider2)
				if SizeSlider2.editbox then SizeSlider2.editbox:Enable() end
			end
			if AnchorDropDown2 then UIDropDownMenu_EnableDropDown(AnchorDropDown2) end
		else
			if AlphaSlider2 then
				BlizzardOptionsPanel_Slider_Disable(AlphaSlider2)
				if AlphaSlider2.editbox then AlphaSlider2.editbox:Disable() end
			end
			if SizeSlider2 then
				BlizzardOptionsPanel_Slider_Disable(SizeSlider2)
				if SizeSlider2.editbox then SizeSlider2.editbox:Disable() end
			end
			if AnchorDropDown2 then UIDropDownMenu_DisableDropDown(AnchorDropDown2) end
		end
		if AnchorPositionPartyDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionPartyDropDown) end
		if AnchorPositionRaidDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionRaidDropDown) end
		if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
			if (frame.anchor ~= "Blizzard") then
				PositionXEditBox:Enable()
				PositionYEditBox:Enable()
				FrameLevelEditBox:Enable()
			else
				PositionXEditBox:Disable()
				PositionYEditBox:Disable()
				FrameLevelEditBox:Disable()
			end
		end
		if (AnchorPointDropDown) then
			if (frame.anchor ~= "Blizzard") then
				UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
			else
				UIDropDownMenu_DisableDropDown(AnchorPointDropDown)
			end
		end
		if (AnchorIconPointDropDown) then
			if (frame.anchor ~= "Blizzard") then
				UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
			else
				UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown)
			end
		end
		if (AnchorFrameStrataDropDown) then
			if (frame.anchor ~= "Blizzard") then
				UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
			else
				UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown)
			end
		end
	end

	local function DisableInterfaceFrames()
		if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
		if DisableInRaid then BlizzardOptionsPanel_CheckButton_Disable(DisableInRaid) end
		if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Disable(ShowNPCInterrupts) end
		if DisablePlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisablePlayerTargetTarget) end
		if DisableTargetTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisableTargetTargetTarget) end
		if DisablePlayerTargetPlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisablePlayerTargetPlayerTargetTarget) end
		if DisableTargetDeadTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisableTargetDeadTargetTarget) end
		if DuplicatePlayerPortrait then BlizzardOptionsPanel_CheckButton_Disable(DuplicatePlayerPortrait) end
		if EnabledPartyPlayerIcon then BlizzardOptionsPanel_CheckButton_Disable(EnabledPartyPlayerIcon) end
		for _, checkbuttonframe in pairs(CategoriesCheckButtons) do
			BlizzardOptionsPanel_CheckButton_Disable(checkbuttonframe.frame)
		end
		if CategoriesCheckButtonsPlayer2 then
			for _, checkbuttonframeplayer2 in pairs(CategoriesCheckButtonsPlayer2) do
				BlizzardOptionsPanel_CheckButton_Disable(checkbuttonframeplayer2.frame)
			end
		end
		CategoriesEnabledLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledInterruptLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledPvELabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledImmuneLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledImmuneSpellLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledImmunePhysicalLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledCCLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledSilenceLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledDisarmLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledRootLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledSnareLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		CategoryEnabledOtherLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		PositionEditBoxLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		AdditionalOptionsLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		InterruptBackgroundColorLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		BlizzardOptionsPanel_Slider_Disable(SizeSlider)
		BlizzardOptionsPanel_Slider_Disable(AlphaSlider)
		BlizzardOptionsPanel_Slider_Disable(AlphaSliderBackgroundInterrupt)
		BlizzardOptionsPanel_Slider_Disable(AlphaSliderInterruptMiniIcons)
		ColorPickerBackgroundInterrupt:Disable()
		ColorPickerBackgroundInterruptREditBox:Disable()
		ColorPickerBackgroundInterruptGEditBox:Disable()
		ColorPickerBackgroundInterruptBEditBox:Disable()
		HideColorPicker()
		SizeSlider.editbox:Disable()
		AlphaSlider.editbox:Disable()
		AlphaSliderBackgroundInterrupt.editbox:Disable()
		AlphaSliderInterruptMiniIcons.editbox:Disable()
		UIDropDownMenu_DisableDropDown(AnchorDropDown)
		if AlphaSlider2 then
			BlizzardOptionsPanel_Slider_Disable(AlphaSlider2)
			if AlphaSlider2.editbox then AlphaSlider2.editbox:Disable() end
		end
		if SizeSlider2 then
			BlizzardOptionsPanel_Slider_Disable(SizeSlider2)
			if SizeSlider2.editbox then SizeSlider2.editbox:Disable() end
		end
		if AnchorDropDown2 then UIDropDownMenu_DisableDropDown(AnchorDropDown2) end
		if AnchorPositionPartyDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionPartyDropDown) end
		if AnchorPositionRaidDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionRaidDropDown) end
		if PositionXEditBox then
			PositionXEditBox:Disable()
		end
		if PositionYEditBox then
			PositionYEditBox:Disable()
		end
		if FrameLevelEditBox then
			FrameLevelEditBox:Disable()
		end
		if AnchorPointDropDown then UIDropDownMenu_DisableDropDown(AnchorPointDropDown) end
		if AnchorIconPointDropDown then UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown) end
		if AnchorFrameStrataDropDown then UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown) end
	end

	local Enabled = CreateFrame("CheckButton", O..v.."Enabled", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
	_G[O..v.."EnabledText"]:SetText(L["Enabled"])
	Enabled:SetScript("OnClick", function(self)
		local enabled = self:GetChecked()
		if enabled then
			local unitIdSel = v
			if (v == "party") then
				unitIdSel = (AnchorPositionPartyDropDown ~= nil) and UIDropDownMenu_GetSelectedValue(AnchorPositionPartyDropDown) or "party1"
			elseif (v == "raid") then
				unitIdSel = (AnchorPositionRaidDropDown ~= nil) and UIDropDownMenu_GetSelectedValue(AnchorPositionRaidDropDown) or "raid1"
			end
			EnableInterfaceFrames(LoseControlDB.frames[unitIdSel])
		else
			DisableInterfaceFrames()
		end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			if (frame == "partyplayer") then
				LoseControlDB.frames[frame].enabled = enabled and LoseControlDB.showPartyplayerIcon
			else
				LoseControlDB.frames[frame].enabled = enabled
			end
			local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
			LCframes[frame].maxExpirationTime = 0
			LCframes[frame]:RegisterUnitEvents(enable)
			if enable and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.enabled = enabled and LoseControlDB.duplicatePlayerPortrait
				LCframeplayer2.maxExpirationTime = 0
				LCframeplayer2:RegisterUnitEvents(enabled and LoseControlDB.duplicatePlayerPortrait)
				if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
				end
			end
		end
		if (v == "raid" and enabled) then
			MainHookCompactRaidFrames()
		end
		if Unlock:GetChecked() then
			Unlock:OnClick()
		end
	end)

	Enabled:SetPoint("TOPLEFT", 16, -32)
	if DisableInBG then DisableInBG:SetPoint("TOPLEFT", Enabled, 225, ((v == "party") and -25 or 0)) end
	if DisableInRaid then DisableInRaid:SetPoint("TOPLEFT", Enabled, 225, ((v == "party") and -50 or -25)) end
	if ShowNPCInterrupts then ShowNPCInterrupts:SetPoint("TOPLEFT", Enabled, 225, 0) end
	if DisablePlayerTargetTarget then DisablePlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -25) end
	if DisableTargetTargetTarget then DisableTargetTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -50) end
	if DisablePlayerTargetPlayerTargetTarget then DisablePlayerTargetPlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -75) end
	if DisableTargetDeadTargetTarget then DisableTargetDeadTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -100) end
	if DuplicatePlayerPortrait then DuplicatePlayerPortrait:SetPoint("TOPLEFT", Enabled, 300, 0) end
	if EnabledPartyPlayerIcon then EnabledPartyPlayerIcon:SetPoint("TOPLEFT", Enabled, 225, 0) end
	SizeSlider:SetPoint("TOPLEFT", Enabled, "BOTTOMLEFT", 0, -32)
	AlphaSlider:SetPoint("TOPLEFT", SizeSlider, "BOTTOMLEFT", 0, -32)
	AnchorDropDownLabel:SetPoint("TOPLEFT", AlphaSlider, "BOTTOMLEFT", 0, -12)
	AnchorDropDown:SetPoint("TOPLEFT", AnchorDropDownLabel, "BOTTOMLEFT", 0, -8)
	PositionEditBoxLabel:SetPoint("TOPLEFT", AnchorDropDown, "BOTTOMLEFT", 0, -4)
	PositionXEditBoxLabel:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 10, -9)
	PositionXEditBox:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 27, -3)
	PositionYEditBoxLabel:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 90, -9)
	PositionYEditBox:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 107, -3)
	if AnchorPositionPartyDropDown then AnchorPositionPartyDropDown:SetPoint("RIGHT", PositionYEditBox, "RIGHT", 30, 0) end
	if AnchorPositionRaidDropDown then AnchorPositionRaidDropDown:SetPoint("RIGHT", PositionYEditBox, "RIGHT", 30, 0) end
	AnchorPointDropDownLabel:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 10, -37)
	AnchorPointDropDown:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 39, -30)
	AnchorIconPointDropDownLabel:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 200, -37)
	AnchorIconPointDropDown:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 265, -30)
	AnchorFrameStrataDropDownLabel:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 10, -67)
	AnchorFrameStrataDropDown:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 66, -60)
	FrameLevelEditBoxLabel:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 252, -69)
	FrameLevelEditBox:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 327, -63)
	CategoriesEnabledLabel:SetPoint("TOPLEFT", AnchorPointDropDownLabel, "BOTTOMLEFT", -10, -49)
	CategoryEnabledInterruptLabel:SetPoint("TOPLEFT", CategoriesEnabledLabel, "BOTTOMLEFT", 0, -12)
	CategoryEnabledPvELabel:SetPoint("TOPLEFT", CategoryEnabledInterruptLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledImmuneLabel:SetPoint("TOPLEFT", CategoryEnabledPvELabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledImmuneSpellLabel:SetPoint("TOPLEFT", CategoryEnabledImmuneLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledImmunePhysicalLabel:SetPoint("TOPLEFT", CategoryEnabledImmuneSpellLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledCCLabel:SetPoint("TOPLEFT", CategoryEnabledImmunePhysicalLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledSilenceLabel:SetPoint("TOPLEFT", CategoryEnabledCCLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledDisarmLabel:SetPoint("TOPLEFT", CategoryEnabledSilenceLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledRootLabel:SetPoint("TOPLEFT", CategoryEnabledDisarmLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledSnareLabel:SetPoint("TOPLEFT", CategoryEnabledRootLabel, "BOTTOMLEFT", 0, -8)
	CategoryEnabledOtherLabel:SetPoint("TOPLEFT", CategoryEnabledSnareLabel, "BOTTOMLEFT", 0, -8)
	AdditionalOptionsLabel:SetPoint("TOPLEFT", CategoryEnabledOtherLabel, "BOTTOMLEFT", 0, -20)
	AlphaSliderBackgroundInterrupt:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 20, -20)
	InterruptBackgroundColorLabel:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 16, -50)
	ColorPickerBackgroundInterrupt:SetPoint("TOPLEFT", InterruptBackgroundColorLabel, "BOTTOMLEFT", 10, -7)
	ColorPickerBackgroundInterruptREditBoxLabel:SetPoint("TOPLEFT", ColorPickerBackgroundInterrupt, "BOTTOMLEFT", 36, 20)
	ColorPickerBackgroundInterruptREditBox:SetPoint("TOPLEFT", ColorPickerBackgroundInterrupt, "BOTTOMLEFT", 54, 26)
	ColorPickerBackgroundInterruptGEditBoxLabel:SetPoint("TOPLEFT", ColorPickerBackgroundInterrupt, "BOTTOMLEFT", 89, 20)
	ColorPickerBackgroundInterruptGEditBox:SetPoint("TOPLEFT", ColorPickerBackgroundInterrupt, "BOTTOMLEFT", 107, 26)
	ColorPickerBackgroundInterruptBEditBoxLabel:SetPoint("TOPLEFT", ColorPickerBackgroundInterrupt, "BOTTOMLEFT", 142, 20)
	ColorPickerBackgroundInterruptBEditBox:SetPoint("TOPLEFT", ColorPickerBackgroundInterrupt, "BOTTOMLEFT", 160, 26)
	AlphaSliderInterruptMiniIcons:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 310, -20)
	if SizeSlider2 then SizeSlider2:SetPoint("TOPLEFT", Enabled, "BOTTOMLEFT", 300, -32) end
	if AlphaSlider2 then AlphaSlider2:SetPoint("TOPLEFT", SizeSlider2, "BOTTOMLEFT", 0, -32) end
	if AnchorDropDown2Label then AnchorDropDown2Label:SetPoint("TOPLEFT", AlphaSlider2, "BOTTOMLEFT", 0, -12) end
	if AnchorDropDown2 then AnchorDropDown2:SetPoint("TOPLEFT", AnchorDropDown2Label, "BOTTOMLEFT", 0, -8) end
	for _, checkbuttonframe in pairs(CategoriesCheckButtons) do
		checkbuttonframe.frame:SetPoint("TOPLEFT", checkbuttonframe.anchorPos, checkbuttonframe.xPos, checkbuttonframe.yPos)
	end
	if CategoriesCheckButtonsPlayer2 then
		for _, checkbuttonframeplayer2 in pairs(CategoriesCheckButtonsPlayer2) do
			checkbuttonframeplayer2.frame:SetPoint("TOPLEFT", checkbuttonframeplayer2.anchorPos, checkbuttonframeplayer2.xPos, checkbuttonframeplayer2.yPos)
		end
	end

	OptionsPanelFrame.default = OptionsPanel.default
	OptionsPanelFrame.refresh = function()
		local unitId = v
		if unitId == "party" then
			DisableInBG:SetChecked(LoseControlDB.disablePartyInBG)
			DisableInRaid:SetChecked(LoseControlDB.disablePartyInRaid)
			EnabledPartyPlayerIcon:SetChecked(LoseControlDB.showPartyplayerIcon)
			unitId = "party1"
		elseif unitId == "player" then
			DuplicatePlayerPortrait:SetChecked(LoseControlDB.duplicatePlayerPortrait)
			AlphaSlider2:SetValue(LoseControlDB.frames.player2.alpha * 100)
			AlphaSlider2.editbox:SetText(LoseControlDB.frames.player2.alpha * 100)
			AlphaSlider2.editbox:SetCursorPosition(0)
			SizeSlider2:SetValue(LoseControlDB.frames.player2.size)
			SizeSlider2.editbox:SetText(LoseControlDB.frames.player2.size)
			SizeSlider2.editbox:SetCursorPosition(0)
		elseif unitId == "target" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsTarget)
		elseif unitId == "targettarget" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsTargetTarget)
			DisablePlayerTargetTarget:SetChecked(LoseControlDB.disablePlayerTargetTarget)
			DisableTargetTargetTarget:SetChecked(LoseControlDB.disableTargetTargetTarget)
			DisablePlayerTargetPlayerTargetTarget:SetChecked(LoseControlDB.disablePlayerTargetPlayerTargetTarget)
			DisableTargetDeadTargetTarget:SetChecked(LoseControlDB.disableTargetDeadTargetTarget)
		elseif unitId == "raid" then
			DisableInBG:SetChecked(LoseControlDB.disableRaidInBG)
			unitId = "raid1"
		end
		LCframes[unitId]:CheckAnchor(true)
		for _, checkbuttonframe in pairs(CategoriesCheckButtons) do
			if checkbuttonframe.auraType ~= "interrupt" then
				checkbuttonframe.frame:SetChecked(LoseControlDB.frames[unitId].categoriesEnabled[checkbuttonframe.auraType][checkbuttonframe.reaction][checkbuttonframe.categoryType])
			else
				checkbuttonframe.frame:SetChecked(LoseControlDB.frames[unitId].categoriesEnabled[checkbuttonframe.auraType][checkbuttonframe.reaction])
			end
		end
		if CategoriesCheckButtonsPlayer2 then
			for _, checkbuttonframeplayer2 in pairs(CategoriesCheckButtonsPlayer2) do
				if checkbuttonframeplayer2.auraType ~= "interrupt" then
					checkbuttonframeplayer2.frame:SetChecked(LoseControlDB.frames.player2.categoriesEnabled[checkbuttonframeplayer2.auraType][checkbuttonframeplayer2.reaction][checkbuttonframeplayer2.categoryType])
				else
					checkbuttonframeplayer2.frame:SetChecked(LoseControlDB.frames.player2.categoriesEnabled[checkbuttonframeplayer2.auraType][checkbuttonframeplayer2.reaction])
				end
			end
		end
		local frame = LoseControlDB.frames[unitId]
		Enabled:SetChecked(frame.enabled)
		if frame.enabled then
			EnableInterfaceFrames(frame)
		else
			DisableInterfaceFrames()
		end
		SizeSlider:SetValue(frame.size)
		SizeSlider.editbox:SetText(frame.size)
		SizeSlider.editbox:SetCursorPosition(0)
		AlphaSlider:SetValue(frame.alpha * 100)
		AlphaSlider.editbox:SetText(frame.alpha * 100)
		AlphaSlider.editbox:SetCursorPosition(0)
		AlphaSliderBackgroundInterrupt.timerEnabled = false
		AlphaSliderBackgroundInterrupt:SetValue(frame.interruptBackgroundAlpha * 100)
		AlphaSliderBackgroundInterrupt.timerEnabled = true
		AlphaSliderBackgroundInterrupt.editbox:SetText(frame.interruptBackgroundAlpha * 100)
		AlphaSliderBackgroundInterrupt.editbox:SetCursorPosition(0)
		AlphaSliderInterruptMiniIcons.timerEnabled = false
		AlphaSliderInterruptMiniIcons:SetValue(frame.interruptMiniIconsAlpha * 100)
		AlphaSliderInterruptMiniIcons.timerEnabled = true
		AlphaSliderInterruptMiniIcons.editbox:SetText(frame.interruptMiniIconsAlpha * 100)
		AlphaSliderInterruptMiniIcons.editbox:SetCursorPosition(0)
		ColorPickerBackgroundInterrupt.texture:UpdateColor(frame)
		if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
			PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
			PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
			FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
			PositionXEditBox:SetCursorPosition(0)
			PositionYEditBox:SetCursorPosition(0)
			FrameLevelEditBox:SetCursorPosition(0)
			PositionXEditBox:ClearFocus()
			PositionYEditBox:ClearFocus()
			FrameLevelEditBox:ClearFocus()
		end
		UIDropDownMenu_Initialize(AnchorDropDown, function() -- called on refresh and also every time the drop down menu is opened
			AddItem(AnchorDropDown, L["None"], "None")
			if not(strfind(unitId, "raid")) then
				AddItem(AnchorDropDown, "Blizzard", "Blizzard")
			else
				AddItem(AnchorDropDown, "Blizzard", "BlizzardRaidFrames")
			end
			if _G[anchors["Perl"][unitId]] or (type(anchors["Perl"][unitId])=="table" and anchors["Perl"][unitId]) or (type(anchors["Perl"][unitId])=="string" and _GF(anchors["Perl"][unitId])) then AddItem(AnchorDropDown, "Perl", "Perl") end
			if _G[anchors["XPerl"][unitId]] or (type(anchors["XPerl"][unitId])=="table" and anchors["XPerl"][unitId]) or (type(anchors["XPerl"][unitId])=="string" and _GF(anchors["XPerl"][unitId])) then AddItem(AnchorDropDown, "XPerl", "XPerl") end
			if _G[anchors["LUI"][unitId]] or (type(anchors["LUI"][unitId])=="table" and anchors["LUI"][unitId]) or (type(anchors["LUI"][unitId])=="string" and _GF(anchors["LUI"][unitId])) then AddItem(AnchorDropDown, "LUI", "LUI") end
			if _G[anchors["SUF"][unitId]] or (type(anchors["SUF"][unitId])=="table" and anchors["SUF"][unitId]) or (type(anchors["SUF"][unitId])=="string" and _GF(anchors["SUF"][unitId])) then AddItem(AnchorDropDown, "SUF", "SUF") end
			if _G[anchors["LUF"][unitId]] or (type(anchors["LUF"][unitId])=="table" and anchors["LUF"][unitId]) or (type(anchors["LUF"][unitId])=="string" and _GF(anchors["LUF"][unitId])) then AddItem(AnchorDropDown, "LUF", "LUF") end
			if _G[anchors["PitBullUF"][unitId]] or (type(anchors["PitBullUF"][unitId])=="table" and anchors["PitBullUF"][unitId]) or (type(anchors["PitBullUF"][unitId])=="string" and _GF(anchors["PitBullUF"][unitId])) then AddItem(AnchorDropDown, "PitBullUF", "PitBullUF") end
			if _G[anchors["SpartanUI_2D"][unitId]] or (type(anchors["SpartanUI_2D"][unitId])=="table" and anchors["SpartanUI_2D"][unitId]) or (type(anchors["SpartanUI_2D"][unitId])=="string" and _GF(anchors["SpartanUI_2D"][unitId])) then AddItem(AnchorDropDown, "SpartanUI_2D", "SpartanUI_2D") end
			if _G[anchors["SpartanUI_3D"][unitId]] or (type(anchors["SpartanUI_3D"][unitId])=="table" and anchors["SpartanUI_3D"][unitId]) or (type(anchors["SpartanUI_3D"][unitId])=="string" and _GF(anchors["SpartanUI_3D"][unitId])) then AddItem(AnchorDropDown, "SpartanUI_3D", "SpartanUI_3D") end
			if _G[anchors["SpartanUI_2D_NoPlayerInParty"][unitId]] or (type(anchors["SpartanUI_2D_NoPlayerInParty"][unitId])=="table" and anchors["SpartanUI_2D_NoPlayerInParty"][unitId]) or (type(anchors["SpartanUI_2D_NoPlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_2D_NoPlayerInParty"][unitId])) then AddItem(AnchorDropDown, "SpartanUI_2D_NoPlayerInParty", "SpartanUI_2D_NoPlayerInParty") end
			if _G[anchors["SpartanUI_2D_PlayerInParty"][unitId]] or (type(anchors["SpartanUI_2D_PlayerInParty"][unitId])=="table" and anchors["SpartanUI_2D_PlayerInParty"][unitId]) or (type(anchors["SpartanUI_2D_PlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_2D_PlayerInParty"][unitId])) then AddItem(AnchorDropDown, "SpartanUI_2D_PlayerInParty", "SpartanUI_2D_PlayerInParty") end
			if _G[anchors["SpartanUI_3D_NoPlayerInParty"][unitId]] or (type(anchors["SpartanUI_3D_NoPlayerInParty"][unitId])=="table" and anchors["SpartanUI_3D_NoPlayerInParty"][unitId]) or (type(anchors["SpartanUI_3D_NoPlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_3D_NoPlayerInParty"][unitId])) then AddItem(AnchorDropDown, "SpartanUI_3D_NoPlayerInParty", "SpartanUI_3D_NoPlayerInParty") end
			if _G[anchors["SpartanUI_3D_PlayerInParty"][unitId]] or (type(anchors["SpartanUI_3D_PlayerInParty"][unitId])=="table" and anchors["SpartanUI_3D_PlayerInParty"][unitId]) or (type(anchors["SpartanUI_3D_PlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_3D_PlayerInParty"][unitId])) then AddItem(AnchorDropDown, "SpartanUI_3D_PlayerInParty", "SpartanUI_3D_PlayerInParty") end
			if _G[anchors["GW2"][unitId]] or (type(anchors["GW2"][unitId])=="table" and anchors["GW2"][unitId]) or (type(anchors["GW2"][unitId])=="string" and _GF(anchors["GW2"][unitId])) then AddItem(AnchorDropDown, "GW2", "GW2") end
			if _G[anchors["nUI"][unitId]] or (type(anchors["nUI"][unitId])=="table" and anchors["nUI"][unitId]) or (type(anchors["nUI"][unitId])=="string" and _GF(anchors["nUI"][unitId])) then AddItem(AnchorDropDown, "nUI", "nUI") end
			if _G[anchors["Tukui"][unitId]] or (type(anchors["Tukui"][unitId])=="table" and anchors["Tukui"][unitId]) or (type(anchors["Tukui"][unitId])=="string" and _GF(anchors["Tukui"][unitId])) then AddItem(AnchorDropDown, "Tukui", "Tukui") end
			if _G[anchors["ElvUI"][unitId]] or (type(anchors["ElvUI"][unitId])=="table" and anchors["ElvUI"][unitId]) or (type(anchors["ElvUI"][unitId])=="string" and _GF(anchors["ElvUI"][unitId])) then AddItem(AnchorDropDown, "ElvUI", "ElvUI") end
			if _G[anchors["ElvUI_PlayerInParty"][unitId]] or (type(anchors["ElvUI_PlayerInParty"][unitId])=="table" and anchors["ElvUI_PlayerInParty"][unitId]) or (type(anchors["ElvUI_PlayerInParty"][unitId])=="string" and _GF(anchors["ElvUI_PlayerInParty"][unitId])) then AddItem(AnchorDropDown, "ElvUI_PlayerInParty", "ElvUI_PlayerInParty") end
			if _G[anchors["ElvUI_NoPlayerInParty"][unitId]] or (type(anchors["ElvUI_NoPlayerInParty"][unitId])=="table" and anchors["ElvUI_NoPlayerInParty"][unitId]) or (type(anchors["ElvUI_NoPlayerInParty"][unitId])=="string" and _GF(anchors["ElvUI_NoPlayerInParty"][unitId])) then AddItem(AnchorDropDown, "ElvUI_NoPlayerInParty", "ElvUI_NoPlayerInParty") end
		end)
		UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
		if AnchorDropDown2 then
			UIDropDownMenu_Initialize(AnchorDropDown2, function() -- called on refresh and also every time the drop down menu is opened
				AddItem(AnchorDropDown2, "Blizzard", "Blizzard")
				if _G[anchors["Perl"][unitId]] or (type(anchors["Perl"][unitId])=="table" and anchors["Perl"][unitId]) or (type(anchors["Perl"][unitId])=="string" and _GF(anchors["Perl"][unitId])) then AddItem(AnchorDropDown2, "Perl", "Perl") end
				if _G[anchors["XPerl"][unitId]] or (type(anchors["XPerl"][unitId])=="table" and anchors["XPerl"][unitId]) or (type(anchors["XPerl"][unitId])=="string" and _GF(anchors["XPerl"][unitId])) then AddItem(AnchorDropDown2, "XPerl", "XPerl") end
				if _G[anchors["LUI"][unitId]] or (type(anchors["LUI"][unitId])=="table" and anchors["LUI"][unitId]) or (type(anchors["LUI"][unitId])=="string" and _GF(anchors["LUI"][unitId])) then AddItem(AnchorDropDown2, "LUI", "LUI") end
				if _G[anchors["SUF"][unitId]] or (type(anchors["SUF"][unitId])=="table" and anchors["SUF"][unitId]) or (type(anchors["SUF"][unitId])=="string" and _GF(anchors["SUF"][unitId])) then AddItem(AnchorDropDown2, "SUF", "SUF") end
				if _G[anchors["LUF"][unitId]] or (type(anchors["LUF"][unitId])=="table" and anchors["LUF"][unitId]) or (type(anchors["LUF"][unitId])=="string" and _GF(anchors["LUF"][unitId])) then AddItem(AnchorDropDown2, "LUF", "LUF") end
				if _G[anchors["PitBullUF"][unitId]] or (type(anchors["PitBullUF"][unitId])=="table" and anchors["PitBullUF"][unitId]) or (type(anchors["PitBullUF"][unitId])=="string" and _GF(anchors["PitBullUF"][unitId])) then AddItem(AnchorDropDown2, "PitBullUF", "PitBullUF") end
				if _G[anchors["SpartanUI_2D"][unitId]] or (type(anchors["SpartanUI_2D"][unitId])=="table" and anchors["SpartanUI_2D"][unitId]) or (type(anchors["SpartanUI_2D"][unitId])=="string" and _GF(anchors["SpartanUI_2D"][unitId])) then AddItem(AnchorDropDown2, "SpartanUI_2D", "SpartanUI_2D") end
				if _G[anchors["SpartanUI_3D"][unitId]] or (type(anchors["SpartanUI_3D"][unitId])=="table" and anchors["SpartanUI_3D"][unitId]) or (type(anchors["SpartanUI_3D"][unitId])=="string" and _GF(anchors["SpartanUI_3D"][unitId])) then AddItem(AnchorDropDown2, "SpartanUI_3D", "SpartanUI_3D") end
				if _G[anchors["SpartanUI_2D_NoPlayerInParty"][unitId]] or (type(anchors["SpartanUI_2D_NoPlayerInParty"][unitId])=="table" and anchors["SpartanUI_2D_NoPlayerInParty"][unitId]) or (type(anchors["SpartanUI_2D_NoPlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_2D_NoPlayerInParty"][unitId])) then AddItem(AnchorDropDown2, "SpartanUI_2D_NoPlayerInParty", "SpartanUI_2D_NoPlayerInParty") end
				if _G[anchors["SpartanUI_2D_PlayerInParty"][unitId]] or (type(anchors["SpartanUI_2D_PlayerInParty"][unitId])=="table" and anchors["SpartanUI_2D_PlayerInParty"][unitId]) or (type(anchors["SpartanUI_2D_PlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_2D_PlayerInParty"][unitId])) then AddItem(AnchorDropDown2, "SpartanUI_2D_PlayerInParty", "SpartanUI_2D_PlayerInParty") end
				if _G[anchors["SpartanUI_3D_NoPlayerInParty"][unitId]] or (type(anchors["SpartanUI_3D_NoPlayerInParty"][unitId])=="table" and anchors["SpartanUI_3D_NoPlayerInParty"][unitId]) or (type(anchors["SpartanUI_3D_NoPlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_3D_NoPlayerInParty"][unitId])) then AddItem(AnchorDropDown2, "SpartanUI_3D_NoPlayerInParty", "SpartanUI_3D_NoPlayerInParty") end
				if _G[anchors["SpartanUI_3D_PlayerInParty"][unitId]] or (type(anchors["SpartanUI_3D_PlayerInParty"][unitId])=="table" and anchors["SpartanUI_3D_PlayerInParty"][unitId]) or (type(anchors["SpartanUI_3D_PlayerInParty"][unitId])=="string" and _GF(anchors["SpartanUI_3D_PlayerInParty"][unitId])) then AddItem(AnchorDropDown2, "SpartanUI_3D_PlayerInParty", "SpartanUI_3D_PlayerInParty") end
				if _G[anchors["GW2"][unitId]] or (type(anchors["GW2"][unitId])=="table" and anchors["GW2"][unitId]) or (type(anchors["GW2"][unitId])=="string" and _GF(anchors["GW2"][unitId])) then AddItem(AnchorDropDown2, "GW2", "GW2") end
				if _G[anchors["nUI"][unitId]] or (type(anchors["nUI"][unitId])=="table" and anchors["nUI"][unitId]) or (type(anchors["nUI"][unitId])=="string" and _GF(anchors["nUI"][unitId])) then AddItem(AnchorDropDown2, "nUI", "nUI") end
				if _G[anchors["Tukui"][unitId]] or (type(anchors["Tukui"][unitId])=="table" and anchors["Tukui"][unitId]) or (type(anchors["Tukui"][unitId])=="string" and _GF(anchors["Tukui"][unitId])) then AddItem(AnchorDropDown2, "Tukui", "Tukui") end
				if _G[anchors["ElvUI"][unitId]] or (type(anchors["ElvUI"][unitId])=="table" and anchors["ElvUI"][unitId]) or (type(anchors["ElvUI"][unitId])=="string" and _GF(anchors["ElvUI"][unitId])) then AddItem(AnchorDropDown2, "ElvUI", "ElvUI") end
				if _G[anchors["ElvUI_PlayerInParty"][unitId]] or (type(anchors["ElvUI_PlayerInParty"][unitId])=="table" and anchors["ElvUI_PlayerInParty"][unitId]) or (type(anchors["ElvUI_PlayerInParty"][unitId])=="string" and _GF(anchors["ElvUI_PlayerInParty"][unitId])) then AddItem(AnchorDropDown2, "ElvUI_PlayerInParty", "ElvUI_PlayerInParty") end
				if _G[anchors["ElvUI_NoPlayerInParty"][unitId]] or (type(anchors["ElvUI_NoPlayerInParty"][unitId])=="table" and anchors["ElvUI_NoPlayerInParty"][unitId]) or (type(anchors["ElvUI_NoPlayerInParty"][unitId])=="string" and _GF(anchors["ElvUI_NoPlayerInParty"][unitId])) then AddItem(AnchorDropDown2, "ElvUI_NoPlayerInParty", "ElvUI_NoPlayerInParty") end
			end)
			UIDropDownMenu_SetSelectedValue(AnchorDropDown2, LoseControlDB.frames.player2.anchor)
		end
		if AnchorPositionPartyDropDown then
			UIDropDownMenu_Initialize(AnchorPositionPartyDropDown, function() -- called on refresh and also every time the drop down menu is opened
				AddItem(AnchorPositionPartyDropDown, "party1", "party1")
				AddItem(AnchorPositionPartyDropDown, "party2", "party2")
				AddItem(AnchorPositionPartyDropDown, "party3", "party3")
				AddItem(AnchorPositionPartyDropDown, "party4", "party4")
				if (LoseControlDB.frames.partyplayer.enabled) then AddItem(AnchorPositionPartyDropDown, "partyplayer", "partyplayer") end
			end)
			UIDropDownMenu_SetSelectedValue(AnchorPositionPartyDropDown, "party1")
		end
		if AnchorPositionRaidDropDown then
			UIDropDownMenu_Initialize(AnchorPositionRaidDropDown, function() -- called on refresh and also every time the drop down menu is opened
				for i = 1, 40 do
					AddItem(AnchorPositionRaidDropDown, "raid"..i, "raid"..i)
				end
			end)
			UIDropDownMenu_SetSelectedValue(AnchorPositionRaidDropDown, "raid1")
		end
		UIDropDownMenu_Initialize(AnchorPointDropDown, function() -- called on refresh and also every time the drop down menu is opened
			AddItem(AnchorPointDropDown, "TOP", "TOP")
			AddItem(AnchorPointDropDown, "TOPLEFT", "TOPLEFT")
			AddItem(AnchorPointDropDown, "TOPRIGHT", "TOPRIGHT")
			AddItem(AnchorPointDropDown, "CENTER", "CENTER")
			AddItem(AnchorPointDropDown, "LEFT", "LEFT")
			AddItem(AnchorPointDropDown, "RIGHT", "RIGHT")
			AddItem(AnchorPointDropDown, "BOTTOM", "BOTTOM")
			AddItem(AnchorPointDropDown, "BOTTOMLEFT", "BOTTOMLEFT")
			AddItem(AnchorPointDropDown, "BOTTOMRIGHT", "BOTTOMRIGHT")
		end)
		UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, frame.relativePoint or "CENTER")
		UIDropDownMenu_Initialize(AnchorIconPointDropDown, function() -- called on refresh and also every time the drop down menu is opened
			AddItem(AnchorIconPointDropDown, "TOP", "TOP")
			AddItem(AnchorIconPointDropDown, "TOPLEFT", "TOPLEFT")
			AddItem(AnchorIconPointDropDown, "TOPRIGHT", "TOPRIGHT")
			AddItem(AnchorIconPointDropDown, "CENTER", "CENTER")
			AddItem(AnchorIconPointDropDown, "LEFT", "LEFT")
			AddItem(AnchorIconPointDropDown, "RIGHT", "RIGHT")
			AddItem(AnchorIconPointDropDown, "BOTTOM", "BOTTOM")
			AddItem(AnchorIconPointDropDown, "BOTTOMLEFT", "BOTTOMLEFT")
			AddItem(AnchorIconPointDropDown, "BOTTOMRIGHT", "BOTTOMRIGHT")
		end)
		UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
		UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, function() -- called on refresh and also every time the drop down menu is opened
			AddItem(AnchorFrameStrataDropDown, "AUTO", "AUTO")
			AddItem(AnchorFrameStrataDropDown, "BACKGROUND", "BACKGROUND")
			AddItem(AnchorFrameStrataDropDown, "LOW", "LOW")
			AddItem(AnchorFrameStrataDropDown, "MEDIUM", "MEDIUM")
			AddItem(AnchorFrameStrataDropDown, "HIGH", "HIGH")
			AddItem(AnchorFrameStrataDropDown, "DIALOG", "DIALOG")
			AddItem(AnchorFrameStrataDropDown, "FULLSCREEN", "FULLSCREEN")
			AddItem(AnchorFrameStrataDropDown, "FULLSCREEN_DIALOG", "FULLSCREEN_DIALOG")
			AddItem(AnchorFrameStrataDropDown, "TOOLTIP", "TOOLTIP")
		end)
		UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
		UIDropDownMenu_SetWidth(AnchorFrameStrataDropDown, 140)
	end

	InterfaceOptions_AddCategory(OptionsPanelFrame)
end

-------------------------------------------------------------------------------
SLASH_LoseControl1 = "/lc"
SLASH_LoseControl2 = "/losecontrol"

local SlashCmd = {}
function SlashCmd:help()
	print(addonName, "slash commands:")
	print("    reset [<unit>]")
	print("    lock")
	print("    unlock")
	print("    enable <unit>")
	print("    disable <unit>")
	print("    customspells add <spellId> <category>")
	print("    customspells ban <spellId>")
	print("    customspells remove <spellId>")
	print("    customspells list")
	print("    customspells wipe")
	print("    customspells checkandclean")
	print("<unit> can be: player, pet, target, targettarget, party1 ... party4, raid1 ... raid40")
	print("<category> can be: none, pve, immune, immunespell, immunephysical, cc, silence, interrupt, disarm, other, root, snare")
end
function SlashCmd:debug(value)
	if value == "on" then
		debug = true
		print(addonName, "debugging enabled.")
	elseif value == "off" then
		debug = false
		print(addonName, "debugging disabled.")
	end
end
function SlashCmd:reset(unitId)
	if unitId == nil or unitId == "" or unitId == "all" then
		OptionsPanel.default()
	elseif unitId == "party" then
		for _, v in ipairs({"party1", "party2", "party3", "party4","partyplayer"}) do
			LoseControlDB.frames[v] = CopyTable(DBdefaults.frames[v])
			LCframes[v]:PLAYER_ENTERING_WORLD()
			print(L["LoseControl reset."].." "..v)
		end
	elseif unitId == "raid" then
		for _, v in ipairs({"raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40"}) do
			LoseControlDB.frames[v] = CopyTable(DBdefaults.frames[v])
			LCframes[v]:PLAYER_ENTERING_WORLD()
			print(L["LoseControl reset."].." "..v)
		end
	elseif LoseControlDB.frames[unitId] and unitId ~= "player2" then
		LoseControlDB.frames[unitId] = CopyTable(DBdefaults.frames[unitId])
		LCframes[unitId]:PLAYER_ENTERING_WORLD()
		if (unitId == "player") then
			LoseControlDB.frames.player2 = CopyTable(DBdefaults.frames.player2)
			LCframeplayer2:PLAYER_ENTERING_WORLD()
		end
		print(L["LoseControl reset."].." "..unitId)
	end
	Unlock:OnClick()
	OptionsPanel.refresh()
	for _, v in ipairs({ "player", "pet", "target", "targettarget", "party", "raid" }) do
		_G[O..v].refresh()
	end
end
function SlashCmd:lock()
	Unlock:SetChecked(false)
	Unlock:OnClick()
	print(addonName, "locked.")
end
function SlashCmd:unlock()
	Unlock:SetChecked(true)
	Unlock:OnClick()
	print(addonName, "unlocked.")
end
function SlashCmd:enable(unitId)
	if LCframes[unitId] and unitId ~= "player2" then
		LoseControlDB.frames[unitId].enabled = true
		local enabled = LCframes[unitId]:GetEnabled()
		LCframes[unitId]:RegisterUnitEvents(enabled)
		if strfind(unitId, "raid") then
			MainHookCompactRaidFrames()
		end
		if enabled and not LCframes[unitId].unlockMode then
			LCframes[unitId].maxExpirationTime = 0
			LCframes[unitId]:UNIT_AURA(LCframes[unitId].unitId, 0)
		end
		if (unitId == "player") then
			LoseControlDB.frames.player2.enabled = LoseControlDB.duplicatePlayerPortrait
			LCframeplayer2:RegisterUnitEvents(LoseControlDB.duplicatePlayerPortrait)
			if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
				LCframeplayer2.maxExpirationTime = 0
				LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
			end
		elseif (unitId == "partyplayer") then
			LoseControlDB.showPartyplayerIcon = true
		end
		print(addonName, unitId, "frame enabled.")
	end
end
function SlashCmd:disable(unitId)
	if LCframes[unitId] and unitId ~= "player2" then
		LoseControlDB.frames[unitId].enabled = false
		LCframes[unitId].maxExpirationTime = 0
		LCframes[unitId]:RegisterUnitEvents(false)
		if (unitId == "player") then
			LoseControlDB.frames.player2.enabled = false
			LCframeplayer2.maxExpirationTime = 0
			LCframeplayer2:RegisterUnitEvents(false)
		elseif (unitId == "partyplayer") then
			LoseControlDB.showPartyplayerIcon = false
		end
		print(addonName, unitId, "frame disabled.")
	end
end
function SlashCmd:cs(operation, spellId, category)
	SlashCmd:customspells(operation, spellId, category)
end
function SlashCmd:customspells(operation, spellId, category)
	if operation == "add" then
		if spellId ~= nil and category ~= nil then
			if category == "pve" then
				category = "PvE"
			elseif category == "immune" then
				category = "Immune"
			elseif category == "immunespell" then
				category = "ImmuneSpell"
			elseif category == "immunephysical" then
				category = "ImmunePhysical"
			elseif category == "cc" then
				category = "CC"
			elseif category == "silence" then
				category = "Silence"
			elseif category == "disarm" then
				category = "Disarm"
			elseif category == "other" then
				category = "Other"
			elseif category == "root" then
				category = "Root"
			elseif category == "snare" then
				category = "Snare"
			elseif category == "none" then
				category = "None"
			else
				category = nil
			end
			spellId = tonumber(spellId)
			if (type(spellId) == "number") then
				spellId = mathfloor(mathabs(spellId))
				if (category) then
					if (LoseControlDB.customSpellIds[spellId] == category) then
						print(addonName, "Error adding new custom spell |cffff0000["..spellId.."]|r: The spell is already in the custom list")
					else
						LoseControlDB.customSpellIds[spellId] = category
						LoseControl:UpdateSpellIdsTableWithCustomSpellIds()
						local colortag
						if (category == "None") then
							if (origSpellIdsChanged[spellId] == "None") then
								colortag = "|cffffc419"
							else
								colortag = "|cff00ff00"
							end
						elseif (LoseControlDB.priority[category]) then
							if (origSpellIdsChanged[spellId] == category) then
								colortag = "|cffffc419"
							elseif (origSpellIdsChanged[spellId] ~= "None") then
								colortag = "|cff74cf14"
							else
								colortag = "|cff00ff00"
							end
						else
							colortag = "|cffff0000"
						end
						print(addonName, "The spell "..colortag.."["..spellId.."]->("..category..")|r has been added to the custom list")
					end
				else
					print(addonName, "Error adding new custom spell |cffff0000["..spellId.."]|r: Invalid category")
				end
			else
				print(addonName, "Error adding new custom spell: Invalid spellId")
			end
		else
			print(addonName, "Error adding new custom spell: Wrong parameters")
		end
	elseif operation == "ban" then
		if spellId ~= nil then
			spellId = tonumber(spellId)
			if (type(spellId) == "number") then
				spellId = mathfloor(mathabs(spellId))
				if (LoseControlDB.customSpellIds[spellId] == "None") then
					print(addonName, "Error adding new custom spell |cffff0000["..spellId.."]|r: The spell is already in the custom list")
				else
					LoseControlDB.customSpellIds[spellId] = "None"
					LoseControl:UpdateSpellIdsTableWithCustomSpellIds()
					local colortag
					if (origSpellIdsChanged[spellId] == "None") then
						colortag = "|cffffc419"
					else
						colortag = "|cff00ff00"
					end
					print(addonName, "The spell "..colortag.."["..spellId.."]->(None)|r has been added to the custom list")
				end
			else
				print(addonName, "Error adding new custom spell: Invalid spellId")
			end
		else
			print(addonName, "Error adding new custom spell: Wrong parameters")
		end
	elseif operation == "remove" then
		if spellId ~= nil then
			spellId = tonumber(spellId)
			if (type(spellId) == "number") then
				spellId = mathfloor(mathabs(spellId))
				if (LoseControlDB.customSpellIds[spellId]) then
					print(addonName, "The spell |cff00ff00["..spellId.."]->("..LoseControlDB.customSpellIds[spellId]..")|r has been removed from the custom list")
					LoseControlDB.customSpellIds[spellId] = nil
					LoseControl:UpdateSpellIdsTableWithCustomSpellIds()
				else
					print(addonName, "Error removing custom spell |cffff0000["..spellId.."]|r: the spell is not in the custom list")
				end
			else
				print(addonName, "Error removing custom spell: Invalid spellId")
			end
		else
			print(addonName, "Error removing custom spell|r: Wrong parameters")
		end
	elseif operation == "list" then
		print(addonName, "Custom spell list:")
		if (next(LoseControlDB.customSpellIds) == nil) then
			print(addonName, "Custom spell list is |cffffc419empty|r")
		else
			for cSpellId, cPriority in pairs(LoseControlDB.customSpellIds) do
				if (cPriority == "None") then
					if (origSpellIdsChanged[cSpellId] == "None") then
						print(addonName, "|cffffc419["..cSpellId.."]->("..cPriority..")|r")
					else
						print(addonName, "|cff00ff00["..cSpellId.."]->("..cPriority..")|r")
					end
				elseif (LoseControlDB.priority[cPriority]) then
					if (origSpellIdsChanged[cSpellId] == cPriority) then
						print(addonName, "|cffffc419["..cSpellId.."]->("..cPriority..")|r")
					elseif (origSpellIdsChanged[cSpellId] ~= "None") then
						print(addonName, "|cff74cf14["..cSpellId.."]->("..cPriority..")|r")
					else
						print(addonName, "|cff00ff00["..cSpellId.."]->("..cPriority..")|r")
					end
				else
					print(addonName, "|cffff0000["..cSpellId.."]->("..cPriority..")|r")
				end
			end
		end
	elseif operation == "wipe" then
		LoseControlDB.customSpellIds = { }
		LoseControl:UpdateSpellIdsTableWithCustomSpellIds()
		print(addonName, "Removed |cff00ff00all spells|r from custom list")
	elseif operation == "checkandclean" then
		LoseControl:CheckAndCleanCustomSpellIdsTable()
	else
		print(addonName, "customspells slash commands:")
		print("    add <spellId> <category>")
		print("    ban <spellId>")
		print("    remove <spellId>")
		print("    list")
		print("    wipe")
		print("    checkandclean")
		print("<category> can be: none, pve, immune, immunespell, immunephysical, cc, silence, disarm, other, root, snare")
	end
end

SlashCmdList[addonName] = function(cmd)
	local args = {}
	for word in cmd:lower():gmatch("%S+") do
		tinsert(args, word)
	end
	if SlashCmd[args[1]] then
		SlashCmd[args[1]](unpack(args))
	else
		print(addonName, ": Type \"/lc help\" for more options.")
		InterfaceOptionsFrame_OpenToCategory(OptionsPanel)
		InterfaceOptionsFrame_OpenToCategory(OptionsPanel)
	end
end
