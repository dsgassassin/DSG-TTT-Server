TRADING.Theme = {}

-- Pointshop Trading Theme
--See the included PointshopTradingGuide.pdf for more detailed explnations
--of what these settings do and how to use them.

TRADING.Theme.WindowColor = Color(26, 30, 38, 255) --Main window color
TRADING.Theme.ControlColor = Color( 37, 43, 55, 255 ) --Main window control color
TRADING.Theme.OutlineColor = Color(191,191,191, 50)
TRADING.Theme.NotifcationAccentColor = Color(72,108,143)
TRADING.Theme.NotifcationErrorColor = Color(255,51,51)
TRADING.Theme.NotifcationSuccessColor = Color(51,255,51)
TRADING.Theme.TradePointsIcon = "icon16/money.png"
TRADING.Theme.TradePointsOutlineColor = Color(51,255,102)
TRADING.Theme.InventoryItemSize = 125

TRADING.Settings = {}

--
-- Pointshop Trading Settings
--

--Chat command to send a trade request, opens menu if no name is given, {} to disable
TRADING.ChatCommands = {"!trade","/trade","trade"}
--You can set the FKey binds to F1,F2,F3 or F4 and change to "" to disable FKeyBind
TRADING.Settings.SelectionMenuFKey = "F$" --Invitation menu
TRADING.Settings.CursorFKey = "F2" --Cursor key to accept invitations
--These FKeys will only be active when there is a pending trade request
--so it means these keys will not override other menus or actions.
TRADING.Settings.AcceptLastTradeFKey = "F1" --Accept last trade
TRADING.Settings.IgnoreLastTradeFKey = "F2" --Ignore last trade
TRADING.Settings.NotificationSound = "ui/hint.wav" --Notification sound file
TRADING.Settings.DefaultTradeSlots = 8 --Default empty slots in trade (more added automatically)
TRADING.Settings.TradeRequestCooldown = 20 --Cooldown for sending invitations
TRADING.Settings.CanTradePoints = true --Can players trade points?
TRADING.Settings.JoinNotification = true --Notify players of how to trade when they join?
--Enter category names to be excluded from trading and change to "" to disable
--Use folder name for PS1 and display name for PS2
TRADING.Settings.ExcludeCategories = {"weapons","Uncategorized Items"}
--Enter item names to be excluded from trading and change to "" to disable
--Use item lua file name for PS1 and display name for PS2
TRADING.Settings.ExcludeItems = {""}

--
-- Pointshop Trading Language Strings
--

TRADING.Settings.YourInventoryTitle = "Your inventory:"
TRADING.Settings.YourOfferTitle = "Your offerings:"
TRADING.Settings.TheirOfferTitle = "%s's offerings:"
TRADING.Settings.YourSummaryTitle = "You offered:"
TRADING.Settings.TheirSummaryTitle = "For %s's:"
TRADING.Settings.YourOfferSubtitle = "These are the items you will lose in the trade."
TRADING.Settings.TheirOfferSubtitle = "These are the items you will receive in the trade."
TRADING.Settings.NoItemsStatus = "Waiting for someone to make an offer."
TRADING.Settings.NotReadyStatus = "Not ready to trade."
TRADING.Settings.CheckReadyStatus = "Check this box when ready to trade."
TRADING.Settings.ReadyStatus = "Ready to trade."
TRADING.Settings.BothNotReady = "Waiting for both parties to check the ready box."
TRADING.Settings.YouNotReady = "Waiting for you to confirm your offer."
TRADING.Settings.BothReady = "Both parties are ready."
TRADING.Settings.MakeTrade = "Make Trade"
TRADING.Settings.AwaitingConfirmation = "Waiting for the other party to confirm..."
TRADING.Settings.NoItemsMessage = "You currently have 0 item in your %s inventory\nYou can purchase them from the Pointshop F3 menu."
TRADING.Settings.TradeRequestMessage = "%s has sent you a trade request. Do you want to accept?"
TRADING.Settings.TradeRequestSentMessage = "Your trade request has been sent to %s"
TRADING.Settings.CantSendNotification = "You need to wait a while before sending another request."
TRADING.Settings.ErrorNotification = "This player cannot trade currently."
TRADING.Settings.PlayerNoLongerHasItems = "%s no longer has the items they entered into the trade and the trade was cancelled. No items or points were removed from your inventory."
TRADING.Settings.RemoveTradeItem = "Remove from trade"
TRADING.Settings.OfferChanged = "Offer changed"
TRADING.Settings.ChatboxSend = "Send"
TRADING.Settings.PS2ItemCantBeTraded = "This item cannot be traded"
TRADING.Settings.PS2InventorySlotsFull = "%s doesn't have enough inventory space for this item."
TRADING.Settings.DefaultChatBoxMessage = "Welcome to Pointshop Trading..."
TRADING.Settings.TradeCancelledByOther = "%s cancelled the trade session."
TRADING.Settings.TradeCancelled = "The trade session has been cancelled."
TRADING.Settings.TradeConfirmed = "This trade has been confirmed and the following items have been sent to %s\nYou can review the trade below then close this window or view your inventory."
TRADING.Settings.TheyAdded = "%s added "
TRADING.Settings.TheyRemoved = "%s removed "
TRADING.Settings.YouAdded = "You added "
TRADING.Settings.YouRemoved = "You removed "
TRADING.Settings.PlayerSelection = "Player Selection:"
TRADING.Settings.PlayerSelectionSubtitle = "Click a player's name to send a trade request."
TRADING.Settings.AddPoints = "Add %s"
TRADING.Settings.AddPointsToTrade = "Add %s to Trade"
TRADING.Settings.AddPointsDetails = "How many %s do you want to add to the trade? (Current Balance: %s %s)"
TRADING.Settings.NotEnoughPoints = "You don't have enough %s"
TRADING.Settings.SendRequest = "Send request."
TRADING.Settings.PS2TradeRequest = "Trade Request"
TRADING.Settings.AcceptRequest = "Accept"
TRADING.Settings.IgnoreRequest = "Ignore"
TRADING.Settings.CancelTrade = "Cancel Trade"
TRADING.Settings.YesText = "Yes"
TRADING.Settings.NoText = "No"
TRADING.Settings.CancelTradeConfirmation = "Are you sure you want to cancel this trade? No items or points will be lost."
TRADING.Settings.JoinNotificationFKey = "To send a trade request press %s."
TRADING.Settings.JoinNotificationChatCommand = "To send a trade request type %s in chat."
TRADING.Settings.OpenInventory = "Open Inventory"
TRADING.Settings.CloseSummaryWindow = "Close Window"
TRADING.Settings.TradeConfirmedTitle = "Trade Confirmed"
TRADING.Settings.NotificationPrefix = "[POINTSHOP TRADING]"

--Custom can trade function, this is called to check if a trade can be started and again
--for each item added to the trade. The example function restricts trading to admin,superadmin and VIPs
-- TRADING.Settings.CustomCanTradeFunction = function(ply, tradingwith, item)
	-- if not table.HasValue({"admin","superadmin","vip"}, ply:GetUserGroup()) then
		-- return false,"Only admins and VIPs can start a trade!"
	-- end
	-- return true
-- end