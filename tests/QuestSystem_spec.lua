local QuestSystem = require("src.QuestSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("QuestSystem", function()
    before_each(function()
        QuestSystem.quests = {}
        CurrencySystem.balances = {}
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
end)
