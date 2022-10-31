local ox_target = exports.ox_target
lib.locale()

local function sell(productName, amount, price)
	TriggerServerEvent('hunterXhunter:sellItem', productName, amount, price)
end

local buyerOptions = {
    {
        name = 'meat',
        onSelect = function(data)
			local amount = exports.ox_inventory:Search('count', data.name)
			if amount > 0 then
				sell(data.name, amount, Config.buyer.prices.meat)
			else
				lib.notify({
					id = 'msg_not_enough_meat',
					title = 'ERROR',
					description = locale('no_meat'),
					position = 'top',
					style = {
						backgroundColor = '#141517',
						color = '#909296'
					},
					icon = 'ban',
					iconColor = '#C53030'
				})
			end 
        end,
        icon = locale('icon_sell_meat'),
        label = locale('sell_meat')..Config.buyer.prices.meat..locale('per_kg'),
        distance = 2,
        canInteract = function(entity, coords, distance)
            return ((not IsPedDeadOrDying(PlayerPedId(), true))) and (not IsPedCuffed(PlayerPedId())) 
        end	
    }, 
	{
        name = 'a_c_deer_horns',
        onSelect = function(data)
			local amount = exports.ox_inventory:Search('count', data.name)
			if amount > 0 then
				sell(data.name, amount, Config.buyer.prices.horns)
			else
				lib.notify({
					id = 'msg_not_enough_horns',
					title = 'ERROR',
					description = locale('no_deer_horns'),
					position = 'top',
					style = {
						backgroundColor = '#141517',
						color = '#909296'
					},
					icon = 'ban',
					iconColor = '#C53030'
				})
			end 
        end,
        icon = locale('icon_sell_horns'),
        label = locale('sell_deer_horns')..Config.buyer.prices.horns..locale('deer_horns_per_unit'),
        distance = 2,
        canInteract = function(entity, coords, distance)
            return ((not IsPedDeadOrDying(PlayerPedId(), true))) and (not IsPedCuffed(PlayerPedId())) 
        end	
    }, 
	{
        name = 'leather',
        onSelect = function(data)
			local amount = exports.ox_inventory:Search('count', data.name)
			if amount > 0 then
				sell(data.name, amount, Config.buyer.prices.leather)
			else
				lib.notify({
					id = 'msg_not_enough_leather',
					title = 'ERROR',
					description = locale('no_leather'),
					position = 'top',
					style = {
						backgroundColor = '#141517',
						color = '#909296'
					},
					icon = 'ban',
					iconColor = '#C53030'
				})
			end 
        end,
        icon = locale('icon_sell_leather'),
        label = locale('sell_leather')..Config.buyer.prices.leather..locale('leather_per_unit'),
        distance = 2,
        canInteract = function(entity, coords, distance)
            return ((not IsPedDeadOrDying(PlayerPedId(), true))) and (not IsPedCuffed(PlayerPedId())) 
        end	
    },
}

local function createblip(coords, blipSprite, scale, color)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, blipSprite)
	SetBlipScale(blip, scale)
	SetBlipColour(blip, color)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(Config.buyer.blipName)
	EndTextCommandSetBlipName(blip)
end

local function createBuyerPed()
	local genderNum
	local model = Config.buyer.model
	local gender = Config.buyer.gender
	local coords = Config.buyer.coords
	local heading = Config.buyer.heading
	local animDict = Config.buyer.animDict
	local animName = Config.buyer.animName

	RequestModel(GetHashKey(model))
	while not HasModelLoaded(GetHashKey(model)) do
		Citizen.Wait(1)
	end

	if gender == 'male' then
		genderNum = 4
	elseif gender == 'female' then 
		genderNum = 5
	else
		print("No gender provided! Check your configuration!")
	end	

	--Check if someones coordinate grabber thingy needs to subract 1 from Z or not.
    local x, y, z = table.unpack(coords)
    local ped = CreatePed(genderNum, GetHashKey(model), x, y, z - 1, heading, false, true)
	SetEntityAlpha(ped, 0, false)
    FreezeEntityPosition(ped, true) --Don't let the ped move.
    SetEntityInvincible(ped, true) --Don't let the ped die.
    SetBlockingOfNonTemporaryEvents(ped, true) --Don't let the ped react to his surroundings.
	--Add an animation to the ped, if one exists.
    RequestAnimDict(animDict)-- to do
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(1)
    end
    TaskPlayAnim(ped, animDict, animName, 8.0, 0, -1, 1, 0, 0, 0)
	
    for i = 0, 255, 51 do
        Citizen.Wait(50)
        SetEntityAlpha(ped, i, false)
    end
	ox_target:addLocalEntity(ped, buyerOptions)
	return ped
	
end

local function removeBuyerPed(ped)
	for i = 255, 0, -51 do
		Citizen.Wait(50)
		SetEntityAlpha(ped, i, false)
	end
	ox_target:removeLocalEntity(ped, buyerOptions)
	DeletePed(ped)
	
end

local function setBuyer()
	local coords = Config.buyer.coords

    local point = lib.points.new(coords, 30, { name = 'buyer'})
	
	createblip(coords, Config.buyer.blipSprite, Config.buyer.blipScale, Config.buyer.blipColor)

	local pedSpawned =  nil
	function point:onEnter()
		pedSpawned = createBuyerPed()
	end

	function point:onExit()
		removeBuyerPed(pedSpawned)
	end
end

setBuyer()