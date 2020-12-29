unit BaseConflict.Globals.Client;

interface

uses
  // ----------- Delphi --------------
  System.Generics.Collections,
  Vcl.Taskbar,
  // --------- ThirdParty ------------
  FMOD.Studio.Classes,
  // ----------- Engine --------------
  Engine.Input,
  Engine.GUI,
  Engine.Terrain,
  Engine.PostEffects,
  {$IFDEF DEBUG}
  Engine.GUI.Editor,
  Engine.Terrain.Editor,
  Engine.PostEffects.Editor,
  {$ENDIF}
  Engine.Vertex,
  // ------------ Game ---------------
  BaseConflict.Api.Types,
  BaseConflict.Entity,
  BaseConflict.Game.Client,
  BaseConflict.EntityComponents.Client.Sound,
  BaseConflict.Classes.MiniMap,
  BaseConflict.Api.Account,
  BaseConflict.Api.Chat,
  BaseConflict.Api.Game,
  BaseConflict.Api.Matchmaking,
  BaseConflict.Api.Shop,
  BaseConflict.Api.Deckbuilding,
  BaseConflict.Map.Client,
  BaseConflict.Constants.Client,
  BaseConflict.Classes.Client,
  BaseConflict.Classes.Gamestates.GUI;

type
  EnumInputType = (itKeyboard, itMouse);
  SetInputTypes = set of EnumInputType;
  /// <summary> Coloring mode of units.
  /// ucAlly distinguish between own,ally,enemy and neutral units.
  /// ucPlayer colors units related to their owner. </summary>
  EnumUnitColoringMode = (ucTeam, ucAlly, ucPlayer);
  EnumTaskbarState = (tsNone, tsNormal, tsError, tsPaused, tsIndeterminate);

var
  IsStaging : boolean;

  GlobalEntity : TEntity;

  ClientWindowActive : boolean;
  HUD : TIngameHUD;
  PostEffects : TPostEffectManager;
  GUI : TGUI;
  GUIInputUsed : SetInputTypes;
  ShowHealthbars : boolean = true;
  ShowHitBoxes : boolean   = false;
  PreventIdle : boolean    = false;

  KeybindingManager : TKeybindingManager<EnumKeybinding>;

  TaskbarManager : TTaskbar;
  Appstate : EnumTaskbarState = tsNone;
  AppProgress : int64         = 0;
  AppProgressMax : int64      = 0;

  /// <summary> The current game. Used by the components, so it must be contain the right game. </summary>
  ClientGame : TClientGame;
  ClientMap : TClientMap;
  /// <summary> Currently only ucTeam is implemented. </summary>
  UnitColorMode : EnumUnitColoringMode = ucTeam;

  /// <summary> Contains the information about the last game played by the player. </summary>
  ServerGameData : TGameMetaInfo;
  GameServerPort : Word;

  SoundSystem : TFMODStudioSystem;
  SoundMasterBus : TFMODStudioBus;
  SoundMusicBus : TFMODStudioBus;
  SoundEffectBus : TFMODStudioBus;
  SoundUIBus : TFMODStudioBus;
  SoundPingBus : TFMODStudioBus;

  SoundManager : TGlobalSoundManagerComponent;

  USE_ASSET_PRELOADER_CACHE : boolean = {$IFDEF RELEASE}true{$ELSE}false{$ENDIF};

implementation

end.
