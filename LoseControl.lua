--[[
-------------------------------------------
-- Addon: LoseControl
-- Version: 7.06
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
local GetInstanceInfo = GetInstanceInfo
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local GetCVar = GetCVar
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
local IsPlayerSpell = IsPlayerSpell
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local SoulbindsGetActiveSoulbindID = C_Soulbinds.GetActiveSoulbindID
local SoulbindsGetNode = C_Soulbinds.GetNode
local SoulbindsGetConduitRank = C_Soulbinds.GetConduitRank
local SoulbindsFindNodeIDActuallyInstalled = C_Soulbinds.FindNodeIDActuallyInstalled
local CovenantGetRenownLevel = C_CovenantSanctumUI.GetRenownLevel
local GetAllSelectedPvpTalentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs
local GetPvpTalentInfoByID = GetPvpTalentInfoByID
local playerGUID, playerClass
local print = print
local debug = false -- type "/lc debug on" if you want to see UnitAura info logged to the console
local LCframes = {}
local LCframeplayer2
local InterruptAuras = { }
local SpecialAurasExtraInfo = { [145629] = { }, [81261] = { }, [212183] = { } }
local origSpellIdsChanged = { }
local LoseControlCompactRaidFramesHooked
local LCHookedCompactRaidFrames = { }
local Masque = LibStub("Masque", true)
local LCAddonBartender4IsPresent = false
local LCAddonConsolePortIsPresent = false
local LCAddonElvUIIsPresent = false
local LCBartender4ButtonsTable = {} 
local LCConsolePortButtonsTable = {} 
local LCElvUIButtonsTable = {} 
local LCUnitPendingUnitWatchFrames = {}
local LCCombatLockdownDelayFrame = CreateFrame("Frame")
local RefreshBlizzardLossOfControlOptionsEnabled = function() end
local RefreshPendingUnitWatchState = function() end
local delayFunc_RefreshPendingUnitWatchState = false
LCCombatLockdownDelayFrame:SetScript("OnEvent", function(self,event)
	if event == "PLAYER_REGEN_ENABLED" then
		-- Check delayed functions
		if (delayFunc_RefreshPendingUnitWatchState) then
			delayFunc_RefreshPendingUnitWatchState = false
			RefreshPendingUnitWatchState()
		end
		-- Enable protected options in the configuration panel
		RefreshBlizzardLossOfControlOptionsEnabled(false)
	elseif event == "PLAYER_REGEN_DISABLED" then
		-- Disable protected options in the configuration panel
		RefreshBlizzardLossOfControlOptionsEnabled(true)
	end
end)
LCCombatLockdownDelayFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
LCCombatLockdownDelayFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

-------------------------------------------------------------------------------
-- Thanks to all the people on the Curse.com and WoWInterface forums who help keep this list up to date :)

local interruptsIds = {
	-- Player Interrupts
	[1766]   = 5,		-- Kick (Rogue)
	[2139]   = 6,		-- Counterspell (Mage)
	[6552]   = 4,		-- Pummel (Warrior)
	[13491]  = 5,		-- Pummel (Iron Knuckles Item)
	[19647]  = 6,		-- Spell Lock (felhunter) (Warlock)
	[29443]  = 10,		-- Counterspell (Clutch of Foresight)
	[31935]  = 3,		-- Avenger's Shield (only vs npc's) (Paladin)
	[47528]  = 3,		-- Mind Freeze (Death Knight)
	[57994]  = 3,		-- Wind Shear (Shaman)
	[91807]  = 2,		-- Shambling Rush (Death Knight)
	[96231]  = 4,		-- Rebuke (Paladin)
	[93985]  = 4,		-- Skull Bash (Druid Feral)
	[97547]  = 5,		-- Solar Beam (Druid Balance)
	[115781] = 6,		-- Optical Blast (Warlock)
	[116705] = 4,		-- Spear Hand Strike (Monk)
	[132409] = 6,		-- Spell Lock (command demon) (Warlock)
	[147362] = 3,		-- Countershot (Hunter)
	[183752] = 3,		-- Disrupt (Demon Hunter)
	[187707] = 3,		-- Muzzle (Hunter)
	[212619] = 6,		-- Call Felhunter (Warlock)
	[217824] = 4,		-- Shield of Virtue (Protec Paladin)
	[220543] = 3,		-- Silence (only vs npc's) (Priest)
	[347008] = 4,		-- Axe Toss (Warlock)
	[342414] = 5,		-- Cracked Mindscreecher (Priest Anima Power)
	[328406] = 1,		-- Discharged Anima (Necrotic Wake Item)
	[337614] = 3,		-- Erratic Howl (Anima Power)
	[348029] = 3,		-- Erratic Howl (Anima Power)
	[356915] = 3,		-- Erratic Howl (Anima Power)
	[312419] = 3,		-- Soul-Devouring Howl (Torghast Anima Power)
	[341580] = 4,		-- Wailing Blast (Torghast Anima Power)
	[334452] = 0.250,	-- Unbound Shriek (Shrieker's Voicebox Shadowlands Item)
	[345608] = 8,		-- Forgotten Forgehammer (Necrotic Wake Item)
	-- NPC Classic Interrupts
	[8714]   = 5,		-- Overwhelming Musk
	[10887]  = 4,		-- Crowd Pummel
	[11972]  = 3,		-- Shield Bash
	[19129]  = 2,		-- Massive Tremor
	[21832]  = 6,		-- Boulder
	[25788]  = 5,		-- Head Butt
	[27620]  = 4,		-- Snap Kick
	[11978]  = 6,		-- Kick
	[15610]  = 6,		-- Kick
	[15614]  = 6,		-- Kick
	[27613]  = 4,		-- Kick
	[27814]  = 6,		-- Kick
	[12555]  = 4,		-- Pummel
	[15615]  = 4,		-- Pummel
	[19639]  = 5,		-- Pummel
	[13728]  = 2,		-- Earth Shock
	[15501]  = 2,		-- Earth Shock
	[22885]  = 2,		-- Earth Shock
	[23114]  = 2,		-- Earth Shock
	[25025]  = 2,		-- Earth Shock
	[26194]  = 2,		-- Earth Shock
	[24685]  = 4,		-- Earth Shock
	[15122]  = 6,		-- Counterspell
	[20537]  = 15,		-- Counterspell
	[19715]  = 10,		-- Counterspell
	[20788]  = 0.001,	-- Counterspell
	-- NPC Interrupts
	[2676]   = 2,		-- Pulverize
	[7074]   = 2,		-- Screams of the Past
	[27880]  = 3,		-- Stun
	[29298]  = 4,		-- Dark Shriek
	[29560]  = 2,		-- Kick
	[29586]  = 5,		-- Kick
	[29961]  = 10,		-- Counterspell
	[30849]  = 4,		-- Spell Lock
	[31596]  = 6,		-- Counterspell
	[31999]  = 3,		-- Counterspell
	[32322]  = 4,		-- Dark Shriek
	[32691]  = 6,		-- Spell Shock
	[32747]  = 3,		-- Arcane Torrent
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
	[36254]  = 3,		-- Judgment of the Flame
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
	[40823]  = 3,		-- Interrupting Shriek
	[40864]  = 3,		-- Throbbing Stun
	[41180]  = 3,		-- Shield Bash
	[41197]  = 3,		-- Shield Bash
	[41395]  = 5,		-- Kick
	[42708]  = 6,		-- Staggering Roar
	[42729]  = 8,		-- Dreadful Roar
	[42780]  = 5,		-- Ringing Slap
	[43305]  = 2,		-- Earth Shock
	[43518]  = 2,		-- Kick
	[44418]  = 2,		-- Massive Tremor
	[44644]  = 6,		-- Arcane Nova
	[46036]  = 6,		-- Arcane Nova
	[46182]  = 2,		-- Snap Kick
	[47071]  = 2,		-- Earth Shock
	[47081]  = 5,		-- Pummel
	[50504]  = 2,		-- Arcane Jolt
	[50854]  = 5,		-- Side Kick
	[51591]  = 1.5,		-- Stormhammer
	[51610]  = 4,		-- Counterspell
	[51612]  = 4,		-- Static Arrest
	[52272]  = 4,		-- Boulder Throw
	[52666]  = 4,		-- Disease Expulsion
	[52764]  = 4,		-- Serrated Arrow
	[52885]  = 3,		-- Deadly Throw
	[53394]  = 5,		-- Pummel
	[53550]  = 4,		-- Mind Freeze
	[54511]  = 2,		-- Earth Shock
	[56256]  = 0.001,	-- Vortex
	[56506]  = 2,		-- Earth Shock
	[56730]  = 8,		-- Dark Counterspell
	[56854]  = 4,		-- Counter Kick
	[57783]  = 2,		-- Earth Shock
	[57845]  = 5,		-- Ringing Slap
	[58690]  = 2,		-- Tail Sweep
	[58824]  = 4,		-- Disease Expulsion
	[58953]  = 4,		-- Pummel
	[59033]  = 4,		-- Static Arrest
	[59111]  = 8,		-- Dark Counterspell
	[59180]  = 3,		-- Deadly Throw
	[59283]  = 2,		-- Tail Sweep
	[59344]  = 5,		-- Pummel
	[59606]  = 5,		-- Ringing Slap
	[59708]  = 6,		-- Staggering Roar
	[59734]  = 8,		-- Dreadful Roar
	[60011]  = 2,		-- Earth Shock
	[61068]  = 0.001,	-- Vortex
	[61668]  = 3,		-- Earth Shock
	[62325]  = 8,		-- Ground Tremor
	[62437]  = 8,		-- Ground Tremor
	[62522]  = 4,		-- Electroshock
	[62681]  = 6,		-- Flame Jets
	[62859]  = 10,		-- Ground Tremor
	[62932]  = 8,		-- Ground Tremor
	[64376]  = 2,		-- Barrel Toss
	[64496]  = 6,		-- Feral Rush
	[64674]  = 6,		-- Feral Rush
	[64710]  = 8,		-- Overhead Smash Tremor
	[64715]  = 8,		-- Overhead Smash Tremor
	[65790]  = 8,		-- Counterspell
	[65973]  = 2,		-- Earth Shock
	[66330]  = 8,		-- Staggering Stomp
	[66335]  = 8,		-- Mistress' Kiss
	[66359]  = 8,		-- Mistress' Kiss
	[66408]  = 5,		-- Batter
	[66905]  = 2,		-- Hammer of the Righteous
	[67235]  = 4,		-- Pummel
	[68749]  = 5,		-- Stun
	[68884]  = 5,		-- Silence Fool
	[71022]  = 8,		-- Disrupting Shout
	[72194]  = 3,		-- Shield Bash
	[73255]  = 2,		-- Earth Shock
	[75242]  = 1.5,		-- Rock Punch
	[76583]  = 6,		-- Kick
	[77334]  = 3,		-- Wind Shear
	[77389]  = {
		{2, 0},
		{3, 2},
		{3, 4}
	},					-- Stone Throw
	[77611]  = 1,		-- Resonating Clash
	[78145]  = 2,		-- Earth Shock
	[79223]  = 3,		-- Concussive Splash
	[79866]  = 3,		-- Deadly Throw
	[82207]  = 1,		-- Explosive Bolts
	[82800]  = 3,		-- Shield Bash
	[83005]  = 3,		-- Wind Shear
	[83690]  = 6,		-- Flamelash
	[84828]  = 1.5,		-- Stormhammer
	[86487]  = 0.001,	-- Hurricane
	[87873]  = 0.1,		-- Static Shock
	[88029]  = {
		{2, 0},
		{3.5, 2},
		{3.5, 4}
	},					-- Wind Shock
	[90783]  = 3,		-- Deadly Throw
	[93267]  = 0.001,	-- Static Shock
	[95038]  = 3,		-- Wind Shear
	[96650]  = 4,		-- Earth Shock
	[98237]  = 6,		-- Hand of Ragnaros
	[98715]  = 0.1,		-- Interrupt (PBTable)
	[100724] = 4,		-- Earthquake
	[101817] = 3,		-- Shield Bash
	[103414] = 10,		-- Stomp
	[106548] = 6.5,		-- Agonizing Pain
	[107099] = 1,		-- Static Shock
	[108044] = 8,		-- Disrupting Roar
	[114339] = 3,		-- Stun
	[116069] = 0.001,	-- Gnaw
	[116075] = 0.1,		-- Shout
	[120435] = 2,		-- Shadowflay
	[122389] = 1,		-- Amber Strike
	[122887] = 8,		-- QA Test Interrupt
	[123060] = 0.1,		-- Break Free
	[123287] = 5,		-- Pummel
	[124944] = 3,		-- Sonic Boom
	[125441] = 2,		-- Sonic Scream
	[125886] = 5,		-- Sonic Blade
	[125888] = 5,		-- Sonic Blade
	[126223] = 3,		-- Shrieking Caw
	[128136] = 6,		-- Wind Shear
	[129464] = 2,		-- Forest Song
	[129891] = 0.001,	-- Solar Beam
	[131772] = 4,		-- Spear Hand Strike
	[134008] = 4,		-- Rebuke
	[134091] = 3,		-- Shell Concussion
	[134361] = 2,		-- Screech
	[134535] = 0.001,	-- Slip
	[135620] = 5,		-- Shield Bash
	[136473] = 5,		-- Counter Shot
	[137457] = 10,		-- Piercing Roar
	[137576] = 4,		-- Deadly Throw
	[138696] = 2,		-- Earth Blast
	[138763] = 7.5,		-- Interrupting Jolt
	[138766] = 6,		-- Piercing Roar
	[138809] = 0.1,		-- Despawn Sentry Laser Bunny
	[139425] = 5,		-- Waves of Fury
	[139811] = 0.1,		-- Despawn Sentry Laser Bunny
	[139867] = 10,		-- Interrupting Jolt
	[139869] = 7.5,		-- Interrupting Jolt
	[140252] = 3,		-- Piercing Screech
	[140408] = 6,		-- Piercing Cry
	[140659] = 3,		-- Shield Bash
	[141421] = 8,		-- Spell Shatter
	[142111] = 8,		-- Disrupting Bellow
	[142657] = 4,		-- Skull Bash
	[142699] = 5,		-- Counter Shot
	[142752] = 0.001,	-- Slip
	[143343] = 2,		-- Deafening Screech
	[143834] = 3,		-- Shield Bash
	[145427] = 2,		-- Kick
	[145530] = 3,		-- Counterspell
	[146706] = 5,		-- Pummel
	[146748] = 5,		-- Pummel
	[147173] = 8,		-- Unstable Iron Star
	[148797] = 2,		-- War Horn
	[149184] = 4,		-- Skull Rattle
	[150332] = 3,		-- Disrupting Dash
	[151329] = 3,		-- Sap Magic
	[152360] = 0.5,		-- Caw
	[153673] = 2,		-- Shake the Earth
	[156310] = 3,		-- Lava Shock
	[157159] = 3,		-- Shield Bash
	[157612] = 0.1,		-- Despawn Sentry Laser Bunny
	[158024] = 2,		-- Thwack
	[158102] = {
		{6, 0},
		{1, 17}
	},					-- Interrupting Shout
	[158471] = 8,		-- Disorientation Grenade
	[158658] = 4,		-- Shield Smash
	[159006] = 6,		-- Spell Lock
	[160838] = 6,		-- Disrupting Roar
	[160845] = 6,		-- Disrupting Roar
	[160847] = 6,		-- Disrupting Roar
	[160848] = 6,		-- Disrupting Roar
	[161089] = 3,		-- Mad Dash
	[161220] = 1,		-- Suppressive Fire
	[162232] = 1,		-- Interrupting Shout
	[162617] = {
		{1.5, 0},
		{6, 8}
	},					-- Slam
	[162638] = 3,		-- Avenger's Shield
	[166637] = 2,		-- Sweep
	[167061] = 6,		-- Kick
	[168085] = 0.5,		-- Rupturing Shout
	[169113] = 6,		-- Counterspell
	[169498] = 6,		-- Deafening Shout
	[171138] = 6,		-- Shadow Lock
	[171139] = 6,		-- Shadow Lock
	[173047] = 4,		-- Mind Freeze
	[173061] = 5,		-- Pummel
	[173077] = 6,		-- Counterspell
	[173085] = 4,		-- Rebuke
	[173090] = 3,		-- Wind Shear
	[173094] = 5,		-- Kick
	[173320] = 5,		-- Spear Hand Strike
	[173555] = 6,		-- Spell Lock
	[173892] = 3,		-- Counter Shot
	[174401] = 2.5,		-- Shield Throw
	[174476] = 0.5,		-- Deafening Roar
	[176228] = 3,		-- Boulder Smash
	[177150] = 6,		-- Booming Shout
	[177155] = 4,		-- Disrupting Shout
	[183455] = 1,		-- Interrupting Shout
	[184381] = 1.5,		-- Interrupting Slam
	[185544] = 15,		-- Arresting Presence
	[186190] = 3,		-- Interrupting Screech
	[186562] = 3,		-- Consume Magic
	[187219] = 3,		-- Avenger's Shield
	[191527] = 4,		-- Deafening Shout
	[191887] = 3,		-- Shield Bash
	[196543] = 3,		-- Unnerving Howl
	[199512] = 3,		-- Avenger's Shield
	[199726] = 3,		-- Unruly Yell
	[204884] = 4,		-- Spell Lock
	[205109] = 3,		-- Spell Lock
	[205149] = 3,		-- Shield Bash
	[209748] = 3,		-- Deafening Roar
	[216146] = 4,		-- Inifinite Warp
	[218096] = 3,		-- Shield Bash
	[218501] = 3,		-- Shield Bash
	[219022] = 2,		-- Deafening Roar
	[220081] = 3,		-- Spellbreak
	[220977] = 4,		-- Disrupting Shout
	[221328] = 2,		-- Brutish Roar
	[221704] = 3,		-- Avenger's Shield
	[222250] = 1,		-- Interrupting Roar
	[224088] = 6,		-- Mind Wrack
	[226246] = 5,		-- Withering Void
	[227363] = 4,		-- Mighty Stomp
	[227379] = 75,		-- Dissipation
	[230329] = 4,		-- Negative Energy
	[231002] = 4,		-- Piercing Screech
	[233739] = 1.5,		-- Malfunction
	[236230] = 6,		-- Primal Shout
	[237652] = 3,		-- Fel Fire
	[239818] = 3,		-- Deafening Screech
	[240029] = 6,		-- Counterspell
	[240198] = 4,		-- Pummel
	[240448] = 5,		-- Quake
	[240569] = 3,		-- Counter Shot
	[241346] = 6,		-- Earthquake
	[241446] = 6,		-- Sonic Scream
	[241687] = 6,		-- Sonic Scream
	[241772] = 3,		-- Unearthy Howl
	[243788] = 1,		-- Arcane Vacuum
	[244881] = 3,		-- Shield Bash
	[245000] = 3,		-- Consume Magic
	[245504] = 6,		-- Howling Shadows
	[247698] = 6,		-- Silence
	[247733] = 6,		-- Stomp
	[248919] = 15,		-- Silencing Shot
	[249212] = 3,		-- Howling Shadows
	[249279] = 1.5,		-- Counter
	[249821] = 1.5,		-- Counter
	[250171] = 8,		-- Arcane Burst
	[251523] = 6,		-- Spell Lock
	[253683] = 1.5,		-- Counter
	[254410] = 3,		-- Wind Shear
	[254771] = 3,		-- Disruption Field
	[255342] = 1.5,		-- Counter
	[257549] = 1,		-- Rocky Bash
	[257732] = 5,		-- Shattering Bellow
	[258347] = 2,		-- Sonic Screech
	[260344] = 3,		-- Piercing Roar
	[262074] = 3,		-- Wind Shear
	[263307] = 3,		-- Mind-Numbing Chatter
	[263715] = 4,		-- Silence
	[265431] = 4,		-- Pummel
	[265709] = 2,		-- Shake the Earth
	[266106] = 3,		-- Sonic Screech
	[267257] = 4,		-- Thundering Crash
	[268240] = 4,		-- Shout Down
	[270009] = 2,		-- Pummel
	[270995] = 2,		-- Deafening Roar
	[271286] = 1,		-- Treasured Bash
	[273185] = 1,		-- Shield Bash
	[273766] = 3,		-- Shield Bash
	[275099] = 2,		-- Bash
	[276884] = 2,		-- Sonic Scream
	[277515] = 3,		-- Surprise Smash
	[277600] = 4,		-- Rebuke
	[278137] = 1,		-- Stormhammer Strike
	[278189] = 1,		-- Stormhammer Strike
	[278191] = 1,		-- Stormhammer Strike
	[282151] = 3,		-- Mind Freeze
	[282220] = 3,		-- Muzzle
	[282315] = 4,		-- Spear Hand Strike
	[283423] = 4,		-- Pummel
	[283490] = 3,		-- Mind Freeze
	[283616] = 4,		-- Rebuke
	[283681] = 5,		-- Kick
	[283774] = 4,		-- Spear Hand Strike
	[284438] = 1,		-- Quake
	[287174] = 3,		-- Shrieking Caw
	[288917] = 5,		-- Deafening Screech
	[289082] = 3,		-- Deadly Throw
	[289511] = 3,		-- Rumbling Stomp
	[290439] = 3,		-- Wind Shear
	[290494] = 3,		-- Avenger's Shield
	[291400] = 1,		-- Dark Outpour
	[291979] = 1,		-- Saddling
	[292599] = 4,		-- Skull Bash
	[295093] = 2,		-- Direhorn Charge
	[296084] = 1.5,		-- Mind Fracture
	[296523] = 3,		-- Deafening Howl
	[298244] = 0.1,		-- Despawn Sentry Laser Bunny
	[298774] = 4,		-- Dominating Stomp
	[299950] = 2,		-- King's Debris
	[301548] = 7,		-- Disrupting Shout
	[302366] = 1,		-- Maw of the Void
	[302398] = 1,		-- Interrupting Shout
	[302490] = 1.5,		-- Arcane Respite
	[303165] = 2,		-- Crush
	[305031] = 1.5,		-- Cosmetic [Do Not Translate]
	[306199] = 4,		-- Howling in Pain
	[307443] = 10,		-- Radiant Spark
	[312262] = 2,		-- Sonic Scream
	[315668] = 0.1,		-- Life Infusion
	[316806] = 3,		-- Shield Bash
	[317745] = 6,		-- Disrupting Shout
	[318995] = 3,		-- Deafening Howl
	[319623] = 1,		-- Anima Whirl
	[321240] = 2,		-- Interrupting Shout
	[327884] = 0.1,		-- Repair Flesh
	[330565] = 1,		-- Shield Bash
	[332693] = 2,		-- Earth Shock
	[335485] = 4,		-- Bellowing Roar
	[335721] = 2,		-- Anima Expulsion
	[336601] = 3,		-- Disruptive Screams
	[336818] = 0.1,		-- Deep Echo Trident
	[337629] = 3,		-- Shield Bash
	[337635] = 5,		-- Nightmarish Wail
	[339311] = 7.5,		-- Interrupting Jolt
	[339367] = 5,		-- Nightmarish Wail
	[339415] = 2,		-- Deafening Crash
	[341661] = 3,		-- Stun
	[341887] = 8,		-- Dreadful Roar
	[342135] = 3,		-- Interrupting Roar
	[344776] = 4,		-- Vengeful Wail
	[345559] = 4,		-- Vengeful Wail
	[346630] = 3,		-- Deafening Roar
	[347999] = 3,		-- Stunned
	[350922] = 6,		-- Menacing Shout
	[351226] = 6,		-- Kick
	[351252] = {
		{6, 0},
		{3, 14},
		{6, 15},
		{3, 17}
	},					-- Banshee Wail
	[353202] = 4,		-- Blinding Dust
	[353956] = {
		{9, 0},
		{6, 14},
		{9, 15},
		{6, 17}
	},					-- Banshee Scream
	[355638] = 4,		-- Quelling Strike
	[358210] = 0.1,		-- Mawforged Halberd
	[358344] = 6,		-- Disruptive Shout
}

local spellIds = {
	----------------
	-- Demonhunter
	----------------
	[179057] = "CC",				-- Chaos Nova
	[205630] = "CC",				-- Illidan's Grasp
	[208618] = "CC",				-- Illidan's Grasp (throw stun)
	[217832] = "CC",				-- Imprison
	[221527] = "CC",				-- Imprison (pvp talent)
	[204843] = "Snare",				-- Sigil of Chains
	[207685] = "CC",				-- Sigil of Misery
	[204490] = "Silence",			-- Sigil of Silence
	[211881] = "CC",				-- Fel Eruption
	[200166] = "CC",				-- Metamorfosis stun
	[247121] = "Snare",				-- Metamorfosis snare
	[196555] = "Immune",			-- Netherwalk
	[213491] = "CC",				-- Demonic Trample Stun
	[232538] = "Snare",				-- Rain of Chaos
	[213405] = "Snare",				-- Master of the Glaive
	[198813] = "Snare",				-- Vengeful Retreat
	[198589] = "Other",				-- Blur
	[212800] = "Other",				-- Blur
	[209426] = "Immune",			-- Darkness (not immune, 20%/50% chance to avoid all damage in PvE/PvP) (Immune category on PvP (50%), Other on PvE (20%))
	[354610] = "Immune",			-- Glimpse (not immune, damage taken reduced by 75% and immune to loss of control effects)
	
	----------------
	-- Death Knight
	----------------
	[108194] = "CC",				-- Asphyxiate
	[221562] = "CC",				-- Asphyxiate
	[47476]  = "Silence",			-- Strangulate
	[96294]  = "Root",				-- Chains of Ice (Chilblains)
	[45524]  = "Snare",				-- Chains of Ice
	[115018] = "Other",				-- Desecrated Ground (Immune to CC)
	[207319] = "Immune",			-- Corpse Shield (not immune, 90% damage redirected to pet)
	[48707]  = "ImmuneSpell",		-- Anti-Magic Shell
	[51271]  = "Other",				-- Pillar of Frost
	[48792]  = "Other",				-- Icebound Fortitude
	[49039]  = "Other",				-- Lichborne
	[287081] = "Other",				-- Lichborne
	[81256]  = "Other",				-- Dancing Rune Weapon
	[194679] = "Other",				-- Rune Tap
	[152279] = "Other",				-- Breath of Sindragosa
	[207289] = "Other",				-- Unholy Frenzy
	[116888] = "Other",				-- Shroud of Purgatory
	[315443] = "Other",				-- Abomination Limb
	[340735] = "Other",				-- Abomination Limb
	[145629] = "ImmuneSpell",		-- Anti-Magic Zone (not immune, 20%/80% damage reduction) (ImmuneSpell category with PvP talent (80%), Other wihout it (20%))
	[207167] = "CC",				-- Blinding Sleet
	[207165] = "CC",				-- Abomination's Might
	[207171] = "Root",				-- Winter is Coming
	[287254] = "CC",				-- Dead of Winter (pvp talent)
	[210141] = "CC",				-- Zombie Explosion (Reanimation PvP Talent)
	[206961] = "CC",				-- Tremble Before Me
	[248406] = "CC",				-- Cold Heart (legendary)
	[233395] = "Root",				-- Deathchill (pvp talent)
	[204085] = "Root",				-- Deathchill (pvp talent)
	[273977] = "Snare",				-- Grip of the Dead
	[211831] = "Snare",				-- Abomination's Might (slow)
	[200646] = "Snare",				-- Unholy Mutation
	[143375] = "Snare",				-- Tightening Grasp
	[208278] = "Snare",				-- Debilitating Infestation
	[212764] = "Snare",				-- White Walker
	[190780] = "Snare",				-- Frost Breath (Sindragosa's Fury) (artifact trait)
	[191719] = "Snare",				-- Gravitational Pull (artifact trait)
	[204206] = "Snare",				-- Chill Streak (pvp talent)
	[356518] = "Snare",				-- Doomburst (pvp talent)
	[334693] = "CC",				-- Absolute Zero (Legendary)
	
		----------------
		-- Death Knight Ghoul
		----------------
		[212332] = "CC",				-- Smash
		[212336] = "CC",				-- Smash
		[212337] = "CC",				-- Powerful Smash
		[47481]  = "CC",				-- Gnaw
		[91800]  = "CC",				-- Gnaw
		[91797]  = "CC",				-- Monstrous Blow (Dark Transformation)
		[91807]  = "Root",				-- Shambling Rush (Dark Transformation)
		[212540] = "Root",				-- Flesh Hook (Abomination)
	
	----------------
	-- Druid
	----------------
	[33786]  = "CC",				-- Cyclone
	[99]     = "CC",				-- Incapacitating Roar
	[236748] = "CC",				-- Intimidating Roar
	[163505] = "CC",				-- Rake
	[22570]  = "CC",				-- Maim
	[203123] = "CC",				-- Maim
	[203126] = "CC",				-- Maim (pvp honor talent)
	[236025] = "CC",				-- Enraged Maim (pvp honor talent)
	[5211]   = "CC",				-- Mighty Bash
	[2637]   = "CC",				-- Hibernate
	[81261]  = "Silence",			-- Solar Beam
	[339]    = "Root",				-- Entangling Roots
	[235963] = "CC",				-- Entangling Roots (Earthen Grasp - feral pvp talent) -- Also -80% hit chance (CC and Root category)
	[45334]  = "Root",				-- Immobilized (Wild Charge - Bear)
	[102359] = "Root",				-- Mass Entanglement
	[102793] = "Snare",				-- Ursol's Vortex
	[50259]  = "Snare",				-- Dazed (Wild Charge - Cat)
	[61391]  = "Snare",				-- Typhoon
	[127797] = "Snare",				-- Ursol's Vortex
	[232559] = "Snare",				-- Thorns (pvp honor talent)
	[345209] = "Snare",				-- Infected Wounds
	[61336]  = "Immune",			-- Survival Instincts (not immune, damage taken reduced by 50%)
	[362486] = "Immune",			-- Keeper of the Grove (pvp talent)
	[22842]  = "Other",				-- Frenzied Regeneration
	[332172] = "Other",				-- Frenzied Regeneration
	[332471] = "Other",				-- Frenzied Regeneration
	[132158] = "Other",				-- Nature's Swiftness
	[305497] = "Other",				-- Thorns (pvp honor talent)
	[102543] = "Other",				-- Incarnation: King of the Jungle
	[106951] = "Other",				-- Berserk
	[102558] = "Other",				-- Incarnation: Guardian of Ursoc
	[102560] = "Other",				-- Incarnation: Chosen of Elune
	[117679] = "Other",				-- Incarnation: Tree of Life
	[236696] = "Other",				-- Thorns
	[29166]  = "Other",				-- Innervate
	[22812]  = "Other",				-- Barkskin
	[102342] = "Other",				-- Ironbark
	[200931] = "Other",				-- High Winds (pvp talent) (damage and healing reduced by 30%)
	[202244] = "CC",				-- Overrun (pvp talent)
	[209749] = "Disarm",			-- Faerie Swarm (pvp talent)
	[329042] = "CC",				-- Emerald Slumber (pvp talent)
	
	----------------
	-- Hunter
	----------------
	[117526] = "Root",				-- Binding Shot
	[1513]   = "CC",				-- Scare Beast
	[3355]   = "CC",				-- Freezing Trap
	[13809]  = "CC",				-- Ice Trap 1
	[195645] = "Snare",				-- Wing Clip
	[19386]  = "CC",				-- Wyvern Sting
	[128405] = "Root",				-- Narrow Escape
	[136634] = "Root",				-- Narrow Escape
	[201158] = "Root",				-- Super Sticky Tar (root)
	[111735] = "Snare",				-- Tar
	[135299] = "Snare",				-- Tar Trap
	[5116]   = "Snare",				-- Concussive Shot
	[194279] = "Snare",				-- Caltrops
	[206755] = "Snare",				-- Ranger's Net (snare)
	[236699] = "Snare",				-- Super Sticky Tar (slow)
	[213691] = "CC",				-- Scatter Shot (pvp honor talent)
	[186265] = "Immune",			-- Aspect of the Turtle
	[189949] = "Immune",			-- Aspect of the Turtle
	[212704] = "Other",				-- The Beast Within (immune to fear and horror)
	[190927] = "Root",				-- Harpoon
	[212331] = "Root",				-- Harpoon
	[212353] = "Root",				-- Harpoon
	[162480] = "Root",				-- Steel Trap
	[200108] = "Root",				-- Ranger's Net
	[212638] = "CC",				-- Tracker's Net (pvp honor talent) -- Also -80% hit chance melee & range physical (CC and Root category)
	[357021] = "CC",				-- Consecutive Concussion
	[186387] = "Snare",				-- Bursting Shot
	[224729] = "Snare",				-- Bursting Shot
	[266779] = "Other",				-- Coordinated Assault
	[193530] = "Other",				-- Aspect of the Wild
	[186289] = "Other",				-- Aspect of the Eagle
	[288613] = "Other",				-- Trueshot
	[203337] = "CC",				-- Freezing Trap (Diamond Ice - pvp honor talent)
	[202748] = "Immune",			-- Survival Tactics (pvp honor talent) (not immune, 90% damage reduction)
	[248519] = "ImmuneSpell",		-- Interlope (pvp honor talent)
	[5384]   = "Other",				-- Feign Death
	[356723] = "Snare",				-- Scorpid Venom (pvp talent)
	[356727] = "Silence",			-- Spider Venom (pvp talent)
	[355596] = "Silence",			-- Wailing Arrow (Rae'shalare, Death's Whisper legendary bow)
	
		----------------
		-- Hunter Pets
		----------------
		[24394]  = "CC",				-- Intimidation
		[50433]  = "Snare",				-- Ankle Crack (Crocolisk)
		[54644]  = "Snare",				-- Frost Breath (Chimaera)
		[35346]  = "Snare",				-- Warp Time (Warp Stalker)
		[160067] = "Snare",				-- Web Spray (Spider)
		[160065] = "Snare",				-- Tendon Rip (Silithid)
		[263852] = "Snare",				-- Talon Rend (Bird of Prey)
		[263841] = "Snare",				-- Petrifying Gaze (Basilisk)
		[288962] = "Snare",				-- Blood Bolt (Blood Beast)
		[50245]  = "Snare",				-- Pin (Crab)
		[263446] = "Snare",				-- Acid Spit (Worm)
		[263423] = "Snare",				-- Lock Jaw (Dog)
		[50285]  = "Snare",				-- Dust Cloud (Tallstrider)
		[263840] = "Snare",				-- Furious Bite (Wolf)
		[54216]  = "Other",				-- Master's Call (root and snare immune only)
		[53148]  = "Root",				-- Charge (tenacity ability)
		[26064]  = "Immune",			-- Shell Shield (damage taken reduced 50%) (Turtle)
		[90339]  = "Immune",			-- Harden Carapace (damage taken reduced 50%) (Beetle)
		[160063] = "Immune",			-- Solid Shell (damage taken reduced 50%) (Shale Spider)
		[264022] = "Immune",			-- Niuzao's Fortitude (damage taken reduced 60%) (Oxen)
		[263920] = "Immune",			-- Gruff (damage taken reduced 60%) (Goat)
		[263867] = "Immune",			-- Obsidian Skin (damage taken reduced 50%) (Core Hound)
		[279410] = "Immune",			-- Bulwark (damage taken reduced 50%) (Krolusk)
		[263938] = "Immune",			-- Silverback (damage taken reduced 60%) (Gorilla)
		[263869] = "Immune",			-- Bristle (damage taken reduced 50%) (Boar)
		[263868] = "Immune",			-- Defense Matrix (damage taken reduced 50%) (Mechanical)
		[263926] = "Immune",			-- Thick Fur (damage taken reduced 60%) (Bear)
		[263865] = "Immune",			-- Scale Shield (damage taken reduced 50%) (Scalehide)
		[279400] = "Immune",			-- Ancient Hide (damage taken reduced 60%) (Pterrordax)
		[160058] = "Immune",			-- Thick Hide (damage taken reduced 60%) (Clefthoof)

	----------------
	-- Mage
	----------------
	[31661]  = "CC",				-- Dragon's Breath
	[118]    = "CC",				-- Polymorph
	[61305]  = "CC",				-- Polymorph: Black Cat
	[28272]  = "CC",				-- Polymorph: Pig
	[61721]  = "CC",				-- Polymorph: Rabbit
	[61780]  = "CC",				-- Polymorph: Turkey
	[28271]  = "CC",				-- Polymorph: Turtle
	[161353] = "CC",				-- Polymorph: Polar bear cub
	[126819] = "CC",				-- Polymorph: Porcupine
	[161354] = "CC",				-- Polymorph: Monkey
	[61025]  = "CC",				-- Polymorph: Serpent
	[161355] = "CC",				-- Polymorph: Penguin
	[277787] = "CC",				-- Polymorph: Direhorn
	[277792] = "CC",				-- Polymorph: Bumblebee
	[161372] = "CC",				-- Polymorph: Peacock
	[82691]  = "CC",				-- Ring of Frost
	[140376] = "CC",				-- Ring of Frost
	[122]    = "Root",				-- Frost Nova
	[120]    = "Snare",				-- Cone of Cold
	[116]    = "Snare",				-- Frostbolt
	[44614]  = "Snare",				-- Flurry
	[31589]  = "Snare",				-- Slow
	[205708] = "Snare",				-- Chilled
	[212792] = "Snare",				-- Cone of Cold
	[205021] = "Snare",				-- Ray of Frost
	[59638]  = "Snare",				-- Frostbolt (Mirror Images)
	[228354] = "Snare",				-- Flurry
	[157981] = "Snare",				-- Blast Wave
	[236299] = "Snare",				-- Chrono Shift
	[45438]  = "Immune",			-- Ice Block
	[198065] = "ImmuneSpell",		-- Prismatic Cloak (pvp talent) (not immune, 50% magic damage reduction)
	[198121] = "Root",				-- Frostbite (pvp talent)
	[220107] = "Root",				-- Frostbite
	[157997] = "Root",				-- Ice Nova
	[228600] = "Root",				-- Glacial Spike
	[110909] = "Other",				-- Alter Time
	[342246] = "Other",				-- Alter Time
	[110959] = "Other",				-- Greater Invisibility
	[110960] = "Other",				-- Greater Invisibility
	[198144] = "Other",				-- Ice form (stun/knockback immune)
	[12042]  = "Other",				-- Arcane Power
	[190319] = "Other",				-- Combustion
	[12472]  = "Other",				-- Icy Veins
	[198111] = "Immune",			-- Temporal Shield (not immune, heals all damage taken after 4 sec)

		----------------
		-- Mage Water Elemental
		----------------
		[33395]  = "Root",				-- Freeze

	----------------
	-- Monk
	----------------
	[119381] = "CC",				-- Leg Sweep
	[115078] = "CC",				-- Paralysis
	[324382] = "Root",				-- Clash
	[116706] = "Root",				-- Disable
	[116095] = "Snare",				-- Disable
	[123586] = "Snare",				-- Flying Serpent Kick
	[196733] = "Snare",				-- Special Delivery
	[205320] = "Snare",				-- Strike of the Windlord (artifact trait)
	[125174] = "Immune",			-- Touch of Karma
	[122783] = "ImmuneSpell",		-- Diffuse Magic (not immune, 60% magic damage reduction)
	[198909] = "CC",				-- Song of Chi-Ji
	[233759] = "Disarm",			-- Grapple Weapon
	[202274] = "CC",				-- Incendiary Brew (honor talent)
	[202346] = "CC",				-- Double Barrel (honor talent)
	[123407] = "Root",				-- Spinning Fire Blossom (honor talent)
	[115176] = "Immune",			-- Zen Meditation (60% damage reduction)
	[202248] = "ImmuneSpell",		-- Guided Meditation (pvp honor talent) (redirect spells to monk)
	[353319] = "ImmuneSpell",		-- Peaceweaver (pvp talent)
	[353937] = "Other",				-- Essence Font (pvp talent)
	[122278] = "Other",				-- Dampen Harm
	[243435] = "Other",				-- Fortifying Brew
	[120954] = "Other",				-- Fortifying Brew
	[201318] = "Other",				-- Fortifying Brew (pvp honor talent)
	[116849] = "Other",				-- Life Cocoon
	[214326] = "Other",				-- Exploding Keg (artifact trait - blind)
	[213664] = "Other",				-- Nimble Brew (duration of root, stun, fear and horror effects reduced by 60%) (pvp talent)
	[354540] = "Other",				-- Nimble Brew (prevents the next full loss of control effect) (pvp talent)
	[209584] = "Other",				-- Zen Focus Tea
	[137639] = "Other",				-- Storm, Earth, and Fire
	[152173] = "Other",				-- Serenity
	[115080] = "Other",				-- Touch of Death

	----------------
	-- Paladin
	----------------
	[105421] = "CC",				-- Blinding Light
	[853]    = "CC",				-- Hammer of Justice
	[20066]  = "CC",				-- Repentance
	[31935]  = "Silence",			-- Avenger's Shield
	[187219] = "Silence",			-- Avenger's Shield (pvp talent)
	[199512] = "Silence",			-- Avenger's Shield (unknow use)
	[217824] = "Silence",			-- Shield of Virtue (pvp honor talent)
	[204242] = "Snare",				-- Consecration (talent Consecrated Ground)
	[183218] = "Snare",				-- Hand of Hindrance
	[642]    = "Immune",			-- Divine Shield
	[31821]  = "Other",				-- Aura Mastery
	[210256] = "Other",				-- Blessing of Sanctuary
	[210294] = "Other",				-- Divine Favor
	[105809] = "Other",				-- Holy Avenger
	[1044]   = "Other",				-- Blessing of Freedom
	[1022]   = "ImmunePhysical",	-- Hand of Protection
	[204018] = "ImmuneSpell",		-- Blessing of Spellwarding
	[31850]  = "Other",				-- Ardent Defender
	[31884]  = "Other",				-- Avenging Wrath
	[216331] = "Other",				-- Avenging Crusader
	[86659]  = "Immune",			-- Guardian of Ancient Kings (not immune, 50% damage reduction)
	[212641] = "Immune",			-- Guardian of Ancient Kings (not immune, 50% damage reduction)
	[174535] = "Immune",			-- Guardian of Ancient Kings (not immune, 50% damage reduction)
	[10326]  = "CC",				-- Turn Evil
	[228050] = "Immune",			-- Divine Shield (Guardian of the Forgotten Queen)
	[205273] = "Snare",				-- Wake of Ashes (artifact trait) (snare)
	[205290] = "CC",				-- Wake of Ashes (artifact trait) (stun)
	[255937] = "Snare",				-- Wake of Ashes (talent) (snare)
	[255941] = "CC",				-- Wake of Ashes (talent) (stun)
	[199448] = "Immune",			-- Blessing of Sacrifice (Ultimate Sacrifice pvp talent) (not immune, 100% damage transfered to paladin)
	[337851] = "Immune",			-- Guardian of Ancient Kings (Reign of Endless Kings Legendary) (not immune, 50% damage reduction)

	----------------
	-- Priest
	----------------
	[605]    = "CC",				-- Dominate Mind
	[64044]  = "CC",				-- Psychic Horror
	[8122]   = "CC",				-- Psychic Scream
	[9484]   = "CC",				-- Shackle Undead
	[87204]  = "CC",				-- Sin and Punishment
	[15487]  = "Silence",			-- Silence
	[64058]  = "Disarm",			-- Psychic Horror
	[114404] = "Root",				-- Void Tendril's Grasp
	[15407]  = "Snare",				-- Mind Flay
	[47585]  = "Immune",			-- Dispersion (not immune, damage taken reduced by 75%)
	[47788]  = "Other",				-- Guardian Spirit (prevent the target from dying)
	[200183] = "Other",				-- Apotheosis
	[197268] = "Other",				-- Ray of Hope
	[33206]  = "Other",				-- Pain Suppression
	[27827]  = "Immune",			-- Spirit of Redemption
	[290114] = "Immune",			-- Spirit of Redemption	(pvp honor talent)
	[215769] = "Immune",			-- Spirit of Redemption	(pvp honor talent)
	[213602] = "Immune",			-- Greater Fade (pvp honor talent - protects vs spells. melee, ranged attacks + 50% speed)
	[232707] = "Immune",			-- Ray of Hope (pvp honor talent - not immune, only delay damage and heal)
	[213610] = "Other",				-- Holy Ward (pvp honor talent - wards against the next loss of control effect)
	[289655] = "Other",				-- Holy Word: Concentration
	[226943] = "CC",				-- Mind Bomb
	[200196] = "CC",				-- Holy Word: Chastise
	[200200] = "CC",				-- Holy Word: Chastise (talent)
	[358861] = "CC",				-- Void Volley: Horrify (pvp talent)
	[204263] = "Snare",				-- Shining Force
	[199845] = "Other",				-- Psyflay (pvp honor talent - Psyfiend)
	[210979] = "Snare",				-- Focus in the Light (artifact trait)

	----------------
	-- Rogue
	----------------
	[2094]   = "CC",				-- Blind
	[1833]   = "CC",				-- Cheap Shot
	[1776]   = "CC",				-- Gouge
	[408]    = "CC",				-- Kidney Shot
	[6770]   = "CC",				-- Sap
	[196958] = "CC",				-- Strike from the Shadows (stun effect)
	[1330]   = "Silence",			-- Garrote - Silence
	[280322] = "Silence",			-- Garrote - Silence
	[3409]   = "Snare",				-- Crippling Poison
	[26679]  = "Snare",				-- Deadly Throw
	[222775] = "Snare",				-- Strike from the Shadows (daze effect)
	[152150] = "Immune",			-- Death from Above (in the air you are immune to CC)
	[31224]  = "ImmuneSpell",		-- Cloak of Shadows
	[51690]  = "Other",				-- Killing Spree
	[13750]  = "Other",				-- Adrenaline Rush
	[199754] = "ImmunePhysical",	-- Riposte (parry chance increased by 100%)
	[1966]   = "Other",				-- Feint
	[121471] = "Other",				-- Shadow Blades
	[45182]  = "Immune",			-- Cheating Death (-85% damage taken)
	[5277]   = "ImmunePhysical",	-- Evasion (dodge chance increased by 100%)
	[199027] = "ImmunePhysical", 	-- Veil of Midnight (pvp honor talent)
	[212183] = "Other",				-- Smoke Bomb
	[207777] = "Disarm",			-- Dismantle
	[212283] = "Other",				-- Symbols of Death
	[207736] = "Other",				-- Shadowy Duel
	[199743] = "CC",				-- Parley
	[185422] = "Other",				-- Shadow Dance
	[198222] = "Snare",				-- System Shock (pvp honor talent) (90% slow)
	[226364] = "ImmunePhysical",	-- Evasion (Shadow Swiftness, artifact trait)
	[209786] = "Snare",				-- Goremaw's Bite (artifact trait)

	----------------
	-- Shaman
	----------------
	[77505]  = "CC",				-- Earthquake
	[51514]  = "CC",				-- Hex
	[210873] = "CC",				-- Hex (compy)
	[211010] = "CC",				-- Hex (snake)
	[211015] = "CC",				-- Hex (cockroach)
	[211004] = "CC",				-- Hex (spider)
	[196942] = "CC",				-- Hex (Voodoo Totem)
	[269352] = "CC",				-- Hex (skeletal hatchling)
	[277778] = "CC",				-- Hex (zandalari Tendonripper)
	[277784] = "CC",				-- Hex (wicker mongrel)
	[309328] = "CC",				-- Hex (living honey)
	[118905] = "CC",				-- Static Charge (Capacitor Totem)
	[64695]  = "Root",				-- Earthgrab (Earthgrab Totem)
	[3600]   = "Snare",				-- Earthbind (Earthbind Totem)
	[116947] = "Snare",				-- Earthbind (Earthgrab Totem)
	[196840] = "Snare",				-- Frost Shock
	[51490]  = "Snare",				-- Thunderstorm
	[147732] = "Snare",				-- Frostbrand Attack
	[207498] = "Other",				-- Ancestral Protection (prevent the target from dying)
	[290641] = "Other",				-- Ancestral Gift (PvP Talent) (immune to Silence and Interrupt effects)
	[108271] = "Other",				-- Astral Shift
	[114050] = "Other",				-- Ascendance (Elemental)
	[114051] = "Other",				-- Ascendance (Enhancement)
	[114052] = "Other",				-- Ascendance (Restoration)
	[204361] = "Other",				-- Bloodlust (Shamanism pvp talent)
	[204362] = "Other",				-- Heroism (Shamanism pvp talent)
	[356824] = "CC",				-- Water Unleashed (pvp talent) (damage and healing reduced by 50%)
	[356738] = "Root",				-- Earth Unleashed (pvp talent)
	[8178]   = "ImmuneSpell",		-- Grounding Totem Effect (Grounding Totem)
	[204399] = "CC",				-- Earthfury (PvP Talent)
	[192058] = "CC",				-- Lightning Surge totem (capacitor totem)
	[210918] = "ImmunePhysical",	-- Ethereal Form
	[305485] = "CC",				-- Lightning Lasso
	[204437] = "CC",				-- Lightning Lasso
	[197214] = "CC",				-- Sundering
	[207654] = "Immune",			-- Servant of the Queen (not immune, 80% damage reduction - artifact trait)
	
		----------------
		-- Shaman Pets
		----------------
		[118345] = "CC",				-- Pulverize (Shaman Primal Earth Elemental)

	----------------
	-- Warlock
	----------------
	[710]    = "CC",				-- Banish
	[5782]   = "CC",				-- Fear
	[118699] = "CC",				-- Fear
	[130616] = "CC",				-- Fear (Glyph of Fear)
	[5484]   = "CC",				-- Howl of Terror
	[22703]  = "CC",				-- Infernal Awakening
	[6789]   = "CC",				-- Mortal Coil
	[30283]  = "CC",				-- Shadowfury
	[43523]  = "Silence",			-- Unstable Affliction
	[65813]  = "Silence",			-- Unstable Affliction
	[196364] = "Silence",			-- Unstable Affliction
	[285155] = "Silence",			-- Unstable Affliction
	[104773] = "Other",				-- Unending Resolve
	[113860] = "Other",				-- Dark Soul: Misery
	[113858] = "Other",				-- Dark Soul: Instability
	[333889] = "Other",				-- Fel Domination
	[212295] = "ImmuneSpell",		-- Netherward (reflects spells)
	[233582] = "Root",				-- Entrenched in Flame (pvp honor talent)
	[334275] = "Snare",				-- Curse of Exhaustion
	[353807] = "Snare",				-- Bonds of Fel

		----------------
		-- Warlock Pets
		----------------
		[32752]  = "CC",			-- Summoning Disorientation
		[89766]  = "CC",			-- Axe Toss (Felguard/Wrathguard)
		[115268] = "CC",			-- Mesmerize (Shivarra)
		[6358]   = "CC",			-- Seduction (Succubus)
		[171017] = "CC",			-- Meteor Strike (infernal)
		[171018] = "CC",			-- Meteor Strike (abisal)
		[213688] = "CC",			-- Fel Cleave (Fel Lord - PvP Talent)
		[170996] = "Snare",			-- Debilitate (Terrorguard)
		[170995] = "Snare",			-- Cripple (Doomguard)
		[6360]   = "Snare",			-- Whiplash (Succubus)

	----------------
	-- Warrior
	----------------
	[5246]   = "CC",				-- Intimidating Shout (aoe)
	[132168] = "CC",				-- Shockwave
	[107570] = "CC",				-- Storm Bolt
	[132169] = "CC",				-- Storm Bolt
	[46968]  = "CC",				-- Shockwave
	[213427] = "CC",				-- Charge Stun Talent (Warbringer)
	[237744] = "CC",				-- Charge Stun Talent (Warbringer)
	[105771] = "Root",				-- Charge (root)
	[236027] = "Snare",				-- Charge (snare)
	[1715]   = "Snare",				-- Hamstring
	[12323]  = "Snare",				-- Piercing Howl
	[46924]  = "Immune",			-- Bladestorm (not immune to dmg, only to LoC)
	[227847] = "Immune",			-- Bladestorm (not immune to dmg, only to LoC)
	[199038] = "Immune",			-- Leave No Man Behind (not immune, 90% damage reduction)
	[218826] = "Immune",			-- Trial by Combat (warr fury artifact hidden trait) (only immune to death)
	[23920]  = "ImmuneSpell",		-- Spell Reflection
	[169339] = "ImmuneSpell",		-- Spell Reflection
	[335255] = "ImmuneSpell",		-- Spell Reflection
	[871]    = "Other",				-- Shield Wall
	[12975]  = "Other",				-- Last Stand
	[18499]  = "Other",				-- Berserker Rage
	[107574] = "Other",				-- Avatar
	[262228] = "Other",				-- Deadly Calm
	[198819] = "Other",				-- Mortal Strike (50% heal reduction) (pvp honor talent)
	[236321] = "Other",				-- War Banner
	[236438] = "Other",				-- War Banner
	[236439] = "Other",				-- War Banner
	[236273] = "Other",				-- Duel
	[198817] = "Other",				-- Sharpen Blade (pvp honor talent)
	[184364] = "Other",				-- Enraged Regeneration
	[118038] = "ImmunePhysical",	-- Die by the Sword (parry chance increased by 100%, damage taken reduced by 30%)
	[198760] = "ImmunePhysical",	-- Intercept (pvp honor talent) (intercept the next ranged or melee hit)
	[199085] = "CC",				-- Warpath
	[199042] = "Root",				-- Thunderstruck
	[356356] = "Root",				-- Warbringer (pvp talent)
	[236236] = "Disarm",			-- Disarm (pvp talent - protection)
	[236077] = "Disarm",			-- Disarm (pvp talent)
	
	----------------
	-- Shadowlands Covenant Spells
	----------------
	[331866] = "CC",				-- Agent of Chaos
	[314416] = "CC",				-- Blind Faith
	[323557] = "CC",				-- Ravenous Frenzy
	[335432] = "CC",				-- Thirst For Anima
	[317589] = "Silence",			-- Tormenting Backlash
	[326062] = "CC",				-- Ancient Aftershock
	[325886] = "CC",				-- Ancient Aftershock
	[326083] = "CC",				-- Ancient Aftershock
	[296035] = "CC",				-- Invoke Armaments
	[296034] = "CC",				-- Archon of Justice
	[324263] = "CC",				-- Sulfuric Emission
	[347684] = "CC",				-- Sulfuric Emission
	[332423] = "CC",				-- Sparkling Driftglobe Core
	[323996] = "Root",				-- The Hunt
	[325321] = "CC",				-- Wild Hunt's Charge
	[320224] = "CC",				-- Podtender
	[323524] = "Other",				-- Ultimate Form (immune to CC)
	[330752] = "Other",				-- Ascendant Phial (immune to curse, disease, poison, and bleed effects)
	[326514] = "Other",				-- Forgeborne Reveries
	[348272] = "Other",				-- Forgeborne Reveries
	[327140] = "Other",				-- Forgeborne Reveries
	[347831] = "Other",				-- Forgeborne Reveries
	[348303] = "Other",				-- Forgeborne Reveries
	[348304] = "Other",				-- Forgeborne Reveries
	[323673] = "Other",				-- Mindgames
	[323701] = "Other",				-- Mindgames
	[323705] = "Other",				-- Mindgames
	[296040] = "Snare",				-- Vanquishing Sweep
	[320267] = "Snare",				-- Soothing Voice
	[321759] = "Snare",				-- Bearer's Pursuit
	[339051] = "Snare",				-- Demonic Parole
	[354051] = "Root",				-- Nimble Steps
	[353472] = "Snare",				-- Cunning Dreams
	[352448] = "Snare",				-- Viscous Coating
	[352451] = "Snare",				-- Viscous Coating
	
	----------------
	-- Other
	----------------
	[67769]  = "CC",				-- Cobalt Frag Bomb
	[67890]  = "CC",				-- Cobalt Frag Bomb (belt)
	[224074] = "CC",				-- Devilsaur's Bite (trinket)
	[127723] = "Root",				-- Covered In Watermelon (trinket)
	[42803]  = "Snare",				-- Frostbolt (trinket)
	[195342] = "Snare",				-- Shrink Ray (trinket)
	[107079] = "CC",				-- Quaking Palm (pandaren racial)
	[255723] = "CC",				-- Bull Rush (highmountain tauren racial)
	[287712] = "CC",				-- Haymaker (kul tiran racial)
	[256948] = "Other",				-- Spatial Rift (void elf racial)
	[302731] = "Other",				-- Ripple in Space (azerite essence)
	[214459] = "Silence",			-- Choking Flames (trinket)
	[131510] = "Immune",			-- Uncontrolled Banish
	[55536]  = "Root",				-- Frostweave Net
	[148526] = "Root",				-- Sticky Silk
	[295048] = "Immune",			-- Touch of the Everlasting (not immune, damage taken reduced 85%)
	[221792] = "CC",				-- Kidney Shot (Vanessa VanCleef (Rogue Bodyguard))
	[222897] = "CC",				-- Storm Bolt (Dvalen Ironrune (Warrior Bodyguard))
	[222317] = "CC",				-- Mark of Thassarian (Thassarian (Death Knight Bodyguard))
	[212435] = "CC",				-- Shado Strike (Thassarian (Monk Bodyguard))
	[212246] = "CC",				-- Brittle Statue (The Monkey King (Monk Bodyguard))
	[238511] = "CC",				-- March of the Withered
	[252717] = "CC",				-- Light's Radiance (Argus powerup)
	[148535] = "CC",				-- Ordon Death Chime (trinket)
	[141928] = "CC",				-- Growing Pains (Whole-Body Shrinka' toy)
	[285643] = "CC",				-- Battle Screech
	[245855] = "CC",				-- Belly Smash
	[262177] = "CC",				-- Into the Storm
	[255978] = "CC",				-- Pallid Glare
	[256050] = "CC",				-- Disoriented (Electroshock Mount Motivator)
	[218546] = "CC",				-- Nightmarish Visions
	[258258] = "CC",				-- Quillbomb
	[260149] = "CC",				-- Quillbomb
	[258236] = "CC",				-- Sleeping Quill Dart
	[269186] = "CC",				-- Holographic Horror Projector
	[255228] = "CC",				-- Polymorphed (Organic Discombobulation Grenade and some NPCs)
	[334307] = "CC",				-- Imperfect Polymorph (Darktower Parchments: Instant Polymorphist)
	[330607] = "CC",				-- 50UL-TR4P!
	[272188] = "CC",				-- Hammer Smash (quest)
	[264860] = "CC",				-- Binding Talisman
	[238322] = "CC",				-- Arcane Prison
	[171369] = "CC",				-- Arcane Prison
	[172692] = "CC",				-- Unbound Charge
	[172160] = "Other",				-- Vintage Free Action Potion
	[330914] = "Other",				-- Momentum Redistributor Boots
	[339672] = "Snare",				-- Gravimetric Scrambler
	[295395] = "Silence",			-- Oblivion Spear
	[268966] = "Root",				-- Hooked Deep Sea Net
	[268965] = "Snare",				-- Tidespray Linen Net
	[295366] = "CC",				-- Purifying Blast (Azerite Essences)
	[293031] = "Snare",				-- Suppressing Pulse (Azerite Essences)
	[300009] = "Snare",				-- Suppressing Pulse (Azerite Essences)
	[300010] = "Snare",				-- Suppressing Pulse (Azerite Essences)
	[299109] = "CC",				-- Scrap Grenade
	[302880] = "Silence",			-- Sharkbit (G99.99 Landshark)
	[299577] = "CC",				-- Scroll of Bursting Power
	[296273] = "CC",				-- Mirror Charm
	[304705] = "CC",				-- Razorshell
	[304706] = "CC",				-- Razorshell
	[299802] = "CC",				-- Eel Trap
	[299803] = "CC",				-- Eel Trap
	[299768] = "CC",				-- Shiv and Shank
	[299769] = "CC",				-- Undercut
	[299772] = "CC",				-- Tsunami Slam
	[299805] = "Root",				-- Undertow
	[299785] = "CC",				-- Maelstrom
	[310126] = "Immune",			-- Psychic Shell (not immune, 99% damage reduction) (Lingering Psychic Shell trinket)
	[314585] = "Immune",			-- Psychic Shell (not immune, 50-80% damage reduction) (Lingering Psychic Shell trinket)
	[313448] = "CC",				-- Realized Truth (Corrupted Ring - Face the Truth ring)
	[290105] = "CC",				-- Psychic Scream
	[295953] = "CC",				-- Gnaw
	[292306] = "CC",				-- Leg Sweep
	[247587] = "CC",				-- Holy Word: Chastise
	[291391] = "CC",				-- Sap
	[292224] = "CC",				-- Chaos Nova
	[295459] = "CC",				-- Mortal Coil
	[295240] = "CC",				-- Dragon's Breath
	[284379] = "CC",				-- Intimidation
	[290438] = "CC",				-- Hex
	[283618] = "CC",				-- Hammer of Justice
	[339738] = "CC",				-- Dreamer's Mending (Dreamer's Mending trinket)
	[329491] = "CC",				-- Slumberwood Band (Slumberwood Band ring)
	[344713] = "CC",				-- Pestilent Hex
	[336517] = "CC",				-- Hex
	[292055] = "Immune",			-- Spirit of Redemption
	[290049] = "Immune",			-- Ice Block
	[283627] = "Immune",			-- Divine Shield
	[292230] = "ImmunePhysical",	-- Evasion
	[290494] = "Silence",			-- Avenger's Shield
	[284879] = "Root",				-- Frost Nova
	[284844] = "Root",				-- Glacial Spike
	[339309] = "Root",				-- Everchill Brambles (Everchill Brambles trinket)
	[299256] = "Other",				-- Blessing of Freedom
	[292266] = "Other",				-- Avenging Wrath
	[292222] = "Other",				-- Blur
	[292152] = "Other",				-- Icebound Fortitude
	[292158] = "Other",				-- Astral Shift
	[283433] = "Other",				-- Avatar
	[342890] = "Other",				-- Unhindered Passing (Potion of Unhindered Passing)
	[183823] = "Other",				-- Potion of Unhindered Passing
	[345548] = "Snare",				-- Spare Meat Hook (Spare Meat Hook trinket)
	[343399] = "Snare",				-- Heart of a Gargoyle (Pulsating Stoneheart trinket)
	[292297] = "Snare",				-- Cone of Cold
	[283649] = "Snare",				-- Crippling Poison
	[284860] = "Snare",				-- Flurry
	[284217] = "Snare",				-- Concussive Shot
	[290292] = "Snare",				-- Vengeful Retreat
	[292156] = "Snare",				-- Typhoon
	[295282] = "Snare",				-- Concussive Shot
	[283558] = "Snare",				-- Chains of Ice
	[284414] = "Snare",				-- Mind Flay
	[290441] = "Snare",				-- Frost Shock
	[295577] = "Snare",				-- Frostbrand
	[133362] = "CC",				-- Megafantastic Discombobumorphanator
	[286167] = "CC",				-- Cold Crash
	[229413] = "CC",				-- Stormburst
	[142769] = "CC",				-- Stasis Beam
	[133308] = "Root",				-- Throw Net
	[291399] = "CC",				-- Blinding Peck
	[134810] = "CC",				-- Stay Out!
	[176813] = "Snare",				-- Itchy Spores
	[298356] = "CC",				-- Tidal Blast
	[121548] = "Immune",			-- Ice Block
	[129032] = "Snare",				-- Frostbolt	
	[121547] = "CC",				-- Polymorph: Sheep
	[278575] = "CC",				-- Steel-Toed Boots
	[58729]  = "Immune",			-- Spiritual Immunity
	[95332]  = "Immune",			-- Spiritual Immunity
	[171496] = "Immune",			-- Hallowed Ground
	[178266] = "Immune",			-- Hallowed Ground
	[222206] = "CC",				-- Playing with Matches
	[298272] = "CC",				-- Massive Stone
	[293935] = "CC",				-- Overcharged!
	[281923] = "CC",				-- Super Heroic Landing
	[52696]  = "CC",				-- Constricting Chains
	[97164]  = "CC",				-- Charge
	[176278] = "CC",				-- Deep Freeze
	[176169] = "Root",				-- Freezing Field
	[176276] = "Root",				-- Frost Nova
	[176268] = "Snare",				-- Frostbolt
	[176273] = "Snare",				-- Frostbolt Volley
	[176269] = "Immune",			-- Ice Block
	[176204] = "CC",				-- Mass Polymorph
	[176608] = "CC",				-- Combustion Nova
	[176098] = "Snare",				-- Phoenix Flames
	[174955] = "CC",				-- Frozen
	[178072] = "CC",				-- Howl of Terror
	[164464] = "CC",				-- Intimidating Shout
	[164465] = "CC",				-- Intimidating Shout
	[164092] = "CC",				-- Shockwave
	[164444] = "Immune",			-- Dispersion
	[164443] = "CC",				-- Psychic Scream
	[178064] = "CC",				-- Hex
	[79899]  = "Snare",				-- Chains of Ice
	[79850]  = "Root",				-- Frost Nova
	[79858]  = "Snare",				-- Frostbolt
	[177606] = "Root",				-- Entangling Roots
	[164067] = "Root",				-- Frost Nova
	[162608] = "Snare",				-- Frostbolt
	[164392] = "CC",				-- Leg Sweep
	[178058] = "CC",				-- Blind
	[178055] = "ImmuneSpell",		-- Cloak of Shadows
	[168382] = "CC",				-- Psychic Scream
	[162764] = "CC",				-- Hammer of Justice
	[189287] = "Snare",				-- Grind
	[79857]  = "Snare",				-- Blast Wave
	[162638] = "Silence",			-- Avenger's Shield
	[189265] = "Snare",				-- Shred
	[139777] = "CC",				-- Stone Smash
	[304349] = "Silence",			-- Pacifying Screech
	[292693] = "Immune",			-- Nullification Field
	[300524] = "CC",				-- Song of Azshara
	[91933]  = "CC",				-- Intimidating Roar
	[276846] = "CC",				-- Silvered Weapons
	[287478] = "CC",				-- Oppressive Power
	[287371] = "CC",				-- Spirits of Madness
	[228318] = "Other",				-- Enrage
	[79872]  = "CC",				-- Shockwave
	[341945] = "CC",				-- Defiling Horror
	[311079] = "CC",				-- Deep Introspection
	[327430] = "CC",				-- Touch of the Maw
	[340500] = "CC",				-- Terrifying Slam
	[319266] = "CC",				-- Shambling Rush
	[321662] = "CC",				-- Bone Spike
	[327145] = "CC",				-- Called to the Stone
	[313451] = "CC",				-- Fuseless Special
	[331161] = "CC",				-- Big Blue Fist
	[332984] = "CC",				-- Paralytic Plague
	[311722] = "CC",				-- Stunned
	[322802] = "CC",				-- Psychic Blast
	[341367] = "CC",				-- Psychic Blast
	[325549] = "CC",				-- Dread Roar
	[325241] = "CC",				-- Shield Slam
	[333217] = "CC",				-- Vile Roots
	[319575] = "CC",				-- Stunning Strike
	[310998] = "CC",				-- Basket Trap Sprung
	[311124] = "CC",				-- Nightmares
	[312063] = "CC",				-- Faerie Punishment
	[326316] = "CC",				-- Massive Blow
	[340724] = "CC",				-- Whimsy Eruption
	[340759] = "CC",				-- Manifest Dread
	[345188] = "CC",				-- Shield Smash
	[330727] = "CC",				-- Mounting Fear
	[316935] = "CC",				-- Rush
	[347598] = "CC",				-- Carriage Knockdown
	[358841] = "CC",				-- Carriage Knockdown
	[308077] = "CC",				-- Stomp
	[329087] = "CC",				-- Hazy Brew
	[305926] = "CC",				-- Trapped
	[305988] = "CC",				-- Accuser's Rebuke
	[319045] = "CC",				-- Named and Shamed
	[306415] = "CC",				-- Named and Shamed
	[307315] = "CC",				-- Recovering
	[324683] = "CC",				-- Suckerpunch
	[345169] = "CC",				-- Twinkledust
	[331533] = "CC",				-- Feeling Froggy
	[323075] = "CC",				-- Malefic Resonance
	[340704] = "CC",				-- Externalize Rage
	[324666] = "CC",				-- Duke's Descent
	[324660] = "CC",				-- Madness
	[335059] = "CC",				-- Light of Truth
	[340770] = "CC",				-- Glacial Ray
	[318685] = "CC",				-- Tripped
	[318939] = "CC",				-- Vulpin Shenanigans
	[341226] = "CC",				-- Charge
	[342187] = "CC",				-- Beckon
	[340593] = "CC",				-- Bewildering Slam
	[340469] = "CC",				-- Radiant Breath
	[272272] = "CC",				-- Trampling Charge
	[343153] = "CC",				-- Twilight Barrage (all damage done reduced by 75%)
	[218956] = "CC",				-- Pounce
	[335190] = "CC",				-- Weaken Will
	[329976] = "CC",				-- Pacifying Dust
	[329508] = "CC",				-- Incapacitated
	[331925] = "CC",				-- Horrorscape
	[339352] = "CC",				-- Death Splinter
	[342886] = "CC",				-- Twilight Dust
	[342519] = "CC",				-- Psychic Yoke
	[338756] = "CC",				-- Overcharged
	[321746] = "CC",				-- Reverberate Anima
	[337511] = "CC",				-- Emberlight Flash
	[337508] = "CC",				-- Explosive Animastore
	[336711] = "CC",				-- Hazardous Animacache
	[328010] = "CC",				-- Anima Overwhelming
	[332642] = "CC",				-- Dream Dust
	[311837] = "CC",				-- Dazed
	[332473] = "CC",				-- Sweeping Slashes
	[320234] = "CC",				-- Shimmer Down
	[340207] = "CC",				-- Anima Flash
	[340228] = "CC",				-- Relentless Mauling
	[309908] = "CC",				-- Anima Overwhelming
	[323592] = "CC",				-- Widow Venom
	[335447] = "CC",				-- Hungering Eruption
	[340134] = "CC",				-- Massive Shockwave
	[313189] = "CC",				-- Doubt (chance to hit with attacks and abilities decreased by 100%)
	[332569] = "CC",				-- Pinning Spear
	[340468] = "CC",				-- Kollect Weapon (disarmed and damage done reduced by 100%)
	[323936] = "CC",				-- Disarm (disarmed and damage done reduced by 100%)
	[332643] = "CC",				-- Mass Temptation
	[336893] = "CC",				-- Terrifying Chaos
	[337552] = "CC",				-- Molten Crash
	[332655] = "CC",				-- Cantrip of Flame
	[332653] = "CC",				-- Cantrip of Frost
	[330402] = "CC",				-- Blinding Ash
	[319380] = "CC",				-- Crushing Strike
	[316298] = "CC",				-- Stunned!
	[316326] = "CC",				-- Stunned!
	[338836] = "CC",				-- Agent of Chaos
	[338950] = "CC",				-- Mark of Penance
	[330678] = "CC",				-- Bellowing Roar
	[314182] = "CC",				-- Sin Lash
	[319229] = "CC",				-- Wrathful Invocation
	[327621] = "CC",				-- Anima Trap
	[327957] = "CC",				-- Condensed Anima Vial
	[329396] = "CC",				-- Darkest Secrets
	[307452] = "CC",				-- Pounce
	[313065] = "CC",				-- Light Impalement
	[328927] = "CC",				-- Final Strike (silenced and disarmed)
	[336991] = "CC",				-- Blinding Trap
	[312779] = "CC",				-- Feign Death
	[322683] = "CC",				-- Ice Block
	[240009] = "CC",				-- Howl from Beyond
	[342820] = "CC",				-- Charge
	[347146] = "CC",				-- Wave of Trepidation
	[337121] = "CC",				-- Overpowering Dirge
	[343119] = "CC",				-- Mournful Dirge
	[343830] = "CC",				-- Dominating Grasp
	[343172] = "CC",				-- Soulfreezing Rune
	[336974] = "CC",				-- Screeching Madness
	[345148] = "CC",				-- Echoes of Misery
	[347154] = "CC",				-- Focused Loathing
	[340031] = "CC",				-- Charge
	[339581] = "CC",				-- Transmute Anima
	[339828] = "CC",				-- Mawrat Maul
	[345331] = "CC",				-- Silence of the Grave
	[345520] = "CC",				-- Gauntlet Smash
	[344975] = "CC",				-- Lost Hope
	[346605] = "CC",				-- Shockwave
	[346266] = "CC",				-- Severing Doom
	[341747] = "CC",				-- Overwhelming Misery
	[333976] = "CC",				-- Flash
	[346652] = "CC",				-- Otherworldly Screeching
	[346239] = "CC",				-- Incalculable Daze
	[324418] = "CC",				-- Anima Transfer
	[326726] = "CC",				-- Sleep
	[341788] = "CC",				-- Crystallize
	[335711] = "CC",				-- Dark Miasma
	[339372] = "CC",				-- Eternal Slumber
	[329867] = "CC",				-- Overwhelming Depression
	[353378] = "CC",				-- Anima Extrapolation
	[355945] = "CC",				-- Detonate
	[341219] = "CC",				-- Charge
	[357995] = "CC",				-- Pillage Hope
	[355682] = "CC",				-- Rift Scream
	[346191] = "CC",				-- Ensared
	[357920] = "CC",				-- Crushing Swipe
	[324849] = "CC",				-- Dark Leap
	[334699] = "CC",				-- Vorkai Charge
	[326145] = "CC",				-- Cage of Humility
	[354625] = "CC",				-- Bubble Trap
	[352215] = "CC",				-- Cries of the Tormented
	[358327] = "CC",				-- Cries of the Tormented
	[358270] = "CC",				-- Pain Bringer
	[357499] = "CC",				-- Bewildering Pollen
	[357970] = "CC",				-- Haunting Shout
	[358468] = "CC",				-- Psychic Blast
	[356885] = "CC",				-- Terrifying Roar
	[356306] = "CC",				-- Devastating Smash
	[358483] = "CC",				-- Horrific Surge
	[358330] = "CC",				-- Binding Chains
	[357871] = "CC",				-- Death Wave
	[358219] = "CC",				-- Bewildering Pollen
	[358462] = "CC",				-- Destructive Greed
	[354841] = "CC",				-- Cross the Veil
	[358307] = "CC",				-- Entropic Detonation
	[355799] = "CC",				-- Rift Slam
	[358082] = "CC",				-- Cry of Desolation
	[356384] = "CC",				-- Pulverize
	[339963] = "CC",				-- Leap
	[352220] = "CC",				-- Dreadful Blend
	[335495] = "CC",				-- Severing Roar
	[357236] = "CC",				-- Tormenting Flames
	[357943] = "CC",				-- Unnerving Howl
	[352799] = "CC",				-- Collected
	[333793] = "CC",				-- Eating
	[350724] = "CC",				-- Rising Bile
	[336108] = "CC",				-- Unstable Animapod
	[350901] = "CC",				-- Volatile Concoction
	[217017] = "CC",				-- Slumber
	[205605] = "CC",				-- Psychic Scream
	[353202] = "CC",				-- Blinding Dust
	[353333] = "CC",				-- Moonberry's Trick: Snail
	[126663] = "CC",				-- Debilitating Strike
	[351044] = "CC",				-- Dirge of Dread
	[351622] = "CC",				-- Anima Farshot
	[352817] = "CC",				-- Moonberry's Trick: Shrink
	[352160] = "CC",				-- Caught!
	[336044] = "CC",				-- Wildershroom Sickness
	[307530] = "CC",				-- Moment of Clarity
	[343090] = "CC",				-- Dissonance
	[353983] = "CC",				-- Stone Prison
	[350706] = "CC",				-- Fugue State
	[350770] = "CC",				-- Fugue State
	[350948] = "CC",				-- Fugue State
	[351958] = "CC",				-- Fugue State
	[340887] = "CC",				-- Summon the Fallen
	[323132] = "CC",				-- Pure Tone
	[323127] = "CC",				-- Pure Tone
	[341683] = "CC",				-- Anima Devour
	[354556] = "CC",				-- Sleeping Mist
	[354775] = "CC",				-- Small Shell Shock
	[321744] = "CC",				-- Deadly Pounce
	[346323] = "CC",				-- Entangling Trap
	[315963] = "CC",				-- Panic Stricken
	[334350] = "CC",				-- Peck Acorn
	[320566] = "CC",				-- Surprise!
	[349897] = "CC",				-- Quiet Suicide
	[337347] = "CC",				-- Shockwave
	[325706] = "Silence",			-- Call to Chaos
	[337064] = "Silence",			-- Forgotten Voice
	[345340] = "Silence",			-- Dead Quiet
	[353848] = "Silence",			-- Slanknen's Salty Soak
	[332442] = "Disarm",			-- Hurled Charge
	[346992] = "Disarm",			-- Disarm
	[325034] = "Disarm",			-- Called Shot: Arm
	[333240] = "Immune",			-- Blade Guardian's Rune (not immune, 50% damage reduction)
	[313440] = "Immune",			-- Indomitable Shield
	[331762] = "Immune",			-- Necrotic Shield (not immune, 50% damage reduction)
	[319557] = "Immune",			-- Barricaded (not immune, damage taken reduced by 50%)
	[350454] = "Immune",			-- Shell Shocked (not immune, damage taken reduced by 50%)
	[356805] = "Immune",			-- Mawsworn Bulwark (not immune, damage taken reduced by 90%)
	[310364] = "Immune",			-- Inquisitor's Immunity
	[321345] = "Immune",			-- Harvester's Might (not immune, damage taken reduced by 75%)
	[339373] = "Immune",			-- Impenetrable Chitin (damage taken reduced by 95%)
	[318860] = "Immune",			-- Ravenous Shield
	[321441] = "Immune",			-- Crimson Ward
	[344530] = "Immune",			-- Edict of the Eternal Ones
	[348464] = "Immune",			-- Lingering Cloak of Ve'nari
	[338038] = "Immune",			-- Misty Veil
	[333856] = "Immune",			-- Soul Barrier
	[290378] = "Immune",			-- Rock of Life
	[334791] = "Immune",			-- Undeath Barrier
	[346495] = "Immune",			-- Spectral Wing Guard
	[346336] = "Immune",			-- Phase Shift
	[339123] = "Immune",			-- Shade Shift
	[338486] = "Immune",			-- Conversion Trance
	[340297] = "Immune",			-- Anchoring Rune Barrier
	[355864] = "Immune",			-- Krelva's Resolve
	[354148] = "Immune",			-- Herald's Immunity
	[356192] = "Immune",			-- Popo's Potion (not immune, damage taken reduced by 50%)
	[356193] = "Immune",			-- Popo's Potion (not immune, damage taken reduced by 50%)
	[352181] = "Immune",			-- Flameforged Core not immune, damage taken reduced by 99%)
	[343046] = "ImmuneSpell",		-- Magic Shell (magic damage taken reduced by 70%)
	[320401] = "ImmuneSpell",		-- Lucky Dust
	[357956] = "ImmuneSpell",		-- Magebane Ward
	[343062] = "ImmunePhysical",	-- Iron Shell
	[328286] = "ImmunePhysical",	-- Nimble Dodge (increased dodge chance by 100%)
	[340398] = "ImmunePhysical",	-- Aura of Protection
	[63861]  = "Root",				-- Chains of Law
	[311077] = "Root",				-- Deep Introspection
	[311068] = "Root",				-- Deep Introspection
	[311113] = "Root",				-- Gotta Dance
	[340736] = "Root",				-- Rainbow Rush
	[329710] = "Root",				-- Creeping Tendrils
	[302124] = "Root",				-- Ol' Big Tusk Charge
	[311767] = "Root",				-- Death From Above
	[330456] = "Root",				-- Shadow Surge
	[330106] = "Root",				-- Shadow Surge
	[330593] = "Root",				-- Web
	[308277] = "Root",				-- Entangling Spores
	[328782] = "Root",				-- Webspinner Song
	[329023] = "Root",				-- Extra Sticky Spidey Webs
	[312353] = "Root",				-- Soultrapped
	[331515] = "Root",				-- Time Out
	[345002] = "Root",				-- Calcify
	[330436] = "Root",				-- Entrap Soul
	[346439] = "Root",				-- Culling Blades
	[305752] = "Root",				-- Javelin of Justice
	[357455] = "Root",				-- Hollow Roots
	[358871] = "Root",				-- Falling Strike
	[358170] = "Root",				-- Wrapping Vines
	[358014] = "Root",				-- Binding Torment
	[358232] = "Root",				-- Entangling Roots
	[352766] = "Root",				-- Heavy Hands
	[354588] = "Root",				-- Grasping Roots
	[360423] = "Root",				-- Tome of Small Sins
	[335047] = "Other",				-- Goliath Bulwark (deflecting attacks from the front)
	[338085] = "Other",				-- Necrosis (healing received reduced by 100%)
	[321000] = "Other",				-- Unholy Bulwark (deflecting attacks from the front)
	[329889] = "Other",				-- Planar Dissonance (damage dealt reduced by 50%, damage taken increased by 200%)
	[358506] = "Other",				-- Decaying Grasp (healing received reduced by 75%)
	[324883] = "Other",				-- Decaying Spores (damage done reduced by 50%)
	--[356567] = "Other",				-- Shackles of Malediction
	--[358259] = "Other",				-- Gladiator's Maledict
	[51878]  = "Snare",				-- Ice Slash
	[329158] = "Snare",				-- Frigid Blast
	[321525] = "Snare",				-- Spectral Shackle
	[320028] = "Snare",				-- Ground Pound
	[330092] = "Snare",				-- Plaguefallen
	[324795] = "Snare",				-- Slime Blast
	[332293] = "Snare",				-- Hurled Charge
	[317341] = "Snare",				-- Reluctant Soul
	[327754] = "Snare",				-- Soulbreaker Trap
	[324003] = "Snare",				-- Siphon
	[324004] = "Snare",				-- Drained
	[322686] = "Snare",				-- Chilled
	[343421] = "Snare",				-- Cursed Heart
	[334882] = "Snare",				-- Sticky Muck
	[336252] = "Snare",				-- Sticky Spittle
	[185152] = "Snare",				-- Flame Binding
	[329432] = "Snare",				-- Cripple
	[347163] = "Snare",				-- Iron Shackles
	[334177] = "Snare",				-- Death's Demise
	[336040] = "Snare",				-- Heartshroom Bloat
	[308228] = "Snare",				-- Shackles
	[342252] = "Snare",				-- Cursed Heart
	[220242] = "Snare",				-- Eye of Dread
	[343072] = "Snare",				-- Crushing Stomp
	[336859] = "Snare",				-- Fel Armament
	[324114] = "Snare",				-- Forbidden Knowledge
	[340482] = "Snare",				-- Explosive Fungistorm
	[344408] = "Snare",				-- Carrying a Rock
	[339617] = "Snare",				-- Crushing Strength
	[319728] = "Snare",				-- Drain Anima
	[166906] = "Snare",				-- Pinning Shot
	[335505] = "Snare",				-- Smash
	[345010] = "Snare",				-- Wracking Pain
	[346629] = "Snare",				-- Punishing Strike
	[346255] = "Snare",				-- Iron Shackles
	[346811] = "Snare",				-- Iron Shackles
	[329430] = "Snare",				-- Ghastly Wail
	[342341] = "Snare",				-- Wormhole Sickness
	[341812] = "Snare",				-- Stygic Pool
	[324744] = "Snare",				-- Debilitating Beam
	[357110] = "Snare",				-- Mawchains
	[352302] = "Snare",				-- Gormblood Poison
	[357703] = "Snare",				-- Shadowstorm
	[358481] = "Snare",				-- Discordant Wail
	[358323] = "Snare",				-- Binding Chains
	[355805] = "Snare",				-- Wracking Torture
	[325036] = "Snare",				-- Called Shot: Leg
	[355795] = "Snare",				-- Rift Stare
	[355939] = "Snare",				-- Wracking Interrogation
	[355824] = "Snare",				-- Devourer Ambush
	[356169] = "Snare",				-- Lumbering Roar
	[356911] = "Snare",				-- Metallic Resonance
	[351053] = "Snare",				-- Slime's Demise
	[351174] = "Snare",				-- Frostbolt Volley
	[351173] = "Snare",				-- Frostbolt
	[351876] = "Snare",				-- Vorkai Net
	[357856] = "Snare",				-- Wake of Ashes
	[171858] = "Snare",				-- Frostbolt
	[357458] = "Snare",				-- Oil Slicked Spin Out
	[361180] = "Snare",				-- Observe Weakness
	[56]     = "CC",				-- Stun (some weapons proc)
	[835]    = "CC",				-- Tidal Charm (trinket)
	[8312]   = "Root",				-- Trap (Hunting Net trinket)
	[17308]  = "CC",				-- Stun (Hurd Smasher fist weapon)
	[23454]  = "CC",				-- Stun (The Unstoppable Force weapon)
	[9179]   = "CC",				-- Stun (Tigule and Foror's Strawberry Ice Cream item)
	[13327]  = "CC",				-- Reckless Charge (Goblin Rocket Helmet)
	[20549]  = "CC",				-- War Stomp (tauren racial)
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
	[23412]  = "Snare",				-- Frostbolt
	[24942]  = "Snare",				-- Frostbolt
	[23102]  = "Snare",				-- Frostbolt
	[20828]  = "Snare",				-- Cone of Cold
	[22746]  = "Snare",				-- Cone of Cold
	[20717]  = "Snare",				-- Sand Breath
	[16568]  = "Snare",				-- Mind Flay
	[29407]  = "Snare",				-- Mind Flay
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
	[5219]   = "Root",				-- Draw of Thistlenettle
	[9576]   = "Root",				-- Lock Down
	[7950]   = "Root",				-- Pause
	[7761]   = "Root",				-- Shared Bondage
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
	[5403]   = "Root",				-- Crash of Waves
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
	[23676]  = "CC",				-- Minigun (chance to hit reduced by 50%)
	[11983]  = "CC",				-- Steam Jet (chance to hit reduced by 30%)
	[9612]   = "CC",				-- Ink Spray (chance to hit reduced by 50%)
	[4150]   = "CC",				-- Eye Peck (chance to hit reduced by 47%)
	[6530]   = "CC",				-- Sling Dirt (chance to hit reduced by 40%)
	[5101]   = "CC",				-- Dazed
	[4320]   = "Silence",			-- Trelane's Freezing Touch
	[4243]   = "Silence",			-- Pester Effect
	[9552]   = "Silence",			-- Searing Flames
	[10576]  = "Silence",			-- Piercing Howl
	[12943]  = "Silence",			-- Fell Curse Effect
	[23417]  = "Silence",			-- Smother
	[10851]  = "Disarm",			-- Grab Weapon
	[27581]  = "Disarm",			-- Disarm
	[25057]  = "Disarm",			-- Dropped Weapon
	[25655]  = "Disarm",			-- Dropped Weapon
	[14180]  = "Disarm",			-- Sticky Tar
	[6576]   = "CC",				-- Intimidating Growl
	[7093]   = "CC",				-- Intimidation
	[8715]   = "CC",				-- Terrifying Howl
	[8817]   = "CC",				-- Smoke Bomb
	[9458]   = "CC",				-- Smoke Cloud
	[3442]   = "CC",				-- Enslave
	[3651]   = "ImmuneSpell",		-- Shield of Reflection
	[20223]  = "ImmuneSpell",		-- Magic Reflection
	[27546]  = "ImmuneSpell",		-- Faerie Dragon Form (not immune, 50% magical damage reduction)
	[17177]  = "ImmunePhysical",	-- Seal of Protection
	[25772]  = "CC",				-- Mental Domination
	[16053]  = "CC",				-- Dominion of Soul (Orb of Draconic Energy)
	[15859]  = "CC",				-- Dominate Mind
	[20740]  = "CC",				-- Dominate Mind
	[20668]  = "CC",				-- Sleepwalk
	[21330]  = "CC",				-- Corrupted Fear (Deathmist Raiment set)
	[27868]  = "Root",				-- Freeze (Magister's and Sorcerer's Regalia sets)
	[17333]  = "Root",				-- Spider's Kiss (Spider's Kiss set)
	[26108]  = "CC",				-- Glimpse of Madness (Dark Edge of Insanity axe)
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
	[17624]  = "CC",				-- Flask of Petrification
	[13534]  = "Disarm",			-- Disarm (The Shatterer weapon)
	[11879]  = "Disarm",			-- Disarm (Shoni's Disarming Tool weapon)
	[13439]  = "Snare",				-- Frostbolt (some weapons)
	[16621]  = "ImmunePhysical",	-- Self Invulnerability (Invulnerable Mail)
	[27559]  = "Silence",			-- Silence (Jagged Obsidian Shield)
	[13907]  = "CC",				-- Smite Demon (Enchant Weapon - Demonslaying)
	[18798]  = "CC",				-- Freeze (Freezing Band)
	[17500]  = "CC",				-- Malown's Slam (Malown's Slam weapon)
	[34510]  = "CC",				-- Stun (Stormherald and Deep Thunder weapons)
	[46567]  = "CC",				-- Rocket Launch (Goblin Rocket Launcher trinket)
	[30501]  = "Silence",			-- Poultryized! (Gnomish Poultryizer trinket)
	[30504]  = "Silence",			-- Poultryized! (Gnomish Poultryizer trinket)
	[30506]  = "Silence",			-- Poultryized! (Gnomish Poultryizer trinket)
	[35474]  = "CC",				-- Drums of Panic (Drums of Panic item)
	[28504]  = "CC",				-- Major Dreamless Sleep (Major Dreamless Sleep Potion)
	[30216]  = "CC",				-- Fel Iron Bomb
	[30217]  = "CC",				-- Adamantite Grenade
	[30461]  = "CC",				-- The Bigger One
	[31367]  = "Root",				-- Netherweave Net (tailoring item)
	[31368]  = "Root",				-- Heavy Netherweave Net (tailoring item)
	[39965]  = "Root",				-- Frost Grenade
	[36940]  = "CC",				-- Transporter Malfunction
	[51581]  = "CC",				-- Rocket Boots Malfunction
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
	[43441]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[44268]  = "Other",				-- Mortal Strike (healing effects reduced by 50%)
	[34625]  = "Other",				-- Demolish (healing effects reduced by 75%)
	[36513]  = "ImmunePhysical",	-- Intangible Presence (not immune, physical damage taken reduced by 40%)
	[31731]  = "Immune",			-- Shield Wall (not immune, damage taken reduced by 60%)
	[41104]  = "Immune",			-- Shield Wall (not immune, damage taken reduced by 60%)
	[41196]  = "Immune",			-- Shield Wall (not immune, damage taken reduced by 75%)
	[45954]  = "Immune",			-- Ahune's Shield (not immune, damage taken reduced by 90%)
	[46416]  = "Immune",			-- Ahune Self Stun
	[50279]  = "Immune",			-- Copy of Elemental Shield (not immune, damage taken reduced by 75%)
	[30858]  = "Immune",			-- Demon Blood Shell
	[42206]  = "Immune",			-- Protection
	[33581]  = "Immune",			-- Divine Shield
	[40733]  = "Immune",			-- Divine Shield
	[41367]  = "Immune",			-- Divine Shield
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
	[34518]  = "ImmunePhysical",	-- Nether Protection (Embrace of the Twisting Nether & Twisting Nether Chain Shirt items)
	[38026]  = "ImmunePhysical",	-- Viscous Shield
	[36576]  = "ImmuneSpell",		-- Shaleskin (not immune, magic damage taken reduced by 50%)
	[39804]  = "ImmuneSpell",		-- Damage Immunity: Magic
	[39811]  = "ImmuneSpell",		-- Damage Immunity: Fire, Frost, Shadow, Nature, Arcane
	[39666]  = "ImmuneSpell",		-- Cloak of Shadows
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
	[33390]  = "Silence",			-- Arcane Torrent
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
	[43550]  = "CC",				-- Mind Control
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
	[43443]  = "ImmuneSpell",		-- Spell Reflection
	[28516]  = "Silence",			-- Sunwell Torrent (Sunwell Blade & Sunwell Orb items)
	[33913]  = "Silence",			-- Soul Burn
	[37031]  = "Silence",			-- Chaotic Temperament
	[41247]  = "Silence",			-- Shared Suffering
	[44957]  = "Silence",			-- Nether Shock
	[31955]  = "Disarm",			-- Disarm
	[34097]  = "Disarm",			-- Riposte
	[34099]  = "Disarm",			-- Riposte
	[36208]  = "Disarm",			-- Steal Weapon
	[36510]  = "Disarm",			-- Enchanted Weapons
	[39489]  = "Disarm",			-- Enchanted Weapons
	[41053]  = "Disarm",			-- Whirling Blade
	[41392]  = "Disarm",			-- Riposte
	[47310]  = "Disarm",			-- Direbrew's Disarm
	[30298]  = "CC",				-- Tree Disguise
	[42695]  = "CC",				-- Holiday - Brewfest - Dark Iron Knock-down Power-up
	[49750]  = "CC",				-- Honey Touched
	[42380]  = "CC",				-- Conflagration
	[42408]  = "CC",				-- Headless Horseman Climax - Head Stun
	[42435]  = "CC",				-- Brewfest - Stun
	[47718]  = "CC",				-- Direbrew Charge
	[47340]  = "CC",				-- Dark Brewmaiden's Stun
	[50093]  = "CC",				-- Chilled
	[29044]  = "CC",				-- Hex
	[30838]  = "CC",				-- Polymorph
	[34654]  = "CC",				-- Blind
	[35840]  = "CC",				-- Conflagration
	[37289]  = "CC",				-- Dragon's Breath
	[39293]  = "CC",				-- Conflagration
	[40400]  = "CC",				-- Hex
	[41397]  = "CC",				-- Confusion
	[43433]  = "CC",				-- Blind
	[45665]  = "CC",				-- Encapsulate
	[51413]  = "CC",				-- Barreled!
	[26661]  = "CC",				-- Fear
	[31358]  = "CC",				-- Fear
	[31404]  = "CC",				-- Shrill Cry
	[32040]  = "CC",				-- Scare Daggerfen
	[32241]  = "CC",				-- Fear
	[32709]  = "CC",				-- Death Coil
	[33829]  = "CC",				-- Fleeing in Terror
	[33924]  = "CC",				-- Fear
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
	[41070]  = "CC",				-- Death Coil
	[41436]  = "CC",				-- Panic
	[42690]  = "CC",				-- Terrifying Roar
	[42869]  = "CC",				-- Conflagration
	[43432]  = "CC",				-- Psychic Scream
	[44142]  = "CC",				-- Death Coil
	[46283]  = "CC",				-- Death Coil
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
	[31292]  = "CC",				-- Sleep
	[31390]  = "CC",				-- Knockdown
	[31408]  = "CC",				-- War Stomp
	[31539]  = "CC",				-- Self Stun Forever
	[31541]  = "CC",				-- Sleep
	[31548]  = "CC",				-- Sleep
	[31733]  = "CC",				-- Charge
	[31819]  = "CC",				-- Cheap Shot
	[31843]  = "CC",				-- Cheap Shot
	[31964]  = "CC",				-- Thundershock
	[31994]  = "CC",				-- Shoulder Charge
	[32015]  = "CC",				-- Knockdown
	[32021]  = "CC",				-- Rushing Charge
	[32023]  = "CC",				-- Hoof Stomp
	[32104]  = "CC",				-- Backhand
	[32105]  = "CC",				-- Kick
	[32150]  = "CC",				-- Infernal
	[32416]  = "CC",				-- Hammer of Justice
	[32588]  = "CC",				-- Concussion Blow
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
	[37527]  = "CC",				-- Banish
	[37592]  = "CC",				-- Knockdown
	[37768]  = "CC",				-- Metamorphosis
	[37833]  = "CC",				-- Banish
	[37919]  = "CC",				-- Arcano-dismantle
	[38006]  = "CC",				-- World Breaker
	[38009]  = "CC",				-- Banish
	[38169]  = "CC",				-- Subservience
	[38235]  = "CC",				-- Water Tomb
	[38357]  = "CC",				-- Tidal Surge
	[38461]  = "CC",				-- Charge
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
	[41186]  = "CC",				-- Wyvern Sting
	[41358]  = "CC",				-- Rizzle's Blackjack
	[41421]  = "CC",				-- Brief Stun
	[41528]  = "CC",				-- Mark of Stormrage
	[41534]  = "CC",				-- War Stomp
	[41592]  = "CC",				-- Spirit Channelling
	[41962]  = "CC",				-- Possession Transfer
	[42386]  = "CC",				-- Sleeping Sleep
	[42621]  = "CC",				-- Fire Bomb
	[42648]  = "CC",				-- Sleeping Sleep
	[43448]  = "CC",				-- Freezing Trap
	[43519]  = "CC",				-- Charge
	[43528]  = "CC",				-- Cyclone
	[44138]  = "CC",				-- Rocket Launch
	[44415]  = "CC",				-- Blackout
	[44432]  = "CC",				-- Cube Ground State
	[44836]  = "CC",				-- Banish
	[44994]  = "CC",				-- Self Repair
	[45270]  = "CC",				-- Shadowfury
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
	[43207]  = "Root",				-- Fiery Breath
	[43049]  = "Root",				-- Upset Tummy
	[31287]  = "Root",				-- Entangling Roots
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
	[39268]  = "Root",				-- Chains of Ice
	[40363]  = "Root",				-- Entangling Roots
	[40525]  = "Root",				-- Rizzle's Frost Grenade
	[40590]  = "Root",				-- Rizzle's Frost Grenade (Self
	[40727]  = "Root",				-- Icy Leap
	[40875]  = "Root",				-- Freeze
	[41981]  = "Root",				-- Dust Field
	[42716]  = "Root",				-- Self Root Forever (No Visual)
	[43130]  = "Root",				-- Creeping Vines
	[43150]  = "Root",				-- Claw Rage
	[43426]  = "Root",				-- Frost Nova
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
	[37276]  = "Snare",				-- Mind Flay
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
	[38712]  = "Snare",				-- Blast Wave
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
	[43428]  = "Snare",				-- Frostbolt
	[43530]  = "Snare",				-- Piercing Howl
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
	---- PVE SHADOWLANDS
	------------------------
	-- Sanctum of Domination Raid
	-- -- Trash
	[355063] = "CC",				-- Crushing Strike
	[355212] = "CC",				-- Fearsome Howl
	[357286] = "CC",				-- River's Grasp
	[357288] = "CC",				-- River's Grasp
	[355950] = "CC",				-- Crushing Slam
	[356955] = "CC",				-- Torture
	[358748] = "CC",				-- Gauntlet Smash
	[357123] = "CC",				-- Bloodcurdling Howl
	[358978] = "CC",				-- Spite
	[355302] = "CC",				-- Chain Burst
	[358758] = "CC",				-- Shattered Destiny
	[357138] = "CC",				-- Stonecrash
	[354904] = "CC",				-- Sundering Smash
	[354900] = "CC",				-- Earthen Grasp
	[355992] = "Immune",			-- Infusion
	[355975] = "Immune",			-- Infuse Deathsight
	[356901] = "Immune",			-- Submerge
	[355231] = "Immune",			-- Commanding Presence (not immune, damage taken reduced by 50%)
	[355049] = "Other",				-- Gathering Power (damage done increased by 50%)
	[357128] = "Root",				-- Gaoler's Chains
	[357259] = "Snare",				-- Drink Soul
	[354925] = "Snare",				-- Pulverize
	-- -- The Tarragrue
	[347981] = "Immune",			-- Unstable Form (not immune, damage taken reduced by 99%)
	[354172] = "CC",				-- Ten of Towers
	[347990] = "CC",				-- Ten of Towers
	[347991] = "CC",				-- Ten of Towers
	[354173] = "CC",				-- Chains of Eternity
	[347554] = "CC",				-- Chains of Eternity
	[348314] = "CC",				-- The Jailer's Gaze
	[346985] = "CC",				-- Overpower
	[347286] = "CC",				-- Unshakeable Dread
	[347274] = "CC",				-- Annihilating Smash
	-- -- Eye of the Jailer
	[348805] = "Immune",			-- Stygian Darkshield
	[350006] = "CC",				-- Pulled Down
	[350606] = "Snare",				-- Hopeless Lethargy
	[350713] = "Snare",				-- Slothful Corruption
	-- -- The Nine
	[350158] = "Immune",			-- Annhylde's Bright Aegis (not immune, damage taken reduced by 90%)
	[350374] = "CC",				-- Wings of Rage
	[352757] = "CC",				-- Wings of Rage
	[350462] = "CC",				-- Reverberating Refrain
	[352753] = "CC",				-- Reverberating Refrain
	[350555] = "Snare",				-- Shard of Destiny
	-- -- Remnant of Ner'zhul
	[355790] = "Immune",			-- Eternal Torment (not immune, damage taken reduced by 99%)
	[354479] = "CC",				-- Spite
	[354534] = "CC",				-- Spite
	[354634] = "CC",				-- Spite
	[350388] = "Snare",				-- Sorrowful Procession
	-- -- Soulrender Dormazain
	[351946] = "CC",				-- Hellscream
	-- -- Painsmith Raznal
	[359033] = "Immune",			-- Forge's Flames
	[350653] = "CC",				-- Terrifying Shriek
	[348363] = "CC",				-- Spiked Ball
	[355526] = "CC",				-- Spiked
	[359112] = "CC",				-- Spiked
	-- -- Guardian of the First Ones
	[347359] = "CC",				-- Suppression Field
	[352833] = "CC",				-- Disintegration
	-- -- Fatescribe Roh-Kalo
	[357739] = "Immune",			-- Realign Fate (not immune, damage taken reduced by 99%)
	-- -- Kel'Thuzad
	[347518] = "CC",				-- Oblivion's Echo
	[347454] = "CC",				-- Oblivion's Echo
	[348638] = "CC",				-- Return of the Damned
	[354848] = "Immune",			-- Undying Wrath
	[352381] = "Root",				-- Freezing Blast
	[357298] = "Root",				-- Frozen Binds
	[355058] = "Root",				-- Glacial Winds
	[355948] = "Other",				-- Necrotic Empowerment
	-- -- Sylvanas Windrunner
	[350857] = "Immune",			-- Banshee Shroud
	[357738] = "Immune",			-- Defensive Field
	[357728] = "CC",				-- Blasphemy
	[358805] = "CC",				-- Merciless
	[354176] = "CC",				-- Crippling Defeat
	[356023] = "CC",				-- Terror Orb
	[357109] = "CC",				-- Arcane Stasiswave
	[355488] = "CC",				-- Sylvanas
	[358550] = "CC",				-- Sylvanas
	[359062] = "CC",				-- Sylvanas
	[358806] = "Immune",			-- Sylvanas
	[358985] = "Immune",			-- Sylvanas
	[353957] = "Silence",			-- Banshee Scream
	[354926] = "Root",				-- Runic Mark
	[347608] = "Root",				-- Sylvanas
	[350003] = "Snare",				-- Cone of Cold
	-- Castle Nathria Raid
	-- -- Trash
	[341867] = "CC",				-- Subdue
	[329438] = "CC",				-- Doubt (chance to hit with attacks and abilities decreased by 100%)
	[327474] = "CC",				-- Crushing Doubt
	[326227] = "CC",				-- Insidious Anxieties
	[340622] = "CC",				-- Headbutt
	[338618] = "Immune",			-- Nobility's Guard (not immune, damage taken reduced by 90%)
	[339525] = "Root",				-- Concentrate Anima
	[343325] = "Snare",				-- Curse of Sindrel
	-- -- Shriekwing
	[343024] = "CC",				-- Horrified
	[328921] = "Immune",			-- Blood Shroud 
	-- -- Sun King's Salvation
	[333145] = "CC",				-- Return to Stone
	-- -- Artificer Xy'mox
	[326302] = "CC",				-- Stasis Trap
	[327414] = "CC",				-- Possession
	[342874] = "Immune",			-- Stasis Shield
	-- -- Hungering Destroyer
	--[329298] = "Other",				-- Gluttonous Miasma (healing received reduced by 100%)
	-- -- Lady Inerva Darkvein
	[338666] = "CC",				-- Warped Cognition
	[332664] = "Root",				-- Concentrated Anima
	[340477] = "Root",				-- Concentrated Anima
	[335396] = "Root",				-- Hidden Desire
	[341746] = "Root",				-- Rooted in Anima
	--[324982] = "Silence",			-- Shared Suffering
	-- -- The Council of Blood
	[346694] = "Immune",			-- Unyielding Shield
	[335775] = "Immune",			-- Unyielding Shield (not immune, damage taken reduced by 90%)
	[327619] = "CC",				-- Waltz of Blood
	[328334] = "CC",				-- Tactical Advance
	[331706] = "CC",				-- Scarlet Letter
	-- -- Sludgefist
	[331314] = "CC",				-- Destructive Impact
	[335295] = "CC",				-- Shattering Chain
	[332572] = "CC",				-- Falling Rubble
	[339067] = "CC",				-- Heedless Charge
	[339181] = "Root",				-- Chain Slam (Root)
	-- -- Stone Legion Generals
	[329636] = "Immune",			-- Hardened Stone Form (not immune, damage taken reduced by 95%)
	[329808] = "Immune",			-- Hardened Stone Form (not immune, damage taken reduced by 95%)
	[342735] = "CC",				-- Ravenous Feast
	[343273] = "CC",				-- Ravenous Feast
	[339693] = "CC",				-- Crystalline Burst
	[334616] = "CC",				-- Petrified
	[331986] = "Root",				-- Chains of Suppression
	-- -- Sire Denathrius
	[326851] = "CC",				-- Blood Price
	[328276] = "CC",				-- March of the Penitent
	[328222] = "CC",				-- March of the Penitent
	[331982] = "CC",				-- Debilitating Injury
	[336388] = "CC",				-- Weight of Contrition
	[341732] = "Silence",			-- Searing Censure
	[341426] = "Silence",			-- Searing Censure
	-- Shadowlands World Bosses
	-- -- Valinor, The Light of Eons
	[327280] = "CC",				-- Recharge Anima
	-- -- Oranomonos the Everbranching
	[338853] = "Root",				-- Rapid Growth
	[339040] = "Other",				-- Withered Winds (melee and ranged chance to hit reduced by 30%)
	[339023] = "Snare",				-- Dirge of the Fallen Sanctum
	------------------------
	-- Shadowlands Mythics
	-- -- Common
	[342494] = "CC",				-- Belligerent Boast
	[355802] = "Snare",				-- Lumbering Might
	--[355710] = "Snare",				-- Chilling Presence
	--[355714] = "Other",				-- Thanatophobia (healing received reduced by 50%)
	[358973] = "CC",				-- Wave of Terror
	[358777] = "Root",				-- Bindings of Misery
	[357898] = "Other",				-- Crumbling Bulwark (damage taken reduced by 40%)
	[355806] = "CC",				-- Massive Smash
	[357830] = "CC",				-- Gavel of Judgement
	[357540] = "ImmunePhysical",	-- Tiny Dancing Shoes
	[360831] = "ImmunePhysical",	-- Tiny Dancing Shoes
	[357826] = "Other",				-- Vial of Desperation (damage taken reduced by 50%)
	[361180] = "Snare",				-- Observe Weakness
	-- -- Tazavesh, the Veiled Market
	[348006] = "CC",				-- Containment Cell
	[345770] = "CC",				-- Impound Contraband
	[350101] = "Root",				-- Chains of Damnation
	[353414] = "Root",				-- Interrogation
	[347094] = "CC",				-- Titanic Crash
	[355476] = "CC",				-- Shock Mines
	[347097] = "Immune",			-- Security Shield
	[356796] = "CC",				-- Runic Feedback
	[347149] = "CC",				-- Infinite Breath
	[347422] = "CC",				-- Deadly Seas
	[356031] = "CC",				-- Stasis Beam
	[356408] = "CC",				-- Ground Stomp
	[355502] = "CC",				-- Shocklight Barrier
	[347728] = "CC",				-- Flock!
	[345990] = "CC",				-- Containment Cell
	[358168] = "CC",				-- Shocked
	[357452] = "CC",				-- Dancing
	[357512] = "CC",				-- Frenzied Charge
	[357019] = "CC",				-- Lightshard Retreat
	[355465] = "CC",				-- Boulder Throw
	[356560] = "CC",				-- Hyperlight Containment Cell
	[356943] = "Root",				-- Lockdown
	[355640] = "ImmuneSpell",		-- Phalanx Field
	[347775] = "Immune",			-- Spam Filter (not immune, damage taken reduced by 50%)
	[351086] = "Immune",			-- Power Overwhelming (not immune, damage taken reduced by 99%)
	[355147] = "Other",				-- Fish Invigoration
	[356324] = "Snare",				-- Empowered Glyph of Restraint
	[358131] = "Snare",				-- Lightning Nova
	[355915] = "Snare",				-- Glyph of Restraint
	[357229] = "Snare",				-- Chronolight Enhancer
	-- -- De Other Side
	[201441] = "Immune",			-- Thorium Plating
	[201581] = "Immune",			-- Mega Miniaturization Turbo-Beam (Chance to be hit by attacks and spells reduced by 95%)
	[344739] = "Immune",			-- Spectral
	[202310] = "CC",				-- Hyper Zap-o-matic Ultimate Mark III
	[228626] = "CC",				-- Haunted Urn
	[330434] = "Root",				-- Buzz-Saw
	[331847] = "CC",				-- W-00F
	[339978] = "CC",				-- Pacifying Mists
	[324010] = "CC",				-- Eruption
	[331381] = "CC",				-- Slipped
	[338762] = "CC",				-- Slipped
	[334505] = "CC",				-- Shimmerdust Sleep
	[321349] = "CC",				-- Absorbing Haze
	[340026] = "CC",				-- Wailing Grief
	[320132] = "CC",				-- Shadowfury
	[332605] = "CC",				-- Hex
	[320008] = "Snare",				-- Frostbolt
	[332236] = "Snare",				-- Sludgegrab
	[334530] = "Snare",				-- Snaring Gore
	-- -- Halls of Atonement
	[322977] = "CC",				-- Sinlight Visions
	[339237] = "CC",				-- Sinlight Visions
	[319724] = "Immune",			-- Stone Form
	[323741] = "Immune",			-- Ephemeral Visage
	[319611] = "CC",				-- Turned to Stone
	[326876] = "CC",				-- Shredded Ankles
	[326617] = "CC",				-- Turn to Stone
	[326607] = "Immune",			-- Turn to Stone (not immune, damage taken reduced by 50%)
	--[326450] = "Other",				-- Loyal Beasts	(increases all damage done by 125%)
	-- -- Mists of Tirna Scithe
	[323149] = "Immune",			-- Embrace Darkness (not immune, damage taken reduced by 50%)
	[336499] = "Immune",			-- Guessing Game
	[321005] = "CC",				-- Soul Shackle
	[321010] = "CC",				-- Soul Shackle
	[323059] = "CC",				-- Droman's Wrath
	[323137] = "CC",				-- Bewildering Pollen
	[321968] = "CC",				-- Bewildering Pollen
	[328756] = "CC",				-- Repulsive Visage
	[321893] = "CC",				-- Freezing Burst
	[321828] = "CC",				-- Patty Cake
	[337220] = "CC",				-- Parasitic Pacification
	[337251] = "CC",				-- Parasitic Incapacitation
	[337253] = "CC",				-- Parasitic Domination
	[322487] = "CC",				-- Overgrowth
	[340160] = "CC",				-- Radiant Breath
	[323881] = "CC",				-- Envelopment of Mist
	[324859] = "Root",				-- Bramblethorn Entanglement
	[325027] = "Snare",				-- Bramble Burst
	[341898] = "Snare",				-- Bramble Burst
	[322486] = "Snare",				-- Overgrowth
	-- -- The Necrotic Wake
	[320646] = "CC",				-- Fetid Gas
	[335141] = "ImmunePhysical",	-- Dark Shroud
	[345832] = "CC",				-- Dark Grasp
	[343504] = "CC",				-- Dark Grasp
	[345608] = "CC",				-- Forgotten Forgehammer
	[326629] = "Immune",			-- Noxious Fog
	[322548] = "CC",				-- Meat Hook
	[327041] = "CC",				-- Meat Hook
	[320788] = "Root",				-- Frozen Binds
	[323730] = "Root",				-- Frozen Binds
	[322274] = "Snare",				-- Enfeeble
	[334748] = "CC",				-- Drain Fluids
	[345625] = "Silence",			-- Death Burst
	[324293] = "CC",				-- Rasping Scream
	[328051] = "Immune",			-- Discarded Shield (not immune, damage taken reduced by 50%)
	[321576] = "Other",				-- Undying Aura (unkillable)
	[333489] = "Other",				-- Necrotic Breath (healing received reduced by 50%)
	[320573] = "Other",				-- Shadow Well (healing received reduced by 100%)
	[324381] = "Snare",				-- Chill Scythe
	-- -- Plaguefall
	[321521] = "Immune",			-- Congealed Bile (not immune, damage taken reduced by 75%)
	[336449] = "Immune",			-- Bulwark of Maldraxxus (not immune, damage taken reduced by 90%)
	[328175] = "Immune",			-- Congealed Contagion (not immune, damage taken reduced by 75%)
	[326242] = "Root",				-- Slime Wave
	[331818] = "CC",				-- Shadow Ambush
	[336306] = "CC",				-- Web Wrap
	[336301] = "CC",				-- Web Wrap
	[333173] = "CC",				-- Volatile Substance
	[328409] = "Root",				-- Enveloping Webbing
	[328012] = "Root",				-- Binding Fungus
	[328180] = "Root",				-- Gripping Infection
	[328002] = "Snare",				-- Hurl Spores
	[334926] = "Snare",				-- Wretched Phlegm
	[335090] = "Snare",				-- Crushing Embrace
	-- -- Sanguine Depths
	[324092] = "Immune",			-- Shining Radiance (not immune, damage taken reduced by 65%)
	[327107] = "Immune",			-- Shining Radiance (not immune, damage taken reduced by 75%)
	[336749] = "CC",				-- Rend Souls
	[326836] = "Silence",			-- Curse of Suppression
	[335306] = "Root",				-- Barbed Shackles
	-- -- Spires of Ascension
	[324205] = "CC",				-- Blinding Flash
	[323878] = "CC",				-- Drained
	[323744] = "CC",				-- Pounce
	[330388] = "CC",				-- Terrifying Screech
	[339917] = "CC",				-- Spear of Destiny
	[327808] = "Other",				-- Inspiring Presence (damage taken from AoE reduced by 75%)
	[330453] = "Snare",				-- Stone Breath
	[331906] = "Snare",				-- Fling Muck
	-- -- Theater of Pain
	[333540] = "CC",				-- Opportunity Strikes
	[320112] = "CC",				-- Blood and Glory
	[320287] = "CC",				-- Blood and Glory
	[319539] = "CC",				-- Soulless
	[333567] = "CC",				-- Possession
	[331275] = "Other",				-- Unbreakable Guard (deflecting attacks and spells from the front)
	[333710] = "Root",				-- Grasping Hands
	[342691] = "Root",				-- Grasping Hands
	[319567] = "Root",				-- Grasping Hands
	[333301] = "CC",				-- Curse of Desolation
	[323750] = "CC",				-- Vile Gas
	[330592] = "CC",				-- Vile Eruption
	[330608] = "CC",				-- Vile Eruption
	[323831] = "CC",				-- Death Grasp
	[321768] = "CC",				-- On the Hook
	[319531] = "CC",				-- Draw Soul
	[332708] = "CC",				-- Ground Smash
	[330562] = "CC",				-- Demoralizing Shout (damage done reduced by 50%)
	[320679] = "Snare",				-- Charge
	[342103] = "Snare",				-- Rancid Bile
	[330810] = "Snare",				-- Bind Soul
	------------------------
	-- Torghast, Tower of the Damned
	[348131] = "CC",				-- Soul Emanation
	[314702] = "CC",				-- Twisted Hellchoker
	[307612] = "CC",				-- Darkening Canopy
	[329454] = "CC",				-- Ogundimu's Fist
	[314691] = "CC",				-- Darkhelm of Nuren
	[333599] = "CC",				-- Pridebreaker's Anvil
	[312902] = "CC",				-- Volatile Augury
	[331917] = "CC",				-- Force Pull
	[332531] = "CC",				-- Ancient Drake Breath
	[332544] = "CC",				-- Imprison
	[314590] = "CC",				-- Big Clapper
	[333762] = "CC",				-- The Hunt
	[330858] = "CC",				-- Creeping Freeze
	[321395] = "CC",				-- Polymorph: Mawrat
	[302583] = "CC",				-- Polymorph
	[321134] = "CC",				-- Polymorph
	[334392] = "CC",				-- Polymorph
	[329398] = "CC",				-- Pandemonium
	[305005] = "CC",				-- Incomprehensible Glory
	[345524] = "CC",				-- Mad Wizard's Confusion
	[333767] = "CC",				-- Distracting Charges
	[353104] = "CC",				-- Briefcase Bash
	[353124] = "CC",				-- Spirit Shock
	[351621] = "CC",				-- Impaling Spikes
	[353328] = "CC",				-- Soul Ruin
	[297722] = "Silence",			-- Subjugator's Manacles
	[342375] = "Silence",			-- Tormenting Backlash
	[342414] = "Silence",			-- Cracked Mindscreecher
	[295089] = "Silence",			-- Ultimate Detainment
	[332547] = "Disarm",			-- Animate Armaments
	[337097] = "Root",				-- Grasping Tendrils
	[331362] = "Root",				-- Hateful Shard-Ring
	[342373] = "Root",				-- Fae Tendrils
	[333561] = "Root",				-- Nightmare Tendrils
	[321224] = "Root",				-- Rapid Contagion
	[332205] = "Other",				-- Smoking Shard of Teleportation
	[348403] = "Other",				-- Smoking Shard of Teleportation
	[315312] = "Other",				-- Icy Heartcrust
	[331188] = "Other",				-- Cadaverous Cleats
	[348662] = "Other",				-- Cadaverous Cleats
	[347983] = "Other",				-- Stoneflesh Figurine
	[338065] = "Other",				-- Stoneflesh Figurine
	[353573] = "Other",				-- Carrion Swarm (healing received reduced by 75%)
	[333920] = "ImmuneSpell",		-- Cloak of Shadows
	[332831] = "ImmuneSpell",		-- Anti-Magic Zone
	[329267] = "ImmuneSpell",		-- Spell Reflection
	[348722] = "Immune",			-- Ever-Tumbling Stone
	[335103] = "Immune",			-- Divine Shield
	[295963] = "Immune",			-- Crumbling Aegis
	[308204] = "Immune",			-- Crumbling Aegis
	[331356] = "Immune",			-- Craven Strategem
	[323220] = "Immune",			-- Shield of Unending Fury
	[350931] = "Immune",			-- Phantasmic Ward
	[350180] = "Immune",			-- Escape!
	[334532] = "Immune",			-- Shield of Laguas
	[331464] = "Immune",			-- Fogged Crystal (not immune, damage taken reduced by 90%)
	[341622] = "Immune",			-- Phase Shift (not immune, damage taken reduced by 90%)
	[353652] = "Immune",			-- Insect Swarm (not immune, damage taken reduced by 75%)
	[356533] = "Immune",			-- Dread Protection (not immune, damage taken reduced by 50%)
	[354586] = "Immune",			-- Ceremony of Hatred (not immune, damage taken reduced by 99%)
	[352016] = "Immune",			-- Soul Tormentor (not immune, damage taken reduced by 99%)
	[342783] = "ImmunePhysical",	-- Crystallized Dreams
	[322136] = "Snare",				-- Dissolving Vial
	[324501] = "Snare",				-- Chilling Touch
	[296146] = "Snare",				-- Know Mortality
	[304993] = "Snare",				-- Deep Burns
	[342758] = "Snare",				-- Clinging Fog
	[332165] = "CC",				-- Fearsome Shriek
	[329930] = "CC",				-- Terrifying Screech
	[334575] = "CC",				-- Earthen Crush
	[334562] = "CC",				-- Suppress
	[295985] = "CC",				-- Ground Crush
	[330458] = "CC",				-- Shockwave
	[327461] = "CC",				-- Meat Hook
	[294173] = "CC",				-- Hulking Charge
	[297018] = "CC",				-- Fearsome Howl
	[330438] = "CC",				-- Fearsome Howl
	[298844] = "CC",				-- Fearsome Howl
	[320600] = "CC",				-- Fearsome Howl
	[350958] = "CC",				-- Visage of Lethality
	[341140] = "CC",				-- Writhing Shadow-Tendrils
	[348911] = "CC",				-- Frigid Wildseed
	[348267] = "CC",				-- Distracting Charges
	[170751] = "CC",				-- Crushing Shadows
	[329608] = "CC",				-- Terrifying Roar
	[242391] = "CC",				-- Terror
	[305003] = "CC",				-- Shadowed Iris (chance to hit reduced by 50%)
	[334568] = "CC",				-- Call of Thunder
	[312324] = "CC",				-- Coalesce Anima
	[312609] = "CC",				-- Coalesce Anima
	[312410] = "CC",				-- Leaping Maul
	[305009] = "CC",				-- Hematoma
	[341976] = "CC",				-- Soulburst Charm
	[328511] = "CC",				-- Slumberweb
	[353121] = "CC",				-- Thanatophobia
	[356663] = "CC",				-- Refractive Burst
	[351931] = "CC",				-- Pain Bringer
	[356508] = "CC",				-- Sweet Dreams
	[356346] = "CC",				-- Timebreaker's Paradox
	[301952] = "Silence",			-- Silencing Calm
	[329903] = "Silence",			-- Silence
	[312419] = "Silence",			-- Soul-Devouring Howl
	[329319] = "Disarm",			-- Disarm
	[304949] = "Root",				-- Falling Strike
	[295945] = "Root",				-- Rat Traps
	[304831] = "Root",				-- Chains of Ice
	[296023] = "Root",				-- Lockdown
	[259220] = "Root",				-- Barbed Net
	[296454] = "Immune",			-- Vanish to Nothing
	[337622] = "Immune",			-- Unstable Form (not immune, damage taken reduced by 99%)
	[167012] = "Immune",			-- Incorporeal (not immune, damage taken reduced by 99%)
	[336556] = "Immune",			-- Concealing Fog (not immune, damage taken reduced by 50%)
	[294517] = "Immune",			-- Phasing Roar (not immune, damage taken reduced by 80%)
	[339006] = "ImmunePhysical",	-- Ephemeral Body (not immune, physical damage taken reduced by 75%)
	[297166] = "ImmunePhysical",	-- Armor Plating (not immune, physical damage taken reduced by 50%)
	[339010] = "ImmuneSpell",		-- Resonating Body (not immune, magic damage taken reduced by 75%)
	[302543] = "ImmuneSpell",		-- Glimmering Barrier (not immune, magic damage taken reduced by 50%)
	[351090] = "Snare",				-- Persecute
	[321633] = "Snare",				-- Frost Strike
	[330479] = "Snare",				-- Gunk
	[327471] = "Snare",				-- Noxious Cloud
	[297292] = "Snare",				-- Thorned Shell
	[295991] = "Snare",				-- Lumbering Might
	[295929] = "Snare",				-- Rats!
	[302552] = "Snare",				-- Sedative Dust
	[330646] = "Snare",				-- Cloying Juices
	[304093] = "Snare",				-- Mass Debilitate
	[335685] = "Snare",				-- Wracking Torment
	[292910] = "Snare",				-- Shackles
	[292942] = "Snare",				-- Iron Shackles
	[295001] = "Snare",				-- Whirlwind
	[329905] = "Snare",				-- Mass Slow
	[329862] = "Snare",				-- Ghastly Wail
	[329325] = "Snare",				-- Cripple
	[185493] = "Snare",				-- Cripple
	[329326] = "Snare",				-- Dark Binding
	[351281] = "Snare",				-- Torn Soul
	------------------------
	---- PVE BFA
	------------------------
	-- Ny'alotha, The Waking City Raid
	-- -- Trash
	[313949] = "Immune",			-- Ny'alotha Gateway
	[315071] = "Immune",			-- Ny'alotha Gateway
	[315080] = "Immune",			-- Ny'alotha Gateway
	[315214] = "Immune",			-- Ny'alotha Gateway
	[311052] = "Immune",			-- Steadfast Defense (not immune, 75% damage reduction)
	[311073] = "Immune",			-- Steadfast Defense (not immune, 75% damage reduction)
	[310830] = "CC",				-- Disorienting Strike
	[315013] = "Silence",			-- Bursting Shadows
	[316951] = "CC",				-- Voracious Charge
	[311552] = "CC",				-- Fear the Void
	[311041] = "CC",				-- Drive to Madness
	[318785] = "CC",				-- Corrupted Touch
	[318880] = "Root",				-- Corrupted Touch
	[316143] = "Snare",				-- Thunder Clap
	-- -- Wrathion
	[314347] = "CC",				-- Noxious Choke
	[313175] = "Immune",			-- Hardened Core
	[306995] = "Immune",			-- Smoke and Mirrors
	-- -- Maut
	[307586] = "CC",				-- Devoured Abyss
	[309853] = "Silence",			-- Devoured Abyss
	-- -- The Prophet Skitra
	[313208] = "Immune",			-- Intangible Illusion
	-- -- Dark Inquisitor
	[314035] = "Immune",			-- Void Shield
	[316211] = "CC",				-- Terror Wave
	[305575] = "Snare",				-- Ritual Field
	--[309569] = "CC",				-- Voidwoken (damage dealt reduced 99%)
	--[312406] = "CC",				-- Voidwoken (damage dealt reduced 99%)
	-- -- The Hivemind
	[307202] = "Immune",			-- Shadow Veil (damage taken reduced by 99%)
	[308873] = "CC",				-- Corrosive Venom
	[313460] = "Other",				-- Nullification (healing received reduced by 100%)
	-- -- Shad'har the Insatiable
	[306928] = "CC",				-- Umbral Breath
	[306930] = "Other",				-- Entropic Breath (healing received reduced by 50%)
	-- -- Drest'agath
	[310246] = "CC",				-- Void Grip
	[310361] = "CC",				-- Unleashed Insanity
	[310552] = "Snare",				-- Mind Flay
	-- -- Il'gynoth
	[311367] = "CC",				-- Touch of the Corruptor
	[310322] = "CC",				-- Morass of Corruption
	-- -- Vexiona
	[307645] = "CC",				-- Heart of Darkness
	[315932] = "CC",				-- Brutal Smash
	[307729] = "CC",				-- Fanatical Ascension
	[307075] = "CC",				-- Power of the Chosen
	[316745] = "CC",				-- Power of the Chosen
	[310323] = "Snare",				-- Desolation
	-- -- Ra Den
	[315207] = "CC",				-- Stunned
	[306637] = "Silence",			-- Unstable Void Burst
	[306645] = "Silence",			-- Consuming Void
	[309777] = "Other",				-- Void Defilement (all healing taken reduced 50%)
	-- -- Carapace of N'Zoth
	[307832] = "CC",				-- Servant of N'Zoth
	[312158] = "Immune",			-- Ashjra'kamas, Shroud of Resolve
	[317165] = "CC",				-- Regenerative Expulsion
	[306978] = "CC",				-- Madness Bomb
	[306985] = "CC",				-- Insanity Bomb
	[307071] = "Immune",			-- Synthesis
	[307061] = "Snare",				-- Mycelial Growth
	[317164] = "Immune",			-- Reactive Mass
	-- -- N'Zoth
	[308996] = "CC",				-- Servant of N'Zoth
	[310073] = "CC",				-- Mindgrasp
	[311392] = "CC",				-- Mindgrasp
	[314843] = "CC",				-- Corruptor's Gift
	[313793] = "CC",				-- Flames of Insanity
	[319353] = "CC",				-- Flames of Insanity
	[315675] = "CC",				-- Shattered Ego
	[315672] = "CC",				-- Shattered Ego
	[318976] = "CC",				-- Stupefying Glare
	[312155] = "CC",				-- Shattered Ego
	[310134] = "Immune",			-- Manifest Madness (99% damage reduction)
	------------------------
	-- The Eternal Palace Raid
	-- -- Trash
	[303747] = "CC",				-- Ice Tomb
	[303396] = "Root",				-- Barbed Net
	[304189] = "Snare",				-- Frostbolt
	[303316] = "Snare",				-- Hindering Resonance
	-- -- Abyssal Commander Sivara
	[295807] = "CC",				-- Frozen
	[295850] = "CC",				-- Delirious
	[295704] = "CC",				-- Frost Bolt
	[295705] = "CC",				-- Toxic Bolt
	[302004] = "CC",				-- Lockdown
	[300882] = "Root",				-- Inversion Sickness
	[300883] = "Root",				-- Inversion Sickness
	-- -- Radiance of Azshara
	[295916] = "Immune",			-- Ancient Tempest (damage taken reduced 99%)
	[296746] = "CC",				-- Arcane Bomb
	[304027] = "CC",				-- Arcane Bomb
	[296389] = "Immune",			-- Swirling Winds (damage taken reduced 99%)
	-- -- Lady Ashvane
	[297333] = "CC",				-- Briny Bubble
	[302992] = "CC",				-- Briny Bubble
	-- -- Orgozoa
	[305347] = "Immune",			-- Massive Incubator (damage taken reduced 90%)
	[295822] = "CC",				-- Conductive Pulse
	[305603] = "CC",				-- Electro Shock
	[304280] = "Immune",			-- Chaotic Growth (damage taken reduced 50%)
	[296914] = "Immune",			-- Chaotic Growth (damage taken reduced 50%)
	-- -- The Queen's Court
	[296704] = "Immune",			-- Separation of Power (damage taken reduced 99%)
	[296716] = "Immune",			-- Separation of Power (damage taken reduced 99%)
	[304410] = "Silence",			-- Repeat Performance
	[301832] = "CC",				-- Fanatical Zeal
	-- -- Za'qul, Harbinger of Ny'alotha
	[300133] = "CC",				-- Snapped
	[294545] = "CC",				-- Portal of Madness
	[292963] = "CC",				-- Dread
	[302503] = "CC",				-- Dread
	[303619] = "CC",				-- Dread
	[295327] = "CC",				-- Shattered Psyche
	[303832] = "CC",				-- Tentacle Slam
	[301117] = "Immune",			-- Dark Shield
	[296084] = "CC",				-- Mind Fracture
	[299705] = "CC",				-- Dark Passage
	[299591] = "Immune",			-- Shroud of Fear
	[303543] = "CC",				-- Dread Scream
	[296018] = "CC",				-- Manic Dread
	[302504] = "CC",				-- Manic Dread
	-- -- Queen Azshara
	[304759] = "CC",				-- Queen's Disgust
	[304763] = "CC",				-- Queen's Disgust
	[304760] = "Disarm",			-- Queen's Disgust
	[304770] = "Snare",				-- Queen's Disgust
	[304768] = "Snare",				-- Queen's Disgust
	[304757] = "Snare",				-- Queen's Disgust
	[298018] = "CC",				-- Frozen
	[299094] = "CC",				-- Beckon
	[302141] = "CC",				-- Beckon
	[303797] = "CC",				-- Beckon
	[303799] = "CC",				-- Beckon
	[303802] = "CC",				-- Army of Azshara
	[300001] = "CC",				-- Devotion
	[303825] = "CC",				-- Crushing Depths
	[300620] = "Immune",			-- Crystalline Shield
	[303706] = "CC",				-- Song of Azshara
	------------------------
	-- Crucible of Storms Raid
	-- -- Trash
	[293957] = "CC",				-- Maddening Gaze
	[295312] = "Immune",			-- Shadow Siphon
	[286754] = "CC",				-- Storm of Annihilation (damage done decreased by 50%)
	-- -- The Restless Cabal
	[282589] = "CC",				-- Cerebral Assault
	[285154] = "CC",				-- Cerebral Assault
	[282517] = "CC",				-- Terrifying Echo
	[287876] = "CC",				-- Enveloping Darkness (healing and damage done reduced by 99%)
	[282743] = "CC",				-- Storm of Annihilation (damage done decreased by 50%)
	-- -- Uu'nat
	[285562] = "CC",				-- Unknowable Terror
	[287693] = "Immune",			-- Sightless Bond (damage taken reduced by 99%)
	[286310] = "Immune",			-- Void Shield (damage taken reduced by 99%)
	[284601] = "CC",				-- Storm of Annihilation (damage done decreased by 50%)
	------------------------
	-- Battle of Dazar'alor Raid
	-- -- Trash
	[289471] = "CC",				-- Terrifying Roar
	[286740] = "CC",				-- Light's Fury
	[289645] = "CC",				-- Polymorph
	[287325] = "CC",				-- Comet Storm
	[289772] = "CC",				-- Impale
	[289937] = "CC",				-- Thundering Slam
	[288842] = "CC",				-- Throw Goods
	[289419] = "CC",				-- Mass Hex
	[288815] = "CC",				-- Breath of Fire
	[287456] = "Root",				-- Frost Nova
	[289742] = "Immune",			-- Defense Field (damage taken reduced 75%)
	[287295] = "Snare",				-- Chilled
	-- -- Champion of the Light
	[288294] = "Immune",			-- Divine Protection (damage taken reduced 99%)
	[283651] = "CC",				-- Blinding Faith
	-- -- Grong
	[289406] = "CC",				-- Bestial Throw
	[289412] = "CC",				-- Bestial Impact
	[285998] = "CC",				-- Ferocious Roar
	[290575] = "CC",				-- Ferocious Roar
	-- -- Opulence
	[283609] = "CC",				-- Crush
	[283610] = "CC",				-- Crush
	-- -- Conclave of the Chosen
	[282079] = "Immune",			-- Loa's Pact (damage taken reduced 90%)
	[282135] = "CC",				-- Crawling Hex
	[290573] = "CC",				-- Crawling Hex
	[285879] = "CC",				-- Mind Wipe
	[265495] = "CC",				-- Static Orb
	[286838] = "CC",				-- Static Orb
	[282447] = "CC",				-- Kimbul's Wrath
	-- -- King Rastakhan
	[284995] = "CC",				-- Zombie Dust
	[284376] = "CC",				-- Death's Presence
	[284377] = "Immune",			-- Unliving
	-- -- High Tinker Mekkatorque
	[287167] = "CC",				-- Discombobulation
	[284214] = "CC",				-- Trample
	[289138] = "CC",				-- Trample
	[289644] = "Immune",			-- Spark Shield (damage taken reduced 99%)
	[282401] = "Immune",			-- Gnomish Force Shield (damage taken reduced 99%)
	[289248] = "Immune",			-- P.L.O.T Armor (damage taken reduced 99%)
	[282408] = "CC",				-- Spark Pulse (stun)
	[289232] = "CC",				-- Spark Pulse (hit chance reduced 100%)
	[289226] = "CC",				-- Spark Pulse (pacify)
	[286480] = "CC",				-- Anti-Tampering Shock
	[286516] = "CC",				-- Anti-Tampering Shock
	-- -- Stormwall Blockade
	[284121] = "Silence",			-- Thunderous Boom
	[286495] = "CC",				-- Tempting Song
	[284369] = "Snare",				-- Sea Storm
	-- -- Lady Jaina Proudmoore
	[287490] = "CC",				-- Frozen Solid
	[289963] = "CC",				-- Frozen Solid
	[285704] = "CC",				-- Frozen Solid
	[287199] = "Root",				-- Ring of Ice
	[287626] = "Root",				-- Grasp of Frost
	[288412] = "Root",				-- Hand of Frost
	[288434] = "Root",				-- Hand of Frost
	[289219] = "Root",				-- Frost Nova
	[289855] = "CC",				-- Frozen Siege
	[275809] = "CC",				-- Flash Freeze
	[271527] = "Immune",			-- Ice Block
	[287322] = "Immune",			-- Ice Block
	[282841] = "Immune",			-- Arctic Armor
	[287282] = "Immune",			-- Arctic Armor (damage taken reduced 90%)
	[287418] = "Immune",			-- Arctic Armor (damage taken reduced 90%)
	[288219] = "Immune",			-- Refractive Ice (damage taken reduced 99%)
	------------------------
	-- Uldir Raid
	-- -- Trash
	[277498] = "CC",				-- Mind Slave
	[277358] = "CC",				-- Mind Flay
	[278890] = "CC",				-- Violent Hemorrhage
	[278967] = "CC",				-- Winged Charge
	[260275] = "CC",				-- Rumbling Stomp
	[262375] = "CC",				-- Bellowing Roar
	-- -- Taloc
	[271965] = "Immune",			-- Powered Down (damage taken reduced 99%)
	-- -- Fetid Devourer
	[277800] = "CC",				-- Swoop
	-- -- Zek'voz, Herald of N'zoth
	[265646] = "CC",				-- Will of the Corruptor
	[270589] = "CC",				-- Void Wail
	[270620] = "CC",				-- Psionic Blast
	-- -- Vectis
	[265212] = "CC",				-- Gestate
	-- -- Zul, Reborn
	[273434] = "CC",				-- Pit of Despair
	[269965] = "CC",				-- Pit of Despair
	[274271] = "CC",				-- Deathwish
	-- -- Mythrax the Unraveler
	[272407] = "CC",				-- Oblivion Sphere
	[284944] = "CC",				-- Oblivion Sphere
	[274230] = "Immune",			-- Oblivion Veil (damage taken reduced 99%)
	[276900] = "Immune",			-- Critical Mass (damage taken reduced 80%)
	-- -- G'huun
	[269691] = "CC",				-- Mind Thrall
	[273401] = "CC",				-- Mind Thrall
	[263504] = "CC",				-- Reorigination Blast
	[273251] = "CC",				-- Reorigination Blast
	[267700] = "CC",				-- Gaze of G'huun
	[255767] = "CC",				-- Grasp of G'huun
	[263217] = "Immune",			-- Blood Shield (not immune, but heals 5% of maximum health every 0.5 sec)
	[275129] = "Immune",			-- Corpulent Mass (damage taken reduced by 99%)
	[268174] = "Root",				-- Tendrils of Corruption
	[263235] = "Root",				-- Blood Feast
	[263321] = "Snare",				-- Undulating Mass
	[270287] = "Snare",				-- Blighted Ground
	------------------------
	-- BfA World Bosses
	-- -- T'zane
	[261552] = "CC",				-- Terror Wail
	-- -- Hailstone Construct
	[274895] = "CC",				-- Freezing Tempest
	-- -- Warbringer Yenajz
	[274904] = "CC",				-- Reality Tear
	-- -- The Lion's Roar and Doom's Howl
	[271778] = "Snare",				-- Reckless Charge
	-- -- Ivus the Decayed
	[287554] = "Immune",			-- Petrify
	[282615] = "Immune",			-- Petrify
	-- -- Grand Empress Shek'zara
	[314306] = "CC",				-- Song of the Empress
	[314332] = "Immune",			-- Sound Barrier (damage taken reduced 70%)
	------------------------
	-- Horrific Visions of N'zoth
	[317865] = "CC",				-- Emergency Cranial Defibrillation
	[304816] = "CC",				-- Emergency Cranial Defibrillation
	[291782] = "CC",				-- Controlled by the Vision
	[311558] = "ImmuneSpell",		-- Volatile Intent
	[306965] = "CC",				-- Shadow's Grasp
	[316510] = "CC",				-- Split Personality
	[306545] = "CC",				-- Haunting Shadows
	[288545] = "CC",				-- Fear	(Madness: Terrified)
	[292240] = "Other",				-- Entomophobia
	[306583] = "Root",				-- Leaden Foot
	[288560] = "Snare",				-- Slowed
	[298514] = "CC",				-- Aqiri Mind Toxin
	[313639] = "CC",				-- Hex
	[305155] = "Snare",				-- Rupture
	[296510] = "Snare",				-- Creepy Crawler
	[78622]  = "CC",				-- Heroic Leap
	[314723] = "CC",				-- War Stomp
	[304969] = "CC",				-- Void Torrent
	[298033] = "CC",				-- Touch of the Abyss
	[299243] = "CC",				-- Touch of the Abyss
	[300530] = "CC",				-- Mind Carver
	[304634] = "CC",				-- Despair
	[297574] = "CC",				-- Hopelessness
	[283408] = "Snare",				-- Charge
	[304350] = "CC",				-- Mind Trap
	[299870] = "CC",				-- Mind Trap
	[306828] = "CC",				-- Defiled Ground
	[306726] = "CC",				-- Defiled Ground
	[297746] = "CC",				-- Seismic Slam
	[306646] = "CC",				-- Ring of Chaos
	[305378] = "CC",				-- Horrifying Shout
	[298630] = "CC",				-- Shockwave
	[297958] = "Snare",				-- Punishing Throw
	[314748] = "Snare",				-- Slow
	[298701] = "CC",				-- Chains of Servitude
	[298770] = "CC",				-- Chains of Servitude
	[309648] = "CC",				-- Tainted Polymorph
	[296674] = "Silence",			-- Lurking Appendage
	[308172] = "Snare",				-- Mind Flay
	[308375] = "CC",				-- Psychic Scream
	[306748] = "CC",				-- Psychic Scream
	[309882] = "CC",				-- Brutal Smash
	[298584] = "Immune",			-- Repel (not immune, 75% damage reduction)
	[312017] = "Immune",			-- Shrouded (not immune, 90% damage reduction)
	[308481] = "CC",				-- Rift Strike
	[308508] = "CC",				-- Rift Strike
	[308575] = "Immune",			-- Shadow Shift	(not immune, 75% damage reduction)
	[311373] = "Snare",				-- Numbing Poison
	[283655] = "CC",				-- Cheap Shot
	[283106] = "ImmuneSpell",		-- Cloak of Shadows
	[283661] = "CC",				-- Kidney Shot
	[315254] = "Snare",				-- Harsh Lesson
	[315391] = "Snare",				-- Gladiator's Spite
	[311042] = "CC",				-- Evacuation Protocol
	[306552] = "CC",				-- Evacuation Protocol
	[306465] = "CC",				-- Evacuation Protocol
	[314916] = "CC",				-- Evacuation Protocol
	[302460] = "CC",				-- Evacuation Protocol
	[297286] = "CC",				-- Evacuation Protocol
	[311036] = "CC",				-- Evacuation Protocol
	[302493] = "CC",				-- Evacuation Protocol
	[311020] = "CC",				-- Evacuation Protocol
	[308654] = "Immune",			-- Shield Craggle (not immune, 90% damage reduction)
	------------------------
	-- Visions of N'zoth Assaults (Uldum, Vale of Eternal Blossoms and Misc)
	[315818] = "CC",				-- Burning
	[250490] = "CC",				-- Animated Strike
	[317277] = "CC",				-- Storm Bolt
	[316508] = "CC",				-- Thunderous Charge
	[296820] = "CC",				-- Invoke Niuzao
	[308969] = "CC",				-- Dusted
	[166139] = "CC",				-- Blinding Radiance
	[308890] = "CC",				-- Shockwave
	[314193] = "CC",				-- Massive Shockwave
	[314191] = "CC",				-- Massive Shockwave
	[314880] = "CC",				-- Wave of Hysteria
	[312678] = "CC",				-- Insanity
	[312666] = "Other",				-- Soulbreak
	[314796] = "CC",				-- Bursting Darkness
	[157176] = "CC",				-- Grip of the Void
	[309398] = "CC",				-- Blinding Radiance
	[316997] = "CC",				-- Blinding Radiance
	[315892] = "Silence",			-- Void of Silence
	[314205] = "CC",				-- Maddening Gaze
	[314614] = "CC",				-- Fear of the Void
	[265721] = "Root",				-- Web Spray
	[93585]  = "CC",				-- Serum of Torment
	[316093] = "CC",				-- Terrifying Shriek
	[314458] = "ImmuneSpell",		-- Magnetic Field
	[315829] = "CC",				-- Evolution
	[314077] = "CC",				-- Psychic Assault
	[86699]  = "CC",				-- Shockwave
	[88846]  = "CC",				-- Shockwave
	[309696] = "CC",				-- Soul Wipe
	[316353] = "CC",				-- Shield Bash
	[310271] = "CC",				-- Bewildering Gaze
	[242085] = "CC",				-- Disoriented
	[242084] = "CC",				-- Fear
	[242088] = "CC",				-- Polymorph
	[242090] = "CC",				-- Sleep
	[296661] = "CC",				-- Stomp
	[306875] = "CC",				-- Electrostatic Burst
	[308886] = "Root",				-- Grasp of the Stonelord
	[313751] = "Snare",				-- Amber Burst
	[313934] = "Immune",			-- Sticky Shield
	[310239] = "CC",				-- Terror Gasp
	[81210]  = "Root",				-- Net
	[200434] = "CC",				-- Petrified!
	[309709] = "CC",				-- Petrified
	[312248] = "CC",				-- Amber Hibernation
	[305141] = "Immune",			-- Azerite-Hardened Carapace
	[317490] = "Snare",				-- Mind Flay
	[97154]  = "Snare",				-- Concussive Shot
	[126339] = "CC",				-- Shield Slam
	[126580] = "CC",				-- Crippling Blow
	[177578] = "CC",				-- Paralysis
	[314591] = "CC",				-- Flesh to Stone
	[314382] = "Silence",			-- Silence the Masses
	[312884] = "CC",				-- Heaving Blow
	[270444] = "Other",				-- Harden
	[309463] = "CC",				-- Crystalline
	[309889] = "Snare",				-- Grasp of N'Zoth
	[309411] = "Immune",			-- Gift of Stone
	[307327] = "Immune",			-- Expel Anima
	[312933] = "Immune",			-- Void's Embrace
	[306791] = "Immune",			-- Unexpected Results (not immune, 75% damage reduction)
	[307234] = "CC",				-- Disciple of N'Zoth
	[292982] = "CC",				-- Disciple of N'Zoth
	[307786] = "CC",				-- Spirit Bind
	[154793] = "Root",				-- Spirit Bind
	[311522] = "CC",				-- Nightmarish Stare
	[306222] = "CC",				-- Critical Failure
	[304241] = "Root",				-- Distorting Reality
	[316940] = "CC",				-- Assassin Spawn
	[302338] = "CC",				-- Ice Trap
	[302591] = "CC",				-- Ice Trap
	[296810] = "Immune",			-- Fear of Death
	[313275] = "CC",				-- Cowardice
	[292451] = "CC",				-- Binding Shot
	[306769] = "CC",				-- Mutilate
	[302232] = "CC",				-- Crushing Charge
	[314301] = "CC",				-- Doom
	[299269] = "CC",				-- Eye Beam
	[314118] = "CC",				-- Glimpse of Infinity
	[306282] = "CC",				-- Knockdown
	[303403] = "CC",				-- Sap
	[296057] = "CC",				-- Seeker's Song
	[299485] = "CC",				-- Surging Shadows
	[311635] = "CC",				-- Throw Hefty Coin Sack
	[303193] = "CC",				-- Trample
	[313719] = "CC",				-- X-52 Personnel Armor: Overload
	[313311] = "CC",				-- Underhanded Punch
	[315850] = "CC",				-- Vomit
	------------------------
	-- Battle for Darkshore
	[314516] = "CC",				-- Savage Charge
	[314519] = "CC",				-- Ravage
	[314884] = "CC",				-- Frozen Solid
	[7964]   = "CC",				-- Smoke Bomb
	[31274]  = "CC",				-- Knockdown
	[283921] = "CC",				-- Lancer's Charge
	[285708] = "CC",				-- Frozen Solid
	[288344] = "CC",				-- Massive Stomp
	[288339] = "CC",				-- Massive Stomp
	[286397] = "CC",				-- Massive Stomp
	[282676] = "CC",				-- Massive Stomp
	[212566] = "CC",				-- Terrifying Screech
	[283880] = "CC",				-- DRILL KILL
	[284949] = "CC",				-- Warden's Prison
	[22127]  = "Root",				-- Entangling Roots
	[31290]  = "Root",				-- Net
	[286404] = "Root",				-- Grasping Bramble
	[290013] = "Root",				-- Volatile Bulb
	[311761] = "Root",				-- Entangling Roots
	[311634] = "Root",				-- Entangling Roots
	[22356]  = "Snare",				-- Slow
	[284221] = "Snare",				-- Crippling Gash
	[194584] = "Snare",				-- Crippling Slash
	[284737] = "Snare",				-- Toxic Strike
	[289073] = "Snare",				-- Terrifying Screech
	[286510] = "Snare",				-- Nature's Force
	------------------------
	-- Battle for Stromgarde
	[6524]   = "CC",				-- Ground Tremor
	[97933]  = "CC",				-- Intimidating Shout
	[273867] = "CC",				-- Intimidating Shout
	[262007] = "CC",				-- Polymorph
	[261488] = "CC",				-- Charge
	[264942] = "CC",				-- Scatter Shot
	[258186] = "CC", 				-- Crushing Cleave
	[270411] = "CC",				-- Earthshatter
	[259833] = "CC",				-- Heroic Leap
	[259867] = "CC",				-- Storm Bolt
	[272856] = "CC",				-- Hex Bomb
	[266918] = "CC",				-- Fear
	[262362] = "CC",				-- Hex
	[253731] = "CC",				-- Massive Stomp
	[269674] = "CC",				-- Shattering Stomp
	[263665] = "CC",				-- Conflagration
	[210131] = "CC",				-- Trampling Charge
	[745]    = "Root",				-- Web
	[269680] = "Root",				-- Entanglement
	[262610] = "Root",				-- Weighted Net
	[20822]  = "Snare",				-- Frostbolt
	[141619] = "Snare",				-- Frostbolt
	[183081] = "Snare",				-- Frostbolt
	[266985] = "Snare",				-- Oil Slick
	[271001] = "Snare",				-- Poisoned Axe
	[273665] = "Snare",				-- Seismic Disturbance
	[278190] = "Snare",				-- Debilitating Infection
	[270089] = "Snare",				-- Frostbolt Volley
	[262538] = "Snare",				-- Thunder Clap
	[259850] = "Snare",				-- Reverberating Clap
	------------------------
	-- BfA Island Expeditions
	[8377]   = "Root",				-- Earthgrab
	[270399] = "Root",				-- Unleashed Roots
	[270196] = "Root",				-- Chains of Light
	[267024] = "Root",				-- Stranglevines
	[236467] = "Root",				-- Pearlescent Clam
	[267025] = "Root",				-- Animal Trap
	[276807] = "Root",				-- Crude Net
	[276806] = "Root",				-- Stoutthistle
	[255311] = "Root",				-- Hurl Spear
	[8208]   = "CC",				-- Backhand
	[12461]  = "CC",				-- Backhand
	[276991] = "CC",				-- Backhand
	[280061] = "CC",				-- Brainsmasher Brew
	[280062] = "CC",				-- Unluckydo
	[267029] = "CC",				-- Glowing Seed
	[276808] = "CC",				-- Heavy Boulder
	[267028] = "CC",				-- Bright Lantern
	[276809] = "CC",				-- Crude Spear
	[276804] = "CC",				-- Crude Boomerang
	[267030] = "CC",				-- Heavy Crate
	[276805] = "CC",				-- Gloomspore Shroom
	[245638] = "CC",				-- Thick Shell
	[267026] = "CC",				-- Giant Flower
	[243576] = "CC",				-- Sticky Starfish
	[278818] = "CC",				-- Amber Entrapment
	[268345] = "CC",				-- Azerite Suppression
	[278813] = "CC",				-- Brain Freeze
	[272982] = "CC",				-- Bubble Trap
	[278823] = "CC",				-- Choking Mist
	[268343] = "CC",				-- Crystalline Stasis
	[268341] = "CC",				-- Cyclone
	[273392] = "CC",				-- Drakewing Bonds
	[278817] = "CC",				-- Drowning Waters
	[268337] = "CC",				-- Flash Freeze
	[278914] = "CC",				-- Ghostly Rune Prison
	[278822] = "CC",				-- Heavy Net
	[273612] = "CC",				-- Mental Fog
	[278820] = "CC",				-- Netted
	[278816] = "CC",				-- Paralyzing Pool
	[278811] = "CC",				-- Poisoned Water
	[278821] = "CC",				-- Sand Trap
	[274055] = "CC",				-- Sap
	[273914] = "CC",				-- Shadowy Conflagration
	[279986] = "CC",				-- Shrink Ray
	[278814] = "CC",				-- Sticky Ooze
	[259236] = "CC",				-- Stone Rune Prison
	[290626] = "CC",				-- Debilitating Howl
	[290625] = "CC",				-- Creeping Decay
	[290624] = "CC",				-- Necrotic Paralysis
	[290623] = "CC",				-- Stone Prison
	[245139] = "CC",				-- Petrified
	[274794] = "CC",				-- Hex
	[278808] = "CC",				-- Hex
	[278809] = "CC",				-- Hex
	[275651] = "CC",				-- Charge
	[262470] = "CC",				-- Blast-O-Matic Frag Bomb
	[262906] = "CC",				-- Arcane Charge
	[270460] = "CC",				-- Stone Eruption
	[262500] = "CC",				-- Crushing Charge
	[268203] = "CC",				-- Death Lens
	[244880] = "CC",				-- Charge
	[275087] = "CC",				-- Charge
	[262342] = "CC",				-- Hex
	[257748] = "CC",				-- Blind
	[262147] = "CC",				-- Wild Charge
	[262000] = "CC",				-- Wyvern Sting
	[258822] = "CC",				-- Blinding Peck
	[271227] = "CC",				-- Wildfire
	[244888] = "CC",				-- Bonk
	[273664] = "CC",				-- Crush
	[256600] = "CC",				-- Point Blank Blast
	[270457] = "CC",				-- Slam
	[258371] = "CC",				-- Crystal Gaze
	[266989] = "CC",				-- Swooping Charge
	[258390] = "CC",				-- Petrifying Gaze
	[275990] = "CC",				-- Conflagrating Exhaust
	[277375] = "CC",				-- Sucker Punch
	[278193] = "CC",				-- Crush
	[275671] = "CC",				-- Tremendous Roar
	[270459] = "CC",				-- Earth Blast
	[270461] = "CC",				-- Seismic Force
	[270463] = "CC",				-- Jagged Slash
	[275192] = "CC",				-- Blinding Sand
	[286907] = "CC",				-- Volatile Eruption
	[244988] = "CC",				-- Throw Boulder
	[244893] = "CC",				-- Throw Boulder
	[250505] = "CC",				-- Hysteria
	[285266] = "CC",				-- Asphyxiate
	[285270] = "CC",				-- Leg Sweep
	[275748] = "CC",				-- Paralyzing Fang
	[275997] = "CC",				-- Twilight Nova
	[270264] = "CC",				-- Meteor
	[277161] = "CC",				-- Shockwave
	[290764] = "CC",				-- Dragon Roar
	[286780] = "CC",				-- Terrifying Woof
	[276992] = "CC",				-- Big Foot Kick
	[277111] = "CC",				-- Serum of Torment
	[270248] = "CC",				-- Conflagrate
	[266151] = "CC",				-- Fire Bomb
	[265615] = "CC",				-- Icy Charge
	[186637] = "CC",				-- Grrlmmggr...
	[274758] = "CC",				-- Shrink (damage done reduced by 50%)
	[277118] = "CC",				-- Curse of Impotence (damage done reduced by 75%)
	--[262197] = "Immune",			-- Tenacity of the Pack (unkillable but not immune to damage)
	[264115] = "Immune",			-- Divine Shield
	[277040] = "Immune",			-- Soul of Mist (damage taken reduced 90%)
	[265445] = "Immune",			-- Shell Shield (damage taken reduced 75%)
	[267487] = "ImmunePhysical",	-- Icy Reflection
	[163671] = "Immune",			-- Ethereal
	[294375] = "CC",				-- Spiritflame
	[275154] = "Silence",			-- Silencing Calm
	[265723] = "Root",				-- Web
	[274801] = "Root",				-- Net
	[277115] = "Root",				-- Hooked Net
	[270613] = "Root",				-- Frost Nova
	[265584] = "Root",				-- Frost Nova
	[270705] = "Root",				-- Frozen Wave
	[265583] = "Root",				-- Grasping Claw
	[278176] = "Root",				-- Entangling Roots
	[278181] = "Root",				-- Wrapping Vines
	[275821] = "Root",				-- Earthen Hold
	[197720] = "Root",				-- Elder Charge
	[288473] = "Root",				-- Enslave
	[275052] = "Root",				-- Shocking Reins
	[277496] = "Root",				-- Spear Leap
	[85691]  = "Snare",				-- Piercing Howl
	[270285] = "Snare",				-- Blast Wave
	[277870] = "Snare",				-- Icy Venom
	[277109] = "Snare",				-- Sticky Stomp
	[266974] = "Snare",				-- Frostbolt
	[261962] = "Snare",				-- Brutal Whirlwind
	[258748] = "Snare",				-- Arctic Torrent
	[266286] = "Snare",				-- Tendon Rip
	[270606] = "Snare",				-- Frostbolt
	[294363] = "Snare",				-- Spirit Chains
	[266288] = "Snare",				-- Gnash
	[262465] = "Snare",				-- Bug Zapper
	[267195] = "Snare",				-- Slow
	[275038] = "Snare",				-- Icy Claw
	[274968] = "Snare",				-- Howl
	[273650] = "Snare",				-- Thorn Spray
	[256661] = "Snare",				-- Staggering Roar
	[256851] = "Snare",				-- Vile Spew
	[179021] = "Snare",				-- Slime
	[273124] = "Snare",				-- Lethargic Poison
	[205187] = "Snare",				-- Cripple
	[266158] = "Snare",				-- Frost Bomb
	[263344] = "Snare",				-- Subjugate
	[261095] = "Snare",				-- Vermin Parade
	[245386] = "Other",				-- Darkest Darkness (healing taken reduced by 99%)
	[274972] = "Other",				-- Breath of Darkness (healing taken reduced by 75%)
	------------------------
	-- BfA Mythics
	-- -- Common
	[314483] = "CC",				-- Cascading Terror
	[314411] = "Other",				-- Lingering Doubt (casting speed reduced by 70%)
	[314308] = "Other",				-- Spirit Breaker (damage taken increased by 100%)
	[314392] = "Snare",				-- Vile Corruption
	[314592] = "Snare",				-- Mind Flay
	[314406] = "Snare",				-- Crippling Pestilence
	-- -- Operation: Mechagon
	[297283] = "CC",				-- Cave In
	[294995] = "CC",				-- Cave In
	[298259] = "CC",				-- Gooped
	[298124] = "CC",				-- Gooped
	[298718] = "CC",				-- Mega Taze
	[302681] = "CC",				-- Mega Taze
	[304452] = "CC",				-- Mega Taze
	[296150] = "CC",				-- Vent Blast
	[299994] = "CC",				-- Vent Blast
	[300650] = "CC",				-- Suffocating Smog
	[291974] = "CC",				-- Obnoxious Monologue
	[295130] = "CC",				-- Neutralize Threat
	[283640] = "CC",				-- Rattled
	[282943] = "CC",				-- Piston Smasher
	[285460] = "CC",				-- Discom-BOMB-ulator
	[299572] = "CC",				-- Shrink (damage and healing done reduced by 99%)
	[299707] = "CC",				-- Trample
	[296571] = "Immune",			-- Power Shield (damage taken reduced 99%)
	[295147] = "Immune",			-- Reflective Armor
	[293986] = "Silence",			-- Sonic Pulse
	[303264] = "CC",				-- Anti-Trespassing Field
	[296279] = "CC",				-- Anti-Trespassing Teleport
	[293724] = "Immune",			-- Shield Generator (damage taken reduced 75%)
	[300514] = "Immune",			-- Stoneskin (damage taken reduced 75%)
	[304074] = "Immune",			-- Stoneskin (damage taken reduced 75%)
	[295168] = "CC",				-- Capacitor Discharge
	[295170] = "CC",				-- Capacitor Discharge
	[295182] = "CC",				-- Capacitor Discharge
	[295183] = "CC",				-- Capacitor Discharge
	[300436] = "Root",				-- Grasping Hex
	[299475] = "Snare",				-- B.O.R.K
	[300764] = "Snare",				-- Slimebolt
	[296560] = "Snare",				-- Clinging Static
	[285388] = "Snare",				-- Vent Jets
	[298602] = "Immune",			-- Smoke Cloud (interferes with targeting)
	[300675] = "Other",				-- Toxic Fog
	[296080] = "Other",				-- Haywire
	[300011] = "Immune",			-- Force Shield
	-- -- Atal'Dazar
	[255371] = "CC",				-- Terrifying Visage
	[255041] = "CC",				-- Terrifying Screech
	[252781] = "CC",				-- Unstable Hex
	[279118] = "CC",				-- Unstable Hex
	[252692] = "CC",				-- Waylaying Jab
	[255567] = "CC",				-- Frenzied Charge
	[258653] = "Immune",			-- Bulwark of Juju (90% damage reduction)
	[253721] = "Immune",			-- Bulwark of Juju (90% damage reduction)
	[255971] = "Other",				-- Bad Voodoo
	[255960] = "Other",				-- Bad Voodoo
	[255967] = "Other",				-- Bad Voodoo
	[255968] = "Other",				-- Bad Voodoo
	[255970] = "Other",				-- Bad Voodoo
	[255972] = "Other",				-- Bad Voodoo
	[272618] = "Other",				-- Bad Voodoo
	-- -- Kings' Rest
	[268796] = "CC",				-- Impaling Spear
	[269369] = "CC",				-- Deathly Roar
	[267702] = "CC",				-- Entomb
	[271555] = "CC",				-- Entomb
	[270920] = "CC",				-- Seduction
	[270003] = "CC",				-- Suppression Slam
	[270492] = "CC",				-- Hex
	[276031] = "CC",				-- Pit of Despair
	[267626] = "CC",				-- Dessication (damage done reduced by 50%)
	[270931] = "Snare",				-- Darkshot
	[270499] = "Snare",				-- Frost Shock
	-- -- The MOTHERLODE!!
	[257337] = "CC",				-- Shocking Claw
	[257371] = "CC",				-- Tear Gas
	[275907] = "CC",				-- Tectonic Smash
	[280605] = "CC",				-- Brain Freeze
	[263637] = "CC",				-- Clothesline
	[268797] = "CC",				-- Transmute: Enemy to Goo
	[268846] = "Silence",			-- Echo Blade
	[267367] = "CC",				-- Deactivated
	[278673] = "CC",				-- Red Card
	[278644] = "CC",				-- Slide Tackle
	[257481] = "CC",				-- Fracking Totem
	[269278] = "CC",				-- Panic!
	[260189] = "Immune",			-- Configuration: Drill (damage taken reduced 99%)
	[268704] = "Snare",				-- Furious Quake
	-- -- Shrine of the Storm
	[268027] = "CC",				-- Rising Tides
	[276268] = "CC",				-- Heaving Blow
	[269131] = "CC",				-- Ancient Mindbender
	[268059] = "Root",				-- Anchor of Binding
	[269419] = "Silence",			-- Yawning Gate
	[267956] = "CC",				-- Zap
	[269104] = "CC",				-- Explosive Void
	[268391] = "CC",				-- Mental Assault
	[269289] = "CC",				-- Disciple of the Vol'zith
	[264526] = "Root",				-- Grasp from the Depths
	[276767] = "ImmuneSpell",		-- Consuming Void
	[268375] = "ImmunePhysical",	-- Detect Thoughts
	[267982] = "Immune",			-- Protective Gaze (damage taken reduced 75%)
	[268212] = "Immune",			-- Minor Reinforcing Ward (damage taken reduced 75%)
	[268186] = "Immune",			-- Reinforcing Ward (damage taken reduced 75%)
	[267904] = "Immune",			-- Reinforcing Ward (damage taken reduced 75%)
	[267901] = "Snare",				-- Blessing of Ironsides
	[274631] = "Snare",				-- Lesser Blessing of Ironsides
	[267899] = "Snare",				-- Hindering Cleave
	[268896] = "Snare",				-- Mind Rend
	-- -- Temple of Sethraliss
	[280032] = "CC",				-- Neurotoxin
	[268993] = "CC",				-- Cheap Shot
	[268008] = "CC",				-- Snake Charm
	[263958] = "CC",				-- A Knot of Snakes
	[269970] = "CC",				-- Blinding Sand
	[256333] = "CC",				-- Dust Cloud (0% chance to hit)
	[260792] = "CC",				-- Dust Cloud (0% chance to hit)
	[269670] = "Immune",			-- Empowerment (90% damage reduction)
	[261635] = "Immune",			-- Stoneshield Potion
	[273274] = "Snare",				-- Polarized Field
	[275566] = "Snare",				-- Numb Hands
	-- -- Waycrest Manor
	[265407] = "Silence",			-- Dinner Bell
	[263891] = "CC",				-- Grasping Thorns
	[260900] = "CC",				-- Soul Manipulation
	[260926] = "CC",				-- Soul Manipulation
	[265352] = "CC",				-- Toad Blight
	[264390] = "Silence",			-- Spellbind
	[278468] = "CC",				-- Freezing Trap
	[267907] = "CC",				-- Soul Thorns
	[265346] = "CC",				-- Pallid Glare
	[268202] = "CC",				-- Death Lens
	[261265] = "Immune",			-- Ironbark Shield (99% damage reduction)
	[261266] = "Immune",			-- Runic Ward (99% damage reduction)
	[261264] = "Immune",			-- Soul Armor (99% damage reduction)
	[271590] = "Immune",			-- Soul Armor (99% damage reduction)
	[260923] = "Immune",			-- Soul Manipulation (99% damage reduction)
	[264027] = "Immune",			-- Warding Candles (50% damage reduction)
	[264040] = "Snare",				-- Uprooted Thorns
	[264712] = "Snare",				-- Rotten Expulsion
	[261440] = "Snare",				-- Virulent Pathogen
	-- -- Tol Dagor
	[258058] = "Root",				-- Squeeze
	[259711] = "Root",				-- Lockdown
	[258313] = "CC",				-- Handcuff (Pacified and Silenced)
	[260067] = "CC",				-- Vicious Mauling
	[257791] = "CC",				-- Howling Fear
	[257793] = "CC",				-- Smoke Powder
	[257119] = "CC",				-- Sand Trap
	[256474] = "CC",				-- Heartstopper Venom
	[258128] = "CC",				-- Debilitating Shout (damage done reduced by 50%)
	[258317] = "ImmuneSpell",		-- Riot Shield (-75% spell damage and redirect spells to the caster)
	[258153] = "Immune",			-- Watery Dome (75% damage redictopm)
	[265271] = "Snare",				-- Sewer Slime
	[257777] = "Snare",				-- Crippling Shiv
	[259188] = "Snare",				-- Heavily Armed
	-- -- Freehold
	[274516] = "CC",				-- Slippery Suds
	[257949] = "CC",				-- Slippery
	[258875] = "CC",				-- Blackout Barrel
	[274400] = "CC",				-- Duelist Dash
	[274389] = "Root",				-- Rat Traps
	[276061] = "CC",				-- Boulder Throw
	[258182] = "CC",				-- Boulder Throw
	[268283] = "CC",				-- Obscured Vision (hit chance decreased 75%)
	[257274] = "Snare",				-- Vile Coating
	[257478] = "Snare",				-- Crippling Bite
	[257747] = "Snare",				-- Earth Shaker
	[257784] = "Snare",				-- Frost Blast
	[272554] = "Snare",				-- Bloody Mess
	-- -- Siege of Boralus
	[256957] = "Immune",			-- Watertight Shell
	[257069] = "CC",				-- Watertight Shell
	[261428] = "CC",				-- Hangman's Noose
	[257292] = "CC",				-- Heavy Slash
	[272874] = "CC",				-- Trample
	[257169] = "CC",				-- Terrifying Roar
	[274942] = "CC",				-- Banana Rampage
	[272571] = "Silence",			-- Choking Waters
	[275826] = "Immune",			-- Bolstering Shout (damage taken reduced 75%)
	[270624] = "Root",				-- Crushing Embrace
	[272834] = "Snare",				-- Viscous Slobber
	-- -- The Underrot
	[265377] = "Root",				-- Hooked Snare
	[272609] = "CC",				-- Maddening Gaze
	[265511] = "CC",				-- Spirit Drain
	[278961] = "CC",				-- Decaying Mind
	[269406] = "CC",				-- Purge Corruption
	[258347] = "Silence",			-- Sonic Screech
	------------------------
	---- PVE LEGION
	------------------------
	-- EN Raid
	-- -- Trash
	[223914] = "CC",				-- Intimidating Roar
	[225249] = "CC",				-- Devastating Stomp
	[225073] = "Root",				-- Despoiling Roots
	[222719] = "Root",				-- Befoulment
	-- -- Nythendra
	[205043] = "CC",				-- Infested Mind
	-- -- Ursoc
	[197980] = "CC",				-- Nightmarish Cacophony
	-- -- Dragons of Nightmare
	[205341] = "CC",				-- Seeping Fog
	[225356] = "CC",				-- Seeping Fog
	[203110] = "CC",				-- Slumbering Nightmare
	[204078] = "CC",				-- Bellowing Roar
	[203770] = "Root",				-- Defiled Vines
	-- -- Il'gynoth
	[212886] = "CC",				-- Nightmare Corruption
	-- -- Cenarius
	[210315] = "Root",				-- Nightmare Brambles
	[214505] = "CC",				-- Entangling Nightmares
	-- -- Xavius
	[207409] = "CC",				-- Corruption: Madness
	------------------------
	-- ToV Raid
	-- -- Trash
	[228609] = "CC",				-- Bone Chilling Scream
	[228883] = "CC",				-- Unholy Reckoning
	[228869] = "CC",				-- Crashing Waves
	-- -- Odyn
	[228018] = "Immune",			-- Valarjar's Bond
	[229529] = "Immune",			-- Valarjar's Bond
	[227781] = "CC",				-- Glowing Fragment
	[227594] = "Immune",			-- Runic Shield
	[227595] = "Immune",			-- Runic Shield
	[227596] = "Immune",			-- Runic Shield
	[227597] = "Immune",			-- Runic Shield
	[227598] = "Immune",			-- Runic Shield
	-- -- Guarm
	[228248] = "CC",				-- Frost Lick (Guarm)
	-- -- Helya
	[232350] = "CC",				-- Corrupted (Helya)
	------------------------
	-- NH Raid
	-- -- Trash
	[225583] = "CC",				-- Arcanic Release
	[225803] = "Silence",			-- Sealed Magic
	[224483] = "CC",				-- Slam
	[224944] = "CC",				-- Will of the Legion
	[224568] = "CC",				-- Mass Suppress
	[221524] = "Immune",			-- Protect (not immune, 90% less dmg)
	[226231] = "Immune",			-- Faint Hope
	[230377] = "CC",				-- Wailing Bolt
	-- -- Skorpyron
	[204483] = "CC",				-- Focused Blast
	-- -- Spellblade Aluriel
	[213621] = "CC",				-- Entombed in Ice
	-- -- Tichondrius
	[215988] = "CC",				-- Carrion Nightmare
	-- -- High Botanist Tel'arn
	[218304] = "Root",				-- Parasitic Fetter
	-- -- Star Augur
	[206603] = "CC",				-- Frozen Solid
	[216697] = "CC",				-- Frigid Pulse
	[207720] = "CC",				-- Witness the Void
	[207714] = "Immune",			-- Void Shift (-99% dmg taken)
	-- -- Gul'dan
	[206366] = "CC",				-- Empowered Bonds of Fel (Knockback Stun)
	[206983] = "CC",				-- Shadowy Gaze
	[208835] = "CC",				-- Distortion Aura
	[208671] = "CC",				-- Carrion Wave
	[229951] = "CC",				-- Fel Obelisk
	[206841] = "CC",				-- Fel Obelisk
	[227749] = "Immune",			-- The Eye of Aman'Thul
	[227750] = "Immune",			-- The Eye of Aman'Thul
	[227743] = "Immune",			-- The Eye of Aman'Thul
	[227745] = "Immune",			-- The Eye of Aman'Thul
	[227427] = "Immune",			-- The Eye of Aman'Thul
	[227320] = "Immune",			-- The Eye of Aman'Thul
	[206516] = "Immune",			-- The Eye of Aman'Thul
	------------------------
	-- ToS Raid
	-- -- Trash
	[243298] = "CC",				-- Lash of Domination
	[240706] = "CC",				-- Arcane Ward
	[240737] = "CC",				-- Polymorph Bomb
	[239810] = "CC",				-- Sever Soul
	[240592] = "CC",				-- Serpent Rush
	[240169] = "CC",				-- Electric Shock
	[241234] = "CC",				-- Darkening Shot
	[241009] = "CC",				-- Power Drain (-90% damage)
	[241254] = "CC",				-- Frost-Fingered Fear
	[241276] = "CC",				-- Icy Tomb
	[241348] = "CC",				-- Deafening Wail
	[241032] = "Silence",			-- Desolation of the Moon
	-- -- Demonic Inquisition
	[233430] = "CC",				-- Unbearable Torment (no CC, -90% dmg, -25% heal, +90% dmg taken)
	-- -- Harjatan
	[240315] = "Immune",			-- Hardened Shell
	-- -- Sisters of the Moon
	[237351] = "Silence",			-- Lunar Barrage
	-- -- Mistress Sassz'ine
	[234332] = "CC",				-- Hydra Acid
	[230362] = "CC",				-- Thundering Shock
	[230959] = "CC",				-- Concealing Murk (no CC, hit chance reduced 75%)
	-- -- The Desolate Host
	[236241] = "CC",				-- Soul Rot (no CC, dmg dealt reduced 75%)
	[236011] = "Silence",			-- Tormented Cries
	[236513] = "Immune",			-- Bonecage Armor (75% dmg reduction)
	-- -- Maiden of Vigilance
	[248812] = "CC",				-- Blowback
	[233739] = "CC",				-- Malfunction
	-- -- Kil'jaeden
	[245332] = "Immune",			-- Nether Shift
	[244834] = "Immune",			-- Nether Gale
	[236602] = "CC",				-- Soul Anguish
	[236555] = "CC",				-- Deceiver's Veil
	------------------------
	-- Antorus Raid
	-- -- Trash
	[246209] = "CC",				-- Punishing Flame
	[254502] = "CC",				-- Fearsome Leap
	[254125] = "CC",				-- Cloud of Confusion
	[254176] = "Silence",			-- Lash of Punishment
	[241311] = "Snare",				-- Spirit Chain Volley
	-- -- Garothi Worldbreaker
	[246920] = "CC",				-- Haywire Decimation
	-- -- Hounds of Sargeras
	[244086] = "CC",				-- Molten Touch
	[244072] = "CC",				-- Molten Touch
	[249227] = "CC",				-- Molten Touch
	[249241] = "CC",				-- Molten Touch
	[244071] = "CC",				-- Weight of Darkness
	-- -- War Council
	[244748] = "CC",				-- Shocked
	-- -- Portal Keeper Hasabel
	[246208] = "Root",				-- Acidic Web
	[244949] = "CC",				-- Felsilk Wrap
	-- -- Imonar the Soulhunter
	[247641] = "CC",				-- Stasis Trap
	[255029] = "CC",				-- Sleep Canister
	[247565] = "CC",				-- Slumber Gas
	[250135] = "Immune",			-- Conflagration (-99% damage taken)
	[248233] = "Immune",			-- Conflagration (-99% damage taken)
	-- -- Kin'garoth
	[246516] = "Immune",			-- Apocalypse Protocol (-99% damage taken)
	-- -- The Coven of Shivarra
	[253203] = "Immune",			-- Shivan Pact (-99% damage taken)
	[249863] = "Immune",			-- Visage of the Titan
	[256356] = "CC",				-- Chilled Blood
	-- -- Aggramar
	[244894] = "Immune",			-- Corrupt Aegis
	[246014] = "CC",				-- Searing Tempest
	[255062] = "CC",				-- Empowered Searing Tempest
	------------------------
	-- The Deaths of Chromie Scenario
	[246941] = "CC",				-- Looming Shadows
	[245167] = "CC",				-- Ignite
	[248839] = "CC",				-- Charge
	[246211] = "CC",				-- Shriek of the Graveborn
	[247683] = "Root",				-- Deep Freeze
	[247684] = "CC",				-- Deep Freeze
	[244959] = "CC",				-- Time Stop
	[248516] = "CC",				-- Sleep
	[245169] = "Immune",			-- Reflective Shield
	[248716] = "CC",				-- Infernal Strike
	[247730] = "Root",				-- Faith's Fetters
	[245822] = "CC",				-- Inescapable Nightmare
	[245126] = "Silence",			-- Soul Burn
	------------------------
	-- Legion Mythics
	-- -- The Arcway
	[195804] = "CC",				-- Quarantine
	[203649] = "CC",				-- Exterminate
	[203957] = "CC",				-- Time Lock
	[211543] = "Root",				-- Devour
	-- -- Black Rook Hold
	[194960] = "CC",				-- Soul Echoes
	[197974] = "CC",				-- Bonecrushing Strike
	[199168] = "CC",				-- Itchy!
	[204954] = "CC",				-- Cloud of Hypnosis
	[199141] = "CC",				-- Cloud of Hypnosis
	[199097] = "CC",				-- Cloud of Hypnosis
	[214002] = "CC",				-- Raven's Dive
	[200261] = "CC",				-- Bonebreaking Strike
	[201070] = "CC",				-- Dizzy
	[221117] = "CC",				-- Ghastly Wail
	[222417] = "CC",				-- Boulder Crush
	[221838] = "CC",				-- Disorienting Gas
	-- -- Court of Stars
	[207278] = "Snare",				-- Arcane Lockdown
	[207261] = "CC",				-- Resonant Slash
	[215204] = "CC",				-- Hinder
	[207979] = "CC",				-- Shockwave
	[224333] = "CC",				-- Enveloping Winds
	[209404] = "Silence",			-- Seal Magic
	[209413] = "Silence",			-- Suppress
	[209027] = "CC",				-- Quelling Strike
	[212773] = "CC",				-- Subdue
	[216000] = "CC",				-- Mighty Stomp
	[213233] = "CC",				-- Uninvited Guest
	-- -- Return to Karazhan
	[227567] = "CC",				-- Knocked Down
	[228215] = "CC",				-- Severe Dusting
	[227508] = "CC",				-- Mass Repentance
	[227545] = "CC",				-- Mana Drain
	[227909] = "CC",				-- Ghost Trap
	[228693] = "CC",				-- Ghost Trap
	[228280] = "CC",				-- Oath of Fealty
	[228837] = "CC",				-- Bellowing Roar
	[227592] = "CC",				-- Frostbite
	[228239] = "CC",				-- Terrifying Wail
	[241774] = "CC",				-- Shield Smash
	[230122] = "Silence",			-- Garrote - Silence
	[39331]  = "Silence",			-- Game In Session
	[227977] = "CC",				-- Flashlight
	[241799] = "CC",				-- Seduction
	[227917] = "CC",				-- Poetry Slam
	[230083] = "CC",				-- Nullification
	[232156] = "Immune",			-- Spectral Service
	[229489] = "Immune",			-- Royalty (90% dmg reduction)
	-- -- Maw of Souls
	[193364] = "CC",				-- Screams of the Dead
	[198551] = "CC",				-- Fragment
	[197653] = "CC",				-- Knockdown
	[198405] = "CC",				-- Bone Chilling Scream
	[193215] = "CC",				-- Kvaldir Cage
	[204057] = "CC",				-- Kvaldir Cage
	[204058] = "CC",				-- Kvaldir Cage
	[204059] = "CC",				-- Kvaldir Cage
	[204060] = "CC",				-- Kvaldir Cage
	-- -- Vault of the Wardens
	[202455] = "Immune",			-- Void Shield
	[212565] = "CC",				-- Inquisitive Stare
	[225416] = "CC",				-- Intercept
	[6726]   = "Silence",			-- Silence
	[201488] = "CC",				-- Frightening Shout
	[203774] = "Immune",			-- Focusing
	[192517] = "CC",				-- Brittle
	[201523] = "CC",				-- Brittle
	[194323] = "CC",				-- Petrified
	[206387] = "CC",				-- Steal Light
	[197422] = "Immune",			-- Creeping Doom
	[210138] = "CC",				-- Fully Petrified
	[202615] = "Root",				-- Torment
	[193069] = "CC",				-- Nightmares
	[191743] = "Silence",			-- Deafening Screech
	[202658] = "CC",				-- Drain
	[193969] = "Root",				-- Razors
	[204282] = "CC",				-- Dark Trap
	-- -- Eye of Azshara
	[191975] = "CC",				-- Impaling Spear
	[191977] = "CC",				-- Impaling Spear
	[193597] = "CC",				-- Static Nova
	[192708] = "CC",				-- Arcane Bomb
	[195561] = "CC",				-- Blinding Peck
	[195129] = "CC",				-- Thundering Stomp
	[195253] = "CC",				-- Imprisoning Bubble
	[197144] = "Root",				-- Hooked Net
	[197105] = "CC",				-- Polymorph: Fish
	[195944] = "CC",				-- Rising Fury
	[193491] = "Immune",			-- Tempest Attunement
	-- -- Darkheart Thicket
	[200329] = "CC",				-- Overwhelming Terror
	[200273] = "CC",				-- Cowardice
	[204246] = "CC",				-- Tormenting Fear
	[200631] = "CC",				-- Unnerving Screech
	[200771] = "CC",				-- Propelling Charge
	[199063] = "Root",				-- Strangling Roots
	-- -- Halls of Valor
	[198088] = "CC",				-- Glowing Fragment
	[215429] = "CC",				-- Thunderstrike
	[199340] = "CC",				-- Bear Trap
	[210749] = "CC",				-- Static Storm
	-- -- Neltharion's Lair
	[200672] = "CC",				-- Crystal Cracked
	[202181] = "CC",				-- Stone Gaze
	[193585] = "CC",				-- Bound
	[186616] = "CC",				-- Petrified
	-- -- Cathedral of Eternal Night
	[238678] = "Silence",			-- Stifling Satire
	[237391] = "CC",				-- Alluring Aroma
	[238484] = "CC",				-- Beguiling Biography
	[242724] = "CC",				-- Dread Scream
	[239217] = "CC",				-- Blinding Glare
	[238583] = "Silence",			-- Devour Magic
	[239156] = "CC",				-- Book of Eternal Winter
	[240556] = "Silence",			-- Tome of Everlasting Silence
	[242792] = "CC",				-- Vile Roots
	-- -- The Seat of the Triumvirate
	[246913] = "Immune",			-- Void Phased
	[244621] = "CC",				-- Void Tear
	[248831] = "CC",				-- Dread Screech
	[246026] = "CC",				-- Void Trap
	[245278] = "CC",				-- Void Trap
	[244751] = "CC",				-- Howling Dark
	[248804] = "Immune",			-- Dark Bulwark
	[247816] = "CC",				-- Backlash
	[254020] = "Immune",			-- Darkened Shroud
	[253952] = "CC",				-- Terrifying Howl
	[248298] = "Silence",			-- Screech
	[245706] = "CC",				-- Ruinous Strike
	[248133] = "CC",				-- Stygian Blast
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
	[37160]  = "Silence",			-- Silence
	[37262]  = "Snare",				-- Frostbolt Volley
	[37265]  = "Snare",				-- Cone of Cold
	[39087]  = "Snare",				-- Frost Attack
	-- -- Void Reaver
	[34190]  = "Silence",			-- Arcane Orb
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
	[40099]  = "CC",				-- Vile Slime (damage and healing dealt reduced by 50%)
	[40079]  = "CC",				-- Debilitating Spray (damage and healing dealt reduced by 50%)
	[39584]  = "Root",				-- Sweeping Wing Clip
	[40082]  = "Root",				-- Hooked Net
	[41086]  = "Root",				-- Ice Trap
	[41371]  = "ImmuneSpell",		-- Shell of Pain
	[41381]  = "ImmuneSpell",		-- Shell of Life
	[39667]  = "Immune",			-- Vanish
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
	[42201]  = "Silence",			-- Eternal Silence
	[42205]  = "Silence",			-- Residue of Eternity
	[31406]  = "Snare",				-- Cripple
	[31622]  = "Snare",				-- Frostbolt
	[31688]  = "Snare",				-- Frost Breath
	[31741]  = "Snare",				-- Slow
	-- -- Rage Winterchill
	[31249]  = "CC",				-- Icebolt
	[31250]  = "Root",				-- Frost Nova
	[31257]  = "Snare",				-- Chilled
	-- -- Anetheron
	[31298]  = "CC",				-- Sleep
	-- -- Kaz'rogal
	[31480]  = "CC",				-- War Stomp
	[31477]  = "Snare",				-- Cripple
	-- -- Azgalor
	[31344]  = "Silence",			-- Howl of Azgalor
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
	[35011]  = "CC",				-- Knockdown
	[42479]  = "Immune",			-- Protective Ward
	[43362]  = "Root",				-- Electrified Net
	[43364]  = "Snare",				-- Tranquilizing Poison
	[43524]  = "Snare",				-- Frost Shock
	-- -- Akil'zon
	[43648]  = "CC",				-- Electrical Storm
	-- -- Nalorakk
	[42398]  = "Silence",			-- Deafening Roar
	-- -- Hex Lord Malacrass
	[43590]  = "CC",				-- Psychic Wail
	-- -- Daakara
	[43437]  = "CC",				-- Paralyzed
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
	[136466] = "CC",				-- Banish
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
	[30621]  = "CC",				-- Kidney Shot
	[31901]  = "Immune",			-- Demonic Shield (not immune, damage taken reduced by 75%)
	-- -- The Blood Furnace
	[30923]  = "CC",				-- Domination
	[31865]  = "CC",				-- Seduction
	[30940]  = "Immune",			-- Burning Nova
	[58747]  = "CC",				-- Intercept
	-- -- The Shattered Halls
	[30500]  = "CC",				-- Death Coil
	[30741]  = "CC",				-- Death Coil
	[30584]  = "CC",				-- Fear
	[37511]  = "CC",				-- Charge
	[23601]  = "CC",				-- Scatter Shot
	[30980]  = "CC",				-- Sap
	[30986]  = "CC",				-- Cheap Shot
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
	[100940] = "CC",				-- Improved Concussive Shot
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
	[29061]  = "Immune",			-- Bone Barrier (not immune, 75% damage reduction)
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
	[243901] = "CC",				-- Mark of Frost
	[21099]  = "CC",				-- Frost Breath
	[22067]  = "ImmuneSpell",		-- Reflection
	[27564]  = "ImmuneSpell",		-- Reflection
	[243835] = "ImmuneSpell",		-- Reflection
	[21098]  = "Snare",				-- Chill
	-- -- Doom Lord Kazzak & Highlord Kruul
	[8078]   = "Snare",				-- Thunderclap
	[23931]  = "Snare",				-- Thunderclap
	[243713] = "Snare",				-- Void Bolt
	-- -- Dragons of Nightmare
	[25043]  = "CC",				-- Aura of Nature
	[24778]  = "CC",				-- Sleep (Dream Fog)
	[24811]  = "CC",				-- Draw Spirit
	[25806]  = "CC",				-- Creature of Nightmare
	[248320] = "CC",				-- Lethargy
	[243411] = "CC",				-- Tail Sweep
	[243666] = "CC",				-- Bellowing Roar
	[243667] = "CC",				-- Bellowing Roar
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
	[92614]  = "Immune",			-- Deflection
	[88348]  = "CC",				-- Off-line
	[91732]  = "CC",				-- Off-line
	[92100]  = "CC",				-- Noxious Concoction
	[88836]  = "CC",				-- Go For the Throat
	[87901]  = "Snare",				-- Fists of Frost
	[88177]  = "Snare",				-- Frost Blossom
	[88288]  = "CC",				-- Charge
	[91726]  = "CC",				-- Reaper Charge
	[90958]  = "Other",				-- Evasion
	[95491]  = "CC",				-- Cannonball
	[135337] = "CC",				-- Cannonball
	[89769]  = "CC",				-- Explode
	[55041]  = "CC",				-- Freezing Trap Effect
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
	[93956]  = "Other",				-- Cursed Veil	
	[67781]  = "Snare",				-- Desecration
	[93691]  = "Snare",				-- Desecration
	[196178] = "Snare",				-- Desecration
	[93697]  = "Snare",				-- Conjure Poisonous Mixture
	[91220]  = "CC",				-- Cowering Roar
	[93423]  = "CC",				-- Asphyxiate
	[30615]  = "CC",				-- Fear
	[15497]  = "Snare",				-- Frostbolt
	[93930]  = "CC",				-- Spectral Ravaging
	[93863]  = "Root",				-- Soul Drain
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
	[151963] = "CC",				-- Crush
	[150660] = "CC",				-- Crush
	[152417] = "CC",				-- Crush
	[149955] = "CC",				-- Devouring Blackness
	[150634] = "CC",				-- Leviathan's Grip
	[5424]   = "Root",				-- Claw Grasp
	[149910] = "Root",				-- Catch of the Day
	[302956] = "Root",				-- Catch of the Day
	-- -- The Stockade
	[3419]   = "Other",				-- Improved Blocking
	[6253]   = "CC",				-- Backhand
	[204735] = "Snare",				-- Frostbolt
	[86740]  = "CC",				-- Dirty Blow
	[86814]  = "CC",				-- Bash Head
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
	[74720]  = "CC",				-- Pound
	-- -- Razorfen Kraul
	[8281]   = "Silence",			-- Sonic Burst
	[39052]  = "Silence",			-- Sonic Burst
	[8359]   = "CC",				-- Left for Dead
	[8285]   = "CC",				-- Rampage
	[8361]   = "Immune",			-- Purity
	[6984]   = "Snare",				-- Frost Shot
	[18802]  = "Snare",				-- Frost Shot
	[6728]   = "CC",				-- Enveloping Winds
	[3248]   = "Other",				-- Improved Blocking
	[151583] = "Root",				-- Elemental Binding
	[286963] = "CC",				-- Elemental Binding
	[153550] = "Silence",			-- Solarshard Beam
	[150357] = "Silence",			-- Solarshard Beam
	[150859] = "Snare",				-- Wing Clip
	[153214] = "CC",				-- Sonic Charge
	[150651] = "Root",				-- Vine Line
	[150304] = "Root",				-- Vine Line
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
	[11443]  = "Snare",				-- Cripple
	[11436]  = "Snare",				-- Slow
	[12531]  = "Snare",				-- Chilling Touch
	[12748]  = "Root",				-- Frost Nova
	[152773] = "CC",				-- Possession
	[150082] = "Snare",				-- Plagued Bite
	[150707] = "CC",				-- Overwhelmed
	[150485] = "Root",				-- Web Wrap
	-- -- Uldaman
	[11876]  = "CC",				-- War Stomp
	[3636]   = "CC",				-- Crystalline Slumber
	[9906]   = "ImmuneSpell",		-- Reflection
	[10093]  = "Snare",				-- Harsh Winds
	[25161]  = "Silence",			-- Harsh Winds
	[55142]  = "CC",				-- Ground Tremor
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
	[34259]  = "CC",				-- Fear
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
	[280494] = "CC",				-- Conflagration
	[47442]  = "CC",				-- Barreled!
	[21401]  = "Snare",				-- Frost Shock
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
	[3589]   = "Silence",			-- Deafening Screech
	[54791]  = "Snare",				-- Frostbolt
	[66290]  = "CC",				-- Sleep
	[82107]  = "CC",				-- Deep Freeze
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
	[12611]  = "Snare",				-- Cone of Cold
	[16838]  = "Silence",			-- Banshee Shriek
	[22519]  = "CC",				-- Ice Nova
	[57825]  = "Snare",				-- Frostbolt
	-- -- Scholomance
	[5708]   = "CC",				-- Swoop
	[18144]  = "CC",				-- Swoop
	[18103]  = "CC",				-- Backhand
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
	Perl = {
		player       = "Perl_Player_PortraitFrame",
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
	PitBullUF = {
		player       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Player"]..".Portrait" or nil,
		pet          = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Player's pet"]..".Portrait" or nil,
		target       = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Target"]..".Portrait" or nil,
		targettarget = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["%s's target"]:format(LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Target"])..".Portrait" or nil,
		focus        = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Focus"]..".Portrait" or nil,
		focustarget  = LibStub("AceLocale-3.0"):GetLocale("PitBull4",true) and "PitBull4_Frames_"..LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["%s's target"]:format(LibStub("AceLocale-3.0"):GetLocale("PitBull4",true)["Focus"])..".Portrait" or nil,
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
		focus        = "SUI_UF_focus.Portrait2D",
		focustarget  = "SUI_UF_focustarget.Portrait2D",
	},
	SpartanUI_3D = {
		player       = "SUI_UF_player.Portrait3D",
		pet          = "SUI_UF_pet.Portrait3D",
		target       = "SUI_UF_target.Portrait3D",
		targettarget = "SUI_UF_targettarget.Portrait3D",
		focus        = "SUI_UF_focus.Portrait3D",
		focustarget  = "SUI_UF_focustarget.Portrait3D",
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
		focus        = "GwFocusUnitFrame.portrait",
		party1       = "GwPartyFrame1.portrait",
		party2       = "GwPartyFrame2.portrait",
		party3       = "GwPartyFrame3.portrait",
		party4       = "GwPartyFrame4.portrait",
	},
	nUI = {
		player       = "nUI_PartyUnit_Player_Portrait",
		target       = "nUI_PartyUnit_Target_Portrait",
		focus        = "nUI_PartyUnit_Focus_Portrait",
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
		focus        = "ElvUF_Focus.Portrait",
		focustarget  = "ElvUF_FocusTarget.Portrait",
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
	version = 7.2, -- This is the settings version, not necessarily the same as the LoseControl version
	noCooldownCount = false,
	noBlizzardCooldownCount = true,
	noLossOfControlCooldown = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
					friendly = (not(GetCVarBool("lossOfControl")) or (GetCVar("lossOfControlInterrupt")~="2"))
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
			enableElementalSchoolMiniIcon = true,
			enableChaosSchoolMiniIcon = true,
			useSpellInsteadSchoolMiniIcon = false,
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
						C_Timer.After(2.5, self.UpdateStateFuncCache)
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
						self:UNIT_AURA(self.unitId, 300)
						self.timerActive = true
						C_Timer.After(2.5, self.UpdateStateFuncCache)
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
				-- FocusTarget Blizzard Frame Show
				FocusFrameToT:HookScript("OnShow", function()
					if (self.frame.enabled and not self.unlockMode) then
						self.unitGUID = UnitGUID(self.unitId)
						if self.frame.anchor == "Blizzard" then
							self:UNIT_AURA(self.unitId, -30)
						else
							self:UNIT_AURA(self.unitId, 30)
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
										self:UNIT_AURA(self.unitId, 30)
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
										self:UNIT_AURA(self.unitId, 31)
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
	LCframes["target"]:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Function to check if pvp talents are active for the player
function LoseControl:ArePvpTalentsActive()
	local inInstance, instanceType = IsInInstance()
	if inInstance and (instanceType == "pvp" or instanceType == "arena") then
		return true
	elseif inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
		return false
	else
		local talents = GetAllSelectedPvpTalentIDs()
		if talents then
			for _, pvptalent in pairs(talents) do
				if pvptalent then
					local spellId = select(6, GetPvpTalentInfoByID(pvptalent))
					if IsPlayerSpell(spellId) then
						return true
					end
				end
			end
		end
		return false
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
	for _, v in pairs(iconFrame.iconExtraInterruptList) do
		v:SetWidth(interruptIconSize)
		v:SetHeight(interruptIconSize)
		v:SetPoint("BOTTOMRIGHT", iconFrame.interruptIconOrderPos[v.interruptIconOrder or 1][1], iconFrame.interruptIconOrderPos[v.interruptIconOrder or 1][2])
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

-- Dummy function to replace GetLossOfControlCooldown function from ActionButtons
local function LoseControl_ActionButtonGetLossOfControlCooldown(self)
	return 0, 0
end

-- Function to reconfigure all BT4Buttons when Bartender4 ActionBars are loaded or modified
function LoseControl_HookBartender4LoseControlIcons()
	for i = 1, 120 do
		if (not LCBartender4ButtonsTable[i]) then
			local button = _G["BT4Button"..i]
			LCBartender4ButtonsTable[i] = button
			if (button and (not button.LOSECONTROL_BT4_HOOKED)) then
				button.GetLossOfControlCooldown = LoseControl_ActionButtonGetLossOfControlCooldown
				button.LOSECONTROL_BT4_HOOKED = true
			end
		end
	end
end

-- Function to reconfigure all ConsolePortActionButtons when ConsolePort ActionBars are loaded or modified
function LoseControl_HookConsolePortLoseControlIcons()
	local mods = { "", "_SHIFT", "_CTRL", "_CTRL-SHIFT" }
	for bindName in ConsolePort:GetBindings() do
		for _, modSuf in ipairs(mods) do
			local buttonName = "CPB_"..bindName..modSuf
			if (not LCConsolePortButtonsTable[buttonName]) then
				local button = _G[buttonName]
				LCConsolePortButtonsTable[buttonName] = button
				if (button and (not button.LOSECONTROL_CONSOLEPORT_HOOKED)) then
					button.GetLossOfControlCooldown = LoseControl_ActionButtonGetLossOfControlCooldown
					button.LOSECONTROL_CONSOLEPORT_HOOKED = true
				end
			end
		end
	end
end

-- Function to reconfigure all ElvUI_BarX_ButtonX when ElvUI ActionBars are loaded or modified
function LoseControl_HookElvUILoseControlIcons()
	for iBar = 1, 10 do
		for iButton = 1, 12 do
			local index = (iBar-1)*12+iButton
			if (not LCElvUIButtonsTable[index]) then
				local button = _G["ElvUI_Bar"..iBar.."Button"..iButton]
				LCElvUIButtonsTable[index] = button
				if (button and (not button.LOSECONTROL_ELVUI_HOOKED)) then
					button.GetLossOfControlCooldown = LoseControl_ActionButtonGetLossOfControlCooldown
					button.LOSECONTROL_ELVUI_HOOKED = true
				end
			end
		end
	end
end

-- Function to disable Cooldown on player bars for CC effects
function LoseControl:DisableLossOfControlUI(isAutoCall)
	if (not LCAddonBartender4IsPresent) then
		if ((BINDING_HEADER_Bartender4 ~= nil) and (BINDING_NAME_BTTOGGLEACTIONBARLOCK ~= nil) and (Bartender4 ~= nil) and (Bartender4.ActionBar ~= nil)) then
			if (not Bartender4.ActionBar.LOSECONTROL_BT4_HOOKED) then
				hooksecurefunc(Bartender4.ActionBar, 'ApplyConfig', LoseControl_HookBartender4LoseControlIcons)
				LoseControl_HookBartender4LoseControlIcons()
				Bartender4.ActionBar.LOSECONTROL_BT4_HOOKED = true
			end
			LCAddonBartender4IsPresent = true
		elseif not(isAutoCall) then	-- delay checking to make sure all variables of the other addons are loaded
			C_Timer.After(8, function() self:DisableLossOfControlUI(true) end)
		end
	end
	if (not LCAddonConsolePortIsPresent) then
		if ((ConsolePort ~= nil) and (ConsolePortBar ~= nil) and (CPActionButtonMixin ~= nil)) then
			if (not ConsolePortBar.LOSECONTROL_CONSOLEPORT_HOOKED) then
				hooksecurefunc(ConsolePortBar, 'OnLoad', LoseControl_HookConsolePortLoseControlIcons)
				LoseControl_HookConsolePortLoseControlIcons()
				ConsolePortBar.LOSECONTROL_CONSOLEPORT_HOOKED = true
			end
			LCAddonConsolePortIsPresent = true
		elseif not(isAutoCall) then	-- delay checking to make sure all variables of the other addons are loaded
			C_Timer.After(9, function() self:DisableLossOfControlUI(true) end)
		end
	end
	if (not LCAddonElvUIIsPresent) then
		if ((ElvUI ~= nil) and (Elv_ABFade ~= nil) and (ElvUI_Bar1 ~= nil)) then
			LoseControl_HookElvUILoseControlIcons()
			LCAddonElvUIIsPresent = true
		elseif not(isAutoCall) then	-- delay checking to make sure all variables of the other addons are loaded
			C_Timer.After(10, function() self:DisableLossOfControlUI(true) end)
		end
	end
	if (not DISABLELOSSOFCONTROLUI_HOOKED) then
		hooksecurefunc('ActionButton_UpdateCooldown', function(self)
			if ( self.cooldown.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL ) then
				local start, duration, enable, charges, maxCharges, chargeStart, chargeDuration
				local modRate = 1.0
				local chargeModRate = 1.0
				if ( self.spellID ) then
					start, duration, enable, modRate = GetSpellCooldown(self.spellID)
					charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetSpellCharges(self.spellID)
				else
					start, duration, enable, modRate = GetActionCooldown(self.action)
					charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(self.action)
				end
				self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
				self.cooldown:SetSwipeColor(0, 0, 0)
				self.cooldown:SetHideCountdownNumbers(false)
				if ( charges and maxCharges and maxCharges > 1 and charges < maxCharges ) then
					if chargeStart == 0 then
						ClearChargeCooldown(self)
					else
						if self.chargeCooldown then
							CooldownFrame_Set(self.chargeCooldown, chargeStart, chargeDuration, true, true, chargeModRate)
						end
					end
				else
					ClearChargeCooldown(self)
				end
				CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate)
			end
		end)
		DISABLELOSSOFCONTROLUI_HOOKED = true
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
		if _G.LoseControlDB.version < DBdefaults.version then
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
		self.VERSION = "7.06"
		self.noCooldownCount = LoseControlDB.noCooldownCount
		self.noBlizzardCooldownCount = LoseControlDB.noBlizzardCooldownCount
		self.noLossOfControlCooldown = LoseControlDB.noLossOfControlCooldown
		if LoseControlDB.noLossOfControlCooldown then
			LoseControl:DisableLossOfControlUI()
		end
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
				elseif strfind(self.unitId, "arena") then
					if ((self.fakeUnitId or self.unitId) == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelarenaPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelarenaPositionYEditBox']
						FrameLevelEditBox = _G['LoseControlOptionsPanelarenaFrameLevelEditBox']
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
function LoseControl:PLAYER_ENTERING_WORLD() -- this correctly anchors enemy arena frames that aren't created until you zone into an arena
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
	for _, v in pairs(self.iconExtraInterruptList) do
		v:SetAlpha(frame.interruptMiniIconsAlpha)
	end
	for _, v in ipairs(self.iconQueueInterruptList) do
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
		self:UNIT_AURA(unitId, 0)
	end
end

function LoseControl:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	self:ARENA_OPPONENT_UPDATE()
end

-- This event check interrupts and SpecialAurasExtraInfo and targettarget/focustarget unit aura triggers
function LoseControl:COMBAT_LOG_EVENT_UNFILTERED()
	if self.unitId == "target" then
		-- Check Interrupts
		local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, _, _, exSpellId, _, spellSchool = CombatLogGetCurrentEventInfo()
		if (destGUID ~= nil and destGUID ~= "") then
			if (event == "SPELL_INTERRUPT") then
				local duration = interruptsIds[spellId]
				if (duration ~= nil) then
					if (type(duration)=="table") then
						local _, _, difficultyID = GetInstanceInfo()
						if difficultyID == nil then
							difficultyID = 0
						end
						local default = 0
						for _, v in pairs(duration) do
							if v[2] == difficultyID then
								duration = v[1]
								break
							elseif v[2] == 0 then
								default = v[1]
							end
						end
						if (type(duration)=="table") then
							duration = default
						end
					end
					if (strfind(destGUID, "^Player-")) then
						local unitIdFromGUID
						for _, v in pairs(LCframes) do
							if (UnitGUID(v.unitId) == destGUID) then
								unitIdFromGUID = v.unitId
								break
							end
						end
						local duration2 = duration
						if (unitIdFromGUID ~= nil) then
							local _, destClass = GetPlayerInfoByGUID(destGUID)
							for i = 1, 120 do
								local _, _, _, _, _, _, _, _, _, auxSpellId = UnitAura(unitIdFromGUID, i)
								if not auxSpellId then break end
								-- spellId = 35126 [Interrupted Mechanic Duration -20% (Item) (doesn't stack)] and spellId = 42184 [Interrupted Mechanic Duration -10% (Item) (doesn't stack)] are hidden auras, assume absent
								if (destClass == "DRUID") then
									if auxSpellId == 234084 then		-- Moon and Stars (Druid) [Interrupted Mechanic Duration -70% (stacks)]
										duration = duration * 0.3
									end
								end
								if auxSpellId == 317920 then		-- Concentration Aura (Paladin) [Interrupted Mechanic Duration -30% (stacks)]
									duration = duration * 0.7
								end
							end
						end
						-- Familiar Predicaments (Nadjia Soulbind Spell, spellId = 331582, soulbindNodeId = 1403) [Interrupted Mechanic Duration -15% ((doesn't stack)] (only trackable on player atm)
						if ((destGUID == playerGUID) and (SoulbindsGetActiveSoulbindID() == 8) and (SoulbindsGetNode(1403) and SoulbindsGetNode(1403).state == 3)) then
							duration2 = duration2 * 0.85
							if (duration2 < duration) then
								duration = duration2
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
		-- Check SpecialAurasExtraInfo
		if (event == "SPELL_CAST_SUCCESS" and sourceGUID ~= nil) then
			if (spellId == 51052) then	-- Anti-Magic Zone
				if (strfind(sourceGUID, "^Player-")) then
					local extraDuration = 0
					if (sourceGUID == playerGUID) then
						if (IsPlayerSpell(337764)) then	-- Reinforced Shell Conduit Spell
							local conduitRank = SoulbindsGetConduitRank(74) or 0	-- Reinforced Shell Conduit ID
							extraDuration = 1.8 + conduitRank * 0.2
							local renownLevel = CovenantGetRenownLevel() or 1
							if renownLevel >= 79 then
								extraDuration = extraDuration + 0.4
							elseif renownLevel > 60 then
								local activeSoulbind = SoulbindsGetActiveSoulbindID() or 0
								if (activeSoulbind > 0) then
									local nodeId = SoulbindsFindNodeIDActuallyInstalled(activeSoulbind, 74) or 0
									if (nodeId > 0) then
										if (SoulbindsGetNode(nodeId) and SoulbindsGetNode(nodeId).socketEnhanced) then
											extraDuration = extraDuration + 0.4
										end
									end
								end
							end
						end
						for i = 1, 120 do
							local _, _, auxCount, _, _, _, _, _, _, auxSpellId = UnitAura("player", i, "MAW");
							if not auxSpellId then break end
							if (auxSpellId == 332861) then	-- Darkreaver's Ward Anima Power
								if (auxCount == nil or auxCount <= 0) then
									auxCount = 1
								end
								extraDuration = extraDuration + (3 * auxCount)
							end
						end
					end
					SpecialAurasExtraInfo[145629][sourceGUID] = {
						timestamp = GetTime(),
						duration = 8 + extraDuration,
						expirationTime = GetTime() + 8 + extraDuration,
					}
					C_Timer.After((8 + extraDuration + 0.5), function()
						SpecialAurasExtraInfo[145629][sourceGUID] = nil
					end)
				end
			elseif (spellId == 78675) then	-- Solar Beam
				if (strfind(sourceGUID, "^Player-")) then
					SpecialAurasExtraInfo[81261][sourceGUID] = {
						timestamp = GetTime(),
						duration = 8,
						expirationTime = GetTime() + 8
					}
					C_Timer.After(8 + 0.5, function()
						SpecialAurasExtraInfo[81261][sourceGUID] = nil
					end)
				end
			elseif (spellId == 359053) then	-- Smoke Bomb
				if (strfind(sourceGUID, "^Player-")) then
					SpecialAurasExtraInfo[212183][sourceGUID] = {
						timestamp = GetTime(),
						duration = 5,
						expirationTime = GetTime() + 5
					}
					C_Timer.After(5 + 0.5, function()
						SpecialAurasExtraInfo[212183][sourceGUID] = nil
					end)
				end
			end
		end
		-- Check Cold Snap use
		if ((sourceGUID ~= nil) and (event == "SPELL_CAST_SUCCESS") and (spellId == 235219)) then
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
						self:UNIT_AURA(self.unitId, 3)
					end
				end)
			end
		end
	end
end

-- This is the main event. Check for (de)buffs and update the frame icon and cooldown.
function LoseControl:UNIT_AURA(unitId, typeUpdate) -- fired when a (de)buff is gained/lost
	if (((typeUpdate ~= nil and typeUpdate > 0) or (typeUpdate == nil and self.unitId == "targettarget") or (typeUpdate == nil and self.unitId == "focustarget")) and (self.lastTimeUnitAuraEvent == GetTime())) then return end
	if ((self.unitId == "targettarget" or self.unitId == "focustarget") and (not UnitIsUnit(unitId, self.unitId))) then return end
	local priority = LoseControlDB.priority
	local maxPriority = 1
	local maxExpirationTime = 0
	local maxPriorityIsInterrupt = false
	local Icon, Duration
	local forceEventUnitAuraAtEnd = false
	self.lastTimeUnitAuraEvent = GetTime()

	if ((self.anchor ~= nil and self.anchor:IsVisible() and (self.anchor ~= UIParent or self.frame.anchor == "None")) or (self.frame.anchor ~= "None" and self.frame.anchor ~= "Blizzard" and self.frame.anchor ~= "BlizzardRaidFrames" and self.anchor ~= UIParent)) and UnitExists(self.unitId) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetPlayerTargetTarget) or not(UnitIsUnit("player", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetTarget) or not(UnitIsUnit("targettarget", "player")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetTargetTarget) or not(UnitIsUnit("targettarget", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetDeadTargetTarget) or (UnitHealth("target") > 0))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disablePlayerFocusPlayerFocusTarget) or not(UnitIsUnit("player", "focus") and UnitIsUnit("player", "focustarget")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disablePlayerFocusTarget) or not(UnitIsUnit("focustarget", "player")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disableFocusFocusTarget) or not(UnitIsUnit("focustarget", "focus")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disableFocusDeadFocusTarget) or (UnitHealth("focus") > 0))) then
		local reactionToPlayer = (strfind(self.unitId, "arena") or ((self.unitId == "target" or self.unitId == "focus" or self.unitId == "targettarget" or self.unitId == "focustarget") and UnitCanAttack("player", unitId))) and "enemy" or "friendly"
		-- Check debuffs
		for i = 1, 120 do
			local localForceEventUnitAuraAtEnd = false
			local name, icon, _, _, duration, expirationTime, auraSource, _, _, spellId = UnitAura(unitId, i, "HARMFUL")
			if not spellId then break end -- no more debuffs, terminate the loop
			if (self.unitId == "targettarget") or (self.unitId == "focustarget") then
				if debug then print(unitId, "debuff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
			end
			
			if duration == 0 and expirationTime == 0 then
				expirationTime = GetTime() + 1 -- normal expirationTime = 0
			elseif expirationTime > 0 then
				localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
			end
			
			-- exceptions
			if spellId == 212183 then	-- Smoke Bomb
				local customSourceGUID
				if (auraSource == nil) then
					local lastCasterGUID, lastCasterUnit
					local lastCasterExpirationTime = 0
					local lastCasterEnemyOrUnknown = false
					for k, v in pairs(SpecialAurasExtraInfo[212183]) do
						if (k ~= playerGUID) then
							local iUnitId
							for _, w in pairs(LCframes) do
								if (UnitGUID(w.unitId) == k) then
									iUnitId = w.unitId
									break
								end
							end
							local isEnemyOrUnknown = (iUnitId == nil) or (UnitCanAttack(self.unitId, iUnitId))
							if (lastCasterEnemyOrUnknown) then
								if (isEnemyOrUnknown and (v.expirationTime > lastCasterExpirationTime)) then
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								end
							else
								if (isEnemyOrUnknown) then
									lastCasterEnemyOrUnknown = true
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								elseif (v.expirationTime > lastCasterExpirationTime) then
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								end
							end
						end
					end
					auraSource = lastCasterUnit
					customSourceGUID = lastCasterGUID
				end
				if (auraSource ~= nil or customSourceGUID ~= nil) then
					local auraSourceGUID = ((auraSource ~= nil) and UnitGUID(auraSource)) or customSourceGUID
					if ((auraSourceGUID ~= nil) and (strfind(auraSourceGUID, "^Player-"))) then
						if ((auraSource ~= nil) and (not UnitCanAttack(self.unitId, auraSource))) then
							spellId = 1
						elseif ((SpecialAurasExtraInfo[212183][auraSourceGUID] ~= nil) and (SpecialAurasExtraInfo[212183][auraSourceGUID].expirationTime > GetTime())) then
							duration = SpecialAurasExtraInfo[212183][auraSourceGUID].duration
							expirationTime = SpecialAurasExtraInfo[212183][auraSourceGUID].expirationTime
							localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
						end
					end
				end
			elseif spellId == 81261 then	-- Solar Beam
				local customSourceGUID
				if (auraSource == nil) then
					local lastCasterGUID, lastCasterUnit
					local lastCasterExpirationTime = 0
					local lastCasterEnemyOrUnknown = false
					for k, v in pairs(SpecialAurasExtraInfo[81261]) do
						if (k ~= playerGUID and k ~= UnitGUID(self.unitId)) then
							local iUnitId
							for _, w in pairs(LCframes) do
								if (UnitGUID(w.unitId) == k) then
									iUnitId = w.unitId
									break
								end
							end
							local isEnemyOrUnknown = (iUnitId == nil) or (UnitCanAttack(self.unitId, iUnitId))
							if (lastCasterEnemyOrUnknown) then
								if (isEnemyOrUnknown and (v.expirationTime > lastCasterExpirationTime)) then
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								end
							else
								if (isEnemyOrUnknown) then
									lastCasterEnemyOrUnknown = true
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								elseif (v.expirationTime > lastCasterExpirationTime) then
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								end
							end
						end
					end
					auraSource = lastCasterUnit
					customSourceGUID = lastCasterGUID
				end
				if (auraSource ~= nil or customSourceGUID ~= nil) then
					local auraSourceGUID = ((auraSource ~= nil) and UnitGUID(auraSource)) or customSourceGUID
					if ((auraSourceGUID ~= nil) and (strfind(auraSourceGUID, "^Player-"))) then
						if ((SpecialAurasExtraInfo[81261][auraSourceGUID] ~= nil) and (SpecialAurasExtraInfo[81261][auraSourceGUID].expirationTime > GetTime())) then
							duration = SpecialAurasExtraInfo[81261][auraSourceGUID].duration
							expirationTime = SpecialAurasExtraInfo[81261][auraSourceGUID].expirationTime
							localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
						end
					end
				end
			elseif spellId == 212638 then	-- Tracker's Net
				if (UnitIsPlayer(self.unitId)) then
					local _, _, class = UnitClass(self.unitId)
					if ((class == 5) or (class == 8) or (class == 9)) then
						spellId = 1
					elseif ((class == 7) or (class == 11)) then
						if (self.unitId == "player") then 
							local specID = GetSpecialization()
							if (specID ~= nil) then
								specID = GetSpecializationInfo(specID)
							end
							if ((specID ~= nil) and (specID ~= 0) and (specID ~= 263) and (specID ~= 103) and (specID ~= 104)) then
								spellId = 1
							end
						else
							local powerTypeID = UnitPowerType(self.unitId)
							if ((powerTypeID ~= nil) and (powerTypeID ~= 1) and (powerTypeID ~= 3) and (powerTypeID ~= 11)) then
								spellId = 1
							end
						end
					end
				end
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
			local name, icon, _, _, duration, expirationTime, auraSource, _, _, spellId, _, _, _, _, _, extraFlag1 = UnitAura(unitId, i) -- defaults to "HELPFUL" filter
			if not spellId then break end -- no more debuffs, terminate the loop
			if debug then print(unitId, "buff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
			
			if duration == 0 and expirationTime == 0 then
				expirationTime = GetTime() + 1 -- normal expirationTime = 0
			elseif expirationTime > 0 then
				localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
			end
			
			-- exceptions
			if spellId == 145629 then	-- Anti-Magic Zone
				if extraFlag1 <= 30 then
					newCategory = "Other"
				end
				local customSourceGUID
				if (auraSource == nil) then
					local lastCasterGUID, lastCasterUnit
					local lastCasterExpirationTime = 0
					local lastCasterFriendlyOrUnknown = false
					for k, v in pairs(SpecialAurasExtraInfo[145629]) do
						if (k ~= playerGUID) then
							local iUnitId
							for _, w in pairs(LCframes) do
								if (UnitGUID(w.unitId) == k) then
									iUnitId = w.unitId
									break
								end
							end
							local isFriendlyOrUnknown = (iUnitId == nil) or not(UnitCanAttack(self.unitId, iUnitId))
							if (lastCasterFriendlyOrUnknown) then
								if (isFriendlyOrUnknown and (v.expirationTime > lastCasterExpirationTime)) then
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								end
							else
								if (isFriendlyOrUnknown) then
									lastCasterFriendlyOrUnknown = true
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								elseif (v.expirationTime > lastCasterExpirationTime) then
									lastCasterUnit = iUnitId
									lastCasterGUID = k
									lastCasterExpirationTime = v.expirationTime
								end
							end
						end
					end
					auraSource = lastCasterUnit
					customSourceGUID = lastCasterGUID
				end
				if (auraSource ~= nil or customSourceGUID ~= nil) then
					local auraSourceGUID = ((auraSource ~= nil) and UnitGUID(auraSource)) or customSourceGUID
					if ((auraSourceGUID ~= nil) and (strfind(auraSourceGUID, "^Player-"))) then
						if ((SpecialAurasExtraInfo[145629][auraSourceGUID] ~= nil) and (SpecialAurasExtraInfo[145629][auraSourceGUID].expirationTime > GetTime())) then
							duration = SpecialAurasExtraInfo[145629][auraSourceGUID].duration
							expirationTime = SpecialAurasExtraInfo[145629][auraSourceGUID].expirationTime
							localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
						end
					end
				end
			elseif spellId == 209426 and not(self:ArePvpTalentsActive()) then	-- Darkness
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
		if ((self.unitGUID ~= nil) and (priority.Interrupt > 0) and self.frame.categoriesEnabled.interrupt[reactionToPlayer] and (UnitIsPlayer(self.unitId) or (((self.unitId ~= "target") or (LoseControlDB.showNPCInterruptsTarget)) and ((self.unitId ~= "focus") or (LoseControlDB.showNPCInterruptsFocus)) and ((self.unitId ~= "targettarget") or (LoseControlDB.showNPCInterruptsTargetTarget)) and ((self.unitId ~= "focustarget") or (LoseControlDB.showNPCInterruptsFocusTarget))))) then
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
					[64] = {false, 0},	-- Arcane
					[28] = {false, 0},	-- Elemental (Frost + Nature + Fire)
					[124] = {false, 0}	-- Chaos/Chromatic (Arcane + Shadow + Frost + Nature + Fire)
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
				if self.frame.enableElementalSchoolMiniIcon and spellSchoolInteruptsTable[28][1] then
					for schoolIntId, schoolIntInfo in pairs(spellSchoolInteruptsTable) do
						if ((schoolIntId ~= 28) and (bit_band(28, schoolIntId) >= schoolIntId) and (schoolIntInfo[1]) and (schoolIntInfo[2] <= spellSchoolInteruptsTable[28][2])) then
							spellSchoolInteruptsTable[schoolIntId][1] = false
							spellSchoolInteruptsTable[schoolIntId][2] = 0
						end
					end
				else
					spellSchoolInteruptsTable[28][1] = false
				end
				if self.frame.enableChaosSchoolMiniIcon and spellSchoolInteruptsTable[124][1] then
					for schoolIntId, schoolIntInfo in pairs(spellSchoolInteruptsTable) do
						if ((schoolIntId ~= 124) and (bit_band(124, schoolIntId) >= schoolIntId) and (schoolIntInfo[1]) and (schoolIntInfo[2] <= spellSchoolInteruptsTable[124][2])) then
							spellSchoolInteruptsTable[schoolIntId][1] = false
							spellSchoolInteruptsTable[schoolIntId][2] = 0
						end
					end
				else
					spellSchoolInteruptsTable[124][1] = false
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
				if (self.frame.enableElementalSchoolMiniIcon or self.frame.enableChaosSchoolMiniIcon) then
					for schoolIntId, schoolIntFrame in pairs(self.iconExtraInterruptList) do
						if spellSchoolInteruptsTable[schoolIntId] and spellSchoolInteruptsTable[schoolIntId][1] then
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

function LoseControl:PLAYER_FOCUS_CHANGED()
	--if (debug) then print("PLAYER_FOCUS_CHANGED") end
	if (self.unitId == "focus" or self.unitId == "focustarget") then
		self.unitGUID = UnitGUID(self.unitId)
		self:CheckAnchor(self.frame.anchor=="PitBullUF")
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -10)
		end
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
	if (self.unitId == "targettarget" or self.unitId == "focustarget") then
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
	o.iconInterruptElemental = o:CreateTexture(addonName .. unitId .. "InterruptIconElemental", "ARTWORK", nil, -1)
	o.iconInterruptElemental:SetTexture("Interface\\Icons\\Shaman_talent_elementalblast")
	o.iconInterruptChaos = o:CreateTexture(addonName .. unitId .. "InterruptIconChaos", "ARTWORK", nil, -1)
	o.iconInterruptChaos:SetTexture("Interface\\Icons\\Ability_warlock_chaosbolt")
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
	o.iconExtraInterruptList = {
		[28] = o.iconInterruptElemental,
		[124] = o.iconInterruptChaos
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
	for _, v in pairs(o.iconExtraInterruptList) do
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
	o:RegisterEvent("GROUP_ROSTER_UPDATE")
	o:RegisterEvent("GROUP_JOINED")
	o:RegisterEvent("GROUP_LEFT")
	o:RegisterEvent("ARENA_OPPONENT_UPDATE")
	o:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")

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

local DisableLossOfControlCooldownAuxText = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
DisableLossOfControlCooldownAuxText:SetText(L["NeedsReload"])
DisableLossOfControlCooldownAuxText:SetTextColor(1,0,0)
DisableLossOfControlCooldownAuxText:Hide()

local DisableLossOfControlCooldownAuxButton = CreateFrame("Button", O.."DisableLossOfControlCooldownAuxButton", OptionsPanel.container, "OptionsButtonTemplate")
_G[O.."DisableLossOfControlCooldownAuxButtonText"]:SetText(L["ReloadUI"])
DisableLossOfControlCooldownAuxButton:SetHeight(12)
DisableLossOfControlCooldownAuxButton:Hide()
DisableLossOfControlCooldownAuxButton:SetScript("OnClick", function(self)
	ReloadUI()
end)

local DisableLossOfControlCooldown = CreateFrame("CheckButton", O.."DisableLossOfControlCooldown", OptionsPanel.container, "OptionsCheckButtonTemplate")
_G[O.."DisableLossOfControlCooldownText"]:SetText(L["DisableLossOfControlCooldownText"])
DisableLossOfControlCooldown:SetScript("OnClick", function(self)
	LoseControlDB.noLossOfControlCooldown = self:GetChecked()
	LoseControl.noLossOfControlCooldown = LoseControlDB.noLossOfControlCooldown
	if (self:GetChecked()) then
		LoseControl:DisableLossOfControlUI()
		DisableLossOfControlCooldownAuxText:Hide()
		DisableLossOfControlCooldownAuxButton:Hide()
	else
		DisableLossOfControlCooldownAuxText:Show()
		DisableLossOfControlCooldownAuxButton:Show()
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

local BlizzardLossOfControl = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
BlizzardLossOfControl:SetText(L["BlizzardLossOfControl"])

local BlizzardLossOfControlCombatWarning = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
BlizzardLossOfControlCombatWarning:SetText(" - "..L["BlizzardLossOfControlCombatWarning"])
BlizzardLossOfControlCombatWarning:SetTextColor(1,0,0)
BlizzardLossOfControlCombatWarning:Hide()

local BlizzardLossOfControlDescription = OptionsPanel.container:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
BlizzardLossOfControlDescription:SetText(L["BlizzardLossOfControlDescription"])
BlizzardLossOfControlDescription:SetJustifyH("LEFT")

local BlizzardLossOfControlCC = CreateFrame("Frame", O.."BlizzardLossOfControlCC", OptionsPanel.container, "UIDropDownMenuTemplate")
function BlizzardLossOfControlCC:OnClick()
	if InCombatLockdown() then
		UIDropDownMenu_Initialize(BlizzardLossOfControlCC, BlizzardLossOfControlCC.initialize)
		UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlCC, GetCVar("lossOfControlFull"))
		return
	end
	local value = self.value or UIDropDownMenu_GetSelectedValue(BlizzardLossOfControlCC)
	UIDropDownMenu_Initialize(BlizzardLossOfControlCC, BlizzardLossOfControlCC.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlCC, value)
	SetCVar("lossOfControlFull", value)
end
UIDropDownMenu_Initialize(BlizzardLossOfControlCC, function() -- called on refresh and also every time the drop down menu is opened
	AddItem(BlizzardLossOfControlCC, L["Off"], "0")
	AddItem(BlizzardLossOfControlCC, L["Only Alert"], "1")
	AddItem(BlizzardLossOfControlCC, L["Show Full Duration"], "2")
end)
UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlCC, GetCVar("lossOfControlCC"))
UIDropDownMenu_SetWidth(BlizzardLossOfControlCC, 170)
BlizzardLossOfControlCCLabel = OptionsPanel.container:CreateFontString(O.."BlizzardLossOfControlCCLabel", "ARTWORK", "GameFontNormal")
BlizzardLossOfControlCCLabel:SetText(L["CC"]..":")

local BlizzardLossOfControlSilence = CreateFrame("Frame", O.."BlizzardLossOfControlSilence", OptionsPanel.container, "UIDropDownMenuTemplate")
function BlizzardLossOfControlSilence:OnClick()
	if InCombatLockdown() then
		UIDropDownMenu_Initialize(BlizzardLossOfControlSilence, BlizzardLossOfControlSilence.initialize)
		UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlSilence, GetCVar("lossOfControlSilence"))
		return
	end
	local value = self.value or UIDropDownMenu_GetSelectedValue(BlizzardLossOfControlSilence)
	UIDropDownMenu_Initialize(BlizzardLossOfControlSilence, BlizzardLossOfControlSilence.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlSilence, value)
	SetCVar("lossOfControlSilence", value)
end
UIDropDownMenu_Initialize(BlizzardLossOfControlSilence, function() -- called on refresh and also every time the drop down menu is opened
	AddItem(BlizzardLossOfControlSilence, L["Off"], "0")
	AddItem(BlizzardLossOfControlSilence, L["Only Alert"], "1")
	AddItem(BlizzardLossOfControlSilence, L["Show Full Duration"], "2")
end)
UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlSilence, GetCVar("lossOfControlSilence"))
UIDropDownMenu_SetWidth(BlizzardLossOfControlSilence, 170)
BlizzardLossOfControlSilenceLabel = OptionsPanel.container:CreateFontString(O.."BlizzardLossOfControlSilenceLabel", "ARTWORK", "GameFontNormal")
BlizzardLossOfControlSilenceLabel:SetText(L["Silence"]..":")

local BlizzardLossOfControlInterrupt = CreateFrame("Frame", O.."BlizzardLossOfControlInterrupt", OptionsPanel.container, "UIDropDownMenuTemplate")
function BlizzardLossOfControlInterrupt:OnClick()
	if InCombatLockdown() then
		UIDropDownMenu_Initialize(BlizzardLossOfControlInterrupt, BlizzardLossOfControlInterrupt.initialize)
		UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlInterrupt, GetCVar("lossOfControlInterrupt"))
		return
	end
	local value = self.value or UIDropDownMenu_GetSelectedValue(BlizzardLossOfControlInterrupt)
	UIDropDownMenu_Initialize(BlizzardLossOfControlInterrupt, BlizzardLossOfControlInterrupt.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlInterrupt, value)
	SetCVar("lossOfControlInterrupt", value)
end
UIDropDownMenu_Initialize(BlizzardLossOfControlInterrupt, function() -- called on refresh and also every time the drop down menu is opened
	AddItem(BlizzardLossOfControlInterrupt, L["Off"], "0")
	AddItem(BlizzardLossOfControlInterrupt, L["Only Alert"], "1")
	AddItem(BlizzardLossOfControlInterrupt, L["Show Full Duration"], "2")
end)
UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlInterrupt, GetCVar("lossOfControlInterrupt"))
UIDropDownMenu_SetWidth(BlizzardLossOfControlInterrupt, 170)
BlizzardLossOfControlInterruptLabel = OptionsPanel.container:CreateFontString(O.."BlizzardLossOfControlInterruptLabel", "ARTWORK", "GameFontNormal")
BlizzardLossOfControlInterruptLabel:SetText(L["Interrupt"]..":")

local BlizzardLossOfControlDisarm = CreateFrame("Frame", O.."BlizzardLossOfControlDisarm", OptionsPanel.container, "UIDropDownMenuTemplate")
function BlizzardLossOfControlDisarm:OnClick()
	if InCombatLockdown() then
		UIDropDownMenu_Initialize(BlizzardLossOfControlDisarm, BlizzardLossOfControlDisarm.initialize)
		UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlDisarm, GetCVar("lossOfControlDisarm"))
		return
	end
	local value = self.value or UIDropDownMenu_GetSelectedValue(BlizzardLossOfControlDisarm)
	UIDropDownMenu_Initialize(BlizzardLossOfControlDisarm, BlizzardLossOfControlDisarm.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlDisarm, value)
	SetCVar("lossOfControlDisarm", value)
end
UIDropDownMenu_Initialize(BlizzardLossOfControlDisarm, function() -- called on refresh and also every time the drop down menu is opened
	AddItem(BlizzardLossOfControlDisarm, L["Off"], "0")
	AddItem(BlizzardLossOfControlDisarm, L["Only Alert"], "1")
	AddItem(BlizzardLossOfControlDisarm, L["Show Full Duration"], "2")
end)
UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlDisarm, GetCVar("lossOfControlDisarm"))
UIDropDownMenu_SetWidth(BlizzardLossOfControlDisarm, 170)
BlizzardLossOfControlDisarmLabel = OptionsPanel.container:CreateFontString(O.."BlizzardLossOfControlDisarmLabel", "ARTWORK", "GameFontNormal")
BlizzardLossOfControlDisarmLabel:SetText(L["Disarm"]..":")

local BlizzardLossOfControlRoot = CreateFrame("Frame", O.."BlizzardLossOfControlRoot", OptionsPanel.container, "UIDropDownMenuTemplate")
function BlizzardLossOfControlRoot:OnClick()
	if InCombatLockdown() then
		UIDropDownMenu_Initialize(BlizzardLossOfControlRoot, BlizzardLossOfControlRoot.initialize)
		UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlRoot, GetCVar("lossOfControlRoot"))
		return
	end
	local value = self.value or UIDropDownMenu_GetSelectedValue(BlizzardLossOfControlRoot)
	UIDropDownMenu_Initialize(BlizzardLossOfControlRoot, BlizzardLossOfControlRoot.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlRoot, value)
	SetCVar("lossOfControlRoot", value)
