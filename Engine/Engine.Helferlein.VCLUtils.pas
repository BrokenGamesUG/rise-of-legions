unit Engine.Helferlein.VCLUtils;

interface

uses
  Math,
  Classes,
  Types,
  Vcl.FileCtrl,
  SysUtils,
  StrUtils,
  TypInfo,
  RTTI,
  Windows,
  Winapi.Messages,
  Generics.Collections,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Controls,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Graphics,
  Vcl.Samples.Spin,
  Vcl.Menus,
  /// /// Engine ///////
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows;

type
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  /// ========================== Helper ========================================

  TLiveColorPicker = class
    public
      type
      cbtype = procedure(Sender : TObject) of object;
    strict private
      FColor : RVector3;
      FHueImage, FSaturationValueImage : TImage;
      FHueBitmap, FSaturationValueBitmap : TBitmap;
      FCallback : cbtype;
      procedure DrawHue;
      procedure DrawSaturationValue;
      procedure CopyIntoImage;
      procedure setColor(const Value : RColor);
      function getColor : RColor;
      procedure ColorPickerMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : integer);
      procedure ColorPickerMouseMove(Sender : TObject; Shift : TShiftState; X, Y : integer);
      procedure ColorPickerMouseUp(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : integer);
    public
      property Color : RColor read getColor write setColor;
      constructor Create(HueImage, SaturationValue : TImage; Callback : cbtype);
      procedure SelectHue(X, Y : integer);
      procedure SelectSaturationValue(X, Y : integer);
      destructor Destroy; override;
  end;

  /// <summary> Helper methode to deal with multi-select or single-select listboxes at the same time. </summary>
  TListboxHelper = class helper for TCustomListBox
    private
      function GetSelectedIndex(index : integer) : integer;
      function GetSelectedItem(index : integer) : string;
    public
      /// <summary> Return the nth index of selected items. If index is out of range, returns -1 </summary>
      property SelectedIndices[index : integer] : integer read GetSelectedIndex;
      /// <summary> Return the nth selected item. If index is out of range, returns '' </summary>
      property SelectedItems[index : integer] : string read GetSelectedItem;
      function HasSelection : boolean;
      function IsSelected(index : integer) : boolean;
      /// <summary> Selects an item by a list index. If Exclusive is false and Multiselect, selected item is added to selection
      /// otherwise all other elements are deselected. </summary>
      procedure Select(index : integer; Exclusive : boolean = True);
      /// <summary> Deselects an item by a list index. </summary>
      procedure Deselect(index : integer);
      /// <summary> Removes any selection of this list. </summary>
      procedure DeselectAll();
      /// <summary> Deselectes an item by its selection index. </summary>
      procedure DeselectBySelectedIndex(index : integer);
      /// <summary> Deselects an item by a list index. </summary>
      function SelectionCount : integer;
  end;

  TTrackbarHelper = class helper for TTrackBar
    private
      function GetInstanceValue : single;
      procedure setValue(const Value : single);
    public
      property Value : single read GetInstanceValue write setValue;
  end;

  TEditHelper = class helper for TEdit
    private
      function GetSingleValue : single;
      procedure setSingleValue(const Value : single);
    public
      property SingleValue : single read GetSingleValue write setSingleValue;
  end;

  TFormHelper = class helper for TForm
    public
      function MouseOverForm : boolean;
      /// <summary> Place window lefttop on the right most monitor, if this is the primary, place it on the righttop part.
      /// Must be called when window is visible, as setting is visible will set its position by Delphi. </summary>
      procedure PositionToolWindow;
  end;

  CControl = class of TControl;

  /// =========================== FORM GENERATOR ===============================

  TBoundComponent = class;
  TPropertyBinding = class;

  CBoundComponent = class of TBoundComponent;
  CBoundProperty = class of TPropertyBinding;

  ProcOnChange = procedure(Sender : string; NewValue : TValue) of object;
  ProcOnDelete = procedure(Sender : TObject);

  /// <summary> Options for VCLListField. Can control if user can edit, delete or add item.</summary>
  EnumListOptions = (
    /// <summary> Will generate an inplace form if item is selected by click, to edit item.</summary>
    loEditItem,
    /// <summary> Will add an option to list rightclick popmenu, to add item to list. If itemtype is a class,
    /// user can choose from all descandants of the class. This choose is used to create the item.
    /// Hint: (Class needs to have an parameterless constructor create).</summary>
    loAddItem,
    /// <summary> Will add an option to list rightclick popmenu, to add delete selected item from list.</summary>
    loDeleteItem,
    /// <summary> If an item is deleted from list and this option is active, complete tree form tree structure is traversed
    /// to find and delete any other refrence to this item. Will only works with classtypes not with records.</summary>
    loDeleteAllRefrencesToItem);

  SetListOptions = set of EnumListOptions;

  TBoundForm = class
    private
      FControl : TControl;
      FInstance : Pointer;
      FBindings : TObjectList<TBoundComponent>;
      FOnChange : ProcOnChange;
      FOnDelete : ProcOnDelete;
      FRttiInfo : TRttiType;
      /// <summary> Parent of current form (e.g. by TListBinding), if nil form has no parent</summary>
      FParentForm : TBoundForm;
      procedure setInstance(const Value : Pointer);
      /// <summary> Sync all GUI binded components in Direction Instance -> GUI.</summary>
      procedure ReadValuesFromInstance;
      /// <summary> Sync all GUI binded components in Direction GUI -> Instance.</summary>
      procedure WriteValuesToInstance;
      /// <summary> Create and init. Not for direct invoke, use TFormGenerator.GenerateForm instead.</summary>
      constructor Create(ParentControl : TControl; RttiInfo : TRttiType);
    public
      /// <summary> Callback is called everytime data is changed.</summary>
      property OnChange : ProcOnChange read FOnChange write FOnChange;
      /// <summary> Callback is called everytime an member-instance is deleted from boundinstance or from child of this.</summary>
      property OnDelete : ProcOnDelete read FOnDelete write FOnDelete;
      /// <summary> Instance fom which is source of values for form and destination for changed values from form. Accept nil
      /// to unbound form. If set a instance, all values will read from instance and overwrite form.</summary>
      property BoundInstance : Pointer read FInstance write setInstance;
      /// <summary> Set Instance as new BoundInstance and write all value from form to instance. Hint, accept also nil
      /// to unbound form.</summary>
      procedure SetUpInstance(instance : Pointer);
      /// <summary> Used to refresh form and reread all values from bounded instance to form. If instance = nil, nothing will happen.</summary>
      procedure ExternChange;
      /// <summary> Realign all children. </summary>
      procedure Sort;
      /// <summary> Free all bindings.</summary>
      destructor Destroy; override;
  end;

  TFormGenerator = class
    public
      /// <summary> Generates a dynamic form on base of the class of the given classtype.</summary>
      class function GenerateForm(Target : TControl; FormTemplate : TClass) : TBoundForm; overload;
      /// <summary> Generates a dynamic form on base of the ClassInfo at the pointer. Instance is not set at this point.
      /// Can be used with instance.ClassInfo. </summary>
      class function GenerateForm(Target : TControl; FormTemplate : Pointer) : TBoundForm; overload;
  end;

  TBoundComponent = class
    private
      FTargetControl : TControl;
      FBoundForm : TBoundForm;
      FRttiInfo : TRttiMemberUnified;
      FComponents : TList<TControl>;
      FBlockChanges : boolean;
      function CreateComponent(Component : CControl; aTarget : TControl = nil) : TControl;
      procedure CreateVariedField(Name : string; attribute : TCustomAttribute; index : integer = 0);
      procedure CreateVariedEditField(Name : string; attribute : TCustomAttribute; index : integer = 0);
      function CreateSingleField(Name : string; attribute : TCustomAttribute; index : integer) : TControl;
      procedure OnChangeHandler(Sender : TObject);
      procedure WriteValueToInstance; virtual;
      function ReadValueFromComponents : TValue; virtual;
      procedure WriteValueToComponents; virtual;
      function GetInstanceValue : TValue;
    public
      /// <summary> If true every write to GUI or write to value is blocked.</summary>
      property BlockChanges : boolean read FBlockChanges write FBlockChanges;
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); virtual;
      destructor Destroy; override;
  end;

  TPropertyBinding = class(TBoundComponent)
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); reintroduce; virtual;
  end;

  TIntegerTrackBarBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TIntegerSpinEditBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TSingleTrackBarBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TRIntVector2SpinEditBinding = class(TPropertyBinding)
    private const
      X = 0;
      Y = 1;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TRVector3TrackBarBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TRVector4TrackBarBinding = class(TPropertyBinding)
    private const
      MEAN_X = 0;
      MEAN_Y = 1;
      MEAN_Z = 2;
      MEAN_W = 3;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TRColorBinding = class(TRVector4TrackBarBinding)
    private
      FColorDialog : TColorDialog;
      procedure OnClickHandler(Sender : TObject);
      procedure OnClickInputHandler(Sender : TObject);
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TSingleEditBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TEditInstanceBinding = class(TPropertyBinding)
    private
      FInstanceBoundForm : TBoundForm;
      FValue : TValue;
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
      procedure InstanceChangeHandler(Sender : string; NewValue : TValue);
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
      destructor Destroy; override;
  end;

  TStringEditBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TStringTextFieldBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TBooleanBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TEnumBinding = class(TPropertyBinding)
    private
      ordType : PTypeInfo;
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TListBinding = class(TPropertyBinding)
    private
      /// <summary> Control for hold boundform for item of editlist.</summary>
      FItemControl : TControl;
      FItemBoundForm : TBoundForm;
      FOptions : SetListOptions;
      FItem : TValue;
      FArrayField : TRttiField;
      FPopMenu : TPopupMenu;
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
      procedure OnClickHandler(Sender : TObject);
      procedure ItemChangedHandler(Sender : string; NewValue : TValue);
      /// <summary> Handles all popmenu add actions</summary>
      procedure MenuItemAddHandler(Sender : TObject);
      /// <summary> Handle all popmenu delete actions</summary>
      procedure MenuItemDeleteHandler(Sender : TObject);
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
      destructor Destroy; override;
  end;

  TListChoiceBinding = class(TPropertyBinding)
    private const
      LEVLEUP = '..';
    private
      /// <summary> Path as a sequnce of instructions, :: means go a level up, any other string means select property</summary>
      FChoicesSourePath : TList<string>;
      function GetChoicesList : TList<TObject>;
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
      destructor Destroy; override;
  end;

  TFileBinding = class(TPropertyBinding)
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
      procedure OnClickHandler(Sender : TObject);
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TRVector2Binding = class(TPropertyBinding)
    private const
      X = 0;
      Y = 1;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TRVector3EditBinding = class(TPropertyBinding)
    private const
      X = 0;
      Y = 1;
      Z = 2;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedIntegerBinding = class(TPropertyBinding)
    private const
      MEAN     = 0;
      VARIANCE = 1;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedIntegerEditBinding = class(TPropertyBinding)
    private const
      MEAN     = 0;
      VARIANCE = 1;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedSingleBinding = class(TPropertyBinding)
    private const
      MEAN     = 0;
      VARIANCE = 1;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedSingleEditBinding = class(TPropertyBinding)
    private const
      MEAN     = 0;
      VARIANCE = 1;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedRVector2Binding = class(TPropertyBinding)
    private const
      MEAN_X     = 0;
      VARIANCE_X = 1;
      MEAN_Y     = 2;
      VARIANCE_Y = 3;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedRVector3EditBinding = class(TPropertyBinding)
    private const
      MEAN_X     = 0;
      VARIANCE_X = 1;
      MEAN_Y     = 2;
      VARIANCE_Y = 3;
      MEAN_Z     = 4;
      VARIANCE_Z = 5;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedRVectorTrackBarBinding = class(TPropertyBinding)
    private const
      MEAN_X     = 0;
      VARIANCE_X = 1;
      MEAN_Y     = 2;
      VARIANCE_Y = 3;
      MEAN_Z     = 4;
      VARIANCE_Z = 5;
      MEAN_W     = 6;
      VARIANCE_W = 7;
    private
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
      function Dimensions : integer; virtual; abstract;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TVariedRVector3TrackBarBinding = class(TVariedRVectorTrackBarBinding)
    private
      function Dimensions : integer; override;
  end;

  TVariedRVector4TrackBarBinding = class(TVariedRVectorTrackBarBinding)
    private
      function Dimensions : integer; override;
  end;

  TVariedRColorBinding = class(TVariedRVectorTrackBarBinding)
    private
      FColorDialog : TColorDialog;
      function Dimensions : integer; override;
      function ReadValueFromComponents : TValue; override;
      procedure WriteValueToComponents; override;
      procedure OnClickHandler(Sender : TObject);
      procedure OnClickInputHandler(Sender : TObject);
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  TCallableBinding = class(TBoundComponent)
    private
      procedure OnClickHandler(Sender : TObject);
      procedure WriteValueToInstance; override;
    public
      constructor Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute); override;
  end;

  /// <summary> Descandant for every VCLField like VCLSingleField or VCLVariedRVector2Field.
  /// Provides field, to choose correct binding class for field</summary>
  VCLField = class abstract(TCustomAttribute)
    private
      FBindingClass : CBoundComponent;
  end;

  VCLPropertyField = class abstract(TCustomAttribute)
    private
      FBindingClass : CBoundProperty;
  end;

  VCLFileField = class(VCLPropertyField)
    public
      constructor Create();
  end;

  EnumStringComponent = (scEdit, scMemo);

  VCLStringField = class(VCLPropertyField)
    public
      constructor Create(ComponentType : EnumStringComponent = scEdit);
  end;

  VCLCallable = class(VCLField)
    private
      FCaption : string;
    public
      constructor Create(Caption : string);
  end;

  EnumSingleComponent = (isTrackBar, isEdit);

  VCLSingleField = class(VCLPropertyField)
    private
      FRange : single;
      FWithNegativeRange : boolean;
    public
      constructor Create(ComponentType : EnumSingleComponent = isTrackBar); overload;
      constructor Create(Range : single; ComponentType : EnumSingleComponent = isTrackBar); overload;
  end;

  VCLBooleanField = class(VCLPropertyField)
    public
      constructor Create;
  end;

  VCLRVector2Field = class(VCLPropertyField)
    private
      FRange : RVector2;
      FWithNegativeRange : boolean;
    public
      constructor Create(xRange, yRange : single);
  end;

  VCLRVector3Field = class(VCLPropertyField)
    private
      FRange : RVector3;
      FWithNegativeRange : boolean;
    public
      constructor Create(xRange, yRange, zRange : single; ComponentType : EnumSingleComponent = isTrackBar; WithNegativeRange : boolean = False); overload;
  end;

  VCLRVector4Field = class(VCLPropertyField)
    private
      FRange : RVector4;
      FWithNegativeRange : boolean;
    public
      constructor Create(xRange, yRange, zRange, wRange : single; ComponentType : EnumSingleComponent = isTrackBar);
  end;

  VCLRColorField = class(VCLPropertyField)
    private
      FRange : RVector4;
    public
      constructor Create(xRange, yRange, zRange, wRange : single; ComponentType : EnumSingleComponent = isTrackBar);
  end;

  EnumIntegerComponent = (icTrackBar, icEdit, icSpinEdit);

  VCLIntegerField = class(VCLPropertyField)
    private
      FMin, FMax : integer;
    public
      constructor Create(Min, Max : integer; ComponentType : EnumIntegerComponent = icTrackBar);
  end;

  VCLRIntVector2Field = class(VCLPropertyField)
    private
      FRange : RIntVector2;
    public
      constructor Create(xMax, yMax : integer; ComponentType : EnumIntegerComponent = icSpinEdit);
  end;

  VCLVariedSingleField = class(VCLPropertyField)
    private
      FValue : RVariedSingle;
    public
      constructor Create(RangeMean, RangeVariance : single; ComponentType : EnumSingleComponent = isTrackBar);
  end;

  VCLVariedRVector2Field = class(VCLPropertyField)
    private
      FValue : RVariedVector2;
    public
      constructor Create(xRangeMean, xRangeVariance, yRangeMean, yRangeVariance : single);
  end;

  VCLVariedRVector3Field = class(VCLPropertyField)
    private
      FValue : RVariedVector3;
    public
      constructor Create(); overload;
      constructor Create(xRangeMean, xRangeVariance, yRangeMean, yRangeVariance, zRangeMean, zRangeVariance : single); overload;
  end;

  VCLVariedRVector4Field = class(VCLPropertyField)
    private
      FValue : RVariedVector4;
    public
      constructor Create(xRangeMean, xRangeVariance, yRangeMean, yRangeVariance, zRangeMean, zRangeVariance, wRangeMean, wRangeVariance : single); overload;
  end;

  VCLVariedRColorField = class(VCLPropertyField)
    private
      FValue : RVariedVector4;
    public
      constructor Create(xRangeMean, xRangeVariance, yRangeMean, yRangeVariance, zRangeMean, zRangeVariance, wRangeMean, wRangeVariance : single); overload;
  end;

  VCLVariedIntegerField = class(VCLPropertyField)
    private
      FMin, FMax, FVariance : integer;
    public
      constructor Create(Min, Max, VARIANCE : integer; ComponentType : EnumIntegerComponent = icTrackBar);
  end;

  VCLEnumField = class(VCLPropertyField)
    public
      constructor Create();
  end;

  /// <summary> </summary>
  VCLListField = class(VCLPropertyField)
    private
      FOptions : SetListOptions;
    public
      /// <summary> Constructor
      /// <param name="Options"> Options to control list behavior, see set for more informations.</param></summary>
      constructor Create(Options : SetListOptions = [loEditItem]);
  end;

  /// <summary> Generates a new Panel with content of the instance. Allow to edit a class or record property of a class/record.</summary>
  VCLEditInstance = class(VCLPropertyField)
    public
      constructor Create;
  end;

  /// <summary> Creates a ComboBox from to choice content for this field. Source for choices determined by path.</summary>
  VCLListChoiceField = class(VCLPropertyField)
    private
      FChoicesSourcePath : string;
    public
      /// <summary> Constructor.
      /// <param name="ChoiceSourcePath"> Path to a list that is used for as choices for this property.
      /// Path has follow form: '$parent::property'; $parent - used to go a level up; :: - select a property</param></summary>
      constructor Create(ChoiceSourcePath : string);
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ TTrackbarHelper }

