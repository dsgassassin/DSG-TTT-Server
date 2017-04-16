Pointshop2Controller = class( "Pointshop2Controller" )
Pointshop2Controller:include( BaseController )

function Pointshop2.InitPromises( )
	Pointshop2.LoadModulesPromise = Deferred( )
	Pointshop2.LoadModulesPromise:Done( function( )
		KLogf( 4, "[Pointshop 2] All Modules were loaded" )
	end )

	Pointshop2.LoadModuleItemsPromise = Deferred( )
	Pointshop2.LoadModuleItemsPromise:Done( function( )
		KLogf( 4, "[Pointshop2] All Module items were loaded" )
	end )

	Pointshop2.ItemsLoadedPromise = Deferred( )
	Pointshop2.ItemsLoadedPromise:Done( function( )
		KLogf( 4, "[Pointshop2] All Items were loaded by KInv" )
	end )
	Pointshop2.ItemsLoadedPromise:Fail( function( )
		debug.Trace( )
	end )
	hook.Add( "KInv_ItemsLoaded", "ResolveDeferred", function( )
		Pointshop2.ItemsLoadedPromise:Resolve( ) --Trigger ready for all listeners
	end )

	Pointshop2.DatabaseConnectedPromise = Deferred( )
	Pointshop2.DatabaseConnectedPromise:Done( function( )
		KLogf( 4, "[Pointshop2] The database was connected" )
	end )
	function Pointshop2.onDatabaseConnected( )
		if not Pointshop2.DB then
			Pointshop2.DatabaseError = true
			return
		end

		DATABASES["KInventory"] = Pointshop2.DB
		Pointshop2.LoadModulesPromise:Done( function( )
			Pointshop2.DatabaseConnectedPromise:Resolve( )
		end )
	end
	function Pointshop2.onDatabaseConnectionFailed( err )
		Pointshop2.DatabaseConnectedPromise:Reject( err )
		KLogf( 1, "[Pointshop2] The database is not set up correctly!")
	end

	Pointshop2.SettingsLoadedPromise = Deferred( )
	Pointshop2.SettingsLoadedPromise:Done( function( )
		KLogf( 4, "[Pointshop2] Settings have been loaded" )
	end )

	Pointshop2.FullyInitializedPromise = WhenAllFinished{
		Pointshop2.ItemsLoadedPromise:Promise( ),
		Pointshop2.DatabaseConnectedPromise:Promise( ),
		Pointshop2.SettingsLoadedPromise:Promise( ),
		Pointshop2.LoadModulesPromise:Promise( )
	}
	Pointshop2.FullyInitializedPromise:Done( function( )
		KLogf( 4, "[Pointshop2] The initial load stage has been completed" )
	end )
end
Pointshop2.InitPromises( )

--Modules can contain own models and are loaded on InitPostEntity.
--Wait for this hook until initializing the database
Pointshop2.LoadModulesPromise:Done( function( )
	KLogf( 4, "[Pointshop2] Starting Database initialization" )

	LibK.SetupDatabase( "Pointshop2", Pointshop2, nil, true )
	Pointshop2.DBInitialize( )
end )

