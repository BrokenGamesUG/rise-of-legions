unit BaseConflict.Classes.MiniMap;

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  Generics.Defaults,

  Engine.Math,
  Engine.Core,
  Engine.Core.Types,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.GUI,
  Engine.Vertex,
  Engine.GfxApi,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,

  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Entity,
  BaseConflict.Settings.Client;

type
  RMiniMapEntry = record
    Entity : TEntity;
    IconPath : string;
    IconSize : single;
    DynamicPath : boolean;
    constructor Create(Entity : TEntity; IconSize : single; IconPath : string = '');
  end;

  TMiniMapEntryComparer = class(TEqualityComparer<RMiniMapEntry>)
    function Equals(const Left, Right : RMiniMapEntry) : boolean; override;
    function GetHashCode(const Value : RMiniMapEntry) : Integer; override;
  end;

  TMiniMapPing = class
    Position : RVector2;
    IconPath : string;
    IconSize : single;
    PingStart, PingDuration : int64;
    Quad : TVertexScreenAlignedQuad;
    destructor Destroy; override;
  end;

  TMiniMap = class
    private const
      MINIMAP_PADDING           = 38.0;
      MINIMAP_OFFSET : RVector2 = (X : 3.0; Y : - 1.0);
    protected
      FInitialized, FSingle : boolean;
      FEntries : TObjectDictionary<RMiniMapEntry, TVertexScreenAlignedQuad>;
      FPings : TObjectList<TMiniMapPing>;
      FPingOrder : Integer;
      FWorldBounds : RRectFloat;
      FGuiBounds : RRectFloat;
      FBorderQuads : TObjectList<TVertexScreenAlignedQuad>;
      FIconTextures : TObjectDictionary<string, TTexture>;
      FCurrentColorOverride : RColor;

      // transforms world position into minimap position
      function WorldToMiniMap(const WorldPos : RVector3; Transform : boolean = True; IgnoreBounds : boolean = False) : RVector2;

      function ComputeMiniMapBounds() : RRectFloat;
      function GetMapWorldBounds() : RRectFloat;

      function PingSize(s : single) : single;

      function SizeToMinimapSize(const Size : single) : RVector2;
      function CreateQuad(const Position : RVector2; Size : single) : TVertexScreenAlignedQuad; overload;
      function CreateQuad(const Entry : RMiniMapEntry; const Position : RVector2) : TVertexScreenAlignedQuad; overload;
      function GetIconTexture(Path : string) : TTexture;

      procedure Init;
      function TryGetComponent(out MinimapComponent : TGUIComponent) : boolean;
      procedure IdlePings;
      procedure IdleMinimapEntries;
      procedure IdleViewQuad;
    public
      constructor Create;

      procedure RecalculateSize();
      procedure IsSingleMap;

      procedure Add(Entry : RMiniMapEntry);
      procedure Remove(Entity : TEntity);

      procedure Ping(const Position : RVector2; const IconPath : string; IconSize : single; Duration : Integer);

      function MiniMapToWorld(screenPos : RIntVector2) : RVector2;

      /// <summary>Checks whether the position is within the bounds of the
      /// minimap GUI element.</summary>
      function IsWithinGuiBounds(screenPos : RIntVector2) : boolean;

      procedure Idle;

      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals.Client;

{ TMiniMap }

function TMiniMap.ComputeMiniMapBounds : RRectFloat;
var
  X, Y, Width, Height : single;
  GUIComponent : TGUIComponent;
begin
  if TryGetComponent(GUIComponent) then
  begin
    X := GUIComponent.screenPos.X * GFXD.Settings.Resolution.Width;
    Y := GUIComponent.screenPos.Y * GFXD.Settings.Resolution.Height;
    Width := GUIComponent.ScreenSize.X * GFXD.Settings.Resolution.Width;
    Height := GUIComponent.ScreenSize.Y * GFXD.Settings.Resolution.Height;

    Result := RRectFloat.CreateWidthHeight(X, Y, Width, Height);
    Result := Result.Inflate(-MINIMAP_PADDING);
    Result := Result.Translate(MINIMAP_OFFSET);
  end
  else
      Result := RRectFloat.CreateWidthHeight(0, 0, 300, 300);
