TRADING.ErrorNotify = 1
TRADING.SuccessNotify = 2
TRADING.TradeNotify = 3
TRADING.NotificationSize = ScrW() / 4
TRADING.Notifications = {}
TRADING.Notifications[TRADING.ErrorNotify] = {color = TRADING.Theme.NotifcationErrorColor, time = 7}
TRADING.Notifications[TRADING.SuccessNotify] = {color = TRADING.Theme.NotifcationSuccessColor, time = 3}
TRADING.Notifications[TRADING.TradeNotify] = {color = TRADING.Theme.NotifcationAccentColor, time = 25}

local Messages = {}
local y = 10
local Offset = 10
local function UpdateMessages(CurrentTime)
	local x = ScrW() - (TRADING.NotificationSize + 50)
	local lastpanel
	for k,v in pairs(Messages) do
		if v:IsValid() then
			if lastpanel then 
				local lastx,lasty = lastpanel:GetPos()
				v.MoveToHeight = math.Approach(v.MoveToHeight, (lasty + lastpanel:GetTall()), FrameTime() * 400)
				v:SetPos(x,v.MoveToHeight + Offset)
			else v:SetPos(x,y)
			end
			lastpanel = v
			if v:GetAlpha() < 255 then
				v:SetAlpha(math.Approach(v:GetAlpha(), 255, FrameTime() * 400))
			end
			if CurrentTime >= v.EndTime then
				v:SetAlpha(math.Approach(v:GetAlpha(), 0, FrameTime() * 400))
				if v:GetAlpha() <= 0 then v:Remove() v = nil table.remove(Messages, k) end
			end
		end
	end
end

function TRADING.AddNotifcation(text, type, ply)
	if not text then return end
	if TRADING.TradeWindowOpen and (type == TRADING.ErrorNotify) then
		local color = TRADING.Theme.NotifcationErrorColor
		TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
		TradingWindow.Chatbox:AppendText(string.format("%s\n",text))
		return
	end
	
	TRADING.NotificationSize = ScrW() / 4
	local Notification = vgui.Create("TradeMessage")
	Notification.MoveToHeight = 10
	Notification:SetAlpha(0)
	if (type == TRADING.TradeNotify) then
		Notification:SetPlayer(ply)
		local acceptstr = TRADING.Settings.AcceptLastTradeFKey and (TRADING.Settings.AcceptLastTradeFKey != "") and string.format("%s (%s)",TRADING.Settings.AcceptRequest,TRADING.Settings.AcceptLastTradeFKey) or TRADING.Settings.AcceptRequest
		local ignorestr = TRADING.Settings.IgnoreLastTradeFKey and (TRADING.Settings.IgnoreLastTradeFKey != "") and string.format("%s (%s)",TRADING.Settings.IgnoreRequest,TRADING.Settings.IgnoreLastTradeFKey) or TRADING.Settings.IgnoreRequest
		Notification:SetQuestionButtons(acceptstr, function() TRADING.RemoveNotification(Notification) RunConsoleCommand("_AcceptTradeRequest",ply:UserID()) end, ignorestr,
		function() TRADING.RemoveNotification(Notification) end)
	end
	//Notification:ParentToHUD()
	Notification.Think = function()
		if CurTime() >= (Notification.EndTime + 3) then Notification:Remove() Notification = nil return end
		//if not Notification:GetParent():IsValid() then
			//Notification:ParentToHUD()
		//end
	end
	Notification:SetText(text)
	if type then 
		Notification:SetColor(TRADING.Notifications[type].color)
		Notification.StartTime = CurTime()
		Notification.EndTime = CurTime() + (time or TRADING.Notifications[type].time or 5)
	else 
		Notification.StartTime = CurTime()
		Notification.EndTime = CurTime() + (time or 5)
	end
	table.insert(Messages, Notification)
	
	if TRADING.Settings.NotificationSound and (TRADING.Settings.NotificationSound != "") then
		surface.PlaySound(TRADING.Settings.NotificationSound)
	end
end

function TRADING.GetLastTradeRequest()
	local ply, pnl
	for k,v in ipairs(Messages) do
		if IsValid(v) and IsValid(v:GetPlayer()) then
			ply = v:GetPlayer()
			pnl = v
		end
	end
	return ply, pnl
end

function TRADING.RemoveNotification(pnl)
	table.RemoveByValue(Messages, pnl)
	pnl:Remove()
end

local function TradingNotification()
	local text = net.ReadString()
	local mtype = net.ReadUInt(4)
	local ply = net.ReadEntity()
	TRADING.AddNotifcation(text, mtype, ply)
end
net.Receive("TradingNotification",TradingNotification)

hook.Add("Think", "TradingNotifications", function()
	if #Messages < 1 then return end
	UpdateMessages(CurTime())	
end)