--Override for access controll
--returns a promise, resolved if user can do it, rejected with error if he cant
function Pointshop2Controller:canDoAction( ply, action )
	local def = Deferred( )
	if action == "saveCategoryOrganization" or
	   action == "removeItem" or
	   action == "removeItems" or
	   action == "migrateServer" or
	   action == "removeServer" or
	   action == "updateServerRestrictions" or
		 action == "updateRankRestrictions" or
	   action == "requestMaterials"
	then
		if PermissionInterface.query( ply, "pointshop2 manageitems" ) then
			def:Resolve( )
		else
			def:Reject( 1, "Permission Denied" )
		end
	elseif action =="adminGetServers" then
		if PermissionInterface.query( ply, "pointshop2 manageservers" ) then
			def:Resolve( )
		else
			def:Reject( 1, "Permission Denied" )
		end
	elseif action == "resetToDefaults" or action == "installDefaults" or action == "fixDatabase" or action == "installDlcPack" then
		if PermissionInterface.query( ply, "pointshop2 reset" ) then
			def:Resolve( )
		else
			def:Reject( 1, "Permission Denied" )
		end
	elseif action == "saveModuleItem" then
		if PermissionInterface.query( ply, "pointshop2 createitems" ) then
			def:Resolve( )
		else
			def:Reject( 1, "Permission Denied" )
		end
	elseif action == "outfitsReceived" or action == "dynamicsReceived" then
		def:Resolve( )
	elseif action == "searchPlayers" or
		   action == "getUserDetails" or
		   action == "adminChangeWallet" or
		   action == "adminGiveItem" or
			 action == "adminRemoveItem"
	then
		if PermissionInterface.query( ply, "pointshop2 manageusers" ) then
			def:Resolve( )
		else
			def:Reject( 1, "Permission Denied" )
		end
	elseif action == "buyItem" or action == "sellItem" then
		def:Resolve( )
	elseif action == "equipItem" or action == "unequipItem" then
		def:Resolve( )
	elseif action == "sendPoints" then
		def:Resolve( )
	else
		def:Reject( 1, "Permission denied" )
	end
	return def:Promise( )
end

function Pointshop2Controller:initializeInventory( ply )
	return KInventory.Inventory.findByOwnerId( ply.kPlayerId )
	:Then( function( inventory )
		--Check for Inventory and create if necessary
		if inventory then
			return inventory
		end

		inventory = KInventory.Inventory:new( )
		inventory.ownerId = ply.kPlayerId
		inventory.numSlots = Pointshop2.GetSetting( "Pointshop 2", "BasicSettings.DefaultSlots" )
		inventory.maxWeight = 0 --Not using weight for ps items
		return inventory:save( )
	end )
	:Then( function( inventory )
		if inventory.numSlots < tonumber( Pointshop2.GetSetting( "Pointshop 2", "BasicSettings.DefaultSlots" ) ) then
			inventory.numSlots = tonumber( Pointshop2.GetSetting( "Pointshop 2", "BasicSettings.DefaultSlots" ) )
			return inventory:save( )
		end
		return inventory
	end )
	:Then( function( inventory )
		--Load Items
		return inventory:loadItems( )
		:Done( function( )
			--Cache the inventory
			ply.PS2_Inventory = inventory
			KLogf( 5, "[PS2] Loaded inventory for player %s", ply:Nick( ) )

			--Network the Inventory to the player
			self:startView( "Pointshop2View", "receiveInventory", ply, inventory )
			--self:startView( "InventoryView", "receiveInventory", ply, inventory )
		end )
		:Fail( function( errid, err )
			KLogf( 2, "Error loading items %i %s", errid, err )
		end )
	end,
	function( errid, err )
		KLogf( 2, "Error creating inventory %i %s", errid, err )
	end )
end

/*
	After joining initialize all slots for the player
	and equip Items he has in them
*/
function Pointshop2Controller:initializeSlots( ply )
	return Pointshop2.EquipmentSlot.findAllByOwnerId( ply.kPlayerId )
	:Then( function( slots )
		ply.PS2_Slots = {}
		for _, slot in pairs( slots ) do
			ply.PS2_Slots[slot.id] = slot
			KLogf( 5, "[PS2] Loaded slot %i for player %s", _, ply:Nick( ) )
		end
		self:startView( "Pointshop2View", "receiveSlots", ply, slots )

		for _, slot in pairs( ply.PS2_Slots ) do
			if not slot.itemId then continue end

			local item = slot.Item or KInventory.ITEMS[slot.itemId]
			if not item then
				KLogf( 2, "[WARN-01] Uncached item %s from player %s slot %s", slot.itemId, ply:Nick( ), slot.slotName )
				continue
			end

			item.owner = ply
			if not IsValid( item:GetOwner() ) then
				debug.Trace( )
				print( "Error in 3" )
			end

			--Delay to next frame to clear stack
			timer.Simple( 0, function( )
				if item.class:IsValidForServer( Pointshop2.GetCurrentServerId( ) ) then
					self:startViewWhenValid( "Pointshop2View", "playerEquipItem", player.GetAll( ), ply.kPlayerId, item )
					item:OnEquip( )
				end
			end )
		end
	end )
end

