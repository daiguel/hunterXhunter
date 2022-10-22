Config = {}


Config.allowToHuntWithoutLicense = false
Config.allowToSlaughterWithoutKnif = false

Config.allowToHuntOutSideZone = true --not yet implemented

Config.allowedAnimals = {   
    a_c_mtlion = { minMeatAmount = 5, maxMeatAmount = 7 , hornsAmount = 0, leatherAmount=1, leatherType=3, }, 
    a_c_deer = { minMeatAmount = 40, maxMeatAmount = 70 , hornsAmount = 1, leatherAmount=1, leatherType=3, }, 
    a_c_rabbit_01 = { minMeatAmount = 1, maxMeatAmount = 2, hornsAmount = 0, leatherAmount=1, leatherType=1 },
    a_c_boar =  { minMeatAmount = 5, maxMeatAmount = 10, hornsAmount = 0, leatherAmount=1, leatherType=1 },
    a_c_cow =  { minMeatAmount = 40, maxMeatAmount = 70, hornsAmount = 0, leatherAmount=1, leatherType=1 }
} --list of animals allowed to hunt

Config.prices = {
    leather =   {
                    type5=500, type4=400, type3=300, type2=200, type1=100
                },
    meat =     {
                    type5=500, type4=400, type3=300, type2=200, type1=100
                },
    a_c_boarH_horns =     {
                    type5=500, type4=400, type3=300, type2=200, type1=100
                },
            
}

Config.allowedKnifes = { 'WEAPON_DAGGER', 'WEAPON_KNIFE' } 

Config.licensesNeededToHunt = { 'WEAPON' } -- add liceses here if you have hunting license add it here

Config.legalHuntingAreas = { 
    area1 = { 
        coords=vector3(1408.4, 1780.2, 100.9), --one number after coma or will not display area on map
        distance = 400.0, --float
        blipSprite = 463,
        blipColor = 3,
        blipScale = 0.9,
        bigAreaColor = 3 
    },
    area2 = { 
        coords=vector3(-419.9, 4727.8, 256.1),--one number after coma or will not display area on map
        distance = 200.0,--float
        blipSprite = 463,
        blipColor = 3,
        blipScale = 0.9,
        bigAreaColor = 3 
    }
}

Config.signal = function () --calls to better trigger alert 
    local test= "oui"
end