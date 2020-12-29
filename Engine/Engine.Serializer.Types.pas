unit Engine.Serializer.Types;

interface

uses
  SysUtils,
  XMLIntf,
  RTTI;

type

{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  TXMLNode = IXMLNode;

  EInvalidXMLDoc = class(Exception);
  ERttiSerializeError = class(Exception);
  EXMLSerializeError = class(Exception);

  EJSONError = class(Exception);
  EJSONParserError = class(EJSONError);
  EJSONSerializeError = class(EJSONError);

  ACustomData = TArray<TObject>;

  XMLIncludeOption = (
    XMLIncludeFields,   // all fields of the class are saved
    XMLIncludeProperties// all properties of the class are saved
    );
  XMLIncludeOptions = set of XMLIncludeOption;

  /// <summary> While serialization, if a class should be serialized, the serializer looks for
  /// parents with this tag and use the baseclass instead of the derived class. Can be omitted.</summary>
  XMLBaseClass = class(TCustomAttribute);

  /// <summary> A class with this attribute is saved complete.
  /// The Parameter "option" controll what is saved. With <see cref="XMLExcludeElement"/> elements can anyway exclude from saving.</summary>
  /// If no parameter denoted, no elements are saved. For this reason [XMLIncludeAll()] resulting in same effect as [XMLExcludeAll]
{$RTTI EXPLICIT METHODS([vcPublic]) PROPERTIES([]) FIELDS([])}

  XMLIncludeAll = class(TCustomAttribute)
    private
      FOption : XMLIncludeOptions;
    public
      constructor Create(Option : XMLIncludeOptions = [XMLIncludeFields]);
      property Option : XMLIncludeOptions read FOption write FOption;
  end;
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  /// <summary> No element in the class is saved. To include elements to saving operation, use <see cref="XMLIncludeElement"/></summary>
  XMLExcludeAll = class(TCustomAttribute);

  /// <summary> NOT FOR PUBLIC USING! A attributeclass that inherit from this class,
  /// controll the savebehavior of a element.</summary>
  XMLElementControll = class(TCustomAttribute);

  /// <summary> A element (fiel, property) with this attribute is serialized in a XMLDocument.</summary>
  XMLIncludeElement = class(XMLElementControll);

  /// <summary> A element (fiel, property) with this attribute is NOT serialized in a XMLDocument,
  /// regardless which other attributes the class has.</summary>
  XMLExcludeElement = class(XMLElementControll);

  /// <summary> Mark a element (only arrays) to saved as Raw Data. Raw Data is saved as non parsed data. This attribute
  /// is only supported for arrays. If any other elementtype marked with this attribute, it will be ignored.</summary>
  XMLRawData = class(XMLElementControll);

  /// <summary> A Class with this attribute is not autoloaded and saved by TXMLSerializer. However, if it inherited from <see cref="TXMLCustomSerializable"/>
  /// this methods are called to save and load.</summary>
  XMLDisableAuto = class(TCustomAttribute);

  /// <summary> This attribute marks any method that should be called after XML
  /// deserialization is done.</summary>
  XMLDeserializationCallback = class(TCustomAttribute);

  /// <summary> NOT FOR PUBLIC USING! Parentclass for all XML default values. Save the TValue</summary>
  XMLDefaultValue = class(TCustomAttribute)
    public
      DefaultValueAsTValue : TValue;
  end;

{$RTTI EXPLICIT METHODS([vcPublic]) PROPERTIES([]) FIELDS([])}

  /// <summary> NOT FOR PUBLIC USING! A attributeclass that inherit from this class contains a
  /// default value for a element. Because a generic class can't be a attribute. This class
  /// has to inherit with explicit typedef (e.g. XMLDefaultValueInteger = XMLDefaultValue<integer>)</summary>
  XMLDefaultValue<T> = class(XMLDefaultValue)
    private
      FDefaultValue : T;
      procedure SetDefaultValue(const Value : T);
    public
      // every access have to use the property and not field, because TValue has to update
      property DefaultValue : T read FDefaultValue write SetDefaultValue;
      constructor Create(DefaultValue : T);
  end;
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  /// <summary> Default Value attribute for integer</summary>
  XMLDefaultValueInteger = class(XMLDefaultValue<Integer>);

  /// <summary> Default Value attribute for string</summary>
  XMLDefaultValueString = class(XMLDefaultValue<string>);

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation


{ XMLIncludeAll }

constructor XMLIncludeAll.Create(Option : XMLIncludeOptions);
begin
  Self.Option := Option;
end;

{ XMLDefaultValue<T> }

constructor XMLDefaultValue<T>.Create(DefaultValue : T);
begin
  Self.DefaultValue := DefaultValue;
end;

procedure XMLDefaultValue<T>.SetDefaultValue(const Value : T);
begin
  FDefaultValue := Value;
  DefaultValueAsTValue := TValue.From<T>(Value);
end;

end.
