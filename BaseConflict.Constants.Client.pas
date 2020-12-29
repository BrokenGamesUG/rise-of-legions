unit BaseConflict.Constants.Client;

interface

uses
  generics.Collections,
  Math,
  SysUtils,
  RegularExpressions,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Script,
  BaseConflict.API.Types,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards;

const

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$IF Defined(SERVER)and not Defined(SHUTUP)}
  This should not be part of the server !
  {$ENDIF}
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// General
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////

  // Camera

    CAMERAOFFSET : RVector3 = (X : - 0.394721269607544; Y : 0.812130928039551; Z : - 0.429695725440979);
  CAMERAMOVEMENTWEIGHT      = 0.010;
  ZOOMSPEED                 = 0.2;
  GROUND_EPSILON            = 0.01;
  FLYING_HEIGHT             = 3.5;
  SPAWNER_FLYING_HEIGHT     = 1.0;
  TUTORIAL_SLIDE_COUNT      = 5;

  // Minimap
  MINIMAP_SCALE : RVector2           = (X : 1.8; Y : 1.8);
  MINIMAP_ROTATIONAL_OFFSET : Single = 37.25; // added to rotation of minimap

  TIME_OFFSET_ENDSCREEN  = 4000;                         // Time to wait before showing Victory/Defeat-Screen
  TIME_TO_FINISH_GAME    = TIME_OFFSET_ENDSCREEN + 7000; // Time to wait before automatically exit game to statistic screen
  SERVER_CRASHED_TIMEOUT = 5000;

  // Game States
  GAMESTATE_INGAME        = 'Game';
  GAMESTATE_LOADGAMESTATE = 'LoadGame';
  GAMESTATE_MAINMENU      = 'MainMenu';
  GAMESTATE_LOGINSTEAM    = 'LoginSteamMenu';
  GAMESTATE_LOGIN_QUEUE   = 'LoginQueue';
  GAMESTATE_RECONNECT     = 'Reconnect';
  GAMESTATE_SERVER_DOWN   = 'ServerDown';
  GAMESTATE_MAINTENANCE   = 'Maintenance';

type

  // actions with keybinding
  EnumKeybinding = (
    kbNone,
    // general
    kbScreenshot,
    // core
    kbDeckslot01,
    kbDeckslot02,
    kbDeckslot03,
    kbDeckslot04,
    kbDeckslot05,
    kbDeckslot06,
    kbDeckslot07,
    kbDeckslot08,
    kbDeckslot09,
    kbDeckslot10,
    kbDeckslot11,
    kbDeckslot12,
    kbSpellCast,
    kbSpellCastRepeat,
    kbPingGeneric,
    kbPingAttack,
    kbPingDefend,
    kbUnitSelect,
    kbMainAction,
    kbSecondaryAction,
    kbMainCancel,
    kbNexusJump,
    kbScoreboardHold,
    kbGUIToggle,
    kbSandboxGUIToggle,
    kbCaptureMode,

    kbCameraLeft,
    kbCameraUp,
    kbCameraRight,
    kbCameraDown,
    kbCameraLaneLeft,
    kbCameraLaneRight,
    kbCameraRise,
    kbCameraFall,
    kbCameraPanning,
    kbCameraMoveTo,
    kbCameraResetZoom,
    kbCameraToggleRotation,
    // debug
    kbChangeCommander01,
    kbChangeCommander02,
    kbChangeCommander03,
    kbChangeCommander04,
    kbChangeCommander05,
    kbChangeCommander06,
    kbChangeCommander07,
    kbChangeCommander08,
    kbChangeCommander09,
    kbChangeCommander10,
    kbChangeCommander11,
    kbChangeCommander12,
    kbDrawTerrainToggle,
    kbDrawWaterToggle,
    kbDrawVegetationToggle,
    kbDeferredShadingToggle,
    kbNormalmappingToggle,
    kbShadowTechniqueToggle,
    kbTerrainEditor,
    kbGUIEditor,
    kbPostEffectEditor,
    kbForceGameTick,
    kbHitboxToggleVisibility,
    kbHealthbarsToggleVisibility,
    kbPathfindingVisualize,
    kbPathfindingCoordinate,
    kbPathfindingFlow,
    kbPathfindingIncVisibleLength,
    kbPathfindingDecVisibleLength
    );