end;

constructor TMiniMap.Create;
begin
  FEntries := TObjectDictionary<RMiniMapEntry, TVertexScreenAlignedQuad>.Create([doOwnsValues], TMiniMapEntryComparer.Create);
  FIconTextures := TObjectDictionary<string, TTexture>.Create([doOwnsValues]);
  FBorderQuads := TObjectList<TVertexScreenAlignedQuad>.Create();
  FPings := TObjectList<TMiniMapPing>.Create;
  Init;
end;

function TMiniMap.CreateQuad(const Position : RVector2; Size : single) : TVertexScreenAlignedQuad;
begin
  Result := TVertexScreenAlignedQuad.Create(VertexEngine, Position, SizeToMinimapSize(Size), nil, 1000);
  Result.DrawsAtStage := rsGUI;
  Result.DrawOrder := 1000 - round(Size * 10);
  Result.Anchor := RVector2.Create(0.5, 0.5);
end;

function TMiniMap.CreateQuad(const Entry : RMiniMapEntry; const Position : RVector2) : TVertexScreenAlignedQuad;
begin
  Result := CreateQuad(Position, Entry.IconSize);
  Result.Color := TEAMCOLORS[Entry.Entity.TeamID];
end;

destructor TMiniMap.Destroy;
begin
  FPings.Free;
  FBorderQuads.Free;
  FEntries.Free;
  FIconTextures.Free;

  inherited;
end;

function TMiniMap.TryGetComponent(out MinimapComponent : TGUIComponent) : boolean;
begin
  Result := GUI.FindUnique(HUD_MINIMAP, MinimapComponent);
end;

function TMiniMap.GetMapWorldBounds : RRectFloat;
begin
  if assigned(ClientGame) then Result := ClientGame.Map.MapBoundaries
  else
  begin
    Result.Left := -1;
    Result.Top := -1;
    Result.Bottom := -1;
    Result.Right := -1;
  end;
end;

function TMiniMap.GetIconTexture(Path : string) : TTexture;
begin
  Path := AbsolutePath(Path);
  if not FIconTextures.TryGetValue(Path, Result) then
  begin
    Result := TTexture.CreateTextureFromFile(Path, GFXD.Device3D, mhGenerate, True);
    FIconTextures.Add(Path, Result);
  end;
end;

procedure TMiniMap.Idle;
var
  GUIComponent : TGUIComponent;
begin
  if not FInitialized then Init;
  if not FInitialized or not HUD.IsHUDVisible or not TryGetComponent(GUIComponent) or not GUIComponent.IsVisible then exit;
  RecalculateSize();

  if HUD.IsTutorial and GUI.FindUnique('ui').HasClass('disabled') then
      FCurrentColorOverride := $E0080D0D
  else
      FCurrentColorOverride := 0;

  IdleViewQuad;
  IdleMinimapEntries;
  IdlePings;
end;

procedure TMiniMap.IdleMinimapEntries;
var
  Entry : TPair<RMiniMapEntry, TVertexScreenAlignedQuad>;
  Path : string;
  Entity : TEntity;
  TeamID : Integer;
