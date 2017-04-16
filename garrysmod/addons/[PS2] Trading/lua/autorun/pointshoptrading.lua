if SERVER then
	AddCSLuaFile()
	AddCSLuaFile('cl_pointshoptrading.lua')
	AddCSLuaFile('cl_tradingfonts.lua')
	AddCSLuaFile('sh_tradingconfig.lua')
	AddCSLuaFile('sh_pointshoptrading.lua')
	if not PSPLUS then AddCSLuaFile('cl_trademessages.lua') end
	
	--Add panel files
	AddCSLuaFile('panels/cl_categoriesdropdown.lua')
	AddCSLuaFile('panels/cl_tradeitem.lua')
	AddCSLuaFile('panels/cl_playertradepanel.lua')
	AddCSLuaFile('panels/cl_playersummarypanel.lua')
	AddCSLuaFile('panels/cl_playerselection.lua') 
	if not PSPLUS then
		AddCSLuaFile('panels/cl_trademessage.lua') 		
	end
	--Add server files
	include('sv_pointshoptrading.lua')
	
	--Add resources
	resource.AddFile("resource/fonts/BebasNeue.ttf")
	resource.AddFile("resource/fonts/OpenSansC.ttf")
end

if CLIENT then
	include('cl_pointshoptrading.lua')
end