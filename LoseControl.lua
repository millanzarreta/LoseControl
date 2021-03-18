--[[
-------------------------------------------
-- Addon: LoseControl
-- Version: 6.04
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
local pairs = pairs
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
	[19647]  = 6,		-- Spell Lock (felhunter) (Warlock)
	[47528]  = 3,		-- Mind Freeze (Death Knight)
	[57994]  = 3,		-- Wind Shear (Shaman)
	[91802]  = 2,		-- Shambling Rush (Death Knight)
	[96231]  = 4,		-- Rebuke (Paladin)
	[106839] = 4,		-- Skull Bash (Feral)
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
	[48792]  = "Other",				-- Icebound Fortitude
	[49039]  = "Other",				-- Lichborne
	[51271]  = "Other",				-- Pillar of Frost
	[207167] = "CC",				-- Blinding Sleet
	[207165] = "CC",				-- Abomination's Might
	[207171] = "Root",				-- Winter is Coming
	[210141] = "CC",				-- Zombie Explosion (Reanimation PvP Talent)
	[206961] = "CC",				-- Tremble Before Me
	[248406] = "CC",				-- Cold Heart (legendary)
	[233395] = "Root",				-- Frozen Center (pvp talent)
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
	[50259]  = "Snare",				-- Wild Charge (Dazed)
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
		[54216]  = "Other",				-- Master's Call (root and snare immune only)
		[53148]  = "Root",				-- Charge (tenacity ability)
		[137798] = "ImmuneSpell",		-- Reflective Armor Plating (Direhorn)

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
	[198909] = "CC",				-- Song of Chi-Ji
	[233759] = "Disarm",			-- Grapple Weapon
	[202274] = "CC",				-- Incendiary Brew (honor talent)
	[202346] = "CC",				-- Double Barrel (honor talent)
	[123407] = "Root",				-- Spinning Fire Blossom (honor talent)
	[214326] = "Other",				-- Exploding Keg (artifact trait - blind)
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
	[1022]   = "ImmunePhysical",	-- Hand of Protection
	[204018] = "ImmuneSpell",		-- Blessing of Spellwarding
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
	[8178]   = "ImmuneSpell",		-- Grounding Totem Effect (Grounding Totem)
	[204399] = "CC",				-- Earthfury (PvP Talent)
	[192058] = "CC",				-- Lightning Surge totem (capacitor totem)
	[210918] = "ImmunePhysical",	-- Ethereal Form
	[204437] = "CC",				-- Lightning Lasso
	[197214] = "CC",				-- Sundering
	[224126] = "Snare",				-- Frozen Bite (Doom Wolves, artifact trait)
	[207654] = "Immune",			-- Servant of the Queen (not immune, 80% damage reduction - artifact trait)
	
		----------------
		-- Shaman Pets
		----------------
		[118345] = "CC",				-- Pulverize (Shaman Primal Earth Elemental)
		[157375] = "CC",				-- Gale Force (Primal Storm Elemental)

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
	[31117]  = "Silence",			-- Unstable Affliction
	[196364] = "Silence",			-- Unstable Affliction
	[110913] = "Other",				-- Dark Bargain
	[104773] = "Other",				-- Unending Resolve
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
	[118038] = "Other",				-- Die by the Sword
	[198819] = "Other",				-- Sharpen Blade (70% heal reduction)
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
	[30217]  = "CC",				-- Adamantite Grenade
	[67769]  = "CC",				-- Cobalt Frag Bomb
	[67890]  = "CC",				-- Cobalt Frag Bomb (belt)
	[30216]  = "CC",				-- Fel Iron Bomb
	[224074] = "CC",				-- Devilsaur's Bite (trinket)
	[127723] = "Root",				-- Covered In Watermelon (trinket)
	[195342] = "Snare",				-- Shrink Ray (trinket)
	[13327]  = "CC",				-- Reckless Charge
	[107079] = "CC",				-- Quaking Palm (pandaren racial)
	[20549]  = "CC",				-- War Stomp (tauren racial)
	[255723] = "CC",				-- Bull Rush (highmountain tauren racial)
	[214459] = "Silence",			-- Choking Flames (trinket)
	[19821]  = "Silence",			-- Arcane Bomb
	[131510] = "Immune",			-- Uncontrolled Banish
	[8346]   = "Root",				-- Mobility Malfunction (trinket)
	[39965]  = "Root",				-- Frost Grenade
	[55536]  = "Root",				-- Frostweave Net
	[13099]  = "Root",				-- Net-o-Matic (trinket)
	[16566]  = "Root",				-- Net-o-Matic (trinket)
	[15752]  = "Disarm",			-- Linken's Boomerang (trinket)
	[15753]  = "CC",				-- Linken's Boomerang (trinket)
	[1604]   = "Snare",				-- Dazed
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
	[245855] = "CC",				-- Belly Smash
	[262177] = "CC",				-- Into the Storm
	[255978] = "CC",				-- Pallid Glare
	[256050] = "CC",				-- Disoriented (Electroshock Mount Motivator)
	[258258] = "CC",				-- Quillbomb
	[260149] = "CC",				-- Quillbomb
	[258236] = "CC",				-- Sleeping Quill Dart
	[269186] = "CC",				-- Holographic Horror Projector
	[255228] = "CC",				-- Polymorphed (Organic Discombobulation Grenade)
	[272188] = "CC",				-- Hammer Smash (quest)
	[264860] = "CC",				-- Binding Talisman
	[268966] = "Root",				-- Hooked Deep Sea Net
	[268965] = "Snare",				-- Tidespray Linen Net
	-- PvE
	--[123456] = "PvE",				-- This is just an example, not a real spell
	------------------------
	---- PVE BFA
	------------------------
	-- Uldir Raid
	-- -- Trash
	[277498] = "CC",				-- Mind Slave
	[277358] = "CC",				-- Mind Flay
	[278890] = "CC",				-- Violent Hemorrhage
	[278967] = "CC",				-- Winged Charge
	[260275] = "CC",				-- Rumbling Stomp
	[262375] = "CC",				-- Bellowing Roar
	[263321] = "Snare",				-- Undulating Mass
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
	[276031] = "CC",				-- Pit of Despair
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
	------------------------
	-- Battle for Stromgarde
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
	[262610] = "Root",				-- Weighted Net
	[273665] = "Snare",				-- Seismic Disturbance
	[262538] = "Snare",				-- Thunder Clap
	[259850] = "Snare",				-- Reverberating Clap
	[20822]  = "Snare",				-- Frostbolt
	------------------------
	-- BfA Island Expeditions
	[8377] = "Root",				-- Earthgrab
	[280061] = "CC",				-- Brainsmasher Brew
	[280062] = "CC",				-- Unluckydo
	[270399] = "Root",				-- Unleashed Roots
	[270196] = "Root",				-- Chains of Light
	[267024] = "Root",				-- Stranglevines
	[236467] = "Root",				-- Pearlescent Clam
	[267025] = "Root",				-- Animal Trap
	[276807] = "Root",				-- Crude Net
	[276806] = "Root",				-- Stoutthistle
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
	[274794] = "CC",				-- Hex
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
	--[262197] = "Immune",			-- Tenacity of the Pack (unkillable but not immune to damage)
	[264115] = "Immune",			-- Divine Shield
	[267487] = "ImmunePhysical",	-- Icy Reflection
	[275154] = "Silence",			-- Silencing Calm
	[265723] = "Root",				-- Web
	[274801] = "Root",				-- Net
	[265584] = "Root",				-- Frost Nova
	[265583] = "Root",				-- Grasping Claw
	[278176] = "Root",				-- Entangling Roots
	[275821] = "Root",				-- Earthen Hold
	[277109] = "Snare",				-- Sticky Stomp
	[266974] = "Snare",				-- Frostbolt
	[261962] = "Snare",				-- Brutal Whirlwind
	[258748] = "Snare",				-- Arctic Torrent
	[266286] = "Snare",				-- Tendon Rip
	[270606] = "Snare",				-- Frostbolt
	[266288] = "Snare",				-- Gnash
	[262465] = "Snare",				-- Bug Zapper
	[267195] = "Snare",				-- Slow
	[275038] = "Snare",				-- Icy Claw
	[274968] = "Snare",				-- Howl
	[256661] = "Snare",				-- Staggering Roar
	------------------------
	-- BfA Mythics
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
	version = 6.0, -- This is the settings version, not necessarily the same as the LoseControl version
	noCooldownCount = false,
	noBlizzardCooldownCount = true,
	noLossOfControlCooldown = false,
	disablePartyInBG = false,
	disableArenaInBG = true,
	disablePartyInRaid = true,
	disablePlayerInterrupts = true,
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
		if (LoseControlDB.priority.Interrupt > 0) then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
		if unitId == "target" then
			self:RegisterEvent("PLAYER_TARGET_CHANGED")
		elseif unitId == "focus" then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		elseif unitId == "pet" then
			self:RegisterUnitEvent("UNIT_PET", "player")
		end
	else
		self:UnregisterEvent("UNIT_AURA")
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		if unitId == "target" then
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		elseif unitId == "focus" then
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		elseif unitId == "pet" then
			self:UnregisterEvent("UNIT_PET")
		end
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
		if _G.LoseControlDB and _G.LoseControlDB.version then
			if _G.LoseControlDB.version < DBdefaults.version then
				if _G.LoseControlDB.version == 5.1 then -- upgrade gracefully
					_G.LoseControlDB.disableArenaInBG = DBdefaults.disableArenaInBG
					_G.LoseControlDB.noBlizzardCooldownCount = DBdefaults.noBlizzardCooldownCount
					_G.LoseControlDB.noLossOfControlCooldown = DBdefaults.noLossOfControlCooldown
					_G.LoseControlDB.disablePartyInRaid = DBdefaults.disablePartyInRaid
					_G.LoseControlDB.disablePlayerInterrupts = DBdefaults.disablePlayerInterrupts
					_G.LoseControlDB.priority.Interrupt = DBdefaults.priority.Interrupt
					_G.LoseControlDB.priority.ImmunePhysical = DBdefaults.priority.ImmunePhysical
					_G.LoseControlDB.version = DBdefaults.version
				elseif _G.LoseControlDB.version == 5.2 then -- upgrade gracefully
					_G.LoseControlDB.disablePlayerInterrupts = DBdefaults.disablePlayerInterrupts
					_G.LoseControlDB.priority.Interrupt = DBdefaults.priority.Interrupt
					_G.LoseControlDB.priority.ImmunePhysical = DBdefaults.priority.ImmunePhysical
					_G.LoseControlDB.version = DBdefaults.version
				else
					_G.LoseControlDB = CopyTable(DBdefaults)
					print(L["LoseControl reset."])
				end
			end
		else -- never installed before
			_G.LoseControlDB = CopyTable(DBdefaults)
			print(L["LoseControl reset."])
		end
		LoseControlDB = _G.LoseControlDB
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
	self:RegisterUnitEvents(
		frame.enabled and not (
			inInstance and instanceType == "pvp" and (
				( LoseControlDB.disablePartyInBG and string.find(unitId, "party") ) or
				( LoseControlDB.disableArenaInBG and string.find(unitId, "arena") )
			)
		) and not (
			IsInRaid() and instanceType~="arena" and LoseControlDB.disablePartyInRaid and string.find(unitId, "party")
		)
	)
	self.anchor = _G[anchors[frame.anchor][unitId]] or UIParent
	self.unitGUID = UnitGUID(self.unitId)
	self.parent:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
	--self:SetFrameStrata(frame.strata or "LOW")
	self:ClearAllPoints() -- if we don't do this then the frame won't always move
	self:SetWidth(frame.size)
	self:SetHeight(frame.size)
	self:SetPoint(
		frame.point or "CENTER",
		self.anchor,
		frame.relativePoint or "CENTER",
		frame.x or 0,
		frame.y or 0
	)
	--self:SetAlpha(frame.alpha) -- doesn't seem to work; must manually set alpha after the cooldown is displayed, otherwise it doesn't apply.
	self:Hide()
end

function LoseControl:GROUP_ROSTER_UPDATE()
	local unitId = self.unitId
	local frame = self.frame
	if (frame == nil) or (unitId == nil) or not(string.find(unitId, "party")) then
		return
	end
	local inInstance, instanceType = IsInInstance()
	self:RegisterUnitEvents(
		frame.enabled and not (
			inInstance and instanceType == "pvp" and (
				( LoseControlDB.disablePartyInBG and string.find(unitId, "party") ) or
				( LoseControlDB.disableArenaInBG and string.find(unitId, "arena") )
			)
		) and not (
			IsInRaid() and instanceType~="arena" and LoseControlDB.disablePartyInRaid and string.find(unitId, "party")
		)
	)
	self.unitGUID = UnitGUID(self.unitId)
end

function LoseControl:GROUP_JOINED()
	self:GROUP_ROSTER_UPDATE()
end

function LoseControl:GROUP_LEFT()
	self:GROUP_ROSTER_UPDATE()
end

-- This event check pvp interrupts
function LoseControl:COMBAT_LOG_EVENT_UNFILTERED()
	if (UnitIsPlayer(self.unitId)) then
		local _, event, _, _, _, _, _, destGUID, _, _, _, spellId, _, _, _, _, spellSchool = CombatLogGetCurrentEventInfo()
		if (destGUID == self.unitGUID) then
			if (event == "SPELL_INTERRUPT") then
				local duration = interruptsIds[spellId]
				if (duration ~= nil) then
					local _, class = UnitClass(self.unitId)
					if ((class == "PRIEST") or (class == "SHAMAN")) then
						for i = 1, 40 do
							local _, _, _, _, _, _, _, _, _, auxSpellId = UnitBuff(self.unitId, i)
							if not auxSpellId then break end
							if auxSpellId == 221660 then		-- Holy Concentration (Priest)
								duration = duration * 0.3
								break
							elseif auxSpellId == 221677 then	-- Calming Waters (Shaman)
								duration = duration * 0.5
								break
							end
						end	
					end
					local expirationTime = GetTime() + duration
					local priority = LoseControlDB.priority.Interrupt
					local _, _, icon = GetSpellInfo(spellId)
					if (InterruptAuras[self.unitGUID] == nil) then
						InterruptAuras[self.unitGUID] = {}
					end
					table.insert(InterruptAuras[self.unitGUID], { ["spellId"] = spellId, ["duration"] = duration, ["expirationTime"] = expirationTime, ["priority"] = priority, ["icon"] = icon, ["spellSchool"] = spellSchool })
					self:UNIT_AURA(self.unitId)
				end
			end
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

	-- Check buffs
	if unitId ~= "player" and (priority.Immune > 0 or priority.ImmuneSpell > 0 or priority.ImmunePhysical > 0 or priority.Other > 0) then
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
	if ((self.unitGUID ~= nil) and (priority.Interrupt > 0) and ((unitId ~= "player") or (not LoseControlDB.disablePlayerInterrupts))) then
		if (InterruptAuras[self.unitGUID] ~= nil) then
			for k, v in ipairs(InterruptAuras[self.unitGUID]) do
				local spellId = v.spellId
				local Priority = v.priority
				local expirationTime = v.expirationTime
				local duration = v.duration
				local icon = v.icon
				local spellSchool = v.spellSchool
				if (expirationTime < GetTime()) then
					InterruptAuras[self.unitGUID][k] = nil
				else
					if Priority then
						if Priority == maxPriority and expirationTime > maxExpirationTime then
							maxExpirationTime = expirationTime
							Duration = duration
							Icon = icon
							C_Timer.After(expirationTime - GetTime() + 0.05, function()
								self:UNIT_AURA(unitId)
								for e, f in pairs(InterruptAuras) do
									for g, h in ipairs(f) do
										if (h.expirationTime < GetTime()) then
											InterruptAuras[e][g] = nil
										end
									end
								end
							end)
						elseif Priority > maxPriority then
							maxPriority = Priority
							maxExpirationTime = expirationTime
							Duration = duration
							Icon = icon
							C_Timer.After(expirationTime - GetTime() + 0.05, function()
								self:UNIT_AURA(unitId)
								for e, f in pairs(InterruptAuras) do
									for g, h in ipairs(f) do
										if (h.expirationTime < GetTime()) then
											InterruptAuras[e][g] = nil
										end
									end
								end
							end)
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
		if self.frame.anchor == "Blizzard" then
			SetPortraitToTexture(self.texture, Icon) -- Sets the texture to be displayed from a file applying a circular opacity mask making it look round like portraits. TO DO: mask the cooldown frame somehow so the corners don't stick out of the portrait frame. Maybe apply a circular alpha mask in the OVERLAY draw layer.
		else
			self.texture:SetTexture(Icon)
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
	self:UNIT_AURA("focus")
end

function LoseControl:PLAYER_TARGET_CHANGED()
	--if (debug) then print("PLAYER_TARGET_CHANGED") end
	if (self.unitId == "target") then
		self.unitGUID = UnitGUID("target")
	end
	self:UNIT_AURA("target")
end

function LoseControl:UNIT_PET(unitId)
	--if (debug) then print("UNIT_PET", unitId) end
	if (self.unitId == "pet") then
		self.unitGUID = UnitGUID("pet")
	end
	self:UNIT_AURA("pet")
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
				v:SetCooldown( GetTime(), 30 )
				v:SetAlpha(frame.alpha) -- hack to apply the alpha to the cooldown timer
				v:SetMovable(true)
				v:RegisterForDrag("LeftButton")
				v:EnableMouse(true)
			end
		end
	else
		_G[O.."UnlockText"]:SetText(L["Unlock"])
		for _, v in pairs(LCframes) do
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
local function CreateSlider(text, parent, low, high, step)
	local name = parent:GetName() .. text
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
			if AnchorDropDown.value ~= "None" then -- reset the frame position so it centers on the anchor frame
				frame.point = nil
				frame.relativePoint = nil
				frame.x = nil
				frame.y = nil
			end

			icon.anchor = _G[anchors[frame.anchor][unitId]] or UIParent

			if not Unlock:GetChecked() then -- prevents the icon from disappearing if the frame is currently hidden
				icon.parent:SetParent(icon.anchor:GetParent())
			end

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

	local SizeSlider = CreateSlider(L["Icon Size"], OptionsPanelFrame, 16, 512, 4)
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

	local Enabled = CreateFrame("CheckButton", O..v.."Enabled", OptionsPanelFrame, "OptionsCheckButtonTemplate")
	_G[O..v.."EnabledText"]:SetText(L["Enabled"])
	Enabled:SetScript("OnClick", function(self)
		local enabled = self:GetChecked()
		if enabled then
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Enable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Enable(DisableInterrupts) end
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		else
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Disable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Disable(DisableInterrupts) end
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
			LCframes[frame]:RegisterUnitEvents(enabled)
		end
	end)

	Enabled:SetPoint("TOPLEFT", 16, -32)
	if DisableInBG then DisableInBG:SetPoint("TOPLEFT", Enabled, 200, 0) end
	if DisableInRaid then DisableInRaid:SetPoint("TOPLEFT", Enabled, 200, -25) end
	if DisableInterrupts then DisableInterrupts:SetPoint("TOPLEFT", Enabled, 200, 0) end
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
		end
		local frame = LoseControlDB.frames[unitId]
		Enabled:SetChecked(frame.enabled)
		if frame.enabled then
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Enable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Enable(DisableInterrupts) end
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		else
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
			if DisableInRaid then BlizzardOptionsPanel_CheckButton_Disable(DisableInRaid) end
			if DisableInterrupts then BlizzardOptionsPanel_CheckButton_Disable(DisableInterrupts) end
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
		LCframes[unitId]:RegisterUnitEvents(true)
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
