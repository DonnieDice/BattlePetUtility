--[[
	Pet Buddy by Sonaza
	Battle Pet management addon
	
	All rights reserved
	Questions can be sent to temu92@gmail.com
--]]

local ADDON_NAME, addon = ...;
local E = addon.E;
local DEFAULT_STATUSBAR_NAME = "RenAscensionL";
local DEFAULT_STATUSBAR_PATH = [[Interface\AddOns\PetBuddy2\media\renascensionl.tga]];

local function GetRGX()
	return rawget(_G, "RGXFramework");
end

local function GetRGXFonts()
	local rgx = GetRGX();
	return rgx and rgx:GetFonts();
end

local function GetRGXTextures()
	local rgx = GetRGX();
	return rgx and rgx:GetTextures();
end

local function GetDefaultFontName()
	local rgxFonts = GetRGXFonts();
	if(type(rgxFonts) == "table" and type(rgxFonts.GetDefault) == "function") then
		local defaultName = rgxFonts:GetDefault();
		if(type(defaultName) == "string" and defaultName ~= "") then
			return defaultName;
		end
	end

	return "FRIZQT";
end

addon.Media = addon.Media or {
	statusbar = {},
	defaults = {
		statusbar = DEFAULT_STATUSBAR_NAME,
	},
};

local function BuildDefaultTextStyle(size, flags, extras)
	local style = {
		font = GetDefaultFontName(),
		size = size,
		flags = flags or "",
	};

	if(type(extras) == "table") then
		for key, value in pairs(extras) do
			style[key] = value;
		end
	end

	local rgxFonts = GetRGXFonts();
	if(type(rgxFonts) == "table" and type(rgxFonts.CreateStyle) == "function") then
		return rgxFonts:CreateStyle(style);
	end

	return style;
end

local function EnsurePB2TextStyles(db)
	if(type(db) ~= "table") then
		return;
	end

	if(type(db.titleText) ~= "table" or type(db.normalText) ~= "table" or type(db.smallText) ~= "table") then
		local legacyFont = db.fontFace or GetDefaultFontName();
		local legacySize = tonumber(db.fontSize) or 10;

		db.titleText = BuildDefaultTextStyle(legacySize + 2, "OUTLINE", {
			font = legacyFont,
			shadowColor = "shadow",
			shadowOffset = { x = 1, y = -1 },
		});
		db.normalText = BuildDefaultTextStyle(legacySize, "", {
			font = legacyFont,
		});
		db.smallText = BuildDefaultTextStyle(math.max(8, legacySize - 1), "", {
			font = legacyFont,
		});
	end

	db.fontFace = nil;
	db.fontSize = nil;
end

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

	if(string.lower(mediaType or "") == "statusbar") then
		local rgxTextures = GetRGXTextures();
		if(type(rgxTextures) == "table" and type(rgxTextures.RegisterBar) == "function") then
			rgxTextures:RegisterBar(name, path);
		end
	end
end

function addon:HasMedia(mediaType, name)
	local mediaTable = self.Media and self.Media[string.lower(mediaType or "")];
	if(type(mediaTable) == "table" and mediaTable[name] ~= nil) then
		return true;
	end

	if(string.lower(mediaType or "") == "statusbar") then
		local rgxTextures = GetRGXTextures();
		return type(rgxTextures) == "table"
			and type(rgxTextures.bars) == "table"
			and rgxTextures.bars[name] ~= nil;
	end

	return false;
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

	if(mediaKey == "statusbar") then
		local rgxTextures = GetRGXTextures();
		if(type(name) == "string"
			and type(rgxTextures) == "table"
			and type(rgxTextures.bars) == "table"
			and rgxTextures.bars[name] ~= nil
			and type(rgxTextures.GetBar) == "function") then
			return rgxTextures:GetBar(name);
		end
	end

	local defaultName = self.Media.defaults and self.Media.defaults[mediaKey];
	if(type(defaultName) == "string" and mediaTable[defaultName]) then
		return mediaTable[defaultName];
	end

	if(mediaKey == "statusbar") then
		local rgxTextures = GetRGXTextures();
		if(type(defaultName) == "string"
			and type(rgxTextures) == "table"
			and type(rgxTextures.bars) == "table"
			and rgxTextures.bars[defaultName] ~= nil
			and type(rgxTextures.GetBar) == "function") then
			return rgxTextures:GetBar(defaultName);
		end
	end

	for _, path in pairs(mediaTable) do
		return path;
	end

	if(mediaKey == "statusbar") then
		local rgxTextures = GetRGXTextures();
		if(type(rgxTextures) == "table"
			and type(rgxTextures.ListBars) == "function"
			and type(rgxTextures.GetBar) == "function") then
			local bars = rgxTextures:ListBars();
			local first = bars and bars[1];
			if(type(first) == "string" and first ~= "") then
				return rgxTextures:GetBar(first);
			end
		end
	end

	return nil;
