unit Engine.ORM;

interface

uses
  Generics.Collections,
  System.Rtti,
  SynSQLite3,
  SynCommons,
  System.SysUtils,
  System.Classes,
  System.Variants,
  Engine.Helferlein,
  Engine.Math;

/// //////////////////////////////////////////////////////////////////////////
/// ------------------------- ABOUT this Unit --------------------------------
///
/// This unit provied access ORM for any objects inherited from TORMObject<V>.
/// It will save object in database and can reload it.
/// For any global settings, like database or security settings use
/// ORMManager, but be aware, before any ORM functionality can be used, app
/// need to assigned one a time a instance to ORMManager to setup.
/// The unit is inspired by Django for pyhton, but not all concepts are
/// borrowed or are the same!
/// Inherite from TORMObject<V : class> to utilize ORM for a class. But be aware
/// the ORM mechanisms use WHITELISTING for any member, so mark them with the
/// ORMField attribute or an inheriting attribute to ensure they will saved in
/// table.
/// HINT!!! At the moment only fields with base datatypes (e.g. integer,
/// boolean, single, string, datetime,...) can be saved in database.
/// According to delphi, ORM will setup DB that any string operation is
/// case insensitiv.
/// Ask Martin for more :)
///
/// //////////////////////////////////////////////////////////////////////////

