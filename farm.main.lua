local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ====================== NOCLIP (Always On) ======================
local Noclip = nil
local Clip = false

local function noclip()
    if Noclip then return end
    
    local function Nocl()
        if Clip == false and LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end
    
    Noclip = RunService.Stepped:Connect(Nocl)
end

-- ====================== TARGET POSITION ======================
local targetPosition = Vector3.new(163.49, 433.86, -512.23)

local teleportConnection = nil
local spamConnection = nil
local claimFunction = nil

-- ====================== EMOTE CLAIM LOGIC ======================
local function tryClaimEmote()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj.Name == "Spin" and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                
                local text = ""
                pcall(function()
                    if obj:FindFirstChild("TextLabel") then
                        text = obj.TextLabel.Text
                    elseif obj.Text then
                        text = obj.Text
                    end
                end)
                
                local upper = text:upper()
                if upper:find("CLAIM") or upper:find("CLICK ME") or upper:find("NEW EMOTE") then
                    
                    if not claimFunction then
                        pcall(function()
                            local cons = getconnections(obj.MouseButton1Click)
                            if #cons > 0 and cons[1].Function then
                                claimFunction = cons[1].Function
                            end
                        end)
                    end
                    
                    if claimFunction then
                        pcall(function() claimFunction() end)
                    else
                        pcall(function() firesignal(obj.MouseButton1Click) end)
                    end
                end
            end
        end
    end
end

-- ====================== PRESS B FUNCTION ======================
local function pressB()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.B, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.B, false, game)
end

-- ====================== TELEPORT LOCK ======================
local function startTeleportLock()
    if teleportConnection then teleportConnection:Disconnect() end
    teleportConnection = RunService.Heartbeat:Connect(function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(targetPosition) * (root.CFrame.Rotation)
        end
    end)
end

-- ====================== KEY SPAM ======================
local function startKeySpam()
    if spamConnection then spamConnection:Disconnect() end
    spamConnection = RunService.Heartbeat:Connect(function()
        local t = tick()
        if t % 1 < 0.1 then
            for _, key in ipairs({Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}) do
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.03)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
                task.wait(0.02)
            end
        end
    end)
end

-- ====================== START EVERYTHING ======================
startTeleportLock()
startKeySpam()

-- Auto Claim Loop (every 5 seconds)
task.spawn(function()
    while true do
        task.wait(15)
        
        pcall(pressB)           -- Open emote wheel
        task.wait(0.5)
        pcall(tryClaimEmote)    -- Try to claim
        task.wait(1.5)
        pcall(pressB)           -- Close emote wheel
    end
end)
-- Enable Noclip
noclip()
