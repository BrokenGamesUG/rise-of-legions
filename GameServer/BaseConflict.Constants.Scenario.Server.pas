unit BaseConflict.Constants.Scenario.Server;

interface

uses
  // ===== Delphi ==========
  System.Generics.Collections,
  SysUtils,
  // ===== Game ==========
  BaseConflict.Constants.Cards;

type

  EnumUnitType = (utRanged, utMelee, utTank, utDD, utUtil, utSiege, utBigBoss,
    utSmallBoss, utCannonFodder, utFlying, utGround, utUnit, utBuilding);

  SetUnitTypes = set of EnumUnitType;

  TScenarioUnitInfo = class
    public
      UnitTypes : SetUnitTypes;
  end;

var
  ScenarioUnitInfoMapping : TObjectDictionary<string, TScenarioUnitInfo>;

implementation

function sui(UnitTypes : SetUnitTypes) : TScenarioUnitInfo;
begin
  Result := TScenarioUnitInfo.Create;
  Result.UnitTypes := UnitTypes;
end;

initialization

ScenarioUnitInfoMapping := TObjectDictionary<string, TScenarioUnitInfo>.Create([doOwnsValues]);

ScenarioUnitInfoMapping.Add('BigCasterGolem', sui([utUnit, utGround, utRanged, utUtil]));
ScenarioUnitInfoMapping.Add('BigFlyingGolem', sui([utUnit, utFlying, utRanged, utDD]));
ScenarioUnitInfoMapping.Add('BigGolemTower', sui([utBuilding]));
ScenarioUnitInfoMapping.Add('BigMeleeGolem', sui([utUnit, utGround, utMelee, utTank, utSmallBoss]));
ScenarioUnitInfoMapping.Add('MediumMeleeGolem', sui([utUnit, utGround, utMelee, utTank]));
ScenarioUnitInfoMapping.Add('MeleeGolemTower', sui([utBuilding]));
ScenarioUnitInfoMapping.Add('SiegeGolem', sui([utUnit, utGround, utRanged, utSiege]));
ScenarioUnitInfoMapping.Add('SmallCasterGolem', sui([utUnit, utGround, utRanged, utUtil]));
ScenarioUnitInfoMapping.Add('SmallFlyingGolem', sui([utUnit, utFlying, utRanged, utDD]));
ScenarioUnitInfoMapping.Add('SmallGolemTower', sui([utBuilding]));
ScenarioUnitInfoMapping.Add('SmallMeleeGolem', sui([utUnit, utGround, utMelee, utCannonFodder]));
ScenarioUnitInfoMapping.Add('SmallRangedGolem', sui([utUnit, utGround, utRanged, utDD]));

ScenarioUnitInfoMapping.Add('BossGolem', sui([utUnit, utGround, utMelee, utBigBoss]));
ScenarioUnitInfoMapping.Add('GolemLaneTowerLevel1', sui([utBuilding]));
ScenarioUnitInfoMapping.Add('GolemLaneTowerLevel2', sui([utBuilding]));
ScenarioUnitInfoMapping.Add('GolemLaneTowerLevel3', sui([utBuilding]));


finalization

FreeAndNil(ScenarioUnitInfoMapping);

end.
