local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local WHITELIST_URL = "http://127.0.0.1:3000/api/whitelist/check"
local EXECUTE_LOG_URL = "http://127.0.0.1:3000/api/logs/execute"

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "W hub (private)",
    Author = "by moonz",
    Icon = "grid-3x3",
    Size = UDim2.fromOffset(500, 400)
})

local licenseUnlocked = false
local mainTabsCreated = false
local lastLicenseCheck = 0
local licenseCheckInterval = 60
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
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

local function verifyWhitelist()
    local url = string.format(
        "%s?robloxUserId=%s&robloxUsername=%s&user=%s",
        WHITELIST_URL,
        HttpService:UrlEncode(tostring(player.UserId)),
        HttpService:UrlEncode(player.Name),
        HttpService:UrlEncode(player.Name)
    )

    local ok, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        return false, "Falha ao consultar a whitelist. Confira a URL e o servidor."
    end

    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodedOk or type(data) ~= "table" then
        return false, "A API respondeu algo invalido."
    end

    if not data.ok then
        return false, data.message or "Acesso nao liberado."
    end

    return true, data
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

local function sendExecuteLog(keyCode)
    if executionLogged then
        return
    end

    executionLogged = true

    local payload = {
        robloxUsername = player.Name,
        robloxUserId = tostring(player.UserId),
        key = keyCode or "n/a",
        executor = getExecutorName()
    }

    task.spawn(function()
        pcall(function()
            HttpService:PostAsync(
                EXECUTE_LOG_URL,
                HttpService:JSONEncode(payload),
                Enum.HttpContentType.ApplicationJson
            )
        end)
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
    Title = "Mostrar meu UserId",
    Desc = "Use este numero no Discord ao fazer claim da key",
    Icon = "badge-info",
    Callback = function()
        notify("Whitelist", "Seu Roblox UserId: " .. tostring(player.UserId))
    end
})

AccessTab:Button({
    Title = "Checar acesso",
    Desc = "Consulta a whitelist vinculada ao seu UserId",
    Icon = "shield-check",
    Callback = function()
        local ok, result = verifyWhitelist()
        if not ok then
            notify("Whitelist", result)
            return
        end

        licenseUnlocked = true
        lastLicenseCheck = os.clock()
        createProtectedTabs()
        sendExecuteLog(result.code)
        notify("Whitelist", "Acesso liberado ate: " .. tostring(result.expiresAt))
    end
})

task.defer(function()
    local ok, result = verifyWhitelist()
    if not ok then
        notify("Whitelist", result)
        return
    end

    licenseUnlocked = true
    lastLicenseCheck = os.clock()
    createProtectedTabs()
    sendExecuteLog(result.code)
    notify("Whitelist", "Acesso liberado ate: " .. tostring(result.expiresAt))
end)




