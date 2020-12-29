unit BaseConflict.Settings.Client;

interface

uses
  Winapi.Windows,
  Generics.Collections,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Script,
  Engine.Log,
  Engine.Input,
  SysUtils,
  Classes,
  IniFiles,
  BaseConflict.Entity,
  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Globals;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPublic])}
  EnumOptionType = (otEngine, otSound, otSoundMeta, otGraphics, otMenu, otGameplay, otSandbox, otGeneral, otKeybinding, otServer, otDebug);

  /// <summary> All possible option of the client. To add new options use the
  /// naming conventention "co" + OptionType + OptionName </summary>
  EnumClientOption = (
    coGeneralNone,

    /// ///////////////////// GENERAL ////////////////////////
    coGeneralOptionsStart,
    coGeneralLanguage,            // string; Client language (de,en), overrides steam settings if set
    coGeneralUsername,            // string; Saved username
    coGeneralPassword,            // string; Saved passwort, slightly obfusicated
    coGeneralHasSecretAccess,     // unused for now
    coGeneralBypassMaintenance,   // boolean; Login even if maintenance
    coGeneralBypassLoginQueue,    // boolean; Login without restriction
    coGeneralRightClickEpsilon,   // integer; distance in pixels, when a click is a click and not a drag
    coGeneralFirstStart,          // boolean; Does the client starts for the first time
    coGeneralDisableBots,         // boolean; Does allow bots to be matched against you
    coGeneralForceBrokerFallback, // boolean; Always use the broker fallback
    coGeneralForceServerOffline,  // boolean; Does not connect to Rise of Legions server
    coGeneralApiTimeout,          // integer; Determines the RPC Api timeout
    coGeneralEnableSpectator,     // boolean; Allow spectator option
    coGeneralOptionsEnd,

    /// ///////////////////// ENGINE ////////////////////////
    coEngineOptionsStart,
    coEngineResolution,             // (integer)x(integer); ingame resolution
    coEngineGameWindowOverride,     // (integer)x(integer)x(integer)x(integer); ingame resolution
    coEngineDisplayMode,            // EnumDisplayMode; Determine window size and state
    coEngineTargetMonitor,          // integer; The monitor to use, defaults to -1 for auto
    coEngineFileHotReload,          // boolean; Enables ContentManager to check changed files
    coEngineShadowBiasMin,          // single; Tweaking value for shadow acne on minimum zoom
    coEngineShadowBiasMax,          // single; Tweaking value for shadow acne on maximum zoom
    coEngineShadowSlopeBias,        // single; Tweaking value for shadow acne on slope
    coEngineShadowClipBelow,        // single; Tweaking value for shadow quality
    coEngineShadowClipAbove,        // single; Tweaking value for shadow quality
    coEngineShadowTweakZoom,        // single; Tweaking value for shadow quality
    coEngineCameraFoV,              // single; Field of view of camera
    coEngineGlobalShadingReduction, // single; Global default value for shading reduction for meshes
    coEngineFMODConnectorEnabled,   // boolean; Determines whether FMOD Studio can connect to the game instance
    coEngineVSyncLevel,             // integer
    coEngineOptionsEnd,

    /// ///////////////////// GRAPHICS ////////////////////////
    coGraphicsOptionsStart,
    coGraphicsPerformanceAnalysed,      // boolean; performance has been analysed
    coGraphicsShadows,                  // boolean; Enables shadows
    coGraphicsShadowResolution,         // integer; Shadowmap resolution
    coGraphicsTextureQuality,           // EnumTextureQuality; Reduction of texture resolution
    coGraphicsDeferredShading,          // boolean; Enables deferred shading
    coGraphicsVSync,                    // boolean; Enables vsync
    coGraphicsGUIBlurBackgrounds,       // boolean; Enables blurred gui backgrounds
    coGraphicsPostEffectSSAO,           // boolean; Enables SSAO
    coGraphicsPostEffectToon,           // boolean; Enables Toon
    coGraphicsPostEffectGlow,           // boolean; Enables Glow
    coGraphicsPostEffectFXAA,           // boolean; Enables FXAA
    coGraphicsPostEffectUnsharpMasking, // boolean; Enables UnsharpMasking
    coGraphicsPostEffectDistortion,     // boolean; Enables Distortion
    coGraphicsOptionsEnd,

    /// ///////////////////// SOUND ////////////////////////
    coSoundOptionsStart,
    coSoundPlayMaster,     // boolean; Enables global audio output
    coSoundMasterVolume,   // 0..100 : integer; The master volume of the whole game
    coSoundBackground,     // boolean; Sound will be muted if game goes out of focus
    coSoundPlayMusic,      // boolean; Enables Music
    coSoundMusicVolume,    // 0..100 : integer; The music volume level
    coSoundPlayEffects,    // boolean; Enables Effects, e.g. explosions, swords
    coSoundEffectVolume,   // 0..100 : integer; The effect volume level
    coSoundPlayGUISound,   // boolean; Enables GUI Sound, e.g. clicks, hovers
    coSoundGUISoundVolume, // 0..100 : integer; The gui volume level
    coSoundPlayPings,      // boolean; Enables ping sounds
    coSoundPingVolume,     // 0..100 : integer; The ping volume level
    coSoundPlayAtmo,       // boolean; Enables atmo sounds
    coSoundOptionsEnd,

    coSoundMetaOptionsStart,
    coSoundMetaPlayMaster,     // boolean; Enables global audio output for the meta client
    coSoundMetaMasterVolume,   // 0..100 : integer; The master volume for the meta client
    coSoundMetaBackground,     // boolean; Sound will be muted if meta client goes out of focus
    coSoundMetaPlayMusic,      // boolean; Enables Music in meta client
    coSoundMetaMusicVolume,    // 0..100 : integer; The music volume level in meta client
    coSoundMetaPlayGUISound,   // boolean; Enables GUI Sound, e.g. clicks, hovers in meta client
    coSoundMetaGUISoundVolume, // 0..100 : integer; The gui volume level in meta client
    coSoundMetaOptionsEnd,

    /// ///////////////////// GAMEPLAY ////////////////////////
    coGameplayOptionsStart,
    coGameplayShowEffectRadius,          // boolean; If true show colored circles of spells and other effects
    coGameplayHealthbarMode,             // EnumHealthbarMode; different modes of healthbars being displayed
    coGameplayDragWavetemplates,         // boolean; Enables drag and drop of wave templates
    coGameplayEndlessBuild,              // boolean; If true wave templates won't be deselected after building it
    coGameplayClipCursor,                // boolean; If true mouse will be caught in the window
    coGameplayRightClickPanning,         // boolean; If true camera can be panned with the right mouse button
    coGameplayCameraMinZoom,             // single; The minimal camera distance zoom factor to the scene
    coGameplayCameraMaxZoom,             // single; The maximal camera distance zoom factor to the scene
    coGameplayDropZoneMode,              // EnumDropZoneMode; different modes of drop zones being displayed
    coGameplayDropValidColor,            // RColor; The valid color of the drop zone
    coGameplayDropInvalidColor,          // RColor; The invalid color of the drop zone
    coGameplayPreviewValidColor,         // RColor; The valid color of the unit preview
    coGameplayPreviewInvalidColor,       // RColor; The invalid color of the unit preview
    coGameplayFixedTeamColors,           // boolean; If true the player will always be blue
    coGameplayClickPrecision,            // single; Additional bias to hit units with a click
    coGameplayScrollSpeed,               // single; Speed of camera
    coGameplayShowTechnicalPanel,        // boolean; If true show fps and ping
    coGameplayShowNumericChargeCooldown, // boolean; if true show cooldown in s on deck cards
    coGameplayShowDeckHotkeys,           // boolean; if true show hotkeys on decks
    coGameplayOptionsEnd,

    /// ///////////////////// SANDBOX ////////////////////////

    coSandboxOptionsStart,
    coSandboxRotationSpeed,       // single; Rotation speed of camera
    coSandboxRotationOffset,      // single; Rotation offset of camera
    coSandboxTiltOffset,          // single; Rotation tilt of the camera
    coSandboxFoVOffset,           // single; Angle added to fov of the camera
    coSandboxSavedCameraPosition, // RVector2; Position of camera
    coSandboxFinishCamOffset,     // RVector2; Offset of target of finish cam
    coSandboxOptionsEnd,

    /// ///////////////////// MENU ////////////////////////
    coMenuOptionsStart,
    coMenuAnimatedBackground,            // boolean; draws the animated background in the main menu
    coMenuDeckbuildingGridSize,          // 3..4 : integer;
    coMenuDeckbuildingSacrificeGridSize, // integer;
    coMenuLimitFramerate,                // integer; 0 - no limit, number - limit
    coMenuClientResolution,              // (integer)x(integer); The resolution of the client
    coMenuClientScaling,                 // EnumMenuScaling; The scaling mode of the client
    coMenuClientFullscreenFrame,         // boolean; Frames the client
    coMenuBringToFrontOnMatchFound,      // boolean; Brings the client into the foreground on match found
    coMenuOptionsEnd,

    /// ///////////////////// KEYBINDINGS ////////////////////////

    coKeybindingBindingNone,
    coKeybindingBindingNoneAlt,
    coKeybindingBindingScreenshot,
    coKeybindingBindingScreenshotAlt,
    coKeybindingBindingDeckslot01,
    coKeybindingBindingDeckslot01Alt,
    coKeybindingBindingDeckslot02,
    coKeybindingBindingDeckslot02Alt,
    coKeybindingBindingDeckslot03,
    coKeybindingBindingDeckslot03Alt,
    coKeybindingBindingDeckslot04,
    coKeybindingBindingDeckslot04Alt,
    coKeybindingBindingDeckslot05,
    coKeybindingBindingDeckslot05Alt,
    coKeybindingBindingDeckslot06,
    coKeybindingBindingDeckslot06Alt,
    coKeybindingBindingDeckslot07,
    coKeybindingBindingDeckslot07Alt,
    coKeybindingBindingDeckslot08,
    coKeybindingBindingDeckslot08Alt,
    coKeybindingBindingDeckslot09,
    coKeybindingBindingDeckslot09Alt,
    coKeybindingBindingDeckslot10,
    coKeybindingBindingDeckslot10Alt,
    coKeybindingBindingDeckslot11,
    coKeybindingBindingDeckslot11Alt,
    coKeybindingBindingDeckslot12,
    coKeybindingBindingDeckslot12Alt,
    coKeybindingBindingSpellCast,
    coKeybindingBindingSpellCastAlt,
    coKeybindingBindingSpellCastRepeat,
    coKeybindingBindingSpellCastRepeatAlt,
    coKeybindingBindingPingGeneric,
    coKeybindingBindingPingGenericAlt,
    coKeybindingBindingPingAttack,
    coKeybindingBindingPingAttackAlt,
    coKeybindingBindingPingDefend,
    coKeybindingBindingPingDefendAlt,
    coKeybindingBindingUnitSelect,
    coKeybindingBindingUnitSelectAlt,
    coKeybindingBindingMainAction,
    coKeybindingBindingMainActionAlt,
    coKeybindingBindingSecondaryAction,
    coKeybindingBindingSecondaryActionAlt,
    coKeybindingBindingMainCancel,
    coKeybindingBindingMainCancelAlt,
    coKeybindingBindingNexusJump,
    coKeybindingBindingNexusJumpAlt,
    coKeybindingBindingScoreboardHold,
    coKeybindingBindingScoreboardHoldAlt,
    coKeybindingBindingGUIToggle,
    coKeybindingBindingGUIToggleAlt,
    coKeybindingBindingSandboxGUIToggle,
    coKeybindingBindingSandboxGUIToggleAlt,
    coKeybindingBindingCaptureMode,
    coKeybindingBindingCaptureModeAlt,
    coKeybindingBindingCameraLeft,
    coKeybindingBindingCameraLeftAlt,
    coKeybindingBindingCameraUp,
    coKeybindingBindingCameraUpAlt,
    coKeybindingBindingCameraRight,
    coKeybindingBindingCameraRightAlt,
    coKeybindingBindingCameraDown,
    coKeybindingBindingCameraDownAlt,
    coKeybindingBindingCameraLaneLeft,
    coKeybindingBindingCameraLaneLeftAlt,
    coKeybindingBindingCameraLaneRight,
    coKeybindingBindingCameraLaneRightAlt,
    coKeybindingBindingCameraRise,
    coKeybindingBindingCameraRiseAlt,
    coKeybindingBindingCameraFall,
    coKeybindingBindingCameraFallAlt,
    coKeybindingBindingCameraPanning,
    coKeybindingBindingCameraPanningAlt,
    coKeybindingBindingCameraMoveTo,
    coKeybindingBindingCameraMoveToAlt,
    coKeybindingBindingCameraResetZoom,
    coKeybindingBindingCameraResetZoomAlt,
    coKeybindingBindingCameraToggleRotation,
    coKeybindingBindingCameraToggleRotationAlt,
    coKeybindingBindingChangeCommander01,
    coKeybindingBindingChangeCommander01Alt,
    coKeybindingBindingChangeCommander02,
    coKeybindingBindingChangeCommander02Alt,
    coKeybindingBindingChangeCommander03,
    coKeybindingBindingChangeCommander03Alt,
    coKeybindingBindingChangeCommander04,
    coKeybindingBindingChangeCommander04Alt,
    coKeybindingBindingChangeCommander05,
    coKeybindingBindingChangeCommander05Alt,
    coKeybindingBindingChangeCommander06,
    coKeybindingBindingChangeCommander06Alt,
    coKeybindingBindingChangeCommander07,
    coKeybindingBindingChangeCommander07Alt,
    coKeybindingBindingChangeCommander08,
    coKeybindingBindingChangeCommander08Alt,
    coKeybindingBindingChangeCommander09,
    coKeybindingBindingChangeCommander09Alt,
    coKeybindingBindingChangeCommander10,
    coKeybindingBindingChangeCommander10Alt,
    coKeybindingBindingChangeCommander11,
    coKeybindingBindingChangeCommander11Alt,
    coKeybindingBindingChangeCommander12,
    coKeybindingBindingChangeCommander12Alt,
    coKeybindingBindingDrawTerrainToggle,
    coKeybindingBindingDrawTerrainToggleAlt,
    coKeybindingBindingDrawWaterToggle,
    coKeybindingBindingDrawWaterToggleAlt,
    coKeybindingBindingDrawVegetationToggle,
    coKeybindingBindingDrawVegetationToggleAlt,
    coKeybindingBindingDeferredShadingToggle,
    coKeybindingBindingDeferredShadingToggleAlt,
    coKeybindingBindingNormalmappingToggle,
    coKeybindingBindingNormalmappingToggleAlt,
    coKeybindingBindingShadowTechniqueToggle,
    coKeybindingBindingShadowTechniqueToggleAlt,
    coKeybindingBindingTerrainEditor,
    coKeybindingBindingTerrainEditorAlt,
    coKeybindingBindingGUIEditor,
    coKeybindingBindingGUIEditorAlt,
    coKeybindingBindingPostEffectEditor,
    coKeybindingBindingPostEffectEditorAlt,
    coKeybindingBindingForceGameTick,
    coKeybindingBindingForceGameTickAlt,
    coKeybindingBindingHitboxToggleVisibility,
    coKeybindingBindingHitboxToggleVisibilityAlt,
    coKeybindingBindingHealthbarsToggleVisibility,
    coKeybindingBindingHealthbarsToggleVisibilityAlt,
    coKeybindingBindingPathfindingVisualize,
    coKeybindingBindingPathfindingVisualizeAlt,
    coKeybindingBindingPathfindingCoordinate,
    coKeybindingBindingPathfindingCoordinateAlt,
    coKeybindingBindingPathfindingFlow,
    coKeybindingBindingPathfindingFlowAlt,
    coKeybindingBindingPathfindingIncVisibleLength,
    coKeybindingBindingPathfindingIncVisibleLengthAlt,
    coKeybindingBindingPathfindingDecVisibleLength,
    coKeybindingBindingPathfindingDecVisibleLengthAlt,

    /// ///////////////////// SERVER ////////////////////////
    coServerWebApiServer,
    coServerBugReportServer,

    /// ///////////////////// DEBUG ////////////////////////
    coDebugSkipLoadingScreen,    // boolean; Skips loading screen from mainmenu to game
    coDebugHideMapEnvironment,   // boolean; Skip loading map environment like Terrain, Water, Vegetation and Doodads
    coDebugUseLocalTestServer,   // boolean; Tries to connect directly to the test servers game at startup
    coDebugLocalTestServerIP,    // string; The ip of the local test server, only used with coDebugUseLocalTestServer = True
    coDebugLocalTestServerToken, // string; The player token for the local test server, only used with coDebugUseLocalTestServer = True
    coDebugEmulateRelease        // boolean; switch for textures, meshes and so on to load different in debug
    );
  SetClientOption = set of EnumClientOption;

  EnumGeneralOptions = coGeneralOptionsStart .. coGeneralOptionsEnd;
  EnumEngineOptions = coEngineOptionsStart .. coEngineOptionsEnd;
  EnumSoundOptions = coSoundOptionsStart .. coSoundOptionsEnd;
  EnumSoundMetaOptions = coSoundMetaOptionsStart .. coSoundMetaOptionsEnd;
  EnumGraphicsOptions = coGraphicsOptionsStart .. coGraphicsOptionsEnd;
  EnumGameplayOptions = coGameplayOptionsStart .. coGameplayOptionsEnd;
  EnumSandboxOptions = coSandboxOptionsStart .. coSandboxOptionsEnd;
  EnumMenuOptions = coMenuOptionsStart .. coMenuOptionsEnd;
  EnumKeybindingOptions = coKeybindingBindingNone .. coKeybindingBindingPathfindingDecVisibleLengthAlt;
  EnumServerOptions = coServerWebApiServer .. coServerBugReportServer;

