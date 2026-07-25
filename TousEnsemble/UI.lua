-- Tous ensemble - interface serveur inspirée du Dungeon Finder de G.B.G.

local TE = TousEnsemble
local floor = math.floor
local max = math.max
local min = math.min
local sort = table.sort
local tonumber = tonumber
local tostring = tostring
local strlower = string.lower
local time = time
local date = date

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = {left = 1, right = 1, top = 1, bottom = 1},
}
local PANEL = {0.035, 0.040, 0.065, 0.985}
local PANEL_2 = {0.060, 0.065, 0.100, 0.98}
local PANEL_3 = {0.085, 0.090, 0.135, 0.98}
local BORDER = {0.23, 0.20, 0.38, 1}
local ACCENT = {0.60, 0.42, 1.00, 1}
local ACCENT_DARK = {0.30, 0.19, 0.52, 1}
local TEXT = {0.91, 0.92, 0.97, 1}
local MUTED = {0.52, 0.55, 0.67, 1}
local GREEN = {0.28, 0.90, 0.57, 1}
local RED = {0.96, 0.34, 0.43, 1}
local GOLD = {1.00, 0.78, 0.30, 1}
local BLUE = {0.30, 0.70, 1.00, 1}
local ROLE_ORDER = {tank = 1, heal = 2, dps = 3, support = 4}

local ACTIVITY_TYPES = {
    PVE = {
        {id = "XP_DUNGEON", fr = "Donjon", en = "Dungeon"},
        {id = "RAID", fr = "Raid", en = "Raid"},
        {id = "QUEST", fr = "Quêtes", en = "Quests"},
        {id = "FARM", fr = "Farm", en = "Farm"},
        {id = "WORLD_BOSS", fr = "Boss mondial", en = "World boss"},
        {id = "OTHER_PVE", fr = "Autre JcE", en = "Other PvE"},
    },
    PVP = {
        {id = "XP_BATTLEGROUND", fr = "Champ de bataille", en = "Battleground"},
        {id = "ARENA", fr = "Arène", en = "Arena"},
        {id = "WORLD_PVP", fr = "JcJ sauvage", en = "World PvP"},
        {id = "DUEL", fr = "Duels", en = "Duels"},
        {id = "OTHER_PVP", fr = "Autre JcJ", en = "Other PvP"},
    },
}

local function Backdrop(frame, background, border)
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(unpack(background or PANEL))
    frame:SetBackdropBorderColor(unpack(border or BORDER))
end

local function Text(parent, fontObject, value, size)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    if size then
        local font, _, flags = fs:GetFont()
        if font then fs:SetFont(font, size, flags) end
    end
    fs:SetText(value or "")
    fs:SetTextColor(unpack(TEXT))
    return fs
end

local function SetFontSize(fontString, size)
    local font, _, flags = fontString:GetFont()
    if font then fontString:SetFont(font, size, flags) end
end

local function SetSelected(button, selected)
    button.selected = selected == true
    if button.selected then
        button:SetBackdropColor(unpack(ACCENT_DARK))
        button:SetBackdropBorderColor(unpack(ACCENT))
        if button.label then button.label:SetTextColor(1, 1, 1, 1) end
    else
        button:SetBackdropColor(unpack(PANEL_2))
        button:SetBackdropBorderColor(unpack(BORDER))
        if button.label then button.label:SetTextColor(unpack(TEXT)) end
    end
end

local function ShowWhen(frame, visible)
    if visible then frame:Show() else frame:Hide() end
end

local function SetEnabled(button, enabled)
    button.disabled = not enabled
    button:SetAlpha(enabled and 1 or 0.42)
    if enabled then button:Enable() else button:Disable() end
end

local function SetButtonText(button, value)
    if button and button.label then button.label:SetText(value or "") end
end

local function Tooltip(frame, textProvider)
    frame:SetScript("OnEnter", function(self)
        local value = type(textProvider) == "function" and textProvider(self) or textProvider
        if value and value ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(value, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function FlatButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width or 120)
    button:SetHeight(height or 30)
    Backdrop(button, PANEL_2, BORDER)
    button.label = Text(button, "GameFontNormal", label or "", 12)
    button.label:SetPoint("LEFT", 8, 0)
    button.label:SetPoint("RIGHT", -8, 0)
    button.label:SetJustifyH("CENTER")
    button:SetScript("OnEnter", function(self)
        if not self.disabled and not self.selected then self:SetBackdropColor(unpack(PANEL_3)); self:SetBackdropBorderColor(unpack(ACCENT)) end
    end)
    button:SetScript("OnLeave", function(self)
        if not self.disabled then SetSelected(self, self.selected) end
    end)
    return button
end

local function IconButton(parent, texture, width, height)
    local button = FlatButton(parent, "", width, height)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetTexture(texture)
    button.icon:SetPoint("CENTER")
    button.icon:SetWidth((width or 30) - 10)
    button.icon:SetHeight((height or 30) - 10)
    return button
end

local function Input(parent, width, height, multiline)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetWidth(width)
    holder:SetHeight(height)
    Backdrop(holder, PANEL_2, BORDER)
    local edit = CreateFrame("EditBox", nil, holder)
    edit:SetPoint("TOPLEFT", 9, -7)
    edit:SetPoint("BOTTOMRIGHT", -9, 7)
    edit:SetAutoFocus(false)
    edit:SetFontObject(multiline and "ChatFontNormal" or "GameFontHighlight")
    edit:SetTextColor(unpack(TEXT))
    edit:SetMaxLetters(multiline and 700 or 90)
    edit:SetMultiLine(multiline == true)
    if multiline then edit:SetJustifyV("TOP") end
    holder.editBox = edit
    return holder, edit
end

local function Toggle(parent, label, width)
    local button = FlatButton(parent, label, width or 220, 30)
    button.checked = false
    button.box = button:CreateTexture(nil, "ARTWORK")
    button.box:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.box:SetWidth(14)
    button.box:SetHeight(14)
    button.box:SetPoint("LEFT", 8, 0)
    button.box:SetVertexColor(unpack(PANEL_3))
    button.mark = button:CreateTexture(nil, "OVERLAY")
    button.mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    button.mark:SetWidth(20)
    button.mark:SetHeight(20)
    button.mark:SetPoint("CENTER", button.box, "CENTER", 0, 0)
    button.label:ClearAllPoints()
    button.label:SetPoint("LEFT", button.box, "RIGHT", 7, 0)
    button.label:SetPoint("RIGHT", -7, 0)
    button.label:SetJustifyH("LEFT")
    function button:SetChecked(value)
        self.checked = value == true
        if self.checked then self.mark:Show() else self.mark:Hide() end
    end
    function button:GetChecked() return self.checked end
    button:SetScript("OnClick", function(self) self:SetChecked(not self:GetChecked()); if self.OnToggle then self:OnToggle(self:GetChecked()) end end)
    button:SetChecked(false)
    return button
end

local function SectionTitle(parent, value, x, y)
    local title = Text(parent, "GameFontNormal", value, 13)
    title:SetTextColor(unpack(ACCENT))
    title:SetPoint("TOPLEFT", x, y)
    return title
end

local function TypeLabel(activityType, category)
    local locale = TE:GetLocaleCode()
    for _, definition in ipairs(ACTIVITY_TYPES[category == "PVP" and "PVP" or "PVE"]) do
        if definition.id == activityType then return definition[locale] or definition.fr end
    end
    return activityType ~= "" and activityType or (category == "PVP" and TE:L("PVP") or TE:L("PVE"))
end

function TE:RegisterEscapeFrame(frameName)
    if not frameName or not UISpecialFrames then return end
    for _, registeredName in ipairs(UISpecialFrames) do
        if registeredName == frameName then return end
    end
    table.insert(UISpecialFrames, frameName)
end

function TE:CreateMainFrame()
    if self.mainFrame then return self.mainFrame end
    local frame = CreateFrame("Frame", "TousEnsembleMainFrame", UIParent)
    frame:SetWidth(1020)
    frame:SetHeight(680)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); TE:SaveFramePosition(self, "frame") end)
    Backdrop(frame, PANEL, ACCENT_DARK)
    self:ApplySavedPosition(frame, "frame")
    frame:SetScale(self.db.profile.uiScale or 1)
    self:RegisterEscapeFrame("TousEnsembleMainFrame")
    frame:SetScript("OnHide", function(self)
        self:SetAlpha(1)
        TE.adaptiveWindowAlpha = 1
        if TE.activityPopup then TE.activityPopup:Hide(); TE.activityPopup:SetAlpha(1) end
        if TE.guildAdPopup then TE.guildAdPopup:Hide(); TE.guildAdPopup:SetAlpha(1) end
    end)

    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", 1, -1)
    frame.header:SetPoint("TOPRIGHT", -1, -1)
    frame.header:SetHeight(72)
    Backdrop(frame.header, {0.055, 0.045, 0.095, 1}, ACCENT_DARK)

    frame.logo = frame.header:CreateTexture(nil, "ARTWORK")
    frame.logo:SetTexture(self:GetOwnAvatar())
    frame.logo:SetWidth(50)
    frame.logo:SetHeight(50)
    frame.logo:SetPoint("LEFT", 15, 0)

    frame.title = Text(frame.header, "GameFontNormal", self:L("BRAND"), 22)
    frame.title:SetPoint("TOPLEFT", frame.logo, "TOPRIGHT", 14, -5)
    frame.title:SetTextColor(unpack(ACCENT))
    frame.subtitle = Text(frame.header, "GameFontNormal", self:L("SUBTITLE"), 12)
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
    frame.subtitle:SetTextColor(unpack(MUTED))

    frame.close = FlatButton(frame.header, "×", 34, 34)
    frame.close:SetPoint("TOPRIGHT", -10, -10)
    SetFontSize(frame.close.label, 22)
    frame.close:SetScript("OnClick", function() frame:Hide() end)

    frame.tabs = {}
    local definitions = {
        {"activities", self:L("TAB_ACTIVITIES")},
        {"guilds", self:L("TAB_GUILDS")},
        {"applications", self:L("TAB_APPLICATIONS")},
        {"profile", self:L("TAB_PROFILE")},
    }
    for index, definition in ipairs(definitions) do
        local button = FlatButton(frame, definition[2], index == 3 and 155 or 140, 34)
        button:SetPoint("TOPLEFT", 18 + (index - 1) * 150, -81)
        button.tabKey = definition[1]
        button:SetScript("OnClick", function(self) TE:ShowTab(self.tabKey) end)
        frame.tabs[definition[1]] = button
    end

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", 18, -124)
    frame.content:SetPoint("BOTTOMRIGHT", -18, 39)
    Backdrop(frame.content, PANEL_2, BORDER)

    self.statusText = Text(frame, "GameFontNormal", "", 11)
    self.statusText:SetPoint("BOTTOMLEFT", 20, 13)
    self.statusText:SetTextColor(unpack(MUTED))
    frame.version = Text(frame, "GameFontNormal", "v" .. self.version, 10)
    frame.version:SetPoint("BOTTOMRIGHT", -20, 13)
    frame.version:SetTextColor(unpack(MUTED))

    self.mainFrame = frame
    return frame
end

function TE:ShowTab(key)
    if not self.mainFrame then return end
    key = self.mainFrame.tabs[key] and key or "activities"
    self.db.profile.lastTab = key
    for tabKey, button in pairs(self.mainFrame.tabs) do SetSelected(button, tabKey == key) end
    local pages = {self.activitiesPage, self.guildsPage, self.applicationsPage, self.profilePage}
    for _, page in ipairs(pages) do if page then page:Hide() end end
    if key == "activities" and self.activitiesPage then self.activitiesPage:Show(); self:RefreshActivitiesPage(true)
    elseif key == "guilds" and self.guildsPage then self.guildsPage:Show(); self:RefreshGuildSearchPage(true)
    elseif key == "applications" and self.applicationsPage then self.applicationsPage:Show(); self:RefreshApplicationsPage(true)
    elseif key == "profile" and self.profilePage then self.profilePage:Show(); self:RefreshProfilePage(true) end
