--Pointshop trading shared functions

function TRADING.PlayerHasItem(ply, itemid)
	if PS then return ply:PS_HasItem(itemid)
	else
		local items = ply.PS2_Inventory:getItems()
		for k,v in pairs(items) do
			if (v.id == tonumber(itemid)) then return true end
		end
		return false
	end
end

function TRADING.GetPlayerPoints(ply)
	return PS and ply:PS_GetPoints() or ply:PS2_GetWallet().points
end

function TRADING.GetPlayerItem(ply, itemid)
	local items = ply.PS2_Inventory:getItems()
	for k,v in pairs(items) do
		if (v.id == tonumber(itemid)) then return v end
	end
end

function TRADING.PlayerHasPoints(ply, points)
	if (points <= 0) then return true end
	if PS then return ply:PS_HasPoints(points)
	elseif Pointshop2 then return (ply:PS2_GetWallet().points >= points) end
end

function TRADING.AddPlayerItem(ply, itemid)
	if PS then
		ply:PS_GiveItem(itemid)
	else
		Pointshop2Controller:getInstance():easyAddItem( ply, itemid, nil, true )
	end
end

function TRADING.RemovePlayerItem(ply, itemid)
	if PS then
		ply:PS_TakeItem(itemid)
	else
		local item = TRADING.GetPlayerItem(ply, itemid)
		if not item then return end
		local def 
		if ply.PS2_Inventory:containsItem( item ) then
			def = ply.PS2_Inventory:removeItem( item ) --Unlink from inventory
		end
		
		def:Then( function( )
			item:OnHolster( )
			item:OnSold( ) //Should we run this?
		end )
		:Then( function( ) 
			KInventory.ITEMS[item.id] = nil
			return item:remove( ) --remove the actual db entry
		end )		
	end
end

function TRADING.AddPlayerPoints(ply, points)
	if PS then ply:PS_GivePoints(points)
	else ply:PS2_AddStandardPoints( points, false, false, true ) end
end

function TRADING.RemovePlayerPoints(ply, points)
	if PS then ply:PS_TakePoints(points)
	else ply:PS2_AddStandardPoints( -points, false, false, true ) end
end

function TRADING.PlayerIsTradingItem(ply, itemid)
	if CLIENT then
		return TradingWindow and TradingWindow.YourOffer:HasItem(itemid)
	else
		return ply.TradeOffer and table.HasValue(ply.TradeOffer, itemid)
	end
end

function TRADING.ItemsInTrade(ply, tradeply)
	if CLIENT then
		return TradingWindow and (TradingWindow.YourOffer:HasItems(true) or TradingWindow.TheirOffer:HasItems(true))
	else
		if not ply.TradeOffer or not tradeply.TradeOffer then return false end
		if ply.TradeOfferPoints or tradeply.TradeOfferPoints then return true
		elseif (#(ply.TradeOffer) >= 1) or (#(tradeply.TradeOffer) >= 1) then return true
		else return false end	
	end
end

function TRADING.GetCategoryColor(category, name)
	if PS then
		if name then category = TRADING.FindCategoryIDByName(category) end
		return PS.Categories[category].Color
	else
		return TRADING.Theme.OutlineColor
	end
end

function TRADING.FindCategoryIDByName(name)
	if PS then
		for k,v in pairs(PS.Categories) do
			if (v.Name == name) then return k end
		end
	else
		return Pointshop2.GetCategoryByName(name).id
	end
end

function TRADING.FindCategoryNameByID(id)
	local categories
	if CLIENT then
		categories = Pointshop2View:getInstance( ).itemCategories
	else
		categories = Pointshop2Controller:getInstance( ).itemCategories
	end
	
	if (id == -1) then return "Uncategorized Items" end
	
	for k,v in pairs(categories) do
		if (v.id == id) then return v.label end
	end
end

function TRADING.CanOfferItem(ply, itemid, points)
	if points then return true end

	local item = TRADING.GetItemData(itemid, ply)
	
	if not item then return false end //Item is invalid
	
	if TRADING.Settings.ExcludeCategories and table.HasValue(TRADING.Settings.ExcludeCategories, 
	PS and TRADING.FindCategoryIDByName(TRADING.GetItemCategory(item)) or TRADING.FindCategoryNameByID(TRADING.GetItemCategory(item))) then
		return false
	end
	
	if TRADING.Settings.ExcludeItems and table.HasValue(TRADING.Settings.ExcludeItems, PS and itemid or item:GetPrintName()) then
		return false
	end
	
	if Pointshop2 then
		//We can't check this because it doesn't return true when not implemented
		//if not item:CanBeTraded(ply.TradingWith) then return false, TRADING.Settings.PS2ItemCantBeTraded end
		local slotsneeded = (#ply.TradeOffer - #ply.TradingWith.TradeOffer)
		if not ply.TradingWith:PS2_HasInventorySpace(slotsneeded) then return false,string.format(TRADING.Settings.PS2InventorySlotsFull,ply.TradingWith:Nick()) end
		local slot
		for k, v in pairs( ply.PS2_Slots ) do
			if v.itemId == item.id then
				return false
			end
		end
	end	
	
	if TRADING.Settings.CustomCanTradeFunction then
		local cantrade,message = TRADING.Settings.CustomCanTradeFunction(ply,ply.TradingWith,TRADING.GetItemData(itemid, ply))
		if not cantrade then return false,message end
	end
	
	return true
end

function TRADING.GetItemData(itemid, ply)
	if PS then return PS.Items[itemid]
	else
		if ply then
			local items = ply.PS2_Inventory:getItems()
			for k,v in pairs(items) do
				if (v.id == tonumber(itemid)) then return v end
			end
		else
			return Pointshop2.GetItemClassByName(itemid)
		end
	end
end

local rootid,notforsaleid,categories,mappings
function TRADING.GetItemCategory(item, truecategory)
	if PS then return item.Category
	else

		//Find root category ID
		if not rootid then rootid = Pointshop2.GetCategoryByName("Shop Categories").id end
		if not notforsaleid then notforsaleid = Pointshop2.GetCategoryByName("Not for sale Items").id end
		local itemid = item.class.className
		
		if not categories or not mappings then
			if CLIENT then
				categories, mappings = Pointshop2View:getInstance( ).itemCategories, Pointshop2View:getInstance( ).itemMappings
			else
				categories, mappings = Pointshop2Controller:getInstance( ).itemCategories, Pointshop2Controller:getInstance( ).itemMappings
			end
		end
		
		local categoryid
		for k,v in pairs(mappings) do
			if (v.itemClass == itemid) then categoryid = v.categoryId end
		end
		if truecategory then return categoryid end
		
		local function RecursiveCategoryMatch(id, rootid, notforsaleid)
			for k,v in pairs(categories) do
				if (v.id == id) then
					if (v.parent == rootid or v.parent == notforsaleid) then return v.id
					else 
						return RecursiveCategoryMatch(v.parent, rootid, notforsaleid) 
					end
				end
			end
		end
		
		local firstparentid = RecursiveCategoryMatch(categoryid, rootid, notforsaleid )
		
		return firstparentid or -1
	end
end

function TRADING.GetPointsName()
	return PS and PS.Config.PointsName or "Points"
end