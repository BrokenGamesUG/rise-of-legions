unit BaseConflict.Classes.Shared;

interface

uses
  System.Math,
  System.SysUtils,
  System.RTTI,
  System.Win.ComObj,
  System.Classes,
  System.Hash,
  Generics.Defaults,
  Generics.Collections,
  BaseConflict.Entity,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Types.Shared,
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Collision,
  Engine.Math.Collision2D,
  Engine.Math;

type

  TEntityDataCache = class
    protected
      type
      RKey = record
        EventIdentifier : EnumEventIdentifier;
        ComponentGroup : SetComponentGroup;
        Index : integer;
      end;

      TEntityWrapper = class
        DataEntity : TEntity;
        IsSpell : boolean;
        CachedValues : TDictionary<RKey, RParam>;
        destructor Destroy; override;
      end;

      RCacheKey = record
        Scriptfile : string;
        League, Level : integer;
        constructor Create(const Scriptfile : string; League, Level : integer);
        function Hash : integer;
        class operator equal(a, b : RCacheKey) : boolean;
      end;
    var
      FCache : TObjectDictionary<RCacheKey, TEntityWrapper>;
      function GetEntityCache(const Scriptfile : string; League, Level : integer) : TEntityWrapper;
    public
      function Read(const Scriptfile : string; League, Level : integer; Event : EnumEventIdentifier; Group : SetComponentGroup = []; Index : integer = -1; ByPassCache : boolean = False) : RParam;
      /// <summary> Triggers an event on the cached entity. Used for initializing tooltips by components. </summary>
      procedure Trigger(const Scriptfile : string; League, Level : integer; Event : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup = []);
      /// <summary> Writes a value to the cached entity. Use with care as it could introduce side effects to other useages. </summary>
      procedure Write(const Scriptfile : string; League, Level : integer; Event : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup = []);
      /// <summary> Returns the cached entity. ATTENTION: Do not modify this in any kind or free it. </summary>
      function GetEntity(const Scriptfile : string; League, Level : integer) : TEntity;
      constructor Create;
      destructor Destroy; override;
  end;

  TEntityLooseQuadtreeData = class(TLooseQuadTreeNodeData<TEntity>)
    protected
      FTeamID : integer;
      procedure SetTeamID(const Value : integer);
    public
      /// <summary> TeamID for this data, set new teamID will update datanode in tree</summary>
      property TeamID : integer read FTeamID write SetTeamID;
      constructor Create(Boundaries : RCircle; Data : TEntity);
  end;

  TEntityLooseQuadTreeNode = class(TLooseQuadTreeNode<TEntity>)
    protected
      const
      MAX_TEAMS = 6;
    var
      /// <summary> saves for every team, number of entities saved in this node and every subnode.</summary>
      FTeamCount : array [0 .. MAX_TEAMS - 1] of integer;
      procedure Split; override;
    public
      procedure AddItemRecursive(Item : TLooseQuadTreeNodeData<TEntity>); override;
      procedure RemoveItemRecursive(Item : TLooseQuadTreeNodeData<TEntity>); override;
      procedure GetIntersections(const Intersector : RCircle; SourceTeamID : integer; TargetTeamConstraint : EnumTargetTeamConstraint; var Intersections : TList<TEntityLooseQuadtreeData>); reintroduce;
  end;

  TEntityLooseQuardtree = class(TLooseQuadTree<TEntity>)
    public
      constructor Create(WorldRect : RRectFloat; MinWidth : single);
      function GetIntersections(Intersector : RCircle; SourceTeamID : integer; TargetTeamConstraint : EnumTargetTeamConstraint) : TList<TEntityLooseQuadtreeData>; reintroduce;
  end;

  RUnitCosts = record
    Costs : TArray<RTuple<EnumResource, integer>>;
  end;

  TBalancingManager = class
    private
      const
      SCRIPTFILE_EXTENSIONS : array [0 .. 1] of string = ('.ets', '.sps');
      EXCEL_EXTENSIONS : array [0 .. 1] of string      = ('.xls', '.xlsx');
      UNITBALANCING_SHEET                              = 'UBL';
      SPELLBALANCING_SHEET                             = 'SBL';
      UNITNAME_COLUMN                                  = 1;
      TECHCOLUMN_CAPTION                               = 'Tier';
    private
      /// <summary> Sheet, RowName (e.g. unit name), ColumnName (e.g. property like health or attackspeed) -> value.
      /// Sheet, rowname, columname will be in lowercase.</summary>
      FData : TObjectDictionary<string, TObjectDictionary<string, TDictionary<string, Variant>>>;
      class constructor CreateSingleton;
      class destructor DestroySingleton;
    public
      constructor Create;
      /// <summary> Apply data from excel file to all scripts in scriptpath.</summary>
      procedure Apply;
      procedure LoadExcelFile(FileName : string);
      destructor Destroy; override;
  end;

