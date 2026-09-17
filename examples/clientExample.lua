export type Entries = "Enabled" | "Disabled"

local Custom_Layout: Entries = "Disabled"

local State = State_Service.New("UI_Layout", Custom_Layout)
State.Run_Side = "Client"

State:Player_Init(function(Player: Player)
	if RunService:IsServer() then
		return
	end

	if Player ~= Players.LocalPlayer then
		return
	end

	State:Set(Player, "Disabled")
end)

return State