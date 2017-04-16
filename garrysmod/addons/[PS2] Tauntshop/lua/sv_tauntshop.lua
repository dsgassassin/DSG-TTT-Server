print("==========================\nTauntShop Server loaded\n==========================")

TAUNTSHOP = TAUNTSHOP or {}

local function IndexFromTaunt(taunt)
	for k, v in ipairs(TAUNTSHOP.Taunts) do
		if v.id == taunt.id then
			return k
		end
	end
end



function TAUNTSHOP.BuyTaunt(ply, _, args)
	local id = tonumber(args[1])
	local taunt = TAUNTSHOP.Taunts[id]
	local donorcheck = hook.Call("PlayerTauntDonorCheck", GAMEMODE, ply)
	if !donorcheck and taunt.donor then return end
	if ply:TShopCanAfford(taunt.price) and !ply:TShopHasTaunt(id) then
		ply:TShopTakePoints(taunt.price)
		ply:TShopGiveTaunt(id)
		ply:TShopEquipTaunt(id)
		TAUNTSHOP.DB.UpdatePlayerTaunts(ply)
	end
end

concommand.Add("tshop_buy", TAUNTSHOP.BuyTaunt)

function TAUNTSHOP.PlayTaunt(ply)
	local taunt = ply.TShopEquippedTaunt
	ply.TShopLastTaunted = ply.TShopLastTaunted or 0
	if !taunt or taunt == "" then return end
	local delay = hook.Call("PlayerTauntDelay", GAMEMODE, ply) or TAUNTSHOP.TauntTime
	local call = hook.Call("CanPlayerPlayTaunt", GAMEMODE, ply)
	local canplay = (call == nil and true or call)
	if canplay and ply:TShopHasTaunt(IndexFromTaunt(taunt)) and CurTime() - ply.TShopLastTaunted >= delay + taunt.duration then
		ply:EmitSound(taunt.path)
		ply.TShopLastTaunted = CurTime()
	end
end

concommand.Add("tshop_playtaunt", TAUNTSHOP.PlayTaunt)

hook.Add("PlayerSay", "OpenMenu", function(ply, txt)
	if txt:Trim():len() == 7 and txt:Trim():lower():match("[!/]taunts") then
		ply:ConCommand("tshop_openmenu")
	end
end)

concommand.Add("tshop_equiptaunt", function(ply, _,  args)
	if args[1] == "" then args[1] = -1 end
	ply:TShopEquipTaunt(tonumber(args[1]))
	TAUNTSHOP.DB.UpdatePlayerTaunts(ply)
end)

hook.Add("CanPlayerPlayTaunt", "SpectatorCheck", function(ply)
	if ply:Team() == TEAM_SPECTATOR then return false end
end)
