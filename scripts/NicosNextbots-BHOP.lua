-- Nico's Nextbots - Adaptive Auto BHOP
-- Roblox / Delta
-- One jump per landing, with an on-screen toggle.
-- RightShift still toggles Auto BHOP.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local ENABLED = true
local TOGGLE_KEY = Enum.KeyCode.RightShift

local connection
local characterConnection
local gui

local function makeUI()
    local playerGui = Player:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("NicosAutoBhop")
    if old then
        old:Destroy()
    end

    gui = Instance.new("ScreenGui")
    gui.Name = "NicosAutoBhop"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.fromOffset(210, 105)
    frame.Position = UDim2.new(0.5, -105, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 65, 75)
    stroke.Thickness = 1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.fromOffset(10, 6)
    title.Font = Enum.Font.GothamBold
    title.Text = "Nico's Auto BHOP"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(1, -20, 0, 18)
    status.Position = UDim2.fromOffset(10, 32)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    local button = Instance.new("TextButton")
    button.Name = "Toggle"
    button.Size = UDim2.new(1, -20, 0, 38)
    button.Position = UDim2.fromOffset(10, 58)
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 0
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 9)
    buttonCorner.Parent = button

    local function refresh()
        if ENABLED then
            status.Text = "Auto jump: ON"
            status.TextColor3 = Color3.fromRGB(110, 255, 150)
            button.Text = "AUTO BHOP  •  ON"
            button.BackgroundColor3 = Color3.fromRGB(45, 145, 80)
        else
            status.Text = "Auto jump: OFF"
            status.TextColor3 = Color3.fromRGB(255, 120, 120)
            button.Text = "AUTO BHOP  •  OFF"
            button.BackgroundColor3 = Color3.fromRGB(145, 55, 55)
        end
    end

    button.Activated:Connect(function()
        ENABLED = not ENABLED
        refresh()
    end)

    -- Simple touch/mouse dragging.
    local dragging = false
    local dragStart
    local startPos

    local function updateDrag(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            updateDrag(input)
        end
    end)

    refresh()
end

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

        local main = gui and gui:FindFirstChild("Main")
        local status = main and main:FindFirstChild("Status")
        local button = main and main:FindFirstChild("Toggle")

        if status and button then
            if ENABLED then
                status.Text = "Auto jump: ON"
                status.TextColor3 = Color3.fromRGB(110, 255, 150)
                button.Text = "AUTO BHOP  •  ON"
                button.BackgroundColor3 = Color3.fromRGB(45, 145, 80)
            else
                status.Text = "Auto jump: OFF"
                status.TextColor3 = Color3.fromRGB(255, 120, 120)
                button.Text = "AUTO BHOP  •  OFF"
                button.BackgroundColor3 = Color3.fromRGB(145, 55, 55)
            end
        end
    end
end)

characterConnection = Player.CharacterAdded:Connect(start)

makeUI()

if Player.Character then
    start(Player.Character)
end
