midnight_sb = {}
midnight_sb.config = {}

--[[  Name: Scoreboard column config.
      Description: Add another column to display points? ]]--
      
midnight_sb.config.titles_enabled = true -- Enable the title column and coloured names?
midnight_sb.config.tagpos = 0 -- Used to reposition tags such as "Friend", "Suspect", "Missing", etc. as well as the search result icon.
midnight_sb.config.title_text = "Title" -- What do you want the title column to be labelled as?
midnight_sb.config.points_text = "Points" -- What do you want the "points" column to be labelled as?   
midnight_sb.config.pointshop = false -- Display how many Pointshop points people have on the scoreboard?
midnight_sb.config.pointshop2 = false -- Display how many Pointshop 2 points people have on the scoreboard?
  
 --[[  Name: Scoreboard title config.
       Description: Define titles and colours for usergroups, including a default for guests. ]]--

midnight_sb.config.titles = {
   ["superadmin"] = "Super Admin",
   ["admin"] = "Admin"
}

midnight_sb.config.colours = {
   ["superadmin"] = Color(255, 166, 117),
   ["admin"] = Color(235, 146, 97)
}

midnight_sb.config.default_group_name = "Guest" -- Default title to display for "guests".
midnight_sb.config.default_group_colour = Color(255, 215, 193) -- Default title colour to display for "guests".
midnight_sb.config.coloured_names = true -- Use colours for names as well as for titles?
midnight_sb.config.coloured_name_blacklist = {"user"} -- For which usergroups do you not want to have coloured names?

--[[  Name: Scoreboard map preview config.
      Description: Options for changing the map preview. ]]--
      
midnight_sb.config.map_preview = true -- Enable the map previews?
midnight_sb.config.map_source = "fastdl" -- Source of map icons. Set to either "fastdl" or "webhost".
midnight_sb.config.map_url = "http://www.google.co.uk/" -- If using a webhost, where should we look for the icons?

--[[  Name: Scoreboard logo config.
      Description: Enable, change path and positioning of the custom logo. ]]--

midnight_sb.config.logo_custom = false -- Are you using a custom logo?
midnight_sb.config.logo_path = "community_materials/logo.png" -- Path to the logo that you want to appear on the scoreboard in .png format.
midnight_sb.config.logo_offset_x = -145 -- Logo "x" position for fine-tuning.
midnight_sb.config.logo_offset_y = 81 -- Logo "y" position for fine-tuning.
midnight_sb.config.logo_scale = 1 -- Scale of the logo. Should be between 0.0 and 1.0

--[[  Name: Colour scheme config.
      Description: Changes the colours used, in case the theme does not suit your preference. ]]--

midnight_sb.panel = {}
midnight_sb.panel.main_dark = Color(43, 49, 55)
midnight_sb.panel.main_light = Color(48, 53, 61)
midnight_sb.panel.main_lighter = Color(55, 61, 67)
midnight_sb.panel.top_dark = Color(101, 111, 123)
midnight_sb.panel.top_light = Color(116, 126, 138)
midnight_sb.panel.border = Color(39, 41, 43, 255)
midnight_sb.panel.shade_dark = Color(0, 0, 0, 80)
midnight_sb.panel.shade_light = Color(255, 255, 255, 4)
midnight_sb.panel.shade_lighter = Color(255, 255, 255, 12)

midnight_sb.text_colour = {}
midnight_sb.text_colour.dark = Color(28, 30, 32)
midnight_sb.text_colour.light = Color(116, 126, 138)
midnight_sb.text_colour.lighter = Color(151, 161, 173)
midnight_sb.text_colour.lightest = Color(171, 181, 193)
midnight_sb.text_colour.white = Color(237, 237, 237)
midnight_sb.text_colour.spectate = Color(200, 200, 0, 140)

midnight_sb.tag_colour = {}
midnight_sb.tag_colour.friend = Color(170, 225, 100)
midnight_sb.tag_colour.suspect = Color(230, 215, 10)
midnight_sb.tag_colour.avoid = Color(255, 140, 0)
midnight_sb.tag_colour.kill = Color(205, 60, 40)
midnight_sb.tag_colour.missing = Color(130, 190, 130)

midnight_sb.tag_text = {}
midnight_sb.tag_text.friend = "Friend"
midnight_sb.tag_text.suspect = "Suspect"
midnight_sb.tag_text.avoid = "Avoid"
midnight_sb.tag_text.kill = "Kill"
midnight_sb.tag_text.missing = "Missing"