function Pointshop2Controller:startViewWhenValid( view, action, plyOrPlys, ... )
	local args = {...}

	if type( plyOrPlys ) != "table" then
		plyOrPlys = { plyOrPlys }
	end

	for k, ply in pairs( plyOrPlys ) do
		WhenAllFinished{ ply.outfitsReceivedPromise:Promise( ), ply.dynamicsReceivedPromise:Promise( ) }
		:Done( function( )
			self:startView( view, action, ply, unpack( args ) )
		end )
	end
end

local function loadOrCreateCategoryTree( )
	return Pointshop2.Category.getDbEntries( "WHERE 1 ORDER BY parent ASC" )
	:Then( function( categories )
		if #categories == 0 then
			local rootNode = Pointshop2.Category:new( )
			rootNode.label = "Root"
			rootNode.icon = "Root"

			return rootNode:save( )
			:Then( function( rootNode )
				local notForSale = Pointshop2.Category:new( )
				notForSale.label = "Not for sale Items"
				notForSale.icon = "pointshop2/circle14.png"
				notForSale.parent = rootNode.id

				local shopCategories = Pointshop2.Category:new( )
				shopCategories.label = "Shop Categories"
				shopCategories.icon = "pointshop2/folder62.png"
				shopCategories.parent = rootNode.id

				return WhenAllFinished{ notForSale:save( ), shopCategories:save( ) }
			end )
			:Then( function( )
				return Pointshop2.Category.getDbEntries( "WHERE 1 ORDER BY parent ASC" )
			end )
		end
		return categories
	end )
end

function Pointshop2Controller:loadDynamicInfo( )
	LibK.GLib.Resources.Resources["Pointshop2/dynamics"] = nil --Force resource reset
	self.dynamicsResource = nil
	return WhenAllFinished{ Pointshop2.ItemMapping.getDbEntries( "WHERE 1" ),
							loadOrCreateCategoryTree( )
	}
	:Then( function( itemMappings, categories )
		local itemProperties = self.cachedPersistentItems

		self.itemCategories = categories
		self.itemMappings = itemMappings
		local tblData = {
			generateNetTable( itemMappings ),
			generateNetTable( categories ),
			generateNetTable( itemProperties )
		}

		local data = LibK.von.serialize( { tblData } )
		local resource = LibK.GLib.Resources.RegisterData( "Pointshop2", "dynamics", data )
		resource:GetCompressedData( ) --Force compression now
		KLogf( 4, "[Pointshop2] Dynamics package loaded, version %s, %i item mappings, %i categories, %i items", resource:GetVersionHash(), table.Count( itemMappings ), table.Count( categories ), table.Count( itemProperties ) )

		self.tree = Pointshop2.BuildTree( self.itemCategories, self.itemMappings )
		self.dynamicsResource = resource
	end )
end
Pointshop2.DynamicsLoadedPromise = Pointshop2.LoadModuleItemsPromise:Then( function( )
	return Pointshop2Controller:getInstance( ):loadDynamicInfo( )
end )
function Pointshop2Controller:sendDynamicInfo( ply )
	if ply.dynamicsReceivedPromise._promise._state != "pending" then
		ply.dynamicsReceivedPromise = Deferred( )
	end
	if not self.dynamicsResource then
		KLogf( 3, "[Pointshop2] Dynamics resource not loaded when player joined" )
	end

Pointshop2.DynamicsLoadedPromise:Done( function( )
		self:startView( "Pointshop2View", "loadDynamics", ply, self.dynamicsResource:GetVersionHash() )
	end )
end

function Pointshop2Controller:dynamicsReceived( ply )
	ply.dynamicsReceivedPromise:Resolve( )
end

--[[
	Send equipped items of players to "late" joiners
]]--
function Pointshop2Controller:sendActiveEquipmentTo( plyToSendTo )
	for _, ply in pairs( player.GetAll( ) ) do
		if ply == plyToSendTo then
			continue --handled in the slot-sender
		end

		if not ply.PS2_Slots then
			continue --handled in the slot-sender
		end

		for _, slot in pairs( ply.PS2_Slots ) do
			if not slot.itemId then continue end

			local item = KInventory.ITEMS[slot.itemId]
			if not item then
				KLogf( 2, "[WARN] Uncached item %s from player %s slot %s", slot.itemId, ply:Nick( ), slot.slotName )
				continue
			end
			self:startViewWhenValid( "Pointshop2View", "playerEquipItem", plyToSendTo, ply.kPlayerId, item )
		end
	end