function TTrackbarHelper.GetInstanceValue : single;
begin
  if self.Tag = 0 then self.Tag := 1;
  if self.Tag < 0 then Result := self.Position / self.Max / -self.Tag
  else Result := self.Position / self.Max * self.Tag;
end;

procedure TTrackbarHelper.setValue(const Value : single);
begin
  if self.Tag = 0 then self.Tag := 1;
  if self.Tag < 0 then self.Position := round(Value * -self.Tag * self.Max)
  else self.Position := round(Value / self.Tag * self.Max);
end;

{ TLiveColorPicker }

procedure TLiveColorPicker.CopyIntoImage;
begin
  FHueImage.Picture.Bitmap := FHueBitmap;
  FSaturationValueImage.Picture.Bitmap := FSaturationValueBitmap;
end;

constructor TLiveColorPicker.Create(HueImage, SaturationValue : TImage; Callback : cbtype);
begin
  FCallback := Callback;
  FColor := RVector3.Create(0, 1, 1);
  FHueImage := HueImage;
  FHueImage.OnMouseDown := ColorPickerMouseDown;
  FHueImage.OnMouseMove := ColorPickerMouseMove;
  FHueImage.OnMouseUp := ColorPickerMouseUp;
  FSaturationValueImage := SaturationValue;
  FSaturationValueImage.OnMouseDown := ColorPickerMouseDown;
  FSaturationValueImage.OnMouseMove := ColorPickerMouseMove;
  FSaturationValueImage.OnMouseUp := ColorPickerMouseUp;
  FHueBitmap := TBitmap.Create;
  FHueBitmap.PixelFormat := pf24bit;
  FHueBitmap.Width := FHueImage.Width;
  FHueBitmap.Height := FHueImage.Height;
  FSaturationValueBitmap := TBitmap.Create;
  FSaturationValueBitmap.PixelFormat := pf24bit;
  FSaturationValueBitmap.Width := FSaturationValueImage.Width;
  FSaturationValueBitmap.Height := FSaturationValueImage.Height;
  DrawHue;
  DrawSaturationValue;
  CopyIntoImage;
end;

destructor TLiveColorPicker.Destroy;
begin
  FHueBitmap.Free;
  FSaturationValueBitmap.Free;
  inherited;
end;

procedure TLiveColorPicker.DrawHue;
var
  Y : integer;
  X : integer;
  hsv : RVector3;
  temp : RColor;
  line : PByte;
begin
  for Y := 0 to FHueBitmap.Height - 1 do
  begin
    line := PByte(FHueBitmap.ScanLine[Y]);
    for X := 0 to FHueBitmap.Width - 1 do
    begin
      hsv := RVector3.Create(Y / (FHueBitmap.Height - 1), 1, 1);
      temp.hsv := hsv;
      if abs(hsv.X - FColor.X) < 1 / FHueBitmap.Height then temp := $000000;
      line^ := temp.BlueByte;
      inc(line);
      line^ := temp.GreenByte;
      inc(line);
      line^ := temp.RedByte;
      inc(line);
    end;
  end;
end;

procedure TLiveColorPicker.DrawSaturationValue;
var
  Y : integer;
  X : integer;
  hsv : RVector3;
  temp : RColor;
  line : PByte;
begin
  for Y := 0 to FSaturationValueBitmap.Height - 1 do
  begin
    line := PByte(FSaturationValueBitmap.ScanLine[Y]);
    for X := 0 to FSaturationValueBitmap.Width - 1 do
    begin
      hsv := RVector3.Create(FColor.X, X / (FSaturationValueBitmap.Width - 1), 1 - Y / (FSaturationValueBitmap.Height - 1));
      temp.hsv := hsv;
      if abs(hsv.YZ.Distance(FColor.YZ)) < 2 / FSaturationValueBitmap.Height then temp.hsv := (RVector3.Create(1, 1, 1) - hsv).SetY(0);
      line^ := temp.BlueByte;
      inc(line);
      line^ := temp.GreenByte;
      inc(line);
      line^ := temp.RedByte;
      inc(line);
    end;
  end;
end;

function TLiveColorPicker.getColor : RColor;
begin
  Result := 0;
  Result.hsv := self.FColor;
end;

procedure TLiveColorPicker.SelectHue(X, Y : integer);
begin
  FColor.X := Y / (FHueBitmap.Height - 1);
  DrawHue;
  DrawSaturationValue;
  CopyIntoImage;
  FCallback(FHueImage);
end;

procedure TLiveColorPicker.SelectSaturationValue(X, Y : integer);
begin
  FColor.Y := X / (FSaturationValueBitmap.Width - 1);
  FColor.Z := 1 - Y / (FSaturationValueBitmap.Height - 1);
  DrawSaturationValue;
  CopyIntoImage;
  FCallback(FSaturationValueImage);
end;

procedure TLiveColorPicker.setColor(const Value : RColor);
begin
  FColor := Value.hsv;
  DrawHue;
  DrawSaturationValue;
  CopyIntoImage;
end;

procedure TLiveColorPicker.ColorPickerMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : integer);
begin
  TComponent(Sender).Tag := 1;
end;

procedure TLiveColorPicker.ColorPickerMouseMove(Sender : TObject; Shift : TShiftState; X, Y : integer);
begin
  if (Sender = FSaturationValueImage) and (TComponent(Sender).Tag = 1) then self.SelectSaturationValue(X, Y);
  if (Sender = FHueImage) and (TComponent(Sender).Tag = 1) then self.SelectHue(X, Y);
end;

procedure TLiveColorPicker.ColorPickerMouseUp(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : integer);
begin
  if Sender = FHueImage then self.SelectHue(X, Y)
  else self.SelectSaturationValue(X, Y);;
  TComponent(Sender).Tag := 0;
end;

