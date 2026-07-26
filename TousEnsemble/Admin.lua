-- Internal diagnostics for Tous ensemble.

local TE = TousEnsemble
local strlower = string.lower
local tostring = tostring
local tonumber = tonumber
local time = time

local ADMIN_NAMES = {
    glayna = true,
}

local originalStoreProfile = TE.StoreProfile

function TE:IsLocalAdmin()
    local name = self:NormalizeName(self:GetPlayerName())
    return ADMIN_NAMES[strlower(name or "")] == true
end

local function FormatSeenAt(timestamp)
    timestamp = tonumber(timestamp) or time()
    if date then return date("%H:%M:%S", timestamp) end
    return "-"
end

function TE:CaptureAdminProfile(profile)
    if not self.adminScanActive or type(profile) ~= "table" then return end
    local version = tostring(profile.remoteVersion or "")
    if version == "" then return end
    local name = self:NormalizeName(profile.name)
    if name == "" then return end

    self.adminUsers = self.adminUsers or {}
    self.adminUsers[strlower(name)] = {
        name = name,
        version = version,
        guildName = tostring(profile.guildName or ""),
        level = tonumber(profile.level) or 0,
        className = tostring(profile.className or ""),
        seenAt = time(),
    }

    if self.adminFrame and self.adminFrame:IsShown() then
        self:RefreshAdminPanel()
    end
end

TE.StoreProfile = function(self, profile)
    local result = originalStoreProfile(self, profile)
    self:CaptureAdminProfile(profile)
    return result
end

