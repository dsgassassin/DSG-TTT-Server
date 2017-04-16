local CATEGORY_NAME = "Fun"

------------------------------ Slap ------------------------------
function ulx.slap( calling_ply, target_plys, dmg )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]
		if v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		else
			ULib.slap( v, dmg )
			table.insert( affected_plys, v )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A slapped #T with #i damage", affected_plys, dmg )
end

local slap = ulx.command( CATEGORY_NAME, "ulx slap", ulx.slap, "!slap" )
slap:addParam{ type=ULib.cmds.PlayersArg }
slap:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="damage", ULib.cmds.optional, ULib.cmds.round }
slap:defaultAccess( ULib.ACCESS_ADMIN )
slap:help( "Slaps target(s) with given damage." )

------------------------------ Slay ------------------------------
function ulx.slay( calling_ply, target_plys )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		elseif not v:Alive() then
			ULib.tsayError( calling_ply, v:Nick() .. " is already dead!", true )
		elseif v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		else
			v:Kill()
			table.insert( affected_plys, v )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A slayed #T", affected_plys )
end
local slay = ulx.command( CATEGORY_NAME, "ulx slay", ulx.slay, "!slay" )
slay:addParam{ type=ULib.cmds.PlayersArg }
slay:defaultAccess( ULib.ACCESS_ADMIN )
slay:help( "Slays target(s)." )

------------------------------ Unigniteall ------------------------------
function ulx.unigniteall( calling_ply )
	local flame_ents = ents.FindByClass( 'entityflame' )
	for _,v in ipairs( flame_ents ) do
		if v:IsValid() then
			v:Remove()
		end
	end

	local plys = player.GetAll()
	for _, v in ipairs( plys ) do
		if v:IsOnFire() then
			v:Extinguish()
			v.ulx_ignited_until = nil
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A extinguished everything" )
end
local unigniteall = ulx.command( CATEGORY_NAME, "ulx unigniteall", ulx.unigniteall, "!unigniteall" )
unigniteall:defaultAccess( ULib.ACCESS_ADMIN )
unigniteall:help( "Extinguishes all players and all entities." )

------------------------------ Freeze ------------------------------
function ulx.freeze( calling_ply, target_plys, should_unfreeze )
	local affected_plys = {}
	for i=1, #target_plys do
		if not should_unfreeze and ulx.getExclusive( target_plys[ i ], calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( target_plys[ i ], calling_ply ), true )
		else
			local v = target_plys[ i ]
			if v:InVehicle() then
				v:ExitVehicle()
			end

			if not should_unfreeze then
				v:Lock()
				v.frozen = true
				ulx.setExclusive( v, "frozen" )
			else
				v:UnLock()
				v.frozen = nil
				ulx.clearExclusive( v )
			end

			v:DisallowSpawning( not should_unfreeze )
			ulx.setNoDie( v, not should_unfreeze )
			table.insert( affected_plys, v )

			if v.whipped then
				v.whipcount = v.whipamt -- Will make it remove
			end
		end
	end

	if not should_unfreeze then
		ulx.fancyLogAdmin( calling_ply, "#A froze #T", affected_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unfroze #T", affected_plys )
	end
end
local freeze = ulx.command( CATEGORY_NAME, "ulx freeze", ulx.freeze, "!freeze" )
freeze:addParam{ type=ULib.cmds.PlayersArg }
freeze:addParam{ type=ULib.cmds.BoolArg, invisible=true }
freeze:defaultAccess( ULib.ACCESS_ADMIN )
freeze:help( "Freezes target(s)." )
freeze:setOpposite( "ulx unfreeze", {_, _, true}, "!unfreeze" )

------------------------------ God ------------------------------
function ulx.god( calling_ply, target_plys, should_revoke )
	if not target_plys[ 1 ]:IsValid() then
		if not should_revoke then
			Msg( "You are the console, you are already god.\n" )
		else
			Msg( "Your position of god is irrevocable; if you don't like it, leave the matrix.\n" )
		end
		return
	end

	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		else
			if not should_revoke then
				v:GodEnable()
				v.ULXHasGod = true
			else
				v:GodDisable()
				v.ULXHasGod = nil
			end
			table.insert( affected_plys, v )
		end
	end

	if not should_revoke then
		ulx.fancyLogAdmin( calling_ply, "#A granted god mode upon #T", affected_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A revoked god mode from #T", affected_plys )
	end
end
local god = ulx.command( CATEGORY_NAME, "ulx god", ulx.god, "!god" )
god:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
god:addParam{ type=ULib.cmds.BoolArg, invisible=true }
god:defaultAccess( ULib.ACCESS_ADMIN )
god:help( "Grants god mode to target(s)." )
god:setOpposite( "ulx ungod", {_, _, true}, "!ungod" )

------------------------------ Hp ------------------------------
function ulx.hp( calling_ply, target_plys, amount )
	for i=1, #target_plys do
		target_plys[ i ]:SetHealth( amount )
	end
	ulx.fancyLogAdmin( calling_ply, "#A set the hp for #T to #i", target_plys, amount )
end
local hp = ulx.command( CATEGORY_NAME, "ulx hp", ulx.hp, "!hp" )
hp:addParam{ type=ULib.cmds.PlayersArg }
hp:addParam{ type=ULib.cmds.NumArg, min=1, max=2^32/2-1, hint="hp", ULib.cmds.round }
hp:defaultAccess( ULib.ACCESS_ADMIN )
hp:help( "Sets the hp for target(s)." )


