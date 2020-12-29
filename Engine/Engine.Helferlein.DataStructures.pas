unit Engine.Helferlein.DataStructures;

interface

uses
  Engine.Math,
  Engine.Math.Collision3D,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.Threads,
  Engine.DataQuery,
  /// ///////////////////////////
  System.Math,
  System.Types,
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  System.Hash,
  System.Generics.Defaults,
  System.Generics.Collections;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished, vcProtected]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  ProcItemMethod<T> = reference to procedure(const Item : T);
  ProcItemWithIndexMethod<T> = reference to procedure(index : Integer; const Item : T);
  FuncItemFilterMethod<T> = reference to function(Item : T) : boolean;
  FuncItemMapMethod<T, U> = reference to function(Item : T) : U;
  FuncItemFoldOperator<U> = reference to function(const item1, item2 : U) : U;
  FuncMaximumMethod<U> = reference to function(a, b : U) : Integer;

  HFoldOperators = class
    public
      class function AddInteger(const a, b : Integer) : Integer;
  end;

  /// <summary> A generic TList with some new methods. Class helper unfortunately aren't compatible
  /// with generic classes. </summary>
  TAdvancedList<T> = class(TList<T>)
    public
      /// <summary> Returns true if all items returned true for the speciied method. </summary>
      function All(Method : FuncItemFilterMethod<T>) : boolean;
      /// <summary> Returns true if any item returned true for the speciied method. </summary>
      function Any(Method : FuncItemFilterMethod<T>) : boolean;
      /// <summary> Returns whether index is a valid index or not. </summary>
      function InRange(Index : Integer) : boolean;
      /// <summary> Calls a method for each item of this list. </summary>
      function Each(Method : ProcItemMethod<T>) : TAdvancedList<T>; overload;
      /// <summary> Calls a method for each item of this list, passes its index. </summary>
      function Each(Method : ProcItemWithIndexMethod<T>) : TAdvancedList<T>; overload;
      /// <summary> Returns a slice of this list FromIndex to ToIndex. Indices can be smaller 0
      /// for indexing from tail (-1 => last item). No wrapping, indexing must be bound, negatives too.
      /// If an FromIndex exceeds bound returns nil. ToIndex is clamped to the end.</summary>
      function Slice(FromIndex, ToIndex : Integer) : TArray<T>;
      /// <summary> Transforms all elements to U with the mapping method and afterwards folding the list with
      /// the specified operator. [Thing1, Thing2, Thing3] -> [1, 2, 3] -> 1 + 2 + 3 -> 6 </summary>
      function Fold<U>(MappingMethod : FuncItemMapMethod<T, U>; AnOperator : FuncItemFoldOperator<U>) : U;
      /// <summary> Transforms all elements to U with the mapping method and afterwards return the minimum
      /// of the values. </summary>
      function Min(MappingMethod : FuncItemMapMethod<T, Single>) : T;
      /// <summary> Transforms all elements to U with the mapping method and afterwards return the index of the minimum
      /// of the values. Returns -1 if list is empty. </summary>
      function MinIndex(MappingMethod : FuncItemMapMethod<T, Single>) : Integer;
      /// <summary> Transforms all elements to U with the mapping method and afterwards return the maximum
      /// of the values. </summary>
      function Max<U>(MappingMethod : FuncItemMapMethod<T, U>; Maximizer : FuncMaximumMethod<U>) : T;
      /// <summary> Returns a list of all elements passing the test. (List must be freed)</summary>
      function Filter(Method : FuncItemFilterMethod<T>) : TAdvancedList<T>;
      /// <summary> Returns the first element of a list that passes the test. If no element passing the test
      /// function will raise an Exception.</summary>
      function FilterFirst(Method : FuncItemFilterMethod<T>) : T;
      /// <summary> Retruns true if the list contains any item that passes the test. If no item passing the test,
      /// function will return false.</summary>
      function Exists(Method : FuncItemFilterMethod<T>) : boolean;
      /// <summary> Returns a random value from this list. </summary>
      function Random : T;
      /// <summary> Returns a random value from this list and delete it. </summary>
      function RandomExtract : T;
      function Map<U>(MappingMethod : FuncItemMapMethod<T, U>) : TAdvancedList<U>;
      /// <summary> Returns whether this list contains any items. </summary>
      function IsEmpty : boolean;
      /// <summary> Returns thether the index is in range. </summary>
      function IsValidIndex(Index : Integer) : boolean;
      /// <summary> Returns the number of all elements passing the test.</summary>
      function CountFiltered(Method : FuncItemFilterMethod<T>) : Integer;
      /// <summary> Returns the index of the first element of a list that passes the test. If no element passing the test
      /// function will return -1.</summary>
      function FilterFirstIndex(Method : FuncItemFilterMethod<T>) : Integer;
      /// <summary> Deletes all items which don't pass the given filter-method. </summary>
      function DeleteFilter(Method : FuncItemFilterMethod<T>) : TAdvancedList<T>;
      /// <summary> Deletes first items which pass the given filter-method. </summary>
      function DeleteFirst(Method : FuncItemFilterMethod<T>) : TAdvancedList<T>;
      /// <summary> Returns a copy of this list. </summary>
      function Clone : TList<T>;
      /// <summary> Removes the last item from the list. </summary>
      procedure Pop;
      /// <summary> Extracts the last item from the list. </summary>
      function PopExtract : T;
      /// <summary> Swaps the items at index i and j. If one of them does not exist, do nothing. </summary>
      procedure Swap(const i, j : Integer);
      /// <summary> Finds the index of the given Value in the list. If it isn't present, returns false.
      /// If the value is contained multiple times, it returns the index of the first. </summary>
      function TryIndexOf(const Value : T; out Index : Integer) : boolean;
  end;

  /// <summary> A generic TObjectList with some new methods. Class helper unfortunately aren't compatible
  /// with generic classes. Methods manipulates and return the list itself. </summary>
  TAdvancedObjectList<T : class> = class(TAdvancedList<T>)
    public
      /// <summary> Returns the first element, if there are no elements returns nil. </summary>
      function FirstSave() : T;
      /// <summary> Calls a method for each non-nil item of this list. </summary>
      function EachSave(Method : ProcItemMethod<T>) : TAdvancedObjectList<T>;
      /// <summary> Returns the first element of a list that passes the test. If no element passing the test
      /// function will return nil.</summary>
      function FilterFirstSave(Method : FuncItemFilterMethod<T>) : T;
  end;

  TUltimateList<T> = class;

  EnumListAction = (
    laAdd,            // New Item was added to list
    laAddRange,       // Many new items were added to list
    laRemoved,        // A Item was removed from list, but not the whole list was cleared
    laExtracted,      // An item was extracted from the list
    laExtractedRange, // A bunch of items were extracted from the list
    laChanged,        // The content or whole Item was changed, this does not affect directly the list, but is anyway important
    laClear           // The whole list was cleared
    );

  ProcUltimateListOnChange<T> = reference to procedure(Sender : TUltimateList<T>; Items : TArray<T>; Action : EnumListAction; Indices : TArray<Integer>);

  /// <summary> The ultimate list extend the generic TList<T> by some useful extensions like strong events for every
  /// action and some other enhancements. This class is for every enhancement that needs virtual methods or fields, all
  /// other enhancements should be done in TAdvancedList or TAdvancedObjectList.</summary>
  TUltimateList<T> = class(TList<T>)
    private
      function GetItem(Index : Integer) : T;
      procedure SetItem(Index : Integer; const Value : T);
    protected
      FOnChange : ProcUltimateListOnChange<T>;
      /// <summary> While BlockOnChangeNotify is true, all events that are catched by Notify will not redirected to NotifyChange.</summary>
      BlockNotify : boolean;
      property OnNotify;
      /// <summary> Enhanced Version of Notify.
      /// <param name="Items"> List of items that are affected by action.</param>
      /// <param name="Action"> Action that was applied on items.</param></summary >
      procedure NotifyChange(const Items : TArray<T>; Action : EnumListAction; Indices : TArray<Integer>); virtual;
      procedure Notify(const Item : T; Action : TCollectionNotification); override;
    public
      property OnChange : ProcUltimateListOnChange<T> read FOnChange write FOnChange;
      /// <summary> Cast UltimateList as TAdvancedList to have some enhanced methods like filter.</summary>
      function Extra : TAdvancedList<T>;
      property Items[index : Integer] : T read GetItem write SetItem; default;

      function IsEmpty : boolean; inline;

      function Add(const Value : T) : Integer; reintroduce;
      procedure AddRange(const Values : array of T); reintroduce; overload;
      procedure AddRange(const Collection : IEnumerable<T>); reintroduce; overload;
      procedure AddRange(const Collection : TEnumerable<T>); reintroduce; overload;

      procedure Insert(Index : Integer; const Value : T); reintroduce;

      procedure InsertRange(Index : Integer; const Values : array of T); reintroduce; overload;
      procedure InsertRange(Index : Integer; const Collection : IEnumerable<T>); reintroduce; overload;
      procedure InsertRange(Index : Integer; const Collection : TEnumerable<T>); reintroduce; overload;

      function Remove(const Value : T) : Integer; reintroduce;
      procedure Delete(Index : Integer); reintroduce;
      procedure DeleteRange(AIndex, ACount : Integer); reintroduce;
      function Extract(const Value : T) : T; reintroduce;
      function ExtractRange(const Values : array of T) : TArray<T>;

      /// <summary> Will move any item to a random position.</summary>
      procedure Shuffle;

      /// <summary> Same Clear as TList clear, but will cause an laClear event and NO remove event for every item.</summary>
      procedure Clear; reintroduce;
      /// <summary> Call that method will cause an laChanged event. If Item is not in the list and SuppressError is False,
      /// an error will raised, else nothing happens.</summary>
      procedure SignalItemChanged(Item : T; SuppressError : boolean = False);
      /// <summary> This will call an clear notification in the list. </summary>
      procedure FakeClear();
      /// <summary> This will call an add notification for all items in the list. </summary>
      procedure FakeCompleteAdd();
      procedure FakeCompleteChanged();
      /// <summary> Clones this list, building a new list with all content copied. OnChange-Handler is not copied. </summary>
      function Clone : TUltimateList<T>;
      function Query : IDataQuery<T>;
      destructor Destroy; override;
  end;

  /// <summary> Same as TUltimateList, but owns all items that are saved into list. So if a item is removed from list,
  /// regardless how the item was removed.</summary>
  TUltimateObjectList<T : class> = class(TUltimateList<T>)
    private
      FOwnsObjects : boolean;
    protected
      procedure NotifyChange(const Items : TArray<T>; Action : EnumListAction; Indices : TArray<Integer>); override;
    public
      property OwnsObjects : boolean read FOwnsObjects write FOwnsObjects;
      function Extra : TAdvancedObjectList<T>; reintroduce;
      /// <summary> Returns the first element, if there are no elements returns nil. </summary>
      function FirstSave() : T;
      constructor Create; overload;
      constructor Create(const AComparer : IComparer<T>); overload;
      constructor Create(const Collection : TEnumerable<T>); overload;
      destructor Destroy; override;
  end;

  /// <summary> Implement a list which can modified while loop through the list. Add actions will deferred until
  /// save loop is leaved and removed elements will replaced with nil and finally deleted after save loop is leaved.
  /// CAUTION:
  /// - Objects in list will still freed while loop through list (only index moving is prevented).
  /// - Any item in list can be nil, so any loop has to check if current item nil before work with item.</summary>
  TLoopSafeObjectList<T : class> = class
    private type
      TListActionAdd = class
        strict private
          FList : TObjectList<T>;
          FItem : T;
        public
          property List : TObjectList<T> read FList;
          property Item : T read FItem;
          constructor Create(List : TObjectList<T>; const Item : T);
          procedure DoAction;
      end;

    private
      FPendingActions : TObjectList<TListActionAdd>;
      FList : TObjectList<T>;
      /// <summary> When 0, save loop is leaved and all pending actions will applied on list.</summary>
      FSaveLoopCounter : Integer;
      procedure ApplyPendingActions;
      function GetOwnsObjects : boolean;
      procedure SetOwnsObjects(const Value : boolean);
    public
      property OwnsObjects : boolean read GetOwnsObjects write SetOwnsObjects;
      procedure Add(const Value : T);

      function Remove(const Value : T) : Integer;
      /// <summary> Returns the current number of items in list.
      /// CAUTION: Count will not change while save loop mode is enabled.</summary>
      function Count : Integer;
      /// <summary> Start save loop mode where actions will deferred. Multiple calls are allowed, but every EnterSaveLoop call
      /// has to ended with a LeaveSaveLoop call.</summary>
      procedure EnterSafeLoop;
      /// <summary> Will end save loop mode and apply any pending actions on list. Multiple calls are allowed, but
      /// changes on list will not applied until same amount Leave calls as Enter calls are made.</summary>
      procedure LeaveSafeLoop;

      function GetEnumerator : TEnumerator<T>; inline;

      constructor Create();
      destructor Destroy; override;
  end;

  TCaseInsensitiveDictionary<T> = class(TDictionary<string, T>)
    public type
      TStringPair = TPair<string, T>;
    public
      constructor Create(); overload;
      constructor Create(const Collection : TEnumerable<TStringPair>); overload;
  end;

  TCaseInsensitiveObjectDictionary<T> = class(TObjectDictionary<string, T>)
    public type
      TStringPair = TPair<string, T>;
    public
      constructor Create(Ownerships : TDictionaryOwnerships); overload;
      constructor Create(Ownerships : TDictionaryOwnerships; const Collection : TEnumerable<TStringPair>); overload;
  end;

  ProcPermutation<T> = reference to procedure(Permutation : TArray<T>);

  /// <summary> Returns all sets of values of given groups without regarding order. </summary>
  TPermutator<T> = class
    strict private
      FFixedValues : TList<T>;
      FValues : TObjectList<TList<T>>;
      FIterateInsteadOfPermutate : boolean;
    public
      constructor Create;
      /// <summary> The Values are iterated and permutated. </summary>
      function IterateInsteadOfPermutate : TPermutator<T>;
      /// <summary> Adds a value which is prepended to any permutation. </summary>
      function AddFixedValue(ValueGroup : array of T) : TPermutator<T>;
      /// <summary> Add a value to be permutated with the others. </summary>
      function AddValue(ValueGroup : array of T) : TPermutator<T>;
      /// <summary> Add values to be permutated with the others. </summary>
      function AddValues(Values : array of TArray<T>) : TPermutator<T>;
      /// <summary> Returns permutation 0 <= index < Count. </summary>
      function GetPermutation(Index : Integer) : TArray<T>;
      /// <summary> Calls the callback on each permutation. </summary>
      function Permutate(Callback : ProcPermutation<T>) : TPermutator<T>;
      /// <summary> The count of permutations of this permutator. </summary>
      function Count : Integer;
      destructor Destroy; override;
  end;

  /// <summary> Permutates all permutations of n Permutators. </summary>
  TGroupPermutator<T> = class
    strict private
      FFixedValues : TList<T>;
      FPermutators : TObjectList<TPermutator<T>>;
      procedure PermutateRecursive(PermutatorIndex : Integer; Values : TArray<T>; Callback : ProcPermutation<T>);
    public
      constructor Create(OwnsPermutators : boolean = True);
      /// <summary> Adds a value which is prepended to any permutation. </summary>
      function AddFixedValue(ValueGroup : array of T) : TGroupPermutator<T>;
      /// <summary> Add a permutator to be permutated with the others. </summary>
      function AddPermutator(Permutator : TPermutator<T>) : TGroupPermutator<T>;
      /// <summary> Calls the callback on each permutation. </summary>
      function Permutate(Callback : ProcPermutation<T>) : TGroupPermutator<T>;
      /// <summary> The count of permutations of this permutator. </summary>
      function Count : Integer;
      destructor Destroy; override;
  end;

  ProcPaginatorOnChange = reference to procedure();

  /// <summary> This paginator enables a paged view on lists. So it splits the whole amount of items in fixed chunks aka pages. </summary>
  TPaginator<T : class> = class
    strict private
      FOwnsObjects : boolean;
      FObjects, FCurrentObjects : TList<T>;
      FPageSize, FCurrentPage : Integer;
      FOnChange : ProcPaginatorOnChange;
      procedure SetCurrentPage(const Value : Integer);
      procedure SetPageSize(const Value : Integer);
      procedure SetObjects(const Value : TList<T>);
    public
      /// <summary> If the paginator owns the object list, it will be freed on change or destroy. </summary>
      property OwnsObjects : boolean read FOwnsObjects write FOwnsObjects;
      /// <summary> The current pagesize. If altered, it tries to keep the first element of the current page on the page. </summary>
      property PageSize : Integer read FPageSize write SetPageSize;
      /// <summary> All objects in this paginator. </summary>
      property Objects : TList<T> read FObjects write SetObjects;
      property OnChange : ProcPaginatorOnChange read FOnChange write FOnChange;
      property CurrentPage : Integer read FCurrentPage write SetCurrentPage;
      /// <summary> Returns a list of all objects on the current page. List is managed. </summary>
      function CurrentObjects : TList<T>;
      /// <summary> Returns the item index of the first item of the page. If there are no items returns -1. </summary>
      function PageMinIndex : Integer;
      /// <summary> Returns the item index of the last item of the page. If there are no items returns -2. </summary>
      function PageMaxIndex : Integer;
      /// <summary> If Index is not in range, returns 0 or last page regarding the way it is exceeded. </summary>
      function PageOfIndex(Index : Integer) : Integer;
      /// <summary> If Obj is not in list, returns 0. </summary>
      function PageOfObject(Obj : T) : Integer;
      function InRange(Index : Integer) : boolean;
      constructor Create(Objects : TList<T>; PageSize : Integer; OwnsObjects : boolean = False);
      function PageCount : Integer;
      function HasNext : boolean;
      procedure Next;
      function HasPrevious : boolean;
      procedure Previous;
      function IsObjectVisible(Obj : T) : boolean;
      /// <summary> Objects has been changed from the outside, update the paginator. </summary>
      procedure Update;
      destructor Destroy; override;
  end;

  EnumPriorityOrder = (poDescending, poAscending);

  /// <summary> A priority queue is a queue, where all items are sorted by a value.
  /// The item with the lowest priority value is popped first. </summary>
  TPriorityQueue<T : class; U> = class
    protected type
      RItem = record
        Item : T;
        Priority : U;
        constructor Create(Item : T; Priority : U);
      end;
    protected
      FItems : array of RItem;
      FCount : Integer;
      FOrder : EnumPriorityOrder;
      function Compare(const a, b : U) : Integer; virtual; abstract;
      procedure SetOrder(const Value : EnumPriorityOrder);
      procedure Grow;
    public
      /// <summary> Order of priority values, ascending or descending. Default is ascending.
      /// Ascending - ExtractMin returns smallest value; Descending - ExtractMin returns biggest value
      /// Change order will also affect current items.</summary>
      property Order : EnumPriorityOrder read FOrder write SetOrder;
      /// <summary> The current count of all items in the queue. </summary>
      property Count : Integer read FCount;
      constructor Create();
      /// <summary> Inserts a new item to the queue. Priority is fetched once at insertion. </summary>
      procedure Insert(const Data : T; Priority : U);
      /// <summary> Returns the first item in relation to order and removes it from the queue. </summary>
      function ExtractMin() : T;
      /// <summary> Returns the first item without removing it from the queue. </summary>
      function Peek() : T;
      /// <summary> Returns the first item priority without removing it from the queue. </summary>
      function PeekPriority() : U;
      /// <summary> Returns whether the item is in this queue or not. </summary>
      function Contains(const Item : T) : boolean;
      /// <summary> Removes the item from the priority queue.</summary>
      procedure Remove(const Item : T);
      /// <summary> Change the priorityvalue from a item.
      /// <param name="Item"> Item that's priority value is changed.</param>
      /// <param name="NewPriority"> The new priority of the item.</param>
      /// </summary>
      procedure DecreaseKey(const Item : T; NewPriority : U);
      /// <summary> Removes all items. </summary>
      procedure Clear;
      /// <summary> Returns True if the queue does not contain any items.</summary>
      function IsEmpty : boolean;
      destructor Destroy; override;
  end;

  /// <summary> A priority queue with a single typed priority. </summary>
  TPriorityQueue<T : class> = class(TPriorityQueue<T, Single>)
    protected
      function Compare(const a, b : Single) : Integer; override;
  end;

  /// <summary> A priority queue with a Int64 typed priority. </summary>
  TIntPriorityQueue<T : class> = class(TPriorityQueue<T, Int64>)
    protected
      function Compare(const a, b : Int64) : Integer; override;
  end;

  /// <summary> A generic 2D-Grid holding a class T in each node. </summary>
  T2DGrid<T> = class
    protected
      FDefaultValue : T;
      FGrid : array of array of T;
      procedure SetSize(WidthHeight : RIntVector2);
      function GetNode(x, y : Integer) : T; overload;
      procedure SetNode(xy : RIntVector2; Node : T); overload;
      function GetNode(xy : RIntVector2) : T; overload;
      procedure SetNode(x, y : Integer; Node : T); overload;
      function getHeight : Integer;
      function getWidth : Integer;
      function getSize : RIntVector2;
    public
      type
      FuncGridMethod = reference to procedure(Item : T);
      FuncGridWithIndicesMethod = reference to procedure(x, y : Integer; Item : T);
      FuncGridUpdateMethod = reference to function(x, y : Integer; Item : T) : T;
    var
      /// <summary> Sets and gets nodes savely. If indices are out of range the
      /// default value of T is returned at get or nothing happens at set. </summary>
      property Nodes[x, y : Integer] : T read GetNode write SetNode; default;
      property Nodes[xy : RIntVector2] : T read GetNode write SetNode; default;
      property Width : Integer read getWidth;
      property Height : Integer read getHeight;
      property Size : RIntVector2 read getSize write SetSize;
      /// <summary> Creates a new empty grid with specified size. </summary>
      constructor Create(Width, Height : Integer); overload;
      constructor Create(); overload;
      constructor Create(DefaultValue : T); overload;
      /// <summary> Get all adjacent neighbours of gridnode X. List has form
      /// 0 1 2
      /// 3 X 4
      /// 5 6 7  (X isn't in the list)</summary>
      function GetNeighbours(x, y : Integer) : TList<T>; overload;
      function GetNeighbours(xy : RIntVector2) : TList<T>; overload;
      /// <summary> Calls func for each item in this grid. Returns itself for chains. </summary>
      function Each(func : FuncGridMethod) : T2DGrid<T>; overload;
      function Each(func : FuncGridWithIndicesMethod) : T2DGrid<T>; overload;
      /// <summary> Calls func for each item in this grid and replaces the value with the result. Returns itself for chains. </summary>
      function Update(func : FuncGridUpdateMethod) : T2DGrid<T>;
      destructor Destroy; override;
  end;

  /// <summary> The same as a T2DGrid<T>, except special class functionality. </summary>
  T2DObjectGrid<T : class> = class(T2DGrid<T>)
    protected
      FOwnsObjects : boolean;
    public
      constructor Create(Width, Height : Integer; OwnsObjects : boolean = True);
      destructor Destroy; override;
  end;

  RPositionWeightItem<T> = record
    Position : RVector3;
    Weight : Integer;
    Item : T;
    constructor Create(Position : RVector3; Weight : Integer; Item : T);
  end;

  TTreeNode = class abstract
    protected
      FChilds : TObjectList<TTreeNode>;
      FParent : TTreeNode;
      function GetChildCount : Integer;
    public
      property ChildCount : Integer read GetChildCount;
      constructor Create;
      function Depth : Integer;
      function AddChild(Child : TTreeNode) : Integer;
      procedure DeleteChild(Index : Integer);
      procedure RemoveChild(Child : TTreeNode);
      procedure ClearChilds;
      /// <summary> Returns True if this Node has no parent node.</summary>
      function IsRootNode : boolean;
      destructor Destroy; override;
  end;

  /// <summary> A node within the <see cref="TTree"/> datastructure. Don't use it </summary>
  TTreeNode<T : class> = class abstract(TTreeNode)
    protected
      function GetChild(Index : Integer) : T;
      procedure SetChild(Index : Integer; const Value : T);
      function GetParent : T;
    public
      property Parent : T read GetParent;
      property Children[index : Integer] : T read GetChild write SetChild;
  end;

  FuncGenericCompare<T> = reference to function(const L, R : T) : boolean;

  TTreeNodeWithValue<T> = class(TTreeNode)
    private
      function GetValue : T;
      procedure SetValue(const Value : T);
    protected
      FValue : T;
      function GetChild(Index : Integer) : TTreeNodeWithValue<T>;
      procedure SetChild(Index : Integer; const Value : TTreeNodeWithValue<T>);
      function GetParentNode : TTreeNodeWithValue<T>;
    public
      property Value : T read GetValue write SetValue;
      constructor Create(const Value : T);
      /// <summary> Returns the first node with the same Value. Traverses the tree with pre-order
      /// (self, trees from childs from left to right).</summary>
      function GetNodeByValue(const Value : T; Comparer : FuncGenericCompare<T> = nil) : TTreeNodeWithValue<T>;
      property Parent : TTreeNodeWithValue<T> read GetParentNode;
      property Children[index : Integer] : TTreeNodeWithValue<T> read GetChild write SetChild;
  end;

  /// <summary> A tree datastructure containing any descendant of a TTreeNode's.</summary>
  TTree<T : TTreeNode> = class
    protected
      FRootNode : T;
      FOwnObjects : boolean;
    public
      /// <summary> First node of the tree, the rootnode. If nil, tree is empty. Rootnode
      /// has to added manually using <see cref="AddRootNode"/>.</summary>
      property RootNode : T read FRootNode;
      /// <summary> Create a new tree. Will NOT create any rootnode.
      /// <param name="OwnObjects"> If true, TreeNodes are freed on remove. </param> </summary>
      constructor Create(OwnObjects : boolean = True);
      /// <summary> Add a new rootnode</summary>
      procedure AddRootNode(Node : T);
      procedure RemoveRootNode;
      destructor Destroy; override;
  end;

  /// <summary> A node of k-d tree. Nothing interesting for the user. </summary>
  TkdTreeNode<T : class> = class
    strict private
      procedure AddItems(const Items : TArray < RPositionWeightItem < T >> );
    protected
      FPositiveChildren, FNegativeChildren : TkdTreeNode<T>;
      FSplitDimension : Integer;
      FSplit : Single;
      FIsLeaf, FOwnsObjects, FOptimal : boolean;
      FItems : TAdvancedList<RPositionWeightItem<T>>;
      FParent : TkdTreeNode<T>;
      FMaxElementCount : Integer;
      function ElementCount : Integer;
      function SplittingPlane : RPlane;
      procedure Split;
    public
      property Items : TAdvancedList < RPositionWeightItem < T >> read FItems;
      /// <summary> Returns whether this node has childnodes or is a leaf. </summary>
      property IsLeaf : boolean read FIsLeaf;
      /// <summary> Adds many items at once recursive. </summary>
      procedure AddItemsRecursive(const Items : TArray < RPositionWeightItem < T >> );
      /// <summary> Gathers all leaves. </summary>
      procedure GatherLeavesRecursive(var List : TList < TkdTreeNode < T >> ); overload;
      /// <summary> Gathers all leaves intersecting a frustum. </summary>
      procedure GatherLeavesRecursive(var List : TList<TkdTreeNode<T>>; frustum : RFrustum); overload;
      /// <summary> Opens up a new node. Splitdimension -1 means optimal split dimension. </summary>
      constructor Create(SplitDimension : Integer; MaxElementCount : Integer; Parent : TkdTreeNode<T>; OwnsObjects : boolean = False);
      destructor Destroy; override;
  end;

  /// <summary> A k-dimensional tree for spatial splitting. </summary>
  TkdTree<T : class> = class
    protected
      FRoot : TkdTreeNode<T>;
      FMaxElementCount : Integer;
      FOwnsObjects : boolean;
      FOptimalSplitDimension : boolean;
    public
      /// <summary> Each node will be splitted if the children exceeds the maximal element count. You can pass an optional
      /// weight which let elements count for more than 1. Then nodes are splitted even with fewer elements if their sum
      /// is higher the the max. In worst case splits down to single elements, if an item has higher weight than maximum.  </summary>
      constructor Create(MaxElementCount : Integer; OptimalSplitDimension : boolean = False; OwnsObjects : boolean = False); overload;
      /// <summary> Adds an item to the tree. Nil will be ignored. If node was previously added, position will be updated. </summary>
      procedure AddItem(const Position : RVector3; Item : T; Weight : Integer = 1);
      /// <summary> Adds many items at once, better structure for optimal dimension splitting. </summary>
      procedure AddItems(const Items : TList < RPositionWeightItem < T >> ); overload;
      procedure AddItems(const Items : TArray < RPositionWeightItem < T >> ); overload;
      /// <summary> Removes all item from the tree. </summary>
      procedure Clear;
      /// <summary> Return all nodes which contain at least one item. </summary>
      function GetAllLeaves() : TList<TkdTreeNode<T>>; overload;
      /// <summary> Get all leaves intersecting a frustum. </summary>
      function GetAllLeaves(frustum : RFrustum) : TList<TkdTreeNode<T>>; overload;
      /// <summary> Skadoosh. </summary>
      destructor Destroy; override;
  end;

  /// <summary> Implements a generic ring buffer. A ring buffer behave like an endless array but with a maximum number
  /// of elements that can saved in a row. To implement this, the real index = adressed index mod BufferSize
  /// Provides a default value for items that are accessed but never set.</summary>
  TRingBuffer<T> = class
    protected type
      RItemEntry = record
        Index : Integer;
        Value : T;
      end;
    protected
      FRingBuffer : TArray<RItemEntry>;
      FDefaultValue : T;
      FEnableDefaultValue : boolean;
      FLastIndex : Integer;
      function GetBufferSize : Integer;
      function GetItems(Index : Integer) : T;
      procedure SetItem(Index : Integer; const Value : T); virtual;
      function GetCellIndex(Index : Integer) : Integer; inline;
    public
      /// <summary> Autoset to index whenever a item is set.</summary>
      property LastIndex : Integer read FLastIndex;
      /// <summary> If an index is read that was never set or the value is already overwritten, the default value
      /// will be returned instead of the content of pointing cell.
      /// DefaultValue will be initiliazed with default(T)</summary>
      property DefaultValue : T read FDefaultValue write FDefaultValue;
      /// <summary> If True, DefaultValue is returned for an index that point to a cell that is not set by the index.
      /// If EnableDefaultValue is False, the value of the cell is still returned.
      /// Default = True.</summary>
      property EnableDefaultValue : boolean read FEnableDefaultValue write FEnableDefaultValue;
      /// <summary> Maximal number of items which can set in a row (row, because if the distance between two indices >
      /// size, index two could be override index one, because they point to the same cell in the ringbuffer.</summary>
      property Size : Integer read GetBufferSize;
      property Items[index : Integer] : T read GetItems write SetItem; default;
      /// <summary> Returns True is the cell that the index points is set by the index, else false.</summary>
      function IsIndexSet(Index : Integer) : boolean;
      /// <summary> Add value to end of ringbuffer using last index + 1.</summary>
      procedure Append(const Value : T);
      constructor Create(Size : Integer);
      destructor Destroy; override;
  end;

  /// <summary> Same as ringbuffer but will manage objects.</summary>
  TObjectRingBuffer<T : class> = class(TRingBuffer<T>)
    protected
      FOwnsObjects : boolean;
      procedure SetItem(Index : Integer; const Value : T); override;
    public
      property OwnsObjects : boolean read FOwnsObjects write FOwnsObjects;
      constructor Create(Size : Integer; OwnsObjects : boolean = True);
      destructor Destroy; override;
  end;

  /// ///////////////////////////////////////////////////////////////////////////////////////
  /// ///////////////////////// Action Queue ////////////////////////////////////////////////
  /// ///////////////////////////////////////////////////////////////////////////////////////

  EActionQueueError = class(Exception);

  /// <summary> Mark an action as critical. Classattribute. If an action is critical
  /// and the action execution fails, all actions in queue after this action (so every not commited action)
  /// will be rolledback.
  /// Any action NOT marked as critical will be handled as non critcial and therefore if execution fails, only
  /// this concret action will be rolled back and no other action.</summary>
  AQCriticalAction = class(TCustomAttribute);

  // ===========================
  // ==== What is a Block ======
  /// <summary> A block consists of some actions and the main purport is, that no action within the block is executed
  /// before the block is ended. Additionally it is possible to end a block with a normal close or with
  /// a caneling close (Rollback) that will preventing the block from execution completly and rollback any
  /// of the actions containing.</summary>

  /// <summary> Parent of any block attribute. NOT for direct use.</summary>
  AQBlockAttribute = class(TCustomAttribute)
    private
      FUID : string;
    public
      property UID : string read FUID;
      constructor Create(UID : string);
  end;

  /// <summary> Starts a new block.</summary>
  AQBlockStart = class(AQBlockAttribute);

  /// <summary> Parent class for all block ending (closing) attributes.</summary>
  AQBlockEnding = class abstract(AQBlockAttribute)
  end;

  /// <summary> Ends a block and mark them as successful, so the block will be processed (action by action).</summary>
  AQBlockFinished = class(AQBlockEnding);

  /// <summary> Ends a block and mark them as failed, so the block will be completly rollbacked without
  /// executing any action within the block (including starting action and ending action).</summary>
  AQBlockRollback = class(AQBlockEnding);

  /// <summary> An action defines an atomatre action for the actionqueue.</summary>
  TAction = class abstract
    protected
      // which thread has added the action
      FOriginThread : TThread;
      FErrorMsg : string;
      FReadyForExecution : boolean;
    public
      /// <summary> Execution thread will stop if an action with ReadyForExecution = False is True.
      /// On default this property is True, some attributes (like BlockStart) will change this to false.</summary>
      property ReadyForExecution : boolean read FReadyForExecution write FReadyForExecution;
      /// <summary> Contains an errorcode if the execution fails.</summary>
      property ErrorMsg : string read FErrorMsg;
      /// <summary> Thread in which this action was created.</summary>
      property OriginThread : TThread read FOriginThread;
      /// <summary> This method is called to emulate the affect of an action. This is specially to instantly
      /// make user inputs takes effect. This method has to be done in realtime, because it is called in threadcontext
      /// that create and add the action.
      /// Method ist called right after action is added to actionqueue. </summary>
      procedure Emulate; virtual;
      /// <summary> The method is called, if the actionqueue has processed all actions before and now this action will be processed.
      /// This method really change the data and e.g. send the changig to server. ATTENTION: This method will be called in
      /// a threaded context, so every change has to be threadsafe.
      /// <returns> Returns True if execution was successfull, else False</returns></summary>
      function Execute : boolean; virtual;
      /// <summary> Will be call after Execute and only if it was successful, but will executed in OriginThread content. </summary>
      function ExecuteSynchronized : boolean; virtual;
      /// <summary> Will be call after Execute and only if it was not successful, but will executed in OriginThread content. </summary>
      procedure Rollback; virtual;
      /// <summary> Called if this action will be processed, regardless if rollback or execute will be called, this method will also called.
      /// Method is called in OriginThread context.</summary>
      procedure Finished; virtual;
      constructor Create;
  end;

  ProcInlineAction = reference to procedure;
  FuncInlineAction = reference to function() : boolean;

  /// <summary> A dynamic action to be filled with anonymous methods. </summary>
  TActionInline = class(TAction)
    strict private
      FEmulate, FRollback, FFinished : ProcInlineAction;
      FExecute, FExecuteSynchronized : FuncInlineAction;
    public
      function OnEmulate(const Action : ProcInlineAction) : TActionInline; overload;
      function OnExecute(const Action : FuncInlineAction) : TActionInline; overload;
      function OnExecuteSynchronized(const Action : FuncInlineAction) : TActionInline; overload;
      function OnRollback(const Action : ProcInlineAction) : TActionInline; overload;
      function OnFinished(const Action : ProcInlineAction) : TActionInline; overload;
      procedure Emulate; override;
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
      procedure Rollback; override;
      procedure Finished; override;
  end;

  ProcActionQueueErrorCallback = reference to procedure(CriticalError : boolean; const ErrorMsg : string; ActionClass : TClass);

  /// <summary> Ac action queue is a deferred action system, where the effect of the action
  /// will be emulated as fast as possible and the concrect action execution is deferred. When the
  /// exectuion fails, the emulation will be rolled back.
  /// The execution will be done within a thread and all action will be executed </summary>
  TActionQueue = class
    private const
      WAIT_FOR_ACTION_TIMEOUT = 250;
    private
      FOnClearQueueFinished : ProcCallback;
      /// <summary> Any action that is added to queue, will first added to this list to prevent that
      /// an emulate within an emulate would cause order issues.</summary>
      FDoActionQueue : TList<TAction>;
      function GetOnError : ProcActionQueueErrorCallback;
      procedure SetOnError(const Value : ProcActionQueueErrorCallback);

    type
      TProcessActionThread = class(TThread)
        private
          FActionWaits : TEvent;
          FLastActionClassname : string;
          FActionQueue : TThreadSafeObjectData<TObjectList<TAction>>;
          /// <summary> If there is currently any block started, this variable is set, else it is nil.</summary>
          FCurrentBlockUid : string;
          FClearQueue : boolean;
        protected
          FOnError : ProcActionQueueErrorCallback;
          FOwner : TActionQueue;
          procedure Execute; override;
          procedure DoClearQueue;
        public
          property OnError : ProcActionQueueErrorCallback read FOnError write FOnError;
          property ActionQueue : TThreadSafeObjectData < TObjectList < TAction >> read FActionQueue;
          /// <summary> For debugging, last action classname.</summary>
          property LastActionClassname : string read FLastActionClassname;
          procedure AddAction(const Action : TAction);
          constructor Create(Owner : TActionQueue);
          destructor Destroy; override;
      end;
    protected
      FProcessActionThread : TProcessActionThread;
      FIsActive : boolean;
      FEmulateIsActive : boolean;
      FProcessActionThreadRunning : boolean;
    public
      property OnClearQueueFinished : ProcCallback read FOnClearQueueFinished write FOnClearQueueFinished;
      /// <summary> A flag that shows, whether the current execution point takes place in an action from
      /// the action queue or not. Only set in mainthread synchronized methods (Emulate, ExecuteSynchronized, Rollback and Finished) </summary>
      property IsActive : boolean read FIsActive;
      /// <summary> Called if an error occurs while action are processed. CriticalError is True, if
      /// the action was a critical action, else False.</summary>
      property OnError : ProcActionQueueErrorCallback read GetOnError write SetOnError;
      /// <summary> Will be start processing the action, this splits in:
      /// 1. emulate the action (in caller thread context)
      /// 2. execute the action (in ProcessActionThread context)
      /// 3. if error -> rollback action (in caller thread context) </summary>
      procedure DoAction(const Action : TAction);
      // ===================== Constructor and destructor =====================
      constructor Create;
      /// <summary> If called, the queue is signaled to stop current action execution and clear all waiting actions.
      /// CAUTION: This will not rollback any actions, it will simply reset the complete queue to empty. </summary>
      procedure ClearQueue;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ T2DGrid<T> }

