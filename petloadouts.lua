--[[
	Pet Buddy by Sonaza
	Battle Pet management addon
	
	All rights reserved
	Questions can be sent to temu92@gmail.com
--]]

local ADDON_NAME, addon = ...;

local PETBUDDY_LOADOUT_TEXT = "Enter a name for current pet loadout:|n|n%s";
local CURRENT_LOADOUT_NAME = nil;

StaticPopupDialogs["PETBUDDY_LOADOUT_ERROR_LOCKED"] = {
	text = "Cannot save loadout: all pet battle slots are not unlocked.",
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["PETBUDDY_LOADOUT_ERROR_NOT_FOUND"] = {
	text = "Cannot restore loadout: all saved pets cannot be found.",
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["PETBUDDY_LOADOUT_SAVE_EXISTS"] = {
	text = "Another loadout with the same name already exists. Do you want to overwrite?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		local data = self.data;
		if(data.newSave) then
			addon:DeleteLoadout(data.name);
			addon:SaveLoadout(data.name);
		else
			addon:DeleteLoadout(data.name);
			addon:RenameLoadout(data.oldName, data.name);
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["PETBUDDY_LOADOUT_OVERWRITE"] = {
	text = "Are you sure you want to overwrite \"%s\" with current loadout?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		local name = self.data;
		addon:DeleteLoadout(name);
		addon:SaveLoadout(name);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["PETBUDDY_LOADOUT_RESTORE"] = {
	text = "Are you sure you want to restore loadout \"%s\"?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		addon:RestoreLoadout(self.data);
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["PETBUDDY_LOADOUT_DELETE"] = {
	text = "Are you sure you want to |cffff5555delete|r loadout \"%s\"? The action cannot be undone.",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		addon:DeleteLoadout(self.data);
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["PETBUDDY_LOADOUT_REMATCH_MANAGED"] = {
	text = "Loadouts are managed by Rematch while it is enabled. Create, rename, and delete teams in Rematch.",
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};
	
StaticPopupDialogs["PETBUDDY_LOADOUT_SAVE"] = {
	text = "Enter a name for current pet loadout:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 38,
	OnAccept = function(self)
		local name = string.trim(self.editBox:GetText());
		addon:SaveLoadout(name);
	end,
	EditBoxOnEnterPressed = function(self)
		local name = string.trim(self:GetParent().editBox:GetText());
		addon:SaveLoadout(name);
		self:GetParent():Hide();
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
};

local function IsPetGUID(petID)
	return type(petID) == "string" and string.match(petID, "^BattlePet%-") ~= nil;
end

function addon:IsRematchLoadoutsEnabled()
	return type(Rematch) == "table"
		and type(Rematch.savedTeams) == "table"
		and type(Rematch.loadTeam) == "table"
		and type(Rematch.loadTeam.LoadTeamID) == "function";
end

function addon:GetRematchTeamIDByName(name)
	if(not addon:IsRematchLoadoutsEnabled() or type(name) ~= "string") then return nil end
	if(type(Rematch.savedTeams.GetTeamIDByName) == "function") then
		return Rematch.savedTeams:GetTeamIDByName(name);
	end

	for teamID, team in pairs(Rematch5SavedTeams or {}) do
		if(team and string.lower(team.name or "") == string.lower(name)) then
			return teamID;
		end
	end
end

function addon:BuildRematchLoadout(teamID, team)
	if(not team) then return nil end

	local pets = {};
	local usedPetIDs = {};

	for slotIndex = 1, 3 do
		local rematchPetID = team.pets and team.pets[slotIndex] or nil;
		local rematchTag = team.tags and team.tags[slotIndex] or nil;

		local ability1, ability2, ability3 = nil, nil, nil;
		if(Rematch.petTags and type(Rematch.petTags.GetAbilities) == "function" and rematchTag) then
			ability1, ability2, ability3 = Rematch.petTags:GetAbilities(rematchTag);
		end

		local resolvedPetID = rematchPetID;
		if(IsPetGUID(resolvedPetID)) then
			usedPetIDs[resolvedPetID] = true;
		else
			resolvedPetID = nil;
			if(Rematch.petTags and type(Rematch.petTags.FindPetID) == "function" and rematchTag) then
				local candidate = Rematch.petTags:FindPetID(rematchTag, usedPetIDs);
				if(IsPetGUID(candidate)) then
					resolvedPetID = candidate;
					usedPetIDs[candidate] = true;
				end
			end
		end

		pets[slotIndex] = {
			petID = resolvedPetID,
			abilities = { ability1, ability2, ability3 },
			rematchPetID = rematchPetID,
			rematchTag = rematchTag,
		};
	end

	return {
		name = team.name or ("Rematch Team " .. tostring(teamID or "")),
		pets = pets,
		rematchTeamID = teamID,
		isRematch = true,
	};
end

function addon:GetRematchLoadouts()
	local loadoutData = {};
	if(not addon:IsRematchLoadoutsEnabled()) then return loadoutData, 0 end

	local filterText = PetBuddyFrameLoadouts and PetBuddyFrameLoadouts.filterText or "";

	local iter = nil;
	local state = nil;
	local key = nil;

	if(type(Rematch.savedTeams.AllTeams) == "function") then
		iter, state, key = Rematch.savedTeams:AllTeams();
	else
		state = Rematch5SavedTeams or {};
		iter = next;
	end

	while(true) do
		local teamID, team = iter(state, key);
		key = teamID;
		if(teamID == nil) then
			break;
		end

		if(type(team) == "table" and team.name and team.name ~= "") then
			local data = addon:BuildRematchLoadout(teamID, team);
			if(data) then
				local searchHit = true;
				if(filterText and filterText ~= "") then
					local loweredName = string.lower(data.name or "");
					searchHit = string.find(loweredName, filterText, 1, true) ~= nil;

					if(not searchHit) then
						for i = 1, 3 do
							local petData = data.pets[i];
							if(petData and petData.petID) then
								local speciesID, customName, _, _, _, _, _, speciesName = C_PetJournal.GetPetInfoByPetID(petData.petID);
								if(speciesID) then
									if(string.find(string.lower(speciesName or ""), filterText, 1, true)) then
										searchHit = true;
										break;
									end
									if(customName and string.find(string.lower(customName), filterText, 1, true)) then
										searchHit = true;
										break;
									end
								end
							end
						end
					end
				end

				if(searchHit) then
					tinsert(loadoutData, data);
				end
			end
		end
	end

	table.sort(loadoutData, function(a, b)
		return string.lower(a.name or "") < string.lower(b.name or "");
	end);

	return loadoutData, #loadoutData;
end
	
StaticPopupDialogs["PETBUDDY_LOADOUT_RENAME"] = {
	text = "Enter a new name for the loadout:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 38,
	OnAccept = function(self)
		local new_name = string.trim(self.editBox:GetText());
		addon:RenameLoadout(self.data, new_name);
	end,
	EditBoxOnEnterPressed = function(self)
		local new_name = string.trim(self:GetParent().editBox:GetText());
		addon:RenameLoadout(self:GetParent().data, new_name);
		self:GetParent():Hide();
	end,
	OnShow = function(self)
		self.editBox:SetText(self.data);
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
};

function addon:GetPetLoadoutText(saved_loadout)
	local loadoutText = "";
	for slotIndex = 1, 3 do
		local petID, ability1, ability2, ability3, locked;
		
		if(not saved_loadout) then
			petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slotIndex);
		elseif(saved_loadout[slotIndex] and saved_loadout[slotIndex].petID and saved_loadout[slotIndex].abilities) then
			petID = saved_loadout[slotIndex].petID;
			ability1, ability2, ability3 = unpack(saved_loadout[slotIndex].abilities);
			locked = false;
		elseif(saved_loadout[slotIndex] and saved_loadout[slotIndex].abilities) then
			ability1, ability2, ability3 = unpack(saved_loadout[slotIndex].abilities);
		end
		
		local petString;
		
		if(petID and C_PetJournal.GetPetInfoByPetID(petID)) then
			local speciesID, customName, level, _, _, _, _, speciesName, _, petType = C_PetJournal.GetPetInfoByPetID(petID);
			local health, maxHealth, _, _, rarity = C_PetJournal.GetPetStats(petID);
			
			local ability1_name = ability1 and C_PetJournal.GetPetAbilityInfo(ability1) or nil;
			local ability2_name = ability2 and C_PetJournal.GetPetAbilityInfo(ability2) or nil;
			local ability3_name = ability3 and C_PetJournal.GetPetAbilityInfo(ability3) or nil;
			
			ability1_name = ability1_name or "-";
			ability2_name = ability2_name or "-";
			ability3_name = ability3_name or "-";
			
			local rarityColor = ITEM_QUALITY_COLORS[(rarity or 1)-1] or ITEM_QUALITY_COLORS[1];
			
			local petTypeSuffix = PET_TYPE_SUFFIX[petType or 1] or PET_TYPE_SUFFIX[1];
			local petTypeIcon = "|TInterface\\PetBattles\\PetIcon-"..petTypeSuffix..":16:16:0:0:128:256:102:63:129:168|t";
			
			local formattedSpeciesName = not customName and speciesName ;
			
			if(customName) then
				petString = string.format("%s[%d]|r |cffffffff%s|r |cff999999(%s)|r %s|n%s / %s / %s",
					rarityColor.hex, level, customName, speciesName, petTypeIcon,
					ability1_name, ability2_name, ability3_name);
			else
				petString = string.format("%s[%d]|r |cffffffff%s|r %s|n%s / %s / %s",
					rarityColor.hex, level, speciesName, petTypeIcon,
					ability1_name, ability2_name, ability3_name);
			end
		else
			petString = string.format("|cffff5555Pet #%d not found|r", slotIndex);
		end
		
		loadoutText = string.format("%s%s|n|n", loadoutText, petString);
	end
	
	return loadoutText;
end
	
function addon:SaveLoadout(loadout_name)
	if(not loadout_name) then return false end
	if(loadout_name == "") then return end

	if(addon:IsRematchLoadoutsEnabled()) then
		StaticPopup_Show("PETBUDDY_LOADOUT_REMATCH_MANAGED");
		return false;
	end
	
	if(self.db.global.SavedLoadouts[loadout_name]) then
		StaticPopup_Show("PETBUDDY_LOADOUT_SAVE_EXISTS", loadout_name, nil, {
			newSave = true,
			name = loadout_name,
		});
	end
	
	local currentLoadout = {};
	
	for slotIndex = 1, 3 do
		local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slotIndex);
		if(locked) then
			StaticPopup_Show("PETBUDDY_LOADOUT_ERROR_LOCKED");
			return false;
		end
		
		tinsert(currentLoadout, {
			petID = petID,
			abilities = { ability1, ability2, ability3 },
		});
	end
	
	self.db.global.SavedLoadouts[loadout_name] = currentLoadout;
	
	PetBuddyFrameLoadouts_UpdateList();
	CloseMenus();
end

function addon:RestoreLoadout(loadout_info)
	if(not loadout_info) then return false end

	local rematchTeamID = nil;
	local loadout_name = loadout_info;

	if(type(loadout_info) == "table") then
		loadout_name = loadout_info.name;
		rematchTeamID = loadout_info.rematchTeamID;
	elseif(type(loadout_info) == "string" and addon:IsRematchLoadoutsEnabled()) then
		rematchTeamID = addon:GetRematchTeamIDByName(loadout_info);
	end

	if(rematchTeamID and addon:IsRematchLoadoutsEnabled()) then
		Rematch.loadTeam:LoadTeamID(rematchTeamID);
		addon:UpdatePets();
		PetBuddyPetFrame_ResetAbilitySwitches();
		PetBuddyFrameLoadoutsScrollFrame_ToggleVisibility(false);
		CloseMenus();
		PetBuddyFrameLoadoutsSearchBox:ClearFocus();
		return true;
	end

	if(not loadout_name or loadout_name == "") then return false end

	local loadout = self.db.global.SavedLoadouts[loadout_name];
	if(not loadout) then return false end
	
	for slotIndex, data in ipairs(loadout) do
		if(not C_PetJournal.GetPetInfoByPetID(data.petID)) then
			StaticPopup_Show("PETBUDDY_LOADOUT_ERROR_NOT_FOUND");
			return;
		end
	end
	
	for slotIndex, data in ipairs(loadout) do
		C_PetJournal.SetPetLoadOutInfo(slotIndex, data.petID);
		
		for spellIndex, abilityID in ipairs(data.abilities) do
			C_PetJournal.SetAbility(slotIndex, spellIndex, abilityID);
		end
	end
	
	addon:RefreshPetJournalLoadOut();
	PetBuddyPetFrame_ResetAbilitySwitches();
	
	PetBuddyFrameLoadoutsScrollFrame_ToggleVisibility(false);
	CloseMenus();
	
	PetBuddyFrameLoadoutsSearchBox:ClearFocus();
end

function addon:RenameLoadout(old_loadout_name, new_loadout_name)
	if(not old_loadout_name or not new_loadout_name) then return false end
	if(new_loadout_name == "") then return end
	
	if(addon:IsRematchLoadoutsEnabled()) then
		StaticPopup_Show("PETBUDDY_LOADOUT_REMATCH_MANAGED");
		return false;
	end
	
	if(self.db.global.SavedLoadouts[new_loadout_name]) then
		StaticPopup_Show("PETBUDDY_LOADOUT_SAVE_EXISTS", new_loadout_name, nil, {
			newSave = false,
			name = new_loadout_name,
			oldName = old_loadout_name,
		});
	end
	
	self.db.global.SavedLoadouts[new_loadout_name] = self.db.global.SavedLoadouts[old_loadout_name];
	self.db.global.SavedLoadouts[old_loadout_name] = nil;
	
	PetBuddyFrameLoadouts_UpdateList();
	CloseMenus();
end

function addon:DeleteLoadout(loadout_name)
	if(not loadout_name) then return false end
	if(loadout_name == "") then return end
	
	if(addon:IsRematchLoadoutsEnabled()) then
		StaticPopup_Show("PETBUDDY_LOADOUT_REMATCH_MANAGED");
		return false;
	end
	
	if(self.db.global.SavedLoadouts[loadout_name]) then
		self.db.global.SavedLoadouts[loadout_name] = nil;
	end
	
	PetBuddyFrameLoadouts_UpdateList();
	CloseMenus();
end

function addon:GetSortedLoadouts()
	if(addon:IsRematchLoadoutsEnabled()) then
		local rematchLoadouts, numRematchLoadouts = addon:GetRematchLoadouts();
		if(numRematchLoadouts > 0) then
			return rematchLoadouts, numRematchLoadouts;
		end
	end

	local loadoutData = {};
	for loadout_name, pets in pairs(addon.db.global.SavedLoadouts) do
		local searchHit = true;
		if(PetBuddyFrameLoadouts.filterText ~= "") then
			searchHit = string.find(string.lower(loadout_name), PetBuddyFrameLoadouts.filterText) ~= nil;
			
			if(not searchHit) then
				for i=1, 3 do
					local speciesID, customName, _, _, _, _, _, speciesName = C_PetJournal.GetPetInfoByPetID(pets[i].petID);
					if(speciesID) then
						searchHit = string.find(string.lower(speciesName), PetBuddyFrameLoadouts.filterText) ~= nil;
						
						if(not searchHit and customName) then
							searchHit = string.find(string.lower(customName), PetBuddyFrameLoadouts.filterText) ~= nil;
						end
					end
					
					if(searchHit) then break; end
				end
			end
		end
		
		if(searchHit) then
			tinsert(loadoutData, {
				name = loadout_name,
				pets = pets,
			});
		end
	end
	
	table.sort(loadoutData, function(a, b)
		if(a == nil and b == nil) then return false end
		if(a == nil) then return true end
		if(b == nil) then return false end
		
		return string.lower(a.name) < string.lower(b.name);
	end);
	
	if(#loadoutData == 0) then
		tinsert(loadoutData, {
			name = "N/addon",
			pets = {},
			notFound = true,
		});
	end
	
	return loadoutData, #loadoutData;
end

function PetBuddyFrameLoadouts_UpdateList()
	local scrollFrame = PetBuddyFrameLoadouts.scrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	
	local loadoutData, foundLoadouts = addon:GetSortedLoadouts();
	
	local button, index;
	for i=1, #buttons do
		button = buttons[i];
		index = offset + i;
		local data = loadoutData[index];
		
		if(index <= foundLoadouts) then
			button.data = data;
			
			if(not data.notFound) then
				button.errorText:Hide();
				
				button.name:Show();
				button.name:SetText(data.name);
				
				button.background:SetVertexColor(1, 1, 1);
				button.backgroundError:Hide();
				button.hasMissingPet = false;
				
				for i=1,3 do
					local petIcon = button['pet'..i];
					petIcon:Show();
					
					local petID = data.pets[i].petID;
					
					local speciesID, customName, level, _, _, _, _, name, icon, petType = C_PetJournal.GetPetInfoByPetID(petID);
					
					if(speciesID) then
						local health, maxHealth, _, _, rarity = C_PetJournal.GetPetStats(petID);
						local rarityColor = ITEM_QUALITY_COLORS[(rarity or 1)-1] or ITEM_QUALITY_COLORS[1];
						
						petIcon.level:SetText(level);
						
						petIcon.icon:Show();
						petIcon.icon:SetTexture(icon);
						petIcon.iconBorder:SetVertexColor(rarityColor.r, rarityColor.g, rarityColor.b);
						
						petIcon.petTypeIcon:Show();
						petIcon.petTypeIcon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType or 1]);
						
						petIcon.isDead:Hide();
					else
						petIcon.level:SetText("");
						
						if(data.isRematch) then
							petIcon.icon:Show();
							petIcon.icon:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark");
							petIcon.iconBorder:SetVertexColor(0.7, 0.6, 0.2);
							petIcon.petTypeIcon:Hide();
							petIcon.isDead:Hide();
						else
							petIcon.icon:Hide();
							petIcon.iconBorder:SetVertexColor(0.8, 0.1, 0.1);
							petIcon.petTypeIcon:Hide();
							petIcon.isDead:Show();
							
							button.background:SetVertexColor(0.8, 0.1, 0.1);
							button.backgroundError:Show();
							button.hasMissingPet = true;
						end
					end
				end
				
				button:SetScript("OnEnter", PetBuddyLoadoutsButton_OnEnter);
				button:SetScript("OnLeave", PetBuddyLoadoutsButton_OnLeave);
			else
				for i=1,3 do
					local petIcon = button['pet'..i];
					petIcon:Hide();
				end
				
				button.name:Hide();
				
				button.errorText:Show();
				button.errorText:SetText("No Results");
				
				button:SetScript("OnEnter", nil);
				button:SetScript("OnLeave", nil);
			end
			
			button:Show();
		else
			button.data = nil;
			button.hasMissingPet = false;
			button:Hide();
		end
	end
	
	local totalHeight = foundLoadouts * 46;
	HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight());
end

function PetBuddyLoadoutsButton_OnClick(self, button)
	if(self.data.notFound) then return end
	
	if(button == "LeftButton") then
		if(self.data.isRematch or not self.hasMissingPet) then
			StaticPopup_Show("PETBUDDY_LOADOUT_RESTORE", self.data.name, nil, self.data)
		else
			StaticPopup_Show("PETBUDDY_LOADOUT_DELETE", self.data.name, nil, self.data.name)
		end
	elseif(button == "RightButton") then
		PetBuddyFrameLoadouts_OpenContextMenu(self)
	end
end

function PetBuddyLoadoutsButton_OnEnter(self)
	if(not self.data) then return end
	
	GameTooltip:ClearLines();
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint("RIGHT", self, "LEFT", -1, 0);
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	
	GameTooltip:AddLine("Loadout: |cffffffff" .. self.data.name .. "|r");
	GameTooltip:AddLine("|n");
	GameTooltip:AddLine(addon:GetPetLoadoutText(self.data.pets));
	
	if(self.data.isRematch) then
		GameTooltip:AddLine("|n");
		GameTooltip:AddLine("|cff58be81Managed by Rematch|r");
		GameTooltip:AddLine("Left-Click |cffffffffLoad this Rematch team");
	elseif(not self.hasMissingPet) then
		GameTooltip:AddLine("Left-Click |cffffffffRestore this loadout");
	else
		GameTooltip:AddLine("|cffff5555One or more pets are missing and this saved loadout is invalid");
		GameTooltip:AddLine("|n");
		GameTooltip:AddLine("Left-Click |cffffffffDelete this loadout");
	end
	
	GameTooltip:AddLine("Right-Click |cffffffffOpen options");
	
	GameTooltip:Show();
end

function PetBuddyLoadoutsButton_OnLeave(self)
	GameTooltip:Hide();
end

function PetBuddyFrameLoadouts_OnSearchTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self);
	PetBuddyFrameLoadouts.filterText = string.lower(self:GetText());
	
	if(PetBuddyFrameLoadouts.filterText ~= "") then
		PetBuddyFrameLoadoutsScrollFrame_ToggleVisibility(true);
	end
	
	PetBuddyFrameLoadouts_UpdateList();
end

function PetBuddyFrameLoadouts_OnLoad(self)
	self.filterText = "";
	self.scrollFrame.update = PetBuddyFrameLoadouts_UpdateList;
	-- self.scrollFrame.scrollBar.doNotHide = true;
	
	HybridScrollFrame_CreateButtons(self.scrollFrame, "PetBuddyLoadoutsButtonTemplate", 0, 0, nil, nil, 0, 0);
end

function PetBuddyLoadoutsSaveButton_OnLoad(self)
	local actionData = {
		iconTexture = "Interface\\AddOns\\BetterPetBuddy\\Media\\SaveButtonIcon",
		-- count = "S",
		tooltipTitle = "Save Loadout",
		tooltipDescription = "Save current pets and abilities so that they can later be restored (disabled when Rematch controls loadouts)",
		func = function(self)
			if(addon:IsRematchLoadoutsEnabled()) then
				StaticPopup_Show("PETBUDDY_LOADOUT_REMATCH_MANAGED");
			else
				StaticPopup_Show("PETBUDDY_LOADOUT_SAVE");
			end
		end,
	};
	
	PetBuddyFrameButton_Initialize(self, "custom", actionData);
end

function PetBuddyLoadoutsToggleButton_OnLoad(self)
	local actionData = {
		iconTexture = "Interface\\AddOns\\BetterPetBuddy\\Media\\ToggleButtonIconDown",
		tooltipTitle = "Toggle Loadout List",
		tooltipDescription = "Show/hide the list of existing loadouts",
		func = function(self)
			local showstate = not PetBuddyFrameLoadoutsScrollFrame:IsShown();
			PetBuddyFrameLoadoutsScrollFrame_ToggleVisibility(showstate);
		end,
	};
	
	PetBuddyFrameButton_Initialize(self, "custom", actionData);
end

function PetBuddyFrameLoadoutsScrollFrame_ToggleVisibility(showstate)
	PetBuddyFrameLoadoutsScrollFrame:SetShown(showstate);
	
	local button = PetBuddyFrameLoadouts.toggleButton;
	
	if(showstate) then
		PetBuddyFrameLoadouts_UpdateList();
		HybridScrollFrame_SetOffset(PetBuddyFrameLoadouts.scrollFrame, 0);
		button.icon:SetTexture("Interface\\AddOns\\BetterPetBuddy\\Media\\ToggleButtonIconUp");
	else
		button.icon:SetTexture("Interface\\AddOns\\BetterPetBuddy\\Media\\ToggleButtonIconDown");
	end
end

function PetBuddyFrameLoadouts_OpenContextMenu(relativeFrame)
	if(not relativeFrame) then return end
	
	if(not PetBuddyFrameLoadouts.ContextMenu) then
		PetBuddyFrameLoadouts.ContextMenu = CreateFrame("Frame", "PetBuddyLoadoutsContextMenuFrame", PetBuddyFrame, "UIDropDownMenuTemplate");
	end
	
	local data = relativeFrame.data;
	
	local contextMenuData = {
		{
			text = data.name, isTitle = true, notCheckable = true,
		},
		{
			text = data.isRematch and "Load (Rematch)" or "Restore",
			func = function()
				StaticPopup_Show("PETBUDDY_LOADOUT_RESTORE", data.name, nil, data);
			end,
			notCheckable = true,
		},
		{
			text = "Rename",
			func = function()
				StaticPopup_Show("PETBUDDY_LOADOUT_RENAME", data.name, nil, data.name);
			end,
			notCheckable = true,
		},
		{
			text = "Overwrite",
			func = function()
				StaticPopup_Show("PETBUDDY_LOADOUT_OVERWRITE", data.name, nil, data.name);
			end,
			notCheckable = true,
		},
		{
			text = "Delete",
			func = function()
				StaticPopup_Show("PETBUDDY_LOADOUT_DELETE", data.name, nil, data.name);
			end,
			notCheckable = true,
		},
	};

	if(data.isRematch) then
		contextMenuData[3].disabled = true;
		contextMenuData[4].disabled = true;
		contextMenuData[5].disabled = true;
		tinsert(contextMenuData, {
			text = "Open Rematch",
			func = function()
				if(Rematch and Rematch.frame and type(Rematch.frame.Toggle) == "function") then
					Rematch.frame:Toggle();
				end
			end,
			notCheckable = true,
		});
	end
	
	if(relativeFrame.hasMissingPet) then
		contextMenuData[2].disabled = true;
	end
	
	PetBuddyFrameLoadouts.ContextMenu:SetPoint("TOPLEFT", relativeFrame, "CENTER", 0, 5);
	EasyMenu(contextMenuData, PetBuddyFrameLoadouts.ContextMenu, "cursor", 0, 0, "MENU", 5);
end

