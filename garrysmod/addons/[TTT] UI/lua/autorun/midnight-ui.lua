AddCSLuaFile()

if (SERVER) then
   AddCSLuaFile("cl_init_mnui.lua")
else
   include("cl_init_mnui.lua")
end