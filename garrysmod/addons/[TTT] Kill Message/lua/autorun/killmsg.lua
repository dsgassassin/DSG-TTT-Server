AddCSLuaFile("autorun/client/cl_killmsg.lua")
print("Kill message script loaded!, continuing happily!")

function PrintKillMsgOnDeath(victim, wep, attacker)
	if GetRoundState() == ROUND_ACTIVE then
		if (attacker:IsPlayer()) and (attacker ~= victim) and attacker:IsTraitor() then
			umsg.Start("KillMsg", victim)
				umsg.String(attacker:Nick())
				umsg.Char(2)
			umsg.End()
		end
		if (attacker:IsPlayer()) and (attacker ~= victim) and attacker:IsDetective() then
			umsg.Start("KillMsg", victim)
				umsg.String(attacker:Nick())
				umsg.Char(3)
			umsg.End()
		end
		if (attacker:IsPlayer()) and (attacker ~= victim) and !attacker:IsDetective() and !attacker:IsTraitor() then
			umsg.Start("KillMsg", victim)
				umsg.String(attacker:Nick())
				umsg.Char(1)
			umsg.End()
		end
	end
end

hook.Add("PlayerDeath", "ChatKillMsg", PrintKillMsgOnDeath)
