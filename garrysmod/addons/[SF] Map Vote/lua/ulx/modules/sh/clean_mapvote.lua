local CATEGORY_NAME = "Clean Map Vote"
		
function ulx.CMV( ply )
	CMV:Start()
	ulx.fancyLogAdmin( ply, "#A forced a mapvote!" )
end
	
local mapvote = ulx.command( CATEGORY_NAME, "ulx mapvote", ulx.CMV, "!mapvote" )
mapvote:defaultAccess( ULib.ACCESS_ADMIN )
mapvote:help( "Starts a mapvote." )
