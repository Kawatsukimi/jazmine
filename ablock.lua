local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
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
local autoblockEnabled = true

-- ================== GUI SETUP ==================
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoblockGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Main container frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 350)
    mainFrame.Position = UDim2.new(0, 50, 0, 50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Stroke/Border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = mainFrame
    
    -- Dragging functionality
    local dragging = false
    local dragStart = nil
    local frameStart = nil
    
    mainFrame.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = frameStart + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "⚔ AUTOBLOCK"
    titleLabel.Parent = mainFrame
    
    -- Autoblock Toggle Button
    local autoblockButton = Instance.new("TextButton")
    autoblockButton.Name = "AutoblockToggle"
    autoblockButton.Size = UDim2.new(1, 0, 0, 45)
    autoblockButton.Position = UDim2.new(0, 0, 0, 40)
    autoblockButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    autoblockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoblockButton.TextSize = 14
    autoblockButton.Font = Enum.Font.GothamBold
    autoblockButton.Text = "🟢 AUTOBLOCK: ON"
    autoblockButton.BorderSizePixel = 0
    autoblockButton.Parent = mainFrame
    
    -- Button corner
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = autoblockButton
    
    autoblockButton.MouseButton1Click:Connect(function()
        autoblockEnabled = not autoblockEnabled
        if autoblockEnabled then
            autoblockButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
            autoblockButton.Text = "🟢 AUTOBLOCK: ON"
        else
            autoblockButton.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
            autoblockButton.Text = "🔴 AUTOBLOCK: OFF"
        end
    end)
    
    -- Empty Panel 1
    local panelA = Instance.new("Frame")
    panelA.Name = "PanelA"
    panelA.Size = UDim2.new(0.48, 0, 0, 45)
    panelA.Position = UDim2.new(0, 0, 0, 100)
    panelA.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    panelA.BorderSizePixel = 0
    panelA.Parent = mainFrame
    
    local panelACorner = Instance.new("UICorner")
    panelACorner.CornerRadius = UDim.new(0, 8)
    panelACorner.Parent = panelA
    
    local panelALabel = Instance.new("TextLabel")
    panelALabel.Size = UDim2.new(1, 0, 1, 0)
    panelALabel.BackgroundTransparency = 1
    panelALabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    panelALabel.TextSize = 12
    panelALabel.Font = Enum.Font.Gotham
    panelALabel.Text = "PANEL 1"
    panelALabel.Parent = panelA
    
    -- Empty Panel 2
    local panelB = Instance.new("Frame")
    panelB.Name = "PanelB"
    panelB.Size = UDim2.new(0.48, 0, 0, 45)
    panelB.Position = UDim2.new(0.52, 0, 0, 100)
    panelB.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    panelB.BorderSizePixel = 0
    panelB.Parent = mainFrame
    
    local panelBCorner = Instance.new("UICorner")
    panelBCorner.CornerRadius = UDim.new(0, 8)
    panelBCorner.Parent = panelB
    
    local panelBLabel = Instance.new("TextLabel")
    panelBLabel.Size = UDim2.new(1, 0, 1, 0)
    panelBLabel.BackgroundTransparency = 1
    panelBLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    panelBLabel.TextSize = 12
    panelBLabel.Font = Enum.Font.Gotham
    panelBLabel.Text = "PANEL 2"
    panelBLabel.Parent = panelB
    
    -- Empty Panel 3
    local panelC = Instance.new("Frame")
    panelC.Name = "PanelC"
    panelC.Size = UDim2.new(0.48, 0, 0, 45)
    panelC.Position = UDim2.new(0, 0, 0, 160)
    panelC.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    panelC.BorderSizePixel = 0
    panelC.Parent = mainFrame
    
    local panelCCorner = Instance.new("UICorner")
    panelCCorner.CornerRadius = UDim.new(0, 8)
    panelCCorner.Parent = panelC
    
    local panelCLabel = Instance.new("TextLabel")
    panelCLabel.Size = UDim2.new(1, 0, 1, 0)
    panelCLabel.BackgroundTransparency = 1
    panelCLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    panelCLabel.TextSize = 12
    panelCLabel.Font = Enum.Font.Gotham
    panelCLabel.Text = "PANEL 3"
    panelCLabel.Parent = panelC
    
    -- Empty Panel 4
    local panelD = Instance.new("Frame")
    panelD.Name = "PanelD"
    panelD.Size = UDim2.new(0.48, 0, 0, 45)
    panelD.Position = UDim2.new(0.52, 0, 0, 160)
    panelD.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    panelD.BorderSizePixel = 0
    panelD.Parent = mainFrame
    
    local panelDCorner = Instance.new("UICorner")
    panelDCorner.CornerRadius = UDim.new(0, 8)
    panelDCorner.Parent = panelD
    
    local panelDLabel = Instance.new("TextLabel")
    panelDLabel.Size = UDim2.new(1, 0, 1, 0)
    panelDLabel.BackgroundTransparency = 1
    panelDLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    panelDLabel.TextSize = 12
    panelDLabel.Font = Enum.Font.Gotham
    panelDLabel.Text = "PANEL 4"
    panelDLabel.Parent = panelD
    
    -- Status indicator
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 220)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Text = "● READY"
    statusLabel.Parent = mainFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "Close"
    closeButton.Size = UDim2.new(1, 0, 0, 30)
    closeButton.Position = UDim2.new(0, 0, 0, 310)
    closeButton.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
    closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.TextSize = 12
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "CLOSE"
    closeButton.BorderSizePixel = 0
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    return mainFrame
end

