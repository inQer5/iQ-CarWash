local ESX = exports['es_extended']:getSharedObject()

local carWashBlip = {
    pos = vector3(176.13, -1736.74, 28.70),
    blip = nil
}

local isInRange = false

Citizen.CreateThread(function()
    carWashBlip.blip = AddBlipForCoord(carWashBlip.pos)
    SetBlipSprite(carWashBlip.blip, 100)
    SetBlipDisplay(carWashBlip.blip, 4)
    SetBlipScale(carWashBlip.blip, 0.8)
    SetBlipColour(carWashBlip.blip, 3)
    SetBlipAsShortRange(carWashBlip.blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Automyčka")
    EndTextCommandSetBlipName(carWashBlip.blip)
end)

local function openCarWashMenu()
    exports.ox_lib:registerContext({
        id = 'car_wash_menu',
        title = 'Automyčka',
        options = {
            {
                title = 'Standardní',
                description = 'Cena: 500$',
                icon = 'fa-solid fa-angle-right',
                event = 'carwash:startWashing',
                args = { type = 'standard', price = 500 }
            },
            {
                title = 'Luxusní',
                description = 'Cena: 1000$',
                icon = 'fa-solid fa-angle-right',
                event = 'carwash:startWashing',
                args = { type = 'luxury', price = 1000 }
            }
        }
    })
    exports.ox_lib:showContext('car_wash_menu')
end

RegisterNetEvent('carwash:startWashing')
AddEventHandler('carwash:startWashing', function(data)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        exports.ox_lib:notify({title = 'Chyba', description = 'Musíte být ve vozidle.', type = 'error'})
        return
    end

    FreezeEntityPosition(vehicle, true)  -- Zamrznutí vozidla

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
            Citizen.Wait(15000)  -- Délka mytí

            exports.ox_lib:notify({title = 'Úspěch', description = 'Vaše vozidlo bylo umyto.', type = 'success'})
            DeletePed(npc)
            SetVehicleDirtLevel(vehicle, 0.0)
        else
            exports.ox_lib:notify({title = 'Chyba', description = 'Nemáte dostatek peněz.', type = 'error'})
        end

        FreezeEntityPosition(vehicle, false)  -- Odblokování vozidla
    end, data.price)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - carWashBlip.pos)

        if distance < 10.0 and not isInRange then
            isInRange = true
            while distance < 10.0 do
                Citizen.Wait(5)
                playerCoords = GetEntityCoords(playerPed)
                distance = #(playerCoords - carWashBlip.pos)
                
                DrawMarker(1, carWashBlip.pos.x, carWashBlip.pos.y, carWashBlip.pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 0.5, 0, 255, 0, 100, false, true, 2, nil, nil, false)

                if distance < 2.5 then
                    exports.ox_lib:showTextUI('Otevřít menu automyčky', {
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
                    exports.ox_lib:hideTextUI()
                end
            end
        elseif distance >= 10.0 and isInRange then
            isInRange = false
            exports.ox_lib:hideTextUI()
        end
    end
end)