{ TFormHelper }

function TFormHelper.MouseOverForm : boolean;
var
  Pointi : TPoint;
begin
  Pointi := ScreenToClient(Mouse.CursorPos);
  Result := ((Left <= Pointi.X) and (Left + Width >= Pointi.X)) and ((Top <= Pointi.Y) and (Top + Height >= Pointi.Y));
end;

procedure TFormHelper.PositionToolWindow;
var
  TargetMonitor : TMonitor;
  rightMost, i : integer;
begin
  rightMost := -100000;
  TargetMonitor := nil;
  for i := 0 to Screen.MonitorCount - 1 do
    if rightMost < Screen.Monitors[i].WorkareaRect.Right then
    begin
      TargetMonitor := Screen.Monitors[i];
      rightMost := TargetMonitor.WorkareaRect.Right;
    end;
  if not assigned(TargetMonitor) then TargetMonitor := Screen.PrimaryMonitor;
  if TargetMonitor.Handle = Screen.PrimaryMonitor.Handle then
  begin
    self.Top := Screen.WorkareaRect.Top;
    self.Height := Screen.WorkareaRect.Height;
    self.Left := Screen.WorkareaRect.Right - self.Width;
  end
  else
  begin
    self.Top := TargetMonitor.WorkareaRect.Top;
    self.Height := TargetMonitor.WorkareaRect.Height;
    self.Left := TargetMonitor.WorkareaRect.Left;
  end;
end;

{ VCLSingleField }

constructor VCLSingleField.Create(Range : single; ComponentType : EnumSingleComponent);
begin
  FRange := Range;
  case ComponentType of
    isTrackBar : FBindingClass := TSingleTrackBarBinding;
    isEdit : FBindingClass := TSingleEditBinding;
  else raise Exception.Create('VCLIntegerField: Unknown Componenttype.');
  end;
end;

constructor VCLSingleField.Create(ComponentType : EnumSingleComponent);
begin
  Create(1.0, ComponentType);
end;

{ VCLStringField }

constructor VCLStringField.Create(ComponentType : EnumStringComponent);
begin
  case ComponentType of
    scEdit : FBindingClass := TStringEditBinding;
    scMemo : FBindingClass := TStringTextFieldBinding;
  end;
end;

{ VCLCallable }

constructor VCLCallable.Create(Caption : string);
begin
  FCaption := Caption;
  FBindingClass := TCallableBinding;
end;

{ TFormGenerator }

class function TFormGenerator.GenerateForm(Target : TControl; FormTemplate : Pointer) : TBoundForm;
var
  inserted : TControl;
  context : TRTTIContext;

  procedure InsertSpacer();
  begin
    inserted := TPanel.Create(Target);
    inserted.SetParentComponent(Target);
    inserted.Align := alTop;
    inserted.Top := 0;
    inserted.Height := 7;
    TPanel(inserted).BevelOuter := bvNone;
  end;

  function GetVCLFieldAttributes : TArray<TClass>;
  var
    rttiType : TRttiType;
    attributes : TList<TClass>;
  begin
    attributes := TList<TClass>.Create;
    for rttiType in context.GetTypes do
      // any descandant from VCLPropertyField can used to annotated a property
      if rttiType.IsInstance and rttiType.AsInstance.MetaclassType.InheritsFrom(VCLPropertyField) then
          attributes.Add(rttiType.AsInstance.MetaclassType);
    Result := attributes.ToArray;
    attributes.Free;
  end;

  procedure CreateBindingsForMember(RttiUnified : TRttiMemberUnified);
  var
    attributes : TArray<TCustomAttribute>;
    attribute : TCustomAttribute;
    binding : TBoundComponent;
  begin
    attributes := RttiUnified.GetAttributes;
    // any VCLFieldAttribute found -> create binding
    if HArray.SearchClassInArray<TCustomAttribute>(GetVCLFieldAttributes, attributes, @attribute) then
    begin
      // label with propertyname
      inserted := TLabel.Create(Target);
      inserted.SetParentComponent(Target);
      inserted.Align := alTop;
      inserted.Top := 0;
      inserted.Name := RttiUnified.Name + inttostr(Gettickcount);
      TLabel(inserted).Caption := RttiUnified.Name;
      // create binding
      assert(attribute is VCLPropertyField);
      if not assigned(VCLField(attribute).FBindingClass) then
          raise Exception.Create(attribute.ClassName + ' - no bindingclass ist set.');
      binding := VCLPropertyField(attribute).FBindingClass.Create(Target, RttiUnified, attribute);
      binding.FBoundForm := Result;
      // BindingForm owns binding
      Result.FBindings.Add(binding);
      // Spacer
      InsertSpacer;
    end
    else RttiUnified.Free;
  end;

var

  rttiType : TRttiType;
  RttiProperty : TRttiProperty;
  rttiField : TRttiField;
  rttiMethod : TRttiMethod;
  attributes : TArray<TCustomAttribute>;
  attribute : TCustomAttribute;
  binding : TBoundComponent;

begin
  Target.RemoveAllComponents();
  rttiType := context.GetType(FormTemplate);
  Result := TBoundForm.Create(Target, rttiType);
  for RttiProperty in rttiType.GetProperties do
  begin
    CreateBindingsForMember(TRttiMemberUnified.Create(RttiProperty));
  end;
  for rttiField in rttiType.GetFields do
  begin
    CreateBindingsForMember(TRttiMemberUnified.Create(rttiField));
  end;
  for rttiMethod in rttiType.GetMethods do
  begin
    attributes := rttiMethod.GetAttributes;
    // any VCLFieldAttribute found -> create binding
    if HArray.SearchClassInArray<TCustomAttribute>(VCLCallable, attributes, @attribute) then
    begin
      // create binding
      assert(attribute is VCLField);
      if not assigned(VCLField(attribute).FBindingClass) then
          raise Exception.Create(attribute.ClassName + ' - no bindingclass ist set.');
      binding := VCLField(attribute).FBindingClass.Create(Target, TRttiMemberUnified.Create(rttiMethod), attribute);
      binding.FBoundForm := Result;
      // BindingForm owns binding
      Result.FBindings.Add(binding);
      // Spacer
      InsertSpacer;
    end;
  end;
  Result.Sort;
end;

class function TFormGenerator.GenerateForm(Target : TControl; FormTemplate : TClass) : TBoundForm;
begin
  Result := TFormGenerator.GenerateForm(Target, FormTemplate.ClassInfo);
end;

{ VCLIntegerField }

constructor VCLIntegerField.Create(Min, Max : integer; ComponentType : EnumIntegerComponent);
begin
  FMin := Min;
  FMax := Max;
  case ComponentType of
    icTrackBar : FBindingClass := TIntegerTrackBarBinding;
    icSpinEdit : FBindingClass := TIntegerSpinEditBinding;
  else raise Exception.Create('VCLIntegerField: Unknown Componenttype.');
  end;
end;

{ VCLRVector2Field }

constructor VCLRVector2Field.Create(xRange, yRange : single);
begin
  FRange := RVector2.Create(xRange, yRange);
  FBindingClass := TRVector2Binding;
end;

{ VCLVariedIntegerField }

constructor VCLVariedIntegerField.Create(Min, Max, VARIANCE : integer; ComponentType : EnumIntegerComponent = icTrackBar);
begin
  FMin := Min;
  FMax := Max;
  FVariance := VARIANCE;
  case ComponentType of
    icTrackBar : FBindingClass := TVariedIntegerBinding;
    icEdit : FBindingClass := TVariedIntegerEditBinding;
  else raise Exception.Create('VCLVariedIntegerField: Unknown Componenttype.');
  end;
end;

{ VCLVariedRVector2Field }

constructor VCLVariedRVector2Field.Create(xRangeMean, xRangeVariance, yRangeMean, yRangeVariance : single);
begin
  FValue := RVariedVector2.Create(xRangeMean, yRangeMean, xRangeVariance, yRangeVariance);
  FBindingClass := TVariedRVector2Binding;
end;

{ VCLVariedSingleField }

constructor VCLVariedSingleField.Create(RangeMean, RangeVariance : single; ComponentType : EnumSingleComponent = isTrackBar);
begin
  FValue := RVariedSingle.Create(RangeMean, RangeVariance);
  case ComponentType of
    isTrackBar : FBindingClass := TVariedSingleBinding;
    isEdit : FBindingClass := TVariedSingleEditBinding;
  else raise Exception.Create('VCLVariedSingleField: Unknown Componenttype.');
  end;
end;

{ TBoundForm }

constructor TBoundForm.Create(ParentControl : TControl; RttiInfo : TRttiType);
begin
  FControl := ParentControl;
  FRttiInfo := RttiInfo;
  FBindings := TObjectList<TBoundComponent>.Create();
end;

destructor TBoundForm.Destroy;
begin
  FBindings.Free;
  inherited;
end;

procedure TBoundForm.ExternChange;
begin
  ReadValuesFromInstance;
end;

procedure TBoundForm.ReadValuesFromInstance;
var
  binding : TBoundComponent;
begin
  for binding in FBindings do
  begin
    assert(assigned(binding.FRttiInfo));
    binding.BlockChanges := True;
    binding.WriteValueToComponents;
    binding.BlockChanges := False;
  end;
end;

procedure TBoundForm.setInstance(const Value : Pointer);
begin
  FInstance := Value;
  if assigned(FInstance) then ReadValuesFromInstance;
end;

procedure TBoundForm.SetUpInstance(instance : Pointer);
begin
  FInstance := instance;
  if assigned(FInstance) then WriteValuesToInstance;
end;

procedure TBoundForm.Sort;
var
  i : integer;
begin
  for i := FControl.ComponentCount - 1 downto 0 do
    if FControl.Components[i] is TControl then
    begin
      TControl(FControl.Components[i]).Top := 0;
    end;
end;

procedure TBoundForm.WriteValuesToInstance;
var
  binding : TBoundComponent;
begin
  for binding in FBindings do
  begin
    binding.WriteValueToInstance;
  end;
end;

{ TBoundComponent }

constructor TBoundComponent.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  FTargetControl := TargetControl;
  FRttiInfo := RttiInfo;
  FComponents := TList<TControl>.Create;
end;

function TBoundComponent.CreateComponent(Component : CControl; aTarget : TControl) : TControl;
begin
  if aTarget = nil then aTarget := FTargetControl;
  Result := Component.Create(aTarget);
  Result.SetParentComponent(aTarget);
  Result.Align := alTop;
  Result.Top := 0;

  if Component = TTrackBar then
  begin
    FComponents.Add(Result);
    TTrackBar(Result).PositionToolTip := ptTop;
    TTrackBar(Result).TickMarks := tmBoth;
    TTrackBar(Result).TickStyle := tsNone;
    TTrackBar(Result).OnChange := OnChangeHandler;
    Result.Height := 22;
  end;
  if Component = TSpinEdit then
  begin
    TSpinEdit(Result).OnChange := OnChangeHandler;
    FComponents.Add(Result);
  end;
  if Component = TEdit then
  begin
    TEdit(Result).OnChange := OnChangeHandler;
    FComponents.Add(Result);
  end;
  if Component = TCheckBox then
  begin
    TCheckBox(Result).OnClick := OnChangeHandler;
    FComponents.Add(Result);
  end;
  if Component = TRadioGroup then TRadioGroup(Result).OnClick := OnChangeHandler;
  // if Component = TPanel then TPanel(Result).BevelOuter := bvNone;
end;

function TBoundComponent.CreateSingleField(Name : string; attribute : TCustomAttribute; index : integer) : TControl;
var
  negative : boolean;
