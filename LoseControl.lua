--[[
-------------------------------------------
-- Addon: LoseControl
-- Version: 6.10
-- Authors: Kouri, millanzarreta
-------------------------------------------

-- Changelog:

No more changelogs in this file. To consult the last changes check https://www.curseforge.com/wow/addons/losecontrol/changes

Updated for 8.0.1
- Added more PvE spells (Uldir Raid, BfA Mythics and BfA Island Expeditions)
- Added ImmunePhysical category
- Added Interrupt category
- Fixed some minor bugs

Updated for 7.3.0 by millanzarreta
- Added Antorus Raid spells
- Added The Seat of the Triumvirate spells

Updated for 7.2.5 by millanzarreta
- Updated the spellID list to reflect the class changes
- Added more PvE spells (ToS Raid, Chromie Scenario)

Updated for 7.2.0 by millanzarreta
- Updated the spell ID list to reflect the class changes
- Added a large amount of PvE spells (EN Raid, ToV Raid, NH Raid and Legions Mythics) to spell ID list
- Added new option to allows hide party frames when the player is in raid group (never in arena)
- Improved the code to detect automatically the debuffs without defined duration (before, we had to add manually the spellId to the list)
- Fixed an error that could cause the icon to not display properly when the effect have not a defined time

Updated for 7.1.0 by millanzarreta
- Added most spells to spell ID list and corrected others (a lot of work, really...)
- Fixed the problem with spells that were not showing correctly (spells without duration, such as Solar Beam, Grounding Totem, Smoke Bomb, ...)
- Added new option to allows manage the blizzard cooldown countdown
- Added new option to allows remove the cooldown on bars for CC effects (tested for default Bars and Bartender4 Bars)
- Fixed a bug: now type /lc opens directly the LoseControl panel instead of Interface panel

Updated for 7.0.3 (Legion) by Hid@Emeriss and Wardz
- Added a large amount of spells, hopefully I didn't miss anything (important)
- Removed spell IDs that no longer exists.
- Added Ice Nova (mage) and Rake (druid) to spell ID list
- Fixed cooldown spiral

-- Code Credits - to the people whose code I borrowed and learned from:

Wowwiki
Kollektiv
Tuller
ckknight
The authors of Nao!!
And of course, Blizzard

Thanks! :)
]]

local addonName, L = ...
local UIParent = UIParent -- it's faster to keep local references to frequently used global vars
local UnitAura = UnitAura
local GetTime = GetTime
local SetPortraitToTexture = SetPortraitToTexture
local ipairs = ipairs
local pairs = pairs
local next = next
local strfind = string.find
local tblinsert = table.insert
local bit_band = bit.band
local SetScript = SetScript
local OnEvent = OnEvent
local CreateFrame = CreateFrame
local SetTexture = SetTexture
local SetCooldown = SetCooldown
local SetAlpha, SetPoint = SetAlpha, SetPoint
local print = print
local debug = false -- type "/lc debug on" if you want to see UnitAura info logged to the console
local LCframes = {}
local InterruptAuras = { }

-------------------------------------------------------------------------------
-- Thanks to all the people on the Curse.com and WoWInterface forums who help keep this list up to date :)

