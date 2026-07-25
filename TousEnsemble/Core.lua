-- Tous ensemble
-- Addon communautaire serveur pour WoW 3.3.5a / Ascension (Interface 30300).

TousEnsemble = TousEnsemble or {}
local TE = TousEnsemble

TE.name = "TousEnsemble"
TE.displayName = "Tous ensemble"
TE.version = "1.0.4"
TE.serverChannelName = "TousEnsemble"
TE.serverWirePrefix = "TES1"
TE.gbgPrefix = "GMG2"
TE.recruitmentChannelName = "GBGRecruit"
TE.DEFAULT_AVATAR = "Interface\\Icons\\INV_Misc_QuestionMark"
TE.DEFAULT_CUSTOM_AVATAR = "Interface\\AddOns\\TousEnsemble\\Media\\Characters\\custom_03"
TE.MAX_ACTIVITY_AGE = 14400
TE.MAX_PROFILE_AGE = 86400
TE.refreshInterval = 1

local floor = math.floor
local max = math.max
local min = math.min
local tostring = tostring
local tonumber = tonumber
local strlower = string.lower
local format = string.format
local time = time

TE.Locales = {
    fr = {
        BRAND = "TOUS ENSEMBLE",
        SUBTITLE = "Les activités du serveur, avec ou sans guilde",
        TAB_ACTIVITIES = "Activités",
        TAB_GUILDS = "Guildes",
        TAB_APPLICATIONS = "Candidatures",
        TAB_PROFILE = "Profil",
        CREATE = "Créer une activité",
        REFRESH = "Actualiser",
        FILTER_FR = "FR",
        FILTER_ALL = "All",
        FILTER_HELP_FR = "Affiche uniquement les activités dont le créateur a coché FR.",
        FILTER_HELP_ALL = "Affiche toutes les activités, qu'elles soient marquées FR ou All.",
        NO_ACTIVITY = "Aucune activité correspondant à ce filtre n'a encore été détectée.",
        SELECT_ACTIVITY = "Sélectionnez une activité pour afficher les détails.",
        OWNER = "Chef",
        GUILD = "Guilde",
        LEVELS = "Niveaux %d–%d",
        MEMBERS = "%d/%d inscrits",
        LANGUAGE = "Langue",
        INTERFACE_LANGUAGE = "Langue de l'interface",
        LANGUAGE_FRENCH = "Français",
        LANGUAGE_ENGLISH = "English",
        CATEGORY = "Catégorie",
        TYPE = "Type d'activité",
        DESCRIPTION = "Description",
        ROLES = "Rôles acceptés",
        JOIN = "S'inscrire",
        LEAVE = "Se désinscrire",
        CLOSE = "Fermer",
        EDIT = "Modifier",
        INVITE_ALL = "Inviter les inscrits",
        PENDING = "En attente : %d",
        ACCEPT = "Accepter",
        DECLINE = "Refuser",
        ROLE_TANK = "Tank",
        ROLE_HEAL = "Soigneur",
        ROLE_DPS = "Dégâts",
        ROLE_SUPPORT = "Soutien",
        ROLE_REQUIRED = "Choisissez votre rôle.",
        ACTIVITY_FULL = "Cette activité est complète.",
        ALREADY_PENDING = "Votre inscription est déjà en attente.",
        JOIN_SENT = "Inscription envoyée à %s.",
        LEAVE_SENT = "Désinscription envoyée.",
        JOIN_ACCEPTED = "Votre inscription à « %s » a été acceptée.",
        JOIN_PENDING = "Votre inscription à « %s » attend la validation du chef.",
        JOIN_DECLINED = "Votre inscription à « %s » a été refusée.",
        NEW_ACTIVITY = "Nouvelle activité %s : %s",
        ACTIVITY_UPDATED = "Activité mise à jour : %s",
        ACTIVITY_CLOSED = "L'activité « %s » est terminée.",
        GROUPS_ACTIVE = "%d groupe(s) en cours",
        CREATE_TITLE = "Créer une activité serveur",
        EDIT_TITLE = "Modifier l'activité",
        NAME = "Nom de l'activité",
        NAME_REQUIRED = "Indiquez un nom pour l'activité.",
        DESC_PLACEHOLDER = "Décrivez l'objectif, le lieu, l'horaire ou les prérequis...",
        PVE = "JcE",
        PVP = "JcJ",
        MIN_LEVEL = "Niveau min.",
        MAX_LEVEL = "Niveau max.",
        SLOTS = "Taille du groupe",
        APPROVAL = "Validation",
        AUTO = "Automatique",
        MANUAL = "Manuelle",
        YOUR_ROLE = "Votre rôle",
        ACTIVITY_LANGUAGE = "Visibilité linguistique",
        ACTIVITY_LANGUAGE_FR = "FR — visible dans FR et All",
        ACTIVITY_LANGUAGE_ALL = "All — visible uniquement dans All",
        SAVE = "Enregistrer",
        CANCEL = "Annuler",
        CREATED = "Activité créée et diffusée sur le serveur.",
        UPDATED = "Activité mise à jour.",
        PROFILE_TITLE = "Votre profil Tous ensemble",
        PROFILE_HELP = "Ce portrait est partagé avec les autres utilisateurs de Tous ensemble et, dans votre guilde, avec G.B.G.",
        PROFILE_PICTURE = "Image de profil",
        PROFILE_FEED = "Filtre des activités",
        PROFILE_FEED_HELP = "FR n'affiche que les groupes marqués FR. All affiche tout le monde.",
        NOTIFICATIONS = "Notifications",
        NOTIFY_NEW = "Nouvelles activités correspondant au filtre",
        NOTIFY_UPDATES = "Inscriptions, acceptations et groupes en cours",
        SHOW_LAUNCHER = "Afficher le mini bouton",
        UI_SCALE = "Échelle de l'interface",
        WINDOW_APPEARANCE = "Apparence de la fenêtre",
        FADE_IN_COMBAT = "Semi-transparente en combat",
        FADE_WHILE_MOVING = "Semi-transparente en déplacement",
        FADE_OPACITY = "Opacité en mode semi-transparent",
        PROFILE_SAVED = "Profil enregistré et partagé.",
        PREVIOUS = "Précédent",
        NEXT = "Suivant",
        PAGE = "Page %d/%d",
        GUILD_SEARCH_TITLE = "Recherche de guilde",
        GUILD_SEARCH_HELP = "Les annonces sont compatibles avec la recherche de guilde de G.B.G.",
        NO_GUILD = "Aucune guilde en recrutement n'a encore été détectée.",
        SELECT_GUILD = "Sélectionnez une guilde pour consulter son annonce.",
        GUILD_MEMBERS = "%d membres • %d en ligne",
        GUILD_LEVELS = "Niveaux recommandés : %d–%d",
        APPLY_MESSAGE = "Message de candidature",
        APPLY_PLACEHOLDER = "Présentez votre personnage et ce que vous recherchez...",
        APPLY = "Postuler",
        APPLICATION_SENT = "Candidature envoyée à %s.",
        APPLICATION_UPDATED = "Candidature mise à jour pour %s.",
        APPLICATION_REQUIRES_MESSAGE = "Écrivez un message avant de postuler.",
        APPLICATION_REQUIRES_GUILDLESS = "Vous devez quitter votre guilde avant de postuler.",
        STATUS_NONE = "Aucune candidature envoyée.",
        STATUS_PENDING = "En attente",
        STATUS_ACCEPTED = "Acceptée — invitation à venir",
        STATUS_DECLINED = "Refusée",
        STATUS_JOINED = "Rejoint la guilde",
        PUBLISH_GUILD = "Publier ma guilde",
        GUILD_AD_TITLE = "Annonce de votre guilde",
        GUILD_AD_ENABLED = "Annonce activée",
        GUILD_OBJECTIVE = "Objectif principal",
        GUILD_OBJECTIVE_PVE = "JcE",
        GUILD_OBJECTIVE_PVP = "JcJ",
        GUILD_OBJECTIVE_MIXED = "JcE & JcJ",
        GUILD_AD_DESCRIPTION = "Présentation de la guilde",
        GUILD_AD_SAVED = "Annonce de guilde enregistrée et diffusée.",
        GUILD_AD_REQUIRES_GUILD = "Vous devez être dans une guilde.",
        APPLICATIONS_TITLE = "Candidatures reçues",
        NO_APPLICATION = "Aucune candidature reçue pour votre guilde.",
        APPLICANT = "Candidat",
        APPLIED_AT = "Envoyée le %s",
        ACCEPT_AND_INVITE = "Accepter et guilder",
        REFUSE = "Refuser",
        REASON = "Motif du refus",
        REASON_DEFAULT = "La guilde a décidé de ne pas accepter cette candidature.",
        ACCEPTED_NOTICE = "Candidature de %s acceptée.",
        DECLINED_NOTICE = "Candidature de %s refusée.",
        SERVER_CHANNEL = "Canal communautaire connecté",
        SERVER_CHANNEL_WAIT = "Connexion au canal communautaire...",
        SOURCE_GBG = "G.B.G — activité de guilde",
        SOURCE_SERVER = "Tous ensemble — serveur",
        INVITED = "Invitation envoyée à %s.",
    },
    en = {
        BRAND = "TOGETHER",
        SUBTITLE = "Server-wide activities, with or without a guild",
        TAB_ACTIVITIES = "Activities",
        TAB_GUILDS = "Guilds",
        TAB_APPLICATIONS = "Applications",
        TAB_PROFILE = "Profile",
        CREATE = "Create activity",
        REFRESH = "Refresh",
        FILTER_FR = "FR",
        FILTER_ALL = "All",
        FILTER_HELP_FR = "Only show activities explicitly marked FR.",
        FILTER_HELP_ALL = "Show every activity, including FR and All.",
        NO_ACTIVITY = "No activity matching this filter has been detected yet.",
        SELECT_ACTIVITY = "Select an activity to view its details.",
        OWNER = "Leader",
        GUILD = "Guild",
        LEVELS = "Levels %d–%d",
        MEMBERS = "%d/%d registered",
        LANGUAGE = "Language",
        INTERFACE_LANGUAGE = "Interface language",
        LANGUAGE_FRENCH = "Français",
        LANGUAGE_ENGLISH = "English",
        CATEGORY = "Category",
        TYPE = "Activity type",
        DESCRIPTION = "Description",
        ROLES = "Accepted roles",
        JOIN = "Register",
        LEAVE = "Leave",
        CLOSE = "Close",
        EDIT = "Edit",
        INVITE_ALL = "Invite members",
        PENDING = "Pending: %d",
        ACCEPT = "Accept",
        DECLINE = "Decline",
        ROLE_TANK = "Tank",
        ROLE_HEAL = "Healer",
        ROLE_DPS = "Damage",
        ROLE_SUPPORT = "Support",
        ROLE_REQUIRED = "Choose your role.",
        ACTIVITY_FULL = "This activity is full.",
        ALREADY_PENDING = "Your registration is already pending.",
        JOIN_SENT = "Registration sent to %s.",
        LEAVE_SENT = "Registration removed.",
        JOIN_ACCEPTED = "Your registration for “%s” was accepted.",
        JOIN_PENDING = "Your registration for “%s” is awaiting approval.",
        JOIN_DECLINED = "Your registration for “%s” was declined.",
        NEW_ACTIVITY = "New %s activity: %s",
        ACTIVITY_UPDATED = "Activity updated: %s",
        ACTIVITY_CLOSED = "The activity “%s” has ended.",
        GROUPS_ACTIVE = "%d active group(s)",
        CREATE_TITLE = "Create server activity",
        EDIT_TITLE = "Edit activity",
        NAME = "Activity name",
        NAME_REQUIRED = "Enter an activity name.",
        DESC_PLACEHOLDER = "Describe the goal, location, schedule or requirements...",
        PVE = "PvE",
        PVP = "PvP",
        MIN_LEVEL = "Min level",
        MAX_LEVEL = "Max level",
        SLOTS = "Group size",
        APPROVAL = "Approval",
        AUTO = "Automatic",
        MANUAL = "Manual",
        YOUR_ROLE = "Your role",
        ACTIVITY_LANGUAGE = "Language visibility",
        ACTIVITY_LANGUAGE_FR = "FR — visible in FR and All",
        ACTIVITY_LANGUAGE_ALL = "All — visible only in All",
        SAVE = "Save",
        CANCEL = "Cancel",
        CREATED = "Activity created and broadcast server-wide.",
        UPDATED = "Activity updated.",
        PROFILE_TITLE = "Your Together profile",
        PROFILE_HELP = "This portrait is shared with Together users and, inside your guild, with G.B.G.",
        PROFILE_PICTURE = "Profile picture",
        PROFILE_FEED = "Activity filter",
        PROFILE_FEED_HELP = "FR shows only FR-marked groups. All shows everyone.",
        NOTIFICATIONS = "Notifications",
        NOTIFY_NEW = "New activities matching the filter",
        NOTIFY_UPDATES = "Registrations, approvals and active groups",
        SHOW_LAUNCHER = "Show mini button",
        UI_SCALE = "Interface scale",
        WINDOW_APPEARANCE = "Window appearance",
        FADE_IN_COMBAT = "Semi-transparent in combat",
        FADE_WHILE_MOVING = "Semi-transparent while moving",
        FADE_OPACITY = "Semi-transparent opacity",
        PROFILE_SAVED = "Profile saved and shared.",
        PREVIOUS = "Previous",
        NEXT = "Next",
        PAGE = "Page %d/%d",
        GUILD_SEARCH_TITLE = "Guild search",
        GUILD_SEARCH_HELP = "Advertisements are compatible with G.B.G guild search.",
        NO_GUILD = "No recruiting guild has been detected yet.",
        SELECT_GUILD = "Select a guild to view its advertisement.",
        GUILD_MEMBERS = "%d members • %d online",
        GUILD_LEVELS = "Recommended levels: %d–%d",
        APPLY_MESSAGE = "Application message",
        APPLY_PLACEHOLDER = "Introduce your character and what you are looking for...",
        APPLY = "Apply",
        APPLICATION_SENT = "Application sent to %s.",
        APPLICATION_UPDATED = "Application updated for %s.",
        APPLICATION_REQUIRES_MESSAGE = "Write a message before applying.",
        APPLICATION_REQUIRES_GUILDLESS = "You must leave your guild before applying.",
        STATUS_NONE = "No application sent.",
        STATUS_PENDING = "Pending",
        STATUS_ACCEPTED = "Accepted — invitation pending",
        STATUS_DECLINED = "Declined",
        STATUS_JOINED = "Joined guild",
        PUBLISH_GUILD = "Publish my guild",
        GUILD_AD_TITLE = "Your guild advertisement",
        GUILD_AD_ENABLED = "Advertisement enabled",
        GUILD_OBJECTIVE = "Main objective",
        GUILD_OBJECTIVE_PVE = "PvE",
        GUILD_OBJECTIVE_PVP = "PvP",
        GUILD_OBJECTIVE_MIXED = "PvE & PvP",
        GUILD_AD_DESCRIPTION = "Guild presentation",
        GUILD_AD_SAVED = "Guild advertisement saved and broadcast.",
        GUILD_AD_REQUIRES_GUILD = "You must be in a guild.",
        APPLICATIONS_TITLE = "Received applications",
        NO_APPLICATION = "No application received for your guild.",
        APPLICANT = "Applicant",
        APPLIED_AT = "Sent on %s",
        ACCEPT_AND_INVITE = "Accept and invite",
        REFUSE = "Decline",
        REASON = "Decline reason",
        REASON_DEFAULT = "The guild decided not to accept this application.",
        ACCEPTED_NOTICE = "%s's application was accepted.",
        DECLINED_NOTICE = "%s's application was declined.",
        SERVER_CHANNEL = "Community channel connected",
        SERVER_CHANNEL_WAIT = "Connecting to community channel...",
        SOURCE_GBG = "G.B.G — guild activity",
        SOURCE_SERVER = "Together — server",
        INVITED = "Invitation sent to %s.",
    },
}

