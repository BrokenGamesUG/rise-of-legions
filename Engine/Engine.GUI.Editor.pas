unit Engine.GUI.Editor;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  ShellApi,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Engine.Core,
  Engine.GUI,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.VCLUtils,
  Engine.Math,
  Engine.Vertex,
  Engine.Input,
  Vcl.StdCtrls,
  Vcl.Grids,
  Vcl.ValEdit,
  Vcl.FileCtrl,
  StrUtils,
  Generics.Collections,
  Vcl.ComCtrls,
  Vcl.Menus,
  Engine.Serializer.Types,
  Engine.Serializer,
  Vcl.ExtCtrls,
  System.UITypes,
  Vcl.ButtonGroup,
  System.ImageList,
  Vcl.ImgList,
  Vcl.Clipbrd;

type

  TGUI = class;

  CGUIClass = class of TGUIComponent;

  TGUIDebugForm = class(TForm)
    ComputedList : TValueListEditor;
    Label1 : TLabel;
    Label2 : TLabel;
    TemplateBox : TMemo;
    DomTree : TTreeView;
    TreePopUp : TPopupMenu;
    Delete1 : TMenuItem;
    N1 : TMenuItem;
    AddComponent1 : TMenuItem;
    AddStack1 : TMenuItem;
    MainMenu1 : TMainMenu;
    Save1 : TMenuItem;
    Load1 : TMenuItem;
    New1 : TMenuItem;
    SaveDialog1 : TSaveDialog;
    OpenDialog1 : TOpenDialog;
    Panel1 : TPanel;
    Panel2 : TPanel;
    Panel3 : TPanel;
    ChangeGraphicspath1 : TMenuItem;
    Dirty1 : TMenuItem;
    ErrorBox : TMemo;
    AddEdit1 : TMenuItem;
    Load2 : TMenuItem;
    Save2 : TMenuItem;
    AddProgressbar1 : TMenuItem;
    AddCheckbox1 : TMenuItem;
    File1 : TMenuItem;
    Settings1 : TMenuItem;
    ShowElementborders1 : TMenuItem;
    Column2Panel : TPanel;
    Column1Panel : TPanel;
    Panel4 : TPanel;
    TreeExpandAllBtn : TButton;
    TreeCollapseAllBtn : TButton;
    TreeCollapseSubBtn : TButton;
    TreeExpandSubBtn : TButton;
    Label4 : TLabel;
    ClassesMemo : TMemo;
    ComputedStylesMemo : TMemo;
    Label5 : TLabel;
    SaveDialogComponent : TSaveDialog;
    ExtractGSS1 : TMenuItem;
    OpenDialogComponent : TOpenDialog;
    ExtractdXML1 : TMenuItem;
    procedure TemplateBoxChange(Sender : TObject);
    procedure DomTreeClick(Sender : TObject);
    procedure DomTreeDragDrop(Sender, Source : TObject; X, Y : Integer);
    procedure DomTreeDragOver(Sender, Source : TObject; X, Y : Integer; State : TDragState; var Accept : Boolean);
    procedure DomTreeEdited(Sender : TObject; Node : TTreeNode; var S : string);
    procedure TreePopUpPopup(Sender : TObject);
    procedure DomTreeMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
    procedure Delete1Click(Sender : TObject);
    procedure New1Click(Sender : TObject);
    procedure Load1Click(Sender : TObject);
    procedure AddComponent1Click(Sender : TObject);
    procedure AddStack1Click(Sender : TObject);
    procedure Save1Click(Sender : TObject);
    procedure ChangeGraphicspath1Click(Sender : TObject);
    procedure Dirty1Click(Sender : TObject);
    procedure AddEdit1Click(Sender : TObject);
    procedure Load2Click(Sender : TObject);
    procedure Save2Click(Sender : TObject);
    procedure AddProgressbar1Click(Sender : TObject);
    procedure AddCheckbox1Click(Sender : TObject);
    procedure AnchorGridButtonClicked(Sender : TObject; Index : Integer);
    procedure TreeExpandSubBtnClick(Sender : TObject);
    procedure ClassesMemoChange(Sender : TObject);
    procedure ExtractGSS1Click(Sender : TObject);
    procedure ExtractdXML1Click(Sender : TObject);
    private
      { Private-Deklarationen }
      FGUI : TGUI;
    public
      { Public-Deklarationen }
      procedure PrintError(msg : string);
      procedure AddComponent(CompClass : CGUIClass);
  end;

  TGUIComponentHack = class(TGUIComponent)
  end;

  TGUIComponentHelper = class helper for TGUIComponent
    public
      procedure DrawSelection;
      function GetHovered(Position : RVector2) : TGUIComponent;
      function GetHoveredRecursive(Position : RVector2) : TGUIComponent;
      procedure RenderBorder;
      procedure RenderBorderRecursive;
  end;

  TGUITemplateHack = class(TGUIStyleSheet)

  end;

  TTreeViewHelper = class helper for TTreeView
    function FindByData(Ptr : Pointer) : TTreeNode;
  end;

  [XMLExcludeAll]
  TGUI = class(Engine.GUI.TGUI)
    protected
      LastShowed, Selected : TGUIComponent;
      MousePos : RIntVector2;
      MountedFile : string;
      procedure BuildTreeRecursive(TreeView : TTreeView; Node : TGUIComponent; TreeNode : TTreeNode);
      procedure SelectComponent(Selection : TGUIComponent);
      procedure AddComponent(AtElement, AddedElement : TGUIComponent);
      procedure UpdateStyles;
      function IsEditorOpen : Boolean;
    public
      Dirty : Boolean;
      LastLoadedGUIComponent : string;
      procedure LoadFromFile(filename : string);
      procedure ShowDebugForm();
      function DebugFormShowing : Boolean;
      procedure HideDebugForm;
      procedure UpdateTree;
      procedure MouseMove(Position : RIntVector2);
      procedure MouseUp(Button : EnumMouseButton);
      procedure HandleMouse(Mouse : TMouse);
      procedure SaveToFile(const filename : string);
      procedure Clear;
      procedure SetDirty;
      procedure Idle;
      procedure DebugSavedXML;
  end;

