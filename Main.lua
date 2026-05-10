local redzlib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Ha3kCodeVN/RedzV5Gui/refs/heads/main/Game-Roblox.txt"
))()

local Window = redzlib:MakeWindow({
    Title = "Survive The Apocalypse [PENETRATION🩸]",
    SubTitle = "FireSnowFireVoinDark",
    SaveFolder = "Hub"
})

-- Tabs
local MainTab = Window:MakeTab({"Main", "rbxassetid://4483345998"})
local CombatTab = Window:MakeTab({"Combat", "rbxassetid://4483345998"})

-- Variables
local LP = game:GetService("Players").LocalPlayer
local SpeedEnabled, desiredSpeed = false, 33
local GlobalAura, GunEnabled = false, false
local MeleeRange, GunRange = 25, 125
local Attack_Speed = 0.1

local PENETRATE_LIST = {
    ["Fence"] = true, ["Gate"] = true, ["Shelf"] = true, 
    ["Barbed Wire"] = true, ["Bear Trap"] = true, ["Farm Plot"] = true, 
    ["Floodlight"] = true, ["Electric Fence"] = true
}

-- Utils
local function isAlive(obj)
    if not obj then return false end
    local mock = obj:FindFirstChild("MockHumanoid")
    if mock then
        local hp = mock:GetAttribute("Health")
        return hp and hp > 0
    end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0.1
end

local function isValidTarget(obj)
    if not obj or not obj:IsA("Model") then return false end
    if obj.Name == LP.Name or obj.Name == "Merchant" or game:GetService("Players"):GetPlayerFromCharacter(obj) then return false end
    if obj:FindFirstChild("Follow") then return false end
    return isAlive(obj)
end

local function getActiveWeapon(requiredType)
    if not LP.Character then return nil end
    for _, tool in ipairs(LP.Character:GetChildren()) do
        if (tool:IsA("Tool") or tool:IsA("Model")) and tool:GetAttribute("ToolType") == requiredType then
            return tool
        end
    end
    return nil
end

local function canShootTarget(from, to, targetModel)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignoreList = {LP.Character}
    for _, v in ipairs(workspace.Structures:GetChildren()) do
        if PENETRATE_LIST[v.Name] then table.insert(ignoreList, v) end
    end
    rayParams.FilterDescendantsInstances = ignoreList

    local result = workspace:Raycast(from, (to - from).Unit * GunRange, rayParams)
    
    if not result or result.Instance:IsDescendantOf(targetModel) then
        return true
    end
    return false
end

-- Core Logic
-- Melee Kill Aura
task.spawn(function()
    while true do
        task.wait(Attack_Speed)
        if GlobalAura then
            local tool = getActiveWeapon("Melee")
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and tool and tool:FindFirstChild("HitTargets") then
                local targets = {}
                for _, folder in ipairs({workspace.Characters, workspace.Structures}) do
                    for _, obj in ipairs(folder:GetChildren()) do
                        if (folder == workspace.Characters and isValidTarget(obj)) or (folder == workspace.Structures and (obj.Name == "Barrel" or obj.Name == "Scrap Pile") and isAlive(obj)) then
                            local pivot = obj:FindFirstChild("MainPart") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("BasePart")
                            if pivot and (myRoot.Position - pivot.Position).Magnitude <= MeleeRange then
                                table.insert(targets, obj)
                            end
                        end
                    end
                end
                if #targets > 0 then
                    if tool:FindFirstChild("Swing") then tool.Swing:FireServer() end
                    tool.HitTargets:FireServer(targets)
                end
            end
        end
    end
end)

-- GunKillAura
task.spawn(function()
    while true do
        task.wait(Attack_Speed)
        if GunEnabled then
            local gun = getActiveWeapon("Gun")
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and gun and gun:FindFirstChild("Shoot") then
                local closest, dist = nil, GunRange
                
                for _, enemy in ipairs(workspace.Characters:GetChildren()) do
                    if isValidTarget(enemy) then
                        local head = enemy:FindFirstChild("Head")
                        if head then
                            local d = (myRoot.Position - head.Position).Magnitude
                            if d < dist then
                                if canShootTarget(myRoot.Position, head.Position, enemy) then
                                    dist = d
                                    closest = enemy
                                end
                            end
                        end
                    end
                end

                if closest then
                    gun.Shoot:FireServer(myRoot.Position, {{
                        Target = closest.Head.Position,
                        HitData = {{HitChar = closest, HitPos = closest.Head.Position, HitPart = closest.Head}}
                    }})
                end
            end
        end
    end
end)

-- WalkSpeed
game:GetService("RunService").Heartbeat:Connect(function()
    if SpeedEnabled and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = desiredSpeed end
    end
end)

--Ui
MainTab:AddToggle({ Name = "Enable WalkSpeed", Default = false, Callback = function(v) SpeedEnabled = v end })
MainTab:AddSlider({ Name = "Speed Value", Min = 26, Max = 33, Increment = 1, Default = 33, Callback = function(v) desiredSpeed = v end })

CombatTab:AddToggle({ Name = "Melee KillAura", Default = false, Callback = function(v) GlobalAura = v end })
CombatTab:AddToggle({ Name = "Auto Gun Sniper", Default = false, Callback = function(v) GunEnabled = v end })
CombatTab:AddSlider({ Name = "Melee Range", Min = 10, Max = 18, Increment = 1, Default = 25, Callback = function(v) MeleeRange = v end })
CombatTab:AddSlider({ Name = "Gun Range", Min = 50, Max = 125, Increment = 1, Default = 75, Callback = function(v) GunRange = v end })
CombatTab:AddSlider({ Name = "Attack Speed", Min = 0.05, Max = 1, Increment = 0.05, Default = 0.1, Callback = function(v) Attack_Speed = v end })
