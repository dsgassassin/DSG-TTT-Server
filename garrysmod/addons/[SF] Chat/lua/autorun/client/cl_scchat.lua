print( "Loading Chatbox..." )

local ChatTitle = "Server Chat" -- Change this to your server name.

ClearChat = {}

local cfont
if system.IsWindows() then -- OSX + Linux don't have Tahoma.
	cfont = CreateConVar( "sc_chatbox_font", "Tahoma", FCVAR_ARCHIVE )
else
	cfont = CreateConVar( "sc_chatbox_font", "Arial", FCVAR_ARCHIVE )
end

local csize = CreateConVar( "sc_chatbox_fontsize", 16, FCVAR_ARCHIVE )
local cshadow = CreateConVar( "sc_chatbox_shadow", 1, FCVAR_ARCHIVE )
local cweight = CreateConVar( "sc_chatbox_weight", 1000, FCVAR_ARCHIVE )
local cout = CreateConVar( "sc_chatbox_outline", 0, FCVAR_ARCHIVE )
local caa = CreateConVar( "sc_chatbox_antialias", 1, FCVAR_ARCHIVE )

local x = CreateConVar( "sc_chatpos_x", 20, FCVAR_ARCHIVE )
local y = CreateConVar( "sc_chatpos_y", ScrH() - 400, FCVAR_ARCHIVE )
local sizex = CreateConVar( "sc_chatsize_x", 500, FCVAR_ARCHIVE )
local sizey = CreateConVar( "sc_chatsize_y", 255, FCVAR_ARCHIVE )

local useUrls = CreateConVar( "sc_use_urls", 0, FCVAR_ARCHIVE )

local stayTime = CreateConVar( "sc_chatbox_duration", 10, FCVAR_ARCHIVE )

local timestamp = CreateConVar( "sc_timestamp", 0, FCVAR_ARCHIVE )

local ratedYet = CreateConVar( "cc_gaverating", 0, FCVAR_ARCHIVE, "If this is enabled, you (the person who bought the script) will get a nag screen asking you to rate this addon." )

local rText
local say
local sayit
local show
local lastMessages = {}
local lmIndex = 1

local tags = {}

local plyMeta = FindMetaTable( "Player" )

hook.Add( "InitPostEntity", "NagMeClearChat", function()
	timer.Simple( 180, function()
		if not ratedYet:GetBool() and LocalPlayer():SteamID64() == "76561198039443769" then
			Derma_Query( "Love ClearChat? Leave a 5 star review on our scriptfodder page!", "ClearChat: Rate us!", "Yes!",function() gui.OpenURL( "https://scriptfodder.com/scripts/view/1557/reviews" ) RunConsoleCommand( "cc_gaverating", 1 ) end, "No", function() end, "Don't ask me again", function() RunConsoleCommand( "cc_gaverating", 1 ) end )
		end
	end )
end )

net.Receive( "SendTags", function()
	tags = net.ReadTable()
	PrintTable( tags )
end )

surface.CreateFont( "ChatFont2", {
	font = cfont:GetString(),
	size = csize:GetInt(),
	shadow = cshadow:GetBool(),
	weight = cweight:GetInt(),
	outline = cout:GetBool(),
	antialias = caa:GetBool()
} )

function plyMeta:IsTyping()
	return self:GetNWBool( "Typing" ) -- Fix for certain gamemodes that don't use StartChat
end

function ClearChat.GetTags()
	return tags
end

local function Say(message, team) -- helper function so i can unfuck things if they break
	if team then
		RunConsoleCommand("say_team", message)
	else
		RunConsoleCommand("say", message)
	end
end

hook.Add( "InitPostEntity", "LoadChatTags", function()
	net.Start( "RequestTags" )
	net.SendToServer()

	if DarkRP then -- Hacky fix for darkrp chat tags. Also, can you people please stop renaming your gamemodes. If you have a DarkRP based gamemode that has been renamed that has the no name chat bug, don't expect support.
		local function AddToChat(bits)
			local col1 = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))

			local prefixText = net.ReadString()
			local ply = net.ReadEntity()
			ply = IsValid(ply) and ply or LocalPlayer()
			//print( ply )

			if prefixText == "" or not prefixText then
				prefixText = ""
			end

			prefixText = string.Replace( prefixText, ply:Name(), "" )
			//print( prefixText )

			local col2 = Color( net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) )
			//print( col2 )

			local text = net.ReadString()
			print( text )
			local shouldShow
			if text and text != "" then
				//print( "text exists and is valid" )
				if IsValid(ply) then
					--print( "ply is valid, calling OnPlayerChat" )
					//shouldShow = hook.Call("OnPlayerChat", GAMEMODE, ply, text, false, not ply:Alive(), prefixText, col1, col2)
				end

				//if shouldShow != true then
					//print( "Not showing player (i think)")
					--print( prefixText )
					chat.AddText( col1, prefixText, ply, col2, ": " .. text )
				//end
			else
				//print( "text isnt valid" )
				//shouldShow = hook.Call("ChatText", GAMEMODE, "0", prefixText, prefixText, "none")
				if shouldShow != true then
					chat.AddText( ply, col1, " ", prefixText )
				end
			end
			chat.PlaySound()
		end
		net.Receive("DarkRP_Chat", AddToChat)
	end
