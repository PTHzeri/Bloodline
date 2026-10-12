-- [[ PTH HUB - SYSTEM + FARM + REMOTE SNIFFER V2 + ESP + FRUIT FARM ]]
if not game:IsLoaded() then game.Loaded:Wait() end

local PlayersService = game:GetService("Players")
local lp = PlayersService.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ===== CLEANUP ESP CŨ =====
if _G._PTH_ESP_Render then
    pcall(function() _G._PTH_ESP_Render:Disconnect() end)
    _G._PTH_ESP_Render = nil
end
if _G._PTH_ESP_Objects then
    for _, o in pairs(_G._PTH_ESP_Objects) do
        pcall(function() o.bb:Destroy() end)
        pcall(function() o.hl:Destroy() end)
    end
    _G._PTH_ESP_Objects = nil
end
for _, p in ipairs(PlayersService:GetPlayers()) do
    if p.Character then
        for _, obj in ipairs(p.Character:GetChildren()) do
            if obj:IsA("Highlight") and obj.Name == "PTH_ESP_HL" then obj:Destroy() end
        end
        local head = p.Character:FindFirstChild("Head")
        if head then
            for _, obj in ipairs(head:GetChildren()) do
                if obj:IsA("BillboardGui") and obj.Name == "PTH_ESP_BB" then obj:Destroy() end
            end
        end
    end
end
if _G._PTH_Boss_ESP_Objects then
    for _, o in pairs(_G._PTH_Boss_ESP_Objects) do
        pcall(function() o.bb:Destroy() end)
        pcall(function() o.hl:Destroy() end)
    end
    _G._PTH_Boss_ESP_Objects = nil
end

-- ===== CLEANUP FRUIT CŨ (nếu load lại) =====
if _G._PTH_FruitStop then pcall(_G._PTH_FruitStop) end
if _G._PTH_FruitNoclip then pcall(function() _G._PTH_FruitNoclip:Disconnect() end) end
if _G._PTH_FruitHold then pcall(function() _G._PTH_FruitHold:Disconnect() end) end
if _G._PTH_FruitLoop then pcall(function() task.cancel(_G._PTH_FruitLoop) end) end
_G._PTH_FruitNoclip = nil
_G._PTH_FruitHold = nil
_G._PTH_FruitLoop = nil
_G._PTH_FruitStop = nil
if _G._PTH_StopPlayerFarm then pcall(_G._PTH_StopPlayerFarm) end
if _G._PTH_StopBossFarm then pcall(_G._PTH_StopBossFarm) end

-- ===== CHARACTER PHYSICS & COLLISION HELPERS =====
local function restoreCharacterCollision(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local name = part.Name
            -- Trong Roblox, chỉ Torso / Head mới bật CanCollide; tứ chi (arms, legs) PHẢI là false
            -- Nếu bật CanCollide trên tay/chân sẽ bị va chạm lẫn nhau và với Torso làm nhân vật bị giật lùi/văng!
            if name == "Torso" or name == "UpperTorso" or name == "LowerTorso" or name == "Head" then
                pcall(function() part.CanCollide = true end)
            else
                pcall(function() part.CanCollide = false end)
            end
        end
    end
end

local function stopCharacterMomentum(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end)
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

-- ===== CLEANUP GUI CŨ (tránh bị nhân đôi GUI khi execute lại) =====
do
    local pg = lp:FindFirstChild("PlayerGui")
    local old = pg and pg:FindFirstChild("PTH_HUB_CLEANED")
    if old then pcall(function() old:Destroy() end) end
end
if _G._PTH_SystemCleanup then pcall(_G._PTH_SystemCleanup) _G._PTH_SystemCleanup = nil end
if _G._PTH_AFKThread then pcall(function() task.cancel(_G._PTH_AFKThread) end) _G._PTH_AFKThread = nil end

-- ===== CẤU HÌNH FARM =====
local returnPos = Vector3.new(1030.5, 291.6, -1879.2)
_G.FarmDistance = 5
_G.FarmHeight   = 0
_G.AutoExecuteKnocked = false
_G.SelectedWeapon = nil
_G.TargetPlayerToFarm = nil
_G.ESPPlayer = false
_G.FarmLoopDelay = 2
_G.FarmStickTime = 0.5
_G.FarmLeadTime  = 0.1
_G.AttackMode    = "TOOL"
_G.SelectedRemote = nil
_G.SelectedRemoteName = nil
_G.RemoteArgMode = 2
_G.RemoteActionString = "Combat"
_G.SnifferActive = false
_G.DetectedRemotes = {}
local KNOCKED_HEALTH_THRESHOLD = 3

-- ===== SCREENGUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PTH_HUB_CLEANED"
ScreenGui.Parent = lp:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- ===== MAIN FRAME =====
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 560, 0, 480)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 14, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.ClipsDescendants = false

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 16)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(110, 60, 240)
UIStroke.Thickness = 1.8
UIStroke.Transparency = 0.2

-- Nền Gradient mờ phía sau
local MainGradient = Instance.new("UIGradient", MainFrame)
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 19, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 17))
})
MainGradient.Rotation = 45

-- ===== DRAGGING (gắn vào TopBar) =====
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

-- ===== TOP BAR =====
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 46)
TopBar.BackgroundColor3 = Color3.fromRGB(17, 18, 28)
TopBar.BorderSizePixel = 0
local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = UDim.new(0, 16)

-- Che góc bo tròn dưới của TopBar
local TopBarCover = Instance.new("Frame", TopBar)
TopBarCover.Size = UDim2.new(1, 0, 0, 12)
TopBarCover.Position = UDim2.new(0, 0, 1, -12)
TopBarCover.BackgroundColor3 = Color3.fromRGB(17, 18, 28)
TopBarCover.BorderSizePixel = 0

-- Đường kẻ viền ngăn cách TopBar
local TopBarDivider = Instance.new("Frame", TopBar)
TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
TopBarDivider.Position = UDim2.new(0, 0, 1, 0)
TopBarDivider.BackgroundColor3 = Color3.fromRGB(35, 38, 58)
TopBarDivider.BorderSizePixel = 0

local TitleIcon = Instance.new("TextLabel", TopBar)
TitleIcon.Size = UDim2.new(0, 32, 1, 0)
TitleIcon.Position = UDim2.new(0, 12, 0, 0)
TitleIcon.Text = "⚡"
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextSize = 18
TitleIcon.TextColor3 = Color3.fromRGB(160, 90, 255)
TitleIcon.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 44, 0, 0)
Title.Text = "PTH HUB  <font color=\"#a060ff\">v2.5</font>"
Title.RichText = true
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(240, 242, 255)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Status Badge trên Topbar
local StatusBadge = Instance.new("Frame", TopBar)
StatusBadge.Size = UDim2.new(0, 75, 0, 22)
StatusBadge.Position = UDim2.new(0, 175, 0.5, -11)
StatusBadge.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
Instance.new("UICorner", StatusBadge).CornerRadius = UDim.new(1, 0)
local StatusDot = Instance.new("Frame", StatusBadge)
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(0, 8, 0.5, -3)
StatusDot.BackgroundColor3 = Color3.fromRGB(50, 230, 130)
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
local StatusText = Instance.new("TextLabel", StatusBadge)
StatusText.Size = UDim2.new(1, -20, 1, 0)
StatusText.Position = UDim2.new(0, 18, 0, 0)
StatusText.Text = "ONLINE"
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 10
StatusText.TextColor3 = Color3.fromRGB(50, 230, 130)
StatusText.BackgroundTransparency = 1
StatusText.TextXAlignment = Enum.TextXAlignment.Left

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging and dragStart and startPos then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local HideBtn = Instance.new("TextButton", TopBar)
HideBtn.Size = UDim2.new(0, 32, 0, 32)
HideBtn.Position = UDim2.new(1, -78, 0.5, -16)
HideBtn.Text = "−"
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 18
HideBtn.BackgroundColor3 = Color3.fromRGB(26, 28, 42)
HideBtn.TextColor3 = Color3.fromRGB(180, 185, 215)
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 8)
local HideStroke = Instance.new("UIStroke", HideBtn)
HideStroke.Color = Color3.fromRGB(45, 48, 70)
HideStroke.Thickness = 1

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BackgroundColor3 = Color3.fromRGB(230, 60, 80)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Logo mở lại khi HIDE
local LogoBtn = Instance.new("TextButton", ScreenGui)
LogoBtn.Size = UDim2.new(0, 130, 0, 42)
LogoBtn.Position = UDim2.new(0, 15, 0, 15)
LogoBtn.Text = "⚡ PTH HUB"
LogoBtn.Font = Enum.Font.GothamBold
LogoBtn.TextSize = 15
LogoBtn.BackgroundColor3 = Color3.fromRGB(18, 19, 30)
LogoBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
Instance.new("UICorner", LogoBtn).CornerRadius = UDim.new(0, 10)
local LogoStroke = Instance.new("UIStroke", LogoBtn)
LogoStroke.Color = Color3.fromRGB(140, 45, 230)
LogoStroke.Thickness = 2
LogoBtn.Visible = false

HideBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    LogoBtn.Visible = true
end)
LogoBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    LogoBtn.Visible = false
end)

local States = { System = { AntiAFK = false } }
CloseBtn.MouseButton1Click:Connect(function()
    if _G._PTH_ESP_Render then
        pcall(function() _G._PTH_ESP_Render:Disconnect() end)
        _G._PTH_ESP_Render = nil
    end
    if _G._PTH_ESP_Objects then
        for _, o in pairs(_G._PTH_ESP_Objects) do
            pcall(function() o.bb:Destroy() end)
            pcall(function() o.hl:Destroy() end)
        end
        _G._PTH_ESP_Objects = nil
    end
    if _G._PTH_Boss_ESP_Objects then
        for _, o in pairs(_G._PTH_Boss_ESP_Objects) do
            pcall(function() o.bb:Destroy() end)
            pcall(function() o.hl:Destroy() end)
        end
        _G._PTH_Boss_ESP_Objects = nil
    end
    -- cleanup Fruit
    if _G._PTH_FruitStop then pcall(_G._PTH_FruitStop) end
    if _G._PTH_FruitNoclip then pcall(function() _G._PTH_FruitNoclip:Disconnect() end) end
    if _G._PTH_FruitHold then pcall(function() _G._PTH_FruitHold:Disconnect() end) end
    if _G._PTH_FruitLoop then pcall(function() task.cancel(_G._PTH_FruitLoop) end) end
    -- dừng các tính năng khác
    if _G._PTH_StopPlayerFarm then pcall(_G._PTH_StopPlayerFarm) end
    if _G._PTH_StopBossFarm then pcall(_G._PTH_StopBossFarm) end
    _G.TargetPlayerToFarm = nil
    _G.TargetBossToFarm = nil
    _G.ESPPlayer = false
    _G.SnifferActive = false
    _G.AutoExecuteKnocked = false
    States.System.AntiAFK = false
    if _G._PTH_AFKThread then pcall(function() task.cancel(_G._PTH_AFKThread) end) _G._PTH_AFKThread = nil end
    if _G._PTH_SystemCleanup then pcall(_G._PTH_SystemCleanup) end
    
    -- Khôi phục va chạm và triệt tiêu toàn bộ lực kéo/quán tính
    if lp.Character then
        restoreCharacterCollision(lp.Character)
        stopCharacterMomentum(lp.Character)
    end
    ScreenGui:Destroy()
end)

-- ===== SIDEBAR =====
local Sidebar = Instance.new("ScrollingFrame", MainFrame)
Sidebar.Size = UDim2.new(0, 145, 1, -54)
Sidebar.Position = UDim2.new(0, 8, 0, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 17, 26)
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.ScrollBarImageColor3 = Color3.fromRGB(60, 65, 95)
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local SidebarStroke = Instance.new("UIStroke", Sidebar)
SidebarStroke.Color = Color3.fromRGB(28, 30, 45)
SidebarStroke.Thickness = 1

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

local SidebarPadding = Instance.new("UIPadding", Sidebar)
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingBottom = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 6)
SidebarPadding.PaddingRight = UDim.new(0, 6)

-- ===== CONTENT FRAME =====
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -167, 1, -54)
ContentFrame.Position = UDim2.new(0, 159, 0, 50)
ContentFrame.BackgroundColor3 = Color3.fromRGB(16, 17, 26)
ContentFrame.BorderSizePixel = 0
ContentFrame.ClipsDescendants = true
Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 12)

local ContentStroke = Instance.new("UIStroke", ContentFrame)
ContentStroke.Color = Color3.fromRGB(28, 30, 45)
ContentStroke.Thickness = 1

local Features = {}
local SectionFrames = {}
local TabButtons = {}

local TAB_ICONS = {
    ["System"] = "⚙️",
    ["Farm"]   = "⚡",
    ["Remote"] = "🔌",
    ["ESP"]    = "👁️",
    ["Fruit"]  = "🍊",
}

-- ===== OPEN SECTION =====
local function OpenSection(name)
    for tabName, btn in pairs(TabButtons) do
        if tabName == name then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(110, 60, 240),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            local ind = btn:FindFirstChild("Indicator")
            if ind then ind.Visible = true end
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(22, 24, 36),
                TextColor3 = Color3.fromRGB(160, 165, 190)
            }):Play()
            local ind = btn:FindFirstChild("Indicator")
            if ind then ind.Visible = false end
        end
    end

    for _, frame in pairs(SectionFrames) do
        if frame and frame.Parent then frame.Visible = false end
    end
    if SectionFrames[name] then SectionFrames[name].Visible = true return end

    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.CanvasSize = UDim2.new(0, 0, 0, 900)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 120)
    Page.BorderSizePixel = 0
    Page.BackgroundTransparency = 1
    Page.Parent = ContentFrame
    SectionFrames[name] = Page

    local pagePadding = Instance.new("UIPadding", Page)
    pagePadding.PaddingTop = UDim.new(0, 10)
    pagePadding.PaddingBottom = UDim.new(0, 15)
    pagePadding.PaddingLeft = UDim.new(0, 10)
    pagePadding.PaddingRight = UDim.new(0, 10)

    if type(Features[name]) == "function" then
        task.spawn(function()
            pcall(function() Features[name](Page) end)
        end)
    end
end

