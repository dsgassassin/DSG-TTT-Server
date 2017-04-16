local PlayerTradePanel = {}

function PlayerTradePanel:Init()
	self:SetDrawBackground(false)
	//self:SetSize(200, 200)
	self.StatusCode = 1 //1 Not ready, 2 Items but not ready, 3 ready
	self.StatusColor = Color(255,255,255,10)

	self.PlayerIconButton = vgui.Create("DButton",self)
	self.PlayerIconButton:SetSize(64,64)
	self.PlayerIconButton:SetCursor("arrow")
	self.PlayerIcon = vgui.Create("AvatarImage",self.PlayerIconButton)
	self.PlayerIcon:SetSize(64,64)
	self.PlayerIcon:SetMouseInputEnabled( false )
	
	self.TradeTitle = vgui.Create("DLabel",self)
	self.TradeTitle:SetFont("Bebas40Font")
	self.TradeTitle:SetColor(color_white)
	
	self.TradeSubtitle = vgui.Create("DLabel",self)
	self.TradeSubtitle:SetFont("OpenSans24Font")
	
	self.TradeItemsScroller = vgui.Create("DScrollPanel",self)
	self.TradeItemsScroller.Paint = function(s,w,h)
		surface.SetDrawColor(TRADING.Theme.OutlineColor)
		surface.DrawRect( 0, 0, w, h ) 
		surface.SetDrawColor(TRADING.Theme.WindowColor)
		surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	end
	self.TradeItemsScroller.PaintOver = function(s,w,h)
		if self.Disabled then
			surface.SetDrawColor(Color(0,0,0,150))
			surface.DrawRect( 0, 0, w, h ) 
		end
	end
	
	TRADING.EditScrollBarStyle(self.TradeItemsScroller)
	
	self.TradeItems = vgui.Create("DIconLayout",self.TradeItemsScroller)
	self.TradeItems:Dock(FILL)
	self.TradeItems:SetSpaceX(5)
	self.TradeItems:SetSpaceY(5)
	self.TradeItems:SetBorder(5)
end

function PlayerTradePanel:SetData(ply, ouroffer)
	self.PlayerIcon:SetPlayer(ply, 84)
	self.OurOffer = ouroffer
	if ouroffer then
		self.TradeTitle:SetText(TRADING.Settings.YourOfferTitle)
		self.TradeTitle:SizeToContents()
		self.TradeSubtitle:SetText(TRADING.Settings.YourOfferSubtitle)
		self.TradeSubtitle:SizeToContents()
		self.StatusText = TRADING.Settings.NoItemsStatus
		
		self.ReadyCheckbox = vgui.Create("DCheckBox",self)
		self.ReadyCheckbox:SetSize(26,26)
		self.ReadyCheckbox.Paint = function(s,w,h)
			draw.RoundedBox( 4, 0, 0, w, h, TRADING.Theme.ControlColor ) 
			if s:GetChecked() then
				draw.SimpleText("✔","Bebas40Font",1,-8,color_white)
			end
		end
		self.ReadyCheckbox:SetVisible(false)
		self.ReadyCheckbox.OnChange = function(s, checked)
			TRADING.ChangeReadyStatus(checked)
			self.OfferChanged = false
		end
	else
		self.TradeTitle:SetText(string.format(TRADING.Settings.TheirOfferTitle,ply:Nick()))
		self.TradeTitle:SizeToContents()
		self.TradeSubtitle:SetText(TRADING.Settings.TheirOfferSubtitle)
		self.TradeSubtitle:SizeToContents()
		self.StatusText = TRADING.Settings.NotReadyStatus
		
		self.PlayerIconButton:SetCursor("hand")
		self.PlayerIconButton.DoClick = function()
			ply:ShowProfile()
		end
	end
	
	for i=1,TRADING.Settings.DefaultTradeSlots,1 do
		local TradeSlot = self.TradeItems:Add("TradeItem")
		TradeSlot:SetSize(TRADING.CurrentIconSize,TRADING.CurrentIconSize)
		TradeSlot:SetEmptySlot(true, self.OurOffer)
	end	
	
	if self.OurOffer then
		self:Receiver("TradeItem", self.DropItem)
	end
end

function PlayerTradePanel:DropItem(panels, dropped)
	if IsValid(panels[1]) and dropped then
		local itemid = panels[1]:GetData()
		TRADING.OfferTradeItem(itemid, true)
	end
end