constructor T2DGrid<T>.Create(Width, Height : Integer);
begin
  SetSize(RIntVector2.Create(Width, Height));
end;

constructor T2DGrid<T>.Create;
begin
  Create(0, 0);
end;

constructor T2DGrid<T>.Create(DefaultValue : T);
begin
  FDefaultValue := DefaultValue;
  Create;
end;

destructor T2DGrid<T>.Destroy;
begin
  inherited;
end;

function T2DGrid<T>.Each(func : FuncGridWithIndicesMethod) : T2DGrid<T>;
var
  x, y : Integer;
begin
  for x := 0 to Width - 1 do
    for y := 0 to Height - 1 do
        func(x, y, self[x, y]);
  Result := self;
end;

function T2DGrid<T>.Each(func : FuncGridMethod) : T2DGrid<T>;
var
  x, y : Integer;
begin
  for x := 0 to Width - 1 do
    for y := 0 to Height - 1 do
        func(self[x, y]);
  Result := self;
end;

function T2DGrid<T>.getHeight : Integer;
begin
  if Width > 0 then Result := length(FGrid[0])
  else Result := 0;
end;

function T2DGrid<T>.GetNeighbours(x, y : Integer) : TList<T>;
var
  i, j : Integer;
begin
  Result := TList<T>.Create;
  for i := -1 to 1 do
    for j := -1 to 1 do
      if not((i = 0) and (j = 0)) then
      begin
        Result.Add(GetNode(x + j, y + i));
      end;
