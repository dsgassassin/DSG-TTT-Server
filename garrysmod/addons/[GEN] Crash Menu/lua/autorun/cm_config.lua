CM = {}

//Increase this if the menu shows on map change.
CM.DelayTime = 5

//What's the title?
CM.Title = "Sorry"

//What message do you want to display when the server has crashed?
CM.Message = "Looks like My Cool Server has crashed. Check out our other servers or wait for the server to restart and reconnect."

//What is the estimated time in seconds it takes for the server to restart after a crash?
CM.ServerRestartTime = 30

CM.BackgroundColor = Color(52, 152, 219)

CM.ButtonColor = Color(236, 240, 241)
CM.ButtonHoverColor = Color(41, 128, 185)

CM.TitleTextColor = Color(236, 240, 241)
CM.MessageTextColor = Color(236, 240, 241)
CM.ButtonTextColor = Color(52, 152, 219)

/*
Insert the YouTube video ID if you want music.
Example:
If the YouTube link is: https://www.youtube.com/watch?v=2HQaBWziYvY then 'YouTubeURL = "2HQaBWziYvY"'.

Leave YouTubeURL at nil if you don't want any music.
*/
CM.YouTubeURL = nil

//Server buttons(Limit 3).
CM.ServerNameButtons = {
	"Join Server 1",
	"Join Server 2",
	"Check Out My Profile",
}

//Make sure it corresponds to the server names above!
//You can also do websites. Have it start with http://
CM.ServerIPButtons = {
	"192.168.1.1",
	"192.168.1.2",
	"http://steamcommunity.com//id/Kalamitous/",
}

//Delete the code inside the brackets of both the ServerNameButtons and ServerIPButtons if you don't need server buttons.
