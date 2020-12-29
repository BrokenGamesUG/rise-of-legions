unit FBXFile.Loader;

interface

uses
  System.Classes,
  System.SysUtils,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Math,
  Generics.Collections,
  ZLib;

const
  FBX_BINARY_STARTHEADER = 'Kaydara FBX Binary';
  FBX_ASCII_STARTHEADER  = '; FBX';

type

  EFBXError = class(Exception);

  TFBXNode = class
    private
      FRawData : string;
      FName : string;
      FObjectID : LongWord;
      FChildList : TObjectList<TFBXNode>;
      FChildDictionary : TObjectDictionary<string, TList<TFBXNode>>;
      function GetChildCount : integer;
      function GetChildPerIndex(index : LongWord) : TFBXNode;
      function GetChildPerName(Name : string) : TArray<TFBXNode>;
      procedure AddChild(Child : TFBXNode);
      procedure AddChilds(Childs : TArray<TFBXNode>);
    public
      /// <summary> If Node has a is object, if will have a objectID > 0 </summary>
      property ObjectID : LongWord read FObjectID;
      property NodeName : string read FName;
      property ChildCount : integer read GetChildCount;
      property ChildPerIndex[index : LongWord] : TFBXNode read GetChildPerIndex;
      property ChildPerName[name : string] : TArray<TFBXNode> read GetChildPerName; default;
      property RawData : string read FRawData;
      function AsInteger : integer;
      function AsFloat : single;
      function AsString : string;
      function AsStringArray : TArray<string>;
      function AsFloatArray : TArray<single>;
      function AsIntegerArray : TArray<integer>;
      function HasChild(ChildName : string) : boolean;
      // =======================================================================
      constructor Create();
      destructor Destroy; override;
  end;

  TFBXDataParser = class abstract
    public
      function GetData : TFBXNode; virtual; abstract;
  end;

  TFBX_ASCIIDataParser = class(TFBXDataParser)
    private const
      EOF            = '$EOF%';
      COMMENT        = ';';
      NAME_SEPERATOR = ': ';
      START_BLOCK    = '{';
      END_BLOCK      = '}';
    private
      FData : TStrings;
      /// <summary> Return the next line containing data, will remove all leading whitespaces and
      /// will drop comment lines. If end of file is reached, method returns constant EOF.</summary>
      function GetNextLine : string;
      /// <summary> Removing the current line (the line on position 0 in Data) from data.</summary>
      procedure RemoveCurrentLineFromData;
    public
      constructor Create(Data : TStrings);
      function GetData : TFBXNode; override;
      destructor Destroy; override;
  end;

  TFBXBinaryToASCIIConverter = class
    private type
      RFBXFileHeader = packed record
        FileDescriptor : array [0 .. 20] of AnsiChar;
        UnkownData : array [0 .. 1] of byte;
        Version : LongWord;
        function Check : boolean;
      end;

      RNodeRecordHeader = packed record
        EndOffset : LongWord;
        NumProperties : LongWord;
        PropertyListLen : LongWord;
        NameLen : byte;
      end;

      TFBXProperty = class
        private
          procedure ReadArray(TypeCode : AnsiChar; Stream : TStream);
          procedure ReadPrimitive(TypeCode : AnsiChar; Stream : TStream);
          procedure ReadString(Stream : TStream);
          procedure ReadRawBinaryData(Stream : TStream);
        public
          Data : string;
          ElementCount : integer;
          function IsArray : boolean;
          constructor Create(Stream : TStream);
      end;

      TFBXNode = class
        public
          Header : RNodeRecordHeader;
          Name : AnsiString;
          Properties : TObjectList<TFBXBinaryToASCIIConverter.TFBXProperty>;
          ChildNodes : TObjectList<TFBXBinaryToASCIIConverter.TFBXNode>;
          constructor Create(Stream : TStream);
          function ToStrings : TStrings;
          destructor Destroy; override;
      end;
    private
    public
      MainNodes : TObjectList<TFBXBinaryToASCIIConverter.TFBXNode>;
      constructor Create;
      function Convert(Stream : TStream) : TStrings;
      destructor Destroy; override;
  end;

  TFBXFileParser = class
    private
      FData : TFBXNode;
    public
      property Data : TFBXNode read FData;
      /// <summary> Load Data from FBX file.</summary>
      constructor CreateFromFile(FileName : string);
      /// <summary> Load Data from stream which contain data from a fbx file.</summary>
      constructor CreateFromStream(Stream : TStream);
      destructor Destroy; override;
  end;

  EnumFBXObjectType = (
    foUnknown, foRoot, foModel, foGeometry, foDeformer, foAnimationStack,
    foAnimationLayer, foAnimationCurve, foAnimationCurveNode, foNodeAttribute);

