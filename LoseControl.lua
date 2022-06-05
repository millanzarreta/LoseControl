--[[
-------------------------------------------
-- Addon: LoseControl TBC
-- Version: 2.05
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
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetInventoryItemID = GetInventoryItemID
local GetTalentInfo = GetTalentInfo
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local GetCVarBool = GetCVarBool
local SetPortraitToTexture = SetPortraitToTexture
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type
local select = select
local tonumber = tonumber
local strfind = string.find
local strgmatch = string.gmatch
local tblinsert = table.insert
local tblsort = table.sort
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
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local playerGUID, playerClass
local print = print
local debug = false -- type "/lc debug on" if you want to see UnitAura info logged to the console
local LCframes = {}
local LCframeplayer2
local InterruptAuras = { }
local origSpellIdsChanged = { }
local LoseControlCompactRaidFramesHooked
local LCHookedCompactRaidFrames = { }
local Masque = LibStub("Masque", true)
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
	[72]     = 6,		-- Shield Bash (rank 1) (Warrior)
	[1671]   = 6,		-- Shield Bash (rank 2) (Warrior)
	[1672]   = 6,		-- Shield Bash (rank 3) (Warrior)
	[29704]  = 6,		-- Shield Bash (rank 4) (Warrior)
	[1766]   = 5,		-- Kick (rank 1) (Rogue)
	[1767]   = 5,		-- Kick (rank 2) (Rogue)
	[1768]   = 5,		-- Kick (rank 3) (Rogue)
	[1769]   = 5,		-- Kick (rank 4) (Rogue)
	[38768]  = 5,		-- Kick (rank 5) (Rogue)
	[26679]  = 3,		-- Deadly Throw (Gladiator's Leather Gloves) (rank 1) (Rogue)
	[2139]   = 8,		-- Counterspell (Mage)
	[6552]   = 4,		-- Pummel (rank 1) (Warrior)
	[6554]   = 4,		-- Pummel (rank 2) (Warrior)
	[8042]   = 2,		-- Earth Shock (rank 1) (Shaman)
	[8044]   = 2,		-- Earth Shock (rank 2) (Shaman)
	[8045]   = 2,		-- Earth Shock (rank 3) (Shaman)
	[8046]   = 2,		-- Earth Shock (rank 4) (Shaman)
	[10412]  = 2,		-- Earth Shock (rank 5) (Shaman)
	[10413]  = 2,		-- Earth Shock (rank 6) (Shaman)
	[10414]  = 2,		-- Earth Shock (rank 7) (Shaman)
	[25454]  = 2,		-- Earth Shock (rank 8) (Shaman)
	[13491]  = 5,		-- Pummel (Iron Knuckles Item)
	[19244]  = 5,		-- Spell Lock (felhunter) (rank 1) (Warlock)
	[19647]  = 6,		-- Spell Lock (felhunter) (rank 2) (Warlock)
	[19675]  = 4,		-- Feral Charge (Druid)
	[22570]  = 3,		-- Maim (Gladiator's Dragonhide Gloves) (rank 1) (Druid)
	[29443]  = 10,		-- Counterspell (Clutch of Foresight)
	-- NPC Classic Interrupts
	--------------------------------------------------------
	[2676]   = 2,		-- Pulverize
	[5133]   = 30,		-- Interrupt (PT)
	[8714]   = 5,		-- Overwhelming Musk
	[10887]  = 5,		-- Crowd Pummel
	[11972]  = 8,		-- Shield Bash
	[11978]  = 6,		-- Kick
	[12555]  = 5,		-- Pummel
	[13281]  = 2,		-- Earth Shock
	[13728]  = 2,		-- Earth Shock
	[15122]  = 15,		-- Counterspell
	[15501]  = 2,		-- Earth Shock
	[15610]  = 6,		-- Kick
	[15614]  = 6,		-- Kick
	[15615]  = 5,		-- Pummel
	[19129]  = 2,		-- Massive Tremor
	[19639]  = 5,		-- Pummel
	[19715]  = 10,		-- Counterspell
	[20537]  = 15,		-- Counterspell
	[20788]  = 0.0010,	-- Counterspell
	[21832]  = 10,		-- Boulder
	[22885]  = 2,		-- Earth Shock
	[23114]  = 2,		-- Earth Shock
	[24685]  = 4,		-- Earth Shock
	[25025]  = 2,		-- Earth Shock
	[25788]  = 5,		-- Head Butt
	[26194]  = 2,		-- Earth Shock
	[27613]  = 4,		-- Kick
	[27620]  = 4,		-- Snap Kick
	[27814]  = 6,		-- Kick
	[27880]  = 3,		-- Stun
	[29298]  = 4,		-- Dark Shriek
	[29560]  = 2,		-- Kick
	[29586]  = 5,		-- Kick
	[29961]  = 10,		-- Counterspell
	[30849]  = 6,		-- Spell Lock
	[31596]  = 6,		-- Counterspell
	[31999]  = 15,		-- Counterspell
	[32322]  = 4,		-- Dark Shriek
	[32691]  = 6,		-- Spell Shock
	[32747]  = 3,		-- Deadly Interrupt Effect
	[32846]  = 4,		-- Counter Kick
	[32938]  = 4,		-- Cry of the Dead
	[33871]  = 8,		-- Shield Bash
	[34797]  = 6,		-- Nature Shock
	[34802]  = 6,		-- Kick
	[35039]  = 10,		-- Countercharge
	[35178]  = 6,		-- Shield Bash
	[35856]  = 3,		-- Stun
	[35920]  = 2,		-- Electroshock
	[36033]  = 6,		-- Kick
	[36138]  = 3,		-- Hammer Stun
	[36254]  = 3,		-- Judgement of the Flame
	[36841]  = 3,		-- Sonic Boom
	[36988]  = 8,		-- Shield Bash
	[37359]  = 5,		-- Rush
	[37470]  = 3,		-- Counterspell
	[38052]  = 3,		-- Sonic Boom
	[38233]  = 8,		-- Shield Bash
	[38313]  = 5,		-- Pummel
	[38625]  = 6,		-- Kick
	[38750]  = 4,		-- War Stomp
	[38897]  = 4,		-- Sonic Boom
	[39076]  = 6,		-- Spell Shock
	[39120]  = 6,		-- Nature Shock
	[40305]  = 1,		-- Power Burn
	[40547]  = 1,		-- Interrupt Unholy Growth
	[40751]  = 3,		-- Disrupt Magic
	[40864]  = 3,		-- Throbbing Stun
	[41180]  = 3,		-- Shield Bash
	[41197]  = 3,		-- Shield Bash
	[41395]  = 5,		-- Kick
	[43305]  = 4,		-- Earth Shock
	[43518]  = 2,		-- Kick
	[44418]  = 2,		-- Massive Tremor
	[44644]  = 6,		-- Arcane Nova
	[45214]  = 8,		-- Ron's Test Spell #4
	[45356]  = 5,		-- Kick
	[46036]  = 6,		-- Arcane Nova
	[46182]  = 2,		-- Snap Kick
	[47071]  = 2,		-- Earth Shock
	[47081]  = 5,		-- Pummel
}

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
	[26989]  = "Root",				-- Entangling Roots (rank 7)
	[9005]   = "CC",				-- Pounce (rank 1)
	[9823]   = "CC",				-- Pounce (rank 2)
	[9827]   = "CC",				-- Pounce (rank 3)
	[27006]  = "CC",				-- Pounce (rank 4)
	[5211]   = "CC",				-- Bash (rank 1)
	[6798]   = "CC",				-- Bash (rank 2)
	[8983]   = "CC",				-- Bash (rank 3)
	[2637]   = "CC",				-- Hibernate (rank 1)
	[18657]  = "CC",				-- Hibernate (rank 2)
	[18658]  = "CC",				-- Hibernate (rank 3)
	[33786]  = "CC",				-- Cyclone
	[19975]  = "Root",				-- Entangling Roots (rank 1) (Nature's Grasp talent)
	[19974]  = "Root",				-- Entangling Roots (rank 2) (Nature's Grasp talent)
	[19973]  = "Root",				-- Entangling Roots (rank 3) (Nature's Grasp talent)
	[19972]  = "Root",				-- Entangling Roots (rank 4) (Nature's Grasp talent)
	[19971]  = "Root",				-- Entangling Roots (rank 5) (Nature's Grasp talent)
	[19970]  = "Root",				-- Entangling Roots (rank 6) (Nature's Grasp talent)
	[27010]  = "Root",				-- Entangling Roots (rank 6) (Nature's Grasp talent)
	[22570]  = "CC",				-- Maim (rank 1)
	[16922]  = "CC",				-- Starfire Stun (Improved Starfire talent)
	[19675]  = "Root",				-- Feral Charge Effect (Feral Charge talent)
	[45334]  = "Root",				-- Feral Charge Effect (Feral Charge talent)
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
	[27068]  = "CC",				-- Wyvern Sting (talent) (rank 4)
	[19410]  = "CC",				-- Improved Concussive Shot (talent)
	[28445]  = "CC",				-- Improved Concussive Shot (talent)
	[19503]  = "CC",				-- Scatter Shot (talent)
	[34490]  = "Silence",			-- Silencing Shot
	[19306]  = "Root",				-- Counterattack (talent) (rank 1)
	[20909]  = "Root",				-- Counterattack (talent) (rank 2)
	[20910]  = "Root",				-- Counterattack (talent) (rank 3)
	[27067]  = "Root",				-- Counterattack (talent) (rank 4)
	[19229]  = "Root",				-- Improved Wing Clip (talent)
	[19185]  = "Root",				-- Entrapment (talent)
	[2974]   = "Snare",				-- Wing Clip (rank 1)
	[14267]  = "Snare",				-- Wing Clip (rank 2)
	[14268]  = "Snare",				-- Wing Clip (rank 3)
	[5116]   = "Snare",				-- Concussive Shot
	[15571]  = "Snare",				-- Dazed (Aspect of the Cheetah and Aspect of the Pack)
	[13809]  = "Snare",				-- Frost Trap
	[13810]  = "Snare",				-- Frost Trap Aura
	[35101]  = "Snare",				-- Concussive Barrage (talent)
	[19263]  = "Other",				-- Deterrence (dodge and Parry chance increased by 25%)
	[19574]  = "ImmuneSpell",		-- Bestial Wrath (talent) (not immuune to spells, only immune to some CC's)
	[34471]  = "ImmuneSpell",		-- The Beast Within (talent) (not immuune to spells, only immune to some CC's)
	[5384]   = "Other",				-- Feign Death
	--[19434]  = "Other",				--Aimed Shot (rank 1) (healing effects reduced by 50%)
	--[20900]  = "Other",				--Aimed Shot (rank 2) (healing effects reduced by 50%)
	--[20901]  = "Other",				--Aimed Shot (rank 3) (healing effects reduced by 50%)
	--[20902]  = "Other",				--Aimed Shot (rank 4) (healing effects reduced by 50%)
	--[20903]  = "Other",				--Aimed Shot (rank 5) (healing effects reduced by 50%)
	--[20904]  = "Other",				--Aimed Shot (rank 6) (healing effects reduced by 50%)
	--[27065]  = "Other",				--Aimed Shot (rank 7) (healing effects reduced by 50%)
	
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
	[28271]  = "CC",				-- Polymorph: Turtle
	[28272]  = "CC",				-- Polymorph: Pig
	[12355]  = "CC",				-- Impact (talent)
	[31661]  = "CC",				-- Dragon's Breath (rank 1) (talent)
	[33041]  = "CC",				-- Dragon's Breath (rank 2) (talent)
	[33042]  = "CC",				-- Dragon's Breath (rank 3) (talent)
	[33043]  = "CC",				-- Dragon's Breath (rank 4) (talent)
	[18469]  = "Silence",			-- Counterspell - Silenced (Improved Counterspell talent)
	[45438]  = "Immune",			-- Ice Block
	[122]    = "Root",				-- Frost Nova (rank 1)
	[865]    = "Root",				-- Frost Nova (rank 2)
	[6131]   = "Root",				-- Frost Nova (rank 3)
	[10230]  = "Root",				-- Frost Nova (rank 4)
	[27088]  = "Root",				-- Frost Nova (rank 5)
	[12494]  = "Root",				-- Frostbite (talent)
	[12484]  = "Snare",				-- Chilled (rank 1) (Improved Blizzard talent)
	[12485]  = "Snare",				-- Chilled (rank 2) (Improved Blizzard talent)
	[12486]  = "Snare",				-- Chilled (rank 3) (Improved Blizzard talent)
	[120]    = "Snare",				-- Cone of Cold (rank 1)
	[8492]   = "Snare",				-- Cone of Cold (rank 2)
	[10159]  = "Snare",				-- Cone of Cold (rank 3)
	[10160]  = "Snare",				-- Cone of Cold (rank 4)
	[10161]  = "Snare",				-- Cone of Cold (rank 5)
	[27087]  = "Snare",				-- Cone of Cold (rank 6)
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
	[27071]  = "Snare",				-- Frostbolt (rank 12)
	[27072]  = "Snare",				-- Frostbolt (rank 13)
	[38697]  = "Snare",				-- Frostbolt (rank 14)
	--[6136]   = "Snare",				-- Chilled (Frost Armor)
	--[7321]   = "Snare",				-- Chilled (Ice Armor)
	[11113]  = "Snare",				-- Blast Wave (talent) (rank 1)
	[13018]  = "Snare",				-- Blast Wave (talent) (rank 2)
	[13019]  = "Snare",				-- Blast Wave (talent) (rank 3)
	[13020]  = "Snare",				-- Blast Wave (talent) (rank 4)
	[13021]  = "Snare",				-- Blast Wave (talent) (rank 5)
	[27133]  = "Snare",				-- Blast Wave (talent) (rank 6)
	[33933]  = "Snare",				-- Blast Wave (talent) (rank 7)
	[31589]  = "Snare",				-- Slow (talent)
	[12043]  = "Other",				-- Presence of Mind (talent)
	[12042]  = "Other",				-- Arcane Power (talent)

		----------------
		-- Mage Water Elemental
		----------------
		[33395]  = "Root",				-- Freeze

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
	[10326]  = "CC",				-- Turn Evil (rank 1)
	[20066]  = "CC",				-- Repentance (talent)
	[1044]   = "Other",				-- Blessing of Freedom
	[20216]  = "Other",				-- Divine Favor
	[31935]  = "Snare",				-- Avenger's Shield (rank 1) (talent)
	[32699]  = "Snare",				-- Avenger's Shield (rank 2) (talent)
	[32700]  = "Snare",				-- Avenger's Shield (rank 3) (talent)
	[31884]  = "Other",				-- Avenging Wrath
	[31842]  = "Other",				-- Divine Illumination
	--[31854]  = "Other",				-- Ardent Defender (damage taken reduced by 30%)

	----------------
	-- Priest
	----------------
	[15487]  = "Silence",			-- Silence (talent)
	[10060]  = "Other",				-- Power Infusion (talent)
	[15269]  = "CC",				-- Blackout (talent)
	[2651]   = "Other",				-- Elune's Grace (chance to be hit by melee and ranged attacks reduced by 20%)
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
	[44041]  = "Root",				-- Chastise (rank 1)
	[44043]  = "Root",				-- Chastise (rank 2)
	[44044]  = "Root",				-- Chastise (rank 3)
	[44045]  = "Root",				-- Chastise (rank 4)
	[44046]  = "Root",				-- Chastise (rank 5)
	[44047]  = "Root",				-- Chastise (rank 6)
	[27827]  = "Immune",			-- Spirit of Redemption
	[33206]  = "Immune",			-- Pain Suppression (not immune, damage taken reduced by 40%)
	[14751]  = "Other",				-- Inner Focus
	[15407]  = "Snare",				-- Mind Flay (talent) (rank 1)
	[17311]  = "Snare",				-- Mind Flay (talent) (rank 2)
	[17312]  = "Snare",				-- Mind Flay (talent) (rank 3)
	[17313]  = "Snare",				-- Mind Flay (talent) (rank 4)
	[17314]  = "Snare",				-- Mind Flay (talent) (rank 5)
	[18807]  = "Snare",				-- Mind Flay (talent) (rank 6)
	[25387]  = "Snare",				-- Mind Flay (talent) (rank 7)

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
	[38764]  = "CC",				-- Gouge (rank 6)
	[5530]   = "CC",				-- Mace Stun (talent)
	[1330]   = "Silence",			-- Garrote - Silence
	[14251]  = "Disarm",			-- Riposte (talent)
	[18425]  = "Silence",			-- Kick - Silenced (talent)
	[3409]   = "Snare",				-- Crippling Poison (rank 1)
	[11201]  = "Snare",				-- Crippling Poison (rank 2)
	[26679]  = "Snare",				-- Deadly Throw (rank 1)
	[31125]  = "Snare",				-- Dazed (Blade Twisting) (talent)
	[5277]   = "ImmunePhysical",	-- Evasion (dodge chance increased 50%)
	[26669]  = "ImmunePhysical",	-- Evasion (dodge chance increased 50%)
	[31224]  = "ImmuneSpell",		-- Cloak of Shadows
	[45182]  = "Immune",			-- Cheating Death (talent) (damage taken reduced by 90%)
	[14177]  = "Other",				-- Cold Blood (talent)
	[13877]  = "Other",				-- Blade Flurry
	[13750]  = "Other",				-- Adrenaline Rush

	----------------
	-- Shaman
	----------------
	[39796]  = "CC",				-- Stoneclaw Stun (Stoneclaw Totem)
	[8178]   = "ImmuneSpell",		-- Grounding Totem Effect (Grounding Totem)
	[8056]   = "Snare",				-- Frost Shock (rank 1)
	[8058]   = "Snare",				-- Frost Shock (rank 2)
	[10472]  = "Snare",				-- Frost Shock (rank 3)
	[10473]  = "Snare",				-- Frost Shock (rank 4)
	[25464]  = "Snare",				-- Frost Shock (rank 5)
	[3600]   = "Snare",				-- Earthbind (Earthbind Totem)
	[16166]  = "Other",				-- Elemental Mastery (talent)
	[16188]  = "Other",				-- Nature's Swiftness (talent)
	[30823]  = "Other",				-- Shamanistic Rage (talent) (damage taken reduced by 30%)

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
	[27223]  = "CC",				-- Death Coil (rank 4)
	[22703]  = "CC",				-- Inferno Effect
	[18093]  = "CC",				-- Pyroclasm (talent)
	[30283]  = "CC",				-- Shadowfury (rank 1) (talent)
	[30413]  = "CC",				-- Shadowfury (rank 2) (talent)
	[30414]  = "CC",				-- Shadowfury (rank 3) (talent)
	[43523]  = "Silence",			-- Unstable Affliction
	[30300]  = "Other",				-- Nether Protection (immune to Fire and Shadow magic spells)
	[18708]  = "Other",				-- Fel Domination (talent)
	[18223]  = "Snare",				-- Curse of Exhaustion (talent)
	[18118]  = "Snare",				-- Aftermath (talent)

		----------------
		-- Warlock Pets
		----------------
		[32752]  = "CC",			-- Summoning Disorientation
		[24259]  = "Silence",		-- Spell Lock (Felhunter)
		[6358]   = "CC",			-- Seduction (Succubus)
		[4511]   = "Immune",		-- Phase Shift (Imp)
		[19482]  = "CC",			-- War Stomp (Doomguard)
		[89]     = "Snare",			-- Cripple (Doomguard)
		[30153]  = "CC",			-- Intercept Stun (rank 1) (Felguard)
		[30195]  = "CC",			-- Intercept Stun (rank 2) (Felguard)
		[30197]  = "CC",			-- Intercept Stun (rank 3) (Felguard)

	----------------
	-- Warrior
	----------------
	[7922]   = "CC",				-- Charge (rank 1/2/3)
	[20253]  = "CC",				-- Intercept (rank 1)
	[20614]  = "CC",				-- Intercept (rank 2)
	[20615]  = "CC",				-- Intercept (rank 3)
	[25273]  = "CC",				-- Intercept (rank 4)
	[25274]  = "CC",				-- Intercept (rank 5)
	[5246]   = "CC",				-- Intimidating Shout
	[20511]  = "CC",				-- Intimidating Shout
	[12798]  = "CC",				-- Revenge Stun (Improved Revenge talent)
	[12809]  = "CC",				-- Concussion Blow (talent)
	[676]    = "Disarm",			-- Disarm
	[871]    = "Immune",			-- Shield Wall (not immune, 75% damage reduction)
	[23920]  = "ImmuneSpell",		-- Spell Reflection
	[23694]  = "Root",				-- Improved Hamstring (talent)
	[18498]  = "Silence",			-- Shield Bash - Silenced (Improved Shield Bash talent)
	[29703]  = "Snare",				-- Dazed (Shield Bash)
	[1715]   = "Snare",				-- Hamstring (rank 1)
	[7372]   = "Snare",				-- Hamstring (rank 2)
	[7373]   = "Snare",				-- Hamstring (rank 3)
	[25212]  = "Snare",				-- Hamstring (rank 4)
	[12705]  = "Snare",				-- Long Daze (Improved Pummel)
	[12323]  = "Snare",				-- Piercing Howl (talent)
	[3411]   = "Other",				-- Intervene
	[2565]   = "Other",				-- Shield Block
	[12328]  = "Other",				-- Death Wish (talent)
	[12976]  = "Other",				-- Last Stand (talent)
	[20230]  = "Other",				-- Retaliation
	[18499]  = "Other",				-- Berserker Rage
	[1719]   = "Other",				-- Recklessness
	--[12294]  = "Other",				-- Mortal Strike (rank 1) (healing effects reduced by 50%)
	--[21551]  = "Other",				-- Mortal Strike (rank 2) (healing effects reduced by 50%)
	--[21552]  = "Other",				-- Mortal Strike (rank 3) (healing effects reduced by 50%)
	--[21553]  = "Other",				-- Mortal Strike (rank 4) (healing effects reduced by 50%)
	--[25248]  = "Other",				-- Mortal Strike (rank 5) (healing effects reduced by 50%)
	--[30330]  = "Other",				-- Mortal Strike (rank 6) (healing effects reduced by 50%)

	----------------
	-- Other
	----------------
	[56]     = "CC",				-- Stun (some weapons proc)
	[835]    = "CC",				-- Tidal Charm (trinket)
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
	[25046]  = "Silence",			-- Arcane Torrent (blood elf racial)
	[28730]  = "Silence",			-- Arcane Torrent (blood elf racial)
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
	[23115]  = "Snare",				-- Frost Shock
	[19133]  = "Snare",				-- Frost Shock
	[21030]  = "Snare",				-- Frost Shock
	[11538]  = "Snare",				-- Frostbolt
	[21369]  = "Snare",				-- Frostbolt
	[20297]  = "Snare",				-- Frostbolt
	[20806]  = "Snare",				-- Frostbolt
	[20819]  = "Snare",				-- Frostbolt
	[12737]  = "Snare",				-- Frostbolt
	[20792]  = "Snare",				-- Frostbolt
	[20822]  = "Snare",				-- Frostbolt
	[23412]  = "Snare",				-- Frostbolt
	[24942]  = "Snare",				-- Frostbolt
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
	[22800]  = "Root",				-- Entangling Roots
	[20699]  = "Root",				-- Entangling Roots
	[18546]  = "Root",				-- Overdrive
	[22935]  = "Root",				-- Planted
	[12520]  = "Root",				-- Teleport from Azshara Tower
	[12521]  = "Root",				-- Teleport from Azshara Tower
	[12509]  = "Root",				-- Teleport from Azshara Tower
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
	[19136]  = "CC",				-- Stormbolt
	[20685]  = "CC",				-- Storm Bolt
	[16803]  = "CC",				-- Flash Freeze
	[14100]  = "CC",				-- Terrifying Roar
	[17276]  = "CC",				-- Scald
	[13360]  = "CC",				-- Knockdown
	[11430]  = "CC",				-- Slam
	[28335]  = "CC",				-- Whirlwind
	[16451]  = "CC",				-- Judge's Gavel
	[25260]  = "CC",				-- Wings of Despair
	[23275]  = "CC",				-- Dreadful Fright
	[24919]  = "CC",				-- Nauseous
	[21167]  = "CC",				-- Snowball
	[26641]  = "CC",				-- Aura of Fear
	[28315]  = "CC",				-- Aura of Fear
	[21898]  = "CC",				-- Warlock Terror
	[20672]  = "CC",				-- Fade
	[31365]  = "CC",				-- Self Fear
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
	[20310]  = "CC",				-- Stun
	[23775]  = "CC",				-- Stun Forever
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
	[24360]  = "CC",				-- Greater Dreamless Sleep Potion
	[15822]  = "CC",				-- Dreamless Sleep Potion
	[15283]  = "CC",				-- Stunning Blow (Dark Iron Pulverizer weapon)
	[21152]  = "CC",				-- Earthshaker (Earthshaker weapon)
	[16600]  = "CC",				-- Might of Shahram (Blackblade of Shahram sword)
	[16597]  = "Snare",				-- Curse of Shahram (Blackblade of Shahram sword)
	[13496]  = "Snare",				-- Dazed (Mug O' Hurt mace)
	[3238]   = "Other",				-- Nimble Reflexes
	[5990]   = "Other",				-- Nimble Reflexes
	[6615]   = "Other",				-- Free Action Potion
	[11359]  = "Other",				-- Restorative Potion
	[24364]  = "Other",				-- Living Free Action Potion
	[23505]  = "Other",				-- Berserking
	[24378]  = "Other",				-- Berserking
	[19135]  = "Other",				-- Avatar
	[12738]  = "Other",				-- Amplify Damage
	[26198]  = "CC",				-- Whisperings of C'Thun
	[26195]  = "CC",				-- Whisperings of C'Thun
	[26197]  = "CC",				-- Whisperings of C'Thun
	[26258]  = "CC",				-- Whisperings of C'Thun
	[26259]  = "CC",				-- Whisperings of C'Thun
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
	[34510]  = "CC",				-- Stun (Stormherald and Deep Thunder weapons)
	[46567]  = "CC",				-- Rocket Launch (Goblin Rocket Launcher trinket)
	[30501]  = "Silence",			-- Poultryized! (Gnomish Poultryizer trinket)
	[30504]  = "Silence",			-- Poultryized! (Gnomish Poultryizer trinket)
	[30506]  = "Silence",			-- Poultryized! (Gnomish Poultryizer trinket)
	[35474]  = "CC",				-- Drums of Panic (Drums of Panic item)
	[351357] = "CC",				-- Greater Drums of Panic (Greater Drums of Panic item)
	[28504]  = "CC",				-- Major Dreamless Sleep (Major Dreamless Sleep Potion)
	[30216]  = "CC",				-- Fel Iron Bomb
	[30217]  = "CC",				-- Adamantite Grenade
	[30461]  = "CC",				-- The Bigger One
	[31367]  = "Root",				-- Netherweave Net (tailoring item)
	[31368]  = "Root",				-- Heavy Netherweave Net (tailoring item)
	[39965]  = "Root",				-- Frost Grenade
	[36940]  = "CC",				-- Transporter Malfunction
	[51581]  = "CC",				-- Rocket Boots Malfunction
	[12565]  = "CC",				-- Wyatt Test
	[35182]  = "CC",				-- Banish
	[40307]  = "CC",				-- Stasis Field
	[40282]  = "Immune",			-- Possess Spirit Immune
	[45838]  = "Immune",			-- Possess Drake Immune
	[35236]  = "CC",				-- Heat Wave (chance to hit reduced by 35%)
	[29117]  = "CC",				-- Feather Burst (chance to hit reduced by 50%)
	[34088]  = "CC",				-- Feeble Weapons (chance to hit reduced by 75%)
	[45078]  = "Other",				-- Berserk (damage increased by 500%)
	[32378]  = "Other",				-- Filet (healing effects reduced by 50%)
	[32736]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[39595]  = "Other",				-- Mortal Cleave (healing effects reduced by 50%)
	[40220]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[44268]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[34625]  = "Other",				-- Demolish (healing effects reduced by 75%)
	[36513]  = "ImmunePhysical",	-- Intangible Presence (not immune, physical damage taken reduced by 40%)
	[45954]  = "Immune",			-- Ahune's Shield (not immune, damage taken reduced by 75%)
	[46416]  = "Immune",			-- Ahune Self Stun
	[50279]  = "Immune",			-- Copy of Elemental Shield (not immune, damage taken reduced by 75%)
	[29476]  = "Immune",			-- Astral Armor (not immune, damage taken reduced by 90%)
	[30858]  = "Immune",			-- Demon Blood Shell
	[42206]  = "Immune",			-- Protection
	[33581]  = "Immune",			-- Divine Shield
	[40733]  = "Immune",			-- Divine Shield
	[30972]  = "Immune",			-- Evocation
	[31797]  = "Immune",			-- Banish Self
	[34973]  = "Immune",			-- Ravandwyr's Ice Block
	[36527]  = "Immune",			-- Stasis
	[36816]  = "Immune",			-- Water Shield
	[36860]  = "Immune",			-- Cannon Charging (self)
	[36911]  = "Immune",			-- Ice Block
	[37546]  = "Immune",			-- Banish
	[37905]  = "Immune",			-- Metamorphosis
	[37205]  = "Immune",			-- Channel Air Shield
	[38099]  = "Immune",			-- Channel Air Shield
	[38100]  = "Immune",			-- Channel Air Shield
	[37204]  = "Immune",			-- Channel Earth Shield
	[38101]  = "Immune",			-- Channel Earth Shield
	[38102]  = "Immune",			-- Channel Earth Shield
	[37206]  = "Immune",			-- Channel Fire Shield
	[38103]  = "Immune",			-- Channel Fire Shield
	[38104]  = "Immune",			-- Channel Fire Shield
	[36817]  = "Immune",			-- Channel Water Shield
	[38105]  = "Immune",			-- Channel Water Shield
	[38106]  = "Immune",			-- Channel Water Shield
	[38456]  = "Immune",			-- Banish Self
	[38916]  = "Immune",			-- Diplomatic Immunity
	[40357]  = "Immune",			-- Legion Ring - Character Invis and Immune
	[41130]  = "Immune",			-- Toranaku - Character Invis and Immune
	[40671]  = "Immune",			-- Health Funnel
	[41590]  = "Immune",			-- Ice Block
	[42354]  = "Immune",			-- Banish Self
	[46604]  = "Immune",			-- Ice Block
	[11412]  = "ImmunePhysical",	-- Nether Shell
	[27181]  = "ImmunePhysical",	-- Nether Cloak
	[34518]  = "ImmunePhysical",	-- Nether Protection (Embrace of the Twisting Nether & Twisting Nether Chain Shirt items)
	[38026]  = "ImmunePhysical",	-- Viscous Shield
	[36576]  = "ImmuneSpell",		-- Shaleskin (not immune, magic damage taken reduced by 50%)
	[39804]  = "ImmuneSpell",		-- Damage Immunity: Magic
	[39811]  = "ImmuneSpell",		-- Damage Immunity: Fire, Frost, Shadow, Nature, Arcane
	[32904]  = "CC",				-- Pacifying Dust
	[37748]  = "CC",				-- Teron Gorefiend
	[38177]  = "CC",				-- Blackwhelp Net
	[39810]  = "CC",				-- Sparrowhawk Net
	[41621]  = "CC",				-- Wolpertinger Net
	[43906]  = "CC",				-- Feeling Froggy
	[32913]  = "CC",				-- Dazzling Dust
	[33810]  = "CC",				-- Rock Shell
	[37450]  = "CC",				-- Dimensius Feeding
	[38318]  = "CC",				-- Transformation - Blackwhelp
	[30849]  = "Silence",			-- Spell Lock
	[35892]  = "Silence",			-- Suppression
	[34087]  = "Silence",			-- Chilling Words
	[35334]  = "Silence",			-- Nether Shock
	[38913]  = "Silence",			-- Silence
	[38915]  = "CC",				-- Mental Interference
	[41128]  = "CC",				-- Through the Eyes of Toranaku
	[22901]  = "CC",				-- Body Switch
	[31988]  = "CC",				-- Enslave Humanoid
	[37323]  = "CC",				-- Crystal Control
	[37221]  = "CC",				-- Crystal Control
	[38774]  = "CC",				-- Incite Rage
	[33384]  = "CC",				-- Mass Charm
	[36145]  = "CC",				-- Chains of Naberius
	[42185]  = "CC",				-- Brewfest Control Piece
	[44881]  = "CC",				-- Charm Ravager
	[37216]  = "CC",				-- Crystal Control
	[29909]  = "CC",				-- Elven Manacles
	[31533]  = "ImmuneSpell",		-- Spell Reflection (50% chance to reflect a spell)
	[33719]  = "ImmuneSpell",		-- Perfect Spell Reflection
	[34783]  = "ImmuneSpell",		-- Spell Reflection
	[36096]  = "ImmuneSpell",		-- Spell Reflection
	[37885]  = "ImmuneSpell",		-- Spell Reflection
	[38331]  = "ImmuneSpell",		-- Spell Reflection
	[28516]  = "Silence",			-- Sunwell Torrent (Sunwell Blade & Sunwell Orb items)
	[33913]  = "Silence",			-- Soul Burn
	[37031]  = "Silence",			-- Chaotic Temperament
	[39052]  = "Silence",			-- Sonic Burst
	[41247]  = "Silence",			-- Shared Suffering
	[44957]  = "Silence",			-- Nether Shock
	[31955]  = "Disarm",			-- Disarm
	[34097]  = "Disarm",			-- Riposte
	[34099]  = "Disarm",			-- Riposte
	[36208]  = "Disarm",			-- Steal Weapon
	[36510]  = "Disarm",			-- Enchanted Weapons
	[39489]  = "Disarm",			-- Enchanted Weapons
	[41053]  = "Disarm",			-- Whirling Blade
	[47310]  = "Disarm",			-- Direbrew's Disarm
	[30298]  = "CC",				-- Tree Disguise
	[49750]  = "CC",				-- Honey Touched
	[42380]  = "CC",				-- Conflagration
	[42408]  = "CC",				-- Headless Horseman Climax - Head Stun
	[42695]  = "CC",				-- Holiday - Brewfest - Dark Iron Knock-down Power-up
	[42435]  = "CC",				-- Brewfest - Stun
	[47718]  = "CC",				-- Direbrew Charge
	[47442]  = "CC",				-- Barreled!
	[51413]  = "CC",				-- Barreled!
	[47340]  = "CC",				-- Dark Brewmaiden's Stun
	[50093]  = "CC",				-- Chilled
	[29044]  = "CC",				-- Hex
	[30838]  = "CC",				-- Polymorph
	[35840]  = "CC",				-- Conflagration
	[39293]  = "CC",				-- Conflagration
	[40400]  = "CC",				-- Hex
	[42805]  = "CC",				-- Dirty Trick
	[45665]  = "CC",				-- Encapsulate
	[26661]  = "CC",				-- Fear
	[31358]  = "CC",				-- Fear
	[31404]  = "CC",				-- Shrill Cry
	[32040]  = "CC",				-- Scare Daggerfen
	[32241]  = "CC",				-- Fear
	[32709]  = "CC",				-- Death Coil
	[33829]  = "CC",				-- Fleeing in Terror
	[33924]  = "CC",				-- Fear
	[34259]  = "CC",				-- Fear
	[35198]  = "CC",				-- Terrify
	[35954]  = "CC",				-- Death Coil
	[36629]  = "CC",				-- Terrifying Roar
	[36950]  = "CC",				-- Blinding Light
	[37939]  = "CC",				-- Terrifying Roar
	[38065]  = "CC",				-- Death Coil
	[38154]  = "CC",				-- Fear
	[39048]  = "CC",				-- Howl of Terror
	[39119]  = "CC",				-- Fear
	[39176]  = "CC",				-- Fear
	[39210]  = "CC",				-- Fear
	[39661]  = "CC",				-- Death Coil
	[39914]  = "CC",				-- Scare Soulgrinder Ghost
	[40221]  = "CC",				-- Terrifying Roar
	[40259]  = "CC",				-- Boar Charge
	[40636]  = "CC",				-- Bellowing Roar
	[40669]  = "CC",				-- Egbert
	[41436]  = "CC",				-- Panic
	[42690]  = "CC",				-- Terrifying Roar
	[42869]  = "CC",				-- Conflagration
	[44142]  = "CC",				-- Death Coil
	[50368]  = "CC",				-- Ethereal Liqueur Mutation
	[27983]  = "CC",				-- Lightning Strike
	[29516]  = "CC",				-- Dance Trance
	[29903]  = "CC",				-- Dive
	[30657]  = "CC",				-- Quake
	[30688]  = "CC",				-- Shield Slam
	[30790]  = "CC",				-- Arcane Domination
	[30832]  = "CC",				-- Kidney Shot
	[30850]  = "CC",				-- Seduction
	[30857]  = "CC",				-- Wield Axes
	[31274]  = "CC",				-- Knockdown
	[31292]  = "CC",				-- Sleep
	[31390]  = "CC",				-- Knockdown
	[31539]  = "CC",				-- Self Stun Forever
	[31541]  = "CC",				-- Sleep
	[31548]  = "CC",				-- Sleep
	[31733]  = "CC",				-- Charge
	[31819]  = "CC",				-- Cheap Shot
	[31843]  = "CC",				-- Cheap Shot
	[31864]  = "CC",				-- Shield Charge Stun
	[31964]  = "CC",				-- Thundershock
	[31994]  = "CC",				-- Shoulder Charge
	[32015]  = "CC",				-- Knockdown
	[32021]  = "CC",				-- Rushing Charge
	[32023]  = "CC",				-- Hoof Stomp
	[32104]  = "CC",				-- Backhand
	[32105]  = "CC",				-- Kick
	[32150]  = "CC",				-- Infernal
	[32416]  = "CC",				-- Hammer of Justice
	[32779]  = "CC",				-- Repentance
	[32905]  = "CC",				-- Glare
	[33128]  = "CC",				-- Stone Gaze
	[33241]  = "CC",				-- Infernal
	[33422]  = "CC",				-- Phase In
	[33463]  = "CC",				-- Icebolt
	[33487]  = "CC",				-- Addle Humanoid
	[33542]  = "CC",				-- Staff Strike
	[33637]  = "CC",				-- Infernal
	[33781]  = "CC",				-- Ravage
	[33792]  = "CC",				-- Exploding Shot
	[33965]  = "CC",				-- Look Around
	[33937]  = "CC",				-- Stun Phase 2 Units
	[34016]  = "CC",				-- Stun Phase 3 Units
	[34023]  = "CC",				-- Stun Phase 4 Units
	[34024]  = "CC",				-- Stun Phase 5 Units
	[34108]  = "CC",				-- Spine Break
	[34243]  = "CC",				-- Cheap Shot
	[34357]  = "CC",				-- Vial of Petrification
	[34620]  = "CC",				-- Slam
	[34815]  = "CC",				-- Teleport Effect
	[34885]  = "CC",				-- Petrify
	[35202]  = "CC",				-- Paralysis
	[35313]  = "CC",				-- Hypnotic Gaze
	[35382]  = "CC",				-- Rushing Charge
	[35424]  = "CC",				-- Soul Shadows
	[35492]  = "CC",				-- Exhaustion
	[35570]  = "CC",				-- Charge
	[35614]  = "CC",				-- Kaylan's Wrath
	[35856]  = "CC",				-- Stun
	[35957]  = "CC",				-- Mana Bomb Explosion
	[36138]  = "CC",				-- Hammer Stun
	[36254]  = "CC",				-- Judgement of the Flame
	[36402]  = "CC",				-- Sleep
	[36449]  = "CC",				-- Debris
	[36474]  = "CC",				-- Flayer Flu
	[36509]  = "CC",				-- Charge
	[36575]  = "CC",				-- T'chali the Head Freeze State
	[36642]  = "CC",				-- Banished from Shattrath City
	[36671]  = "CC",				-- Banished from Shattrath City
	[36732]  = "CC",				-- Scatter Shot
	[36809]  = "CC",				-- Overpowering Sickness
	[36824]  = "CC",				-- Overwhelming Odor
	[36877]  = "CC",				-- Stun Forever
	[37012]  = "CC",				-- Swoop
	[37073]  = "CC",				-- Drink Eye Potion
	[37103]  = "CC",				-- Smash
	[37417]  = "CC",				-- Warp Charge
	[37493]  = "CC",				-- Feign Death
	[37592]  = "CC",				-- Knockdown
	[37768]  = "CC",				-- Metamorphosis
	[37833]  = "CC",				-- Banish
	[37919]  = "CC",				-- Arcano-dismantle
	[38006]  = "CC",				-- World Breaker
	[38009]  = "CC",				-- Banish
	[38169]  = "CC",				-- Subservience
	[38357]  = "CC",				-- Tidal Surge
	[38510]  = "CC",				-- Sablemane's Sleeping Powder
	[38554]  = "CC",				-- Absorb Eye of Grillok
	[38757]  = "CC",				-- Fel Reaver Freeze
	[38863]  = "CC",				-- Gouge
	[39229]  = "CC",				-- Talon of Justice
	[39568]  = "CC",				-- Stun
	[39594]  = "CC",				-- Cyclone
	[39622]  = "CC",				-- Banish
	[39668]  = "CC",				-- Ambush
	[40135]  = "CC",				-- Shackle Undead
	[40262]  = "CC",				-- Super Jump
	[40358]  = "CC",				-- Death Hammer
	[40370]  = "CC",				-- Banish
	[40380]  = "CC",				-- Legion Ring - Shield Defense Beam
	[40511]  = "CC",				-- Demon Transform 1
	[40398]  = "CC",				-- Demon Transform 2
	[40510]  = "CC",				-- Demon Transform 3
	[40409]  = "CC",				-- Maiev Down
	[40447]  = "CC",				-- Akama Soul Channel
	[40490]  = "CC",				-- Resonant Feedback
	[40497]  = "CC",				-- Chaos Charge
	[40503]  = "CC",				-- Possession Transfer
	[40563]  = "CC",				-- Throw Axe
	[40578]  = "CC",				-- Cyclone
	[40774]  = "CC",				-- Stun Pulse
	[40835]  = "CC",				-- Stasis Field
	[40846]  = "CC",				-- Crystal Prison
	[40858]  = "CC",				-- Ethereal Ring, Cannon Visual
	[40951]  = "CC",				-- Stasis Field
	[41182]  = "CC",				-- Concussive Throw
	[41358]  = "CC",				-- Rizzle's Blackjack
	[41421]  = "CC",				-- Brief Stun
	[41528]  = "CC",				-- Mark of Stormrage
	[41534]  = "CC",				-- War Stomp
	[41592]  = "CC",				-- Spirit Channelling
	[41962]  = "CC",				-- Possession Transfer
	[42386]  = "CC",				-- Sleeping Sleep
	[42621]  = "CC",				-- Fire Bomb
	[42648]  = "CC",				-- Sleeping Sleep
	[43528]  = "CC",				-- Cyclone
	[44031]  = "CC",				-- Tackled!
	[44138]  = "CC",				-- Rocket Launch
	[44415]  = "CC",				-- Blackout
	[44432]  = "CC",				-- Cube Ground State
	[44836]  = "CC",				-- Banish
	[44994]  = "CC",				-- Self Repair
	[45574]  = "CC",				-- Water Tomb
	[45676]  = "CC",				-- Juggle Torch (Quest, Missed)
	[45889]  = "CC",				-- Scorchling Blast
	[45947]  = "CC",				-- Slip
	[46188]  = "CC",				-- Rocket Launch
	[46590]  = "CC",				-- Ninja Grenade [PH]
	[48342]  = "CC",				-- Stun Self
	[50876]  = "CC",				-- Mounted Charge
	[47407]  = "Root",				-- Direbrew's Disarm (precast)
	[47411]  = "Root",				-- Direbrew's Disarm (spin)
	[43207]  = "Root",				-- Headless Horseman Climax - Head's Breath
	[43049]  = "Root",				-- Upset Tummy
	[31287]  = "Root",				-- Entangling Roots
	[31290]  = "Root",				-- Net
	[31409]  = "Root",				-- Wild Roots
	[33356]  = "Root",				-- Self Root Forever
	[33844]  = "Root",				-- Entangling Roots
	[34080]  = "Root",				-- Riposte Stance
	[34569]  = "Root",				-- Chilled Earth
	[34779]  = "Root",				-- Freezing Circle
	[35234]  = "Root",				-- Strangling Roots
	[35247]  = "Root",				-- Choking Wound
	[35327]  = "Root",				-- Jackhammer
	[39194]  = "Root",				-- Jackhammer
	[36252]  = "Root",				-- Felforge Flames
	[36734]  = "Root",				-- Test Whelp Net
	[37823]  = "Root",				-- Entangling Roots
	[38033]  = "Root",				-- Frost Nova
	[38035]  = "Root",				-- Freeze
	[38051]  = "Root",				-- Fel Shackles
	[38338]  = "Root",				-- Net
	[38505]  = "Root",				-- Shackle
	[39268]  = "Root",				-- Chains of Ice
	[40363]  = "Root",				-- Entangling Roots
	[40525]  = "Root",				-- Rizzle's Frost Grenade
	[40590]  = "Root",				-- Rizzle's Frost Grenade (Self
	[40727]  = "Root",				-- Icy Leap
	[41981]  = "Root",				-- Dust Field
	[42716]  = "Root",				-- Self Root Forever (No Visual)
	[43130]  = "Root",				-- Creeping Vines
	[43585]  = "Root",				-- Entangle
	[45255]  = "Root",				-- Rocket Chicken
	[45905]  = "Root",				-- Frost Nova
	[29158]  = "Snare",				-- Inhale
	[29957]  = "Snare",				-- Frostbolt Volley
	[30600]  = "Snare",				-- Blast Wave
	[30942]  = "Snare",				-- Frostbolt
	[30981]  = "Snare",				-- Crippling Poison
	[31296]  = "Snare",				-- Frostbolt
	[32334]  = "Snare",				-- Cyclone
	[32417]  = "Snare",				-- Mind Flay
	[32774]  = "Snare",				-- Avenger's Shield
	[32984]  = "Snare",				-- Frostbolt
	[33047]  = "Snare",				-- Void Bolt
	[34214]  = "Snare",				-- Frost Touch
	[34347]  = "Snare",				-- Frostbolt
	[35252]  = "Snare",				-- Unstable Cloud
	[35263]  = "Snare",				-- Frost Attack
	[35316]  = "Snare",				-- Frostbolt
	[35351]  = "Snare",				-- Sand Breath
	[35955]  = "Snare",				-- Dazed
	[36148]  = "Snare",				-- Chill Nova
	[36278]  = "Snare",				-- Blast Wave
	[36279]  = "Snare",				-- Frostbolt
	[36464]  = "Snare",				-- The Den Mother's Mark
	[36518]  = "Snare",				-- Shadowsurge
	[36839]  = "Snare",				-- Impairing Poison
	[36843]  = "Snare",				-- Slow
	[37330]  = "Snare",				-- Mind Flay
	[37359]  = "Snare",				-- Rush
	[37554]  = "Snare",				-- Avenger's Shield
	[37786]  = "Snare",				-- Bloodmaul Rage
	[37830]  = "Snare",				-- Repolarized Magneto Sphere
	[38032]  = "Snare",				-- Stormbolt
	[38256]  = "Snare",				-- Piercing Howl
	[38534]  = "Snare",				-- Frostbolt
	[38536]  = "Snare",				-- Blast Wave
	[38663]  = "Snare",				-- Slow
	[38767]  = "Snare",				-- Daze
	[38771]  = "Snare",				-- Burning Rage
	[38952]  = "Snare",				-- Frost Arrow
	[39001]  = "Snare",				-- Blast Wave
	[39038]  = "Snare",				-- Blast Wave
	[40417]  = "Snare",				-- Rage
	[40429]  = "Snare",				-- Frostbolt
	[40430]  = "Snare",				-- Frostbolt
	[40653]  = "Snare",				-- Whirlwind
	[40976]  = "Snare",				-- Slimy Spittle
	[41281]  = "Snare",				-- Cripple
	[41439]  = "Snare",				-- Mangle
	[41486]  = "Snare",				-- Frostbolt
	[42396]  = "Snare",				-- Mind Flay
	[42803]  = "Snare",				-- Frostbolt
	[43945]  = "Snare",				-- You're a ...! (Effects)
	[43963]  = "Snare",				-- Retch!
	[44289]  = "Snare",				-- Crippling Poison
	[44937]  = "Snare",				-- Fel Siphon
	[46984]  = "Snare",				-- Cone of Cold
	[46987]  = "Snare",				-- Frostbolt
	[47106]  = "Snare",				-- Soul Flay

	-- PvE
	--[123456] = "PvE",				-- This is just an example, not a real spell
	------------------------
	---- PVE TBC
	------------------------
	-- Karazhan Raid
	-- -- Trash
	[18812]  = "CC",				-- Knockdown
	[29684]  = "CC",				-- Shield Slam
	[29679]  = "CC",				-- Bad Poetry
	[29676]  = "CC",				-- Rolling Pin
	[29490]  = "CC",				-- Seduction
	[29300]  = "CC",				-- Sonic Blast
	[29321]  = "CC",				-- Fear
	[29546]  = "CC",				-- Oath of Fealty
	[29670]  = "CC",				-- Ice Tomb
	[29690]  = "CC",				-- Drunken Skull Crack
	[29486]  = "CC",				-- Bewitching Aura (spell damage done reduced by 50%)
	[29485]  = "CC",				-- Alluring Aura (physical damage done reduced by 50%)
	[37498]  = "CC",				-- Stomp (physical damage done reduced by 50%)
	[41580]  = "Root",				-- Net
	[29309]  = "Immune",			-- Phase Shift
	[37432]  = "Immune",			-- Water Shield (not immune, damage taken reduced by 50%)
	[37434]  = "Immune",			-- Fire Shield (not immune, damage taken reduced by 50%)
	[30969]  = "ImmuneSpell",		-- Reflection
	[29505]  = "Silence",			-- Banshee Shriek
	[30013]  = "Disarm",			-- Disarm
	--[30019]  = "CC",				-- Control Piece
	--[39331]  = "Silence",			-- Game In Session
	[29303]  = "Snare",				-- Wing Beat
	[29540]  = "Snare",				-- Curse of Past Burdens
	[29666]  = "Snare",				-- Frost Shock
	[29667]  = "Snare",				-- Hamstring
	[29837]  = "Snare",				-- Fist of Stone
	[29717]  = "Snare",				-- Cone of Cold
	[29923]  = "Snare",				-- Frostbolt Volley
	[29926]  = "Snare",				-- Frostbolt
	[29292]  = "Snare",				-- Frost Mist
	-- -- Servant Quarters
	[29896]  = "CC",				-- Hyakiss' Web
	[29904]  = "Silence",			-- Sonic Burst
	-- -- Attumen the Huntsman
	[29711]  = "CC",				-- Knockdown
	[29833]  = "CC",				-- Intangible Presence (chance to hit with spells and melee attacks reduced by 50%)
	-- -- Moroes
	[29425]  = "CC",				-- Gouge
	[34694]  = "CC",				-- Blind
	[29382]  = "Immune",			-- Divine Shield
	[29390]  = "Immune",			-- Shield Wall (not immune, damage taken reduced by 75%)
	[29572]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[29570]  = "Snare",				-- Mind Flay
	-- -- Maiden of Virtue
	[29511]  = "CC",				-- Repentance
	[29512]  = "Silence",			-- Holy Ground
	-- -- Opera Event
	[31046]  = "CC",				-- Brain Bash
	[30889]  = "CC",				-- Powerful Attraction
	[30761]  = "CC",				-- Wide Swipe
	[31013]  = "CC",				-- Frightened Scream
	[30752]  = "CC",				-- Terrifying Howl
	[31075]  = "CC",				-- Burning Straw
	[30753]  = "CC",				-- Red Riding Hood
	[30756]  = "CC",				-- Little Red Riding Hood
	[31015]  = "CC",				-- Annoying Yipping
	[31069]  = "Silence",			-- Brain Wipe
	[30887]  = "Other",				-- Devotion
	-- -- The Curator
	[30254]  = "CC",				-- Evocation
	-- -- Terestian Illhoof
	[30115]  = "CC",				-- Sacrifice
	-- -- Shade of Aran
	[29964]  = "CC",				-- Dragon's Breath
	[29963]  = "CC",				-- Mass Polymorph
	[29991]  = "Root",				-- Chains of Ice
	[29954]  = "Snare",				-- Frostbolt
	[29990]  = "Snare",				-- Slow
	[29951]  = "Snare",				-- Blizzard
	[30035]  = "Snare",				-- Mass Slow
	-- -- Nightbane
	[36922]  = "CC",				-- Bellowing Roar
	[30130]  = "CC",				-- Distracting Ash (chance to hit with attacks, spells and abilities reduced by 30%)
	-- -- Prince Malchezaar
	[39095]  = "Other",				-- Amplify Damage (damage taken is increased by 100%)
	[30843]  = "Other",				-- Enfeeble (healing effects and health regeneration reduced by 100%)
	------------------------
	-- Gruul's Lair Raid
	-- -- Trash
	[33709]  = "CC",				-- Charge
	[39171]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	-- -- High King Maulgar & Council
	[33173]  = "CC",				-- Greater Polymorph
	[33130]  = "CC",				-- Death Coil
	[33175]  = "Disarm",			-- Arcane Shock
	[33054]  = "ImmuneMagic",		-- Spell Shield (not immune, magic damage taken reduced by 75%)
	[33147]  = "Other",				-- Greater Power Word: Shield (immune to spell interrupt, immune to stun)
	[33238]  = "Snare",				-- Whirlwind
	[33061]  = "Snare",				-- Blast Wave
	-- -- Gruul the Dragonkiller
	[33652]  = "CC",				-- Stoned
	[36297]  = "Silence",			-- Reverberation
	------------------------
	-- -- Magtheridon’s Lair Raid
	-- -- Trash
	[34437]  = "CC",				-- Death Coil
	[31117]  = "Silence",			-- Unstable Affliction
	-- -- Magtheridon
	[30530]  = "CC",				-- Fear
	[30168]  = "CC",				-- Shadow Cage
	[30205]  = "CC",				-- Shadow Cage
	------------------------
	-- Serpentshrine Cavern Raid
	-- -- Trash
	[38945]  = "CC",				-- Frightening Shout
	[38946]  = "CC",				-- Frightening Shout
	[38626]  = "CC",				-- Domination
	[39002]  = "CC",				-- Spore Quake Knockdown
	[37527]  = "CC",				-- Banish
	[38461]  = "CC",				-- Charge
	[38661]  = "Root",				-- Net
	[39035]  = "Root",				-- Frost Nova
	[39063]  = "Root",				-- Frost Nova
	[38599]  = "ImmuneSpell",		-- Spell Reflection
	[38634]  = "Silence",			-- Arcane Lightning
	[38491]  = "Silence",			-- Silence
	[38572]  = "Other",				-- Mortal Cleave (healing effects reduced by 50%)
	[38631]  = "Snare",				-- Avenger's Shield
	[38644]  = "Snare",				-- Cone of Cold
	[38645]  = "Snare",				-- Frostbolt
	[38995]  = "Snare",				-- Hamstring
	[39062]  = "Snare",				-- Frost Shock
	[39064]  = "Snare",				-- Frostbolt
	[38516]  = "Snare",				-- Cyclone
	-- -- Hydross the Unstable
	[38235]  = "CC",				-- Water Tomb
	[38246]  = "CC",				-- Vile Sludge (damage and healing dealt is reduced by 50%)
	-- -- Leotheras the Blind
	[37749]  = "CC",				-- Consuming Madness
	-- -- Fathom-Lord Karathress
	[38441]  = "CC",				-- Cataclysmic Bolt
	[38234]  = "Snare",				-- Frost Shock
	-- -- Morogrim Tidewalker
	[37871]  = "CC",				-- Freeze
	[37850]  = "CC",				-- Watery Grave
	[38023]  = "CC",				-- Watery Grave
	[38024]  = "CC",				-- Watery Grave
	[38025]  = "CC",				-- Watery Grave
	[38049]  = "CC",				-- Watery Grave
	-- -- Lady Vashj
	[38509]  = "CC",				-- Shock Blast
	[38511]  = "CC",				-- Persuasion
	[38258]  = "CC",				-- Panic
	[38316]  = "Root",				-- Entangle
	[38132]  = "Root",				-- Paralyze (Tainted Core item)
	[38112]  = "Immune",			-- Magic Barrier
	[38262]  = "Snare",				-- Hamstring
	------------------------
	-- The Eye (Tempest Keep) Raid
	-- -- Trash
	[34937]  = "CC",				-- Powered Down
	[37122]  = "CC",				-- Domination
	[37135]  = "CC",				-- Domination
	[37118]  = "CC",				-- Shell Shock
	[39077]  = "CC",				-- Hammer of Justice
	[37289]  = "CC",				-- Dragon's Breath
	[37160]  = "Silence",			-- Silence
	[38712]  = "Snare",				-- Blast Wave
	[37262]  = "Snare",				-- Frostbolt Volley
	[37265]  = "Snare",				-- Cone of Cold
	[39087]  = "Snare",				-- Frost Attack
	[37276]  = "Snare",				-- Mind Flay
	-- -- Void Reaver
	[34190]  = "Silence",			-- Arcane Orb
	-- -- High Astromancer Solarian
	[33390]  = "Silence",			-- Arcane Torrent
	-- -- Kael'thas
	[36834]  = "CC",				-- Arcane Disruption
	[37018]  = "CC",				-- Conflagration
	[44863]  = "CC",				-- Bellowing Roar
	[36797]  = "CC",				-- Mind Control
	[37029]  = "CC",				-- Remote Toy
	[36989]  = "Root",				-- Frost Nova
	[36970]  = "Snare",				-- Arcane Burst
	[36990]  = "Snare",				-- Frostbolt
	------------------------
	-- Black Temple Raid
	-- -- Trash
	[41345]  = "CC",				-- Infatuation
	[39645]  = "CC",				-- Shadow Inferno
	[41150]  = "CC",				-- Fear
	[39574]  = "CC",				-- Charge
	[39674]  = "CC",				-- Banish
	[40936]  = "CC",				-- War Stomp
	[41197]  = "CC",				-- Shield Bash
	[41272]  = "CC",				-- Behemoth Charge
	[41274]  = "CC",				-- Fel Stomp
	[41338]  = "CC",				-- Love Tap
	[41396]  = "CC",				-- Sleep
	[41356]  = "CC",				-- Chest Pains
	[41213]  = "CC",				-- Throw Shield
	[40864]  = "CC",				-- Throbbing Stun
	[41334]  = "CC",				-- Polymorph
	[34654]  = "CC",				-- Blind
	[41070]  = "CC",				-- Death Coil
	[41186]  = "CC",				-- Wyvern Sting
	[41397]  = "CC",				-- Confusion
	[40099]  = "CC",				-- Vile Slime (damage and healing dealt reduced by 50%)
	[40079]  = "CC",				-- Debilitating Spray (damage and healing dealt reduced by 50%)
	[39584]  = "Root",				-- Sweeping Wing Clip
	[40082]  = "Root",				-- Hooked Net
	[41086]  = "Root",				-- Ice Trap
	[40875]  = "Root",				-- Freeze
	[41367]  = "Immune",			-- Divine Shield
	[41104]  = "Immune",			-- Shield Wall (not immune, damage taken reduced by 60%)
	[41196]  = "Immune",			-- Shield Wall (not immune, damage taken reduced by 75%)
	[39666]  = "ImmuneSpell",		-- Cloak of Shadows
	[41371]  = "ImmuneSpell",		-- Shell of Pain
	[41381]  = "ImmuneSpell",		-- Shell of Life
	[39667]  = "Immune",			-- Vanish
	[41978]  = "Other",				-- Debilitating Poison (time between attacks increased and spell cast time increased by 50%)
	[41392]  = "Disarm",			-- Riposte
	[41062]  = "Disarm",			-- Disarm
	[36139]  = "Disarm",			-- Disarm
	[41084]  = "Silence",			-- Silencing Shot
	[41168]  = "Silence",			-- Sonic Strike
	[41097]  = "Snare",				-- Whirlwind
	[41116]  = "Snare",				-- Frost Shock
	[41384]  = "Snare",				-- Frostbolt
	-- -- High Warlord Naj'entus
	[39837]  = "CC",				-- Impaling Spine
	[39872]  = "Immune",			-- Tidal Shield
	-- -- Supremus
	[41922]  = "Snare",				-- Snare Self
	-- -- Shade of Akama
	[41179]  = "CC",				-- Debilitating Strike (physical damage done reduced by 75%)
	-- -- Teron Gorefiend
	[40175]  = "CC",				-- Spirit Chains
	-- -- Gurtogg Bloodboil
	[40597]  = "CC",				-- Eject
	[40491]  = "CC",				-- Bewildering Strike
	[40599]  = "Other",				-- Arcing Smash (healing effects reduced by 50%)
	[40569]  = "Root",				-- Fel Geyser
	[40591]  = "CC",				-- Fel Geyser
	-- -- Reliquary of the Lost
	[41426]  = "CC",				-- Spirit Shock
	[41376]  = "Immune",			-- Spite
	[41377]  = "Immune",			-- Spite
	--[41292]  = "Other",				-- Aura of Suffering (healing effects reduced by 100%)
	-- -- Mother Shahraz
	[40823]  = "Silence",			-- Silencing Shriek
	-- -- The Illidari Council
	[41468]  = "CC",				-- Hammer of Justice
	[41479]  = "CC",				-- Vanish
	[41452]  = "Immune",			-- Devotion Aura (not immune, damage taken reduced by 75%)
	[41478]  = "ImmuneSpell",		-- Dampen Magic (not immune, magic damage taken reduced by 75%)
	[41451]  = "ImmuneSpell",		-- Blessing of Spell Warding
	[41450]  = "ImmunePhysical",	-- Blessing of Protection
	-- -- Illidan
	[40647]  = "CC",				-- Shadow Prison
	[41083]  = "CC",				-- Paralyze
	[40620]  = "CC",				-- Eyebeam
	[40695]  = "CC",				-- Caged
	[40760]  = "CC",				-- Cage Trap
	[41218]  = "CC",				-- Death
	[41220]  = "CC",				-- Death
	[41221]  = "CC",				-- Teleport Maiev
	[39869]  = "Other",				-- Uncaged Wrath
	------------------------
	-- Hyjal Summit Raid
	-- -- Trash
	[31755]  = "CC",				-- War Stomp
	[31610]  = "CC",				-- Knockdown
	[31537]  = "CC",				-- Cannibalize
	[31302]  = "CC",				-- Inferno Effect
	[31651]  = "CC",				-- Banshee Curse (chance to hit reduced by 66%)
	[31731]  = "Immune",			-- Shield Wall (not immune, damage taken reduced by 60%)
	[31662]  = "ImmuneSpell",		-- Anti-Magic Shell (not immune, very big magic shield)
	[42201]  = "Silence",			-- Eternal Silence
	[42205]  = "Silence",			-- Residue of Eternity
	[31622]  = "Snare",				-- Frostbolt
	[31688]  = "Snare",				-- Frost Breath
	[31741]  = "Snare",				-- Slow
	-- -- Rage Winterchill
	[31249]  = "CC",				-- Icebolt
	[31250]  = "Root",				-- Frost Nova
	[31257]  = "Snare",				-- Chilled
	-- -- Anetheron
	[31298]  = "CC",				-- Sleep
	--[31306]  = "Other",				-- Carrion Swarm (healing done is reduced by 75%)
	-- -- Kaz'rogal
	[31480]  = "CC",				-- War Stomp
	[31477]  = "Snare",				-- Cripple
	-- -- Azgalor
	[31408]  = "CC",				-- War Stomp
	[31344]  = "Silence",			-- Howl of Azgalor
	[31406]  = "Snare",				-- Cripple
	-- -- Archimonde
	[31970]  = "CC",				-- Fear
	[32053]  = "Silence",			-- Soul Charge
	[38528]  = "Immune",			-- Protection of Elune
	------------------------
	-- Zul'Aman Raid
	-- -- Trash
	[43356]  = "CC",				-- Pounce
	[43361]  = "CC",				-- Domesticate
	[42220]  = "CC",				-- Conflagration
	[43519]  = "CC",				-- Charge
	[42479]  = "Immune",			-- Protective Ward
	[43362]  = "Root",				-- Electrified Net
	[43364]  = "Snare",				-- Tranquilizing Poison
	[43524]  = "Snare",				-- Frost Shock
	[43530]  = "Snare",				-- Piercing Howl
	-- -- Akil'zon
	[43648]  = "CC",				-- Electrical Storm
	-- -- Nalorakk
	[42398]  = "Silence",			-- Deafening Roar
	-- -- Hex Lord Malacrass
	[43590]  = "CC",				-- Psychic Wail
	[43432]  = "CC",				-- Psychic Scream
	[43433]  = "CC",				-- Blind
	[43550]  = "CC",				-- Mind Control
	[43448]  = "CC",				-- Freezing Trap
	[43426]  = "Root",				-- Frost Nova
	[43443]  = "ImmuneSpell",		-- Spell Reflection
	[43421]  = "Other",				-- Lifebloom (big heal hot)
	[43430]  = "Other",				-- Avenging Wrath (damage increased by 50%)
	[43441]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[43428]  = "Snare",				-- Frostbolt
	-- -- Zul'jin
	[43437]  = "CC",				-- Paralyzed
	[43150]  = "Root",				-- Claw Rage
	------------------------
	-- Sunwell Plateau Raid
	-- -- Trash
	[46762]  = "CC",				-- Shield Slam
	[46288]  = "CC",				-- Petrify
	[46239]  = "CC",				-- Bear Down
	[46561]  = "CC",				-- Fear
	[46427]  = "CC",				-- Domination
	[46280]  = "CC",				-- Polymorph
	[46295]  = "CC",				-- Hex
	[46681]  = "CC",				-- Scatter Shot
	[45029]  = "CC",				-- Corrupting Strike
	[44872]  = "CC",				-- Frost Blast
	[45201]  = "CC",				-- Frost Blast
	[45203]  = "CC",				-- Frost Blast
	[46283]  = "CC",				-- Death Coil
	[45270]  = "CC",				-- Shadowfury
	[46555]  = "Root",				-- Frost Nova
	[46287]  = "Immune",			-- Infernal Defense (immune to most forms of damage, holy damage taken increased by 500%)
	[46296]  = "Other",				-- Necrotic Poison (healing effects reduced by 75%)
	[46299]  = "Snare",				-- Wavering Will
	[46562]  = "Snare",				-- Mind Flay
	[46745]  = "Snare",				-- Chilling Touch
	-- -- Kalecgos & Sathrovarr
	[45066]  = "CC",				-- Self Stun
	[45002]  = "CC",				-- Wild Magic (chance to hit with melee and ranged attacks reduced by 50%)
	[45122]  = "CC",				-- Tail Lash
	-- -- Felmyst
	[46411]  = "CC",				-- Fog of Corruption
	[45717]  = "CC",				-- Fog of Corruption
	-- -- Grand Warlock Alythess & Lady Sacrolash
	[45256]  = "CC",				-- Confounding Blow
	[45342]  = "CC",				-- Conflagration
	-- -- M'uru
	[46102]  = "Root",				-- Spell Fury
	[45996]  = "Other",				-- Darkness (cannot be healed)
	-- -- Kil'jaeden
	[37369]  = "CC",				-- Hammer of Justice
	[45848]  = "Immune",			-- Shield of the Blue (all incoming and outgoing damage is reduced by 95%)
	[45885]  = "Other",				-- Shadow Spike (healing effects reduced by 50%)
	[45737]  = "Snare",				-- Flame Dart
	[45740]  = "Snare",				-- Flame Dart
	[45741]  = "Snare",				-- Flame Dart
	------------------------
	-- TBC World Bosses
	-- -- Doom Lord Kazzak
	[21063]  = "Other",				-- Twisted Reflection
	[32964]  = "Other",				-- Frenzy
	[21066]  = "Snare",				-- Void Bolt
	[36706]  = "Snare",				-- Thunderclap
	-- -- Doomwalker
	[33653]  = "Other",				-- Frenzy
	------------------------
	-- TBC Dungeons
	-- -- Hellfire Ramparts
	[39427]  = "CC",				-- Bellowing Roar
	[30615]  = "CC",				-- Fear
	[30621]  = "CC",				-- Kidney Shot
	[31901]  = "Immune",			-- Demonic Shield (not immune, damage taken reduced by 75%)
	-- -- The Blood Furnace
	[30923]  = "CC",				-- Domination
	[31865]  = "CC",				-- Seduction
	[30940]  = "Immune",			-- Burning Nova
	-- -- The Shattered Halls
	[30500]  = "CC",				-- Death Coil
	[30741]  = "CC",				-- Death Coil
	[30584]  = "CC",				-- Fear
	[37511]  = "CC",				-- Charge
	[23601]  = "CC",				-- Scatter Shot
	[30980]  = "CC",				-- Sap
	[30986]  = "CC",				-- Cheap Shot
	[32588]  = "CC",				-- Concussion Blow
	[36023]  = "Other",				-- Deathblow (healing effects reduced by 50%)
	[36054]  = "Other",				-- Deathblow (healing effects reduced by 50%)
	[32587]  = "Other",				-- Shield Block (chance to block increased by 100%)
	[30989]  = "Snare",				-- Hamstring
	[31553]  = "Snare",				-- Hamstring
	-- -- The Slave Pens
	[34984]  = "CC",				-- Psychic Horror
	[32173]  = "Root",				-- Entangling Roots
	[31983]  = "Root",				-- Earthgrab
	[32192]  = "Root",				-- Frost Nova
	[31986]  = "ImmunePhysical",	-- Stoneskin (melee damage taken reduced by 50%)
	[31554]  = "ImmuneSpell",		-- Spell Reflection (50% chance to reflect a spell)
	[33787]  = "Snare",				-- Cripple
	[15497]  = "Snare",				-- Frostbolt
	-- -- The Underbog
	[31428]  = "CC",				-- Sneeze
	[31932]  = "CC",				-- Freezing Trap Effect
	[35229]  = "CC",				-- Sporeskin (chance to hit with attacks, spells and abilities reduced by 35%)
	[31673]  = "Root",				-- Foul Spores
	[12248]  = "Other",				-- Amplify Damage
	[31719]  = "Snare",				-- Suspension
	-- -- The Steamvault
	[31718]  = "CC",				-- Enveloping Winds
	[38660]  = "CC",				-- Fear
	[35107]  = "Root",				-- Electrified Net
	[31534]  = "ImmuneSpell",		-- Spell Reflection
	[22582]  = "Snare",				-- Frost Shock
	[37865]  = "Snare",				-- Frost Shock
	[37930]  = "Snare",				-- Frostbolt
	[10987]  = "Snare",				-- Geyser
	-- -- Mana-Tombs
	[32361]  = "CC",				-- Crystal Prison
	[34322]  = "CC",				-- Psychic Scream
	[33919]  = "CC",				-- Earthquake
	[34940]  = "CC",				-- Gouge
	[32365]  = "Root",				-- Frost Nova
	[38759]  = "ImmuneSpell",		-- Dark Shell
	[32358]  = "ImmuneSpell",		-- Dark Shell
	[34922]  = "Silence",			-- Shadows Embrace
	[32315]  = "Other",				-- Soul Strike (healing effects reduced by 50%)
	[25603]  = "Snare",				-- Slow
	[32364]  = "Snare",				-- Frostbolt
	[32370]  = "Snare",				-- Frostbolt
	[38064]  = "Snare",				-- Blast Wave
	-- -- Auchenai Crypts
	[32421]  = "CC",				-- Soul Scream
	[32830]  = "CC",				-- Possess
	[32859]  = "Root",				-- Falter
	[33401]  = "Root",				-- Possess
	[32346]  = "CC",				-- Stolen Soul (damage and healing done reduced by 50%)
	[37335]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[37332]  = "Snare",				-- Frost Shock
	-- -- Sethekk Halls
	[40305]  = "CC",				-- Power Burn
	[40184]  = "CC",				-- Paralyzing Screech
	[43309]  = "CC",				-- Polymorph
	[38245]  = "CC",				-- Polymorph
	[40321]  = "CC",				-- Cyclone of Feathers
	[35120]  = "CC",				-- Charm
	[32654]  = "CC",				-- Talon of Justice
	[33961]  = "ImmuneSpell",		-- Spell Reflection
	[32690]  = "Silence",			-- Arcane Lightning
	[38146]  = "Silence",			-- Arcane Lightning
	[12548]  = "Snare",				-- Frost Shock
	[32651]  = "Snare",				-- Howling Screech
	[32674]  = "Snare",				-- Avenger's Shield
	[33967]  = "Snare",				-- Thunderclap
	[35032]  = "Snare",				-- Slow
	[38238]  = "Snare",				-- Frostbolt
	[17503]  = "Snare",				-- Frostbolt
	-- -- Shadow Labyrinth
	[30231]  = "Immune",			-- Banish
	[33547]  = "CC",				-- Fear
	[38791]  = "CC",				-- Banish
	[33563]  = "CC",				-- Draw Shadows
	[33684]  = "CC",				-- Incite Chaos
	[33502]  = "CC",				-- Brain Wash
	[33332]  = "CC",				-- Suppression Blast
	[33686]  = "Silence",			-- Shockwave
	[33499]  = "Silence",			-- Shape of the Beast
	[33666]  = "Snare",				-- Sonic Boom
	[38795]  = "Snare",				-- Sonic Boom
	[38243]  = "Snare",				-- Mind Flay
	-- -- Old Hillsbrad Foothills
	[33789]  = "CC",				-- Frightening Shout
	[50733]  = "CC",				-- Scatter Shot
	[32890]  = "CC",				-- Knockout
	[32864]  = "CC",				-- Kidney Shot
	[41389]  = "CC",				-- Kidney Shot
	[50762]  = "Root",				-- Net
	[12024]  = "Root",				-- Net
	[31911]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[31914]  = "Snare",				-- Sand Breath
	[38384]  = "Snare",				-- Cone of Cold
	-- -- The Black Morass
	[31422]  = "CC",				-- Time Stop
	[38592]  = "ImmuneSpell",		-- Spell Reflection
	[31458]  = "Other",				-- Hasten (melee and movement speed increased by 200%)
	[15708]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[35054]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[31467]  = "Snare",				-- Time Lapse
	[31473]  = "Snare",				-- Sand Breath
	[39049]  = "Snare",				-- Sand Breath
	[31478]  = "Snare",				-- Sand Breath
	-- -- The Mechanar
	[35250]  = "CC",				-- Dragon's Breath
	[35326]  = "CC",				-- Hammer Punch
	[35280]  = "CC",				-- Domination
	[35049]  = "CC",				-- Pound
	[35783]  = "CC",				-- Knockdown
	[35011]  = "CC",				-- Knockdown
	[36333]  = "CC",				-- Anesthetic
	[35268]  = "CC",				-- Inferno
	[35158]  = "ImmuneSpell",		-- Reflective Magic Shield
	[36022]  = "Silence",			-- Arcane Torrent
	[35055]  = "Disarm",			-- The Claw
	[35189]  = "Other",				-- Solar Strike (healing effects reduced by 50%)
	[35056]  = "Snare",				-- Glob of Machine Fluid
	[38923]  = "Snare",				-- Glob of Machine Fluid
	[35178]  = "Snare",				-- Shield Bash
	-- -- The Arcatraz
	[36924]  = "CC",				-- Mind Rend
	[39017]  = "CC",				-- Mind Rend
	[39415]  = "CC",				-- Fear
	[37162]  = "CC",				-- Domination
	[36866]  = "CC",				-- Domination
	[39019]  = "CC",				-- Complete Domination
	[38850]  = "CC",				-- Deafening Roar
	[36887]  = "CC",				-- Deafening Roar
	[36700]  = "CC",				-- Hex
	[36840]  = "CC",				-- Polymorph
	[38896]  = "CC",				-- Polymorph
	[36634]  = "CC",				-- Emergence
	[36719]  = "CC",				-- Explode
	[38830]  = "CC",				-- Explode
	[36835]  = "CC",				-- War Stomp
	[38911]  = "CC",				-- War Stomp
	[36862]  = "CC",				-- Gouge
	[36778]  = "CC",				-- Soul Steal (physical damage done reduced by 45%)
	[35963]  = "Root",				-- Improved Wing Clip
	[36512]  = "Root",				-- Knock Away
	[36827]  = "Root",				-- Hooked Net
	[38912]  = "Root",				-- Hooked Net
	[37480]  = "Root",				-- Bind
	[38900]  = "Root",				-- Bind
	[36173]  = "Other",				-- Gift of the Doomsayer (chance to heal enemy when healed)
	[36693]  = "Other",				-- Necrotic Poison (healing effects reduced by 45%)
	[36917]  = "Other",				-- Magma-Thrower's Curse (healing effects reduced by 50%)
	[35965]  = "Snare",				-- Frost Arrow
	[38942]  = "Snare",				-- Frost Arrow
	[36646]  = "Snare",				-- Sightless Touch
	[38815]  = "Snare",				-- Sightless Touch
	[36710]  = "Snare",				-- Frostbolt
	[38826]  = "Snare",				-- Frostbolt
	[36741]  = "Snare",				-- Frostbolt Volley
	[38837]  = "Snare",				-- Frostbolt Volley
	[36786]  = "Snare",				-- Soul Chill
	[38843]  = "Snare",				-- Soul Chill
	-- -- The Botanica
	[34716]  = "CC",				-- Stomp
	[34661]  = "CC",				-- Sacrifice
	[32323]  = "CC",				-- Charge
	[34639]  = "CC",				-- Polymorph
	[34752]  = "CC",				-- Freezing Touch
	[34770]  = "CC",				-- Plant Spawn Effect
	[34801]  = "CC",				-- Sleep
	[34551]  = "Immune",			-- Tree Form
	[35399]  = "ImmuneSpell",		-- Spell Reflection
	[22127]  = "Root",				-- Entangling Roots
	[34353]  = "Snare",				-- Frost Shock
	[34782]  = "Snare",				-- Bind Feet
	[34800]  = "Snare",				-- Impending Coma
	[35507]  = "Snare",				-- Mind Flay
	-- -- Magisters' Terrace
	[47109]  = "CC",				-- Power Feedback
	[44233]  = "CC",				-- Power Feedback
	[46183]  = "CC",				-- Knockdown
	[46026]  = "CC",				-- War Stomp
	[46024]  = "CC",				-- Fel Iron Bomb
	[46184]  = "CC",				-- Fel Iron Bomb
	[44352]  = "CC",				-- Overload
	[38595]  = "CC",				-- Fear
	[44320]  = "CC",				-- Mana Rage
	[44547]  = "CC",				-- Deadly Embrace
	[44765]  = "CC",				-- Banish
	[44475]  = "ImmuneSpell",		-- Magic Dampening Field (magic damage taken reduced by 75%)
	[44177]  = "Root",				-- Frost Nova
	[47168]  = "Root",				-- Improved Wing Clip
	[46182]  = "Silence",			-- Snap Kick
	[44505]  = "Other",				-- Drink Fel Infusion (damage and attack speed increased dramatically)
	[44534]  = "Other",				-- Wretched Strike (healing effects reduced by 50%)
	[44286]  = "Snare",				-- Wing Clip
	[44504]  = "Snare",				-- Wretched Frostbolt
	[44606]  = "Snare",				-- Frostbolt
	[46035]  = "Snare",				-- Frostbolt
	[46180]  = "Snare",				-- Frost Shock
	[21401]  = "Snare",				-- Frost Shock
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
	[24004]  = "CC",				-- Sleep
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
	[25756]  = "CC",				-- Purge
	[25187]  = "Snare",				-- Hive'Zara Catalyst
	-- -- Kurinnaxx
	[25656]  = "CC",				-- Sand Trap
	-- -- General Rajaxx
	[19134]  = "CC",				-- Frightening Shout
	[29544]  = "CC",				-- Frightening Shout
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
	[21808]  = "CC",				-- Landslide
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
	[12890]  = "CC",				-- Deep Slumber
	[6607]   = "CC",				-- Lash
	[25774]  = "CC",				-- Mind Shatter
	[33126]  = "Disarm",			-- Dropped Weapon
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
	[20989]  = "CC",				-- Sleep
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

-- Helper function to sort an array of arrays by the second element of the value array (from highest to lowest)
local function OrderArrayBy2El(a, b)
	return a[2] > b[2]
end

-------------------------------------------------------------------------------
-- Global references for attaching icons to various unit frames
local anchors = {
	None = {}, -- empty but necessary
	Blizzard = {
		player       = "PlayerPortrait",
		player2      = "PlayerPortrait",
		pet          = "PetPortrait",
		target       = "TargetFramePortrait",
		targettarget = "TargetFrameToTPortrait",
		focus        = "FocusFramePortrait",
		focustarget  = "FocusFrameToTPortrait",
		party1       = "PartyMemberFrame1Portrait",
		party2       = "PartyMemberFrame2Portrait",
		party3       = "PartyMemberFrame3Portrait",
		party4       = "PartyMemberFrame4Portrait",
		--party1pet    = "PartyMemberFrame1PetFramePortrait",
		--party2pet    = "PartyMemberFrame2PetFramePortrait",
		--party3pet    = "PartyMemberFrame3PetFramePortrait",
		--party4pet    = "PartyMemberFrame4PetFramePortrait",
		arena1       = "ArenaEnemyFrame1ClassPortrait",
		arena2       = "ArenaEnemyFrame2ClassPortrait",
		arena3       = "ArenaEnemyFrame3ClassPortrait",
		arena4       = "ArenaEnemyFrame4ClassPortrait",
		arena5       = "ArenaEnemyFrame5ClassPortrait",
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
	BlizzardNameplates = {
		nameplate1   = "NamePlate1",
		nameplate2   = "NamePlate2",
		nameplate3   = "NamePlate3",
		nameplate4   = "NamePlate4",
		nameplate5   = "NamePlate5",
		nameplate6   = "NamePlate6",
		nameplate7   = "NamePlate7",
		nameplate8   = "NamePlate8",
		nameplate9   = "NamePlate9",
		nameplate10  = "NamePlate10",
		nameplate11  = "NamePlate11",
		nameplate12  = "NamePlate12",
		nameplate13  = "NamePlate13",
		nameplate14  = "NamePlate14",
		nameplate15  = "NamePlate15",
		nameplate16  = "NamePlate16",
		nameplate17  = "NamePlate17",
		nameplate18  = "NamePlate18",
		nameplate19  = "NamePlate19",
		nameplate20  = "NamePlate20",
		nameplate21  = "NamePlate21",
		nameplate22  = "NamePlate22",
		nameplate23  = "NamePlate23",
		nameplate24  = "NamePlate24",
		nameplate25  = "NamePlate25",
		nameplate26  = "NamePlate26",
		nameplate27  = "NamePlate27",
		nameplate28  = "NamePlate28",
		nameplate29  = "NamePlate29",
		nameplate30  = "NamePlate30",
		nameplate31  = "NamePlate31",
		nameplate32  = "NamePlate32",
		nameplate33  = "NamePlate33",
		nameplate34  = "NamePlate34",
		nameplate35  = "NamePlate35",
		nameplate36  = "NamePlate36",
		nameplate37  = "NamePlate37",
		nameplate38  = "NamePlate38",
		nameplate39  = "NamePlate39",
		nameplate40  = "NamePlate40"
	},
	Perl = {
		player       = "Perl_Player_PortraitFrame",
		player2      = "Perl_Player_PortraitFrame",
		pet          = "Perl_Player_Pet_PortraitFrame",
		target       = "Perl_Target_PortraitFrame",
		targettarget = "Perl_Target_Target_PortraitFrame",
		focus        = "Perl_Focus_PortraitFrame",
		focustarget  = "Perl_Focus_Target_PortraitFrame",
		party1       = "Perl_Party_MemberFrame1_PortraitFrame",
		party2       = "Perl_Party_MemberFrame2_PortraitFrame",
		party3       = "Perl_Party_MemberFrame3_PortraitFrame",
		party4       = "Perl_Party_MemberFrame4_PortraitFrame",
	},
	XPerl = {	-- and Z-Perl
		player       = "XPerl_PlayerportraitFrameportrait",
		player2      = "XPerl_PlayerportraitFrameportrait",
		pet          = "XPerl_Player_PetportraitFrameportrait",
		target       = "XPerl_TargetportraitFrameportrait",
		targettarget = "XPerl_TargettargetportraitFrameportrait",
		focus        = "XPerl_FocusportraitFrameportrait",
		focustarget  = "XPerl_FocustargetportraitFrameportrait",
		party1       = "XPerl_party1portraitFrameportrait",
		party2       = "XPerl_party2portraitFrameportrait",
		party3       = "XPerl_party3portraitFrameportrait",
		party4       = "XPerl_party4portraitFrameportrait",
	},
	LUI = {
		player       = "oUF_LUI_player",
		player2      = "oUF_LUI_player",
		pet          = "oUF_LUI_pet",
		target       = "oUF_LUI_target",
		targettarget = "oUF_LUI_targettarget",
		focus        = "oUF_LUI_focus",
		focustarget  = "oUF_LUI_focustarget",
		party1       = "oUF_LUI_partyUnitButton1",
		party2       = "oUF_LUI_partyUnitButton2",
		party3       = "oUF_LUI_partyUnitButton3",
		party4       = "oUF_LUI_partyUnitButton4",
	},
	SyncFrames = {
		arena1       = "SyncFrame1Class",
		arena2       = "SyncFrame2Class",
		arena3       = "SyncFrame3Class",
		arena4       = "SyncFrame4Class",
		arena5       = "SyncFrame5Class",
	},
	SUF = {
		player       = "SUFUnitplayer.portrait",
		player2      = "SUFUnitplayer.portrait",
		pet          = "SUFUnitpet.portrait",
		target       = "SUFUnittarget.portrait",
		targettarget = "SUFUnittargettarget.portrait",
		focus        = "SUFUnitfocus.portrait",
		focustarget  = "SUFUnitfocustarget.portrait",
		party1       = "SUFHeaderpartyUnitButton1.portrait",
		party2       = "SUFHeaderpartyUnitButton2.portrait",
		party3       = "SUFHeaderpartyUnitButton3.portrait",
		party4       = "SUFHeaderpartyUnitButton4.portrait",
		arena1       = "SUFHeaderarenaUnitButton1.portrait",
		arena2       = "SUFHeaderarenaUnitButton2.portrait",
		arena3       = "SUFHeaderarenaUnitButton3.portrait",
		arena4       = "SUFHeaderarenaUnitButton4.portrait",
		arena5       = "SUFHeaderarenaUnitButton5.portrait",
	},
	LUF = {
		player       = "LUFUnitplayer.StatusPortrait.model",
		player2      = "LUFUnitplayer.StatusPortrait.model",
		pet          = "LUFUnitpet.StatusPortrait.model",
		target       = "LUFUnittarget.StatusPortrait.model",
		targettarget = "LUFUnittargettarget.StatusPortrait.model",
		focus        = "LUFUnitfocus.StatusPortrait.model",
		focustarget  = "LUFUnitfocustarget.StatusPortrait.model",
		party1       = "LUFHeaderpartyUnitButton1.StatusPortrait.model",
		party2       = "LUFHeaderpartyUnitButton2.StatusPortrait.model",
		party3       = "LUFHeaderpartyUnitButton3.StatusPortrait.model",
		party4       = "LUFHeaderpartyUnitButton4.StatusPortrait.model",
		arena1       = "LUFHeaderarenaUnitButton1.StatusPortrait.model",
		arena2       = "LUFHeaderarenaUnitButton2.StatusPortrait.model",
		arena3       = "LUFHeaderarenaUnitButton3.StatusPortrait.model",
		arena4       = "LUFHeaderarenaUnitButton4.StatusPortrait.model",
		arena5       = "LUFHeaderarenaUnitButton5.StatusPortrait.model",
	},
	PitBullUF = {
		player       = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Player"]..".Portrait" or nil,
		player2      = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Player"]..".Portrait" or nil,
		pet          = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Player's pet"]..".Portrait" or nil,
		target       = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Target"]..".Portrait" or nil,
		targettarget = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["%s's target"]:format(LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Target"])..".Portrait" or nil,
		focus        = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Focus"]..".Portrait" or nil,
		focustarget  = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["%s's target"]:format(LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Focus"])..".Portrait" or nil,
		party1       = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton1"..".Portrait" or nil,
		party2       = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton2"..".Portrait" or nil,
		party3       = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton3"..".Portrait" or nil,
		party4       = LibStub("AceLocale-3.0",true) and LibStub("AceLocale-3.0",true):GetLocale("PitBull4",true) and "PitBull4_Groups_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Party"].."UnitButton4"..".Portrait" or nil,
	},
	SpartanUI_2D = {
		player       = "SUI_UF_player.Portrait2D",
		player2      = "SUI_UF_player.Portrait2D",
		pet          = "SUI_UF_pet.Portrait2D",
		target       = "SUI_UF_target.Portrait2D",
		targettarget = "SUI_UF_targettarget.Portrait2D",
		focus        = "SUI_UF_focus.Portrait2D",
		focustarget  = "SUI_UF_focustarget.Portrait2D",
	},
	SpartanUI_3D = {
		player       = "SUI_UF_player.Portrait3D",
		player2      = "SUI_UF_player.Portrait3D",
		pet          = "SUI_UF_pet.Portrait3D",
		target       = "SUI_UF_target.Portrait3D",
		targettarget = "SUI_UF_targettarget.Portrait3D",
		focus        = "SUI_UF_focus.Portrait3D",
		focustarget  = "SUI_UF_focustarget.Portrait3D",
	},
	SpartanUI_2D_PlayerInParty = {
		partyplayer  = "SUI_partyFrameHeaderUnitButton1.Portrait2D",
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
		partyplayer  = "SUI_partyFrameHeaderUnitButton1.Portrait3D",
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
		player2      = "GwPlayerUnitFrame.portrait",
		pet          = "GwPlayerPetFrame.portrait",
		target       = "GwTargetUnitFrame.portrait",
		focus        = "GwFocusUnitFrame.portrait",
		party1       = "GwPartyFrame1.portrait",
		party2       = "GwPartyFrame2.portrait",
		party3       = "GwPartyFrame3.portrait",
		party4       = "GwPartyFrame4.portrait",
	},
	nUI = {
		player       = "nUI_PartyUnit_Player_Portrait",
		player2      = "nUI_PartyUnit_Player_Portrait",
		target       = "nUI_PartyUnit_Target_Portrait",
		focus        = "nUI_PartyUnit_Focus_Portrait",
		party1       = "nUI_PartyUnit_Party1_Portrait",
		party2       = "nUI_PartyUnit_Party2_Portrait",
		party3       = "nUI_PartyUnit_Party3_Portrait",
		party4       = "nUI_PartyUnit_Party4_Portrait",
	},
	Tukui = {
		player       = "TukuiPlayerFrame.Portrait",
		player2      = "TukuiPlayerFrame.Portrait",
		target       = "TukuiTargetFrame.Portrait",
	},
	ElvUI = {
		player       = "ElvUF_Player.Portrait",
		player2      = "ElvUF_Player.Portrait",
		pet          = "ElvUF_Pet.Portrait",
		target       = "ElvUF_Target.Portrait",
		targettarget = "ElvUF_TargetTarget.Portrait",
		focus        = "ElvUF_Focus.Portrait",
		focustarget  = "ElvUF_FocusTarget.Portrait",
	},
	ElvUI_PlayerInParty = {
		partyplayer  = "ElvUF_PartyGroup1UnitButton1.Portrait",
		party1       = "ElvUF_PartyGroup1UnitButton2.Portrait",
		party2       = "ElvUF_PartyGroup1UnitButton3.Portrait",
		party3       = "ElvUF_PartyGroup1UnitButton4.Portrait",
		party4       = "ElvUF_PartyGroup1UnitButton5.Portrait",
	},
	ElvUI_NoPlayerInParty = {
		party1       = "ElvUF_PartyGroup1UnitButton1.Portrait",
		party2       = "ElvUF_PartyGroup1UnitButton2.Portrait",
		party3       = "ElvUF_PartyGroup1UnitButton3.Portrait",
		party4       = "ElvUF_PartyGroup1UnitButton4.Portrait",
	},
	Gladius = {
		arena1       = "GladiusClassIconFramearena1",
		arena2       = "GladiusClassIconFramearena2",
		arena3       = "GladiusClassIconFramearena3",
		arena4       = "GladiusClassIconFramearena4",
		arena5       = "GladiusClassIconFramearena5",
	},
	GladiusEx = {
		party1       = "GladiusExClassIconFrameparty1",
		party2       = "GladiusExClassIconFrameparty2",
		party3       = "GladiusExClassIconFrameparty3",
		party4       = "GladiusExClassIconFrameparty4",
		arena1       = "GladiusExClassIconFramearena1",
		arena2       = "GladiusExClassIconFramearena2",
		arena3       = "GladiusExClassIconFramearena3",
		arena4       = "GladiusExClassIconFramearena4",
		arena5       = "GladiusExClassIconFramearena5",
	}
	-- more to come here?
}

-------------------------------------------------------------------------------
-- Default settings
local DBdefaults = {
	version = 2.2, -- This is the settings version, not necessarily the same as the LoseControl version
	noCooldownCount = false,
	noBlizzardCooldownCount = true,
	disablePartyInBG = true,
	disablePartyInArena = false,
	disableArenaInBG = true,
	disablePartyInRaid = true,
	disableRaidInBG = false,
	disableRaidInArena = true,
	disablePlayerTargetTarget = false,
	disableTargetTargetTarget = false,
	disablePlayerTargetPlayerTargetTarget = true,
	disableTargetDeadTargetTarget = true,
	disablePlayerFocusTarget = false,
	disableFocusFocusTarget = false,
	disablePlayerFocusPlayerFocusTarget = true,
	disableFocusDeadFocusTarget = true,
	showNPCInterruptsTarget = true,
	showNPCInterruptsFocus = true,
	showNPCInterruptsTargetTarget = true,
	showNPCInterruptsFocusTarget = true,
	showNPCInterruptsNameplate = true,
	duplicatePlayerPortrait = true,
	showPartyplayerIcon = true,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
		focus = {
			enabled = true,
			size = 56,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
		focustarget = {
			enabled = true,
			size = 36,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
		arena1 = {
			enabled = true,
			size = 28,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					enemy    = true
				}
			}
		},
		arena2 = {
			enabled = true,
			size = 28,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					enemy    = true
				}
			}
		},
		arena3 = {
			enabled = true,
			size = 28,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					enemy    = true
				}
			}
		},
		arena4 = {
			enabled = true,
			size = 28,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					enemy    = true
				}
			}
		},
		arena5 = {
			enabled = true,
			size = 28,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				debuff = {
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = true, Root = true, Snare = true }
				},
				interrupt = {
					enemy    = true
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
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
		nameplate1 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate2 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate3 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate4 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate5 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate6 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate7 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate8 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate9 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate10 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate11 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate12 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate13 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate14 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate15 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate16 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate17 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate18 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate19 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate20 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate21 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate22 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate23 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate24 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate25 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate26 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate27 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate28 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate29 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate30 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate31 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate32 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate33 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate34 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate35 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate36 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate37 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate38 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate39 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
			}
		},
		nameplate40 = {
			enabled = true,
			size = 42,
			alpha = 1,
			interruptBackgroundAlpha = 0.7,
			interruptBackgroundVertexColor = { r = 1, g = 1, b = 1 },
			interruptMiniIconsAlpha = 0.8,
			useSpellInsteadSchoolMiniIcon = false,
			swipeAlpha = 0.8,
			frameLevel = 0,
			anchor = "BlizzardNameplates",
			relativePoint ="RIGHT",
			point = "LEFT",
			x = 0,
			y = 0,
			categoriesEnabled = {
				buff =      {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				debuff = {
					friendly = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false },
					enemy    = { PvE = true, Immune = true, ImmuneSpell = true, ImmunePhysical = true, CC = true, Silence = true, Disarm = true, Other = false, Root = true, Snare = false }
				},
				interrupt = { friendly = true, enemy = true }
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
						self:UNIT_AURA(self.unitId, true, nil, 300)
						self.timerActive = true
						C_Timer.After(1.0, self.UpdateStateFuncCache)
					else
						self.timerActive = false
					end
				end
				-- Attribute state-unitexists from RegisterUnitWatch
				self:SetScript("OnAttributeChanged", function(self, name, value)
					if (self.frame.enabled and not self.unlockMode) then
						self.unitGUID = UnitGUID(self.unitId)
						self:UNIT_AURA(self.unitId, true, nil, 200)
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
							self:UNIT_AURA(self.unitId, true, nil, -30)
						else
							self:UNIT_AURA(self.unitId, true, nil, 30)
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
										self:UNIT_AURA(self.unitId, true, nil, 40)
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
										self:UNIT_AURA(self.unitId, true, nil, 43)
									end
								end)
							end
						end)
					end
				end
				TARGETTOTARGET_ANCHORTRIGGER_UNIT_AURA_HOOK = true
			end
		elseif unitId == "focus" then
			self:RegisterUnitEvent("UNIT_AURA", unitId)
			self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		elseif unitId == "focustarget" then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:RegisterEvent("PLAYER_FOCUS_CHANGED")
			self:RegisterUnitEvent("UNIT_TARGET", "focus")
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
			if (not FOCUSTOTARGET_ANCHORTRIGGER_UNIT_AURA_HOOK) then
				-- Update unit frecuently when exists
				self.UpdateStateFuncCache = function() self:UpdateState(true) end
				function self:UpdateState(autoCall)
					if not autoCall and self.timerActive then return end
					if (self.frame.enabled and not self.unlockMode and UnitExists(self.unitId)) then
						self.unitGUID = UnitGUID(self.unitId)
						self:UNIT_AURA(self.unitId, true, nil, 300)
						self.timerActive = true
						C_Timer.After(1.0, self.UpdateStateFuncCache)
					else
						self.timerActive = false
					end
				end
				-- Attribute state-unitexists from RegisterUnitWatch
				self:SetScript("OnAttributeChanged", function(self, name, value)
					if (self.frame.enabled and not self.unlockMode) then
						self.unitGUID = UnitGUID(self.unitId)
						self:UNIT_AURA(self.unitId, true, nil, 200)
					end
					if value then
						self:UpdateState()
					end
				end)
				-- FocusTarget Blizzard Frame Show
				FocusFrameToT:HookScript("OnShow", function()
					if (self.frame.enabled and not self.unlockMode) then
						self.unitGUID = UnitGUID(self.unitId)
						if self.frame.anchor == "Blizzard" then
							self:UNIT_AURA(self.unitId, true, nil, -30)
						else
							self:UNIT_AURA(self.unitId, true, nil, 30)
						end
					end
				end)
				-- FocusTarget Blizzard Debuff Show/Hide
				for i = 1, 4 do
					local FframeToTDebuff = _G["FocusFrameToTDebuff"..i]
					if (FframeToTDebuff ~= nil) then
						FframeToTDebuff:HookScript("OnShow", function()
							if (self.frame.enabled) then
								local timeCombatLogAuraEvent = GetTime()
								C_Timer.After(0.01, function()	-- execute in some close next frame to depriorize this event
									if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < timeCombatLogAuraEvent)) then
										self.unitGUID = UnitGUID(self.unitId)
										self:UNIT_AURA(self.unitId, true, nil, 30)
									end
								end)
							end
						end)
						FframeToTDebuff:HookScript("OnHide", function()
							if (self.frame.enabled) then
								local timeCombatLogAuraEvent = GetTime()
								C_Timer.After(0.01, function()	-- execute in some close next frame to depriorize this event
									if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < timeCombatLogAuraEvent)) then
										self.unitGUID = UnitGUID(self.unitId)
										self:UNIT_AURA(self.unitId, true, nil, 31)
									end
								end)
							end
						end)
					end
				end
				FOCUSTOTARGET_ANCHORTRIGGER_UNIT_AURA_HOOK = true
			end
		elseif unitId == "pet" then
			self:RegisterUnitEvent("UNIT_AURA", unitId)
			self:RegisterUnitEvent("UNIT_PET", "player")
		elseif strfind(unitId, "nameplate") then
			self:CheckNameplateAnchor()
			self:RegisterUnitEvent("UNIT_AURA", unitId)
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
		elseif unitId == "focus" then
			self:UnregisterEvent("UNIT_AURA")
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		elseif unitId == "focustarget" then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
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
		elseif strfind(unitId, "nameplate") then
			self:UnregisterEvent("UNIT_AURA")
			self:CheckNameplateAnchor()
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
			( LoseControlDB.disableRaidInBG and strfind((self.fakeUnitId or self.unitId), "raid") ) or
			( LoseControlDB.disableArenaInBG and strfind((self.fakeUnitId or self.unitId), "arena") )
		)
	) and not (
		inInstance and instanceType == "arena" and (
			( LoseControlDB.disablePartyInArena and strfind((self.fakeUnitId or self.unitId), "party") ) or
			( LoseControlDB.disableRaidInArena and strfind((self.fakeUnitId or self.unitId), "raid") )
		)
	) and not (
		IsInRaid() and LoseControlDB.disablePartyInRaid and strfind((self.fakeUnitId or self.unitId), "party") and not (inInstance and (instanceType=="arena" or instanceType=="pvp"))
	) and not (
		not(IsInGroup()) and (self.fakeUnitId == "partyplayer")
	)
	return enabled
end

-- Function to set the size of the schoolinterrupt icons based on the size of the main icon
local function SetInterruptIconsSize(iconFrame, iconSize)
	local interruptIconSize = (iconSize * 0.88) / 3
	local interruptIconOffset = (iconSize * 0.06)
	local frame = iconFrame.frame or LoseControlDB.frames[iconFrame.fakeUnitId or iconFrame.unitId]
	if frame.anchor == "Blizzard" and not(iconFrame.useCompactPartyFrames) then
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
	for k, v in ipairs(iconFrame.iconQueueInterruptList) do
		v:SetWidth(interruptIconSize)
		v:SetHeight(interruptIconSize)
		v:SetPoint("BOTTOMRIGHT", iconFrame.interruptIconOrderPos[v.interruptIconOrder or k][1], iconFrame.interruptIconOrderPos[v.interruptIconOrder or k][2])
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

-- Function to update the Blizzard anchors of the raid icons with their corresponding CompactRaidFrame
local function UpdateRaidIconsAnchorCompactRaidFrame(compactRaidFrame, key, value)
	if compactRaidFrame:IsForbidden() then return end
	local name = compactRaidFrame:GetName()
	if not name or not name:match("^Compact") then return end
	if (key == nil or key == "unit") then
		local anchorUnitId = value or compactRaidFrame.displayedUnit or compactRaidFrame.unit
		if (anchorUnitId ~= nil) then
			if anchorUnitId == "player" then
				anchorUnitId = "partyplayer"
			end
			local isPartyFrame = strfind(anchorUnitId, "party")
			if (strfind(anchorUnitId, "raid") or isPartyFrame) then
				local icon = LCframes[anchorUnitId]
				if (icon ~= nil and (not(isPartyFrame) or icon.useCompactPartyFrames)) then
					local frame = icon.frame or LoseControlDB.frames[anchorUnitId]
					if (frame ~= nil) then
						if isPartyFrame then
							anchors.Blizzard[anchorUnitId] = name
						else
							anchors.BlizzardRaidFrames[anchorUnitId] = name
						end
						if (frame.anchor == "BlizzardRaidFrames" or (isPartyFrame and frame.anchor == "Blizzard")) then
							icon.anchor = compactRaidFrame
							icon.parent:SetParent(icon.anchor:GetParent())
							icon.defaultFrameStrata = icon:GetFrameStrata()
							icon:GetParent():ClearAllPoints()
							icon:GetParent():SetPoint(
								frame.point or "CENTER",
								icon.anchor,
								frame.relativePoint or "CENTER",
								frame.x or 0,
								frame.y or 0
							)
							local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
							if frameLevel < 0 then frameLevel = 0 end
							icon:GetParent():SetFrameLevel(frameLevel)
							icon:SetFrameLevel(frameLevel)
						end
						if (icon.frame and icon:GetEnabled() and (icon.frame.anchor == "BlizzardRaidFrames" or (isPartyFrame and frame.anchor == "Blizzard"))) then
							icon:UNIT_AURA(icon.unitId, true, nil, -80)
						end
					end
				end
			end
			if (IsInRaid() and GetCVarBool("useCompactPartyFrames") and not(isPartyFrame) and strfind(anchorUnitId, "raid")) then
				local partyframes = { "party1", "party2", "party3", "party4", "player" }
				for _, v in ipairs(partyframes) do
					if UnitIsUnit(anchorUnitId, v) then
						UpdateRaidIconsAnchorCompactRaidFrame(compactRaidFrame, "unit", v)
						break
					end
				end
			end
		end
	end
end

-- Function to hook the raid frame and anchors the LoseControl raid frames to their corresponding blizzard raid frame
local function HookCompactRaidFrame(compactRaidFrame)
	if not(LCHookedCompactRaidFrames[compactRaidFrame]) then
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

-- Function to update all the Blizzard anchors of the raid icons with their corresponding CompactRaidFrame
local function UpdateAllRaidIconsAnchorCompactRaidFrame()
	for i = 1, 40 do
		local compactRaidFrame = _G["CompactRaidFrame"..i]
		if (compactRaidFrame ~= nil) then
			UpdateRaidIconsAnchorCompactRaidFrame(compactRaidFrame)
		end
	end
	for i = 1, 8 do
		for j = 1, 5 do
			local compactRaidFrame = _G["CompactRaidGroup"..i.."Member"..j]
			if (compactRaidFrame ~= nil) then
				UpdateRaidIconsAnchorCompactRaidFrame(compactRaidFrame)
			end
		end
	end
end

-- Function to update and hook the Blizzard anchors of the raid icons with their corresponding CompactRaidFrame
local function UpdateAndHookAllRaidIconsAnchorCompactRaidFrame()
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
end

-- Function to hook the raid frames and anchors the LoseControl raid frames to their corresponding blizzard raid frame
local function MainHookCompactRaidFrames()
	if not LoseControlCompactRaidFramesHooked then
		local somePartyRaidEnabledAndBlizzAnchored = false
		for i = 1, 40 do
			if LoseControlDB.frames["raid"..i].enabled and LoseControlDB.frames["raid"..i].anchor == "BlizzardRaidFrames" then
				somePartyRaidEnabledAndBlizzAnchored = true
				break
			end
		end
		if GetCVarBool("useCompactPartyFrames") then
			for i = 1, 4 do
				if LoseControlDB.frames["party"..i].enabled and LoseControlDB.frames["party"..i].anchor == "Blizzard" then
					somePartyRaidEnabledAndBlizzAnchored = true
					break
				end
			end
			if LoseControlDB.frames.partyplayer.enabled and LoseControlDB.frames.partyplayer.anchor == "Blizzard" then
				somePartyRaidEnabledAndBlizzAnchored = true
			end
		end
		if somePartyRaidEnabledAndBlizzAnchored then
			UpdateAndHookAllRaidIconsAnchorCompactRaidFrame()
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
		if _G.LoseControlDB.version < DBdefaults.version or _G.LoseControlDB.version >= 3.0 then
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
		self.VERSION = "2.05"
		self.noCooldownCount = LoseControlDB.noCooldownCount
		self.noBlizzardCooldownCount = LoseControlDB.noBlizzardCooldownCount
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
		playerGUID = UnitGUID("player")
		_, _, playerClass = UnitClass("player")
		if Masque then
			for _, v in pairs(LCframes) do
				v.MasqueGroup = Masque:Group(addonName, (v.fakeUnitId or v.unitId))
				if (LoseControlDB.frames[(v.fakeUnitId or v.unitId)].anchor ~= "Blizzard" or v.useCompactPartyFrames) then
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

function LoseControl:CheckNameplateAnchor()
	local newAnchor = GetNamePlateForUnit(self.unitId, false)
	if ((newAnchor ~= nil) and not(newAnchor:IsForbidden())) then
		if (self.anchor ~= newAnchor) then
			local name = newAnchor:GetName()
			if not name or not name:match("^NamePlate") then return end
			anchors.BlizzardNameplates[self.unitId] = name
			local frame = self.frame or LoseControlDB.frames[self.fakeUnitId or self.unitId]
			if (frame.anchor == "BlizzardNameplates") then
				self.anchor = newAnchor
				self.parent:SetParent(self.anchor)
				self.defaultFrameStrata = self:GetFrameStrata()
				self:GetParent():ClearAllPoints()
				self:GetParent():SetPoint(
					frame.point or "CENTER",
					self.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
			end
		end
	else
		anchors.BlizzardNameplates[self.unitId] = "UIParent"
		local frame = self.frame or LoseControlDB.frames[self.fakeUnitId or self.unitId]
		if (frame.anchor == "BlizzardNameplates") then
			self.anchor = UIParent
			self.parent:SetParent(nil)
			self.defaultFrameStrata = self:GetFrameStrata()
			self:GetParent():ClearAllPoints()
			self:GetParent():SetPoint(
				frame.point or "CENTER",
				self.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
		end
	end
end

function LoseControl:CheckAnchor(forceCheck)
	if (strfind((self.fakeUnitId or self.unitId), "raid")) then return end
	if ((self.frame.anchor ~= "None") and (forceCheck or self.anchor == UIParent or self.anchor == nil)) then
		local anchorObj = anchors[self.frame.anchor]
		if anchorObj ~= nil then
			local updateFrame = false
			local newAnchor = _G[anchorObj[self.fakeUnitId or self.unitId]]
			if (newAnchor and self.anchor ~= newAnchor) then
				self.anchor = newAnchor
				updateFrame = true
			end
			if (type(anchorObj[self.fakeUnitId or self.unitId])=="string") then
				newAnchor = _GF(anchorObj[self.fakeUnitId or self.unitId])
				if (newAnchor and self.anchor ~= newAnchor) then
					self.anchor = newAnchor
					updateFrame = true
				end
			elseif (type(anchorObj[self.fakeUnitId or self.unitId])=="table") then
				newAnchor = anchorObj[self.fakeUnitId or self.unitId]
				if (newAnchor and self.anchor ~= newAnchor) then
					self.anchor = newAnchor
					updateFrame = true
				end
			end
			if (newAnchor ~= nil and updateFrame) then
				local frame = self.frame
				self.parent:SetParent(self.anchor:GetParent())
				self.defaultFrameStrata = self:GetFrameStrata()
				self:GetParent():ClearAllPoints()
				self:GetParent():SetPoint(
					frame.point or "CENTER",
					self.anchor,
					frame.relativePoint or "CENTER",
					frame.x or 0,
					frame.y or 0
				)
				local PositionXEditBox, PositionYEditBox, FrameLevelEditBox
				if strfind(self.fakeUnitId or self.unitId, "party") then
					if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
						FrameLevelEditBox = _G['LoseControlOptionsPanelpartyFrameLevelEditBox']
					end
				elseif strfind(self.fakeUnitId or self.unitId, "arena") then
					if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelarenaPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelarenaPositionYEditBox']
						FrameLevelEditBox = _G['LoseControlOptionsPanelarenaFrameLevelEditBox']
					end
				elseif strfind(self.fakeUnitId or self.unitId, "raid") then
					if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
						FrameLevelEditBox = _G['LoseControlOptionsPanelraidFrameLevelEditBox']
					end
				elseif strfind(self.fakeUnitId or self.unitId, "nameplate") then
					PositionXEditBox = _G['LoseControlOptionsPanelnameplatePositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanelnameplatePositionYEditBox']
					FrameLevelEditBox = _G['LoseControlOptionsPanelnameplateFrameLevelEditBox']
				elseif self.fakeUnitId ~= "player2" then
					PositionXEditBox = _G['LoseControlOptionsPanel'..self.unitId..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..self.unitId..'PositionYEditBox']
					FrameLevelEditBox = _G['LoseControlOptionsPanel'..self.unitId..'FrameLevelEditBox']
				end
				if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
					PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
					PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
					FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
					if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
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
				local frameLevel = (self.anchor:GetParent() and self.anchor:GetParent():GetFrameLevel() or self.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
				if frameLevel < 0 then frameLevel = 0 end
				self:GetParent():SetFrameLevel(frameLevel)
				self:SetFrameLevel(frameLevel)
			end
		end
	end
end

-- Initialize a frame's position and register for events
function LoseControl:PLAYER_ENTERING_WORLD() -- this correctly anchors enemy arena frames that aren't created until you zone into an arena
	local unitId = self.unitId
	self.frame = LoseControlDB.frames[self.fakeUnitId or unitId] -- store a local reference to the frame's settings
	local frame = self.frame
	local enabled = self:GetEnabled()
	C_Timer.After(8, function()	-- delay checking to make sure all variables of the other addons are loaded
		self:CheckAnchor(true)
	end)
	self.unitGUID = UnitGUID(unitId)
	self.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][self.fakeUnitId or unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][self.fakeUnitId or unitId])=="string") and _GF(anchors[frame.anchor][self.fakeUnitId or unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][self.fakeUnitId or unitId])=="table") and anchors[frame.anchor][self.fakeUnitId or unitId] or UIParent))
	self.parent:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
	self.defaultFrameStrata = self:GetFrameStrata()
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:GetParent():ClearAllPoints()
	self:SetWidth(frame.size)
	self:SetHeight(frame.size)
	self:GetParent():SetWidth(frame.size)
	self:GetParent():SetHeight(frame.size)
	self:RegisterUnitEvents(enabled)
	
	self:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0)
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
	elseif strfind((self.fakeUnitId or unitId), "arena") then
		if ((self.fakeUnitId or unitId) == ((_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown'] ~= nil) and UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown']) or "arena1")) then
			PositionXEditBox = _G['LoseControlOptionsPanelarenaPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelarenaPositionYEditBox']
			FrameLevelEditBox = _G['LoseControlOptionsPanelarenaFrameLevelEditBox']
		end
	elseif strfind((self.fakeUnitId or unitId), "raid") then
		if ((self.fakeUnitId or unitId) == ((_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'] ~= nil) and UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown']) or "raid1")) then
			PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
			FrameLevelEditBox = _G['LoseControlOptionsPanelraidFrameLevelEditBox']
		end
	elseif strfind((self.fakeUnitId or unitId), "nameplate") then
		PositionXEditBox = _G['LoseControlOptionsPanelnameplatePositionXEditBox']
		PositionYEditBox = _G['LoseControlOptionsPanelnameplatePositionYEditBox']
		FrameLevelEditBox = _G['LoseControlOptionsPanelnameplateFrameLevelEditBox']
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
	local frameLevel = (self.anchor:GetParent() and self.anchor:GetParent():GetFrameLevel() or self.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
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
	for _, v in ipairs(self.iconQueueInterruptList) do
		v:SetAlpha(frame.interruptMiniIconsAlpha)
	end
	
	if strfind((self.fakeUnitId or unitId), "party") then
		self:CheckStatusPartyFrameChange()
	end
	C_Timer.After(0.01, MainHookCompactRaidFrames)	-- execute in some close next frame
	
	if frame.anchor == "Blizzard" and not(self.useCompactPartyFrames) then
		if self.textureicon then
			SetPortraitToTexture(self.texture, self.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
		end
		self:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
		self:SetSwipeColor(0, 0, 0, frame.swipeAlpha*0.75)
		self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
	else
		if self.textureicon then
			self.texture:SetTexture(self.textureicon)
		end
		self:SetSwipeColor(0, 0, 0, frame.swipeAlpha)
		self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
	end
	
	--self:SetAlpha(frame.alpha) -- doesn't seem to work; must manually set alpha after the cooldown is displayed, otherwise it doesn't apply.
	self:Hide()
	self:GetParent():Hide()
	
	if enabled and not self.unlockMode then
		self.maxExpirationTime = 0
		self:UNIT_AURA(self.unitId, true, nil, 0)
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
		self:CheckAnchor(frame.anchor ~= "Blizzard" or self.useCompactPartyFrames)
	end
	if (enabled and IsInRaid() and (frame.anchor == "Blizzard") and (self.useCompactPartyFrames) and strfind(self.fakeUnitId or self.unitId, "party") and GetCVarBool("useCompactPartyFrames") and UnitExists(self.unitId)) then
		UpdateAllRaidIconsAnchorCompactRaidFrame()
	end
	if enabled and not self.unlockMode then
		self.maxExpirationTime = 0
		self:UNIT_AURA(unitId, true, nil, 0)
	end
end

function LoseControl:GROUP_JOINED()
	self:GROUP_ROSTER_UPDATE()
end

function LoseControl:GROUP_LEFT()
	self:GROUP_ROSTER_UPDATE()
end

function LoseControl:NAME_PLATE_UNIT_ADDED(unitId)
	if (unitId == self.unitId) then
		local enabled = self:GetEnabled()
		if enabled then
			self.unitGUID = UnitGUID(unitId)
			self:CheckNameplateAnchor()
			if not self.unlockMode then
				self.maxExpirationTime = 0
				if (UnitExists(unitId)) then
					self:UNIT_AURA(unitId, true, nil, 0)
				else
					local timeCombatLogAuraEvent = GetTime()
					C_Timer.After(0.01, function()	-- execute in some close next frame to depriorize this event
						if (not(self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < timeCombatLogAuraEvent)) then
							self.unitGUID = UnitGUID(unitId)
							self:CheckNameplateAnchor()
							self:UNIT_AURA(unitId, true, nil, 3)
						end
					end)
				end
			end
		end
	end
end

function LoseControl:NAME_PLATE_UNIT_REMOVED(unitId)
	if (unitId == self.unitId) then
		local enabled = self:GetEnabled()
		if enabled then
			self.unitGUID = nil
			self:CheckNameplateAnchor()
			self.maxExpirationTime = 0
			if self.iconInterruptBackground:IsShown() then
				self.iconInterruptBackground:Hide()
			end
			self:Hide()
			self:GetParent():Hide()
		end
	end
end

local function UpdateUnitAuraByUnitGUID(unitGUID, typeUpdate)
	for k, v in pairs(LCframes) do
		local enabled = v:GetEnabled()
		if enabled and not v.unlockMode then
			if v.unitGUID == unitGUID then
				v:UNIT_AURA(v.unitId, true, nil, typeUpdate)
				if (k == "player") and LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, typeUpdate)
				end
			end
		end
	end
end

function LoseControl:ARENA_OPPONENT_UPDATE()
	local unitId = self.unitId
	local frame = self.frame
	if (frame == nil) or (unitId == nil) or not(strfind(unitId, "arena")) then
		return
	end
	local enabled = self:GetEnabled()
	self:RegisterUnitEvents(self:GetEnabled())
	self.unitGUID = UnitGUID(self.unitId)
	self:CheckAnchor(true)
	if enabled and not self.unlockMode then
		self.maxExpirationTime = 0
		self:UNIT_AURA(unitId, true, nil, 0)
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

function LoseControl:CheckStatusPartyFrameChange(value)
	if (value == nil) then value = GetCVarBool("useCompactPartyFrames") end
	if (value ~= self.useCompactPartyFrames) then
		local unitId = self.fakeUnitId or self.unitId
		if not(strfind(unitId, "party")) then return end
		self.useCompactPartyFrames = value
		local frame = self.frame or LoseControlDB.frames[unitId]
		if (frame.anchor == "Blizzard") or (unitId == "partyplayer") then
			if (value) then
				MainHookCompactRaidFrames()
				anchors.Blizzard[unitId] = nil
				UpdateAllRaidIconsAnchorCompactRaidFrame()
				if not(frame.noCompactFrame) then
					frame.noCompactFrame = { 
						["point"] = frame.point,
						["relativePoint"] = frame.relativePoint,
						["frameStrata"] = frame.frameStrata,
						["frameLevel"] = frame.frameLevel,
						["x"] = frame.x,
						["y"] = frame.y,
						["size"] = frame.size
					}
					if (unitId == "partyplayer") then frame.noCompactFrame.anchor = frame.anchor end
				end
				if frame.compactFrame then
					frame.point = frame.compactFrame.point
					frame.relativePoint = frame.compactFrame.relativePoint
					frame.frameStrata = frame.compactFrame.frameStrata
					frame.frameLevel = frame.compactFrame.frameLevel
					frame.x = frame.compactFrame.x
					frame.y = frame.compactFrame.y
					frame.size = frame.compactFrame.size
					if (unitId == "partyplayer") then frame.anchor = frame.compactFrame.anchor or "Blizzard" end
					frame.compactFrame = nil
				else
					if (unitId == "partyplayer") then frame.anchor = "Blizzard" end
				end
			else
				local numId = -1
				if (unitId == "party1") then
					numId = 1
				elseif (unitId == "party2") then
					numId = 2
				elseif (unitId == "party3") then
					numId = 3
				elseif (unitId == "party4") then
					numId = 4
				elseif (unitId == "partyplayer") then
					numId = 0
				end
				if (numId <= 0) then
					anchors.Blizzard[unitId] = nil
				else
					anchors.Blizzard[unitId] = "PartyMemberFrame" .. numId .. "Portrait"
				end
				if not(frame.compactFrame) then
					frame.compactFrame = { 
						["point"] = frame.point,
						["relativePoint"] = frame.relativePoint,
						["frameStrata"] = frame.frameStrata,
						["frameLevel"] = frame.frameLevel,
						["x"] = frame.x,
						["y"] = frame.y,
						["size"] = frame.size
					}
					if (unitId == "partyplayer") then frame.compactFrame.anchor = frame.anchor end
				end
				frame.point = (frame.noCompactFrame and frame.noCompactFrame.point) or (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].point) or nil
				frame.relativePoint = (frame.noCompactFrame and frame.noCompactFrame.relativePoint) or (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].relativePoint) or nil
				frame.frameStrata = (frame.noCompactFrame and frame.noCompactFrame.frameStrata) or (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].frameStrata) or nil
				frame.frameLevel = (frame.noCompactFrame and frame.noCompactFrame.frameLevel) or (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].frameLevel) or 0
				frame.x = (frame.noCompactFrame and frame.noCompactFrame.x) or (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].x) or nil
				frame.y = (frame.noCompactFrame and frame.noCompactFrame.y) or (DBdefaults.frames[unitId] and frame.anchor == DBdefaults.frames[unitId].anchor and DBdefaults.frames[unitId].y) or nil
				frame.size = (frame.noCompactFrame and frame.noCompactFrame.size) or 36
				if (unitId == "partyplayer") then frame.anchor = (frame.noCompactFrame and frame.noCompactFrame.anchor) or "None" end
				frame.noCompactFrame = nil
			end
			self.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][unitId])=="string") and _GF(anchors[frame.anchor][unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][unitId])=="table") and anchors[frame.anchor][unitId] or UIParent))
			self.parent:SetParent(self.anchor:GetParent())
			self.defaultFrameStrata = self:GetFrameStrata()
			self:GetParent():ClearAllPoints()
			self:GetParent():SetPoint(
				frame.point or "CENTER",
				self.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
			if (frame.frameStrata ~= nil) then
				self:GetParent():SetFrameStrata(frame.frameStrata)
				self:SetFrameStrata(frame.frameStrata)
			end
			local frameLevel = (self.anchor:GetParent() and self.anchor:GetParent():GetFrameLevel() or self.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
			if frameLevel < 0 then frameLevel = 0 end
			self:GetParent():SetFrameLevel(frameLevel)
			self:SetFrameLevel(frameLevel)
			self:SetWidth(frame.size)
			self:SetHeight(frame.size)
			self:GetParent():SetWidth(frame.size)
			self:GetParent():SetHeight(frame.size)
			if (frame.anchor == "Blizzard" and not(self.useCompactPartyFrames)) then
				SetPortraitToTexture(self.texture, self.textureicon)
				self:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
				self:SetSwipeColor(0, 0, 0, frame.swipeAlpha*0.75)
				self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
				if self.MasqueGroup then
					self.MasqueGroup:RemoveButton(self:GetParent())
					HideTheButtonDefaultSkin(self:GetParent())
				end
				SetInterruptIconsSize(self, frame.size)
			else
				self.texture:SetTexture(self.textureicon)
				self:SetSwipeColor(0, 0, 0, frame.swipeAlpha)
				self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
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
				SetInterruptIconsSize(self, frame.size)
			end
			if unitId == "party1" then
				if _G['LoseControlOptionsPanelpartyIconSizeSlider'] then
					local SizeSlider = _G['LoseControlOptionsPanelpartyIconSizeSlider']
					SizeSlider:SetValue(frame.size)
					SizeSlider.editbox:SetText(frame.size)
					SizeSlider.editbox:SetCursorPosition(0)
				end
			end
			if (_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'] ~= nil and unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'])) then
				local PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
				local PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
				local FrameLevelEditBox = _G['LoseControlOptionsPanelpartyFrameLevelEditBox']
				if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
					PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
					PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
					FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
					if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
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
				local AnchorPointDropDown = _G['LoseControlOptionsPanelpartyAnchorPointDropDown']
				if (AnchorPointDropDown) then
					UIDropDownMenu_Initialize(AnchorPointDropDown, AnchorPointDropDown.initialize)
					UIDropDownMenu_SetSelectedValue(AnchorPointDropDown, frame.relativePoint or "CENTER")
					if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
						UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
					else
						UIDropDownMenu_DisableDropDown(AnchorPointDropDown)
					end
				end
				local AnchorIconPointDropDown = _G['LoseControlOptionsPanelpartyAnchorIconPointDropDown']
				if (AnchorIconPointDropDown) then
					UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
					UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
					if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
						UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
					else
						UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown)
					end
				end
				local AnchorFrameStrataDropDown = _G['LoseControlOptionsPanelpartyAnchorFrameStrataDropDown']
				if (AnchorFrameStrataDropDown) then
					UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
					UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
					if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
						UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
					else
						UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown)
					end
				end
			end
		end
	end
