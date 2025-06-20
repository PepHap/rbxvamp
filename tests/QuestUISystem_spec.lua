local QuestUISystem = require("src.QuestUISystem")
local QuestSystem = require("src.QuestSystem")
local CurrencySystem = require("src.CurrencySystem")

describe("QuestUISystem", function()
    before_each(function()
        QuestUISystem.gui = nil
        QuestSystem.quests = {}
        CurrencySystem.balances = {}
    end)

    it("displays quest progress", function()
        QuestSystem:addQuest{ id = "q1", goal = 2, reward = {currency = "gold", amount = 1} }
        QuestUISystem:start(QuestSystem)
        local frame = QuestUISystem.window.children[1]
        assert.is_table(frame)
        assert.is_truthy(string.find(frame.ProgressLabel.Text, "0/2"))
    end)

    it("claims reward via button", function()
        QuestSystem:addQuest{ id = "q1", goal = 1, reward = {currency = "gold", amount = 5} }
        QuestSystem:addProgress("q1", 1)
        QuestUISystem:start(QuestSystem)
        local frame = QuestUISystem.window.children[1]
        local btn = frame.ClaimButton
        if btn.onClick then
            btn.onClick()
        elseif btn.MouseButton1Click and btn.MouseButton1Click.Connect then
            btn.MouseButton1Click:Connect(function() end)
        end
        assert.is_true(QuestSystem.quests["q1"].rewarded)
        assert.equals(5, CurrencySystem:get("gold"))
    end)
end)