type

  /// /////////////////////// ATTRIBUTES ////////////////////////////////////////

  /// <summary> Attribute for class. Set a custom tablename for ORM for this class. If attribute is
  /// not used, classname without leading T in lowercase manner is used.</summary>
  ORMCustomTableName = class(TCustomAttribute)
    private
      FTableName : string;
    public
      property TableName : string read FTableName;
      constructor Create(TableName : string);
  end;

  /// <summary> Marks a member (property or a field) to save in table. Gives also
  /// the possibility to set a custom fieldname.
  /// HINT!!! Without marking, no property or field is saved (except for ID) in table for this class.
  /// Any other member attribute thats specified a ORM setting inherits from this attribute
  /// and accordingly marks a member to save in database.</summary>
  ORMField = class(TCustomAttribute)
    strict private
      FCustomFieldName : string;
    public
      property CustomFieldName : string read FCustomFieldName;
      constructor Create(CustomFieldName : string = '');
  end;

  /// <summary> Marks a member that value can never be null (not set). On default a value can be null.
  /// HINT! Only for completeness, because in delphi no (with minor exceptions) basetype is nullable.</summary>
  ORMFieldNotNull = class(ORMField);

  /// <summary> Marks a member that for every instance of this class the member has to be unique. If
  /// any value set twice, an error will on save() will occur.</summary>
  ORMFieldUnique = class(ORMField);

  /// <summary> According to delphi, ORM will setup DB that any string operation is
  /// case insensitiv. Mark a string member with this attribute and any string operation
  /// will be case sensitive.</summary>
  ORMFieldCaseSensitive = class(ORMField);

  /// <summary> Attribute to setup member with custom SQL code.
  /// E.g. used for ID with [ORMFieldCustomSQLSetup('PRIMARY KEY AUTOINCREMENT')]</summary>
  ORMFieldCustomSQLSetup = class(ORMField)
    strict private
      FCustomSQLSetup : string;
    public
      property CustomSQLSetup : string read FCustomSQLSetup;
      constructor Create(CustomSQLSetup : string);
  end;

  /// /////////////////////// CLASSES ///////////////////////////////////////////
  EnumDatabaseType = (dtSQLLite);
  EnumSQLDataType = (stNULL, stInteger, stReal, stText, stBlob);

  ASQLData = array of Variant;
  RField = RTuple<string, Variant>;

  EORMUnsupportedException = class(Exception);
  EORMAttributeError = class(Exception);
  EORMException = class(Exception);

  /// <summary> "Raw" query result for a sql query. Saves every new dataentry (set of fields) as a own item.</summary>
  TRawQuerySet = class
    private
      FData : TObjectList<TList<Variant>>;
      FFields : TDictionary<string, integer>;
      function GetData(Index : integer; Field : string) : Variant;
      procedure AddData(Data : TList<Variant>);
      procedure AddField(FieldName : string);
      function GetItem(Index : integer) : TList<Variant>;
    public
      /// <summary> Access every data item per index. Range is from "0" to "count - 1". Provide
      /// a list of data, where the index is in relation to fieldindex. List must NOT be owned,
      /// modifing or free list will cause an error.</summary>
      property Item[index : integer] : TList<Variant> read GetItem;
      /// <summary> Access a date from a specified dataentry and within this entry a specified field.</summary>
      property Data[index : integer; Field : string] : Variant read GetData;
      /// <summary> Return number of data entries for the queryset.</summary>
      function Count : integer;
      /// <summary> Return for a field index in dataentry. If fieldname not found, return -1.</summary>
      function GetFieldIndex(FieldName : string) : integer;
      /// <summary> Init empty lists.</summary>
      constructor Create;
      /// <summary> Badabumm</summary>
      destructor Destroy; override;
  end;

  TORMBaseObject = class
    protected
      constructor Create; virtual;
  end;

  /// <summary> Global ORM </summary>
  TORMManager = class
    private type
    strict private
      FSQLiteDatabase : TSQLDatabase;
    private
      /// ====================== SQL Methods ===================================
      procedure BeginTransaction;
      procedure Commit;
      procedure Rollback;
      procedure Exec(const SQL : string; Parameters : ASQLData = []);
      function Query(const SQL : string; Parameters : ASQLData = []) : TRawQuerySet;
      procedure AssignParameters(var rq : TSQLRequest; const params : ASQLData);
      function TableExists(TableName : string) : boolean;
      /// ==================== ORM Methods= ====================================
      procedure RegisterObject(NewObject : TORMBaseObject);
    public
      constructor Create(DatabaseURI : string; DatabaseType : EnumDatabaseType = dtSQLLite; Username : string = ''; Passwort : string = '');
      /// <summary> Return a list of tablename for every table exists in database. Caller has to manage resultlist.</summary>
      function GetAllTables : TStrings;
      /// <summary> Badaboom.</summary>
      destructor Destroy; override;
  end;

  TORMObject<V : class> = class;

  IQuerySet<U : class> = interface
    function GetCount : integer;
    property Count : integer read GetCount;
  end;

  TQuerySet<W : class> = class(TInterfacedObject, IQuerySet<W>)
    private
      function GetCount : integer;
    public
  end;

  RORMQuerySet<U : class> = record
    private
      FCount : integer;
    public
      /// <summary> Number of objects that the QuerySet contains</summary>
      property Count : integer read FCount;
      /// <summary> Return True if QuerySet doesn't contain at least one object.</summary>
      function IsEmpty : boolean;
  end;

  TORMObjectAccessor<T : class> = class
    private
    public
      /// <summary> Returns single object that fulfilled the sql where statement. Raise a exception
      /// if more than one object was found. If no object found, return nil.</summary>
      function Get(WhereSQL : string; Values : ASQLData) : T;
      /// <summary> Returns a QuerySet of objects that fulfilled the sql where statement.
      /// It is possible that no object was found, then the queryset is empty.</summary>
      function Filter(WhereSQL : string) : RORMQuerySet<T>;
  end;

  TORMFieldInfo = class
    strict private
      FFieldName : string;
      FRttiInfo : TRttiMemberUnified;
      FORMSettings : TList<ORMField>;
      function GetSQLDataType : EnumSQLDataType;
    public
      property SQLDataType : EnumSQLDataType read GetSQLDataType;
      property FieldName : string read FFieldName;
      property ORMSettings : TList<ORMField> read FORMSettings;
      procedure SetValue(Instance : TORMBaseObject; const Value : Variant);
      function GetValue(Instance : TORMBaseObject) : Variant;
      constructor Create(FieldRtti : TRttiMemberUnified);
      destructor Destroy; override;
  end;

  TORMObject<V : class> = class(TORMBaseObject)
    private
      class var FObjectsAccessor : TORMObjectAccessor<V>;
      class var FieldInfos : TObjectList<TORMFieldInfo>;
      class var RttiContext : TRttiContext;
      class function GetTableName : string;
      class constructor Create;
      class destructor Destroy;
    protected
      class var TableName : string;
    private
      FID : integer;
      /// <summary> CreateTable for current class to save data. Cause an error if table already exists.</summary>
      procedure CreateTable;
      function BuildUpdate : string;
      function BuildInsert : string;
      /// <summary> Load all ORM fields from QuerySet into this instance.</summary>
      procedure LoadObjectFromQuerySet(QuerySet : TRawQuerySet; DataIndex : integer);
    protected
      constructor Create; override;
    public
      /// ============================== Global =================================
      class property Objects : TORMObjectAccessor<V> read FObjectsAccessor;
    public
      /// ============================== Local =================================
      [ORMFieldCustomSQLSetup('PRIMARY KEY AUTOINCREMENT')]
      /// <summary> UniqueID (in context of this class) for the object. If ID = -1, object is not saved in database.</summary>
      property ID : integer read FID write FID;
      /// <summary> Return true if instance already saved in database, else false.</summary>
      function SavedInDatabase : boolean;
      /// <summary> Save, respectively create (if never done before) object in database.</summary>
      procedure Save;
      /// <summary> Delete object from database. Method will NOT free object.</summary>
      procedure Delete;
      /// <summary> Release object. Will NOT delete or modifie any data in database.</summary>
      destructor Destroy; override;
  end;

  CORMObject = class of TORMBaseObject;

  TORMUser = class(TORMObject<TORMUser>)
    private
      FEMail : string;
      FUsername : string;
    public
      property Username : string read FUsername write FUsername;
      property EMail : string read FEMail write FEMail;
      constructor Create; override;
      procedure SetPassword(Password : string);
  end;

  /// <summary> Global instance for of ORMManager, used by any ORM object to access database and access settings. Need an instance
  /// of TORMManager before any other use of ORM.</summary>