end

function TE:Toggle()
    if not self.mainFrame then self:CreateUI() end
    if self.mainFrame:IsShown() then self.mainFrame:Hide()
    else self.mainFrame:Show(); self:ShowTab(self.db.profile.lastTab or "activities"); self:RefreshAll(true) end
end

-- --------------------------------------------------------------------------
-- Activities page
-- --------------------------------------------------------------------------
function TE:CreateActivitiesPage()
    if self.activitiesPage then return end
    local page = CreateFrame("Frame", nil, self.mainFrame.content)
    page:SetAllPoints()

    page.title = Text(page, "GameFontNormal", self:L("TAB_ACTIVITIES"), 18)
    page.title:SetPoint("TOPLEFT", 18, -16)
    page.title:SetTextColor(unpack(ACCENT))

    page.create = FlatButton(page, self:L("CREATE"), 170, 32)
    page.create:SetPoint("TOPRIGHT", -18, -12)
    page.create:SetScript("OnClick", function() TE:OpenActivityPopup(nil) end)

    page.refresh = FlatButton(page, self:L("REFRESH"), 105, 32)
    page.refresh:SetPoint("RIGHT", page.create, "LEFT", -8, 0)
    page.refresh:SetScript("OnClick", function() TE:RequestServerState(); TE:RequestGBGActivities(); TE:RefreshActivitiesPage(true) end)

    page.filterAll = FlatButton(page, self:L("FILTER_ALL"), 62, 30)
    page.filterAll:SetPoint("TOPLEFT", 185, -13)
    page.filterAll:SetScript("OnClick", function() TE.db.profile.feedFilter = "ALL"; TE:RefreshActivitiesPage(true); TE:RefreshProfilePage(false) end)
    Tooltip(page.filterAll, function() return TE:L("FILTER_HELP_ALL") end)
    page.filterFR = FlatButton(page, self:L("FILTER_FR"), 62, 30)
    page.filterFR:SetPoint("LEFT", page.filterAll, "RIGHT", 7, 0)
    page.filterFR:SetScript("OnClick", function() TE.db.profile.feedFilter = "FR"; TE:RefreshActivitiesPage(true); TE:RefreshProfilePage(false) end)
    Tooltip(page.filterFR, function() return TE:L("FILTER_HELP_FR") end)

    page.listPanel = CreateFrame("Frame", nil, page)
    page.listPanel:SetPoint("TOPLEFT", 14, -57)
    page.listPanel:SetPoint("BOTTOMLEFT", 14, 48)
    page.listPanel:SetWidth(535)
    Backdrop(page.listPanel, PANEL, BORDER)

    page.rows = {}
    for index = 1, 8 do
        local row = CreateFrame("Button", nil, page.listPanel)
        row:SetHeight(57)
        row:SetPoint("TOPLEFT", 8, -8 - (index - 1) * 61)
        row:SetPoint("TOPRIGHT", -8, -8 - (index - 1) * 61)
        Backdrop(row, PANEL_2, BORDER)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(40); row.icon:SetHeight(40); row.icon:SetPoint("LEFT", 8, 0)
        row.title = Text(row, "GameFontNormal", "", 13)
        row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 9, -4)
        row.title:SetPoint("RIGHT", -115, 0)
        row.title:SetJustifyH("LEFT")
        row.meta = Text(row, "GameFontNormal", "", 10)
        row.meta:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 9, 4)
        row.meta:SetPoint("RIGHT", -105, 0)
        row.meta:SetJustifyH("LEFT")
        row.meta:SetTextColor(unpack(MUTED))
        row.language = Text(row, "GameFontNormal", "", 11)
        row.language:SetPoint("TOPRIGHT", -10, -8)
        row.count = Text(row, "GameFontNormal", "", 11)
        row.count:SetPoint("BOTTOMRIGHT", -10, 8)
        row.count:SetTextColor(unpack(GREEN))
        row:SetScript("OnEnter", function(self) if not self.selected then self:SetBackdropColor(unpack(PANEL_3)); self:SetBackdropBorderColor(unpack(ACCENT)) end end)
        row:SetScript("OnLeave", function(self) if self.selected then self:SetBackdropColor(unpack(ACCENT_DARK)); self:SetBackdropBorderColor(unpack(ACCENT)) else self:SetBackdropColor(unpack(PANEL_2)); self:SetBackdropBorderColor(unpack(BORDER)) end end)
        row:SetScript("OnClick", function(self) if self.activityID then TE.selectedActivityID = self.activityID; TE:RefreshActivitiesPage(true) end end)
        page.rows[index] = row
    end

    page.empty = Text(page.listPanel, "GameFontNormal", self:L("NO_ACTIVITY"), 13)
    page.empty:SetPoint("CENTER", 0, 0)
    page.empty:SetWidth(450)
    page.empty:SetJustifyH("CENTER")
    page.empty:SetTextColor(unpack(MUTED))

    page.prev = FlatButton(page, self:L("PREVIOUS"), 105, 30)
    page.prev:SetPoint("BOTTOMLEFT", 14, 11)
    page.prev:SetScript("OnClick", function() page.pageIndex = max(1, (page.pageIndex or 1) - 1); TE:RefreshActivitiesPage(true) end)
    page.pageText = Text(page, "GameFontNormal", "", 11)
    page.pageText:SetPoint("BOTTOM", page.listPanel, "BOTTOM", 0, -30)
    page.pageText:SetTextColor(unpack(MUTED))
    page.next = FlatButton(page, self:L("NEXT"), 105, 30)
    page.next:SetPoint("BOTTOMRIGHT", page.listPanel, "BOTTOMRIGHT", 0, -37)
    page.next:SetScript("OnClick", function() page.pageIndex = (page.pageIndex or 1) + 1; TE:RefreshActivitiesPage(true) end)

    page.detail = CreateFrame("Frame", nil, page)
    page.detail:SetPoint("TOPLEFT", page.listPanel, "TOPRIGHT", 12, 0)
    page.detail:SetPoint("BOTTOMRIGHT", -14, 11)
    Backdrop(page.detail, PANEL, BORDER)

    page.detailAvatar = page.detail:CreateTexture(nil, "ARTWORK")
    page.detailAvatar:SetWidth(72); page.detailAvatar:SetHeight(72); page.detailAvatar:SetPoint("TOPLEFT", 15, -15)
    page.detailTitle = Text(page.detail, "GameFontNormal", "", 17)
    page.detailTitle:SetPoint("TOPLEFT", page.detailAvatar, "TOPRIGHT", 12, -2)
    page.detailTitle:SetPoint("RIGHT", -12, 0)
    page.detailTitle:SetJustifyH("LEFT")
    page.detailOwner = Text(page.detail, "GameFontNormal", "", 12)
    page.detailOwner:SetPoint("TOPLEFT", page.detailTitle, "BOTTOMLEFT", 0, -7)
    page.detailOwner:SetTextColor(unpack(GOLD))
    page.detailMeta = Text(page.detail, "GameFontNormal", "", 11)
    page.detailMeta:SetPoint("TOPLEFT", page.detailOwner, "BOTTOMLEFT", 0, -6)
    page.detailMeta:SetTextColor(unpack(MUTED))
    page.detailSource = Text(page.detail, "GameFontNormal", "", 10)
    page.detailSource:SetPoint("TOPLEFT", page.detailMeta, "BOTTOMLEFT", 0, -5)
    page.detailSource:SetTextColor(unpack(BLUE))

    page.descriptionTitle = SectionTitle(page.detail, self:L("DESCRIPTION"), 15, -105)
    page.description = Text(page.detail, "GameFontNormal", "", 12)
    page.description:SetPoint("TOPLEFT", 15, -128)
    page.description:SetPoint("RIGHT", -15, 0)
    page.description:SetHeight(90)
    page.description:SetJustifyH("LEFT")
    page.description:SetJustifyV("TOP")

    page.rolesTitle = SectionTitle(page.detail, self:L("ROLES"), 15, -224)
    page.roleButtons = {}
    local roles = {"tank", "heal", "dps", "support"}
    for index, role in ipairs(roles) do
        local button = FlatButton(page.detail, self:RoleLabel(role), 98, 36)
        button:SetPoint("TOPLEFT", 15 + (index - 1) * 103, -248)
        button.role = role
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetTexture(self:RoleIcon(role)); button.icon:SetWidth(20); button.icon:SetHeight(20); button.icon:SetPoint("LEFT", 7, 0)
        button.label:ClearAllPoints(); button.label:SetPoint("LEFT", button.icon, "RIGHT", 5, 0); button.label:SetPoint("RIGHT", -4, 0); button.label:SetJustifyH("LEFT")
        button:SetScript("OnClick", function(self) TE.selectedActivityRole = self.role; TE:RefreshActivitiesPage(false) end)
        page.roleButtons[index] = button
    end

    page.membersTitle = SectionTitle(page.detail, self:L("MEMBERS", 0, 0), 15, -301)
    page.members = Text(page.detail, "GameFontNormal", "", 11)
    page.members:SetPoint("TOPLEFT", 15, -324)
    page.members:SetPoint("RIGHT", -15, 0)
    page.members:SetHeight(65)
    page.members:SetJustifyH("LEFT")
    page.members:SetJustifyV("TOP")
    page.members:SetTextColor(unpack(MUTED))

    page.pendingTitle = SectionTitle(page.detail, self:L("PENDING", 0), 15, -395)
    page.applicantRows = {}
    for index = 1, 3 do
        local row = CreateFrame("Frame", nil, page.detail)
        row:SetHeight(31)
        row:SetPoint("TOPLEFT", 15, -418 - (index - 1) * 34)
        row:SetPoint("RIGHT", -15, 0)
        Backdrop(row, PANEL_2, BORDER)
        row.name = Text(row, "GameFontNormal", "", 11)
        row.name:SetPoint("LEFT", 8, 0)
        row.accept = FlatButton(row, self:L("ACCEPT"), 74, 25)
        row.accept:SetPoint("RIGHT", -82, 0)
        row.decline = FlatButton(row, self:L("DECLINE"), 74, 25)
        row.decline:SetPoint("RIGHT", -4, 0)
        page.applicantRows[index] = row
    end

    page.join = FlatButton(page.detail, self:L("JOIN"), 170, 36)
    page.join:SetPoint("BOTTOMLEFT", 15, 14)
    page.join:SetScript("OnClick", function()
        local activity = TE:GetActivity(TE.selectedActivityID)
        if not activity then return end
        local me = TE:GetPlayerName()
        local leave = (activity.members and activity.members[me]) or (activity.pending and activity.pending[me])
        TE:RequestJoin(activity, TE.selectedActivityRole or "dps", leave and true or false)
    end)
    page.edit = FlatButton(page.detail, self:L("EDIT"), 105, 36)
    page.edit:SetPoint("LEFT", page.join, "RIGHT", 8, 0)
    page.edit:SetScript("OnClick", function() local activity = TE:GetActivity(TE.selectedActivityID); if activity then TE:OpenActivityPopup(activity) end end)
    page.close = FlatButton(page.detail, self:L("CLOSE"), 105, 36)
    page.close:SetPoint("BOTTOMRIGHT", -15, 14)
    page.close:SetScript("OnClick", function() local activity = TE:GetActivity(TE.selectedActivityID); if activity then TE:CloseActivity(activity) end end)
    page.invite = FlatButton(page.detail, self:L("INVITE_ALL"), 170, 32)
    page.invite:SetPoint("BOTTOMLEFT", 15, 56)
    page.invite:SetScript("OnClick", function() local activity = TE:GetActivity(TE.selectedActivityID); if activity then TE:InviteAllMembers(activity) end end)

    page.selectHelp = Text(page.detail, "GameFontNormal", self:L("SELECT_ACTIVITY"), 13)
    page.selectHelp:SetPoint("CENTER", 0, 0)
    page.selectHelp:SetWidth(360)
    page.selectHelp:SetJustifyH("CENTER")
    page.selectHelp:SetTextColor(unpack(MUTED))

    self.activitiesPage = page