-- ===== SIDEBAR BUTTON =====
local function CreateSidebarBtn(name)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Text = "  " .. (TAB_ICONS[name] or "📁") .. "  " .. name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
    btn.TextColor3 = Color3.fromRGB(160, 165, 190)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local ind = Instance.new("Frame", btn)
    ind.Name = "Indicator"
    ind.Size = UDim2.new(0, 3, 0.6, 0)
    ind.Position = UDim2.new(0, 3, 0.2, 0)
    ind.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
    ind.BorderSizePixel = 0
    ind.Visible = false
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

    btn.MouseEnter:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(110, 60, 240) then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 33, 48)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(110, 60, 240) then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 24, 36)}):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function() OpenSection(name) end)
    TabButtons[name] = btn
end

-- ============================================================
-- ============== REMOTE ATTACK HELPERS =======================
-- ============================================================
local ARG_MODE_NAMES = {
    [1] = "No Args",
    [2] = "Target Player",
    [3] = "Target Character",
    [4] = "Target HRP",
    [5] = "Target Position",
    [6] = "HRP + HRP",
    [7] = "Player + HRP",
    [8] = "Action + Player",
    [9] = "Action + HRP",
    [10] = "Action + Position",
    [11] = "Action + Character",
}

local function buildRemoteArgs(targetObj, mode)
    local char = nil
    local pInstance = nil
    if typeof(targetObj) == "Instance" then
        if targetObj:IsA("Player") then
            pInstance = targetObj
            char = targetObj.Character
        elseif targetObj:IsA("Model") then
            char = targetObj
            pInstance = PlayersService:GetPlayerFromCharacter(targetObj) or targetObj
        end
    end
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart)
    local mode = mode or _G.RemoteArgMode
    local action = _G.RemoteActionString or "Combat"

    if mode == 1 then
        return {}
    elseif mode == 2 then
        return {pInstance or char}
    elseif mode == 3 then
        return {char or pInstance}
    elseif mode == 4 then
        return {hrp or char}
    elseif mode == 5 then
        return {hrp and hrp.Position or Vector3.new()}
    elseif mode == 6 then
        return {hrp or char, hrp or char}
    elseif mode == 7 then
        return {pInstance or char, hrp or char}
    elseif mode == 8 then
        return {action, pInstance or char}
    elseif mode == 9 then
        return {action, hrp or char}
    elseif mode == 10 then
        return {action, hrp and hrp.Position or Vector3.new()}
    elseif mode == 11 then
        return {action, char or pInstance}
    end
    return {}
end

local function fireAttackRemote(targetObj)
    local remote = _G.SelectedRemote
    if not remote or not targetObj then return false end

    local char = nil
    local pInstance = nil
    if typeof(targetObj) == "Instance" then
        if targetObj:IsA("Player") then
            pInstance = targetObj
            char = targetObj.Character
        elseif targetObj:IsA("Model") then
            char = targetObj
            pInstance = PlayersService:GetPlayerFromCharacter(targetObj) or targetObj
        end
    end
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart)

    -- Ưu tiên sử dụng chính xác args mà game vừa bắn ra khi bắt được (Replay Captured Args)
    -- Xử lý chuyên biệt cho action CheckMeleeHit trong Bloodline
    local selectedName = _G.SelectedRemoteName or ""
    if string.find(selectedName:lower(), "checkmeleehit") or (_G.RemoteActionString and _G.RemoteActionString:lower() == "checkmeleehit") then
        if _G.RemoteCapturedArgs and #_G.RemoteCapturedArgs >= 3 then
            finalArgs = {}
            for i, v in ipairs(_G.RemoteCapturedArgs) do
                if i == 1 then
                    finalArgs[1] = "CheckMeleeHit"
                elseif typeof(v) == "Instance" then
                    finalArgs[i] = char or hrp or v
                elseif typeof(v) == "Vector3" and hrp then
                    finalArgs[i] = hrp.Position
                else
                    finalArgs[i] = v
                end
            end
        else
            -- Cấu trúc chuẩn của CheckMeleeHit trong Bloodline: {"CheckMeleeHit", TargetCharacter/HRP, TargetHRP.Position, ...}
            finalArgs = {"CheckMeleeHit", char or hrp, hrp and hrp.Position or Vector3.zero, true}
        end
    elseif _G.RemoteCapturedArgs and #_G.RemoteCapturedArgs > 0 then
        finalArgs = {}
        for i, v in ipairs(_G.RemoteCapturedArgs) do
            -- Nếu trong arg có chứa con trỏ Instance/Model/Player/Vector3, thay thế bằng mục tiêu hiện tại
            if typeof(v) == "Instance" then
                if v:IsA("Player") then
                    finalArgs[i] = pInstance or char
                elseif v:IsA("Model") then
                    finalArgs[i] = char or pInstance
                elseif v:IsA("BasePart") then
                    finalArgs[i] = hrp or char
                else
                    finalArgs[i] = v
                end
            elseif typeof(v) == "Vector3" and hrp then
                finalArgs[i] = hrp.Position
            else
                finalArgs[i] = v
            end
        end
    else
        finalArgs = buildRemoteArgs(targetObj, _G.RemoteArgMode)
    end

    local ok = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(table.unpack(finalArgs))
        elseif remote:IsA("RemoteFunction") then
            task.spawn(function()
                pcall(function() remote:InvokeServer(table.unpack(finalArgs)) end)
            end)
        end
    end)
    return ok
end

-- ===== SNIFFER =====
local function getMethod()
    if getnamecallmethod then return getnamecallmethod() end
    if get_namecall_method then return get_namecall_method() end
    return nil
end

local function recordRemote(self, method, ...)
    if not _G.SnifferActive then return end
    if checkcaller and checkcaller() then return end -- bỏ qua remote do chính script bắn
    if typeof(self) ~= "Instance" then return end
    if not (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then return end
    local n = select("#", ...)
    local args = {...}

    -- Trong Bloodline/Anime games, DataEvent và DataFunction dùng args[1] làm tên action (vd: "Combat", "Damage", "Hit", "Skill")
    local actionName = ""
    if n >= 1 and type(args[1]) == "string" then
        actionName = args[1]
    end

    local callKey = self:GetFullName() .. (actionName ~= "" and (" :: " .. actionName) or "")

    -- Kiểm tra xem call này có liên quan tới đòn đánh / gây dame / combat không
    local isAttackRelated = false
    local combinedCheck = (self.Name .. " " .. actionName):lower()
    for _, kw in ipairs({"combat", "hit", "damage", "attack", "punch", "slash", "swing", "m1", "weapon", "skill", "takehit", "takedamage", "hurt"}) do
        if string.find(combinedCheck, kw, 1, true) then
            isAttackRelated = true
            break
        end
    end

    _G.DetectedRemotes = _G.DetectedRemotes or {}
    local entry = _G.DetectedRemotes[callKey]
    if not entry then
        entry = {
            remote = self,
            count = 0,
            action = actionName,
            isAttack = isAttackRelated,
            callKey = callKey
        }
        _G.DetectedRemotes[callKey] = entry
    end
    entry.count = entry.count + 1
    entry.lastArgs = args
    entry.argCount = n
    entry.method = method

    -- Nếu đây là đòn đánh và chưa chọn remote nào hoặc đang tìm remote đánh, tự gán luôn!
    if isAttackRelated and not _G._PTH_ManualSelected then
        _G.SelectedRemote = self
        _G.SelectedRemoteName = callKey
        _G.RemoteCapturedArgs = args
        if actionName ~= "" then
            _G.RemoteActionString = actionName
        end
    end
end

local function startSniffer()
    if _G._PTH_SnifferActive then return true end
    _G.DetectedRemotes = _G.DetectedRemotes or {}

    local hooked = false
    local function handler(oldNamecall)
        return function(self, ...)
            local method = getMethod()
            if method == "FireServer" or method == "InvokeServer" then
                pcall(recordRemote, self, method, ...)
            end
            return oldNamecall(self, ...)
        end
    end

    if hookmetamethod and newcclosure then
        local ok = pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getMethod()
                if method == "FireServer" or method == "InvokeServer" then
                    pcall(recordRemote, self, method, ...)
                end
                return oldNamecall(self, ...)
            end))
        end)
        hooked = ok
    end
    if not hooked and getrawmetatable and newcclosure then
        local ok = pcall(function()
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall
            if setreadonly then setreadonly(mt, false) end
            mt.__namecall = newcclosure(handler(oldNamecall))
            if setreadonly then setreadonly(mt, true) end
        end)
        hooked = ok
    end
    if not hooked then
        return false, "Executor không hỗ trợ hook"
    end
    _G._PTH_SnifferActive = true -- hook chỉ cài 1 lần, bật/tắt bằng _G.SnifferActive
    return true
end

-- ============================================================
-- ================= SYSTEM FEATURE ===========================
-- ============================================================
local function SetupSystemFeature(parent)
    local header = Instance.new("TextLabel", parent)
    header.Size = UDim2.new(1, -20, 0, 30)
    header.Position = UDim2.new(0, 10, 0, 48)
    header.Text = "⚙️ SYSTEM"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = Color3.fromRGB(0, 255, 200)
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left

    local baseX = 10
    local btnW = 250
    local btnH = 40
    local spacing = 10
    local startY = 110

    local infJumpBtn = Instance.new("TextButton", parent)
    infJumpBtn.Size = UDim2.new(0, btnW, 0, btnH)
    infJumpBtn.Position = UDim2.new(0, baseX, 0, startY)
    infJumpBtn.Text = "INFINITE JUMP: OFF"
    infJumpBtn.Font = Enum.Font.GothamBold
    infJumpBtn.TextSize = 14
    infJumpBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    infJumpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", infJumpBtn).CornerRadius = UDim.new(0,8)

    local flyRow = Instance.new("Frame", parent)
    flyRow.Size = UDim2.new(1, -20, 0, btnH)
    flyRow.Position = UDim2.new(0, baseX, 0, startY + (btnH + spacing) * 1)
    flyRow.BackgroundTransparency = 1
    flyRow.ZIndex = 5

    local flyBtn = Instance.new("TextButton", flyRow)
    flyBtn.Size = UDim2.new(0, btnW, 0, btnH)
    flyBtn.Position = UDim2.new(0, 0, 0, 0)
    flyBtn.Text = "FLY: OFF (Speed: 80)"
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextSize = 14
    flyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    flyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    flyBtn.ZIndex = 6
    Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0,8)

    local speedBox = Instance.new("TextBox", flyRow)
    speedBox.Size = UDim2.new(0, 70, 0, btnH)
    speedBox.Position = UDim2.new(0, btnW + 10, 0, 0)
    speedBox.Text = "80"
    speedBox.PlaceholderText = "Speed"
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextSize = 14
    speedBox.TextColor3 = Color3.fromRGB(0,255,200)
    speedBox.ClearTextOnFocus = false
    speedBox.BackgroundColor3 = Color3.fromRGB(40,40,50)
    speedBox.ZIndex = 7
    Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,6)

    local decBtn = Instance.new("TextButton", flyRow)
    decBtn.Size = UDim2.new(0, 30, 0, btnH)
    decBtn.Position = UDim2.new(0, btnW + 10 + 70 + 5, 0, 0)
    decBtn.Text = "-"
    decBtn.Font = Enum.Font.GothamBold
    decBtn.TextSize = 18
    decBtn.BackgroundColor3 = Color3.fromRGB(60,60,120)
    decBtn.TextColor3 = Color3.fromRGB(255,255,255)
    decBtn.ZIndex = 6
    Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0,6)

    local incBtn = Instance.new("TextButton", flyRow)
    incBtn.Size = UDim2.new(0, 30, 0, btnH)
    incBtn.Position = UDim2.new(0, btnW + 10 + 70 + 5 + 30 + 5, 0, 0)
    incBtn.Text = "+"
    incBtn.Font = Enum.Font.GothamBold
    incBtn.TextSize = 18
    incBtn.BackgroundColor3 = Color3.fromRGB(60,60,120)
    incBtn.TextColor3 = Color3.fromRGB(255,255,255)
    incBtn.ZIndex = 6
    Instance.new("UICorner", incBtn).CornerRadius = UDim.new(0,6)

    local isFlying = false
    local flyBV, flyBG = nil, nil
    local flyConn = nil
    local flySpeed = 80

    local function applyFlySpeedFromBox()
        local num = tonumber(speedBox.Text)
        if not num or num <= 0 then speedBox.Text = tostring(flySpeed) return end
        flySpeed = num
        flyBtn.Text = "FLY: " .. (isFlying and "ON" or "OFF") .. " (Speed: "..tostring(flySpeed)..")"
    end

    speedBox.FocusLost:Connect(function() applyFlySpeedFromBox() end)
    incBtn.MouseButton1Click:Connect(function()
        flySpeed = math.max(1, flySpeed + 10); speedBox.Text = tostring(flySpeed); applyFlySpeedFromBox()
    end)
    decBtn.MouseButton1Click:Connect(function()
        flySpeed = math.max(1, flySpeed - 10); speedBox.Text = tostring(flySpeed); applyFlySpeedFromBox()
    end)

    local function startFly()
        if not lp.Character then lp.CharacterAdded:Wait() end
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
        if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3.new(0,0,0)
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBG.CFrame = hrp.CFrame
        flyBG.Parent = hrp
        hum.PlatformStand = false
        flyConn = RunService.Heartbeat:Connect(function()
            if not isFlying or not hrp or not hrp.Parent then return end
            local cam = workspace.CurrentCamera
            local moveVec = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0,1,0) end
            if moveVec.Magnitude > 0 then moveVec = moveVec.Unit * flySpeed else moveVec = Vector3.new(0,0,0) end
            if flyBV then flyBV.Velocity = Vector3.new(moveVec.X, moveVec.Y, moveVec.Z) end
            if flyBG and hrp then flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector) end
        end)
    end

    local function stopFly()
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
        if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
            pcall(function() lp.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false end)
        end
    end

    flyBtn.MouseButton1Click:Connect(function()
        applyFlySpeedFromBox()
        isFlying = not isFlying
        flyBtn.Text = "FLY: " .. (isFlying and "ON" or "OFF") .. " (Speed: "..tostring(flySpeed)..")"
        flyBtn.BackgroundColor3 = isFlying and Color3.fromRGB(0,150,0) or Color3.fromRGB(60,60,120)
        if isFlying then task.spawn(startFly) else stopFly() end
    end)

    -- Respawn khi đang bay -> gắn lại BodyVelocity/BodyGyro cho nhân vật mới
    local flyCharConn = lp.CharacterAdded:Connect(function(c)
        if not isFlying then return end
        stopFly()
        c:WaitForChild("HumanoidRootPart", 10)
        c:WaitForChild("Humanoid", 10)
        if isFlying then startFly() end
    end)

    local antiRow = Instance.new("Frame", parent)
    antiRow.Size = UDim2.new(1, -20, 0, 40)
    antiRow.Position = UDim2.new(0, 10, 0, startY + (btnH + spacing) * 2)
    antiRow.BackgroundTransparency = 1

    local antiBtn = Instance.new("TextButton", antiRow)
    antiBtn.Size = UDim2.new(0, btnW, 0, btnH)
    antiBtn.Position = UDim2.new(0, 0, 0, 0)
    antiBtn.Text = "ANTI AFK: " .. (States.System.AntiAFK and "ON" or "OFF")
    antiBtn.Font = Enum.Font.GothamBold
    antiBtn.TextSize = 14
    antiBtn.BackgroundColor3 = States.System.AntiAFK and Color3.fromRGB(0,150,0) or Color3.fromRGB(60,60,120)
    antiBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", antiBtn).CornerRadius = UDim.new(0,8)

    local afkThread = nil
    local afkConn = nil

    local function startAntiAFK()
        if afkThread then return end
        afkThread = task.spawn(function()
            while States.System.AntiAFK do
                pcall(function()
                    local char = lp.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                    else
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(0,0))
                        end)
                    end
                end)
                task.wait(60)
            end
            afkThread = nil
            _G._PTH_AFKThread = nil
        end)
        _G._PTH_AFKThread = afkThread
    end

    local function stopAntiAFK()
        States.System.AntiAFK = false
        if afkConn then afkConn:Disconnect() afkConn = nil end
        -- hủy hẳn thread đang chờ task.wait(60), tránh chạy 2 vòng lặp khi bật lại
        if afkThread then pcall(function() task.cancel(afkThread) end) end
        afkThread = nil
        _G._PTH_AFKThread = nil
    end

    antiBtn.MouseButton1Click:Connect(function()
        States.System.AntiAFK = not States.System.AntiAFK
        local isOn = States.System.AntiAFK
        antiBtn.Text = "ANTI AFK: " .. (isOn and "ON" or "OFF")
        antiBtn.BackgroundColor3 = isOn and Color3.fromRGB(0,150,0) or Color3.fromRGB(60,60,120)
        if isOn then
            startAntiAFK()
            if not afkConn then
                afkConn = lp.Idled:Connect(function()
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new(0,0))
                    end)
                end)
            end
        else
            stopAntiAFK()
        end
    end)

    local infJumpEnabled = false
    local jumpConn = nil
    local function enableInfJump()
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
        jumpConn = UIS.JumpRequest:Connect(function()
            if infJumpEnabled and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
                pcall(function() lp.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end)
    end

    infJumpBtn.MouseButton1Click:Connect(function()
        infJumpEnabled = not infJumpEnabled
        infJumpBtn.Text = "INFINITE JUMP: " .. (infJumpEnabled and "ON" or "OFF")
        infJumpBtn.BackgroundColor3 = infJumpEnabled and Color3.fromRGB(0,150,0) or Color3.fromRGB(60,60,120)
        if infJumpEnabled then enableInfJump() else
            if jumpConn then jumpConn:Disconnect() jumpConn = nil end
        end
    end)

    -- Dọn dẹp khi bấm CLOSE
    _G._PTH_SystemCleanup = function()
        isFlying = false
        stopFly()
        if flyCharConn then flyCharConn:Disconnect() flyCharConn = nil end
        stopAntiAFK()
        infJumpEnabled = false
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    end

    local rejoinBtn = Instance.new("TextButton", parent)
    rejoinBtn.Size = UDim2.new(0, btnW, 0, btnH)
    rejoinBtn.Position = UDim2.new(0, 10, 0, startY + (btnH + spacing) * 3)
    rejoinBtn.Text = "🔄 REJOIN SERVER"
    rejoinBtn.Font = Enum.Font.GothamBold
    rejoinBtn.TextSize = 14
    rejoinBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
    rejoinBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0,8)
    rejoinBtn.MouseButton1Click:Connect(function()
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, lp) end)
    end)
