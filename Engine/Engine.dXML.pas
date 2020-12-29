unit Engine.dXML;

interface

uses
  // Delphi
  System.Rtti,
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.IOUtils,
  System.Hash,
  System.TypInfo,
  // 3rd Party
  Xml.VerySimple,
  // Engine
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Rtti,
  Engine.Expression,
  Engine.Log;

const

  /// //////////////////////////////////////////////////////////////////////////
  /// ////////////////////////////dXML - Dynamic XML ///////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// Dynamic Xml is based on the standard xml format but introduce some language
  /// features to dynamically change the xml format depending on a set context.
  /// The context can be set and modified at any time after document is loaded.
  /// Just at this moment (with some exceptions) any dynamic content is resolved.
  /// The context consists of a variable name (key) and a value:
  /// <key:String; value: TValue>
  ///
  ///
  /// dXML language reference
  /// =============
  ///
  /// Dynamic Value - {{ variable_name }}
  /// Example:
  /// <name>{{ instance.name }}</name>
  /// <name>Name: {{ instance.name }}</name>
  /// Description: Value of a node is dynamically loaded from a context variable
  /// and will be changing if the variable is changed. Dynamic value can also mixed
  /// with static value (this will convert the dynamic value to string).
  /// HINT: Value will Empty until variable is set in context.
  ///
  /// Conditonal content - dxml-if="condition" | [dmxl-else]
  /// Example:
  /// <caption class="cpt-xl" dxml-if="instance.show_caption">Hello World<caption dmxl-else>Empty World</caption></caption>
  /// Description: Will only show node value and all Children if condition is true.
  /// If an else part is declared (childnode with same nodename and the attribute dmxl-else)
  /// and the condition is false, instead value and Children from this node will be shown.
  /// HINT: If variable is not set in context, else block is used.
  ///
  /// For-Loop - dxml-for="instance in list" | [dxml-forempty="Empty"]
  /// Example:
  /// <stack dxml-for="instance in list">
  /// |  <item>{{ instance.name }}</item>
  /// </stack>
  /// Description: Creating childnode as copy of the template child for any item
  /// in list. Will also set the item instance variable with given name
  /// (in example instance) to any childnode.
  /// HINT: If list variable is not set, no node is created.
  ///
  /// Conditional Attribute - dxml-bind:attribute_name="value if condition [else value]"
  /// Example:
  /// <button class="btn" dxml-bind:class="btn-xl if instance.is_down else btn-sm">§gui_login_submit</LoginButton>

  DXML_PREFIX = 'dXML-';
  // controll tokens - will change the structure of the xml (add nodes) or
  // show nodes in dependence of conditions
  DXML_TOKEN_CONDITIONAL_CONTENT        = DXML_PREFIX + 'IF';
  DXML_TOKEN_CONDITIONAL_CONTENT_ELSEIF = DXML_PREFIX + 'ELIF';
  DXML_TOKEN_CONDITIONAL_CONTENT_ELSE   = DXML_PREFIX + 'ELSE';
  DXML_TOKEN_FORLOOP                    = DXML_PREFIX + 'FOR';
  DXML_TOKEN_FORLOOP_STATIC             = DXML_PREFIX + 'FOR:STATIC';
  DXML_TOKEN_INCLUDE                    = DXML_PREFIX + 'INCLUDE';
  DXML_TOKEN_CACHE_DATA                 = DXML_PREFIX + 'CACHE';
  // binding tokens
  DXML_TOKEN_ONEVENT = DXML_PREFIX + 'ON';
  DXML_TOKEN_WITH    = DXML_PREFIX + 'WITH';

