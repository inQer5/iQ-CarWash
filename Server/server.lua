local ESX = exports['es_extended']:getSharedObject()

-- Aktuální verze skriptu
local currentVersion = '0.0.4'

local function getLatestRelease()
    PerformHttpRequest('https://api.github.com/repos/inQer5/iQ-CarWash/releases/latest', function(statusCode, response, headers)
        if statusCode == 200 then
            local releaseInfo = json.decode(response)
            local latestVersion = releaseInfo.tag_name:match("^%s*(.-)%s*$")  -- Trim whitespace
            print("\27[31mLatest release version: " .. latestVersion .. "\27[0m")
            print("\27[32mCurrent server version: " .. currentVersion)
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
