unit Engine.Navigation;

interface

uses
  Classes,
  System.SysUtils,
  Engine.Math,
  Engine.Helferlein,
  Engine.Collision,
  System.Generics.Collections;

type

  TPathPlanner = class
    protected

    public
  end;

  RPathNode = record
    public
      FPosition : RVector3;
      FTag : TObject;

      constructor Create(pos : RVector3);
  end;

  TPath = class
    protected
      FNodes : TList<RPathNode>;

      function GetStart : RPathNode;
      function GetNodeCount : Integer;

    public

      constructor Create();
      destructor Destroy(); override;

      property Nodes : TList<RPathNode> read FNodes;
      property NumNodes : Integer read GetNodeCount;

      function GetEnumerator : TEnumerator<RPathNode>;

  end;

  TPathEnumerator = class(TEnumerator<RPathNode>)
    private
      FPath : TPath;
      FIndex : Integer;

    public
      constructor Create(path : TPath);

      property NodeIndex : Integer read FIndex;

      function DoGetCurrent : RPathNode; override;
      function DoMoveNext : Boolean; override;
  end;

  TPotentialField = class

  end;

implementation


{ RPathNode }

constructor RPathNode.Create(pos : RVector3);
begin
  FPosition := pos;
end;

{ TPath }

constructor TPath.Create;
begin
  FNodes := TList<RPathNode>.Create();
end;

destructor TPath.Destroy;
begin
  FNodes.Free;
  inherited;
end;

function TPath.GetEnumerator: TEnumerator<RPathNode>;
begin
  Result := TPathEnumerator.Create(Self);
end;

function TPath.GetNodeCount: Integer;
begin
  Result := FNodes.Count;
end;

function TPath.GetStart: RPathNode;
begin
  if FNodes.Count > 0 then
    Result := FNodes[0]
  else
    raise Exception.Create('Path is empty');
end;

{ TPathEnumerator }

constructor TPathEnumerator.Create(path: TPath);
begin
  FPath := path;
  FIndex := -1;
  Inherited Create();
end;

function TPathEnumerator.DoGetCurrent: RPathNode;
begin
  Result := FPath.Nodes[FIndex];
end;

function TPathEnumerator.DoMoveNext: Boolean;
begin
  if FIndex >= FPath.NumNodes then
    Result := False
  else
  begin
    Inc(FIndex);
    Result := True;
  end;
end;

end.
