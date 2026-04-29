local ADDON_NAME, addon = ...;
local RGX = _G.RGXFramework;

local ZONE_TRACKER_TITLE = "Zone Pets";
local MAX_TRACKED_PET_NAMES = 3;
local MAX_TOOLTIP_PET_LINES = 30;
local MAX_VISIBLE_ZONE_LINES = 4;
local TOOLTIP_ICON_SIZE = 12;
local MISSING_SEGMENT_COLOR = CreateColor(0.62, 0.62, 0.62);
local MAP_ALIASES = {
  -- Stormwind City and its modern city-map variant should use the
  -- nearest outdoor wild-pet dataset instead of showing as unavailable.
  [84] = 37,    -- Stormwind City -> Elwynn Forest
  [301] = 37,   -- Stormwind City (modern variant)

  -- Orgrimmar -> Durotar
  [85] = 1,     -- Orgrimmar
  [321] = 1,    -- Orgrimmar (modern variant)

  -- Ironforge -> Dun Morogh
  [87] = 27,    -- Ironforge

  -- Darnassus -> Teldrassil
  [89] = 57,    -- Darnassus

  -- Thunder Bluff -> Mulgore
  [88] = 7,     -- Thunder Bluff

  -- Undercity -> Tirisfal Glades
  [90] = 20,    -- Undercity

  -- Silvermoon City -> Eversong Woods (Ghostlands is 95)
  [110] = 94,   -- Silvermoon City -> Eversong Woods

  -- Exodar -> Azuremyst Isle
  [103] = 104,  -- Exodar

  -- Dalaran (Northrend)
  [125] = 127,  -- Dalaran -> Crystalsong Forest
  [126] = 127,  -- Dalaran Underbelly

  -- Dalaran (Broken Isles)
  [627] = 634,  -- Dalaran (Legion) -> Stormheim
  [628] = 634,  -- Dalaran (Legion Underbelly)

  -- Shattrath City
  [111] = 108,  -- Shattrath -> Terokkar Forest

  -- The War Within - Khaz Algar Subzones -> Main Zones
  [2248] = 2249, -- Dornogal (subzone) -> Isle of Dorn
  [2214] = 2250, -- The Ringing Deeps (various subzones)
  [2215] = 2251, -- Hallowfall (various subzones)
  [2255] = 2252, -- Azj-Kahet (various subzones)
  [2256] = 2252, -- Azj-Kahet (alternate)

  -- Dragonflight - Major Cities/Hubs
  [2112] = 2025, -- Valdrakken -> Thaldraszus
  [2022] = 2022, -- Wingrest Embassy -> Waking Shores (self)

  -- Shadowlands - Covenant Sanctuaries
  [1690] = 1525, -- Sinfall -> Revendreth
  [1691] = 1533, -- Bastion Covenant
  [1692] = 1536, -- Maldraxxus Covenant
  [1693] = 1565, -- Ardenweald Covenant
  [1694] = 1543, -- The Maw Covenant

  -- Instances/Dungeons that share outdoor areas
  [1477] = 630,  -- Eye of Azshara instance -> Azsuna
  [1456] = 680,  -- The Nighthold instance -> Suramar
  [1466] = 634,  -- Maw of Souls instance -> Stormheim
  [1501] = 641,  -- Black Rook Hold instance -> Val'sharah
  [1516] = 630,  -- The Arcway instance -> Azsuna

  -- BFA - Major Cities
  [1161] = 895,  -- Boralus -> Tiragarde Sound
  [1165] = 862,  -- Dazar'alor -> Zuldazar

  -- Mechagon
  [1462] = 1462, -- Mechagon Island (self)
  [1490] = 1462, -- Operation: Mechagon

  -- Nazjatar
  [1355] = 1355, -- Nazjatar (self)

  -- Instances that can have outdoor pet spawns nearby
  [1205] = 2022, -- Vault of the Incarnates -> Waking Shores
  [1209] = 2022, -- Aberrus -> Waking Shores
  [1208] = 2024, -- Amirdrassil -> Azure Span
};
local PET_QUALITY_COLORS = {
	[1] = CreateColor(1.00, 1.00, 1.00), -- poor shown as white per requested bar palette
	[2] = CreateColor(1.00, 1.00, 1.00), -- common
	[3] = CreateColor(0.12, 1.00, 0.00), -- uncommon
	[4] = CreateColor(0.00, 0.44, 0.87), -- rare
};

