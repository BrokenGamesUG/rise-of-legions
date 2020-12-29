unit BaseConflict.Types.Shared;

interface

uses
  Engine.Helferlein.Windows,
  BaseConflict.Constants;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  /// <summary>
  /// gsLoading - Players are loading and connecting, game time has not been started
  /// gsWarming - Players are all ready and game starts, countdown for first tick is running
  /// gsPlaying - Players are playing and game time is running
  /// gsShutdown - Game is shutting down
  /// </summary>
  EnumInGameStatus = (gsLoading, gsWarming, gsPlaying, gsShutdown);

  EnumComparator = (coLowerEqual, coLower, coGreaterEqual, coGreater, coEqual);

function ResourceCompare(ResourceType : EnumResource; const Resource : RParam; Comparator : EnumComparator; ReferenceValue : integer) : boolean; overload;
function ResourceCompare(ResourceType : EnumResource; const Resource : RParam; Comparator : EnumComparator; ReferenceValue : single) : boolean; overload;
function ResourceCompare(ResourceType : EnumResource; const Resource : RParam; Comparator : EnumComparator; const ReferenceValue : RParam; ReferenceFactor : single = 1.0) : boolean; overload;
function ResourcePercentage(ResourceType : EnumResource; const Balance, Cap : RParam) : single;
function ResourceAdd(ResourceType : EnumResource; const Summand, Summand2 : RParam) : RParam;
function ResourceSubtract(ResourceType : EnumResource; const Minuend, Subtrahend : RParam) : RParam;
function ResourceAsSingle(ResourceType : EnumResource; const Resource : RParam) : single;
function ResourceOverride(ResourceType : EnumResource; const Resource : RParam; const OverrideValue : single) : RParam;

type
  RResourceCost = record
    ResourceType : EnumResource;
    Amount : RParam;
  end;

  AResourceCost = array of RResourceCost;

  AResourceCostHelper = record helper for AResourceCost
    public
      function ToRParam : RParam;
      function Count : integer;
      function TryGetValue(ResourceType : EnumResource; out Amount : RParam) : boolean;
      function GetValue(ResourceType : EnumResource) : RParam;
  end;

  RIncome = record
    Gold, Wood : single;
    constructor Create(Gold, Wood : single);
    function ToRParam : RParam;
    class operator add(const a, b : RIncome) : RIncome; static;
  end;

  TGameTimer = class(TTimer)
    protected
      function GetTimeStamp : double; override;
    public
      property StartingTime : double read FLastTime write FLastTime;
  end;

  EnumLaneDirection = (ldNormal, ldReverse);

  PLaneDirection = ^EnumLaneDirection;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

uses
  BaseConflict.Globals;

function ResourceCompare(ResourceType : EnumResource; const Resource : RParam; Comparator : EnumComparator; ReferenceValue : integer) : boolean; overload;
begin
  Result := False;
  if ResourceType in RES_INT_RESOURCES then
  begin
    case Comparator of
      coLowerEqual : Result := Resource.AsInteger <= ReferenceValue;
      coLower : Result := Resource.AsInteger < ReferenceValue;
      coGreaterEqual : Result := Resource.AsInteger >= ReferenceValue;
      coGreater : Result := Resource.AsInteger > ReferenceValue;
      coEqual : Result := Resource.AsInteger = ReferenceValue;
    end;
  end
  else
  begin
    case Comparator of
      coLowerEqual : Result := Resource.AsSingle <= ReferenceValue;
      coLower : Result := Resource.AsSingle < ReferenceValue;
      coGreaterEqual : Result := Resource.AsSingle >= ReferenceValue;
      coGreater : Result := Resource.AsSingle > ReferenceValue;
      coEqual : Result := Resource.AsSingle = ReferenceValue;
    end;
  end;
end;

function ResourceCompare(ResourceType : EnumResource; const Resource : RParam; Comparator : EnumComparator; ReferenceValue : single) : boolean; overload;
var
  IntReferenceValue : integer;
begin
  Result := False;
  if ResourceType in RES_INT_RESOURCES then
  begin
    IntReferenceValue := round(ReferenceValue);
    case Comparator of
      coLowerEqual : Result := Resource.AsInteger <= IntReferenceValue;
      coLower : Result := Resource.AsInteger < IntReferenceValue;
      coGreaterEqual : Result := Resource.AsInteger >= IntReferenceValue;
      coGreater : Result := Resource.AsInteger > IntReferenceValue;
      coEqual : Result := Resource.AsInteger = IntReferenceValue;
    end;
  end
  else
  begin
    case Comparator of
      coLowerEqual : Result := Resource.AsSingle <= ReferenceValue;
      coLower : Result := Resource.AsSingle < ReferenceValue;
      coGreaterEqual : Result := Resource.AsSingle >= ReferenceValue;
      coGreater : Result := Resource.AsSingle > ReferenceValue;
      coEqual : Result := Resource.AsSingle = ReferenceValue;
    end;
  end;
