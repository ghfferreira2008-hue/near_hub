local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local KEY_VERIFY_URL = "https://near-hub-api.squareweb.app/api/keys/verify"
local EXECUTE_LOG_URL = "https://near-hub-api.squareweb.app/api/logs/execute"

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

local function getGuiContainers()
    return { CoreGui, playerGui }
end

local function snapshotScreenGuis()
    local snapshot = {}
    for _, container in ipairs(getGuiContainers()) do
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ScreenGui") then
                snapshot[child] = true
            end
        end
    end
    return snapshot
end

local function parentScreenGui(gui)
    local ok = pcall(function()
        gui.Parent = CoreGui
    end)
    if not ok then
        gui.Parent = playerGui
    end
end

local guisBeforeWindow = snapshotScreenGuis()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Near Hub | Premium",
    Author = "by moonz",
    Icon = "rbxassetid://75575297806121",
    Size = UDim2.fromOffset(500, 400)
})

local hubScreenGui = nil
local hubVisible = true

local function findHubScreenGui()
    if hubScreenGui and hubScreenGui.Parent then
        return hubScreenGui
    end

    for _, container in ipairs(getGuiContainers()) do
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ScreenGui") and not guisBeforeWindow[child] and child.Name ~= "NearHubToggleGui" then
                hubScreenGui = child
                return hubScreenGui
            end
        end
    end

    for _, container in ipairs(getGuiContainers()) do
        for _, child in ipairs(container:GetChildren()) do
            local name = string.lower(child.Name)
            if child:IsA("ScreenGui") and child.Name ~= "NearHubToggleGui" and (string.find(name, "wind") or string.find(name, "near")) then
                hubScreenGui = child
                return hubScreenGui
            end
        end
    end

    return nil
end

local function setHubVisible(visible)
    hubVisible = visible
    local gui = findHubScreenGui()
    if gui then
        gui.Enabled = visible
    end
end

local function createToggleButton()
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "NearHubToggleGui"
    toggleGui.ResetOnSpawn = false
    toggleGui.IgnoreGuiInset = true
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    parentScreenGui(toggleGui)

    local button = Instance.new("ImageButton")
    button.Name = "NearHubToggleButton"
    button.Size = UDim2.fromOffset(56, 56)
    button.Position = UDim2.fromOffset(18, 160)
    button.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    button.BackgroundTransparency = 0.12
    button.BorderSizePixel = 0
    button.Image = "rbxassetid://74589842007874"
    button.ScaleType = Enum.ScaleType.Fit
    button.AutoButtonColor = true
    button.ZIndex = 50
    button.Parent = toggleGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.35
    stroke.Thickness = 1
    stroke.Parent = button

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil
    local movedDuringDrag = false

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            movedDuringDrag = false
            dragStart = input.Position
            startPosition = button.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
                movedDuringDrag = true
            end
            button.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    button.Activated:Connect(function()
        if movedDuringDrag then
            return
        end
        setHubVisible(not hubVisible)
    end)
end

createToggleButton()
local licenseUnlocked = false
local mainTabsCreated = false
local lastLicenseCheck = 0
local licenseCheckInterval = 60
local executionLogged = false

local function notify(title, content)
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = 6
        })
        return
    end

    warn(string.format("[%s] %s", title, content))
end

local function getProvidedKey()
    local key = nil

    pcall(function()
        if getgenv then
            key = getgenv().script_key
        end
    end)

    if (not key or tostring(key) == "") and script_key then
        key = script_key
    end

    key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
        return nil
    end

    return key
end

local currentKey = getProvidedKey()

