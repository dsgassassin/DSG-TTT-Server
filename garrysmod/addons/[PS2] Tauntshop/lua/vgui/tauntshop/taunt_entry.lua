 local function IconScale(size)
	return math.Clamp(ScreenScale(size), 0, 32), math.Clamp(ScreenScale(size), 0, 32)
end

local TAUNT = {}

function TAUNT:Init()
	self.Title = ""
	self.Audio = ""
	self.DonorOnly = false
	self.Bought = false
	self.hovered = false
	self:SetText("")
	self.donortextmatrix = Matrix()
	self.boughtmatrix = Matrix()
	self.equippedmatrix = Matrix()
end

function TAUNT:SetAudio(str, duration)
	if !file.Exists("sound/" .. str, "GAME") then error("TauntShop: file \"" .. str .. "\" doesn't exist") return end
	self.Audio = str
	self.Length = duration
	self.soundstart = -1
	self.soundend = -1
end

function TAUNT:SetPrice(price)
	self.Price = price
end

function TAUNT:PerformLayout(w, h)
	self._originalscrw = ScrW()
	self._originalscrh = ScrH()
	surface.SetFont("TauntBoughtFont")
	local ang = -5
	self.donortextmatrix:SetAngles(Angle(0, ang, 0))
	local textw, texth = surface.GetTextSize("Donate to be able to buy this taunt")
	local x, y = w / 2 - textw * .35,  h / 2 - texth * math.sin(math.rad(ang)) * 0.35 - 2
	self.donortextmatrix:SetTranslation(Vector(x, y)) 
	self.donortextmatrix:SetScale(Vector(1, 1, 1) * 0.72)

	self.boughtmatrix:SetAngles(Angle(0, ang, 0))
	local textw, texth = surface.GetTextSize("You already own this taunt")
	local x, y = w / 2 - textw * .35,  h / 2 - texth * math.sin(math.rad(ang)) * 0.35 - 5
	self.boughtmatrix:SetTranslation(Vector(x, y)) 
	self.boughtmatrix:SetScale(Vector(1, 1, 1) * 0.72)
	
	self.equippedmatrix:SetAngles(Angle(0, ang, 0))
	local textw, texth = surface.GetTextSize("Equipped")
	local x, y = w / 2 - textw * .35,  h / 2 - texth * math.sin(math.rad(ang)) * 0.3 - 20
	self.equippedmatrix:SetTranslation(Vector(x, y)) 
	self.equippedmatrix:SetScale(Vector(1, 1, 1) * 1)
	
end

function TAUNT:OnCursorEntered()
	self:SetCursor("hand")
	if (self.DonorOnly and !hook.Call("PlayerTauntDonorCheck", GAMEMODE, LocalPlayer())) or self.Bought then
		self:SetCursor("arrow")
		self.hovered = false
		return
	end
	if self.Equipped then self.hovered = false return end
	self.hovered = true
end	

function TAUNT:OnCursorExited()
	self.hovered = false
end

