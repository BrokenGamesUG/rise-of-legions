unit BaseConflict.EntityComponents.Client.GUI;

interface

uses
  Generics.Collections,
  System.SysUtils,
  System.RegularExpressions,
  System.Math,
  Engine.Log,
  Engine.Input,
  Engine.Core,
  Engine.Core.Types,
  Engine.Vertex,
  Engine.GUI,
  Engine.GFXApi,
  Engine.GFXApi.Types,
  Engine.Script,
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Windows,
  Engine.Terrain,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  BaseConflict.Map,
  BaseConflict.Game,
  BaseConflict.Classes.Gamestates.GUI,
  BaseConflict.Classes.Shared,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Client,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Globals,
  BaseConflict.Globals.Client,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Shared.Wela,
  BaseConflict.EntityComponents.Client,
  BaseConflict.Settings.Client;

type

  {$RTTI INHERIT}
  /// <summary> Handles a commanderability like build, spell. Handles the related GUI. </summary>
  TAbilitybuttonComponent = class(TEntityComponent)
    protected
      FSpell : TCommanderSpellData;
      FMultiMode : TArray<byte>;
      function GetDataEntity() : TEntity;
      procedure DeRegisterButton; virtual;
      procedure RegisterButton; virtual;
      procedure GenerateSpellData;
    published
      [XEvent(eiRegisterInGui, epLast, etTrigger)]
      /// <summary> Registers this ability in the gui. </summary>
      function OnRegisterInGUI() : boolean;
      [XEvent(eiDeregisterInGui, epLast, etTrigger)]
      /// <summary> Deregister this ability in the gui. </summary>
      function OnClearGUI() : boolean;
    public
      function IsMultiMode(ModeGroups : TArray<byte>) : TAbilitybuttonComponent;
      destructor Destroy; override;
  end;

  /// <summary> Specify the ability as a generic commander ability. </summary>
  TCommanderAbilityButtonComponent = class(TAbilitybuttonComponent)
    protected
      FHUDCommanderAbility : THUDCommanderAbility;
      FUID : string;
      procedure RegisterButton; override;
      procedure DeRegisterButton; override;
    public
      function UID(const UID : string) : TCommanderAbilityButtonComponent;
  end;

  /// <summary> Specify the ability as buildability. </summary>
  TDeckCardButtonComponent = class(TAbilitybuttonComponent)
    protected
      FHUDDeckSlot : THUDDeckSlot;
      FSlot : integer;
      FCardInfo : TCardInfo;
      FCooldownGroup : SetComponentGroup;
      procedure RegisterButton; override;
      procedure DeRegisterButton; override;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Shows tooltip for buildabilities after a short delay. </summary>
      function OnIdle() : boolean;
    public
      function Slot(Slot : integer) : TDeckCardButtonComponent;
      function CardInfo(CardInfo : TCardInfo) : TDeckCardButtonComponent;
      function SetCooldownGroup(Group : TArray<byte>) : TDeckCardButtonComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a unit ability. </summary>
  TTooltipUnitAbilityComponent = class(TEntityComponent)
    protected
      FIsCardDescription : boolean;
      FAbilityname : string;
      FKeywords : TList<string>;
      FVariables : TObjectList<TTranslationVariable>;
    published
      [XEvent(eiBuildAbilityList, epLower, etTrigger)]
      function OnBuildAbilityList(AbilityIDList, KeywordIDList, CardDescriptionRaw : RParam) : boolean;
    public
      constructor Create(Owner : TEntity; const AbilityName : string); reintroduce;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; const AbilityName : string); reintroduce;
      function Keyword(const Keyword : string) : TTooltipUnitAbilityComponent;
      function IsCardDescription() : TTooltipUnitAbilityComponent;
      function PassInteger(const Key : string; Value : integer) : TTooltipUnitAbilityComponent; overload;
      function PassInteger(const Key : string; Value : integer; const SpanClass : string) : TTooltipUnitAbilityComponent; overload;
      function PassSingleAsInteger(const Key : string; Value : single) : TTooltipUnitAbilityComponent; overload;
      function PassSingleAsInteger(const Key : string; Value : single; const SpanClass : string) : TTooltipUnitAbilityComponent; overload;
      function PassPercentage(const Key : string; Value : integer) : TTooltipUnitAbilityComponent; overload;
      function PassPercentage(const Key : string; Value : integer; const SpanClass : string) : TTooltipUnitAbilityComponent; overload;
      function PassSingle(const Key : string; IntegralPart, FractionalPart : integer) : TTooltipUnitAbilityComponent; overload;
      function PassSingle(const Key : string; IntegralPart, FractionalPart : integer; const SpanClass : string) : TTooltipUnitAbilityComponent; overload;
      function PassString(const Key : string; const Value : string) : TTooltipUnitAbilityComponent; overload;
      function PassString(const Key : string; const Value : string; const SpanClass : string) : TTooltipUnitAbilityComponent; overload;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Shows a ping on the minimap. </summary>
  TMinimapPingComponent = class(TEntityComponent)
    protected const
      PING_DURATION = 4000;
    protected
      FIconPath : string;
      FSize : single;
    published
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
    public
      function Size(Size : single) : TMinimapPingComponent;
      function Texture(const IconPath : string) : TMinimapPingComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a healthbar and other data above the entity. </summary>
  TEntityDisplayWrapperComponent = class(TEntityComponent)
    protected
      FWrapper : TGUIStackPanel;
      FOffset : RVector3;
      procedure UpdatePosition;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Init the position. </summary>
      function OnAfterDeserialization() : boolean;
      [XEvent(eiIdle, epLow, etTrigger, esGlobal)]
      /// <summary> Update position of the Resource display. </summary>
      function OnIdle() : boolean;
      [XEvent(eiGetEntityResourceWrapper, epFirst, etRead)]
      /// <summary> Returns the wrapper. </summary>
      function OnGetEntityResourceWrapper() : RParam;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SetOffset(YOffset : single) : TEntityDisplayWrapperComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays icons above the entity. </summary>
  TEntityDisplayComponent = class abstract(TEntityComponent)
    protected
      FRegisteredInWrapper : boolean;
      FDirty : boolean;
      FOrderValue : integer;
      FSizeYOverride : single;
      procedure SetDirty;
      function GetDefaultSize : RVector2; virtual;
      function GetSize : RVector2;
      function IsVisible : boolean; virtual;
      procedure ComputeVisibility; virtual;
      procedure Init; virtual;
      procedure Update; virtual;
      procedure Idle; virtual;
      /// <summary> Component is applied all generic changes. </summary>
      procedure PostProcessComponent(Component : TGUIComponent);
      /// <summary> Component will be inserted into resource stack. Will be postprocessed before insert. </summary>
      procedure InsertIntoWrapper(Component : TGUIComponent; Wrapper : TGUIStackPanel = nil);
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Create the Resourcebar. </summary>
      function OnAfterDeserialization() : boolean;
      [XEvent(eiIdle, epLow, etTrigger, esGlobal)]
      /// <summary> Compute visibility. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); override;
      /// <summary> Determines an order value, where this display is placed relative to other stack elements. Default 0. </summary>
      function OrderValue(OrderValue : integer) : TEntityDisplayComponent;
      function SizeY(SizeY : single) : TEntityDisplayComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays all icons above the entity. </summary>
  TStateDisplayStackComponent = class(TEntityDisplayComponent)
    protected
      FStack : TGUIStackPanel;
      function GetDefaultSize : RVector2; override;
      procedure ComputeVisibility; override;
      procedure Init; override;
      procedure InitWrapper;
    published
      [XEvent(eiGetEntityStateWrapper, epFirst, etRead)]
      /// <summary> Returns the wrapper. </summary>
      function OnGetEntityStateWrapper() : RParam;
    public
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a particula icon above the entity. </summary>
  TStateDisplayComponent = class(TEntityDisplayComponent)
    protected
      FReverseWelaIsReadyCheck : boolean;
      FWelaIsReadyGroup : SetComponentGroup;
      FTexturePath : string;
      FIcon : TGUIComponent;
      procedure Init; override;
      procedure InitIcon;
      procedure ComputeVisibility; override;
      function IsVisible : boolean; override;
    public
      function CheckWelaIsReadyInGroup(const TargetGroup : TArray<byte>) : TStateDisplayComponent;
      function ReverseWelaIsReadyCheck : TStateDisplayComponent;
      function Texture(const TexturePath : string) : TStateDisplayComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a progress bar above the entity. </summary>
  TResourceDisplayComponent = class abstract(TEntityDisplayComponent)
    protected
      FHideIfEmpty, FHideIfFull : boolean;
      FResourceType : EnumResource;
      FTeamOverride : integer;
      function ObservedResourceTypes : SetResource; virtual;
      function TeamID : integer;
      function IsVisible : boolean; override;
      function IsEmpty : boolean; virtual;
      function IsFull : boolean; virtual;
      procedure ResourceChanged(Value : RParam); virtual;
      procedure ResourceCapChanged(Value : RParam); virtual;
    published
      [XEvent(eiResourceBalance, epLast, etWrite)]
      /// <summary> Update the healthbar. </summary>
      function OnSetResource(ID, Value : RParam) : boolean;
      [XEvent(eiResourceCap, epLast, etWrite)]
      /// <summary> Update the healthbar. </summary>
      function OnSetResourceCap(ID, Value : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      function ShowResource(ResourceType : integer) : TResourceDisplayComponent;
      function ShowAsTeam(TeamID : integer) : TResourceDisplayComponent;
      function HideIfEmpty : TResourceDisplayComponent;
      function HideIfFull : TResourceDisplayComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a progress bar above the entity. </summary>
  TResourceDisplayBarComponent = class abstract(TResourceDisplayComponent)
    protected
      FResourceBar : TGUIComponent;
      FGradientTopOverride, FGradientBottomOverride : RColor;
      procedure InitBar;
      function GetDefaultBackgroundColor : RColor; virtual;
      function GetBackgroundColor : RColor;
      function GetColorGradient : RTuple<RColor, RColor>; overload;
      function GetColorGradient(Resource : EnumResource) : RTuple<RColor, RColor>; overload;
      function GetColorTop : RColor; overload;
      function GetColorTop(Resource : EnumResource) : RColor; overload;
      function GetColorBottom : RColor; overload;
      function GetColorBottom(Resource : EnumResource) : RColor; overload;
      procedure ComputeVisibility; override;
      function IsVisible : boolean; override;
      procedure Init; override;
    public
      function GradientTop(GradientTop : cardinal) : TResourceDisplayBarComponent;
      function GradientBottom(GradientBottom : cardinal) : TResourceDisplayBarComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a progress bar above the entity. </summary>
  TResourceDisplayProgressBarComponent = class(TResourceDisplayBarComponent)
    protected
      FResourceFill : TGUIComponent;
      procedure InitFillbar; virtual;
      function GetCurrent : single;
      function GetMax : single;
      function GetProgress : single; virtual;
      function IsEmpty : boolean; override;
      function IsFull : boolean; override;
      procedure Update; override;
      procedure UpdateColors;
      procedure Init; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a progress bar above the entity. </summary>
  TResourceDisplayHealthComponent = class(TResourceDisplayProgressBarComponent)
    protected
      FOverhealBar : TGUIComponent;
      procedure InitFillbar; override;
      function GetDefaultSize : RVector2; override;
      function ObservedResourceTypes : SetResource; override;
      function GetProgress : single; override;
      function GetCurrentOverheal : single;
      function GetMaxOverheal : single;
      function IsVisible : boolean; override;
      procedure Update; override;
    published
      [XEvent(eiChangeCommander, epLast, etTrigger, esGlobal)]
      /// <summary> Refreshes the commanderswitch. </summary>
      function OnChangeCommander(Index : RParam) : boolean;
      [XEvent(eiClientOption, epLast, etTrigger, esGlobal)]
      /// <summary> React to option changes. </summary>
      function OnClientOption(ChangedOption : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
  end;

  {$RTTI INHERIT}

  /// <summary> Displays a progress bar build by small chunks above the entity. </summary>
  TResourceDisplayIntegerProgressBarComponent = class(TResourceDisplayBarComponent)
    strict private
    type
      EnumAnimationState = (asShown, asIn, asOut, asHidden);
    public const
      MAX_CHUNKS_PER_ROW = 31;
      MAX_ROWS           = 2;
      MAX_CHUNKS         = MAX_ROWS * MAX_CHUNKS_PER_ROW;
    protected
      FFixedCap, FVisibleChunks : integer;
      FNoCap : boolean;
      procedure AddChunkToBar;
      function GetDefaultBackgroundColor : RColor; override;
      function GetCurrent : integer;
      function GetMax : integer;
      function IsEmpty : boolean; override;
      function IsFull : boolean; override;
      function AmountToInt(Amount : RParam) : integer;
      procedure Init; override;
      procedure RecomputeChunk(Index : integer);
      procedure ResourceChanged(Value : RParam); override;
      procedure ResourceCapChanged(Value : RParam); override;
      procedure UpdateBar;
      procedure Idle; override;
    public
      function NoCap : TResourceDisplayIntegerProgressBarComponent;
      function FixedCap(NewCap : integer) : TResourceDisplayIntegerProgressBarComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Prints the resource to the console. </summary>
  TResourceDisplayConsoleComponent = class(TResourceDisplayComponent)
    published
      [XEvent(eiIdle, epLow, etTrigger, esGlobal)]
      /// <summary> Compute visibility. </summary>
      function OnIdle() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Shows a circle to visualize a range. </summary>
  TRangeIndicatorComponent = class(TEntityComponent)
    protected
      FColor : RColor;
      FPermanent : boolean;
      procedure Idle; virtual;
    published
      [XEvent(eiColorAdjustment, epLast, etTrigger)]
      /// <summary> Changes the color of the circle. </summary>
      function OnColorAdjustment(ColorAdjustment : RParam; absH, absS, absV : RParam) : boolean;
      [XEvent(eiIdle, epLower, etTrigger, esGlobal)]
      /// <summary> Draws the circle. </summary>
      function OnIdle() : boolean;
      [XEvent(eiDeploy, epLast, etTrigger)]
      /// <summary> Removes this after real creation of the entity. </summary>
      function OnDeploy() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function IsPermanent : TRangeIndicatorComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Shows a texture circle to visualize a range. Default with additive blending. </summary>
  TTextureRangeIndicatorComponent = class(TRangeIndicatorComponent)
    protected
      FTexture, FInvalidTexture : TTexture;
      FQuad : TVertexWorldspaceQuad;
      FCircle : TVertexWorldspaceCircle;
      FUseWeaponrange, FShowTeamColor, FDrawOnShowSpawnZone, FIsCone, FHideInCaptureMode : boolean;
      FShownDynamicZones : SetDynamicZone;
      FSize, FOpacity : single;
      FConeDirection, FOffset : RVector2;
      function GetSize : single;
      procedure Idle; override;
    published
      [XEvent(eiDrawSpawnZone, epLower, etRead, esGlobal)]
      /// <summary> Enumerates Zones. </summary>
      function OnEnumerateSpawnZone(Zone, Previous : RParam) : RParam;
    public
      constructor Create(Owner : TEntity); override;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SetAdditiveBlend : TTextureRangeIndicatorComponent;
      function ShowWeaponRange : TTextureRangeIndicatorComponent;
      function Size(Size : single) : TTextureRangeIndicatorComponent;
      function Opacity(Opacity : single) : TTextureRangeIndicatorComponent;
      /// <summary> Alters the used texture, uses 'SpelltargetGround.png' as default. </summary>
      function SetTexture(TextureName : string) : TTextureRangeIndicatorComponent;
      function DrawCircle(Thickness : single) : TTextureRangeIndicatorComponent;
      /// <summary> Only with DrawCircle. </summary>
      function Slice(SliceFrom, SliceTo : single) : TTextureRangeIndicatorComponent;
      function ShowTeamColor : TTextureRangeIndicatorComponent;
      function DrawOnShowSpawnZone(Zones : TArray<byte>) : TTextureRangeIndicatorComponent;
      function HideInCaptureMode : TTextureRangeIndicatorComponent;
      function Cone(DirectionX, DirectionZ : single) : TTextureRangeIndicatorComponent;
      function Offset(OffsetX, OffsetZ : single) : TTextureRangeIndicatorComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Highlight all entities in range and valid to wela. </summary>
  TRangeIndicatorHighlightEntitiesComponent = class(TRangeIndicatorComponent)
    protected
      FValidGroup, FInvalidGroup : SetComponentGroup;
      /// <summary> Highlights entities. </summary>
      procedure Idle; override;
    public
      function Valid(Group : TArray<byte>) : TRangeIndicatorHighlightEntitiesComponent;
      function Invalid(Group : TArray<byte>) : TRangeIndicatorHighlightEntitiesComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Metaclass for all spelltargetvisualizer. </summary>
  TSpelltargetVisualizerComponent = class(TEntityComponent)
    protected
      /// <summary> Called every frame. </summary>
      procedure Visualize(Data : TCommanderSpellData); virtual; abstract;
      procedure Hide; virtual; abstract;
    published
      [XEvent(eiSpellVisualization, epMiddle, etTrigger)]
      /// <summary> Updates the abilitypreview. </summary>
      function OnVisualize(Data : RParam) : boolean;
      [XEvent(eiSpellVisualizationHide, epMiddle, etTrigger)]
      /// <summary> Updates the abilitypreview. </summary>
      function OnHideVisualization() : boolean;
  end;

  {$RTTI INHERIT}

  /// <summary> Shows a texture circle to visualize a cooldown. Default with additive blending. </summary>
  TIndicatorCooldownCircleComponent = class(TSpelltargetVisualizerComponent)
    protected
      FTexture : TTexture;
      FCircle : TVertexWorldspaceCircle;
      FOffset : RVector3;
      FOpacity, FRadius : single;
      FScaleWith : EnumEventIdentifier;
      FSpelltargetVisualizer, FInvertDirection, FInvert, FUseScaleWith : boolean;
      FShowGameEvent : string;
      FGameEventDuration : integer;
      FShowResource : EnumResource;
      FTeamOverride : integer;
      FColorOverride : RColor;

      FTargetPosition : RVector3;
      FTargetTeam : integer;
      FTargetCollisionRadius : single;
      function Progress : single;
      procedure Idle; virtual;
      procedure Render; virtual;
      procedure Visualize(Data : TCommanderSpellData); override;
      procedure Hide; override;
    published
      [XEvent(eiIdle, epLower, etTrigger, esGlobal)]
      /// <summary> Draws the circle. </summary>
      function OnIdle() : boolean;
    public
      constructor Create(Owner : TEntity); override;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SpelltargetVisualizer : TIndicatorCooldownCircleComponent;
      function SetLinearBlend : TIndicatorCooldownCircleComponent;
      function SetThickness(Thickness : single) : TIndicatorCooldownCircleComponent;
      function SetRadius(Radius : single) : TIndicatorCooldownCircleComponent;
      function ScaleWith(Event : EnumEventIdentifier) : TIndicatorCooldownCircleComponent;
      function SetTexture(TextureName : string) : TIndicatorCooldownCircleComponent;
      function Opacity(s : single) : TIndicatorCooldownCircleComponent;
      function Offset(X, Y, Z : single) : TIndicatorCooldownCircleComponent;
      function InvertDirection : TIndicatorCooldownCircleComponent;
      function Invert : TIndicatorCooldownCircleComponent;
      function ShowsResource(Resource : EnumResource) : TIndicatorCooldownCircleComponent;
      function ShowsGameEvent(const GameEvent : string; Duration : integer) : TIndicatorCooldownCircleComponent;
      function ShowAsTeam(TeamID : integer) : TIndicatorCooldownCircleComponent;
      function Color(ForcedColor : cardinal) : TIndicatorCooldownCircleComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Shows a dashed texture circle to visualize a integer resource. Default with additive blending. </summary>
  TIndicatorResourceCircleComponent = class(TIndicatorCooldownCircleComponent)
    protected
      FFixedCap : integer;
      FPadding : single;
      FChunks : TObjectList<TVertexWorldspaceCircle>;
      procedure Idle; override;
      procedure Render; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function Padding(Angle : single) : TIndicatorResourceCircleComponent;
      function FixedCap(FixedCap : integer) : TIndicatorResourceCircleComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> For each target the the texture is placed beneath it. </summary>
  TSpelltargetVisualizerShowTextureComponent = class(TSpelltargetVisualizerComponent)
    protected
      type
      TTargetInfo = class
        Texture, Invalidtexture : TTexture;
        Size, Opacity : single;
        Additive : boolean;
        constructor Create;
        destructor Destroy; override;
      end;
    var
      FQuads : TObjectList<TVertexWorldspaceQuad>;
      /// <summary> Sets the textures (Valid, Invalid Target) for each targetindex. If not specified defaults to 0. </summary>
      FInfo : TObjectDictionary<integer, TTargetInfo>;
      FDefaultInfo : TTargetInfo;
      FNoValidChecks : boolean;
      function GetInfo(Index : integer) : TTargetInfo;
      function GetOrCreateInfo(Index : integer) : TTargetInfo;
      procedure Visualize(Data : TCommanderSpellData); override;
      procedure Hide; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function SetTexture(TexturePath : string; ForIndex : integer = 0) : TSpelltargetVisualizerShowTextureComponent;
      function SetSize(Size : single; ForIndex : integer = 0) : TSpelltargetVisualizerShowTextureComponent;
      function Opacity(Opacity : single; ForIndex : integer = 0) : TSpelltargetVisualizerShowTextureComponent;
      function Additive(ForIndex : integer = 0) : TSpelltargetVisualizerShowTextureComponent;
      function NoValidChecks : TSpelltargetVisualizerShowTextureComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Shows a text on the targets. </summary>
  TIndicatorShowTextComponent = class(TSpelltargetVisualizerComponent)
    private
      const
      DEFAULT_OFFSET_FROM_CURSOR : RIntVector2 = (X : 25; Y : - 10);
    protected
      FShownResource : EnumResource;
      FResourceGroup : SetComponentGroup;
      FResourceFromCommander, FNoCap, FResourceGroupOfSpell, FClamps, FUseFixedCap : boolean;
      FFixedCap : integer;
      FText : TVertexFont;
      FCursorOffset : RIntVector2;
      FColor, FColorAtCap : RColor;
      FClamp : RIntVector2;

      FSpelltargetVisualizer : boolean;
      FTargetPosition : RVector3;
      procedure Visualize(Data : TCommanderSpellData); override;
      procedure Hide; override;

      procedure Idle; virtual;
      procedure Render; virtual;
    published
      [XEvent(eiIdle, epLower, etTrigger, esGlobal)]
      function OnIdle() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function ShowResource(Resource : EnumResource) : TIndicatorShowTextComponent;
      function ResourceGroup(Group : TArray<byte>) : TIndicatorShowTextComponent;
      function ResourceFromCommander : TIndicatorShowTextComponent;
      function Clamp(Minimum, Maximum : integer) : TIndicatorShowTextComponent;
      function Color(Color : cardinal) : TIndicatorShowTextComponent;
      function ColorAtCap(Color : cardinal) : TIndicatorShowTextComponent;
      function FixedCap(Value : integer) : TIndicatorShowTextComponent;
      function NoCap : TIndicatorShowTextComponent;
      function SpelltargetVisualizer : TIndicatorShowTextComponent;
      function ResourceGroupOfSpell : TIndicatorShowTextComponent;
      function CursorOffset(X, Y : integer) : TIndicatorShowTextComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> For each target the eiWelaUnitPattern is meta created and placed there. </summary>
  TSpelltargetVisualizerShowPatternComponent = class(TSpelltargetVisualizerComponent)
    protected
      FForIndex : integer;
      FPattern : TArray<TEntity>;
      procedure Visualize(Data : TCommanderSpellData); override;
      procedure Hide; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function ShowForIndex(Index : integer) : TSpelltargetVisualizerShowPatternComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Places a line between the first to targets. If fewer targets are passed, nothing will be showed. </summary>
  TSpelltargetVisualizerLineBetweenTargetsComponent = class(TSpelltargetVisualizerComponent)
    protected
      FLine : TVertexLine;
      FTexture, FInvalidTexture : TTexture;
      FRatio : single;
      procedure Visualize(Data : TCommanderSpellData); override;
      procedure Hide; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function Width(Width : single) : TSpelltargetVisualizerLineBetweenTargetsComponent;
      function Additive : TSpelltargetVisualizerLineBetweenTargetsComponent;
      function Texture(const TexturePath : string) : TSpelltargetVisualizerLineBetweenTargetsComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> A selected entity gets this component. </summary>
  TSelectedEntityComponent = class(TEntityComponent)
    protected
      SendUnselect : boolean;
      FTexture, FRangeTexture : TTexture;
      FQuad, FRangeQuad : TVertexWorldspaceQuad;
    published
      [XEvent(eiSelectEntity, epLower, etTrigger, esGlobal)]
      /// <summary> Kills this component. </summary>
      function OnSelectEntity(Entity : RParam) : boolean;
      [XEvent(eiIdle, epLow, etTrigger, esGlobal)]
      /// <summary> Renders a circle around the selected entity. </summary>
      function OnIdle : boolean;
      [XEvent(eiUnitProperties, epMiddle, etRead)]
      /// <summary> Tags the unit with certain properties. </summary>
      function OnUnitProperies(Previous : RParam) : RParam;
    public
      constructor Create(Owner : TEntity); reintroduce;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes the target gridpoints in red or green, if it's blocked or not. </summary>
  TWelaTargetConstraintGridVisualizedComponent = class(TWelaTargetConstraintGridComponent)
    protected
      function CheckGridNode(TargetBuildZone : TBuildZone; WorldCoord : RVector2) : boolean; override;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  TShowOnMinimapComponent = class(TEntityComponent)
    protected
      FIconSize : single;
      FIconPath : string;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Register at minimap. </summary>
      function OnAfterCreate() : boolean;
    public
      constructor Create(Owner : TEntity); reintroduce;
      function SetIconSize(Size : single) : TShowOnMinimapComponent;
      destructor Destroy(); override;
  end;

implementation

{ TTooltipUnitAbilityComponent }

constructor TTooltipUnitAbilityComponent.Create(Owner : TEntity; const AbilityName : string);
begin
  CreateGrouped(Owner, nil, AbilityName);
end;

constructor TTooltipUnitAbilityComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; const AbilityName : string);
begin
  inherited CreateGrouped(Owner, Group);
  FAbilityname := AbilityName;
  FKeywords := TList<string>.Create;
  FVariables := TObjectList<TTranslationVariable>.Create;
end;

destructor TTooltipUnitAbilityComponent.Destroy;
begin
  FKeywords.Free;
  FVariables.Free;
  inherited;
end;

function TTooltipUnitAbilityComponent.IsCardDescription : TTooltipUnitAbilityComponent;
begin
  Result := self;
  FIsCardDescription := True;
end;

function TTooltipUnitAbilityComponent.Keyword(const Keyword : string) : TTooltipUnitAbilityComponent;
begin
  Result := self;
  FKeywords.Add(Keyword);
end;

function TTooltipUnitAbilityComponent.OnBuildAbilityList(AbilityIDList, KeywordIDList, CardDescriptionRaw : RParam) : boolean;
var
  List : TList<RAbilityDescription>;
  KeyWordList : TList<string>;
  Keyword : string;
  CardDescription : TCardDescription;
begin
  Result := True;
  // add ability
  if not FIsCardDescription then
  begin
    List := AbilityIDList.AsType<TList<RAbilityDescription>>;
    if assigned(List) and (self.FAbilityname <> '') then
        List.Add(RAbilityDescription.Create(self.FAbilityname.ToLowerInvariant, FVariables));
  end;
  // add keywords avoiding duplicates
  KeyWordList := KeywordIDList.AsType<TList<string>>;
  if assigned(KeyWordList) then
  begin
    for Keyword in FKeywords do
    begin
      if not KeyWordList.Contains(Keyword.ToLowerInvariant) then
          KeyWordList.Add(Keyword.ToLowerInvariant);
    end;
  end;
  // add card description
  if FIsCardDescription then
  begin
    CardDescription := CardDescriptionRaw.AsType<TCardDescription>;
    if assigned(CardDescription) then
        CardDescription.Fill(self.FAbilityname.ToLowerInvariant, FVariables);
  end;
end;

function TTooltipUnitAbilityComponent.PassInteger(const Key : string; Value : integer) : TTooltipUnitAbilityComponent;
begin
  Result := PassInteger(Key, Value, '');
end;

function TTooltipUnitAbilityComponent.PassInteger(const Key : string; Value : integer; const SpanClass : string) : TTooltipUnitAbilityComponent;
begin
  Result := self;
  FVariables.Add(TTranslationIntegerVariable.Create(Key, SpanClass, Value, 0, False));
end;

function TTooltipUnitAbilityComponent.PassPercentage(const Key : string; Value : integer) : TTooltipUnitAbilityComponent;
begin
  Result := PassPercentage(Key, Value, '');
end;

function TTooltipUnitAbilityComponent.PassSingle(const Key : string; IntegralPart, FractionalPart : integer) : TTooltipUnitAbilityComponent;
begin
  Result := PassSingle(Key, IntegralPart, FractionalPart, '');
end;

function TTooltipUnitAbilityComponent.PassSingleAsInteger(const Key : string; Value : single; const SpanClass : string) : TTooltipUnitAbilityComponent;
begin
  Result := self;
  FVariables.Add(TTranslationIntegerVariable.Create(Key, SpanClass, round(Value), 0, False));
end;

function TTooltipUnitAbilityComponent.PassString(const Key, Value : string) : TTooltipUnitAbilityComponent;
begin
  Result := PassString(Key, Value, '');
end;

function TTooltipUnitAbilityComponent.PassPercentage(const Key : string; Value : integer; const SpanClass : string) : TTooltipUnitAbilityComponent;
begin
  Result := self;
  FVariables.Add(TTranslationIntegerVariable.Create(Key, SpanClass, Value, 0, True));
end;

function TTooltipUnitAbilityComponent.PassSingle(const Key : string; IntegralPart, FractionalPart : integer; const SpanClass : string) : TTooltipUnitAbilityComponent;
begin
  Result := self;
  FVariables.Add(TTranslationIntegerVariable.Create(Key, SpanClass, IntegralPart, FractionalPart, False));
end;

function TTooltipUnitAbilityComponent.PassSingleAsInteger(const Key : string; Value : single) : TTooltipUnitAbilityComponent;
begin
  Result := PassSingleAsInteger(Key, Value, '');
end;

function TTooltipUnitAbilityComponent.PassString(const Key, Value, SpanClass : string) : TTooltipUnitAbilityComponent;
begin
  Result := self;
  FVariables.Add(TTranslationStringVariable.Create(Key, SpanClass, Value));
end;

{ TAbilitybuttonComponent }

procedure TAbilitybuttonComponent.DeRegisterButton;
begin
  FreeAndNil(FSpell);
end;

function TAbilitybuttonComponent.IsMultiMode(ModeGroups : TArray<byte>) : TAbilitybuttonComponent;
begin
  Result := self;
  FMultiMode := ModeGroups;
end;

destructor TAbilitybuttonComponent.Destroy;
begin
  DeRegisterButton;
  inherited;
end;

procedure TAbilitybuttonComponent.GenerateSpellData;
var
  MetaInf : TEntity;
  TargetType : EnumCommanderAbilityTargetType;
  TargetCount : integer;
  Targets : TArray<RCommanderAbilityTarget>;
  Range : single;
begin
  MetaInf := GetDataEntity;

  TargetType := ctNone;
  TargetCount := 0;
  if assigned(MetaInf) then
  begin
    TargetType := MetaInf.Eventbus.Read(eiAbilityTargetType, []).AsEnumType<EnumCommanderAbilityTargetType>;
    TargetCount := MetaInf.Eventbus.Read(eiAbilityTargetCount, []).AsInteger;
  end;
  if not assigned(MetaInf) or (TargetType = ctNone) then
  begin
    TargetType := Eventbus.Read(eiAbilityTargetType, [], ComponentGroup).AsEnumType<EnumCommanderAbilityTargetType>;
    TargetCount := Eventbus.Read(eiAbilityTargetCount, [], ComponentGroup).AsInteger;
  end;
  TargetCount := Max(1, TargetCount);
  Range := Eventbus.Read(eiAbilityTargetRange, [], ComponentGroup).AsSingle;

  Targets := HArray.Generate<RCommanderAbilityTarget>(TargetCount, RCommanderAbilityTarget.CreateUnset(TargetType));
  FSpell := TCommanderSpellData.Create(GlobalEventbus, FOwner.ID, ComponentGroup, Targets, Range);
end;

function TAbilitybuttonComponent.OnClearGUI : boolean;
begin
  Result := True;
  DeRegisterButton;
end;

procedure TAbilitybuttonComponent.RegisterButton;
begin
  GenerateSpellData;
end;

function TAbilitybuttonComponent.GetDataEntity() : TEntity;
var
  Pattern : string;
begin
  Pattern := Eventbus.Read(eiWelaUnitPattern, [], ComponentGroup).AsString;
  if Pattern = '' then Result := nil
  else Result := EntityDataCache.GetEntity(Pattern, CardLeague, CardLevel);
end;

function TAbilitybuttonComponent.OnRegisterInGUI() : boolean;
begin
  Result := True;
  RegisterButton;
end;

{ TDeckCardButtonComponent }

function TDeckCardButtonComponent.OnIdle : boolean;
var
  CooldownProgress, CooldownSeconds : single;
  CurrentCharges, MaxCharges : integer;
  IsReady : boolean;
begin
  Result := True;
  if assigned(FHUDDeckSlot) then
  begin
    IsReady := Eventbus.Read(eiIsReady, [], ComponentGroup).AsBoolean;
    if FHUDDeckSlot.IsReady <> IsReady then
        FHUDDeckSlot.IsReady := IsReady;

    // Display charges
    CurrentCharges := Owner.Balance(reCharge, ComponentGroup).AsInteger;
    if FHUDDeckSlot.CurrentCharges <> CurrentCharges then
        FHUDDeckSlot.CurrentCharges := CurrentCharges;

    MaxCharges := Owner.Cap(reCharge, ComponentGroup).AsInteger;
    if FHUDDeckSlot.MaxCharges <> MaxCharges then
        FHUDDeckSlot.MaxCharges := MaxCharges;

    // update cooldown if not reached cap
    if CurrentCharges < MaxCharges then
    begin
      CooldownProgress := HMath.Saturate(Eventbus.Read(eiCooldownProgress, [], FCooldownGroup).AsSingle);
      if FHUDDeckSlot.ChargeProgress <> CooldownProgress then
          FHUDDeckSlot.ChargeProgress := CooldownProgress;
      CooldownSeconds := Eventbus.Read(eiCooldown, [], FCooldownGroup).AsInteger * (1 - CooldownProgress) / 1000;
      if FHUDDeckSlot.CooldownSeconds <> CooldownSeconds then
          FHUDDeckSlot.CooldownSeconds := CooldownSeconds;
    end;
  end;
end;

procedure TDeckCardButtonComponent.RegisterButton;
begin
  inherited;
  assert(assigned(FCardInfo), Format('TDeckCardButtonComponent.RegisterButton: Empty card info for build button in slot %d!', [FSlot]));
  if assigned(FCardInfo) then
  begin
    FSpell.IsSpawner := FCardInfo.IsSpawner;
    FSpell.IsDrop := not FCardInfo.IsSpawner and not FCardInfo.IsSpell;
    FSpell.IsSpell := FCardInfo.IsSpell;
    FSpell.IsEpic := FCardInfo.IsEpic;
    FSpell.MultiModes := FMultiMode;
    if assigned(HUD) then
    begin
      FHUDDeckSlot := HUD.RegisterDeckSlot(FCardInfo, FSlot, FSpell);
      // deckslot takes the ownership
      FSpell := nil;
    end;
  end;
end;

function TDeckCardButtonComponent.SetCooldownGroup(Group : TArray<byte>) : TDeckCardButtonComponent;
begin
  Result := self;
  FCooldownGroup := ByteArrayToComponentGroup(Group);
end;

function TDeckCardButtonComponent.CardInfo(CardInfo : TCardInfo) : TDeckCardButtonComponent;
begin
  Result := self;
  FCardInfo := CardInfo;
end;

function TDeckCardButtonComponent.Slot(Slot : integer) : TDeckCardButtonComponent;
begin
  Result := self;
  FSlot := Slot;
end;

procedure TDeckCardButtonComponent.DeRegisterButton;
begin
  inherited;
  if assigned(HUD) then
      HUD.DeregisterDeckSlot(FHUDDeckSlot);
  FHUDDeckSlot := nil;
end;

{ TWelaTargetConstraintGridVisualizedComponent }

function TWelaTargetConstraintGridVisualizedComponent.CheckGridNode(TargetBuildZone : TBuildZone; WorldCoord : RVector2) : boolean;
var
  Color : RColor;
begin
  Result := inherited CheckGridNode(TargetBuildZone, WorldCoord);
  Color := HGeneric.TertOp(Result, RColor.CGREEN, RColor.CRED);

  TargetBuildZone.RenderGridNode(TargetBuildZone.PositionToCoord(WorldCoord), Color);
end;

constructor TWelaTargetConstraintGridVisualizedComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  CheckAllFields := True;
end;

{ TRangeIndicatorComponent }

constructor TRangeIndicatorComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FColor := RColor.CBLACK;
end;

procedure TRangeIndicatorComponent.Idle;
begin
  LinePool.DrawCircleOnTerrain(ClientGame.ClientMap.Terrain, Owner.DisplayPosition, Eventbus.Read(eiWelaAreaOfEffect, []).AsSingle, FColor);
end;

function TRangeIndicatorComponent.IsPermanent : TRangeIndicatorComponent;
begin
  Result := self;
  FPermanent := True;
end;

function TRangeIndicatorComponent.OnDeploy : boolean;
begin
  Result := True;
  if not FPermanent and assigned(Game) then Game.EntityManager.FreeComponent(Owner.ID, self.UniqueID);
end;

function TRangeIndicatorComponent.OnColorAdjustment(ColorAdjustment, absH, absS, absV : RParam) : boolean;
begin
  Result := True;
  FColor.HSV := ColorAdjustment.AsVector3;
end;

function TRangeIndicatorComponent.OnIdle : boolean;
begin
  Result := True;
  Idle;
end;

{ TSelectedEntityComponent }

constructor TSelectedEntityComponent.Create(Owner : TEntity);
var
  TexturePath : string;
begin
  inherited Create(Owner);
  SendUnselect := True;
  if upBuilding in Eventbus.Read(eiUnitProperties, []).AsSetType<SetUnitProperty> then TexturePath := HUD_BUILDING_SELECTION_TEXTURE
  else TexturePath := HUD_SELECTION_TEXTURE;
  FTexture := TTexture.CreateTextureFromFile(AbsolutePath(TexturePath), GFXD.Device3D, mhGenerate, True);
  FQuad := TVertexWorldspaceQuad.Create(VertexEngine);
  FQuad.Up := RVector3.UNITX;
  FQuad.Left := RVector3.UNITZ;
  FQuad.Texture := FTexture;
  FQuad.OwnsTexture := True;

  FRangeTexture := TTexture.CreateTextureFromFile(AbsolutePath(HUD_SELECTION_RANGE_TEXTURE), GFXD.Device3D, mhGenerate, True);
  FRangeQuad := TVertexWorldspaceQuad.Create(VertexEngine);
  FRangeQuad.Up := RVector3.UNITX;
  FRangeQuad.Left := RVector3.UNITZ;
  FRangeQuad.Texture := FRangeTexture;
  FRangeQuad.OwnsTexture := True;
end;

destructor TSelectedEntityComponent.Destroy;
begin
  // unsubscribe first to don't infinite frees with selectionevent
  inherited;
  FRangeQuad.Free;
  FQuad.Free;
  if SendUnselect then GlobalEventbus.Trigger(eiSelectEntity, [nil]);
end;

function TSelectedEntityComponent.OnIdle : boolean;
var
  Range : single;
begin
  Result := True;
  Eventbus.Trigger(eiDrawOutline, [RColor.CTRANSPARENTBLACK, False]);
  if [upUnit, upBuilding] * Owner.UnitProperties <> [] then
  begin
    // Draw circle under entity
    FQuad.Position := Owner.DisplayPosition.SetY(0.02);
    FQuad.Size := RVector2.Create((Owner.CollisionRadius + 0.2) * 2.0);
    FQuad.Color := RColor(TEAMCOLORS[Owner.TeamID]).SetAlphaF(0.8);
    FQuad.Up := Owner.DisplayFront.X0Z;
    FQuad.Left := FQuad.Up.XZ.GetOrthogonal.X0Y;
    FQuad.AddRenderJob;
    // Draw range if ranged
    Range := Eventbus.Read(eiWelaRange, [], [GROUP_MAINWEAPON]).AsSingle;
    if Range > 2 then
    begin
      FRangeQuad.Position := FQuad.Position;
      FRangeQuad.Size := RVector2.Create((Range + Owner.CollisionRadius) * 2.0);
      FRangeQuad.AddRenderJob;
    end;
  end;
end;

function TSelectedEntityComponent.OnSelectEntity(Entity : RParam) : boolean;
begin
  Result := True;
  SendUnselect := False;
  DeferFree;
end;

function TSelectedEntityComponent.OnUnitProperies(Previous : RParam) : RParam;
var
  Props : SetUnitProperty;
begin
  Props := Previous.AsSetType<SetUnitProperty>;
  Result := RParam.From<SetUnitProperty>(Props + [upSelected]);
end;

{ TShowOnMiniMapComponent }

constructor TShowOnMinimapComponent.Create(Owner : TEntity);
begin
  inherited Create(Owner);
  FIconSize := Owner.CollisionRadius;
end;

destructor TShowOnMinimapComponent.Destroy;
begin
  if assigned(ClientGame) then
      ClientGame.MinimapManager.RemoveFromMinimap(FOwner);
  inherited;
end;

function TShowOnMinimapComponent.OnAfterCreate : boolean;
begin
  Result := True;
  FIconPath := PATH_HUD_MINIMAP + Owner.UnitData(udMinimapIcon).AsString;
  FIconSize := Owner.UnitData(udMinimapIconSize).AsSingleDefault(FIconSize);
  if assigned(ClientGame) then
      ClientGame.MinimapManager.AddToMinimap(Owner, FIconPath, FIconSize);
end;

function TShowOnMinimapComponent.SetIconSize(Size : single) : TShowOnMinimapComponent;
begin
  Result := self;
  FIconSize := Size;
end;

{ TTextureRangeIndicatorComponent }

function TTextureRangeIndicatorComponent.Cone(DirectionX, DirectionZ : single) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FIsCone := True;
  FConeDirection := RVector2.Create(DirectionX, DirectionZ).Normalize;
  if assigned(FQuad) then
  begin
    FQuad.Up := FConeDirection.X0Y;
    FQuad.Left := FQuad.Up.Cross(RVector3.UNITY).Normalize;
  end;
end;

constructor TTextureRangeIndicatorComponent.Create(Owner : TEntity);
begin
  CreateGrouped(Owner, nil);
end;

constructor TTextureRangeIndicatorComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  SetTexture('SpelltargetGround.png');
  FQuad := TVertexWorldspaceQuad.Create(VertexEngine);
  FQuad.Up := RVector3.UNITX;
  FQuad.Left := RVector3.UNITZ;
  FQuad.Texture := FTexture;
  FQuad.BlendMode := BlendLinear;
  FSize := 1.0;
  FOpacity := 1.0;
end;

destructor TTextureRangeIndicatorComponent.Destroy;
begin
  FQuad.Free;
  FCircle.Free;
  FTexture.Free;
  FInvalidTexture.Free;
  inherited;
end;

function TTextureRangeIndicatorComponent.DrawCircle(Thickness : single) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FreeAndNil(FQuad);
  FCircle := TVertexWorldspaceCircle.Create(VertexEngine);
  FCircle.Up := RVector3.UNITZ;
  FCircle.Left := RVector3.UNITX;
  FCircle.Texture := FTexture;
  FCircle.Thickness := Thickness;
  FCircle.BlendMode := BlendLinear;
end;

function TTextureRangeIndicatorComponent.DrawOnShowSpawnZone(Zones : TArray<byte>) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FDrawOnShowSpawnZone := True;
  FShownDynamicZones := ByteArrayToSetDynamicZone(Zones);
end;

function TTextureRangeIndicatorComponent.GetSize : single;
var
  RangeParam : RParam;
begin
  RangeParam := Eventbus.Read(eiWelaAreaOfEffect, [], ComponentGroup);
  if RangeParam.IsEmpty or FUseWeaponrange then RangeParam := Eventbus.Read(eiWelaRange, [], ComponentGroup);
  Result := RangeParam.AsSingleDefault(1.0) * FSize;
end;

function TTextureRangeIndicatorComponent.HideInCaptureMode : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FHideInCaptureMode := True;
end;

procedure TTextureRangeIndicatorComponent.Idle;
var
  Range : single;
  Vertex : TVertexWorldspaceQuad;
begin
  if not FHideInCaptureMode or not HUD.CaptureMode then
  begin
    Range := GetSize;

    if assigned(FQuad) then
    begin
      Vertex := FQuad;
      FQuad.Size := RVector2.Create(Range * 2);
      if FIsCone then
          FQuad.Size := FQuad.Size * RVector2.Create(1, 0.5);
    end
    else if assigned(FCircle) then
    begin
      Vertex := FCircle;
      FCircle.Radius := Range;
      if FCircle.Radius < 20 then FCircle.Samples := 64
      else FCircle.Samples := 128;
    end
    else exit;

    Vertex.Position := Owner.DisplayPosition.SetY(GROUND_EPSILON);
    if FIsCone then
        Vertex.Position := Vertex.Position + (Vertex.Up * (Vertex.Size.Y / 2));
    Vertex.Position := Vertex.Position + FOffset.X0Y;
    if FColor.R > 0.5 then Vertex.Texture := FInvalidTexture
    else Vertex.Texture := FTexture;
    if FShowTeamColor then
        Vertex.Color := GetTeamColor(Owner.TeamID)
    else
        Vertex.Color := RColor.CWHITE;
    Vertex.Color := Vertex.Color.SetAlphaF(Vertex.Color.A * FOpacity);

    if not FDrawOnShowSpawnZone then
        Vertex.AddRenderJob;
  end;
end;

function TTextureRangeIndicatorComponent.Offset(OffsetX, OffsetZ : single) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FOffset := RVector2.Create(OffsetX, OffsetZ);
end;

function TTextureRangeIndicatorComponent.OnEnumerateSpawnZone(Zone, Previous : RParam) : RParam;
var
  realList : TList<RCircle>;
begin
  if not FDrawOnShowSpawnZone then exit(Previous);
  realList := Previous.AsType<TList<RCircle>>;
  if not assigned(realList) then
      realList := TList<RCircle>.Create;
  if (Owner.TeamID = ClientGame.CommanderManager.ActiveCommanderTeamID) and (Zone.AsEnumType<EnumDynamicZone> in FShownDynamicZones) then
      realList.Add(RCircle.Create(Owner.DisplayPosition.XZ, GetSize));
  Result := realList;
end;

function TTextureRangeIndicatorComponent.Opacity(Opacity : single) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FOpacity := Opacity;
end;

function TTextureRangeIndicatorComponent.SetAdditiveBlend : TTextureRangeIndicatorComponent;
begin
  if assigned(FQuad) then FQuad.BlendMode := BlendAdditive;
  if assigned(FCircle) then FCircle.BlendMode := BlendAdditive;
  Result := self;
end;

function TTextureRangeIndicatorComponent.SetTexture(TextureName : string) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  if TextureName.Contains('\') then TextureName := AbsolutePath(TextureName)
  else TextureName := AbsolutePath(PATH_SPELLTARGET + TextureName);
  FTexture.Free;
  FTexture := TTexture.CreateTextureFromFile(TextureName, GFXD.Device3D, mhGenerate, True);
  FInvalidTexture.Free;
  FInvalidTexture := TTexture.CreateTextureFromFile(ChangeFileExt(TextureName, 'Invalid' + ExtractFileExt(TextureName)), GFXD.Device3D, mhGenerate, True);
end;

function TTextureRangeIndicatorComponent.ShowTeamColor : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FShowTeamColor := True;
end;

function TTextureRangeIndicatorComponent.ShowWeaponRange : TTextureRangeIndicatorComponent;
begin
  FUseWeaponrange := True;
  Result := self;
end;

function TTextureRangeIndicatorComponent.Size(Size : single) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FSize := Size;
end;

function TTextureRangeIndicatorComponent.Slice(SliceFrom, SliceTo : single) : TTextureRangeIndicatorComponent;
begin
  Result := self;
  FCircle.SliceFrom := SliceFrom;
  FCircle.SliceTo := SliceTo;
end;

{ TRangeIndicatorHighlightEntitiesComponent }

procedure TRangeIndicatorHighlightEntitiesComponent.Idle;
var
  Entities : TList<TEntity>;
  Range : RParam;
  ValidateGroup : SetComponentGroup;
begin
  Range := Eventbus.Read(eiWelaAreaOfEffect, [], ComponentGroup);
  if Range.IsEmpty then Range := Eventbus.Read(eiWelaRange, [], ComponentGroup);
  if FValidGroup <> [] then
      ValidateGroup := FValidGroup
  else
      ValidateGroup := ComponentGroup;
  Entities := GlobalEventbus.Read(eiEntitiesInRange, [
    Owner.Position,
    Range,
    -1,
    RParam.From<EnumTargetTeamConstraint>(tcAll),
    RParam.FromProc<ProcEntityFilterFunction>(
    function(Entity : TEntity) : boolean
    begin
      Result := Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Entity).ToRParam], ValidateGroup).AsRTargetValidity.IsValid;
    end)
    ]).AsType<TList<TEntity>>;
  if assigned(Entities) then
  begin
    TAdvancedList<TEntity>(Entities).Each(
      procedure(const Entity : TEntity)
      begin
        if (FInvalidGroup = []) or
          Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Entity).ToRParam], FInvalidGroup).AsRTargetValidity.IsValid then
            Entity.Eventbus.Trigger(eiDrawOutline, [Settings.GetColorOption(coGameplayPreviewValidColor), False])
        else
            Entity.Eventbus.Trigger(eiDrawOutline, [Settings.GetColorOption(coGameplayPreviewInValidColor), False]);
      end);
    Entities.Free;
  end;