end

function LoseControl:CVAR_UPDATE(eventName, value)
	if (eventName == "USE_RAID_STYLE_PARTY_FRAMES") then
		self:CheckStatusPartyFrameChange()
	end
end

-- This event check interrupts and targettarget/focustarget unit aura triggers
function LoseControl:COMBAT_LOG_EVENT_UNFILTERED()
	if self.unitId == "target" then
		-- Check Interrupts
		local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, _, _, exSpellId, _, spellSchool = CombatLogGetCurrentEventInfo()
		if (destGUID ~= nil and destGUID ~= "") then
			if (event == "SPELL_INTERRUPT") then
				local duration = interruptsIds[spellId]
				if (duration ~= nil) then
					if (strfind(destGUID, "^Player-")) then
						local durationOri = duration
						if (destGUID == playerGUID) then
							local itemIdHead = GetInventoryItemID("player", 1)
							local itemIdNeck = GetInventoryItemID("player", 2)
							local itemIdRing1 = GetInventoryItemID("player", 11)
							local itemIdRing2 = GetInventoryItemID("player", 12)
							-- spellId = 35126 [Interrupted Mechanic Duration -20% (Item) (doesn't stack)]
							if (itemIdHead == 21517) or (itemIdNeck == 29347) or (itemIdNeck == 30008) then
								duration = durationOri * 0.8
							-- spellId = 42184 [Interrupted Mechanic Duration -10% (Item) (doesn't stack)]
							elseif (itemIdRing1 == 18345) or (itemIdRing2 == 18345) or (itemIdNeck == 16009) then
								duration = durationOri * 0.9
							end
							if playerClass == 7 then
								local duration2 = duration
								local _, _, _, _, focusedMindRank = GetTalentInfo(3, 14)	-- Focused Mind (talent) (Shaman) [Interrupted Mechanic Duration -10%/-20%/-30% (Talent) (doesn't stack)]
								if (focusedMindRank == 3) then
									duration2 = durationOri * 0.7
								elseif (focusedMindRank == 2) then
									duration2 = durationOri * 0.8
								elseif (focusedMindRank == 1) then
									duration2 = durationOri * 0.9
								end
								if (duration2 < duration) then
									duration = duration2
								end
							elseif playerClass == 2 then
								local duration2 = duration
								local _, _, _, _, improvConcAuraRank = GetTalentInfo(2, 12)	-- Improved Concentration Aura (talent) (Paladin) [Interrupted Mechanic Duration -10%/-20%/-30% (Talent) (doesn't stack)]
								if (improvConcAuraRank > 0) then
									for i = 1, 120 do
										local _, _, _, _, _, _, _, _, _, auxSpellId = UnitAura("player", i)
										if not auxSpellId then break end
										if auxSpellId == 19746 then		-- Concentration Aura (Paladin)
											if (improvConcAuraRank == 3) then
												duration2 = durationOri * 0.7
											elseif (improvConcAuraRank == 2) then
												duration2 = durationOri * 0.8
											elseif (improvConcAuraRank == 1) then
												duration2 = durationOri * 0.9
											end
											break
										end
									end
								end
								if (duration2 < duration) then
									duration = duration2
								end
							end
						end
					end
					local expirationTime = GetTime() + duration
					if debug then print("interrupt", ")", destGUID, "|", GetSpellInfo(spellId), "|", duration, "|", expirationTime, "|", spellId) end
					local priority = LoseControlDB.priority.Interrupt
					local _, _, icon = GetSpellInfo(spellId)
					local _, _, exIcon = GetSpellInfo(exSpellId)
					if (InterruptAuras[destGUID] == nil) then
						InterruptAuras[destGUID] = {}
					end
					tblinsert(InterruptAuras[destGUID], { ["spellId"] = spellId, ["duration"] = duration, ["expirationTime"] = expirationTime, ["priority"] = priority, ["icon"] = (icon or 134400), ["spellSchool"] = spellSchool, ["exSpellId"] = exSpellId, ["exIcon"] = (exIcon or 134400) })
					UpdateUnitAuraByUnitGUID(destGUID, -20)
				end
			elseif (((event == "UNIT_DIED") or (event == "UNIT_DESTROYED") or (event == "UNIT_DISSIPATES")) and (select(2, GetPlayerInfoByGUID(destGUID)) ~= "HUNTER")) then
				if (InterruptAuras[destGUID] ~= nil) then
					InterruptAuras[destGUID] = nil
					UpdateUnitAuraByUnitGUID(destGUID, -21)
				end
			end
		end
	elseif (self.unitId == "targettarget" and self.unitGUID ~= nil and (not(LoseControlDB.disablePlayerTargetTarget) or (self.unitGUID ~= playerGUID)) and (not(LoseControlDB.disableTargetTargetTarget) or (self.unitGUID ~= LCframes.target.unitGUID))) or (self.unitId == "focustarget" and self.unitGUID ~= nil and (not(LoseControlDB.disablePlayerFocusTarget) or (self.unitGUID ~= playerGUID)) and (not(LoseControlDB.disableFocusFocusTarget) or (self.unitGUID ~= LCframes.focus.unitGUID))) then
		-- Manage targettarget/focustarget UNIT_AURA triggers
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
						self:UNIT_AURA(self.unitId, true, nil, 3)
					end
				end)
			end
		end
	end
end

-- This is the main event. Check for (de)buffs and update the frame icon and cooldown.
function LoseControl:UNIT_AURA(unitId, isFullUpdate, updatedAuras, typeUpdate) -- fired when a (de)buff is gained/lost
	if (((typeUpdate ~= nil and typeUpdate > 0) or (typeUpdate == nil and self.unitId == "targettarget") or (typeUpdate == nil and self.unitId == "focustarget")) and (self.lastTimeUnitAuraEvent == GetTime())) then return end
	if ((self.unitId == "targettarget" or self.unitId == "focustarget") and (not UnitIsUnit(unitId, self.unitId))) then return end
	if (isFullUpdate == false) and (updatedAuras ~= nil) then
		local anyInterestAura = false
		for _, v in pairs(updatedAuras) do
			if (spellIds[v.spellId] ~= nil) then
				anyInterestAura = true
				break
			end
		end
		if not(anyInterestAura) then return end
	end
	local priority = LoseControlDB.priority
	local maxPriority = 1
	local maxExpirationTime = 0
	local maxPriorityIsInterrupt = false
	local Icon, Duration
	local forceEventUnitAuraAtEnd = false
	self.lastTimeUnitAuraEvent = GetTime()

	if ((self.anchor ~= nil and self.anchor:IsVisible() and (self.anchor ~= UIParent or self.frame.anchor == "None")) or (self.frame.anchor ~= "None" and self.frame.anchor ~= "Blizzard" and self.frame.anchor ~= "BlizzardRaidFrames" and self.frame.anchor ~= "BlizzardNameplates" and self.anchor ~= UIParent)) and UnitExists(self.unitId) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetPlayerTargetTarget) or not(UnitIsUnit("player", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetTarget) or not(UnitIsUnit("targettarget", "player")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetTargetTarget) or not(UnitIsUnit("targettarget", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetDeadTargetTarget) or (UnitHealth("target") > 0))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disablePlayerFocusPlayerFocusTarget) or not(UnitIsUnit("player", "focus") and UnitIsUnit("player", "focustarget")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disablePlayerFocusTarget) or not(UnitIsUnit("focustarget", "player")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disableFocusFocusTarget) or not(UnitIsUnit("focustarget", "focus")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disableFocusDeadFocusTarget) or (UnitHealth("focus") > 0))) then
		local reactionToPlayer = (strfind(self.unitId, "arena") or ((self.unitId == "target" or self.unitId == "focus" or self.unitId == "targettarget" or self.unitId == "focustarget") and UnitCanAttack("player", unitId))) and "enemy" or "friendly"
		-- Check debuffs
		for i = 1, 120 do
			local localForceEventUnitAuraAtEnd = false
			local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i, "HARMFUL")
			if not spellId then break end -- no more debuffs, terminate the loop
			if (self.unitId == "targettarget") or (self.unitId == "focustarget") then
				if debug then print(unitId, "debuff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
			end
			
			if duration == 0 and expirationTime == 0 then
				expirationTime = GetTime() + 1 -- normal expirationTime = 0
			elseif expirationTime > 0 then
				localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
			end
			
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
			local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i) -- defaults to "HELPFUL" filter
			if not spellId then break end -- no more debuffs, terminate the loop
			if debug then print(unitId, "buff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
			
			if duration == 0 and expirationTime == 0 then
				expirationTime = GetTime() + 1 -- normal expirationTime = 0
			elseif expirationTime > 0 then
				localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
			end
			
			-- exceptions
			if (spellId == 605) or (spellId == 10911) or (spellId == 10912) or (spellId == 24020) then	-- Mind Control and Axe Flurry
				spellId = 1
			elseif (spellId == 19574 and (self.unitId == "pet" or (playerClass ~= 1 and playerClass ~= 2 and playerClass ~= 5 and playerClass ~= 9))) then	-- Bestial Wrath
				newCategory = "Other"
			elseif (spellId == 34471 and (self.unitId == "player" or (playerClass ~= 1 and playerClass ~= 2 and playerClass ~= 5 and playerClass ~= 9))) then	--  The Beast Within
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
		if ((self.unitGUID ~= nil) and (priority.Interrupt > 0) and self.frame.categoriesEnabled.interrupt[reactionToPlayer] and (UnitIsPlayer(self.unitId) or (((self.unitId ~= "target") or (LoseControlDB.showNPCInterruptsTarget)) and ((self.unitId ~= "focus") or (LoseControlDB.showNPCInterruptsFocus)) and ((self.unitId ~= "targettarget") or (LoseControlDB.showNPCInterruptsTargetTarget)) and ((self.unitId ~= "focustarget") or (LoseControlDB.showNPCInterruptsFocusTarget)) and (not(strfind(self.unitId, "nameplate")) or (LoseControlDB.showNPCInterruptsNameplate))))) then
			if (self.frame.useSpellInsteadSchoolMiniIcon) then
				local spellQueueInterruptList = { }
				if (InterruptAuras[self.unitGUID] ~= nil) then
					for k, v in pairs(InterruptAuras[self.unitGUID]) do
						local Priority = v.priority
						local expirationTime = v.expirationTime
						local duration = v.duration
						local icon = v.icon
						local exIcon = v.exIcon
						if (expirationTime < GetTime()) then
							InterruptAuras[self.unitGUID][k] = nil
							if (next(InterruptAuras[self.unitGUID]) == nil) then
								InterruptAuras[self.unitGUID] = nil
							end
						else
							if Priority then
								tblinsert(spellQueueInterruptList, { exIcon, expirationTime })
								local nextTimerUpdate = expirationTime - GetTime() + 0.05
								if nextTimerUpdate < 0.05 then
									nextTimerUpdate = 0.05
								end
								C_Timer.After(nextTimerUpdate, function()
									if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < (GetTime() - 0.04))) then
										self:UNIT_AURA(self.unitId, true, nil, 20)
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
				tblsort(spellQueueInterruptList, OrderArrayBy2El)
				local numSpellQueueList = #spellQueueInterruptList
				for qsId, qsFrame in ipairs(self.iconQueueInterruptList) do
					if (qsId <= numSpellQueueList) then
						if (not qsFrame:IsShown()) then
							qsFrame:Show()
						end
						qsFrame:SetTexture(spellQueueInterruptList[qsId][1])
						SetPortraitToTexture(qsFrame, qsFrame:GetTexture())
						qsFrame:SetPoint("BOTTOMRIGHT", self.interruptIconOrderPos[qsId][1], self.interruptIconOrderPos[qsId][2])
						qsFrame.interruptIconOrder = qsId
					elseif qsFrame:IsShown() then
						qsFrame.interruptIconOrder = nil
						qsFrame:Hide()
					end
				end
			else
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
										self:UNIT_AURA(self.unitId, true, nil, 20)
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
	end
	
	if maxExpirationTime == 0 then -- no (de)buffs found
		self.maxExpirationTime = 0
		if self.anchor ~= UIParent and self.drawlayer then
			if self.drawanchor == self.anchor and self.anchor.GetDrawLayer and self.anchor.SetDrawLayer then
				self.anchor:SetDrawLayer(self.drawlayer) -- restore the original draw layer
			else
				self.drawlayer = nil
				self.drawanchor = nil
			end
		end
		if self.iconInterruptBackground:IsShown() then
			self.iconInterruptBackground:Hide()
		end
		self:Hide()
		self:GetParent():Hide()
	elseif maxExpirationTime ~= self.maxExpirationTime then -- this is a different (de)buff, so initialize the cooldown
		self.maxExpirationTime = maxExpirationTime
		if self.anchor ~= UIParent then
			local frameLevel = (self.anchor:GetParent() and self.anchor:GetParent():GetFrameLevel() or self.anchor:GetFrameLevel())+((self.frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) and (12 + self.frame.frameLevel) or 0) -- must be dynamic, frame level changes all the time
			if frameLevel < 0 then frameLevel = 0 end
			self:GetParent():SetFrameLevel(frameLevel)
			self:SetFrameLevel(frameLevel)
			if (not(self.drawlayer) or (self.drawanchor ~= self.anchor)) and self.anchor.GetDrawLayer and self.anchor.SetDrawLayer then
				self.drawlayer = self.anchor:GetDrawLayer() -- back up the current draw layer
				self.drawanchor = self.anchor
			end
			if self.drawlayer and self.anchor.GetDrawLayer and self.anchor.SetDrawLayer then
				self.anchor:SetDrawLayer("BACKGROUND") -- Temporarily put the portrait texture below the debuff texture. This is the only reliable method I've found for keeping the debuff texture visible with the cooldown spiral on top of it.
			end
		end
		if maxPriorityIsInterrupt then
			if self.frame.anchor == "Blizzard" and not(self.useCompactPartyFrames) then
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
		if self.frame.anchor == "Blizzard" and not(self.useCompactPartyFrames) then
			SetPortraitToTexture(self.texture, Icon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
			self:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
			self:SetSwipeColor(0, 0, 0, self.frame.swipeAlpha*0.75)	-- Adjust the alpha of this mask to similar levels of the normal swipe cooldown texture
		else
			self.texture:SetTexture(Icon)
			self:SetSwipeColor(0, 0, 0, self.frame.swipeAlpha)	-- This is the default alpha of the normal swipe cooldown texture
		end
		if forceEventUnitAuraAtEnd and maxExpirationTime > 0 and Duration > 0 then
			local nextTimerUpdate = maxExpirationTime - GetTime() + 0.10
			if nextTimerUpdate < 0.10 then
				nextTimerUpdate = 0.10
			end
			C_Timer.After(nextTimerUpdate, function()
				if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < (GetTime() - 0.08))) then
					self:UNIT_AURA(self.unitId, true, nil, 4)
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

function LoseControl:PLAYER_FOCUS_CHANGED()
	--if (debug) then print("PLAYER_FOCUS_CHANGED") end
	if (self.unitId == "focus" or self.unitId == "focustarget") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, true, nil, -10)
		end
	end
end

function LoseControl:PLAYER_TARGET_CHANGED()
	--if (debug) then print("PLAYER_TARGET_CHANGED") end
	if (self.unitId == "target" or self.unitId == "targettarget") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, true, nil, -11)
		end
	end
end

function LoseControl:UNIT_TARGET(unitId)
	--if (debug) then print("UNIT_TARGET", unitId) end
	if (self.unitId == "targettarget" or self.unitId == "focustarget") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, true, nil, -12)
		end
	end
