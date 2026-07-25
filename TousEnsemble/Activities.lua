-- Tous ensemble - activités serveur, profils et inscriptions.

local TE = TousEnsemble
local max = math.max
local min = math.min
local sort = table.sort
local tonumber = tonumber
local tostring = tostring
local strlower = string.lower
local time = time

local ROLE_ORDER = {tank = 1, heal = 2, dps = 3, support = 4}

function TE:NormalizeRole(role)
    role = strlower(tostring(role or ""))
    if role == "tank" then return "tank" end
    if role == "heal" or role == "healer" then return "heal" end
    if role == "dps" or role == "damage" or role == "damager" then return "dps" end
    if role == "support" then return "support" end
    return nil
end

function TE:RoleLabel(role)
    local key = {tank = "ROLE_TANK", heal = "ROLE_HEAL", dps = "ROLE_DPS", support = "ROLE_SUPPORT"}
    return self:L(key[self:NormalizeRole(role)] or "ROLE_DPS")
end

function TE:RoleIcon(role)
    local icons = {
        tank = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
        heal = "Interface\\Icons\\Spell_Holy_GreaterHeal",
        dps = "Interface\\Icons\\Ability_DualWield",
        support = "Interface\\Icons\\Spell_Holy_PowerWordShield",
    }
    return icons[self:NormalizeRole(role)] or self.DEFAULT_AVATAR
end

function TE:HasRole(activity, role)
    role = self:NormalizeRole(role)
    if not role then return false end
    for value in string.gmatch(activity and activity.roles or "", "[^,]+") do
        if self:NormalizeRole(value) == role then return true end
    end
    return false
end

