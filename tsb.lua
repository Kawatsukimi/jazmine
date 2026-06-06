local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- ================== SETTINGS ==================
local MAX_DISTANCE = 50
local BEHIND_DISTANCE = 3
local SPAM_DURATION = 0.185
local TARGETING_FOV = 100       -- Lower = stricter, Higher = more forgiving
local TARGETING_RANGE = 80      -- Max range to consider players
-- UserIds to ignore for targeting/highlighting
local IGNORED_USER_IDS = {
    [10675839508] = true,
    [7982162904] = true,
}
-- =============================================

local CurrentTarget = nil
local CurrentHighlight = nil

local function createHighlight()
    local highlight = Instance.new("Highlight")
    highlight.Name = "TargetOutline"
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255, 105, 180)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return highlight
end

local function removeHighlight()
    if CurrentHighlight then
        CurrentHighlight:Destroy()
        CurrentHighlight = nil
    end
    CurrentTarget = nil
end

local function applyHighlight(character)
    removeHighlight()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local player = Players:GetPlayerFromCharacter(character)
    if player and IGNORED_USER_IDS[player.UserId] then
        return
    end
    
    CurrentTarget = character
    CurrentHighlight = createHighlight()
    CurrentHighlight.Adornee = character
    CurrentHighlight.Parent = character
end

-- ================== BETTER TARGETING ==================
local function getClosestPlayerToMouse()
    if not LocalPlayer.Character then return nil end
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local rayOrigin = ray.Origin
    local rayDirection = ray.Direction * TARGETING_RANGE

    local closestPlayer = nil
    local closestDistToRay = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not IGNORED_USER_IDS[player.UserId] then
            local char = player.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")

            if root and humanoid and humanoid.Health > 0 then
                local toRoot = (root.Position - rayOrigin)
                local distToRay = toRoot:Cross(rayDirection).Magnitude / rayDirection.Magnitude
                local distFromCamera = toRoot.Magnitude

                -- Consider players within camera range and close to the mouse ray (ignore distance from local player)
                if distFromCamera <= TARGETING_RANGE and distToRay < TARGETING_FOV then
                    if distToRay < closestDistToRay then
                        closestDistToRay = distToRay
                        closestPlayer = char
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function teleportBehind()
    if not CurrentTarget then 
        warn("No target selected!")
        return 
    end
    
    local targetRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not targetRoot or not myRoot then return end

    local distance = (myRoot.Position - targetRoot.Position).Magnitude
    if distance > MAX_DISTANCE then
        warn("Target is too far! (" .. math.floor(distance) .. " studs)")
        return
    end

    local startTime = tick()
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if tick() - startTime > SPAM_DURATION then
            connection:Disconnect()
            return
        end
        
        if not (targetRoot and targetRoot.Parent and myRoot and myRoot.Parent) then
            connection:Disconnect()
            return
        end

        local targetCFrame = targetRoot.CFrame
        local behindOffset = targetCFrame.LookVector * -BEHIND_DISTANCE
        local behindPos = targetCFrame.Position + behindOffset
        behindPos = Vector3.new(behindPos.X, myRoot.Position.Y, behindPos.Z)

        myRoot.CFrame = CFrame.lookAt(behindPos, targetRoot.Position)
        
        local camPos = Camera.CFrame.Position
        Camera.CFrame = CFrame.lookAt(camPos, targetRoot.Position + Vector3.new(0, 2.5, 0))
    end)
end

-- ================== INPUT ==================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        local targetChar = getClosestPlayerToMouse()
        if targetChar then
            if CurrentTarget == targetChar then
                removeHighlight()
            else
                applyHighlight(targetChar)
            end
        else
            removeHighlight()
        end
        
    elseif input.KeyCode == Enum.KeyCode.Z then
        teleportBehind()
    end
end)

-- Cleanup
RunService.Heartbeat:Connect(function()
    if CurrentTarget then
        local bad = false
        if not CurrentTarget.Parent or not CurrentTarget:FindFirstChild("Humanoid") or CurrentTarget.Humanoid.Health <= 0 then
            bad = true
        else
            local targPlayer = Players:GetPlayerFromCharacter(CurrentTarget)
            if targPlayer and IGNORED_USER_IDS[targPlayer.UserId] then
                bad = true
            end
        end

        if bad then
            removeHighlight()
        end
    end
end)
