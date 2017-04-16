
local BUYPAGE = {}

function BUYPAGE:Init()
	self.IsClicked = true
end

function BUYPAGE:SetClicked(click)
	self.IsClicked = click
end

function BUYPAGE:GetClicked()
	return self.IsClicked
end

function BUYPAGE:OnCursorEntered()
	if self.IsClicked then self:SetCursor("arrow") return end
	self:SetCursor("hand")
	self.Hovered = true
end

function BUYPAGE:OnCursorExited()
	if self.IsClicked then return end
	self.Hovered = false
end

function BUYPAGE:Paint(w, h)
	surface.SetDrawColor(Color(46, 204, 113))
	surface.DrawRect(0, 0, w, h * .66)
	surface.SetDrawColor(Color(39, 174, 96))
	surface.DrawRect(0, h * .66, w, h)
	surface.SetFont("TauntButtonFont")
	surface.SetTextColor(Color(236, 240, 241))
	local textw, texth = surface.GetTextSize("SHOP TAUNTS")
	surface.SetTextPos(w / 2 - textw / 2, h / 2 - texth / 2)
	surface.DrawText("SHOP TAUNTS")
	if self.IsClicked then
		surface.SetDrawColor(Color(0, 0, 0, 160))
		surface.DrawRect(0, 0, w, h)
	end
	if self.Hovered and !self.IsClicked then
		surface.SetDrawColor(Color(255, 255, 255, 50))
		surface.DrawRect(0, 0, w, h)
	end
end

function BUYPAGE:DoClick()
	if self:GetClicked() then return end
	self:SetCursor("arrow")
	self:SetClicked(!self:GetClicked())
	self:GetParent().invbutton:SetClicked(false)
	self:GetParent():GetShopContainer():SetVisible(true)
	self:GetParent():GetInventoryContainer():SetVisible(false)
end

vgui.Register("TauntsFrameBuyPage", BUYPAGE, "Button")

local INVPAGE = {}

function INVPAGE:SetClicked(click)
	self.IsClicked = click
end

function INVPAGE:GetClicked()
	return self.IsClicked
end

function INVPAGE:Init()
	self.IsClicked = false
end

function INVPAGE:OnCursorEntered()
	if self.IsClicked then self:SetCursor("arrow") return end
	self:SetCursor("hand")
	self.Hovered = true
end

function INVPAGE:OnCursorExited()
	if self.IsClicked then return end
	self.Hovered = false
end

function INVPAGE:Paint(w, h)
	surface.SetDrawColor(Color(231, 76, 60))
	surface.DrawRect(0, 0, w, h * .66)
	surface.SetDrawColor(Color(192, 57, 43))
	surface.DrawRect(0, h * .66, w, h)
	surface.SetFont("TauntButtonFont")
	surface.SetTextColor(Color(236, 240, 241))
	local textw, texth = surface.GetTextSize("YOUR TAUNTS")
	surface.SetTextPos(w / 2 - textw / 2, h / 2 - texth / 2)
	surface.DrawText("YOUR TAUNTS")
	if self.IsClicked then
		surface.SetDrawColor(Color(0, 0, 0, 160))
		surface.DrawRect(0, 0, w, h)
	end
	if self.Hovered and !self.IsClicked then
		surface.SetDrawColor(Color(255, 255, 255, 50))
		surface.DrawRect(0, 0, w, h)
	end
end

function INVPAGE:DoClick()
	if self:GetClicked() then return end
	self:SetCursor("arrow")
	self:SetClicked(!self:GetClicked())
	self:GetParent().buybutton:SetClicked(false)
	self:GetParent():GetShopContainer():SetVisible(false)
	self:GetParent():GetInventoryContainer():SetVisible(true)
end

vgui.Register("TauntsFrameInvPage", INVPAGE, "Button")