const

  TEAMCOLORS : array [0 .. 5] of Cardinal = (
    ($FF404040), // NPC is grey
    ($FF0090FF), // first team blue
    ($FFFF0000), // second team red
    ($FFFF0000), // third team purple
    ($FF00FF00), // fourth team green
    ($FFFF0000)  // ai team is red for PvE Maps atm
    );

  // (ecColorless, ecBlack, ecGreen, ecRed, ecBlue, ecWhite)
  ENTITY_COLOR_MAP : array [EnumEntityColor] of Cardinal = (
    ($FF8080A0), // ecColorless
    ($FF000000), // ecBlack
    ($FF51BF26), // ecGreen
    ($FFFF5A00), // ecRed
    ($FF238EE8), // ecBlue
    ($FFFEFF98)  // ecWhite
    );

  GLOW_COLOR_MAP : array [EnumEntityColor] of Cardinal = (
    ($FF8080A0), // ecColorless
    ($FF327AA2), // ecBlack
    ($FF80E92B), // ecGreen // ($FF2A5700), // ecGreen
    ($FFB83E26), // ecRed
    ($FF5BA9FF), // ecBlue // ($FF71D4D4),
    ($FFFEFF98)  // ecWhite // ($FF6E6F42)  // ecWhite
    );

  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// Animation
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////

  BIND_ZONE_CENTER        = 'center';
  BIND_ZONE_HIT_ZONE      = BIND_ZONE_CENTER;
  BIND_ZONE_HIT_ZONE_AIR  = 'hit_zone_air';
  BIND_ZONE_WEAPON_MUZZLE = 'muzzle';
  BIND_ZONE_WEAPON        = 'weapon';
  BIND_ZONE_HEAD          = 'head';
  BIND_ZONE_TOP           = 'top';
  BIND_ZONE_GROUND        = 'ground';
  BIND_ZONE_BOTTOM        = 'bottom';
  BIND_ZONE_PIVOT         = 'pivot';

  ANIMATION_SPAWN            = 'spawn';
  ANIMATION_DEATH            = 'death';
  ANIMATION_WALK             = 'walk';
  ANIMATION_STAND            = 'stand';
  ANIMATION_ATTACK           = 'attack';
  ANIMATION_ATTACK2          = 'attack2';
  ANIMATION_ATTACK_AIR       = 'attackair';
  ANIMATION_ATTACK_AIR2      = 'attackair2';
  ANIMATION_ATTACK_LOOP      = 'attack_loop';
  ANIMATION_ABILITY_1        = 'ability_1';
  FBX_DEFAULT_ANIMATIONTRACK = 'AnimStack::Take 001';

  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// GUI
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////
  /// /////////////////////////////////////////////////////////////////////////

  // Cursors

  crIngame      = 10;
  crIngameHover = 11;

  /// /////////////////////////////////////////////////////////////////////////
  /// Paths
  /// /////////////////////////////////////////////////////////////////////////

  PATH_LANG                   = '\Lang\';
  PATH_GRAPHICS               = '\Graphics\';
  PATH_FONT                   = PATH_GRAPHICS + 'Fonts\';
  PATH_PRECOMPILEDSHADER      = '\PrecompiledDX11Shaders\';
  PATH_PRECOMPILEDSHADERCACHE = '\PrecompiledDX11ShadersCached\';

  PATH_AUDIO = '\Sound\';

  PATH_GRAPHICS_GAMEPLAY                = PATH_GRAPHICS + 'Gameplay\';
  PATH_GRAPHICS_ENVIRONMENT             = PATH_GRAPHICS + 'Environment\';
  PATH_GRAPHICS_EFFECTS                 = PATH_GRAPHICS + 'Effects\';
  PATH_GRAPHICS_SHADER                  = PATH_GRAPHICS_EFFECTS + 'Shader\';
  PATH_GRAPHICS_EFFECTS_MESHES          = PATH_GRAPHICS_EFFECTS + 'Meshes\';
  PATH_GRAPHICS_EFFECTS_TEXTURES        = PATH_GRAPHICS_EFFECTS + 'Textures\';
  PATH_GRAPHICS_PARTICLE_EFFECTS        = PATH_GRAPHICS_EFFECTS + 'ParticleEffects\';
  PATH_GRAPHICS_PARTICLE_EFFECTS_SHARED = PATH_GRAPHICS_PARTICLE_EFFECTS + 'Shared\';
  PATH_GRAPHICS_UNITS                   = PATH_GRAPHICS + 'Units\';

  PATH_GUI                     = PATH_GRAPHICS + 'GUI\';
  PATH_GUI_SHARED              = PATH_GUI + 'Shared\';
  PATH_GUI_SHARED_DECK_ICONS   = PATH_GUI_SHARED + 'Icons\';
  PATH_GUI_SHARED_PLAYER_ICONS = PATH_GUI_SHARED + 'Icons\';

  PATH_GUI_RELATIVE_SHARED                    = 'Shared\';
  PATH_GUI_RELATIVE_SHARED_ABILITY_ICONS_PATH = PATH_GUI_RELATIVE_SHARED + 'AbilityIcons\';
  PATH_GUI_RELATIVE_SHARED_FACTION_ICONS_PATH = PATH_GUI_RELATIVE_SHARED + 'FactionIcons\';
  PATH_GUI_RELATIVE_SHARED_CARD_ICONS_PATH    = PATH_GUI_RELATIVE_SHARED + 'CardIcons\';
  PATH_GUI_RELATIVE_SHARED_UNIT_ICONS_PATH    = PATH_GUI_RELATIVE_SHARED + 'UnitIcons\';
  PATH_GUI_RELATIVE_SHARED_SHOP_ICONS_PATH    = PATH_GUI_RELATIVE_SHARED + 'ShopIcons\';
  PATH_GUI_RELATIVE_SHARED_BACKGROUND_PATH    = PATH_GUI_RELATIVE_SHARED + 'AnimatedBackground\';
  PATH_GUI_RELATIVE_SHARED_PLAYER_ICONS       = PATH_GUI_RELATIVE_SHARED + 'Icons\';
  PATH_GUI_RELATIVE_SHARED_DECK_ICONS         = PATH_GUI_RELATIVE_SHARED + 'Icons\';
  PATH_GUI_RELATIVE_SHARED_LEAGUE_ICONS       = PATH_GUI_RELATIVE_SHARED + 'LeagueIcons\';
  PATH_GUI_RELATIVE_SHARED_CURRENCY_ICONS     = PATH_GUI_RELATIVE_SHARED + 'CurrencyIcons\';
  PATH_GUI_RELATIVE_SHARED_TUTORIAL_SHEETS    = PATH_GUI_RELATIVE_SHARED + 'TutorialSheets\';

  PATH_CURSOR                       = PATH_GUI + 'Cursors\';
  PATH_HINT                         = PATH_GUI + 'Hints';
  PATH_HUD                          = PATH_GUI + 'HUD\';
  PATH_HUD_RELATIVE                 = 'HUD\';
  PATH_STYLESHEETS                  = PATH_GUI + 'Stylesheets\';
  PATH_HUD_UNITBARS                 = PATH_HUD + 'Unitbars\';
  PATH_HUD_DECK                     = PATH_HUD + 'DeckPanel\';
  PATH_HUD_TECHNICAL                = PATH_HUD + 'TechnicalPanel\';
  PATH_HUD_TUTORIAL                 = PATH_HUD + 'Tutorial\';
  PATH_HUD_TOOLTIP                  = PATH_HUD + 'InfoPanel\';
  PATH_HUD_TOOLTIP_RELATIVE         = PATH_HUD_RELATIVE + 'InfoPanel\';
  PATH_HUD_TOOLTIP_ARMOR_ICONS      = PATH_HUD_TOOLTIP_RELATIVE + 'Armor\';
  PATH_HUD_TOOLTIP_ATTACK_ICONS     = PATH_HUD_TOOLTIP_RELATIVE + 'Attack\';
  PATH_HUD_MINIMAP                  = PATH_HUD + 'MinimapPanel\';
  PATH_HUD_FINALSCREEN              = PATH_HUD + 'FinalScreen\';
  PATH_LOADINGSCREEN                = PATH_GUI + 'LoadingScreen\';
  PATH_LOGINMENU                    = PATH_GUI + 'LoginMenu\';
  PATH_MAINMENU                     = 'MainMenu\';
  PATH_MAINMENU_SHARED              = PATH_MAINMENU + 'Shared\';
  PATH_MAINMENU_SHARED_CARD         = PATH_MAINMENU_SHARED + 'Card\';
  PATH_MAINMENU_TEAMBUILDING        = PATH_MAINMENU + 'IntoTheGame\';
  PATH_MAINMENU_FRIENDLIST          = PATH_MAINMENU + 'SocialSystem\';
  PATH_MAINMENU_CHAT                = PATH_MAINMENU + 'SocialSystem\';
  PATH_MAINMENU_CHAT_NOTIFICATIONS  = PATH_MAINMENU_CHAT + 'Notifications\';
  PATH_MAINMENU_DECKBUILDING        = PATH_MAINMENU + 'Deckbuilding\';
  PATH_MAINMENU_DECKBUILDING_LIST   = PATH_MAINMENU_DECKBUILDING + 'Decklist\';
  PATH_MAINMENU_DECKBUILDING_EDITOR = PATH_MAINMENU_DECKBUILDING + 'Deckeditor\';
  PATH_MAINMENU_SHOP                = PATH_MAINMENU + 'Shop\';
  PATH_MAINMENU_COLLECTION          = PATH_MAINMENU + 'Collection\';
  PATH_SPELLTARGET                  = PATH_GUI + 'Spelltarget\';

  /// /////////////////////////////////////////////////////////////////////////
  /// Framed GUI-Hierarchy, Managed by BaseConflict.Classes.Gamestates.HGUIFrameManager
  /// Frames are ordered in a tree, showing a frame is showing the frame and all it parent nodes
  /// /////////////////////////////////////////////////////////////////////////

  GUI_ROOT_MAIN_FILENAME        = PATH_GUI + 'Main.dui';
  GUI_ROOT_LOGIN_QUEUE_FILENAME = PATH_GUI + 'LoginQueue.dui';
  GUI_ROOT_RECONNECT_FILENAME   = PATH_GUI + 'Reconnect.dui';
  GUI_ROOT_MAINMENU_FILENAME    = PATH_GUI + 'MainMenu.dui';
  GUI_ROOT_SERVER_DOWN_FILENAME = PATH_GUI + 'ServerDown.dui';
  GUI_ROOT_MAINTENANCE_FILENAME = PATH_GUI + 'Maintenance.dui';
  GUI_ROOT_LOADING_FILENAME     = PATH_GUI + 'LoadingScreen.dui';
  GUI_ROOT_CORE_GAME_FILENAME   = PATH_GUI + 'Game.dui';

  /// /////////////////////////////////////////////////////////////////////////
  /// Misc
  /// /////////////////////////////////////////////////////////////////////////

  PATH_HINT_DEFAULT              = PATH_HINT + '\DefaultHint.gco';
  HUD_SELECTION_TEXTURE          = PATH_HUD + '\Selection.png';
  HUD_BUILDING_SELECTION_TEXTURE = PATH_HUD + '\SelectionBuilding.png';
  HUD_SELECTION_RANGE_TEXTURE    = PATH_GUI + 'Spelltarget\SpelltargetGeneric.png';
  HEALTHBARWRAPPER               = 'Healhtbars';
  COMMANDERSWITCH                = 'CommanderSwitch';
  TIMEDISPLAY                    = 'TimeDisplay';
  BUILDGRID_MESH_PATH            = PATH_GRAPHICS_GAMEPLAY + 'Buildgrid\Buildgrid%d.xml';
  PATH_GRAPHICS_GAMPLAY_ZONE     = PATH_GRAPHICS_GAMEPLAY + 'Zone\';
  BUILDGRID_MESH_PATH_COUNT      = 4;
  PRELOADER_CACHE_FILENAME       = 'PreloaderCache.xml';

  // Feedback Form
  FEEDBACK_TOGGLE_BUTTON = 'FeedbackButton';
  FEEDBACK_FORM          = 'FeedbackFormWrapper';
  FEEDBACK_TEXT          = 'FeedbackInput';
  FEEDBACK_SUBMIT_BUTTON = 'FeedbackSubmitButton';

  /// /////////////////////////////////////////////////////////////////////////
  /// Login Menu
  /// /////////////////////////////////////////////////////////////////////////

  LOGINMENU_BACKGROUND_FILENAME = PATH_GUI + PATH_GUI_RELATIVE_SHARED_BACKGROUND_PATH + 'bg.anb';

