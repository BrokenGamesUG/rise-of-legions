unit Baseconflict.Tools.ScriptTest;

interface

uses
  Baseconflict.Tools.Main,
  // Delphi
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Log,
  Engine.Script;

type
  TScriptTestCommand = class(TCommand)
    public
      procedure Execute; override;
      constructor Create();
  end;

implementation

{ TScriptTestCommand }

constructor TScriptTestCommand.Create;
begin
  inherited Create('ScriptTest', 'scripttest', 'Compile any script within Baseconflict/Script to check for syntax errors.');
  ScriptManager.UnitSearchPath := AbsolutePath('\..\Scripts\HelperScripts\');
end;

procedure TScriptTestCommand.Execute;
var
  ScriptFiles, Errors : TStrings;
  ScriptFileName, ShortFileName : string;
  ScriptPath, Error, Define : string;
  Script : TScript;
  ErrorCount, i : integer;
  Failed : boolean;
begin
  ScriptPath := AbsolutePath('\..\Scripts\');
  WriteLn(Format('Syntaxcheck all files under "%s" ', [ScriptPath]));
  HFileIO.FindAllFiles(ScriptFiles, ScriptPath);
  Errors := TStringList.Create;
  i := 0;
  for ScriptFileName in ScriptFiles do
  begin
    inc(i);
    ShortFileName := ExtractFileName(ScriptFileName);
    write(Format('%s/%d Checking...%s',
      [HString.IntMitNull(i, Length(ScriptFiles.Count.ToString)),
      ScriptFiles.Count, ShortFileName]));
    Failed := False;
    for Define in HArray.Create(['SERVER', 'CLIENT']) do
    begin
      ErrorCount := Errors.Count;
      ScriptManager.ClearCache;
      ScriptManager.Defines.Clear;
      ScriptManager.Defines.Add(Define);
      try
        Script := ScriptManager.CompileScriptFromFile(ScriptFileName, Errors);
        Script.Free;
        if ErrorCount < Errors.Count then
        begin
          Errors[Errors.Count - 1] := ShortFileName + Format(' [%s]', [Define]) + ' - ' + Errors[Errors.Count - 1];
          Failed := True;
        end;
      except
        on e : Exception do
            Errors.Add(ShortFileName + ' - ' + e.ToString);
      end;
    end;
    if Failed then
        WriteLn('...FAILED')
    else
        WriteLn('...OK');
  end;
  WriteLn;
  WriteLn('===========');
  WriteLn('Check Done');
  if Errors.Count > 0 then
  begin
    WriteLn(Errors.Count, ' errors found');
    for Error in Errors do
        WriteLn(Error);
  end;
end;

end.