end )

-- Hacky DarkRP Fix, stop renaming your gamemodes. 
hook.Add("PlayerCanHearPlayersVoice", "SpawnSpawnHacky", function()
	return true
end)

local function TagEdit()
	local group
	local text
	local color

	local panel = vgui.Create( "HFrame" )
	panel:SetSize( 300, ScrH() - 150 )
	panel:Center()
	panel:SetTitle( "Chat tag editor" )
	panel:MakePopup()

	local scroll = vgui.Create( "DScrollPanel", panel )
	scroll:Dock( FILL )

	local preview = vgui.Create( "RichText", scroll )
	preview:Dock( TOP )
	preview.PerformLayout = function()
		preview:SetFontInternal( "ChatFont2" )
	end
	preview:SetTall( 100 )
	preview.Think = function()
		preview:SetText( "" )
		preview:InsertColorChange( color:GetColor().r, color:GetColor().g, color:GetColor().b, 255 )
		preview:AppendText( text:GetValue() .. " " )
		local col = team.GetColor( LocalPlayer():Team() )
		preview:InsertColorChange( col.r, col.g, col.b, 255 )
		preview:AppendText( LocalPlayer():Nick() .. ": " )
		preview:InsertColorChange( 255, 255, 255, 255 )
		preview:AppendText( "Hi! This is an example message to show you how your chat tag looks!" )
	end

	local select = vgui.Create( "DComboBox", scroll )
	select:Dock( TOP )
	select:SetValue( "Select a chat tag..." )
	for k,v in pairs( tags ) do
		select:AddChoice( k, v )
	end
	select.OnSelect = function( self, index, value, data )
		color:SetColor( data[ 2 ] )
		text:SetValue( data[ 1 ] )
		group:SetValue( value )
	end

	group = vgui.Create( "HTextEntry", scroll )
	group:Dock( TOP )
	group:SetValue( "Group (must be the same as ULX)" )

	text = vgui.Create( "HTextEntry", scroll )
	text:Dock( TOP )
	text:SetValue( "Tag (What people see)" )

	color = vgui.Create( "DColorMixer", scroll )
	color:Dock( TOP )
	color:SetTall( 300 )
	color:SetAlphaBar( false )

	local add = vgui.Create( "HButton", scroll )
	add:Dock( TOP )
	add:SetText( "Add chat tag" )
	add.DoClick = function()
		tags[ group:GetValue() ] = { text:GetValue(), color:GetColor() }
		panel:Remove()
		TagEdit()
	end

	local remove = vgui.Create( "HButton", scroll )
	remove:Dock( TOP )
	remove:SetText( "Remove chat tag" )
	remove.DoClick = function()
		tags[ group:GetValue() ] = nil
		panel:Remove()
		TagEdit()
	end

	local save = vgui.Create( "HButton", scroll )
	save:Dock( TOP )
	save:SetText( "Save Chat Tags" )
	save.DoClick = function()
		net.Start( "SaveTags" )
		net.WriteTable( tags )
		net.SendToServer()
		panel:Remove()
		chat.AddText( "Saved chat tags!" )
	end
end