type
  EnumFilterItemOrder = (foCreated, foAlphabetical, foAlphabeticalReverse, foTech, foTechReverse, foAttack, foDefense, foUtility);
const

  // Friendlist  ------------------------------------------------------------------

  FRIENDLIST_ROOT                 = 'Friendlist';
  FRIENDLIST_REQUEST_LIST         = 'FriendlistRequestsList';
  FRIENDLIST_REQUEST_PENDING_LIST = 'FriendlistPendingRequestsList';
  FRIENDLIST_FRIEND_LIST          = 'FriendlistFriendsList';
  FRIENDLIST_FRIEND_OFFLINE_LIST  = 'FriendlistOfflineList';

  FRIENDLIST_FRIEND_CONTAINER                   = 'FriendWrapper';
  FRIENDLIST_FRIEND_NAME_TEXT                   = 'FriendName';
  FRIENDLIST_FRIEND_ICON                        = 'FriendIcon';
  FRIENDLIST_FRIEND_STATUS_TEXT                 = 'FriendStatus';
  FRIENDLIST_REQUEST_NEW_NAME_EDIT              = 'NewRequestNameEdit';
  FRIENDLIST_REQUEST_NEW_BUTTON                 = 'NewRequestButton';
  FRIENDLIST_FRIEND_ONLINE_TEMPLATE_FILENAME    = PATH_MAINMENU_FRIENDLIST + 'FriendActive.gui';
  FRIENDLIST_FRIEND_OFFLINE_TEMPLATE_FILENAME   = PATH_MAINMENU_FRIENDLIST + 'FriendOffline.gui';
  FRIENDLIST_REQUEST_INCOMING_TEMPLATE_FILENAME = PATH_MAINMENU_FRIENDLIST + 'FriendIncomingRequest.gui';
  FRIENDLIST_REQUEST_OUTGOING_TEMPLATE_FILENAME = PATH_MAINMENU_FRIENDLIST + 'FriendOutgoingRequest.gui';

  FRIENDLIST_FRIEND_POPUPMENU_ITEM_SEND_MESSAGE         = 'send_message';
  FRIENDLIST_FRIEND_POPUPMENU_ITEM_SEND_MESSAGE_VALUE   = 0;
  FRIENDLIST_FRIEND_POPUPMENU_ITEM_INVITE_TO_TEAM       = 'invite_to_team';
  FRIENDLIST_FRIEND_POPUPMENU_ITEM_INVITE_TO_TEAM_VALUE = 1;
  FRIENDLIST_FRIEND_POPUPMENU_ITEM_REMOVE_FRIEND        = 'remove_friend';
  FRIENDLIST_FRIEND_POPUPMENU_ITEM_REMOVE_FRIEND_VALUE  = 2;

  // Chat  ------------------------------------------------------------------

  MAINMENU_CHAT_ROOT                  = 'ChatBar';
  MAINMENU_CHAT_WINDOW_CONTAINER      = 'ChatWindowWrapper';
  MAINMENU_CHAT_WINDOW_FILENAME       = PATH_MAINMENU_CHAT + 'ChatWindow.gui';
  MAINMENU_CHAT_WINDOW_CLOSE_BTN      = 'ChatWindowCloseBtn';
  MAINMENU_CHAT_WINDOW_MINIMIZE_BTN   = 'ChatMinimizeBtn';
  MAINMENU_CHAT_WINDOW                = 'ChatWindow';
  MAINMENU_CHAT_WINDOW_TEXT           = 'ChatWindowText';
  MAINMENU_CHAT_WINDOW_TAB            = 'ChatWindowTab';
  MAINMENU_CHAT_WINDOW_TAB_NAME_TEXT  = 'ChatWindowTab';
  MAINMENU_CHAT_WINDOW_SEND_EDIT      = 'ChatMessageEdit';
  MAINMENU_CHAT_WINDOW_SEND_BTN       = 'ChatMessageSendBtn';
  MAINMENU_CHAT_WINDOW_SEND_CONTAINER = 'ChatMessageInputWrapper';

  /// /////////////////////////////////////////////////////////////////////////
  /// Ingame HUD
  /// /////////////////////////////////////////////////////////////////////////

  // Tutorial Hints

  HUD_TUTORIAL_MUTE_CHECK = 'TutMuteCheck';

  // Tooltip //////////////////////////////////////////////////////////////////

  // Unit --------------------------------

  HUD_HEALTHBAR_OVERHEAL_BAR = 'OverhealBar';


  // Armor

  ARMOR_TYPE_IMAGES : array [low(EnumArmorType) .. high(EnumArmorType)] of string =
    ('ArmorUnarmored.png', 'ArmorLight.png', 'ArmorMedium.png', 'ArmorHeavy.png', 'ArmorFortified.png');


  // Build Panel //////////////////////////////////////////////////////////////

  HUD_BUILD_PANEL                 = 'BuildPanel';
  HUD_BUILD_BUTTONS_WRAPPER       = 'deck_panel';
  HUD_BUILD_BUTTONS_TECH1         = 'Tech1';
  HUD_BUILD_BUTTONS_TECH2         = 'Tech2';
  HUD_BUILD_BUTTONS_TECH3         = 'Tech3';
  HUD_BUILD_BUTTONS_SPAWNER       = 'Spawner';
  HUD_BUILD_BUTTONS_TIMER_WRAPPER = 'DeckTimer';
  HUD_BUILD_BUTTONS_TIMER_TEXT    = 'Timer';
  HUD_BUILD_BUTTON_WRAPPER        = 'BuildButton';
  HUD_BUILD_BUTTON_ICON_FRAME     = 'IconFrame';
  HUD_BUILD_BUTTON_ICON           = 'Icon';

  // Minimap //////////////////////////////////////////////////////////////////

  HUD_MINIMAP = 'Minimap';

  // Ingame Menu /////////////////////////////////////////////////////////

  INGAME_MENU_SURRENDER_BTN = 'SurrenderBtn';

  // Endscreen ///////////////////////////////////////////////////////////

  HUD_ENDSCREEN_CONTINUE_BUTTON = 'EndGameButton';

  /// /////////////////////////////////////////////////////////////////////////
  /// Settings
  /// /////////////////////////////////////////////////////////////////////////
  ///
  SETTINGS_CATEGORY_STACK = 'CategoryStack';

  /// /////////////////////////////////////////////////////////////////////////
  /// Helper functions
  /// /////////////////////////////////////////////////////////////////////////

  /// /////////////////////////////////////////////////////////////////////////
  /// Steam
  /// /////////////////////////////////////////////////////////////////////////
  SteamAppID = 748940;

  STEAM_LANG_Arabic             = 'arabic';
  STEAM_LANG_Bulgarian          = 'bulgarian';
  STEAM_LANG_ChineseSimplified  = 'schinese';
  STEAM_LANG_ChineseTraditional = 'tchinese';
  STEAM_LANG_Czech              = 'czech';
  STEAM_LANG_Danish             = 'danish';
  STEAM_LANG_Dutch              = 'dutch';
  STEAM_LANG_English            = 'english';
  STEAM_LANG_Finnish            = 'finnish';
  STEAM_LANG_French             = 'french';
  STEAM_LANG_German             = 'german';
  STEAM_LANG_Greek              = 'greek';
  STEAM_LANG_Hungarian          = 'hungarian';
  STEAM_LANG_Italian            = 'italian';
  STEAM_LANG_Japanese           = 'japanese';
  STEAM_LANG_Korean             = 'koreana';
  STEAM_LANG_Norwegian          = 'norwegian';
  STEAM_LANG_Polish             = 'polish';
  STEAM_LANG_Portuguese         = 'portuguese';
  STEAM_LANG_PortugueseBrazil   = 'brazilian';
  STEAM_LANG_Romanian           = 'romanian';
  STEAM_LANG_Russian            = 'russian';
  STEAM_LANG_SpanishSpain       = 'spanish';
  STEAM_LANG_SpanishLatin       = 'latam';
  STEAM_LANG_Swedish            = 'swedish';
  STEAM_LANG_Thai               = 'thai';
  STEAM_LANG_Turkish            = 'turkish';
  STEAM_LANG_Ukrainian          = 'ukrainian';
  STEAM_LANG_Vietnamese         = 'vietnamese';

  STEAM_LANGUAGES : TArray<string> = [
    STEAM_LANG_Arabic,
    STEAM_LANG_Bulgarian,
    STEAM_LANG_ChineseSimplified,
    STEAM_LANG_ChineseTraditional,
    STEAM_LANG_Czech,
    STEAM_LANG_Danish,
    STEAM_LANG_Dutch,
    STEAM_LANG_English,
    STEAM_LANG_Finnish,
    STEAM_LANG_French,
    STEAM_LANG_German,
    STEAM_LANG_Greek,
    STEAM_LANG_Hungarian,
    STEAM_LANG_Italian,
    STEAM_LANG_Japanese,
    STEAM_LANG_Korean,
    STEAM_LANG_Norwegian,
    STEAM_LANG_Polish,
    STEAM_LANG_Portuguese,
    STEAM_LANG_PortugueseBrazil,
    STEAM_LANG_Romanian,
    STEAM_LANG_Russian,
    STEAM_LANG_SpanishSpain,
    STEAM_LANG_SpanishLatin,
    STEAM_LANG_Swedish,
    STEAM_LANG_Thai,
    STEAM_LANG_Turkish,
    STEAM_LANG_Ukrainian,
    STEAM_LANG_Vietnamese
    ];

