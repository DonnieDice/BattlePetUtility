local ADDON_NAME, addon = ...

local function TryLoadDropDownAPI()
	if type(UIDropDownMenu_Initialize) == "function" and type(UIDropDownMenu_AddButton) == "function" then
		return true
	end

	local loadAddon = nil
	if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
		loadAddon = C_AddOns.LoadAddOn
	elseif type(LoadAddOn) == "function" then
		loadAddon = LoadAddOn
	end

	if loadAddon then
		pcall(loadAddon, "Blizzard_UIDropDownMenu")
		pcall(loadAddon, "Blizzard_Deprecated")
	end

	return type(UIDropDownMenu_Initialize) == "function" and type(UIDropDownMenu_AddButton) == "function"
end

function addon.RefreshDropdownMenu(menuFrame)
	if not menuFrame then
		if type(addon) == "table" and addon.ContextMenu then
			menuFrame = addon.ContextMenu
		end
	end

	if type(UIDropDownMenu_Refresh) == "function" and menuFrame then
		pcall(UIDropDownMenu_Refresh, menuFrame)
	elseif type(CloseDropDownMenus) == "function" then
		pcall(CloseDropDownMenus)
	end
end

local function SuppressDropDownFrameVisuals(menuFrame)
	if not menuFrame then
		return
	end

	local frameName = menuFrame.GetName and menuFrame:GetName()
	if type(frameName) == "string" and frameName ~= "" then
		for _, suffix in ipairs({ "Left", "Middle", "Right", "Button", "Text", "Icon" }) do
			local region = _G[frameName .. suffix]
			if region then
				if region.Hide then
					region:Hide()
				end
				if region.SetAlpha then
					region:SetAlpha(0)
				end
			end
		end
	end

	if menuFrame.SetWidth then
		menuFrame:SetWidth(1)
	end
	if menuFrame.SetHeight then
		menuFrame:SetHeight(1)
	end
end

local function CreateMenuInfo(entry)
	if type(entry) ~= "table" then
		return entry
	end

	local info
	if type(UIDropDownMenu_CreateInfo) == "function" then
		info = UIDropDownMenu_CreateInfo()
	else
		info = {}
	end

	for k, v in pairs(entry) do
		info[k] = v
	end

	if type(entry.menuList) == "table" then
		info.hasArrow = true
		info.menuList = entry.menuList
		info.value = entry.value or entry.menuList
	elseif type(entry.menuList) == "string" and entry.menuList ~= "" then
		info.hasArrow = true
		info.menuList = entry.menuList
		info.value = info.value or entry.menuList
	end

	return info
end

local function InitializeMenuLevel(self, level, menuList)
	level = level or 1
	local currentList

	if menuList == "pb2_fonts" then
		currentList = addon._fontMenuItems
	elseif type(menuList) == "table" then
		currentList = menuList
	else
		currentList = self._pbMenuData
	end

	if type(currentList) ~= "table" then
		return
	end

	for _, entry in ipairs(currentList) do
		if type(entry) == "table" then
			local info = CreateMenuInfo(entry)
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function addon:OpenContextMenu(contextMenuData, parentframe, anchor, point, relativePoint)
	if not addon.ContextMenu then
		addon.ContextMenu = CreateFrame("Frame", "PetBuddyContextMenuFrame", UIParent, "UIDropDownMenuTemplate")
		addon.ContextMenu:SetFrameStrata("DIALOG")
		SuppressDropDownFrameVisuals(addon.ContextMenu)
	end

	if not contextMenuData then
		contextMenuData = addon:GetPrimaryMenuData()
	end

	addon.ContextMenu:ClearAllPoints()
	addon.ContextMenu:SetPoint(point or "TOPLEFT", parentframe or PetBuddyFrame, relativePoint or "CENTER", 0, 5)
	addon:OpenDropDownMenu(contextMenuData, addon.ContextMenu, anchor or "cursor", 0, 0, "MENU", 5)
end

function addon:OpenDropDownMenu(menuData, menuFrame, anchor, x, y, displayMode, autoHideDelay)
	if type(menuData) ~= "table" or not menuFrame then
		return false
	end

	if not TryLoadDropDownAPI() then
		if type(addon.PrintMessage) == "function" then
			addon:PrintMessage("|cffff5555Dropdown menu API unavailable on this client.|r")
		end
		return false
	end

	menuFrame._pbMenuData = menuData

	local okInit = pcall(UIDropDownMenu_Initialize, menuFrame, InitializeMenuLevel, displayMode or "MENU")
	if not okInit then
		if type(addon.PrintMessage) == "function" then
			addon:PrintMessage("|cffff5555Unable to initialize dropdown menu.|r")
		end
		return false
	end

	if type(ToggleDropDownMenu) == "function" then
		local okToggle = pcall(ToggleDropDownMenu, 1, nil, menuFrame, anchor or "cursor", x or 0, y or 0, menuData, nil, autoHideDelay or 5)
		return okToggle == true
	end

	return false
end