var
  BalancingManager : TBalancingManager;

implementation

uses
  BaseConflict.Globals;

{ TBalancingManager }

procedure TBalancingManager.Apply;
type
  EnumValueType = (vtInteger, vtFloat, vtString);
var
  ScriptFiles : TStrings;
  ScriptFileExtension, FileName, Filecontent : string;
  Identifier, SheetName, PropertyName, UnitName, OldValueString, ValueString : string;
  Index, Count, DecimalPlaces : integer;
  ValueType : EnumValueType;
  Value : Variant;
  FileChanged : boolean;
begin
  ScriptFiles := nil;
  // gathering all files
  for ScriptFileExtension in SCRIPTFILE_EXTENSIONS do
      HFileIO.FindAllFiles(ScriptFiles, AbsolutePath(PATH_SCRIPT), '*' + ScriptFileExtension, True);
  for FileName in ScriptFiles do
  begin
    FileChanged := False;
    UnitName := ChangeFileExt(ExtractFileName(FileName), '');
    UnitName := UnitName.Replace('Drop', '').Replace('Spawner', '').Replace('Building', '').Replace('_Base', '').Replace('_', '');
    Filecontent := ContentManager.FileToString(FileName);
    index := Filecontent.IndexOf('{@');
    while index >= 0 do
    begin
      // get identifier to value
      Count := Filecontent.IndexOf('}', index) - index;
      Identifier := Filecontent.Substring(index + 2, Count - 2).Trim;
      SheetName := Identifier.Split(['_'])[0];
      PropertyName := Identifier.Split(['_'])[1];
      // get old value, to know place, length and format
      index := index + Count + 1;
      Count := Filecontent.IndexOfAny([')', ','], index) - index;
      OldValueString := Filecontent.Substring(index, Count).Trim;
      DecimalPlaces := 0;
      if OldValueString.Contains('.') then
      begin
        ValueType := vtFloat;
        OldValueString := OldValueString.Trim;
        DecimalPlaces := (OldValueString.Length - 1) - OldValueString.IndexOf('.');
      end
      else if OldValueString.StartsWith('at') then
          ValueType := vtString
      else
          ValueType := vtInteger;
      // sanity checks if data is available for lookup
      if FData.ContainsKey(SheetName.ToLowerInvariant) then
      begin
        if FData[SheetName.ToLowerInvariant].ContainsKey(UnitName.ToLowerInvariant) then
        begin
          if FData[SheetName.ToLowerInvariant][UnitName.ToLowerInvariant].ContainsKey(PropertyName.ToLowerInvariant) then
          begin
            // finally get value
            Value := FData[SheetName.ToLowerInvariant][UnitName.ToLowerInvariant][PropertyName.ToLowerInvariant];
            case ValueType of
              vtInteger : ValueString := integer(Value).ToString;
              vtFloat : ValueString := FloatToStrF(Value, ffFixed, 7, DecimalPlaces, EngineFloatFormatSettings);
              vtString : ValueString := Value;
            end;
            if OldValueString <> ValueString then
            begin
              Filecontent := Filecontent.Remove(index, Count).Insert(index, ValueString);
              FileChanged := True;
            end;
          end
          else HLog.Console('TBalancingManager.Apply: Couldn''t find the property "%s" for unit "%s" in sheet "%s".', [PropertyName, UnitName, SheetName]);
        end
        else HLog.Console('TBalancingManager.Apply: Couldn''t find the row for unit "%s" in sheet "%s".', [UnitName, SheetName]);
      end
      else HLog.Console('TBalancingManager.Apply: Couldn''t find the sheet "%s".', [SheetName]);
      index := Filecontent.IndexOf('{@', index);
    end;
    // only if any data has changed, write back file (this will pretend that the game will reload every skript everytime
    // the balancing file is loaded)
    if FileChanged then
        HString.SaveStringToFile(FileName, Filecontent);
  end;
  ScriptFiles.Free;
