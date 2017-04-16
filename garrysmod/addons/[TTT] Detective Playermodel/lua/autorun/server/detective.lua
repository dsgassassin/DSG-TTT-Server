	hook.Add("TTTBeginRound", "BeginRoundDetectiveSkin", function()
        for k,v in pairs(player.GetAll()) do
            if v:IsActiveDetective() then v:SetModel(Model("models/mark2580/payday2/pd2_bulldozer_player.mdl")) end
        end
    end)
