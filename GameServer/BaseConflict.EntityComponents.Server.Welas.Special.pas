unit BaseConflict.EntityComponents.Server.Welas.Special;

interface

uses
  SysUtils,
  System.Rtti,
  Generics.Collections,
  Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Script,
  BaseConflict.Types.Server,
  BaseConflict.Constants,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Server.Brains,
  BaseConflict.EntityComponents.Server.Welas;

type

  {$RTTI INHERIT}
  /// <summary> Gives each commander his/her income. </summary>
  TWelaEffectIncomePayoutComponent = class(TWelaEffectComponent)
    protected
      procedure Fire(Targets : ATarget); override;
  end;

  {$RTTI INHERIT}

  TSpawnrotation = class
    strict private
    const
      FIXED_TUTORIAL_ROTATION : array [0 .. BUILDGRID_SLOTS - 1] of integer = (
        6, 19, 13, 11, 10, 9, 17, 14, 0, 16, 15, 7, 8, 2, 3, 1, 18, 12, 4, 5
        );
    strict private
      FSpawnCount : integer;
      FSpawnInOrder, FUseFixedRotation : boolean;
      FCurrentRotation : TAdvancedList<RIntVector2>;
      FLastSpawnedCoordinate : RIntVector2;
      procedure Fill;
    public
      constructor Create(SpawnInOrder, UseFixedTutorialRotation : boolean);
      function IsActive(const Coordinate : RIntVector2) : boolean;
      function NextInRotation : RIntVector2;
      procedure CheckEmptyAndFill;
      procedure UseField(const Coordinate : RIntVector2);
      destructor Destroy; override;
  end;

  /// <summary> Triggers the wave spawns in a random order, but asserting that each grid field is spawned once each cycle. </summary>
  TWelaEffectWaveSpawnComponent = class(TWelaEffectComponent)
    protected
      FSpawnAllTogether, FSpawnInOrder : boolean;
      FSpawnRotations : TObjectDictionary<integer, TSpawnrotation>;
      procedure Fire(Targets : ATarget); override;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterCreate() : boolean;
      [XEvent(eiWaveSpawn, epFirst, etTrigger, esGlobal)]
      function OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SpawnAllTogether : TWelaEffectWaveSpawnComponent;
      function SpawnInOrder : TWelaEffectWaveSpawnComponent;
      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals.Server;

{ TWelaEffectIncomePayoutComponent }

procedure TWelaEffectIncomePayoutComponent.Fire(Targets : ATarget);
var
  i : integer;
  Income: RIncome;
  Commander : TEntity;
begin
  for i := 0 to ServerGame.Commanders.Count - 1 do
  begin
    Commander := ServerGame.Commanders[i];
    income := GlobalEventbus.Read(eiIncome, [Commander.ID]).AsType<RIncome>;
    Commander.Eventbus.Trigger(eiResourceTransaction, [ord(reGold), Income.Gold]);
    Commander.Eventbus.Trigger(eiResourceTransaction, [ord(reWood), Income.Wood]);
  end;
end;

{ TWelaEffectWaveSpawnComponent }

constructor TWelaEffectWaveSpawnComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FSpawnRotations := TObjectDictionary<integer, TSpawnrotation>.Create([doOwnsValues]);
end;

destructor TWelaEffectWaveSpawnComponent.Destroy;
begin
  FSpawnRotations.Free;
  inherited;
end;

function TWelaEffectWaveSpawnComponent.OnAfterCreate : boolean;
var
  ZoneID : integer;
begin
  Result := True;
  if assigned(ServerGame) then
    for ZoneID in ServerGame.Map.BuildZones.BuildZones.Keys do
        FSpawnRotations.Add(ZoneID, TSpawnrotation.Create(FSpawnInOrder, ServerGame.GameInformation.IsTutorial));
end;

procedure TWelaEffectWaveSpawnComponent.Fire(Targets : ATarget);
var
  ZoneID : integer;
  x, y : integer;
  Target : RIntVector2;
  Spawnrotation : TSpawnrotation;
begin
  for ZoneID in FSpawnRotations.Keys do
  begin
    if FSpawnAllTogether then
    begin
      for x := 0 to BUILDGRID_SIZE.x - 1 do
        for y := 0 to BUILDGRID_SIZE.y - 1 do
          if not((x = 0) and (y = 0)) and
            not((x = 0) and (y = BUILDGRID_SIZE.y - 1)) and
            not((x = BUILDGRID_SIZE.x - 1) and (y = 0)) and
            not((x = BUILDGRID_SIZE.x - 1) and (y = BUILDGRID_SIZE.y - 1)) then
              GlobalEventbus.Trigger(eiWaveSpawn, [ZoneID, RIntVector2.Create(x, y)]);
    end
    else
    begin
      Spawnrotation := FSpawnRotations[ZoneID];
      Target := Spawnrotation.NextInRotation;
      GlobalEventbus.Trigger(eiWaveSpawn, [ZoneID, Target]);
    end;
  end;