end;

function TRangeIndicatorHighlightEntitiesComponent.Invalid(Group : TArray<byte>) : TRangeIndicatorHighlightEntitiesComponent;
begin
  Result := self;
  FInvalidGroup := ByteArrayToComponentGroup(Group);
end;

function TRangeIndicatorHighlightEntitiesComponent.Valid(Group : TArray<byte>) : TRangeIndicatorHighlightEntitiesComponent;
begin
  Result := self;
  FValidGroup := ByteArrayToComponentGroup(Group);
end;

{ TSpelltargetvisualizerComponent }

function TSpelltargetVisualizerComponent.OnHideVisualization : boolean;
begin
  Result := True;
  Hide;
end;

function TSpelltargetVisualizerComponent.OnVisualize(Data : RParam) : boolean;
begin
  Result := True;
  Visualize(Data.AsType<TCommanderSpellData>);
end;

{ TSpelltargetVisualizerShowPatternComponent }

constructor TSpelltargetVisualizerShowPatternComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FForIndex := -1;
end;

destructor TSpelltargetVisualizerShowPatternComponent.Destroy;
var
  i : integer;
begin
  for i := 0 to length(FPattern) - 1 do FPattern[i].DeferFree;
  FPattern := nil;
  inherited;
end;

procedure TSpelltargetVisualizerShowPatternComponent.Hide;
var
  i : integer;