end
Features["System"] = SetupSystemFeature

-- ============================================================
-- ============ FARM FEATURE ==================================
-- ============================================================
local function SetupFarmFeature(parent)
    local header = Instance.new("TextLabel", parent)
    header.Size = UDim2.new(1, -20, 0, 30)
    header.Position = UDim2.new(0, 10, 0, 48)
    header.Text = "⚡ PLAYER HUNTER"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = Color3.fromRGB(0, 255, 200)
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left

    local modeFrame = Instance.new("Frame", parent)
    modeFrame.Size = UDim2.new(1, -20, 0, 34)
    modeFrame.Position = UDim2.new(0, 10, 0, 88)
    modeFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    Instance.new("UICorner", modeFrame).CornerRadius = UDim.new(0, 6)

    local modeLabel = Instance.new("TextLabel", modeFrame)
    modeLabel.Text = "🎯 Attack Mode: " .. _G.AttackMode
    modeLabel.Font = Enum.Font.GothamBold
    modeLabel.TextSize = 13
    modeLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    modeLabel.Size = UDim2.new(1, 0, 1, 0)
    modeLabel.BackgroundTransparency = 1

    local weaponFrame = Instance.new("Frame", parent)
    weaponFrame.Size = UDim2.new(1, -20, 0, 40)
    weaponFrame.Position = UDim2.new(0, 10, 0, 128)
    weaponFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    Instance.new("UICorner", weaponFrame).CornerRadius = UDim.new(0, 6)

    local weaponLabel = Instance.new("TextLabel", weaponFrame)
    weaponLabel.Text = " Vũ khí:"
    weaponLabel.Font = Enum.Font.GothamBold
    weaponLabel.TextSize = 13
    weaponLabel.TextColor3 = Color3.new(1, 1, 1)
    weaponLabel.Size = UDim2.new(0.3, 0, 1, 0)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.TextXAlignment = Enum.TextXAlignment.Left

    local weaponBtn = Instance.new("TextButton", weaponFrame)
    weaponBtn.Size = UDim2.new(0.68, 0, 0, 28)
    weaponBtn.Position = UDim2.new(0.3, 0, 0.5, -14)
    weaponBtn.Text = _G.SelectedWeapon or "Chưa chọn"
    weaponBtn.Font = Enum.Font.GothamBold
    weaponBtn.TextSize = 11
    weaponBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
    weaponBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
    Instance.new("UICorner", weaponBtn).CornerRadius = UDim.new(0, 6)

    weaponBtn.MouseButton1Click:Connect(function()
        local tools = {}
        local backpack = lp:FindFirstChild("Backpack")
        local char = lp.Character
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then table.insert(tools, item.Name) end
            end
        end
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then table.insert(tools, item.Name) end
            end
        end
        if #tools == 0 then
            weaponBtn.Text = "Balo trống!"; task.wait(1.5); weaponBtn.Text = _G.SelectedWeapon or "Chưa chọn"; return
        end
        local currentIndex = 0
        for i, name in ipairs(tools) do
            if name == _G.SelectedWeapon then currentIndex = i; break end
        end
        _G.SelectedWeapon = tools[(currentIndex % #tools) + 1]
        weaponBtn.Text = _G.SelectedWeapon
    end)

    local autoFrame = Instance.new("Frame", parent)
    autoFrame.Size = UDim2.new(1, -20, 0, 40)
    autoFrame.Position = UDim2.new(0, 10, 0, 175)
    autoFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    Instance.new("UICorner", autoFrame).CornerRadius = UDim.new(0, 6)

    local autoLabel = Instance.new("TextLabel", autoFrame)
    autoLabel.Text = " Auto Execute (HP ≤ " .. KNOCKED_HEALTH_THRESHOLD .. ")"
    autoLabel.Font = Enum.Font.GothamBold
    autoLabel.TextSize = 12
    autoLabel.TextColor3 = Color3.new(1, 1, 1)
    autoLabel.Size = UDim2.new(0.7, 0, 1, 0)
    autoLabel.BackgroundTransparency = 1
    autoLabel.TextXAlignment = Enum.TextXAlignment.Left

    local autoToggleBtn = Instance.new("TextButton", autoFrame)
    autoToggleBtn.Size = UDim2.new(0, 60, 0, 26)
    autoToggleBtn.Position = UDim2.new(1, -70, 0.5, -13)
    autoToggleBtn.Text = _G.AutoExecuteKnocked and "ON" or "OFF"
    autoToggleBtn.Font = Enum.Font.GothamBold
    autoToggleBtn.TextSize = 13
    autoToggleBtn.BackgroundColor3 = _G.AutoExecuteKnocked and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(45, 48, 62)
    autoToggleBtn.TextColor3 = _G.AutoExecuteKnocked and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 180)
    Instance.new("UICorner", autoToggleBtn).CornerRadius = UDim.new(0, 6)

    autoToggleBtn.MouseButton1Click:Connect(function()
        _G.AutoExecuteKnocked = not _G.AutoExecuteKnocked
        if _G.AutoExecuteKnocked then
            autoToggleBtn.Text = "ON"; autoToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255); autoToggleBtn.TextColor3 = Color3.new(1, 1, 1)
        else
            autoToggleBtn.Text = "OFF"; autoToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 62); autoToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end)

    local scroll = Instance.new("ScrollingFrame", parent)
    scroll.Size = UDim2.new(1, -20, 1, -230)
    scroll.Position = UDim2.new(0, 10, 0, 222)
    scroll.BackgroundColor3 = Color3.fromRGB(13, 14, 23)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 120)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)
    local scrollStroke = Instance.new("UIStroke", scroll)
    scrollStroke.Color = Color3.fromRGB(28, 30, 48)
    scrollStroke.Thickness = 1

    local scrollPadding = Instance.new("UIPadding", scroll)
    scrollPadding.PaddingTop = UDim.new(0, 6)
    scrollPadding.PaddingBottom = UDim.new(0, 6)
    scrollPadding.PaddingLeft = UDim.new(0, 6)
    scrollPadding.PaddingRight = UDim.new(0, 6)

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function forceEquip()
        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not char or not hum or not _G.SelectedWeapon then return end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and currentTool.Name == _G.SelectedWeapon then return currentTool end
        local backpack = lp:FindFirstChild("Backpack")
        local targetTool = backpack and backpack:FindFirstChild(_G.SelectedWeapon)
        if targetTool then hum:EquipTool(targetTool); return targetTool end
    end

    local function doToolAttack()
        local tool = forceEquip()
        if tool then pcall(function() tool:Activate() end) end
        local cam = workspace.CurrentCamera
        if cam then
            local vx, vy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(vx, vy, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(vx, vy, 0, false, game, 1)
            end)
        end
    end

    local function doAttack(target)
        if _G.AttackMode == "TOOL" then
            doToolAttack()
        elseif _G.AttackMode == "REMOTE" then
            if _G.SelectedRemote and target then fireAttackRemote(target) end
        elseif _G.AttackMode == "BOTH" then
            doToolAttack()
            if _G.SelectedRemote and target then fireAttackRemote(target) end
        end
    end

    local farmOriginalPos = nil
    local farmLoopThread = nil

    local function startFarmLoop()
        if farmLoopThread then
            pcall(function() task.cancel(farmLoopThread) end)
            farmLoopThread = nil
        end
        farmOriginalPos = nil
        farmLoopThread = task.spawn(function()
            while _G.TargetPlayerToFarm do
                local target = _G.TargetPlayerToFarm
                if not target or not target.Character then task.wait(0.5); continue end
                local tHum = target.Character:FindFirstChild("Humanoid")
                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not (tHum and tHum.Health > 0 and hrp and hum and hum.Health > 0) then
                    _G.TargetPlayerToFarm = nil; break
                end
                if not farmOriginalPos then farmOriginalPos = hrp.CFrame end
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                local stickStart = tick()
                local lastAttack = 0
                while (tick() - stickStart) < _G.FarmStickTime and _G.TargetPlayerToFarm do
                    local curChar = lp.Character
                    local tHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                    local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
                    if not (tHrp and curHrp) then break end
                    local predictedPos = tHrp.Position + (tHrp.AssemblyLinearVelocity * _G.FarmLeadTime)
                    local behindPos = predictedPos - tHrp.CFrame.LookVector * _G.FarmDistance + Vector3.new(0, _G.FarmHeight, 0)
                    pcall(function()
                        curHrp.CFrame = CFrame.lookAt(behindPos, predictedPos)
                        curHrp.AssemblyLinearVelocity = Vector3.zero
                        curHrp.AssemblyAngularVelocity = Vector3.zero
                    end)
                    local now = tick()
                    if (now - lastAttack) >= 0.05 then
                        doAttack(target); lastAttack = now
                    end
                    RunService.Heartbeat:Wait()
                end
                local curHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if curHrp and farmOriginalPos and _G.TargetPlayerToFarm then
                    pcall(function() curHrp.CFrame = farmOriginalPos end)
                end
                local elapsed = 0
                while elapsed < _G.FarmLoopDelay and _G.TargetPlayerToFarm do
                    task.wait(0.1); elapsed = elapsed + 0.1
                end
            end
            farmOriginalPos = nil; farmLoopThread = nil
        end)
    end

    -- Dừng farm: hủy thread, tắt quán tính, khôi phục va chạm chuẩn
    local function stopFarm()
        _G.TargetPlayerToFarm = nil
        if farmLoopThread then
            pcall(function() task.cancel(farmLoopThread) end)
            farmLoopThread = nil
        end
        local char = lp.Character
        farmOriginalPos = nil
        restoreCharacterCollision(char)
        stopCharacterMomentum(char)
    end
    _G._PTH_StopPlayerFarm = stopFarm

    local function TeleportToPlayer(targetPlayer)
        if not targetPlayer then return end
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetHrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and targetHrp then
            pcall(function() hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3) end)
        end
    end

    local isTeleporting = false
    local function TPAndPressV(targetPlayer)
        if isTeleporting or _G.TargetPlayerToFarm or not targetPlayer then return end
        isTeleporting = true
        pcall(function()
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local targetHrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and targetHrp then
                hrp.CFrame = targetHrp.CFrame
                task.wait(0.15)
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.V, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                end)
                task.wait(0.5)
                if hrp.Parent then hrp.CFrame = CFrame.new(returnPos) end
            end
        end)
        task.wait(0.5)
        isTeleporting = false
    end

    local playerCards = {}
    local spectatingTarget = nil

    local function updatePlayerList()
        for _, p in ipairs(PlayersService:GetPlayers()) do
            if p ~= lp then
                local card = playerCards[p.Name]
                if not card then
                    card = Instance.new("Frame", scroll)
                    card.Size = UDim2.new(1, 0, 0, 68)
                    card.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
                    local cardStroke = Instance.new("UIStroke", card)
                    cardStroke.Color = Color3.fromRGB(38, 42, 64)
                    cardStroke.Thickness = 1

                    local nameBtn = Instance.new("TextButton", card)
                    nameBtn.Text = "👤 " .. p.DisplayName .. " (@" .. p.Name .. ")"
                    nameBtn.Font = Enum.Font.GothamBold
                    nameBtn.TextSize = 12
                    nameBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
                    nameBtn.Size = UDim2.new(1, -215, 0, 22)
                    nameBtn.Position = UDim2.new(0, 12, 0, 10)
                    nameBtn.BackgroundTransparency = 1
                    nameBtn.TextXAlignment = Enum.TextXAlignment.Left
                    nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
                    nameBtn.MouseButton1Click:Connect(function()
                        local cam = workspace.CurrentCamera
                        if spectatingTarget == p then
                            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                                cam.CameraSubject = lp.Character:FindFirstChild("Humanoid")
                                cam.CameraType = Enum.CameraType.Custom
                            end
                            spectatingTarget = nil
                        else
                            if p.Character and p.Character:FindFirstChild("Humanoid") then
                                cam.CameraSubject = p.Character:FindFirstChild("Humanoid")
                                cam.CameraType = Enum.CameraType.Custom
                                spectatingTarget = p
                            end
                        end
                    end)

                    local healthLabel = Instance.new("TextLabel", card)
                    healthLabel.Name = "HealthLabel"
                    healthLabel.Font = Enum.Font.GothamMedium
                    healthLabel.TextSize = 12
                    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
                    healthLabel.Size = UDim2.new(1, -215, 0, 20)
                    healthLabel.Position = UDim2.new(0, 12, 0, 36)
                    healthLabel.BackgroundTransparency = 1
                    healthLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local teleBtn = Instance.new("TextButton", card)
                    teleBtn.Name = "TeleBtn"
                    teleBtn.Size = UDim2.new(0, 58, 0, 32)
                    teleBtn.Position = UDim2.new(1, -195, 0.5, -16)
                    teleBtn.Text = "TELE"
                    teleBtn.Font = Enum.Font.GothamBold
                    teleBtn.TextSize = 11
                    teleBtn.BackgroundColor3 = Color3.fromRGB(28, 75, 145)
                    teleBtn.TextColor3 = Color3.new(1, 1, 1)
                    Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 7)
                    teleBtn.MouseButton1Click:Connect(function()
                        task.spawn(function() TeleportToPlayer(p) end)
                    end)

                    local tpBtn = Instance.new("TextButton", card)
                    tpBtn.Name = "TPBtn"
                    tpBtn.Size = UDim2.new(0, 62, 0, 32)
                    tpBtn.Position = UDim2.new(1, -132, 0.5, -16)
                    tpBtn.Text = "TP (V)"
                    tpBtn.Font = Enum.Font.GothamBold
                    tpBtn.TextSize = 11
                    tpBtn.BackgroundColor3 = Color3.fromRGB(115, 45, 175)
                    tpBtn.TextColor3 = Color3.new(1, 1, 1)
                    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 7)
                    tpBtn.MouseButton1Click:Connect(function()
                        if isTeleporting or _G.TargetPlayerToFarm then return end
                        task.spawn(function() TPAndPressV(p) end)
                    end)

                    local farmBtn = Instance.new("TextButton", card)
                    farmBtn.Name = "FarmBtn"
                    farmBtn.Size = UDim2.new(0, 62, 0, 32)
                    farmBtn.Position = UDim2.new(1, -66, 0.5, -16)
                    farmBtn.Text = "FARM"
                    farmBtn.Font = Enum.Font.GothamBold
                    farmBtn.TextSize = 11
                    farmBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
                    farmBtn.TextColor3 = Color3.new(1, 1, 1)
                    Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 7)
                    farmBtn.MouseButton1Click:Connect(function()
                        if _G.TargetPlayerToFarm == p then
                            _G.TargetPlayerToFarm = nil
                            if farmLoopThread then
                                pcall(function() task.cancel(farmLoopThread) end)
                                farmLoopThread = nil
                            end
                            farmOriginalPos = nil
                        else
                            _G.TargetPlayerToFarm = p
                            startFarmLoop()
                        end
                    end)
                    playerCards[p.Name] = card
                end
                local fBtn = card:FindFirstChild("FarmBtn")
                if fBtn then
                    if _G.TargetPlayerToFarm == p then
                        fBtn.Text = "STOP"; fBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                    else
                        fBtn.Text = "FARM"; fBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
                    end
                end
                local healthText = "❤️ Loading..."
                local healthColor = Color3.fromRGB(160, 160, 160)
                if p.Character and p.Character:FindFirstChild("Humanoid") then
                    local hum = p.Character.Humanoid
                    local currentH = math.floor(hum.Health)
                    local maxH = math.floor(hum.MaxHealth)
                    healthText = string.format("❤️ %d / %d", currentH, maxH)
                    local hpPercent = currentH / maxH
                    if hpPercent > 0.6 then healthColor = Color3.fromRGB(0, 255, 120)
                    elseif hpPercent > 0.3 then healthColor = Color3.fromRGB(255, 200, 0)
                    else healthColor = Color3.fromRGB(255, 50, 50) end
                    if _G.AutoExecuteKnocked and currentH > 0 and currentH <= KNOCKED_HEALTH_THRESHOLD and not isTeleporting and not _G.TargetPlayerToFarm then
                        task.spawn(function() TPAndPressV(p) end)
                    end
                end
                card.HealthLabel.Text = healthText
                card.HealthLabel.TextColor3 = healthColor
            end
        end
        for pName, card in pairs(playerCards) do
            if not PlayersService:FindFirstChild(pName) then
                if _G.TargetPlayerToFarm and _G.TargetPlayerToFarm.Name == pName then
                    _G.TargetPlayerToFarm = nil
                    if farmLoopThread then
                        pcall(function() task.cancel(farmLoopThread) end)
                        farmLoopThread = nil
                    end
                    farmOriginalPos = nil
                end
                card:Destroy()
                playerCards[pName] = nil
            end
        end
    end
    task.spawn(function()
        while task.wait(0.25) do
            if not parent.Parent then break end
            pcall(updatePlayerList)
        end
    end)
    updatePlayerList()