function TE:SerializeNameRoleMap(map)
    local values = {}
    for name, role in pairs(map or {}) do
        role = self:NormalizeRole(role)
        name = self:NormalizeName(name)
        if name ~= "" and role then values[#values + 1] = self:Escape(name) .. "~" .. self:Escape(role) end
    end
    sort(values)
    return table.concat(values, ";")
end

function TE:DeserializeNameRoleMap(value)
    local result = {}
    for entry in string.gmatch(tostring(value or ""), "[^;]+") do
        local separator = string.find(entry, "~", 1, true)
        if separator then
            local name = self:NormalizeName(self:Unescape(string.sub(entry, 1, separator - 1)))
            local role = self:NormalizeRole(self:Unescape(string.sub(entry, separator + 1)))
            if name ~= "" and role then result[name] = role end
        end
    end
    return result
end

function TE:CountMap(map)
    local count = 0
    for _, value in pairs(map or {}) do if value then count = count + 1 end end
    return count
end

function TE:GetActivity(id)
    return self.db and self.db.activities and self.db.activities[id]
end

function TE:GetActivityOccupancy(activity)
    if not activity then return 0 end
    local registered = self:CountMap(activity.members)
    return max(registered, tonumber(activity.currentCount) or 0, tonumber(activity.groupCount) or 0, 1)
end

function TE:GetActivityAvailable(activity)
    return max(0, (tonumber(activity and activity.slots) or 1) - self:GetActivityOccupancy(activity))
end

function TE:NormalizeActivity(activity)
    if type(activity) ~= "table" then return nil end
    activity.id = tostring(activity.id or "")
    activity.owner = self:NormalizeName(activity.owner)
    activity.title = string.sub(self:Trim(activity.title), 1, 80)
    activity.description = string.sub(self:Trim(activity.description), 1, 500)
    activity.category = activity.category == "PVP" and "PVP" or "PVE"
    activity.activityType = string.sub(self:Trim(activity.activityType), 1, 40)
    if activity.activityType == "" then activity.activityType = activity.category == "PVP" and "OTHER_PVP" or "OTHER_PVE" end
    activity.minLevel = self:Clamp(activity.minLevel, 1, 255, 1)
    activity.maxLevel = self:Clamp(activity.maxLevel, activity.minLevel, 255, 60)
    activity.slots = self:Clamp(activity.slots, 1, 40, 5)
    activity.roles = tostring(activity.roles or "dps")
    activity.ownerRole = self:NormalizeRole(activity.ownerRole) or "dps"
    activity.approvalMode = activity.approvalMode == "manual" and "manual" or "auto"
    activity.language = activity.language == "FR" and "FR" or "ALL"
    activity.guildName = string.sub(self:Trim(activity.guildName), 1, 80)
    activity.members = activity.members or {}
    activity.pending = activity.pending or {}
    activity.revision = max(1, tonumber(activity.revision) or 1)
    activity.createdAt = tonumber(activity.createdAt) or time()
    activity.updatedAt = tonumber(activity.updatedAt) or activity.createdAt
    activity.expiresAt = tonumber(activity.expiresAt) or (time() + self.MAX_ACTIVITY_AGE)
    activity.groupCount = max(1, tonumber(activity.groupCount) or 1)
    activity.currentCount = max(self:CountMap(activity.members), activity.groupCount, tonumber(activity.currentCount) or 1)
    if activity.owner ~= "" and activity.source ~= "GBG" and not activity.members[activity.owner] then
        activity.members[activity.owner] = activity.ownerRole
    end
    return activity
end

function TE:AddNotification(kind, title, body, activityID)
    if not self.db then return end
    self.db.notifications = self.db.notifications or {}
    table.insert(self.db.notifications, 1, {
        kind = kind or "info",
        title = tostring(title or ""),
        body = tostring(body or ""),
        activityID = activityID,
        at = time(),
        unread = true,
    })
    while #self.db.notifications > 40 do table.remove(self.db.notifications) end
    if self.UpdateLauncher then self:UpdateLauncher() end
end

function TE:Notify(kind, text, activityID)
    self:AddNotification(kind, self.displayName, text, activityID)
    if self.ShowToast then self:ShowToast(text, kind, activityID) end
end

function TE:StoreActivity(activity, source, sender, silent)
    activity = self:NormalizeActivity(activity)
    if not activity or activity.id == "" or activity.owner == "" or activity.title == "" then return false end
    if activity.expiresAt <= time() then return false end
    if self.db.closedActivities[activity.id] and self.db.closedActivities[activity.id] > time() then return false end

    local current = self.db.activities[activity.id]
    -- A Tous ensemble server packet carries the FR/All flag and richer profile
    -- context. When the same activity is mirrored through G.B.G, keep the
    -- server copy instead of letting the compatibility mirror downgrade it.
    if current and current.source == "SERVER" and (source == "GBG" or activity.source == "GBG")
        and (tonumber(current.revision) or 0) >= activity.revision then
        current.lastSeen = time()
        return false
    end
    if current and (tonumber(current.revision) or 0) > activity.revision then return false end
    if current and (tonumber(current.revision) or 0) == activity.revision and (tonumber(current.updatedAt) or 0) > activity.updatedAt then return false end

    local me = self:GetPlayerName()
    local wasMember = current and current.members and current.members[me]
    local wasPending = current and current.pending and current.pending[me]
    local isNew = current == nil

    activity.source = source or activity.source or "SERVER"
    activity.sender = self:NormalizeName(sender or activity.owner)
    activity.lastSeen = time()
    self.db.activities[activity.id] = activity

    local isMember = activity.members and activity.members[me]
    local isPending = activity.pending and activity.pending[me]
    if not silent and me ~= activity.owner then
        if isNew and self.db.profile.notifyNew and self:PassesLanguageFilter(activity) then
            self:Notify("activity", self:L("NEW_ACTIVITY", activity.language, activity.title), activity.id)
        elseif current and self.db.profile.notifyUpdates and activity.revision > (tonumber(current.revision) or 0) then
            if not wasMember and isMember then
                self:Notify("success", self:L("JOIN_ACCEPTED", activity.title), activity.id)
            elseif not wasPending and isPending then
                self:Notify("info", self:L("JOIN_PENDING", activity.title), activity.id)
            elseif wasMember and not isMember and not isPending then
                self:Notify("warning", self:L("ACTIVITY_UPDATED", activity.title), activity.id)
            end
        end
    end

    self.activitiesDirty = true
    if self.RefreshActivitiesPage then self:RefreshActivitiesPage(true) end
    if self.UpdateLauncher then self:UpdateLauncher() end
    return true
end

function TE:RemoveActivity(id, reason, owner, silent)
    local activity = self:GetActivity(id)
    if not activity then return false end
    if owner and self:NormalizeName(owner) ~= self:NormalizeName(activity.owner) then return false end
    self.db.activities[id] = nil
    self.db.closedActivities[id] = time() + 600
    if self.selectedActivityID == id then self.selectedActivityID = nil end
    if not silent and activity.owner ~= self:GetPlayerName() and self.db.profile.notifyUpdates then
        self:Notify("warning", self:L("ACTIVITY_CLOSED", activity.title), id)
    end
    self.activitiesDirty = true
    if self.RefreshActivitiesPage then self:RefreshActivitiesPage(true) end
    if self.UpdateLauncher then self:UpdateLauncher() end
    return true
end

function TE:GetVisibleActivities()
    local output = {}
    for _, activity in pairs(self.db.activities or {}) do
        if type(activity) == "table" and activity.expiresAt > time() and self:PassesLanguageFilter(activity) then
            output[#output + 1] = activity
        end
    end
    sort(output, function(a, b)
        local aOwn = self:NormalizeName(a.owner) == self:GetPlayerName()
        local bOwn = self:NormalizeName(b.owner) == self:GetPlayerName()
        if aOwn ~= bOwn then return aOwn end
        local aOpen = self:GetActivityAvailable(a) > 0
        local bOpen = self:GetActivityAvailable(b) > 0
        if aOpen ~= bOpen then return aOpen end
        if (a.updatedAt or 0) ~= (b.updatedAt or 0) then return (a.updatedAt or 0) > (b.updatedAt or 0) end
        return strlower(a.title or "") < strlower(b.title or "")
    end)
    return output
end

function TE:BuildOwnProfilePayload()
    local localizedClass, classFile = UnitClass and UnitClass("player")
    return table.concat({
        "TP",
        tostring(self.db.profile.avatarRevision or 1),
        self:Escape(self:GetPlayerName()),
        tostring(UnitLevel and UnitLevel("player") or 1),
        self:Escape(localizedClass or ""),
        self:Escape(classFile or ""),
        self:Escape(self:GetOwnAvatar()),
        self:Escape(self:GetGuildName() or ""),
        self:Escape(self:GetLocaleCode()),
        tostring(self.version),
    }, "|")
end

function TE:BroadcastOwnProfile(priority)
    if not self.db then return end
    self:StoreProfile({
        name = self:GetPlayerName(),
        revision = self.db.profile.avatarRevision or 1,
        level = UnitLevel and UnitLevel("player") or 1,
        className = (UnitClass and UnitClass("player")) or "",
        classFile = select(2, UnitClass and UnitClass("player")) or "",
        avatar = self:GetOwnAvatar(),
        guildName = self:GetGuildName() or "",
        locale = self:GetLocaleCode(),
    })
    self:QueueServerPacket(self:BuildOwnProfilePayload(), priority)
    if self:IsInGuild() then self:BroadcastGBGProfile(priority) end
end

function TE:BuildActivityPayload(activity)
    activity = self:NormalizeActivity(activity)
    return table.concat({
        "TA",
        self:Escape(activity.id),
        tostring(activity.revision),
        tostring(activity.createdAt),
        tostring(activity.updatedAt),
        tostring(activity.expiresAt),
        self:Escape(activity.owner),
        self:Escape(activity.title),
        activity.category,
        tostring(activity.minLevel),
        tostring(activity.maxLevel),
        tostring(activity.slots),
        self:Escape(activity.roles),
        self:Escape(self:SerializeNameRoleMap(activity.members)),
        self:Escape(self:SerializeNameRoleMap(activity.pending)),
        activity.approvalMode,
        self:Escape(activity.activityType),
        self:Escape(activity.description),
        self:Escape(activity.ownerRole),
        activity.language,
        self:Escape(activity.guildName),
        tostring(activity.currentCount or 1),
        tostring(activity.groupCount or 1),
        tostring(self.version),
    }, "|")
end

function TE:BroadcastActivity(activity, priority)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return end
    self:RefreshActivityOccupancy(activity)
    self:QueueServerPacket(self:BuildActivityPayload(activity), priority)
    if self:IsInGuild() then self:BroadcastActivityToGBG(activity, priority) end
end

function TE:BroadcastOwnedActivities(priority)
    if not self.db then return end
    for _, activity in pairs(self.db.activities or {}) do
        if activity.source ~= "GBG" and self:NormalizeName(activity.owner) == self:GetPlayerName() and activity.expiresAt > time() then
            self:BroadcastActivity(activity, priority)
        end
    end
end

function TE:RequestServerState()
    self:QueueServerPacket(table.concat({"TR", self:Escape(self:GetPlayerName()), tostring(self.version)}, "|"), true)
end

function TE:RefreshActivityOccupancy(activity)
    if not activity then return end
    local oldGroup = tonumber(activity.groupCount) or 1
    local newGroup = self:GetGroupSize()
    activity.groupCount = max(1, newGroup)
    activity.currentCount = max(self:CountMap(activity.members), activity.groupCount)
    if newGroup ~= oldGroup and self:NormalizeName(activity.owner) == self:GetPlayerName() then
        activity.updatedAt = time()
        activity.revision = (tonumber(activity.revision) or 1) + 1
    end
end

function TE:RefreshOwnedActivityOccupancy()
    if not self.db then return end
    for _, activity in pairs(self.db.activities or {}) do
        if activity.source ~= "GBG" and self:NormalizeName(activity.owner) == self:GetPlayerName() then
            local oldCount = tonumber(activity.currentCount) or 1
            self:RefreshActivityOccupancy(activity)
            if activity.currentCount ~= oldCount then self:BroadcastActivity(activity, true) end
        end
    end
end

function TE:CreateActivity(data)
    data = data or {}
    local title = string.sub(self:Trim(data.title), 1, 80)
    if title == "" then self:Print(self:L("NAME_REQUIRED")); return false end
    local roles = tostring(data.roles or "")
    local ownerRole = self:NormalizeRole(data.ownerRole)
    if not ownerRole or not string.find("," .. roles .. ",", "," .. ownerRole .. ",", 1, true) then
        self:Print(self:L("ROLE_REQUIRED")); return false
    end
    local minLevel = self:Clamp(data.minLevel, 1, 255, 1)
    local maxLevel = self:Clamp(data.maxLevel, minLevel, 255, 60)
    local playerLevel = UnitLevel and UnitLevel("player") or 1
    if playerLevel < minLevel or playerLevel > maxLevel then
        minLevel = min(minLevel, playerLevel)
        maxLevel = max(maxLevel, playerLevel)
    end
    self.activitySerial = (self.activitySerial or 0) + 1
    local id = "te" .. self:Hash(self:GetRealmName() .. ":" .. self:GetPlayerName() .. ":" .. tostring(time()) .. ":" .. tostring(self.activitySerial) .. ":" .. tostring(GetTime and GetTime() or 0))
    local me = self:GetPlayerName()
    local activity = self:NormalizeActivity({
        id = id,
        revision = 1,
        createdAt = time(),
        updatedAt = time(),
        expiresAt = time() + self.MAX_ACTIVITY_AGE,
        owner = me,
        title = title,
        description = data.description,
        category = data.category,
        activityType = data.activityType,
        minLevel = minLevel,
        maxLevel = maxLevel,
        slots = data.slots,
        roles = roles,
        ownerRole = ownerRole,
        approvalMode = data.approvalMode,
        language = data.language,
        guildName = self:GetGuildName() or "",
        members = {[me] = ownerRole},
        pending = {},
        groupCount = self:GetGroupSize(),
        currentCount = self:GetGroupSize(),
        source = "SERVER",
    })
    self:StoreActivity(activity, "SERVER", me, true)
    self.selectedActivityID = id
    self:BroadcastActivity(activity, true)
    self:Print(self:L("CREATED"))
    return true
end

function TE:UpdateActivity(activity, data)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() or activity.source == "GBG" then return false end
    data = data or {}
    local title = string.sub(self:Trim(data.title), 1, 80)
    if title == "" then self:Print(self:L("NAME_REQUIRED")); return false end
    local ownerRole = self:NormalizeRole(data.ownerRole)
    local roles = tostring(data.roles or "")
    if not ownerRole or not string.find("," .. roles .. ",", "," .. ownerRole .. ",", 1, true) then
        self:Print(self:L("ROLE_REQUIRED")); return false
    end
    activity.title = title
    activity.description = data.description
    activity.category = data.category
    activity.activityType = data.activityType
    activity.minLevel = data.minLevel
    activity.maxLevel = data.maxLevel
    activity.slots = max(self:GetActivityOccupancy(activity), self:Clamp(data.slots, 1, 40, activity.slots))
    activity.roles = roles
    activity.ownerRole = ownerRole
    activity.approvalMode = data.approvalMode
    activity.language = data.language
    activity.guildName = self:GetGuildName() or ""
    activity.members[self:GetPlayerName()] = ownerRole
    activity.revision = (tonumber(activity.revision) or 1) + 1
    activity.updatedAt = time()
    activity.expiresAt = time() + self.MAX_ACTIVITY_AGE
    self:NormalizeActivity(activity)
    self:BroadcastActivity(activity, true)
    self:Print(self:L("UPDATED"))
    return true
end

function TE:CloseActivity(activity)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return false end
    if activity.source == "GBG" then
        self:CloseGBGActivity(activity)
        return true
    end
    activity.revision = (tonumber(activity.revision) or 1) + 1
    self:QueueServerPacket(table.concat({"TC", self:Escape(activity.id), tostring(activity.revision), self:Escape(activity.owner), "closed"}, "|"), true)
    if self:IsInGuild() then self:CloseActivityToGBG(activity, "closed") end
    self:RemoveActivity(activity.id, "closed", activity.owner, true)
    return true
end

function TE:RequestJoin(activity, role, leave)
    if not activity then return false end
    role = self:NormalizeRole(role)
    if activity.source == "GBG" then return self:RequestGBGJoin(activity, role, leave) end
    if not leave and not role then self:Print(self:L("ROLE_REQUIRED")); return false end
    if not leave and not self:HasRole(activity, role) then self:Print(self:L("ROLE_REQUIRED")); return false end
    if not leave and self:GetActivityAvailable(activity) <= 0 and not (activity.members and activity.members[self:GetPlayerName()]) then
        self:Print(self:L("ACTIVITY_FULL")); return false
    end
    local action = leave and "leave" or "join"
    local me = self:GetPlayerName()
    if self:NormalizeName(activity.owner) == me then return false end
    self:QueueServerPacket(table.concat({"TJ", self:Escape(activity.id), self:Escape(me), self:Escape(role or ""), action}, "|"), true)
    if leave then self:Print(self:L("LEAVE_SENT")) else self:Print(self:L("JOIN_SENT", activity.owner)) end
    return true
end

function TE:ApplyJoinRequest(activity, player, role, action, sender)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return false end
    player = self:NormalizeName(player)
    sender = self:NormalizeName(sender)
    role = self:NormalizeRole(role)
    if player == "" or strlower(player) ~= strlower(sender) then return false end
    activity.members = activity.members or {}
    activity.pending = activity.pending or {}
    if action == "leave" then
        activity.members[player] = nil
        activity.pending[player] = nil
        activity.revision = (tonumber(activity.revision) or 1) + 1
        activity.updatedAt = time()
        self:RefreshActivityOccupancy(activity)
        self:BroadcastActivity(activity, true)
        return true
    end
    if not role or not self:HasRole(activity, role) then return false end
    if activity.members[player] then return true end
    if self:GetActivityAvailable(activity) <= 0 then
        self:SendJoinNotice(activity, player, "declined", "full")
        return false
    end
    if activity.approvalMode == "manual" then
        activity.pending[player] = role
        self:SendJoinNotice(activity, player, "pending", "")
    else
        activity.members[player] = role
        activity.pending[player] = nil
        self:SendJoinNotice(activity, player, "accepted", "")
        self:InvitePlayerToGroupSilently(player)
    end
    activity.revision = (tonumber(activity.revision) or 1) + 1
    activity.updatedAt = time()
    activity.expiresAt = time() + self.MAX_ACTIVITY_AGE
    self:RefreshActivityOccupancy(activity)
    self:BroadcastActivity(activity, true)
    return true
end

function TE:SendJoinNotice(activity, player, status, reason)
    self:QueueServerPacket(table.concat({"TN", self:Escape(activity.id), self:Escape(player), self:Escape(status), self:Escape(reason or ""), self:Escape(activity.title)}, "|"), true)
end

function TE:AcceptApplicant(activity, player)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return false end
    player = self:NormalizeName(player)
    local role = activity.pending and activity.pending[player]
    if not role or self:GetActivityAvailable(activity) <= 0 then return false end
    activity.pending[player] = nil
    activity.members[player] = role
    activity.revision = (tonumber(activity.revision) or 1) + 1
    activity.updatedAt = time()
    activity.expiresAt = time() + self.MAX_ACTIVITY_AGE
    self:RefreshActivityOccupancy(activity)
    self:SendJoinNotice(activity, player, "accepted", "")
    self:InvitePlayerToGroupSilently(player)
    self:BroadcastActivity(activity, true)
    return true
end

function TE:DeclineApplicant(activity, player)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return false end
    player = self:NormalizeName(player)
    if not activity.pending or not activity.pending[player] then return false end
    activity.pending[player] = nil
    activity.revision = (tonumber(activity.revision) or 1) + 1
    activity.updatedAt = time()
    self:SendJoinNotice(activity, player, "declined", "manual")
    self:BroadcastActivity(activity, true)
    return true
end

function TE:InviteAllMembers(activity)
    if not activity or self:NormalizeName(activity.owner) ~= self:GetPlayerName() then return end
    local groupSet = self:GetGroupMemberSet()
    for player in pairs(activity.members or {}) do
        if self:NormalizeName(player) ~= self:GetPlayerName() and not groupSet[strlower(self:NormalizeName(player))] then
            if self:InvitePlayerToGroupSilently(player) then self:Print(self:L("INVITED", player)) end
        end
    end
end

function TE:HandleServerPayload(payload, sender)
    local values = self:Split(payload)
    local command = values[1]
    sender = self:NormalizeName(sender)
    if sender == "" then return end

    if command == "TP" then
        local name = self:NormalizeName(self:Unescape(values[3]))
        if name ~= sender then return end
        self:StoreProfile({
            revision = tonumber(values[2]) or 1,
            name = name,
            level = values[4],
            className = self:Unescape(values[5]),
            classFile = self:Unescape(values[6]),
            avatar = self:Unescape(values[7]),
            guildName = self:Unescape(values[8]),
            locale = self:Unescape(values[9]),
            remoteVersion = values[10],
        })
        if self.RefreshActivitiesPage then self:RefreshActivitiesPage(false) end
        return
    end

    if command == "TA" then
        local owner = self:NormalizeName(self:Unescape(values[7]))
        if owner ~= sender then return end
        local activity = {
            id = self:Unescape(values[2]),
            revision = values[3],
            createdAt = values[4],
            updatedAt = values[5],
            expiresAt = values[6],
            owner = owner,
            title = self:Unescape(values[8]),
            category = values[9],
            minLevel = values[10],
            maxLevel = values[11],
            slots = values[12],
            roles = self:Unescape(values[13]),
            members = self:DeserializeNameRoleMap(self:Unescape(values[14])),
            pending = self:DeserializeNameRoleMap(self:Unescape(values[15])),
            approvalMode = values[16],
            activityType = self:Unescape(values[17]),
            description = self:Unescape(values[18]),
            ownerRole = self:Unescape(values[19]),
            language = values[20],
            guildName = self:Unescape(values[21]),
            currentCount = values[22],
            groupCount = values[23],
            remoteVersion = values[24],
        }
        self:StoreActivity(activity, "SERVER", sender, false)
        return
    end

    if command == "TJ" then
        local id = self:Unescape(values[2])
        local player = self:NormalizeName(self:Unescape(values[3]))
        local role = self:Unescape(values[4])
        local action = values[5]
        local activity = self:GetActivity(id)
        if activity then self:ApplyJoinRequest(activity, player, role, action, sender) end
        return
    end

    if command == "TC" then
        local id = self:Unescape(values[2])
        local owner = self:NormalizeName(self:Unescape(values[4]))
        local activity = self:GetActivity(id)
        if activity and owner == sender and self:NormalizeName(activity.owner) == sender then
            self:RemoveActivity(id, self:Unescape(values[5]), owner, false)
        end
        return
    end

    if command == "TN" then
        local id = self:Unescape(values[2])
        local player = self:NormalizeName(self:Unescape(values[3]))
        if player ~= self:GetPlayerName() then return end
        local status = self:Unescape(values[4])
        local title = self:Unescape(values[6])
        if status == "accepted" then self:Notify("success", self:L("JOIN_ACCEPTED", title), id)
        elseif status == "pending" then self:Notify("info", self:L("JOIN_PENDING", title), id)
        elseif status == "declined" then self:Notify("warning", self:L("JOIN_DECLINED", title), id) end
        return
    end

    if command == "TR" then
        self:BroadcastOwnProfile(false)
        self:BroadcastOwnedActivities(false)
        return
    end
end
