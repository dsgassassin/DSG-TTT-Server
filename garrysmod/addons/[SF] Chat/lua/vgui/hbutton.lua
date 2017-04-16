surface.CreateFont( "ButtonFont", {
	font = "Tahoma",
	size = 14,
	weight = 400
} )

local PANEL = {}

function PANEL:Init()
	self:SetFont( "ButtonFont" )
	self:SetTextColor( Color( 255, 255, 255 ) )
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 19, 28, 35 ) )
	draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 47, 51, 54 ) )

	if not self:IsHovered() then
		draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 41, 44, 49 ) )
	else
		draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 51, 54, 59 ) )
	end

	if self:GetDisabled() then
		draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 19, 28, 35 ) )
	end
end

derma.DefineControl( "HButton", "A better DButton", PANEL, "DButton" )