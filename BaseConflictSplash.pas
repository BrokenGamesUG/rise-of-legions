unit BaseConflictSplash;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Types,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Engine.Helferlein.Windows,
  Vcl.Imaging.pngimage;

type
  TSplashForm = class(TForm)
    private
      { Private-Deklarationen }
    protected
      procedure WMNCHitTest(var Message : TWMNCHitTest); message WM_NCHITTEST;
    public
      procedure Execute;
  end;

var
  SplashForm : TSplashForm;

implementation

{$R *.dfm}

{ TSplashForm }

procedure TSplashForm.Execute;
var
  BlendFunction : TBlendFunction;
  BitmapPos : TPoint;
  BitmapSize : TSize;
  exStyle : DWORD;
  Png : TPngImage;
  Bitmap : TBitmap;
begin
//  // if file is not present skip this form
//  if not HFilepathManager.FileExists('Splash.png') then
//  begin
//    Hide;
//    exit;
//  end;
  // Enable window layering
  exStyle := GetWindowLongA(Handle, GWL_EXSTYLE);
  if (exStyle and WS_EX_LAYERED = 0) then
      SetWindowLong(Handle, GWL_EXSTYLE, exStyle or WS_EX_LAYERED);

  Bitmap := TBitmap.Create;
  Png := TPngImage.Create;
  try
    try
      Png.LoadFromResourceName(HInstance, 'Splash.png');
      Bitmap.Assign(Png);

      // Resize form to fit bitmap
      ClientWidth := Bitmap.Width;
      ClientHeight := Bitmap.Height;

      // Position bitmap on form
      BitmapPos := Point(0, 0);
      BitmapSize.cx := Bitmap.Width;
      BitmapSize.cy := Bitmap.Height;

      // Setup alpha blending parameters
      BlendFunction.BlendOp := AC_SRC_OVER;
      BlendFunction.BlendFlags := 0;
      BlendFunction.SourceConstantAlpha := 255;
      BlendFunction.AlphaFormat := AC_SRC_ALPHA;

      // ... and action!
      UpdateLayeredWindow(Handle, 0, nil, @BitmapSize, Bitmap.Canvas.Handle,
        @BitmapPos, 0, @BlendFunction, ULW_ALPHA);

      Show;
    except
      Hide;
    end;
  finally
    Png.Free;
    Bitmap.Free;
  end;
end;

procedure TSplashForm.WMNCHitTest(var Message : TWMNCHitTest);
begin
  message.Result := HTCAPTION;
end;

end.