end
Features["Farm"] = SetupFarmFeature

-- ============================================================
-- ==================== REMOTE ATTACK V2 ======================
-- ============================================================
local function SetupRemoteFeature(parent)
    local header = Instance.new("TextLabel", parent)
    header.Size = UDim2.new(1, -20, 0, 30)
    header.Position = UDim2.new(0, 10, 0, 48)
    header.Text = "🔌 REMOTE ATTACK V2"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = Color3.fromRGB(0, 255, 200)
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left

    local modeBtn = Instance.new("TextButton", parent)
    modeBtn.Size = UDim2.new(1, -20, 0, 38)
    modeBtn.Position = UDim2.new(0, 10, 0, 88)
    modeBtn.Text = "🎯 Attack Mode: " .. _G.AttackMode
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.TextSize = 14
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    modeBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0,8)

    modeBtn.MouseButton1Click:Connect(function()
        if _G.AttackMode == "TOOL" then _G.AttackMode = "REMOTE"
        elseif _G.AttackMode == "REMOTE" then _G.AttackMode = "BOTH"
        else _G.AttackMode = "TOOL" end
        modeBtn.Text = "🎯 Attack Mode: " .. _G.AttackMode
        if _G.AttackMode == "TOOL" then modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
        elseif _G.AttackMode == "REMOTE" then modeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 200)
        else modeBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 40) end
    end)
    if _G.AttackMode == "REMOTE" then modeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 200)
    elseif _G.AttackMode == "BOTH" then modeBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 40) end

    local snifferHeader = Instance.new("TextLabel", parent)
    snifferHeader.Size = UDim2.new(1, -20, 0, 22)
    snifferHeader.Position = UDim2.new(0, 10, 0, 132)
    snifferHeader.Text = "🔍 REMOTE SNIFFER"
    snifferHeader.Font = Enum.Font.GothamBold
    snifferHeader.TextSize = 14
    snifferHeader.TextColor3 = Color3.fromRGB(255, 200, 100)
    snifferHeader.BackgroundTransparency = 1
    snifferHeader.TextXAlignment = Enum.TextXAlignment.Left

    local sniffBtn = Instance.new("TextButton", parent)
    sniffBtn.Size = UDim2.new(1, -20, 0, 34)
    sniffBtn.Position = UDim2.new(0, 10, 0, 156)
    sniffBtn.Text = "▶  BẬT SNIFFER"
    sniffBtn.Font = Enum.Font.GothamBold
    sniffBtn.TextSize = 14
    sniffBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 100)
    sniffBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", sniffBtn).CornerRadius = UDim.new(0,8)

    sniffBtn.MouseButton1Click:Connect(function()
        if _G.SnifferActive then
            _G.SnifferActive = false
            sniffBtn.Text = "▶  BẬT SNIFFER"
            sniffBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 100)
        else
            local ok, err = startSniffer()
            if ok then
                _G.SnifferActive = true
                sniffBtn.Text = "⏹  TẮT SNIFFER"
                sniffBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            else
                sniffBtn.Text = "❌ " .. tostring(err)
                task.wait(2)
                sniffBtn.Text = "▶  BẬT SNIFFER"
            end
        end
    end)

    local selHeader = Instance.new("TextLabel", parent)
    selHeader.Size = UDim2.new(1, -20, 0, 22)
    selHeader.Position = UDim2.new(0, 10, 0, 198)
    selHeader.Text = "🎯 SELECTED: " .. (_G.SelectedRemoteName or "NONE")
    selHeader.Font = Enum.Font.GothamBold
    selHeader.TextSize = 13
    selHeader.TextColor3 = Color3.fromRGB(0, 255, 200)
    selHeader.BackgroundTransparency = 1
    selHeader.TextXAlignment = Enum.TextXAlignment.Left

    local previewHeader = Instance.new("TextLabel", parent)
    previewHeader.Size = UDim2.new(1, -20, 0, 20)
    previewHeader.Position = UDim2.new(0, 10, 0, 224)
    previewHeader.Text = "👁 ARGS THỰC TẾ ĐÃ BẮT ĐƯỢC:"
    previewHeader.Font = Enum.Font.GothamBold
    previewHeader.TextSize = 12
    previewHeader.TextColor3 = Color3.fromRGB(255, 200, 100)
    previewHeader.BackgroundTransparency = 1
    previewHeader.TextXAlignment = Enum.TextXAlignment.Left

    local previewBox = Instance.new("ScrollingFrame", parent)
    previewBox.Size = UDim2.new(1, -20, 0, 80)
    previewBox.Position = UDim2.new(0, 10, 0, 246)
    previewBox.BackgroundColor3 = Color3.fromRGB(15, 25, 15)
    previewBox.BorderSizePixel = 0
    previewBox.ScrollBarThickness = 4
    previewBox.CanvasSize = UDim2.new(0, 0, 0, 0)
    previewBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", previewBox).CornerRadius = UDim.new(0, 6)

    local previewText = Instance.new("TextLabel", previewBox)
    previewText.Size = UDim2.new(1, -10, 0, 0)
    previewText.Position = UDim2.new(0, 5, 0, 4)
    previewText.AutomaticSize = Enum.AutomaticSize.Y
    previewText.Text = "(Chọn 1 remote bên dưới để xem args)"
    previewText.Font = Enum.Font.Code
    previewText.TextSize = 11
    previewText.TextColor3 = Color3.fromRGB(0, 255, 150)
    previewText.BackgroundTransparency = 1
    previewText.TextXAlignment = Enum.TextXAlignment.Left
    previewText.TextYAlignment = Enum.TextYAlignment.Top
    previewText.TextWrapped = true

    local function typeofArg(a)
        if a == nil then return "nil" end
        if type(a) == "string" then return string.format('string: "%s"', a) end
        if type(a) == "number" then return "number: " .. tostring(a) end
        if type(a) == "boolean" then return "bool: " .. tostring(a) end
        if type(a) == "table" then
            local parts = {}
            for k, v in pairs(a) do
                if #parts >= 5 then parts[#parts+1] = "..."; break end
                parts[#parts+1] = tostring(k) .. "=" .. (type(v) == "Instance" and v.Name or tostring(v))
            end
            return "table {" .. table.concat(parts, ", ") .. "}"
        end
        if typeof(a) == "Instance" then
            return string.format("Instance: %s (%s)", a.Name, a.ClassName)
        end
        if typeof(a) == "Vector3" then
            return string.format("Vector3(%d, %d, %d)", a.X, a.Y, a.Z)
        end
        if typeof(a) == "CFrame" then
            return "CFrame"
        end
        return typeof(a) .. ": " .. tostring(a)
    end

    local function updatePreview()
        if not _G.SelectedRemote then
            previewText.Text = "(Chọn 1 remote bên dưới để xem args)"
            return
        end
        local info = nil
        if _G.SelectedRemoteName and _G.DetectedRemotes[_G.SelectedRemoteName] then
            info = _G.DetectedRemotes[_G.SelectedRemoteName]
        else
            for _, v in pairs(_G.DetectedRemotes) do
                if v.remote == _G.SelectedRemote then info = v; break end
            end
        end
        if not info or not info.lastArgs then
            previewText.Text = "(Chưa bắt được args — đánh thủ công lại)"
            return
        end
        local lines = {"Tổng số args: " .. (info.argCount or #info.lastArgs), ""}
        for i, a in ipairs(info.lastArgs) do
            lines[#lines+1] = string.format("[%d] %s", i, typeofArg(a))
        end
        previewText.Text = table.concat(lines, "\n")
    end

    local argBtn = Instance.new("TextButton", parent)
    argBtn.Size = UDim2.new(1, -20, 0, 34)
    argBtn.Position = UDim2.new(0, 10, 0, 332)
    argBtn.Text = "📦 Args: " .. (ARG_MODE_NAMES[_G.RemoteArgMode] or "Target Player")
    argBtn.Font = Enum.Font.GothamBold
    argBtn.TextSize = 13
    argBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
    argBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", argBtn).CornerRadius = UDim.new(0,8)

    argBtn.MouseButton1Click:Connect(function()
        _G.RemoteArgMode = (_G.RemoteArgMode % 11) + 1
        argBtn.Text = "📦 Args: " .. (ARG_MODE_NAMES[_G.RemoteArgMode] or "Target Player")
    end)

    local actionRow = Instance.new("Frame", parent)
    actionRow.Size = UDim2.new(1, -20, 0, 32)
    actionRow.Position = UDim2.new(0, 10, 0, 372)
    actionRow.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    Instance.new("UICorner", actionRow).CornerRadius = UDim.new(0, 6)

    local actionLbl = Instance.new("TextLabel", actionRow)
    actionLbl.Text = "Action str:"
    actionLbl.Font = Enum.Font.GothamBold
    actionLbl.TextSize = 12
    actionLbl.TextColor3 = Color3.fromRGB(200, 200, 255)
    actionLbl.Size = UDim2.new(0.35, 0, 1, 0)
    actionLbl.BackgroundTransparency = 1
    actionLbl.TextXAlignment = Enum.TextXAlignment.Left

    local actionBox = Instance.new("TextBox", actionRow)
    actionBox.Size = UDim2.new(0.63, 0, 0, 24)
    actionBox.Position = UDim2.new(0.35, 0, 0.5, -12)
    actionBox.Text = _G.RemoteActionString or "Combat"
    actionBox.PlaceholderText = "vd: Combat / Attack / Hit"
    actionBox.Font = Enum.Font.GothamBold
    actionBox.TextSize = 12
    actionBox.TextColor3 = Color3.fromRGB(0, 255, 200)
    actionBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    actionBox.ClearTextOnFocus = false
    Instance.new("UICorner", actionBox).CornerRadius = UDim.new(0, 6)
    actionBox.FocusLost:Connect(function()
        _G.RemoteActionString = actionBox.Text
    end)

    local listHeader = Instance.new("TextLabel", parent)
    listHeader.Size = UDim2.new(1, -20, 0, 22)
    listHeader.Position = UDim2.new(0, 10, 0, 410)
    listHeader.Text = "📋 DETECTED REMOTES (click để chọn)"
    listHeader.Font = Enum.Font.GothamBold
    listHeader.TextSize = 12
    listHeader.TextColor3 = Color3.fromRGB(200,200,255)
    listHeader.BackgroundTransparency = 1
    listHeader.TextXAlignment = Enum.TextXAlignment.Left

    local refreshBtn = Instance.new("TextButton", parent)
    refreshBtn.Size = UDim2.new(0, 80, 0, 24)
    refreshBtn.Position = UDim2.new(1, -90, 0, 410)
    refreshBtn.Text = "REFRESH"
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 11
    refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    refreshBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0,6)

    local clearBtn = Instance.new("TextButton", parent)
    clearBtn.Size = UDim2.new(0, 60, 0, 24)
    clearBtn.Position = UDim2.new(1, -175, 0, 410)
    clearBtn.Text = "CLEAR"
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 11
    clearBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
    clearBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0,6)

    local remoteScroll = Instance.new("ScrollingFrame", parent)
    remoteScroll.Size = UDim2.new(1, -20, 0, 220)
    remoteScroll.Position = UDim2.new(0, 10, 0, 438)
    remoteScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    remoteScroll.BorderSizePixel = 0
    remoteScroll.ScrollBarThickness = 4
    remoteScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    remoteScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", remoteScroll).CornerRadius = UDim.new(0, 6)
    local rl = Instance.new("UIListLayout", remoteScroll)
    rl.Padding = UDim.new(0, 4)
    rl.SortOrder = Enum.SortOrder.LayoutOrder

    local onlyAttackFilter = false
    local filterBtn = Instance.new("TextButton", parent)
    filterBtn.Size = UDim2.new(0, 105, 0, 24)
    filterBtn.Position = UDim2.new(1, -285, 0, 410)
    filterBtn.Text = "⚔️ CHỈ ĐÒN ĐÁNH"
    filterBtn.Font = Enum.Font.GothamBold
    filterBtn.TextSize = 10
    filterBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    filterBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Instance.new("UICorner", filterBtn).CornerRadius = UDim.new(0, 6)

    filterBtn.MouseButton1Click:Connect(function()
        onlyAttackFilter = not onlyAttackFilter
        filterBtn.BackgroundColor3 = onlyAttackFilter and Color3.fromRGB(180, 50, 70) or Color3.fromRGB(50, 50, 75)
        filterBtn.TextColor3 = onlyAttackFilter and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200)
        refreshRemoteList()
    end)

    local function refreshRemoteList()
        for _, c in ipairs(remoteScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
        end
        local list = {}
        for key, info in pairs(_G.DetectedRemotes) do
            if not onlyAttackFilter or info.isAttack then
                table.insert(list, {key = key, info = info})
            end
        end
        table.sort(list, function(a, b)
            if a.info.isAttack and not b.info.isAttack then return true end
            if not a.info.isAttack and b.info.isAttack then return false end
            return a.info.count > b.info.count
        end)

        if #list == 0 then
            local empty = Instance.new("TextLabel", remoteScroll)
            empty.Size = UDim2.new(1, -10, 0, 30)
            empty.Text = onlyAttackFilter and "Chưa bắt được action đòn đánh nào (hãy đấm quái 1 cái)" or "Chưa phát hiện remote nào"
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextColor3 = Color3.fromRGB(150,150,150)
            empty.BackgroundTransparency = 1
            return
        end

        for _, entry in ipairs(list) do
            local info = entry.info
            local isSelected = (_G.SelectedRemote == info.remote and _G.SelectedRemoteName == entry.key)
            local btn = Instance.new("TextButton", remoteScroll)
            btn.Size = UDim2.new(1, -6, 0, 32)
            local icon = info.isAttack and "⚔️ " or "📡 "
            local displayName = (info.action ~= "" and (info.remote.Name .. " [" .. info.action .. "]") or info.remote.Name)
            btn.Text = string.format("%s%s (%d) args=%d", icon, displayName, info.count, info.argCount)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.TextColor3 = Color3.new(1,1,1)
            btn.BackgroundColor3 = isSelected and Color3.fromRGB(0,160,70) or (info.isAttack and Color3.fromRGB(65, 30, 85) or Color3.fromRGB(35, 38, 52))
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

            btn.MouseButton1Click:Connect(function()
                _G.SelectedRemote = info.remote
                _G.SelectedRemoteName = entry.key
                _G.RemoteCapturedArgs = info.lastArgs
                _G._PTH_ManualSelected = true
                if info.action ~= "" then _G.RemoteActionString = info.action end
                selHeader.Text = "🎯 SELECTED: " .. entry.key
                updatePreview()
                refreshRemoteList()
            end)
        end
        remoteScroll.CanvasSize = UDim2.new(0, 0, 0, rl.AbsoluteContentSize.Y + 8)
    end

    refreshBtn.MouseButton1Click:Connect(refreshRemoteList)
    clearBtn.MouseButton1Click:Connect(function()
        _G.DetectedRemotes = {}
        _G.SelectedRemote = nil
        _G.SelectedRemoteName = nil
        selHeader.Text = "🎯 SELECTED: NONE"
        updatePreview()
        refreshRemoteList()
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if not parent.Parent then break end
            pcall(refreshRemoteList)
            pcall(updatePreview)
        end
    end)

    local scanBtn = Instance.new("TextButton", parent)
    scanBtn.Size = UDim2.new(0.48, -10, 0, 38)
    scanBtn.Position = UDim2.new(0, 10, 0, 666)
    scanBtn.Text = "🔎 AUTO TÌM REMOTE"
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 12
    scanBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 180)
    scanBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0,8)

    local function autoFindAttackRemote()
        local candidates = {}
        local keywords = {"combat", "punch", "hit", "attack", "damage", "slash", "swing", "weapon", "m1", "melee", "skill"}

        local function checkRemote(obj)
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local oName = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if string.find(oName, kw, 1, true) then
                        table.insert(candidates, obj)
                        break
                    end
                end
            end
        end

        pcall(function()
            for _, d in ipairs(ReplicatedStorage:GetDescendants()) do checkRemote(d) end
        end)
        pcall(function()
            local char = lp.Character
            if char then
                for _, d in ipairs(char:GetDescendants()) do checkRemote(d) end
            end
            local bp = lp:FindFirstChild("Backpack")
            if bp then
                for _, d in ipairs(bp:GetDescendants()) do checkRemote(d) end
            end
        end)

        if #candidates > 0 then
            local chosen = candidates[1]
            _G.SelectedRemote = chosen
            _G.SelectedRemoteName = chosen:GetFullName()
            selHeader.Text = "🎯 SELECTED: " .. chosen:GetFullName()
            _G.DetectedRemotes = _G.DetectedRemotes or {}
            _G.DetectedRemotes[chosen:GetFullName()] = {
                remote = chosen,
                count = 1,
                argCount = 1,
                method = chosen:IsA("RemoteEvent") and "FireServer" or "InvokeServer"
            }
            refreshRemoteList()
            updatePreview()
            return chosen
        end
        return nil
    end
    _G._PTH_AutoFindAttackRemote = autoFindAttackRemote

    scanBtn.MouseButton1Click:Connect(function()
        scanBtn.Text = "Đang quét..."
        local found = autoFindAttackRemote()
        if found then
            scanBtn.Text = "✅ Đã tìm thấy: " .. found.Name
        else
            scanBtn.Text = "❌ Hãy bật Sniffer & đánh 1 cái!"
        end
        task.wait(2)
        scanBtn.Text = "🔎 AUTO TÌM REMOTE"
    end)

    local testBtn = Instance.new("TextButton", parent)
    testBtn.Size = UDim2.new(0.48, -10, 0, 38)
    testBtn.Position = UDim2.new(0.52, 0, 0, 666)
    testBtn.Text = "⚡ TEST FIRE (mục tiêu)"
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    testBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0,8)

    testBtn.MouseButton1Click:Connect(function()
        if not _G.SelectedRemote then
            testBtn.Text = "❌ Chưa chọn remote!"
            task.wait(1.5); testBtn.Text = "⚡ TEST FIRE (vào người gần nhất)"; return
        end
        local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local nearest, nd, isBoss = nil, math.huge, false

        -- 1. Ưu tiên tìm Boss / Quái sống gần nhất trong phạm vi
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not PlayersService:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local r = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
                    if r and myRoot then
                        local d = (r.Position - myRoot.Position).Magnitude
                        if d < nd then nearest = obj; nd = d; isBoss = true end
                    end
                end
            end
        end

        -- 2. Nếu không có quái/boss xung quanh, tìm Player gần nhất
        if not nearest then
            for _, p in ipairs(PlayersService:GetPlayers()) do
                if p ~= lp and p.Character then
                    local r = p.Character:FindFirstChild("HumanoidRootPart")
                    if r and myRoot then
                        local d = (r.Position - myRoot.Position).Magnitude
                        if d < nd then nearest = p; nd = d; isBoss = false end
                    end
                end
            end
        end

        if nearest then
            fireAttackRemote(nearest)
            testBtn.Text = "✅ Đã test fire: " .. nearest.Name .. " (" .. math.floor(nd) .. "m)"
        else
            testBtn.Text = "❌ Không có mục tiêu gần!"
        end
        task.wait(1.5)
        testBtn.Text = "⚡ TEST FIRE (mục tiêu)"
    end)

    updatePreview()