end
UIDropDownMenu_Initialize(BlizzardLossOfControlRoot, function() -- called on refresh and also every time the drop down menu is opened
	AddItem(BlizzardLossOfControlRoot, L["Off"], "0")
	AddItem(BlizzardLossOfControlRoot, L["Only Alert"], "1")
	AddItem(BlizzardLossOfControlRoot, L["Show Full Duration"], "2")
end)
UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlRoot, GetCVar("lossOfControlRoot"))
UIDropDownMenu_SetWidth(BlizzardLossOfControlRoot, 170)
BlizzardLossOfControlRootLabel = OptionsPanel.container:CreateFontString(O.."BlizzardLossOfControlRootLabel", "ARTWORK", "GameFontNormal")
BlizzardLossOfControlRootLabel:SetText(L["Root"]..":")

local BlizzardLossOfControlGeneral = CreateFrame("CheckButton", O.."BlizzardLossOfControlGeneral", OptionsPanel.container, "OptionsCheckButtonTemplate")
_G[O.."BlizzardLossOfControlGeneralText"]:SetText(L["BlizzardLossOfControlGeneralTextUnchecked"])
BlizzardLossOfControlGeneral:SetScript("OnClick", function(self)
	if InCombatLockdown() then
		return self:SetChecked(GetCVarBool("lossOfControl"))
	end
	if (self:GetChecked()) then
		SetCVar("lossOfControl", "1", "LOSS_OF_CONTROL")
		_G[O.."BlizzardLossOfControlGeneralText"]:SetText(L["BlizzardLossOfControlGeneralTextChecked"])
	else
		SetCVar("lossOfControl", "0", "LOSS_OF_CONTROL")
		_G[O.."BlizzardLossOfControlGeneralText"]:SetText(L["BlizzardLossOfControlGeneralTextUnchecked"])
	end
	RefreshBlizzardLossOfControlOptionsEnabled(InCombatLockdown())
end)

