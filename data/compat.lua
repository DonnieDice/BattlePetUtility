-- Compatibility shims for modern Retail API namespaces.
-- These are loaded before embedded libraries so legacy calls still resolve.

local function TableLen(tbl)
	if type(tbl) ~= "table" then
		return 0;
	end

	return #tbl;
end

local unpackFunc = unpack or table.unpack;

if type(GetSpellInfo) ~= "function" and C_Spell and type(C_Spell.GetSpellInfo) == "function" then
	function GetSpellInfo(spellIdentifier)
		local spellInfo = C_Spell.GetSpellInfo(spellIdentifier);
		if not spellInfo then
			return nil;
		end

		return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID;
	end
end

if type(GetSpellCooldown) ~= "function" and C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
	function GetSpellCooldown(spellIdentifier)
		local cooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier);
		if not cooldownInfo then
			return 0, 0, 0, 1;
		end

		local enabled = 1;
		pcall(function() enabled = cooldownInfo.isEnabled and 1 or 0; end);
		return cooldownInfo.startTime or 0, cooldownInfo.duration or 0, enabled, cooldownInfo.modRate or 1;
	end
end

if type(IsUsableSpell) ~= "function" and C_Spell and type(C_Spell.IsSpellUsable) == "function" then
	function IsUsableSpell(spellIdentifier)
		local usable, noMana = C_Spell.IsSpellUsable(spellIdentifier);

		if type(usable) == "table" then
			local info = usable;
			return info.isUsable and true or false, info.notEnoughMana and true or false;
		end

		return usable and true or false, noMana and true or false;
	end
end

if type(IsUsableItem) ~= "function" and C_Item and type(C_Item.IsUsableItem) == "function" then
	function IsUsableItem(item)
		local usable = C_Item.IsUsableItem(item);

		if type(usable) == "table" then
			local info = usable;
			return info.isUsable and true or false;
		end

		return usable and true or false;
	end
end

if type(GetPetTypeTexture) ~= "function" then
	local PET_TYPE_TEXTURE_SUFFIX = {
		[1] = "Humanoid",
		[2] = "Dragon",
		[3] = "Flying",
		[4] = "Undead",
		[5] = "Critter",
		[6] = "Magical",
		[7] = "Elemental",
		[8] = "Beast",
		[9] = "Water",
		[10] = "Mechanical",
	};

	function GetPetTypeTexture(petType)
		local suffix = PET_TYPE_TEXTURE_SUFFIX[petType];
		if(not suffix and type(PET_TYPE_SUFFIX) == "table") then
			suffix = PET_TYPE_SUFFIX[petType];
		end

		if(not suffix) then
			suffix = "Humanoid";
		end

		return "Interface\\PetBattles\\PetIcon-" .. suffix;
	end
end

if type(GetNumGossipOptions) ~= "function" and C_GossipInfo and type(C_GossipInfo.GetOptions) == "function" then
	function GetNumGossipOptions()
		return TableLen(C_GossipInfo.GetOptions());
	end
end

if type(GetGossipOptions) ~= "function" and C_GossipInfo and type(C_GossipInfo.GetOptions) == "function" then
	function GetGossipOptions()
		local options = C_GossipInfo.GetOptions();
		if type(options) ~= "table" then
			return;
		end

		local flattened = {};
		for _, option in ipairs(options) do
			flattened[#flattened + 1] = option.name or "";
			flattened[#flattened + 1] = option.type or "gossip";
		end

		return unpackFunc(flattened);
	end
end

if type(SelectGossipOption) ~= "function" and C_GossipInfo and type(C_GossipInfo.GetOptions) == "function" and type(C_GossipInfo.SelectOption) == "function" then
	function SelectGossipOption(index, text, confirmed)
		local options = C_GossipInfo.GetOptions();
		if type(options) ~= "table" then
			return;
		end

		local option = options[index];
		if not option then
			return;
		end

		C_GossipInfo.SelectOption(option.gossipOptionID or option.orderIndex or index, text, confirmed);
	end
end

if type(GetNumGossipAvailableQuests) ~= "function" and C_GossipInfo and type(C_GossipInfo.GetAvailableQuests) == "function" then
	function GetNumGossipAvailableQuests()
		return TableLen(C_GossipInfo.GetAvailableQuests());
	end
end

if type(GetNumGossipActiveQuests) ~= "function" and C_GossipInfo and type(C_GossipInfo.GetActiveQuests) == "function" then
	function GetNumGossipActiveQuests()
		return TableLen(C_GossipInfo.GetActiveQuests());
	end
end

if C_PetJournal then
	if type(C_PetJournal.GetPetInfoByPetID) == "function" then
		local OriginalGetPetInfoByPetID = C_PetJournal.GetPetInfoByPetID;
		C_PetJournal.GetPetInfoByPetID = function(...)
			local a, b, c, d, e, f, g, h, i, j, k, l, m, n, o = OriginalGetPetInfoByPetID(...);
			if type(a) == "table" and b == nil then
				local info = a;
				return info.speciesID, info.customName, info.level, info.xp, info.maxXp, info.displayID, info.isFavorite, info.name, info.icon, info.petType, info.creatureID, info.sourceText, info.description, info.isWild, info.canBattle;
			end
			return a, b, c, d, e, f, g, h, i, j, k, l, m, n, o;
		end
	end

	if type(C_PetJournal.GetPetInfoBySpeciesID) == "function" then
		local OriginalGetPetInfoBySpeciesID = C_PetJournal.GetPetInfoBySpeciesID;
		C_PetJournal.GetPetInfoBySpeciesID = function(...)
			local a, b, c, d, e, f, g = OriginalGetPetInfoBySpeciesID(...);
			if type(a) == "table" and b == nil then
				local info = a;
				return info.name, info.icon, info.petType, info.creatureID, info.sourceText, info.description, info.isWild;
			end
			return a, b, c, d, e, f, g;
		end
	end

	if type(C_PetJournal.GetPetLoadOutInfo) == "function" then
		local OriginalGetPetLoadOutInfo = C_PetJournal.GetPetLoadOutInfo;
		C_PetJournal.GetPetLoadOutInfo = function(...)
			local a, b, c, d, e = OriginalGetPetLoadOutInfo(...);
			if type(a) == "table" and b == nil then
				local info = a;
				return info.petID, info.ability1ID or info.abilityID1, info.ability2ID or info.abilityID2, info.ability3ID or info.abilityID3, info.locked;
			end
			return a, b, c, d, e;
		end
	end

	if type(C_PetJournal.GetPetStats) == "function" then
		local OriginalGetPetStats = C_PetJournal.GetPetStats;
		C_PetJournal.GetPetStats = function(...)
			local a, b, c, d, e = OriginalGetPetStats(...);
			if type(a) == "table" and b == nil then
				local info = a;
				return info.health, info.maxHealth, info.power, info.speed, info.rarity;
			end
			return a, b, c, d, e;
		end
	end

	if type(C_PetJournal.GetPetAbilityInfo) == "function" then
		local OriginalGetPetAbilityInfo = C_PetJournal.GetPetAbilityInfo;
		C_PetJournal.GetPetAbilityInfo = function(...)
			local a, b, c, d = OriginalGetPetAbilityInfo(...);
			if type(a) == "table" and b == nil then
				local info = a;
				return info.name, info.icon, info.petType, info.cooldown;
			end
			return a, b, c, d;
		end
	end
end
