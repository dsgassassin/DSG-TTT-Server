local function IsDonor(ply)
	return false
end

local function IconScale(size)
	return math.Clamp(ScreenScale(size), 0, 32), math.Clamp(ScreenScale(size), 0, 32)
end

include("fonts.lua")
include("vgui/frame.lua")
include("vgui/frame_canvas.lua")
include("vgui/menu_pages.lua")
include("vgui/taunt_entry.lua")

function createframetest()
	local frame = vgui.Create("TauntsFrame")
	frame:SetSize(ScrW() * .65, ScrH() * .8)
	frame:MakePopup()
	for i = 0, 10, 1 do
		frame:GetShopContainer():AddEntry("taunts/taunt_boom.wav", 1.7, "BOOM HEADSHOT!", (i % 3 == 0) and true or false, (i % 4 == 0) and true or false)
	end
	frame:GetInventoryContainer():AddEntry("taunts/taunt_boom.wav", 1.7, "BOOM HEADSHOT!")
	frame:GetInventoryContainer():AddEntry("taunts/taunt_boom.wav", 1.7, "BOOM HEADSHOT!")
	frame:GetInventoryContainer():AddEntry("taunts/taunt_boom.wav", 1.7, "BOOM HEADSHOT!")
end