var
  GUIDebugForm : TGUIDebugForm;

implementation

{$R *.dfm}

{ TGUI }

procedure TGUI.AddComponent(AtElement, AddedElement : TGUIComponent);
begin
  AtElement.AddChild(AddedElement);
  GUIDebugForm.DomTree.Items.AddChild(GUIDebugForm.DomTree.Selected, AddedElement.name).Data := AddedElement;
  SelectComponent(AddedElement);
end;

procedure TGUI.BuildTreeRecursive(TreeView : TTreeView; Node : TGUIComponent; TreeNode : TTreeNode);
var
  child : TGUIComponent;
begin
  if not assigned(Node) then exit;
  TreeNode := TreeView.Items.AddChildObject(TreeNode, Format('%s (%s) #%s', [Node.ElementName, TGUIComponentHack(Node).ClassesAsText, Node.name]), Node);
  for child in (TGUIComponentHack(Node).FChildren) do
  begin
    BuildTreeRecursive(TreeView, child, TreeNode);
  end;
end;

procedure TGUI.Clear;
begin
  inherited;
  MountedFile := '';
  UpdateTree;
end;

procedure TGUI.LoadFromFile(filename : string);
begin
  inherited LoadFromFile(filename);
  MountedFile := filename;
  UpdateTree;
end;

function TGUI.DebugFormShowing : Boolean;
begin
  Result := assigned(GUIDebugForm) and GUIDebugForm.Showing;
end;

procedure TGUI.DebugSavedXML;
begin
  if assigned(FDocument) then FDocument.SaveXMLToFile(AbsolutePath('D:\rgl.xml'));
end;