local function OpenSettingsMenu()
	local panel = vgui.Create( "HFrame" )
	panel:SetSize( 300, ScrH() - 150 )
	panel:Center()
	panel:SetTitle( "Chatbox Settings" )
	panel:MakePopup()

	local scroll = vgui.Create( "DScrollPanel", panel )
	scroll:Dock( FILL )

	local posx = vgui.Create( "DNumSlider", scroll )
	posx:SetConVar( "sc_chatpos_x" )
	posx:Dock( TOP )
	posx:SetMin( 0 )
	posx:SetMax( ScrW() )
	posx:SetText( "X Pos" )
	posx:GetTextArea():SetTextColor( Color( 255, 255, 255 ) )

	local posy = vgui.Create( "DNumSlider", scroll )
	posy:SetConVar( "sc_chatpos_y" )
	posy:Dock( TOP )
	posy:SetMin( 0 )
	posy:SetMax( ScrH() )
	posy:SetText( "Y Pos" )
	posy:GetTextArea():SetTextColor( Color( 255, 255, 255 ) )

	local sizex = vgui.Create( "DNumSlider", scroll )
	sizex:SetConVar( "sc_chatsize_x" )
	sizex:Dock( TOP )
	sizex:SetMin( 0 )
	sizex:SetMax( ScrW() )
	sizex:SetText( "Chatbox Width" )
	sizex:GetTextArea():SetTextColor( Color( 255, 255, 255 ) )

	local sizey = vgui.Create( "DNumSlider", scroll )
	sizey:SetConVar( "sc_chatsize_y" )
	sizey:Dock( TOP )
	sizey:SetMin( 0 )
	sizey:SetMax( ScrH() )
	sizey:SetText( "Chatbox Height" )
	sizey:GetTextArea():SetTextColor( Color( 255, 255, 255 ) )

	local duration = vgui.Create( "DNumSlider", scroll )
	duration:SetConVar( "sc_chatbox_duration" )
	duration:Dock( TOP )
	duration:SetMin( 1 )
	duration:SetMax( 60 )
	duration:SetText( "Message Duration" )
	duration:GetTextArea():SetTextColor( Color( 255, 255, 255 ) )

	local fontText = vgui.Create( "DLabel", scroll )
	fontText:SetFont( "ColumnFornt" )
	fontText:SetText( "Font Name" )
	fontText:SetTextColor( Color( 255, 255, 255 ) )
	fontText:Dock( TOP )

	local font = vgui.Create( "HTextEntry", scroll )
	font:Dock( TOP )
	font.OnValueChange = function( self )
		RunConsoleCommand( "sc_chatbox_font", self:GetValue() )
	end
	font:SetValue( cfont:GetString() )

	local shadow = vgui.Create( "DCheckBoxLabel", scroll )
	shadow:SetText( "Enable font shadow?" )
	shadow:Dock( TOP )
	shadow:SetConVar( "sc_chatbox_shadow" )

	local outline = vgui.Create( "DCheckBoxLabel", scroll )
	outline:SetText( "Enable text outline?" )
	outline:Dock( TOP )
	outline:SetConVar( "sc_chatbox_outline" )

	local weight = vgui.Create( "DNumSlider", scroll )
	weight:SetText( "Font Weight" )
	weight:SetConVar( "sc_chatbox_weight" )
	weight:Dock( TOP )
	weight:SetMin( 100 )
	weight:SetMax( 1000 )
	weight:GetTextArea():SetTextColor( Color( 255, 255, 255 ) )

	local size = vgui.Create( "DNumSlider", scroll )
	size:SetText( "Font Size" )
	size:SetConVar( "sc_chatbox_fontsize" )
	size:Dock( TOP )
	size:SetMin( 1 )
	size:SetMax( 100 )
	size:GetTextArea():SetTextColor( Color( 255, 255, 255 ) )

	local time = vgui.Create( "DCheckBoxLabel", scroll )
	time:SetText( "Add timestamp to chat messages?" )
	time:Dock( TOP )
	time:SetConVar( "sc_timestamp" )

	local savefont = vgui.Create( "HButton", scroll )
	savefont:SetText( "Update Font Settings" )
	savefont:Dock( TOP )
	savefont.DoClick = function()
		RunConsoleCommand( "sc_chatbox_font", font:GetValue() )
		surface.CreateFont( "ChatFont2", {
			font = cfont:GetString(),
			size = csize:GetInt(),
			shadow = cshadow:GetBool(),
			weight = cweight:GetInt(),
			outline = cout:GetBool(),
			antialias = caa:GetBool()
		} )
	end

	if ULib and ULib.ucl.query( LocalPlayer(), "edittags", false ) or LocalPlayer():IsSuperAdmin() then
		local openEditor = vgui.Create( "HButton", scroll )
		openEditor:SetText( "Open chat tag editor" )
		openEditor:Dock( TOP )
		openEditor.DoClick = function()
			TagEdit()
		end
	end
end