end;

constructor TBalancingManager.Create();
begin
  FData := TObjectDictionary < string, TObjectDictionary < string, TDictionary<string, Variant> >>.Create([doOwnsValues]);
end;

class constructor TBalancingManager.CreateSingleton;
begin
  BalancingManager := TBalancingManager.Create;
end;

destructor TBalancingManager.Destroy;
begin
  FData.Free;
  inherited;
end;

class destructor TBalancingManager.DestroySingleton;
begin
  BalancingManager.Free;
end;

procedure TBalancingManager.LoadExcelFile(FileName : string);
  procedure ParseUnitBalancingData(const SheetData : Variant; MaxCol, MaxRow : integer; const DataDict : TObjectDictionary < string, TDictionary < string, Variant >> );
  var
    X, Y : integer;
    DataStartRow, TechColumn : integer;
    Content, UnitName : string;
    ColumnNames : TDictionary<integer, string>;
  begin
    ColumnNames := TDictionary<integer, string>.Create();
    DataStartRow := -1;
    TechColumn := -1;
    // search for section which contains unit balancing data
    for Y := 1 to MaxRow do
      if SameText(SheetData[Y, 1], 'UNIT BALANCING') then
      begin
        DataStartRow := Y + 2; // skip caption and column naming row (+1)
        for X := 1 to MaxCol do
        begin
          Content := SheetData[Y + 1, X];
          if not Content.IsEmpty then
          begin
            ColumnNames.Add(X, Content);
            if SameText(Content, TECHCOLUMN_CAPTION) then
                TechColumn := X;
          end;
        end;
        break;
      end;
    assert(DataStartRow > 0, 'Does not find UNIT BALANCING section');
    assert(TechColumn > 0, 'Does not find "Tier" column');
    for Y := DataStartRow to MaxRow do
      // skip all rows without tech entry, because this are spacing rows or captions
      if not string(SheetData[Y, TechColumn]).IsEmpty then
      begin
        UnitName := SheetData[Y, UNITNAME_COLUMN];
        // Remove whitespace, because filename would not likely contains one
        UnitName := UnitName.Replace(' ', '');
        DataDict.Add(UnitName.ToLowerInvariant, TDictionary<string, Variant>.Create());
        for X := 2 to MaxCol do
          if not string(SheetData[Y, X]).IsEmpty then
              DataDict[UnitName.ToLowerInvariant].Add(ColumnNames[X].Trim([' ', '*']).ToLowerInvariant, SheetData[Y, X]);
      end;
    ColumnNames.Free;
  end;

  procedure ParseSpellBalancingData(const SheetData : Variant; MaxCol, MaxRow : integer; const DataDict : TObjectDictionary < string, TDictionary < string, Variant >> );
  var
    X, Y : integer;
    DataStartRow, TechColumn : integer;
    Content, UnitName : string;
    ColumnNames : TDictionary<integer, string>;
  begin
    ColumnNames := TDictionary<integer, string>.Create();
    DataStartRow := -1;
    TechColumn := -1;
    // search for section which contains spell balancing data
    for Y := 1 to MaxRow do
      if SameText(SheetData[Y, 1], 'SPELL BALANCING') then
      begin
        DataStartRow := Y + 2; // skip caption and column naming row (+1)
        for X := 1 to MaxCol do
        begin
          Content := SheetData[Y + 1, X];
          if not Content.IsEmpty then
          begin
            ColumnNames.Add(X, Content);
            if SameText(Content, TECHCOLUMN_CAPTION) then
                TechColumn := X;
          end;
        end;
        break;
      end;
    assert(DataStartRow > 0, 'Does not find SPELL BALANCING section');
    assert(TechColumn > 0, 'Does not find "Tier" column');
    for Y := DataStartRow to MaxRow do
      // skip all rows without tech entry, because this are spacing rows or captions
      if not string(SheetData[Y, TechColumn]).IsEmpty then
      begin
        UnitName := SheetData[Y, UNITNAME_COLUMN];
        // Remove whitespace, because filename would not likely contains one
        UnitName := UnitName.Replace(' ', '');
        DataDict.Add(UnitName.ToLowerInvariant, TDictionary<string, Variant>.Create());
        for X := 2 to MaxCol do
          if not string(SheetData[Y, X]).IsEmpty then
              DataDict[UnitName.ToLowerInvariant].Add(ColumnNames[X].Trim([' ', '*']).ToLowerInvariant, SheetData[Y, X]);
      end;
    ColumnNames.Free;
  end;