end

function addon:ListMedia(mediaType)
	local mediaTable = self.Media and self.Media[string.lower(mediaType or "")];
	if(type(mediaTable) ~= "table") then
		mediaTable = {};
	end

	local list, seen = {}, {};
	for name, path in pairs(mediaTable) do
		if(type(name) == "string" and name ~= "" and not seen[name]) then
			seen[name] = true;
			tinsert(list, name);
		end
	end

	if(string.lower(mediaType or "") == "statusbar") then
		local rgxTextures = GetRGXTextures();
		if(type(rgxTextures) == "table" and type(rgxTextures.ListBars) == "function") then
			for _, name in ipairs(rgxTextures:ListBars()) do
				if(type(name) == "string" and name ~= "" and not seen[name]) then
					seen[name] = true;
					tinsert(list, name);
				end
			end
		end
	end

	table.sort(list);
	return list;
end

local function ImportExternalStatusbars()
	local libStubObject = rawget(_G, "LibStub");
	if(type(libStubObject) ~= "table" or type(libStubObject.GetLibrary) ~= "function") then
		return;
	end

	local ok, externalLSM = pcall(libStubObject.GetLibrary, libStubObject, "LibSharedMedia-3.0", true);
	if(not ok or not externalLSM) then
		return;
	end

	local mediaType = "statusbar";
	local mediaList = externalLSM:List(mediaType) or {};
	for _, mediaName in ipairs(mediaList) do
		local mediaPath = externalLSM:Fetch(mediaType, mediaName, true) or externalLSM:Fetch(mediaType, mediaName);
		if(type(mediaPath) == "string" and mediaPath ~= "") then
			addon:RegisterMedia(mediaType, mediaName, mediaPath);
		end
	end
end

