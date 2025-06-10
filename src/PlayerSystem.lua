-- PlayerSystem.lua
-- Tracks player health and handles death events.

local PlayerSystem = {}

local LevelSystem = require("src.LevelSystem")

---Maximum player health.
PlayerSystem.maxHealth = 100

---Current player health.
PlayerSystem.health = PlayerSystem.maxHealth

---Damages the player by the given amount and checks for death.
-- @param amount number amount of damage to apply
function PlayerSystem:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self:onDeath()
    end
end

---Heals the player by the given amount without exceeding max health.
-- @param amount number amount to heal
function PlayerSystem:heal(amount)
    self.health = math.min(self.health + amount, self.maxHealth)
end

---Handles player death and notifies the LevelSystem.
function PlayerSystem:onDeath()
    LevelSystem:onPlayerDeath()
    self.health = self.maxHealth
end

return PlayerSystem
