--[[
-------------------------------------------
-- Addon: LoseControl
-- Version: 7.0
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
local UnitBuff = UnitBuff
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitHealth = UnitHealth
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local SetPortraitToTexture = SetPortraitToTexture
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type
local select = select
local tonumber = tonumber
local strfind = string.find
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
local playerGUID
local print = print
local debug = false -- type "/lc debug on" if you want to see UnitAura info logged to the console
local LCframes = {}
local LCframeplayer2
local InterruptAuras = { }
local origSpellIdsChanged = { }
local Masque = LibStub("Masque", true)

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
	[31935]  = 3,		-- Avenger's Shield (only vs npc's) (Paladin)
	[347008] = 4,		-- Axe Toss (Warlock)
	[342414] = 5,		-- Cracked Mindscreecher (Priest Anima Power)
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
	[188499] = "ImmunePhysical",	-- Blade Dance (dodge chance increased by 100%)
	[213491] = "CC",				-- Demonic Trample Stun
	[206649] = "Silence",			-- Eye of Leotheras (no silence, 5% dmg and duration reset for spell casted)
	[232538] = "Snare",				-- Rain of Chaos
	[213405] = "Snare",				-- Master of the Glaive
	[198813] = "Snare",				-- Vengeful Retreat
	[198589] = "Other",				-- Blur
	[212800] = "Other",				-- Blur
	[209426] = "Other",				-- Darkness
	
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
	[145629] = "ImmuneSpell",		-- Anti-Magic Zone (not immune, 20%/60% damage reduction)
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
	[204206] = "Snare",				-- Chill Streak (pvp honor talent)
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
	[61336]  = "Immune",			-- Survival Instincts (not immune, damage taken reduced by 50%)
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
	[202244] = "CC",				-- Overrun (pvp honor talent)
	[209749] = "Disarm",			-- Faerie Swarm (pvp honor talent)
	
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
	[193530] = "Other",				-- Aspect of the Wild
	[186289] = "Other",				-- Aspect of the Eagle
	[288613] = "Other",				-- Trueshot
	[203337] = "CC",				-- Freezing Trap (Diamond Ice - pvp honor talent)
	[202748] = "Immune",			-- Survival Tactics (pvp honor talent) (not immune, 90% damage reduction)
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
	[110909] = "Other",				-- Alter Time
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
	[122278] = "Other",				-- Dampen Harm
	[243435] = "Other",				-- Fortifying Brew
	[120954] = "Other",				-- Fortifying Brew
	[201318] = "Other",				-- Fortifying Brew (pvp honor talent)
	[116849] = "Other",				-- Life Cocoon
	[214326] = "Other",				-- Exploding Keg (artifact trait - blind)
	[213664] = "Other",				-- Nimble Brew
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
	[212150] = "CC",				-- Cheap Tricks (pvp honor talent) (-75%  melee & range physical hit chance)
	[199743] = "CC",				-- Parley
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
	[212295] = "ImmuneSpell",		-- Netherward (reflects spells)
	[233582] = "Root",				-- Entrenched in Flame (pvp honor talent)
	[337113] = "Snare",				-- Sacrolash's Dark Strike (Legendary)

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
	[329267] = "ImmuneSpell",		-- Spell Reflection
	[335255] = "ImmuneSpell",		-- Spell Reflection
	[330279] = "ImmuneSpell", 		-- Overwatch (pvp honor talent)
	[871]    = "Other",				-- Shield Wall
	[12975]  = "Other",				-- Last Stand
	[18499]  = "Other",				-- Berserker Rage
	[107574] = "Other",				-- Avatar
	[262228] = "Other",				-- Deadly Calm
	[198819] = "Other",				-- Sharpen Blade (70% heal reduction)
	[236321] = "Other",				-- War Banner
	[236438] = "Other",				-- War Banner
	[236439] = "Other",				-- War Banner
	[236273] = "Other",				-- Duel
	[198817] = "Other",				-- Sharpen Blade (pvp honor talent)
	[198819] = "Other",				-- Mortal Strike (Sharpen Blade pvp honor talent))
	[184364] = "Other",				-- Enraged Regeneration
	[118038] = "ImmunePhysical",	-- Die by the Sword (parry chance increased by 100%, damage taken reduced by 30%)
	[198760] = "ImmunePhysical",	-- Intercept (pvp honor talent) (intercept the next ranged or melee hit)
	[199085] = "CC",				-- Warpath
	[199042] = "Root",				-- Thunderstruck
	[236236] = "Disarm",			-- Disarm (pvp honor talent - protection)
	[236077] = "Disarm",			-- Disarm (pvp honor talent)
	
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
	[327140] = "Other",				-- Forgeborne Reveries
	[348303] = "Other",				-- Forgeborne Reveries
	[296040] = "Snare",				-- Vanquishing Sweep
	[320267] = "Snare",				-- Soothing Voice
	[321759] = "Snare",				-- Bearer's Pursuit
	[339051] = "Snare",				-- Demonic Parole
	[336887] = "Snare",				-- Lingering Numbness
	
	----------------
	-- Other
	----------------
	[56]     = "CC",				-- Stun (low lvl weapons proc)
	[835]    = "CC",				-- Tidal Charm (trinket)
	[15534]  = "CC",				-- Polymorph (trinket)
	[15535]  = "CC",				-- Enveloping Winds (Six Demon Bag trinket)
	[23103]  = "CC",				-- Enveloping Winds (Six Demon Bag trinket)
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
	[256948] = "Other",				-- Spatial Rift (void elf racial)
	[302731] = "Other",				-- Ripple in Space (azerite essence)
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
	[21847]  = "CC",				-- Snowman
	[21848]  = "CC",				-- Snowman
	[21980]  = "CC",				-- Snowman
	[27880]  = "CC",				-- Stun
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
	[334307] = "CC",				-- Imperfect Polymorph (Darktower Parchments: Instant Polymorphist)
	[330607] = "CC",				-- 50UL-TR4P!
	[272188] = "CC",				-- Hammer Smash (quest)
	[264860] = "CC",				-- Binding Talisman
	[238322] = "CC",				-- Arcane Prison
	[171369] = "CC",				-- Arcane Prison
	[172692] = "CC",				-- Unbound Charge
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
	[45954]  = "Immune",			-- Ahune's Shield (damage taken reduced 90%)
	[133362] = "CC",				-- Megafantastic Discombobumorphanator
	[286167] = "CC",				-- Cold Crash
	[229413] = "CC",				-- Stormburst
	[142769] = "CC",				-- Stasis Beam
	[133308] = "Root",				-- Throw Net
	[291399] = "CC",				-- Blinding Peck
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
	[33844]  = "Root",				-- Entangling Roots
	[178072] = "CC",				-- Howl of Terror
	[32323]  = "CC",				-- Charge
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
	[35963]  = "Root",				-- Improved Wing Clip
	[189287] = "Snare",				-- Grind
	[79857]  = "Snare",				-- Blast Wave
	[162638] = "Silence",			-- Avenger's Shield
	[189265] = "Snare",				-- Shred
	[139777] = "CC",				-- Stone Smash
	[304349] = "Silence",			-- Pacifying Screech
	[292693] = "Immune",			-- Nullification Field
	[300524] = "CC",				-- Song of Azshara
	[91933]  = "CC",				-- Intimidating Roar
	[228318] = "Other",				-- Enrage
	[276846] = "CC",				-- Silvered Weapons
	[287478] = "CC",				-- Oppressive Power
	[287371] = "CC",				-- Spirits of Madness
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
	[35474]  = "CC",				-- Drums of Panic
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
	[11538]  = "Snare",				-- Frostbolt
	[21369]  = "Snare",				-- Frostbolt
	[20297]  = "Snare",				-- Frostbolt
	[20806]  = "Snare",				-- Frostbolt
	[20819]  = "Snare",				-- Frostbolt
	[12737]  = "Snare",				-- Frostbolt
	[20792]  = "Snare",				-- Frostbolt
	[17503]  = "Snare",				-- Frostbolt
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
	[12520]  = "Root",				-- Teleport from Azshara Tower
	[12521]  = "Root",				-- Teleport from Azshara Tower
	[12024]  = "Root",				-- Net
	[12023]  = "Root",				-- Web
	[13608]  = "Root",				-- Hooked Net
	[10017]  = "Root",				-- Frost Hold
	[23279]  = "Root",				-- Crippling Clip
	[3542]   = "Root",				-- Naraxis Web
	[5567]   = "Root",				-- Miring Mud
	[4932]   = "ImmuneSpell",		-- Ward of Myzrael
	[7383]   = "ImmunePhysical",	-- Water Bubble
	[101]    = "CC",				-- Trip
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
	[8646]   = "CC",				-- Snap Kick
	[27620]  = "Silence",			-- Snap Kick
	[27814]  = "Silence",			-- Kick
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
	[18812]  = "CC",				-- Knockdown
	[11430]  = "CC",				-- Slam
	[28335]  = "CC",				-- Whirlwind
	[16451]  = "CC",				-- Judge's Gavel
	[23601]  = "CC",				-- Scatter Shot
	[25260]  = "CC",				-- Wings of Despair
	[23275]  = "CC",				-- Dreadful Fright
	[24919]  = "CC",				-- Nauseous
	[21167]  = "CC",				-- Snowball
	[25815]  = "CC",				-- Frightening Shriek
	[290378] = "Immune",			-- Rock of Life
	[9612]   = "CC",				-- Ink Spray (Chance to hit reduced by 50%)
	[4320]   = "Silence",			-- Trelane's Freezing Touch
	[4243]   = "Silence",			-- Pester Effect
	[9552]   = "Silence",			-- Searing Flames
	[10576]  = "Silence",			-- Piercing Howl
	[12943]  = "Silence",			-- Fell Curse Effect
	[23417]  = "Silence",			-- Smother
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
	[26198]  = "CC",				-- Whisperings of C'Thun
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
	---- PVE SHADOWLANDS
	------------------------
	-- Castle Nathria
	-- -- Trash
	[341867] = "CC",				-- Subdue
	[329438] = "CC",				-- Doubt (chance to hit with attacks and abilities decreased by 100%)
	[327474] = "CC",				-- Crushing Doubt
	[326227] = "CC",				-- Insidious Anxieties
	[340622] = "CC",				-- Headbutt
	[339525] = "Root",				-- Concentrate Anima
	-- -- Shriekwing
	[343024] = "CC",				-- Horrified
	-- -- Sun King's Salvation
	[333145] = "CC",				-- Return to Stone
	-- -- Artificer Xy'mox
	[326302] = "CC",				-- Stasis Trap
	[327414] = "CC",				-- Possession
	-- -- Hungering Destroyer
	[329298] = "Other",				-- Gluttonous Miasma (healing received reduced by 100%)
	-- -- Lady Inerva Darkvein
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
	-- -- De Other Side
	[201441] = "Immune",			-- Thorium Plating
	[201581] = "Immune",			-- Mega Miniaturization Turbo-Beam (Chance to be hit by attacks and spells reduced by 95%)
	[202310] = "CC",				-- Hyper Zap-o-matic Ultimate Mark III
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
	-- -- Mists of Tirna Scithe
	[323149] = "Immune",			-- Embrace Darkness (not immune, damage taken reduced by 50%)
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
	[324859] = "Root",				-- Bramblethorn Entanglement
	[325027] = "Snare",				-- Bramble Burst
	[322486] = "Snare",				-- Overgrowth
	-- -- The Necrotic Wake
	[320646] = "CC",				-- Fetid Gas
	[335141] = "ImmunePhysical",	-- Dark Shroud
	[343504] = "CC",				-- Dark Grasp
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
	[333489] = "Other",				-- Necrotic Breath (healing received reduced by 50%)
	[320573] = "Other",				-- Shadow Well (healing received reduced by 100%)
	[324381] = "Snare",				-- Chill Scythe
	-- -- Plaguefall
	[321521] = "Immune",			-- Congealed Bile (not immune, damage taken reduced by 75%)
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
	-- -- Sanguine Depths
	[324092] = "Immune",			-- Shining Radiance (not immune, damage taken reduced by 65%)
	[327107] = "Immune",			-- Shining Radiance (not immune, damage taken reduced by 75%)
	[326836] = "Silence",			-- Curse of Suppression
	[335306] = "Root",				-- Barbed Shackles
	-- -- Spires of Ascension
	[324205] = "CC",				-- Blinding Flash
	[323878] = "CC",				-- Drained
	[323744] = "CC",				-- Pounce
	[347598] = "CC",				-- Carriage Knockdown
	[330388] = "CC",				-- Terrifying Screech
	[330453] = "Snare",				-- Stone Breath
	[331906] = "Snare",				-- Fling Muck
	-- -- Theater of Pain
	[333540] = "CC",				-- Opportunity Strikes
	[320112] = "CC",				-- Blood and Glory
	[320287] = "CC",				-- Blood and Glory
	[319539] = "CC",				-- Soulless
	[333567] = "CC",				-- Possession
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
	[345524] = "CC",				-- Mad Wizard's Confusion
	[333767] = "CC",				-- Distracting Charges
	[342375] = "Silence",			-- Tormenting Backlash
	[342414] = "Silence",			-- Cracked Mindscreecher
	[332547] = "Disarm",			-- Animate Armaments
	[337097] = "Root",				-- Grasping Tendrils
	[331362] = "Root",				-- Hateful Shard-Ring
	[342373] = "Root",				-- Fae Tendrils
	[333561] = "Root",				-- Nightmare Tendrils
	[332205] = "Other",				-- Smoking Shard of Teleportation
	[331188] = "Other",				-- Cadaverous Cleats
	[333920] = "ImmuneSpell",		-- Cloak of Shadows
	[332831] = "ImmuneSpell",		-- Anti-Magic Zone
	[335103] = "Immune",			-- Divine Shield
	[295963] = "Immune",			-- Crumbling Aegis
	[308204] = "Immune",			-- Crumbling Aegis
	[331356] = "Immune",			-- Craven Strategem
	[323220] = "Immune",			-- Shield of Unending Fury
	[331464] = "Immune",			-- Fogged Crystal (not immune, damage taken reduced by 90%)
	[342783] = "ImmunePhysical",	-- Crystallized Dreams
	[322136] = "Snare",				-- Dissolving Vial
	[338065] = "Snare",				-- Stoneflesh Figurine
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
	[170751] = "CC",				-- Crushing Shadows
	[329608] = "CC",				-- Terrifying Roar
	[242391] = "CC",				-- Terror
	[301952] = "Silence",			-- Silencing Calm
	[329903] = "Silence",			-- Silence
	[329319] = "Disarm",			-- Disarm
	[304949] = "Root",				-- Falling Strike
	[295945] = "Root",				-- Rat Traps
	[304831] = "Root",				-- Chains of Ice
	[296023] = "Root",				-- Lockdown
	[259220] = "Root",				-- Barbed Net
	[296454] = "Immune",			-- Vanish to Nothing
	[167012] = "Immune",			-- Incorporeal (not immune, damage taken reduced by 99%)
	[336556] = "Immune",			-- Concealing Fog (not immune, damage taken reduced by 50%)
	[294517] = "Immune",			-- Phasing Roar (not immune, damage taken reduced by 80%)
	[339006] = "ImmunePhysical",	-- Ephemeral Body (not immune, physical damage taken reduced by 75%)
	[297166] = "ImmunePhysical",	-- Armor Plating (not immune, physical damage taken reduced by 50%)
	[339010] = "ImmuneSpell",		-- Resonating Body (not immune, magic damage taken reduced by 75%)
	[302543] = "ImmuneSpell",		-- Glimmering Barrier (not immune, magic damage taken reduced by 50%)
	[38572]  = "Other",				-- Mortal Cleave (healing effects reduced by 50%)
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
	[24375]  = "CC",				-- War Stomp
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
	[25654]  = "CC",				-- Tail Lash
	[25515]  = "CC",				-- Bash
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
	-- -- Ayamiss the Hunter
	[25852]  = "CC",				-- Lash
	[6608]   = "Disarm",			-- Dropped Weapon
	[25725]  = "CC",				-- Paralyze
	-- -- Ossirian the Unscarred
	[25189]  = "CC",				-- Enveloping Winds
	------------------------
	-- Temple of Ahn'Qiraj Raid
	-- -- Trash
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
	[29849]  = "Root",				-- Frost Nova
	[30094]  = "Root",				-- Frost Nova
	[28350]  = "Other",				-- Veil of Darkness (immune to direct healing)
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
	[28440]  = "Other",				-- Veil of Shadow
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
	[17307]  = "CC",				-- Knockout
	[15970]  = "CC",				-- Sleep
	[3589]   = "Silence",			-- Deafening Screech
	[54791]  = "Snare",				-- Frostbolt
	[66290]  = "CC",				-- Sleep
	[82107]  = "CC",				-- Deep Freeze
	-- -- Dire Maul
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
		arena1      = "ArenaEnemyFrame1ClassPortrait",
		arena2      = "ArenaEnemyFrame2ClassPortrait",
		arena3      = "ArenaEnemyFrame3ClassPortrait",
		arena4      = "ArenaEnemyFrame4ClassPortrait",
		arena5      = "ArenaEnemyFrame5ClassPortrait",
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
	XPerl = {
		player       = "XPerl_PlayerportraitFrameportrait",
		pet          = "XPerl_Player_PetportraitFrameportrait",
		target       = "XPerl_TargetportraitFrameportrait",
		targettarget = "XPerl_TargettargetportraitFrameportrait",
		focus        = "XPerl_FocusportraitFrameportrait",
		focustarget = "XPerl_FocustargetportraitFrameportrait",
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
		arena1 = "SyncFrame1Class",
		arena2 = "SyncFrame2Class",
		arena3 = "SyncFrame3Class",
		arena4 = "SyncFrame4Class",
		arena5 = "SyncFrame5Class",
	},
	SUF = {
		player       = SUFUnitplayer and SUFUnitplayer.portrait or nil,
		pet          = SUFUnitpet and SUFUnitpet.portrait or nil,
		target       = SUFUnittarget and SUFUnittarget.portrait or nil,
		targettarget = SUFUnittargettarget and SUFUnittargettarget.portrait or nil,
		focus        = SUFUnitfocus and SUFUnitfocus.portrait or nil,
		focustarget  = SUFUnitfocustarget and SUFUnitfocustarget.portrait or nil,
		party1       = SUFHeaderpartyUnitButton1 and SUFHeaderpartyUnitButton1.portrait or nil,
		party2       = SUFHeaderpartyUnitButton2 and SUFHeaderpartyUnitButton2.portrait or nil,
		party3       = SUFHeaderpartyUnitButton3 and SUFHeaderpartyUnitButton3.portrait or nil,
		party4       = SUFHeaderpartyUnitButton4 and SUFHeaderpartyUnitButton4.portrait or nil,
		arena1       = SUFHeaderarenaUnitButton1 and SUFHeaderarenaUnitButton1.portrait or nil,
		arena2       = SUFHeaderarenaUnitButton2 and SUFHeaderarenaUnitButton2.portrait or nil,
		arena3       = SUFHeaderarenaUnitButton3 and SUFHeaderarenaUnitButton3.portrait or nil,
		arena4       = SUFHeaderarenaUnitButton4 and SUFHeaderarenaUnitButton4.portrait or nil,
		arena5       = SUFHeaderarenaUnitButton5 and SUFHeaderarenaUnitButton5.portrait or nil,
	},
	-- more to come here?
}

