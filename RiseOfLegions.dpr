program RiseOfLegions;

{$R 'Shader.res' 'Engine\Shader\Shader.rc'}
{$R 'Splash.res' 'Splash.rc'}

uses
  BaseConflict.Client.Init in 'BaseConflict.Client.Init.pas',
  ShellApi,
  windows,
  messages,
  Forms,
  Engine.Helferlein in 'Engine\Engine.Helferlein.pas',
  BaseConflictMainUnit in 'BaseConflictMainUnit.pas' {Hauptform},
  Engine.Collision in 'Engine\Engine.Collision.pas',
  Engine.Core in 'Engine\Engine.Core.pas',
  Engine.Input in 'Engine\Engine.Input.pas',
  Engine.Log in 'Engine\Engine.Log.pas',
  Engine.Math in 'Engine\Engine.Math.pas',
  Engine.Mesh in 'Engine\Engine.Mesh.pas',
  Engine.Network in 'Engine\Engine.Network.pas',
  Engine.ParticleEffects in 'Engine\Engine.ParticleEffects.pas',
  Engine.Physics in 'Engine\Engine.Physics.pas',
  Engine.PostEffects in 'Engine\Engine.PostEffects.pas',
  Engine.Serializer in 'Engine\Engine.Serializer.pas',
  Engine.SkyBox in 'Engine\Engine.SkyBox.pas',
  Engine.Terrain in 'Engine\Engine.Terrain.pas',
  Engine.Vertex in 'Engine\Engine.Vertex.pas',
  BaseConflict.EntityComponents.Client in 'BaseConflict.EntityComponents.Client.pas',
  BaseConflict.Entity in 'BaseConflict.Entity.pas',
  BaseConflict.EntityComponents.Shared in 'BaseConflict.EntityComponents.Shared.pas',
  BaseConflict.Game.Client in 'BaseConflict.Game.Client.pas',
  BaseConflict.Constants in 'BaseConflict.Constants.pas',
  Engine.Script in 'Engine\Engine.Script.pas',
  Engine.GfxApi.Types in 'Engine\Engine.GfxApi.Types.pas',
  Engine.Core.Camera in 'Engine\Engine.Core.Camera.pas',
  Engine.GUI.Editor in 'Engine\Engine.GUI.Editor.pas' {GUIDebugForm},
  Engine.GUI in 'Engine\Engine.GUI.pas',
  Engine.GfxApi.Classmapper in 'Engine\Engine.GfxApi.Classmapper.pas',
  Engine.GfxApi in 'Engine\Engine.GfxApi.pas',
  Engine.DX9Api in 'Engine\Engine.DX9Api.pas',
  BaseConflict.Globals.Client in 'BaseConflict.Globals.Client.pas',
  Engine.Math.Collision3D in 'Engine\Engine.Math.Collision3D.pas',
  Engine.Navigation in 'Engine\Engine.Navigation.pas',
  BaseConflict.Map in 'BaseConflict.Map.pas',
  BaseConflict.Map.Client in 'BaseConflict.Map.Client.pas',
  Engine.Serializer.Types in 'Engine\Engine.Serializer.Types.pas',
  BaseConflict.Game in 'BaseConflict.Game.pas',
  BaseConflict.Globals in 'BaseConflict.Globals.pas',
  Engine.Math.Collision2D in 'Engine\Engine.Math.Collision2D.pas',
  BaseConflict.EntityComponents.Client.GUI in 'BaseConflict.EntityComponents.Client.GUI.pas',
  BaseConflict.EntityComponents.Client.Debug in 'BaseConflict.EntityComponents.Client.Debug.pas',
  BaseConflict.EntityComponents.Client.Visuals in 'BaseConflict.EntityComponents.Client.Visuals.pas',
  BaseConflict.Classes.MiniMap in 'BaseConflict.Classes.MiniMap.pas',
  Engine.Animation in 'Engine\Engine.Animation.pas',
  Engine.Vegetation in 'Engine\Engine.Vegetation.pas',
  BaseConflict.EntityComponents.Client.Sound in 'BaseConflict.EntityComponents.Client.Sound.pas',
  Engine.Water in 'Engine\Engine.Water.pas',
  BaseConflict.Settings.Client in 'BaseConflict.Settings.Client.pas',
  BaseConflict.Types.Target in 'BaseConflict.Types.Target.pas',
  Engine.DX11Api in 'Engine\Engine.DX11Api.pas',
  BaseConflict.Classes.Shared in 'BaseConflict.Classes.Shared.pas',
  BaseConflict.Api in 'BaseConflict.Api.pas',
  BaseConflict.Api.Chat in 'BaseConflict.Api.Chat.pas',
  BaseConflict.Constants.Client in 'BaseConflict.Constants.Client.pas',
  BaseConflict.Api.Matchmaking in 'BaseConflict.Api.Matchmaking.pas',
  BaseConflict.Classes.Gamestates in 'BaseConflict.Classes.Gamestates.pas',
  BaseConflict.Constants.Cards in 'BaseConflict.Constants.Cards.pas',
  D3DCompiler_JSB in 'Engine\FixedDX11Header\D3DCompiler_JSB.pas',
  D3DX11_JSB in 'Engine\FixedDX11Header\D3DX11_JSB.pas',
  Winapi.D3D11 in 'Engine\FixedDX11Header\Winapi.D3D11.pas',
  BaseConflict.Classes.Pathfinding in 'BaseConflict.Classes.Pathfinding.pas',
  Engine.Helferlein.DataStructures in 'Engine\Engine.Helferlein.DataStructures.pas',
  BaseConflict.Api.Types in 'BaseConflict.Api.Types.pas',
  BaseConflict.Api.Deckbuilding in 'BaseConflict.Api.Deckbuilding.pas',
  Engine.AnimatedBackground in 'Engine\Engine.AnimatedBackground.pas',
  Engine.Network.RPC in 'Engine\Engine.Network.RPC.pas',
  BaseConflict.Api.Account in 'BaseConflict.Api.Account.pas',
  BaseConflict.Classes.Gamestates.Actions in 'BaseConflict.Classes.Gamestates.Actions.pas',
  BaseConflict.Classes.Client in 'BaseConflict.Classes.Client.pas',
  Engine.Helferlein.Threads in 'Engine\Engine.Helferlein.Threads.pas',
  BaseConflict.Constants.Scenario in 'BaseConflict.Constants.Scenario.pas',
  Engine.Helferlein.Windows in 'Engine\Engine.Helferlein.Windows.pas',
  BaseConflict.Api.Shop in 'BaseConflict.Api.Shop.pas',
  BaseConflict.Api.Game in 'BaseConflict.Api.Game.pas',
  BaseConflict.Classes.Gamestates.GUI in 'BaseConflict.Classes.Gamestates.GUI.pas',
  Engine.PostEffects.Editor in 'Engine\Engine.PostEffects.Editor.pas' {PostEffectDebugForm},
  Engine.Core.Types in 'Engine\Engine.Core.Types.pas',
  BaseConflict.Api.Cards in 'BaseConflict.Api.Cards.pas',
  BaseConflict.Api.Profile in 'BaseConflict.Api.Profile.pas',
  BaseConflict.Api.Shared in 'BaseConflict.Api.Shared.pas',
  Engine.DataQuery in 'Engine\Engine.DataQuery.pas',
  BaseConflict.Types.Shared in 'BaseConflict.Types.Shared.pas',
  BaseConflict.EntityComponents.Shared.Wela in 'BaseConflict.EntityComponents.Shared.Wela.pas',
  BaseConflictSplash in 'BaseConflictSplash.pas' {SplashForm},
  Engine.dXML in 'Engine\Engine.dXML.pas',
  Engine.Expression in 'Engine\Engine.Expression.pas',
  Engine.Core.Texture in 'Engine\Engine.Core.Texture.pas',
  FMOD.Studio.Classes in 'Engine\Sound\FMOD.Studio.Classes.pas',
  steam_api in 'Engine\Steam\steam_api.pas',
  Baseconflict.Api.Scenarios in 'Baseconflict.Api.Scenarios.pas',
  steamclientpublic in 'Engine\Steam\steamclientpublic.pas',
  Engine.Serializer.JSON in 'Engine\Engine.Serializer.JSON.pas',
  BaseConflict.Api.Quests in 'BaseConflict.Api.Quests.pas',
  Engine.Helferlein.Rtti in 'Engine\Engine.Helferlein.Rtti.pas',
  BaseConflict.Api.Messages in 'BaseConflict.Api.Messages.pas',
  Engine.ParticleEffects.Simulators in 'Engine\Engine.ParticleEffects.Simulators.pas',
  Engine.ParticleEffects.Types in 'Engine\Engine.ParticleEffects.Types.pas',
  Engine.ParticleEffects.Emitters in 'Engine\Engine.ParticleEffects.Emitters.pas',
  Engine.ParticleEffects.Particles in 'Engine\Engine.ParticleEffects.Particles.pas',
  Engine.ParticleEffects.Renderer in 'Engine\Engine.ParticleEffects.Renderer.pas',
  Engine.Preloader in 'Engine\Engine.Preloader.pas',
  Engine.Debug in 'Engine\Engine.Debug.pas',
  Engine.Core.Mesh in 'Engine\Engine.Core.Mesh.pas',
  BaseConflict.Types.Client in 'BaseConflict.Types.Client.pas';

{$SETPEFLAGS IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$R *.res}


begin
  {$IFDEF STEAM}
  if SteamAPI_RestartAppIfNecessary(SteamAppID) then
      halt;
  {$ENDIF}
  Application.Initialize;
  Application.ShowMainForm := False;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Rise of Legions';

  // show splash screen
  SplashForm := TSplashForm.Create(Application);
  SplashForm.Execute;

  // then load game
  Application.CreateForm(THauptform, Hauptform);
  Application.Run;
  // unconfine cursor at any chances
  ClipCursor(nil);

end.
