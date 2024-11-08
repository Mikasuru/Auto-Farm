if game.PlaceId ~= 9359839118 then
    local player = game.Players.LocalPlayer

    local screenGui = Instance.new("ScreenGui")
    local frame = Instance.new("Frame")
    local textLabel = Instance.new("TextLabel")
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.Position = UDim2.new(0.5, -150, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = "The script isn't support on this map."
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 16
    textLabel.Parent = frame
    
    wait(3)
    screenGui:Destroy()
    return
end

-- ANTI AFK
local virtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    virtualUser:CaptureController()
    virtualUser:ClickButton2(Vector2.new())
end)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Global Variables & Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ActionRemote = ReplicatedStorage:WaitForChild("Remote")
local PumpsFolder = workspace:WaitForChild("Pumps")
local StorageFolder = workspace:WaitForChild("Storage")
local ShelvesFolder = workspace:WaitForChild("Shelves")
local StatsHolder = require(ReplicatedStorage:WaitForChild("StatHolder"))
local InputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Script Variables
local TravelSpeed = 50
local GasEnabled = false
local CleaningEnabled = false
local RestockEnabled = false
local CashierEnabled = false
local SittingEnabled = false
local AllowFuelBuy = false
local AllowItemsBuy = false
local ReQueueItemAfterFailedPurchase = false
local MoneySource = "Station"
local AllowSecondarySource = false
local SecondaryMoneySource = "Station"
local AllowStationSpendingDuringBankruptcy = true
local FuelChoice = 1
local ItemRestockQueue = {}
local ItemPositionMemory = {}
local PreviousItem
local BlacklistedItems = {}

local sofa = workspace.Ceilings.Sofa

-- Add notify function
if _G.dAAcG3fvBqVoPzVnAFk == nil then _G.dAAcG3fvBqVoPzVnAFk = "" end 
function notify(a,b,c)
    local d=c or function()return end
    local e=b or false
    if a==_G.dAAcG3fvBqVoPzVnAFk and e==false then return end
    Fluent:Notify({
        Title = "Notification",
        Content = a,
        Duration = 3
    })
end