local function verifyWhitelist()
    currentKey = getProvidedKey()
    if not currentKey then
        warn("[Near Hub] nenhuma script_key foi encontrada antes da verificacao")
        return false, "invalid key", "missing_script_key"
    end

    local url = string.format(
        "%s?key=%s&robloxUserId=%s&robloxUsername=%s&user=%s",
        KEY_VERIFY_URL,
        HttpService:UrlEncode(currentKey),
        HttpService:UrlEncode(tostring(player.UserId)),
        HttpService:UrlEncode(player.Name),
        HttpService:UrlEncode(player.Name)
    )

    warn("[Near Hub] verificando key na API: " .. KEY_VERIFY_URL)

    local ok, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        return false, "invalid key", "http_failed", tostring(response)
    end

    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodedOk or type(data) ~= "table" then
        return false, "invalid key", "json_decode_failed", tostring(response)
    end

    if not data.ok then
        return false, "invalid key", data.state or "api_rejected", data.message or "n/a"
    end

    return true, data
end

local function formatKeyTime(result)
    if result.durationType == "permanente" or result.expiresAt == nil then
        return "Permanente"
    end

    local remaining = tonumber(result.remainingSeconds) or 0
    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    end

    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end

    return string.format("%dm", minutes)
end

local function getExecutorName()
    local ok, result = pcall(function()
        if identifyexecutor then
            return identifyexecutor()
        end

        return "Unknown"
    end)

    if ok and result then
        return tostring(result)
    end

    return "Unknown"
end

local function getRequestFunction()
    if syn and syn.request then
        return syn.request
    end

    if http and http.request then
        return http.request
    end

    if http_request then
        return http_request
    end

    if request then
        return request
    end

    return nil
end

local function sendExecuteLog(keyCode)
    if executionLogged then
        return
    end

    local payload = {
        robloxUsername = player.Name,
        robloxUserId = tostring(player.UserId),
        key = keyCode or "n/a",
        executor = getExecutorName()
    }

    local jsonPayload = HttpService:JSONEncode(payload)

    task.spawn(function()
        local requestFunction = getRequestFunction()
        if requestFunction then
            local requestOk = pcall(function()
                requestFunction({
                    Url = EXECUTE_LOG_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonPayload
                })
            end)

            if requestOk then
                executionLogged = true
                return
            end
        end

        local postOk = pcall(function()
            HttpService:PostAsync(
                EXECUTE_LOG_URL,
                jsonPayload,
                Enum.HttpContentType.ApplicationJson
            )
        end)

        if postOk then
            executionLogged = true
            return
        end

        local fallbackUrl = string.format(
            "%s?robloxUsername=%s&robloxUserId=%s&key=%s&executor=%s",
            EXECUTE_LOG_URL,
            HttpService:UrlEncode(payload.robloxUsername),
            HttpService:UrlEncode(payload.robloxUserId),
            HttpService:UrlEncode(payload.key),
            HttpService:UrlEncode(payload.executor)
        )

        local getOk = pcall(function()
            return game:HttpGet(fallbackUrl)
        end)

        if getOk then
            executionLogged = true
        else
            warn("[Near Hub] Nao foi possivel enviar o log de execucao.")
        end
    end)
end

local function canUseProtectedFeature()
    if not licenseUnlocked then
        notify("License", "Valide a key antes de usar as funcoes.")
        return false
    end

    if os.clock() - lastLicenseCheck < licenseCheckInterval then
        return true
    end

    local ok, result = verifyWhitelist()
    lastLicenseCheck = os.clock()

    if not ok then
        licenseUnlocked = false
        notify("Whitelist", "Acesso expirado ou removido. As funcoes foram bloqueadas.")
        return false
    end

    return true
end

