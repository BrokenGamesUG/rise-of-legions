unit Engine.Vegetation.Editor;

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
  Engine.Vegetation,
  Vcl.ExtCtrls,
  Vcl.Buttons,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.VCLUtils,
  Engine.GFXApi,
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
  Engine.Input,
  Engine.Terrain,
  generics.collections;

type

  TVegetationEditor = class;

  TVegetationEditorForm = class(TForm)
    TextureOpenDialog : TOpenDialog;
    MainMenu1 : TMainMenu;
    File1 : TMenuItem;
    Save1 : TMenuItem;
    New1 : TMenuItem;
    Save2 : TMenuItem;
    Saveas1 : TMenuItem;
    Open1 : TMenuItem;
    WireFrameCheck : TMenuItem;
    VegetationOpenDialog : TOpenDialog;
    VegetationSaveDialog : TSaveDialog;
    DrawkdTree1 : TMenuItem;
    StatBox : TListBox;
    PageControl1 : TPageControl;
    GeneralSheet : TTabSheet;
    TreeSheet : TTabSheet;
    GrassSheet : TTabSheet;
    GrassGeneralPanelPanel : TPanel;
    GrassDetailPanelPanel : TPanel;
    MouseModeRadio : TRadioGroup;
    TreeDetailPanelPanel : TPanel;
    GeneralCategoryPanel : TPanel;
    MeshSheet : TTabSheet;
    MeshGeneralPanel : TPanel;
    MeshDetailPanel : TPanel;
    Action1 : TMenuItem;
    Mirror1 : TMenuItem;
    MirrorXToNegativeXBtn : TMenuItem;
    MirrorNegativeXToXBtn : TMenuItem;
    MirrorZToNegativeZBtn : TMenuItem;
    MirrorNegativeZToZBtn : TMenuItem;
    N1 : TMenuItem;
    PointMirrorXToNegativeXBtn : TMenuItem;
    PointMirrorNegativeXToXBtn : TMenuItem;
    PointMirrorZToNegativeZBtn : TMenuItem;
    PointMirrorNegativeZToZBtn : TMenuItem;
    procedure BigChange(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure Save2Click(Sender : TObject);
    procedure Saveas1Click(Sender : TObject);
    procedure Open1Click(Sender : TObject);
    procedure New1Click(Sender : TObject);
    procedure FormDestroy(Sender : TObject);
    procedure FormCreate(Sender : TObject);
    private
      { Private-Deklarationen }
      FVegetationManager : TVegetationManager;
      FVegetationEditor : TVegetationEditor;
      PreventChanges : boolean;
      MountedFile : string;
      FStatSync : TTimer;
      procedure SyncStats;
    public
      { Public-Deklarationen }
      procedure Idle(UseInputs : boolean);
  end;

  TTreeHelper = class helper for TTree
    public
      procedure DrawBoundings(Color : RColor);
  end;

  TVegetationManagerHelper = class helper for TVegetationManager
    public
      function VegetationObjects : TUltimateObjectList<TVegetationObject>;
      function GetTree(Clickvector : RRay) : TTree;
      function GetThing<T : class>(Clickvector : RRay) : T;
      procedure ShowEditor(Terrain : TTerrain = nil);
      procedure IdleEditor(UseInputs : boolean);
      procedure HideEditor;
  end;

  EnumSprayEditorMode = (gmPipette, gmAdd, gmRemove, gmEdit);

  TSprayEditor<T : class> = class abstract
    protected
      FParent : TVegetationEditor;
      FBrushSize : RVariedSingle;
      FBrushMode : EnumSprayEditorMode;
      FGeneralBoundForm, FDetailForm : TBoundForm;
      FFirst : boolean;
      FLastPosition : RVector3;
      FBrushDensity : integer;
      FBrushFlowrate : Single;
      function GetDefaultInstance : T; virtual; abstract;
      function GetInstance(Position, Normal : RVector3) : T; virtual; abstract;
    public
      constructor Create(Parent : TVegetationEditor; TargetGeneralPanel, TargetDetailPanel : TControl);
      [VCLVariedSingleField(10, 10)]
      property BrushSize : RVariedSingle read FBrushSize write FBrushSize;
      [VCLEnumField]
      property BrushMode : EnumSprayEditorMode read FBrushMode write FBrushMode;
      [VCLIntegerField(1, 50)]
      property BrushDensity : integer read FBrushDensity write FBrushDensity;
      [VCLSingleField(10.0)]
      property BrushFlow : Single read FBrushFlowrate write FBrushFlowrate;
      procedure Idle(UseInputs : boolean); virtual;
      destructor Destroy; override;
  end;

  TGrassEditor = class(TSprayEditor<TGrassTuft>)
    protected
      function GetDefaultInstance : TGrassTuft; override;
      function GetInstance(Position, Normal : RVector3) : TGrassTuft; override;
  end;

  TVegetationMeshEditor = class(TSprayEditor<TVegetationMesh>)
    protected
      function GetDefaultInstance : TVegetationMesh; override;
      function GetInstance(Position, Normal : RVector3) : TVegetationMesh; override;
  end;

  EnumTreeEditorMode = (emSelection, emAdding);

  EnumEditorMode = (emGeneral, emTree, emGrass, emMesh);

  TVegetationEditor = class
    private
      procedure setSelectedTree(const Value : TTree);
    protected
      FSelectedTree : TTree;
      FVegetationManager : TVegetationManager;
      FManagerForm : TBoundForm;
    public
      TreeMode : EnumTreeEditorMode;
      Mode : EnumEditorMode;
      Terrain : TTerrain;
      GrassEditor : TGrassEditor;
      MeshEditor : TVegetationMeshEditor;
      TreeBoundForm : TBoundForm;
      property SelectedTree : TTree read FSelectedTree write setSelectedTree;
      constructor Create(VegetationManager : TVegetationManager);
      function IsSelected : boolean;
      procedure RemoveSelected;
      procedure Idle(UseInputs : boolean);
      destructor Destroy; override;
  end;

var
  VegetationEditorForm : TVegetationEditorForm;

implementation

{$R *.dfm}


procedure TVegetationEditorForm.FormCreate(Sender : TObject);
begin
  FStatSync := TTimer.CreateAndStart(50);
end;

procedure TVegetationEditorForm.FormDestroy(Sender : TObject);
begin
  FStatSync.Free;
  FVegetationEditor.Free;
end;

procedure TVegetationEditorForm.FormShow(Sender : TObject);
begin
  Left := Screen.WorkAreaRect.Right - Width;
  Top := 0;
  Height := Screen.WorkAreaHeight;
  TextureOpenDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
end;

procedure TVegetationEditorForm.Idle(UseInputs : boolean);
begin
  FVegetationEditor.Idle(UseInputs);
end;

procedure TVegetationEditorForm.New1Click(Sender : TObject);
begin
  MountedFile := '';
  FVegetationManager.Free;
  FVegetationManager := TVegetationManager.Create(GFXD.MainScene);
end;

procedure TVegetationEditorForm.Open1Click(Sender : TObject);
begin
  if VegetationOpenDialog.Execute then
  begin
    MountedFile := VegetationOpenDialog.filename;
    FVegetationManager.LoadFromFile(VegetationOpenDialog.filename);
    BigChange(Self);
  end;
end;

procedure TVegetationEditorForm.Save2Click(Sender : TObject);
begin
  if (MountedFile <> '') or VegetationSaveDialog.Execute then
  begin
    if (MountedFile = '') then MountedFile := VegetationSaveDialog.filename;
    FVegetationManager.SaveToFile(MountedFile);
  end;
end;

procedure TVegetationEditorForm.Saveas1Click(Sender : TObject);
begin
  MountedFile := '';
  Save2Click(Self);
end;

procedure TVegetationEditorForm.SyncStats;
var
  i : integer;
begin
  if FStatSync.Expired then
  begin
    FStatSync.Start;
    i := FVegetationManager.VegetationObjects.Extra.Fold<integer>(
      function(item : TVegetationObject) : integer
      begin
        if item is TTree then Result := 1
        else Result := 0
      end,
      HFoldOperators.AddInteger);

    StatBox.Clear;
    StatBox.Items.Add('Trees: ' + Inttostr(i));
    i := FVegetationManager.VegetationObjects.Extra.Fold<integer>(
      function(item : TVegetationObject) : integer
      begin
        if item is TGrassTuft then Result := 1
        else Result := 0
      end,
      HFoldOperators.AddInteger);
    StatBox.Items.Add('Grasstufts: ' + Inttostr(i));
    i := FVegetationManager.VegetationObjects.Extra.Fold<integer>(
      function(item : TVegetationObject) : integer
      begin
        if item is TVegetationMesh then Result := 1
        else Result := 0
      end,
      HFoldOperators.AddInteger);
    StatBox.Items.Add('Meshes: ' + Inttostr(i));
    StatBox.Items.Add('DrawCalls: ' + Inttostr(FVegetationManager.DrawCalls));
    StatBox.Items.Add('Triangles: ' + Inttostr(FVegetationManager.DrawnTriangles));
  end;
end;

procedure TVegetationEditorForm.BigChange(Sender : TObject);
begin
  if PreventChanges then exit;
  if Sender = Self then
  begin
    SyncStats;
    BigChange(PageControl1);
  end;
  if Sender = MouseModeRadio then FVegetationEditor.TreeMode := EnumTreeEditorMode(MouseModeRadio.ItemIndex);
  if Sender = WireFrameCheck then FVegetationManager.DrawWireframe := WireFrameCheck.Checked;
  if Sender = DrawkdTree1 then FVegetationManager.DrawkdTree := DrawkdTree1.Checked;
  if Sender = MirrorXToNegativeXBtn then FVegetationManager.Symmetry(0, False, False);
  if Sender = MirrorNegativeXToXBtn then FVegetationManager.Symmetry(0, True, False);
  if Sender = MirrorZToNegativeZBtn then FVegetationManager.Symmetry(2, False, False);
  if Sender = MirrorNegativeZToZBtn then FVegetationManager.Symmetry(2, True, False);
  if Sender = PointMirrorXToNegativeXBtn then FVegetationManager.Symmetry(0, False, True);
  if Sender = PointMirrorNegativeXToXBtn then FVegetationManager.Symmetry(0, True, True);
  if Sender = PointMirrorZToNegativeZBtn then FVegetationManager.Symmetry(2, False, True);
  if Sender = PointMirrorNegativeZToZBtn then FVegetationManager.Symmetry(2, True, True);
  if Sender = PageControl1 then
  begin
    FVegetationEditor.Mode := EnumEditorMode(PageControl1.TabIndex);
    case FVegetationEditor.Mode of
      emGeneral : FVegetationEditor.FManagerForm.Sort;
      emTree : FVegetationEditor.TreeBoundForm.Sort;
      emGrass :
        begin
          FVegetationEditor.GrassEditor.FGeneralBoundForm.Sort;
          FVegetationEditor.GrassEditor.FDetailForm.Sort;
        end;
      emMesh :
        begin
          FVegetationEditor.MeshEditor.FGeneralBoundForm.Sort;
          FVegetationEditor.MeshEditor.FDetailForm.Sort;
        end;
    end;
  end;
end;

{ TVegetationManagerHelper }

procedure TVegetationManagerHelper.IdleEditor(UseInputs : boolean);
begin
  if assigned(VegetationEditorForm) then VegetationEditorForm.Idle(UseInputs);
end;

procedure TVegetationManagerHelper.ShowEditor(Terrain : TTerrain);
begin
  if not assigned(VegetationEditorForm) then
  begin
    VegetationEditorForm := TVegetationEditorForm.Create(Application);
    VegetationEditorForm.Top := 25;
    VegetationEditorForm.Height := Screen.WorkAreaHeight - 25;
    VegetationEditorForm.Left := Screen.WorkAreaWidth - VegetationEditorForm.Width;
    VegetationEditorForm.FVegetationManager := Self;
    VegetationEditorForm.VegetationOpenDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
    VegetationEditorForm.VegetationSaveDialog.InitialDir := HFilepathManager.AbsoluteWorkingPath;
    VegetationEditorForm.Show;
    VegetationEditorForm.FVegetationEditor := TVegetationEditor.Create(Self);
    VegetationEditorForm.FVegetationEditor.Terrain := Terrain;
    VegetationEditorForm.FVegetationEditor.TreeBoundForm := TFormGenerator.GenerateForm(VegetationEditorForm.TreeDetailPanelPanel, TTree);
    VegetationEditorForm.BigChange(VegetationEditorForm);
  end
  else VegetationEditorForm.Show;
end;

function TVegetationManagerHelper.VegetationObjects : TUltimateObjectList<TVegetationObject>;
begin
  Result := FVegetationObjects;
end;

function TVegetationManagerHelper.GetTree(Clickvector : RRay) : TTree;
var
  i : integer;
begin
  for i := 0 to VegetationObjects.Count - 1 do
    if (VegetationObjects[i] is TTree) and VegetationObjects[i].GetBoundingSphere.IntersectSphereRay(Clickvector) then exit(VegetationObjects[i] as TTree);
  Result := nil;
end;

function TVegetationManagerHelper.GetThing<T>(Clickvector : RRay) : T;
var
  i : integer;
begin
  for i := 0 to VegetationObjects.Count - 1 do
    if (VegetationObjects[i] is T) and VegetationObjects[i].GetBoundingSphere.IntersectSphereRay(Clickvector) then exit(VegetationObjects[i] as T);
  Result := nil;
end;

procedure TVegetationManagerHelper.HideEditor;
begin
  if assigned(VegetationEditorForm) then VegetationEditorForm.Hide;
end;

{ TVegetationEditor }

constructor TVegetationEditor.Create(VegetationManager : TVegetationManager);
begin
  FVegetationManager := VegetationManager;
  GrassEditor := TGrassEditor.Create(Self, VegetationEditorForm.GrassGeneralPanelPanel, VegetationEditorForm.GrassDetailPanelPanel);
  MeshEditor := TVegetationMeshEditor.Create(Self, VegetationEditorForm.MeshGeneralPanel, VegetationEditorForm.MeshDetailPanel);
  FManagerForm := TFormGenerator.GenerateForm(VegetationEditorForm.GeneralCategoryPanel, TVegetationManager);
  FManagerForm.BoundInstance := FVegetationManager;
end;

destructor TVegetationEditor.Destroy;
begin
  FManagerForm.Free;
  TreeBoundForm.Free;
  MeshEditor.Free;
  GrassEditor.Free;
  inherited;
end;

procedure TVegetationEditor.Idle(UseInputs : boolean);
var
  Target, Normal : RVector3;
  ClickRay : RRay;
  Tree : TTree;
begin
  if not VegetationEditorForm.Visible then exit;

  VegetationEditorForm.SyncStats;

  if Mode = emGrass then GrassEditor.Idle(UseInputs)
  else
    if Mode = emMesh then MeshEditor.Idle(UseInputs)
  else
  begin

    if assigned(SelectedTree) then SelectedTree.DrawBoundings($FF00FF00);

    if not UseInputs or VegetationEditorForm.Active or VegetationEditorForm.MouseInClient then exit;

    ClickRay := GFXD.MainScene.Camera.Clickvector(Mouse.Position);

    case TreeMode of
      emSelection :
        begin
          Tree := FVegetationManager.GetTree(ClickRay);
          if assigned(Tree) then Tree.DrawBoundings(RColor.CNEONORANGE);
          if Mouse.ButtonUp(mbLeft) then SelectedTree := Tree;
          if Mouse.ButtonUp(mbRight) and not Mouse.WasDragging then SelectedTree := nil;
          if Keyboard.KeyUp(TasteEntf) then RemoveSelected;
          if Keyboard.KeyUp(TasteR) and IsSelected then SelectedTree.ReRoll;
        end;
      emAdding :
        begin
          SelectedTree := nil;
          if Mouse.ButtonUp(mbLeft) then
          begin
            if assigned(Terrain) then Target := Terrain.IntersectRayTerrain(ClickRay, @Normal)
            else Target := RPlane.XZ.IntersectRay(ClickRay);
            Tree := TTree.Create(Target - (0.5 * Normal), Normal, -RVector3.UNITY);
            TreeBoundForm.SetUpInstance(Tree);
            FVegetationManager.AddVegetationObject(Tree);

            VegetationEditorForm.SyncStats;
          end;
        end;
    end;

    if not assigned(SelectedTree) then exit;
  end;
end;

function TVegetationEditor.IsSelected : boolean;
begin
  Result := assigned(SelectedTree);
end;

procedure TVegetationEditor.RemoveSelected;
begin
  if not IsSelected then exit;
  FVegetationManager.RemoveVegetationObject(SelectedTree);
  SelectedTree := nil;
end;

procedure TVegetationEditor.setSelectedTree(const Value : TTree);
begin
  if Value <> FSelectedTree then
  begin
    FSelectedTree := Value;
    TreeBoundForm.BoundInstance := FSelectedTree;
    VegetationEditorForm.SyncStats;
  end
  else FSelectedTree := Value;
end;

{ TTreeHelper }

procedure TTreeHelper.DrawBoundings(Color : RColor);
begin
  LinePool.AddSphere(GetBoundingSphere, Color);
end;

{ TSprayEditor<T> }

constructor TSprayEditor<T>.Create(Parent : TVegetationEditor; TargetGeneralPanel, TargetDetailPanel : TControl);
var
  DefaultInstance : T;
begin
  FParent := Parent;
  FBrushSize := RVariedSingle.Create(5, 1);
  FBrushMode := gmPipette;
  FBrushDensity := 5;
  FBrushFlowrate := 1;
  FGeneralBoundForm := TFormGenerator.GenerateForm(TargetGeneralPanel, Self.ClassType);
  FGeneralBoundForm.BoundInstance := Self;
  FDetailForm := TFormGenerator.GenerateForm(TargetDetailPanel, T);
  // set default values in form fields
  DefaultInstance := GetDefaultInstance;
  FDetailForm.BoundInstance := Pointer(DefaultInstance);
  FDetailForm.BoundInstance := nil;
  DefaultInstance.Free;
end;

destructor TSprayEditor<T>.Destroy;
begin
  FGeneralBoundForm.Free;
  FDetailForm.Free;
  inherited;
end;

procedure TSprayEditor<T>.Idle(UseInputs : boolean);
var
  ClickRay : RRay;
  GroundTarget, GroundNormal, Target, targetNormal : RVector3;
  Thing : T;
  i : integer;
  selectedThings : TAdvancedList<TVegetationObject>;
begin

  ClickRay := GFXD.MainScene.Camera.Clickvector(Mouse.Position);

  if FParent.Terrain = nil then GroundTarget := RPlane.XZ.IntersectRay(ClickRay)
  else GroundTarget := FParent.Terrain.IntersectRayTerrain(ClickRay, @GroundNormal);

  // draw brush
  if BrushMode in [gmAdd, gmRemove, gmEdit] then
  begin
    GroundNormal := RVector3.UNITY;
    if FParent.Terrain = nil then LinePool.AddCircle(GroundTarget, RVector3.UNITY, BrushSize.Mean, BrushSize.Mean + BrushSize.Variance, RColor.CGRASSGREEN)
    else LinePool.DrawCircleOnTerrain(FParent.Terrain, GroundTarget, BrushSize.Mean, BrushSize.Mean + BrushSize.Variance, RColor.CGRASSGREEN, 10);
  end;

  if not UseInputs or VegetationEditorForm.Active or VegetationEditorForm.MouseInClient then exit;

  if not Mouse.WasDragging and Mouse.ButtonUp(mbRight) then
  begin
    BrushMode := gmPipette;
    FGeneralBoundForm.ExternChange;
  end;

  case BrushMode of
    gmPipette :
      begin
        Thing := FParent.FVegetationManager.GetThing<T>(ClickRay);
        if assigned(Thing) and Mouse.ButtonUp(mbLeft) then
        begin
          FDetailForm.BoundInstance := Pointer(Thing);
          FDetailForm.BoundInstance := nil;
        end;
      end;
    gmAdd, gmRemove, gmEdit :
      begin
        if Mouse.ButtonDown(mbLeft) then
        begin
          FFirst := True;
          FLastPosition := GroundTarget;
        end;
        if (FFirst or (FLastPosition.DistanceXZ(GroundTarget) >= BrushFlow)) and Mouse.ButtonIsDown(mbLeft) then
        begin
          Randomize;
          FFirst := False;
          if BrushMode = gmAdd then
          begin
            for i := 0 to FBrushDensity - 1 do
            begin
              Target := RVariedVector3.Create(GroundTarget, RVector3.Create(BrushSize.Mean + BrushSize.Variance)).getRandomVector;
              if (Target.DistanceXZ(GroundTarget) > BrushSize.Mean) and ((Target.DistanceXZ(GroundTarget) - BrushSize.Mean) / BrushSize.Variance > random) then continue;
              if FParent.Terrain = nil then Thing := GetInstance(Target.SetY(0), GroundNormal)
              else
              begin
                Target := FParent.Terrain.GetTerrainHeight(Target, False, @targetNormal);
                Thing := GetInstance(Target, targetNormal)
              end;
              FDetailForm.SetUpInstance(Pointer(Thing));
              FParent.FVegetationManager.AddVegetationObject(TVegetationObject(Thing));
            end;
          end
          else
          begin
            selectedThings := FParent.FVegetationManager.VegetationObjects.Extra.Filter(
              function(item : TVegetationObject) : boolean
              begin
                Result := (item is T) and
                  ((GroundTarget.DistanceXZ(item.Position) <= BrushSize.Mean) or
                  ((GroundTarget.DistanceXZ(item.Position) - BrushSize.Mean) / BrushSize.Variance < random));

              end);
            if BrushMode = gmRemove then
                selectedThings.Each(
                procedure(const item : TVegetationObject)
                begin
                  FParent.FVegetationManager.RemoveVegetationObject(item);
                end
                )
            else
            begin
              selectedThings.Each(
                procedure(const item : TVegetationObject)
                var
                  Normal : RVector3;
                begin
                  FDetailForm.SetUpInstance(item);
                  if assigned(FParent.Terrain) then
                  begin
                    item.Position := FParent.Terrain.GetTerrainHeight(item.Position, False, @Normal);
                    item.GroundNormal := Normal;
                  end;
                end);
              FDetailForm.BoundInstance := nil;
            end;
            selectedThings.Free;
          end;
          VegetationEditorForm.SyncStats;
        end;
      end;
  end;
end;

const
  HackyPath1 : string = 'Graphics\Environment\Grass\';

  { TGrassEditor }

function TGrassEditor.GetDefaultInstance : TGrassTuft;
begin
  // set default values
  Result := TGrassTuft.Create(RVector3.ZERO, RVector3.UNITY);
  Result.Diffuse := HackyPath1 + 'Grass.png';
end;

function TGrassEditor.GetInstance(Position, Normal : RVector3) : TGrassTuft;
begin
  Result := TGrassTuft.Create(Position, Normal);
  Result.Diffuse := HackyPath1 + 'Grass.png';
end;

const
  HackyPath2 : string = 'Graphics\Environment\Palmtrees\';

  { TVegetationMeshEditor }

function TVegetationMeshEditor.GetDefaultInstance : TVegetationMesh;
begin
  Result := TVegetationMesh.Create(RVector3.ZERO, RVector3.UNITY);
  Result.Diffuse := HackyPath2 + 'PalmtreeDiffuse.tga';
  Result.Meshes := HackyPath2 + 'Palmtree1.fbx' + sLineBreak +
    HackyPath2 + 'Palmtree2.fbx';
end;

function TVegetationMeshEditor.GetInstance(Position, Normal : RVector3) : TVegetationMesh;
begin
  Result := TVegetationMesh.Create(Position, Normal);
  Result.Diffuse := 'PalmtreeDiffuse.tga';
  Result.Meshes := HackyPath2 + 'Palmtree1.fbx' + sLineBreak +
    HackyPath2 + 'Palmtree2.fbx';
end;

end.
