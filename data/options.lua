--[[
	Pet Buddy by Sonaza
	Battle Pet management addon
	
	All rights reserved
	Questions can be sent to temu92@gmail.com
--]]

local ADDON_NAME, addon = ...;
local E = addon.E;
local DEFAULT_FONT_NAME = "DorisPP";
local DEFAULT_FONT_PATH = [[Interface\AddOns\PetBuddy2\media\DORISPP.ttf]];
local DEFAULT_STATUSBAR_NAME = "RenAscensionL";
local DEFAULT_STATUSBAR_PATH = [[Interface\AddOns\PetBuddy2\media\RenAscensionL.tga]];

addon.Media = addon.Media or {
	font = {},
	statusbar = {},
	defaults = {
		font = DEFAULT_FONT_NAME,
		statusbar = DEFAULT_STATUSBAR_NAME,
	},
};

local function EnsureTable(tbl, key)
	if(type(tbl[key]) ~= "table") then
		tbl[key] = {};
	end
	return tbl[key];
end

local function CopyDefaults(dst, src)
	for key, value in pairs(src) do
		if(type(value) == "table") then
			if(type(dst[key]) ~= "table") then
				dst[key] = {};
			end
			CopyDefaults(dst[key], value);
		elseif(dst[key] == nil) then
			dst[key] = value;
		end
	end
end

local function GetCharacterKey()
	local characterName = UnitName("player") or "Unknown";
	local realmName = GetRealmName() or "Unknown";
	return characterName .. " - " .. realmName;
end

function addon:RegisterMedia(mediaType, name, path)
	local mediaTable = self.Media and self.Media[string.lower(mediaType or "")];
	if(not mediaTable or type(name) ~= "string" or type(path) ~= "string") then
		return;
	end

	mediaTable[name] = path;
end

function addon:HasMedia(mediaType, name)
	local mediaTable = self.Media and self.Media[string.lower(mediaType or "")];
	return type(mediaTable) == "table" and mediaTable[name] ~= nil;
end

function addon:FetchMedia(mediaType, name)
	local mediaKey = string.lower(mediaType or "");
	local mediaTable = self.Media and self.Media[mediaKey];
	if(type(mediaTable) ~= "table") then
		return nil;
	end

	if(type(name) == "string" and mediaTable[name]) then
		return mediaTable[name];
	end

	local defaultName = self.Media.defaults and self.Media.defaults[mediaKey];
	if(type(defaultName) == "string" and mediaTable[defaultName]) then
		return mediaTable[defaultName];
	end

	for _, path in pairs(mediaTable) do
		return path;
	end

	return nil;
end

function addon:ListMedia(mediaType)
	local mediaTable = self.Media and self.Media[string.lower(mediaType or "")];
	if(type(mediaTable) ~= "table") then
		return {};
	end

	local list = {};
	for name in pairs(mediaTable) do
		tinsert(list, name);
	end
	table.sort(list);
	return list;
end

local function ImportExternalSharedMedia()
	local libStubObject = rawget(_G, "LibStub");
	if(type(libStubObject) ~= "table" or type(libStubObject.GetLibrary) ~= "function") then
		return;
	end

	local ok, externalLSM = pcall(libStubObject.GetLibrary, libStubObject, "LibSharedMedia-3.0", true);
	if(not ok or not externalLSM) then
		return;
	end

	for _, mediaType in ipairs({ "font", "statusbar" }) do
		local mediaList = externalLSM:List(mediaType) or {};
		for _, mediaName in ipairs(mediaList) do
			local mediaPath = externalLSM:Fetch(mediaType, mediaName, true) or externalLSM:Fetch(mediaType, mediaName);
			if(type(mediaPath) == "string" and mediaPath ~= "") then
				addon:RegisterMedia(mediaType, mediaName, mediaPath);
			end
		end
	end
end

addon:RegisterMedia("font", DEFAULT_FONT_NAME, DEFAULT_FONT_PATH);
addon:RegisterMedia("font", "Friz Quadrata", STANDARD_TEXT_FONT or DEFAULT_FONT_PATH);
addon:RegisterMedia("statusbar", DEFAULT_STATUSBAR_NAME, DEFAULT_STATUSBAR_PATH);
addon:RegisterMedia("statusbar", "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar");
ImportExternalSharedMedia();

