local Config = require(script.Parent.Config)
local MonsterManager = {}
MonsterManager.__index = MonsterManager

function MonsterManager.new()
    local self = setmetatable({}, MonsterManager)
    self.CurrentLevel = 1
    return self
end

function MonsterManager:SpawnMiniBoss()
    local boss = Instance.new("Model")
    boss.Name = "MiniBoss"
    local baseHealth = 300
    boss:SetAttribute("Health", baseHealth + Config.HealthPerLevel * (self.CurrentLevel - 1))
    boss.Parent = workspace.Bosses
    return boss
end

function MonsterManager:SpawnMonsters()
    local monsterCount = Config.MonstersPerLevel
    local monsters = {}

    for i = 1, monsterCount do
        local monster = Instance.new("Model")
        monster.Name = "Mob"
        monster:SetAttribute("Health", 100 + Config.HealthPerLevel * (self.CurrentLevel - 1))
        monster.Parent = workspace.Monsters
        table.insert(monsters, monster)
    end
    return monsters
end

function MonsterManager:SpawnBoss(isStrong)
    local boss = Instance.new("Model")
    boss.Name = isStrong and "StrongBoss" or "Boss"
    local baseHealth = isStrong and 1000 or 500
    boss:SetAttribute("Health", baseHealth + Config.HealthPerLevel * (self.CurrentLevel - 1))
    boss.Parent = workspace.Bosses
    return boss
end

return MonsterManager