begin
  for i := 0 to length(FPattern) - 1 do FPattern[i].DeferFree;
  FPattern := nil;
end;

function TSpelltargetVisualizerShowPatternComponent.ShowForIndex(Index : integer) : TSpelltargetVisualizerShowPatternComponent;
begin
  Result := self;
  FForIndex := index;
end;

procedure TSpelltargetVisualizerShowPatternComponent.Visualize(Data : TCommanderSpellData);
var
  Targets : ACommanderAbilityTarget;
  i : integer;

  procedure Apply(TargetDisplay : TEntity; Target : RCommanderAbilityTarget);
  var
    Ready : RParam;
    TargetBuildZone : TBuildZone;
    BuildGridTarget : RTarget;
    TargetPos, TargetFront : RVector2;
    NeededSize : RIntVector2;
    procedure TargetPossibilityColor(Possible : boolean);
    begin
      if Possible or Game.IsSandbox then
      begin
        TargetDisplay.Eventbus.Trigger(eiColorAdjustment, [RVector3.Create(1 / 3, 1, 1), True, True, True]);
        TargetDisplay.Eventbus.Trigger(eiDrawOutline, [Settings.GetColorOption(coGameplayPreviewValidColor), True]);
      end
      else
      begin
        TargetDisplay.Eventbus.Trigger(eiColorAdjustment, [RVector3.Create(0, 1, 1), True, True, True]);
        TargetDisplay.Eventbus.Trigger(eiDrawOutline, [Settings.GetColorOption(coGameplayPreviewInValidColor), True]);
      end
    end;

  begin
    if assigned(TargetDisplay) then
    begin
      if not(Target.IsBuildTarget) then
      begin
        Ready := Eventbus.Read(eiIsReady, [], ComponentGroup + CurrentEvent.CalledToGroup);
        TargetPossibilityColor((Ready.IsEmpty or Ready.AsBoolean) and Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(Target.ToRTarget(Owner)).ToRParam], ComponentGroup + CurrentEvent.CalledToGroup).AsRTargetValidity.IsValid);
        TargetPos := Target.GetWorldPosition;
        TargetDisplay.Position := TargetPos;
        TargetFront := Map.Lanes.GetOrientationOfNextLane(TargetPos, Owner.TeamID);
        TargetDisplay.Front := TargetFront;
      end
      else
      // if buildzone target, discretize the position of the target
      begin
        TargetBuildZone := Target.ToRTarget(Owner).GetBuildZone;
        if not assigned(TargetBuildZone) then
        begin
          // can't be build there
          TargetDisplay.Position := Target.GetWorldPosition;
          TargetDisplay.Front := RVector2.UNITY;
          TargetPossibilityColor(False);
        end
        else
        begin
          // target is on grid, check for possibility
          BuildGridTarget := Target.ToRTarget(Owner);
          Ready := Eventbus.Read(eiIsReady, [], CurrentEvent.CalledToGroup);
          TargetPossibilityColor(Eventbus.Read(eiWelaTargetPossible, [ATarget.Create(BuildGridTarget).ToRParam], ComponentGroup + CurrentEvent.CalledToGroup).AsRTargetValidity.IsValid and (Ready.IsEmpty or Ready.AsBoolean));
          NeededSize := Eventbus.Read(eiWelaNeededGridSize, [], CurrentEvent.CalledToGroup).AsIntVector2;
          TargetDisplay.Position := BuildGridTarget.GetRealBuildPosition(NeededSize);
          TargetDisplay.Front := TargetBuildZone.Front;
        end;
      end
    end;
  end;

  function GetMetaEntity() : TEntity;
  var
    Pattern : RParam;
    SkinID : string;
  begin
    Pattern := Eventbus.Read(eiWelaUnitPattern, [], CurrentEvent.CalledToGroup);
    if Pattern.IsEmpty or (Pattern.AsString = '') then Result := nil
    else
    begin
      SkinID := Owner.GetSkinID(CurrentEvent.CalledToGroup);
      Result := TEntity.CreateMetaFromScript(
        Pattern.AsString,
        GlobalEventbus,
        procedure(Entity : TEntity)
        var
          Caller : TEntity;
          CardTimesPlayed : integer;
        begin
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), CardLevel);
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), CardLeague);
          Entity.SkinID := SkinID;
          Entity.Blackboard.SetValue(eiSkinIdentifier, [], SkinID);
          if assigned(Game) and Game.EntityManager.TryGetEntityByID(Data.EntityID, Caller) then
          begin
            // plus one as it will be played
            CardTimesPlayed := Caller.Balance(reCardTimesPlayed, Data.ComponentGroup).AsInteger + 1;
            Entity.Eventbus.Write(eiResourceBalance, [ord(reCardTimesPlayed), CardTimesPlayed]);
          end;
        end);
      TLogicToWorldComponent.Create(Result);
      if Result.Eventbus.Read(eiTeamID, []).IsEmpty then
          Result.Eventbus.Write(eiTeamID, [Eventbus.Read(eiTeamID, [])]);
      Result.Eventbus.Trigger(eiAfterCreate, []);
    end;
  end;

