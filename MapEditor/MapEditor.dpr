program MapEditor;

{$R 'Shader.res' '..\..\Units\Shader\Shader.rc'}

uses
  Forms,
  MapEditorMain in 'MapEditorMain.pas' {Hauptform},
  BaseConflict.Map in '..\BaseConflict.Map.pas',
  BaseConflict.Entity in '..\BaseConflict.Entity.pas',
  BaseConflict.Constants in '..\BaseConflict.Constants.pas',
  Engine.Math.Collision2D in '..\..\Units\Engine.Math.Collision2D.pas',
  Engine.Terrain.Editor in '..\..\Units\Engine.Terrain.Editor.pas',
  Engine.Terrain in '..\..\Units\Engine.Terrain.pas',
  Engine.Pathfinding in '..\..\Units\Engine.Pathfinding.pas',
  BaseConflict.Game.Client in '..\BaseConflict.Game.Client.pas',
  BaseConflict.Game in '..\BaseConflict.Game.pas',
  BaseConflict.Globals in '..\BaseConflict.Globals.pas',
  Engine.Water in '..\..\Units\Engine.Water.pas',
  Engine.Vegetation in '..\..\Units\Engine.Vegetation.pas',
  Engine.Water.Editor in '..\..\Units\Engine.Water.Editor.pas',
  Engine.Math.CollisionHelper in '..\..\Units\Engine.Math.CollisionHelper.pas',
  Baseconflict.Types.Shared in '..\Baseconflict.Types.Shared.pas',
  Baseconflict.Classes.Shared in '..\Baseconflict.Classes.Shared.pas',
  BaseConflict.Settings.Client in '..\BaseConflict.Settings.Client.pas',
  LightManagerFormUnit in 'LightManagerFormUnit.pas' {LightManagerForm},
  BaseConflict.Constants.Client in '..\BaseConflict.Constants.Client.pas',
  Engine.DX11Api in '..\..\Units\Engine.DX11Api.pas',
  Engine.GfxApi in '..\..\Units\Engine.GfxApi.pas',
  Engine.GfxApi.Types in '..\..\Units\Engine.GfxApi.Types.pas',
  Engine.ParticleEffects in '..\..\Units\Engine.ParticleEffects.pas',
  Engine.Vertex in '..\..\Units\Engine.Vertex.pas',
  Engine.Animation in '..\..\Units\Engine.Animation.pas',
  Engine.AssetLoader.AssimpLoader in '..\..\Units\Engine.AssetLoader.AssimpLoader.pas',
  Engine.AssetLoader.FBXLoader in '..\..\Units\Engine.AssetLoader.FBXLoader.pas',
  Engine.AssetLoader.MeshAsset in '..\..\Units\Engine.AssetLoader.MeshAsset.pas',
  Engine.AssetLoader in '..\..\Units\Engine.AssetLoader.pas',
  Engine.AssetLoader.XFileLoader in '..\..\Units\Engine.AssetLoader.XFileLoader.pas',
  Engine.Collision in '..\..\Units\Engine.Collision.pas',
  Engine.Core.Camera in '..\..\Units\Engine.Core.Camera.pas',
  Engine.Core.Lights in '..\..\Units\Engine.Core.Lights.pas',
  Engine.Core in '..\..\Units\Engine.Core.pas',
  Engine.Core.Types in '..\..\Units\Engine.Core.Types.pas',
  Engine.DX9Api in '..\..\Units\Engine.DX9Api.pas',
  Engine.GfxApi.Classmapper in '..\..\Units\Engine.GfxApi.Classmapper.pas',
  Engine.GUI.Editor in '..\..\Units\Engine.GUI.Editor.pas',
  Engine.GUI in '..\..\Units\Engine.GUI.pas',
  Engine.Helferlein.DataStructures.Helper in '..\..\Units\Engine.Helferlein.DataStructures.Helper.pas',
  Engine.Helferlein.DataStructures in '..\..\Units\Engine.Helferlein.DataStructures.pas',
  Engine.Helferlein in '..\..\Units\Engine.Helferlein.pas',
  Engine.Helferlein.Threads in '..\..\Units\Engine.Helferlein.Threads.pas',
  Engine.Helferlein.VCLUtils in '..\..\Units\Engine.Helferlein.VCLUtils.pas',
  Engine.Helper.Tga in '..\..\Units\Engine.Helper.Tga.pas',
  Engine.Input in '..\..\Units\Engine.Input.pas',
  Engine.Log in '..\..\Units\Engine.Log.pas',
  Engine.Math.Collision3D in '..\..\Units\Engine.Math.Collision3D.pas',
  Engine.Math in '..\..\Units\Engine.Math.pas',
  Engine.Mesh in '..\..\Units\Engine.Mesh.pas',
  Engine.Navigation in '..\..\Units\Engine.Navigation.pas',
  Engine.Network in '..\..\Units\Engine.Network.pas',
  Engine.ParticleEffects.Emitters in '..\..\Units\Engine.ParticleEffects.Emitters.pas',
  Engine.ParticleEffects.Particles in '..\..\Units\Engine.ParticleEffects.Particles.pas',
  Engine.ParticleEffects.Renderer in '..\..\Units\Engine.ParticleEffects.Renderer.pas',
  Engine.ParticleEffects.Simulators in '..\..\Units\Engine.ParticleEffects.Simulators.pas',
  Engine.ParticleEffects.Types in '..\..\Units\Engine.ParticleEffects.Types.pas',
  Engine.Pathfinding.Helper in '..\..\Units\Engine.Pathfinding.Helper.pas',
  Engine.Physics in '..\..\Units\Engine.Physics.pas',
  Engine.PostEffects in '..\..\Units\Engine.PostEffects.pas',
  Engine.Script in '..\..\Units\Engine.Script.pas',
  Engine.Serializer in '..\..\Units\Engine.Serializer.pas',
  Engine.Serializer.Types in '..\..\Units\Engine.Serializer.Types.pas',
  Engine.SkyBox in '..\..\Units\Engine.SkyBox.pas',
  Engine.Sound in '..\..\Units\Engine.Sound.pas',
  Engine.Vegetation.Editor in '..\..\Units\Engine.Vegetation.Editor.pas',
  Baseconflict.Api.Types in '..\Baseconflict.Api.Types.pas',
  BaseConflict.Classes.Pathfinding in '..\BaseConflict.Classes.Pathfinding.pas',
  BaseConflict.Classes.MiniMap in '..\BaseConflict.Classes.MiniMap.pas',
  BaseConflict.Globals.Client in '..\BaseConflict.Globals.Client.pas',
  BaseConflict.Map.Client in '..\BaseConflict.Map.Client.pas',
  Baseconflict.Api.Chat in '..\Baseconflict.Api.Chat.pas',
  Baseconflict.Api.Deckbuilding in '..\Baseconflict.Api.Deckbuilding.pas',
  Baseconflict.Api.Matchmaking in '..\Baseconflict.Api.Matchmaking.pas',
  BaseConflict.Api in '..\BaseConflict.Api.pas',
  BaseConflict.EntityComponents.Client.Debug in '..\BaseConflict.EntityComponents.Client.Debug.pas',
  BaseConflict.EntityComponents.Client.GUI in '..\BaseConflict.EntityComponents.Client.GUI.pas',
  BaseConflict.EntityComponents.Client in '..\BaseConflict.EntityComponents.Client.pas',
  BaseConflict.EntityComponents.Client.Sound in '..\BaseConflict.EntityComponents.Client.Sound.pas',
  BaseConflict.EntityComponents.Client.Visuals in '..\BaseConflict.EntityComponents.Client.Visuals.pas',
  BaseConflict.EntityComponents.Shared in '..\BaseConflict.EntityComponents.Shared.pas',
  BaseConflict.Constants.Cards in '..\BaseConflict.Constants.Cards.pas',
  BaseConflict.Constants.Scenario in '..\BaseConflict.Constants.Scenario.pas',
  BaseConflict.Classes.Client in '..\BaseConflict.Classes.Client.pas',
  BaseConflict.Api.Account in '..\BaseConflict.Api.Account.pas',
  Baseconflict.Api.Shop in '..\Baseconflict.Api.Shop.pas',
  BaseConflict.Classes.Gamestates.GUI in '..\BaseConflict.Classes.Gamestates.GUI.pas',
  Baseconflict.Api.Game in '..\Baseconflict.Api.Game.pas',
  MapEditorToolBox in 'MapEditorToolBox.pas' {ToolWindow},
  Baseconflict.Api.Cards in '..\Baseconflict.Api.Cards.pas',
  BaseConflict.Api.Profile in '..\BaseConflict.Api.Profile.pas',
  Baseconflict.Api.Shared in '..\Baseconflict.Api.Shared.pas',
  BaseConflict.Types.Target in '..\BaseConflict.Types.Target.pas',
  BaseConflict.EntityComponents.Shared.Wela in '..\BaseConflict.EntityComponents.Shared.Wela.pas',
  Engine.Mesh.Editor in '..\..\Units\Engine.Mesh.Editor.pas',
  Baseconflict.Api.Scenarios in '..\Baseconflict.Api.Scenarios.pas',
  BaseConflict.Classes.Gamestates in '..\BaseConflict.Classes.Gamestates.pas',
  BaseConflict.Api.Messages in '..\BaseConflict.Api.Messages.pas',
  BaseConflict.Api.Quests in '..\BaseConflict.Api.Quests.pas',
  BaseConflictSplash in '..\BaseConflictSplash.pas',
  BaseConflict.Classes.Gamestates.Actions in '..\BaseConflict.Classes.Gamestates.Actions.pas',
  BaseConflict.Types.Client in '..\BaseConflict.Types.Client.pas';

{$R *.res}


begin
  Application.Initialize;
  Application.CreateForm(THauptform, Hauptform);
  Application.CreateForm(TToolWindow, ToolWindow);
  Application.CreateForm(TLightManagerForm, LightManagerForm);
  Application.Run;

end.