hook.Add( "Initialize", "LoadChat", function()
	if chatPanel then chatPanel:Remove() end

	show = false

	chatPanel = vgui.Create( "HFrame" )
	chatPanel:SetPos( x:GetInt(), y:GetInt() )
	chatPanel:SetSize( sizex:GetInt(), sizey:GetInt() )
	chatPanel:SetTitle( "" )
	local oldPaint = chatPanel.Paint
	chatPanel.Paint = function( self, w, h )
		if show then
			oldPaint( self, w, h )
		end
	end
	chatPanel.Button:SetText( "Settings" )
	chatPanel.Button:SizeToContents()
	chatPanel.Button:Hide()
	chatPanel.OnKeyCodePressed = function()
	end
	chatPanel.Think = function( self )
		self:SetPos( x:GetInt(), y:GetInt() )
		self.Button:SetPos( self:GetWide() - self.Button:GetWide() - 6, 0 )
		self:SetWide( sizex:GetInt() )
		self:SetTall( sizey:GetInt() )
	end
	chatPanel.Button.DoClick = function()
		OpenSettingsMenu()
	end

	rText = vgui.Create( "RichText", chatPanel )
	rText:Dock( TOP )
	rText.PerformLayout = function()
		rText:SetFontInternal( "ChatFont2" )
	end
	rText:SetVerticalScrollbarEnabled( false )
	rText.ActionSignal = function( self, name, value )
		if name == "TextClicked" then
			gui.OpenURL( value )
		end
	end
	rText.Think = function( self )
		self:SetTall( chatPanel:GetTall() - 54 )
	end

	say = vgui.Create( "HTextEntry", chatPanel )
	say:Dock( LEFT )
	say:SetWide( 30 )
	say:AlphaTo( 0, 0, 0 )
	say:SetWide( chatPanel:GetWide() - 100 )
	say.OnTextChanged = function( self )
		hook.Call( "ChatTextChanged", GAMEMODE, self:GetValue() )
	end
	say.OnKeyCodeTyped = function( self, key )
		if key == KEY_TAB then
			self:SetText( hook.Call( "OnChatTab", GAMEMODE, self:GetValue() ) )
			timer.Simple( 0.1, function()
				self:RequestFocus()
			end )
		elseif key == KEY_ENTER then
			Say(say:GetValue(), (say.Active != "messagemode"))
			table.insert(lastMessages, say:GetValue())
			RunConsoleCommand( "hidechat" )
		elseif key == KEY_UP then
			if lastMessages[lmIndex] then
				self:SetText(lastMessages[lmIndex])
				if lastMessages[lmIndex + 1] then
					lmIndex = lmIndex + 1
				end
			end
		elseif key == KEY_DOWN then
			if lastMessages[lmIndex] then
				self:SetText(lastMessages[lmIndex])
				if lastMessages[lmIndex - 1] then
					lmIndex = lmIndex - 1
				end
			end
		end
	end
	say:SetFont( "ColumnFornt" )
	say.Think = function()
		say:SetWide( chatPanel:GetWide() - 100 )
	end

	sayit = vgui.Create( "HButton", chatPanel )
	sayit:Dock( FILL )
	sayit:AlphaTo( 0, 0, 0 )
	sayit:SetWide( 64 )
	sayit:SetText( "Say" )
	sayit.DoClick = function()
		--print(say:GetValue())
		Say(say:GetValue(), (say.Active != "messagemode"))
		table.insert(lastMessages, say:GetValue())
		RunConsoleCommand( "hidechat" )
	end
end )

local oldAddText = chat.AddText -- Disable when live editing