var
  Caller : TEntity;
  CardTimesPlayed : integer;
begin
  Targets := Data.Targets;
  i := length(FPattern);
  if length(Targets) > i then
  begin
    setlength(FPattern, length(Targets));
    for i := i to length(FPattern) - 1 do FPattern[i] := nil;
  end;
  // update patterns
  for i := 0 to length(Targets) - 1 do
  begin
    if Targets[i].IsSet and ((FForIndex < 0) or (i = FForIndex)) then
    begin
      if not assigned(FPattern[i]) then
      begin
        FPattern[i] := GetMetaEntity;
        assert(assigned(FPattern[i]), BuildExceptionMessage('No pattern found to visualize!'));
      end
      else
      begin
        if assigned(Game) and Game.EntityManager.TryGetEntityByID(Data.EntityID, Caller) then
        begin
          // plus one as it will be played
          CardTimesPlayed := Caller.Balance(reCardTimesPlayed, Data.ComponentGroup).AsInteger + 1;
          FPattern[i].Eventbus.Write(eiResourceBalance, [ord(reCardTimesPlayed), CardTimesPlayed]);
        end;
      end;
      Apply(FPattern[i], Targets[i]);
    end
    else
    begin
      FPattern[i].DeferFree;
      FPattern[i] := nil;
    end;
  end;
end;

{ TSpelltargetVisualizerLineBetweenTargetsComponent }

function TSpelltargetVisualizerLineBetweenTargetsComponent.Additive : TSpelltargetVisualizerLineBetweenTargetsComponent;
begin
  Result := self;
  FLine.BlendMode := BlendAdditive;
end;

constructor TSpelltargetVisualizerLineBetweenTargetsComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FLine := TVertexLine.Create(VertexEngine);
  FLine.Normal := RVector3.UNITY;
  self.Width(0.5);
  FLine.Color := FLine.Color.SetAlphaF(0.8);
  FRatio := 0.5;
  Texture('SpelltargetLine.png');