begin
  // update and draw the quads for the entities on the map
  for Entry in FEntries do
  begin
    Entry.Value.Position := WorldToMiniMap(Entry.Key.Entity.DisplayPosition);

    if (Entry.Key.IconPath = '') and (FIconTextures <> nil) then
    begin
      Entry.Value.Color := GetTeamColor(Entry.Key.Entity.TeamID);
      Entry.Value.Texture := nil;
    end
    else
    begin
      Entity := Entry.Key.Entity;

      if Entity.Eventbus.Read(eiExiled, []).AsBoolean then continue;

      if not assigned(Entry.Value.Texture) or Entry.Key.DynamicPath then
      begin
        Path := Entry.Key.IconPath;
        if Entry.Key.DynamicPath then Path := Format(Path, [GetDisplayedTeam(Entry.Key.Entity.TeamID)]);
        Entry.Value.Texture := GetIconTexture(Path);
      end;

      if Entry.Key.DynamicPath then Entry.Value.Color := RColor.CWHITE
      else
      begin
        TeamID := Entity.TeamID;
        Entry.Value.Color := GetTeamColor(TeamID);
      end;
    end;

    Entry.Value.ColorOverride := FCurrentColorOverride;
    Entry.Value.AddRenderJob;
  end;
end;

procedure TMiniMap.IdlePings;
var
  i : Integer;
  Ping : TMiniMapPing;
begin
  if FPings.Count <= 0 then
      FPingOrder := 0;
  for i := FPings.Count - 1 downto 0 do
  begin
    Ping := FPings[i];
    if (Ping.PingStart + Ping.PingDuration) <= TimeManager.GetTimeStamp then
    begin
      FPings.Delete(i);
    end
    else
    begin
      Ping.Quad.Position := WorldToMiniMap(Ping.Position.X0Y);

      if (Ping.IconPath <> '') or not assigned(FIconTextures) then
      begin
        if not assigned(Ping.Quad.Texture) then
            Ping.Quad.Texture := GetIconTexture(Ping.IconPath);

        Ping.Quad.Size := SizeToMinimapSize(Ping.IconSize * PingSize((TimeManager.GetTimeStamp - Ping.PingStart) / Ping.PingDuration));
        Ping.Quad.ColorOverride := FCurrentColorOverride;
        Ping.Quad.AddRenderJob;
      end;
    end;
  end;
end;

procedure TMiniMap.IdleViewQuad;
var
  Corners : array [0 .. 3] of RVector2;
  i, j : Integer;
  LineCenter, Line : RVector2;
  Length : single;
begin
  if not HUD.CaptureMode then
  begin
    // compute frustrum corners in minimap coordinates
    for i := 0 to 3 do
        Corners[i] := WorldToMiniMap(RPlane.XZ.IntersectRay(GFXD.MainScene.Camera.ViewingFrustum.Rays[i]), True, True);

    // draw lines between the corners
    for i := 0 to 3 do
    begin
      j := (i + 1) mod 4;
      Line := Corners[j] - Corners[i];
      Length := Line.Length;
      LineCenter := Corners[i] + (Corners[j] - Corners[i]) * 0.5;

      FBorderQuads[i].Position := LineCenter;

      if Abs(Line.X) > Abs(Line.Y) then
      begin
        // horizontal
        FBorderQuads[i].Width := Length;
        FBorderQuads[i].Height := 2;

        if i = 0 then
            FBorderQuads[i].Transform := RMatrix4x3.CreateRotationZAroundPosition(LineCenter.XY0, -Abs((Corners[j] - LineCenter).InnerAngle(RVector2.UNITX)))
        else
            FBorderQuads[i].Transform := RMatrix4x3.CreateRotationZAroundPosition(LineCenter.XY0, -((Corners[i] - LineCenter).InnerAngle(RVector2.UNITX)));
      end
      else
      begin
        // vertical
        FBorderQuads[i].Width := 2;
        FBorderQuads[i].Height := Length;

        if i = 3 then
            FBorderQuads[i].Transform := RMatrix4x3.CreateRotationZAroundPosition(LineCenter.XY0, Abs((Corners[i] - LineCenter).InnerAngle(RVector2.UNITY)))
        else
            FBorderQuads[i].Transform := RMatrix4x3.CreateRotationZAroundPosition(LineCenter.XY0, -((Corners[j] - LineCenter).InnerAngle(RVector2.UNITY)));
      end;

      FBorderQuads[i].ColorOverride := FCurrentColorOverride;
      FBorderQuads[i].AddRenderJob;
    end;
  end;