procedure TGUI.SaveToFile(const filename : string);
begin
  inherited;
  MountedFile := filename;
end;

procedure TGUI.SelectComponent(Selection : TGUIComponent);
begin
  Selected := Selection;
  GUIDebugForm.DomTree.Select(GUIDebugForm.DomTree.FindByData(Selected));
end;

procedure TGUI.SetDirty;
begin
  TGUIComponentHack(DOMRoot).SetCompleteDirty;
  TGUIComponentHack(DynamicDOMRoot).SetCompleteDirty;
end;

procedure TGUI.ShowDebugForm;
begin
  if not assigned(GUIDebugForm) then
  begin
    GUIDebugForm := TGUIDebugForm.Create(Application);
    GUIDebugForm.FGUI := Self;
    Self.Erroroutput := GUIDebugForm.PrintError;
    UpdateTree;
  end;
  GUIDebugForm.Show;
  GUIDebugForm.PositionToolWindow;
end;

procedure TGUI.UpdateStyles;
begin
  LastShowed := nil;
end;

procedure TGUI.UpdateTree;
begin
  if not assigned(GUIDebugForm) then exit;
  GUIDebugForm.DomTree.Items.Clear;
  BuildTreeRecursive(GUIDebugForm.DomTree, DOMRoot, GUIDebugForm.DomTree.Items.GetFirstNode);
  GUIDebugForm.DomTree.FullExpand;
  SelectComponent(Selected);
  Dirty := False;
end;

procedure TGUI.HandleMouse(Mouse : TMouse);
var
  Button : EnumMouseButton;
begin
  MouseMove(Mouse.Position);
  for Button := low(EnumMouseButton) to high(EnumMouseButton) do
  begin
    if Mouse.ButtonDown(Button) then MouseDown(Button);
    if Mouse.ButtonUp(Button) then MouseUp(Button);
  end;
  MouseWheel(Mouse.dZ);
end;

procedure TGUI.HideDebugForm;
begin
  if assigned(GUIDebugForm) then GUIDebugForm.Hide;
  SelectComponent(nil);
end;

procedure TGUI.Idle;
var
  CurrentComponent : TGUIComponent;
begin
  inherited Idle;
  if not IsEditorOpen then exit;
  if Dirty then UpdateTree;
  if not GUIDebugForm.Showing then Selected := nil;
  if GUIDebugForm.Showing and GUIDebugForm.ShowElementborders1.Checked then DOMRoot.RenderBorderRecursive;
  if (Selected <> nil) then
  begin
    CurrentComponent := Selected;
    if GUIDebugForm.ShowElementborders1.Checked then Selected.DrawSelection;
  end
  else CurrentComponent := TGUIComponentHack(DOMRoot).FindContainingComponent(MousePos);
  if (CurrentComponent = nil) or (CurrentComponent = LastShowed) then exit;
  LastShowed := CurrentComponent;
  GUIDebugForm.TemplateBox.OnChange := nil;
  GUIDebugForm.TemplateBox.Clear;
  GUIDebugForm.TemplateBox.Lines.Text := TGUITemplateHack(TGUIComponentHack(CurrentComponent).FStyleSheet).DataAsText;
  GUIDebugForm.TemplateBox.OnChange := GUIDebugForm.TemplateBoxChange;
  GUIDebugForm.ClassesMemo.OnChange := nil;
  GUIDebugForm.ClassesMemo.Clear;
  GUIDebugForm.ClassesMemo.Lines.Text := TGUIComponentHack(CurrentComponent).ClassesAsText;
  GUIDebugForm.ClassesMemo.OnChange := GUIDebugForm.ClassesMemoChange;
  GUIDebugForm.ComputedStylesMemo.Clear;
  TGUIComponentHack(CurrentComponent).CheckAndBuildStyleSheetStack;
  GUIDebugForm.ComputedStylesMemo.Lines.Text := TGUIComponentHack(CurrentComponent).FStyleSheetStack.StyleSheetStack.ComputedStyles;

  GUIDebugForm.ComputedList.Strings.Clear;
  GUIDebugForm.ComputedList.InsertRow('position', Inttostr(round(TGUIComponentHack(CurrentComponent).FRect.Left)) + 'px ' + Inttostr(round(TGUIComponentHack(CurrentComponent).FRect.Top)) + 'px', True);
  GUIDebugForm.ComputedList.InsertRow('size', Inttostr(round(TGUIComponentHack(CurrentComponent).FRect.Width)) + 'px ' + Inttostr(round(TGUIComponentHack(CurrentComponent).FRect.Height)) + 'px', True);
  GUIDebugForm.ComputedList.InsertRow('name', TGUIComponentHack(CurrentComponent).FName, True);
  GUIDebugForm.ComputedList.InsertRow('type', TGUIComponentHack(CurrentComponent).ClassName, True);
  GUIDebugForm.ComputedList.InsertRow('zoffset', Inttostr(TGUIComponentHack(CurrentComponent).ZOffset), True);
