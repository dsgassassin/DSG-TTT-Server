local PANEL = {}

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 19, 28, 35 ) )
	draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 51, 54, 59 ) )
	draw.RoundedBox( 0, 2, 2, ( w - 4 ) * self:GetFraction(), h - 4, Color( 19, 28, 35 ) )
end

derma.DefineControl( "HProgress", "A better DProgress", PANEL, "DProgress" )