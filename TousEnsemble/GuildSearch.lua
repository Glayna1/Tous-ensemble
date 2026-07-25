-- Tous ensemble - recherche de guilde compatible avec le protocole public G.B.G.

local TE = TousEnsemble
local max = math.max
local min = math.min
local sort = table.sort
local tonumber = tonumber
local tostring = tostring
local strlower = string.lower
local time = time
local date = date

function TE:GetGuildMemberCounts()
    if not self:IsInGuild() then return 0, 0 end
    if GuildRoster then pcall(GuildRoster) end
    local total, online = 0, 0
    if GetNumGuildMembers then
        total, online = GetNumGuildMembers(true)
        total = tonumber(total) or 0
        online = tonumber(online) or 0
    end
    return total, online
end

function TE:GetOwnGuildAdvertisement()
    if not self:IsInGuild() or not self.db or not self.db.guildAd then return nil end
    local settings = self.db.guildAd
    local total, online = self:GetGuildMemberCounts()
    return {
        guildKey = self:GetGuildHash() or "",
        revision = tonumber(settings.revision) or 0,
        enabled = settings.enabled == true,
        guildName = self:GetGuildName() or "",
        objective = settings.objective or "MIXED",
        mode = settings.mode or "manual",
        minLevel = self:Clamp(settings.minLevel, 1, 60, 1),
        maxLevel = self:Clamp(settings.maxLevel, 1, 60, 60),
        totalMembers = total,
        onlineMembers = online,
        description = string.sub(self:Trim(settings.description), 1, 700),
        bannerEncoded = "",
        guildImage = "Interface\\Icons\\INV_BannerPVP_02",
        updatedAt = settings.updatedAt or time(),
        publisher = self:GetPlayerName(),
    }
end

function TE:BuildGuildAdvertisementPayload(ad)
    return table.concat({
        "AD", self:GBGEscape(ad.guildKey), tostring(ad.revision or 0), ad.enabled and "1" or "0",
        self:GBGEscape(ad.guildName), self:GBGEscape(ad.objective), self:GBGEscape(ad.mode),
        tostring(ad.minLevel or 1), tostring(ad.maxLevel or 60), tostring(ad.totalMembers or 0), tostring(ad.onlineMembers or 0),
        self:GBGEscape(ad.description), self:GBGEscape(ad.bannerEncoded), self:GBGEscape(ad.guildImage),
        tostring(ad.updatedAt or time()), self:GBGEscape(ad.publisher), tostring(self.version)
    }, "|")
end

function TE:BroadcastGuildAdvertisement(priority)
    -- When G.B.G is installed, it remains the single authority for the guild
    -- advertisement. Tous ensemble only consumes the shared listing, avoiding
    -- competing revisions or duplicated applications.
    if _G.GlaynaBetterGuild and _G.GlaynaBetterGuild ~= self then return end
    local ad = self:GetOwnGuildAdvertisement()
    if not ad then return end
    self:QueueRecruitmentPacket(self:BuildGuildAdvertisementPayload(ad), priority)
end

function TE:SaveGuildAdvertisement(data)
    if not self:IsInGuild() then self:Print(self:L("GUILD_AD_REQUIRES_GUILD")); return false end
    data = data or {}
    local settings = self.db.guildAd
    settings.enabled = data.enabled == true
    settings.objective = data.objective == "PVE" and "PVE" or (data.objective == "PVP" and "PVP" or "MIXED")
    settings.minLevel = self:Clamp(data.minLevel, 1, 60, 1)
    settings.maxLevel = self:Clamp(data.maxLevel, settings.minLevel, 60, 60)
    settings.description = string.sub(self:Trim(data.description), 1, 700)
    settings.revision = max((tonumber(settings.revision) or 0) + 1, time())
    settings.updatedAt = time()
    self:BroadcastGuildAdvertisement(true)
    self:Print(self:L("GUILD_AD_SAVED"))
    return true
end

function TE:RequestRecruitmentAdvertisements()
    if not self.db then return end
    self:QueueRecruitmentPacket(table.concat({"RQ", self:GBGEscape(self:GetPlayerName()), tostring(self.version)}, "|"), true)
