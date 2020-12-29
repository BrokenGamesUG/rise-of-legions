unit BaseConflict.DebugForm;

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
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Engine.Core,
  Engine.Helferlein,
  Engine.Math;

type
  TForm2 = class(TForm)
    OutputMemo : TMemo;
    OutputLabel : TLabel;
    DebugTrack : TTrackBar;
    DebugValueEdit : TEdit;
    PrintBtn : TButton;
    ValueMinEdit : TEdit;
    ValueMaxEdit : TEdit;
    procedure FormCreate(Sender : TObject);
    procedure ValueMinEditChange(Sender : TObject);
    procedure DebugTrackChange(Sender : TObject);
    private
      FMini, FMaxi, FTrackValue, FRealValue : single;
      { Private-Deklarationen }
    public
      { Public-Deklarationen }

      procedure RefreshSpan;
      procedure RefreshValue;
      procedure ApplyValue;
  end;

var
  Form2 : TForm2;

implementation

{$R *.dfm}


function f(float : single) : string;
begin
  Result := FloatToStrF(float, ffGeneral, 4, 4, EngineFloatFormatSettings);
end;

procedure TForm2.ApplyValue;
begin
  GFXD.Rendermanager.Shadowmapping.Shadowbias := FRealValue;
end;

procedure TForm2.DebugTrackChange(Sender : TObject);
begin
  FTrackValue := DebugTrack.Position / DebugTrack.Max;
  RefreshValue;
end;

procedure TForm2.FormCreate(Sender : TObject);
begin
  assert(assigned(GFXD));
  OutputLabel.Caption := f(GFXD.Camera.Position.Distance(GFXD.Camera.Target));
  DebugValueEdit.Text := f(GFXD.Rendermanager.Shadowmapping.Shadowbias);
end;

procedure TForm2.RefreshSpan;
var
  mini, maxi : single;
begin
  if TryStrToFloat(ValueMinEdit.Text, mini, EngineFloatFormatSettings) and TryStrToFloat(ValueMaxEdit.Text, maxi, EngineFloatFormatSettings) then
  begin
    FMini := mini;
    FMaxi := maxi;
  end;
end;

procedure TForm2.RefreshValue;
begin
  FRealValue := FTrackValue * (FMaxi - FMini) + FMini;
  DebugValueEdit.Text := f(FRealValue);
  ApplyValue;
end;

procedure TForm2.ValueMinEditChange(Sender : TObject);
begin
  RefreshSpan;
  RefreshValue;
end;

end.
