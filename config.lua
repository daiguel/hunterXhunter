Config = {}
Config.Locale                     = 'en'

Config.allowToHuntWithoutLicense = true
Config.allowToSlaughterWithoutKnif = false
Config.allowToHuntOutSideZone = true --disable slaughter carry/drop and put on roof 
Config.allowedAnimals = {   --list of animals allowed to hunt
    a_c_mtlion = { minMeatAmount = 30, maxMeatAmount = 50 }, 
    a_c_deer = { minMeatAmount = 70, maxMeatAmount = 120 }, 
    a_c_boar =  { minMeatAmount = 50, maxMeatAmount = 60 },
} 

Config.slaughterhouse = { 
    coords = vector3( 997.3, -2179.1, 29.8 ), 
    distance = 13.0,
    blipName = "Slaughterhouse",
    blipSprite = 463,
    blipColor = 3,
    blipScale = 0.9,
    bigAreaColor = 3,
    marker = 31,
    markerColor = { 3, 165, 252 } --RGB
    }

Config.allowedKnifes = { 'WEAPON_DAGGER', 'WEAPON_KNIFE' } 

Config.licensesNeededToHunt = { 'WEAPON' } -- add liceses here if you have hunting license add it here

Config.legalHuntingAreas = { 
    area1 = { 
        coords=vector3(1408.4, 1780.2, 100.9), --one number after coma or will not display area on map
        distance = 400.0,
        blipName = 'Legal hunting area',
        blipSprite = 463,
        blipColor = 3,
        blipScale = 0.9,
        bigAreaColor = 3 
    },
    area2 = { 
        coords=vector3(-419.9, 4727.8, 256.1),--one number after coma or will not display area on map
        distance = 200.0,
        blipName = 'Legal hunting area',
        blipSprite = 463,
        blipColor = 3,
        blipScale = 0.9,
        bigAreaColor = 3 
    }
}

Config.rentalHunter = {
		model = "cs_hunter", --The model name. See above for the URL of the list.
		coords = vector3(202.8745, 2441.9783, 60.4760), --HAIR ON HAWICK AVE
		heading = 238.1330, --Must be a float value. This means it needs a decimal and a number after the decimal.
		gender = "male", --Use male or female
		animDict = "amb@code_human_cross_road@male@idle_a", --The animation dictionary. Optional. Comment out or delete if not using.
		animName = "idle_c", --The animation name. Optional. Comment out or delete if not using.
		isRendered = false,
		ped = nil,
        rentCost = 2000,
        blipName = 'Rent car for hunt',
        blipSprite = 524,
        blipColor = 3,
        blipScale = 0.7,
        marker = 36,
        markerColor = { 3, 165, 252 }, --RGB
        car = "mesa3", -- car model
        carSapwnCords = vector3(203.0993, 2454.5398, 56.5882),
        carSapwnCordsHeading = 278.2991,
        carTakeBack = vector3(211.3851, 2477.7458, 55.4935)
	}

Config.buyer = {
    model = "cs_martinmadrazo",
    gender = "male",
    animDict = "amb@code_human_cross_road@male@idle_a", --The animation dictionary. Optional. Comment out or delete if not using.
	animName = "idle_c",
    coords = vector3(1185.2501, -2993.6406, 5.9021),
    heading =  303.4307, 
    prices = { horns = 15000, meat = 85, leather = 2000 }, --price of meat per kg - others per unit 
    blipName = 'Sell hunted goods',
    blipSprite = 500,
    blipColor = 3,
    blipScale = 0.7,
} 

Config.outlaw = {
    signalfunc = function (outlawSource, outalwCoords, policeSource) -- trigger your alerts here _ will be triggered many times on each police
        TriggerClientEvent('ox_lib:notify', policeSource, { type = 'error', description = TranslateCap('notify_cops') })
    end,
    blipName = 'Outlaw hunter',
    blipSprite = 303,
    blipColor = 23,
    blipScale = 0.9,
    drawBlipTimeout = 100000,
}