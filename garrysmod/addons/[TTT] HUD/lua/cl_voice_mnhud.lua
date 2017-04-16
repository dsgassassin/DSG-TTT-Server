hook.Add("PostGamemodeLoaded", "midnight_voice", function()    
   if (gmod.GetGamemode().Name == "Trouble in Terrorist Town") then

      local PANEL = {}
      local voice_panel = {}

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
         ["white"] =  midnight_hud.text_colour.white,
         ["spectate"] = midnight_hud.text_colour.spectate
      }

      local role_dark = {
         ["innocent"] =  midnight_hud.role_dark.innocent,
         ["traitor"] = midnight_hud.role_dark.traitor,
         ["detective"] = midnight_hud.role_dark.detective
      }

      local role_light = {
         ["innocent"] = midnight_hud.role_light.innocent,
         ["traitor"] = midnight_hud.role_light.traitor,
         ["detective"] = midnight_hud.role_light.detective
      }

      local voice = {
         ["spectate_dark"] = midnight_hud.voice.spectate_dark,
         ["spectate_light"] = midnight_hud.voice.spectate_light,
      }

      local function BorderedRect(x, y, w, h, main, border, shade, bt, br, bb, bl, centered, shaded)
         if (centered) then offset = (w/2) bx = -1 else offset = 0 bx = (w-1) end
       
         surface.SetDrawColor(main)
         surface.DrawRect(x-offset, y, w, h)
         
         if (shaded) then 
            surface.SetDrawColor(shade)
            surface.DrawRect(x-offset, y, w, 1)
         end

         if (bt) or (br) or (bb) or (bl) then surface.SetDrawColor(border) end
         if (bt) then surface.DrawRect(x-offset, y-1, w, 1) end
         if (br) then surface.DrawRect(x+offset+bx+1, y-1, 1, h+3) end
         if (bb) then surface.DrawRect(x-offset, y+h, w, 2) end
         if (bl) then surface.DrawRect(x-offset-1, y-1, 1, h+3) end
      end

      function PANEL:Init()
         self.Label = vgui.Create("DLabel", self)
         self.Label:SetFont("midnight_font_13")
         self.Label:Dock(FILL)
         self.Label:DockMargin(9, -10, 1, 2)
         self.Label:SetTextColor(text_colour.light)
         self.Label:SetExpensiveShadow(1, Color(0, 0, 0, 190))
         
         self.Avatar = vgui.Create("AvatarImage", self)
         self.Avatar:Dock(LEFT)
         self.Avatar:SetSize(32, 32)

         self:SetSize(250, 40)
         self:DockPadding(4, 4, 4, 4)
         self:DockMargin(2, 2, 2, 2)
         self:Dock(BOTTOM)
         self:GetParent():SetSize(240, ScrH()-200)
      end

      function PANEL:Setup(ply)
         local client = LocalPlayer()
         self.ply = ply
       
         local name_colour = text_colour.lightest

         if client:IsActiveTraitor() then
            if ply == client then
               if not client.traitor_gvoice then
                  name_colour = role_light.traitor
               end
            elseif ply:IsActiveTraitor() then
               if not ply.traitor_gvoice then
                  name_colour = role_light.traitor
               end
            end
         end
         
         if self.ply:IsActiveTraitor() and not self.ply.traitor_gvoice then
            name_colour = role_light.traitor
         elseif self.ply:IsActiveDetective() then
            name_colour = role_light.detective
         elseif self.ply:IsSpec() then
            name_colour = text_colour.spectate
         else
            name_colour = text_colour.lightest
         end
         
         self.Label:SetText(self.ply:Nick())
         
         for group, prefix in pairs(midnight_hud.config.voice) do
            if self.ply:IsUserGroup(group) or self.ply:GetUserGroup() == group then
               self.Label:SetText(prefix.." "..self.ply:Nick())
            end
         end
   
         self.Label:SetTextColor(name_colour)
         self.Avatar:SetPlayer(self.ply)
         self:InvalidateLayout()
         self.r_paint = self.Paint
      end

      function PANEL:Paint(w, h)
         if (!IsValid(self.ply)) then return end
         
         local client = LocalPlayer()
         local voice_bar_dark, voice_bar_light = panel.top_dark, panel.top_light

         if client:IsActiveTraitor() then
            if self.ply == client then
               if not client.traitor_gvoice then
                  voice_bar_dark = role_dark.traitor
                  voice_bar_light = role_light.traitor
               end
            elseif self.ply:IsActiveTraitor() then
               if not self.ply.traitor_gvoice then
                  voice_bar_dark = role_dark.traitor
                  voice_bar_light = role_light.traitor
               end
            end
         end
         
         if self.ply:IsActiveTraitor() and not self.ply.traitor_gvoice then
            voice_bar_dark = role_dark.traitor
            voice_bar_light = role_light.traitor
         elseif self.ply:IsActiveDetective() then
            voice_bar_dark = role_dark.detective
            voice_bar_light = role_light.detective
         elseif self.ply:IsSpec() then
            voice_bar_dark = voice.spectate_dark
            voice_bar_light = voice.spectate_light
         else
            voice_bar_dark = panel.top_dark
            voice_bar_light = text_colour.lighter
         end

         BorderedRect(1, 1, w-47, h-3, panel.main_light, panel.border, panel.shade_light, true, true, true, true, false, true) 
         BorderedRect(45, 26, 136, 6, voice_bar_dark, panel.border, panel.shade_light, true, true, true, true, false, true) 

         if self.ply:VoiceVolume() > 0.01 then
            BorderedRect(45, 26, 136*self.ply:VoiceVolume(), 6, voice_bar_light, panel.border, panel.shade_light, false, false, false, false, false, true) 
         end
      end

      function PANEL:Think()
         if self.Paint != self.r_paint then
            self.Paint = self.r_paint
         end
      end
      
      derma.DefineControl("VoiceNotify", "", PANEL, "DPanel")
   end
end)