end;

function TGUI.IsEditorOpen : Boolean;
begin
  Result := assigned(GUIDebugForm) and GUIDebugForm.Visible;
end;

procedure TGUI.MouseMove(Position : RIntVector2);
begin
  MousePos := Position;
  inherited MouseMove(Position);
end;

procedure TGUI.MouseUp(Button : EnumMouseButton);
var
  last : TGUIComponent;
begin
  MousePos := FLastMousePosition.round;
  if IsEditorOpen and (Button = mbLeft) then
  begin
    last := Selected;
    SelectComponent(TGUIComponentHack(DOMRoot).FindContainingComponent(MousePos));
    if last = Selected then Selected := nil;
  end
  else inherited MouseUp(Button);
end;

procedure TGUIDebugForm.AddCheckbox1Click(Sender : TObject);
begin
  AddComponent(TGUICheckbox);
end;

procedure TGUIDebugForm.AddComponent(CompClass : CGUIClass);
var
  Comp : TGUIComponent;
begin
  if CompClass = TGUIComponent then Comp := TGUIComponent.Create(FGUI, nil, CompClass.ClassName.Remove(0, 4))
  else if CompClass = TGUIStackPanel then Comp := TGUIStackPanel.Create(FGUI, nil, CompClass.ClassName.Remove(0, 4))
  else if CompClass = TGUIProgressBar then Comp := TGUIProgressBar.Create(FGUI, nil, CompClass.ClassName.Remove(0, 4))
  else if CompClass = TGUIEdit then Comp := TGUIEdit.Create(FGUI, nil, CompClass.ClassName.Remove(0, 4))
  else if CompClass = TGUICheckbox then Comp := TGUICheckbox.Create(FGUI, nil, CompClass.ClassName.Remove(0, 4))
  else
  begin
    assert(False);
    exit;
  end;
  FGUI.AddComponent(TGUIComponent(DomTree.Selected.Data), Comp);
end;

procedure TGUIDebugForm.AddComponent1Click(Sender : TObject);
begin
  AddComponent(TGUIComponent);
end;

procedure TGUIDebugForm.AddEdit1Click(Sender : TObject);
begin
  AddComponent(TGUIEdit);
end;

procedure TGUIDebugForm.AddProgressbar1Click(Sender : TObject);
begin
  AddComponent(TGUIProgressBar);
  FGUI.UpdateTree;
end;

procedure TGUIDebugForm.AddStack1Click(Sender : TObject);
begin
  AddComponent(TGUIStackPanel);
end;

procedure TGUIDebugForm.AnchorGridButtonClicked(Sender : TObject; Index : Integer);
type
  SetIndex = set of byte;
const
  GRID_SIZE = 5;
var
  Columns : array [1 .. GRID_SIZE] of SetIndex;
  Rows : array [1 .. GRID_SIZE] of SetIndex;
  i : Integer;
