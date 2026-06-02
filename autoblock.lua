local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local camera = Workspace.CurrentCamera

local DASH_MIN_RADIUS = 11
local DASH_MAX_RADIUS = 35
local DASH_HOLD_RADIUS = 22
local DASH_CANCEL_TIME = 0.95

local RADIUS = 8.5
local HOLD_TIME = 0.285
local COOLDOWN = 0.325

local CLICK_COOLDOWN = 0.65
local FOLLOW_CLICK_DISTANCE = 7

local isHoldingF = false
local holdStartTime = 0
local dashHoldStartTime = nil
local holdTargetRoot = nil
local lastFTime = 0
local lastClickTime = 0
local currentTarget = nil
local autoblockEnabled = true

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
end

local function hasFreeze(targetChar)
    if not targetChar then return false end
    for _, v in ipairs(targetChar:GetDescendants()) do
        if v.Name == "Freeze" then
            return true
        end
    end
    return false
end

local function hasRecentM1Hit()
    if not character then return false end
    if character:FindFirstChild("RecentM1Hit", true) then
        return true
    end
    if character:GetAttribute("RecentM1Hit") then
        return true
    end
    return false
end

local function findDashTrigger()
    if not root then return nil end
    local myPos = root.Position
    local closestModel, closestDist = nil, math.huge

    for _, model in ipairs(Workspace.Live:GetChildren()) do
        if model:IsA("Model") and model ~= character then
            local hum = model:FindFirstChild("Humanoid")
            local tRoot = model:FindFirstChild("HumanoidRootPart")
            if hum and tRoot and hum.Health > 0 then
                local dist = (myPos - tRoot.Position).Magnitude
                if dist >= DASH_MIN_RADIUS and dist <= DASH_MAX_RADIUS and hasFreeze(model) then
                    if dist < closestDist then
                        closestDist = dist
                        closestModel = model
                    end
                end
            end
        end
    end

    return closestModel
end

-- ================== INPUT FUNCTIONS ==================
local function holdF()
    if not isHoldingF then
        isHoldingF = true
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    end
end

local function doLeftClick(force)
    local now = tick()
    if not force and now - lastClickTime < CLICK_COOLDOWN then
        return
    end
    lastClickTime = now
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.001)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function releaseF()
    if isHoldingF then
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        isHoldingF = false
    end
end

-- ================== MAIN LOOP ==================
RunService.RenderStepped:Connect(function()
    if not autoblockEnabled or not root or not root.Parent then
        releaseF()
        currentTarget = nil
        return
    end

    local currentTime = tick()

    if currentTime - lastFTime < COOLDOWN then
        releaseF()
        currentTarget = nil
        return
    end

    local myPos = root.Position

    local dashTarget = nil
    if dashHoldStartTime == nil then
        dashTarget = findDashTrigger()
    end

    if dashHoldStartTime or (dashTarget and not hasRecentM1Hit()) then
        currentTarget = nil
        if dashHoldStartTime == nil then
            dashHoldStartTime = currentTime
            holdTargetRoot = dashTarget and dashTarget:FindFirstChild("HumanoidRootPart")
        end

        local triggerRoot = holdTargetRoot
        if triggerRoot and (root.Position - triggerRoot.Position).Magnitude <= DASH_HOLD_RADIUS then
            -- keep facing the dash target while holding so the follow-up click lands
            pcall(function() faceTarget(triggerRoot) end)
            holdF()

            local elapsed = currentTime - dashHoldStartTime
            if elapsed >= HOLD_TIME then
                -- release first to ensure block state updates, wait a tiny bit, then click
                releaseF()
                task.wait(0.01)
                if (root.Position - triggerRoot.Position).Magnitude <= FOLLOW_CLICK_DISTANCE then
                    doLeftClick(true)
                end
                dashHoldStartTime = nil
                holdTargetRoot = nil
                lastFTime = currentTime
                return
            end
        else
            local elapsed = currentTime - dashHoldStartTime
            if elapsed >= DASH_CANCEL_TIME then
                dashHoldStartTime = nil
                holdTargetRoot = nil
            end
        end
        return
    end

    if currentTarget == nil and dashHoldStartTime == nil then
        releaseF()
    end

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
        holdTargetRoot = bestTarget
        holdStartTime = currentTime
        faceTarget(bestTarget)
        holdF()
    end

    if currentTarget then
        faceTarget(currentTarget)

        local elapsed = currentTime - holdStartTime

            if elapsed >= HOLD_TIME then
            if holdTargetRoot and (root.Position - holdTargetRoot.Position).Magnitude <= FOLLOW_CLICK_DISTANCE then
                doLeftClick()
            end
            releaseF()
            lastFTime = currentTime
            currentTarget = nil
            holdTargetRoot = nil
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
