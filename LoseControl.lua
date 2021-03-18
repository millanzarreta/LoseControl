local f = CreateFrame("Cooldown", "LoseControl_Frame");

local abilities = {
	-- Death Knight
	["Glyph of Frost Strike"] = 1,
	["Hungering Cold"] = 1,
	-- Druid
	["Bash"] = 1,
	["Cyclone"] = 1,
	["Feral Charge Effect"] = 1,
	["Hibernate"] = 1,
	["Maim"] = 1,
	["Pounce"] = 1,
	-- Hunter
	["Freezing Trap"] = 1,
	["Intimidation"] = 1,
	["Scare Beast"] = 1,
	["Scatter Shot"] = 1,
	["Wyvern Sting"] = 1,
	-- Mage
	["Deep Freeze"] = 1,
	["Dragon's Breath"] = 1,
	["Polymorph"] = 1,
	-- Paladin
	["Hammer of Justice"] = 1,
	["Repentance"] = 1,
	-- Priest
	["Mind Control"] = 1,
	["Psychic Scream"] = 1,
	-- Rogue
	["Blind"] = 1,
	["Cheap Shot"] = 1,
	["Gouge"] = 1,
	["Kidney Shot"] = 1,
	["Sap"] = 1,
	-- Shaman
	["Hex"] = 1,
	["Improved Fire Nova Totem"] = 1,
	["Stoneclaw Stun"] = 1,
	-- Warlock
	["Deathcoil"] = 1,
	["Fear"] = 1,
	["Howl of Terror"] = 1,
	["Seduction"] = 1,
	["Shadowfury"] = 1,
	-- Warrior
	["Charge Stun"] = 1,
	["Concussion Blow"] = 1,
	["Intercept Stun"] = 1,
	["Intimidating Shout"] = 1,
	["Revenge Stun"] = 1,
	["Shockwave"] = 1,
	-- other
	["Adamantite Grenade"] = 1,
	["Fel Iron Bomb"] = 1,
	["War Stomp"] = 1
}

function LoseControl_OnEvent(self, event, arg1)
	if ( arg1 == "player" ) then
		local maxExpirationTime = 0;
		local debuffTexture;

		for i=1, DEBUFF_MAX_DISPLAY do -- Iterating through all the debuffs via index should be faster than checking specifically for each debuff above, because typically there aren't that many debuffs on the player.
			local name, _, icon, _, _, _, expirationTime = UnitDebuff("player", i);
			if ( not name ) then
				break; -- no more debuffs, terminate the loop
			end
			--DEFAULT_CHAT_FRAME:AddMessage(i .. ") " .. name .. " | " .. expirationTime );

			if ( abilities[name] and expirationTime > maxExpirationTime ) then -- see if the name exists as a key in our table first
				maxExpirationTime = expirationTime;
				debuffTexture = icon;
			end
		end

		if ( maxExpirationTime > 0 ) then
			if ( f.texture:GetTexture() ~= debuffTexture ) then -- this is a new debuff, so initialize the cooldown
				f.texture:SetTexture(debuffTexture);
				f:Show();
				f:SetCooldown( GetTime(), maxExpirationTime - GetTime() );
			end
		else
			f.texture:SetTexture(nil);
			f:Hide();
		end
	end
end

f:SetScript("OnEvent", LoseControl_OnEvent);
f:RegisterEvent("UNIT_AURA");
f:SetWidth(36);
f:SetHeight(36);
f:SetPoint("CENTER", 0, 0);
f:SetFrameStrata("LOW");
f.texture = f:CreateTexture("LoseControl_Texture", "BACKGROUND");
f.texture:SetAllPoints(f);