end

function LoseControl:UNIT_PET(unitId)
	--if (debug) then print("UNIT_PET", unitId) end
	if (self.unitId == "pet") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, true, nil, -13)
		end
	end
end

-- Handle mouse dragging StartMoving
hooksecurefunc(LoseControl, "StartMoving", function(self)
	if (self.frame.anchor == "Blizzard" and not(self.useCompactPartyFrames)) then
		self.texture:SetTexture(self.textureicon)
		self:SetSwipeColor(0, 0, 0, self.frame.swipeAlpha)
		self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
	end
end)

-- Handle mouse dragging StopMoving
function LoseControl:StopMoving()
	self:StopMovingOrSizing()
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
	self.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][self.fakeUnitId or self.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][self.fakeUnitId or self.unitId])=="string") and _GF(anchors[frame.anchor][self.fakeUnitId or self.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][self.fakeUnitId or self.unitId])=="table") and anchors[frame.anchor][self.fakeUnitId or self.unitId] or UIParent))
	self.parent:SetParent(self.anchor:GetParent())
	self.defaultFrameStrata = self:GetFrameStrata()
	self:ClearAllPoints()
	self:GetParent():ClearAllPoints()
	self:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0)
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
	elseif strfind((self.fakeUnitId or self.unitId), "arena") then
		if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown'])) then
			PositionXEditBox = _G['LoseControlOptionsPanelarenaPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelarenaPositionYEditBox']
			FrameLevelEditBox = _G['LoseControlOptionsPanelarenaFrameLevelEditBox']
			AnchorPointDropDown = _G['LoseControlOptionsPanelarenaAnchorPointDropDown']
			AnchorIconPointDropDown = _G['LoseControlOptionsPanelarenaAnchorIconPointDropDown']
			AnchorFrameStrataDropDown = _G['LoseControlOptionsPanelarenaAnchorFrameStrataDropDown']
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
	elseif strfind((self.fakeUnitId or self.unitId), "nameplate") then
		PositionXEditBox = _G['LoseControlOptionsPanelnameplatePositionXEditBox']
		PositionYEditBox = _G['LoseControlOptionsPanelnameplatePositionYEditBox']
		FrameLevelEditBox = _G['LoseControlOptionsPanelnameplateFrameLevelEditBox']
		AnchorPointDropDown = _G['LoseControlOptionsPanelnameplateAnchorPointDropDown']
		AnchorIconPointDropDown = _G['LoseControlOptionsPanelnameplateAnchorIconPointDropDown']
		AnchorFrameStrataDropDown = _G['LoseControlOptionsPanelnameplateAnchorFrameStrataDropDown']
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
		if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
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
		if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
			UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
		end
	end
	if (AnchorIconPointDropDown) then
		UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
		UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
		if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
			UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
		end
	end
	if (AnchorFrameStrataDropDown) then
		UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
		UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
		if (frame.anchor ~= "Blizzard" or self.useCompactPartyFrames) then
			UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
		end
	end
	if self.MasqueGroup then
		self.MasqueGroup:ReSkin()
	end
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
	o.iconInterruptQueue01 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue01", "ARTWORK", nil, -1)
	o.iconInterruptQueue01:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue02 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue02", "ARTWORK", nil, -1)
	o.iconInterruptQueue02:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue03 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue03", "ARTWORK", nil, -1)
	o.iconInterruptQueue03:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue04 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue04", "ARTWORK", nil, -1)
	o.iconInterruptQueue04:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue05 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue05", "ARTWORK", nil, -1)
	o.iconInterruptQueue05:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue06 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue06", "ARTWORK", nil, -1)
	o.iconInterruptQueue06:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue07 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue07", "ARTWORK", nil, -1)
	o.iconInterruptQueue07:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue08 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue08", "ARTWORK", nil, -1)
	o.iconInterruptQueue08:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptQueue09 = o:CreateTexture(addonName .. unitId .. "InterruptIconQueue09", "ARTWORK", nil, -1)
	o.iconInterruptQueue09:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
	o.iconInterruptList = {
		[1] = o.iconInterruptPhysical,
		[2] = o.iconInterruptHoly,
		[4] = o.iconInterruptFire,
		[8] = o.iconInterruptNature,
		[16] = o.iconInterruptFrost,
		[32] = o.iconInterruptShadow,
		[64] = o.iconInterruptArcane
	}
	o.iconQueueInterruptList = {
		o.iconInterruptQueue01,
		o.iconInterruptQueue02,
		o.iconInterruptQueue03,
		o.iconInterruptQueue04,
		o.iconInterruptQueue05,
		o.iconInterruptQueue06,
		o.iconInterruptQueue07,
		o.iconInterruptQueue08,
		o.iconInterruptQueue09
	}
	for _, v in pairs(o.iconInterruptList) do
		v:Hide()
		SetPortraitToTexture(v, v:GetTexture())
		v:SetTexCoord(0.08,0.92,0.08,0.92)
	end
	for _, v in ipairs(o.iconQueueInterruptList) do
		v:Hide()
		SetPortraitToTexture(v, v:GetTexture())
		v:SetTexCoord(0.08,0.92,0.08,0.92)
	end
	
	-- Handle events
	o:SetScript("OnEvent", self.OnEvent)
	o:SetScript("OnDragStart", self.StartMoving) -- this function is already built into the Frame class
	o:SetScript("OnDragStop", self.StopMoving) -- this is a custom function

	o:RegisterEvent("PLAYER_ENTERING_WORLD")
	if (strfind(o.fakeUnitId or o.unitId, "party") or strfind(o.fakeUnitId or o.unitId, "raid")) then
		o:RegisterEvent("GROUP_ROSTER_UPDATE")
		o:RegisterEvent("GROUP_JOINED")
		o:RegisterEvent("GROUP_LEFT")
	end
	if (strfind(o.unitId, "arena")) then
		o:RegisterEvent("ARENA_OPPONENT_UPDATE")
	end
	if (strfind(o.unitId, "nameplate")) then
		o:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		o:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	end
	if (strfind(o.fakeUnitId or o.unitId, "party")) then
		o:RegisterEvent("CVAR_UPDATE")
	end

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
				if self:GetParent().Func then
					self:GetParent():Func(val)
				end
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
			if not(strfind(k, "nameplate")) then
				v.maxExpirationTime = 0
				v.unlockMode = true
				local frame = LoseControlDB.frames[k]
				if frame.enabled and ((anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][k]]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][k])=="string") and _GF(anchors[frame.anchor][k]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][k])=="table") and anchors[frame.anchor][k] or frame.anchor == "None"))) then -- only unlock frames whose anchor exists
					v:RegisterUnitEvents(false)
					v.textureicon = select(3, GetSpellInfo(keys[random(#keys)]))
					if frame.anchor == "Blizzard" and not(v.useCompactPartyFrames) then
						SetPortraitToTexture(v.texture, v.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
						v:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
						v:SetSwipeColor(0, 0, 0, frame.swipeAlpha*0.75)
						v.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
					else
						v.texture:SetTexture(v.textureicon)
						v:SetSwipeColor(0, 0, 0, frame.swipeAlpha)
						v.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background.blp")
					end
					v.parent:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
					if (frame.frameStrata ~= nil) then
						v:GetParent():SetFrameStrata(frame.frameStrata)
						v:SetFrameStrata(frame.frameStrata)
					end
					local frameLevel = (v.anchor:GetParent() and v.anchor:GetParent():GetFrameLevel() or v.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or v.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
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
		end
		LCframeplayer2.maxExpirationTime = 0
		LCframeplayer2.unlockMode = true
		local frame = LoseControlDB.frames.player2
		if frame.enabled and ((anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][LCframeplayer2.fakeUnitId or LCframeplayer2.unitId]]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframeplayer2.fakeUnitId or LCframeplayer2.unitId])=="string") and _GF(anchors[frame.anchor][LCframeplayer2.fakeUnitId or LCframeplayer2.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframeplayer2.fakeUnitId or LCframeplayer2.unitId])=="table") and anchors[frame.anchor][LCframeplayer2.fakeUnitId or LCframeplayer2.unitId] or frame.anchor == "None"))) then -- only unlock frames whose anchor exists
			LCframeplayer2:RegisterUnitEvents(false)
			LCframeplayer2.textureicon = select(3, GetSpellInfo(keys[random(#keys)]))
			if frame.anchor == "Blizzard" and not(LCframeplayer2.useCompactPartyFrames) then
				SetPortraitToTexture(LCframeplayer2.texture, LCframeplayer2.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
				LCframeplayer2:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
				LCframeplayer2:SetSwipeColor(0, 0, 0, frame.swipeAlpha*0.75)
				LCframeplayer2.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
			else
				LCframeplayer2.texture:SetTexture(LCframeplayer2.textureicon)
				LCframeplayer2:SetSwipeColor(0, 0, 0, frame.swipeAlpha)
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
		for k, v in pairs(LCframes) do
			if not(strfind(k, "nameplate")) then
				v.unlockMode = false
				v:EnableMouse(false)
				v:RegisterForDrag()
				v:SetMovable(false)
				v.text:Hide()
				v:PLAYER_ENTERING_WORLD()
			end
		end
		LCframeplayer2.unlockMode = false
		LCframeplayer2.text:Hide()
		LCframeplayer2:PLAYER_ENTERING_WORLD()
	end
end
Unlock:SetScript("OnClick", Unlock.OnClick)

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
	PrioritySlider[k]:SetScript("OnValueChanged", function(self, value, userInput)
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
DisableCooldownCount:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -2)
DisableBlizzardCooldownCount:SetPoint("TOPLEFT", DisableCooldownCount, "BOTTOMLEFT", 0, -2)

Priority:SetPoint("TOPLEFT", DisableBlizzardCooldownCount, "BOTTOMLEFT", 0, -16)
PriorityDescription:SetPoint("TOPLEFT", Priority, "BOTTOMLEFT", 0, -8)
PrioritySlider.PvE:SetPoint("TOPLEFT", PriorityDescription, "BOTTOMLEFT", 0, -24)
PrioritySlider.Immune:SetPoint("TOPLEFT", PrioritySlider.PvE, "BOTTOMLEFT", 0, -24)
PrioritySlider.ImmuneSpell:SetPoint("TOPLEFT", PrioritySlider.Immune, "BOTTOMLEFT", 0, -24)
PrioritySlider.ImmunePhysical:SetPoint("TOPLEFT", PrioritySlider.ImmuneSpell, "BOTTOMLEFT", 0, -24)
PrioritySlider.CC:SetPoint("TOPLEFT", PrioritySlider.ImmunePhysical, "BOTTOMLEFT", 0, -24)
PrioritySlider.Silence:SetPoint("TOPLEFT", PrioritySlider.CC, "BOTTOMLEFT", 0, -24)
PrioritySlider.Interrupt:SetPoint("TOPLEFT", PrioritySlider.Silence, "BOTTOMLEFT", 0, -24)
PrioritySlider.Disarm:SetPoint("TOPLEFT", PrioritySlider.Interrupt, "BOTTOMLEFT", 0, -24)
PrioritySlider.Root:SetPoint("TOPLEFT", PrioritySlider.PvE, "TOPRIGHT", 40, 0)
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
	local priority = LoseControlDB.priority
	for k in pairs(priority) do
		PrioritySlider[k]:SetValue(priority[k])
	end
end

InterfaceOptions_AddCategory(OptionsPanel)

-------------------------------------------------------------------------------
-- Create sub-option frames
for _, v in ipairs({ "player", "pet", "target", "targettarget", "focus", "focustarget", "party", "arena", "raid", "nameplate" }) do
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if (unitId ~= "partyplayer") then
				frame.anchor = self.value
			else
				if (GetCVarBool("useCompactPartyFrames")) then
					frame.anchor = self.value
				else
					frame.anchor = "None"
				end
			end
			icon.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][icon.fakeUnitId or icon.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][icon.fakeUnitId or icon.unitId])=="string") and _GF(anchors[frame.anchor][icon.fakeUnitId or icon.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][icon.fakeUnitId or icon.unitId])=="table") and anchors[frame.anchor][icon.fakeUnitId or icon.unitId] or UIParent))
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
			if frame.anchor == "Blizzard" and not(icon.useCompactPartyFrames) then
				local portrSizeValue = 36
				if (unitId == "player" or unitId == "target" or unitId == "focus") then
					portrSizeValue = 56
				elseif (strfind(unitId, "arena")) then
					portrSizeValue = 28
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
				icon:SetSwipeColor(0, 0, 0, frame.swipeAlpha*0.75)
				icon.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait.blp")
				if icon.MasqueGroup then
					icon.MasqueGroup:RemoveButton(icon:GetParent())
					HideTheButtonDefaultSkin(icon:GetParent())
				end
				if (v ~= "party" or unitId == "party1") and (v ~= "arena" or unitId == "arena1") and (v ~= "raid" or unitId == "raid1") and (v ~= "nameplate" or unitId == "nameplate1") then
					_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"]:SetValue(portrSizeValue)
					_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"].editbox:SetText(portrSizeValue)
					_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"].editbox:SetCursorPosition(0)
				end
			else
				icon.texture:SetTexture(icon.textureicon)
				icon:SetSwipeColor(0, 0, 0, frame.swipeAlpha)
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
			icon:GetParent():ClearAllPoints()
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
			elseif v == "arena" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])) then
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
			elseif v == "nameplate" then
				PositionXEditBox = _G['LoseControlOptionsPanelnameplatePositionXEditBox']
				PositionYEditBox = _G['LoseControlOptionsPanelnameplatePositionYEditBox']
				FrameLevelEditBox = _G['LoseControlOptionsPanelnameplateFrameLevelEditBox']
				AnchorPointDropDown = _G['LoseControlOptionsPanelnameplateAnchorPointDropDown']
				AnchorIconPointDropDown = _G['LoseControlOptionsPanelnameplateAnchorIconPointDropDown']
				AnchorFrameStrataDropDown = _G['LoseControlOptionsPanelnameplateAnchorFrameStrataDropDown']
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
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
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
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
					UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorDropDown, AnchorDropDown.initialize)
			end
			if (AnchorIconPointDropDown) then
				UIDropDownMenu_Initialize(AnchorIconPointDropDown, AnchorIconPointDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorIconPointDropDown, frame.point or "CENTER")
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
					UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown)
				end
				UIDropDownMenu_Initialize(AnchorDropDown, AnchorDropDown.initialize)
			end
			if (AnchorFrameStrataDropDown) then
				UIDropDownMenu_Initialize(AnchorFrameStrataDropDown, AnchorFrameStrataDropDown.initialize)
				UIDropDownMenu_SetSelectedValue(AnchorFrameStrataDropDown, frame.frameStrata or "AUTO")
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
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
			local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
			if frameLevel < 0 then frameLevel = 0 end
			icon:GetParent():SetFrameLevel(frameLevel)
			icon:SetFrameLevel(frameLevel)
			if icon.MasqueGroup then
				icon.MasqueGroup:ReSkin()
			end
			if v == "raid" and frame.anchor == "BlizzardRaidFrames" then
				MainHookCompactRaidFrames()
			elseif v == "party" and frame.anchor == "Blizzard" and GetCVarBool("useCompactPartyFrames") then
				MainHookCompactRaidFrames()
			end
			if icon:GetEnabled() and not icon.unlockMode then
				icon.maxExpirationTime = 0
				icon:UNIT_AURA(icon.unitId, true, nil, 0)
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
			icon.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][icon.fakeUnitId or icon.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][icon.fakeUnitId or icon.unitId])=="string") and _GF(anchors[frame.anchor][icon.fakeUnitId or icon.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][icon.fakeUnitId or icon.unitId])=="table") and anchors[frame.anchor][icon.fakeUnitId or icon.unitId] or UIParent))
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
			if frame.anchor == "Blizzard" and not(icon.useCompactPartyFrames) then
				local portrSizeValue = 56
				frame.size = portrSizeValue
				icon:SetWidth(portrSizeValue)
				icon:SetHeight(portrSizeValue)
				icon:GetParent():SetWidth(portrSizeValue)
				icon:GetParent():SetHeight(portrSizeValue)
				SetPortraitToTexture(icon.texture, icon.textureicon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
				icon:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
				icon:SetSwipeColor(0, 0, 0, frame.swipeAlpha*0.75)
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
				icon:SetSwipeColor(0, 0, 0, frame.swipeAlpha)
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
			icon:GetParent():ClearAllPoints()
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
			local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
			if frameLevel < 0 then frameLevel = 0 end
			icon:GetParent():SetFrameLevel(frameLevel)
			icon:SetFrameLevel(frameLevel)
			if icon.MasqueGroup then
				icon.MasqueGroup:ReSkin()
			end
			if icon:GetEnabled() and not icon.unlockMode then
				icon.maxExpirationTime = 0
				icon:UNIT_AURA(icon.unitId, true, nil, 0)
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
			local icon = LCframes[unitId]
			local PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
			local PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
			local FrameLevelEditBox = _G['LoseControlOptionsPanel'..v..'FrameLevelEditBox']
			if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				FrameLevelEditBox:SetText(mathfloor((frame.frameLevel or 0)+0.5))
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
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
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
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
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
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
				if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
					UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
				else
					UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown)
				end
				UIDropDownMenu_Initialize(AnchorPositionPartyDropDown, AnchorPositionPartyDropDown.initialize)
			end
		end
	end
	
	local AnchorPositionArenaDropDown
	if v == "arena" then
		AnchorPositionArenaDropDown	= CreateFrame("Frame", O..v.."AnchorPositionArenaDropDown", OptionsPanelFrame.container, "UIDropDownMenuTemplate")
		function AnchorPositionArenaDropDown:OnClick()
			UIDropDownMenu_SetSelectedValue(AnchorPositionArenaDropDown, self.value)
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
				UIDropDownMenu_Initialize(AnchorPositionArenaDropDown, AnchorPositionArenaDropDown.initialize)
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
				UIDropDownMenu_Initialize(AnchorPositionArenaDropDown, AnchorPositionArenaDropDown.initialize)
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
				UIDropDownMenu_Initialize(AnchorPositionArenaDropDown, AnchorPositionArenaDropDown.initialize)
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
		local frames = { v }
		if v == "party" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown']) }
		elseif v == "arena" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown']) }
		elseif v == "raid" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown']) }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if tonumber(val) then
				val = mathfloor(val+0.5)
				self:SetText(val)
				frame.x = val
				icon:GetParent():ClearAllPoints()
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
		local frames = { v }
		if v == "party" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown']) }
		elseif v == "arena" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown']) }
		elseif v == "raid" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown']) }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if tonumber(val) then
				val = mathfloor(val+0.5)
				self:SetText(val)
				frame.y = val
				icon:GetParent():ClearAllPoints()
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon, AnchorIconPointDropDown
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					icon = LCframes[unitId]
					AnchorIconPointDropDown = _G['LoseControlOptionsPanel'..v..'AnchorIconPointDropDown']
				end
			elseif v == "arena" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])) then
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
				icon:GetParent():ClearAllPoints()
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					icon = LCframes[unitId]
				end
			elseif v == "arena" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])) then
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
				icon:GetParent():ClearAllPoints()
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					icon = LCframes[unitId]
				end
			elseif v == "arena" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])) then
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
				local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
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
		local frames = { v }
		if v == "party" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown']) }
		elseif v == "arena" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown']) }
		elseif v == "raid" then
			frames = { UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown']) }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			if tonumber(val) then
				val = mathfloor(val+0.5)
				self:SetText(val)
				frame.frameLevel = val
				local frameLevel = (icon.anchor:GetParent() and icon.anchor:GetParent():GetFrameLevel() or icon.anchor:GetFrameLevel())+((frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) and (12 + frame.frameLevel) or 0)
				if frameLevel < 0 then frameLevel = 0 end
				icon:GetParent():SetFrameLevel(frameLevel)
				icon:SetFrameLevel(frameLevel)
				self:ClearFocus()
			else
				self:SetText(mathfloor((frame.frameLevel or 0)+0.5))
				self:ClearFocus()
			end
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
	SizeSlider.Func = function(self, value)
		if value == nil then value = self:GetValue() end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, frame in ipairs(frames) do
			if (v ~= "party" or GetCVarBool("useCompactPartyFrames") or not(LoseControlDB.showPartyplayerIcon) or frame == "partyplayer") then
				LoseControlDB.frames[frame].size = value
				LCframes[frame]:SetWidth(value)
				LCframes[frame]:SetHeight(value)
				LCframes[frame]:GetParent():SetWidth(value)
				LCframes[frame]:GetParent():SetHeight(value)
				if LCframes[frame].MasqueGroup then
					LCframes[frame].MasqueGroup:ReSkin()
				end
				if (LCframes[frame].frame and LCframes[frame].unitId) then
					SetInterruptIconsSize(LCframes[frame], value)
				end
			end
		end
	end
	SizeSlider:SetScript("OnValueChanged", function(self, value, userInput)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["Icon Size"] .. " (" .. value .. "px)")
		self.editbox:SetText(value)
		if userInput and self.Func then
			self:Func(value)
		end
	end)
	
	local SizeSlider2
	if v == "player" then
		SizeSlider2 = CreateSlider(L["Icon Size"], OptionsPanelFrame.container, 4, 256, 1, 160, true, OptionsPanelFrame:GetName() .. "IconSizeSlider2")
		SizeSlider2.Func = function(self, value)
			if value == nil then value = self:GetValue() end
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
		end
		SizeSlider2:SetScript("OnValueChanged", function(self, value, userInput)
			value = mathfloor(value+0.5)
			_G[self:GetName() .. "Text"]:SetText(L["Icon Size"] .. " (" .. value .. "px)")
			self.editbox:SetText(value)
			if v == "player" and userInput and self.Func then
				self:Func(value)
			end
		end)
	end

	local AlphaSlider = CreateSlider(L["Opacity"], OptionsPanelFrame.container, 0, 100, 1, 160, true, OptionsPanelFrame:GetName() .. "OpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSlider.Func = function(self, value)
		if value == nil then value = self:GetValue() end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].alpha = value / 100 -- the real alpha value
			LCframes[frame]:GetParent():SetAlpha(value / 100)
		end
	end
	AlphaSlider:SetScript("OnValueChanged", function(self, value, userInput)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["Opacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		if userInput and self.Func then
			self:Func(value)
		end
	end)

	local AlphaSlider2
	if v == "player" then
		AlphaSlider2 = CreateSlider(L["Opacity"], OptionsPanelFrame.container, 0, 100, 1, 160, true, OptionsPanelFrame:GetName() .. "Opacity2Slider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
		AlphaSlider2.Func = function(self, value)
			if value == nil then value = self:GetValue() end
			if v == "player" then
				LoseControlDB.frames.player2.alpha = value / 100 -- the real alpha value
				LCframeplayer2:GetParent():SetAlpha(value / 100)
			end
		end
		AlphaSlider2:SetScript("OnValueChanged", function(self, value, userInput)
			value = mathfloor(value+0.5)
			_G[self:GetName() .. "Text"]:SetText(L["Opacity"] .. " (" .. value .. "%)")
			self.editbox:SetText(value)
			if v == "player" and userInput and self.Func then
				self:Func(value)
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
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
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
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
				end
			end
		end)
	elseif v == "arena" then
		DisableInBG = CreateFrame("CheckButton", O..v.."DisableInBG", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInBGText"]:SetText(L["DisableInBG"])
		DisableInBG:SetScript("OnClick", function(self)
			LoseControlDB.disableArenaInBG = self:GetChecked()
			local frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
			for _, frame in ipairs(frames) do
				local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
				LCframes[frame].maxExpirationTime = 0
				LCframes[frame]:RegisterUnitEvents(enable)
				if enable and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
				end
			end
		end)
	end
	
	local DisableInArena
	if v == "party" then
		DisableInArena = CreateFrame("CheckButton", O..v.."DisableInArena", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInArenaText"]:SetText(L["DisableInArena"])
		DisableInArena:SetScript("OnClick", function(self)
			LoseControlDB.disablePartyInArena = self:GetChecked()
			local frames = { "party1", "party2", "party3", "party4", "partyplayer" }
			for _, frame in ipairs(frames) do
				local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
				LCframes[frame].maxExpirationTime = 0
				LCframes[frame]:RegisterUnitEvents(enable)
				if enable and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
				end
			end
		end)
	elseif v == "raid" then
		DisableInArena = CreateFrame("CheckButton", O..v.."DisableInArena", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInArenaText"]:SetText(L["DisableInArena"])
		DisableInArena:SetScript("OnClick", function(self)
			LoseControlDB.disableRaidInArena = self:GetChecked()
			local frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
			for _, frame in ipairs(frames) do
				local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
				LCframes[frame].maxExpirationTime = 0
				LCframes[frame]:RegisterUnitEvents(enable)
				if enable and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
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
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
				end
			end
		end)
	end

	local ShowNPCInterrupts
	if v == "target" or v == "focus" or v == "targettarget" or v == "focustarget" or v == "nameplate" then
		ShowNPCInterrupts = CreateFrame("CheckButton", O..v.."ShowNPCInterrupts", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."ShowNPCInterruptsText"]:SetText(L["ShowNPCInterrupts"])
		ShowNPCInterrupts:SetScript("OnClick", function(self)		
			if v == "target" then
				LoseControlDB.showNPCInterruptsTarget = self:GetChecked()
			elseif v == "focus" then
				LoseControlDB.showNPCInterruptsFocus = self:GetChecked()
			elseif v == "targettarget" then
				LoseControlDB.showNPCInterruptsTargetTarget = self:GetChecked()
			elseif v == "focustarget" then
				LoseControlDB.showNPCInterruptsFocusTarget = self:GetChecked()
			elseif v == "nameplate" then
				LoseControlDB.showNPCInterruptsNameplate = self:GetChecked()
			end
			local frames = { v }
			if v == "nameplate" then
				frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
			end
			for _, frame in ipairs(frames) do
				local enable = LoseControlDB.frames[frame].enabled and LCframes[frame]:GetEnabled()
				LCframes[frame].maxExpirationTime = 0
				LCframes[frame]:RegisterUnitEvents(enable)
				if enable and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
				end
			end
		end)
	end

	local DisablePlayerTargetTarget
	if v == "targettarget" or v == "focustarget" then
		DisablePlayerTargetTarget = CreateFrame("CheckButton", O..v.."DisablePlayerTargetTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisablePlayerTargetTargetText"]:SetText(L["DisablePlayerTargetTarget"])
		DisablePlayerTargetTarget:SetScript("OnClick", function(self)
			if v == "targettarget" then
				LoseControlDB.disablePlayerTargetTarget = self:GetChecked()
			elseif v == "focustarget" then
				LoseControlDB.disablePlayerFocusTarget = self:GetChecked()
			end
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, true, nil, 0)
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
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, true, nil, 0)
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
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, true, nil, 0)
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
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, true, nil, 0)
			end
		end)
	end
	
	local DisableFocusFocusTarget
	if v == "focustarget" then
		DisableFocusFocusTarget = CreateFrame("CheckButton", O..v.."DisableFocusFocusTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableFocusFocusTargetText"]:SetText(L["DisableFocusFocusTarget"])
		DisableFocusFocusTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableFocusFocusTarget = self:GetChecked()
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, true, nil, 0)
			end
		end)
	end

	local DisablePlayerFocusPlayerFocusTarget
	if v == "focustarget" then
		DisablePlayerFocusPlayerFocusTarget = CreateFrame("CheckButton", O..v.."DisablePlayerFocusPlayerFocusTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisablePlayerFocusPlayerFocusTargetText"]:SetText(L["DisablePlayerFocusPlayerFocusTarget"])
		DisablePlayerFocusPlayerFocusTarget:SetScript("OnClick", function(self)
			LoseControlDB.disablePlayerFocusPlayerFocusTarget = self:GetChecked()
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, true, nil, 0)
			end
		end)
	end

	local DisableFocusDeadFocusTarget
	if v == "focustarget" then
		DisableFocusDeadFocusTarget = CreateFrame("CheckButton", O..v.."DisableFocusDeadFocusTarget", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableFocusDeadFocusTargetText"]:SetText(L["DisableFocusDeadFocusTarget"])
		DisableFocusDeadFocusTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableFocusDeadFocusTarget = self:GetChecked()
			local enable = LoseControlDB.frames[v].enabled and LCframes[v]:GetEnabled()
			LCframes[v].maxExpirationTime = 0
			LCframes[v]:RegisterUnitEvents(enable)
			if enable and not LCframes[v].unlockMode then
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, true, nil, 0)
			end
		end)
	end

	local AlphaSliderBackgroundInterrupt = CreateSlider(L["InterruptBackgroundOpacity"], OptionsPanelFrame.container, 0, 100, 1, 200, true, OptionsPanelFrame:GetName() .. "InterruptBackgroundOpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSliderBackgroundInterrupt.Func = function(self, value)
		if value == nil then value = self:GetValue() end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
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
	end
	AlphaSliderBackgroundInterrupt:SetScript("OnValueChanged", function(self, value, userInput)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["InterruptBackgroundOpacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		if userInput and self.Func then
			self:Func(value)
		end
	end)
	
	local AlphaSliderInterruptMiniIcons = CreateSlider(L["InterruptMiniIconsOpacity"], OptionsPanelFrame.container, 0, 100, 1, 200, true, OptionsPanelFrame:GetName() .. "InterruptMiniIconsOpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSliderInterruptMiniIcons.Func = function(self, value)
		if value == nil then value = self:GetValue() end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
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
			for _, w in ipairs(LCframes[frame].iconQueueInterruptList) do
				w:SetAlpha(value / 100)
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
				for _, w in ipairs(LCframeplayer2.iconQueueInterruptList) do
					w:SetAlpha(value / 100)
				end
			end
		end
	end
	AlphaSliderInterruptMiniIcons:SetScript("OnValueChanged", function(self, value, userInput)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["InterruptMiniIconsOpacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		if userInput and self.Func then
			self:Func(value)
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
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
	
	local UseSpellInsteadSchoolMiniIcon = CreateFrame("CheckButton", OptionsPanelFrame:GetName().."UseSpellInsteadSchoolMiniIcon", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
	_G[OptionsPanelFrame:GetName().."UseSpellInsteadSchoolMiniIconText"]:SetText(L["UseSpellInsteadSchoolMiniIcon"])
	function UseSpellInsteadSchoolMiniIcon:Check(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].useSpellInsteadSchoolMiniIcon = self:GetChecked()
			for _, v in pairs(LCframes[frame].iconInterruptList) do
				v:Hide()
			end
			for _, v in ipairs(LCframes[frame].iconQueueInterruptList) do
				v:Hide()
			end
			LCframes[frame].maxExpirationTime = 0
			if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.useSpellInsteadSchoolMiniIcon = self:GetChecked()
				for _, v in pairs(LCframeplayer2.iconInterruptList) do
					v:Hide()
				end
				for _, v in ipairs(LCframeplayer2.iconQueueInterruptList) do
					v:Hide()
				end
				LCframeplayer2.maxExpirationTime = 0
				if LoseControlDB.frames.player2.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, 0)
				end
			end
		end
	end
	UseSpellInsteadSchoolMiniIcon:SetScript("OnClick", function(self)
		UseSpellInsteadSchoolMiniIcon:Check(self:GetChecked())
	end)

	local AlphaSliderSwipeCooldown = CreateSlider(L["SwipeCooldownOpacity"], OptionsPanelFrame.container, 0, 100, 1, 200, true, OptionsPanelFrame:GetName() .. "SwipeCooldownOpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSliderSwipeCooldown.Func = function(self, value)
		if value == nil then value = self:GetValue() end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].swipeAlpha = value / 100 -- the real alpha value
			if (LoseControlDB.frames[frame].anchor == "Blizzard" and not(LCframes[frame].useCompactPartyFrames)) then
				LCframes[frame]:SetSwipeColor(0, 0, 0, (value / 100)*0.75)
			else
				LCframes[frame]:SetSwipeColor(0, 0, 0, value / 100)
			end
			
			if (frame == "player") then
				LoseControlDB.frames.player2.swipeAlpha = value / 100 -- the real alpha value
				if (LoseControlDB.frames.player2.anchor == "Blizzard" and not(LCframes[frame].useCompactPartyFrames)) then
					LCframeplayer2:SetSwipeColor(0, 0, 0, (value / 100)*0.75)
				else
					LCframeplayer2:SetSwipeColor(0, 0, 0, value / 100)
				end
			end
		end
	end
	AlphaSliderSwipeCooldown:SetScript("OnValueChanged", function(self, value, userInput)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["SwipeCooldownOpacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		if userInput and self.Func then
			self:Func(value)
		end
	end)

	local catListEnChecksButtons = { "PvE", "Immune", "ImmuneSpell", "ImmunePhysical", "CC", "Silence", "Disarm", "Root", "Snare", "Other" }
	local CategoriesCheckButtons = { }
	if v ~= "arena" then
		local FriendlyInterrupt = CreateFrame("CheckButton", O..v.."FriendlyInterrupt", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		FriendlyInterrupt:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."FriendlyInterruptText"]:SetText(L["CatFriendly"])
		FriendlyInterrupt:SetScript("OnClick", function(self)
			local frames = { v }
			if v == "party" then
				frames = { "party1", "party2", "party3", "party4", "partyplayer" }
			elseif v == "raid" then
				frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
			elseif v == "nameplate" then
				frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
			end
			for _, frame in ipairs(frames) do
				LoseControlDB.frames[frame].categoriesEnabled.interrupt.friendly = self:GetChecked()
				LCframes[frame].maxExpirationTime = 0
				if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
				end
			end
		end)
		tblinsert(CategoriesCheckButtons, { frame = FriendlyInterrupt, auraType = "interrupt", reaction = "friendly", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = 140, yPos = 5 })
	end
	if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or v == "arena" or v == "nameplate" then
		local EnemyInterrupt = CreateFrame("CheckButton", O..v.."EnemyInterrupt", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		EnemyInterrupt:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."EnemyInterruptText"]:SetText(L["CatEnemy"])
		EnemyInterrupt:SetScript("OnClick", function(self)
			local frames = { v }
			if v == "arena" then
				frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
			elseif v == "nameplate" then
				frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
			end
			for _, frame in ipairs(frames) do
				LoseControlDB.frames[frame].categoriesEnabled.interrupt.enemy = self:GetChecked()
				LCframes[frame].maxExpirationTime = 0
				if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
				end
			end
		end)
		tblinsert(CategoriesCheckButtons, { frame = EnemyInterrupt, auraType = "interrupt", reaction = "enemy", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = (v ~= "arena" and 270 or 140), yPos = 5 })
	end
	for _, cat in pairs(catListEnChecksButtons) do
		if v ~= "arena" then
			local FriendlyBuff = CreateFrame("CheckButton", O..v.."Friendly"..cat.."Buff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			FriendlyBuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."BuffText"]:SetText(L["CatFriendlyBuff"])
			FriendlyBuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "party" then
					frames = { "party1", "party2", "party3", "party4", "partyplayer" }
				elseif v == "raid" then
					frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
				elseif v == "nameplate" then
					frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.buff.friendly[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = FriendlyBuff, auraType = "buff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 140, yPos = 5 })
		end
		if v ~= "arena" then
			local FriendlyDebuff = CreateFrame("CheckButton", O..v.."Friendly"..cat.."Debuff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			FriendlyDebuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."DebuffText"]:SetText(L["CatFriendlyDebuff"])
			FriendlyDebuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "party" then
					frames = { "party1", "party2", "party3", "party4", "partyplayer" }
				elseif v == "raid" then
					frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
				elseif v == "nameplate" then
					frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.debuff.friendly[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = FriendlyDebuff, auraType = "debuff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 205, yPos = 5 })
		end
		if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or v == "arena" or v == "nameplate" then
			local EnemyBuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Buff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			EnemyBuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Enemy"..cat.."BuffText"]:SetText(L["CatEnemyBuff"])
			EnemyBuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "arena" then
					frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
				elseif v == "nameplate" then
					frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.buff.enemy[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = EnemyBuff, auraType = "buff", reaction = "enemy", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = (v ~= "arena" and 270 or 140), yPos = 5 })
		end
		if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or v == "arena" or v == "nameplate" then
			local EnemyDebuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Debuff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			EnemyDebuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Enemy"..cat.."DebuffText"]:SetText(L["CatEnemyDebuff"])
			EnemyDebuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "arena" then
					frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
				elseif v == "nameplate" then
					frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.debuff.enemy[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = EnemyDebuff, auraType = "debuff", reaction = "enemy", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = (v ~= "arena" and 335 or 205), yPos = 5 })
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
				LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, 0)
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
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, 0)
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
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, 0)
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
				LCframes.player:SetSwipeColor(0, 0, 0, frame.swipeAlpha)
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
				LCframes.player.anchor = anchors[frame.anchor]~=nil and _G[anchors[frame.anchor][LCframes.player.fakeUnitId or LCframes.player.unitId]] or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframes.player.fakeUnitId or LCframes.player.unitId])=="string") and _GF(anchors[frame.anchor][LCframes.player.fakeUnitId or LCframes.player.unitId]) or ((anchors[frame.anchor]~=nil and type(anchors[frame.anchor][LCframes.player.fakeUnitId or LCframes.player.unitId])=="table") and anchors[frame.anchor][LCframes.player.fakeUnitId or LCframes.player.unitId] or UIParent))
				LCframes.player.parent:SetParent(LCframes.player.anchor:GetParent())
				LCframes.player.defaultFrameStrata = LCframes.player:GetFrameStrata()
				LCframes.player:GetParent():ClearAllPoints()
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
				LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, 0)
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
				LCframes.partyplayer:UNIT_AURA(LCframes.partyplayer.unitId, true, nil, 0)
			elseif Unlock:GetChecked() then
				Unlock:OnClick()
			end
		end
		EnabledPartyPlayerIcon:SetScript("OnClick", function(self)
			EnabledPartyPlayerIcon:Check(self:GetChecked())
		end)
	end

	local function EnableInterfaceFrames(icon, frame)
		if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
		if DisableInArena then BlizzardOptionsPanel_CheckButton_Enable(DisableInArena) end
		if DisableInRaid then BlizzardOptionsPanel_CheckButton_Enable(DisableInRaid) end
		if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Enable(ShowNPCInterrupts) end
		if DisablePlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisablePlayerTargetTarget) end
		if DisableTargetTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisableTargetTargetTarget) end
		if DisablePlayerTargetPlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisablePlayerTargetPlayerTargetTarget) end
		if DisableTargetDeadTargetTarget then BlizzardOptionsPanel_CheckButton_Enable(DisableTargetDeadTargetTarget) end
		if DisableFocusFocusTarget then BlizzardOptionsPanel_CheckButton_Enable(DisableFocusFocusTarget) end
		if DisablePlayerFocusPlayerFocusTarget then BlizzardOptionsPanel_CheckButton_Enable(DisablePlayerFocusPlayerFocusTarget) end
		if DisableFocusDeadFocusTarget then BlizzardOptionsPanel_CheckButton_Enable(DisableFocusDeadFocusTarget) end
		if DuplicatePlayerPortrait then BlizzardOptionsPanel_CheckButton_Enable(DuplicatePlayerPortrait) end
		if EnabledPartyPlayerIcon then BlizzardOptionsPanel_CheckButton_Enable(EnabledPartyPlayerIcon) end
		BlizzardOptionsPanel_CheckButton_Enable(UseSpellInsteadSchoolMiniIcon)
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
		BlizzardOptionsPanel_Slider_Enable(AlphaSliderSwipeCooldown)
		ColorPickerBackgroundInterrupt:Enable()
		ColorPickerBackgroundInterruptREditBox:Enable()
		ColorPickerBackgroundInterruptGEditBox:Enable()
		ColorPickerBackgroundInterruptBEditBox:Enable()
		SizeSlider.editbox:Enable()
		AlphaSlider.editbox:Enable()
		AlphaSliderBackgroundInterrupt.editbox:Enable()
		AlphaSliderInterruptMiniIcons.editbox:Enable()
		AlphaSliderSwipeCooldown.editbox:Enable()
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
		if AnchorPositionArenaDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionArenaDropDown) end
		if AnchorPositionRaidDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionRaidDropDown) end
		if (PositionXEditBox and PositionYEditBox and FrameLevelEditBox) then
			if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
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
			if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
				UIDropDownMenu_EnableDropDown(AnchorPointDropDown)
			else
				UIDropDownMenu_DisableDropDown(AnchorPointDropDown)
			end
		end
		if (AnchorIconPointDropDown) then
			if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
				UIDropDownMenu_EnableDropDown(AnchorIconPointDropDown)
			else
				UIDropDownMenu_DisableDropDown(AnchorIconPointDropDown)
			end
		end
		if (AnchorFrameStrataDropDown) then
			if (frame.anchor ~= "Blizzard" or icon.useCompactPartyFrames) then
				UIDropDownMenu_EnableDropDown(AnchorFrameStrataDropDown)
			else
				UIDropDownMenu_DisableDropDown(AnchorFrameStrataDropDown)
			end
		end
	end

	local function DisableInterfaceFrames()
		if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
		if DisableInArena then BlizzardOptionsPanel_CheckButton_Disable(DisableInArena) end
		if DisableInRaid then BlizzardOptionsPanel_CheckButton_Disable(DisableInRaid) end
		if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Disable(ShowNPCInterrupts) end
		if DisablePlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisablePlayerTargetTarget) end
		if DisableTargetTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisableTargetTargetTarget) end
		if DisablePlayerTargetPlayerTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisablePlayerTargetPlayerTargetTarget) end
		if DisableTargetDeadTargetTarget then BlizzardOptionsPanel_CheckButton_Disable(DisableTargetDeadTargetTarget) end
		if DisableFocusFocusTarget then BlizzardOptionsPanel_CheckButton_Disable(DisableFocusFocusTarget) end
		if DisablePlayerFocusPlayerFocusTarget then BlizzardOptionsPanel_CheckButton_Disable(DisablePlayerFocusPlayerFocusTarget) end
		if DisableFocusDeadFocusTarget then BlizzardOptionsPanel_CheckButton_Disable(DisableFocusDeadFocusTarget) end
		if DuplicatePlayerPortrait then BlizzardOptionsPanel_CheckButton_Disable(DuplicatePlayerPortrait) end
		if EnabledPartyPlayerIcon then BlizzardOptionsPanel_CheckButton_Disable(EnabledPartyPlayerIcon) end
		BlizzardOptionsPanel_CheckButton_Disable(UseSpellInsteadSchoolMiniIcon)
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
		BlizzardOptionsPanel_Slider_Disable(AlphaSliderSwipeCooldown)
		ColorPickerBackgroundInterrupt:Disable()
		ColorPickerBackgroundInterruptREditBox:Disable()
		ColorPickerBackgroundInterruptGEditBox:Disable()
		ColorPickerBackgroundInterruptBEditBox:Disable()
		HideColorPicker()
		SizeSlider.editbox:Disable()
		AlphaSlider.editbox:Disable()
		AlphaSliderBackgroundInterrupt.editbox:Disable()
		AlphaSliderInterruptMiniIcons.editbox:Disable()
		AlphaSliderSwipeCooldown.editbox:Disable()
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
		if AnchorPositionArenaDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionArenaDropDown) end
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
			elseif (v == "arena") then
				unitIdSel = (AnchorPositionArenaDropDown ~= nil) and UIDropDownMenu_GetSelectedValue(AnchorPositionArenaDropDown) or "arena1"
			elseif (v == "raid") then
				unitIdSel = (AnchorPositionRaidDropDown ~= nil) and UIDropDownMenu_GetSelectedValue(AnchorPositionRaidDropDown) or "raid1"
			elseif (v == "nameplate") then
				unitIdSel = "nameplate1"
			end
			EnableInterfaceFrames(LCframes[unitIdSel], LoseControlDB.frames[unitIdSel])
		else
			DisableInterfaceFrames()
		end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		elseif v == "nameplate" then
			frames = { "nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40" }
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
				LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, true, nil, 0)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.enabled = enabled and LoseControlDB.duplicatePlayerPortrait
				LCframeplayer2.maxExpirationTime = 0
				LCframeplayer2:RegisterUnitEvents(enabled and LoseControlDB.duplicatePlayerPortrait)
				if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, 0)
				end
			end
		end
		if ((v == "raid" or v == "party") and enabled) then
			MainHookCompactRaidFrames()
		end
		if Unlock:GetChecked() then
			Unlock:OnClick()
		end
	end)

	Enabled:SetPoint("TOPLEFT", 16, -12)
	if DisableInBG then DisableInBG:SetPoint("TOPLEFT", Enabled, 225, ((v == "party") and -25 or 0)) end
	if DisableInArena then DisableInArena:SetPoint("TOPLEFT", Enabled, 225, ((v == "party") and -50 or -25)) end
	if DisableInRaid then DisableInRaid:SetPoint("TOPLEFT", Enabled, 225, ((v == "party") and -75 or -50)) end
	if ShowNPCInterrupts then ShowNPCInterrupts:SetPoint("TOPLEFT", Enabled, 225, 0) end
	if DisablePlayerTargetTarget then DisablePlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -25) end
	if DisableTargetTargetTarget then DisableTargetTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -50) end
	if DisablePlayerTargetPlayerTargetTarget then DisablePlayerTargetPlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -75) end
	if DisableTargetDeadTargetTarget then DisableTargetDeadTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -100) end
	if DisableFocusFocusTarget then DisableFocusFocusTarget:SetPoint("TOPLEFT", Enabled, 225, -50) end
	if DisablePlayerFocusPlayerFocusTarget then DisablePlayerFocusPlayerFocusTarget:SetPoint("TOPLEFT", Enabled, 225, -75) end
	if DisableFocusDeadFocusTarget then DisableFocusDeadFocusTarget:SetPoint("TOPLEFT", Enabled, 225, -100) end
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
	if AnchorPositionArenaDropDown then AnchorPositionArenaDropDown:SetPoint("RIGHT", PositionYEditBox, "RIGHT", 30, 0) end
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
	AlphaSliderSwipeCooldown:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 20, -120)
	UseSpellInsteadSchoolMiniIcon:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 280, -50)
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
			DisableInArena:SetChecked(LoseControlDB.disablePartyInArena)
			DisableInRaid:SetChecked(LoseControlDB.disablePartyInRaid)
			EnabledPartyPlayerIcon:SetChecked(LoseControlDB.showPartyplayerIcon)
			unitId = "party1"
		elseif unitId == "arena" then
			DisableInBG:SetChecked(LoseControlDB.disableArenaInBG)
			unitId = "arena1"
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
		elseif unitId == "focus" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsFocus)
		elseif unitId == "targettarget" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsTargetTarget)
			DisablePlayerTargetTarget:SetChecked(LoseControlDB.disablePlayerTargetTarget)
			DisableTargetTargetTarget:SetChecked(LoseControlDB.disableTargetTargetTarget)
			DisablePlayerTargetPlayerTargetTarget:SetChecked(LoseControlDB.disablePlayerTargetPlayerTargetTarget)
			DisableTargetDeadTargetTarget:SetChecked(LoseControlDB.disableTargetDeadTargetTarget)
		elseif unitId == "focustarget" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsFocusTarget)
			DisablePlayerTargetTarget:SetChecked(LoseControlDB.disablePlayerFocusTarget)
			DisableFocusFocusTarget:SetChecked(LoseControlDB.disableFocusFocusTarget)
			DisablePlayerFocusPlayerFocusTarget:SetChecked(LoseControlDB.disablePlayerFocusPlayerFocusTarget)
			DisableFocusDeadFocusTarget:SetChecked(LoseControlDB.disableFocusDeadFocusTarget)
		elseif unitId == "raid" then
			DisableInBG:SetChecked(LoseControlDB.disableRaidInBG)
			DisableInArena:SetChecked(LoseControlDB.disableRaidInArena)
			unitId = "raid1"
		elseif unitId == "nameplate" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsNameplate)
			unitId = "nameplate1"
		end
		LCframes[unitId]:CheckAnchor(true)
		UseSpellInsteadSchoolMiniIcon:SetChecked(LoseControlDB.frames[unitId].useSpellInsteadSchoolMiniIcon)
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
			EnableInterfaceFrames(LCframes[unitId], frame)
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
		AlphaSliderSwipeCooldown:SetValue(frame.swipeAlpha * 100)
		AlphaSliderSwipeCooldown.editbox:SetText(frame.swipeAlpha * 100)
		AlphaSliderSwipeCooldown.editbox:SetCursorPosition(0)
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
			if strfind(unitId, "raid") then
				AddItem(AnchorDropDown, L["None"], "None")
				AddItem(AnchorDropDown, "Blizzard", "BlizzardRaidFrames")
			elseif strfind(unitId, "nameplate") then
				AddItem(AnchorDropDown, "Blizzard", "BlizzardNameplates")
			else
				AddItem(AnchorDropDown, L["None"], "None")
				AddItem(AnchorDropDown, "Blizzard", "Blizzard")
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
			if _G[anchors["Gladius"][unitId]] or (type(anchors["Gladius"][unitId])=="table" and anchors["Gladius"][unitId]) or (type(anchors["Gladius"][unitId])=="string" and _GF(anchors["Gladius"][unitId])) then AddItem(AnchorDropDown, "Gladius", "Gladius") end
			if _G[anchors["GladiusEx"][unitId]] or (type(anchors["GladiusEx"][unitId])=="table" and anchors["GladiusEx"][unitId]) or (type(anchors["GladiusEx"][unitId])=="string" and _GF(anchors["GladiusEx"][unitId])) then AddItem(AnchorDropDown, "GladiusEx", "GladiusEx") end
			if _G[anchors["SyncFrames"][unitId]] or (type(anchors["SyncFrames"][unitId])=="table" and anchors["SyncFrames"][unitId]) or (type(anchors["SyncFrames"][unitId])=="string" and _GF(anchors["SyncFrames"][unitId])) then AddItem(AnchorDropDown, "SyncFrames", "SyncFrames") end
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
		if AnchorPositionArenaDropDown then
			UIDropDownMenu_Initialize(AnchorPositionArenaDropDown, function() -- called on refresh and also every time the drop down menu is opened
				AddItem(AnchorPositionArenaDropDown, "arena1", "arena1")
				AddItem(AnchorPositionArenaDropDown, "arena2", "arena2")
				AddItem(AnchorPositionArenaDropDown, "arena3", "arena3")
				AddItem(AnchorPositionArenaDropDown, "arena4", "arena4")
				AddItem(AnchorPositionArenaDropDown, "arena5", "arena5")
			end)
			UIDropDownMenu_SetSelectedValue(AnchorPositionArenaDropDown, "arena1")
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
	print("<unit> can be: player, pet, target, focus, targettarget, focustarget, party1 ... party4, arena1 ... arena5, raid1 ... raid40, nameplate")
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
	elseif unitId == "arena" then
		for _, v in ipairs({"arena1", "arena2", "arena3", "arena4", "arena5"}) do
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
	elseif unitId == "nameplate" then
		for _, v in ipairs({"nameplate1", "nameplate2", "nameplate3", "nameplate4", "nameplate5", "nameplate6", "nameplate7", "nameplate8", "nameplate9", "nameplate10", "nameplate11", "nameplate12", "nameplate13", "nameplate14", "nameplate15", "nameplate16", "nameplate17", "nameplate18", "nameplate19", "nameplate20", "nameplate21", "nameplate22", "nameplate23", "nameplate24", "nameplate25", "nameplate26", "nameplate27", "nameplate28", "nameplate29", "nameplate30", "nameplate31", "nameplate32", "nameplate33", "nameplate34", "nameplate35", "nameplate36", "nameplate37", "nameplate38", "nameplate39", "nameplate40"}) do
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
	for _, v in ipairs({ "player", "pet", "target", "targettarget", "focus", "focustarget", "party", "arena", "raid", "nameplate" }) do
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
		if strfind(unitId, "raid") or strfind(unitId, "party") then
			MainHookCompactRaidFrames()
		end
		if enabled and not LCframes[unitId].unlockMode then
			LCframes[unitId].maxExpirationTime = 0
			LCframes[unitId]:UNIT_AURA(LCframes[unitId].unitId, true, nil, 0)
		end
		if (unitId == "player") then
			LoseControlDB.frames.player2.enabled = LoseControlDB.duplicatePlayerPortrait
			LCframeplayer2:RegisterUnitEvents(LoseControlDB.duplicatePlayerPortrait)
			if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
				LCframeplayer2.maxExpirationTime = 0
				LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, true, nil, 0)
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