const
  FBX_OT_MODEL              = 'Model';
  FBX_OT_GEOMETRY           = 'Geometry';
  FBX_OT_DEFROMER           = 'Deformer';
  FBX_OT_ANIMATIONSTACK     = 'AnimationStack';
  FBX_OT_ANIMATIONLAYER     = 'AnimationLayer';
  FBX_OT_ANIMATIONCURVENODE = 'AnimationCurveNode';
  FBX_OT_ANIMATIONCURVE     = 'AnimationCurve';
  FBX_OT_NODEATTRIBUTE      = 'NodeAttribute';

type

  EnumFBXPropertyDataType = (dtValue, dtArray, dtRecord);

  TFBXProperty = class
    private
      FName : string;
      FRawData : string;
      FArrayElementCount : integer;
      FDataType : EnumFBXPropertyDataType;
      FSubProperties : TObjectDictionary<string, TFBXProperty>;
      procedure LoadArrayData(PropertyNode : TFBXNode);
      procedure LoadRecordData(PropertyNode : TFBXNode);
      procedure LoadValueData(PropertyNode : TFBXNode);
      procedure LoadProperties70Data(PropertyNode : TFBXNode);
      function GetSubPropertyByName(Name : string) : TFBXProperty;
    public
      // ========== some general infos ============
      property name : string read FName;
      property DataType : EnumFBXPropertyDataType read FDataType;
      // ========== data access ===============
      property SubProperties[name : string] : TFBXProperty read GetSubPropertyByName; default;
      function HasSubProperty(const Name : string) : boolean;
      function DataAsInteger : integer;
      function DataAsInt64 : int64;
      property DataArrayElementCount : integer read FArrayElementCount;
      property ArrayElementCount : integer read FArrayElementCount;
      function DataAsIntArray : TArray<integer>;
      function DataAsInt64Array : TArray<int64>;
      function DataAsFloatArray : TArray<single>;
      function DataAsVector3 : RVector3;
      function DataAsVector3Array : TArray<RVector3>;
      function DataAsString : string;
      // ========== default ===================
      constructor Create(PropertyNode : TFBXNode);
      destructor Destroy; override;
  end;

  TFBXObject = class
    private
      FID : LongWord;
      FObjectType : EnumFBXObjectType;
      FName : string;
      FSubName : string;
      FParentNode : TFBXObject;
      FConnections : TList<TFBXObject>;
      FProperties : TObjectDictionary<string, TFBXProperty>;
      function GetConnectedObject(index : integer) : TFBXObject;
      function GetConnectionCount : integer;
      function MapObectType(ObjectTypeName : string) : EnumFBXObjectType;
      function GetPropertyByName(Name : string) : TFBXProperty;
      procedure AddConnection(const AObject : TFBXObject);
      procedure SetParentNode(const ParentNode : TFBXObject);
    public
      property ID : LongWord read FID;
      property ObjectType : EnumFBXObjectType read FObjectType;
      property name : string read FName;
      property SubName : string read FSubName;
      property Properties[name : string] : TFBXProperty read GetPropertyByName;
      function HasProperty(const Name : string) : boolean;
      property Connections[index : integer] : TFBXObject read GetConnectedObject;
      property ConnectionCount : integer read GetConnectionCount;
      function FilterConnectionsByType(ObjectType : EnumFBXObjectType) : TArray<TFBXObject>;
      function GetConnectionByType(ObjectType : EnumFBXObjectType) : TFBXObject;
      /// ///////////////////////////Default//////////////////////////////////
      constructor Create(ObjectNode : TFBXNode);
      destructor Destroy; override;
  end;

  TFBXScene = class
    private
      FRoot : TFBXObject;
      FObjects : TObjectList<TFBXObject>;
      FGlobalSettings : TFBXProperty;
      procedure LoadAllObjects(ObjectNode : TFBXNode);
      procedure BuildConnections(ConnectionsNode : TFBXNode);
      function GetGlobalSetting(SettingsName : string) : TFBXProperty;
    public
      property GlobalSetting[SettinsName : string] : TFBXProperty read GetGlobalSetting;
      property Root : TFBXObject read FRoot;
      constructor Create(Data : TFBXNode);
      destructor Destroy; override;
  end;

var
  FBXFormatSettings : TFormatSettings;

implementation

{ TFBXFileLoader }

constructor TFBXFileParser.CreateFromFile(FileName : string);
var
  Stream : TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    CreateFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

constructor TFBXFileParser.CreateFromStream(Stream : TStream);
var
  Strings : TStrings;
  firstLine : string;
  DataParser : TFBXDataParser;
  BinaryConverter : TFBXBinaryToASCIIConverter;
