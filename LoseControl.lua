--[[
Updated for 7.1.0 by millanzarreta
- Added most spells to spell ID list and corrected others (a lot of work, really...)
- Fixed the problem with spells that were not showing correctly (spells without duration, such as Solar Beam, Grounding Totem, Smoke Bomb, ...)
- Added new option to allows manage the blizzard cooldown countdown
- Added new option to allows remove the cooldown on bars for CC effects (tested for default Bars and Bartender4 Bars)
- Fixed a bug: now type /lc opens directly the LoseControl panel instead of Interface panel

Updated for 7.0.3 (Legion) by Hid@Emeriss
- Added a large amount of spells, hopefully I didn't miss anything (important)

Updated by Wardz
Changes:
- Removed spell IDs that no longer exists.
- Added Ice Nova (mage) and Rake (druid) to spell ID list
- Fixed cooldown spiral
]]

--[[ Code Credits - to the people whose code I borrowed and learned from:
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
local disableLossOfControlUIHooked = false
local LCframes = {}

-------------------------------------------------------------------------------
-- Thanks to all the people on the Curse.com and WoWInterface forums who help keep this list up to date :)
local spellIds = {
	----------------
	-- Demonhunter
	----------------
	[179057] = "CC",					-- Chaos Nova
	[205630] = "CC",					-- Illidan's Grasp
	[208618] = "CC",					-- Illidan's Grasp (throw stun)
	[217832] = "CC",					-- Imprison
	[221527] = "CC",					-- Imprison (pvp talent)
	[204843] = "Snare",				-- Sigil of Chains
	[207685] = "CC",					-- Sigil of Misery
	[204490] = "Silence",			-- Sigil of Silence
	[211881] = "CC",					-- Fel Eruption
	[200166] = "CC",					-- Metamorfosis stun
	[196555] = "Immune",			-- Netherwalk
	[213491] = "CC",					-- Demonic Trample Stun
	[206649] = "Silence",			-- Eye of Leotheras (no silence, 4% dmg and duration reset for spell casted)
	[232538] = "Snare",				-- Rain of Chaos
	[213405] = "Snare",				-- Master of the Glaive
	[210003] = "Snare",				-- Razor Spikes
	[198813] = "Snare",				-- Vengeful Retreat
	

	----------------
	-- Death Knight
	----------------
	[108194] = "CC",					-- Asphyxiate
	[221562] = "CC",					-- Asphyxiate
	[47476]  = "Silence",			-- Strangulate
	[96294]  = "Root",				-- Chains of Ice (Chilblains)
	[45524]  = "Snare",				-- Chains of Ice
	[115018] = "Other",				-- Desecrated Ground (Immune to CC)
	[207319] = "Immune",			-- Corpse Shield (not immune, 90% damage redirected to pet)
	[48707]  = "ImmuneSpell",	-- Anti-Magic Shell
	[48792]  = "Other",				-- Icebound Fortitude
	[49039]  = "Other",				-- Lichborne
	[51271]  = "Other",				-- Pillar of Frost
	[207167] = "CC",					-- Blinding Sleet
	[207165] = "CC",					-- Abomination's Might
	[207171] = "CC",					-- Winter is Coming
	[210141] = "CC",					-- Zombie Explosion (Reanimation PvP Talent)
	[206961] = "CC",					-- Tremble Before Me
	[233395] = "Root",				-- Frozen Center (pvp talent)
	[204085] = "Root",				-- Deathchill (pvp talent)
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
		[212332] = "CC",			-- Smash
		[212336] = "CC",			-- Smash
		[212337] = "CC",			-- Powerful Smash
		[47481]  = "CC",			-- Gnaw
		[91800]  = "CC",			-- Gnaw
		[91797]  = "CC",			-- Monstrous Blow (Dark Transformation)
		[91807]  = "Root",		-- Shambling Rush (Dark Transformation)
		[212540] = "Root",		-- Flesh Hook (Abomination)
	
	----------------
	-- Druid
	----------------
	[33786]  = "CC",				-- Cyclone
	[209753] = "CC",				-- Cyclone
	[99]     = "CC",				-- Incapacitating Roar
	[163505] = "CC",				-- Rake
	[22570]  = "CC",				-- Maim
	[203123] = "CC",				-- Maim
	[203126] = "CC",				-- Maim (pvp honor talent)
	[236025] = "CC",				-- Enraged Maim (pvp honor talent)
	[5211]   = "CC",				-- Mighty Bash
	[81261]  = "Silence",		-- Solar Beam
	[339]    = "Root",			-- Entangling Roots
	[113770] = "Root",			-- Entangling Roots (Force of Nature - Balance Treants)
	[45334]  = "Root",			-- Immobilized (Wild Charge - Bear)
	[102359] = "Root",			-- Mass Entanglement
	[50259]  = "Snare",			-- Dazed (Wild Charge - Cat)
	[58180]  = "Snare",			-- Infected Wounds
	[61391]  = "Snare",			-- Typhoon
	[127797] = "Snare",			-- Ursol's Vortex
	[50259]  = "Snare",			-- Wild Charge (Dazed)
	[102543] = "Other",			-- Incarnation: King of the Jungle
	[106951] = "Other",			-- Berserk
	[102558] = "Other",			-- Incarnation: Guardian of Ursoc
	[102560] = "Other",			-- Incarnation: Chosen of Elune
	[202244] = "CC",				-- Overrun (pvp honor talent)
	[209749] = "Disarm",		-- Faerie Swarm (pvp honor talent)
	
	----------------
	-- Hunter
	----------------
	[117526] = "CC",					-- Binding Shot
	[3355]   = "CC",					-- Freezing Trap
	[13809]  = "CC",					-- Ice Trap 1
	[195645] = "Snare",				-- Wing Clip
	[19386]  = "CC",					-- Wyvern Sting
	[128405] = "Root",				-- Narrow Escape
	[201158] = "Root",				-- Super Sticky Tar
	[111735] = "Snare",				-- Tar
	[135299] = "Snare",				-- Tar Trap
	[5116]   = "Snare",				-- Concussive Shot
	[194279] = "Snare",				-- Caltrops
	[206755] = "Snare",				-- Ranger's Net (snare)
	[213691] = "CC",					-- Scatter Shot (pvp honor talent)
	[186265] = "Immune",			-- Deterrence (aspect of the turtle)
	[19574]  = "ImmuneSpell",	-- Bestial Wrath (only if The Beast Within (212704) it's active) (immune to some CC's)
	[190927] = "Root",				-- Harpoon
	[212331] = "Root",				-- Harpoon
	[212353] = "Root",				-- Harpoon
	[162480] = "Root",				-- Steel Trap
	[200108] = "Root",				-- Ranger's Net
	[212638] = "Root",				-- Tracker's Net (pvp honor talent) -- Also -80% hit chance
	[224729] = "CC",					-- Bursting Shot
	[203337] = "CC",					-- Freezing Trap (Diamond Ice - pvp honor talent)
	[209790] = "CC",					-- Freezing Arrow (pvp honor talent)
	[202748] = "Immune",			-- Survival Tactics (pvp honor talent) (not immune, 99% damage reduction)
	--[202914] = "Silence",			-- Spider Sting (pvp honor talent) --no silence, this its the previous effect
	[202933] = "Silence",			-- Spider Sting	(pvp honor talent) --this its the silence effect
	[5384]   = "Other",				-- Feign Death
  
		----------------
		-- Hunter Pets
		----------------
		[24394]  = "CC",					-- Intimidation
		[50433]  = "Snare",				-- Ankle Crack (Crocolisk)
		[54644]  = "Snare",				-- Frost Breath (Chimaera)
		[35346]  = "Snare",				-- Warp Time (Warp Stalker)
		[160067] = "Snare",				-- Web Spray (Spider)
		[160065] = "Snare",				-- Tendon Rip (Silithid)
		[54216]  = "Other",				-- Master's Call (root and snare immune only)
		[53148]  = "Root",				-- Charge (tenacity ability)
		[137798] = "ImmuneSpell",	-- Reflective Armor Plating (Direhorn)

	----------------
	-- Mage
	----------------
	[44572]  = "CC",					-- Deep Freeze
	[31661]  = "CC",					-- Dragon's Breath
	[118]    = "CC",					-- Polymorph
	[61305]  = "CC",					-- Polymorph: Black Cat
	[28272]  = "CC",					-- Polymorph: Pig
	[61721]  = "CC",					-- Polymorph: Rabbit
	[61780]  = "CC",					-- Polymorph: Turkey
	[28271]  = "CC",					-- Polymorph: Turtle
	[161353] = "CC",					-- Polymorph: Polar bear cub
	[126819] = "CC",					-- Polymorph: Porcupine
	[161354] = "CC",					-- Polymorph: Monkey
	[61025]  = "CC",					-- Polymorph: Serpent
	[161355] = "CC",					-- Polymorph: Penguin
	[82691]  = "CC",					-- Ring of Frost
	[140376] = "CC",					-- Ring of Frost
	[122]    = "Root",				-- Frost Nova
	[111340] = "Root",				-- Ice Ward
	[120]    = "Snare",				-- Cone of Cold
	[116]    = "Snare",				-- Frostbolt
	[44614]  = "Snare",				-- Frostfire Bolt
	[31589]  = "Snare",				-- Slow
	[10]	   = "Snare",				-- Blizzard
	[205708] = "Snare",				-- Chilled
	[212792] = "Snare",				-- Cone of Cold
	[205021] = "Snare",				-- Ray of Frost
	[135029] = "Snare",				-- Water Jet
	[59638]  = "Snare",				-- Frostbolt (Mirror Images)
	[228354] = "Snare",				-- Flurry
	[157981] = "Snare",				-- Blast Wave
	[2120]   = "Snare",				-- Flamestrike
	[45438]  = "Immune",			-- Ice Block
	[198065] = "ImmuneSpell",	-- Prismatic Cloak (pvp talent)
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
		[33395]  = "Root",			-- Freeze

	----------------
	-- Monk
	----------------
	[123393] = "CC",				-- Breath of Fire (Glyph of Breath of Fire)
	[119392] = "CC",				-- Charging Ox Wave
	[119381] = "CC",				-- Leg Sweep
	[115078] = "CC",				-- Paralysis
	[232055] = "CC",				-- Fist of Fury (honor talent stun)
	[120086] = "CC",				-- Fist of Fury (unknow)
	[116706] = "Root",			-- Disable
	[116095] = "Snare",			-- Disable
	[118585] = "Snare",			-- Leer of the Ox
	[123586] = "Snare",			-- Flying Serpent Kick
	[121253] = "Snare",			-- Keg Smash
	[196733] = "Snare",			-- Special Delivery
	[196723] = "Snare",			-- Dizzying Kicks
	[205320] = "Snare",			-- Strike of the Windlord (artifact trait)
	[125174] = "Immune",		-- Touch of Karma
	[198909] = "CC",				-- Song of Chi-Ji
	[233759] = "Disarm",		-- Grapple Weapon
	[202274] = "CC",				-- Incendiary Brew (honor talent)
	[202346] = "CC",				-- Double Barrel (honor talent)
	[123407] = "Root",			-- Spinning Fire Blossom (honor talent)
	[214326] = "Other",			-- Exploding Keg (artifact trait - blind)
	[199387] = "Snare",			-- Spirit Tether (artifact trait)

	----------------
	-- Paladin
	----------------
	[105421] = "CC",					-- Blinding Light
	[105593] = "CC",					-- Fist of Justice
	[853]    = "CC",					-- Hammer of Justice
	[20066]  = "CC",					-- Repentance
	[31935]  = "Silence",			-- Avenger's Shield
	[187219] = "Silence",			-- Avenger's Shield (pvp talent)
	[199512] = "Silence",			-- Avenger's Shield (unknow use)
	[217824] = "Silence",			-- Shield of Virtue (pvp honor talent)
	[204242] = "Snare",				-- Consecration (talent Consecrated Ground)
	[183218] = "Snare",				-- Hand of Hindrance
	[642]    = "Immune",			-- Divine Shield
	[184662] = "Other",				-- Shield of Vengeance
	[31821]  = "Other",				-- Aura Mastery
	[1022]   = "Other",				-- Hand of Protection (only immune to physical damage)
	[204018] = "ImmuneSpell",	-- Blessing of Spellwarding
	[228050] = "Immune",			-- Divine Shield (Guardian of the Forgotten Queen)
	[205273] = "Snare",				-- Wake of Ashes (artifact trait) (snare)
	[205290] = "CC",					-- Wake of Ashes (artifact trait) (stun)

	----------------
	-- Priest
	----------------
	[605]    = "CC",				-- Dominate Mind
	[64044]  = "CC",				-- Psychic Horror
	[8122]   = "CC",				-- Psychic Scream
	[9484]   = "CC",				-- Shackle Undead
	[87204]  = "CC",				-- Sin and Punishment
	[15487]  = "Silence",		-- Silence
	[64058]  = "Disarm",		-- Psychic Horror
	[87194]  = "Root",			-- Glyph of Mind Blast
	[114404] = "Root",			-- Void Tendril's Grasp
	[15407]  = "Snare",			-- Mind Flay
	[47585]  = "Immune",		-- Dispersion
	[47788]  = "Other",			-- Guardian Spirit (prevent the target from dying)
	[213602] = "Other",			-- Greater Fade (pvp honor talent - protects 3 melee attacks + 50% speed)
	[213610] = "Other",			-- Holy Ward (pvp honor talent - wards against the next loss of control effect)
	[196762] = "Other",			-- Inner Focus (pvp honor talent - immunity to silence and interrupt effects)
	[226943] = "CC",				-- Mind Bomb
	[200196] = "CC",				-- Holy Word: Chastise
	[200200] = "CC",				-- Holy Word: Chastise (talent)
	[204263] = "Snare",			-- Shining Force
	[199845] = "Snare",			-- Psyflay (pvp honor talent - Psyfiend)
	[199683] = "Silence",		-- Last Word (pvp honor talent)
	[210979] = "Snare",			-- Focus in the Light (artifact trait)

	----------------
	-- Rogue
	----------------
	[2094]   = "CC",						-- Blind
	[1833]   = "CC",						-- Cheap Shot
	[1776]   = "CC",						-- Gouge
	[408]    = "CC",						-- Kidney Shot
	[6770]   = "CC",						-- Sap
	[196958] = "CC",						-- Strike from the Shadows (stun effect)
	[1330]   = "Silence",				-- Garrote - Silence
	[3409]   = "Snare",					-- Crippling Poison
	[26679]  = "Snare",					-- Deadly Throw
	[185763] = "Snare",					-- Pistol Shot
	[185778] = "Snare",					-- Shellshocked
	[206760] = "Snare",					-- Night Terrors
	[222775] = "Snare",					-- Strike from the Shadows (daze effect)
	[152150] = "Immune",				-- Death from Above (in the air you are immune to CC)
	[31224]  = "ImmuneSpell",		-- Cloak of Shadows
	[51690]  = "Other",					-- Killing Spree
	[13750]  = "Other",					-- Adrenaline Rush
	[199754] = "Other",					-- Riposte
	[1966]   = "Other",					-- Feint
	[45182]  = "Other",					-- Cheating Death
	[5277]   = "Other",					-- Evasion
	[76577]  = "Other",					-- Smoke Bomb
	[88611]  = "Other",					-- Smoke Bomb
	[212182] = "Other",					-- Smoke Bomb
	[212183] = "Other",					-- Smoke Bomb --I think this is the real debuff for legion
	[199804] = "CC",						-- Between the eyes
	[199740] = "CC",						-- Bribe
	[207777] = "Disarm",				-- Dismantle
	[185767] = "Snare",					-- Cannonball Barrage
	[207736] = "Other",					-- Shadowy Duel
	[212150] = "Other",					-- Cheap Tricks (pvp honor talent) (-75% hit chance)
	[199743] = "CC",						-- Parley
	[198653] = "CC",						-- Filthy Tricks (pvp honor talent)
	[198222] = "Snare",					-- System Shock (pvp honor talent)
	[226364] = "Other",					-- Evasion (Shadow Swiftness, artifact trait)
	[209786] = "Snare",					-- Goremaw's Bite (artifact trait)
	

	----------------
	-- Shaman
	----------------
	[77505]  = "CC",						-- Earthquake
	[51514]  = "CC",						-- Hex
	[210873] = "CC",						-- Hex (compy)
	[211010] = "CC",						-- Hex (snake)
	[211015] = "CC",						-- Hex (cockroach)
	[211004] = "CC",						-- Hex (spider)
	[196942] = "CC",						-- Hex (Voodoo Totem)
	[118905] = "CC",						-- Static Charge (Capacitor Totem)
	[64695]  = "Root",					-- Earthgrab (Earthgrab Totem)
	[3600]   = "Snare",					-- Earthbind (Earthbind Totem)
	[116947] = "Snare",					-- Earthbind (Earthgrab Totem)
	[77478]  = "Snare",					-- Earthquake (Glyph of Unstable Earth)
	[8056]   = "Snare",					-- Frost Shock
	[196840] = "Snare",					-- Frost Shock
	[51490]  = "Snare",					-- Thunderstorm
	[147732] = "Snare",					-- Frostbrand Attack
	[197385] = "Snare",					-- Fury of Air
	[207498] = "Other",					-- Ancestral Protection (prevent the target from dying)
	[8178]   = "ImmuneSpell",		-- Grounding Totem Effect (Grounding Totem)
	[204399] = "CC",						-- Earthfury (PvP Talent)
	[192058] = "CC",						-- Lightning Surge totem (capacitor totem)
	[210918] = "Other",					-- Ethereal Form (only immune to physical damage)
	[204437] = "CC",						-- Lightning Lasso
	[197214] = "Root",					-- Sundering
	[224126] = "Snare",					-- Frozen Bite (Doom Wolves, artifact trait)
	[207654] = "Immune",				-- Servant of the Queen (not immune, 80% damage reduction - artifact trait)
	
		----------------
		-- Shaman Pets
		----------------
		[118345] = "CC",			-- Pulverize (Shaman Primal Earth Elemental)
		[157375] = "CC",			-- Gale Force (Primal Storm Elemental)

	----------------
	-- Warlock
	----------------
	[710]    = "CC",						-- Banish
	[5782]   = "CC",						-- Fear
	[118699] = "CC",						-- Fear
	[130616] = "CC",						-- Fear (Glyph of Fear)
	[5484]   = "CC",						-- Howl of Terror
	[22703]  = "CC",						-- Infernal Awakening
	[6789]   = "CC",						-- Mortal Coil
	[30283]  = "CC",						-- Shadowfury
	[31117]  = "Silence",				-- Unstable Affliction
	[196364] = "Silence",				-- Unstable Affliction
	[110913] = "Other",					-- Dark Bargain
	[104773] = "Other",					-- Unending Resolve
	[212295] = "ImmuneSpell",		-- Netherward (reflects spells)
	[233582] = "Root",					-- Entrenched in Flame (pvp honor talent)

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
		[170996] = "Snare",		-- Debilitate (Terrorguard)
		[170995] = "Snare",		-- Cripple (Doomguard)

	----------------
	-- Warrior
	----------------
	[118895] = "CC",						-- Dragon Roar
	[5246]   = "CC",						-- Intimidating Shout (aoe)
	[132168] = "CC",						-- Shockwave
	[107570] = "CC",						-- Storm Bolt
	[132169] = "CC",						-- Storm Bolt
	[46968]  = "CC",						-- Shockwave
	[213427] = "CC",						-- Charge Stun Talent (Warbringer)
	[7922]   = "CC",						-- Charge Stun Talent (Warbringer)
	[107566] = "Root",					-- Staggering Shout
	[105771] = "Root",					-- Charge
	[147531] = "Snare",					-- Bloodbath
	[1715]   = "Snare",					-- Hamstring
	[12323]  = "Snare",					-- Piercing Howl
	[6343]   = "Snare",					-- Thunder Clap
	[46924]  = "Immune",				-- Bladestorm (not immune to dmg, only to LoC)
	[227847] = "Immune",				-- Bladestorm (not immune to dmg, only to LoC)
	[199038] = "Immune",				-- Leave No Man Behind (not immune, 90% damage reduction)
	[23920]  = "ImmuneSpell",		-- Spell Reflection
	[216890] = "ImmuneSpell",		-- Spell Reflection
	[213915] = "ImmuneSpell",		-- Mass Spell Reflection
	[114028] = "ImmuneSpell",		-- Mass Spell Reflection
	[18499]  = "Other",					-- Berserker Rage
	[118038] = "Other",					-- Die by the Sword
	[198819] = "Other",					-- Sharpen Blade (70% heal reduction)
	[198760] = "Other",					-- Intercept (pvp honor talent) (intercept the next ranged or melee hit)
	[198760] = "Other",					-- Intercept (pvp honor talent) (intercept the next ranged or melee hit)
	[176289] = "CC",						-- Siegebreaker
	[199085] = "CC",						-- Warpath
	[199042] = "Root",					-- Thunderstruck
	[236236] = "Disarm",				-- Disarm (pvp honor talent - protection)
	[236077] = "Disarm",				-- Disarm (pvp honor talent)
	
	----------------
	-- Other
	----------------
	[30217]  = "CC",					-- Adamantite Grenade
	[67769]  = "CC",					-- Cobalt Frag Bomb
	[67890]  = "CC",					-- Cobalt Frag Bomb (belt)
	[30216]  = "CC",					-- Fel Iron Bomb
	[107079] = "CC",					-- Quaking Palm
	[13327]  = "CC",					-- Reckless Charge
	[20549]  = "CC",					-- War Stomp
	[25046]  = "Silence",			-- Arcane Torrent (Energy)
	[28730]  = "Silence",			-- Arcane Torrent (Mana)
	[50613]  = "Silence",			-- Arcane Torrent (Runic Power)
	[69179]  = "Silence",			-- Arcane Torrent (Rage)
	[80483]  = "Silence",			-- Arcane Torrent (Focus)
	[129597] = "Silence",			-- Arcane Torrent (Chi)
	[202719] = "Silence",			-- Arcane Torrent (fury)
	[232633] = "Silence",			-- Arcane Torrent (mana/insanity priest)
	[155145] = "Silence",			-- Arcane Torrent (mana/holypower paladin)
	[214459] = "Silence",			-- Choking Flames (trinket)
	[39965]  = "Root",				-- Frost Grenade
	[55536]  = "Root",				-- Frostweave Net
	[13099]  = "Root",				-- Net-o-Matic
	[1604]   = "Snare",				-- Dazed
	[221792] = "CC",					-- Kidney Shot (Vanessa VanCleef (Rogue Bodyguard))
	-- PvE
	--[123456] = "PvE",				-- This is just an example, not a real spell
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
	version = 5.2, -- This is the settings version, not necessarily the same as the LoseControl version
	noCooldownCount = false,
	noBlizzardCooldownCount = true,
	noLossOfControlCooldown = false,
	disablePartyInBG = false,
	disableArenaInBG = true,
	priority = {		-- higher numbers have more priority; 0 = disabled
		PvE		= 90,
		Immune		= 80,
		ImmuneSpell	= 70,
		CC		= 60,
		Silence		= 50,
		Disarm		= 40,
		Other		= 0,
		Root		= 0,
		Snare		= 0,
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
	end
end

-- Function to disable Cooldown on player bars for CC effects
function LoseControl:DisableLossOfControlUI()
	if not disableLossOfControlUIHooked then
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
		disableLossOfControlUIHooked = true
	end
end

-- Handle default settings
function LoseControl:ADDON_LOADED(arg1)
	if arg1 == addonName then
		if _G.LoseControlDB and _G.LoseControlDB.version then
			if _G.LoseControlDB.version < DBdefaults.version then
				if _G.LoseControlDB.version == 5.1 then -- upgrade gracefully
					_G.LoseControlDB.disableArenaInBG = DBdefaults.disableArenaInBG
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
		)
	)
	self.anchor = _G[anchors[frame.anchor][unitId]] or UIParent
	self:SetParent(self.anchor:GetParent()) -- or LoseControl) -- If Hide() is called on the parent frame, its children are hidden too. This also sets the frame strata to be the same as the parent's.
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

