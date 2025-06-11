local Config = require(script.Parent.Config)
local MonsterManager = require(script.Parent.MonsterManager)
local PlayerManager = require(script.Parent.PlayerManager)
local Inventory = require(script.Parent.Inventory)
local Roulette = require(script.Parent.Roulette)
local SkillManager = require(script.Parent.SkillManager)
local CompanionManager = require(script.Parent.CompanionManager)
local StatsManager = require(script.Parent.StatsManager)
local QuestManager = require(script.Parent.QuestManager)
local LocationManager = require(script.Parent.LocationManager)

local GameManager = {}
GameManager.__index = GameManager

function GameManager.new(player)
    local self = setmetatable({}, GameManager)
    self.PlayerManager = PlayerManager.new(player)
    self.Inventory = Inventory.new()
    self.SkillManager = SkillManager.new(self.PlayerManager)
    self.CompanionManager = CompanionManager.new(self.PlayerManager)
    self.StatsManager = StatsManager.new(self.PlayerManager)
    self.QuestManager = QuestManager.new(self.PlayerManager)
    self.LocationManager = LocationManager.new(self.PlayerManager)
    self.MonsterManager = MonsterManager.new()
    self.Monsters = {}
    return self
end

local function offerRandomItem(playerManager)
    if playerManager.Gauge >= Config.MonstersPerLevel then
        playerManager.Gauge = 0
        local itemsByRarity = {
            S = {"Flaming Sword"},
            A = {"Steel Armor"},
            B = {"Magic Hat", "Swift Boots"},
            C = {"Wooden Shield", "Iron Ring"},
            D = {"Old Cap"}
        }
        local item, rarity = Roulette:GetRandomItem(itemsByRarity)
        if item then
            print("Awarded item:", item, "rarity:", rarity)
        end
    end
end

function GameManager:AdvanceLevel()
    self.PlayerManager:ResetKills()
    self.MonsterManager.CurrentLevel += 1

    if self.MonsterManager.CurrentLevel % Config.StrongBossInterval == 0 then
        self.MonsterManager:SpawnBoss(true)
    elseif self.MonsterManager.CurrentLevel % Config.BossInterval == 0 then
        self.MonsterManager:SpawnBoss(false)
    elseif self.MonsterManager.CurrentLevel % Config.MiniBossInterval == 0 then
        self.MonsterManager:SpawnMiniBoss()
    else
        self.Monsters = self.MonsterManager:SpawnMonsters()
    end
end

function GameManager:KillMonster(monster)
    monster:Destroy()
    self.PlayerManager:RecordKill()
    self.PlayerManager:AddExp(1)
    self.QuestManager:RecordKill()
    self.PlayerManager:AddCurrency("Coins", 1)
    if math.random() < 0.2 then
        self.PlayerManager:AddCurrency("Ether", 1)
    end
    if monster.Name == "StrongBoss" then
        local newLoc = self.LocationManager:UnlockNext()
        if newLoc then
            self.MonsterManager.CurrentLevel = 1
        end
    end
    if self.PlayerManager.Kills >= Config.MonstersPerLevel then
        self:AdvanceLevel()
    end
    offerRandomItem(self.PlayerManager)
end

return GameManager
