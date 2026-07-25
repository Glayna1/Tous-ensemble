-- Tous ensemble - transports serveur, G.B.G et recrutement inter-guildes.

local TE = TousEnsemble
local floor = math.floor
local max = math.max
local tonumber = tonumber
local tostring = tostring
local strlower = string.lower
local time = time

local function Push(queue, value, priority)
    if priority then table.insert(queue, 1, value) else table.insert(queue, value) end
end

function TE:HideChannelFromChat(channelName)
    if not ChatFrame_RemoveChannel or not channelName then return end
    for index = 1, 10 do
        local frame = _G["ChatFrame" .. index]
        if frame then pcall(ChatFrame_RemoveChannel, frame, channelName) end
    end
end

function TE:JoinNamedChannel(channelName)
    if not channelName or channelName == "" then return nil end
    if JoinPermanentChannel then pcall(JoinPermanentChannel, channelName)
    elseif JoinChannelByName then pcall(JoinChannelByName, channelName) end
    local channelID
    if GetChannelName then
        local id = GetChannelName(channelName)
        if type(id) == "number" and id > 0 then channelID = id end
    end
    self:HideChannelFromChat(channelName)
    return channelID
end

function TE:JoinCommunityChannels()
    self.serverChannelID = self:JoinNamedChannel(self.serverChannelName) or self.serverChannelID
    self.recruitmentChannelID = self:JoinNamedChannel(self.recruitmentChannelName) or self.recruitmentChannelID
    if self.statusText and self.statusText.SetText then
        self.statusText:SetText(self:L(self.serverChannelID and "SERVER_CHANNEL" or "SERVER_CHANNEL_WAIT"))
    end
end

function TE:QueueServerRaw(text, priority)
    if not text or text == "" then return end
    self.serverSendQueue = self.serverSendQueue or {}
    Push(self.serverSendQueue, text, priority)
end

function TE:QueueServerPacket(payload, priority)
    payload = tostring(payload or "")
    if payload == "" then return end
    local header = self.serverWirePrefix .. "|"
    if string.len(header .. payload) <= 240 then
        self:QueueServerRaw(header .. payload, priority)
        return
    end
    self.serverPacketSerial = (self.serverPacketSerial or 0) + 1
    local packetID = self:Hash(self:GetPlayerName() .. ":server:" .. tostring(time()) .. ":" .. tostring(self.serverPacketSerial) .. ":" .. tostring(GetTime and GetTime() or 0))
    local chunkSize = 158
    local total = math.ceil(string.len(payload) / chunkSize)
    if total > 40 then return end
    for index = 1, total do
        local chunk = string.sub(payload, (index - 1) * chunkSize + 1, index * chunkSize)
        self:QueueServerRaw(header .. table.concat({"F", packetID, tostring(index), tostring(total), chunk}, "|"), priority and index == 1)
    end
end

function TE:QueueGBGRaw(payload, channel, target, priority)
    if not payload or payload == "" then return end
    self.gbgSendQueue = self.gbgSendQueue or {}
    Push(self.gbgSendQueue, {payload = payload, channel = channel or "GUILD", target = target}, priority)
end

function TE:QueueGBGPacket(payload, channel, target, priority)
    payload = tostring(payload or "")
    if payload == "" then return end
    if string.len(payload) <= 240 then
        self:QueueGBGRaw(payload, channel, target, priority)
        return
    end
    self.gbgPacketSerial = (self.gbgPacketSerial or 0) + 1
    local packetID = self:Hash(self:GetPlayerName() .. ":gbg:" .. tostring(time()) .. ":" .. tostring(self.gbgPacketSerial))
    local chunkSize = 170
    local total = math.ceil(string.len(payload) / chunkSize)
    if total > 20 then return end
    for index = 1, total do
        local chunk = string.sub(payload, (index - 1) * chunkSize + 1, index * chunkSize)
        self:QueueGBGRaw(table.concat({"F", packetID, tostring(index), tostring(total), chunk}, "|"), channel, target, priority and index == 1)
    end
end

function TE:QueueRecruitmentRaw(text, priority)
    if not text or text == "" then return end
    self.recruitmentSendQueue = self.recruitmentSendQueue or {}
    Push(self.recruitmentSendQueue, text, priority)
end

-- Tous ensemble deliberately transmits the legacy GBGR1 wire format. GBG 1.8.14
-- reads it and temporarily mirrors its protected GBGR2 replies back to legacy,
-- preserving compatibility across addon versions and factions.
function TE:QueueRecruitmentPacket(payload, priority)
    payload = tostring(payload or "")
    if payload == "" then return end
    local header = "GBGR1|"
    if string.len(header .. payload) <= 240 then
        self:QueueRecruitmentRaw(header .. payload, priority)
        return
    end
    self.recruitmentPacketSerial = (self.recruitmentPacketSerial or 0) + 1
    local packetID = self:Hash(self:GetPlayerName() .. ":recruit:" .. tostring(time()) .. ":" .. tostring(self.recruitmentPacketSerial))
    local chunkSize = 165
    local total = math.ceil(string.len(payload) / chunkSize)
    if total > 30 then return end
    for index = 1, total do
        local chunk = string.sub(payload, (index - 1) * chunkSize + 1, index * chunkSize)
        self:QueueRecruitmentRaw(header .. table.concat({"F", packetID, tostring(index), tostring(total), chunk}, "|"), priority and index == 1)
    end
