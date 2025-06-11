local QuestManager = {}
QuestManager.__index = QuestManager

local questDefinitions = {
    FirstBlood = {Goal = 10, Reward = {Tickets = 3}},
    BossSlayer = {Goal = 1, Reward = {Keys = 1}},
}

function QuestManager.new(playerManager)
    local self = setmetatable({}, QuestManager)
    self.PlayerManager = playerManager
    self.Quests = {}
    for name, def in pairs(questDefinitions) do
        self.Quests[name] = {
            Progress = 0,
            Goal = def.Goal,
            Reward = def.Reward,
            Completed = false,
        }
    end
    return self
end

function QuestManager:RecordKill()
    for _, quest in pairs(self.Quests) do
        if not quest.Completed then
            quest.Progress += 1
            if quest.Progress >= quest.Goal then
                quest.Completed = true
                self.PlayerManager:AddCurrency("Tickets", quest.Reward.Tickets or 0)
                self.PlayerManager:AddCurrency("Keys", quest.Reward.Keys or 0)
            end
        end
    end
end

return QuestManager
