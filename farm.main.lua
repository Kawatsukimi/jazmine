local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

local targetPosition = Vector3.new(-360.94, 490.02, -297.26)

local teleportConnection = nil
local spamConnection = nil
local claimFunction = nil

local function tryClaimEmote()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj.Name == "Spin" and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                
                if not claimFunction then
                    pcall(function()
                        local cons = getconnections(obj.MouseButton1Click)
                        if #cons > 0 and cons[1].Function then
                            claimFunction = cons[1].Function
                        end
                    end)
                end
                
                if claimFunction then
                    pcall(function()
                        claimFunction()
                    end)
                else
                    pcall(function()
                        firesignal(obj.MouseButton1Click)
                    end)
                end
                
                return
            end
        end
    end
end

local function startTeleportLock()
    if teleportConnection then 
        teleportConnection:Disconnect() 
    end
    
    teleportConnection = task.spawn(function()
        while true do
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(targetPosition) * (root.CFrame.Rotation)
            end
            task.wait(0.25)  -- 0.25 seconds
        end
    end)
end

local function startKeySpam()
    if spamConnection then 
        spamConnection:Disconnect() 
    end
    
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

startTeleportLock()
startKeySpam()

-- emote every 5 second claim
task.spawn(function()
    while true do
        task.wait(5)
        pcall(tryClaimEmote)
    end
end)
