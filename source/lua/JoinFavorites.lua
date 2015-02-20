Shared.Message("JoinFavorites")

-- required for the Modding Framework (http://wiki.unknownworlds.com/ns2/Modding_Framework)
Script.Load("lua/Class.lua")

-- required for Elixer - Cross-Mod Compatible Utility Library - https://github.com/sclark39/NS2Elixer
Script.Load( "lua/JoinFavorites/Elixer_Utility.lua" )
Elixer.UseVersion( 1.8 )

--[[
local function onLoadComplete()
    Shared.Message("JoinFavorites.onLoadComplete")
    
    LoadCSSFile("lua/JoinFavorites.css")
    
    originalMenuCreateOptions = Class_ReplaceMethod( "GUIMainMenu_PlayNow", "ShowServerWindow",
        function(self)
            Shared.Message("JoinFavorites.GUIMainMenu_PlayNow.ShowServerWindow")
            
            -- allow original call
            originalMenuCreateOptions(self)
            
            -- customization
            self.playWindow.joinFavoritesButton:SetIsVisible(true)
        end
    )    
    
    originalCreateServerListWindow = Class_ReplaceMethod( "GUIMainMenu", "CreateServerListWindow",
        function(self)
            Shared.Message("JoinFavorites.GUIMainMenu.CreateServerListWindow")
            
            -- allow original call
            originalCreateServerListWindow(self)
            
            -- customization
            self.playWindow.joinFavoritesButton = CreateMenuElement(self.playWindow, "MenuButton")
            self.playWindow.joinFavoritesButton:SetCSSClass("joinfavorites")
            self.playWindow.joinFavoritesButton:SetText(Locale.ResolveString("JOIN FAVOURITES"))
            self.playWindow.joinFavoritesButton:AddEventCallbacks( {OnClick = function(self) 
                Shared.Message('joinFavoritesButton pressed') 
            end } )
        end
    )
end

Shared.Message("JoinFavorites hooks")
Event.Hook("LoadComplete", onLoadComplete)
]]--