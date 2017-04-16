print("Kill message script loaded!")
local teamslist = {" innocent.", " traitor.", " detective."}
local teamscolors = {Color(0, 200, 0, 255), Color(180, 50, 40, 255), Color(50, 60, 180, 255)} 

function PrintKillMsg(um)
	local nick = um:ReadString()
	local team = um:ReadChar()
	chat.AddText(Color(255, 255, 255), "[Kill Report] You were killed by ", teamscolors[team], nick, Color(255, 255, 255), ", he was a", teamscolors[team], teamslist[team])
end

usermessage.Hook("KillMsg", PrintKillMsg)