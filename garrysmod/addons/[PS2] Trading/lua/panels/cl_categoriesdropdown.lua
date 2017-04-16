local PANEL = {}
--[[---------------------------------------------------------
   Name: Init
-----------------------------------------------------------]]
function PANEL:Init()
	self:SetDrawBackground(false)
	
	self.ArrowIcon = vgui.Create("DLabel", self)
	self.ArrowIcon:SetText("▼")
	self.ArrowIcon:SizeToContents()
	
	self.CategoryIcon = vgui.Create("DImage", self)
	self.CategoryIcon:SetSize(32,32)
	
	self:SetTall( 40 )
	self:Clear()

	self:SetContentAlignment( 4 )
	self:SetTextInset( 40, 0 )
	self:SetTextColor(Color(209,209,209))
	self:SetIsMenu( true )
end

--[[---------------------------------------------------------
   Name: Clear
-----------------------------------------------------------]]
function PANEL:Clear()

	self:SetText( "" )
	self.Choices = {}
	self.Data = {}

	if ( self.Menu ) then
		self.Menu:Remove()
		self.Menu = nil
	end
	
end

--[[---------------------------------------------------------
   Name: GetOptionText
-----------------------------------------------------------]]
function PANEL:GetOptionText( id )

	return self.Choices[ id ]

end

--[[---------------------------------------------------------
   Name: GetOptionData
-----------------------------------------------------------]]
function PANEL:GetOptionData( id )

	return self.Data[ id ][1]

end

--[[---------------------------------------------------------
   Name: PerformLayout
-----------------------------------------------------------]]
function PANEL:PerformLayout(w,h)
	self.CategoryIcon:SetPos(5,4)
	self.ArrowIcon:SetPos(w - 15, (h / 2) - (self.ArrowIcon:GetTall() / 2))
end

--[[---------------------------------------------------------
   Name: ChooseOption
-----------------------------------------------------------]]
function PANEL:ChooseOption( value, index )

	if ( self.Menu ) then
		self.Menu:Remove()
		self.Menu = nil
	end
	
	if self.Data[index][3] then
		self:OnSelect( index, value, self.Data[index][1] )
		return
	end

	self:SetText( value )
	self.CategoryIcon:SetImage(self.Data[index][2])
	
	self.selected = index
	self:OnSelect( index, value, self.Data[index][1] )
	
end

--[[---------------------------------------------------------
   Name: ChooseOptionID
-----------------------------------------------------------]]
function PANEL:ChooseOptionID( index )

	local value = self:GetOptionText( index )
	self:ChooseOption( value, index )

end

--[[---------------------------------------------------------
   Name: GetSelected
-----------------------------------------------------------]]
function PANEL:GetSelectedID()

	return self.selected

end



--[[---------------------------------------------------------
   Name: GetSelected
-----------------------------------------------------------]]
function PANEL:GetSelected()
	
	if ( !self.selected ) then return end
	
	return self:GetOptionText(self.selected), self:GetOptionData(self.selected)
	
end


--[[---------------------------------------------------------
   Name: OnSelect
-----------------------------------------------------------]]
function PANEL:OnSelect( index, value, data )

	-- For override

end

--[[---------------------------------------------------------
   Name: AddChoice
-----------------------------------------------------------]]
function PANEL:AddChoice( value, data, icon, pointsbutton, select )

	local i = table.insert( self.Choices, value )

	if ( data ) then
		self.Data[ i ] = {data,icon,pointsbutton}
	end

	if ( select ) then

		self:ChooseOption( value, i )

	end
	
	return i

end

function PANEL:IsMenuOpen()

	return IsValid( self.Menu ) && self.Menu:IsVisible()

end

