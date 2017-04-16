function Pointshop2Controller:isValidPurchase( ply, itemClassName )
	local itemClass = Pointshop2.GetItemClassByName( itemClassName )
	if not itemClass then
		return Promise.Reject( "Couldn't buy item, item " .. itemClassName .. " isn't valid" )
	end

	if itemClass.isBase then
		return Promise.Reject( "You can not buy a base" )
	end

	if not ply:PS2_HasInventorySpace( 1 ) then
		return Promise.Reject( "Inventory full" )
	end

	if table.HasValue( self.tree:getNotForSaleItemClassNames( ), itemClassName ) then
		return Promise.Reject( "This item cannot be bought" )
	end

	if not itemClass:PassesRankCheck( ply ) then
		return Promise.Reject( "You are not the correct rank to buy this item" )
	end

	return Promise.Resolve( )
end

function Pointshop2Controller:internalBuyItem( ply, itemClass, currencyType, price, suppressNotify )
	--[[
		Wrap everything into a blocking transaction to make sure we don't get duplicate stuff
		if mysql takes a little longer to respond and prevent any lua from queueing querys in
		between.
		TODO: look into alternative methods of locking the database as this is a bit performance heavy because it blocks the game thread,
	]]--
	LibK.SetBlocking( true )

	return Pointshop2.DB.DoQuery( "BEGIN" )
	:Then( function( )
		ply.PS2_Wallet[currencyType] = ply.PS2_Wallet[currencyType] - price
		return ply.PS2_Wallet:save( )
	end )
	:Then( function( )
		return self:easyAddItem( ply, itemClass.className, {
			time = os.time(),
			amount = price,
			currency = currencyType,
			origin = "SHOP"
		}, suppressNotify )
	end )
	:Then( function( item )
		Pointshop2.DB.DoQuery( "COMMIT" )
		LibK.SetBlocking( false )

		self:sendWallet( ply )
		return item
	end, function( errid, err )
		Pointshop2.DB.DoQuery( "ROLLBACK" )
		LibK.SetBlocking( false )
	end )
end

function Pointshop2Controller:buyItem( ply, itemClassName, currencyType )
	return self:isValidPurchase( ply, itemClassName )
	:Then( function( )
		local itemClass = Pointshop2.GetItemClassByName( itemClassName )

		local price = itemClass:GetBuyPrice( ply )
		if not price then
			KLogf( 3, "Player %s tried to buy item %s which cannot be bought! Hacking Attempt?", ply:Nick(), itemClass )
			return Promise.Reject( "Item %s cannot be bought!" )
		end

		if currencyType == "points" and price.points and ply.PS2_Wallet.points < price.points  or
		   currencyType == "premiumPoints" and price.premiumPoints and ply.PS2_Wallet.premiumPoints < price.premiumPoints
		then
			return Promise.Reject( "You cannot purchase this item (insufficient " .. currencyType .. ")" )
		end

		return self:internalBuyItem( ply, itemClass, currencyType, price[currencyType] )
	end )
	:Then( function( item )
		KLogf( 4, "Player %s purchased item %s", ply:Nick( ), itemClassName )
		hook.Run( "PS2_PurchasedItem", ply, itemClassName )
		return item
	end, function( errid, err )
		KLogf( 2, "Error saving item purchase: %s", err or errid )
		return Promise.Reject( "A technical error occured (2), your purchase was not carried out. " .. ( err or errid or "" ) )
	end )
end

function Pointshop2Controller:easyAddItem( ply, itemClassName, purchaseData, suppressNotify )
	local itemClass = Pointshop2.GetItemClassByName( itemClassName )
	return Promise.Resolve()
	:Then( function( )
		if not itemClass then
			return Promise.Reject( "Item class " .. tostring( itemClassName ) .. " is not valid!" )
		end

		local item = itemClass:new( )
		local price = itemClass.Price
		local currencyType, amount
		if price.points then
			currencyType = "points"
			amount = price.points
		elseif price.premiumPoints then
			currencyType = "premiumPoints"
			amount = price.premiumPoints
		else
			currencyType = "points"
			amount = 0
		end
		item.purchaseData = purchaseData or {
			time = os.time(),
			amount = amount,
			currency = currencyType,
			origin = "LUA"
		}
		return item:save( )
	end )
	:Then( function( item )
		KInventory.ITEMS[item.id] = item
		return ply.PS2_Inventory:addItem( item )
		:Then( function( )
			item:OnPurchased( )
			if not suppressNotify then
				self:startView( "Pointshop2View", "displayItemAddedNotify", ply, item )
			end
			return item
		end )
	end )
end