createGUI()

-- ================== CHARACTER SETUP ==================
local function setupCharacter(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

-- ================== M1 DETECTION ==================
local function isM1ing(targetChar)
    if not targetChar then return false end
    for _, v in ipairs(targetChar:GetDescendants()) do
        if v.Name == "M1ing" and v:IsA("Accessory") then
            return true
        end
    end
    return false
end

-- ================== FACE TARGET (TRUE HORIZONTAL ONLY) ==================
local function faceTarget(targetRoot)
    if not targetRoot or not root then return end
    
    local myPos = root.Position
    local targetPos = targetRoot.Position

    -- Character faces target horizontally only
    local flatDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z)
    if flatDir.Magnitude < 0.1 then return end
    flatDir = flatDir.Unit

    root.CFrame = CFrame.lookAt(myPos, myPos + flatDir)

    -- === CAMERA: Horizontal Only (Keeps your exact up/down angle & FOV) ===
    local camCFrame = camera.CFrame
    local camPos = camCFrame.Position
    
    -- Get current vertical angle (pitch)
    local currentLook = camCFrame.LookVector
    local currentPitch = math.asin(currentLook.Y)
    
    -- Desired horizontal direction to target
    local targetLookPos = targetPos + Vector3.new(0, 2.8, 0)
    local desiredHorizontal = Vector3.new(targetLookPos.X - camPos.X, 0, targetLookPos.Z - camPos.Z)
    if desiredHorizontal.Magnitude < 0.1 then return end
    desiredHorizontal = desiredHorizontal.Unit
    
    -- Rebuild look vector with original pitch
    local newLookVector = desiredHorizontal * math.cos(currentPitch) + Vector3.new(0, math.sin(currentPitch), 0)
    
    camera.CFrame = CFrame.lookAt(camPos, camPos + newLookVector)
end

-- ================== INPUT FUNCTIONS ==================
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

-- ================== MAIN LOOP ==================
RunService.RenderStepped:Connect(function()
    if not autoblockEnabled or not root or not root.Parent then return end

    local currentTime = tick()

    if currentTime - lastFTime < COOLDOWN then
        releaseF()
        currentTarget = nil
        return
    end

    local myPos = root.Position
    local bestTarget = nil
    local closestDist = math.huge

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

    if bestTarget and currentTarget == nil then
        currentTarget = bestTarget
        holdStartTime = currentTime
        faceTarget(bestTarget)
        holdF()
    end

    if currentTarget then
        faceTarget(currentTarget)

        local elapsed = currentTime - holdStartTime

        if elapsed >= HOLD_TIME then
            releaseF()
            doLeftClick()
            
            lastFTime = currentTime
            currentTarget = nil
        else
            holdF()
        end
    end
end)

-- ================== Toggle ==================
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        releaseF()
        print("Anti-M1 Script Disabled")
    end
end)