type

  EnumImageState = (isNormal, isHover, isDisabled, isDown);

  HClient = class abstract
    strict private
      class function CardColorsToString(const CardColors : SetEntityColor) : string; static;
    public
      /// <summary> Retrieves the card icon path from the script file path. Path is relative to GUI asset path. </summary>
      class function GetCardIconByFile(const ScriptFile, SkinID : string) : string; static;
      class function GetCardIcon(const CardInfo : TCardInfo) : string; static;
      class function GetCardIconBackgroundByFile(const ScriptFile : string) : string; static;
      class function GetCardIconBackground(const CardInfo : TCardInfo) : string; static;
      class function GetCardInfoBackground(const CardInfo : TCardInfo) : string; static;

      /// <summary> Retrieves the league icon of the given league. Clamps to league range. </summary>
      class function GetLeagueIcon(const League : integer) : string;
      /// <summary> Returns the icon for the given currency </summary>
      class function CurrencyIcon(const CurrencyUID : string) : string; static;
      /// <summary> Returns the icon for the given color </summary>
      class function ColorIcon(const Color : EnumEntityColor) : string; static;

      class function GetSpellIcon(const CardInfo : TCardInfo) : string; static;
      /// <summary> Retrieves the unit icon path from the script file path. Path is relative to GUI asset path.
      /// Accepts also CardIdentifiers. </summary>
      class function GetUnitIconByScriptfile(ScriptFile : string) : string; static;

      class function GetDeckIcon(const IconUID : string) : string; static;

      /// <summary> Retrieves the player icon path icon identifier. Path is relative to GUI asset path. </summary>
      class function GetPlayerIcon(Icon : string) : string; static;

      class function GetDamageTypeIcon(DamageType : EnumDamageType) : string; static;
      class function GetArmorTypeIcon(ArmorType : EnumArmorType) : string; static;
      /// <summary> Maps the language keys from steam (see https://partner.steamgames.com/doc/store/localization#supported_languages)
      /// to game language keys (e.g. de, en).</summary>
      class function MapSteamLanguageKeyToGame(const SteamLanguageKey : string) : string;
  end;

  RSteamLanguage = record
    SteamLanguageCode, EnglishName, NativeName, WebApiLanguageCode : string;
    Progress : integer;
    constructor Create(const SteamLanguageCode, EnglishName, NativeName, WebApiLanguageCode : string);
    function UpdateProgress : RSteamLanguage;
    function DisplayText : string;
    function ProgressWithColoring : string;
  end;