begin
  Strings := nil;
  try
    Strings := TStringList.Create;
    // load data and look up file formar (ascii or binary)
    Strings.LoadFromStream(Stream);
    assert(Strings.Count > 0);
    firstLine := Strings.Strings[0];

    // choose the correct file parser in dependency of fileformat
    // Binary FBX Format
    // convert binary format to ascii
    if firstLine.StartsWith(FBX_BINARY_STARTHEADER) then
    begin
      Stream.Position := 0;
      BinaryConverter := TFBXBinaryToASCIIConverter.Create;
      Strings.Free;
      Strings := BinaryConverter.Convert(Stream);
      BinaryConverter.Free;
      firstLine := Strings.Strings[0];
      // Strings.SaveToFile('c:\test.fbx');
    end;
    // ASCII FBX Format
    if firstLine.StartsWith(FBX_ASCII_STARTHEADER) then
    begin
      DataParser := TFBX_ASCIIDataParser.Create(Strings);
    end
    // unkown FBX Format
    else
        raise EFBXError.Create('TFBXFileLoader.CreateFromStream: Unknown fbx file format.');

    // finally use the parser to load data
    FData := DataParser.GetData;
    DataParser.Free;
  finally
    Strings.Free;
  end;
end;

destructor TFBXFileParser.Destroy;
begin
  FData.Free;
  inherited;
end;

{ TFBXNode }

procedure TFBXNode.AddChild(Child : TFBXNode);
begin
  FChildList.Add(Child);
  if not FChildDictionary.ContainsKey(Child.NodeName) then
      FChildDictionary.Add(Child.NodeName, TList<TFBXNode>.Create);
  FChildDictionary[Child.NodeName].Add(Child);
end;

procedure TFBXNode.AddChilds(Childs : TArray<TFBXNode>);
var
  Child : TFBXNode;
begin
  for Child in Childs do
  begin
    AddChild(Child);
  end;
end;

function TFBXNode.AsFloat : single;
begin
  result := StrToFloat(FRawData, FBXFormatSettings);
end;

function TFBXNode.AsFloatArray : TArray<single>;
var
  Data : TArray<string>;
  i : integer;
begin
  Data := FRawData.Trim.Split([',']);
  setlength(result, length(Data));
  for i := 0 to length(Data) - 1 do
      result[i] := StrToFloat(Data[i], FBXFormatSettings);
end;

function TFBXNode.AsInteger : integer;
begin
  result := FRawData.ToInteger;
end;

function TFBXNode.AsIntegerArray : TArray<integer>;
var
  Data : TArray<string>;
  i : integer;
begin
  Data := FRawData.Trim.Split([',']);
  setlength(result, length(Data));
  for i := 0 to length(Data) - 1 do
      result[i] := Data[i].ToInteger();
end;

function TFBXNode.AsString : string;
begin
  result := FRawData.Trim.Trim(['"']);
end;

function TFBXNode.AsStringArray : TArray<string>;
begin
  raise ENotImplemented.Create('TFBXNode.AsStringArray');
end;

constructor TFBXNode.Create;
begin
  FChildList := TObjectList<TFBXNode>.Create();
  FChildDictionary := TObjectDictionary < string, TList < TFBXNode >>.Create([doOwnsValues]);
end;

destructor TFBXNode.Destroy;
begin
  FChildDictionary.Free;
  FChildList.Free;
  inherited;
end;

function TFBXNode.GetChildPerIndex(index : LongWord) : TFBXNode;
begin
  if inRange(index, 0, FChildList.Count - 1) then
  begin
    result := FChildList[index];
  end
  else raise EOutOfBoundException.Create('TFBXNode.GetChild: Index out of bound.');
end;

function TFBXNode.GetChildPerName(Name : string) : TArray<TFBXNode>;
begin
  result := FChildDictionary[name].ToArray;
end;

function TFBXNode.HasChild(ChildName : string) : boolean;
begin
  result := FChildDictionary.ContainsKey(ChildName);
end;

function TFBXNode.GetChildCount : integer;
begin
  result := FChildList.Count;
end;

{ TFBX_ASCIIDataParser }

constructor TFBX_ASCIIDataParser.Create(Data : TStrings);
begin
  FData := Data;
  assert(FData.Count > 3);
  assert(FData[0].StartsWith(FBX_ASCII_STARTHEADER));
end;

destructor TFBX_ASCIIDataParser.Destroy;
begin
  inherited;
end;

function TFBX_ASCIIDataParser.GetData : TFBXNode;
  function ReadBlock : TArray<TFBXNode>;
  var
    DataLine : string;
    NameAndData : TArray<string>;
    Data : string;
    Nodes : TList<TFBXNode>;
    Node : TFBXNode;
  begin
    Nodes := TList<TFBXNode>.Create;
    DataLine := GetNextLine.Trim;
    while (DataLine <> EOF) and (DataLine <> END_BLOCK) do
    begin
      Node := TFBXNode.Create;
      NameAndData := DataLine.Split([NAME_SEPERATOR], 2, TStringSplitOptions.None);
      assert(length(NameAndData) = 2);
      Node.FName := NameAndData[0];
      Data := NameAndData[1];
      // remove all whitespace and controlchars from begining and end
      Data := Data.Trim;

      if Data.EndsWith(START_BLOCK) then
      begin
        Data := Data.TrimRight([START_BLOCK]);
        Node.FRawData := Data;
        // test if node is a object
        if length(Data.Split([','])) = 3 then
            Node.FObjectID := StrToUInt64(Data.Split([','])[0].Trim());
        Node.AddChilds(ReadBlock);
      end
      else Node.FRawData := Data;
      Nodes.Add(Node);
      DataLine := GetNextLine.Trim;
    end;
    result := Nodes.ToArray;
    Nodes.Free;
  end;