E.VISIBILITY_MODE = {
	DO_NOTHING 	= 0x1,
	SHOW 		= 0x2,
	HIDE 		= 0x3,
};

E.AUTO_SUMMON_MODE = {
	LAST_PET	= 0x1,
	FAVORITE	= 0x2,
	ANY			= 0x3,	
};

function addon:InitializeDatabase()
	local defaults = {
		char = {
			AutoSummonLastPetID = nil,
		},
		
		global = {
			Visible = true,
			Position = {
				Point = "CENTER",
				RelativePoint = "CENTER",
				x = 0,
				y = 0,
			},
			
			fontSize = 10,
			fontFace = "DorisPP",
			barTexture = "RenAscensionL",
			
			SavedLoadouts = {},
			
			WindowScale = 1.0,
			
			IsFrameLocked = false,
			
			PetBattleVisiblityMode = E.VISIBILITY_MODE.SHOW,
			
			HideInCombat = true,
			
			ShowPetTooltips = true,
			ShowPetCharms = true,
			
			PetStatsText = {
				Enabled = true,
				ShowHealthPercentage = false,
				ShowExperiencePercentage = true,
				RemainingExperience = true,
			},			
			
			PetUtilityMenuState = 1,
			
			ShowPepe = true,
			ShowWelcomeMessage = true,
			
			ShowPetItems = true,
			ShowPetLoadouts = false,
			PetItemCategories = {
				heal_spell = true,
				battle_bandage = true,
				battle_stones = false,
				pet_consumables = false,
				pet_rewards = false,
				pet_currencies = false,
			},
			
			AutoHealPets = true,
			AutoHealPetsFee = true,
			
			AutoSummonPet = true,
			AutoSummonMode = E.AUTO_SUMMON_MODE.LAST_PET,
			
			Broker = {
				ShowWoundedPets = true,
				ShowPetCharms = true,	
			},
		}
	};
	
	PetBuddyDB = type(PetBuddyDB) == "table" and PetBuddyDB or {};
	local saved = PetBuddyDB;

	local globalData = EnsureTable(saved, "global");
	local charRoot = EnsureTable(saved, "char");
	local charKey = GetCharacterKey();
	if(type(charRoot[charKey]) ~= "table") then
		charRoot[charKey] = {};
	end

	CopyDefaults(globalData, defaults.global);
	CopyDefaults(charRoot[charKey], defaults.char);

	self.db = {
		global = globalData,
		char = charRoot[charKey],
		_saved = saved,
	};

	if(type(addon.InitializePetItemCategoryDefaults) == "function") then
		addon:InitializePetItemCategoryDefaults();
	end

	addon:RestoreSavedSettings();
end

function PetBuddyFrame_SavePosition()
	if(not addon.db) then return end
	
	local point, _, relativePoint, x, y = PetBuddyFrame:GetPoint()
	addon.db.global.Position = {
		Point = point,
		RelativePoint = relativePoint,
		x = x,
		y = y,
	};
end

function addon:RestoreSavedSettings()
	if(InCombatLockdown()) then return end
	
	addon:UpdateUtilityMenuState();
	
	PetBuddyFrameTitlePetCharms:SetShown(self.db.global.ShowPetCharms);
	
	for i=1,3 do
		local petFrame = _G['PetBuddyFramePet'..i];
		petFrame.stats.petHealth.text:SetShown(self.db.global.PetStatsText.Enabled);
		petFrame.stats.petExperience.text:SetShown(self.db.global.PetStatsText.Enabled);
	end
	
	addon:RefreshMedia();
	
	if(self.db.global.ShowPepe) then
		PetBuddyFrameTitle.pepeFrame:Show();
	else
		PetBuddyFrameTitle.pepeFrame:Hide();
	end
	
	local position = self.db.global.Position;
	PetBuddyFrame:SetPoint(position.Point, UIParent, position.RelativePoint, position.x, position.y);
	
	if(self.db.global.Visible) then
		PetBuddyFrame:Show();
	else
		PetBuddyFrame:Hide();
	end
	
	addon:SetWindowScale(self.db.global.WindowScale);