function ColorToString(Color : EnumEntityColor) : string;
function GetDisplayedTeam(TeamID : integer) : integer;
function GetTeamColor(TeamID : integer) : RColor;
function ByteArrayToSetEntityColor(const arr : TArray<byte>) : SetEntityColor;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  FILE_EXTENSION_PNG : string = {$IFDEF RELEASE}'.tex'{$ELSE}'.png'{$ENDIF};
  FILE_EXTENSION_TGA : string = {$IFDEF RELEASE}'.tex'{$ELSE}'.tga'{$ENDIF};
  SteamLanguageKeys : TDictionary<string, RSteamLanguage>;

implementation

uses
  BaseConflict.Globals.Client,
  BaseConflict.Settings.Client;

function ByteArrayToSetEntityColor(const arr : TArray<byte>) : SetEntityColor;
var
  i : integer;
begin
  Result := [];
  for i := 0 to length(arr) - 1 do
      Result := Result + [EnumEntityColor(arr[i])];
end;

function GetDisplayedTeam(TeamID : integer) : integer;
begin
  if assigned(ClientGame) and Settings.GetBooleanOption(coGameplayFixedTeamColors) and (TeamID <> 0) then
  begin
    if (ClientGame.CommanderManager.ActiveCommanderTeamID = TeamID) then Result := 1
    else Result := 2;
  end
  else Result := TeamID;
