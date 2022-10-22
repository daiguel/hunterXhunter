local ox_inventory = exports.ox_inventory
local allowedAnim = Config.allowedAnimals

local function canCarry(_source, itemName, amount)
    local amountToAdd = ox_inventory:CanCarryAmount(_source, itemName)
    if (amountToAdd < amount) and (amountToAdd > 0) then
        return amountToAdd
    elseif (amountToAdd > 0) then 
        return amount
    end
    TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = "inventory full" })
    return false
    
end

local function addItem(_source, itemName, amount)
    local flag = false
    ox_inventory:AddItem(_source, itemName, amount, nil, nil, function(success, reason)
        if success then
            TriggerClientEvent('ox_lib:notify', _source, { type = 'success', description = "successfully added X"..amount.." of "..itemName })
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

local function hasLicenses(identifier)
    local hasLisence = false
    for _, license in pairs(Config.licensesNeededToHunt) do
        hasLisence = MySQL.scalar.await('SELECT * FROM user_licenses WHERE owner = ? and type = ?', { identifier, license})
        if not hasLisence then
            TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = "you need "..license.." license"})
        end
    end
    return hasLisence
end

local function signalIllegalHunting(cords)
    local xPlayers = ESX.GetExtendedPlayers("job", "police")
	for _, xPlayer in pairs(xPlayers) do
        TriggerClientEvent('hunterXhunter:drawOutlaw', xPlayer.source, cords)
        TriggerClientEvent('ox_lib:notify', xPlayer.source, { type = 'error', description = "ILLEGAL HUNTING ACTIVITY LOOK MAP"})
        Config.signal()
    end
end

RegisterNetEvent('hunterXhunter:slaughter')
AddEventHandler('hunterXhunter:slaughter', function(animalNetId, entityType, hasCorns, amountOfMeatLeftToGive)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
	local identifier = xPlayer.getIdentifier() 
    local cords = xPlayer.getCoords(true)

    local entity = NetworkGetEntityFromNetworkId(animalNetId)
    local hasLisence = hasLicenses(identifier)
    local hasKnife = hasKnife(_source)
    local inLegalHuntingZone = lib.callback.await('hunterXhunter:insideLegalZone', _source)
    
    if inLegalHuntingZone then 
        print ("in Zone")
    else
        print("out zone")
        signalIllegalHunting(cords)
    end
    if hasLisence or Config.allowToHuntWithoutLicense then 
        if hasKnife or Config.allowToSlaughterWithoutKnif then 
            if DoesEntityExist(entity) then
                local addNext = true --avoid multiple messages -- adding most valuables items first 
                if hasCorns then
                    local amount = canCarry(_source, entityType.."_horns", 1)
                    if amount then
                        if lib.callback.await('hunterXhunter:showPrgressbar', _source, "collecting horns", 2) then
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
                        if lib.callback.await('hunterXhunter:showPrgressbar', _source, "collecting leather and meat", 4) then
                            addNext = addItem(_source, "meat", amount)
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
                TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = "already slaughtered" })
            end
        else
            TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = "you can't go to hunt without knife :("})
        end
    else
        TriggerClientEvent('ox_lib:notify', _source, { type = 'error', description = "you can't hunt without License"})
    end
end)

RegisterNetEvent('hunterXhunter:signalIllegalHunting')
AddEventHandler('hunterXhunter:signalIllegalHunting', function(cords)
    signalIllegalHunting(cords)
end)

RegisterNetEvent('hunterXhunter:removeOldEntity')
AddEventHandler('hunterXhunter:removeOldEntity', function(prevAnimalNedId)
    local prevAnimal = NetworkGetEntityFromNetworkId(prevAnimalNedId) --delete original entity, clone to replace 
    if DoesEntityExist(prevAnimal) then
        DeleteEntity(prevAnimal)
    end
end)

RegisterNetEvent('hunterXhunter:setAmountOfMeat')
AddEventHandler('hunterXhunter:setAmountOfMeat', function(animlaNetId, amount)
    print(animlaNetId, amount )
    local animal = NetworkGetEntityFromNetworkId(animlaNetId)
    Entity(animal).state.amountOfMeatLeftToGive = amount
end)

lib.callback.register('hunterXhunter:getAmountOfMeat', function(source, animlaNetId)
    local animal = NetworkGetEntityFromNetworkId(animlaNetId)
    local state = Entity(animal).state
    return state.amountOfMeatLeftToGive
end)

RegisterNetEvent('hunterXhunter:setAnimalCarried')
AddEventHandler('hunterXhunter:setAnimalCarried', function(animlaNetId)
    local animal = NetworkGetEntityFromNetworkId(animlaNetId)
    Entity(animal).state.carried = true
end)

RegisterNetEvent('hunterXhunter:setVehicleState')
AddEventHandler('hunterXhunter:setVehicleState', function(vehicleNetId, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    Entity(vehicle).state.full = state
end)