end

hook.Add( "PlayerInitialSpawn", "EnforceValidPromise", function( ply )
	ply.dynamicsReceivedPromise = Deferred( )
	ply.outfitsReceivedPromise = Deferred( )
	ply.fullyLoadedPromise = Deferred( )
	hook.Add( "PS2_PlayerFullyLoaded", "FullyLoadedResolver_" .. ply:SteamID(), function( loadedPly )
		if loadedPly == ply then
			ply.fullyLoadedPromise:Resolve( )
			hook.Remove( "PS2_PlayerFullyLoaded", "FullyLoadedResolver_" .. ply:SteamID( ) )
		end
	end )
end )

local function initPlayer( ply )
	KLogf( 5, "[PS2] Initializing player %s, modules loaded: %s", ply:Nick( ), Pointshop2.LoadModuleItemsPromise:Promise( )._state )
	local controller = Pointshop2Controller:getInstance( )

	Pointshop2.DatabaseConnectedPromise:Fail( function( err )
		if ply:IsAdmin( ) then
			timer.Simple( 2, function( )
				ply:PS2_DisplayError( "[CRITICAL][ADMIN ONLY] Your MySQL configuration is faulty. (" .. err .. "). Please fix these errors. Other parts of your server can be affected by errors if this is not fixed.", 1000 )
			end )
		end
	end )

	Pointshop2.LoadModuleItemsPromise:Then( function( )
		controller:sendDynamicInfo( ply )
		return ply.dynamicsReceivedPromise
	end )
	:Done( function( )
		controller:sendWallet( ply )
		--TODO: Make a proper promise/transaction for this
		timer.Simple( 2, function( )
			WhenAllFinished{ controller:initializeInventory( ply ),
				controller:initializeSlots( ply ),
				ply.outfitsReceivedPromise
			}
			:Done( function( )
				controller:sendActiveEquipmentTo( ply )
				hook.Run("PS2_PlayerFullyLoaded", ply)
			end )
		end )
	end )
end

local function reloadAllPlayers( )
	for _, ply in pairs( player.GetAll( ) ) do
		ply.outfitsReceivedPromise = Deferred( )
		ply.dynamicsReceivedPromise = Deferred( )
	end
	timer.Simple( 0, function( )
		for _, ply in pairs( player.GetAll( ) ) do
			initPlayer( ply )
		end
	end )
end

hook.Add( "LibK_PlayerInitialSpawn", "Pointshop2Controller:initPlayer", function( ply )
	KLogf( 5, "[PS2] Initializing player %s, modules loaded: %s", ply:Nick( ), Pointshop2.LoadModuleItemsPromise:Promise( )._state )
	timer.Simple( 1, function( )
		if not IsValid( ply ) then
			KLogf( 4, "[PS2] Loading a player failed, possible disconnect" )
		end
		initPlayer( ply )
	end )
end )
hook.Add( "OnReloaded", "Pointshop2Controller:sendDynamicInfo", function( )
	reloadAllPlayers( )
end )