type
  dXMLDependency = class(TCustomAttribute)
    strict private
      FDependencies : TArray<string>;
    public
      property Dependencies : TArray<string> read FDependencies;
      constructor Create(const Dependency : string); overload;
      constructor Create(const Dependency1, Dependency2 : string); overload;
      constructor Create(const Dependency1, Dependency2, Dependency3 : string); overload;
      constructor Create(const Dependency1, Dependency2, Dependency3, Dependency4 : string); overload;
  end;

  EdXMLParseError = class(Exception);

  EnumdXMLNodeType = (dnSimpleNode, dnIfNode, dnForLoopNode, dnIncludeNode);

  TdXMLAbstractXMLNode = class
    private
      FParent : TdXMLAbstractXMLNode;
      constructor Create(Parent : TdXMLAbstractXMLNode);
      /// <summary> Returns the rootnode of this xml document.</summary>
      function GetRootNode : TdXMLAbstractXMLNode;
    public
      property Parent : TdXMLAbstractXMLNode read FParent;
      class function CreateFromXMLNode(const XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode) : TdXMLAbstractXMLNode;
  end;

  TdXMLAbstractSimpleNode = class(TdXMLAbstractXMLNode)
    private
      FChildren : TObjectList<TdXMLAbstractXMLNode>;
      FName : string;
      FAttributes : TDictionary<string, string>;
      FText : string;
    public
      property name : string read FName;
      property Text : string read FText;
      property Attributes : TDictionary<string, string> read FAttributes;
      property Children : TObjectList<TdXMLAbstractXMLNode> read FChildren;
      constructor Create(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
      destructor Destroy; override;
  end;

  TdXMLAbstractIfNode = class(TdXMLAbstractXMLNode)
    private type
      TConditionalItem = class
        public
          /// <summary> Condition of node that is will be displayed, if condition is empty,
          /// node is the else statement and will used whenever nodes before not used.</summary>
          Condition : string;
          Node : TdXMLAbstractXMLNode;
          function IsElse : boolean;
          destructor Destroy; override;
      end;
    private
      FConditionalItems : TObjectList<TConditionalItem>;
      constructor Create(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
    public
      /// <summary> List of all conditional items, if the condition of the top list item is not used, try next, etc.
      /// until list is empty (then hide node) or a item with empty condition is found, this item has to used whenever reached
      /// (else)</summary>
      property ConditionalItems : TObjectList<TConditionalItem> read FConditionalItems;
      destructor Destroy; override;
  end;

  TdXMLAbstractForLoopNode = class(TdXMLAbstractXMLNode)
    private
      FInnerNode : TdXMLAbstractXMLNode;
      FItemVariableName : string;
      FListVariableName : string;
      FStaticBinding : boolean;
      FCacheData : boolean;
      constructor Create(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
    public
      /// <summary> Node that will duplicated for every item in for loop.</summary>
      property InnerNode : TdXMLAbstractXMLNode read FInnerNode;
      property ItemVariableName : string read FItemVariableName;
      property ListVariableName : string read FListVariableName;
      /// <summary> If True, XML loop will only read data from list, but not subscribe on changes on list.</summary>
      property StaticBinding : boolean read FStaticBinding;
      property CacheData : boolean read FCacheData;
      destructor Destroy; override;
  end;

  TdXMLAbstractIncludeNode = class(TdXMLAbstractXMLNode)
    private
      FInnerNode : TdXMLAbstractXMLNode;
      FSourceFileName : string;
      FWithRawValue : string;
      FAttributes : TDictionary<string, string>;
    public
      constructor CreateFromFile(const SourceFileName : string; Parent : TdXMLAbstractXMLNode);
      constructor CreateFromNode(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
      /// <summary> RootNode of the Included file.</summary>
      property InnerNode : TdXMLAbstractXMLNode read FInnerNode;
      property SourceFileName : string read FSourceFileName;
      property Attributes : TDictionary<string, string> read FAttributes;
      destructor Destroy; override;
  end;

  /// ==========================================================================

  ProcExpressionNeedReEvaluation = procedure(Expression : TExpression; Context : TExpressionContext) of object;

  /// <summary> Observer all variables and properties for changes and notfiy if an expression
  /// need to ReEvaluate because any circumstance has changed. </summary>
  TExpressionObserver = class
    private type
      TObserverNode = class abstract
        private
          FOwner : TExpressionObserver;
          FObservedPath : TArray<string>;
          FRawPath : string;
          FRttiContext : TRttiContext;
          FChildren : TObjectList<TObserverNode>;
          FIsPartOfDependency : boolean;
          /// <summary> Update Children by initiate observers. Will clear children before initiate observers.</summary>
          procedure UpdateChildren(Instance : TObject);
        public
          property ObservedPath : TArray<string> read FObservedPath;
          /// <summary> Update context for observernode and all childs of this node. Returns True, if
          /// context change influenced expression and therefore expression has to reevaluate.</summary>
          function ContextHasChanged(NewContext : TExpressionContext; const ChangedVariable : string) : boolean; virtual;
          constructor Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; IsPartOfDependency : boolean);
          destructor Destroy; override;
      end;

      /// <summary> Only observe expression context and  </summary>
      TExpressionContextObserverNode = class(TObserverNode)
        public
          function ContextHasChanged(NewContext : TExpressionContext; const ChangedVariable : string) : boolean; override;
          constructor Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; Context : TExpressionContext);
      end;

      /// <summary> General observer of an member, does not really observer this member, only start observing result of member.</summary>
      TMemberObserverNode = class(TObserverNode)
        public
          constructor Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; ParentInstance : TObject; AMember : TRttiMember; IsPartOfDependency : boolean);
      end;

      TObjectObserverNode = class(TObserverNode)
        public
          constructor Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; Instance : TObject);
      end;

      TPropertyObserverNode = class(TObserverNode)
        private
          FInstance : TObject;
          FPropertySetterMethod : TRttiMethod;
          FProperty : TRttiProperty;
          FPropertySetterObserver : TVirtualMethodInterceptorHandle;
          procedure BeforeSetProperty(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
          procedure AfterSetProperty(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; var Result : TValue);
        public
          constructor Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; ParentInstance : TObject; AProperty : TRttiProperty; IsPartOfDependency : boolean);
          destructor Destroy; override;
      end;

      TListObserverNode = class(TObserverNode)
        private
          FListInstance : TObject;
          FListObserver : TVirtualMethodInterceptorHandle;
          FItemsObserverMap : TDictionary<TObject, TObserverNode>;
          procedure BeforeListChangedHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
          procedure AfterListChangedHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; var Result : TValue);
          procedure UpdateItems(Items : TValue; Action : EnumListAction);
        public
          constructor Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; ParentInstance : TObject; IsPartOfDependency : boolean);
          destructor Destroy; override;
      end;
    private
      FExpression : TExpression;
      FObserverNodes : TObjectList<TObserverNode>;
      FContext : TExpressionContext;
      FOnExpressionNeedReEvaluation : ProcExpressionNeedReEvaluation;
      FDependencies : TCaseInsensitiveDictionary<boolean>;
      procedure CallExpressionNeedReEvaluate;
    public
      /// <summary> Notifies whenever any values or subvalues referenced by expression is changed.
      /// Also notifies if the circumstance is changed trough changed context.</summary>
      property OnExpressionNeedReEvaluation : ProcExpressionNeedReEvaluation read FOnExpressionNeedReEvaluation write FOnExpressionNeedReEvaluation;
      /// <summary> Signal that maybe the context for observed expression has changed.
      /// <param name="NewContext"> Newcontext containing the updated contextdata.</param>
      /// <param name="ChangedVariable"> Name of the changed variable in context. If ChangedVariable is empty,
      /// assume that complete context has changed.</summary>
      procedure ContextHasChanged(NewContext : TExpressionContext; const ChangedVariable : string);
      function DependsOnVariableName(const VariableName : string) : boolean;
      constructor Create(const Expression : TExpression);
      destructor Destroy; override;
  end;

  /// ==========================================================================

  TDynamicTextField = class
    private type
      TPart = class
        private
          FText : string;
          FOnTextChanged : ProcCallback;
        public
          property OnTextChanged : ProcCallback read FOnTextChanged write FOnTextChanged;
          property Text : string read FText;
          function Clone : TPart; virtual; abstract;
          procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string); virtual; abstract;
      end;

      TStaticPart = class(TPart)
        public
          constructor Create(const Value : string);
          function Clone : TPart; override;
          procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string); override;
      end;

      TDynamicPart = class(TPart)
        private
          FExpression : TExpression;
          FExpressionObserver : TExpressionObserver;
          FRawExpression : string;
          function GetString(Context : TExpressionContext) : string;
          procedure ObserverSignalHandler(Expression : TExpression; Context : TExpressionContext);
        public
          constructor Create(const Expression : string);
          function Clone : TPart; override;
          procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string); override;
          destructor Destroy; override;
      end;

      ProcTextFieldDataChanged = procedure(Sender : TDynamicTextField) of object;
    private
      FParts : TObjectList<TPart>;
      FIsDynamic : boolean;
      FStaticText : string;
      FOnTextChanged : ProcTextFieldDataChanged;
      function BuildText : string;
      procedure AddPart(Part : TPart);
      procedure PartTextHasChangedHandler;
    public
      property OnTextChanged : ProcTextFieldDataChanged read FOnTextChanged write FOnTextChanged;
      property Text : string read BuildText;
      /// <summary> True if dynamic textfield contains any dynamic part, else false.</summary>
      property IsDynamic : boolean read FIsDynamic;
      constructor Create(const Text : string); overload;
      constructor Create(); overload; virtual;
      procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
      function Clone : TDynamicTextField;

      destructor Destroy; override;
  end;

  CDynamicTextField = class of TDynamicTextField;

  TdXMLNode = class;

  ProcdXMLNodeNotify = procedure(const Sender : TdXMLNode) of object;

  TdXMLBaseNode = class
    strict private
      /// <summary> Callback for local context to get informed if any data was changed.</summary>
      procedure ContextDataChangedCallback(Sender : TObject; const Item : string; Action : TCollectionNotification);
    private
      FParent : TdXMLBaseNode;
      FIndex : Integer;
      FLocalContext : TExpressionContext;
      constructor Create(); overload;
      constructor Create(Parent : TdXMLBaseNode); overload;
      function Clone(Value : TdXMLBaseNode = nil) : TdXMLBaseNode; virtual;
      /// <summary> Called whenever the context has changed.
      /// <param name="ChangedVariable"> Name of Variable changed (added/removed or data simple changed) in context.
      /// If ChangedVariable is empty, complete context has changed.</param></summary>
      procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string); virtual;
      /// <summary> Returning the complete context for node, including data from all parents.</summary>
      function GetCurrentExpressionContext : TExpressionContext; virtual;
      function GetXML : TXmlNode; virtual;
      procedure SetParent(const Value : TdXMLBaseNode); virtual;
    private
      class function CreateNode(Parent : TdXMLBaseNode; Data : TdXMLAbstractXMLNode) : TdXMLBaseNode;
    public
      property Parent : TdXMLBaseNode read FParent write SetParent;
      property Context : TExpressionContext read FLocalContext;
      destructor Destroy; override;
  end;

  TdXMLNode = class(TdXMLBaseNode)
    private type
      TEventBinding = class
        Context : TExpressionContext;
        Expression : TExpression;
        RawExpression : string;
        DependantFields : TCaseInsensitiveDictionary<boolean>;
        constructor Create; overload;
        constructor Create(const Binding : string); overload;
        procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
        function Clone : TEventBinding;
        procedure Call(const Parameter : TValue);
        destructor Destroy; override;
      end;

      TDynamicAttribute = class(TDynamicTextField)
        private
          FName : string;
        public
          property name : string read FName;
          constructor Create(const Name, Text : string); overload;
          constructor Create(); override;
          function Clone : TDynamicTextField;
      end;

      ProcAliasValueHasChanged = procedure(ContextWithAlias : TExpressionContext; const Alias : string) of object;

      TAlias = class
        strict private
          FOriginalValue : TExpression;
          FObserver : TExpressionObserver;
          FAlias : string;
          FValue : TValue;
          FOnAliasValueHasChanged : ProcAliasValueHasChanged;
          procedure ObserverHandler(Expression : TExpression; Context : TExpressionContext);
        public
          property OnAliasValueChanged : ProcAliasValueHasChanged read FOnAliasValueHasChanged write FOnAliasValueHasChanged;
          property Value : TValue read FValue;
          property Alias : string read FAlias;
          function DependsOnVariable(const VariableName : string) : boolean;
          procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
          constructor Create(const Value : string);
          function Clone : TAlias;
          destructor Destroy; override;
      end;

    private
      FLogicalChildren : TUltimateObjectList<TdXMLBaseNode>;
      FChildren : TUltimateList<TdXMLNode>;
      FName : string;
      FOnNeedReload : ProcdXMLNodeNotify;
      FDynamicAttributes : TObjectList<TDynamicAttribute>;
      FAttributes : TDictionary<string, string>;
      FEventBindings : TObjectDictionary<string, TEventBinding>;
      FOnTextChanged : ProcdXMLNodeNotify;
      FDynamicText : TDynamicTextField;
      FAliases : TObjectList<TAlias>;
      constructor BaseCreate();
      constructor Create(); overload;
      constructor Create(Parent : TdXMLBaseNode; Data : TdXMLAbstractSimpleNode); overload;
      function Clone(Value : TdXMLBaseNode = nil) : TdXMLBaseNode; override;
      procedure LoadData(const Data : TdXMLAbstractSimpleNode);
      procedure TextChangedCallback(Sender : TDynamicTextField);
      procedure AttributeValueChangedCallback(Sender : TDynamicTextField);
      procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string); override;
      procedure AliasValueChanged(ContextWithAlias : TExpressionContext; const Alias : string);
      function GetXML : TXmlNode; override;
      function GetText : string;
      function GetCurrentExpressionContext : TExpressionContext; override;
      procedure LoadAttributes(const Attributes : TDictionary<string, string>);
    public
      /// <summary> Callback is called whenever the data of this node has completly changed and needed
      /// to reloaded. This also affects all Children and subChildren. Also the context needed to be set again.
      /// HINT: This callback will not called when only Children changed or the text (there are different callbacks).</summary>
      property OnNeedReload : ProcdXMLNodeNotify read FOnNeedReload write FOnNeedReload;
      /// <summary> Called whenever the text maybe changed. Can also be a false alarm because context changed, but has same content.</summary>
      property OnTextChanged : ProcdXMLNodeNotify read FOnTextChanged write FOnTextChanged;
      /// <summary> Nodename.</summary>
      property name : string read FName;
      /// <summary> Text of the node. The text will be dynamically changing, signaled by OnTextChanged.</summary>
      property Text : string read GetText;
      /// <summary> All attributes of this node, attributes can dynamically change, to get notified
      /// register on callback (OnKeyNotify or OnValueNotify) in Attributes.
      /// HINT: Access is case insensitive.</summary>
      property Attributes : TDictionary<string, string> read FAttributes;
      /// <summary> All childnodes of this node, children can dynamically change, to get notified
      /// register on callback (OnChange) in Children.</summary>
      property Children : TUltimateList<TdXMLNode> read FChildren;
      /// <summary> Call binded method if binding exists, else nothing happens.
      /// Parameter will only passed to binded method if it accept a parameter.
      /// WARNING: There will no parameter type tests made, so if parameter not castable to method parameter type
      /// an exception will raised.</summary>
      procedure CallEvent(const EventName : string; const Parameter : TValue); overload;
      procedure CallEvent(const EventName : string); overload;
      destructor Destroy; override;
  end;

  TdXMLIncludeNode = class(TdXMLNode)
    private
      FDynamicFileName : TDynamicTextField;
      FFileName : string;
      FWithValue : string;
      // additional attributes set on included node
      FAdditionalAttributes : TDictionary<string, string>;
      constructor Create(); overload;
      constructor Create(Parent : TdXMLBaseNode; const FileNameExpression : string); overload;
      constructor Create(Parent : TdXMLBaseNode; Node : TdXMLAbstractIncludeNode); overload;
      function Clone(Value : TdXMLBaseNode = nil) : TdXMLBaseNode; override;
      procedure SourceFileChangedCallback(const Filepath : string; const FileContent : string);
      procedure SetSourceFileName(const Value : string);
      procedure FileNameChangedCallback(Sender : TDynamicTextField);
      procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string); override;
    public
      property SourceFileName : string read FFileName write SetSourceFileName;
      procedure Reload;
      destructor Destroy; override;
  end;

  TdXMLForLoopNode = class(TdXMLBaseNode)
    private
      FPattern : TdXMLBaseNode;
      FItemVariableName : string;
      FListExpression : TExpression;
      FListExpressionObserver : TExpressionObserver;
      FStaticBinding : boolean;
      FListInstance : TObject;
      FParentChildList : TUltimateList<TdXMLNode>;
      /// <summary> Copy of the observed list to identifiy the index of a missing or added item.</summary>
      FListCopy : TList<TValue>;
      FCreatedNodes : TObjectList<TdXMLBaseNode>;
      FMethodInterceptor : TVirtualMethodInterceptorHandle;
      /// <summary> If True, nodes that removed from observed list will not deleted, instead they will remain in cache.</summary>
      FCacheEnabled : boolean;
      FCache : TObjectDictionary<TObject, TdXMLNode>;
      procedure ContextChanged(Context : TExpressionContext; const ChangedVariable : string); override;
      procedure ListInstanceChangedHandler(Expression : TExpression; Context : TExpressionContext);
      /// <summary> Will intercept all virtual methods of the list, to intercept Notify method.</summary>
      procedure RegisterOnListNotify(const List : TObject);
      /// <summary> Will stop intercept all virtual methods of list instance and cleanup.</summary>
      procedure DeRegisterOnListNotify;
      procedure ListChangedHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
      procedure InsertItems(const Items : TValue; FirstIndex : Integer);
      constructor Create(); overload;
      constructor Create(Parent : TdXMLBaseNode; Data : TdXMLAbstractForLoopNode); overload;
      function Clone(Value : TdXMLBaseNode = nil) : TdXMLBaseNode; override;
      procedure SetParent(const Value : TdXMLBaseNode); override;
      function GetBaseIndex : Integer;
    public
      property Pattern : TdXMLBaseNode read FPattern;
      destructor Destroy; override;
  end;

  TdXMLIfNode = class(TdXMLBaseNode)
    private
      constructor Create(Parent : TdXMLBaseNode; Data : TdXMLAbstractIfNode);
    public
  end;

  TdXMLDocument = class
    private
      FRootNode : TdXMLNode;
    public
      class var BasePath : string;
    public
      property RootNode : TdXMLNode read FRootNode;
      procedure SaveXMLToFile(FileName : string);
      procedure Reload;
      // ============== Constructor & Destructor =================
      constructor Create(FileName : string);
      destructor Destroy; override;
  end;

