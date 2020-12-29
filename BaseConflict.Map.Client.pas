unit BaseConflict.Map.Client;

interface

uses
  generics.collections,
  Engine.Math,
  BaseConflict.Constants,
  Engine.Terrain,
  Engine.Input,
  BaseConflict.Globals,
  BaseConflict.Map,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Client,
  BaseConflict.Settings.Client,
  Engine.Core.Lights,
  Engine.Serializer,
  Engine.Serializer.Types,
  Engine.Core,
  Engine.Core.Types,
  Engine.GFXApi,
  Engine.GFXApi.Types,
  Engine.Vertex,
  Engine.Script,
  Classes,
  SysUtils,
  Engine.Water,
  Engine.Vegetation,
  {$IFDEF DEBUG}
  Engine.Terrain.Editor,
  Engine.Water.Editor,
  Engine.Vegetation.Editor,
  {$ENDIF}
  Engine.helferlein,
  Engine.helferlein.Windows,
  Engine.GUI,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  EncdDecd,
  Engine.helferlein.VCLUtils;

type

  {$RTTI EXPLICIT METHODS([vcPublic]) FIELDS([vcProtected,vcPublic]) PROPERTIES([vcProtected, vcPublic])}
  RDecoEntityDescription = record
    Position, Front : RVector3;
    Size : single;
    ScriptFilename : string;
    Freezed : boolean; // only used in the map editor
  end;

  RDirectionalMapLight = record
  [VCLRVector3Field(1, 1, 1, isTrackBar, True)]
    Direction : RVector3;
    [VCLRColorField(1, 1, 1, 10)]
    Color : RVector4;
    [VCLBooleanField]
    Enabled : boolean;
  end;

  [XMLIncludeAll([XMLIncludeFields, XMLIncludeProperties])]
  TLightManager = class(TDirtyClass)
    public const
      FILEEXTENSION = '.lig';
    protected
      [VCLRColorField(1, 1, 1, 1)]
      FAmbient : RVector4;
      FDirectionalLights : TList<RDirectionalMapLight>;
    public
      [VCLListField([loEditItem, loDeleteItem, loAddItem])]
      property DirectionalLights : TList<RDirectionalMapLight> read FDirectionalLights;
      constructor Create;
      procedure SynchronizeLightWithGFXD;
      procedure Idle;
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  [ScriptExcludeAll]
  TClientMap = class
    protected
      FLightManager : TLightManager;
      /// <summary> A list of all decoration on the map. Describing which entity is where and how.
      /// Used for loading and saving. </summary>
      FDecorationDescriptions : TList<RDecoEntityDescription>;
      /// <summary> The real decorations used in a running game. </summary>
      FDecoEntities : TObjectList<TEntity>;
      procedure LoadDecorationDescriptions(Value : TList<RDecoEntityDescription>);
      // <summary> Only for loading entities after deserialization. </summary>
      [XMLIncludeElement]
      property SavedDecorations : TList<RDecoEntityDescription> read FDecorationDescriptions write LoadDecorationDescriptions;
    public
      /// <summary> The terrain used as ground in this map. </summary>
      Terrain : TTerrain;
      /// <summary> Contains all watersurfaces of the map. </summary>
      Water : TWaterManager;
      /// <summary> Manages all procedural vegetation of the scene. </summary>
      Vegetation : TVegetationManager;
      /// <summary> Hides the terrain if false. </summary>
      DrawTerrain : boolean;
      /// <summary> Hides the water if false. </summary>
      DrawWater : boolean;
      /// <summary> Hides the vegetation if false. </summary>
      DrawVegetation : boolean;
      property LightManager : TLightManager read FLightManager;
      /// <summary> All decorations on the map. Read only! </summary>
      property Decorations : TList<RDecoEntityDescription> read FDecorationDescriptions;
      /// <summary> All real decoration entities. Read only! </summary>
      property DecorationEntities : TObjectList<TEntity> read FDecoEntities;
      constructor Create;
      constructor CreateEmpty;
      constructor CreateFromFile(Filename : string);
      [ScriptIncludeMember]
      function AddDecoEntity(PositionX, PositionY, PositionZ, FrontX, FrontY, FrontZ, Size : single; const ScriptFilename : string) : TClientMap; overload;
      /// <summary> Adds a new decoration to the map. </summary>
      procedure AddDecoEntity(EntityDesc : RDecoEntityDescription); overload;
      /// <summary> Removes a decoration from the map. </summary>
      procedure RemoveDecoEntity(index : integer);
      /// <summary> Updates a decoration of the map. </summary>
      procedure UpdateDecoEntity(index : integer; EntityDesc : RDecoEntityDescription);
      /// <summary> Draws all map things. </summary>
      procedure Idle;
      /// <summary> Save this map to the specified file. Terrain, Water, etc. saves under the same filename
      /// but with another file extension. </summary>
      procedure SaveToFile(Filename : string);
      /// <summary> Skadoosh </summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}

