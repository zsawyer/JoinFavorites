Shared.Message("JoinFavorites.GUIMainMenu_PlayNow")

-- required for the Modding Framework (http://wiki.unknownworlds.com/ns2/Modding_Framework)
Script.Load("lua/Class.lua")

-- required for Elixer - Cross-Mod Compatible Utility Library - https://github.com/sclark39/NS2Elixer
Script.Load( "lua/JoinFavorites/Elixer_Utility.lua" )
Elixer.UseVersion( 1.8 )

-- loading custom script 
Script.Load("lua/JoinFavorites/menu/JF_GUIMainMenu_PlayNow.lua")



-- loading modified original <<START>>



// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\GUIMainMenu_PlayNow.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


local function GetServerTagValue(serverIndex, tagName)

    if serverIndex >= 0 then
    
        local serverTags = { }
        Client.GetServerTags(serverIndex, serverTags)
        for t = 1, #serverTags do
        
            local tag = serverTags[t]
            local startIndex, endIndex = string.find(tag, tagName)
            if endIndex then
            
                local numValue = string.sub(tag, endIndex + 1)
                return tonumber(numValue)
                
            end
            
        end
        
    end
    
    return nil
    
end

function GetNumServerReservedSlots(serverIndex)
    return GetServerTagValue(serverIndex, "R_S") or 0
end

function GetServerPlayerSkill(serverIndex)
    return GetServerTagValue(serverIndex, "P_S") or kDefaultPlayerSkill
end

function GetServerTickRate(serverIndex)
    return Client.GetServerTickRate(serverIndex)
end


local function UpdateAutoJoin(playNowWindow)

    playNowWindow.lastTimeRefreshedServers = playNowWindow.lastTimeRefreshedServers or 0
    local timeSinceRefreshed = Shared.GetTime() - playNowWindow.lastTimeRefreshedServers
    local timeToCheckForServerUpdate = timeSinceRefreshed > 5
    local forceRefreshTime = timeSinceRefreshed > 60
    if timeToCheckForServerUpdate and Client.GetNumServers() == 0 or forceRefreshTime then
    
        playNowWindow.lastTimeRefreshedServers = Shared.GetTime()
        Client.RebuildServerList()
        
    end
    
    local rookieMode = Client.GetOptionBoolean(kRookieOptionsKey, true)
    local playerSkill = Client.GetOptionInteger("player-ranking", 0)
    timeSinceRefreshed = Shared.GetTime() - playNowWindow.lastTimeRefreshedServers
    if timeSinceRefreshed > 6 and Client.GetNumServers() > 0 then
    
        local allValidServers = { }
        for s = 0, Client.GetNumServers() - 1 do
        
            if not Client.GetServerRequiresPassword(s) then
            
                local numPlayers = Client.GetServerNumPlayers(s)
                local maxPlayers = Client.GetServerMaxPlayers(s) 
                local realMaxPlayers = maxPlayers - GetNumServerReservedSlots(s)
                local percentFull = numPlayers / realMaxPlayers
                local name = Client.GetServerName(s)
                local address = Client.GetServerAddress(s)
                local mapname = Client.GetServerMapName(s)
                local ping = Client.GetServerPing(s)
                local rookieFriendly = Client.GetServerHasTag(s, "rookieFriendly")
                local isLANServer = Client.GetServerIsLAN(s)
                local tickrate = GetServerTickRate(s)
                local currentScore = Client.GetServerCurrentPerformanceScore(s)
                local performanceScore = Client.GetServerPerformanceScore(s)
                local performanceQuality = Client.GetServerPerformanceQuality(s)
                local skill = GetServerPlayerSkill(s)
                local mode = Client.GetServerGameMode(s)
                local favorite = GetServerIsFavorite(address)
                
                if percentFull < 1 and ( not rookieMode or rookieFriendly ) and mode == "ns2" and maxPlayers < 25 and maxPlayers > 11 then
                    table.insert(allValidServers,
                      { numPlayers = numPlayers,
                        maxPlayers = realMaxPlayers,
                        percentFull = percentFull,
                        {name = name, rookieFriendly = rookieFriendly},
                        address = address,
                        mapname = mapname,
                        ping = ping,
                        rookieFriendly = rookieFriendly,
                        isLANServer = isLANServer,
                        tickrate = tickrate,
                        currentScore = currentScore,
                        performanceScore = performanceScore,
                        performanceQuality = performanceQuality,
                        skill = skill,
                        favorite = favorite })
                end
                
            end
            
        end
        
        local function closerTo(compareTo, num1, num2)
            local range1 = math.abs(num1 - compareTo)
            local range2 = math.abs(num2 - compareTo)
            
            if range1 >= range2 then
                return num1
            else
                return num2
            end
        end
        
        local bestServer = nil
        for vs = 1, #allValidServers do
        
            local possibleServer = allValidServers[vs]
            
            -- Favor servers with low ping. But ignore ping when it is small enough.
            -- Ignore LAN servers for this process.
            if not possibleServer.isLANServer and (not bestServer or (possibleServer.ping < bestServer.ping or possibleServer.ping <= 80)) then
            
                bestServer = bestServer or possibleServer
                -- Favor servers that are at least half full and have a tickrate above 29.
                if possibleServer.percentFull >= 0.5 and possibleServer.tickrate > 29 then
                    
                    if bestServer.favorite then
                        possibleServer.favorite = false
                    end
                    
                    -- Favor servers that are most populated or favoured and are closer to the players skill level.
                    if ( possibleServer.percentFull > bestServer.percentFull or possibleServer.favorite ) and closerTo(playerSkill, possibleServer.skill, bestServer.skill) == possibleServer.skill then
                        bestServer = possibleServer
                    end
                    
                -- Favor servers that are more populated than our current best choice if
                -- both are below 50% populated. Still make sure the performance is not drastically worse.
                elseif bestServer.percentFull < 0.5 and possibleServer.percentFull > bestServer.percentFull and possibleServer.tickrate > bestServer.tickrate * 0.95 then
                    bestServer = possibleServer
                end
                
            end
            
        end
        
        if bestServer then
            MainMenu_SBJoinServer(bestServer.address, nil, bestServer.mapname)
        end
        
    end
    
end

local function UpdatePlayNowWindowLogic(playNowWindow, mainMenu)

    PROFILE("GUIMainMenu:UpdatePlayNowWindowLogic")

    if playNowWindow:GetIsVisible() then
    
        playNowWindow.searchingForGameText.animateTime = playNowWindow.searchingForGameText.animateTime or Shared.GetTime()
        if Shared.GetTime() - playNowWindow.searchingForGameText.animateTime > 0.85 then
        
            playNowWindow.searchingForGameText.animateTime = Shared.GetTime()
            playNowWindow.searchingForGameText.numberOfDots = playNowWindow.searchingForGameText.numberOfDots or 3
            playNowWindow.searchingForGameText.numberOfDots = playNowWindow.searchingForGameText.numberOfDots + 1
            if playNowWindow.searchingForGameText.numberOfDots > 3 then
                playNowWindow.searchingForGameText.numberOfDots = 0
            end
            
            playNowWindow.searchingForGameText:SetText(string.format( "%s%s", Locale.ResolveString("SEARCHING"), string.rep(".", playNowWindow.searchingForGameText.numberOfDots)))
            
        end
        
        UpdateAutoJoin(playNowWindow)
        
    end
    
end

local function CreatePlayNowPage(self)

    self.playNowWindow = self:CreateWindow()
    self.playNowWindow:SetWindowName("PLAY NOW")
    self.playNowWindow:SetInitialVisible(false)
    self.playNowWindow:SetIsVisible(false)
    self.playNowWindow:DisableResizeTile()
    self.playNowWindow:DisableSlideBar()
    self.playNowWindow:DisableContentBox()
    self.playNowWindow:SetCSSClass("playnow_window")
    self.playNowWindow:DisableCloseButton()
    
    self.playNowWindow.UpdateLogic = UpdatePlayNowWindowLogic

    local eventCallbacks =
    {
        OnShow = function(self)

            MainMenu_OnWindowOpen()

        end
    }
    self.playNowWindow:AddEventCallbacks(eventCallbacks)

    self.playNowWindow.searchingForGameText = CreateMenuElement(self.playNowWindow.titleBar, "Font", false)
    self.playNowWindow.searchingForGameText:SetCSSClass("playnow_title")
    self.playNowWindow.searchingForGameText:SetText(Locale.ResolveString("SERVERBROWSER_SEARCHING"))
    
    local cancelButton = CreateMenuElement(self.playNowWindow, "MenuButton")
    cancelButton:SetCSSClass("playnow_cancel")
    cancelButton:SetText(Locale.ResolveString("AUTOJOIN_CANCEL"))
    
    cancelButton:AddEventCallbacks({ OnClick =
    function() self.playNowWindow:SetIsVisible(false) end })
    
end

local function CreateJoinServerPage(self)

    self:CreateServerListWindow()
    self:CreateServerDetailsWindow()
    
end

local function CreateHostGamePage(self)

    self.createGame = CreateMenuElement(self.playWindow:GetContentBox(), "Image")
    self.createGame:SetCSSClass("play_now_content")
    self:CreateHostGameWindow()
    
end

local function ShowServerWindow(self)

    JF_ShowServerWindow_Pre(self)

    self.playWindow.updateButton:SetIsVisible(true)
    self.playWindow.detailsButton:SetIsVisible(true)
    self.joinServerButton:SetIsVisible(true)
    self.highlightServer:SetIsVisible(true)
    self.selectServer:SetIsVisible(true)
    self.serverRowNames:SetIsVisible(true)
    self.serverTabs:SetIsVisible(true)
    self.serverList:SetIsVisible(true)
    self.filterForm:SetIsVisible(true)
    
    // Re-enable slide bar.
    self.playWindow:SetSlideBarVisible(true)
    self.playWindow:ResetSlideBar()
    
end

local function HideServerWindow(self)

    self.playWindow.updateButton:SetIsVisible(false)
    self.playWindow.detailsButton:SetIsVisible(false)
    self.joinServerButton:SetIsVisible(false)
    self.highlightServer:SetIsVisible(false)
    self.selectServer:SetIsVisible(false)
    self.serverRowNames:SetIsVisible(false)
    self.serverTabs:SetIsVisible(false)
    self.serverList:SetIsVisible(false)
    self.filterForm:SetIsVisible(false)
    
    // Hide it, but make sure it's at the top position.
    self.playWindow:SetSlideBarVisible(false)
    self.playWindow:ResetSlideBar()
    
end

function GUIMainMenu:SetPlayContentInvisible(cssClass)

    HideServerWindow(self)
    self.createGame:SetIsVisible(false)
    self.playNowWindow:SetIsVisible(false)
    self.hostGameButton:SetIsVisible(false)
    
    if cssClass then
        self.playWindow:GetContentBox():SetCSSClass(cssClass)
    end
    
end

function GUIMainMenu:CreatePlayWindow()

    self.playWindow = self:CreateWindow()
    self:SetupWindow(self.playWindow, "SERVER BROWSER")
    self.playWindow:AddCSSClass("play_window")
    self.playWindow:ResetSlideBar()    // so it doesn't show up mis-drawn
    self.playWindow:GetContentBox():SetCSSClass("serverbrowse_content")
    
    local hideTickerCallbacks =
    {
        OnShow = function(self)
            self.scriptHandle.tweetText:SetIsVisible(false)
        end,
        
        OnHide = function(self)
            self.scriptHandle.tweetText:SetIsVisible(true)
        end
    }
    
    self.playWindow:AddEventCallbacks( hideTickerCallbacks )
    
    local back = CreateMenuElement(self.playWindow, "MenuButton")
    back:SetCSSClass("back")
    back:SetText(Locale.ResolveString("BACK"))
    back:AddEventCallbacks( { OnClick = function()
        self.playNowWindow:SetIsVisible(false)
        self.playWindow:SetIsVisible(false)
    end } )
    
    local tabs = 
        {
            { label = Locale.ResolveString("JOIN"), func = function(self) self.scriptHandle:SetPlayContentInvisible("serverbrowse_content") ShowServerWindow(self.scriptHandle) end },
            --{ label = Locale.ResolveString("QUICK_JOIN"), func = function(self) self.scriptHandle:SetPlayContentInvisible("play_content") self.scriptHandle.playNowWindow:SetIsVisible(true) end },
            { label = Locale.ResolveString("START_SERVER"), func = function(self) self.scriptHandle:SetPlayContentInvisible("play_content") self.scriptHandle.createGame:SetIsVisible(true) self.scriptHandle.hostGameButton:SetIsVisible(true) end }
        }
        
    local xTabWidth = 256

    local tabBackground = CreateMenuElement(self.playWindow, "Image")
    tabBackground:SetCSSClass("tab_background_playnow")
    tabBackground:SetIgnoreEvents(true)
    
    local tabAnimateTime = 0.1
        
    for i = 1,#tabs do
    
        local tab = tabs[i]
        local tabButton = CreateMenuElement(self.playWindow, "MenuButton")
        
        local function ShowTab()
            for j =1,#tabs do
                local tabPosition = tabButton.background:GetPosition()
                tabBackground:SetBackgroundPosition( tabPosition, false, tabAnimateTime ) 
            end
        end
    
        tabButton:SetCSSClass("tab_playnow")
        tabButton:SetText(tab.label)
        tabButton:AddEventCallbacks({ OnClick = tab.func })
        tabButton:AddEventCallbacks({ OnClick = ShowTab })
        
        local tabWidth = tabButton:GetWidth()
        tabButton:SetBackgroundPosition( Vector(tabWidth * (i - 1), 0, 0) )
        
    end
    
    CreateJoinServerPage(self)
    CreatePlayNowPage(self)
    CreateHostGamePage(self)
    
    self:SetPlayContentInvisible()
    ShowServerWindow(self)
    
end



-- loading original <<END>>