-------------------------------------------------------------------------------
-- Default settings
local DBdefaults = {
	version = 7.0, -- This is the settings version, not necessarily the same as the LoseControl version
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
			anchor = "None",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = false, ImmuneSpell = false, ImmunePhysical = false, CC = true,  Silence = true,  Disarm = true,  Other = false, Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = false, ImmuneSpell = false, ImmunePhysical = false, CC = true,  Silence = true,  Disarm = true,  Other = false, Root = true,  Snare = true }
				},
				interrupt = {
					friendly = false
				}
			}
		},
		player2 = {
			enabled = true,
			size = 56,
			alpha = 1,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true, Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true, Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
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
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				interrupt = {
					friendly = true,
					enemy    = true
				}
			}
		},
		arena2 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				interrupt = {
					friendly = true,
					enemy    = true
				}
			}
		},
		arena3 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				interrupt = {
					friendly = true,
					enemy    = true
				}
			}
		},
		arena4 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				interrupt = {
					friendly = true,
					enemy    = true
				}
			}
		},
		arena5 = {
			enabled = true,
			size = 28,
			alpha = 1,
			anchor = "Blizzard",
			categoriesEnabled = {
				buff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				debuff = {
					friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true },
					enemy    = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true }
				},
				interrupt = {
					friendly = true,
					enemy    = true
				}
			}
		},
		raid1 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid2 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid3 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid4 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid5 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid6 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid7 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid8 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid9 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid10 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid11 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid12 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid13 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid14 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid15 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid16 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid17 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid18 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid19 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid20 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid21 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid22 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid23 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid24 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid25 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid26 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid27 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid28 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid29 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid30 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid31 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid32 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid33 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid34 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid35 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid36 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid37 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid38 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid39 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
				interrupt = { friendly = true }
			}
		},
		raid40 = {
			enabled = true,
			size = 20,
			alpha = 1,
			anchor = "BlizzardRaidFrames",
			categoriesEnabled = {
				buff =      { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = false,  Root = true,  Snare = true } },
				debuff =    { friendly = { PvE = true,  Immune = true,  ImmuneSpell = true,  ImmunePhysical = true,  CC = true,  Silence = true,  Disarm = true,  Other = true,  Root = true,  Snare = true } },
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
			RegisterUnitWatch(self, true)
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
			RegisterUnitWatch(self, true)
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
			UnregisterUnitWatch(self)
		elseif unitId == "focus" then
			self:UnregisterEvent("UNIT_AURA")
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		elseif unitId == "focustarget" then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
			self:UnregisterEvent("UNIT_TARGET")
			self:UnregisterEvent("UNIT_AURA")
			UnregisterUnitWatch(self)
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
	for cSpellId, cPriority  in pairs(LoseControlDB.customSpellIds) do
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
			( LoseControlDB.disablePartyInBG and strfind(self.unitId, "party") ) or
			( LoseControlDB.disableRaidInBG and strfind(self.unitId, "raid") ) or
			( LoseControlDB.disableArenaInBG and strfind(self.unitId, "arena") )
		)
	)and not (
		inInstance and instanceType == "arena" and (
			( LoseControlDB.disablePartyInArena and strfind(self.unitId, "party") ) or
			( LoseControlDB.disableRaidInArena and strfind(self.unitId, "raid") )
		)
	) and not (
		IsInRaid() and LoseControlDB.disablePartyInRaid and strfind(self.unitId, "party") and not (inInstance and (instanceType=="arena" or instanceType=="pvp"))
	)
	return enabled
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

