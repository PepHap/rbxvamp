-- ServerGameExtensions.lua
-- Adds server-only methods to the shared GameManager.
-- This module should only be required from the server.

return function(GameManager, src)
    src = src or script.Parent.Parent:WaitForChild("src")

    local GachaSystem = require(src:WaitForChild("GachaSystem"))
    local PlayerLevelSystem = require(src:WaitForChild("PlayerLevelSystem"))
    local RewardGaugeSystem = require(src:WaitForChild("RewardGaugeSystem"))
    local LevelSystem = require(src:WaitForChild("LevelSystem"))
    local CurrencySystem = require(src:WaitForChild("CurrencySystem"))
    local ItemSystem = require(src:WaitForChild("ItemSystem"))
    local KeySystem = require(src:WaitForChild("KeySystem"))
    local ItemSalvageSystem = require(src:WaitForChild("ItemSalvageSystem"))
    local DungeonSystem = require(src:WaitForChild("DungeonSystem"))
    local StatUpgradeSystem = require(src:WaitForChild("StatUpgradeSystem"))
    local AchievementSystem = require(src:WaitForChild("AchievementSystem"))
    local DailyBonusSystem = require(src:WaitForChild("DailyBonusSystem"))
    local QuestSystem = require(src:WaitForChild("QuestSystem"))

    -- Gacha rewards
    function GameManager:rollSkill(count)
        if not PlayerLevelSystem:isUnlocked("skills") then
            return {}
        end
        count = tonumber(count) or 1
        local results = {}
        for _ = 1, count do
            local reward = GachaSystem:rollSkill()
            if not reward then
                break
            end
            table.insert(results, reward)
            self.skillSystem:addSkill(reward)
            if self.skillCastSystem and self.skillCastSystem.addSkill then
                self.skillCastSystem:addSkill(reward)
            end
        end
        return results
    end

    function GameManager:rollCompanion(count)
        if not PlayerLevelSystem:isUnlocked("companions") then
            return {}
        end
        count = tonumber(count) or 1
        local results = {}
        for _ = 1, count do
            local reward = GachaSystem:rollCompanion()
            if not reward then
                break
            end
            table.insert(results, reward)
            self.companionSystem:add(reward)
            local ai = self.systems and self.systems.CompanionAI
            if ai and ai.addCompanion then
                ai:addCompanion(reward)
            end
        end
        return results
    end

    function GameManager:rollEquipment(slot, count)
        count = tonumber(count) or 1
        local rewards = GachaSystem:rollEquipmentMultiple(slot, count)
        for _, reward in ipairs(rewards) do
            self.itemSystem:assignId(reward)
            if not (self.inventory and self.inventory.AddItem) then
                self.itemSystem:addItem(reward)
            end
        end
        return rewards or {}
    end

    -- Reward gauge management
    function GameManager:addRewardPoints(amount)
        RewardGaugeSystem:addPoints(amount)
    end

    function GameManager:getGaugePercent()
        if RewardGaugeSystem.getPercent then
            return RewardGaugeSystem:getPercent()
        end
        return 0
    end

    function GameManager:getLevelPercent()
        if LevelSystem.getPercent then
            return LevelSystem:getPercent()
        end
        return 0
    end

    function GameManager:getRewardOptions()
        return RewardGaugeSystem:getOptions()
    end

    function GameManager:chooseReward(index)
        return RewardGaugeSystem:choose(index)
    end

    function GameManager:rerollRewardOptions()
        if RewardGaugeSystem.reroll then
            return RewardGaugeSystem:reroll()
        end
        return nil
    end

    function GameManager:resetRewardGauge()
        if RewardGaugeSystem.resetGauge then
            RewardGaugeSystem:resetGauge()
        end
    end

    function GameManager:setGaugeThreshold(value)
        if RewardGaugeSystem.setMaxGauge then
            RewardGaugeSystem:setMaxGauge(value)
        end
    end

    function GameManager:setGaugeOptionCount(count)
        if RewardGaugeSystem.setOptionCount then
            RewardGaugeSystem:setOptionCount(count)
        end
    end

    function GameManager:setGaugeRerollCost(cost)
        if RewardGaugeSystem.setRerollCost then
            RewardGaugeSystem:setRerollCost(cost)
        end
    end

    -- Crystal exchange helpers
    function GameManager:buyTickets(kind, amount)
        if self.crystalExchangeSystem and self.crystalExchangeSystem.buyTickets then
            return self.crystalExchangeSystem:buyTickets(kind, amount)
        end
        return false
    end

    function GameManager:buyCurrency(kind, amount)
        if self.crystalExchangeSystem and self.crystalExchangeSystem.buyCurrency then
            return self.crystalExchangeSystem:buyCurrency(kind, amount)
        end
        return false
    end

    function GameManager:upgradeItemWithCrystals(slot, amount, currencyType)
        if not self.crystalExchangeSystem then
            return false
        end
        local itemSys = self.itemSystem or (self.inventory and self.inventory.itemSystem)
        return self.crystalExchangeSystem:upgradeItemWithCrystals(itemSys, slot, amount, currencyType)
    end

    function GameManager:startDungeon(kind)
        if not DungeonSystem or not DungeonSystem.start then
            return false
        end
        return DungeonSystem:start(kind)
    end

    -- Save data helpers
    function GameManager:getSaveData()
        return {
            currency = CurrencySystem:saveData(),
            gacha = GachaSystem:saveData(),
            items = self.itemSystem:toData(),
            playerLevel = PlayerLevelSystem:saveData(),
            levelState = LevelSystem:saveData(),
            keys = KeySystem:saveData(),
            rewardGauge = RewardGaugeSystem:saveData(),
            skills = self.skillSystem:saveData(),
            companions = self.companionSystem:saveData(),
            stats = StatUpgradeSystem:saveData(),
            achievements = AchievementSystem:saveData(),
            dailyBonus = DailyBonusSystem:saveData(),
            quests = QuestSystem:saveData(),
        }
    end

    function GameManager:applySaveData(data)
        if type(data) ~= "table" then return end
        CurrencySystem:loadData(data.currency)
        GachaSystem:loadData(data.gacha)
        local newItems = ItemSystem.fromData(data.items or {})
        self.itemSystem = newItems
        if self.inventory then
            self.inventory.itemSystem = newItems
        end
        if self.setBonusSystem then
            self.setBonusSystem.itemSystem = newItems
        end
        self.skillSystem:loadData(data.skills)
        self.companionSystem:loadData(data.companions)
        StatUpgradeSystem:loadData(data.stats)
        PlayerLevelSystem:loadData(data.playerLevel)
        LevelSystem:loadData(data.levelState)
        KeySystem:loadData(data.keys)
        RewardGaugeSystem:loadData(data.rewardGauge)
        AchievementSystem:loadData(data.achievements)
        DailyBonusSystem:loadData(data.dailyBonus)
        QuestSystem:loadData(data.quests)
    end

    -- Item salvaging
    function GameManager:salvageInventoryItem(index)
        local itemSys = self.itemSystem or (self.inventory and self.inventory.itemSystem)
        if not self.itemSalvageSystem or not itemSys then
            return false
        end
        local idx = tonumber(index)
        if not idx or idx < 1 or idx > #itemSys.inventory then
            return false
        end
        return self.itemSalvageSystem:salvageFromInventory(itemSys, idx)
    end

    function GameManager:salvageEquippedItem(slot)
        local itemSys = self.itemSystem or (self.inventory and self.inventory.itemSystem)
        if not self.itemSalvageSystem or not itemSys then
            return false
        end
        local SlotConstants = require(src:WaitForChild("SlotConstants"))
        if not SlotConstants.valid[slot] then
            return false
        end
        local itm = itemSys.slots[slot]
        if not itm then
            return false
        end
        itemSys:unequip(slot)
        return self.itemSalvageSystem:salvageItem(itm)
    end

    -- Party and raid helpers
    function GameManager:createParty(player)
        if self.partySystem and self.partySystem.createParty then
            return self.partySystem:createParty(player)
        end
        return nil
    end

    function GameManager:joinParty(id, player)
        if self.partySystem and self.partySystem.addMember then
            return self.partySystem:addMember(id, player)
        end
        return false
    end

    function GameManager:leaveParty(id, player)
        if self.partySystem and self.partySystem.removeMember then
            return self.partySystem:removeMember(id, player)
        end
        return false
    end

    function GameManager:startRaid(player)
        if self.raidSystem and self.raidSystem.startRaid then
            return self.raidSystem:startRaid(player)
        end
        return false
    end

    function GameManager:loadPlayerData(playerId)
        if self.saveSystem and self.saveSystem.load then
            return self.saveSystem:load(playerId)
        end
        return {}
    end

    function GameManager:savePlayerData(playerId, data)
        if self.saveSystem and self.saveSystem.save then
            self.saveSystem:save(playerId, data)
        end
    end

    function GameManager:startAutoSave(playerId)
        if self.autoSaveSystem and self.autoSaveSystem.start and self.saveSystem then
            self.autoSaveSystem:start(self.saveSystem, playerId, function()
                return GameManager:getSaveData()
            end)
        end
    end

    function GameManager:forceAutoSave()
        if self.autoSaveSystem and self.autoSaveSystem.forceSave then
            self.autoSaveSystem:forceSave()
        end
    end
end

