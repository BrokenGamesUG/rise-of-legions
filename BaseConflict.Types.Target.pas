unit BaseConflict.Types.Target;

interface

uses
  System.Math,
  SysUtils,
  BaseConflict.Entity,
  BaseConflict.Map,
  BaseConflict.Constants,
  BaseConflict.Types.Shared,
  Engine.Script,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  EnumTargetType = (ttNone, ttCoordinate, ttEntity, ttBuild);

  /// <summary> A target for a wela. Can be one of a numerous amount of types, e.g. an entity or spot on the ground. </summary>
  RTarget = packed record
    private
      FTargetType : EnumTargetType;
      FTargetCoord : RVector2;
      FEntityID, FBuildGridID : integer;
      FBuildZoneCoord : RIntVector2;
    public
      property TargetType : EnumTargetType read FTargetType;
      property BuildGridID : integer read FBuildGridID;
      property BuildGridCoordinate : RIntVector2 read FBuildZoneCoord;
      property EntityID : integer read FEntityID;
      class function CreateEmpty : RTarget; static;
      constructor Create(Target : RVector2); overload;
      constructor Create(Target : TEntity); overload;
      constructor Create(TargetEntityID : integer); overload;
      constructor CreateBuildTarget(BuildGridID : integer; Coord : RIntVector2); overload;
      function IsEmpty : boolean;
      function IsEntity : boolean;
      function IsBuildTarget : boolean;
      function IsCoordinate : boolean;
      function GetTargetPosition : RVector2;
      function GetRealBuildPosition(NeededGridSize : RIntVector2) : RVector2;
      function GetTargetEntity : TEntity;
      function IsEntityValid : boolean;
      /// <summary> Returns the saved entity, if target is an entity and valid. </summary>
      function TryGetTargetEntity(out Entity : TEntity) : boolean;
      function GetBuildZone : TBuildZone;
      function Hash : integer;
      class operator Explicit(a : TEntity) : RTarget;
      class operator Explicit(a : RVector2) : RTarget;
      class operator Implicit(a : RTarget) : RParam;
      class operator Equal(a, b : RTarget) : boolean;
      class operator NotEqual(a, b : RTarget) : boolean;
  end;

  ATarget = array of RTarget;

  ProcTargetProcessor = reference to procedure(Item : RTarget);
  ProcTargetProcessorWithIndex = reference to procedure(index : integer; Item : RTarget);

  ATargetHelper = record helper for ATarget
    public
      constructor Create(Item : RTarget); overload;
      constructor Create(Item : TEntity); overload;
      constructor Create(EntityID : integer); overload;
      constructor Create(Item : RVector2); overload;
      class function CreateEmpty : ATarget; static;
      function Count : integer;
      function First : RTarget;
      procedure Append(Values : ATarget);
      /// <summary> Returns whether given target is in this list. Only works for entity targets. </summary>
      function Contains(const Target : RTarget) : boolean;
      /// <summary> Checks whether index is a valid index. </summary>
      function HasIndex(Index : integer) : boolean;
      function ToRParam : RParam;
  end;

  /// <summary> Data about the validity of an array of targets. Defaults to true if not processed. </summary>
  RTargetValidity = record
    const
      MAX_TARGETS = SizeOf(SetByte) * 8;
    var
      /// <summary> If have been cast from RParam.Empty IsInitialized will be false. </summary>
      IsInitialized : boolean;
      /// <summary> Determines whether the combination of the targets is valid. </summary>
      TogetherValid : boolean;
      /// <summary> Needed because we can't use a dynamic array in this record due automatic memory management and casting
      /// into the RParam. </summary>
      TargetCount : integer;
      /// <summary> Determines whether the single targets are valid. </summary>
      SingleValidityMask : SetByte;
      /// <summary> Creates a template with everything set on true for an array of targets. </summary>
      constructor Create(Targets : ATarget);
      /// <summary> Returns whether all targets and the combination of them is valid. </summary>
      function IsValid : boolean;
      /// <summary> Sets a single validity. If a targets have been invalid before even a valid check would leave it invalid. </summary>
      procedure SetValidity(const Index : integer; const Value : boolean);
      /// <summary> Sets the combinatorial validity. If some component made this invalid before, it will stay invalid. </summary>
      procedure SetTogetherValid(const Value : boolean);
      class operator Implicit(a : RTargetValidity) : RParam;
  end;

  EnumCommanderAbilityTargetType = (ctNone, ctCoordinate, ctEntity, ctTargetLess, ctBuildZone, ctSelftarget);
