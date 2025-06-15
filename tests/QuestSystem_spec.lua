local QuestSystem = require("src.QuestSystem")
local CurrencySystem = require("src.CurrencySystem")
local KeySystem = require("src.KeySystem")
local GachaSystem = require("src.GachaSystem")

describe("QuestSystem", function()
    before_each(function()
        QuestSystem.quests = {}
        CurrencySystem.balances = {}
        KeySystem.keys = {}
        GachaSystem.tickets = {skill = 0, companion = 0, equipment = 0}
        GachaSystem.crystals = 0
    end)

    it("adds a quest", function()
        QuestSystem:addQuest{ id = "q1", goal = 2, reward = {currency = "gold", amount = 5} }
        assert.is_table(QuestSystem.quests["q1"])
        assert.equals(0, QuestSystem.quests["q1"].progress)
    end)

    it("handles non-number progress amounts", function()
        QuestSystem:addQuest{ id = "qt", goal = 2, reward = {currency = "gold", amount = 1} }
        QuestSystem:addProgress("qt", {})
        assert.equals(1, QuestSystem.quests["qt"].progress)
    end)

    it("completes a quest and grants reward", function()
        QuestSystem:addQuest{ id = "q1", goal = 1, reward = {currency = "gold", amount = 3} }
        QuestSystem:addProgress("q1", 1)
        assert.is_true(QuestSystem:isCompleted("q1"))
        local ok = QuestSystem:claimReward("q1")
        assert.is_true(ok)
        assert.equals(3, CurrencySystem:get("gold"))
    end)

    it("grants keys from rewards", function()
        QuestSystem:addQuest{ id = "q2", goal = 1, reward = {keys = {arena = 2}} }
        QuestSystem:addProgress("q2", 1)
        local ok = QuestSystem:claimReward("q2")
        assert.is_true(ok)
        assert.equals(2, KeySystem:getCount("arena"))
    end)

    it("grants gacha tickets", function()
        QuestSystem:addQuest{ id = "q3", goal = 1, reward = {tickets = {skill = 2}} }
        QuestSystem:addProgress("q3", 1)
        local ok = QuestSystem:claimReward("q3")
        assert.is_true(ok)
        assert.equals(2, GachaSystem.tickets.skill)
    end)

    it("grants crystals as part of the reward", function()
        QuestSystem:addQuest{ id = "q4", goal = 1, reward = {crystals = 5} }
        QuestSystem:addProgress("q4", 1)
        local ok = QuestSystem:claimReward("q4")
        assert.is_true(ok)
        assert.equals(5, GachaSystem.crystals)
    end)
end)
