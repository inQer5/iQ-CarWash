local ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('carwash:pay', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        cb(true)
    else
        cb(false)
    end
end)
