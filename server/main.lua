local ox_inventory = exports.ox_inventory
local animalsCarriedNetIDs = {}
local function canCarry(_source, itemName, amount)
    local amountToAdd = ox_inventory:CanCarryAmount(_source, itemName)
    if (amountToAdd < amount) and (amountToAdd > 0) then
        return amountToAdd
    elseif (amountToAdd > 0) then 
        return amount
    end
    TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = locale('inventory_full') })
    return false
    
end

local function addItem(_source, itemName, amount)
    local flag = false
    ox_inventory:AddItem(_source, itemName, amount, nil, nil, function(success, reason)
        if success then
            TriggerClientEvent('ox_lib:notify', _source, { type = 'success', description = locale('added_x')..amount..locale('of')..itemName })
            flag =  true
        else
            TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = reason })
            flag = false
        end
    end)
    return flag

end

local function hasKnife(_source)
    for _, weapon in pairs(Config.allowedKnifes) do
        if  ox_inventory:GetItem(_source, weapon, nil, true) > 0 then
            return true
        end
    end
    return false
end

local function hasLicenses(identifier, source)
    local hasLisence = false
    for _, license in pairs(Config.licensesNeededToHunt) do
        hasLisence = MySQL.scalar.await('SELECT * FROM user_licenses WHERE owner = ? and type = ?', { identifier, license})
        if not hasLisence then
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('you_need')..license..locale('license')})
        end
    end
    return hasLisence
end

lib.callback.register('hunterXhunter:slaughter', function(source, animalNetId, entityType, hasCorns, amountOfMeatLeftToGive)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
	local identifier = xPlayer.getIdentifier() 

    local entity = NetworkGetEntityFromNetworkId(animalNetId)
    local hasLisence = hasLicenses(identifier, _source)
    local hasKnife = hasKnife(_source)
    if hasLisence or Config.allowToHuntWithoutLicense then 
        if hasKnife or Config.allowToSlaughterWithoutKnif then 
            if DoesEntityExist(entity) then
                local addNext = true --avoid multiple messages -- adding most valuables items first 
                if hasCorns then
                    local amount = canCarry(_source, entityType.."_horns", 1)
                    if amount then
                        if lib.callback.await('hunterXhunter:showPrgressbar', _source, locale('collecting_horns'), 2) then
                            SetPedComponentVariation(entity, 8, 0, 0, 0) --remove horns to avoid give multiple times
                            addNext = addItem(_source, entityType.."_horns", 1)
                        else --cancel everything if progress is cancelled 
                            return false
                        end
                    end
                end
                if addNext then
                    local amount = canCarry(_source, "meat", amountOfMeatLeftToGive)
                    if amount then
                        if lib.callback.await('hunterXhunter:showPrgressbar', _source, locale('collecting_meat_and_leather'), 4) then
                            if amount > 0 then --this because adding 0 is shiting everything
                                addNext = addItem(_source, "meat", amount)
                            elseif amount == 0 then
                                addNext = true
                            end
                            if addNext then 
                                amount = amountOfMeatLeftToGive - amount
                                Entity(entity).state.amountOfMeatLeftToGive = amount
                                local amount = canCarry(_source, "leather", 1)
                                if amount then
                                    addItem(_source, "leather", 1)
                                    DeleteEntity(entity) --delete only when got all items 
                                end
                            end
                        else --cancel everything if progress is cancelled 
                            return false
                        end
                    end
                end 
            else
                TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = locale('already_slaughtered')})
            end
        else
            TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = locale('you_cant_go_to_hunt_without_knife')})
        end
    else
        TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = locale('you_cant_slaughter_without_License')})
    end
    return true
end)

RegisterNetEvent('hunterXhunter:signalIllegalHunting')
AddEventHandler('hunterXhunter:signalIllegalHunting', function(coords)
    local xPlayers = ESX.GetExtendedPlayers("job", "police")
	for _, xPlayer in pairs(xPlayers) do
        TriggerClientEvent('hunterXhunter:drawOutlaw', xPlayer.source, coords)
        Config.outlaw.signalfunc(source, coords, xPlayer.source)
    end
    
end)

RegisterNetEvent('hunterXhunter:removeOldEntity')
AddEventHandler('hunterXhunter:removeOldEntity', function(animalNetID)
    local prevAnimal = NetworkGetEntityFromNetworkId(animalNetID) --delete original entity, clone to replace 
    if DoesEntityExist(prevAnimal) then
        DeleteEntity(prevAnimal)
    end
end)

lib.callback.register('hunterXhunter:canCarry', function(source, animalNetID)
    for _, v in pairs(animalsCarriedNetIDs) do 
        if v == animalNetID then 
            return false
        end
    end
    table.insert(animalsCarriedNetIDs, animalNetID)
    local index= #animalsCarriedNetIDs
    print(index)
    print(json.encode(animalsCarriedNetIDs, {indent=true}))
    SetTimeout(2, function() 
        table.remove(animalsCarriedNetIDs, index)
        print(json.encode(animalsCarriedNetIDs, {indent=true}))
    end)
    print("tototo finished")
    return true
end)

RegisterNetEvent('hunterXhunter:setAmountOfMeat')
AddEventHandler('hunterXhunter:setAmountOfMeat', function(animlaNetId, amount)
    local animal = NetworkGetEntityFromNetworkId(animlaNetId)
    Entity(animal).state.amountOfMeatLeftToGive = amount
end)

lib.callback.register('hunterXhunter:getAmountOfMeat', function(source, animlaNetId)
    local animal = NetworkGetEntityFromNetworkId(animlaNetId)
    return Entity(animal).state.amountOfMeatLeftToGive
end)

RegisterNetEvent('hunterXhunter:setAnimalCarried')
AddEventHandler('hunterXhunter:setAnimalCarried', function(animlaNetId, status)
    local animal = NetworkGetEntityFromNetworkId(animlaNetId)
    Entity(animal).state.carried = status
end)

RegisterNetEvent('hunterXhunter:isAnimalCarried')
AddEventHandler('hunterXhunter:isAnimalCarried', function(animlaNetId)
    local animal = NetworkGetEntityFromNetworkId(animlaNetId)
    return Entity(animal).state.carried
end)

RegisterNetEvent('hunterXhunter:setVehicleState')
AddEventHandler('hunterXhunter:setVehicleState', function(vehicleNetId, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    Entity(vehicle).state.full = state
end)

lib.versionCheck('daiguel/hunterXhunter')