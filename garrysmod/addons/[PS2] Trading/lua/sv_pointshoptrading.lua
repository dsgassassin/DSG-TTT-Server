--Pointshop Trading System Server Dist
if TRADING then TRADING = TRADING
else TRADING = {} end
include('sh_tradingconfig.lua')
include('sh_pointshoptrading.lua')
util.AddNetworkString("TradingNotification")
util.AddNetworkString("TradingStart")
util.AddNetworkString("TradingFinish")
util.AddNetworkString("TradingChat")
util.AddNetworkString("TradingOfferItem")
util.AddNetworkString("TradingStatus")
if TRADING.Settings.CanTradePoints then util.AddNetworkString("TradingOfferPoints") end

function TRADING.PlayerSay( ply, chattext, teamc )
	for k,v in pairs(TRADING.ChatCommands) do
		if (string.sub(string.lower(chattext), 1, #v) == string.lower(v)) then
			//Send invite
			local tradeply = TRADING.FindPlayer(string.lower(string.Trim(string.sub( chattext, #v + 1, #chattext ))))
			//Open selection menu
			if tradeply and not (tradeply == ply) then
				TRADING.SendTradeRequest(ply, tradeply)
			else
				SendUserMessage("TradingSelection",ply)
			end
			return ""
		end
	end
end

function TRADING.SendTradeRequest(ply, tradeply)
	if not PS and not Pointshop2 then return end
	if not IsValid(ply) or not IsValid(tradeply) or ply.TradingWith then return end
	if ply.NextTradeRequest and (CurTime() < ply.NextTradeRequest) then
		TRADING.SendNotification(TRADING.Settings.CantSendNotification, 1, ply)
		return
	end
	
	if TRADING.Settings.CustomCanTradeFunction and not TRADING.Settings.CustomCanTradeFunction(ply, tradeply) then
		local cantrade,message = TRADING.Settings.CustomCanTradeFunction(ply, tradeply)
		TRADING.SendNotification(message, 1, ply)
		return
	end
	ply.NextTradeRequest = (CurTime() + (TRADING.Settings.TradeRequestCooldown or 15))
	ply.TradeRequest = tradeply
	//tradeply.LastTradeRequest = ply
	//Trade request notification
	TRADING.SendNotification(string.format(TRADING.Settings.TradeRequestMessage, ply:Nick()), 3, tradeply, ply)
	
	//Trade request sent notification
	TRADING.SendNotification(string.format(TRADING.Settings.TradeRequestSentMessage, tradeply:Nick()), 2, ply)
end

function TRADING.FindPlayer(name)
	if not name or (name=="") then return end
	for k,v in pairs(player.GetAll()) do
		if (string.find(v:Name():lower(),name:lower(),1,true)) then
			return v
		end
	end
end

function TRADING.FindPlayerByUserID(id)
	id = tonumber(id)
	for k,v in pairs(player.GetAll()) do
		if (v:UserID() == id) then
			return v
		end
	end	
end

if TRADING.ChatCommands and TRADING.ChatCommands != "" then
	hook.Add( "PlayerSay", "TradingChatCommand", TRADING.PlayerSay )
end

function TRADING.TradeRequest(ply, cmd, args)
	if not args then return end
	local tradeply = TRADING.FindPlayerByUserID(args[1])

	if not tradeply then TRADING.SendNotification(TRADING.Settings.ErrorNotification, 1, ply) return end	
	TRADING.SendTradeRequest(ply, tradeply)
end
concommand.Add("_TradeRequest",TRADING.TradeRequest)

function TRADING.AcceptTradeRequest(ply, cmd, args)
	if not args or ply.TradingWith then return end
	local tradeply = TRADING.FindPlayerByUserID(args[1])
	
	if tradeply and (tradeply.TradeRequest == ply) and not tradeply.TradingWith then
		tradeply.TradeRequest = nil
		TRADING.StartTrading(ply, tradeply)
	else TRADING.SendNotification(TRADING.Settings.ErrorNotification, 1, ply) end
end
concommand.Add("_AcceptTradeRequest",TRADING.AcceptTradeRequest)

function TRADING.StartTrading(ply, tradeply, debugmode)
	if not PS and not Pointshop2 then return end
	if not IsValid(ply) or not IsValid(tradeply) or (not debugmode and ply == tradeply) then return end
	ply.TradingWith = tradeply
	tradeply.TradingWith = ply
	
	ply.TradeOffer = {}
	tradeply.TradeOffer = {}
	ply.TradeOfferPoints = nil
	tradeply.TradeOfferPoints = nil
	ply.TradeReady = nil
	tradeply.TradeReady = nil
	net.Start("TradingStart")
		net.WriteEntity(tradeply)
	net.Send(ply)
	net.Start("TradingStart")
		net.WriteEntity(ply)
	net.Send(tradeply)
end

function TRADING.OfferTradeItem(ply, cmd, args)
	if not args or not IsValid(ply.TradingWith) or ply.TradeReady then return end
	
	local itemid = args[1]
	if not itemid or TRADING.PlayerIsTradingItem(ply, itemid) then return end
	local canoffer,message = TRADING.CanOfferItem(ply, itemid)
	if not canoffer then if message then TRADING.SendNotification(message, 1, ply) end return end
	
	table.insert(ply.TradeOffer, itemid)
	TRADING.UpdateReadyStatus(ply.TradingWith, false)
	net.Start("TradingOfferItem")
		net.WriteString(itemid)
		net.WriteBool(true)
		net.WriteBool(true)
	net.Send(ply)
	
	net.Start("TradingOfferItem")
		net.WriteString(PS and itemid or string.format("%s;%s",itemid,TRADING.GetItemData(itemid, ply).class.className))
		net.WriteBool(true)
		net.WriteBool(false)
	net.Send(ply.TradingWith)
end
concommand.Add("_OfferTradeItem",TRADING.OfferTradeItem)

function TRADING.OfferTradePoints(ply, cmd, args)
	if not args or not IsValid(ply.TradingWith) or not TRADING.Settings.CanTradePoints then return end
	
	local points = tonumber(args[1])
	local oldpoints = ply.TradeOfferPoints
	local removepoints

	if ply.TradeOfferPoints and points and (points <= 0) then
		removepoints = true
	elseif not points or (points < 1) or ply.TradeOfferPoints or not TRADING.CanOfferItem(ply, "", true)
	or not TRADING.PlayerHasPoints(ply, points) then return end

	ply.TradeOfferPoints = points
	if removepoints then 
		ply.TradeOfferPoints = nil
		if not TRADING.ItemsInTrade(ply, ply.TradingWith) then
			TRADING.UpdateReadyStatus(ply, false)
			TRADING.UpdateReadyStatus(ply.TradingWith, false)
		end
	end
	TRADING.UpdateReadyStatus(ply.TradingWith, false)
	if ply.TradeReady then ply.TradeReady = false end //We're allowed to remove even when ready
	
	net.Start("TradingOfferPoints")
		net.WriteUInt(oldpoints or points, 32)
		net.WriteBool(true)
		net.WriteBool(removepoints)
	net.Send(ply)
	
	net.Start("TradingOfferPoints")
		net.WriteUInt(oldpoints or points, 32)
		net.WriteBool(false)
		net.WriteBool(removepoints)
	net.Send(ply.TradingWith)
end
concommand.Add("_OfferTradePoints",TRADING.OfferTradePoints)

function TRADING.RemoveOfferTradeItem(ply, cmd, args)
	if not args or not IsValid(ply.TradingWith) then return end
	
	local itemid = args[1]
	if not itemid or not TRADING.PlayerIsTradingItem(ply, itemid) then return end
	
	table.RemoveByValue(ply.TradeOffer, itemid)
	if not TRADING.ItemsInTrade(ply, ply.TradingWith) then
		TRADING.UpdateReadyStatus(ply, false)
		TRADING.UpdateReadyStatus(ply.TradingWith, false)
	end
	TRADING.UpdateReadyStatus(ply.TradingWith, false)
	if ply.TradeReady then ply.TradeReady = false end //We're allowed to remove even when ready

	net.Start("TradingOfferItem")
		net.WriteString(itemid)
		net.WriteBool(false)
		net.WriteBool(true)
	net.Send(ply)
	
	net.Start("TradingOfferItem")
		net.WriteString(PS and itemid or string.format("%s;%s",itemid,TRADING.GetItemData(itemid, ply).class.className))
		net.WriteBool(false)
		net.WriteBool(false)
	net.Send(ply.TradingWith)
end
concommand.Add("_RemoveOfferTradeItem",TRADING.RemoveOfferTradeItem)

function TRADING.TradeChatMessage(ply, cmd, args)
	if not ply.TradingWith or (ply.NextTradeChat and (CurTime() < ply.NextTradeChat))  then return end
	ply.NextTradeChat  = CurTime() + 2
	local chatstr = ""
	for k,v in ipairs(args) do
		chatstr = chatstr..v
	end
	chatstr = string.Trim(chatstr)
	if (chatstr == "") then return end
	
	net.Start("TradingChat")
		net.WriteString(chatstr)
		net.WriteEntity(ply)
	net.Send({ply, ply.TradingWith})
end
concommand.Add("_TradeChatMessage",TRADING.TradeChatMessage)

function TRADING.UpdateReadyStatus(ply, ready)
	if (ply.TradeReady == ready) then return end
	ply.TradeReady = ready
	
	//Update partner
	if IsValid(ply.TradingWith) then
	net.Start("TradingStatus")
		net.WriteBool(ready) //Ready?
	net.Send(ply.TradingWith)
	end
end

function TRADING.ChangeReadyStatus(ply, cmd, args)
	if not args or not IsValid(ply.TradingWith) then return end
	local ready = tobool(args[1])
	if ready and not TRADING.ItemsInTrade(ply, ply.TradingWith) then return end

	ply.TradeConfirmed = false
	ply.TradingWith.TradeConfirmed = false
	TRADING.UpdateReadyStatus(ply, ready)
end
concommand.Add("_ChangeTradeReadyStatus",TRADING.ChangeReadyStatus)

function TRADING.ConfirmTrade(ply, cmd, args)
	if ply.TradeConfirmed or not IsValid(ply.TradingWith) or not ply.TradeReady 
	or not ply.TradingWith.TradeReady then return end
	
	ply.TradeConfirmed = true
	if ply.TradeConfirmed and ply.TradingWith.TradeConfirmed then
		TRADING.FinishTrade(ply, ply.TradingWith)
	end
end
concommand.Add("_ConfirmTrade",TRADING.ConfirmTrade)

function TRADING.FinishTrade(ply, tradeply)
	if not IsValid(ply) or not IsValid(tradeply) then return end
	
	//Check players still have items entered into the trade
	for k,v in pairs(ply.TradeOffer) do
		if not TRADING.PlayerHasItem(ply, v) then TRADING.CancelTrade(tradeply, nil, nil, nil, TRADING.Settings.PlayerNoLongerHasItems) return end
	end	
	for k,v in pairs(tradeply.TradeOffer) do
		if not TRADING.PlayerHasItem(tradeply, v) then TRADING.CancelTrade(tradeply, nil, nil, nil, TRADING.Settings.PlayerNoLongerHasItems) return end
	end
	if ply.TradeOfferPoints and (ply.TradeOfferPoints > 0) then
		if not TRADING.PlayerHasPoints(ply, ply.TradeOfferPoints) then TRADING.CancelTrade(tradeply, nil, nil, nil, TRADING.Settings.PlayerNoLongerHasItems) return end
	end
	if tradeply.TradeOfferPoints and (tradeply.TradeOfferPoints > 0) then
		if not TRADING.PlayerHasPoints(tradeply, tradeply.TradeOfferPoints) then TRADING.CancelTrade(tradeply, nil, nil, nil, TRADING.Settings.PlayerNoLongerHasItems) return end
	end
	
	//Process trade items
	if PS then
		for k,v in pairs(ply.TradeOffer) do
			TRADING.RemovePlayerItem(ply, v)
			TRADING.AddPlayerItem(tradeply, v) 
		end
		
		for k,v in pairs(tradeply.TradeOffer) do
			TRADING.RemovePlayerItem(tradeply, v)
			TRADING.AddPlayerItem(ply, v)
		end
	else
		for k,v in pairs(ply.TradeOffer) do
			local classname = TRADING.GetItemData(v, ply).class.className
			TRADING.RemovePlayerItem(ply, v)
			TRADING.AddPlayerItem(tradeply, classname) 
		end
		
		if not (ply == tradeply) then
			for k,v in pairs(tradeply.TradeOffer) do
				local classname = TRADING.GetItemData(v, tradeply).class.className
				TRADING.RemovePlayerItem(tradeply, v)
				TRADING.AddPlayerItem(ply, classname)
			end
		end
	end
	
	//Process points if enabled
	if ply.TradeOfferPoints and (ply.TradeOfferPoints > 0) then
		TRADING.AddPlayerPoints(tradeply, ply.TradeOfferPoints)
		TRADING.RemovePlayerPoints(ply, ply.TradeOfferPoints)
	end
	if tradeply.TradeOfferPoints and (tradeply.TradeOfferPoints > 0) then
		TRADING.AddPlayerPoints(ply, tradeply.TradeOfferPoints)
		TRADING.RemovePlayerPoints(tradeply, tradeply.TradeOfferPoints)
	end
	
	ply.TradingWith = nil
	ply.TradeOffer = nil
	ply.TradeOfferPoints = nil
	ply.TradeReady = nil
	ply.TradeConfirmed = nil
	
	tradeply.TradingWith = nil
	tradeply.TradeOffer = nil
	tradeply.TradeOfferPoints = nil
	tradeply.TradeReady = nil
	tradeply.TradeConfirmed = nil
	
	net.Start("TradingFinish")
		net.WriteBool(false)
	net.Send(ply)

	net.Start("TradingFinish")
		net.WriteBool(false)
	net.Send(tradeply)	
end

function TRADING.CancelTrade(ply, cmd, args, str, reason)
	if not ply.TradingWith then return end
	
	local tradeply = ply.TradingWith
	ply.TradingWith = nil
	ply.TradeOffer = nil
	ply.TradeOfferPoints = nil
	ply.TradeReady = nil
	ply.TradeConfirmed = nil
	
	net.Start("TradingFinish")
		net.WriteBool(true)
	net.Send(ply)
	
	TRADING.SendNotification(TRADING.Settings.TradeCancelled, 1, ply)
	if IsValid(tradeply) then
		tradeply.TradingWith = nil
		tradeply.TradeOffer = nil
		tradeply.TradeOfferPoints = nil
		tradeply.TradeReady = nil
		tradeply.TradeConfirmed = nil
		
		net.Start("TradingFinish")
			net.WriteBool(true)
		net.Send(tradeply)
		
		TRADING.SendNotification(string.format(reason or TRADING.Settings.TradeCancelledByOther, ply:Nick()), 1, tradeply)
	end
end
concommand.Add("_CancelTrade",TRADING.CancelTrade)

function TRADING.SendNotification(text, mtype, sendtoply, ply)
	if not text or not mtype or not sendtoply then return end

	net.Start("TradingNotification")
		net.WriteString(text)
		net.WriteUInt(mtype, 4)
		if ply then net.WriteEntity(ply) end
	net.Send(sendtoply)	
end

function TRADING.DebugTrade(ply, tradeply)
	//This debug function does not pose a security risk, since 
	//any items traded will be both taken and received
	if ply.TradingWith then
		TRADING.CancelTrade(ply)
	else
		TRADING.StartTrading(ply, ply, true)
	end
end
concommand.Add("trading_debug",TRADING.DebugTrade)