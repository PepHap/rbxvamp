-- RewardGaugeSystem.lua
-- Tracks a separate gauge that grants random equipment choices when filled.

local RewardGaugeSystem = {}

---Current gauge value.
RewardGaugeSystem.gauge = 0

---Amount required to fill the gauge.
RewardGaugeSystem.maxGauge = 100

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
local NetworkSystem = require(script.Parent:WaitForChild("NetworkSystem"))

-- Precompute a list of available equipment slots
local slots = {}
for slot in pairs(itemPool) do
    table.insert(slots, slot)
end

---Generates three random equipment options using ``GachaSystem``'s rarity roll.
-- @return table list of option tables {slot=string,item=table}
function RewardGaugeSystem:generateOptions()
    local opts = {}
    for i = 1, 3 do
        local slot = slots[math.random(#slots)]
        local rarity = GachaSystem:rollRarity()
        local choice = EquipmentGenerator.getRandomItem(slot, rarity, itemPool)
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
-- @param index number selection index (1-3)
-- @return table|nil the chosen reward
function RewardGaugeSystem:choose(index)
    local opts = self.options
    if not opts or not opts[index] then
        return nil
    end
    local chosen = opts[index]
    self.options = nil
    NetworkSystem:fireAllClients("GaugeOptions", nil)
    if self.onSelect then
        pcall(self.onSelect, chosen)
    end
    return chosen
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

return RewardGaugeSystem