var
  ORMManager : TORMManager;

const
  SQL_DELETE       = 'DELETE FROM %s WHERE %s;';
  SQL_SELECT_WHERE = 'SELECT * FROM %s WHERE %s;';
  SQL_INSERT       = 'INSERT INTO %s(%s) VALUES(%s);';
  SQL_UPDATE       = 'UPDATE %s SET %s WHERE id=%d;';
  SQL_TABLE_CREATE = 'CREATE TABLE %s(%s);';
  SQL_TABLE_EXISTS = 'SELECT * FROM sqlite_master WHERE name = ? and type = ''table'';';
  SQL_LAST_ROWID   = 'SELECT last_insert_rowid()';

implementation

{ RORMQuerySet<U> }

function RORMQuerySet<U>.IsEmpty : boolean;
begin

end;

{ TORMObjectAccess<T> }

function TORMObjectAccessor<T>.Filter(WhereSQL : string) : RORMQuerySet<T>;
begin

end;

function TORMObjectAccessor<T>.Get(WhereSQL : string; Values : ASQLData) : T;
var
  NewObject : TObject;
  QuerySet : TRawQuerySet;
  SQL : string;
begin
  QuerySet := nil;
  try
    assert(assigned(ORMManager));
    assert(T.inheritsFrom(TORMObject<T>));
    SQL := Format(SQL_SELECT_WHERE, [TORMObject<T>.TableName, WhereSQL]);
    QuerySet := ORMManager.Query(SQL, Values);
    // any result found?
    if QuerySet.Count > 0 then
    begin
      if QuerySet.Count > 1 then
          raise EORMException.CreateFmt('TORMObjectAccessor<T>.Get: Multiple instances for query "%s" found.', [WhereSQL]);
      NewObject := CORMObject(T).Create;
      if not(NewObject is T) then
          raise EORMException.CreateFmt('TORMObjectAccessor<T>.Get: Class "%s" didn''t override the parameterless constructor create.', [T.ClassName]);
      result := T(NewObject);
      TORMObject<T>(result).LoadObjectFromQuerySet(QuerySet, 0);
    end
    else
        result := nil;
  finally
    QuerySet.Free;
  end;
end;

{ TORMUser }

constructor TORMUser.Create;
begin
  inherited;
end;

procedure TORMUser.SetPassword(Password : string);
begin
end;

{ TORMObject<V> }

class constructor TORMObject<V>.Create;
var
  rttiField : TRttiField;
  rttiProperty : TRttiProperty;
  rttiClass : TRttiInstanceType;
  member : TRttiMemberUnified;
  members : TList<TRttiMemberUnified>;
  attribute : TCustomAttribute;
  coulmnname : string;
