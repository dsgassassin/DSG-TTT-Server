AddCSLuaFile()

if (SERVER) then
   AddCSLuaFile("cl_init_mnsb.lua")
   include("init_mnsb.lua")
else
   include("cl_init_mnsb.lua")
end