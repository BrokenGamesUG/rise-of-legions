unit Engine.Serializer;

interface

uses
  XMLDoc,
  XMLIntf,
  TypInfo,
  Generics.Collections,
  Classes,
  Rtti,
  System.Math,
  System.SysUtils,
  System.Variants,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Log,
  // Windows,
  System.ZLib,
  Engine.Serializer.Types,
  DateUtils;

const
  XMLDOCELEMENTPREFIX = 'element_';
  ERRORLEVEL          = 1;
  /// <summary> Determine which char is used to format Floats, e.g. '.' or ','
  /// Important: If you change this seperator, XML documents saved with another seperator might not be loaded correctly.</summary>
  XMLDECIMALSEPERATOR = ',';

type
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  /// <summary> Attribute for a class that inherits from TXMLSerializerClassLoader, setup the class for which that class works.</summary>
  XMLCustomClassSerializer = class(TCustomAttribute)
    strict private
      FTargetClassName : string;
    public
      property TargetClassName : string read FTargetClassName;
      constructor Create(TargetClassName : string);
  end;

  TXMLSerializer = class;

  /// <summary> Base class for every class that implements a custom load and save method for
  /// a class.</summary>
  TXMLCustomClassSerializer = class abstract
    protected
      FRttiContext : TRttiContext;
      FContext : TXMLSerializer;
      FObjectType : TRttiInstanceType;
      FTargetObject : TObject;
      /// <summary> Init serializer by update FObjectType and other fields. Requirement for GetMethod etc. </summary>
      function GetField(const FieldName : string) : TRttiField;
      function GetMethod(const MethodName : string) : TRttiMethod;
      function GetProperty(const PropertyName : string) : TRttiProperty;
      function GetIndexedProperty(const PropertyName : string) : TRttiIndexedProperty;
      function GetChildNode(const XMLNode : IXMLNode; const NodeName : string) : IXMLNode;
    public
      /// <summary> Initialize custom serializer and set target object that will be serialized.</summary>
      constructor Create(TargetObject : TObject; Context : TXMLSerializer); virtual;
      procedure Load(const XMLNode : IXMLNode); virtual;
      procedure Save(const XMLNode : IXMLNode); virtual;
      destructor Destroy; override;
  end;

  CXMLCustomClassSerializer = class of TXMLCustomClassSerializer;

  [XMLCustomClassSerializer('TList<T>')]
  [XMLCustomClassSerializer('TUltimateList<T>')]
  [XMLCustomClassSerializer('TAdvancedList<T>')]
  // base on TList and has no OwnsObjects property
  [XMLCustomClassSerializer('TUltimateObjectList<T>')]
  TXMLCustomListSerializer = class(TXMLCustomClassSerializer)
    protected const
      CURRENT_VERSION = '1.0';
    protected
      FItemType : TRttiType;
      FMethodAdd : TRttiMethod;
      FMethodClear : TRttiMethod;
      FPropertyItems : TRttiIndexedProperty;
      FPropertyCount : TRttiProperty;
      /// <summary> Loading types and method.</summary>
      procedure CallClear();
      procedure CallAdd(const Value : TValue);
      procedure LoadLegacy(const XMLNode : IXMLNode); virtual;
      procedure LoadV1_0(const XMLNode : IXMLNode); virtual;
      procedure SaveV1_0(const XMLNode : IXMLNode); virtual;
    public
      constructor Create(TargetObject : TObject; Context : TXMLSerializer); override;
      procedure Load(const XMLNode : IXMLNode); override;
      procedure Save(const XMLNode : IXMLNode); override;
  end;

  [XMLCustomClassSerializer('TObjectList<T>')]
  [XMLCustomClassSerializer('TAdvancedObjectList<T>')]
  TXMLCustomObjectListSerializer = class(TXMLCustomListSerializer)
    protected
      FPropertyOwnsObjects : TRttiProperty;
      procedure LoadLegacy(const XMLNode : IXMLNode); override;
      procedure LoadV1_0(const XMLNode : IXMLNode); override;
      procedure SaveV1_0(const XMLNode : IXMLNode); override;
    public
      constructor Create(TargetObject : TObject; Context : TXMLSerializer); override;
  end;

  [XMLCustomClassSerializer('TDictionary<T, U>')]
  TXMLCustomDictionarySerializer = class(TXMLCustomClassSerializer)
    protected const
      CURRENT_VERSION = '1.0';
    protected
      FKeyType : TRttiType;
      FValueType : TRttiType;
      FMethodAdd : TRttiMethod;
      FMethodClear : TRttiMethod;
      FMethodGetEnumerator : TRttiMethod;
      procedure CallClear();
      procedure CallAdd(const Key, Value : TValue);
      procedure LoadLegacy(const XMLNode : IXMLNode); virtual;
      procedure LoadV1_0(const XMLNode : IXMLNode); virtual;
      procedure SaveV1_0(const XMLNode : IXMLNode); virtual;
    public
      procedure Load(const XMLNode : IXMLNode); override;
      procedure Save(const XMLNode : IXMLNode); override;
      constructor Create(TargetObject : TObject; Context : TXMLSerializer); override;
  end;

  [XMLCustomClassSerializer('TObjectDictionary<T, U>')]
  TXMLCustomObjectDictionarySerializer = class(TXMLCustomDictionarySerializer)
    protected
      FFieldOwnerships : TRttiField;
      procedure LoadLegacy(const XMLNode : IXMLNode); override;
      procedure LoadV1_0(const XMLNode : IXMLNode); override;
      procedure SaveV1_0(const XMLNode : IXMLNode); override;
    public
      constructor Create(TargetObject : TObject; Context : TXMLSerializer); override;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  /// <summary> Class for serializing objects in to XML document.
  /// With attributes the serializer decide which fields and propertie are saved and loaded. The attributes are inherited to classchild,
  /// but same attributes overrides.
  /// Attributes are for example <see cref="XMLIncludeAll"/> or <see cref="XMLExcludeElement"/>. If some data for element is missing in XML-Node or file
  /// the serializer search for default value (attribute: <see cref="XMLDefaultValue"/>), nothing found: Element isn't changed.
  /// In case of classes without attributes, only all fields are saved and loaded.
  ///
  /// ATTENTION: Any type with partialname 'ArrayManager' will not be serialized to take account of delphi bug (TMoveArrayManager-bug)!!!!
  /// </summary>
  TXMLSerializer = class
    private type
      EnumElementType = (etClass, etField, etProperty);
      EnumElementCtrl = (ecNone, ecIncluded, ecExcluded);
    private
      // RTTI Context for all serializetasks
      class var FRttiContext : TRttiContext;
      class var FXMLDocumentCache : TDictionary<string, IXMLDocument>;
      // contains all custom serializer for classes
      class var FCustomClassSerializer : TDictionary<string, CXMLCustomClassSerializer>;
      class constructor Initialize;
      class destructor Finalize;
      class procedure ClearXMLDocumentCache; static;
      class function GetXMLDocumentFromFile(XMLFileName : string) : IXMLDocument;
      class procedure RegisterCustomClassSerializer(const CustomClassSerializer : CXMLCustomClassSerializer);
      /// <summary> Normalize classname by removing all namespace (System.Generics.Collections.TObjectList -> TObjectList),
      /// reduce GenericParameter to T, U,... (TDictionary<String, TArray<Integer>> -> TGenericType<T, U>),
      /// and finally convert all to lowercase.</summary>
      class function SanitizeClassName(const ClassName : string) : string;
    private
      // store references to objects to load a objectreference as a reference and not a new object
      FReferenceContainer : TDictionary<Integer, TObject>;
      // stores the identifier for each object (since identifier no longer calculated by object memory address)
      FReferenceMap : TDictionary<TObject, Integer>;
      // FOR SAVING ONLY, saves for every object the node where the object was saved
      FReferenceNodeMap : TObjectDictionary<TObject, TList<IXMLNode>>;
      // starts on 100'000
      FReferenceCounter : Integer;
      // store customData if exist to pass it over all ObjectConstructor
      FCustomData : TArray<TObject>;
      FCompressRawData : boolean;
      // get out which elementtyps (field, property) are saved
      procedure GetIncludedElementsFromAttributes(Attributes : TArray<TCustomAttribute>; var IncFields : boolean; var IncProperties : boolean);
      function GetElementControll(Attributes : TArray<TCustomAttribute>) : EnumElementCtrl;
      procedure SaveValueToNode(Value : TValue; RttiType : TRttiType; Node : IXMLNode; SaveAsRawData : boolean);
      procedure SaveStructTypeToNode(RefToStructType : Pointer; RttiType : TRttiType; Node : IXMLNode);
      procedure LoadStructTypeFromNode(RefToStructType : Pointer; RttiType : TRttiType; Node : IXMLNode);
      procedure LoadValueFromNode(var CurrentValue : TValue; RttiType : TRttiType; Node : IXMLNode);
      procedure GetArrayAsMemoryBlock(AArray : TValue; DestStream : TStream);
      procedure SetArrayFromMemoryBlock(AArray : TValue; MemoryBlock : TStream);
      function GetBaseType(AType : TRttiType) : TRttiType;
      // Calls all methods of deserialized class marked with XMLDeserializationCallback
      procedure CallDeserializationCallbacks(ObjectToLoad : TObject);
      // returns an unique identifier that stay the same if called same time
      // if object already in map, return saved identifier
      function GetReferenceIdentifier(const AObject : TObject) : Integer;
    public
      /// <summary> If true every opened to read XML Document isn't closed after reading and reused if adresserd another time.
      /// Default is True</summary>
      class var CacheXMLDocuments : boolean;
      /// <summary> Determine which errors are reported in error.log
      /// ReportErrorLevel = 0 -> no errors or warnings are reported
      /// ReportErrorLevel = 1 -> only errors are reported, no warnings
      /// ReportErrorLevel = 2 -> all undefined actions are reported, like unsupported types
      /// Default is 1 (set by constant ERRORLEVEL).</summary>
      class var ReportErrorLevel : Byte;
      /// <summary> LoadXMLFile into cache but dont create any object</summary>
      class procedure PreLoadXMLFile(Filename : string);
    public
      /// <summary> Content of a array with attribute <see cref="XMLRawData"/> is saved compressed with ZLib. This value
      /// only affect saving data. For loading a xmlattribute controll loaded data will decompressed or not.
      /// Default is True.</summary>
      property CompressRawData : boolean read FCompressRawData write FCompressRawData;
      constructor Create();
      destructor Destroy; override;
      /// <summary> Saves object to XML file.</summary>
      /// <param name="ObjectToSave"> Object which should saved in to XML File.</param>
      /// <param name="XMLFileName"> Path and filename to XMLFile.</param>
      procedure SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string); overload;
      procedure SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string; CustomData : array of TObject); overload;
      /// <summary> Saves object to XML-Node.</summary>
      /// <param name="ObjectToSave"> Object which is saved.</param>
      /// <param name="XMLNode"> In this XMLNode all Data from object are saved.</param>
      procedure SaveObjectToNode(ObjectToSave : TObject; XMLNode : IXMLNode; CustomData : array of TObject); overload;
      /// <summary> Create a object and load it from XML document.</summary>
      /// <param name="XMLNode"> Node From which Data is loaded.</param>
      /// <param name="CustomData"> Array of Custom Data, this data is hand to all ObjectConstructors
      /// which are called, accept this parametercount and types.</param>
      /// <returns> Returns the object with Data</returns>
      function CreateAndLoadObjectFromNode<T : class>(XMLNode : IXMLNode) : T; overload;
      function CreateAndLoadObjectFromNode(XMLNode : IXMLNode) : TObject; overload;
      function CreateAndLoadObjectFromNode<T : class>(XMLNode : IXMLNode; CustomData : array of TObject) : T; overload;
      function CreateAndLoadObjectFromNode(XMLNode : IXMLNode; CustomData : array of TObject) : TObject; overload;
      /// <summary> Create a object and load it from XML file.</summary>
      /// <param name="XMLFileName"> Path and filename for XML file from which data is loaded.</param>
      /// <returns> Returns the object with Data</returns>
      function CreateAndLoadObjectFromFile<T : class>(XMLFileName : string) : T; overload;
      function CreateAndLoadObjectFromFile(XMLFileName : string) : TObject; overload;
      function CreateAndLoadObjectFromFile<T : class>(XMLFileName : string; CustomData : array of TObject) : T; overload;
      function CreateAndLoadObjectFromFile(XMLFileName : string; CustomData : array of TObject; FailSilently : boolean = True) : TObject; overload;
      /// <summary> Load Data in to object (has to exist).</summary>
      /// <param name="XMLNode"> Node From which Data is loaded.</param>
      /// <param name="ObjectToLoad"> Object (not nil) to collect data. Existing data are replaced, if data exists in XML document.</param>
      procedure LoadObjectFromNode(XMLNode : IXMLNode; ObjectToLoad : TObject);
      /// <summary> Load Data in to object (has to exist).</summary>
      /// <param name="XMLNode"> Path and filename for XML file from which data is loaded.</param>
      /// <param name="ObjectToLoad"> Object (not nil) to collect data. Existing data are replaced, if data exists in XML file.</param>
      procedure LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string); overload;
      procedure LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string; CustomData : array of TObject); overload;

      procedure LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string); overload;
      procedure LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string; CustomData : array of TObject); overload;
  end;

  /// <summary> A class ihnerited from this class provide methods to load and save data to a XMLNode. This methods
  /// are used to customize the load and save process. However this DO NOT!!! disable the autosave and loading of the XMLSerializer.
  /// Instead use <see cref="XMLDisableAuto"/></summary>
  TXMLCustomSerializable = class abstract
    protected
      /// <summary> This methode is first called by TXMLSerializer to load data from class. After call, serializer will load data with default behavior.
      /// Customdata provide unknown data.</summary>
      constructor CustomXMLCreate(Node : TXMLNode; CustomData : array of TObject); virtual;
      /// <summary> This method is called by TXMLSerializer after instance ist created, but bevor ANY XML data is read. After this method, serializer will load data with default behavior.
      /// Customdata provide unknown data.</summary>
      procedure CustomXMLLoad(Node : TXMLNode; CustomData : array of TObject); virtual;
      /// <summary> On saving object, this Method first called by TXMLSerializer. After call, serializer will save data with default behavior.</summary>
      procedure CustomXMLSave(Node : TXMLNode; CustomData : array of TObject); virtual;
      /// <summary> Called after creation and loading from XML. </summary>
      procedure CustomAfterXMLCreate; virtual;
      /// <summary> Called after load and loading from XML. </summary>
      procedure CustomAfterXMLLoad(CustomData : array of TObject); virtual;
  end;

  CXMLCustomSerializable = class of TXMLCustomSerializable;

  HXMLSerializer = class
    public
      /// <summary> Saves object to XML file.</summary>
      /// <param name="ObjectToSave"> Object which should saved in to XML File.</param>
      /// <param name="XMLFileName"> Path and filename to XMLFile.</param>
      class procedure SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string); overload;
      class procedure SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string; CustomData : array of TObject); overload;
      /// <summary> Load Data in to object (has to exist).</summary>
      /// <param name="XMLNode"> Path and filename for XML file from which data is loaded.</param>
      /// <param name="ObjectToLoad"> Object (not nil) to collect data. Existing data are replaced, if data exists in XML file.</param>
      class procedure LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string); overload;
      class procedure LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string; CustomData : array of TObject); overload;

      class procedure LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string); overload;
      class procedure LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string; CustomData : array of TObject); overload;

      class function CreateAndLoadObjectFromFile<T : class>(XMLFileName : string) : T; overload;
  end;

  // return if Attribute is present in Attributes