const
  OPTIONS_POSTEFFECTS                  = [coGraphicsPostEffectSSAO .. coGraphicsPostEffectDistortion];
  OPTIONS_GENERAL : SetClientOption    = [low(EnumGeneralOptions) .. high(EnumGeneralOptions)];
  OPTIONS_ENGINE : SetClientOption     = [low(EnumEngineOptions) .. high(EnumEngineOptions)];
  OPTIONS_SOUND : SetClientOption      = [low(EnumSoundOptions) .. high(EnumSoundOptions)];
  OPTIONS_SOUND_META : SetClientOption = [low(EnumSoundMetaOptions) .. high(EnumSoundMetaOptions)];
  OPTIONS_GRAPHICS : SetClientOption   = [low(EnumGraphicsOptions) .. high(EnumGraphicsOptions)];
  OPTIONS_GAMEPLAY : SetClientOption   = [low(EnumGameplayOptions) .. high(EnumGameplayOptions)];
  OPTIONS_SANDBOX : SetClientOption    = [low(EnumSandboxOptions) .. high(EnumSandboxOptions)];
  OPTIONS_MENU : SetClientOption       = [low(EnumMenuOptions) .. high(EnumMenuOptions)];
  OPTIONS_KEYBINDING : SetClientOption = [low(EnumKeybindingOptions) .. high(EnumKeybindingOptions)];
  OPTIONS_SERVER : SetClientOption     = [low(EnumServerOptions) .. high(EnumServerOptions)];

