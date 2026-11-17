local onDuty = false
local serviceVehicle = nil

local receptionCoords = vector3(441.79, -982.07, 30.69)

-- Rejestracja menu również wtedy, gdy zasób wystartuje po zalogowaniu gracza.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function()
        Wait(1500)
        local playerData = ESX.GetPlayerData()
        if playerData and playerData.job and playerData.job.name == 'police' then
            onDuty = true
            RegisterPoliceRadialMenu()
        end
    end)
end)
local parkingCoords = vector3(441.20, -1017.50, 28.60)
local parkingHeading = 90.0

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    if playerData and playerData.job and playerData.job.name == 'police' then
        onDuty = true
        Citizen.Wait(3000)
        SetPoliceUniform()
        SpawnPoliceCar() -- Automatyczny spawn radiowozu przy wejściu na serwer
        RegisterPoliceRadialMenu()
    end
end)

RegisterNetEvent('esx_sluzba:forceRestore')
AddEventHandler('esx_sluzba:forceRestore', function()
    onDuty = true
    Citizen.Wait(2000)
    SetPoliceUniform()
    SpawnPoliceCar() -- Automatyczny spawn radiowozu po przywróceniu sesji
    RegisterPoliceRadialMenu()
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
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
                            SetPoliceUniform()
                            SpawnPoliceCar()
                            RegisterPoliceRadialMenu()
                        else
                            RemovePoliceUniform()
                            DeletePoliceCar()
                        end
                        Citizen.Wait(1000)
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

function SetPoliceUniform()
    TriggerEvent('skinchanger:getSkin', function(skin)
        if not skin then return end
        local uniform = {}
        if skin.sex == 0 then -- Facet
            uniform = {
                ['tshirt_1'] = 58, ['tshirt_2'] = 0,
                ['torso_1'] = 55, ['torso_2'] = 0,
                ['bproof_1'] = 11, ['bproof_2'] = 1, -- Kamizelka zgodna z Config.Uniforms.bullet_wear
                ['decals_1'] = 0, ['decals_2'] = 0,
                ['arms'] = 41,
                ['pants_1'] = 25, ['pants_2'] = 0,
                ['shoes_1'] = 25, ['shoes_2'] = 0,
                ['helmet_1'] = -1, ['helmet_2'] = 0,
                ['chain_1'] = 0, ['chain_2'] = 0
            }
        else -- Kobieta
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
    local model = 'police'
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(10)
    end

    if DoesEntityExist(serviceVehicle) then
        DeleteEntity(serviceVehicle)
    end

    local vehicle = CreateVehicle(GetHashKey(model), parkingCoords.x, parkingCoords.y, parkingCoords.z + 0.5, parkingHeading, true, false)
    SetVehicleNumberPlateText(vehicle, 'LSPD ' .. math.random(100, 999))
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    
    serviceVehicle = vehicle
    ESX.ShowNotification('~b~Radiowóz~s~ został podstawiony na parking!')
    SetModelAsNoLongerNeeded(model)
end

function DeletePoliceCar()
    if DoesEntityExist(serviceVehicle) then
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
                    ESX.ShowNotification('Wybrano: ~b~Kajdanki~s~. Podepnę ich użycie do akcji zakuwania w kolejnym kroku.')
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