end;

function T2DGrid<T>.GetNeighbours(xy : RIntVector2) : TList<T>;
begin
  Result := GetNeighbours(xy.x, xy.y);
end;

function T2DGrid<T>.GetNode(xy : RIntVector2) : T;
begin
  Result := GetNode(xy.x, xy.y);
end;

function T2DGrid<T>.GetNode(x, y : Integer) : T;
begin
  if (x >= 0) and (x < Width) and (y >= 0) and (y < Height) then
  begin
    Result := FGrid[x, y];
  end
  else Result := FDefaultValue;
end;

function T2DGrid<T>.getSize : RIntVector2;
begin
  Result := RIntVector2.Create(Width, Height);
end;

function T2DGrid<T>.getWidth : Integer;
begin
  Result := length(FGrid)
end;

procedure T2DGrid<T>.SetNode(x, y : Integer; Node : T);
begin
  if (x >= 0) and (x < Width) and (y >= 0) and (y < Height) then
  begin
    FGrid[x, y] := Node;
  end;
end;

procedure T2DGrid<T>.SetNode(xy : RIntVector2; Node : T);
begin
  SetNode(xy.x, xy.y, Node);
end;

procedure T2DGrid<T>.SetSize(WidthHeight : RIntVector2);
var
  i : Integer;
  j : Integer;