function TE:GetAdminUserList()
    local output = {}
    for _, user in pairs(self.adminUsers or {}) do
        output[#output + 1] = user
    end
    table.sort(output, function(a, b)
        return strlower(a.name or "") < strlower(b.name or "")
    end)
    return output
end

function TE:RefreshAdminPanel()
    local frame = self.adminFrame
    if not frame then return end

    local users = self:GetAdminUserList()
    frame.userCount:SetText(tostring(#users) .. " utilisateur(s) détecté(s)")

    local now = GetTime and GetTime() or 0
    if self.adminScanActive and now < (self.adminScanEndsAt or 0) then
        frame.status:SetText("Recherche en cours…")
    else
        self.adminScanActive = false
        frame.status:SetText("Scan terminé")
    end

    local rows = frame.rows
    local rowHeight = 25
    for index = 1, math.max(#users, #rows) do
        local row = rows[index]
        if not row and index <= #users then
            row = CreateFrame("Frame", nil, frame.scrollChild)
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -((index - 1) * rowHeight))
            row:SetPoint("TOPRIGHT", frame.scrollChild, "TOPRIGHT", 0, -((index - 1) * rowHeight))

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints(row)
            if index % 2 == 0 then
                row.bg:SetTexture(1, 1, 1, 0.035)
            else
                row.bg:SetTexture(1, 1, 1, 0.015)
            end

            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.name:SetWidth(150)
            row.name:SetJustifyH("LEFT")

            row.version = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.version:SetPoint("LEFT", row, "LEFT", 170, 0)
            row.version:SetWidth(95)
            row.version:SetJustifyH("LEFT")

            row.guild = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.guild:SetPoint("LEFT", row, "LEFT", 280, 0)
            row.guild:SetWidth(190)
            row.guild:SetJustifyH("LEFT")

            row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.level:SetPoint("LEFT", row, "LEFT", 485, 0)
            row.level:SetWidth(55)
            row.level:SetJustifyH("CENTER")

            row.seen = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.seen:SetPoint("LEFT", row, "LEFT", 545, 0)
            row.seen:SetWidth(80)
            row.seen:SetJustifyH("CENTER")

            rows[index] = row
        end

        if row then
            local user = users[index]
            if user then
                row.name:SetText(user.name or "?")
                row.version:SetText(user.version or "?")
                row.guild:SetText(user.guildName ~= "" and user.guildName or "—")
                row.level:SetText((user.level and user.level > 0) and tostring(user.level) or "—")
                row.seen:SetText(FormatSeenAt(user.seenAt))
                if tostring(user.version or "") == tostring(self.version or "") then
                    row.version:SetTextColor(0.35, 1.0, 0.45)
                else
                    row.version:SetTextColor(1.0, 0.75, 0.25)
                end
                row:Show()
            else
                row:Hide()
            end
        end
    end

    frame.scrollChild:SetHeight(math.max(1, #users) * rowHeight)
end

function TE:StartAdminScan()
    if not self:IsLocalAdmin() then return end

    self.adminUsers = {}
    self.adminScanActive = true
    local now = GetTime and GetTime() or 0
    self.adminScanEndsAt = now + 8

    local me = self:GetPlayerName()
    self.adminUsers[strlower(me)] = {
        name = me,
        version = tostring(self.version or "?"),
        guildName = self:GetGuildName() or "",
        level = UnitLevel and UnitLevel("player") or 0,
        className = (UnitClass and UnitClass("player")) or "",
        seenAt = time(),
    }

    self:RequestServerState()
    self:RefreshAdminPanel()
end

function TE:CreateAdminPanel()
    if self.adminFrame or not self:IsLocalAdmin() then return self.adminFrame end

    local frame = CreateFrame("Frame", "TousEnsembleAdminFrame", UIParent)
    frame:SetWidth(690)
    frame:SetHeight(470)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(selfFrame) selfFrame:StartMoving() end)
    frame:SetScript("OnDragStop", function(selfFrame) selfFrame:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    frame:SetBackdropColor(0.03, 0.03, 0.05, 0.98)
    frame:Hide()

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -23)
    title:SetText("Tous ensemble — diagnostic")

    frame.userCount = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.userCount:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    frame.userCount:SetText("0 utilisateur détecté")

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.status:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -52, -54)
    frame.status:SetText("Scan terminé")

    local refresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refresh:SetWidth(92)
    refresh:SetHeight(24)
    refresh:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -78)
    refresh:SetText("Actualiser")
    refresh:SetScript("OnClick", function() TE:StartAdminScan() end)

    local headerY = -116
    local headers = {
        {"Nom", 32, 150, "LEFT"},
        {"Version", 194, 95, "LEFT"},
        {"Guilde", 304, 190, "LEFT"},
        {"Niv.", 509, 55, "CENTER"},
        {"Vu", 569, 80, "CENTER"},
    }
    for _, info in ipairs(headers) do
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", frame, "TOPLEFT", info[2], headerY)
        text:SetWidth(info[3])
        text:SetJustifyH(info[4])
        text:SetText(info[1])
    end

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(1, 1, 1, 0.12)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -137)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -137)
    divider:SetHeight(1)

    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -145)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -48, 24)

    frame.scrollChild = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.scrollChild:SetWidth(630)
    frame.scrollChild:SetHeight(1)
    frame.scrollFrame:SetScrollChild(frame.scrollChild)
    frame.rows = {}

    frame:SetScript("OnUpdate", function(_, elapsed)
        frame.elapsed = (frame.elapsed or 0) + (tonumber(elapsed) or 0)
        if frame.elapsed < 0.25 then return end
        frame.elapsed = 0
        if TE.adminScanActive then TE:RefreshAdminPanel() end
    end)

    frame:SetScript("OnShow", function()
        TE:StartAdminScan()
    end)

    self.adminFrame = frame
    if UISpecialFrames then table.insert(UISpecialFrames, "TousEnsembleAdminFrame") end
    return frame
end

function TE:ShowAdminPanel()
    if not self:IsLocalAdmin() then return end
    local frame = self:CreateAdminPanel()
    if frame then frame:Show() end
end

SLASH_TOUSENSEMBLEADMIN1 = "/teadmin"
SlashCmdList.TOUSENSEMBLEADMIN = function()
    if TE:IsLocalAdmin() then TE:ShowAdminPanel() end
end
