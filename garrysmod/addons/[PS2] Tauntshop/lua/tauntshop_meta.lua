local meta = FindMetaTable("Player")

function meta:TShopHasTaunt(ind)
	for _, v in ipairs(self:TShopGetTaunts()) do
		if v.id == TAUNTSHOP.Taunts[ind].id then return true end
	end
end

function meta:TShopGetTaunts()
	return self.TShopTaunts or {}
end

function meta:TShopGetPoints()
	if TAUNTSHOP.Currency == "pointshop" then
		return self:PS_GetPoints()
	end
	if TAUNTSHOP.Currency == "darkrp" then
		return self:getDarkRPVar("money")
	end
	if TAUNTSHOP.Currency == "pointshop2" then
		return self.PS2_Wallet.points
	end
end 

function meta:TShopCanAfford(amount)
	return self:TShopGetPoints() - amount >= 0
end

local function AddTaunt()
	local ply = LocalPlayer()
	local id = net.ReadUInt(16)
	ply.TShopTaunts = ply.TShopTaunts or {}
	ply.TShopTaunts[#ply.TShopTaunts + 1] = TAUNTSHOP.Taunts[id]
end

net.Receive("TShop.AddTaunt", AddTaunt)

/*local function UpdatePoints()
	local points = net.ReadDouble()
	LocalPlayer().TShopPoints = points
end*/

net.Receive("TShop.UpdatePoints", UpdatePoints)

local function EquipTaunt()
	local id = net.ReadInt(16)
	if id == -1 then
		LocalPlayer().TShopEquippedTaunt = false
	else
		LocalPlayer().TShopEquippedTaunt = TAUNTSHOP.Taunts[id]
	end
end

net.Receive("TShop.EquipTaunt", EquipTaunt)

if SERVER then
	util.AddNetworkString("TShop.AddTaunt")
	util.AddNetworkString("TShop.EquipTaunt")
	util.AddNetworkString("TShop.UpdatePoints")

	function meta:TShopGiveTaunt(id)
		self.TShopTaunts = self.TShopTaunts or {}
		self.TShopTaunts[#self.TShopTaunts + 1] = TAUNTSHOP.Taunts[id]
		net.Start("TShop.AddTaunt")
			net.WriteUInt(id, 16)
		net.Send(self)
	end
	
	function meta:TShopEquipTaunt(id)
		if id == -1 then
			net.Start("TShop.EquipTaunt")
				net.WriteInt(-1, 16)
			net.Send(self)
			self.TShopEquippedTaunt = false
			return
		end
		if !self:TShopHasTaunt(id) then return end
		self.TShopEquippedTaunt = TAUNTSHOP.Taunts[id]
		net.Start("TShop.EquipTaunt")
			net.WriteInt(id, 16)
		net.Send(self)
	end
	
	
	function meta:TShopSetPoints(amount)
		/*self.TShopPoints = amount
		net.Start("TShop.UpdatePoints")
			net.WriteDouble(amount)
		net.Send(self)*/
		if TAUNTSHOP.Currency == "pointshop" then
			self:PS_SetPoints(amount)
		end
		if TAUNTSHOP.Currency == "darkrp" then
			self:addMoney(-1 * self:getDarkRPVar("money") +	amount)
		end
		if TAUNTSHOP.Currency == "pointshop2" then
			self:PS2_AddStandardPoints(-1 * self.PS2_Wallet.points + amount)
		end
	end
	
	function meta:TShopGivePoints(amount)
		self:TShopSetPoints(self:TShopGetPoints() + amount)
	end
	
	function meta:TShopTakePoints(amount)
		self:TShopSetPoints(self:TShopGetPoints() - amount)
	end
end