PetBuddy_ZoneTrackerMixin = {};

local function IsPetTrackerLoaded()
	return rawget(_G, "PetTracker") ~= nil;
end

local qualityMapCache = nil;
local function InvalidateQualityMap()
	qualityMapCache = nil;
end
addon.InvalidateZoneQualityCache = InvalidateQualityMap;

local function GetMapName(mapID)
	if(not mapID or mapID == 0 or not C_Map or type(C_Map.GetMapInfo) ~= "function") then
		return nil;
	end

	local mapInfo = C_Map.GetMapInfo(mapID);
	return mapInfo and mapInfo.name or nil;
end

local function GetPetTrackerSnapshotForMap(mapID)
	local petTracker = rawget(_G, "PetTracker");
	local maps = petTracker and petTracker.Maps;
	if(type(maps) ~= "table" or type(maps.GetProgressIn) ~= "function") then
		return nil;
	end

	local ok, progress = pcall(maps.GetProgressIn, maps, mapID);
	if(not ok or type(progress) ~= "table") then
		return nil;
	end

	local total = tonumber(progress.total) or 0;
	if(total <= 0) then
		return nil;
	end

	local missingBucket = type(progress[0]) == "table" and progress[0] or {};
	local missing = tonumber(missingBucket.total) or 0;
	local owned = math.max(0, total - missing);
	local qualityCounts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 };
	local missingNames, allNames = {}, {};

	local maxQuality = tonumber(petTracker.MaxPlayerQuality or 4) or 4;
	for quality = 0, maxQuality do
		local bucket = type(progress[quality]) == "table" and progress[quality] or nil;
		if(bucket) then
			for level = 0, 25 do
				local speciesAtLevel = bucket[level];
				if(type(speciesAtLevel) == "table") then
					for _, species in ipairs(speciesAtLevel) do
						local name = nil;
						local icon = nil;
						local sourceIcon = nil;
						if(type(species) == "table" and type(species.GetInfo) == "function") then
							local ok, speciesName, speciesIcon = pcall(species.GetInfo, species);
							if(ok) then
								name = speciesName;
								icon = speciesIcon;
							end
						end

						if(type(species) == "table" and type(species.GetSourceIcon) == "function") then
							local ok, source = pcall(species.GetSourceIcon, species);
							if(ok) then
								sourceIcon = source;
							end
						end

						name = name or "Unknown";
						allNames[#allNames + 1] = {
							name = name,
							quality = quality,
							icon = icon,
							sourceIcon = sourceIcon,
						};

						if(quality <= 0) then
							missingNames[#missingNames + 1] = name;
						else
							local clampedQuality = math.max(1, math.min(4, quality));
							qualityCounts[clampedQuality] = (qualityCounts[clampedQuality] or 0) + 1;
						end
					end
				end
			end
		end
	end

	return {
		mapID = mapID,
		mapName = GetMapName(mapID),
		total = total,
		owned = owned,
		missing = missing,
		percent = total > 0 and (owned / total) or 0,
		qualityCounts = qualityCounts,
		missingNames = missingNames,
		allNames = allNames,
		provider = "PetTracker",
	};
end

local function GetSpeciesName(speciesID)
	if(not speciesID or not C_PetJournal or type(C_PetJournal.GetPetInfoBySpeciesID) ~= "function") then
		return "Unknown";
	end

	local name = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
	return name or ("Species " .. tostring(speciesID));
end

local function GetSpeciesIcon(speciesID)
	if(not speciesID or not C_PetJournal or type(C_PetJournal.GetPetInfoBySpeciesID) ~= "function") then
		return nil;
	end

	local _, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
	return icon;
end

local function GetPetQualityColor(quality)
	local clampedQuality = math.max(1, math.min(4, tonumber(quality) or 1));
	return PET_QUALITY_COLORS[clampedQuality] or NORMAL_FONT_COLOR;
end

local function BuildSpeciesQualityMap()
	-- PetTracker path: we never use the native quality map, so skip the whole scan
	-- (and critically, avoid mutating C_PetJournal filters which would thrash PetTracker).
	if(IsPetTrackerLoaded()) then
		return {};
	end

	if(qualityMapCache) then
		return qualityMapCache;
	end

	local qualityBySpecies = {};
	if(not C_PetJournal or type(C_PetJournal.GetNumPets) ~= "function" or type(C_PetJournal.GetPetInfoByIndex) ~= "function") then
		return qualityBySpecies;
	end

	local resetFiltering = type(addon.ResetJournalFiltering) == "function";
	local restoreFiltering = type(addon.RestoreJournalFiltering) == "function";
	if(resetFiltering and restoreFiltering) then
		addon:ResetJournalFiltering();
	end

	local totalPets = C_PetJournal.GetNumPets();
	totalPets = tonumber(totalPets) or 0;
	for index = 1, totalPets do
		local petID, speciesID, isOwned = C_PetJournal.GetPetInfoByIndex(index);
		if(isOwned and petID and speciesID) then
			local _, _, _, _, quality = C_PetJournal.GetPetStats(petID);
			quality = math.max(1, math.min(4, tonumber(quality) or 1));
			if(not qualityBySpecies[speciesID] or quality > qualityBySpecies[speciesID]) then
				qualityBySpecies[speciesID] = quality;
			end
		end
	end

	if(resetFiltering and restoreFiltering) then
		addon:RestoreJournalFiltering();
	end

	qualityMapCache = qualityBySpecies;
	return qualityBySpecies;
end

local function GetSpeciesCollectionCount(speciesID)
	if(not speciesID or not C_PetJournal or type(C_PetJournal.GetNumCollectedInfo) ~= "function") then
		return 0;
	end

	local _, numCollected = C_PetJournal.GetNumCollectedInfo(speciesID);
	return tonumber(numCollected) or 0;
end

local function GetNativeProgressForMap(mapID)
	local speciesList = addon.ZoneSpeciesByMap and addon.ZoneSpeciesByMap[mapID];
	if(type(speciesList) ~= "table" or #speciesList == 0) then
		return nil;
	end

	local total = #speciesList;
	local owned = 0;
	local qualityBySpecies = BuildSpeciesQualityMap();
	local qualityCounts = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 };
	local missingNames = {};
	local allNames = {};
	for _, speciesID in ipairs(speciesList) do
		local name = GetSpeciesName(speciesID);
		local icon = GetSpeciesIcon(speciesID);
		local quality = qualityBySpecies[speciesID];
		if(quality and quality > 0 and GetSpeciesCollectionCount(speciesID) > 0) then
			owned = owned + 1;
			qualityCounts[quality] = (qualityCounts[quality] or 0) + 1;
			allNames[#allNames + 1] = {
				name = name,
				quality = quality,
				speciesID = speciesID,
				icon = icon,
			};
		else
			missingNames[#missingNames + 1] = name;
			allNames[#allNames + 1] = {
				name = name,
				quality = 0,
				speciesID = speciesID,
				icon = icon,
			};
		end
	end

	return {
		mapID = mapID,
		mapName = GetMapName(mapID),
		total = total,
		owned = owned,
		missing = math.max(0, total - owned),
		percent = total > 0 and (owned / total) or 0,
		qualityCounts = qualityCounts,
		missingNames = missingNames,
		allNames = allNames,
		provider = "native",
	};
end

local function EnsureQualityBars(frame)
	if(not frame or not frame.bar) then
		return nil;
	end

	local container = frame.bar;
	if(container.qualityBars) then
		return container.qualityBars;
	end

	container.qualityBars = {};
	for quality = 0, 4 do
		local bar = container:CreateTexture(nil, "ARTWORK");
		bar:SetDrawLayer("ARTWORK", quality);
		bar:ClearAllPoints();
		bar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0);
		bar:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0);
		bar:SetWidth(0);
		local color = nil;
		if(quality == 0) then
			color = MISSING_SEGMENT_COLOR;
		else
			color = GetPetQualityColor(quality);
		end
		bar.pbColor = color;
		bar:SetColorTexture(color.r, color.g, color.b, 1);
		container.qualityBars[quality] = bar;
	end

	if(not container.textOverlay) then
		local overlay = CreateFrame("Frame", nil, container);
		overlay:SetAllPoints(container);
		overlay:SetFrameLevel(container:GetFrameLevel() + 10);
		container.textOverlay = overlay;

		if(container.text) then
			container.text:SetParent(overlay);
			container.text:SetDrawLayer("OVERLAY", 7);
		end
	end

	return container.qualityBars;