RefreshBlizzardLossOfControlOptionsEnabled = function(inCombat)
	if (inCombat) then
		BlizzardLossOfControlGeneral:Disable()
		_G[O.."BlizzardLossOfControlGeneralText"]:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
		BlizzardLossOfControlCombatWarning:Show()
		UIDropDownMenu_DisableDropDown(BlizzardLossOfControlCC)
		UIDropDownMenu_DisableDropDown(BlizzardLossOfControlSilence)
		UIDropDownMenu_DisableDropDown(BlizzardLossOfControlInterrupt)
		UIDropDownMenu_DisableDropDown(BlizzardLossOfControlDisarm)
		UIDropDownMenu_DisableDropDown(BlizzardLossOfControlRoot)
	else
		BlizzardLossOfControlGeneral:Enable()
		_G[O.."BlizzardLossOfControlGeneralText"]:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		BlizzardLossOfControlCombatWarning:Hide()
		if (GetCVarBool("lossOfControl")) then
			UIDropDownMenu_EnableDropDown(BlizzardLossOfControlCC)
			UIDropDownMenu_EnableDropDown(BlizzardLossOfControlSilence)
			UIDropDownMenu_EnableDropDown(BlizzardLossOfControlInterrupt)
			UIDropDownMenu_EnableDropDown(BlizzardLossOfControlDisarm)
			UIDropDownMenu_EnableDropDown(BlizzardLossOfControlRoot)
		else
			UIDropDownMenu_DisableDropDown(BlizzardLossOfControlCC)
			UIDropDownMenu_DisableDropDown(BlizzardLossOfControlSilence)
			UIDropDownMenu_DisableDropDown(BlizzardLossOfControlInterrupt)
			UIDropDownMenu_DisableDropDown(BlizzardLossOfControlDisarm)
			UIDropDownMenu_DisableDropDown(BlizzardLossOfControlRoot)
		end
	end
