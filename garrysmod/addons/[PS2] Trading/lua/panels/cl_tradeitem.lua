local TradeItem = {}

function TradeItem:Init()
	self:SetDrawBackground(false)
	self:SetDrawBorder(false)
	self:SetSize(90, 90)
	self:SetText("")
	
	self.BackColor = TRADING.Theme.ControlColor
	self.TypeColor = TRADING.Theme.OutlineColor
end

function TradeItem:SetData(data,inventoryitem)
	self.Data = data
	self.EmptySlot = false
	
	self.InventoryItem = true
	if inventoryitem then 
		self:Droppable("TradeItem") 
		self.DoDoubleClick = function()
			if TRADING.IsPlayerReady() then return end
			TRADING.OfferTradeItem(PS and data.ID or data.id)
		end
	elseif self.OurOfferSlot then
		self:Droppable("TradeOfferItem") 
		self.DoDoubleClick = function()
			TRADING.RemoveOfferTradeItem(PS and data.ID or data.id)
		end
	end
	
	if Pointshop2 then
		if data.class then
		self.DImageButton = data:getCrashsafeIcon()
		self.DImageButton:SetParent(self)
		self.DImageButton:SetSize(self:GetSize())
		self.DImageButton:SetCursor("hand")
		else
			self.DImageButton = vgui.Create( data:GetConfiguredIconControl( ), self )
			self.DImageButton:SetItemClass( data )
			self.DImageButton:SetSize(self:GetSize())
			self.DImageButton:SetCursor("hand")
		end
		
		function self.DImageButton:DoDoubleClick()
			self:GetParent():DoDoubleClick()
		end
		
		function self.DImageButton:OnCursorEntered()
			self:GetParent():OnCursorEntered()
		end
		
		function self.DImageButton:OnCursorExited()
			self:GetParent():OnCursorExited()
		end
		self.DImageButton:SetDragParent(self)
	elseif data.Model then
		self.DModelPanel = vgui.Create("DModelPanel", self)
		self.DModelPanel:SetModel(data.Model)
		
		self.DModelPanel:SetSize(self:GetSize())
		
		if data.Skin then
			self.DModelPanel:SetSkin(data.Skin)
		end
		
		local PrevMins, PrevMaxs = self.DModelPanel.Entity:GetRenderBounds()
		self.DModelPanel:SetCamPos(PrevMins:Distance(PrevMaxs) * Vector(0.5, 0.5, 0.5))
		self.DModelPanel:SetLookAt((PrevMaxs + PrevMins) / 2)
		
		function self.DModelPanel:LayoutEntity(ent)
			if self:IsHovered() and not self:GetParent():IsDragging() then
				ent:SetAngles(Angle(0, ent:GetAngles().y + 2, 0))
			end
			
			local ITEM = PS.Items[data.ID]	
			ITEM:ModifyClientsideModel(LocalPlayer(), ent, Vector(), Angle())
		end
		
		function self.DModelPanel:DoDoubleClick()
			self:GetParent():DoDoubleClick()
		end
		
		function self.DModelPanel:OnCursorEntered()
			self:GetParent():OnCursorEntered()
		end
		
		function self.DModelPanel:OnCursorExited()
			self:GetParent():OnCursorExited()
		end
		
		function self.DModelPanel:DrawModel()
			local curparent = self
			local rightx = self:GetWide()
			local leftx = 0
			local topy = 0
			local bottomy = self:GetTall()
			local previous = curparent
			while( curparent:GetParent() != nil ) do
				curparent = curparent:GetParent()
				local x, y = previous:GetPos()
				topy = math.Max( y, topy + y )
				leftx = math.Max( x, leftx + x )
				bottomy = math.Min( y + previous:GetTall(), bottomy + y )
				rightx = math.Min( x + previous:GetWide(), rightx + x )
				previous = curparent
			end
			if self:GetParent():IsDragging() then
				self.Entity:DrawModel()
			else
				render.SetScissorRect( leftx, topy, rightx, bottomy, true )
				self.Entity:DrawModel()
				render.SetScissorRect( 0, 0, 0, 0, false )
			end
		end
		self.DModelPanel:SetDragParent(self)
	else
		self.DImageButton = vgui.Create('DImageButton', self)
		self.DImageButton:SetMaterial(data.Material)
		if data.RandomColor then self.DImageButton.m_Image:SetImageColor(Color(math.random(1,255),math.random(1,255),math.random(1,255))) end
		self.DImageButton:SetSize(self:GetSize())
		
		function self.DImageButton:DoDoubleClick()
			self:GetParent():DoDoubleClick()
		end
		
		function self.DImageButton:OnCursorEntered()
			self:GetParent():OnCursorEntered()
		end
		
		function self.DImageButton:OnCursorExited()
			self:GetParent():OnCursorExited()
		end
		self.DImageButton:SetDragParent(self)
	end
	
	self:SetTooltip(PS and data.Name or data:GetPrintName())
	
	if data.Color then self:SetColor(data.Color) end
