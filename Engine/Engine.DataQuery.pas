unit Engine.DataQuery;

interface

uses
  System.SysUtils,
  Generics.Collections,
  Generics.Defaults,
  System.Rtti,
  System.TypInfo,
  System.Math,
  System.Hash;

type
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  EQueryResolveError = class(Exception);
  EQueryOperandCountError = class(EQueryResolveError);
  EQueryOperandTypeMissmatch = class(EQueryResolveError);

  // a primitive definite value e.g. 1, 'hello', True
  // a descriptor for a field, e.g. F('id'), F('setting.enabled')
  // ========================= comparison ===================================
  // compare of two operands (qoField or qoValue), e.g. F('id') = 1, F('vector.x') = F('vector.y')
  // compare of two operands (qoField or qoValue), e.g. F('count') > 0
  // ========================= logical operation and combination ============
  // HINT: A comparison will always bind stronger than a combination, so no brackets are necessary
  // but can be used for clariying.
  // and combination of two comparisons e.g. F('id') = 10 and F('name') = 'Hans'

  {$REGION 'QueryNodes'}

  TQueryTreeNode = class
    protected
      FChilds : TObjectList<TQueryTreeNode>;
    public
      property Childs : TObjectList<TQueryTreeNode> read FChilds;
      constructor Create();
      /// <summary> Execute the query by checking if item fullfil the query or not,
      /// therefor the field descriptor are resolved with help of the item.</summary>
      function Resolve(const Item : TValue) : TValue; virtual; abstract;
      destructor Destroy; override;
  end;

  CQueryTreeNode = class of TQueryTreeNode;

  TQueryTreeNodeValue = class(TQueryTreeNode)
    private
      FValue : TValue;
    public
      constructor Create(const Value : TValue);
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeField = class(TQueryTreeNodeValue)
    private
      FReverse : boolean;
      FParameters : TArray<TValue>;
      function GetFieldDescriptor : string;
      procedure SetFieldDescriptor(const Value : string);
    public
      property Reverse : boolean read FReverse;
      property FieldDescriptor : string read GetFieldDescriptor write SetFieldDescriptor;
      constructor Create(const FieldDescriptor : string; Parameters : array of TValue);
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOperator = class(TQueryTreeNode)
    protected
      FOperands : TArray<TValue>;
      procedure CheckOperands(OperandCount : integer);
      procedure LoadOperand(Index : integer; const Item : TValue); inline;
      procedure CheckAndLoadOperands(OperandCount : integer; const Item : TValue);
      procedure CheckOperandType(Index : integer; ClassType : CQueryTreeNode);
  end;

  TQueryTreeNodeOpAnd = class(TQueryTreeNodeOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpOr = class(TQueryTreeNodeOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpNot = class(TQueryTreeNodeOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeComparingOperator = class(TQueryTreeNodeOperator)
    protected
      function CompareValue(const Left, Right : TValue) : integer;
      function SameValue(const Left, Right : TValue) : boolean;
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpEqual = class(TQueryTreeNodeComparingOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpNotEqual = class(TQueryTreeNodeComparingOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpGreaterThan = class(TQueryTreeNodeComparingOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpLessThan = class(TQueryTreeNodeComparingOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpGreaterThanOrEqual = class(TQueryTreeNodeComparingOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpLessThanOrEqual = class(TQueryTreeNodeComparingOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpIn = class(TQueryTreeNodeComparingOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeArithmeticOperator = class(TQueryTreeNodeOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;

  TQueryTreeNodeOpMultiply = class(TQueryTreeNodeArithmeticOperator)
    public
      function Resolve(const Item : TValue) : TValue; override;
  end;
  {$ENDREGION}

  SetByte = set of Byte;

  /// <summary> An Query is used for filtermethods in queryset. Queries are only usable one time, because after
  /// passing a query to filter, this free the query (destroy containing data).</summary>
  RQuery = record
    strict private
      FQueryTree : TQueryTreeNode;
    public
      property QueryTree : TQueryTreeNode read FQueryTree write FQueryTree;
      /// <summary> Creates a part of a query that is a descriptor for a field.
      /// the descriptor will obtained until the query is checked against a value.
      /// Than the descriptor will resolved to an concret value.</summary>
      constructor CreateFieldDescriptor(const FieldDescriptor : string; Parameters : array of TValue);
      procedure Free;
      class function From<T>(const Value : T) : RQuery; static;
      class function FromA<T>(const AArray : TArray<T>) : RQuery; static;
      class operator BitwiseAnd(const a, b : RQuery) : RQuery;
      class operator BitwiseOr(const a, b : RQuery) : RQuery;
      class operator LogicalNot(const a : RQuery) : RQuery;
      class operator in (a : RQuery; b : RQuery) : RQuery;
      class operator Equal(const a, b : RQuery) : RQuery;
      class operator NotEqual(const a, b : RQuery) : RQuery;
      class operator GreaterThan(const a, b : RQuery) : RQuery;
      class operator LessThan(const a, b : RQuery) : RQuery;
      class operator LessThanOrEqual(const a, b : RQuery) : RQuery;
      class operator GreaterThanOrEqual(const a, b : RQuery) : RQuery;
      class operator Multiply(const a, b : RQuery) : RQuery;
      class operator Implicit(a : integer) : RQuery;
      class operator Implicit(const a : string) : RQuery;
      class operator Implicit(a : boolean) : RQuery;
      class operator Implicit(a : single) : RQuery;
      class operator Implicit(a : TObject) : RQuery;
      class operator Implicit(a : TClass) : RQuery;
      class operator Implicit(const a : TArray<integer>) : RQuery;
      class operator Implicit(const a : TArray<string>) : RQuery;
      class operator Implicit(const a : TArray<single>) : RQuery;
      class operator Implicit(const a : SetByte) : RQuery;
  end;

  /// <summary> Creates a field descriptor within a query. This describes a field that will be resolved
  /// when query is tested against a value. To reference the value itself use point '.'</summary>
function F(const FieldDescriptor : string) : RQuery; overload;
/// <summary> Additionally allow to pass parameter for F which are used to call methods. If parameter should be used
/// to call a method, the method has to passed with methodname(a, b), where a/b is only a placeholder
/// to signal that a parameter is expected and to declare the parameter count (a/b is only an example, any other string will also works,
/// because the comma is important.). Through the explicit parameter declaration it is also possible to chain methods with parameters.
/// E.g. 'PropertyByTypes(a, b).ColorChannel(c)', [Content1, Content2, AChannel]</summary>
function F(const FieldDescriptor : string; Parameters : array of TValue) : RQuery; overload;

type

  /// <summary> Helper record for workaround that an interface type does not support generic methods,
  /// like function Values<T>(const FieldDescriptor : string) : TArray<T>;</summary>
  RValues = record
    private
      FValues : TArray<TValue>;
    public
      function ToArray<T> : TArray<T>; overload;
      function ToArray : TArray<TValue>; overload;
  end;

  ProcDataQueryEachCallback<T> = reference to procedure(const Item : T);
  FuncDataFilter<T> = reference to function(const Item : T) : boolean;

  {$M+}

  /// <summary> Interface for querying any data of any database/list. That can be e.g. a query for
  /// SQL or a TList<T>.</summary>
  IDataQuery<T> = interface
    ['{BF181E91-1532-4F97-9327-411FF6F89F30}']
    /// <summary> Returns a IDataQuery<T> that containg all data which passes the query.</summary>
    function Filter(const Query : RQuery) : IDataQuery<T>; overload;
    /// <summary> Returns a IDataQuery<T> that containg all data which passes the filter method.</summary>
    function Filter(const FilterCallback : FuncDataFilter<T>) : IDataQuery<T>; overload;
    /// <summary> Returns the first item which passes the query. If DefaultIfNotFound is True, the default value of
    /// T will be returned, else an exception will be raised</summary>
    function Get(const Query : RQuery; DefaultIfNotFound : boolean = False) : T;
    /// <summary> Returns the index of the first item that passes the query. If no item was found, method returns -1.</summary>
    function GetIndex(const Query : RQuery) : integer;
    /// <summary>  Try to returns the index of the first item that passes the query. If no item was found, method returns -1 and false.</summary>
    function TryGetIndex(const Query : RQuery; out ItemIndex : integer) : boolean;
    /// <summary> If any item was found that passes the query, the method will return true, else false.
    /// The first item that passes the test will outputted through ItemFound, else ItemFound will not set.</summary>
    function TryGet(const Query : RQuery; out ItemFound : T) : boolean;
    /// <summary> Returns a IDataQuery<T> that containg all data which passes NOT the query.</summary>
    function Exclude(const Query : RQuery) : IDataQuery<T>; overload;
    /// <summary> Returns a IDataQuery<T> that containg all data which passes NOT the filter method.</summary>
    function Exclude(const FilterCallback : FuncDataFilter<T>) : IDataQuery<T>; overload;
    /// <summary> Remove all duplicates respectively all items where the value described by FieldDescriptor matches.
    /// so e.g. an array [1, 1, 2, 2, 3, 3] would result in [1, 2, 3]</summary>
    function Distinct(const FieldDescriptor : string = '.') : IDataQuery<T>; overload;
    /// <summary> Sorting all items ascending by the values referenced by FieldDescriptors. A leading '-' will reverse the sorting
    /// to descending, e.g. OrderBy('-created'). Multiple FieldDescriptor will used like an hierarchy,
    /// so only if the values of the first FieldDescriptor are matching, the secound is used to order the items,
    /// e.g. [(21, 'Sheen'), (17, 'Joy') (21, 'Roll')].OrderBy('age', 'name'), only when Sheen and Roll are compared, the
    /// FieldDescriptor 'name' will come to work, because the age (21) is equal.
    /// Hint: Sorting algorithm: Quicksort.</summary>
    function OrderBy(const FieldDescriptor : string) : IDataQuery<T>; overload;
    function OrderBy(const FieldDescriptor : RQuery) : IDataQuery<T>; overload;
    function OrderBy(FieldDescriptors : array of string) : IDataQuery<T>; overload;
    function OrderBy(FieldDescriptors : array of RQuery) : IDataQuery<T>; overload;
    /// <summary> Reduces the query set to have at max Count items by dropping everything behind the limit. </summary>
    function Limit(Count : integer) : IDataQuery<T>; overload;
    /// <summary> Drops everything before offset and the take up to the next count items dropping everything behind the limit.  </summary>
    function Limit(Offset, Count : integer) : IDataQuery<T>; overload;
    /// <summary> Returns the number of data that the DataQuery contains.</summary>
    function Count : integer;
    /// <summary> Returning the first date that the DataQuery contains.</summary>
    function First(DefaultIfNone : boolean = False) : T;
    /// <summary> Returning the last date that the DataQuery contains.</summary>
    function Last(DefaultIfNone : boolean = False) : T;
    /// <summary> Returns True if query contains any data (count > 0).</summary>
    function Exists : boolean;
    /// <summary> Returns a list that containing all data for DataQuery. If Managed True, query will free list when
    /// query is freed, else user has to take care of free the list.
    /// WARNING If the managed list is used, don't maniupulate the list, because this will manipulate the content of the
    /// queryset.</summary>
    function ToList(Managed : boolean = True) : TList<T>;
    /// <summary> Returns an Array that containing all data for DataQuery. </summary>
    function ToArray : TArray<T>;
    /// <summary> Returns an array that only contains the content of the field/property/method described by FieldDescriptor.
    /// If field does not exists, an error will occur. Only typical conversions (Integer -> single) are made,
    /// if type not match and conversion not possible, an exception will raise.</summary>
    function Values(const FieldDescriptor : string) : RValues;
    /// <summary> Shortcut, same as Values with type string.</summary>
    function ValuesAsString(const FieldDescriptor : string) : TArray<string>;
    /// <summary> Shortcut, same as Values with type single.</summary>
    function ValuesAsSingle(const FieldDescriptor : string) : TArray<single>;
    /// <summary> Shortcut, same as Values with type integer.</summary>
    function ValuesAsInteger(const FieldDescriptor : string) : TArray<integer>;
    function GetEnumerator : TEnumerator<T>;
    function Each(const Callback : ProcDataQueryEachCallback<T>) : IDataQuery<T>;
  end;

  {$M-}

  /// <summary> Implementing the IDataQuery<T> interface.</summary>
  TDelphiDataQuery<T> = class(TInterfacedObject, IDataQuery<T>)
    protected
      FData : TList<T>;
      constructor BaseCreate;
    public
      constructor Create(const Data : TEnumerable<T>); overload;
      constructor Create(const Data : IEnumerable<T>); overload;
      constructor Create(const Data : array of T); overload;
      class function CreateInterface(const Data : array of T) : IDataQuery<T>; static;

      function Filter(const Query : RQuery) : IDataQuery<T>; overload;
      function Filter(const FilterCallback : FuncDataFilter<T>) : IDataQuery<T>; overload;
      function Get(const Query : RQuery; DefaultIfNotFound : boolean = False) : T;
      function GetIndex(const Query : RQuery) : integer;
      function TryGetIndex(const Query : RQuery; out ItemIndex : integer) : boolean;
      function TryGet(const Query : RQuery; out ItemFound : T) : boolean;
      function Exclude(const Query : RQuery) : IDataQuery<T>; overload;
      function Exclude(const FilterCallback : FuncDataFilter<T>) : IDataQuery<T>; overload;
      function Distinct(const FieldDescriptor : string = '.') : IDataQuery<T>; overload;
      function OrderBy(const FieldDescriptor : string) : IDataQuery<T>; overload;
      function OrderBy(const FieldDescriptor : RQuery) : IDataQuery<T>; overload;
      function OrderBy(FieldDescriptors : array of string) : IDataQuery<T>; overload;
      function OrderBy(FieldDescriptors : array of RQuery) : IDataQuery<T>; overload;
      function Limit(Count : integer) : IDataQuery<T>; overload;
      function Limit(Offset, Count : integer) : IDataQuery<T>; overload;
      function Count : integer;
      function First(DefaultIfNone : boolean = False) : T;
      function Last(DefaultIfNone : boolean = False) : T;
      function Exists : boolean;
      function ToList(Managed : boolean = True) : TList<T>;
      function ToArray : TArray<T>;

      function Values(const FieldDescriptor : string) : RValues;
      function ValuesAsString(const FieldDescriptor : string) : TArray<string>;
      function ValuesAsSingle(const FieldDescriptor : string) : TArray<single>;
      function ValuesAsInteger(const FieldDescriptor : string) : TArray<integer>;

      function GetEnumerator : TEnumerator<T>;

      function Each(const Callback : ProcDataQueryEachCallback<T>) : IDataQuery<T>;

      destructor Destroy; override;
  end;

var
  Context : TRttiContext;

implementation

uses
  Engine.Helferlein,
  Engine.Helferlein.Windows;

function F(const FieldDescriptor : string) : RQuery;
begin
  result := F(FieldDescriptor, []);
end;

function F(const FieldDescriptor : string; Parameters : array of TValue) : RQuery;
begin
  result := RQuery.CreateFieldDescriptor(FieldDescriptor, Parameters);
end;

{ TDelphiDataQuery<T> }

constructor TDelphiDataQuery<T>.BaseCreate;
begin
  FData := TList<T>.Create;
end;

function TDelphiDataQuery<T>.Count : integer;
begin
  result := FData.Count;
end;

constructor TDelphiDataQuery<T>.Create(const Data : TEnumerable<T>);
begin
  BaseCreate;
  FData.AddRange(Data);
end;

constructor TDelphiDataQuery<T>.Create(const Data : IEnumerable<T>);
begin
  BaseCreate;
  FData.AddRange(Data);
end;

constructor TDelphiDataQuery<T>.Create(const Data : array of T);
begin
  BaseCreate;
  FData.AddRange(Data);
end;

class function TDelphiDataQuery<T>.CreateInterface(const Data : array of T) : IDataQuery<T>;
begin
  result := TDelphiDataQuery<T>.Create(Data);
end;

destructor TDelphiDataQuery<T>.Destroy;
begin
  FData.Free;
  inherited;
end;

function TDelphiDataQuery<T>.Distinct(const FieldDescriptor : string) : IDataQuery<T>;
var
  DistinctValues : TDictionary<TValue, boolean>;
  DistinctItems : TList<T>;
  Item : T;
  FieldValue : TValue;
  FieldQueryNode : TQueryTreeNodeField;
begin
  DistinctItems := TList<T>.Create;
  DistinctValues := TDictionary<TValue, boolean>.Create(TEqualityComparer<TValue>.Construct(
    function(const Left, Right : TValue) : boolean
    begin
      result := Left.SameValue(Right);
    end,
    function(const Value : TValue) : integer
    begin
      result := Value.GetSimpleHashValue;
    end
    ));
  FieldQueryNode := TQueryTreeNodeField.Create(FieldDescriptor, []);
  for Item in FData do
  begin
    FieldValue := FieldQueryNode.Resolve(TValue.From<T>(Item));
    if not DistinctValues.ContainsKey(FieldValue) then
    begin
      DistinctValues.Add(FieldValue, True);
      DistinctItems.Add(Item);
    end;
  end;
  result := TDelphiDataQuery<T>.Create(DistinctItems);
  FieldQueryNode.Free;
  DistinctValues.Free;
  DistinctItems.Free;
end;

function TDelphiDataQuery<T>.Each(const Callback : ProcDataQueryEachCallback<T>) : IDataQuery<T>;
var
  Item : T;
begin
  result := Self;
  for Item in FData do
      Callback(Item);
end;

function TDelphiDataQuery<T>.Exclude(const Query : RQuery) : IDataQuery<T>;
begin
  result := Filter(not Query);
end;

function TDelphiDataQuery<T>.Exclude(const FilterCallback : FuncDataFilter<T>) : IDataQuery<T>;
begin
  result := Filter(
    function(const Item : T) : boolean
    begin
      result := not FilterCallback(Item);
    end);
end;

function TDelphiDataQuery<T>.Exists : boolean;
begin
  result := FData.Count > 0;
end;

function TDelphiDataQuery<T>.Filter(const Query : RQuery) : IDataQuery<T>;
var
  FilteredData : TList<T>;
  Item : T;
  QueryResult : TValue;
begin
  FilteredData := TList<T>.Create;
  // filter items if query match
  for Item in FData do
  begin
    QueryResult := Query.QueryTree.Resolve(TValue.From<T>(Item));
    if QueryResult.AsBoolean then
        FilteredData.Add(Item);
  end;
  // after query is used, ivalidate it
  Query.Free;
  // create a new query containg the filtered data
  result := TDelphiDataQuery<T>.Create(FilteredData);
  FilteredData.Free;
end;

function TDelphiDataQuery<T>.Filter(const FilterCallback : FuncDataFilter<T>) : IDataQuery<T>;
var
  FilteredData : TList<T>;
  Item : T;
  FilterResult : boolean;
begin
  FilteredData := TList<T>.Create;
  // filter items if query match
  for Item in FData do
  begin
    FilterResult := FilterCallback(Item);
    if FilterResult then
        FilteredData.Add(Item);
  end;
  // create a new query containg the filtered data
  result := TDelphiDataQuery<T>.Create(FilteredData);
  FilteredData.Free;
end;

function TDelphiDataQuery<T>.First(DefaultIfNone : boolean) : T;
begin
  if (FData.Count <= 0) and DefaultIfNone then result := default (T)
  else result := FData.First;
end;

function TDelphiDataQuery<T>.Get(const Query : RQuery; DefaultIfNotFound : boolean) : T;
var
  ItemIndex : integer;
begin
  ItemIndex := GetIndex(Query);
  if ItemIndex >= 0 then
    // item found
      result := FData[ItemIndex]
  else
  // item not found
  begin
    if DefaultIfNotFound then
        result := default (T)
    else
        raise ENotFoundException.Create('TDelphiDataQuery<T>.Get: Could not find any item matching the query.');
  end;
end;

function TDelphiDataQuery<T>.GetEnumerator : TEnumerator<T>;
begin
  result := FData.GetEnumerator;
end;

function TDelphiDataQuery<T>.GetIndex(const Query : RQuery) : integer;
var
  i : integer;
  QueryResult : TValue;
begin
  result := -1;
  for i := 0 to FData.Count - 1 do
  begin
    QueryResult := Query.QueryTree.Resolve(TValue.From<T>(FData[i]));
    // any item has passed the query?
    if QueryResult.AsBoolean then
    begin
      result := i;
      break;
    end;
  end;
  // after query is used, ivalidate it
  Query.Free;
end;

function TDelphiDataQuery<T>.Last(DefaultIfNone : boolean) : T;
begin
  if (FData.Count <= 0) and DefaultIfNone then result := default (T)
  else result := FData.Last;
end;

function TDelphiDataQuery<T>.Limit(Count : integer) : IDataQuery<T>;
begin
  result := Limit(0, Count);
end;

function TDelphiDataQuery<T>.Limit(Offset, Count : integer) : IDataQuery<T>;
var
  SlicedData : TList<T>;
  i : integer;
begin
  SlicedData := TList<T>.Create;
  for i := Offset to Min(Offset + Count, FData.Count) - 1 do
      SlicedData.Add(FData[i]);
  // create a new query containg the limited data
  result := TDelphiDataQuery<T>.Create(SlicedData);
  SlicedData.Free;
end;

function TDelphiDataQuery<T>.OrderBy(const FieldDescriptor : string) : IDataQuery<T>;
begin
  result := OrderBy(F(FieldDescriptor));
end;

function TDelphiDataQuery<T>.OrderBy(FieldDescriptors : array of string) : IDataQuery<T>;
begin
  result := OrderBy(HArray.Map<string, RQuery>(FieldDescriptors,
    function(const Item : string) : RQuery
    begin
      result := F(Item);
    end));
end;

function TDelphiDataQuery<T>.OrderBy(const FieldDescriptor : RQuery) : IDataQuery<T>;
begin
  result := OrderBy([FieldDescriptor]);
end;

function TDelphiDataQuery<T>.OrderBy(FieldDescriptors : array of RQuery) : IDataQuery<T>;
var
  SortedData : TArray<T>;
  LocalFieldDescriptors : TArray<RQuery>;
  FieldDescriptor : RQuery;
begin
  LocalFieldDescriptors := HArray.ConvertDynamicToTArray<RQuery>(FieldDescriptors);
  SortedData := FData.ToArray;
  TArray.Sort<T>(SortedData, TComparer<T>.Construct(
    function(const Left, Right : T) : integer
    var
      FieldDescriptor : RQuery;
      ValueComparer : TQueryTreeNodeComparingOperator;
      i : integer;
      LeftValue, RightValue : TValue;
      Reverse : boolean;
    begin
      // assume both items are equal (only appreciable for empty FieldDescriptors)
      result := 0;
      // helper class for comparing two TValues
      ValueComparer := TQueryTreeNodeComparingOperator.Create;
      for FieldDescriptor in LocalFieldDescriptors do
      begin
        // '-' marks a field to be ordered in reverse order
        Reverse := TQueryTreeNodeField(FieldDescriptor.QueryTree).Reverse;
        // helper to query content of a field for value
        // ignore all leading - or space, because this is only for signal order
        // TQueryTreeNodeField(FieldDescriptor.QueryTree).FieldDescriptor := TQueryTreeNodeField(FieldDescriptor.QueryTree).FieldDescriptor.TrimLeft(['-', ' ']);
        LeftValue := FieldDescriptor.QueryTree.Resolve(TValue.From<T>(Left));
        RightValue := FieldDescriptor.QueryTree.Resolve(TValue.From<T>(Right));
        result := ValueComparer.CompareValue(LeftValue, RightValue);
        // FieldDescriptor.Free;
        // negate a comparing value results in reverse sorting
        if Reverse then
            result := result * -1;
        // we only need to compare next field in FieldDescriptors if current field content is equal,
        // because only then the next field influence the sorting
        if result <> 0 then
            break;
      end;
      ValueComparer.Free;
    end));
  result := TDelphiDataQuery<T>.Create(SortedData);
  for FieldDescriptor in FieldDescriptors do
      FieldDescriptor.Free;
end;

function TDelphiDataQuery<T>.ToList(Managed : boolean) : TList<T>;
begin
  if Managed then
      result := FData
  else
      result := TList<T>.Create(FData);
end;

function TDelphiDataQuery<T>.TryGet(const Query : RQuery; out ItemFound : T) : boolean;
var
  ItemIndex : integer;
begin
  ItemIndex := GetIndex(Query);
  if ItemIndex >= 0 then
  begin
    // item found
    result := True;
    ItemFound := FData[ItemIndex];
  end
  else
      result := False;
end;

function TDelphiDataQuery<T>.TryGetIndex(const Query: RQuery; out ItemIndex: integer): boolean;
begin
  ItemIndex := GetIndex(Query);
  result := ItemIndex > -1;
end;

function TDelphiDataQuery<T>.ToArray : TArray<T>;
begin
  result := FData.ToArray;
end;

function TDelphiDataQuery<T>.Values(const FieldDescriptor : string) : RValues;
var
  FieldAccessor : TQueryTreeNodeField;
  i : integer;
begin
  setlength(result.FValues, FData.Count);
  for i := 0 to FData.Count - 1 do
  begin
    FieldAccessor := TQueryTreeNodeField.Create(FieldDescriptor, []);
    result.FValues[i] := FieldAccessor.Resolve(TValue.From<T>(FData[i]));
    FieldAccessor.Free;
  end;
end;

function TDelphiDataQuery<T>.ValuesAsSingle(const FieldDescriptor : string) : TArray<single>;
begin
  result := Values(FieldDescriptor).ToArray<single>;
end;

function TDelphiDataQuery<T>.ValuesAsInteger(const FieldDescriptor : string) : TArray<integer>;
begin
  result := Values(FieldDescriptor).ToArray<integer>;
end;

function TDelphiDataQuery<T>.ValuesAsString(const FieldDescriptor : string) : TArray<string>;
begin
  result := Values(FieldDescriptor).ToArray<string>;
end;

{ RQuery }

class operator RQuery.BitwiseAnd(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpAnd.Create();
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.LogicalNot(const a : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpNot.Create();
  result.QueryTree.Childs.Add(a.QueryTree);
end;

class operator RQuery.Multiply(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpMultiply.Create();
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.BitwiseOr(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpOr.Create();
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

constructor RQuery.CreateFieldDescriptor(const FieldDescriptor : string; Parameters : array of TValue);
begin
  QueryTree := TQueryTreeNodeField.Create(FieldDescriptor, Parameters);
end;

class operator RQuery.Equal(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpEqual.Create;
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

procedure RQuery.Free;
begin
  FQueryTree.Free;
end;

class function RQuery.From<T>(const Value : T) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(TValue.From<T>(Value));
end;

class function RQuery.FromA<T>(const AArray : TArray<T>) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(TValue.From < TArray < T >> (AArray));
end;

class operator RQuery.GreaterThan(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpGreaterThan.Create;
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.GreaterThanOrEqual(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpGreaterThanOrEqual.Create;
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.LessThan(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpLessThan.Create;
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.LessThanOrEqual(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpLessThanOrEqual.Create;
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.NotEqual(const a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpNotEqual.Create;
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.in(a, b : RQuery) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeOpIn.Create;
  result.QueryTree.Childs.Add(a.QueryTree);
  result.QueryTree.Childs.Add(b.QueryTree);
end;

class operator RQuery.Implicit(const a : string) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(a);
end;

class operator RQuery.Implicit(a : integer) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(a);
end;

class operator RQuery.Implicit(a : single) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(a);
end;

class operator RQuery.Implicit(a : boolean) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(a);
end;

class operator RQuery.Implicit(const a : TArray<integer>) : RQuery;
begin
  result := RQuery.FromA<integer>(a);
end;

class operator RQuery.Implicit(const a : TArray<string>) : RQuery;
begin
  result := RQuery.FromA<string>(a);
end;

class operator RQuery.Implicit(const a : TArray<single>) : RQuery;
begin
  result := RQuery.FromA<single>(a);
end;

class operator RQuery.Implicit(a : TObject) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(a);
end;

class operator RQuery.Implicit(const a : SetByte) : RQuery;
var
  Value : TValue;
begin
  TValue.Make(@a, TypeInfo(SetByte), Value);
  result.QueryTree := TQueryTreeNodeValue.Create(Value);
end;

class operator RQuery.Implicit(a : TClass) : RQuery;
begin
  result.QueryTree := TQueryTreeNodeValue.Create(a);
end;

{ TQueryTreeNode }

constructor TQueryTreeNode.Create();
begin
  FChilds := TObjectList<TQueryTreeNode>.Create();
end;

destructor TQueryTreeNode.Destroy;
begin
  FChilds.Free;
  inherited;
end;

{ TQueryTreeNodeValue }

constructor TQueryTreeNodeValue.Create(const Value : TValue);
begin
  inherited Create;
  FValue := Value;
end;

function TQueryTreeNodeValue.Resolve(const Item : TValue) : TValue;
begin
  result := FValue;
end;

{ TQueryTreeNodeField }

constructor TQueryTreeNodeField.Create(const FieldDescriptor : string; Parameters : array of TValue);
begin
  FReverse := FieldDescriptor.StartsWith('-');
  inherited Create(FieldDescriptor.Trim(['-', ' ']));
  FParameters := HArray.ConvertDynamicToTArray<TValue>(Parameters);
end;

function TQueryTreeNodeField.GetFieldDescriptor : string;
begin
  result := FValue.AsString;
end;

function TQueryTreeNodeField.Resolve(const Item : TValue) : TValue;
var
  Tokens : TList<string>;
  Token : string;
  CurrentType : TRttiType;
  CurrentItem : TValue;
  ParameterIndex : integer;

  function ReadNextToken : string;
  begin
    Tokens.Delete(0);
    if Tokens.Count > 0 then
        Token := Tokens.First
    else
        Token := string.Empty;
    result := Token;
  end;

  function NextToken : string;
  begin
    if Tokens.Count >= 2 then
        result := Tokens[1]
    else
        result := string.Empty;
  end;

  function ParseMethod(const MethodName : string) : TValue;
  var
    Method : TRttiMethod;
    ParameterCount : integer;
  begin
    Method := CurrentType.GetMethod(MethodName);
    ParameterCount := 0;
    if NextToken = '(' then
    begin
      // pop "("
      ReadNextToken;
      // read ")" or parameter_name
      while ReadNextToken <> ')' do
        if not(Token = ',') then
        begin
          if Token = '(' then
              raise EQueryResolveError.CreateFmt('TQueryTreeNodeField.Resolve: Does not support innercalls for methods. FieldDescriptor "%s" is buggy.', [FieldDescriptor]);
          inc(ParameterCount);
        end;
    end;
    if not Method.ParameterCount = ParameterCount then
        raise EQueryResolveError.CreateFmt('TQueryTreeNodeField.Resolve: Method "%s" expect %d parameters, but %d parameter has been declared. FieldDescriptor "%s" is buggy.',
        [Method.Name, Method.ParameterCount, ParameterCount, FieldDescriptor]);
    assert(ParameterIndex + ParameterCount <= length(FParameters));
    result := Method.Invoke(CurrentItem, Copy(FParameters, ParameterIndex, ParameterCount));
  end;

  function ParseField(const FieldName : string) : TValue;
  var
    Member : TRttiMemberUnified;
  begin
    Member := TRttiMemberUnified.Create(CurrentType.GetField(FieldName));
    result := Member.GetValue(CurrentItem);
    Member.Free;
  end;

  function ParseProperty(const PropertyName : string) : TValue;
  var
    Member : TRttiMemberUnified;
  begin
    Member := TRttiMemberUnified.Create(CurrentType.GetProperty(PropertyName));
    result := Member.GetValue(CurrentItem);
    Member.Free;
  end;

begin
  // step throw the FieldDescriptor
  Tokens := TList<string>.Create();
  Tokens.AddRange(HString.Split(FieldDescriptor, ['.', '(', ',', ')'], True));
  assert(Tokens.Count > 0);
  CurrentItem := Item;
  ParameterIndex := 0;
  Token := Tokens.First;
  while Tokens.Count > 0 do
  begin
    // ignore point fieldnames, because this is caused by '..' '.field' or 'field.'
    // and is interpreted as access the current field or item itself
    if (Token <> '.') and (Token <> '') then
    begin
      if not HArray.Contains(['(', ',', ')'], Token) then
      begin
        CurrentType := CurrentItem.GetRttiType;
        if CurrentType.HasField(Token) then
            CurrentItem := ParseField(Token)
        else if CurrentType.HasProperty(Token) then
            CurrentItem := ParseProperty(Token)
        else if CurrentType.HasMethod(Token) then
            CurrentItem := ParseMethod(Token)
        else raise EQueryResolveError.CreateFmt('TQueryTreeNodeField.Resolve: In type "%s" no field/property/method with ' +
            'name "%s" was found, FieldDescriptor "%s" is buggy.', [CurrentType.Name, Token, FieldDescriptor]);
      end
      else
          raise EQueryResolveError.CreateFmt('TQueryTreeNodeField.Resolve: Unexpected Token "%s" for FieldName. FieldDescriptor "%s" is buggy.', [Token, FieldDescriptor]);
    end;
    ReadNextToken;
  end;
  result := CurrentItem;
  Tokens.Free;
end;

procedure TQueryTreeNodeField.SetFieldDescriptor(const Value : string);
begin
  FValue := Value;
end;

{ TQueryTreeNodeOpAnd }

function TQueryTreeNodeOpAnd.Resolve(const Item : TValue) : TValue;
begin
  CheckOperands(2);
  setlength(FOperands, 2);
  LoadOperand(0, Item);
  if FOperands[0].AsBoolean then
  begin
    LoadOperand(1, Item);
    result := FOperands[1].AsBoolean;
  end
  else
      result := False;
end;

{ TQueryTreeNodeOperator }

procedure TQueryTreeNodeOperator.CheckAndLoadOperands(OperandCount : integer; const Item : TValue);
var
  i : integer;
begin
  CheckOperands(OperandCount);
  setlength(FOperands, OperandCount);
  for i := 0 to OperandCount - 1 do
      LoadOperand(i, Item);
end;

procedure TQueryTreeNodeOperator.CheckOperands(OperandCount : integer);
begin
  if Childs.Count <> OperandCount then
      raise EQueryOperandCountError.CreateFmt('%s: Expected %d operands, but found %d',
      [Self.ClassName, OperandCount, Childs.Count]);
end;

procedure TQueryTreeNodeOperator.CheckOperandType(Index : integer; ClassType : CQueryTreeNode);
begin
  assert(InRange(index, 0, Childs.Count - 1));
  if not Childs[index].InheritsFrom(ClassType) then
      raise EQueryOperandTypeMissmatch.CreateFmt('%s: Expected type "%s" but found "%s".', [Self.ClassName, ClassType.ClassName, Childs[index].ClassName]);
end;

procedure TQueryTreeNodeOperator.LoadOperand(Index : integer; const Item : TValue);
begin
  FOperands[index] := FChilds[index].Resolve(Item);
end;

{ TQueryTreeNodeComparingOperator }

function TQueryTreeNodeComparingOperator.CompareValue(const Left, Right : TValue) : integer;
begin
  if Left.IsOrdinal and Right.IsOrdinal then
  begin
    result := System.Math.CompareValue(Left.AsOrdinal, Right.AsOrdinal);
  end
  else
    if Left.IsNumeric and Right.IsNumeric then
  begin
    result := System.Math.CompareValue(Left.AsExtended, Right.AsExtended);
  end
  else
    if Left.IsString and Right.IsString then
  begin
    result := string.CompareText(Left.AsString, Right.AsString);
  end
  else
  begin
    raise EQueryOperandTypeMissmatch.CreateFmt('%s: Can''t compare "%s" and "%s"',
      [Self.ClassName, Left.GetRttiType.Name, Right.GetRttiType.Name]);
  end;
end;

function TQueryTreeNodeComparingOperator.Resolve(const Item : TValue) : TValue;
begin
  CheckAndLoadOperands(2, Item);
  // No longer check operand type, because also arithmetic operations are supported
  // CheckOperandType(0, TQueryTreeNodeValue);
  // CheckOperandType(1, TQueryTreeNodeValue);
end;

function TQueryTreeNodeComparingOperator.SameValue(const Left, Right : TValue) : boolean;
begin
  result := Left.SameValue(Right);
end;

{ TQueryTreeNodeOpEqual }

function TQueryTreeNodeOpEqual.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  result := SameValue(FOperands[0], FOperands[1]);
end;

{ TQueryTreeNodeOpGreaterThan }

function TQueryTreeNodeOpGreaterThan.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) > 0;
end;

{ TQueryTreeNodeOpNotEqual }

function TQueryTreeNodeOpNotEqual.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  result := not SameValue(FOperands[0], FOperands[1]);
end;

{ TQueryTreeNodeOpLessThan }

function TQueryTreeNodeOpLessThan.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) < 0;
end;

{ TQueryTreeNodeOpGreaterThanOrEqual }

function TQueryTreeNodeOpGreaterThanOrEqual.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) >= 0;
end;

{ TQueryTreeNodeOpLessThanOrEqual }

function TQueryTreeNodeOpLessThanOrEqual.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) <= 0;
end;

{ TQueryTreeNodeOpIn }

function TQueryTreeNodeOpIn.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  result := FOperands[1].Contains(FOperands[0], True);
end;

{ RValues }

function RValues.ToArray<T> : TArray<T>;
var
  i : integer;
begin
  setlength(result, length(FValues));
  if length(FValues) > 0 then
  begin
    if FValues[0].IsType<T> then
    begin
      for i := 0 to length(FValues) - 1 do
          result[i] := FValues[i].AsType<T>;
    end
    else raise EQueryOperandTypeMissmatch.CreateFmt('TDelphiDataQuery.ValuesGeneric: Fieldtype "%s" can''t convert to target type "%s".',
        [Context.GetType(TypeInfo(T)).Name, FValues[0].GetRttiType.Name]);
  end;
end;

function RValues.ToArray : TArray<TValue>;
begin
  result := FValues;
end;

{ TQueryTreeNodeOpOr }

function TQueryTreeNodeOpOr.Resolve(const Item : TValue) : TValue;
begin
  CheckAndLoadOperands(2, Item);
  result := FOperands[0].AsBoolean or FOperands[1].AsBoolean;
end;

{ TQueryTreeNodeOpNot }

function TQueryTreeNodeOpNot.Resolve(const Item : TValue) : TValue;
begin
  CheckAndLoadOperands(1, Item);
  result := not FOperands[0].AsBoolean;
end;

{ TQueryTreeNodeArithmetikOperator }

function TQueryTreeNodeArithmeticOperator.Resolve(const Item : TValue) : TValue;
begin
  CheckAndLoadOperands(2, Item);
end;

{ TQueryTreeNodeOpMultiply }

function TQueryTreeNodeOpMultiply.Resolve(const Item : TValue) : TValue;
begin
  inherited;
  if FOperands[0].IsNumeric and FOperands[1].IsNumeric then
      result := FOperands[0].Multiply(FOperands[1])
  else
    if FOperands[0].IsSet and FOperands[1].IsSet then
      result := FOperands[0].Intersect(FOperands[1])
  else raise EQueryOperandTypeMissmatch.CreateFmt('TQueryTreeNodeOpMultiply.Resolve: Operand multiply is for "%s" and "%s" not supported.',
      [FOperands[0].GetRttiType.Name, FOperands[1].GetRttiType.Name]);
end;

end.
