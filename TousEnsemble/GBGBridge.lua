-- Tous ensemble - passerelle native avec G.B.G 1.7+ / 1.8.x.
-- Les deux addons restent autonomes et n'écrivent jamais dans les SavedVariables de l'autre.

local TE = TousEnsemble
local max = math.max
local tonumber = tonumber
local tostring = tostring
local strlower = string.lower
local time = time

function TE:GBGEscape(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%", "%%25")
    value = string.gsub(value, "|", "%%7C")
    value = string.gsub(value, "\n", "%%0A")
    value = string.gsub(value, "\r", "%%0D")
    return value
end

function TE:GBGUnescape(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%0D", "\r")
    value = string.gsub(value, "%%0A", "\n")
    value = string.gsub(value, "%%7C", "|")
    value = string.gsub(value, "%%25", "%%")
    return value
end

function TE:SerializeGBGNameRoleMap(map)
    local values = {}
    for name, role in pairs(map or {}) do
        name = self:NormalizeName(name)
        role = self:NormalizeRole(role)
        if name ~= "" and role then values[#values + 1] = self:GBGEscape(name) .. "~" .. self:GBGEscape(role) end
    end
    table.sort(values)
    return table.concat(values, ";")
end

function TE:DeserializeGBGNameRoleMap(value)
    local result = {}
    for entry in string.gmatch(tostring(value or ""), "[^;]+") do
        local separator = string.find(entry, "~", 1, true)
        if separator then
            local name = self:NormalizeName(self:GBGUnescape(string.sub(entry, 1, separator - 1)))
            local role = self:NormalizeRole(self:GBGUnescape(string.sub(entry, separator + 1)))
            if name ~= "" and role then result[name] = role end
        end
    end
    return result
end

function TE:IsGuildMemberName(name)
    name = strlower(self:NormalizeName(name))
    if name == "" or not self:IsInGuild() then return false end
    if name == strlower(self:GetPlayerName()) then return true end
    if GuildRoster then pcall(GuildRoster) end
    local count = GetNumGuildMembers and GetNumGuildMembers(true) or 0
    for index = 1, count do
        local memberName = GetGuildRosterInfo and GetGuildRosterInfo(index)
        if strlower(self:NormalizeName(memberName)) == name then return true end
    end
    return false
end

function TE:BroadcastGBGProfile(priority)
    if not self:IsInGuild() then return end
    local name = self:GetPlayerName()
    local revision = tonumber(self.db.profile.avatarRevision) or 1
    local payload = table.concat({
        "P",
        self:GetGuildHash() or "",
        self:GBGEscape(name),
        tostring(revision),
        self:GBGEscape(self:GetGBGAvatarPath(self:GetOwnAvatar())),
        self:GBGEscape(self:GetOwnerID()),
        tostring(revision),
        self:GBGEscape(name),
    }, "|")
    self:QueueGBGPacket(payload, "GUILD", nil, priority)
end

function TE:BuildGBGActivityPayload(activity)
    activity = self:NormalizeActivity(activity)
    self:RefreshActivityOccupancy(activity)
    return table.concat({
        "DA",
        self:GetGuildHash() or "",
        self:GBGEscape(activity.id),
        tostring(activity.revision or 1),
        tostring(activity.createdAt or time()),
        tostring(activity.updatedAt or time()),
        tostring(activity.expiresAt or (time() + self.MAX_ACTIVITY_AGE)),
        self:GBGEscape(activity.owner),
        self:GBGEscape(activity.title),
        activity.category == "PVP" and "PVP" or "PVE",
        tostring(activity.minLevel or 1),
        tostring(activity.maxLevel or 60),
        tostring(activity.slots or 5),
        self:GBGEscape(activity.roles or "dps"),
        self:GBGEscape(self:SerializeGBGNameRoleMap(activity.members)),
        activity.approvalMode == "manual" and "manual" or "auto",
        "1",
        self:GBGEscape(self:SerializeGBGNameRoleMap(activity.pending)),
        tostring(activity.currentCount or 1),
        tostring(activity.groupCount or 1),
        self:GBGEscape(activity.activityType or ""),
        self:GBGEscape(activity.description or ""),
        self:GBGEscape(activity.ownerRole or "dps"),
    }, "|")
end

function TE:BroadcastActivityToGBG(activity, priority, target)
    if not self:IsInGuild() or not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return end
    self:QueueGBGPacket(self:BuildGBGActivityPayload(activity), target and "WHISPER" or "GUILD", target, priority)
end

function TE:CloseActivityToGBG(activity, reason)
    if not self:IsInGuild() or not activity then return end
    self:QueueGBGPacket(table.concat({
        "DC", self:GetGuildHash() or "", self:GBGEscape(activity.id), tostring(activity.revision or 1),
        self:GBGEscape(activity.owner), self:GBGEscape(reason or "closed")
    }, "|"), "GUILD", nil, true)
end

function TE:RequestGBGJoin(activity, role, leave)
    if not self:IsInGuild() or not activity then return false end
    role = self:NormalizeRole(role)
    if not leave and (not role or not self:HasRole(activity, role)) then self:Print(self:L("ROLE_REQUIRED")); return false end
    local action = leave and "leave" or "join"
    self:QueueGBGPacket(table.concat({
        "DJ", self:GetGuildHash() or "", self:GBGEscape(activity.id), self:GBGEscape(self:GetPlayerName()), self:GBGEscape(role or ""), action
    }, "|"), "GUILD", nil, true)
    if leave then self:Print(self:L("LEAVE_SENT")) else self:Print(self:L("JOIN_SENT", activity.owner)) end
    return true
end

function TE:CloseGBGActivity(activity)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return end
    activity.revision = (tonumber(activity.revision) or 1) + 1
    self:CloseActivityToGBG(activity, "closed")
    self:RemoveActivity(activity.id, "closed", activity.owner, true)
end

function TE:StoreGBGProfile(values, sender)
    local name = self:NormalizeName(self:GBGUnescape(values[3]))
    if name == "" then return end
    self:StoreProfile({
        name = name,
        revision = tonumber(values[4]) or 1,
        avatar = self:NormalizeAvatarPath(self:GBGUnescape(values[5])),
        level = 1,
        className = "",
        classFile = "",
        guildName = self:GetGuildName() or "",
        source = "GBG",
        sender = sender,
    })
end

function TE:StoreGBGActivity(values, sender)
    local owner = self:NormalizeName(self:GBGUnescape(values[8]))
    if owner == "" or owner ~= self:NormalizeName(sender) then return end
    local activity = {
        id = self:GBGUnescape(values[3]),
        revision = tonumber(values[4]) or 1,
        createdAt = tonumber(values[5]) or time(),
        updatedAt = tonumber(values[6]) or time(),
        expiresAt = tonumber(values[7]) or (time() + self.MAX_ACTIVITY_AGE),
        owner = owner,
        title = self:GBGUnescape(values[9]),
        category = values[10],
        minLevel = values[11],
        maxLevel = values[12],
        slots = values[13],
        roles = self:GBGUnescape(values[14]),
        members = self:DeserializeGBGNameRoleMap(self:GBGUnescape(values[15])),
        approvalMode = values[16],
        pending = self:DeserializeGBGNameRoleMap(self:GBGUnescape(values[18])),
        currentCount = values[19],
        groupCount = values[20],
        activityType = self:GBGUnescape(values[21]),
        description = self:GBGUnescape(values[22]),
        ownerRole = self:GBGUnescape(values[23]),
        language = "ALL",
        guildName = self:GetGuildName() or "",
        source = "GBG",
    }
    self:StoreActivity(activity, "GBG", sender, false)
end

function TE:HandleGBGPayload(payload, channel, sender)
    if not self:IsInGuild() then return end
    local values = self:Split(payload)
    local command = values[1]
    if values[2] ~= self:GetGuildHash() then return end
    sender = self:NormalizeName(sender)
    if sender == "" or sender == self:GetPlayerName() then return end
    if channel == "GUILD" and not self:IsGuildMemberName(sender) then return end

    if command == "P" then
        self:StoreGBGProfile(values, sender)
        if self.RefreshActivitiesPage then self:RefreshActivitiesPage(false) end
        return
    end

    if command == "DA" then
        self:StoreGBGActivity(values, sender)
        return
    end

    if command == "DJ" then
        local id = self:GBGUnescape(values[3])
        local player = self:NormalizeName(self:GBGUnescape(values[4]))
        local role = self:GBGUnescape(values[5])
        local action = values[6]
        local activity = self:GetActivity(id)
        if activity and activity.source ~= "GBG" and self:NormalizeName(activity.owner) == self:GetPlayerName() then
            self:ApplyJoinRequest(activity, player, role, action, sender)
        end
        return
    end

    if command == "DC" then
        local id = self:GBGUnescape(values[3])
        local owner = self:NormalizeName(self:GBGUnescape(values[5]))
        local activity = self:GetActivity(id)
        if activity and activity.source == "GBG" and owner == sender and self:NormalizeName(activity.owner) == sender then
            self:RemoveActivity(id, self:GBGUnescape(values[6]), owner, false)
        end
        return
    end

    if command == "DR" then
        for _, activity in pairs(self.db.activities or {}) do
            if activity.source ~= "GBG" and self:NormalizeName(activity.owner) == self:GetPlayerName() then
                self:BroadcastActivityToGBG(activity, false, sender)
            end
        end
        self:BroadcastGBGProfile(false)
        return
    end

    if command == "DM" then
        local id = self:GBGUnescape(values[3])
        local player = self:NormalizeName(self:GBGUnescape(values[4]))
        local role = self:NormalizeRole(self:GBGUnescape(values[5]))
        local activity = self:GetActivity(id)
        if activity and activity.source ~= "GBG" and self:NormalizeName(activity.owner) == self:GetPlayerName() and role and activity.members[player] then
            activity.members[player] = role
            activity.revision = (tonumber(activity.revision) or 1) + 1
            activity.updatedAt = time()
            self:BroadcastActivity(activity, true)
        end
    end
end

function TE:RequestGBGActivities()
    if not self:IsInGuild() then return end
    self:QueueGBGPacket(table.concat({"DR", self:GetGuildHash() or ""}, "|"), "GUILD", nil, true)
end
