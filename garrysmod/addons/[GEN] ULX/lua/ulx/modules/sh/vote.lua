local CATEGORY_NAME = "Voting"

---------------
--Public vote--
---------------
if SERVER then ulx.convar( "voteEcho", "0", _, ULib.ACCESS_SUPERADMIN ) end -- Echo votes?

-- First, our helper function to make voting so much easier!
function ulx.doVote( title, options, callback, timeout, filter, noecho, ... )
	timeout = timeout or 20
	if ulx.voteInProgress then
		Msg( "Error! ULX tried to start a vote when another vote was in progress!\n" )
		return false
	end

	if not options[ 1 ] or not options[ 2 ] then
		Msg( "Error! ULX tried to start a vote without at least two options!\n" )
		return false
	end

	local voters = 0
	local rp = RecipientFilter()
	if not filter then
		rp:AddAllPlayers()
		voters = #player.GetAll()
	else
		for _, ply in ipairs( filter ) do
			rp:AddPlayer( ply )
			voters = voters + 1
		end
	end

	umsg.Start( "ulx_vote", rp )
		umsg.String( title )
		umsg.Short( timeout )
		ULib.umsgSend( options )
	umsg.End()

	ulx.voteInProgress = { callback=callback, options=options, title=title, results={}, voters=voters, votes=0, noecho=noecho, args={...} }

	timer.Create( "ULXVoteTimeout", timeout, 1, ulx.voteDone )

	return true
end

function ulx.voteCallback( ply, command, argv )
	if not ulx.voteInProgress then
		ULib.tsayError( ply, "There is not a vote in progress" )
		return
	end

	if not argv[ 1 ] or not tonumber( argv[ 1 ] ) or not ulx.voteInProgress.options[ tonumber( argv[ 1 ] ) ] then
		ULib.tsayError( ply, "Invalid or out of range vote." )
		return
	end

	if ply.ulxVoted then
		ULib.tsayError( ply, "You have already voted!" )
		return
	end

	local echo = ULib.toBool( GetConVarNumber( "ulx_voteEcho" ) )
	local id = tonumber( argv[ 1 ] )
	ulx.voteInProgress.results[ id ] = ulx.voteInProgress.results[ id ] or 0
	ulx.voteInProgress.results[ id ] = ulx.voteInProgress.results[ id ] + 1

	ulx.voteInProgress.votes = ulx.voteInProgress.votes + 1

	ply.ulxVoted = true -- Tag them as having voted

	local str = ply:Nick() .. " voted for: " .. ulx.voteInProgress.options[ id ]
	if echo and not ulx.voteInProgress.noecho then
		ULib.tsay( _, str ) -- TODO, color?
	end
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end

	if ulx.voteInProgress.votes >= ulx.voteInProgress.voters then
		ulx.voteDone()
	end
end
if SERVER then concommand.Add( "ulx_vote", ulx.voteCallback ) end

function ulx.voteDone( cancelled )
	local players = player.GetAll()
	for _, ply in ipairs( players ) do -- Clear voting tags
		ply.ulxVoted = nil
	end

	local vip = ulx.voteInProgress
	ulx.voteInProgress = nil
	timer.Remove( "ULXVoteTimeout" )
	if not cancelled then
		ULib.pcallError( vip.callback, vip, unpack( vip.args, 1, 10 ) ) -- Unpack is explicit in length to avoid odd LuaJIT quirk.
	end
end
-- End our helper functions

local function voteDone( t )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local str
	if not winner then
		str = "Vote results: No option won because no one voted!"
	else
		str = "Vote results: Option '" .. t.options[ winner ] .. "' won. (" .. winnernum .. "/" .. t.voters .. ")"
	end
	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	Msg( str .. "\n" )
end

function ulx.vote( calling_ply, title, ... )
	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end

	ulx.doVote( title, { ... }, voteDone )
	ulx.fancyLogAdmin( calling_ply, "#A started a vote (#s)", title )
end
local vote = ulx.command( CATEGORY_NAME, "ulx vote", ulx.vote, "!vote" )
vote:addParam{ type=ULib.cmds.StringArg, hint="title" }
vote:addParam{ type=ULib.cmds.StringArg, hint="options", ULib.cmds.takeRestOfLine, repeat_min=2, repeat_max=10 }
vote:defaultAccess( ULib.ACCESS_ADMIN )
vote:help( "Starts a public vote." )

-- Stop a vote in progress
function ulx.stopVote( calling_ply )
	if not ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is no vote currently in progress.", true )
		return
	end

	ulx.voteDone( true )
	ulx.fancyLogAdmin( calling_ply, "#A has stopped the current vote." )
end
local stopvote = ulx.command( CATEGORY_NAME, "ulx stopvote", ulx.stopVote, "!stopvote" )
stopvote:defaultAccess( ULib.ACCESS_SUPERADMIN )
stopvote:help( "Stops a vote in progress." )
