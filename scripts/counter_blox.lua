-- OMNI HUB | Counter Blox V3 (Custom UI)
-- Full UI Menu Like MM2/Ink Game

task.wait(0.5)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

print("======================")
print("OMNI HUB - Counter Blox")
print("INSERT = Toggle Menu")
print("======================")

-- Config
getgenv().CBConfig = {
    BoxEsp = false,
    NameEsp = false,
    SpinbotEnabled = false,
    WalkSpeed = 16,
    MenuVisible = true,
    Connections = {}
}

-- Notify
local function Notify(msg)
    print("[OMNI] " .. msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "OMNI CB",
            Text = msg,
            Duration = 2
        })
    end)
end

-- ESP Functions
local function UpdateESP()
    while getgenv().CBConfig.BoxEsp or getgenv().CBConfig.NameEsp do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Team ~= LocalPlayer.Team then
                local char = p.Character
                
                -- Box ESP
                if getgenv().CBConfig.BoxEsp and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local hl = char:FindFirstChild("OmniHL")
                    if not hl then
                        hl = Instance.new("Highlight", char)
                        hl.Name = "OmniHL"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                    end
                else
                    local hl = char:FindFirstChild("OmniHL")
                    if hl then hl:Destroy() end
                end
                
                -- Name ESP
                if getgenv().CBConfig.NameEsp then
                    local head = char:FindFirstChild("Head")
                    if head and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        local bg = head:FindFirstChild("OmniName")
                        if not bg then
                            bg = Instance.new("BillboardGui", head)
                            bg.Name = "OmniName"
                            bg.Size = UDim2.new(0, 200, 0, 50)
                            bg.StudsOffset = Vector3.new(0, 2, 0)
                            bg.AlwaysOnTop = true
                            
                            local lbl = Instance.new("TextLabel", bg)
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.TextStrokeTransparency = 0
                            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 14
                            lbl.Name = "Lbl"
                        end
                        if bg and bg:FindFirstChild("Lbl") then
                            bg.Lbl.Text = p.Name .. " [" .. math.floor(char.Humanoid.Health) .. "]"
                        end
                    end
                else
                    if head then
                        local bg = head:FindFirstChild("OmniName")
                        if bg then bg:Destroy() end
                    end
                end
            end
        end
        task.wait(1.5)
    end
    
    -- Cleanup
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("OmniHL")
            if hl then hl:Destroy() end
            local head = p.Character:FindFirstChild("Head")
            if head then
                local nm = head:FindFirstChild("OmniName")
                if nm then nm:Destroy() end
            end
        end
    end
end

-- Movement Loop
local move_conn = RunService.Stepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = getgenv().CBConfig.WalkSpeed
    end
    
    if getgenv().CBConfig.SpinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(50), 0)
    end
end)
table.insert(getgenv().CBConfig.Connections, move_conn)

