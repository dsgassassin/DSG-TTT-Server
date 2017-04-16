local function IconScale(size)
	return math.Clamp(ScreenScale(size), 0, 32), math.Clamp(ScreenScale(size), 0, 32)
end

local SETTINGS_KEY = {}

function SETTINGS_KEY:Init()
	self.Text = ""
end

function SETTINGS_KEY:OnKeyCodePressed(key)
	self.Text = input.GetKeyName(key):upper()
	RunConsoleCommand("tshop_tauntkey", key)
end

function SETTINGS_KEY:Paint(w, h)
		surface.SetDrawColor(Color(236, 240, 241))
		surface.DrawRect(0, 0, w, h)
		draw.NoTexture()
		surface.SetFont("TauntSettingsKey")
		local fw, fh = surface.GetTextSize(self.Text:upper())
		surface.SetTextPos(w / 2 - fw / 2, h / 2 - fh / 2)
		surface.SetTextColor(Color(44, 62, 80))
		surface.DrawText(self.Text:upper())
		return w, h
end

vgui.Register("TauntSettingsKey", SETTINGS_KEY, "EditablePanel")

local function OpenUpSettingsPage()
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(260, 80)
	frame:Center()
	frame:SetTitle("TauntShop Settings")
	frame:ShowCloseButton(false)
	frame:SetBackgroundBlur(true)
	frame:MakePopup()
	
	local textentry = vgui.Create("TauntSettingsKey", frame)
	textentry.Text = input.GetKeyName(GetConVar("tshop_tauntkey"):GetInt()):upper()
	textentry:SetSize(40, 40)
	textentry:SetPos(10, 32)
	textentry:SetVisible(true)
	textentry:RequestFocus()
	
	local desc = vgui.Create("DLabel", frame)
	desc:SetPos(55, 28)
	desc:SetSize(260, 20)
	desc:SetText("Press a button to change your taunt key")
	desc:SetVisible(true)
	
	local button = vgui.Create("DButton", frame)
	button:SetSize(45, 20)
	button:SetPos(210, 55)
	button:SetText("OK")
	button.DoClick = function() frame:Remove() end
	button:SetVisible(true)
	
	return frame

end

local SETTINGS = {}

function SETTINGS:Init()
end

function SETTINGS:Paint(w, h)
	surface.SetDrawColor(Color(236, 240, 241))
	surface.DrawRect(0, 0, w, h)
	surface.SetFont("TauntSettings")
	local fw, fh = surface.GetTextSize("SETTINGS")
	surface.SetTextPos(w / 2 - fw / 2, h / 2 - fh / 2)
	surface.SetTextColor(Color(44, 62, 80))
	surface.DrawText("SETTINGS")
end

function SETTINGS:DoClick()
	local frame = OpenUpSettingsPage()
	self:GetParent()._settingsframe = frame
end

vgui.Register("TauntsSettings", SETTINGS, "Button")

local CLOSE = {}

function CLOSE:Init()
end

function CLOSE:Paint(w, h)
	surface.SetFont("Trebuchet24")
	surface.SetTextColor(Color(236, 240, 241))
	local textw, texth = surface.GetTextSize("X")
	surface.SetTextPos(w - textw, 2 + (h / 2 - texth / 2))
	surface.DrawText("X")
end

function CLOSE:DoClick()
	self:GetParent():SetVisible(false)
	self:GetParent():KillFocus()
	if self:GetParent()._settingsframe then self:GetParent()._settingsframe:Remove() end
end

vgui.Register("TauntsFrameCloseButton", CLOSE, "Button")

local PANEL = {}
 
function PANEL:Init()
	self.created = 0
	self.Entries = {}
	self.Material = Material("pp/blurscreen")
	self.close = vgui.Create("TauntsFrameCloseButton", self)
	self.close:SetText("")
	self.buybutton = vgui.Create("TauntsFrameBuyPage", self)
	self.buybutton:SetText("")
	self.invbutton = vgui.Create("TauntsFrameInvPage", self)
	self.invbutton:SetText("")
	self.shoplist = vgui.Create("TauntsContainer", self)
	self.inventory = vgui.Create("TauntsContainer", self)
	self.inventory:SetVisible(false)
	self.settings = vgui.Create("TauntsSettings", self)
	self.settings:SetText("")
	self.IsSoundPlaying = false
