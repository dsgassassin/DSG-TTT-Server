TAUNTSHOP = TAUNTSHOP or {}

local usesql = TAUNTSHOP.SaveMethod == "mysql"

if usesql then require("mysqloo") end

function TAUNTSHOP.DB.Connect()
	if !usesql then return end
	local db = mysqloo.connect(TAUNTSHOP.DB.Hostname, TAUNTSHOP.DB.Username, TAUNTSHOP.DB.Password, TAUNTSHOP.DB.Database, 3306)

	function db:onConnected()
		print("TAUNTSHOP: DB successfully connected!")
		TAUNTSHOP.DB.CreateTable()
	end

	function db:onConnectionFailed(err)
		print("TAUNTSHOP: DB connection failed with \"" .. err .. "\"")
	end

	db:connect()
	return db
end

local db = TAUNTSHOP.DB.Connect()

function TAUNTSHOP.DB.CreateTable()
	local q = db:query([[CREATE TABLE tauntshop ( uniqueid varchar(30) NOT NULL,
	taunts text NOT NULL,
	equipped varchar(30) NOT NULL,
	points int(32) NOT NULL,
	PRIMARY KEY (uniqueid));]])
	
	function q:onSuccess(data)
		print("TAUNTSHOP: Table succesfully created!")
	end
	
	q:start()
end
	
function TAUNTSHOP.DB.AddPlayer(ply)
	TAUNTSHOP.DB.GetPlayerData(ply)
	if !usesql then return end
	local txt = [[INSERT IGNORE INTO tauntshop(uniqueid, taunts, equipped) VALUES (%s, '', '');]]
	local q = db:query(txt:format(ply:UniqueID()))
	q:start()
end

function TAUNTSHOP.DB.GetPlayerData(ply)
	if usesql then
		local txt = [[SELECT taunts, equipped FROM tauntshop WHERE uniqueid = %s;]]
		local q = db:query(txt:format(ply:UniqueID()))
		function q:onSuccess(data)
			local taunts = data[1].taunts
			local equipped = data[1].equipped
			if ply.TShopTaunts and #ply.TShopTaunts > 0 then return end
			for taunt in taunts:gmatch("[^;]+") do
				ply:TShopGiveTaunt(TAUNTSHOP.IntFromID(taunt))
			end
			if equipped ~= "" then ply:TShopEquipTaunt(TAUNTSHOP.IntFromID(equipped)) end
		end
		q:start()
	else
		local taunts = ply:GetPData("taunts") or ""
		local equipped = ply:GetPData("equipped") or ""
		if ply.TShopTaunts and #ply.TShopTaunts > 0 then return end
		for taunt in taunts:gmatch("[^;]+") do
			ply:TShopGiveTaunt(TAUNTSHOP.IntFromID(taunt))
		end
		if equipped ~= "" then ply:TShopEquipTaunt(TAUNTSHOP.IntFromID(equipped)) end
	end
end

concommand.Add("__tshoploadpldata", TAUNTSHOP.DB.AddPlayer)

function TAUNTSHOP.DB.UpdatePlayerTaunts(ply)
	local taunts = ply.TShopTaunts
	local tbl = {}
	for i = 1, #ply.TShopTaunts do
		tbl[i] = ply.TShopTaunts[i].id
	end
	local list = table.concat(tbl, ";")
	if usesql then
		local txt = [[UPDATE tauntshop SET taunts = '%s', equipped = '%s' WHERE uniqueid = %s;]]
		local q = db:query(txt:format(list, (ply.TShopEquippedTaunt and ply.TShopEquippedTaunt.id  or ""), ply:UniqueID()))
		q:start()
	else
		ply:SetPData("taunts", list)
		ply:SetPData("equipped", (ply.TShopEquippedTaunt and ply.TShopEquippedTaunt.id  or ""))
	end
end