begin
  TableName := GetTableName();
  FObjectsAccessor := TORMObjectAccessor<V>.Create;
  RttiContext := TRttiContext.Create;
  FieldInfos := TObjectList<TORMFieldInfo>.Create();

  rttiClass := RttiContext.GetType(V).AsInstance;
  // get all members of class, fields first
  for rttiField in rttiClass.GetFields do
  begin
    member := TRttiMemberUnified.Create(rttiField);
    // only if member is marked for ORM, need to save, else info is not longer needed
    if member.HasAttribute(ORMField) then
        FieldInfos.Add(TORMFieldInfo.Create(member))
    else member.Free;
  end;
  for rttiProperty in rttiClass.GetProperties do
  begin
    member := TRttiMemberUnified.Create(rttiProperty);
    if member.HasAttribute(ORMField) then
        FieldInfos.Add(TORMFieldInfo.Create(member))
    else member.Free;
  end;
end;

class destructor TORMObject<V>.Destroy;
begin
  FObjectsAccessor.Free;
  FieldInfos.Free;
  RttiContext.Free;
end;

function TORMObject<V>.BuildInsert : string;
var
  fieldInfo : TORMFieldInfo;
  sqlFields : string;
  sqlValues : string;
begin
  sqlFields := '';
  sqlValues := '';
  for fieldInfo in FieldInfos do
    // skip id, because this field will autoset by database
    if fieldInfo.FieldName <> 'id' then
    begin
      sqlFields := sqlFields + fieldInfo.FieldName + ',';
      sqlValues := sqlValues + '?,';
    end;
  // remove last needless comma
  sqlFields := sqlFields.Remove(sqlFields.Length - 1, 1);
  sqlValues := sqlValues.Remove(sqlValues.Length - 1, 1);
  result := Format(SQL_INSERT, [TableName, sqlFields, sqlValues]);
end;

function TORMObject<V>.BuildUpdate : string;
var
  fieldInfo : TORMFieldInfo;
  sqlFields : string;
begin
  sqlFields := '';
  for fieldInfo in FieldInfos do
    // skip id, because this field will autoset by database
    if fieldInfo.FieldName <> 'id' then
    begin
      sqlFields := sqlFields + fieldInfo.FieldName + '=?' + ',';
    end;
  // remove last needless comma
  sqlFields := sqlFields.Remove(sqlFields.Length - 1, 1);
  result := Format(SQL_UPDATE, [TableName, sqlFields, ID]);
end;

procedure TORMObject<V>.CreateTable;
const
  ORM_DATATYPE_STRINGS : array [EnumSQLDataType] of string = ('NULL', 'INTEGER', 'REAL', 'TEXT', 'BLOB');
var
  Field : TORMFieldInfo;
  fieldSQL, fieldsSQL, createSQL : string;
  ORMSetting : ORMField;
  caseSensitive : boolean;
begin
  fieldsSQL := '';
  for Field in FieldInfos do
  begin
    // base string for every coulmn (field), name and type
    fieldSQL := '';
    caseSensitive := False;
    fieldSQL := Field.FieldName + ' ' + ORM_DATATYPE_STRINGS[Field.SQLDataType];
    // additionally check all other settings and add them to string
    for ORMSetting in Field.ORMSettings do
    begin
      if ORMSetting is ORMFieldCustomSQLSetup then
          fieldSQL := fieldSQL + ' ' + ORMFieldCustomSQLSetup(ORMSetting).CustomSQLSetup
      else if ORMSetting is ORMFieldNotNull then
          fieldSQL := fieldSQL + ' ' + 'NOT NULL'
      else if ORMSetting is ORMFieldUnique then
          fieldSQL := fieldSQL + ' ' + 'UNIQUE'
      else if ORMSetting is ORMFieldCaseSensitive then
      begin
        assert(Field.SQLDataType = stText, 'TORMObject<V>.CreateTable: Attribute ORMFieldCaseSensitive is only for string member supported.');
        caseSensitive := True;
      end
      else if ORMSetting.ClassType <> ORMField then
          raise ENotImplemented.CreateFmt('TORMObject<V>.CreateTable: Code for attribute "%s" missing.', [ORMSetting.ClassName]);
    end;
    if not caseSensitive and (Field.SQLDataType = stText) then
        fieldSQL := fieldSQL + ' ' + 'COLLATE NOCASE';
    // build sql for field finished
    fieldsSQL := fieldsSQL + ' ' + fieldSQL + ',';
  end;
  // remove last comma
  fieldsSQL := fieldsSQL.Remove(fieldsSQL.Length - 1, 1);
  createSQL := Format(SQL_TABLE_CREATE, [TableName, fieldsSQL]);
  // finally create table
  ORMManager.Exec(createSQL);