begin
  Result := CreateComponent(TTrackBar);
  Result.Name := name;
  negative := False;
  if attribute is VCLSingleField then
  begin
    Result.Tag := Math.Ceil(VCLSingleField(attribute).FRange);
    negative := VCLSingleField(attribute).FWithNegativeRange;
  end
  else if attribute is VCLRVector2Field then
  begin
    Result.Tag := Math.Ceil(VCLRVector2Field(attribute).FRange.Element[index]);
    negative := VCLRVector2Field(attribute).FWithNegativeRange;
  end
  else if attribute is VCLRVector3Field then
  begin
    Result.Tag := Math.Ceil(VCLRVector3Field(attribute).FRange.Element[index]);
    negative := VCLRVector3Field(attribute).FWithNegativeRange;
  end
  else if (attribute is VCLRVector4Field) or (attribute is VCLRColorField) then
  begin
    Result.Tag := Math.Ceil(VCLRVector4Field(attribute).FRange.Element[index]);
    negative := VCLRVector4Field(attribute).FWithNegativeRange;
  end
  else assert(False);
  if negative then
  begin
    TTrackBar(Result).Min := -125;
    TTrackBar(Result).Max := 125;
  end
  else
  begin
    TTrackBar(Result).Min := 0;
    TTrackBar(Result).Max := 250;
  end;
end;

procedure TBoundComponent.CreateVariedEditField(Name : string; attribute : TCustomAttribute; index : integer);
var
  panel : TControl;
  Result : TControl;
begin
  panel := CreateComponent(TPanel);
  panel.Height := 22;
  panel.Width := FTargetControl.Width;
  // Mean edit
  Result := CreateComponent(TEdit, panel);
  Result.Align := alLeft;
  Result.Width := panel.Width div 2;
  Result.Name := name + 'Mean_Edit';
  // Variance edit
  Result := CreateComponent(TEdit, panel);
  Result.Align := alRight;
  Result.Width := panel.Width div 2;
  Result.Name := name + 'Variance_Edit';
end;

procedure TBoundComponent.CreateVariedField(Name : string; attribute : TCustomAttribute; index : integer = 0);
var
  panel : TControl;
  Result : TControl;
begin
  panel := CreateComponent(TPanel);
  panel.Height := 22;
  panel.Width := FTargetControl.Width;
  // Mean slider
  Result := CreateComponent(TTrackBar, panel);
  Result.Align := alLeft;
  Result.Width := panel.Width div 2;
  Result.Name := name + 'Mean_Track';
  if attribute is VCLVariedIntegerField then
  begin
    TTrackBar(Result).Min := VCLVariedIntegerField(attribute).FMin;
    TTrackBar(Result).Max := VCLVariedIntegerField(attribute).FMax;
  end
  else
  begin
    TTrackBar(Result).Min := 0;
    TTrackBar(Result).Max := 250;
    if attribute is VCLVariedSingleField then Result.Tag := Math.Ceil(VCLVariedSingleField(attribute).FValue.MEAN)
    else if attribute is VCLVariedRVector2Field then Result.Tag := Math.Ceil(VCLVariedRVector2Field(attribute).FValue.MEAN.Element[index])
    else if attribute is VCLVariedRVector3Field then Result.Tag := Math.Ceil(VCLVariedRVector3Field(attribute).FValue.MEAN.Element[index])
    else if (attribute is VCLVariedRVector4Field) or (attribute is VCLVariedRColorField) then Result.Tag := Math.Ceil(VCLVariedRVector4Field(attribute).FValue.MEAN.Element[index])
    else assert(False);
  end;
  // Variance slider
  Result := CreateComponent(TTrackBar, panel);
  Result.Align := alRight;
  Result.Width := panel.Width div 2;
  Result.Name := name + 'Variance_Track';
  if attribute is VCLVariedIntegerField then
  begin
    TTrackBar(Result).Min := 0;
    TTrackBar(Result).Max := VCLVariedIntegerField(attribute).FVariance;
  end
  else
  begin
    TTrackBar(Result).Min := 0;
    TTrackBar(Result).Max := 250;
    if attribute is VCLVariedSingleField then Result.Tag := Math.Ceil(VCLVariedSingleField(attribute).FValue.VARIANCE)
    else if attribute is VCLVariedRVector2Field then Result.Tag := Math.Ceil(VCLVariedRVector2Field(attribute).FValue.VARIANCE.Element[index])
    else if attribute is VCLVariedRVector3Field then Result.Tag := Math.Ceil(VCLVariedRVector3Field(attribute).FValue.VARIANCE.Element[index])
    else if (attribute is VCLVariedRVector4Field) or (attribute is VCLVariedRColorField) then Result.Tag := Math.Ceil(VCLVariedRVector4Field(attribute).FValue.VARIANCE.Element[index])
    else assert(False);
  end;
end;

destructor TBoundComponent.Destroy;
begin
  FRttiInfo.Free;
  FComponents.Free;
  inherited;
end;

function TBoundComponent.GetInstanceValue : TValue;
begin
  assert(assigned(FRttiInfo));
  Result := FRttiInfo.GetValueFromRawPointer(FBoundForm.FInstance);
end;

procedure TBoundComponent.OnChangeHandler(Sender : TObject);
var
  NewValue : TValue;
begin
  if assigned(FBoundForm) and assigned(FBoundForm.FInstance) and not FBlockChanges then
  begin
    assert(assigned(FRttiInfo));
    NewValue := ReadValueFromComponents();
    FRttiInfo.SetValueToRawPointer(FBoundForm.FInstance, NewValue);
    if assigned(FBoundForm.OnChange) then
        FBoundForm.OnChange(FRttiInfo.Name, NewValue);
  end;
end;

function TBoundComponent.ReadValueFromComponents : TValue;
begin

end;

procedure TBoundComponent.WriteValueToComponents;
begin

end;

procedure TBoundComponent.WriteValueToInstance;
begin
  FRttiInfo.SetValueToRawPointer(FBoundForm.FInstance, ReadValueFromComponents);
end;

{ TFileBinding }

constructor TFileBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  FComponents.Add(CreateComponent(TEdit));
  FComponents[0].Name := RttiInfo.Name + '_Edit';
  TEdit(FComponents[0]).Text := '';
  FComponents.Add(CreateComponent(TButton));
  TButton(FComponents[FComponents.Count - 1]).Caption := 'Load File';
  TButton(FComponents[FComponents.Count - 1]).OnClick := OnClickHandler;
end;

procedure TFileBinding.OnClickHandler(Sender : TObject);
var
  openDialog : topendialog;
begin
  openDialog := topendialog.Create(nil);
  openDialog.Options := [ofFileMustExist];
  openDialog.InitialDir := GetCurrentDir;
  openDialog.Filter := 'Image files(*.tga *.jpg *.png)|*.tga;*.jpg;*.png|All Files(*.*)|*.*';

  if assigned(FBoundForm) and assigned(FBoundForm.FInstance) and not FBlockChanges and openDialog.Execute then
  begin
    TEdit(FComponents[0]).Text := openDialog.FileName;
    WriteValueToInstance;
  end;
  openDialog.Free;
end;

function TFileBinding.ReadValueFromComponents : TValue;
begin
  Result := TEdit(FComponents[0]).Text;
end;

procedure TFileBinding.WriteValueToComponents;
begin
  TEdit(FComponents[0]).Text := GetInstanceValue.AsType<string>;
end;

{ TEditInstanceBinding }

constructor TEditInstanceBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  FComponents.Add(CreateComponent(TPanel));
  // TPanel(FComponents[0]).Name := RttiInfo.Name + '_Panel';
  TPanel(FComponents[0]).AutoSize := True;
end;

destructor TEditInstanceBinding.Destroy;
begin
  FInstanceBoundForm.Free;
  inherited;
end;

procedure TEditInstanceBinding.InstanceChangeHandler(Sender : string; NewValue : TValue);
begin
  WriteValueToInstance;
  if assigned(FBoundForm.FOnChange) then
      FBoundForm.FOnChange('', TValue.Empty);
end;

function TEditInstanceBinding.ReadValueFromComponents : TValue;
begin
  Result := FValue;
end;

procedure TEditInstanceBinding.WriteValueToComponents;
begin
  inherited;
  FComponents[0].RemoveAllComponents();
  FreeAndNil(FInstanceBoundForm);
  FValue := GetInstanceValue;
  FInstanceBoundForm := TFormGenerator.GenerateForm(FComponents[0], FValue.TypeInfo);
  FInstanceBoundForm.OnChange := InstanceChangeHandler;
  FInstanceBoundForm.FParentForm := FBoundForm;
  if FValue.IsObject then
      FInstanceBoundForm.BoundInstance := FValue.AsObject
  else
      FInstanceBoundForm.BoundInstance := FValue.GetReferenceToRawData;
end;

{ TListBinding }

constructor TListBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
var
  arrayRttiType : TRttiDynamicArrayType;
  itemType : TRttiType;
  itemTypes : TList<TRttiType>;
  menuItem : TMenuItem;
begin
  inherited;
  FComponents.Add(CreateComponent(TListbox));
  FComponents[0].Name := RttiInfo.Name + '_List';
  FOptions := VCLListField(Data).FOptions;
  if loEditItem in FOptions then
  begin

    TListbox(FComponents[0]).OnClick := OnClickHandler;
    FComponents.Add(CreateComponent(TPanel));
    FItemControl := FComponents[1];
    TPanel(FItemControl).AutoSize := True;
    // has to be a class
    assert(RttiInfo.MemberType.IsInstance);
    if not(ContainsText(RttiInfo.MemberType.Name, 'TObjectList') or
      ContainsText(RttiInfo.MemberType.Name, 'TList')) then
        ENotSupportedException.CreateFmt('TListBinding does only supports TObjectList<> and TList<>, not %s.', [RttiInfo.MemberType.Name]);
    // test itemtype
    FArrayField := RttiInfo.MemberType.GetField('FItems');
    arrayRttiType := TRttiDynamicArrayType(FArrayField.FieldType);
    if not(arrayRttiType.ElementType.TypeKind in [tkClass, tkRecord]) then
        raise ENotSupportedException.CreateFmt('TListBinding: EditContent is only supported for lists containing class or record types, not for "%S"', [arrayRttiType.ElementType.Name]);
    // !!!! Do not create EditForm for items here, because item class can be a descandant of the class from list, and edit
    // should edit complete properties, not only from parent

    // create PopMenu if any options for popmenu are active
    if (loDeleteItem in FOptions) or (loAddItem in FOptions) then
    begin
      FPopMenu := TPopupMenu.Create(FComponents[0]);
      TListbox(FComponents[0]).PopupMenu := FPopMenu;
      if loAddItem in FOptions then
      begin
        itemType := arrayRttiType.ElementType;
        itemTypes := TList<TRttiType>.Create;
        if arrayRttiType.ElementType.IsRecord then
            itemTypes.Add(itemType)
        else
        begin
          assert(arrayRttiType.ElementType.IsInstance);
          for itemType in arrayRttiType.ElementType.Package.GetTypes do
            if itemType.IsInstance then
            begin
              if itemType.AsInstance.MetaclassType.InheritsFrom(arrayRttiType.ElementType.AsInstance.MetaclassType) and
                (itemType.AsInstance.MetaclassType <> arrayRttiType.ElementType.AsInstance.MetaclassType) then
              begin
                itemTypes.Add(itemType);
              end;
            end;
          // no descandant for itemType found?, use arrayRttiType.ElementType
          if itemTypes.Count = 0 then
              itemTypes.Add(arrayRttiType.ElementType);
        end;
        for itemType in itemTypes do
        begin
          menuItem := TMenuItem.Create(FPopMenu);
          menuItem.Caption := 'Add ' + itemType.Name;
          // tag will in addcaller used to identify class
          menuItem.Tag := NativeInt(itemType);
          menuItem.OnClick := MenuItemAddHandler;
          FPopMenu.Items.Add(menuItem);
        end;
        itemTypes.Free;
      end;
      if loDeleteItem in FOptions then
      begin
        menuItem := TMenuItem.Create(FPopMenu);
        menuItem.Caption := 'Delete Item';
        menuItem.OnClick := MenuItemDeleteHandler;
        FPopMenu.Items.Add(menuItem);
      end;
    end;
  end;
end;

destructor TListBinding.Destroy;
begin
  FItemBoundForm.Free;
  inherited;
end;

procedure TListBinding.ItemChangedHandler(Sender : string; NewValue : TValue);
var
  itemIndex : integer;
