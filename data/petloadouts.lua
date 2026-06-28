--[[
	Pet Buddy by Sonaza
	Battle Pet management addon
	
	All rights reserved
	Questions can be sent to temu92@gmail.com
--]]

local ADDON_NAME, addon = ...;

local BattlePetUtility_LOADOUT_TEXT = "Enter a name for current pet loadout:|n|n%s";
local CURRENT_LOADOUT_NAME = nil;
local unpackFunc = unpack or table.unpack;

local function GetSafeRarityColor(rarity)
	local normalized = tonumber(rarity) or 1;
	if(normalized < 1) then
		normalized = 1;
	end

	return ITEM_QUALITY_COLORS[normalized - 1] or ITEM_QUALITY_COLORS[1] or NORMAL_FONT_COLOR;
end

local function TrimInput(text)
	text = tostring(text or "");

	if(type(strtrim) == "function") then
		return strtrim(text);
	end

	if(type(string.trim) == "function") then
		return string.trim(text);
	end

	return (text:gsub("^%s+", ""):gsub("%s+$", ""));
end

local function GetPopupEditBox(frame)
	if(type(frame) ~= "table") then
		return nil;
	end

	if(frame.EditBox) then
		return frame.EditBox;
	end

	if(frame.editBox) then
		return frame.editBox;
	end

	if(type(frame.GetParent) == "function") then
		local parent = frame:GetParent();
		if(type(parent) == "table") then
			return parent.EditBox or parent.editBox;
		end
	end

	return nil;
end

local function EnsureSavedLoadoutsTable()
	if(not addon.db or not addon.db.global) then
		return nil;
	end

	if(type(addon.db.global.SavedLoadouts) ~= "table") then
		addon.db.global.SavedLoadouts = {};
	end

	return addon.db.global.SavedLoadouts;
end

local function RefreshLoadoutUI(keepListOpen)
	if(type(BattlePetUtilityFrameLoadouts_UpdateList) == "function") then
		BattlePetUtilityFrameLoadouts_UpdateList();
	end

	if(type(addon.UpdateUtilityMenuState) == "function") then
		addon:UpdateUtilityMenuState();
	end

	if(type(addon.UpdatePets) == "function") then
		addon:UpdatePets();
	end

	if(type(addon.RefreshZoneTracker) == "function") then
		addon:RefreshZoneTracker();
	end

	if(not keepListOpen and type(BattlePetUtilityFrameLoadoutsScrollFrame_ToggleVisibility) == "function") then
		BattlePetUtilityFrameLoadoutsScrollFrame_ToggleVisibility(false);
	end
end

