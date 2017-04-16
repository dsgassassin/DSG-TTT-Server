
-- Should we enable sprinting
local advttt_sprint_enabled = CreateConVar("ttt_advttt_sprint_enabled", "1", FCVAR_ARCHIVE)
-- How fast should sprinting players move? Multiplier of normal speed
local advttt_sprint_speedmul = CreateConVar("ttt_advttt_sprint_speedmul", "1.5", FCVAR_ARCHIVE)
-- How fast should stamina deplete while sprinting
local advttt_sprint_depletion = CreateConVar("ttt_advttt_sprint_depletion", "1", FCVAR_ARCHIVE)
-- How fast should stamina restore while not sprinting
local advttt_sprint_restoration = CreateConVar("ttt_advttt_sprint_restoration", "0.75", FCVAR_ARCHIVE)
-- Should we use shift instead of tapping W for sprinting? Warning: shift is used for traitor voice chat
local advttt_sprint_useshift = CreateConVar("ttt_advttt_sprint_useshift", "0", FCVAR_ARCHIVE)

-- Should we enable modified head/bodyshot damages
local advttt_dmg_enabled= CreateConVar("ttt_advttt_dmg_enabled", "0", FCVAR_ARCHIVE)
-- How much damage should headshots do? Multiple of normal damage amount
local advttt_dmg_headshot = CreateConVar("ttt_advttt_dmg_headshot", "3", FCVAR_ARCHIVE)
-- How much damage should bodyshots do? Multiple of normal damage amount
local advttt_dmg_bodyshot = CreateConVar("ttt_advttt_dmg_bodyshot", "2", FCVAR_ARCHIVE)

-- How much should player speed decrease if shot to legs? 0 to disable. Otherwise multiplier of speed decrease amount
local advttt_eff_legslowdown = CreateConVar("ttt_advttt_eff_legslowdown", "1", FCVAR_ARCHIVE)

-- Should player speed be modified based on the weapon they're carrying
local advttt_eff_weaponweight = CreateConVar("ttt_advttt_eff_weaponweight_enabled", "1", FCVAR_ARCHIVE)
-- How much speedboost should players get if not carrying primary, secondary or equipment items.
local advttt_eff_weaponweight_boost = CreateConVar("ttt_advttt_eff_weaponweight_initialboost", "0.1", FCVAR_ARCHIVE)
-- Should only the active weapon affect the player speed? If disabled, all weapons carried affect speed
local advttt_eff_weaponweight_onlyactive = CreateConVar("ttt_advttt_eff_weaponweight_onlyactive", "1", FCVAR_ARCHIVE)
-- How much more should active weapon weigh compared to if the same weapon was in inventory but not carried? A multiplier
local advttt_eff_weaponweight_activemul = CreateConVar("ttt_advttt_eff_weaponweight_activemul", "1.25", FCVAR_ARCHIVE)
-- How much should heavy (primary) weapons weigh?
local advttt_eff_weaponweight_heavy = CreateConVar("ttt_advttt_eff_weaponweight_heavy", "0.15", FCVAR_ARCHIVE)
-- How much should pistols (secondary weapons) weigh?
local advttt_eff_weaponweight_pistol = CreateConVar("ttt_advttt_eff_weaponweight_pistol", "0.1", FCVAR_ARCHIVE)
-- How much should grenades & equipment weapons weigh?
local advttt_eff_weaponweight_nade = CreateConVar("ttt_advttt_eff_weaponweight_nade", "0.05", FCVAR_ARCHIVE)

hook.Add("KeyPress", "WyoziAdvTTTSprintTap", function(ply, key)
	local thekey = advttt_sprint_useshift:GetBool() and IN_SPEED or IN_FORWARD
	if key == thekey and advttt_sprint_enabled:GetBool() then
		if (advttt_sprint_useshift:GetBool() or ply.W_LastWTap and ply.W_LastWTap > CurTime() - 0.2) and ply:GetNWFloat("w_stamina", 0) > 0.1 then
			ply.W_Sprinting = true
		end 
		ply.W_LastWTap = CurTime()
	end
end)

