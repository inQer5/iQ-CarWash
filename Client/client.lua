local ESX = exports['es_extended']:getSharedObject()
local Config = Config or {}

-- Načítání lokalizace
local function loadLocale(locale)
    local localeFile = ('Locales/%s.lua'):format(locale)
    if not LoadResourceFile(GetCurrentResourceName(), localeFile) then
        print(('Locale file for "%s" does not exist. Falling back to default "en".'):format(locale))
        locale = 'en'
        localeFile = 'Locales/en.lua'
    end
    local locales = LoadResourceFile(GetCurrentResourceName(), localeFile)
    assert(load(locales))()
end

-- Funkce pro načtení lokalizačních textů
local function _U(entry, ...)
    if Locales[entry] then
        return string.format(Locales[entry], ...)
    else
        return entry
    end
end

-- Načíst lokalizaci při startu
loadLocale(Config.Locale)

local carWashBlips = {}
local isInRange = false
local currentCarWash = nil

local function isCarWashOpen()
    local hour = GetClockHours()
    return (hour >= Config.OpenHours.open and hour < Config.OpenHours.close)
end

local function createCarWashBlips()
    for i, loc in ipairs(Config.Locations) do
        local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(blip, 100)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(_U('car_wash'))
        EndTextCommandSetBlipName(blip)
        table.insert(carWashBlips, {blip = blip, pos = vector3(loc.x, loc.y, loc.z)})
    end
end

local function openCarWashMenu()
    if currentCarWash then
        exports.ox_lib:registerContext({
            id = 'car_wash_menu',
            title = _U('car_wash'),
            options = {
                {
                    title = _U('standard'),
                    description = _U('price') .. Config.Prices.standard,
                    icon = 'fa-solid fa-angle-right',
                    event = 'carwash:startWashing',
                    args = { type = 'standard', price = Config.Prices.standard }
                },
                {
                    title = _U('luxury'),
                    description = _U('price') .. Config.Prices.luxury,
                    icon = 'fa-solid fa-angle-right',
                    event = 'carwash:startWashing',
                    args = { type = 'luxury', price = Config.Prices.luxury }
                }
            }
        })
        exports.ox_lib:showContext('car_wash_menu')
    end
end

RegisterNetEvent('carwash:startWashing')
AddEventHandler('carwash:startWashing', function(data)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        exports.ox_lib:notify({title = _U('error'), description = _U('error_vehicle'), type = 'error'})
        return
    end

    FreezeEntityPosition(vehicle, true)

    ESX.TriggerServerCallback('carwash:pay', function(success)
        if success then
            local npcModel = data.type == 'standard' and 'a_m_m_beach_02' or 'a_f_y_beach_02'
            RequestModel(npcModel)
            while not HasModelLoaded(npcModel) do
                Citizen.Wait(0)
            end

            local playerCoords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local spawnDistance = 6.0
            local spawnAngle = math.rad(math.random(0, 360))
            local spawnOffsetX = math.cos(spawnAngle) * spawnDistance
            local spawnOffsetY = math.sin(spawnAngle) * spawnDistance
            local spawnCoords = vector3(playerCoords.x + spawnOffsetX, playerCoords.y + spawnOffsetY, playerCoords.z)

            local npc = CreatePed(4, npcModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, true)
            TaskGoToEntity(npc, vehicle, -1, 2.0, 2.0, 1073741824, 0)

            local isNpcNearVehicle = false
            while not isNpcNearVehicle do
                Citizen.Wait(100)
                local npcCoords = GetEntityCoords(npc)
                local vehicleCoords = GetEntityCoords(vehicle)
                local distance = #(npcCoords - vehicleCoords)
                if distance < 3.0 then
                    isNpcNearVehicle = true
                end
            end

            TaskTurnPedToFaceEntity(npc, vehicle, -1)
            Citizen.Wait(400)

            TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_MAID_CLEAN', 0, true)

            exports.ox_lib:progressCircle({
                duration = 15000,
                position = 'bottom',
                label = _U('washing'),
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = true,
                }
            })

            Citizen.Wait(500)

            exports.ox_lib:notify({title = _U('success'), description = _U('success_wash'), type = 'success'})
            DeletePed(npc)
            SetVehicleDirtLevel(vehicle, 0.0)
        else
            exports.ox_lib:notify({title = _U('error'), description = _U('error_money'), type = 'error'})
        end

        FreezeEntityPosition(vehicle, false)
    end, data.price)
end)

Citizen.CreateThread(function()
    createCarWashBlips()

    while true do
        Citizen.Wait(5)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isInRangeAny = false

        for _, blip in pairs(carWashBlips) do
            local distance = #(playerCoords - blip.pos)

            if distance < 10.0 then
                isInRangeAny = true
                if distance < 4.0 then
                    currentCarWash = blip
                    if isCarWashOpen() then
                        exports.ox_lib:showTextUI(_U('open_menu'), {
                            position = "right-center",
                            icon = 'hand',
                            style = {
                                borderRadius = 5,
                                color = 'white'
                            }
                        })
                        if IsControlJustReleased(0, 38) then
                            openCarWashMenu()
                        end
                    else
                        exports.ox_lib:showTextUI(_U('closed', Config.OpenHours.open, Config.OpenHours.close), {
                            position = "right-center",
                            icon = 'lock',
                            style = {
                                borderRadius = 5,
                                color = 'red'
                            }
                        })
                    end
                else
                    exports.ox_lib:hideTextUI()
                end
            end
        end

        if not isInRangeAny then
            currentCarWash = nil
            exports.ox_lib:hideTextUI()
        end

        isInRange = isInRangeAny
    end
end)
