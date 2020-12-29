unit Engine.Terrain.Editor;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Engine.Terrain,
  Vcl.ExtCtrls,
  Vcl.Buttons,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.VCLUtils,
  Math,
  Engine.Math,
  Engine.Vertex,
  Engine.Math.Collision3D,
  Engine.Collision,
  Engine.Core,
  Engine.Core.Types,
  Engine.GFXApi,
  Vcl.Grids,
  Vcl.ValEdit,
  Vcl.Menus,
  System.UITypes;

type

  TTerrain = class;

  TTerrainDebugForm = class(TForm)
    MainScrollBox : TScrollBox;
    GeomipmapDistanceTrack : TTrackBar;
    GeomipmapNormalTrack : TTrackBar;
    Label1 : TLabel;
    Label2 : TLabel;
    GeomipmapGroup : TGroupBox;
    BrushcoreDisplay : TLabel;
    BrushcoreTrack : TTrackBar;
    BrushEdgeDisplay : TLabel;
    BrushEdgeTrack : TTrackBar;
    HigherSpeed : TSpeedButton;
    LowerSpeed : TSpeedButton;
    PlanarSpeed : TSpeedButton;
    SetSpeed : TSpeedButton;
    TextureSpeed : TSpeedButton;
    NoiseSpeed : TSpeedButton;
    SmoothSpeed : TSpeedButton;
    TransformationValueTrack : TTrackBar;
    TransformationValueDisplay : TLabel;
    TexuteLayerGroup : TGroupBox;
    ManipulationGroup : TGroupBox;
    TextureOpenDialog : TOpenDialog;
    Movementcheck : TCheckBox;
    GeneralEditor : TValueListEditor;
    MainMenu1 : TMainMenu;
    File1 : TMenuItem;
    Save1 : TMenuItem;
    New1 : TMenuItem;
    NewfromGrayscale1 : TMenuItem;
    Save2 : TMenuItem;
    Saveas1 : TMenuItem;
    Open1 : TMenuItem;
    WireFrameCheck : TMenuItem;
    DrawOptimizedCheck : TMenuItem;
    TerrainOpenDialog : TOpenDialog;
    GrayscaleOpenDialog : TOpenDialog;
    TerrainSaveDialog : TSaveDialog;
    SnaptoInteger1 : TMenuItem;
    LinemodeCheck : TCheckBox;
    LineModeDistance : TTrackBar;
    ChunkIdCombo : TComboBox;
    Label9 : TLabel;
    TextureSizeCombo : TComboBox;
    Label5 : TLabel;
    BrushGroup : TGroupBox;
    Label3 : TLabel;
    Label4 : TLabel;
    Label6 : TLabel;
    Label7 : TLabel;
    Label8 : TLabel;
    DiffuseEdit : TEdit;
    LoadDiffuseMapBtn : TBitBtn;
    LoadMaterialMapBtn : TBitBtn;
    LoadNormalMapBtn : TBitBtn;
    MaterialMapEdit : TEdit;
    NormalMapEdit : TEdit;
    RemoveDiffuseMapBtn : TBitBtn;
    RemoveMaterialMapBtn : TBitBtn;
    RemoveNormalMapBtn : TBitBtn;
    SpecularIntensitiyTrack : TTrackBar;
    SpecularPowerTrack : TTrackBar;
    OverwriteMaterial : TCheckBox;
    EmissiveTrack : TTrackBar;
    Label10 : TLabel;
    NoneSpeed : TSpeedButton;
    OverwriteColorCheck : TCheckBox;
    BrushColorShape : TShape;
    ColorDialog : TColorDialog;
    Label11 : TLabel;
    AlphaTrack : TTrackBar;
    TextureSizeTrack : TTrackBar;
    Label12 : TLabel;
    ShowChunkCheck : TCheckBox;
    Label13 : TLabel;
    TextureSplitCombo : TComboBox;
    Label14 : TLabel;
    PipetteSpeed : TSpeedButton;
    Label15 : TLabel;
    ClearDiffuseBtn : TButton;
    ClearNormalBtn : TButton;
    ClearMaterialBtn : TButton;
    GroupBox1 : TGroupBox;
    PointReflectionBtn : TButton;
    MirrorAlongXRadio : TRadioButton;
    MirrorAlongYRadio : TRadioButton;
    MirrorInvertCheck : TCheckBox;
    ObjExportDialog : TSaveDialog;
    SaveAsObj1 : TMenuItem;
    LoadHeightsfromObj1 : TMenuItem;
    AxisReflectionBtn : TButton;
    Actions1 : TMenuItem;
    Flatten1 : TMenuItem;
    procedure BigChange(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure GeneralEditorSetEditText(Sender : TObject; ACol, ARow : Integer; const Value : string);
    procedure Save2Click(Sender : TObject);
    procedure Saveas1Click(Sender : TObject);
    procedure Open1Click(Sender : TObject);
    procedure NewfromGrayscale1Click(Sender : TObject);
    procedure New1Click(Sender : TObject);
    procedure BrushColorShapeMouseUp(Sender : TObject; Button : TMouseButton;
      Shift : TShiftState; X, Y : Integer);
    procedure SaveAsObj1Click(Sender : TObject);
    procedure LoadHeightsfromObj1Click(Sender : TObject);
    private
      { Private-Deklarationen }
      FTerrain : TTerrain;
    public
      { Public-Deklarationen }
  end;

  EnumBrushType = (btNone, btHigher, btLower, btPlanar, btSetHeight, btSmooth, btNoise, btTexture, btPipette);
  EnumKeyState = (ksDown, ksUp, ksIsDown, ksIsUp);

  TTerrain = class(Engine.Terrain.TTerrain)
    private
      function getShowing : boolean;
    protected
      TerrainEditor : TTerrainEditor;
      Transformationvalue : single;
      Brushcore, Brushedge, SetHeightValue, LineModeDistance : single;
      Brushtype : EnumBrushType;
      LineMode : boolean;
      LineStart : RVector3;
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure Init;
    public
      constructor CreateEmpty(Scene : TRenderManager; Size : Integer);
      constructor CreateFromGrayscaleTexture(Scene : TRenderManager; Texturfile : string);
      constructor CreateFromFile(Scene : TRenderManager; TerrainFile : string);
      procedure LoadEmpty(Size : Integer);
      procedure LoadFromGrayscaleTexture(Texturfile : string);
      procedure LoadFromFile(TerrainFile : string);

      procedure ShowDebugForm;
      procedure HideDebugForm;
      procedure RenderBrush(ClickRay : RRay);
      procedure Manipulate(ClickRay : RRay; Movement : boolean; StrgDown : boolean; Mousestate : EnumKeyState; RightUp : boolean);
      destructor Destroy; override;
      property Showing : boolean read getShowing;
  end;

var
  TerrainDebugForm : TTerrainDebugForm;

  PreventChanges : boolean;
  MountedFile : string;

implementation

{$R *.dfm}


procedure TTerrainDebugForm.BrushColorShapeMouseUp(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
begin
  ColorDialog.Color := BrushColorShape.Brush.Color;
  if ColorDialog.Execute then
  begin
    BrushColorShape.Brush.Color := ColorDialog.Color;
  end;
  BigChange(BrushColorShape);
end;

procedure TTerrainDebugForm.FormShow(Sender : TObject);
begin
  Left := Screen.WorkAreaRect.Right - Width;
  Top := 0;
  Height := Screen.WorkAreaHeight;
  TextureOpenDialog.InitialDir := HFilePathManager.AbsoluteWorkingPath;
end;

procedure TTerrainDebugForm.GeneralEditorSetEditText(Sender : TObject; ACol,
  ARow : Integer; const Value : string);
  function ValueListToVec3(Name : string; ValueList : TValueListEditor) : RVector3;
  var
    i : Integer;
  begin
    Result := RVector3.ZERO;
    Result.X := StrToFloat(ValueList.Values[name + '.X']);
    if ValueList.FindRow(name + '.Y', i) then Result.Y := StrToFloat(ValueList.Values[name + '.Y'], EngineFloatFormatSettings);
    Result.Z := StrToFloat(ValueList.Values[name + '.Z']);
  end;

begin
  try
    if Sender = GeneralEditor then
    begin
      case ARow of
        1 : FTerrain.Position := FTerrain.Position.SetX(StrToFloat(Value, EngineFloatFormatSettings));
        2 : FTerrain.Position := FTerrain.Position.SetY(StrToFloat(Value, EngineFloatFormatSettings));
        3 : FTerrain.Position := FTerrain.Position.SetZ(StrToFloat(Value, EngineFloatFormatSettings));
        4 : FTerrain.Scale := FTerrain.Scale.SetX(StrToFloat(Value, EngineFloatFormatSettings));
        5 : FTerrain.Scale := FTerrain.Scale.SetY(StrToFloat(Value, EngineFloatFormatSettings));
        6 : FTerrain.Scale := FTerrain.Scale.SetZ(StrToFloat(Value, EngineFloatFormatSettings));
        7 : TryStrToFloat(Value, FTerrain.FShadingReduction, EngineFloatFormatSettings);
      end;
    end;
  except
  end;
end;

procedure TTerrainDebugForm.LoadHeightsfromObj1Click(Sender : TObject);
begin
  if ObjExportDialog.Execute then
  begin
    FTerrain.LoadFromOBJ(ObjExportDialog.filename);
    showmessage('Imported!');
  end;
end;

procedure TTerrainDebugForm.New1Click(Sender : TObject);
begin
  MountedFile := '';
  FTerrain.LoadEmpty(512);
end;

procedure TTerrainDebugForm.NewfromGrayscale1Click(Sender : TObject);
begin
  if GrayscaleOpenDialog.Execute then
  begin
    MountedFile := '';
    FTerrain.LoadFromGrayscaleTexture(GrayscaleOpenDialog.filename);
  end;
end;

procedure TTerrainDebugForm.Open1Click(Sender : TObject);
begin
  if TerrainOpenDialog.Execute then
  begin
    MountedFile := TerrainOpenDialog.filename;
    FTerrain.LoadFromFile(TerrainOpenDialog.filename);
  end;
end;

procedure TTerrainDebugForm.Save2Click(Sender : TObject);
begin
  if (MountedFile <> '') or TerrainSaveDialog.Execute then
  begin
    if (MountedFile = '') then MountedFile := TerrainSaveDialog.filename;
    FTerrain.SaveToFile(MountedFile);
  end;
end;

procedure TTerrainDebugForm.Saveas1Click(Sender : TObject);
begin
  MountedFile := '';
  Save2Click(self);
end;

procedure TTerrainDebugForm.SaveAsObj1Click(Sender : TObject);
begin
  if ObjExportDialog.Execute then
  begin
    FTerrain.SaveToOBJ(ObjExportDialog.filename);
    showmessage('Exported!');
  end;
end;

procedure TTerrainDebugForm.BigChange(Sender : TObject);
type
  EnumBrushTexture = (btNone, btDiffuse, btNormal, btMaterial);
var
  brushtexturetarget : EnumBrushTexture;
  heightReference : single;
  function FtS(s : single) : string;
  begin
    Result := FloatToStrF(s, ffGeneral, 4, 4);
  end;
  procedure Vec3ToValueList(Vec : RVector3; Name : string; ValueList : TValueListEditor);
  var
    i : Integer;
  begin
    ValueList.Values[name + '.X'] := FtS(Vec.X);
    if ValueList.FindRow(name + '.Y', i) then ValueList.Values[name + '.Y'] := FtS(Vec.Y);
    ValueList.Values[name + '.Z'] := FtS(Vec.Z);
  end;
  procedure RefreshTrackBars;
  begin
    PreventChanges := True;
    if FTerrain.Brushtype = btSetHeight then
    begin
      TransformationValueTrack.Visible := False;
      TransformationValueDisplay.Caption := 'Height: ' + FloatToStrF(FTerrain.SetHeightValue, ffGeneral, 4, 4) + sLineBreak + 'Pick height with Strg+Leftclick.';
    end
    else
    begin
      TransformationValueTrack.Visible := True;
      TransformationValueTrack.Position := round(FTerrain.Transformationvalue * TransformationValueTrack.Tag);
      TransformationValueDisplay.Caption := 'Strength: ' + FloatToStrF(FTerrain.Transformationvalue, ffGeneral, 4, 4);
    end;
    GeomipmapDistanceTrack.Position := round(FTerrain.TerrainSettings.Geomipmapdistanceerror * GeomipmapDistanceTrack.Tag);
    GeomipmapNormalTrack.Position := round(FTerrain.TerrainSettings.Geomipmapnormalerror * GeomipmapNormalTrack.Tag);
    BrushcoreTrack.Position := round(FTerrain.Brushcore * BrushcoreTrack.Tag);
    BrushcoreDisplay.Caption := 'Brushcore: ' + FloatToStrF(FTerrain.Brushcore, ffGeneral, 4, 4);
    BrushEdgeTrack.Position := round(FTerrain.Brushedge * BrushEdgeTrack.Tag);
    BrushEdgeDisplay.Caption := 'Smoothedge: ' + FloatToStrF(FTerrain.Brushedge, ffGeneral, 4, 4);
    PreventChanges := False;
  end;
  procedure SyncBrush;
  begin
    FTerrain.TerrainEditor.Alpha := HMath.Saturate(AlphaTrack.Position / AlphaTrack.Max);
    FTerrain.TerrainEditor.OverwriteColor := OverwriteColorCheck.Checked;
    FTerrain.TerrainEditor.OverwriteMaterial := OverwriteMaterial.Checked;
    FTerrain.TerrainEditor.ExtraMaterial := RColor.Create(SpecularIntensitiyTrack.Position, SpecularPowerTrack.Position, 0, EmissiveTrack.Position);
    FTerrain.TerrainEditor.ExtraColor.AsBGRCardinal := BrushColorShape.Brush.Color;
    FTerrain.TerrainEditor.BrushTextureScale := TextureSizeTrack.Value;
  end;
  procedure RefreshTextureGeneral;
  var
    temp, i : Integer;
  begin
    temp := ChunkIdCombo.ItemIndex;
    ChunkIdCombo.Clear;
    for i := 0 to FTerrain.FChunkTextures.Count - 1 do ChunkIdCombo.Items.Add(Inttostr(i));
    ChunkIdCombo.ItemIndex := temp;
    if FTerrain.FChunkTextures[ChunkIdCombo.ItemIndex].TextureSize <= 0 then TextureSizeCombo.ItemIndex := 0
    else TextureSizeCombo.ItemIndex := Log2Aufgerundet(FTerrain.FChunkTextures[ChunkIdCombo.ItemIndex].TextureSize) - 7; // min 128
    TextureSplitCombo.ItemIndex := FTerrain.TextureSplits;
  end;
  procedure SetBrushTexture(target : EnumBrushTexture; filename : string);
  begin
    case target of
      btDiffuse :
        begin
          if filename.IsEmpty then FTerrain.TerrainEditor.Diffuse := nil
          else FTerrain.TerrainEditor.Diffuse := TTexture.CreateTextureFromFile(filename, GFXD.Device3D, mhSkip, False);
          DiffuseEdit.Text := ExtractFileName(filename);
        end;
      btNormal :
        begin
          if filename.IsEmpty then FTerrain.TerrainEditor.Normal := nil
          else FTerrain.TerrainEditor.Normal := TTexture.CreateTextureFromFile(filename, GFXD.Device3D, mhSkip, False);
          NormalMapEdit.Text := ExtractFileName(filename);
        end;
      btMaterial :
        begin
          if filename.IsEmpty then FTerrain.TerrainEditor.Material := nil
          else FTerrain.TerrainEditor.Material := TTexture.CreateTextureFromFile(filename, GFXD.Device3D, mhSkip, False);
          MaterialMapEdit.Text := ExtractFileName(filename);
        end;
    end;
  end;

begin
  if PreventChanges or (FTerrain = nil) or (FTerrain.TerrainEditor = nil) then exit;
  if Sender = self then
  begin
    BigChange(BrushcoreTrack);
    BigChange(BrushEdgeTrack);
    BigChange(GeneralEditor);
    RefreshTrackBars;
    RefreshTextureGeneral;
    SyncBrush;
  end;
  if Sender = RemoveDiffuseMapBtn then SetBrushTexture(btDiffuse, string.Empty);
  if Sender = RemoveMaterialMapBtn then SetBrushTexture(btMaterial, string.Empty);
  if Sender = RemoveNormalMapBtn then SetBrushTexture(btNormal, string.Empty);
  brushtexturetarget := btNone;
  if (Sender = LoadDiffuseMapBtn) or (Sender = DiffuseEdit) then brushtexturetarget := btDiffuse;
  if (Sender = LoadNormalMapBtn) or (Sender = NormalMapEdit) then brushtexturetarget := btNormal;
  if (Sender = LoadMaterialMapBtn) or (Sender = MaterialMapEdit) then brushtexturetarget := btMaterial;
  if brushtexturetarget <> btNone then
  begin
    if TextureOpenDialog.Execute then
    begin
      SetBrushTexture(brushtexturetarget, TextureOpenDialog.filename);
      if brushtexturetarget = btDiffuse then
      begin
        if FileExists(string(TextureOpenDialog.filename).replace('.', 'Normal.')) then SetBrushTexture(btNormal, string(TextureOpenDialog.filename).replace('.', 'Normal.'));
        if FileExists(string(TextureOpenDialog.filename).replace('.', 'Material.')) then SetBrushTexture(btMaterial, string(TextureOpenDialog.filename).replace('.', 'Material.'));
      end;
    end;
  end;
  if Sender = GeneralEditor then
  begin
    GeneralEditor.OnSetEditText := nil;
    Vec3ToValueList(FTerrain.Position, 'Position', GeneralEditor);
    Vec3ToValueList(FTerrain.Scale, 'Scale', GeneralEditor);
    GeneralEditor.Values['Shading Reduction'] := FloatToStrF(FTerrain.ShadingReduction, ffGeneral, 4, 4, EngineFloatFormatSettings);
    GeneralEditor.OnSetEditText := GeneralEditorSetEditText;
  end;
  if Sender is TSpeedButton then
  begin
    FTerrain.Brushtype := EnumBrushType(TSpeedButton(Sender).Tag);
    RefreshTrackBars;
  end;
  if Sender = DrawOptimizedCheck then
  begin
    if DrawOptimizedCheck.Checked then FTerrain.Optimize;
    Engine.Terrain.UseGeoMipMapping := DrawOptimizedCheck.Checked;
  end;
  if Sender = TransformationValueTrack then
  begin
    FTerrain.Transformationvalue := TransformationValueTrack.Position / TransformationValueTrack.Tag;
    TransformationValueDisplay.Caption := 'Strength: ' + FloatToStrF(FTerrain.Transformationvalue, ffGeneral, 4, 4);
  end;
  if Sender = BrushcoreTrack then
  begin
    FTerrain.Brushcore := BrushcoreTrack.Position / BrushcoreTrack.Tag;
    BrushcoreDisplay.Caption := 'Brushcore: ' + FloatToStrF(FTerrain.Brushcore, ffGeneral, 4, 4);
  end;
  if Sender = BrushEdgeTrack then
  begin
    FTerrain.Brushedge := BrushEdgeTrack.Position / BrushEdgeTrack.Tag;
    BrushEdgeDisplay.Caption := 'Smoothedge: ' + FloatToStrF(FTerrain.Brushedge, ffGeneral, 4, 4);
  end;
  if Sender = LineModeDistance then FTerrain.LineModeDistance := LineModeDistance.Position / LineModeDistance.Tag;
  if Sender = LinemodeCheck then
  begin
    FTerrain.LineMode := LinemodeCheck.Checked;
    LineModeDistance.Visible := LinemodeCheck.Checked;
  end;
  if Sender = GeomipmapDistanceTrack then FTerrain.TerrainSettings.Geomipmapdistanceerror := GeomipmapDistanceTrack.Position / GeomipmapDistanceTrack.Tag;
  if Sender = GeomipmapNormalTrack then FTerrain.TerrainSettings.Geomipmapnormalerror := GeomipmapNormalTrack.Position / GeomipmapNormalTrack.Tag;
  if Sender = WireFrameCheck then FTerrain.TerrainSettings.DrawWireFramed := WireFrameCheck.Checked;
  if (Sender is TComponent) and (TComponent(Sender).GetParentComponent = BrushGroup) then SyncBrush;
  if Sender = TextureSplitCombo then
  begin
    FTerrain.TextureSplits := TextureSplitCombo.ItemIndex;
    RefreshTextureGeneral;
  end;
  if Sender = ChunkIdCombo then RefreshTextureGeneral;
  if Sender = TextureSizeCombo then FTerrain.FChunkTextures[ChunkIdCombo.ItemIndex].TextureSize := 1 shl (TextureSizeCombo.ItemIndex + 7); // starting at 128
  if Sender = ClearDiffuseBtn then FTerrain.TerrainEditor.ClearMap(mtDiffuse);
  if Sender = ClearNormalBtn then FTerrain.TerrainEditor.ClearMap(mtNormal);
  if Sender = ClearMaterialBtn then FTerrain.TerrainEditor.ClearMap(mtMaterial);
  if Sender = PointReflectionBtn then
  begin
    if MirrorAlongXRadio.Checked then FTerrain.TerrainEditor.PointReflection(mtX, MirrorInvertCheck.Checked);
    if MirrorAlongYRadio.Checked then FTerrain.TerrainEditor.PointReflection(mtY, MirrorInvertCheck.Checked);
  end;
  if Sender = AxisReflectionBtn then
  begin
    if MirrorAlongXRadio.Checked then FTerrain.TerrainEditor.AxisReflection(mtX, MirrorInvertCheck.Checked);
    if MirrorAlongYRadio.Checked then FTerrain.TerrainEditor.AxisReflection(mtY, MirrorInvertCheck.Checked);
  end;
  if Sender = Flatten1 then
  begin
    if not TryStrToFloat(InputBox('Flatten terrain', 'Please give a height, which will be reduced to 0', '0.01').replace(',', '.'), heightReference, EngineFloatFormatSettings) then
        heightReference := 0.01;;
    FTerrain.TerrainEditor.Flatten(heightReference);
  end;
end;

{ TTerrain }

procedure TTerrain.ShowDebugForm;
begin
  if not assigned(TerrainDebugForm) then
  begin
    TerrainDebugForm := TTerrainDebugForm.Create(Application);
    TerrainDebugForm.Top := 25;
    TerrainDebugForm.Height := Screen.WorkAreaHeight - 25;
    TerrainDebugForm.Left := Screen.WorkAreaWidth - TerrainDebugForm.Width;
    Engine.Terrain.UseGeoMipMapping := False;
    TerrainDebugForm.WireFrameCheck.Checked := TerrainSettings.DrawWireFramed;
    TerrainDebugForm.TerrainOpenDialog.InitialDir := HFilePathManager.AbsoluteWorkingPath;
    TerrainDebugForm.TerrainSaveDialog.InitialDir := HFilePathManager.AbsoluteWorkingPath;
  end;
  TerrainDebugForm.FTerrain := self;
  if TerrainEditor = nil then TerrainEditor := TTerrainEditor.Create(self);
  TerrainDebugForm.BigChange(TerrainDebugForm);
  TerrainDebugForm.Show;
end;

procedure TTerrain.HideDebugForm;
begin
  if assigned(TerrainDebugForm) then TerrainDebugForm.Hide;
end;

procedure TTerrain.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
begin
  inherited;
  if Showing and TerrainDebugForm.ShowChunkCheck.Checked then
  begin
    RenderBorders(TerrainDebugForm.ChunkIdCombo.ItemIndex);
  end;
end;

procedure TTerrain.RenderBrush(ClickRay : RRay);
const
  SMOOTHSTEPS = 8;
var
  j : Integer;
  Pos : RVector3;
begin
  if not Showing or (Brushtype in [btNone, btPipette]) then exit;
  Pos := IntersectRayTerrain(ClickRay);
  if assigned(TerrainDebugForm) and TerrainDebugForm.SnaptoInteger1.Checked then Pos := Pos.round;
  LinePool.DrawCircleOnTerrain(self, Pos, Brushcore, $FF00FF00);
  for j := 0 to SMOOTHSTEPS - 1 do
      LinePool.DrawCircleOnTerrain(self, Pos, (Brushcore + Brushedge * (j / (SMOOTHSTEPS - 1))), SingleToByte(1 - (j / (SMOOTHSTEPS - 1))) * $01000000 + $00FF00);
end;

constructor TTerrain.CreateEmpty(Scene : TRenderManager; Size : Integer);
begin
  inherited CreateEmpty(Scene, Size);
  Init;
end;

procedure TTerrain.LoadEmpty(Size : Integer);
begin
  inherited;
  Init;
end;

procedure TTerrain.LoadFromFile(TerrainFile : string);
begin
  inherited;
  Init;
end;

procedure TTerrain.LoadFromGrayscaleTexture(Texturfile : string);
begin
  inherited;
  Init;
end;

constructor TTerrain.CreateFromFile(Scene : TRenderManager; TerrainFile : string);
begin
  inherited CreateFromFile(Scene, TerrainFile);
  Init;
end;

constructor TTerrain.CreateFromGrayscaleTexture(Scene : TRenderManager; Texturfile : string);
begin
  inherited CreateFromGrayscaleTexture(Scene, Texturfile);
  Init;
end;

destructor TTerrain.Destroy;
begin
  TerrainEditor.Free;
  inherited;
end;

function TTerrain.getShowing : boolean;
begin
  Result := assigned(TerrainDebugForm) and TerrainDebugForm.Visible;
end;

procedure TTerrain.Init;
begin
  Transformationvalue := 0.02;
  Brushtype := btNone;
  LineStart := RVector3.Empty;
  LineModeDistance := 1;
  if assigned(TerrainDebugForm) then TerrainDebugForm.Hide;
end;

procedure TTerrain.Manipulate(ClickRay : RRay; Movement : boolean; StrgDown : boolean; Mousestate : EnumKeyState; RightUp : boolean);
var
  Pos : RVector3;
  i, Count : Integer;
  procedure DoAction(Pos : RVector3);
  begin
    case Brushtype of
      btNone :;
      btHigher : TerrainEditor.Transform(Pos, False);
      btLower :
        begin
          TerrainEditor.Strength := -Transformationvalue;
          TerrainEditor.Transform(Pos, False);
        end;
      btPlanar : TerrainEditor.Plane(Pos);
      btSetHeight :
        begin
          if StrgDown then
          begin
            SetHeightValue := GetTerrainHeight(Pos).Y;
            if abs(SetHeightValue) < 0.0001 then SetHeightValue := 0;
            TerrainDebugForm.BigChange(TerrainDebugForm.SetSpeed);
          end
          else
          begin
            TerrainEditor.Strength := SetHeightValue;
            TerrainEditor.Transform(Pos, True);
          end;
        end;
      btSmooth : TerrainEditor.Smooth(Pos);
      btNoise : TerrainEditor.Noise(Pos);
      btTexture : TerrainEditor.DrawTexture(Pos);
      btPipette :
        begin
          self.TerrainEditor.ExtraColor := TerrainEditor.GetColor(Pos);
          if assigned(TerrainDebugForm) then TerrainDebugForm.BrushColorShape.Brush.Color := self.TerrainEditor.ExtraColor.AsBGRCardinal;
        end;
    end;
  end;

begin
  if (not Showing) or ((Mousestate = ksIsUp) and not LineMode) then exit;
  if not LineMode and TerrainDebugForm.Movementcheck.Checked and not Movement and not((Brushtype = btSetHeight) and StrgDown) and not(Brushtype = btPipette) then exit;
  TerrainDebugForm.DrawOptimizedCheck.Checked := False;
  Pos := IntersectRayTerrain(ClickRay);
  if assigned(TerrainDebugForm) and TerrainDebugForm.SnaptoInteger1.Checked then Pos := GetTerrainHeight(Pos.round);
  TerrainEditor.Brushcore := Brushcore;
  TerrainEditor.Brushedge := Brushedge;
  TerrainEditor.Strength := Transformationvalue;
  Count := 0;
  if LineMode then
  begin
    if RightUp then LineStart := RVector3.Empty;
    if not LineStart.IsEmpty then
    begin
      Count := Math.Ceil(LineStart.Distance(Pos) / LineModeDistance);
      LinePool.DrawLineOnTerrain(self, LineStart, Pos, RColor.CGREEN, 20);
      for i := 0 to Count - 1 do LinePool.DrawCircleOnTerrain(self, LineStart.Lerp(Pos, i / (Count - 1)), Brushcore, RColor.CGREEN, 16);
    end;
    if Mousestate = ksUp then
    begin
      if LineStart.IsEmpty then LineStart := Pos
      else
      begin
        for i := 0 to Count - 1 do DoAction(LineStart.Lerp(Pos, i / (Count - 1)));
        LineStart := RVector3.Empty;
      end;
    end;
  end
  else DoAction(Pos);
end;

end.
