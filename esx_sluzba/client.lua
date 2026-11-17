local onDuty = false
local serviceVehicle = nil

-- Nielimitowana amunicja wyłącznie dla broni służbowej podczas służby.
local policeServiceWeapons = {
    'WEAPON_COMBATPISTOL',
    'WEAPON_NIGHTSTICK',
    'WEAPON_STUNGUN',
    'WEAPON_FLASHLIGHT'
}

local function SetPoliceInfiniteAmmo(enabled)
    local ped = PlayerPedId()
    for _, weaponName in ipairs(policeServiceWeapons) do
        SetPedInfiniteAmmo(ped, enabled, GetHashKey(weaponName))
    end
end


local receptionCoords = vector3(441.79, -982.07, 30.69)

local restoringDuty = false

local function RestorePoliceDuty()
    if restoringDuty then return end
    restoringDuty = true
    onDuty = true
    SetPoliceInfiniteAmmo(true)

    CreateThread(function()
        Wait(1000)
        SetPoliceUniform()
        SpawnPoliceCar()
        RegisterPoliceRadialMenu()
        restoringDuty = false
    end)
end

-- Główne przywracanie wysyła serwer po załadowaniu postaci.
-- Ten fallback obsługuje restart samego zasobu, gdy gracz jest już na serwerze.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function()
        Wait(2500)
        local playerData = ESX.GetPlayerData()
        local dutyState = LocalPlayer and LocalPlayer.state and LocalPlayer.state.policeDuty
        if playerData and playerData.job and playerData.job.name == 'police' and dutyState ~= false then
            RestorePoliceDuty()
        end
    end)
end)

RegisterNetEvent('esx_sluzba:forceRestore', RestorePoliceDuty)

RegisterNetEvent('esx_sluzba:dutyEnded', function()
    onDuty = false
    SetPoliceInfiniteAmmo(false)
    RemovePoliceUniform()
    DeletePoliceCar()
    if lib and lib.removeRadialItem then
        lib.removeRadialItem('police_root')
    end
end)

local parkingCoords = vector3(441.20, -1017.50, 28.60)
local parkingHeading = 90.0

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerData = ESX and ESX.GetPlayerData()
        local isPolice = playerData and playerData.job and playerData.job.name == 'police'

        if isPolice then
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                local coords = GetEntityCoords(playerPed)
                local dist = #(coords - receptionCoords)

                if dist < 10.0 then
                    sleep = 0
                    DrawMarker(1, receptionCoords.x, receptionCoords.y, receptionCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.5, 0, 100, 255, 150, false, true, 2, false, nil, nil, false)

                    if dist < 1.5 then
                        local text = onDuty and 'Naciśnij ~INPUT_CONTEXT~ aby ~r~zakończyć~s~ służbę' or 'Naciśnij ~INPUT_CONTEXT~ aby ~b~rozpocząć~s~ służbę'
                        ESX.ShowHelpNotification(text)

                        if IsControlJustReleased(0, 38) then
                            onDuty = not onDuty
                            TriggerServerEvent('esx_sluzba:setDuty', onDuty)

                            if onDuty then
                                SetPoliceInfiniteAmmo(true)
                                -- Serwer potwierdza rozpoczęcie i wywołuje forceRestore.
                            else
                                SetPoliceInfiniteAmmo(false)
                                RemovePoliceUniform()
                                DeletePoliceCar()
                                if lib and lib.removeRadialItem then
                                    lib.removeRadialItem('police_root')
                                end
                            end
                            Wait(1000)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function SetPoliceUniform()
    CreateThread(function()
        for attempt = 1, 20 do
            if GetResourceState('skinchanger') == 'started' then
                local skin, received = nil, false
                TriggerEvent('skinchanger:getSkin', function(currentSkin)
                    skin = currentSkin
                    received = true
                end)

                local timeout = GetGameTimer() + 2500
                while not received and GetGameTimer() < timeout do
                    Wait(50)
                end

                if type(skin) == 'table' then
                    local uniform = {}
                    if skin.sex == 0 then
                        uniform = {
                            ['tshirt_1'] = 58, ['tshirt_2'] = 0,
                            ['torso_1'] = 55, ['torso_2'] = 0,
                            ['bproof_1'] = 11, ['bproof_2'] = 1,
                            ['decals_1'] = 0, ['decals_2'] = 0,
                            ['arms'] = 41,
                            ['pants_1'] = 25, ['pants_2'] = 0,
                            ['shoes_1'] = 25, ['shoes_2'] = 0,
                            ['helmet_1'] = -1, ['helmet_2'] = 0,
                            ['chain_1'] = 0, ['chain_2'] = 0
                        }
                    else
                        uniform = {
                            ['tshirt_1'] = 35, ['tshirt_2'] = 0,
                            ['torso_1'] = 48, ['torso_2'] = 0,
                            ['bproof_1'] = 11, ['bproof_2'] = 1,
                            ['decals_1'] = 0, ['decals_2'] = 0,
                            ['arms'] = 44,
                            ['pants_1'] = 34, ['pants_2'] = 0,
                            ['shoes_1'] = 27, ['shoes_2'] = 0,
                            ['helmet_1'] = -1, ['helmet_2'] = 0,
                            ['chain_1'] = 0, ['chain_2'] = 0
                        }
                    end

                    TriggerEvent('skinchanger:loadClothes', skin, uniform)
                    return
                end
            end
            Wait(500)
        end

        if ESX and ESX.ShowNotification then
            ESX.ShowNotification('~r~Nie udało się załadować skórki do munduru. Sprawdź skinchanger.~s~')
        end
    end)