begin
  itemIndex := TListbox(FComponents[0]).itemIndex;
  if itemIndex >= 0 then
  begin
    FArrayField.GetValue(GetInstanceValue.AsObject).SetArrayElement(itemIndex, FItem);
  end;
  if assigned(FBoundForm.FOnChange) then
      FBoundForm.OnChange(Sender, NewValue);
end;

procedure TListBinding.MenuItemAddHandler(Sender : TObject);
var
  rttiType : TRttiType;
  createMethod, rttiMethod, addMethod : TRttiMethod;
  newItem : TValue;
  zeroarray : array [0 .. 10000] of byte;
begin
  assert(Sender is TMenuItem);
  rttiType := TRttiType(TMenuItem(Sender).Tag);
  // search for a parameterless constructor
  createMethod := nil;
  for rttiMethod in rttiType.GetMethods do
  begin
    if rttiMethod.IsConstructor and (rttiMethod.ParameterCount <= 0)
    // don't allow constructors from an parentype (e.g. TObject)
      and (rttiMethod.Parent.Name = rttiType.Name) then
    begin
      createMethod := rttiMethod;
      break;
    end;
  end;
  if (not rttiType.IsRecord) then
  begin
    if (createMethod = nil) then
        raise ENotSupportedException.CreateFmt('TListBinding: Could not find any parameterless constructor for type "%s". ' +
        'Hint: Any constructor from parentclass are ignored to avoid the use of constructors from TObject.', [rttiType.Name]);
    // create a new instance of target type
    if rttiType.IsInstance then
        newItem := createMethod.Invoke(rttiType.AsInstance.MetaclassType, [])
    else
        newItem := createMethod.Invoke(nil, []);
  end
  else
  begin
    ZeroMemory(@zeroarray[0], length(zeroarray));
    TValue.Make(@zeroarray[0], rttiType.Handle, newItem);
  end;

  // add new item to list
  addMethod := FRttiInfo.MemberType.GetMethod('Add');
  assert(assigned(addMethod));
  addMethod.Invoke(GetInstanceValue, [newItem]);
  WriteValueToComponents;
  if assigned(FBoundForm.OnChange) then
      FBoundForm.OnChange('', TValue.Empty);
end;

procedure TListBinding.MenuItemDeleteHandler(Sender : TObject);
var
  itemIndex : integer;
  deleteMethod : TRttiMethod;
  item : TValue;
  rootForm : TBoundForm;
  alreadyChecked : TDictionary<TObject, boolean>;

  /// <summary> Search with deepsearch in class/record (instance) for any occurent of target object(item) and delete
  /// all refrences to object.</summary>
  procedure TraverseRttiTree(instance : Pointer; BaseType : TRttiType);
    procedure CheckMember(Member : TRttiMemberUnified);
    var
      Value : TValue;
      i : integer;
      list : TList<TObject>;
      arraytype : TRttiDynamicArrayType;
      arrayvalue : TValue;
      arrayitem : TValue;
    begin
      if assigned(Member.MemberType) and (Member.MemberType.TypeKind in [tkClass, tkRecord]) and HArray.SearchClassInArray<TCustomAttribute>(VCLPropertyField, Member.GetAttributes) then
      begin
        Value := Member.GetValueFromRawPointer(instance);
        // same reference? clear member content, because reference does not longer exists
        if Value.IsObject and (Value.AsObject = item.AsObject) then
            Member.SetValueToRawPointer(instance, TValue.Empty)
        else
          // skip every object that already in dict, because the object was already checked for any reference
          // does not add records
          if (not Value.IsObject) or ((Value.AsObject <> nil) and not alreadyChecked.ContainsKey(Value.AsObject)) then
          // no refrence? search in all members of type for reference
          begin
            if ContainsText(Member.MemberType.Name, 'TObjectList') or ContainsText(Member.MemberType.Name, 'TList') then
            begin
              list := TList<TObject>(Value.AsObject);
              // if list contains item, delete it
              if Member.MemberType.GetField('FItems').FieldType.IsInstance and (list.IndexOf(item.AsObject) >= 0) then
              begin
                list.Delete(list.IndexOf(item.AsObject));
              end
              else
              begin
                arraytype := TRttiDynamicArrayType(Member.MemberType.GetField('FItems').FieldType);
                arrayvalue := Member.MemberType.GetField('FItems').GetValue(Value.AsObject);
                for i := 0 to list.Count - 1 do
                begin
                  arrayitem := arrayvalue.GetArrayElement(i);
                  if arrayitem.IsObject and (arrayitem.AsObject <> nil) then
                      TraverseRttiTree(arrayitem.AsObject, arraytype.ElementType)
                  else
                  begin
                    TraverseRttiTree(arrayitem.GetReferenceToRawData, arraytype.ElementType);
                    arrayvalue.SetArrayElement(i, arrayitem);
                  end;
                end;
              end;
            end
            else
            begin
              // object
              if Value.IsObject then
              begin
                alreadyChecked.Add(Value.AsObject, True);
                TraverseRttiTree(Value.AsObject, Member.MemberType);
              end
              else
              // record
              begin
                TraverseRttiTree(Value.GetReferenceToRawData, Member.MemberType);
                // write record back
                Member.SetValueToRawPointer(instance, Value);
              end;

            end;
          end;
      end;
      Member.Free;
    end;

  var
    field : TRttiField;
    prop : TRttiProperty;
  begin
    for field in BaseType.GetFields do
    begin
      CheckMember(TRttiMemberUnified.Create(field));
    end;
    for prop in BaseType.GetProperties do
    begin
      CheckMember(TRttiMemberUnified.Create(prop));
    end;
  end;

begin
  itemIndex := TListbox(FComponents[0]).itemIndex;
  if itemIndex >= 0 then
  begin
    item := FArrayField.GetValue(GetInstanceValue.AsObject).GetArrayElement(itemIndex);
    deleteMethod := FRttiInfo.MemberType.GetMethod('Delete');
    assert(assigned(deleteMethod));
    deleteMethod.Invoke(GetInstanceValue, [itemIndex]);
    // no need for seperate free object here, because if List owns object, delete will already free object
    // if item.IsObject then
    // item.AsObject.Free;
    // list changed -> update components
    if loDeleteAllRefrencesToItem in FOptions then
    begin
      assert(item.IsObject);
      // go to rootForm
      rootForm := FBoundForm;
      while assigned(rootForm.FParentForm) do
          rootForm := rootForm.FParentForm;
      alreadyChecked := TDictionary<TObject, boolean>.Create();
      // call OnDelete callback in rootform, to inform user
      if assigned(rootForm.OnDelete) then rootForm.OnDelete(item.AsObject);
      TraverseRttiTree(rootForm.FInstance, rootForm.FRttiInfo);
      alreadyChecked.Free;
      rootForm.ReadValuesFromInstance;
    end
    else WriteValueToComponents;
  end;
end;

procedure TListBinding.OnClickHandler(Sender : TObject);
var
  itemIndex : integer;
begin
  SendMessage(TWinControl(FItemControl).Handle, WM_SETREDRAW, 0, 0);
  TPanel(FItemControl).DisableAlign;
  itemIndex := TListbox(FComponents[0]).itemIndex;
  // first clear current editform for item
  FItem := TValue.Empty;
  FreeAndNil(FItemBoundForm);
  FItemControl.RemoveAllComponents();
  if itemIndex >= 0 then
  begin
    // can cast object to TList, because only TObjectList<> and TList<> containing a classtype are allowed
    FItem := FArrayField.GetValue(GetInstanceValue.AsObject).GetArrayElement(itemIndex);
    FItemBoundForm := TFormGenerator.GenerateForm(FItemControl, FItem.TypeInfo);
    FItemBoundForm.OnChange := ItemChangedHandler;
    FItemBoundForm.FParentForm := FBoundForm;
    if FItem.IsObject then
        FItemBoundForm.BoundInstance := FItem.AsObject
    else
        FItemBoundForm.BoundInstance := FItem.GetReferenceToRawData;
  end;
  TPanel(FItemControl).EnableAlign;
  SendMessage(TPanel(FItemControl).Handle, WM_SETREDRAW, -1, 0);
  if assigned(FItemBoundForm) then FItemBoundForm.Sort;
  RedrawWindow(TPanel(FItemControl).Handle, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN);
end;

function TListBinding.ReadValueFromComponents : TValue;
begin
  raise ENotSupportedException.Create('TListBinding: ReadOnly!');
end;

procedure TListBinding.WriteValueToComponents;
var
  i : integer;
  list : TList<TObject>;
  arrayvalue, item : TValue;
  listobj : TObject;
begin
  listobj := GetInstanceValue.AsObject;
  list := TList<TObject>(Pointer(@listobj)^);
  TListbox(FComponents[0]).Clear;
  FreeAndNil(FItemBoundForm);
  FItemControl.RemoveAllComponents();
  if list <> nil then
  begin
    arrayvalue := FArrayField.GetValue(list);
    assert(arrayvalue.Kind = tkDynArray);
    // can't use list.GetArrayLength, because array could cotain more elements then list actually contains,
    // because array usually grows in big steps for performance
    for i := 0 to list.Count - 1 do
    begin
      item := arrayvalue.GetArrayElement(i);
      TListbox(FComponents[0]).Items.Add(TRttiDynamicArrayType(FArrayField.FieldType).ElementType.Name + inttostr(i));
    end;
  end;
end;

{ TListChoiceBinding }

constructor TListChoiceBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
var
  i : integer;
begin
  inherited;
  FComponents.Add(CreateComponent(TComboBox));
  TComboBox(FComponents[0]).Name := RttiInfo.Name + '_ComboBox';
  TComboBox(FComponents[0]).Text := RttiInfo.Name;
  TComboBox(FComponents[0]).OnChange := OnChangeHandler;
  FChoicesSourePath := TList<string>.Create;
  FChoicesSourePath.AddRange(VCLListChoiceField(Data).FChoicesSourcePath.Split(['.']));
  // replace all parent keywords by levelup instruction
  for i := 0 to FChoicesSourePath.Count - 1 do
  begin
    if CompareText(FChoicesSourePath[i], 'inherited') = 0 then
        FChoicesSourePath[i] := LEVLEUP;
  end;
end;

destructor TListChoiceBinding.Destroy;
begin
  FChoicesSourePath.Free;
  inherited;
end;

function TListChoiceBinding.GetChoicesList : TList<TObject>;
var
  instance : TObject;
  instruction : string;
  rttiContext : TRTTIContext;
  rttiType : TRttiType;
  RttiProperty : TRttiProperty;
begin
  RttiProperty := nil;
  rttiContext := TRTTIContext.Create;
  assert(assigned(FBoundForm.BoundInstance));
  // init with boundform, because path could go serveral levels up until use the real instance
  instance := FBoundForm;
  if FChoicesSourePath.Count <= 0 then
      raise ENotSupportedException.Create('TListChoiceBinding: Sourcepath is empty!');
  for instruction in FChoicesSourePath do
  begin
    if instruction <> LEVLEUP then
      if instance is TBoundForm then
          instance := TBoundForm(instance).BoundInstance;
    if instruction = LEVLEUP then
    begin
      if not(instance is TBoundForm) then
          raise ENotSupportedException.Create('TListChoiceBinding: Couldn''t go levelup (::) after select a property.');
      if not assigned(TBoundForm(instance).FParentForm) then
          raise ENotSupportedException.Create('TListChoiceBinding: Couldn''t go a levelup (::), current form has no parent');
      // if this code reached, all okay -> go a level up
      instance := TBoundForm(instance).FParentForm;
    end
    else
    // select property
    begin
      rttiType := rttiContext.GetType(instance.ClassType);
      RttiProperty := rttiType.GetProperty(instruction);
      if RttiProperty.PropertyType.TypeKind <> tkClass then
          raise ENotSupportedException.CreateFmt('TListChoiceBinding: Only support propertyselection for classtypes, properties "%s" type "%s" is no classtype.',
          [RttiProperty.Name, RttiProperty.PropertyType.Name]);
      // select property and get new instance
      instance := RttiProperty.GetValue(instance).AsObject;
    end;
  end;
  // target instance selected (should be a list), check and return list
  if not(ContainsText(instance.ClassName, 'TList') or (ContainsText(instance.ClassName, 'TObjectList'))) then
      raise ENotSupportedException.CreateFmt('TListChoiceBinding: Finalselection for choicessource musst be a TList<> or TObjectList<>. You have choose property "%s" with type "%s".',
      [RttiProperty.Name, instance.ClassName]);
  Result := TList<TObject>(instance);
  rttiContext.Free;
