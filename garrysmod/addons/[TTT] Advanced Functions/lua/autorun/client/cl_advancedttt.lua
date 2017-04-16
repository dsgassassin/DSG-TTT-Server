
--local show_on_right_side = false
--local show_label = true

--hook.Add("HUDPaint", "WyoziAdvTTTHUD", function()
	--local margin = 10
	--local client = LocalPlayer()

	--if not client:Alive() or client:Team() == TEAM_SPEC then return end
	--if not TEAM_SPEC then return end -- not ttt

	--local width = 250
	--local height = 90

	--local x = show_on_right_side and (ScrW() - width - margin*2) or margin*2
	--local y = ScrH() - margin - height

	--local bar_height = 9
	--local bar_width = width - (margin*2)

	--local health = math.max(0, client:Health())
	--local health_y = y + height - bar_height - 5

	--draw.RoundedBox(4, x, health_y, bar_width, bar_height, Color(25, 100, 25, 222))
	--draw.RoundedBox(4, x, health_y, bar_width * math.max(client:GetNWFloat("w_stamina", 0), 0.02), bar_height, Color(50, 200, 50, 250))

	--if show_label then
		--draw.SimpleText("Stamina", "Trebuchet18", x, health_y, Color(255, 255, 255))
	--end

--end) 