end

-------------------------------------------------------------------------------
-- Arrange all the options neatly
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

Unlock:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
DisableCooldownCount:SetPoint("TOPLEFT", Unlock, "BOTTOMLEFT", 0, -2)
DisableBlizzardCooldownCount:SetPoint("TOPLEFT", DisableCooldownCount, "BOTTOMLEFT", 0, -2)
DisableLossOfControlCooldown:SetPoint("TOPLEFT", DisableBlizzardCooldownCount, "BOTTOMLEFT", 0, -2)
DisableLossOfControlCooldownAuxButton:SetPoint("TOPLEFT", DisableLossOfControlCooldown, "BOTTOMLEFT", 30, 4)
DisableLossOfControlCooldownAuxText:SetPoint("TOPLEFT", DisableLossOfControlCooldownAuxButton, "TOPRIGHT", 4, 0)

Priority:SetPoint("TOPLEFT", DisableLossOfControlCooldownAuxButton, "BOTTOMLEFT", -30, -8)
PriorityDescription:SetPoint("TOPLEFT", Priority, "BOTTOMLEFT", 0, -8)
PrioritySlider.PvE:SetPoint("TOPLEFT", PriorityDescription, "BOTTOMLEFT", 0, -24)
PrioritySlider.Immune:SetPoint("TOPLEFT", PrioritySlider.PvE, "BOTTOMLEFT", 0, -24)
PrioritySlider.ImmuneSpell:SetPoint("TOPLEFT", PrioritySlider.Immune, "BOTTOMLEFT", 0, -24)
PrioritySlider.ImmunePhysical:SetPoint("TOPLEFT", PrioritySlider.ImmuneSpell, "BOTTOMLEFT", 0, -24)
PrioritySlider.CC:SetPoint("TOPLEFT", PrioritySlider.ImmunePhysical, "BOTTOMLEFT", 0, -24)
PrioritySlider.Silence:SetPoint("TOPLEFT", PrioritySlider.CC, "BOTTOMLEFT", 0, -24)
PrioritySlider.Interrupt:SetPoint("TOPLEFT", PrioritySlider.PvE, "TOPRIGHT", 40, 0)
PrioritySlider.Disarm:SetPoint("TOPLEFT", PrioritySlider.Interrupt, "BOTTOMLEFT", 0, -24)
PrioritySlider.Root:SetPoint("TOPLEFT", PrioritySlider.Disarm, "BOTTOMLEFT", 0, -24)
PrioritySlider.Snare:SetPoint("TOPLEFT", PrioritySlider.Root, "BOTTOMLEFT", 0, -24)
PrioritySlider.Other:SetPoint("TOPLEFT", PrioritySlider.Snare, "BOTTOMLEFT", 0, -24)