begin
  result := TFBXNode.Create;
  result.FName := 'FBX_RootNode';
  result.AddChilds(ReadBlock);
end;

function TFBX_ASCIIDataParser.GetNextLine : string;
begin
  if FData.Count <= 0 then
      result := EOF
  else
  begin
    // current line
    result := FData[0];
    RemoveCurrentLineFromData;
    // remove leading whitespace
    result := result.TrimLeft;
    // if current line a comment or an empty line, drop line and read next line
    if result.IsEmpty or result.StartsWith(COMMENT) then
    begin
      result := GetNextLine;
    end;
    // if a line ends with an comma, there is more data for this line in the next line
    if result.EndsWith(',') then
    begin
      result := result + GetNextLine;
    end;
  end;
end;

procedure TFBX_ASCIIDataParser.RemoveCurrentLineFromData;
begin
  if FData.Count > 0 then
      FData.Delete(0);
end;

{ TFBXScene }

procedure TFBXScene.BuildConnections(ConnectionsNode : TFBXNode);
var
  i, srcID, destID : LongWord;
  src, dest : TFBXObject;
  Data : TArray<string>;

  function GetObjectByID(ID : LongWord) : TFBXObject;
  begin
    result := TAdvancedObjectList<TFBXObject>(FObjects).FilterFirstSave(
      function(value : TFBXObject) : boolean
      begin
        result := value.ID = ID;
      end);
  end;

begin
  for i := 0 to length(ConnectionsNode.ChildPerName['C']) - 1 do
  begin
    Data := ConnectionsNode.ChildPerName['C'][i].RawData.Trim.Split([',']);
    // atm only support object <-> object and object <-> property connections
    if (Data[0].Trim([' ', '"']) = 'OO') or (Data[0].Trim([' ', '"']) = 'OP') then
    begin
      // get objects by id
      srcID := StrToUInt64(Data[1].Trim);
      destID := StrToUInt64(Data[2].Trim);
      src := GetObjectByID(srcID);
      dest := GetObjectByID(destID);
      // register connection
      if (src <> nil) and (dest <> nil) then
      begin
        src.AddConnection(dest);
        dest.AddConnection(src);
      end;
    end;
  end;
end;

constructor TFBXScene.Create(Data : TFBXNode);
begin
  FObjects := TObjectList<TFBXObject>.Create();
  FRoot := TFBXObject.Create(nil);
  // root node has the special ID = 0
  FRoot.FID := 0;
  FRoot.FName := 'Root';
  FRoot.FObjectType := foRoot;
  // root is custom object, but also a object (needed to later connecting objects)
  FObjects.Add(FRoot);
  FGlobalSettings := TFBXProperty.Create(Data['GlobalSettings'][0]);
  // first load all objects into list
  LoadAllObjects(Data['Objects'][0]);
  BuildConnections(Data['Connections'][0]);
  // clear parents from connections and set parent variable for complete tree
  // FRoot.SetParentNode(nil);
end;

destructor TFBXScene.Destroy;
begin
  FGlobalSettings.Free;
  FObjects.Free;
  inherited;
end;

function TFBXScene.GetGlobalSetting(SettingsName : string) : TFBXProperty;
begin
  result := FGlobalSettings.SubProperties['Properties70'].SubProperties[SettingsName];
end;

procedure TFBXScene.LoadAllObjects(ObjectNode : TFBXNode);
var
  item : TFBXObject;
  i : integer;
begin
  for i := 0 to ObjectNode.ChildCount - 1 do
  begin
    item := TFBXObject.Create(ObjectNode.ChildPerIndex[i]);
    assert(item.ID <> 0);
    FObjects.Add(item);
  end;
end;

{ TFBXObject }

procedure TFBXObject.AddConnection(const AObject : TFBXObject);
begin
  FConnections.Add(AObject);
end;

constructor TFBXObject.Create(ObjectNode : TFBXNode);
var
  MetaData : TArray<string>;
  i : integer;
  Child : TFBXNode;
  property_item : TFBXProperty;
begin
  FConnections := TList<TFBXObject>.Create;
  FProperties := TObjectDictionary<string, TFBXProperty>.Create([doOwnsValues]);
  // also allow empty ObjectNode, then object will created manually
  if assigned(ObjectNode) then
  begin
    FObjectType := MapObectType(ObjectNode.NodeName);
    // extract metadata
    MetaData := ObjectNode.RawData.Split([',']);
    assert(length(MetaData) = 3);
    FID := StrToUInt64(MetaData[0].Trim);
    FName := MetaData[1].Trim([' ', '"']);
    FSubName := MetaData[2].Trim([' ', '"']);
    // iterate over all object properties
    for i := 0 to ObjectNode.ChildCount - 1 do
    begin
      Child := ObjectNode.ChildPerIndex[i];
      property_item := TFBXProperty.Create(Child);
      assert(not property_item.Name.IsEmpty);
      if not FProperties.ContainsKey(property_item.Name) then
          FProperties.Add(property_item.Name, property_item)
      else property_item.Free;
    end;
  end;
