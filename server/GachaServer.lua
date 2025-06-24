-- GachaServer.lua
-- Provides server-only functionality for the GachaSystem.
-- Should be required only by the server.

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
    error("GachaServer can only be required on the server", 2)
end

return function(src)
    src = src or script.Parent.Parent:WaitForChild("src")
    local GachaSystem = require(src:WaitForChild("GachaSystem"))

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local assets = ReplicatedStorage:WaitForChild("assets")
    local skillPool = require(assets:WaitForChild("skills"))
    local itemPool = require(assets:WaitForChild("items"))
    local companionPool = require(assets:WaitForChild("companions"))

    local EquipmentGenerator = require(src:WaitForChild("EquipmentGenerator"))
    local SkillSystem = require(src:WaitForChild("SkillSystem"))
    local CompanionSystem = require(src:WaitForChild("CompanionSystem"))
    local PlayerLevelSystem = require(src:WaitForChild("PlayerLevelSystem"))
    local NetworkSystem = require(src:WaitForChild("NetworkServer"))
    local LoggingSystem = require(src:WaitForChild("LoggingSystem"))

    local function selectByRarity(pool, rarity)
        local matches = {}
        for _, entry in ipairs(pool) do
            if entry.rarity == rarity then
                table.insert(matches, entry)
            end
        end
        if #matches == 0 then
            matches = pool
        end
        return matches[math.random(#matches)]
    end

    local function consumeCurrency(self, field)
        if self.tickets[field] and self.tickets[field] > 0 then
            self.tickets[field] = self.tickets[field] - 1
            return true
        elseif self.crystals > 0 then
            self.crystals = self.crystals - 1
            return true
        end
        return false
    end

    function GachaSystem:setRarityWeights(category, weights)
        if type(category) ~= "string" or type(weights) ~= "table" then
            return
        end
        self.rarityWeights[category] = weights
    end

    function GachaSystem:addCrystals(amount)
        local n = tonumber(amount) or 0
        self.crystals = self.crystals + n
        LoggingSystem:logCurrency(nil, "crystal", n)
        NetworkSystem:fireAllClients("CurrencyUpdate", "crystal", self.crystals)
    end

    function GachaSystem:spendCrystals(amount)
        local n = tonumber(amount) or 0
        if n <= 0 then
            return false
        end
        if self.crystals >= n then
            self.crystals = self.crystals - n
            LoggingSystem:logCurrency(nil, "crystal", -n)
            return true
        end
        return false
    end

    function GachaSystem:addTickets(kind, amount)
        if self.tickets[kind] == nil then
            return
        end
        local n = tonumber(amount) or 0
        self.tickets[kind] = self.tickets[kind] + n
        LoggingSystem:logCurrency(nil, kind .. "_ticket", n)
    end

    function GachaSystem:setInventory(inv)
        self.inventory = inv
    end

    function GachaSystem:rollSkill()
        if not consumeCurrency(self, "skill") then
            return nil
        end
        local rarity = self:rollRarity("skill")
        local reward = selectByRarity(skillPool, rarity)
        if reward and LoggingSystem.logItem then
            LoggingSystem:logItem(nil, reward, "skill")
        end
        return reward
    end

    function GachaSystem:rollSkills(count)
        local results = {}
        local n = tonumber(count) or 1
        for _ = 1, n do
            local reward = self:rollSkill()
            if not reward then
                break
            end
            table.insert(results, reward)
        end
        return results
    end

    function GachaSystem:rollCompanion()
        if not consumeCurrency(self, "companion") then
            return nil
        end
        local rarity = self:rollRarity("companion")
        local reward = selectByRarity(companionPool, rarity)
        if reward and LoggingSystem.logItem then
            LoggingSystem:logItem(nil, reward, "companion")
        end
        return reward
    end

    function GachaSystem:rollCompanions(count)
        local results = {}
        local n = tonumber(count) or 1
        for _ = 1, n do
            local reward = self:rollCompanion()
            if not reward then
                break
            end
            table.insert(results, reward)
        end
        return results
    end

    function GachaSystem:rollEquipment(slot)
        if not consumeCurrency(self, "equipment") then
            return nil
        end
        local rarity = self:rollRarity("equipment")
        local reward = EquipmentGenerator.getRandomItem(slot, rarity, itemPool)
        if not reward then
            return nil
        end
        if self.inventory and self.inventory.AddItem then
            self.inventory:AddItem(reward)
        end
        if reward and LoggingSystem.logItem then
            LoggingSystem:logItem(nil, reward, "equipment")
        end
        return reward
    end

    function GachaSystem:rollEquipmentMultiple(slot, count)
        local results = {}
        local n = tonumber(count) or 1
        for _ = 1, n do
            local reward = self:rollEquipment(slot)
            if not reward then
                break
            end
            table.insert(results, reward)
        end
        return results
    end
end
