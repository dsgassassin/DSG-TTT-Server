local TradeMessage = {}

function TradeMessage:Init()
	self:SetDrawBackground(false)
	self:SetSize(TRADING.NotificationSize, 150)
	
	self.TextFont = "Bebas24Scaled"
	self.TextColorStr = "255,255,255,100"
	self.BackColor = TRADING.Theme.ControlColor
	self.TypeColor = TRADING.Theme.NotifcationAccentColor
end

function TradeMessage:SetText(text)
	local markupstr = string.format("<font=%s><color=%s>%s</color></font>",self.TextFont,self.TextColorStr,text)
	self.Text = markup.Parse(markupstr, self:GetWide() - 79)
end

function TradeMessage:SetPlayer(ply)
	self.Player = ply
	if self:GetWide() < (64 * 2) then return end
	self.ImageIcon = vgui.Create("AvatarImage", self)
	self.ImageIcon:SetSize(64,64)
	self.ImageIcon:SetPlayer(ply, 84)
end

function TradeMessage:GetPlayer()
	return self.Player
end

function TradeMessage:SetQuestionButtons(firsttext, firstfunc, secondtext, secondfunc)
	self.QuestionMessage = true
	self.FirstButton = vgui.Create("DButton", self)
	self.FirstButton:SetSize(self:GetWide() / 5, 25)
	self.FirstButton:SetFont("Bebas24Scaled")
	self.FirstButton:SetText(firsttext)
	self.FirstButton.Paint = function(s,w,h)
		surface.SetDrawColor(self.BackColor)
		surface.DrawRect( 0, 0, w, h ) 
		surface.SetDrawColor(self.TypeColor)
		surface.DrawRect( 1, 1, w - 2, h - 2 )
		if s:IsDown() then
			surface.SetDrawColor(Color(255,255,255,20))
			surface.DrawRect( 1, 1, w - 2, h - 2 ) 
		end
	end
	self.FirstButton.UpdateColours = function(s, skin)
		if (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
		elseif s:IsHovered() then return s:SetTextStyleColor(Color(255,255,255,10))
		else return s:SetTextStyleColor(Color(255,255,255,20))
		end
	end
	self.FirstButton.UpdateColours = function(s, skin)
		if (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
		elseif s:IsHovered() then return s:SetTextStyleColor(Color(255,255,255,200))
		else return s:SetTextStyleColor(Color(255,255,255,150))
		end
	end
	self.FirstButton.DoClick = firstfunc
	
	self.SecondButton = vgui.Create("DButton", self)
	self.SecondButton:SetSize(self:GetWide() / 5, 25)
	self.SecondButton:SetFont("Bebas24Scaled")
	self.SecondButton:SetText(secondtext)
	self.SecondButton.Paint = function(s,w,h)
		surface.SetDrawColor(self.BackColor)
		surface.DrawRect( 0, 0, w, h ) 
		surface.SetDrawColor(self.TypeColor)
		surface.DrawRect( 1, 1, w - 2, h - 2 )
		if s:IsDown() then
			surface.SetDrawColor(Color(255,255,255,20))
			surface.DrawRect( 1, 1, w - 2, h - 2 ) 
		end
	end
	self.SecondButton.UpdateColours = function(s, skin)
		if (s.Depressed || s.m_bSelected) then return s:SetTextStyleColor(color_white)
		elseif s:IsHovered() then return s:SetTextStyleColor(Color(255,255,255,200))
		else return s:SetTextStyleColor(Color(255,255,255,150))
		end
	end
	self.SecondButton.DoClick = secondfunc
end

function TradeMessage:SetColor(color)
	if not IsColor(color) then return end
	self.TypeColor = color
end

function TradeMessage:PerformLayout()	
	if self.ImageIcon then self.ImageIcon:SetPos(5, 10) end
	
	if self.QuestionMessage then
		local height = math.max(79, (10 + self.Text:GetHeight()))
		self.FirstButton:SetPos(5, height )
		self.SecondButton:SetPos(10 + self.FirstButton:GetWide(), height)
	end
	
	local tall = math.Clamp(self.Text:GetHeight(), (self.ImageIcon and 85) or 20, 400)
	self:SetTall(tall + (self.QuestionMessage and (self.FirstButton:GetTall()) or 15))
 end

function TradeMessage:Paint()
	surface.SetDrawColor(self.BackColor)
	surface.DrawRect( 0, 0, self:GetWide(), self:GetTall())
	
	surface.SetDrawColor(self.TypeColor)
	surface.DrawRect( 0, 0, self:GetWide(), 5)
	self.Text:Draw(74,10,nil,nil,self:GetAlpha())
end

derma.DefineControl("TradeMessage", "", TradeMessage, "DPanel")