addon:RegisterMedia("statusbar", DEFAULT_STATUSBAR_NAME, DEFAULT_STATUSBAR_PATH);
addon:RegisterMedia("statusbar", "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar");
addon:RegisterMedia("statusbar", "Smooth", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill");
addon:RegisterMedia("statusbar", "Flat", "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar");
addon:RegisterMedia("statusbar", "Glamour", "Interface\\AddOns\\PetBuddy2\\media\\renascensionl.tga");
addon:RegisterMedia("statusbar", "Minimalist", "Interface\\Tooltips\\UI-Tooltip-Background");
addon:RegisterMedia("statusbar", "Perl", "Interface\\TargetingFrame\\UI-StatusBar");
addon:RegisterMedia("statusbar", "Smoother", "Interface\\AddOns\\PetBuddy2\\media\\backdrop.tga");
ImportExternalStatusbars();

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
			
			barTexture = "RenAscensionL",
			titleText = BuildDefaultTextStyle(12, "OUTLINE", {
				shadowColor = "shadow",
				shadowOffset = { x = 1, y = -1 },
			}),
			normalText = BuildDefaultTextStyle(10, ""),
			smallText = BuildDefaultTextStyle(9, ""),
			
			SavedLoadouts = {},
			
			WindowScale = 1.0,
			
			IsFrameLocked = false,
			IsMinimized = false,
			HideMainGUI = false,
			
			PetBattleVisiblityMode = E.VISIBILITY_MODE.SHOW,
			
			HideInCombat = true,
			
			ShowPetTooltips = true,
			ShowPetCharms = true,
			ShowZoneTracker = true,
			ShowZoneTrackerPetList = true,

			MinimapIcon = {
				enabled = true,
				angle = 215,
			},
			
			PetStatsText = {
				Enabled = true,
				ShowHealthPercentage = false,
				ShowExperiencePercentage = true,
				RemainingExperience = true,
			},			
			
			PetUtilityMenuState = 1,
			
			ShowPepe = true,
			PepeOnLeft = false,
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

	EnsurePB2TextStyles(self.db.global);

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

	addon:SyncUtilityMenuState();
	addon:UpdateUtilityMenuState();
	
	PetBuddyFrameTitlePetCharms:SetShown(self.db.global.ShowPetCharms);
	
	for i=1,3 do
		local petFrame = _G['PetBuddyFramePet'..i];
		petFrame.stats.petHealth.text:SetShown(self.db.global.PetStatsText.Enabled);
		petFrame.stats.petExperience.text:SetShown(self.db.global.PetStatsText.Enabled);
	end
	
	addon:RefreshMedia();
	addon:RefreshHeaderArt();
	
	if(self.db.global.ShowPepe) then
		PetBuddyFrameTitle.pepeFrame:Show();
	else
		PetBuddyFrameTitle.pepeFrame:Hide();
	end
	
	local position = self.db.global.Position;
	PetBuddyFrame:ClearAllPoints();
	PetBuddyFrame:SetPoint(position.Point, UIParent, position.RelativePoint, position.x, position.y);
	
	if(self.db.global.Visible) then
		PetBuddyFrame:Show();
	else
		PetBuddyFrame:Hide();
	end
	
	addon:SetWindowScale(self.db.global.WindowScale);
	addon:UpdateMinimizeState();

	if(PetBuddyFrame:IsShown()) then
		addon:UpdateUtilityMenuState();
		addon:UpdatePets();
		addon:ScheduleTimer(function()
			if(PetBuddyFrame and PetBuddyFrame:IsShown()) then
				addon:UpdateUtilityMenuState();
				addon:UpdatePets();
				if(type(addon.RefreshZoneTracker) == "function") then
					addon:RefreshZoneTracker();
				end
			end
		end, 0.5);
	end
end

function addon:RefreshMedia(_, barTexture)
	local selectedBarTexture = barTexture or self.db.global.barTexture;
	if(not addon:HasMedia("statusbar", selectedBarTexture)) then
		selectedBarTexture = DEFAULT_STATUSBAR_NAME;
		self.db.global.barTexture = selectedBarTexture;
	end

	local statusBarPath = addon:FetchMedia("statusbar", selectedBarTexture);

	EnsurePB2TextStyles(self.db.global);

	local rgxFonts = GetRGXFonts();
	if(type(rgxFonts) == "table" and type(rgxFonts.ApplyStyleMap) == "function") then
		rgxFonts:ApplyStyleMap({
			titleText = PetBuddyFontTitle,
			normalText = PetBuddyFontNormal,
			smallText = PetBuddyFontSmall,
		}, self.db.global);
	end
	
	for i=1,3 do
		local petFrame = _G['PetBuddyFramePet'..i];
		
		petFrame.stats.petHealth:SetStatusBarTexture(statusBarPath);
		petFrame.stats.petExperience:SetStatusBarTexture(statusBarPath);
	end

	if(PetBuddyFrameZoneTracker and PetBuddyFrameZoneTracker.bar) then
		PetBuddyFrameZoneTracker.bar:SetStatusBarTexture(statusBarPath);
		local qualityBars = PetBuddyFrameZoneTracker.bar.qualityBars;
		if(type(qualityBars) == "table") then
			for _, qBar in pairs(qualityBars) do
				if(qBar and qBar.SetStatusBarTexture) then
					qBar:SetStatusBarTexture(statusBarPath);
				end
			end
		end
	end

	if(type(self.RefreshZoneTracker) == "function") then
		self:RefreshZoneTracker();
	end
end

function addon:SetWindowScale(scale)
	self.db.global.WindowScale = scale or 1.0;
	PetBuddyFrame:SetScale(self.db.global.WindowScale);
end

function addon:CreateTextStyleOptionsFrame()
	if(self.TextStyleOptionsFrame) then
		return self.TextStyleOptionsFrame;
	end

	local rgxFonts = GetRGXFonts();
	if(type(rgxFonts) ~= "table" or type(rgxFonts.CreateStyleEditorFrame) ~= "function") then
		return nil;
	end

	local frame = rgxFonts:CreateStyleEditorFrame({
		name = "PetBuddyTextStyleOptionsFrame",
		parent = UIParent,
		title = "PetBuddy2 Text Styles",
		subtitle = "PetBuddy2 uses RGX-Framework for all font selection and styling.",
		db = self.db.global,
		width = 420,
		height = 520,
		onChange = function()
			addon:RefreshMedia();
		end,
		onReset = function(db)
			db.titleText = BuildDefaultTextStyle(12, "OUTLINE", {
				shadowColor = "shadow",
				shadowOffset = { x = 1, y = -1 },
			});
			db.normalText = BuildDefaultTextStyle(10, "");
			db.smallText = BuildDefaultTextStyle(9, "");
		end,
		styles = {
			{
				key = "titleText",
				label = "Title Text",
				previewText = "PetBuddy2 title and pet names",
				width = 360,
				height = 130,
			},
			{
				key = "normalText",
				label = "Normal Text",
				previewText = "PetBuddy2 body and status text",
				width = 360,
				height = 130,
			},
			{
				key = "smallText",
				label = "Small Text",
				previewText = "PetBuddy2 compact helper text",
				width = 360,
				height = 130,
			},
		},
	});

	self.TextStyleOptionsFrame = frame;
	return frame;
end

function addon:ToggleTextStyleOptionsFrame()
	local frame = self:CreateTextStyleOptionsFrame();
	if(not frame) then
		return;
	end

	frame:Toggle();
end

function addon:GetWindowScaleMenu()
	local windowScales = { 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, };
	local menu = {};

	for index, scale in ipairs(windowScales) do
		tinsert(menu, {
			text = string.format("%d%%", scale * 100),
			func = function()
				addon:SetWindowScale(scale);
				RefreshDropdownMenu(addon.ContextMenu);
			end,
			checked = function() return self.db.global.WindowScale == scale end,
		});
	end

	return menu;
end

local function TryLoadDropDownAPI()
	if(type(UIDropDownMenu_Initialize) == "function" and type(UIDropDownMenu_AddButton) == "function") then
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

	return type(UIDropDownMenu_Initialize) == "function" and type(UIDropDownMenu_AddButton) == "function";
end

local function RefreshDropdownMenu(menuFrame)
	if(not menuFrame) then
		if(type(addon) == "table" and addon.ContextMenu) then
			menuFrame = addon.ContextMenu;
		end
	end

	if(type(UIDropDownMenu_Refresh) == "function" and menuFrame) then
		UIDropDownMenu_Refresh(menuFrame);
	elseif(type(CloseDropDownMenus) == "function") then
		CloseDropDownMenus();
	end
end

local function SuppressDropDownFrameVisuals(menuFrame)
	if(not menuFrame) then
		return;
	end

	local frameName = menuFrame.GetName and menuFrame:GetName();
	if(type(frameName) == "string" and frameName ~= "") then
		for _, suffix in ipairs({ "Left", "Middle", "Right", "Button", "Text", "Icon" }) do
			local region = _G[frameName .. suffix];
			if(region) then
				if(region.Hide) then
					region:Hide();
				end
				if(region.SetAlpha) then
					region:SetAlpha(0);
				end
			end
		end
	end

	if(menuFrame.SetWidth) then
		menuFrame:SetWidth(1);
	end
	if(menuFrame.SetHeight) then
		menuFrame:SetHeight(1);
	end
end

-- Recursively convert menuData (array of info tables) into UIDropDownMenu-compatible info objects
local function CreateMenuInfo(entry)
	if(type(entry) ~= "table") then
		return entry;
	end

	local info;
	if(type(UIDropDownMenu_CreateInfo) == "function") then
		info = UIDropDownMenu_CreateInfo();
	else
		info = {};
	end

	for k, v in pairs(entry) do
		info[k] = v;
	end

	return info;
end

-- Initialize a single level of the dropdown menu
local function InitializeMenuLevel(self, level, menuList)
	level = level or 1;
	local currentList;

	if(type(menuList) == "table") then
		currentList = menuList;
	else
		currentList = self._pbMenuData;
	end

	if(type(currentList) ~= "table") then
		return;
	end

	for _, entry in ipairs(currentList) do
		if(type(entry) == "table") then
			local info = CreateMenuInfo(entry);
			UIDropDownMenu_AddButton(info, level);
		end
	end
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
	local menu = {};
	tinsert(menu, { text = "Pet Items Options", isTitle = true, notCheckable = true });

	if(type(addon.GetPetItemCategoryMenuData) == "function") then
		local categories = addon:GetPetItemCategoryMenuData(false);
		if(type(categories) == "table") then
			for _, entry in ipairs(categories) do
				tinsert(menu, entry);
			end
		end
	end
	return menu;
end

function addon:GetPrimaryMenuData()
	local sharedMediaBarTextures = {};
	for _, statusbar in ipairs(addon:ListMedia("statusbar")) do
		local barName = statusbar;
		tinsert(sharedMediaBarTextures, {
			text = barName,
			func = function()
				self.db.global.barTexture = barName;
				addon:RefreshMedia();
				RefreshDropdownMenu(addon.ContextMenu);
			end,
			checked = function() return self.db.global.barTexture == barName; end,
			keepShownOnClick = true,
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
			keepShownOnClick = true,
		},
		{
			text = "Hide when entering combat",
			func = function() self.db.global.HideInCombat = not self.db.global.HideInCombat; end,
			checked = function() return self.db.global.HideInCombat; end,
			isNotRadio = true,
			keepShownOnClick = true,
		},
		{
			text = "Show welcome message on login",
			func = function()
				self.db.global.ShowWelcomeMessage = not self.db.global.ShowWelcomeMessage;
			end,
			checked = function() return self.db.global.ShowWelcomeMessage; end,
			isNotRadio = true,
			keepShownOnClick = true,
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Automation", isTitle = true, notCheckable = true,
		},
		{
			text = "When starting pet battle",
			notCheckable = true,
			hasArrow = true,
			keepShownOnClick = true,
			menuList = {
				{
					text = "Show",
					func = function()
						self.db.global.PetBattleVisiblityMode = E.VISIBILITY_MODE.SHOW;
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.PetBattleVisiblityMode == E.VISIBILITY_MODE.SHOW; end,
					keepShownOnClick = true,
				},
				{
					text = "Hide",
					func = function()
						self.db.global.PetBattleVisiblityMode = E.VISIBILITY_MODE.HIDE;
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.PetBattleVisiblityMode == E.VISIBILITY_MODE.HIDE; end,
					keepShownOnClick = true,
				},
				{
					text = "Do nothing",
					func = function()
						self.db.global.PetBattleVisiblityMode = E.VISIBILITY_MODE.DO_NOTHING;
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.PetBattleVisiblityMode == E.VISIBILITY_MODE.DO_NOTHING; end,
					keepShownOnClick = true,
				},
			},
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
			keepShownOnClick = true,
			hasArrow = true,
			menuList = {
				{
					text = "Resummon Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Last used pet",
					func = function()
						self.db.global.AutoSummonMode = E.AUTO_SUMMON_MODE.LAST_PET;
						addon:UpdateAutoResummon(true);
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.AutoSummonMode == E.AUTO_SUMMON_MODE.LAST_PET; end,
					keepShownOnClick = true,
				},
				{
					text = "Random favorite pet",
					func = function()
						self.db.global.AutoSummonMode = E.AUTO_SUMMON_MODE.FAVORITE;
						addon:UpdateAutoResummon(true);
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.AutoSummonMode == E.AUTO_SUMMON_MODE.FAVORITE; end,
					keepShownOnClick = true,
				},
				{
					text = "Any random pet",
					func = function()
						self.db.global.AutoSummonMode = E.AUTO_SUMMON_MODE.ANY;
						addon:UpdateAutoResummon(true);
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.AutoSummonMode == E.AUTO_SUMMON_MODE.ANY; end,
					keepShownOnClick = true,
				},
			},
		},
		{
			text = "Automatically heal pets at stables",
			func = function() self.db.global.AutoHealPets = not self.db.global.AutoHealPets; AutoHealButton_OnShow(PetBuddyAutoHealButton) end,
			checked = function() return self.db.global.AutoHealPets; end,
			isNotRadio = true,
			keepShownOnClick = true,
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
					keepShownOnClick = true,
				},
			}
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Displays", isTitle = true, notCheckable = true,
		},
		{
			text = "Enable cuteness",
			func = function()
				self.db.global.ShowPepe = not self.db.global.ShowPepe;
				addon:RefreshHeaderArt();
				if(self.db.global.ShowPepe) then
					PetBuddyFrameTitle.pepeFrame:Show();
				else
					PetBuddyFrameTitle.pepeFrame:Hide();
				end
			end,
			checked = function() return self.db.global.ShowPepe; end,
			isNotRadio = true,
			hasArrow = true,
			keepShownOnClick = true,
			menuList = {
				{
					text = "Cuteness Position", notCheckable = true, isTitle = true,
				},
				{
					text = "Right side",
					func = function()
						self.db.global.PepeOnLeft = false;
						addon:RefreshHeaderArt();
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return not self.db.global.PepeOnLeft; end,
					keepShownOnClick = true,
				},
				{
					text = "Left side",
					func = function()
						self.db.global.PepeOnLeft = true;
						addon:RefreshHeaderArt();
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.PepeOnLeft; end,
					keepShownOnClick = true,
				},
			},
		},
		{
			text = "Show pet charms",
			func = function()
				self.db.global.ShowPetCharms = not self.db.global.ShowPetCharms;
				addon:RestoreSavedSettings();
			end,
			checked = function() return self.db.global.ShowPetCharms; end,
			isNotRadio = true,
			keepShownOnClick = true,
		},
		{
			text = "Show pet health and experience text",
			func = function() self.db.global.PetStatsText.Enabled = not self.db.global.PetStatsText.Enabled; addon:RestoreSavedSettings() end,
			checked = function() return self.db.global.PetStatsText.Enabled; end,
			isNotRadio = true,
			keepShownOnClick = true,
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
					keepShownOnClick = true,
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
					keepShownOnClick = true,
				},
				{
					text = "Display current experience",
					func = function()
						self.db.global.PetStatsText.RemainingExperience = false;
						addon:UpdatePets();
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return not self.db.global.PetStatsText.RemainingExperience; end,
					keepShownOnClick = true,
				},
				{
					text = "Display experience to level",
					func = function()
						self.db.global.PetStatsText.RemainingExperience = true;
						addon:UpdatePets();
						RefreshDropdownMenu(addon.ContextMenu);
					end,
					checked = function() return self.db.global.PetStatsText.RemainingExperience; end,
					keepShownOnClick = true,
				},
			},
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
			keepShownOnClick = true,
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
			keepShownOnClick = true,
			disabled = C_PetBattles.IsInBattle(),
			menuList = addon:GetPetItemsUtilityMenuData(),
		},
		{
			text = "Show pet tooltips",
			func = function() self.db.global.ShowPetTooltips = not self.db.global.ShowPetTooltips; end,
			checked = function() return self.db.global.ShowPetTooltips; end,
			isNotRadio = true,
			keepShownOnClick = true,
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Zone Tracker", isTitle = true, notCheckable = true,
		},
		{
			text = "Hide main GUI body",
			func = function()
				self.db.global.HideMainGUI = not self.db.global.HideMainGUI;
				addon:UpdateMinimizeState();
			end,
			checked = function() return self.db.global.HideMainGUI; end,
			isNotRadio = true,
			keepShownOnClick = true,
		},
		{
			text = "Show zone pet tracker",
			func = function()
				self.db.global.ShowZoneTracker = not self.db.global.ShowZoneTracker;
				addon:RestoreSavedSettings();
			end,
			checked = function() return self.db.global.ShowZoneTracker; end,
			isNotRadio = true,
			hasArrow = true,
			keepShownOnClick = true,
			menuList = {
				{ text = "Zone Tracker Options", isTitle = true, notCheckable = true },
				{
					text = "Show missing pets list",
					func = function()
						self.db.global.ShowZoneTrackerPetList = not self.db.global.ShowZoneTrackerPetList;
						addon:RefreshZoneTracker();
					end,
					checked = function() return self.db.global.ShowZoneTrackerPetList; end,
					isNotRadio = true,
					keepShownOnClick = true,
				},
			},
		},
		{
			text = "Show minimap icon",
			func = function()
				if(type(addon.ToggleMinimapIcon) == "function") then
					addon:ToggleMinimapIcon(nil);  -- nil toggles
				end
			end,
			checked = function()
				return self.db.global.MinimapIcon and self.db.global.MinimapIcon.enabled;
			end,
			isNotRadio = true,
			keepShownOnClick = true,
			tooltipTitle = "Ctrl+Right-click minimap icon to hide",
			tooltipText = "You can also use |cffb07fff/pb2 icon off|r to hide or |cffb07fff/pb2 icon on|r to show.",
		},
		{
			text = "", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Frame Options", isTitle = true, notCheckable = true, disabled = true,
		},
		{
			text = "Text styles",
			notCheckable = true,
			func = function()
				addon:ToggleTextStyleOptionsFrame();
			end,
		},
		{
			text = "Bar texture",
			notCheckable = true,
			hasArrow = true,
			menuList = sharedMediaBarTextures,
		},
		{
			text = string.format("Change scale (%d%%)", self.db.global.WindowScale * 100),
			notCheckable = true,
			hasArrow = true,
			keepShownOnClick = true,
			menuList = addon:GetWindowScaleMenu(),
		},
	};

	return data;
