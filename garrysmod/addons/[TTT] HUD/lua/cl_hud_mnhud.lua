hook.Add("PostGamemodeLoaded", "midnight_hud", function()
   if (gmod.GetGamemode().Name == "Trouble in Terrorist Town") then
      local string = string
      local math = math
      local surface = surface
      local draw = draw
      local dst = draw.SimpleText

      local x = ScrW()
      local y = ScrH()
      local offset, bx

      local text = ""
      local w, h = surface.GetTextSize(text)+16, 0
      local width, height, margin = 200, 22, 8

      local panel = {
         ["main_dark"] = midnight_hud.panel.main_dark,
         ["main_light"] = midnight_hud.panel.main_light,
         ["main_lighter"] = midnight_hud.panel.main_lighter,
         ["top_dark"] = midnight_hud.panel.top_dark,
         ["top_light"] = midnight_hud.panel.top_light,
         ["border"] = midnight_hud.panel.border,
         ["shade_dark"] = midnight_hud.panel.shade_dark,
         ["shade_light"] = midnight_hud.panel.shade_light,
         ["shade_lighter"] = midnight_hud.panel.shade_lighter
      }

      local text_colour = {
         ["dark"] = midnight_hud.text_colour.dark,
         ["light"] =  midnight_hud.text_colour.light,
         ["lighter"] =  midnight_hud.text_colour.lighter,
         ["lightest"] =  midnight_hud.text_colour.lightest,
         ["white"] =  midnight_hud.text_colour.white
      }

      local role_dark = {
         ["innocent"] =  midnight_hud.role_dark.innocent,
         ["traitor"] = midnight_hud.role_dark.traitor,
         ["detective"] = midnight_hud.role_dark.detective,
         ["prep"] = midnight_hud.role_dark.prep
      }

      local role_light = {
         ["innocent"] = midnight_hud.role_light.innocent,
         ["traitor"] = midnight_hud.role_light.traitor,
         ["detective"] = midnight_hud.role_light.detective,
         ["prep"] = midnight_hud.role_light.prep
      }

      local health_bar_dark = {
         ["hp_healthy"] = midnight_hud.health_bar_dark.healthy,
         ["hp_hurt"] = midnight_hud.health_bar_dark.hurt,
         ["hp_wounded"] = midnight_hud.health_bar_dark.wounded,
         ["hp_badwnd"] = midnight_hud.health_bar_dark.badly_wounded,
         ["hp_death"] = midnight_hud.health_bar_dark.near_death
      }

      local health_bar_light = {
         ["hp_healthy"] = midnight_hud.health_bar_light.healthy,
         ["hp_hurt"] = midnight_hud.health_bar_light.hurt,
         ["hp_wounded"] = midnight_hud.health_bar_light.wounded,
         ["hp_badwnd"] = midnight_hud.health_bar_light.badly_wounded,
         ["hp_death"] = midnight_hud.health_bar_light.near_death
      }

      local karma_colour = {
         ["karma_max"] = midnight_hud.karma_colour.karma_max,
         ["karma_high"] = midnight_hud.karma_colour.karma_high,
         ["karma_med"] = midnight_hud.karma_colour.karma_med,
         ["karma_low"] = midnight_hud.karma_colour.karma_low,
         ["karma_min"] = midnight_hud.karma_colour.karma_min
      }
      
      local tags = {
         {txt = midnight_hud.tag_text.friend, color = midnight_hud.tag_colour.friend},
         {txt = midnight_hud.tag_text.suspect, color = midnight_hud.tag_colour.suspect},
         {txt = midnight_hud.tag_text.avoid, color = midnight_hud.tag_colour.avoid},
         {txt = midnight_hud.tag_text.kill, color = midnight_hud.tag_colour.kill},
         {txt = midnight_hud.tag_text.missing, color = midnight_hud.tag_colour.missing}
      }

      local round_state_string = {
         [ROUND_WAIT] = "round_wait",
         [ROUND_PREP] = "round_prep",
         [ROUND_ACTIVE] = "round_active",
         [ROUND_POST] = "round_post"
      }
       
      local colour_active = {
         background = panel.main_dark,
         text_low = Color(200, 200, 20),
         text_empty = Color(200, 20, 20),
         text_weapon = text_colour.white,
         text_ammo = text_colour.lighter
      }

      local colour_inactive = {
         background = panel.main_light,
         text_low = Color(200, 200, 20, 100),
         text_empty = Color(200, 20, 20, 100),
         text_weapon = text_colour.light,
         text_ammo = text_colour.light
      }

      local show_preround = midnight_hud.config.show_preround
      local propspec_outline = Material("models/props_combine/portalball001_sheet")
      local health_percentage, ammo_percentage, punch_percentage
      local clip, max, inv, invmax
      local amount = 20
      
      local GetLang = LANG.GetUnsafeLanguageTable
      local GetPTranslation = LANG.GetParamTranslation
      local GetRaw = LANG.GetRawTranslation
      local TryTranslation = LANG.TryTranslation
      local key_params = {usekey = Key("+use", "USE"), walkkey = Key("+walk", "WALK")}

      local ClassHint = {
         prop_ragdoll = {
            name= "corpse",
            hint= "corpse_hint",

            fmt = function(ent, text) return GetPTranslation(text, key_params) end
         }
      }
      
      local function GetRole()
         local client = LocalPlayer()
      
         if client:IsDetective() then
            return "detective"
         elseif client:IsTraitor() then
            return "traitor"
         elseif GetRoundState() == ROUND_PREP then
            return "prep"
         else
            return "innocent"
         end
      end

      local function HealthBarColours(ent)
         local bar_dark, bar_light
         
         if ent:IsDetective() then
            bar_dark = role_dark.detective
            bar_light = role_light.detective
            
            return bar_dark, bar_light
         elseif ent:IsTraitor() then
            bar_dark = role_dark.traitor
            bar_light = role_light.traitor
            
            return bar_dark, bar_light
         elseif ent:Health() > 90 then
            bar_dark = health_bar_dark.hp_healthy
            bar_light = health_bar_light.hp_healthy
            
            return bar_dark, bar_light
         elseif ent:Health() > 70 then
            bar_dark = health_bar_dark.hp_hurt
            bar_light = health_bar_light.hp_hurt
            
            return bar_dark, bar_light
         elseif ent:Health() > 40 then
            bar_dark = health_bar_dark.hp_wounded
            bar_light = health_bar_light.hp_wounded
            
            return bar_dark, bar_light
         elseif ent:Health() > 20 then
            bar_dark = health_bar_dark.hp_badwnd
            bar_light = health_bar_light.hp_badwnd
            
            return bar_dark, bar_light
         else 
            bar_dark = health_bar_dark.hp_death
            bar_light = health_bar_light.hp_death
            
            return bar_dark, bar_light
         end
      end

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

      local function GetGroup()
         if !IsValid(LocalPlayer()) then return end

         local str = FormatString(LocalPlayer():GetUserGroup())
         
         if string.find(str, "admin") then
            str = string.gsub(str, "admin", " Admin")
         end
         
         return str
      end
      
      local function GetTitle()
         local client = LocalPlayer()
         local title_text, premium_text
         local points, points_name = "0", "Points"
         
         if (midnight_sb) then
            title_text, premium_text = client:GetNWString("midnight_tstr", str), ""
         else
            title_text, premium_text = GetGroup(), ""
         end

         if (midnight_hud.config.pointshop) and (PS != nil) then
            points_name = PS.Config.PointsName
            points = string.Comma(client:PS_GetPoints())
            title_text = tostring(points.." "..points_name)
            
            return title_text, ""
         elseif (midnight_hud.config.pointshop2) and (Pointshop2 != nil) then
            points_name = midnight_hud.config.pointshop2_points_name
            
            if (PS2_Wallet != nil) then
               points = string.Comma(client.PS2_Wallet.points)
               title_text = tostring(points.." "..points_name)
            end
            
            if (midnight_hud.config.pointshop2_show_premium) then
               points_name = midnight_hud.config.pointshop2_premium_points_name
               points = string.Comma(client.PS2_Wallet.premiumPoints)
               premium_text = tostring(points.." "..points_name)
            end
            
            return title_text, premium_text
         elseif (!midnight_hud.config.group_show) then
            return midnight_hud.config.group_text, ""
         else
            return title_text, ""
         end
      end

      local function BorderedRect(x, y, w, h, main, border, bt, br, bb, bl, centered, shaded)
         if (centered) then offset = (w/2) bx = -1 else offset = 0 bx = (w-1) end
       
         amount = 20
       
         surface.SetDrawColor(main)
         surface.DrawRect(x-offset, y, w, h)
         
         if (main.r <= 100) or (main.g <= 100) or (main.b <= 100) then
            amount = 6
         end
         
         if (shaded) then
            surface.SetDrawColor(Color(main.r+amount, main.g+amount, main.b+amount, main.a))
            surface.DrawRect(x-offset, y, w, 1)
         end
         
         if (bt) or (br) or (bb) or (bl) then surface.SetDrawColor(border) end
         if (bt) then surface.DrawRect(x-offset, y-1, w, 1) end
         if (br) then surface.DrawRect(x+offset+bx+1, y-1, 1, h+3) end
         if (bb) then surface.DrawRect(x-offset, y+h, w, 2) end
         if (bl) then surface.DrawRect(x-offset-1, y-1, 1, h+3) end
      end

      local function GetAmmo()
         local ply = LocalPlayer()
         local weapon = ply:GetActiveWeapon()
         if !IsValid(weapon) or not ply:Alive() then return -1 end
       
         local ammo_inv = weapon:Ammo1() or 0
         local ammo_clip = weapon:Clip1() or 0 
         local ammo_max = weapon.Primary.ClipSize or 0
         local ammo_invmax = weapon.Primary.ClipMax or 0
         
         return ammo_clip, ammo_max, ammo_inv, ammo_invmax
      end

      local function DrawPropSpecLabels(client)
         if (not client:IsSpec()) and (GetRoundState() != ROUND_POST) then return end

         surface.SetFont("TabLarge")
         
         local target, screen_position, text, w = nil, nil, nil, 0

         for _, ply in pairs(player.GetAll()) do
            if ply:IsSpec() then
               surface.SetTextColor(220, 200, 0, 120)

               target = ply:GetObserverTarget()

               if IsValid(target) and target:GetNWEntity("spec_owner", nil) == ply then
                  screen_position = target:GetPos():ToScreen()
               else
                  screen_position = nil
               end
            else
               local hp_text = util.HealthToString(ply:Health())
               local name_colour = health_bar_light[hp_text]
                
               surface.SetTextColor(name_colour)
                
               screen_position = ply:EyePos()
               screen_position.z = screen_position.z+20
               screen_position = screen_position:ToScreen()
            end

            if screen_position and (not IsOffScreen(screen_position)) then
               text = ply:Nick()
               w, _ = surface.GetTextSize(text)

               surface.SetTextPos(screen_position.x-w/2, screen_position.y)
               surface.DrawText(text)
            end
         end
      end

      local minimalist = CreateConVar("ttt_minimal_targetid", "0", FCVAR_ARCHIVE)
      local magnifier_material = Material("icon16/magnifier.png")
      local ring_texture = surface.GetTextureID("effects/select_ring")
      local ragdoll_colour = Color(200, 200, 200)

      GAMEMODE.HUDDrawTargetID = function()
         local client = LocalPlayer()
         local trace = client:GetEyeTrace(MASK_SHOT)
         local ent = trace.Entity

         DrawPropSpecLabels(client)

         if (not IsValid(ent)) or ent.NoTarget then return end
         
         local target_traitor = false
         local target_detective = false
         local target_corpse = false
         local target_c4 = false
         local target_hs = false
         
         if IsValid(ent:GetNWEntity("ttt_driver", nil)) then
            ent = ent:GetNWEntity("ttt_driver", nil)

            if ent == client then return end
         end 
         
         local class = ent:GetClass()
         local minimal = minimalist:GetBool()
         local hint = (not minimal) and (ent.TargetIDHint or ClassHint[class]) 
         local tag_text, tag_text_colour, panel_text_colour = "", text_colour.lighter, text_colour.lighter

         if ent:IsPlayer() then
            if ent:GetNWBool("disguised", false) then
               client.last_id = nil 
               
               if client:IsTraitor() or client:IsSpec() then 
                  text = ent:Nick() 
               else return end
            else
               text = ent:Nick()
               client.last_id = ent
            end
            
            if (ent.sb_tag) then
               tag_text = ent.sb_tag.txt or ""
               tag_text_colour = ent.sb_tag.color
               
               if (tag_text) then
                  tag_text = FormatString(tag_text)
               end
            end
           
            if minimal then
               local hp_text = util.HealthToString(ent:Health())
               
               panel_text_colour = health_bar_light[hp_text]
            end 

            if client:IsTraitor() and GAMEMODE.round_state == ROUND_ACTIVE then
               target_traitor = ent:IsTraitor()
            end

            target_detective = ent:IsDetective()
         elseif (class == "prop_ragdoll") then
            if CORPSE.GetPlayerNick(ent, false) == false then return end
            
            target_corpse = true

            if CORPSE.GetFound(ent, false) or not DetectiveMode() then
               text = CORPSE.GetPlayerNick(ent, "A Terrorist")
               panel_text_colour = text_colour.light
            else
               local L = GetLang()
               text  = L.target_unid
               panel_text_colour = COLOR_YELLOW
            end
         elseif (class == "ttt_c4") then
            target_c4 = true
            
            text = "C-4 Explosive"
            panel_text_colour = text_colour.light
         elseif (class == "ttt_health_station") then
            target_hs = true
            
            text = "Health Station"
            panel_text_Colour = text_colour.light
         elseif (class != "prop_ragdoll") and (class != "ttt_c4") and (class != "ttt_health_station") then
            text = nil
         elseif not hint then return end
         
         if GetRoundState() != ROUND_PREP then 
            if target_traitor or target_detective then
               surface.SetTexture(ring_texture)

               if target_traitor then
                  surface.SetDrawColor(role_light.traitor)
               else
                  surface.SetDrawColor(role_light.detective)
               end
               surface.DrawTexturedRect(x/2-32, y/2-32, 64, 64)
            end
         end
         
         surface.SetFont("midnight_font_15")
         
         if (text) then
            w, h = surface.GetTextSize(text)
            w = w+32

            BorderedRect(x/2, y/2+40, w, 26, panel.main_light, panel.border, true, true, true, true, true, true) 
                        
            if (!minimal) then
               local L = GetLang()
               local status_effects = {}
               local status_effect_colour 
               local hp_text = util.HealthToString(ent:Health())
               local hp_colour = health_bar_light[hp_text]
               local health_text, hint_text = L[hp_text], ""
               local k_text, k_colour, karma_text

               if (!target_corpse) and (ent:IsPlayer()) then
                  k_text = util.KarmaToString(ent:GetBaseKarma()) 
                  k_colour = karma_colour[k_text]
                  karma_text = L[k_text]
                  
                  if (hp_text) then table.insert(status_effects, health_text) end
                  if (k_text) then table.insert(status_effects, karma_text) end
               end
               
               if (ent.sb_tag) then table.insert(status_effects, tag_text) end
               if (ent:GetNWBool("disguised", false)) then table.insert(status_effects, "Disguised") end
               if (ent:GetNWBool("Poisoned")) then table.insert(status_effects, "Poisoned") end
               if (ent:IsPlayer()) and (ent:IsOnFire()) then table.insert(status_effects, "Burning") end
               if (ent:IsPlayer()) and (ent:IsFrozen()) then table.insert(status_effects, "Frozen") end
               
               if (target_corpse) or (target_c4) or (target_hs) then
                  if (#status_effects >= 1) then
                     table.Empty(status_effects)
                  end

                  if hint and hint.hint then
                     if not hint.fmt then
                        hint_text = GetRaw(hint.hint) or hint.hint
                     else
                        hint_text = hint.fmt(ent, hint.hint)
                     end
                     
                     if !CORPSE.GetFound(ent, false) then
                        dst(hint_text, "TabSmall", x/2, y/2+72, text_colour.light, TEXT_ALIGN_CENTER)
                     end
                  end
               end 

               if (status_effects) then
                  dst(text, "midnight_font_15", x/2, y/2+46, panel_text_colour, TEXT_ALIGN_CENTER)
                  
                  for k, v in pairs(status_effects) do
                     if v == health_text then status_effect_colour = hp_colour
                     elseif v == karma_text then status_effect_colour = k_colour
                     elseif v == tag_text then status_effect_colour = tag_text_colour 
                     elseif v == "Disguised" then status_effect_colour = role_light["traitor"]
                     elseif v == "Poisoned" then status_effect_colour = Color(122, 208, 75)
                     elseif v == "Burning" then status_effect_colour = Color(157, 43, 15) 
                     elseif v == "Frozen" then status_effect_colour = role_light["detective"] end
                  
                     dst(v, "TabSmall", x/2, y/2+71+(k*12), status_effect_colour, TEXT_ALIGN_CENTER)
                  end
               else
                  dst(text, "midnight_font_15", x/2, y/2+46, panel_text_colour, TEXT_ALIGN_CENTER)
               end
            else
               dst(text, "midnight_font_15", x/2, y/2+46, panel_text_colour, TEXT_ALIGN_CENTER)
            end
                           
            if (!target_corpse) and (!minimal) then   
               local health_percentage = ((math.Clamp(ent:Health(), 0, 100)/100)*w)

               if ent:IsPlayer() then
                  local health_bar_dark, health_bar_light = HealthBarColours(ent)
                  
                  BorderedRect(x/2-(w/2), y/2+72, w, 7, health_bar_dark, panel.border, true, true, true, true, false, true) 
                  BorderedRect(x/2-(w/2), y/2+72, health_percentage, 7, health_bar_light, panel.border, false, false, false, false, false, true) 
               end 
            end
         end   
      end

      local mstack_margin, msg_width = 6, 400
      local text_width = msg_width-(mstack_margin*3)
      local text_height = draw.GetFontHeight("midnight_font_13")
      local top_y = mstack_margin-5
      local top_x = x-mstack_margin-msg_width-1
      local duration, max_items, fadein, fadeout, movespeed = 12, 8, 0.05, 0.05, 2
      local msg_sound = Sound("Hud.Hint")
      local base_spec = {
         font = "midnight_font_13",
         xalign = TEXT_ALIGN_CENTER,
         yalign = TEXT_ALIGN_TOP
      }

      function MSTACK:Draw(client)
         if next(self.msgs) == nil then return end

         local running_y = top_y
         for k, item in pairs(self.msgs) do
            if item.time < CurTime() then
               if item.sounded == false then
                  client:EmitSound(msg_sound, 80, 250)
                  item.sounded = true
               end

               local spec = base_spec
               local height = item.height
               local y = running_y+mstack_margin+item.move_y
               local delta = (item.time+duration)-CurTime()
               local alpha = 255
               
               item.move_y = (item.move_y < 0) and item.move_y+movespeed or 0
               delta = delta/duration

               if k >= max_items then delta = delta/2 end

               if delta > 1-fadein then
                  alpha = math.Clamp((1.0-delta)*(255/fadein), 0, 255)
               elseif delta < fadeout then
                  alpha = math.Clamp(delta*(255/fadeout), 0, 255)
               end
       
               local alpha = math.Clamp(alpha, 0, 255)    
               local m, b, neutral, traitor, detective, t = panel.main_light, panel.border, panel.top_light, role_light.traitor, role_light.detective, text_colour.lightest
               
               local m = Color(panel.main_light.r, panel.main_light.g, panel.main_light.b, panel.main_light.a)
               local b = Color(panel.border.r, panel.border.g, panel.border.b, panel.border.a)
               local neutral = Color(panel.top_light.r, panel.top_light.g, panel.top_light.b, panel.top_light.a)
               local traitor = Color(role_light.traitor.r, role_light.traitor.g, role_light.traitor.b, role_light.traitor.a)
               local detective = Color(role_light.detective.r, role_light.detective.g, role_light.detective.b, role_light.detective.a)
               local t = Color(text_colour.lightest.r, text_colour.lightest.g, text_colour.lightest.b, text_colour.lightest.a)
               
               m.a, b.a, neutral.a, traitor.a, detective.a, t.a = alpha, alpha, alpha, alpha, alpha, alpha

               if item.bg == Color(150, 0, 0, 200) then
                  BorderedRect(top_x, y, 8, height, traitor, b, true, false, true, true, false, true) 
                  BorderedRect(top_x+8, y, msg_width-8, height, m, b, true, true, true, false, false, true) 
               elseif item.bg == Color(0, 0, 150, 200) then
                  BorderedRect(top_x, y, 8, height, detective, b, true, false, true, true, false, true) 
                  BorderedRect(top_x+8, y, msg_width-8, height, m, b, true, true, true, false, false, true) 
               else
                  BorderedRect(top_x, y, msg_width, height, m, b, true, true, true, true, false, true) 
               end 

               spec.color = t
       
               for i = 1, #item.text do
                  spec.text=item.text[i]

                  local tx = top_x+(msg_width/2)
                  local ty = y+mstack_margin+(i-1)*(text_height+mstack_margin)
                  spec.pos={tx, ty}

                  draw.TextShadow(spec, 1, alpha) 
               end

               if alpha == 0 then 
                  self.msgs[k] = nil 
               end

               running_y = y+height
            end
         end
      end

      function WSWITCH:DrawBarBg(x, y, w, h, colour)
         local role_string = string.lower(GetRole() or client:GetRoleString())
         local role_colour = role_light[role_string]
         
         if GetRoundState() == ROUND_PREP then role_colour = role_light.prep end

         BorderedRect(x-57, y-14, 30, 30, role_colour, panel.border, false, false, false, false, false, false) 
         BorderedRect(x-27, y-14, width+30, 30, colour.background, panel.border, false, false, false, false, false, false) 
      end

      function WSWITCH:DrawWeapon(x, y, colour, weapon) 
         if not IsValid(weapon) then return false end

         local clip, max, inv, invmax = weapon:Clip1() or 0, weapon.Primary.ClipSize or 0, weapon:Ammo1() or 0, weapon.ClipMax or 0
         local name = TryTranslation(weapon:GetPrintName() or weapon.PrintName or "Spoooky!")
         local y = y-1

         name = FormatString(name)

         dst(weapon.Slot+1, "midnight_font_13", x-42, y, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         dst(name, "midnight_font_13", x-12, y, colour.text_weapon, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

         if clip != -1 then
            local colour_total, colour_current = colour.text_ammo, colour.text_ammo
            
            if clip == 0 then
               colour_total = colour.text_empty
            elseif clip/max <= 0.25 then
               colour_total = colour.text_low
            end
            
            if inv == 0 then
               colour_current = colour.text_empty
            elseif inv/invmax <= 0.25 then
               colour_current = colour.text_low
            end
            
            if clip < 10 then clip = "0"..clip end
            if inv < 10 then inv = "0"..inv end
            
            local w, h = dst(inv, "midnight_font_13", ScrW()-margin*3, y, colour_current, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            local w2, h2 = dst("+", "midnight_font_13", ScrW()-margin *3-w-4, y, colour.text_ammo, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            dst(clip, "midnight_font_13", ScrW()-margin*3-w-w2-8, y, colour_total, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
         end

         return true
      end

      function WSWITCH:Draw(client)
         if not self.Show then return end

         local role_string = string.lower(GetRole() or client:GetRoleString())
         local role_colour = role_light[role_string]
         
         if GetRoundState() == ROUND_PREP then role_colour = role_light.prep end
         
         local weapons = self.WeaponCache
         local colour = colour_inactive
         
         local x = ScrW()-width-margin*2
         local y = ScrH()-(#weapons*(height+margin))
         
         for k, weapon in pairs(weapons) do
            if self.Selected == k then
               colour = colour_active
            else
               colour = colour_inactive
            end

            self:DrawBarBg(x, y, width, height, colour)
              
            if not self:DrawWeapon(x, y, colour, weapon) then
               self:UpdateWeaponCache()
               return
            end

            y = y+height+margin
         end
         
         if (#weapons) then
            BorderedRect(x-58, y-14, width+62, 2, panel.border, panel.border,  false, false, false, false, false, false)
         end
         
         for i = 1, #weapons do
            BorderedRect(x-58, y-14-(i*30), 1, 30, panel.border, panel.border, false, false, false, false, false, false)
            BorderedRect(ScrW()-13, y-14-(i*30), 1, 30, panel.border, panel.border, false, false, false, false, false, false)
         end
         
         for i = 1, #weapons-1 do
            BorderedRect(x-57, y-14-(i*30), 30, 1, panel.shade_dark, panel.border, false, false, false, false, false, false)
            BorderedRect(x-27, y-14-(i*30), width+30, 1, panel.border, panel.border, false, false, false, false, false, false)
         end
         
         for i = 1, #weapons, #weapons do
            BorderedRect(x-57, y-14-(i*#weapons*30), 30, 1, role_colour, panel.border, false, false, false, false, false, true)
            BorderedRect(x-27, y-14-(i*#weapons*30), width+30, 1, panel.shade_light, panel.border, false, false, false, false, false, false)
            BorderedRect(x-58, y-15-(i*#weapons*30), width+62, 1, panel.border, panel.border, false, false, false, false, false, false)
         end
      end

      function GAMEMODE:HUDDrawPickupHistory()
         if (GAMEMODE.PickupHistory == nil) then return end

         local y = GAMEMODE.PickupHistoryTop
         local wide, tall = 0, 0

         for k, v in pairs(GAMEMODE.PickupHistory) do
            if v.time < CurTime() then
               if (v.y == nil) then v.y = y end
               
               v.x = x
               v.y = (v.y*5+y)/6

               local delta = (v.time+v.holdtime)-CurTime()
               delta = delta/v.holdtime
               delta = math.Clamp(delta, 0, 1)

               v.name = FormatString(v.name)

               surface.SetFont("midnight_font_13")
                
               local w_name = surface.GetTextSize(v.name)
               local w_ammo = 0
               
               if v.amount then
                  w_ammo = surface.GetTextSize(" ["..v.amount.."]")
                  w_name = w_name + w_ammo
               end 
               
               local w_clamp, alpha = 0, 0

               if delta >= 0.85 then
                  w_clamp = 0
               elseif delta < 0.85 and delta > 0.8 then
                  w_clamp = math.Round(w_name*(1-((delta-0.8)*20)))
               elseif delta > 0.2 then
                  w_clamp = w_name*1
               elseif delta <= 0.2 and delta > 0.15 then
                  w_clamp = math.Round(w_name*((delta-0.15)*20))
               elseif delta <= 0.1 then
                  w_clamp = 0
               end
               
               if delta > 0.9 then
                  alpha = 1-((delta-0.9)*10)
               elseif delta < 0.1 then
                  alpha = delta*10
               else
                  alpha = 1
               end
               
               local w = math.max(w_clamp, 0)

               local role_string = string.lower(GetRole() or client:GetRoleString())
               local role_colour = Color(role_light[role_string].r, role_light[role_string].g, role_light[role_string].b, role_light[role_string].a*alpha)
               local main_colour = Color(panel.main_light.r, panel.main_light.g, panel.main_light.b, panel.main_light.a*alpha)
               local border = Color(panel.border.r, panel.border.g, panel.border.b, panel.border.a*alpha)

               if GetRoundState() == ROUND_PREP then role_colour = role_light.prep end   
               
               BorderedRect(x-55-w, v.y-18, 15, 24, role_colour, border, true, false, true, true, false, true)
               BorderedRect(x-40-w, v.y-18, w+27, 24, main_colour, border, true, true, true, false, false, true)
               
               render.SetScissorRect(x-40-w+10, v.y-18, x-30, v.y+6, true)
                  dst(v.name, "midnight_font_13", x-30-w_ammo, v.y-(v.height/2), text_colour.light, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                  if v.amount then
                     dst(" ["..v.amount.."]", "midnight_font_13", x-30, v.y - (v.height/2), text_colour.lightest, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                  end
               render.SetScissorRect(x-40-w, v.y-18, w, 24, false) 

               y = y+(v.height+16)
               wide = math.max(wide, v.width+v.height+24)
               tall = tall + v.height+18

               if delta == 0 then GAMEMODE.PickupHistory[k] = nil end
            end
         end  

         GAMEMODE.PickupHistoryTop = (GAMEMODE.PickupHistoryTop*5+(ScrH()*0.75-tall)/2)/6
         GAMEMODE.PickupHistoryWide = (GAMEMODE.PickupHistoryWide*5+wide)/6
      end

      GAMEMODE.HUDPaint = function() 
         local client = LocalPlayer()
         
         GAMEMODE:HUDDrawTargetID()
         MSTACK:Draw(client)

         if (!client:Alive()) or client:Team() == TEAM_SPEC then
           return
         end

         RADAR:Draw(client)
         TBHUD:Draw(client)
         WSWITCH:Draw(client)
         VOICE.Draw(client)
         DISGUISE.Draw(client)
         GAMEMODE:HUDDrawPickupHistory()
      end
       
      hook.Add("HUDPaint", "midnight", function()
         local client = LocalPlayer()
      
         if (SpecDM) then
            if (client:IsGhost()) then return end
         end
      
         local role_colour_dark = (role_dark[string.lower(GetRole() or client:GetRoleString())] or role_dark["innocent"])
         local role_colour_light = (role_light[string.lower(GetRole() or client:GetRoleString())] or role_light["innocent"])
         local role_string = string.upper(string.lower(GetRole() or client:GetRoleString()))
         local is_haste = HasteMode() and GetRoundState() == ROUND_ACTIVE
         local is_traitor = client:IsTraitor() or !client:Alive()
         local hastetime = GetGlobalFloat("ttt_haste_end", 0)-CurTime()
         local endtime = GetGlobalFloat("ttt_round_end", 0)-CurTime()
         local overtime = false
         local round_time
          
         if GetRoundState() == ROUND_PREP then 
            role_colour_dark = role_dark.prep
            role_colour_light = role_light.prep
            role_string = "PREPARING"
         end
         
         if (is_haste) then
            hastetime = GetGlobalFloat("ttt_haste_end", 0)-CurTime()
            if (hastetime < 0) then
               if (!is_traitor) or (math.ceil(CurTime())%7<=2) then 
                  local L = GetLang()
                  round_time = L.overtime
                  overtime = true
               else
                  round_time = string.ToMinutesSeconds(math.max(0, endtime))
               end
            else
               local t = hastetime
               if (is_traitor) and math.ceil(CurTime())%6<2 then
                  t = endtime 
               end
               round_time = string.ToMinutesSeconds(math.max(0, t))
            end
         else
            round_time = string.ToMinutesSeconds(math.max(0, endtime))
         end

         local function ShouldDraw()
            BorderedRect(13, y-128, 33, 114, role_colour_light, panel.border, true, false, false, true, false, true)
            BorderedRect(46, y-128, 335, 57, panel.main_light, panel.border, true, true, false, false, false, true)
            BorderedRect(13, y-71, 33, 57, Color(0, 0, 0, 65), panel.border, false, false, true, true, false, false)
            BorderedRect(46, y-71, 335, 57, panel.main_dark, panel.border, false, true, true, false, false, false)
            
            health_percentage = ((math.Clamp(client:Health(), 0, 100)/100)*(292))
            
            local hp_bar_dark, hp_bar_light = HealthBarColours(client)
            local title_text, premium_text = GetTitle()
            local colour = text_colour.light
            
            if GetRoundState() == ROUND_PREP  then
               BorderedRect(68, y-62, 292, 18, role_colour_dark, panel.border, true, true, true, true, false, true)
               BorderedRect(68, y-62, health_percentage, 18, role_colour_light, panel.border, false, false, false, false, false, true)
            else
               BorderedRect(68, y-62, 292, 18, hp_bar_dark, panel.border, true, true, true, true, false, true)
               BorderedRect(68, y-62, health_percentage, 18, hp_bar_light, panel.border, false, false, false, false, false, true)
            end
            
            clip, max, inv, invmax = GetAmmo()
            ammo_percentage = (clip/(max or 1))*(292)

            BorderedRect(68, y-38, 292, 9, panel.top_dark, panel.border, true, true, true, true, false, true)
            BorderedRect(68, y-38, ammo_percentage, 9, panel.top_light, panel.border, false, false, false, false, false, true)
            
            dst(role_string, "midnight_font_28", 68, y-120, text_colour.dark, TEXT_ALIGN_LEFT)
            dst(round_time, "midnight_font_28", 360, y-120, text_colour.dark, TEXT_ALIGN_RIGHT)
            dst(title_text, "midnight_font_15", 68, y-95, colour, TEXT_ALIGN_LEFT)
            
            if (premium_text) then
               dst(premium_text, "midnight_font_15", 68, y-85, text_colour.light, TEXT_ALIGN_LEFT)
            end
            
            dst("Time Remaining", "midnight_font_15", 360, y-95, text_colour.dark, TEXT_ALIGN_RIGHT)
            dst(string.Comma(client:Health()), "midnight_font_15", 74, y-60, text_colour.dark, TEXT_ALIGN_LEFT)
            if (!overtime) and (is_haste) then dst("HASTE", "midnight_font_11", 290, y-107, text_colour.dark, TEXT_ALIGN_RIGHT) end

            if clip != -1 then
               if clip < 10 then clip = "0"..clip end
               if inv < 10 then inv = "0"..inv end
            end
            
            surface.SetFont("midnight_font_15")
            
            if clip != -1 then
               w, h = surface.GetTextSize(inv)
               
               dst(clip, "midnight_font_15", 334-w, y-60, text_colour.dark, TEXT_ALIGN_RIGHT)
               dst("+", "midnight_font_15", 344-w, y-60, text_colour.dark, TEXT_ALIGN_CENTER)
               dst(inv, "midnight_font_15", 354, y-60, text_colour.dark, TEXT_ALIGN_RIGHT)
            end
         end
         
         if client:Alive() and client:Team() != TEAM_SPECTATOR and GetRoundState() != ROUND_WAIT then
            if (show_preround) and GetRoundState() == ROUND_PREP then 
               ShouldDraw()
            elseif GetRoundState() != ROUND_PREP then
               ShouldDraw()
            end
         else
            surface.SetFont("midnight_font_13")
            
            local target = client:GetObserverTarget()
            local punches = client:GetNWFloat("specpunches", 0)
            local L = GetLang()

            if IsValid(target) and target:IsPlayer() then
               local w_name = surface.GetTextSize(target:Nick())
               
               BorderedRect(x/2, 13, w_name+32, 24, panel.main_light, panel.border, true, true, true, true, true, true)
               dst(target:Nick(), "midnight_font_13", x/2, 25, text_colour.light, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif IsValid(target) and target:GetNWEntity("spec_owner", nil) == client then
               local punch_percentage = (punches) * 180
               
               BorderedRect(x/2, 13, 180, 24, panel.main_light, panel.border, true, true, true, true, true, true)
               dst(string.upper((L.punch_title or "PUNCH-O-METER")), "midnight_font_13", x/2, 25, text_colour.light, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
               BorderedRect(x/2, 43, 180, 6, panel.top_dark, panel.border, true, true, true, true, true, true)
               BorderedRect(x/2-90, 43, punch_percentage, 6, panel.top_light, panel.border, false, false, false, false, false, true)
            else
               BorderedRect(x/2, 13, 520, 24, panel.main_light, panel.border, true, true, true, true, true, true) 
               dst(string.upper(string.Interp(L.spec_help, {usekey = Key("+use", "USE")})), "midnight_font_13", x/2, 25, text_colour.lighter, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
         end 
         
         surface.SetFont("midnight_font_21") 
         
         local L = GetLang()
         local round_state = L[round_state_string[GetRoundState()]]
         local w_round_time = surface.GetTextSize(round_time)
         local w_round_state = surface.GetTextSize(round_state)
       
         if GetRoundState() == ROUND_PREP and client:Alive() and client:Team() != TEAM_SPECTATOR then
            if (show_preround) then
               BorderedRect(13, y-162, w_round_time+20, 25, panel.main_dark, panel.border, true, false, true, true, false, true)
               dst(round_time, "midnight_font_21", 23, y-160, text_colour.lighter, TEXT_ALIGN_LEFT)
               BorderedRect(13+w_round_time+20, y-162, w_round_state+38, 25, panel.main_lighter, panel.border, true, true, true, false, false, true)
               dst(string.upper(round_state), "midnight_font_21", 13+w_round_time+30, y-160, text_colour.dark, TEXT_ALIGN_LEFT)
            else
               BorderedRect(13, y-40, w_round_time+20, 25, panel.main_dark, panel.border, true, false, true, true, false, true)
               dst(round_time, "midnight_font_21", 23, y-38, text_colour.lighter, TEXT_ALIGN_LEFT)
               BorderedRect(13+w_round_time+20, y-40, w_round_state+38, 25, panel.main_lighter, panel.border, true, true, true, false, false, true)
               dst(string.upper(round_state), "midnight_font_21", 13+w_round_time+30, y-38, text_colour.dark, TEXT_ALIGN_LEFT)
            end
         elseif !client:Alive() or client:Team() == TEAM_SPECTATOR then
            BorderedRect(13, y-40, w_round_time+20, 25, panel.main_dark, panel.border, true, false, true, true, false, true)
            dst(round_time, "midnight_font_21", 23, y-38, text_colour.lighter, TEXT_ALIGN_LEFT)
            BorderedRect(13+w_round_time+20, y-40, w_round_state+38, 25, panel.main_lighter, panel.border, true, true, true, false, false, true)
            dst(string.upper(round_state), "midnight_font_21", 13+w_round_time+30, y-38, text_colour.dark, TEXT_ALIGN_LEFT)
         end
      end)
   end
end)