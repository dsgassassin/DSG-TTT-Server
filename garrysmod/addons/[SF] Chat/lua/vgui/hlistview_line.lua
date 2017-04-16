local PANEL = {}

--[[---------------------------------------------------------
	Name: Init
-----------------------------------------------------------]]
function PANEL:Init()

	self:SetTextInset( 5, 0 )
	self:SetFont( "ColumnFornt" )

end

function PANEL:UpdateColours( skin )

	return self:SetTextStyleColor( Color( 255, 255, 255 ) )

end

function PANEL:GenerateExample()

	// Do nothing!

end

derma.DefineControl( "HListViewLabel", "", PANEL, "DLabel" )

local PANEL = {}

//Derma_Hook( PANEL, "Paint", "Paint", "ListViewLine" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "ListViewLine" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "ListViewLine" )

AccessorFunc( PANEL, "m_iID", "ID" )
AccessorFunc( PANEL, "m_pListView", "ListView" )
AccessorFunc( PANEL, "m_bAlt", "AltLine" )

--[[---------------------------------------------------------
	Name: Init
-----------------------------------------------------------]]
function PANEL:Init()

	self:SetSelectable( true )
	self:SetMouseInputEnabled( true )

	self.Columns = {}
	self.Data = {}

end

--[[---------------------------------------------------------
	Name: OnSelect
-----------------------------------------------------------]]
function PANEL:OnSelect()

	-- For override

end

function PANEL:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 19, 28, 35 ) )
	draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 47, 51, 54 ) )

	if not self:IsHovered() then
		draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 41, 44, 49 ) )
	else
		draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 51, 54, 59 ) )
	end

	local curWide = 0

	for k,v in pairs( self.Columns ) do
		if k % 2 == 1 then
			//if k == 0 then
			if not self:IsHovered() then
				draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 41, 44, 49 ) )
			else
				draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 51, 54, 59 ) )
			end
			if self:IsLineSelected() then
				draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 81, 84, 89 ) )
			end
			//else
			//	draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 51, 54, 255 ) )
			//end
		else
			//if k == 0 then
			if not self:IsHovered() then
				draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 51, 54, 59 ) )
			else
				draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 61, 64, 69 ) )
			end
			if self:IsLineSelected() then
				draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 81, 84, 89 ) )
			end
			//else
			//	draw.RoundedBox( 0, curWide + 2, 2, v:GetWide(), h - 3, Color( 51, 54, 255 ) )
			//end
		end
		curWide = curWide + v:GetWide()
	end
end

--[[---------------------------------------------------------
	Name: OnRightClick
-----------------------------------------------------------]]
function PANEL:OnRightClick()

	-- For override

end

--[[---------------------------------------------------------
   Name: OnMousePressed
-----------------------------------------------------------]]
function PANEL:OnMousePressed( mcode )


	if ( mcode == MOUSE_RIGHT ) then
	
		-- This is probably the expected behaviour..
		if ( !self:IsLineSelected() ) then
		
			self:GetListView():OnClickLine( self, true )
			self:OnSelect()

		end
		
		self:GetListView():OnRowRightClick( self:GetID(), self )
		self:OnRightClick()
		
		return
		
	end

	self:GetListView():OnClickLine( self, true )
	self:OnSelect()

end

--[[---------------------------------------------------------
	Name: OnMousePressed
-----------------------------------------------------------]]
function PANEL:OnCursorMoved()

	if ( input.IsMouseDown( MOUSE_LEFT ) ) then
		self:GetListView():OnClickLine( self )
	end

end

--[[---------------------------------------------------------
	Name: IsLineSelected
-----------------------------------------------------------]]
function PANEL:SetSelected( b )

	self.m_bSelected = b

	-- Update colors of the lines
	for id, column in pairs( self.Columns ) do
		column:ApplySchemeSettings()
	end

end

function PANEL:IsLineSelected()

	return self.m_bSelected

end

--[[---------------------------------------------------------
	Name: SetColumnText
-----------------------------------------------------------]]
function PANEL:SetColumnText( i, strText )

	if ( type( strText ) == "Panel" ) then
	
		if ( IsValid( self.Columns[ i ] ) ) then self.Columns[ i ]:Remove() end
	
		strText:SetParent( self )
		self.Columns[ i ] = strText
		self.Columns[ i ].Value = strText
		return
	
	end

	if ( !IsValid( self.Columns[ i ] ) ) then
	
		self.Columns[ i ] = vgui.Create( "HListViewLabel", self )
		self.Columns[ i ]:SetMouseInputEnabled( false )
	
	end

	self.Columns[ i ]:SetText( tostring( strText ) )
	self.Columns[ i ].Value = strText

	return self.Columns[ i ]

end
PANEL.SetValue = PANEL.SetColumnText

--[[---------------------------------------------------------
	Name: SetColumnText
-----------------------------------------------------------]]
function PANEL:GetColumnText( i )

	if ( !self.Columns[ i ] ) then return "" end

	return self.Columns[ i ].Value

end

PANEL.GetValue = PANEL.GetColumnText

--[[---------------------------------------------------------
	Name: SetSortValue
	Allows you to store data per column
	Used in the SortByColumn function for incase you want to
	sort with something else than the text
-----------------------------------------------------------]]
function PANEL:SetSortValue( i, data )

	self.Data[ i ] = data

end

--[[---------------------------------------------------------
	Name: GetSortValue
-----------------------------------------------------------]]
function PANEL:GetSortValue( i )

	return self.Data[ i ]

end

--[[---------------------------------------------------------
	Name: SetColumnText
-----------------------------------------------------------]]
function PANEL:DataLayout( ListView )

	self:ApplySchemeSettings()

	local height = self:GetTall()

	local x = 0
	for k, Column in pairs( self.Columns ) do
	
		local w = ListView:ColumnWidth( k )
		Column:SetPos( x, 0 )
		Column:SetSize( w, height )
		x = x + w

	end

end

derma.DefineControl( "HListViewLine", "A line from the List View", PANEL, "Panel" )
derma.DefineControl( "HListView_Line", "A line from the List View", PANEL, "Panel" )