local function performSafeCategoryUpdate( categoryItemsTable )
	--Repopulate Categories Table
	Pointshop2.Category.removeDbEntries( "WHERE 1=1" )
	:Fail( function( errid, err ) error( "Couldn't truncate categories", errid, err ) end )

	local function recursiveAddCategory( category, parentId )
		local dbCategory = Pointshop2.Category:new( )
		dbCategory.label = category.self.label
		dbCategory.icon = category.self.icon
		dbCategory.parent = parentId
		return dbCategory:save( )
		:Done( function( x )
			category.id = dbCategory.id --need this later for the items
			for _, subcategory in pairs( category.subcategories ) do
				recursiveAddCategory( subcategory, dbCategory.id )
			end
		end )
		:Fail( function( errid, err ) error( "Error saving subcategory", errid, err ) end )
	end
	recursiveAddCategory( categoryItemsTable )

	--Repopulate Item Mappings Table
	Pointshop2.ItemMapping.removeDbEntries( "WHERE 1=1" )
	:Fail( function( errid, err ) error( "Couldn't truncate item mappings", errid, err ) end )

	if Pointshop2.DB.CONNECTED_TO_MYSQL then
		local mappings = {}
		local function recursiveAddItems( category )
			for _, itemClassName in pairs( category.items ) do
				table.insert( mappings, string.format( "(%s, %s)", Pointshop2.DB.SQLStr( itemClassName ), Pointshop2.DB.SQLStr( category.id ) ) )
			end

			for _, subcategory in pairs( category.subcategories ) do
				recursiveAddItems( subcategory )
			end
		end
		recursiveAddItems( categoryItemsTable )

		-- Prevent error if no mappings are present
		if #mappings == 0 then
			return
		end

		local splitted = LibK.splitTable( mappings, 50 )
		for k, mappingsChunk in pairs(splitted) do
			local query = "INSERT INTO ps2_itemmapping (itemClass, categoryId) VALUES "
			query = query .. table.concat( mappingsChunk, ", " )
			Pointshop2.DB.DoQuery( query )
		end
	else

		local mappings = {}
		local function recursiveAddItems( category )
			for _, itemClassName in pairs( category.items ) do
				table.insert( mappings, { itemClassName = itemClassName, categoryId = category.id } )
			end

			for _, subcategory in pairs( category.subcategories ) do
				recursiveAddItems( subcategory )
			end
		end
		recursiveAddItems( categoryItemsTable )

		for _, itemClassName in ipairs( mappings ) do
			print( "\t" .. Pointshop2.GetItemClassByName( itemClassName.itemClassName ):GetPrintName(), itemClassName.itemClassName )
		end

		-- Prevent error if no mappings are present
		if #mappings == 0 then
			return
		end

		local splitted = LibK.splitTable( mappings, 50 )
		local lastQuery = Promise.Resolve()
		for k, mappingsChunk in pairs( splitted ) do
			for k, v in pairs( mappingsChunk ) do
				Pointshop2.DB.DoQuery( Format( "INSERT INTO ps2_itemmapping\n SELECT %s as itemClass, %i as categoryId, NULL as id ",
					Pointshop2.DB.SQLStr( v.itemClassName ),
					tonumber( v.categoryId )
				) )
			end
		end
	end
end

local GLib = LibK.GLib
GLib.Transfers.RegisterInitialPacketHandler( "Pointshop2.CategoryOrganization", function( userId )
	local ply = GLib.PlayerMonitor:GetUserEntity( userId )
	return PermissionInterface.query( ply, "pointshop2 manageitems" )
end )

GLib.Transfers.RegisterHandler( "Pointshop2.CategoryOrganization", function( userId, data )
	Pointshop2Controller:getInstance( ):saveCategoryOrganization( GLib.PlayerMonitor:GetUserEntity( userId ), util.JSONToTable( data ) )
end )

function Pointshop2Controller:saveCategoryOrganization( ply, categoryItemsTable )
	--Wrap it into a transaction in case anything happens.
	--since tables are cleared and refilled for this it could fuck up the whole pointshop
	LibK.SetBlocking( true )
	Pointshop2.DB.DoQuery( "BEGIN" )
	:Fail( function( errid, err )
		KLogf( 2, "Error starting transaction: %s", err )
		self:startView( "Pointshop2View", "displayError", ply, "A Technical error occured, your changes could not be saved!" )
		error( "Error starting transaction:", err )
	end )

	Pointshop2.DB.DisableForeignKeyChecks( true )

	local success, err = pcall( performSafeCategoryUpdate, categoryItemsTable )
	if not success then
		KLogf( 2, "Error saving categories: %s", err )
		Pointshop2.DB.DoQuery( "ROLLBACK" )
		Pointshop2.DB.DisableForeignKeyChecks( false )
		LibK.SetBlocking( false )

		self:startView( "Pointshop2View", "displayError", ply, "A technical error occured, your changes could not be saved!" )
	else
		KLogf( 4, "Categories Updated" )
		Pointshop2.DB.DoQuery( "COMMIT" )
		Pointshop2.DB.DisableForeignKeyChecks( false )
		LibK.SetBlocking( false )

		self:loadDynamicInfo( ):Done( function( )
			for k, v in pairs( player.GetAll( ) ) do
				self:sendDynamicInfo( v )
			end
		end )
	end