end;

procedure TORMObject<V>.Delete;
var
  deleteSQL : string;
begin
  if not SavedInDatabase then
      raise EORMUnsupportedException.Create('TORMObject<V>.Delete: Can''t delete object not saved in database.');
  deleteSQL := Format(SQL_DELETE, [TableName, 'ID=?']);
  ORMManager.Exec(deleteSQL, [ID]);
  FID := -1;
end;

constructor TORMObject<V>.Create;
begin
  FID := -1;
end;

destructor TORMObject<V>.Destroy;
begin

  inherited;
end;

class function TORMObject<V>.GetTableName : string;
var
  RttiContext : TRttiContext;
  attributes : TArray<TCustomAttribute>;
  customTableName : TCustomAttribute;
begin
  result := '';
  RttiContext := TRttiContext.Create;
  // get all attributes for target class where orm is created for
  attributes := RttiContext.GetType(V).GetAttributes;
  customTableName := HRtti.SearchForAttribute(ORMCustomTableName, attributes);
  if customTableName <> nil then
  begin
    result := ORMCustomTableName(customTableName).TableName;
  end
  else
  begin
    // only use classname without first leading T
    result := V.ClassName.Remove(0, 1);
  end;
  result := result.ToLowerInvariant;
  RttiContext.Free;
end;

procedure TORMObject<V>.LoadObjectFromQuerySet(QuerySet : TRawQuerySet; DataIndex : integer);
var
  Field : TORMFieldInfo;
begin
  assert(ID = -1);
  for Field in FieldInfos do
  begin
    Field.SetValue(self, QuerySet.Data[DataIndex, Field.FieldName]);
  end;
end;

procedure TORMObject<V>.Save;
var
  Values : ASQLData;
  SQL : string;
  QuerySet : TRawQuerySet;
  Field : TORMFieldInfo;
  i : integer;
begin
  if not ORMManager.TableExists(TableName) then
      CreateTable;

  // need different commands if object alerady exists
  if self.SavedInDatabase then
      SQL := BuildUpdate
  else SQL := BuildInsert;
  // prepare values
  // ignore ID, this field will never be changed by program, only db should access it
  setlength(Values, FieldInfos.Count - 1);
  i := 0;
  for Field in FieldInfos do
    if Field.FieldName <> 'id' then
    begin
      Values[i] := Field.GetValue(self);
      inc(i);
    end;
  assert(i = FieldInfos.Count - 1);
  ORMManager.BeginTransaction;
  try
    ORMManager.Exec(SQL, Values);
    if not self.SavedInDatabase then
    begin
      // after add new instance to DB, need to get ID (because until now ID = -1 -> ID unknown)
      QuerySet := ORMManager.Query(SQL_LAST_ROWID);
      assert(QuerySet.Count = 1);
      assert(QuerySet.Item[0].Count = 1);
      FID := QuerySet.Item[0][0];
      QuerySet.Free;
    end;
    ORMManager.Commit;
  except
    ORMManager.Rollback;
  end;
end;

function TORMObject<V>.SavedInDatabase : boolean;
begin
  result := ID <= -1;
end;

{ TORMManager }

procedure TORMManager.BeginTransaction;
begin
  FSQLiteDatabase.TransactionBegin();
end;

procedure TORMManager.Commit;
begin
  FSQLiteDatabase.Commit;
end;

constructor TORMManager.Create(DatabaseURI : string; DatabaseType : EnumDatabaseType; Username, Passwort : string);
begin
  FreeAndNil(sqlite3);
  sqlite3 := TSQLite3LibraryDynamic.Create;
  FSQLiteDatabase := TSQLDatabase.Create(DatabaseURI);
  FSQLiteDatabase.BusyTimeout := 1500;
end;

destructor TORMManager.Destroy;
begin
  FSQLiteDatabase.Free;
  FreeAndNil(sqlite3);
  inherited;
end;

function TORMManager.GetAllTables : TStrings;
var
  tableNames : TRawUTF8DynArray;
  TableName : RawUTF8;
begin
  tableNames := nil;
  FSQLiteDatabase.GetTableNames(tableNames);
  result := TStringList.Create;
  for TableName in tableNames do
  begin
    result.Add(TableName);
  end;
end;

