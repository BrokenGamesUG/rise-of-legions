unit Engine.PostEffects.Editor;

interface

uses
  // System
  Winapi.Windows,
  System.SysUtils,
  VCL.Forms,
  Math,
  // Engine
  Engine.Core,
  Engine.PostEffects,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.VCLUtils,
  Engine.Math,
  VCL.Dialogs,
  System.Classes,
  VCL.Menus,
  VCL.Controls,
  VCL.ExtCtrls,
  VCL.StdCtrls;

type

  TPostEffectManager = class;

  TPostEffectDebugForm = class(TForm)
    OpenDialog : TOpenDialog;
    SaveDialog : TSaveDialog;
    PostEffectList : TListBox;
    ListPopupMenu : TPopupMenu;
    ListAddList : TMenuItem;
    ListDeleteBtn : TMenuItem;
    ListMoveUpBtn : TMenuItem;
    ListMoveDownBtn : TMenuItem;
    MainMenu : TMainMenu;
    File1 : TMenuItem;
    NewBtn : TMenuItem;
    SaveBtn : TMenuItem;
    SaveAsBtn : TMenuItem;
    N1 : TMenuItem;
    CloseBtn : TMenuItem;
    LoadBtn : TMenuItem;
    ListRenameBtn : TMenuItem;
    PostEffectOptionPanel : TScrollBox;
    procedure BigChange(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure FormClose(Sender : TObject; var Action : TCloseAction);
    private
      { Private-Deklarationen }
      FPostEffectManager : TPostEffectManager;
      FPreventChanges : boolean;
      FEditedEffect : TBoundForm;
    public
      { Public-Deklarationen }
  end;

  TPostEffectManager = class(Engine.PostEffects.TPostEffectManager)
    protected
      procedure Init;
      function GetShowing : boolean;
    public
      constructor Create(Scene : TRenderManager);
      constructor CreateFromFile(Scene : TRenderManager; EffectsFile : string);
      procedure Clear;
      procedure LoadFromFile(EffectsFile : string);
      procedure ShowDebugForm;
      procedure HideDebugForm;
      property Showing : boolean read GetShowing;
  end;

var
  PostEffectDebugForm : TPostEffectDebugForm;
  MountedFile : string;

implementation

{$R *.dfm}


procedure TPostEffectDebugForm.FormClose(Sender : TObject; var Action : TCloseAction);
begin
  FreeAndNil(FEditedEffect);
end;

procedure TPostEffectDebugForm.FormShow(Sender : TObject);
begin
  Left := Screen.WorkAreaRect.Right - Width;
  Top := 0;
  Height := Screen.WorkAreaHeight;
end;

procedure TPostEffectDebugForm.BigChange(Sender : TObject);
  procedure GenerateForm;
  var
    PostEffect : TPostEffect;
  begin
    PostEffectOptionPanel.Visible := PostEffectList.HasSelection;
    if PostEffectList.HasSelection then
    begin
      PostEffect := FPostEffectManager.GetPostEffect(PostEffectList.SelectedItems[0]);
      assert(assigned(PostEffect));
      FEditedEffect.Free;
      FEditedEffect := TFormGenerator.GenerateForm(PostEffectOptionPanel, PostEffect.ClassInfo);
      FEditedEffect.BoundInstance := PostEffect;
    end;
  end;
  procedure SyncEffectList();
  var
    i : integer;
    lastIndex : string;
    effects : TArray<TPostEffect>;
  begin
    if PostEffectList.HasSelection then lastIndex := PostEffectList.SelectedItems[0]
    else lastIndex := '';

    PostEffectList.Clear;
    effects := FPostEffectManager.ToArray;
    for i := 0 to length(effects) - 1 do
    begin
      PostEffectList.Items.Add(effects[i].UID);
      if effects[i].UID = lastIndex then PostEffectList.Select(i);
    end;

    GenerateForm;
  end;

var
  UID : string;
  PostEffect, PostEffect2 : TPostEffect;
  index : integer;
begin
  if FPreventChanges or (FPostEffectManager = nil) then exit;
  if Sender = self then
  begin
    // sync all gui with data
    SyncEffectList();
  end;
  // Main-Menu -------------------------------------------------------------------------------------
  if Sender = NewBtn then
  begin
    MountedFile := '';
    FPostEffectManager.Clear;
  end;
  if (Sender = SaveBtn) and ((MountedFile <> '') or SaveDialog.Execute) then
  begin
    if (MountedFile = '') then MountedFile := SaveDialog.Filename;
    FPostEffectManager.SaveToFile(MountedFile);
  end;
  if Sender = SaveAsBtn then
  begin
    MountedFile := '';
    BigChange(SaveBtn);
  end;
  if (Sender = LoadBtn) and OpenDialog.Execute then
  begin
    MountedFile := OpenDialog.Filename;
    FPostEffectManager.LoadFromFile(OpenDialog.Filename);
  end;
  // List-Actions ----------------------------------------------------------------------------------
  if Sender = PostEffectList then GenerateForm;

  if (TComponent(Sender).GetParentComponent = ListAddList) then
  begin
    UID := AvailablePostEffects[TComponent(Sender).Tag].ClassName.Replace('TPostEffect', '');
    if FPostEffectManager.Contains(UID) then InputQuery('UID Conflict', 'Please specify the unique identifier of the post effect!', UID);
    if FPostEffectManager.Contains(UID) then ShowMessage('This identifier is already in use!')
    else
    begin
      PostEffect := AvailablePostEffects[TComponent(Sender).Tag].Create();
      PostEffect.RenderOrder := PostEffectList.Items.Count;
      FPostEffectManager.Add(UID, PostEffect);
      SyncEffectList;
    end;
  end;
  if (TComponent(Sender).GetParentComponent = ListPopupMenu) then
  begin
    index := PostEffectList.ItemIndex;
    if index >= 0 then
    begin
      if Sender = ListDeleteBtn then FPostEffectManager.Delete(PostEffectList.Items[index]);
      if (Sender = ListRenameBtn) and InputQuery('Rename UID', 'Please specify the unique identifier of the post effect!', UID) then
      begin
        if FPostEffectManager.Contains(UID) then ShowMessage('This identifier is already in use!')
        else
        begin
          PostEffect := FPostEffectManager.Extract(PostEffectList.SelectedItems[0]);
          FPostEffectManager.Add(UID, PostEffect);
        end;
      end;
      if (Sender = ListMoveUpBtn) and (index > 0) and
        FPostEffectManager.TryGetPostEffect(PostEffectList.Items[index], PostEffect) and
        FPostEffectManager.TryGetPostEffect(PostEffectList.Items[index - 1], PostEffect2) then
          HGeneric.Swap<integer>(PostEffect.RenderOrder, PostEffect2.RenderOrder);
      if (Sender = ListMoveDownBtn) and (index < PostEffectList.Items.Count - 1) and
        FPostEffectManager.TryGetPostEffect(PostEffectList.Items[index], PostEffect) and
        FPostEffectManager.TryGetPostEffect(PostEffectList.Items[index + 1], PostEffect2) then
          HGeneric.Swap<integer>(PostEffect.RenderOrder, PostEffect2.RenderOrder);
    end;
    SyncEffectList;
  end;
end;

{ TPostEffectManager }

procedure TPostEffectManager.ShowDebugForm;
var
  i : integer;
  item : TMenuItem;
begin
  if not assigned(PostEffectDebugForm) then
  begin
    PostEffectDebugForm := TPostEffectDebugForm.Create(Application);
    PostEffectDebugForm.Top := 25;
    PostEffectDebugForm.Height := Screen.WorkAreaHeight - 25;
    PostEffectDebugForm.Left := Screen.WorkAreaWidth - PostEffectDebugForm.Width;
    PostEffectDebugForm.OpenDialog.InitialDir := HFilePathManager.AbsoluteWorkingPath;
    PostEffectDebugForm.SaveDialog.InitialDir := HFilePathManager.AbsoluteWorkingPath;
    PostEffectDebugForm.ListAddList.Clear;
    // init popup create list
    for i := 0 to length(AvailablePostEffects) - 1 do
    begin
      item := TMenuItem.Create(PostEffectDebugForm.ListAddList);
      item.Caption := AvailablePostEffects[i].ClassName.Replace('TPostEffect', '');
      item.OnClick := PostEffectDebugForm.BigChange;
      item.Tag := i;
      PostEffectDebugForm.ListAddList.Add(item);
    end;
  end;
  PostEffectDebugForm.FPostEffectManager := self;
  PostEffectDebugForm.BigChange(PostEffectDebugForm);
  PostEffectDebugForm.Show;
end;

procedure TPostEffectManager.HideDebugForm;
begin
  if assigned(PostEffectDebugForm) then PostEffectDebugForm.Hide;
end;

procedure TPostEffectManager.Clear;
begin
  inherited;
  Init;
end;

constructor TPostEffectManager.Create(Scene : TRenderManager);
begin
  inherited Create(Scene);
  Init;
end;

constructor TPostEffectManager.CreateFromFile(Scene : TRenderManager; EffectsFile : string);
begin
  inherited CreateFromFile(Scene, EffectsFile);
  Init;
end;

function TPostEffectManager.GetShowing : boolean;
begin
  Result := assigned(PostEffectDebugForm) and PostEffectDebugForm.Visible;
end;

procedure TPostEffectManager.Init;
begin
  if assigned(PostEffectDebugForm) then PostEffectDebugForm.Hide;
end;

procedure TPostEffectManager.LoadFromFile(EffectsFile : string);
begin
  inherited;
  MountedFile := AbsolutePath(EffectsFile);
  Init;
end;

end.