type
  EnumHealthbarMode = (hmNone, hmDamaged, hmAlways);
  EnumDropZoneMode = (dzAll, dzArea, dzCursor, dzHide);

  /// <summary> Handles all settings in the client. Loads and saves them from disk, sends eiClientOption if something
  /// has changed. </summary>
  TOptionManager = class
    protected
      /// <summary> Second dictionary has integer because EnumType is determined by Settingstype. </summary>
      FOptionBackUp, FOptions : TObjectDictionary<EnumOptionType, TDictionary<EnumClientOption, string>>;
      FOptionTypeCache : TDictionary<EnumClientOption, EnumOptionType>;
      procedure LoadSettingsCallback(const FilePath, FileContent : string);
      procedure LoadSettingsFromFile(FilePath : string);
      procedure SaveSettingsToFile(FilePath : string);
      function OptionTypeToString(OptionType : EnumOptionType) : string;
      function OptionToString(Option : EnumClientOption; Category : EnumOptionType) : string;
      function OptionToOptionType(Option : EnumClientOption) : EnumOptionType;
      function TryStringToOption(Option : string; Category : EnumOptionType; out OptionEnum : EnumClientOption) : boolean;
      procedure ClearSnapshot;
    public
      constructor Create();

      /// <summary> Reverts this option to the default value. </summary>
      procedure RevertOption(Option : EnumClientOption);

      /// <summary> Returns whether this option has been set by the user (true) or is the default value (false). </summary>
      function IsSet(Option : EnumClientOption) : boolean;
      function IsSetNotNone(Option : EnumClientOption) : boolean;

      /// <summary> Returns the raw default option of a client option. </summary>
      function GetDefaultOption(Option : EnumClientOption) : string;

      /// <summary> Getter methods for all options. For correct type look at enum above. If a value isn't
      /// set in the options a correct default value is provided. </summary>
      function GetBooleanOption(Option : EnumClientOption) : boolean;
      function GetIntegerOption(Option : EnumClientOption) : integer;
      function GetSingleOption(Option : EnumClientOption) : single;
      function GetIntegerOptionClamped(Option : EnumClientOption; Min, Max : integer) : integer;
      function GetEnumOption<U : record >(Option : EnumClientOption) : U;
      function GetColorOption(Option : EnumClientOption) : RColor;
      function GetStringOption(Option : EnumClientOption) : string;
      function GetKeybinding(Option : EnumClientOption) : RBinding;
      function GetDimensionOption(Option : EnumClientOption) : RIntVector2;
      function GetVector2Option(Option : EnumClientOption) : RVector2;
      function GetVector3Option(Option : EnumClientOption) : RVector3;

      /// <summary> Setter methods for all options. Returns itself for chained operations. </summary>
      function SetBooleanOption(Option : EnumClientOption; Value : boolean) : TOptionManager;
      function SetIntegerOption(Option : EnumClientOption; Value : integer) : TOptionManager;
      function SetEnumOption<U : record >(Option : EnumClientOption; Value : U) : TOptionManager;
      function SetStringOption(Option : EnumClientOption; Value : string) : TOptionManager;
      function SetSingleOption(Option : EnumClientOption; Value : single) : TOptionManager;
      function SetKeybinding(Option : EnumClientOption; Value : RBinding) : TOptionManager;
      function SetDimensionOption(Option : EnumClientOption; Value : RIntVector2) : TOptionManager;
      function SetVector2Option(Option : EnumClientOption; Value : RVector2) : TOptionManager;
      function SetVector3Option(Option : EnumClientOption; Value : RVector3) : TOptionManager;

      procedure FireOptionEvent(Option : EnumClientOption);
      procedure FireOptionEvents(Options : SetClientOption);

      /// <summary> Creates a snapshot of the current settings. These can be restored with LoadSnapshot.
      /// A call to SaveSettings clears the snapshot. If there is already a snapshot, it will be overriden. </summary>
      procedure SaveSnapshot;
      /// <summary> Revert the options to the state of the snapshot, clearing the snapshot. For each reverted option
      /// a change event is triggered. If no snapshot has been created before, nothing happens. </summary>
      procedure LoadSnapshot;

      /// <summary> Saves and load the settings from a human readable and editble Ini-File. All
      /// identifiers and values should be easily readable. </summary>
      procedure LoadSettings;
      procedure SaveSettings;

      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  Settings : TOptionManager;