implementation

uses
  BaseConflict.Globals.Client;

{ TClientMap }

function TClientMap.AddDecoEntity(PositionX, PositionY, PositionZ, FrontX, FrontY, FrontZ, Size : single; const ScriptFilename : string) : TClientMap;
var
  Desc : RDecoEntityDescription;
begin
  Result := self;
  Desc.Position := RVector3.Create(PositionX, PositionY, PositionZ);
  Desc.Front := RVector3.Create(FrontX, FrontY, FrontZ);
  Desc.Size := Size;
  Desc.ScriptFilename := ScriptFilename;
  Desc.Freezed := False;
  AddDecoEntity(Desc);
end;

constructor TClientMap.Create;
begin
  FDecorationDescriptions := TList<RDecoEntityDescription>.Create;
  FDecoEntities := TObjectList<TEntity>.Create;
  DrawTerrain := True;
  DrawWater := True;
  DrawVegetation := True;
  FLightManager := TLightManager.Create;
end;

constructor TClientMap.CreateEmpty;
begin
  Create;
  Terrain := TTerrain.CreateEmpty(GFXD.MainScene, 512);
  Water := TWaterManager.Create();
  Vegetation := TVegetationManager.Create(GFXD.MainScene);
end;

constructor TClientMap.CreateFromFile(Filename : string);
begin
  Create;
  // light-setup
  HXMLSerializer.LoadObjectFromFile(FLightManager, ChangeFileExt(Filename, TLightManager.FILEEXTENSION));
  // terrain
  if not Settings.GetBooleanOption(coDebugHideMapEnvironment) and FileExists(ChangeFileExt(Filename, TTerrain.FILEEXTENSION)) then
      Terrain := TTerrain.CreateFromFile(GFXD.MainScene, ChangeFileExt(Filename, TTerrain.FILEEXTENSION))
  else
  begin
    Terrain := TTerrain.CreateEmpty(GFXD.MainScene, 128);
    if not FileExists(ChangeFileExt(Filename, TTerrain.FILEEXTENSION)) then
        Terrain.Scale := RVector3.Create(0, 0, 0)
    else
        Terrain.Scale := RVector3.Create(300, 1, 300);
    Terrain.Optimize;
  end;
  // water
  if not Settings.GetBooleanOption(coDebugHideMapEnvironment) and FileExists(ChangeFileExt(Filename, TWaterManager.FILEEXTENSION)) then
      Water := TWaterManager.CreateFromFile(ChangeFileExt(Filename, TWaterManager.FILEEXTENSION))
  else
      Water := TWaterManager.Create();
  // vegetation
  if not Settings.GetBooleanOption(coDebugHideMapEnvironment) and FileExists(ChangeFileExt(Filename, TVegetationManager.FILEEXTENSION)) then
      Vegetation := TVegetationManager.CreateFromFile(GFXD.MainScene, ChangeFileExt(Filename, TVegetationManager.FILEEXTENSION){$IFNDEF MAPEDITOR}, False{$ENDIF})
  else
      Vegetation := TVegetationManager.Create(GFXD.MainScene);
  // doodads
  if not Settings.GetBooleanOption(coDebugHideMapEnvironment) then
      HXMLSerializer.LoadObjectFromFile(self, ChangeFileExt(Filename, CLIENTMAP_FILEEXTENSION));
end;

destructor TClientMap.Destroy;
begin
  FLightManager.Free;
  FDecorationDescriptions.Free;
  Water.Free;
  Vegetation.Free;
  FDecoEntities.Free;
  Terrain.Free;
  inherited;
