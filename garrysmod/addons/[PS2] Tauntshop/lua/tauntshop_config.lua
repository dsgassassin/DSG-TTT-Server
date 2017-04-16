print("Config loaded!")

TAUNTSHOP = TAUNTSHOP or {}
TAUNTSHOP.SaveMethod = "mysql" --use "mysql" to save to a MySQL db, "gmod" saves to your server's local db
TAUNTSHOP.DonorGroups = {"vip_user", "vip_moderator", "vip_senior_moderator", "vip_admin", "vip_sadmin", "vip_superadmin"} --Add your donator usergroups here
TAUNTSHOP.TauntTime = 3 --How long (in seconds) till you can taunt again
TAUNTSHOP.DefaultKey = KEY_G --the default taunt key (press this to play taunts)
TAUNTSHOP.Currency = "pointshop2" --can be "pointshop", "pointshop2", or "darkrp"

---DB STUFF
TAUNTSHOP.DB = {}
TAUNTSHOP.DB.Hostname = "0x3g3n.info" --your database's address
TAUNTSHOP.DB.Username = "dsg_user" --username
TAUNTSHOP.DB.Password = "Ash171994" --password
TAUNTSHOP.DB.Database = "dsg_tauntshop" --database name

--load shit
include("sh_tauntshop.lua")
if SERVER then include("sv_tauntshop.lua"); include("tauntshop_db.lua") else include("cl_tauntshop.lua") end

--you can add your custom taunts down here
/*TAUNTSHOP.RegisterTaunt(id, name, path, duration, price, donor)
	id is your taunt's unique name
	name is the name that will be shown in the menu
	path is the taunt's sound path (relative to garrysmod/sound)
	duration is the taunt's length (this should be as accurate as possible)
	price is your taunt's price (both in pointshop points and darkrp money)
	donor sets whether the taunt should be avaible to everyone or only to certain groups
*/
	
TAUNTSHOP.RegisterTaunt("boomheadshot", "Boom Headshot", "taunts/taunt_boom.mp3", 1.7, 50000, true)
TAUNTSHOP.RegisterTaunt("pulpfiction", "English, motherf***er, do you speak it!?", "taunts/taunt_english.mp3", 2.3, 50000, true)
TAUNTSHOP.RegisterTaunt("following", "Why are you following me?", "taunts/taunt_following.mp3", 2.6, 50000, true)
TAUNTSHOP.RegisterTaunt("alleluja", "Alleluja", "taunts/taunt_holy.mp3", 1.8, 50000, true)
TAUNTSHOP.RegisterTaunt("evillaugh", "Evil Laugh", "taunts/taunt_laugh.mp3", 3.7, 50000, true)
TAUNTSHOP.RegisterTaunt("leeroy", "LEEEROOOOOY JEEEENKINS", "taunts/taunt_leeroy.mp3", 4.6, 50000, true)
TAUNTSHOP.RegisterTaunt("nomnomnom", "NOM NOM NOM", "taunts/taunt_nomnomtf2.mp3", 2, 50000, true)
TAUNTSHOP.RegisterTaunt("sparta", "THIS. IS. SPARTA", "taunts/taunt_sparta.mp3", 2.3, 50000, true)
TAUNTSHOP.RegisterTaunt("bulletproof", "I am bulletproof", "taunts/taunt_tf2heavy.mp3", 3.2, 50000, true)
TAUNTSHOP.RegisterTaunt("vader", "Power of the dark side", "taunts/taunt_vader.mp3", 4.6, 50000, true)
TAUNTSHOP.RegisterTaunt("wickedsick", "Wicked SICK!", "taunts/taunt_wickedsick.mp3", 2.6, 50000, true)
TAUNTSHOP.RegisterTaunt("weed", "Smoke weed everyday", "taunts/taunt_weed.mp3", 1.9, 50000, true)
TAUNTSHOP.RegisterTaunt("wreckingball", "Wrecking Ball", "taunts/taunt_wreck.mp3", 4, 50000, true)
 