end;

function GetTeamColor(TeamID : integer) : RColor;
begin
  TeamID := GetDisplayedTeam(TeamID);
  if HMath.InRange(TeamID, 0, length(TEAMCOLORS) - 1) then
      Result := TEAMCOLORS[TeamID]
  else
      Result := TEAMCOLORS[0];
end;

function ColorToString(Color : EnumEntityColor) : string;
begin
  Result := HRTTI.EnumerationToString<EnumEntityColor>(Color).Remove(0, 2);
end;

class function HClient.CardColorsToString(const CardColors : SetEntityColor) : string;
var
  Color : EnumEntityColor;
begin
  Result := '';
  for Color := low(EnumEntityColor) to high(EnumEntityColor) do
    if Color in CardColors then Result := Result + ColorToString(Color);
end;

class function HClient.ColorIcon(const Color : EnumEntityColor) : string;
begin
  Result := PATH_GUI_RELATIVE_SHARED_FACTION_ICONS_PATH;
  case Color of
    ecColorless : Result := Result + 'FactionIcon_Colorless.png';
    ecBlack : Result := Result + 'FactionIcon_Black.png';
    ecGreen : Result := Result + 'FactionIcon_Green.png';
    ecRed : Result := Result + 'FactionIcon_Red.png';
    ecBlue : Result := Result + 'FactionIcon_Blue.png';
    ecWhite : Result := Result + 'FactionIcon_White.png';
  else
    raise ENotImplemented.CreateFmt('HClient.ColorIcon: Color %s not implemented!', [HRTTI.EnumerationToString<EnumEntityColor>(Color)]);
  end;
end;

class function HClient.GetArmorTypeIcon(ArmorType : EnumArmorType) : string;
begin
  Result := PATH_HUD_TOOLTIP_ARMOR_ICONS + ARMOR_TYPE_IMAGES[ArmorType];
end;

class function HClient.GetCardIcon(const CardInfo : TCardInfo) : string;
begin
  Result := PATH_GUI_RELATIVE_SHARED_CARD_ICONS_PATH + 'Unknown.tga';
  if not assigned(CardInfo) then exit;
  Result := GetCardIconByFile(CardInfo.Filename, CardInfo.SkinID);
end;

class function HClient.GetCardIconByFile(const ScriptFile, SkinID : string) : string;
var
  IconFile : string;
begin
  if ScriptFile = '' then exit('');
  // extract filename
  IconFile := ExtractFileName(ChangeFileExt(ScriptFile, FILE_EXTENSION_TGA));
  // remove suffixes, Spawner and Drop to gain direct card name
  IconFile := IconFile.Replace(FILE_IDENTIFIER_DROP, '').Replace(FILE_IDENTIFIER_SPAWNER, '').Replace(FILE_IDENTIFIER_BUILDING, '').Replace(FILE_IDENTIFIER_SPELL, '').Replace(FILE_IDENTIFIER_GOLEMS, '');
  // add icon prefixes
  IconFile := PATH_GUI_RELATIVE_SHARED_CARD_ICONS_PATH + HClient.CardColorsToString(CardInfoManager.ScriptFilenameToCardColors(ScriptFile)) + IconFile;
  // add skin suffixes
  if SkinID <> '' then
      IconFile := IconFile.Replace('.', '_' + SkinID + '.');
  // if skin not found, remove skin suffix
  if not HFilepathManager.FileExists(PATH_GUI + IconFile) then
      IconFile := TRegex.SubstituteDirect(IconFile, '(_\w+)', '');
  if not HFilepathManager.FileExists(PATH_GUI + IconFile) then
      IconFile := '';
  Result := IconFile;
end;

class function HClient.GetCardIconBackground(const CardInfo : TCardInfo) : string;
begin
  Result := '';
  if not assigned(CardInfo) then exit;
  Result := PATH_GUI_RELATIVE_SHARED_CARD_ICONS_PATH + 'Card_';

  if CardInfo.IsSpawner then
      Result := Result + 'Spawner'
  else
      Result := Result + HClient.CardColorsToString(CardInfo.CardColors);

  if CardInfo.IsSpell then
      Result := Result + '_Spell';

  Result := Result + '.tga';
end;

class function HClient.GetCardIconBackgroundByFile(const ScriptFile : string) : string;
var
  CardType : EnumCardType;
begin
  Result := PATH_GUI_RELATIVE_SHARED_CARD_ICONS_PATH + 'Card_';
  CardType := CardInfoManager.ScriptFilenameToCardType(ScriptFile);

  if CardType = ctSpawner then
      Result := Result + 'Spawner'
  else
      Result := Result + HClient.CardColorsToString(CardInfoManager.ScriptFilenameToCardColors(ScriptFile));

  if CardType = ctSpell then
      Result := Result + '_Spell';

  Result := Result + '.tga';
end;

class function HClient.GetCardInfoBackground(const CardInfo : TCardInfo) : string;
begin
  Result := '';
  if not assigned(CardInfo) then exit;
  Result := PATH_MAINMENU_SHARED_CARD + 'CardBackground';
  Result := Result + HClient.CardColorsToString(CardInfo.CardColors);
  if CardInfo.IsSpawner then Result := Result + 'Spawner'
  else if CardInfo.IsSpell then Result := Result + 'Spell'
  else Result := Result + 'Unit';
  Result := Result + '.png';
end;