end;

function TListChoiceBinding.ReadValueFromComponents : TValue;
var
  choicesList : TList<TObject>;
begin
  if TComboBox(FComponents[0]).itemIndex >= 0 then
  begin
    choicesList := GetChoicesList;
    assert(choicesList.Count = TComboBox(FComponents[0]).Items.Count);
    Result := choicesList[TComboBox(FComponents[0]).itemIndex];
  end;
end;

procedure TListChoiceBinding.WriteValueToComponents;
var
  choicesList : TList<TObject>;
  currentItem : TObject;
  i : integer;
begin
  TComboBox(FComponents[0]).Clear;
  currentItem := GetInstanceValue.AsObject;
  choicesList := GetChoicesList;
  for i := 0 to choicesList.Count - 1 do
  begin
    TComboBox(FComponents[0]).Items.Add(choicesList[i].ToString + inttostr(i));
    if choicesList[i] = currentItem then
        TComboBox(FComponents[0]).itemIndex := i;
  end;
end;

{ TSingleBinding }

constructor TSingleTrackBarBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateSingleField(RttiInfo.Name + '_Track', Data, 0);
end;

function TSingleTrackBarBinding.ReadValueFromComponents : TValue;
begin
  Result := TTrackBar(FComponents[0]).Value;
end;

procedure TSingleTrackBarBinding.WriteValueToComponents;
begin
  TTrackBar(FComponents[0]).Value := GetInstanceValue.AsType<single>;
end;

{ TBooleanBinding }

constructor TBooleanBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateComponent(TCheckBox);
  TCheckBox(FComponents[0]).Caption := RttiInfo.Name;
  TCheckBox(FComponents[0]).Name := RttiInfo.Name + '_CheckBox';
end;

function TBooleanBinding.ReadValueFromComponents : TValue;
begin
  Result := TCheckBox(FComponents[0]).Checked;
end;

procedure TBooleanBinding.WriteValueToComponents;
begin
  inherited;
  TCheckBox(FComponents[0]).Checked := GetInstanceValue.AsBoolean;
end;

{ TIntegerTrackBarBinding }

constructor TIntegerTrackBarBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateComponent(TTrackBar);
  FComponents[0].Name := RttiInfo.Name + '_Track';
  TTrackBar(FComponents[0]).Min := VCLIntegerField(Data).FMin;
  TTrackBar(FComponents[0]).Max := VCLIntegerField(Data).FMax;
end;

function TIntegerTrackBarBinding.ReadValueFromComponents : TValue;
begin
  Result := TTrackBar(FComponents[0]).Position;
end;

procedure TIntegerTrackBarBinding.WriteValueToComponents;
begin
  TTrackBar(FComponents[0]).Position := GetInstanceValue.AsInteger;
end;

{ TIntegerSpinEditBinding }

constructor TIntegerSpinEditBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateComponent(TSpinEdit);
  FComponents[0].Name := RttiInfo.Name + '_Spin';
  TSpinEdit(FComponents[0]).MinValue := VCLIntegerField(Data).FMin;
  TSpinEdit(FComponents[0]).MaxValue := VCLIntegerField(Data).FMax;
end;

function TIntegerSpinEditBinding.ReadValueFromComponents : TValue;
begin
  Result := TSpinEdit(FComponents[0]).Value;
end;

procedure TIntegerSpinEditBinding.WriteValueToComponents;
begin
  TSpinEdit(FComponents[0]).Value := GetInstanceValue.AsInteger;
end;

{ VCLFileField }

constructor VCLFileField.Create;
begin
  FBindingClass := TFileBinding;
end;

{ TRVector2Binding }

constructor TRVector2Binding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateSingleField(RttiInfo.Name + 'X_Track', Data, 0);
  CreateSingleField(RttiInfo.Name + 'Y_Track', Data, 1);
end;

function TRVector2Binding.ReadValueFromComponents : TValue;
begin
  Result := TValue.From<RVector2>(RVector2.Create(TTrackBar(FComponents[X]).Value, TTrackBar(FComponents[Y]).Value));
end;

procedure TRVector2Binding.WriteValueToComponents;
begin
  TTrackBar(FComponents[X]).Value := GetInstanceValue.AsType<RVector2>.X;
  TTrackBar(FComponents[Y]).Value := GetInstanceValue.AsType<RVector2>.Y;
end;

{ TVariedIntegerBinding }

constructor TVariedIntegerBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateVariedField(RttiInfo.Name, Data);
end;

function TVariedIntegerBinding.ReadValueFromComponents : TValue;
begin
  Result := TValue.From<RVariedInteger>(RVariedInteger.Create(TTrackBar(FComponents[MEAN]).Position, TTrackBar(FComponents[VARIANCE]).Position));
end;

procedure TVariedIntegerBinding.WriteValueToComponents;
begin
  TTrackBar(FComponents[MEAN]).Position := GetInstanceValue.AsType<RVariedInteger>.MEAN;
  TTrackBar(FComponents[VARIANCE]).Position := GetInstanceValue.AsType<RVariedInteger>.VARIANCE;
end;

{ TVariedSingleBinding }

constructor TVariedSingleBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateVariedField(RttiInfo.Name, Data);
end;

function TVariedSingleBinding.ReadValueFromComponents : TValue;
begin
  Result := TValue.From<RVariedSingle>(RVariedSingle.Create(TTrackBar(FComponents[MEAN]).Value, TTrackBar(FComponents[VARIANCE]).Value));
end;

procedure TVariedSingleBinding.WriteValueToComponents;
begin
  TTrackBar(FComponents[MEAN]).Value := GetInstanceValue.AsType<RVariedSingle>.MEAN;
  TTrackBar(FComponents[VARIANCE]).Value := GetInstanceValue.AsType<RVariedSingle>.VARIANCE;
end;

{ TVariedRVector2Binding }

constructor TVariedRVector2Binding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateVariedField(RttiInfo.Name + 'X_', Data, 0);
  CreateVariedField(RttiInfo.Name + 'Y_', Data, 1);
end;

function TVariedRVector2Binding.ReadValueFromComponents : TValue;
var
  Value : RVariedVector2;
begin
  Value.RadialVaried := False;
  Value.MEAN.X := TTrackBar(FComponents[MEAN_X]).Value;
  Value.MEAN.Y := TTrackBar(FComponents[MEAN_Y]).Value;
  Value.VARIANCE.X := TTrackBar(FComponents[VARIANCE_X]).Value;
  Value.VARIANCE.Y := TTrackBar(FComponents[VARIANCE_Y]).Value;
  Result := TValue.From<RVariedVector2>(Value);
end;

procedure TVariedRVector2Binding.WriteValueToComponents;
begin
  TTrackBar(FComponents[MEAN_X]).Value := GetInstanceValue.AsType<RVariedVector2>.MEAN.X;
  TTrackBar(FComponents[MEAN_Y]).Value := GetInstanceValue.AsType<RVariedVector2>.MEAN.Y;
  TTrackBar(FComponents[VARIANCE_X]).Value := GetInstanceValue.AsType<RVariedVector2>.VARIANCE.X;
  TTrackBar(FComponents[VARIANCE_Y]).Value := GetInstanceValue.AsType<RVariedVector2>.VARIANCE.Y;
end;

{ TCallableBinding }

constructor TCallableBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  FComponents.Add(CreateComponent(TButton));
  TButton(FComponents[0]).Caption := VCLCallable(Data).FCaption;
  TButton(FComponents[0]).OnClick := OnClickHandler;
end;

procedure TCallableBinding.OnClickHandler(Sender : TObject);
begin
  if assigned(FBoundForm) and assigned(FBoundForm.FInstance) and not FBlockChanges then
      FRttiInfo.Invoke(FBoundForm.FInstance, []);
end;

procedure TCallableBinding.WriteValueToInstance;
begin

end;

{ VCLEnumField }

constructor VCLEnumField.Create;
begin
  FBindingClass := TEnumBinding;
end;

{ TEnumBinding }

constructor TEnumBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
var
  i : integer;
begin
  inherited;
  FComponents.Add(CreateComponent(TRadioGroup));
  FComponents[0].Name := RttiInfo.Name + '_Radio';
  TRadioGroup(FComponents[0]).Caption := '';
  assert(RttiInfo.MemberType.TypeKind = tkEnumeration);
  FComponents[0].Height := (RttiInfo.MemberType.AsOrdinal.MaxValue + 1) * 16 + 17;
  ordType := RttiInfo.MemberType.AsOrdinal.Handle;
  for i := 0 to RttiInfo.MemberType.AsOrdinal.MaxValue do
  begin
    TRadioGroup(FComponents[0]).Items.Add(TValue.FromOrdinal(ordType, i).ToString);
    TRadioGroup(FComponents[0]).itemIndex := 0;
  end;
end;

function TEnumBinding.ReadValueFromComponents : TValue;
begin
  Result := TValue.FromOrdinal(ordType, TRadioGroup(FComponents[0]).itemIndex);
end;

procedure TEnumBinding.WriteValueToComponents;
begin
  TRadioGroup(FComponents[0]).itemIndex := GetInstanceValue.AsOrdinal;
end;

{ TPropertyBinding }

constructor TPropertyBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  FTargetControl := TargetControl;
  FRttiInfo := RttiInfo;
  FComponents := TList<TControl>.Create;
end;

{ TStringBinding }

constructor TStringEditBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  FComponents.Add(CreateComponent(TEdit));
  FComponents[0].Name := RttiInfo.Name + '_Edit';
  TEdit(FComponents[0]).Text := '';
end;

function TStringEditBinding.ReadValueFromComponents : TValue;
begin
  Result := TEdit(FComponents[0]).Text;
end;

procedure TStringEditBinding.WriteValueToComponents;
begin
  inherited;
  TEdit(FComponents[0]).Text := GetInstanceValue.AsType<string>;
end;

{ VCLListField }

constructor VCLListField.Create(Options : SetListOptions);
begin
  FBindingClass := TListBinding;
  FOptions := Options;
end;

{ VCLBooleanField }

constructor VCLBooleanField.Create;
begin
  FBindingClass := TBooleanBinding;
end;

{ VCLListChoiceField }

constructor VCLListChoiceField.Create(ChoiceSourcePath : string);
begin
  FBindingClass := TListChoiceBinding;
  FChoicesSourcePath := ChoiceSourcePath;
end;

{ VCLEditInstance }

constructor VCLEditInstance.Create;
begin
  FBindingClass := TEditInstanceBinding;
end;

{ TSingleEditBinding }

constructor TSingleEditBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateComponent(TEdit);
  FComponents[0].Name := RttiInfo.Name + '_Edit';
end;

function TSingleEditBinding.ReadValueFromComponents : TValue;
begin
  Result := StrToFloat(TEdit(FComponents[0]).Text);
end;

procedure TSingleEditBinding.WriteValueToComponents;
begin
  TEdit(FComponents[0]).Text := FloatToStrF(GetInstanceValue.AsExtended, ffGeneral, 4, 4);
end;

{ VCLRVector3Field }

constructor VCLRVector3Field.Create(xRange, yRange, zRange : single; ComponentType : EnumSingleComponent; WithNegativeRange : boolean);
begin
  FRange := RVector3.Create(xRange, yRange, zRange);
  FWithNegativeRange := WithNegativeRange;
  case ComponentType of
    isTrackBar : FBindingClass := TRVector3TrackBarBinding;
    isEdit : FBindingClass := TRVector3EditBinding;
  else raise Exception.Create('VCLIntegerField: Unknown Componenttype.');
  end;
end;

{ TRVector3EditBinding }