end

function TradeItem:SetPoints(points)
	self.PointsSlot = true
	self.EmptySlot = false
	self.Data = points
	
	if self.OurOfferSlot then
		self:Droppable("TradeOfferItem") 
		self.DoDoubleClick = function()
			TRADING.OfferPointsTrade(0)
		end	
	end
	
	self.DImageButton = vgui.Create('DImageButton', self)
	self.DImageButton:SetMaterial(TRADING.Theme.TradePointsIcon)
	local w,h = self:GetSize()
	self.DImageButton:SetSize((w / 4), (w / 4))
	self.DImageButton:Center()
	function self.DImageButton:DoDoubleClick()
		self:GetParent():DoDoubleClick()
	end
	
	function self.DImageButton:OnCursorEntered()
		self:GetParent():OnCursorEntered()
	end
	
	function self.DImageButton:OnCursorExited()
		self:GetParent():OnCursorExited()
	end
	self.DImageButton:SetDragParent(self)	
	
	self:SetTooltip(string.format("%s %s",string.Comma(points),TRADING.GetPointsName()))
end

function TradeItem:GetData()
	if self.Data then return self.PointsSlot and self.Data or (PS and self.Data.ID or self.UniqueID or self.Data.id) end
end

function TradeItem:GetUID()
	return self.UniqueID
end

function TradeItem:IsPointsSlot()
	return self.PointsSlot
end

function TradeItem:SetEmptySlot(empty, dropitem, summary)
	self.EmptySlot = empty
	self.OurOfferSlot = dropitem
end

function TradeItem:CopyData()
	return self.Data,self.PointsSlot
end

function TradeItem:IsEmpty()
	return self.EmptySlot
end

function TradeItem:FadeInAnimation()
	self.FadeInAlpha = 255
end

function TradeItem:SetColor(color)
	if not IsColor(color) then return end
	self.TypeColor = color
end

function TradeItem:PerformLayout()
	if self.DModelPanel then self.DModelPanel:SetPos(0,0)
	elseif self.DImageButton and not self.PointsSlot then self.DImageButton:SetPos(0,0)
	end
end

function TradeItem:Paint(w,h)
	surface.SetDrawColor(self.TypeColor)
	surface.DrawRect( 0, 0, w, h ) 
	surface.SetDrawColor(self.BackColor)
	surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	if self:IsHovered() and (self.InventoryItem or self.OurOfferSlot) then
		surface.SetDrawColor(Color(255,255,255,20))
		surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	end
end

function TradeItem:PaintOver(w,h)
	if self.FadeInAlpha then
		self.FadeInAlpha = math.Approach( self.FadeInAlpha, 0, FrameTime() * 500 ) 
		surface.SetDrawColor(Color(255,255,255,self.FadeInAlpha))
		surface.DrawRect( 0,0,w,h )
		if (self.FadeInAlpha <= 0) then self.FadeInAlpha = nil end
	end
end

function TradeItem:OnMouseReleased( mousecode )
	if ( self:EndBoxSelection() ) then return end

	self:MouseCapture( false )
	
	if ( self:DragMouseRelease( mousecode ) ) then
		return
	end

end

derma.DefineControl("TradeItem", "", TradeItem, "DButton")