end

function addon:OpenContextMenu(contextMenuData, parentframe, anchor, point, relativePoint)

	if(not addon.ContextMenu) then
		addon.ContextMenu = CreateFrame("Frame", "PetBuddyContextMenuFrame", UIParent, "UIDropDownMenuTemplate");
		addon.ContextMenu:SetFrameStrata("DIALOG");
		SuppressDropDownFrameVisuals(addon.ContextMenu);
	end

	if(not contextMenuData) then
		contextMenuData = addon:GetPrimaryMenuData();
	end

	addon.ContextMenu:ClearAllPoints();
	addon.ContextMenu:SetPoint(point or "TOPLEFT", parentframe or PetBuddyFrame, relativePoint or "CENTER", 0, 5);
	addon:OpenDropDownMenu(contextMenuData, addon.ContextMenu, anchor or "cursor", 0, 0, "MENU", 5);
end

function addon:OpenDropDownMenu(menuData, menuFrame, anchor, x, y, displayMode, autoHideDelay)
	if(type(menuData) ~= "table" or not menuFrame) then
		return false;
	end

	if(not TryLoadDropDownAPI()) then
		if(type(addon.PrintMessage) == "function") then
			addon:PrintMessage("|cffff5555Dropdown menu API unavailable on this client.|r");
		end
		return false;
	end

	-- Store menu data on the frame for the init function to access
	menuFrame._pbMenuData = menuData;

	-- Initialize using the native UIDropDownMenu API (same pattern BLU uses)
	UIDropDownMenu_Initialize(menuFrame, InitializeMenuLevel, displayMode or "MENU");

	-- Open the dropdown
	if(type(ToggleDropDownMenu) == "function") then
		ToggleDropDownMenu(1, nil, menuFrame, anchor or "cursor", x or 0, y or 0, menuData, nil, autoHideDelay or 5);
	end

	return true;
end
