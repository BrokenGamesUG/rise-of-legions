unit BaseConflict.Classes.Client;

interface

uses
  Generics.Collections,
  SysUtils,

  Engine.Core,
  Engine.Core.Types,
  Engine.GFXApi.Types,
  Engine.GFXApi,
  Engine.Log,
  Engine.Input,
  Engine.GUI,
  Engine.Mesh,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Helferlein,
  Engine.DataQuery,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Serializer.Types,
  Engine.Serializer,

  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Settings.Client;

type

  TRenderableHack = class(TRenderable);

  TZoneRenderer = class(TRenderable)
    private
      FDropZoneMode : EnumDropZoneMode;
      FValidColor, FInvalidColor : RColor;
      FTexture : TFullscreenRendertarget;
      FPostShader : TShader;
      FScreenQuad : TScreenQuad;
      FBase, FBaseInvalid, FDynamic, FBaseCutout : TMesh;
      FDynamicZones : TList<RCircle>;
      procedure SetDynamicZones(const Value : TList<RCircle>);
      procedure SetDropZoneMode(const Value : EnumDropZoneMode);
    protected
      procedure Render(CurrentStage : EnumRenderStage; RenderContext : TRenderContext); override;
    public
      property DropZoneMode : EnumDropZoneMode write SetDropZoneMode;
      property DynamicZones : TList<RCircle> read FDynamicZones write SetDynamicZones;
      constructor Create(Scene : TRenderManager; const Zonename : string);
      destructor Destroy; override;
  end;

implementation

uses
  BaseConflict.Globals;

{ TZoneRenderer }

constructor TZoneRenderer.Create(Scene : TRenderManager; const Zonename : string);
var
  MapName : string;
begin
  FCallbackTime := ctBefore;
  inherited Create(Scene, [rsEffects]);
  FDropZoneMode := dzHide;
  SetDropZoneMode(dzAll);

  FScreenQuad := TScreenQuad.Create();

  FValidColor := Settings.GetColorOption(coGameplayDropValidColor);
  FInvalidColor := Settings.GetColorOption(coGameplayDropInValidColor);
  FDynamicZones := TList<RCircle>.Create;
  FTexture := Scene.CreateFullscreenRendertarget();

  if assigned(Game) then MapName := Game.GameInfo.Scenario.MapName
  else if assigned(Map) and Map.Filepath.Contains('Classic') then MapName := 'Classic'
  else MapName := 'Single';

  FBase := TMesh.CreateFromFile(Scene, AbsolutePath(PATH_GRAPHICS_GAMPLAY_ZONE + Zonename + '_' + MapName + '.xml'));
  FBase.Visible := False;
  FBase.Position := RVector3.Create(0, 0.01, 0);
  FBaseCutout := TMesh.CreateFromFile(Scene, AbsolutePath(PATH_GRAPHICS_GAMPLAY_ZONE + Zonename + '_' + MapName + '_Cutout.xml'));
  FBaseCutout.Visible := False;
  FBaseCutout.Position := RVector3.Create(0, 0.01, 0);
  FBaseInvalid := TMesh.CreateFromFile(Scene, AbsolutePath(PATH_GRAPHICS_GAMPLAY_ZONE + Zonename + '_' + MapName + '_Invalid.xml'));
  FBaseInvalid.Visible := False;
  FBaseInvalid.Position := RVector3.Create(0, 0.01, 0);
  FDynamic := TMesh.CreateFromFile(Scene, AbsolutePath(PATH_GRAPHICS_GAMPLAY_ZONE + Zonename + '_Dynamic' + '.xml'));
  FDynamic.Visible := False;
  FDynamic.Position := RVector3.Create(0, 0.01, 0);
end;

destructor TZoneRenderer.Destroy;
begin
  FPostShader.Free;
  FScreenQuad.Free;
  FTexture.Free;
  FBase.Free;
  FBaseInvalid.Free;
  FBaseCutout.Free;
  FDynamic.Free;
  FDynamicZones.Free;
  inherited;
end;

procedure TZoneRenderer.Render(CurrentStage : EnumRenderStage; RenderContext : TRenderContext);
var
  i : integer;
