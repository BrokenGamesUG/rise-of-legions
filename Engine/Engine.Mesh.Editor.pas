unit Engine.Mesh.Editor;

interface

uses
  // System
  Winapi.Windows,
  System.SysUtils,
  VCL.Forms,
  Math,
  // Engine
  Engine.Core,
  Engine.Mesh,
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

  TMesh = class;

  TMeshEditorForm = class(TForm)
    SaveDialog : TSaveDialog;
    MainMenu : TMainMenu;
    File1 : TMenuItem;
    SaveBtn : TMenuItem;
    SaveAsBtn : TMenuItem;
    N1 : TMenuItem;
    CloseBtn : TMenuItem;
    MeshBox : TScrollBox;
    MeshPanel : TPanel;
    procedure BigChange(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure FormClose(Sender : TObject; var Action : TCloseAction);
    private
      { Private-Deklarationen }
      FMesh : TMesh;
      FPreventChanges : boolean;
      FEditedMesh : TBoundForm;
    public
      { Public-Deklarationen }
  end;

  TMesh = class(Engine.Mesh.TMesh)
    protected
      procedure Init;
      function GetShowing : boolean;
    public
      constructor CreateFromFile(Scene : TRenderManager; const Filepath : string);
      procedure ShowEditorForm;
      procedure HideEditorForm;
      property Showing : boolean read GetShowing;
      destructor Destroy; override;
  end;

var
  MeshEditorForm : TMeshEditorForm;
  MountedFile : string;

implementation

{$R *.dfm}


procedure TMeshEditorForm.FormClose(Sender : TObject; var Action : TCloseAction);
begin
  FreeAndNil(FEditedMesh);
end;

procedure TMeshEditorForm.FormShow(Sender : TObject);
begin
  Left := Screen.WorkAreaRect.Right - Width;
  Top := 0;
  Height := Screen.WorkAreaHeight;
end;

procedure TMeshEditorForm.BigChange(Sender : TObject);
  procedure GenerateForm;
  begin
    assert(assigned(FMesh));
    FEditedMesh.Free;
    FEditedMesh := TFormGenerator.GenerateForm(MeshPanel, FMesh.ClassInfo);
    FEditedMesh.BoundInstance := FMesh;
  end;

begin
  if FPreventChanges or (FMesh = nil) then exit;
  if Sender = self then
  begin
    // sync all gui with data
    GenerateForm;
  end;
  // Main-Menu -------------------------------------------------------------------------------------
  if (Sender = SaveBtn) and ((MountedFile <> '') or SaveDialog.Execute) then
  begin
    if (MountedFile = '') then MountedFile := SaveDialog.FileName;
    FMesh.SaveToFile(MountedFile);
  end;
  if Sender = SaveAsBtn then
  begin
    MountedFile := '';
    BigChange(SaveBtn);
  end;
  if (Sender = CloseBtn) and assigned(MeshEditorForm) then MeshEditorForm.Hide;
end;

{ TMesh }

procedure TMesh.ShowEditorForm;
begin
  if not assigned(MeshEditorForm) then
  begin
    MeshEditorForm := TMeshEditorForm.Create(Application);
    MeshEditorForm.Top := 25;
    MeshEditorForm.Height := Screen.WorkAreaHeight - 25;
    MeshEditorForm.Left := Screen.WorkAreaWidth - MeshEditorForm.Width;
    if MountedFile <> '' then MeshEditorForm.SaveDialog.InitialDir := MountedFile
    else MeshEditorForm.SaveDialog.InitialDir := HFilePathManager.AbsoluteWorkingPath;
  end;
  MeshEditorForm.FMesh := self;
  MountedFile := self.FFilePath;
  MeshEditorForm.Show;
  MeshEditorForm.BigChange(MeshEditorForm);
end;

procedure TMesh.HideEditorForm;
begin
  if assigned(MeshEditorForm) then MeshEditorForm.Hide;
end;

constructor TMesh.CreateFromFile(Scene : TRenderManager; const Filepath : string);
begin
  inherited CreateFromFile(Scene, Filepath);
  Init;
end;

destructor TMesh.Destroy;
begin
  HideEditorForm;
  inherited;
end;

function TMesh.GetShowing : boolean;
begin
  Result := assigned(MeshEditorForm) and MeshEditorForm.Visible;
end;

procedure TMesh.Init;
begin
  if assigned(MeshEditorForm) then MeshEditorForm.Hide;
end;

end.
