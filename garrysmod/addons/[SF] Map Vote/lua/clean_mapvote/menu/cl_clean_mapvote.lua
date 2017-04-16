surface.CreateFont( "CMV_MapName", { font = "Segoe UI Light", size = ScreenScale( 9 ), weight = 0 } )
surface.CreateFont( "CMV_Head", { font = "Segoe UI Light", size = ScreenScale( 24 ), weight = 0 } )
surface.CreateFont( "CMV_Timer", { font = "Roboto Thin", size = ScreenScale( 18 ), weight = 0 } )

local cfg = CMV.Config

CMV.Votes = {}
CMV.Active = false
CMV.WinningMap = ""

for i = 1, cfg.MapAmount do
    table.insert( CMV.Votes, 0 )
end

function CMV:GetVotes()
    CMV.Votes = net.ReadTable()
end
net.Receive( "CMV_Votes", CMV.GetVotes )

function CMV:CreateMapvote( maps )
    CMV.Active = true

    local ply = LocalPlayer()
    local iteration = 0
    local vote = 0
    local endTime = CurTime() + cfg.VoteTime
    local postTime = endTime + cfg.PostVoteTime

    local mapSpacing = {}

    for i = 1, cfg.MapAmount / 2 do
        table.insert( mapSpacing, 1 / ( cfg.MapAmount / 2 + ( 1 ) ) * i )
    end

    local CMVFrame = vgui.Create( "DFrame" )
    CMVFrame:SetSize( ScrW(), ScrH() )
    CMVFrame:Center()
    CMVFrame:SetTitle( "" )
    CMVFrame:SetDraggable( false )
    CMVFrame:ShowCloseButton( cfg.CloseButton )
    CMVFrame:MakePopup()
    CMVFrame.Paint = function( s, w, h )
        Derma_DrawBackgroundBlur( s )

        draw.SimpleText( CurTime() < endTime and cfg.HeadText or "The winning map is " ..  CMV.WinningMap .. "!", "CMV_Head", w / 2, 20, cfg.HeadTextColor, TEXT_ALIGN_CENTER )

        local timeColor = Color( 255, 255, 255 )

        if CurTime() + 5 >= endTime and CurTime() < endTime then
            timeColor = cfg.TimeEndingColor
        elseif CurTime() >= endTime then
            timeColor = cfg.TimeColor
        end

        draw.SimpleText( CurTime() < endTime and string.ToMinutesSecondsMilliseconds( math.Round( endTime - CurTime(), 2 ) ) or "Changing in " .. ( CurTime() < postTime and string.ToMinutesSecondsMilliseconds( math.Round( postTime - CurTime(), 2 ) ) or "00:00:00" ), "CMV_Timer", w / 2, 120, timeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

        local barColor = cfg.TimeBar and HSVToColor( ( ( endTime - CurTime() ) / cfg.VoteTime ) * 100, 1, 1 ) or cfg.BarColor

        draw.RoundedBox( 0, 0, ScrH() - 10, w * ( ( endTime - CurTime() ) / cfg.VoteTime ), 10, barColor )

        if CurTime() > endTime then
            draw.RoundedBox( 0, 100 + ( w * ( postTime - CurTime() ) / cfg.PostVoteTime ), ScrH() - 10, w, 10, barColor )
        end

        if CurTime() >= postTime  then
            s:Remove()
        end
    end
    CMVFrame.OnRemove = function()
        render.ClearStencil()
		hook.Remove( "Think", "CMV_VoiceChat" )
    end

    for _, pos in ipairs( mapSpacing ) do
        iteration = iteration + 1
        for __, space in ipairs( { 1, -1 } ) do
            local currentLoops = space == 1 and iteration or iteration + cfg.MapAmount / 2
            local s = 76561198039443769

            if !maps[ currentLoops ] then return end

            local CMVMap = vgui.Create( "CircleMap", CMVFrame )
            CMVMap:SetSize( ScreenScale( 64 ), ScreenScale( 64 ) )
            CMVMap:SetPos( ScrW() * pos - CMVMap:GetWide() / 2, ScrH() / 2 + CMVMap:GetTall() * space )
            CMVMap:MapURL( cfg.ImageURL .. maps[ currentLoops ] ..".jpg" )
            CMVMap.Button.DoClick = function()
                if !CMV.Active then return end

                ply:ConCommand( "cmv_vote " .. currentLoops )

                vote = currentLoops
				
				if cfg.VoteThenClose then
					CMVFrame:ShowCloseButton( true )
				end
            end
            CMVMap.Think = function( s )
                if !CMV.Active then return end

                s:SetSelected( vote == currentLoops and true or false )
            end

            local CMVMapText = vgui.Create( "DFrame", CMVFrame )
            CMVMapText:SetSize( ScreenScale( 64 ) + ScreenScale( 32 ), ScreenScale( 64 ) )
            CMVMapText:SetPos( ScrW() * pos - CMVMapText:GetWide() / 2, ScrH() / 2 + CMVMapText:GetTall() * space + ( CMVMapText:GetTall() / 2 + 10 ) )
            CMVMapText:SetTitle( "" )
            CMVMapText:SetDraggable( false )
            CMVMapText:ShowCloseButton( false )
            CMVMapText.Paint = function( s, w, h )
				local mapName = maps[ currentLoops ] == game.GetMap() and "Extend Map" or maps[ currentLoops ]
                draw.SimpleText( mapName .. " [" .. CMV.Votes[ currentLoops ] .. "]", "CMV_MapName", w / 2, h / 2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP ) 
            end
            CMVMapText:MoveToBack()
        end
    end
end

function CMV:Voice()
	RunConsoleCommand( input.IsKeyDown( cfg.VoiceKey ) and "+voicerecord" or "-voicerecord" )
end

function CMV:StartMapvote()
    table.Empty( CMV.Votes )

    for i = 1, cfg.MapAmount do
        table.insert( CMV.Votes, 0 )
    end

    CMV:CreateMapvote( net.ReadTable() )
	
	if cfg.VoiceChat then
		hook.Add( "Think", "CMV_VoiceChat", CMV.Voice )
	end
	
	if cfg.PlayMusic then
		sound.PlayURL( table.Random( cfg.MusicURL ), "", function( s )
			timer.Simple( .5, function()
				s:Play()
				s:SetVolume( cfg.Volume / 100 )
			end )
		end )  
	end 
end
net.Receive( "CMV_Start", CMV.StartMapvote )

function CMV:EndMapvote()
    CMV.WinningMap = net.ReadString()
    CMV.Active = false
	
	hook.Remove( "Think", "CMV_VoiceChat" )
end
net.Receive( "CMV_End", CMV.EndMapvote )

function CMV:Inform()
    chat.AddText( cfg.PrefixColor, cfg.Prefix, Color( 255, 255, 255 ), net.ReadString() )
end
net.Receive( "CMV_Inform", CMV.Inform )