implementation

uses
  BaseConflict.Classes.Gamestates;

{ TOptionManager }

procedure TOptionManager.ClearSnapshot;
begin
  FreeAndNil(FOptionBackUp);
end;

constructor TOptionManager.Create();
begin
  FOptions := TObjectDictionary < EnumOptionType, TDictionary < EnumClientOption, string >>.Create([doOwnsValues]);
  FOptionTypeCache := TDictionary<EnumClientOption, EnumOptionType>.Create;
end;

destructor TOptionManager.Destroy;
begin
  ContentManager.UnSubscribeFromFile(FormatDateiPfad(GAMESETTINGSFILE), LoadSettingsCallback);
  ContentManager.UnSubscribeFromFile(FormatDateiPfad(CONNECTIONSETTINGSFILE), LoadSettingsCallback);
  {$IFDEF DEBUG}
  ContentManager.UnSubscribeFromFile(FormatDateiPfad(GAMEDEBUGSETTINGSFILE), LoadSettingsCallback);
  {$ENDIF}
  FOptionBackUp.Free;
  FOptions.Free;
  FOptionTypeCache.Free;
  inherited;
end;

procedure TOptionManager.FireOptionEvent(Option : EnumClientOption);
begin
  GlobalEventbus.Trigger(eiClientOption, [RParam.From<EnumClientOption>(Option)]);
end;

procedure TOptionManager.FireOptionEvents(Options : SetClientOption);
var
  Option : EnumClientOption;
begin
  for Option in Options do
      FireOptionEvent(Option);
end;

function TOptionManager.GetBooleanOption(Option : EnumClientOption) : boolean;
var
  StrResult : string;
begin
  StrResult := GetStringOption(Option);
  Result := StrToBool(StrResult) or (StrResult.ToLowerInvariant = 'true');
end;

function TOptionManager.GetColorOption(Option : EnumClientOption) : RColor;
var
  StrResult : string;
begin
  StrResult := GetStringOption(Option);
  Result := RColor.CreateFromString(StrResult);
end;

function TOptionManager.GetDefaultOption(Option : EnumClientOption) : string;
const
  sTrue  = 'True';
  sFalse = 'False';