class function HClient.GetDamageTypeIcon(DamageType : EnumDamageType) : string;
begin
  if DamageType = dtSiege then Result := 'DamageTypeSiege.png'
  else if DamageType = dtRanged then Result := 'DamageTypeRanged.png'
  else Result := 'DamageTypeMelee.png';
  Result := PATH_HUD_TOOLTIP_ATTACK_ICONS + Result;
end;

class function HClient.GetDeckIcon(const IconUID : string) : string;
begin
  Result := PATH_GUI_RELATIVE_SHARED_DECK_ICONS + IconUID + FILE_EXTENSION_PNG;
  if not HFilepathManager.FileExists(PATH_GUI + Result) then
      Result := PATH_GUI_RELATIVE_SHARED_DECK_ICONS + 'UnknownDeck.png';
end;

class function HClient.GetLeagueIcon(const League : integer) : string;
begin
  Result := PATH_GUI_RELATIVE_SHARED_LEAGUE_ICONS + 'League' + Inttostr(HMath.Clamp(League, 1, 5)) + '.tga';
end;

class function HClient.GetPlayerIcon(Icon : string) : string;
begin
  Icon := PATH_GUI_RELATIVE_SHARED_PLAYER_ICONS + Icon + FILE_EXTENSION_PNG;
  if not HFilepathManager.FileExists(PATH_GUI + Icon) then
      Result := PATH_GUI_RELATIVE_SHARED_PLAYER_ICONS + 'UnknownPlayer.png'
  else
      Result := Icon;
end;

class function HClient.GetSpellIcon(const CardInfo : TCardInfo) : string;
begin
  if not assigned(CardInfo) then exit(GetUnitIconByScriptfile(''));
  Result := GetUnitIconByScriptfile(CardInfo.Filename);
end;

class function HClient.GetUnitIconByScriptfile(ScriptFile : string) : string;
var
  EntityColors : SetEntityColor;
begin
  if ScriptFile = '' then exit(PATH_GUI_RELATIVE_SHARED_UNIT_ICONS_PATH + 'Unknown.png');
  EntityColors := CardInfoManager.ScriptFilenameToCardColors(ScriptFile);
  ScriptFile := CardInfoManager.ScriptFilenameToCardIdentifier(ScriptFile);
  ScriptFile := ScriptFile + FILE_EXTENSION_PNG;
  Result := PATH_GUI_RELATIVE_SHARED_UNIT_ICONS_PATH + CardInfoManager.EntityColorsToFolder(EntityColors) + ScriptFile;
  // Try to remove suffixes, if icons does not exist
  if not HFilepathManager.FileExists(PATH_GUI + Result) then
      Result := TRegex.SubstituteDirect(Result, '(_\w+)', '');
  if not HFilepathManager.FileExists(PATH_GUI + Result) then
      Result := PATH_GUI_RELATIVE_SHARED_UNIT_ICONS_PATH + 'Unknown.png';
end;

class function HClient.MapSteamLanguageKeyToGame(const SteamLanguageKey : string) : string;
var
  SteamLang : RSteamLanguage;
begin
  if SteamLanguageKeys.TryGetValue(SteamLanguageKey, SteamLang) then
      Result := SteamLang.WebApiLanguageCode
  else
      Result := 'en';
end;

class function HClient.CurrencyIcon(const CurrencyUID : string) : string;
begin
  Result := PATH_GUI_RELATIVE_SHARED_CURRENCY_ICONS + CurrencyUID + '.png';
end;

{ RSteamLanguage }

constructor RSteamLanguage.Create(const SteamLanguageCode, EnglishName, NativeName, WebApiLanguageCode : string);
begin
  self.SteamLanguageCode := SteamLanguageCode;
  self.EnglishName := EnglishName;
  self.NativeName := NativeName;
  self.WebApiLanguageCode := WebApiLanguageCode;
end;

function RSteamLanguage.DisplayText : string;
begin
  Result := EnglishName + ' (' + NativeName + ') - ' + Inttostr(Progress) + '%';
end;

function RSteamLanguage.ProgressWithColoring : string;
begin
  if Progress >= 100 then
      Result := 'premium'
  else if Progress >= 60 then
      Result := 'warning'
  else if Progress >= 10 then
      Result := 'questcount'
  else
      Result := 'danger';
  Result := '<span class="' + Result + '">' + Inttostr(Progress) + '%</span>';
end;

function RSteamLanguage.UpdateProgress : RSteamLanguage;
begin
  Result := self;
  Result.Progress := trunc(100 * HInternationalizer.TranslationProgress(WebApiLanguageCode));
end;

initialization

ScriptManager.ExposeType(TypeInfo(EnumKeybinding));

ScriptManager.ExposeConstant('BIND_ZONE_CENTER', BIND_ZONE_CENTER);
ScriptManager.ExposeConstant('BIND_ZONE_HIT_ZONE_AIR', BIND_ZONE_HIT_ZONE_AIR);
ScriptManager.ExposeConstant('BIND_ZONE_HIT_ZONE', BIND_ZONE_HIT_ZONE);
ScriptManager.ExposeConstant('BIND_ZONE_WEAPON_MUZZLE', BIND_ZONE_WEAPON_MUZZLE);
ScriptManager.ExposeConstant('BIND_ZONE_WEAPON', BIND_ZONE_WEAPON);
ScriptManager.ExposeConstant('BIND_ZONE_TOP', BIND_ZONE_TOP);
ScriptManager.ExposeConstant('BIND_ZONE_BOTTOM', BIND_ZONE_BOTTOM);
ScriptManager.ExposeConstant('BIND_ZONE_HEAD', BIND_ZONE_HEAD);
ScriptManager.ExposeConstant('BIND_ZONE_GROUND', BIND_ZONE_GROUND);
ScriptManager.ExposeConstant('BIND_ZONE_PIVOT', BIND_ZONE_PIVOT);

ScriptManager.ExposeConstant('FLYING_HEIGHT', FLYING_HEIGHT);
ScriptManager.ExposeConstant('GROUND_EPSILON', GROUND_EPSILON);

