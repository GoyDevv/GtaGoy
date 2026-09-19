-- Nico's Nextbots - Adaptive Auto BHOP
-- Roblox / Delta
-- Triggers one jump per landing instead of hammering Jump every frame.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local ENABLED = true
local TOGGLE_KEY = Enum.KeyCode.RightShift

local connection
local characterConnection

local function cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

local function start(character)
    cleanup()

    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root then
        return
    end

    local wasGrounded = humanoid.FloorMaterial ~= Enum.Material.Air
    local lastJump = 0
    local MIN_JUMP_INTERVAL = 0.08

    connection = RunService.Heartbeat:Connect(function()
        if not ENABLED or humanoid.Health <= 0 then
            return
        end

        local state = humanoid:GetState()
        local blockedState =
            state == Enum.HumanoidStateType.Swimming
            or state == Enum.HumanoidStateType.Climbing
            or state == Enum.HumanoidStateType.Seated
            or state == Enum.HumanoidStateType.Dead

        if blockedState then
            wasGrounded = false
            return
        end

        local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

        -- Only fire when we transition from air -> ground.
        -- This keeps the script from spamming jump every frame.
        if grounded and not wasGrounded then
            local now = os.clock()
            if now - lastJump >= MIN_JUMP_INTERVAL then
                humanoid.Jump = true
                lastJump = now
            end
        end

        wasGrounded = grounded
    end)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == TOGGLE_KEY then
        ENABLED = not ENABLED
    end
end)

characterConnection = Player.CharacterAdded:Connect(start)

if Player.Character then
    start(Player.Character)
end