function TE:GetLocaleCode()
    local configured = self.db and self.db.profile and self.db.profile.interfaceLanguage
    if configured == "fr" or configured == "en" then return configured end
    return "fr"
end

function TE:L(key, ...)
    local locale = self.Locales[self:GetLocaleCode()] or self.Locales.fr
    local value = locale[key] or self.Locales.fr[key] or key
    if select("#", ...) > 0 then
        local ok, result = pcall(string.format, value, ...)
        if ok then return result end
    end
    return value
end

local DEFAULTS = {
    version = 1,
    profile = {
        avatar = TE.DEFAULT_CUSTOM_AVATAR,
        avatarRevision = 1,
        feedFilter = "ALL",
        interfaceLanguage = "fr",
        notifyNew = true,
        notifyUpdates = true,
        showLauncher = true,
        uiScale = 1.00,
        fadeInCombat = true,
        fadeWhileMoving = true,
        contextFadeAlpha = 0.48,
        lastTab = "activities",
        launcherPoint = "CENTER",
        launcherRelativePoint = "CENTER",
        launcherX = -470,
        launcherY = 70,
        framePoint = "CENTER",
        frameRelativePoint = "CENTER",
        frameX = 0,
        frameY = 0,
    },
    account = {
        ownerID = "",
    },
    activities = {},
    profiles = {},
    guildAds = {},
    myApplications = {},
    incomingApplications = {},
    guildAd = {
        enabled = false,
        revision = 0,
        objective = "MIXED",
        minLevel = 1,
        maxLevel = 60,
        description = "",
        mode = "manual",
    },
    notifications = {},
    closedActivities = {},
}

