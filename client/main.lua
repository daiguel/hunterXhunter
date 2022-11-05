local allowedAnimals = {}
local ox_target = exports.ox_target
local insideLegalZone = false
local canHuntOutSideLegalZone = Config.allowToHuntOutSideZone
local carriying = false
local lastEntity = nil
local slaughterhouse = Config.slaughterhouse
local insideSlaughterhouseZone = false 
local outalwBlipSprite, outlawBlipColor, outlawBlipScale = Config.outlaw.blipSprite, Config.outlaw.blipColor, Config.outlaw.blipScale
local outlawDrawBlipTimeout = Config.outlaw.drawBlipTimeout

local function createBlip(coords, bigAreaColor, distance, blipSprite, blipColor, blipScale , type , text)
    if type == "area" then
        local blip = AddBlipForRadius(coords, distance) -- need to have .0
        SetBlipColour(blip, bigAreaColor)
        SetBlipAlpha(blip, 128)
    end 

    local blip2 = AddBlipForCoord(coords)
    SetBlipSprite(blip2, blipSprite)
	SetBlipDisplay(blip2, 4)
	SetBlipScale(blip2, blipScale)
	SetBlipColour(blip2, blipColor)
	SetBlipAsShortRange(blip2, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandSetBlipName(blip2)
    return blip, blip2
end

local function setSlaughterHouse()

    createBlip(slaughterhouse.coords, slaughterhouse.bigAreaColor, slaughterhouse.distance, slaughterhouse.blipSprite, slaughterhouse.blipColor, slaughterhouse.blipScale, "simple", Config.slaughterhouse.blipName)
    
    local slaughterHousePoint = lib.points.new(slaughterhouse.coords, slaughterhouse.distance, { name = 'slaughterhouse'})
    local r, g, b = table.unpack(slaughterhouse.markerColor)
    local slaughterRange = 5
    local marker = Config.slaughterhouse.marker
    
    function slaughterHousePoint:nearby()
		DrawMarker(marker, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, r, g, b, 50, true, true, 2, nil, nil, false)
		if (self.currentDistance <= slaughterRange)  then --activate deactivate slaughter 
			insideSlaughterhouseZone = true 
		end
		if (self.currentDistance > slaughterRange) then 
			insideSlaughterhouseZone = false 
		end
       
    end
    
    function slaughterHousePoint:onExit() -- when tp's out 
        insideSlaughterhouseZone = false
    end
end

local function setHuntingZone(areas)
    for _, area in pairs(areas) do
        createBlip(area.coords, area.bigAreaColor, area.distance, area.blipSprite, area.blipColor, area.blipScale, "area", area.blipName)
        
        local huntingPoint = lib.points.new(area.coords, area.distance, { name = 'legal hunting area'})
        
        function huntingPoint:onEnter()
            insideLegalZone = true
        end
        
        function huntingPoint:onExit()
            insideLegalZone = false
        end
    end
end

local function getListOfAllowedAnimals()
    for key,_ in pairs(Config.allowedAnimals) do
        table.insert(allowedAnimals, key)
    end
end

local function getAnimalModel(entity)
    local hash = GetEntityModel(entity)
    for _, animal in pairs(allowedAnimals) do 
        if GetHashKey(animal)==hash then
            return animal 
        end
    end
end

local function loadanimdict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end

local function slaughter(data)
    carriying = true
    local hasHorns=false
    local animalType = getAnimalModel(data.entity)
    local netEntity = NetworkGetNetworkIdFromEntity(data.entity)
    local minMeat = Config.allowedAnimals[animalType].minMeatAmount
    local maxMeat = Config.allowedAnimals[animalType].maxMeatAmount
    local amountOfMeatLeftToGive = lib.callback.await('hunterXhunter:getAmountOfMeat', false, NetworkGetNetworkIdFromEntity(data.entity))
    if not amountOfMeatLeftToGive then 
        amountOfMeatLeftToGive = math.random(minMeat , maxMeat)
        TriggerServerEvent('hunterXhunter:setAmountOfMeat', NetworkGetNetworkIdFromEntity(data.entity), amountOfMeatLeftToGive)
    end
    if GetPedDrawableVariation(data.entity, 8)==1 then
        hasHorns = true
    end   
    local wait = lib.callback.await('hunterXhunter:slaughter', false, netEntity, animalType, hasHorns, amountOfMeatLeftToGive) --wait end of opertions
    carriying = false
end

local function desableEnteringVehicle()
    CreateThread(function ()
        lib.disableControls:Add(23)
        while carriying do
            Wait(0)
            lib.disableControls()
        end
        lib.disableControls:Clear(23)
    end)
end

local function animalPositionBasedOnPed(entity)
    local animalType =  getAnimalModel(entity)
    local xPos, zPos
    if animalType=="a_c_deer" or animalType=="a_c_cow" then
        zPos = 1.53
        xPos = 0.35
    elseif  animalType=="a_c_boar" then
        zPos = 0.91 
        xPos = -0.29
    elseif  animalType=="a_c_coyote" then
        zPos = 0.91 
        xPos = 0.24
    elseif  animalType=="a_c_rabbit_01" then
        zPos = 0.61 
        xPos = 0.34
    elseif  animalType=="a_c_mtlion" then
        zPos = 1.01 
        xPos = 0.30
    else
        zPos = 0.61 
        xPos = 0.30
    end
    return zPos, xPos
end

local function carry(data)

    local entity = data.entity
    local vehicleId = GetEntityAttachedTo(entity) -- block to set vehicle to empty
    local amountOfMeatLeftToGive = lib.callback.await('hunterXhunter:getAmountOfMeat', false, NetworkGetNetworkIdFromEntity(entity))

    if vehicleId then
        TriggerServerEvent('hunterXhunter:setVehicleState', NetworkGetNetworkIdFromEntity(vehicleId), nil) --set vehicle empty
    end
    carriying = true
    desableEnteringVehicle()
    DetachEntity(entity, true, true)-- when attached to vehicle
    local cords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local x, y, z = table.unpack(cords)
    local clone = ClonePed(entity, true, false, true)
    lastEntity = clone
    TriggerServerEvent("hunterXhunter:removeOldEntity", NetworkGetNetworkIdFromEntity(entity)) -- delete old animal that freezes
    
    TriggerServerEvent("hunterXhunter:setAnimalCarried", NetworkGetNetworkIdFromEntity(clone), true) 
    TriggerServerEvent('hunterXhunter:setAmountOfMeat', NetworkGetNetworkIdFromEntity(clone), amountOfMeatLeftToGive) --copy amount of meat to clone
    
    SetEntityCoords(clone, x, y, z, false, false, true, false)
    SetEntityHeading(clone, heading)

    local zPos , xPos = animalPositionBasedOnPed(clone)
    
    AttachEntityToEntity(clone, PlayerPedId(), 0, xPos, 0.0, zPos, 0.5, 0.5, 0.0, false, false, false, false, 2, true) -- z=0.63 
    SetEntityCollision(clone, true, false)

    loadanimdict('missfinale_c2mcs_1')
    TaskPlayAnim(PlayerPedId(), 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, 100000, 49, 0, false, false, false)
end

local function drop(data)
    lastEntity = nil
    carriying = false
    local entity = data.entity
    DetachEntity(entity, true, true)
    TriggerServerEvent("hunterXhunter:setAnimalCarried", NetworkGetNetworkIdFromEntity(entity), false)
    ClearPedSecondaryTask(PlayerPedId())
end

local function animalPositionBasedOnVehicle(entity)
    local animalType =  getAnimalModel(entity)
    local yPos, zPos
    if animalType=="a_c_deer" or animalType=="a_c_cow" then
        zPos = 2.40
        yPos = -1.5
    elseif  animalType=="a_c_boar" then
        zPos = 1.90
        yPos = -0.9
    elseif  animalType=="a_c_coyote" then
        zPos = 1.80
        yPos = -1.8
    elseif  animalType=="a_c_rabbit_01" then
        zPos = 1.50
        yPos = -1.5
    elseif  animalType=="a_c_mtlion" then
        zPos = 1.90
        yPos = -1.8
    else
        zPos = 1.50
        yPos = -1.5
    end
    return yPos, zPos
end


local function putOnRoof(data)
    local entity = data.entity
    local animalCoords = GetEntityCoords(entity)
    local vehicleId, vehicleCoords = lib.getClosestVehicle(animalCoords, 4, true)
    if GetHashKey("mesa3")==GetEntityModel(vehicleId) then
        if vehicleId then
            local state = Entity(vehicleId).state
            local isVehicleFull = state.full
            if not isVehicleFull then 
                TriggerServerEvent('hunterXhunter:setVehicleState', NetworkGetNetworkIdFromEntity(vehicleId), true) --set vehicle full
                TriggerServerEvent("hunterXhunter:setAnimalCarried", NetworkGetNetworkIdFromEntity(entity), false)
                lastEntity = nil
                carriying = false
                DetachEntity(entity, true, true)
                ClearPedSecondaryTask(PlayerPedId())
                ClearPedSecondaryTask(entity) --TODO add animation to animal
                local  yPos, zPos = animalPositionBasedOnVehicle(entity)
                AttachEntityToEntity(entity, vehicleId, 0, 0.0, yPos, zPos, 0.0, 0.5, 270.0, false, false, false, false, 2, true)
                SetEntityCollision(entity, true, false) 
            else
                lib.notify({
                    id = 'vehicle_full',
                    title = 'ERROR',
                    description = locale('vehicle_full'), 
                    position = 'top',
                    style = {
                        backgroundColor = '#141517',
                        color = '#909296'
                    },
                    icon = 'ban',
                    iconColor = '#C53030'
                })
            end
        else
            lib.notify({
                id = 'vehicle_far',
                title = 'ERROR',
                description = locale('vehicle_far'),
                position = 'top',
                style = {
                    backgroundColor = '#141517',
                    color = '#909296'
                },
                icon = 'ban',
                iconColor = '#C53030'
            })
        end
    else 
        lib.notify({
            id = 'vehicle_model_not_supported',
            title = 'ERROR',
            description = locale('vehicle_model_not_supported'),
            position = 'top',
            style = {
                backgroundColor = '#141517',
                color = '#909296'
            },
            icon = 'ban',
            iconColor = '#C53030'
        })
    end
end

local animalsOptions = {
    {
        name = 'slaughter',
        onSelect = function (data)
            slaughter(data)
        end,
        icon = locale('icon_slaughter'),
        label = locale('slaughter'),
        canInteract = function(entity, distance, coords, name, bone)
            local state = Entity(entity).state
            local isEntityCarried = state.carried
            return IsPedDeadOrDying(entity, true) and (not carriying) and (not lastEntity) and (not isEntityCarried) and (canHuntOutSideLegalZone or insideLegalZone) and insideSlaughterhouseZone
        end
    },
    {
        name = 'carry',
        onSelect = function (data)
            carry(data)
        end,
        icon = locale('icon_carry'),
        label = locale('carry'),
        canInteract = function(entity, distance, coords, name, bone)
            local state = Entity(entity).state
            local isEntityCarried = state.carried
            return IsPedDeadOrDying(entity, true) and (not carriying) and (not lastEntity) and (not isEntityCarried) and (canHuntOutSideLegalZone or insideLegalZone)
        end
    },
    {
        name = 'drop',
        onSelect = function (data)
            drop(data)
        end,
        icon = locale('icon_drop'),
        label = locale('drop'),
        canInteract = function(entity, distance, coords, name, bone)
            return IsPedDeadOrDying(entity, true) and carriying and (lastEntity==entity) and (canHuntOutSideLegalZone or insideLegalZone)
        end
    },
    {
        name = 'load',
        onSelect = function (data)
            putOnRoof(data)
        end,
        icon = locale('icon_put_on_roof'),
        label = locale('put_on_roof'),
        canInteract = function(entity, distance, coords, name, bone)
            return IsPedDeadOrDying(entity, true) and carriying and (lastEntity==entity) and (canHuntOutSideLegalZone or insideLegalZone)
        end
    },
}

RegisterNetEvent('hunterXhunter:drawOutlaw')
AddEventHandler('hunterXhunter:drawOutlaw', function(cords)
    local blip = AddBlipForCoord(cords)
    SetBlipSprite(blip, outalwBlipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, outlawBlipScale)
    SetBlipColour(blip, outlawBlipColor)

    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.outlaw.blipName)
    EndTextCommandSetBlipName(blip)

    SetTimeout(outlawDrawBlipTimeout, function() 
        RemoveBlip(blip)
    end)
end)

