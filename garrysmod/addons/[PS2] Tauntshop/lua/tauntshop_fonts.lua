--fonts

surface.CreateFont("TauntTitle", {
	font = "Coolvetica",
	size = math.Clamp(ScreenScale(35), 0, 105),
	weight = 500,
	antialias = true
})

surface.CreateFont("TauntSubtitle", {
	font = "Coolvetica",
	size = math.Clamp(ScreenScale(7), 0, 21),
	weight = 500,
	antialias = true
})
 
surface.CreateFont("TauntButtonFont", {
	font = "BebasNeue",
	size = math.Clamp(ScreenScale(36), 0, 108),
	weight = 500,
	antialias = true
})

surface.CreateFont("TauntBoughtFont", {
	font = "BebasNeue",
	size = 54,
	weight = 500, 
	antialias = true
})

surface.CreateFont("BuyButtonFont", {
	font = "BebasNeue",
	size = math.Clamp(ScreenScale(12), 0, 36),
	weight = 500, 
	antialias = true
})

 surface.CreateFont("CashFont", {
	font = "BebasNeue",
	size = math.Clamp(ScreenScale(12), 0, 36),
	weight = 500, 
	antialias = true
}) 

surface.CreateFont("TauntSettings", {
	font = "Trebuchet MS",
	size = math.ceil(math.Clamp(ScreenScale(7.5), 0, 23)),
	weight = 500, 
	antialias = true
})

surface.CreateFont("TauntSettingsKey", {
	font = "Trebuchet MS",
	size = 36,
	weight = 800, 
	antialias = true
})