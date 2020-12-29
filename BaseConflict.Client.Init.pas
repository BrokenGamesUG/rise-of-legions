unit BaseConflict.Client.Init;

interface

uses
  Engine.Helferlein.Windows;

implementation

initialization

HFilepathManager.ForEachFile('\Graphics\Fonts\',
  procedure(const Filename : string)
  begin
    HSystem.RegisterFontFromFile(Filename);
  end, '*.ttf');

end.