function PlayerTradePanel:AddItem(item, points, uniqueid)
	//Find first empty trade slot
	local slot
	local empty = 0
	for k,v in ipairs(self.TradeItems:GetChildren()) do
		if v:IsEmpty() and not slot then slot = v
		elseif v:IsEmpty() then empty = (empty + 1) end
	end
	if not self.OurOffer then slot:FadeInAnimation() end
	slot:SetColor(points and TRADING.Theme.TradePointsOutlineColor or TRADING.GetCategoryColor(item.Category, true))
	
	if points then
		slot:SetPoints(item)
	else
		slot:SetData(item)
		if uniqueid then slot.UniqueID = uniqueid end
	end
	if (empty <= 1) then
		//We'll have to recreate all the children, in-case one was dragged, bug?
		local previousdata = {}
		for k,v in pairs(self.TradeItems:GetChildren()) do
			if v:GetData() then
				table.insert(previousdata, {data = v:CopyData(), points = v:IsPointsSlot(), uid = v:GetUID()})
			end
		end
		self.TradeItems:Clear()
		for k,v in pairs(previousdata) do
			local TradeSlot = self.TradeItems:Add("TradeItem")
			TradeSlot:SetSize(TRADING.CurrentIconSize,TRADING.CurrentIconSize)
			TradeSlot:SetEmptySlot(true, self.OurOffer)
			TradeSlot:SetColor(v.points and TRADING.Theme.TradePointsOutlineColor or TRADING.GetCategoryColor(v.data.Category, true))
			if v.points then
				TradeSlot:SetPoints(v.data)
			else
				TradeSlot:SetData(v.data)
				if v.uid then TradeSlot.UniqueID = v.uid end
			end
		end
		
		for i=1,(math.Round(TRADING.Settings.DefaultTradeSlots / 2) + 1),1 do
			local TradeSlot = self.TradeItems:Add("TradeItem")
			TradeSlot:SetSize(TRADING.CurrentIconSize,TRADING.CurrentIconSize)
			TradeSlot:SetEmptySlot(true, self.OurOffer)
		end
		local scroll = self.TradeItemsScroller.VBar:GetScroll()
		self.TradeItemsScroller.VBar:SetEnabled(false)
		self.TradeItemsScroller.VBar:SetEnabled(true)
		self.TradeItemsScroller.VBar:SetScroll(scroll)
		self.TradeItemsScroller.VBar:AnimateTo(self.TradeItemsScroller.pnlCanvas:GetTall(), 0.5, 0.2)
	end
end