end

function TE:SendNextQueuedPacket()
    if self.gbgSendQueue and #self.gbgSendQueue > 0 and SendAddonMessage then
        local item = table.remove(self.gbgSendQueue, 1)
        pcall(SendAddonMessage, self.gbgPrefix, item.payload, item.channel, item.target)
        return
    end
    if self.serverSendQueue and #self.serverSendQueue > 0 then
        local channelID = self.serverChannelID or self:JoinNamedChannel(self.serverChannelName)
        self.serverChannelID = channelID or self.serverChannelID
        if channelID and channelID > 0 and SendChatMessage then
            local text = table.remove(self.serverSendQueue, 1)
            pcall(SendChatMessage, text, "CHANNEL", nil, channelID)
            return
        end
    end
    if self.recruitmentSendQueue and #self.recruitmentSendQueue > 0 then
        local channelID = self.recruitmentChannelID or self:JoinNamedChannel(self.recruitmentChannelName)
        self.recruitmentChannelID = channelID or self.recruitmentChannelID
        if channelID and channelID > 0 and SendChatMessage then
            local text = table.remove(self.recruitmentSendQueue, 1)
            pcall(SendChatMessage, text, "CHANNEL", nil, channelID)
        end
    end
end

function TE:HandleFragment(storeName, sender, packetID, index, total, chunk, callback, maxParts)
    index = tonumber(index) or 0
    total = tonumber(total) or 0
    maxParts = maxParts or 40
    if packetID == "" or index < 1 or total < 1 or index > total or total > maxParts then return end
    self[storeName] = self[storeName] or {}
    local key = strlower(self:NormalizeName(sender)) .. ":" .. packetID
    local record = self[storeName][key]
    if not record then
        record = {parts = {}, count = 0, total = total, at = time()}
        self[storeName][key] = record
    end
    if record.total ~= total then self[storeName][key] = nil; return end
    if not record.parts[index] then
        record.parts[index] = chunk
        record.count = record.count + 1
    end
    if record.count >= total then
        local completed = {}
        for part = 1, total do
            if not record.parts[part] then return end
            completed[#completed + 1] = record.parts[part]
        end
        self[storeName][key] = nil
        callback(self, table.concat(completed), sender)
    end
end

function TE:HandleServerWire(message, sender)
    local prefix = self.serverWirePrefix .. "|"
    if string.sub(message, 1, string.len(prefix)) ~= prefix then return false end
    local wire = string.sub(message, string.len(prefix) + 1)
    if string.sub(wire, 1, 2) == "F|" then
        local packetID, index, total, chunk = string.match(wire, "^F|([^|]+)|(%d+)|(%d+)|(.*)$")
        if packetID then
            self:HandleFragment("serverFragments", sender, packetID, index, total, chunk, self.HandleServerPayload, 40)
        end
    else
        self:HandleServerPayload(wire, sender)
    end
    return true
end

function TE:HandleGBGFragment(payload, channel, sender)
    if string.sub(payload, 1, 2) ~= "F|" then
        self:HandleGBGPayload(payload, channel, sender)
        return
    end
    local packetID, index, total, chunk = string.match(payload, "^F|([^|]+)|(%d+)|(%d+)|(.*)$")
    if not packetID then return end
    self.gbgFragments = self.gbgFragments or {}
    local key = strlower(self:NormalizeName(sender)) .. ":" .. packetID
    local record = self.gbgFragments[key]
    index, total = tonumber(index) or 0, tonumber(total) or 0
    if index < 1 or total < 1 or index > total or total > 20 then return end
    if not record then
        record = {parts = {}, count = 0, total = total, channel = channel, at = time()}
        self.gbgFragments[key] = record
    end
    if record.total ~= total then self.gbgFragments[key] = nil; return end
    if not record.parts[index] then record.parts[index] = chunk; record.count = record.count + 1 end
    if record.count >= total then
        local completed = {}
        for part = 1, total do if not record.parts[part] then return end; completed[#completed + 1] = record.parts[part] end
        self.gbgFragments[key] = nil
        self:HandleGBGPayload(table.concat(completed), channel, sender)
    end
end

function TE:CHAT_MSG_ADDON(prefix, payload, channel, sender)
    if prefix ~= self.gbgPrefix or not payload or payload == "" then return end
    self:HandleGBGFragment(payload, channel, sender)
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local B64MAP = {}
for index = 1, string.len(B64) do B64MAP[string.sub(B64, index, index)] = index - 1 end

local function Base64Decode(data)
    local output = {}
    local index = 1
    local length = string.len(data)
    while index <= length do
        local a = B64MAP[string.sub(data, index, index)]
        local b = B64MAP[string.sub(data, index + 1, index + 1)]
        local c = B64MAP[string.sub(data, index + 2, index + 2)]
        local d = B64MAP[string.sub(data, index + 3, index + 3)]
        if a == nil or b == nil then return nil end
        local n = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
        output[#output + 1] = string.char(floor(n / 65536) % 256)
        if c ~= nil then output[#output + 1] = string.char(floor(n / 256) % 256) end
        if d ~= nil then output[#output + 1] = string.char(n % 256) end
        index = index + 4
    end
    return table.concat(output)
end

local function ByteXor(a, b)
    local result, bitValue = 0, 1
    for _ = 1, 8 do
        local aa = a % 2
        local bb = b % 2
        if aa ~= bb then result = result + bitValue end
        a = floor(a / 2)
        b = floor(b / 2)
        bitValue = bitValue * 2
    end
    return result
end

local function SeedFromString(value)
    local seed = 104729
    for index = 1, string.len(value) do
        seed = (seed * 131 + string.byte(value, index) + index * 17) % 2147483647
    end
    if seed <= 0 then seed = 104729 end
    return seed
end

local function CryptBytes(data, keyMaterial)
    local seed = SeedFromString(keyMaterial)
    local output = {}
    for index = 1, string.len(data) do
        seed = (seed * 48271) % 2147483647
        output[index] = string.char(ByteXor(string.byte(data, index), seed % 256))
    end
    return table.concat(output)
end

function TE:GetRecruitmentTransportKey(nonce)
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "Neutral"
    return table.concat({"GBG", "Recruitment", "188", self:GetRealmName(), faction, tostring(nonce or "")}, ":")
end

function TE:DecodeSecureRecruitmentPayload(encoded)
    local nonce, checksum, body = string.match(tostring(encoded or ""), "^([^.]+)%.([^.]+)%.(.+)$")
    if not nonce or not checksum or not body then return nil end
    local encrypted = Base64Decode(body)
    if not encrypted then return nil end
    local payload = CryptBytes(encrypted, self:GetRecruitmentTransportKey(nonce))
    if tostring(self:Hash(payload .. ":" .. nonce .. ":GBG188")) ~= tostring(checksum) then return nil end
    return payload
end

function TE:HandleRecruitmentFragment(sender, packetID, index, total, chunk, secure)
    local store = secure and "secureRecruitmentFragments" or "legacyRecruitmentFragments"
    local callback
    if secure then
        callback = function(selfRef, encoded, senderRef)
            local payload = selfRef:DecodeSecureRecruitmentPayload(encoded)
            if payload then selfRef:HandleRecruitmentPayload(payload, senderRef) end
        end
    else
        callback = self.HandleRecruitmentPayload
    end
    self:HandleFragment(store, sender, packetID, index, total, chunk, callback, secure and 40 or 30)
end

function TE:HandleRecruitmentWire(message, sender)
    if string.sub(message, 1, 6) == "GBGR2|" then
        local wire = string.sub(message, 7)
        if string.sub(wire, 1, 2) == "E|" then
            local payload = self:DecodeSecureRecruitmentPayload(string.sub(wire, 3))
            if payload then self:HandleRecruitmentPayload(payload, sender) end
        elseif string.sub(wire, 1, 2) == "F|" then
            local packetID, index, total, chunk = string.match(wire, "^F|([^|]+)|(%d+)|(%d+)|(.*)$")
            if packetID then self:HandleRecruitmentFragment(sender, packetID, index, total, chunk, true) end
        end
        return true
    end
    if string.sub(message, 1, 6) == "GBGR1|" then
        local wire = string.sub(message, 7)
        if string.sub(wire, 1, 2) == "F|" then
            local packetID, index, total, chunk = string.match(wire, "^F|([^|]+)|(%d+)|(%d+)|(.*)$")
            if packetID then self:HandleRecruitmentFragment(sender, packetID, index, total, chunk, false) end
        else
            self:HandleRecruitmentPayload(wire, sender)
        end
        return true
    end
    return false
end

function TE:CHAT_MSG_CHANNEL(message, sender, ...)
    message = tostring(message or "")
    sender = self:NormalizeName(sender)
    if self:HandleServerWire(message, sender) then return end
    self:HandleRecruitmentWire(message, sender)
end

function TE:CleanupFragments()
    local now = time()
    local names = {"serverFragments", "gbgFragments", "secureRecruitmentFragments", "legacyRecruitmentFragments"}
    for _, storeName in ipairs(names) do
        local store = self[storeName]
        if store then
            for key, record in pairs(store) do
                if now - (record.at or now) > 60 then store[key] = nil end
            end
        end
    end
end
