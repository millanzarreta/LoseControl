if GetLocale() == "koKR" then
LoseControlAbilities = { -- This is our list of debuffs to check for. I don't use spellIDs because then it wouldn't work in PvE without adding a massive amount of spellIDs and I don't use texture icons because Blizzard re-uses too many of them for other spells.
	-- Death Knight
	["공포에 질림"] = 1, -- effect added by Glyph of Death and Decay
	["물어뜯기"] = 1,
	["갈망의 한기"] = 1,
	-- Druid
	["강타"] = 1,
	["회오리바람"] = 1,
	["성의 돌진"] = 1, -- an immobilize with silence is close enough
	["겨울잠"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["무력화"] = 1,
	["암습"] = 1,
	-- Hunter
	["얼음의 덫"] = 1,
	["위협"] = 1,
	["야수 겁주기"] = 1, -- works against Druids in most forms and Shamans using Ghost Wolf
	["산탄 사격"] = 1,
	["비룡 쐐기"] = 1,
	-- Mage
	["동결"] = 1,
	["용의 숨결"] = 1,
	["변이"] = 1,
	-- Paladin
	["심판의 망치"] = 1,
	["신의 격노"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	["참회"] = 1,
	["악령 퇴치"] = 1, -- works against Warlocks using Metamorphasis and Death Knights using Lichborne
	-- Priest
	["정신 지배"] = 1,
	["영혼의 절규"] = 1,
	["언데드 속박"] = 1, -- works against Death Knights using Lichborne
	-- Rogue
	["실명"] = 1,
	["비열한 습격"] = 1,
	["후려치기"] = 1,
	["급소 가격"] = 1,
	["기절시키기"] = 1,
	-- Shaman
	["주술"] = 1, -- even though you can still "control" your character, you cannot attack or cast spells
	["불꽃 회오리 토템 연마"] = 1,
	["돌발톱 기절"] = 1,
	-- Warlock
	["추방"] = 1, -- works against Warlocks using Metamorphasis and Druids using Tree Form
	["죽음의 고리"] = 1,
	["공포"] = 1,
	["공포의 울부짖음"] = 1,
	["유혹"] = 1,
	["어둠의 격노"] = 1,
	-- Warrior
	["돌진 기절"] = 1,
	["충격의 일격"] = 1,
	["봉쇄 기절"] = 1,
	["위협의 외침"] = 1,
	["복수 기절"] = 1,
	["충격파"] = 1,
	-- other
	["아다만타이트 수류탄"] = 1,
	["지옥무쇠 폭탄"] = 1,
	["전투 발구르기"] = 1
}
end
