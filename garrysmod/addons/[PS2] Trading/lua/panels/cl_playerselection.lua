local PlayerSelectionRow = {}

function PlayerSelectionRow:Init()
	self:SetDrawBackground(false)
	self:SetSize(300, 40)
	self:SetText("")
	self.RowColor = TRADING.Theme.ControlColor
	self.HoverColor = TRADING.Theme.OutlineColor
	
	self.PlayerName = vgui.Create("DLabel", self)
	self.PlayerName:SetFont("OpenSans24Font")
	self.PlayerName:SetColor(self.TextColor)
	
	self.SendRequest = vgui.Create("DLabel", self)
	self.SendRequest:SetFont("OpenSans24Font")
	self.SendRequest:SetColor(Color(255,255,255,50))
	self.SendRequest:SetText(TRADING.Settings.SendRequest)
	self.SendRequest:SizeToContents()
	self.SendRequest:SetVisible(false)
	
	self.AvatarImg = vgui.Create("AvatarImage", self)
	self.AvatarImg:SetSize(32,32)

end

function PlayerSelectionRow:SetColor(color)
	if not IsColor(color) then return end
	self.HoverColor = color
end

function PlayerSelectionRow:SetPlayer(ply)
	if not IsValid(ply) then return end
	self.Player = ply
	self.PlayerName:SetText(ply:Nick())
	self.PlayerName:SizeToContents()
	
	self.AvatarImg:SetPlayer(ply, 32)
end

function PlayerSelectionRow:GetPlayer()
	return self.Player
end

function PlayerSelectionRow:PerformLayout()
	if self.AvatarImg then self.AvatarImg:SetPos(5, 4) end
	
	self.PlayerName:SetPos(40, 8)
	self.SendRequest:SetPos(self:GetWide() - self.SendRequest:GetWide() ,8)
 end

function PlayerSelectionRow:Paint()
	surface.SetDrawColor(self.RowColor)
	surface.DrawRect( 0, 0, self:GetWide(), self:GetTall())
	
	if self:IsHovered() then
		surface.SetDrawColor(Color(255,255,255,25))
		surface.DrawRect( 0, 0, self:GetWide(), self:GetTall())
	
		surface.SetDrawColor(self.HoverColor)
		surface.DrawRect( 0, 0, 3, self:GetTall())
	end
end

function PlayerSelectionRow:OnCursorEntered()
	self.SendRequest:SetVisible(true)
end

function PlayerSelectionRow:OnCursorExited()
	self.SendRequest:SetVisible(false)
end
derma.DefineControl("PlayerSelectionRow", "", PlayerSelectionRow, "DButton")

//Pointshop2 Player Selection panel
local PANEL = {}
function PANEL:Init( )
	self:SetDrawBackground(false)
	self:DockPadding( 10, 0, 10, 10 )
	
	self.selectPlyLabel = vgui.Create( "DLabel", self )
	self.selectPlyLabel:Dock( TOP )
	self.selectPlyLabel:SetText(TRADING.Settings.PlayerSelection) 
	self.selectPlyLabel:SizeToContents( )
	self.selectPlyLabel:DockMargin( 5, 5, 5, 10 )
	
	self.selectPlySubtitle = vgui.Create( "DLabel", self )
	self.selectPlySubtitle:Dock( TOP )
	self.selectPlySubtitle:SetText(TRADING.Settings.PlayerSelectionSubtitle) 
	self.selectPlySubtitle:SizeToContents()
	self.selectPlySubtitle:DockMargin( 5, 0, 5, 5 )
	
	self.playerSelector = vgui.Create( "DPointshopPlayerSelect", self )
	self.playerSelector:Dock( FILL )
	//self.playerSelector:SetTall( 10+5*7+8*42 )
	self.playerSelector:ShowAllConncectedPlayers( true )
	function self.playerSelector.OnChange( pnl, ply )
		for k,v in pairs(pnl.playerLookup) do v.Selected = nil end
		RunConsoleCommand("_TradeRequest",ply:UserID())
		Pointshop2:CloseMenu()
	end
end

function PANEL:ApplySchemeSettings( )
	self.selectPlyLabel:SetFont( self:GetSkin().SmallTitleFont )
	self.selectPlyLabel:SetColor( self:GetSkin().Colours.Label.Bright )
	self.selectPlyLabel:SizeToContents( )
	
	//self.selectPlySubtitle:SetFont( "Default" )
	self.selectPlySubtitle:SetColor( self:GetSkin().Colours.Label.Bright )
	self.selectPlySubtitle:SizeToContents( )
end
vgui.Register( "DPointshopPlayerTradeSelection", PANEL, "DPanel" )