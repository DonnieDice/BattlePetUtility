local ADDON_NAME, addon = ...
local E = addon.E
local DEFAULT_STATUSBAR_NAME = "RenAscensionL"

local RGX = _G.RGXFramework
local Fonts = _G.RGXFonts
local Textures = _G.RGXTextures

local function BuildDefaultTextStyle(size, flags, extras)
	local style = { font = Fonts:GetDefault(), size = size, flags = flags or "" }
	if type(extras) == "table" then
		for key, value in pairs(extras) do style[key] = value end
	end
	return Fonts:CreateStyle(style)
end

local function EnsureBPUTextStyles(db)
	if type(db) ~= "table" then return end

	if type(db.titleText) ~= "table" or type(db.normalText) ~= "table" or type(db.smallText) ~= "table" then
		local legacyFont = db.fontFace or Fonts:GetDefault()
		local legacySize = tonumber(db.fontSize) or 10
		db.titleText = BuildDefaultTextStyle(legacySize + 2, "OUTLINE", {
			font = legacyFont, shadowColor = "shadow", shadowOffset = { x = 1, y = -1 },
		})
		db.normalText = BuildDefaultTextStyle(legacySize, "", { font = legacyFont })
		db.smallText = BuildDefaultTextStyle(math.max(8, legacySize - 1), "", { font = legacyFont })
	end

	db.fontFace = nil
	db.fontSize = nil
end

Textures:RegisterBars("BattlePetUtility", {
	[DEFAULT_STATUSBAR_NAME] = [[Interface\AddOns\BattlePetUtility\media\renascensionl]],
	["Glamour"] = [[Interface\AddOns\BattlePetUtility\media\renascensionl]],
	["Smoother"] = [[Interface\AddOns\BattlePetUtility\media\backdrop]],
})

E.VISIBILITY_MODE = {
	DO_NOTHING = 0x1,
	SHOW = 0x2,
	HIDE = 0x3,
}

E.AUTO_SUMMON_MODE = {
	LAST_PET = 0x1,
	FAVORITE = 0x2,
	ANY = 0x3,
}

function addon:InitializeDatabase()
	-- Carry over data from the old PetBuddy2 saved variable name.
	if type(_G.BattlePetUtilityDB) ~= "table" and type(_G.PetBuddyDB) == "table" then
		_G.BattlePetUtilityDB = _G.PetBuddyDB
	end

	-- Migrate old flat BattlePetUtilityDB to NewDatabase structure
	if type(BattlePetUtilityDB) == "table" and BattlePetUtilityDB.global and not BattlePetUtilityDB.profiles then
		local oldGlobal = BattlePetUtilityDB.global or {}
		local oldChar = BattlePetUtilityDB.char or {}

		-- Run the v2.3.7 one-time migration before moving to profiles
		-- (kept old flag name to avoid double-migration on carry-over data)
		if oldGlobal._pb2DefaultInit_v237 ~= true then
			if (tonumber(oldGlobal.PetUtilityMenuState) or 0) == 1 and oldGlobal.ShowPetLoadouts == false then
				oldGlobal.PetUtilityMenuState = 3
				oldGlobal.ShowPetLoadouts = true
				oldGlobal.ShowPetItems = true
			end
			if oldGlobal.ShowZoneTracker == nil then
				oldGlobal.ShowZoneTracker = true
			end
			if oldGlobal.ShowZoneTrackerPetList == nil then
				oldGlobal.ShowZoneTrackerPetList = true
			end
			oldGlobal._pb2DefaultInit_v237 = true
		end

		-- Rebuild as NewDatabase-compatible structure
		wipe(BattlePetUtilityDB)
		BattlePetUtilityDB.profiles = { Default = oldGlobal }
		BattlePetUtilityDB.global = {}
		BattlePetUtilityDB.char = oldChar
		BattlePetUtilityDB.profiles.Default.currentProfile = "Default"
	end

	local defaults = {
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

		PetUtilityMenuState = 3,

		ShowPepe = true,
		PepeOnLeft = false,
		ShowWelcomeMessage = true,

		ShowPetItems = true,
		ShowPetLoadouts = true,
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

	self.db = RGX:NewDatabase("BattlePetUtilityDB", defaults, {
		char = {
			AutoSummonLastPetID = nil,
			LastActiveTeam = nil,
			LastSavedMapID = nil,
		},
		profileIsGlobal = true,
	})

	-- db.global returns the active profile (profileIsGlobal=true), so
	-- EnsureBPUTextStyles reads/writes through the proxy to the profile.
	EnsureBPUTextStyles(self.db.global)

	if type(addon.InitializePetItemCategoryDefaults) == "function" then
		addon:InitializePetItemCategoryDefaults()
	end

	addon:RestoreSavedSettings()
end

function BattlePetUtilityFrame_SavePosition()
	if not addon.db then return end

	local point, _, relativePoint, x, y = BattlePetUtilityFrame:GetPoint()
	addon.db.global.Position = {
		Point = point,
		RelativePoint = relativePoint,
		x = x,
		y = y,
	}
end

function addon:RestoreSavedSettings()
	if InCombatLockdown() then return end

	addon:SyncUtilityMenuState()
	addon:UpdateUtilityMenuState()

	BattlePetUtilityFrameTitlePetCharms:SetShown(self.db.global.ShowPetCharms)

	for i = 1, 3 do
		local petFrame = _G['BattlePetUtilityFramePet' .. i]
		petFrame.stats.petHealth.text:SetShown(self.db.global.PetStatsText.Enabled)
		petFrame.stats.petExperience.text:SetShown(self.db.global.PetStatsText.Enabled)
	end

	addon:RefreshMedia()
	addon:RefreshHeaderArt()

	if self.db.global.ShowPepe then
		BattlePetUtilityFrameTitle.pepeFrame:Show()
	else
		BattlePetUtilityFrameTitle.pepeFrame:Hide()
	end

	local position = self.db.global.Position
	BattlePetUtilityFrame:ClearAllPoints()
	BattlePetUtilityFrame:SetPoint(position.Point, UIParent, position.RelativePoint, position.x, position.y)

	if self.db.global.Visible then
		BattlePetUtilityFrame:Show()
	else
		BattlePetUtilityFrame:Hide()
	end

	addon:SetWindowScale(self.db.global.WindowScale)
	addon:UpdateMinimizeState()

	if BattlePetUtilityFrame:IsShown() then
		addon:UpdateUtilityMenuState()
		addon:UpdatePets()
		addon:ScheduleTimer(function()
			if BattlePetUtilityFrame and BattlePetUtilityFrame:IsShown() then
				addon:UpdateUtilityMenuState()
				addon:UpdatePets()
				if type(addon.RefreshZoneTracker) == "function" then
					addon:RefreshZoneTracker()
				end
			end
		end, 0.5)
	end
end