function isAttributePresent(Attributes : TList<TCustomAttribute>; AttributeToSearch : TClass) : boolean; overload;
function isAttributePresent(Attributes : TArray<TCustomAttribute>; AttributeToSearch : TClass) : boolean; overload;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

function isAttributePresent(
  Attributes : TList<TCustomAttribute>; AttributeToSearch : TClass) : boolean;
var
  atr : TCustomAttribute;
begin
  Result := False;
  for atr in Attributes do
  begin
    if atr is AttributeToSearch then Exit(True);
  end;
end;

function isAttributePresent(Attributes : TArray<TCustomAttribute>; AttributeToSearch : TClass) : boolean;
var
  atr : TCustomAttribute;
begin
  Result := False;
  for atr in Attributes do
  begin
    if atr is AttributeToSearch then Exit(True);
  end;
end;

procedure TXMLSerializer.GetArrayAsMemoryBlock(AArray : TValue; DestStream : TStream);
  procedure WriteArrayData(Value : TValue);
  var
    hasArrayChilds : boolean;
    ArraySize, i : Integer;
  begin
    // if Arraylength 0, no need to save data, save only length
    if Value.GetArrayLength <= 0 then
    begin
      hasArrayChilds := False;
      DestStream.Write(hasArrayChilds, SizeOf(boolean));
      ArraySize := Value.GetArrayLength;
      DestStream.Write(ArraySize, SizeOf(Integer));
    end
    else
      // every array has at least 1 element, arrays with length 0 already dropped, check element 0 for arrayelementtypes
      case Value.GetArrayElement(0).Kind of
        tkArray, tkDynArray :
          begin
            hasArrayChilds := True;
            DestStream.Write(hasArrayChilds, SizeOf(boolean));
            ArraySize := Value.GetArrayLength;
            DestStream.Write(ArraySize, SizeOf(Integer));
            for i := 0 to ArraySize - 1 do WriteArrayData(Value.GetArrayElement(i));
          end
      else
        begin
          hasArrayChilds := False;
          DestStream.Write(hasArrayChilds, SizeOf(boolean));
          ArraySize := Value.GetArrayLength;
          DestStream.Write(ArraySize, SizeOf(Integer));
          DestStream.Write(Pointer(Value.GetReferenceToRawData^)^, Value.GetArrayElement(0).DataSize * ArraySize);
        end;
      end;
  end;

begin
  WriteArrayData(AArray);
end;

function TXMLSerializer.GetBaseType(AType : TRttiType) : TRttiType;
var
  Attributes : TArray<TCustomAttribute>;
begin
  // if no basetypetagging found, use type as is
  Result := AType;
  if not AType.IsInstance then Exit;
  repeat
    Attributes := AType.GetAttributes;
    // if <> nil type contains attribute -> use them!
    if HRtti.SearchForAttribute(XMLBaseClass, Attributes) <> nil then
    begin
      Result := AType;
      break;
    end
    // do not test type with no base type, bit tricky but useful, because only TObject has no basetype
    // and also don't need to be tested
    else AType := AType.BaseType;
  until AType.BaseType = nil;
end;

function TXMLSerializer.GetElementControll(Attributes : TArray<TCustomAttribute>) : EnumElementCtrl;
var
  atr : TCustomAttribute;
begin
  Result := ecNone;
  for atr in Attributes do
  begin
    if atr is XMLIncludeElement then Exit(ecIncluded);
    if atr is XMLExcludeElement then Exit(ecExcluded);
  end;
end;

procedure TXMLSerializer.GetIncludedElementsFromAttributes(Attributes : TArray<TCustomAttribute>; var IncFields : boolean; var IncProperties : boolean);
var
  Attribute : TCustomAttribute;
begin
  for Attribute in Attributes do
  begin
    if Attribute is XMLIncludeAll then
    begin
      if XMLIncludeOption.XMLIncludeFields in XMLIncludeAll(Attribute).Option then
          IncFields := True
      else
          IncFields := False;
      if XMLIncludeOption.XMLIncludeProperties in XMLIncludeAll(Attribute).Option then
          IncProperties := True
      else
          IncProperties := False;
      // if attribute found, older attributes doesn't matter
      Exit;
    end;
    if Attribute is XMLExcludeAll then
    begin
      IncFields := False;
      IncProperties := False;
      // if attribute found, older attributes doesn't matter
      Exit;
    end;
  end;
end;

function TXMLSerializer.GetReferenceIdentifier(const AObject : TObject) : Integer;
begin
  if not FReferenceMap.TryGetValue(AObject, Result) then
  begin
    Result := FReferenceCounter;
    FReferenceMap.Add(AObject, FReferenceCounter);
    inc(FReferenceCounter);
  end;