end

/*function PANEL:FixSize()
	surface.SetFont("TauntTitle")
	local w, h = self:GetWide(), self:GetTall()
	local _, top = surface.GetTextSize("TauntShop")
	print((math.Round((ScrH() * 0.8 / 76))))
	local _, start = self.shoplist:GetPos()
	self:SetSize(w, start)
end*/

function PANEL:GetShopContainer()
	return self.shoplist
end

function PANEL:GetInventoryContainer()
	return self.inventory
end

function PANEL:PerformLayout(w, h)
	self.close:SetSize(32, 24)
	self.close:SetPos(w - 36, 1)
	self.close:SetVisible(true)
	self.settings:SetSize(100, 20)
	self.settings:SetPos(w - 300, 0)
	self.settings:SetVisible(true)
	surface.SetFont("TauntTitle")
	local _, top = surface.GetTextSize("TauntShop")
	self.buybutton:SetSize(w / 2 - 10, h / 7)
	self.buybutton:SetPos(5, top)
	self.buybutton:SetVisible(true)
	self.invbutton:SetSize(w / 2 - 10, h / 7)
	self.invbutton:SetPos(w / 2 + 5, top)
	self.invbutton:SetVisible(true)
	self.shoplist:SetSize(self:GetWide() - 10,  self:GetTall() - (top + self:GetTall() / 7 + 10) - 5)
	self.shoplist:SetPos(5, top + self:GetTall() / 7 + 10)
--	self.shoplist:SetVisible(true)
	self.inventory:SetSize(self:GetWide() - 10,  self:GetTall() - (top + self:GetTall() / 7 + 10) - 5)
	self.inventory:SetPos(5, top + self:GetTall() / 7 + 10)
	self:SetPos(ScrW() / 2 - w / 2, ScrH() / 2 - h / 2)
end


function PANEL:Paint(w, h)
	surface.SetMaterial(self.Material)
	surface.SetDrawColor(Color(255, 255, 255, 255))
	local posx, posy = self:GetPos()
	for i = 0.25, 1, 0.25 do --derma_drawbackgroundblur (shamelessly stolen!)
		self.Material:SetFloat( "$blur", 16 * i )
		self.Material:Recompute()
		if ( render ) then render.UpdateScreenEffectTexture() end -- Todo: Make this available to menu Lua
		surface.DrawTexturedRect( posx * -1, posy * -1, ScrW(), ScrH() )
	end
	surface.SetDrawColor(Color(0, 0, 0, 235))
	surface.DrawRect(0, 0, w, h)
	--surface.DrawTexturedRect(posx * -1, posy * -1, ScrW(), ScrH())
	--title
	surface.SetFont("TauntTitle")
	surface.SetTextPos(5, -5)
	surface.SetTextColor(Color(236, 240, 241))
	surface.DrawText("TauntShop")
	local titlew, titleh = surface.GetTextSize("TauntShop")
	--subtitle
	surface.SetFont("TauntSubtitle")
	local _, subh = surface.GetTextSize("Buy your silly sounds here!")
	surface.SetTextPos(titlew + 10, titleh - subh * 2.2)
	surface.SetTextColor(Color(236, 240, 241))
	surface.DrawText("Buy your silly sounds here!")
	--money/points/whatever 
	surface.SetMaterial(Material("icon32/coins.png"))
	surface.SetDrawColor(color_white)
	surface.SetFont("CashFont")
	local pad, th = surface.GetTextSize(": " .. tostring(LocalPlayer():TShopGetPoints()))
	surface.SetTextPos(w - pad - 5, titleh - th - 2)
	pad = pad + IconScale(13) + 2
	surface.DrawTexturedRect(w - pad - 5, titleh - IconScale(13) - 3, IconScale(13))
	surface.DrawText(": " .. tostring(LocalPlayer():TShopGetPoints()))
end

vgui.Register("TauntsFrame", PANEL, "Panel")