end;

destructor TFBXObject.Destroy;
begin
  FConnections.Free;
  FProperties.Free;
  inherited;
end;

function TFBXObject.FilterConnectionsByType(ObjectType : EnumFBXObjectType) : TArray<TFBXObject>;
var
  FilteredList : TAdvancedList<TFBXObject>;
begin
  FilteredList := TAdvancedList<TFBXObject>(FConnections).Filter(
    function(item : TFBXObject) : boolean
    begin
      result := item.ObjectType = ObjectType;
    end);
  result := FilteredList.ToArray;
  FilteredList.Free;
end;

function TFBXObject.GetConnectedObject(index : integer) : TFBXObject;
begin
  result := FConnections[index];
end;

function TFBXObject.GetConnectionByType(
  ObjectType : EnumFBXObjectType) : TFBXObject;
var
  Connections : TArray<TFBXObject>;
begin
  Connections := FilterConnectionsByType(ObjectType);
  assert(length(Connections) = 1);
  result := Connections[0];
end;

function TFBXObject.GetConnectionCount : integer;
begin
  result := FConnections.Count;
end;

function TFBXObject.GetPropertyByName(Name : string) : TFBXProperty;
begin
  result := FProperties[name];
end;

function TFBXObject.HasProperty(const Name : string) : boolean;
begin
  result := FProperties.ContainsKey(name);
end;

function TFBXObject.MapObectType(ObjectTypeName : string) : EnumFBXObjectType;
begin
  if SameText(ObjectTypeName, FBX_OT_MODEL) then
      result := foModel
  else if SameText(ObjectTypeName, FBX_OT_GEOMETRY) then
      result := foGeometry
  else if SameText(ObjectTypeName, FBX_OT_DEFROMER) then
      result := foDeformer
  else if SameText(ObjectTypeName, FBX_OT_ANIMATIONSTACK) then
      result := foAnimationStack
  else if SameText(ObjectTypeName, FBX_OT_ANIMATIONLAYER) then
      result := foAnimationLayer
  else if SameText(ObjectTypeName, FBX_OT_ANIMATIONCURVENODE) then
      result := foAnimationCurveNode
  else if SameText(ObjectTypeName, FBX_OT_ANIMATIONCURVE) then
      result := foAnimationCurve
  else if SameText(ObjectTypeName, FBX_OT_NODEATTRIBUTE) then
      result := foNodeAttribute
  else result := foUnknown; // raise EFBXError.CreateFmt('TFBXObject.MapObectType: Unknown ObjectType "%s".', [ObjectTypeName]);
end;

procedure TFBXObject.SetParentNode(const ParentNode : TFBXObject);
var
  i : integer;
begin
  FParentNode := ParentNode;
  // if there is any connection to parent, remove them from Connections, because these is saved in special variable
  // this is important to make it later easier to iterate over connections without cycles
  i := FConnections.IndexOf(FParentNode);
  if i >= 0 then
      FConnections.Delete(i);
  for i := 0 to FConnections.Count - 1 do
    if FConnections[i].FParentNode = nil then
        FConnections[i].SetParentNode(self);
end;

{ TFBXProperty }

constructor TFBXProperty.Create(PropertyNode : TFBXNode);
begin
  // also allow empty nodes, then property will created manually
  if assigned(PropertyNode) then
  begin
    FName := PropertyNode.NodeName;
    FArrayElementCount := -1;
    FSubProperties := TObjectDictionary<string, TFBXProperty>.Create([doOwnsValues]);
    // determine property type
    // property70 is a special case where data need preperation for easier access
    if FName = 'Properties70' then
        LoadProperties70Data(PropertyNode)
      // an array starts with an * an is followed by the element count
    else if PropertyNode.RawData.Trim.StartsWith('*') then
        LoadArrayData(PropertyNode)
      // if fbx property has any childs, is is a record (could be also a array, but this was already tested before)
    else if PropertyNode.ChildCount > 0 then
        LoadRecordData(PropertyNode)
      // if the first both does not match, it is a plain value property
    else
        LoadValueData(PropertyNode);
  end;
end;

function TFBXProperty.DataAsFloatArray : TArray<single>;
var
  Data : TArray<string>;
  i : integer;
begin
  assert(DataType = dtArray);
  Data := FRawData.Trim.Split([',']);
  setlength(result, length(Data));
  for i := 0 to length(Data) - 1 do
      result[i] := StrToFloat(Data[i], FBXFormatSettings);
end;