end;

class function TXMLSerializer.GetXMLDocumentFromFile(XMLFileName : string) : IXMLDocument;
begin
  if CacheXMLDocuments and FXMLDocumentCache.ContainsKey(AnsiUpperCase(XMLFileName)) then
  begin
    Result := FXMLDocumentCache[AnsiUpperCase(XMLFileName)];
  end
  else
  begin
    Result := NewXMLDocument();
    Result.Options := [doNodeAutoIndent];
    Result.LoadFromFile(XMLFileName);
    if CacheXMLDocuments then FXMLDocumentCache.Add(AnsiUpperCase(XMLFileName), Result);
  end;
end;

class constructor TXMLSerializer.Initialize;
begin
  CacheXMLDocuments := True;
  FRttiContext := TRttiContext.Create;
  ReportErrorLevel := ERRORLEVEL;
  FXMLDocumentCache := TDictionary<string, IXMLDocument>.Create();
  FCustomClassSerializer := TDictionary<string, CXMLCustomClassSerializer>.Create();
  RegisterCustomClassSerializer(TXMLCustomListSerializer);
  RegisterCustomClassSerializer(TXMLCustomObjectListSerializer);
  RegisterCustomClassSerializer(TXMLCustomDictionarySerializer);
  RegisterCustomClassSerializer(TXMLCustomObjectDictionarySerializer);
end;

class destructor TXMLSerializer.Finalize;
begin
  FRttiContext.Free;
  ClearXMLDocumentCache;
  FXMLDocumentCache.Free;
  FCustomClassSerializer.Free;
end;

procedure TXMLSerializer.LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string);
begin
  LoadObjectFromFile(ObjectToLoad, XMLFileName, []);
end;

procedure TXMLSerializer.LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string; CustomData : array of TObject);
var
  XMLDocument : IXMLDocument;
begin
  if not FileExists(XMLFileName) then
  begin
    if ReportErrorLevel >= 1 then HLog.Log('TXMLSerializer.LoadObject: XMLFile "' + XMLFileName + '" doesn''t exist.');
    Exit;
  end;
  // save CustomData
  FCustomData := HArray.ConvertDynamicToTArray<TObject>(CustomData);
  // New XML-Document
  XMLDocument := TXMLSerializer.GetXMLDocumentFromFile(XMLFileName);
  if XMLDocument.ChildNodes.Count < 1 then raise EInvalidXMLDoc.Create('TXMLSerializer.LoadObject: "XML document contains no nodes."');
  assert(XMLDocument.ChildNodes.Count = 2);
  LoadObjectFromNode(XMLDocument.DocumentElement, ObjectToLoad);
  XMLDocument := nil;
  // delete all loaded identifiers, because they invalid for further progressing
  FCustomData := nil;
end;

procedure TXMLSerializer.LoadObjectFromNode(XMLNode : IXMLNode; ObjectToLoad : TObject);
var
  RttiType : TRttiType;
  Identifier : Integer;
  CustomSerializer : TXMLCustomClassSerializer;
  CustomSerializerClass : CXMLCustomClassSerializer;
begin
  if XMLNode.HasAttribute('identifier') then
  begin
    Identifier := Integer(XMLNode.GetAttributeNS('identifier', ''));
    // add new object with old (from XML) identifier to RefrenzContainer
    if not FReferenceContainer.ContainsKey(Identifier) then
        FReferenceContainer.Add(Identifier, ObjectToLoad)
    else assert(FReferenceContainer[Identifier] = ObjectToLoad);
  end;
  RttiType := GetBaseType(FRttiContext.GetType(ObjectToLoad.ClassType));
  // any custom serializer for current class registered, use it instead of auto code
  if FCustomClassSerializer.TryGetValue(SanitizeClassName(RttiType.Name), CustomSerializerClass) then
  begin
    CustomSerializer := CustomSerializerClass.Create(ObjectToLoad, self);
    CustomSerializer.Load(XMLNode);
    CustomSerializer.Free;
  end
  else
  begin
    // test if class Inherits from TXMLCustomSerializable, then use the customload
    if ObjectToLoad is TXMLCustomSerializable then
    begin
      TXMLCustomSerializable(ObjectToLoad).CustomXMLLoad(XMLNode, FCustomData);
    end;

    LoadStructTypeFromNode(ObjectToLoad, RttiType, XMLNode);

    if ObjectToLoad is TXMLCustomSerializable then
    begin
      TXMLCustomSerializable(ObjectToLoad).CustomAfterXMLCreate;
      TXMLCustomSerializable(ObjectToLoad).CustomAfterXMLLoad(FCustomData);
    end;
    CallDeserializationCallbacks(ObjectToLoad);
  end;

  // if RttiType.Name.StartsWith('TList<') or RttiType.Name.StartsWith('TObjectList<') or RttiType.Name.StartsWith('TAdvancedObjectList<')
  // or RttiType.Name.StartsWith('TAdvancedList<') or RttiType.Name.StartsWith('TUltimateList<') or RttiType.Name.StartsWith('TUltimateObjectList<') then
  // begin
  // LoadList(RttiType.Name.StartsWith('TObjectList<') or RttiType.Name.StartsWith('TAdvancedObjectList<'){ or RttiType.Name.StartsWith('TUltimateObjectList<') has no field ownsObjects });
  // end
  // else if RttiType.Name.StartsWith('TDictionary<') or RttiType.Name.StartsWith('TObjectDictionary<') then
  // begin
  // LoadDict(RttiType.Name.StartsWith('TObjectDictionary<'));
  // end

end;

procedure TXMLSerializer.LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string; CustomData : array of TObject);
var
  XMLDocument : IXMLDocument;
begin
  // save CustomData
  FCustomData := HArray.ConvertDynamicToTArray<TObject>(CustomData);
  // New XML-Document
  XMLDocument := NewXMLDocument();
  XMLDocument.Options := [doNodeAutoIndent];
  XMLDocument.LoadFromXML(XMLContent);
  if XMLDocument.ChildNodes.Count < 1 then raise EInvalidXMLDoc.Create('TXMLSerializer.LoadObject: "XML document contains no nodes."');
  assert(XMLDocument.ChildNodes.Count = 2);
  LoadObjectFromNode(XMLDocument.DocumentElement, ObjectToLoad);
  XMLDocument := nil;
  // delete all loaded identifiers, because they invalid for further progressing
  FCustomData := nil;
end;

procedure TXMLSerializer.LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string);
begin
  LoadObjectFromString(ObjectToLoad, XMLContent, []);
end;

procedure TXMLSerializer.LoadStructTypeFromNode(RefToStructType : Pointer;
  RttiType : TRttiType; Node : IXMLNode);
var
  Field : TRttiField;
  Prop : TRttiProperty;
  Offset : Integer;

  procedure LoadElementFromNode(Element : TRttiMember; ElementTyp : EnumElementType; Node : IXMLNode);
  var
    Attribute : TCustomAttribute;
    ElementCtrl : EnumElementCtrl;
    ElementNode : IXMLNode;
    ElementRttiType : TRttiType;
    ElementValue : TValue;
    IncFields, IncProperties : boolean;
    Attributes : TArray<TCustomAttribute>;
    CurrentParent : TRttiType;
    i : Integer;
  begin
    // standard values for saving
    IncFields := True;
    IncProperties := False;
    // if direct parent has no attributes, search for prarent and so on for attribute
    // stop if attributes was found or parent = TObject
    Attributes := nil;
    CurrentParent := Element.Parent;
    while (CurrentParent <> nil) and (Attributes = nil) and (CurrentParent.Name <> 'TObject') do
    begin
      Attributes := CurrentParent.GetAttributes;
      CurrentParent := CurrentParent.BaseType;
    end;
    GetIncludedElementsFromAttributes(Attributes, IncFields, IncProperties);
    // locate attributes for serializing controll
    ElementCtrl := GetElementControll(Element.GetAttributes);
    // if elementcontroll or classcontroll includ it, serialize it!
    if (((IncFields and (ElementTyp = etField)) or (IncProperties and (ElementTyp = etProperty))) and not(ElementCtrl = ecExcluded)) or (ElementCtrl = ecIncluded) then
    begin
      ElementRttiType := nil;
      // catch invalid (no typeinformations) elements, exit if some found
      case ElementTyp of
        etField : ElementRttiType := TRttiField(Element).FieldType;
        etProperty : ElementRttiType := TRttiProperty(Element).propertyType;
      end;
      if ElementRttiType = nil then
      begin
        if ReportErrorLevel >= 1 then HLog.Log('TXMLSerializer.LoadStructTypeFromNode: Exist no typeinfo for element "' + Element.Name + '".');
        Exit;
      end;

      ElementNode := nil;
      // use custom search instead of ElementNode := Node.ChildNodes.FindNode(Element.Name) to make a case insensitive search
      for i := 0 to Node.ChildNodes.Count - 1 do
      begin
        ElementNode := Node.ChildNodes.Get(i);
        if CompareText(ElementNode.NodeName, Element.Name) = 0 then
            break
        else
            ElementNode := nil;
      end;
      // if elementNode exist, load value from XMLNode
      if (ElementNode <> nil) then
      begin
        case ElementTyp of
          etProperty :
            begin
              ElementValue := TRttiProperty(Element).GetValue(RefToStructType);
              LoadValueFromNode(ElementValue, ElementRttiType, ElementNode);
              TRttiProperty(Element).SetValue(RefToStructType, ElementValue);
            end;
          etField :
            begin
              ElementValue := TRttiField(Element).GetValue(RefToStructType);
              LoadValueFromNode(ElementValue, ElementRttiType, ElementNode);
              TRttiField(Element).SetValue(RefToStructType, ElementValue);
            end;
        end;
      end
      // if elementNode doesn't exist, XMLDocument doesn't contain data, attempt to load DefaultValue
      else
      begin
        for Attribute in Element.GetAttributes do
          // if a default Value was found
          if Attribute is XMLDefaultValue then
          begin
            // load it
            case ElementTyp of
              etProperty :
                TRttiProperty(Element).SetValue(RefToStructType, XMLDefaultValue(Attribute).DefaultValueAsTValue);
              etField :
                TRttiField(Element).SetValue(RefToStructType, XMLDefaultValue(Attribute).DefaultValueAsTValue);
            end;
            // and stop searching, older default values doesn't matter
            break;
          end;
      end;
    end;
  end;