-- This is the main event. Check for (de)buffs and update the frame icon and cooldown.
function LoseControl:UNIT_AURA(unitId) -- fired when a (de)buff is gained/lost
	if not self.anchor:IsVisible() then return end
	local priority = LoseControlDB.priority
	local maxPriority = 1
	local maxExpirationTime = 0
	local Icon, Duration

	-- Check debuffs
	for i = 1, 80 do
		local name, _, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i, "HARMFUL")
		if not spellId then break end -- no more debuffs, terminate the loop
		if debug then print(unitId, "debuff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end
		-- exceptions
		if spellId == 212183 and unitId ~= "player" then -- Smoke Bomb
			expirationTime = GetTime() + 1 -- normal expirationTime = 0
		elseif spellId == 81261  -- Solar Beam
				or spellId == 127797 -- Ursol's Vortex
				or spellId == 115018 -- Desecrated Ground
				or spellId == 143375 -- Tightening Grasp
				or spellId == 135299 -- Tar Trap
		then
			expirationTime = GetTime() + 1 -- normal expirationTime = 0
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
	if unitId ~= "player" and (priority.Immune > 0 or priority.ImmuneSpell > 0 or priority.Other > 0) then
		for i = 1, 80 do
			local name, _, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unitId, i) -- defaults to "HELPFUL" filter
			if not spellId then break end
			if debug then print(unitId, "buff", i, ")", name, "|", duration, "|", expirationTime, "|", spellId) end

			-- exceptions
			if spellId == 8178 then -- Grounding Totem Effect
				expirationTime = GetTime() + 1 -- hack, normal expirationTime = 0
			elseif spellId == 19574 and (not UnitBuff(unitId,GetSpellInfo(212704))) then --exception for The Breast Within
				spellId = 212704
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
		end
		--UIFrameFadeOut(self, Duration, self.frame.alpha, 0)
		self:SetAlpha(self.frame.alpha) -- hack to apply transparency to the cooldown timer
	end