end

function addon:RefreshMedia(font, barTexture)
	local selectedFont = font or self.db.global.fontFace;
	local selectedBarTexture = barTexture or self.db.global.barTexture;

	if(not addon:HasMedia("font", selectedFont)) then
		selectedFont = DEFAULT_FONT_NAME;
		self.db.global.fontFace = selectedFont;
	end
	if(not addon:HasMedia("statusbar", selectedBarTexture)) then
		selectedBarTexture = DEFAULT_STATUSBAR_NAME;
		self.db.global.barTexture = selectedBarTexture;
	end

	local fontPath = addon:FetchMedia("font", selectedFont);
	local statusBarPath = addon:FetchMedia("statusbar", selectedBarTexture);
	
	local fontSize = self.db.global.fontSize;
	
	PetBuddyFontTitle:SetFont(fontPath, fontSize + 2, "OUTLINE");
	PetBuddyFontNormal:SetFont(fontPath, fontSize, "OUTLINE");
	PetBuddyFontSmall:SetFont(fontPath, math.max(8, fontSize - 1), "OUTLINE");
	
	for i=1,3 do
		local petFrame = _G['PetBuddyFramePet'..i];
		
		petFrame.stats.petHealth:SetStatusBarTexture(statusBarPath);
		petFrame.stats.petExperience:SetStatusBarTexture(statusBarPath);
	end
end

function addon:SetWindowScale(scale)
	self.db.global.WindowScale = scale or 1.0;
	PetBuddyFrame:SetScale(self.db.global.WindowScale);
end

function addon:GetWindowScaleMenu()
	local windowScales = { 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, };
	local menu = {};
	
	for index, scale in ipairs(windowScales) do
		tinsert(menu, {
			text = string.format("%d%%", scale * 100),
			func = function() addon:SetWindowScale(scale); end,
			checked = function() return self.db.global.WindowScale == scale end,
		});
	end
	
	return menu;
end

local function NormalizeUtilityMenuState(state)
	state = tonumber(state) or 0;
	state = math.floor(state);
	if(state < 0 or state > 3) then
		state = 0;
	end
	return state;
end

function addon:GetPetItemsUtilityMenuData()
	if(type(addon.GetPetItemCategoryMenuData) == "function") then
		return addon:GetPetItemCategoryMenuData(false);
	end
	return {};
end