function Pointshop2Controller:sellItem( ply, itemId )
	local transactionDef = Deferred( )

	LibK.SetBlocking( true )
	Pointshop2.DB.DoQuery( "BEGIN" )
	:Fail( function( errid, err )
		KLogf( 2, "Error starting transaction: %s", err )

		transactionDef:Reject( 0, "A Technical error occured(1), your sale was not carried out." )
		return transactionDef:Promise()
	end )


	local item = KInventory.ITEMS[itemId]
	if not item then
		KLogf( 3, "[WARN] Player %s tried to sell an item that wasn't cached (id %i)", ply:Nick( ), itemId )
		return Promise.Reject( 0, "Invalid Data" )
	end

	if not item:CanBeSold( ) then
		KLogf( 3, "[WARN] Player %s tried to sell not sellable item %i", ply:Nick( ), itemId )
		return Promise.Reject( 0, "Invalid Data" )
	end

	if not Pointshop2.PlayerOwnsItem( ply, item ) then
		transactionDef:Reject( 0, "Couldn't sell item: You don't own this item." )
		return transactionDef:Promise( )
	end

	local slot
	for k, v in pairs( ply.PS2_Slots ) do
		if v.itemId == item.id then
			slot = v
		end
	end

	local def
	if ply.PS2_Inventory:containsItem( item ) then
		def = ply.PS2_Inventory:removeItem( item ) --Unlink from inventory
	elseif slot then
		def = slot:removeItem( item ):Then( function( )
			self:startView( "Pointshop2View", "slotChanged", ply, slot )
		end )
	end

	def:Then( function( )
		self:startView( "Pointshop2View", "playerUnequipItem", player.GetAll( ), ply, item.id )
		item:OnHolster( )
		item:OnSold( )
		local amount, currencyType = item:GetSellPrice( )
		ply.PS2_Wallet[currencyType] = ply.PS2_Wallet[currencyType] + amount
		return ply.PS2_Wallet:save( )
	end )
	:Then( function( )
		KInventory.ITEMS[item.id] = nil
		return item:remove( ) --remove the actual db entry
	end )
	:Then( function( )
		KLogf( 4, "Player %s sold an item", ply:Nick( ) )
		hook.Run( "PS2_SoldItem", ply )

		Pointshop2.DB.DoQuery( "COMMIT" )
		LibK.SetBlocking( false )
		self:sendWallet( ply )

		transactionDef:Resolve( )
	end, function( errid, err )
		KLogf( 2, "Error selling item: %s", err )
		Pointshop2.DB.DoQuery( "ROLLBACK" )
		LibK.SetBlocking( false )

		transactionDef:Reject( errid, "A technical error occured (2), your sale was not carried out." )
	end )

	return transactionDef:Promise( )
end

--Remove Item, clear inventory references etc.
function Pointshop2Controller:removeItemFromPlayer( ply, item )
	local slot
	for k, v in pairs( ply.PS2_Slots ) do
		if v.itemId == item.id then
			slot = v
		end
	end

	return Promise.Resolve( )
	:Then( function( )
		if ply.PS2_Inventory:containsItem( item ) then
			return ply.PS2_Inventory:removeItem( item ) --Unlink from inventory
		elseif slot then
			return slot:removeItem( item ):Then( function( )
				self:startView( "Pointshop2View", "slotChanged", ply, slot )
			end )
		end
	end )
	:Then( function( )
		item:OnHolster( )
		self:startView( "Pointshop2View", "playerUnequipItem", player.GetAll( ), ply, item.id )
		KInventory.ITEMS[item.id] = nil
		return item:remove( ) --remove the actual db entry
	end )
end

function Pointshop2Controller:adminRemoveItem(ply, itemId)
	local item = KInventory.ITEMS[itemId]
	if not item then
		return Promise.Reject("Invalid Item")
	end

	return self:removeItemFromPlayer(ply, item)
end

function Pointshop2Controller:unequipItem( ply, slotName )
	local slot
	for k, v in pairs( ply.PS2_Slots ) do
		if v.slotName == slotName then
			slot = v
		end
	end

	if not slot then
		KLogf( 3, "[ERROR] Player %s tried to unequipItem from uncached slot %s", ply:Nick( ), slotName )
		self:startView( "Pointshop2View", "displayError", ply, "Could not unequip item, " .. slotName .. " is not a valid equipment slot." )
		return
	end

	if not slot.itemId then
		KLogf( 3, "[ERROR] Player %s tried to unequipItem empty slot %s", ply:Nick( ), slotName )
		self:startView( "Pointshop2View", "displayError", ply, "Could not unequip item, " .. slotName .. " is empty!" )
		return
	end

	local item = KInventory.ITEMS[slot.itemId]
	if not item then
		KLogf( 3, "[ERROR] Player %s tried to unequip an uncached Item %i", ply:Nick( ), slot.itemId )
		self:startView( "Pointshop2View", "displayError", ply, "Could not unequip item, Item not found in cache" )
		return
	end

	LibK.SetBlocking( true )
	Pointshop2.DB.DoQuery( "BEGIN" )

	return ply.PS2_Inventory:addItem( item )
	:Then( function( )
		slot.itemId = nil
		slot.Item = nil
		return slot:save( )
	end )
	:Then( function( updatedSlot )
		item:OnHolster( ply )
		hook.Run( "PS2_UnEquipItem", ply, item.id )

		self:startView( "Pointshop2View", "playerUnequipItem", player.GetAll( ), ply, item.id )
		self:startView( "Pointshop2View", "slotChanged", ply, updatedSlot )

		Pointshop2.DB.DoQuery( "COMMIT" )
		LibK.SetBlocking( false )
	end, function( errid, err )
		self:reportError( "Pointshop2View", ply, "Error unequipping item", errid, err )

		Pointshop2.DB.DoQuery( "ROLLBACK" )
		LibK.SetBlocking( false )
	end )
