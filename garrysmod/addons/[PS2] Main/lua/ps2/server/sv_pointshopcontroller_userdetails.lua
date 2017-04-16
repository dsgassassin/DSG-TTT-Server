function Pointshop2Controller:searchPlayers( ply, subject, attribute )
	local attributeTranslate = { ["Name"] = "name", ["Steam ID"] = "player", ["Profile ID"] = "steam64" }
	if not attributeTranslate[attribute] then
		local def = Deferred( )
		def:Reject( "Invalid attribute " .. attribute )
		return def:Promise( )
	end


	return LibK.Player.findPlayers( subject, attributeTranslate[attribute] )
	:Then( function( players )
		local ids = {}
		local playerNames = {}
		for k, v in pairs( players ) do
			table.insert( ids, tonumber( v.id ) )
			table.insert( playerNames, { id = v.id, name = v.name, lastConnected = v.updated_at } )
		end

		local def = Deferred( )

		if #ids == 0 then
			def:Resolve( {} )
			return def:Promise( )
		end

		Pointshop2.Wallet.getDbEntries( "WHERE ownerId IN (" .. table.concat( ids, ', ' ) .. ")" )
		:Done( function( wallets )
			for k, v in pairs( playerNames ) do
				for _, wallet in pairs( wallets ) do
					if wallet.ownerId == v.id then
						v.Wallet = wallet
					end
				end
			end
			def:Resolve( playerNames )
		end )
		:Fail( function( errid, err )
			def:Fail( 1, "Error fetching wallets: " .. err )
		end	)

		return def:Promise( )
	end )
end

function Pointshop2Controller:getUserDetails( ply, kPlayerId )
	local def = Deferred( )

	WhenAllFinished{ LibK.Player.findById( kPlayerId ),
					 Pointshop2.Wallet.findByOwnerId( kPlayerId ),
					 KInventory.Inventory.findByOwnerId( kPlayerId )
	}:Then( function( dbPlayer, wallet, inventory )
		dbPlayer.wallet = wallet
		dbPlayer.inventory = inventory
		if not wallet or not inventory then
			local def = Deferred( )
			def:Reject( 1, "Player is not a Pointshop2 User" )
			return def:Promise( )
		end
		return inventory:loadItems( )
		:Then( function( )
			return dbPlayer
		end )
	end )
	:Done( function( plyInfo )
		def:Resolve( plyInfo )
	end )
	:Fail( function( errid, err )
		def:Reject( errid, err )
	end )

	return def:Promise( )
end

function Pointshop2Controller:updatePlayerWallet( kPlayerId, currencyType, newValue )
	if not table.HasValue( { "points", "premiumPoints" }, currencyType ) then
		local def = Deferred( )
		def:Reject( 0, "Invalid currency type " .. currencyType )
		return def:Promise( )
	end

	if not LibK.isProperNumber( newValue ) then
		return Promise.Reject( 0, "Improper number passed" )
	end

	local walletPromise = Deferred( )
	local walletFound = false
	local shouldBlock = Pointshop2.GetSetting( "Pointshop 2", "AdvancedSettings.ShouldBlock" )
	for k, v in pairs( player.GetAll( ) ) do
		if v.kPlayerId == kPlayerId then
			if v.PS2_Wallet then
				walletPromise:Resolve( v.PS2_Wallet )
				walletFound = true
			end
		end
	end

	if not walletFound then
		Pointshop2.Wallet.findByOwnerId( kPlayerId )
		:Done( function( wallet )
			walletPromise:Resolve( wallet )
		end )
		:Fail( function( errid, err )
			walletPromise:Reject( errid, err )
		end )
	end

	if walletFound and shouldBlock then --no need to block if player is offline
		Pointshop2.DB:SetBlocking( true ) --don't want player to sell/buy stuff during our update
	end

	newValue = tonumber( newValue )
	return walletPromise:Then( function( wallet )
		wallet[currencyType] = newValue
		return wallet:save( )
	end )
	:Always( function( )
		if walletFound and shouldBlock then
			Pointshop2.DB:SetBlocking( false )
		end
	end )