end

function Pointshop2Controller:getPersistenceModels( )
	local persistences = {}
	for _, mod in pairs( Pointshop2.Modules ) do
		for k, v in pairs( mod.Blueprints ) do
			local class = Pointshop2.GetItemClassByName( v.base )
			if not class then
				KLogf( 2, "[Pointshop2][Error] Blueprint %s: couldn't find baseclass", v.base )
				continue
			end

			table.insert( persistences, class.getPersistence( ) )
		end
	end
	return persistences
end

function Pointshop2Controller:loadModuleItems( )
	local promises = {}
	self.cachedPersistentItems = {}

	for _, persistence in pairs( Pointshop2Controller:getPersistenceModels( ) ) do
		local promise = persistence.getDbEntries( "WHERE 1" )
		:Then( function( persistentItems )
			for _, persistentItem in pairs( persistentItems ) do
				table.insert( self.cachedPersistentItems, persistentItem )
				Pointshop2.LoadPersistentItem( persistentItem )
			end
		end )
		table.insert( promises, promise )
	end

	return WhenAllFinished( promises )
end
local function loadPersistent( )
	KLogf( 4, "[Pointshop2] Loading Module items" )
	Pointshop2Controller:getInstance( ):loadModuleItems( )
	:Done( function( )
		Pointshop2.LoadModuleItemsPromise:Resolve( )
		KLogf( 4, "[Pointshop2] Loaded Module items from DB" )
	end )
	:Fail( function( errid, err )
		Pointshop2.LoadModuleItemsPromise:Reject( errid, err )
		KLogf( 2, "[Pointshop2] Couldn't load persistent items: %i - %s", errid, err )
	end )
end
--When KInventory has loaded all item bases and the database has been connected we load persistent items
Pointshop2.FullyInitializedPromise:Done( function( )
	loadPersistent( )
end )

function Pointshop2Controller:updateItemPersistence( saveTable )
	local class = Pointshop2.GetItemClassByName( saveTable.baseClass )
	local outfitsChanged = saveTable.baseClass == "base_hat" and saveTable.outfitsChanged

	return class.getPersistence( ).findByItemPersistenceId( saveTable.persistenceId )
	:Then( function( persistentItem )
		-- Update cached copy for new players
		for k, v in pairs( self.cachedPersistentItems ) do
			if v.itemPersistenceId == saveTable.persistenceId then
				self.cachedPersistentItems[k] = persistentItem
			end
		end

		-- Update KInventory.Items entry
		Pointshop2.LoadPersistentItem( persistentItem )

		-- If outfits have changed reload & resend outfits
		if outfitsChanged then
			for k, v in pairs( player.GetAll( ) ) do
				v.outfitsReceivedPromise = Deferred( )
			end

			return self:loadOutfits( ):Then( function( )
				return persistentItem
			end )
		end

		return persistentItem
	end )
	:Then( function( persistentItem )
		-- Send info to players as soon as they received the outfits change
		if outfitsChanged then
			for k, v in pairs( player.GetAll( ) ) do
				v.outfitsReceivedPromise:Done(function( )
						self:startView( "Pointshop2View", "updateItemPersistence", v, persistentItem )
				end)
			end
		else
			self:startView( "Pointshop2View", "updateItemPersistence", player.GetAll(), persistentItem )
		end
	end )
end

