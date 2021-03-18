if GetLocale() == "zhTW" then
LoseControlAbilities = { -- This is our list of debuffs to check for. I don't use spellIDs because then it wouldn't work in PvE without adding a massive amount of spellIDs and I don't use texture icons because Blizzard re-uses too many of them for other spells.
	-- Death Knight
	["惶恐畏縮"] = 1, -- effect added by Glyph of Death and Decay
	["啃食"] = 1,
	["噬溫酷寒"] = 1,
	-- Druid
	["重擊"] = 1,
	["颶風術"] = 1,
	["野性衝鋒效果"] = 1, -- an immobilize with silence is close enough
	["休眠"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["傷殘術"] = 1,
	["突襲"] = 1,
	-- Hunter
	["冰凍陷阱"] = 1,
	["脅迫"] = 1,
	["恐嚇野獸"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["驅散射擊"] = 1,
	["翼龍釘刺"] = 1,
	-- Mage
	["極度冰凍"] = 1,
	["龍之吐息"] = 1,
	["變形術"] = 1,
	-- Paladin
	["制裁之錘"] = 1,
	["神聖憤怒"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	["懺悔"] = 1,
	["退邪術"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	-- Priest
	["精神控制"] = 1,
	["心靈尖嘯"] = 1,
	["束縛不死生物"] = 1, -- works against Death Knights using Lichborne
	-- Rogue
	["致盲"] = 1,
	["偷襲"] = 1,
	["鑿擊"] = 1,
	["腎擊"] = 1,
	["悶棍"] = 1,
	-- Shaman
	["妖術"] = 1, -- even though you can still "control" your character, you cannot attack or cast spells
	["強化火焰新星圖騰"] = 1,
	["石爪昏迷"] = 1,
	-- Warlock
	["放逐術"] = 1, -- works against Warlocks using Metamorphasis and Druids using Tree Form
	["死亡纏繞"] = 1,
	["恐懼術"] = 1,
	["恐懼嚎叫"] = 1,
	["誘惑"] = 1,
	["暗影之怒"] = 1,
	-- Warrior
	["衝鋒昏迷"] = 1,
	["震盪猛擊"] = 1,
	["攔截昏迷"] = 1,
	["破膽怒吼"] = 1,
	["復仇昏迷"] = 1,
	["震攝波"] = 1,
	-- other
	["堅鋼手榴彈"] = 1,
	["魔鐵炸彈"] = 1,
	["戰爭踐踏"] = 1
}
end
