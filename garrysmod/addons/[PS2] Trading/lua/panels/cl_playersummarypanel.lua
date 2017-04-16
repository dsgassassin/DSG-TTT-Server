local PlayerSummaryPanel = {}

function PlayerSummaryPanel:Init()
	self:SetDrawBackground(false)
	//self:SetSize(200, 200)
	self.PlayerIconButton = vgui.Create("DButton",self)
	self.PlayerIconButton:SetSize(64,64)
	self.PlayerIconButton:SetCursor("arrow")
	self.PlayerIcon = vgui.Create("AvatarImage",self.PlayerIconButton)
	self.PlayerIcon:SetSize(64,64)
	self.PlayerIcon:SetMouseInputEnabled( false )
	
	self.TradeTitle = vgui.Create("DLabel",self)
	self.TradeTitle:SetFont("Bebas40Font")
	self.TradeTitle:SetColor(color_white)
	
	self.TradeItemsScroller = vgui.Create("DScrollPanel",self)
	self.TradeItemsScroller.Paint = function(s,w,h)
		surface.SetDrawColor(TRADING.Theme.OutlineColor)
		surface.DrawRect( 0, 0, w, h ) 
		surface.SetDrawColor(TRADING.Theme.WindowColor)
		surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	end
	
	TRADING.EditScrollBarStyle(self.TradeItemsScroller)
	
	self.TradeItems = vgui.Create("DIconLayout",self.TradeItemsScroller)
	self.TradeItems:Dock(FILL)
	self.TradeItems:SetSpaceX(5)
	self.TradeItems:SetSpaceY(5)
	self.TradeItems:SetBorder(5)
end

function PlayerSummaryPanel:SetData(ply, ouroffer)
	self.PlayerIcon:SetPlayer(ply, 84)
	self.OurOffer = ouroffer
	if ouroffer then
		self.TradeTitle:SetText(TRADING.Settings.YourSummaryTitle)
		self.TradeTitle:SizeToContents()
	else
		self.TradeTitle:SetText(string.format(TRADING.Settings.TheirSummaryTitle,ply:Nick()))
		self.TradeTitle:SizeToContents()
		self.PlayerIconButton:SetCursor("hand")
		self.PlayerIconButton.DoClick = function()
			ply:ShowProfile()
		end
	end
end

function PlayerSummaryPanel:AddItem(item, points)
	local TradeSlot = self.TradeItems:Add("TradeItem")
	TradeSlot:SetSize(TRADING.CurrentIconSize,TRADING.CurrentIconSize)
	TradeSlot:SetEmptySlot(true)
	TradeSlot:SetColor(points and TRADING.Theme.TradePointsOutlineColor or TRADING.GetCategoryColor(item.Category, true))
	if points then
		TradeSlot:SetPoints(item)
	else
		TradeSlot:SetData(item)
	end
end

function PlayerSummaryPanel:PerformLayout()
	self.PlayerIconButton:SetPos(0,0)
	self.TradeTitle:SetPos(69, 0)
	self.TradeItemsScroller:SetPos(0, 74)
	self.TradeItemsScroller:SetSize(self:GetWide(), 15 + (TRADING.CurrentIconSize * 2))
 end

function PlayerSummaryPanel:Paint(w,h)
	//surface.SetDrawColor(Color(255,0,0))
	//surface.DrawRect( 0, 0, w, h ) 
end

derma.DefineControl("PlayerSummaryPanel", "", PlayerSummaryPanel, "DPanel")