function addon:GetPrimaryMenuData()
	local sharedMediaFonts = {};
	for index, font in ipairs(addon:ListMedia("font")) do
		tinsert(sharedMediaFonts, {
			text = font,
			func = function()
				self.db.global.fontFace = font;
				addon:RefreshMedia();
			end,
			checked = function() return self.db.global.fontFace == font; end,
		});
	end
	
	local fontSizes = {};
	for size = 8, 16 do
		tinsert(fontSizes, {
			text = tostring(size),
			func = function() self.db.global.fontSize = size; addon:RefreshMedia(); end,
			checked = function() return self.db.global.fontSize == size; end,
		});
	end
	
	local sharedMediaBarTextures = {};
	for index, statusbar in ipairs(addon:ListMedia("statusbar")) do
		tinsert(sharedMediaBarTextures, {
			text = statusbar,
			func = function() self.db.global.barTexture = statusbar; addon:RefreshMedia(); end,
			checked = function() return self.db.global.barTexture == statusbar; end,
		});
	end
	
	local data = {
		{
			text = "PetBuddy2 Options", isTitle = true, notCheckable = true,
		},
		{
			text = "Lock PetBuddy2",
			func = function() self.db.global.IsFrameLocked = not self.db.global.IsFrameLocked; end,
			checked = function() return self.db.global.IsFrameLocked; end,
			isNotRadio = true,
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Toggle Displays", isTitle = true, notCheckable = true,
		},
		{
			text = "Show pet tooltips",
			func = function() self.db.global.ShowPetTooltips = not self.db.global.ShowPetTooltips; end,
			checked = function() return self.db.global.ShowPetTooltips; end,
			isNotRadio = true,
		},
		{
			text = "Show pet charms",
			func = function() self.db.global.ShowPetCharms = not self.db.global.ShowPetCharms; addon:RestoreSavedSettings() end,
			checked = function() return self.db.global.ShowPetCharms; end,
			isNotRadio = true,
		},
		{
			text = "Show pet health and experience text",
			func = function() self.db.global.PetStatsText.Enabled = not self.db.global.PetStatsText.Enabled; addon:RestoreSavedSettings() end,
			checked = function() return self.db.global.PetStatsText.Enabled; end,
			isNotRadio = true,
			hasArrow = true,
			menuList = {
				{
					text = "Health Text", notCheckable = true, isTitle = true,
				},
				{
					text = "Show percentage",
					func = function() self.db.global.PetStatsText.ShowHealthPercentage = not self.db.global.PetStatsText.ShowHealthPercentage; addon:UpdatePets() end,
					checked = function() return self.db.global.PetStatsText.ShowHealthPercentage; end,
					isNotRadio = true,
				},
				{
					text = "", isTitle = true, notCheckable = true, disabled = true,
				},
				{
					text = "Experience Text", notCheckable = true, isTitle = true,
				},
				{
					text = "Show percentage",
					func = function() self.db.global.PetStatsText.ShowExperiencePercentage = not self.db.global.PetStatsText.ShowExperiencePercentage; addon:UpdatePets() end,
					checked = function() return self.db.global.PetStatsText.ShowExperiencePercentage; end,
					isNotRadio = true,
				},
				{
					text = "Display current experience",
					func = function() self.db.global.PetStatsText.RemainingExperience = false; addon:UpdatePets() end,
					checked = function() return not self.db.global.PetStatsText.RemainingExperience; end,
				},
				{
					text = "Display experience to level",
					func = function() self.db.global.PetStatsText.RemainingExperience = true; addon:UpdatePets() end,
					checked = function() return self.db.global.PetStatsText.RemainingExperience; end,
				},
			},
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Automation", isTitle = true, notCheckable = true,
		},
		{
			text = "Always resummon companion",
			func = function()
				self.db.global.AutoSummonPet = not self.db.global.AutoSummonPet;
				addon:UpdateDatabrokerText();
				if(self.db.global.AutoSummonPet) then
					addon:UpdateAutoResummon(true);
				end
			end,
			checked = function() return self.db.global.AutoSummonPet; end,
			isNotRadio = true,
			hasArrow = true,
			menuList = {
				{
					text = "Resummon Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Last used pet",
					func = function() self.db.global.AutoSummonMode = E.AUTO_SUMMON_MODE.LAST_PET; addon:UpdateAutoResummon(true); end,
					checked = function() return self.db.global.AutoSummonMode == E.AUTO_SUMMON_MODE.LAST_PET; end,
				},
				{
					text = "Random favorite pet",
					func = function() self.db.global.AutoSummonMode = E.AUTO_SUMMON_MODE.FAVORITE; addon:UpdateAutoResummon(true); end,
					checked = function() return self.db.global.AutoSummonMode == E.AUTO_SUMMON_MODE.FAVORITE; end,
				},
				{
					text = "Any random pet",
					func = function() self.db.global.AutoSummonMode = E.AUTO_SUMMON_MODE.ANY; addon:UpdateAutoResummon(true); end,
					checked = function() return self.db.global.AutoSummonMode == E.AUTO_SUMMON_MODE.ANY; end,
				},
			},
		},
		{
			text = "Automatically heal pets at stables",
			func = function() self.db.global.AutoHealPets = not self.db.global.AutoHealPets; AutoHealButton_OnShow(PetBuddyAutoHealButton) end,
			checked = function() return self.db.global.AutoHealPets; end,
			isNotRadio = true,
			hasArrow = true,
			menuList = {
				{
					text = "Auto Pet Healer", isTitle = true, notCheckable = true,
				},
				{
					text = "Also automatically accept the healing fee",
					func = function() self.db.global.AutoHealPetsFee = not self.db.global.AutoHealPetsFee; end,
					checked = function() return self.db.global.AutoHealPetsFee; end,
					isNotRadio = true,
				},
			}
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Visibility Options", isTitle = true, notCheckable = true,
		},
		{
			text = "When starting pet battle",
			notCheckable = true,
			hasArrow = true,
			menuList = {
				{
					text = "Show",
					func = function() self.db.global.PetBattleVisiblityMode = E.VISIBILITY_MODE.SHOW; end,
					checked = function() return self.db.global.PetBattleVisiblityMode == E.VISIBILITY_MODE.SHOW; end,
				},
				{
					text = "Hide",
					func = function() self.db.global.PetBattleVisiblityMode = E.VISIBILITY_MODE.HIDE; end,
					checked = function() return self.db.global.PetBattleVisiblityMode == E.VISIBILITY_MODE.HIDE; end,
				},
				{
					text = "Do nothing",
					func = function() self.db.global.PetBattleVisiblityMode = E.VISIBILITY_MODE.DO_NOTHING; end,
					checked = function() return self.db.global.PetBattleVisiblityMode == E.VISIBILITY_MODE.DO_NOTHING; end,
				},
			},
		},
		{
			text = "Hide when entering combat",
			func = function() self.db.global.HideInCombat = not self.db.global.HideInCombat; end,
			checked = function() return self.db.global.HideInCombat; end,
			isNotRadio = true,
		},
		{
			text = "Enable cuteness",
			func = function()
				self.db.global.ShowPepe = not self.db.global.ShowPepe;
				if(self.db.global.ShowPepe) then
					PetBuddyFrameTitle.pepeFrame:Show();
				else
					PetBuddyFrameTitle.pepeFrame:Hide();
				end
			end,
			checked = function() return self.db.global.ShowPepe; end,
			isNotRadio = true,
		},
		{
			text = "Show welcome message on login",
			func = function()
				self.db.global.ShowWelcomeMessage = not self.db.global.ShowWelcomeMessage;
			end,
			checked = function() return self.db.global.ShowWelcomeMessage; end,
			isNotRadio = true,
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Pet Utility", isTitle = true, notCheckable = true,
		},
		{
			text = "Show pet related items",
			func = function()
				local state = NormalizeUtilityMenuState(self.db.global.PetUtilityMenuState);
				local hasItems = (state == 1 or state == 3);
				if(hasItems) then state = state - 1; else state = state + 1; end
				self.db.global.PetUtilityMenuState = state;
				addon:RestoreSavedSettings();
			end,
			checked = function()
				local state = NormalizeUtilityMenuState(self.db.global.PetUtilityMenuState);
				return state == 1 or state == 3;
			end,
			isNotRadio = true,
			hasArrow = true,
			menuList = addon:GetPetItemsUtilityMenuData(),
			disabled = C_PetBattles.IsInBattle(),
			keepShownOnClick = true,
		},
		{
			text = "Show pet loadouts menu",
			func = function()
				local state = tonumber(self.db.global.PetUtilityMenuState) or 0;
				state = math.floor(state);
				if(state < 0 or state > 3) then state = 0; end
				local hasLoadouts = (state == 2 or state == 3);
				if(hasLoadouts) then state = state - 2; else state = state + 2; end
				self.db.global.PetUtilityMenuState = state;
				addon:RestoreSavedSettings();
			end,
			checked = function()
				local state = tonumber(self.db.global.PetUtilityMenuState) or 0;
				return state == 2 or state == 3;
			end,
			disabled = C_PetBattles.IsInBattle(),
			isNotRadio = true,
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Frame Options", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = string.format("Change scale (%d%%)", self.db.global.WindowScale * 100),
			notCheckable = true,
			hasArrow = true,
			menuList = addon:GetWindowScaleMenu(),
		},
		{
			text = "Font face",
			notCheckable = true,
			hasArrow = true,
			menuList = sharedMediaFonts,
		},
		{
			text = "Font size",
			notCheckable = true,
			hasArrow = true,
			menuList = fontSizes,
		},
		{
			text = "Bar texture",
			notCheckable = true,
			hasArrow = true,
			menuList = sharedMediaBarTextures,
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Other Options", isTitle = true, notCheckable = true,
		},
	};
	
	if(PetBuddyFrame:IsShown()) then
		tinsert(data, {
			text = "Hide PetBuddy2",
			func = function()
				PetBuddyFrame:Hide(); CloseMenus();
			end,
			notCheckable = true,
		});
	else
		tinsert(data, {
			text = "Show PetBuddy2",
			func = function()
				PetBuddyFrame:Show(); CloseMenus();
			end,
			notCheckable = true,
		});
	end
	
	return data;
