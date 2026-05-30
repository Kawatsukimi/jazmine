local userid1 = 5801536462
local userid2 = 9287360225
local userid3 = 10041989412

local pos1 = Vector3.new(-359.59, 491.38, -280.95)
local pos2 = Vector3.new(-364.17, 490.65, -280.43)
local pos3 = Vector3.new(-355.34, 492.07, -281.14)

-- no afk
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

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