-- Function to hook the raid frame and anchors the LoseControl raid frames to their corresponding blizzard raid frame
local function HookCompactRaidFrame(compactRaidFrame)
	if not(compactRaidFrame.lchooked) then
		compactRaidFrame:HookScript("OnAttributeChanged", function(self, key, value)
			if (key == "unit" and self:IsVisible()) then
				if (value ~= nil) then
					local icon = LCframes[value]
					if (icon ~= nil) then
						local frame = icon.frame or LoseControlDB.frames[value]
						if (frame ~= nil) then
							anchors.BlizzardRaidFrames[value] = self:GetName()
							if (frame.anchor == "BlizzardRaidFrames") then
								icon.anchor = self
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
				end
			end
		end)
		compactRaidFrame:HookScript("OnShow", function(self)
			if (self:IsVisible()) then
				local anchorUnitId = compactRaidFrame:GetAttribute("unit")
				if (anchorUnitId ~= nil) then
					local icon = LCframes[anchorUnitId]
					if (icon ~= nil) then
						local frame = icon.frame or LoseControlDB.frames[anchorUnitId]
						if (frame ~= nil) then
							anchors.BlizzardRaidFrames[anchorUnitId] = self:GetName()
							if (frame.anchor == "BlizzardRaidFrames") then
								icon.anchor = self
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
				end
			end
		end)
		compactRaidFrame.lchooked = true
	end
end

-- Function to hook the raid frames and anchors the LoseControl raid frames to their corresponding blizzard raid frame
function LoseControl:MainHookCompactRaidFrames()
	for i = 1, 40 do
		local compactRaidFrame = _G["CompactRaidFrame"..i]
		if (compactRaidFrame ~= nil) then
			HookCompactRaidFrame(compactRaidFrame)
		end
	end
	for i = 1, 8 do
		for j = 1, 5 do
			local compactRaidFrame = _G["CompactRaidGroup"..i.."Member"..j]
			if (compactRaidFrame ~= nil) then
				HookCompactRaidFrame(compactRaidFrame)
			end
		end
	end
	hooksecurefunc("CompactUnitFrame_OnLoad", function(self)
		HookCompactRaidFrame(self)
	end)
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
		self.VERSION = "7.0"
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
		self:MainHookCompactRaidFrames()
		if Masque then
			for _, v in pairs(LCframes) do
				v.MasqueGroup = Masque:Group(addonName, v.unitId)
				if (LoseControlDB.frames[v.unitId].anchor ~= "Blizzard") then
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
		end
	end
end

LoseControl:RegisterEvent("ADDON_LOADED")

function LoseControl:CheckSUFUnitsAnchors(updateFrame)
	if not(ShadowUF and (SUFUnitplayer or SUFUnitpet or SUFUnittarget or SUFUnittargettarget or SUFHeaderpartyUnitButton1 or SUFHeaderpartyUnitButton2 or SUFHeaderpartyUnitButton3 or SUFHeaderpartyUnitButton4)) then return false end
	local frames = { self.unitId }
	if strfind(self.unitId, "party") then
		frames = { "party1", "party2", "party3", "party4" }
	elseif strfind(self.unitId, "arena") then
		frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
	elseif strfind(self.unitId, "raid") then
		frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
	end
	for _, unitId in ipairs(frames) do
		if anchors.SUF.player == nil then anchors.SUF.player = SUFUnitplayer and SUFUnitplayer.portrait or nil end
		if anchors.SUF.pet == nil then anchors.SUF.pet    = SUFUnitpet and SUFUnitpet.portrait or nil end
		if anchors.SUF.target == nil then anchors.SUF.target = SUFUnittarget and SUFUnittarget.portrait or nil end
		if anchors.SUF.targettarget == nil then anchors.SUF.targettarget = SUFUnittargettarget and SUFUnittargettarget.portrait or nil end
		if anchors.SUF.focus == nil then anchors.SUF.focus = SUFUnitfocus and SUFUnitfocus.portrait or nil end
		if anchors.SUF.focustarget == nil then anchors.SUF.focustarget = SUFUnitfocustarget and SUFUnitfocustarget.portrait or nil end
		if anchors.SUF.party1 == nil then anchors.SUF.party1 = SUFHeaderpartyUnitButton1 and SUFHeaderpartyUnitButton1.portrait or nil end
		if anchors.SUF.party2 == nil then anchors.SUF.party2 = SUFHeaderpartyUnitButton2 and SUFHeaderpartyUnitButton2.portrait or nil end
		if anchors.SUF.party3 == nil then anchors.SUF.party3 = SUFHeaderpartyUnitButton3 and SUFHeaderpartyUnitButton3.portrait or nil end
		if anchors.SUF.party4 == nil then anchors.SUF.party4 = SUFHeaderpartyUnitButton4 and SUFHeaderpartyUnitButton4.portrait or nil end
		if anchors.SUF.arena1 == nil then anchors.SUF.arena1 = SUFHeaderarenaUnitButton1 and SUFHeaderarenaUnitButton1.portrait or nil end
		if anchors.SUF.arena2 == nil then anchors.SUF.arena2 = SUFHeaderarenaUnitButton2 and SUFHeaderarenaUnitButton2.portrait or nil end
		if anchors.SUF.arena3 == nil then anchors.SUF.arena3 = SUFHeaderarenaUnitButton3 and SUFHeaderarenaUnitButton3.portrait or nil end
		if anchors.SUF.arena4 == nil then anchors.SUF.arena4 = SUFHeaderarenaUnitButton4 and SUFHeaderarenaUnitButton4.portrait or nil end
		if anchors.SUF.arena5 == nil then anchors.SUF.arena5 = SUFHeaderarenaUnitButton5 and SUFHeaderarenaUnitButton5.portrait or nil end
		if updateFrame and anchors.SUF[unitId] ~= nil then
			local frame = LoseControlDB.frames[self.fakeUnitId or unitId]
			local icon = LCframes[unitId]
			if self.fakeUnitId == "player2" then
				icon = LCframeplayer2
			end
			local newAnchor = _G[anchors[frame.anchor][unitId]] or (type(anchors[frame.anchor][unitId])=="table" and anchors[frame.anchor][unitId] or UIParent)
			if newAnchor ~= nil and icon.anchor ~= newAnchor then
				icon.anchor = newAnchor
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
				local PositionXEditBox
				local PositionYEditBox
				if strfind(unitId, "party") then
					if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
					end
				elseif strfind(unitId, "arena") then
					if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelarenaPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelarenaPositionYEditBox']
					end
				elseif strfind(unitId, "raid") then
					if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'])) then
						PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
						PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
					end
				else
					PositionXEditBox = _G['LoseControlOptionsPanel'..unitId..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..unitId..'PositionYEditBox']
				end
				if (PositionXEditBox and PositionYEditBox) then
					PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
					PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
					if (frame.anchor ~= "Blizzard") then
						PositionXEditBox:Enable()
						PositionYEditBox:Enable()
					else
						PositionXEditBox:Disable()
						PositionYEditBox:Disable()
					end
					PositionXEditBox:SetCursorPosition(0)
					PositionYEditBox:SetCursorPosition(0)
				end
				if icon.anchor:GetParent() then
					icon:SetFrameLevel(icon.anchor:GetParent():GetFrameLevel()+((frame.anchor ~= "None" and frame.anchor ~= "Blizzard") and 3 or 0))
				end
			end
		end
	end
	if self.fakeUnitId ~= "player2" and self.unitId == "player" then
		LCframeplayer2:CheckSUFUnitsAnchors(updateFrame)
	end
	return true
end

-- Initialize a frame's position and register for events
function LoseControl:PLAYER_ENTERING_WORLD() -- this correctly anchors enemy arena frames that aren't created until you zone into an arena
	local unitId = self.unitId
	self.frame = LoseControlDB.frames[self.fakeUnitId or unitId] -- store a local reference to the frame's settings
	local frame = self.frame
	local enabled = self:GetEnabled()
	if (ShadowUF ~= nil) and not(self:CheckSUFUnitsAnchors(false)) and (self.SUFDelayedSearch == nil) then
		self.SUFDelayedSearch = GetTime()
		C_Timer.After(8, function()	-- delay checking to make sure all variables of the other addons are loaded
			self:CheckSUFUnitsAnchors(true)
		end)
	end
	self.anchor = _G[anchors[frame.anchor][unitId]] or (type(anchors[frame.anchor][unitId])=="table" and anchors[frame.anchor][unitId] or UIParent)
	self.unitGUID = UnitGUID(unitId)
	self.parent:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
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
	local PositionXEditBox
	local PositionYEditBox
	if strfind(unitId, "party") then
		if (unitId == ((_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'] ~= nil) and UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown']) or "party1")) then
			PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
		end
	elseif strfind(unitId, "arena") then
		if (unitId == ((_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown'] ~= nil) and UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown']) or "arena1")) then
			PositionXEditBox = _G['LoseControlOptionsPanelarenaPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelarenaPositionYEditBox']
		end
	elseif strfind(unitId, "raid") then
		if (unitId == ((_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'] ~= nil) and UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown']) or "raid1")) then
			PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
		end
	else
		PositionXEditBox = _G['LoseControlOptionsPanel'..unitId..'PositionXEditBox']
		PositionYEditBox = _G['LoseControlOptionsPanel'..unitId..'PositionYEditBox']
	end
	if (PositionXEditBox and PositionYEditBox) then
		PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
		PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
		if (frame.anchor ~= "Blizzard") then
			PositionXEditBox:Enable()
			PositionYEditBox:Enable()
		else
			PositionXEditBox:Disable()
			PositionYEditBox:Disable()
		end
		PositionXEditBox:SetCursorPosition(0)
		PositionYEditBox:SetCursorPosition(0)
	end
	if self.anchor:GetParent() then
		self:SetFrameLevel(self.anchor:GetParent():GetFrameLevel()+((frame.anchor ~= "None" and frame.anchor ~= "Blizzard") and 3 or 0))
	end
	if self.MasqueGroup then
		self.MasqueGroup:ReSkin()
	end
	
	SetInterruptIconsSize(self, frame.size)
	
	--self:SetAlpha(frame.alpha) -- doesn't seem to work; must manually set alpha after the cooldown is displayed, otherwise it doesn't apply.
	self:Hide()
	self:GetParent():Hide()
	
	if enabled and not self.unlockMode then
		self:UNIT_AURA(self.unitId, 0)
	end
end

function LoseControl:GROUP_ROSTER_UPDATE()
	local unitId = self.unitId
	local frame = self.frame
	if (frame == nil) or (unitId == nil) or not(strfind(unitId, "party") or (strfind(unitId, "raid"))) then
		return
	end
	local enabled = self:GetEnabled()
	self:RegisterUnitEvents(enabled)
	self.unitGUID = UnitGUID(unitId)
	self:CheckSUFUnitsAnchors(true)
	if enabled and not self.unlockMode then
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
				v:UNIT_AURA(k, typeUpdate)
				if (k == "player") and LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(k, typeUpdate)
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
	local inInstance, instanceType = IsInInstance()
	self:RegisterUnitEvents(self:GetEnabled())
	self.unitGUID = UnitGUID(self.unitId)
	self:CheckSUFUnitsAnchors(true)
	if enabled and not self.unlockMode then
		self:UNIT_AURA(unitId, 0)
	end