constructor TRVector3EditBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateComponent(TEdit);
  CreateComponent(TEdit);
  CreateComponent(TEdit);
  FComponents[X].Name := RttiInfo.Name + 'X_Edit';
  FComponents[Y].Name := RttiInfo.Name + 'Y_Edit';
  FComponents[Z].Name := RttiInfo.Name + 'Z_Edit';
end;

function TRVector3EditBinding.ReadValueFromComponents : TValue;
begin
  Result := TValue.From<RVector3>(RVector3.Create(
    StrToFloat(TEdit(FComponents[X]).Text),
    StrToFloat(TEdit(FComponents[Y]).Text),
    StrToFloat(TEdit(FComponents[Z]).Text)));
end;

procedure TRVector3EditBinding.WriteValueToComponents;
begin
  TEdit(FComponents[X]).Text := FloatToStrF(GetInstanceValue.AsType<RVector3>.X, ffGeneral, 4, 4);
  TEdit(FComponents[Y]).Text := FloatToStrF(GetInstanceValue.AsType<RVector3>.Y, ffGeneral, 4, 4);
  TEdit(FComponents[Z]).Text := FloatToStrF(GetInstanceValue.AsType<RVector3>.Z, ffGeneral, 4, 4);
end;

{ VCLVariedRVector3Field }

constructor VCLVariedRVector3Field.Create;
begin
  FBindingClass := TVariedRVector3EditBinding;
end;

constructor VCLVariedRVector3Field.Create(xRangeMean, xRangeVariance, yRangeMean, yRangeVariance, zRangeMean, zRangeVariance : single);
begin
  FValue := RVariedVector3.Create(RVector3.Create(xRangeMean, yRangeMean, zRangeMean), RVector3.Create(xRangeVariance, yRangeVariance, zRangeVariance));
  FBindingClass := TVariedRVector3TrackBarBinding;
end;

{ TVariedRVector3EditBinding }

constructor TVariedRVector3EditBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateVariedEditField(RttiInfo.Name + 'X_', Data, 0);
  CreateVariedEditField(RttiInfo.Name + 'Y_', Data, 1);
  CreateVariedEditField(RttiInfo.Name + 'Z_', Data, 2);
end;

function TVariedRVector3EditBinding.ReadValueFromComponents : TValue;
var
  Value : RVariedVector3;
begin
  Value.RadialVaried := False;
  Value.MEAN.X := StrToFloat(TEdit(FComponents[MEAN_X]).Text);
  Value.MEAN.Y := StrToFloat(TEdit(FComponents[MEAN_Y]).Text);
  Value.MEAN.Z := StrToFloat(TEdit(FComponents[MEAN_Z]).Text);
  Value.VARIANCE.X := StrToFloat(TEdit(FComponents[VARIANCE_X]).Text);
  Value.VARIANCE.Y := StrToFloat(TEdit(FComponents[VARIANCE_Y]).Text);
  Value.VARIANCE.Z := StrToFloat(TEdit(FComponents[VARIANCE_Z]).Text);
  Result := TValue.From<RVariedVector3>(Value);
end;

procedure TVariedRVector3EditBinding.WriteValueToComponents;
begin
  TEdit(FComponents[MEAN_X]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedVector3>.MEAN.X, ffGeneral, 4, 4);
  TEdit(FComponents[MEAN_Y]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedVector3>.MEAN.Y, ffGeneral, 4, 4);
  TEdit(FComponents[MEAN_Z]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedVector3>.MEAN.Z, ffGeneral, 4, 4);
  TEdit(FComponents[VARIANCE_X]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedVector3>.VARIANCE.X, ffGeneral, 4, 4);
  TEdit(FComponents[VARIANCE_Y]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedVector3>.VARIANCE.Y, ffGeneral, 4, 4);
  TEdit(FComponents[VARIANCE_Z]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedVector3>.VARIANCE.Z, ffGeneral, 4, 4);
end;

{ VCLVariedRVector4Field }

constructor VCLVariedRVector4Field.Create(xRangeMean, xRangeVariance,
  yRangeMean, yRangeVariance, zRangeMean, zRangeVariance, wRangeMean,
  wRangeVariance : single);
begin
  FValue := RVariedVector4.Create(RVector4.Create(xRangeMean, yRangeMean, zRangeMean, wRangeMean), RVector4.Create(xRangeVariance, yRangeVariance, zRangeVariance, wRangeVariance));
  FBindingClass := TVariedRVector4TrackBarBinding;
end;

{ TVariedRVector4TrackBarBinding }

constructor TVariedRVectorTrackBarBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  if Dimensions > 0 then CreateVariedField(RttiInfo.Name + 'X_', Data, 0);
  if Dimensions > 1 then CreateVariedField(RttiInfo.Name + 'Y_', Data, 1);
  if Dimensions > 2 then CreateVariedField(RttiInfo.Name + 'Z_', Data, 2);
  if Dimensions > 3 then CreateVariedField(RttiInfo.Name + 'W_', Data, 3);
end;

function TVariedRVectorTrackBarBinding.ReadValueFromComponents : TValue;
var
  Value : RVariedVector4;
begin
  if Dimensions > 0 then Value.MEAN.X := TTrackBar(FComponents[MEAN_X]).Value;
  if Dimensions > 1 then Value.MEAN.Y := TTrackBar(FComponents[MEAN_Y]).Value;
  if Dimensions > 2 then Value.MEAN.Z := TTrackBar(FComponents[MEAN_Z]).Value;
  if Dimensions > 3 then Value.MEAN.W := TTrackBar(FComponents[MEAN_W]).Value;
  if Dimensions > 0 then Value.VARIANCE.X := TTrackBar(FComponents[VARIANCE_X]).Value;
  if Dimensions > 1 then Value.VARIANCE.Y := TTrackBar(FComponents[VARIANCE_Y]).Value;
  if Dimensions > 2 then Value.VARIANCE.Z := TTrackBar(FComponents[VARIANCE_Z]).Value;
  if Dimensions > 3 then Value.VARIANCE.W := TTrackBar(FComponents[VARIANCE_W]).Value;

  if Dimensions > 3 then Result := TValue.From<RVariedVector4>(Value)
  else if Dimensions > 2 then Result := TValue.From<RVariedVector3>(Value.XYZ)
  else if Dimensions > 1 then Result := TValue.From<RVariedVector2>(Value.XY)
  else if Dimensions > 0 then Result := TValue.From<RVariedSingle>(Value.X);
end;

procedure TVariedRVectorTrackBarBinding.WriteValueToComponents;
var
  Value : RVariedVector4;
begin
  if Dimensions > 3 then Value := GetInstanceValue.AsType<RVariedVector4>
  else if Dimensions > 2 then Value.XYZ := GetInstanceValue.AsType<RVariedVector3>
  else if Dimensions > 1 then Value.XY := GetInstanceValue.AsType<RVariedVector2>
  else if Dimensions > 0 then Value.X := GetInstanceValue.AsType<RVariedSingle>;

  if Dimensions > 0 then TTrackBar(FComponents[MEAN_X]).Value := Value.MEAN.X;
  if Dimensions > 1 then TTrackBar(FComponents[MEAN_Y]).Value := Value.MEAN.Y;
  if Dimensions > 2 then TTrackBar(FComponents[MEAN_Z]).Value := Value.MEAN.Z;
  if Dimensions > 3 then TTrackBar(FComponents[MEAN_W]).Value := Value.MEAN.W;
  if Dimensions > 0 then TTrackBar(FComponents[VARIANCE_X]).Value := Value.VARIANCE.X;
  if Dimensions > 1 then TTrackBar(FComponents[VARIANCE_Y]).Value := Value.VARIANCE.Y;
  if Dimensions > 2 then TTrackBar(FComponents[VARIANCE_Z]).Value := Value.VARIANCE.Z;
  if Dimensions > 3 then TTrackBar(FComponents[VARIANCE_W]).Value := Value.VARIANCE.W;
end;

{ TVariedRVector4TrackBarBinding }

function TVariedRVector4TrackBarBinding.Dimensions : integer;
begin
  Result := 4;
end;

{ TVariedSingleEditBinding }