function PlayerTradePanel:RemoveItem(item, points, uniqueid)
	//Find matching item slot
	local empty = 1
	local removerow
	for k,v in pairs(self.TradeItems:GetChildren()) do
		if ((points and v:IsPointsSlot()) or (!points and v:GetData() == (PS and item.ID or uniqueid or item.id))) then v:SetEmptySlot(true) v.Removing = true
		elseif v:IsEmpty() then empty = (empty + 1) end
	end
	if (empty >= math.Round(TRADING.Settings.DefaultTradeSlots / 2) + 2) and ((#self.TradeItems:GetChildren() - 1) > TRADING.Settings.DefaultTradeSlots) then
		removerow = true
	end
	
	//We'll have to recreate all the children, in-case one was dragged, bug?
	local previousdata = {}
	for k,v in pairs(self.TradeItems:GetChildren()) do
		if removerow and (k > (#self.TradeItems:GetChildren() - math.Round(TRADING.Settings.DefaultTradeSlots / 2))) then break end
		table.insert(previousdata, {data = v:CopyData(), points = v:IsPointsSlot(), empty = v:IsEmpty(), uid = v:GetUID()})
	end
	self.TradeItems:Clear()	
	for k,v in pairs(previousdata) do
		if not v.empty then
			local TradeSlot = self.TradeItems:Add("TradeItem")
			TradeSlot:SetSize(TRADING.CurrentIconSize,TRADING.CurrentIconSize)
			TradeSlot:SetEmptySlot(true, self.OurOffer)
			TradeSlot:SetColor(v.points and TRADING.Theme.TradePointsOutlineColor or TRADING.GetCategoryColor(v.data.Category, true))
			if v.points then
				TradeSlot:SetPoints(v.data)
			else
				TradeSlot:SetData(v.data)
				if v.uid then TradeSlot.UniqueID = v.uid end
			end
		end
	end
	//Add empty slots to end
	for k,v in pairs(previousdata) do
		if  v.empty then
			local TradeSlot = self.TradeItems:Add("TradeItem")
			TradeSlot:SetSize(TRADING.CurrentIconSize,TRADING.CurrentIconSize)
			TradeSlot:SetEmptySlot(true, self.OurOffer)
		end
	end
	
	if removerow then
		self.TradeItemsScroller.VBar:SetEnabled(false)
		self.TradeItemsScroller.VBar:SetEnabled(true)
	end
end

function PlayerTradePanel:GetItems()
	local items = {}
	for k,v in pairs(self.TradeItems:GetChildren()) do
		if v:GetData() and not v.Removing then
			table.insert(items, {data = v:CopyData(), points = v:IsPointsSlot()})
		end
	end	
	return items
end

function PlayerTradePanel:HasItem(itemid)
	for k,v in pairs(self.TradeItems:GetChildren()) do
		if not v.Removing and not v:IsPointsSlot() and (v:GetData() == itemid) then return true end
	end
end

function PlayerTradePanel:HasItems()
	for k,v in pairs(self.TradeItems:GetChildren()) do
		if v:GetData() and not v.Removing then return true end
	end
end

function PlayerTradePanel:HasPoints()
	for k,v in pairs(self.TradeItems:GetChildren()) do
		if not v.Removing and v:IsPointsSlot() then return true end
	end
end

function PlayerTradePanel:SetStatus(statuscode)
	self.StatusCode = statuscode
	if self.OurOffer then
		if (statuscode == 1) then
			self.StatusText = TRADING.Settings.NoItemsStatus
			self.StatusColor = Color(255,255,255,10)
			self.ReadyCheckbox:SetVisible(false)
			self.ReadyCheckbox:SetChecked(false)
		elseif (statuscode == 2) then
			self.StatusText = TRADING.Settings.CheckReadyStatus
			self.StatusColor = Color(72,108,143)
			self.ReadyCheckbox:SetVisible(true)
			self.ReadyCheckbox:SetChecked(false)
		else
			self.StatusText = TRADING.Settings.ReadyStatus
			self.StatusColor = Color(99,137,41)
			self.ReadyCheckbox:SetVisible(true)
		end
	else
		if (statuscode == 2) then
			self.StatusText = TRADING.Settings.NotReadyStatus
			self.StatusColor = Color(255,255,255,10)
		else
			self.StatusText = TRADING.Settings.ReadyStatus
			self.StatusColor = Color(99,137,41)
		end
	end
end

function PlayerTradePanel:GetStatus()
	return self.StatusCode
end

function PlayerTradePanel:ShowOfferChanged(changed)
	self.OfferChanged = changed
end

function PlayerTradePanel:SetDisabled(disabled)
	self.Disabled = disabled
	if disabled and self.OurOffer then
		for k,v in pairs(self.TradeItems:GetChildren()) do
			v.m_DragSlot = nil
		end
	elseif self.OurOffer then
		for k,v in pairs(self.TradeItems:GetChildren()) do
			v:Droppable("TradeOfferItem")
		end
	end
end

function PlayerTradePanel:PerformLayout()
	self.PlayerIconButton:SetPos(0,0)
	self.TradeTitle:SetPos(69, 0)
	self.TradeSubtitle:SetPos(69, 32)
	self.TradeItemsScroller:SetPos(0, 74)
	self.TradeItemsScroller:SetSize(self:GetWide(), 15 + (TRADING.CurrentIconSize * 2))
	if self.ReadyCheckbox then self.ReadyCheckbox:SetPos(5, 81 + self.TradeItemsScroller:GetTall()) end
 end

function PlayerTradePanel:Paint(w,h)
	//Trade status box
	draw.RoundedBox( 4, 0, 79 + self.TradeItemsScroller:GetTall(), w, 30, self.StatusColor ) 
	draw.SimpleText( self.StatusText, "OpenSans24Font", self.ReadyCheckbox and self.ReadyCheckbox:IsVisible() and 36 or 5, self.TradeItemsScroller:GetTall() + 82, Color(209,209,209) ) 
	if self.OfferChanged and (self:GetStatus() == 2) then
		surface.SetFont("OpenSans24Font")
		local tw,th = surface.GetTextSize(TRADING.Settings.OfferChanged)
		draw.SimpleText( TRADING.Settings.OfferChanged, "OpenSans24Font", self:GetWide() - (tw + 5), self.TradeItemsScroller:GetTall() + 82, Color(255,77,77) )
	end
	
	if not self.OurOffer and dragndrop.IsDragging() then
		self:SetAlpha(25)
	else self:SetAlpha(255) end
end

derma.DefineControl("PlayerTradePanel", "", PlayerTradePanel, "DPanel")