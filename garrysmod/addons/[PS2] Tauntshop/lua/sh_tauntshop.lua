TAUNTSHOP = TAUNTSHOP or {}
TAUNTSHOP.Taunts = TAUNTSHOP.Taunts or {}
 
function TAUNTSHOP.RegisterTaunt(id, name, path, duration, price, donor)
	if !file.Exists("sound/" .. path, "GAME") then MsgN("Sound \"" .. path .. "\" doesn't exist, skipping") return end
	for _, v in ipairs(TAUNTSHOP.Taunts) do --dupe check
		if id == v.id then return end
	end
	TAUNTSHOP.Taunts[#TAUNTSHOP.Taunts + 1] = {["id"] = id:gsub(";", ""), ["name"] = name, ["path"] = path, ["duration"] = duration, ["price"] = price, ["donor"] = donor}
end

function TAUNTSHOP.IntFromID(id)
	for k, v in ipairs(TAUNTSHOP.Taunts) do
		if v.id == id then return k end
	end
end

local function getusergroup(ply, group)
	if ulx then
		return ply:CheckGroup(group)
	end
	if evolve then
		return ply:GetNWString("EV_UserGroup"):lower() == group:lower()
	end
	return ply:GetUserGroup():lower() == group:lower()
end

local function DonorCheck(ply)
	local donorcheck = false
	for _, v in ipairs(TAUNTSHOP.DonorGroups) do
		if getusergroup(ply, v) then
			donorcheck = true
		end
	end
	return donorcheck
end

hook.Add("PlayerTauntDonorCheck", "DefaultDonorCheck", DonorCheck)