implementation

{ TdXML }

constructor TdXMLDocument.Create(FileName : string);
begin
  if not FileExists(FileName) then
  begin
    HLog.Log('TdXML.Create: XMLFile "' + FileName + '" doesn''t exist.');
    Exit;
  end;
  FRootNode := TdXMLIncludeNode.Create(nil, FileName);
end;

destructor TdXMLDocument.Destroy;
begin
  FRootNode.Free;
  inherited;
end;

procedure TdXMLDocument.Reload;
begin
  if assigned(FRootNode) then
    (FRootNode as TdXMLIncludeNode).Reload;
end;

procedure TdXMLDocument.SaveXMLToFile(FileName : string);
var
  XMLDocument : TXmlVerySimple;
begin
  XMLDocument := TXmlVerySimple.Create;
  XMLDocument.DocumentElement := RootNode.GetXML;
  XMLDocument.SaveToFile(FileName);
  XMLDocument.Free;
end;

{ TdXMLNode }

procedure TdXMLNode.CallEvent(const EventName : string; const Parameter : TValue);
var
  EventBinding : TEventBinding;
begin
  if FEventBindings.TryGetValue(EventName, EventBinding) then
      EventBinding.Call(Parameter);
end;

procedure TdXMLNode.CallEvent(const EventName : string);
begin
  CallEvent(EventName, TValue.Empty);
end;

procedure TdXMLNode.TextChangedCallback(Sender : TDynamicTextField);
begin
  assert(Sender = FDynamicText);
  if assigned(FOnTextChanged) then FOnTextChanged(self);
end;

function TdXMLNode.Clone(Value : TdXMLBaseNode) : TdXMLBaseNode;
var
  LogicalChild : TdXMLBaseNode;
  ResultAsNode : TdXMLNode;
  Attribute : TPair<string, string>;
  DynamicAttribute : TDynamicAttribute;
  EventBinding : TPair<string, TEventBinding>;
  Alias : TAlias;
begin
  if not assigned(Value) then
      Value := TdXMLNode.Create;
  Result := inherited Clone(Value);
  ResultAsNode := Result as TdXMLNode;
  ResultAsNode.FName := FName;
  if assigned(FDynamicText) then
  begin
    ResultAsNode.FDynamicText := FDynamicText.Clone;
    ResultAsNode.FDynamicText.OnTextChanged := ResultAsNode.TextChangedCallback;
  end;
  for Alias in FAliases do
  begin
    ResultAsNode.FAliases.Add(Alias.Clone);
  end;
  for DynamicAttribute in FDynamicAttributes do
  begin
    ResultAsNode.FDynamicAttributes.Add(DynamicAttribute.Clone() as TDynamicAttribute);
    ResultAsNode.FDynamicAttributes.Last.OnTextChanged := ResultAsNode.AttributeValueChangedCallback;
  end;
  for Attribute in Attributes do
      ResultAsNode.Attributes.Add(Attribute.Key, Attribute.Value);
  for EventBinding in FEventBindings do
  begin
    ResultAsNode.FEventBindings.Add(EventBinding.Key, EventBinding.Value.Clone);
  end;
  for LogicalChild in FLogicalChildren do
  begin
    ResultAsNode.FLogicalChildren.Add(LogicalChild.Clone);
    ResultAsNode.FLogicalChildren.Last.Parent := ResultAsNode;
    if ResultAsNode.FLogicalChildren.Last is TdXMLNode then
        ResultAsNode.Children.Add(ResultAsNode.FLogicalChildren.Last as TdXMLNode);
  end;
end;

procedure TdXMLNode.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
var
  ContextCopy : TExpressionContext;
  Child : TdXMLBaseNode;
  EventBinding : TEventBinding;
  Alias : TAlias;
  DynamicAttribute : TDynamicAttribute;
  ChangedArray : TArray<string>;
  ChangedVariableName : string;
begin
  inherited;
  ChangedArray := [ChangedVariable];
  for Alias in FAliases do
  begin
    Alias.OnAliasValueChanged := nil;
    Alias.ContextChanged(Context, ChangedVariable);
    Context.AddOrSetValue(Alias.Alias, Alias.Value);
    // don't need refresh on empty as all aliases are refreshed implicitly, when global refresh is called
    if not ChangedVariable.IsEmpty and Alias.DependsOnVariable(ChangedVariable) then ChangedArray := ChangedArray + [Alias.Alias];
    Alias.OnAliasValueChanged := AliasValueChanged;
  end;

  for ChangedVariableName in ChangedArray do
  begin
    if assigned(FDynamicText) and FDynamicText.IsDynamic then FDynamicText.ContextChanged(Context, ChangedVariableName);
    for EventBinding in FEventBindings.Values do
        EventBinding.ContextChanged(Context, ChangedVariableName);
    for DynamicAttribute in FDynamicAttributes do
        DynamicAttribute.ContextChanged(Context, ChangedVariableName);

    // notify also all children about change
    for Child in FLogicalChildren do
    begin
      // copy context to allow child to manipulate it
      ContextCopy := Context.Clone;
      Child.ContextChanged(ContextCopy, ChangedVariableName);
      ContextCopy.Free;
    end;
  end;
end;

procedure TdXMLNode.AliasValueChanged(ContextWithAlias : TExpressionContext; const Alias : string);
begin
  ContextChanged(ContextWithAlias, Alias);
end;

procedure TdXMLNode.AttributeValueChangedCallback(Sender : TDynamicTextField);
var
  AttributeKey : string;
begin
  assert(Sender is TDynamicAttribute);
  // if attribute is still present in attribute list, update it
  AttributeKey := TDynamicAttribute(Sender).Name;
  if Attributes.ContainsKey(AttributeKey) then
  begin
    // reassign new value will trigger only Value notifies
    Attributes[AttributeKey] := Sender.Text;
    // so call key notify manually
    if assigned(Attributes.OnKeyNotify) then Attributes.OnKeyNotify(Attributes, TDynamicAttribute(Sender).Name, cnAdded);
  end;
end;

constructor TdXMLNode.BaseCreate;
begin
  FAttributes := TDictionary<string, string>.Create(TEqualityComparer<string>.Construct(
    function(const Left, Right : string) : boolean
    begin
      Result := SameText(Left, Right);
    end,
    function(const Value : string) : Integer
    begin
      Result := THashBobJenkins.GetHashValue(Value.ToLowerInvariant);
    end
    ));
  FEventBindings := TObjectDictionary<string, TEventBinding>.Create([doOwnsValues], TEqualityComparer<string>.Construct(
    function(const Left, Right : string) : boolean
    begin
      Result := SameText(Left, Right);
    end,
    function(const Value : string) : Integer
    begin
      Result := THashBobJenkins.GetHashValue(Value.ToLowerInvariant);
    end
    ));
  FChildren := TUltimateList<TdXMLNode>.Create;
  FLogicalChildren := TUltimateObjectList<TdXMLBaseNode>.Create();
  FDynamicAttributes := TObjectList<TDynamicAttribute>.Create();
  FAliases := TObjectList<TAlias>.Create();
end;

constructor TdXMLNode.Create(Parent : TdXMLBaseNode; Data : TdXMLAbstractSimpleNode);
begin
  inherited Create(Parent);
  BaseCreate();
  if assigned(Data) then
      LoadData(Data);
end;

constructor TdXMLNode.Create;
begin
  inherited Create;
  BaseCreate;
end;

destructor TdXMLNode.Destroy;
begin
  FLogicalChildren.Free;
  FChildren.Free;
  FEventBindings.Free;
  FAttributes.Free;
  FDynamicText.Free;
  FDynamicAttributes.Free;
  FAliases.Free;
  inherited;
end;

procedure TdXMLNode.LoadAttributes(const Attributes : TDictionary<string, string>);
var
  Attribute : TPair<string, string>;
  Events : TList<string>;
  Event : string;
  AliasRaw, AttributeKey, AttributeValue : string;
  DynamicAttribute : TDynamicAttribute;
begin
  for Attribute in Attributes do
  begin
    // filter and process dxml attributes
    if Attribute.Key.StartsWith(DXML_TOKEN_ONEVENT, True) then
    begin
      Events := TList<string>.Create;
      Events.AddRange(Attribute.Key.Split([':']));
      assert(SameText(Events.First, DXML_TOKEN_ONEVENT));
      Events.Delete(0);
      for Event in Events do
          FEventBindings.Add(Event, TEventBinding.Create(Attribute.Value));
      Events.Free;
    end
    else if SameText(Attribute.Key, DXML_TOKEN_WITH) then
    begin
      for AliasRaw in Attribute.Value.Split([';']) do
      begin
        FAliases.Add(TAlias.Create(AliasRaw));
        FAliases.Last.OnAliasValueChanged := AliasValueChanged;
      end;
    end
    else
    begin
      AttributeKey := Attribute.Key;
      AttributeValue := Attribute.Value;
      // attributes starting with a : are always traited as an expression
      if AttributeKey.StartsWith(':') then
      begin
        AttributeKey := AttributeKey.Remove(0, 1);
        AttributeValue := '{{ ' + AttributeValue + ' }}';
      end;
      DynamicAttribute := TDynamicAttribute.Create(AttributeKey, AttributeValue);
      FAttributes.Add(AttributeKey, DynamicAttribute.Text);
      // only real dynamic attributes need maintance
      if DynamicAttribute.IsDynamic then
      begin
        DynamicAttribute.OnTextChanged := AttributeValueChangedCallback;
        FDynamicAttributes.Add(DynamicAttribute);
      end
      else
          DynamicAttribute.Free;
    end;
  end;
end;

function TdXMLNode.GetCurrentExpressionContext : TExpressionContext;
var
  Alias : TAlias;
begin
  Result := inherited;
  for Alias in FAliases do
  begin
    Result.AddOrSetValue(Alias.Alias, Alias.Value);
  end;
end;

function TdXMLNode.GetText : string;
begin
  if assigned(FDynamicText) then
      Result := FDynamicText.Text
  else Result := '';
