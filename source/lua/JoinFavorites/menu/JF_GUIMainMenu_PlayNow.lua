Shared.Message("JoinFavorites JF_GUIMainMenu_PlayNow")

-- required for the Modding Framework (http://wiki.unknownworlds.com/ns2/Modding_Framework)
Script.Load("lua/Class.lua")

-- required for Elixer - Cross-Mod Compatible Utility Library - https://github.com/sclark39/NS2Elixer
Script.Load( "lua/JoinFavorites/Elixer_Utility.lua" )
Elixer.UseVersion( 1.8 )

-- extend MainMenu_PlayNow functions
function JF_ShowServerWindow_Pre(self)
    Shared.Message("JoinFavorites.JF_GUIMainMenu_PlayNow.JF_ShowServerWindow_Pre")      
    
    -- customization
    self.playWindow.joinFavoritesButton:SetIsVisible(true)
end