end

function TE:RefreshActivitiesPage(force)
    local page = self.activitiesPage
    if not page then return end
    local activities = self:GetVisibleActivities()
    local perPage = #page.rows
    local maxPage = max(1, math.ceil(#activities / perPage))
    page.pageIndex = min(max(1, page.pageIndex or 1), maxPage)
    local first = (page.pageIndex - 1) * perPage + 1

    SetSelected(page.filterFR, self.db.profile.feedFilter == "FR")
    SetSelected(page.filterAll, self.db.profile.feedFilter ~= "FR")
    page.pageText:SetText(self:L("PAGE", page.pageIndex, maxPage))
    SetEnabled(page.prev, page.pageIndex > 1)
    SetEnabled(page.next, page.pageIndex < maxPage)
    ShowWhen(page.empty, #activities == 0)

    for index, row in ipairs(page.rows) do
        local activity = activities[first + index - 1]
        if activity then
            row:Show(); row.activityID = activity.id
            local profile = self:GetProfile(activity.owner)
            row.icon:SetTexture(profile and profile.avatar or self.DEFAULT_AVATAR)
            row.title:SetText(activity.title)
            row.meta:SetText((activity.category == "PVP" and self:L("PVP") or self:L("PVE")) .. " • " .. TypeLabel(activity.activityType, activity.category) .. " • " .. activity.owner)
            row.language:SetText(activity.language)
            if activity.language == "FR" then row.language:SetTextColor(unpack(BLUE)) else row.language:SetTextColor(unpack(GOLD)) end
            row.count:SetText(self:L("MEMBERS", self:GetActivityOccupancy(activity), activity.slots or 1))
            row.selected = self.selectedActivityID == activity.id
            if row.selected then row:SetBackdropColor(unpack(ACCENT_DARK)); row:SetBackdropBorderColor(unpack(ACCENT)) else row:SetBackdropColor(unpack(PANEL_2)); row:SetBackdropBorderColor(unpack(BORDER)) end
        else
            row:Hide(); row.activityID = nil; row.selected = false
        end
    end

    local selected = self:GetActivity(self.selectedActivityID)
    if selected and not self:PassesLanguageFilter(selected) then selected = nil end
    if not selected and #activities > 0 then selected = activities[1]; self.selectedActivityID = selected.id end
    self:RefreshActivityDetails(selected)
end

function TE:RefreshActivityDetails(activity)
    local page = self.activitiesPage
    if not page then return end
    local elements = {
        page.detailAvatar, page.detailTitle, page.detailOwner, page.detailMeta, page.detailSource,
        page.descriptionTitle, page.description, page.rolesTitle, page.membersTitle, page.members,
        page.pendingTitle, page.join, page.edit, page.close, page.invite,
    }
    if not activity then
        page.selectHelp:Show()
        for _, element in ipairs(elements) do element:Hide() end
        for _, button in ipairs(page.roleButtons) do button:Hide() end
        for _, row in ipairs(page.applicantRows) do row:Hide() end
        return
    end
    page.selectHelp:Hide()
    for _, element in ipairs(elements) do element:Show() end

    local profile = self:GetProfile(activity.owner)
    page.detailAvatar:SetTexture(profile and profile.avatar or self.DEFAULT_AVATAR)
    page.detailTitle:SetText(activity.title)
    page.detailOwner:SetText(self:L("OWNER") .. " : " .. activity.owner .. (activity.guildName ~= "" and (" • " .. activity.guildName) or ""))
    page.detailMeta:SetText((activity.category == "PVP" and self:L("PVP") or self:L("PVE")) .. " • " .. TypeLabel(activity.activityType, activity.category) .. " • " .. self:L("LEVELS", activity.minLevel, activity.maxLevel) .. " • " .. activity.language)
    page.detailSource:SetText(self:L(activity.source == "GBG" and "SOURCE_GBG" or "SOURCE_SERVER"))
    page.description:SetText(activity.description ~= "" and activity.description or "—")

    if not self.selectedActivityRole or not self:HasRole(activity, self.selectedActivityRole) then
        for _, role in ipairs({"tank", "heal", "dps", "support"}) do if self:HasRole(activity, role) then self.selectedActivityRole = role; break end end
    end
    for _, button in ipairs(page.roleButtons) do
        button:Show()
        local allowed = self:HasRole(activity, button.role)
        SetEnabled(button, allowed)
        SetSelected(button, allowed and self.selectedActivityRole == button.role)
    end

    local memberLines = {}
    local members = {}
    for name, role in pairs(activity.members or {}) do members[#members + 1] = {name = name, role = role} end
    sort(members, function(a, b)
        local ar = ROLE_ORDER[TE:NormalizeRole(a.role)] or 9
        local br = ROLE_ORDER[TE:NormalizeRole(b.role)] or 9
        if ar ~= br then return ar < br end
        return strlower(a.name) < strlower(b.name)
    end)
    for index = 1, min(#members, 8) do
        local item = members[index]
        memberLines[#memberLines + 1] = self:RoleLabel(item.role) .. " — " .. item.name
    end
    if #members == 0 then memberLines[1] = "—" end
    page.membersTitle:SetText(self:L("MEMBERS", self:GetActivityOccupancy(activity), activity.slots))
    page.members:SetText(table.concat(memberLines, "\n"))

    local pending = {}
    for name, role in pairs(activity.pending or {}) do pending[#pending + 1] = {name = name, role = role} end
    sort(pending, function(a, b) return strlower(a.name) < strlower(b.name) end)
    page.pendingTitle:SetText(self:L("PENDING", #pending))
    local isOwner = self:NormalizeName(activity.owner) == self:GetPlayerName()
    ShowWhen(page.pendingTitle, isOwner and activity.approvalMode == "manual")
    for index, row in ipairs(page.applicantRows) do
        local applicant = pending[index]
        if isOwner and activity.approvalMode == "manual" and applicant then
            row:Show(); row.name:SetText(applicant.name .. " — " .. self:RoleLabel(applicant.role))
            row.accept:SetScript("OnClick", function() TE:AcceptApplicant(activity, applicant.name) end)
            row.decline:SetScript("OnClick", function() TE:DeclineApplicant(activity, applicant.name) end)
        else row:Hide() end
    end

    local me = self:GetPlayerName()
    local joined = activity.members and activity.members[me]
    local queued = activity.pending and activity.pending[me]
    page.join.label:SetText((joined or queued) and self:L("LEAVE") or self:L("JOIN"))
    ShowWhen(page.join, not isOwner)
    SetEnabled(page.join, isOwner or joined or queued or self:GetActivityAvailable(activity) > 0)
    ShowWhen(page.edit, isOwner and activity.source ~= "GBG")
    ShowWhen(page.close, isOwner)
    ShowWhen(page.invite, isOwner)
end

-- --------------------------------------------------------------------------
-- Activity creation/edit popup
-- --------------------------------------------------------------------------
function TE:CreateActivityPopup()
    if self.activityPopup then return end
    local frame = CreateFrame("Frame", "TousEnsembleActivityPopup", UIParent)
    self:RegisterEscapeFrame("TousEnsembleActivityPopup")
    frame:SetWidth(650); frame:SetHeight(690); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:Hide()
    Backdrop(frame, PANEL, ACCENT)
    frame:SetPoint("CENTER")

    frame.title = Text(frame, "GameFontNormal", self:L("CREATE_TITLE"), 19)
    frame.title:SetPoint("TOPLEFT", 22, -20); frame.title:SetTextColor(unpack(ACCENT))
    frame.closeX = FlatButton(frame, "×", 32, 32); frame.closeX:SetPoint("TOPRIGHT", -12, -12); frame.closeX:SetScript("OnClick", function() frame:Hide() end)

    frame.nameLabel = SectionTitle(frame, self:L("NAME"), 22, -62)
    frame.nameHolder, frame.name = Input(frame, 606, 36, false); frame.nameHolder:SetPoint("TOPLEFT", 22, -84)
    frame.descLabel = SectionTitle(frame, self:L("DESCRIPTION"), 22, -132)
    frame.descHolder, frame.description = Input(frame, 606, 78, true); frame.descHolder:SetPoint("TOPLEFT", 22, -154)

    frame.categoryLabel = SectionTitle(frame, self:L("CATEGORY"), 22, -247)
    frame.pve = FlatButton(frame, self:L("PVE"), 145, 34); frame.pve:SetPoint("TOPLEFT", 22, -270)
    frame.pvp = FlatButton(frame, self:L("PVP"), 145, 34); frame.pvp:SetPoint("LEFT", frame.pve, "RIGHT", 8, 0)
    frame.pve:SetScript("OnClick", function() frame.category = "PVE"; TE:RefreshActivityPopup() end)
    frame.pvp:SetScript("OnClick", function() frame.category = "PVP"; TE:RefreshActivityPopup() end)

    frame.typeLabel = SectionTitle(frame, self:L("TYPE"), 338, -247)
    frame.type = FlatButton(frame, "", 290, 34); frame.type:SetPoint("TOPLEFT", 338, -270)
    frame.type:SetScript("OnClick", function()
        local definitions = ACTIVITY_TYPES[frame.category or "PVE"]
        frame.typeIndex = (frame.typeIndex or 1) + 1
        if frame.typeIndex > #definitions then frame.typeIndex = 1 end
        frame.activityType = definitions[frame.typeIndex].id
        TE:RefreshActivityPopup()
    end)

    frame.minLabel = SectionTitle(frame, self:L("MIN_LEVEL"), 22, -322)
    frame.minHolder, frame.minLevel = Input(frame, 110, 34, false); frame.minHolder:SetPoint("TOPLEFT", 22, -345); frame.minLevel:SetNumeric(true)
    frame.maxLabel = SectionTitle(frame, self:L("MAX_LEVEL"), 150, -322)
    frame.maxHolder, frame.maxLevel = Input(frame, 110, 34, false); frame.maxHolder:SetPoint("TOPLEFT", 150, -345); frame.maxLevel:SetNumeric(true)
    frame.slotsLabel = SectionTitle(frame, self:L("SLOTS"), 278, -322)
    frame.slotsHolder, frame.slots = Input(frame, 110, 34, false); frame.slotsHolder:SetPoint("TOPLEFT", 278, -345); frame.slots:SetNumeric(true)

    frame.languageLabel = SectionTitle(frame, self:L("ACTIVITY_LANGUAGE"), 406, -322)
    frame.langFR = FlatButton(frame, "FR", 105, 34); frame.langFR:SetPoint("TOPLEFT", 406, -345)
    frame.langAll = FlatButton(frame, "All", 105, 34); frame.langAll:SetPoint("LEFT", frame.langFR, "RIGHT", 7, 0)
    frame.langFR:SetScript("OnClick", function() frame.language = "FR"; TE:RefreshActivityPopup() end)
    frame.langAll:SetScript("OnClick", function() frame.language = "ALL"; TE:RefreshActivityPopup() end)
    Tooltip(frame.langFR, function() return TE:L("ACTIVITY_LANGUAGE_FR") end)
    Tooltip(frame.langAll, function() return TE:L("ACTIVITY_LANGUAGE_ALL") end)

    frame.rolesLabel = SectionTitle(frame, self:L("ROLES"), 22, -397)
    frame.roleChecks = {}
    for index, role in ipairs({"tank", "heal", "dps", "support"}) do
        local check = Toggle(frame, self:RoleLabel(role), 145)
        check:SetPoint("TOPLEFT", 22 + (index - 1) * 153, -420)
        check.role = role
        check.OnToggle = function() TE:RefreshActivityPopup() end
        frame.roleChecks[index] = check
    end

    frame.ownerRoleLabel = SectionTitle(frame, self:L("YOUR_ROLE"), 22, -469)
    frame.ownerRoleButtons = {}
    for index, role in ipairs({"tank", "heal", "dps", "support"}) do
        local button = FlatButton(frame, self:RoleLabel(role), 145, 34)
        button:SetPoint("TOPLEFT", 22 + (index - 1) * 153, -492)
        button.role = role
        button:SetScript("OnClick", function(self) frame.ownerRole = self.role; TE:RefreshActivityPopup() end)
        frame.ownerRoleButtons[index] = button
    end

    frame.approvalLabel = SectionTitle(frame, self:L("APPROVAL"), 22, -541)
    frame.auto = FlatButton(frame, self:L("AUTO"), 295, 34); frame.auto:SetPoint("TOPLEFT", 22, -564)
    frame.manual = FlatButton(frame, self:L("MANUAL"), 295, 34); frame.manual:SetPoint("LEFT", frame.auto, "RIGHT", 8, 0)
    frame.auto:SetScript("OnClick", function() frame.approvalMode = "auto"; TE:RefreshActivityPopup() end)
    frame.manual:SetScript("OnClick", function() frame.approvalMode = "manual"; TE:RefreshActivityPopup() end)

    frame.save = FlatButton(frame, self:L("SAVE"), 180, 40); frame.save:SetPoint("BOTTOMLEFT", 22, 18)
    frame.cancel = FlatButton(frame, self:L("CANCEL"), 130, 40); frame.cancel:SetPoint("BOTTOMRIGHT", -22, 18); frame.cancel:SetScript("OnClick", function() frame:Hide() end)
    frame.save:SetScript("OnClick", function() TE:SaveActivityPopup() end)

    self.activityPopup = frame
end

function TE:FindTypeIndex(category, activityType)
    local definitions = ACTIVITY_TYPES[category == "PVP" and "PVP" or "PVE"]
    for index, definition in ipairs(definitions) do if definition.id == activityType then return index end end
    return 1
end

function TE:OpenActivityPopup(activity)
    self:CreateActivityPopup()
    local frame = self.activityPopup
    frame.editActivityID = activity and activity.id or nil
    frame.title:SetText(self:L(activity and "EDIT_TITLE" or "CREATE_TITLE"))
    frame.name:SetText(activity and activity.title or "")
    frame.description:SetText(activity and activity.description or "")
    frame.category = activity and activity.category or "PVE"
    frame.activityType = activity and activity.activityType or ACTIVITY_TYPES[frame.category][1].id
    frame.typeIndex = self:FindTypeIndex(frame.category, frame.activityType)
    frame.minLevel:SetText(tostring(activity and activity.minLevel or max(1, (UnitLevel and UnitLevel("player") or 1) - 5)))
    frame.maxLevel:SetText(tostring(activity and activity.maxLevel or min(60, (UnitLevel and UnitLevel("player") or 1) + 5)))
    frame.slots:SetText(tostring(activity and activity.slots or 5))
    frame.language = activity and activity.language or (self.db.profile.feedFilter == "FR" and "FR" or "ALL")
    frame.approvalMode = activity and activity.approvalMode or "auto"
    frame.ownerRole = activity and activity.ownerRole or "dps"
    for _, check in ipairs(frame.roleChecks) do
        check:SetChecked(activity and self:HasRole(activity, check.role) or (check.role == "dps"))
    end
    if not activity then frame.roleChecks[1]:SetChecked(true); frame.roleChecks[2]:SetChecked(true) end
    self:RefreshActivityPopup()
    frame:Show()
end

function TE:RefreshActivityPopup()
    local frame = self.activityPopup
    if not frame then return end
    SetSelected(frame.pve, frame.category ~= "PVP")
    SetSelected(frame.pvp, frame.category == "PVP")
    SetSelected(frame.langFR, frame.language == "FR")
    SetSelected(frame.langAll, frame.language ~= "FR")
    SetSelected(frame.auto, frame.approvalMode ~= "manual")
    SetSelected(frame.manual, frame.approvalMode == "manual")
    local definitions = ACTIVITY_TYPES[frame.category == "PVP" and "PVP" or "PVE"]
    frame.typeIndex = self:FindTypeIndex(frame.category, frame.activityType)
    frame.activityType = definitions[frame.typeIndex].id
    frame.type.label:SetText(definitions[frame.typeIndex][self:GetLocaleCode()] or definitions[frame.typeIndex].fr)
    local enabled = {}
    for _, check in ipairs(frame.roleChecks) do enabled[check.role] = check:GetChecked() end
    if not enabled[frame.ownerRole] then
        for _, role in ipairs({"tank", "heal", "dps", "support"}) do if enabled[role] then frame.ownerRole = role; break end end
    end
    for _, button in ipairs(frame.ownerRoleButtons) do
        SetEnabled(button, enabled[button.role] == true)
        SetSelected(button, enabled[button.role] and frame.ownerRole == button.role)
    end
end

function TE:SaveActivityPopup()
    local frame = self.activityPopup
    if not frame then return end
    local roles = {}
    for _, check in ipairs(frame.roleChecks) do if check:GetChecked() then roles[#roles + 1] = check.role end end
    if #roles == 0 then self:Print(self:L("ROLE_REQUIRED")); return end
    local data = {
        title = frame.name:GetText(), description = frame.description:GetText(), category = frame.category,
        activityType = frame.activityType, minLevel = frame.minLevel:GetText(), maxLevel = frame.maxLevel:GetText(),
        slots = frame.slots:GetText(), roles = table.concat(roles, ","), ownerRole = frame.ownerRole,
        approvalMode = frame.approvalMode, language = frame.language,
    }
    local success
    if frame.editActivityID then success = self:UpdateActivity(self:GetActivity(frame.editActivityID), data)
    else success = self:CreateActivity(data) end
    if success then frame:Hide(); self:RefreshActivitiesPage(true) end
end

-- --------------------------------------------------------------------------
-- Guild search page
-- --------------------------------------------------------------------------
function TE:CreateGuildSearchPage()
    if self.guildsPage then return end
    local page = CreateFrame("Frame", nil, self.mainFrame.content); page:SetAllPoints()
    page.title = Text(page, "GameFontNormal", self:L("GUILD_SEARCH_TITLE"), 18); page.title:SetPoint("TOPLEFT", 18, -16); page.title:SetTextColor(unpack(ACCENT))
    page.help = Text(page, "GameFontNormal", self:L("GUILD_SEARCH_HELP"), 11); page.help:SetPoint("TOPLEFT", 18, -42); page.help:SetTextColor(unpack(MUTED))
    page.refresh = FlatButton(page, self:L("REFRESH"), 110, 32); page.refresh:SetPoint("TOPRIGHT", -18, -12); page.refresh:SetScript("OnClick", function() TE:RequestRecruitmentAdvertisements(); TE:RefreshGuildSearchPage(true) end)
    page.publish = FlatButton(page, self:L("PUBLISH_GUILD"), 155, 32); page.publish:SetPoint("RIGHT", page.refresh, "LEFT", -8, 0); page.publish:SetScript("OnClick", function() TE:OpenGuildAdPopup() end)

    page.listPanel = CreateFrame("Frame", nil, page); page.listPanel:SetPoint("TOPLEFT", 14, -70); page.listPanel:SetPoint("BOTTOMLEFT", 14, 48); page.listPanel:SetWidth(425); Backdrop(page.listPanel, PANEL, BORDER)
    page.rows = {}
    for index = 1, 8 do
        local row = CreateFrame("Button", nil, page.listPanel); row:SetHeight(53); row:SetPoint("TOPLEFT", 8, -8 - (index - 1) * 57); row:SetPoint("TOPRIGHT", -8, -8 - (index - 1) * 57); Backdrop(row, PANEL_2, BORDER)
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetWidth(36); row.icon:SetHeight(36); row.icon:SetPoint("LEFT", 8, 0)
        row.name = Text(row, "GameFontNormal", "", 13); row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 9, -4); row.name:SetPoint("RIGHT", -80, 0); row.name:SetJustifyH("LEFT")
        row.meta = Text(row, "GameFontNormal", "", 10); row.meta:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 9, 4); row.meta:SetTextColor(unpack(MUTED))
        row.online = Text(row, "GameFontNormal", "", 11); row.online:SetPoint("RIGHT", -10, 0); row.online:SetTextColor(unpack(GREEN))
        row:SetScript("OnClick", function(self) if self.guildKey then TE.selectedGuildKey = self.guildKey; TE:RefreshGuildSearchPage(true) end end)
        row:SetScript("OnEnter", function(self) if not self.selected then self:SetBackdropColor(unpack(PANEL_3)); self:SetBackdropBorderColor(unpack(ACCENT)) end end)
        row:SetScript("OnLeave", function(self) if self.selected then self:SetBackdropColor(unpack(ACCENT_DARK)); self:SetBackdropBorderColor(unpack(ACCENT)) else self:SetBackdropColor(unpack(PANEL_2)); self:SetBackdropBorderColor(unpack(BORDER)) end end)
        page.rows[index] = row
    end
    page.empty = Text(page.listPanel, "GameFontNormal", self:L("NO_GUILD"), 13); page.empty:SetPoint("CENTER"); page.empty:SetWidth(360); page.empty:SetJustifyH("CENTER"); page.empty:SetTextColor(unpack(MUTED))
    page.prev = FlatButton(page, self:L("PREVIOUS"), 105, 30); page.prev:SetPoint("BOTTOMLEFT", 14, 11); page.prev:SetScript("OnClick", function() page.pageIndex = max(1, (page.pageIndex or 1) - 1); TE:RefreshGuildSearchPage(true) end)
    page.pageText = Text(page, "GameFontNormal", "", 11); page.pageText:SetPoint("BOTTOM", page.listPanel, "BOTTOM", 0, -30); page.pageText:SetTextColor(unpack(MUTED))
    page.next = FlatButton(page, self:L("NEXT"), 105, 30); page.next:SetPoint("BOTTOMRIGHT", page.listPanel, "BOTTOMRIGHT", 0, -37); page.next:SetScript("OnClick", function() page.pageIndex = (page.pageIndex or 1) + 1; TE:RefreshGuildSearchPage(true) end)

    page.detail = CreateFrame("Frame", nil, page); page.detail:SetPoint("TOPLEFT", page.listPanel, "TOPRIGHT", 12, 0); page.detail:SetPoint("BOTTOMRIGHT", -14, 11); Backdrop(page.detail, PANEL, BORDER)
    page.icon = page.detail:CreateTexture(nil, "ARTWORK"); page.icon:SetWidth(76); page.icon:SetHeight(76); page.icon:SetPoint("TOPLEFT", 15, -15)
    page.guildName = Text(page.detail, "GameFontNormal", "", 18); page.guildName:SetPoint("TOPLEFT", page.icon, "TOPRIGHT", 12, -2); page.guildName:SetPoint("RIGHT", -12, 0); page.guildName:SetJustifyH("LEFT")
    page.objective = Text(page.detail, "GameFontNormal", "", 12); page.objective:SetPoint("TOPLEFT", page.guildName, "BOTTOMLEFT", 0, -7); page.objective:SetTextColor(unpack(GOLD))
    page.memberMeta = Text(page.detail, "GameFontNormal", "", 11); page.memberMeta:SetPoint("TOPLEFT", page.objective, "BOTTOMLEFT", 0, -6); page.memberMeta:SetTextColor(unpack(MUTED))
    page.levelMeta = Text(page.detail, "GameFontNormal", "", 11); page.levelMeta:SetPoint("TOPLEFT", page.memberMeta, "BOTTOMLEFT", 0, -5); page.levelMeta:SetTextColor(unpack(MUTED))
    page.descTitle = SectionTitle(page.detail, self:L("GUILD_AD_DESCRIPTION"), 15, -113)
    page.description = Text(page.detail, "GameFontNormal", "", 12); page.description:SetPoint("TOPLEFT", 15, -137); page.description:SetPoint("RIGHT", -15, 0); page.description:SetHeight(150); page.description:SetJustifyV("TOP"); page.description:SetJustifyH("LEFT")
    page.messageTitle = SectionTitle(page.detail, self:L("APPLY_MESSAGE"), 15, -304)
    page.messageHolder, page.message = Input(page.detail, 500, 100, true); page.messageHolder:SetPoint("TOPLEFT", 15, -328)
    page.status = Text(page.detail, "GameFontNormal", "", 11); page.status:SetPoint("TOPLEFT", 15, -438); page.status:SetPoint("RIGHT", -15, 0); page.status:SetTextColor(unpack(MUTED)); page.status:SetJustifyH("LEFT")
    page.apply = FlatButton(page.detail, self:L("APPLY"), 180, 38); page.apply:SetPoint("BOTTOMLEFT", 15, 15); page.apply:SetScript("OnClick", function() local ad = TE.db.guildAds[TE.selectedGuildKey or ""]; if ad then TE:SubmitGuildApplication(ad, page.message:GetText()) end end)
    page.selectHelp = Text(page.detail, "GameFontNormal", self:L("SELECT_GUILD"), 13); page.selectHelp:SetPoint("CENTER"); page.selectHelp:SetWidth(420); page.selectHelp:SetJustifyH("CENTER"); page.selectHelp:SetTextColor(unpack(MUTED))
    self.guildsPage = page
end

function TE:ObjectiveLabel(value)
    if value == "PVE" then return self:L("GUILD_OBJECTIVE_PVE") end
    if value == "PVP" then return self:L("GUILD_OBJECTIVE_PVP") end
    return self:L("GUILD_OBJECTIVE_MIXED")
end

function TE:RefreshGuildSearchPage(force)
    local page = self.guildsPage; if not page then return end
    local ads = self:GetGuildAdvertisements(); local perPage = #page.rows; local maxPage = max(1, math.ceil(#ads / perPage)); page.pageIndex = min(max(1, page.pageIndex or 1), maxPage); local first = (page.pageIndex - 1) * perPage + 1
    ShowWhen(page.empty, #ads == 0); page.pageText:SetText(self:L("PAGE", page.pageIndex, maxPage)); SetEnabled(page.prev, page.pageIndex > 1); SetEnabled(page.next, page.pageIndex < maxPage); SetEnabled(page.publish, self:IsInGuild())
    for index, row in ipairs(page.rows) do
        local ad = ads[first + index - 1]
        if ad then
            row:Show(); row.guildKey = ad.guildKey; row.icon:SetTexture(ad.guildImage ~= "" and ad.guildImage or "Interface\\Icons\\INV_BannerPVP_02"); row.name:SetText(ad.guildName); row.meta:SetText(self:ObjectiveLabel(ad.objective) .. " • " .. tostring(ad.totalMembers or 0) .. " membres"); row.online:SetText(tostring(ad.onlineMembers or 0) .. " online")
            row.selected = self.selectedGuildKey == ad.guildKey; if row.selected then row:SetBackdropColor(unpack(ACCENT_DARK)); row:SetBackdropBorderColor(unpack(ACCENT)) else row:SetBackdropColor(unpack(PANEL_2)); row:SetBackdropBorderColor(unpack(BORDER)) end
        else row:Hide(); row.guildKey = nil end
    end
    local selected = self.db.guildAds[self.selectedGuildKey or ""]
    if not selected and #ads > 0 then selected = ads[1]; self.selectedGuildKey = selected.guildKey end
    self:RefreshGuildDetails(selected)
end

function TE:RefreshGuildDetails(ad)
    local page = self.guildsPage; if not page then return end
    local elements = {page.icon, page.guildName, page.objective, page.memberMeta, page.levelMeta, page.descTitle, page.description, page.messageTitle, page.messageHolder, page.status, page.apply}
    if not ad then page.selectHelp:Show(); for _, element in ipairs(elements) do element:Hide() end; return end
    page.selectHelp:Hide(); for _, element in ipairs(elements) do element:Show() end
    page.icon:SetTexture(ad.guildImage ~= "" and ad.guildImage or "Interface\\Icons\\INV_BannerPVP_02"); page.guildName:SetText(ad.guildName); page.objective:SetText(self:ObjectiveLabel(ad.objective)); page.memberMeta:SetText(self:L("GUILD_MEMBERS", ad.totalMembers or 0, ad.onlineMembers or 0)); page.levelMeta:SetText(self:L("GUILD_LEVELS", ad.minLevel or 1, ad.maxLevel or 60)); page.description:SetText(ad.description ~= "" and ad.description or "—")
    local application = self:GetMyApplicationForGuild(ad.guildKey)
    if application then
        if page.message:GetText() == "" then page.message:SetText(application.message or "") end
        local key = application.status == "accepted" and "STATUS_ACCEPTED" or (application.status == "declined" and "STATUS_DECLINED" or (application.status == "joined" and "STATUS_JOINED" or "STATUS_PENDING")); page.status:SetText(self:L(key) .. (application.reason and application.reason ~= "" and (" — " .. application.reason) or ""))
    else page.status:SetText(self:L("STATUS_NONE")) end
    SetEnabled(page.apply, not self:IsInGuild())
end

function TE:CreateGuildAdPopup()
    if self.guildAdPopup then return end
    local frame = CreateFrame("Frame", "TousEnsembleGuildAdPopup", UIParent); self:RegisterEscapeFrame("TousEnsembleGuildAdPopup"); frame:SetWidth(620); frame:SetHeight(505); frame:SetFrameStrata("DIALOG"); frame:SetPoint("CENTER"); frame:SetClampedToScreen(true); frame:Hide(); Backdrop(frame, PANEL, ACCENT)
    frame.title = Text(frame, "GameFontNormal", self:L("GUILD_AD_TITLE"), 19); frame.title:SetPoint("TOPLEFT", 22, -20); frame.title:SetTextColor(unpack(ACCENT))
    frame.closeX = FlatButton(frame, "×", 32, 32); frame.closeX:SetPoint("TOPRIGHT", -12, -12); frame.closeX:SetScript("OnClick", function() frame:Hide() end)
    frame.enabled = Toggle(frame, self:L("GUILD_AD_ENABLED"), 280); frame.enabled:SetPoint("TOPLEFT", 22, -61)
    frame.objectiveLabel = SectionTitle(frame, self:L("GUILD_OBJECTIVE"), 22, -108)
    frame.objectives = {}
    for index, objective in ipairs({"PVE", "PVP", "MIXED"}) do
        local button = FlatButton(frame, self:ObjectiveLabel(objective), 180, 34); button:SetPoint("TOPLEFT", 22 + (index - 1) * 190, -132); button.objective = objective; button:SetScript("OnClick", function(self) frame.objective = self.objective; TE:RefreshGuildAdPopup() end); frame.objectives[index] = button
    end
    frame.minLabel = SectionTitle(frame, self:L("MIN_LEVEL"), 22, -184); frame.minHolder, frame.minLevel = Input(frame, 120, 34, false); frame.minHolder:SetPoint("TOPLEFT", 22, -208); frame.minLevel:SetNumeric(true)
    frame.maxLabel = SectionTitle(frame, self:L("MAX_LEVEL"), 160, -184); frame.maxHolder, frame.maxLevel = Input(frame, 120, 34, false); frame.maxHolder:SetPoint("TOPLEFT", 160, -208); frame.maxLevel:SetNumeric(true)
    frame.descLabel = SectionTitle(frame, self:L("GUILD_AD_DESCRIPTION"), 22, -260); frame.descHolder, frame.description = Input(frame, 576, 130, true); frame.descHolder:SetPoint("TOPLEFT", 22, -284)
    frame.save = FlatButton(frame, self:L("SAVE"), 180, 40); frame.save:SetPoint("BOTTOMLEFT", 22, 18); frame.save:SetScript("OnClick", function() if TE:SaveGuildAdvertisement({enabled = frame.enabled:GetChecked(), objective = frame.objective, minLevel = frame.minLevel:GetText(), maxLevel = frame.maxLevel:GetText(), description = frame.description:GetText()}) then frame:Hide(); TE:RefreshGuildSearchPage(true) end end)
    frame.cancel = FlatButton(frame, self:L("CANCEL"), 130, 40); frame.cancel:SetPoint("BOTTOMRIGHT", -22, 18); frame.cancel:SetScript("OnClick", function() frame:Hide() end)
    self.guildAdPopup = frame
end

function TE:OpenGuildAdPopup()
    if not self:IsInGuild() then self:Print(self:L("GUILD_AD_REQUIRES_GUILD")); return end
    local gbg = _G.GlaynaBetterGuild
    if gbg and gbg ~= self and gbg.OpenRecruitmentSettings then
        if gbg.CreateUI then pcall(gbg.CreateUI, gbg) end
        pcall(gbg.OpenRecruitmentSettings, gbg)
        return
    end
    self:CreateGuildAdPopup(); local frame = self.guildAdPopup; local settings = self.db.guildAd
    frame.enabled:SetChecked(settings.enabled == true); frame.objective = settings.objective or "MIXED"; frame.minLevel:SetText(tostring(settings.minLevel or 1)); frame.maxLevel:SetText(tostring(settings.maxLevel or 60)); frame.description:SetText(settings.description or ""); self:RefreshGuildAdPopup(); frame:Show()
end

function TE:RefreshGuildAdPopup()
    local frame = self.guildAdPopup; if not frame then return end
    for _, button in ipairs(frame.objectives) do SetSelected(button, button.objective == frame.objective) end
end

-- --------------------------------------------------------------------------
-- Incoming applications page
-- --------------------------------------------------------------------------
function TE:CreateApplicationsPage()
    if self.applicationsPage then return end
    local page = CreateFrame("Frame", nil, self.mainFrame.content); page:SetAllPoints()
    page.title = Text(page, "GameFontNormal", self:L("APPLICATIONS_TITLE"), 18); page.title:SetPoint("TOPLEFT", 18, -16); page.title:SetTextColor(unpack(ACCENT))
    page.listPanel = CreateFrame("Frame", nil, page); page.listPanel:SetPoint("TOPLEFT", 14, -57); page.listPanel:SetPoint("BOTTOMLEFT", 14, 48); page.listPanel:SetWidth(425); Backdrop(page.listPanel, PANEL, BORDER)
    page.rows = {}
    for index = 1, 8 do
        local row = CreateFrame("Button", nil, page.listPanel); row:SetHeight(53); row:SetPoint("TOPLEFT", 8, -8 - (index - 1) * 57); row:SetPoint("TOPRIGHT", -8, -8 - (index - 1) * 57); Backdrop(row, PANEL_2, BORDER)
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetWidth(36); row.icon:SetHeight(36); row.icon:SetPoint("LEFT", 8, 0)
        row.name = Text(row, "GameFontNormal", "", 13); row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 9, -4); row.name:SetPoint("RIGHT", -90, 0); row.name:SetJustifyH("LEFT")
        row.meta = Text(row, "GameFontNormal", "", 10); row.meta:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 9, 4); row.meta:SetTextColor(unpack(MUTED))
        row.status = Text(row, "GameFontNormal", "", 10); row.status:SetPoint("RIGHT", -9, 0)
        row:SetScript("OnClick", function(self) if self.applicationID then TE.selectedApplicationID = self.applicationID; TE:RefreshApplicationsPage(true) end end)
        row:SetScript("OnEnter", function(self) if not self.selected then self:SetBackdropColor(unpack(PANEL_3)); self:SetBackdropBorderColor(unpack(ACCENT)) end end)
        row:SetScript("OnLeave", function(self) if self.selected then self:SetBackdropColor(unpack(ACCENT_DARK)); self:SetBackdropBorderColor(unpack(ACCENT)) else self:SetBackdropColor(unpack(PANEL_2)); self:SetBackdropBorderColor(unpack(BORDER)) end end)
        page.rows[index] = row
    end
    page.empty = Text(page.listPanel, "GameFontNormal", self:L("NO_APPLICATION"), 13); page.empty:SetPoint("CENTER"); page.empty:SetWidth(360); page.empty:SetJustifyH("CENTER"); page.empty:SetTextColor(unpack(MUTED))
    page.prev = FlatButton(page, self:L("PREVIOUS"), 105, 30); page.prev:SetPoint("BOTTOMLEFT", 14, 11); page.prev:SetScript("OnClick", function() page.pageIndex = max(1, (page.pageIndex or 1) - 1); TE:RefreshApplicationsPage(true) end)
    page.pageText = Text(page, "GameFontNormal", "", 11); page.pageText:SetPoint("BOTTOM", page.listPanel, "BOTTOM", 0, -30); page.pageText:SetTextColor(unpack(MUTED))
    page.next = FlatButton(page, self:L("NEXT"), 105, 30); page.next:SetPoint("BOTTOMRIGHT", page.listPanel, "BOTTOMRIGHT", 0, -37); page.next:SetScript("OnClick", function() page.pageIndex = (page.pageIndex or 1) + 1; TE:RefreshApplicationsPage(true) end)
    page.detail = CreateFrame("Frame", nil, page); page.detail:SetPoint("TOPLEFT", page.listPanel, "TOPRIGHT", 12, 0); page.detail:SetPoint("BOTTOMRIGHT", -14, 11); Backdrop(page.detail, PANEL, BORDER)
    page.avatar = page.detail:CreateTexture(nil, "ARTWORK"); page.avatar:SetWidth(82); page.avatar:SetHeight(82); page.avatar:SetPoint("TOPLEFT", 15, -15)
    page.name = Text(page.detail, "GameFontNormal", "", 18); page.name:SetPoint("TOPLEFT", page.avatar, "TOPRIGHT", 12, -2)
    page.classLevel = Text(page.detail, "GameFontNormal", "", 12); page.classLevel:SetPoint("TOPLEFT", page.name, "BOTTOMLEFT", 0, -8); page.classLevel:SetTextColor(unpack(GOLD))
    page.date = Text(page.detail, "GameFontNormal", "", 11); page.date:SetPoint("TOPLEFT", page.classLevel, "BOTTOMLEFT", 0, -7); page.date:SetTextColor(unpack(MUTED))
    page.messageTitle = SectionTitle(page.detail, self:L("APPLY_MESSAGE"), 15, -120); page.message = Text(page.detail, "GameFontNormal", "", 12); page.message:SetPoint("TOPLEFT", 15, -145); page.message:SetPoint("RIGHT", -15, 0); page.message:SetHeight(170); page.message:SetJustifyV("TOP"); page.message:SetJustifyH("LEFT")
    page.reasonTitle = SectionTitle(page.detail, self:L("REASON"), 15, -340); page.reasonHolder, page.reason = Input(page.detail, 500, 75, true); page.reasonHolder:SetPoint("TOPLEFT", 15, -364)
    page.accept = FlatButton(page.detail, self:L("ACCEPT_AND_INVITE"), 205, 40); page.accept:SetPoint("BOTTOMLEFT", 15, 15); page.accept:SetScript("OnClick", function() local record = TE.db.incomingApplications[TE.selectedApplicationID or ""]; if record then TE:AcceptGuildApplication(record) end end)
    page.decline = FlatButton(page.detail, self:L("REFUSE"), 155, 40); page.decline:SetPoint("BOTTOMRIGHT", -15, 15); page.decline:SetScript("OnClick", function() local record = TE.db.incomingApplications[TE.selectedApplicationID or ""]; if record then TE:DeclineGuildApplication(record, page.reason:GetText()) end end)
    page.selectHelp = Text(page.detail, "GameFontNormal", self:L("NO_APPLICATION"), 13); page.selectHelp:SetPoint("CENTER"); page.selectHelp:SetWidth(420); page.selectHelp:SetJustifyH("CENTER"); page.selectHelp:SetTextColor(unpack(MUTED))
    self.applicationsPage = page
end

function TE:RefreshApplicationsPage(force)
    local page = self.applicationsPage; if not page then return end
    local records = self:GetIncomingApplications(); local perPage = #page.rows; local maxPage = max(1, math.ceil(#records / perPage)); page.pageIndex = min(max(1, page.pageIndex or 1), maxPage); local first = (page.pageIndex - 1) * perPage + 1
    ShowWhen(page.empty, #records == 0); page.pageText:SetText(self:L("PAGE", page.pageIndex, maxPage)); SetEnabled(page.prev, page.pageIndex > 1); SetEnabled(page.next, page.pageIndex < maxPage)
    for index, row in ipairs(page.rows) do
        local record = records[first + index - 1]
        if record then
            row:Show(); row.applicationID = record.id; row.icon:SetTexture(record.avatar or self.DEFAULT_AVATAR); row.name:SetText(record.name or ""); row.meta:SetText("Niv. " .. tostring(record.level or 1) .. " • " .. tostring(record.className or "")); row.status:SetText(record.status == "accepted" and self:L("STATUS_ACCEPTED") or self:L("STATUS_PENDING")); if record.status == "accepted" then row.status:SetTextColor(unpack(GREEN)) else row.status:SetTextColor(unpack(GOLD)) end; row.selected = self.selectedApplicationID == record.id; if row.selected then row:SetBackdropColor(unpack(ACCENT_DARK)); row:SetBackdropBorderColor(unpack(ACCENT)) else row:SetBackdropColor(unpack(PANEL_2)); row:SetBackdropBorderColor(unpack(BORDER)) end
        else row:Hide(); row.applicationID = nil end
    end
    local selected = self.db.incomingApplications[self.selectedApplicationID or ""]
    if not selected and #records > 0 then selected = records[1]; self.selectedApplicationID = selected.id end
    self:RefreshApplicationDetails(selected)
end

function TE:RefreshApplicationDetails(record)
    local page = self.applicationsPage; if not page then return end
    local elements = {page.avatar, page.name, page.classLevel, page.date, page.messageTitle, page.message, page.reasonTitle, page.reasonHolder, page.accept, page.decline}
    if not record then page.selectHelp:Show(); for _, element in ipairs(elements) do element:Hide() end; return end
    page.selectHelp:Hide(); for _, element in ipairs(elements) do element:Show() end
    page.avatar:SetTexture(record.avatar or self.DEFAULT_AVATAR); page.name:SetText(record.name or ""); page.classLevel:SetText("Niveau " .. tostring(record.level or 1) .. " • " .. tostring(record.className or "")); page.date:SetText(self:L("APPLIED_AT", date("%d/%m/%Y %H:%M", record.appliedAt or time()))); page.message:SetText(record.message or "—"); page.reason:SetText(record.reason or ""); SetEnabled(page.accept, record.status ~= "accepted"); SetEnabled(page.decline, true)
end

-- --------------------------------------------------------------------------
-- Profile page and portraits
-- --------------------------------------------------------------------------
function TE:CreateProfilePage()
    if self.profilePage then return end
    local page = CreateFrame("Frame", nil, self.mainFrame.content); page:SetAllPoints()
    page.title = Text(page, "GameFontNormal", self:L("PROFILE_TITLE"), 18); page.title:SetPoint("TOPLEFT", 18, -14); page.title:SetTextColor(unpack(ACCENT))
    page.help = Text(page, "GameFontNormal", self:L("PROFILE_HELP"), 11); page.help:SetPoint("TOPLEFT", 18, -39); page.help:SetWidth(930); page.help:SetTextColor(unpack(MUTED))

    -- Portrait area kept completely above the settings panel.
    page.previewPanel = CreateFrame("Frame", nil, page); page.previewPanel:SetPoint("TOPLEFT", 18, -67); page.previewPanel:SetWidth(205); page.previewPanel:SetHeight(205); Backdrop(page.previewPanel, PANEL, BORDER)
    page.avatar = page.previewPanel:CreateTexture(nil, "ARTWORK"); page.avatar:SetWidth(158); page.avatar:SetHeight(158); page.avatar:SetPoint("TOP", 0, -16)
    page.name = Text(page.previewPanel, "GameFontNormal", self:GetPlayerName(), 14); page.name:SetPoint("BOTTOM", 0, 12); page.name:SetTextColor(unpack(GOLD))
    page.pictureTitle = SectionTitle(page, self:L("PROFILE_PICTURE"), 245, -68)
    page.portraitButtons = {}
    for index = 1, 24 do
        local button = CreateFrame("Button", nil, page)
        button:SetWidth(54); button:SetHeight(54)
        local col = (index - 1) % 8
        local row = floor((index - 1) / 8)
        button:SetPoint("TOPLEFT", 245 + col * 61, -92 - row * 61)
        Backdrop(button, PANEL_2, BORDER)
        button.texture = button:CreateTexture(nil, "ARTWORK"); button.texture:SetPoint("TOPLEFT", 4, -4); button.texture:SetPoint("BOTTOMRIGHT", -4, 4)
        button:SetScript("OnClick", function(self)
            if self.texturePath then
                TE.db.profile.avatar = self.texturePath
                TE.db.profile.avatarRevision = max((tonumber(TE.db.profile.avatarRevision) or 1) + 1, time())
                TE:BroadcastOwnProfile(true)
                TE:RefreshProfilePage(true)
                TE:RefreshAll(true)
            end
        end)
        button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(ACCENT)) end)
        button:SetScript("OnLeave", function(self) if self.texturePath == TE:GetOwnAvatar() then self:SetBackdropBorderColor(unpack(ACCENT)) else self:SetBackdropBorderColor(unpack(BORDER)) end end)
        page.portraitButtons[index] = button
    end
    page.portraitPrev = FlatButton(page, self:L("PREVIOUS"), 105, 28); page.portraitPrev:SetPoint("TOPLEFT", 245, -278); page.portraitPrev:SetScript("OnClick", function() page.portraitPage = max(1, (page.portraitPage or 1) - 1); TE:RefreshProfilePage(true) end)
    page.portraitPageText = Text(page, "GameFontNormal", "", 11); page.portraitPageText:SetPoint("LEFT", page.portraitPrev, "RIGHT", 32, 0); page.portraitPageText:SetWidth(100); page.portraitPageText:SetJustifyH("CENTER"); page.portraitPageText:SetTextColor(unpack(MUTED))
    page.portraitNext = FlatButton(page, self:L("NEXT"), 105, 28); page.portraitNext:SetPoint("LEFT", page.portraitPageText, "RIGHT", 32, 0); page.portraitNext:SetScript("OnClick", function() page.portraitPage = (page.portraitPage or 1) + 1; TE:RefreshProfilePage(true) end)

    -- Settings are split into clear columns so no control can overlap another.
    page.settingsPanel = CreateFrame("Frame", nil, page); page.settingsPanel:SetPoint("TOPLEFT", 18, -307); page.settingsPanel:SetPoint("BOTTOMRIGHT", -18, 18); Backdrop(page.settingsPanel, PANEL, BORDER)

    page.feedTitle = SectionTitle(page.settingsPanel, self:L("PROFILE_FEED"), 14, -12)
    page.feedHelp = Text(page.settingsPanel, "GameFontNormal", self:L("PROFILE_FEED_HELP"), 10); page.feedHelp:SetPoint("TOPLEFT", 14, -31); page.feedHelp:SetWidth(225); page.feedHelp:SetHeight(28); page.feedHelp:SetJustifyH("LEFT"); page.feedHelp:SetJustifyV("TOP"); page.feedHelp:SetTextColor(unpack(MUTED))
    page.feedFR = FlatButton(page.settingsPanel, "FR", 105, 30); page.feedFR:SetPoint("TOPLEFT", 14, -62); page.feedFR:SetScript("OnClick", function() TE.db.profile.feedFilter = "FR"; TE:RefreshProfilePage(true); TE:RefreshActivitiesPage(true) end)
    page.feedAll = FlatButton(page.settingsPanel, "All", 105, 30); page.feedAll:SetPoint("LEFT", page.feedFR, "RIGHT", 8, 0); page.feedAll:SetScript("OnClick", function() TE.db.profile.feedFilter = "ALL"; TE:RefreshProfilePage(true); TE:RefreshActivitiesPage(true) end)

    page.appearanceTitle = SectionTitle(page.settingsPanel, self:L("WINDOW_APPEARANCE"), 14, -103)
    page.fadeInCombat = Toggle(page.settingsPanel, self:L("FADE_IN_COMBAT"), 232); page.fadeInCombat:SetPoint("TOPLEFT", 14, -124); page.fadeInCombat.OnToggle = function(_, value) TE.db.profile.fadeInCombat = value end
    page.fadeWhileMoving = Toggle(page.settingsPanel, self:L("FADE_WHILE_MOVING"), 232); page.fadeWhileMoving:SetPoint("TOPLEFT", 14, -157); page.fadeWhileMoving.OnToggle = function(_, value) TE.db.profile.fadeWhileMoving = value end

    page.notifyTitle = SectionTitle(page.settingsPanel, self:L("NOTIFICATIONS"), 265, -12)
    page.notifyNew = Toggle(page.settingsPanel, self:L("NOTIFY_NEW"), 420); page.notifyNew:SetPoint("TOPLEFT", 265, -35); page.notifyNew.OnToggle = function(_, value) TE.db.profile.notifyNew = value end
    page.notifyUpdates = Toggle(page.settingsPanel, self:L("NOTIFY_UPDATES"), 420); page.notifyUpdates:SetPoint("TOPLEFT", 265, -70); page.notifyUpdates.OnToggle = function(_, value) TE.db.profile.notifyUpdates = value end

    page.languageTitle = SectionTitle(page.settingsPanel, self:L("INTERFACE_LANGUAGE"), 710, -12)
    page.languageFR = FlatButton(page.settingsPanel, self:L("LANGUAGE_FRENCH"), 112, 30); page.languageFR:SetPoint("TOPLEFT", 710, -35)
    page.languageEN = FlatButton(page.settingsPanel, self:L("LANGUAGE_ENGLISH"), 112, 30); page.languageEN:SetPoint("LEFT", page.languageFR, "RIGHT", 8, 0)
    page.languageFR:SetScript("OnClick", function() TE:SetInterfaceLanguage("fr") end)
    page.languageEN:SetScript("OnClick", function() TE:SetInterfaceLanguage("en") end)

    page.scaleTitle = SectionTitle(page.settingsPanel, self:L("UI_SCALE"), 265, -108)
    -- Direct +/- controls are deliberately used instead of the old slider.
    -- On the 3.3.5 client the slider thumb could remain captured at its minimum,
    -- while these buttons always apply an exact one-percent change immediately.
    page.scaleMinus = FlatButton(page.settingsPanel, "-", 42, 30)
    page.scaleMinus:SetPoint("TOPLEFT", 265, -133)
    page.scaleMinus:SetScript("OnClick", function()
        local current = floor(((tonumber(TE.db.profile.uiScale) or 1) * 100) + 0.5)
        TE:SetUIScalePercent(current - 1)
    end)

    page.scaleValueHolder = CreateFrame("Frame", nil, page.settingsPanel)
    page.scaleValueHolder:SetPoint("LEFT", page.scaleMinus, "RIGHT", 8, 0)
    page.scaleValueHolder:SetWidth(82)
    page.scaleValueHolder:SetHeight(30)
    Backdrop(page.scaleValueHolder, PANEL_2, BORDER)
    page.scaleValue = Text(page.scaleValueHolder, "GameFontNormal", "100%", 13)
    page.scaleValue:SetPoint("CENTER", 0, 0)
    page.scaleValue:SetTextColor(unpack(ACCENT))

    page.scalePlus = FlatButton(page.settingsPanel, "+", 42, 30)
    page.scalePlus:SetPoint("LEFT", page.scaleValueHolder, "RIGHT", 8, 0)
    page.scalePlus:SetScript("OnClick", function()
        local current = floor(((tonumber(TE.db.profile.uiScale) or 1) * 100) + 0.5)
        TE:SetUIScalePercent(current + 1)
    end)

    page.fadeOpacityTitle = SectionTitle(page.settingsPanel, self:L("FADE_OPACITY"), 510, -108)
    page.fadeOpacityMinus = FlatButton(page.settingsPanel, "-", 42, 30); page.fadeOpacityMinus:SetPoint("TOPLEFT", 510, -133)
    page.fadeOpacityMinus:SetScript("OnClick", function()
        local current = floor(((tonumber(TE.db.profile.contextFadeAlpha) or 0.48) * 100) + 0.5)
        TE:SetFadeOpacityPercent(current - 1)
    end)
    page.fadeOpacityValueHolder = CreateFrame("Frame", nil, page.settingsPanel); page.fadeOpacityValueHolder:SetPoint("LEFT", page.fadeOpacityMinus, "RIGHT", 8, 0); page.fadeOpacityValueHolder:SetWidth(70); page.fadeOpacityValueHolder:SetHeight(30); Backdrop(page.fadeOpacityValueHolder, PANEL_2, BORDER)
    page.fadeOpacityValue = Text(page.fadeOpacityValueHolder, "GameFontNormal", "48%", 13); page.fadeOpacityValue:SetPoint("CENTER", 0, 0); page.fadeOpacityValue:SetTextColor(unpack(ACCENT))
    page.fadeOpacityPlus = FlatButton(page.settingsPanel, "+", 42, 30); page.fadeOpacityPlus:SetPoint("LEFT", page.fadeOpacityValueHolder, "RIGHT", 8, 0)
    page.fadeOpacityPlus:SetScript("OnClick", function()
        local current = floor(((tonumber(TE.db.profile.contextFadeAlpha) or 0.48) * 100) + 0.5)
        TE:SetFadeOpacityPercent(current + 1)
    end)

    page.showLauncher = Toggle(page.settingsPanel, self:L("SHOW_LAUNCHER"), 232); page.showLauncher:SetPoint("TOPLEFT", 710, -79); page.showLauncher.OnToggle = function(_, value) TE.db.profile.showLauncher = value; TE:UpdateLauncher() end
    page.save = FlatButton(page.settingsPanel, self:L("SAVE"), 165, 34); page.save:SetPoint("BOTTOMRIGHT", -14, 11); page.save:SetScript("OnClick", function() TE:BroadcastOwnProfile(true); TE:Print(TE:L("PROFILE_SAVED")); TE:RefreshAll(true) end)
    self.profilePage = page
end

function TE:RefreshProfilePage(force)
    local page = self.profilePage; if not page then return end
    page.avatar:SetTexture(self:GetOwnAvatar()); page.name:SetText(self:GetPlayerName()); if self.mainFrame and self.mainFrame.logo then self.mainFrame.logo:SetTexture(self:GetOwnAvatar()) end
    local presets = self:GetPortraitPresets(); local perPage = #page.portraitButtons; local maxPage = max(1, math.ceil(#presets / perPage)); page.portraitPage = min(max(1, page.portraitPage or 1), maxPage); local first = (page.portraitPage - 1) * perPage + 1
    for index, button in ipairs(page.portraitButtons) do
        local preset = presets[first + index - 1]
        if preset then button:Show(); button.texturePath = preset.texture; button.texture:SetTexture(preset.texture); if preset.texture == self:GetOwnAvatar() then button:SetBackdropBorderColor(unpack(ACCENT)) else button:SetBackdropBorderColor(unpack(BORDER)) end else button:Hide(); button.texturePath = nil end
    end
    page.portraitPageText:SetText(self:L("PAGE", page.portraitPage, maxPage)); SetEnabled(page.portraitPrev, page.portraitPage > 1); SetEnabled(page.portraitNext, page.portraitPage < maxPage)
    SetSelected(page.feedFR, self.db.profile.feedFilter == "FR")
    SetSelected(page.feedAll, self.db.profile.feedFilter ~= "FR")
    SetSelected(page.languageFR, self:GetLocaleCode() == "fr")
    SetSelected(page.languageEN, self:GetLocaleCode() == "en")
    page.notifyNew:SetChecked(self.db.profile.notifyNew ~= false)
    page.notifyUpdates:SetChecked(self.db.profile.notifyUpdates ~= false)
    page.fadeInCombat:SetChecked(self.db.profile.fadeInCombat ~= false)
    page.fadeWhileMoving:SetChecked(self.db.profile.fadeWhileMoving ~= false)
    page.showLauncher:SetChecked(self.db.profile.showLauncher ~= false)
    local fadePercent = floor((self.db.profile.contextFadeAlpha or 0.48) * 100 + 0.5)
    fadePercent = max(20, min(80, fadePercent))
    page.fadeOpacityValue:SetText(tostring(fadePercent) .. "%")
    SetEnabled(page.fadeOpacityMinus, fadePercent > 20)
    SetEnabled(page.fadeOpacityPlus, fadePercent < 80)
    local scalePercent = floor((self.db.profile.uiScale or 1) * 100 + 0.5)
    scalePercent = max(50, min(125, scalePercent))
    page.scaleValue:SetText(tostring(scalePercent) .. "%")
    SetEnabled(page.scaleMinus, scalePercent > 50)
    SetEnabled(page.scalePlus, scalePercent < 125)
end

function TE:SetUIScalePercent(percent)
    if not self.db or not self.db.profile then return end
    percent = floor((tonumber(percent) or 100) + 0.5)
    percent = max(50, min(125, percent))
    self.db.profile.uiScale = percent / 100

    if self.mainFrame then
        self.mainFrame:SetScale(self.db.profile.uiScale)
    end

    local page = self.profilePage
    if page then
        if page.scaleValue then page.scaleValue:SetText(tostring(percent) .. "%") end
        if page.scaleMinus then SetEnabled(page.scaleMinus, percent > 50) end
        if page.scalePlus then SetEnabled(page.scalePlus, percent < 125) end
    end
end

function TE:SetFadeOpacityPercent(percent)
    if not self.db or not self.db.profile then return end
    percent = floor((tonumber(percent) or 48) + 0.5)
    percent = max(20, min(80, percent))
    self.db.profile.contextFadeAlpha = percent / 100

    local page = self.profilePage
    if page then
        if page.fadeOpacityValue then page.fadeOpacityValue:SetText(tostring(percent) .. "%") end
        if page.fadeOpacityMinus then SetEnabled(page.fadeOpacityMinus, percent > 20) end
        if page.fadeOpacityPlus then SetEnabled(page.fadeOpacityPlus, percent < 80) end
    end
end

function TE:SetInterfaceLanguage(locale)
    locale = locale == "en" and "en" or "fr"
    if not self.db or not self.db.profile then return end
    self.db.profile.interfaceLanguage = locale
    self:ApplyUILanguage()
    self:RefreshAll(true)
end

function TE:ApplyUILanguage()
    local frame = self.mainFrame
    if frame then
        frame.title:SetText(self:L("BRAND"))
        frame.subtitle:SetText(self:L("SUBTITLE"))
        SetButtonText(frame.tabs.activities, self:L("TAB_ACTIVITIES"))
        SetButtonText(frame.tabs.guilds, self:L("TAB_GUILDS"))
        SetButtonText(frame.tabs.applications, self:L("TAB_APPLICATIONS"))
        SetButtonText(frame.tabs.profile, self:L("TAB_PROFILE"))
    end

    local page = self.activitiesPage
    if page then
        page.title:SetText(self:L("TAB_ACTIVITIES")); SetButtonText(page.create, self:L("CREATE")); SetButtonText(page.refresh, self:L("REFRESH")); SetButtonText(page.filterFR, self:L("FILTER_FR")); SetButtonText(page.filterAll, self:L("FILTER_ALL")); page.empty:SetText(self:L("NO_ACTIVITY")); SetButtonText(page.prev, self:L("PREVIOUS")); SetButtonText(page.next, self:L("NEXT")); page.descriptionTitle:SetText(self:L("DESCRIPTION")); page.rolesTitle:SetText(self:L("ROLES")); page.membersTitle:SetText(self:L("MEMBERS", 0, 0)); page.pendingTitle:SetText(self:L("PENDING", 0)); SetButtonText(page.join, self:L("JOIN")); SetButtonText(page.edit, self:L("EDIT")); SetButtonText(page.close, self:L("CLOSE")); SetButtonText(page.invite, self:L("INVITE_ALL")); page.selectHelp:SetText(self:L("SELECT_ACTIVITY"))
        for _, row in ipairs(page.applicantRows or {}) do SetButtonText(row.accept, self:L("ACCEPT")); SetButtonText(row.decline, self:L("DECLINE")) end
        for _, button in ipairs(page.roleButtons or {}) do SetButtonText(button, self:RoleLabel(button.role)) end
    end

    local popup = self.activityPopup
    if popup then
        popup.nameLabel:SetText(self:L("NAME")); popup.descLabel:SetText(self:L("DESCRIPTION")); popup.categoryLabel:SetText(self:L("CATEGORY")); SetButtonText(popup.pve, self:L("PVE")); SetButtonText(popup.pvp, self:L("PVP")); popup.typeLabel:SetText(self:L("TYPE")); popup.minLabel:SetText(self:L("MIN_LEVEL")); popup.maxLabel:SetText(self:L("MAX_LEVEL")); popup.slotsLabel:SetText(self:L("SLOTS")); popup.languageLabel:SetText(self:L("ACTIVITY_LANGUAGE")); popup.rolesLabel:SetText(self:L("ROLES")); popup.ownerRoleLabel:SetText(self:L("YOUR_ROLE")); popup.approvalLabel:SetText(self:L("APPROVAL")); SetButtonText(popup.auto, self:L("AUTO")); SetButtonText(popup.manual, self:L("MANUAL")); SetButtonText(popup.save, self:L("SAVE")); SetButtonText(popup.cancel, self:L("CANCEL")); popup.title:SetText(self:L(popup.editActivityID and "EDIT_TITLE" or "CREATE_TITLE"))
        for _, check in ipairs(popup.roleChecks or {}) do SetButtonText(check, self:RoleLabel(check.role)) end
        for _, button in ipairs(popup.ownerRoleButtons or {}) do SetButtonText(button, self:RoleLabel(button.role)) end
        self:RefreshActivityPopup()
    end

    page = self.guildsPage
    if page then
        page.title:SetText(self:L("GUILD_SEARCH_TITLE")); page.help:SetText(self:L("GUILD_SEARCH_HELP")); SetButtonText(page.refresh, self:L("REFRESH")); SetButtonText(page.publish, self:L("PUBLISH_GUILD")); page.empty:SetText(self:L("NO_GUILD")); SetButtonText(page.prev, self:L("PREVIOUS")); SetButtonText(page.next, self:L("NEXT")); page.descTitle:SetText(self:L("GUILD_AD_DESCRIPTION")); page.messageTitle:SetText(self:L("APPLY_MESSAGE")); SetButtonText(page.apply, self:L("APPLY")); page.selectHelp:SetText(self:L("SELECT_GUILD"))
    end

    popup = self.guildAdPopup
    if popup then
        popup.title:SetText(self:L("GUILD_AD_TITLE")); SetButtonText(popup.enabled, self:L("GUILD_AD_ENABLED")); popup.objectiveLabel:SetText(self:L("GUILD_OBJECTIVE")); popup.minLabel:SetText(self:L("MIN_LEVEL")); popup.maxLabel:SetText(self:L("MAX_LEVEL")); popup.descLabel:SetText(self:L("GUILD_AD_DESCRIPTION")); SetButtonText(popup.save, self:L("SAVE")); SetButtonText(popup.cancel, self:L("CANCEL"))
        for _, button in ipairs(popup.objectives or {}) do SetButtonText(button, self:ObjectiveLabel(button.objective)) end
    end

    page = self.applicationsPage
    if page then
        page.title:SetText(self:L("APPLICATIONS_TITLE")); page.empty:SetText(self:L("NO_APPLICATION")); SetButtonText(page.prev, self:L("PREVIOUS")); SetButtonText(page.next, self:L("NEXT")); page.messageTitle:SetText(self:L("APPLY_MESSAGE")); page.reasonTitle:SetText(self:L("REASON")); SetButtonText(page.accept, self:L("ACCEPT_AND_INVITE")); SetButtonText(page.decline, self:L("REFUSE")); page.selectHelp:SetText(self:L("NO_APPLICATION"))
    end

    page = self.profilePage
    if page then
        page.title:SetText(self:L("PROFILE_TITLE")); page.help:SetText(self:L("PROFILE_HELP")); page.pictureTitle:SetText(self:L("PROFILE_PICTURE")); SetButtonText(page.portraitPrev, self:L("PREVIOUS")); SetButtonText(page.portraitNext, self:L("NEXT")); page.feedTitle:SetText(self:L("PROFILE_FEED")); page.feedHelp:SetText(self:L("PROFILE_FEED_HELP")); page.notifyTitle:SetText(self:L("NOTIFICATIONS")); SetButtonText(page.notifyNew, self:L("NOTIFY_NEW")); SetButtonText(page.notifyUpdates, self:L("NOTIFY_UPDATES")); page.appearanceTitle:SetText(self:L("WINDOW_APPEARANCE")); SetButtonText(page.fadeInCombat, self:L("FADE_IN_COMBAT")); SetButtonText(page.fadeWhileMoving, self:L("FADE_WHILE_MOVING")); page.fadeOpacityTitle:SetText(self:L("FADE_OPACITY")); page.languageTitle:SetText(self:L("INTERFACE_LANGUAGE")); SetButtonText(page.languageFR, self:L("LANGUAGE_FRENCH")); SetButtonText(page.languageEN, self:L("LANGUAGE_ENGLISH")); page.scaleTitle:SetText(self:L("UI_SCALE")); SetButtonText(page.showLauncher, self:L("SHOW_LAUNCHER")); SetButtonText(page.save, self:L("SAVE"))
    end
end

-- --------------------------------------------------------------------------
-- Launcher and notifications
-- --------------------------------------------------------------------------
function TE:CreateLauncher()
    if self.launcher then return end
    local frame = CreateFrame("Button", "TousEnsembleLauncher", UIParent); frame:SetWidth(54); frame:SetHeight(54); frame:SetFrameStrata("MEDIUM"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:RegisterForDrag("RightButton"); frame:SetScript("OnDragStart", function(self) self:StartMoving() end); frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); TE:SaveFramePosition(self, "launcher") end); frame:SetScript("OnClick", function(_, button) if button == "LeftButton" then TE:Toggle() end end); Backdrop(frame, PANEL, ACCENT)
    self:ApplySavedPosition(frame, "launcher")
    frame.icon = frame:CreateTexture(nil, "ARTWORK"); frame.icon:SetPoint("TOPLEFT", 5, -5); frame.icon:SetPoint("BOTTOMRIGHT", -5, 5); frame.icon:SetTexture(self:GetOwnAvatar())
    frame.badge = CreateFrame("Frame", nil, frame); frame.badge:SetWidth(25); frame.badge:SetHeight(20); frame.badge:SetPoint("TOPRIGHT", 7, 7); Backdrop(frame.badge, {0.45, 0.05, 0.11, 1}, RED)
    frame.badgeText = Text(frame.badge, "GameFontNormal", "0", 10); frame.badgeText:SetPoint("CENTER")
    Tooltip(frame, function() local count = #TE:GetVisibleActivities(); return TE.displayName .. "\n" .. TE:L("GROUPS_ACTIVE", count) .. "\nClic gauche : ouvrir\nClic droit : déplacer" end)
    self.launcher = frame
end

function TE:UpdateLauncher()
    if not self.launcher then return end
    self.launcher.icon:SetTexture(self:GetOwnAvatar())
    local count = #self:GetVisibleActivities(); local unread = 0
    for _, notification in ipairs(self.db.notifications or {}) do if notification.unread then unread = unread + 1 end end
    self.launcher.badgeText:SetText(tostring(count)); ShowWhen(self.launcher.badge, count > 0)
    if self.db.profile.showLauncher ~= false then self.launcher:Show() else self.launcher:Hide() end
end

function TE:CreateToast()
    if self.toast then return end
    local frame = CreateFrame("Button", "TousEnsembleToast", UIParent); frame:SetWidth(470); frame:SetHeight(72); frame:SetPoint("TOP", UIParent, "TOP", 0, -90); frame:SetFrameStrata("DIALOG"); frame:Hide(); Backdrop(frame, PANEL, ACCENT)
    frame.icon = frame:CreateTexture(nil, "ARTWORK"); frame.icon:SetWidth(48); frame.icon:SetHeight(48); frame.icon:SetPoint("LEFT", 12, 0); frame.icon:SetTexture(self:GetOwnAvatar())
    frame.text = Text(frame, "GameFontNormal", "", 14); frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 13, 0); frame.text:SetPoint("RIGHT", -15, 0); frame.text:SetJustifyH("LEFT"); frame.text:SetWidth(380)
    frame:SetScript("OnClick", function() if frame.activityID then TE.selectedActivityID = frame.activityID end; TE:Toggle(); TE:ShowTab("activities"); frame:Hide() end)
    frame:SetScript("OnUpdate", function(self, elapsed) self.remaining = (self.remaining or 0) - elapsed; if self.remaining <= 0 then self:Hide() elseif self.remaining < 1 then self:SetAlpha(max(0, self.remaining)) else self:SetAlpha(1) end end)
    self.toast = frame
end

function TE:ShowToast(text, kind, activityID)
    if not self.toast then self:CreateToast() end
    local frame = self.toast; frame.icon:SetTexture(self:GetOwnAvatar()); frame.text:SetText(text or ""); frame.activityID = activityID; frame.remaining = 5; frame:SetAlpha(1)
    if kind == "success" then frame:SetBackdropBorderColor(unpack(GREEN)) elseif kind == "warning" then frame:SetBackdropBorderColor(unpack(RED)) elseif kind == "activity" then frame:SetBackdropBorderColor(unpack(GOLD)) else frame:SetBackdropBorderColor(unpack(ACCENT)) end
    frame:Show()
end

function TE:RefreshAll(force)
    if not self.mainFrame then return end
    self.statusText:SetText(self:L(self.serverChannelID and "SERVER_CHANNEL" or "SERVER_CHANNEL_WAIT"))
    self:RefreshActivitiesPage(force); self:RefreshGuildSearchPage(force); self:RefreshApplicationsPage(force); self:RefreshProfilePage(force); self:UpdateLauncher()
end

function TE:CreateUI()
    if self.uiCreated then return end
    self:CreateMainFrame(); self:CreateActivitiesPage(); self:CreateGuildSearchPage(); self:CreateApplicationsPage(); self:CreateProfilePage(); self:CreateLauncher(); self:CreateToast(); self.uiCreated = true; self:ApplyUILanguage(); self.mainFrame:Hide(); self:ShowTab(self.db.profile.lastTab or "activities"); self:UpdateLauncher()
end
