unit LightManagerFormUnit;

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
  BaseConflict.Map.Client,
  RTTI,
  Engine.Helferlein.VCLUtils;

type
  TLightManagerForm = class(TForm)
    procedure FormDestroy(Sender: TObject);
    private
      { Private-Deklarationen }
      FLightManager : TLightManager;
      FBoundForm : TBoundForm;
      procedure OnChange(Sender : string; NewValue : TValue);
    public
      { Public-Deklarationen }
      procedure ShowEditor(LightManager : TLightManager);
      procedure HideEditor;
  end;

var
  LightManagerForm : TLightManagerForm;

implementation

{$R *.dfm}

{ TLightManagerForm }

procedure TLightManagerForm.FormDestroy(Sender: TObject);
begin
  FBoundForm.Free;
end;

procedure TLightManagerForm.HideEditor;
begin
  FLightManager := nil;
  Hide;
end;

procedure TLightManagerForm.OnChange(Sender : string; NewValue : TValue);
begin
  FLightManager.SynchronizeLightWithGFXD;
end;

procedure TLightManagerForm.ShowEditor(LightManager : TLightManager);
begin
  Show;
  FLightManager := LightManager;
  FBoundForm.Free;
  FBoundForm := TFormGenerator.GenerateForm(self, TLightManager);
  FBoundForm.OnChange := OnChange;
  FBoundForm.BoundInstance := FLightManager;
end;

end.
