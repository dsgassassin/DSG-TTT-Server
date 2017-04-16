--Pointshop Trading Fonts
local function LoadFonts()
if TRADING.FontsLoaded then return end
surface.CreateFont("Bebas20Font", {font = "Bebas Neue", size= 20, weight = 400, antialias = true } )  
surface.CreateFont("Bebas40Font", {font = "Bebas Neue", size= 40, weight = 400, antialias = true } ) 
surface.CreateFont("Bebas24Scaled", {font = "Bebas Neue", size= ScreenScale(9), weight = 400, antialias = true } ) 
 
surface.CreateFont("OpenSans24Font", {font = "Open Sans Condensed", size= 24, weight = 400, antialias = true } ) 
surface.CreateFont("OpenSans30Font", {font = "Open Sans Condensed", size= 30, weight = 400, antialias = true } ) 
TRADING.FontsLoaded = true
end
LoadFonts()
hook.Add("InitPostEntity", "PointshopTradingFonts", LoadFonts)