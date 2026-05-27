local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local autoblockEnabled = false
local espEnabled = false

-- ================== AUTOBLOCK ==================
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local camera = Workspace.CurrentCamera

local RADIUS = 11
local HOLD_TIME = 0.25
local COOLDOWN = 0.65

local isHoldingF = false
local holdStartTime = 0
local lastFTime = 0
local currentTarget = nil

local function setupCharacter(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

local function isM1ing(targetChar)
    if not targetChar then return false end
    for _, v in ipairs(targetChar:GetDescendants()) do
        if v.Name == "M1ing" and v:IsA("Accessory") then return true end
    end
    return false
end

local function faceTarget(targetRoot)
    if not targetRoot or not root then return end
    local myPos = root.Position
    local targetPos = targetRoot.Position
    local flatDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z)
    if flatDir.Magnitude < 0.1 then return end
    flatDir = flatDir.Unit
    root.CFrame = CFrame.lookAt(myPos, myPos + flatDir)

    local camCFrame = camera.CFrame
    local camPos = camCFrame.Position
    local currentLook = camCFrame.LookVector
    local currentPitch = math.asin(currentLook.Y)

    local targetLookPos = targetPos + Vector3.new(0, 2.8, 0)
    local desiredHorizontal = Vector3.new(targetLookPos.X - camPos.X, 0, targetLookPos.Z - camPos.Z)
    if desiredHorizontal.Magnitude < 0.1 then return end
    desiredHorizontal = desiredHorizontal.Unit

    local newLookVector = desiredHorizontal * math.cos(currentPitch) + Vector3.new(0, math.sin(currentPitch), 0)
    camera.CFrame = CFrame.lookAt(camPos, camPos + newLookVector)
end

local function holdF()
    if not isHoldingF then
        isHoldingF = true
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    end
end

local function releaseF()
    if isHoldingF then
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        isHoldingF = false
    end
end

local function doLeftClick()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.001)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- ================== ESP ==================
local espLabels = {}

local function createESP(plr)
    if plr == player or espLabels[plr] then return end
    local head = plr.Character and plr.Character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 140, 0, 26)
    billboard.StudsOffset = Vector3.new(0, -5.2, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = head

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = plr.Name:lower()
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0.4
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard

    billboard.Enabled = false
    espLabels[plr] = billboard
end

local function updateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (root.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            local billboard = espLabels[plr]

            if dist > 45 then
                if not billboard then createESP(plr) end
                if billboard and not billboard.Enabled then
                    billboard.Enabled = true
                end
            else
                if billboard and billboard.Enabled then
                    billboard.Enabled = false
                end
            end
        end
    end
end

-- ================== COMPACT GUI (No Bottom Space) ==================
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SleepCheats"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 210, 0, 125)   -- Tight height
    mainFrame.Position = UDim2.new(0.5, -105, 0.5, -65)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    mainFrame.Parent = screenGui

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
    Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(55, 55, 65)

    -- Dragging + Game Click Fix
    local dragging = false
    local dragStart, frameStart

    mainFrame.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = mainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = frameStart + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Panel Creator
    local function createPanel(name, yPos, toggleVar)
        local panel = Instance.new("Frame", mainFrame)
        panel.Size = UDim2.new(0.9, 0, 0, 48)
        panel.Position = UDim2.new(0.05, 0, 0, yPos)
        panel.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

        local label = Instance.new("TextButton", panel)
        label.Size = UDim2.new(1, -14, 1, -14)
        label.Position = UDim2.new(0, 7, 0, 7)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(170, 170, 180)
        label.TextSize = 14
        label.Font = Enum.Font.GothamSemibold

        label.MouseButton1Click:Connect(function()
            toggleVar.Value = not toggleVar.Value
            if toggleVar.Value then
                TweenService:Create(panel, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                label.TextColor3 = Color3.fromRGB(25, 25, 25)
            else
                TweenService:Create(panel, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(28, 28, 32)}):Play()
                label.TextColor3 = Color3.fromRGB(170, 170, 180)
                if name == "autoblock" then releaseF() end
            end
        end)
    end

    local abToggle = Instance.new("BoolValue") abToggle.Value = false
    local espToggle = Instance.new("BoolValue") espToggle.Value = false

    createPanel("autoblock", 12, abToggle)
    createPanel("esp", 68, espToggle)

    abToggle.Changed:Connect(function() autoblockEnabled = abToggle.Value end)
    espToggle.Changed:Connect(function() espEnabled = espToggle.Value end)
end

createGUI()

-- ================== LOOPS ==================
RunService.RenderStepped:Connect(function()
    if autoblockEnabled then
        if not root or not root.Parent then return end
        local currentTime = tick()
        if currentTime - lastFTime < COOLDOWN then releaseF() currentTarget = nil return end

        local myPos = root.Position
        local bestTarget, closestDist = nil, math.huge

        for _, model in ipairs(Workspace.Live:GetChildren()) do
            if model:IsA("Model") and model ~= character then
                local hum = model:FindFirstChild("Humanoid")
                local tRoot = model:FindFirstChild("HumanoidRootPart")
                if hum and tRoot and hum.Health > 0 then
                    local dist = (myPos - tRoot.Position).Magnitude
                    if dist <= RADIUS and isM1ing(model) and dist < closestDist then
                        closestDist = dist
                        bestTarget = tRoot
                    end
                end
            end
        end

        if bestTarget and not currentTarget then
            currentTarget = bestTarget
            holdStartTime = currentTime
            faceTarget(bestTarget)
            holdF()
        end

        if currentTarget then
            faceTarget(currentTarget)
            if currentTime - holdStartTime >= HOLD_TIME then
                releaseF()
                doLeftClick()
                lastFTime = currentTime
                currentTarget = nil
            else
                holdF()
            end
        end
    else
        releaseF()
        currentTarget = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if espEnabled then
        updateESP()
    else
        for _, gui in pairs(espLabels) do gui:Destroy() end
        espLabels = {}
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        autoblockEnabled = false
        espEnabled = false
        releaseF()
    end
end)
