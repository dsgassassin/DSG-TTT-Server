--Pointshop Trading System Client Dist
if TRADING then TRADING = TRADING
else TRADING = {} end

include('cl_tradingfonts.lua')
include('sh_tradingconfig.lua')
include('sh_pointshoptrading.lua')
if not PSPLUS then include('cl_trademessages.lua') end
--Include panels
include('panels/cl_categoriesdropdown.lua')
include('panels/cl_tradeitem.lua')
include('panels/cl_playertradepanel.lua')
include('panels/cl_playersummarypanel.lua')
include('panels/cl_playerselection.lua')
if not PSPLUS then
	include('panels/cl_trademessage.lua')	
end

function TRADING.OpenTradeWindow(tradeply,cmd)
	if not PS and not Pointshop2 then return end
	
	TRADING.TradeWindowOpen = true
	TRADING.OtherPlayer = tradeply
	if !TradingWindow then
		//Resolution check
		if ((ScrH() / 2) < (TRADING.Theme.InventoryItemSize * 4)) or ((ScrW() / 2) < (TRADING.Theme.InventoryItemSize * 4)) then
			TRADING.LowResolution = true
			TRADING.CurrentIconSize = (TRADING.Theme.InventoryItemSize / 2)
		else
			TRADING.LowResolution = false
			TRADING.CurrentIconSize = (TRADING.Theme.InventoryItemSize)
		end
	
		TradingWindow = vgui.Create( "DFrame" )
		if TRADING.LowResolution then
			TradingWindow:SetSize( ScrW() - 40, ScrH() - 15 )
		else
			TradingWindow:SetSize( ScrW() - 400, ScrH() - 150 )
		end
		TradingWindow:Center()
		TradingWindow:SetDraggable( false )
		TradingWindow:ShowCloseButton( false )
		TradingWindow:SetTitle( "" )
		TradingWindow:SetBackgroundBlur( true )
		TradingWindow.Paint = TRADING.PaintWindow
		
		//Inventory title
		local InventoryTitle = vgui.Create("DLabel",TradingWindow)
		InventoryTitle:SetPos(20, 10)
		InventoryTitle:SetFont("Bebas40Font")
		InventoryTitle:SetText(TRADING.Settings.YourInventoryTitle)
		InventoryTitle:SetColor(color_white)
		InventoryTitle:SizeToContents()
		
		//Item categories dropdown
		TradingWindow.ItemCategories = vgui.Create("CategoriesDropdown",TradingWindow)
		TradingWindow.ItemCategories:SetPos(20, 50)
		TradingWindow.ItemCategories:SetSize((TradingWindow:GetWide() / 2) - 50, 40)
		TradingWindow.ItemCategories:SetFont("OpenSans30Font")

		for k,v in pairs(TRADING.RetrieveAvailableCategories()) do
			local icon = v.Icon
			if icon and not string.EndsWith(v.Icon,".png") then
				icon = string.format("icon16/%s.png",icon)
			end
			if k == 1 or v.First then TradingWindow.ItemCategories:AddChoice(v.Name, k, icon, false, true)
			else TradingWindow.ItemCategories:AddChoice(v.Name, k, icon) end
		end
		if TRADING.Settings.CanTradePoints then
			TradingWindow.ItemCategories:AddChoice(string.format(TRADING.Settings.AddPoints,TRADING.GetPointsName()),"",TRADING.Theme.TradePointsIcon,true)
		end
		TradingWindow.ItemCategories.OnSelect = function(s, index, value, data)
			if TRADING.Settings.CanTradePoints and (index == #s.Choices) then
				Derma_StringRequest(string.format(TRADING.Settings.AddPointsToTrade,TRADING.GetPointsName()),string.format(TRADING.Settings.AddPointsDetails,
				string.lower(TRADING.GetPointsName()),string.Comma(TRADING.GetPlayerPoints(LocalPlayer())),TRADING.GetPointsName()),"0",function(val)
					TRADING.OfferPointsTrade(val)
				end)
			else
			TRADING.ChangeInventoryCategory(value, data)
			end
		end
		
		//Cancel Trade
		local CancelTradeButton = vgui.Create("DButton",TradingWindow)
		CancelTradeButton:SetPos((TradingWindow:GetWide() / 2) - 180, 10)
		CancelTradeButton:SetSize(150, 30)
		CancelTradeButton:SetFont("OpenSans24Font")
		CancelTradeButton:SetText(TRADING.Settings.CancelTrade)
		CancelTradeButton.Paint = function(s,w,h)
			surface.SetDrawColor(Color(255,255,255,10))
			surface.DrawRect( 0, 0, w, h )
			if s:IsHovered() then
				surface.SetDrawColor(Color(255,255,255,25))
				surface.DrawRect( 0, 0, w, h ) 
			end
		end
		CancelTradeButton.UpdateColours = function(s, skin)
			if (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
			elseif s:IsHovered() then return s:SetTextStyleColor(Color(222,222,222))
			else return s:SetTextStyleColor(Color(209,209,209))
			end
		end
		CancelTradeButton.DoClick = function()
			if TRADING.ItemsInTrade() then
				Derma_Query(TRADING.Settings.CancelTradeConfirmation, 
				TRADING.Settings.CancelTrade, TRADING.Settings.YesText, function() TRADING.CancelTrade() end, TRADING.Settings.NoText ) 
			else
			TRADING.CancelTrade()
			end
		end
		
		//Chatbox
		TradingWindow.Chatbox = vgui.Create("RichText",TradingWindow)
		TradingWindow.Chatbox:SetPos(20, TradingWindow:GetTall() - 225)
		TradingWindow.Chatbox:SetSize((TradingWindow:GetWide() / 2) - 50, 170)	
		TradingWindow.Chatbox.Paint = function(s,w,h)
			TradingWindow.Chatbox:SetFontInternal( "OpenSans24Font" )
			surface.SetDrawColor(TRADING.Theme.OutlineColor)
			surface.DrawRect( 0, 0, w, h ) 
			surface.SetDrawColor(TRADING.Theme.WindowColor)
			surface.DrawRect( 1, 1, w - 2, h - 2 ) 
		end
		if TRADING.Settings.DefaultChatBoxMessage and (TRADING.Settings.DefaultChatBoxMessage != "") then
			TradingWindow.Chatbox:AppendText( string.format("%s\n",TRADING.Settings.DefaultChatBoxMessage) )
		end
		
		//Chatbox text entry
		local ChatTextEntry = vgui.Create("DTextEntry",TradingWindow)
		ChatTextEntry:SetPos(20, TradingWindow:GetTall() - 50)
		ChatTextEntry:SetSize((TradingWindow:GetWide() / 2) - 120, 40)
		ChatTextEntry:SetFont("OpenSans24Font")
		ChatTextEntry:SetTextColor(color_white)
		//ChatTextEntry:SetText("TEST MESSAGE!")
		ChatTextEntry:SetDrawBackground(false)
		ChatTextEntry:SetUpdateOnType(true)
		ChatTextEntry:SetHighlightColor(Color(192,28,0,140))
		ChatTextEntry:SetCursorColor(color_white)
		ChatTextEntry.Paint = function(s,w,h)
			surface.SetDrawColor(TRADING.Theme.OutlineColor)
			surface.DrawRect( 0, 0, w, h ) 
			surface.SetDrawColor(TRADING.Theme.WindowColor)
			surface.DrawRect( 1, 1, w - 2, h - 2 ) 
			derma.SkinHook( "Paint", "TextEntry", s, w, h )
			return false
		end
		ChatTextEntry.OnEnter = function()
			if not TradingWindow.ChatSendButton:GetDisabled() then
				RunConsoleCommand("_TradeChatMessage",ChatTextEntry:GetValue())
				ChatTextEntry:SetText("")
				TradingWindow.ChatSendButton:SetDisabled(true)
				ChatTextEntry:RequestFocus()
			end
		end
		ChatTextEntry.OnValueChange = function(s,value)
			if string.Trim(value) != "" then
				TradingWindow.ChatSendButton:SetDisabled(false)
			else
				TradingWindow.ChatSendButton:SetDisabled(true)
			end
		end
		
		TradingWindow.ChatSendButton = vgui.Create("DButton",TradingWindow)
		TradingWindow.ChatSendButton:SetPos(25 + ChatTextEntry:GetWide(), TradingWindow:GetTall() - 50)
		TradingWindow.ChatSendButton:SetSize(65, 40)
		TradingWindow.ChatSendButton:SetFont("Bebas20Font")
		TradingWindow.ChatSendButton:SetText(TRADING.Settings.ChatboxSend)
		TradingWindow.ChatSendButton:SetDisabled(true)
		TradingWindow.ChatSendButton.Paint = function(s,w,h)
			surface.SetDrawColor(TRADING.Theme.OutlineColor)
			surface.DrawRect( 0, 0, w, h ) 
			surface.SetDrawColor(TRADING.Theme.WindowColor)
			surface.DrawRect( 1, 1, w - 2, h - 2 )
			if s:IsDown() then
				surface.SetDrawColor(Color(255,255,255,20))
				surface.DrawRect( 1, 1, w - 2, h - 2 ) 
			end
		end
		TradingWindow.ChatSendButton.UpdateColours = function(s, skin)
			if s:GetDisabled() then return s:SetTextStyleColor(Color(89,89,89))
			elseif (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
			elseif s:IsHovered() then return s:SetTextStyleColor(Color(192,28,0,140))
			else return s:SetTextStyleColor(Color(209,209,209))
			end
		end
		TradingWindow.ChatSendButton.DoClick = function()
			RunConsoleCommand("_TradeChatMessage",ChatTextEntry:GetValue())
			ChatTextEntry:SetText("")
			TradingWindow.ChatSendButton:SetDisabled(true)
		end

		//Right pane
		TradingWindow.YourOffer = vgui.Create("PlayerTradePanel",TradingWindow)
		TradingWindow.YourOffer:SetPos(30 + (TradingWindow:GetWide() / 2), 10)
		TradingWindow.YourOffer:SetSize((TradingWindow:GetWide() / 2) - 50, 134 + (TRADING.CurrentIconSize * 2))
		TradingWindow.YourOffer:SizeToContentsY()
		TradingWindow.YourOffer:SetData(LocalPlayer(), true)
		//TradingWindow.YourOffer:SetStatus(3)
		
		TradingWindow.TheirOffer = vgui.Create("PlayerTradePanel",TradingWindow)
		TradingWindow.TheirOffer:SetPos(30 + (TradingWindow:GetWide() / 2), 10 + TradingWindow.YourOffer:GetTall())
		TradingWindow.TheirOffer:SetSize((TradingWindow:GetWide() / 2) - 50, 134 + (TRADING.CurrentIconSize * 2))
		TradingWindow.TheirOffer:SizeToContentsY()
		TradingWindow.TheirOffer:SetData(tradeply)
		//TradingWindow.TheirOffer:SetStatus(3)
		
		//Make trade
		TradingWindow.MakeTradeButton = vgui.Create("DButton",TradingWindow)
		TradingWindow.MakeTradeButton:SetPos((TradingWindow:GetWide() / 2) + (TradingWindow:GetWide() / 4) - 100 , 25 + (TradingWindow.YourOffer:GetTall() * 2) )
		TradingWindow.MakeTradeButton:SetSize(200, 50)
		TradingWindow.MakeTradeButton:SetFont("OpenSans30Font")
		TradingWindow.MakeTradeButton:SetText(TRADING.Settings.MakeTrade)
		TradingWindow.MakeTradeButton:SetDisabled(true)
		TradingWindow.MakeTradeButton:SetCursor("no")
		TradingWindow.MakeTradeButton.Paint = function(s,w,h)
			if not TradingWindow.MakeTradeButton.Confirmed then
				if s:GetDisabled() then
					draw.RoundedBox( 4, 0, 0, w, h, Color(255,255,255,20) )
				else
					draw.RoundedBox( 4, 0, 0, w, h, Color(99,137,41))
				end
				if s:IsDown() then
					surface.SetDrawColor(Color(255,255,255,20))
					surface.DrawRect( 1, 1, w - 2, h - 2 ) 
				end
			end
		end
		TradingWindow.MakeTradeButton.UpdateColours = function(s, skin)
			if s.Confirmed then return s:SetTextStyleColor(color_white)
			elseif s:GetDisabled() then return s:SetTextStyleColor(Color(255,255,255,10))
			elseif (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
			elseif s:IsHovered() then return s:SetTextStyleColor(Color(222,222,222))
			else return s:SetTextStyleColor(Color(209,209,209))
			end
		end
		
		TradingWindow.MakeTradeButton.SetConfirmed = function(s, confirmed)
			TradingWindow.MakeTradeButton.Confirmed = confirmed
			if confirmed then
				TradingWindow.MakeTradeButton.TextDots = ""
				TradingWindow.MakeTradeButton.NextThink = CurTime() + 0.5
				TradingWindow.MakeTradeButton:SetText("Waiting")
				TradingWindow.MakeTradeButton.Think = function()
					if CurTime() >= TradingWindow.MakeTradeButton.NextThink then
						TradingWindow.MakeTradeButton.NextThink = CurTime() + 0.5
						if TradingWindow.MakeTradeButton.TextDots == "..." then
							TradingWindow.MakeTradeButton.TextDots = ""
						end
						 TradingWindow.MakeTradeButton.TextDots = (TradingWindow.MakeTradeButton.TextDots..".")
						 TradingWindow.MakeTradeButton:SetText(string.format("Waiting%s",TradingWindow.MakeTradeButton.TextDots))
					end
				end
			else
				TradingWindow.MakeTradeButton:SetText(TRADING.Settings.MakeTrade)
				TradingWindow.MakeTradeButton:SetDisabled(true)
				TradingWindow.MakeTradeButton:SetCursor("no")	
				TradingWindow.MakeTradeButton.Think = nil
			end
		end
		TradingWindow.MakeTradeButton.DoClick = function()
			RunConsoleCommand("_ConfirmTrade")
			TRADING.UpdateTradeConfirmed(true)
		end

		//Trade status
		TradingWindow.TradeStatus = vgui.Create("DLabel", TradingWindow)
		TradingWindow.TradeStatus:SetFont("OpenSans24Font")
		TradingWindow.TradeStatus:SetColor(Color(255,255,255,50))
		TradingWindow.TradeStatus:SetText(TRADING.Settings.BothNotReady)
		TradingWindow.TradeStatus:SizeToContents()
		TradingWindow.TradeStatus:SetPos((TradingWindow:GetWide() / 2) + (TradingWindow:GetWide() / 4) - (TradingWindow.TradeStatus:GetWide() / 2) , 80 + (TradingWindow.YourOffer:GetTall() * 2))

		TRADING.ChangeInventoryCategory(TradingWindow.ItemCategories:GetSelected())
		
		TradingWindow:MakePopup()
		
		//Trade partner check
		TradingWindow.NextThink = CurTime()
		TradingWindow.Think = function()
			if (TradingWindow.NextThink > CurTime()) or TradingWindow.ParnterInvalid then return end
			TradingWindow.NextThink = CurTime() + 2
			if not IsValid(TRADING.OtherPlayer) then
				TradingWindow.ParnterInvalid = true
				TRADING.CancelTrade()
			end
		end
		
		//Find the menu tab to open
	elseif cmd then
		TRADING.CloseTradeWindow()
	end
end
concommand.Add("trading", TRADING.OpenTradeWindow)
//usermessage.Hook("MODERN_Open", MODERN.OpenMOTD)

function TRADING.PaintWindow(s,w,h)
	surface.SetDrawColor(TRADING.Theme.WindowColor)
	
	surface.DrawRect(0, 0, w, h)
	
	//Left pane top background
	draw.RoundedBox( 4, 5, 5, (w / 2) - 20, h - 260, TRADING.Theme.ControlColor  )	
	
	//Left pane lower background
	draw.RoundedBox( 4, 5, h- 230, (w / 2) - 20, 225, TRADING.Theme.ControlColor  )	
	
	//Right pane background
	draw.RoundedBox( 4, (w / 2) + 15, 5, (w / 2) - 20, h - 10, TRADING.Theme.ControlColor  )

	//Make trade divider
	local x,y = s.TheirOffer:GetPos()
	surface.SetDrawColor(Color(255,255,255,10))
	surface.DrawRect( 30 + (w / 2), 5 + (y + s.TheirOffer:GetTall()), s.TheirOffer:GetWide(), 2 ) 
end

function TRADING.ShowTradeSummary(yourtrade,theirtrade,tradeply)
	if TradingWindow then return end
	
	local TradeSummaryWindow = vgui.Create( "DFrame" )
	if TRADING.LowResolution then
		TradeSummaryWindow:SetSize( ScrW() - 40, ScrH() - 15 )
	else
		TradeSummaryWindow:SetSize( ScrW() - 400, ScrH() - 150 )
	end
	TradeSummaryWindow:Center()
	TradeSummaryWindow:SetDraggable( false )
	TradeSummaryWindow:ShowCloseButton( false )
	TradeSummaryWindow:SetTitle( "" )
	TradeSummaryWindow:SetBackgroundBlur( true )
	TradeSummaryWindow.Paint = function(s,w,h)
		surface.SetDrawColor(TRADING.Theme.WindowColor)
		surface.DrawRect(0, 0, w, h)
		//Summary background
		local th = (55 + TradeSummaryWindow.SummarySubtitle:GetTall())
		draw.RoundedBox( 4, 5, th, w - 10, (h - 60) - th, TRADING.Theme.ControlColor  )
	end
	
	//Summary title
	TradeSummaryWindow.SummaryTitle = vgui.Create("DLabel",TradeSummaryWindow)
	TradeSummaryWindow.SummaryTitle:SetPos(20, 10)
	TradeSummaryWindow.SummaryTitle:SetFont("Bebas40Font")
	TradeSummaryWindow.SummaryTitle:SetText(TRADING.Settings.TradeConfirmedTitle)
	TradeSummaryWindow.SummaryTitle:SetColor(color_white)
	TradeSummaryWindow.SummaryTitle:SizeToContents()
	
	//Summary title
	TradeSummaryWindow.SummarySubtitle = vgui.Create("DLabel",TradeSummaryWindow)
	TradeSummaryWindow.SummarySubtitle:SetPos(20, 50)
	TradeSummaryWindow.SummarySubtitle:SetFont("OpenSans24Font")
	TradeSummaryWindow.SummarySubtitle:SetText(string.format(TRADING.Settings.TradeConfirmed,tradeply:Nick()))
	TradeSummaryWindow.SummarySubtitle:SizeToContents()
	
	//Summary panels
	local YourSummary = vgui.Create("PlayerSummaryPanel",TradeSummaryWindow)
	YourSummary:SetPos(30, 60 + TradeSummaryWindow.SummarySubtitle:GetTall())
	YourSummary:SetSize((TradeSummaryWindow:GetWide() / 1.5), 90 + (TRADING.CurrentIconSize * 2))
	//YourSummary:SizeToContentsY()
	YourSummary:SetData(LocalPlayer(), true)
	
	for k,v in pairs(yourtrade) do
		if v.points then YourSummary:AddItem(v.data,v.points)
		else YourSummary:AddItem(v.data) end
	end

	local TheirSummary = vgui.Create("PlayerSummaryPanel",TradeSummaryWindow)
	TheirSummary:SetPos(30, (70 + TradeSummaryWindow.SummarySubtitle:GetTall()) + YourSummary:GetTall())
	TheirSummary:SetSize((TradeSummaryWindow:GetWide() / 1.5), 90 + (TRADING.CurrentIconSize * 2))
	//TheirSummary:SizeToContentsY()
	TheirSummary:SetData(tradeply)
	
	for k,v in pairs(theirtrade) do
		if v.points then TheirSummary:AddItem(v.data,v.points)
		else TheirSummary:AddItem(v.data) end
	end
	
	//Close button
	local CloseButton = vgui.Create("DButton",TradeSummaryWindow)
	CloseButton:SetPos((TradeSummaryWindow:GetWide() / 2) - 205, TradeSummaryWindow:GetTall() - 55)
	CloseButton:SetSize(200, 50)
	CloseButton:SetFont("OpenSans30Font")
	CloseButton:SetText(TRADING.Settings.CloseSummaryWindow)
	CloseButton.Paint = function(s,w,h)
		surface.SetDrawColor(Color(255,255,255,10))
		surface.DrawRect( 0, 0, w, h )
		if s:IsHovered() then
			surface.SetDrawColor(Color(255,255,255,25))
			surface.DrawRect( 0, 0, w, h ) 
		end
	end
	CloseButton.UpdateColours = function(s, skin)
		if (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
		elseif s:IsHovered() then return s:SetTextStyleColor(Color(222,222,222))
		else return s:SetTextStyleColor(Color(209,209,209))
		end
	end
	CloseButton.DoClick = function()
		TradeSummaryWindow:Close()
	end
	
	//Open pointshop button
	local PointshopButton = vgui.Create("DButton",TradeSummaryWindow)
	PointshopButton:SetPos((TradeSummaryWindow:GetWide() / 2) , TradeSummaryWindow:GetTall() - 55)
	PointshopButton:SetSize(200, 50)
	PointshopButton:SetFont("OpenSans30Font")
	PointshopButton:SetText(TRADING.Settings.OpenInventory)
	PointshopButton.Paint = function(s,w,h)
		surface.SetDrawColor(Color(255,255,255,10))
		surface.DrawRect( 0, 0, w, h )
		if s:IsHovered() then
			surface.SetDrawColor(Color(255,255,255,25))
			surface.DrawRect( 0, 0, w, h ) 
		end
	end
	PointshopButton.UpdateColours = function(s, skin)
		if (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
		elseif s:IsHovered() then return s:SetTextStyleColor(Color(222,222,222))
		else return s:SetTextStyleColor(Color(209,209,209))
		end
	end
	PointshopButton.DoClick = function()
		TradeSummaryWindow:Close()
		TRADING.OpenPointshopInventory()
	end
	
	TradeSummaryWindow:MakePopup()
end

function TRADING.ChangeInventoryCategory(name, id)
	if not TradingWindow then return end
	
	TRADING.CurrentCategory = PS and name or id

	local items = TRADING.RetrievePlayerItems(PS and name or id, true)
	if TradingWindow.NoItemsLabel then TradingWindow.NoItemsLabel:Remove() end
	if TradingWindow.InventoryScroller then
		TradingWindow.InventoryScroller:Remove()
		TradingWindow.InventoryItems:Remove()
	end
	TradingWindow.InventoryScroller = vgui.Create("DScrollPanel",TradingWindow)
	TradingWindow.InventoryScroller:SetPos(20, 95)
	TradingWindow.InventoryScroller:SetSize((TradingWindow:GetWide() / 2) - 50, TradingWindow:GetTall() - 375)
	TradingWindow.InventoryScroller.Paint = function(s,w,h)
		surface.SetDrawColor(TRADING.Theme.OutlineColor)
		surface.DrawRect( 0, 0, w, h ) 
		surface.SetDrawColor(TRADING.Theme.WindowColor)
		surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	end
	TradingWindow.InventoryScroller.PaintOver = function(s,w,h)
		if s.IsDragHovered or TRADING.IsPlayerReady() then
			surface.SetDrawColor(Color(0,0,0,150))
			surface.DrawRect( 0, 0, w, h ) 
			
			if s.IsDragHovered then
			surface.SetFont("OpenSans30Font")
			local tw,th = surface.GetTextSize(TRADING.Settings.RemoveTradeItem)
			draw.SimpleText( TRADING.Settings.RemoveTradeItem, "OpenSans30Font", (w / 2) - (tw / 2), (h / 2) - (th / 2), Color(209,209,209))
			s.IsDragHovered = false
			end
		end
	end
	TRADING.EditScrollBarStyle(TradingWindow.InventoryScroller)
	TradingWindow.InventoryScroller.DropItem = function(s, panels, dropped)
		if IsValid(panels[1]) and dropped then
			local itemid = panels[1]:GetData()
			if panels[1]:IsPointsSlot() then
				TRADING.OfferPointsTrade(0)
			else
				TRADING.RemoveOfferTradeItem(itemid)
			end
		elseif IsValid(panels[1]) then s.IsDragHovered = true end
	end
	TradingWindow.InventoryScroller:Receiver("TradeOfferItem",TradingWindow.InventoryScroller.DropItem)
	
	TradingWindow.InventoryItems = vgui.Create("DIconLayout",TradingWindow.InventoryScroller)
	TradingWindow.InventoryItems:Dock(FILL)
	TradingWindow.InventoryItems:SetSpaceX(5)
	TradingWindow.InventoryItems:SetSpaceY(5)
	TradingWindow.InventoryItems:SetBorder(5)
	
	if #items >= 1 then	
		for k,v in pairs(items) do
			local item = TradingWindow.InventoryItems:Add("TradeItem")
			item:SetSize(TRADING.CurrentIconSize,TRADING.CurrentIconSize)
			item:SetColor(TRADING.GetCategoryColor(v.Category, true))
			item:SetData(v,true)
		end
	else
		TradingWindow.NoItemsLabel = vgui.Create("DLabel",TradingWindow)
		local x,y,w,h = TradingWindow.InventoryScroller:GetBounds()
		TradingWindow.NoItemsLabel:SetFont("OpenSans24Font")
		TradingWindow.NoItemsLabel:SetText(string.format(TRADING.Settings.NoItemsMessage, name))
		TradingWindow.NoItemsLabel:SizeToContents()
		TradingWindow.NoItemsLabel:SetPos((25 + (w/2)) - (TradingWindow.NoItemsLabel:GetWide() / 2), (y + (h/2)) - (TradingWindow.NoItemsLabel:GetTall() / 2))
	end
	TradingWindow.InventoryScroller:PerformLayout()
end

function TRADING.UpdateTradeConfirmed(confirmed)
	TRADING.TradeConfirmed = confirmed
	TradingWindow.MakeTradeButton:SetConfirmed(confirmed)
	TradingWindow.YourOffer:SetDisabled(confirmed)
	
	TradingWindow.TradeStatus:SetText(TRADING.Settings.AwaitingConfirmation)
	TradingWindow.TradeStatus:SizeToContents()
	TradingWindow.TradeStatus:SetPos((TradingWindow:GetWide() / 2) + (TradingWindow:GetWide() / 4) - (TradingWindow.TradeStatus:GetWide() / 2) , 80 + (TradingWindow.YourOffer:GetTall() * 2))
end

function TRADING.UpdateTradeStatus(status, ourstatus)
	if ourstatus then
		TradingWindow.YourOffer:SetStatus(status)	
	else
		TradingWindow.TheirOffer:SetStatus(status)
	end
	
	if TRADING.TradeConfirmed then TRADING.UpdateTradeConfirmed(false) end
	
	if ourstatus and (status == 3) then
		TradingWindow.ItemCategories:SetDisabled(true)
		for k,v in pairs(TradingWindow.InventoryItems:GetChildren()) do
			v.m_DragSlot = nil
		end
	elseif ourstatus then
		TradingWindow.ItemCategories:SetDisabled(false)
		for k,v in pairs(TradingWindow.InventoryItems:GetChildren()) do
			v:Droppable("TradeItem")
		end
	end	
	
	if ((TradingWindow.YourOffer:GetStatus() == 3) and (TradingWindow.TheirOffer:GetStatus() == 3)) then
		TradingWindow.MakeTradeButton:SetDisabled(false)
		TradingWindow.MakeTradeButton:SetCursor("hand")
		TradingWindow.TradeStatus:SetText(TRADING.Settings.BothReady)
	elseif ((TradingWindow.YourOffer:GetStatus() == 2) and (TradingWindow.TheirOffer:GetStatus() == 3)) then
		TradingWindow.MakeTradeButton:SetDisabled(true)
		TradingWindow.MakeTradeButton:SetCursor("no")
		TradingWindow.TradeStatus:SetText(TRADING.Settings.YouNotReady)
	else
		TradingWindow.MakeTradeButton:SetDisabled(true)
		TradingWindow.MakeTradeButton:SetCursor("no")
		TradingWindow.TradeStatus:SetText(TRADING.Settings.BothNotReady)
	end
	TradingWindow.TradeStatus:SizeToContents()
	TradingWindow.TradeStatus:SetPos((TradingWindow:GetWide() / 2) + (TradingWindow:GetWide() / 4) - (TradingWindow.TradeStatus:GetWide() / 2) , 80 + (TradingWindow.YourOffer:GetTall() * 2))
end

function TRADING.StartTrading()
	local tradeply = net.ReadEntity()
	if not IsValid(tradeply) then 
		MsgN("POINTSHOP TRADING: Trade partner is no longer valid.")
		TRADING.CancelTrade()
		return
	end
	TRADING.IsTrading = true
	TRADING.OpenTradeWindow(tradeply)
end
net.Receive("TradingStart",TRADING.StartTrading)

function TRADING.FinishTrading()
	local cancelled = net.ReadBool()
	TRADING.IsTrading = nil
	TRADING.TradeConfirmed = nil
	if cancelled then
		TRADING.CloseTradeWindow()
	elseif TradingWindow then
		local yourtrade = TradingWindow.YourOffer:GetItems()
		local theirtrade = TradingWindow.TheirOffer:GetItems()

		local tradeply = TRADING.OtherPlayer
		TRADING.CloseTradeWindow()
		TRADING.ShowTradeSummary(yourtrade,theirtrade,tradeply)
	end
end
net.Receive("TradingFinish",TRADING.FinishTrading)

function TRADING.OfferTradeItem(itemid)
	if TRADING.PlayerHasItem(LocalPlayer(), itemid) then
		RunConsoleCommand("_OfferTradeItem", itemid)
	end
end

function TRADING.RemoveOfferTradeItem(itemid)
	if TRADING.PlayerHasItem(LocalPlayer(), itemid) and TradingWindow.YourOffer:HasItem(itemid) then
		RunConsoleCommand("_RemoveOfferTradeItem", itemid)
	end
end

function TRADING.OfferPointsTrade(points)
	if not tonumber(points) then return end
	if not TRADING.PlayerHasPoints(LocalPlayer(), tonumber(points)) then
		TRADING.AddNotifcation(string.format(TRADING.Settings.NotEnoughPoints,TRADING.GetPointsName()), TRADING.ErrorNotify)
		return
	end
	RunConsoleCommand("_OfferTradePoints",points)
end

function TRADING.ChangeReadyStatus(checked)
	RunConsoleCommand("_ChangeTradeReadyStatus",tostring(checked))
	TRADING.UpdateTradeStatus(checked and 3 or 2, true)
	
	TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
	TradingWindow.Chatbox:AppendText(checked and "You are ready.\n" or "You are not ready.\n")
end

function TRADING.UpdateReadyStatus()
	local ready = net.ReadBool()
	
	TRADING.UpdateTradeStatus(ready and 3 or 2)
	
	TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
	TradingWindow.Chatbox:AppendText(string.format("%s %s\n",TRADING.OtherPlayer:Nick(),ready and "is ready." or "is not ready."))
end
net.Receive("TradingStatus",TRADING.UpdateReadyStatus)

function TRADING.CancelTrade()
	RunConsoleCommand("_CancelTrade")
end

function TRADING.IsPlayerReady(ply)
	return ply and (TradingWindow.TheirOffer:GetStatus() == 3) or (TradingWindow.YourOffer:GetStatus() == 3)
end

function TRADING.UpdateTradeOfferItem()
	local itemid = net.ReadString()
	local added = net.ReadBool()
	local ouroffer = net.ReadBool()
	
	local uniqueid
	if not PS and not ouroffer then
		local parts = string.Explode(";",itemid)
		itemid = parts[2]
		uniqueid = parts[1]
	end
	
	local item = TRADING.GetItemData(itemid, ouroffer and LocalPlayer())

	local color = item.Color or TRADING.GetCategoryColor(item.Category, true) or TRADING.Theme.OutlineColor
	if (TradingWindow.YourOffer:GetStatus() == 3) then 
		TradingWindow.YourOffer:ShowOfferChanged(true)
		TRADING.UpdateTradeStatus(2, true)
	end
	if (TradingWindow.TheirOffer:GetStatus() == 3) then
		TRADING.UpdateTradeStatus(2)
	end
	if added then
		if ouroffer then
			TradingWindow.YourOffer:AddItem(item)
			
			//Remove item from available items
			for k,v in pairs(TradingWindow.InventoryItems:GetChildren()) do
				if (v:GetData() == (PS and item.ID or item.id)) then
					v:Remove()
				end
			end
			
			
			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(TRADING.Settings.YouAdded)
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s\n",item.Name or item:GetPrintName()))		
		else
			if PS then TradingWindow.TheirOffer:AddItem(item)
			else TradingWindow.TheirOffer:AddItem(item,nil,uniqueid) end
		
			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(string.format(TRADING.Settings.TheyAdded, TRADING.OtherPlayer:Nick()))
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s\n",item.Name or item:GetPrintName()))	
		end
		
		if (TradingWindow.YourOffer:GetStatus() == 1) then
			TRADING.UpdateTradeStatus(2, true)
		end
	else
		if ouroffer then
			TradingWindow.YourOffer:RemoveItem(item)
			
			//Reload current category if it matches
			if (TRADING.GetItemCategory(item) == TRADING.CurrentCategory) then
				TRADING.ChangeInventoryCategory(TRADING.CurrentCategory,PS and nil or TRADING.CurrentCategory)
			end
			
			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(TRADING.Settings.YouRemoved)
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s\n",item.Name or item:GetPrintName()))		
		else
			if PS then TradingWindow.TheirOffer:RemoveItem(item)
			else TradingWindow.TheirOffer:RemoveItem(item,nil,uniqueid) end
			
			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(string.format(TRADING.Settings.TheyRemoved, TRADING.OtherPlayer:Nick()))
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s\n",item.Name or item:GetPrintName()))	
		end	
		if not TRADING.ItemsInTrade() then
			TRADING.UpdateTradeStatus(1, true)
			TRADING.UpdateTradeStatus(2)
		end
	end
end
net.Receive("TradingOfferItem",TRADING.UpdateTradeOfferItem)

function TRADING.UpdateTradeOfferPoints()
	local points = net.ReadUInt(32)
	local ouroffer = net.ReadBool()
	local removepoints = net.ReadBool()

	local color = TRADING.Theme.TradePointsOutlineColor
	if (TradingWindow.YourOffer:GetStatus() == 3) then 
		TradingWindow.YourOffer:ShowOfferChanged(true)
		TRADING.UpdateTradeStatus(2, true)
	end
	if (TradingWindow.TheirOffer:GetStatus() == 3) then
		TRADING.UpdateTradeStatus(2)
	end
	if removepoints then
		if ouroffer then
			TradingWindow.YourOffer:RemoveItem(points, true)

			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(TRADING.Settings.YouRemoved)
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s %s\n",string.Comma(points),TRADING.GetPointsName()))		
		else
			TradingWindow.TheirOffer:RemoveItem(points, true)
			
			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(string.format(TRADING.Settings.TheyRemoved, TRADING.OtherPlayer:Nick()))
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s %s\n",string.Comma(points),TRADING.GetPointsName()))		
		end
		
		if not TRADING.ItemsInTrade() then
			TRADING.UpdateTradeStatus(1, true)
			TRADING.UpdateTradeStatus(2)
		end
	else
		if ouroffer then
			TradingWindow.YourOffer:AddItem(points, true)

			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(TRADING.Settings.YouAdded)
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s %s\n",string.Comma(points),TRADING.GetPointsName()))		
		else
			TradingWindow.TheirOffer:AddItem(points, true)
			
			TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
			TradingWindow.Chatbox:AppendText(string.format(TRADING.Settings.TheyAdded, TRADING.OtherPlayer:Nick()))
			TradingWindow.Chatbox:InsertColorChange(color.r, color.g, color.b, color.a)
			TradingWindow.Chatbox:AppendText(string.format("%s %s\n",string.Comma(points),TRADING.GetPointsName()))		
		end
		
		if (TradingWindow.YourOffer:GetStatus() == 1) then
			TRADING.UpdateTradeStatus(2, true)
		end
	end
end
net.Receive("TradingOfferPoints",TRADING.UpdateTradeOfferPoints)

function TRADING.TradeChatMessage()
	if not TRADING.TradeWindowOpen then return end
	local text = net.ReadString()
	local ply = net.ReadEntity()
	if not IsValid(ply) then return end
	
	if (ply == LocalPlayer()) then
		TradingWindow.Chatbox:InsertColorChange(72,108,143,255)
		TradingWindow.Chatbox:AppendText(string.format("%s: ",ply:Nick()))
		TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
		TradingWindow.Chatbox:AppendText(string.format("%s\n",text))
	else
		TradingWindow.Chatbox:InsertColorChange(72,108,143,255)
		TradingWindow.Chatbox:AppendText(string.format("%s: ",ply:Nick()))
		TradingWindow.Chatbox:InsertColorChange(209,209,209,255)
		TradingWindow.Chatbox:AppendText(string.format("%s\n",text))
	end
end
net.Receive("TradingChat",TRADING.TradeChatMessage)

function TRADING.EditScrollBarStyle(scrollpanel)
	local scrollbar = scrollpanel.VBar
	scrollbar.btnUp:SetVisible(false)
	scrollbar.btnDown:SetVisible(false)
	-- scrollbar.OnCursorEntered = function()
		-- scrollbar:SetCursor("hand")
	-- end
	scrollbar.PerformLayout = function()
		local Wide = scrollbar:GetWide()
		local Scroll = scrollbar:GetScroll() / scrollbar.CanvasSize
		local BarSize = math.max( scrollbar:BarScale() * (scrollbar:GetTall() - (Wide * 2)), 10 )
		local Track = scrollbar:GetTall() - (Wide * 2) - BarSize
		Track = Track + 1


		Scroll = Scroll * Track


		scrollbar.btnGrip:SetPos( 0, (Wide + Scroll) - 15 )
		scrollbar.btnGrip:SetSize( Wide, BarSize + 30 )
	end
	scrollbar.Paint = function() 
		surface.SetDrawColor(Color(255,255,255,100))
		surface.DrawRect(5,0,scrollbar:GetWide() / 1.5,scrollbar:GetTall())
	end
	scrollbar.btnGrip.Paint = function() 
		surface.SetDrawColor(Color(77,77,77))
		surface.DrawRect(5,0,scrollbar.btnGrip:GetWide() / 1.5,scrollbar.btnGrip:GetTall())
	end
end

function TRADING.CloseTradeWindow()
	if TradingWindow then
		TradingWindow:Remove()
		TradingWindow = nil
		//if MODERN.Settings.MenuSounds then surface.PlaySound(MODERN.Settings.MenuCloseSound) end
	end
	TRADING.TradeWindowOpen = false
end

function TRADING.OpenSelectionWindow()
	if TRADING.OpenSelectionWindowOpen then return end
	
	TRADING.OpenSelectionWindowOpen = true
	local TradingSelectionWindow = vgui.Create("DFrame")
	TradingSelectionWindow:SetSize(450, 500)
	if (ScrW() < 450) or (ScrH() < 500) then
		TradingSelectionWindow:SetSize(ScrW(),ScrH())
	end
	TradingSelectionWindow:SetTitle("")
	TradingSelectionWindow:Center()
	TradingSelectionWindow.Paint = function(s,w,h)
		surface.SetDrawColor(TRADING.Theme.WindowColor)
		surface.DrawRect(0, 0, w, h)
	end
	TradingSelectionWindow.OnClose = function()
		TRADING.OpenSelectionWindowOpen = nil
	end
	
	local SelectionTitle = vgui.Create("DLabel",TradingSelectionWindow)
	SelectionTitle:SetFont("Bebas40Font")
	SelectionTitle:SetColor(color_white)
	SelectionTitle:SetText(TRADING.Settings.PlayerSelection)
	SelectionTitle:SizeToContents()
	SelectionTitle:SetPos((TradingSelectionWindow:GetWide() / 2) - (SelectionTitle:GetWide() / 2),5)
	
	local SelectionSubtitle = vgui.Create("DLabel",TradingSelectionWindow)
	SelectionSubtitle:SetFont("OpenSans24Font")
	SelectionSubtitle:SetText(TRADING.Settings.PlayerSelectionSubtitle)
	SelectionSubtitle:SizeToContents()
	SelectionSubtitle:SetPos((TradingSelectionWindow:GetWide() / 2) - (SelectionSubtitle:GetWide() / 2),35)
	
	local PlayerSelectionScroller = vgui.Create("DScrollPanel",TradingSelectionWindow)
	PlayerSelectionScroller:SetPos(5, 70)
	PlayerSelectionScroller:SetSize(TradingSelectionWindow:GetWide() - 10, TradingSelectionWindow:GetTall() - 75)
	TRADING.EditScrollBarStyle(PlayerSelectionScroller)
	
	local PlayerSelection = vgui.Create("DListLayout",PlayerSelectionScroller)
	PlayerSelection:Dock(FILL)
	
	for k,v in pairs(player.GetAll()) do
		if (v==LocalPlayer()) then continue end
		local PlayerRow = PlayerSelection:Add("PlayerSelectionRow")
		PlayerRow:SetPlayer(v)
		PlayerRow:SetColor(team.GetColor(v:Team()))
		PlayerRow:DockMargin( 0,0,0,5 )
		
		PlayerRow.DoClick = function()
			RunConsoleCommand("_TradeRequest",v:UserID())
			TradingSelectionWindow:Close()
		end
	end
	TradingSelectionWindow:MakePopup()
end
concommand.Add("trading_selection", TRADING.OpenSelectionWindow)
usermessage.Hook("TradingSelection", TRADING.OpenSelectionWindow)

local BindToFKey = {
	["gm_showhelp"] = "F1",
	["gm_showteam"] = "F2",
	["gm_showspare1"] = "F3",
	["gm_showspare2"] = "F4"
}

local CursorEnabled
function TRADING.PlayerBindPress(ply, bind, pressed)
	if not PS and not Pointshop2 then return end
	if not pressed then return end
	if TRADING.Settings.SelectionMenuFKey and (TRADING.Settings.SelectionMenuFKey != "")
	and (TRADING.Settings.SelectionMenuFKey == BindToFKey[bind]) then
		TRADING.OpenSelectionWindow()
	elseif TRADING.Settings.AcceptLastTradeFKey and (TRADING.Settings.AcceptLastTradeFKey != "")
	and (TRADING.Settings.AcceptLastTradeFKey == BindToFKey[bind]) and TRADING.GetLastTradeRequest() then
		local ply, pnl = TRADING.GetLastTradeRequest()
		TRADING.RemoveNotification(pnl)
		RunConsoleCommand("_AcceptTradeRequest",ply:UserID())
		return true
	elseif TRADING.Settings.IgnoreLastTradeFKey and (TRADING.Settings.IgnoreLastTradeFKey != "")
	and (TRADING.Settings.IgnoreLastTradeFKey == BindToFKey[bind]) and TRADING.GetLastTradeRequest() then
		local ply, pnl = TRADING.GetLastTradeRequest()
		TRADING.RemoveNotification(pnl)
		return true
	elseif TRADING.Settings.CursorFKey and (TRADING.Settings.CursorFKey != "")
	and (TRADING.Settings.CursorFKey == BindToFKey[bind]) then
		CursorEnabled = !CursorEnabled
		gui.EnableScreenClicker(CursorEnabled)
	end
end
hook.Add("PlayerBindPress","TradingPlayerBindPress",TRADING.PlayerBindPress)

function TRADING.RetrieveAvailableCategories()
	local categories = {}
	if PS then
	for k,v in pairs(PS.Categories) do
		if TRADING.Settings.ExcludeCategories and (table.HasValue(TRADING.Settings.ExcludeCategories, k)) then continue end
		table.insert(categories, v)
	end	
	table.sort(categories, function(a, b) 
	if a.Order == b.Order then 
		return a.Name < b.Name
	else
		return a.Order < b.Order
	end
	end)
	else
		local dataNode = Pointshop2View:getInstance():getShopCategory()
		local first = true
		for k, v in pairs( dataNode.subcategories ) do
			if TRADING.Settings.ExcludeCategories and (table.HasValue(TRADING.Settings.ExcludeCategories, TRADING.FindCategoryNameByID(v.self.id))) then continue end
			categories[v.self.id] = {Name = v.self.label, Icon = v.self.icon, First = first}
			first = false
		end
		
		//Not for sale
		local notforsaleNode = Pointshop2View:getInstance():getNoSaleCategory()
		for k, v in pairs( notforsaleNode.subcategories ) do
			if TRADING.Settings.ExcludeCategories and (table.HasValue(TRADING.Settings.ExcludeCategories, TRADING.FindCategoryNameByID(v.self.id))) then continue end
			categories[v.self.id] = {Name = v.self.label, Icon = v.self.icon, First = first}
			first = false
		end
		
		//Uncategorized items
		if (TRADING.Settings.ExcludeCategories and not (table.HasValue(TRADING.Settings.ExcludeCategories, "Uncategorized Items"))) or not TRADING.Settings.ExcludeCategories then
			categories[-1] = {Name = "Uncategorized Items", Icon = "pointshop2/folder62.png", First = first}
		end
		
	end
	return categories
end

function TRADING.RetrievePlayerItems(category, suppress)
	local playeritems = {}
	
	if PS then
		local items = {}
		for _, i in pairs(PS.Items) do
			table.insert(items, i)
		end
		table.SortByMember(items, PS.Config.SortItemsBy, function(a, b) return a > b end)
		for k,v in pairs(items) do
			if TRADING.Settings.ExcludeItems and table.HasValue(TRADING.Settings.ExcludeItems, k) then continue end
			if category and not (v.Category == category) then continue end
			if suppress and TradingWindow.YourOffer:HasItem(v.ID) then continue end
			if LocalPlayer():PS_HasItem(v.ID) then
				table.insert(playeritems,v)
			end
		end
	else
		local items = LocalPlayer().PS2_Inventory:getItems()
		for k,v in pairs(items) do
			if TRADING.Settings.ExcludeItems and table.HasValue(TRADING.Settings.ExcludeItems, v:GetPrintName()) then continue end
			if category and not (TRADING.GetItemCategory(v) == category) then continue end
			
			if suppress and TradingWindow.YourOffer:HasItem(v.id) then continue end
			table.insert(playeritems,v)
		end		
	end
	return playeritems
end

function TRADING.OpenPointshopInventory()
	if PSPLUS then
		PSPLUS.OpenMOTD({})
	elseif PS and PS.ShopMenu then
		PS.ShopMenu:Show()
		gui.EnableScreenClicker(true)
	elseif PS then 
		PS:ToggleMenu()
	elseif Pointshop2 then
		Pointshop2:OpenMenu()
	end
end

local function TradingInitPostEntity()
	timer.Simple(5, function()
		local chattext
		if TRADING.Settings.SelectionMenuFKey and (TRADING.Settings.SelectionMenuFKey != "") then
			chattext = string.format(TRADING.Settings.JoinNotificationFKey,TRADING.Settings.SelectionMenuFKey)
		elseif TRADING.ChatCommands and (#TRADING.ChatCommands >= 1) then
			chattext = string.format(TRADING.Settings.JoinNotificationChatCommand,TRADING.ChatCommands[1])
		else return end
		chat.AddText(TRADING.Theme.NotifcationAccentColor,TRADING.Settings.NotificationPrefix,color_white,chattext)
	end)
	
	//Pointshop2 Inventory Panel
	if Pointshop2 then
		Pointshop2:AddInventoryPanel( TRADING.Settings.PS2TradeRequest, "pointshop2/transfer.png", "DPointshopPlayerTradeSelection" )
	end
end
hook.Add("InitPostEntity","TradingInitPostEntity",TradingInitPostEntity)