function chat.AddText( ... )
	if not IsValid(rText) then
		oldAddText(...)
		return
	end

	local tab = { ... }
	rText:InsertColorChange( 255, 255, 255, 255 )
	if timestamp:GetBool() then
		rText:InsertColorChange( 255, 255, 255, 255 )
		rText:AppendText( "[" .. os.date( "%H:%M:%S", os.time() ) .. "] " )
		rText:InsertFade( stayTime:GetInt(), 2 )
	end
	for k,v in pairs( tab ) do
		if type( v ) == "table" then
			rText:InsertColorChange( v.r, v.g, v.b, 255 )
		elseif type( v ) == "string" then
			if string.find( v, "rgb(", 1, true ) and string.find( v, ")" ) then
				local colstr = string.sub( v, string.find( v, "rgb(", 1, true 	), string.find( v, ")" ) )
				v = string.Replace( v, colstr, "" )
				print( colstr )
				colstr = string.Replace( colstr, "rgb(", "" )
				colstr = string.Replace( colstr, ")", "" )
				print( colstr )
				local col = string.Explode( ",", colstr )
				for k,str in pairs( col ) do
					colstr = string.Replace( colstr, " ", "" )
				end
				PrintTable( col )
				if #col >= 3 then
					rText:InsertColorChange( col[ 1 ], col[ 2 ], col[ 3 ], 255 )
				end
			end
			// TODO: Learn RegEx and make this work
			if string.find( v, "https?://[%w-_%.%?%.:/%+=&]+" ) and useUrls:GetBool() then
				rText:InsertClickableTextStart( v )
				rText:AppendText( v )
				rText:InsertClickableTextEnd()
			else
				rText:AppendText( v )
				rText:InsertFade( stayTime:GetInt(), 2 )
			end
		else
			if IsEntity( v ) and IsValid( v ) and tags[ v:GetUserGroup() ] then
				local cl = tags[ v:GetUserGroup() ][ 2 ]
				rText:InsertColorChange( cl.r, cl.g, cl.b, 255 )
				rText:AppendText( tags[ v:GetUserGroup() ][ 1 ] .. " ")
				rText:InsertFade( stayTime:GetInt(), 2 )
			end
			if IsEntity( v ) and IsValid( v ) then
				local col = team.GetColor( v:Team() )
				rText:InsertColorChange( col.r, col.g, col.b, 255 )
				rText:AppendText( v:Nick() )
				rText:InsertFade( stayTime:GetInt(), 2 )
				rText:InsertColorChange( 255, 255, 255, 255 )
			else -- In the case where a poorly coded addon uses a number instead of a string, we cater for that here.
				rText:AppendText( v )
				rText:InsertFade( stayTime:GetInt(), 2 )
			end
		end
	end
	rText:InsertFade( stayTime:GetInt(), 2 )
	rText:AppendText( "\n" )
	oldAddText( ... )
end

-- Overriding default chat functions, fixes a good few problems with DarkRP
function chat.GetChatBoxPos()
	return x:GetInt(), y:GetInt()
end

function chat.GetChatBoxSize()
	return sizex:GetInt(), sizey:GetInt()
end

function chat.Open()
	RunConsoleCommand( "showchat" )
end

function chat.Close()
	RunConsoleCommand( "hidechat" )
end

concommand.Add( "showchat", function()
	lmIndex = 1
	rText:ResetAllFades( true, false, -2 )
	show = true
	rText:SetVerticalScrollbarEnabled( true )
	gui.EnableScreenClicker( true )
	say:AlphaTo( 255, 0.15, 0 )
	sayit:AlphaTo( 255, 0.15, 0 )
	say:RequestFocus()
	chatPanel:MakePopup()
	chatPanel:SetTitle( ChatTitle )
	if hook.GetTable()[ "StartChat" ] != nil then
		for k,v in pairs( hook.GetTable()[ "StartChat" ] ) do -- Hacky fix for hook.Call not working, look in to this.
			v()
		end
	end
	GAMEMODE:StartChat()
	if say.Active == "messagemode" then
		sayit:SetText( "Say" )
	else
		sayit:SetText( "Say (Team)" )
	end
	chatPanel.Button:Show()
	net.Start( "StartChat" )
	net.SendToServer()
end )

hook.Add( "PlayerBindPress", "SuppressingFire", function( ply, bind, pressed )
	if pressed then
		if ( bind == "messagemode" or bind == "messagemode2" ) and show then
			RunConsoleCommand( "hidechat" )
			return true
		elseif bind == "messagemode" or bind == "messagemode2" then
			say.Active = bind
			RunConsoleCommand( "showchat" )
			return true
		end
	end
end )

hook.Add( "PreRender", "FuckEveryoneWhoDoesntDoThis", function()
	if gui.IsGameUIVisible() and show then
		RunConsoleCommand( "hidechat" )
		gui.HideGameUI()
	end
end )

hook.Add( "ChatText", "GameMessagesInChatbox", function( index, name, text )
	chat.AddText( Color( 151, 210, 254 ), text )
end )

hook.Add( "HUDShouldDraw", "HideNormalChat", function( name )
	if name == "CHudChat" then
		return false
	end
end )

concommand.Add( "hidechat", function()
	rText:ResetAllFades( false, true, 0.35 )
	show = false
	rText:SetVerticalScrollbarEnabled( false )
	gui.EnableScreenClicker( false )
	say:AlphaTo( 0, 0.15, 0 )
	sayit:AlphaTo( 0, 0.15, 0 )
	chatPanel:SetTitle( "" )
	chatPanel:SetMouseInputEnabled( false )
	chatPanel:SetKeyboardInputEnabled( false )
	hook.Call( "FinishChat", GAMEMODE )
	GAMEMODE:FinishChat()
	say:SetText( "" )
	chatPanel.Button:Hide()
	hook.Call( "ChatTextChanged", GAMEMODE, "" )
	net.Start( "EndChat" )
	net.SendToServer()
	rText:GotoTextEnd()
end )	