end

function TE:StoreGuildAdvertisement(ad)
    if not ad or ad.guildKey == "" or ad.guildName == "" then return false end
    local current = self.db.guildAds[ad.guildKey]
    if current and (tonumber(current.revision) or 0) > (tonumber(ad.revision) or 0) then
        current.lastSeen = time()
        return false
    end
    ad.minLevel = self:Clamp(ad.minLevel, 1, 60, 1)
    ad.maxLevel = self:Clamp(ad.maxLevel, ad.minLevel, 60, 60)
    ad.totalMembers = tonumber(ad.totalMembers) or 0
    ad.onlineMembers = tonumber(ad.onlineMembers) or 0
    ad.lastSeen = time()
    self.db.guildAds[ad.guildKey] = ad
    self.guildsDirty = true
    if self.RefreshGuildSearchPage then self:RefreshGuildSearchPage(true) end
    return true
end

function TE:GetGuildAdvertisements()
    local output = {}
    for _, ad in pairs(self.db.guildAds or {}) do
        if type(ad) == "table" and ad.enabled then output[#output + 1] = ad end
    end
    sort(output, function(a, b)
        if (a.onlineMembers or 0) ~= (b.onlineMembers or 0) then return (a.onlineMembers or 0) > (b.onlineMembers or 0) end
        return strlower(a.guildName or "") < strlower(b.guildName or "")
    end)
    return output
end

function TE:GetApplicationID(guildKey)
    return self:Hash(tostring(guildKey or "") .. ":" .. self:GetPlayerName())
end

function TE:GetMyApplicationForGuild(guildKey)
    local id = self:GetApplicationID(guildKey)
    return self.db.myApplications[id]
end

function TE:BuildApplicationPayload(record)
    local localizedClass, classFile = UnitClass and UnitClass("player")
    return table.concat({
        "AP", self:GBGEscape(record.guildKey), self:GBGEscape(record.guildName), self:GBGEscape(record.id), tostring(record.profileRevision or 1),
        self:GBGEscape(record.name), self:GBGEscape(record.fullName), tostring(record.level or 1), self:GBGEscape(localizedClass or record.className or ""),
        self:GBGEscape(classFile or record.classFile or ""), self:GBGEscape(self:GetGBGAvatarPath(record.avatar)), self:GBGEscape(record.message),
        tostring(record.appliedAt or time()), tostring(time()), tostring(self.version)
    }, "|")
end

function TE:SubmitGuildApplication(ad, message)
    if not ad then return false end
    if self:IsInGuild() then self:Print(self:L("APPLICATION_REQUIRES_GUILDLESS")); return false end
    message = string.sub(self:Trim(message), 1, 700)
    if message == "" then self:Print(self:L("APPLICATION_REQUIRES_MESSAGE")); return false end
    local id = self:GetApplicationID(ad.guildKey)
    local current = self.db.myApplications[id]
    local record = current or {
        id = id,
        guildKey = ad.guildKey,
        guildName = ad.guildName,
        profileRevision = 0,
        statusRevision = 0,
    }
    record.profileRevision = (tonumber(record.profileRevision) or 0) + 1
    record.name = self:GetPlayerName()
    record.fullName = self:GetPlayerFullName()
    record.level = UnitLevel and UnitLevel("player") or 1
    record.avatar = self:GetOwnAvatar()
    record.message = message
    record.appliedAt = current and current.appliedAt or time()
    record.status = "pending"
    record.reason = ""
    record.updatedAt = time()
    self.db.myApplications[id] = record
    self:QueueRecruitmentPacket(self:BuildApplicationPayload(record), true)
    self:Print(self:L(current and "APPLICATION_UPDATED" or "APPLICATION_SENT", ad.guildName))
    if self.RefreshGuildSearchPage then self:RefreshGuildSearchPage(true) end
    return true
end

function TE:BuildApplicationResponsePayload(record)
    return table.concat({
        "RS", self:GBGEscape(record.guildKey), self:GBGEscape(record.guildName), self:GBGEscape(record.id), tostring(record.statusRevision or 1),
        self:GBGEscape(record.name), self:GBGEscape(record.status), self:GBGEscape(record.reason or ""),
        tostring(record.updatedAt or time()), self:GBGEscape(record.acceptedBy or "")
    }, "|")
end

function TE:GetIncomingApplications()
    local output = {}
    local guildKey = self:GetGuildHash()
    for _, record in pairs(self.db.incomingApplications or {}) do
        if type(record) == "table" and record.guildKey == guildKey and record.status ~= "joined" then output[#output + 1] = record end
    end
    sort(output, function(a, b)
        if a.status ~= b.status then return a.status == "pending" end
        return (tonumber(a.appliedAt) or 0) > (tonumber(b.appliedAt) or 0)
    end)
    return output
end

function TE:AcceptGuildApplication(record)
    if not record or not self:IsInGuild() or record.guildKey ~= self:GetGuildHash() then return false end
    if CanGuildInvite and not CanGuildInvite() then return false end
    record.status = "accepted"
    record.statusRevision = (tonumber(record.statusRevision) or 0) + 1
    record.acceptedBy = self:GetPlayerName()
    record.updatedAt = time()
    self:QueueRecruitmentPacket(self:BuildApplicationResponsePayload(record), true)
    self:InvitePlayerToGuildSilently(record.name)
    self:Notify("success", self:L("ACCEPTED_NOTICE", record.name), nil)
    if self.RefreshApplicationsPage then self:RefreshApplicationsPage(true) end
    return true
end

function TE:DeclineGuildApplication(record, reason)
    if not record or not self:IsInGuild() or record.guildKey ~= self:GetGuildHash() then return false end
    record.status = "declined"
    record.reason = string.sub(self:Trim(reason), 1, 300)
    if record.reason == "" then record.reason = self:L("REASON_DEFAULT") end
    record.statusRevision = (tonumber(record.statusRevision) or 0) + 1
    record.acceptedBy = self:GetPlayerName()
    record.updatedAt = time()
    self:QueueRecruitmentPacket(self:BuildApplicationResponsePayload(record), true)
    self:Notify("warning", self:L("DECLINED_NOTICE", record.name), nil)
    if self.RefreshApplicationsPage then self:RefreshApplicationsPage(true) end
    return true
end

function TE:HandleRecruitmentPayload(payload, sender)
    payload = tostring(payload or "")
    sender = self:NormalizeName(sender)
    if sender == "" or sender == self:GetPlayerName() then return end

    self.recruitmentSeen = self.recruitmentSeen or {}
    local fingerprint = strlower(sender) .. ":" .. self:Hash(payload)
    local now = GetTime and GetTime() or 0
    if now - (tonumber(self.recruitmentSeen[fingerprint]) or -1000) < 15 then return end
    self.recruitmentSeen[fingerprint] = now

    local values = self:Split(payload)
    local command = values[1]

    if command == "AD" then
        local ad = {
            guildKey = self:GBGUnescape(values[2]),
            revision = tonumber(values[3]) or 0,
            enabled = values[4] == "1",
            guildName = self:GBGUnescape(values[5]),
            objective = self:GBGUnescape(values[6]),
            mode = self:GBGUnescape(values[7]),
            minLevel = values[8],
            maxLevel = values[9],
            totalMembers = values[10],
            onlineMembers = values[11],
            description = self:GBGUnescape(values[12]),
            bannerEncoded = self:GBGUnescape(values[13]),
            guildImage = self:GBGUnescape(values[14]),
            updatedAt = tonumber(values[15]) or 0,
            publisher = self:GBGUnescape(values[16]),
            remoteVersion = values[17],
        }
        self:StoreGuildAdvertisement(ad)
        return
    end

    if command == "RQ" then
        if self.db.guildAd and self.db.guildAd.enabled and self:IsInGuild() then self:BroadcastGuildAdvertisement(true) end
        return
    end

    if command == "AP" then
        local guildKey = self:GBGUnescape(values[2])
        if not self:IsInGuild() or guildKey ~= self:GetGuildHash() then return end
        local id = self:GBGUnescape(values[4])
        if id == "" then return end
        local incomingRevision = tonumber(values[5]) or 1
        local current = self.db.incomingApplications[id]
        local previousProfileRevision = current and (tonumber(current.profileRevision) or 0) or 0
        if current and incomingRevision < previousProfileRevision then return end
        local previousStatus = current and current.status or nil
        local record = current or {id = id, guildKey = guildKey, status = "pending", statusRevision = 1}
        record.guildName = self:GBGUnescape(values[3])
        record.profileRevision = incomingRevision
        record.name = self:NormalizeName(self:GBGUnescape(values[6]))
        record.fullName = self:GBGUnescape(values[7])
        record.level = self:Clamp(values[8], 1, 255, 1)
        record.className = self:GBGUnescape(values[9])
        record.classFile = self:GBGUnescape(values[10])
        record.avatar = self:NormalizeAvatarPath(self:GBGUnescape(values[11]))
        record.message = self:GBGUnescape(values[12])
        record.appliedAt = tonumber(values[13]) or time()
        record.lastSeen = time()
        record.source = sender
        if current and (previousStatus == "declined" or previousStatus == "withdrawn") and incomingRevision > previousProfileRevision then
            record.status = "pending"
            record.reason = ""
        end
        self.db.incomingApplications[id] = record
        self:Notify("activity", self:L("APPLICANT") .. " : " .. record.name, nil)
        if self.RefreshApplicationsPage then self:RefreshApplicationsPage(true) end
        return
    end

    if command == "RS" then
        local appID = self:GBGUnescape(values[4])
        local applicant = self:NormalizeName(self:GBGUnescape(values[6]))
        if applicant ~= self:GetPlayerName() then return end
        local record = self.db.myApplications[appID]
        if not record then
            record = {id = appID, guildKey = self:GBGUnescape(values[2]), guildName = self:GBGUnescape(values[3])}
            self.db.myApplications[appID] = record
        end
        local revision = tonumber(values[5]) or 0
        if revision < (tonumber(record.statusRevision) or 0) then return end
        record.statusRevision = revision
        record.status = self:GBGUnescape(values[7])
        record.reason = self:GBGUnescape(values[8])
        record.updatedAt = tonumber(values[9]) or time()
        record.acceptedBy = self:GBGUnescape(values[10])
        local statusText = record.status == "accepted" and self:L("STATUS_ACCEPTED") or (record.status == "declined" and self:L("STATUS_DECLINED") or self:L("STATUS_PENDING"))
        self:Notify(record.status == "accepted" and "success" or "warning", (record.guildName or "") .. " : " .. statusText, nil)
        if self.RefreshGuildSearchPage then self:RefreshGuildSearchPage(true) end
        return
    end

    if command == "JN" then
        local guildKey = self:GBGUnescape(values[2])
        local appID = self:GBGUnescape(values[3])
        local applicant = self:NormalizeName(self:GBGUnescape(values[4]))
        if self:IsInGuild() and guildKey == self:GetGuildHash() then
            local record = self.db.incomingApplications[appID]
            if record and self:NormalizeName(record.name) == applicant then
                record.status = "joined"
                record.statusRevision = (tonumber(record.statusRevision) or 0) + 1
                record.updatedAt = time()
                self:QueueRecruitmentPacket(self:BuildApplicationResponsePayload(record), true)
            end
        end
    end
end

function TE:CheckJoinedGuildApplication()
    if not self:IsInGuild() then return end
    local currentGuild = self:GetGuildName()
    for _, record in pairs(self.db.myApplications or {}) do
        if record.status ~= "joined" and record.guildName == currentGuild then
            record.status = "joined"
            record.statusRevision = (tonumber(record.statusRevision) or 0) + 1
            record.updatedAt = time()
            self:QueueRecruitmentPacket(table.concat({"JN", self:GBGEscape(record.guildKey), self:GBGEscape(record.id), self:GBGEscape(self:GetPlayerName()), tostring(time())}, "|"), true)
        end
    end
end