end;

function TWelaEffectWaveSpawnComponent.OnWaveSpawn(GridID, Coordinate : RParam) : boolean;
var
  Spawnrotation : TSpawnrotation;
begin
  Result := False;
  if not FSpawnAllTogether and FSpawnRotations.TryGetValue(GridID.AsInteger, Spawnrotation) then
  begin
    Spawnrotation.CheckEmptyAndFill;
    if Spawnrotation.IsActive(Coordinate.AsIntVector2) then
    begin
      Result := True;
      Spawnrotation.UseField(Coordinate.AsIntVector2);
    end;
  end;
end;

function TWelaEffectWaveSpawnComponent.SpawnAllTogether : TWelaEffectWaveSpawnComponent;
begin
  Result := self;
  FSpawnAllTogether := True;
end;

function TWelaEffectWaveSpawnComponent.SpawnInOrder : TWelaEffectWaveSpawnComponent;
begin
  Result := self;
  FSpawnInOrder := True;
end;

{ TSpawnrotation }

procedure TSpawnrotation.CheckEmptyAndFill;
begin
  if FCurrentRotation.IsEmpty then
      Fill;
end;

constructor TSpawnrotation.Create(SpawnInOrder, UseFixedTutorialRotation : boolean);
begin
  FSpawnInOrder := SpawnInOrder;
  FCurrentRotation := TAdvancedList<RIntVector2>.Create;
  FLastSpawnedCoordinate := RIntVector2.Create(-1, -1);
  if UseFixedTutorialRotation then
  begin
    FUseFixedRotation := True;
    FSpawnInOrder := True;
  end;
  Fill;
end;

destructor TSpawnrotation.Destroy;
begin
  FCurrentRotation.Free;
  inherited;
end;

procedure TSpawnrotation.Fill;
var
  x, y, i : integer;
  temp : TArray<RIntVector2>;
begin
  FCurrentRotation.Clear;
  // create a new spawnrotation
  for x := 0 to BUILDGRID_SIZE.x - 1 do
    for y := 0 to BUILDGRID_SIZE.y - 1 do
      if not((x = 0) and (y = 0)) and
        not((x = 0) and (y = BUILDGRID_SIZE.y - 1)) and
        not((x = BUILDGRID_SIZE.x - 1) and (y = 0)) and
        not((x = BUILDGRID_SIZE.x - 1) and (y = BUILDGRID_SIZE.y - 1)) then
          FCurrentRotation.Add(RIntVector2.Create(x, y));
  if FUseFixedRotation then
  begin
    setLength(temp, length(FIXED_TUTORIAL_ROTATION));
    for i := 0 to length(FIXED_TUTORIAL_ROTATION) - 1 do
        temp[i] := FCurrentRotation[FIXED_TUTORIAL_ROTATION[i]];
    FCurrentRotation.Clear;
    FCurrentRotation.AddRange(temp);
  end
end;

function TSpawnrotation.IsActive(const Coordinate : RIntVector2) : boolean;
var
  i : integer;
begin
  Result := Coordinate = FLastSpawnedCoordinate;
  if not Result then
  begin
    for i := 0 to FCurrentRotation.Count - 1 do
      if FCurrentRotation[i] = Coordinate then
      begin
        Result := True;
        break;
      end;
  end;
end;

function TSpawnrotation.NextInRotation : RIntVector2;
begin
  CheckEmptyAndFill;
  if FSpawnInOrder then
      Result := FCurrentRotation.First
  else
      Result := FCurrentRotation.Random;
end;

procedure TSpawnrotation.UseField(const Coordinate : RIntVector2);
var
  i : integer;
begin
  inc(FSpawnCount);
  FLastSpawnedCoordinate := Coordinate;
  for i := 0 to FCurrentRotation.Count - 1 do
    if FCurrentRotation[i] = Coordinate then
    begin
      FCurrentRotation.Delete(i);
      break;
    end;
end;

initialization

ScriptManager.ExposeClass(TWelaEffectIncomePayoutComponent);
ScriptManager.ExposeClass(TWelaEffectWaveSpawnComponent);

end.