begin
  inherited;
  if FDropZoneMode <> dzHide then
  begin
    GFXD.Device3D.PushRenderTargets([FTexture.AsRendertarget]);
    GFXD.Device3D.Clear([cfStencil, cfTarget], RColor.CTRANSPARENTBLACK, 0, 0);
    GFXD.Device3D.SetRenderState(rsZWRITEENABLE, False, True);
    GFXD.Settings.Lighting := False;

    GFXD.Device3D.SetRenderState(rsSTENCILENABLE, True, True);

    // first mask drop area
    GFXD.Device3D.SetRenderState(rsSTENCILFUNC, coAlways, True);
    GFXD.Device3D.SetRenderState(rsSTENCILPASS, soIncrSat, True);
    GFXD.Device3D.SetRenderState(rsSTENCILZFAIL, soIncrSat, True);
    GFXD.Device3D.SetRenderState(rsSTENCILFAIL, soKeep, True);
    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, True, True);
    GFXD.Device3D.SetRenderState(rsSEPARATEALPHABLENDENABLE, True, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOP, boAdd, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blZero, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blOne, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOPALPHA, boAdd, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLENDALPHA, blOne, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLENDALPHA, blZero, True);

    FBase.Alpha := FValidColor.A;
    FBase.ColorOverride := FValidColor.RGB1;
    TRenderableHack(FBase).Render(rsEffects, RenderContext);

    GFXD.Device3D.SetRenderState(rsZENABLE, False, True);

    // now draw zones while removing mask
    GFXD.Device3D.SetRenderState(rsSTENCILFUNC, coEqual, True);
    GFXD.Device3D.SetRenderState(rsSTENCILREF, 1, True);
    GFXD.Device3D.SetRenderState(rsSTENCILPASS, soDecrSat, True);
    GFXD.Device3D.SetRenderState(rsSTENCILZFAIL, soKeep, True);
    GFXD.Device3D.SetRenderState(rsSTENCILFAIL, soKeep, True);

    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blOne, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blZero, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLENDALPHA, blZero, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLENDALPHA, blOne, True);

    // invalid cutout
    FBaseInvalid.Alpha := FInvalidColor.A;
    FBaseInvalid.ColorOverride := FInvalidColor.RGB1;
    TRenderableHack(FBaseInvalid).Render(rsEffects, RenderContext);

    // valid cutout
    for i := 0 to DynamicZones.Count - 1 do
    begin
      FDynamic.Alpha := FValidColor.A;
      FDynamic.ColorOverride := FValidColor.RGB1;
      FDynamic.Position := DynamicZones[i].Center.X0Y(0.01);
      FDynamic.Scale := DynamicZones[i].Radius * 4;
      TRenderableHack(FDynamic).Render(rsEffects, RenderContext);
    end;

    // fill rest with invalid color
    {$IFDEF MAPEDITOR}
    FBase.ColorOverride := FValidColor.RGB1;
    FBase.Alpha := FValidColor.A;
    {$ELSE}
    FBase.ColorOverride := FInvalidColor.RGB1;
    FBase.Alpha := FInvalidColor.A;
    {$ENDIF}
    TRenderableHack(FBase).Render(rsEffects, RenderContext);

    // finally remove all cutout parts with zero alpha to don't generate borders
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blZero, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blOne, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLENDALPHA, blZero, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLENDALPHA, blZero, True);
    TRenderableHack(FBaseCutout).Render(rsEffects, RenderContext);

    GFXD.Device3D.ClearRenderState(rsALPHABLENDENABLE);
    GFXD.Device3D.ClearRenderState(rsSEPARATEALPHABLENDENABLE);
    GFXD.Device3D.ClearRenderState(rsBLENDOP);
    GFXD.Device3D.ClearRenderState(rsSRCBLEND);
    GFXD.Device3D.ClearRenderState(rsDESTBLEND);
    GFXD.Device3D.ClearRenderState(rsBLENDOPALPHA);
    GFXD.Device3D.ClearRenderState(rsSRCBLENDALPHA);
    GFXD.Device3D.ClearRenderState(rsDESTBLENDALPHA);
    GFXD.Device3D.ClearRenderState(rsSTENCILENABLE);
    GFXD.Device3D.ClearRenderState(rsSTENCILREF);
    GFXD.Device3D.ClearRenderState(rsSTENCILFUNC);
    GFXD.Device3D.ClearRenderState(rsSTENCILPASS);
    GFXD.Device3D.ClearRenderState(rsSTENCILZFAIL);
    GFXD.Device3D.ClearRenderState(rsSTENCILFAIL);

    GFXD.Device3D.ClearRenderState(rsZENABLE);
    GFXD.Device3D.ClearRenderState(rsZWRITEENABLE);

    GFXD.Device3D.PopRenderTargets;

    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, True);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOP, boAdd);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blInvSrcAlpha);
    GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
    RenderContext.SetShader(FPostShader);
    FPostShader.SetShaderConstant<RMatrix>('view_projection_inverse', RenderContext.Camera.ViewProjectionInverse);
    FPostShader.SetShaderConstant<RVector3>('camera_position', RenderContext.Camera.Position);
    FPostShader.SetShaderConstant<RVector3>('mouse_pos', RPlane.XZ.IntersectRay(RenderContext.Camera.Clickvector(Mouse.Position)));
    FPostShader.SetShaderConstant<single>('pixelwidth', 1 / RenderContext.Size.Width);
    FPostShader.SetShaderConstant<single>('pixelheight', 1 / RenderContext.Size.Height);
    FPostShader.SetTexture(tsColor, FTexture.Texture);
    FPostShader.ShaderBegin;
    FScreenQuad.Render;
    FPostShader.ShaderEnd;

    GFXD.Device3D.ClearSamplerStates;
    GFXD.Device3D.ClearRenderState();
    GFXD.Settings.Lighting := True;
  end;
end;

procedure TZoneRenderer.SetDropZoneMode(const Value : EnumDropZoneMode);
var
  Defines : TArray<string>;
begin
  if Value <> FDropZoneMode then
  begin
    FDropZoneMode := Value;
    case FDropZoneMode of
      dzArea : Defines := ['#define HIGHLIGHT_AREA'];
      dzCursor : Defines := ['#define HIGHLIGHT_CURSOR'];
    else
      Defines := ['#define HIGHLIGHT_AREA', '#define HIGHLIGHT_CURSOR'];
    end;
    FPostShader := TShader.CreateShaderFromFile(GFXD.Device3D, AbsolutePath(PATH_GRAPHICS_GAMPLAY_ZONE + 'PostprocessZone.fx'), Defines);
  end;
end;

procedure TZoneRenderer.SetDynamicZones(const Value : TList<RCircle>);
begin
  if assigned(Value) then
  begin
    FDynamicZones.Free;
    FDynamicZones := Value;
  end
  else FDynamicZones.Clear;
end;

end.