procedure TORMManager.AssignParameters(var rq : TSQLRequest; const params : ASQLData);
var
  i : integer;
  p : PVarData;
begin
  for i := 0 to Length(params) - 1 do
  begin
    p := PVarData(@params[i]);
    case p.VType of
      varInt64 : rq.Bind(i + 1, p.VInt64);
      varDouble : rq.Bind(i + 1, p.VDouble);
      varUString, varString : rq.BindS(i + 1, string(params[i]));
      varBoolean : rq.Bind(i + 1, Ord(p.VBoolean));
      varNull : rq.BindNull(i + 1);
    else
      raise EORMUnsupportedException.CreateFmt('TORMManager.AssignParameters: Unsupported VarType "%d".', [p.VType]);
    end;
  end;
end;

function TORMManager.Query(const SQL : string; Parameters : ASQLData) : TRawQuerySet;
var
  request : TSQLRequest;
  i : integer;
  Data : TList<Variant>;
  dataitem : Variant;
begin
  // compile sqlcommand
  request.Prepare(FSQLiteDatabase.DB, StringToUTF8(SQL));
  try
    // bind parameters to request, does no use format here to use sql intern parameterbinding
    // because this avoid e.g. SQL injection
    AssignParameters(request, Parameters);
    result := TRawQuerySet.Create;
    // only fetch data if not sql already finished
    // every step will fetch a new dataentry, so this fetch get the first entry
    if request.Step <> SQLITE_DONE then
    begin
      // first fetch all fields
      for i := 0 to request.FieldCount - 1 do
          result.AddField(request.FieldName(i));
      // next fetch data for current entry
      repeat
        Data := TList<Variant>.Create;
        for i := 0 to request.FieldCount - 1 do
        begin
          // test that every dataentry has same order
          assert(result.GetFieldIndex(request.FieldName(i)) = i);
          case request.FieldType(i) of
            SQLITE_INTEGER : dataitem := request.FieldInt(i);
            SQLITE_FLOAT : dataitem := request.FieldDouble(i);
            SQLITE_TEXT : dataitem := request.Fields(i);
            SQLITE_BLOB : dataitem := request.FieldBlob(i);
            SQLITE_NULL : dataitem := Null; // special variant constant
          else raise EORMUnsupportedException.Create('TORMManager.Query: Unsupported SQLite datatype.');
          end;
          Data.Add(dataitem);
        end;
        // for current dataentry all values for fields fetched, transfer them to result QuerySet
        // from now queryset will own data
        result.AddData(Data);
        // get next dataentry or end if no more data provided
      until request.Step = SQLITE_DONE;
    end;
  finally
    request.Close;
  end;
end;

procedure TORMManager.Exec(const SQL : string; Parameters : ASQLData);
var
  request : TSQLRequest;
begin
  // compile sqlcommand
  request.Prepare(FSQLiteDatabase.DB, StringToUTF8(SQL));
  try
    // bind parameters to request, does no use format here to use sql intern parameterbinding
    // because this avoid e.g. SQL injection
    AssignParameters(request, Parameters);
    // for exec simple execute without any result is enough
    request.Execute;
  finally
    request.Close;
  end;
end;

procedure TORMManager.RegisterObject(NewObject : TORMBaseObject);
begin

end;

procedure TORMManager.Rollback;
begin
  FSQLiteDatabase.Rollback;
end;

function TORMManager.TableExists(TableName : string) : boolean;
var
  SQL : string;
  QuerySet : TRawQuerySet;
begin
  QuerySet := Query(SQL_TABLE_EXISTS, [TableName]);
  assert(QuerySet.Count <= 1);
  // found any table with tablename? queryset has an entry with infodata for that table
  result := QuerySet.Count = 1;
end;

{ ORMCustomTableName }

constructor ORMCustomTableName.Create(TableName : string);
begin
  FTableName := TableName;
end;

{ TQuerySet<W> }

function TQuerySet<W>.GetCount : integer;
begin

end;

{ ORMField }

constructor ORMField.Create(CustomFieldName : string);
begin
  FCustomFieldName := CustomFieldName;
end;

{ ORMFieldCustomSQLSetup }

constructor ORMFieldCustomSQLSetup.Create(CustomSQLSetup : string);
begin
  FCustomSQLSetup := CustomSQLSetup;
end;

{ TRawQuerySet }

procedure TRawQuerySet.AddData(Data : TList<Variant>);
begin
  FData.Add(Data);