const
  COMMANDER_ABILITIES_WITHOUT_TARGET = [ctNone, ctTargetLess, ctSelftarget];

type

  PCommanderAbilityTarget = ^RCommanderAbilityTarget;

  /// <summary> A target of a ability activated by a commander. If it isn't set user
  /// interaction is needed. </summary>
  RCommanderAbilityTarget = packed record
    private
      FCoord : RVector2;
      FEntityID, FGridID : integer;
      FGridCoordinate : RIntVector2;
      FIsSet : boolean;
      FType : EnumCommanderAbilityTargetType;
    public
      class function CreateEmpty : RCommanderAbilityTarget; static;
      class function CreateTargetLess : RCommanderAbilityTarget; static;
      class function CreateSelftarget() : RCommanderAbilityTarget; static;
      /// <summary> Creates a abilitytarget with a not set target. Targetless is always set. </summary>
      constructor CreateUnset(CAType : EnumCommanderAbilityTargetType); overload;
      constructor Create(Target : RVector2); overload;
      constructor Create(Target : TEntity); overload;
      constructor Create(TargetEntity : integer); overload;

      constructor CreateBuildTarget(TargetBuildZone : integer; TargetCoordinate : RIntVector2); overload;
      function IsEmpty : boolean;
      property TargetType : EnumCommanderAbilityTargetType read FType;
      property IsSet : boolean read FIsSet;
      property Coordinate : RVector2 read FCoord;
      property EntityID : integer read FEntityID;
      function GetWorldPosition(Owner : TEntity = nil) : RVector2;
      function IsTargetLess : boolean;
      function IsBuildTarget : boolean;
      function IsEntityTarget : boolean;
      function IsCoordinateTarget : boolean;
      function IsSelftarget : boolean;
      function ToRTarget(Owner : TEntity) : RTarget;
      procedure Unset;
      class operator Implicit(a : RCommanderAbilityTarget) : RParam;
  end;

  ACommanderAbilityTarget = array of RCommanderAbilityTarget;

  ACommanderAbilityTargetHelper = record helper for ACommanderAbilityTarget
    public
      function ToRTargets(Owner : TEntity) : ATarget;
      function ToRParam : RParam;
      function Count : integer;
      function Clone : ACommanderAbilityTarget;
  end;

  RParamHelper = record helper for RParam
    public
      function AsATarget : ATarget;
      function AsACommanderAbilityTarget : ACommanderAbilityTarget;
      function AsRTargetValidity : RTargetValidity;
      function AsAResourceCost : AResourceCost;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}


function ComputeSpawningPattern(Position, Front : RVector2; IsSpawner : boolean; Index, Count : integer) : RVector2;

implementation

uses
  BaseConflict.Globals;

function ComputeSpawningPattern(Position, Front : RVector2; IsSpawner : boolean; Index, Count : integer) : RVector2;
const
  SPAWN_DISTANCE = 1.5 / 0.45;
var
  Side : RVector2;
  Size : single;
begin
  if (Count > 1) then
  begin
    if IsSpawner then Size := 0.2
    else Size := 0.45;
    Side := Front * SPAWN_DISTANCE * Size;
    // for two entities spawn them beside each other
    case Count of
      2 : Side := Side.Rotate(PI / 2) * 0.5;
      3 : Side := Side.Rotate(PI / 3);
      4 : Side := Side.Rotate(PI / 4);
    end;
    Side := Side.Rotate((index / Count) * 2 * PI);
    Position := Position + Side;
  end;
  Result := Position;
end;

{ RTarget }

constructor RTarget.Create(Target : TEntity);
begin
  if Target = nil then
  begin
    FTargetType := ttNone;
    FEntityID := 0;
    FTargetCoord := RVector2.ZERO;
    exit;
  end;
  FTargetType := ttEntity;
  FEntityID := Target.ID;
  FTargetCoord := RVector2.ZERO;
end;

constructor RTarget.Create(TargetEntityID : integer);
begin
  FTargetType := ttEntity;
  FEntityID := TargetEntityID;
  FTargetCoord := RVector2.ZERO;
end;

constructor RTarget.CreateBuildTarget(BuildGridID : integer; Coord : RIntVector2);
begin
  FTargetType := ttBuild;
  FBuildGridID := BuildGridID;
  FBuildZoneCoord := Coord;