ScriptManager.ExposeConstant('PATH_GRAPHICS', PATH_GRAPHICS);
ScriptManager.ExposeConstant('PATH_GRAPHICS_EFFECTS_TEXTURES', PATH_GRAPHICS_EFFECTS_TEXTURES);
ScriptManager.ExposeConstant('PATH_GRAPHICS_EFFECTS_MESHES', PATH_GRAPHICS_EFFECTS_MESHES);

SteamLanguageKeys := TDictionary<string, RSteamLanguage>.Create;

SteamLanguageKeys.Add(STEAM_LANG_Arabic, RSteamLanguage.Create(STEAM_LANG_Arabic, 'Arabic', 'العربية', 'ar'));
SteamLanguageKeys.Add(STEAM_LANG_Bulgarian, RSteamLanguage.Create(STEAM_LANG_Bulgarian, 'Bulgarian', 'български език', 'bg'));
SteamLanguageKeys.Add(STEAM_LANG_ChineseSimplified, RSteamLanguage.Create(STEAM_LANG_ChineseSimplified, 'Chinese (Simplified)', '简体中文', 'zh-CN'));
SteamLanguageKeys.Add(STEAM_LANG_ChineseTraditional, RSteamLanguage.Create(STEAM_LANG_ChineseTraditional, 'Chinese (Traditional)', '繁體中文', 'zh-TW'));
SteamLanguageKeys.Add(STEAM_LANG_Czech, RSteamLanguage.Create(STEAM_LANG_Czech, 'Czech', 'čeština', 'cs'));
SteamLanguageKeys.Add(STEAM_LANG_Danish, RSteamLanguage.Create(STEAM_LANG_Danish, 'Danish', 'Dansk', 'da'));
SteamLanguageKeys.Add(STEAM_LANG_Dutch, RSteamLanguage.Create(STEAM_LANG_Dutch, 'Dutch', 'Nederlands', 'nl'));
SteamLanguageKeys.Add(STEAM_LANG_English, RSteamLanguage.Create(STEAM_LANG_English, 'English', 'English', 'en'));
SteamLanguageKeys.Add(STEAM_LANG_Finnish, RSteamLanguage.Create(STEAM_LANG_Finnish, 'Finnish', 'Suomi', 'fi'));
SteamLanguageKeys.Add(STEAM_LANG_French, RSteamLanguage.Create(STEAM_LANG_French, 'French', 'Français', 'fr'));
SteamLanguageKeys.Add(STEAM_LANG_German, RSteamLanguage.Create(STEAM_LANG_German, 'German', 'Deutsch', 'de'));
SteamLanguageKeys.Add(STEAM_LANG_Greek, RSteamLanguage.Create(STEAM_LANG_Greek, 'Greek', 'Ελληνικά', 'el'));
SteamLanguageKeys.Add(STEAM_LANG_Hungarian, RSteamLanguage.Create(STEAM_LANG_Hungarian, 'Hungarian', 'Magyar', 'hu'));
SteamLanguageKeys.Add(STEAM_LANG_Italian, RSteamLanguage.Create(STEAM_LANG_Italian, 'Italian', 'Italiano', 'it'));
SteamLanguageKeys.Add(STEAM_LANG_Japanese, RSteamLanguage.Create(STEAM_LANG_Japanese, 'Japanese', '日本語', 'ja'));
SteamLanguageKeys.Add(STEAM_LANG_Korean, RSteamLanguage.Create(STEAM_LANG_Korean, 'Korean', '한국어', 'ko'));
SteamLanguageKeys.Add(STEAM_LANG_Norwegian, RSteamLanguage.Create(STEAM_LANG_Norwegian, 'Norwegian', 'Norsk', 'no'));
SteamLanguageKeys.Add(STEAM_LANG_Polish, RSteamLanguage.Create(STEAM_LANG_Polish, 'Polish', 'Polski', 'pl'));
SteamLanguageKeys.Add(STEAM_LANG_Portuguese, RSteamLanguage.Create(STEAM_LANG_Portuguese, 'Portuguese', 'Português', 'pt'));
SteamLanguageKeys.Add(STEAM_LANG_PortugueseBrazil, RSteamLanguage.Create(STEAM_LANG_PortugueseBrazil, 'Portuguese-Brazil', 'Português-Brasil', 'pt-BR'));
SteamLanguageKeys.Add(STEAM_LANG_Romanian, RSteamLanguage.Create(STEAM_LANG_Romanian, 'Romanian', 'Română', 'ro'));
SteamLanguageKeys.Add(STEAM_LANG_Russian, RSteamLanguage.Create(STEAM_LANG_Russian, 'Russian', 'Русский', 'ru'));
SteamLanguageKeys.Add(STEAM_LANG_SpanishSpain, RSteamLanguage.Create(STEAM_LANG_SpanishSpain, 'Spanish-Spain', 'Español-España', 'es'));
SteamLanguageKeys.Add(STEAM_LANG_SpanishLatin, RSteamLanguage.Create(STEAM_LANG_SpanishLatin, 'Spanish-Latin America', 'Español-Latinoamérica', 'es-419'));
SteamLanguageKeys.Add(STEAM_LANG_Swedish, RSteamLanguage.Create(STEAM_LANG_Swedish, 'Swedish', 'Svenska', 'sv'));
SteamLanguageKeys.Add(STEAM_LANG_Thai, RSteamLanguage.Create(STEAM_LANG_Thai, 'Thai', 'ไทย', 'th'));
SteamLanguageKeys.Add(STEAM_LANG_Turkish, RSteamLanguage.Create(STEAM_LANG_Turkish, 'Turkish', 'Türkçe', 'tr'));
SteamLanguageKeys.Add(STEAM_LANG_Ukrainian, RSteamLanguage.Create(STEAM_LANG_Ukrainian, 'Ukrainian', 'Українська', 'uk'));
SteamLanguageKeys.Add(STEAM_LANG_Vietnamese, RSteamLanguage.Create(STEAM_LANG_Vietnamese, 'Vietnamese', 'Tiếng Việt', 'vn'));

finalization

SteamLanguageKeys.Free;

end.
