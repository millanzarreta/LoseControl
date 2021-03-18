if GetLocale() == "enUS" then
LoseControlAbilities = { -- This is our list of debuffs to check for. I don't use spellIDs because then it wouldn't work in PvE without adding a massive amount of spellIDs and I don't use texture icons because Blizzard re-uses too many of them for other spells.
	-- Death Knight
	["Cower in Fear"] = 1, -- effect added by Glyph of Death and Decay
	["Gnaw"] = 1,
	["Hungering Cold"] = 1,
	-- Druid
	["Bash"] = 1,
	["Cyclone"] = 1,
	["Feral Charge Effect"] = 1, -- an immobilize with silence is close enough
	["Hibernate"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["Maim"] = 1,
	["Pounce"] = 1,
	-- Hunter
	["Freezing Trap"] = 1,
	["Intimidation"] = 1,
	["Scare Beast"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["Scatter Shot"] = 1,
	["Wyvern Sting"] = 1,
	-- Mage
	["Deep Freeze"] = 1,
	["Dragon's Breath"] = 1,
	["Polymorph"] = 1,
	-- Paladin
	["Hammer of Justice"] = 1,
	["Holy Wrath"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	["Repentance"] = 1,
	["Turn Evil"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	-- Priest
	["Mind Control"] = 1,
	["Psychic Scream"] = 1,
	["Shackle Undead"] = 1, -- works against Death Knights using Lichborne
	-- Rogue
	["Blind"] = 1,
	["Cheap Shot"] = 1,
	["Gouge"] = 1,
	["Kidney Shot"] = 1,
	["Sap"] = 1,
	-- Shaman
	["Hex"] = 1, -- even though you can still "control" your character, you cannot attack or cast spells
	["Improved Fire Nova Totem"] = 1,
	["Stoneclaw Stun"] = 1,
	-- Warlock
	["Banish"] = 1, -- works against Warlocks using Metamorphasis and Druids using Tree Form
	["Death Coil"] = 1,
	["Fear"] = 1,
	["Howl of Terror"] = 1,
	["Seduction"] = 1,
	["Shadowfury"] = 1,
	-- Warrior
	["Charge Stun"] = 1,
	["Concussion Blow"] = 1,
	["Intercept"] = 1,
	["Intimidating Shout"] = 1,
	["Revenge Stun"] = 1,
	["Shockwave"] = 1,
	-- other
	["Adamantite Grenade"] = 1,
	["Fel Iron Bomb"] = 1,
	["War Stomp"] = 1
}
end
