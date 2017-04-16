CMV.Config = CMV.Config or {}
local cfg = CMV.Config

cfg.AutoPrefix = true -- Grab prefixes for gamemodes automatically
cfg.Prefixes = { -- If enabled, prefixes will be grabbed from the table.  Do not enable at the same time as AutoPrefix
    "ttt_"
}

cfg.BlacklistMaps = { -- Maps with the proper prefix that are not wanted in the pool
    "de_dust"
}

cfg.ExtraMaps = { -- Maps with different prefixes that are wanted in the map pool

}

cfg.ExtendMap = false -- Allow for the map to be extended
cfg.MapAmount = 16 -- Amount of maps in vote.  Please note, only input even numbers, or there will be errors
cfg.Cooldown = 4 -- Amount of maps before a map can be played again

cfg.VoteTime = 30 -- The amount of time in which the voting occurs
cfg.PostVoteTime = 5 -- The amount of time after the voting before the map changes

cfg.VoiceChat = true -- Voice chat enabled?
cfg.VoiceKey = KEY_X -- Specific key to be pressed for the chat

cfg.RTVCommand = "cmv_rtv" -- Consolec ommand for rocking the vote
cfg.RTVChatCommand = "rtv" -- Do not add ! or /, this is done automatically
cfg.RTVAmount = 2/3 -- Amount required to successfully rock the vote

-- Set votes per rank here
cfg.VotePower = {}
cfg.VotePower[ "superadmin" ] = 1

cfg.Prefix = "[Map Vote]] " -- Chat prefix
cfg.PrefixColor = Color( 255, 0, 0 ) -- Chat prefix color

cfg.HeadText = "Vote on the next map!" -- Top text
cfg.HeadTextColor = Color( 255, 255, 255 )

cfg.TimeColor = Color( 255, 255, 255 ) -- Time color before changing (last 5 seconds)
cfg.TimeEndingColor = Color( 255, 50, 50 ) -- Time color in last 5 seconds

cfg.CloseButton = true -- Show close button - doesn't require vote first 
cfg.VoteThenClose = false -- Enable this if you want the user to vote first

cfg.TimeBar = false -- Bar colors based on how much time is left (green to red)
cfg.BarColor = Color( 50, 255, 50 ) -- Bar color

cfg.ImageURL = "http://image.www.gametracker.com/images/maps/160x120/garrysmod/" -- Replace with your own link, map names must follow and be jpgs

cfg.PlayMusic = false -- Play music when the vote begins
cfg.MusicURL = { -- URLs for the music -- Must be an MP3
	""
}	
cfg.Volume = 80 -- Between 0 and 100