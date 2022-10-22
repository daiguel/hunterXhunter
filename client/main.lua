local allowedAnimals = {}
local ox_target = exports.ox_target
local insideLegalZone = false

local carriying = false
local lastEntity = nil

local function createBlip(coords, bigAreaColor, distance, blipSprite, blipColor, blipScale)
    local blip = AddBlipForRadius(coords, distance) -- need to have .0
    SetBlipColour(blip, bigAreaColor)
    SetBlipAlpha(blip, 128)


    local blip2 = AddBlipForCoord(coords)
    SetBlipSprite(blip2, blipSprite)
	SetBlipDisplay(blip2, 4)
	SetBlipScale(blip2, blipScale)
	SetBlipColour(blip2, blipColor)
	SetBlipAsShortRange(blip2, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName('legal hunting area')
	EndTextCommandSetBlipName(blip2)
    return blip, blip2
end

local function setHuntingZone(areas)
    for _, area in pairs(areas) do
        createBlip(area.coords, area.bigAreaColor, area.distance, area.blipSprite, area.blipColor, area.blipScale)
        
        local point = lib.points.new(area.coords, area.distance, { name = 'legal hunting area'})
        
        function point:onEnter()
            --print('entered range of point', self.id)
            insideLegalZone = true
        end
        
        function point:onExit()
            --print('left range of point', self.id)
            insideLegalZone = false
        end
    end
end

local function GetListOfAllowedAnimals()
    for key,_ in pairs(Config.allowedAnimals) do
        table.insert(allowedAnimals, key)
    end
end

local function get_animal_model(entity)
    local hash = GetEntityModel(entity)
    for _, animal in pairs(allowedAnimals) do 
        if GetHashKey(animal)==hash then
            return animal 
        end
    end
end
 
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
            model = `prop_knife`,
            pos = vec3(-0.04, -0.03, 0.02),
            rot = vec3(0.0, 0.0, -2.5) 
        },
    }) then return true end 
    return false
  end
)

lib.callback.register('hunterXhunter:insideLegalZone', function()
    return insideLegalZone
  end
)

local function loadanimdict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end

local function copyAmountOfMeat(animal, clone)
    local state = Entity(animal).state
    local amountOfMeatLeftToGive = state.amountOfMeatLeftToGive
    Entity(clone).state:set('amountOfMeatLeftToGive', amountOfMeatLeftToGive, true)
end


local function slaughter(data, amountOfMeatLeftToGive)
    local hasHorns=false
        
    if GetPedDrawableVariation(data.entity, 8)==1 then
        hasHorns = true
    end
    --end
    local animalType = get_animal_model(data.entity)
    local netEntity = NetworkGetNetworkIdFromEntity(data.entity)
    TriggerServerEvent('hunterXhunter:slaughter', netEntity, animalType, hasHorns, amountOfMeatLeftToGive)
end

local function carry(data)
    -- if not insideLegalZone then 
    --     TriggerServerEvent('hunterXhunter:signalIllegalHunting', GetEntityCoords(PlayerPedId()))
    -- end 
    local entity = data.entity
    local vehicleId = GetEntityAttachedTo(entity) -- block to set vehicle to empty
    local amountOfMeatLeftToGive = lib.callback.await('hunterXhunter:getAmountOfMeat', false, NetworkGetNetworkIdFromEntity(entity))
    if vehicleId then
        TriggerServerEvent('hunterXhunter:setVehicleState', NetworkGetNetworkIdFromEntity(vehicleId), nil) --set vehicle empty
    end
    carriying = true
    DetachEntity(entity, true, true)-- when attached do vehicle
    local cords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local x, y, z = table.unpack(cords)
    local clone = ClonePed(entity, true, false, true)
    lastEntity = clone
    TriggerServerEvent("hunterXhunter:removeOldEntity", NetworkGetNetworkIdFromEntity(entity)) -- delete old animal that freezes
    
    TriggerServerEvent("hunterXhunter:setAnimalCarried", NetworkGetNetworkIdFromEntity(clone)) 
    TriggerServerEvent('hunterXhunter:setAmountOfMeat', NetworkGetNetworkIdFromEntity(clone), amountOfMeatLeftToGive) --copy amount to clone
    
    SetEntityCoords(clone, x, y, z, false, false, true, false)
    SetEntityHeading(clone, heading)
    
    AttachEntityToEntity(clone, PlayerPedId(), 0, 0.35, 0.0, 1.53, 0.5, 0.5, 0.0, false, false, false, false, 2, true) -- z=0.63 is the shoulder but doesnt syncs still shit 
    SetEntityCollision(clone, true, false)

    loadanimdict('missfinale_c2mcs_1')
    TaskPlayAnim(PlayerPedId(), 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, 100000, 49, 0, false, false, false)
end