local function CopyDefaults(defaults, target)
    if type(target) ~= "table" then target = {} end
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

function TE:Trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

function TE:Clamp(value, low, high, fallback)
    value = tonumber(value)
    if not value then value = fallback end
    value = tonumber(value) or low
    return max(low, min(high, floor(value + 0.5)))
end

function TE:Hash(text)
    local hash = 5381
    text = tostring(text or "")
    for index = 1, string.len(text) do
        hash = (hash * 33 + string.byte(text, index)) % 4294967296
    end
    return format("%08x", hash)
end

function TE:NormalizeName(name)
    name = tostring(name or "")
    name = string.gsub(name, "%s", "")
    return string.match(name, "^[^-]+") or name
end

function TE:GetPlayerName()
    return self:NormalizeName(UnitName and UnitName("player") or "")
end

function TE:GetPlayerFullName()
    return self:GetPlayerName()
end

function TE:GetRealmName()
    return GetRealmName and GetRealmName() or "UnknownRealm"
end

function TE:GetGuildName()
    local guildName = GetGuildInfo and GetGuildInfo("player")
    if guildName and guildName ~= "" then return guildName end
    return nil
end

function TE:GetGuildKey()
    local guildName = self:GetGuildName()
    if not guildName then return nil end
    return tostring(self:GetRealmName()) .. "::" .. tostring(guildName)
