Shared.Message("JoinFavorites JF_GUIMainMenu_PlayNow")

-- required for the Modding Framework (http://wiki.unknownworlds.com/ns2/Modding_Framework)
Script.Load("lua/Class.lua")

-- required for Elixer - Cross-Mod Compatible Utility Library - https://github.com/sclark39/NS2Elixer
Script.Load( "lua/JoinFavorites/Elixer_Utility.lua" )
Elixer.UseVersion( 1.8 )
  
-- custom CSS
LoadCSSFile("lua/JoinFavorites.css")


    
-- extend MainMenu functions    
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
