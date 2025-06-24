-- RewardGaugeSystem.lua
-- Tracks a separate gauge that grants random equipment choices when filled.

local RewardGaugeSystem = {}

---Current gauge value.
RewardGaugeSystem.gauge = 0

---Amount required to fill the gauge.
RewardGaugeSystem.maxGauge = 100

---Number of reward options generated when the gauge fills.
RewardGaugeSystem.optionCount = 3

---Crystals required to reroll existing options.
RewardGaugeSystem.rerollCost = 1

---Table of reward options when the gauge fills.
RewardGaugeSystem.options = nil

---Optional callback invoked when a reward is chosen.
RewardGaugeSystem.onSelect = nil

-- Required systems/assets
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local itemPool = require(assets:WaitForChild("items"))
local EquipmentGenerator = require(script.Parent:WaitForChild("EquipmentGenerator"))
local NetworkSystem
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))
end
local LoggingSystem
do
    local RunService = game:GetService("RunService")
    if RunService and RunService.IsServer and RunService:IsServer() then
        LoggingSystem = require(script.Parent:WaitForChild("LoggingSystem"))
    end
end

-- Precompute a list of available equipment slots
local slots = {}
for slot in pairs(itemPool) do
    table.insert(slots, slot)
end

---Sets the maximum gauge amount required for a reward.
-- @param value number new threshold
function RewardGaugeSystem:setMaxGauge(value)
    local n = tonumber(value)
    if n and n > 0 then
        self.maxGauge = n
        NetworkSystem:fireAllClients("GaugeUpdate", self.gauge, self.maxGauge)
    end
end

---Sets how many reward options are generated when the gauge fills.
-- @param count number option count
function RewardGaugeSystem:setOptionCount(count)
    local n = tonumber(count)
    if n and n >= 1 then
        self.optionCount = math.floor(n)
    end
end

---Sets the crystal price used when rerolling reward options.
-- @param cost number new cost value
function RewardGaugeSystem:setRerollCost(cost)
    local n = tonumber(cost)
    if n and n >= 0 then
        self.rerollCost = n
    end
end

---Generates three random equipment options using ``GachaSystem``'s rarity roll.
-- @return table list of option tables {slot=string,item=table}
function RewardGaugeSystem:generateOptions()
    local opts = {}
    local count = self.optionCount or 3
    for i = 1, count do
        local slot = slots[math.random(#slots)]
        local rarity = GachaSystem:rollRarity()
        local choice = EquipmentGenerator.getRandomItem(slot, rarity, itemPool)
        if choice then
            LoggingSystem:logItem(nil, choice, "gauge_option")
        end
        table.insert(opts, {slot = slot, item = choice})
    end
    return opts
end

---Adds points to the gauge and generates options when filled.
-- Further points are ignored until an option is chosen.
-- @param amount number amount to add
function RewardGaugeSystem:addPoints(amount)
    if self.options then
        return
    end
    local n = tonumber(amount)
    if not n or n <= 0 then
        return
    end
    self.gauge = self.gauge + n
    NetworkSystem:fireAllClients("GaugeUpdate", self.gauge, self.maxGauge)
    while self.gauge >= self.maxGauge do
        -- Once the gauge fills, reset it and generate reward options.
        self.gauge = self.gauge - self.maxGauge
        self.options = self:generateOptions()
        if self.options then
            -- Any leftover points are discarded when options appear
            self.gauge = 0
            NetworkSystem:fireAllClients("GaugeOptions", self.options)
            break
        end
    end
end

---Returns the current list of reward options if available.
function RewardGaugeSystem:getOptions()
    return self.options
end

---Chooses a reward option clearing the list.
-- @param index number selection index (1-optionCount)
-- @return table|nil the chosen reward
function RewardGaugeSystem:choose(index)
    local opts = self.options
    if not opts or not opts[index] then
        return nil
    end
    local chosen = opts[index]
    self.options = nil
    NetworkSystem:fireAllClients("GaugeOptions", nil)
    NetworkSystem:fireAllClients("GaugeReset")
    if chosen and chosen.item then
        LoggingSystem:logItem(nil, chosen.item, "gauge_claim")
    end
    if self.onSelect then
        pcall(self.onSelect, chosen)
    end

    return chosen
end

---Rerolls the current reward options by spending crystals.
--  When enough crystals are available, new options are generated and sent
--  to all clients. Returns the new option table or nil on failure.
function RewardGaugeSystem:reroll()
    if not self.options or self.rerollCost <= 0 then
        return nil
    end
    if not GachaSystem:spendCrystals(self.rerollCost) then
        return nil
    end
    self.options = self:generateOptions()
    NetworkSystem:fireAllClients("GaugeOptions", self.options)
    if self.options then
        for _, opt in ipairs(self.options) do
            if opt.item then
                LoggingSystem:logItem(nil, opt.item, "gauge_reroll")
            end
        end
    end
    return self.options
end

---Resets the gauge to zero discarding any stored options.
function RewardGaugeSystem:resetGauge()
    self.gauge = 0
    self.options = nil
    NetworkSystem:fireAllClients("GaugeUpdate", self.gauge, self.maxGauge)
    NetworkSystem:fireAllClients("GaugeOptions", nil)
    NetworkSystem:fireAllClients("GaugeReset")
end

---Returns gauge progress as a value from ``0`` to ``1``.
function RewardGaugeSystem:getPercent()
    if self.maxGauge <= 0 then
        return 0
    end
    return self.gauge / self.maxGauge
end

---Serializes the gauge state so progress persists across sessions.
-- @return table data table containing ``gauge`` value
function RewardGaugeSystem:saveData()
    return {gauge = self.gauge}
end

---Loads gauge progress from a table produced by ``saveData``.
-- @param data table saved gauge state
function RewardGaugeSystem:loadData(data)
    if type(data) ~= "table" then return end
    if type(data.gauge) == "number" then
        self.gauge = data.gauge
        NetworkSystem:fireAllClients("GaugeUpdate", self.gauge, self.maxGauge)
    end
end

local RunService = game:GetService("RunService")
if RunService:IsClient() then
    local serverOnly = {
        setMaxGauge = true,
        setOptionCount = true,
        setRerollCost = true,
        generateOptions = true,
        addPoints = true,
        choose = true,
        reroll = true,
        resetGauge = true,
        saveData = true,
    }
    for name in pairs(serverOnly) do
        RewardGaugeSystem[name] = nil
    end
end

return RewardGaugeSystem