end;

procedure TMiniMap.Init;
var
  i : Integer;
  GUIComponent : TGUIComponent;
begin
  if not FInitialized and TryGetComponent(GUIComponent) then
  begin
    // create placeholder quads for the borders, position and size will be corrected
    // later during the Idle step.
    for i := 0 to 3 do
    begin
      FBorderQuads.Add(TVertexScreenAlignedQuad.Create(VertexEngine, RVector2.ZERO, 4, 4, nil, 1010));
      FBorderQuads.Last.UseTransform := True;
      FBorderQuads.Last.DrawOrder := 1000;
      FBorderQuads.Last.DrawsAtStage := rsGUI;
      FBorderQuads.Last.Anchor := RVector2.Create(0.5, 0.5);
    end;

    // default is classic map
    if FSingle then
        GUIComponent.BackgroundImage := 'HUD\MinimapPanel\map_minimap_single.png'
    else
        GUIComponent.BackgroundImage := 'HUD\MinimapPanel\map_minimap.png';

    RecalculateSize();

    FInitialized := True;
  end;
end;

procedure TMiniMap.IsSingleMap;
begin
  FSingle := True;
  if FInitialized then GUI.FindUnique(HUD_MINIMAP).BackgroundImage := 'HUD\MinimapPanel\map_minimap_single.png';
end;

function TMiniMap.IsWithinGuiBounds(screenPos : RIntVector2) : boolean;
begin
  Result := FGuiBounds.Inflate(MINIMAP_PADDING).ContainsPoint(screenPos.X, screenPos.Y);
end;

procedure TMiniMap.RecalculateSize;
begin
  FGuiBounds := ComputeMiniMapBounds();
  FWorldBounds := GetMapWorldBounds();
end;

procedure TMiniMap.Remove(Entity : TEntity);
var
  search : RMiniMapEntry;
  pair : TPair<RMiniMapEntry, TVertexScreenAlignedQuad>;
begin
  search.Entity := Entity;
  search.IconPath := '';

  if FEntries.ContainsKey(search) then
  begin
    pair := FEntries.ExtractPair(search);
    pair.Value.Free;
  end;
end;

function TMiniMap.SizeToMinimapSize(const Size : single) : RVector2;
begin
  Result.X := 2 * (4 + Size * MINIMAP_SCALE.X);
  Result.Y := 2 * (4 + Size * MINIMAP_SCALE.Y);
end;

procedure TMiniMap.Add(Entry : RMiniMapEntry);
begin
  if not FEntries.ContainsKey(Entry) then
      FEntries.Add(Entry, CreateQuad(Entry, WorldToMiniMap(RVector3.ZERO)));
end;

function TMiniMap.WorldToMiniMap(const WorldPos : RVector3; Transform : boolean; IgnoreBounds : boolean) : RVector2;
var
  World, GUI : RRectFloat;
  X, Y : single;
  V : RVector2;