end;

destructor TSpelltargetVisualizerLineBetweenTargetsComponent.Destroy;
begin
  FLine.Free;
  FTexture.Free;
  FInvalidTexture.Free;
  inherited;
end;

procedure TSpelltargetVisualizerLineBetweenTargetsComponent.Hide;
begin
  // nothing to do here, as visualization only added each frame
end;

function TSpelltargetVisualizerLineBetweenTargetsComponent.Texture(const TexturePath : string) : TSpelltargetVisualizerLineBetweenTargetsComponent;
var
  FullPath : string;
begin
  Result := self;
  FullPath := AbsolutePath(PATH_SPELLTARGET + TexturePath);
  FTexture.Free;
  FTexture := TTexture.CreateTextureFromFile(FullPath, GFXD.Device3D, mhGenerate, True);
  FInvalidTexture.Free;
  FInvalidTexture := TTexture.CreateTextureFromFile(HFilepathManager.AppendToFilename(FullPath, 'Invalid'), GFXD.Device3D, mhGenerate, True);
end;

procedure TSpelltargetVisualizerLineBetweenTargetsComponent.Visualize(Data : TCommanderSpellData);
var
  Targets : ACommanderAbilityTarget;
  Validity : RTargetValidity;
  Ready : boolean;
begin
  Targets := Data.Targets;
  if (length(Targets) < 2) or not Targets[1].IsSet then exit;

  Validity := Eventbus.Read(eiWelaTargetPossible, [Targets.ToRTargets(Owner).ToRParam], CurrentEvent.CalledToGroup).AsRTargetValidity;
  Ready := Eventbus.Read(eiIsReady, [], CurrentEvent.CalledToGroup).AsBooleanDefaultTrue and Validity.IsValid;

  FLine.Start := Targets[0].GetWorldPosition.X0Y.SetY(0.1);
  FLine.Target := Targets[1].GetWorldPosition.X0Y.SetY(0.1);

  FLine.CoordinateRect := RRectFloat.Create(0, 0, 1, FRatio * FLine.Start.Distance(FLine.Target) / FLine.Width);
  FLine.CoordinateRect.Translate(0, ((TimeManager.GetTimestamp mod 1200) / 1200));

  if Ready then
      FLine.Texture := FTexture
  else
      FLine.Texture := FInvalidTexture;

  FLine.AddRenderJob;
end;

function TSpelltargetVisualizerLineBetweenTargetsComponent.Width(Width : single) : TSpelltargetVisualizerLineBetweenTargetsComponent;
begin
  Result := self;
  FLine.Width := Width;
end;

{ TSpelltargetVisualizerShowTextureComponent }

function TSpelltargetVisualizerShowTextureComponent.Additive(ForIndex : integer) : TSpelltargetVisualizerShowTextureComponent;
begin
  Result := self;
  GetOrCreateInfo(ForIndex).Additive := True;
end;

constructor TSpelltargetVisualizerShowTextureComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FInfo := TObjectDictionary<integer, TTargetInfo>.Create([doOwnsValues]);
  FDefaultInfo := TTargetInfo.Create;
  FInfo.Add(-1, FDefaultInfo);
  SetTexture('SpelltargetEntity.png');
  FQuads := TObjectList<TVertexWorldspaceQuad>.Create;
end;

destructor TSpelltargetVisualizerShowTextureComponent.Destroy;
begin
  FQuads.Free;
  // FDefaultInfo.Free; don't free it because its added to the dict
  FInfo.Free;
  inherited;
end;

function TSpelltargetVisualizerShowTextureComponent.GetInfo(Index : integer) : TTargetInfo;
begin
  if not FInfo.TryGetValue(index, Result) then
      Result := FInfo[-1];
end;

function TSpelltargetVisualizerShowTextureComponent.GetOrCreateInfo(Index : integer) : TTargetInfo;
begin
  if not FInfo.TryGetValue(index, Result) then
  begin
    Result := TTargetInfo.Create;
    FInfo.Add(index, Result);
  end;
end;

procedure TSpelltargetVisualizerShowTextureComponent.Hide;
begin
  FQuads.Clear;
end;

function TSpelltargetVisualizerShowTextureComponent.NoValidChecks : TSpelltargetVisualizerShowTextureComponent;
begin
  Result := self;
  FNoValidChecks := True;
end;

function TSpelltargetVisualizerShowTextureComponent.Opacity(Opacity : single; ForIndex : integer) : TSpelltargetVisualizerShowTextureComponent;
begin
  Result := self;
  GetOrCreateInfo(ForIndex).Opacity := Opacity;
end;

function TSpelltargetVisualizerShowTextureComponent.SetSize(Size : single; ForIndex : integer) : TSpelltargetVisualizerShowTextureComponent;
begin
  Result := self;
  GetOrCreateInfo(ForIndex).Size := Size * 2;
end;

function TSpelltargetVisualizerShowTextureComponent.SetTexture(TexturePath : string; ForIndex : integer) : TSpelltargetVisualizerShowTextureComponent;
var
  info : TTargetInfo;
  FullPath : string;
begin
  Result := self;
  info := GetOrCreateInfo(ForIndex);
  FullPath := AbsolutePath(PATH_SPELLTARGET + TexturePath);
  info.Texture.Free;
  info.Texture := TTexture.CreateTextureFromFile(FullPath, GFXD.Device3D, mhGenerate, True);
  if not FNoValidChecks then
  begin
    info.Invalidtexture.Free;
    info.Invalidtexture := TTexture.CreateTextureFromFile(HFilepathManager.AppendToFilename(FullPath, 'Invalid'), GFXD.Device3D, mhGenerate, True);
  end;
end;

procedure TSpelltargetVisualizerShowTextureComponent.Visualize(Data : TCommanderSpellData);
var
  Targets : ACommanderAbilityTarget;
  i : integer;
  Ready, AllSet : boolean;
  Validity : RTargetValidity;
begin
  Targets := Data.Targets;
  // delete unset targets
  for i := length(Targets) - 1 downto 0 do
    if not Targets[i].IsSet and (FQuads.Count > i) then
        FQuads.Delete(i)
    else break;
  // show set targets
  AllSet := Data.AllTargetsSet;
  if not FNoValidChecks then
      Validity := Eventbus.Read(eiWelaTargetPossible, [Targets.ToRTargets(Owner).ToRParam], CurrentEvent.CalledToGroup).AsRTargetValidity;
  for i := 0 to length(Targets) - 1 do
    if Targets[i].IsSet then
    begin
      if FQuads.Count <= i then
          FQuads.Add(TVertexWorldspaceQuad.Create(VertexEngine));
      FQuads[i].Position := Targets[i].GetWorldPosition.X0Y.SetY(GROUND_EPSILON);
      FQuads[i].Up := RVector3.UNITX;
      FQuads[i].Left := RVector3.UNITZ;
      FQuads[i].Size := RVector2.Create(GetInfo(i).Size);
      if GetInfo(i).Additive then
          FQuads[i].BlendMode := BlendAdditive
      else
          FQuads[i].BlendMode := BlendLinear;
      FQuads[i].Color := FQuads[i].Color.SetAlphaF(FQuads[i].Color.A * GetInfo(i).Opacity);

      Ready := FNoValidChecks or
        (Eventbus.Read(eiIsReady, [], CurrentEvent.CalledToGroup).AsBooleanDefaultTrue and
        (i in Validity.SingleValidityMask) and (not AllSet or Validity.TogetherValid));

      if Ready then
          FQuads[i].Texture := GetInfo(i).Texture
      else
          FQuads[i].Texture := GetInfo(i).Invalidtexture;
      if assigned(FQuads[i]) then
          FQuads[i].AddRenderJob;
    end
    else break;
end;

{ TSpelltargetVisualizerShowTextureComponent.TTargetInfo }

constructor TSpelltargetVisualizerShowTextureComponent.TTargetInfo.Create;
begin
  Size := 1.0;
  Opacity := 1.0;
end;

destructor TSpelltargetVisualizerShowTextureComponent.TTargetInfo.Destroy;
begin
  Texture.Free;
  Invalidtexture.Free;
  inherited;
end;

{ TEntityDisplayWrapperComponent }

constructor TEntityDisplayWrapperComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  if assigned(GUI) then
  begin
    FWrapper := TGUIStackPanel.Create(GUI, nil, '', GUI.FindUnique(HEALTHBARWRAPPER));
    FWrapper.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateAbsolute(0));
    FWrapper.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.Auto());
    FWrapper.ChangeStyle<EnumComponentAnchor>(gtAnchor, caCenter);
    FWrapper.ChangeStyle<EnumDrawSpace>(gtDrawSpace, dsWorldScreenSpace);
    FWrapper.ChangeStyle<EnumStackOrientation>(gtStackorientation, soVertical);
    FWrapper.ChangeStyle<RGSSSpaceData>(gtStackpartitioning, RGSSSpaceData.Auto());
  end;
end;

destructor TEntityDisplayWrapperComponent.Destroy;
begin
  FWrapper.Free;
  inherited;
end;

function TEntityDisplayWrapperComponent.OnAfterDeserialization : boolean;
begin
  Result := True;
  UpdatePosition;
end;

function TEntityDisplayWrapperComponent.OnGetEntityResourceWrapper : RParam;
begin
  Result := FWrapper;
end;

function TEntityDisplayWrapperComponent.OnIdle : boolean;
begin
  Result := True;
  if not assigned(FWrapper) then exit;

  if FWrapper.Visible then
      UpdatePosition;
end;

function TEntityDisplayWrapperComponent.SetOffset(YOffset : single) : TEntityDisplayWrapperComponent;
begin
  Result := self;
  FOffset.Y := YOffset;
end;

procedure TEntityDisplayWrapperComponent.UpdatePosition;
var
  Boundings : RSphere;
  Target : RVector3;
begin
  if not assigned(FWrapper) then exit;
  Boundings := Eventbus.Read(eiBoundings, []).AsTypeDefault<RSphere>(RSphere.CreateSphere(Owner.Position.X0Y, 2));
  Target := Boundings.Center + RVector3.UNITY * (Boundings.Radius + 1 + Owner.UnitData(udHealthbarOffset).AsSingle) + FOffset;
  FWrapper.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.CreateAbsolute(Target.X));
  FWrapper.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.CreateAbsolute(Target.Y));
  FWrapper.ChangeStyle<RGSSSpaceData>(gtPosition, 2, RGSSSpaceData.CreateAbsolute(Target.Z));
end;

{ TResourceDisplayComponent }

constructor TResourceDisplayComponent.Create(Owner : TEntity);
begin
  inherited;
  FResourceType := reHealth;
  FTeamOverride := -1;
end;

function TResourceDisplayComponent.HideIfEmpty : TResourceDisplayComponent;
begin
  Result := self;
  FHideIfEmpty := True;
end;

function TResourceDisplayComponent.HideIfFull : TResourceDisplayComponent;
begin
  Result := self;
  FHideIfFull := True;
end;

function TResourceDisplayComponent.IsEmpty : boolean;
begin
  Result := False;
end;

function TResourceDisplayComponent.IsFull : boolean;
begin
  Result := False;
end;

function TResourceDisplayComponent.IsVisible : boolean;
begin
  Result := inherited and
    (not FHideIfEmpty or not IsEmpty) and
    (not FHideIfFull or not IsFull);
end;

function TResourceDisplayComponent.ObservedResourceTypes : SetResource;
begin
  Result := [FResourceType];
end;

function TResourceDisplayComponent.OnSetResource(ID, Value : RParam) : boolean;
begin
  Result := True;
  if (EnumResource(ID.AsInteger) in ObservedResourceTypes) and IsLocalCall then
      ResourceChanged(Value);
end;

function TResourceDisplayComponent.OnSetResourceCap(ID, Value : RParam) : boolean;
begin
  Result := True;
  if (EnumResource(ID.AsInteger) in ObservedResourceTypes) and IsLocalCall then
      ResourceCapChanged(Value);
end;

procedure TResourceDisplayComponent.ResourceCapChanged(Value : RParam);
begin
  SetDirty;
end;

procedure TResourceDisplayComponent.ResourceChanged(Value : RParam);
begin
  SetDirty;
end;

function TResourceDisplayComponent.ShowAsTeam(TeamID : integer) : TResourceDisplayComponent;
begin
  Result := self;
  FTeamOverride := TeamID;
end;

function TResourceDisplayComponent.ShowResource(ResourceType : integer) : TResourceDisplayComponent;
begin
  Result := self;
  FResourceType := EnumResource(ResourceType);
end;

function TResourceDisplayComponent.TeamID : integer;
begin
  if FTeamOverride <> -1 then
      Result := FTeamOverride
  else
      Result := Owner.TeamID;
end;

{ TEntityDisplayComponent }

procedure TEntityDisplayComponent.ComputeVisibility;
begin

end;

constructor TEntityDisplayComponent.Create(Owner : TEntity);
begin
  inherited;
  SetDirty;
end;

function TEntityDisplayComponent.GetDefaultSize : RVector2;
begin
  Result := RVector2.Create(63, 6);
end;

function TEntityDisplayComponent.GetSize : RVector2;
begin
  Result := GetDefaultSize;
  if FSizeYOverride > 0 then
      Result.Y := FSizeYOverride;
end;

procedure TEntityDisplayComponent.Idle;
begin
  ComputeVisibility;
  Update;
end;

procedure TEntityDisplayComponent.Init;
begin

end;

procedure TEntityDisplayComponent.InsertIntoWrapper(Component : TGUIComponent; Wrapper : TGUIStackPanel);
var
  i : integer;
begin
  // adds order value to customdata
  PostProcessComponent(Component);
  if assigned(GUI) then
  begin
    if not assigned(Wrapper) then
        Wrapper := Eventbus.Read(eiGetEntityResourceWrapper, []).AsType<TGUIStackPanel>;
    if assigned(Wrapper) then
    begin
      FRegisteredInWrapper := True;
      for i := 0 to Wrapper.ChildCount - 1 do
        if Wrapper.Children[i].CustomDataAsWrapper<integer> >= FOrderValue then
        begin
          Wrapper.InsertChild(i, Component);
          exit;
        end;
      Wrapper.AddChild(Component);
    end;
  end;
end;

function TEntityDisplayComponent.IsVisible : boolean;
begin
  Result := not Eventbus.Read(eiExiled, []).AsBoolean;
end;

function TEntityDisplayComponent.OnAfterDeserialization : boolean;
begin
  Result := True;
  Init;
  SetDirty;
  Update;
  ComputeVisibility;
end;

function TEntityDisplayComponent.OnIdle : boolean;
begin
  Result := True;
  Idle;
end;

