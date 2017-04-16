print("==========================\nTauntShop Client loaded\n==========================")

TAUNTSHOP = TAUNTSHOP or {}
CreateClientConVar("tshop_tauntkey", TAUNTSHOP.DefaultKey, true, false)


function TAUNTSHOP.LoadMenu()
	local frame = vgui.Create("TauntsFrame")
	frame:SetSize(ScrW() * .65, ScrH() * .8)
	frame:SetVisible(true)
	frame:MakePopup()
	frame:GetShopContainer():RequestFocus()
	for k, v in ipairs(TAUNTSHOP.Taunts) do
		if LocalPlayer():TShopHasTaunt(k) then
			local pnl = frame:GetInventoryContainer():AddEntry(k, v)
			if LocalPlayer().TShopEquippedTaunt then
				if LocalPlayer().TShopEquippedTaunt.id == v.id then
					pnl:SetEquipped(true)
				end
			end
		end
		local pnl = frame:GetShopContainer():AddEntry(k, v)
		pnl:SetDonorOnly(v.donor)
		pnl:SetBought(LocalPlayer():TShopHasTaunt(k))
	end
end

concommand.Add("tshop_openmenu", TAUNTSHOP.LoadMenu)

local function _printtauntad()
	chat.AddText(Color(155, 89, 182), "Type \"!taunts\" in chat to open up the taunts menu")
	timer.Simple(math.random(12, 36) / 10 * 50, function() _printtauntad() end)
end

hook.Add("Think", "PlayTaunt", function(p, key) --crappy I know, but input.IsKeyDown is the only function that recognises multiple key presses
	local key = input.IsKeyDown(GetConVar("tshop_tauntkey"):GetInt())
	if key and !gui.IsConsoleVisible() and !gui.IsGameUIVisible() and LocalPlayer():Alive() and !vgui.CursorVisible() and !vgui.GetKeyboardFocus() then --this should cover all of it
		RunConsoleCommand("tshop_playtaunt")
	end
end)



hook.Add("InitPostEntity", "TAUNTSHOP.LoadData", function()
	RunConsoleCommand("__tshoploadpldata")
	timer.Simple(math.random(12, 36) / 10 * 50, function() _printtauntad() end)
end)