-- UI Builder
task.spawn(function()
    local Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if Parent:FindFirstChild("OmniCB") then Parent.OmniCB:Destroy() end

    local ScreenGui = Instance.new("ScreenGui", Parent)
    ScreenGui.Name = "OmniCB"
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 450, 0, 400)
    Main.Position = UDim2.new(0.5, -225, 0.5, -200)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Main.BackgroundTransparency = 0.2
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)

    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Color3.fromRGB(180, 0, 255)
    Stroke.Thickness = 2
    Stroke.Transparency = 0.5

    -- Title
    local Title = Instance.new("TextLabel", Main)
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Text = "OMNI HUB | COUNTER BLOX"
    Title.TextColor3 = Color3.fromRGB(180, 0, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.BackgroundTransparency = 1

    -- Container
    local Container = Instance.new("ScrollingFrame", Main)
    Container.Size = UDim2.new(1, -20, 1, -70)
    Container.Position = UDim2.new(0, 10, 0, 60)
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.ScrollBarThickness = 2
    
    local Layout = Instance.new("UIListLayout", Container)
    Layout.Padding = UDim.new(0, 10)

    -- Toggle Button Helper
    local function CreateToggle(text, config_key, callback)
        local btn = Instance.new("TextButton", Container)
        btn.Size = UDim2.new(1, -10, 0, 45)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.Text = "  " .. text .. ": OFF"
        btn.TextColor3 = Color3.fromRGB(150, 150, 160)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        btn.MouseButton1Click:Connect(function()
            getgenv().CBConfig[config_key] = not getgenv().CBConfig[config_key]
            btn.Text = "  " .. text .. ": " .. (getgenv().CBConfig[config_key] and "ON" or "OFF")
            btn.BackgroundColor3 = getgenv().CBConfig[config_key] and Color3.fromRGB(180, 0, 255) or Color3.fromRGB(30, 30, 40)
            btn.TextColor3 = getgenv().CBConfig[config_key] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
            
            if callback then callback(getgenv().CBConfig[config_key]) end
        end)
    end

    -- Slider Helper
    local function CreateSlider(text, min, max, def, callback)
        local frame = Instance.new("Frame", Container)
        frame.Size = UDim2.new(1, -10, 0, 60)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.Text = text .. ": " .. def
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left

        local bar = Instance.new("Frame", frame)
        bar.Size = UDim2.new(1, -20, 0, 4)
        bar.Position = UDim2.new(0, 10, 0, 45)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        bar.BorderSizePixel = 0

        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
        fill.BorderSizePixel = 0

        local function Update(input)
            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            local v = math.floor(min + (max - min) * pos)
            label.Text = text .. ": " .. v
            callback(v)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local conn
                conn = UserInputService.InputChanged:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseMovement then
                        Update(inp)
                    end
                end)
                local end_conn
                end_conn = UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        conn:Disconnect()
                        end_conn:Disconnect()
                    end
                end)
                Update(input)
            end
        end)
    end

    -- Features
    CreateToggle("Box ESP", "BoxEsp", function(state)
        if state then
            task.spawn(UpdateESP)
            Notify("Box ESP Enabled")
        else
            Notify("Box ESP Disabled")
        end
    end)

    CreateToggle("Name ESP", "NameEsp", function(state)
        if state then
            task.spawn(UpdateESP)
            Notify("Name ESP Enabled")
        else
            Notify("Name ESP Disabled")
        end
    end)

    CreateToggle("Spinbot", "SpinbotEnabled", function(state)
        Notify("Spinbot: " .. (state and "ON" or "OFF"))
    end)

    CreateSlider("Walk Speed", 16, 100, 16, function(v)
        getgenv().CBConfig.WalkSpeed = v
    end)

    -- Unload Button
    local unloadBtn = Instance.new("TextButton", Container)
    unloadBtn.Size = UDim2.new(1, -10, 0, 50)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
    unloadBtn.Text = "UNLOAD SCRIPT"
    unloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unloadBtn.Font = Enum.Font.GothamBold
    unloadBtn.TextSize = 14
    Instance.new("UICorner", unloadBtn).CornerRadius = UDim.new(0, 10)

    unloadBtn.MouseButton1Click:Connect(function()
        getgenv().CBConfig.BoxEsp = false
        getgenv().CBConfig.NameEsp = false
        getgenv().CBConfig.SpinbotEnabled = false
        
        for _, conn in pairs(getgenv().CBConfig.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                if p.Character:FindFirstChild("OmniHL") then p.Character.OmniHL:Destroy() end
                local head = p.Character:FindFirstChild("Head")
                if head and head:FindFirstChild("OmniName") then head.OmniName:Destroy() end
            end
        end
        
        ScreenGui:Destroy()
        Notify("Unloaded")
    end)

    -- Toggle Menu Key
    local toggleConn = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            getgenv().CBConfig.MenuVisible = not getgenv().CBConfig.MenuVisible
            Main.Visible = getgenv().CBConfig.MenuVisible
        end
    end)
    table.insert(getgenv().CBConfig.Connections, toggleConn)

    Notify("Loaded! Press INSERT to toggle menu")
end)