function TEntityDisplayComponent.OrderValue(OrderValue : integer) : TEntityDisplayComponent;
begin
  Result := self;
  FOrderValue := OrderValue;
end;

procedure TEntityDisplayComponent.PostProcessComponent(Component : TGUIComponent);
begin
  Component.OwnsCustomData := True;
  Component.SetCustomDataAsWrapper<integer>(FOrderValue);
  if FSizeYOverride <> 0 then
      Component.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateAbsolute(FSizeYOverride));
end;

procedure TEntityDisplayComponent.SetDirty;
begin
  FDirty := True;
end;

function TEntityDisplayComponent.SizeY(SizeY : single) : TEntityDisplayComponent;
begin
  Result := self;
  FSizeYOverride := SizeY;
end;

procedure TEntityDisplayComponent.Update;
begin
  FDirty := False;
end;

{ TResourceDisplayProgressBarComponent }

function TResourceDisplayProgressBarComponent.GetCurrent : single;
begin
  if FResourceType in RES_FLOAT_RESOURCES then
  begin
    try
      Result := Owner.Balance(FResourceType, ComponentGroup).AsSingle;
    except
      Result := Owner.Balance(FResourceType, ComponentGroup).AsSingle;
    end;
  end
  else
      Result := Owner.Balance(FResourceType, ComponentGroup).AsInteger;
end;

function TResourceDisplayProgressBarComponent.GetMax : single;
begin
  if FResourceType in RES_FLOAT_RESOURCES then
      Result := Owner.Cap(FResourceType, ComponentGroup).AsSingle
  else
      Result := Owner.Cap(FResourceType, ComponentGroup).AsInteger;
end;

function TResourceDisplayProgressBarComponent.GetProgress : single;
begin
  Result := HMath.Saturate(GetCurrent / GetMax);
end;

procedure TResourceDisplayProgressBarComponent.Init;
begin
  inherited;
  InitFillbar;
end;

procedure TResourceDisplayProgressBarComponent.InitFillbar;
begin
  if assigned(GUI) and assigned(FResourceBar) and not assigned(FResourceFill) then
  begin
    FResourceFill := TGUIComponent.Create(GUI, nil, '', FResourceBar);
    FResourceFill.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.CreateAbsolute(0));
    FResourceFill.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.CreateAbsolute(0));
    FResourceFill.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateAbsolute(0));
    FResourceFill.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateRelative(1));
    UpdateColors;
  end;
end;

function TResourceDisplayProgressBarComponent.IsEmpty : boolean;
begin
  Result := GetProgress <= 0;
end;

function TResourceDisplayProgressBarComponent.IsFull : boolean;
begin
  Result := GetProgress >= 1;
end;

procedure TResourceDisplayProgressBarComponent.Update;
begin
  if FDirty then
  begin
    inherited;
    if assigned(FResourceBar) and FResourceBar.Visible then
    begin
      if assigned(FResourceFill) then
      begin
        FResourceFill.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateRelative(GetProgress));
        UpdateColors;
      end;
    end;
  end;
end;

procedure TResourceDisplayProgressBarComponent.UpdateColors;
begin
  if assigned(FResourceFill) then
  begin
    FResourceFill.ChangeStyle<RColor>(gtBackgroundColor, 0, GetColorTop);
    FResourceFill.ChangeStyle<RColor>(gtBackgroundColor, 1, GetColorTop);
    FResourceFill.ChangeStyle<RColor>(gtBackgroundColor, 2, GetColorBottom);
    FResourceFill.ChangeStyle<RColor>(gtBackgroundColor, 3, GetColorBottom);
  end;
end;

{ TResourceDisplayHealthComponent }

constructor TResourceDisplayHealthComponent.Create(Owner : TEntity);
begin
  inherited;
  FResourceType := reHealth;
end;

function TResourceDisplayHealthComponent.GetCurrentOverheal : single;
begin
  Result := Owner.Balance(reOverheal).AsSingle;
end;

function TResourceDisplayHealthComponent.GetDefaultSize : RVector2;
begin
  Result := inherited;
  Result.Y := 8;
end;

function TResourceDisplayHealthComponent.GetMaxOverheal : single;
begin
  Result := Owner.Cap(reOverheal).AsSingle;
end;

function TResourceDisplayHealthComponent.GetProgress : single;
begin
  Result := GetCurrent / (GetMax + GetCurrentOverheal);
end;

procedure TResourceDisplayHealthComponent.InitFillbar;
begin
  inherited;
  if assigned(FResourceFill) then
  begin
    // health is on top of overheal, as overheal is always filling up the whole bar
    FResourceFill.ChangeStyle<integer>(gtZOffset, 10);
  end;
  if assigned(GUI) and assigned(FResourceBar) and not assigned(FOverhealBar) then
  begin
    FOverhealBar := TGUIComponent.Create(GUI, nil, '', FResourceBar);
    FOverhealBar.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateRelative(1));
    FOverhealBar.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateRelative(1));
    FOverhealBar.ChangeStyle<RColor>(gtBackgroundColor, 0, GetColorTop(reOverheal));
    FOverhealBar.ChangeStyle<RColor>(gtBackgroundColor, 1, GetColorTop(reOverheal));
    FOverhealBar.ChangeStyle<RColor>(gtBackgroundColor, 2, GetColorBottom(reOverheal));
    FOverhealBar.ChangeStyle<RColor>(gtBackgroundColor, 3, GetColorBottom(reOverheal));
  end;
end;

function TResourceDisplayHealthComponent.IsVisible : boolean;
begin
  Result := inherited;
  if Result then
  begin
    // Healthbar without health always hidden
    if (GetCurrent <= 0) then
        Result := False
      // Healthbars shown an pressing alt key or mode set to always
    else if Keyboard.Alt or (Settings.GetEnumOption<EnumHealthbarMode>(coGameplayHealthbarMode) = hmAlways) then
        Result := True
      // Healthbars only shown if unit is damaged in this mode
    else if (Settings.GetEnumOption<EnumHealthbarMode>(coGameplayHealthbarMode) = hmDamaged) then
        Result := (GetCurrent < GetMax) or (GetCurrentOverheal > 0)
      // Healthbars always hidden in this mode
    else if (Settings.GetEnumOption<EnumHealthbarMode>(coGameplayHealthbarMode) = hmNone) then
        Result := False;
  end;
end;

function TResourceDisplayHealthComponent.ObservedResourceTypes : SetResource;
begin
  Result := inherited + [reOverheal];
end;

function TResourceDisplayHealthComponent.OnChangeCommander(Index : RParam) : boolean;
begin
  Result := True;
  SetDirty;
end;

function TResourceDisplayHealthComponent.OnClientOption(ChangedOption : RParam) : boolean;
begin
  Result := True;
  if ChangedOption.AsEnumType<EnumClientOption> = coGameplayFixedTeamColors then
      SetDirty;
end;

procedure TResourceDisplayHealthComponent.Update;
begin
  if FDirty then
  begin
    if FResourceBar.Visible then
    begin
      if assigned(FResourceFill) then
      begin
        FResourceFill.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateRelative(GetProgress));
        UpdateColors;
      end;
      if assigned(FOverhealBar) then
      begin
        FOverhealBar.Visible := GetCurrentOverheal > 0;
      end;
      FDirty := False;
    end;
  end;
end;

{ TResourceDisplayIntegerProgressBarComponent }

function TResourceDisplayIntegerProgressBarComponent.AmountToInt(Amount : RParam) : integer;
begin
  if FResourceType in RES_FLOAT_RESOURCES then
      Result := Trunc(Amount.AsSingle)
  else Result := Amount.AsInteger;
end;

procedure TResourceDisplayIntegerProgressBarComponent.AddChunkToBar;
var
  Chunk : TGUIComponent;
begin
  if assigned(FResourceBar) then
  begin
    Chunk := TGUIStackPanel.Create(GUI, nil, '', FResourceBar);
    Chunk.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.CreateAbsolute(0));
    Chunk.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.CreateAbsolute(0));
    Chunk.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateAbsolute(10));
    Chunk.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateRelative(1));
    Chunk.ChangeStyle<RColor>(gtBackgroundColor, 0, GetColorTop);
    Chunk.ChangeStyle<RColor>(gtBackgroundColor, 1, GetColorTop);
    Chunk.ChangeStyle<RColor>(gtBackgroundColor, 2, GetColorBottom);
    Chunk.ChangeStyle<RColor>(gtBackgroundColor, 3, GetColorBottom);
    Chunk.ChangeStyle<RGSSSpaceData>(gtOutline, 0, RGSSSpaceData.CreateAbsolute(1));
    Chunk.ChangeStyle<RColor>(gtOutline, 1, $FF000000);
    Chunk.ChangeStyle<EnumBorderLocation>(gtOutline, 3, blOutline);
    Chunk.ChangeStyle<boolean>(gtTransformInheritance, False);

    Chunk.ChangeStyle<string>(gtAnimationName, 'ammo-in');
    Chunk.ChangeStyle<integer>(gtAnimationDuration, 200);
    Chunk.ChangeStyle<EnumAnimationFillMode>(gtAnimationFillMode, afBoth);
    Chunk.ChangeStyle<integer>(gtAnimationIterationCount, 1);
    Chunk.ChangeStyle<EnumComponentAnchor>(gtTransformAnchor, caBottom);
  end;
end;

function TResourceDisplayIntegerProgressBarComponent.FixedCap(NewCap : integer) : TResourceDisplayIntegerProgressBarComponent;
begin
  Result := self;
  FFixedCap := NewCap;
end;

function TResourceDisplayIntegerProgressBarComponent.GetCurrent : integer;
begin
  Result := Min(MAX_CHUNKS, AmountToInt(Owner.Balance(FResourceType, ComponentGroup)));
end;

function TResourceDisplayIntegerProgressBarComponent.GetDefaultBackgroundColor : RColor;
begin
  Result := $AA464646;
end;

function TResourceDisplayIntegerProgressBarComponent.GetMax : integer;
begin
  if FNoCap or (FFixedCap > 0) then
      Result := Max(FFixedCap, GetCurrent)
  else
      Result := Min(MAX_CHUNKS, AmountToInt(Owner.Cap(FResourceType, ComponentGroup)));
end;

procedure TResourceDisplayIntegerProgressBarComponent.Idle;
begin
  inherited;
  UpdateBar;
end;

procedure TResourceDisplayIntegerProgressBarComponent.Init;
begin
  inherited;
  // inits chunks
  ResourceChanged(RPARAMEMPTY);
end;

function TResourceDisplayIntegerProgressBarComponent.IsEmpty : boolean;
begin
  Result := GetCurrent <= 0;
end;

function TResourceDisplayIntegerProgressBarComponent.IsFull : boolean;
begin
  Result := GetCurrent >= GetMax;
end;

function TResourceDisplayIntegerProgressBarComponent.NoCap : TResourceDisplayIntegerProgressBarComponent;
begin
  Result := self;
  FNoCap := True;
end;

procedure TResourceDisplayIntegerProgressBarComponent.RecomputeChunk(Index : integer);
var
  Position : RIntVector2;
  Size : RIntVector2;
  ParentWidth, MaxChunkCount, Width, Overhang, OverhangSplit, OverhangSplitRest, RestDistributionStartIndex : integer;
  Chunk : TGUIComponent;
begin
  Chunk := FResourceBar.Children[index];
  // padding left and right is 1, but right side is overlapped by outline, so reduce by one
  ParentWidth := round(GetSize.Width) - 1;
  MaxChunkCount := Max(GetMax, FVisibleChunks);
  if MaxChunkCount > 0 then
  begin
    Size.Y := round(GetSize.Y);
    if MaxChunkCount <= MAX_CHUNKS_PER_ROW then
    begin
      Width := Trunc(1 / MaxChunkCount * ParentWidth);
      Overhang := ParentWidth - (Width * MaxChunkCount);
      OverhangSplit := Overhang div MaxChunkCount;
      OverhangSplitRest := Overhang mod MaxChunkCount;
      Width := Width + OverhangSplit;
      Position.X := Width * index;
      Position.Y := 0;
      RestDistributionStartIndex := MaxChunkCount - OverhangSplitRest;
      // distribute overhang rest over the last n element
      if index >= RestDistributionStartIndex then
      begin
        Width := Width + 1;
        Position.X := Position.X + Max(0, index - RestDistributionStartIndex);
      end;
      // outline is overlapping with other element, so last elements look larger
      if index = GetCurrent - 1 then
          Width := Width - 1;
    end
    else
    begin
      Width := Trunc(1 / MAX_CHUNKS_PER_ROW * ParentWidth);
      Position.X := Width * (index mod MAX_CHUNKS_PER_ROW);
      Position.Y := (index div MAX_CHUNKS_PER_ROW) * Size.Y;
      // outline is overlapping with other element, so last element in each line look larger
      if (index = GetCurrent - 1) or ((index mod MAX_CHUNKS_PER_ROW) = MAX_CHUNKS_PER_ROW - 1) then
          Width := Width - 1;
    end;
    Size.X := Width;
    Size.Y := Size.Y - 2; // padding remove afterwards

    Chunk.ChangeStyle<RGSSSpaceData>(gtPosition, [RGSSSpaceData.CreateAbsolute(Position.X), RGSSSpaceData.CreateAbsolute(Position.Y)]);
    Chunk.ChangeStyle<RGSSSpaceData>(gtSize, [RGSSSpaceData.CreateAbsolute(Size.X), RGSSSpaceData.CreateAbsolute(Size.Y)]);
  end;
end;

procedure TResourceDisplayIntegerProgressBarComponent.ResourceCapChanged(Value : RParam);
var
  i : integer;
begin
  if not assigned(FResourceBar) then exit;
  for i := 0 to FResourceBar.ChildCount - 1 do
      RecomputeChunk(i);
end;

procedure TResourceDisplayIntegerProgressBarComponent.ResourceChanged(Value : RParam);
var
  Current, i : integer;
  Chunk : TGUIComponent;
begin
  if not assigned(FResourceBar) then exit;
  Current := GetCurrent;
  FVisibleChunks := 0;
  for i := 0 to Max(Current, FResourceBar.ChildCount) - 1 do
  begin
    // create new chunk if not enough are present
    if i >= FResourceBar.ChildCount then
    begin
      AddChunkToBar;
      // on init no animation, otherwise with animation
      Chunk := FResourceBar.Children[FResourceBar.ChildCount - 1];
      Chunk.Visible := Value.IsEmpty;
      if Value.IsEmpty then
          Chunk.CustomData := ord(asShown)
      else
          Chunk.CustomData := ord(asIn);
    end;
    // animate show and hide
    Chunk := FResourceBar.Children[i];
    if (i < Current) and (not Chunk.Visible or (Smallint(Chunk.CustomData) = ord(asOut))) then
    begin
      Chunk.CustomData := ord(asIn);
      Chunk.Visible := True;
      Chunk.ChangeStyle<string>(gtAnimationName, 'ammo-in');
      Chunk.StartAnimation;
    end
    else if (i >= Current) and Chunk.Visible then
    begin
      if Smallint(Chunk.CustomData) <> ord(asOut) then
      begin
        Chunk.ChangeStyle<string>(gtAnimationName, 'ammo-out');
        Chunk.StartAnimation;
        Chunk.CustomData := ord(asOut);
      end
      else if Chunk.AnimationFinished then
      begin
        Chunk.Visible := False;
        Chunk.CustomData := ord(asHidden);
      end;
    end;
    if Chunk.Visible then
        FVisibleChunks := FVisibleChunks + 1;
  end;
  for i := 0 to Max(Current, FResourceBar.ChildCount) - 1 do
      RecomputeChunk(i);