begin
  // if XMLDisableAuto is present, autoload is disable -> STOP IT!!!
  if isAttributePresent(RttiType.GetAttributes, XMLDisableAuto) then
  begin
    Exit;
  end;
  // Load all fields
  // if type is record, test offset to avoid load content of a variant record twice
  if RttiType.IsRecord then
  begin
    Offset := -1;
    for Field in RttiType.GetFields do
      if Offset < Field.Offset then
      begin
        Offset := Field.Offset;
        LoadElementFromNode(Field, etField, Node);
      end
  end
  else
    for Field in RttiType.GetFields do
    begin
      LoadElementFromNode(Field, etField, Node);
    end;

  // Load all properties
  for Prop in RttiType.GetProperties do
  begin
    // skip all read only properties
    if Prop.IsWritable then
        LoadElementFromNode(Prop, etProperty, Node);
  end;
end;

procedure TXMLSerializer.LoadValueFromNode(var CurrentValue : TValue; RttiType : TRttiType; Node : IXMLNode);
var
  i : Integer;
  arrayNode : IXMLNode;
  arrayValue : TValue;
  ArraySize, EnumValue, ErrorCode : Integer;
  LoadAsRawData, RawDataIsCompressed : boolean;
  Data : AnsiString;
  myFormatSettings : TFormatSettings;
  MemoryStreamRawData : TMemoryStream;
  DeCompressStream : TZDecompressionStream;
begin
  // load data to XML depend on type
  case RttiType.TypeKind of
    tkUnknown : raise ERttiSerializeError.Create('TXMLSerializer.LoadValueFromNode: Can''t assign type for ' + RttiType.Name + '. For this reason value not loaded.');
    tkInteger :
      begin
        // tkInteger is not inconclusively value = integer, also cardinal, byte etc possible
        assert(RttiType.IsOrdinal);
        case RttiType.AsOrdinal.OrdType of
          otSByte : CurrentValue := ShortInt(Node.NodeValue);
          otUByte : CurrentValue := Byte(Node.NodeValue);
          otSWord : CurrentValue := SmallInt(Node.NodeValue);
          otUWord : CurrentValue := Word(Node.NodeValue);
          otSLong : CurrentValue := LongInt(Node.NodeValue);
          // oleVariant converts every integer to type integer, even if values bigger like cardinal
          // so custom conversion is needed
          otULong : CurrentValue := LongWord(StrToInt64(Node.NodeValue));
        end;
      end;
    tkChar, tkWChar : CurrentValue := TValue.From<Char>(string(Node.NodeValue)[1]);
    // recognise a ordinal enumvalue from stringrepresentation
    tkEnumeration :
      begin
        Val(Node.NodeValue, EnumValue, ErrorCode);
        if ErrorCode = 0 then
            CurrentValue := TValue.FromOrdinal(CurrentValue.TypeInfo, EnumValue)
        else
            CurrentValue := TValue.FromOrdinal(CurrentValue.TypeInfo, GetEnumValue(CurrentValue.TypeInfo, Node.NodeValue));
      end;
    tkFloat :
      begin
        myFormatSettings := TFormatSettings.Create('en-US');
        myFormatSettings.DecimalSeparator := XMLDECIMALSEPERATOR;
        CurrentValue := StrToFloat(Node.Text, myFormatSettings);
      end;
    tkString, tkWString, tkLString, tkUString : if VarIsNull(Node.NodeValue) then CurrentValue := ''
      else CurrentValue := string(Node.NodeValue);
    tkSet : TValue.Make(StringToSet(CurrentValue.TypeInfo, Node.NodeValue), CurrentValue.TypeInfo, CurrentValue);
    tkClass : if CurrentValue.IsEmpty then CurrentValue := CreateAndLoadObjectFromNode(Node, FCustomData)
      else LoadObjectFromNode(Node, CurrentValue.AsObject);
    tkVariant : CurrentValue := TValue.From<Variant>(Node.NodeValue);
    tkArray, tkDynArray :
      begin
        // check for correct XML-Array-Node and get arraysize
        if (Node.HasAttribute('type') and (string(Node.GetAttributeNS('type', '')) = 'array')) and Node.HasAttribute('size') then ArraySize := Integer(Node.GetAttributeNS('size', ''))
        else
        begin
          if ReportErrorLevel >= 1 then HLog.Log('TXMLSerializer.LoadValueFromNode: Node "' + Node.NodeName + '" is invalid arraynode.');
          Exit;
        end;
        // check if data is in raw format and rawdata is compressed
        LoadAsRawData := Node.HasAttribute('rawData') and (boolean(Node.GetAttributeNS('rawData', '')) = True);
        RawDataIsCompressed := Node.HasAttribute('compressed') and (boolean(Node.GetAttributeNS('compressed', '')) = True);
        // set arraylength if dynamic or check if staticarray
        if RttiType.TypeKind = tkDynArray then DynArraySetLength(Pointer(CurrentValue.GetReferenceToRawData^), CurrentValue.TypeInfo, 1, @ArraySize)
        else if CurrentValue.GetArrayLength <> ArraySize then raise EXMLSerializeError.Create('TXMLSerializer.LoadValueFromNode: Arraysize from staticarray and saved value doesn''t match.');
        if LoadAsRawData then
        begin
          MemoryStreamRawData := TMemoryStream.Create;
          // load Data into MemoryStream
          Data := DecodeBase64(AnsiString(Node.Text));
          MemoryStreamRawData.Write(Data[1], Length(Data));
          MemoryStreamRawData.Position := 0;
          if RawDataIsCompressed then
          begin
            DeCompressStream := TZDecompressionStream.Create(MemoryStreamRawData);
            SetArrayFromMemoryBlock(CurrentValue, DeCompressStream);
            DeCompressStream.Free;
          end
          else
          begin
            SetArrayFromMemoryBlock(CurrentValue, MemoryStreamRawData);
          end;
          MemoryStreamRawData.Free;
          Data := '';
        end
        else
          for i := 0 to ArraySize - 1 do
          begin
            arrayNode := Node.ChildNodes.FindNode(XMLDOCELEMENTPREFIX + IntToStr(i));
            if arrayNode = nil then
            begin
              if ReportErrorLevel >= 1 then HLog.Log('TXMLSerializer.LoadValueFromNode: Element doesn''t exists in XMLDocument.');
              continue;
            end;
            arrayValue := CurrentValue.GetArrayElement(i);
            LoadValueFromNode(arrayValue, FRttiContext.GetType(arrayValue.TypeInfo), arrayNode);
            CurrentValue.SetArrayElement(i, arrayValue);
          end;
      end;
    tkRecord : LoadStructTypeFromNode(CurrentValue.GetReferenceToRawData, RttiType, Node);
    tkInt64 : CurrentValue := Int64(Node.NodeValue);
    tkClassRef, tkInterface : if ReportErrorLevel >= 2 then HLog.Log('TXMLSerializer.LoadValueFromNode: Not yet supported.');
    tkPointer, tkProcedure, tkMethod : if ReportErrorLevel >= 2 then HLog.Log('TXMLSerializer.LoadValueFromNode: Can''t load referenztype, e.g. pointer, method.');
  end;
end;

class procedure TXMLSerializer.PreLoadXMLFile(Filename : string);
begin
  GetXMLDocumentFromFile(Filename);
end;

class procedure TXMLSerializer.RegisterCustomClassSerializer(const CustomClassSerializer : CXMLCustomClassSerializer);
var
  Attribute : TCustomAttribute;
  Attributes : TArray<TCustomAttribute>;
begin
  Attributes := HRtti.GetAttributes(CustomClassSerializer, XMLCustomClassSerializer);
  if Length(Attributes) <= 0 then
      raise EXMLSerializeError.Create('TXMLSerializer.RegisterCustomClassSerializer: Can''t register the custom serializer "'
      + CustomClassSerializer.ClassName + '" without any target class.');

  for Attribute in Attributes do
      FCustomClassSerializer.Add(SanitizeClassName(XMLCustomClassSerializer(Attribute).TargetClassName), CustomClassSerializer);
end;

procedure TXMLSerializer.CallDeserializationCallbacks(ObjectToLoad : TObject);
var
  RttiType : TRttiType;
  RttiMethod : TRttiMethod;
begin
  RttiType := FRttiContext.GetType(ObjectToLoad.ClassType);
  // Search for all methods marked with the XMLDeserializationCallback attribute
  for RttiMethod in RttiType.GetMethods do
    if HRtti.HasAttribute(RttiMethod.GetAttributes, XMLDeserializationCallback) then
        RttiMethod.Invoke(ObjectToLoad, []);
end;

class procedure TXMLSerializer.ClearXMLDocumentCache;
var
  Key : string;
begin
  for Key in TXMLSerializer.FXMLDocumentCache.Keys do
  begin
    TXMLSerializer.FXMLDocumentCache[Key] := nil;
  end;
end;

constructor TXMLSerializer.Create;
begin
  FReferenceContainer := TDictionary<Integer, TObject>.Create();
  FReferenceContainer.Add(0, nil);
  FReferenceMap := TDictionary<TObject, Integer>.Create();
  FReferenceMap.Add(nil, 0);
  FReferenceCounter := 100000;
  FReferenceNodeMap := TObjectDictionary < TObject, TList < IXMLNode >>.Create([doOwnsValues]);
  CompressRawData := True;
end;

function TXMLSerializer.CreateAndLoadObjectFromFile(XMLFileName : string) : TObject;
begin
  Result := CreateAndLoadObjectFromFile(XMLFileName, []);
end;

function TXMLSerializer.CreateAndLoadObjectFromFile<T>(XMLFileName : string) : T;
begin
  Result := T(CreateAndLoadObjectFromFile(XMLFileName));
end;

