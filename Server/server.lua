local ESX = exports['es_extended']:getSharedObject()

-- Aktuální verze skriptu
local currentVersion = '0.0.4'

local function getLatestRelease()
    PerformHttpRequest('https://api.github.com/repos/inQer5/iQ-CarWash/releases/latest', function(statusCode, response, headers)
        if statusCode == 200 then
            local releaseInfo = json.decode(response)
            local latestVersion = releaseInfo.tag_name:match("^%s*(.-)%s*$")  -- Trim whitespace
            if currentVersion == latestVersion then
                print("\27[32mYou are using the latest version!\27[0m")
            else
                print("\27[31mYour version is outdated. Please download the latest version.\27[0m")
            end
            TriggerClientEvent('carwash:checkVersion', -1, currentVersion, latestVersion)
        else
            print("Failed to fetch release info. Status code: " .. statusCode)
        end
    end, 'GET', '', {['User-Agent'] = 'lua-script'})
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        getLatestRelease()
    end
end)

ESX.RegisterServerCallback('carwash:pay', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        cb(true)
    else
        cb(false)
    end
end)