begin
  Result := '';
  case Option of
    // General
    coGeneralLanguage : Result := '';
    coGeneralUsername : Result := '';
    coGeneralPassword : Result := '';
    coGeneralHasSecretAccess : Result := sFalse;
    coGeneralBypassMaintenance : Result := sFalse;
    coGeneralBypassLoginQueue : Result := sFalse;
    coGeneralRightClickEpsilon : Result := '35';
    coGeneralFirstStart : Result := sTrue;
    coGeneralDisableBots : Result := sFalse;
    coGeneralForceBrokerFallback : Result := sFalse;
    coGeneralForceServerOffline : Result := sFalse;
    coGeneralApiTimeout : Result := '20000';
    coGeneralEnableSpectator : Result := sFalse;

    // Engine
    coEngineOptionsStart : Result := '';

    coEngineResolution : Result := '';
    coEngineGameWindowOverride : Result := '';
    coEngineDisplayMode : Result := IntToStr(ord(dmBorderlessFullscreenWindow));
    coEngineTargetMonitor : Result := '-1';
    coEngineFileHotReload : Result := {$IFDEF DEBUG}sTrue{$ELSE}sFalse{$ENDIF};
    coEngineShadowBiasMin : Result := '0.01';
    coEngineShadowBiasMax : Result := '0.02';
    coEngineShadowSlopeBias : Result := '0.5';
    coEngineShadowClipBelow : Result := '-9.0';
    coEngineShadowClipAbove : Result := '0.0';
    coEngineShadowTweakZoom : Result := '15.0';
    coEngineCameraFoV : Result := '0.6853981635';     // 0.6853981635 -> 0.62
    coEngineGlobalShadingReduction : Result := '0.5'; // 2.75
    coEngineFMODConnectorEnabled : Result := sFalse;
    coEngineVSyncLevel : Result := '1';

    coEngineOptionsEnd : Result := '';

    // Graphics
    coGraphicsOptionsStart : Result := '';

    coGraphicsPerformanceAnalysed : Result := sFalse;
    coGraphicsShadows : Result := sTrue;
    coGraphicsDeferredShading : Result := sTrue;
    coGraphicsVSync : Result := sFalse;
    coGraphicsShadowResolution : Result := '2048';
    coGraphicsGUIBlurBackgrounds : Result := sTrue;
    coGraphicsTextureQuality : Result := IntToStr(ord(tqMaximum));
    coGraphicsPostEffectSSAO : Result := sFalse;
    coGraphicsPostEffectToon : Result := sTrue;
    coGraphicsPostEffectGlow : Result := sTrue;
    coGraphicsPostEffectFXAA : Result := sTrue;
    coGraphicsPostEffectUnsharpMasking : Result := sTrue;
    coGraphicsPostEffectDistortion : Result := sTrue;

    coGraphicsOptionsEnd : Result := '';

    // Sound
    coSoundOptionsStart : Result := '';

    coSoundMasterVolume : Result := '70';
    coSoundPlayMusic : Result := sTrue;
    coSoundMusicVolume : Result := '70';
    coSoundPlayMaster : Result := sTrue;
    coSoundBackground : Result := sFalse;
    coSoundPlayEffects : Result := sTrue;
    coSoundEffectVolume : Result := '70';
    coSoundPlayGUISound : Result := sTrue;
    coSoundGUISoundVolume : Result := '70';
    coSoundPlayPings : Result := sTrue;
    coSoundPingVolume : Result := '70';
    coSoundPlayAtmo : Result := sTrue;

    coSoundOptionsEnd : Result := '';
    coSoundMetaOptionsStart : Result := '';

    coSoundMetaMasterVolume : Result := '70';
    coSoundMetaPlayMusic : Result := sTrue;
    coSoundMetaMusicVolume : Result := '70';
    coSoundMetaPlayMaster : Result := sTrue;
    coSoundMetaBackground : Result := sFalse;
    coSoundMetaPlayGUISound : Result := sTrue;
    coSoundMetaGUISoundVolume : Result := '70';

    coSoundMetaOptionsEnd : Result := '';

    // Gameplay
    coGameplayOptionsStart : Result := '';

    coGameplayShowEffectRadius : Result := sTrue;
    coGameplayHealthbarMode : Result := IntToStr(ord(hmDamaged));
    coGameplayDragWavetemplates : Result := sFalse;
    coGameplayEndlessBuild : Result := sFalse;
    coGameplayClipCursor : Result := sTrue;
    coGameplayRightClickPanning : Result := sTrue;
    coGameplayCameraMinZoom : Result := '2.6'; // 2.6
    coGameplayCameraMaxZoom : Result := '3.8'; // 3.4 -> 4.0
    coGameplayDropZoneMode : Result := IntToStr(ord(dzAll));
    coGameplayDropValidColor : Result := '$FF00FF00';
    coGameplayDropInvalidColor : Result := '$FFFF0000';
    coGameplayPreviewValidColor : Result := '$FF00FF00';
    coGameplayPreviewInvalidColor : Result := '$FFFF0000';
    coGameplayFixedTeamColors : Result := sTrue;
    coGameplayClickPrecision : Result := '1.0';
    coGameplayScrollSpeed : Result := '40.0';
    coGameplayShowTechnicalPanel : Result := sTrue;
    coGameplayShowNumericChargeCooldown : Result := sFalse;
    coGameplayShowDeckHotkeys : Result := sFalse;

    coGameplayOptionsEnd : Result := '';

    // Sandbox
    coSandboxOptionsStart : Result := '';
    coSandboxRotationSpeed : Result := '-1.0';
    coSandboxRotationOffset : Result := '0.0';
    coSandboxTiltOffset : Result := '0.0';
    coSandboxFoVOffset : Result := '0.0';
    coSandboxSavedCameraPosition : Result := RVector2.ZERO.ToIniString;
    coSandboxFinishCamOffset : Result := RVector2.ZERO.ToIniString;
    coSandboxOptionsEnd : Result := '';

    // Menu
    coMenuOptionsStart : Result := '';

    coMenuAnimatedBackground : Result := sTrue;
    coMenuDeckbuildingGridSize : Result := IntToStr(3);
    coMenuDeckbuildingSacrificeGridSize : Result := IntToStr(12);
    coMenuLimitFramerate : Result := IntToStr(50);
    coMenuClientResolution : Result := IntToStr(TGameStateManager.CLIENT_DEFAULT_DIMENSIONS.Width) + 'x' + IntToStr(TGameStateManager.CLIENT_DEFAULT_DIMENSIONS.Height);
    coMenuClientScaling : Result := IntToStr(ord(EnumMenuScaling.msDownscaling));
    coMenuClientFullscreenFrame : Result := sFalse;
    coMenuBringToFrontOnMatchFound : Result := sTrue;

    coMenuOptionsEnd : Result := '';

    // Keybindings
    coKeybindingBindingNone : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingNoneAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingScreenshot : Result := RBinding.Create(TasteDruck).SaveToString;
    coKeybindingBindingScreenshotAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeckslot01 : Result := RBinding.Create(Taste1).SaveToString;
    coKeybindingBindingDeckslot01Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeckslot02 : Result := RBinding.Create(Taste2).SaveToString;
    coKeybindingBindingDeckslot02Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeckslot03 : Result := RBinding.Create(Taste3).SaveToString;
    coKeybindingBindingDeckslot03Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeckslot04 : Result := RBinding.Create(Taste4).SaveToString;
    coKeybindingBindingDeckslot04Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeckslot05 : Result := RBinding.Create(Taste5).SaveToString;
    coKeybindingBindingDeckslot05Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeckslot06 : Result := RBinding.Create(Taste6).SaveToString;
    coKeybindingBindingDeckslot06Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeckslot07 : Result := RBinding.Create(Taste7).SaveToString;
    coKeybindingBindingDeckslot07Alt : Result := RBinding.Create(Taste1).WithShift.SaveToString;
    coKeybindingBindingDeckslot08 : Result := RBinding.Create(Taste8).SaveToString;
    coKeybindingBindingDeckslot08Alt : Result := RBinding.Create(Taste2).WithShift.SaveToString;
    coKeybindingBindingDeckslot09 : Result := RBinding.Create(Taste9).SaveToString;
    coKeybindingBindingDeckslot09Alt : Result := RBinding.Create(Taste3).WithShift.SaveToString;
    coKeybindingBindingDeckslot10 : Result := RBinding.Create(Taste0).SaveToString;
    coKeybindingBindingDeckslot10Alt : Result := RBinding.Create(Taste4).WithShift.SaveToString;
    coKeybindingBindingDeckslot11 : Result := RBinding.Create(Tasteß).SaveToString;
    coKeybindingBindingDeckslot11Alt : Result := RBinding.Create(Taste5).WithShift.SaveToString;
    coKeybindingBindingDeckslot12 : Result := RBinding.Create(TasteAkzent).SaveToString;
    coKeybindingBindingDeckslot12Alt : Result := RBinding.Create(Taste6).WithShift.SaveToString;
    coKeybindingBindingSpellCast : Result := RBinding.Create(mbLeft).SaveToString;
    coKeybindingBindingSpellCastAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingSpellCastRepeat : Result := RBinding.Create(mbLeft).WithShift.SaveToString;
    coKeybindingBindingSpellCastRepeatAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPingGeneric : Result := RBinding.Create(TasteF).SaveToString;
    coKeybindingBindingPingGenericAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPingAttack : Result := RBinding.Create(TasteC).SaveToString;
    coKeybindingBindingPingAttackAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPingDefend : Result := RBinding.Create(TasteV).SaveToString;
    coKeybindingBindingPingDefendAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingUnitSelect : Result := RBinding.Create(mbLeft).SaveToString;
    coKeybindingBindingUnitSelectAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingMainAction : Result := RBinding.Create(mbLeft).SaveToString;
    coKeybindingBindingMainActionAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingSecondaryAction : Result := RBinding.Create(mbRight).SaveToString;
    coKeybindingBindingSecondaryActionAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingMainCancel : Result := RBinding.Create(TasteEsc).SaveToString;
    coKeybindingBindingMainCancelAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingNexusJump : Result := RBinding.Create(TasteLeerTaste).SaveToString;
    coKeybindingBindingNexusJumpAlt : Result := RBinding.Create(mbMiddle).SaveToString;
    coKeybindingBindingScoreboardHold : Result := RBinding.Create(TasteTabulator).SaveToString;
    coKeybindingBindingScoreboardHoldAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingGUIToggle : Result := RBinding.Create(TasteY).WithAlt.SaveToString;
    coKeybindingBindingGUIToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingSandboxGUIToggle : Result := RBinding.Create(TasteX).WithAlt.SaveToString;
    coKeybindingBindingSandboxGUIToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCaptureMode : Result := RBinding.Create(TasteP).SaveToString;
    coKeybindingBindingCaptureModeAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraLeft : Result := RBinding.Create(TasteA).SaveToString;
    coKeybindingBindingCameraLeftAlt : Result := RBinding.Create(TastePfeilLinks).SaveToString;
    coKeybindingBindingCameraUp : Result := RBinding.Create(TasteW).SaveToString;
    coKeybindingBindingCameraUpAlt : Result := RBinding.Create(TastePfeilOben).SaveToString;
    coKeybindingBindingCameraRight : Result := RBinding.Create(TasteD).SaveToString;
    coKeybindingBindingCameraRightAlt : Result := RBinding.Create(TastePfeilRechts).SaveToString;
    coKeybindingBindingCameraDown : Result := RBinding.Create(TasteS).SaveToString;
    coKeybindingBindingCameraDownAlt : Result := RBinding.Create(TastePfeilUnten).SaveToString;
    coKeybindingBindingCameraLaneLeft : Result := RBinding.Create(TasteQ).SaveToString;
    coKeybindingBindingCameraLaneLeftAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraLaneRight : Result := RBinding.Create(TasteE).SaveToString;
    coKeybindingBindingCameraLaneRightAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraRise : Result := RBinding.Create(TasteLeerTaste).SaveToString;
    coKeybindingBindingCameraRiseAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraFall : Result := RBinding.Create(TasteC).SaveToString;
    coKeybindingBindingCameraFallAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraPanning : Result := RBinding.Create(mbRight).SaveToString;
    coKeybindingBindingCameraPanningAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraMoveTo : Result := RBinding.Create(mbRight).WithShift.SaveToString;
    coKeybindingBindingCameraMoveToAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraResetZoom : Result := RBinding.Create(mbMiddle).WithShift.SaveToString;
    coKeybindingBindingCameraResetZoomAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingCameraToggleRotation : Result := RBinding.Create(TasteR).WithStrg.SaveToString;
    coKeybindingBindingCameraToggleRotationAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander01 : Result := RBinding.Create(TasteF1).SaveToString;
    coKeybindingBindingChangeCommander01Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander02 : Result := RBinding.Create(TasteF2).SaveToString;
    coKeybindingBindingChangeCommander02Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander03 : Result := RBinding.Create(TasteF3).SaveToString;
    coKeybindingBindingChangeCommander03Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander04 : Result := RBinding.Create(TasteF4).SaveToString;
    coKeybindingBindingChangeCommander04Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander05 : Result := RBinding.Create(TasteF5).SaveToString;
    coKeybindingBindingChangeCommander05Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander06 : Result := RBinding.Create(TasteF6).SaveToString;
    coKeybindingBindingChangeCommander06Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander07 : Result := RBinding.Create(TasteF7).SaveToString;
    coKeybindingBindingChangeCommander07Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander08 : Result := RBinding.Create(TasteF8).SaveToString;
    coKeybindingBindingChangeCommander08Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander09 : Result := RBinding.Create(TasteF9).SaveToString;
    coKeybindingBindingChangeCommander09Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander10 : Result := RBinding.Create(TasteF10).SaveToString;
    coKeybindingBindingChangeCommander10Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander11 : Result := RBinding.Create(TasteF11).SaveToString;
    coKeybindingBindingChangeCommander11Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingChangeCommander12 : Result := RBinding.Create(TasteF12).SaveToString;
    coKeybindingBindingChangeCommander12Alt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDrawTerrainToggle : Result := RBinding.Create(TasteT).WithAlt.WithShift.WithStrg.SaveToString;
    coKeybindingBindingDrawTerrainToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDrawWaterToggle : Result := RBinding.Create(TasteW).WithAlt.WithShift.SaveToString;
    coKeybindingBindingDrawWaterToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDrawVegetationToggle : Result := RBinding.Create(TasteV).WithAlt.WithShift.SaveToString;
    coKeybindingBindingDrawVegetationToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingDeferredShadingToggle : Result := RBinding.Create(TasteD).WithAlt.WithShift.SaveToString;
    coKeybindingBindingDeferredShadingToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingNormalmappingToggle : Result := RBinding.Create(TasteN).WithAlt.WithShift.SaveToString;
    coKeybindingBindingNormalmappingToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingShadowTechniqueToggle : Result := RBinding.Create(TasteS).WithAlt.WithShift.SaveToString;
    coKeybindingBindingShadowTechniqueToggleAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingTerrainEditor : Result := RBinding.Create(TasteT).WithAlt.WithShift.SaveToString;
    coKeybindingBindingTerrainEditorAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingGUIEditor : Result := RBinding.Create(TasteG).WithAlt.WithShift.SaveToString;
    coKeybindingBindingGUIEditorAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPostEffectEditor : Result := RBinding.Create(TasteP).WithAlt.WithShift.SaveToString;
    coKeybindingBindingPostEffectEditorAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingForceGameTick : Result := RBinding.Create(TasteEnter).SaveToString;
    coKeybindingBindingForceGameTickAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingHitboxToggleVisibility : Result := RBinding.Create(TasteÄ).WithAlt.WithShift.SaveToString;
    coKeybindingBindingHitboxToggleVisibilityAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingHealthbarsToggleVisibility : Result := RBinding.Create(TasteH).WithAlt.WithShift.SaveToString;
    coKeybindingBindingHealthbarsToggleVisibilityAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPathfindingVisualize : Result := RBinding.Create(TasteP).WithStrg.SaveToString;
    coKeybindingBindingPathfindingVisualizeAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPathfindingCoordinate : Result := RBinding.Create(TasteC).WithStrg.SaveToString;
    coKeybindingBindingPathfindingCoordinateAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPathfindingFlow : Result := RBinding.Create(TasteF).WithStrg.SaveToString;
    coKeybindingBindingPathfindingFlowAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPathfindingIncVisibleLength : Result := RBinding.Create(TastePlus).WithStrg.SaveToString;
    coKeybindingBindingPathfindingIncVisibleLengthAlt : Result := RBinding.EMPTY.SaveToString;
    coKeybindingBindingPathfindingDecVisibleLength : Result := RBinding.Create(TasteMinus).WithStrg.SaveToString;
    coKeybindingBindingPathfindingDecVisibleLengthAlt : Result := RBinding.EMPTY.SaveToString;

    // Server
    coServerWebApiServer : Result := 'https://riseoflegions.com';
    coServerBugReportServer : Result := 'https://riseoflegions.com/api/account/bugreport/';

    // Debug
    coDebugSkipLoadingScreen : Result := sFalse;
    coDebugUseLocalTestServer : Result := sFalse;
    coDebugHideMapEnvironment : Result := sFalse;
    coDebugLocalTestServerIP : Result := 'localhost';
    coDebugLocalTestServerToken : Result := '1';
    coDebugEmulateRelease : Result := sFalse;
  else
    begin
      HLog.Write(elWarning, 'There should be a default value for option ' + HRTTI.EnumerationToString<EnumClientOption>(Option) + ' !');
      Result := '';
    end;
  end;
