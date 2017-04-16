function surface.CreateCircle( x, y, r, c )
	local circle = {}

	for i = 1, 360 do
		circle[ i ] = {}
		circle[ i ].x = x + math.cos( math.rad( i * 360 ) / 360 ) * r
		circle[ i ].y = y + math.sin( math.rad( i * 360 ) / 360 ) * r
	end

	draw.NoTexture()
	surface.SetDrawColor( c )
	surface.DrawPoly( circle )
end