begin
  if not assigned(FGUI.Selected) then exit;
  FGUI.UpdateStyles;

  if index = 0 then
  begin
    FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caTopLeft);
    FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtPosition, [RGSSSpaceData.CreateAbsolute(0), RGSSSpaceData.CreateAbsolute(0)]);
    FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtSize, [RGSSSpaceData.CreateAbsolute(100), RGSSSpaceData.CreateAbsolute(100)]);
    exit;
  end;

  for i := 0 to GRID_SIZE - 1 do
  begin
    Columns[i + 1] := [i * GRID_SIZE, i * GRID_SIZE + 1, i * GRID_SIZE + 2, i * GRID_SIZE + 3, i * GRID_SIZE + 4];
    Rows[i + 1] := [i, i + GRID_SIZE, i + 2 * GRID_SIZE, i + 3 * GRID_SIZE, i + 4 * GRID_SIZE];
  end;
  if (index in Columns[2]) or (index in [21, 22, 23]) then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.CreateAbsolute(0));
  if index in Columns[3] then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.CreateRelative(0.5));
  if index in Columns[4] then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.CreateRelative(1));
  if (index in Rows[2]) or (index in [9, 14, 19]) then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.CreateAbsolute(0));
  if index in Rows[3] then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.CreateRelative(0.5));
  if index in Rows[4] then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.CreateRelative(1));

  if index in Columns[5] then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateRelative(1));
  if index in Rows[5] then FGUI.Selected.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateRelative(1));

  case index of
    6, 9, 21 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caTopLeft);
    7, 22 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caTop);
    8, 23 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caTopRight);
    11, 14 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caLeft);
    12 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caCenter);
    13 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caRight);
    16, 19 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caBottomLeft);
    17 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caBottom);
    18 : FGUI.Selected.ChangeStyle<EnumComponentAnchor>(gtAnchor, caBottomRight);
  end;
end;

procedure TGUIDebugForm.ChangeGraphicspath1Click(Sender : TObject);
var
  str : string;
begin
  str := FormatDateiPfad(FGUI.AssetPath);
  SelectDirectory('Please select the path to the graphics!', '', str);
  FGUI.AssetPath := RelativDateiPfad(str);
  FGUI.StyleManager.LoadStylesFromFolder(FGUI.AssetPath);
  TGUIComponentHack(FGUI.DOMRoot).SetCompleteDirty;
  HFileIO.WriteToIni(FormatDateiPfad('GUIEditorSettings.ini'), 'General', 'Graphicspath', FGUI.AssetPath);
end;

procedure TGUIDebugForm.ClassesMemoChange(Sender : TObject);
begin
  TGUIComponentHack(FGUI.LastShowed).ClassesAsText := ClassesMemo.Lines.Text;
  Dirty1.Click;
end;

procedure TGUIDebugForm.Delete1Click(Sender : TObject);
begin
  TGUIComponent(DomTree.Selected.Data).Delete;
  DomTree.Selected.Delete;
  FGUI.SelectComponent(nil);
end;

procedure TGUIDebugForm.Dirty1Click(Sender : TObject);
begin
  TGUIComponentHack(FGUI.DOMRoot).SetCompleteDirty;
  FGUI.UpdateTree;
end;

procedure TGUIDebugForm.DomTreeClick(Sender : TObject);
begin
  if DomTree.Selected <> nil then
  begin
    FGUI.SelectComponent(TGUIComponent(DomTree.Selected.Data));
  end;
end;

procedure TGUIDebugForm.DomTreeDragDrop(Sender, Source : TObject; X, Y : Integer);
var
  AnItem : TTreeNode;
  HT : THitTests;
begin
  if DomTree.Selected = nil then exit;
  HT := DomTree.GetHitTestInfoAt(X, Y);
  AnItem := DomTree.GetNodeAt(X, Y);
  if (HT - [htOnItem, htOnIcon, htNowhere, htOnIndent] <> HT) then
  begin
    TGUIComponentHack(DomTree.Selected.Data).MoveTo(TGUIComponent(AnItem.Data));
    FGUI.Dirty := True;
  end;
