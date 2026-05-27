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

local connections = {}

-- ================== CHARACTER SETUP ==================
local function setupCharacter(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
end

if player.Character then setupCharacter(player.Character) end
table.insert(connections, player.CharacterAdded:Connect(setupCharacter))

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

-- ================== FACE TARGET (Horizontal Only) ==================
local function faceTarget(targetRoot)
    if not targetRoot or not root then return end
    
    local myPos = root.Position
    local targetPos = targetRoot.Position

    local flatDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z)
    if flatDir.Magnitude < 0.1 then return end
    flatDir = flatDir.Unit

    root.CFrame = CFrame.lookAt(myPos, myPos + flatDir)

    -- Camera Horizontal Only
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
local renderConnection = RunService.RenderStepped:Connect(function()
    if not root or not root.Parent then return end

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

table.insert(connections, renderConnection)

-- ================== RIGHT CTRL TOGGLE ==================
local toggleConnection = UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        releaseF()
        print("Anti-M1 Script Disabled (Manual)")
    end
end)
table.insert(connections, toggleConnection)

-- ================== UNLOAD FUNCTION ==================
local function Unload()
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    releaseF()
    print("AutoBlock Fully Unloaded")
end

return { Unload = Unload }
