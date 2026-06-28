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

local function EnsurePB2TextStyles(db)
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

Textures:RegisterBars("PetBuddy2", {
	[DEFAULT_STATUSBAR_NAME] = [[Interface\AddOns\PetBuddy2\media\renascensionl.tga]],
	["Glamour"] = [[Interface\AddOns\PetBuddy2\media\renascensionl.tga]],
	["Smoother"] = [[Interface\AddOns\PetBuddy2\media\backdrop.tga]],
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
	-- Migrate old flat PetBuddyDB to NewDatabase structure
	if type(PetBuddyDB) == "table" and PetBuddyDB.global and not PetBuddyDB.profiles then
		local oldGlobal = PetBuddyDB.global or {}
		local oldChar = PetBuddyDB.char or {}

		-- Run the v2.3.7 one-time migration before moving to profiles
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
		wipe(PetBuddyDB)
		PetBuddyDB.profiles = { Default = oldGlobal }
		PetBuddyDB.global = {}
		PetBuddyDB.char = oldChar
		PetBuddyDB.profiles.Default.currentProfile = "Default"
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

	self.db = RGX:NewDatabase("PetBuddyDB", defaults, {
		char = {
			AutoSummonLastPetID = nil,
			LastActiveTeam = nil,
			LastSavedMapID = nil,
		},
		profileIsGlobal = true,
	})

	-- db.global returns the active profile (profileIsGlobal=true), so
	-- EnsurePB2TextStyles reads/writes through the proxy to the profile.
	EnsurePB2TextStyles(self.db.global)

	if type(addon.InitializePetItemCategoryDefaults) == "function" then
		addon:InitializePetItemCategoryDefaults()
	end

	addon:RestoreSavedSettings()
end

function PetBuddyFrame_SavePosition()
	if not addon.db then return end

	local point, _, relativePoint, x, y = PetBuddyFrame:GetPoint()
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

	PetBuddyFrameTitlePetCharms:SetShown(self.db.global.ShowPetCharms)

	for i = 1, 3 do
		local petFrame = _G['PetBuddyFramePet' .. i]
		petFrame.stats.petHealth.text:SetShown(self.db.global.PetStatsText.Enabled)
		petFrame.stats.petExperience.text:SetShown(self.db.global.PetStatsText.Enabled)
	end

	addon:RefreshMedia()
	addon:RefreshHeaderArt()

	if self.db.global.ShowPepe then
		PetBuddyFrameTitle.pepeFrame:Show()
	else
		PetBuddyFrameTitle.pepeFrame:Hide()
	end

	local position = self.db.global.Position
	PetBuddyFrame:ClearAllPoints()
	PetBuddyFrame:SetPoint(position.Point, UIParent, position.RelativePoint, position.x, position.y)

	if self.db.global.Visible then
		PetBuddyFrame:Show()
	else
		PetBuddyFrame:Hide()
	end

	addon:SetWindowScale(self.db.global.WindowScale)
	addon:UpdateMinimizeState()

	if PetBuddyFrame:IsShown() then
		addon:UpdateUtilityMenuState()
		addon:UpdatePets()
		addon:ScheduleTimer(function()
			if PetBuddyFrame and PetBuddyFrame:IsShown() then
				addon:UpdateUtilityMenuState()
				addon:UpdatePets()
				if type(addon.RefreshZoneTracker) == "function" then
					addon:RefreshZoneTracker()
				end
			end
		end, 0.5)
	end
end