end;

procedure TResourceDisplayIntegerProgressBarComponent.UpdateBar;
var
  CurrentRow, RowCount, i : integer;
begin
  RowCount := 1;
  // if any chunk in second row is visible, we need the second row
  if FResourceBar.ChildCount > MAX_CHUNKS_PER_ROW then
  begin
    CurrentRow := 1;
    for i := MAX_CHUNKS_PER_ROW to FResourceBar.Count - 1 do
      if (CurrentRow <= i div MAX_CHUNKS_PER_ROW) and
        (FResourceBar[i].Visible and not((Smallint(FResourceBar[i].CustomData) = ord(asOut)) and FResourceBar[i].AnimationFinished)) then
      begin
        inc(RowCount);
        inc(CurrentRow);
      end;
  end;
  // update bar size
  FResourceBar.ChangeStyle(gtSize, 1, RGSSSpaceData.CreateAbsolute(RowCount * GetSize.Height));
end;

{ TIndicatorCooldownCircleComponent }

function TIndicatorCooldownCircleComponent.Color(ForcedColor : cardinal) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FColorOverride := RColor.Create(ForcedColor);
end;

constructor TIndicatorCooldownCircleComponent.Create(Owner : TEntity);
begin
  CreateGrouped(Owner, nil);
end;

constructor TIndicatorCooldownCircleComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FTexture := TTexture.CreateTextureFromFile(AbsolutePath(PATH_SPELLTARGET + 'SpelltargetGround.png'), GFXD.Device3D, mhGenerate, True);

  FRadius := 1.7;

  FCircle := TVertexWorldspaceCircle.Create(VertexEngine);
  FCircle.Up := -RVector3.UNITZ;
  FCircle.Left := -RVector3.UNITX;
  FCircle.Texture := FTexture;
  FCircle.Thickness := 0.5;
  FCircle.BlendMode := BlendAdditive;
  FCircle.Texture := FTexture;
  FCircle.Radius := FRadius;
  FCircle.Samples := 32;

  FOpacity := 1.0;

  FTeamOverride := -1;
end;

destructor TIndicatorCooldownCircleComponent.Destroy;
begin
  FTexture.Free;
  FCircle.Free;
  inherited;
end;

procedure TIndicatorCooldownCircleComponent.Hide;
begin

end;

procedure TIndicatorCooldownCircleComponent.Idle;
begin
  FCircle.Radius := FRadius;
  if FUseScaleWith then
  begin
    if FScaleWith = eiCollisionRadius then
        FCircle.Radius := FCircle.Radius * FTargetCollisionRadius
    else
        FCircle.Radius := FCircle.Radius * Eventbus.ReadHierarchic(FScaleWith, [], ComponentGroup).AsSingle;
  end;

  FCircle.Samples := 32;
  if FCircle.Radius > 1 then FCircle.Samples := 64;
  if FCircle.Radius > 5 then FCircle.Samples := 128;

  if FInvertDirection then
  begin
    FCircle.SliceTo := 1;
    FCircle.SliceFrom := 1 - Progress;
  end
  else
  begin
    FCircle.SliceTo := Progress;
    FCircle.SliceFrom := 0;
  end;
  FCircle.Position := FTargetPosition.SetY(GROUND_EPSILON) + FOffset;
  if FColorOverride.IsFullTransparent then
      FCircle.Color := GetTeamColor(HGeneric.TertOp<integer>(FTeamOverride >= 0, FTeamOverride, FTargetTeam)).SetAlphaF(FOpacity)
  else
      FCircle.Color := FColorOverride.SetAlphaF(FOpacity * FColorOverride.A);
end;

function TIndicatorCooldownCircleComponent.Invert : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FInvert := True;
end;

function TIndicatorCooldownCircleComponent.InvertDirection : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FInvertDirection := True;
end;

function TIndicatorCooldownCircleComponent.Offset(X, Y, Z : single) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FOffset := RVector3.Create(X, Y, Z);
end;

function TIndicatorCooldownCircleComponent.OnIdle : boolean;
begin
  Result := True;
  if not FSpelltargetVisualizer then
  begin
    FTargetTeam := Owner.TeamID;
    FTargetPosition := Owner.DisplayPosition;
    FTargetCollisionRadius := Owner.CollisionRadius;
    Idle;
    Render;
  end;
end;

function TIndicatorCooldownCircleComponent.Opacity(s : single) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FOpacity := s;
end;

function TIndicatorCooldownCircleComponent.Progress : single;
begin
  if FShowGameEvent <> '' then
      Result := HMath.Saturate(GlobalEventbus.Read(eiGameEventTimeTo, [FShowGameEvent]).AsInteger / FGameEventDuration)
  else if FShowResource = reNone then
      Result := Eventbus.Read(eiCooldownProgress, [], ComponentGroup).AsSingle
  else
      Result := Owner.ResFill(FShowResource, ComponentGroup);
  if FInvert then Result := 1 - Result;
end;

procedure TIndicatorCooldownCircleComponent.Render;
begin
  FCircle.AddRenderJob;
end;

function TIndicatorCooldownCircleComponent.ScaleWith(Event : EnumEventIdentifier) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FUseScaleWith := True;
  FScaleWith := Event;
end;

function TIndicatorCooldownCircleComponent.SetLinearBlend : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FCircle.BlendMode := BlendLinear;
end;

function TIndicatorCooldownCircleComponent.SetRadius(Radius : single) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FRadius := Radius;
end;

function TIndicatorCooldownCircleComponent.SetTexture(TextureName : string) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FTexture.Free;
  FTexture := TTexture.CreateTextureFromFile(AbsolutePath(TextureName), GFXD.Device3D, mhGenerate, True);
  FCircle.Texture := FTexture;
end;

function TIndicatorCooldownCircleComponent.SetThickness(Thickness : single) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FCircle.Thickness := Thickness;
end;

function TIndicatorCooldownCircleComponent.ShowAsTeam(TeamID : integer) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FTeamOverride := TeamID;
end;

function TIndicatorCooldownCircleComponent.ShowsGameEvent(const GameEvent : string; Duration : integer) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FShowGameEvent := GameEvent;
  FGameEventDuration := Duration;
end;

function TIndicatorCooldownCircleComponent.ShowsResource(Resource : EnumResource) : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FShowResource := Resource;
end;

function TIndicatorCooldownCircleComponent.SpelltargetVisualizer : TIndicatorCooldownCircleComponent;
begin
  Result := self;
  FSpelltargetVisualizer := True;
end;

procedure TIndicatorCooldownCircleComponent.Visualize(Data : TCommanderSpellData);
begin
  if FSpelltargetVisualizer and (length(Data.Targets) > 0) then
  begin
    FTargetTeam := Owner.TeamID;
    FTargetPosition := Data.Targets[0].GetWorldPosition().X0Y;
    FTargetCollisionRadius := 1.0;
    Idle;
    Render;
  end;
end;

{ TResourceDisplayConsoleComponent }

function TResourceDisplayConsoleComponent.OnIdle : boolean;
var
  Balance, Max : RParam;
begin
  Result := True;
  Balance := Owner.Balance(FResourceType, ComponentGroup);
  Max := Owner.Cap(FResourceType, ComponentGroup);
  if FResourceType in RES_INT_RESOURCES then
      HLog.Console('%d / %d', [Balance.AsInteger, Max.AsInteger])
  else
      HLog.Console('%.2f / %.2f', [Balance.AsSingle, Max.AsSingle])
end;

{ TIndicatorResourceCircleComponent }

constructor TIndicatorResourceCircleComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FChunks := TObjectList<TVertexWorldspaceCircle>.Create;
end;

destructor TIndicatorResourceCircleComponent.Destroy;
begin
  FChunks.Free;
  inherited;
end;

function TIndicatorResourceCircleComponent.FixedCap(FixedCap : integer) : TIndicatorResourceCircleComponent;
begin
  Result := self;
  FFixedCap := FixedCap;
end;

procedure TIndicatorResourceCircleComponent.Idle;
var
  i, Balance, Cap : integer;
begin
  inherited;
  if (FShowResource <> reNone) and (FShowResource in RES_INT_RESOURCES) then
  begin
    Balance := Owner.Balance(FShowResource, ComponentGroup).AsInteger;
    if FFixedCap > 0 then
        Cap := Max(Balance, FFixedCap)
    else
        Cap := Owner.Cap(FShowResource, ComponentGroup).AsInteger;
    while FChunks.Count < Balance do
        FChunks.Add(TVertexWorldspaceCircle.Create(VertexEngine));
    for i := 0 to Balance - 1 do
    begin
      FChunks[i].Radius := FCircle.Radius;
      FChunks[i].Thickness := FCircle.Thickness;
      FChunks[i].Samples := FCircle.Samples;
      FChunks[i].Position := FCircle.Position;
      FChunks[i].Up := FCircle.Up;
      FChunks[i].Left := FCircle.Left;
      FChunks[i].Texture := FCircle.Texture;
      FChunks[i].Color := FCircle.Color;
      FChunks[i].BlendMode := FCircle.BlendMode;
      FChunks[i].SliceFrom := (i / Cap) + (FPadding / 4 * PI);
      FChunks[i].SliceTo := ((i + 1) / Cap) - (FPadding / 4 * PI);
    end;
  end;
end;

function TIndicatorResourceCircleComponent.Padding(Angle : single) : TIndicatorResourceCircleComponent;
begin
  Result := self;
  FPadding := Angle;
end;

procedure TIndicatorResourceCircleComponent.Render;
var
  i, Balance : integer;
begin
  if (FShowResource <> reNone) and (FShowResource in RES_INT_RESOURCES) then
  begin
    Balance := Owner.Balance(FShowResource, ComponentGroup).AsInteger;
    assert(Balance <= FChunks.Count);
    for i := 0 to Balance - 1 do
        FChunks[i].AddRenderJob;
  end;
end;

{ TResourceDisplayBarComponent }

procedure TResourceDisplayBarComponent.ComputeVisibility;
begin
  inherited;
  if assigned(FResourceBar) then
  begin
    FResourceBar.Visible := IsVisible;
  end;
end;

destructor TResourceDisplayBarComponent.Destroy;
begin
  if not FRegisteredInWrapper then
      FreeAndNil(FResourceBar);
  inherited;
end;

procedure TResourceDisplayBarComponent.Init;
var
  Wrapper : TGUIComponent;
begin
  inherited;
  if assigned(GUI) then
  begin
    Wrapper := Eventbus.Read(eiGetEntityResourceWrapper, []).AsType<TGUIComponent>;
    if assigned(Wrapper) then
    begin
      InitBar;
      InsertIntoWrapper(FResourceBar);
    end;
  end;
end;

procedure TResourceDisplayBarComponent.InitBar;
begin
  if assigned(GUI) and not assigned(FResourceBar) then
  begin
    FResourceBar := TGUIStackPanel.Create(GUI, nil);
    FResourceBar.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.Inherit);
    FResourceBar.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.Inherit);
    FResourceBar.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.CreateAbsolute(GetSize.X));
    FResourceBar.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateAbsolute(GetSize.Y));
    FResourceBar.ChangeStyle<EnumComponentAnchor>(gtAnchor, caTop);
    FResourceBar.ChangeStyle<RGSSSpaceData>(gtPadding, [
      RGSSSpaceData.CreateAbsolute(1),
      RGSSSpaceData.CreateAbsolute(1),
      RGSSSpaceData.CreateAbsolute(1),
      RGSSSpaceData.CreateAbsolute(1)]);
    FResourceBar.ChangeStyle<RColor>(gtBackgroundColor, GetBackgroundColor);
    FResourceBar.ChangeStyle<RGSSSpaceData>(gtBorder, 0, RGSSSpaceData.CreateAbsolute(1));
    FResourceBar.ChangeStyle<RColor>(gtBorder, 1, $FF000000);
    FResourceBar.ChangeStyle<EnumBorderLocation>(gtBorder, 3, blInset);
    FResourceBar.ChangeStyle<RGSSSpaceData>(gtStackpartitioning, RGSSSpaceData.Auto());
    FResourceBar.ChangeStyle<EnumStackOrientation>(gtStackorientation, soHorizontal);
  end;
end;

function TResourceDisplayBarComponent.IsVisible : boolean;
begin
  Result := inherited and Eventbus.Read(eiVisible, []).AsBooleanDefaultTrue;
end;

function TResourceDisplayBarComponent.GetBackgroundColor : RColor;
begin
  Result := GetDefaultBackgroundColor;
end;

function TResourceDisplayBarComponent.GetDefaultBackgroundColor : RColor;
begin
  Result := $99000000;
end;

function TResourceDisplayBarComponent.GradientBottom(GradientBottom : cardinal) : TResourceDisplayBarComponent;
begin
  Result := self;
  FGradientBottomOverride := GradientBottom;
end;

function TResourceDisplayBarComponent.GradientTop(GradientTop : cardinal) : TResourceDisplayBarComponent;
begin
  Result := self;
  FGradientTopOverride := GradientTop;
end;

function TResourceDisplayBarComponent.GetColorBottom(Resource : EnumResource) : RColor;
begin
  Result := GetColorGradient(Resource).b;
end;

function TResourceDisplayBarComponent.GetColorBottom : RColor;
begin
  Result := GetColorGradient.b;
end;

function TResourceDisplayBarComponent.GetColorGradient(Resource : EnumResource) : RTuple<RColor, RColor>;
begin
  case Resource of
    reHealth :
      begin
        case GetDisplayedTeam(TeamID) of
          0 : Result := RTuple<RColor, RColor>.Create($FFDEDEDE, $FF404040); // grey
          1 : Result := RTuple<RColor, RColor>.Create($FF51A2FF, $FF2850A0); // blue
        else
          Result := RTuple<RColor, RColor>.Create($FFE66868, $FF723333); // red
        end;
      end;
    reOverheal : Result := RTuple<RColor, RColor>.Create($FFFFFFFF, $FF808080); // white
    reMana : Result := RTuple<RColor, RColor>.Create($FFFAF800, $FF8B8A00); // yellow
    reWelaCharge : Result := RTuple<RColor, RColor>.Create($FF63D9DB, $FF377D7D); // cyan
  else
    Result := RTuple<RColor, RColor>.Create($FFDEDEDE, $FF404040); // grey
  end;
  if not FGradientTopOverride.IsTransparentBlack then
      Result.b := FGradientTopOverride;
  if not FGradientBottomOverride.IsTransparentBlack then
      Result.b := FGradientBottomOverride;