end;

function TdXMLNode.GetXML : TXmlNode;
var
  Child : TdXMLNode;
  Attribute : TPair<string, string>;
begin
  Result := TXmlNode.Create();
  Result.Name := name;
  Result.Text := Text;
  for Attribute in Attributes do
  begin
    Result.AttributeList.Add(Attribute.Key);
    if not Attribute.Value.IsEmpty then
        Result.AttributeList.Last.Value := Attribute.Value;
  end;
  for Child in Children do
  begin
    Result.ChildNodes.Add(Child.GetXML);
  end;
end;

procedure TdXMLNode.LoadData(const Data : TdXMLAbstractSimpleNode);
var
  ChildData : TdXMLAbstractXMLNode;
begin
  FChildren.Clear;
  FLogicalChildren.Clear;
  Attributes.Clear;
  FDynamicAttributes.Clear;
  FEventBindings.Clear;
  FName := Data.Name;
  FDynamicText.Free;
  FDynamicText := TDynamicTextField.Create(Data.Text);
  FDynamicText.OnTextChanged := TextChangedCallback;
  FAliases.Clear;
  LoadAttributes(Data.Attributes);
  for ChildData in Data.Children do
  begin
    // first only add new child to logical Children, because if childnode
    FLogicalChildren.Add(TdXMLBaseNode.CreateNode(self, ChildData));
    FLogicalChildren.Last.FIndex := FLogicalChildren.Count - 1;
    // TdXMLNode is the default node with name, text and Children and will always be part
    // of the real Children
    if FLogicalChildren.Last is TdXMLNode then
        FChildren.Add(FLogicalChildren.Last as TdXMLNode);
  end;
end;

{ TdXMLSimpleXMLNode }

