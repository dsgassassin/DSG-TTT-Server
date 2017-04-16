util.AddNetworkString( "CMV_Start" )
util.AddNetworkString( "CMV_End" )
util.AddNetworkString( "CMV_Votes" )
util.AddNetworkString( "CMV_Inform" )

local cfg = CMV.Config

CMV.Voting = false
CMV.RTV = math.Round( #player.GetHumans() * cfg.RTVAmount )
CMV.RTVAmount = 0
CMV.Maps = {}
CMV.Votes = {}

for i = 1, cfg.MapAmount do
    table.insert( CMV.Votes, 0 )
end

function CMV:ChangeMap()
    RunConsoleCommand( "changelevel", self )
end
 
function CMV:LoadGamemodes()
	if !sql.TableExists( "cmv_cooldown" ) then
		sql.Query "CREATE TABLE IF NOT EXISTS cmv_cooldown ( map TEXT NOT NULL, remaining INTEGER NOT NULL )"
	end

    if !cfg.AutoPrefix then
        hook.Add( "CMV_ChangeMap", "CMV_ChangeMap", CMV.ChangeMap )
        return
    end

    local gamemodesTable = {
        "terrortown",
        "deathrun",
        "murder",
        "jailbreak",
        "prop_hunt",
		"zombiesurvival",
		"fretta",
		"stalker",
		"guesswho"
    }

    local gamemodeName = GetConVar( "gamemode" ):GetString()

    if !table.HasValue( gamemodesTable, gamemodeName ) then
		if gmod.GetGamemode().BaseClass.FolderName and gmod.GetGamemode().BaseClass.FolderName:lower() == "fretta" then 
			gamemodeName = "fretta"
			include( "clean_mapvote/gamemodes/" .. gamemodeName .. ".lua" )
		end
		
        error "No valid gamemode detected!"
        return
    end

    include( "clean_mapvote/gamemodes/" .. gamemodeName .. ".lua" )
end

CMV:LoadGamemodes()

function CMV:PlayerInitialize()
    self.Voted = false
    self.VotedMap = 0
end
hook.Add( "PlayerAuthed", "CMV_PlayerInitialize", CMV.PlayerInitialize )

function CMV:GetMaps()
    local availableMaps = {}
    local tempMaps = {}
	local mapCooldowns = sql.Query "SELECT * FROM cmv_cooldown"

    for _, prefix in ipairs( cfg.Prefixes ) do
        availableMaps[ _ ] = file.Find( "maps/" .. prefix .. "*.bsp", "GAME" )
    end

    for _, mapdir in ipairs( availableMaps ) do
        for _, map in ipairs( mapdir ) do
            table.insert( tempMaps, map:Replace( ".bsp", "" ) )
        end
    end

    for _, map in ipairs( tempMaps ) do
        if map:find( game.GetMap() ) then
            table.remove( tempMaps, _ )
            break
        end
    end

    for _, map in ipairs( cfg.BlacklistMaps ) do
        if table.HasValue( tempMaps, map ) then
            table.RemoveByValue( tempMaps, map )
        end
    end

    for _, map in ipairs( cfg.ExtraMaps ) do
        table.insert( tempMaps, map )
    end
	
	if mapCooldowns != nil then
		for _, row in ipairs( mapCooldowns ) do
			if table.HasValue( tempMaps, row.map ) then
				table.RemoveByValue( tempMaps, row.map )
			end
		end
	end

	local iterations = cfg.ExtendMap and cfg.MapAmount - 1 or cfg.MapAmount

    for i = 1, iterations do
        local map = table.Random( tempMaps )
        table.insert( CMV.Maps, map )
        table.RemoveByValue( tempMaps, map )
    end

	if cfg.ExtendMap then
		table.insert( CMV.Maps, game.GetMap() )
	end
end

function CMV:Start()
    if CMV.Voting then return end

    self:Print "A mapvote has begun..."

    CMV.Voting = true
    CMV:GetMaps()

    net.Start( "CMV_Start" )
    net.WriteTable( CMV.Maps )
    net.Broadcast()

    timer.Simple( cfg.VoteTime, function()
        CMV:End()
    end )
end

function CMV:End()
    if !CMV.Voting then return end

    CMV.Voting = false

    local winningIndex = table.GetWinningKey( CMV.Votes )
    local winningMap = CMV.Maps[ winningIndex ]

    net.Start( "CMV_End" )
    net.WriteString( winningMap )
    net.Broadcast()
	
	local mapCooldowns = sql.Query "SELECT * FROM cmv_cooldown"
	local cooledMaps = {}
	
	if mapCooldowns != nil then
		for _, row in ipairs( mapCooldowns ) do
			sql.Query( "UPDATE cmv_cooldown SET remaining = remaining - 1 WHERE map = " .. SQLStr( row.map ) )
			
			if tonumber( row.remaining ) - 1 == 0 then
				sql.Query( "DELETE FROM cmv_cooldown WHERE map = " .. SQLStr( row.map ) )
			end
			
			table.insert( cooledMaps, row.map )
		end
	end
	
	if !table.HasValue( cooledMaps, game.GetMap() ) then
		sql.Query( "INSERT INTO cmv_cooldown ( map, remaining ) VALUES( " .. SQLStr( game.GetMap() ) .. ", " .. SQLStr( cfg.Cooldown ) .. " )" )
	end

    timer.Simple( cfg.PostVoteTime, function()
        hook.Call( "CMV_ChangeMap", nil, winningMap )
    end )
end

function CMV:Inform( msg, ply )
    net.Start( "CMV_Inform" )
    net.WriteString( msg )

    if ply then
        net.Send( ply )
    else
        net.Broadcast()
    end
end

function CMV:Vote( useless, args )
    local map = tonumber( args[ 1 ] )

    if CMV.Voting and map < cfg.MapAmount + 1 and map > 0 then
		local voteAmount = cfg.VotePower[ self:GetUserGroup() ] and cfg.VotePower[ self:GetUserGroup() ] or 1
		
        if self.Voted then
            CMV.Votes[ self.VotedMap ] = CMV.Votes[ self.VotedMap ] - voteAmount
            CMV.Votes[ map ] = CMV.Votes[ map ] + voteAmount
            self.VotedMap = map
        else
            CMV.Votes[ map ] = CMV.Votes[ map ] + voteAmount
            self.Voted = true
            self.VotedMap = map
        end

        net.Start( "CMV_Votes" )
        net.WriteTable( CMV.Votes )
        net.Broadcast()
    end
end
concommand.Add( "cmv_vote", CMV.Vote )

function CMV:RTVCommand()
    if !CMV.Voting then
        if self.RTVed then
            CMV:Inform( "You have already rocked the vote! " .. CMV.RTV - CMV.RTVAmount .. " more votes required to start a map vote.", self )
        else
            CMV:Inform( self:Nick() .. " has rocked the vote! " .. CMV.RTV - CMV.RTVAmount .. " more votes required to start a map vote." )
            CMV.RTVAmount = CMV.RTVAmount + 1
			self.RTVed = true
        end
    end
end
concommand.Add( cfg.RTVCommand, CMV.RTVCommand )

function CMV:CheckRTV()
	if #player.GetHumans() < 1 then return end

	CMV.RTV = math.Round( #player.GetHumans() * cfg.RTVAmount )

    if CMV.RTVAmount >= CMV.RTV and !CMV.Voting then
        if GetConVar( "gamemode" ) == "terrortown" then
            if GetRoundState() == ROUND_POST or GetRoundState() == ROUND_WAIT or #player.GetHumans() <= 2 then
                CMV:Start()
            end
        else
            CMV:Start()
        end

        hook.Remove( "Think", "CMV_CheckRTV" )
    end
end
hook.Add( "Think", "CMV_CheckRTV", CMV.CheckRTV )

function CMV:Chat( text )
    if text:lower():match( "^[!/:.]"  .. cfg.RTVChatCommand ) then
        self:ConCommand( cfg.RTVCommand )

        return ""
    end
end
hook.Add( "PlayerSay", "CMV_Chat", CMV.Chat )