end

function addon:OpenContextMenu(contextMenuData, parentframe, anchor, point, relativePoint)
	
	if(not addon.ContextMenu) then
		addon.ContextMenu = CreateFrame("Frame", "PetBuddyContextMenuFrame", UIParent, "UIDropDownMenuTemplate");
		addon.ContextMenu:SetFrameStrata("DIALOG");
	end
	
	if(not contextMenuData) then
		contextMenuData = addon:GetPrimaryMenuData();
	end
	
	addon.ContextMenu:ClearAllPoints();
	addon.ContextMenu:SetPoint(point or "TOPLEFT", parentframe or PetBuddyFrame, relativePoint or "CENTER", 0, 5);
	addon:OpenDropDownMenu(contextMenuData, addon.ContextMenu, anchor or "cursor", 0, 0, "MENU", 5);
end

local function TryLoadDropDownAPI()
	if(type(EasyMenu) == "function") then
		return true;
	end

	local loadAddon = nil;
	if(C_AddOns and type(C_AddOns.LoadAddOn) == "function") then
		loadAddon = C_AddOns.LoadAddOn;
	elseif(type(LoadAddOn) == "function") then
		loadAddon = LoadAddOn;
	end

	if(loadAddon) then
		pcall(loadAddon, "Blizzard_UIDropDownMenu");
		pcall(loadAddon, "Blizzard_Deprecated");
	end

	return type(EasyMenu) == "function";