end;

function TResourceDisplayBarComponent.GetColorGradient : RTuple<RColor, RColor>;
begin
  Result := GetColorGradient(FResourceType);
end;

function TResourceDisplayBarComponent.GetColorTop : RColor;
begin
  Result := GetColorGradient.A;
end;

function TResourceDisplayBarComponent.GetColorTop(Resource : EnumResource) : RColor;
begin
  Result := GetColorGradient(Resource).A;
end;

{ TStateDisplayComponent }

function TStateDisplayComponent.CheckWelaIsReadyInGroup(const TargetGroup : TArray<byte>) : TStateDisplayComponent;
begin
  Result := self;
  FWelaIsReadyGroup := ByteArrayToComponentGroup(TargetGroup);
end;

procedure TStateDisplayComponent.ComputeVisibility;
begin
  inherited;
  if assigned(FIcon) then
      FIcon.Visible := IsVisible;
end;

destructor TStateDisplayComponent.Destroy;
begin
  if not FRegisteredInWrapper then
      FreeAndNil(FIcon);
  inherited;
end;

procedure TStateDisplayComponent.Init;
var
  Wrapper : TGUIStackPanel;
begin
  inherited;
  if assigned(GUI) then
  begin
    Wrapper := Eventbus.Read(eiGetEntityStateWrapper, []).AsType<TGUIStackPanel>;
    if assigned(Wrapper) then
    begin
      InitIcon;
      InsertIntoWrapper(FIcon, Wrapper);
    end;
  end;
end;

procedure TStateDisplayComponent.InitIcon;
begin
  if assigned(GUI) and not assigned(FIcon) then
  begin
    FIcon := TGUIComponent.Create(GUI, nil);
    FIcon.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.Inherit);
    FIcon.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.Inherit);
    FIcon.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.Auto);
    FIcon.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateRelative(1));
    FIcon.ChangeStyle<RGSSSpaceData>(gtMargin, 1, RGSSSpaceData.CreateAbsolute(5));
    FIcon.ChangeStyle<RGSSSpaceData>(gtMargin, 3, RGSSSpaceData.CreateAbsolute(5));
    FIcon.ChangeStyle<string>(gtBackground, FTexturePath);
  end;
end;

function TStateDisplayComponent.IsVisible : boolean;
begin
  Result := inherited;
  if Result and (FWelaIsReadyGroup <> []) then
      Result := Eventbus.Read(eiIsReady, [], FWelaIsReadyGroup).AsBooleanDefaultTrue <> FReverseWelaIsReadyCheck;
end;

function TStateDisplayComponent.ReverseWelaIsReadyCheck : TStateDisplayComponent;
begin
  Result := self;
  FReverseWelaIsReadyCheck := True;
end;

function TStateDisplayComponent.Texture(const TexturePath : string) : TStateDisplayComponent;
begin
  Result := self;
  FTexturePath := TexturePath;
end;

{ TStateDisplayStackComponent }

procedure TStateDisplayStackComponent.ComputeVisibility;
begin
  inherited;
  if assigned(FStack) then
      FStack.Visible := IsVisible;
end;

destructor TStateDisplayStackComponent.Destroy;
begin
  if not FRegisteredInWrapper then
      FreeAndNil(FStack);
  inherited;
end;

function TStateDisplayStackComponent.GetDefaultSize : RVector2;
begin
  Result := inherited;
  Result.Y := 38;
end;

procedure TStateDisplayStackComponent.Init;
var
  Wrapper : TGUIComponent;
begin
  inherited;
  if assigned(GUI) then
  begin
    Wrapper := Eventbus.Read(eiGetEntityResourceWrapper, []).AsType<TGUIComponent>;
    if assigned(Wrapper) then
    begin
      InitWrapper;
      InsertIntoWrapper(FStack);
    end;
  end;
end;

procedure TStateDisplayStackComponent.InitWrapper;
begin
  if assigned(GUI) and not assigned(FStack) then
  begin
    FStack := TGUIStackPanel.Create(GUI, nil);
    FStack.ChangeStyle<RGSSSpaceData>(gtPosition, 0, RGSSSpaceData.CreateRelative(0.5));
    FStack.ChangeStyle<RGSSSpaceData>(gtPosition, 1, RGSSSpaceData.CreateAbsolute(0));
    FStack.ChangeStyle<RGSSSpaceData>(gtSize, 0, RGSSSpaceData.Auto);
    FStack.ChangeStyle<RGSSSpaceData>(gtSize, 1, RGSSSpaceData.CreateAbsolute(GetSize.Y));
    FStack.ChangeStyle<EnumComponentAnchor>(gtAnchor, caBottom);
    FStack.ChangeStyle<RGSSSpaceData>(gtPadding, [
      RGSSSpaceData.CreateAbsolute(0),
      RGSSSpaceData.CreateAbsolute(0),
      RGSSSpaceData.CreateAbsolute(6),
      RGSSSpaceData.CreateAbsolute(0)]);
    FStack.ChangeStyle<RGSSSpaceData>(gtStackpartitioning, RGSSSpaceData.Auto());
    FStack.ChangeStyle<EnumStackOrientation>(gtStackorientation, soHorizontal);
  end;
end;

function TStateDisplayStackComponent.OnGetEntityStateWrapper : RParam;
begin
  if FRegisteredInWrapper then
      Result := FStack
  else
      Result := nil;
end;

{ TIndicatorShowTextComponent }

function TIndicatorShowTextComponent.Clamp(Minimum, Maximum : integer) : TIndicatorShowTextComponent;
begin
  Result := self;
  FClamp.X := Minimum;
  FClamp.Y := Maximum;
  FClamps := True;
end;

function TIndicatorShowTextComponent.Color(Color : cardinal) : TIndicatorShowTextComponent;
begin
  Result := self;
  FColor := RColor.Create(Color);
end;

function TIndicatorShowTextComponent.ColorAtCap(Color : cardinal) : TIndicatorShowTextComponent;
begin
  Result := self;
  FColorAtCap := RColor.Create(Color);
end;

constructor TIndicatorShowTextComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
var
  FontDescription : RFontDescription;
  FontBorder : Rfontborder;
begin
  inherited CreateGrouped(Owner, Group);
  FontDescription := RFontDescription.Create(DefaultFontFamily);
  FontDescription.Height := 24;
  FontDescription.Weight := fwBold;
  FText := TVertexFont.Create(VertexEngine, FontDescription);
  FText.Format := [ffLeft, ffVerticalCenter];
  FColor := $FF000000;
  FontBorder.Color := FColor;
  FontBorder.Width := 1.0;
  FText.FontBorder := FontBorder;
  FText.Visible := True;
  FResourceGroup := ComponentGroup;
  FCursorOffset := DEFAULT_OFFSET_FROM_CURSOR;
  FText.DrawsAtStage := rsGUI;
  FColorAtCap := $FFFF0000;
end;

function TIndicatorShowTextComponent.CursorOffset(X, Y : integer) : TIndicatorShowTextComponent;
begin
  Result := self;
  FCursorOffset.X := X;
  FCursorOffset.Y := Y;
end;

destructor TIndicatorShowTextComponent.Destroy;
begin
  FText.Free;
  inherited;
end;

function TIndicatorShowTextComponent.FixedCap(Value : integer) : TIndicatorShowTextComponent;
begin
  Result := self;
  FUseFixedCap := True;
  FFixedCap := Value;
end;

procedure TIndicatorShowTextComponent.Hide;
begin
  // nothing to do here, as visualization only added each frame
end;

procedure TIndicatorShowTextComponent.Idle;
var
  WorldPosition : RVector3;
  ScreenPosition : RVector2;
  Balance, Cap : integer;
  Position, Size : RIntVector2;
  ResourceTarget : TEntity;
begin
  WorldPosition := FTargetPosition;
  ScreenPosition := GFXD.MainScene.Camera.WorldSpaceToScreenSpace(WorldPosition).XY;

  Size := RIntVector2.Create(50, ceil(FText.FontDescription.Height));
  Position := ScreenPosition.round + FCursorOffset - RIntVector2.Create(0, Size.Y);
  FText.Rect := RRect.CreateWidthHeight(Position, Size);
  FText.Color := FColor;

  if (FShownResource <> reNone) and (FShownResource in RES_INT_RESOURCES) then
  begin
    if assigned(ClientGame) and FResourceFromCommander then
        ResourceTarget := ClientGame.CommanderManager.ActiveCommander
    else
        ResourceTarget := Owner;
    if assigned(ResourceTarget) then
    begin
      Balance := ResourceTarget.Balance(FShownResource, FResourceGroup).AsInteger;
      if FClamps then
          Balance := HMath.Clamp(Balance, FClamp.X, FClamp.Y);
      if FUseFixedCap then
          Cap := FFixedCap
      else
          Cap := ResourceTarget.Cap(FShownResource, FResourceGroup).AsInteger;
      FText.Text := Balance.ToString;
      if (Cap > 0) and (Cap < 100) then
      begin
        if Balance >= Cap then
            FText.Color := FColorAtCap;
        if not FNoCap then
            FText.Text := FText.Text + ' / ' + Cap.ToString;
      end;
    end
    else
        FText.Text := '';
  end;
end;

function TIndicatorShowTextComponent.NoCap : TIndicatorShowTextComponent;
begin
  Result := self;
  FNoCap := True;
end;

function TIndicatorShowTextComponent.OnIdle : boolean;
begin
  Result := True;
  if not FSpelltargetVisualizer then
  begin
    FTargetPosition := Owner.DisplayPosition;
    Idle;
    Render;
  end;
end;

procedure TIndicatorShowTextComponent.Render;
begin
  FText.AddRenderJob;
end;

function TIndicatorShowTextComponent.ResourceFromCommander : TIndicatorShowTextComponent;
begin
  Result := self;
  FResourceFromCommander := True;
end;

function TIndicatorShowTextComponent.ResourceGroup(Group : TArray<byte>) : TIndicatorShowTextComponent;
begin
  Result := self;
  FResourceGroup := ByteArrayToComponentGroup(Group);
end;

function TIndicatorShowTextComponent.ResourceGroupOfSpell : TIndicatorShowTextComponent;
begin
  Result := self;
  FResourceGroupOfSpell := True;
end;

function TIndicatorShowTextComponent.ShowResource(Resource : EnumResource) : TIndicatorShowTextComponent;
begin
  Result := self;
  FShownResource := Resource
end;

function TIndicatorShowTextComponent.SpelltargetVisualizer : TIndicatorShowTextComponent;
begin
  Result := self;
  FSpelltargetVisualizer := True;
end;

procedure TIndicatorShowTextComponent.Visualize(Data : TCommanderSpellData);
begin
  if FSpelltargetVisualizer and (length(Data.Targets) > 0) then
  begin
    FTargetPosition := Data.Targets[0].GetWorldPosition().X0Y;
    if FResourceGroupOfSpell then
        FResourceGroup := Data.ComponentGroup;
    Idle;
    Render;
  end;
end;

{ TCommanderAbilityButtonComponent }

procedure TCommanderAbilityButtonComponent.DeRegisterButton;
begin
  inherited;
  if assigned(HUD) then
      HUD.DeregisterCommanderAbility(FHUDCommanderAbility);
  FHUDCommanderAbility := nil;
end;

procedure TCommanderAbilityButtonComponent.RegisterButton;
begin
  inherited;
  FSpell.MultiModes := FMultiMode;
  if assigned(HUD) then
  begin
    FHUDCommanderAbility := HUD.RegisterCommanderAbility(FUID, FSpell);
    // deckslot takes the ownership
    FSpell := nil;
  end;
end;

function TCommanderAbilityButtonComponent.UID(const UID : string) : TCommanderAbilityButtonComponent;
begin
  Result := self;
  FUID := UID;
end;

{ TMinimapPingComponent }

function TMinimapPingComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if assigned(ClientGame) then
      ClientGame.MinimapManager.MiniMap.Ping(Targets.AsATarget.First.GetTargetPosition, FIconPath, FSize, PING_DURATION);
end;

function TMinimapPingComponent.Size(Size : single) : TMinimapPingComponent;
begin
  Result := self;
  FSize := Size;
end;

function TMinimapPingComponent.Texture(const IconPath : string) : TMinimapPingComponent;
begin
  Result := self;
  FIconPath := PATH_HUD_MINIMAP + IconPath;
end;

initialization

ScriptManager.ExposeClass(TTooltipUnitAbilityComponent);

ScriptManager.ExposeClass(TDeckCardButtonComponent);
ScriptManager.ExposeClass(TAbilitybuttonComponent);
ScriptManager.ExposeClass(TCommanderAbilityButtonComponent);

ScriptManager.ExposeClass(TMinimapPingComponent);

ScriptManager.ExposeClass(TEntityDisplayComponent);
ScriptManager.ExposeClass(TStateDisplayComponent);
ScriptManager.ExposeClass(TStateDisplayStackComponent);
ScriptManager.ExposeClass(TResourceDisplayComponent);
ScriptManager.ExposeClass(TResourceDisplayIntegerProgressBarComponent);
ScriptManager.ExposeClass(TResourceDisplayBarComponent);
ScriptManager.ExposeClass(TResourceDisplayProgressBarComponent);
ScriptManager.ExposeClass(TEntityDisplayWrapperComponent);
ScriptManager.ExposeClass(TResourceDisplayHealthComponent);
ScriptManager.ExposeClass(TResourceDisplayConsoleComponent);

ScriptManager.ExposeClass(TRangeIndicatorComponent);
ScriptManager.ExposeClass(TTextureRangeIndicatorComponent);
ScriptManager.ExposeClass(TRangeIndicatorHighlightEntitiesComponent);
ScriptManager.ExposeClass(TIndicatorCooldownCircleComponent);
ScriptManager.ExposeClass(TIndicatorResourceCircleComponent);
ScriptManager.ExposeClass(TIndicatorShowTextComponent);

ScriptManager.ExposeClass(TSpelltargetVisualizerShowPatternComponent);
ScriptManager.ExposeClass(TSpelltargetVisualizerLineBetweenTargetsComponent);
ScriptManager.ExposeClass(TSpelltargetVisualizerShowTextureComponent);

ScriptManager.ExposeClass(TWelaTargetConstraintGridVisualizedComponent);

ScriptManager.ExposeClass(TShowOnMinimapComponent);

end.