BlizzardLossOfControl:SetPoint("TOPLEFT", PriorityDescription, "BOTTOMLEFT", 0, -270)
BlizzardLossOfControlCombatWarning:SetPoint("LEFT", BlizzardLossOfControl, "RIGHT", 0, 0)
BlizzardLossOfControlDescription:SetPoint("TOPLEFT", BlizzardLossOfControl, "BOTTOMLEFT", 0, -8)
BlizzardLossOfControlGeneral:SetPoint("TOPLEFT", BlizzardLossOfControlDescription, "BOTTOMLEFT", 0, -10)
BlizzardLossOfControlCCLabel:SetPoint("TOPLEFT", BlizzardLossOfControlGeneral, "BOTTOMLEFT", 0, -16)
BlizzardLossOfControlCC:SetPoint("LEFT", BlizzardLossOfControlCCLabel, "LEFT", 75, 0)
BlizzardLossOfControlSilenceLabel:SetPoint("TOPLEFT", BlizzardLossOfControlCCLabel, "BOTTOMLEFT", 0, -20)
BlizzardLossOfControlSilence:SetPoint("LEFT", BlizzardLossOfControlSilenceLabel, "LEFT", 75, 0)
BlizzardLossOfControlInterruptLabel:SetPoint("TOPLEFT", BlizzardLossOfControlSilenceLabel, "BOTTOMLEFT", 0, -20)
BlizzardLossOfControlInterrupt:SetPoint("LEFT", BlizzardLossOfControlInterruptLabel, "LEFT", 75, 0)
BlizzardLossOfControlDisarmLabel:SetPoint("TOPLEFT", BlizzardLossOfControlInterruptLabel, "BOTTOMLEFT", 0, -20)
BlizzardLossOfControlDisarm:SetPoint("LEFT", BlizzardLossOfControlDisarmLabel, "LEFT", 75, 0)
BlizzardLossOfControlRootLabel:SetPoint("TOPLEFT", BlizzardLossOfControlDisarmLabel, "BOTTOMLEFT", 0, -20)
BlizzardLossOfControlRoot:SetPoint("LEFT", BlizzardLossOfControlRootLabel, "LEFT", 75, 0)

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
	DisableLossOfControlCooldown:SetChecked(LoseControlDB.noLossOfControlCooldown)
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
	local lossOfControlGeneralEnabled = GetCVarBool("lossOfControl")
	BlizzardLossOfControlGeneral:SetChecked(lossOfControlGeneralEnabled)
	if lossOfControlGeneralEnabled then
		_G[O.."BlizzardLossOfControlGeneralText"]:SetText(L["BlizzardLossOfControlGeneralTextChecked"])
	else
		_G[O.."BlizzardLossOfControlGeneralText"]:SetText(L["BlizzardLossOfControlGeneralTextUnchecked"])
	end
	RefreshBlizzardLossOfControlOptionsEnabled(InCombatLockdown())
	UIDropDownMenu_Initialize(BlizzardLossOfControlCC, BlizzardLossOfControlCC.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlCC, GetCVar("lossOfControlFull"))
	UIDropDownMenu_Initialize(BlizzardLossOfControlSilence, BlizzardLossOfControlSilence.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlSilence, GetCVar("lossOfControlSilence"))
	UIDropDownMenu_Initialize(BlizzardLossOfControlInterrupt, BlizzardLossOfControlInterrupt.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlInterrupt, GetCVar("lossOfControlInterrupt"))
	UIDropDownMenu_Initialize(BlizzardLossOfControlDisarm, BlizzardLossOfControlDisarm.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlDisarm, GetCVar("lossOfControlDisarm"))
	UIDropDownMenu_Initialize(BlizzardLossOfControlRoot, BlizzardLossOfControlRoot.initialize)
	UIDropDownMenu_SetSelectedValue(BlizzardLossOfControlRoot, GetCVar("lossOfControlRoot"))
