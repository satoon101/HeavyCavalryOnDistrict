-- ===========================================================================
--  Heavy Cavalry On District - Gameplay Script
--  Spawns a heavy cavalry unit on entertainment districts.
-- ===========================================================================

print("=== Heavy Cavalry On District (Gameplay) Loading ===")

local traitToCivMap = {}
for row in GameInfo.CivilizationTraits() do
    traitToCivMap[row.TraitType] = row.CivilizationType
end

local techMap = {}
for row in GameInfo.Technologies() do
    techMap[row.TechnologyType] = row.Index
end

local civicMap = {}
for row in GameInfo.Civics() do
    civicMap[row.CivicType] = row.Index
end

function shouldUnitSpawn(districtInfo)
    if districtInfo == nil then
        return false
    end

    if districtInfo.Entertainment <= 0 then
        return false
    end

    if not districtInfo.OnePerCity then
        return false
    end

    if districtInfo.Coast then
        return false
    end

    if districtInfo.DistrictType == "DISTRICT_HIPPODROME" then
        return false
    end
    return true
end

function isValidUnit(unitInfo, techs, civics, civType, promotionClass)
    if unitInfo.EnabledByReligion then
        return false
    end

    if unitInfo.PromotionClass ~= promotionClass then
        return false
    end

    if unitInfo.Range > 0 then
        return false
    end

    if unitInfo.TraitType then
        local unitCiv = traitToCivMap[unitInfo.TraitType]
        if unitCiv ~= civType then
            return false
        end
    end

    if unitInfo.PrereqTech then
        local techIndex = techMap[unitInfo.PrereqTech]
        if not techs:HasTech(techIndex) then
            return false
        end
    end

    if unitInfo.PrereqCivic then
        local civicIndex = civicMap[unitInfo.prereqCivic]
        if not civics:HasCivic(civicIndex) then
            return false
        end
    end

    return true
end

function GetBestAvailableUnit(player, playerID, promotionClass)
    local civType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
    local techs = player:GetTechs()
    local civics = player:GetCulture()

    local bestUnit = nil
    local bestStrength = -1

    for unitInfo in GameInfo.Units() do
        if isValidUnit(unitInfo, techs, civics, civType, promotionClass) then
            if unitInfo.Combat > bestStrength or (unitInfo.Combat == bestStrength and unitInfo.TraitType) then
                bestStrength = unitInfo.Combat
                bestUnit = unitInfo
            end
        end
    end
    return bestUnit
end

function spawnUnit(playerID, districtInfo, iX, iY)
    local player = Players[playerID]
    if not player then
        return
    end

    if not player:IsHuman() then
        return
    end

    if not shouldUnitSpawn(districtInfo) then
        return
    end

    local unitToSpawn = GetBestAvailableUnit(player, playerID, "PROMOTION_CLASS_HEAVY_CAVALRY")
    if not unitToSpawn then
        unitToSpawn = GetBestAvailableUnit(player, playerID, "PROMOTION_CLASS_MELEE")
        if not unitToSpawn then
            return
        end
    end

    UnitManager.InitUnit(playerID, unitToSpawn.Index, iX, iY)
end

function BuildingConstructed(playerID, cityID, buildingID, plotID, bOriginalConstruction)
    local buildingInfo = GameInfo.Buildings[buildingID]
    local districtInfo = GameInfo.Districts[buildingInfo.PrereqDistrict]
    local plot = Map.GetPlotByIndex(plotID)
    spawnUnit(playerID, districtInfo, plot:GetX(), plot:GetY())
end

GameEvents.BuildingConstructed.Add(BuildingConstructed)


function OnDistrictConstructed(playerID, districtID, iX, iY)
    local districtInfo = GameInfo.Districts[districtID]
    spawnUnit(playerID, districtInfo, iX, iY)
end

GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed)

print("=== Heavy Cavalry On District (Gameplay) Loaded ===")