end;

function TOptionManager.GetDimensionOption(Option : EnumClientOption) : RIntVector2;
var
  VectorRaw : string;
begin
  VectorRaw := GetStringOption(Option);
  if not HSystem.TryParseResolution(VectorRaw, Result.X, Result.Y) then
      Result := RIntVector2.ZERO;
end;

function TOptionManager.GetEnumOption<U>(Option : EnumClientOption) : U;
var
  IntResult : integer;
begin
  IntResult := GetIntegerOption(Option);
  if not HRTTI.TryIntegerToEnumeration<U>(IntResult, Result) then
      Result := default (U);
end;

function TOptionManager.GetIntegerOption(Option : EnumClientOption) : integer;
var
  StrResult : string;
begin
  StrResult := GetStringOption(Option);
  if not TryStrToInt(StrResult, Result) then
    if not TryStrToInt(GetDefaultOption(Option), Result) then
        Result := 0;
end;

function TOptionManager.GetIntegerOptionClamped(Option : EnumClientOption; Min, Max : integer) : integer;
begin
  Result := HMath.Clamp(GetIntegerOption(Option), Min, Max);
end;

function TOptionManager.GetKeybinding(Option : EnumClientOption) : RBinding;
var
  BindingRaw : string;
begin
  BindingRaw := GetStringOption(Option);
  Result := RBinding.CreateFromString(BindingRaw)