end;

constructor RTarget.Create(Target : RVector2);
begin
  FTargetType := ttCoordinate;
  FTargetCoord := Target;
  FEntityID := 0;
end;

class function RTarget.CreateEmpty : RTarget;
begin
  FillChar(Result, SizeOf(RTarget), 0);
  assert(Result.IsEmpty);
end;

class operator RTarget.Equal(a, b : RTarget) : boolean;
begin
  Result := (a.TargetType = b.TargetType);
  if Result then
    case a.TargetType of
      ttNone :;
      ttCoordinate : Result := a.FTargetCoord.SimilarTo(b.FTargetCoord, SPATIALEPSILON);
      ttEntity : Result := a.EntityID = b.EntityID;
      ttBuild : Result := (a.BuildGridID = b.BuildGridID) and (a.BuildGridCoordinate = b.BuildGridCoordinate);
    end;
end;

class operator RTarget.NotEqual(a, b : RTarget) : boolean;
begin
  Result := (a.TargetType <> b.TargetType);
  if not Result then
    case a.TargetType of
      ttNone :;
      ttCoordinate : Result := not a.FTargetCoord.SimilarTo(b.FTargetCoord, SPATIALEPSILON);
      ttEntity : Result := a.EntityID <> b.EntityID;
      ttBuild : Result := (a.BuildGridID <> b.BuildGridID) or (a.BuildGridCoordinate <> b.BuildGridCoordinate);
    end;
end;

class operator RTarget.Explicit(a : RVector2) : RTarget;
begin
  Result := RTarget.Create(a);
end;

class operator RTarget.Explicit(a : TEntity) : RTarget;
begin
  Result := RTarget.Create(a);
end;

function RTarget.GetBuildZone : TBuildZone;
begin
  assert(IsBuildTarget);
  Result := Game.Map.BuildZones.GetBuildZone(BuildGridID);
end;

function RTarget.GetRealBuildPosition(NeededGridSize : RIntVector2) : RVector2;
begin
  Result := GetTargetPosition + (GetBuildZone.CoordBase * ((NeededGridSize.ToRVector / 2 - 0.5) * TBuildZone.GRIDNODESIZE));
end;

function RTarget.GetTargetEntity : TEntity;
begin
  Result := nil;
  if IsEntity and assigned(Game) and not Game.IsShuttingDown then
      Result := Game.EntityManager.GetEntityByID(EntityID);
end;

function RTarget.GetTargetPosition : RVector2;
var
  TargetEntity : TEntity;
  TargetBuildZone : TBuildZone;
begin
  if IsCoordinate then Result := FTargetCoord
  else if IsEntity then
  begin
    if Game.EntityManager.TryGetEntityByID(EntityID, TargetEntity) then
    begin
      Result := TargetEntity.Position;
      FTargetCoord := Result;
    end;
  end
  else if IsBuildTarget then
  begin
    TargetBuildZone := Game.Map.BuildZones.GetBuildZone(BuildGridID);
    assert(assigned(TargetBuildZone));
    FTargetCoord := TargetBuildZone.GetCenterOfField(BuildGridCoordinate);
  end;
  Result := FTargetCoord;
end;

function RTarget.Hash : integer;
begin
  Result := Ord(TargetType) xor EntityID xor FTargetCoord.GetHashValue;
end;

class operator RTarget.Implicit(a : RTarget) : RParam;
begin
  Result := RParam.From<RTarget>(a);
end;

function RTarget.IsEmpty : boolean;
begin
  Result := TargetType = ttNone;
end;

function RTarget.IsBuildTarget : boolean;
begin
  Result := TargetType = ttBuild;
end;

function RTarget.IsCoordinate : boolean;
begin
  Result := TargetType = ttCoordinate;
end;

function RTarget.IsEntity : boolean;
begin
  Result := TargetType = ttEntity;
end;

function RTarget.IsEntityValid : boolean;
begin
  Result := GetTargetEntity <> nil;
end;

function RTarget.TryGetTargetEntity(out Entity : TEntity) : boolean;
begin
  Entity := GetTargetEntity;
  Result := assigned(Entity);
end;

{ RCommanderAbilityTarget }

constructor RCommanderAbilityTarget.Create(Target : RVector2);
begin
  self.FIsSet := True;
  self.FCoord := Target;
  self.FType := ctCoordinate;
end;