end

InterfaceOptions_AddCategory(OptionsPanel)

-------------------------------------------------------------------------------
-- Create sub-option frames
for _, v in ipairs({ "player", "pet", "target", "targettarget", "focus", "focustarget", "party", "arena", "raid" }) do
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
	OptionsPanelFrame.scrollchild:SetSize(623, 720)

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
		local unitId = v
		if v == "party" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])
		elseif v == "arena" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])
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
		elseif v == "arena" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			unitId = UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
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
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
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
	if v == "target" or v == "focus" or v == "targettarget" or v == "focustarget"  then
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
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
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
				LCframes[v]:UNIT_AURA(LCframes[v].unitId, 0)
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
			for _, w in pairs(LCframes[frame].iconExtraInterruptList) do
				w:SetAlpha(value / 100)
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
				for _, w in pairs(LCframeplayer2.iconExtraInterruptList) do
					w:SetAlpha(value / 100)
				end
				for _, w in ipairs(LCframeplayer2.iconQueueInterruptList) do
					w:SetAlpha(value / 100)
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
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
	
	local EnableElementalSchoolMiniIcon = CreateFrame("CheckButton", OptionsPanelFrame:GetName().."EnableElementalSchoolMiniIcon", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
	_G[OptionsPanelFrame:GetName().."EnableElementalSchoolMiniIconText"]:SetText(L["EnableElementalSchoolMiniIcon"])
	function EnableElementalSchoolMiniIcon:Check(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].enableElementalSchoolMiniIcon = self:GetChecked()
			for _, v in pairs(LCframes[frame].iconInterruptList) do
				v:Hide()
			end
			for _, v in pairs(LCframes[frame].iconExtraInterruptList) do
				v:Hide()
			end
			for _, v in ipairs(LCframes[frame].iconQueueInterruptList) do
				v:Hide()
			end
			LCframes[frame].maxExpirationTime = 0
			if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.enableElementalSchoolMiniIcon = self:GetChecked()
				for _, v in pairs(LCframeplayer2.iconInterruptList) do
					v:Hide()
				end
				for _, v in pairs(LCframeplayer2.iconExtraInterruptList) do
					v:Hide()
				end
				for _, v in ipairs(LCframeplayer2.iconQueueInterruptList) do
					v:Hide()
				end
				LCframeplayer2.maxExpirationTime = 0
				if LoseControlDB.frames.player2.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
				end
			end
		end
	end
	EnableElementalSchoolMiniIcon:SetScript("OnClick", function(self)
		EnableElementalSchoolMiniIcon:Check(self:GetChecked())
	end)
	
	local EnableChaosSchoolMiniIcon = CreateFrame("CheckButton", OptionsPanelFrame:GetName().."EnableChaosSchoolMiniIcon", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
	_G[OptionsPanelFrame:GetName().."EnableChaosSchoolMiniIconText"]:SetText(L["EnableChaosSchoolMiniIcon"])
	function EnableChaosSchoolMiniIcon:Check(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4", "partyplayer" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].enableChaosSchoolMiniIcon = self:GetChecked()
			for _, v in pairs(LCframes[frame].iconInterruptList) do
				v:Hide()
			end
			for _, v in pairs(LCframes[frame].iconExtraInterruptList) do
				v:Hide()
			end
			for _, v in ipairs(LCframes[frame].iconQueueInterruptList) do
				v:Hide()
			end
			LCframes[frame].maxExpirationTime = 0
			if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.enableChaosSchoolMiniIcon = self:GetChecked()
				for _, v in pairs(LCframeplayer2.iconInterruptList) do
					v:Hide()
				end
				for _, v in pairs(LCframeplayer2.iconExtraInterruptList) do
					v:Hide()
				end
				for _, v in ipairs(LCframeplayer2.iconQueueInterruptList) do
					v:Hide()
				end
				LCframeplayer2.maxExpirationTime = 0
				if LoseControlDB.frames.player2.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
				end
			end
		end
	end
	EnableChaosSchoolMiniIcon:SetScript("OnClick", function(self)
		EnableChaosSchoolMiniIcon:Check(self:GetChecked())
	end)
	
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
		end
		if (EnableElementalSchoolMiniIcon and EnableChaosSchoolMiniIcon) then
			if (value) then
				BlizzardOptionsPanel_CheckButton_Disable(EnableElementalSchoolMiniIcon)
				BlizzardOptionsPanel_CheckButton_Disable(EnableChaosSchoolMiniIcon)
			else
				BlizzardOptionsPanel_CheckButton_Enable(EnableElementalSchoolMiniIcon)
				BlizzardOptionsPanel_CheckButton_Enable(EnableChaosSchoolMiniIcon)
			end
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].useSpellInsteadSchoolMiniIcon = self:GetChecked()
			for _, v in pairs(LCframes[frame].iconInterruptList) do
				v:Hide()
			end
			for _, v in pairs(LCframes[frame].iconExtraInterruptList) do
				v:Hide()
			end
			for _, v in ipairs(LCframes[frame].iconQueueInterruptList) do
				v:Hide()
			end
			LCframes[frame].maxExpirationTime = 0
			if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.useSpellInsteadSchoolMiniIcon = self:GetChecked()
				for _, v in pairs(LCframeplayer2.iconInterruptList) do
					v:Hide()
				end
				for _, v in pairs(LCframeplayer2.iconExtraInterruptList) do
					v:Hide()
				end
				for _, v in ipairs(LCframeplayer2.iconQueueInterruptList) do
					v:Hide()
				end
				LCframeplayer2.maxExpirationTime = 0
				if LoseControlDB.frames.player2.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(LCframeplayer2.unitId, 0)
				end
			end
		end
	end
	UseSpellInsteadSchoolMiniIcon:SetScript("OnClick", function(self)
		UseSpellInsteadSchoolMiniIcon:Check(self:GetChecked())
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
	end
	if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or v == "arena" then
		local EnemyInterrupt = CreateFrame("CheckButton", O..v.."EnemyInterrupt", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
		EnemyInterrupt:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."EnemyInterruptText"]:SetText(L["CatEnemy"])
		EnemyInterrupt:SetScript("OnClick", function(self)
			local frames = { v }
			if v == "arena" then
				frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
			end
			for _, frame in ipairs(frames) do
				LoseControlDB.frames[frame].categoriesEnabled.interrupt.enemy = self:GetChecked()
				LCframes[frame].maxExpirationTime = 0
				if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
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
		end
		if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or v == "arena" then
			local EnemyBuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Buff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			EnemyBuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Enemy"..cat.."BuffText"]:SetText(L["CatEnemyBuff"])
			EnemyBuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "arena" then
					frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.buff.enemy[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = EnemyBuff, auraType = "buff", reaction = "enemy", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = (v ~= "arena" and 270 or 140), yPos = 5 })
		end
		if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or v == "arena" then
			local EnemyDebuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Debuff", OptionsPanelFrame.container, "OptionsCheckButtonTemplate")
			EnemyDebuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Enemy"..cat.."DebuffText"]:SetText(L["CatEnemyDebuff"])
			EnemyDebuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "arena" then
					frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.debuff.enemy[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(LCframes[frame].unitId, 0)
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
		if (frame.useSpellInsteadSchoolMiniIcon) then
			BlizzardOptionsPanel_CheckButton_Disable(EnableElementalSchoolMiniIcon)
			BlizzardOptionsPanel_CheckButton_Disable(EnableChaosSchoolMiniIcon)
		else
			BlizzardOptionsPanel_CheckButton_Enable(EnableElementalSchoolMiniIcon)
			BlizzardOptionsPanel_CheckButton_Enable(EnableChaosSchoolMiniIcon)
		end
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
		if AnchorPositionArenaDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionArenaDropDown) end
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
		BlizzardOptionsPanel_CheckButton_Disable(EnableElementalSchoolMiniIcon)
		BlizzardOptionsPanel_CheckButton_Disable(EnableChaosSchoolMiniIcon)
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
			end
			EnableInterfaceFrames(LoseControlDB.frames[unitIdSel])
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

	Enabled:SetPoint("TOPLEFT", 16, -12)
	if DisableInBG then DisableInBG:SetPoint("TOPLEFT", Enabled, 220, ((v == "party") and -25 or 0)) end
	if DisableInArena then DisableInArena:SetPoint("TOPLEFT", Enabled, 220, ((v == "party") and -50 or -25)) end
	if DisableInRaid then DisableInRaid:SetPoint("TOPLEFT", Enabled, 220, ((v == "party") and -75 or -50)) end
	if ShowNPCInterrupts then ShowNPCInterrupts:SetPoint("TOPLEFT", Enabled, 220, 0) end
	if DisablePlayerTargetTarget then DisablePlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 220, -25) end
	if DisableTargetTargetTarget then DisableTargetTargetTarget:SetPoint("TOPLEFT", Enabled, 220, -50) end
	if DisablePlayerTargetPlayerTargetTarget then DisablePlayerTargetPlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 220, -75) end
	if DisableTargetDeadTargetTarget then DisableTargetDeadTargetTarget:SetPoint("TOPLEFT", Enabled, 220, -100) end
	if DisableFocusFocusTarget then DisableFocusFocusTarget:SetPoint("TOPLEFT", Enabled, 220, -50) end
	if DisablePlayerFocusPlayerFocusTarget then DisablePlayerFocusPlayerFocusTarget:SetPoint("TOPLEFT", Enabled, 220, -75) end
	if DisableFocusDeadFocusTarget then DisableFocusDeadFocusTarget:SetPoint("TOPLEFT", Enabled, 220, -100) end
	if DuplicatePlayerPortrait then DuplicatePlayerPortrait:SetPoint("TOPLEFT", Enabled, 290, 0) end
	if EnabledPartyPlayerIcon then EnabledPartyPlayerIcon:SetPoint("TOPLEFT", Enabled, 220, 0) end
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
	EnableElementalSchoolMiniIcon:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 280, -50)
	EnableChaosSchoolMiniIcon:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 280, -75)
	UseSpellInsteadSchoolMiniIcon:SetPoint("TOPLEFT", AdditionalOptionsLabel, "BOTTOMLEFT", 280, -100)
	if SizeSlider2 then SizeSlider2:SetPoint("TOPLEFT", Enabled, "BOTTOMLEFT", 290, -32) end
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
		end
		LCframes[unitId]:CheckAnchor(true)
		EnableElementalSchoolMiniIcon:SetChecked(LoseControlDB.frames[unitId].enableElementalSchoolMiniIcon)
		EnableChaosSchoolMiniIcon:SetChecked(LoseControlDB.frames[unitId].enableChaosSchoolMiniIcon)
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
	print("<unit> can be: player, pet, target, focus, targettarget, focustarget, party1 ... party4, arena1 ... arena5, raid1 ... raid40")
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
	for _, v in ipairs({ "player", "pet", "target", "targettarget", "focus", "focustarget", "party", "arena", "raid" }) do
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