end

function LoseControl:PLAYER_FOCUS_CHANGED()
	--if (debug) then print("PLAYER_FOCUS_CHANGED") end
	self:UNIT_AURA("focus")
end

function LoseControl:PLAYER_TARGET_CHANGED()
	--if (debug) then print("PLAYER_TARGET_CHANGED") end
	self:UNIT_AURA("target")
end

function LoseControl:UNIT_PET(unitId)
	--if (debug) then print("UNIT_PET", unitId) end
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
	setmetatable(o, self)
	self.__index = self
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
				v:SetParent(nil) -- detach the frame from its parent or else it won't show if the parent is hidden
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
	PrioritySlider[k] = CreateSlider(L[k], OptionsPanel, 0, 100, 10)
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
PrioritySlider.CC:SetPoint("TOPLEFT", PrioritySlider.ImmuneSpell, "BOTTOMLEFT", 0, -24)
PrioritySlider.Silence:SetPoint("TOPLEFT", PrioritySlider.CC, "BOTTOMLEFT", 0, -24)
PrioritySlider.Disarm:SetPoint("TOPLEFT", PrioritySlider.Silence, "BOTTOMLEFT", 0, -24)
PrioritySlider.Root:SetPoint("TOPLEFT", PrioritySlider.Disarm, "BOTTOMLEFT", 0, -24)
PrioritySlider.Snare:SetPoint("TOPLEFT", PrioritySlider.Root, "BOTTOMLEFT", 0, -24)
PrioritySlider.Other:SetPoint("TOPLEFT", PrioritySlider.PvE, "TOPRIGHT", 40, 0)

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
				icon:SetParent(icon.anchor:GetParent())
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

	local Enabled = CreateFrame("CheckButton", O..v.."Enabled", OptionsPanelFrame, "OptionsCheckButtonTemplate")
	_G[O..v.."EnabledText"]:SetText(L["Enabled"])
	Enabled:SetScript("OnClick", function(self)
		local enabled = self:GetChecked()
		if enabled then
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		else
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
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
	SizeSlider:SetPoint("TOPLEFT", Enabled, "BOTTOMLEFT", 0, -32)
	AlphaSlider:SetPoint("TOPLEFT", SizeSlider, "BOTTOMLEFT", 0, -32)
	AnchorDropDownLabel:SetPoint("TOPLEFT", AlphaSlider, "BOTTOMLEFT", 0, -12)
	AnchorDropDown:SetPoint("TOPLEFT", AnchorDropDownLabel, "BOTTOMLEFT", 0, -8)

	OptionsPanelFrame.default = OptionsPanel.default
	OptionsPanelFrame.refresh = function()
		local unitId = v
		if unitId == "party" then
			DisableInBG:SetChecked(LoseControlDB.disablePartyInBG)
			unitId = "party1"
		elseif unitId == "arena" then
			DisableInBG:SetChecked(LoseControlDB.disableArenaInBG)
			unitId = "arena1"
		end
		local frame = LoseControlDB.frames[unitId]
		Enabled:SetChecked(frame.enabled)
		if frame.enabled then
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Enable(DisableInBG) end
			BlizzardOptionsPanel_Slider_Enable(SizeSlider)
			BlizzardOptionsPanel_Slider_Enable(AlphaSlider)
		else
			if DisableInBG then BlizzardOptionsPanel_CheckButton_Disable(DisableInBG) end
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
