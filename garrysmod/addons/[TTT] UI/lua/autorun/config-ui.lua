midnight_ui = {}
midnight_ui.config = {}

--[[  Name: Colour scheme config.
      Description: Changes the colours used, in case the theme does not suit your preference. ]]--

midnight_ui.panel = {}
midnight_ui.panel.main_dark = Color(43, 49, 55)
midnight_ui.panel.main_light = Color(48, 53, 61)
midnight_ui.panel.main_lighter = Color(55, 61, 67)
midnight_ui.panel.top_dark = Color(101, 111, 123)
midnight_ui.panel.top_light = Color(116, 126, 138)
midnight_ui.panel.top_lighter = Color(131, 141, 153)
midnight_ui.panel.border = Color(39, 41, 43, 255)

midnight_ui.text_colour = {}
midnight_ui.text_colour.dark = Color(28, 30, 32)
midnight_ui.text_colour.light = Color(116, 126, 138)
midnight_ui.text_colour.lighter = Color(151, 161, 173)
midnight_ui.text_colour.lightest = Color(171, 181, 193)
midnight_ui.text_colour.white = Color(237, 237, 237)
midnight_ui.text_colour.spectate = Color(200, 200, 0, 140)

midnight_ui.role_dark = {}
midnight_ui.role_dark.innocent = Color(130, 185, 60)
midnight_ui.role_dark.traitor = Color(185, 40, 20)
midnight_ui.role_dark.detective = Color(46, 80, 180)
midnight_ui.role_dark.prep = Color(116, 126, 138)

midnight_ui.role_light = {}
midnight_ui.role_light.innocent = Color(170, 225, 100)
midnight_ui.role_light.traitor = Color(205, 60, 40)
midnight_ui.role_light.detective = Color(66, 100, 200)

if (CLIENT) then
      surface.CreateFont("midnight_font_68", {font = "Tahoma", size = 68, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_28", {font = "Tahoma", size = 28, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_21", {font = "Tahoma", size = 21, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_15", {font = "Tahoma", size = 15, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_14", {font = "Tahoma", size = 14, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_13", {font = "Tahoma", size = 13, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_12", {font = "Tahoma", size = 12, weight = 1000, antialias = true})
      surface.CreateFont("midnight_font_11", {font = "Tahoma", size = 11, weight = 1000, antialias = true}) 
      surface.CreateFont("TabLarge", {font = "Tahoma", size = 13, weight = 700, shadow = true, antialias = false})
      surface.CreateFont("TabSmall", {font = "Tahoma", size = 11, weight = 700, shadow = true, antialias = false})
end