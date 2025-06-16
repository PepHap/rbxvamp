-- RewardGaugeSystem.lua
-- Tracks a separate gauge that grants random equipment choices when filled.

local RewardGaugeSystem = {}

---Current gauge value.
RewardGaugeSystem.gauge = 0

---Amount required to fill the gauge.
RewardGaugeSystem.maxGauge = 100

---Table of reward options when the gauge fills.
RewardGaugeSystem.options = nil

-- Required systems/assets
local GachaSystem = require(script.Parent:WaitForChild("GachaSystem"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:WaitForChild("assets")
local itemPool = require(assets:WaitForChild("items"))

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
        local pool = itemPool[slot]
        local candidates = {}
        for _, itm in ipairs(pool) do
            if itm.rarity == rarity then
                table.insert(candidates, itm)
            end
        end
        if #candidates == 0 then
            candidates = pool
        end
        local choice = candidates[math.random(#candidates)]
        table.insert(opts, {slot = slot, item = choice})
    end
    return opts
end

---Adds points to the gauge and generates options when filled.
-- Further points are ignored until an option is chosen.
-- @param amount number amount to add
function RewardGaugeSystem:addPoints(amount)
    local n = tonumber(amount) or 0
    if self.options then
        return
    end
    self.gauge = self.gauge + n
    if self.gauge >= self.maxGauge then
        self.gauge = 0
        self.options = self:generateOptions()
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
    return chosen
end

return RewardGaugeSystem