local interruptsIds = {
	[1766]   = 5,		-- Kick (Rogue)
	[2139]   = 6,		-- Counterspell (Mage)
	[6552]   = 4,		-- Pummel (Warrior)
	[13491]  = 5,		-- Pummel (Iron Knuckles Item)
	[19647]  = 6,		-- Spell Lock (felhunter) (Warlock)
	[29443]  = 10,		-- Counterspell (Clutch of Foresight)
	[47528]  = 3,		-- Mind Freeze (Death Knight)
	[57994]  = 3,		-- Wind Shear (Shaman)
	[91802]  = 2,		-- Shambling Rush (Death Knight)
	[96231]  = 4,		-- Rebuke (Paladin)
	[93985]  = 4,		-- Skull Bash (Druid Feral)
	[97547]  = 5,		-- Solar Beam (Druid Balance)
	[115781] = 6,		-- Optical Blast (Warlock)
	[116705] = 4,		-- Spear Hand Strike (Monk)
	[132409] = 6,		-- Spell Lock (command demon) (Warlock)
	[147362] = 3,		-- Countershot (Hunter)
	[183752] = 3,		-- Consume Magic (Demon Hunter)
	[187707] = 3,		-- Muzzle (Hunter)
	[212619] = 6,		-- Call Felhunter (Warlock)
	[217824] = 4,		-- Shield of Virtue (Protec Paladin)
	[231665] = 3,		-- Avengers Shield (Paladin)
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
	[206649] = "Silence",			-- Eye of Leotheras (no silence, 4% dmg and duration reset for spell casted)
	[232538] = "Snare",				-- Rain of Chaos
	[213405] = "Snare",				-- Master of the Glaive
	[210003] = "Snare",				-- Razor Spikes
	[198813] = "Snare",				-- Vengeful Retreat
	[198589] = "Other",				-- Blur
	
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
	[287081] = "Other",				-- Lichborne
	[145629] = "ImmuneSpell",		-- Anti-Magic Zone (not immune, 60% damage reduction)
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
	[206930] = "Snare",				-- Heart Strike
	[228645] = "Snare",				-- Heart Strike
	[211831] = "Snare",				-- Abomination's Might (slow)
	[200646] = "Snare",				-- Unholy Mutation
	[143375] = "Snare",				-- Tightening Grasp
	[211793] = "Snare",				-- Remorseless Winter
	[208278] = "Snare",				-- Debilitating Infestation
	[212764] = "Snare",				-- White Walker
	[190780] = "Snare",				-- Frost Breath (Sindragosa's Fury) (artifact trait)
	[191719] = "Snare",				-- Gravitational Pull (artifact trait)
	[204206] = "Snare",				-- Chill Streak (pvp honor talent)
	
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
	[209753] = "CC",				-- Cyclone
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
	[58180]  = "Snare",				-- Infected Wounds
	[61391]  = "Snare",				-- Typhoon
	[127797] = "Snare",				-- Ursol's Vortex
	[102543] = "Other",				-- Incarnation: King of the Jungle
	[106951] = "Other",				-- Berserk
	[102558] = "Other",				-- Incarnation: Guardian of Ursoc
	[102560] = "Other",				-- Incarnation: Chosen of Elune
	[202244] = "CC",				-- Overrun (pvp honor talent)
	[209749] = "Disarm",			-- Faerie Swarm (pvp honor talent)
	
	----------------
	-- Hunter
	----------------
	[117526] = "Root",				-- Binding Shot
	[3355]   = "CC",				-- Freezing Trap
	[13809]  = "CC",				-- Ice Trap 1
	[195645] = "Snare",				-- Wing Clip
	[19386]  = "CC",				-- Wyvern Sting
	[128405] = "Root",				-- Narrow Escape
	[201158] = "Root",				-- Super Sticky Tar (root)
	[111735] = "Snare",				-- Tar
	[135299] = "Snare",				-- Tar Trap
	[5116]   = "Snare",				-- Concussive Shot
	[194279] = "Snare",				-- Caltrops
	[206755] = "Snare",				-- Ranger's Net (snare)
	[236699] = "Snare",				-- Super Sticky Tar (slow)
	[213691] = "CC",				-- Scatter Shot (pvp honor talent)
	[186265] = "Immune",			-- Deterrence (aspect of the turtle)
	[19574]  = "ImmuneSpell",		-- Bestial Wrath (only if The Beast Within (212704) it's active) (immune to some CC's)
	[190927] = "Root",				-- Harpoon
	[212331] = "Root",				-- Harpoon
	[212353] = "Root",				-- Harpoon
	[162480] = "Root",				-- Steel Trap
	[200108] = "Root",				-- Ranger's Net
	[212638] = "CC",				-- Tracker's Net (pvp honor talent) -- Also -80% hit chance melee & range physical (CC and Root category)
	[186387] = "Snare",				-- Bursting Shot
	[224729] = "Snare",				-- Bursting Shot
	[266779] = "Other",				-- Coordinated Assault
	[203337] = "CC",				-- Freezing Trap (Diamond Ice - pvp honor talent)
	[202748] = "Immune",			-- Survival Tactics (pvp honor talent) (not immune, 99% damage reduction)
	[248519] = "ImmuneSpell",		-- Interlope (pvp honor talent)
	--[202914] = "Silence",			-- Spider Sting (pvp honor talent) --no silence, this its the previous effect
	[202933] = "Silence",			-- Spider Sting	(pvp honor talent) --this its the silence effect
	[5384]   = "Other",				-- Feign Death
	
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
	[44572]  = "CC",				-- Deep Freeze
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
	[111340] = "Root",				-- Ice Ward
	[120]    = "Snare",				-- Cone of Cold
	[116]    = "Snare",				-- Frostbolt
	[44614]  = "Snare",				-- Frostfire Bolt
	[31589]  = "Snare",				-- Slow
	[10]     = "Snare",				-- Blizzard
	[205708] = "Snare",				-- Chilled
	[212792] = "Snare",				-- Cone of Cold
	[205021] = "Snare",				-- Ray of Frost
	[135029] = "Snare",				-- Water Jet
	[59638]  = "Snare",				-- Frostbolt (Mirror Images)
	[228354] = "Snare",				-- Flurry
	[157981] = "Snare",				-- Blast Wave
	[2120]   = "Snare",				-- Flamestrike
	[236299] = "Snare",				-- Chrono Shift
	[45438]  = "Immune",			-- Ice Block
	[198121] = "Root",				-- Frostbite (pvp talent)
	[220107] = "Root",				-- Frostbite
	[157997] = "Root",				-- Ice Nova
	[228600] = "Root",				-- Glacial Spike
	[110959] = "Other",				-- Greater Invisibility
	[198144] = "Other",				-- Ice form (stun/knockback immune)
	[12042]  = "Other",				-- Arcane Power
	[190319] = "Other",				-- Combustion
	[198111] = "Immune",			-- Temporal Shield (heals all damage taken after 4 sec)

		----------------
		-- Mage Water Elemental
		----------------
		[33395]  = "Root",				-- Freeze

	----------------
	-- Monk
	----------------
	[123393] = "CC",				-- Breath of Fire (Glyph of Breath of Fire)
	[119392] = "CC",				-- Charging Ox Wave
	[119381] = "CC",				-- Leg Sweep
	[115078] = "CC",				-- Paralysis
	[116706] = "Root",				-- Disable
	[116095] = "Snare",				-- Disable
	[118585] = "Snare",				-- Leer of the Ox
	[123586] = "Snare",				-- Flying Serpent Kick
	[121253] = "Snare",				-- Keg Smash
	[196733] = "Snare",				-- Special Delivery
	[205320] = "Snare",				-- Strike of the Windlord (artifact trait)
	[125174] = "Immune",			-- Touch of Karma
	[122783] = "ImmuneSpell",		-- Diffuse Magic (not immune, 60% magic damage reduction)
	[198909] = "CC",				-- Song of Chi-Ji
	[233759] = "Disarm",			-- Grapple Weapon
	[202274] = "CC",				-- Incendiary Brew (honor talent)
	[202346] = "CC",				-- Double Barrel (honor talent)
	[123407] = "Root",				-- Spinning Fire Blossom (honor talent)
	[214326] = "Other",				-- Exploding Keg (artifact trait - blind)
	[213664] = "Other",				-- Nimble Brew
	[209584] = "Other",				-- Zen Focus Tea
	[216113] = "Other",				-- Way of the Crane
	[137639] = "Other",				-- Storm, Earth, and Fire
	[152173] = "Other",				-- Serenity
	[199387] = "Snare",				-- Spirit Tether (artifact trait)

	----------------
	-- Paladin
	----------------
	[105421] = "CC",				-- Blinding Light
	[105593] = "CC",				-- Fist of Justice
	[853]    = "CC",				-- Hammer of Justice
	[20066]  = "CC",				-- Repentance
	[31935]  = "Silence",			-- Avenger's Shield
	[187219] = "Silence",			-- Avenger's Shield (pvp talent)
	[199512] = "Silence",			-- Avenger's Shield (unknow use)
	[217824] = "Silence",			-- Shield of Virtue (pvp honor talent)
	[204242] = "Snare",				-- Consecration (talent Consecrated Ground)
	[183218] = "Snare",				-- Hand of Hindrance
	[642]    = "Immune",			-- Divine Shield
	[184662] = "Other",				-- Shield of Vengeance
	[31821]  = "Other",				-- Aura Mastery
	[210256] = "Other",				-- Blessing of Sanctuary
	[210294] = "Other",				-- Divine Favor
	[1022]   = "ImmunePhysical",	-- Hand of Protection
	[204018] = "ImmuneSpell",		-- Blessing of Spellwarding
	[31884]  = "Other",				-- Avenging Wrath
	[216331] = "Other",				-- Avenging Crusader
	[228050] = "Immune",			-- Divine Shield (Guardian of the Forgotten Queen)
	[205273] = "Snare",				-- Wake of Ashes (artifact trait) (snare)
	[205290] = "CC",				-- Wake of Ashes (artifact trait) (stun)
	[255937] = "Snare",				-- Wake of Ashes (talent) (snare)
	[255941] = "CC",				-- Wake of Ashes (talent) (stun)
	[199448] = "Immune",			-- Blessing of Sacrifice (Ultimate Sacrifice pvp talent) (not immune, 100% damage transfered to paladin)

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
	[87194]  = "Root",				-- Glyph of Mind Blast
	[114404] = "Root",				-- Void Tendril's Grasp
	[15407]  = "Snare",				-- Mind Flay
	[47585]  = "Immune",			-- Dispersion
	[47788]  = "Other",				-- Guardian Spirit (prevent the target from dying)
	[213602] = "Immune",			-- Greater Fade (pvp honor talent - protects vs spells. melee, ranged attacks + 50% speed)
	[232707] = "Immune",			-- Ray of Hope (pvp honor talent - not immune, only delay damage and heal)
	[213610] = "Other",				-- Holy Ward (pvp honor talent - wards against the next loss of control effect)
	[289655] = "Other",				-- Holy Word: Concentration
	[226943] = "CC",				-- Mind Bomb
	[200196] = "CC",				-- Holy Word: Chastise
	[200200] = "CC",				-- Holy Word: Chastise (talent)
	[204263] = "Snare",				-- Shining Force
	[199845] = "Snare",				-- Psyflay (pvp honor talent - Psyfiend)
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
	[185763] = "Snare",				-- Pistol Shot
	[185778] = "Snare",				-- Shellshocked
	[206760] = "Snare",				-- Night Terrors
	[222775] = "Snare",				-- Strike from the Shadows (daze effect)
	[152150] = "Immune",			-- Death from Above (in the air you are immune to CC)
	[31224]  = "ImmuneSpell",		-- Cloak of Shadows
	[51690]  = "Other",				-- Killing Spree
	[13750]  = "Other",				-- Adrenaline Rush
	[199754] = "Other",				-- Riposte
	[1966]   = "Other",				-- Feint
	[121471] = "Other",				-- Shadow Blades
	[45182]  = "Immune",			-- Cheating Death (-85% damage taken)
	[5277]   = "Other",				-- Evasion
	[212183] = "Other",				-- Smoke Bomb
	[199804] = "CC",				-- Between the eyes
	[199740] = "CC",				-- Bribe
	[207777] = "Disarm",			-- Dismantle
	[185767] = "Snare",				-- Cannonball Barrage
	[207736] = "Other",				-- Shadowy Duel
	[212150] = "CC",				-- Cheap Tricks (pvp honor talent) (-75%  melee & range physical hit chance)
	[199743] = "CC",				-- Parley
	[198222] = "Snare",				-- System Shock (pvp honor talent) (90% slow)
	[226364] = "Other",				-- Evasion (Shadow Swiftness, artifact trait)
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
	[118905] = "CC",				-- Static Charge (Capacitor Totem)
	[64695]  = "Root",				-- Earthgrab (Earthgrab Totem)
	[3600]   = "Snare",				-- Earthbind (Earthbind Totem)
	[116947] = "Snare",				-- Earthbind (Earthgrab Totem)
	[77478]  = "Snare",				-- Earthquake (Glyph of Unstable Earth)
	[8056]   = "Snare",				-- Frost Shock
	[196840] = "Snare",				-- Frost Shock
	[51490]  = "Snare",				-- Thunderstorm
	[147732] = "Snare",				-- Frostbrand Attack
	[197385] = "Snare",				-- Fury of Air
	[207498] = "Other",				-- Ancestral Protection (prevent the target from dying)
	[290641] = "Other",				-- Ancestral Gift (PvP Talent) (immune to Silence and Interrupt effects)
	[108271] = "Other",				-- Astral Shift
	[114050] = "Other",				-- Ascendance (Elemental)
	[114051] = "Other",				-- Ascendance (Enhancement)
	[114052] = "Other",				-- Ascendance (Restoration)
	[8178]   = "ImmuneSpell",		-- Grounding Totem Effect (Grounding Totem)
	[204399] = "CC",				-- Earthfury (PvP Talent)
	[192058] = "CC",				-- Lightning Surge totem (capacitor totem)
	[210918] = "ImmunePhysical",	-- Ethereal Form
	[305485] = "CC",				-- Lightning Lasso
	[204437] = "CC",				-- Lightning Lasso
	[197214] = "CC",				-- Sundering
	[224126] = "Snare",				-- Frozen Bite (Doom Wolves, artifact trait)
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
	[110913] = "Other",				-- Dark Bargain
	[104773] = "Other",				-- Unending Resolve
	[113860] = "Other",				-- Dark Soul: Misery
	[113858] = "Other",				-- Dark Soul: Instability
	[212295] = "ImmuneSpell",		-- Netherward (reflects spells)
	[233582] = "Root",				-- Entrenched in Flame (pvp honor talent)

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
	[118895] = "CC",				-- Dragon Roar
	[5246]   = "CC",				-- Intimidating Shout (aoe)
	[132168] = "CC",				-- Shockwave
	[107570] = "CC",				-- Storm Bolt
	[132169] = "CC",				-- Storm Bolt
	[46968]  = "CC",				-- Shockwave
	[213427] = "CC",				-- Charge Stun Talent (Warbringer)
	[7922]   = "CC",				-- Charge Stun Talent (Warbringer)
	[237744] = "CC",				-- Charge Stun Talent (Warbringer)
	[107566] = "Root",				-- Staggering Shout
	[105771] = "Root",				-- Charge (root)
	[236027] = "Snare",				-- Charge (snare)
	[118000] = "Snare",				-- Dragon Roar
	[147531] = "Snare",				-- Bloodbath
	[1715]   = "Snare",				-- Hamstring
	[12323]  = "Snare",				-- Piercing Howl
	[6343]   = "Snare",				-- Thunder Clap
	[46924]  = "Immune",			-- Bladestorm (not immune to dmg, only to LoC)
	[227847] = "Immune",			-- Bladestorm (not immune to dmg, only to LoC)
	[199038] = "Immune",			-- Leave No Man Behind (not immune, 90% damage reduction)
	[218826] = "Immune",			-- Trial by Combat (warr fury artifact hidden trait) (only immune to death)
	[23920]  = "ImmuneSpell",		-- Spell Reflection
	[216890] = "ImmuneSpell",		-- Spell Reflection
	[213915] = "ImmuneSpell",		-- Mass Spell Reflection
	[114028] = "ImmuneSpell",		-- Mass Spell Reflection
	[18499]  = "Other",				-- Berserker Rage
	[107574] = "Other",				-- Avatar
	[262228] = "Other",				-- Deadly Calm
	[118038] = "Other",				-- Die by the Sword
	[198819] = "Other",				-- Sharpen Blade (70% heal reduction)
	[236321] = "Other",				-- War Banner
	[236438] = "Other",				-- War Banner
	[236439] = "Other",				-- War Banner
	[236273] = "Other",				-- Duel
	[198760] = "ImmunePhysical",	-- Intercept (pvp honor talent) (intercept the next ranged or melee hit)
	[176289] = "CC",				-- Siegebreaker
	[199085] = "CC",				-- Warpath
	[199042] = "Root",				-- Thunderstruck
	[236236] = "Disarm",			-- Disarm (pvp honor talent - protection)
	[236077] = "Disarm",			-- Disarm (pvp honor talent)
	
	----------------
	-- Other
	----------------
	[56]     = "CC",				-- Stun (low lvl weapons proc)
	[835]    = "CC",				-- Tidal Charm (trinket)
	[15534]  = "CC",				-- Polymorph (trinket)
	[15535]  = "CC",				-- Enveloping Winds (Six Demon Bag trinket)
	[23103]  = "CC",				-- Enveloping Winds (Six Demon Bag trinket)
	[25189]  = "CC",				-- Enveloping Winds (Six Demon Bag trinket)
	[30217]  = "CC",				-- Adamantite Grenade
	[67769]  = "CC",				-- Cobalt Frag Bomb
	[67890]  = "CC",				-- Cobalt Frag Bomb (belt)
	[30216]  = "CC",				-- Fel Iron Bomb
	[224074] = "CC",				-- Devilsaur's Bite (trinket)
	[127723] = "Root",				-- Covered In Watermelon (trinket)
	[42803]  = "Snare",				-- Frostbolt (trinket)
	[195342] = "Snare",				-- Shrink Ray (trinket)
	[20549]  = "CC",				-- War Stomp (tauren racial)
	[107079] = "CC",				-- Quaking Palm (pandaren racial)
	[255723] = "CC",				-- Bull Rush (highmountain tauren racial)
	[287712] = "CC",				-- Haymaker (kul tiran racial)
	[214459] = "Silence",			-- Choking Flames (trinket)
	[19821]  = "Silence",			-- Arcane Bomb
	[131510] = "Immune",			-- Uncontrolled Banish
	[8346]   = "Root",				-- Mobility Malfunction (trinket)
	[39965]  = "Root",				-- Frost Grenade
	[55536]  = "Root",				-- Frostweave Net
	[13099]  = "Root",				-- Net-o-Matic (trinket)
	[13119]  = "Root",				-- Net-o-Matic (trinket)
	[16566]  = "Root",				-- Net-o-Matic (trinket)
	[13138]  = "Root",				-- Net-o-Matic (trinket)
	[148526] = "Root",				-- Sticky Silk
	[15752]  = "Disarm",			-- Linken's Boomerang (trinket)
	[15753]  = "CC",				-- Linken's Boomerang (trinket)
	[1604]   = "Snare",				-- Dazed
	[295048] = "Immune",			-- Touch of the Everlasting (not immune, damage taken reduced 85%)
	[221792] = "CC",				-- Kidney Shot (Vanessa VanCleef (Rogue Bodyguard))
	[222897] = "CC",				-- Storm Bolt (Dvalen Ironrune (Warrior Bodyguard))
	[222317] = "CC",				-- Mark of Thassarian (Thassarian (Death Knight Bodyguard))
	[212435] = "CC",				-- Shado Strike (Thassarian (Monk Bodyguard))
	[212246] = "CC",				-- Brittle Statue (The Monkey King (Monk Bodyguard))
	[238511] = "CC",				-- March of the Withered
	[252717] = "CC",				-- Light's Radiance (Argus powerup)
	[148535] = "CC",				-- Ordon Death Chime (trinket)
	[30504]  = "CC",				-- Poultryized! (trinket)
	[30501]  = "CC",				-- Poultryized! (trinket)
	[30506]  = "CC",				-- Poultryized! (trinket)
	[46567]  = "CC",				-- Rocket Launch (trinket)
	[24753]  = "CC",				-- Trick
	[141928] = "CC",				-- Growing Pains (Whole-Body Shrinka' toy)
	[285643] = "CC",				-- Battle Screech
	[245855] = "CC",				-- Belly Smash
	[262177] = "CC",				-- Into the Storm
	[255978] = "CC",				-- Pallid Glare
	[256050] = "CC",				-- Disoriented (Electroshock Mount Motivator)
	[258258] = "CC",				-- Quillbomb
	[260149] = "CC",				-- Quillbomb
	[258236] = "CC",				-- Sleeping Quill Dart
	[269186] = "CC",				-- Holographic Horror Projector
	[255228] = "CC",				-- Polymorphed (Organic Discombobulation Grenade and some NPCs)
	[272188] = "CC",				-- Hammer Smash (quest)
	[264860] = "CC",				-- Binding Talisman
	[238322] = "CC",				-- Arcane Prison
	[171369] = "CC",				-- Arcane Prison
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
	[310126] = "Immune",			-- Psychic Shell (not immune, 99% damage reduction) (Lingering Psychic Shell trinket)
	[314585] = "Immune",			-- Psychic Shell (not immune, 50-80% damage reduction) (Lingering Psychic Shell trinket)
	[313448] = "CC",				-- Realized Truth (Corrupted Ring - Face the Truth ring)
	[8312]   = "Root",				-- Trap (Hunting Net trinket)
	[17308]  = "CC",				-- Stun (Hurd Smasher fist weapon)
	[23454]  = "CC",				-- Stun (The Unstoppable Force weapon)
	[9179]   = "CC",				-- Stun (Tigule and Foror's Strawberry Ice Cream item)
	[13327]  = "CC",				-- Reckless Charge (Goblin Rocket Helmet)
	[13181]  = "CC",				-- Gnomish Mind Control Cap (Gnomish Mind Control Cap helmet)
	[26740]  = "CC",				-- Gnomish Mind Control Cap (Gnomish Mind Control Cap helmet)
	[8345]   = "CC",				-- Control Machine (Gnomish Universal Remote trinket)
	[13235]  = "CC",				-- Forcefield Collapse (Gnomish Harm Prevention belt)
	[13158]  = "CC",				-- Rocket Boots Malfunction (Engineering Rocket Boots)
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
	[25282]  = "Immune",			-- Shield of Rajaxx
	[27619]  = "Immune",			-- Ice Block
	[21892]  = "Immune",			-- Arcane Protection
	[13237]  = "CC",				-- Goblin Mortar
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
	--[9774]   = "Other",				-- Immune Root (spider belt)
	[18278]  = "Silence",			-- Silence (Silent Fang sword)
	[16470]  = "CC",				-- Gift of Stone
	[700]    = "CC",				-- Sleep (Slumber Sand item)
	[1090]   = "CC",				-- Sleep
	[12098]  = "CC",				-- Sleep
	[20663]  = "CC",				-- Sleep
	[20669]  = "CC",				-- Sleep
	[20989]  = "CC",				-- Sleep
	[24004]  = "CC",				-- Sleep
	[24664]  = "CC",				-- Sleep
	[17446]  = "CC",				-- The Black Sleep
	[29848]  = "CC",				-- Polymorph
	[29124]  = "CC",				-- Polymorph
	[14621]  = "CC",				-- Polymorph
	[27760]  = "CC",				-- Polymorph
	[28406]  = "CC",				-- Polymorph Backfire
	[851]    = "CC",				-- Polymorph: Sheep
	[785]    = "CC",				-- True Fulfillment
	[17172]  = "CC",				-- Hex
	[24053]  = "CC",				-- Hex
	[16707]  = "CC",				-- Hex
	[16708]  = "CC",				-- Hex
	[16709]  = "CC",				-- Hex
	[18503]  = "CC",				-- Hex
	[20683]  = "CC",				-- Highlord's Justice
	[17286]  = "CC",				-- Crusader's Hammer
	[17820]  = "Other",				-- Veil of Shadow
	[24178]  = "CC",				-- Will of Hakkar
	[12096]  = "CC",				-- Fear
	[26070]  = "CC",				-- Fear
	[26580]  = "CC",				-- Fear
	[27641]  = "CC",				-- Fear
	[27990]  = "CC",				-- Fear
	[29168]  = "CC",				-- Fear
	[30002]  = "CC",				-- Fear
	[26042]  = "CC",				-- Psychic Scream
	[9915]   = "Root",				-- Frost Nova
	[14907]  = "Root",				-- Frost Nova
	[22645]  = "Root",				-- Frost Nova
	[29849]  = "Root",				-- Frost Nova
	[30094]  = "Root",				-- Frost Nova
	[15091]  = "Snare",				-- Blast Wave
	[17277]  = "Snare",				-- Blast Wave
	[23039]  = "Snare",				-- Blast Wave
	[23113]  = "Snare",				-- Blast Wave
	[30092]  = "Snare",				-- Blast Wave
	[12548]  = "Snare",				-- Frost Shock
	[22582]  = "Snare",				-- Frost Shock
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
	[28478]  = "Snare",				-- Frostbolt
	[28479]  = "Snare",				-- Frostbolt
	[17503]  = "Snare",				-- Frostbolt
	[23412]  = "Snare",				-- Frostbolt
	[24942]  = "Snare",				-- Frostbolt
	[23102]  = "Snare",				-- Frostbolt
	[20828]  = "Snare",				-- Cone of Cold
	[22746]  = "Snare",				-- Cone of Cold
	[30095]  = "Snare",				-- Cone of Cold
	[20717]  = "Snare",				-- Sand Breath
	[16568]  = "Snare",				-- Mind Flay
	[23953]  = "Snare",				-- Mind Flay
	[28310]  = "Snare",				-- Mind Flay
	[29407]  = "Snare",				-- Mind Flay
	[26044]  = "CC",				-- Mind Flay
	[16094]  = "Snare",				-- Frost Breath
	[16099]  = "Snare",				-- Frost Breath
	[16340]  = "Snare",				-- Frost Breath
	[17174]  = "Snare",				-- Concussive Shot
	[27634]  = "Snare",				-- Concussive Shot
	[20654]  = "Root",				-- Entangling Roots
	[22800]  = "Root",				-- Entangling Roots
	[24648]  = "Root",				-- Entangling Roots
	[26071]  = "Root",				-- Entangling Roots
	[12520]  = "Root",				-- Teleport from Azshara Tower
	[12521]  = "Root",				-- Teleport from Azshara Tower
	[12024]  = "Root",				-- Net
	[12023]  = "Root",				-- Web
	[13608]  = "Root",				-- Hooked Net
	[10017]  = "Root",				-- Frost Hold
	[3542]   = "Root",				-- Naraxis Web
	[5567]   = "Root",				-- Miring Mud
	[4932]   = "ImmuneSpell",		-- Ward of Myzrael
	[7383]   = "ImmunePhysical",	-- Water Bubble
	[101]    = "CC",				-- Trip
	[3109]   = "CC",				-- Presence of Death
	[3143]   = "CC",				-- Glacial Roar
	[5403]   = "Root",				-- Crash of Waves
	[6605]   = "CC",				-- Terrifying Screech
	[3242]   = "CC",				-- Ravage
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
	[6869]   = "CC",				-- Fall down
	[8646]   = "CC",				-- Snap Kick
	[24671]  = "CC",				-- Snap Kick
	[27620]  = "Silence",			-- Snap Kick
	[27814]  = "Silence",			-- Kick
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
	[29685]  = "CC",				-- Terrifying Roar
	[17276]  = "CC",				-- Scald
	[18812]  = "CC",				-- Knockdown
	[19128]  = "CC",				-- Knockdown
	[11430]  = "CC",				-- Slam
	[28335]  = "CC",				-- Whirlwind
	[16451]  = "CC",				-- Judge's Gavel
	[23601]  = "CC",				-- Scatter Shot
	[24261]  = "CC",				-- Brain Wash
	[25260]  = "CC",				-- Wings of Despair
	[23275]  = "CC",				-- Dreadful Fright
	[24919]  = "CC",				-- Nauseous
	[29484]  = "CC",				-- Web Spray
	[21167]  = "CC",				-- Snowball
	[9612]   = "CC",				-- Ink Spray (Chance to hit reduced by 50%)
	[4320]   = "Silence",			-- Trelane's Freezing Touch
	[9552]   = "Silence",			-- Searing Flames
	[12943]  = "Silence",			-- Fell Curse Effect
	[10851]  = "Disarm",			-- Grab Weapon
	[6576]   = "CC",				-- Intimidating Growl
	[7093]   = "CC",				-- Intimidation
	[8715]   = "CC",				-- Terrifying Howl
	[8817]   = "CC",				-- Smoke Bomb
	[3442]   = "CC",				-- Enslave
	[3651]   = "ImmuneSpell",		-- Shield of Reflection
	[20223]  = "ImmuneSpell",		-- Magic Reflection
	[25772]  = "CC",				-- Mental Domination
	[16053]  = "CC",				-- Dominion of Soul (Orb of Draconic Energy)
	[15859]  = "CC",				-- Dominate Mind
	[20740]  = "CC",				-- Dominate Mind
	[21330]  = "CC",				-- Corrupted Fear (Deathmist Raiment set)
	[27868]  = "Root",				-- Freeze (Magister's and Sorcerer's Regalia sets)
	[17333]  = "Root",				-- Spider's Kiss (Spider's Kiss set)
	[26108]  = "CC",				-- Glimpse of Madness (Dark Edge of Insanity axe)
	[9462]   = "Snare",				-- Mirefin Fungus
	[19137]  = "Snare",				-- Slow
	[21847]  = "CC",				-- Snowman
	[21848]  = "CC",				-- Snowman
	[21980]  = "CC",				-- Snowman
	[6724]   = "Immune",			-- Light of Elune
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
	[24364]  = "Other",				-- Living Free Action
	[23505]  = "Other",				-- Berserking
	[24378]  = "Other",				-- Berserking
	[19135]  = "Other",				-- Avatar
	[17624]  = "CC",				-- Flask of Petrification
	[13534]  = "Disarm",			-- Disarm (The Shatterer weapon)
	[13439]  = "Snare",				-- Frostbolt (some weapons)
	[16621]  = "ImmunePhysical",	-- Self Invulnerability (Invulnerable Mail)
	[27559]  = "Silence",			-- Silence (Jagged Obsidian Shield)
	[13907]  = "CC",				-- Smite Demon (Enchant Weapon - Demonslaying)
	[18798]  = "CC",				-- Freeze (Freezing Band)
	
	-- PvE
	--[123456] = "PvE",				-- This is just an example, not a real spell
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
	[310134] = "Immune",			-- Manifest Madness (99% damage reduction)
	-- -- 
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
	-- --- Common to all 
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
	[293986] = "Silence",			-- Sonic Pulse
	[303264] = "CC",				-- Anti-Trespassing Field
	[296279] = "CC",				-- Anti-Trespassing Teleport
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
	[298602] = "Other",				-- Smoke Cloud
	[300675] = "Other",				-- Toxic Fog
	-- -- Atal'Dazar
	[255371] = "CC",				-- Terrifying Visage
	[255041] = "CC",				-- Terrifying Screech
	[252781] = "CC",				-- Unstable Hex
	[279118] = "CC",				-- Unstable Hex
	[252692] = "CC",				-- Waylaying Jab
	[255567] = "CC",				-- Frenzied Charge
	[258653] = "Immune",			-- Bulwark of Juju (90% damage reduction)
	[253721] = "Immune",			-- Bulwark of Juju (90% damage reduction)
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
	[264027] = "Other",				-- Warding Candles (50% damage reduction)
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
	[205043] = "CC",				-- Infested Mind (Nythendra)
	-- -- Ursoc
	[197980] = "CC",				-- Nightmarish Cacophony (Ursoc)
	-- -- Dragons of Nightmare
	[205341] = "CC",				-- Seeping Fog (Dragons of Nightmare)
	[225356] = "CC",				-- Seeping Fog (Dragons of Nightmare)
	[203110] = "CC",				-- Slumbering Nightmare (Dragons of Nightmare)
	[204078] = "CC",				-- Bellowing Roar (Dragons of Nightmare)
	[203770] = "Root",				-- Defiled Vines (Dragons of Nightmare)
	-- -- Il'gynoth
	[212886] = "CC",				-- Nightmare Corruption (Il'gynoth)
	-- -- Cenarius
	[210315] = "Root",				-- Nightmare Brambles (Cenarius)
	[214505] = "CC",				-- Entangling Nightmares (Cenarius)
	------------------------
	-- ToV Raid
	-- -- Trash
	[228609] = "CC",				-- Bone Chilling Scream
	[228883] = "CC",				-- Unholy Reckoning
	[228869] = "CC",				-- Crashing Waves
	-- -- Odyn
	[228018] = "Immune",			-- Valarjar's Bond (Odyn)
	[229529] = "Immune",			-- Valarjar's Bond (Odyn)
	[227781] = "CC",				-- Glowing Fragment (Odyn)
	[227594] = "Immune",			-- Runic Shield (Odyn)
	[227595] = "Immune",			-- Runic Shield (Odyn)
	[227596] = "Immune",			-- Runic Shield (Odyn)
	[227597] = "Immune",			-- Runic Shield (Odyn)
	[227598] = "Immune",			-- Runic Shield (Odyn)
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
	[204483] = "CC",				-- Focused Blast (Skorpyron)
	-- -- Spellblade Aluriel
	[213621] = "CC",				-- Entombed in Ice (Spellblade Aluriel)
	-- -- Tichondrius
	[215988] = "CC",				-- Carrion Nightmare (Tichondrius)
	-- -- High Botanist Tel'arn
	[218304] = "Root",				-- Parasitic Fetter (Botanist)
	-- -- Star Augur
	[206603] = "CC",				-- Frozen Solid (Star Augur)
	[216697] = "CC",				-- Frigid Pulse (Star Augur)
	[207720] = "CC",				-- Witness the Void (Star Augur)
	[207714] = "Immune",			-- Void Shift (-99% dmg taken) (Star Augur)
	-- -- Gul'dan
	[206366] = "CC",				-- Empowered Bonds of Fel (Knockback Stun) (Gul'dan)
	[206983] = "CC",				-- Shadowy Gaze (Gul'dan)
	[208835] = "CC",				-- Distortion Aura (Gul'dan)
	[208671] = "CC",				-- Carrion Wave (Gul'dan)
	[229951] = "CC",				-- Fel Obelisk (Gul'dan)
	[206841] = "CC",				-- Fel Obelisk (Gul'dan)
	[227749] = "Immune",			-- The Eye of Aman'Thul (Gul'dan)
	[227750] = "Immune",			-- The Eye of Aman'Thul (Gul'dan)
	[227743] = "Immune",			-- The Eye of Aman'Thul (Gul'dan)
	[227745] = "Immune",			-- The Eye of Aman'Thul (Gul'dan)
	[227427] = "Immune",			-- The Eye of Aman'Thul (Gul'dan)
	[227320] = "Immune",			-- The Eye of Aman'Thul (Gul'dan)
	[206516] = "Immune",			-- The Eye of Aman'Thul (Gul'dan)
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
	-- -- Demonic Inquisition
	[233430] = "CC",				-- Unbearable Torment (Demonic Inquisition) (no CC, -90% dmg, -25% heal, +90% dmg taken)
	-- -- Harjatan
	[240315] = "Immune",			-- Hardened Shell (Harjatan)
	-- -- Sisters of the Moon
	[237351] = "Silence",			-- Lunar Barrage (Sisters of the Moon)
	-- -- Mistress Sassz'ine
	[234332] = "CC",				-- Hydra Acid (Mistress Sassz'ine)
	[230362] = "CC",				-- Thundering Shock (Mistress Sassz'ine)
	[230959] = "CC",				-- Concealing Murk (Mistress Sassz'ine) (no CC, hit chance reduced 75%)
	-- -- The Desolate Host
	[236241] = "CC",				-- Soul Rot (The Desolate Host) (no CC, dmg dealt reduced 75%)
	[236011] = "Silence",			-- Tormented Cries (The Desolate Host)
	[236513] = "Immune",			-- Bonecage Armor (The Desolate Host) (75% dmg reduction)
	-- -- Maiden of Vigilance
	[248812] = "CC",				-- Blowback (Maiden of Vigilance)
	[233739] = "CC",				-- Malfunction (Maiden of Vigilance
	-- -- Kil'jaeden
	[245332] = "Immune",			-- Nether Shift (Kil'jaeden)
	[244834] = "Immune",			-- Nether Gale (Kil'jaeden)
	[236602] = "CC",				-- Soul Anguish (Kil'jaeden)
	[236555] = "CC",				-- Deceiver's Veil (Kil'jaeden)
	------------------------
	-- Antorus Raid
	-- -- Trash
	[246209] = "CC",				-- Punishing Flame
	[254502] = "CC",				-- Fearsome Leap
	[254125] = "CC",				-- Cloud of Confusion
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
	[27758]  = "CC",				-- War Stomp
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
	[39427]  = "CC",				-- Bellowing Roar
	[22678]  = "CC",				-- Fear
	[23603]  = "CC",				-- Wild Polymorph
	[23364]  = "CC",				-- Tail Lash
	[25654]  = "CC",				-- Tail Lash
	[23365]  = "Disarm",			-- Dropped Weapon
	[23415]  = "ImmunePhysical",	-- Improved Blessing of Protection
	[23414]  = "Root",				-- Paralyze
	[22687]  = "Other",				-- Veil of Shadow
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
	-- -- Dragons of Nightmare
	[25043]  = "CC",				-- Aura of Nature
	[24778]  = "CC",				-- Sleep (Dream Fog)
	[24811]  = "CC",				-- Draw Spirit
	[25806]  = "CC",				-- Creature of Nightmare
	[12528]  = "Silence",			-- Silence
	[23207]  = "Silence",			-- Silence
	[26069]  = "Silence",			-- Silence
	[29943]  = "Silence",			-- Silence
	[30225]  = "Silence",			-- Silence
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
	[8150]   = "CC",				-- Thundercrack
	-- -- Shadowfang Keep
	[7295]   = "Root",				-- Soul Drain
	[7139]   = "CC",				-- Fel Stomp
	[13005]  = "CC",				-- Hammer of Justice
	[9080]   = "Snare",				-- Hamstring
	[7621]   = "CC",				-- Arugal's Curse
	[7068]   = "Other",				-- Veil of Shadow
	[23224]  = "Other",				-- Veil of Shadow
	[7803]   = "CC",				-- Thundershock
	[7074]   = "Silence",			-- Screams of the Past
	[24021]  = "ImmuneSpell",		-- Anti-Magic Shield
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
	[29321]  = "CC",				-- Fear
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
	[19134]  = "CC",				-- Intimidating Shout
	[29544]  = "CC",				-- Intimidating Shout
	[6253]   = "CC",				-- Backhand
	[204735] = "Snare",				-- Frostbolt
	[86740]  = "CC",				-- Dirty Blow
	[86814]  = "CC",				-- Bash Head
	-- -- Gnomeregan
	[10831]  = "ImmuneSpell",		-- Reflection Field
	[11820]  = "Root",				-- Electrified Net
	[10852]  = "Root",				-- Battle Net
	[10734]  = "Snare",				-- Hail Storm
	[11264]  = "Root",				-- Ice Blast
	[10730]  = "CC",				-- Pacify
	[74720]  = "CC",				-- Pound
	-- -- Razorfen Kraul
	[8281]   = "Silence",			-- Sonic Burst
	[23918]  = "Silence",			-- Sonic Burst
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
	[21793]  = "Snare",				-- Twisted Tranquility
	[21808]  = "CC",				-- Landslide
	[29419]  = "CC",				-- Flash Bomb
	[22592]  = "CC",				-- Knockdown
	[21869]  = "CC",				-- Repulsive Gaze
	[11428]  = "CC",				-- Knockdown
	[16790]  = "CC",				-- Knockdown
	[11922]  = "Root",				-- Entangling Roots
	-- -- Zul'Farrak
	[11020]  = "CC",				-- Petrify
	[13704]  = "CC",				-- Psychic Scream
	[11089]  = "ImmunePhysical",	-- Theka Transform (also immune to shadow damage)
	[12551]  = "Snare",				-- Frost Shot
	[11836]  = "CC",				-- Freeze Solid
	[11131]  = "Snare",				-- Icicle
	[11641]  = "CC",				-- Hex
	[12540]  = "CC",				-- Gouge
	-- -- The Temple of Atal'Hakkar (Sunken Temple)
	[12888]  = "CC",				-- Cause Insanity
	[24327]  = "CC",				-- Cause Insanity
	[26079]  = "CC",				-- Cause Insanity
	[12480]  = "CC",				-- Hex of Jammal'an
	[12890]  = "CC",				-- Deep Slumber
	[25852]  = "CC",				-- Lash
	[6607]   = "CC",				-- Lash
	[6608]   = "Disarm",			-- Dropped Weapon
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
	[29061]  = "Immune",			-- Shield Wall (not immune, 75% damage reduction)
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
	[17405]  = "CC",				-- Domination
	[17246]  = "CC",				-- Possessed
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
	[18327]  = "Silence",			-- Silence
	[17307]  = "CC",				-- Knockout
	[15970]  = "CC",				-- Sleep
	[3589]   = "Silence",			-- Deafening Screech
	[54791]  = "Snare",				-- Frostbolt
	[66290]  = "CC",				-- Sleep
	[82107]  = "CC",				-- Deep Freeze
	-- -- Dire Maul
	[17145]  = "Snare",				-- Blast Wave
	[21060]  = "CC",				-- Blind
	[22651]  = "CC",				-- Sacrifice
	[22419]  = "Disarm",			-- Riptide
	[22691]  = "Disarm",			-- Disarm
	[22833]  = "CC",				-- Booze Spit (chance to hit reduced by 75%)
	[22856]  = "CC",				-- Ice Lock
	[16727]  = "CC",				-- War Stomp
	[22884]  = "CC",				-- Psychic Scream
	[22911]  = "CC",				-- Charge
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
	[23919]  = "CC",				-- Swoop
	[18103]  = "CC",				-- Backhand
	[24619]  = "Silence",			-- Soul Tap
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

-------------------------------------------------------------------------------
-- Global references for attaching icons to various unit frames
local anchors = {
	None = {}, -- empty but necessary
	Blizzard = {
		player = "PlayerPortrait",
		pet    = "PetPortrait",
		target = "TargetFramePortrait",
		focus  = "FocusFramePortrait",
		party1 = "PartyMemberFrame1Portrait",
		party2 = "PartyMemberFrame2Portrait",
		party3 = "PartyMemberFrame3Portrait",
		party4 = "PartyMemberFrame4Portrait",
		--party1pet = "PartyMemberFrame1PetFramePortrait",
		--party2pet = "PartyMemberFrame2PetFramePortrait",
		--party3pet = "PartyMemberFrame3PetFramePortrait",
		--party4pet = "PartyMemberFrame4PetFramePortrait",
		arena1 = "ArenaEnemyFrame1ClassPortrait",
		arena2 = "ArenaEnemyFrame2ClassPortrait",
		arena3 = "ArenaEnemyFrame3ClassPortrait",
		arena4 = "ArenaEnemyFrame4ClassPortrait",
		arena5 = "ArenaEnemyFrame5ClassPortrait",
	},
	Perl = {
		player = "Perl_Player_Portrait",
		pet    = "Perl_Player_Pet_Portrait",
		target = "Perl_Target_Portrait",
		focus  = "Perl_Focus_Portrait",
		party1 = "Perl_Party_MemberFrame1_Portrait",
		party2 = "Perl_Party_MemberFrame2_Portrait",
		party3 = "Perl_Party_MemberFrame3_Portrait",
		party4 = "Perl_Party_MemberFrame4_Portrait",
	},
	XPerl = {
		player = "XPerl_PlayerportraitFrameportrait",
		pet    = "XPerl_Player_PetportraitFrameportrait",
		target = "XPerl_TargetportraitFrameportrait",
		focus  = "XPerl_FocusportraitFrameportrait",
		party1 = "XPerl_party1portraitFrameportrait",
		party2 = "XPerl_party2portraitFrameportrait",
		party3 = "XPerl_party3portraitFrameportrait",
		party4 = "XPerl_party4portraitFrameportrait",
	},
	LUI = {
		player = "oUF_LUI_player",
		pet    = "oUF_LUI_pet",
		target = "oUF_LUI_target",
		focus  = "oUF_LUI_focus",
		party1 = "oUF_LUI_partyUnitButton1",
		party2 = "oUF_LUI_partyUnitButton2",
		party3 = "oUF_LUI_partyUnitButton3",
		party4 = "oUF_LUI_partyUnitButton4",
	},
	SyncFrames = {
		arena1 = "SyncFrame1Class",
		arena2 = "SyncFrame2Class",
		arena3 = "SyncFrame3Class",
		arena4 = "SyncFrame4Class",
		arena5 = "SyncFrame5Class",
	},
	--SUF = {
	--	player = SUFUnitplayer.portraitModel.portrait,
	--	pet    = SUFUnitpet.portraitModel.portrait,
	--	target = SUFUnittarget.portraitModel.portrait,
	--	focus  = SUFUnitfocus.portraitModel.portrait,
	--	party1 = SUFUnitparty1.portraitModel.portrait, -- SUFHeaderpartyUnitButton1 ?
	--	party2 = SUFUnitparty2.portraitModel.portrait,
	--	party3 = SUFUnitparty3.portraitModel.portrait,
	--	party4 = SUFUnitparty4.portraitModel.portrait,
	--},
	-- more to come here?
}

-------------------------------------------------------------------------------
-- Default settings
local DBdefaults = {
	version = 6.1, -- This is the settings version, not necessarily the same as the LoseControl version
	noCooldownCount = false,
	noBlizzardCooldownCount = true,
	noLossOfControlCooldown = false,
	disablePartyInBG = true,
	disableArenaInBG = true,
	disablePartyInRaid = true,
	disablePlayerInterrupts = true,
	showNPCInterruptsTarget = true,
	showNPCInterruptsFocus = true,
	priority = {		-- higher numbers have more priority; 0 = disabled
		PvE = 90,
		Immune = 80,
		ImmuneSpell	= 70,
		ImmunePhysical = 65,
		CC = 60,
		Silence = 50,
		Interrupt = 40,
		Disarm = 30,
		Other = 0,
		Root = 0,
		Snare = 0,
	},
	frames = {
		player = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "None",
		},
		pet = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		target = {
			enabled = true,
			size = 56,
			alpha = 1,
			anchor = "Blizzard",
		},
		focus = {
			enabled = true,
			size = 56,
			alpha = 1,
			anchor = "Blizzard",
		},
		party1 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		party2 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		party3 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		party4 = {
			enabled = true,
			size = 36,
			alpha = 1,
			anchor = "Blizzard",
		},
		arena1 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
		},
		arena2 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
		},
		arena3 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
		},
		arena4 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
		},
		arena5 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
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

-- Utility function to handle registering for unit events
function LoseControl:RegisterUnitEvents(enabled)
	local unitId = self.unitId
	if debug then print("RegisterUnitEvents", unitId, enabled) end
	if enabled then
		self:RegisterUnitEvent("UNIT_AURA", unitId)
		if unitId == "target" then
			self:RegisterEvent("PLAYER_TARGET_CHANGED")
		elseif unitId == "focus" then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		elseif unitId == "pet" then
			self:RegisterUnitEvent("UNIT_PET", "player")
		end
	else
		self:UnregisterEvent("UNIT_AURA")
		if unitId == "target" then
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		elseif unitId == "focus" then
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		elseif unitId == "pet" then
			self:UnregisterEvent("UNIT_PET")
		end
		if not self.unlockMode then
			self:Hide()
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

local function SetInterruptIconsSize(iconFrame, iconSize)
	local interruptIconSize = (iconSize * 0.88) / 3
	local interruptIconOffset = (iconSize * 0.06)
	if iconFrame.frame.anchor == "Blizzard" then
		iconFrame.interruptIconOrderPos = {
			[1] = {-interruptIconOffset-interruptIconSize, interruptIconOffset},
			[2] = {-interruptIconOffset, interruptIconOffset+interruptIconSize},
			[3] = {-interruptIconOffset-interruptIconSize, interruptIconOffset+interruptIconSize},
			[4] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset+interruptIconSize},
			[5] = {-interruptIconOffset, interruptIconOffset+interruptIconSize*2},
			[6] = {-interruptIconOffset-interruptIconSize, interruptIconOffset+interruptIconSize*2},
			[7] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset+interruptIconSize*2}
		}
	else
		iconFrame.interruptIconOrderPos = {
			[1] = {-interruptIconOffset, interruptIconOffset},
			[2] = {-interruptIconOffset-interruptIconSize, interruptIconOffset},
			[3] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset},
			[4] = {-interruptIconOffset, interruptIconOffset+interruptIconSize},
			[5] = {-interruptIconOffset-interruptIconSize, interruptIconOffset+interruptIconSize},
			[6] = {-interruptIconOffset-interruptIconSize*2, interruptIconOffset+interruptIconSize},
			[7] = {-interruptIconOffset, interruptIconOffset+interruptIconSize*2}
		}
	end
	iconFrame.iconInterruptBackground:SetWidth(iconSize)
	iconFrame.iconInterruptBackground:SetHeight(iconSize)
	for _, v in pairs(iconFrame.iconInterruptList) do
		v:SetWidth(interruptIconSize)
		v:SetHeight(interruptIconSize)
		v:SetPoint("BOTTOMRIGHT", iconFrame.interruptIconOrderPos[v.interruptIconOrder or 1][1], iconFrame.interruptIconOrderPos[v.interruptIconOrder or 1][2])
	end
end

-- Function to disable Cooldown on player bars for CC effects
function LoseControl:DisableLossOfControlUI()
	if (not DISABLELOSSOFCONTROLUI_HOOKED) then
		hooksecurefunc('CooldownFrame_Set', function(self)
			if self.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL then
				self:SetDrawBling(false)
				self:SetCooldown(0, 0)
			else
				if not self:GetDrawBling() then
					self:SetDrawBling(true)
				end
			end
		end)
		hooksecurefunc('ActionButton_UpdateCooldown', function(self)
			if ( self.cooldown.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL ) then
				local start, duration, enable, charges, maxCharges, chargeStart, chargeDuration;
				local modRate = 1.0;
				local chargeModRate = 1.0;
				if ( self.spellID ) then
					start, duration, enable, modRate = GetSpellCooldown(self.spellID);
					charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetSpellCharges(self.spellID);
				else
					start, duration, enable, modRate = GetActionCooldown(self.action);
					charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(self.action);
				end
				self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
				self.cooldown:SetSwipeColor(0, 0, 0);
				self.cooldown:SetHideCountdownNumbers(false);
				if ( charges and maxCharges and maxCharges > 1 and charges < maxCharges ) then
					if chargeStart == 0 then
						ClearChargeCooldown(self);
					else
						if self.chargeCooldown then
							CooldownFrame_Set(self.chargeCooldown, chargeStart, chargeDuration, true, true, chargeModRate);
						end
					end
				else
					ClearChargeCooldown(self);
				end
				CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate);
			end
		end)
		DISABLELOSSOFCONTROLUI_HOOKED = true
	end
end

-- Handle default settings
function LoseControl:ADDON_LOADED(arg1)
	if arg1 == addonName then
		if (_G.LoseControlDB == nil) or (_G.LoseControlDB.version == nil) then -- never installed before
			_G.LoseControlDB = CopyTable(DBdefaults)
			print(L["LoseControl reset."])
		end
		if _G.LoseControlDB.version < DBdefaults.version then
			for k, v in pairs(DBdefaults) do
				if (_G.LoseControlDB[k] == nil) then
					_G.LoseControlDB[k] = v
				end
			end
			_G.LoseControlDB.version = DBdefaults.version
		end
		LoseControlDB = _G.LoseControlDB
		self.VERSION = "6.10"
		self.noCooldownCount = LoseControlDB.noCooldownCount
		self.noBlizzardCooldownCount = LoseControlDB.noBlizzardCooldownCount
		self.noLossOfControlCooldown = LoseControlDB.noLossOfControlCooldown
		if LoseControlDB.noLossOfControlCooldown then
			LoseControl:DisableLossOfControlUI()
		end
		if LoseControlDB.noCooldownCount then
			self:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
			for _, v in pairs(LCframes) do
				v:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
			end
		else
			self:SetHideCountdownNumbers(true)
			for _, v in pairs(LCframes) do
				v:SetHideCountdownNumbers(true)
			end
		end
	end
end

LoseControl:RegisterEvent("ADDON_LOADED")

-- Initialize a frame's position and register for events
function LoseControl:PLAYER_ENTERING_WORLD() -- this correctly anchors enemy arena frames that aren't created until you zone into an arena
	local unitId = self.unitId
	self.frame = LoseControlDB.frames[unitId] -- store a local reference to the frame's settings
	local frame = self.frame
	local inInstance, instanceType = IsInInstance()
	local enabled = frame.enabled and not (
		inInstance and instanceType == "pvp" and (
			( LoseControlDB.disablePartyInBG and strfind(unitId, "party") ) or
			( LoseControlDB.disableArenaInBG and strfind(unitId, "arena") )
		)
	) and not (
		IsInRaid() and LoseControlDB.disablePartyInRaid and strfind(unitId, "party") and not (inInstance and (instanceType=="arena" or instanceType=="pvp"))
	)
	self.anchor = _G[anchors[frame.anchor][unitId]] or UIParent
	self.unitGUID = UnitGUID(self.unitId)
	self.parent:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
	--self:SetFrameStrata(frame.strata or "LOW")
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:SetWidth(frame.size)
	self:SetHeight(frame.size)
	self:RegisterUnitEvents(enabled)
	
	self:SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	
	SetInterruptIconsSize(self, frame.size)
	
	--self:SetAlpha(frame.alpha) -- doesn't seem to work; must manually set alpha after the cooldown is displayed, otherwise it doesn't apply.
	self:Hide()
	
	if enabled and not self.unlockMode then
		self:UNIT_AURA(self.unitId)
	end
end

function LoseControl:GROUP_ROSTER_UPDATE()
	local unitId = self.unitId
	local frame = self.frame
	if (frame == nil) or (unitId == nil) or not(strfind(unitId, "party")) then
		return
	end
	local inInstance, instanceType = IsInInstance()
	local enabled = frame.enabled and not (
		inInstance and instanceType == "pvp" and LoseControlDB.disablePartyInBG
	) and not (
		IsInRaid() and LoseControlDB.disablePartyInRaid and not (inInstance and (instanceType=="arena" or instanceType=="pvp"))
	)
	self:RegisterUnitEvents(enabled)
	self.unitGUID = UnitGUID(unitId)
	if enabled and not self.unlockMode then
		self:UNIT_AURA(unitId)
	end
end

function LoseControl:GROUP_JOINED()
	self:GROUP_ROSTER_UPDATE()
end

function LoseControl:GROUP_LEFT()
	self:GROUP_ROSTER_UPDATE()
end

local function UpdateUnitAuraByUnitGUID(unitGUID)
	local inInstance, instanceType = IsInInstance()
	for k, v in pairs(LCframes) do
		local enabled = v.frame.enabled and not (
			inInstance and instanceType == "pvp" and (
				( LoseControlDB.disablePartyInBG and strfind(v.unitId, "party") ) or
				( LoseControlDB.disableArenaInBG and strfind(v.unitId, "arena") )
			)
		) and not (
			IsInRaid() and LoseControlDB.disablePartyInRaid and strfind(v.unitId, "party") and not (inInstance and (instanceType=="arena" or instanceType=="pvp"))
		)
		if enabled and not v.unlockMode then
			if v.unitGUID == unitGUID then
				v:UNIT_AURA(k)
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
	local inInstance, instanceType = IsInInstance()
	self:RegisterUnitEvents(
		frame.enabled and not (
			inInstance and instanceType == "pvp" and LoseControlDB.disableArenaInBG
		)
	)
	self.unitGUID = UnitGUID(self.unitId)
	if enabled and not self.unlockMode then
		self:UNIT_AURA(unitId)
	end
end

function LoseControl:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	self:ARENA_OPPONENT_UPDATE()
end

-- This event check pvp interrupts
function LoseControl:COMBAT_LOG_EVENT_UNFILTERED()
	local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, _, _, _, _, spellSchool = CombatLogGetCurrentEventInfo()
	if (destGUID ~= nil) then
		if (event == "SPELL_INTERRUPT") then
			local duration = interruptsIds[spellId]
			if (duration ~= nil) then
				local _, destClass = GetPlayerInfoByGUID(destGUID)
				if (destClass == "DRUID") then
					local unitIdFromGUID
					for _, v in pairs(LCframes) do
						if (UnitGUID(v.unitId) == destGUID) then
							unitIdFromGUID = v.unitId
							break
						end
					end
					if (unitIdFromGUID ~= nil) then
						for i = 1, 40 do
							local _, _, _, _, _, _, _, _, _, auxSpellId = UnitBuff(unitIdFromGUID, i)
							if not auxSpellId then break end
							if auxSpellId == 234084 then		-- Moon and Stars (Druid)
								duration = duration * 0.3
								break
							end
						end	
					end
				end
				local expirationTime = GetTime() + duration
				if debug then print("interrupt", ")", destGUID, "|", GetSpellInfo(spellId), "|", duration, "|", expirationTime, "|", spellId) end
				local priority = LoseControlDB.priority.Interrupt
				local _, _, icon = GetSpellInfo(spellId)
				if (InterruptAuras[destGUID] == nil) then
					InterruptAuras[destGUID] = {}
				end
				tblinsert(InterruptAuras[destGUID], { ["spellId"] = spellId, ["duration"] = duration, ["expirationTime"] = expirationTime, ["priority"] = priority, ["icon"] = icon, ["spellSchool"] = spellSchool })
				UpdateUnitAuraByUnitGUID(destGUID)
			end
		elseif (((event == "UNIT_DIED") or (event == "UNIT_DESTROYED") or (event == "UNIT_DISSIPATES")) and (select(2, GetPlayerInfoByGUID(destGUID)) ~= "HUNTER")) then
			InterruptAuras[destGUID] = nil
			UpdateUnitAuraByUnitGUID(destGUID)
		end
	end
	if ((sourceGUID ~= nil) and (event == "SPELL_CAST_SUCCESS") and (spellId == 235219)) then
		local needUpdateUnitAura = false
		if (InterruptAuras[sourceGUID] ~= nil) then
			for k, v in pairs(InterruptAuras[sourceGUID]) do
				if (bit_band(v.spellSchool, 16) > 0) then
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
			UpdateUnitAuraByUnitGUID(sourceGUID)
		end
	end
end

-- This is the main event. Check for (de)buffs and update the frame icon and cooldown.
function LoseControl:UNIT_AURA(unitId) -- fired when a (de)buff is gained/lost
	if not self.anchor:IsVisible() then return end
	local priority = LoseControlDB.priority
	local maxPriority = 1
	local maxExpirationTime = 0
	local Icon, Duration

	-- Check debuffs
	for i = 1, 40 do
		local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i, "HARMFUL")
		if not spellId then break end -- no more debuffs, terminate the loop
		if debug then print(unitId, "debuff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end

		if duration == 0 and expirationTime == 0 then
			expirationTime = GetTime() + 1 -- normal expirationTime = 0
		end
		
		-- exceptions
		if spellId == 212183 and unitId == "player" then -- Smoke Bomb (don't show countdown)
			expirationTime = 0
		elseif spellId == 212638 or spellId == 212150 then	-- Tracker's Net and Cheap Tricks
			if (UnitIsPlayer(unitId)) then
				local _, class = UnitClass(unitId)
				if ((class == "PRIEST") or (class == "MAGE") or (class == "WARLOCK")) then
					break
				elseif ((class == "SHAMAN") or (class == "DRUID")) then
					if (unitId == "player") then 
						local specID = GetSpecialization()
						if (specID ~= nil) then
							specID = GetSpecializationInfo(specID);
						end
						if ((specID ~= nil) and (specID ~= 0) and (specID ~= 263) and (specID ~= 103) and (specID ~= 104)) then
							break
						end
					else
						local powerTypeID = UnitPowerType(unitId)
						if ((powerTypeID ~= nil) and (powerTypeID ~= 1) and (powerTypeID ~= 3) and (powerTypeID ~= 11)) then
							break
						end
					end
				end
			end
		end

		local Priority = priority[spellIds[spellId]]
		if unitId ~= "player" or (spellIds[spellId] ~= "Immune" and spellIds[spellId] ~= "ImmuneSpell" and spellIds[spellId] ~= "ImmunePhysical" and spellIds[spellId] ~= "Other") then
			if Priority then
				if Priority == maxPriority and expirationTime > maxExpirationTime then
					maxExpirationTime = expirationTime
					Duration = duration
					Icon = icon
				elseif Priority > maxPriority then
					maxPriority = Priority
					maxExpirationTime = expirationTime
					Duration = duration
					Icon = icon
				end
			end
		end
	end

	-- Check buffs
	for i = 1, 40 do
		local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i) -- defaults to "HELPFUL" filter
		if not spellId then break end
		if debug then print(unitId, "buff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
		
		if expirationTime == 0 then
			expirationTime = GetTime() + 1 -- normal expirationTime = 0
		end
		
		-- exceptions
		-- exception for The Breast Within
		if (spellId == 19574) then
			spellId = 212704
			for j = 1, 40 do
				local _, _, _, _, _, _, _, _, _, auxSpellId = UnitBuff(unitId, j)
				if not auxSpellId then break end
				if auxSpellId == 212704 then
					spellId = 19574
					break
				end
			end
		end
		
		local Priority = priority[spellIds[spellId]]
		if unitId ~= "player" or (spellIds[spellId] ~= "Immune" and spellIds[spellId] ~= "ImmuneSpell" and spellIds[spellId] ~= "ImmunePhysical" and spellIds[spellId] ~= "Other") then
			if Priority then
				if Priority == maxPriority and expirationTime > maxExpirationTime then
					maxExpirationTime = expirationTime
					Duration = duration
					Icon = icon
				elseif Priority > maxPriority then
					maxPriority = Priority
					maxExpirationTime = expirationTime
					Duration = duration
					Icon = icon
				end
			end
		end
	end
	
	-- Check interrupts
	local maxPriorityIsInterrupt = false
	if ((self.unitGUID ~= nil) and (priority.Interrupt > 0) and ((unitId ~= "player") or (not LoseControlDB.disablePlayerInterrupts)) and ((unitId ~= "target") or (LoseControlDB.showNPCInterruptsTarget) or UnitIsPlayer(unitId)) and ((unitId ~= "focus") or (LoseControlDB.showNPCInterruptsFocus) or UnitIsPlayer(unitId))) then 
		local spellSchoolInteruptsTable = {
			[1] = {false, 0},
			[2] = {false, 0},
			[4] = {false, 0},
			[8] = {false, 0},
			[16] = {false, 0},
			[32] = {false, 0},
			[64] = {false, 0}
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
							if (bit_band(spellSchool, schoolIntId) > 0) then
								spellSchoolInteruptsTable[schoolIntId][1] = true
								if expirationTime > spellSchoolInteruptsTable[schoolIntId][2] then
									spellSchoolInteruptsTable[schoolIntId][2] = expirationTime
								end
							end
						end
						if Priority == maxPriority and expirationTime > maxExpirationTime then
							maxExpirationTime = expirationTime
							Duration = duration
							Icon = icon
							maxPriorityIsInterrupt = true
							local nextTimerUpdate = expirationTime - GetTime() + 0.05
							if nextTimerUpdate < 0.05 then
								nextTimerUpdate = 0.05
							end
							C_Timer.After(nextTimerUpdate, function()
								self:UNIT_AURA(unitId)
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
						elseif Priority > maxPriority then
							maxPriority = Priority
							maxExpirationTime = expirationTime
							Duration = duration
							Icon = icon
							maxPriorityIsInterrupt = true
							local nextTimerUpdate = expirationTime - GetTime() + 0.05
							if nextTimerUpdate < 0.05 then
								nextTimerUpdate = 0.05
							end
							C_Timer.After(nextTimerUpdate, function()
								self:UNIT_AURA(unitId)
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
	
	if maxExpirationTime == 0 then -- no (de)buffs found
		self.maxExpirationTime = 0
		if self.anchor ~= UIParent and self.drawlayer then
			self.anchor:SetDrawLayer(self.drawlayer) -- restore the original draw layer
		end
		if self.iconInterruptBackground:IsShown() then
			self.iconInterruptBackground:Hide()
		end
		self:Hide()
	elseif maxExpirationTime ~= self.maxExpirationTime then -- this is a different (de)buff, so initialize the cooldown
		self.maxExpirationTime = maxExpirationTime
		if self.anchor ~= UIParent then
			self:SetFrameLevel(self.anchor:GetParent():GetFrameLevel()) -- must be dynamic, frame level changes all the time
			if not self.drawlayer and self.anchor.GetDrawLayer then
				self.drawlayer = self.anchor:GetDrawLayer() -- back up the current draw layer
			end
			if self.drawlayer and self.anchor.SetDrawLayer then
				self.anchor:SetDrawLayer("BACKGROUND") -- Temporarily put the portrait texture below the debuff texture. This is the only reliable method I've found for keeping the debuff texture visible with the cooldown spiral on top of it.
			end
		end
		if maxPriorityIsInterrupt then
			if self.frame.anchor == "Blizzard" then
				self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background_portrait")
			else
				self.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background")
			end
			if (not self.iconInterruptBackground:IsShown()) then
				self.iconInterruptBackground:Show()
			end
		else
			if self.iconInterruptBackground:IsShown() then
				self.iconInterruptBackground:Hide()
			end
		end
		if self.frame.anchor == "Blizzard" then
			SetPortraitToTexture(self.texture, Icon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits
			self:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
			self:SetSwipeColor(0, 0, 0, 0.6)	-- Adjust the alpha of this mask to similar levels of the normal swipe cooldown texture
		else
			self.texture:SetTexture(Icon)
			self:SetSwipeColor(0, 0, 0, 0.8)	-- This is the default alpha of the normal swipe cooldown texture
		end
		self:Show()
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
		self:SetAlpha(self.frame.alpha) -- hack to apply transparency to the cooldown timer
	end
end

function LoseControl:PLAYER_FOCUS_CHANGED()
	--if (debug) then print("PLAYER_FOCUS_CHANGED") end
	if (self.unitId == "focus") then
		self.unitGUID = UnitGUID("focus")
	end
	if not self.unlockMode then
		self:UNIT_AURA("focus")
	end
end

function LoseControl:PLAYER_TARGET_CHANGED()
	--if (debug) then print("PLAYER_TARGET_CHANGED") end
	if (self.unitId == "target") then
		self.unitGUID = UnitGUID("target")
	end
	if not self.unlockMode then
		self:UNIT_AURA("target")
	end
end

function LoseControl:UNIT_PET(unitId)
	--if (debug) then print("UNIT_PET", unitId) end
	if (self.unitId == "pet") then
		self.unitGUID = UnitGUID("pet")
	end
	if not self.unlockMode then
		self:UNIT_AURA("pet")
	end
end

-- Handle mouse dragging
function LoseControl:StopMoving()
	local frame = LoseControlDB.frames[self.unitId]
	frame.point, frame.anchor, frame.relativePoint, frame.x, frame.y = self:GetPoint()
	if not frame.anchor then
		frame.anchor = "None"
	end
	self.anchor = _G[anchors[frame.anchor][self.unitId]] or UIParent
	self:StopMovingOrSizing()
end

-- Constructor method
function LoseControl:new(unitId)
	local o = CreateFrame("Cooldown", addonName .. unitId, nil, 'CooldownFrameTemplate') --, UIParent)
	local op = CreateFrame("Frame", addonName .. "FrameParent" .. unitId)
	setmetatable(o, self)
	self.__index = self
	
	o:SetParent(op)
	o.parent = op
	
	o:SetDrawEdge(false)

	-- Init class members
	o.unitId = unitId -- ties the object to a unit
	o.texture = o:CreateTexture(nil, "BORDER") -- displays the debuff; draw layer should equal "BORDER" because cooldown spirals are drawn in the "ARTWORK" layer.
	o.texture:SetAllPoints(o) -- anchor the texture to the frame
	o:SetReverse(true) -- makes the cooldown shade from light to dark instead of dark to light

	o.text = o:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	o.text:SetText(L[unitId])
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

	-- Create and initialize Interrupt Mini Icons
	o.iconInterruptBackground = o:CreateTexture(addonName .. unitId .. "InterruptIconBackground", "ARTWORK", nil, -2)
	o.iconInterruptBackground:SetTexture("Interface\\AddOns\\LoseControl\\Textures\\lc_interrupt_background")
	o.iconInterruptBackground:SetAlpha(0.7)
	o.iconInterruptBackground:SetPoint("TOPLEFT", 0, 0)
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
		v:SetAlpha(0.8)
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
	LCframes[k] = LoseControl:new(k)
end

-------------------------------------------------------------------------------
-- Add main Interface Option Panel
local O = addonName .. "OptionsPanel"

local OptionsPanel = CreateFrame("Frame", O)
OptionsPanel.name = addonName

local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(addonName)

local subText = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
local notes = GetAddOnMetadata(addonName, "Notes-" .. GetLocale())
if not notes then
	notes = GetAddOnMetadata(addonName, "Notes")
end
subText:SetText(notes)

-- "Unlock" checkbox - allow the frames to be moved
local Unlock = CreateFrame("CheckButton", O.."Unlock", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."UnlockText"]:SetText(L["Unlock"])
function Unlock:OnClick()
	if self:GetChecked() then
		_G[O.."UnlockText"]:SetText(L["Unlock"] .. L[" (drag an icon to move)"])
		local keys = {} -- for random icon sillyness
		for k in pairs(spellIds) do
			tinsert(keys, k)
		end
		for k, v in pairs(LCframes) do
			v.unlockMode = true
			local frame = LoseControlDB.frames[k]
			if frame.enabled and (_G[anchors[frame.anchor][k]] or frame.anchor == "None") then -- only unlock frames whose anchor exists
				v:RegisterUnitEvents(false)
				v.texture:SetTexture(select(3, GetSpellInfo(keys[random(#keys)])))
				v.parent:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
				--v:SetFrameStrata(frame.strata or "MEDIUM")
				if v.anchor:GetParent() then
					v:SetFrameLevel(v.anchor:GetParent():GetFrameLevel())
				end
				v.text:Show()
				v:Show()
				v:SetDrawSwipe(true)
				v:SetCooldown( GetTime(), 60 )
				v:SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
				v:SetMovable(true)
				v:RegisterForDrag("LeftButton")
				v:EnableMouse(true)
			end
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
	end
end
Unlock:SetScript("OnClick", Unlock.OnClick)

local DisableBlizzardCooldownCount = CreateFrame("CheckButton", O.."DisableBlizzardCooldownCount", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."DisableBlizzardCooldownCountText"]:SetText(L["Disable Blizzard Countdown"])
function DisableBlizzardCooldownCount:Check(value)
	LoseControlDB.noBlizzardCooldownCount = value
	LoseControl.noBlizzardCooldownCount = LoseControlDB.noBlizzardCooldownCount
	LoseControl:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
	for _, v in pairs(LCframes) do
		v:SetHideCountdownNumbers(LoseControlDB.noBlizzardCooldownCount)
	end
end
DisableBlizzardCooldownCount:SetScript("OnClick", function(self)
	DisableBlizzardCooldownCount:Check(self:GetChecked())
end)

local DisableCooldownCount = CreateFrame("CheckButton", O.."DisableCooldownCount", OptionsPanel, "OptionsCheckButtonTemplate")
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

local DisableLossOfControlCooldownAuxText = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
DisableLossOfControlCooldownAuxText:SetText(L["NeedsReload"])
DisableLossOfControlCooldownAuxText:SetTextColor(1,0,0)
DisableLossOfControlCooldownAuxText:Hide()

local DisableLossOfControlCooldownAuxButton = CreateFrame("Button", O.."DisableLossOfControlCooldownAuxButton", OptionsPanel, "OptionsButtonTemplate")
_G[O.."DisableLossOfControlCooldownAuxButtonText"]:SetText(L["ReloadUI"])
DisableLossOfControlCooldownAuxButton:SetHeight(12)
DisableLossOfControlCooldownAuxButton:Hide()
DisableLossOfControlCooldownAuxButton:SetScript("OnClick", function(self)
	ReloadUI()
end)

local DisableLossOfControlCooldown = CreateFrame("CheckButton", O.."DisableLossOfControlCooldown", OptionsPanel, "OptionsCheckButtonTemplate")
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

local Priority = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
Priority:SetText(L["Priority"])

local PriorityDescription = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
PriorityDescription:SetText(L["PriorityDescription"])

-------------------------------------------------------------------------------
-- Slider helper function, thanks to Kollektiv
local function CreateSlider(text, parent, low, high, step, globalName)
	local name = globalName or (parent:GetName() .. text)
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(160)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	--_G[name .. "Text"]:SetText(text)
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)
	return slider
end

local PrioritySlider = {}
for k in pairs(DBdefaults.priority) do
	PrioritySlider[k] = CreateSlider(L[k], OptionsPanel, 0, 100, 5)
	PrioritySlider[k]:SetScript("OnValueChanged", function(self, value)
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
	end
	local priority = LoseControlDB.priority
	for k in pairs(priority) do
		PrioritySlider[k]:SetValue(priority[k])
	end
end

InterfaceOptions_AddCategory(OptionsPanel)

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
-- Create sub-option frames
for _, v in ipairs({ "player", "pet", "target", "focus", "party", "arena" }) do
	local OptionsPanelFrame = CreateFrame("Frame", O..v)
	OptionsPanelFrame.parent = addonName
	OptionsPanelFrame.name = L[v]

	local AnchorDropDownLabel = OptionsPanelFrame:CreateFontString(O..v.."AnchorDropDownLabel", "ARTWORK", "GameFontNormal")
	AnchorDropDownLabel:SetText(L["Anchor"])
	local AnchorDropDown = CreateFrame("Frame", O..v.."AnchorDropDown", OptionsPanelFrame, "UIDropDownMenuTemplate")
	function AnchorDropDown:OnClick()
		UIDropDownMenu_SetSelectedValue(AnchorDropDown, self.value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			frame.anchor = self.value
			if self.value ~= "None" then -- reset the frame position so it centers on the anchor frame
				frame.point = nil
				frame.relativePoint = nil
				frame.x = nil
				frame.y = nil
				if self.value == "Blizzard" then
					local portrSizeValue = 36
					if (unitId == "player" or unitId == "target" or unitId == "focus") then
						portrSizeValue = 56
					elseif (strfind(unitId, "arena")) then
						portrSizeValue = 28
					end
					frame.size = portrSizeValue
					icon:SetWidth(portrSizeValue)
					icon:SetHeight(portrSizeValue)
					_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"]:SetValue(portrSizeValue)
				end
			end
			icon.anchor = _G[anchors[frame.anchor][unitId]] or UIParent
			SetInterruptIconsSize(icon, frame.size)

			icon:ClearAllPoints() -- if we don't do this then the frame won't always move
			icon:SetPoint(
				frame.point or "CENTER",
				icon.anchor,
				frame.relativePoint or "CENTER",
				frame.x or 0,
				frame.y or 0
			)
		end
	end

	local SizeSlider = CreateSlider(L["Icon Size"], OptionsPanelFrame, 16, 512, 4, OptionsPanelFrame:GetName() .. "IconSizeSlider")
	SizeSlider:SetScript("OnValueChanged", function(self, value)
		_G[self:GetName() .. "Text"]:SetText(L["Icon Size"] .. " (" .. value .. "px)")
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].size = value
			LCframes[frame]:SetWidth(value)
			LCframes[frame]:SetHeight(value)
			SetInterruptIconsSize(LCframes[frame], value)
		end
	end)

	local AlphaSlider = CreateSlider(L["Opacity"], OptionsPanelFrame, 0, 100, 5) -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSlider:SetScript("OnValueChanged", function(self, value)
		_G[self:GetName() .. "Text"]:SetText(L["Opacity"] .. " (" .. value .. "%)")
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].alpha = value / 100 -- the real alpha value
			LCframes[frame]:SetAlpha(value / 100)
		end
	end)

	local DisableInBG
	if v == "party" then
		DisableInBG = CreateFrame("CheckButton", O..v.."DisableInBG", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInBGText"]:SetText(L["DisableInBG"])
		DisableInBG:SetScript("OnClick", function(self)
			LoseControlDB.disablePartyInBG = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				for i = 1, 4 do
					LCframes[v .. i]:PLAYER_ENTERING_WORLD()
				end
			end
		end)
	elseif v == "arena" then
		DisableInBG = CreateFrame("CheckButton", O..v.."DisableInBG", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInBGText"]:SetText(L["DisableInBG"])
		DisableInBG:SetScript("OnClick", function(self)
			LoseControlDB.disableArenaInBG = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				for i = 1, 5 do
					LCframes[v .. i]:PLAYER_ENTERING_WORLD()
				end
			end
		end)
	end

	local DisableInRaid
	if v == "party" then
		DisableInRaid = CreateFrame("CheckButton", O..v.."DisableInRaid", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInRaidText"]:SetText(L["DisableInRaid"])
		DisableInRaid:SetScript("OnClick", function(self)
			LoseControlDB.disablePartyInRaid = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				for i = 1, 4 do
					LCframes[v .. i]:PLAYER_ENTERING_WORLD()
				end
			end
		end)
	end

	local DisableInterrupts
	if v == "player" then
		DisableInterrupts = CreateFrame("CheckButton", O..v.."DisableInterrupts", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInterruptsText"]:SetText(L["DisableInterrupts"])
		DisableInterrupts:SetScript("OnClick", function(self)
			LoseControlDB.disablePlayerInterrupts = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end
	
	local ShowNPCInterrupts
	if v == "target" or v == "focus" then
		ShowNPCInterrupts = CreateFrame("CheckButton", O..v.."ShowNPCInterrupts", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."ShowNPCInterruptsText"]:SetText(L["ShowNPCInterrupts"])
		ShowNPCInterrupts:SetScript("OnClick", function(self)
			if v == "target" then
				LoseControlDB.showNPCInterruptsTarget = self:GetChecked()
			elseif v == "focus" then
				LoseControlDB.showNPCInterruptsFocus = self:GetChecked()
			end
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local Enabled = CreateFrame("CheckButton", O..v.."Enabled", OptionsPanelFrame, "OptionsCheckButtonTemplate")
	_G[O..v.."EnabledText"]:SetText(L["Enabled"])
	Enabled:SetScript("OnClick", function(self)
		local enabled = self:GetChecked()
		if enabled then
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Enable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Enable(DisableInterrupts) end
			if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Enable(ShowNPCInterrupts) end
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		else
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Disable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Disable(DisableInterrupts) end
			if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Disable(ShowNPCInterrupts) end
			BlizzardOptionsPanel_Slider_Disable(SizeSlider)
			BlizzardOptionsPanel_Slider_Disable(AlphaSlider)
		end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].enabled = enabled
			local inInstance, instanceType = IsInInstance()
			local enable = enabled and not (
				inInstance and instanceType == "pvp" and (
					( LoseControlDB.disablePartyInBG and strfind(unitId, "party") ) or
					( LoseControlDB.disableArenaInBG and strfind(unitId, "arena") )
				)
			) and not (
				IsInRaid() and LoseControlDB.disablePartyInRaid and strfind(unitId, "party") and not (inInstance and (instanceType=="arena" or instanceType=="pvp"))
			)
			LCframes[frame]:RegisterUnitEvents(enable)
			if enable and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(frame)
			end
		end
	end)

	Enabled:SetPoint("TOPLEFT", 16, -32)
	if DisableInBG then DisableInBG:SetPoint("TOPLEFT", Enabled, 200, 0) end
	if DisableInRaid then DisableInRaid:SetPoint("TOPLEFT", Enabled, 200, -25) end
	if DisableInterrupts then DisableInterrupts:SetPoint("TOPLEFT", Enabled, 200, 0) end
	if ShowNPCInterrupts then ShowNPCInterrupts:SetPoint("TOPLEFT", Enabled, 200, 0) end
	SizeSlider:SetPoint("TOPLEFT", Enabled, "BOTTOMLEFT", 0, -32)
	AlphaSlider:SetPoint("TOPLEFT", SizeSlider, "BOTTOMLEFT", 0, -32)
	AnchorDropDownLabel:SetPoint("TOPLEFT", AlphaSlider, "BOTTOMLEFT", 0, -12)
	AnchorDropDown:SetPoint("TOPLEFT", AnchorDropDownLabel, "BOTTOMLEFT", 0, -8)

	OptionsPanelFrame.default = OptionsPanel.default
	OptionsPanelFrame.refresh = function()
		local unitId = v
		if unitId == "party" then
			DisableInBG:SetChecked(LoseControlDB.disablePartyInBG)
			DisableInRaid:SetChecked(LoseControlDB.disablePartyInRaid)
			unitId = "party1"
		elseif unitId == "arena" then
			DisableInBG:SetChecked(LoseControlDB.disableArenaInBG)
			unitId = "arena1"
		elseif unitId == "player" then
			DisableInterrupts:SetChecked(LoseControlDB.disablePlayerInterrupts)
		elseif unitId == "target" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsTarget)
		elseif unitId == "focus" then
			ShowNPCInterrupts:SetChecked(LoseControlDB.showNPCInterruptsFocus)
		end
		local frame = LoseControlDB.frames[unitId]
		Enabled:SetChecked(frame.enabled)
		if frame.enabled then
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Enable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Enable(DisableInterrupts) end
			if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Enable(ShowNPCInterrupts) end
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		else
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Disable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Disable(DisableInterrupts) end
			if ShowNPCInterrupts then BlizzardOptionsPanel_CheckButton_Disable(ShowNPCInterrupts) end
			BlizzardOptionsPanel_Slider_Disable(SizeSlider)
			BlizzardOptionsPanel_Slider_Disable(AlphaSlider)
		end
		SizeSlider:SetValue(frame.size)
		AlphaSlider:SetValue(frame.alpha * 100)
		UIDropDownMenu_Initialize(AnchorDropDown, function() -- called on refresh and also every time the drop down menu is opened
			AddItem(AnchorDropDown, L["None"], "None")
			AddItem(AnchorDropDown, "Blizzard", "Blizzard")
			if _G[anchors["Perl"][unitId]] then AddItem(AnchorDropDown, "Perl", "Perl") end
			if _G[anchors["XPerl"][unitId]] then AddItem(AnchorDropDown, "XPerl", "XPerl") end
			if _G[anchors["LUI"][unitId]] then AddItem(AnchorDropDown, "LUI", "LUI") end
			if _G[anchors["SyncFrames"][unitId]] then AddItem(AnchorDropDown, "SyncFrames", "SyncFrames") end
		end)
		UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
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
	print("<unit> can be: player, pet, target, focus, party1 ... party4, arena1 ... arena5")
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
	if LoseControlDB.frames[unitId] then
		LoseControlDB.frames[unitId] = CopyTable(DBdefaults.frames[unitId])
		LCframes[unitId]:PLAYER_ENTERING_WORLD()
	else
		OptionsPanel.default()
	end
	Unlock:OnClick()
	OptionsPanel.refresh()
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
	if LCframes[unitId] then
		LoseControlDB.frames[unitId].enabled = true
		local inInstance, instanceType = IsInInstance()
		local enabled = not (
			inInstance and instanceType == "pvp" and (
				( LoseControlDB.disablePartyInBG and strfind(unitId, "party") ) or
				( LoseControlDB.disableArenaInBG and strfind(unitId, "arena") )
			)
		) and not (
			IsInRaid() and LoseControlDB.disablePartyInRaid and strfind(unitId, "party") and not (inInstance and (instanceType=="arena" or instanceType=="pvp"))
		)
		LCframes[unitId]:RegisterUnitEvents(enabled)
		if enabled and not LCframes[unitId].unlockMode then
			LCframes[unitId]:UNIT_AURA(unitId)
		end
		print(addonName, unitId, "frame enabled.")
	end
end
function SlashCmd:disable(unitId)
	if LCframes[unitId] then
		LoseControlDB.frames[unitId].enabled = false
		LCframes[unitId]:RegisterUnitEvents(false)
		print(addonName, unitId, "frame disabled.")
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