end

local function ApplyMenuKeepShown(menuData)
	if(type(menuData) ~= "table") then
		return;
	end

	for _, info in ipairs(menuData) do
		if(type(info) == "table") then
			if(type(info.menuList) == "table") then
				ApplyMenuKeepShown(info.menuList);
			end

			if(info.keepShownOnClick == nil) then
				local isToggleEntry = (info.isNotRadio == true) or (type(info.checked) == "function");
				local isClickableEntry = (type(info.func) == "function") and not info.isTitle and not info.disabled and not info.hasArrow;
				if(isToggleEntry and isClickableEntry) then
					info.keepShownOnClick = true;
				end
			end
		end
	end
end

function addon:OpenDropDownMenu(menuData, menuFrame, anchor, x, y, displayMode, autoHideDelay)
	if(type(menuData) ~= "table" or not menuFrame) then
		return false;
	end

	ApplyMenuKeepShown(menuData);

	if(type(EasyMenu) == "function" or TryLoadDropDownAPI()) then
		EasyMenu(menuData, menuFrame, anchor or "cursor", x or 0, y or 0, displayMode or "MENU", autoHideDelay or 5);
		return true;
	end

	if(type(UIDropDownMenu_Initialize) == "function" and type(UIDropDownMenu_AddButton) == "function" and type(ToggleDropDownMenu) == "function") then
		UIDropDownMenu_Initialize(menuFrame, function(_, level, list)
			level = level or 1;
			local currentList = list;
			if(type(currentList) ~= "table") then
				currentList = menuData;
			end

			for _, info in ipairs(currentList) do
				UIDropDownMenu_AddButton(info, level);
			end
		end, displayMode or "MENU");
		ToggleDropDownMenu(1, nil, menuFrame, anchor or "cursor", x or 0, y or 0, menuData, nil, autoHideDelay or 5);
		return true;
	end

	if(type(addon.PrintMessage) == "function") then
		addon:PrintMessage("|cffff5555Dropdown menu API unavailable on this client.|r");
	end
	return false;
end