var
  i : integer;
  MaxRow, MaxCol : integer;
  Sheet : Variant;
  ExcelApp, SheetData : Variant;
  SheetName : string;
begin
  FData.Clear;
  assert(HString.ContainsString(HArray.ConvertDynamicToTArray<string>(EXCEL_EXTENSIONS), ExtractFileExt(FileName).ToLowerInvariant));
  ExcelApp := createoleobject('excel.application');
  ExcelApp.Workbooks.open(FileName);
  for i := 1 to ExcelApp.WorkSheets.Count do
  begin
    Sheet := ExcelApp.WorkSheets.Item[i];
    MaxRow := Sheet.Usedrange.EntireRow.Count;
    MaxCol := Sheet.Usedrange.EntireColumn.Count;
    SheetData := Sheet.Usedrange.Value;
    SheetName := Sheet.Name;
    FData.Add(SheetName.ToLowerInvariant, TObjectDictionary < string, TDictionary < string, Variant >>.Create([doOwnsValues]));
    if SameText(SheetName, UNITBALANCING_SHEET) then
        ParseUnitBalancingData(SheetData, MaxCol, MaxRow, FData[SheetName.ToLowerInvariant]);
    if SameText(SheetName, SPELLBALANCING_SHEET) then
        ParseSpellBalancingData(SheetData, MaxCol, MaxRow, FData[SheetName.ToLowerInvariant]);
  end;
  ExcelApp.Workbooks.Close;
end;

{ TEntityLooseQuardtree }

constructor TEntityLooseQuardtree.Create(WorldRect : RRectFloat; MinWidth : single);
begin
  if not WorldRect.IsSquare then
  begin
    WorldRect.Width := max(WorldRect.Width, WorldRect.Height);
    WorldRect.Height := max(WorldRect.Width, WorldRect.Height);
  end;
  FRoot := TEntityLooseQuadTreeNode.Create(WorldRect, MinWidth, nil);
end;

function TEntityLooseQuardtree.GetIntersections(Intersector : RCircle; SourceTeamID : integer; TargetTeamConstraint : EnumTargetTeamConstraint) : TList<TEntityLooseQuadtreeData>;
begin
  Result := TList<TEntityLooseQuadtreeData>.Create;
  TEntityLooseQuadTreeNode(FRoot).GetIntersections(Intersector, SourceTeamID, TargetTeamConstraint, Result);
end;

{ TEntityLooseQuadTreeNode }

procedure TEntityLooseQuadTreeNode.AddItemRecursive(Item : TLooseQuadTreeNodeData<TEntity>);
var
  i : integer;
begin
  assert(Item is TEntityLooseQuadtreeData);
  if (Item.Boundaries.radius >= FBorderSizeHalf) or not HasChildren then AddItem(Item)
  else
    for i := 0 to CHILDCOUNT - 1 do
      if FChildren[i].FRealRect.ContainsPoint(Item.Boundaries.Center) then
      begin
        FChildren[i].AddItemRecursive(Item);
        break;
      end;
  FHasItems := True;
  // add item to this node, need to increment counter
  inc(FTeamCount[TEntityLooseQuadtreeData(Item).TeamID]);
end;

procedure TEntityLooseQuadTreeNode.GetIntersections(const Intersector : RCircle; SourceTeamID : integer; TargetTeamConstraint : EnumTargetTeamConstraint; var Intersections : TList<TEntityLooseQuadtreeData>);
var
  i : integer;
  // team : TeamType;
  nodeCanFulfillConstraint : boolean;
