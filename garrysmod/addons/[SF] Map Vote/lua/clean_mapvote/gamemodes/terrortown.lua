CMV:Print "Loaded TTT Compatability"

CMV.Config.Prefixes = {
	"ttt_",
	"de_"
}

function CMV:GamemodeOverride()
	GAMEMODE = GAMEMODE or GM
	GAMEMODE.StartFrettaVote = function() end

	function game.LoadNextMap()
		CMV:Start()
	end

	local oldTimer = timer.Simple

	function timer.Simple( t, func, ... )
		if func == game.LoadNextMap then
			CMV:Start()
			return
		end

		oldTimer( t, func, ... )
	end
end
hook.Add( "Initialize", "CMV_GamemodeOverride", CMV.GamemodeOverride )

function CMV:ChangeMap()
	if self == game.GetMap() then
		SetGlobalInt( "ttt_rounds_left", GetConVar( "ttt_round_limit" ):GetInt() )
		SetGlobalInt( "ttt_time_limit_minutes", CurTime() + GetConVar( "ttt_time_limit_minutes" ):GetInt() )

		timer.Create( "end2prep", 1, 1, PrepareRound )
		
		RunConsoleCommand( "ttt_rounds_left", GetConVar( "ttt_round_limit" ):GetInt() )
		RunConsoleCommand( "ttt_time_limit_minutes", CurTime() + GetConVar( "ttt_time_limit_minutes" ):GetInt() )

		table.Empty( CMV.Votes )

		for i = 1, CMV.Config.MapAmount do
			table.insert( CMV.Votes, 0 )
		end

		for _, ply in ipairs( player.GetAll() ) do
			ply.Voted = false
		    ply.VotedMap = 0
			ply.RTVed = false
		end
	else
		RunConsoleCommand( "changelevel", self )
	end
end
hook.Add( "CMV_ChangeMap", "CMV_ChangeMap", CMV.ChangeMap )
