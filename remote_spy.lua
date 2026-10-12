-- ============================================================
-- REMOTE SPY & DAMAGE EXPLORER FOR ROBLOX (BLOODLINE)
-- Tự động in và copy toàn bộ Remote/Arguments khi bạn đánh quái
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Tạo UI riêng biệt, gọn gàng để theo dõi trực quan
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PTH_RemoteSpy"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = lp:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 520, 0, 360)
Frame.Position = UDim2.new(0.5, -260, 0.5, -180)
Frame.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
Frame.BorderSizePixel = 0
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(0, 255, 200)
Stroke.Thickness = 1.5

-- TopBar drag
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, -60, 0, 36)
Title.Position = UDim2.new(0, 14, 0, 4)
Title.Text = "📡 PTH REMOTE SPY (ĐÁNH QUÁI ĐỂ BẮT LOG)"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Frame)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local ClearBtn = Instance.new("TextButton", Frame)
ClearBtn.Size = UDim2.new(0, 60, 0, 24)
ClearBtn.Position = UDim2.new(1, -100, 0, 9)
ClearBtn.Text = "CLEAR"
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 10
ClearBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
ClearBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1, -20, 1, -52)
Scroll.Position = UDim2.new(0, 10, 0, 42)
Scroll.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 8)

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 6)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

ClearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end)

-- Format tham số
local function formatVal(v)
    if typeof(v) == "Instance" then
        return string.format("Instance(%s [%s])", v.Name, v.ClassName)
    elseif typeof(v) == "Vector3" then
        return string.format("Vector3(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
    elseif typeof(v) == "CFrame" then
        return "CFrame"
    elseif type(v) == "string" then
        return string.format('"%s"', v)
    elseif type(v) == "table" then
        local str = "{"
        for k, val in pairs(v) do
            str = str .. tostring(k) .. "=" .. formatVal(val) .. ", "
            if #str > 60 then str = str .. "..."; break end
        end
        return str .. "}"
    end
    return tostring(v)
end

local function addLog(remote, method, args)
    local card = Instance.new("Frame", Scroll)
    card.Size = UDim2.new(1, -6, 0, 70)
    card.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local isMelee = false
    local combined = (remote.Name .. " " .. tostring(args[1])):lower()
    if combined:find("hit") or combined:find("melee") or combined:find("damage") or combined:find("attack") or combined:find("combat") then
        isMelee = true
        card.BackgroundColor3 = Color3.fromRGB(35, 20, 45)
        local cStroke = Instance.new("UIStroke", card)
        cStroke.Color = Color3.fromRGB(255, 60, 100)
        cStroke.Thickness = 1
    end

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(1, -85, 0, 20)
    titleLbl.Position = UDim2.new(0, 8, 0, 4)
    titleLbl.Text = string.format("%s %s : %s", isMelee and "⚔️ [MELEE/HIT]" or "📡", remote.Name, method)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextColor3 = isMelee and Color3.fromRGB(255, 80, 120) or Color3.fromRGB(0, 220, 255)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local argsText = {}
    for i, a in ipairs(args) do
        table.insert(argsText, string.format("[%d] %s", i, formatVal(a)))
    end

    local argsLbl = Instance.new("TextLabel", card)
    argsLbl.Size = UDim2.new(1, -85, 0, 42)
    argsLbl.Position = UDim2.new(0, 8, 0, 24)
    argsLbl.Text = table.concat(argsText, " | ")
    argsLbl.Font = Enum.Font.Code
    argsLbl.TextSize = 10
    argsLbl.TextColor3 = Color3.fromRGB(200, 210, 230)
    argsLbl.BackgroundTransparency = 1
    argsLbl.TextXAlignment = Enum.TextXAlignment.Left
    argsLbl.TextYAlignment = Enum.TextYAlignment.Top
    argsLbl.TextWrapped = true

    -- Nút COPY code gọi lại Remote này
    local copyBtn = Instance.new("TextButton", card)
    copyBtn.Size = UDim2.new(0, 68, 0, 26)
    copyBtn.Position = UDim2.new(1, -74, 0.5, -13)
    copyBtn.Text = "COPY"
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 10
    copyBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 150)
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 5)

    copyBtn.MouseButton1Click:Connect(function()
        local code = string.format([[
-- Test Fire Script
local remote = game:GetService("%s"):FindFirstChild("%s", true)
remote:%s(%s)
]], remote.Parent and remote.Parent.Name or "ReplicatedStorage", remote.Name, method, table.concat(argsText, ", "))
        if setclipboard then
            setclipboard(code)
            copyBtn.Text = "COPIED!"
            task.wait(1)
            copyBtn.Text = "COPY"
        end
    end)
end

-- ==================== HOOK METAMETHOD ====================
local function getMethod()
    if getnamecallmethod then return getnamecallmethod() end
    if get_namecall_method then return get_namecall_method() end
    return nil
end

local hooked = false
if hookmetamethod and newcclosure then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getMethod()
        if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            local isScriptCaller = false
            if checkcaller then
                pcall(function() isScriptCaller = checkcaller() end)
            end
            if not isScriptCaller then
                local args = {...}
                task.spawn(function()
                    pcall(addLog, self, method, args)
                end)
            end
        end
        return oldNamecall(self, ...)
    end))
    hooked = true
end

if not hooked and hookfunction then
    local oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
        local args = {...}
        task.spawn(function() pcall(addLog, self, "FireServer", args) end)
        return oldFireServer(self, ...)
    end))
end

print("✅ Remote Spy Loaded! Hãy đến gần quái và đánh thường.")