function TFBXProperty.DataAsInt64 : int64;
begin
  assert(DataType = dtValue);
  result := StrToInt64(FRawData);
end;

function TFBXProperty.DataAsInt64Array : TArray<int64>;
var
  Data : TArray<string>;
  i : integer;
begin
  assert(DataType = dtArray);
  Data := FRawData.Trim.Split([',']);
  setlength(result, length(Data));
  for i := 0 to length(Data) - 1 do
      result[i] := StrToInt64(Data[i]);
end;

function TFBXProperty.DataAsIntArray : TArray<integer>;
var
  Data : TArray<string>;
  i : integer;
begin
  assert(DataType = dtArray);
  Data := FRawData.Trim.Split([',']);
  setlength(result, length(Data));
  for i := 0 to length(Data) - 1 do
      result[i] := Data[i].ToInteger();
end;

function TFBXProperty.DataAsInteger : integer;
begin
  assert(DataType = dtValue);
  result := FRawData.ToInteger();
end;

function TFBXProperty.DataAsString : string;
begin
  assert(DataType = dtValue);
  result := FRawData;
end;

function TFBXProperty.DataAsVector3 : RVector3;
begin
  assert(ArrayElementCount = 3);
  result := RVector3.Create(DataAsFloatArray);
end;

function TFBXProperty.DataAsVector3Array : TArray<RVector3>;
var
  Data : TArray<single>;
  i : integer;
begin
  assert(DataType = dtArray);
  assert(ArrayElementCount mod 3 = 0);
  Data := DataAsFloatArray;
  setlength(result, length(Data) div 3);
  for i := 0 to (length(Data) div 3) - 1 do
      result[i] := RVector3.Create(Data[i * 3 + 0], Data[i * 3 + 1], Data[i * 3 + 2]);
end;

destructor TFBXProperty.Destroy;
begin
  FSubProperties.Free;
  inherited;
end;

function TFBXProperty.GetSubPropertyByName(Name : string) : TFBXProperty;
begin
  result := FSubProperties[name];
end;

function TFBXProperty.HasSubProperty(const Name : string) : boolean;
begin
  result := FSubProperties.ContainsKey(name);
end;

procedure TFBXProperty.LoadArrayData(PropertyNode : TFBXNode);
begin
  FDataType := dtArray;
  // array fbx property has only exactly one child, the 'a'rray
  assert(PropertyNode.ChildCount = 1);
  FArrayElementCount := PropertyNode.RawData.Trim([' ', '*']).ToInteger();
  FRawData := PropertyNode.ChildPerName['a'][0].RawData;
end;

procedure TFBXProperty.LoadProperties70Data(PropertyNode : TFBXNode);
var
  i : integer;
  property_item : TFBXProperty;
  Data : TArray<string>;
begin
  FDataType := dtRecord;
  assert(PropertyNode.ChildCount = length(PropertyNode['P']));

  for i := 0 to length(PropertyNode['P']) - 1 do
  begin
    // item property item, because this is created complete custom
    property_item := TFBXProperty.Create(nil);
    assert(PropertyNode['P'][i].NodeName = 'P');
    // all metainfo and data is encoded in one string
    Data := PropertyNode['P'][i].RawData.Split([',']);
    // first get name
    property_item.FName := Data[0].Trim([' ', '"']);
    // secound determine if data is only one value or a array
    // the datapart begins at data[4], so if there any data beyond, this is an array of data
    if length(Data) > 5 then
    begin
      property_item.FDataType := dtArray;
      property_item.FArrayElementCount := length(Data) - 4
    end
    else
    begin
      property_item.FDataType := dtValue;
      property_item.FArrayElementCount := -1
    end;
    if length(Data) > 4 then
        property_item.FRawData := string.join(',', copy(Data, 4, length(Data) - 4))
    else property_item.FRawData := '';
    FSubProperties.Add(property_item.Name, property_item);
  end;
end;

procedure TFBXProperty.LoadRecordData(PropertyNode : TFBXNode);
var
  i : integer;
begin
  FDataType := dtRecord;
  for i := 0 to PropertyNode.ChildCount - 1 do
    // bad HACK to prevent double usage of a propertyname, but this will drop data NEED TO BE FIXED!
    if not FSubProperties.ContainsKey(PropertyNode.ChildPerIndex[i].NodeName) then
        FSubProperties.Add(PropertyNode.ChildPerIndex[i].NodeName, TFBXProperty.Create(PropertyNode.ChildPerIndex[i]));
end;

procedure TFBXProperty.LoadValueData(PropertyNode : TFBXNode);
begin
  FDataType := dtValue;
  // clear rawdata from unwished chars like " for sting surrounding
  FRawData := PropertyNode.RawData.Trim([' ', '"']);
end;

{ TFBXBinaryToASCIIConverter }

function TFBXBinaryToASCIIConverter.Convert(Stream : TStream) : TStrings;
var
  Header : RFBXFileHeader;
  NullRecord, NullData : RawByteString;
  Strings : TStrings;
  mainNode : TFBXBinaryToASCIIConverter.TFBXNode;
