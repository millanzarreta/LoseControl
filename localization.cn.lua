  --translate by 饺子
if GetLocale() == "zhCN" then
LoseControlAbilities = { -- This is our list of debuffs to check for. I don't use spellIDs because then it wouldn't work in PvE without adding a massive amount of spellIDs and I don't use texture icons because Blizzard re-uses too many of them for other spells.
	-- Death Knight
	["恐惧畏缩"] = 1, -- effect added by Glyph of Death and Decay
	["撕扯"] = 1,
	["饥饿之寒"] = 1,
	-- Druid
	["猛击"] = 1,
	["旋风"] = 1,
	["野性冲锋效果"] = 1, -- an immobilize with silence is close enough
	["休眠"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["割碎"] = 1,
	["突袭"] = 1,
	-- Hunter
	["冰冻陷阱"] = 1,
	["胁迫"] = 1,
	["恐吓野兽"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["驱散射击"] = 1,
	["翼龙钉刺"] = 1,
	-- Mage
	["深度冻结"] = 1,
	["龙息术"] = 1,
	["变形术"] = 1,
	-- Paladin
	["制裁之锤"] = 1,
	["神圣愤怒"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	["忏悔"] = 1,
	["超度邪恶"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	-- Priest
	["精神控制"] = 1,
	["心灵尖啸"] = 1,
	["束缚亡灵"] = 1, -- works against Death Knights using Lichborne
	-- Rogue
	["致盲"] = 1,
	["偷袭"] = 1,
	["凿击"] = 1,
	["肾击"] = 1,
	["闷棍"] = 1,
	-- Shaman
	["妖术"] = 1, -- even though you can still "control" your character, you cannot attack or cast spells
	["强化火焰新星图腾"] = 1,
	["石爪昏迷"] = 1,
	-- Warlock
	["放逐术"] = 1, -- works against Warlocks using Metamorphasis and Druids using Tree Form
	["死亡缠绕"] = 1,
	["恐惧"] = 1,
	["恐惧嚎叫"] = 1,
	["诱惑"] = 1,
	["暗影之怒"] = 1,
	-- Warrior
	["冲锋击昏"] = 1,
	["震荡猛击"] = 1,
	["拦截"] = 1,
	["破胆怒吼"] = 1,
	["复仇昏迷"] = 1,
	["震荡波"] = 1,
	-- other
	["精金手雷"] = 1,
	["魔铁炸弹"] = 1,
	["战争践踏"] = 1
}
end