StaticPopupDialogs["BattlePetUtility_LOADOUT_ERROR_LOCKED"] = {
	text = "Cannot save loadout: all pet battle slots are not unlocked.",
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["BattlePetUtility_LOADOUT_ERROR_NOT_FOUND"] = {
	text = "Cannot restore loadout: all saved pets cannot be found.",
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["BattlePetUtility_LOADOUT_SAVE_EXISTS"] = {
	text = "Another loadout with the same name already exists. Do you want to overwrite?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		local data = self.data;
		if(data.newSave) then
			addon:DeleteLoadout(data.name);
			addon:SaveLoadout(data.name);
		else
			if(data.oldName == data.name) then
				return;
			end
			addon:DeleteLoadout(data.name);
			addon:RenameLoadout(data.oldName, data.name);
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["BattlePetUtility_LOADOUT_OVERWRITE"] = {
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

StaticPopupDialogs["BattlePetUtility_LOADOUT_RESTORE"] = {
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

StaticPopupDialogs["BattlePetUtility_LOADOUT_DELETE"] = {
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

StaticPopupDialogs["BattlePetUtility_LOADOUT_REMATCH_MANAGED"] = {
	text = "Loadouts are managed by Rematch while it is enabled. Create, rename, and delete teams in Rematch.",
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};
	
StaticPopupDialogs["BattlePetUtility_LOADOUT_SAVE"] = {
	text = "Enter a name for current pet loadout:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 38,
	OnAccept = function(self)
		local editBox = GetPopupEditBox(self);
		local name = TrimInput(editBox and editBox:GetText() or "");
		addon:SaveLoadout(name);
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = type(self.GetParent) == "function" and self:GetParent() or nil;
		local editBox = GetPopupEditBox(self);
		local name = TrimInput(editBox and editBox:GetText() or "");
		addon:SaveLoadout(name);
		if(parent and type(parent.Hide) == "function") then
			parent:Hide();
		end
	end,
	OnShow = function(self)
		local editBox = GetPopupEditBox(self);
		if(editBox) then
			editBox:SetFocus();
		end
	end,
	OnHide = function(self)
		if(type(ChatEdit_FocusActiveWindow) == "function") then
			ChatEdit_FocusActiveWindow();
		end
		local editBox = GetPopupEditBox(self);
		if(editBox) then
			editBox:SetText("");
		end
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
				tinsert(loadoutData, data);
			end
		end
	end

	table.sort(loadoutData, function(a, b)
		return string.lower(a.name or "") < string.lower(b.name or "");
	end);

	return loadoutData, #loadoutData;
end
	
StaticPopupDialogs["BattlePetUtility_LOADOUT_RENAME"] = {
	text = "Enter a new name for the loadout:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 38,
	OnAccept = function(self)
		local editBox = GetPopupEditBox(self);
		local new_name = TrimInput(editBox and editBox:GetText() or "");
		addon:RenameLoadout(self.data, new_name);
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = type(self.GetParent) == "function" and self:GetParent() or nil;
		local editBox = GetPopupEditBox(self);
		local new_name = TrimInput(editBox and editBox:GetText() or "");
		addon:RenameLoadout(parent and parent.data or nil, new_name);
		if(parent and type(parent.Hide) == "function") then
			parent:Hide();
		end
	end,
	OnShow = function(self)
		local editBox = GetPopupEditBox(self);
		if(editBox) then
			editBox:SetText(self.data or "");
			editBox:SetFocus();
		end
	end,
	OnHide = function(self)
		if(type(ChatEdit_FocusActiveWindow) == "function") then
			ChatEdit_FocusActiveWindow();
		end
		local editBox = GetPopupEditBox(self);
		if(editBox) then
			editBox:SetText("");
		end
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
			ability1, ability2, ability3 = unpackFunc(saved_loadout[slotIndex].abilities);
			locked = false;
		elseif(saved_loadout[slotIndex] and saved_loadout[slotIndex].abilities) then
			ability1, ability2, ability3 = unpackFunc(saved_loadout[slotIndex].abilities);
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
	loadout_name = TrimInput(loadout_name);
	if(loadout_name == "") then return false end

	local savedLoadouts = EnsureSavedLoadoutsTable();
	if(not savedLoadouts) then return false end
	
	if(savedLoadouts[loadout_name]) then
		StaticPopup_Show("BattlePetUtility_LOADOUT_SAVE_EXISTS", loadout_name, nil, {
			newSave = true,
			name = loadout_name,
		});
		return false;
	end
	
	local currentLoadout = {};
	
	for slotIndex = 1, 3 do
		local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slotIndex);
		if(locked) then
			StaticPopup_Show("BattlePetUtility_LOADOUT_ERROR_LOCKED");
			return false;
		end
		
		tinsert(currentLoadout, {
			petID = petID,
			abilities = { ability1, ability2, ability3 },
		});
	end
	
	savedLoadouts[loadout_name] = currentLoadout;
	RefreshLoadoutUI(true);
	CloseMenus();
	return true;
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
		BattlePetUtilityPetFrame_ResetAbilitySwitches();
		BattlePetUtilityFrameLoadoutsScrollFrame_ToggleVisibility(false);
		CloseMenus();
		return true;
	end

	if(not loadout_name or loadout_name == "") then return false end

	local loadout = self.db.global.SavedLoadouts[loadout_name];
	if(not loadout) then return false end
	
	for slotIndex, data in ipairs(loadout) do
		if(not C_PetJournal.GetPetInfoByPetID(data.petID)) then
			StaticPopup_Show("BattlePetUtility_LOADOUT_ERROR_NOT_FOUND");
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
	BattlePetUtilityPetFrame_ResetAbilitySwitches();
	RefreshLoadoutUI(false);
	-- Enforce known-good static layout so the team change doesn't leave a
	-- visual gap between the main GUI and the zone pet tracker.
	if(type(addon.UpdateMinimizeState) == "function") then
		addon:UpdateMinimizeState();
	end
	if(type(addon.RefreshZoneTracker) == "function") then
		addon._lastZoneTrackerRefresh = nil;
		addon:RefreshZoneTracker();
	end
	CloseMenus();
	return true;
end

function addon:RenameLoadout(old_loadout_name, new_loadout_name)
	if(not old_loadout_name or not new_loadout_name) then return false end
	old_loadout_name = TrimInput(old_loadout_name);
	new_loadout_name = TrimInput(new_loadout_name);
	if(new_loadout_name == "") then return false end
	if(old_loadout_name == "" or old_loadout_name == new_loadout_name) then return false end

	local savedLoadouts = EnsureSavedLoadoutsTable();
	if(not savedLoadouts or not savedLoadouts[old_loadout_name]) then return false end
	
	if(savedLoadouts[new_loadout_name]) then
		StaticPopup_Show("BattlePetUtility_LOADOUT_SAVE_EXISTS", new_loadout_name, nil, {
			newSave = false,
			name = new_loadout_name,
			oldName = old_loadout_name,
		});
		return false;
	end
	
	savedLoadouts[new_loadout_name] = savedLoadouts[old_loadout_name];
	savedLoadouts[old_loadout_name] = nil;
	
	RefreshLoadoutUI(true);
	CloseMenus();
	return true;
end

function addon:DeleteLoadout(loadout_name)
	if(not loadout_name) then return false end
	loadout_name = TrimInput(loadout_name);
	if(loadout_name == "") then return false end

	local savedLoadouts = EnsureSavedLoadoutsTable();
	if(not savedLoadouts) then return false end
	
	if(savedLoadouts[loadout_name]) then
		savedLoadouts[loadout_name] = nil;
	end
	
	RefreshLoadoutUI(true);
	CloseMenus();
	return true;
end

function addon:GetSortedLoadouts()
	local loadoutData = {};
	local savedLoadouts = EnsureSavedLoadoutsTable() or {};
	local seenNames = {};

	for loadout_name, pets in pairs(savedLoadouts) do
		local entry = {
			name = loadout_name,
			pets = pets,
		};
		tinsert(loadoutData, entry);
		seenNames[string.lower(loadout_name or "")] = true;
	end

	if(addon.IsRematchLoadoutsEnabled and addon:IsRematchLoadoutsEnabled()) then
		local rematchLoadouts = addon:GetRematchLoadouts();
		for _, loadout in ipairs(rematchLoadouts) do
			local normalizedName = string.lower(loadout.name or "");
			if(not seenNames[normalizedName]) then
				tinsert(loadoutData, loadout);
				seenNames[normalizedName] = true;
			end
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
			name = "No loadouts",
			pets = {},
			notFound = true,
		});
	end
	
	return loadoutData, #loadoutData;
end

function BattlePetUtilityFrameLoadouts_UpdateList()
	local scrollFrame = BattlePetUtilityFrameLoadouts.scrollFrame;
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
						local rarityColor = GetSafeRarityColor(rarity);
						
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
				
				button:SetScript("OnEnter", BattlePetUtilityLoadoutsButton_OnEnter);
				button:SetScript("OnLeave", BattlePetUtilityLoadoutsButton_OnLeave);
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

function BattlePetUtilityLoadoutsButton_OnClick(self, button)
	if(self.data.notFound) then return end
	
	if(button == "LeftButton") then
		if(self.data.isRematch or not self.hasMissingPet) then
			addon:RestoreLoadout(self.data);
		else
			StaticPopup_Show("BattlePetUtility_LOADOUT_DELETE", self.data.name, nil, self.data.name)
		end
	elseif(button == "RightButton") then
		BattlePetUtilityFrameLoadouts_OpenContextMenu(self)
	end
end

function BattlePetUtilityLoadoutsButton_OnEnter(self)
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

function BattlePetUtilityLoadoutsButton_OnLeave(self)
	GameTooltip:Hide();
end

function BattlePetUtilityFrameLoadouts_OnLoad(self)
	self.scrollFrame.update = BattlePetUtilityFrameLoadouts_UpdateList;
	-- self.scrollFrame.scrollBar.doNotHide = true;
	
	HybridScrollFrame_CreateButtons(self.scrollFrame, "BattlePetUtilityLoadoutsButtonTemplate", 0, 0, nil, nil, 0, 0);
end

function addon:OpenRematchSaveTeamDialog()
	if(type(Rematch) ~= "table" or not addon:IsRematchLoadoutsEnabled()) then
		return false;
	end

	-- Preferred path: use Rematch's existing Save As button behavior.
	local saveAsButton = Rematch.bottombar and Rematch.bottombar.SaveAsButton;
	if(saveAsButton and type(saveAsButton.OnClick) == "function") then
		local ok = pcall(saveAsButton.OnClick, saveAsButton);
		if(ok) then
			return true;
		end
	end

	-- Fallback path: invoke SaveTeam dialog directly.
	if(Rematch.saveDialog and type(Rematch.saveDialog.SidelineLoadouts) == "function") then
		pcall(Rematch.saveDialog.SidelineLoadouts, Rematch.saveDialog);
	end

	if(Rematch.dialog and type(Rematch.dialog.ShowDialog) == "function") then
		local saveMode = (Rematch.constants and Rematch.constants.SAVE_MODE_SAVEAS) or 2;
		local subject = { saveMode = saveMode };
		local currentTeamID = Rematch.settings and Rematch.settings.currentTeamID;

		if(Rematch.savedTeams and type(Rematch.savedTeams.IsUserTeam) == "function" and currentTeamID and Rematch.savedTeams:IsUserTeam(currentTeamID)) then
			subject.teamID = currentTeamID;
		end

		local ok = pcall(Rematch.dialog.ShowDialog, Rematch.dialog, "SaveTeam", subject);
		if(ok) then
			return true;
		end
	end

	return false;
end

function BattlePetUtilityLoadoutsSaveButton_OnLoad(self)
	local actionData = {
		iconTexture = "Interface\\AddOns\\BattlePetUtility\\media\\savebuttonicon",
		-- count = "S",
		tooltipTitle = "Save Loadout",
		tooltipDescription = "Save current pets and abilities to BattlePetUtility loadouts, or open Rematch Save Team when Rematch is available",
		func = function(self)
			if(addon:IsRematchLoadoutsEnabled()) then
				if(addon:OpenRematchSaveTeamDialog()) then
					return;
				end
			end
			StaticPopup_Show("BattlePetUtility_LOADOUT_SAVE");
		end,
	};
	
	BattlePetUtilityFrameButton_Initialize(self, "custom", actionData);
end

function BattlePetUtilityLoadoutsToggleButton_OnLoad(self)
	local actionData = {
		iconTexture = "Interface\\AddOns\\BattlePetUtility\\media\\togglebuttonicondown",
		tooltipTitle = "Toggle Loadout List",
		tooltipDescription = "Show/hide the list of existing loadouts",
		func = function(self)
			local showstate = not BattlePetUtilityFrameLoadoutsScrollFrame:IsShown();
			BattlePetUtilityFrameLoadoutsScrollFrame_ToggleVisibility(showstate);
		end,
	};
	
	BattlePetUtilityFrameButton_Initialize(self, "custom", actionData);
end

function BattlePetUtilityFrameLoadoutsScrollFrame_ToggleVisibility(showstate)
	local minimized = addon and addon:IsFrameMinimized();
	local hideMain = addon and addon.db and addon.db.global.HideMainGUI == true;
	if(minimized or hideMain) then
		showstate = false;
	end

	BattlePetUtilityFrameLoadoutsScrollFrame:SetShown(showstate);

	local button = BattlePetUtilityFrameLoadouts.toggleButton;
	if(button) then
		button:SetEnabled(not minimized and not hideMain);
		if(button.icon) then
			button.icon:SetDesaturated(minimized or hideMain);
		end
	end

	if(showstate) then
		BattlePetUtilityFrameLoadouts_UpdateList();
		HybridScrollFrame_SetOffset(BattlePetUtilityFrameLoadouts.scrollFrame, 0);
		if(button and button.icon) then
			button.icon:SetTexture("Interface\\AddOns\\BattlePetUtility\\media\\togglebuttoniconup");
		end
	else
		if(button and button.icon) then
			button.icon:SetTexture("Interface\\AddOns\\BattlePetUtility\\media\\togglebuttonicondown");
		end
	end
end

function BattlePetUtilityFrameLoadouts_OpenContextMenu(relativeFrame)
	if(not relativeFrame) then return end
	if(not relativeFrame.data or relativeFrame.data.notFound) then return end
	
	if(not BattlePetUtilityFrameLoadouts.ContextMenu) then
		BattlePetUtilityFrameLoadouts.ContextMenu = CreateFrame("Frame", "BattlePetUtilityLoadoutsContextMenuFrame", UIParent, "UIDropDownMenuTemplate");
		BattlePetUtilityFrameLoadouts.ContextMenu:SetFrameStrata("DIALOG");
	end
	
	local data = relativeFrame.data;
	
	local contextMenuData = {
		{
			text = data.name, isTitle = true, notCheckable = true,
		},
		{
			text = data.isRematch and "Load (Rematch)" or "Restore",
			func = function()
				addon:RestoreLoadout(data);
			end,
			notCheckable = true,
		},
		{
			text = "Rename",
			func = function()
				StaticPopup_Show("BattlePetUtility_LOADOUT_RENAME", data.name, nil, data.name);
			end,
			notCheckable = true,
		},
		{
			text = "Overwrite",
			func = function()
				StaticPopup_Show("BattlePetUtility_LOADOUT_OVERWRITE", data.name, nil, data.name);
			end,
			notCheckable = true,
		},
		{
			text = "Delete",
			func = function()
				StaticPopup_Show("BattlePetUtility_LOADOUT_DELETE", data.name, nil, data.name);
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

	BattlePetUtilityFrameLoadouts.ContextMenu:ClearAllPoints();
	BattlePetUtilityFrameLoadouts.ContextMenu:SetPoint("BOTTOMLEFT", relativeFrame, "TOPLEFT", 0, 0);
	addon:OpenDropDownMenu(contextMenuData, BattlePetUtilityFrameLoadouts.ContextMenu, "cursor", 0, 0, "MENU", 5);
end