end;

procedure TClientMap.Idle;
begin
  FLightManager.Idle;
  Terrain.CastsNoShadow := True;
  Terrain.Visible := DrawTerrain;
  Water.Visible := DrawWater;
  Water.Idle;
  Vegetation.Visible := DrawVegetation;
end;

procedure TClientMap.LoadDecorationDescriptions(Value : TList<RDecoEntityDescription>);
var
  Desc : RDecoEntityDescription;
  fix : TArray<RDecoEntityDescription>;
begin
  fix := Value.ToArray;
  FDecorationDescriptions.Clear;
  for Desc in fix do
  begin
    AddDecoEntity(Desc);
  end;
end;

procedure TClientMap.AddDecoEntity(EntityDesc : RDecoEntityDescription);
var
  newEntity : TEntity;
begin
  FDecorationDescriptions.Add(EntityDesc);
  newEntity := TEntity.CreateFromScript(EntityDesc.ScriptFilename, GlobalEventbus);
  FDecoEntities.Add(newEntity);
  UpdateDecoEntity(FDecoEntities.Count - 1, EntityDesc);
  newEntity.Eventbus.Trigger(eiAfterCreate, []);
end;

procedure TClientMap.RemoveDecoEntity(index : integer);
begin
  FDecorationDescriptions.Delete(index);
  FDecoEntities.Delete(index);
end;

procedure TClientMap.UpdateDecoEntity(index : integer; EntityDesc : RDecoEntityDescription);
var
  Entity : TEntity;
begin
  FDecorationDescriptions[index] := EntityDesc;
  Entity := FDecoEntities[index];
  Entity.Position := EntityDesc.Position.XZ;
  Entity.DisplayPosition := EntityDesc.Position;
  Entity.DisplayFront := EntityDesc.Front;
  Entity.DisplayUp := RVector3.UNITY;
  Entity.Eventbus.Write(eiSize, [RVector3.Create(EntityDesc.Size)]);
end;

procedure TClientMap.SaveToFile(Filename : string);
begin
  Filename := ChangeFileExt(Filename, CLIENTMAP_FILEEXTENSION);
  HXMLSerializer.SaveObjectToFile(self, Filename);
  HXMLSerializer.SaveObjectToFile(FLightManager, ChangeFileExt(Filename, TLightManager.FILEEXTENSION));
  Terrain.SaveToFile(ChangeFileExt(Filename, TTerrain.FILEEXTENSION));
  Water.SaveToFile(ChangeFileExt(Filename, TWaterManager.FILEEXTENSION));
  Vegetation.SaveToFile(ChangeFileExt(Filename, TVegetationManager.FILEEXTENSION));
end;

{ TLightManager }

constructor TLightManager.Create;
var
  light : RDirectionalMapLight;
begin
  FDirectionalLights := TList<RDirectionalMapLight>.Create;
  light.Direction := RVector3.Create(0.2545, -0.76334, -0.5937);
  light.Color := RVector4.Create(1, 1, 1, 0.8);
  light.Enabled := True;
  FDirectionalLights.Add(light);
  FAmbient := RVector4.Create(0.7, 0.7, 0.7, 1.0); // RVector4.Create(0.1882, 0.1882, 0.1882, 1.0);
  SetDirty;
end;

destructor TLightManager.Destroy;
begin
  FDirectionalLights.Free;
  inherited;
end;

procedure TLightManager.Idle;
begin
  if IsDirty then
  begin
    SynchronizeLightWithGFXD;
    SetClean;
  end;
end;

procedure TLightManager.SynchronizeLightWithGFXD;
var
  i : integer;
begin
  GFXD.MainScene.Ambient := FAmbient;
  GFXD.MainScene.DirectionalLights.Clear;
  for i := 0 to FDirectionalLights.Count - 1 do
  begin
    GFXD.MainScene.DirectionalLights.Add(TDirectionalLight.Create(FDirectionalLights[i].Color, FDirectionalLights[i].Direction));
    GFXD.MainScene.DirectionalLights.Last.Enabled := FDirectionalLights[i].Enabled;
  end;
end;

initialization

ScriptManager.ExposeClass(TClientMap);

end.
