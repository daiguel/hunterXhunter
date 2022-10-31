local ox_target = exports.ox_target
local renCost = Config.rentalHunter.rentCost

local function spawnCar()
	local hasMoney = lib.callback.await('hunterXhunter:removeMoney', false, renCost)
	if hasMoney then
		local pos = Config.rentalHunter.carSapwnCords
		ESX.Game.SpawnVehicle(Config.rentalHunter.car, pos, Config.rentalHunter.carSapwnCordsHeading, function(vehicle)
			local plate = GetVehicleNumberPlateText(vehicle)
			LocalPlayer.state.carRented = plate
			SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
		end)
	end

end

local hunterOptions = {
    {
        name = 'rental',
        onSelect = function(data)
			spawnCar()
        end,
        icon = locale('rental_menu_icon'),
        label = locale('rent_car_for')..renCost..locale('coin'),
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
	AddTextComponentSubstringPlayerName(Config.rentalHunter.blipName)
	EndTextCommandSetBlipName(blip)
end

local function createRentalHunterPed()
	local genderNum
	local model = Config.rentalHunter.model
	local gender = Config.rentalHunter.gender
	local coords = Config.rentalHunter.coords
	local heading = Config.rentalHunter.heading
	local animDict = Config.rentalHunter.animDict
	local animName = Config.rentalHunter.animName

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
	ox_target:addLocalEntity(ped, hunterOptions)
	return ped
	
end

local function deleteRentalHunterPed(ped)
	for i = 255, 0, -51 do
		Citizen.Wait(50)
		SetEntityAlpha(ped, i, false)
	end
	ox_target:removeLocalEntity(ped, hunterOptions)
	DeletePed(ped)
	
end

local function setRentalHunter()
	local coords = Config.rentalHunter.coords
	createblip(coords, Config.rentalHunter.blipSprite, Config.rentalHunter.blipScale, Config.rentalHunter.blipColor)
    local rentalHunterPoint = lib.points.new(coords, 30, { name = 'buyer'})

	local pedSpawned
	function rentalHunterPoint:onEnter()
		pedSpawned = createRentalHunterPed()
	end

	function rentalHunterPoint:onExit()
		deleteRentalHunterPed(pedSpawned)
	end
end

local function setTakeBackCar()

    local point = lib.points.new(Config.rentalHunter.carTakeBack, 30, { name = 'slaughterhouse'})
	local player, carRentedByCurrentPlayer --this adds 0.02 ms ads in infite loop

	function point:onEnter()
		carRentedByCurrentPlayer = LocalPlayer.state.carRented
		player =  PlayerPedId()
	end

	function point:onExit()
		lib.hideTextUI()
	end

	local MessageShown = false
	local range = 5
	local marker = Config.rentalHunter.marker
	local r, g, b = table.unpack(Config.rentalHunter.markerColor)

	function point:nearby()
		local vehicle = GetVehiclePedIsIn(player, false)
		local isCurrentCarRentedByThisPalyer = (GetVehicleNumberPlateText(vehicle) == carRentedByCurrentPlayer)
		DrawMarker(marker, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, r, g, b, 50, true, true, 2, nil, nil, false)
		if (self.currentDistance <= range) and (isCurrentCarRentedByThisPalyer) and (vehicle ~=0) then
			if not MessageShown then
				MessageShown = true
				lib.showTextUI(locale('return_veh'), {
					position = "bottom-center",
					style = {
						borderRadius = 30,
						backgroundColor = '#33adff',
						color = 'black',
						opacity =  0.5, 
					}
				})
			end
			if IsControlJustPressed(0, 38) then
				local bodyHealth = GetVehicleBodyHealth(vehicle)
				local engineHealth = GetVehicleEngineHealth(vehicle)
				if engineHealth < 0 then
					engineHealth = 0
				end 
				local enginePercentage = engineHealth*100/1000
				local bodyPercentage = bodyHealth*100/1000
				local sum = ((renCost/2)*enginePercentage/100)+((renCost/2)*bodyPercentage/100) 
				TriggerServerEvent('hunterXhunter:deleteCarAndRedeem', NetworkGetNetworkIdFromEntity(vehicle), sum)
			end
		else
			if MessageShown then 
				lib.hideTextUI()
				MessageShown = false
			end
		end
		
		
	end

	
end

setRentalHunter()
setTakeBackCar()