-- ClientGachaSystem.lua
-- Provides a sanitized gacha interface for the client without any server-side methods.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientGachaSystem should only be required on the client", 2)
end

local ClientGachaSystem = {
    tickets = {skill = 0, companion = 0, equipment = 0},
    crystals = 0,
}

---Restores ticket and crystal counts from serialized data.
-- @param data table state produced by the server
function ClientGachaSystem:loadData(data)
    if type(data) ~= "table" then return end
    self.crystals = tonumber(data.crystals) or 0
    self.tickets.skill = data.tickets and data.tickets.skill or 0
    self.tickets.companion = data.tickets and data.tickets.companion or 0
    self.tickets.equipment = data.tickets and data.tickets.equipment or 0
end

---Serializes the current ticket and crystal amounts.
-- @return table data table
function ClientGachaSystem:saveData()
    return {
        crystals = self.crystals,
        tickets = {
            skill = self.tickets.skill or 0,
            companion = self.tickets.companion or 0,
            equipment = self.tickets.equipment or 0,
        }
    }
end

return ClientGachaSystem
