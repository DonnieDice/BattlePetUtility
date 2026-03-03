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

		local enabled = cooldownInfo.isEnabled and 1 or 0;
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
