unit Engine.Water.Editor;

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
  Engine.Water,
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
  Vcl.Grids,
  Vcl.ValEdit,
  Vcl.Menus,
  System.UITypes,
  Engine.Input;

type

  TWaterEditor = class;

  TWaterEditorForm = class(TForm)
    TextureOpenDialog : TOpenDialog;
    MainMenu1 : TMainMenu;
    File1 : TMenuItem;
    Save1 : TMenuItem;
    New1 : TMenuItem;
    Save2 : TMenuItem;
    Saveas1 : TMenuItem;
    Open1 : TMenuItem;
    WireFrameCheck : TMenuItem;
    WaterOpenDialog : TOpenDialog;
    WaterSaveDialog : TSaveDialog;
    ToolBox : TCategoryPanelGroup;
    CategoryPanel1 : TCategoryPanel;
    WaveHeight : TLabel;
    Label1 : TLabel;
    Label2 : TLabel;
    SaturationValueImage : TImage;
    HueImage : TImage;
    Label3 : TLabel;
    Label5 : TLabel;
    Label6 : TLabel;
    WaveHeightTrack : TTrackBar;
    RoughnessTrack : TTrackBar;
    ExposureTrack : TTrackBar;
    ColorRadio : TRadioGroup;
    SpecularPowerTrack : TTrackBar;
    SpecularIntensityTrack : TTrackBar;
    ScalingTrack : TTrackBar;
    FresnelOffsetTrack : TTrackBar;
    CategoryPanel2 : TCategoryPanel;
    WaterSurfaceList : TListBox;
    SelectionCheck : TCheckBox;
    Panel1 : TPanel;
    Label4 : TLabel;
    Panel2 : TPanel;
    AddSurfaceBtn : TButton;
    DeleteSurfaceBtn : TButton;
    CategoryPanel3 : TCategoryPanel;
    GeometryResolutionEdit : TEdit;
    Label7 : TLabel;
    Label8 : TLabel;
    Panel3 : TPanel;
    TextureEdit : TEdit;
    TextureRemoveBtn : TButton;
    TransparencyTrack : TTrackBar;
    Label9 : TLabel;
    Label10 : TLabel;
    DepthOpacityRangeTrack : TTrackBar;
    RefractionIndexTrack : TTrackBar;
    Label11 : TLabel;
    Label12 : TLabel;
    RefractionSamplesTrack : TTrackBar;
    RefractionSteplength : TTrackBar;
    Label13 : TLabel;
    Panel4 : TPanel;
    SkyEdit : TEdit;
    SkyRemoveBtn : TButton;
    Label14 : TLabel;
    Panel5 : TPanel;
    CausticsEdit : TEdit;
    CausticsRemoveBtn : TButton;
    Label15 : TLabel;
    Label16 : TLabel;
    ColorExtinctionTrack : TTrackBar;
    ReflectionCheck : TCheckBox;
    RefractionCheck : TCheckBox;
    Label17 : TLabel;
    CausticsRangeTrack : TTrackBar;
    Label18 : TLabel;
    CausticsScaleTrack : TTrackBar;
    procedure BigChange(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure Save2Click(Sender : TObject);
    procedure Saveas1Click(Sender : TObject);
    procedure Open1Click(Sender : TObject);
    procedure New1Click(Sender : TObject);
    procedure FormDestroy(Sender : TObject);
    private
      { Private-Deklarationen }
      FWaterManager : TWaterManager;
      FWaterEditor : TWaterEditor;
      ColorPicker : TLiveColorPicker;
      PreventChanges : boolean;
      MountedFile : string;
    public
      { Public-Deklarationen }
      procedure Idle(UseInputs : boolean);
  end;

  TWaterManagerHelper = class helper for TWaterManager
    public
      procedure ShowEditor;
      procedure IdleEditor(UseInputs : boolean);
      procedure HideEditor;
  end;

  TWaterEditor = class
    private
      procedure setIndex(const Value : Integer);
    protected
      type
      EnumDragType = (dtNone, dtPosition, dtMinimum, dtMaximum, dtHeight, dtHack);
    var
      FIndex : Integer;
      FWaterManager : TWaterManager;
      FDraggingOffset, FStartingPosition : RVector3;
      FDragging : EnumDragType;
    public
      constructor Create(WaterManager : TWaterManager);
      property CurrentIndex : Integer read FIndex write setIndex;
      function CurrentWaterSurface : TWaterSurface;
      procedure Idle(UseInputs : boolean);
  end;

var
  WaterEditorForm : TWaterEditorForm;

implementation

{$R *.dfm}


procedure TWaterEditorForm.FormDestroy(Sender : TObject);
begin
  FWaterEditor.Free;
  ColorPicker.Free;
end;

procedure TWaterEditorForm.FormShow(Sender : TObject);
begin
  Left := Screen.WorkAreaRect.Right - Width;
  Top := 0;
  Height := Screen.WorkAreaHeight;
  TextureOpenDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
end;

procedure TWaterEditorForm.Idle(UseInputs : boolean);
begin
  FWaterEditor.Idle(UseInputs);
end;

procedure TWaterEditorForm.New1Click(Sender : TObject);
begin
  MountedFile := '';
  FWaterManager.Free;
  FWaterManager := TWaterManager.Create();
end;

procedure TWaterEditorForm.Open1Click(Sender : TObject);
begin
  if WaterOpenDialog.Execute then
  begin
    MountedFile := WaterOpenDialog.filename;
    FWaterManager.LoadFromFile(WaterOpenDialog.filename);
    BigChange(Self);
  end;
end;

procedure TWaterEditorForm.Save2Click(Sender : TObject);
begin
  if (MountedFile <> '') or WaterSaveDialog.Execute then
  begin
    if (MountedFile = '') then MountedFile := WaterSaveDialog.filename;
    FWaterManager.SaveToFile(MountedFile);
  end;
end;

procedure TWaterEditorForm.Saveas1Click(Sender : TObject);
begin
  MountedFile := '';
  Save2Click(Self);
end;

procedure TWaterEditorForm.BigChange(Sender : TObject);
  procedure SyncSurface();
  var
    Surface : TWaterSurface;
  begin
    Surface := FWaterEditor.CurrentWaterSurface;
    if not assigned(Surface) then exit;
    PreventChanges := True;
    WaveHeightTrack.Value := Surface.WaveHeight;
    RoughnessTrack.Value := Surface.Roughness;
    SpecularPowerTrack.Value := Surface.Specularpower;
    SpecularIntensityTrack.Value := Surface.Specularintensity;
    ExposureTrack.Value := Surface.Exposure;
    ScalingTrack.Value := Surface.Size;
    FresnelOffsetTrack.Value := Surface.FresnelOffset;
    TransparencyTrack.Value := Surface.Transparency;
    DepthOpacityRangeTrack.Value := Surface.DepthTransparencyRange;
    RefractionIndexTrack.Value := Surface.RefractionIndex;
    RefractionSteplength.Value := Surface.RefractionSteplength;
    RefractionSamplesTrack.Value := Surface.RefractionSteps;
    ColorExtinctionTrack.Value := Surface.ColorExtinctionRange;
    CausticsRangeTrack.Value := Surface.CausticsRange;
    CausticsScaleTrack.Value := Surface.CausticsScale;
    if ColorRadio.Items[ColorRadio.ItemIndex] = 'Sky' then ColorPicker.Color := Surface.SkyColor
    else if ColorRadio.Items[ColorRadio.ItemIndex] = 'Water' then ColorPicker.Color := Surface.WaterColor;
    TextureEdit.Text := Surface.WaveTexture;
    SkyEdit.Text := Surface.SkyTexture;
    CausticsEdit.Text := Surface.CausticsTexture;
    RefractionCheck.Checked := Surface.Refraction;
    ReflectionCheck.Checked := Surface.Reflections;
    PreventChanges := False;
  end;
  procedure SyncSurfaces();
  var
    i, oldindex : Integer;
  begin
    oldindex := max(WaterSurfaceList.ItemIndex, 0);
    WaterSurfaceList.Clear;
    for i := 0 to FWaterManager.SurfaceCount - 1 do
        WaterSurfaceList.Items.Add('Surface ' + inttostr(i + 1));
    WaterSurfaceList.ItemIndex := oldindex;
  end;

var
  Surface : TWaterSurface;
begin
  if PreventChanges then exit;
  if Sender = Self then
  begin
    SyncSurfaces;
    BigChange(WaterSurfaceList);
  end;
  if Sender = WaterSurfaceList then
  begin
    FWaterEditor.CurrentIndex := WaterSurfaceList.ItemIndex;
    SyncSurface;
  end;
  if Sender = ColorRadio then SyncSurface;
  Surface := FWaterEditor.CurrentWaterSurface;
  if assigned(Surface) then
  begin
    if Sender = WaveHeightTrack then Surface.WaveHeight := WaveHeightTrack.Value;
    if Sender = RoughnessTrack then Surface.Roughness := RoughnessTrack.Value;
    if Sender = SpecularPowerTrack then Surface.Specularpower := SpecularPowerTrack.Value;
    if Sender = SpecularIntensityTrack then Surface.Specularintensity := SpecularIntensityTrack.Value;
    if Sender = ExposureTrack then Surface.Exposure := ExposureTrack.Value;
    if Sender = ScalingTrack then Surface.Size := ScalingTrack.Value;
    if Sender = FresnelOffsetTrack then Surface.FresnelOffset := FresnelOffsetTrack.Value;
    if Sender = TransparencyTrack then Surface.Transparency := TransparencyTrack.Value;
    if Sender = DepthOpacityRangeTrack then Surface.DepthTransparencyRange := DepthOpacityRangeTrack.Value;
    if Sender = RefractionIndexTrack then Surface.RefractionIndex := RefractionIndexTrack.Value;
    if Sender = RefractionSteplength then Surface.RefractionSteplength := RefractionSteplength.Value;
    if Sender = RefractionSamplesTrack then Surface.RefractionSteps := RefractionSamplesTrack.Value;
    if Sender = ColorExtinctionTrack then Surface.ColorExtinctionRange := ColorExtinctionTrack.Value;
    if Sender = CausticsRangeTrack then Surface.CausticsRange := CausticsRangeTrack.Value;
    if Sender = ReflectionCheck then Surface.Reflections := ReflectionCheck.Checked;
    if Sender = RefractionCheck then Surface.Refraction := RefractionCheck.Checked;
    if Sender = CausticsScaleTrack then Surface.CausticsScale := CausticsScaleTrack.Value;
    if (Sender = HueImage) or (Sender = SaturationValueImage) then
    begin
      if ColorRadio.Items[ColorRadio.ItemIndex] = 'Sky' then Surface.SkyColor := ColorPicker.Color;
      if ColorRadio.Items[ColorRadio.ItemIndex] = 'Water' then Surface.WaterColor := ColorPicker.Color;
    end;
    if (Sender = TextureEdit) or (Sender = SkyEdit) or (Sender = CausticsEdit) then
    begin
      if TextureOpenDialog.Execute then
      begin
        if Sender = SkyEdit then Surface.SkyTexture := TextureOpenDialog.filename
        else if Sender = CausticsEdit then Surface.CausticsTexture := TextureOpenDialog.filename
        else Surface.WaveTexture := TextureOpenDialog.filename;
      end;
    end;
    if Sender = TextureRemoveBtn then Surface.WaveTexture := '';
    if Sender = SkyRemoveBtn then Surface.SkyTexture := '';
    if Sender = CausticsRemoveBtn then Surface.CausticsTexture := '';
    SyncSurface;
    if Sender = DeleteSurfaceBtn then
    begin
      FWaterManager.RemoveSurface(Surface);
      SyncSurfaces;
    end;
  end;
  if Sender = AddSurfaceBtn then
  begin
    FWaterManager.AddSurface(TWaterSurface.CreateEmpty(GFXD.MainScene));
    SyncSurfaces;
  end;
  if Sender = GeometryResolutionEdit then
  begin
    try
      Surface.GeometryResolution := StrToInt(GeometryResolutionEdit.Text)
    except
      on E : EConvertError do
    end;
  end;
  if Active then SelectionCheck.SetFocus;
end;

{ TWaterManagerHelper }

procedure TWaterManagerHelper.IdleEditor(UseInputs : boolean);
begin
  if assigned(WaterEditorForm) then WaterEditorForm.Idle(UseInputs);
end;

procedure TWaterManagerHelper.ShowEditor;
begin
  if not assigned(WaterEditorForm) then
  begin
    WaterEditorForm := TWaterEditorForm.Create(Application);
    WaterEditorForm.Top := 25;
    WaterEditorForm.Height := Screen.WorkAreaHeight - 25;
    WaterEditorForm.Left := Screen.WorkAreaWidth - WaterEditorForm.Width;
    WaterEditorForm.FWaterManager := Self;
    WaterEditorForm.WireFrameCheck.Checked := Self.DrawWireFramed;
    WaterEditorForm.WaterOpenDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
    WaterEditorForm.WaterSaveDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
    WaterEditorForm.ColorPicker := TLiveColorPicker.Create(WaterEditorForm.HueImage, WaterEditorForm.SaturationValueImage, WaterEditorForm.BigChange);
    WaterEditorForm.FWaterEditor := TWaterEditor.Create(Self);
    WaterEditorForm.BigChange(WaterEditorForm);
  end;
  WaterEditorForm.Show;
end;

procedure TWaterManagerHelper.HideEditor;
begin
  if assigned(WaterEditorForm) then WaterEditorForm.Hide;
end;

{ TWaterEditor }

constructor TWaterEditor.Create(WaterManager : TWaterManager);
begin
  FWaterManager := WaterManager;
  FIndex := -1;
end;

function TWaterEditor.CurrentWaterSurface : TWaterSurface;
begin
  if (FIndex < 0) or (FIndex > FWaterManager.SurfaceCount - 1) then Result := nil
  else Result := FWaterManager.Surfaces[FIndex];
end;

procedure TWaterEditor.Idle(UseInputs : boolean);
var
  i : Integer;
  Surface : TWaterSurface;
  ClickPos, SurfaceMaximum, SurfaceMinimum, new : RVector3;
  DragSizeRadius : single;
  ClickRay : RRay;
begin
  if not WaterEditorForm.Visible then exit;
  if not UseInputs or WaterEditorForm.Active or WaterEditorForm.MouseInClient then
  begin
    FDragging := EnumDragType.dtHack;
    exit;
  end;
  if FDragging = dtHack then
  begin
    FDragging := dtNone;
    exit;
  end;

  ClickRay := GFXD.MainScene.Camera.Clickvector(Mouse.Position);
  Surface := CurrentWaterSurface;
  // Select Surface
  if Mouse.ButtonUp(mbLeft) and (FDragging = dtNone) then
  begin
    for i := 0 to FWaterManager.SurfaceCount - 1 do
    begin
      ClickPos := RPlane.XZ.Translate(FWaterManager.Surfaces[i].Position * RVector3.UNITY).IntersectRay(ClickRay);
      if (ClickPos - FWaterManager.Surfaces[i].Position).abs.XZ <= (FWaterManager.Surfaces[i].GeometrySize / 2) then
      begin
        CurrentIndex := i;
        Surface := CurrentWaterSurface;
        WaterEditorForm.WaterSurfaceList.ItemIndex := i;
        WaterEditorForm.BigChange(WaterEditorForm.WaterSurfaceList);
        break;
      end;
    end;
  end;

  if not assigned(Surface) then exit;

  ClickPos := RPlane.XZ.Translate(Surface.Position * RVector3.UNITY).IntersectRay(ClickRay);

  DragSizeRadius := Surface.GeometrySize.X / 40;
  SurfaceMinimum := Surface.Position - (Surface.GeometrySize.X0Y * 0.5);
  SurfaceMaximum := Surface.Position + (Surface.GeometrySize.X0Y * 0.5);

  // Draw Helpers
  if WaterEditorForm.SelectionCheck.Checked then
  begin
    for i := 0 to 10 do
    begin
      LinePool.AddGrid(Surface.Position + RVector3.Create(0, (i / 10) * Surface.GeometrySize.MaxAbsValue / 6, 0), RVector3.UNITX, RVector3.UNITZ, Surface.GeometrySize, RColor($FF00FF00).Lerp($0000FF00, i / 10), 0);
    end;
    LinePool.AddSphere(SurfaceMinimum, DragSizeRadius, $FF00FF00);
    LinePool.AddSphere(SurfaceMaximum, DragSizeRadius, $FF00FF00);
    LinePool.AddArrow(Surface.Position + RVector3.Create(0, Surface.GeometrySize.MaxAbsValue / 6, 0), RVector3.UNITY, DragSizeRadius / 3, DragSizeRadius, $FF00FF00);
  end;

  // Process positioning and sizing
  if Mouse.ButtonDown(mbLeft) then
  begin
    if RSphere.CreateSphere(Surface.Position + RVector3.Create(0, Surface.GeometrySize.MaxAbsValue / 6, 0), DragSizeRadius).IntersectSphereRay(ClickRay) then FDragging := dtHeight
    else if ClickPos.Distance(SurfaceMinimum) <= DragSizeRadius then FDragging := dtMinimum
    else if ClickPos.Distance(SurfaceMaximum) <= DragSizeRadius then FDragging := dtMaximum
    else if (ClickPos - Surface.Position).abs.XZ <= (Surface.GeometrySize / 2) then FDragging := dtPosition
    else FDragging := dtNone;
    case FDragging of
      dtPosition : FDraggingOffset := Surface.Position - ClickPos;
      dtMinimum :
        FDraggingOffset := SurfaceMinimum - ClickPos;
      dtMaximum : FDraggingOffset := SurfaceMaximum - ClickPos;
      dtHeight :
        begin
          FStartingPosition := Surface.Position;
          FDraggingOffset := -RVector3.Create(0, Surface.GeometrySize.MaxAbsValue / 6, 0);
        end;
    end;
  end;

  if (FDragging <> dtNone) and Mouse.ButtonIsDown(mbLeft) then
  begin
    case FDragging of
      dtPosition : Surface.Position := ClickPos + FDraggingOffset;
      dtHeight : Surface.Position := RRay.Create(FStartingPosition, RVector3.UNITY).NearestPointToRay(ClickRay) + FDraggingOffset;
      dtMinimum :
        begin
          new := ClickPos + FDraggingOffset;
          Surface.Position := new.Lerp(SurfaceMaximum, 0.5);
          Surface.GeometrySize := (SurfaceMaximum - new).XZ;
        end;
      dtMaximum :
        begin
          new := ClickPos + FDraggingOffset;
          Surface.Position := new.Lerp(SurfaceMinimum, 0.5);
          Surface.GeometrySize := (new - SurfaceMinimum).XZ;
        end;
    end;
  end;

  if Mouse.ButtonUp(mbLeft) then FDragging := dtNone;
end;

procedure TWaterEditor.setIndex(const Value : Integer);
begin
  FIndex := Value;
end;

end.