begin
  SetLength(FGrid, WidthHeight.x);
  for i := 0 to WidthHeight.x - 1 do
  begin
    SetLength(FGrid[i], WidthHeight.y);
    for j := 0 to WidthHeight.y - 1 do
        FGrid[i, j] := FDefaultValue;
  end;
end;

function T2DGrid<T>.Update(func : FuncGridUpdateMethod) : T2DGrid<T>;
var
  x, y : Integer;
begin
  for x := 0 to Width - 1 do
    for y := 0 to Height - 1 do
        self[x, y] := func(x, y, self[x, y]);
  Result := self;
end;

{ T2DObjectGrid<T> }

constructor T2DObjectGrid<T>.Create(Width, Height : Integer; OwnsObjects : boolean);
begin
  inherited Create(Width, Height);
  FOwnsObjects := OwnsObjects;
end;

destructor T2DObjectGrid<T>.Destroy;
begin
  Each(
    procedure(Item : T)
    begin
      Item.Free;
    end);
  inherited;
end;

{ TPriorityQueue<T,U> }

procedure TPriorityQueue<T, U>.Clear;
begin
  FCount := 0;
  Grow;
end;

function TPriorityQueue<T, U>.Contains(const Item : T) : boolean;
var
  i : Integer;
begin
  Result := False;
  for i := 0 to FCount - 1 do
    if Item = FItems[i].Item then exit(True);
end;

constructor TPriorityQueue<T, U>.Create();
begin
  FOrder := poAscending;
end;

procedure TPriorityQueue<T, U>.DecreaseKey(const Item : T; NewPriority : U);
begin
  Remove(Item);
  Insert(Item, NewPriority);
end;

destructor TPriorityQueue<T, U>.Destroy;
begin

  inherited;
end;

function TPriorityQueue<T, U>.ExtractMin : T;
begin
  assert(FCount > 0, 'TPriorityQueue<T,U>.ExtractMin: Called with Count = 0!');
  Result := FItems[FCount - 1].Item;
  dec(FCount);
  Grow;
end;

procedure TPriorityQueue<T, U>.Grow;
begin
  // grow
  while length(FItems) < FCount do
  begin
    if length(FItems) = 0 then SetLength(FItems, 1)
    else SetLength(FItems, length(FItems) * 2);
  end;
  // shrink
  while (length(FItems) >= FCount * 2) and (length(FItems) > 2) do
  begin
    SetLength(FItems, length(FItems) div 2);
  end;
end;

procedure TPriorityQueue<T, U>.Insert(const Data : T; Priority : U);
var
  i : Integer;
  newitem : RItem;
  inserted : boolean;
  OrderCompareValue : Integer;
begin
  inc(FCount);
  Grow;
  newitem := RItem.Create(Data, Priority);
  inserted := False;
  case Order of
    poAscending : OrderCompareValue := GreaterThanValue;
    poDescending : OrderCompareValue := LessThanValue;
  end;
  for i := FCount - 2 downto 0 do
  begin
    if Compare(newitem.Priority, FItems[i].Priority) = OrderCompareValue then FItems[i + 1] := FItems[i]
    else
    begin
      FItems[i + 1] := newitem;
      inserted := True;
      break;
    end;
  end;
  if not inserted then FItems[0] := newitem;
end;

function TPriorityQueue<T, U>.IsEmpty : boolean;
begin
  Result := FCount <= 0;
end;

function TPriorityQueue<T, U>.Peek : T;
begin
  assert(FCount > 0, 'TPriorityQueue<T,U>.Peek: Called with Count = 0!');
  Result := FItems[FCount - 1].Item;
end;

function TPriorityQueue<T, U>.PeekPriority : U;
begin
  assert(FCount > 0, 'TPriorityQueue<T,U>.PeekPriority: Called with Count = 0!');
  Result := FItems[FCount - 1].Priority;
end;

procedure TPriorityQueue<T, U>.Remove(const Item : T);
var
  i : Integer;
  removed : boolean;
begin
  removed := False;
  for i := 0 to FCount - 1 do
  begin
    if removed then
    begin
      FItems[i - 1] := FItems[i];
    end
    else
      if Item = FItems[i].Item then removed := True;
  end;
  if removed then
  begin
    dec(FCount);
    Grow;
  end;
end;

procedure TPriorityQueue<T, U>.SetOrder(const Value : EnumPriorityOrder);
begin
  HArray.Reverse<RItem>(FItems, FCount);
  FOrder := Value;
end;

{ TPriorityQueue<T,U>.RItem }

constructor TPriorityQueue<T, U>.RItem.Create(Item : T; Priority : U);
begin
  self.Item := Item;
  self.Priority := Priority;
end;

{ TkdTree<T> }

procedure TkdTree<T>.AddItem(const Position : RVector3; Item : T; Weight : Integer);
begin
  FRoot.AddItemsRecursive(TArray < RPositionWeightItem < T >>.Create(RPositionWeightItem<T>.Create(Position, Weight, Item)));
end;

procedure TkdTree<T>.AddItems(const Items : TList < RPositionWeightItem < T >> );
begin
  FRoot.AddItemsRecursive(Items.ToArray);
end;

procedure TkdTree<T>.AddItems(const Items : TArray < RPositionWeightItem < T >> );
begin
  FRoot.AddItemsRecursive(Items);
end;

procedure TkdTree<T>.Clear;
begin
  FRoot.Free;
  FRoot := TkdTreeNode<T>.Create(HGeneric.TertOp<Integer>(FOptimalSplitDimension, -1, 0), FMaxElementCount, nil, FOwnsObjects);
end;

constructor TkdTree<T>.Create(MaxElementCount : Integer; OptimalSplitDimension : boolean; OwnsObjects : boolean);
begin
  FMaxElementCount := MaxElementCount;
  FOwnsObjects := OwnsObjects;
  FOptimalSplitDimension := OptimalSplitDimension;
  Clear;
end;

destructor TkdTree<T>.Destroy;
begin
  FRoot.Free;
  inherited;
end;

function TkdTree<T>.GetAllLeaves(frustum : RFrustum) : TList<TkdTreeNode<T>>;
begin
  Result := TList < TkdTreeNode < T >>.Create;
  FRoot.GatherLeavesRecursive(Result, frustum);
end;

function TkdTree<T>.GetAllLeaves : TList<TkdTreeNode<T>>;
begin
  Result := TList < TkdTreeNode < T >>.Create;
  FRoot.GatherLeavesRecursive(Result);
end;

{ TkdTreeNode<T> }

procedure TkdTreeNode<T>.AddItems(const Items : TArray < RPositionWeightItem < T >> );
begin
  FItems.AddRange(Items);
  if ElementCount > FMaxElementCount then Split;
end;

procedure TkdTreeNode<T>.AddItemsRecursive(const Items : TArray < RPositionWeightItem < T >> );
var
  left, right : TList<RPositionWeightItem<T>>;
  i : Integer;
begin
  if IsLeaf then AddItems(Items)
  else
  begin
    left := TList < RPositionWeightItem < T >>.Create;
    right := TList < RPositionWeightItem < T >>.Create;
    for i := 0 to length(Items) do
    begin
      if Items[i].Position.Element[FSplitDimension] >= FSplit then left.Add(Items[i])
      else right.Add(Items[i]);
    end;
    FPositiveChildren.AddItemsRecursive(left.ToArray);
    FNegativeChildren.AddItemsRecursive(right.ToArray);
    left.Free;
    right.Free;
  end;
end;

procedure TkdTreeNode<T>.Split;
var
  i, FNextSplitDimension, splitIndex : Integer;
  rangeMin, rangeMax : RVector3;
begin
  assert((FMaxElementCount >= 1) and (ElementCount > FMaxElementCount), 'TkdTreeNode<T>.Split: Unexpected Split!');
  FIsLeaf := False;
  if FSplitDimension = -1 then
  begin
    FNextSplitDimension := -1;
    // determine best dimension
    rangeMin := FItems.First.Position;
    rangeMax := rangeMin;
    for i := 1 to FItems.Count - 1 do
    begin
      rangeMin := FItems[i].Position.MinEachComponent(rangeMin);
      rangeMax := FItems[i].Position.MaxEachComponent(rangeMax);
    end;
    FSplitDimension := (rangeMax - rangeMin).MaxAbsDimension;
  end
  // or cycling through dimensions
  else FNextSplitDimension := (FSplitDimension + 1) mod 3;

  FItems.Sort(TComparer < RPositionWeightItem < T >>.Construct(
    function(const left, right : RPositionWeightItem<T>) : Integer
    begin
      Result := sign(right.Position.Element[FSplitDimension] - left.Position.Element[FSplitDimension]);
    end));
  FPositiveChildren := TkdTreeNode<T>.Create(FNextSplitDimension, FMaxElementCount, self, FOwnsObjects);
  FNegativeChildren := TkdTreeNode<T>.Create(FNextSplitDimension, FMaxElementCount, self, FOwnsObjects);
  assert(FItems.Count >= 2);
  splitIndex := (FItems.Count div 2) - 1;
  FSplit := FItems[splitIndex].Position.Element[FSplitDimension];
  FPositiveChildren.AddItemsRecursive(FItems.Slice(0, splitIndex));
  FNegativeChildren.AddItemsRecursive(FItems.Slice(splitIndex + 1, -1));
  FItems.Clear;