end

function Pointshop2Controller:equipItem( ply, itemId, slotName )
	if not Pointshop2.IsValidEquipmentSlot( slotName ) then
		self:startView( "Pointshop2View", "displayError", ply, "Could not equip item, " .. slotName .. " is not a valid equipment slot." )
		KLogf( 3, "[Pointshop2][WARN] Player %s tried to equip item into invalid slot %s", ply:Nick( ), slotName )
		return
	end

	local item = KInventory.ITEMS[itemId]
	if not item then
		KLogf( 3, "[Pointshop2][WARN] Player %s tried to equip uncached item %i", ply:Nick( ), itemId )
		self:startView( "Pointshop2View", "displayError", ply, "Could not equip item: Item couldn't be found." )
		return
	end

	if not Pointshop2.PlayerOwnsItem( ply, item ) then
		KLogf( 3, "[Pointshop2][WARN] Player %s tried to equip foreign owned item %i", ply:Nick( ), itemId )
		self:startView( "Pointshop2View", "displayError", ply, "Could not equip item: You don't own this item." )
		return
	end

	if not Pointshop2.IsItemValidForSlot( item, slotName ) then
		KLogf( 3, "[Pointshop2][WARN] Player %s tried to equip item %i into slot %s (not valid for slot)", ply:Nick( ), itemId, slotName )
		self:startView( "Pointshop2View", "displayError", ply, "Could not equip item: You can't put it into this slot." )
		return
	end

	LibK.SetBlocking( true )
	Pointshop2.DB.DoQuery( "BEGIN" )
	local slot
	local slotsused = 1
	for k, v in pairs( ply.PS2_Slots ) do
		if v.slotName == slotName then
			slot = v
		end
		if v.itemId then
			slotsused = slotsused + 1
		end
	end

	if not slot then
		slot = Pointshop2.EquipmentSlot:new( )
		slot.ownerId = ply.kPlayerId
		slot.slotName = slotName
		slot:save( )
		ply.PS2_Slots[slot.id] = slot
	end


	local moveOldItemDef = Deferred( )
	if slot.itemId then
		local oldItem = KInventory.ITEMS[slot.itemId]
		if not oldItem then
			KLogf( 2, "[ERROR] Unsynced item %i in slot %s", slot.itemId, slot.slotName )
		end

		ply.PS2_Inventory:addItem( oldItem )
		:Then( function( )
			moveOldItemDef:Resolve( )
			oldItem:OnHolster( ply )
			self:startView( "Pointshop2View", "playerUnequipItem", player.GetAll( ), ply, oldItem.id )
			slot.Item = nil
			slot.itemId = nil
			hook.Run( "PS2_SlotChanged", ply, slot, nil )
		end, function( errid, err )
			moveOldItemDef:Reject( errid, err )
		end )
	else
		moveOldItemDef:Resolve( )
	end

	moveOldItemDef:Then( function( )
		slot.itemId = item.id
		slot.Item = item
		self:startView( "Pointshop2View", "slotChanged", ply, slot )
		hook.Run( "PS2_SlotChanged", ply, slot, item )
		return slot:save( )
	end )
	:Then( function( slot )
		return ply.PS2_Inventory:removeItem( item ) --unlink from inventory
	end )
	:Done( function( )
		item.owner = ply
		if not IsValid( item:GetOwner() ) then
			debug.Trace( )
			print( "Error in 0" )
		end

		slot.Item = item
		slot.itemId = item.id

		--Delay to next frame to clear stack
		timer.Simple( 0, function( )
			if item.class:IsValidForServer( Pointshop2.GetCurrentServerId( ) ) then
				item:OnEquip(  )
				hook.Run( "PS2_EquipItem", ply, item.id, slotsused )
				self:startView( "Pointshop2View", "playerEquipItem", player.GetAll( ), ply.kPlayerId, item )
			end
		end )

		Pointshop2.DB.DoQuery( "COMMIT" )
		LibK.SetBlocking( false )
	end )
	:Fail( function( errid, err )
		self:reportError( "Pointshop2View", ply, "Error equipping item", errid, err )

		Pointshop2.DB.DoQuery( "ROLLBACK" )
		LibK.SetBlocking( false )
	end )
end

Pointshop2.DlcPacks = {}

function Pointshop2.RegisterDlcPack( name, items, categories )
	Pointshop2.DlcPacks[name] = { items = items, categories = categories }
end

function Pointshop2Controller:installDlcPack( ply, name )
	local pack = Pointshop2.DlcPacks[name]
	if not pack then
		KLogf( 2, "Trying to install invalid DLC pack " .. name .. "!" )
		return
	end

	Promise.Resolve( )
	:Then( function( )
		return self:importItems( pack.items )
	end )
	:Then( function( )
		return self:importCategoryOrganization( pack.categories )
	end )
	:Done( function( )
		return self:moduleItemsChanged( )
	end )
end