function Pointshop2Controller:saveModuleItem( ply, saveTable )
	local class = Pointshop2.GetItemClassByName( saveTable.baseClass )
	if not class then
		KLogf( 3, "[Pointshop2] Couldn't save item %s: invalid baseclass", saveTable.name, saveTable.baseClass )
		return self:reportError( "Pointshop2View", ply, "Error saving item", 1, "Invalid Baseclass " .. saveTable.baseClass )
	end

	--If persistenceId != nil update existing
	local isUpdate = saveTable.persistenceId != nil
	class.getPersistence( ).createOrUpdateFromSaveTable( saveTable, isUpdate )
	:Then( function( saved )
		KLogf( 4, "[Pointshop2] Saved item %s", saveTable.name )
		-- Use shortcut path for updates, do a full reload on newly created items
		if isUpdate then
			return self:updateItemPersistence( saveTable )
		else
			return self:moduleItemsChanged( )
		end
	end, function( errid, err )
		self:reportError( "Pointshop2View", ply, "Error saving item", errid, err )
	end )
end

function Pointshop2Controller:moduleItemsChanged( outfitsChanged )
	for k, v in pairs( player.GetAll( ) ) do
		v.outfitsReceivedPromise = Deferred( )
	end

	return self:loadModuleItems( )
	:Then( function( )
		if outfitsChanged == false then
			return Promise.Resolve( )
		end
		return self:loadOutfits( )
	end )
	:Then( function( )
		return self:loadDynamicInfo( )
	end )
	:Done( function( )
		for k, v in pairs( player.GetAll( ) ) do
			Promise.Resolve( )
			:Then( function( )
				if outfitsChanged == false then
					return Promise.Resolve( )
				end
				return v.outfitsReceivedPromise
			end )
			:Done( function( )
				self:sendDynamicInfo( v )
			end )
		end
	end )
end

--Lookup table taken from adamburton/pointshop
local KeyToHook = {
	F1 = "ShowHelp",
	F2 = "ShowTeam",
	F3 = "ShowSpare1",
	F4 = "ShowSpare2",
	None = "ThisHookDoesNotExist"
}
function Pointshop2Controller:registerShopOpenHook( )
	for key, hookName in pairs( KeyToHook ) do
		hook.Remove( hookName, "PS2_MenuOpen" )
	end
	hook.Add( KeyToHook[Pointshop2.GetSetting( "Pointshop 2", "GUISettings.ShopKey" )], "PS2_MenuOpen", function( ply )
		self:startView( "Pointshop2View", "toggleMenu", ply )
	end )

	local ChatCommand = Pointshop2.GetSetting("Pointshop 2", "GUISettings.ShopChat")
	hook.Add( "PlayerSay", "PS2_MenuOpen", function( ply, msg )
		if string.len( ChatCommand ) > 0 then
			if string.sub( msg, 0, string.len( ChatCommand ) ) == ChatCommand then
				self:startView( "Pointshop2View", "toggleMenu", ply )
			end
		end
	end )
end
hook.Add( "PS2_OnSettingsUpdate", "ChangeKeyHook", function( )
	Pointshop2Controller:getInstance( ):registerShopOpenHook( )
end )
Pointshop2.SettingsLoadedPromise:Done( function( )
	Pointshop2Controller:getInstance( ):registerShopOpenHook( )
end )

function Pointshop2Controller:sendPoints( ply, targetPly, points )
	points = math.floor( points )

	if points < 0 then
		KLogf( 3, "Player %s tried to send negative points! Hacking attempt!", ply:Nick( ) )
		return
	end

	if points > ply.PS2_Wallet.points then
		KLogf( 3, "Player %s tried to send more points than he has! Hacking attempt!", ply:Nick( ) )
		return
	end

	if not LibK.isProperNumber( points ) then
	KLogf( 3, "Player %s tried to send nan/inf points!", ply:Nick( ) )
		return
	end

	if not IsValid( targetPly ) then
		--This could legitimately happen
		KLogf( 4, "Player %s tried to send points to an invalid player!", ply:Nick( ) )
		return
	end

	if Pointshop2.GetSetting( "Pointshop 2", "BasicSettings.SendPointsEnabled" ) == false then
		KLogf( 3, "Player %s tried to bypass disabled sendpoints, possible hacking attempt!" )
		return
	end

	self:updatePlayerWallet( ply.kPlayerId, "points", ply.PS2_Wallet.points - points )
	:Done( function( wallet )
		self:startView( "Pointshop2View", "walletChanged", self:getWalletChangeSubscribers( ply ), wallet )
	end )

	self:updatePlayerWallet( targetPly.kPlayerId, "points", targetPly.PS2_Wallet.points + points )
	:Done( function( wallet )
		self:startView( "Pointshop2View", "walletChanged", self:getWalletChangeSubscribers( targetPly ), wallet )
	end )

	--TODO: Send the targetPlayer a nice notification, similar to iten added
