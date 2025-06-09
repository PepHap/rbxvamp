local QuestSystem = require("src.QuestSystem")
local CurrencySystem = require("src.CurrencySystem")
local KeySystem = require("src.KeySystem")

describe("QuestSystem", function()
    before_each(function()
        QuestSystem.quests = {}
        CurrencySystem.balances = {}
        KeySystem.keys = {}
    end)

    it("adds a quest", function()
        QuestSystem:addQuest{ id = "q1", goal = 2, reward = {currency = "gold", amount = 5} }
        assert.is_table(QuestSystem.quests["q1"])
        assert.equals(0, QuestSystem.quests["q1"].progress)
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
end)