end

local function ApplyProgressBarTexture(frame)
	if(not frame or not frame.bar) then
		return;
	end

	local texturePath = "Interface\\TargetingFrame\\UI-StatusBar";
	if(type(addon.FetchMedia) == "function" and addon.db and addon.db.global) then
		texturePath = addon:FetchMedia("statusbar", addon.db.global.barTexture) or texturePath;
	end

	if(frame.bar.SetStatusBarTexture) then
		frame.bar:SetStatusBarTexture(texturePath);
	end

	local bars = EnsureQualityBars(frame);
	if(bars) then
		for _, bar in pairs(bars) do
			if(bar.SetTexture) then
				bar:SetTexture(texturePath);
				if(bar.pbColor) then
					bar:SetVertexColor(bar.pbColor.r, bar.pbColor.g, bar.pbColor.b, 1);
				end
			end
		end
	end
end

local function UpdateQualityBars(frame, snapshot)
	if(not frame or not frame.bar) then
		return;
	end

	local bars = EnsureQualityBars(frame);
	if(not bars) then
		return;
	end

	local total = math.max(1, tonumber(snapshot.total) or 1);
	local qualityCounts = snapshot.qualityCounts or {};
	local containerWidth = frame.bar:GetWidth() or 0;
	if(containerWidth <= 0) then
		RGX:After(0, function()
			if(frame and frame.bar and frame.snapshot == snapshot) then
				UpdateQualityBars(frame, snapshot);
			end
		end);
		return;
	end
	local missingCount = math.max(0, tonumber(snapshot.missing) or math.max(0, total - (tonumber(snapshot.owned) or 0)));
	local offset = 0;
	local segmentOrder = { 0, 1, 2, 3, 4 };

	for _, quality in ipairs(segmentOrder) do
		local count = quality == 0 and missingCount or math.max(0, tonumber(qualityCounts[quality]) or 0);
		local width = containerWidth * (count / total);
		local bar = bars[quality];
		bar:ClearAllPoints();
		bar:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", offset, 0);
		bar:SetPoint("BOTTOMLEFT", frame.bar, "BOTTOMLEFT", offset, 0);
		bar:SetWidth(width);
		bar:SetShown(snapshot.state == "ready" and width > 0);
		offset = offset + width;
	end