end

function RemovePoliceUniform()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        if skin then
            TriggerEvent('skinchanger:loadSkin', skin)
        end
    end)
end

function SpawnPoliceCar()
    CreateThread(function()
        local modelHash = joaat('police3')

        if serviceVehicle and serviceVehicle ~= 0 and DoesEntityExist(serviceVehicle) then
            DeleteEntity(serviceVehicle)
            serviceVehicle = nil
        end

        RequestModel(modelHash)
        local timeout = GetGameTimer() + 15000
        while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
            Wait(50)
        end

        if not HasModelLoaded(modelHash) then
            ESX.ShowNotification('~r~Nie udało się załadować modelu radiowozu police3.~s~')
            return
        end

        local vehicle = CreateVehicle(modelHash, parkingCoords.x, parkingCoords.y, parkingCoords.z + 0.5, parkingHeading, true, true)
        if vehicle == 0 or not DoesEntityExist(vehicle) then
            ESX.ShowNotification('~r~Nie udało się utworzyć radiowozu.~s~')
            SetModelAsNoLongerNeeded(modelHash)
            return
        end

        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleNumberPlateText(vehicle, 'LSPD ' .. math.random(100, 999))
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDoorsLocked(vehicle, 1)

        serviceVehicle = vehicle
        ESX.ShowNotification('~b~Radiowóz~s~ został podstawiony na parking!')
        SetModelAsNoLongerNeeded(modelHash)
    end)
end

function DeletePoliceCar()
    if serviceVehicle and serviceVehicle ~= 0 and DoesEntityExist(serviceVehicle) then
        DeleteEntity(serviceVehicle)
        serviceVehicle = nil
    end
end

local selectedPoliceEquipment = nil

local function SelectPoliceWeapon(label, weaponName)
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)

    if not HasPedGotWeapon(ped, weaponHash, false) then
        ESX.ShowNotification('~r~Nie masz tego wyposażenia. Zgłoś się po nie do zbrojowni.~s~')
        return
    end

    SetCurrentPedWeapon(ped, weaponHash, true)
    selectedPoliceEquipment = label
    ESX.ShowNotification('Wybrano: ~b~' .. label .. '~s~')
end

