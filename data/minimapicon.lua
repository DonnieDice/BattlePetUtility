local ADDON_NAME, addon = ...
local RGX = _G.RGXFramework

local DEFAULT_ANGLE = 215

local function GetMinimapStorage()
    if not addon.db or not addon.db.global then return nil end
    addon.db.global.MinimapIcon = addon.db.global.MinimapIcon or {}
    return addon.db.global.MinimapIcon
end

function addon:InitializeMinimapIcon()
    local MM = RGX:GetMinimap()
    if not MM then return end

    self.minimapBtn = MM:Create({
        name         = "PetBuddy2MinimapButton",
        icon         = self.LOGO_TEXTURE or "Interface\\AddOns\\PetBuddy2\\media\\logo.tga",
        defaultAngle = DEFAULT_ANGLE,
        iconOffsetX  = 1,
        iconOffsetY  = -2,

        getAngle = function()
            local s = GetMinimapStorage()
            return s and tonumber(s.angle) or DEFAULT_ANGLE
        end,
        setAngle = function(v)
            local s = GetMinimapStorage()
            if s then s.angle = v end
        end,

        tooltip = {
            title       = "|TInterface\\AddOns\\PetBuddy2\\media\\logo.tga:18:18:0:0|t |cffb512fcPetBuddy2|r |cffd9c6ffBattle Pet HUD|r",
            description = "|cffd9c6ffYour compact pet team, loadouts, and tracker hub.|r",
            lines = {
                { left = "|cffb512fcLeft-Click|r",       right = "Show or hide PetBuddy2" },
                { left = "|cff4ecdc4Right-Click|r",      right = "Open options" },
                { left = "|cffe67e22Drag|r",             right = "Move around minimap" },
                { left = "|cffe74c3cCtrl+Right-Click|r", right = "Hide minimap icon" },
            },
        },

        onLeftClick  = function() TogglePetBuddy() end,
        onRightClick = function(btn) addon:OpenContextMenu(nil, btn.frame, btn.frame, "TOPLEFT", "BOTTOMLEFT") end,
        onCtrlRight  = function() addon:ToggleMinimapIcon(false) end,
    })
end

function addon:UpdateMinimapIconVisibility()
    if not self.minimapBtn then
        self:InitializeMinimapIcon()
    end
    if not self.minimapBtn then return end

    local s = GetMinimapStorage()
    self.minimapBtn:SetVisible(not s or s.enabled ~= false)
end