local function createProtectedTabs()
    if mainTabsCreated then
        return
    end

    mainTabsCreated = true

    local Tab = Window:Tab({
        Title = "Main",
        Icon = "star"
    })

    local autoFarm1 = false

    Tab:Toggle({
        Title = "Auto Ranked Reward",
        Default = false,
        Callback = function(state)
            if state and not canUseProtectedFeature() then
                return
            end

            autoFarm1 = state

            if autoFarm1 then
                task.spawn(function()
                    while autoFarm1 and licenseUnlocked do
                        if not canUseProtectedFeature() then
                            autoFarm1 = false
                            break
                        end

                        local args = {1}

                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Packages")
                            :WaitForChild("_Index")
                            :WaitForChild("sleitnick_knit@1.7.0")
                            :WaitForChild("knit")
                            :WaitForChild("Services")
                            :WaitForChild("SeasonService")
                            :WaitForChild("RF")
                            :WaitForChild("RequestRankedReward")
                            :InvokeServer(unpack(args))

                        task.wait(1)
                    end
                end)
            end
        end
    })

    local autoFarm2 = false

    Tab:Toggle({
        Title = "auto ranked rewards (g3)",
        Default = false,
        Callback = function(state)
            if state and not canUseProtectedFeature() then
                return
            end

            autoFarm2 = state

            if autoFarm2 then
                task.spawn(function()
                    while autoFarm2 and licenseUnlocked do
                        if not canUseProtectedFeature() then
                            autoFarm2 = false
                            break
                        end

                        local args = {7}

                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Packages")
                            :WaitForChild("_Index")
                            :WaitForChild("sleitnick_knit@1.7.0")
                            :WaitForChild("knit")
                            :WaitForChild("Services")
                            :WaitForChild("SeasonService")
                            :WaitForChild("RF")
                            :WaitForChild("RequestRankedReward")
                            :InvokeServer(unpack(args))

                        task.wait(1)
                    end
                end)
            end
        end
    })

    local AdvancedTab = Window:Tab({
        Title = "Advanced",
        Icon = "settings"
    })

    local rewardInput = ""
    local autoCustom = false

    AdvancedTab:Input({
        Title = "Escreva o numero da reward",
        Placeholder = "Ex: 1,3,4",
        Callback = function(text)
            rewardInput = text
        end
    })

    local function parseNumbers(text)
        local numbers = {}

        for num in string.gmatch(text, "%d+") do
            table.insert(numbers, tonumber(num))
        end

        return numbers
    end

    AdvancedTab:Toggle({
        Title = "Auto Custom Reward",
        Default = false,
        Callback = function(state)
            if state and not canUseProtectedFeature() then
                return
            end

            autoCustom = state

            if autoCustom then
                task.spawn(function()
                    while autoCustom and licenseUnlocked do
                        if not canUseProtectedFeature() then
                            autoCustom = false
                            break
                        end

                        local lista = parseNumbers(rewardInput)

                        for _, value in ipairs(lista) do
                            local args = {value}

                            game:GetService("ReplicatedStorage")
                                :WaitForChild("Packages")
                                :WaitForChild("_Index")
                                :WaitForChild("sleitnick_knit@1.7.0")
                                :WaitForChild("knit")
                                :WaitForChild("Services")
                                :WaitForChild("SeasonService")
                                :WaitForChild("RF")
                                :WaitForChild("RequestRankedReward")
                                :InvokeServer(unpack(args))

                            task.wait(0.1)
                        end

                        task.wait(1)
                    end
                end)
            end
        end
    })
end

local AccessTab = Window:Tab({
    Title = "Whitelist",
    Icon = "shield-check"
})

AccessTab:Button({
    Title = "Checar Key",
    Desc = "Mostra quanto tempo ainda falta na sua key",
    Icon = "shield-check",
    Callback = function()
        local ok, result, reason, detail = verifyWhitelist()
        if not ok then
            warn("[Near Hub] invalid key: " .. tostring(reason) .. " | " .. tostring(detail))
            notify("Whitelist", "invalid key")
            return
        end

        licenseUnlocked = true
        lastLicenseCheck = os.clock()
        createProtectedTabs()
        notify("Whitelist", "Tempo restante: " .. formatKeyTime(result))
    end
})

task.defer(function()
    local ok, result, reason, detail = verifyWhitelist()
    if not ok then
        warn("[Near Hub] invalid key: " .. tostring(reason) .. " | " .. tostring(detail))
        player:Kick("invalid key")
        return
    end

    licenseUnlocked = true
    lastLicenseCheck = os.clock()
    createProtectedTabs()
end)

