begin
  // target contraint to any type (enemies or allies), test if node can fulfill this constraint
  nodeCanFulfillConstraint := False;
  case TargetTeamConstraint of
    tcAll : nodeCanFulfillConstraint := HasItems;
    tcEnemies :
      begin
        // any entity in node or subnodes that not match sourceteam?
        for i := 0 to MAX_TEAMS - 1 do
          if i <> SourceTeamID then
          begin
            nodeCanFulfillConstraint := nodeCanFulfillConstraint or (FTeamCount[i] > 0);
          end;
      end;
    // any entity in node or subnodes that match sourceteam?
    tcAllies : nodeCanFulfillConstraint := FTeamCount[SourceTeamID] > 0;
  end;
  if not nodeCanFulfillConstraint then
      Exit;
  // node lies in area of interest?
  if not Intersector.IntersectRect(FLooseRect) then
      Exit;
  for i := 0 to FItems.Count - 1 do
    if Intersector.IntersectCircle(FItems[i].Boundaries) and // Check whether fine collision test passes
      ((TargetTeamConstraint = tcAll) or // Check whether team test passes
      ((TargetTeamConstraint = tcEnemies) and (SourceTeamID <> TEntityLooseQuadtreeData(FItems[i]).TeamID)) or
      ((TargetTeamConstraint = tcAllies) and (SourceTeamID = TEntityLooseQuadtreeData(FItems[i]).TeamID))) then
        Intersections.Add(TEntityLooseQuadtreeData(FItems[i]));
  if HasChildren then
    for i := 0 to CHILDCOUNT - 1 do TEntityLooseQuadTreeNode(FChildren[i]).GetIntersections(Intersector, SourceTeamID, TargetTeamConstraint, Intersections);
end;

procedure TEntityLooseQuadTreeNode.RemoveItemRecursive(Item : TLooseQuadTreeNodeData<TEntity>);
begin
  assert(Item is TEntityLooseQuadtreeData);
  if not assigned(Item) then Exit;
  inherited;
  Dec(FTeamCount[TEntityLooseQuadtreeData(Item).TeamID]);
end;

procedure TEntityLooseQuadTreeNode.Split;
begin
  FHasChildren := True;
  FChildren[0] := TEntityLooseQuadTreeNode.Create(RRectFloat.CreateWidthHeight(FRealRect.Left, FRealRect.Top, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, self);
  FChildren[1] := TEntityLooseQuadTreeNode.Create(RRectFloat.CreateWidthHeight(FRealRect.Left + FRealRect.Width / 2, FRealRect.Top, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, self);
  FChildren[2] := TEntityLooseQuadTreeNode.Create(RRectFloat.CreateWidthHeight(FRealRect.Left, FRealRect.Top + FRealRect.Height / 2, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, self);
  FChildren[3] := TEntityLooseQuadTreeNode.Create(RRectFloat.CreateWidthHeight(FRealRect.Left + FRealRect.Width / 2, FRealRect.Top + FRealRect.Height / 2, FRealRect.Width / 2, FRealRect.Height / 2), FMinWidth, self);
end;

{ TEntityLooseQuadtreeData }

constructor TEntityLooseQuadtreeData.Create(Boundaries : RCircle; Data : TEntity);
begin
  inherited;
  TeamID := Data.TeamID;
end;

procedure TEntityLooseQuadtreeData.SetTeamID(const Value : integer);
var
  owningTree : TEntityLooseQuardtree;
begin
  if Value <> FTeamID then
  begin
    // remove datanode with old teamID to ensure that teamID-table will be correctly maintained
    owningTree := TEntityLooseQuardtree(FOwningTree);
    if assigned(owningTree) then
        owningTree.RemoveItem(self);
    FTeamID := Value;
    if assigned(owningTree) then
        owningTree.AddItem(self);
  end;
end;

{ TEntityDataCache }

constructor TEntityDataCache.Create;
begin
  FCache := TObjectDictionary<RCacheKey, TEntityWrapper>.Create([doOwnsValues],
    TEqualityComparer<RCacheKey>.Construct(
    function(const Left, right : RCacheKey) : boolean
    begin
      Result := Left = right;
    end,
    function(const Value : RCacheKey) : integer
    begin
      Result := Value.Hash;
    end
    ));
end;

destructor TEntityDataCache.Destroy;
begin
  FCache.Free;
end;

function TEntityDataCache.GetEntity(const Scriptfile : string; League, Level : integer) : TEntity;
var
  EntityCache : TEntityWrapper;
begin
  EntityCache := GetEntityCache(Scriptfile, League, Level);
  Result := EntityCache.DataEntity;
end;

function TEntityDataCache.GetEntityCache(const Scriptfile : string; League, Level : integer) : TEntityWrapper;
begin
  if not FCache.TryGetValue(RCacheKey.Create(Scriptfile, League, Level), Result) then
  begin
    Result := TEntityWrapper.Create;
    if Scriptfile.Contains(FILE_EXTENSION_SPELL) then
    begin
      Result.DataEntity := TEntity.Create(GlobalEventbus);
      Result.DataEntity.Blackboard.SetIndexedValue(eiResourceBalance, [0], ord(reCardLevel), Level);
      Result.DataEntity.Blackboard.SetIndexedValue(eiResourceBalance, [0], ord(reCardLeague), League);
      Result.IsSpell := True;
      Result.DataEntity.ApplyScript(Scriptfile, 'CreateData', [Result.DataEntity, TValue.From<integer>(0), TValue.From<integer>(1)]);
    end
    else
    begin
      Result.DataEntity := TEntity.CreateDataFromScript(
        Scriptfile,
        GlobalEventbus,
        procedure(Entity : TEntity)
        begin
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), Level);
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), League);
        end);
    end;
    Result.CachedValues := TDictionary<RKey, RParam>.Create;
    FCache.Add(RCacheKey.Create(Scriptfile, League, Level), Result);
  end;