end

function LoseControl:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	self:ARENA_OPPONENT_UPDATE()
end

-- This event check interrupts and targettarget/focustarget unit aura triggers
function LoseControl:COMBAT_LOG_EVENT_UNFILTERED()
	if self.unitId == "target" then
		-- Check Interrupts
		local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, _, _, _, _, spellSchool = CombatLogGetCurrentEventInfo()
		if (destGUID ~= nil) then
			if (event == "SPELL_INTERRUPT") then
				local duration = interruptsIds[spellId]
				if (duration ~= nil) then
					if (strfind(destGUID, "Player-") == 1) then
						local unitIdFromGUID
						for _, v in pairs(LCframes) do
							if (UnitGUID(v.unitId) == destGUID) then
								unitIdFromGUID = v.unitId
								break
							end
						end
						if (unitIdFromGUID ~= nil) then
							local _, destClass = GetPlayerInfoByGUID(destGUID)
							for i = 1, 40 do
								local _, _, _, _, _, _, _, _, _, auxSpellId = UnitBuff(unitIdFromGUID, i)
								if not auxSpellId then break end
								if (destClass == "DRUID") then
									if auxSpellId == 234084 then		-- Moon and Stars (Druid)
										duration = duration * 0.3
									end
								end
								if auxSpellId == 317920 then		-- Concentration Aura (Paladin)
									duration = duration * 0.7
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
					UpdateUnitAuraByUnitGUID(destGUID, -20)
				end
			elseif (((event == "UNIT_DIED") or (event == "UNIT_DESTROYED") or (event == "UNIT_DISSIPATES")) and (select(2, GetPlayerInfoByGUID(destGUID)) ~= "HUNTER")) then
				if (InterruptAuras[destGUID] ~= nil) then
					InterruptAuras[destGUID] = nil
					UpdateUnitAuraByUnitGUID(destGUID, -21)
				end
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

	if (self.anchor:IsVisible() or (self.frame.anchor ~= "None" and self.frame.anchor ~= "Blizzard")) and UnitExists(self.unitId) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetPlayerTargetTarget) or not(UnitIsUnit("player", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disablePlayerTargetTarget) or not(UnitIsUnit("targettarget", "player")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetTargetTarget) or not(UnitIsUnit("targettarget", "target")))) and ((self.unitId ~= "targettarget") or (not(LoseControlDB.disableTargetDeadTargetTarget) or (UnitHealth("target") > 0))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disablePlayerFocusPlayerFocusTarget) or not(UnitIsUnit("player", "focus") and UnitIsUnit("player", "focustarget")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disablePlayerFocusTarget) or not(UnitIsUnit("focustarget", "player")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disableFocusFocusTarget) or not(UnitIsUnit("focustarget", "focus")))) and ((self.unitId ~= "focustarget") or (not(LoseControlDB.disableFocusDeadFocusTarget) or (UnitHealth("focus") > 0))) then
		local reactionToPlayer = ((self.unitId == "target" or self.unitId == "focus" or self.unitId == "targettarget" or self.unitId == "focustarget" or strfind(self.unitId, "arena")) and UnitCanAttack("player", unitId)) and "enemy" or "friendly"
		-- Check debuffs
		for i = 1, 40 do
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
			
			-- exceptions
			if spellId == 212183 and unitId == "player" then -- Smoke Bomb (don't show countdown)
				expirationTime = 0
			elseif spellId == 212638 or spellId == 212150 then	-- Tracker's Net and Cheap Tricks
				if (UnitIsPlayer(unitId)) then
					local _, class = UnitClass(unitId)
					if ((class == "PRIEST") or (class == "MAGE") or (class == "WARLOCK")) then
						spellId = 1
					elseif ((class == "SHAMAN") or (class == "DRUID")) then
						if (unitId == "player") then 
							local specID = GetSpecialization()
							if (specID ~= nil) then
								specID = GetSpecializationInfo(specID);
							end
							if ((specID ~= nil) and (specID ~= 0) and (specID ~= 263) and (specID ~= 103) and (specID ~= 104)) then
								spellId = 1
							end
						else
							local powerTypeID = UnitPowerType(unitId)
							if ((powerTypeID ~= nil) and (powerTypeID ~= 1) and (powerTypeID ~= 3) and (powerTypeID ~= 11)) then
								spellId = 1
							end
						end
					end
				end
			end
			
			local spellCategory = spellIds[spellId]
			local Priority = priority[spellCategory]
			if self.frame.categoriesEnabled.debuff[reactionToPlayer][spellCategory] then
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
		for i = 1, 40 do
			local localForceEventUnitAuraAtEnd = false
			local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i) -- defaults to "HELPFUL" filter
			if not spellId then break end -- no more debuffs, terminate the loop
			if debug then print(unitId, "buff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
			
			if duration == 0 and expirationTime == 0 then
				expirationTime = GetTime() + 1 -- normal expirationTime = 0
			elseif expirationTime > 0 then
				localForceEventUnitAuraAtEnd = (self.unitId == "targettarget")
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
			
			local spellCategory = spellIds[spellId]
			local Priority = priority[spellCategory]
			if self.frame.categoriesEnabled.buff[reactionToPlayer][spellCategory] then
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
		if ((self.unitGUID ~= nil) and (priority.Interrupt > 0) and self.frame.categoriesEnabled.interrupt[reactionToPlayer] and (UnitIsPlayer(unitId) or (((unitId ~= "target") or (LoseControlDB.showNPCInterruptsTarget)) and ((unitId ~= "focus") or (LoseControlDB.showNPCInterruptsFocus)) and ((unitId ~= "targettarget") or (LoseControlDB.showNPCInterruptsTargetTarget)) and ((unitId ~= "focustarget") or (LoseControlDB.showNPCInterruptsFocusTarget))))) then
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
								forceEventUnitAuraAtEnd = false
								local nextTimerUpdate = expirationTime - GetTime() + 0.05
								if nextTimerUpdate < 0.05 then
									nextTimerUpdate = 0.05
								end
								C_Timer.After(nextTimerUpdate, function()
									if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < (GetTime() - 0.04))) then
										self:UNIT_AURA(unitId, 20)
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
							elseif Priority > maxPriority then
								maxPriority = Priority
								maxExpirationTime = expirationTime
								Duration = duration
								Icon = icon
								maxPriorityIsInterrupt = true
								forceEventUnitAuraAtEnd = false
								local nextTimerUpdate = expirationTime - GetTime() + 0.05
								if nextTimerUpdate < 0.05 then
									nextTimerUpdate = 0.05
								end
								C_Timer.After(nextTimerUpdate, function()
									if ((not self.unlockMode) and (self.lastTimeUnitAuraEvent == nil or self.lastTimeUnitAuraEvent < (GetTime() - 0.04))) then
										self:UNIT_AURA(unitId, 20)
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
			self:SetFrameLevel(self.anchor:GetParent():GetFrameLevel()+((self.frame.anchor ~= "None" and self.frame.anchor ~= "Blizzard") and 3 or 0)) -- must be dynamic, frame level changes all the time
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
					self:UNIT_AURA(unitId, 4)
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
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -10)
		end
	end
end

function LoseControl:PLAYER_TARGET_CHANGED()
	--if (debug) then print("PLAYER_TARGET_CHANGED") end
	if (self.unitId == "target" or self.unitId == "targettarget") then
		self.unitGUID = UnitGUID(self.unitId)
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -11)
		end
	end
end

function LoseControl:UNIT_TARGET(unitId)
	--if (debug) then print("UNIT_TARGET", unitId) end
	if (self.unitId == "targettarget" or self.unitId == "focustarget") then
		self.unitGUID = UnitGUID(self.unitId)
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -12)
		end
	end
end

function LoseControl:UNIT_PET(unitId)
	--if (debug) then print("UNIT_PET", unitId) end
	if (self.unitId == "pet") then
		self.unitGUID = UnitGUID(self.unitId)
		if not self.unlockMode then
			self:UNIT_AURA(self.unitId, -13)
		end
	end
end