hook.Add("KeyRelease", "WyoziAdvTTTSprintTap", function(ply, key)
	local thekey = advttt_sprint_useshift:GetBool() and IN_SPEED or IN_FORWARD
	if key == thekey then
		ply.W_Sprinting = false
	end
end)

hook.Add("ScalePlayerDamage", "WyoziAdvTTTScaleDmg", function(ply, hitgroup, dmginfo)
	if (hitgroup == HITGROUP_RIGHTLEG or hitgroup == HITGROUP_LEFTLEG) then
		ply.LegDamage = (ply.LegDamage or 0) + dmginfo:GetBaseDamage()
	end
	if advttt_dmg_enabled:GetBool() then
		if ( hitgroup == HITGROUP_HEAD ) then
			dmginfo:ScaleDamage( advttt_dmg_headshot:GetFloat() )
		else
			dmginfo:ScaleDamage( advttt_dmg_bodyshot:GetFloat() )
		end
	end
end)

local function SWeaponWeight(wep)
	if wep.Kind then
		if wep.Kind == WEAPON_PISTOL then
			return advttt_eff_weaponweight_pistol:GetFloat()
		elseif wep.Kind == WEAPON_HEAVY then
			return advttt_eff_weaponweight_heavy:GetFloat()
		elseif wep.Kind == WEAPON_NADE or wep.Kind == WEAPON_EQUIP1 or wep.Kind == WEAPON_EQUIP2 then
			return advttt_eff_weaponweight_nade:GetFloat()
		end
	end
	return 0
end

local function WeaponsWeight(ply)
	local weight = -(advttt_eff_weaponweight_boost:GetFloat()) -- Initial boost
	if not advttt_eff_weaponweight_onlyactive:GetBool() then
		for _,wep in pairs(ply:GetWeapons()) do
			weight = weight + SWeaponWeight(wep)
		end
	end
	local awep = ply:GetActiveWeapon()
	if awep then
		weight = weight + SWeaponWeight(awep)*advttt_eff_weaponweight_activemul:GetFloat()
	end
	return weight
end

local function PMetaSetSpeed(self, slowed)
	local mul = 1
	local rest = not self:IsOnGround()

	if self.W_Sprinting and self:GetNWFloat("w_stamina", 0) > 0 then
		mul = mul * advttt_sprint_speedmul:GetFloat()
		local speed = self:GetVelocity():Length()
		if speed >= 200 then
			self:SetNWFloat("w_stamina", math.max(self:GetNWFloat("w_stamina", 0)-(advttt_sprint_depletion:GetFloat() * 0.003), 0))
		end
	else
		if not self:KeyDown(IN_JUMP) then
			self:SetNWFloat("w_stamina", math.min(self:GetNWFloat("w_stamina", 0)+(advttt_sprint_restoration:GetFloat() * 0.003), 1))
		end
		self.W_Sprinting = false
	end

	if self.LegDamage and self.LegDamage > 0 and advttt_eff_legslowdown:GetFloat() > 0 then
		local nor = self.LegDamage / 100 -- normalized
		nor = nor * advttt_eff_legslowdown:GetFloat()
		nor = math.Clamp(nor, 0, 0.7)
		nor = 1 - nor

		mul = mul * nor
		self.LegDamage = self.LegDamage - 0.5
	end

	if advttt_eff_weaponweight:GetBool() then
		mul = mul * (1 - WeaponsWeight(self))
	end
	
	if slowed then
		self:SetWalkSpeed(120 * mul)
		self:SetRunSpeed(120 * mul)
		self:SetMaxSpeed(120 * mul)
	else
		self:SetWalkSpeed(220 * mul)
		self:SetRunSpeed(220 * mul)
		self:SetMaxSpeed(220 * mul)
	end
end

hook.Add("InitPostEntity", "WyoziAdvTTTOverrideSetSpeed", function()
	local pmeta = FindMetaTable("Player")
	pmeta.SetSpeed = PMetaSetSpeed
end)