begin
  result := TStringList.Create;
  result.Add('; FBX 7.4.0 project file');
  result.Add('; Copyright (C) 1997-2010 Autodesk Inc. and/or its licensors.');
  result.Add('; All rights reserved.');
  result.Add('; ----------------------------------------------------');
  result.Add('');
  MainNodes.Clear;
  Stream.Read(Header, SizeOf(RFBXFileHeader));

  if not Header.Check then
      raise EFilerError.Create('Stream is not a binary fbx file.');
  setlength(NullRecord, 13);
  setlength(NullData, 13);
  FillChar(NullData[1], 13, #0);
  Stream.Read(NullRecord[1], 13);
  while NullData <> NullRecord do
  begin
    Stream.Position := Stream.Position - 13;
    MainNodes.Add(TFBXBinaryToASCIIConverter.TFBXNode.Create(Stream));
    Stream.Read(NullRecord[1], 13);
  end;
  for mainNode in MainNodes do
  begin
    // skip all empty childnodes, because binary has some strange empty nodes
    if mainNode.ChildNodes.Count > 0 then
    begin
      Strings := mainNode.ToStrings;
      result.AddStrings(Strings);
      result.Add('');
      result.Add('');
      Strings.Free;
    end;
  end;
end;

constructor TFBXBinaryToASCIIConverter.Create;
begin
  MainNodes := TObjectList<TFBXBinaryToASCIIConverter.TFBXNode>.Create();
end;

destructor TFBXBinaryToASCIIConverter.Destroy;
begin
  MainNodes.Free;
end;

{ TFBXBinaryToASCIIConverter.RHeader }

function TFBXBinaryToASCIIConverter.RFBXFileHeader.Check : boolean;
begin
  result := string(FileDescriptor).StartsWith('Kaydara FBX Binary  ');
end;

{ TFBXBinaryToASCIIConverter.TRBXNode }

constructor TFBXBinaryToASCIIConverter.TFBXNode.Create(Stream : TStream);
var
  i : integer;
  StreamPosition : int64;
  NullRecord, NullData : RawByteString;
  HasChilds : boolean;
begin
  Properties := TObjectList<TFBXBinaryToASCIIConverter.TFBXProperty>.Create();
  ChildNodes := TObjectList<TFBXBinaryToASCIIConverter.TFBXNode>.Create();
  // read headers, imporant for determine size of following data
  Stream.Read(Header, SizeOf(RNodeRecordHeader));
  // user header info to read name
  setlength(name, Header.NameLen);
  Stream.Read(name[1], Header.NameLen);
  StreamPosition := Stream.Position;
  // Now some properties are possible
  for i := 0 to Header.NumProperties - 1 do
      Properties.Add(TFBXBinaryToASCIIConverter.TFBXProperty.Create(Stream));
  assert(Stream.Position = StreamPosition + Header.PropertyListLen);
  assert(Stream.Position <= Header.EndOffset);
  // and at least a optional list of nested nodes (nodelist) follows
  HasChilds := Stream.Position < Header.EndOffset;
  if HasChilds then
  begin
    while Stream.Position + 13 < Header.EndOffset do
    begin
      ChildNodes.Add(TFBXBinaryToASCIIConverter.TFBXNode.Create(Stream));
    end;
    // finally 13 empty bytes marking the end of the nodelist
    setlength(NullRecord, 13);
    setlength(NullData, 13);
    Stream.Read(NullRecord[1], 13);
    FillChar(NullData[1], 13, #0);
    if NullData <> NullRecord then
        raise EFilerError.Create('NodeRecord endmarker of 13 zero bytes expected but other data found.');
  end;
  assert(Stream.Position = Header.EndOffset);
end;

destructor TFBXBinaryToASCIIConverter.TFBXNode.Destroy;
begin
  Properties.Free;
  ChildNodes.Free;
  inherited;
end;

function TFBXBinaryToASCIIConverter.TFBXNode.ToStrings : TStrings;
var
  Child : TFBXBinaryToASCIIConverter.TFBXNode;
  stringArray : TArray<string>;
  i : integer;
  Strings : TStrings;
  identifier : string;
begin
  result := TStringList.Create;
  identifier := String(name) + ': ';
  if (Properties.Count = 1) and Properties.First.IsArray then
  begin
    identifier := identifier + '*' + Properties.First.ElementCount.ToString() + ' {';
    result.Add(identifier);
    result.Add(#9 + 'a: ' + Properties.First.Data);
    result.Add('}')
  end
  else
  begin
    if Properties.Count > 0 then
    begin
      setlength(stringArray, Properties.Count);
      for i := 0 to Properties.Count - 1 do
      begin
        stringArray[i] := Properties[i].Data;
      end;
      identifier := identifier + string.join(', ', stringArray);
    end;
    if ChildNodes.Count > 0 then
        identifier := identifier + ' {';
    result.Add(identifier);
    if ChildNodes.Count > 0 then
    begin
      for Child in ChildNodes do
      begin
        Strings := Child.ToStrings;
        for i := 0 to Strings.Count - 1 do
            Strings[i] := #9 + Strings[i];
        result.AddStrings(Strings);
        Strings.Free;
      end;
      result.Add('}');
    end;
  end;
end;

{ TFBXBinaryToASCIIConverter.TFBXProperty }

constructor TFBXBinaryToASCIIConverter.TFBXProperty.Create(Stream : TStream);
var
  TypeCode : AnsiChar;
begin
  ElementCount := -1;
  Stream.Read(TypeCode, 1);
  case TypeCode of
    'Y', 'C', 'I', 'F', 'D', 'L' : ReadPrimitive(TypeCode, Stream);
    'f', 'd', 'l', 'i', 'b' : ReadArray(TypeCode, Stream);
    'S' : ReadString(Stream);
    'R' : ReadRawBinaryData(Stream);
  else raise ENotSupportedException.CreateFmt('TFBXBinaryToASCIIConverter: Unknown TypeCode "%s"', [TypeCode]);
  end;
end;

function TFBXBinaryToASCIIConverter.TFBXProperty.IsArray : boolean;
begin
  result := ElementCount >= 0;
end;

procedure TFBXBinaryToASCIIConverter.TFBXProperty.ReadArray(TypeCode : AnsiChar; Stream : TStream);
var
  CompressedData : TStream;

  function DecompressData(SourceStream : TStream; DataLength : LongWord) : TStream;
  var
    Decompressor : TZDecompressionStream;
  begin
    CompressedData := TMemoryStream.Create;
    CompressedData.CopyFrom(SourceStream, DataLength);
    CompressedData.Position := 0;
    Decompressor := TZDecompressionStream.Create(CompressedData);
    result := Decompressor;
  end;

var
  ArrayLength : LongWord;
  Encoding : LongWord;
  CompressedLength : LongWord;
  ArrayData : TArray<string>;
  i : integer;
const
  DATA_COMPRESSED = 1;
begin
  CompressedData := nil;
  Stream.Read(ArrayLength, SizeOf(LongWord));
  Stream.Read(Encoding, SizeOf(LongWord));
  Stream.Read(CompressedLength, SizeOf(LongWord));
  if Encoding = DATA_COMPRESSED then
      Stream := DecompressData(Stream, CompressedLength);
  // raise ENotSupportedException.Create('Arraydata compression is not supported.')
  ElementCount := ArrayLength;
  setlength(ArrayData, ArrayLength);
  for i := 0 to ArrayLength - 1 do
    case TypeCode of
      'f' : ArrayData[i] := FloatToStr(Stream.ReadAny<Single>, FBXFormatSettings);
      'd' : ArrayData[i] := FloatToStr(Stream.ReadAny<Double>, FBXFormatSettings);
      'l' : ArrayData[i] := Stream.ReadAny<int64>.ToString;
      'i' : ArrayData[i] := Stream.ReadAny<integer>.ToString;
      'b' : ArrayData[i] := Stream.ReadAny<byte>.ToString;
    end;
  Data := string.join(',', ArrayData);
  if Encoding = DATA_COMPRESSED then
  begin
    Stream.Free;
    CompressedData.Free;
  end;
end;

procedure TFBXBinaryToASCIIConverter.TFBXProperty.ReadPrimitive(TypeCode : AnsiChar; Stream : TStream);
begin
  case TypeCode of
    'Y' : Data := Stream.ReadAny<SmallInt>.ToString;
    'C' : Data := Stream.ReadAny<byte>.ToString;
    'F' : Data := FloatToStr(Stream.ReadAny<Single>, FBXFormatSettings);
    'D' : Data := FloatToStr(Stream.ReadAny<Double>, FBXFormatSettings);
    'L' : Data := Stream.ReadAny<int64>.ToString;
    'I' : Data := Stream.ReadAny<integer>.ToString;
  end;
end;

procedure TFBXBinaryToASCIIConverter.TFBXProperty.ReadRawBinaryData(Stream : TStream);
var
  len : LongWord;
begin
  // Binary Data for ASCII format irrelevant, so simple skip it
  Stream.Read(len, SizeOf(LongWord));
  Stream.Skip(len);
end;

procedure TFBXBinaryToASCIIConverter.TFBXProperty.ReadString(Stream : TStream);
var
  len : LongWord;
  str : RawByteString;
  i : integer;
begin
  Stream.Read(len, SizeOf(LongWord));
  setlength(str, len);
  Stream.Read(str[1], len);
  // can't use replace here, because this will ignore #0
  for i := 1 to len do
    if str[i] in [#0, #1] then
        str[i] := ':';
  Data := '"' + String(str) + '"';
end;

initialization

FBXFormatSettings := TFormatSettings.Create('en-US');
FBXFormatSettings.DecimalSeparator := '.';

end.