end;

function ResourceCompare(ResourceType : EnumResource; const Resource : RParam; Comparator : EnumComparator; const ReferenceValue : RParam; ReferenceFactor : single) : boolean;
begin
  Result := False;
  if ResourceType in RES_INT_RESOURCES then
  begin
    case Comparator of
      coLowerEqual : Result := Resource.AsInteger <= ReferenceValue.AsInteger * ReferenceFactor;
      coLower : Result := Resource.AsInteger < ReferenceValue.AsInteger * ReferenceFactor;
      coGreaterEqual : Result := Resource.AsInteger >= ReferenceValue.AsInteger * ReferenceFactor;
      coGreater : Result := Resource.AsInteger > ReferenceValue.AsInteger * ReferenceFactor;
      coEqual : Result := Resource.AsInteger = ReferenceValue.AsInteger * ReferenceFactor;
    end;
  end
  else
  begin
    case Comparator of
      coLowerEqual : Result := Resource.AsSingle <= ReferenceValue.AsSingle * ReferenceFactor;
      coLower : Result := Resource.AsSingle < ReferenceValue.AsSingle * ReferenceFactor;
      coGreaterEqual : Result := Resource.AsSingle >= ReferenceValue.AsSingle * ReferenceFactor;
      coGreater : Result := Resource.AsSingle > ReferenceValue.AsSingle * ReferenceFactor;
      coEqual : Result := Resource.AsSingle = ReferenceValue.AsSingle * ReferenceFactor;
    end;
  end;
end;

function ResourceSubtract(ResourceType : EnumResource; const Minuend, Subtrahend : RParam) : RParam;
begin
  if ResourceType in RES_INT_RESOURCES then Result := Minuend.AsInteger - Subtrahend.AsInteger
  else Result := Minuend.AsSingle - Subtrahend.AsSingle;
end;

function ResourceAdd(ResourceType : EnumResource; const Summand, Summand2 : RParam) : RParam;
begin
  if ResourceType in RES_INT_RESOURCES then Result := Summand.AsInteger + Summand2.AsInteger
  else Result := Summand.AsSingle + Summand2.AsSingle;
end;

function ResourcePercentage(ResourceType : EnumResource; const Balance, Cap : RParam) : single;
begin
  if ResourceType in RES_INT_RESOURCES then Result := Balance.AsInteger / Cap.AsInteger
  else Result := Balance.AsSingle / Cap.AsSingle;
end;

function ResourceAsSingle(ResourceType : EnumResource; const Resource : RParam) : single;
begin
  if ResourceType in RES_INT_RESOURCES then Result := Resource.AsInteger
  else Result := Resource.AsSingle;
end;

function ResourceOverride(ResourceType : EnumResource; const Resource : RParam; const OverrideValue : single) : RParam;
begin
  if OverrideValue <= 0 then
      Result := Resource
  else
    if ResourceType in RES_INT_RESOURCES then Result := integer(round(OverrideValue))
  else Result := OverrideValue;
end;

{ AResourceCostHelper }

function AResourceCostHelper.Count : integer;
begin
  Result := length(self);
end;

function AResourceCostHelper.GetValue(ResourceType : EnumResource) : RParam;
begin
  if not TryGetValue(ResourceType, Result) then
      Result := RPARAM_EMPTY;
end;

function AResourceCostHelper.ToRParam : RParam;
begin
  Result := RParam.FromArray<RResourceCost>(TArray<RResourceCost>(self));
end;

function AResourceCostHelper.TryGetValue(ResourceType : EnumResource; out Amount : RParam) : boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to Count - 1 do
    if self[i].ResourceType = ResourceType then
    begin
      Amount := self[i].Amount;
      exit(True);
    end;
end;

{ TGameTimer }

function TGameTimer.GetTimeStamp : double;
begin
  {$IF defined(CLIENT) and not defined(MAPEDITOR)}
  assert(assigned(Game));
  Result := Game.ServerTime;
  {$ELSE}
  Result := GameTimeManager.GetFloatingTimestamp;
  {$ENDIF}
end;

{ RIncome }

class operator RIncome.add(const a, b : RIncome) : RIncome;
begin
  Result.Gold := a.Gold + b.Gold;
  Result.Wood := a.Wood + b.Wood;
end;

constructor RIncome.Create(Gold, Wood : single);
begin
  self.Gold := Gold;
  self.Wood := Wood;
end;

function RIncome.ToRParam : RParam;
begin
  Result := RParam.From<RIncome>(self);
end;

end.