function TAUNT:SetBought(Bought)
	self.Bought = Bought
	if self.button and Bought then self.button:SetVisible(false) end
	self.stars = {{2, 53}}
	for i = 1, self:GetWide(), 1 do --shitty but cba to improve
		self.stars[#self.stars + 1] = {2 + (#self.stars - 1) * 27, 2}
		self.stars[#self.stars + 1] = {2 + (#self.stars - 1) * 27, 27}
		self.stars[#self.stars + 1] = {2 + (#self.stars - 1) * 27, 53}
	end
end

function TAUNT:SetEquipped(equipped)
	self.Equipped = equipped
	self.button:SetVisible(!equipped)
end

function TAUNT:SetTitle(str)
	self.Title = str
end

function TAUNT:SetDonorOnly(donor)
	self.DonorOnly = donor
	self.stars = {{2, 53}}
	for i = 1, self:GetWide(), 1 do --shitty but cba to improve
		self.stars[#self.stars + 1] = {2 + (#self.stars - 1) * 27, 2} 
		self.stars[#self.stars + 1] = {2 + (#self.stars - 1) * 27, 27}
		self.stars[#self.stars + 1] = {2 + (#self.stars - 1) * 27, 53}
	end
	if self.button and donor and !hook.Call("PlayerTauntDonorCheck", GAMEMODE, LocalPlayer()) then self.button:SetVisible(false) end
end


function TAUNT:DoClick() 
	if self.Equipped then
		self:SetEquipped(false)
		RunConsoleCommand("tshop_equiptaunt", "")
		return
	end
	if !self:GetParent().IsSoundPlaying and !self.Active then
		if self.Bought or self.Equipped then return end
		surface.PlaySound(self.Audio)
		self.soundstart = CurTime()
		self.soundend = CurTime() + self.Length
		self:GetParent().IsSoundPlaying = true
		self.Active = true
		timer.Simple(self.Length, function() self:GetParent().IsSoundPlaying = false; self.Active = false end)
	end
end

function TAUNT:Paint(w, h)
	local fract
	if self.soundend and self.soundstart then
		fract = math.TimeFraction(self.soundstart, self.soundend, CurTime())
	else
		fract = 0
	end
	if !self.button then return end
	local x, y = self:LocalToScreen(0, 0)
	render.ClearStencil(); 
	render.SetStencilEnable(true)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP);
	render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilReferenceValue(1)
	
	draw.RoundedBox(8, 0, 0, w, h, Color(243, 156, 18, 150))
			
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	
	surface.SetFont("Trebuchet24")
	surface.SetTextColor(Color(236, 240, 241))
	local textw, texth = surface.GetTextSize(self.Title:upper())
	surface.SetTextPos(texth / 2, h / 2 - texth / 2)
	
	render.EnableClipping(true)
	render.SetScissorRect(x, y, x + (self.button:IsVisible() and w * .875 or w) * fract, y + h, true)
	draw.RoundedBox(8, 0, 0, w, h, Color(52, 152, 219, 200))
	render.SetScissorRect(x, y, x + (self.button:IsVisible() and w * .875 or w) * fract, y + h, false)
	render.EnableClipping(false)
	if !((self.DonorOnly and !hook.Call("PlayerTauntDonorCheck", GAMEMODE, LocalPlayer())) or self.Bought or self.Equipped) then
		surface.DrawText(self.Title:upper())
	end

	--donor
	if (self.DonorOnly and !hook.Call("PlayerTauntDonorCheck", GAMEMODE, LocalPlayer())) or self.Bought or self.Equipped then
		surface.SetDrawColor(color_white)
		if self.Bought then
			surface.SetMaterial(Material("icon16/exclamation.png"))
		else
			surface.SetMaterial(Material("icon16/star.png"))
		end
		if !self.Equipped then
			for _, v in ipairs(self.stars) do
				surface.DrawTexturedRect(v[1], v[2], 16, 16)
			end
		end
		surface.SetFont("Trebuchet24")
		surface.SetTextColor(Color(236, 240, 241))
		local textw, texth = surface.GetTextSize(self.Title:upper())
		surface.SetTextPos(texth / 2, h / 2 - texth / 2)
		surface.DrawText(self.Title:upper())
		draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 220))
		render.PushFilterMag(TEXFILTER.ANISOTROPIC)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		render.SetViewPort(x, y, w, h) --instead of using complex trig math we just change viewports back and forth
		cam.Start2D()
			if self.Equipped then
				cam.PushModelMatrix(self.equippedmatrix)
			else
				if self.Bought then
					cam.PushModelMatrix(self.boughtmatrix)
				else
					cam.PushModelMatrix(self.donortextmatrix)
				end
			end
				surface.SetFont("TauntBoughtFont")
				surface.SetTextColor(color_white)
				surface.SetTextPos(0, 0)
				if self.Equipped then
					surface.DrawText("Equipped")
				else
					if self.Bought then
						surface.DrawText("You already own this taunt")
					else
						surface.DrawText("Donate to be able to buy this taunt")
					end
				end
			cam.PopModelMatrix()
		cam.End2D()
		render.PopFilterMag()
		render.PopFilterMin()
		render.SetViewPort(0, 0, self._originalscrw, self._originalscrh)
	end
	render.SetStencilEnable(false);
	if self.hovered then draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 20)) end
	if fract > 1 then self.soundstart = 0; self.soundend = 0 end
	
end


vgui.Register("TauntEntry", TAUNT, "Button")

local BUYBUTTON = {}

function BUYBUTTON:Init()
	self:SetText("")
	self.Clickable = true
	self._endblink = -1
end

function BUYBUTTON:OnCursorEntered()
	surface.PlaySound("ui/buttonrollover.wav")
	self.hovered = true
end

function BUYBUTTON:OnCursorExited()
	self.hovered = false
end

function BUYBUTTON:Paint(w, h)
	local color = Color(52, 73, 94)
	if CurTime() < self._endblink then
		color = (CurTime() % 1 > .5) and Color(225, 229, 230) or Color(192, 57, 43)
		draw.RoundedBoxEx(8, 0, 0, w, h, color, false, true, false, true)
		self.hovered = false
	else
		draw.RoundedBoxEx(8, 0, 0, w, h, (!self.hovered and Color(225, 229, 230) or Color(52, 73, 94)), false, true, false, true)
	end
		surface.SetFont("BuyButtonFont")
		surface.SetTextColor(!self.hovered and Color(52, 73, 94) or Color(225, 229, 230))
		surface.SetTextPos(math.Clamp(ScreenScale(13), 0, 39) + math.Clamp(ScreenScale(2), 0, 6), 36 - (math.Clamp(ScreenScale(12), 0, 36)) / 2)
		surface.DrawText(": ")
		local wide = surface.GetTextSize(": ")
		surface.SetTextPos(math.Clamp(ScreenScale(13), 0, 39) + math.Clamp(ScreenScale(2), 0, 6) + 4 + wide, 36 - (math.Clamp(ScreenScale(12), 0, 36) / 2) + 1.5)
		surface.DrawText(self:GetParent().Price)
		surface.SetMaterial(Material("icon32/coins.png"))
		surface.SetDrawColor(color_white) 
		surface.DrawTexturedRect(10, 36 - (IconScale(13) / 2), IconScale(13), IconScale(13))
end

function BUYBUTTON:DoClick()
	--buy stuff
	if !LocalPlayer():TShopCanAfford(self:GetParent().Price) then
		--surface.PlaySound("")
		self._endblink = CurTime() + 3
		surface.PlaySound("buttons/button10.wav")
		return
	end
	surface.PlaySound("ui/buttonclick.wav")
	self:GetParent():SetBought(true)
	RunConsoleCommand("tshop_buy", self:GetParent().id)
	local taunt = TAUNTSHOP.Taunts[self:GetParent().id]
	self:GetParent():GetParent():GetParent():GetInventoryContainer():AddEntry(self:GetParent().id, taunt)
	for _, v in ipairs(self:GetParent():GetParent():GetParent():GetInventoryContainer():GetChildren()) do
		v:SetEquipped(false)
		if v.id == self:GetParent().id then
			v:SetEquipped(true)
		end
	end
end

vgui.Register("TauntBuyButton", BUYBUTTON, "Button")

local EQUIPBUTTON = {}

function EQUIPBUTTON:Init()
	self:SetText("")
	self.Clickable = true
end

function EQUIPBUTTON:OnCursorEntered()
	surface.PlaySound("ui/buttonrollover.wav")
	self.hovered = true
end

function EQUIPBUTTON:OnCursorExited()
	self.hovered = false
end

function EQUIPBUTTON:Paint(w, h)
	draw.RoundedBoxEx(8, 0, 0, w, h, (!self.hovered and Color(225, 229, 230) or Color(52, 73, 94)), false, true, false, true)
	surface.SetFont("BuyButtonFont")
	local wide = surface.GetTextSize("EQUIP")
	surface.SetTextColor(!self.hovered and Color(52, 73, 94) or Color(225, 229, 230))
	surface.SetTextPos(w / 2 - wide / 2, 36 - (math.Clamp(ScreenScale(12), 0, 36) / 2))
	surface.DrawText("EQUIP")
end

function EQUIPBUTTON:DoClick()
	--buy stuff
	surface.PlaySound("ui/buttonclick.wav")
	self:GetParent():SetEquipped(true)
	self:SetVisible(false)
	RunConsoleCommand("tshop_equiptaunt", self:GetParent().id)
	for _, v in ipairs(self:GetParent():GetParent():GetChildren()) do
		if v.Equipped and v ~= self:GetParent() then
			v:SetEquipped(false)
			v.button:SetVisible(true)
		end
	end
end

vgui.Register("TauntEquipButton", EQUIPBUTTON, "Button")