end

local function removeSingleItem( itemClass, refund )
	return Pointshop2.ItemMapping.removeWhere{ itemClass = itemClass.className }
	:Then( function( )
		return KInventory.Item.removeWhere{ itemclass = itemClass.name }
	end )
	:Then( function( )
		if itemClass:getPersistence( ).customRemove then
			return itemClass:getPersistence( ).customRemove( itemClass )
		end
		return Pointshop2.ItemPersistence.removeWhere{ id = itemClass.className }
	end )
end

function Pointshop2Controller:removeItem( ply, itemClassName, refund )
	local itemClass = Pointshop2.GetItemClassByName( itemClassName )
	if not itemClass then
		local def = Deferred( )
		def:Reject( "An item " .. itemClassName .. " doesn't exist!" )
		return def:Promise( )
	end

	return removeSingleItem( itemClass )
	:Then( function( )
		return self:moduleItemsChanged( )
	end )
	:Then( function( )
		reloadAllPlayers( )
	end )
end

function Pointshop2Controller:removeItems( ply, itemClassNames, refund )
	local promises = {}
	local removedClassNames = {}

	for k, itemClassName in pairs( itemClassNames ) do
		local promise = Promise.Resolve()
		:Then( function( )
			local itemClass = Pointshop2.GetItemClassByName( itemClassName )
			if not itemClass then
				return Promise.Reject( "An item " .. itemClassName .. " doesn't exist!" )
			end
			return itemClass
		end )
		:Then( function( itemClass )
			return removeSingleItem( itemClass, refund )
		end )
		:Then( function( )
			table.insert( removedClassNames, itemClassName )
		end )
		table.insert( promises, promise )
	end

	return WhenAllFinished( promises )
	:Then( function( )
		return self:moduleItemsChanged( )
	end )
	:Then( function( )
		reloadAllPlayers( )
	end )
	:Then( function( )
		return removedClassNames
	end )
end

function Pointshop2Controller:requestMaterials( ply, dir )
	local files, folders = file.Find( "materials/" .. dir .. "/*", "GAME" )
	return Promise.Resolve( files )
end

local function recurseFlatten( path, pathId, tab )
	tab = tab or {}
	local _, folders = file.Find( path .. "/*", pathId )
	local files = file.Find( path .. "/*.mdl", pathId )

	for k, v in pairs( files ) do
		table.insert( tab, path .. "/" .. v )
	end

	for k, v in pairs( folders ) do
		recurseFlatten( path .. "/" .. v, pathId, tab )
	end
	return tab
end

function Pointshop2Controller:generateModelCache( )
	KLogf( 5, "[Pointshop 2] Generating model cache..." )
	local startTime = SysTime( )

	self.gameModels = {}
	self.addonModels = {}

	local games = engine.GetGames()
	/*table.insert( games, {
		mounted = true,
		title = "Garry's Mod",
		folder = "garrysmod"
	} )*/
	for _, game in SortedPairsByMemberValue( games, "title" ) do
		if ( !game.mounted ) then continue end

		self.gameModels[game.title] = recurseFlatten( "models", game.folder )
	end

	for _, addon in SortedPairsByMemberValue( engine.GetAddons(), "title" ) do

		if ( !addon.downloaded || !addon.mounted ) then continue end
		if ( addon.models <= 0 ) then continue end

		self.addonModels[addon.title] = recurseFlatten( "models", addon.title )
	end
	local data = util.TableToJSON( { games = self.gameModels,	addons = self.addonModels, addonTbl = engine.GetAddons() } )
	KLogf( 5, "[Pointshop 2] Model cache created in %s", LibK.GLib.FormatDuration( SysTime() - startTime ) )

	local resource = LibK.GLib.Resources.RegisterData( "Pointshop2", "modelCache", data )
	resource:GetCompressedData( ) --Force compression now
end
Pointshop2Controller:getInstance( ):generateModelCache( )