constructor TVariedSingleEditBinding.Create(TargetControl : TControl;
  RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateVariedEditField(RttiInfo.Name, Data, 0);
end;

function TVariedSingleEditBinding.ReadValueFromComponents : TValue;
var
  Value : RVariedSingle;
begin
  Value.MEAN := StrToFloat(TEdit(FComponents[MEAN]).Text);
  Value.VARIANCE := StrToFloat(TEdit(FComponents[VARIANCE]).Text);
  Result := TValue.From<RVariedSingle>(Value);
end;

procedure TVariedSingleEditBinding.WriteValueToComponents;
begin
  TEdit(FComponents[MEAN]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedSingle>.MEAN, ffGeneral, 4, 4);
  TEdit(FComponents[VARIANCE]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedSingle>.VARIANCE, ffGeneral, 4, 4);
end;

{ VCLRVector4Field }

constructor VCLRVector4Field.Create(xRange, yRange, zRange, wRange : single; ComponentType : EnumSingleComponent);
begin
  FRange := RVector4.Create(xRange, yRange, zRange, wRange);
  case ComponentType of
    isTrackBar : FBindingClass := TRVector4TrackBarBinding;
    isEdit : raise ENotImplemented.Create('VCLRVector4Field: TrackBar for RVector4 not available, yet.');
  else raise Exception.Create('VCLRVector4Field: Unknown Componenttype.');
  end;
end;

{ TRVector4TrackBarBinding }

constructor TRVector4TrackBarBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateSingleField(RttiInfo.Name + 'X_', Data, MEAN_X);
  CreateSingleField(RttiInfo.Name + 'Y_', Data, MEAN_Y);
  CreateSingleField(RttiInfo.Name + 'Z_', Data, MEAN_Z);
  CreateSingleField(RttiInfo.Name + 'W_', Data, MEAN_W);
end;

function TRVector4TrackBarBinding.ReadValueFromComponents : TValue;
var
  Value : RVector4;
begin
  Value.X := TTrackBar(FComponents[MEAN_X]).Value;
  Value.Y := TTrackBar(FComponents[MEAN_Y]).Value;
  Value.Z := TTrackBar(FComponents[MEAN_Z]).Value;
  Value.W := TTrackBar(FComponents[MEAN_W]).Value;
  Result := TValue.From<RVector4>(Value);
end;

procedure TRVector4TrackBarBinding.WriteValueToComponents;
var
  Vector : RVector4;
begin
  Vector := GetInstanceValue.AsType<RVector4>;
  TTrackBar(FComponents[MEAN_X]).Value := Vector.X;
  TTrackBar(FComponents[MEAN_Y]).Value := Vector.Y;
  TTrackBar(FComponents[MEAN_Z]).Value := Vector.Z;
  TTrackBar(FComponents[MEAN_W]).Value := Vector.W;
end;

{ TRVector3TrackBarBinding }

constructor TRVector3TrackBarBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateSingleField(RttiInfo.Name + 'X_', Data, 0);
  CreateSingleField(RttiInfo.Name + 'Y_', Data, 1);
  CreateSingleField(RttiInfo.Name + 'Z_', Data, 2);
end;

function TRVector3TrackBarBinding.ReadValueFromComponents : TValue;
var
  Value : RVector3;
begin
  Value.X := TTrackBar(FComponents[0]).Value;
  Value.Y := TTrackBar(FComponents[1]).Value;
  Value.Z := TTrackBar(FComponents[2]).Value;
  Result := TValue.From<RVector3>(Value);
end;

procedure TRVector3TrackBarBinding.WriteValueToComponents;
var
  Value : RVector3;
begin
  Value := GetInstanceValue.AsType<RVector3>;
  TTrackBar(FComponents[0]).Value := Value.X;
  TTrackBar(FComponents[1]).Value := Value.Y;
  TTrackBar(FComponents[2]).Value := Value.Z;
end;

{ TEditHelper }

function TEditHelper.GetSingleValue : single;
begin
  if not TryStrToFloat(Text, Result) then Result := 0;
end;

procedure TEditHelper.setSingleValue(const Value : single);
begin
  Text := FloatToStrF(Value, ffGeneral, 4, 4);
end;

{ TListboxHelper }

procedure TListboxHelper.Select(index : integer; Exclusive : boolean);
begin
  if index >= Count then exit;
  if MultiSelect then
  begin
    if Exclusive then DeselectAll;
    Selected[index] := True
  end
  else itemIndex := index;
end;

procedure TListboxHelper.DeselectAll;
var
  i : integer;
begin
  if MultiSelect then
  begin
    for i := 0 to Items.Count - 1 do
        Selected[i] := False;
  end
  else itemIndex := -1;
end;

procedure TListboxHelper.DeselectBySelectedIndex(index : integer);
begin
  Deselect(SelectedIndices[index]);
end;

function TListboxHelper.GetSelectedIndex(index : integer) : integer;
var
  i : integer;
begin
  Result := -1;
  if index >= SelectionCount then exit;
  if MultiSelect then
  begin
    for i := 0 to Count - 1 do
      if Selected[i] then
      begin
        if index = 0 then
        begin
          Result := i;
          break;
        end;
        dec(index);
      end;
  end
  else if index = 0 then Result := itemIndex;
end;

function TListboxHelper.GetSelectedItem(index : integer) : string;
begin
  index := SelectedIndices[index];
  if index <= -1 then Result := ''
  else Result := Items[index];
end;

function TListboxHelper.HasSelection : boolean;
begin
  if MultiSelect then Result := SelCount > 0
  else Result := itemIndex > -1;
end;

function TListboxHelper.IsSelected(index : integer) : boolean;
begin
  if index >= Count then exit(False);
  if MultiSelect then Result := Selected[index]
  else Result := index = itemIndex;
end;

procedure TListboxHelper.Deselect(index : integer);
begin
  if index >= Count then exit;
  if MultiSelect then Selected[index] := False
  else if itemIndex = index then itemIndex := -1;
end;

function TListboxHelper.SelectionCount : integer;
begin
  if MultiSelect then Result := SelCount
  else if itemIndex > -1 then Result := 1
  else Result := 0;
end;

{ TVariedRVector3TrackBarBinding }

function TVariedRVector3TrackBarBinding.Dimensions : integer;
begin
  Result := 3;
end;

{ TTextFieldBinding }

constructor TStringTextFieldBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  FComponents.Add(CreateComponent(TMemo));
  FComponents[0].Name := RttiInfo.Name + '_Memo';
  TMemo(FComponents[0]).Lines.Text := '';
end;

function TStringTextFieldBinding.ReadValueFromComponents : TValue;
begin
  Result := TMemo(FComponents[0]).Lines.Text;
end;

procedure TStringTextFieldBinding.WriteValueToComponents;
begin
  inherited;
  TMemo(FComponents[0]).Lines.Text := GetInstanceValue.AsType<string>;
end;

{ TVariedIntegerEditBinding }

constructor TVariedIntegerEditBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateVariedEditField(RttiInfo.Name, Data, 0);
end;

function TVariedIntegerEditBinding.ReadValueFromComponents : TValue;
var
  Value : RVariedInteger;
begin
  Value.MEAN := StrToInt(TEdit(FComponents[MEAN]).Text);
  Value.VARIANCE := StrToInt(TEdit(FComponents[VARIANCE]).Text);
  Result := TValue.From<RVariedInteger>(Value);
end;

procedure TVariedIntegerEditBinding.WriteValueToComponents;
begin
  TEdit(FComponents[MEAN]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedInteger>.MEAN, ffGeneral, 4, 4);
  TEdit(FComponents[VARIANCE]).Text := FloatToStrF(GetInstanceValue.AsType<RVariedInteger>.VARIANCE, ffGeneral, 4, 4);
end;

{ TRIntVector2Binding }

constructor TRIntVector2SpinEditBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  CreateComponent(TSpinEdit);
  FComponents[X].Name := RttiInfo.Name + 'X_Spin';
  TSpinEdit(FComponents[X]).MinValue := 0;
  TSpinEdit(FComponents[X]).MaxValue := VCLRIntVector2Field(Data).FRange.X;
  CreateComponent(TSpinEdit);
  FComponents[Y].Name := RttiInfo.Name + 'Y_Spin';
  TSpinEdit(FComponents[Y]).MinValue := 0;
  TSpinEdit(FComponents[Y]).MaxValue := VCLRIntVector2Field(Data).FRange.Y;
end;

function TRIntVector2SpinEditBinding.ReadValueFromComponents : TValue;
begin
  Result := TValue.From<RIntVector2>(RIntVector2.Create(TSpinEdit(FComponents[X]).Value, TSpinEdit(FComponents[Y]).Value));
end;

procedure TRIntVector2SpinEditBinding.WriteValueToComponents;
begin
  TSpinEdit(FComponents[X]).Value := GetInstanceValue.AsType<RIntVector2>.X;
  TSpinEdit(FComponents[Y]).Value := GetInstanceValue.AsType<RIntVector2>.Y;
end;

{ VCLRIntVector2Field }

constructor VCLRIntVector2Field.Create(xMax, yMax : integer; ComponentType : EnumIntegerComponent);
begin
  FRange := RIntVector2.Create(xMax, yMax);
  case ComponentType of
    icSpinEdit : FBindingClass := TRIntVector2SpinEditBinding;
  else raise ENotImplemented.Create('VCLRIntVector2Field: Unknown Componenttype.');
  end;
end;

{ VCLVariedRColorField }

constructor VCLVariedRColorField.Create(xRangeMean, xRangeVariance,
  yRangeMean, yRangeVariance, zRangeMean, zRangeVariance, wRangeMean,
  wRangeVariance : single);
begin
  FValue := RVariedVector4.Create(RVector4.Create(xRangeMean, yRangeMean, zRangeMean, wRangeMean), RVector4.Create(xRangeVariance, yRangeVariance, zRangeVariance, wRangeVariance));
  FBindingClass := TVariedRColorBinding;
end;

{ TVariedRColorBinding }

constructor TVariedRColorBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  FColorDialog := TColorDialog.Create(FTargetControl);
  FColorDialog.Options := FColorDialog.Options + [cdFullOpen, cdAnyColor];
  FComponents.Add(CreateComponent(TButton));
  TButton(FComponents[FComponents.Count - 1]).Caption := 'Color Picker';
  TButton(FComponents[FComponents.Count - 1]).OnClick := OnClickHandler;
  FComponents.Add(CreateComponent(TButton));
  TButton(FComponents[FComponents.Count - 1]).Caption := 'Color by Hex';
  TButton(FComponents[FComponents.Count - 1]).OnClick := OnClickInputHandler;
end;

function TVariedRColorBinding.Dimensions : integer;
begin
  Result := 4;
end;

procedure TVariedRColorBinding.OnClickHandler(Sender : TObject);
var
  PickedColor : RColor;
begin
  PickedColor.R := TTrackBar(FComponents[MEAN_X]).Value;
  PickedColor.G := TTrackBar(FComponents[MEAN_Y]).Value;
  PickedColor.B := TTrackBar(FComponents[MEAN_Z]).Value;
  FColorDialog.Color := PickedColor.AsBGRCardinal;
  if assigned(FBoundForm) and assigned(FBoundForm.FInstance) and not FBlockChanges and FColorDialog.Execute then
  begin
    PickedColor := RColor.CreateFromBGRCardinal(FColorDialog.Color);
    TTrackBar(FComponents[MEAN_X]).Value := PickedColor.R;
    TTrackBar(FComponents[MEAN_Y]).Value := PickedColor.G;
    TTrackBar(FComponents[MEAN_Z]).Value := PickedColor.B;
    WriteValueToInstance;
  end;
end;

procedure TVariedRColorBinding.OnClickInputHandler(Sender : TObject);
var
  Input : string;
  Color : cardinal;
  code : integer;
  PickedColor : RColor;
begin
  PickedColor.R := TTrackBar(FComponents[MEAN_X]).Value;
  PickedColor.G := TTrackBar(FComponents[MEAN_Y]).Value;
  PickedColor.B := TTrackBar(FComponents[MEAN_Z]).Value;
  Input := InputBox('Color by Hexcode', 'Please pass the color without alpha as hex code like $808080', PickedColor.ToHexString.Remove(1, 2));
  if (Input <> '') then
  begin
    Val(Input, Color, code);
    if code = 0 then
    begin
      PickedColor := RColor.Create(Color);
      TTrackBar(FComponents[MEAN_X]).Value := PickedColor.R;
      TTrackBar(FComponents[MEAN_Y]).Value := PickedColor.G;
      TTrackBar(FComponents[MEAN_Z]).Value := PickedColor.B;
      WriteValueToInstance;
    end;
  end;
end;

function TVariedRColorBinding.ReadValueFromComponents : TValue;
begin
  Result := inherited
end;

procedure TVariedRColorBinding.WriteValueToComponents;
begin
  inherited;
end;

{ VCLRColorField }

constructor VCLRColorField.Create(xRange, yRange, zRange, wRange : single;
  ComponentType : EnumSingleComponent);
begin
  FRange := RVector4.Create(xRange, yRange, zRange, wRange);
  case ComponentType of
    isTrackBar : FBindingClass := TRColorBinding;
    isEdit : raise ENotImplemented.Create('VCLRColorField: Edit for RColoor not available, yet.');
  else raise Exception.Create('VCLRColorField: Unknown Componenttype.');
  end;
end;

{ TRColorBinding }

constructor TRColorBinding.Create(TargetControl : TControl; RttiInfo : TRttiMemberUnified; Data : TCustomAttribute);
begin
  inherited;
  FColorDialog := TColorDialog.Create(FTargetControl);
  FColorDialog.Options := FColorDialog.Options + [cdFullOpen, cdAnyColor];
  FComponents.Add(CreateComponent(TButton));
  TButton(FComponents[FComponents.Count - 1]).Caption := 'Color Picker';
  TButton(FComponents[FComponents.Count - 1]).OnClick := OnClickHandler;
  FComponents.Add(CreateComponent(TButton));
  TButton(FComponents[FComponents.Count - 1]).Caption := 'Color by Hex';
  TButton(FComponents[FComponents.Count - 1]).OnClick := OnClickInputHandler;
end;

procedure TRColorBinding.OnClickHandler(Sender : TObject);
var
  PickedColor : RColor;
begin
  PickedColor.R := TTrackBar(FComponents[MEAN_X]).Value;
  PickedColor.G := TTrackBar(FComponents[MEAN_Y]).Value;
  PickedColor.B := TTrackBar(FComponents[MEAN_Z]).Value;
  FColorDialog.Color := PickedColor.AsBGRCardinal;
  if assigned(FBoundForm) and assigned(FBoundForm.FInstance) and not FBlockChanges and FColorDialog.Execute then
  begin
    PickedColor := RColor.CreateFromBGRCardinal(FColorDialog.Color);
    TTrackBar(FComponents[MEAN_X]).Value := PickedColor.R;
    TTrackBar(FComponents[MEAN_Y]).Value := PickedColor.G;
    TTrackBar(FComponents[MEAN_Z]).Value := PickedColor.B;
    WriteValueToInstance;
  end;
end;

procedure TRColorBinding.OnClickInputHandler(Sender : TObject);
var
  Input : string;
  Color : cardinal;
  code : integer;
  PickedColor : RColor;
begin
  PickedColor.R := TTrackBar(FComponents[MEAN_X]).Value;
  PickedColor.G := TTrackBar(FComponents[MEAN_Y]).Value;
  PickedColor.B := TTrackBar(FComponents[MEAN_Z]).Value;
  Input := InputBox('Color by Hexcode', 'Please pass the color without alpha as hex code like $808080', PickedColor.ToHexString.Remove(1, 2));
  if (Input <> '') then
  begin
    Val(Input, Color, code);
    if code = 0 then
    begin
      PickedColor := RColor.Create(Color);
      TTrackBar(FComponents[MEAN_X]).Value := PickedColor.R;
      TTrackBar(FComponents[MEAN_Y]).Value := PickedColor.G;
      TTrackBar(FComponents[MEAN_Z]).Value := PickedColor.B;
      WriteValueToInstance;
    end;
  end;
end;

end.