constructor TdXMLAbstractSimpleNode.Create(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
var
  Attribute : TXmlAttribute;
  Child : TXmlNode;
  i : Integer;
begin
  inherited Create(Parent);
  FName := XMLNode.Name;
  FText := XMLNode.Text;
  FAttributes := TDictionary<string, string>.Create();
  for Attribute in XMLNode.AttributeList do
      FAttributes.Add(Attribute.Name, Attribute.Value);
  FChildren := TObjectList<TdXMLAbstractXMLNode>.Create();
  // don't use for loop here, because ChildNodes list will be manipulated while processing
  i := 0;
  while i < XMLNode.ChildNodes.Count do
  begin
    Child := XMLNode.ChildNodes[i];
    if Child.NodeType in [ntElement] then
        FChildren.Add(TdXMLAbstractXMLNode.CreateFromXMLNode(Child, self));
    inc(i);
  end;
end;

destructor TdXMLAbstractSimpleNode.Destroy;
begin
  FAttributes.Free;
  FChildren.Free;
  inherited;
end;

{ TdXMLAbstractIncludeNode }

constructor TdXMLAbstractIncludeNode.CreateFromNode(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
var
  Attribute : TXmlAttribute;
begin
  inherited Create(Parent);
  FSourceFileName := XMLNode.Attributes[DXML_TOKEN_INCLUDE];
  if XMLNode.HasAttribute(DXML_TOKEN_WITH) then
      FWithRawValue := XMLNode.AttributeList.Find(DXML_TOKEN_WITH).Value;
  FAttributes := TDictionary<string, string>.Create();
  for Attribute in XMLNode.AttributeList do
    if not Attribute.Name.StartsWith(DXML_PREFIX, True) then
        FAttributes.Add(Attribute.Name, Attribute.Value);
end;

constructor TdXMLAbstractIncludeNode.CreateFromFile(const SourceFileName : string; Parent : TdXMLAbstractXMLNode);
var
  XMLDocument : TXmlVerySimple;
  RootNode : TdXMLAbstractXMLNode;
  AbsoluteFileName : string;
  Content : string;
begin
  inherited Create(Parent);
  // save fullpath here, because path is later used to subscribe on file
  if assigned(Parent) then
  begin
    RootNode := self.GetRootNode;
    assert(RootNode is TdXMLAbstractIncludeNode);
    AbsoluteFileName := TPath.Combine(ExtractFilePath(TdXMLAbstractIncludeNode(RootNode).SourceFileName), SourceFileName);
  end
  else
  begin
    if not HFilepathManager.IsAbsolute(SourceFileName) then
        AbsoluteFileName := HFilepathManager.RelativeToAbsolute(SourceFileName)
    else AbsoluteFileName := SourceFileName;
  end;
  FSourceFileName := AbsoluteFileName;
  XMLDocument := TXmlVerySimple.Create();
  XMLDocument.Options := XMLDocument.Options + [doCaseInsensitive];
  Content := HFileIO.ReadAllText(FSourceFileName, TEncoding.UTF8);
  XMLDocument.Text := Content
    .Replace(' <= ', ' &lt;= ')
    .Replace(' < ', ' &lt; ')
    .Replace(' > ', ' &gt; ')
    .Replace(' >= ', ' &gt;= ')
    .Replace(' <> ', ' &lt;&gt; ');
  FInnerNode := TdXMLAbstractXMLNode.CreateFromXMLNode(XMLDocument.DocumentElement, self);
  XMLDocument.Free;
end;

destructor TdXMLAbstractIncludeNode.Destroy;
begin
  FAttributes.Free;
  FInnerNode.Free;
  inherited;
end;

{ TdXMLAbstractXMLNode }

constructor TdXMLAbstractXMLNode.Create(Parent : TdXMLAbstractXMLNode);
begin
  FParent := Parent;
end;

class function TdXMLAbstractXMLNode.CreateFromXMLNode(const XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode) : TdXMLAbstractXMLNode;
begin
  // this attrributes should not be found here
  if XMLNode.AttributeList.HasAttribute(DXML_TOKEN_CONDITIONAL_CONTENT_ELSEIF) then
      raise EdXMLParseError.Create('TdXMLAbstractXMLNode.CreateFromXMLNode: ELIF attribute only allowed after IF.')
  else if XMLNode.AttributeList.HasAttribute(DXML_TOKEN_CONDITIONAL_CONTENT_ELSE) then
      raise EdXMLParseError.Create('TdXMLAbstractXMLNode.CreateFromXMLNode: ELSE attribute only allowed after IF or ELIF.')
    // handle some dXML structure control attributes
  else if XMLNode.AttributeList.HasAttribute(DXML_TOKEN_CONDITIONAL_CONTENT) then
      Result := TdXMLAbstractIfNode.Create(XMLNode, Parent)
  else if XMLNode.AttributeList.HasAttribute(DXML_TOKEN_FORLOOP) or XMLNode.AttributeList.HasAttribute(DXML_TOKEN_FORLOOP_STATIC) then
      Result := TdXMLAbstractForLoopNode.Create(XMLNode, Parent)
  else if XMLNode.AttributeList.HasAttribute(DXML_TOKEN_INCLUDE) then
      Result := TdXMLAbstractIncludeNode.CreateFromNode(XMLNode, Parent)
  else
      Result := TdXMLAbstractSimpleNode.Create(XMLNode, Parent);
end;

function TdXMLAbstractXMLNode.GetRootNode : TdXMLAbstractXMLNode;
begin
  Result := self;
  // rootnode = parent unassigned
  while assigned(Result.Parent) do
      Result := Result.Parent;
end;

{ TdXMLAbstractForLoopXMLNode }

constructor TdXMLAbstractForLoopNode.Create(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
var
  Splitter : string;
  SplitText : TArray<string>;
begin
  inherited Create(Parent);
  FStaticBinding := XMLNode.AttributeList.HasAttribute(DXML_TOKEN_FORLOOP_STATIC);
  FCacheData := XMLNode.AttributeList.HasAttribute(DXML_TOKEN_CACHE_DATA);
  if FStaticBinding then Splitter := DXML_TOKEN_FORLOOP_STATIC
  else Splitter := DXML_TOKEN_FORLOOP;
  SplitText := HString.Split(XMLNode.Attributes[Splitter], [' '], False, 3);
  assert(length(SplitText) = 3);
  assert(SameText(SplitText[1], 'in'));
  FItemVariableName := SplitText[0].Trim;
  FListVariableName := SplitText[2].Trim;
  XMLNode.AttributeList.Delete(DXML_TOKEN_FORLOOP);
  XMLNode.AttributeList.Delete(DXML_TOKEN_FORLOOP_STATIC);
  XMLNode.AttributeList.Delete(DXML_TOKEN_CACHE_DATA);
  FInnerNode := TdXMLAbstractXMLNode.CreateFromXMLNode(XMLNode, self);
end;

{ TdXMLAbstractIfXMLNode }

constructor TdXMLAbstractIfNode.Create(XMLNode : TXmlNode; Parent : TdXMLAbstractXMLNode);
  function GetNextSibling(const XMLNode : TXmlNode) : TXmlNode;
  begin
    Result := XMLNode.NextSibling;
    while assigned(Result) and (Result.NodeType <> ntElement) do
        Result := Result.NextSibling;
  end;

var
  ConditionalItem : TConditionalItem;
  NextSibling, CurrentSibling : TXmlNode;
begin
  inherited Create(Parent);
  FConditionalItems := TObjectList<TConditionalItem>.Create();
  ConditionalItem := TConditionalItem.Create;
  ConditionalItem.Condition := XMLNode.Attributes[DXML_TOKEN_CONDITIONAL_CONTENT];
  XMLNode.AttributeList.Delete(DXML_TOKEN_CONDITIONAL_CONTENT);
  ConditionalItem.Node := TdXMLAbstractXMLNode.CreateFromXMLNode(XMLNode, self);
  ConditionalItems.Add(ConditionalItem);
  // process all following siblings that contain elif or else
  NextSibling := GetNextSibling(XMLNode);

  while assigned(NextSibling) and
    (NextSibling.AttributeList.HasAttribute(DXML_TOKEN_CONDITIONAL_CONTENT_ELSEIF) or
    NextSibling.AttributeList.HasAttribute(DXML_TOKEN_CONDITIONAL_CONTENT_ELSE)) do
  begin
    CurrentSibling := NextSibling;
    ConditionalItem := TConditionalItem.Create;
    if CurrentSibling.HasAttribute(DXML_TOKEN_CONDITIONAL_CONTENT_ELSEIF) then
    begin
      ConditionalItem.Condition := CurrentSibling.Attributes[DXML_TOKEN_CONDITIONAL_CONTENT_ELSEIF];
      CurrentSibling.AttributeList.Delete(DXML_TOKEN_CONDITIONAL_CONTENT_ELSEIF);
    end
    else
    begin
      assert(NextSibling.AttributeList.HasAttribute(DXML_TOKEN_CONDITIONAL_CONTENT_ELSE));
      // else will works always
      ConditionalItem.Condition := '';
      CurrentSibling.AttributeList.Delete(DXML_TOKEN_CONDITIONAL_CONTENT_ELSE);
    end;
    ConditionalItem.Node := TdXMLAbstractXMLNode.CreateFromXMLNode(CurrentSibling, self);
    ConditionalItems.Add(ConditionalItem);
    NextSibling := GetNextSibling(CurrentSibling);
    // free sibling, because else they would confuse the standard node processing routine
    // (elif and else only allowed direct after if)
    CurrentSibling.Parent.ChildNodes.Remove(CurrentSibling);
    // fast exit on ELSE, because ELSE is always the possible statement in an if block
    if ConditionalItem.IsElse then
        Break;
  end;
end;

destructor TdXMLAbstractIfNode.Destroy;
begin
  FConditionalItems.Free;
  inherited;
end;

{ TdXMLAbstractIfXMLNode.TConditionalItem }

destructor TdXMLAbstractIfNode.TConditionalItem.Destroy;
begin
  Node.Free;
  inherited;
end;

function TdXMLAbstractIfNode.TConditionalItem.IsElse : boolean;
begin
  Result := Condition.IsEmpty;
end;

{ TdXMLIncludeNode }

function TdXMLIncludeNode.Clone(Value : TdXMLBaseNode) : TdXMLBaseNode;
var
  Attribute : TPair<string, string>;
begin
  if not assigned(Value) then
      Value := TdXMLIncludeNode.Create;
  Result := inherited Clone(Value);
  for Attribute in FAdditionalAttributes do
      TdXMLIncludeNode(Result).FAdditionalAttributes.AddOrSetValue(Attribute.Key, Attribute.Value);
  if assigned(FDynamicFileName) then
  begin
    TdXMLIncludeNode(Result).FDynamicFileName := FDynamicFileName.Clone;
    TdXMLIncludeNode(Result).FDynamicFileName.OnTextChanged := TdXMLIncludeNode(Result).FileNameChangedCallback;
  end;
end;

procedure TdXMLIncludeNode.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
begin
  if assigned(FDynamicFileName) then
      FDynamicFileName.ContextChanged(Context, ChangedVariable);
  inherited;
end;

constructor TdXMLIncludeNode.Create;
begin
  if not assigned(FAdditionalAttributes) then FAdditionalAttributes := TDictionary<string, string>.Create();
  inherited Create();
end;

constructor TdXMLIncludeNode.Create(Parent : TdXMLBaseNode; Node : TdXMLAbstractIncludeNode);
var
  Attribute : TPair<string, string>;
begin
  FWithValue := Node.FWithRawValue;
  if not assigned(FAdditionalAttributes) then FAdditionalAttributes := TDictionary<string, string>.Create();
  for Attribute in Node.Attributes do
      FAdditionalAttributes.AddOrSetValue(Attribute.Key, Attribute.Value);
  Create(Parent, Node.SourceFileName);
end;

constructor TdXMLIncludeNode.Create(Parent : TdXMLBaseNode; const FileNameExpression : string);
begin
  if not assigned(FAdditionalAttributes) then FAdditionalAttributes := TDictionary<string, string>.Create();
  inherited Create(Parent, nil);
  SourceFileName := FileNameExpression;
end;

destructor TdXMLIncludeNode.Destroy;
begin
  FAdditionalAttributes.Free;
  if FileExists(FFileName) then
      ContentManager.UnSubscribeFromFile(FFileName, SourceFileChangedCallback);
  FDynamicFileName.Free;
  inherited;
end;

procedure TdXMLIncludeNode.FileNameChangedCallback(Sender : TDynamicTextField);
var
  NewFileName : string;
begin
  if assigned(Sender) then
      NewFileName := HFilepathManager.RelativeToAbsolute(TPath.Combine(TdXMLDocument.BasePath, Sender.Text))
  else
      NewFileName := HFilepathManager.RelativeToAbsolute(TPath.Combine(TdXMLDocument.BasePath, FFileName));
  if (NewFileName <> FFileName) or not assigned(Sender) then
  begin
    // cleanup from old filename
    if FileExists(FFileName) then
        ContentManager.UnSubscribeFromFile(FFileName, SourceFileChangedCallback);

    // set new and setup
    FFileName := NewFileName;
    if FileExists(FFileName) then
        ContentManager.SubscribeToFile(FFileName, SourceFileChangedCallback);
  end;
end;

procedure TdXMLIncludeNode.Reload;
begin
  FileNameChangedCallback(nil);
end;

procedure TdXMLIncludeNode.SetSourceFileName(const Value : string);
begin
  FreeAndNil(FDynamicFileName);
  if Value.Contains('{{') then
  begin
    // set new filename expression and try to load data
    FDynamicFileName := TDynamicTextField.Create(Value);
    FDynamicFileName.OnTextChanged := FileNameChangedCallback;
    FileNameChangedCallback(FDynamicFileName);
  end
  else
  begin
    FFileName := Value;
    FileNameChangedCallback(nil);
  end;
end;

procedure TdXMLIncludeNode.SourceFileChangedCallback(const Filepath, FileContent : string);
var
  Data : TdXMLAbstractIncludeNode;
  Context : TExpressionContext;
  Attribute : TPair<string, string>;
  Value, CleanedKey : string;
  merge : boolean;
begin
  Data := nil;
  try
    Data := TdXMLAbstractIncludeNode.CreateFromFile(Filepath, nil) as TdXMLAbstractIncludeNode;
    if not FWithValue.IsEmpty then
        TdXMLAbstractSimpleNode(Data.InnerNode).Attributes.Add(DXML_TOKEN_WITH, FWithValue);
    for Attribute in FAdditionalAttributes do
    begin
      merge := Attribute.Key.EndsWith(':merge', True);
      CleanedKey := Attribute.Key.Replace(':merge', '');
      if not TdXMLAbstractSimpleNode(Data.InnerNode).Attributes.TryGetValue(CleanedKey, Value) then
          Value := Attribute.Value
      else
      begin
        if merge then
            Value := Value + ' ' + Attribute.Value
        else
            Value := Attribute.Value;
      end;
      TdXMLAbstractSimpleNode(Data.InnerNode).Attributes.AddOrSetValue(CleanedKey, Value);
    end;

    LoadData(Data.InnerNode as TdXMLAbstractSimpleNode);

    // notify a contextdata change where all data has changed
    Context := GetCurrentExpressionContext();
    ContextChanged(Context, '');
    Context.Free;
    // node data has maybe completly changed, so make a reload
    if assigned(FOnNeedReload) then FOnNeedReload(self);
  except
    on e : Exception do
        HLog.Console('Error ín dXML file "%s": %s', [Filepath, e.ToString]);
  end;
  Data.Free;
end;

{ TdXMLBaseNode }

function TdXMLBaseNode.Clone(Value : TdXMLBaseNode) : TdXMLBaseNode;
var
  Key : string;
begin
  if not assigned(Value) then
      Value := TdXMLBaseNode.Create;
  Result := Value;
  Result.FParent := FParent;
  Result.FIndex := FIndex;
  for Key in Context.Keys do
  begin
    Result.Context.Add(Key, Context[Key]);
  end;
end;

procedure TdXMLBaseNode.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
var
  Item : TPair<string, TValue>;
begin
  // merge with own local context and shadowing by overwriting existing items with own values
  for Item in FLocalContext do
      Context.AddOrSetValue(Item.Key, Item.Value);
end;

procedure TdXMLBaseNode.ContextDataChangedCallback(Sender : TObject; const Item : string; Action : TCollectionNotification);
var
  Context : TExpressionContext;
begin
  assert(Sender = FLocalContext);
  // use empty context, because ContextChanged will always copy data from local context into called context
  Context := TExpressionContext.Create;
  ContextChanged(Context, Item);
  Context.Free;
end;

constructor TdXMLBaseNode.Create(Parent : TdXMLBaseNode);
begin
  Create();
  self.Parent := Parent;
end;

constructor TdXMLBaseNode.Create;
begin
  FLocalContext := TExpressionContext.Create;
  FLocalContext.OnKeyNotify := ContextDataChangedCallback;
end;

class function TdXMLBaseNode.CreateNode(Parent : TdXMLBaseNode; Data : TdXMLAbstractXMLNode) : TdXMLBaseNode;
begin
  if Data is TdXMLAbstractSimpleNode then
      Result := TdXMLNode.Create(Parent, Data as TdXMLAbstractSimpleNode)
  else if Data is TdXMLAbstractIncludeNode then
      Result := TdXMLIncludeNode.Create(Parent, TdXMLAbstractIncludeNode(Data))
  else if Data is TdXMLAbstractForLoopNode then
      Result := TdXMLForLoopNode.Create(Parent, Data as TdXMLAbstractForLoopNode)
  else if Data is TdXMLAbstractIfNode then
      Result := TdXMLIfNode.Create(Parent, Data as TdXMLAbstractIfNode)
  else
      raise ENotImplemented.Create('TdXMLBaseNode.CreateNode: Unknown node type ' + Data.ClassName);
end;

destructor TdXMLBaseNode.Destroy;
begin
  // stop observing changes, because free a context would call callback for every item
  FLocalContext.OnKeyNotify := nil;
  FLocalContext.Free;
  inherited;
end;

function TdXMLBaseNode.GetCurrentExpressionContext : TExpressionContext;
var
  Parent : TdXMLBaseNode;
  Item : TPair<string, TValue>;
begin
  Parent := self.Parent;
  if assigned(Parent) then
  begin
    Result := Parent.GetCurrentExpressionContext;
    for Item in Context do
    begin
      Result.AddOrSetValue(Item.Key, Item.Value);
    end;
  end
  else
      Result := FLocalContext.Clone;
end;

function TdXMLBaseNode.GetXML : TXmlNode;
begin
  raise ENotImplemented.Create('TdXMLBaseNode.GetXML: Should never called!');
end;

procedure TdXMLBaseNode.SetParent(const Value : TdXMLBaseNode);
begin
  FParent := Value;
end;

{ TdXMLForLoopNode }

function TdXMLForLoopNode.Clone(Value : TdXMLBaseNode) : TdXMLBaseNode;
var
  ResultAsLoopNode : TdXMLForLoopNode;
begin
  if not assigned(Value) then
      Value := TdXMLForLoopNode.Create;
  Result := inherited Clone(Value);
  ResultAsLoopNode := Result as TdXMLForLoopNode;
  ResultAsLoopNode.FPattern := Pattern.Clone;
  ResultAsLoopNode.FItemVariableName := FItemVariableName;
  ResultAsLoopNode.FListExpression := TExpression.Create(FListExpression.RawExpression);
  ResultAsLoopNode.FListExpressionObserver := TExpressionObserver.Create(ResultAsLoopNode.FListExpression);
  ResultAsLoopNode.FListExpressionObserver.OnExpressionNeedReEvaluation := ResultAsLoopNode.ListInstanceChangedHandler;
  ResultAsLoopNode.FStaticBinding := FStaticBinding;
end;

procedure TdXMLForLoopNode.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
var
  Child : TdXMLBaseNode;
  ContextCopy : TExpressionContext;
begin
  inherited;
  FListExpressionObserver.ContextHasChanged(Context, ChangedVariable);
  // notify also all children about change
  for Child in FCreatedNodes do
  begin
    // copy context to allow child to manipulate it
    ContextCopy := Context.Clone;
    Child.ContextChanged(ContextCopy, ChangedVariable);
    ContextCopy.Free;
  end;
end;

constructor TdXMLForLoopNode.Create(Parent : TdXMLBaseNode; Data : TdXMLAbstractForLoopNode);
begin
  inherited Create(Parent);
  FCacheEnabled := Data.CacheData;
  FListCopy := TList<TValue>.Create;
  FCreatedNodes := TObjectList<TdXMLBaseNode>.Create(not FCacheEnabled);
  FCache := TObjectDictionary<TObject, TdXMLNode>.Create([doOwnsValues]);
  FItemVariableName := Data.ItemVariableName;
  FListExpression := TExpression.Create(Data.ListVariableName);
  FListExpressionObserver := TExpressionObserver.Create(FListExpression);
  FListExpressionObserver.OnExpressionNeedReEvaluation := ListInstanceChangedHandler;
  FStaticBinding := Data.StaticBinding;
  FPattern := TdXMLBaseNode.CreateNode(nil, Data.FInnerNode);
end;

constructor TdXMLForLoopNode.Create();
begin
  inherited Create();
  FListCopy := TList<TValue>.Create;
  FCreatedNodes := TObjectList<TdXMLBaseNode>.Create();
  FCache := TObjectDictionary<TObject, TdXMLNode>.Create();
end;

procedure TdXMLForLoopNode.DeRegisterOnListNotify;
begin
  if assigned(FListInstance) then
  begin
    VirtualMethodInterceptorManager.Unproxify(FListInstance, FMethodInterceptor);
    FMethodInterceptor := nil;
  end;
end;

destructor TdXMLForLoopNode.Destroy;
var
  Node : TdXMLBaseNode;
begin
  DeRegisterOnListNotify;
  FListExpressionObserver.Free;
  FListExpression.Free;
  FPattern.Free;
  for Node in FCreatedNodes do
      FParentChildList.Remove(Node as TdXMLNode);
  FCreatedNodes.Free;
  FListCopy.Free;
  FCache.Free;
  inherited;
end;

procedure TdXMLForLoopNode.InsertItems(const Items : TValue; FirstIndex : Integer);
var
  NewNode : TdXMLNode;
  Context : TExpressionContext;
  i, ItemsCount, BaseIndex : Integer;
  Item : TValue;
begin
  assert(Items.IsArray);
  ItemsCount := Items.GetArrayLength;
  if ItemsCount > 0 then
  begin
    BaseIndex := GetBaseIndex;
    Context := GetCurrentExpressionContext;
    for i := 0 to ItemsCount - 1 do
    begin
      Item := Items.GetArrayElement(i);
      FListCopy.Insert(FirstIndex + i, Item);

      if not(FCacheEnabled and Item.IsObject and FCache.TryGetValue(Item.AsObject, NewNode)) then
      begin
        // create new node and set up
        NewNode := FPattern.Clone as TdXMLNode;
        NewNode.FIndex := FIndex;
        NewNode.Parent := Parent;

        NewNode.Context.SuppressNotifies := True;
        // in every node the variable it based on, will set
        NewNode.Context.AddOrSetValue(FItemVariableName, Item);
        NewNode.Context.SuppressNotifies := False;
        if FCacheEnabled and Item.IsObject then
            FCache.Add(Item.AsObject, NewNode);
        NewNode.Context.AddOrSetValue('index', FirstIndex + i);
        NewNode.ContextChanged(Context, '');
      end
      else
      begin
        NewNode.Context.AddOrSetValue('index', FirstIndex + i);
        NewNode.ContextChanged(Context, 'index');
      end;
      FCreatedNodes.Insert(FirstIndex + i, NewNode);
      FParentChildList.Insert(BaseIndex + FirstIndex + i, NewNode);
    end;
    for i := FirstIndex + ItemsCount to FCreatedNodes.Count - 1 do
    begin
      FCreatedNodes[i].Context.AddOrSetValue('index', i);
      FCreatedNodes[i].ContextChanged(Context, 'index');
    end;
    Context.Free;
  end;
end;

/// <summary> Returns the index in parents childlist where the loop should place the created node</summary>
function TdXMLForLoopNode.GetBaseIndex : Integer;
begin
  Result := 0;
  while (Result < FParentChildList.Count) and (FParentChildList[Result].FIndex < FIndex) do
      inc(Result);
end;

procedure TdXMLForLoopNode.ListChangedHandler(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
var
  Action : EnumListAction;
  Items : TValue;
  i : Integer;
  Indices : TArray<Integer>;
  Node : TdXMLBaseNode;
begin
  Result := True;
  if assigned(Instance) then
  begin
    assert(Instance = FListInstance);
    // only need to observe NotifyChange, because this is called everytime the is changed
    if SameText(Method.Name, 'NotifyChange') then
    begin
      assert(length(Args) = 3);
      Items := Args[0];
      Action := Args[1].AsType<EnumListAction>;
      Indices := Args[2].ToArray<Integer>;
      case Action of
        laAdd, laAddRange :
          begin
            InsertItems(Items, Indices[0]);
          end;
        laRemoved, laExtracted, laExtractedRange :
          begin
            for i := 0 to length(Indices) - 1 do
            begin
              Node := FCreatedNodes[Indices[i]];
              FParentChildList.Remove(Node as TdXMLNode);
              FCreatedNodes.Delete(Indices[i]);
              FListCopy.Delete(Indices[i]);
            end;
          end;
        laChanged :; // currently don't know what todo
        laClear :
          begin
            for Node in FCreatedNodes do
                FParentChildList.Remove(Node as TdXMLNode);
            FCreatedNodes.Clear;
            FListCopy.Clear;
          end;
      end;
    end;
  end;
end;

procedure TdXMLForLoopNode.ListInstanceChangedHandler(Expression : TExpression; Context : TExpressionContext);
var
  List : TValue;
  Node : TdXMLBaseNode;
begin
  if (FCreatedNodes.Count > 0) or (assigned(FMethodInterceptor)) then
  begin
    // new list, so clear all nodes created based on old list
    for Node in FCreatedNodes do
        FParentChildList.Remove(Node as TdXMLNode);
    FCreatedNodes.Clear;
    FListCopy.Clear;
    if not FStaticBinding and List.IsObject then
        DeRegisterOnListNotify;
    FListInstance := nil;
  end;
  FCache.Clear;
  List := Expression.Eval(Context);
  if not List.IsEmpty then
  begin
    // add all elements that already in the list
    if List.IsArray then InsertItems(List, FListCopy.Count)
    else InsertItems(List.Resolve('ToArray', []), FListCopy.Count);
    // register on list changes if it is not a static binding
    if not FStaticBinding and List.IsObject then
        RegisterOnListNotify(List.AsObject);
  end
end;

procedure TdXMLForLoopNode.RegisterOnListNotify(const List : TObject);
begin
  FListInstance := List;
  if not(FListInstance.ClassName.StartsWith('TUltimateList<', True) or FListInstance.ClassName.StartsWith('TUltimateObjectList<', True)) then
      raise ENotSupportedException.CreateFmt('TdXMLForLoopNode.RegisterOnListNotify: Only support TUltimateList and TUltimateObjectList, list from type "%s" is not supported.', [FListInstance.ClassName]);
  assert(not assigned(FMethodInterceptor));
  FMethodInterceptor := VirtualMethodInterceptorManager.Proxify(FListInstance);
  FMethodInterceptor.OnBefore := ListChangedHandler;
end;

procedure TdXMLForLoopNode.SetParent(const Value : TdXMLBaseNode);
begin
  inherited;
  assert(assigned(Value));
  FParentChildList := TdXMLNode(Value).Children;
end;

{ TdXMLIfNode }

constructor TdXMLIfNode.Create(Parent : TdXMLBaseNode; Data : TdXMLAbstractIfNode);
begin
  inherited Create(Parent);
end;

destructor TdXMLAbstractForLoopNode.Destroy;
begin
  FInnerNode.Free;
  inherited;
end;

{ TdXMLNode.TEventBinding }

procedure TdXMLNode.TEventBinding.Call(const Parameter : TValue);
begin
  Context.AddOrSetValue('SenderParam', Parameter);
  Expression.Eval(Context);
end;

function TdXMLNode.TEventBinding.Clone : TEventBinding;
var
  Item : string;
begin
  Result := TEventBinding.Create;
  Result.RawExpression := RawExpression;
  Result.Expression := TExpression.Create(RawExpression);
  for Item in DependantFields.Keys do
      Result.DependantFields.Add(Item, True);
end;

procedure TdXMLNode.TEventBinding.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
begin
  if DependantFields.ContainsKey(ChangedVariable) or ChangedVariable.IsEmpty then
  begin
    self.Context.Free;
    self.Context := Context.Clone;
  end;
end;

constructor TdXMLNode.TEventBinding.Create(const Binding : string);
var
  Item : string;
  VariableNames : TList<string>;
begin
  Create;
  assert(not Binding.IsEmpty);
  RawExpression := Binding.Trim;
  // for assignments ignore senderparams
  if not RawExpression.Contains(':=') then
  begin
    if RawExpression.EndsWith(')') then
    begin
      // any parameter?, so not ()
      if not RawExpression.TrimRight([')']).EndsWith('(') then
          RawExpression := RawExpression.TrimRight([')']) + ', SenderParam.)'
      else
          RawExpression := RawExpression.TrimRight([')']) + 'SenderParam.)';
    end
    else
        RawExpression := RawExpression + '(SenderParam.)';
  end;
  Expression := TExpression.Create(RawExpression);
  VariableNames := Expression.GetVariableNames;
  for Item in VariableNames do
      DependantFields.AddOrSetValue(Item, True);
  VariableNames.Free;
end;

destructor TdXMLNode.TEventBinding.Destroy;
begin
  Expression.Free;
  DependantFields.Free;
  Context.Free;
  inherited;
end;

constructor TdXMLNode.TEventBinding.Create;
begin
  Context := TExpressionContext.Create;
  DependantFields := TCaseInsensitiveDictionary<boolean>.Create;
end;

{ TDynamicTextField }

procedure TDynamicTextField.AddPart(Part : TPart);
begin
  Part.OnTextChanged := PartTextHasChangedHandler;
  FParts.Add(Part);
end;

function TDynamicTextField.BuildText : string;
var
  Part : TPart;
begin
  if not IsDynamic then
      Result := FStaticText
  else
  begin
    Result := '';
    for Part in FParts do
        Result := Result + Part.Text;
  end;
end;

function TDynamicTextField.Clone : TDynamicTextField;
var
  Part : TPart;
begin
  Result := CDynamicTextField(self.ClassType).Create();
  Result.FIsDynamic := FIsDynamic;
  if IsDynamic then
  begin
    for Part in FParts do
        Result.AddPart(Part.Clone);
  end
  else
      Result.FStaticText := FStaticText;
end;

procedure TDynamicTextField.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
var
  Part : TPart;
begin
  assert(IsDynamic);
  for Part in FParts do
      Part.ContextChanged(Context, ChangedVariable);
end;

constructor TDynamicTextField.Create(const Text : string);
var
  SplittedText : TArray<string>;
  VariableMode : boolean;
  TextPart : string;
begin
  Create();
  SplittedText := HString.Split(Text, ['{{', '}}'], True);
  VariableMode := False;
  if (length(SplittedText) <= 1) then
  begin
    FIsDynamic := False;
    FStaticText := Text;
  end
  else
  begin
    FIsDynamic := True;
    for TextPart in SplittedText do
    begin
      // variable closing tag
      if TextPart = '}}' then
      begin
        if VariableMode then
            VariableMode := False
        else
            raise EdXMLParseError.CreateFmt('TdXMLNode.TDynamicTextField.Create: Error in Text "%s". Unexpected }}.', [Text]);
      end
      // variable opening tag
      else if TextPart = '{{' then
      begin
        if not VariableMode then
            VariableMode := True
        else
            raise EdXMLParseError.CreateFmt('TdXMLNode.TDynamicTextField.Create: Error in Text "%s". Unexpected {{.', [Text]);
      end
      else
      begin
        // static part
        if not VariableMode then
            AddPart(TStaticPart.Create(TextPart))
        else
            AddPart(TDynamicPart.Create(TextPart));
      end;
    end;
  end;
end;

constructor TDynamicTextField.Create;
begin
  FIsDynamic := False;
  FParts := TObjectList<TPart>.Create();
end;

destructor TDynamicTextField.Destroy;
begin
  FParts.Free;
  inherited;
end;

procedure TDynamicTextField.PartTextHasChangedHandler;
begin
  if assigned(FOnTextChanged) then
      FOnTextChanged(self);
end;

{ TdXMLNode.TDynamicAttributeValueField }

function TdXMLNode.TDynamicAttribute.Clone : TDynamicTextField;
begin
  assert(IsDynamic);
  Result := inherited;
  TDynamicAttribute(Result).FName := FName;
end;

constructor TdXMLNode.TDynamicAttribute.Create(const Name, Text : string);
begin
  inherited Create(Text);
  FName := name;
end;

constructor TdXMLNode.TDynamicAttribute.Create;
begin
  inherited;
end;

{ TDynamicTextField.TStaticPart }

function TDynamicTextField.TStaticPart.Clone : TPart;
begin
  Result := TStaticPart.Create(Text);
end;

procedure TDynamicTextField.TStaticPart.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
begin
  // nothing todo
end;

constructor TDynamicTextField.TStaticPart.Create(const Value : string);
begin
  FText := Value;
end;

{ TDynamicTextField.TDynamicPart }

function TDynamicTextField.TDynamicPart.Clone : TPart;
begin
  Result := TDynamicPart.Create(FExpression.RawExpression);
end;

procedure TDynamicTextField.TDynamicPart.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
begin
  FExpressionObserver.ContextHasChanged(Context, ChangedVariable);
end;

constructor TDynamicTextField.TDynamicPart.Create(const Expression : string);
var
  Context : TExpressionContext;
begin
  FExpression := TExpression.Create(Expression);
  FExpressionObserver := TExpressionObserver.Create(FExpression);
  FExpressionObserver.OnExpressionNeedReEvaluation := ObserverSignalHandler;
  Context := TExpressionContext.Create;
  // init text with expression evaluate against empty context
  FText := GetString(Context);
  Context.Free;
end;

destructor TDynamicTextField.TDynamicPart.Destroy;
begin
  FExpressionObserver.Free;
  FExpression.Free;
  inherited;
end;

function TDynamicTextField.TDynamicPart.GetString(Context : TExpressionContext) : string;
var
  Value : TValue;
begin
  try
    Value := FExpression.Eval(Context);
  except
    on e : Exception do
    begin
      Value := TValue.Empty;
      HLog.Write(elDebug, 'TdXMLNode.TDynamicTextField.TDynamicPart.GetString: Cannot evaluate expression "%s". Error: %s', [FRawExpression, e.Message]);
    end;
  end;
  if not Value.IsEmpty then
  begin
    if Value.IsFloat then Result := FloatToStr(Value.AsExtended, EngineFloatFormatSettings)
    else Result := Value.ToString;
  end
  else
      Result := '';
end;

procedure TDynamicTextField.TDynamicPart.ObserverSignalHandler(Expression : TExpression; Context : TExpressionContext);
begin
  FText := GetString(Context);
  if assigned(FOnTextChanged) then
      FOnTextChanged();
end;

{ TExpressionObserver }

procedure TExpressionObserver.CallExpressionNeedReEvaluate;
begin
  if assigned(FOnExpressionNeedReEvaluation) then
      FOnExpressionNeedReEvaluation(FExpression, FContext);
end;

procedure TExpressionObserver.ContextHasChanged(NewContext : TExpressionContext; const ChangedVariable : string);
var
  ObserverNode : TObserverNode;
  ShouldReevaluate : boolean;
  temp : TExpressionContext;
begin
  temp := NewContext.Clone;
  ShouldReevaluate := False;
  for ObserverNode in FObserverNodes do
  begin
    ShouldReevaluate := ObserverNode.ContextHasChanged(temp, ChangedVariable) or ShouldReevaluate;
  end;
  if ShouldReevaluate then
  begin
    FContext.Free;
    FContext := temp;
    CallExpressionNeedReEvaluate;
  end
  else temp.Free;
end;

constructor TExpressionObserver.Create(const Expression : TExpression);
var
  Path : string;
begin
  FObserverNodes := TObjectList<TObserverNode>.Create();
  FExpression := Expression;
  FDependencies := TCaseInsensitiveDictionary<boolean>.Create;
  FContext := TExpressionContext.Create;
  for Path in Expression.GetVariableFullpaths do
  begin
    FObserverNodes.Add(TExpressionContextObserverNode.Create(Path.Split(['.']), self, FContext));
    FDependencies.AddOrSetValue(FObserverNodes.Last.ObservedPath[0], True);
  end;
end;

function TExpressionObserver.DependsOnVariableName(const VariableName : string) : boolean;
begin
  Result := VariableName.IsEmpty or FDependencies.ContainsKey(VariableName);
end;

destructor TExpressionObserver.Destroy;
begin
  FObserverNodes.Free;
  FContext.Free;
  FDependencies.Free;
  inherited;
end;

{ TdXMLNode.TAlias }

function TdXMLNode.TAlias.Clone : TAlias;
begin
  Result := TAlias.Create(FAlias + '=' + FOriginalValue.RawExpression);
end;

function TdXMLNode.TAlias.DependsOnVariable(const VariableName : string) : boolean;
begin
  Result := FObserver.DependsOnVariableName(VariableName);
end;

procedure TdXMLNode.TAlias.ContextChanged(Context : TExpressionContext; const ChangedVariable : string);
begin
  FObserver.ContextHasChanged(Context, ChangedVariable);
end;

constructor TdXMLNode.TAlias.Create(const Value : string);
var
  Parts : TArray<string>;
begin
  Parts := HString.Split(Value, ['='], False, 2);
  if length(Parts) <> 2 then
      raise EdXMLParseError.CreateFmt('TdXMLNode.TAlias.Create: Error in with expression "%s"', [Value]);
  FAlias := Parts[0].Trim;
  FOriginalValue := TExpression.Create(Parts[1]);
  FObserver := TExpressionObserver.Create(FOriginalValue);
  FObserver.OnExpressionNeedReEvaluation := ObserverHandler;
end;

destructor TdXMLNode.TAlias.Destroy;
begin
  FObserver.Free;
  FOriginalValue.Free;
  inherited;
end;

procedure TdXMLNode.TAlias.ObserverHandler(Expression : TExpression; Context : TExpressionContext);
begin
  FValue := Expression.Eval(Context);
  Context.AddOrSetValue(Alias, FValue);
  if assigned(FOnAliasValueHasChanged) then
      FOnAliasValueHasChanged(Context, self.Alias);
end;

{ dXMLDependency }

constructor dXMLDependency.Create(const Dependency : string);
begin
  FDependencies := [Dependency];
end;

constructor dXMLDependency.Create(const Dependency1, Dependency2 : string);
begin
  FDependencies := [Dependency1, Dependency2];
end;

constructor dXMLDependency.Create(const Dependency1, Dependency2, Dependency3 : string);
begin
  FDependencies := [Dependency1, Dependency2, Dependency3];
end;

constructor dXMLDependency.Create(const Dependency1, Dependency2, Dependency3, Dependency4 : string);
begin
  FDependencies := [Dependency1, Dependency2, Dependency3, Dependency4];
end;

{ TExpressionObserver.TObserverNode }

function TExpressionObserver.TObserverNode.ContextHasChanged(NewContext : TExpressionContext; const ChangedVariable : string) : boolean;
var
  Child : TObserverNode;
begin
  Result := False;
  for Child in FChildren do
      Result := Child.ContextHasChanged(NewContext, ChangedVariable) or Result;
end;

constructor TExpressionObserver.TObserverNode.Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; IsPartOfDependency : boolean);
begin
  FRttiContext := TRttiContext.Create;
  FObservedPath := ObservedPath;
  FRawPath := string.Join('.', ObservedPath);
  FOwner := Owner;
  FChildren := TObjectList<TObserverNode>.Create;
  FIsPartOfDependency := IsPartOfDependency;
end;

destructor TExpressionObserver.TObserverNode.Destroy;
begin
  FChildren.Free;
  FRttiContext.Free;
  inherited;
end;

procedure TExpressionObserver.TObserverNode.UpdateChildren(Instance : TObject);
var
  InstanceType : TRttiType;

  procedure ObserveMember(MemberPath : TArray<string>; IsPartOfDependency : boolean = False);
  var
    Dependencies : TArray<dXMLDependency>;
    Dependency : dXMLDependency;
    DependencyPath : string;
    MemberType : TRttiMember;
    UnifiedMember : TRttiMemberUnified;
  begin
    if InstanceType.TryGetMember(MemberPath[0], MemberType) then
    begin
      Dependencies := TArray<dXMLDependency>(HRtti.SearchForAttributes(dXMLDependency, MemberType.GetAttributes));

      // only observing published members
      if (MemberType.Visibility = mvPublished) then
      begin
        // for setter properties using specialized property observing class
        if (MemberType is TRttiProperty) and TRttiProperty(MemberType).UsingSetterMethod then
            FChildren.Add(TPropertyObserverNode.Create(MemberPath, FOwner, Instance, MemberType as TRttiProperty, IsPartOfDependency))
        else
        begin
          UnifiedMember := TRttiMemberUnified.Create(MemberType);
          // only observe list changes for dependencies or if list is part of an expression and not used directly e.g. within
          // a for loop, else list would be double observed (by expression observer and for loop node itself)
          if (IsPartOfDependency or (length(MemberPath) > 1)) and (UnifiedMember.MemberType is TRttiInstanceType) and
            (UnifiedMember.MemberType.Name.StartsWith('TUltimateList<', True) or
            UnifiedMember.MemberType.Name.StartsWith('TUltimateObjectList<', True)) then
          begin
            FChildren.Add(TListObserverNode.Create(MemberPath, FOwner, Instance, IsPartOfDependency));
          end
          // for anything else using a general observer that not really observe member instead only start observing for children
          else
              FChildren.Add(TMemberObserverNode.Create(MemberPath, FOwner, Instance, MemberType, IsPartOfDependency));
          UnifiedMember.Free;
        end;
      end;

      // additionally observe dependencies
      for Dependency in Dependencies do
      begin
        for DependencyPath in Dependency.Dependencies do
        begin
          // local or global dependency?
          // local!
          if DependencyPath.StartsWith('.') then
          begin
            ObserveMember(DependencyPath.Remove(0, 1).Split(['.']), True);
          end
          // global! (context)
          else
              FChildren.Add(TExpressionContextObserverNode.Create(DependencyPath.Split(['.']), FOwner, FOwner.FContext));
        end;
      end;
    end;
  end;

begin
  FChildren.Clear;
  // if there any member that needs to observed?
  if (length(FObservedPath) > 1) and assigned(Instance) then
  begin
    InstanceType := FRttiContext.GetType(Instance.ClassType);
    ObserveMember(Copy(FObservedPath, 1, length(FObservedPath) - 1), FIsPartOfDependency);
  end;
end;

{ TExpressionObserver.TExpressionContextObserverNode }

function TExpressionObserver.TExpressionContextObserverNode.ContextHasChanged(NewContext : TExpressionContext; const ChangedVariable : string) : boolean;
var
  Value : TValue;
begin
  if SameText(ChangedVariable, FObservedPath[0]) or ChangedVariable.IsEmpty then
  begin
    if NewContext.TryGetValue(FObservedPath[0], Value) and Value.IsObject then
        UpdateChildren(Value.AsObject)
    else
        FChildren.Clear;
    Result := True;
  end
  else
    // only pass new context to Children, if not already a changed was observed
      Result := inherited;
end;

constructor TExpressionObserver.TExpressionContextObserverNode.Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; Context : TExpressionContext);
var
  Value : TValue;
begin
  inherited Create(ObservedPath, Owner, False);
  if assigned(Context) and Context.TryGetValue(FObservedPath[0], Value) then
  begin
    if Value.IsObject then
        UpdateChildren(Value.AsObject);
  end
end;

{ TExpressionObserver.TPropertyObserverNode }

procedure TExpressionObserver.TPropertyObserverNode.AfterSetProperty(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; var Result : TValue);
var
  NewValue : TValue;
begin
  // was our property setter method called?
  if Method = FPropertySetterMethod then
  begin
    // warning, result containing not property value, in fact it will be empty because normally setter methods are procedures
    NewValue := FProperty.GetValue(Instance);
    if NewValue.IsObject then
    begin
      UpdateChildren(NewValue.AsObject);
    end;
    // notify about changed property value
    FOwner.CallExpressionNeedReEvaluate;
  end;
end;

procedure TExpressionObserver.TPropertyObserverNode.BeforeSetProperty(Instance : TObject; Method : TRttiMethod; const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
begin
  DoInvoke := True;

  if (Method = FPropertySetterMethod) then
  begin
    FChildren.Clear;
  end;
  // if SameText(Method.Name, 'BeforeDestruction') then
  // begin
  // if Assigned(FPropertySetterObserver) then
  // begin
  // VirtualMethodInterceptorManager.Unproxify(FInstance, FPropertySetterObserver);
  // FPropertySetterObserver := nil;
  // end;
  // end;
end;

constructor TExpressionObserver.TPropertyObserverNode.Create(ObservedPath : TArray<string>; Owner : TExpressionObserver;
ParentInstance : TObject; AProperty : TRttiProperty; IsPartOfDependency : boolean);
var
  SetterMethod : TRttiMethod;
  Value : TValue;
begin
  inherited Create(ObservedPath, Owner, IsPartOfDependency);
  // if property has an setter, observe it
  if AProperty.TryGetSetterMethod(SetterMethod) then
  begin
    if assigned(SetterMethod) and (SetterMethod.DispatchKind = dkVtable) then
    begin
      FInstance := ParentInstance;
      FProperty := AProperty;
      FPropertySetterMethod := SetterMethod;
      // if this codeblock is reached, all is find to finally start observing
      assert(not assigned(FPropertySetterObserver));
      FPropertySetterObserver := VirtualMethodInterceptorManager.Proxify(FInstance);
      FPropertySetterObserver.OnBefore := BeforeSetProperty;
      FPropertySetterObserver.OnAfter := AfterSetProperty;
    end
    else
        raise EInsufficientRtti.CreateFmt('TExpressionObserver.TPropertyObserverNode.Create: ' +
        'Settermethod for property "%s.%s" is not virtual or have insufficient rtti information.',
        [AProperty.Parent.Name, AProperty.Name]);
  end;
  // and start observing also for child
  Value := AProperty.GetValue(ParentInstance);
  if Value.IsObject then
      UpdateChildren(Value.AsObject)
end;

destructor TExpressionObserver.TPropertyObserverNode.Destroy;
begin
  if assigned(FPropertySetterObserver) then
  begin
    VirtualMethodInterceptorManager.Unproxify(FInstance, FPropertySetterObserver);
    FPropertySetterObserver := nil;
  end;
  inherited;
end;

{ TExpressionObserver.TListObserverNode }

procedure TExpressionObserver.TListObserverNode.AfterListChangedHandler(Instance : TObject; Method : TRttiMethod;
const Args : TArray<TValue>; var Result : TValue);
begin
  if SameText(Method.Name, 'NotifyChange') then
  begin
    assert(Instance = FListInstance);
    FOwner.CallExpressionNeedReEvaluate;
  end;
end;

procedure TExpressionObserver.TListObserverNode.BeforeListChangedHandler(Instance : TObject; Method : TRttiMethod;
const Args : TArray<TValue>; out DoInvoke : boolean; out Result : TValue);
var
  Action : EnumListAction;
  Items : TValue;
begin
  DoInvoke := True;
  if SameText(Method.Name, 'NotifyChange') then
  begin
    assert(Instance = FListInstance);
    Action := Args[1].AsType<EnumListAction>;
    Items := Args[0];
    UpdateItems(Items, Action);
  end;
end;

constructor TExpressionObserver.TListObserverNode.Create(ObservedPath : TArray<string>; Owner : TExpressionObserver;
ParentInstance : TObject; IsPartOfDependency : boolean);
begin
  inherited Create(ObservedPath, Owner, IsPartOfDependency);
  FItemsObserverMap := TDictionary<TObject, TObserverNode>.Create;

  // get list instance by path
  FListInstance := TValue(ParentInstance).Resolve(ObservedPath[0], []).AsObject;

  if assigned(FListInstance) then
  begin
    if not(FListInstance.ClassName.StartsWith('TUltimateList<', True) or
      FListInstance.ClassName.StartsWith('TUltimateObjectList<', True)) then
        raise ENotSupportedException.CreateFmt('TExpressionObserver.TListObserverNode.Create: Currently only TUltimateList or TUltimateObjectList can observed, class "%s" is not supported.',
        [FListInstance.ClassName]);

    assert(not assigned(FListObserver));

    FListObserver := VirtualMethodInterceptorManager.Proxify(FListInstance);
    // only need to handle List before changes
    // if Item properties should be observed
    if length(ObservedPath) > 1 then
    begin
      FListObserver.OnBefore := BeforeListChangedHandler;
      // start observing each existing item
      UpdateItems(FListInstance, laAddRange);
    end;
    FListObserver.OnAfter := AfterListChangedHandler;
  end;
end;

destructor TExpressionObserver.TListObserverNode.Destroy;
begin
  if assigned(FListInstance) then
  begin
    VirtualMethodInterceptorManager.Unproxify(FListInstance, FListObserver);
    FListObserver := nil;
  end;
  FItemsObserverMap.Free;
  inherited;
end;

procedure TExpressionObserver.TListObserverNode.UpdateItems(Items : TValue; Action : EnumListAction);
var
  ItemValue : TValue;
  Item : TObject;
  Observer : TObserverNode;
begin
  if Action = laClear then
  begin
    FItemsObserverMap.Clear;
    FChildren.Clear;
  end
  else
  begin
    for ItemValue in TValueEnumerator.Create(Items) do
    begin
      // pretests
      if not ItemValue.IsObject then
          raise ENotSupportedException.Create('TExpressionObserver.TListObserverNode.UpdateItems: Can only observe class instance children.');
      Item := ItemValue.AsObject;
      if assigned(Item) then
      begin
        if Action in [laAdd, laAddRange] then
        begin
          Observer := TObjectObserverNode.Create(FObservedPath, FOwner, Item);
          FChildren.Add(Observer);
          FItemsObserverMap.Add(Item, Observer);
        end
        else if Action in [laRemoved, laExtractedRange, laExtracted] then
        begin
          Observer := FItemsObserverMap[Item];
          FChildren.Remove(Observer);
          FItemsObserverMap.Remove(Item);
        end;
      end;
    end;
  end;
end;

{ TExpressionObserver.TMemberObserverNode }

constructor TExpressionObserver.TMemberObserverNode.Create(ObservedPath : TArray<string>; Owner : TExpressionObserver;
ParentInstance : TObject; AMember : TRttiMember; IsPartOfDependency : boolean);
var
  UnifiedMember : TRttiMemberUnified;
  Value : TValue;
begin
  inherited Create(ObservedPath, Owner, IsPartOfDependency);
  UnifiedMember := TRttiMemberUnified.Create(AMember);

  // and start observing for child
  Value := UnifiedMember.GetValue(ParentInstance);
  if Value.IsObject then
      UpdateChildren(Value.AsObject);
  UnifiedMember.Free;
end;

{ TExpressionObserver.TObjectObserverNode }

constructor TExpressionObserver.TObjectObserverNode.Create(ObservedPath : TArray<string>; Owner : TExpressionObserver; Instance : TObject);
begin
  inherited Create(ObservedPath, Owner, False);
  UpdateChildren(Instance);
end;

end.