constructor RCommanderAbilityTarget.Create(Target : TEntity);
begin
  self.FIsSet := True;
  self.FEntityID := Target.ID;
  self.FType := ctEntity;
end;

constructor RCommanderAbilityTarget.Create(TargetEntity : integer);
begin
  self.FIsSet := True;
  self.FEntityID := TargetEntity;
  self.FType := ctEntity;
end;

constructor RCommanderAbilityTarget.CreateBuildTarget(TargetBuildZone : integer; TargetCoordinate : RIntVector2);
begin
  self.FIsSet := True;
  self.FType := ctBuildZone;
  self.FGridID := TargetBuildZone;
  self.FGridCoordinate := TargetCoordinate;
end;

class function RCommanderAbilityTarget.CreateEmpty : RCommanderAbilityTarget;
begin
  Result := RCommanderAbilityTarget.CreateUnset(ctNone);
end;

class function RCommanderAbilityTarget.CreateSelftarget : RCommanderAbilityTarget;
begin
  Result.FIsSet := True;
  Result.FType := ctSelftarget;
end;

class function RCommanderAbilityTarget.CreateTargetLess : RCommanderAbilityTarget;
begin
  Result.FIsSet := True;
  Result.FType := ctTargetLess;
end;

constructor RCommanderAbilityTarget.CreateUnset(CAType : EnumCommanderAbilityTargetType);
begin
  self.FIsSet := (CAType in COMMANDER_ABILITIES_WITHOUT_TARGET);
  self.FType := CAType;
end;

function RCommanderAbilityTarget.GetWorldPosition(Owner : TEntity) : RVector2;
begin
  assert(IsCoordinateTarget or IsEntityTarget or IsBuildTarget);
  Result := ToRTarget(Owner).GetTargetPosition;
end;

class operator RCommanderAbilityTarget.Implicit(a : RCommanderAbilityTarget) : RParam;
begin
  Result := RParam.From<RCommanderAbilityTarget>(a);
end;

function RCommanderAbilityTarget.IsBuildTarget : boolean;
begin
  Result := FType = ctBuildZone;
end;

function RCommanderAbilityTarget.IsCoordinateTarget : boolean;
begin
  Result := FType = ctCoordinate;
end;

function RCommanderAbilityTarget.IsEmpty : boolean;
begin
  Result := FType = ctNone;
end;

function RCommanderAbilityTarget.IsEntityTarget : boolean;
begin
  Result := FType = ctEntity
end;

function RCommanderAbilityTarget.IsSelftarget : boolean;
begin
  Result := FType = ctSelftarget;
end;

function RCommanderAbilityTarget.IsTargetLess : boolean;
begin
  Result := FType = ctTargetLess;
end;

function RCommanderAbilityTarget.ToRTarget(Owner : TEntity) : RTarget;
begin
  if not IsSet then exit(RTarget.CreateEmpty);
  case FType of
    ctNone, ctTargetLess : Result := RTarget.CreateEmpty;
    ctSelftarget :
      begin
        if not assigned(Owner) then
            raise EInvalidArgument.Create('RCommanderAbilityTarget.ToRTarget: Need Owner to resolve selftarget!');
        Result := RTarget(Owner);
      end;
    ctCoordinate : Result := RTarget.Create(FCoord);
    ctEntity : Result := RTarget.Create(self.FEntityID);
    ctBuildZone : Result := RTarget.CreateBuildTarget(FGridID, FGridCoordinate);
  else
    assert(False);
  end;
end;

procedure RCommanderAbilityTarget.Unset;
begin
  self.FIsSet := False;
end;

{ ACommanderAbilityTargetHelper }

function ACommanderAbilityTargetHelper.Clone : ACommanderAbilityTarget;
var
  i : integer;
begin
  setlength(Result, Count);
  for i := 0 to Count - 1 do
      Result[i] := self[i];
end;

function ACommanderAbilityTargetHelper.Count : integer;
begin
  Result := length(self);
end;

function ACommanderAbilityTargetHelper.ToRParam : RParam;
begin
  Result := RParam.FromArray<RCommanderAbilityTarget>(TArray<RCommanderAbilityTarget>(self));
end;

function ACommanderAbilityTargetHelper.ToRTargets(Owner : TEntity) : ATarget;
begin
  Result := ATarget(HArray.Map<RCommanderAbilityTarget, RTarget>(self,
    function(const Item : RCommanderAbilityTarget) : RTarget
    begin
      Result := Item.ToRTarget(Owner);
    end));