end;

function TkdTreeNode<T>.SplittingPlane : RPlane;
begin
  Result := RPlane.CreateFromNormal(RVector3.ZERO.SetDim(FSplitDimension, FSplit), RVector3.ZERO.SetDim(FSplitDimension, 1))
end;

constructor TkdTreeNode<T>.Create(SplitDimension, MaxElementCount : Integer; Parent : TkdTreeNode<T>; OwnsObjects : boolean);
begin
  FItems := TAdvancedList < RPositionWeightItem < T >>.Create;
  FSplitDimension := SplitDimension;
  FMaxElementCount := MaxElementCount;
  FParent := Parent;
  FIsLeaf := True;
  FOptimal := SplitDimension <= -1;
end;

destructor TkdTreeNode<T>.Destroy;
begin
  FPositiveChildren.Free;
  FNegativeChildren.Free;
  if FOwnsObjects then FItems.Each(
      procedure(const Item : RPositionWeightItem<T>)
      begin
        Item.Item.Free;
      end);
  FItems.Free;
  inherited;
end;

function TkdTreeNode<T>.ElementCount : Integer;
begin
  Result := FItems.Fold<Integer>(
    function(Item : RPositionWeightItem<T>) : Integer
    begin
      Result := Item.Weight;
    end,
    HFoldOperators.AddInteger);
end;

procedure TkdTreeNode<T>.GatherLeavesRecursive(var List : TList<TkdTreeNode<T>>; frustum : RFrustum);
var
  visible : Single;
begin
  if IsLeaf then List.Add(self)
  else
  begin
    visible := frustum.DistanceToPlane(SplittingPlane);
    if visible >= 0 then FPositiveChildren.GatherLeavesRecursive(List, frustum);
    if visible <= 0 then FNegativeChildren.GatherLeavesRecursive(List, frustum);
  end;
end;

procedure TkdTreeNode<T>.GatherLeavesRecursive(var List : TList < TkdTreeNode < T >> );
begin
  if IsLeaf then List.Add(self)
  else
  begin
    FPositiveChildren.GatherLeavesRecursive(List);
    FNegativeChildren.GatherLeavesRecursive(List);
  end;
end;

{ RPositionWeightItem<T> }

constructor RPositionWeightItem<T>.Create(Position : RVector3; Weight : Integer; Item : T);
begin
  self.Position := Position;
  self.Weight := Weight;
  self.Item := Item;
end;

{ TRingBuffer<T> }

procedure TRingBuffer<T>.Append(const Value : T);
begin
  Items[LastIndex + 1] := Value;
end;

constructor TRingBuffer<T>.Create(Size : Integer);
begin
  assert(Size > 0);
  FLastIndex := -1;
  SetLength(FRingBuffer, Size);
  // clear complete buffer
  FillChar(FRingBuffer[0], SizeOf(RItemEntry) * length(FRingBuffer), 0);
  FDefaultValue := default (T);
  FEnableDefaultValue := True;
end;

destructor TRingBuffer<T>.Destroy;
begin
  FRingBuffer := nil;
  inherited;
end;

function TRingBuffer<T>.GetBufferSize : Integer;
begin
  Result := length(FRingBuffer);
end;

function TRingBuffer<T>.GetItems(Index : Integer) : T;
var
  cellIndex : Integer;
begin
  cellIndex := GetCellIndex(index);
  if not FEnableDefaultValue or (FRingBuffer[cellIndex].Index = index) then
      Result := FRingBuffer[cellIndex].Value
  else
      Result := FDefaultValue;
end;

function TRingBuffer<T>.GetCellIndex(Index : Integer) : Integer;
begin
  assert(index >= 0);
  Result := index mod length(FRingBuffer);
end;

function TRingBuffer<T>.IsIndexSet(Index : Integer) : boolean;
begin
  Result := FRingBuffer[GetCellIndex(index)].Index = index;
end;

procedure TRingBuffer<T>.SetItem(Index : Integer; const Value : T);
var
  cellIndex : Integer;
begin
  cellIndex := GetCellIndex(index);
  FRingBuffer[cellIndex].Index := index;
  FRingBuffer[cellIndex].Value := Value;
  FLastIndex := index;
end;

{ TActionQueue }

procedure TActionQueue.ClearQueue;
begin
  FProcessActionThread.FClearQueue := True;
  FProcessActionThread.FActionWaits.SetEvent;
end;

constructor TActionQueue.Create;
begin
  FDoActionQueue := TList<TAction>.Create;
  FProcessActionThread := TProcessActionThread.Create(self);
end;

destructor TActionQueue.Destroy;
var
  ShutdownTimer : TTimer;
begin
  ShutdownTimer := TTimer.CreateAndStart(10000);
  FProcessActionThread.Terminate;
  while FProcessActionThreadRunning do
  begin
    FProcessActionThread.WaitFor;
    CheckSynchronize();
    if ShutdownTimer.Expired then
        raise EActionQueueError.CreateFmt('TActionQueue.Destroy: Thread could not terminated within 10 seconds. Current action "%s".', [FProcessActionThread.LastActionClassname]);
  end;
  FProcessActionThread.Free;

  FDoActionQueue.Free;
  ShutdownTimer.Free;
  inherited;
end;

procedure TActionQueue.DoAction(const Action : TAction);
var
  isActiveState, EmulateIsActiveState : boolean;
  i : Integer;
begin
  FDoActionQueue.Add(Action);
  isActiveState := FIsActive;
  EmulateIsActiveState := FEmulateIsActive;
  FIsActive := True;
  FEmulateIsActive := True;
  Action.Emulate;
  FIsActive := isActiveState;
  FEmulateIsActive := EmulateIsActiveState;
  // the first action has to add the queue as otherwise execution could start before all emulates are done
  if not FEmulateIsActive then
  begin
    // don't add action directly, instead using the queue to avoid errors through emulate within emulate bug
    // (new action added while emulate)
    for i := 0 to FDoActionQueue.Count - 1 do
    begin
      FProcessActionThread.AddAction(FDoActionQueue[i]);
    end;
    FDoActionQueue.Clear;
  end;
end;

function TActionQueue.GetOnError : ProcActionQueueErrorCallback;
begin
  Result := FProcessActionThread.OnError;
end;

procedure TActionQueue.SetOnError(const Value : ProcActionQueueErrorCallback);
begin
  FProcessActionThread.OnError := Value;
end;

{ TActionQueue.TProcessActionThread }

procedure TActionQueue.TProcessActionThread.AddAction(const Action : TAction);
var
  BlockAttribute : AQBlockAttribute;
  BlockStartAttribute : AQBlockStart;
  i, BlockStartingActionIndex : Integer;
begin
  BlockAttribute := AQBlockAttribute(HRtti.GetAttribute(Action, AQBlockAttribute));
  // Actions that are a starting or ending block needs some extra code
  if BlockAttribute <> nil then
  begin
    // starting a new block
    if BlockAttribute is AQBlockStart then
    begin
      // block starting action executions has to wait until block is ended
      Action.ReadyForExecution := False;
      // nested blocks are not supported, so only a new block can be started, if all other blocks ended
      if FCurrentBlockUid.IsEmpty then
      begin
        FCurrentBlockUid := BlockAttribute.UID;
      end
      else
          raise EActionQueueError.CreateFmt('TActionQueue.TProcessActionThread.AddAction: Try to start a new block "%s" while ' +
          'another block "%s" is still open.', [BlockAttribute.UID, FCurrentBlockUid]);
      ActionQueue.Lock;
      ActionQueue.Data.Add(Action);
      ActionQueue.Unlock;
    end
    // ending the current block
    else if BlockAttribute is AQBlockEnding then
    begin
      if FCurrentBlockUid.IsEmpty then
          raise EActionQueueError.CreateFmt('TActionQueue.TProcessActionThread.AddAction: Try to end the block "%s", but block was never started.', [BlockAttribute.UID]);
      if FCurrentBlockUid <> BlockAttribute.UID then
          raise EActionQueueError.CreateFmt('TActionQueue.TProcessActionThread.AddAction: Try to end the block "%s" while ' +
          'currently the block "%s" is open.', [BlockAttribute.UID, FCurrentBlockUid]);
      // successful ending block (allow executing every action in block)
      if BlockAttribute is AQBlockFinished then
      begin
        // End block successful by allowing the execution of the action that starts the block
        ActionQueue.Lock;
        for i := ActionQueue.Data.Count - 1 downto 0 do
        begin
          BlockStartAttribute := AQBlockStart(HRtti.GetAttribute(ActionQueue.Data[i], AQBlockStart));
          if BlockStartAttribute <> nil then
          begin
            assert(BlockStartAttribute.UID = FCurrentBlockUid);
            // now block is ended, so allow starting action to be executed
            ActionQueue.Data[i].ReadyForExecution := True;
            break;
          end;
        end;
        // and add ending block action aka current action
        ActionQueue.Data.Add(Action);
        ActionQueue.Unlock;
      end
      // fail ending block (rollback any action within block)
      else if BlockAttribute is AQBlockRollback then
      begin
        ActionQueue.Lock;
        // we want to also rollback block ending action
        ActionQueue.Data.Add(Action);
        // but we don't want to rollback the complete actionqueue, only the block
        // on the last position is the block ending action, but we need to now also the starting block action
        BlockStartingActionIndex := -1;
        for i := ActionQueue.Data.Count - 1 downto 0 do
        begin
          ActionQueue.Data[i].Rollback;
          BlockStartAttribute := AQBlockStart(HRtti.GetAttribute(ActionQueue.Data[i], AQBlockStart));
          // found block starting action, stop rollback
          if BlockStartAttribute <> nil then
          begin
            assert(BlockAttribute.UID = BlockStartAttribute.UID);
            BlockStartingActionIndex := i;
            break;
          end;
        end;
        assert(BlockStartingActionIndex >= 0, 'TActionQueue.TProcessActionThread.AddAction: No block starting action for ended block found.');
        // end finally delete all rollbacked action (this will also free them)
        ActionQueue.Data.DeleteRange(BlockStartingActionIndex, ActionQueue.Data.Count - BlockStartingActionIndex);
        ActionQueue.Unlock;
      end
      else assert(False, 'TActionQueue.TProcessActionThread.AddAction: Seems that an block attribute has not implemented.');
      // after ending the current block, no current block is set, so FCurrentBlockUid will be empty
      FCurrentBlockUid := '';
    end
    else assert(False, 'TActionQueue.TProcessActionThread.AddAction: Seems that an block attribute has not implemented.');
  end
  else
  begin
    ActionQueue.Lock;
    ActionQueue.Data.Add(Action);
    ActionQueue.Unlock;
  end;

  // independently what happend, wakeup execution thread,
  // it will also handle an empty actionqueue
  FActionWaits.SetEvent;
end;

constructor TActionQueue.TProcessActionThread.Create(Owner : TActionQueue);
var
  UID : TGuid;
begin
  FOwner := Owner;
  CreateGuid(UID);
  FActionWaits := TEvent.Create(nil, True, False, GuidToString(UID));
  FActionQueue := TThreadSafeObjectData < TObjectList < TAction >>.Create(TObjectList<TAction>.Create());
  inherited Create(False);
end;

destructor TActionQueue.TProcessActionThread.Destroy;
begin
  // this also stops the thread
  inherited;
  FActionWaits.Free;
  FActionQueue.Free;
end;

procedure TActionQueue.TProcessActionThread.DoClearQueue;
begin
  FClearQueue := False;
  FActionQueue.Lock;
  FActionQueue.Data.Clear;
  FActionQueue.Unlock;
  if assigned(FOwner.OnClearQueueFinished) then
      DoSynchronized(TThreadProcedure(FOwner.OnClearQueueFinished));
end;

procedure TActionQueue.TProcessActionThread.Execute;
var
  waitResult : TWaitResult;
  Action : TAction;
  ActionClass : TClass;
  executionSuccessful : boolean;
  ErrorMsg : string;
