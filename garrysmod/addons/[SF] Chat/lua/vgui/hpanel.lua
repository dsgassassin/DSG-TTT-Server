local PANEL = {}

surface.CreateFont( "TitleFont2", {
	font = "Tahoma",
	size = 16,
	weight = 500
} )

function PANEL:Init()
	self:DockPadding( 6, 30, 6, 6 )
	self.Button = vgui.Create( "HButton", self )
	self.Button:SetText( "Close" )
	self.Button:SizeToContents()
	self.Button:SetWide( self.Button:GetWide() + 9 )
	self.Button:SetTall( self.Button:GetTall() + 4 )
	self.Button:Center()
	self.Button.DoClick = function()
		self:Remove()
	end

	self.Title = vgui.Create( "DLabel", self )
	self.Title:SetFont( "TitleFont2" )
	self.Title:SetText( "" )
	self.Title:SetPos( 8.5, 5 )

	self.btnClose:Hide()
	self.btnMaxim:Hide()
	self.btnMinim:Hide()
	self.lblTitle:Hide()
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 19, 28, 35 ) )
	draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 47, 51, 54 ) )
	draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 41, 44, 49 ) )
end

function PANEL:ShowCloseButton( bShow )
	if not bShow then self.Button:Hide() return end
	self.Button:Show()
end

function PANEL:SetTitle( title )
	self.Title:SetText( title )
	self.Title:SizeToContents()
end

function PANEL:Think()
	self.Button:SetPos( self:GetWide() - self.Button:GetWide() - 6, 0 )
end

function PANEL:PreformLayout()
	self.Title = vgui.Create( "DLabel", self )
	self.Title:SetFont( "TitleFont2" )
	self.Title:SetText( "" )
	self.Title:SetPos( 8.5, 5 )
	self.Title:SizeToContents()
end

derma.DefineControl( "HFrame", "A better DFrame", PANEL, "DFrame" )

local PANEL = {}

function PANEL:Init()
	self:DockPadding( 6, 6, 6, 6 )
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 19, 28, 35 ) )
	draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 47, 51, 54 ) )
	draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 41, 44, 49 ) )
end

derma.DefineControl( "HPanel", "A better DPanel", PANEL, "DPanel" )

local PANEL = {}

function PANEL:Init()
	//self:DockPadding( 6, 6, 6, 6 )
end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 19, 28, 35 ) )
	draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 47, 51, 54 ) )
	draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 41, 44, 49 ) )
end

derma.DefineControl( "HScrollPanel", "A better DScrollPanel", PANEL, "DScrollPanel" )