function RegisterPoliceRadialMenu()
    if not lib or not lib.registerRadial or not lib.addRadialItem then
        ESX.ShowNotification('~r~Nie można uruchomić menu kołowego ox_lib!~s~')
        return
    end

    lib.registerRadial({
        id = 'police_equipment_radial',
        items = {
            {
                label = 'Pistolet służbowy',
                icon = 'gun',
                onSelect = function()
                    SelectPoliceWeapon('Pistolet służbowy', 'WEAPON_COMBATPISTOL')
                end
            },
            {
                label = 'Pałka policyjna',
                icon = 'wand-magic-sparkles',
                onSelect = function()
                    SelectPoliceWeapon('Pałka policyjna', 'WEAPON_NIGHTSTICK')
                end
            },
            {
                label = 'Taser',
                icon = 'bolt',
                onSelect = function()
                    SelectPoliceWeapon('Taser', 'WEAPON_STUNGUN')
                end
            },
            {
                label = 'Latarka',
                icon = 'flashlight',
                onSelect = function()
                    SelectPoliceWeapon('Latarka', 'WEAPON_FLASHLIGHT')
                end
            },
            {
                label = 'Kajdanki',
                icon = 'handcuffs',
                onSelect = function()
                    selectedPoliceEquipment = 'Kajdanki'
                    SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)

                    local closestPlayer = -1
                    local closestDistance = 3.0
                    local myCoords = GetEntityCoords(PlayerPedId())

                    for _, playerId in ipairs(GetActivePlayers()) do
                        if playerId ~= PlayerId() then
                            local targetPed = GetPlayerPed(playerId)
                            if DoesEntityExist(targetPed) then
                                local distance = #(myCoords - GetEntityCoords(targetPed))
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestPlayer = playerId
                                end
                            end
                        end
                    end

                    if closestPlayer == -1 then
                        ESX.ShowNotification('Wybrano: ~b~Kajdanki~s~. Brak osoby w zasięgu 3 metrów.')
                        return
                    end

                    if GetResourceState('esx_policejob') ~= 'started' then
                        ESX.ShowNotification('~r~System zakuwania esx_policejob nie jest uruchomiony.~s~')
                        return
                    end

                    TriggerServerEvent('esx_policejob:handcuff', GetPlayerServerId(closestPlayer))
                    ESX.ShowNotification('Używasz ~b~kajdanek~s~.')
                end
            }
        }
    })

    lib.registerRadial({
        id = 'police_duty_radial',
        items = {
            {
                label = 'Wyposażenie policjanta',
                icon = 'toolbox',
                menu = 'police_equipment_radial'
            },
            {
                label = 'Wyjedź radiowozem',
                icon = 'car',
                onSelect = function()
                    SpawnPoliceCar()
                end
            },
            {
                label = 'Załóż mundur',
                icon = 'vest',
                onSelect = function()
                    SetPoliceUniform()
                    ESX.ShowNotification('~b~Odświeżono mundur!~s~')
                end
            },
            {
                label = 'Zakończ służbę',
                icon = 'right-from-bracket',
                onSelect = function()
                    onDuty = false
                    SetPoliceInfiniteAmmo(false)
                    TriggerServerEvent('esx_sluzba:setDuty', false)
                    RemovePoliceUniform()
                    DeletePoliceCar()
                    lib.removeRadialItem('police_root')
                end
            }
        }
    })

    lib.removeRadialItem('police_root')
    lib.addRadialItem({
        id = 'police_root',
        label = 'Policja',
        icon = 'shield-halved',
        menu = 'police_duty_radial'
    })
end


-- Otwieranie menu policjanta rolką myszy w dół.
-- Blokujemy natywne przewijanie broni GTA podczas służby, aby nie otwierało się koło broni.
CreateThread(function()
    while true do
        if onDuty then
            DisableControlAction(0, 14, true) -- przewijanie rolką w dół
            DisableControlAction(0, 15, true) -- przewijanie rolką w górę

            if IsDisabledControlJustPressed(0, 14) then
                if lib and lib.showRadialMenu and lib.getCurrentRadialId then
                    if not lib.getCurrentRadialId() then
                        lib.showRadialMenu('police_duty_radial')
                    end
                else
                    ESX.ShowNotification('~r~Menu ox_lib nie jest dostępne.~s~')
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