begin
  NameThreadForDebugging('ActionQueueThread');
  FOwner.FProcessActionThreadRunning := True;
  try
    while not Terminated do
    begin
      waitResult := FActionWaits.WaitFor(WAIT_FOR_ACTION_TIMEOUT);
      if waitResult = TWaitResult.wrSignaled then
      begin
        repeat
          if FClearQueue then
          begin
            DoClearQueue;
            break;
          end;
          FActionWaits.ResetEvent;
          ActionQueue.Lock;
          if FActionQueue.Data.Count > 0 then
          begin
            Action := FActionQueue.Data.First;
            FLastActionClassname := Action.ClassName;
          end
          else
          begin
            Action := nil;
            FLastActionClassname := '';
          end;
          ActionQueue.Unlock;
          // only if there any action that needs to be processed, do this
          if (Action <> nil) and Action.ReadyForExecution then
          begin
            // do the action execution
            try
              executionSuccessful := Action.Execute;
              // only execute secound execute, if first was successful
              // but this time synchronized (mainly for GUI changing actions)
              if executionSuccessful then
                  Synchronize(Action.OriginThread,
                  procedure()
                  begin
                    FOwner.FIsActive := True;
                    executionSuccessful := Action.ExecuteSynchronized();
                    FOwner.FIsActive := False;
                  end);
            except
              on e : Exception do
              begin
                executionSuccessful := False;
                Action.FErrorMsg := e.Message;
              end;
            end;

            if executionSuccessful then
            begin
              Synchronize(Action.OriginThread,
                procedure()
                begin
                  FOwner.FIsActive := True;
                  Action.Finished();
                  FOwner.FIsActive := False;
                end);
              ActionQueue.Lock;
              // pop current action (and ensure in next pass the next action will be processed) and free them (through delete)
              ActionQueue.Data.Delete(0);
              ActionQueue.Unlock;
            end
            else
            begin
              // through synchronization with origin thread, current thread can directly access actionqueue
              // no danger that two threads accessing actionqueue simultaneously
              Synchronize(Action.OriginThread,
                procedure()
                var
                  i : Integer;
                begin
                  FOwner.FIsActive := True;
                  // failing critical actions causes every action on queue to be rollbacked
                  if HRtti.HasAttribute(Action, AQCriticalAction) then
                  begin
                    for i := ActionQueue.Data.Count - 1 downto 0 do
                    begin
                      ActionQueue.Data[i].Rollback();
                      ActionQueue.Data[i].Finished();
                    end;
                    // get errormsg before action is gone
                    ErrorMsg := Action.ErrorMsg;
                    ActionClass := Action.ClassType;
                    // every action in queue is now invalid, so drop them
                    ActionQueue.Data.Clear;
                    if assigned(FOnError) then FOnError(True, ErrorMsg, ActionClass);
                  end
                  else
                  begin
                    // for non critical actions, only need to rollback current action
                    // and remove it from queue
                    Action.Rollback();
                    Action.Finished();
                    ErrorMsg := Action.ErrorMsg;
                    ActionClass := Action.ClassType;
                    // pop current action (and ensure in next pass the next action will be processed) and free them
                    ActionQueue.Data.Delete(0);
                    // get errormsg before action is gone
                    if assigned(FOnError) then FOnError(False, ErrorMsg, ActionClass);
                  end;
                  FOwner.FIsActive := False;
                end);
            end;
          end;
        until (Action = nil) or not Action.ReadyForExecution or Terminated;
      end;
    end;
  finally
    FOwner.FProcessActionThreadRunning := False;
  end;
end;

{ TAction }

constructor TAction.Create;
begin
  FOriginThread := TThread.CurrentThread;
  FReadyForExecution := True;
end;

procedure TAction.Emulate;
begin

end;

function TAction.Execute : boolean;
begin
  Result := True;
end;

function TAction.ExecuteSynchronized : boolean;
begin
  Result := True;
end;

procedure TAction.Finished;
begin

end;

procedure TAction.Rollback;
begin

end;

{ AQBlockAttribute }

constructor AQBlockAttribute.Create(UID : string);
begin
  FUID := UID;
end;

{ TActionInline }

procedure TActionInline.Emulate;
begin
  if assigned(FEmulate) then FEmulate();
end;

function TActionInline.Execute : boolean;
begin
  if assigned(FExecute) then Result := FExecute()
  else Result := True;
end;

function TActionInline.ExecuteSynchronized : boolean;
begin
  if assigned(FExecuteSynchronized) then Result := FExecuteSynchronized()
  else Result := True;
end;

procedure TActionInline.Finished;
begin
  if assigned(FFinished) then FFinished();
end;

function TActionInline.OnEmulate(const Action : ProcInlineAction) : TActionInline;
begin
  Result := self;
  FEmulate := Action;
end;

function TActionInline.OnExecute(const Action : FuncInlineAction) : TActionInline;
begin
  Result := self;
  FExecute := Action;
end;

function TActionInline.OnExecuteSynchronized(const Action : FuncInlineAction) : TActionInline;
begin
  Result := self;
  FExecuteSynchronized := Action;
end;

function TActionInline.OnFinished(const Action : ProcInlineAction) : TActionInline;
begin
  Result := self;
  FFinished := Action;
end;

function TActionInline.OnRollback(const Action : ProcInlineAction) : TActionInline;
begin
  Result := self;
  FRollback := Action;
end;

procedure TActionInline.Rollback;
begin
  if assigned(FRollback) then FRollback();
end;

{ TTree<T> }

procedure TTree<T>.AddRootNode(Node : T);
begin
  assert(FRootNode = nil);
  FRootNode := Node;
  FRootNode.FChilds.OwnsObjects := FOwnObjects;
end;

constructor TTree<T>.Create(OwnObjects : boolean);
begin
  FOwnObjects := OwnObjects;
end;

destructor TTree<T>.Destroy;
begin
  RemoveRootNode;
  inherited;
end;

procedure TTree<T>.RemoveRootNode;
begin
  if FOwnObjects then FRootNode.Free;
  FRootNode := nil;
end;

{ TTreeNode }

function TTreeNode.AddChild(Child : TTreeNode) : Integer;
begin
  Result := FChilds.Add(Child);
  // setup added child
  Child.FParent := self;
  Child.FChilds.OwnsObjects := FChilds.OwnsObjects;
end;

procedure TTreeNode.ClearChilds;
begin
  FChilds.Clear;
end;

constructor TTreeNode.Create();
begin
  FChilds := TObjectList<TTreeNode>.Create;
end;

procedure TTreeNode.DeleteChild(Index : Integer);
begin
  FChilds.Delete(index);
end;

function TTreeNode.Depth : Integer;
begin
  if not assigned(FParent) then Result := 1
  else Result := 1 + FParent.Depth;
end;

destructor TTreeNode.Destroy;
begin
  FChilds.Free;
  inherited;
end;

function TTreeNode.GetChildCount : Integer;
begin
  Result := FChilds.Count;
end;

function TTreeNode.IsRootNode : boolean;
begin
  Result := not assigned(FParent);
end;

procedure TTreeNode.RemoveChild(Child : TTreeNode);
begin
  FChilds.Remove(Child)
end;

{ TTreeNode<T> }

function TTreeNode<T>.GetChild(Index : Integer) : T;
begin
  assert((index >= 0) and (index < FChilds.Count));
  Result := T(FChilds[index]);
end;

function TTreeNode<T>.GetParent : T;
begin
  Result := T(FParent);
end;

procedure TTreeNode<T>.SetChild(Index : Integer; const Value : T);
begin
  assert((index >= 0) and (index < FChilds.Count));
  FChilds[index] := TTreeNode(Value);
end;

{ TTreeNodeWithValue<T> }

constructor TTreeNodeWithValue<T>.Create(const Value : T);
begin
  inherited Create;
  self.Value := Value;
end;

function TTreeNodeWithValue<T>.GetChild(Index : Integer) : TTreeNodeWithValue<T>;
begin
  assert((index >= 0) and (index < FChilds.Count));
  Result := TTreeNodeWithValue<T>(FChilds[index]);
end;

function TTreeNodeWithValue<T>.GetNodeByValue(const Value : T; Comparer : FuncGenericCompare<T>) : TTreeNodeWithValue<T>;
var
  i : Integer;
begin
  if assigned(Comparer) then
  begin
    if Comparer(FValue, Value) then exit(self);
  end
  else if TEqualityComparer<T>.Default.Equals(FValue, Value) then exit(self);

  for i := 0 to FChilds.Count - 1 do
  begin
    Result := Children[i].GetNodeByValue(Value, Comparer);
    if assigned(Result) then exit;
  end;
end;

function TTreeNodeWithValue<T>.GetParentNode : TTreeNodeWithValue<T>;
begin
  Result := TTreeNodeWithValue<T>(FParent);
end;

function TTreeNodeWithValue<T>.GetValue : T;
begin
  Result := FValue;
end;

procedure TTreeNodeWithValue<T>.SetChild(Index : Integer; const Value : TTreeNodeWithValue<T>);
begin
  assert((index >= 0) and (index < FChilds.Count));
  FChilds[index] := TTreeNode(Value);
end;

procedure TTreeNodeWithValue<T>.SetValue(const Value : T);
begin
  FValue := Value;
end;

{ TPaginator<T> }

constructor TPaginator<T>.Create(Objects : TList<T>; PageSize : Integer; OwnsObjects : boolean = False);
begin
  FObjects := Objects;
  FPageSize := PageSize;
  FCurrentPage := 0;
  FOwnsObjects := OwnsObjects;
  FCurrentObjects := TList<T>.Create;
end;

function TPaginator<T>.CurrentObjects : TList<T>;
var
  i : Integer;
begin
  FCurrentObjects.Clear;
  for i := PageMinIndex to PageMaxIndex do
      FCurrentObjects.Add(Objects[i]);
  Result := FCurrentObjects;
end;

destructor TPaginator<T>.Destroy;
begin
  FCurrentObjects.Free;
  if OwnsObjects then FObjects.Free;
  inherited;
end;

function TPaginator<T>.HasNext : boolean;
begin
  Result := CurrentPage < PageCount - 1;
end;

function TPaginator<T>.HasPrevious : boolean;
begin
  Result := CurrentPage > 0;
end;

function TPaginator<T>.InRange(Index : Integer) : boolean;
begin
  Result := (index >= PageMinIndex) and (index <= PageMaxIndex);
end;

function TPaginator<T>.IsObjectVisible(Obj : T) : boolean;
var
  i : Integer;
begin
  Result := False;
  for i := PageMinIndex to PageMaxIndex do
    if FObjects[i] = Obj then exit(True);
end;

procedure TPaginator<T>.Next;
begin
  CurrentPage := FCurrentPage + 1;
end;

function TPaginator<T>.PageCount : Integer;
begin
  Result := FObjects.Count div FPageSize;
  if FObjects.Count mod FPageSize <> 0 then Result := Result + 1;
end;

function TPaginator<T>.PageMaxIndex : Integer;
begin
  if FObjects.Count <= 0 then Result := -2
  else Result := HMath.Clamp(((FCurrentPage + 1) * FPageSize) - 1, 0, FObjects.Count - 1);
end;

function TPaginator<T>.PageMinIndex : Integer;
begin
  if FObjects.Count <= 0 then Result := -1
  else Result := HMath.Clamp(FCurrentPage * FPageSize, 0, FObjects.Count - 1);
end;

function TPaginator<T>.PageOfIndex(Index : Integer) : Integer;
begin
  if index <= 0 then Result := 0
  else if index >= PageCount * PageSize then Result := PageCount - 1
  else Result := index div PageSize;
end;

function TPaginator<T>.PageOfObject(Obj : T) : Integer;
var
  i : Integer;
begin
  for i := 0 to Objects.Count - 1 do
    if Objects[i] = Obj then
        exit(i);
  Result := 0;
end;

procedure TPaginator<T>.Previous;
begin
  CurrentPage := FCurrentPage - 1;
end;

procedure TPaginator<T>.SetCurrentPage(const Value : Integer);
begin
  FCurrentPage := HMath.Clamp(Value, 0, PageCount - 1);
  if assigned(FOnChange) then FOnChange();
end;

procedure TPaginator<T>.SetObjects(const Value : TList<T>);
begin
  if OwnsObjects then FObjects.Free;
  FObjects := Value;
  CurrentPage := 0;
end;

procedure TPaginator<T>.SetPageSize(const Value : Integer);
var
  FirstPageItem : Integer;
begin
  FirstPageItem := PageMinIndex;
  FPageSize := Value;
  CurrentPage := PageOfIndex(FirstPageItem);
end;

procedure TPaginator<T>.Update;
var
  LastPage : Integer;
begin
  LastPage := CurrentPage;
  if not OwnsObjects then
      self.Objects := Objects;
  CurrentPage := LastPage;
end;

{ TCaseInsensitiveDictionary<T> }

constructor TCaseInsensitiveDictionary<T>.Create;
begin
  inherited Create(TEqualityComparer<string>.Construct(
    function(const left, right : string) : boolean
    begin
      Result := SameText(left, right);
    end,
    function(const Value : string) : Integer
    begin
      Result := THashBobJenkins.GetHashValue(Value.ToLowerInvariant);
    end
    ));
end;

constructor TCaseInsensitiveDictionary<T>.Create(const Collection : TEnumerable<TStringPair>);
var
  Item : TPair<string, T>;
begin
  Create();
  for Item in Collection do
      AddOrSetValue(Item.Key, Item.Value);
