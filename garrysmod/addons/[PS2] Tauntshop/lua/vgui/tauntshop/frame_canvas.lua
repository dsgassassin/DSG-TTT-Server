local function IconScale(size)
	return math.Clamp(ScreenScale(size), 0, 32), math.Clamp(ScreenScale(size), 0, 32)
end

local CONTAINER = {}

function CONTAINER:Init()
	self.LastPress = CurTime()
	self.scrolled = 0
end

function CONTAINER:Paint(w, h)
	--inner box
	surface.SetDrawColor(Color(41, 128, 185, 20)) 
	surface.DrawRect(0, 0, w, h)
end

function CONTAINER:PerformLayout(w, h)
	local _, y = self:GetPos()
	local newh = 5 + 77 * math.Round(h / 77) 
	self:SetSize(w, newh)
	self:GetParent():SetSize(self:GetParent():GetWide(), y + newh + 5)
	for _, pnl in ipairs(self:GetChildren()) do
		pnl:SetSize(self:GetWide() - 10, 72)
		if pnl.button then
			pnl.button:SetSize(w / 8, 72)
			pnl.button:SetPos(pnl:GetWide() - w / 8 + 2, 0)
		end
	end
end

function CONTAINER:Scroll(amount)
	if !self:IsVisible() then return end
	local last, first = self:GetChildren()[#self:GetChildren()], self:GetChildren()[1]
	local _, firsty = first:GetPos()
	local _, lasty = last:GetPos()
	if 5 + #self:GetChildren() * 77 < self:GetTall() then return end
	if firsty + amount >= 77 then return end
	if lasty + amount + 77 <= self:GetTall() - 5 then return end
	for k, pnl in pairs(self:GetChildren()) do
		local x, y = pnl:GetPos()
		pnl:SetPos(x, y + amount)
	end
end
   
function CONTAINER:Think(key)
	local up = input.IsKeyDown(KEY_UP)
	local down = input.IsKeyDown(KEY_DOWN)
	if up and !down and CurTime() > self.LastPress then
		self:Scroll(77)
		self.LastPress = CurTime() + .1
	end
	if !up and down and CurTime() > self.LastPress then
		self:Scroll(-77)
		self.LastPress = CurTime() + .1
	end
end

function CONTAINER:OnMouseWheeled(delta)
	if CurTime() > self.LastPress then
		self:Scroll(77 * (delta > 0 and 1 or -1))
	end
end

function CONTAINER:AddEntry(id, taunt)
	local pnl = vgui.Create("TauntEntry", self)
	pnl.id = id
	pnl:SetAudio(taunt.path, taunt.duration)
	pnl:SetTitle(taunt.name)
	pnl:SetPrice(taunt.price)
	pnl:SetPos(5, (#self:GetChildren() - 1) * 77 + 5)
	pnl:SetVisible(true)
	if self == self:GetParent().inventory then
		pnl.button = vgui.Create("TauntEquipButton", pnl)
	else
		pnl.button = vgui.Create("TauntBuyButton", pnl)
		if (taunt.donor and !hook.Call("PlayerTauntDonorCheck", GAMEMODE, LocalPlayer())) then
			pnl.button:SetVisible(false)
		end
	end
	return pnl
end

vgui.Register("TauntsContainer", CONTAINER, "EditablePanel")