end;

procedure TGUIDebugForm.DomTreeDragOver(Sender, Source : TObject; X, Y : Integer;
  State : TDragState; var Accept : Boolean);
var
  AnItem : TTreeNode;
  HT : THitTests;
begin
  if DomTree.Selected = nil then exit;
  HT := DomTree.GetHitTestInfoAt(X, Y);
  AnItem := DomTree.GetNodeAt(X, Y);
  Accept := (Source = DomTree) and (AnItem <> nil);
end;

procedure TGUIDebugForm.DomTreeEdited(Sender : TObject; Node : TTreeNode; var S : string);
begin
  TGUIComponent(Node.Data).name := S;
end;

procedure TGUIDebugForm.DomTreeMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
var
  Item : TTreeNode;
begin
  Item := DomTree.GetNodeAt(X, Y);
  if assigned(Item) then FGUI.SelectComponent(TGUIComponent(Item.Data));
end;

procedure TGUIDebugForm.ExtractdXML1Click(Sender : TObject);
var
  dXML : string;
begin
  dXML := TGUIComponentHack(DomTree.Selected.Data).ExtractdXML();
  Clipboard.AsText := dXML;
end;

procedure TGUIDebugForm.ExtractGSS1Click(Sender : TObject);
var
  GSS : string;
begin
  GSS := TGUIComponentHack(DomTree.Selected.Data).ExtractGSS();
  Clipboard.AsText := GSS;
end;

procedure TGUIDebugForm.Load1Click(Sender : TObject);
begin
  if OpenDialog1.Execute then FGUI.LoadFromFile(OpenDialog1.filename);
end;

procedure TGUIDebugForm.Load2Click(Sender : TObject);
begin
  if FGUI.LastLoadedGUIComponent <> '' then
  begin
    OpenDialogComponent.InitialDir := ExtractFilePath(FGUI.LastLoadedGUIComponent);
    SetCurrentDirectory(PChar(OpenDialogComponent.InitialDir));
  end;
  if OpenDialogComponent.Execute then
  begin
    FGUI.LastLoadedGUIComponent := OpenDialogComponent.filename;
    TGUIComponent.CreateFromFile(OpenDialogComponent.filename, FGUI, TGUIComponent(DomTree.Selected.Data));
    FGUI.UpdateTree;
  end;
end;

procedure TGUIDebugForm.New1Click(Sender : TObject);
begin
  FGUI.Clear;
end;

procedure TGUIDebugForm.PrintError(msg : string);
begin
  ErrorBox.Lines.Text := msg;
end;

procedure TGUIDebugForm.Save1Click(Sender : TObject);
begin
  if FGUI.MountedFile = '' then
  begin
    if SaveDialog1.Execute then
    begin
      FGUI.MountedFile := SaveDialog1.filename;
      FGUI.SaveToFile(FGUI.MountedFile);
    end;
  end
  else FGUI.SaveToFile(FGUI.MountedFile);
end;

procedure TGUIDebugForm.Save2Click(Sender : TObject);
begin
  if FGUI.LastLoadedGUIComponent <> '' then
  begin
    SaveDialogComponent.filename := FGUI.LastLoadedGUIComponent;
    SaveDialogComponent.InitialDir := ExtractFilePath(FGUI.LastLoadedGUIComponent);
    SetCurrentDirectory(PChar(SaveDialogComponent.InitialDir));
  end;
  if SaveDialogComponent.Execute then
  begin
    TGUIComponent(DomTree.Selected.Data).SaveToFile(SaveDialogComponent.filename);
  end;
end;

