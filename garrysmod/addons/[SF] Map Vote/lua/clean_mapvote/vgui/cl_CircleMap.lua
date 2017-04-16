local PANEL = {}

function PANEL:Init()
    self.HTML = vgui.Create( "DHTML", self )

    self.Button = vgui.Create( "DButton", self.HTML )
end

function PANEL:MapURL( url )
    self.HTML:SetHTML( [[
        <style>
            html {
                overflow-y: hidden;
                overflow-x: hidden;
            }

            img {
                width: ]] .. self:GetWide() ..  [[px;
                height:]] .. self:GetTall() .. [[px;
            }

        </style>

        <img src="]] .. url .. [[" onerror="if (this.src != 'http://image.www.gametracker.com/images/maps/160x120/nomap.jpg' ) this.src='http://image.www.gametracker.com/images/maps/160x120/nomap.jpg';">
    ]] )

end

function PANEL:SetSelected( bool )
    self.Selected = bool
end

function PANEL:PerformLayout()
    self.HTML:SetSize( self:GetWide(), self:GetTall() )

    self.Button:SetSize( self:GetWide(), self:GetTall() )
    self.Button:SetPos( 0, 0 )
    self.Button:SetText( "" )

    local circleSize = 0
	local selectedColor = 0

    self.Button.Paint = function( s, w, h )		
		circleSize = Lerp( FrameTime() * 7, circleSize, s.Hovered and w / 2 or 0 )
		selectedColor = Lerp( FrameTime() * 2, selectedColor, self.Selected and 360 or 0 )	
	
        surface.CreateCircle( w / 2, h / 2, circleSize, Color( 0, 0, 0, 150 ) )
		
        if self.Selected then
            surface.CreateCircle( w / 2, h / 2, w / 2, Color( 0, 0, 0, 230 ) )
            draw.SimpleText( "✓", "CMV_Head", w / 2, h / 2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			draw.Arc( w / 2, h / 2, ( w / 2 ) - 7, 5, 0, 360, 5, Color( 100, 255, 100, selectedColor ), true )
        end
    end
    self.Button:MoveToBack()
end

function PANEL:Paint( w, h )
    render.ClearStencil()
    render.SetStencilEnable( true )

    render.SetStencilWriteMask( 1 )
    render.SetStencilTestMask( 1 )

    render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
    render.SetStencilPassOperation( STENCILOPERATION_ZERO )
    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
    render.SetStencilReferenceValue( 1 )

    surface.CreateCircle( w / 2, h / 2, ( w / 2 ) - 8, Color( 0, 0, 0 ) )

    render.SetStencilFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
    render.SetStencilReferenceValue( 1 )
end

vgui.Register( "CircleMap", PANEL )