end

function Pointshop2Controller:adminChangeWallet( ply, kPlayerId, currencyType, newValue )
	return self:updatePlayerWallet( kPlayerId, currencyType, newValue )
	:Done( function( wallet )
		self:broadcastWalletChanges( wallet )
	end )
end

function Pointshop2Controller:addPointsBySteamId( steamId, currencyType, amount )
	-- Player is online do standard stuff
	for k, v in pairs( player.GetAll( ) ) do
		if v:SteamID( ) == steamId and v.PS2_Wallet then
			return self:addToPlayerWallet( v, currencyType, amount )
		end
	end

	return LibK.Player.findByPlayer( steamId )
	:Then( function( ply )
		-- Player may or may not be in DB, create if not
		if not ply then
			ply = LibK.Player:new( )
			ply.name = "Unknown"
			ply.player = steamId
			ply.steam64 = util.SteamIDTo64( steamId )
			ply.uid = util.CRC( "gm_" .. steamId .. "_gm" )
			return ply:save( )
		end
		return ply
	end )
	:Then( function( ply )
		return WhenAllFinished{ Pointshop2.Wallet.findByOwnerId( ply.id ), Promise.Resolve( ply ) }
	end )
	:Then( function( wallet, kPlayer  )
		-- Player might not have a PS2 Wallet yet, create it if he does not
		if not wallet then
			local wallet = Pointshop2.Wallet:new( )
			wallet.points = Pointshop2.GetSetting( "Pointshop 2", "BasicSettings.DefaultWallet.Points" )
			wallet.premiumPoints = Pointshop2.GetSetting( "Pointshop 2", "BasicSettings.DefaultWallet.PremiumPoints" )
			wallet.ownerId = kPlayer.id
			return wallet:save( )
		end
		return wallet
	end )
	:Then( function( wallet )
		if not table.HasValue( { "points", "premiumPoints" }, currencyType ) then
			return Promise.Reject( 1, "Invalid Currency " .. tostring( currencyType ) )
		end

		wallet[currencyType] = wallet[currencyType] + amount
		return wallet:save( )
	end )
end

function Pointshop2Controller:adminGiveItem( ply, kPlayerId, itemClassName )
	local itemClass = Pointshop2.GetItemClassByName( itemClassName )

	if not itemClass then
		return Promise.Reject( "Invalid item class " .. itemClassName )
	end

	local ply
	for k, v in pairs( player.GetAll( ) ) do
		if v.kPlayerId == kPlayerId then
			ply = v
		end
	end

	return Promise.Resolve()
	:Then( function( )
		local item = itemClass:new( )
		item.purchaseData = purchaseData or {
			time = os.time(),
			amount = 0,
			currency = "points",
			origin = "admin"
		}
		return item:save( )
	end )
	:Then( function( item )
		KInventory.ITEMS[item.id] = item

		if IsValid( ply ) then
			return WhenAllFinished{ ply.outfitsReceivedPromise:Promise( ), ply.dynamicsReceivedPromise:Promise( ) }
			:Then( function( )
				return ply.PS2_Inventory, item
			end )
		else
			return KInventory.Inventory.findByOwnerId( kPlayerId ), item
		end
	end )
	:Then( function( inventory, item )
		if not inventory then
			return Promise.Reject( "The player has not used pointshop 2 yet. Could not give item." )
		end
		return inventory:addItem( item ), item
	end )
	:Then( function( inventory, item )
		if IsValid( ply ) then
			self:startView( "Pointshop2View", "displayItemAddedNotify", ply, item )
		end
		KLogf( 4, "Admin %s gave %s %s", ply:Nick( ), ply and ply:Nick( ) or kPlayerId, item:GetPrintName( ) )
	end )
end