lib.callback.register('hunterXhunter:showPrgressbar', function(text, sec)
    if lib.progressCircle({
        position = 'bottom',
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = flase
        },
        duration = 1000 * sec,
        label = text,
        useWhileDead = false,
        anim = { --hate this part if u a have better suggention please make PR or MR
            scenario = 'WORLD_HUMAN_BUM_WASH',
            playEnter = true, 
        },
        prop = {--hate this part if u a have better suggention please make PR or MR
            model = 'prop_knife',
            pos = vec3(-0.04, -0.03, 0.02),
            rot = vec3(0.0, 0.0, -2.5) 
        },
    }) then return true end 
    return false
  end
)

AddEventHandler('esx:onPlayerDeath', function(data)-- if player is dead detach animal
    if lastEntity then 
        DetachEntity(lastEntity, true, true)
        TriggerServerEvent("hunterXhunter:setAnimalCarried", NetworkGetNetworkIdFromEntity(lastEntity), false)
        ClearPedSecondaryTask(PlayerPedId())
        lastEntity = nil
        carriying = false
    end
end)

CreateThread(function ()

    local allowedWeaponHash = GetHashKey("WEAPON_MUSKET")
    while true do 
        Wait(600)
        local player = PlayerPedId()
        local playerNetId = NetworkGetPlayerIndexFromPed(player)
        local isAiming, entity = GetEntityPlayerIsFreeAimingAt(playerNetId)
        local _, currentWeaponHash  = GetCurrentPedWeapon(player, 1)
        if isAiming and getAnimalModel(entity) and ((not insideLegalZone) or ((currentWeaponHash ~= allowedWeaponHash) and insideLegalZone)) then 
            TriggerServerEvent('hunterXhunter:signalIllegalHunting', GetEntityCoords(player))
        end
    end
end)

setSlaughterHouse()
getListOfAllowedAnimals()
setHuntingZone(Config.legalHuntingAreas)
ox_target:addModel(allowedAnimals, animalsOptions)