end;

function TEntityDataCache.Read(const Scriptfile : string; League, Level : integer; Event : EnumEventIdentifier; Group : SetComponentGroup; Index : integer; ByPassCache : boolean) : RParam;
var
  EntityCache : TEntityWrapper;
  Key : RKey;
begin
  if Scriptfile = '' then Exit(RPARAM_EMPTY);
  EntityCache := GetEntityCache(Scriptfile, League, Level);
  Key.EventIdentifier := Event;
  if EntityCache.IsSpell and (Group <> [1]) then Group := [0];
  Key.ComponentGroup := Group;
  Key.Index := index;
  if ByPassCache or not EntityCache.CachedValues.TryGetValue(Key, Result) then
  begin
    if index < 0 then Result := EntityCache.DataEntity.Eventbus.Read(Event, [], Group)
    else Result := EntityCache.DataEntity.Blackboard.GetIndexedValue(Event, Group, index);
    EntityCache.CachedValues.AddOrSetValue(Key, Result);
  end;
end;

procedure TEntityDataCache.Trigger(const Scriptfile : string; League, Level : integer; Event : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup);
var
  EntityCache : TEntityWrapper;
begin
  EntityCache := GetEntityCache(Scriptfile, League, Level);
  EntityCache.DataEntity.Eventbus.Trigger(Event, Values, Group);
end;

procedure TEntityDataCache.Write(const Scriptfile : string; League, Level : integer; Event : EnumEventIdentifier; Values : array of RParam; Group : SetComponentGroup);
var
  EntityCache : TEntityWrapper;
begin
  EntityCache := GetEntityCache(Scriptfile, League, Level);
  EntityCache.DataEntity.Eventbus.Write(Event, Values, Group);
end;

{ TEntityDataCache.TEntityWrapper }

destructor TEntityDataCache.TEntityWrapper.Destroy;
begin
  DataEntity.Free;
  CachedValues.Free;
  inherited;
end;

{ TEntityDataCache.RCacheKey }

constructor TEntityDataCache.RCacheKey.Create(const Scriptfile : string; League, Level : integer);
begin
  self.Scriptfile := Scriptfile;
  self.League := League;
  self.Level := Level;
end;

class operator TEntityDataCache.RCacheKey.equal(a, b : RCacheKey) : boolean;
begin
  Result := (a.Scriptfile = b.Scriptfile) and (a.League = b.League) and (a.Level = b.Level);
end;

function TEntityDataCache.RCacheKey.Hash : integer;
begin
  Result := THashBobJenkins.GetHashValue(Scriptfile) xor League xor Level;
end;

end.
