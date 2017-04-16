local function FormatString(str)
   local words = string.Explode(" ", str)
   local upper, lower, str
   local formatted = {}
   
   for k, v in pairs(words) do
      upper = string.upper(string.sub(v, 1, 1))
      lower = string.lower(string.sub(v, 2))
      table.insert(formatted, upper..lower)
   end
   
   str = formatted[1]

   if #formatted > 1 then
      for i = 1, #formatted-1 do
         str = str.." "..formatted[i+1]
      end
   end

   return str
end

local function FormatGroup(ply)
   if !IsValid(ply) then return end

   local str = FormatString(ply:GetUserGroup())
   
   if string.find(str, "admin") then
      str = string.gsub(str, "admin", " Admin")
   end
   
   return str
end

local function SetTitleString(ply, str)
	ply:SetNWString("midnight_tstr", str)
	ply:SetPData("midnight_tstr", str)
end

local function SetTitleColour(ply, r, g, b)
	ply:SetNWVector("midnight_tclr", Vector(r, g, b))
	ply:SetPData("midnight_tclr", tostring(r)..","..tostring(g)..","..tostring(b))
end

local function GetTitleString(ply)
	return ply:GetPData("midnight_tstr")
end

local function GetTitleColour(ply)
	local pdata = ply:GetPData("midnight_tclr")
   
	if pdata then
		local spl = pdata:Split(",")
      
		return tonumber(spl[1]), tonumber(spl[2]), tonumber(spl[3])
	end
end

local function UpdateTitle(ply)
   if !IsValid(ply) then return end

   local group = FormatGroup(ply)
   local c = midnight_sb.config.default_group_colour
   
   for k, v in pairs(midnight_sb.config.titles) do
      if (group != v) then
         SetTitleString(ply, midnight_sb.config.default_group_name)
      else
         SetTitleString(ply, FormatGroup(ply))
      end
   end
      
   SetTitleColour(ply, c.r, c.g, c.b)
   
   for group, title in pairs(midnight_sb.config.titles) do
      if ply:IsUserGroup(group) or ply:GetUserGroup() == group then
         SetTitleString(ply, title)
      end
      
      for group, colour in pairs(midnight_sb.config.colours) do
         if ply:IsUserGroup(group) or ply:GetUserGroup() == group then
            SetTitleColour(ply, colour.r, colour.g, colour.b)
         end
      end
   end
end

function SetTitle(ply)
	local r, g, b = GetTitleColour(ply)
   
   if (r) then
      ply:SetNWVector("midnight_tclr", Vector(r, g, b) or Vector(255, 215, 193))
   end
   
	ply:SetNWString("midnight_tstr", GetTitleString(ply))
end
hook.Add("PlayerSpawn", "GetTitle", GetTitle)

local function CreateTimer(ply)
   if !IsValid(ply) then return end
   
   timer.Simple(1, function() 
      if (timer.Exists(ply:UniqueID().."-UpdateTitle")) then return end

      timer.Create(ply:UniqueID().."-UpdateTitle", 1, 0, function()
         UpdateTitle(ply)
         SetTitle(ply)
      end)
   end)
end
hook.Add("PlayerSpawn", "CreateTimer", CreateTimer)

local function RemoveTimer(ply)
   timer.Remove(ply:UniqueID().."-UpdateTitle")
end
hook.Add("PlayerDisconnected", "RemoveTimer", RemoveTimer)

hook.Add("TTTScoreboardColorForPlayer", "midnight_titles", function(ply)
	local v = ply:GetNWVector("midnight_tclr")
   
	if v and (v.x ~= 0 or v.y ~= 0 or v.z ~= 0) then
		return Color(v.x, v.y, v.z)
	else
      return Color(255, 215, 193)
   end
end, -5)