function TXMLSerializer.CreateAndLoadObjectFromNode(XMLNode : IXMLNode) : TObject;
begin
  Result := CreateAndLoadObjectFromNode(XMLNode, []);
end;

function TXMLSerializer.CreateAndLoadObjectFromNode<T>(XMLNode : IXMLNode) : T;
begin
  Result := T(CreateAndLoadObjectFromNode(XMLNode));
end;

function TXMLSerializer.CreateAndLoadObjectFromFile(XMLFileName : string; CustomData : array of TObject; FailSilently : boolean) : TObject;
var
  XMLDocument : IXMLDocument;
  i : Integer;
  fnferror : string;
begin
  if not FileExists(XMLFileName) then
  begin
    fnferror := 'TXMLSerializer.CreateAndLoadObject: XMLFile "' + XMLFileName + '" doesn''t exist.';
    if ReportErrorLevel >= 1 then HLog.Log(fnferror);
    if not FailSilently then
        raise EFileNotFoundException.Create(fnferror);
    Exit(nil);
  end;
  // save CustomData
  setlength(FCustomData, Length(CustomData));
  for i := 0 to Length(CustomData) - 1 do FCustomData[i] := CustomData[i];
  // New XML-Document
  XMLDocument := TXMLSerializer.GetXMLDocumentFromFile(XMLFileName);
  if XMLDocument.ChildNodes.Count < 1 then
      raise EInvalidXMLDoc.Create('TXMLSerializer.CreateAndLoadObject: "XML document contains no nodes."');
  assert(XMLDocument.ChildNodes.Count = 2);
  Result := CreateAndLoadObjectFromNode(XMLDocument.ChildNodes[1], CustomData);
  XMLDocument := nil;
  FCustomData := nil;
end;

function TXMLSerializer.CreateAndLoadObjectFromFile<T>(
  XMLFileName : string; CustomData : array of TObject) : T;
begin
  Result := T(CreateAndLoadObjectFromFile(XMLFileName, CustomData));
end;

function TXMLSerializer.CreateAndLoadObjectFromNode(XMLNode : IXMLNode; CustomData : array of TObject) : TObject;
var
  RttiType : TRttiInstanceType;
  Identifier, ParamLength, i : Integer;
  ClassName : string;
  CreateMethod, method : TRttiMethod;
  CreateParameter : TArray<TValue>;
  MethodParameter : TArray<TRTTIParameter>;
begin
  // type attribute is necessary for locating class to create instance, if it doesn't exists -> exit
  if not XMLNode.HasAttribute('type') then
  begin
    if ReportErrorLevel >= 2 then HLog.Log('TXMLSerializer.CreateAndLoadObjectFromNode: Node has no type attribute.');
    Exit(nil);
  end
  else ClassName := XMLNode.GetAttributeNS('type', '');
  // creates instance from class
  RttiType := FRttiContext.FindType(ClassName).AsInstance;
  // nil RttiType, Class couldn't find
  if RttiType = nil then
  begin
    if ReportErrorLevel >= 1 then HLog.Log('TXMLSerializer.CreateAndLoadObjectFromNode: Cann''t find class "' + ClassName + '""');
    Exit(nil);
  end;

  // if identifier already exists, return referenz and doesn't create new object
  if XMLNode.HasAttribute('identifier') then
  begin
    Identifier := Integer(XMLNode.GetAttributeNS('identifier', ''));
    if FReferenceContainer.ContainsKey(Identifier) then
        Exit(FReferenceContainer[Identifier]);
  end;

  // test if class Inherits from TXMLCustomSerializable, then use the constructor
  if RttiType.MetaclassType.InheritsFrom(TXMLCustomSerializable) then
  begin
    Result := CXMLCustomSerializable(RttiType.MetaclassType).CustomXMLCreate(XMLNode, CustomData);
  end
  else
  begin
    setlength(CreateParameter, 0);
    CreateMethod := nil;
    ParamLength := MaxInt;
    for method in RttiType.GetMethods do
    begin
      if SameText(method.Name, 'create') then
      begin
        MethodParameter := method.GetParameters;
        // if parameters matches exactly call creator if types are matching
        if (Length(CustomData) = Length(MethodParameter)) and (Length(MethodParameter) <> 0) then
        begin
          setlength(CreateParameter, 0);
          for i := 0 to Length(MethodParameter) - 1 do
            if (MethodParameter[i].ParamType.TypeKind = FRttiContext.GetType(CustomData[i].ClassType).TypeKind) and
              ((MethodParameter[i].ParamType.TypeKind <> tkClass) or (MethodParameter[i].ParamType.QualifiedName = CustomData[i].QualifiedClassName))
            then
            begin
              setlength(CreateParameter, Length(CreateParameter) + 1);
              CreateParameter[i] := TValue.From(CustomData[i]);
            end
            else
            begin
              break;
            end;
          if Length(CreateParameter) = Length(MethodParameter) then
          begin
            CreateMethod := method;
            break;
          end;
        end;
        if ParamLength > Length(MethodParameter) then
        begin
          ParamLength := Length(MethodParameter);
          CreateMethod := method;
        end;
      end;
    end;
    // no identifier, load Object with standard constructor
    if CreateMethod = nil then raise Exception.Create('TXMLSerializer.CreateAndLoadObjectFromNode: Can''f find create constructor.');
    Result := CreateMethod.Invoke(RttiType.MetaclassType, CreateParameter).AsObject;
    CreateParameter := nil;
  end;
  // load data in to instance
  LoadObjectFromNode(XMLNode, Result);
end;

function TXMLSerializer.CreateAndLoadObjectFromNode<T>(XMLNode : IXMLNode; CustomData : array of TObject) : T;
begin
  Result := T(CreateAndLoadObjectFromNode(XMLNode, CustomData));
end;

destructor TXMLSerializer.Destroy;
begin
  FReferenceContainer.Free;
  FReferenceMap.Free;
  FReferenceNodeMap.Free;
  inherited;
end;

procedure TXMLSerializer.SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string);
begin
  SaveObjectToFile(ObjectToSave, XMLFileName, []);
end;

class function TXMLSerializer.SanitizeClassName(const ClassName : string) : string;
var
  ClassNameParts, GenericParameterSamples : TArray<string>;
  Item : string;
  StackDepth, GenericParamCount, LastPoint : Integer;
begin
  assert(not ClassName.IsEmpty);
  StackDepth := 0;
  GenericParamCount := 0;
  ClassNameParts := HString.Split(ClassName, ['<', '>', ','], True);
  // count the generic parameter count of given classname (0 or greater), but only for the topmost
  // parameter, so ignore all nested generic parameter like TList<TList<String>> (will return GenericParamCount = 1)
  for Item in ClassNameParts do
  begin
    if Item = '<' then
    begin
      inc(StackDepth);
      // first open < signals also the first parameter
      if StackDepth = 1 then
          inc(GenericParamCount);
    end
    else if Item = '>' then
        dec(StackDepth)
      // another item within topmost < > pair found -> Generic Parameter
    else if (Item = ',') and (StackDepth = 1) then
        inc(GenericParamCount);
  end;
  // classname part without generic parameter (but with namespace) is before first <
  Result := ClassNameParts[0];
  // clear classname from namespaces
  LastPoint := Result.LastIndexOf('.');
  // is there a namespace? -> remove it
  if LastPoint > -1 then
  begin
    Result := Result.Remove(LastPoint, LastPoint + 1);
  end;
  // normalize the Generic Parameters, by using unfified parameter names, so TList<String> -> TList<T>
  if GenericParamCount > 0 then
  begin
    GenericParameterSamples := ['T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
    assert(Length(GenericParameterSamples) >= GenericParamCount);
    Result := Result + '<' + string.Join(',', GenericParameterSamples, 0, GenericParamCount) + '>';
  end;
  Result := Result.ToLowerInvariant;
end;

procedure TXMLSerializer.SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string; CustomData : array of TObject);
var
  Node : IXMLNode;
  Nodes : TList<IXMLNode>;
  XMLDocument : IXMLDocument;
  NodeIdentifier : string;
  Identifier : Integer;
  AObject : TObject;
  function CleanString(DirtyString : string) : string;
  var
    DirtyCharPos : Integer;
  begin
    Result := DirtyString;
    DirtyCharPos := Pos('<', DirtyString);
    if DirtyCharPos > 0 then
        Delete(Result, DirtyCharPos, Length(DirtyString) - DirtyCharPos + 1);
  end;

begin
  if ObjectToSave = nil then
  begin
    if ReportErrorLevel >= 1 then HLog.Log('TXMLSerializer.SaveObject: Object is nil, can''t save it.');
    Exit;
  end;

  // New XML-Document
  XMLDocument := NewXMLDocument();
  XMLDocument.Options := [doNodeAutoIndent];

  NodeIdentifier := CleanString(ObjectToSave.ClassName);
  // Add node and save objectcontent
  Node := XMLDocument.AddChild(NodeIdentifier);
  SaveObjectToNode(ObjectToSave, Node, CustomData);

  // if a object is refenced more then one time, add identifier attribute to every
  // xmlnode of this object
  for AObject in FReferenceNodeMap.Keys do
  begin
    Nodes := FReferenceNodeMap[AObject];
    if Nodes.Count > 1 then
    begin
      Identifier := GetReferenceIdentifier(AObject);
      for Node in Nodes do
          Node.SetAttributeNS('identifier', '', Identifier);
    end;
  end;

  XMLDocument.SaveToFile(XMLFileName);

  XMLDocument := nil;
end;

procedure TXMLSerializer.SaveObjectToNode(ObjectToSave : TObject; XMLNode : IXMLNode; CustomData : array of TObject);
var
  RttiType : TRttiType;
  Identifier : Integer;
  CustomSerializer : TXMLCustomClassSerializer;
  CustomSerializerClass : CXMLCustomClassSerializer;
