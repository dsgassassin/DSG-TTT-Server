-- UNCOMMENT TO USE FastDL
--LibK.addContentFolder( "materials/pointshop2" )
--LibK.addContentFolder( "materials/trails" )
resource.AddWorkshop( "439856500" )

CreateConVar("pointshop2_salt", "76561197981635631", {FCVAR_NOTIFY})

function Pointshop2.ResetDatabase( )
	local models = {}
	local function add( tbl )
		for k, v in pairs( tbl ) do
			if istable( v ) and v.dropTable then
				table.insert( models, v )
			end
		end
	end
	add( Pointshop2 )
	add( KInventory )

	LibK.SetBlocking( true )
	Pointshop2.DB.DisableForeignKeyChecks( true )
	local promises = {}
	for k, v in pairs( models ) do
		local promise = v.dropTable( )
		:Done( function( )
			KLogf( 5, "Dropped table %s", v.name )
		end )
		table.insert( promises, promise )
	end

	LibK.ResetTableCache( )

	for k, v in pairs( models ) do
		local promise = v:initializeTable( )
		:Done( function( )
			KLogf( 5, "Reset Table %s", v.name )
		end )
		table.insert( promises, promise )
	end
	Pointshop2.DB.DisableForeignKeyChecks( false )
	LibK.SetBlocking( false )

	return WhenAllFinished( promises )
end

/*
	This function tries to find and fix database errors.
	Only use it in extreme cases and ALWAYS do a backup!
	The function doesn't consider Lua defined items and detects them as DB errors, be very careful with that!
*/
function Pointshop2.FixDatabase( )
	Promise.Resolve( )
	-- 1: Find all itemPersistences without a valid parent base persistence
	:Then( function()
		return Pointshop2Controller:getPersistenceModels( )
	end )
	:Then( function( persistences )
		local promises = {}
		for _, persistenceModel in pairs( persistences ) do
			local promise = persistenceModel.getDbEntries( "WHERE 1" )
			:Then( function( persistentItems )
				local promises = {}
				for _, item in pairs( persistentItems ) do
					if not item.ItemPersistence then
						KLogf( 2, "[PS2-FIX] Found item persistence with invalid parent persistence, removing it, class %s, id %i", persistenceModel.name, item.id )
						table.insert( promises, item:remove( ) )
					end
				end
				return WhenAllFinished( promises )
			end )
			table.insert( promises, promise )
		end
		return WhenAllFinished( promises )
	end )

	-- 1.1: Find all hats with broken settings
	:Then( function( )
		return Pointshop2.HatPersistence.getAll( )
	end )
	:Then( function( persistentItems )
		local promises = {}
		for k, item in pairs( persistentItems ) do
			if not item.iconInfo.inv or not item.iconInfo.shop then
				KLogf( 2, "[PS2-FIX] Found hat persistence with invalid icon properties, id %i", item.id )
				table.insert( promises, Pointshop2.ItemPersistence.removeWhere{ id = item.ItemPersistence.id } )
			end
		end
		return WhenAllFinished( promises )
	end )

	-- 2: Find all items that don't have a valid class (base persistence)
	:Then( function( )
		return KInventory.Item.getAll( 0 ) --Don't resolve relationships
	end )
	:Then( function( items )
		local promises = {}
		for k, v in pairs( items ) do
			if v._creationFailed then
				PrintTable( v )
				KLogf( 2, "[PS2-FIX] Found invalid item reference in inventory, removing item %i, class %s", v.id, v._className )
				table.insert( promises, v:remove( ) )
			end
		end
		return WhenAllFinished( promises )
	end )

	-- 3: Find all item mappings that don't have a valid class (base persistence)
	:Then( function( )
		return Pointshop2.ItemMapping.getAll( )
	end )
	:Then( function( itemMappings )
		local promises = {}
		for k, itemMapping in pairs( itemMappings ) do
			local promise = Pointshop2.ItemPersistence.findById( itemMapping.itemClass )
			:Then( function( persistence )
				if not persistence then
					KLogf( 2, "[PS2-FIX] Found invalid reference in mapping, class was %s", itemMapping.itemClass )
					return itemMapping:remove( )
				end
			end )
			table.insert( promises, promise )
		end
		return WhenAllFinished( promises )
	end )

	-- 4: Remove settings wrongfully in the DB
	:Then( function( )
		return WhenAllFinished{
			Pointshop2.StoredSetting.removeWhere{ plugin = "Pointshop 2", path = "InternalSettings.Servers" },
			Pointshop2.StoredSetting.removeWhere{ plugin = "Pointshop 2", path = "InternalSettings.ServerId" }
		}
	end )

	-- 5: Remove Inventory assocs wrongfully in the DB
	:Then( function()
		return KInventory.Item.getAll( )
	end )
	:Then( function(items)
		return Promise.Map(items, function( item )
			if item.Inventory then
				item.Inventory = nil
				return item:save( )
			end
		end )
	end )

	-- 6: Fix wrong persistence for instaswitch Weapons
	:Then( function()
		return Pointshop2.DB.DoQuery([[INSERT INTO ps2_instatswitchweaponpersistence (weaponClass, loadoutType, itemPersistenceId)
		    SELECT WP.weaponClass AS weaponClass, WP.loadoutType AS loadoutType, WP.itemPersistenceId AS itemPersistenceId
		    FROM `ps2_itempersistence` IP, ps2_weaponpersistence WP
		    WHERE IP.baseClass="base_weapon_instaswitch" AND WP.itemPersistenceId = IP.id]])
	end )
	:Then( function( )
		if Pointshop2.DB.CONNECTED_TO_MYSQL then
			return Pointshop2.DB.DoQuery([[DELETE w FROM ps2_weaponpersistence w
				INNER JOIN `ps2_itempersistence`
					ON ps2_itempersistence.id = w.itemPersistenceId
				WHERE ps2_itempersistence.baseClass="base_weapon_instaswitch"]])
		else
			return Pointshop2.DB.DoQuery('SELECT w.id FROM ps2_weaponpersistence w INNER JOIN ps2_itempersistence ON ps2_itempersistence.id = w.itemPersistenceId WHERE ps2_itempersistence.baseClass="base_weapon_instaswitch"')
			:Then(function(ids)
				if ids and #ids then
					return Pointshop2.DB.DoQuery('DELETE FROM ps2_weaponpersistence WHERE id IN (' .. table.concat(LibK._.pluck(ids, 'id'), ",") .. ')')
				end
			end)
		end
	end )

	:Done( function( )
		RunConsoleCommand( "changelevel", game.GetMap( ) )
	end )
end

function Pointshop2.PlayerOwnsItem( ply, item )
	for k, v in pairs( ply.PS2_Inventory:getItems( ) ) do
		if v.id == item.id then
			return true
		end
	end

	for k, v in pairs( ply.PS2_Slots ) do
		if v.itemId == item.id then
			return true
		end
	end

	return false
end

function Pointshop2.BroadcastInfo( text )
	for k, v in pairs( player.GetAll( ) ) do
		v:PS2_DisplayInformation( text )
	end
end