-- Handle mouse dragging
function LoseControl:StopMoving()
	local frame = LoseControlDB.frames[self.unitId]
	frame.point, frame.anchor, frame.relativePoint, frame.x, frame.y = self:GetPoint()
	if not frame.anchor then
		frame.anchor = "None"
		local AnchorDropDown = _G['LoseControlOptionsPanel'..self.unitId..'AnchorDropDown']
		if (AnchorDropDown) then
			UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
		end
		if self.MasqueGroup then
			self.MasqueGroup:RemoveButton(self:GetParent())
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
	self.anchor = _G[anchors[frame.anchor][self.unitId]] or (type(anchors[frame.anchor][self.unitId])=="table" and anchors[frame.anchor][self.unitId] or UIParent)
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
	local PositionXEditBox
	local PositionYEditBox
	if strfind(self.unitId, "party") then
		if (self.unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelpartyAnchorPositionPartyDropDown'])) then
			PositionXEditBox = _G['LoseControlOptionsPanelpartyPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelpartyPositionYEditBox']
		end
	elseif strfind(self.unitId, "arena") then
		if (self.unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelarenaAnchorPositionArenaDropDown'])) then
			PositionXEditBox = _G['LoseControlOptionsPanelarenaPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelarenaPositionYEditBox']
		end
	elseif strfind(self.unitId, "raid") then
		if (self.unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanelraidAnchorPositionRaidDropDown'])) then
			PositionXEditBox = _G['LoseControlOptionsPanelraidPositionXEditBox']
			PositionYEditBox = _G['LoseControlOptionsPanelraidPositionYEditBox']
		end
	else
		PositionXEditBox = _G['LoseControlOptionsPanel'..self.unitId..'PositionXEditBox']
		PositionYEditBox = _G['LoseControlOptionsPanel'..self.unitId..'PositionYEditBox']
	end
	if (PositionXEditBox and PositionYEditBox) then
		PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
		PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
		if (frame.anchor ~= "Blizzard") then
			PositionXEditBox:Enable()
			PositionYEditBox:Enable()
		end
		PositionXEditBox:SetCursorPosition(0)
		PositionYEditBox:SetCursorPosition(0)
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
	if op:GetPushedTexture() ~= nil then op:GetPushedTexture():SetAlpha(0) op:GetPushedTexture():Hide() end
	if op:GetNormalTexture() ~= nil then op:GetNormalTexture():SetAlpha(0) op:GetNormalTexture():Hide() end
	if op:GetDisabledTexture() ~= nil then op:GetDisabledTexture():SetAlpha(0) op:GetDisabledTexture():Hide() end
	if op:GetHighlightTexture() ~= nil then op:GetHighlightTexture():SetAlpha(0) op:GetHighlightTexture():Hide() end
	if _G[op:GetName().."Shine"] ~= nil then _G[op:GetName().."Shine"]:SetAlpha(0) _G[op:GetName().."Shine"]:Hide() end
	if _G[op:GetName().."Count"] ~= nil then _G[op:GetName().."Count"]:SetAlpha(0) _G[op:GetName().."Count"]:Hide() end
	if _G[op:GetName().."HotKey"] ~= nil then _G[op:GetName().."HotKey"]:SetAlpha(0) _G[op:GetName().."HotKey"]:Hide() end
	if _G[op:GetName().."Flash"] ~= nil then _G[op:GetName().."Flash"]:SetAlpha(0) _G[op:GetName().."Flash"]:Hide() end
	if _G[op:GetName().."Name"] ~= nil then _G[op:GetName().."Name"]:SetAlpha(0) _G[op:GetName().."Name"]:Hide() end
	if _G[op:GetName().."Border"] ~= nil then _G[op:GetName().."Border"]:SetAlpha(0) _G[op:GetName().."Border"]:Hide() end
	if _G[op:GetName().."Icon"] ~= nil then _G[op:GetName().."Icon"]:SetAlpha(0) _G[op:GetName().."Icon"]:Hide() end
	
	setmetatable(o, self)
	self.__index = self
	
	o:SetParent(op)
	o.parent = op
	
	o:SetDrawEdge(false)

	-- Init class members
	if unitId == "player2" then
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
	o.text:SetText(L[o.unitId] or o.unitId)
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
	if (k ~= "player2") then
		LCframes[k] = LoseControl:new(k)
	end
end
LCframeplayer2 = LoseControl:new("player2")

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
Unlock.nextUnlockLoopTime = 0
function Unlock:LoopFunction()
	if (not self) then self = Unlock end
	if (mathabs(GetTime()-self.nextUnlockLoopTime) < 1) then
		self:OnClick()
	end
end
function Unlock:OnClick()
	if self:GetChecked() then
		_G[O.."UnlockText"]:SetText(L["Unlock"] .. L[" (drag an icon to move)"])
		local keys = {} -- for random icon sillyness
		for k in pairs(spellIds) do
			tinsert(keys, k)
		end
		for k, v in pairs(LCframes) do
			v.maxExpirationTime = 0
			v.unlockMode = true
			local frame = LoseControlDB.frames[k]
			if frame.enabled and (_G[anchors[frame.anchor][k]] or (type(anchors[frame.anchor][k])=="table" and anchors[frame.anchor][k] or frame.anchor == "None")) then -- only unlock frames whose anchor exists
				v:RegisterUnitEvents(false)
				v.texture:SetTexture(select(3, GetSpellInfo(keys[random(#keys)])))
				v.parent:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
				if v.anchor:GetParent() then
					v:SetFrameLevel(v.anchor:GetParent():GetFrameLevel()+((frame.anchor ~= "None" and frame.anchor ~= "Blizzard") and 3 or 0))
				end
				v.text:Show()
				v:Show()
				v:GetParent():Show()
				v:SetDrawSwipe(true)
				v:SetCooldown( GetTime(), 30 )
				self.nextUnlockLoopTime = GetTime()+30
				C_Timer.After(30, Unlock.LoopFunction)
				v:GetParent():SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
				v:SetMovable(true)
				v:RegisterForDrag("LeftButton")
				v:EnableMouse(true)
			end
		end
		LCframeplayer2.maxExpirationTime = 0
		LCframeplayer2.unlockMode = true
		local frame = LoseControlDB.frames.player2
		if frame.enabled and (_G[anchors[frame.anchor][LCframeplayer2.unit]] or (type(anchors[frame.anchor][LCframeplayer2.unit])=="table" and anchors[frame.anchor][LCframeplayer2.unit] or frame.anchor == "None")) then -- only unlock frames whose anchor exists
			LCframeplayer2:RegisterUnitEvents(false)
			LCframeplayer2.texture:SetTexture(select(3, GetSpellInfo(keys[random(#keys)])))
			LCframeplayer2.parent:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
			if LCframeplayer2.anchor:GetParent() then
				LCframeplayer2:SetFrameLevel(LCframeplayer2.anchor:GetParent():GetFrameLevel()+((frame.anchor ~= "None" and frame.anchor ~= "Blizzard") and 3 or 0))
			end
			LCframeplayer2.text:Show()
			LCframeplayer2:Show()
			LCframeplayer2:GetParent():Show()
			LCframeplayer2:SetDrawSwipe(true)
			LCframeplayer2:SetCooldown( GetTime(), 60 )
			LCframeplayer2:GetParent():SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
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

local DisableBlizzardCooldownCount = CreateFrame("CheckButton", O.."DisableBlizzardCooldownCount", OptionsPanel, "OptionsCheckButtonTemplate")
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

-- Slider helper function, thanks to Kollektiv
local function CreateSlider(text, parent, low, high, step, createBox, globalName)
	local name = globalName or (parent:GetName() .. text)
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(160)
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

local PrioritySlider = {}
for k in pairs(DBdefaults.priority) do
	PrioritySlider[k] = CreateSlider(L[k], OptionsPanel, 0, 100, 5, false, "Priority"..k.."Slider")
	PrioritySlider[k]:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value/5)*5;
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
for _, v in ipairs({ "player", "pet", "target", "targettarget", "focus", "focustarget", "party", "arena", "raid" }) do
	local OptionsPanelFrame = CreateFrame("Frame", O..v)
	OptionsPanelFrame.parent = addonName
	OptionsPanelFrame.name = L[v]

	local AnchorDropDownLabel = OptionsPanelFrame:CreateFontString(O..v.."AnchorDropDownLabel", "ARTWORK", "GameFontNormal")
	AnchorDropDownLabel:SetText(L["Anchor"])
	local AnchorDropDown2Label
	if v == "player" then
		AnchorDropDown2Label = OptionsPanelFrame:CreateFontString(O..v.."AnchorDropDown2Label", "ARTWORK", "GameFontNormal")
		AnchorDropDown2Label:SetText(L["Anchor"])
	end
	local PositionEditBoxLabel = OptionsPanelFrame:CreateFontString(O..v.."PositionEditBoxLabel", "ARTWORK", "GameFontNormal")
	PositionEditBoxLabel:SetText(L["Position"])
	local PositionXEditBoxLabel = OptionsPanelFrame:CreateFontString(O..v.."PositionXEditBoxLabel", "ARTWORK", "GameFontNormal")
	PositionXEditBoxLabel:SetText(L["x:"])
	local PositionYEditBoxLabel = OptionsPanelFrame:CreateFontString(O..v.."PositionYEditBoxLabel", "ARTWORK", "GameFontNormal")
	PositionYEditBoxLabel:SetText(L["y:"])
	local CategoriesEnabledLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoriesEnabledLabel", "ARTWORK", "GameFontNormal")
	CategoriesEnabledLabel:SetText(L["CategoriesEnabledLabel"])
	CategoriesEnabledLabel:SetJustifyH("LEFT")
	local CategoryEnabledInterruptLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledInterruptLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledInterruptLabel:SetText(L["Interrupt"]..":")
	local CategoryEnabledPvELabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledPvELabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledPvELabel:SetText(L["PvE"]..":")
	local CategoryEnabledImmuneLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledImmuneLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledImmuneLabel:SetText(L["Immune"]..":")
	local CategoryEnabledImmuneSpellLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledImmuneSpellLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledImmuneSpellLabel:SetText(L["ImmuneSpell"]..":")
	local CategoryEnabledImmunePhysicalLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledImmunePhysicalLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledImmunePhysicalLabel:SetText(L["ImmunePhysical"]..":")
	local CategoryEnabledCCLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledCCLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledCCLabel:SetText(L["CC"]..":")
	local CategoryEnabledSilenceLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledSilenceLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledSilenceLabel:SetText(L["Silence"]..":")
	local CategoryEnabledDisarmLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledDisarmLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledDisarmLabel:SetText(L["Disarm"]..":")
	local CategoryEnabledRootLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledRootLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledRootLabel:SetText(L["Root"]..":")
	local CategoryEnabledSnareLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledSnareLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledSnareLabel:SetText(L["Snare"]..":")
	local CategoryEnabledOtherLabel = OptionsPanelFrame:CreateFontString(O..v.."CategoryEnabledOtherLabel", "ARTWORK", "GameFontNormal")
	CategoryEnabledOtherLabel:SetText(L["Other"]..":")
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
	
	local AnchorDropDown = CreateFrame("Frame", O..v.."AnchorDropDown", OptionsPanelFrame, "UIDropDownMenuTemplate")
	function AnchorDropDown:OnClick()
		UIDropDownMenu_SetSelectedValue(AnchorDropDown, self.value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, unitId in ipairs(frames) do
			local frame = LoseControlDB.frames[unitId]
			local icon = LCframes[unitId]
			frame.anchor = self.value
			icon.anchor = _G[anchors[frame.anchor][unitId]] or (type(anchors[frame.anchor][unitId])=="table" and anchors[frame.anchor][unitId] or UIParent)
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
					if icon.MasqueGroup then
						icon.MasqueGroup:RemoveButton(icon:GetParent())
					end
					_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"]:SetValue(portrSizeValue)
					_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"].editbox:SetText(portrSizeValue)
					_G[OptionsPanelFrame:GetName() .. "IconSizeSlider"].editbox:SetCursorPosition(0)
				end
			else
				if icon.MasqueGroup then
					icon.MasqueGroup:RemoveButton(icon:GetParent())
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
			local PositionXEditBox
			local PositionYEditBox
			if v == "party" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionPartyDropDown'])) then
					PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
				end
			elseif v == "arena" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionArenaDropDown'])) then
					PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
				end
			elseif v == "raid" then
				if (unitId == UIDropDownMenu_GetSelectedValue(_G['LoseControlOptionsPanel'..v..'AnchorPositionRaidDropDown'])) then
					PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
					PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
				end
			else
				PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
				PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
			end
			if (PositionXEditBox and PositionYEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
				end
				PositionXEditBox:SetCursorPosition(0)
				PositionYEditBox:SetCursorPosition(0)
				PositionXEditBox:ClearFocus()
				PositionYEditBox:ClearFocus()
			end
			if icon.anchor:GetParent() then
				icon:SetFrameLevel(icon.anchor:GetParent():GetFrameLevel()+((frame.anchor ~= "None" and frame.anchor ~= "Blizzard") and 3 or 0))
			end
			if icon.MasqueGroup then
				icon.MasqueGroup:ReSkin()
			end
		end
	end

	local AnchorDropDown2
	if v == "player" then
		AnchorDropDown2	= CreateFrame("Frame", O..v.."AnchorDropDown2", OptionsPanelFrame, "UIDropDownMenuTemplate")
		function AnchorDropDown2:OnClick()
			UIDropDownMenu_SetSelectedValue(AnchorDropDown2, self.value)
			local frame = LoseControlDB.frames.player2
			local icon = LCframeplayer2
			frame.anchor = self.value
			frame.point = nil
			frame.relativePoint = nil
			frame.x = nil
			frame.y = nil
			if self.value == "Blizzard" then
				local portrSizeValue = 56
				frame.size = portrSizeValue
				icon:SetWidth(portrSizeValue)
				icon:SetHeight(portrSizeValue)
				icon:GetParent():SetWidth(portrSizeValue)
				icon:GetParent():SetHeight(portrSizeValue)
			end
			icon.anchor = _G[anchors[frame.anchor][LCframes.player.unitId]] or (type(anchors[frame.anchor][LCframes.player.unitId])=="table" and anchors[frame.anchor][LCframes.player.unitId] or UIParent)
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
			if icon.anchor:GetParent() then
				icon:SetFrameLevel(icon.anchor:GetParent():GetFrameLevel()+((frame.anchor ~= "None" and frame.anchor ~= "Blizzard") and 3 or 0))
			end
		end
	end
	
	local AnchorPositionPartyDropDown
	if v == "party" then
		AnchorPositionPartyDropDown	= CreateFrame("Frame", O..v.."AnchorPositionPartyDropDown", OptionsPanelFrame, "UIDropDownMenuTemplate")
		function AnchorPositionPartyDropDown:OnClick()
			UIDropDownMenu_SetSelectedValue(AnchorPositionPartyDropDown, self.value)
			local unitId = self.value
			local frame = LoseControlDB.frames[unitId]
			local PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
			local PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
			if (PositionXEditBox and PositionYEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
				end
				PositionXEditBox:SetCursorPosition(0)
				PositionYEditBox:SetCursorPosition(0)
				PositionXEditBox:ClearFocus()
				PositionYEditBox:ClearFocus()
			end
		end
	end
	
	local AnchorPositionArenaDropDown
	if v == "arena" then
		AnchorPositionArenaDropDown	= CreateFrame("Frame", O..v.."AnchorPositionArenaDropDown", OptionsPanelFrame, "UIDropDownMenuTemplate")
		function AnchorPositionArenaDropDown:OnClick()
			UIDropDownMenu_SetSelectedValue(AnchorPositionArenaDropDown, self.value)
			local unitId = self.value
			local frame = LoseControlDB.frames[unitId]
			local PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
			local PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
			if (PositionXEditBox and PositionYEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
				end
				PositionXEditBox:SetCursorPosition(0)
				PositionYEditBox:SetCursorPosition(0)
				PositionXEditBox:ClearFocus()
				PositionYEditBox:ClearFocus()
			end
		end
	end
	
	local AnchorPositionRaidDropDown
	if v == "raid" then
		AnchorPositionRaidDropDown	= CreateFrame("Frame", O..v.."AnchorPositionRaidDropDown", OptionsPanelFrame, "UIDropDownMenuTemplate")
		function AnchorPositionRaidDropDown:OnClick()
			UIDropDownMenu_SetSelectedValue(AnchorPositionRaidDropDown, self.value)
			local unitId = self.value
			local frame = LoseControlDB.frames[unitId]
			local PositionXEditBox = _G['LoseControlOptionsPanel'..v..'PositionXEditBox']
			local PositionYEditBox = _G['LoseControlOptionsPanel'..v..'PositionYEditBox']
			if (PositionXEditBox and PositionYEditBox) then
				PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
				PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
				end
				PositionXEditBox:SetCursorPosition(0)
				PositionYEditBox:SetCursorPosition(0)
				PositionXEditBox:ClearFocus()
				PositionYEditBox:ClearFocus()
			end
		end
	end

	local PositionXEditBox = CreateEditBox(L["Position"], OptionsPanelFrame, 55, 20, OptionsPanelFrame:GetName() .. "PositionXEditBox")
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
	end)
	PositionXEditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
	end)
	
	local PositionYEditBox = CreateEditBox(L["Position"], OptionsPanelFrame, 55, 20, OptionsPanelFrame:GetName() .. "PositionYEditBox")
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
	end)
	PositionYEditBox:SetScript("OnEnable", function(self)
		self:SetTextColor(1, 1, 1)
	end)

	local SizeSlider = CreateSlider(L["Icon Size"], OptionsPanelFrame, 4, 256, 1, true, OptionsPanelFrame:GetName() .. "IconSizeSlider")
	SizeSlider:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["Icon Size"] .. " (" .. value .. "px)")
		self.editbox:SetText(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
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

	local AlphaSlider = CreateSlider(L["Opacity"], OptionsPanelFrame, 0, 100, 1, true, OptionsPanelFrame:GetName() .. "OpacitySlider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
	AlphaSlider:SetScript("OnValueChanged", function(self, value)
		value = mathfloor(value+0.5)
		_G[self:GetName() .. "Text"]:SetText(L["Opacity"] .. " (" .. value .. "%)")
		self.editbox:SetText(value)
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
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
		AlphaSlider2 = CreateSlider(L["Opacity"], OptionsPanelFrame, 0, 100, 1, true, OptionsPanelFrame:GetName() .. "Opacity2Slider") -- I was going to use a range of 0 to 1 but Blizzard's slider chokes on decimal values
		AlphaSlider2:SetScript("OnValueChanged", function(self, value)
			value = mathfloor(value+0.5)
			_G[self:GetName() .. "Text"]:SetText(L["Opacity"] .. " (" .. value .. "%)")
			self.editbox:SetText(value)
			local frames = { v }
			if v == "player" then
				LoseControlDB.frames.player2.alpha = value / 100 -- the real alpha value
				LCframeplayer2:GetParent():SetAlpha(value / 100)
			end
		end)
	end

	local DisableInBG
	if v == "party" then
		DisableInBG = CreateFrame("CheckButton", O..v.."DisableInBG", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInBGText"]:SetText(L["DisableInBG"])
		DisableInBG:SetScript("OnClick", function(self)
			LoseControlDB.disablePartyInBG = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				for i = 1, 4 do
					LCframes[v .. i].maxExpirationTime = 0
					LCframes[v .. i]:PLAYER_ENTERING_WORLD()
				end
			end
		end)
	elseif v == "raid" then
		DisableInBG = CreateFrame("CheckButton", O..v.."DisableInBG", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInBGText"]:SetText(L["DisableInBG"])
		DisableInBG:SetScript("OnClick", function(self)
			LoseControlDB.disableRaidInBG = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				for i = 1, 40 do
					LCframes[v .. i].maxExpirationTime = 0
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
					LCframes[v .. i].maxExpirationTime = 0
					LCframes[v .. i]:PLAYER_ENTERING_WORLD()
				end
			end
		end)
	end
	
	local DisableInArena
	if v == "party" then
		DisableInArena = CreateFrame("CheckButton", O..v.."DisableInArena", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInArenaText"]:SetText(L["DisableInArena"])
		DisableInArena:SetScript("OnClick", function(self)
			LoseControlDB.disablePartyInArena = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				for i = 1, 4 do
					LCframes[v .. i].maxExpirationTime = 0
					LCframes[v .. i]:PLAYER_ENTERING_WORLD()
				end
			end
		end)
	elseif v == "raid" then
		DisableInArena = CreateFrame("CheckButton", O..v.."DisableInArena", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableInArenaText"]:SetText(L["DisableInArena"])
		DisableInArena:SetScript("OnClick", function(self)
			LoseControlDB.disableRaidInArena = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				for i = 1, 40 do
					LCframes[v .. i].maxExpirationTime = 0
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
					LCframes[v .. i].maxExpirationTime = 0
					LCframes[v .. i]:PLAYER_ENTERING_WORLD()
				end
			end
		end)
	end

	local ShowNPCInterrupts
	if v == "target" or v == "focus" or v == "targettarget" or v == "focustarget"  then
		ShowNPCInterrupts = CreateFrame("CheckButton", O..v.."ShowNPCInterrupts", OptionsPanelFrame, "OptionsCheckButtonTemplate")
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
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local DisablePlayerTargetTarget
	if v == "targettarget" or v == "focustarget" then
		DisablePlayerTargetTarget = CreateFrame("CheckButton", O..v.."DisablePlayerTargetTarget", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisablePlayerTargetTargetText"]:SetText(L["DisablePlayerTargetTarget"])
		DisablePlayerTargetTarget:SetScript("OnClick", function(self)
			if v == "targettarget" then
				LoseControlDB.disablePlayerTargetTarget = self:GetChecked()
			elseif v == "focustarget" then
				LoseControlDB.disablePlayerFocusTarget = self:GetChecked()
			end
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local DisableTargetTargetTarget
	if v == "targettarget" then
		DisableTargetTargetTarget = CreateFrame("CheckButton", O..v.."DisableTargetTargetTarget", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableTargetTargetTargetText"]:SetText(L["DisableTargetTargetTarget"])
		DisableTargetTargetTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableTargetTargetTarget = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local DisablePlayerTargetPlayerTargetTarget
	if v == "targettarget" then
		DisablePlayerTargetPlayerTargetTarget = CreateFrame("CheckButton", O..v.."DisablePlayerTargetPlayerTargetTarget", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisablePlayerTargetPlayerTargetTargetText"]:SetText(L["DisablePlayerTargetPlayerTargetTarget"])
		DisablePlayerTargetPlayerTargetTarget:SetScript("OnClick", function(self)
			LoseControlDB.disablePlayerTargetPlayerTargetTarget = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local DisableTargetDeadTargetTarget
	if v == "targettarget" then
		DisableTargetDeadTargetTarget = CreateFrame("CheckButton", O..v.."DisableTargetDeadTargetTarget", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableTargetDeadTargetTargetText"]:SetText(L["DisableTargetDeadTargetTarget"])
		DisableTargetDeadTargetTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableTargetDeadTargetTarget = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end
	
	local DisableFocusFocusTarget
	if v == "focustarget" then
		DisableFocusFocusTarget = CreateFrame("CheckButton", O..v.."DisableFocusFocusTarget", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableFocusFocusTargetText"]:SetText(L["DisableFocusFocusTarget"])
		DisableFocusFocusTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableFocusFocusTarget = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local DisablePlayerFocusPlayerFocusTarget
	if v == "focustarget" then
		DisablePlayerFocusPlayerFocusTarget = CreateFrame("CheckButton", O..v.."DisablePlayerFocusPlayerFocusTarget", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisablePlayerFocusPlayerFocusTargetText"]:SetText(L["DisablePlayerFocusPlayerFocusTarget"])
		DisablePlayerFocusPlayerFocusTarget:SetScript("OnClick", function(self)
			LoseControlDB.disablePlayerFocusPlayerFocusTarget = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local DisableFocusDeadFocusTarget
	if v == "focustarget" then
		DisableFocusDeadFocusTarget = CreateFrame("CheckButton", O..v.."DisableFocusDeadFocusTarget", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		_G[O..v.."DisableFocusDeadFocusTargetText"]:SetText(L["DisableFocusDeadFocusTarget"])
		DisableFocusDeadFocusTarget:SetScript("OnClick", function(self)
			LoseControlDB.disableFocusDeadFocusTarget = self:GetChecked()
			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				LCframes[v].maxExpirationTime = 0
				LCframes[v]:PLAYER_ENTERING_WORLD()
			end
		end)
	end

	local catListEnChecksButtons = { "PvE", "Immune", "ImmuneSpell", "ImmunePhysical", "CC", "Silence", "Disarm", "Root", "Snare", "Other" }
	local CategoriesCheckButtons = { }
	if not(strfind(v, "arena")) then
		local FriendlyInterrupt = CreateFrame("CheckButton", O..v.."FriendlyInterrupt", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		FriendlyInterrupt:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."FriendlyInterruptText"]:SetText(L["CatFriendly"])
		FriendlyInterrupt:SetScript("OnClick", function(self)
			local frames = { v }
			if v == "party" then
				frames = { "party1", "party2", "party3", "party4" }
			elseif v == "raid" then
				frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
			end
			for _, frame in ipairs(frames) do
				LoseControlDB.frames[frame].categoriesEnabled.interrupt.friendly = self:GetChecked()
				LCframes[frame].maxExpirationTime = 0
				if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
					LCframes[frame]:UNIT_AURA(frame, 0)
				end
			end
		end)
		tblinsert(CategoriesCheckButtons, { frame = FriendlyInterrupt, auraType = "interrupt", reaction = "friendly", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = 140, yPos = 5 })
	end
	if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or strfind(v, "arena") then
		local EnemyInterrupt = CreateFrame("CheckButton", O..v.."EnemyInterrupt", OptionsPanelFrame, "OptionsCheckButtonTemplate")
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
					LCframes[frame]:UNIT_AURA(frame, 0)
				end
			end
		end)
		tblinsert(CategoriesCheckButtons, { frame = EnemyInterrupt, auraType = "interrupt", reaction = "enemy", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = (not(strfind(v, "arena")) and 270 or 140), yPos = 5 })
	end
	for _, cat in pairs(catListEnChecksButtons) do
		if not(strfind(v, "arena")) then
			local FriendlyBuff = CreateFrame("CheckButton", O..v.."Friendly"..cat.."Buff", OptionsPanelFrame, "OptionsCheckButtonTemplate")
			FriendlyBuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."BuffText"]:SetText(L["CatFriendlyBuff"])
			FriendlyBuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "party" then
					frames = { "party1", "party2", "party3", "party4" }
				elseif v == "raid" then
					frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.buff.friendly[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(frame, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = FriendlyBuff, auraType = "buff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 140, yPos = 5 })
		end
		if not(strfind(v, "arena")) then
			local FriendlyDebuff = CreateFrame("CheckButton", O..v.."Friendly"..cat.."Debuff", OptionsPanelFrame, "OptionsCheckButtonTemplate")
			FriendlyDebuff:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."DebuffText"]:SetText(L["CatFriendlyDebuff"])
			FriendlyDebuff:SetScript("OnClick", function(self)
				local frames = { v }
				if v == "party" then
					frames = { "party1", "party2", "party3", "party4" }
				elseif v == "raid" then
					frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
				end
				for _, frame in ipairs(frames) do
					LoseControlDB.frames[frame].categoriesEnabled.debuff.friendly[cat] = self:GetChecked()
					LCframes[frame].maxExpirationTime = 0
					if LoseControlDB.frames[frame].enabled and not LCframes[frame].unlockMode then
						LCframes[frame]:UNIT_AURA(frame, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = FriendlyDebuff, auraType = "debuff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 205, yPos = 5 })
		end
		if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or strfind(v, "arena") then
			local EnemyBuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Buff", OptionsPanelFrame, "OptionsCheckButtonTemplate")
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
						LCframes[frame]:UNIT_AURA(frame, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = EnemyBuff, auraType = "buff", reaction = "enemy", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = (not(strfind(v, "arena")) and 270 or 140), yPos = 5 })
		end
		if v == "target" or v == "targettarget" or v == "focus" or v == "focustarget" or strfind(v, "arena") then
			local EnemyDebuff = CreateFrame("CheckButton", O..v.."Enemy"..cat.."Debuff", OptionsPanelFrame, "OptionsCheckButtonTemplate")
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
						LCframes[frame]:UNIT_AURA(frame, 0)
					end
				end
			end)
			tblinsert(CategoriesCheckButtons, { frame = EnemyDebuff, auraType = "debuff", reaction = "enemy", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = (not(strfind(v, "arena")) and 335 or 205), yPos = 5 })
		end
	end

	local CategoriesCheckButtonsPlayer2
	if (v == "player") then
		CategoriesCheckButtonsPlayer2 = { }
		local FriendlyInterruptPlayer2 = CreateFrame("CheckButton", O..v.."FriendlyInterruptPlayer2", OptionsPanelFrame, "OptionsCheckButtonTemplate")
		FriendlyInterruptPlayer2:SetHitRectInsets(0, -36, 0, 0)
		_G[O..v.."FriendlyInterruptPlayer2Text"]:SetText(L["CatFriendly"].."|cfff28614(Icon2)|r")
		FriendlyInterruptPlayer2:SetScript("OnClick", function(self)
			LoseControlDB.frames.player2.categoriesEnabled.interrupt.friendly = self:GetChecked()
			LCframeplayer2.maxExpirationTime = 0
			if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
				LCframeplayer2:UNIT_AURA(v, 0)
			end
		end)
		tblinsert(CategoriesCheckButtonsPlayer2, { frame = FriendlyInterruptPlayer2, auraType = "interrupt", reaction = "friendly", categoryType = "Interrupt", anchorPos = CategoryEnabledInterruptLabel, xPos = 310, yPos = 5 })
		for _, cat in pairs(catListEnChecksButtons) do
			local FriendlyBuffPlayer2 = CreateFrame("CheckButton", O..v.."Friendly"..cat.."BuffPlayer2", OptionsPanelFrame, "OptionsCheckButtonTemplate")
			FriendlyBuffPlayer2:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."BuffPlayer2Text"]:SetText(L["CatFriendlyBuff"].."|cfff28614(Icon2)|r")
			FriendlyBuffPlayer2:SetScript("OnClick", function(self)
				LoseControlDB.frames.player2.categoriesEnabled.buff.friendly[cat] = self:GetChecked()
				LCframeplayer2.maxExpirationTime = 0
				if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(v, 0)
				end
			end)
			tblinsert(CategoriesCheckButtonsPlayer2, { frame = FriendlyBuffPlayer2, auraType = "buff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 310, yPos = 5 })
			local FriendlyDebuffPlayer2 = CreateFrame("CheckButton", O..v.."Friendly"..cat.."DebuffPlayer2", OptionsPanelFrame, "OptionsCheckButtonTemplate")
			FriendlyDebuffPlayer2:SetHitRectInsets(0, -36, 0, 0)
			_G[O..v.."Friendly"..cat.."DebuffPlayer2Text"]:SetText(L["CatFriendlyDebuff"].."|cfff28614(Icon2)|r")
			FriendlyDebuffPlayer2:SetScript("OnClick", function(self)
				LoseControlDB.frames.player2.categoriesEnabled.debuff.friendly[cat] = self:GetChecked()
				LCframeplayer2.maxExpirationTime = 0
				if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(v, 0)
				end
			end)
			tblinsert(CategoriesCheckButtonsPlayer2, { frame = FriendlyDebuffPlayer2, auraType = "debuff", reaction = "friendly", categoryType = cat, anchorPos = CategoriesLabels[cat], xPos = 419, yPos = 5 })
		end
	end

	local DuplicatePlayerPortrait
	if v == "player" then
		DuplicatePlayerPortrait = CreateFrame("CheckButton", O..v.."DuplicatePlayerPortrait", OptionsPanelFrame, "OptionsCheckButtonTemplate")
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
					UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
				end
				if LCframes.player.MasqueGroup then
					LCframes.player.MasqueGroup:RemoveButton(LCframes.player:GetParent())
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
				LCframes.player.anchor = _G[anchors[frame.anchor][LCframes.player.unitId]] or (type(anchors[frame.anchor][LCframes.player.unitId])=="table" and anchors[frame.anchor][LCframes.player.unitId] or UIParent)
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
				if (PositionXEditBox and PositionYEditBox) then
					PositionXEditBox:SetText(0)
					PositionYEditBox:SetText(0)
					if (frame.anchor ~= "Blizzard") then
						PositionXEditBox:Enable()
						PositionYEditBox:Enable()
					else
						PositionXEditBox:Disable()
						PositionYEditBox:Disable()
					end
					PositionXEditBox:SetCursorPosition(0)
					PositionYEditBox:SetCursorPosition(0)
				end
				if LCframes.player.anchor:GetParent() then
					LCframes.player:SetFrameLevel(LCframes.player.anchor:GetParent():GetFrameLevel()+((frame.anchor ~= "None" and frame.anchor ~= "Blizzard") and 3 or 0))
				end
				if LCframes.player.MasqueGroup then
					LCframes.player.MasqueGroup:ReSkin()
				end
			end
			if enable and not LCframeplayer2.unlockMode then
				LCframeplayer2:UNIT_AURA(v, 0)
			end
		end
		DuplicatePlayerPortrait:SetScript("OnClick", function(self)
			DuplicatePlayerPortrait:Check(self:GetChecked())
		end)
	end

	local Enabled = CreateFrame("CheckButton", O..v.."Enabled", OptionsPanelFrame, "OptionsCheckButtonTemplate")
	_G[O..v.."EnabledText"]:SetText(L["Enabled"])
	Enabled:SetScript("OnClick", function(self)
		local enabled = self:GetChecked()
		if enabled then
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
			PositionXEditBoxLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
			PositionYEditBoxLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
			SizeSlider.editbox:Enable()
			AlphaSlider.editbox:Enable()
			UIDropDownMenu_EnableDropDown(AnchorDropDown)
			if LoseControlDB.duplicatePlayerPortrait then
				if AlphaSlider2 then
					BlizzardOptionsPanel_Slider_Enable(AlphaSlider2)
					if AlphaSlider2.editbox then AlphaSlider2.editbox:Enable() end
				end
				if AnchorDropDown2 then UIDropDownMenu_EnableDropDown(AnchorDropDown2) end
			else
				if AlphaSlider2 then
					BlizzardOptionsPanel_Slider_Disable(AlphaSlider2)
					if AlphaSlider2.editbox then AlphaSlider2.editbox:Disable() end
				end
				if AnchorDropDown2 then UIDropDownMenu_DisableDropDown(AnchorDropDown2) end
			end
			if AnchorPositionPartyDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionPartyDropDown) end
			if AnchorPositionArenaDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionArenaDropDown) end
			if AnchorPositionRaidDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionRaidDropDown) end
			if (PositionXEditBox and PositionYEditBox) then
				local unitIdSel = v
				if (v == "party") then
					unitIdSel = (AnchorPositionPartyDropDown ~= nil) and UIDropDownMenu_GetSelectedValue(AnchorPositionPartyDropDown) or "party1"
				elseif (v == "arena") then
					unitIdSel = (AnchorPositionArenaDropDown ~= nil) and UIDropDownMenu_GetSelectedValue(AnchorPositionArenaDropDown) or "arena1"
				elseif (v == "raid") then
					unitIdSel = (AnchorPositionRaidDropDown ~= nil) and UIDropDownMenu_GetSelectedValue(AnchorPositionRaidDropDown) or "raid1"
				end
				if (LoseControlDB.frames[unitIdSel].anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
				end
			end
		else
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
			PositionXEditBoxLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
			PositionYEditBoxLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
			BlizzardOptionsPanel_Slider_Disable(SizeSlider)
			BlizzardOptionsPanel_Slider_Disable(AlphaSlider)
			SizeSlider.editbox:Disable()
			AlphaSlider.editbox:Disable()
			UIDropDownMenu_DisableDropDown(AnchorDropDown)
			if AlphaSlider2 then
				BlizzardOptionsPanel_Slider_Disable(AlphaSlider2)
				if AlphaSlider2.editbox then AlphaSlider2.editbox:Disable() end
			end
			if AnchorDropDown2 then UIDropDownMenu_DisableDropDown(AnchorDropDown2) end
			if AnchorPositionPartyDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionPartyDropDown) end
			if AnchorPositionArenaDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionArenaDropDown) end
			if AnchorPositionRaidDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionRaidDropDown) end
			if PositionXEditBox then PositionXEditBox:Disable() end
			if PositionYEditBox then PositionYEditBox:Disable() end
		end
		local frames = { v }
		if v == "party" then
			frames = { "party1", "party2", "party3", "party4" }
		elseif v == "arena" then
			frames = { "arena1", "arena2", "arena3", "arena4", "arena5" }
		elseif v == "raid" then
			frames = { "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10", "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20", "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30", "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40" }
		end
		for _, frame in ipairs(frames) do
			LoseControlDB.frames[frame].enabled = enabled
			local enable = enabled and LCframes[frame]:GetEnabled()
			LCframes[frame].maxExpirationTime = 0
			LCframes[frame]:RegisterUnitEvents(enable)
			if enable and not LCframes[frame].unlockMode then
				LCframes[frame]:UNIT_AURA(frame, 0)
			end
			if (frame == "player") then
				LoseControlDB.frames.player2.enabled = enabled and LoseControlDB.duplicatePlayerPortrait
				LCframeplayer2.maxExpirationTime = 0
				LCframeplayer2:RegisterUnitEvents(enabled and LoseControlDB.duplicatePlayerPortrait)
				if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
					LCframeplayer2:UNIT_AURA(frame, 0)
				end
			end
		end
	end)

	Enabled:SetPoint("TOPLEFT", 16, -32)
	if DisableInBG then DisableInBG:SetPoint("TOPLEFT", Enabled, 225, 0) end
	if DisableInArena then DisableInArena:SetPoint("TOPLEFT", Enabled, 225, -25) end
	if DisableInRaid then DisableInRaid:SetPoint("TOPLEFT", Enabled, 225, -50) end
	if ShowNPCInterrupts then ShowNPCInterrupts:SetPoint("TOPLEFT", Enabled, 225, 0) end
	if DisablePlayerTargetTarget then DisablePlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -25) end
	if DisableTargetTargetTarget then DisableTargetTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -50) end
	if DisablePlayerTargetPlayerTargetTarget then DisablePlayerTargetPlayerTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -75) end
	if DisableTargetDeadTargetTarget then DisableTargetDeadTargetTarget:SetPoint("TOPLEFT", Enabled, 225, -100) end
	if DisableFocusFocusTarget then DisableFocusFocusTarget:SetPoint("TOPLEFT", Enabled, 225, -50) end
	if DisablePlayerFocusPlayerFocusTarget then DisablePlayerFocusPlayerFocusTarget:SetPoint("TOPLEFT", Enabled, 225, -75) end
	if DisableFocusDeadFocusTarget then DisableFocusDeadFocusTarget:SetPoint("TOPLEFT", Enabled, 225, -100) end
	if DuplicatePlayerPortrait then DuplicatePlayerPortrait:SetPoint("TOPLEFT", Enabled, 305, 0) end
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
	CategoriesEnabledLabel:SetPoint("TOPLEFT", PositionEditBoxLabel, "BOTTOMLEFT", 0, -38)
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
	if AlphaSlider2 then AlphaSlider2:SetPoint("TOPLEFT", Enabled, "BOTTOMLEFT", 305, -81) end
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
			unitId = "party1"
		elseif unitId == "arena" then
			DisableInBG:SetChecked(LoseControlDB.disableArenaInBG)
			unitId = "arena1"
		elseif unitId == "player" then
			DuplicatePlayerPortrait:SetChecked(LoseControlDB.duplicatePlayerPortrait)
			AlphaSlider2:SetValue(LoseControlDB.frames.player2.alpha * 100)
			AlphaSlider2.editbox:SetText(LoseControlDB.frames.player2.alpha * 100)
			AlphaSlider2.editbox:SetCursorPosition(0)
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
		LCframes[unitId]:CheckSUFUnitsAnchors(true)
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
			PositionXEditBoxLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
			PositionYEditBoxLabel:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
			SizeSlider.editbox:Enable()
			AlphaSlider.editbox:Enable()
			UIDropDownMenu_EnableDropDown(AnchorDropDown)
			if LoseControlDB.duplicatePlayerPortrait then
				if AlphaSlider2 then
					BlizzardOptionsPanel_Slider_Enable(AlphaSlider2)
					if AlphaSlider2.editbox then AlphaSlider2.editbox:Enable() end
				end
				if AnchorDropDown2 then UIDropDownMenu_EnableDropDown(AnchorDropDown2) end
			else
				if AlphaSlider2 then
					BlizzardOptionsPanel_Slider_Disable(AlphaSlider2)
					if AlphaSlider2.editbox then AlphaSlider2.editbox:Disable() end
				end
				if AnchorDropDown2 then UIDropDownMenu_DisableDropDown(AnchorDropDown2) end
			end
			if AnchorPositionPartyDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionPartyDropDown) end
			if AnchorPositionArenaDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionArenaDropDown) end
			if AnchorPositionRaidDropDown then UIDropDownMenu_EnableDropDown(AnchorPositionRaidDropDown) end
			if (PositionXEditBox and PositionYEditBox) then
				if (frame.anchor ~= "Blizzard") then
					PositionXEditBox:Enable()
					PositionYEditBox:Enable()
				else
					PositionXEditBox:Disable()
					PositionYEditBox:Disable()
				end
			end
		else
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
			PositionXEditBoxLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
			PositionYEditBoxLabel:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
			BlizzardOptionsPanel_Slider_Disable(SizeSlider)
			BlizzardOptionsPanel_Slider_Disable(AlphaSlider)
			SizeSlider.editbox:Disable()
			AlphaSlider.editbox:Disable()
			UIDropDownMenu_DisableDropDown(AnchorDropDown)
			if AlphaSlider2 then
				BlizzardOptionsPanel_Slider_Disable(AlphaSlider2)
				if AlphaSlider2.editbox then AlphaSlider2.editbox:Disable() end
			end
			if AnchorDropDown2 then UIDropDownMenu_DisableDropDown(AnchorDropDown2) end
			if AnchorPositionPartyDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionPartyDropDown) end
			if AnchorPositionArenaDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionArenaDropDown) end
			if AnchorPositionRaidDropDown then UIDropDownMenu_DisableDropDown(AnchorPositionRaidDropDown) end
			if PositionXEditBox then PositionXEditBox:Disable() end
			if PositionYEditBox then PositionYEditBox:Disable() end
		end
		SizeSlider:SetValue(frame.size)
		SizeSlider.editbox:SetText(frame.size)
		SizeSlider.editbox:SetCursorPosition(0)
		AlphaSlider:SetValue(frame.alpha * 100)
		AlphaSlider.editbox:SetText(frame.alpha * 100)
		AlphaSlider.editbox:SetCursorPosition(0)
		if (PositionXEditBox and PositionYEditBox) then
			PositionXEditBox:SetText(mathfloor((frame.x or 0)+0.5))
			PositionYEditBox:SetText(mathfloor((frame.y or 0)+0.5))
			PositionXEditBox:SetCursorPosition(0)
			PositionYEditBox:SetCursorPosition(0)
			PositionXEditBox:ClearFocus()
			PositionYEditBox:ClearFocus()
		end
		UIDropDownMenu_Initialize(AnchorDropDown, function() -- called on refresh and also every time the drop down menu is opened
			AddItem(AnchorDropDown, L["None"], "None")
			if not(strfind(unitId, "raid")) then
				AddItem(AnchorDropDown, "Blizzard", "Blizzard")
			else
				AddItem(AnchorDropDown, "Blizzard", "BlizzardRaidFrames")
			end
			if _G[anchors["Perl"][unitId]] or (type(anchors["Perl"][unitId])=="table" and anchors["Perl"][unitId]) then AddItem(AnchorDropDown, "Perl", "Perl") end
			if _G[anchors["XPerl"][unitId]] or (type(anchors["XPerl"][unitId])=="table" and anchors["XPerl"][unitId]) then AddItem(AnchorDropDown, "XPerl", "XPerl") end
			if _G[anchors["LUI"][unitId]] or (type(anchors["LUI"][unitId])=="table" and anchors["LUI"][unitId]) then AddItem(AnchorDropDown, "LUI", "LUI") end
			if _G[anchors["SUF"][unitId]] or (type(anchors["SUF"][unitId])=="table" and anchors["SUF"][unitId]) then AddItem(AnchorDropDown, "SUF", "SUF") end
			if _G[anchors["SyncFrames"][unitId]] or (type(anchors["SyncFrames"][unitId])=="table" and anchors["SyncFrames"][unitId]) then AddItem(AnchorDropDown, "SyncFrames", "SyncFrames") end
		end)
		UIDropDownMenu_SetSelectedValue(AnchorDropDown, frame.anchor)
		if AnchorDropDown2 then
			UIDropDownMenu_Initialize(AnchorDropDown2, function() -- called on refresh and also every time the drop down menu is opened
				AddItem(AnchorDropDown2, "Blizzard", "Blizzard")
				if _G[anchors["Perl"][unitId]] or (type(anchors["Perl"][unitId])=="table" and anchors["Perl"][unitId]) then AddItem(AnchorDropDown2, "Perl", "Perl") end
				if _G[anchors["XPerl"][unitId]] or (type(anchors["XPerl"][unitId])=="table" and anchors["XPerl"][unitId]) then AddItem(AnchorDropDown2, "XPerl", "XPerl") end
				if _G[anchors["LUI"][unitId]] or (type(anchors["LUI"][unitId])=="table" and anchors["LUI"][unitId]) then AddItem(AnchorDropDown2, "LUI", "LUI") end
				if _G[anchors["SUF"][unitId]] or (type(anchors["SUF"][unitId])=="table" and anchors["SUF"][unitId]) then AddItem(AnchorDropDown2, "SUF", "SUF") end
			end)
			UIDropDownMenu_SetSelectedValue(AnchorDropDown2, LoseControlDB.frames.player2.anchor)
		end
		if AnchorPositionPartyDropDown then
			UIDropDownMenu_Initialize(AnchorPositionPartyDropDown, function() -- called on refresh and also every time the drop down menu is opened
				AddItem(AnchorPositionPartyDropDown, "party1", "party1")
				AddItem(AnchorPositionPartyDropDown, "party2", "party2")
				AddItem(AnchorPositionPartyDropDown, "party3", "party3")
				AddItem(AnchorPositionPartyDropDown, "party4", "party4")
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
		for _, v in ipairs({"party1", "party2", "party3", "party4"}) do
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
		if enabled and not LCframes[unitId].unlockMode then
			LCframes[unitId]:UNIT_AURA(unitId, 0)
		end
		if (unitId == "player") then
			LoseControlDB.frames.player2.enabled = LoseControlDB.duplicatePlayerPortrait
			LCframeplayer2:RegisterUnitEvents(LoseControlDB.duplicatePlayerPortrait)
			if LCframeplayer2.frame.enabled and not LCframeplayer2.unlockMode then
				LCframeplayer2:UNIT_AURA(unitId, 0)
			end
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
			for cSpellId, cPriority  in pairs(LoseControlDB.customSpellIds) do
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