end;

{ RParamHelper }

function RParamHelper.AsACommanderAbilityTarget : ACommanderAbilityTarget;
begin
  Result := ACommanderAbilityTarget(self.AsArray<RCommanderAbilityTarget>);
end;

function RParamHelper.AsAResourceCost : AResourceCost;
begin
  Result := AResourceCost(self.AsArray<RResourceCost>);
end;

function RParamHelper.AsATarget : ATarget;
begin
  Result := ATarget(self.AsArray<RTarget>);
end;

function RParamHelper.AsRTargetValidity : RTargetValidity;
begin
  Result := self.AsType<RTargetValidity>;
end;

{ ATargetHelper }

constructor ATargetHelper.Create(Item : TEntity);
begin
  setlength(self, 1);
  self[0] := RTarget(Item);
end;

procedure ATargetHelper.Append(Values : ATarget);
var
  i, offset : integer;
begin
  offset := length(self);
  setlength(self, length(self) + length(Values));
  for i := 0 to length(Values) - 1 do
      self[i + offset] := Values[i];
end;

function ATargetHelper.Contains(const Target : RTarget) : boolean;
var
  i : integer;
begin
  Result := False;
  if not Target.IsEntity then exit;
  for i := 0 to length(self) - 1 do
    if self[i].IsEntity and (self[i].EntityID = Target.EntityID) then
        exit(True);
end;

function ATargetHelper.Count : integer;
begin
  Result := length(self);
end;

constructor ATargetHelper.Create(Item : RVector2);
begin
  setlength(self, 1);
  self[0] := RTarget(Item);
end;

constructor ATargetHelper.Create(EntityID : integer);
begin
  setlength(self, 1);
  self[0] := RTarget.Create(EntityID);
end;

constructor ATargetHelper.Create(Item : RTarget);
begin
  setlength(self, 1);
  self[0] := Item;
end;

class function ATargetHelper.CreateEmpty : ATarget;
begin
  setlength(Result, 1);
  Result[0] := RTarget.CreateEmpty;
end;

function ATargetHelper.First : RTarget;
begin
  assert(HasIndex(0));
  Result := self[0];
end;

function ATargetHelper.HasIndex(Index : integer) : boolean;
begin
  Result := (index < Count) and (index >= 0);
end;

function ATargetHelper.ToRParam : RParam;
begin
  Result := RParam.FromArray<RTarget>(TArray<RTarget>(self));
end;

{ RTargetValidity }

constructor RTargetValidity.Create(Targets : ATarget);
var
  i : integer;
begin
  if Targets.Count > MAX_TARGETS then
      raise EInvalidArgument.Create('RTargetValidity.Create: Maximal ' + Inttostr(MAX_TARGETS) + ' targets are allowed for welas, atm!.');
  self.TogetherValid := True;
  self.IsInitialized := True;
  SingleValidityMask := [low(byte) .. high(byte)];
  self.TargetCount := Targets.Count;
  for i := 0 to TargetCount - 1 do
    if Targets[i].IsEmpty then
        exclude(SingleValidityMask, i);
end;

class operator RTargetValidity.Implicit(a : RTargetValidity) : RParam;
begin
  Result := RParam.From<RTargetValidity>(a);
end;

function RTargetValidity.IsValid : boolean;
var
  i : integer;
begin
  if not IsInitialized then exit(True);
  Result := TogetherValid;
  for i := 0 to TargetCount - 1 do
      Result := Result and (i in SingleValidityMask);
end;

procedure RTargetValidity.SetTogetherValid(const Value : boolean);
begin
  TogetherValid := TogetherValid and Value;
end;

procedure RTargetValidity.SetValidity(const Index : integer; const Value : boolean);
begin
  if MAX_TARGETS > index then
  begin
    if (index in SingleValidityMask) then
    begin
      if Value then
          include(SingleValidityMask, index)
      else
          exclude(SingleValidityMask, index);
    end;
  end
  else raise ECorruptData.Create('RTargetValidity.SetValidity: Target has been validated, but isnt''t present in structure!');
end;

initialization

ScriptManager.ExposeType(TypeInfo(RTarget));
ScriptManager.ExposeType(TypeInfo(EnumTargetType));
ScriptManager.ExposeType(TypeInfo(EnumCommanderAbilityTargetType));

end.
