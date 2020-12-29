unit Engine.AnimatedBackground.Editor;

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
  Engine.AnimatedBackground,
  Vcl.ExtCtrls,
  Vcl.Buttons,
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Windows,
  Engine.Helferlein.VCLUtils,
  Math,
  FileCtrl,
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

  TAnimatedImageEditor = class;

  TAnimatedImageEditorForm = class(TForm)
    MainMenu1 : TMainMenu;
    Save1 : TMenuItem;
    ToolBox : TCategoryPanelGroup;
    CategoryPanel2 : TCategoryPanel;
    LayerList : TListBox;
    Panel2 : TPanel;
    Animated1 : TMenuItem;
    File1 : TMenuItem;
    Save2 : TMenuItem;
    Saveas1 : TMenuItem;
    Open1 : TMenuItem;
    OpenDialog : TOpenDialog;
    SaveDialog : TSaveDialog;
    Label1 : TLabel;
    TimeLineTrack : TTrackBar;
    TimeScaleEdit : TEdit;
    Label2 : TLabel;
    ClearKeyframesBtn : TButton;
    RemoveVertexButton : TButton;
    Label3 : TLabel;
    LayerDepthEdit : TEdit;
    procedure BigChange(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure FormDestroy(Sender : TObject);
    procedure Open1Click(Sender : TObject);
    procedure Save2Click(Sender : TObject);
    procedure Saveas1Click(Sender : TObject);
    private
      { Private-Deklarationen }
      FAnimatedImage : TAnimatedImage;
      FAnimatedImageEditor : TAnimatedImageEditor;
      PreventChanges : boolean;
      MountedFile : string;
    public
      { Public-Deklarationen }
      procedure Idle(UseInputs : boolean);
  end;

  TAnimatedImageHelper = class helper for TAnimatedImage
    public
      procedure ShowEditor;
      procedure IdleEditor(UseInputs : boolean);
      procedure HideEditor;
  end;

  TAnimatedImageLayerHelper = class helper for TAnimatedImageLayer
    public
      procedure RenderDebug(Selected : boolean);
  end;

  TAnimatedImageEditor = class
    protected
      FDragging : boolean;
      FIndex, FTriangleIndex, FSelectedVertex : Integer;
      FNextTriangle : RIntVector3;
      FAnimatedImage : TAnimatedImage;
      procedure setIndex(const Value : Integer);
      function IsVertexSelected : boolean;
      procedure ClearKeyFramesForSelectedVertex;
      procedure RemoveSelectedVertex;
    public
      constructor Create(AnimatedImage : TAnimatedImage);
      property CurrentIndex : Integer read FIndex write setIndex;
      function CurrentAnimatedImageLayer : TAnimatedImageLayer;
      procedure Idle(UseInputs : boolean);
  end;

var
  AnimatedImageEditorForm : TAnimatedImageEditorForm;

implementation

{$R *.dfm}


procedure TAnimatedImageEditorForm.FormDestroy(Sender : TObject);
begin
  FAnimatedImageEditor.Free;
end;

procedure TAnimatedImageEditorForm.FormShow(Sender : TObject);
begin
  Left := Screen.WorkAreaRect.Right - Width;
  Top := 0;
  Height := Screen.WorkAreaHeight;
end;

procedure TAnimatedImageEditorForm.Idle(UseInputs : boolean);
begin
  FAnimatedImageEditor.Idle(UseInputs);
end;

procedure TAnimatedImageEditorForm.Open1Click(Sender : TObject);
var
  newImage : TAnimatedImage;
begin
  if OpenDialog.Execute then
  begin
    MountedFile := OpenDialog.filename;
    FreeAndNil(FAnimatedImage);
    newImage := TAnimatedImage.CreateFromFile(MountedFile);
    FAnimatedImage := newImage;
    BigChange(Self);
  end;
end;

procedure TAnimatedImageEditorForm.Save2Click(Sender : TObject);
begin
  if (MountedFile <> '') or SaveDialog.Execute then
  begin
    if (MountedFile = '') then MountedFile := SaveDialog.filename;
    FAnimatedImage.SaveToFile(MountedFile);
  end;
end;

procedure TAnimatedImageEditorForm.Saveas1Click(Sender : TObject);
begin
  MountedFile := '';
  Save2Click(Self);
end;

procedure TAnimatedImageEditorForm.BigChange(Sender : TObject);
  procedure SyncList;
  var
    i : Integer;
  begin
    LayerList.Clear;
    for i := 0 to FAnimatedImage.Layer.Count - 1 do
    begin
      LayerList.Items.Add(ExtractFilename(FAnimatedImage.Layer[i].TextureFilename));
    end;
  end;

var
  Layer : TAnimatedImageLayer;
  s : single;
begin
  if PreventChanges then exit;
  if Sender = Self then
  begin
    SyncList;
    BigChange(LayerList);
  end;
  if Sender = LayerList then
  begin
    FAnimatedImageEditor.CurrentIndex := LayerList.ItemIndex;
  end;
  Layer := FAnimatedImageEditor.CurrentAnimatedImageLayer;
  if assigned(Layer) then
  begin
    if Sender = TimeScaleEdit then
      if TryStrToFloat(TimeScaleEdit.Text, s) then Layer.TimeScale := s;
    if Sender = LayerDepthEdit then
      if TryStrToFloat(LayerDepthEdit.Text, s) then Layer.Depth := s;
    if Sender = LayerList then
    begin
      TimeScaleEdit.Text := FloatToStrF(Layer.TimeScale, ffGeneral, 4, 4);
      LayerDepthEdit.Text := FloatToStrF(Layer.Depth, ffGeneral, 4, 4);
    end;
    if (Sender = ClearKeyframesBtn) then FAnimatedImageEditor.ClearKeyFramesForSelectedVertex;
    if (Sender = RemoveVertexButton) then FAnimatedImageEditor.RemoveSelectedVertex;
  end;
end;

{ TAnimatedImageHelper }

procedure TAnimatedImageHelper.IdleEditor(UseInputs : boolean);
begin
  if assigned(AnimatedImageEditorForm) then AnimatedImageEditorForm.Idle(UseInputs);
end;

procedure TAnimatedImageHelper.ShowEditor;
begin
  if not assigned(AnimatedImageEditorForm) then
  begin
    AnimatedImageEditorForm := TAnimatedImageEditorForm.Create(Application);
    AnimatedImageEditorForm.Top := 25;
    AnimatedImageEditorForm.Height := Screen.WorkAreaHeight - 25;
    AnimatedImageEditorForm.Left := Screen.WorkAreaWidth - AnimatedImageEditorForm.Width;
    AnimatedImageEditorForm.OpenDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
    AnimatedImageEditorForm.SaveDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
    AnimatedImageEditorForm.FAnimatedImage := Self;
    AnimatedImageEditorForm.FAnimatedImageEditor := TAnimatedImageEditor.Create(Self);
    AnimatedImageEditorForm.BigChange(AnimatedImageEditorForm);
  end;
  AnimatedImageEditorForm.Show;
end;

procedure TAnimatedImageHelper.HideEditor;
begin
  if assigned(AnimatedImageEditorForm) then AnimatedImageEditorForm.Hide;
end;

{ TAnimatedImageEditor }

procedure TAnimatedImageEditor.ClearKeyFramesForSelectedVertex;
begin
  if IsVertexSelected then
  begin
    CurrentAnimatedImageLayer.Keyframes.Remove(FSelectedVertex);
  end;
end;

constructor TAnimatedImageEditor.Create(AnimatedImage : TAnimatedImage);
begin
  FAnimatedImage := AnimatedImage;
  FIndex := -1;
  FTriangleIndex := 0;
  FSelectedVertex := -1;
end;

function TAnimatedImageEditor.CurrentAnimatedImageLayer : TAnimatedImageLayer;
begin
  if FIndex < 0 then Result := nil
  else Result := FAnimatedImage.Layer[FIndex];
end;

procedure TAnimatedImageEditor.Idle(UseInputs : boolean);
const
  CLICK_RADIUS = 6;
  function GetVertexAtPosition(Layer : TAnimatedImageLayer; CursorPos : RVector2) : Integer;
  begin
    Result := TAdvancedList<RVector2>(Layer.Vertices).MinIndex(
      function(Item : RVector2) : single
      begin
        Result := Layer.ScreenToLayer(CursorPos).Distance(Item);
      end);
    if (Result >= 0) and (Layer.LayerToScreen(Layer.Vertices[Result]).Distance(CursorPos) > CLICK_RADIUS) then
        Result := -1;
  end;

var
  i, VertexIndex : Integer;
  Layer : TAnimatedImageLayer;
  ClickPos, SurfaceMaximum, SurfaceMinimum, new : RVector2;
  DragSizeRadius : single;
  ClickRay : RRay;
begin
  FAnimatedImage.Animated := -1;
  if not AnimatedImageEditorForm.Visible then exit;
  if not AnimatedImageEditorForm.Animated1.Checked then
      FAnimatedImage.Animated := AnimatedImageEditorForm.TimeLineTrack.Value;

  Layer := CurrentAnimatedImageLayer;

  for i := 0 to FAnimatedImage.Layer.Count - 1 do
  begin
    FAnimatedImage.Layer[i].RenderDebug(i = CurrentIndex);
  end;

  if not assigned(Layer) then exit;

  for i := 0 to FTriangleIndex - 1 do
  begin
    RHWLinePool.AddCircle(Layer.LayerToScreen(Layer.Vertices[FNextTriangle.Element[i]]).Round, CLICK_RADIUS, RColor.CYELLOW, 16);
  end;
  if FSelectedVertex >= 0 then
      RHWLinePool.AddCircle(Layer.LayerToScreen(Layer.Vertices[FSelectedVertex]).Round, CLICK_RADIUS, RColor.CRED, 16);

  if not UseInputs or AnimatedImageEditorForm.Active or AnimatedImageEditorForm.MouseInClient then exit;
  ClickPos := Mouse.Position;
  VertexIndex := GetVertexAtPosition(Layer, ClickPos);

  if Mouse.ButtonUp(mbLeft) then
  begin
    FDragging := False;
    if Keyboard.KeyIsDown(TasteSTRGLinks) then
    begin
      if (VertexIndex >= 0) then
      begin
        FNextTriangle.Element[FTriangleIndex] := VertexIndex;
        inc(FTriangleIndex);
        if FTriangleIndex > 2 then
        begin
          // finish triangle
          FTriangleIndex := 0;
          Layer.AddTriangle(FNextTriangle);
        end;
      end;
    end
    else
      if Keyboard.KeyIsDown(TasteShiftLinks) then
    begin
      // place vertex
      Layer.AddVertex(ClickPos);
    end
    else
      if VertexIndex >= 0 then
    begin
      // select vertex
      FSelectedVertex := VertexIndex;
    end;
  end;

  if Mouse.ButtonDown(mbLeft) then
  begin
    if IsVertexSelected and (VertexIndex = FSelectedVertex) then
        FDragging := True;
  end;

  if Mouse.IsDragging and Mouse.ButtonIsDown(mbLeft) and FDragging then
  begin
    if IsVertexSelected then
    begin
      Layer.SetKeyFrame(FSelectedVertex, AnimatedImageEditorForm.TimeLineTrack.Value, ClickPos);
    end;
  end;

  if Mouse.ButtonUp(mbRight) then
  begin
    // deselect vertex
    FSelectedVertex := -1;
  end;
end;

function TAnimatedImageEditor.IsVertexSelected : boolean;
begin
  Result := FSelectedVertex >= 0;
end;

procedure TAnimatedImageEditor.RemoveSelectedVertex;
var
  Layer : TAnimatedImageLayer;
begin
  if IsVertexSelected then
  begin
    Layer := CurrentAnimatedImageLayer;
    Layer.RemoveVertex(FSelectedVertex);
    FSelectedVertex := -1;
  end;
end;

procedure TAnimatedImageEditor.setIndex(const Value : Integer);
begin
  FIndex := Value;
  FTriangleIndex := 0;
  FSelectedVertex := -1;
end;

{ TAnimatedImageLayerHelper }

procedure TAnimatedImageLayerHelper.RenderDebug(Selected : boolean);
var
  i : Integer;
begin
  if Selected then
  begin
    RHWLinePool.AddRect(FQuad.Rect.Round, RColor.CNEONORANGE);
    // draw vertices
    for i := 0 to FVertices.Count - 1 do
    begin
      RHWLinePool.AddCircle(LayerToScreen(FVertices[i]).Round, 1, RColor.CGREEN, 4);
      RHWLinePool.AddCircle(LayerToScreen(FVertices[i]).Round, 2, RColor.CGREEN, 4);
    end;
    // draw triangles
    for i := 0 to FIndices.Count - 1 do
    begin
      RHWLinePool.AddLine(LayerToScreen(FVertices[FIndices[i].X]).Round, LayerToScreen(FVertices[FIndices[i].Y]).Round, $8000FF00);
      RHWLinePool.AddLine(LayerToScreen(FVertices[FIndices[i].Y]).Round, LayerToScreen(FVertices[FIndices[i].Z]).Round, $8000FF00);
      RHWLinePool.AddLine(LayerToScreen(FVertices[FIndices[i].Z]).Round, LayerToScreen(FVertices[FIndices[i].X]).Round, $8000FF00);
    end;
    // draw keyframes
    // draw vertices
    for i := 0 to FVertices.Count - 1 do
    begin
      RHWLinePool.AddCircle(LayerToScreen(GetVertexPositionInTime(i, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, 1, $8000FF80, 4);
      RHWLinePool.AddCircle(LayerToScreen(GetVertexPositionInTime(i, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, 2, $8000FF80, 4);
    end;
    // draw triangles
    for i := 0 to FIndices.Count - 1 do
    begin
      RHWLinePool.AddLine(LayerToScreen(GetVertexPositionInTime(FIndices[i].X, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, LayerToScreen(GetVertexPositionInTime(FIndices[i].Y, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, $4000FF80);
      RHWLinePool.AddLine(LayerToScreen(GetVertexPositionInTime(FIndices[i].Y, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, LayerToScreen(GetVertexPositionInTime(FIndices[i].Z, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, $4000FF80);
      RHWLinePool.AddLine(LayerToScreen(GetVertexPositionInTime(FIndices[i].Z, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, LayerToScreen(GetVertexPositionInTime(FIndices[i].X, AnimatedImageEditorForm.TimeLineTrack.Value)).Round, $4000FF80);
    end;
  end
  else
      RHWLinePool.AddRect(FQuad.Rect.Round, RColor.CGREEN);
end;

end.
