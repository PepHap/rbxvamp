-- ClientGachaSystem.lua
-- Provides a sanitized gacha interface for the client without any server-side methods.

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    error("ClientGachaSystem should only be required on the client", 2)
end

local ClientGachaSystem = {
    tickets = {skill = 0, companion = 0, equipment = 0},
    crystals = 0,
    startingTickets = {skill = 10, companion = 10, equipment = 10},
}

---Restores ticket and crystal counts from serialized data.
-- @param data table state produced by the server
function ClientGachaSystem:loadData(data)
    data = type(data) == "table" and data or {}
    self.crystals = tonumber(data.crystals) or 0
    local tickets = data.tickets or {}
    local defaults = self.startingTickets
    self.tickets.skill = tickets.skill or defaults.skill or 0
    self.tickets.companion = tickets.companion or defaults.companion or 0
    self.tickets.equipment = tickets.equipment or defaults.equipment or 0
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