function PANEL:Paint(w,h)
	surface.SetDrawColor(TRADING.Theme.OutlineColor)
	surface.DrawRect( 0, 0, w, h ) 
	surface.SetDrawColor(TRADING.Theme.WindowColor)
	surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	if self:IsHovered() and not self:GetDisabled() then
		surface.SetDrawColor(Color(255,255,255,20))
		surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	end
	//Arrow
	surface.SetDrawColor(TRADING.Theme.OutlineColor)
	surface.DrawRect( w - 20, 0, 1, h ) 
	surface.SetDrawColor(TRADING.Theme.ControlColor)
	surface.DrawRect( w - 19, 1, 18, h - 2 ) 
end

function PANEL:PaintOver(w,h)
	if self:GetDisabled() then
		surface.SetDrawColor(Color(0,0,0,150))
		surface.DrawRect( 0,0,w,h ) 
	end
end

--[[---------------------------------------------------------
   Name: OpenMenu
-----------------------------------------------------------]]
function PANEL:OpenMenu( pControlOpener )

	if ( pControlOpener ) then
		if ( pControlOpener == self.TextEntry ) then
			return
		end
	end

	-- Don't do anything if there aren't any options..
	if ( #self.Choices == 0 ) then return end
	
	-- If the menu still exists and hasn't been deleted
	-- then just close it and don't open a new one.
	if ( IsValid( self.Menu ) ) then
		self.Menu:Remove()
		self.Menu = nil
	end

	self.Menu = vgui.Create("DListLayout")
	self.Menu:SetParent(self:GetParent())
	local x,y = self:GetPos()
	self.Menu:SetPos(x,y+self:GetTall())
	self.Menu:SetSize(self:GetWide(), 40 * #self.Choices)
	self.Menu.Paint = function(s,w,h)
		surface.SetDrawColor(TRADING.Theme.OutlineColor)
		surface.DrawRect( 0, 0, w, h ) 
		surface.SetDrawColor(TRADING.Theme.WindowColor)
		surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	end
	
	for k,v in pairs(self.Choices) do
		if k == self.selected then continue
		elseif self.Data[k][3] and TradingWindow.YourOffer:HasPoints() then continue end
		
		local Category = self.Menu:Add("DropdownButton")
		Category:SetText(v)
		Category:SetIcon(self.Data[k][2])
		Category.DoClick = function()
			self:ChooseOption( v, k )
		end
	end
end

function PANEL:CloseMenu()

	if ( IsValid( self.Menu ) ) then
		self.Menu:Remove()
	end
	
end

function PANEL:SetValue( strValue )

	self:SetText( strValue )

end

function PANEL:DoClick()

	if ( self:IsMenuOpen() ) then
		return self:CloseMenu()
	end
	
	self:OpenMenu()

end

derma.DefineControl( "CategoriesDropdown", "", PANEL, "DButton" )

--Category dropdown button
local DropdownButton = {}

function DropdownButton:Init()
	self:SetDrawBackground(false)
	self:SetDrawBorder(false)
	self:SetTall(40)
	
	self.CategoryIcon = vgui.Create("DImage", self)
	self.CategoryIcon:SetSize(32,32)
	
	self:SetContentAlignment( 4 )
	self:SetTextInset( 40, 0 )
	self:SetTextColor(Color(209,209,209))
	self:SetIsMenu( true )
	self:SetFont("OpenSans30Font")
end

function DropdownButton:PerformLayout()
	self.CategoryIcon:SetPos(5,4)
end

function DropdownButton:Paint(w,h)
	surface.SetDrawColor(TRADING.Theme.OutlineColor)
	surface.DrawRect( 0, 0, w, h ) 
	
	surface.SetDrawColor(TRADING.Theme.WindowColor)
	surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	
	if self:IsHovered() then
		surface.SetDrawColor(Color(255,255,255,20))
		surface.DrawRect( 1, 1, w - 2, h - 2 ) 
	end
end

function DropdownButton:SetIcon(icon)
	self.CategoryIcon:SetImage(icon)
end

derma.DefineControl("DropdownButton", "", DropdownButton, "DButton")