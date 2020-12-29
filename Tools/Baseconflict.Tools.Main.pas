unit Baseconflict.Tools.Main;

interface

uses
  // Delphi
  System.Generics.Collections,
  System.SysUtils,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Log;

type
  TCommand = class
    private
      FCommand : string;
      FDescription : string;
    protected
      FName : string;
    public
      property name : string read FName;
      property Description : string read FDescription;
      property Command : string read FCommand;
      procedure Execute; virtual; abstract;
      constructor Create(const Name, Command, Description : string);
      destructor Destroy; override;
  end;

  TCommandManager = class
    private
      FCommands : TObjectList<TCommand>;
    public
      procedure AddCommand(Command : TCommand);
      procedure PrintOverview;
      procedure ExecuteCommand(Selection : Integer); overload;
      procedure ExecuteCommand(Command : string); overload;
      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TCommand }

constructor TCommand.Create(const Name, Command, Description : string);
begin
  FName := name;
  FCommand := Command.ToLowerInvariant;
  FDescription := Description;
end;

destructor TCommand.Destroy;
begin
  inherited;
end;

{ TCommandManager }

procedure TCommandManager.AddCommand(Command : TCommand);
begin
  FCommands.Add(Command)
end;

constructor TCommandManager.Create;
begin
  FCommands := TObjectList<TCommand>.Create;
end;

destructor TCommandManager.Destroy;
begin
  FCommands.Free;
  inherited;
end;

procedure TCommandManager.ExecuteCommand(Command: string);
var CommandInstance : TCommand;
begin
  for CommandInstance in FCommands do
  begin
    if SameText(CommandInstance.Command, Command) then
      CommandInstance.Execute;
  end;
end;

procedure TCommandManager.ExecuteCommand(Selection : Integer);
var
  Command : TCommand;
begin
  Command := FCommands[Selection - 1];
  WriteLn(Command.Name);
  WriteLn('================');
  WriteLn;
  Command.Execute;
end;

procedure TCommandManager.PrintOverview;
var
  i : Integer;
begin
  HLog.ClearConsole;
  for i := 0 to FCommands.Count - 1 do
  begin
    WriteLn(Format('%d: %s', [i + 1, FCommands[i].Name]));
  end;
end;

end.
