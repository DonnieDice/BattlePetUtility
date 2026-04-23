--[[
	PetBuddy2 Minimap Icon
	Standalone, no LibDBIcon dependency — keeps PB2's zero-library promise.

	- Uses media/logo.tga for the icon face
	- Draggable around the Minimap on a circle
	- Left click toggles the PetBuddy2 frame
	- Right click opens the options context menu
	- Saved state: db.global.MinimapIcon = { enabled, angle, radius }
]]

local ADDON_NAME, addon = ...;

local BUTTON_NAME = "PetBuddy2MinimapButton";
local DEFAULT_ANGLE = 215;
local ICON_TEXTURE = (addon and addon.LOGO_TEXTURE) or "Interface\\AddOns\\PetBuddy2\\media\\logo.tga";
local TOOLTIP_ICON = "|TInterface\\AddOns\\PetBuddy2\\media\\logo.tga:18:18:0:0|t ";
local TOOLTIP_TITLE = TOOLTIP_ICON .. "|cffb512fcPetBuddy2|r |cffd9c6ffBattle Pet HUD|r";

local function EnsureSavedDefaults()
	if(not addon.db or not addon.db.global) then
		return nil;
	end

	addon.db.global.MinimapIcon = addon.db.global.MinimapIcon or {};
	local saved = addon.db.global.MinimapIcon;
	if(saved.enabled == nil) then
		saved.enabled = true;
	end
	saved.angle = tonumber(saved.angle) or DEFAULT_ANGLE;
	return saved;
end

local function PlaceButton(button)
	local saved = EnsureSavedDefaults();
	if(not saved or not Minimap) then
		return;
	end

	local angle = math.rad(saved.angle);
	local minimapRadius = (Minimap:GetWidth() or 140) / 2 + 10;
	local x = math.cos(angle) * minimapRadius;
	local y = math.sin(angle) * minimapRadius;

	button:ClearAllPoints();
	button:SetPoint("CENTER", Minimap, "CENTER", x, y);
end

local function UpdateAngleFromCursor(button)
	if(not Minimap) then
		return;
	end

	local mx, my = Minimap:GetCenter();
	local scale = Minimap:GetEffectiveScale();
	local cx, cy = GetCursorPosition();
	cx = cx / scale;
	cy = cy / scale;

	if(not mx or not my) then
		return;
	end

	local deg = math.deg(math.atan2(cy - my, cx - mx));
	if(deg < 0) then
		deg = deg + 360;
	end

	local saved = EnsureSavedDefaults();
	if(saved) then
		saved.angle = deg;
	end

	PlaceButton(button);
end

local function ShowTooltip(button)
	if(not GameTooltip) then
		return;
	end

	GameTooltip:SetOwner(button, "ANCHOR_LEFT");
	GameTooltip:ClearLines();
	GameTooltip:AddLine(TOOLTIP_TITLE);
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cffd9c6ffYour compact pet team, loadouts, and tracker hub.|r", 1, 1, 1, true);
	GameTooltip:AddLine(" ");
	GameTooltip:AddDoubleLine("|cffb512fcLeft-Click|r", "|cffffffffShow or hide PetBuddy2|r", 0.95, 0.80, 1.0, 1.0, 1.0, 1.0);
	GameTooltip:AddDoubleLine("|cff4ecdc4Right-Click|r", "|cffffffffOpen options|r", 0.45, 0.90, 0.86, 1.0, 1.0, 1.0);
	GameTooltip:AddDoubleLine("|cffe67e22Drag|r", "|cffffffffMove around minimap|r", 0.90, 0.49, 0.13, 1.0, 1.0, 1.0);
	GameTooltip:AddDoubleLine("|cffe74c3cCtrl+Right-Click|r", "|cffffffffHide minimap icon|r", 0.90, 0.20, 0.20, 1.0, 1.0, 1.0);
	GameTooltip:Show();
end

local function CreateMinimapButton()
	if(_G[BUTTON_NAME]) then
		return _G[BUTTON_NAME];
	end

	if(not Minimap) then
		return nil;
	end

	local button = CreateFrame("Button", BUTTON_NAME, Minimap);
	button:SetFrameStrata("MEDIUM");
	button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8);
	button:SetSize(32, 32);
	button:SetMovable(true);
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:RegisterForDrag("LeftButton");

	local backdrop = button:CreateTexture(nil, "BACKGROUND");
	backdrop:SetSize(24, 24);
	backdrop:SetPoint("CENTER", button, "CENTER", 1, 0);
	backdrop:SetTexture("Interface\\Buttons\\WHITE8X8");
	if(backdrop.SetMask) then
		backdrop:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMaskSmall");
	end
	backdrop:SetVertexColor(0.03, 0.03, 0.03, 0.98);
	button.backdrop = backdrop;

	local overlay = button:CreateTexture(nil, "OVERLAY");
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");
	overlay:SetSize(54, 54);
	overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
	button.overlay = overlay;

	local icon = button:CreateTexture(nil, "ARTWORK");
	icon:SetTexture(ICON_TEXTURE);
	icon:SetSize(19, 19);
	icon:SetPoint("CENTER", button, "CENTER", 1, -2);
	icon:SetTexCoord(0.02, 0.98, 0.02, 0.98);
	button.icon = icon;

	button:SetScript("OnEnter", function(self)
		if(not self.isDragging) then
			ShowTooltip(self);
		end
	end);

	button:SetScript("OnLeave", function()
		if(GameTooltip) then
			GameTooltip:Hide();
		end
	end);

	button:SetScript("OnClick", function(self, btn)
		if(self.isDragging) then
			return;
		end

		-- Handle Ctrl+Right-click to hide the minimap icon
		if(btn == "RightButton" and IsControlKeyDown()) then
			if(GameTooltip) then
				GameTooltip:Hide();
			end
			if(type(addon.ToggleMinimapIcon) == "function") then
				addon:ToggleMinimapIcon(false);
			end
			return;
		end

		if(btn == "RightButton") then
			if(GameTooltip) then
				GameTooltip:Hide();
			end
			if(type(addon.OpenContextMenu) == "function") then
				addon:OpenContextMenu(nil, self, self, "TOPLEFT", "BOTTOMLEFT");
			end
		else
			if(type(TogglePetBuddy) == "function") then
				TogglePetBuddy();
			end
		end
	end);

	button:SetScript("OnDragStart", function(self)
		self.isDragging = true;
		if(GameTooltip) then
			GameTooltip:Hide();
		end
		self:SetScript("OnUpdate", function(s)
			UpdateAngleFromCursor(s);
		end);
	end);

	button:SetScript("OnDragStop", function(self)
		self.isDragging = false;
		self:SetScript("OnUpdate", nil);
		PlaceButton(self);
	end);

	return button;
end

function addon:UpdateMinimapIconVisibility()
	local saved = EnsureSavedDefaults();
	local button = _G[BUTTON_NAME] or CreateMinimapButton();
	if(not button) then
		return;
	end

	if(saved and saved.enabled) then
		PlaceButton(button);
		button:Show();
	else
		button:Hide();
	end
end

function addon:InitializeMinimapIcon()
	local button = CreateMinimapButton();
	if(not button) then
		return;
	end

	addon:UpdateMinimapIconVisibility();
end
