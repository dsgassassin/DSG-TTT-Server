CMV = CMV or {}

function CMV:Print( t )
    MsgC( Color( 0 ,178, 238 ), "[Clean Map Vote] ", Color( 255, 255, 255 ), t .. "\n" )
end

local function inc( file, pre )
	local includes = {
		[ "sv_" ] = SERVER and include or function() end,
		[ "cl_" ] = CLIENT and include or AddCSLuaFile,
		[ "sh_" ] = function( file ) if SERVER then include( file ) AddCSLuaFile( file ) else include( file ) end end
	}

    if !includes[ pre ] then return end

	includes[ pre ]( file )
end

function CMV:Load()
    self:Print 'Loading Clean Map Vote by Michael "Beast/xbeastguyx" (STEAM_0:0:2316327)'
    self:Print "Initializing..."

    local _, folders = file.Find( "clean_mapvote/*", "LUA" )

    for _, folder in ipairs( folders ) do
        for _, file in ipairs( file.Find( "clean_mapvote/" .. folder .. "/*.lua", "LUA" ) ) do
            inc( "clean_mapvote/" .. folder .. "/" .. file, file:sub( 1, 3 ) )
        end
    end

    self:Print "Loaded successfully..."
end

CMV:Load()