begin
  FCustomData := HArray.ConvertDynamicToTArray<TObject>(CustomData);
  Identifier := GetReferenceIdentifier(ObjectToSave);
  RttiType := GetBaseType(FRttiContext.GetType(ObjectToSave.ClassType));
  // save classtype in XML attribute
  XMLNode.SetAttributeNS('type', '', RttiType.QualifiedName);
  if not FReferenceNodeMap.ContainsKey(ObjectToSave) then
      FReferenceNodeMap.Add(ObjectToSave, TList<IXMLNode>.Create);
  // if a object is saved, save the xml node for it, need a list of xml nodes because
  // maybe object is refenced more than one
  FReferenceNodeMap[ObjectToSave].Add(XMLNode);

  // if identifier already exists, don't save object to prevent crossreferences
  if not FReferenceContainer.ContainsKey(Identifier) then
  begin
    FReferenceContainer.Add(Identifier, ObjectToSave);
    // any custom serializer for current class registered, use it instead of auto code
    if FCustomClassSerializer.TryGetValue(SanitizeClassName(RttiType.Name), CustomSerializerClass) then
    begin
      CustomSerializer := CustomSerializerClass.Create(ObjectToSave, self);
      CustomSerializer.Save(XMLNode);
      CustomSerializer.Free;
    end
    else
    begin
      // if TXMLCustomSerializable use the savemethod first
      if ObjectToSave is TXMLCustomSerializable then TXMLCustomSerializable(ObjectToSave).CustomXMLSave(XMLNode, CustomData);
      SaveStructTypeToNode(ObjectToSave, RttiType, XMLNode);
    end;
  end;
end;

procedure TXMLSerializer.SaveStructTypeToNode(RefToStructType : Pointer; RttiType : TRttiType; Node : IXMLNode);
var
  Field : TRttiField;
  Prop : TRttiProperty;
  Offset : Integer;

  procedure SaveElementToNode(Element : TRttiMember; ElementType : EnumElementType; Node : IXMLNode);
  var
    IncFields, IncProperties : boolean;
    ElementCtrl : EnumElementCtrl;
    ElementNode : IXMLNode;
    ElementRttiType : TRttiType;
    SaveAsRawData : boolean;
    Attributes : TArray<TCustomAttribute>;
    CurrentParent : TRttiType;
  begin
    // standard values for saving
    IncFields := True;
    IncProperties := False;
    // if direct parent has no attributes, search for prarent and so on for attribute
    // stop if attributes was found or parent = TObject
    Attributes := nil;
    CurrentParent := Element.Parent;
    while (CurrentParent <> nil) and (Attributes = nil) and (CurrentParent.Name <> 'TObject') do
    begin
      Attributes := CurrentParent.GetAttributes;
      CurrentParent := CurrentParent.BaseType
    end;
    GetIncludedElementsFromAttributes(Attributes, IncFields, IncProperties);
    // locate attributes for serializing controll
    ElementCtrl := GetElementControll(Element.GetAttributes);
    SaveAsRawData := isAttributePresent(Element.GetAttributes, XMLRawData);
    ElementRttiType := nil;
    // catch invalid (no typeinformations) elements, exit if some found
    case ElementType of
      etField : ElementRttiType := TRttiField(Element).FieldType;
      etProperty : ElementRttiType := TRttiProperty(Element).propertyType;
    end;
    // if elementcontroll or classcontroll includ it, serialize it!
    if ((((IncFields and (ElementType = etField)) or (IncProperties and (ElementType = etProperty)))
      and not(ElementCtrl = ecExcluded)) or (ElementCtrl = ecIncluded)) and not(assigned(ElementRttiType) and (ElementRttiType.Name.IndexOf('ArrayManager') >= 0)) then
    begin
      if ElementRttiType = nil then
      begin
        if ReportErrorLevel >= 1 then HLog.Log('TXMLSerializer.SaveStructTypeToNode: Exist no typeinfo for element "' + Element.Name + '".');
        Exit;
      end;

      ElementNode := Node.AddChild(Element.Name);

      // if elementNode exist, save value into XMLNode
      if (ElementNode <> nil) then
      begin
        case ElementType of
          etProperty : SaveValueToNode(TRttiProperty(Element).GetValue(RefToStructType), ElementRttiType, ElementNode, SaveAsRawData);
          etField : SaveValueToNode(TRttiField(Element).GetValue(RefToStructType), ElementRttiType, ElementNode, SaveAsRawData);
        end;
      end
      // if elementNode doesn't exist, a error occur on create it
      else raise EInvalidXMLDoc.Create('TXMLSerializer.SaveStructTypeToNode: Error on creating a childnode.');
    end;
  end;

begin

  // if XMLDisableAuto is present, autosave is disabled -> STOP IT!!!
  if isAttributePresent(RttiType.GetAttributes, XMLDisableAuto) then
  begin
    Exit;
  end;
  // Save all fields
  // if type is record, test offset to avoid save content of a variant record twice
  if RttiType.IsRecord then
  begin
    Offset := -1;
    for Field in RttiType.GetFields do
      if Offset < Field.Offset then
      begin
        Offset := Field.Offset;
        SaveElementToNode(Field, etField, Node);
      end
  end
  else
  begin
    for Field in RttiType.GetFields do
    begin
      SaveElementToNode(Field, etField, Node);
    end;
  end;

  // Save all properties
  for Prop in RttiType.GetProperties do
  begin
    SaveElementToNode(Prop, EnumElementType.etProperty, Node);
  end;
end;

procedure TXMLSerializer.SaveValueToNode(Value : TValue; RttiType : TRttiType; Node : IXMLNode; SaveAsRawData : boolean);
var
  i : Integer;
  arrayNode : IXMLNode;
  arrayValue : TValue;
  Data : AnsiString;
  myFormatSettings : TFormatSettings;
  MemoryStreamRawData : TMemoryStream;
  CompressStream : TZCompressionStream;
begin
  // avoid class or something else with nil referenz -> would generate a tkUnknown
  if Value.IsEmpty then Exit;
  // save data to XML depend on type
  case Value.Kind of
    tkUnknown : raise ERttiSerializeError.Create('TXMLSerializer.SaveValueToNode: Can''t assign type for ' + RttiType.Name + '. For this reason value not saved.');
    tkFloat :
      begin
        // set custom formatsettings to prevent float are saved different in varied countries
        myFormatSettings := TFormatSettings.Create('en-US');
        myFormatSettings.DecimalSeparator := XMLDECIMALSEPERATOR;
        Node.Text := FloatToStr(Value.AsExtended, myFormatSettings);
      end;
    tkInteger, tkChar, tkString, tkWChar, tkEnumeration, tkSet, tkLString,
      tkWString, tkVariant, tkInt64, tkUString : Node.Text := Value.ToString;
    tkClass : SaveObjectToNode(Value.AsObject, Node, FCustomData);
    tkRecord : SaveStructTypeToNode(Value.GetReferenceToRawData, RttiType, Node);
    // if Array
    tkArray, tkDynArray :
      begin
        // mark node with arraymark and save elementsize
        Node.SetAttributeNS('type', '', 'array');
        Node.SetAttributeNS('size', '', Value.GetArrayLength);
        Node.SetAttributeNS('rawData', '', SaveAsRawData);
        // only rawdata can saved compressed
        if SaveAsRawData then Node.SetAttributeNS('compressed', '', CompressRawData);
        // save raw data
        if SaveAsRawData then
        begin
          MemoryStreamRawData := TMemoryStream.Create;
          // use ZLib compresser if RawData should compressed
          if CompressRawData then
          begin
            CompressStream := TZCompressionStream.Create(MemoryStreamRawData);
            GetArrayAsMemoryBlock(Value, CompressStream);
            CompressStream.Free;
          end
          else GetArrayAsMemoryBlock(Value, MemoryStreamRawData);
          setlength(Data, MemoryStreamRawData.Size);
          Move(MemoryStreamRawData.Memory^, Data[1], MemoryStreamRawData.Size);
          arrayNode := Node.OwnerDocument.CreateNode('RawData', ntCData);
          arrayNode.Text := string(EncodeBase64(Data));
          Node.ChildNodes.Add(arrayNode);
          Data := '';
          MemoryStreamRawData.Free;
        end
        // save all arrayelements with normal method
        else
          for i := 0 to Value.GetArrayLength - 1 do
          begin
            arrayNode := Node.AddChild(XMLDOCELEMENTPREFIX + IntToStr(i));
            arrayValue := Value.GetArrayElement(i);
            SaveValueToNode(arrayValue, FRttiContext.GetType(arrayValue.TypeInfo), arrayNode, False);
          end;
      end;
    tkInterface, tkClassRef : if ReportErrorLevel >= 2 then HLog.Log('TXMLSerializer.SaveValueToNode: Not yet supported!');
    tkPointer, tkMethod, tkProcedure : if ReportErrorLevel >= 2 then HLog.Log('TXMLSerializer.SaveObjectToNode: Can''t save pointer.');
  end;
end;

procedure TXMLSerializer.SetArrayFromMemoryBlock(AArray : TValue; MemoryBlock : TStream);
var
  hasChildArrays : boolean;
  ArraySize, i : Integer;
  tmpValue : TValue;
begin
  MemoryBlock.Read(hasChildArrays, SizeOf(boolean));
  MemoryBlock.Read(ArraySize, SizeOf(Integer));
  if AArray.Kind = tkDynArray then DynArraySetLength(Pointer(AArray.GetReferenceToRawData^), AArray.TypeInfo, 1, @ArraySize)
  else if AArray.GetArrayLength <> ArraySize then raise EXMLSerializeError.Create('TXMLSerializer.SetArrayFromMemoryBlock: Arraysize from staticarray and saved value doesn''t match.');
  if hasChildArrays then
  begin
    for i := 0 to ArraySize - 1 do
    begin
      tmpValue := AArray.GetArrayElement(i);
      SetArrayFromMemoryBlock(tmpValue, MemoryBlock);
      AArray.SetArrayElement(i, tmpValue);
    end;
  end
  else
    if ArraySize > 0 then
  begin
    MemoryBlock.Read(Pointer(AArray.GetReferenceToRawData^)^, ArraySize * AArray.GetArrayElement(0).DataSize);
  end;
end;

{ TXMLCustomSerializable }

procedure TXMLCustomSerializable.CustomAfterXMLCreate;
begin

end;

procedure TXMLCustomSerializable.CustomAfterXMLLoad(
  CustomData : array of TObject);