end
Features["Remote"] = SetupRemoteFeature

-- ============================================================
-- ==================== ESP PLAYER & BOSS FEATURE =============
-- ============================================================
_G.ESPPlayer = _G.ESPPlayer or false
_G.ESPBoss   = _G.ESPBoss or false

local BOSS_CONFIG = {
    ["Wooden Golem"]        = true,
    ["Tairock"]             = true,
    ["Chakra Knight"]       = true,
    ["Lavarossa"]           = true,
    ["Barbarit The Rose"]   = true,
    ["The Ringed Samurai"]  = true,
    ["Lava Snake"]          = true,
    ["Hyuga Boss"]          = true,
    ["Haku Boss"]           = true,
    ["Matatabi"]            = true,
    ["Shukaku"]             = true,
}
_G.SelectedBosses = _G.SelectedBosses or BOSS_CONFIG

local function SetupESPFeature(parent)
    local header = Instance.new("TextLabel", parent)
    header.Size = UDim2.new(1, -20, 0, 28)
    header.Position = UDim2.new(0, 10, 0, 8)
    header.Text = "👁️ ESP RADAR (PLAYER & BOSS)"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 16
    header.TextColor3 = Color3.fromRGB(0, 255, 200)
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left

    -- Nút Toggle Player ESP
    local pToggleBtn = Instance.new("TextButton", parent)
    pToggleBtn.Size = UDim2.new(0.5, -15, 0, 36)
    pToggleBtn.Position = UDim2.new(0, 10, 0, 42)
    pToggleBtn.Text = "PLAYER ESP: " .. (_G.ESPPlayer and "ON" or "OFF")
    pToggleBtn.Font = Enum.Font.GothamBold
    pToggleBtn.TextSize = 12
    pToggleBtn.BackgroundColor3 = _G.ESPPlayer and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(35, 38, 55)
    pToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", pToggleBtn).CornerRadius = UDim.new(0, 8)

    -- Nút Toggle Boss ESP
    local bToggleBtn = Instance.new("TextButton", parent)
    bToggleBtn.Size = UDim2.new(0.5, -15, 0, 36)
    bToggleBtn.Position = UDim2.new(0.5, 5, 0, 42)
    bToggleBtn.Text = "BOSS ESP: " .. (_G.ESPBoss and "ON" or "OFF")
    bToggleBtn.Font = Enum.Font.GothamBold
    bToggleBtn.TextSize = 12
    bToggleBtn.BackgroundColor3 = _G.ESPBoss and Color3.fromRGB(150, 60, 230) or Color3.fromRGB(35, 38, 55)
    bToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", bToggleBtn).CornerRadius = UDim.new(0, 8)

    local bossListHeader = Instance.new("TextLabel", parent)
    bossListHeader.Size = UDim2.new(1, -20, 0, 22)
    bossListHeader.Position = UDim2.new(0, 10, 0, 86)
    bossListHeader.Text = "👾 DANH SÁCH BOSS THEO DÕI (Click để bật/tắt):"
    bossListHeader.Font = Enum.Font.GothamBold
    bossListHeader.TextSize = 12
    bossListHeader.TextColor3 = Color3.fromRGB(200, 210, 255)
    bossListHeader.BackgroundTransparency = 1
    bossListHeader.TextXAlignment = Enum.TextXAlignment.Left

    local bossScroll = Instance.new("ScrollingFrame", parent)
    bossScroll.Size = UDim2.new(1, -20, 0, 280)
    bossScroll.Position = UDim2.new(0, 10, 0, 112)
    bossScroll.BackgroundColor3 = Color3.fromRGB(13, 14, 23)
    bossScroll.BorderSizePixel = 0
    bossScroll.ScrollBarThickness = 3
    bossScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 120)
    bossScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    bossScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", bossScroll).CornerRadius = UDim.new(0, 10)
    local bsStroke = Instance.new("UIStroke", bossScroll)
    bsStroke.Color = Color3.fromRGB(28, 30, 48)

    local bsPadding = Instance.new("UIPadding", bossScroll)
    bsPadding.PaddingTop = UDim.new(0, 6)
    bsPadding.PaddingBottom = UDim.new(0, 6)
    bsPadding.PaddingLeft = UDim.new(0, 6)
    bsPadding.PaddingRight = UDim.new(0, 6)

    local bsLayout = Instance.new("UIListLayout", bossScroll)
    bsLayout.Padding = UDim.new(0, 5)
    bsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local BOSS_NAMES_ORDER = {
        "Wooden Golem", "Tairock", "Chakra Knight", "Lavarossa",
        "Barbarit The Rose", "The Ringed Samurai", "Lava Snake",
        "Hyuga Boss", "Haku Boss", "Matatabi", "Shukaku"
    }

    _G._PTH_Boss_LastPositions = _G._PTH_Boss_LastPositions or {}
    _G.TargetBossToFarm = nil
    local bossFarmThread = nil
    local bossFarmOriginalPos = nil
    local bossFarmButtons = {}

    local function getBossModel(bName)
        local bLower = bName:lower()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not PlayersService:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and string.find(obj.Name:lower(), bLower, 1, true) then
                    local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
                    if part then
                        return obj, part, hum
                    end
                end
            end
        end
        return nil, nil, nil
    end

    local bossFarmSteppedConn = nil
    local bossFarmHeartbeatConn = nil
    local isBossDodging = false
    local lastDodgeTime = 0

    local function stopBossFarm()
        _G.TargetBossToFarm = nil
        if bossFarmThread then
            pcall(function() task.cancel(bossFarmThread) end)
            bossFarmThread = nil
        end
        if bossFarmSteppedConn then
            pcall(function() bossFarmSteppedConn:Disconnect() end)
            bossFarmSteppedConn = nil
        end
        if bossFarmHeartbeatConn then
            pcall(function() bossFarmHeartbeatConn:Disconnect() end)
            bossFarmHeartbeatConn = nil
        end

        local char = lp.Character
        bossFarmOriginalPos = nil
        isBossDodging = false
        restoreCharacterCollision(char)
        stopCharacterMomentum(char)
        for _, btn in pairs(bossFarmButtons) do
            btn.Text = "FARM"
            btn.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
        end
    end
    _G._PTH_StopBossFarm = stopBossFarm

    local function startBossFarm(bName)
        stopBossFarm()
        _G.TargetBossToFarm = bName

        for name, btn in pairs(bossFarmButtons) do
            if name == bName then
                btn.Text = "STOP"
                btn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
            else
                btn.Text = "FARM"
                btn.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
            end
        end

        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then bossFarmOriginalPos = hrp.CFrame end

        -- 1. Stepped: Noclip liên tục mỗi physics frame chống kẹt/va chạm
        bossFarmSteppedConn = RunService.Stepped:Connect(function()
            if not _G.TargetBossToFarm then return end
            local curChar = lp.Character
            if curChar then
                for _, part in ipairs(curChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)

        -- 2. Heartbeat: Giữ vị trí mượt mà không bị giật rung do trọng lực Roblox
        local targetHoverCFrame = nil
        bossFarmHeartbeatConn = RunService.Heartbeat:Connect(function()
            if not _G.TargetBossToFarm or not targetHoverCFrame then return end
            local curChar = lp.Character
            local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
            if curHrp then
                curHrp.AssemblyLinearVelocity = Vector3.zero
                curHrp.AssemblyAngularVelocity = Vector3.zero
                curHrp.CFrame = targetHoverCFrame
            end
        end)

        -- 3. Vòng lặp logic: Tấn công + Kiểm tra chiêu thức của Boss để né lên cao
        bossFarmThread = task.spawn(function()
            while _G.TargetBossToFarm == bName do
                local curChar = lp.Character
                local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
                local curHum = curChar and curChar:FindFirstChildOfClass("Humanoid")

                if not (curHrp and curHum and curHum.Health > 0) then
                    targetHoverCFrame = nil
                    task.wait(1)
                    continue
                end

                local bModel, bPart, bHum = getBossModel(bName)

                if bModel and bPart and bHum and bHum.Health > 0 then
                    -- Kiểm tra xem Boss có đang tung chiêu / kích hoạt Animation đánh không
                    local bossIsAttacking = false
                    local bAnimator = bHum:FindFirstChildOfClass("Animator")
                    if bAnimator then
                        for _, track in ipairs(bAnimator:GetPlayingAnimationTracks()) do
                            if track.IsPlaying and track.WeightCurrent > 0.1 and track.Speed > 0.05 then
                                bossIsAttacking = true
                                break
                            end
                        end
                    end

                    -- Kiểm tra hitbox/vũ khí/effect của boss đang vung ra
                    if not bossIsAttacking then
                        for _, d in ipairs(bModel:GetChildren()) do
                            if (d:IsA("Tool") or d.Name:lower():find("skill") or d.Name:lower():find("hitbox") or d.Name:lower():find("attack")) then
                                bossIsAttacking = true
                                break
                            end
                        end
                    end

                    -- Chiều cao an toàn: Bình thường 8 studs. Khi quái ra chiêu, tele né vọt lên 18 studs!
                    local normalHeight = 8.5
                    local dodgeHeight = 18.0
                    local currentHeight = normalHeight

                    if bossIsAttacking then
                        currentHeight = dodgeHeight
                        lastDodgeTime = tick()
                    elseif (tick() - lastDodgeTime) < 1.2 then
                        currentHeight = dodgeHeight -- Giữ độ cao thêm 1.2s để hitbox chiêu tan hẳn
                    end

                    -- Cố định góc nhìn nhìn thẳng xuống Boss, không bị xoay tròn giật hình
                    targetHoverCFrame = CFrame.new(bPart.Position + Vector3.new(0, currentHeight, 0), bPart.Position)

                    -- Tự động tìm remote đánh nếu người dùng chưa chọn
                    if not _G.SelectedRemote and _G._PTH_AutoFindAttackRemote then
                        pcall(_G._PTH_AutoFindAttackRemote)
                    end

                    -- Tấn công bằng Remote
                    if _G.SelectedRemote then
                        pcall(function()
                            fireAttackRemote(bModel)
                        end)
                    end

                    -- Tự trang bị vũ khí nếu có chọn weapon trong tab Farm
                    if _G.SelectedWeapon and curHum then
                        local currentTool = curChar:FindFirstChildOfClass("Tool")
                        if not currentTool or currentTool.Name ~= _G.SelectedWeapon then
                            local bp = lp:FindFirstChild("Backpack")
                            local targetTool = bp and bp:FindFirstChild(_G.SelectedWeapon)
                            if targetTool then curHum:EquipTool(targetTool) end
                        end
                    end

                    -- Click / Tool Attack
                    local cam = workspace.CurrentCamera
                    if cam then
                        local vx, vy = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(vx, vy, 0, true, game, 1)
                            VirtualInputManager:SendMouseButtonEvent(vx, vy, 0, false, game, 1)
                        end)
                    end
                    task.wait(0.08)
                else
                    -- Boss chưa spawn hoặc vừa chết: hạ target CFrame và đợi ở điểm spawn
                    targetHoverCFrame = nil
                    TeleportToBoss(bName)
                    task.wait(1)
                end
            end
            stopBossFarm()
        end)
    end

    local function TeleportToBoss(bName)
        local myChar = lp.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end

        local targetCFrame = nil
        local bLower = bName:lower()

        -- 1. Tìm boss sống trực tiếp trong Workspace
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not PlayersService:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and string.find(obj.Name:lower(), bLower, 1, true) then
                    local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
                    if part then
                        targetCFrame = part.CFrame * CFrame.new(0, 3, 5)
                        _G._PTH_Boss_LastPositions[bName] = targetCFrame
                        break
                    end
                end
            end
        end

        -- 2. Nếu boss chưa spawn hoặc đang chết, tìm Spawn/Pad/Zone/Arena liên quan đến Boss trong Workspace
        if not targetCFrame then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local oName = obj.Name:lower()
                if string.find(oName, bLower, 1, true) then
                    if obj:IsA("BasePart") then
                        targetCFrame = obj.CFrame * CFrame.new(0, 3, 0)
                        break
                    elseif obj:IsA("Model") then
                        local part = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                        if part then
                            targetCFrame = part.CFrame * CFrame.new(0, 3, 0)
                            break
                        end
                    end
                end
            end
        end

        -- 3. Nếu vẫn chưa thấy, dùng tọa độ đã lưu (Last Known Position) từ lần xuất hiện gần nhất
        if not targetCFrame and _G._PTH_Boss_LastPositions[bName] then
            targetCFrame = _G._PTH_Boss_LastPositions[bName]
        end

        -- Thực hiện dịch chuyển nếu tìm được vị trí
        if targetCFrame then
            pcall(function()
                myHrp.CFrame = targetCFrame
                myHrp.AssemblyLinearVelocity = Vector3.zero
            end)
        end
    end

    for _, bName in ipairs(BOSS_NAMES_ORDER) do
        local bRow = Instance.new("Frame", bossScroll)
        bRow.Size = UDim2.new(1, 0, 0, 38)
        bRow.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
        Instance.new("UICorner", bRow).CornerRadius = UDim.new(0, 8)
        local rStroke = Instance.new("UIStroke", bRow)
        rStroke.Color = Color3.fromRGB(32, 35, 52)

        local bLbl = Instance.new("TextLabel", bRow)
        bLbl.Size = UDim2.new(1, -170, 1, 0)
        bLbl.Position = UDim2.new(0, 10, 0, 0)
        bLbl.Text = bName
        bLbl.Font = Enum.Font.GothamMedium
        bLbl.TextSize = 12
        bLbl.TextColor3 = Color3.fromRGB(230, 235, 255)
        bLbl.BackgroundTransparency = 1
        bLbl.TextXAlignment = Enum.TextXAlignment.Left
        bLbl.TextTruncate = Enum.TextTruncate.AtEnd

        local teleBossBtn = Instance.new("TextButton", bRow)
        teleBossBtn.Size = UDim2.new(0, 48, 0, 26)
        teleBossBtn.Position = UDim2.new(1, -145, 0.5, -13)
        teleBossBtn.Text = "TELE"
        teleBossBtn.Font = Enum.Font.GothamBold
        teleBossBtn.TextSize = 10
        teleBossBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 150)
        teleBossBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", teleBossBtn).CornerRadius = UDim.new(0, 6)
        teleBossBtn.MouseButton1Click:Connect(function()
            task.spawn(function() TeleportToBoss(bName) end)
        end)

        local farmBossBtn = Instance.new("TextButton", bRow)
        farmBossBtn.Size = UDim2.new(0, 52, 0, 26)
        farmBossBtn.Position = UDim2.new(1, -92, 0.5, -13)
        farmBossBtn.Text = (_G.TargetBossToFarm == bName) and "STOP" or "FARM"
        farmBossBtn.Font = Enum.Font.GothamBold
        farmBossBtn.TextSize = 10
        farmBossBtn.BackgroundColor3 = (_G.TargetBossToFarm == bName) and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(220, 50, 70)
        farmBossBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", farmBossBtn).CornerRadius = UDim.new(0, 6)
        bossFarmButtons[bName] = farmBossBtn

        farmBossBtn.MouseButton1Click:Connect(function()
            if _G.TargetBossToFarm == bName then
                stopBossFarm()
            else
                startBossFarm(bName)
            end
        end)

        local checkBtn = Instance.new("TextButton", bRow)
        checkBtn.Size = UDim2.new(0, 28, 0, 26)
        checkBtn.Position = UDim2.new(1, -34, 0.5, -13)
        local isChecked = (_G.SelectedBosses[bName] ~= false)
        checkBtn.Text = isChecked and "✓" or ""
        checkBtn.Font = Enum.Font.GothamBold
        checkBtn.TextSize = 14
        checkBtn.BackgroundColor3 = isChecked and Color3.fromRGB(130, 60, 230) or Color3.fromRGB(35, 38, 55)
        checkBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0, 6)

        checkBtn.MouseButton1Click:Connect(function()
            local nowState = not (_G.SelectedBosses[bName] ~= false)
            _G.SelectedBosses[bName] = nowState
            checkBtn.Text = nowState and "✓" or ""
            checkBtn.BackgroundColor3 = nowState and Color3.fromRGB(130, 60, 230) or Color3.fromRGB(35, 38, 55)
        end)
    end

    pToggleBtn.MouseButton1Click:Connect(function()
        _G.ESPPlayer = not _G.ESPPlayer
        pToggleBtn.Text = "PLAYER ESP: " .. (_G.ESPPlayer and "ON" or "OFF")
        pToggleBtn.BackgroundColor3 = _G.ESPPlayer and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(35, 38, 55)
    end)

    bToggleBtn.MouseButton1Click:Connect(function()
        _G.ESPBoss = not _G.ESPBoss
        bToggleBtn.Text = "BOSS ESP: " .. (_G.ESPBoss and "ON" or "OFF")
        bToggleBtn.BackgroundColor3 = _G.ESPBoss and Color3.fromRGB(150, 60, 230) or Color3.fromRGB(35, 38, 55)
    end)

    local function getRoot(p)
        local c = p.Character
        if not c then return nil end
        return c:FindFirstChild("HumanoidRootPart")
    end

    local function getHealth(p)
        local c = p.Character
        if not c then return 0,0 end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then return 0,0 end
        return math.floor(h.Health), math.floor(h.MaxHealth)
    end

    local function getChakra(p)
        local c = p.Character
        if c then
            for _, name in ipairs({"Chakra","Mana","Energy","Stamina","Nội Lực"}) do
                local v = c:FindFirstChild(name)
                if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                    local mx = v:FindFirstChild("MaxValue")
                    return math.floor(v.Value), math.floor(mx and mx.Value or v.Value)
                end
            end
        end
        local ls = p:FindFirstChild("leaderstats")
        if ls then
            for _, name in ipairs({"Chakra","Mana","Energy","Nội Lực"}) do
                local v = ls:FindFirstChild(name)
                if v then return math.floor(v.Value), 100 end
            end
        end
        local ca = p:GetAttribute("Chakra")
        if ca then return math.floor(ca), math.floor(p:GetAttribute("MaxChakra") or 100) end
        return 0, 0
    end

    local bloodlineCache = {}
    local bloodlineCacheTime = {}
    local CACHE_TIME = 1.5

    local function nameMatchesBloodline(n)
        if not n then return false end
        local l = n:lower()
        return l:find("blood") or l:find("huyết") or l:find("huyet")
            or l == "bl" or l == "blname" or l == "bl_name"
    end

    local function isValidBloodline(val)
        if val == nil then return false end
        local s = tostring(val)
        if s == "" or s == "0" or s == "nil" then return false end
        return true
    end

    local function getBloodline(p)
        local now = tick()
        if bloodlineCache[p] and bloodlineCacheTime[p] and (now - bloodlineCacheTime[p]) < CACHE_TIME then
            return bloodlineCache[p]
        end
        local result = nil
        local ok, attrs = pcall(function() return p:GetAttributes() end)
        if ok and attrs then
            for name, value in pairs(attrs) do
                if nameMatchesBloodline(name) and isValidBloodline(value) then
                    result = tostring(value); break
                end
            end
        end
        if not result then
            local ls = p:FindFirstChild("leaderstats")
            if ls then
                for _, v in ipairs(ls:GetChildren()) do
                    if nameMatchesBloodline(v.Name) and isValidBloodline(v.Value) then
                        result = tostring(v.Value); break
                    end
                end
            end
        end
        if not result then
            for _, v in ipairs(p:GetChildren()) do
                if (v:IsA("StringValue") or v:IsA("NumberValue") or v:IsA("IntValue"))
                   and nameMatchesBloodline(v.Name) and isValidBloodline(v.Value) then
                    result = tostring(v.Value); break
                end
            end
        end
        if not result and p.Character then
            local ok2, cAttrs = pcall(function() return p.Character:GetAttributes() end)
            if ok2 and cAttrs then
                for name, value in pairs(cAttrs) do
                    if nameMatchesBloodline(name) and isValidBloodline(value) then
                        result = tostring(value); break
                    end
                end
            end
            if not result then
                for _, v in ipairs(p.Character:GetChildren()) do
                    if (v:IsA("StringValue") or v:IsA("NumberValue") or v:IsA("IntValue"))
                       and nameMatchesBloodline(v.Name) and isValidBloodline(v.Value) then
                        result = tostring(v.Value); break
                    end
                end
            end
        end
        result = result or "Unknown"
        bloodlineCache[p] = result
        bloodlineCacheTime[p] = now
        return result
    end

    _G._PTH_ESP_Objects = _G._PTH_ESP_Objects or {}
    _G._PTH_Boss_ESP_Objects = _G._PTH_Boss_ESP_Objects or {}

    local function removePlayerESP(p)
        local o = _G._PTH_ESP_Objects[p]
        if not o then return end
        pcall(function() o.bb:Destroy() end)
        pcall(function() o.hl:Destroy() end)
        _G._PTH_ESP_Objects[p] = nil
    end

    local function createPlayerESP(p)
        local c = p.Character
        if not c or p == lp then return end
        local head = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
        if not head then return end
        for _, obj in ipairs(head:GetChildren()) do
            if obj:IsA("BillboardGui") and obj.Name == "PTH_ESP_BB" then obj:Destroy() end
        end
        for _, obj in ipairs(c:GetChildren()) do
            if obj:IsA("Highlight") and obj.Name == "PTH_ESP_HL" then obj:Destroy() end
        end
        local bb = Instance.new("BillboardGui")
        bb.Name = "PTH_ESP_BB"
        bb.Size = UDim2.new(0, 240, 0, 100)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = head
        bb.Parent = head

        local label = Instance.new("TextLabel", bb)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.2
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.Text = ""

        local hl = Instance.new("Highlight")
        hl.Name = "PTH_ESP_HL"
        hl.Adornee = c
        hl.FillColor = Color3.fromRGB(0, 200, 255)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.65
        hl.OutlineTransparency = 0
        hl.Parent = c

        _G._PTH_ESP_Objects[p] = {bb = bb, label = label, hl = hl}
    end

    local function removeBossESP(model)
        local o = _G._PTH_Boss_ESP_Objects[model]
        if not o then return end
        pcall(function() o.bb:Destroy() end)
        pcall(function() o.hl:Destroy() end)
        _G._PTH_Boss_ESP_Objects[model] = nil
    end

    local function createBossESP(model, bossName, head)
        for _, obj in ipairs(head:GetChildren()) do
            if obj:IsA("BillboardGui") and obj.Name == "PTH_BOSS_BB" then obj:Destroy() end
        end
        for _, obj in ipairs(model:GetChildren()) do
            if obj:IsA("Highlight") and obj.Name == "PTH_BOSS_HL" then obj:Destroy() end
        end

        local bb = Instance.new("BillboardGui")
        bb.Name = "PTH_BOSS_BB"
        bb.Size = UDim2.new(0, 250, 0, 70)
        bb.StudsOffset = Vector3.new(0, 4.2, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = head
        bb.Parent = head

        local label = Instance.new("TextLabel", bb)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 60, 90)
        label.TextStrokeTransparency = 0.2
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.Text = ""

        local hl = Instance.new("Highlight")
        hl.Name = "PTH_BOSS_HL"
        hl.Adornee = model
        hl.FillColor = Color3.fromRGB(255, 50, 80)
        hl.OutlineColor = Color3.fromRGB(255, 215, 0)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0
        hl.Parent = model

        _G._PTH_Boss_ESP_Objects[model] = {bb = bb, label = label, hl = hl, name = bossName}
    end

    local function findMatchingBossName(str)
        if not str then return nil end
        local lowerStr = str:lower()
        for bName, enabled in pairs(_G.SelectedBosses) do
            if enabled ~= false then
                local bLower = bName:lower()
                if string.find(lowerStr, bLower, 1, true) then
                    return bName
                end
            end
        end
        return nil
    end

    -- Vòng lặp Render ESP
    _G._PTH_ESP_Render = RunService.RenderStepped:Connect(function()
        local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local myPos = myRoot and myRoot.Position

        -- 1. Player ESP
        if _G.ESPPlayer then
            for _, p in ipairs(PlayersService:GetPlayers()) do
                if p ~= lp and getRoot(p) then
                    if not _G._PTH_ESP_Objects[p] or not _G._PTH_ESP_Objects[p].bb.Parent then
                        removePlayerESP(p); createPlayerESP(p)
                    end
                    local o = _G._PTH_ESP_Objects[p]
                    if o and o.label then
                        local pos = getRoot(p).Position
                        local hp, mhp = getHealth(p)
                        local cp, mcp = getChakra(p)
                        local bloodline = getBloodline(p)
                        local distance = myPos and math.floor((pos - myPos).Magnitude) or 0
                        o.label.Text = string.format(
                            "👤 %s\n📏 %d M\n🩸 %s\n❤ HP: %d/%d\n🌀 Chakra: %d/%d",
                            p.DisplayName or p.Name, distance, bloodline, hp, mhp, cp, mcp
                        )
                    end
                else
                    removePlayerESP(p)
                end
            end
        else
            for p in pairs(_G._PTH_ESP_Objects) do removePlayerESP(p) end
        end

        -- 2. Boss ESP (Chỉ hiện khi có máu > 0)
        if _G.ESPBoss then
            local seenBosses = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and not PlayersService:GetPlayerFromCharacter(obj) then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local matchedName = findMatchingBossName(obj.Name)
                        if matchedName then
                            local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                            if head then
                                seenBosses[obj] = true
                                if _G._PTH_Boss_LastPositions then
                                    _G._PTH_Boss_LastPositions[matchedName] = head.CFrame * CFrame.new(0, 3, 5)
                                end
                                if not _G._PTH_Boss_ESP_Objects[obj] or not _G._PTH_Boss_ESP_Objects[obj].bb.Parent then
                                    removeBossESP(obj)
                                    createBossESP(obj, matchedName, head)
                                end
                                local bo = _G._PTH_Boss_ESP_Objects[obj]
                                if bo and bo.label then
                                    local dist = myPos and math.floor((head.Position - myPos).Magnitude) or 0
                                    local curH = math.floor(hum.Health)
                                    local maxH = math.floor(hum.MaxHealth)
                                    bo.label.Text = string.format(
                                        "👑 [BOSS] %s\n❤ HP: %d / %d\n📏 %d M",
                                        matchedName, curH, maxH, dist
                                    )
                                end
                            end
                        end
                    end
                end
            end
            for model in pairs(_G._PTH_Boss_ESP_Objects) do
                if not seenBosses[model] then
                    removeBossESP(model)
                end
            end
        else
            for model in pairs(_G._PTH_Boss_ESP_Objects) do removeBossESP(model) end
        end
    end)

    PlayersService.PlayerRemoving:Connect(function(p)
        if _G._PTH_ESP_Objects[p] then removePlayerESP(p) end
        bloodlineCache[p] = nil
        bloodlineCacheTime[p] = nil
    end)
