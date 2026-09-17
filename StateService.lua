-- AUTHOR       : TheEnesDev 
-- DATE (D/M/Y) : 17/09/2026 

-- ──────────────────────── SERVICES 
local RunService = game:GetService("RunService") 
local Players = game:GetService("Players") 
local ServerStorage = game:GetService("ServerStorage") 
local ServerScriptService = game:GetService("ServerScriptService") 
local ReplicatedStorage = game:GetService("ReplicatedStorage") 

-- ──────────────────────── TYPES 
export type State<T> = { 
	State_UID : string, 
	Run_Side : "Client" | "Server", 
	Config : { 
		Custom_State : T, 
	}, 

	Get : (self:State<T>,Player:Player) -> T, 
	GetPlayers : (self:State<T>) -> {Players}, 

	Equals : (self:State<T>,Player:Player,State:T) -> boolean, 

	Set : (self:State<T>,Player:Player,State:T) -> nil, 
	SetAll : (self:State<T>,State:T) -> nil, 

	Player_Init : (self:State<T>,(Player:Player) -> T) -> RBXScriptConnection, 
	Listen : (self:State<T>,CallNow:boolean?,Player:Player,CallBack:(State:T) -> ()) -> RBXScriptConnection, 
} 

-- ──────────────────────── HELPERS 
const function IsPlayer(Player:Player) 
	return Player and typeof(Player) == "Instance" and Player:IsA("Player") 
end 

-- ──────────────────────── SERVICE 
local Service = {} 
local State = {} 
State.__index = State 

function State:Get(Player:Player) 
	local Player = Player or (RunService:IsClient() and Players.LocalPlayer) 
	assert(self and self.State_UID,"[STATE] invalid class.") 
	assert(IsPlayer(Player),"[STATE] invalid player.") 

	return Player:GetAttribute(self.State_UID) 
end 

function State:Equals(Player:Player,State:any) : boolean 
	local Player = Player or (RunService:IsClient() and Players.LocalPlayer) 
	assert(self and self.State_UID,"[STATE] invalid class.") 
	assert(IsPlayer(Player),"[STATE] invalid player.") 

	return self:Get(Player) == State 
end 

function State:GetPlayers(State:any) 
	assert(self and self.State_UID,"[STATE] invalid class.") 

	local WhiteList = {} 
	for _,Player:Player in Players:GetPlayers() do 
		if self:Get(Player) ~= State then continue end 
		table.insert(WhiteList,Player) 
	end 

	return WhiteList 
end 

function State:Set(Player:Player,State:any) 
	assert(self and self.State_UID,"[STATE] invalid class.") 

	local Player = (self.Run_Side == "Server") and Player or (RunService:IsClient() and Players.LocalPlayer) 
	assert(IsPlayer(Player),"[STATE] invalid player.") 

	Player:SetAttribute(self.State_UID,State) 
end 

function State:SetAll(State:any) 
	if not RunService:IsServer() then return end 
	assert(self and self.Config,"[STATE] invalid class.") 

	self.Config.Custom_State = State 
	for _,Player:Player in Players:GetPlayers() do 
		self:Set(Player,State) 
	end 
end 

function State:Player_Init(CallBack:(Player:Player) -> any) 
	assert(self and self.State_UID,"[STATE] invalid class.") 
	assert(CallBack and typeof(CallBack) == "function","[STATE] invalid callback.") 

	for _,Player in Players:GetPlayers() do 
		task.spawn(function() 
			local Result = CallBack(Player) 
			if self.Run_Side == "Client" then return end 
			self:Set(Player,Result) 
		end) 
	end 

	return Players.PlayerAdded:Connect(function(Player) 
		local Result = CallBack(Player) 
		if self.Run_Side == "Client" then return end 
		self:Set(Player,Result) 
	end) 
end 

function State:Listen(CallNow:boolean,Player:Player,CallBack:(State:any) -> ()) 
	local Player = Player or (RunService:IsClient() and Players.LocalPlayer) 
	assert(self and self.State_UID,"[STATE] invalid class.") 
	assert(IsPlayer(Player),"[STATE] invalid player.") 
	assert(CallBack and typeof(CallBack) == "function","[STATE] invalid callback.") 

	if CallNow then 
		task.spawn(CallBack,self:Get(Player)) 
	end 

	return Player:GetAttributeChangedSignal(self.State_UID):Connect(function() 
		task.spawn(CallBack,self:Get(Player)) 
	end) 
end 

function Service.New<T>(name:string,value:T): State<T> 
	assert(name and typeof(name) == "string","[STATE] invalid state name.") 
	local NewState:State<T> = setmetatable({},State) 
	
	NewState.Run_Side = "Server"
	NewState.State_UID = name 
	NewState.Config = { 
		Custom_State = value, 
	} 

	return NewState 
end 

return Service