begin

end;

constructor TXMLCustomSerializable.CustomXMLCreate(Node : TXMLNode;
  CustomData : array of TObject);
begin

end;

procedure TXMLCustomSerializable.CustomXMLLoad(Node : TXMLNode;
  CustomData : array of TObject);
begin

end;

procedure TXMLCustomSerializable.CustomXMLSave(Node : TXMLNode; CustomData : array of TObject);
begin

end;

{ HXMLSerializer }

class procedure HXMLSerializer.LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string);
begin
  LoadObjectFromFile(ObjectToLoad, XMLFileName, []);
end;

class function HXMLSerializer.CreateAndLoadObjectFromFile<T>(XMLFileName : string) : T;
var
  XMLSerializer : TXMLSerializer;
begin
  XMLSerializer := TXMLSerializer.Create;
  Result := XMLSerializer.CreateAndLoadObjectFromFile<T>(XMLFileName);
  XMLSerializer.Free;
end;

class procedure HXMLSerializer.LoadObjectFromFile(ObjectToLoad : TObject; XMLFileName : string; CustomData : array of TObject);
var
  XMLSerializer : TXMLSerializer;
begin
  XMLSerializer := TXMLSerializer.Create;
  XMLSerializer.LoadObjectFromFile(ObjectToLoad, XMLFileName, CustomData);
  XMLSerializer.Free;
end;

class procedure HXMLSerializer.LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string);
begin
  LoadObjectFromString(ObjectToLoad, XMLContent, []);
end;

class procedure HXMLSerializer.LoadObjectFromString(ObjectToLoad : TObject; XMLContent : string; CustomData : array of TObject);
var
  XMLSerializer : TXMLSerializer;
begin
  XMLSerializer := TXMLSerializer.Create;
  XMLSerializer.LoadObjectFromString(ObjectToLoad, XMLContent, CustomData);
  XMLSerializer.Free;
end;

class procedure HXMLSerializer.SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string);
begin
  SaveObjectToFile(ObjectToSave, XMLFileName, []);
end;

class procedure HXMLSerializer.SaveObjectToFile(ObjectToSave : TObject; XMLFileName : string; CustomData : array of TObject);
var
  XMLSerializer : TXMLSerializer;
begin
  XMLSerializer := TXMLSerializer.Create;
  XMLSerializer.SaveObjectToFile(ObjectToSave, XMLFileName, CustomData);
  XMLSerializer.Free;
end;

{ XMLCustomClassSerializer }

constructor XMLCustomClassSerializer.Create(TargetClassName : string);
begin
  FTargetClassName := TargetClassName;
end;

{ TXMLCustomListSerializer }

procedure TXMLCustomListSerializer.CallAdd(const Value : TValue);
var
  Parameter : TRTTIParameter;
begin
  try
    assert(assigned(FMethodAdd));
    FMethodAdd.Invoke(FTargetObject, [Value]);
  except
    for Parameter in FMethodAdd.GetParameters do
    begin
      HLog.Console(Parameter.Name + ': ' + Parameter.ParamType.QualifiedName + ' - ' + FItemType.QualifiedName);
    end;
  end;
end;

procedure TXMLCustomListSerializer.CallClear();
begin
  assert(assigned(FMethodClear));
  FMethodClear.Invoke(FTargetObject, []);
end;

constructor TXMLCustomListSerializer.Create(TargetObject : TObject; Context : TXMLSerializer);
begin
  inherited;
  FMethodClear := GetMethod('Clear');
  FMethodAdd := GetMethod('Add');
  FPropertyItems := GetIndexedProperty('Items');
  FPropertyCount := GetProperty('Count');
  FItemType := FPropertyItems.propertyType;
  if not assigned(FItemType) then
      raise EXMLSerializeError.CreateFmt('TXMLCustomListSerializer.Init: For class type "%s" itemtype could not identified.', [FObjectType.Name]);
end;

procedure TXMLCustomListSerializer.Load(const XMLNode : IXMLNode);
var
  version : string;
begin
  inherited;
  // identifie CustomListSerializer version used to save
  if XMLNode.HasAttribute('list_loader_version') then
      version := string(XMLNode.GetAttributeNS('list_loader_version', ''))
    // auto list -> xml was used
  else version := 'legacy';

  if version = 'legacy' then
      LoadLegacy(XMLNode)
  else if version = '1.0' then
      LoadV1_0(XMLNode)
  else if FContext.ReportErrorLevel >= 1 then
      HLog.Log('TXMLCustomListSerializer.Load: ListLoaderVersion "' + version + '" ist currently not supported.');
end;

procedure TXMLCustomListSerializer.LoadLegacy(const XMLNode : IXMLNode);
var
  Node, Items : IXMLNode;
  Count, i : Integer;
  Value : TValue;
begin
  // first clear all data, because xml list loading always loads completly new data
  CallClear();
  // if List has a lishelper (>=XE8), FCount will be placed in them, else
  // FCount is placed direct in Node (<=XE7)
  if assigned(XMLNode.ChildNodes.FindNode('FListHelper')) then
      Node := XMLNode.ChildNodes.FindNode('FListHelper').ChildNodes.FindNode('FCount')
  else Node := XMLNode.ChildNodes.FindNode('FCount');
  if assigned(Node) then
  begin
    Count := Integer(Node.NodeValue);
    Items := GetChildNode(XMLNode, 'FItems');
    if assigned(Items) then
    begin
      assert(Count <= Items.ChildNodes.Count);
      for i := 0 to Count - 1 do
      begin
        Node := GetChildNode(Items, XMLDOCELEMENTPREFIX + IntToStr(i));
        if assigned(Node) then
        begin
          // create empty value
          TValue.Make(nil, FItemType.Handle, Value);
          // load data for item
          FContext.LoadValueFromNode(Value, FItemType, Node);
          // and put the loaded data back into list
          CallAdd(Value);
        end
        else
            break;
      end;
    end;
  end
  else if FContext.ReportErrorLevel >= 1 then HLog.Log('TXMLCustomListSerializer.LoadLegacy: List does not have a FCount node.');
end;

procedure TXMLCustomListSerializer.LoadV1_0(const XMLNode : IXMLNode);
var
  ItemsList : IXMLNodeList;
  i : Integer;
  Item : TValue;
begin
  // first clear all data, because xml list loading always loads completly new data
  CallClear();
  ItemsList := XMLNode.ChildNodes;
  for i := 0 to ItemsList.Count - 1 do
  begin
    // create empty value
    TValue.Make(nil, FItemType.Handle, Item);
    // load data for item
    FContext.LoadValueFromNode(Item, FItemType, ItemsList.Get(i));
    // and put the loaded data back into list
    CallAdd(Item);
  end;
end;

procedure TXMLCustomListSerializer.Save(const XMLNode : IXMLNode);
begin
  inherited;
  XMLNode.SetAttributeNS('list_loader_version', '', CURRENT_VERSION);
  SaveV1_0(XMLNode);
end;

procedure TXMLCustomListSerializer.SaveV1_0(const XMLNode : IXMLNode);
var
  i : Integer;
  ItemNode : IXMLNode;
  Item : TValue;
begin
  // save content for every item
  for i := 0 to FPropertyCount.GetValue(FTargetObject).AsInteger - 1 do
  begin
    ItemNode := XMLNode.AddChild('Item');
    Item := FPropertyItems.GetValue(FTargetObject, [i]);
    FContext.SaveValueToNode(Item, FItemType, ItemNode, False);
  end;
end;

{ TXMLCustomClassSerializer }

constructor TXMLCustomClassSerializer.Create(TargetObject : TObject; Context : TXMLSerializer);
begin
  FRttiContext := TRttiContext.Create;
  FContext := Context;
  FTargetObject := TargetObject;
  FObjectType := FRttiContext.GetType(TargetObject.ClassType).AsInstance;
end;

destructor TXMLCustomClassSerializer.Destroy;
begin
  FRttiContext.Free;
  inherited;
end;

function TXMLCustomClassSerializer.GetChildNode(const XMLNode : IXMLNode; const NodeName : string) : IXMLNode;
begin
  Result := XMLNode.ChildNodes.FindNode(NodeName);
  if not assigned(Result) then
    if TXMLSerializer.ReportErrorLevel >= 1 then HLog.Log('TXMLCustomClassSerializer.GetChildNode: For classtype "%s" xmlnode "%s" was not found.', [FObjectType.Name, NodeName]);
end;

function TXMLCustomClassSerializer.GetField(const FieldName : string) : TRttiField;
begin
  Result := FObjectType.GetField(FieldName);
  if not assigned(Result) then
      raise EXMLSerializeError.CreateFmt('TXMLCustomClassSerializer.GetField: For classtype "%s" field "%s" not found.', [FObjectType.Name, FieldName]);
end;

function TXMLCustomClassSerializer.GetIndexedProperty(const PropertyName : string) : TRttiIndexedProperty;
begin
  Result := FObjectType.GetIndexedProperty(PropertyName);
  if not assigned(Result) then
      raise EXMLSerializeError.CreateFmt('TXMLCustomClassSerializer.GetIndexedProperty: For classtype "%s" indexed property "%s" not found.', [FObjectType.Name, PropertyName]);
end;

function TXMLCustomClassSerializer.GetMethod(const MethodName : string) : TRttiMethod;
begin
  Result := FObjectType.GetMethod(MethodName);
  if not assigned(Result) then
      raise EXMLSerializeError.CreateFmt('TXMLCustomClassSerializer.GetMethod: For classtype "%s" method "%s" not found.', [FObjectType.Name, MethodName]);
end;

function TXMLCustomClassSerializer.GetProperty(const PropertyName : string) : TRttiProperty;
begin
  Result := FObjectType.GetProperty(PropertyName);
  if not assigned(Result) then
      raise EXMLSerializeError.CreateFmt('TXMLCustomClassSerializer.GetProperty: For classtype "%s" property "%s" not found.', [FObjectType.Name, PropertyName]);
end;

procedure TXMLCustomClassSerializer.Load(const XMLNode : IXMLNode);
begin
end;

procedure TXMLCustomClassSerializer.Save(const XMLNode : IXMLNode);
begin
end;