procedure TGUIDebugForm.TemplateBoxChange(Sender : TObject);
begin
  ErrorBox.Clear;
  TGUIComponentHack(FGUI.LastShowed).FStyleSheet.Free;
  TGUIComponentHack(FGUI.LastShowed).FStyleSheet := TGUIStyleSheet.CreateFromText(TemplateBox.Lines.Text, FGUI);
  TGUIComponentHack(FGUI.LastShowed).SetDirty;
  TGUIComponentHack(FGUI.DOMRoot).ApplyStyleRecursive(FGUI.ScreenRect);
end;

procedure TGUIDebugForm.TreeExpandSubBtnClick(Sender : TObject);
  procedure TreeAction(StartItem : TTreeNode; Expand : Boolean);
  begin
    if not assigned(StartItem) then exit;
    if Expand then StartItem.Expand(True)
    else StartItem.Collapse(True);
  end;
  procedure RecursiveTreeExpand(StartItem : TTreeNode);
  begin
    if not assigned(StartItem) then exit;
    StartItem.Expand(False);
    RecursiveTreeExpand(StartItem.Parent);
  end;

begin
  if Sender = TreeExpandAllBtn then TreeAction(DomTree.Items.GetFirstNode, True)
  else
    if Sender = TreeExpandSubBtn then TreeAction(DomTree.FindByData(FGUI.Selected), True)
  else
    if Sender = TreeCollapseAllBtn then TreeAction(DomTree.Items.GetFirstNode, False)
  else
    if Sender = TreeCollapseSubBtn then
  begin
    TreeAction(DomTree.Items.GetFirstNode, False);
    RecursiveTreeExpand(DomTree.FindByData(FGUI.Selected));
    DomTree.Select(DomTree.FindByData(FGUI.Selected));
  end;
end;

procedure TGUIDebugForm.TreePopUpPopup(Sender : TObject);
begin

end;

{ TGUIComponentHelper }

procedure TGUIComponentHelper.DrawSelection;
begin
  RHWLinePool.AddRect(BackgroundRect.round, $FF008000);
  RHWLinePool.AddRect(OuterRect.round, RColor.CYELLOW);
  RHWLinePool.AddRect(ContentRect.round, $FF8080FF);

  RHWLinePool.AddDashedRect(OuterRect.Inflate(3).round, $40FFFF00, 10);
end;

function TGUIComponentHelper.GetHovered(Position : RVector2) : TGUIComponent;
begin
  Result := nil;
  if FRect.ContainsPoint(Position) then Result := Self;
end;

function TGUIComponentHelper.GetHoveredRecursive(Position : RVector2) : TGUIComponent;
var
  child, HoverChild : TGUIComponent;
begin
  if not Visible then exit(nil);
  for child in FChildren do
  begin
    HoverChild := child.GetHoveredRecursive(Position);
    if HoverChild <> nil then exit(HoverChild);
  end;
  Result := GetHovered(Position);
end;

procedure TGUIComponentHelper.RenderBorder;
begin
  RHWLinePool.AddRect(BackgroundRect.round, HGeneric.TertOp<cardinal>(FHovered, HGeneric.TertOp<cardinal>(FMouseDown[mbLeft], $FFFFFFFF, $FFFF0000), $FF008000));
end;

procedure TGUIComponentHelper.RenderBorderRecursive;
var
  child : TGUIComponent;
begin
  if not Visible then exit;
  RenderBorder;
  for child in FChildren do child.RenderBorderRecursive;
end;

{ TTreeViewHelper }

function TTreeViewHelper.FindByData(Ptr : Pointer) : TTreeNode;
  function FindByDataRecursive(Node : TTreeNode; Ptr : Pointer) : TTreeNode;
  var
    child : TTreeNode;
    i : Integer;
  begin
    Result := nil;
    if (Node = nil) or (Ptr = nil) then exit(nil);
    if Node.Data = Ptr then exit(Node);
    for i := 0 to Node.Count - 1 do
    begin
      child := Node.Item[i];
      Result := FindByDataRecursive(child, Ptr);
      if Result <> nil then exit;
    end;
  end;

begin
  Result := FindByDataRecursive(Items.GetFirstNode, Ptr);
end;

end.
