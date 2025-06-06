--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- Made by jailcase lmao join https://discord.gg/tQKnAxqjTX






-- Prevent multiple runs
if _G.SilentAimSetup then return end
_G.SilentAimSetup = true

-- [[ Services ]] --
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [[ Config ]] --
local SilentAim = {
    Enabled = true,
    HitPart = "HumanoidRootPart",
    FOV = {
        Visible = true,
        Radius = 150,
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 1,
        Transparency = 1
    }
}

-- [[ Drawing ]] --
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Color = SilentAim.FOV.Color
FOVCircle.Thickness = SilentAim.FOV.Thickness
FOVCircle.Transparency = SilentAim.FOV.Transparency
FOVCircle.Radius = SilentAim.FOV.Radius

-- [[ NPC Cache ]] --
local ValidNPCs = {}

local function isPlayer(model)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character == model then
            return true
        end
    end
    return false
end

local function validateNPC(model)
    if not model:IsA("Model") or isPlayer(model) then return false end
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    local part = model:FindFirstChild(SilentAim.HitPart)
    return hum and part and hum.Health > 0
end

local function addNPC(model)
    if not validateNPC(model) then return end
    table.insert(ValidNPCs, model)
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.Died:Connect(function()
            for i, v in ipairs(ValidNPCs) do
                if v == model then
                    table.remove(ValidNPCs, i)
                    break
                end
            end
        end)
    end
    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            for i, v in ipairs(ValidNPCs) do
                if v == model then
                    table.remove(ValidNPCs, i)
                    break
                end
            end
        end
    end)
end

for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("Model") then
        addNPC(v)
    end
end

Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Model") then
        task.wait(0.25)
        addNPC(desc)
    end
end)

local function GetClosestNPCPart()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, shortest = nil, math.huge
    for _, model in ipairs(ValidNPCs) do
        if model and model.Parent then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local part = model:FindFirstChild(SilentAim.HitPart)
            if hum and part and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen then
                    local dist = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < SilentAim.FOV.Radius and dist < shortest then
                        closest, shortest = part, dist
                    end
                end
            end
        end
    end
    return closest
end

local rawmt = getrawmetatable(game)
local old = rawmt.__index
setreadonly(rawmt, false)
rawmt.__index = function(self, key)
    if not checkcaller() and self == Mouse and SilentAim.Enabled then
        local target = GetClosestNPCPart()
        if target then
            if key == "Target" then
                return target
            elseif key == "Hit" then
                return target.CFrame
            end
        end
    end
    return old(self, key)
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = SilentAim.Enabled and SilentAim.FOV.Visible
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = SilentAim.FOV.Radius
end)

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("NotificationGui") or Instance.new("ScreenGui")
screenGui.Name = "NotificationGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local notifications = {}

local function showNotification(text)
    for i, notif in ipairs(notifications) do
        notif.Position = UDim2.new(1, -360, 1, -80 - (70 * i))
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 60)
    frame.Position = UDim2.new(1, -360, 1, -80)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.7
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 20
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTransparency = 1
    label.Parent = frame

    table.insert(notifications, 1, frame)

    TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()
    TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

    task.delay(5, function()
        TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        task.wait(0.5)
        frame:Destroy()
        table.remove(notifications, table.find(notifications, frame))
    end)
end

showNotification("SilentAim Loaded.. press M to toggle FOV visibility")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        SilentAim.FOV.Visible = not SilentAim.FOV.Visible
        showNotification("FOV " .. (SilentAim.FOV.Visible and "enabled" or "disabled"))
    elseif input.KeyCode == Enum.KeyCode.N then
        SilentAim.Enabled = not SilentAim.Enabled
        showNotification("SilentAim " .. (SilentAim.Enabled and "enabled" or "disabled"))
    end
end)
