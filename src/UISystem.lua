-- UISystem.lua
-- Minimal text-based UI functions for rewards and gacha results

local UISystem = {}

local RewardGaugeSystem = require("src.RewardGaugeSystem")
local GachaSystem = require("src.GachaSystem")

---Displays reward options from the RewardGaugeSystem if available.
-- Prints each option to the console.
-- @return table|nil list of options
function UISystem:showRewardOptions()
    local opts = RewardGaugeSystem:getOptions()
    if not opts then
        return nil
    end
    for i, opt in ipairs(opts) do
        print(("%d) %s (%s)"):format(i, opt.item.name, opt.slot))
    end
    return opts
end

---Selects a reward option by index and prints the result.
-- @param index number option index
-- @return table|nil chosen reward
function UISystem:selectReward(index)
    local chosen = RewardGaugeSystem:choose(index)
    if chosen then
        print(("Selected %s for %s"):format(chosen.item.name, chosen.slot))
    else
        print("Invalid reward selection")
    end
    return chosen
end

---Displays the result of a gacha roll.
-- @param result table|nil reward returned from GachaSystem
function UISystem:displayGachaResult(result)
    if not result then
        print("Gacha: no reward")
        return
    end
    local extra = result.slot and (" - " .. result.slot) or ""
    local rarity = result.rarity or "?"
    print(("Gacha: %s [%s]%s"):format(result.name, rarity, extra))
end

---Rolls a skill through ``GachaSystem`` and displays the outcome.
-- @return table|nil the rolled skill
function UISystem:rollSkill()
    local result = GachaSystem:rollSkill()
    self:displayGachaResult(result)
    return result
end

---Rolls a companion through ``GachaSystem`` and displays the outcome.
-- @return table|nil the rolled companion
function UISystem:rollCompanion()
    local result = GachaSystem:rollCompanion()
    self:displayGachaResult(result)
    return result
end

---Rolls equipment for the specified slot and displays the outcome.
-- @param slot string equipment slot
-- @return table|nil the rolled equipment
function UISystem:rollEquipment(slot)
    local result = GachaSystem:rollEquipment(slot)
    self:displayGachaResult(result)
    return result
end

return UISystem