{ TXMLCustomObjectListSerializer }

constructor TXMLCustomObjectListSerializer.Create(TargetObject : TObject; Context : TXMLSerializer);
begin
  inherited;
  FPropertyOwnsObjects := GetProperty('OwnsObjects');
end;

procedure TXMLCustomObjectListSerializer.LoadLegacy(const XMLNode : IXMLNode);
var
  Node : IXMLNode;
begin
  inherited;
  Node := GetChildNode(XMLNode, 'FOwnsObjects');
  if assigned(Node) then
      FPropertyOwnsObjects.SetValue(FTargetObject, boolean(Node.NodeValue));
end;

procedure TXMLCustomObjectListSerializer.LoadV1_0(const XMLNode : IXMLNode);
begin
  inherited;
  if XMLNode.HasAttribute('OwnsObjects') then
      FPropertyOwnsObjects.SetValue(FTargetObject, boolean(XMLNode.GetAttributeNS('OwnsObjects', '')))
  else
    if TXMLSerializer.ReportErrorLevel >= 1 then HLog.Log('TXMLCustomObjectListSerializer.LoadV1_0: For classtype "%s" attribute "OwnsObjects" not found.', [FObjectType.Name]);
end;

procedure TXMLCustomObjectListSerializer.SaveV1_0(const XMLNode : IXMLNode);
begin
  XMLNode.SetAttributeNS('OwnsObjects', '', FPropertyOwnsObjects.GetValue(FTargetObject).ToString);
  inherited;
end;

{ TXMLCustomDictionarySerializer }

procedure TXMLCustomDictionarySerializer.CallAdd(const Key, Value : TValue);
begin
  assert(assigned(FMethodAdd));
  FMethodAdd.Invoke(FTargetObject, [Key, Value]);
end;

procedure TXMLCustomDictionarySerializer.CallClear();
begin
  assert(assigned(FMethodClear));
  FMethodClear.Invoke(FTargetObject, []);
end;

constructor TXMLCustomDictionarySerializer.Create(TargetObject : TObject;
  Context : TXMLSerializer);
var
  pairType : TRttiType;
begin
  inherited;
  FMethodAdd := GetMethod('Add');
  FMethodClear := GetMethod('Clear');
  FMethodGetEnumerator := GetMethod('GetEnumerator');
  // extract key and and value type
  pairType := GetMethod('ExtractPair').ReturnType;
  FKeyType := pairType.GetField('Key').FieldType;
  FValueType := pairType.GetField('Value').FieldType;
end;

procedure TXMLCustomDictionarySerializer.Load(const XMLNode : IXMLNode);
var
  version : string;
begin
  inherited;
  // identifie CustomDictionarySerializer version used to save
  if XMLNode.HasAttribute('dict_loader_version') then
      version := string(XMLNode.GetAttributeNS('dict_loader_version', ''))
    // auto dict -> xml was used
  else version := 'legacy';

  if version = 'legacy' then
      LoadLegacy(XMLNode)
  else if version = '1.0' then
      LoadV1_0(XMLNode)
  else if FContext.ReportErrorLevel >= 1 then
      HLog.Log('TXMLCustomDictionarySerializer.Load: DictLoaderVersion "' + version + '" ist currently not supported.');
end;

procedure TXMLCustomDictionarySerializer.LoadLegacy(const XMLNode : IXMLNode);
var
  Node, Items, HashNode, KeyNode, ValueNode : IXMLNode;
  Count, i : Integer;
  KeyValue, ValueValue : TValue;
begin
  // first clear all data, because xml dict loading always loads completly new data
  CallClear();
  Items := GetChildNode(XMLNode, 'FItems');
  if assigned(Items) then
  begin
    if Items.HasAttribute('size') then
    begin
      Count := Integer(Items.GetAttributeNS('size', ''));
      assert(Count <= Items.ChildNodes.Count);
      for i := 0 to Count - 1 do
      begin
        Node := GetChildNode(Items, XMLDOCELEMENTPREFIX + IntToStr(i));
        if assigned(Node) then
        begin
          HashNode := Node.ChildNodes.FindNode('HashCode');
          // if hashnode = -1, no data is assigned to element, so skip it
          if assigned(HashNode) and (Integer(HashNode.NodeValue) <> -1) then
          begin
            KeyNode := GetChildNode(Node, 'Key');
            ValueNode := GetChildNode(Node, 'Value');
            if assigned(KeyNode) and assigned(ValueNode) then
            begin
              // create empty key
              TValue.Make(nil, FKeyType.Handle, KeyValue);
              // load data for key
              FContext.LoadValueFromNode(KeyValue, FKeyType, KeyNode);
              // create empty value
              TValue.Make(nil, FValueType.Handle, ValueValue);
              // load data for value
              FContext.LoadValueFromNode(ValueValue, FValueType, ValueNode);
              // and put the loaded data back into dict
              CallAdd(KeyValue, ValueValue);
            end;
          end;
        end
        else
            break;
      end;
    end
    else if FContext.ReportErrorLevel >= 1 then HLog.Log('TXMLCustomDictionarySerializer.LoadLegacy: FItems in dict does not have a size attribute.');
  end;
end;

procedure TXMLCustomDictionarySerializer.Save(const XMLNode : IXMLNode);
begin
  inherited;
  XMLNode.SetAttributeNS('dict_loader_version', '', CURRENT_VERSION);
  SaveV1_0(XMLNode);
end;

procedure TXMLCustomDictionarySerializer.LoadV1_0(const XMLNode : IXMLNode);
var
  ItemsList : IXMLNodeList;
  KeyNode, ValueNode, ItemNode : IXMLNode;
  i : Integer;
  Key, Value : TValue;
begin
  // first clear all data, because xml list loading always loads completly new data
  CallClear();
  ItemsList := XMLNode.ChildNodes;
  for i := 0 to ItemsList.Count - 1 do
  begin
    ItemNode := ItemsList.Get(i);
    KeyNode := GetChildNode(ItemNode, 'Key');
    ValueNode := GetChildNode(ItemNode, 'Value');
    // create empty key
    TValue.Make(nil, FKeyType.Handle, Key);
    // load data for key
    FContext.LoadValueFromNode(Key, FKeyType, KeyNode);
    // create empty value
    TValue.Make(nil, FValueType.Handle, Value);
    // load data for value
    FContext.LoadValueFromNode(Value, FValueType, ValueNode);
    // and put the loaded data back into list
    CallAdd(Key, Value);
  end;
end;

procedure TXMLCustomDictionarySerializer.SaveV1_0(const XMLNode : IXMLNode);
var
  Enumerator : TObject;
  CurrentValue : TValue;
  EnumeratorType : TRttiInstanceType;
  MoveNextMethod : TRttiMethod;
  CurrentValueProperty : TRttiProperty;
  KeyField, ValueField : TRttiField;
  ItemNode, KeyNode, ValueNode : IXMLNode;
begin
  // use enumerator to get all values from dict
  Enumerator := FMethodGetEnumerator.Invoke(FTargetObject, []).AsObject;
  EnumeratorType := FRttiContext.GetType(Enumerator.ClassType).AsInstance;
  MoveNextMethod := EnumeratorType.GetMethod('MoveNext');
  CurrentValueProperty := EnumeratorType.GetProperty('Current');
  KeyField := CurrentValueProperty.propertyType.GetField('Key');
  ValueField := CurrentValueProperty.propertyType.GetField('Value');
  // iterate over all key, value pairs within dict
  while MoveNextMethod.Invoke(Enumerator, []).AsBoolean do
  begin
    ItemNode := XMLNode.AddChild('Item');
    CurrentValue := CurrentValueProperty.GetValue(Enumerator);
    KeyNode := ItemNode.AddChild('Key');
    FContext.SaveValueToNode(KeyField.GetValue(CurrentValue.GetReferenceToRawData), FKeyType, KeyNode, False);
    ValueNode := ItemNode.AddChild('Value');
    FContext.SaveValueToNode(ValueField.GetValue(CurrentValue.GetReferenceToRawData), FValueType, ValueNode, False);
  end;
  Enumerator.Free;
end;

{ TXMLCustomObjectDictionarySerializer }

constructor TXMLCustomObjectDictionarySerializer.Create(TargetObject : TObject;
  Context : TXMLSerializer);
begin
  inherited;
  FFieldOwnerships := GetField('FOwnerships');
end;

procedure TXMLCustomObjectDictionarySerializer.LoadLegacy(const XMLNode : IXMLNode);
var
  OwnershipsNode : IXMLNode;
  OwnershipsValue : TValue;
begin
  inherited;
  OwnershipsNode := GetChildNode(XMLNode, 'FOwnerships');
  TValue.Make(StringToSet(PTypeInfo(FFieldOwnerships.FieldType.Handle), OwnershipsNode.Text), FFieldOwnerships.FieldType.Handle, OwnershipsValue);
  FFieldOwnerships.SetValue(FTargetObject, OwnershipsValue);
end;

procedure TXMLCustomObjectDictionarySerializer.LoadV1_0(const XMLNode : IXMLNode);
var
  OwnershipsValue : TValue;
begin
  inherited;
  if XMLNode.HasAttribute('ownerships') then
  begin
    TValue.Make(StringToSet(PTypeInfo(FFieldOwnerships.FieldType.Handle), XMLNode.GetAttributeNS('ownerships', '')), FFieldOwnerships.FieldType.Handle, OwnershipsValue);
    FFieldOwnerships.SetValue(FTargetObject, OwnershipsValue);
  end
  else
    if TXMLSerializer.ReportErrorLevel >= 1 then HLog.Log('TXMLCustomObjectDictionarySerializer.LoadV1_0: For classtype "%s" attribute "Ownerships" not found.', [FObjectType.Name]);
end;

procedure TXMLCustomObjectDictionarySerializer.SaveV1_0(const XMLNode : IXMLNode);
var
  OwnershipsValue : TValue;
begin
  OwnershipsValue := FFieldOwnerships.GetValue(FTargetObject);
  XMLNode.SetAttributeNS('ownerships', '', OwnershipsValue.ToString);
  inherited;
end;

end.