end;

function TOptionManager.GetSingleOption(Option : EnumClientOption) : single;
var
  StrResult : string;
begin
  StrResult := GetStringOption(Option);
  if not TryStrToFloat(StrResult, Result, EngineFloatFormatSettings) then
    if not TryStrToFloat(GetDefaultOption(Option), Result, EngineFloatFormatSettings) then
        Result := 0.0;
end;

function TOptionManager.GetStringOption(Option : EnumClientOption) : string;
var
  dict : TDictionary<EnumClientOption, string>;
  OptionType : EnumOptionType;
begin
  OptionType := OptionToOptionType(Option);
  if not FOptions.TryGetValue(OptionType, dict) then Result := GetDefaultOption(Option)
  else
    if not dict.TryGetValue(Option, Result) then Result := GetDefaultOption(Option);
end;

function TOptionManager.GetVector2Option(Option : EnumClientOption) : RVector2;
var
  VectorRaw : string;
begin
  VectorRaw := GetStringOption(Option);
  Result := RVector2.CreateFromIniString(VectorRaw);
end;

function TOptionManager.GetVector3Option(Option : EnumClientOption) : RVector3;
var
  VectorRaw : string;
begin
  VectorRaw := GetStringOption(Option);
  Result := RVector3.CreateFromIniString(VectorRaw);
end;

function TOptionManager.IsSet(Option : EnumClientOption) : boolean;
var
  OptionType : EnumOptionType;
  dict : TDictionary<EnumClientOption, string>;
begin
  OptionType := OptionToOptionType(Option);
  if not FOptions.TryGetValue(OptionType, dict) then Result := False
  else Result := dict.ContainsKey(Option);
end;

function TOptionManager.IsSetNotNone(Option : EnumClientOption) : boolean;
begin
  Result := IsSet(Option) and (GetStringOption(Option) <> '');
end;

function TOptionManager.SetBooleanOption(Option : EnumClientOption; Value : boolean) : TOptionManager;
begin
  Result := SetStringOption(Option, BoolToStr(Value, True));
end;

function TOptionManager.SetDimensionOption(Option : EnumClientOption; Value : RIntVector2) : TOptionManager;
begin
  Result := SetStringOption(Option, Value.X.ToString + 'x' + Value.Y.ToString);
end;

function TOptionManager.SetEnumOption<U>(Option : EnumClientOption; Value : U) : TOptionManager;
begin
  Result := SetIntegerOption(Option, HRTTI.EnumerationToInteger<U>(Value));
end;

function TOptionManager.SetIntegerOption(Option : EnumClientOption; Value : integer) : TOptionManager;
begin
  Result := SetStringOption(Option, IntToStr(Value));
end;

function TOptionManager.SetKeybinding(Option : EnumClientOption; Value : RBinding) : TOptionManager;
begin
  Result := SetStringOption(Option, Value.SaveToString);
end;

function TOptionManager.SetSingleOption(Option : EnumClientOption; Value : single) : TOptionManager;
begin
  Result := SetStringOption(Option, HConvert.FloatToStr(Value));
end;

function TOptionManager.SetStringOption(Option : EnumClientOption; Value : string) : TOptionManager;
var
  dict : TDictionary<EnumClientOption, string>;
  OptionType : EnumOptionType;
begin
  Result := self;
  OptionType := OptionToOptionType(Option);
  if not FOptions.TryGetValue(OptionType, dict) then
  begin
    dict := TDictionary<EnumClientOption, string>.Create();
    FOptions.Add(OptionType, dict);
  end;

  // don't do anything if value wouldn't change
  if dict.ContainsKey(Option) and (dict[Option] = Value) then exit;

  dict.AddOrSetValue(Option, Value);
  FireOptionEvent(Option);
end;

function TOptionManager.SetVector2Option(Option : EnumClientOption; Value : RVector2) : TOptionManager;
begin
  Result := SetStringOption(Option, Value.ToIniString);
end;

function TOptionManager.SetVector3Option(Option : EnumClientOption; Value : RVector3) : TOptionManager;
begin
  Result := SetStringOption(Option, Value.ToIniString);
end;