end;

{ TAdvancedList<T> }

function TAdvancedList<T>.Each(Method : ProcItemMethod<T>) : TAdvancedList<T>;
var
  i : Integer;
begin
  for i := 0 to self.Count - 1 do
      Method(Items[i]);
  Result := self;
end;

function TAdvancedList<T>.Each(Method : ProcItemWithIndexMethod<T>) : TAdvancedList<T>;
var
  i : Integer;
begin
  for i := 0 to self.Count - 1 do
      Method(i, Items[i]);
  Result := self;
end;

function TAdvancedList<T>.Exists(Method : FuncItemFilterMethod<T>) : boolean;
var
  i : Integer;
begin
  Result := False;
  for i := 0 to self.Count - 1 do
    if Method(Items[i]) then
        exit(True);
end;

function TAdvancedList<T>.Filter(Method : FuncItemFilterMethod<T>) : TAdvancedList<T>;
var
  i : Integer;
begin
  Result := TAdvancedList<T>.Create;
  for i := 0 to self.Count - 1 do
    if Method(Items[i]) then Result.Add(Items[i]);
end;

function TAdvancedList<T>.FilterFirst(Method : FuncItemFilterMethod<T>) : T;
var
  i : Integer;
begin
  for i := 0 to self.Count - 1 do
    if Method(Items[i]) then
        exit(Items[i]);
  raise ENotFoundException.Create('TAdvancedList<T>.FilterFirst: Item not found.');
end;

function TAdvancedList<T>.Fold<U>(MappingMethod : FuncItemMapMethod<T, U>; AnOperator : FuncItemFoldOperator<U>) : U;
var
  i : Integer;
begin
  if Count <= 0 then exit(default (U));
  Result := MappingMethod(First);
  for i := 1 to Count - 1 do
      Result := AnOperator(Result, MappingMethod(Items[i]));
end;

function TAdvancedList<T>.InRange(Index : Integer) : boolean;
begin
  Result := (index >= 0) and (index < Count);
end;

function TAdvancedList<T>.Map<U>(MappingMethod : FuncItemMapMethod<T, U>) : TAdvancedList<U>;
var
  i : Integer;
begin
  if Count <= 0 then exit(nil);
  Result := TAdvancedList<U>.Create;
  for i := 0 to Count - 1 do
      Result.Add(MappingMethod(Items[i]));
end;

function TAdvancedList<T>.Max<U>(MappingMethod : FuncItemMapMethod<T, U>; Maximizer : FuncMaximumMethod<U>) : T;
var
  i, maxI : Integer;
  currentMax : U;
begin
  if Count <= 0 then exit(default (T));
  maxI := 0;
  currentMax := MappingMethod(First);
  for i := 1 to Count - 1 do
    if Maximizer(currentMax, MappingMethod(Items[i])) > 0 then
    begin
      maxI := i;
      currentMax := MappingMethod(Items[i]);
    end;
  Result := Items[maxI];
end;

function TAdvancedList<T>.Min(MappingMethod : FuncItemMapMethod<T, Single>) : T;
begin
  if Count <= 0 then exit(default (T));
  Result := Items[MinIndex(MappingMethod)];
end;

function TAdvancedList<T>.MinIndex(MappingMethod : FuncItemMapMethod<T, Single>) : Integer;
var
  i, minI : Integer;
  currentMin : Single;
begin
  if Count <= 0 then exit(-1);
  minI := 0;
  currentMin := MappingMethod(First);
  for i := 1 to Count - 1 do
    if currentMin > MappingMethod(Items[i]) then
    begin
      minI := i;
      currentMin := MappingMethod(Items[i]);
    end;
  Result := minI;
end;

procedure TAdvancedList<T>.Pop;
begin
  if Count > 0 then Delete(Count - 1);
end;

function TAdvancedList<T>.PopExtract : T;
begin
  Result := default (T);
  if Count > 0 then
      Result := Extract(Last);
end;

function TAdvancedList<T>.TryIndexOf(const Value : T; out Index : Integer) : boolean;
var
  i : Integer;
  lComparer : IEqualityComparer<T>;
begin
  lComparer := TEqualityComparer<T>.Default;
  Result := False;
  for i := 0 to Count - 1 do
    if lComparer.Equals(Items[i], Value) then
    begin
      index := i;
      exit(True);
    end;
end;

function TAdvancedList<T>.Random : T;
begin
  Result := self.Items[System.Random(Count)];
end;

function TAdvancedList<T>.RandomExtract : T;
var
  pick : Integer;
begin
  if Count <= 0 then exit(default (T));
  pick := System.Random(Count);
  Result := self.Items[pick];
  Delete(pick);
end;

function TAdvancedList<T>.Slice(FromIndex, ToIndex : Integer) : TArray<T>;
var
  i : Integer;
begin
  if FromIndex < 0 then FromIndex := FromIndex + self.Count;
  if ToIndex < 0 then ToIndex := ToIndex + self.Count;
  if (FromIndex >= self.Count) then exit(nil);
  if (ToIndex >= self.Count) then ToIndex := self.Count - 1;
  SetLength(Result, ToIndex - FromIndex + 1);
  for i := FromIndex to ToIndex do Result[i - FromIndex] := self[i];
end;

procedure TAdvancedList<T>.Swap(const i, j : Integer);
var
  temp : T;
begin
  if not(InRange(i) and InRange(j)) then exit;
  temp := Items[i];
  Items[i] := Items[j];
  Items[j] := temp;
end;

function TAdvancedList<T>.IsEmpty : boolean;
begin
  Result := Count = 0;
end;

function TAdvancedList<T>.IsValidIndex(Index : Integer) : boolean;
begin
  Result := (index >= 0) and (index < Count);
end;

function TAdvancedList<T>.FilterFirstIndex(Method : FuncItemFilterMethod<T>) : Integer;
var
  i : Integer;
begin
  Result := -1;
  for i := 0 to self.Count - 1 do
    if Method(Items[i]) then
        exit(i);
end;

function TAdvancedList<T>.All(Method : FuncItemFilterMethod<T>) : boolean;
var
  i : Integer;
begin
  for i := 0 to self.Count - 1 do
    if not Method(Items[i]) then exit(False);
  Result := True;
end;

function TAdvancedList<T>.Any(Method : FuncItemFilterMethod<T>) : boolean;
var
  i : Integer;
begin
  for i := 0 to self.Count - 1 do
    if Method(Items[i]) then exit(True);
  Result := False;
end;

function TAdvancedList<T>.Clone : TList<T>;
begin
  assert(self is TList<T>, 'TAdvancedList<T>.Clone: Clone works only for plain lists!');
  Result := TList<T>.Create;
  Result.AddRange(self.ToArray);
end;

function TAdvancedList<T>.CountFiltered(Method : FuncItemFilterMethod<T>) : Integer;
var
  i : Integer;
begin
  Result := 0;
  for i := 0 to self.Count - 1 do
    if Method(Items[i]) then inc(Result);
end;

function TAdvancedList<T>.DeleteFilter(Method : FuncItemFilterMethod<T>) : TAdvancedList<T>;
var
  i : Integer;
begin
  for i := self.Count - 1 downto 0 do
    if not Method(Items[i]) then self.Delete(i);
  Result := self;
end;

function TAdvancedList<T>.DeleteFirst(Method : FuncItemFilterMethod<T>) : TAdvancedList<T>;
var
  i : Integer;
begin
  for i := 0 to self.Count - 1 do
  begin
    if Method(Items[i]) then self.Delete(i);
  end;
  Result := self;
end;

{ TAdvancedObjectList<T> }

function TAdvancedObjectList<T>.EachSave(Method : ProcItemMethod<T>) : TAdvancedObjectList<T>;
var
  i : Integer;
begin
  for i := 0 to self.Count - 1 do
    if Items[i] <> nil then Method(Items[i]);
  Result := self;
end;

function TAdvancedObjectList<T>.FilterFirstSave(Method : FuncItemFilterMethod<T>) : T;
var
  i : Integer;
begin
  Result := nil;
  for i := 0 to self.Count - 1 do
    if Method(Items[i]) then
        exit(Items[i]);
end;

function TAdvancedObjectList<T>.FirstSave : T;
begin
  if Count > 0 then Result := First
  else Result := nil;
end;

{ TUltimateList<T> }

procedure TUltimateList<T>.AddRange(const Values : array of T);
var
  Index : Integer;
begin
  index := Count;
  BlockNotify := True;
  inherited AddRange(Values);
  BlockNotify := False;
  NotifyChange(HArray.ConvertDynamicToTArray<T>(Values), laAddRange, [index]);
end;

procedure TUltimateList<T>.AddRange(const Collection : IEnumerable<T>);
begin
  AddRange(HArray.ConvertEnumerableToArray<T>(Collection));
end;

function TUltimateList<T>.Add(const Value : T) : Integer;
begin
  BlockNotify := True;
  Result := inherited Add(Value);
  BlockNotify := False;
  NotifyChange([Value], laAdd, [Result]);
end;

procedure TUltimateList<T>.AddRange(const Collection : TEnumerable<T>);
begin
  AddRange(Collection.ToArray);
end;

procedure TUltimateList<T>.Clear;
var
  Items : TArray<T>;
begin
  // need to block, because else for every item a removed event will called
  BlockNotify := True;
  Items := self.ToArray;
  inherited Clear;
  BlockNotify := False;
  NotifyChange(Items, laClear, []);
end;

function TUltimateList<T>.Clone : TUltimateList<T>;
begin
  Result := TUltimateList<T>.Create;
  Result.AddRange(self);
end;

procedure TUltimateList<T>.Delete(Index : Integer);
var
  Value : T;
begin
  BlockNotify := True;
  Value := Items[index];
  inherited Delete(index);
  BlockNotify := False;
  NotifyChange([Value], laRemoved, [index]);
end;

procedure TUltimateList<T>.DeleteRange(AIndex, ACount : Integer);
begin
  raise ENotImplemented.Create('TUltimateList<T>.DeleteRange: Implement when used.');
end;

destructor TUltimateList<T>.Destroy;
begin
  FOnChange := nil;
  BlockNotify := True;
  inherited;
end;

function TUltimateList<T>.Extra : TAdvancedList<T>;
begin
  Result := TAdvancedList<T>(self);
end;

function TUltimateList<T>.Extract(const Value : T) : T;
var
  Index : Integer;
begin
  BlockNotify := True;
  index := IndexOf(Value);
  Result := inherited Extract(Value);
  BlockNotify := False;
  if index >= 0 then
      NotifyChange([Value], laExtracted, [index]);
end;

function TUltimateList<T>.ExtractRange(const Values : array of T) : TArray<T>;
var
  i, Index : Integer;
  Indices : TArray<Integer>;
begin
  BlockNotify := True;
  for i := 0 to length(Values) - 1 do
  begin
    index := IndexOf(Values[i]);
    if index >= 0 then
    begin
      SetLength(Result, length(Result) + 1);
      SetLength(Indices, length(Indices) + 1);
      Result[high(Result)] := inherited Extract(Values[i]);
      Indices[high(Indices)] := index;
    end;
  end;
  BlockNotify := False;
  if length(Indices) > 0 then
      NotifyChange(Result, laExtractedRange, Indices);
end;

procedure TUltimateList<T>.FakeClear;
begin
  NotifyChange([], laClear, []);
end;

procedure TUltimateList<T>.FakeCompleteAdd;
begin
  NotifyChange(ToArray, laAddRange, [0]);
end;

procedure TUltimateList<T>.FakeCompleteChanged;
var
  i : Integer;
begin
  for i := 0 to Count - 1 do
      NotifyChange([Items[i]], laChanged, [i]);
end;

function TUltimateList<T>.GetItem(Index : Integer) : T;
begin
  Result := inherited Items[index];
end;

procedure TUltimateList<T>.Insert(Index : Integer; const Value : T);
begin
  BlockNotify := True;
  inherited Insert(index, Value);
  BlockNotify := False;
  NotifyChange([Value], laAdd, [index]);
end;

procedure TUltimateList<T>.InsertRange(Index : Integer; const Values : array of T);
begin
  BlockNotify := True;
  inherited InsertRange(index, Values);
  BlockNotify := False;
  NotifyChange(HArray.ConvertDynamicToTArray<T>(Values), laAddRange, [index]);
end;

procedure TUltimateList<T>.InsertRange(Index : Integer; const Collection : IEnumerable<T>);
begin
  InsertRange(index, HArray.ConvertEnumerableToArray<T>(Collection));
end;

procedure TUltimateList<T>.InsertRange(Index : Integer; const Collection : TEnumerable<T>);
begin
  InsertRange(index, Collection.ToArray);
end;

function TUltimateList<T>.IsEmpty : boolean;
begin
  Result := Count <= 0;
end;