end;

procedure TRawQuerySet.AddField(FieldName : string);
begin
  assert(not FFields.ContainsKey(FieldName.ToLowerInvariant));
  FFields.Add(FieldName.ToLowerInvariant, FFields.Count);
end;

function TRawQuerySet.Count : integer;
begin
  result := FData.Count;
end;

constructor TRawQuerySet.Create;
begin
  FData := TObjectList < TList < Variant >>.Create();
  FFields := TDictionary<string, integer>.Create();
end;

destructor TRawQuerySet.Destroy;
begin
  FData.Free;
  FFields.Free;
  inherited;
end;

function TRawQuerySet.GetData(Index : integer; Field : string) : Variant;
begin
  if not HMath.inRange(index, 0, Count - 1) then
      raise EOutOfBoundException.CreateFmt('RawQuerySet.GetData: Index (%d) out of bound [%d, %d]', [index, 0, Count - 1]);
  if not FFields.ContainsKey(Field.ToLowerInvariant) then
      raise ENotFoundException.CreateFmt('RawQuerySet.GetData: Unknown field "%s".', [Field]);
  result := FData[index][FFields[Field.ToLowerInvariant]];
end;

function TRawQuerySet.GetFieldIndex(FieldName : string) : integer;
begin
  if FFields.ContainsKey(FieldName.ToLowerInvariant) then
      result := FFields[FieldName]
  else
      result := -1;
end;

function TRawQuerySet.GetItem(Index : integer) : TList<Variant>;
begin
  if not HMath.inRange(index, 0, Count - 1) then
      raise EOutOfBoundException.CreateFmt('RawQuerySet.GetItem: Index (%d) out of bound [%d, %d]', [index, 0, Count - 1]);
  result := FData[index];
end;

{ TORMFieldInfo }

constructor TORMFieldInfo.Create(FieldRtti : TRttiMemberUnified);
var
  attribute : TCustomAttribute;
begin
  assert(assigned(FieldRtti));
  FRttiInfo := FieldRtti;
  FFieldName := '';
  FORMSettings := TList<ORMField>.Create;
  for attribute in FRttiInfo.GetAttributes do
  begin
    if attribute is ORMField then
    begin
      // if a customname for field is set, use them, but only one attribute sets name is expected
      if ORMField(attribute).CustomFieldName <> '' then
      begin
        if FFieldName = '' then FFieldName := ORMField(attribute).CustomFieldName.ToLowerInvariant
        else
            raise EORMAttributeError.CreateFmt('TFieldInfo<T>.Create: For member %s customfieldname was set twice.', [FRttiInfo.name]);
      end;
      FORMSettings.Add(ORMField(attribute));
    end;
  end;
  // no custom fieldname set?
  if FFieldName = '' then
      FFieldName := FRttiInfo.name.ToLowerInvariant;
end;

destructor TORMFieldInfo.Destroy;
begin
  FORMSettings.Free;
  FRttiInfo.Free;
  inherited;
end;

function TORMFieldInfo.GetSQLDataType : EnumSQLDataType;
begin
  case FRttiInfo.MemberType.TypeKind of
    tkInteger, tkInt64 : result := stInteger;
    tkFloat : result := stReal;
    tkString, tkWChar, tkChar, tkLString, tkWString, tkUString : result := stText;
  else raise EORMUnsupportedException.CreateFmt('TFieldInfo<T>.GetSQLDataType: Datatype "%s" not supported to save via ORM.',
      [HRtti.EnumerationToString<TTypeKind>(FRttiInfo.MemberType.TypeKind)]);
  end;
end;

function TORMFieldInfo.GetValue(Instance : TORMBaseObject) : Variant;
var
  Value : TValue;
begin
  Value := FRttiInfo.GetValue(Pointer(Instance));
  case SQLDataType of
    stNULL : Null;
    stInteger : result := Value.AsInt64;
    stReal : result := Value.AsExtended;
    stText : result := Value.AsString;
    stBlob : raise ENotImplemented.Create('Slap Martin :).');
  end;
end;

procedure TORMFieldInfo.SetValue(Instance : TORMBaseObject; const Value : Variant);
begin
  FRttiInfo.SetValue(Pointer(Instance), TValue.FromVariant(Value));
end;

{ TORMBaseObject }

constructor TORMBaseObject.Create;
begin

end;

end.