local Window = Fluent:CreateWindow({
    Title = "Kukuri Script",
    SubTitle = "by Kukuri", 
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Add your original functions
local function GetPlayerCharacter() return LocalPlayer.Character or LocalPlayer.CharacterAdded:wait(); end
local function GetStoreGasoline() return PumpsFolder:GetAttribute("Gasoline") end
local function GetMoneyOfSource(Source : StringValue)
   if Source == "Station" then
       return workspace.Station:GetAttribute("Money")
   elseif Source == "Client" then
       return LocalPlayer:GetAttribute("Money")
   end
end
local function IsItemBlacklisted(ItemName : StringValue)
 for _,v in pairs(BlacklistedItems) do
     if v == ItemName then
         return true
     end
 end
 return false
end
local function FindItemCatergory(ItemName : StringValue)
 local ShopTable = StatsHolder.Shops
 for FirstName,FirstCatergory in pairs(ShopTable) do
     if FirstCatergory ~= "Syntin Petrol Co" then
         for SecondName,SecondCatergory in pairs(FirstCatergory) do
             if SecondCatergory[ItemName] ~= nil then
                 return {
                     ["Item"] = ItemName,
                     ["ItemProvider"] = FirstName,
                     ["ItemCatergory"] = SecondName,
                     ["ItemPrice"] = SecondCatergory[ItemName][2]
                 }
             end
         end
     end
 end
end
local function DecideSource(MinimumMoneyNeeded : IntValue)
 local PrimarySourceMoney = GetMoneyOfSource(MoneySource)
 if MoneySource == "Client" then
     if PrimarySourceMoney >= MinimumMoneyNeeded then
         return MoneySource
     end
 else
     local StationBankrupt = not (workspace.Station:GetAttribute("Money") > workspace.Station:GetAttribute("EstBills"))
     if (StationBankrupt and AllowStationSpendingDuringBankruptcy) or (not StationBankrupt) then
         if LocalPlayer:GetAttribute("Contributions") >= MinimumMoneyNeeded then
             if #game.Teams.Manager:GetPlayers() > 0 then
                 if LocalPlayer.Team == game.Teams.Manager then
                     return MoneySource
                 end
             else
                 return MoneySource
             end
         end
     end
 end
 if AllowSecondarySource then
     local SecondarySourceMoney = GetMoneyOfSource(SecondaryMoneySource)
     if SecondaryMoneySource == "Client" then
         if SecondarySourceMoney >= MinimumMoneyNeeded then
             return SecondaryMoneySource
         end
     else
         local StationBankrupt = not (workspace.Station:GetAttribute("Money") > workspace.Station:GetAttribute("EstBills"))
         if (StationBankrupt and AllowStationSpendingDuringBankruptcy) or (not StationBankrupt) then
             if LocalPlayer:GetAttribute("Contributions") >= MinimumMoneyNeeded then
                 if #game.Teams.Manager:GetPlayers() > 0 then
                     if LocalPlayer.Team == game.Teams.Manager then
                         return SecondaryMoneySource
                     end
                 else
                     return SecondaryMoneySource
                 end
             end
         end
     end
 end
 return nil
end
local function BuyFuel()
  local Source = DecideSource(StatsHolder["Shops"]["Syntin Petrol Co"]["Gasoline 87"][FuelChoice][2])
  if Source ~= nil then
      ActionRemote:FireServer("BuyItem","Syntin Petrol Co","Gasoline 87", FuelChoice,Source);
  else
      notify("Failed to purchase fuel",true)
  end
end
local function GetPlayerStamina() return LocalPlayer:GetAttribute("Stamina"); end

if _G.dAAcG3fvBqVoPzVnAFk == nil then _G.dAAcG3fvBqVoPzVnAFk = "" end function notify(a,b,c)local d=c or function()return end;local e=b or false;if a==_G.dAAcG3fvBqVoPzVnAFk and e==false then return end;spawn(function()for f,g in pairs(game.CoreGui:GetChildren())do spawn(function()if g.Name=="MNotify"then pcall(function()g.ImageButton.ZIndex=58;g.ImageButton.TextLabel.ZIndex=59;g.ImageButton:TweenPosition(UDim2.new(0.01,0,1,0),"Out","Quint",.7,true)game:GetService("TweenService"):Create(g.ImageButton.TextLabel,TweenInfo.new(0.8,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,0),{TextTransparency=1})wait(1)g:Destroy()end)end end)end;_G.dAAcG3fvBqVoPzVnAFk=a;local d=c or function()return end;local function h(i,j)local k=Instance.new(i)for f,g in pairs(j)do k[f]=g end;return k end;local l=h('ScreenGui',{DisplayOrder=0,Enabled=true,ResetOnSpawn=true,Name='MNotify',Parent=game.CoreGui})local m=h('ImageButton',{Image='rbxassetid://1051186612',ImageColor3=Color3.new(0.129412,0.129412,0.129412),ImageRectOffset=Vector2.new(0,0),ImageRectSize=Vector2.new(0,0),ImageTransparency=0,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(20,20,20,20),AutoButtonColor=true,Modal=false,Selected=false,Style=Enum.ButtonStyle.Custom,Active=true,AnchorPoint=Vector2.new(0,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderColor3=Color3.new(0.105882,0.164706,0.207843),BorderSizePixel=1,ClipsDescendants=false,Draggable=false,Position=UDim2.new(0.00999999978,0,1,0),Rotation=0,Selectable=true,Size=UDim2.new(0,234,0,40),SizeConstraint=Enum.SizeConstraint.RelativeXY,Visible=true,ZIndex=60,Name='ImageButton',Parent=l})local n=h('TextLabel',{Font=Enum.Font.SourceSansLight,FontSize=Enum.FontSize.Size24,Text=a,TextColor3=Color3.new(0.807843,0.807843,0.807843),TextScaled=false,TextSize=24,TextStrokeColor3=Color3.new(0,0,0),TextStrokeTransparency=1,TextTransparency=0,TextWrapped=false,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,Active=false,AnchorPoint=Vector2.new(0,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderColor3=Color3.new(0.105882,0.164706,0.207843),BorderSizePixel=1,ClipsDescendants=false,Draggable=false,Position=UDim2.new(0.132478639,0,0,0),Rotation=0,Selectable=false,Size=UDim2.new(0,174,0,40),SizeConstraint=Enum.SizeConstraint.RelativeXY,Visible=true,ZIndex=61,Name='TextLabel',Parent=m})local o=h('UIListLayout',{Padding=UDim.new(0,0),FillDirection=Enum.FillDirection.Vertical,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.Name,VerticalAlignment=Enum.VerticalAlignment.Top,Name='UIListLayout',Parent=m})local p=1;if string.len(a)<=49 then m.Size=UDim2.new(0,game:GetService("TextService"):GetTextSize(a,24,Enum.Font.SourceSansLight,Vector2.new(500,900)).X+57,0,40)elseif string.len(a)>49 then p=math.ceil(string.len(string.sub(a,49))/9)m.Size=UDim2.new(0,game:GetService("TextService"):GetTextSize(a,24,Enum.Font.SourceSansLight,Vector2.new(500+p*100,900)).X+57,0,40)end;m:TweenPosition(UDim2.new(0.01,0,1,-60),"Out","Quint",.7,true)spawn(function()wait(6.7)pcall(function()m.ZIndex=58;n.ZIndex=59;m:TweenPosition(UDim2.new(0.01,0,1,0),"Out","Quint",.7,true)_G.dAAcG3fvBqVoPzVnAFk=""wait(1)l:Destroy()end)end)m.MouseButton1Up:Connect(function()if c==nil then return end;spawn(function()pcall(function()m.ZIndex=58;n.ZIndex=59;m:TweenPosition(UDim2.new(0.01,0,1,0),"Out","Quint",.7,true)_G.dAAcG3fvBqVoPzVnAFk=""wait(1)l:Destroy()end)end)d()end)end)end
function roundNumber(num, numDecimalPlaces) -- https://devforum.roblox.com/t/rounding-to-1-decimal-point/673504
return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function TravelToCFrame(TargetCFrame : CFrame)
 local PlayerCharacter = GetPlayerCharacter()
 if PlayerCharacter then
     local DistanceBetweenPoints = ( PlayerCharacter.HumanoidRootPart.Position - TargetCFrame.Position ).Magnitude
     local TimeNeeded = roundNumber(DistanceBetweenPoints / TravelSpeed, 3)
     local Tween = TweenService:Create(
         PlayerCharacter.HumanoidRootPart,
         TweenInfo.new(
             TimeNeeded,
             Enum.EasingStyle.Linear,
             Enum.EasingDirection.Out
         ),
         {
             CFrame = CFrame.new(TargetCFrame.Position)
         }
     )
     Tween:Play()
     task.wait(TimeNeeded)
 end
end

local function GetChar()
    local player = game.Players.LocalPlayer
    if player then
        return player.Character
    end
    return nil
end

local function roundNum(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function MoveToCFrame(TargetCFrame)
    local PlayerCharacter = GetChar()
    if PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") then
        local DistanceBetweenPoints = (PlayerCharacter.HumanoidRootPart.Position - TargetCFrame.Position).Magnitude
        local TimeNeeded = roundNum(DistanceBetweenPoints / TravelSpeed, 3)
        
        local Tween = TweenService:Create(
            PlayerCharacter.HumanoidRootPart,
            TweenInfo.new(
                TimeNeeded,
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.Out
            ),
            {
                CFrame = CFrame.new(TargetCFrame.Position)
            }
        )
        Tween:Play()
        task.wait(TimeNeeded)
    end
end

local function RestoreEnergy(MinimumEnergy : IntValue)
 notify("Resting",true)
 SittingEnabled = true
 local PlayerCharacter = GetPlayerCharacter()
 local PreviousCFrame = PlayerCharacter.HumanoidRootPart.CFrame
 
 --TravelToCFrame(workspace.Ceilings.Sofa.Seat.CFrame)
 local sofa = workspace.Ceilings.Sofa
 if sofa then
 	print("Found sofa at:", sofa.CFrame)
 	MoveToCFrame(sofa.CFrame)
 else
 	print("Could not find sofa")
 end
 task.wait(2)
 while true do
     if GetPlayerStamina() >= MinimumEnergy then
         break
     end
     task.wait(0.5)
 end
 PlayerCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
 SittingEnabled = false
 TravelToCFrame(PreviousCFrame)
end

local function FindPumpToCar(CarModel : Instance)
 local CarPosition = CarModel.PrimaryPart.Position
 local Pump
 local PumpDistance = 999
 for _,v in pairs(PumpsFolder:GetChildren()) do
     local DistanceBetweenPump = (CarPosition - v.Screen.Position).Magnitude
     if DistanceBetweenPump < PumpDistance then
         Pump = v
         PumpDistance = DistanceBetweenPump
     end
 end
 return Pump
end

local function DoesPumpNeedToBeTakenOut(CarModel : Instance)
 if CarModel:FindFirstChild("Lid") then
     if CarModel.Lid:FindFirstChild("FinishFuel") then
         return true
     end
 end
 return false
end

local function RefuelCar(CarModel : Instance)
 local CarPump = FindPumpToCar(CarModel)
 if DoesPumpNeedToBeTakenOut(CarModel) then
     TravelToCFrame(CarModel.Lid.CFrame)
     ActionRemote:FireServer("FinishFuel", CarModel, CarPump)
     return
 end
 if CarModel:GetAttribute("IsRefueld") or CarModel:GetAttribute("IsRefilling") then return end
 local RequiredFuel = CarModel:GetAttribute("RequiredFuel")
 local TotalAttempts = 0
 if AllowFuelBuy then
     while true do
         TotalAttempts += 1
         local StoreFuel = GetStoreGasoline()
         if StoreFuel >= RequiredFuel then
             break
         end
         notify("Attempting to buy "..tostring(StatsHolder["Shops"]["Syntin Petrol Co"]["Gasoline 87"][FuelChoice][1]).."L of fuel",true)
         BuyFuel()
         task.wait(1)
         if TotalAttempts > 10 then
             break
         end
     end
 end
 if GetPlayerStamina() < 5 then
     RestoreEnergy(95)
 end
 local StoreFuel = GetStoreGasoline()
 if StoreFuel >= RequiredFuel then
     if CarModel.Lid:FindFirstChild("Refuel") then
         TravelToCFrame(CarModel.Lid.CFrame)
         notify("Refilling "..CarModel.Name,true)
         ActionRemote:FireServer("FuelCustomer", CarModel, CarPump)
         task.wait(4)
     end
 end
end
local PreviousItem
local function ScanItem(Item : Instance, CashierModel : Instance)
 if GetPlayerStamina() < 5 then
     RestoreEnergy(95)
 end
 if Item ~= PreviousItem then
     local DistanceFromItem = ( Item.Root.Position - GetPlayerCharacter().HumanoidRootPart.Position ).Magnitude
     if DistanceFromItem > 10 then
         notify("Too far away from cash register",true)
         TravelToCFrame(CFrame.new(1.46752572, 3, -6.53523779, 0.726744831, -4.74023416e-08, 0.68690753, 9.53963948e-08, 1, -3.19205924e-08, -0.68690753, 8.87266296e-08, 0.726744831))
     end
     if Item.Root:FindFirstChild("Scan") then
         if Item.Root:FindFirstChild("Scan").Enabled then
             if not CashierModel:GetAttribute("InUse") then
                 notify("Scanning "..Item.Name,true)
                 ActionRemote:FireServer("ScanItem",Item,CashierModel)
                 Item.Root:FindFirstChild("Scan").Enabled = false
                 PreviousItem = Item
                 task.wait(3)
             end
         end
     end
 end
end

-- Main Tab
do
    Tabs.Main:AddParagraph({
        Title = "Auto Features",
        Content = "Toggle automatic features"
    })

    -- Gas Toggle
    local GasToggle = Tabs.Main:AddToggle("GasEnabled", {
        Title = "Auto Gas",
        Description = "Automatically refuel cars",
        Default = false
    })

    GasToggle:OnChanged(function(Value)
        GasEnabled = Value
        notify("Fuel enabled: "..tostring(Value), true)
    end)

    -- Clean Toggle
    local CleanToggle = Tabs.Main:AddToggle("CleanEnabled", {
        Title = "Auto Clean",
        Description = "Automatically clean windows and spots",
        Default = false
    })

    CleanToggle:OnChanged(function(Value)
        CleaningEnabled = Value
        notify("Cleaning enabled: "..tostring(Value), true)
    end)

    -- Cashier Toggle
    local CashierToggle = Tabs.Main:AddToggle("CashierEnabled", {
        Title = "Auto Cashier", 
        Description = "Automatically scan items",
        Default = false
    })

    CashierToggle:OnChanged(function(Value)
        CashierEnabled = Value
        notify("Cashier enabled: "..tostring(Value), true)
    end)

    -- Restock Toggle  
    local RestockToggle = Tabs.Main:AddToggle("RestockEnabled", {
        Title = "Auto Restock",
        Description = "Automatically restock items",
        Default = false
    })

    RestockToggle:OnChanged(function(Value)
        RestockEnabled = Value
        if not Value then
            ItemRestockQueue = {}
        end
        notify("Restocking enabled: "..tostring(Value), true)
    end)

    -- Fuel Choice Dropdown
    local FuelChoices = {
        "15L $9",
        "25L $14",
        "50L $26", 
        "100L $46",
        "240L $100",
        "520L $200",
        "1000L $350"
    }

    Tabs.Main:AddDropdown("FuelChoice", {
        Title = "Fuel Choice",
        Description = "Select fuel amount to purchase",
        Values = FuelChoices,
        Default = 1,
        Multi = false
    }):OnChanged(function(Value)
        for i, choice in ipairs(FuelChoices) do
            if choice == Value then
                FuelChoice = i
                break
            end
        end
    end)

    -- Travel Speed Slider
    Tabs.Main:AddSlider("TravelSpeed", {
        Title = "Travel Speed",
        Description = "Adjust bot travel speed (too fast might get you kicked)",
        Default = 20,
        Min = 1,
        Max = 50,
        Rounding = 0,
        Callback = function(Value)
            TravelSpeed = Value
        end
    })
end

-- Settings Tab
do
    Tabs.Settings:AddParagraph({
        Title = "Money Source Settings",
        Content = "Configure money source options"
    })

    -- Primary Money Source
    Tabs.Settings:AddDropdown("MoneySource", {
        Title = "Primary Money Source",
        Values = {"Station", "Client"},
        Default = 1,
        Multi = false
    }):OnChanged(function(Value)
        MoneySource = Value
    end)

    -- Secondary Source Settings
    local SecondarySourceToggle = Tabs.Settings:AddToggle("AllowSecondarySource", {
        Title = "Allow Secondary Source",
        Default = false
    })

    SecondarySourceToggle:OnChanged(function(Value)
        AllowSecondarySource = Value
    end)

    -- Secondary Money Source
    Tabs.Settings:AddDropdown("SecondaryMoneySource", {
        Title = "Secondary Money Source",
        Values = {"Station", "Client"},
        Default = 1,
        Multi = false
    }):OnChanged(function(Value)
        SecondaryMoneySource = Value
    end)

    -- Purchase Settings
    local FuelBuyToggle = Tabs.Settings:AddToggle("AllowFuelBuy", {
        Title = "Allow Auto Fuel Purchase",
        Default = false
    })

    FuelBuyToggle:OnChanged(function(Value)
        AllowFuelBuy = Value
    end)

    local ItemsBuyToggle = Tabs.Settings:AddToggle("AllowItemsBuy", {
        Title = "Allow Auto Items Purchase",
        Default = false
    })

    ItemsBuyToggle:OnChanged(function(Value)
        AllowItemsBuy = Value
    end)

    local RequeueToggle = Tabs.Settings:AddToggle("ReQueueItemAfterFailedPurchase", {
        Title = "Requeue Failed Purchases",
        Default = false
    })

    RequeueToggle:OnChanged(function(Value)
        ReQueueItemAfterFailedPurchase = Value
    end)

    local BankruptcyToggle = Tabs.Settings:AddToggle("AllowStationSpendingDuringBankruptcy", {
        Title = "Allow Spending During Bankruptcy",
        Default = true
    })

    BankruptcyToggle:OnChanged(function(Value)
        AllowStationSpendingDuringBankruptcy = Value
    end)
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("GasStationGUI")
SaveManager:SetFolder("Kukuri/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

-- Event Connections
InputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.KeyCode == Enum.KeyCode.P then
            GasEnabled = not GasEnabled
            notify("Fuel enabled: "..tostring(GasEnabled), true)
        elseif input.KeyCode == Enum.KeyCode.M then
            CleaningEnabled = not CleaningEnabled
            notify("Cleaning enabled: "..tostring(CleaningEnabled), true)
        elseif input.KeyCode == Enum.KeyCode.L then
            CashierEnabled = not CashierEnabled
            notify("Cashier enabled: "..tostring(CashierEnabled), true)
        elseif input.KeyCode == Enum.KeyCode.Z then
            RestockEnabled = not RestockEnabled
            notify("Restocking enabled: "..tostring(RestockEnabled), true)
            if not RestockEnabled then
                ItemRestockQueue = {}
            end
        end
    end
end)

-- Shelf Events
local function ItemRemoved(Item : Instance, Shelf : Instance)
    if RestockEnabled then
        if Item:FindFirstChild("OriginalCFrame") then
            local OriginalCFrame = Item:FindFirstChild("OriginalCFrame").Value
            table.insert(ItemRestockQueue,{
                ["ItemShelf"] = Shelf,
                ["ItemType"] = Item.Name,
                ["ItemCFrame"] = OriginalCFrame - Vector3.new(0,Item.PrimaryPart.Size.Y/2,0),
                ["OriginalItemSize"] = Item.PrimaryPart.Size
            })
        end
    end
end

local function NewShelfAdded(shelf : Instance)
    if shelf:FindFirstChild("Content") then
        shelf.Content.ChildRemoved:connect(function(Item)
            ItemRemoved(Item,shelf)
        end)
        shelf.Content.ChildAdded:connect(function(Item)
            local OriginalCFrame = Instance.new("CFrameValue")
            OriginalCFrame.Name = "OriginalCFrame"
            OriginalCFrame.Parent = Item
            OriginalCFrame.Value = Item.PrimaryPart.CFrame
        end)
        for _,Item in pairs(shelf.Content:GetChildren()) do
            local OriginalCFrame = Instance.new("CFrameValue")
            OriginalCFrame.Name = "OriginalCFrame"
            OriginalCFrame.Parent = Item
            OriginalCFrame.Value = Item.PrimaryPart.CFrame
        end
    end
end

for _,v in pairs(ShelvesFolder:GetChildren()) do
    NewShelfAdded(v)
end
ShelvesFolder.ChildAdded:Connect(NewShelfAdded)

-- Anti-Sit Loop
task.spawn(function()
    while true do
        if not SittingEnabled then
            if LocalPlayer.Character:FindFirstChild("Humanoid") then
                if LocalPlayer.Character.Humanoid.Sit then
                    LocalPlayer.Character.Humanoid:ChangeState(3)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Restocking Queue Visualization
coroutine.wrap(function()
    local PreviousParts = {}
    while true do
        for _,v in pairs(PreviousParts) do v:Destroy() end
        for _,v in pairs(ItemRestockQueue) do
            local part = Instance.new("Part",workspace)
            part.Anchored = true
            part.Size = v["OriginalItemSize"]
            part.CFrame = v["ItemCFrame"] + Vector3.new(0,v["OriginalItemSize"].Y/2,0)
            part.Color = Color3.fromRGB(255, 0, 0)
            part.Transparency = 0.5
            table.insert(PreviousParts,part)
        end
        task.wait(0.2)
    end
end)()

-- Main Loop
coroutine.wrap(function()
    while true do
        task.wait(0.1)
        if GasEnabled then
            pcall(function()
                for _,v in pairs(workspace:GetChildren()) do
                    if v.Name:sub(1,4) == "Car_" then
                        RefuelCar(v)
                        task.wait(1)
                    end
                end
            end)
        end
        if CashierEnabled then
            pcall(function()
                for _,v in pairs(workspace.Checkouts:GetChildren()) do
                    for _,h in pairs(v.Items:GetChildren()) do
                        ScanItem(h,v)
                    end
                end
            end)
        end
        if CleaningEnabled then
            pcall(function()
                if GetPlayerStamina() < 5 then
                    RestoreEnergy(95)
                end
                for _,v in pairs(workspace.Windows:GetChildren()) do
                    if v:FindFirstChild("Attachment") then
                        if v.Attachment.Clean.Enabled then
                            if GetPlayerStamina() < 5 then
                                RestoreEnergy(95)
                            end
                            notify("Cleaning window",true)
                            TravelToCFrame(v.CFrame)
                            ActionRemote:FireServer("Clean",v.Attachment.Clean)
                            task.wait(6)
                        end
                    end
                end
                for _,v in pairs(workspace.Stains:GetChildren()) do
                    if v.Name == "Spot" then
                        if GetPlayerStamina() < 5 then
                            RestoreEnergy(95)
                        end
                        notify("Cleaning spot")
                        TravelToCFrame(v.CFrame + Vector3.new(0,3,0))
                        ActionRemote:FireServer("Clean",v.Clean)
                        task.wait(6)
                    end
                end
                for _,v in pairs(workspace.Solar.Panels:GetChildren()) do
                    local CleanPrompt = v.Stand.CleanPosition:FindFirstChild("Clean")
                    if CleanPrompt then
                        if CleanPrompt.Enabled then
                            if GetPlayerStamina() < 5 then
                                RestoreEnergy(95)
                            end
                            notify("Cleaning Solar Panels")
                            TravelToCFrame(v.Stand.CleanPosition.WorldCFrame)
                            ActionRemote:FireServer("Clean",CleanPrompt)
                            task.wait(6)
                        end
                    end
                end
            end)
        end
        if RestockEnabled then
            pcall(function()
                if #ItemRestockQueue >= 1 then
                    local ItemRestockQueueCache = ItemRestockQueue
                    ItemRestockQueue = {}
                    for _, iteminfo in pairs(ItemRestockQueueCache) do
                        if GetPlayerStamina() < 5 then
                            RestoreEnergy(95)
                        end
                        if StorageFolder:FindFirstChild(iteminfo["ItemType"]) and not IsItemBlacklisted(iteminfo["ItemType"]) then
                            local RemainingItems = StorageFolder:FindFirstChild(iteminfo["ItemType"]):GetAttribute("Storage")
                            if RemainingItems <= 0 then
                                if AllowItemsBuy then
                                    ItemShopInfo = FindItemCatergory(iteminfo["ItemType"])
                                    local Attempts = 0
                                    while true do
                                        Attempts += 1
                                        RemainingItems = StorageFolder:FindFirstChild(iteminfo["ItemType"]):GetAttribute("Storage")
                                        if RemainingItems > 0 then
                                            break
                                        end
                                        if Attempts > 5 then
                                            break
                                        end
                                        notify("Attempting to buy "..iteminfo["ItemType"],true)
                                        local Source = DecideSource(ItemShopInfo["ItemPrice"])
                                        if Source ~= nil then
                                            ActionRemote:FireServer("BuyItem",ItemShopInfo["ItemProvider"],ItemShopInfo["ItemCatergory"], iteminfo["ItemType"],Source)
                                        else
                                            notify("Failed to purchase "..iteminfo["ItemType"],true)
                                            if ReQueueItemAfterFailedPurchase then
                                                table.insert(ItemRestockQueue,iteminfo)
                                            end
                                            break
                                        end
                                        task.wait(1.5)
                                    end
                                end
                            end
                            RemainingItems = StorageFolder:FindFirstChild(iteminfo["ItemType"]):GetAttribute("Storage")
                            if RemainingItems > 0 then
                                ActionRemote:FireServer("PlaceProduct",iteminfo["ItemType"],iteminfo["ItemCFrame"],true)
                                notify("Restocked "..iteminfo["ItemType"],true)
                            else
                                notify("Failed to restock "..iteminfo["ItemType"]..", not enough stock",true)
                                if ReQueueItemAfterFailedPurchase then
                                    table.insert(ItemRestockQueue,iteminfo)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)()

-- Initial Notification
notify("Loaded!")
