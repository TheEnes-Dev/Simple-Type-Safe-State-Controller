export type Entries = "Combat" | "Safe"

local Custom_State: Entries = "Safe"

local State = State_Service.New("Combat_State", Custom_State)
State.Run_Side = "Server"

State:Player_Init(function(Player: Player)
	return "Safe"
end)

return State
