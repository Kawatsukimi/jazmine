local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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

-- ====================== USERIDS ======================
local userid1 = 5801536462
local userid2 = 9287360225
local userid3 = 10041989412

-- ====================== NEW BOT POSITIONS ======================
local pos1 = Vector3.new(174.60, 433.86, -500.35)
local pos2 = Vector3.new(171.41, 433.86, -500.93)
local pos3 = Vector3.new(174.24, 433.86, -503.37)

-- Anti-AFK
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- ====================== MAIN BOT TELEPORT LOOP ======================
task.spawn(function()
    while true do
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                
                if player.UserId == userid1 then
                    root.CFrame = CFrame.new(pos1) * root.CFrame.Rotation
                    
                elseif player.UserId == userid2 then
                    root.CFrame = CFrame.new(pos2) * root.CFrame.Rotation
                    
                elseif player.UserId == userid3 then
                    root.CFrame = CFrame.new(pos3) * root.CFrame.Rotation
                end
            end
        end
        
        task.wait(0.35)
    end
end)
noclip()