procedure TOptionManager.LoadSettings;
begin
  // user changable settings
  LoadSettingsFromFile(FormatDateiPfad(GAMESETTINGSFILE));
  // set settings
  LoadSettingsFromFile(FormatDateiPfad(CONNECTIONSETTINGSFILE));
  {$IFDEF DEBUG}
  // if debug override all specified things with debugsettings
  LoadSettingsFromFile(FormatDateiPfad(GAMEDEBUGSETTINGSFILE));
  {$ENDIF}
end;

procedure TOptionManager.LoadSettingsCallback(const FilePath, FileContent : string);
var
  IniFile : TMemIniFile;
  Sections, Keys : TStrings;
  i, j : integer;
  Section, Key : string;
  OptionType : EnumOptionType;
  Option : EnumClientOption;
  s : TStrings;
begin
  IniFile := TMemIniFile.Create('');
  s := TStringList.Create;
  s.CommaText := FileContent;
  IniFile.SetStrings(s);
  s.Free;
  Sections := TStringList.Create;
  IniFile.ReadSections(Sections);
  for i := 0 to Sections.Count - 1 do
  begin
    Section := Sections[i];

    if not HRTTI.TryStringToEnumeration<EnumOptionType>('ot' + Section, OptionType) then continue;

    Keys := TStringList.Create;
    IniFile.ReadSection(Section, Keys);
    for j := 0 to Keys.Count - 1 do
    begin
      Key := Keys[j];
      if TryStringToOption(Key, OptionType, Option) then
      begin
        SetStringOption(Option, IniFile.ReadString(Section, Key, ''));
      end;
    end;
    Keys.Free;
  end;
  Sections.Free;
  IniFile.Free;
end;

procedure TOptionManager.LoadSettingsFromFile(FilePath : string);
begin
  if FileExists(FilePath) then
      ContentManager.SubscribeToFile(FilePath, LoadSettingsCallback);
end;

procedure TOptionManager.LoadSnapshot;
var
  temp : TObjectDictionary<EnumOptionType, TDictionary<EnumClientOption, string>>;
  Key : EnumOptionType;
  SubKey : EnumClientOption;
  ChangedOptions : SetClientOption;
begin
  if assigned(FOptionBackUp) then
  begin
    temp := FOptions;
    FOptions := FOptionBackUp;
    FOptionBackUp := nil;

    // trigger events, assume that since SaveSnapshot no values has been deleted
    ChangedOptions := [];
    for Key in temp.Keys do
    begin
      for SubKey in temp[Key].Keys do
      begin
        if not FOptions.ContainsKey(Key) or not FOptions[Key].ContainsKey(SubKey) or (FOptions[Key][SubKey] <> temp[Key][SubKey]) then
            include(ChangedOptions, SubKey);
      end;
    end;
    FireOptionEvents(ChangedOptions);
    temp.Free;
  end;
end;

function TOptionManager.TryStringToOption(Option : string; Category : EnumOptionType; out OptionEnum : EnumClientOption) : boolean;
var
  temp : string;
begin
  temp := HRTTI.EnumerationToString<EnumOptionType>(Category);
  temp := HString.TrimBeforeCaseInsensitive('ot', temp);
  temp := 'co' + temp + Option;
  Result := HRTTI.TryStringToEnumeration<EnumClientOption>(temp, OptionEnum);
end;

function TOptionManager.OptionToOptionType(Option : EnumClientOption) : EnumOptionType;
var
  raw, temp, temp2 : string;
  OptionType : EnumOptionType;
begin
  if not FOptionTypeCache.TryGetValue(Option, Result) then
  begin
    raw := HRTTI.EnumerationToString<EnumClientOption>(Option);
    temp := HString.TrimBeforeCaseInsensitive('co', raw.ToLowerInvariant);
    for OptionType := low(EnumOptionType) to high(EnumOptionType) do
    begin
      temp2 := HRTTI.EnumerationToString<EnumOptionType>(OptionType);
      temp2 := HString.TrimBeforeCaseInsensitive('ot', temp2.ToLowerInvariant);
      if temp.StartsWith(temp2) then
      begin
        FOptionTypeCache.Add(Option, OptionType);
        exit(OptionType);
      end;
    end;
    raise ENotFoundException.Create('Could''t find OptionType for ' + raw + '! Did you followed the naming convention?');
  end;
end;

function TOptionManager.OptionToString(Option : EnumClientOption; Category : EnumOptionType) : string;
var
  OptionTypeString : string;
begin
  OptionTypeString := HRTTI.EnumerationToString<EnumOptionType>(Category);
  OptionTypeString := HString.TrimBeforeCaseInsensitive('ot', OptionTypeString);

  Result := HRTTI.EnumerationToString<EnumClientOption>(Option);
  Result := HString.TrimBeforeCaseInsensitive('co' + OptionTypeString, Result);
end;

function TOptionManager.OptionTypeToString(OptionType : EnumOptionType) : string;
begin
  Result := HRTTI.EnumerationToString<EnumOptionType>(OptionType);
  Result := HString.TrimBeforeCaseInsensitive('ot', Result);
end;

procedure TOptionManager.RevertOption(Option : EnumClientOption);
begin
  SetStringOption(Option, GetDefaultOption(Option));
end;

procedure TOptionManager.SaveSettings;
begin
  SaveSettingsToFile(AbsolutePath(GAMESETTINGSFILE));
end;

procedure TOptionManager.SaveSettingsToFile(FilePath : string);
var
  IniFile : TIniFile;
  OptionType : EnumOptionType;
  Option : EnumClientOption;
begin
  IniFile := nil;
  RenameFile(FilePath, FilePath + '.bak');
  DeleteFile(FilePath);
  try
    try
      IniFile := TIniFile.Create(FilePath);
      for OptionType in FOptions.Keys do
      begin
        // don't save debug options and keybdindings have special save method
        if (OptionType in [otDebug, otServer]) then continue;

        for Option in FOptions[OptionType].Keys do
          // write only if different to defaults
          if FOptions[OptionType][Option] <> GetDefaultOption(Option) then
          begin
            IniFile.WriteString(OptionTypeToString(OptionType), OptionToString(Option, OptionType), FOptions[OptionType][Option]);
          end;
      end;
      // Flush buffer
      IniFile.UpdateFile;
    except
      RenameFile(FilePath + '.bak', FilePath);
    end;
  finally
    IniFile.Free;
  end;
  DeleteFile(FilePath + '.bak');
end;

procedure TOptionManager.SaveSnapshot;
var
  Key : EnumOptionType;
  SubKey : EnumClientOption;
  dict : TDictionary<EnumClientOption, string>;
begin
  ClearSnapshot;
  // make a deep copy of the settings
  FOptionBackUp := TObjectDictionary < EnumOptionType, TDictionary < EnumClientOption, string >>.Create([doOwnsValues]);
  for Key in FOptions.Keys do
  begin
    dict := TDictionary<EnumClientOption, string>.Create;
    for SubKey in FOptions[Key].Keys do
    begin
      dict.Add(SubKey, FOptions[Key][SubKey]);
    end;
    FOptionBackUp.Add(Key, dict);
  end;
end;

initialization

ScriptManager.ExposeType(TypeInfo(EnumClientOption));

end.
