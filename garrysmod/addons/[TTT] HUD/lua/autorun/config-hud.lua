midnight_hud = {}
midnight_hud.config = {}

--[[  Name: Health/Ammo panel config.
      Description: Changes the main hud panel at the bottom left of your screen. ]]--

midnight_hud.config.coloured_health = true -- Health-based health bar colours as innocent?
midnight_hud.config.show_preround = true -- Show Health/Ammo panel during preparation?

--[[  Name: Health/Ammo sub-text config.
      Description: Changes the text that appears under the name of your role. ]]--
      
midnight_hud.config.group_show = true -- Show automatically assigned usergroup based on your admin mod?
midnight_hud.config.group_text = "" -- If not, then what text would you like to display? Leave as "" to display nothing.
midnight_hud.config.pointshop = false -- Display Pointshop currency in place of usergroup?
midnight_hud.config.pointshop2 = false -- Display Pointshop 2 currency in place of usergroup?
midnight_hud.config.pointshop2_show_premium = false -- Show premium points in addition to regular points?
midnight_hud.config.pointshop2_points_name = "Points" -- Name of regular currency to display.
midnight_hud.config.pointshop2_premium_points_name = "Premium Points"  -- Name of premium currency to display.

--[[  Name: Voicechat rank prefix config.
      Description: Defines a prefix for certain usergroups when using voicechat. ]]--
      
midnight_hud.config.voice = {
   ["superadmin"] = "[S-A]",
   ["admin"] = "[A]"
}

--[[  Name: Colour scheme config.
      Description: Changes the colours used, in case the theme does not suit your preference. ]]--

midnight_hud.panel = {}
midnight_hud.panel.main_dark = Color(43, 49, 55)
midnight_hud.panel.main_light = Color(48, 53, 61)
midnight_hud.panel.main_lighter = Color(55, 61, 67)
midnight_hud.panel.top_dark = Color(101, 111, 123)
midnight_hud.panel.top_light = Color(116, 126, 138)
midnight_hud.panel.border = Color(39, 41, 43, 255)
midnight_hud.panel.shade_dark = Color(0, 0, 0, 80)
midnight_hud.panel.shade_light = Color(255, 255, 255, 4)
midnight_hud.panel.shade_lighter = Color(255, 255, 255, 12)

midnight_hud.text_colour = {}
midnight_hud.text_colour.dark = Color(28, 30, 32)
midnight_hud.text_colour.light = Color(116, 126, 138)
midnight_hud.text_colour.lighter = Color(151, 161, 173)
midnight_hud.text_colour.lightest = Color(171, 181, 193)
midnight_hud.text_colour.white = Color(237, 237, 237)
midnight_hud.text_colour.spectate = Color(200, 200, 0, 140)

midnight_hud.role_dark = {}
midnight_hud.role_dark.innocent = Color(130, 185, 60)
midnight_hud.role_dark.traitor = Color(185, 40, 20)
midnight_hud.role_dark.detective = Color(46, 80, 180)
midnight_hud.role_dark.prep = Color(116, 126, 138)

midnight_hud.role_light = {}
midnight_hud.role_light.innocent = Color(170, 225, 100)
midnight_hud.role_light.traitor = Color(205, 60, 40)
midnight_hud.role_light.detective = Color(66, 100, 200)
midnight_hud.role_light.prep = Color(151, 161, 173)

midnight_hud.health_bar_dark = {}
midnight_hud.health_bar_dark.healthy = Color(130, 185, 60)
midnight_hud.health_bar_dark.hurt = Color(130, 180, 0)
midnight_hud.health_bar_dark.wounded = Color(180, 165, 0)
midnight_hud.health_bar_dark.badly_wounded = Color(205, 90, 0)
midnight_hud.health_bar_dark.near_death = Color(185, 40, 20)

midnight_hud.health_bar_light = {}
midnight_hud.health_bar_light.healthy = Color(170, 225, 100)
midnight_hud.health_bar_light.hurt = Color(170, 230, 10)
midnight_hud.health_bar_light.wounded = Color(230, 215, 10)
midnight_hud.health_bar_light.badly_wounded = Color(255, 140, 0)
midnight_hud.health_bar_light.near_death = Color(205, 60, 40)

midnight_hud.karma_colour = {}
midnight_hud.karma_colour.karma_max = Color(210, 200, 50)
midnight_hud.karma_colour.karma_high = Color(220, 170, 50)
midnight_hud.karma_colour.karma_med = Color(230, 140, 50)
midnight_hud.karma_colour.karma_low = Color(240, 110, 50)
midnight_hud.karma_colour.karma_min = Color(250, 80, 50)

midnight_hud.voice = {}
midnight_hud.voice.spectate_dark = Color(200, 200, 0, 140)
midnight_hud.voice.spectate_light = Color(200, 200, 0, 200)

midnight_hud.tag_colour = {}
midnight_hud.tag_colour.friend = Color(170, 225, 100)
midnight_hud.tag_colour.suspect = Color(230, 215, 10)
midnight_hud.tag_colour.avoid = Color(255, 140, 0)
midnight_hud.tag_colour.kill = Color(205, 60, 40)
midnight_hud.tag_colour.missing = Color(130, 190, 130)

midnight_hud.tag_text = {}
midnight_hud.tag_text.friend = "Friend"
midnight_hud.tag_text.suspect = "Suspect"
midnight_hud.tag_text.avoid = "Avoid"
midnight_hud.tag_text.kill = "Kill"
midnight_hud.tag_text.missing = "Missing"

if (CLIENT) then
      surface.CreateFont("midnight_font_28", {font = "Tahoma", size = 28, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_21", {font = "Tahoma", size = 21, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_15", {font = "Tahoma", size = 15, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_13", {font = "Tahoma", size = 13, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_12", {font = "Tahoma", size = 12, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_11", {font = "Tahoma", size = 11, weight = 1000, antialias = true}) 
      surface.CreateFont("TabLarge", {font = "Tahoma", size = 13, weight = 700, shadow = true, antialias = false})
      surface.CreateFont("TabSmall", {font = "Tahoma", size = 11, weight = 700, shadow = true, antialias = false})
end