procedure TUltimateList<T>.Notify(const Item : T; Action : TCollectionNotification);
begin
  inherited;
  if not BlockNotify then
      raise EListError.Create('TUltimateList<T>.Notify: Legacy notification system, should never called.');
end;

procedure TUltimateList<T>.NotifyChange(const Items : TArray<T>; Action : EnumListAction; Indices : TArray<Integer>);
begin
  if assigned(FOnChange) then
  begin
    DoSynchronized(
      procedure()
      begin
        FOnChange(self, Items, Action, Indices)
      end);
  end;
end;

function TUltimateList<T>.Query : IDataQuery<T>;
begin
  Result := TDelphiDataQuery<T>.Create(self);
end;

function TUltimateList<T>.Remove(const Value : T) : Integer;
begin
  BlockNotify := True;
  Result := inherited Remove(Value);
  BlockNotify := False;
  if Result >= 0 then
      NotifyChange([Value], laRemoved, [Result]);
end;

procedure TUltimateList<T>.SetItem(Index : Integer; const Value : T);
var
  OldValue : T;
begin
  BlockNotify := True;
  OldValue := Items[index];
  inherited Items[index] := Value;
  BlockNotify := False;
  NotifyChange([OldValue], laRemoved, [index]);
  NotifyChange([Value], laAdd, [index]);
end;

procedure TUltimateList<T>.Shuffle;
var
  i : Integer;
begin
  for i := Count - 1 downto 0 do
      Exchange(i, Random(i));
end;

procedure TUltimateList<T>.SignalItemChanged(Item : T; SuppressError : boolean);
var
  Index : Integer;
begin
  index := IndexOf(Item);
  if index >= 0 then
  begin
    NotifyChange([Item], laChanged, [index]);
  end
  else if not SuppressError then raise EListError.Create('TUltimateList<T>.SignalItemChanged: Item not in the list.');
end;

{ TUltimateObjectList<T> }

constructor TUltimateObjectList<T>.Create;
begin
  FOwnsObjects := True;
  inherited Create;
end;

constructor TUltimateObjectList<T>.Create(const AComparer : IComparer<T>);
begin
  FOwnsObjects := True;
  inherited Create(AComparer);
end;

constructor TUltimateObjectList<T>.Create(const Collection : TEnumerable<T>);
begin
  FOwnsObjects := True;
  inherited Create(Collection);
end;

destructor TUltimateObjectList<T>.Destroy;
begin
  FOnChange := nil;
  BlockNotify := True;
  Clear;
  inherited;
end;

function TUltimateObjectList<T>.Extra : TAdvancedObjectList<T>;
begin
  Result := TAdvancedObjectList<T>(self);
end;

function TUltimateObjectList<T>.FirstSave : T;
begin
  if Count <= 0 then Result := nil
  else Result := Items[0];
end;

procedure TUltimateObjectList<T>.NotifyChange(const Items : TArray<T>; Action : EnumListAction; Indices : TArray<Integer>);
var
  i : Integer;
begin
  inherited;
  if Action in [laRemoved, laClear] then
  begin
    if OwnsObjects then
    begin
      for i := 0 to length(Items) - 1 do
          Items[i].DisposeOf;
    end;
  end;
end;

{ HFoldOperators }

class function HFoldOperators.AddInteger(const a, b : Integer) : Integer;
begin
  Result := a + b;
end;

{ TCaseInsensitiveObjectDictionary<T> }

constructor TCaseInsensitiveObjectDictionary<T>.Create(
  Ownerships : TDictionaryOwnerships);
begin
  inherited Create(Ownerships, TEqualityComparer<string>.Construct(
    function(const left, right : string) : boolean
    begin
      Result := SameText(left, right);
    end,
    function(const Value : string) : Integer
    begin
      Result := THashBobJenkins.GetHashValue(Value.ToLowerInvariant);
    end
    ));
end;

constructor TCaseInsensitiveObjectDictionary<T>.Create(Ownerships : TDictionaryOwnerships;
const Collection : TEnumerable<TStringPair>);
var
  Item : TStringPair;
begin
  Create(Ownerships);
  for Item in Collection do
      AddOrSetValue(Item.Key, Item.Value);
end;

{ TPriorityQueue<T> }

function TPriorityQueue<T>.Compare(const a, b : Single) : Integer;
begin
  Result := CompareValue(a, b);
end;

{ TIntPriorityQueue<T> }

function TIntPriorityQueue<T>.Compare(const a, b : Int64) : Integer;
begin
  Result := CompareValue(a, b);
end;

{ TLoopSafeObjectList<T>.TListActionAdd }

constructor TLoopSafeObjectList<T>.TListActionAdd.Create(List : TObjectList<T>; const Item : T);
begin
  FList := List;
  FItem := Item;
end;

procedure TLoopSafeObjectList<T>.TListActionAdd.DoAction;
begin
  List.Add(Item);
end;

{ TLoopSafeObjectList<T> }

procedure TLoopSafeObjectList<T>.Add(const Value : T);
begin
  if not assigned(Value) then
      raise ENotSupportedException.Create('TLoopSafeObjectList<T>.Add: Value "nil" is not supported as list item value!')
  else
  begin
    if FSaveLoopCounter <= 0 then
        FList.Add(Value)
    else
        FPendingActions.Add(TListActionAdd.Create(FList, Value));
  end;
end;

procedure TLoopSafeObjectList<T>.ApplyPendingActions;
var
  i : Integer;
  Action : TListActionAdd;
begin
  assert(FSaveLoopCounter = 0);
  // cleanup, all deleted items are marked as nil
  for i := FList.Count - 1 downto 0 do
    if not assigned(FList[i]) then
        FList.Delete(i);

  for Action in FPendingActions do
      Action.DoAction;
  FPendingActions.Clear;
end;

function TLoopSafeObjectList<T>.Count : Integer;
begin
  Result := FList.Count;
end;

constructor TLoopSafeObjectList<T>.Create;
begin
  FPendingActions := TObjectList<TListActionAdd>.Create;
  FList := TObjectList<T>.Create;
end;

destructor TLoopSafeObjectList<T>.Destroy;
begin
  assert((FSaveLoopCounter = 0) and (FPendingActions.Count <= 0));
  FPendingActions.Free;
  FList.Free;
  inherited;
end;

procedure TLoopSafeObjectList<T>.EnterSafeLoop;
begin
  inc(FSaveLoopCounter);
end;

function TLoopSafeObjectList<T>.GetEnumerator : TEnumerator<T>;
begin
  assert(FSaveLoopCounter >= 1, 'Call EnterSaveLoop before iterate over list.');
  Result := FList.GetEnumerator;
end;

function TLoopSafeObjectList<T>.GetOwnsObjects : boolean;
begin
  Result := FList.OwnsObjects;
end;

procedure TLoopSafeObjectList<T>.LeaveSafeLoop;
begin
  if FSaveLoopCounter > 0 then
  begin
    dec(FSaveLoopCounter);
    // as EnterSaveLoop can be multiple called, wait until loop was really leaved until apply pending actions
    if FSaveLoopCounter = 0 then
        ApplyPendingActions;
  end;
end;

function TLoopSafeObjectList<T>.Remove(const Value : T) : Integer;
var
  Index : Integer;
  i : Integer;
begin
  if FSaveLoopCounter <= 0 then
      Result := FList.Remove(Value)
  else
  begin
    Result := FList.IndexOf(Value);
    if Result >= 0 then
    begin
      // this will also free object if owns object
      FList.Items[Result] := nil;
    end
    else
    // also possible that value is in pending action
    begin
      Result := -1;
      for i := FPendingActions.Count - 1 downto 0 do
        if FPendingActions[i].Item = Value then
        begin
          FPendingActions[i].Item.Free;
          FPendingActions.Delete(i);
          Result := i;
          break;
        end;
    end;
  end;
  // for debug reason throw exception if not found
  if Result = -1 then
      raise ENotFoundException.Create('TLoopSafeObjectList<T>.Remove: Item not found');
end;

procedure TLoopSafeObjectList<T>.SetOwnsObjects(const Value : boolean);
begin
  FList.OwnsObjects := Value;
end;

{ TObjectRingBuffer<T> }

constructor TObjectRingBuffer<T>.Create(Size : Integer; OwnsObjects : boolean);
begin
  FOwnsObjects := OwnsObjects;
  inherited Create(Size);
end;

destructor TObjectRingBuffer<T>.Destroy;
var
  i : Integer;
begin
  if OwnsObjects then
  begin
    for i := 0 to length(FRingBuffer) - 1 do
        FRingBuffer[i].Value.Free;
  end;
  inherited;
end;

procedure TObjectRingBuffer<T>.SetItem(Index : Integer; const Value : T);
var
  cellIndex : Integer;
begin
  if OwnsObjects then
  begin
    cellIndex := GetCellIndex(index);
    if assigned(FRingBuffer[cellIndex].Value) and (FRingBuffer[cellIndex].Value <> Value) then
        FRingBuffer[cellIndex].Value.Free;
  end;
  inherited SetItem(index, Value);
end;

{ TPermutator<T> }

function TPermutator<T>.AddFixedValue(ValueGroup : array of T) : TPermutator<T>;
begin
  Result := self;
  FFixedValues.AddRange(ValueGroup);
end;

function TPermutator<T>.AddValue(ValueGroup : array of T) : TPermutator<T>;
var
  ValueGroupList : TList<T>;
begin
  Result := self;
  ValueGroupList := TList<T>.Create;
  ValueGroupList.AddRange(ValueGroup);
  FValues.Add(ValueGroupList);
end;

function TPermutator<T>.AddValues(Values : array of TArray<T>) : TPermutator<T>;
var
  i : Integer;
begin
  Result := self;
  for i := 0 to length(Values) - 1 do
      AddValue(Values[i]);
end;

function TPermutator<T>.Count : Integer;
begin
  if FIterateInsteadOfPermutate then
      Result := FValues.Count
  else
      Result := 1 shl FValues.Count;
end;

constructor TPermutator<T>.Create;
begin
  FFixedValues := TList<T>.Create;
  FValues := TObjectList < TList < T >>.Create;
end;

destructor TPermutator<T>.Destroy;
begin
  FFixedValues.Free;
  FValues.Free;
  inherited;
end;

function TPermutator<T>.GetPermutation(Index : Integer) : TArray<T>;
var
  i : Integer;
begin
  Result := FFixedValues.ToArray;
  if FIterateInsteadOfPermutate then
      Result := Result + FValues[index].ToArray
  else
    for i := 0 to FValues.Count - 1 do
      if ((1 shl i) and index) <> 0 then
          Result := Result + FValues[i].ToArray;
end;

function TPermutator<T>.IterateInsteadOfPermutate : TPermutator<T>;
begin
  Result := self;
  FIterateInsteadOfPermutate := True;
end;

function TPermutator<T>.Permutate(Callback : ProcPermutation<T>) : TPermutator<T>;
var
  i : Integer;
begin
  Result := self;
  for i := 0 to self.Count - 1 do
      Callback(GetPermutation(i));
end;

{ TGroupPermutator<T> }

function TGroupPermutator<T>.AddFixedValue(ValueGroup : array of T) : TGroupPermutator<T>;
begin
  Result := self;
  FFixedValues.AddRange(ValueGroup);
end;

function TGroupPermutator<T>.AddPermutator(Permutator : TPermutator<T>) : TGroupPermutator<T>;
begin
  Result := self;
  FPermutators.Add(Permutator);
end;

function TGroupPermutator<T>.Count : Integer;
var
  i : Integer;
begin
  Result := 0;
  for i := 0 to FPermutators.Count - 1 do
    if i = 0 then
        Result := FPermutators[i].Count
    else
        Result := Result * FPermutators[i].Count;
end;

constructor TGroupPermutator<T>.Create(OwnsPermutators : boolean);
begin
  FFixedValues := TList<T>.Create;
  FPermutators := TObjectList < TPermutator < T >>.Create(OwnsPermutators);
end;

destructor TGroupPermutator<T>.Destroy;
begin
  FFixedValues.Free;
  FPermutators.Free;
  inherited;
end;

function TGroupPermutator<T>.Permutate(Callback : ProcPermutation<T>) : TGroupPermutator<T>;
begin
  if FPermutators.Count > 0 then
      PermutateRecursive(0, FFixedValues.ToArray, Callback)
  else
      Callback(FFixedValues.ToArray);
end;

procedure TGroupPermutator<T>.PermutateRecursive(PermutatorIndex : Integer; Values : TArray<T>; Callback : ProcPermutation<T>);
var
  i : Integer;
begin
  if PermutatorIndex < FPermutators.Count then
  begin
    for i := 0 to FPermutators[PermutatorIndex].Count - 1 do
        PermutateRecursive(PermutatorIndex + 1, Values + FPermutators[PermutatorIndex].GetPermutation(i), Callback);
  end
  else
      Callback(Values);
end;

end.
