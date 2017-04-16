AddCSLuaFile()

if (SERVER) then
   AddCSLuaFile("cl_init_mnhud.lua")
   include("init_mnhud.lua")
else
   include("cl_init_mnhud.lua")
end