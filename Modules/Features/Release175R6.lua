-- OrderOfTheLionGM v1.7.5 corrective release r6
-- Final integration pass: achievement pack, series ordering, event-safe trackers,
-- roster anomaly filtering, Activity layout repair and conservative UI polish.

if not OTLGM then return end

OTLGM.build = "stable-r7-20260723"
local R6 = { revision = 6 }
local A6 = OTLGM.achievements174
local LION_ICON_R6 = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest.tga"
local SAFE_ICON_R6 = "Interface\\Icons\\INV_Misc_Book_09"
local MAX_LEVEL_R6 = 60
local COPPER_PER_GOLD_R6 = 10000
local MAX_SET_R6 = 700

local function TrimR6(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function ShortNameR6(value)
    value = TrimR6(value)
    local dash = string.find(value, "-", 1, true)
    if dash then value = string.sub(value, 1, dash - 1) end
    return value
end

local function KeyR6(value)
    value = string.lower(ShortNameR6(value))
    value = string.gsub(value, "[^%w]", "")
    return value
end

local function CountR6(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function SetButtonTextR6(button, text)
    if not button then return end
    if button.text and button.text.SetText then button.text:SetText(text or "")
    elseif button.label156 and button.label156.SetText then button.label156:SetText(text or "") end
end

local function MoveR6(control, parent, x, y, width, height)
    if not control then return end
    if parent and control.SetParent and control.GetParent and control:GetParent() ~= parent then control:SetParent(parent) end
    control:ClearAllPoints()
    control:SetPoint("TOPLEFT", parent or control:GetParent(), "TOPLEFT", x, y)
    if width then control:SetWidth(width) end
    if height then control:SetHeight(height) end
end

local function IsPlayerR6(name)
    return KeyR6(name) ~= "" and KeyR6(name) == KeyR6(UnitName and UnitName("player") or "")
end

local function IsGuildMemberR6(self, name)
    local key = KeyR6(name)
    if key == "" then return false end
    local members = self.GetGuildMemberSet174 and self:GetGuildMemberSet174() or {}
    return members[key] ~= nil
end

local function GetGuildLeaderNameR6(self)
    self.runtime = self.runtime or {}
    local cached = self.runtime.guildLeaderR6
    if cached and cached.name and self:Now() - (cached.ts or 0) < 30 then return cached.name end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local name, member
    for name, member in pairs(db and db.roster or {}) do
        local rankIndex = tonumber(member and (member.rankIndex or member.guildRankIndex))
        local rank = string.lower(tostring(member and member.rank or ""))
        if rankIndex == 0 or string.find(rank, "guild leader", 1, true) or string.find(rank, "guild master", 1, true) or string.find(rank, "guildmaster", 1, true) then
            local result = ShortNameR6(member and member.name or name)
            self.runtime.guildLeaderR6 = { name = result, ts = self:Now() }
            return result
        end
    end
    local guildName, rankName, rankIndex = GetGuildInfo and GetGuildInfo("player")
    if guildName and tonumber(rankIndex) == 0 then return ShortNameR6(UnitName("player") or "") end
    return ""
end

local function FullGuildPartyR6(self)
    local group = self.GetGroupSnapshot174 and self:GetGroupSnapshot174() or nil
    if not group then return nil, false end
    return group, group.isParty and not group.isRaid and tonumber(group.total) == 5 and tonumber(group.guild) == 5
end

local function HasGuildPartnerR6(self)
    local group = self.GetGroupSnapshot174 and self:GetGroupSnapshot174() or nil
    if not group then return false end
    return tonumber(group.guild) and tonumber(group.guild) >= 2
end

local function AddSetR6(self, key, value)
    value = KeyR6(value)
    if value == "" then return false end
    local set = self:GetAchievementSet174(key)
    if set[value] then return false end
    if CountR6(set) >= MAX_SET_R6 then return false end
    set[value] = true
    return true
end

local function AddAchievementR6(def)
    if not A6 or not def or not def.id or A6.byId[def.id] then return false end
    table.insert(A6.catalog, def)
    A6.byId[def.id] = def
    return true
end

-- 21 definitions from the new implementation pack that were not already present.
local ADDITIONS_R6 = {
    {id="D001",category="SOCIAL",name="A Witness to Sixty",description="Be there when a guild member reaches the maximum level.",icon="Interface\\Icons\\Spell_Holy_PrayerOfSpirit",progress="witnessMaxLevelR6",required=1},
    {id="D002",category="SOCIAL",name="Together, We Grow Stronger",description="Gain ten levels while grouped with the same guild member.",icon="Interface\\Icons\\Spell_Holy_DevotionAura",progress="partnerLevelBestR6",required=10},
    {id="D003",category="SOCIAL",name="Perfect Roll",description="Win an item with a perfect 100 Need or Greed roll.",icon="Interface\\Icons\\INV_Misc_Dice_02",progress="perfectRollR6",required=1},
    {id="D004",category="SOCIAL",name="So Close",description="Lose an item with a roll of 99 to a guild member who rolled 100.",icon="Interface\\Icons\\INV_Misc_Dice_01",progress="soCloseR6",required=1},
    {id="D005",category="SOCIAL",name="For the Greater Good",description="Pass on an epic item in a full guild party.",icon="Interface\\Icons\\INV_Misc_Gem_01",progress="epicPassR6",required=1},
    {id="D006",category="SOCIAL",name="Everybody Passes",description="Have every member of a full guild party pass on the same item.",icon="Interface\\Icons\\INV_Misc_GroupNeedMore",progress="everybodyPassesR6",required=1},
    {id="D007",category="SOCIAL",name="Generous Tip",description="Give a guild member at least one gold and receive nothing in return.",icon="Interface\\Icons\\INV_Misc_Coin_01",progress="generousTipR6",required=1},
    {id="D008",category="SOCIAL",name="Mail Call",description="Send an item to a guild member through the in-game mail.",icon="Interface\\Icons\\INV_Letter_15",progress="mailCallR6",required=1},
    {id="D009",category="SOCIAL",name="Pen Pals",description="Receive mail from ten different guild members.",icon="Interface\\Icons\\INV_Misc_Note_02",progress="mailGuildSendersR6",required=10},
    {id="D010",category="SOCIAL",name="Roll of Fate",description="Roll 100 with /roll while in a full guild party.",icon="Interface\\Icons\\INV_Misc_Dice_02",progress="rollOfFateR6",required=1},
    {id="D011",category="SOCIAL",name="Rise, Commander",description="Successfully resurrect the Guild Leader with a standard resurrection spell.",icon="Interface\\Icons\\Spell_Holy_Resurrection",progress="riseCommanderR6",required=1},
    {id="D012",category="RAIDS",name="The World Is Watching",description="Defeat a world boss with at least ten guild members present.",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",progress="worldBossR6",required=1},
    {id="D013",category="LEGACY",name="The Final Step",description="Reach the maximum level while grouped with a guild member.",icon="Interface\\Icons\\INV_Crown_01",progress="finalStepR6",required=1},
    {id="D014",category="LEGACY",name="First Fortune",description="Carry at least one hundred gold on this character.",icon="Interface\\Icons\\INV_Misc_Coin_02",progress="moneyCopperR6",required=1000000,unitR6="gold"},
    {id="D015",category="LEGACY",name="Cloth Merchant",description="Carry a full stack of every core cloth type at the same time.",icon="Interface\\Icons\\INV_Fabric_Mageweave_01",progress="coreClothStacksR6",required=5},
    {id="D016",category="LEGACY",name="Packed Lunch",description="Carry twenty different kinds of food at the same time.",icon="Interface\\Icons\\INV_Misc_Food_15",progress="uniqueFoodR6",required=20},
    {id="D017",category="LEGACY",name="Traveling Apothecary",description="Carry ten different potions or elixirs at the same time.",icon="Interface\\Icons\\INV_Potion_01",progress="uniquePotionsR6",required=10},
    {id="D018",category="LEGACY",name="Living Legend",description="Link a legendary item you own in guild chat.",icon="Interface\\Icons\\INV_Misc_Gem_Pearl_05",progress="livingLegendR6",required=1},
    {id="D019",category="SECRETS",name="Absolutely Broke",description="The title is your clue.",revealed="Stand in a faction capital with exactly zero copper.",icon="Interface\\Icons\\INV_Misc_Coin_01",progress="absolutelyBrokeR6",required=1,secret=true},
    {id="D020",category="SECRETS",name="Exact Change",description="The title is your clue.",revealed="Give the current Guild Leader exactly one copper and receive nothing.",icon="Interface\\Icons\\INV_Misc_Coin_01",progress="exactChangeR6",required=1,secret=true},
    {id="D021",category="SECRETS",name="Gravity Wins",description="The title is your clue.",revealed="Die from falling damage while grouped with a guild member.",icon="Interface\\Icons\\Ability_Rogue_Sprint",progress="gravityWinsR6",required=1,secret=true},
}

local i
for i=1,table.getn(ADDITIONS_R6) do AddAchievementR6(ADDITIONS_R6[i]) end
if A6 then A6.catalogRevision = math.max(tonumber(A6.catalogRevision) or 0, 12) end

-- Series keep their existing published names, but share an icon and sort together.
local SERIES_R6 = {
    {key="resurrection",icon="Interface\\Icons\\Spell_Holy_Resurrection",ids={"B068","C001","C002","C003"}},
    {key="partners",icon="Interface\\Icons\\INV_Misc_GroupNeedMore",ids={"A013","A020","C004","C005","C006"}},
    {key="groupTime",icon="Interface\\Icons\\INV_Misc_PocketWatch_01",ids={"A018","C007","C008","C009","C010"}},
    {key="dungeonBosses",icon="Interface\\Icons\\INV_Misc_Key_03",ids={"A043","C011","A050","C012","C013"}},
    {key="fullDungeons",icon=LION_ICON_R6,ids={"B070","B071","B072","C014","C015"}},
    {key="raidBosses",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",ids={"A055","C016","A064","C017","C018"}},
    {key="craftActions",icon="Interface\\Icons\\Trade_BlackSmithing",ids={"B079","C019","C020","C021"}},
    {key="groupApplications",icon="Interface\\Icons\\INV_Letter_15",ids={"A021","C022","C023","C024"}},
    {key="acceptedApplications",icon="Interface\\Icons\\Spell_Holy_SealOfSalvation",ids={"A023","C025","C026"}},
    {key="crafterContacts",icon="Interface\\Icons\\INV_Misc_Rune_01",ids={"A040","C027","C028","C029"}},
    {key="announcementReactions",icon="Interface\\Icons\\INV_Misc_Note_01",ids={"A007","C030","C031","C032"}},
    {key="publishedRecipes",icon="Interface\\Icons\\INV_Scroll_03",ids={"A032","C033","C034"}},
    {key="riding",icon="Interface\\Icons\\Ability_Mount_RidingHorse",ids={"B080","B081"}},
}

local function ApplySeriesR6()
    if not A6 then return end
    local catalogIndex = {}
    local index, def, series, tier
    for index=1,table.getn(A6.catalog or {}) do
        def=A6.catalog[index]
        catalogIndex[def.id]=index
        def.catalogIndexR6=index
    end
    for index=1,table.getn(SERIES_R6) do
        series=SERIES_R6[index]
        local firstIndex=999999
        for tier=1,table.getn(series.ids) do
            if catalogIndex[series.ids[tier]] and catalogIndex[series.ids[tier]]<firstIndex then firstIndex=catalogIndex[series.ids[tier]] end
        end
        for tier=1,table.getn(series.ids) do
            def=A6.byId[series.ids[tier]]
            if def then
                def.seriesKeyR6=series.key
                def.seriesTierR6=tier
                def.seriesOrderR6=firstIndex
                def.icon=series.icon
            end
        end
    end
    local neutral={"UNDER_BANNER","A044","A054","B051","B063","B073","B083"}
    for index=1,table.getn(neutral) do if A6.byId[neutral[index]] then A6.byId[neutral[index]].icon=LION_ICON_R6 end end
end
ApplySeriesR6()

local BaseProgressR6 = OTLGM.GetAchievementProgress174
function OTLGM:GetAchievementProgress174(def)
    if not def or string.sub(tostring(def.id or ""),1,1) ~= "D" then return BaseProgressR6(self,def) end
    local db=self:EnsureAchievements174()
    if db.completed[def.id] then return def.required or 1,def.required or 1 end
    local key=def.progress
    local current=0
    if key=="mailGuildSendersR6" then current=CountR6(self:GetAchievementSet174(key))
    else current=tonumber(db.counters[key]) or 0 end
    return math.min(current,def.required or 1),def.required or 1
end

local BaseDisplayListR6 = OTLGM.GetAchievementDisplayList174
function OTLGM:GetAchievementDisplayList174()
    ApplySeriesR6()
    local list=BaseDisplayListR6(self)
    local category=OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.achievementCategory174 or "OVERVIEW"
    local function StateRank(def)
        if self:IsAchievementComplete174(def.id) then return 1 end
        local current=self:GetAchievementProgress174(def)
        if not def.secret and tonumber(current)>0 then return 2 end
        return 3
    end
    table.sort(list,function(left,right)
        if category=="OVERVIEW" then
            local ls,rs=StateRank(left),StateRank(right)
            if ls~=rs then return ls<rs end
        end
        local lo=tonumber(left.seriesOrderR6) or tonumber(left.catalogIndexR6) or 999999
        local ro=tonumber(right.seriesOrderR6) or tonumber(right.catalogIndexR6) or 999999
        if lo~=ro then return lo<ro end
        local lt=tonumber(left.seriesTierR6) or 1
        local rt=tonumber(right.seriesTierR6) or 1
        if lt~=rt then return lt<rt end
        return tostring(left.name or "")<tostring(right.name or "")
    end)
    return list
end

local BaseRefreshAchievementsR6 = OTLGM.RefreshAchievements174
function OTLGM:RefreshAchievements174()
    ApplySeriesR6()
    BaseRefreshAchievementsR6(self)
    local index,row,def,current,required
    for index=1,table.getn(self.ui and self.ui.achievementRows174 or {}) do
        row=self.ui.achievementRows174[index]
        def=row and row.achievement174
        if def and row:IsVisible() then
            if row.icon174 then row.icon174:SetTexture(def.icon or SAFE_ICON_R6) end
            if def.unitR6=="gold" and not self:IsAchievementComplete174(def.id) then
                current,required=self:GetAchievementProgress174(def)
                row.status174:SetText(tostring(math.floor((current or 0)/COPPER_PER_GOLD_R6)).." / "..tostring(math.floor((required or 0)/COPPER_PER_GOLD_R6)).."g")
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Roster anomaly filtering. Large same-minute JOIN/LEAVE bursts are retained in
-- SavedVariables for forensic review but excluded from summaries and default UI.
-- ---------------------------------------------------------------------------

local function BuildAnomalyBucketsR6(self,days)
    local db=self:GetGuildDB()
    local cutoff=self:Now()-((days or 7)*86400)
    local counts={}
    local index,eventInfo,bucket
    for index=1,table.getn(db and db.log or {}) do
        eventInfo=db.log[index]
        if eventInfo.ts and eventInfo.ts>=cutoff and (eventInfo.kind=="JOIN" or eventInfo.kind=="LEAVE") then
            bucket=math.floor((tonumber(eventInfo.ts) or 0)/300)
            counts[bucket]=(counts[bucket] or 0)+1
        end
    end
    local threshold=math.max(25,math.floor((tonumber(db and db.lastTotal) or 0)*0.08))
    local bad={}
    for bucket,index in pairs(counts) do if index>=threshold then bad[bucket]=true end end
    return bad
end

local function IsAnomalousEventR6(eventInfo,bad)
    if not eventInfo or not eventInfo.ts or (eventInfo.kind~="JOIN" and eventInfo.kind~="LEAVE") then return false end
    return bad[math.floor((tonumber(eventInfo.ts) or 0)/300)] and true or false
end

local BaseGetStatsR6=OTLGM.GetStats
function OTLGM:GetStats(days)
    local stats=BaseGetStatsR6(self,days)
    local db=self:GetGuildDB()
    local cutoff=self:Now()-((days or 7)*86400)
    local bad=BuildAnomalyBucketsR6(self,days)
    local joins,leaves=0,0
    local index,eventInfo
    for index=1,table.getn(db and db.log or {}) do
        eventInfo=db.log[index]
        if eventInfo.ts and eventInfo.ts>=cutoff and not IsAnomalousEventR6(eventInfo,bad) then
            if eventInfo.kind=="JOIN" then joins=joins+1 end
            if eventInfo.kind=="LEAVE" then leaves=leaves+1 end
        end
    end
    stats.joins=joins stats.leaves=leaves stats.net=joins-leaves
    stats.anomalyBatchesR6=CountR6(bad)
    return stats
end

local BaseFilteredHistoryR6=OTLGM.GetFilteredHistory
function OTLGM:GetFilteredHistory(filter,search)
    local list=BaseFilteredHistoryR6(self,filter,search)
    if filter=="ALL" or filter==nil then
        local bad=BuildAnomalyBucketsR6(self,30)
        local result={}
        local index,item
        for index=1,table.getn(list) do item=list[index] if not IsAnomalousEventR6(item,bad) then table.insert(result,item) end end
        return result
    end
    return list
end

local BaseRefreshOverviewR6=OTLGM.RefreshOverviewPage
function OTLGM:RefreshOverviewPage()
    local result=BaseRefreshOverviewR6(self)
    if not self.ui or not self.ui.overviewCards then return result end
    local stats=self:GetStats(7)
    local card=self.ui.overviewCards.joined
    if card then
        if card.label then card.label:SetText(stats.anomalyBatchesR6>0 and "ROSTER CHANGES" or "JOINED / LEFT") end
        if stats.anomalyBatchesR6>0 then
            if card.value then card.value:SetText(self.colors.gold.."REVIEW"..self.colors.reset) end
            if card.sub then card.sub:SetText("Anomalous scan batch excluded") end
        end
    end
    if stats.anomalyBatchesR6>0 and self.ui.overviewFreshness then
        self.ui.overviewFreshness:SetText(self.colors.gold.."Anomalous roster batch ignored  |  verified net "..(stats.net>=0 and "+" or "")..tostring(stats.net)..self.colors.reset)
    end
    local db=self:GetGuildDB()
    local bad=BuildAnomalyBucketsR6(self,7)
    local shown=0
    local index,eventInfo
    for index=1,table.getn(db and db.log or {}) do
        eventInfo=db.log[index]
        if eventInfo.kind~="BASELINE" and not eventInfo.hiddenLegacyLevel and not IsAnomalousEventR6(eventInfo,bad) then
            shown=shown+1
            if shown<=7 and self.ui.overviewEvents[shown] then
                local color=self.colors.white
                if eventInfo.kind=="JOIN" then color=self.colors.green elseif eventInfo.kind=="LEAVE" then color=self.colors.red elseif eventInfo.kind=="RANK" then color=self.colors.gold elseif eventInfo.kind=="LEVEL" then color=self.colors.blue elseif eventInfo.kind=="RETURN" then color=self.colors.green end
                self.ui.overviewEvents[shown]:SetText(self.colors.grey..date("%d/%m %H:%M",eventInfo.ts)..self.colors.reset.."  "..color..tostring(eventInfo.kind or "")..self.colors.reset.."  "..tostring(eventInfo.name or "").."  "..tostring(eventInfo.detail or ""))
            end
        end
        if shown>=7 then break end
    end
    local fill
    for fill=shown+1,7 do if self.ui.overviewEvents[fill] then self.ui.overviewEvents[fill]:SetText(self.colors.darkGrey.."No recorded event"..self.colors.reset) end end
    return result
end

-- ---------------------------------------------------------------------------
-- Money, bags, mail, level, trade, loot and chat trackers.
-- ---------------------------------------------------------------------------

local CAPITALS_R6={stormwind=true,stormwindcity=true,ironforge=true,darnassus=true,orgrimmar=true,undercity=true,thunderbluff=true,silvermooncity=true,exodar=true,theexodar=true}
local CORE_CLOTH_R6={ [2589]=20,[2592]=20,[4306]=20,[4338]=20,[14047]=20 }
local WORLD_BOSSES_R6={azuregos=true,["lordkazzak"]=true,emeriss=true,lethon=true,taerar=true,ysondre=true,ostarius=true}

local function CurrentZoneKeyR6()
    local zone=GetRealZoneText and GetRealZoneText() or GetZoneText and GetZoneText() or ""
    return KeyR6(zone)
end

local function CheckMoneyR6(self,silent)
    local money=GetMoney and tonumber(GetMoney()) or 0
    self:SetAchievementCounter174("moneyCopperR6",money)
    if money>=100*COPPER_PER_GOLD_R6 then self:CompleteAchievement174("D014",silent) end
    if money==0 and CAPITALS_R6[CurrentZoneKeyR6()] then self:CompleteAchievement174("D019",silent) end
end

local function ItemIdFromLinkR6(link)
    local _,_,id=string.find(tostring(link or ""),"item:(%d+)")
    return tonumber(id)
end

local function ScanBagsR6(self,silent)
    local clothCounts={}
    local foodSet={}
    local potionSet={}
    local bag,slot,slots,link,id,count,name,quality,level,req,itemType,itemSubType,maxStack
    for bag=0,4 do
        slots=GetContainerNumSlots and tonumber(GetContainerNumSlots(bag)) or 0
        for slot=1,slots do
            link=GetContainerItemLink and GetContainerItemLink(bag,slot) or nil
            if link then
                id=ItemIdFromLinkR6(link)
                local texture,itemCount=GetContainerItemInfo and GetContainerItemInfo(bag,slot)
                count=tonumber(itemCount) or 1
                if id and CORE_CLOTH_R6[id] then clothCounts[id]=(clothCounts[id] or 0)+count end
                name,link,quality,level,req,itemType,itemSubType,maxStack=GetItemInfo(link)
                local typeKey=string.lower(tostring(itemType or ""))
                local subKey=string.lower(tostring(itemSubType or ""))
                local nameKey=string.lower(tostring(name or ""))
                if id and (string.find(subKey,"food",1,true) or (string.find(typeKey,"consumable",1,true) and (string.find(nameKey,"bread",1,true) or string.find(nameKey,"meat",1,true) or string.find(nameKey,"fish",1,true) or string.find(nameKey,"cheese",1,true) or string.find(nameKey,"fruit",1,true)))) then foodSet[id]=true end
                if id and (string.find(subKey,"potion",1,true) or string.find(subKey,"elixir",1,true) or string.find(subKey,"flask",1,true) or string.find(nameKey,"potion",1,true) or string.find(nameKey,"elixir",1,true) or string.find(nameKey,"flask",1,true)) then potionSet[id]=true end
            end
        end
    end
    local clothReady=0
    for id,count in pairs(clothCounts) do if count>=(CORE_CLOTH_R6[id] or 20) then clothReady=clothReady+1 end end
    self:SetAchievementCounter174("coreClothStacksR6",clothReady)
    self:SetAchievementCounter174("uniqueFoodR6",CountR6(foodSet))
    self:SetAchievementCounter174("uniquePotionsR6",CountR6(potionSet))
    if clothReady>=5 then self:CompleteAchievement174("D015",silent) end
    if CountR6(foodSet)>=20 then self:CompleteAchievement174("D016",silent) end
    if CountR6(potionSet)>=10 then self:CompleteAchievement174("D017",silent) end
end

local function OwnedItemIdR6(itemId)
    if not itemId then return false end
    local slot,bag,index,link
    for slot=1,19 do link=GetInventoryItemLink and GetInventoryItemLink("player",slot) or nil if ItemIdFromLinkR6(link)==itemId then return true end end
    for bag=0,4 do
        local slots=GetContainerNumSlots and tonumber(GetContainerNumSlots(bag)) or 0
        for index=1,slots do link=GetContainerItemLink and GetContainerItemLink(bag,index) or nil if ItemIdFromLinkR6(link)==itemId then return true end end
    end
    return false
end

local function CheckLivingLegendR6(self,message,sender)
    if not IsPlayerR6(sender) then return end
    local position=1
    while true do
        local startPos,endPos,idText=string.find(tostring(message or ""),"item:(%d+)",position)
        if not startPos then break end
        local itemId=tonumber(idText)
        local link="item:"..tostring(itemId or "")
        local name,fullLink,quality=GetItemInfo(link)
        if tonumber(quality)==5 and OwnedItemIdR6(itemId) then self:CompleteAchievement174("D018",false) return end
        position=endPos+1
    end
end

local function CheckLevelUpR6(self,newLevel)
    newLevel=tonumber(newLevel) or UnitLevel and tonumber(UnitLevel("player")) or 0
    local group=self:GetGroupSnapshot174()
    local db=self:EnsureAchievements174()
    if group and tonumber(group.guild)>=2 then
        local map=db.partnerLevelsR6
        if type(map)~="table" then map={} db.partnerLevelsR6=map end
        local index,member,best
        for index=1,table.getn(group.guildMembers or {}) do
            member=group.guildMembers[index]
            if not IsPlayerR6(member.name) then
                local key=KeyR6(member.name)
                map[key]=math.min(100,tonumber(map[key]) or 0)+1
                if map[key]>(tonumber(db.counters.partnerLevelBestR6) or 0) then db.counters.partnerLevelBestR6=map[key] end
            end
        end
        if (tonumber(db.counters.partnerLevelBestR6) or 0)>=10 then self:CompleteAchievement174("D002",false) end
        if newLevel>=MAX_LEVEL_R6 then self:CompleteAchievement174("D013",false) end
        if newLevel>=MAX_LEVEL_R6 and self.QueueNetworkPayload then
            local signature=""
            local names={}
            for index=1,table.getn(group.guildMembers or {}) do table.insert(names,KeyR6(group.guildMembers[index].name)) end
            table.sort(names) signature=table.concat(names,",")
            for index=1,table.getn(group.guildMembers or {}) do
                member=group.guildMembers[index]
                if not IsPlayerR6(member.name) then
                    local payload=table.concat({"F1","LEVEL",ShortNameR6(UnitName("player") or ""),tostring(newLevel),signature,tostring(self:Now())},"^")
                    self:QueueNetworkPayload(payload,"WHISPER",member.name,1,"release175","F1LEVEL:"..KeyR6(member.name))
                end
            end
        end
    end
end

local BaseReleaseMessageR6=OTLGM.HandleRelease175Message
function OTLGM:HandleRelease175Message(message,channel,sender)
    local fields=self:Split(message or "","^")
    if fields[1]=="F1" and fields[2]=="LEVEL" then
        local level=tonumber(fields[4]) or 0
        local ts=tonumber(fields[6]) or 0
        if level>=MAX_LEVEL_R6 and math.abs(self:Now()-ts)<=180 and IsGuildMemberR6(self,sender) then
            local group=self:GetGroupSnapshot174()
            if not group then return BaseReleaseMessageR6 and BaseReleaseMessageR6(self,message,channel,sender) or false end
            local found=false
            local index,member
            for index=1,table.getn(group.guildMembers or {}) do
                member=group.guildMembers[index]
                if KeyR6(member and member.name or "")==KeyR6(sender) then found=true break end
            end
            if found then self:SetAchievementCounter174("witnessMaxLevelR6",1) self:CompleteAchievement174("D001",false) return true end
        end
    end
    return BaseReleaseMessageR6 and BaseReleaseMessageR6(self,message,channel,sender) or false
end

local BaseBeginTradeR6=OTLGM.BeginTradeTracking174
function OTLGM:BeginTradeTracking174()
    BaseBeginTradeR6(self)
    if self.runtime and self.runtime.trade174 then self.runtime.trade174.r6=true end
end

local BaseUpdateTradeR6=OTLGM.UpdateTradeTracking174
function OTLGM:UpdateTradeTracking174()
    BaseUpdateTradeR6(self)
    local trade=self.runtime and self.runtime.trade174
    if not trade then return end
    trade.playerMoney=GetPlayerTradeMoney and tonumber(GetPlayerTradeMoney()) or 0
    trade.targetMoney=GetTargetTradeMoney and tonumber(GetTargetTradeMoney()) or 0
    trade.playerItems=0 trade.targetItems=0
    local index
    for index=1,6 do
        if GetTradePlayerItemLink and GetTradePlayerItemLink(index) then trade.playerItems=trade.playerItems+1 end
        if GetTradeTargetItemLink and GetTradeTargetItemLink(index) then trade.targetItems=trade.targetItems+1 end
    end
end

local BaseFinishTradeR6=OTLGM.FinishTradeTracking174
function OTLGM:FinishTradeTracking174(success)
    local trade=self.runtime and self.runtime.trade174
    if trade then self:UpdateTradeTracking174() end
    trade=self.runtime and self.runtime.trade174
    local snapshot=nil
    if trade then
        snapshot={target=trade.target,playerMoney=tonumber(trade.playerMoney) or 0,targetMoney=tonumber(trade.targetMoney) or 0,playerItems=tonumber(trade.playerItems) or 0,targetItems=tonumber(trade.targetItems) or 0}
    end
    BaseFinishTradeR6(self,success)
    if not success or not snapshot or not IsGuildMemberR6(self,snapshot.target) then return end
    if snapshot.playerMoney>=COPPER_PER_GOLD_R6 and snapshot.targetMoney==0 and snapshot.targetItems==0 then self:SetAchievementCounter174("generousTipR6",1) self:CompleteAchievement174("D007",false) end
    if snapshot.playerMoney==1 and snapshot.targetMoney==0 and snapshot.targetItems==0 and snapshot.playerItems==0 and KeyR6(snapshot.target)==KeyR6(GetGuildLeaderNameR6(self)) then self:SetAchievementCounter174("exactChangeR6",1) self:CompleteAchievement174("D020",false) end
end

local BaseCheckResurrectionR6=OTLGM.CheckResurrection175
function OTLGM:CheckResurrection175()
    local target=self.runtime and self.runtime.resurrection175 and self.runtime.resurrection175.target or ""
    local result=BaseCheckResurrectionR6(self)
    if result and target~="" and KeyR6(target)==KeyR6(GetGuildLeaderNameR6(self)) then self:SetAchievementCounter174("riseCommanderR6",1) self:CompleteAchievement174("D011",false) end
    return result
end

local function CaptureMailR6(self,recipient)
    local hasItem=false
    local index
    if GetSendMailItem then
        for index=1,12 do local name=GetSendMailItem(index) if name then hasItem=true break end end
    end
    if not hasItem and SendMailItemButton and SendMailItemButton.icon and SendMailItemButton.icon.GetTexture and SendMailItemButton.icon:GetTexture() then hasItem=true end
    self.runtime=self.runtime or {}
    self.runtime.pendingMailR6={recipient=ShortNameR6(recipient),hasItem=hasItem,ts=self:Now()}
end

local function InstallMailHookR6(self)
    if self.mailHookR6 or type(SendMail)~="function" then return end
    self.mailHookR6=true
    local base=SendMail
    SendMail=function(recipient,subject,body)
        if OTLGM then CaptureMailR6(OTLGM,recipient) end
        return base(recipient,subject,body)
    end
end

local function ScanInboxR6(self)
    if not GetInboxNumItems or not GetInboxHeaderInfo then return end
    local count=tonumber(GetInboxNumItems()) or 0
    local index,sender
    for index=1,count do
        local packageIcon,stationeryIcon,headerSender=GetInboxHeaderInfo(index)
        sender=ShortNameR6(headerSender)
        if sender~="" and IsGuildMemberR6(self,sender) then AddSetR6(self,"mailGuildSendersR6",sender) end
    end
    if CountR6(self:GetAchievementSet174("mailGuildSendersR6"))>=10 then self:CompleteAchievement174("D009",false) end
end

local function CompleteMailSendR6(self)
    local state=self.runtime and self.runtime.pendingMailR6
    if not state or self:Now()-(state.ts or 0)>30 then return end
    self.runtime.pendingMailR6=nil
    if state.hasItem and IsGuildMemberR6(self,state.recipient) then self:SetAchievementCounter174("mailCallR6",1) self:CompleteAchievement174("D008",false) end
end

-- Loot tracker is deliberately conservative. It only awards when the client has
-- both an active standard loot roll and a matching winner/result message.
local function EnsureLootRollR6(self,rollId)
    self.runtime=self.runtime or {} self.runtime.lootRollsR6=self.runtime.lootRollsR6 or {}
    local key=tostring(rollId or "recent")
    local state=self.runtime.lootRollsR6[key]
    if not state then state={id=rollId,ts=self:Now(),passes={},rolls={}} self.runtime.lootRollsR6[key]=state end
    if GetLootRollItemInfo and rollId then
        local texture,name,count,quality=GetLootRollItemInfo(rollId)
        state.name=name or state.name state.quality=tonumber(quality) or state.quality state.texture=texture or state.texture
    end
    return state
end

local function InstallLootHookR6(self)
    if self.lootHookR6 or type(RollOnLoot)~="function" then return end
    self.lootHookR6=true
    local base=RollOnLoot
    RollOnLoot=function(rollId,choice)
        if OTLGM then
            local state=EnsureLootRollR6(OTLGM,rollId)
            state.localChoice=tonumber(choice)
            local groupR6,fullR6=FullGuildPartyR6(OTLGM)
            state.fullGuild=fullR6
            if tonumber(choice)==0 then
                state.passes[KeyR6(UnitName("player") or "")]=true
                if state.fullGuild and tonumber(state.quality)==4 then OTLGM:SetAchievementCounter174("epicPassR6",1) OTLGM:CompleteAchievement174("D005",false) end
            end
        end
        return base(rollId,choice)
    end
end

local function RecentLootStateR6(self)
    local newest=nil
    local key,state
    for key,state in pairs(self.runtime and self.runtime.lootRollsR6 or {}) do if not newest or (state.ts or 0)>(newest.ts or 0) then newest=state end end
    return newest
end

local function ParseRollSystemR6(self,message)
    local text=tostring(message or "")
    local lower=string.lower(text)
    local _,_,name,value,minv,maxv=string.find(text,"^(.+) rolls (%d+) %((%d+)%-(%d+)%)")
    if name and tonumber(value)==100 and tonumber(minv)==1 and tonumber(maxv)==100 and IsPlayerR6(name) then
        local group,full=FullGuildPartyR6(self)
        if full then self:SetAchievementCounter174("rollOfFateR6",1) self:CompleteAchievement174("D010",false) end
    end
    local _,_,rolledName,rolledValue=string.find(text,"^(.+) rolls (%d+)")
    local state=RecentLootStateR6(self)
    if state and rolledName and rolledValue and (string.find(lower,"need",1,true) or string.find(lower,"greed",1,true)) then
        state.rolls[KeyR6(rolledName)]={value=tonumber(rolledValue) or 0,choice=string.find(lower,"need",1,true) and "NEED" or "GREED"}
    end
    if state and string.find(lower,"pass",1,true) then
        local _,_,passName=string.find(text,"^([^%s]+)")
        if passName and IsGuildMemberR6(self,passName) then state.passes[KeyR6(passName)]=true end
        if state.fullGuild and CountR6(state.passes)>=5 then self:SetAchievementCounter174("everybodyPassesR6",1) self:CompleteAchievement174("D006",false) end
    end
    if state and string.find(lower,"won",1,true) then
        local _,_,winner=string.find(text,"^([^%s]+)")
        if string.find(lower,"you won",1,true) then winner=UnitName("player") end
        local localRoll=state.rolls[KeyR6(UnitName("player") or "")]
        local winnerRoll=winner and state.rolls[KeyR6(winner)] or nil
        if winner and IsPlayerR6(winner) and localRoll and localRoll.value==100 then self:SetAchievementCounter174("perfectRollR6",1) self:CompleteAchievement174("D003",false) end
        if winner and not IsPlayerR6(winner) and IsGuildMemberR6(self,winner) and localRoll and winnerRoll and localRoll.value==99 and winnerRoll.value==100 and localRoll.choice==winnerRoll.choice then self:SetAchievementCounter174("soCloseR6",1) self:CompleteAchievement174("D004",false) end
    end
end

local function DeathNameR6(message)
    local _,_,name=string.find(tostring(message or ""),"^(.+) dies%.$")
    if not name then _,_,name=string.find(tostring(message or ""),"^(.+) is slain") end
    return ShortNameR6(name)
end

local function CheckWorldBossR6(self,message)
    local name=DeathNameR6(message)
    if name=="" or not WORLD_BOSSES_R6[KeyR6(name)] then return end
    local group=self:GetGroupSnapshot174()
    if group and group.isRaid and tonumber(group.guild)>=10 then self:SetAchievementCounter174("worldBossR6",1) self:CompleteAchievement174("D012",false) end
end

local function CheckFallTextR6(self,message)
    local lower=string.lower(tostring(message or ""))
    if string.find(lower,"fall",1,true) or string.find(lower,"паден",1,true) or string.find(lower,"sturz",1,true) or string.find(lower,"chute",1,true) then
        self.runtime=self.runtime or {} self.runtime.pendingFallR6=self:Now()
    end
end

-- ---------------------------------------------------------------------------
-- Final UI corrections.
-- ---------------------------------------------------------------------------

local BaseBuildActivityR6=OTLGM.BuildActivityPage
function OTLGM:BuildActivityPage(page)
    BaseBuildActivityR6(self,page)
    local heat=self.ui.heatmapCells and self.ui.heatmapCells[0] and self.ui.heatmapCells[0][0] and self.ui.heatmapCells[0][0]:GetParent() or nil
    local composition=self.ui.compositionTotal and self.ui.compositionTotal:GetParent() or nil
    if heat then MoveR6(heat,page,0,-142,470,340) end
    if composition then MoveR6(composition,page,480,-142,238,340) end
    -- The heatmap note ends around -472. Keep a dedicated gap before the
    -- two-line insight strip, then a separate action row below it.
    if self.ui.activityInsightPanelR4 then MoveR6(self.ui.activityInsightPanelR4,page,0,-486,718,42) end
    if self.ui.activityInsightText170 then
        MoveR6(self.ui.activityInsightText170,self.ui.activityInsightPanelR4 or page,9,-5,700,32)
        if self.ui.activityInsightText170.SetJustifyV then self.ui.activityInsightText170:SetJustifyV("TOP") end
    end
    if self.ui.activitySync156 then MoveR6(self.ui.activitySync156,page,340,-534,178,27) end
    if self.ui.activitySummaryButton then MoveR6(self.ui.activitySummaryButton,page,528,-534,190,27) end
end

local BaseRefreshActivityR6=OTLGM.RefreshActivityPage
function OTLGM:RefreshActivityPage()
    local result=BaseRefreshActivityR6(self)
    if self.ui and self.ui.activityInsightText170 then
        local text=tostring(self.ui.activityInsightText170:GetText() or "")
        text=string.gsub(text,"%s+|%s+Coverage:","\nCoverage:")
        self.ui.activityInsightText170:SetText(text)
    end
    return result
end

local BaseRefreshNavigationR6=OTLGM.RefreshNavigation
function OTLGM:RefreshNavigation()
    local result=BaseRefreshNavigationR6(self)
    -- Pages.lua owns the final order; this wrapper only preserves selected state.
    return result
end

-- ---------------------------------------------------------------------------
-- Event bridge and debounced work.
-- ---------------------------------------------------------------------------

local BaseTimersR6=OTLGM.ProcessQuality156Timers
function OTLGM:ProcessQuality156Timers()
    if BaseTimersR6 then BaseTimersR6(self) end
    local now=self:Now()
    if self.runtime and self.runtime.bagScanDueR6 and now>=self.runtime.bagScanDueR6 then self.runtime.bagScanDueR6=nil ScanBagsR6(self,false) end
    if self.runtime and self.runtime.pendingFallR6 and now-self.runtime.pendingFallR6>5 then self.runtime.pendingFallR6=nil end
    local key,state
    for key,state in pairs(self.runtime and self.runtime.lootRollsR6 or {}) do if now-(state.ts or now)>180 then self.runtime.lootRollsR6[key]=nil end end
end

local frameR6=CreateFrame("Frame","OTLGM_ReleaseEvent175R6")
local eventsR6={"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","PLAYER_MONEY","ZONE_CHANGED_NEW_AREA","BAG_UPDATE","MAIL_SHOW","MAIL_INBOX_UPDATE","MAIL_SEND_SUCCESS","START_LOOT_ROLL","CANCEL_LOOT_ROLL","CHAT_MSG_SYSTEM","CHAT_MSG_GUILD","CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_SPELL_SELF_DAMAGE","PLAYER_DEAD","CHAT_MSG_COMBAT_HOSTILE_DEATH","GUILD_ROSTER_UPDATE"}
for i=1,table.getn(eventsR6) do pcall(frameR6.RegisterEvent,frameR6,eventsR6[i]) end
frameR6:SetScript("OnEvent",function()
    if not OTLGM then return end
    OTLGM.runtime=OTLGM.runtime or {}
    if event=="PLAYER_LOGIN" then
        InstallMailHookR6(OTLGM) InstallLootHookR6(OTLGM)
        local db=OTLGM:EnsureAchievements174()
        local silent=not db.releaseBaselineR6
        CheckMoneyR6(OTLGM,silent)
        ScanBagsR6(OTLGM,silent)
        db.releaseBaselineR6=true
    elseif event=="PLAYER_ENTERING_WORLD" then CheckMoneyR6(OTLGM,false) OTLGM.runtime.bagScanDueR6=OTLGM:Now()+1
    elseif event=="PLAYER_LEVEL_UP" then CheckLevelUpR6(OTLGM,arg1)
    elseif event=="PLAYER_MONEY" or event=="ZONE_CHANGED_NEW_AREA" then CheckMoneyR6(OTLGM,false)
    elseif event=="BAG_UPDATE" then OTLGM.runtime.bagScanDueR6=OTLGM:Now()+1
    elseif event=="MAIL_SHOW" or event=="MAIL_INBOX_UPDATE" then InstallMailHookR6(OTLGM) ScanInboxR6(OTLGM)
    elseif event=="MAIL_SEND_SUCCESS" then CompleteMailSendR6(OTLGM)
    elseif event=="START_LOOT_ROLL" then EnsureLootRollR6(OTLGM,arg1)
    elseif event=="CANCEL_LOOT_ROLL" then if OTLGM.runtime.lootRollsR6 then OTLGM.runtime.lootRollsR6[tostring(arg1 or "recent")]=nil end
    elseif event=="CHAT_MSG_SYSTEM" then ParseRollSystemR6(OTLGM,arg1) CheckFallTextR6(OTLGM,arg1)
    elseif event=="CHAT_MSG_GUILD" then CheckLivingLegendR6(OTLGM,arg1,arg2)
    elseif event=="CHAT_MSG_COMBAT_SELF_HITS" or event=="CHAT_MSG_SPELL_SELF_DAMAGE" then CheckFallTextR6(OTLGM,arg1)
    elseif event=="PLAYER_DEAD" then
        if OTLGM.runtime.pendingFallR6 and OTLGM:Now()-OTLGM.runtime.pendingFallR6<=3 and HasGuildPartnerR6(OTLGM) then OTLGM:SetAchievementCounter174("gravityWinsR6",1) OTLGM:CompleteAchievement174("D021",false) end
        OTLGM.runtime.pendingFallR6=nil
    elseif event=="CHAT_MSG_COMBAT_HOSTILE_DEATH" then CheckWorldBossR6(OTLGM,arg1)
    elseif event=="GUILD_ROSTER_UPDATE" then OTLGM.runtime.guildLeaderR6=nil
    end
end)

if OTLGM.RegisterModule then OTLGM:RegisterModule("Release175R6",{layer="feature",corrective=true,revision=6,totalAchievements=142,eventDriven=true,noOnUpdate=true}) end