end
Features["ESP"] = SetupESPFeature

-- ============================================================
-- ==================== FRUIT FARM FEATURE ====================
-- Gộp từ Fruit Farm v9: duyệt tuần tự tất cả tree + noclip + hold
-- ============================================================
local function SetupFruitFeature(parent)
    local header = Instance.new("TextLabel", parent)
    header.Size = UDim2.new(1, -20, 0, 30)
    header.Position = UDim2.new(0, 10, 0, 48)
    header.Text = "🍊 FRUIT FARM"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = Color3.fromRGB(255, 180, 80)
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left

    -- ===== State riêng cho Fruit =====
    local F = {
        enabled = false,
        running = false,
        currentIndex = 0,
        currentTreeName = "-",
        status = "Idle",
        targetPos = nil,
        treeList = {},
        treeListBuilt = false,
        noclipConn = nil,
        holdConn = nil,
        loopThread = nil,
        Character = nil,
        HRP = nil,
        Humanoid = nil,
    }
    local USE_NOCLIP = true
    local HOLD_POSITION = true
    local WAIT_AT_TREE = 6
    local FRUIT_CHECK_RADIUS = 100
    local CLICK_DELAY = 0.35
    local TELE_BEFORE_CLICK = 0.15

    local FRUIT_CHECKLIST_ORDER = {
        "Chakra Fruit",
        "Life Up Fruit",
        "Fruit Of Forgetfulness",
        "Alluring Apple",
        "Apple",
        "Orange",
        "Banana",
        "Pear",
        "Mango"
    }

    _G.SelectedFruits = _G.SelectedFruits or {
        ["Chakra Fruit"]          = true,
        ["Life Up Fruit"]         = true,
        ["Fruit Of Forgetfulness"]= true,
        ["Alluring Apple"]        = true,
        ["Apple"]                 = true,
        ["Orange"]                = true,
        ["Banana"]                = true,
        ["Pear"]                  = true,
        ["Mango"]                 = true,
    }

    local TREE_NAME_KEYWORD = "Tree"
    local TRUNK_KEYWORDS = { "Trunk", "Log", "Stem", "Body", "Center", "Wood" }

    local function bindChar(c)
        F.Character = c
        F.HRP = c:WaitForChild("HumanoidRootPart")
        F.Humanoid = c:WaitForChild("Humanoid")
    end
    if lp.Character then bindChar(lp.Character) end
    lp.CharacterAdded:Connect(bindChar)

    -- ===== Helpers =====
    local function getRoot(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Model") then
            return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    local function getTrunk(model)
        if model:IsA("BasePart") then return model end
        for _, kw in ipairs(TRUNK_KEYWORDS) do
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("BasePart") and string.find(d.Name, kw) then return d end
            end
        end
        local biggest, biggestSize = nil, 0
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                local vol = d.Size.X * d.Size.Y * d.Size.Z
                if vol > biggestSize then biggest, biggestSize = d, vol end
            end
        end
        return biggest or getRoot(model)
    end

    local function isFruit(part)
        if not part or not (part:IsA("MeshPart") or part:IsA("BasePart") or part:IsA("Model")) then return false end
        if part.Parent ~= Workspace and part.Parent.Parent ~= Workspace then return false end
        local pName = part.Name
        for fruitName, enabled in pairs(_G.SelectedFruits) do
            if enabled ~= false then
                if string.find(pName:lower(), fruitName:lower(), 1, true) then
                    return true
                end
            end
        end
        return false
    end

    local function isTreeModel(obj)
        if not obj then return false end
        if obj.Parent ~= Workspace then return false end
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
        return string.find(obj.Name, TREE_NAME_KEYWORD) ~= nil
    end

    local function getAllTrees()
        local trees = {}
        for _, obj in ipairs(Workspace:GetChildren()) do
            if isTreeModel(obj) then
                local trunk = getTrunk(obj)
                if trunk then table.insert(trees, { model = obj, trunk = trunk }) end
            end
        end
        return trees
    end

    local function buildTreeList()
        local trees = getAllTrees()
        if F.HRP and F.HRP.Parent then
            local myPos = F.HRP.Position
            table.sort(trees, function(a, b)
                return (a.trunk.Position - myPos).Magnitude < (b.trunk.Position - myPos).Magnitude
            end)
        end
        F.treeList = trees
        F.treeListBuilt = true
        print(string.format("[PTH Fruit] Build danh sách %d tree", #trees))
    end

    local function getAllFruits()
        local fruits = {}
        for _, obj in ipairs(Workspace:GetChildren()) do
            if isFruit(obj) then table.insert(fruits, obj) end
        end
        return fruits
    end

    local function findFruitNear(pos, radius)
        local best, bestDist = nil, radius
        for _, f in ipairs(getAllFruits()) do
            local fPos = f:IsA("BasePart") and f.Position or (f.PrimaryPart and f.PrimaryPart.Position or f:GetPivot().Position)
            local d = (fPos - pos).Magnitude
            if d < bestDist then best, bestDist = f, d end
        end
        return best
    end

    local function teleTo(pos)
        if not F.HRP or not F.HRP.Parent then return end
        F.targetPos = pos
        local currentRot = F.HRP.CFrame - F.HRP.CFrame.Position
        F.HRP.CFrame = CFrame.new(pos) * currentRot
        F.HRP.AssemblyLinearVelocity = Vector3.zero
        F.HRP.AssemblyAngularVelocity = Vector3.zero
        F.HRP.Velocity = Vector3.zero
        F.HRP.RotVelocity = Vector3.zero
    end

    -- ===== Noclip =====
    local function enableNoclip()
        if F.noclipConn then return end
        F.noclipConn = RunService.Stepped:Connect(function()
            if not F.enabled or not USE_NOCLIP then return end
            if not F.Character or not F.Character.Parent then return end
            for _, p in ipairs(F.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
        _G._PTH_FruitNoclip = F.noclipConn
    end

    local function disableNoclip()
        if F.noclipConn then F.noclipConn:Disconnect(); F.noclipConn = nil end
        _G._PTH_FruitNoclip = nil
        local char = F.Character or lp.Character
        restoreCharacterCollision(char)
        stopCharacterMomentum(char)
    end

    -- ===== Hold =====
    local function enableHold()
        if F.holdConn then return end
        F.holdConn = RunService.Heartbeat:Connect(function()
            if not F.enabled or not HOLD_POSITION then return end
            if not F.HRP or not F.HRP.Parent then return end
            if not F.targetPos then return end
            F.HRP.AssemblyLinearVelocity = Vector3.zero
            F.HRP.AssemblyAngularVelocity = Vector3.zero
            F.HRP.Velocity = Vector3.zero
            F.HRP.RotVelocity = Vector3.zero
            local currentRot = F.HRP.CFrame - F.HRP.CFrame.Position
            F.HRP.CFrame = CFrame.new(F.targetPos) * currentRot
        end)
        _G._PTH_FruitHold = F.holdConn
    end

    local function disableHold()
        if F.holdConn then F.holdConn:Disconnect(); F.holdConn = nil end
        _G._PTH_FruitHold = nil
        F.targetPos = nil
        local char = F.Character or lp.Character
        stopCharacterMomentum(char)
    end

    -- ===== Shutdown =====
    local function shutdown()
        F.enabled = false
        F.running = false
        F.status = "Đã tắt"
        
        if F.loopThread then
            pcall(function() task.cancel(F.loopThread) end)
            F.loopThread = nil
        end
        _G._PTH_FruitLoop = nil

        disableHold()
        disableNoclip()
        
        local char = F.Character or lp.Character
        restoreCharacterCollision(char)
        stopCharacterMomentum(char)

        _G._PTH_FruitNoclip = nil
        _G._PTH_FruitHold = nil
    end
    _G._PTH_FruitStop = shutdown

    -- ===== Click =====
    local function clickAtWorldPosition(worldPos)
        local cam = workspace.CurrentCamera
        if not cam then return false end
        local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
        if not onScreen then return false end
        local x, y = math.floor(screenPos.X), math.floor(screenPos.Y)
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end

    local function pickFruit(fruit)
        if not fruit or not fruit.Parent then return end
        local fPos = fruit:IsA("BasePart") and fruit.Position or (fruit.PrimaryPart and fruit.PrimaryPart.Position or fruit:GetPivot().Position)
        F.status = "Tới fruit: " .. fruit.Name
        teleTo(fPos + Vector3.new(0, 2, 0))
        task.wait(TELE_BEFORE_CLICK)
        F.status = "Click: " .. fruit.Name
        local ok = clickAtWorldPosition(fPos)
        if not ok then
            local prompt = fruit:FindFirstChildOfClass("ProximityPrompt") or fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function() fireproximityprompt(prompt) end)
            else
                local cd = fruit:FindFirstChildOfClass("ClickDetector") or fruit:FindFirstChildWhichIsA("ClickDetector", true)
                if cd then pcall(function() fireclickdetector(cd) end) end
            end
        end
        task.wait(CLICK_DELAY)
    end

    -- ===== Loop =====
    local function startLoop()
        if F.loopThread then
            pcall(function() task.cancel(F.loopThread) end)
            F.loopThread = nil
        end
        F.loopThread = task.spawn(function()
            task.wait(1.5)
            while F.enabled do
                if not F.HRP or not F.HRP.Parent then
                    F.status = "Chờ respawn..."
                    task.wait(0.5)
                    continue
                end

                if not F.treeListBuilt or #F.treeList == 0 then
                    F.status = "Đang scan tree..."
                    buildTreeList()
                    F.currentIndex = 0
                    if #F.treeList == 0 then
                        F.status = "Không có tree nào"
                        task.wait(2)
                        F.treeListBuilt = false
                        continue
                    end
                end

                local needRebuild = false
                for _, t in ipairs(F.treeList) do
                    if not t.model or not t.model.Parent then needRebuild = true break end
                end
                if needRebuild then
                    F.treeListBuilt = false
                    F.currentIndex = 0
                    task.wait(0.5)
                    continue
                end

                F.currentIndex = F.currentIndex + 1
                if F.currentIndex > #F.treeList then
                    F.currentIndex = 1
                    F.status = "Hết vòng, quay lại cây 1"
                end

                local tree = F.treeList[F.currentIndex]
                F.currentTreeName = tree.model.Name
                F.status = string.format("Tới cây %d/%d: %s", F.currentIndex, #F.treeList, tree.model.Name)
                local trunkSizeY = (tree.trunk:IsA("BasePart") and tree.trunk.Size.Y) or 6
                local standPos = tree.trunk.Position + Vector3.new(0, (trunkSizeY / 2) + 3, 0)
                teleTo(standPos)
                task.wait(0.2)

                for i = WAIT_AT_TREE, 1, -1 do
                    if not F.enabled then break end
                    F.status = string.format("Cây %d/%d: %s (%ds)", F.currentIndex, #F.treeList, tree.model.Name, i)
                    task.wait(1)
                end
                if not F.enabled then continue end

                local fruit = findFruitNear(tree.trunk.Position, FRUIT_CHECK_RADIUS)
                if fruit then
                    while fruit and F.enabled do
                        pickFruit(fruit)
                        fruit = findFruitNear(tree.trunk.Position, FRUIT_CHECK_RADIUS)
                        if fruit and not fruit.Parent then fruit = nil end
                    end
                    F.status = "Đã nhặt hết fruit"
                else
                    F.status = "Không có fruit"
                end
                task.wait(0.3)
            end
            F.loopThread = nil
        end)
        _G._PTH_FruitLoop = F.loopThread
    end

    -- ===== UI =====
    local toggleBtn = Instance.new("TextButton", parent)
    toggleBtn.Size = UDim2.new(1, -20, 0, 42)
    toggleBtn.Position = UDim2.new(0, 10, 0, 88)
    toggleBtn.Text = "FRUIT FARM: OFF"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 60)
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

    local noclipBtn = Instance.new("TextButton", parent)
    noclipBtn.Size = UDim2.new(0.5, -15, 0, 32)
    noclipBtn.Position = UDim2.new(0, 10, 0, 138)
    noclipBtn.Text = "Noclip: ON"
    noclipBtn.Font = Enum.Font.GothamBold
    noclipBtn.TextSize = 12
    noclipBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
    noclipBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", noclipBtn).CornerRadius = UDim.new(0, 6)

    local holdBtn = Instance.new("TextButton", parent)
    holdBtn.Size = UDim2.new(0.5, -15, 0, 32)
    holdBtn.Position = UDim2.new(0.5, 5, 0, 138)
    holdBtn.Text = "Hold: ON"
    holdBtn.Font = Enum.Font.GothamBold
    holdBtn.TextSize = 12
    holdBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
    holdBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", holdBtn).CornerRadius = UDim.new(0, 6)

    local rebuildBtn = Instance.new("TextButton", parent)
    rebuildBtn.Size = UDim2.new(1, -20, 0, 30)
    rebuildBtn.Position = UDim2.new(0, 10, 0, 178)
    rebuildBtn.Text = "🔄 Rebuild danh sách cây"
    rebuildBtn.Font = Enum.Font.GothamBold
    rebuildBtn.TextSize = 12
    rebuildBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
    rebuildBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", rebuildBtn).CornerRadius = UDim.new(0, 6)

    local statusLabel = Instance.new("TextLabel", parent)
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 214)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Trạng thái: Idle"
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    local treeLabel = Instance.new("TextLabel", parent)
    treeLabel.Size = UDim2.new(1, -20, 0, 20)
    treeLabel.Position = UDim2.new(0, 10, 0, 236)
    treeLabel.BackgroundTransparency = 1
    treeLabel.Text = "Cây: -"
    treeLabel.Font = Enum.Font.Gotham
    treeLabel.TextSize = 12
    treeLabel.TextColor3 = Color3.fromRGB(180,220,180)
    treeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local checklistHeader = Instance.new("TextLabel", parent)
    checklistHeader.Size = UDim2.new(1, -20, 0, 22)
    checklistHeader.Position = UDim2.new(0, 10, 0, 260)
    checklistHeader.Text = "🍎 DANH SÁCH FRUIT CẦN FARM (Bật/Tắt):"
    checklistHeader.Font = Enum.Font.GothamBold
    checklistHeader.TextSize = 12
    checklistHeader.TextColor3 = Color3.fromRGB(255, 200, 100)
    checklistHeader.BackgroundTransparency = 1
    checklistHeader.TextXAlignment = Enum.TextXAlignment.Left

    local fruitScroll = Instance.new("ScrollingFrame", parent)
    fruitScroll.Size = UDim2.new(1, -20, 0, 190)
    fruitScroll.Position = UDim2.new(0, 10, 0, 286)
    fruitScroll.BackgroundColor3 = Color3.fromRGB(13, 14, 23)
    fruitScroll.BorderSizePixel = 0
    fruitScroll.ScrollBarThickness = 3
    fruitScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 120)
    fruitScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    fruitScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", fruitScroll).CornerRadius = UDim.new(0, 10)
    local fsStroke = Instance.new("UIStroke", fruitScroll)
    fsStroke.Color = Color3.fromRGB(28, 30, 48)

    local fsPadding = Instance.new("UIPadding", fruitScroll)
    fsPadding.PaddingTop = UDim.new(0, 5)
    fsPadding.PaddingBottom = UDim.new(0, 5)
    fsPadding.PaddingLeft = UDim.new(0, 5)
    fsPadding.PaddingRight = UDim.new(0, 5)

    local fsLayout = Instance.new("UIListLayout", fruitScroll)
    fsLayout.Padding = UDim.new(0, 4)
    fsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, fruitName in ipairs(FRUIT_CHECKLIST_ORDER) do
        local fRow = Instance.new("Frame", fruitScroll)
        fRow.Size = UDim2.new(1, 0, 0, 34)
        fRow.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
        Instance.new("UICorner", fRow).CornerRadius = UDim.new(0, 8)
        local rStroke = Instance.new("UIStroke", fRow)
        rStroke.Color = Color3.fromRGB(32, 35, 52)

        local fLbl = Instance.new("TextLabel", fRow)
        fLbl.Size = UDim2.new(1, -60, 1, 0)
        fLbl.Position = UDim2.new(0, 12, 0, 0)
        fLbl.Text = fruitName
        fLbl.Font = Enum.Font.GothamMedium
        fLbl.TextSize = 13
        fLbl.TextColor3 = Color3.fromRGB(230, 235, 255)
        fLbl.BackgroundTransparency = 1
        fLbl.TextXAlignment = Enum.TextXAlignment.Left

        local checkBtn = Instance.new("TextButton", fRow)
        checkBtn.Size = UDim2.new(0, 28, 0, 24)
        checkBtn.Position = UDim2.new(1, -38, 0.5, -12)
        local isChecked = (_G.SelectedFruits[fruitName] ~= false)
        checkBtn.Text = isChecked and "✓" or ""
        checkBtn.Font = Enum.Font.GothamBold
        checkBtn.TextSize = 14
        checkBtn.BackgroundColor3 = isChecked and Color3.fromRGB(230, 120, 30) or Color3.fromRGB(35, 38, 55)
        checkBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0, 6)

        checkBtn.MouseButton1Click:Connect(function()
            local nowState = not (_G.SelectedFruits[fruitName] ~= false)
            _G.SelectedFruits[fruitName] = nowState
            checkBtn.Text = nowState and "✓" or ""
            checkBtn.BackgroundColor3 = nowState and Color3.fromRGB(230, 120, 30) or Color3.fromRGB(35, 38, 55)
        end)
    end

    -- ===== Button logic =====
    toggleBtn.MouseButton1Click:Connect(function()
        if F.enabled then
            -- TẮT
            toggleBtn.Text = "FRUIT FARM: OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 60)
            shutdown()
            if F.loopThread then
                pcall(function() task.cancel(F.loopThread) end)
                F.loopThread = nil
            end
        else
            -- BẬT
            F.enabled = true
            F.treeListBuilt = false
            F.currentIndex = 0
            toggleBtn.Text = "FRUIT FARM: ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 80)
            F.status = "Đang bật..."
            if USE_NOCLIP then enableNoclip() end
            if HOLD_POSITION then enableHold() end
            startLoop()
        end
    end)

    noclipBtn.MouseButton1Click:Connect(function()
        USE_NOCLIP = not USE_NOCLIP
        if USE_NOCLIP then
            noclipBtn.Text = "Noclip: ON"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
            if F.enabled then enableNoclip() end
        else
            noclipBtn.Text = "Noclip: OFF"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 60)
            disableNoclip()
        end
    end)

    holdBtn.MouseButton1Click:Connect(function()
        HOLD_POSITION = not HOLD_POSITION
        if HOLD_POSITION then
            holdBtn.Text = "Hold: ON"
            holdBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
            if F.enabled then enableHold() end
        else
            holdBtn.Text = "Hold: OFF"
            holdBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 60)
            disableHold()
        end
    end)

    rebuildBtn.MouseButton1Click:Connect(function()
        F.treeListBuilt = false
        F.currentIndex = 0
        F.status = "Đang rebuild danh sách cây..."
    end)

    -- Realtime update labels
    task.spawn(function()
        while task.wait(0.2) do
            if not parent.Parent then break end
            pcall(function()
                statusLabel.Text = "Trạng thái: " .. F.status
                treeLabel.Text = string.format("Cây %d/%d: %s", F.currentIndex, #F.treeList, F.currentTreeName)
            end)
        end
    end)
end
Features["Fruit"] = SetupFruitFeature

-- ============================================================
-- TẠO NÚT SIDEBAR + MỞ TAB MẶC ĐỊNH
-- ============================================================
local sections = {"System", "Farm", "Remote", "ESP", "Fruit"}

for _, s in ipairs(sections) do
    pcall(function() CreateSidebarBtn(s) end)
end

pcall(function() OpenSection("System") end)

print("✅ PTH HUB LOADED - System + Farm + Remote V2 + ESP + Fruit Farm v9")