local function drop(data)
    -- if not insideLegalZone then 
    --     TriggerServerEvent('hunterXhunter:signalIllegalHunting', GetEntityCoords(PlayerPedId()))
    -- end 
    lastEntity = nil
    carriying = false
    local entity = data.entity
    local amountOfMeatLeftToGive = lib.callback.await('hunterXhunter:getAmountOfMeat', false, NetworkGetNetworkIdFromEntity(entity))
    DetachEntity(entity, true, true)
    ClearPedSecondaryTask(PlayerPedId())
    -- ClearPedSecondaryTask(entity) --todo add animation to animal
    local cords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local x, y, z = table.unpack(cords)
    local clone = ClonePed(entity, true, false, true)
    DeleteEntity(entity)-- maybe remove the entity in server [[[[]]]] synced well here :O    
    TriggerServerEvent('hunterXhunter:setAmountOfMeat', NetworkGetNetworkIdFromEntity(clone), amountOfMeatLeftToGive)
    SetEntityCoords(clone, x, y, z-0.63, false, false, true, false)
    SetEntityHeading(clone, heading)
end

local function put_on_roof(data)
    -- if not insideLegalZone then 
    --     TriggerServerEvent('hunterXhunter:signalIllegalHunting', GetEntityCoords(PlayerPedId()))
    -- end 
    local entity = data.entity
    local animalCoords = GetEntityCoords(entity)
    local vehicleId, vehicleCoords = lib.getClosestVehicle(animalCoords, 4, true)
    if vehicleId then
        local state = Entity(vehicleId).state
        local isVehicleFull = state.full
        if not isVehicleFull then 
            TriggerServerEvent('hunterXhunter:setVehicleState', NetworkGetNetworkIdFromEntity(vehicleId), true) --set vehicle full
            lastEntity = nil
            carriying = false
            DetachEntity(entity, true, true)
            ClearPedSecondaryTask(PlayerPedId())
            -- ClearPedSecondaryTask(entity) --TODO add animation to animal
            local cords = GetEntityCoords(entity)
            local heading = GetEntityHeading(entity)
            local x, y, z = table.unpack(cords)
            local clone = ClonePed(entity, true, false, true)
            DeleteEntity(entity) -- maybe remove the entity in server \o/ synced well here :O
            SetEntityCoords(clone, x, y, z, false, false, true, false)
            SetEntityHeading(clone, heading)
            AttachEntityToEntity(clone, vehicleId, 0, 0.0, -1.5, 2.40, 0.0, 0.5, 270.0, false, false, false, false, 2, true) -- z=0.63 is the shoulder but doesnt syncs still shit 
            SetEntityCollision(clone, true, false) 
        else
            lib.notify({
                id = 'vehicle_full',
                title = 'ERROR',
                description = 'vehicle full',
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
            description = 'no vehicles around here',
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
            local amountOfMeatLeftToGive = lib.callback.await('hunterXhunter:getAmountOfMeat', false, NetworkGetNetworkIdFromEntity(data.entity))
            if not amountOfMeatLeftToGive then 
                amountOfMeatLeftToGive = math.random(40,70)
                TriggerServerEvent('hunterXhunter:setAmountOfMeat', NetworkGetNetworkIdFromEntity(data.entity), amountOfMeatLeftToGive)
                -- Entity(entity).state.amountOfMeatLeftToGive = amountOfMeatLeftToGive
            end
            slaughter(data, amountOfMeatLeftToGive)
        end,
        icon = 'fa-solid fa-skull-cow',
        label = 'slaughter',
        canInteract = function(entity, distance, coords, name, bone)
            local state = Entity(entity).state
            local isEntityCarried = state.carried
            return IsPedDeadOrDying(entity, true) and (not carriying) and (not lastEntity) and (not isEntityCarried)--GetPedType(entity) == 28  this is no longer needed
        end
    },
    {
        name = 'carry',
        onSelect = function (data)
            carry(data)
        end,
        icon = 'fa-solid fa-skull-cow',
        label = 'carry',
        canInteract = function(entity, distance, coords, name, bone)
            local state = Entity(entity).state
            local isEntityCarried = state.carried
            return IsPedDeadOrDying(entity, true) and (not carriying) and (not lastEntity) and (not isEntityCarried)--GetPedType(entity) == 28  this is no longer needed
        end
    },
    {
        name = 'drop',
        onSelect = function (data)
            drop(data)
        end,
        icon = 'fa-solid fa-skull-cow',
        label = 'drop',
        canInteract = function(entity, distance, coords, name, bone)
            return IsPedDeadOrDying(entity, true) and carriying and (lastEntity==entity)--GetPedType(entity) == 28  this is no longer needed
        end
    },
    {
        name = 'load',
        onSelect = function (data)
            put_on_roof(data)
        end,
        icon = 'fa-solid fa-skull-cow',
        label = 'put on roof',
        canInteract = function(entity, distance, coords, name, bone)
            return IsPedDeadOrDying(entity, true) and carriying and (lastEntity==entity)--GetPedType(entity) == 28  this is no longer needed
        end
    },


}

RegisterNetEvent('hunterXhunter:drawOutlaw')
AddEventHandler('hunterXhunter:drawOutlaw', function(cords)
    local blip = AddBlipForCoord(cords)
    SetBlipSprite(blip, 303)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, 23)

    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Outlaw hunter')
    EndTextCommandSetBlipName(blip)

    SetTimeout(100000, function() 
        RemoveBlip(blip)
    end)
end)

GetListOfAllowedAnimals()
setHuntingZone(Config.legalHuntingAreas)
ox_target:addModel(allowedAnimals, animalsOptions)