end

local function GetPetSummaryText(snapshot)
	if(snapshot.state ~= "ready") then
		return nil;
	end

	local missingNames = snapshot.missingNames or {};
	if(#missingNames == 0) then
		return "All zone pets collected";
	end

	local shown = {};
	for index = 1, math.min(MAX_TRACKED_PET_NAMES, #missingNames) do
		shown[#shown + 1] = missingNames[index];
	end

	local summary = table.concat(shown, ", ");
	if(#missingNames > MAX_TRACKED_PET_NAMES) then
		summary = summary .. ", +" .. tostring(#missingNames - MAX_TRACKED_PET_NAMES) .. " more";
	end

	return summary;
end

local function AddTooltipPetLines(tooltip, snapshot)
	local allNames = snapshot.allNames or {};
	if(#allNames == 0) then
		return;
	end

	local missingEntries, collectedEntries = {}, {};
	for _, petInfo in ipairs(allNames) do
		if((tonumber(petInfo.quality) or 0) <= 0) then
			missingEntries[#missingEntries + 1] = petInfo;
		else
			collectedEntries[#collectedEntries + 1] = petInfo;
		end
	end

	local function FormatHex(r, g, b)
		return string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5));
	end

	local shown = 0;
	if(#missingEntries > 0) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("Missing", 1.0, 0.82, 0.0);
		for _, petInfo in ipairs(missingEntries) do
			if(shown >= MAX_TOOLTIP_PET_LINES) then break end
			local iconMarkup = petInfo.icon and ("|T" .. tostring(petInfo.icon) .. ":" .. TOOLTIP_ICON_SIZE .. ":" .. TOOLTIP_ICON_SIZE .. ":0:0|t ") or "";
			local name = petInfo.name or "Unknown";
			GameTooltip:AddLine(iconMarkup .. "|cffff5555" .. name .. "|r", 1, 1, 1);
			shown = shown + 1;
		end
	end

	if(#collectedEntries > 0 and shown < MAX_TOOLTIP_PET_LINES) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("Collected", 1.0, 0.82, 0.0);
		for _, petInfo in ipairs(collectedEntries) do
			if(shown >= MAX_TOOLTIP_PET_LINES) then break end
			local quality = tonumber(petInfo.quality) or 0;
			local qualityColor = GetPetQualityColor(quality);
			local hex;
			if(qualityColor and qualityColor.GenerateHexColorMarkup) then
				hex = qualityColor:GenerateHexColorMarkup();
			elseif(qualityColor) then
				hex = FormatHex(qualityColor.r, qualityColor.g, qualityColor.b);
			else
				hex = "|cffffffff";
			end
			local iconMarkup = petInfo.icon and ("|T" .. tostring(petInfo.icon) .. ":" .. TOOLTIP_ICON_SIZE .. ":" .. TOOLTIP_ICON_SIZE .. ":0:0|t ") or "";
			local name = petInfo.name or "Unknown";
			GameTooltip:AddLine(iconMarkup .. hex .. name .. "|r", 1, 1, 1);
			shown = shown + 1;
		end
	end

	if(#allNames > shown) then
		GameTooltip:AddLine("+" .. tostring(#allNames - shown) .. " more", 0.84, 0.84, 0.90);
	end
end

local function EnsureSpeciesLines(frame)
	if(not frame) then
		return nil;
	end

	frame.speciesLines = frame.speciesLines or {};
	for index = 1, MAX_VISIBLE_ZONE_LINES do
		if(not frame.speciesLines[index]) then
			local line = CreateFrame("Frame", nil, frame);
			line:SetSize(182, 14);
			if(index == 1) then
				line:SetPoint("TOPLEFT", frame.bar, "BOTTOMLEFT", 0, -4);
				line:SetPoint("TOPRIGHT", frame.bar, "BOTTOMRIGHT", 0, -4);
			else
				line:SetPoint("TOPLEFT", frame.speciesLines[index - 1], "BOTTOMLEFT", 0, -2);
				line:SetPoint("TOPRIGHT", frame.speciesLines[index - 1], "BOTTOMRIGHT", 0, -2);
			end

			line.icon = line:CreateTexture(nil, "ARTWORK");
			line.icon:SetSize(14, 14);
			line.icon:SetPoint("LEFT", line, "LEFT", 0, 0);

			line.subIcon = line:CreateTexture(nil, "OVERLAY");
			line.subIcon:SetSize(10, 10);
			line.subIcon:SetPoint("BOTTOMRIGHT", line.icon, "BOTTOMRIGHT", 1, -1);

			line.text = line:CreateFontString(nil, "OVERLAY", "PetBuddyFontSmall");
			line.text:SetPoint("LEFT", line.icon, "RIGHT", 4, 0);
			line.text:SetPoint("RIGHT", line, "RIGHT", 0, 0);
			line.text:SetJustifyH("LEFT");
			line.text:SetWordWrap(false);

			frame.speciesLines[index] = line;
		end
	end

	return frame.speciesLines;
end

local function HideSpeciesLines(frame)
	if(not frame or not frame.speciesLines) then
		return;
	end

	for _, line in ipairs(frame.speciesLines) do
		line:Hide();
	end
end

local function GetDisplaySpeciesEntries(snapshot)
	local allNames = snapshot.allNames or {};
	local prioritized, fallback = {}, {};

	for _, petInfo in ipairs(allNames) do
		if((tonumber(petInfo.quality) or 0) <= 0) then
			prioritized[#prioritized + 1] = petInfo;
		else
			fallback[#fallback + 1] = petInfo;
		end
	end

	if(#prioritized == 0) then
		prioritized = fallback;
	end

	return prioritized;
end

local function UpdateSpeciesLines(frame, snapshot)
	local lines = EnsureSpeciesLines(frame);
	if(not lines) then
		return 0;
	end

	HideSpeciesLines(frame);
	if(snapshot.state ~= "ready") then
		return 0;
	end

	local entries = GetDisplaySpeciesEntries(snapshot);
	local shownCount = math.min(MAX_VISIBLE_ZONE_LINES, #entries);
	for index = 1, shownCount do
		local entry = entries[index];
		local line = lines[index];
		local quality = tonumber(entry.quality) or 0;
		local color = quality > 0 and GetPetQualityColor(quality) or nil;

		line.icon:SetTexture(entry.icon or GetSpeciesIcon(entry.speciesID) or "Interface\\Icons\\INV_Misc_QuestionMark");
		line.subIcon:SetShown(entry.sourceIcon ~= nil);
		if(entry.sourceIcon) then
			line.subIcon:SetTexture(entry.sourceIcon);
		end

		line.text:SetText(entry.name or "Unknown");
		if(color) then
			line.text:SetTextColor(color.r, color.g, color.b);
		else
			line.text:SetTextColor(1.0, 0.78, 0.78);
		end
		line:Show();
	end

	if(#entries > shownCount and shownCount > 0) then
		local line = lines[shownCount];
		line.text:SetText((line.text:GetText() or "") .. " +" .. tostring(#entries - shownCount) .. " more");
	end

	return shownCount;
end

local function ResolveZoneProgress()
	if(not C_Map or type(C_Map.GetBestMapForUnit) ~= "function") then
		return {
			state = "unavailable",
			title = ZONE_TRACKER_TITLE,
			detail = "Map data unavailable on this client.",
			provider = nil,
		};
	end

	local currentMapID = C_Map.GetBestMapForUnit("player");
	if(not currentMapID) then
		return {
			state = "unavailable",
			title = ZONE_TRACKER_TITLE,
			detail = "Current zone is unavailable right now.",
			provider = nil,
		};
	end

	local mapID = currentMapID;
	local bestKnownMapName = GetMapName(currentMapID) or ZONE_TRACKER_TITLE;
	while(mapID and mapID > 0) do
		local data = GetPetTrackerSnapshotForMap(mapID) or GetNativeProgressForMap(mapID);
		if(data) then
			data.state = "ready";
			data.title = data.mapName or bestKnownMapName;
			return data;
		end

		local mapInfo = C_Map.GetMapInfo(mapID);
		local parentMapID = mapInfo and mapInfo.parentMapID;
		if(not parentMapID or parentMapID == 0 or parentMapID == mapID) then
			break;
		end
		mapID = parentMapID;
	end

	local aliasMapID = MAP_ALIASES[currentMapID];
	if(aliasMapID and aliasMapID ~= currentMapID) then
		local aliasData = GetPetTrackerSnapshotForMap(aliasMapID) or GetNativeProgressForMap(aliasMapID);
		if(aliasData) then
			aliasData.state = "ready";
			aliasData.title = bestKnownMapName;
			aliasData.resolvedMapID = aliasMapID;
			return aliasData;
		end

		if(addon.ZoneSpeciesByMap and addon.ZoneSpeciesByMap[aliasMapID]) then
			return {
				state = "empty",
				title = bestKnownMapName,
				detail = "No trackable wild pets found for this zone.",
				provider = "native",
				resolvedMapID = aliasMapID,
			};
		end

		if(GetPetTrackerSnapshotForMap(aliasMapID)) then
			return {
				state = "empty",
				title = bestKnownMapName,
				detail = "No trackable wild pets found for this zone.",
				provider = "PetTracker",
				resolvedMapID = aliasMapID,
			};
		end
	end

	if(addon.ZoneSpeciesByMap and addon.ZoneSpeciesByMap[currentMapID]) then
		return {
			state = "empty",
			title = bestKnownMapName,
			detail = "No trackable wild pets found for this zone.",
			provider = "native",
		};
	end

	if(GetPetTrackerSnapshotForMap(currentMapID)) then
		return {
			state = "empty",
			title = bestKnownMapName,
			detail = "No trackable wild pets found for this zone.",
			provider = "PetTracker",
		};
	end

	return {
		state = "unavailable",
		title = bestKnownMapName,
		detail = "No zone pet data is available for this zone yet.",
		provider = nil,
	};
end

function addon:GetZoneTrackerSnapshot()
	return ResolveZoneProgress();
end

function addon:GetZoneTrackerAnchorTarget()
	if(addon and addon.db and addon.db.global.HideMainGUI == true) then
		return PetBuddyFrameTitle;
	end

	local utilityState = tonumber(addon.db.global.PetUtilityMenuState) or 0;
	local showItems = (utilityState == 1 or utilityState == 3);
	local showLoadouts = (utilityState == 2 or utilityState == 3);

	if(showLoadouts and PetBuddyFrameLoadouts) then
		local scrollFrame = PetBuddyFrameLoadouts.scrollFrame or rawget(_G, "PetBuddyFrameLoadoutsScrollFrame");
		if(scrollFrame and scrollFrame:IsShown()) then
			return scrollFrame;
		end

		return PetBuddyFrameLoadouts;
	end

	if(showItems and PetBuddyFrameButtons) then
		return PetBuddyFrameButtons;
	end

	return PetBuddyFramePet3;
end

function addon:RefreshZoneTrackerAnchor()
	local frame = PetBuddyFrameZoneTracker;
	if(not frame) then
		return;
	end

	local anchorTarget = self:GetZoneTrackerAnchorTarget();
	if(not anchorTarget) then
		return;
	end

	frame:ClearAllPoints();

	-- Anchor below the element that is actually visible:
	-- title bar, expanded loadout list, bottom utility row, or Pet3.
	local utilityState = tonumber(addon.db.global.PetUtilityMenuState) or 0;
	local showItems = (utilityState == 1 or utilityState == 3);
	local showLoadouts = (utilityState == 2 or utilityState == 3);
	local hideMain = addon and addon.db and addon.db.global.HideMainGUI == true;

	local yOffset;
	if(hideMain) then
		yOffset = -2;
	elseif(anchorTarget == (PetBuddyFrameLoadouts and PetBuddyFrameLoadouts.scrollFrame) or anchorTarget == rawget(_G, "PetBuddyFrameLoadoutsScrollFrame")) then
		yOffset = -6;
	elseif(showItems or showLoadouts) then
		yOffset = -6;
	else
		yOffset = -2;
	end

	frame:SetPoint("TOPLEFT", anchorTarget, "BOTTOMLEFT", 0, yOffset);
end

function addon:RefreshZoneTracker()
	-- Debounce: prevent calls from firing too rapidly
	local now = GetTime();
	if(self._lastZoneTrackerRefresh and (now - self._lastZoneTrackerRefresh) < 0.1) then
		return;
	end
	self._lastZoneTrackerRefresh = now;

	local frame = PetBuddyFrameZoneTracker;
	if(not frame or not self.db or not self.db.global) then
		return;
	end

	self:RefreshZoneTrackerAnchor();

	local minimized = self:IsFrameMinimized();
	local hideMain = self.db.global.HideMainGUI == true;

	-- Hide zone tracker when minimized (minimize hides everything except title bar)
	local shouldShow = self.db.global.ShowZoneTracker and not minimized;
	if(not shouldShow) then
		frame:Hide();
		return;
	end

	local snapshot = self:GetZoneTrackerSnapshot();
	frame.snapshot = snapshot;
	frame.label:SetText(snapshot.title or ZONE_TRACKER_TITLE);
	ApplyProgressBarTexture(frame);
	if(frame.bar and frame.bar.text) then
		frame.bar.text:SetText("");
		frame.bar.text:Show();
	end
	if(frame.hint) then
		frame.hint:SetText("");
		frame.hint:Hide();
	end
	if(frame.petsText) then
		frame.petsText:SetText("");
		frame.petsText:Hide();
	end
	local visibleLines = 0;

	if(snapshot.state == "ready") then
		frame.value:SetFormattedText("%d / %d", snapshot.owned or 0, snapshot.total or 1);
		frame.bar:Show();
		frame.bar:SetMinMaxValues(0, math.max(1, snapshot.total or 1));
		frame.bar:SetValue(math.max(0, snapshot.owned or 0));
		if(frame.bar.text) then
			frame.bar.text:SetFormattedText("%d%% complete", math.floor((snapshot.percent or 0) * 100 + 0.5));
		end
		frame.bar:SetStatusBarColor(0.20, 0.20, 0.24, 1.0);
		UpdateQualityBars(frame, snapshot);
		-- When main GUI is hidden, zone tracker shows compact view (no species list)
		local hideMain = addon and addon.db and addon.db.global.HideMainGUI == true;
		if(not hideMain and self.db.global.ShowZoneTrackerPetList ~= false) then
			visibleLines = UpdateSpeciesLines(frame, snapshot);
		else
			HideSpeciesLines(frame);
		end
	elseif(snapshot.state == "empty") then
		frame.value:SetText("0 / 0");
		frame.bar:Show();
		frame.bar:SetMinMaxValues(0, 1);
		frame.bar:SetValue(0);
		if(frame.bar.text) then
			frame.bar.text:SetText("No zone pets");
		end
		frame.bar:SetStatusBarColor(0.36, 0.36, 0.42, 1.0);
		UpdateQualityBars(frame, snapshot);
		HideSpeciesLines(frame);
	else
		frame.value:SetText("--");
		frame.bar:Show();
		frame.bar:SetMinMaxValues(0, 1);
		frame.bar:SetValue(0);
		if(frame.bar.text) then
			frame.bar.text:SetText("Unavailable");
		end
		frame.bar:SetStatusBarColor(0.30, 0.30, 0.36, 1.0);
		UpdateQualityBars(frame, snapshot);
		HideSpeciesLines(frame);
	end

	local zoneHeight = 30 + (visibleLines > 0 and (visibleLines * 16 + 2) or 0);
	frame:SetHeight(zoneHeight);

	-- Update main frame height to accommodate zone tracker expansion
	if(PetBuddyFrame and type(PetBuddyFrame.SetHeight) == "function") then
		local minimized = addon and addon:IsFrameMinimized();
		local hideMain = addon and addon.db and addon.db.global.HideMainGUI == true;
		if(hideMain) then
			local titleHeight = 24;
			if(PetBuddyFrameTitle and type(PetBuddyFrameTitle.GetHeight) == "function") then
				titleHeight = PetBuddyFrameTitle:GetHeight() or titleHeight;
			end
			PetBuddyFrame:SetHeight(titleHeight + zoneHeight + 6);
		elseif(minimized) then
			-- Minimized: zone tracker is hidden, just use title height
			local titleHeight = 24;
			if(PetBuddyFrameTitle and type(PetBuddyFrameTitle.GetHeight) == "function") then
				titleHeight = PetBuddyFrameTitle:GetHeight() or titleHeight;
			end
			PetBuddyFrame:SetHeight(titleHeight + 6);
		else
			-- For expanded state, recalculate using the stored expanded height
			if(addon and addon.ExpandedFrameHeight) then
				local zoneExtra = zoneHeight - 30;
				PetBuddyFrame:SetHeight(addon.ExpandedFrameHeight + zoneExtra);
			end
		end
	end

	frame:Show();
end

function PetBuddy_ZoneTrackerMixin:OnEnter()
	local snapshot = self.snapshot or addon:GetZoneTrackerSnapshot();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:ClearLines();
	local logoPath = addon.LOGO_TEXTURE or "Interface\\AddOns\\PetBuddy2\\Media\\logo.tga";
	GameTooltip:AddLine("|T" .. logoPath .. ":18:18:0:0|t |cffb512fcP|r|cffffffffet|r|cffb512fcB|r|cffffffffuddy|r|cffb512fc2|r  |cffb07fff" .. ZONE_TRACKER_TITLE .. "|r");

	if(snapshot.state == "ready") then
		GameTooltip:AddDoubleLine("Zone", snapshot.title or "-", 1, 1, 1, 0.9, 0.9, 0.9);
		GameTooltip:AddDoubleLine("Collected", string.format("%d / %d", snapshot.owned or 0, snapshot.total or 0), 1, 1, 1, 0.9, 0.9, 0.9);
		GameTooltip:AddDoubleLine("Progress", string.format("%d%%", math.floor((snapshot.percent or 0) * 100 + 0.5)), 1, 1, 1, 0.9, 0.9, 0.9);
		AddTooltipPetLines(GameTooltip, snapshot);
	elseif(snapshot.state == "empty") then
		GameTooltip:AddDoubleLine("Zone", snapshot.title or "-", 1, 1, 1, 0.9, 0.9, 0.9);
		GameTooltip:AddLine(snapshot.detail or "", 0.9, 0.9, 0.9, true);
	elseif(snapshot.detail) then
		GameTooltip:AddDoubleLine("Zone", snapshot.title or "-", 1, 1, 1, 0.9, 0.9, 0.9);
		GameTooltip:AddLine(snapshot.detail, 0.9, 0.9, 0.9, true);
	end

	GameTooltip:Show();
end

function PetBuddy_ZoneTrackerMixin:OnLeave()
	GameTooltip:Hide();
end

function PetBuddy_ZoneTrackerMixin:OnMouseUp(button)
	if(button == "RightButton" and type(addon.OpenContextMenu) == "function") then
		GameTooltip:Hide();
		addon:OpenContextMenu(nil, self, "cursor", "TOPLEFT", "CENTER");
	end
end