begin
  World := FWorldBounds;
  GUI := FGuiBounds;

  // world position mapped 1:1 into MiniMap coordinate system within GUI
  X := GUI.Left + ((WorldPos.X - World.Left) / World.Width) * GUI.Width;
  Y := GUI.Top + ((WorldPos.Z - World.Top) / World.Height) * GUI.Height;
  V := RVector2.Create(X, Y);

  // move into local coordinate system around (0, 0), so we can transform them
  V.X := V.X - (GUI.Left + GUI.Width / 2);
  V.Y := V.Y - (GUI.Top + GUI.Height / 2);

  if Transform then
  begin
    // adjust for camera rotation
    V := V.Rotate(RVector3.UNITZ.AngleBetween(CAMERAOFFSET.SetY(0).Normalize) - Pi / MINIMAP_ROTATIONAL_OFFSET);

    // mirror along X=Y
    V := V.Mirror(RVector2.Create(1, 1));
  end;

  // scale up because we don't need all the empty space around the lanes
  V.X := V.X * MINIMAP_SCALE.X;
  V.Y := V.Y * MINIMAP_SCALE.Y;

  // back into GUI coordinate system
  V.X := V.X + (GUI.Left + GUI.Width / 2);
  V.Y := V.Y + (GUI.Top + GUI.Width / 2);

  if not IgnoreBounds then
  begin
    // clip coordinates at the edges of the GUI element
    V.X := HMath.Clamp(V.X, GUI.Left, GUI.Right);
    V.Y := HMath.Clamp(V.Y, GUI.Top, GUI.Bottom);
  end;

  Result := V;
end;

function TMiniMap.MiniMapToWorld(screenPos : RIntVector2) : RVector2;
var
  World, GUI : RRectFloat;
  X, Y, angle : single;
begin
  World := FWorldBounds;
  GUI := FGuiBounds;

  // move from GUI coordinates to world coordinates
  X := World.Left + ((screenPos.X - GUI.Left) / GUI.Width) * World.Width;
  Y := World.Top + ((screenPos.Y - GUI.Top) / GUI.Height) * World.Height;

  // move to local coordinate system so we can apply transforms
  X := X - (World.Left + World.Width / 2);
  Y := Y - (World.Top + World.Height / 2);

  // account for minimap rotation
  angle := RVector3.UNITZ.AngleBetween(CAMERAOFFSET.SetY(0)) - Pi / MINIMAP_ROTATIONAL_OFFSET;
  Result := RVector2.Create(X, Y).Rotate(-angle);

  // mirror
  Result := RVector2.Create(Result.X, Result.Y).Mirror(RVector2.Create(0, 1));

  // account for minimap scale factor
  Result.X := Result.X / MINIMAP_SCALE.X;
  Result.Y := Result.Y / MINIMAP_SCALE.Y;

  // back into worldspace
  Result.X := Result.X + (World.Left + World.Width / 2);
  Result.Y := Result.Y + (World.Top + World.Height / 2);
end;

procedure TMiniMap.Ping(const Position : RVector2; const IconPath : string; IconSize : single; Duration : Integer);
var
  Ping : TMiniMapPing;
begin
  Ping := TMiniMapPing.Create;
  Ping.Position := Position;
  Ping.IconPath := IconPath;
  Ping.IconSize := IconSize;
  Ping.PingStart := TimeManager.GetTimeStamp;
  Ping.PingDuration := Duration;
  Ping.Quad := CreateQuad(Position, IconSize);
  Ping.Quad.DrawOrder := Ping.Quad.DrawOrder + 200 + FPingOrder;
  inc(FPingOrder);
  FPings.Add(Ping);
end;

function TMiniMap.PingSize(s : single) : single;
begin
  Result := 1 + sin(HMath.Saturate(s * 15) * Pi) * 7.5;
end;

{ TMiniMapEntryComparer }

function TMiniMapEntryComparer.Equals(const Left, Right : RMiniMapEntry) : boolean;
begin
  Result := (Left.Entity = Right.Entity);
end;

function TMiniMapEntryComparer.GetHashCode(const Value : RMiniMapEntry) : Integer;
begin
  Result := Value.Entity.GetHashCode;
end;

{ RMiniMapEntry }

constructor RMiniMapEntry.Create(Entity : TEntity; IconSize : single; IconPath : string);
begin
  Self.Entity := Entity;
  Self.IconSize := IconSize;
  Self.IconPath := IconPath;
  Self.DynamicPath := IconPath.Contains('%d');
end;

{ TMiniMapPing }

destructor TMiniMapPing.Destroy;
begin
  Quad.Free;
  inherited;
end;

end.