end

function TE:GetGuildHash()
    local key = self:GetGuildKey()
    return key and self:Hash(key) or nil
end

function TE:IsInGuild()
    return self:GetGuildKey() ~= nil
end

function TE:GetOwnerID()
    self.db.account = self.db.account or {}
    local ownerID = tostring(self.db.account.ownerID or "")
    if ownerID == "" then
        local seed = table.concat({self:GetRealmName(), self:GetPlayerName(), tostring(time()), tostring(GetTime and GetTime() or 0), tostring(math.random and math.random(1, 9999999) or 1)}, ":")
        ownerID = self:Hash(seed) .. self:Hash(seed .. ":TousEnsemble")
        self.db.account.ownerID = ownerID
    end
    return ownerID
end

function TE:Escape(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%", "%%25")
    value = string.gsub(value, "|", "%%7C")
    value = string.gsub(value, "\n", "%%0A")
    value = string.gsub(value, "\r", "%%0D")
    value = string.gsub(value, ";", "%%3B")
    value = string.gsub(value, "~", "%%7E")
    return value
end

function TE:Unescape(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%7E", "~")
    value = string.gsub(value, "%%3B", ";")
    value = string.gsub(value, "%%0D", "\r")
    value = string.gsub(value, "%%0A", "\n")
    value = string.gsub(value, "%%7C", "|")
    value = string.gsub(value, "%%25", "%%")
    return value
end

function TE:Split(value, separator)
    value = tostring(value or "")
    separator = separator or "|"
    local output = {}
    local start = 1
    while true do
        local position = string.find(value, separator, start, true)
        if not position then
            output[#output + 1] = string.sub(value, start)
            break
        end
        output[#output + 1] = string.sub(value, start, position - 1)
        start = position + string.len(separator)
    end
    return output
end

function TE:NormalizeAvatarPath(texture)
    texture = tostring(texture or "")
    if texture == "" then return self.DEFAULT_AVATAR end
    texture = string.gsub(texture, "Interface\\AddOns\\GBG\\Media\\Characters\\", "Interface\\AddOns\\TousEnsemble\\Media\\Characters\\")
    texture = string.gsub(texture, "Interface/AddOns/GBG/Media/Characters/", "Interface\\AddOns\\TousEnsemble\\Media\\Characters\\")
    return texture
end

function TE:GetGBGAvatarPath(texture)
    texture = self:NormalizeAvatarPath(texture)
    return string.gsub(texture, "Interface\\AddOns\\TousEnsemble\\Media\\Characters\\", "Interface\\AddOns\\GBG\\Media\\Characters\\")
end

function TE:GetOwnAvatar()
    return self:NormalizeAvatarPath(self.db and self.db.profile and self.db.profile.avatar or self.DEFAULT_CUSTOM_AVATAR)
end

function TE:GetProfile(name)
    local key = strlower(self:NormalizeName(name))
    if key == strlower(self:GetPlayerName()) then
        local _, className = UnitClass and UnitClass("player")
        local localizedClass, classFile = UnitClass and UnitClass("player")
        return {
            name = self:GetPlayerName(),
            avatar = self:GetOwnAvatar(),
            revision = self.db.profile.avatarRevision or 1,
            level = UnitLevel and UnitLevel("player") or 1,
            className = localizedClass or className or "",
            classFile = classFile or "",
            guildName = self:GetGuildName() or "",
            seenAt = time(),
        }
    end
    local profile = self.db and self.db.profiles and self.db.profiles[key]
    if profile and profile.avatar then profile.avatar = self:NormalizeAvatarPath(profile.avatar) end
    return profile
end

function TE:StoreProfile(profile)
    if type(profile) ~= "table" then return false end
    local name = self:NormalizeName(profile.name)
    if name == "" then return false end
    local key = strlower(name)
    local current = self.db.profiles[key]
    local revision = tonumber(profile.revision) or 1
    if current and revision < (tonumber(current.revision) or 0) then
        current.seenAt = time()
        return false
    end
    profile.name = name
    profile.avatar = self:NormalizeAvatarPath(profile.avatar)
    profile.revision = revision
    profile.level = self:Clamp(profile.level, 1, 255, 1)
    profile.seenAt = time()
    self.db.profiles[key] = profile
    return true
end

function TE:GetPortraitPresets()
    if self.portraitPresets then return self.portraitPresets end
    self.portraitPresets = {}
    for index = 1, 132 do
        self.portraitPresets[#self.portraitPresets + 1] = {
            name = "Portrait " .. tostring(index),
            texture = "Interface\\AddOns\\TousEnsemble\\Media\\Characters\\custom_" .. string.format("%02d", index),
        }
    end
    return self.portraitPresets
end

function TE:PassesLanguageFilter(activity)
    if not activity then return false end
    local filter = self.db and self.db.profile and self.db.profile.feedFilter or "ALL"
    if filter == "FR" then return activity.language == "FR" end
    return true
end

function TE:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff9a7cffTous ensemble|r  " .. tostring(message or "")) end
end

function TE:RunHiddenSlashCommand(command, playerName)
    command = self:Trim(command)
    playerName = self:Trim(playerName)
    if command == "" or playerName == "" or not ChatEdit_ParseText or not CreateFrame or not UIParent then return false end
    if string.sub(command, 1, 1) ~= "/" then command = "/" .. command end
    if string.find(command, "[\r\n]") or string.find(playerName, "[\r\n]") then return false end
    if not self.hiddenSlashEditBox then
        self.hiddenSlashEditBox = CreateFrame("EditBox", nil, UIParent)
        self.hiddenSlashEditBox:SetAutoFocus(false)
        self.hiddenSlashEditBox:Hide()
    end
    self.hiddenSlashEditBox:SetText(command .. " " .. playerName)
    local ok = pcall(ChatEdit_ParseText, self.hiddenSlashEditBox, 1)
    self.hiddenSlashEditBox:SetText("")
    self.hiddenSlashEditBox:Hide()
    return ok
end

function TE:InvitePlayerToGroupSilently(playerName)
    return self:RunHiddenSlashCommand(_G.SLASH_INVITE1 or "/invite", playerName)
end

function TE:InvitePlayerToGuildSilently(playerName)
    return self:RunHiddenSlashCommand(_G.SLASH_GUILD_INVITE1 or _G.SLASH_GUILDINVITE1 or "/ginvite", playerName)
end

function TE:IsGroupLeader()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        if UnitIsRaidLeader and UnitIsRaidLeader("player") then return true end
        if IsRaidLeader and IsRaidLeader() then return true end
        if UnitIsRaidOfficer and UnitIsRaidOfficer("player") then return true end
        return false
    end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        return IsPartyLeader and IsPartyLeader() or false
    end
    return true
end

function TE:GetGroupMemberSet()
    local result = {}
    local me = self:GetPlayerName()
    if me ~= "" then result[strlower(me)] = true end
    local raidCount = GetNumRaidMembers and GetNumRaidMembers() or 0
    if raidCount > 0 then
        for index = 1, raidCount do
            local name = GetRaidRosterInfo and GetRaidRosterInfo(index)
            name = self:NormalizeName(name)
            if name ~= "" then result[strlower(name)] = true end
        end
    else
        local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0
        for index = 1, partyCount do
            local name = UnitName and UnitName("party" .. index)
            name = self:NormalizeName(name)
            if name ~= "" then result[strlower(name)] = true end
        end
    end
    return result
end

function TE:GetGroupSize()
    local count = 0
    for _ in pairs(self:GetGroupMemberSet()) do count = count + 1 end
    return max(1, count)
end

function TE:SaveFramePosition(frame, prefix)
    if not frame or not self.db or not self.db.profile then return end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    self.db.profile[prefix .. "Point"] = point or "CENTER"
    self.db.profile[prefix .. "RelativePoint"] = relativePoint or "CENTER"
    self.db.profile[prefix .. "X"] = floor((x or 0) + 0.5)
    self.db.profile[prefix .. "Y"] = floor((y or 0) + 0.5)
end

function TE:ApplySavedPosition(frame, prefix)
    if not frame or not self.db or not self.db.profile then return end
    frame:ClearAllPoints()
    frame:SetPoint(
        self.db.profile[prefix .. "Point"] or "CENTER",
        UIParent,
        self.db.profile[prefix .. "RelativePoint"] or "CENTER",
        self.db.profile[prefix .. "X"] or 0,
        self.db.profile[prefix .. "Y"] or 0
    )
end

function TE:Persist()
    if self.db then self.db.lastSavedAt = time() end
end

function TE:InitializeDatabase()
    TousEnsembleDB = CopyDefaults(DEFAULTS, TousEnsembleDB or {})
    self.db = TousEnsembleDB
    self.db.profile.avatar = self:NormalizeAvatarPath(self.db.profile.avatar)
    self.db.profile.feedFilter = self.db.profile.feedFilter == "FR" and "FR" or "ALL"
    self.db.profile.interfaceLanguage = self.db.profile.interfaceLanguage == "en" and "en" or "fr"
    self.db.profile.uiScale = max(0.50, min(1.25, tonumber(self.db.profile.uiScale) or 1))
    self.db.profile.fadeInCombat = self.db.profile.fadeInCombat ~= false
    self.db.profile.fadeWhileMoving = self.db.profile.fadeWhileMoving ~= false
    self.db.profile.contextFadeAlpha = max(0.20, min(0.80, tonumber(self.db.profile.contextFadeAlpha) or 0.48))
    self:GetOwnerID()
end

function TE:ADDON_LOADED(addonName)
    if addonName ~= self.name then return end
    self:InitializeDatabase()
    if RegisterAddonMessagePrefix then pcall(RegisterAddonMessagePrefix, self.gbgPrefix) end
    self.loaded = true
end

function TE:PLAYER_LOGIN()
    if not self.db then self:InitializeDatabase() end
    self:JoinCommunityChannels()
    self:CreateUI()
    self:BroadcastOwnProfile(true)
    self:RequestServerState()
    self:RequestGBGActivities()
    self:RequestRecruitmentAdvertisements()
    self:RefreshAll(true)
end

function TE:PLAYER_LOGOUT()
    self:Persist()
end

function TE:PLAYER_GUILD_UPDATE()
    self.guildRosterDirty = true
    self:BroadcastOwnProfile(true)
    self:RequestGBGActivities()
    self:RequestRecruitmentAdvertisements()
    self:CheckJoinedGuildApplication()
    self:RefreshAll(true)
end

function TE:GUILD_ROSTER_UPDATE()
    self.guildRosterDirty = true
    self:RefreshAll(false)
end

function TE:PARTY_MEMBERS_CHANGED()
    self:RefreshOwnedActivityOccupancy()
end

function TE:RAID_ROSTER_UPDATE()
    self:RefreshOwnedActivityOccupancy()
end

function TE:UpdateAdaptiveWindowAlpha(elapsed)
    if not self.db or not self.db.profile then return end

    local frames = {self.mainFrame, self.activityPopup, self.guildAdPopup}
    local anyShown = false
    for _, frame in ipairs(frames) do
        if frame and frame:IsShown() then
            anyShown = true
            break
        end
    end

    if not anyShown then
        self.adaptiveWindowAlpha = 1
        for _, frame in ipairs(frames) do
            if frame then frame:SetAlpha(1) end
        end
        return
    end

    local profile = self.db.profile
    local inCombat = profile.fadeInCombat and (
        (UnitAffectingCombat and UnitAffectingCombat("player")) or
        (InCombatLockdown and InCombatLockdown())
    )
    local moving = profile.fadeWhileMoving and GetUnitSpeed and (GetUnitSpeed("player") or 0) > 0
    local target = (inCombat or moving) and (profile.contextFadeAlpha or 0.48) or 1
    target = max(0.20, min(1, tonumber(target) or 1))

    local current = tonumber(self.adaptiveWindowAlpha) or 1
    current = current + (target - current) * min(1, (tonumber(elapsed) or 0) * 8)
    if math.abs(current - target) < 0.01 then current = target end
    self.adaptiveWindowAlpha = current

    for _, frame in ipairs(frames) do
        if frame then
            if frame:IsShown() then frame:SetAlpha(current) else frame:SetAlpha(1) end
        end
    end
end

function TE:OnUpdate(elapsed)
    elapsed = tonumber(elapsed) or 0
    self:UpdateAdaptiveWindowAlpha(elapsed)
    self.elapsedSend = (self.elapsedSend or 0) + elapsed
    self.elapsedRefresh = (self.elapsedRefresh or 0) + elapsed
    self.elapsedBroadcast = (self.elapsedBroadcast or 0) + elapsed
    self.elapsedChannel = (self.elapsedChannel or 0) + elapsed

    if self.elapsedSend >= 0.20 then
        self.elapsedSend = 0
        self:SendNextQueuedPacket()
    end
    if self.elapsedRefresh >= self.refreshInterval then
        self.elapsedRefresh = 0
        self:PruneData()
        self:CleanupFragments()
        self:CheckJoinedGuildApplication()
        self:RefreshAll(false)
    end
    if self.elapsedBroadcast >= 15 then
        self.elapsedBroadcast = 0
        self:BroadcastOwnedActivities(false)
        self:BroadcastOwnProfile(false)
        if self.db.guildAd and self.db.guildAd.enabled then self:BroadcastGuildAdvertisement(false) end
    end
    if self.elapsedChannel >= 8 then
        self.elapsedChannel = 0
        self:JoinCommunityChannels()
    end
end

function TE:PruneData()
    if not self.db then return end
    local now = time()
    for id, activity in pairs(self.db.activities or {}) do
        if type(activity) ~= "table" or (tonumber(activity.expiresAt) or 0) <= now then
            self.db.activities[id] = nil
            if self.selectedActivityID == id then self.selectedActivityID = nil end
        end
    end
    for key, profile in pairs(self.db.profiles or {}) do
        if type(profile) ~= "table" or now - (tonumber(profile.seenAt) or now) > self.MAX_PROFILE_AGE then
            self.db.profiles[key] = nil
        end
    end
    for key, ad in pairs(self.db.guildAds or {}) do
        if type(ad) ~= "table" or now - (tonumber(ad.lastSeen) or now) > 604800 then
            self.db.guildAds[key] = nil
        end
    end
    for id, expiresAt in pairs(self.db.closedActivities or {}) do
        if tonumber(expiresAt) and expiresAt <= now then self.db.closedActivities[id] = nil end
    end
end

TE.eventFrame = CreateFrame("Frame")
TE.eventFrame:RegisterEvent("ADDON_LOADED")
TE.eventFrame:RegisterEvent("PLAYER_LOGIN")
TE.eventFrame:RegisterEvent("PLAYER_LOGOUT")
TE.eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
TE.eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
TE.eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
TE.eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
TE.eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
TE.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
TE.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if TE[event] then TE[event](TE, ...) end
end)
TE.eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if TE.loaded then TE:OnUpdate(elapsed) end
end)

SLASH_TOUSENSEMBLE1 = "/tousensemble"
SLASH_TOUSENSEMBLE2 = "/te"
SlashCmdList.TOUSENSEMBLE = function() TE:Toggle() end
