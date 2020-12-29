unit BaseConflict.EntityComponents.Client.Visuals;

interface

uses
  System.Types,
  Generics.Collections,
  System.SysUtils,
  System.RegularExpressions,
  System.Rtti,
  Classes,
  Vcl.Dialogs,
  Math,
  Engine.Mesh,
  {$IFDEF MAPEDITOR}
  Engine.Mesh.Editor,
  {$ENDIF}
  Engine.Core,
  Engine.Core.Camera,
  Engine.Core.Types,
  Engine.Core.Lights,
  Engine.Animation,
  Engine.GFXApi,
  Engine.GFXApi.Types,
  Engine.Vertex,
  Engine.GUI,
  Engine.Script,
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Windows,
  Engine.Terrain,
  Engine.Math,
  Engine.Log,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.ParticleEffects,
  Engine.PostEffects,
  BaseConflict.Map,
  BaseConflict.Game,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Client,
  BaseConflict.Globals,
  BaseConflict.Globals.Client,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Client,
  BaseConflict.Settings.Client;

type

  {$RTTI INHERIT}
  /// <summary> Adds shaking to the camera.</summary>
  TCameraShakerComponent = class(TEntityComponent)
    protected const
      DEFAULT_DURATION = 500;
      DEFAULT_STRENGTH = 0.25;
      DEFAULT_WAVES    = 5;
    protected type
      EnumShakerType = (stRadial, stVector, stRotation);
    protected
      // Attention the GFXD owns the shakers so they may be already freed
      FCreatedShaker : TList<TCameraShaker>;
      FShakerType : EnumShakerType;
      FDuration, FDelay, FWaves : integer;
      FStrength : single;
      FVector : RVector3;
      FShakeOnCreate, FShakeOnFire, FShakeOnFireWarhead, FShakeOnFree, FShakeOnDie, FShakeOnLose, FInvert, FGlobal, FNoFade : boolean;
      FStopOnDie, FStopOnFree : boolean;
      FShakerPositions : TList<ISharedData<RVector3>>;
      procedure Shake;
      procedure Stop;
      procedure BeforeComponentFree; override;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterDeserialization() : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiFireWarhead, epLast, etTrigger)]
      function OnFireWarhead(Targets : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      function OnLose(TeamID : RParam) : boolean;
    public
      constructor CreateGrouped(Entity : TEntity; Groups : TArray<byte>); override;
      function VectorShaker(VectorX, VectorY, VectorZ : single) : TCameraShakerComponent;
      function RotationShaker(Yaw, Pitch, Roll : single) : TCameraShakerComponent;

      function ActivateOnCreate() : TCameraShakerComponent;
      function ActivateNow() : TCameraShakerComponent;
      function ActivateOnFireWarhead() : TCameraShakerComponent;
      function ActivateOnFire() : TCameraShakerComponent;
      function ActivateOnDie() : TCameraShakerComponent;
      function ActivateOnLose() : TCameraShakerComponent;
      function ActivateOnFree() : TCameraShakerComponent;

      function StopOnDie : TCameraShakerComponent;
      function StopOnFree : TCameraShakerComponent;

      function Invert : TCameraShakerComponent;
      function Strength(Radius : single) : TCameraShakerComponent;
      function Duration(DurationMs : integer) : TCameraShakerComponent;
      function Delay(DelayTime : integer) : TCameraShakerComponent;
      function Waves(Waves : integer) : TCameraShakerComponent;
      function NoFade : TCameraShakerComponent;
      function Global : TCameraShakerComponent;

      function PresetVectorLight : TCameraShakerComponent;
      function PresetVectorMedium : TCameraShakerComponent;
      function PresetVectorStrong : TCameraShakerComponent;
      function PresetRotationLight : TCameraShakerComponent;
      function PresetRotationMedium : TCameraShakerComponent;
      function PresetRotationStrong : TCameraShakerComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Orients the mesh into movementdirection using his last position and his new position. </summary>
  TOrienterMovementComponent = class(TEntityComponent)
    protected
      FFront : RVector2;
    published
      [XEvent(eiMove, epLast, etTrigger)]
      /// <summary> Save move target. </summary>
      function OnMove(const Target : RParam) : boolean;
      [XEvent(eiDisplayFront, epHigh, etRead)]
      /// <summary> Returns the direction to the move target, if no target specified, pass previous </summary>
      function OnDisplayFront(const PreviousFront : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Orients the mesh into target direction. </summary>
  TOrienterTargetComponent = class(TEntityComponent)
    protected
      FTargetGroup, FFrontGroup : SetComponentGroup;
      FTarget : RTarget;
      FLastFront : RVector3;
      FIsMoving, FWithY, FFromPivot, FKeepLastFront : boolean;
    published
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> Kill this component. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiWelaSetMainTarget, epLast, etTrigger)]
      /// <summary> Reorient the unit to match the target. </summary>
      function OnTarget(const Target : RParam) : boolean;
      [XEvent(eiDisplayFront, epHigh, etRead)]
      /// <summary> Returns the direction to the target, if no target specified, pass previous </summary>
      function OnDisplayFront(const Previous : RParam) : RParam;
    public
      function FrontGroup(const Group : TArray<byte>) : TOrienterTargetComponent;
      function TargetGroup(const Group : TArray<byte>) : TOrienterTargetComponent;
      function FrontWithY() : TOrienterTargetComponent;
      function FrontFromPivot() : TOrienterTargetComponent;
      function KeepLastFront() : TOrienterTargetComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Set the front of an entity. </summary>
  TOrienterFrontComponent = class(TEntityComponent)
    protected
      FFront : RVector3;
    published
      [XEvent(eiDisplayFront, epFirst, etRead)]
      function OnDisplayFront(const Previous : RParam) : RParam;
    public
      function Front(FrontX, FrontY, FrontZ : single) : TOrienterFrontComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Smooth front changes on mesh.</summary>
  TOrienterSmoothRotateComponent = class(TEntityComponent)
    protected
      FRotateSpeed : single;
      FCurrentFront : RVector3;
      FFrameKey : cardinal;
    published
      [XEvent(eiDisplayFront, epLower, etRead)]
      function OnDisplayFront(const PreviousFront : RParam) : RParam;
    public
      function SetAngleSpeed(Value : single) : TOrienterSmoothRotateComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Automatically rotates the entity. </summary>
  TOrienterAutoRotationComponent = class(TEntityComponent)
    protected
      FRotSpeed, FRandomOffset : RVector3;
      FLimit : single;
      FStartTime : double;
      function LastTime : single;
    published
      [XEvent(eiDisplayFront, epMiddle, etRead)]
      /// <summary> Rotate the unit. </summary>
      function OnFront(const Previous : RParam) : RParam;
      [XEvent(eiDisplayUp, epMiddle, etRead)]
      /// <summary> Rotate the unit. </summary>
      function OnUp(const Previous : RParam) : RParam;
    public
      constructor CreateGrouped(Entity : TEntity; Group : TArray<byte>); override;
      function SetSpeed(RotationSpeed : RVector3) : TOrienterAutoRotationComponent;
      function SpeedJitter(X, Y, Z : single) : TOrienterAutoRotationComponent;
      function RandomOffset(X, Y, Z : single) : TOrienterAutoRotationComponent;
      function StopAt(Limit : single) : TOrienterAutoRotationComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Inverts the front of an entity. </summary>
  TOrienterFrontInverterComponent = class(TEntityComponent)
    published
      [XEvent(eiDisplayFront, epLower, etRead)]
      /// <summary> Inverts front. </summary>
      function OnDisplayFront(const PreviousFront : RParam) : RParam;
  end;

  {$RTTI INHERIT}

  /// <summary> Adjusts the size of this entity. </summary>
  TVisualModificatorSizeComponent = class(TEntityComponent)
    protected
      FCurrentSize : single;
      FSizes : TArray<RVector3>;
      FTimeKeys : TArray<RTuple<integer, RVector3>>;
      FDuration : TTimer;
    published
      [XEvent(eiSize, epLow, etRead)]
      /// <summary> Puts this size modificator in the chain. </summary>
      function OnSize(Previous : RParam) : RParam;
    public
      function SetTargetSize(Size : single) : TVisualModificatorSizeComponent;
      function Keypoints(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
      function KeypointsX(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
      function KeypointsY(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
      function KeypointsZ(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
      function TimeKeys(const Times : TArray<integer>) : TVisualModificatorSizeComponent;
      function Duration(Duration : integer) : TVisualModificatorSizeComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  RMatrixAdjustments = record
    BindInvertX, BindInvertY, BindInvertZ, BindSwapXY, BindSwapXZ, BindSwapYZ : boolean;
    Offset, Rotation : RVector3;
    function Apply(const a : RMatrix) : RMatrix;
  end;

  /// <summary> Masterclass for unitdisplays like meshes. </summary>
  TVisualizerComponent = class(TEntityComponent)
    private const
      GAMEPLAY_SCALE_EVENTS = [eiWelaRange, eiWelaAreaOfEffect];
    protected
      FBoundZone : string;
      FBindGroup : SetComponentGroup;
      FBindMatrix : RMatrix;
      FSize : RVector3;
      FFixedTeamID : integer;
      FOveriddenResourceCap : single;
      FModelsize, FMinScaleEvent, FMaxScaleEvent, FFixedHeight, FResourceScaleFactorMin, FResourceScaleFactorMax : single;
      FScaleWithResource : EnumResource;
      FScaleEvent : EnumEventIdentifier;
      FBindMatrixAdjustments : RMatrixAdjustments;
      FFixedOrientation, FScaleWithEvent, FIgnoreSize, FIgnoreModelSize, FHasFixedHeight,
        FBindDebug, FIsStatic, FFirstStaticApplyDone, FIsPiece, FVisibleWithWelaReady, FVisibleWithOption : boolean;
      FVisibilityOption : EnumClientOption;
      FWelaReadyGroup : SetComponentGroup;
      FVisibleWithResource : EnumResource;
      FVisibleWithUnitPropertyMustHave, FVisibleWithUnitPropertyMustNotHave : SetUnitProperty;
      FOffset, FRotationOffset, FFixedFront, FFixedUp, FDefaultFront, FDefaultUp, FFixedOffset : RVector3;
      /// <summary> Apply position, front, size etc data to visual representation</summary>
      procedure Apply; virtual;
      procedure Update;
      function FinalSize : RVector3; virtual;
      /// <summary> Called every frame, can override to manage visual representation (e.g. render).</summary>
      procedure Idle; virtual;
      procedure SetModelSize(ModelSize : single); virtual;
      function IsVisible : boolean; virtual;
      function IsBoundToBone : boolean;
      function FinalModelOffset : RVector3;
    published
      [XEvent(eiModelSize, epLast, etWrite)]
      /// <summary> Sets the modelsize. </summary>
      function OnModelSize(Size : RParam) : boolean;
      [XEvent(eiIdle, epLower, etTrigger, esGlobal)]
      /// <summary> Apply changes and calling Idle every frame.</summary>
      function OnIdle() : boolean;
    public
      function SetModelOffset(OffsetX, OffsetY, OffsetZ : single) : TVisualizerComponent; overload;
      function SetModelOffset(Offset : RVector3) : TVisualizerComponent; overload;
      function SetModelRotationOffset(Offset : RVector3) : TVisualizerComponent;
      function BindToSubPosition(const ZoneName : string) : TVisualizerComponent;
      function BindToSubPositionGroup(const ZoneName : string; TargetGroup : TArray<byte>) : TVisualizerComponent;
      function InvertXBindMatrix : TVisualizerComponent;
      function InvertYBindMatrix : TVisualizerComponent;
      function InvertZBindMatrix : TVisualizerComponent;
      function SwapXYBindMatrix : TVisualizerComponent;
      function SwapXZBindMatrix : TVisualizerComponent;
      function SwapYZBindMatrix : TVisualizerComponent;
      function DebugBindMatrix : TVisualizerComponent;
      function ScaleWith(Event : EnumEventIdentifier) : TVisualizerComponent;
      function ScaleWithResource(Resource : EnumResource; ScaleFactorMin, ScaleFactorMax : single) : TVisualizerComponent;
      function OverrideResourceCap(NewCap : single) : TVisualizerComponent;
      function MaxScale(Maximum : single) : TVisualizerComponent;
      function ScaleRange(Minimum, Maximum : single) : TVisualizerComponent;
      function IgnoreSize : TVisualizerComponent;
      function IgnoreModelSize : TVisualizerComponent;
      /// <summary> Set a model offset of y = EPSILON </summary>
      function IsDecal : TVisualizerComponent;
      /// <summary> If set, the visualized thing is a sub part of the entity with it's own position and orientation. </summary>
      function IsPiece : TVisualizerComponent;
      /// <summary> Ignores the y component of the parent. </summary>
      function FixedHeight(Height : single) : TVisualizerComponent;
      function FixedHeightGround : TVisualizerComponent;
      function FixedOffsetGround : TVisualizerComponent;
      function FixedOrientationDefault : TVisualizerComponent;
      function FixedOrientation(FrontX, FrontY, FrontZ : single) : TVisualizerComponent;
      function FixedOrientationUp(UpX, UpY, UpZ : single) : TVisualizerComponent;
      function FixedOrientationAngle(FrontX, FrontY, FrontZ : single) : TVisualizerComponent;
      function DefaultOrientation(FrontX, FrontY, FrontZ : single) : TVisualizerComponent;
      function DefaultOrientationUp(UpX, UpY, UpZ : single) : TVisualizerComponent;
      function ShowAsTeam(FixTeamID : integer) : TVisualizerComponent;
      function VisibleWithOption(Option : EnumClientOption) : TVisualizerComponent;
      function VisibleWithWelaReady : TVisualizerComponent;
      function VisibleWithWelaReadyGrouped(Group : TArray<byte>) : TVisualizerComponent;
      function VisibleWithResource(ResourceID : integer) : TVisualizerComponent;
      function VisibleWithUnitPropertyMustHave(Properties : TArray<byte>) : TVisualizerComponent;
      function VisibleWithUnitPropertyMustNotHave(Properties : TArray<byte>) : TVisualizerComponent;
      constructor Create(Owner : TEntity); override;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
  end;

  {$RTTI INHERIT}

  TParticleEffectComponent = class(TVisualizerComponent)
    protected
      FParticleEffect : TParticleEffect;
      FDefer, FDeactivateOnTime : TTimer;
      FLastTargets : ATarget;
      FLoadedTeamID : integer;
      FSizeNormalization : single;
      FParticlePath, FEffectFilename : string;
      FPlaceAtSavedTarget, FActivateWithWela, FClonesToTarget : boolean;
      FStartEmissionOnCreate, FStartEmissionOnFire, FStartEmissionOnDie, FStartEmissionOnFree,
        FStartEmissionOnFireWarhead, FStartEmissionOnPreFire, FStartEmissionOnLose : boolean;
      FStopEmissionOnMoveTo, FStopEmissionOnDie, FStopEmissionOnFire : boolean;
      FAtFireTarget, FChangesWithTeam, FEmitFromAllBones : boolean;
      function FinalSize : RVector3; override;
      procedure Apply; override;
      procedure Idle; override;
      procedure BeforeComponentFree; override;
      procedure Start;
      procedure StartNow;
      procedure Stop;
      function IsVisible : boolean; override;
      procedure CheckAndReloadParticleEffect;
      function Clone(Target : TEntity) : TParticleEffectComponent;
    published
      [XEvent(eiWelaActive, epLast, etWrite)]
      function OnWelaActive(Value : RParam) : boolean;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Starts Emission. </summary>
      function OnAfterDeserialization() : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      /// <summary> Starts Emission. </summary>
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiPreFire, epLast, etTrigger)]
      /// <summary> Starts Emission. </summary>
      function OnPreFire(Targets : RParam) : boolean;
      [XEvent(eiFireWarhead, epLast, etTrigger)]
      /// <summary> Starts Emission. </summary>
      function OnFireWarhead(Targets : RParam) : boolean;
      [XEvent(eiMoveTo, epLast, etTrigger)]
      function OnMoveTo(Target, Range : RParam) : boolean;
      [XEvent(eiDie, epLower, etTrigger)]
      /// <summary> Starts Emission. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiExiled, epLast, etWrite)]
      /// <summary> Unit stops pfx on exile. </summary>
      function OnExiled(Exiled : RParam) : boolean;
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      function OnLose(TeamID : RParam) : boolean;
    public
      constructor Create(Owner : TEntity; ParticlePath : string; SizeNormalization : single); reintroduce;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; const ParticlePath : string; SizeNormalization : single); reintroduce;
      constructor CreateGroupedAndActivated(Owner : TEntity; Group : TArray<byte>; const ParticlePath : string; SizeNormalization : single);
      function ActivateOnCreate() : TParticleEffectComponent;
      function ActivateNow() : TParticleEffectComponent;
      function ActivateOnFireWarhead() : TParticleEffectComponent;
      function ActivateOnPreFire() : TParticleEffectComponent;
      function ActivateOnFire() : TParticleEffectComponent;
      function ActivateOnFireDelayed(DeferTime : integer) : TParticleEffectComponent;
      function ActivateAtFireTarget() : TParticleEffectComponent;
      function ActivateOnLose() : TParticleEffectComponent;
      function ActivateOnWelaActivate() : TParticleEffectComponent;
      function ActivateOnDie() : TParticleEffectComponent;
      function ActivateOnFree() : TParticleEffectComponent;
      function DeactivateOnMoveTo() : TParticleEffectComponent;
      function DeactivateOnTime(StopTime : integer) : TParticleEffectComponent;
      function DeactivateOnDie() : TParticleEffectComponent;
      function DeactivateOnFire() : TParticleEffectComponent;
      function Delay(DeferTime : integer) : TParticleEffectComponent;
      function PlaceAtSavedTarget() : TParticleEffectComponent;
      function IgnoreModelSize : TParticleEffectComponent; reintroduce;
      function EmitFromAllBones : TParticleEffectComponent;
      function ClonesToTarget : TParticleEffectComponent;
      function ScaleWith(Event : EnumEventIdentifier) : TParticleEffectComponent; reintroduce;
      function FixedOrientationDefault : TParticleEffectComponent; reintroduce;
      function FixedHeightGround : TParticleEffectComponent; reintroduce;
      function ScaleRange(Minimum, Maximum : single) : TParticleEffectComponent; reintroduce;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Renders a hologram of the produced unit of this entity. </summary>
  TProductionPreviewComponent = class(TEntityComponent)
    protected
      FPreviews : TAdvancedList<TEntity>;
      FIsSpawner : boolean;
      FUnitCount : integer;
      procedure ComputePreviews;
      procedure PositionPreviews;
      procedure ClearPreviews;
      procedure EnumerateComponents(Callback : ProcEnumerateEntityComponentCallback); override;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Read Data and build previews. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiModelSize, epLast, etWrite)]
      /// <summary> Apply the size to the preview. </summary>
      function OnModelSize(ModelSize : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> Kills the preview. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiColorAdjustment, epLast, etTrigger)]
      /// <summary> Recolorize the preview. </summary>
      function OnColorAdjustment(ColorAdjustment : RParam; absH, absS, absV : RParam) : boolean;
      [XEvent(eiDrawOutline, epLast, etTrigger)]
      /// <summary> Draw the preview outlined. </summary>
      function OnDrawOutline(Color, OnlyOutline : RParam) : boolean;
      [XEvent(eiIdle, epLower, etTrigger, esGlobal)]
      /// <summary> Write visibilty to preview. </summary>
      function OnIdle() : boolean;
      [XEvent(eiSubPositionByString, epFirst, etRead)]
      /// <summary> Relay query to the preview. </summary>
      function OnSubPositionByString(Name, Previous : RParam) : RParam;
      [XEvent(eiGetUnitsAtCursor, epLow, etRead, esGlobal)]
      /// <summary> Returns the owner if returned value is preview. </summary>
      function OnGetUnitsAtCursor(ClickRay : RParam; Previous : RParam) : RParam;
      [XEvent(eiBoundings, epFirst, etRead)]
      /// <summary> Redirect event. </summary>
      function OnBoundings() : RParam;
    public
      constructor Create(Owner : TEntity); override;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function IsSpawner : TProductionPreviewComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  TMeshComponent = class;

  TMeshEffect = class abstract
    protected
      FOwningEntity : TEntity;
      FOwningComponent : TMeshComponent;
      FMesh : TMesh;
      FCustomShader, FOriginalGlowTexture : string;
      FHasShaderSetup, FManaged, FColorIdentityOverride : boolean;
      FBlendMode : EnumBlendMode;
      FNeedOwnPass : SetRenderStage;
      FOwnPasses : integer;
      FGlowOverride, FUseGlowOverride, FGlowTextureOverride, FOwnPassBlocks, FIsMounted : boolean;
      FColorIdentity : EnumEntityColor;
      // smallest value gets rendered first
      FOrderValue : integer;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; virtual;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); virtual;
      function Expired : boolean; virtual;
      procedure InitializeOnMesh(const Mesh : TMesh); virtual;
      procedure FinalizeOnMesh(); virtual;
      procedure InitShader(const ShaderName : string);
      procedure InitOnEntity(const Entity : TEntity); virtual;
      constructor CreateEmpty;
    public
      /// <summary> If any effect is important it will be applied alone. If multiple the first is taken. </summary>
      property Managed : boolean read FManaged write FManaged;
      property OrderValue : integer read FOrderValue;
      [ScriptExcludeMember]
      property NeedOwnPass : SetRenderStage read FNeedOwnPass;
      property IsMounted : boolean read FIsMounted;
      property ColorIdentity : EnumEntityColor read FColorIdentity;
      /// <summary> Only for own passes. </summary>
      function Additive : TMeshEffect;
      constructor Create();
      function OverrideGlowTexture : TMeshEffect;
      function OverrideColorIdentity(ColorIdentity : EnumEntityColor) : TMeshEffect;
      procedure Reset; virtual;
      procedure AssignToEntity(const Entity : TEntity);
  end;

  TMeshEffectGeneric = class abstract(TMeshEffect)
    protected
      FLastDisplayedTeamID : integer;
      FTextureSlot : EnumTextureSlot;
      FTextureName : string;
      FEffectTexture : TTexture;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(const ShaderName, TextureFilename : string);
      function SetTexture(const TextureFilename : string) : TMeshEffectGeneric;
      destructor Destroy; override;
  end;

  TMeshEffectWithTimekeys = class abstract(TMeshEffectGeneric)
    protected
      FTimer : TTimer;
      FTimedKeyPoints : TArray<TArray<RTuple<integer, single>>>;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      function CurrentValue(Index : integer = 0) : single;
      function HasTimeLine(Index : integer) : boolean;
      function Expired : boolean; override;
    public
      constructor Create(Duration : integer);
      procedure Reset; override;
      function AddNextTimeLine : TMeshEffectWithTimekeys;
      function AddKey(TimeKey : integer; Value : single) : TMeshEffectWithTimekeys;
      function AddPermaKey(Value : single) : TMeshEffectWithTimekeys;
      destructor Destroy; override;
  end;

  TMeshEffectColorOverlay = class(TMeshEffect)
    strict private
    const
      ORDER_VALUE = 2;
    protected
      FColor : RColor;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(const Color : cardinal);
  end;

  TMeshEffectTint = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 5000;
    protected
      FColor : RColor;
      FAdditive : boolean;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration, Color : cardinal);
      function Additive : TMeshEffectTint;
  end;

  /// <summary> Adds a icy surface to the mesh. </summary>
  TMeshEffectIce = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 5;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer);
  end;

  /// <summary> Adds a stone surface to the mesh. </summary>
  TMeshEffectStone = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 6;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer);
  end;

  /// <summary> Adds a ghost which flies away to the mesh. </summary>
  TMeshEffectSoulExtract = class(TMeshEffectWithTimekeys)
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer);
  end;

  /// <summary> Adds a ghostly corona to the mesh. </summary>
  TMeshEffectSoulGain = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 9999;
    protected
      FRadius : single;
      FColor : RColor;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer);
      function Radius(Radius : single) : TMeshEffectSoulGain;
      function Color(Color : cardinal) : TMeshEffectSoulGain;
  end;

  /// <summary> Adds a ghostly corona to the mesh. </summary>
  TMeshEffectGhost = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 3;
    protected
      FFactor, FOffset : single;
      FAdditive : boolean;
      FColor : RColor;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create();
      function Factor(Factor : single) : TMeshEffectGhost;
      function Offset(Offset : single) : TMeshEffectGhost;
      function Additive : TMeshEffectGhost;
      function Color(Color : cardinal) : TMeshEffectGhost;
  end;

  /// <summary> Adds full glow to the mesh and changes the albedo to the glow color dependent on the entitys color identity. </summary>
  TMeshEffectGlow = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 9998;
    protected
      FFixedColorIdentity : boolean;
      FFixedColor : EnumEntityColor;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer);
      function FixedColorIdentity(ColorIdentity : EnumEntityColor) : TMeshEffectGlow;
  end;

  /// <summary> Uses two timelines: First Glow, Second Visibility. Uses mask texture. </summary>
  TMeshEffectHideAndGlow = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 9997;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer; const TextureFilename : string);
  end;

  TMeshEffectSpherify = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 9996;
    protected
      FUseFixedCenter : boolean;
      FFixedCenter : RVector3;
      FPowFactor : single;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer);
      function PowFactor(PowFactor : single) : TMeshEffectSpherify;
      function SetFixedCenter(X, Y, Z : single) : TMeshEffectSpherify;
  end;

  TMeshEffectMelt = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 9995;
    protected
      FMeltStep, FMeltHeightOverride : single;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(Duration : integer);
      function Step(Step : single) : TMeshEffectMelt;
      function Height(Height : single) : TMeshEffectMelt;
  end;

  TMeshEffectWarp = class(TMeshEffectWithTimekeys)
    strict private
    const
      ORDER_VALUE = 9994;
    protected
      FSmoothStep : single;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(const TextureFilename : string; Duration : integer);
      function Smooth(Step : single) : TMeshEffectWarp;
  end;

  TMeshEffectMetal = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 10000;
    protected
      FColorOverride : EnumEntityColor;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure InitOnEntity(const Entity : TEntity); override;
    public
      constructor Create();
      function ShowAsColor(ColorOverride : EnumEntityColor) : TMeshEffectMetal;
  end;

  TMeshEffectMatcap = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 9993;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure InitOnEntity(const Entity : TEntity); override;
    public
      constructor Create();
  end;

  TMeshEffectWobble = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 9992;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(const VoidMask : string);
  end;

  TMeshEffectInvisible = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 10;
    protected
      FSmoothStep, FSpeed, FSpan : single;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create();
      function Smooth(Step : single) : TMeshEffectInvisible;
      function Speed(Speed : single) : TMeshEffectInvisible;
      function Span(Span : single) : TMeshEffectInvisible;
  end;

  TMeshEffectVoid = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 4999;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create();
  end;

  TMeshEffectSlidingTexture = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 4998;
    protected
      FSpeed, FTiling : RVector2;
      FFurThickness : single;
      FGlowOverride, FFurOverride : boolean;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
      procedure InitializeOnMesh(const Mesh : TMesh); override;
      procedure FinalizeOnMesh(); override;
    public
      constructor Create(const TextureFilename : string);
      function Speed(const SpeedX, SpeedY : single) : TMeshEffectSlidingTexture;
      function Tiling(const TilingX, TilingY : single) : TMeshEffectSlidingTexture;
  end;

  TMeshEffectTeamColor = class(TMeshEffectGeneric)
    strict private
    const
      ORDER_VALUE = 9991;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
    public
      constructor Create(const MaskFilename : string);
  end;

  TMeshEffectSpawn = class(TMeshEffect)
    strict private
    const
      ORDER_VALUE                                       = 1;
      BLUE_PASSES                                       = 20;
      EFFECT_TIMES : array [EnumEntityColor] of integer = (
        1000, // ecColorless
        2500, // ecBlack
        2500, // ecGreen
        2500, // ecRed
        1500, // ecBlue
        2500  // ecWhite
        );
    protected
      FSpawneffectTexture : TTexture;
      FCullmode : EnumCullmode;
      FSpawnTimer : TTimer;
      FFrame, FOffset : integer;
      FZDiff, FHeightFactor : single;
      FLegendary : boolean;
      FOverrideColor : RColor;
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
      function Expired : boolean; override;
      procedure InitializeOnMesh(const Mesh : TMesh); override;
      procedure FinalizeOnMesh(); override;
      procedure SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer); override;
      procedure InitOnEntity(const Entity : TEntity); override;
    public
      constructor Create();
      function OverrideEffectTime(Interval : integer) : TMeshEffectSpawn;
      function OffsetEffectTime(Offset : integer) : TMeshEffectSpawn;
      function OverrideColor(Color : cardinal) : TMeshEffectSpawn;
      function HeightFactor(Factor : single) : TMeshEffectSpawn;
      function Legendary : TMeshEffectSpawn;
      destructor Destroy; override;
  end;

  TMeshEffectSpawnerSpawn = class(TMeshEffectSpawn)
    strict private
    const
      ORDER_VALUE = 5;
    protected
      function Clone(const Effect : TMeshEffect) : TMeshEffect; override;
    public
      constructor Create();
  end;

  EnumMeshTexture = (mtDiffuse, mtNormal, mtMaterial, mtGlow);

  TConditionalMeshTexture = class abstract
    TextureType : EnumMeshTexture;
    TextureFilename : string;
    function Check(Component : TEntityComponent) : boolean; virtual; abstract;
  end;

  TConditionalMeshTextureTeam = class(TConditionalMeshTexture)
    TargetTeamID : integer;
    function Check(Component : TEntityComponent) : boolean; override;
  end;

  TConditionalMeshTextureUnitProperty = class(TConditionalMeshTexture)
    MustHaveAny : SetUnitProperty;
    function Check(Component : TEntityComponent) : boolean; override;
  end;

  TConditionalMeshTextureResource = class(TConditionalMeshTexture)
    ResourceType : EnumResource;
    Comparator : EnumComparator;
    ReferenceValue : single;
    ComponentGroup : SetComponentGroup;
    function Check(Component : TEntityComponent) : boolean; override;
  end;

  /// <summary> Displays a mesh. </summary>
  TMeshComponent = class(TVisualizerComponent)
    protected
      const
      SIZE_FACTOR_3DSMAX = 2 / 125;
    var
      FMesh : TMesh;
      FDeathColorIdentityOverrideActive : boolean;
      FDeathColorIdentityOverride : EnumEntityColor;
      FDecaying, FIgnoreScalingForAnimations, FIsEffectMesh, FNoWalkOffset, FConditionalTexturesDirty : boolean;
      FAnimationSpeed : TDictionary<string, single>;
      FSizeNormalization : single;
      FModelFileName : string;
      FOutlineColor : RColor;
      FLastBoundings : RSphere;
      FHasAttackLoop, FHighlightedThisFrame, FOnlyOutline, FColorHasBeenAdjusted, FUsesGlobalShadingReduction, FShadingReductionFromTerrain, FCastsNoShadows : boolean;
      FEffectStack : TAdvancedObjectList<TMeshEffect>;
      FZoneToBoneBinding, FFollowingDefaultAnimation : TDictionary<string, string>;
      FBoneAdjustments : TDictionary<string, RMatrixAdjustments>;
      // conditional textures
      FOriginalTextures : array [EnumMeshTexture] of string;
      FConditionalTextures : TObjectList<TConditionalMeshTexture>;
      FAlternatingZoneIndex : integer;
      FAlternatingZones : TDictionary<string, integer>;
      procedure LoadMesh;
      procedure CheckConditionalTextures;
      procedure ConditionalTexturesDirty;
      procedure PopEffect;
      procedure Apply; override;
      function FinalSize : RVector3; override;
      procedure Idle; override;
      constructor Create(Meshpath : string); reintroduce; overload;
      procedure AddMeshEffect(const MeshEffect : TMeshEffect);
      procedure RemoveMeshEffect(const MeshEffect : TMeshEffect);
      /// <summary> Returns default if not present in dict. </summary>
      function GetBoneAdjustments(const BoneName : string) : RMatrixAdjustments;
      procedure SetBoneAdjustments(const BoneName : string; const Value : RMatrixAdjustments);
      function TryGetBoneAdjustments(const BoneName : string; out Adjustments : RMatrixAdjustments) : boolean;
    published
      [XEvent(eiDrawOutline, epMiddle, etTrigger)]
      /// <summary> Draws a model outline in this frame. </summary>
      function OnDrawOutline(Color, OnlyOutline : RParam) : boolean;
      [XEvent(eiAfterCreate, epMiddle, etTrigger)]
      /// <summary> Initializes the model. </summary>
      function OnAfterDeserialization() : boolean;
      [XEvent(eiChangeCommander, epLast, etTrigger, esGlobal)]
      /// <summary> Update conditional textures. </summary>
      function OnChangeCommander(Index : RParam) : boolean;
      [XEvent(eiColorAdjustment, epLast, etTrigger), ScriptExcludeMember]
      /// <summary> Recolorize the mesh. </summary>
      function OnColorAdjustment(ColorAdjustment : RParam; absH, absS, absV : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      /// <summary> Inflates the mesh and let it glow. </summary>
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiPlayAnimation, epLast, etTrigger)]
      /// <summary> Plays an animation. </summary>
      function OnPlayAnimation(AnimationName, AnimationPlayMode, Length : RParam) : boolean;
      [XEvent(eiSubPositionByString, epFirst, etRead)]
      /// <summary> Return the center of the mesh. </summary>
      function OnSubPositionByString(Name : RParam; PrevValue : RParam) : RParam;
      [XEvent(eiUnitPropertyChanged, epLast, etTrigger)]
      /// <summary> Pauses animation. </summary>
      function OnUnitPropertyChanged(ChangedUnitProperties, Removed : RParam) : boolean;
      [XEvent(eiBoundings, epFirst, etRead)]
      /// <summary> Return the boundingsphere. </summary>
      function OnBoundings(Previous : RParam) : RParam;
      [XEvent(eiClientOption, epLast, etTrigger, esGlobal)]
      function OnClientOption(ChangedOption : RParam) : boolean;
      [XEvent(eiResourceBalance, epLast, etWrite)]
      function OnSetResource(ResourceID, Amount : RParam) : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
    public
      constructor Create(Owner : TEntity; Meshpath : string); reintroduce; overload;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Meshpath : string); reintroduce;
      function CastsNoShadows : TMeshComponent;
      function ShadingReductionFromTerrain : TMeshComponent;
      function ApplyAutoSizeNormalization : TMeshComponent;
      function ApplyLegacySizeFactor : TMeshComponent;
      function HasAttackLoop : TMeshComponent;
      function NoWalkOffset : TMeshComponent;
      function AlternatingZone(const ZoneName : string; ZoneCount : integer) : TMeshComponent;
      function IgnoreScalingForAnimations : TMeshComponent;
      function IsEffectMesh : TMeshComponent;
      function SetAnimationSpeed(const AnimationName : string; AnimationSpeed : single) : TMeshComponent;
      function CreateNewAnimationFrom(SourceAnimation : string; NewAnimationName : string; Startframe, Endframe : integer) : TMeshComponent;
      /// <summary> For "FBX import" to create several animationclips from standard fbx animationtrack,
      /// until MAYA LT supports named animationclips.</summary>
      function CreateNewAnimation(AnimationName : string; Startframe, Endframe : integer) : TMeshComponent; overload;
      function CreateNewAnimationFromFile(const AnimationFile, AnimationName : string) : TMeshComponent; overload;
      function SetFollowingDefaultAnimation(const AnimationName, FollowingDefaultAnimationName : string) : TMeshComponent; overload;
      function ApplyTeamColoring(MaskFilename : string) : TMeshComponent;
      function BindZoneToBone(const ZoneName, BoneName : string) : TMeshComponent;
      function IsDecal : TMeshComponent; reintroduce;
      function BoneInvertX(const BoneName : string) : TMeshComponent;
      function BoneInvertY(const BoneName : string) : TMeshComponent;
      function BoneInvertZ(const BoneName : string) : TMeshComponent;
      function BoneSwapXY(const BoneName : string) : TMeshComponent;
      function BoneSwapXZ(const BoneName : string) : TMeshComponent;
      function BoneSwapYZ(const BoneName : string) : TMeshComponent;
      function BoneSwizzleXZY(const BoneName : string) : TMeshComponent;
      function BoneSwizzleZYX(const BoneName : string) : TMeshComponent;
      function BoneSwizzleYXZ(const BoneName : string) : TMeshComponent;
      function BoneSwizzleZXY(const BoneName : string) : TMeshComponent;
      function BoneSwizzleYZX(const BoneName : string) : TMeshComponent;
      function BoneOffset(const BoneName : string; OffsetX, OffsetY, OffsetZ : single) : TMeshComponent;
      function BoneRotation(const BoneName : string; RotationX, RotationY, RotationZ : single) : TMeshComponent;
      function BindTextureToResource(TextureType : EnumMeshTexture; const TextureFilename : string; ResourceType : EnumResource; Comparator : EnumComparator; ReferenceValue : single; TargetGroup : TArray<byte>) : TMeshComponent;
      function BindTextureToTeam(TextureType : EnumMeshTexture; const TextureFilename : string; TeamID : integer) : TMeshComponent;
      function BindTextureToUnitProperty(TextureType : EnumMeshTexture; const TextureFilename : string; MustHave : TArray<byte>) : TMeshComponent;
      function DeathColorIdentityOverride(ColorIdentity : EnumEntityColor) : TMeshComponent;
      {$IFDEF MAPEDITOR}
      [ScriptExcludeMember]
      procedure ShowMaterialEditor;
      {$ENDIF}
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  TMeshEffectComponent = class(TEntityComponent)
    protected
      FEffects : TObjectDictionary<TMeshComponent, TObjectList<TMeshEffect>>;
      FTargetGroup : SetComponentGroup;
      FDelayedEffects : TObjectList<TMeshEffect>;
      FOnDie, FOnFire, FOnPreFire, FOnLose, FAtTarget, FOnWelaUnitProduced : boolean;
      procedure ApplyEffects(Targets : TArray<TEntity>);
    published
      [XEvent(eiDie, epLast, etTrigger)]
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiPreFire, epLast, etTrigger)]
      function OnPreFire(Targets : RParam) : boolean;
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      function OnLose(TeamID : RParam) : boolean;
      [XEvent(eiWelaUnitProduced, epLast, etTrigger)]
      function OnWelaUnitProduced(EntityID : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function ActivateOnLose() : TMeshEffectComponent;
      function ActivateOnDie() : TMeshEffectComponent;
      function ActivateOnFire() : TMeshEffectComponent;
      function ActivateOnPreFire() : TMeshEffectComponent;
      function ActivateOnWelaUnitProduced() : TMeshEffectComponent;
      function ApplyToFireTarget() : TMeshEffectComponent;
      function TargetGroup(const Group : TArray<byte>) : TMeshEffectComponent;
      function SetEffect(const Effect : TMeshEffect) : TMeshEffectComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  TAnimationComponent = class(TEntityComponent)
    protected
      FSecondAttackGroup : SetComponentGroup;
      FSecondAttack : SetUnitProperty;
      FOpenLinkCount : integer;
      FLoopFire, FIsLink, FAlternatingAttack, FAlternateAttack, FHasAntiAirAttack : boolean;
      FAnimationLength : TDictionary<EnumEventIdentifier, integer>;
      FAbilityGroup : SetComponentGroup;
      procedure PlayAttack(Target : ATarget);
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Play spawnanimation. </summary>
      function OnAfterCreate() : boolean;
      [XEvent(eiPreFire, epLast, etTrigger)]
      /// <summary> Play fireanimation. </summary>
      function OnPreFire(Targets : RParam) : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      /// <summary> Play fireanimation. </summary>
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiLinkEstablish, epLast, etTrigger)]
      /// <summary> Play fireanimation. </summary>
      function OnLinkEstablish(Source, Dest : RParam) : boolean;
      [XEvent(eiLinkBreak, epLast, etTrigger)]
      /// <summary> Play standanimation. </summary>
      function OnLinkBreak(Dest : RParam) : boolean;
      [XEvent(eiStand, epLast, etTrigger)]
      /// <summary> Play standanimation. </summary>
      function OnStand() : boolean;
      [XEvent(eiMoveTo, epLast, etTrigger)]
      /// <summary> Play Walkanimation. </summary>
      function OnMoveTo(Target, Range : RParam) : boolean;
    public
      function SetAnimationSpeed(identifier : EnumEventIdentifier; AnimationLength : integer) : TAnimationComponent;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function LoopFire : TAnimationComponent;
      function IsLink : TAnimationComponent;
      function HasAntiAirAttack : TAnimationComponent;
      function SecondAttackAgainst(Properties : TArray<byte>) : TAnimationComponent;
      function SecondAttackGroup(Group : TArray<byte>) : TAnimationComponent;
      function AlternatingAttack : TAnimationComponent;
      function AbilityGroup(Group : TArray<byte>) : TAnimationComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes a pointlight which behave like a mesh with orientation etc. </summary>
  TPointLightComponent = class(TVisualizerComponent)
    protected
      FLight : TPointLight;
      FColor : RColor;
      procedure Apply; override;
    public
      constructor Create(Owner : TEntity; Color : cardinal; Radius : single); reintroduce;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Color : cardinal; Radius : single); reintroduce;
      function SetLightShape(Shape : RVector3) : TPointLightComponent;
      function Negate : TPointLightComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes a textured quad which behave like a mesh with orientation etc. </summary>
  TVertexQuadComponent = class(TVisualizerComponent)
    protected
      FQuadSize : RVector2;
      FIsUnitplaceholder, FIsScreenSpace, FCameraOriented : boolean;
      FVertexQuad : TVertexWorldspaceQuad;
      procedure Apply; override;
      procedure Idle; override;
    published
      [XEvent(eiSubPositionByString, epFirst, etRead)]
      /// <summary> Return the center of the quad. </summary>
      function OnSubPositionByString(Name : RParam; PrevValue : RParam) : RParam;
      [XEvent(eiBoundings, epFirst, etRead)]
      /// <summary> Return the boundingsphere of the mesh. </summary>
      function OnBoundings(const Previous : RParam) : RParam;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      /// <summary> Initializes the quad. </summary>
      function OnAfterCreate : boolean;
    public
      constructor Create(Owner : TEntity; Texture : string; Width, Height : single); reintroduce;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Texture : string; Width, Height : single); reintroduce;
      function SetUnitPlaceholder : TVertexQuadComponent;
      function ScreenSpace : TVertexQuadComponent;
      function CameraOriented : TVertexQuadComponent;
      function Additive : TVertexQuadComponent;
      function Color(Color : cardinal) : TVertexQuadComponent;
      function IsDecal : TVertexQuadComponent; reintroduce;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes a vertex trace which follows the entity. </summary>
  TVertexTraceComponent = class(TVisualizerComponent)
    protected
      FQuadSize : RVector2;
      FVertexTrace : TVertexTrace;
      FRollUpSpeed : single;
      FDeactivateAfterTime : TTimer;
      FActivateOnFire, FActivateOnPreFire, FDeactivateOnMoveTo, FLocalSpell : boolean;
      procedure Apply; override;
      procedure Idle; override;
      procedure Activate;
      procedure Deactivate;
    published
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterCreate : boolean;
      [XEvent(eiPreFire, epLast, etTrigger)]
      function OnPreFire(Targets : RParam) : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiMoveTo, epLast, etTrigger)]
      function OnMoveTo(Target, Range : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); reintroduce;
      function Texture(const Filename : string) : TVertexTraceComponent;
      function Color(Color : cardinal) : TVertexTraceComponent;
      function Width(Width : single) : TVertexTraceComponent;
      function SamplingDistance(SamplingDistance : single) : TVertexTraceComponent;
      function FadeLength(FadeLength : single) : TVertexTraceComponent;
      function FadeWidening(FadeWidening : single) : TVertexTraceComponent;
      function MaxLength(MaxLength : single) : TVertexTraceComponent;
      function TexturePerDistance(TexturePerDistance : single) : TVertexTraceComponent;
      function RollUpSpeed(RollUpSpeed : single) : TVertexTraceComponent;
      function Additive : TVertexTraceComponent;
      function ActivateOnFire : TVertexTraceComponent;
      function ActivateOnPreFire : TVertexTraceComponent;
      function ActivateNow : TVertexTraceComponent;
      function DeactivateOnMoveTo : TVertexTraceComponent;
      function DeactivateAfterTime(TimeMs : integer) : TVertexTraceComponent;
      function VisibleWithResource(ResourceID : EnumResource) : TVertexTraceComponent;
      function LocalSpace : TVertexTraceComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes a link with many little bullets. </summary>
  TLinkBulletVisualizerComponent = class(TEntityComponent)
    protected
      type
      RBullet = record
        Bullet : TVertexWorldspaceQuad;
        StartTime : int64;
        Speed : single;
        Offset : RVector3;
      end;
    var
      FBullets : TList<RBullet>;
      FBulletTimer : TTimer;
      FTexture : TTexture;
      EndPos : RTarget;
      FSpawnTime : RVariedSingle;
      FSpeed, FWidth, FHeight, FJitter : RVariedSingle;
      FEndposJitter : RVariedVector3;
      FToGround : boolean;
      FColor : RColor;
      FImpactParticleEffect : TParticleEffect;
      procedure SpawnBullet(StartTime : int64);
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Compute bullets. </summary>
      function OnIdle() : boolean;
    public
      /// <summary> It spawns bullets with given width,height,texture, which fly linear from linksource to destsource with radial jitter at impact. </summary>
      constructor Create(Owner : TEntity; Texture : string); reintroduce;
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>; Texture : string); reintroduce;
      function SetBulletSpawnCooldown(Cooldown : RVariedSingle) : TLinkBulletVisualizerComponent;
      function SetSpeed(Speed : RVariedSingle) : TLinkBulletVisualizerComponent;
      function SetWidth(Width : RVariedSingle) : TLinkBulletVisualizerComponent;
      function SetLength(Length : RVariedSingle) : TLinkBulletVisualizerComponent;
      function SetEndposJitter(EndposJitter : single) : TLinkBulletVisualizerComponent;
      function Color(const Color : cardinal) : TLinkBulletVisualizerComponent;
      /// <summary> Changes target height to ground level if destination is a ground unit. </summary>
      function ToGround : TLinkBulletVisualizerComponent;
      /// <summary> Particleeffect triggered only if target is a ground target. </summary>
      function ImpactParticleEffect(const FilePath : string) : TLinkBulletVisualizerComponent;
      function ImpactSize(const Size : single) : TLinkBulletVisualizerComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes a link with a ray consisting of x subrays. </summary>
  TVertexRayVisualizerComponent = class(TEntityComponent)
    protected
      type
      RRay = record
        Ray : TVertexWorldspaceQuad;
        Speed, RotSpeed, Width, Length : single;
        Offset : RVector3;
      end;
    var
      FTimedSizeKeyPoints : TArray<RTuple<integer, RVector2>>;
      FSizeKeyPoints : TArray<RVector2>;
      FTimer : TTimer;

      FScaleWithResource : EnumResource;
      FRays : TAdvancedList<RRay>;
      FOpacity, FScaleWidth : single;
      FPlanar : boolean;

      FStartZoneBinding : string;
      FStartZoneGroup : SetComponentGroup;
      FStartZoneOffset, FEndZoneOffset : RVector3;

      FRayTexture : TTexture;
      EndPos : RTarget;
      FEndposJitter, FStartWidth : single;
      FWidth, FLength, FLongitudinalSpeed, FRotationSpeed : RVariedSingle;
      procedure InitRays;
      function CurrentSize : RVector2; virtual;
      function CurrentStartPosition : RVector3; virtual;
      function CurrentEndPosition : RVector3; virtual;
      procedure SetValues(const Values : TArray<single>; Axis : integer; var TargetArray : TArray<RVector2>);
      procedure SetTimes(const Values : TArray<integer>; var SourceArray : TArray<RVector2>; var TargetArray : TArray < RTuple < integer, RVector2 >> );
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Compute rays. </summary>
      function OnIdle() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>); override;
      function Texture(const FilePath : string) : TVertexRayVisualizerComponent;
      function SetOpacity(Opacity : single) : TVertexRayVisualizerComponent;
      function SetStartWidth(Width : single) : TVertexRayVisualizerComponent;
      function SetWidth(Width : RVariedSingle) : TVertexRayVisualizerComponent;
      function SetLength(Length : RVariedSingle) : TVertexRayVisualizerComponent;
      function SetLongitudinalSpeed(LongitudinalSpeed : RVariedSingle) : TVertexRayVisualizerComponent;
      function SetRotationSpeed(RotationSpeed : RVariedSingle) : TVertexRayVisualizerComponent;
      function SetEndposJitter(EndposJitter : single) : TVertexRayVisualizerComponent;
      function SetRaycount(Count : integer) : TVertexRayVisualizerComponent;
      function Planar() : TVertexRayVisualizerComponent;

      function SizeKeypoints(Values : TArray<single>) : TVertexRayVisualizerComponent;
      function SizeKeypointsWidth(Values : TArray<single>) : TVertexRayVisualizerComponent;
      function SizeKeypointsLength(Values : TArray<single>) : TVertexRayVisualizerComponent;
      function SizeTimes(Values : TArray<integer>) : TVertexRayVisualizerComponent;

      function ScaleWidth(ScaleWidth : single) : TVertexRayVisualizerComponent;
      function ScaleWith(Resource : EnumResource) : TVertexRayVisualizerComponent;
      function BindStartToSubPositionGroup(const ZoneName : string; TargetGroup : TArray<byte>) : TVertexRayVisualizerComponent;
      function BindStartOffset(StartOffsetX, StartOffsetY, StartOffsetZ : single) : TVertexRayVisualizerComponent;
      function BindEndOffset(EndOffsetX, EndOffsetY, EndOffsetZ : single) : TVertexRayVisualizerComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Visualizes a link with a ray consisting of x subrays. </summary>
  TLinkRayVisualizerComponent = class(TVertexRayVisualizerComponent)
    protected
      FDestSubPosition : string;
      function CurrentStartPosition : RVector3; override;
      function CurrentEndPosition : RVector3; override;
    published
      [XEvent(eiAfterCreate, epFirst, etTrigger)]
      function OnAfterDeserialization() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>); override;
      function SetDestSubPosition(const SubPosition : string) : TVertexRayVisualizerComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Attaches the position to the link source or dest. </summary>
  TPositionerAttacherComponent = class(TEntityComponent)
    protected
      FSource, FUseFront, FInvertFront, FDebug : boolean;
      FPosition, FFront, FLastTargetPos : RVector3;
      FAttachIndex : integer;
      FSubPosition : string;
      FSubPositionGroup : SetComponentGroup;
      FOffset : RVector3;
      function TryGetTarget(out Target : RTarget) : boolean;
    published
      [XEvent(eiDisplayPosition, epMiddle, etRead)]
      function OnDisplayPosition(PreviousPosition : RParam) : RParam;

      [XEvent(eiDisplayFront, epMiddle, etRead)]
      function OnDisplayFront(PreviousFront : RParam) : RParam;

      [XEvent(eiSubPositionByString, epFirst, etRead)]
      /// <summary> Relay to source. </summary>
      function OnSubPositionByString(Name : RParam) : RParam;
      [XEvent(eiAfterCreate, epHigh, etTrigger)]
      /// <summary> Init the starting position. </summary>
      function OnAfterDeserialization() : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      /// <summary> Manipulate position. </summary>
      function OnIdle() : boolean;
    public
      /// <summary> If AttachToSource is false, it will be attached to dest. </summary>
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function AttachToSource : TPositionerAttacherComponent;
      function AttachToDestination : TPositionerAttacherComponent;
      function SetSubPosition(const SubPosition : string) : TPositionerAttacherComponent;
      function SetSubPositionGroup(const SubPosition : string; Group : TArray<byte>) : TPositionerAttacherComponent;
      function Offset(OffsetX, OffsetY, OffsetZ : single) : TPositionerAttacherComponent;
      /// <summary> The index of souorce/destination this component is attaching to. </summary>
      function SetIndex(Index : integer) : TPositionerAttacherComponent;
      function ApplyFront : TPositionerAttacherComponent;
      function InvertFront : TPositionerAttacherComponent;
      function RenderDebug : TPositionerAttacherComponent;
  end;

  {$RTTI INHERIT}

  /// <summary> Plays an positional animation with keyframes. </summary>
  TAnimatorComponent = class(TEntityComponent)
    protected
      FOffset : RVector3;
      FKeyPoints, FFrontKeypoints, FSizeKeyPoints : TArray<RVector3>;
      FTimedKeyPoints, FTimedFrontKeypoints, FTimedSizeKeyPoints : TArray<RTuple<integer, RVector3>>;
      FHideUntil, FHideAfter : integer;
      FTimer : TTimer;
      FFreeGroup : boolean;
      FInterpolationMode : EnumInterpolationMode;
      FAnimations : TArray<RTriple<integer, string, integer>>;
      FOnDie, FOnFire, FOnPreFire, FOnLose : boolean;
      procedure SetValues(const Values : TArray<single>; Axis : integer; var TargetArray : TArray<RVector3>);
      procedure SetTimes(const Values : TArray<integer>; var SourceArray : TArray<RVector3>; var TargetArray : TArray < RTuple < integer, RVector3 >> );
    published
      [XEvent(eiDie, epLast, etTrigger)]
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiDisplayPosition, epLow, etRead)]
      function OnDisplayPosition(Previous : RParam) : RParam;
      [XEvent(eiDisplayFront, epLow, etRead)]
      function OnDisplayFront(Previous : RParam) : RParam;
      [XEvent(eiSize, epLow, etRead)]
      function OnSize(Previous : RParam) : RParam;
      [XEvent(eiIdle, epHigh, etTrigger, esGlobal)]
      function OnIdle() : boolean;
      [XEvent(eiVisible, epMiddle, etRead)]
      function OnVisible(Previous : RParam) : RParam;
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiPreFire, epLast, etTrigger)]
      function OnPreFire(Targets : RParam) : boolean;
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      function OnLose(TeamID : RParam) : boolean;
    public
      function InterpolationMode(Mode : EnumInterpolationMode) : TAnimatorComponent;
      function Offset(X, Y, Z : single) : TAnimatorComponent;
      function Duration(TimeMs : integer) : TAnimatorComponent;
      function FreeGroupAfter() : TAnimatorComponent;

      function HideUntil(TimeKey : integer) : TAnimatorComponent;
      function HideAfter(TimeKey : integer) : TAnimatorComponent;

      function PositionKeypointsX(Values : TArray<single>) : TAnimatorComponent;
      function PositionKeypointsY(Values : TArray<single>) : TAnimatorComponent;
      function PositionKeypointsZ(Values : TArray<single>) : TAnimatorComponent;
      function PositionTimes(Values : TArray<integer>) : TAnimatorComponent;

      function FrontKeypointsX(Values : TArray<single>) : TAnimatorComponent;
      function FrontKeypointsY(Values : TArray<single>) : TAnimatorComponent;
      function FrontKeypointsZ(Values : TArray<single>) : TAnimatorComponent;
      function FrontTimes(Values : TArray<integer>) : TAnimatorComponent;

      function SizeKeypoints(Values : TArray<single>) : TAnimatorComponent;
      function SizeKeypointsXZ(Values : TArray<single>) : TAnimatorComponent;
      function SizeKeypointsY(Values : TArray<single>) : TAnimatorComponent;
      function SizeTimes(Values : TArray<integer>) : TAnimatorComponent;

      function PlayAnimation(TimeKey : integer; const AnimationName : string; AnimationLength : integer) : TAnimatorComponent;

      function ActivateOnLose : TAnimatorComponent;
      function ActivateOnDie : TAnimatorComponent;
      function ActivateOnFire : TAnimatorComponent;
      function ActivateOnPreFire : TAnimatorComponent;

      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Offsets the height of flying entities. </summary>
  TPositionerOffsetComponent = class(TEntityComponent)
    protected
      FTargetGroup : SetComponentGroup;
      FOffset : RVector3;
      FTransitionTimer : TTimer;
      FOverrideY : boolean;
      function FinalOffset : RVector3;
    published
      [XEvent(eiDisplayPosition, epHigh, etRead)]
      /// <summary> Offsets the height for flying units. </summary>
      function OnDisplayPosition(PreviousPosition : RParam) : RParam;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function TargetGroup(Group : TArray<byte>) : TPositionerOffsetComponent;
      function Offset(X, Y, Z : single) : TPositionerOffsetComponent;
      function Transition(Time : integer) : TPositionerOffsetComponent;
      function OverrideY : TPositionerOffsetComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Let the entity fly from the sky to the position at creation. Uses eiCooldown for time of flight. </summary>
  TPositionerMeteorComponent = class(TEntityComponent)
    protected
      FTargetPosition, FStartPosition, FOffset : RVector3;
      FFlyTimer : TTimer;
      procedure Init(Offset : RVector3);
    published
      [XEvent(eiDisplayPosition, epLow, etRead)]
      /// <summary> Falling meteor. </summary>
      function OnDisplayPosition(PreviousPosition : RParam) : RParam;
      [XEvent(eiAfterCreate, epHigh, etTrigger)]
      /// <summary> Initializes this component. </summary>
      function OnAfterDeserialization() : boolean;
      [XEvent(eiFire, epHigher, etTrigger)]
      /// <summary> Repositions this unit. </summary>
      function OnFire(Targets : RParam) : boolean;
    public
      constructor Create(Owner : TEntity; Offset : RVector3); reintroduce;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; Offset : RVector3); reintroduce;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Rotates the entity around it's real position. </summary>
  TPositionerRotationComponent = class(TEntityComponent)
    protected
      FTargetGroup : SetComponentGroup;
      FRotationSpeed, FRotationOffset, FFactor : RVector3;
      FRadius, FPhase : single;
      FScaleEvent : EnumEventIdentifier;
      FScaleByEvent : boolean;
      FRotationTimer, FFadeIn : TTimer;
    published
      [XEvent(eiDisplayPosition, epLow, etRead)]
      function OnDisplayPosition(PreviousPosition : RParam) : RParam;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function TargetGroup(Group : TArray<byte>) : TPositionerRotationComponent;
      /// <summary> Will be added to the event radius if specified. </summary>
      function Radius(Radius : single) : TPositionerRotationComponent;
      function RadiusFromEvent(ScaleEvent : EnumEventIdentifier) : TPositionerRotationComponent;
      function RotationSpeed(RotationSpeedX, RotationSpeedY, RotationSpeedZ : single) : TPositionerRotationComponent;
      function RotationOffset(RotationOffsetX, RotationOffsetY, RotationOffsetZ : single) : TPositionerRotationComponent;
      function Phase(Phase : single) : TPositionerRotationComponent;
      function FadeIn(Time : integer) : TPositionerRotationComponent;
      function Factor(X, Y, Z : single) : TPositionerRotationComponent;
      destructor Destroy; override;
  end;

  {$RTTI INHERIT}

  /// <summary> Add to a linear movement a height according to a spline. </summary>
  TPositionerSplineComponent = class(TEntityComponent)
    protected
      FTarget : RTarget;
      FSub, FTargetSub : string;
      FTargetGroup : SetComponentGroup;
      FStart : RMatrix;     // virtual starting location
      FStartPos : RVector2; // real starting location
      FTangentStart, FTangentEnd, FLastEndPosition : RVector3;
      FLastFront, FStartOffset : RVector3;
      FMaxDistanceScaling, FRotationSpeed, FRotationAxisHorizontal, FRotationAxisVertical : single;
      FDebug, FOrientStartWithTarget : boolean;
      FTangentStartAfterReached, FTangentEndAfterReached : RVector3;
    published
      [XEvent(eiMoveTo, epLower, etTrigger)]
      /// <summary> Updates the spline regarding the new target. </summary>
      function OnMoveTo(Target, Range : RParam) : boolean;
      [XEvent(eiMoveTargetReached, epLast, etTrigger)]
      /// <summary> Updates the startpoint of the spline regarding the last target. </summary>
      function OnMoveTargetReached() : boolean;
      [XEvent(eiDisplayPosition, epMiddle, etRead)]
      /// <summary> Manipulate the worldposition to match the spline. </summary>
      function OnDisplayPosition(PreviousPosition : RParam) : RParam;
      [XEvent(eiDisplayFront, epMiddle, etRead)]
      /// <summary> Attaches the tangent of the spline. </summary>
      function OnDisplayFront(PreviousFront : RParam) : RParam;
      [XEvent(eiAfterCreate, epHigh, etTrigger)]
      /// <summary> Init the starting position. </summary>
      function OnAfterDeserialization() : boolean;
    public
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>); override;
      function RenderDebug() : TPositionerSplineComponent;
      /// <summary> Useful for turrets which don't rotate. </summary>
      function OrientStartWithTarget() : TPositionerSplineComponent;
      function BothTangents(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
      function StartTangent(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
      function StartTangentRandom(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
      function EndTangent(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
      function RotateTangent(const HorizontalRotation, VerticalRotation, RotationSpeed : single) : TPositionerSplineComponent;
      function MaxDistanceScaling(MaxDistanceScaling : single) : TPositionerSplineComponent;
      function BothTangentsAfterReached(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
      function BindToSubPosition(const Name : string; TargetGroup : TArray<byte>) : TPositionerSplineComponent;
      function BindToTargetSubPosition(const Name : string) : TPositionerSplineComponent;
      function StartOffset(OffsetX, OffsetY, OffsetZ : single) : TPositionerSplineComponent;
  end;

implementation

{ TAnimationComponent }

function TAnimationComponent.AbilityGroup(Group : TArray<byte>) : TAnimationComponent;
begin
  Result := self;
  FAbilityGroup := ByteArrayToComponentGroup(Group);
end;

function TAnimationComponent.AlternatingAttack : TAnimationComponent;
begin
  Result := self;
  FAlternatingAttack := True;
end;

constructor TAnimationComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FAnimationLength := TDictionary<EnumEventIdentifier, integer>.Create;
end;

destructor TAnimationComponent.Destroy;
begin
  FAnimationLength.Free;
  inherited;
end;

function TAnimationComponent.HasAntiAirAttack : TAnimationComponent;
begin
  Result := self;
  FHasAntiAirAttack := True;
end;

function TAnimationComponent.IsLink : TAnimationComponent;
begin
  Result := self;
  FIsLink := True;
end;

function TAnimationComponent.LoopFire : TAnimationComponent;
begin
  Result := self;
  FLoopFire := True;
end;

function TAnimationComponent.OnAfterCreate : boolean;
begin
  Result := True;
  Eventbus.Trigger(eiPlayAnimation, [ANIMATION_SPAWN, RParam.From<EnumAnimationPlayMode>(alSingle), 0], ComponentGroup);
end;

procedure TAnimationComponent.PlayAttack(Target : ATarget);
var
  attack : string;
  TargetEntity : TEntity;
begin
  if not FIsLink then
  begin
    if CurrentEvent.CalledToGroup * FAbilityGroup <> [] then
        Eventbus.Trigger(eiPlayAnimation, [ANIMATION_ABILITY_1, RParam.From<EnumAnimationPlayMode>(HGeneric.TertOp<EnumAnimationPlayMode>(FLoopFire, alLoop, alSingle)), 0], ComponentGroup)
    else
    begin
      attack := ANIMATION_ATTACK;
      if FAlternatingAttack then
      begin
        if FAlternateAttack then attack := ANIMATION_ATTACK2;
        FAlternateAttack := not FAlternateAttack;
      end;

      if FHasAntiAirAttack and
        (Target.Count > 0) and
        (Target.First.IsEntity) and
        Target.First.TryGetTargetEntity(TargetEntity) and
        ([upGround, upFlying] * Owner.UnitProperties <= TargetEntity.UnitProperties) then
      begin
        if attack = ANIMATION_ATTACK then attack := ANIMATION_ATTACK_AIR
        else if attack = ANIMATION_ATTACK2 then attack := ANIMATION_ATTACK_AIR2;
      end;

      if ((FSecondAttackGroup <> []) and (FSecondAttackGroup * CurrentEvent.CalledToGroup <> [])) or
        ((FSecondAttack <> []) and
        (Target.Count > 0) and
        (Target.First.IsEntity) and
        Target.First.TryGetTargetEntity(TargetEntity) and
        (TargetEntity.UnitProperties * FSecondAttack <> [])) then attack := ANIMATION_ATTACK2;

      Eventbus.Trigger(eiPlayAnimation, [attack, RParam.From<EnumAnimationPlayMode>(HGeneric.TertOp<EnumAnimationPlayMode>(FLoopFire, alLoop, alSingle)), 0], ComponentGroup);
    end;
  end;
end;

function TAnimationComponent.OnPreFire(Targets : RParam) : boolean;
begin
  Result := True;
  if Eventbus.Read(eiWelaActionpoint, [], CurrentEvent.CalledToGroup).AsInteger > 0 then
      PlayAttack(Targets.AsATarget);
end;

function TAnimationComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if Eventbus.Read(eiWelaActionpoint, [], CurrentEvent.CalledToGroup).AsInteger <= 0 then
      PlayAttack(Targets.AsATarget);
end;

function TAnimationComponent.OnLinkBreak(Dest : RParam) : boolean;
begin
  Result := True;
  if FIsLink then
  begin
    dec(FOpenLinkCount);
    if FOpenLinkCount <= 0 then
        Eventbus.Trigger(eiPlayAnimation, [ANIMATION_STAND, RParam.From<EnumAnimationPlayMode>(alSingle), 0], ComponentGroup);
  end;
end;

function TAnimationComponent.OnLinkEstablish(Source, Dest : RParam) : boolean;
begin
  Result := True;
  if FIsLink then
  begin
    inc(FOpenLinkCount);
    Eventbus.Trigger(eiPlayAnimation, [ANIMATION_ATTACK, RParam.From<EnumAnimationPlayMode>(HGeneric.TertOp<EnumAnimationPlayMode>(FLoopFire, alLoop, alSingle)), 0], ComponentGroup);
  end;
end;

function TAnimationComponent.OnMoveTo(Target, Range : RParam) : boolean;
var
  Length : integer;
begin
  Result := True;
  if not FAnimationLength.TryGetValue(eiMoveTo, Length) then Length := 0;
  Eventbus.Trigger(eiPlayAnimation, [ANIMATION_WALK, RParam.From<EnumAnimationPlayMode>(alLoop), Length], ComponentGroup);
end;

function TAnimationComponent.OnStand : boolean;
begin
  Result := True;
  if not FIsLink or not(upBuilding in Owner.UnitProperties) then
      Eventbus.Trigger(eiPlayAnimation, [ANIMATION_STAND, RParam.From<EnumAnimationPlayMode>(alSingle), 0], ComponentGroup);
end;

function TAnimationComponent.SecondAttackAgainst(Properties : TArray<byte>) : TAnimationComponent;
begin
  Result := self;
  FSecondAttack := ByteArrayToSetUnitProperies(Properties);
end;

function TAnimationComponent.SecondAttackGroup(Group : TArray<byte>) : TAnimationComponent;
begin
  Result := self;
  FSecondAttackGroup := ByteArrayToComponentGroup(Group);
end;

function TAnimationComponent.SetAnimationSpeed(identifier : EnumEventIdentifier; AnimationLength : integer) : TAnimationComponent;
begin
  Result := self;
  FAnimationLength.AddOrSetValue(identifier, AnimationLength);
end;

{ TOrienterMovementComponent }

function TOrienterMovementComponent.OnDisplayFront(const PreviousFront : RParam) : RParam;
begin
  Result := True;
  if not FFront.IsZeroVector and Eventbus.Read(eiIsMoving, []).AsBoolean then Result := FFront.X0Y
  else Result := PreviousFront;
end;

function TOrienterMovementComponent.OnMove(const Target : RParam) : boolean;
begin
  Result := True;
  FFront := Owner.Position.DirectionTo(Target.AsVector2);
end;

{ TOrienterFrontInverterComponent }

function TOrienterFrontInverterComponent.OnDisplayFront(const PreviousFront : RParam) : RParam;
begin
  if not PreviousFront.IsEmpty then Result := -PreviousFront.AsVector3
  else Result := PreviousFront;
end;

{ TOrienterSmoothRotateComponent }

function TOrienterSmoothRotateComponent.OnDisplayFront(const PreviousFront : RParam) : RParam;
var
  TargetFront, Cross : RVector3;
  angleToGo : single;
begin
  {$IFDEF MAPEDITOR}
  Exit(PreviousFront);
  {$ENDIF}
  // only smooth front changes if component is registed to at least one group for what the event is called for
  if IsLocalCall then
  begin
    if not FCurrentFront.IsZeroVector then
    begin
      TargetFront := PreviousFront.AsVector3;
      angleToGo := FCurrentFront.AngleBetween(TargetFront);
      if (angleToGo < FRotateSpeed * GameTimeManager.ZDiff) then FCurrentFront := TargetFront
      else
      begin
        Cross := TargetFront.Cross(FCurrentFront).Normalize;
        if Cross.IsZeroVector then Cross := RVector3.UNITY;
        FCurrentFront := FCurrentFront.RotateAxis(Cross, -FRotateSpeed * GameTimeManager.ZDiff);
      end;
    end
    else FCurrentFront := PreviousFront.AsVector3;
    Result := FCurrentFront;
  end
  else Result := PreviousFront;
end;

function TOrienterSmoothRotateComponent.SetAngleSpeed(Value : single) : TOrienterSmoothRotateComponent;
begin
  Result := self;
  FRotateSpeed := Value;
end;

{ TOrienterTargetComponent }

function TOrienterTargetComponent.FrontFromPivot : TOrienterTargetComponent;
begin
  Result := self;
  FFromPivot := True;
end;

function TOrienterTargetComponent.FrontGroup(const Group : TArray<byte>) : TOrienterTargetComponent;
begin
  Result := self;
  FFrontGroup := ByteArrayToComponentGroup(Group);
end;

function TOrienterTargetComponent.FrontWithY : TOrienterTargetComponent;
begin
  Result := self;
  FWithY := True;
end;

function TOrienterTargetComponent.KeepLastFront : TOrienterTargetComponent;
begin
  Result := self;
  FKeepLastFront := True;
end;

function TOrienterTargetComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  Game.EntityManager.FreeComponent(self);
end;

function TOrienterTargetComponent.OnDisplayFront(const Previous : RParam) : RParam;
var
  CurrentPos, TargetPos : RVector3;
  TargetEntity : TEntity;
begin
  if ((FFrontGroup = []) or (FFrontGroup * CurrentEvent.CalledToGroup <> [])) and
    not Eventbus.Read(eiIsMoving, []).AsBoolean and // or we are currently moving, this should not happen, but would look awkward
    not(FTarget.IsEntity and (FTarget.EntityID = Owner.ID)) then // or if we target our self, than we don't want to change anything
  begin
    if not FTarget.IsEmpty then
    begin
      if FFromPivot then
          CurrentPos := Owner.Eventbus.Read(eiSubPositionByString, [BIND_ZONE_PIVOT], ComponentGroup).AsType<RMatrix>.Translation
      else
          CurrentPos := Owner.DisplayPosition;
      if FTarget.TryGetTargetEntity(TargetEntity) then
          TargetPos := TargetEntity.Eventbus.Read(eiSubPositionByString, [BIND_ZONE_HIT_ZONE], [0, 1]).AsType<RMatrix>.Translation
      else
          TargetPos := FTarget.GetTargetPosition.X0Y;
      if TargetPos.IsZeroVector then
          CurrentPos := FLastFront
      else
          CurrentPos := CurrentPos.DirectionTo(TargetPos);
      if not FWithY then CurrentPos := CurrentPos.SetY(0);
      FLastFront := CurrentPos;
      Result := CurrentPos;
    end
    else
    begin
      if FKeepLastFront and not FLastFront.IsZeroVector then
          Result := FLastFront
      else
          Result := Previous
    end;
  end
  else Result := Previous;
end;

function TOrienterTargetComponent.OnTarget(const Target : RParam) : boolean;
begin
  Result := True;
  if (FTargetGroup = []) or (CurrentEvent.CalledToGroup * FTargetGroup <> []) then
      FTarget := Target.AsType<RTarget>;
end;

function TOrienterTargetComponent.TargetGroup(const Group : TArray<byte>) : TOrienterTargetComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TVertexQuadComponent }

function TVertexQuadComponent.Additive : TVertexQuadComponent;
begin
  Result := self;
  FVertexQuad.BlendMode := BlendAdditive;
end;

procedure TVertexQuadComponent.Apply;
begin
  inherited;
  if FIsScreenSpace then
  begin
    FVertexQuad.Left := RVector3.ZERO;
    FVertexQuad.Up := RVector3.ZERO;
  end
  else
  begin
    FVertexQuad.Left := FBindMatrix.Front;
    if FCameraOriented then FVertexQuad.Up := RVector3.ZERO
    else FVertexQuad.Up := FBindMatrix.Up;
  end;
  FVertexQuad.Position := FBindMatrix.Translation;
  FVertexQuad.Size := FQuadSize * FModelsize * FSize.X;
  if FIsUnitplaceholder then
      FVertexQuad.Position := FVertexQuad.Position + RVector3.Create(0, FVertexQuad.Height / 2, 0);
end;

function TVertexQuadComponent.CameraOriented : TVertexQuadComponent;
begin
  Result := self;
  FCameraOriented := True;
end;

function TVertexQuadComponent.Color(Color : cardinal) : TVertexQuadComponent;
begin
  Result := self;
  FVertexQuad.Color := Color;
end;

constructor TVertexQuadComponent.Create(Owner : TEntity; Texture : string; Width, Height : single);
begin
  CreateGrouped(Owner, [], Texture, Width, Height);
end;

constructor TVertexQuadComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Texture : string; Width, Height : single);
begin
  inherited CreateGrouped(Owner, Group);
  FVertexQuad := TVertexWorldspaceQuad.Create(VertexEngine);
  FVertexQuad.Texture := TTexture.CreateTextureFromFile(PATH_GRAPHICS + Texture, GFXD.Device3D, mhGenerate, True);
  FQuadSize := RVector2.Create(Width, Height);
  FVertexQuad.Size := FQuadSize;
end;

destructor TVertexQuadComponent.Destroy;
begin
  FVertexQuad.Texture.Free;
  FVertexQuad.Free;
  inherited;
end;

procedure TVertexQuadComponent.Idle;
begin
  inherited;
  FVertexQuad.AddRenderJob;
end;

function TVertexQuadComponent.IsDecal : TVertexQuadComponent;
begin
  Result := self;
  TVisualizerComponent(self).IsDecal;
  FVertexQuad.DrawOrder := -100;
end;

function TVertexQuadComponent.OnAfterCreate : boolean;
begin
  Result := True;
  Apply;
end;

function TVertexQuadComponent.OnBoundings(const Previous : RParam) : RParam;
begin
  if Previous.IsEmpty then
      Result := RParam.From<RSphere>(RSphere.CreateSphere(FVertexQuad.Position, FVertexQuad.Size.MaxAbsValue / 2))
  else
      Result := Previous;
end;

function TVertexQuadComponent.OnSubPositionByString(Name, PrevValue : RParam) : RParam;
var
  Position : RVector3;
begin
  if PrevValue.IsEmpty then
  begin
    Position := FVertexQuad.Position;
    if Position.Y < 0 then Position := Position * (RVector3.Create(1, -1, 1));
    Result := RParam.From<RMatrix>(RMatrix.CreateTranslation(Position));
  end;
end;

function TVertexQuadComponent.ScreenSpace : TVertexQuadComponent;
begin
  Result := self;
  FIsScreenSpace := True;
end;

function TVertexQuadComponent.SetUnitPlaceholder : TVertexQuadComponent;
begin
  Result := self;
  FIsUnitplaceholder := True;
end;

{ TPointLightComponent }

procedure TPointLightComponent.Apply;
begin
  inherited;
  FLight.Position := FBindMatrix.Translation;
  FLight.Enabled := IsVisible;
  if FColor.RGB.IsZeroVector then
      FLight.Color.RGB := GetTeamColor(Owner.TeamID).RGB;
end;

constructor TPointLightComponent.Create(Owner : TEntity; Color : cardinal; Radius : single);
begin
  CreateGrouped(Owner, TArray<byte>.Create(), Color, Radius);
end;

constructor TPointLightComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Color : cardinal; Radius : single);
begin
  inherited CreateGrouped(Owner, Group);
  FColor := RColor.Create(Color);
  FLight := TPointLight.Create(Color, RVector3.ZERO, RVector3.Create(Radius, 0, 0));
  GFXD.MainScene.Lights.Add(FLight);
  FLight.Enabled := False;
end;

destructor TPointLightComponent.Destroy;
begin
  GFXD.MainScene.Lights.Remove(FLight);
  inherited;
end;

function TPointLightComponent.Negate : TPointLightComponent;
begin
  Result := self;
  FLight.Color.a := -FLight.Color.a;
  FColor.a := -FColor.a;
end;

function TPointLightComponent.SetLightShape(Shape : RVector3) : TPointLightComponent;
begin
  Result := self;
  FLight.Range := Shape;
end;

{ TProductionPreviewComponent }

procedure TProductionPreviewComponent.ClearPreviews;
var
  i : integer;
begin
  for i := 0 to FPreviews.Count - 1 do FPreviews[i].DeferFree;
  FPreviews.Clear;
end;

procedure TProductionPreviewComponent.ComputePreviews;
var
  ent : TEntity;
  BuildUnit, SkinID : string;
  i : integer;
begin
  BuildUnit := Eventbus.Read(eiWelaUnitPattern, [], ComponentGroup).AsString;
  SkinID := Owner.GetSkinID(ComponentGroup);
  FUnitCount := Max(1, Eventbus.Read(eiWelaCount, [], ComponentGroup).AsInteger);
  if BuildUnit <> '' then
  begin
    ClearPreviews;
    for i := 0 to FUnitCount - 1 do
    begin
      ent := TEntity.CreateMetaFromScript(
        BuildUnit,
        GlobalEventbus,
        procedure(Entity : TEntity)
        begin
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLevel), Owner.CardLevel);
          Entity.Blackboard.SetIndexedValue(eiResourceBalance, [], ord(reCardLeague), Owner.CardLeague);
          Entity.SkinID := SkinID;
          Entity.Blackboard.SetValue(eiSkinIdentifier, [], SkinID);
        end);
      if FIsSpawner and ent.HasUnitProperty(upFlying) and not ent.HasUnitProperty(upGround) then
          TPositionerOffsetComponent.Create(ent).Offset(0, -FLYING_HEIGHT + SPAWNER_FLYING_HEIGHT, 0);
      TLogicToWorldComponent.Create(ent);
      ent.Eventbus.Trigger(eiStand, []);
      ent.Eventbus.Trigger(eiUnitPropertyChanged, [RParam.From<SetUnitProperty>([upFrozen]), False]);
      FPreviews.Add(ent);
    end;
    PositionPreviews;
  end
  else DeferFree;
end;

constructor TProductionPreviewComponent.Create(Owner : TEntity);
begin
  CreateGrouped(Owner, []);
end;

constructor TProductionPreviewComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FPreviews := TAdvancedList<TEntity>(TList<TEntity>.Create);
end;

destructor TProductionPreviewComponent.Destroy;
begin
  ClearPreviews;
  FPreviews.Free;
  inherited;
end;

procedure TProductionPreviewComponent.EnumerateComponents(Callback : ProcEnumerateEntityComponentCallback);
var
  i : integer;
begin
  inherited;
  for i := 0 to FPreviews.Count - 1 do
  begin
    FPreviews[i].Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(Callback)]);
  end;
end;

function TProductionPreviewComponent.IsSpawner : TProductionPreviewComponent;
begin
  Result := self;
  FIsSpawner := True;
end;

function TProductionPreviewComponent.OnAfterCreate : boolean;
begin
  Result := True;
  ComputePreviews;
end;

function TProductionPreviewComponent.OnBoundings : RParam;
begin
  Result := RPARAMEMPTY;
  if assigned(FPreviews) and not FPreviews.IsEmpty then
  begin
    Result := FPreviews.First.Eventbus.Read(eiBoundings, [], CurrentEvent.CalledToGroup);
    Result := RParam.From<RSphere>(RSphere.CreateSphere(Owner.DisplayPosition, Result.AsType<RSphere>.Radius));
  end;
end;

function TProductionPreviewComponent.OnColorAdjustment(ColorAdjustment, absH, absS, absV : RParam) : boolean;
begin
  Result := True;
  if assigned(FPreviews) then
      FPreviews.Each(
      procedure(const Item : TEntity)
      begin
        Item.Eventbus.Trigger(eiColorAdjustment, [ColorAdjustment.AsVector3.SetZ(0), absH, absS, False]);
      end);
end;

function TProductionPreviewComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  ClearPreviews;
end;

function TProductionPreviewComponent.OnDrawOutline(Color, OnlyOutline : RParam) : boolean;
begin
  Result := True;
  if assigned(FPreviews) then
      FPreviews.Each(
      procedure(const Item : TEntity)
      begin
        Item.Eventbus.Trigger(eiDrawOutline, [Color, OnlyOutline]);
      end);
end;

function TProductionPreviewComponent.OnGetUnitsAtCursor(ClickRay, Previous : RParam) : RParam;
var
  List : TList<RTuple<single, TEntity>>;
  i : integer;
begin
  if assigned(FPreviews) then
  begin
    List := Previous.AsType<TList<RTuple<single, TEntity>>>;
    if assigned(List) then
    begin
      for i := 0 to List.Count - 1 do
        if FPreviews.Contains(List[i].b) then List[i] := RTuple<single, TEntity>.Create(List[i].a, FOwner);
    end
    else Result := Previous;
  end
  else Result := Previous;
end;

function TProductionPreviewComponent.OnIdle : boolean;
begin
  Result := True;
  if (FUnitCount <> Max(1, Eventbus.Read(eiWelaCount, [], ComponentGroup).AsInteger)) then ComputePreviews
  else PositionPreviews;
end;

function TProductionPreviewComponent.OnSubPositionByString(Name, Previous : RParam) : RParam;
begin
  if assigned(FPreviews) and not FPreviews.IsEmpty then Result := FPreviews.First.Eventbus.Read(eiSubPositionByString, [name], CurrentEvent.CalledToGroup)
  else Result := Previous;
end;

procedure TProductionPreviewComponent.PositionPreviews;
var
  Position, Front, Up, PreviewPosition, Scale : RVector3;
  i : integer;
begin
  if assigned(FPreviews) then
  begin
    Position := Owner.DisplayPosition;
    Front := Owner.DisplayFront;
    Up := Owner.DisplayUp;
    Scale := Eventbus.Read(eiSize, []).AsVector3Default(RVector3.ONE);
    for i := 0 to FPreviews.Count - 1 do
    begin
      PreviewPosition := ComputeSpawningPattern(Position.XZ, Front.XZ, FIsSpawner, i, FPreviews.Count).X0Y(Position.Y);
      FPreviews[i].Position := PreviewPosition.XZ;
      FPreviews[i].Front := Front.XZ;
      FPreviews[i].Eventbus.Write(eiSize, [Scale]);
      FPreviews[i].Eventbus.Write(eiVisible, [Eventbus.Read(eiVisible, [])]);
    end;
  end;
end;

function TProductionPreviewComponent.OnModelSize(ModelSize : RParam) : boolean;
begin
  Result := True;
  if assigned(FPreviews) then
      FPreviews.Each(
      procedure(const Item : TEntity)
      begin
        Item.Eventbus.Write(eiModelSize, [ModelSize]);
      end);
end;

{ TOrienterAutoRotationComponent }

constructor TOrienterAutoRotationComponent.CreateGrouped(Entity : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Entity, Group);
  FStartTime := GameTimeManager.GetFloatingTimestamp;
end;

function TOrienterAutoRotationComponent.LastTime : single;
begin
  Result := GameTimeManager.GetFloatingTimestamp - FStartTime;
  if FLimit > 0 then Result := Min(FLimit, Result);
end;

function TOrienterAutoRotationComponent.OnFront(const Previous : RParam) : RParam;
begin
  if not IsLocalCall then Exit(Previous);
  if Previous.IsEmpty then Result := RVector3.UNITZ.RotatePitchYawRoll(FRotSpeed * LastTime + FRandomOffset)
  else Result := Previous.AsVector3.RotatePitchYawRoll(FRotSpeed * LastTime);
end;

function TOrienterAutoRotationComponent.OnUp(const Previous : RParam) : RParam;
begin
  if not IsLocalCall then Exit(Previous);
  if Previous.IsEmpty then Result := RVector3.UNITY.RotatePitchYawRoll(FRotSpeed * LastTime + FRandomOffset)
  else Result := Previous.AsVector3.RotatePitchYawRoll(FRotSpeed * LastTime);
end;

function TOrienterAutoRotationComponent.RandomOffset(X, Y, Z : single) : TOrienterAutoRotationComponent;
begin
  Result := self;
  FRandomOffset := RVector3.Create(X * random, Y * random, Z * random);
end;

function TOrienterAutoRotationComponent.SetSpeed(RotationSpeed : RVector3) : TOrienterAutoRotationComponent;
begin
  Result := self;
  FRotSpeed := RotationSpeed;
end;

function TOrienterAutoRotationComponent.SpeedJitter(X, Y, Z : single) : TOrienterAutoRotationComponent;
begin
  Result := self;
  FRotSpeed := RVector3.Create(X * 2 * (random - 0.5), Y * 2 * (random - 0.5), Z * 2 * (random - 0.5)) + FRotSpeed;
end;

function TOrienterAutoRotationComponent.StopAt(Limit : single) : TOrienterAutoRotationComponent;
begin
  Result := self;
  FLimit := Limit;
end;

{ TLinkBulletVisualizerComponent }

function TLinkBulletVisualizerComponent.Color(const Color : cardinal) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FColor := Color;
end;

constructor TLinkBulletVisualizerComponent.Create(Owner : TEntity; Texture : string);
begin
  CreateGrouped(Owner, [], Texture);
end;

constructor TLinkBulletVisualizerComponent.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>; Texture : string);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FBullets := TList<RBullet>.Create;
  FTexture := TTexture.CreateTextureFromFile(PATH_GRAPHICS + Texture, GFXD.Device3D, mhGenerate, True);
  FBulletTimer := TTimer.CreateAndStart(100);
  FWidth := RVariedSingle.Create(0.5);
  FHeight := RVariedSingle.Create(0.5);
  FSpeed := RVariedSingle.Create(20);
  FColor := RColor.CWHITE;
end;

destructor TLinkBulletVisualizerComponent.Destroy;
var
  i : integer;
begin
  for i := 0 to FBullets.Count - 1 do
      FBullets[i].Bullet.Free;
  FBullets.Free;
  FBulletTimer.Free;
  FTexture.Free;
  FImpactParticleEffect.Free;
  inherited;
end;

function TLinkBulletVisualizerComponent.ImpactParticleEffect(const FilePath : string) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FImpactParticleEffect := ParticleEffectEngine.CreateParticleEffectFromFile(AbsolutePath(PATH_GRAPHICS_PARTICLE_EFFECTS + FilePath), True);
end;

function TLinkBulletVisualizerComponent.ImpactSize(const Size : single) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  if assigned(FImpactParticleEffect) then
      FImpactParticleEffect.Size := Size;
end;

function TLinkBulletVisualizerComponent.OnIdle : boolean;
var
  CurrentTime : int64;
  s, dist : single;
  StartPosVec, EndPosVec, FinalEndPos : RVector3;
  IsGroundTarget : boolean;
  ent : TEntity;
  Targets : ATarget;
  i : integer;
begin
  Result := True;
  CurrentTime := GameTimeManager.GetTimestamp;
  // spawn
  // safety
  if FBulletTimer.ZeitDiffProzent > 20 then FBulletTimer.SetZeitDiffProzent(20);
  while FBulletTimer.Expired do
  begin
    SpawnBullet(CurrentTime + round((FBulletTimer.ZeitDiffProzent - 1) * FBulletTimer.Interval));
    FBulletTimer.StartWithRest;
    FBulletTimer.Interval := round(FSpawnTime.random);
  end;
  // compute
  if EndPos.IsEmpty then
  begin
    Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
    if not Targets.HasIndex(0) then
        MakeException('OnIdle: No target found!');
    EndPos := Targets[0];
  end;

  StartPosVec := Eventbus.Read(eiDisplayPosition, [], ComponentGroup).AsVector3;
  // prevent ray from rendered wrong, need to fix it right
  if StartPosVec.X0Z.IsZeroVector then Exit;

  IsGroundTarget := True;
  if EndPos.TryGetTargetEntity(ent) then
  begin
    EndPosVec := ent.Eventbus.Read(eiSubPositionByString, [BIND_ZONE_HIT_ZONE], [0, 1]).AsType<RMatrix>.Translation;
    if FToGround then
        IsGroundTarget := ent.HasUnitProperty(upGround);
  end
  else EndPosVec := EndPos.GetTargetPosition.X0Y;

  if EndPosVec.X0Z.IsZeroVector then Exit;

  if FToGround and IsGroundTarget then
      EndPosVec.Y := 0;

  for i := FBullets.Count - 1 downto 0 do
  begin
    FinalEndPos := EndPosVec + FBullets[i].Offset;
    dist := StartPosVec.Distance(FinalEndPos);
    if dist = 0 then s := 1
    else s := HMath.Saturate((CurrentTime - FBullets[i].StartTime) / 1000 * FBullets[i].Speed / dist);
    if s >= 1 then
    begin
      if assigned(FImpactParticleEffect) and (not FToGround or IsGroundTarget) then
      begin
        FImpactParticleEffect.Position := FinalEndPos;
        FImpactParticleEffect.StartEmission;
      end;
      FBullets[i].Bullet.Free;
      FBullets.Delete(i);
      continue;
    end;
    FBullets[i].Bullet.Position := (StartPosVec).Lerp(FinalEndPos, s);
    FBullets[i].Bullet.Up := (FinalEndPos - StartPosVec).Normalize;
    FBullets[i].Bullet.Left := RVector3.ZERO;
    FBullets[i].Bullet.AddRenderJob;
  end;
end;

function TLinkBulletVisualizerComponent.SetBulletSpawnCooldown(Cooldown : RVariedSingle) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FSpawnTime := Cooldown;
  FBulletTimer.SetIntervalAndStart(round(FSpawnTime.random));
end;

function TLinkBulletVisualizerComponent.SetEndposJitter(EndposJitter : single) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FEndposJitter := RVariedVector3.CreateRadialVaried(RVector3.ZERO, EndposJitter);
end;

function TLinkBulletVisualizerComponent.SetLength(Length : RVariedSingle) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FHeight := Length;
end;

function TLinkBulletVisualizerComponent.SetSpeed(Speed : RVariedSingle) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FSpeed := Speed;
end;

function TLinkBulletVisualizerComponent.SetWidth(Width : RVariedSingle) : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FWidth := Width;
end;

procedure TLinkBulletVisualizerComponent.SpawnBullet(StartTime : int64);
var
  Bullet : RBullet;
begin
  Bullet.Bullet := TVertexWorldspaceQuad.Create(VertexEngine);
  Bullet.Bullet.Texture := FTexture;
  Bullet.Bullet.Width := FWidth.random;
  Bullet.Bullet.Height := FHeight.random;
  Bullet.StartTime := StartTime;
  Bullet.Speed := FSpeed.random;
  Bullet.Offset := FEndposJitter.getRandomVector;
  Bullet.Bullet.BlendMode := BlendAdditive;
  Bullet.Bullet.Color := FColor;
  FBullets.Add(Bullet);
end;

function TLinkBulletVisualizerComponent.ToGround : TLinkBulletVisualizerComponent;
begin
  Result := self;
  FToGround := True;
end;

{ TVisualizerComponent }

procedure TVisualizerComponent.Apply;
var
  mat : RParam;
begin
  if IsBoundToBone then
  begin
    mat := Eventbus.Read(eiSubPositionByString, [FBoundZone], FBindGroup);
    if not mat.IsEmpty then
        FBindMatrix := mat.AsType<RMatrix>
    else
    begin
      FBindMatrix := RMatrix.IDENTITY;
      if FIsPiece then
          FBindMatrix.Translation := Eventbus.ReadHierarchic(eiDisplayPosition, [], ComponentGroup).AsVector3
      else
          FBindMatrix.Translation := Owner.DisplayPosition;
    end;
    if FFixedOrientation then
    begin
      FBindMatrix.Front := FFixedFront;
      FBindMatrix.Up := FFixedUp;
      FBindMatrix.Left := FFixedFront.Cross(FFixedUp).Normalize;
    end
    else if FIsPiece then
    begin
      FBindMatrix.Front := Eventbus.ReadHierarchic(eiDisplayFront, [], ComponentGroup).AsVector3Default(FDefaultFront);
      FBindMatrix.Up := Eventbus.ReadHierarchic(eiDisplayUp, [], ComponentGroup).AsVector3Default(FDefaultUp);
    end;
  end
  else
  begin
    FBindMatrix := RMatrix.IDENTITY;
    if FIsPiece then
        FBindMatrix.Translation := Eventbus.ReadHierarchic(eiDisplayPosition, [], ComponentGroup).AsVector3
    else
        FBindMatrix.Translation := Owner.DisplayPosition;
    if FFixedOrientation then
    begin
      FBindMatrix.Front := FFixedFront;
      FBindMatrix.Up := FFixedUp;
    end
    else
    begin
      if FIsPiece then
          FBindMatrix.Front := Eventbus.ReadHierarchic(eiDisplayFront, [], ComponentGroup).AsVector3Default(FDefaultFront)
      else
          FBindMatrix.Front := Owner.DisplayFront;
      if FIsPiece then
          FBindMatrix.Up := Eventbus.ReadHierarchic(eiDisplayUp, [], ComponentGroup).AsVector3Default(FDefaultUp)
      else
          FBindMatrix.Up := Owner.DisplayUp;
    end;
    FBindMatrix.Left := FBindMatrix.Front.Cross(FBindMatrix.Up).Normalize;
  end;
  FBindMatrix := FBindMatrixAdjustments.Apply(FBindMatrix);

  FBindMatrix := FBindMatrix * RMatrix.CreateRotationPitchYawRoll(FRotationOffset) * RMatrix.CreateTranslation(FinalModelOffset);

  if FHasFixedHeight then
      FBindMatrix._42 := FFixedHeight;

  if FBindDebug then LinePool.AddCoordinateSystem(FBindMatrix);
end;

function TVisualizerComponent.BindToSubPosition(const ZoneName : string) : TVisualizerComponent;
begin
  FBoundZone := ZoneName;
  Result := self;
  FBindGroup := ComponentGroup;
end;

function TVisualizerComponent.BindToSubPositionGroup(const ZoneName : string; TargetGroup : TArray<byte>) : TVisualizerComponent;
begin
  Result := self;
  FBoundZone := ZoneName;
  FBindGroup := ByteArrayToComponentGroup(TargetGroup);
end;

constructor TVisualizerComponent.Create(Owner : TEntity);
begin
  CreateGrouped(Owner, TArray<byte>.Create());
end;

constructor TVisualizerComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FBindMatrix := RMatrix.IDENTITY;
  FSize := RVector3.ONE;
  FModelsize := Eventbus.Read(eiModelSize, [], ComponentGroup).AsSingleDefault(1.0);
  FMaxScaleEvent := 1000.0;
  FDefaultFront := -RVector3.UNITX;
  FDefaultUp := RVector3.UNITY;
  FFixedTeamID := -1;
end;

function TVisualizerComponent.DebugBindMatrix : TVisualizerComponent;
begin
  Result := self;
  FBindDebug := True;
end;

function TVisualizerComponent.DefaultOrientation(FrontX, FrontY, FrontZ : single) : TVisualizerComponent;
begin
  Result := self;
  FDefaultFront := RVector3.Create(FrontX, FrontY, FrontZ);
end;

function TVisualizerComponent.DefaultOrientationUp(UpX, UpY, UpZ : single) : TVisualizerComponent;
begin
  Result := self;
  FDefaultUp := RVector3.Create(UpX, UpY, UpZ);
end;

function TVisualizerComponent.FinalModelOffset : RVector3;
begin
  Result := FOffset * FModelsize * FSize + FFixedOffset;
end;

function TVisualizerComponent.FinalSize : RVector3;
var
  EventSize : single;
begin
  if FScaleWithEvent then
  begin
    if FScaleEvent = eiCollisionRadius then
        EventSize := Owner.CollisionRadius
    else
        EventSize := Eventbus.ReadHierarchic(FScaleEvent, [], ComponentGroup).AsSingle;
  end
  else EventSize := 1.0;
  Result := RVector3.Create(Max(FMinScaleEvent, Min(FMaxScaleEvent, EventSize)));
  if FScaleWithResource <> reNone then
      Result := Result * HMath.LinLerpF(FResourceScaleFactorMin, FResourceScaleFactorMax, ResourcePercentage(
      FScaleWithResource,
      Owner.Balance(FScaleWithResource, ComponentGroup),
      ResourceOverride(FScaleWithResource, Owner.Cap(FScaleWithResource, ComponentGroup), FOveriddenResourceCap)));
  if not FScaleWithEvent or not(FScaleEvent in GAMEPLAY_SCALE_EVENTS) then
  begin
    if not FIgnoreModelSize then Result := Result * FModelsize;
    if not FIgnoreSize then Result := Result * FSize;
  end;
end;

function TVisualizerComponent.FixedHeight(Height : single) : TVisualizerComponent;
begin
  Result := self;
  FHasFixedHeight := True;
  FFixedHeight := Height;
end;

function TVisualizerComponent.FixedHeightGround : TVisualizerComponent;
begin
  Result := self;
  FHasFixedHeight := True;
  FFixedHeight := GROUND_EPSILON;
end;

function TVisualizerComponent.FixedOffsetGround : TVisualizerComponent;
begin
  Result := self;
  FFixedOffset.Y := GROUND_EPSILON;
end;

function TVisualizerComponent.FixedOrientation(FrontX, FrontY, FrontZ : single) : TVisualizerComponent;
begin
  Result := self;
  FFixedOrientation := True;
  FFixedFront := RVector3.Create(FrontX, FrontY, FrontZ).Normalize;
  FFixedUp := RVector3.UNITY;
end;

function TVisualizerComponent.FixedOrientationAngle(FrontX, FrontY, FrontZ : single) : TVisualizerComponent;
begin
  Result := self;
  FFixedOrientation := True;
  FFixedFront := RVector3.UNITZ.RotatePitchYawRoll(FrontX, FrontY, FrontZ);
  FFixedUp := RVector3.UNITY.RotatePitchYawRoll(FrontX, FrontY, FrontZ);
end;

function TVisualizerComponent.FixedOrientationDefault : TVisualizerComponent;
begin
  Result := self;
  FFixedOrientation := True;
  FFixedFront := RVector3.UNITZ;
  FFixedUp := RVector3.UNITY;
end;

function TVisualizerComponent.FixedOrientationUp(UpX, UpY, UpZ : single) : TVisualizerComponent;
begin
  Result := self;
  FFixedOrientation := True;
  FFixedUp := RVector3.Create(UpX, UpY, UpZ).Normalize;
end;

procedure TVisualizerComponent.Idle;
begin
  if not FIsStatic or not FFirstStaticApplyDone then
  begin
    Update;
    Apply;
    FFirstStaticApplyDone := True;
  end;
end;

function TVisualizerComponent.IgnoreModelSize : TVisualizerComponent;
begin
  Result := self;
  FIgnoreModelSize := True;
end;

function TVisualizerComponent.IgnoreSize : TVisualizerComponent;
begin
  Result := self;
  FIgnoreSize := True;
end;

function TVisualizerComponent.InvertXBindMatrix : TVisualizerComponent;
begin
  Result := self;
  FBindMatrixAdjustments.BindInvertX := True;
end;

function TVisualizerComponent.InvertYBindMatrix : TVisualizerComponent;
begin
  Result := self;
  FBindMatrixAdjustments.BindInvertY := True;
end;

function TVisualizerComponent.InvertZBindMatrix : TVisualizerComponent;
begin
  Result := self;
  FBindMatrixAdjustments.BindInvertZ := True;
end;

function TVisualizerComponent.IsBoundToBone : boolean;
begin
  Result := FBoundZone <> '';
end;

function TVisualizerComponent.IsDecal : TVisualizerComponent;
begin
  Result := self;
  SetModelOffset(RVector3.UNITY * GROUND_EPSILON);
end;

function TVisualizerComponent.IsPiece : TVisualizerComponent;
begin
  Result := self;
  FIsPiece := True;
end;

function TVisualizerComponent.IsVisible : boolean;
begin
  Result := Eventbus.ReadHierarchic(eiVisible, [], ComponentGroup).AsBooleanDefaultTrue and
    not Eventbus.Read(eiExiled, []).AsBoolean;
  if FVisibleWithWelaReady then
      Result := Result and Eventbus.Read(eiIsReady, [], FWelaReadyGroup).AsBooleanDefaultTrue;
  if FVisibleWithResource <> reNone then
      Result := Result and (Owner.Balance(FVisibleWithResource, ComponentGroup).AsInteger = Owner.Cap(FVisibleWithResource, ComponentGroup).AsInteger);
  if FVisibleWithOption then
      Result := Result and Settings.GetBooleanOption(FVisibilityOption);
  if FVisibleWithUnitPropertyMustHave <> [] then
      Result := Result and (FVisibleWithUnitPropertyMustHave <= Owner.UnitProperties);
  if FVisibleWithUnitPropertyMustNotHave <> [] then
      Result := Result and (FVisibleWithUnitPropertyMustNotHave * Owner.UnitProperties = []);
end;

function TVisualizerComponent.MaxScale(Maximum : single) : TVisualizerComponent;
begin
  Result := self;
  FMaxScaleEvent := Maximum;
end;

function TVisualizerComponent.OnIdle : boolean;
begin
  Result := True;
  Idle;
end;

function TVisualizerComponent.OnModelSize(Size : RParam) : boolean;
begin
  Result := True;
  SetModelSize(Size.AsSingle);
end;

function TVisualizerComponent.OverrideResourceCap(NewCap : single) : TVisualizerComponent;
begin
  Result := self;
  FOveriddenResourceCap := NewCap;
end;

function TVisualizerComponent.ScaleRange(Minimum, Maximum : single) : TVisualizerComponent;
begin
  Result := self;
  FMinScaleEvent := Minimum;
  FMaxScaleEvent := Maximum;
end;

function TVisualizerComponent.ScaleWith(Event : EnumEventIdentifier) : TVisualizerComponent;
begin
  Result := self;
  FScaleEvent := Event;
  FScaleWithEvent := True;
end;

function TVisualizerComponent.ScaleWithResource(Resource : EnumResource; ScaleFactorMin, ScaleFactorMax : single) : TVisualizerComponent;
begin
  Result := self;
  FScaleWithResource := Resource;
  FResourceScaleFactorMin := ScaleFactorMin;
  FResourceScaleFactorMax := ScaleFactorMax;
end;

function TVisualizerComponent.SetModelOffset(OffsetX, OffsetY, OffsetZ : single) : TVisualizerComponent;
begin
  Result := self;
  FOffset := RVector3.Create(OffsetX, OffsetY, OffsetZ);
end;

function TVisualizerComponent.SetModelOffset(Offset : RVector3) : TVisualizerComponent;
begin
  Result := self;
  FOffset := Offset;
end;

function TVisualizerComponent.SetModelRotationOffset(Offset : RVector3) : TVisualizerComponent;
begin
  Result := self;
  FRotationOffset := Offset;
end;

procedure TVisualizerComponent.SetModelSize(ModelSize : single);
begin
  if ModelSize > 0 then
      FModelsize := ModelSize;
end;

function TVisualizerComponent.ShowAsTeam(FixTeamID : integer) : TVisualizerComponent;
begin
  Result := self;
  FFixedTeamID := FixTeamID;
end;

function TVisualizerComponent.SwapXYBindMatrix : TVisualizerComponent;
begin
  Result := self;
  FBindMatrixAdjustments.BindSwapXY := True;
end;

function TVisualizerComponent.SwapXZBindMatrix : TVisualizerComponent;
begin
  Result := self;
  FBindMatrixAdjustments.BindSwapXZ := True;
end;

function TVisualizerComponent.SwapYZBindMatrix : TVisualizerComponent;
begin
  Result := self;
  FBindMatrixAdjustments.BindSwapYZ := True;
end;

procedure TVisualizerComponent.Update;
begin
  FSize := Eventbus.Read(eiSize, [], []).AsVector3Default(RVector3.ONE) * Eventbus.Read(eiSize, [], ComponentGroup).AsVector3Default(RVector3.ONE);
end;

function TVisualizerComponent.VisibleWithOption(Option : EnumClientOption) : TVisualizerComponent;
begin
  Result := self;
  FVisibilityOption := Option;
  FVisibleWithOption := True;
end;

function TVisualizerComponent.VisibleWithResource(ResourceID : integer) : TVisualizerComponent;
begin
  Result := self;
  FVisibleWithResource := EnumResource(ResourceID);
end;

function TVisualizerComponent.VisibleWithUnitPropertyMustHave(Properties : TArray<byte>) : TVisualizerComponent;
begin
  Result := self;
  FVisibleWithUnitPropertyMustHave := ByteArrayToSetUnitProperies(Properties);
end;

function TVisualizerComponent.VisibleWithUnitPropertyMustNotHave(Properties : TArray<byte>) : TVisualizerComponent;
begin
  Result := self;
  FVisibleWithUnitPropertyMustNotHave := ByteArrayToSetUnitProperies(Properties);
end;

function TVisualizerComponent.VisibleWithWelaReady : TVisualizerComponent;
begin
  Result := self;
  FVisibleWithWelaReady := True;
  FWelaReadyGroup := ComponentGroup;
end;

function TVisualizerComponent.VisibleWithWelaReadyGrouped(Group : TArray<byte>) : TVisualizerComponent;
begin
  Result := self;
  FVisibleWithWelaReady := True;
  FWelaReadyGroup := ByteArrayToComponentGroup(Group);
end;

{ TMeshComponent }

procedure TMeshComponent.AddMeshEffect(const MeshEffect : TMeshEffect);
var
  i : integer;
  isSamePresent : boolean;
begin
  if not assigned(FMesh) then
  begin
    if not MeshEffect.Managed then MeshEffect.Free;
    Exit;
  end;

  MeshEffect.FOwningComponent := self;

  // and enable new effect
  // stacked effects has to be ensured to be unique to prevent naming conflicts
  if MeshEffect.NeedOwnPass = [] then
  begin
    isSamePresent := False;
    for i := 0 to FEffectStack.Count - 1 do
        isSamePresent := isSamePresent or (FEffectStack[i].ClassType = MeshEffect.ClassType);
    if not isSamePresent then
        MeshEffect.InitializeOnMesh(FMesh);
  end
  else
    // own passes can be activated directly
      MeshEffect.InitializeOnMesh(FMesh);

  FEffectStack.Add(MeshEffect);
end;

procedure TMeshComponent.RemoveMeshEffect(const MeshEffect : TMeshEffect);
var
  i : integer;
  isSameActive : boolean;
begin
  // if mesh ist already killed, only remove effect and don't try to deregister it
  if not assigned(FMesh) then
  begin
    if MeshEffect.Managed then FEffectStack.Extract(MeshEffect)
    else FEffectStack.Remove(MeshEffect);
    Exit;
  end;

  MeshEffect.FinalizeOnMesh;
  MeshEffect.FOwningComponent := nil;
  FEffectStack.Extract(MeshEffect);

  // activate another Mesheffect of the same type as they are cancelling each other out
  if MeshEffect.NeedOwnPass = [] then
  begin
    isSameActive := False;
    for i := 0 to FEffectStack.Count - 1 do
        isSameActive := isSameActive or ((FEffectStack[i].ClassType = MeshEffect.ClassType) and (FEffectStack[i].IsMounted));
    if not isSameActive then
    begin
      for i := 0 to FEffectStack.Count - 1 do
        if FEffectStack[i].ClassType = MeshEffect.ClassType then
        begin
          FEffectStack[i].InitializeOnMesh(FMesh);
          break;
        end;
    end;
  end;

  if not MeshEffect.Managed then MeshEffect.Free;
end;

procedure TMeshComponent.PopEffect;
begin
  if FEffectStack.IsEmpty then Exit;
  RemoveMeshEffect(FEffectStack.Last);
end;

function TMeshComponent.AlternatingZone(const ZoneName : string; ZoneCount : integer) : TMeshComponent;
begin
  Result := self;
  FAlternatingZones.AddOrSetValue(ZoneName.ToLowerInvariant, ZoneCount);
end;

procedure TMeshComponent.Apply;
begin
  inherited;
  if assigned(FMesh) then
  begin
    FMesh.ScaleImbalanced := FinalSize;
    FMesh.Position := FBindMatrix.Translation;
    FMesh.Front := FBindMatrix.Front;
    FMesh.Up := FBindMatrix.Up;
  end;
end;

function TMeshComponent.ApplyAutoSizeNormalization : TMeshComponent;
begin
  Result := self;
  if assigned(FMesh) then
      FSizeNormalization := 1 / (FMesh.GetUntransformedBoundingBox.HalfExtents.XZ.MaxAbsValue * 2);
end;

function TMeshComponent.CastsNoShadows : TMeshComponent;
begin
  Result := self;
  FCastsNoShadows := True;
end;

procedure TMeshComponent.CheckConditionalTextures;
var
  i : integer;
begin
  if assigned(FMesh) then
  begin
    FMesh.DiffuseTetxure := FOriginalTextures[mtDiffuse];
    FMesh.NormalTexture := FOriginalTextures[mtNormal];
    FMesh.SpecularTexture := FOriginalTextures[mtMaterial];
    FMesh.GlowTexture := FOriginalTextures[mtGlow];
    for i := 0 to FConditionalTextures.Count - 1 do
      if FConditionalTextures[i].Check(self) then
      begin
        case FConditionalTextures[i].TextureType of
          mtDiffuse : FMesh.DiffuseTetxure := FConditionalTextures[i].TextureFilename;
          mtNormal : FMesh.NormalTexture := FConditionalTextures[i].TextureFilename;
          mtMaterial : FMesh.SpecularTexture := FConditionalTextures[i].TextureFilename;
          mtGlow : FMesh.GlowTexture := FConditionalTextures[i].TextureFilename;
        end;
      end;
  end;
  FConditionalTexturesDirty := False;
end;

procedure TMeshComponent.ConditionalTexturesDirty;
begin
  FConditionalTexturesDirty := True;
end;

constructor TMeshComponent.Create(Owner : TEntity; Meshpath : string);
begin
  inherited Create(Owner);
  Create(Meshpath);
end;

constructor TMeshComponent.Create(Meshpath : string);
begin
  FAlternatingZones := TDictionary<string, integer>.Create;
  FConditionalTextures := TObjectList<TConditionalMeshTexture>.Create;
  FBoneAdjustments := TDictionary<string, RMatrixAdjustments>.Create;
  FZoneToBoneBinding := TDictionary<string, string>.Create;
  FFollowingDefaultAnimation := TDictionary<string, string>.Create;
  FAnimationSpeed := TDictionary<string, single>.Create;
  FEffectStack := TAdvancedObjectList<TMeshEffect>(TObjectList<TMeshEffect>.Create);
  FModelFileName := Meshpath;
  LoadMesh;
end;

constructor TMeshComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Meshpath : string);
begin
  inherited CreateGrouped(Owner, Group);
  Create(Meshpath);
end;

function TMeshComponent.CreateNewAnimationFrom(SourceAnimation, NewAnimationName : string; Startframe, Endframe : integer) : TMeshComponent;
begin
  Result := self;
  assert(assigned(FMesh));
  if assigned(FMesh.AnimationDriverMorph) then
      FMesh.AnimationDriverMorph.CreateNewAnimation(NewAnimationName, SourceAnimation, Startframe, Endframe);
  if assigned(FMesh.AnimationDriverBone) then
  begin
    FMesh.AnimationDriverBone.CreateNewAnimation(NewAnimationName, SourceAnimation, Startframe, Endframe);
    if (NewAnimationName = ANIMATION_STAND) and (FMesh.AnimationController.DefaultAnimation = '') and FMesh.AnimationController.HasAnimation(ANIMATION_STAND) then
        FMesh.AnimationController.DefaultAnimation := ANIMATION_STAND;
  end;
end;

function TMeshComponent.CreateNewAnimationFromFile(const AnimationFile, AnimationName : string) : TMeshComponent;
begin
  Result := self;
  assert(assigned(FMesh));
  if assigned(FMesh.AnimationDriverBone) then
      FMesh.AnimationDriverBone.ImportAnimationFromFile(AbsolutePath(PATH_GRAPHICS + AnimationFile), AnimationName);
  // import from external file only for bones implemented
  // if assigned(FMesh.AnimationDriverMorph) then
  // FMesh.AnimationDriverMorph.ImportAnimationFromFile(AbsolutePath(PATH_GRAPHICS + AnimationFile), AnimationName);
end;

function TMeshComponent.CreateNewAnimation(AnimationName : string; Startframe, Endframe : integer) : TMeshComponent;
begin
  Result := CreateNewAnimationFrom(FBX_DEFAULT_ANIMATIONTRACK, AnimationName, Startframe, Endframe);
end;

function TMeshComponent.DeathColorIdentityOverride(ColorIdentity : EnumEntityColor) : TMeshComponent;
begin
  Result := self;
  FDeathColorIdentityOverrideActive := True;
  FDeathColorIdentityOverride := ColorIdentity;
end;

destructor TMeshComponent.Destroy;
var
  i : integer;
begin
  FAlternatingZones.Free;
  FFollowingDefaultAnimation.Free;
  FConditionalTextures.Free;
  FBoneAdjustments.Free;
  FZoneToBoneBinding.Free;
  FAnimationSpeed.Free;
  for i := FEffectStack.Count - 1 downto 0 do
    if FEffectStack[i].Managed then FEffectStack.Extract(FEffectStack[i]);
  FEffectStack.Free;
  if not FDecaying then FreeAndNil(FMesh);
  inherited;
end;

function TMeshComponent.IsDecal : TMeshComponent;
begin
  Result := self;
  TVisualizerComponent(self).IsDecal;
  SetModelOffset(RVector3.UNITY * (GROUND_EPSILON / 10));
end;

function TMeshComponent.IsEffectMesh : TMeshComponent;
begin
  Result := self;
  FIsEffectMesh := True;
end;

function TMeshComponent.FinalSize : RVector3;
begin
  Result := FSizeNormalization * inherited;
end;

function TMeshComponent.GetBoneAdjustments(const BoneName : string) : RMatrixAdjustments;
begin
  if not TryGetBoneAdjustments(BoneName, Result) then
      Result := default (RMatrixAdjustments);
end;

function TMeshComponent.HasAttackLoop : TMeshComponent;
begin
  Result := self;
  FHasAttackLoop := True;
end;

procedure TMeshComponent.Idle;
const
  BORDER_TEAMCOLORS : array [0 .. 5] of cardinal = (
    ($FF404040), // NPC is grey
  ($FF0036FF),   // first team blue
  ($FFFF1818),   // second team red
  ($FF9600FF),   // third team purple
  ($FF00FF00),   // fourth team green
  ($FFFF0000)    // ai team is red for PvE Maps atm
    );
var
  TeamID, i : integer;
begin
  inherited;
  if assigned(FMesh) then
  begin
    if FConditionalTexturesDirty then
        CheckConditionalTextures;

    FMesh.Outline := FHighlightedThisFrame;
    if FOutlineColor.IsFullTransparent then
    begin
      TeamID := HMath.Clamp(Owner.TeamID, 0, Length(BORDER_TEAMCOLORS) - 1);
      FMesh.OutlineColor := BORDER_TEAMCOLORS[TeamID];
    end
    else FMesh.OutlineColor := FOutlineColor;
    FMesh.OnlyOutline := FHighlightedThisFrame and FOnlyOutline;
    FHighlightedThisFrame := False;

    if not FColorHasBeenAdjusted then
    begin
      FMesh.AbsoluteColorAdjustmentH := False;
      FMesh.AbsoluteColorAdjustmentS := False;
      FMesh.AbsoluteColorAdjustmentV := False;
      FMesh.ColorAdjustment := RVector3.ZERO;
      FMesh.AbsoluteHSV := RVector3.ZERO;
    end;

    FMesh.Visible := IsVisible;
    FMesh.CastsNoShadow := FCastsNoShadows;
    if assigned(ClientMap) and FShadingReductionFromTerrain then
        FMesh.ShadingReduction := ClientMap.Terrain.ShadingReduction;
    for i := FEffectStack.Count - 1 downto 0 do
      if FEffectStack[i].Expired then
          RemoveMeshEffect(FEffectStack[i]);
  end;
end;

function TMeshComponent.IgnoreScalingForAnimations : TMeshComponent;
begin
  Result := self;
  FIgnoreScalingForAnimations := True;
end;

procedure TMeshComponent.LoadMesh;
var
  Meshpath : string;
begin
  Meshpath := FModelFileName.Replace('/', '\').Replace('\\', '\');
  Meshpath := AbsolutePath(PATH_GRAPHICS + Meshpath);

  {$IFNDEF MAPEDITOR}
  if Meshpath.Contains(PATH_GRAPHICS_ENVIRONMENT) then FIsStatic := True;
  {$ENDIF}
  try
    FMesh := TMesh.CreateFromFile(GFXD.MainScene, Meshpath);
  except
    {$IFDEF MAPEDITOR}
    showmessage('Failed to load mesh ''' + Meshpath + '''. It won''t be visible.');
    DeferFree;
    Exit;
    {$ELSE}
    raise;
    {$ENDIF}
  end;
  FOriginalTextures[mtDiffuse] := FMesh.DiffuseTetxure;
  FOriginalTextures[mtNormal] := FMesh.NormalTexture;
  FOriginalTextures[mtMaterial] := FMesh.SpecularTexture;
  FOriginalTextures[mtGlow] := FMesh.GlowTexture;
  FSizeNormalization := 1.0;
  FMesh.Scale := FSizeNormalization;
  FMesh.ShadingReductionOverride := Settings.GetSingleOption(coEngineGlobalShadingReduction);

  if FMesh.AnimationController.HasAnimation(ANIMATION_STAND) then
      FMesh.AnimationController.DefaultAnimation := ANIMATION_STAND;
end;

function TMeshComponent.NoWalkOffset : TMeshComponent;
begin
  Result := self;
  FNoWalkOffset := True;
end;

function TMeshComponent.OnAfterDeserialization : boolean;
begin
  Result := True;
  Apply;
  ConditionalTexturesDirty;
end;

function TMeshComponent.OnBoundings(Previous : RParam) : RParam;
begin
  if Previous.IsEmpty and not FIsEffectMesh then
  begin
    if assigned(FMesh) then
        FLastBoundings := FMesh.BoundingSphereTransformed;
    Result := RParam.From<RSphere>(FLastBoundings);
  end
  else
      Result := Previous;
end;

function TMeshComponent.OnChangeCommander(Index : RParam) : boolean;
begin
  Result := True;
  ConditionalTexturesDirty;
end;

function TMeshComponent.OnClientOption(ChangedOption : RParam) : boolean;
begin
  Result := True;
  if assigned(FMesh) then
  begin
    case ChangedOption.AsEnumType<EnumClientOption> of
      coEngineGlobalShadingReduction : FMesh.ShadingReductionOverride := Settings.GetSingleOption(coEngineGlobalShadingReduction);
      coGameplayFixedTeamColors : ConditionalTexturesDirty;
    end;
  end;
end;

function TMeshComponent.OnColorAdjustment(ColorAdjustment : RParam; absH, absS, absV : RParam) : boolean;
begin
  Result := True;
  if assigned(FMesh) then
  begin
    FColorHasBeenAdjusted := True;
    FMesh.AbsoluteColorAdjustmentH := absH.AsBoolean;
    FMesh.AbsoluteColorAdjustmentS := absS.AsBoolean;
    FMesh.AbsoluteColorAdjustmentV := absV.AsBoolean;
    FMesh.ColorAdjustment := ColorAdjustment.AsVector3;
    FMesh.AbsoluteHSV := ColorAdjustment.AsVector3;
  end;
end;

function TMeshComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
var
  ColorIdentity : EnumEntityColor;
begin
  Result := True;
  if FIsEffectMesh or not assigned(FMesh) then Exit;
  if FMesh.AnimationController.HasAnimation(ANIMATION_DEATH) then
      FMesh.AnimationController.Play(ANIMATION_DEATH)
  else FMesh.AnimationController.Pause();
  if assigned(ClientGame) and Owner.UnitData(udHasDeathEffect).AsBoolean then
  begin
    // remove all effects for death effect
    while not FEffectStack.IsEmpty do PopEffect;
    if FDeathColorIdentityOverrideActive then
        ColorIdentity := FDeathColorIdentityOverride
    else
        ColorIdentity := Eventbus.Read(eiColorIdentity, []).AsEnumType<EnumEntityColor>;
    ClientGame.DecayManager.AddMesh(FMesh, ColorIdentity);
    // we passed our mesh to the manager and so can not rely on its validity anymore
    FMesh := nil;
    FDecaying := True;
    DeferFree;
  end
end;

function TMeshComponent.OnDrawOutline(Color, OnlyOutline : RParam) : boolean;
begin
  Result := True;
  if FIsEffectMesh then Exit;
  FHighlightedThisFrame := True;
  FOutlineColor := Color.AsType<RColor>;
  FOnlyOutline := OnlyOutline.AsBoolean;
end;

function TMeshComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  FAlternatingZoneIndex := (FAlternatingZoneIndex + 1);
end;

function TMeshComponent.OnUnitPropertyChanged(ChangedUnitProperties, Removed : RParam) : boolean;
begin
  Result := True;
  ConditionalTexturesDirty;
  if assigned(FMesh) then
  begin
    if [upFrozen, upBanished, upPetrified] * ChangedUnitProperties.AsSetType<SetUnitProperty> <> [] then
    begin
      if Removed.AsBoolean then
          FMesh.AnimationController.Resume
      else if not Removed.AsBoolean then
          FMesh.AnimationController.Pause;
    end;
  end;
end;

function TMeshComponent.OnSetResource(ResourceID, Amount : RParam) : boolean;
begin
  Result := True;
  ConditionalTexturesDirty;
end;

function TMeshComponent.OnSubPositionByString(Name : RParam; PrevValue : RParam) : RParam;
var
  ZoneName, BoneName : string;
  Pos : RMatrix4x3;
  BoneMatrix : RMatrix;
  Adjustments : RMatrixAdjustments;
  Position : RVector3;
  AlternatingZoneCount : integer;
begin
  if not PrevValue.IsEmpty or not IsVisible then
      Exit(PrevValue);

  // hack to prevent meshes added to entity dynamically from answering position requests
  if ((CurrentEvent.CalledToGroup <> []) and (CurrentEvent.CalledToGroup * [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] = [])) or not assigned(FMesh) then Exit(PrevValue);

  ZoneName := name.AsString.ToLowerInvariant;

  if FAlternatingZones.TryGetValue(ZoneName, AlternatingZoneCount) and (AlternatingZoneCount > 1) then
      ZoneName := ZoneName + Inttostr(FAlternatingZoneIndex mod AlternatingZoneCount);

  // translate predefined zones to bones
  if not FZoneToBoneBinding.TryGetValue(ZoneName, BoneName) then
      BoneName := ZoneName;

  if FMesh.TryGetBonePosition(BoneName, Pos) then
  begin
    BoneMatrix := Pos.To4x4;
    if FBoneAdjustments.TryGetValue(ZoneName, Adjustments) then
        BoneMatrix := Adjustments.Apply(BoneMatrix);
    Result := RParam.From<RMatrix>(BoneMatrix);
  end
  else
  begin
    BoneMatrix := RMatrix.IDENTITY;
    BoneMatrix.Front := FMesh.Front;
    BoneMatrix.Up := FMesh.Up;
    BoneMatrix.Left := FMesh.Left;
    if ZoneName = BIND_ZONE_HEAD then
        Position := FMesh.Position.SetY(FMesh.BoundingBoxTransformed.Max.Y * 0.8)
    else if ZoneName = BIND_ZONE_TOP then
        Position := FMesh.Position.SetY(FMesh.BoundingBoxTransformed.Max.Y)
    else if ZoneName = BIND_ZONE_GROUND then
        Position := FMesh.Position.SetY(GROUND_EPSILON)
    else if ZoneName = BIND_ZONE_PIVOT then
        Position := FMesh.Position
    else if ZoneName = BIND_ZONE_BOTTOM then
        Position := FMesh.Position
    else if PrevValue.IsEmpty then
    // center as default
    begin
      Position := FMesh.BoundingSphereTransformed.Center;
      if Position.Y < 0 then Position := Position * (RVector3.Create(1, -1, 1));
    end;
    Position := Position - (BoneMatrix * FinalModelOffset);
    if ZoneName = BIND_ZONE_GROUND then
        Position := Position.SetY(GROUND_EPSILON);
    BoneMatrix.Translation := Position;
    if FBoneAdjustments.TryGetValue(ZoneName, Adjustments) then
        BoneMatrix := Adjustments.Apply(BoneMatrix);
    Result := RParam.From<RMatrix>(BoneMatrix);
  end;
end;

function TMeshComponent.OnPlayAnimation(AnimationName, AnimationPlayMode, Length : RParam) : boolean;
var
  AnimationInfo : TAnimationController.TAnimationInfo;
  AnimationLength, AnimationOffset : integer;
  AnimName, FollowingDefault : string;
  Scale, Speed, SpeedFactor : single;
  Blend : boolean;
begin
  Result := True;
  if assigned(FMesh) then
  begin
    AnimName := AnimationName.AsString;
    Blend := AnimName = ANIMATION_WALK;
    if FMesh.AnimationController.HasAnimation(AnimName) then
    begin
      AnimationOffset := 0;
      AnimationLength := Length.AsInteger;
      if AnimationLength <= 0 then
      begin
        AnimationInfo := FMesh.AnimationController.GetAnimationInfoExtendedForItem(AnimName);
        AnimationLength := AnimationInfo.Length;
        AnimationInfo.Free;
      end;
      if not FAnimationSpeed.TryGetValue(AnimName, SpeedFactor) then SpeedFactor := 1.0;
      // special code for walkanimation
      if AnimName = ANIMATION_WALK then
      begin
        AnimationInfo := FMesh.AnimationController.GetAnimationInfoExtendedForItem(ANIMATION_WALK);
        if not FIgnoreScalingForAnimations then
        begin
          Speed := 1 / Eventbus.Read(eiSpeed, []).AsSingle;
          Scale := FMesh.Scale;
          AnimationLength := round(Speed * AnimationLength * Scale / FSizeNormalization * SIZE_FACTOR_3DSMAX * SpeedFactor * 0.077 * 2.5);
        end
        else
            AnimationLength := round(AnimationLength * FSize.MaxAbsValue * SpeedFactor);
        AnimationInfo.Free;
        // test for randomness in walk cycle to have same units look more different
        if not FNoWalkOffset then
            AnimationOffset := round(AnimationLength * random * 0.7);
      end
      else AnimationLength := round(AnimationLength * SpeedFactor);

      if FFollowingDefaultAnimation.TryGetValue(AnimName, FollowingDefault) and FMesh.AnimationController.HasAnimation(FollowingDefault) then
          FMesh.AnimationController.DefaultAnimation := FollowingDefault
      else if (AnimName = ANIMATION_ATTACK) and FHasAttackLoop and FMesh.AnimationController.HasAnimation(ANIMATION_ATTACK_LOOP) then
          FMesh.AnimationController.DefaultAnimation := ANIMATION_ATTACK_LOOP
      else if (AnimName = ANIMATION_ATTACK) and Eventbus.Read(eiIsMoving, []).AsBoolean then
          FMesh.AnimationController.DefaultAnimation := ANIMATION_WALK
      else if FMesh.AnimationController.HasAnimation(ANIMATION_STAND) then
          FMesh.AnimationController.DefaultAnimation := ANIMATION_STAND;
      FMesh.AnimationController.Play(AnimName, AnimationPlayMode.AsEnumType<EnumAnimationPlayMode>, AnimationLength, Blend, AnimationOffset);
    end;
  end;
end;

function TMeshComponent.SetAnimationSpeed(const AnimationName : string; AnimationSpeed : single) : TMeshComponent;
begin
  Result := self;
  FAnimationSpeed.AddOrSetValue(AnimationName, AnimationSpeed)
end;

procedure TMeshComponent.SetBoneAdjustments(const BoneName : string; const Value : RMatrixAdjustments);
begin
  FBoneAdjustments.AddOrSetValue(BoneName.ToLowerInvariant, Value);
end;

function TMeshComponent.SetFollowingDefaultAnimation(const AnimationName, FollowingDefaultAnimationName : string) : TMeshComponent;
begin
  Result := self;
  FFollowingDefaultAnimation.Add(AnimationName, FollowingDefaultAnimationName);
end;

function TMeshComponent.ApplyLegacySizeFactor : TMeshComponent;
begin
  Result := self;
  assert(assigned(FMesh));
  FSizeNormalization := SIZE_FACTOR_3DSMAX;
  FMesh.Scale := FSizeNormalization;
end;

function TMeshComponent.ApplyTeamColoring(MaskFilename : string) : TMeshComponent;
begin
  Result := self;
  if not MaskFilename.Contains('\') then
      MaskFilename := ExtractFileDir(FModelFileName) + '\' + MaskFilename;
  TMeshEffectTeamColor.Create(MaskFilename).AssignToEntity(Owner);
end;

function TMeshComponent.BindTextureToResource(TextureType : EnumMeshTexture; const TextureFilename : string; ResourceType : EnumResource; Comparator : EnumComparator; ReferenceValue : single; TargetGroup : TArray<byte>) : TMeshComponent;
var
  ConditionalTexture : TConditionalMeshTextureResource;
begin
  Result := self;
  ConditionalTexture := TConditionalMeshTextureResource.Create;
  ConditionalTexture.TextureType := TextureType;
  ConditionalTexture.TextureFilename := TextureFilename;
  ConditionalTexture.ResourceType := ResourceType;
  ConditionalTexture.Comparator := Comparator;
  ConditionalTexture.ReferenceValue := ReferenceValue;
  ConditionalTexture.ComponentGroup := ByteArrayToComponentGroup(TargetGroup);

  FConditionalTextures.Add(ConditionalTexture);
end;

function TMeshComponent.BindTextureToTeam(TextureType : EnumMeshTexture; const TextureFilename : string; TeamID : integer) : TMeshComponent;
var
  ConditionalTexture : TConditionalMeshTextureTeam;
begin
  Result := self;
  ConditionalTexture := TConditionalMeshTextureTeam.Create;
  ConditionalTexture.TextureType := TextureType;
  ConditionalTexture.TextureFilename := TextureFilename;
  ConditionalTexture.TargetTeamID := TeamID;

  FConditionalTextures.Add(ConditionalTexture);
end;

function TMeshComponent.BindTextureToUnitProperty(TextureType : EnumMeshTexture; const TextureFilename : string; MustHave : TArray<byte>) : TMeshComponent;
var
  ConditionalTexture : TConditionalMeshTextureUnitProperty;
begin
  Result := self;
  ConditionalTexture := TConditionalMeshTextureUnitProperty.Create;
  ConditionalTexture.TextureType := TextureType;
  ConditionalTexture.TextureFilename := TextureFilename;
  ConditionalTexture.MustHaveAny := ByteArrayToSetUnitProperies(MustHave);

  FConditionalTextures.Add(ConditionalTexture);
end;

function TMeshComponent.BindZoneToBone(const ZoneName, BoneName : string) : TMeshComponent;
begin
  Result := self;
  FZoneToBoneBinding.Add(ZoneName.ToLowerInvariant, BoneName.ToLowerInvariant);
end;

function TMeshComponent.BoneInvertX(const BoneName : string) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.BindInvertX := True;
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneInvertY(const BoneName : string) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.BindInvertY := True;
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneInvertZ(const BoneName : string) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.BindInvertZ := True;
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneOffset(const BoneName : string; OffsetX, OffsetY, OffsetZ : single) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.Offset := RVector3.Create(OffsetX, OffsetY, OffsetZ);
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneRotation(const BoneName : string; RotationX, RotationY, RotationZ : single) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.Rotation := RVector3.Create(RotationX, RotationY, RotationZ);
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneSwapXY(const BoneName : string) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.BindSwapXY := True;
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneSwapXZ(const BoneName : string) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.BindSwapXZ := True;
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneSwapYZ(const BoneName : string) : TMeshComponent;
var
  MatrixAdjustments : RMatrixAdjustments;
begin
  Result := self;
  MatrixAdjustments := GetBoneAdjustments(BoneName);
  MatrixAdjustments.BindSwapYZ := True;
  SetBoneAdjustments(BoneName, MatrixAdjustments);
end;

function TMeshComponent.BoneSwizzleXZY(const BoneName : string) : TMeshComponent;
begin
  Result := self;
  BoneSwapYZ(BoneName);
end;

function TMeshComponent.BoneSwizzleYXZ(const BoneName : string) : TMeshComponent;
begin
  Result := self;
  BoneSwapXY(BoneName);
end;

function TMeshComponent.BoneSwizzleYZX(const BoneName : string) : TMeshComponent;
begin
  Result := self;
  BoneSwapXZ(BoneName);
  BoneSwapYZ(BoneName);
end;

function TMeshComponent.BoneSwizzleZXY(const BoneName : string) : TMeshComponent;
begin
  Result := self;
  BoneSwapXY(BoneName);
  BoneSwapYZ(BoneName);
end;

function TMeshComponent.BoneSwizzleZYX(const BoneName : string) : TMeshComponent;
begin
  Result := self;
  BoneSwapXZ(BoneName);
end;

function TMeshComponent.ShadingReductionFromTerrain : TMeshComponent;
begin
  Result := self;
  FShadingReductionFromTerrain := True;
end;

{$IFDEF MAPEDITOR}


procedure TMeshComponent.ShowMaterialEditor;
begin
  if assigned(FMesh) then FMesh.ShowEditorForm;
end;
{$ENDIF}


function TMeshComponent.TryGetBoneAdjustments(const BoneName : string; out Adjustments : RMatrixAdjustments) : boolean;
begin
  Result := FBoneAdjustments.TryGetValue(BoneName.ToLowerInvariant, Adjustments);
end;

{ TParticleEffectComponent }

function TParticleEffectComponent.ActivateAtFireTarget : TParticleEffectComponent;
begin
  Result := self;
  FAtFireTarget := True;
end;

function TParticleEffectComponent.ActivateNow : TParticleEffectComponent;
begin
  Result := self;
  Apply;
  Start;
end;

function TParticleEffectComponent.ActivateOnCreate : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnCreate := True;
end;

function TParticleEffectComponent.ActivateOnDie : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnDie := True;
end;

function TParticleEffectComponent.ActivateOnFire : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnFire := True;
end;

function TParticleEffectComponent.ActivateOnFireDelayed(DeferTime : integer) : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnFire := True;
  FDefer := TTimer.CreatePaused(DeferTime);
end;

function TParticleEffectComponent.ActivateOnFireWarhead : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnFireWarhead := True;
end;

function TParticleEffectComponent.ActivateOnFree : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnFree := True;
end;

function TParticleEffectComponent.ActivateOnLose : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnLose := True;
end;

function TParticleEffectComponent.ActivateOnPreFire : TParticleEffectComponent;
begin
  Result := self;
  FStartEmissionOnPreFire := True;
end;

function TParticleEffectComponent.ActivateOnWelaActivate : TParticleEffectComponent;
begin
  Result := self;
  FActivateWithWela := True;
end;

procedure TParticleEffectComponent.Apply;
var
  Targets : ATarget;
  TargetPosition : RVector3;
begin
  inherited;
  if FPlaceAtSavedTarget then
  begin
    Targets := Eventbus.Read(eiWelaSavedTargets, [], ComponentGroup).AsATarget;
    if Targets.HasIndex(0) then
    begin
      TargetPosition := Targets.First.GetTargetPosition.X0Y;
      FBindMatrix.Translation := TargetPosition;
    end;
  end;
  FParticleEffect.Update(
    FBindMatrix.Translation,
    FBindMatrix.Front,
    FBindMatrix.Up,
    FinalSize.X);
end;

procedure TParticleEffectComponent.BeforeComponentFree;
begin
  if FStartEmissionOnFree and assigned(Game) and not Game.IsShuttingDown then
      Start;
  inherited;
end;

constructor TParticleEffectComponent.Create(Owner : TEntity; ParticlePath : string; SizeNormalization : single);
begin
  CreateGrouped(Owner, TArray<byte>.Create(), ParticlePath, SizeNormalization);
end;

constructor TParticleEffectComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; const ParticlePath : string; SizeNormalization : single);
begin
  inherited CreateGrouped(Owner, Group);
  FLoadedTeamID := -1;
  FParticlePath := ParticlePath;
  FEffectFilename := PATH_GRAPHICS_PARTICLE_EFFECTS + FParticlePath;
  if FEffectFilename.Contains('%d') then
      FChangesWithTeam := True;
  CheckAndReloadParticleEffect;
  FSizeNormalization := SizeNormalization;
  FModelsize := Eventbus.Read(eiModelSize, [], ComponentGroup).AsSingleDefault(1.0);
  FDefer := nil;
  if FModelsize <= 0 then FModelsize := 1;
end;

constructor TParticleEffectComponent.CreateGroupedAndActivated(Owner : TEntity; Group : TArray<byte>; const ParticlePath : string; SizeNormalization : single);
begin
  CreateGrouped(Owner, Group, ParticlePath, SizeNormalization);
  if not assigned(FParticleEffect) then Exit;
  Apply;
  Start;
end;

function TParticleEffectComponent.DeactivateOnMoveTo : TParticleEffectComponent;
begin
  Result := self;
  FStopEmissionOnMoveTo := True;
end;

function TParticleEffectComponent.DeactivateOnTime(StopTime : integer) : TParticleEffectComponent;
begin
  Result := self;
  FDeactivateOnTime := TTimer.Create(StopTime);
  FDeactivateOnTime.Start;
end;

function TParticleEffectComponent.Delay(DeferTime : integer) : TParticleEffectComponent;
begin
  Result := self;
  FDefer := TTimer.CreatePaused(DeferTime);
end;

destructor TParticleEffectComponent.Destroy;
begin
  FDeactivateOnTime.Free;
  FDefer.Free;
  FParticleEffect.Free;
  inherited;
end;

function TParticleEffectComponent.EmitFromAllBones : TParticleEffectComponent;
begin
  Result := self;
  FEmitFromAllBones := True;
end;

function TParticleEffectComponent.FinalSize : RVector3;
begin
  Result := inherited / FSizeNormalization;
end;

function TParticleEffectComponent.FixedHeightGround : TParticleEffectComponent;
begin
  Result := self;
  inherited FixedHeightGround;
end;

function TParticleEffectComponent.FixedOrientationDefault : TParticleEffectComponent;
begin
  Result := self;
  inherited FixedOrientationDefault;
end;

function TParticleEffectComponent.OnAfterDeserialization : boolean;
begin
  Result := True;
  if not assigned(FParticleEffect) then
  begin
    DeferFree;
    Exit;
  end;
  Apply;
  if FStartEmissionOnCreate or
    (FActivateWithWela and Eventbus.Read(eiWelaActive, [], ComponentGroup).AsBooleanDefaultTrue) then
      Start;
end;

function TParticleEffectComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  if FStartEmissionOnDie then Start;
  if FStopEmissionOnDie then FParticleEffect.StopEmission;
end;

function TParticleEffectComponent.OnExiled(Exiled : RParam) : boolean;
begin
  Result := True;
  if Exiled.AsBoolean then
      FParticleEffect.StopEmission
  else
    if FStartEmissionOnCreate then Start;
end;

function TParticleEffectComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FStartEmissionOnFire then
  begin
    if FAtFireTarget or FClonesToTarget then
        FLastTargets := Targets.AsATarget;
    Start;
  end;
  if FStopEmissionOnFire then
      Stop;
end;

function TParticleEffectComponent.OnFireWarhead(Targets : RParam) : boolean;
begin
  Result := True;
  if FStartEmissionOnFireWarhead then
  begin
    if FAtFireTarget or FClonesToTarget then
        FLastTargets := Targets.AsATarget;
    Start;
  end;
end;

function TParticleEffectComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  if FStartEmissionOnLose and (Owner.TeamID = TeamID.AsInteger) then
      Start;
end;

function TParticleEffectComponent.OnMoveTo(Target, Range : RParam) : boolean;
begin
  Result := True;
  if FStopEmissionOnMoveTo then FParticleEffect.StopEmission;
end;

function TParticleEffectComponent.OnPreFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FStartEmissionOnPreFire then
  begin
    if FAtFireTarget or FClonesToTarget then
        FLastTargets := Targets.AsATarget;
    Start;
  end;
end;

function TParticleEffectComponent.OnWelaActive(Value : RParam) : boolean;
begin
  Result := True;
  if FActivateWithWela then
  begin
    if Value.AsBooleanDefaultTrue then
        Start
    else
        FParticleEffect.StopEmission;
  end;
end;

function TParticleEffectComponent.PlaceAtSavedTarget : TParticleEffectComponent;
begin
  Result := self;
  FPlaceAtSavedTarget := True;
end;

procedure TParticleEffectComponent.CheckAndReloadParticleEffect;
var
  resolvedParticlePath : string;
  TeamID : integer;
begin
  if FFixedTeamID >= 0 then
      TeamID := FFixedTeamID
  else
      TeamID := Owner.TeamID;
  TeamID := GetDisplayedTeam(TeamID);
  if FChangesWithTeam and (FLoadedTeamID <> TeamID) then
  begin
    FLoadedTeamID := TeamID;
    resolvedParticlePath := Format(FEffectFilename, [FLoadedTeamID]);
  end
  else
  begin
    // if no dynamic team, we only have to initialize it once
    if assigned(FParticleEffect) then
    begin
      Apply;
      Exit;
    end;
    resolvedParticlePath := FEffectFilename;
  end;
  FParticleEffect.Free;
  FParticleEffect := ParticleEffectEngine.CreateParticleEffectFromFile(AbsolutePath(resolvedParticlePath), True);
  Apply;
end;

function TParticleEffectComponent.Clone(Target : TEntity) : TParticleEffectComponent;
begin
  Result := TParticleEffectComponent.CreateGrouped(Target, [], FParticlePath, FSizeNormalization);
  Result.FBoundZone := FBoundZone;
  Result.FBindGroup := FBindGroup;
  Result.FFixedOrientation := FFixedOrientation;
  Result.FFixedFront := FFixedFront;
  Result.FFixedUp := FFixedUp;
  Result.ActivateNow;
end;

function TParticleEffectComponent.ClonesToTarget : TParticleEffectComponent;
begin
  Result := self;
  FClonesToTarget := True;
end;

procedure TParticleEffectComponent.Idle;
begin
  inherited;
  FParticleEffect.Visible := IsVisible;
  if assigned(FDefer) and FDefer.Expired then
  begin
    StartNow;
    FDefer.Start;
    FDefer.Pause;
  end;
  if assigned(FDeactivateOnTime) and FDeactivateOnTime.Expired then
      FParticleEffect.StopEmission;
end;

function TParticleEffectComponent.IgnoreModelSize : TParticleEffectComponent;
begin
  Result := self;
  inherited IgnoreModelSize;
end;

function TParticleEffectComponent.IsVisible : boolean;
begin
  Result := inherited;
end;

function TParticleEffectComponent.ScaleRange(Minimum, Maximum : single) : TParticleEffectComponent;
begin
  Result := self;
  inherited ScaleRange(Minimum, Maximum);
end;

function TParticleEffectComponent.ScaleWith(Event : EnumEventIdentifier) : TParticleEffectComponent;
begin
  Result := self;
  inherited ScaleWith(Event);
end;

procedure TParticleEffectComponent.Start;
begin
  if assigned(FDefer) then
      FDefer.Start
  else
      StartNow;
end;

procedure TParticleEffectComponent.StartNow;
var
  i : integer;
  TargetEntity : TEntity;
  mat : RParam;
begin
  if not assigned(FParticleEffect) or not assigned(ClientGame) or (ClientGame.IsFinished) then Exit;
  CheckAndReloadParticleEffect;
  if FClonesToTarget then
  begin
    for i := 0 to Length(FLastTargets) - 1 do
      if FLastTargets[i].TryGetTargetEntity(TargetEntity) then
          Clone(TargetEntity);
  end
  else if FAtFireTarget then
  begin
    for i := 0 to Length(FLastTargets) - 1 do
    begin
      if FLastTargets[i].TryGetTargetEntity(TargetEntity) then
      begin
        mat := RPARAMEMPTY;
        if IsBoundToBone then mat := TargetEntity.Eventbus.Read(eiSubPositionByString, [FBoundZone], FBindGroup);
        if not mat.IsEmpty then FParticleEffect.Base := mat.AsType<RMatrix>.To4x3
        else FParticleEffect.Position := TargetEntity.DisplayPosition
      end
      else
          FParticleEffect.Position := FLastTargets[i].GetTargetPosition.X0Y;
      FParticleEffect.Position := FParticleEffect.Position + FinalModelOffset;
      if FFixedOrientation then
      begin
        FParticleEffect.Front := FFixedFront;
        FParticleEffect.Up := FFixedUp;
      end;
      if FHasFixedHeight then
          FParticleEffect.Position := FParticleEffect.Position.SetY(FFixedHeight);
      FParticleEffect.StartEmission;
    end;
  end
  else if FEmitFromAllBones then
  begin
    Owner.Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(
      procedure(Component : TEntityComponent)
      var
        BoneList : TStrings;
        i : integer;
        BoneMat : RMatrix4x3;
      begin
        if (Component is TMeshComponent) and assigned(TMeshComponent(Component).FMesh) then
        begin
          BoneList := TMeshComponent(Component).FMesh.GetBoneList;
          for i := 0 to BoneList.Count - 1 do
            if TMeshComponent(Component).FMesh.TryGetBonePosition(BoneList[i], BoneMat) then
            begin
              FParticleEffect.Base := BoneMat;
              if FFixedOrientation then
              begin
                FParticleEffect.Front := FFixedFront;
                FParticleEffect.Up := FFixedUp;
              end;
              FParticleEffect.StartEmission;
            end;
          BoneList.Free;
        end;
      end)]);
  end
  else FParticleEffect.StartEmission;
end;

procedure TParticleEffectComponent.Stop;
begin
  FParticleEffect.StopEmission;
end;

function TParticleEffectComponent.DeactivateOnDie : TParticleEffectComponent;
begin
  Result := self;
  FStopEmissionOnDie := True;
end;

function TParticleEffectComponent.DeactivateOnFire : TParticleEffectComponent;
begin
  Result := self;
  FStopEmissionOnFire := True;
end;

{ TVertexRayVisualizerComponent }

function TVertexRayVisualizerComponent.BindEndOffset(EndOffsetX, EndOffsetY, EndOffsetZ : single) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FEndZoneOffset.X := EndOffsetX;
  FEndZoneOffset.Y := EndOffsetY;
  FEndZoneOffset.Z := EndOffsetZ;
end;

function TVertexRayVisualizerComponent.BindStartOffset(StartOffsetX, StartOffsetY, StartOffsetZ : single) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FStartZoneOffset.X := StartOffsetX;
  FStartZoneOffset.Y := StartOffsetY;
  FStartZoneOffset.Z := StartOffsetZ;
end;

function TVertexRayVisualizerComponent.BindStartToSubPositionGroup(const ZoneName : string; TargetGroup : TArray<byte>) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FStartZoneBinding := ZoneName;
  FStartZoneGroup := ByteArrayToComponentGroup(TargetGroup);
end;

constructor TVertexRayVisualizerComponent.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FRays := TAdvancedList<RRay>.Create;
end;

function TVertexRayVisualizerComponent.CurrentEndPosition : RVector3;
begin
  Result := CurrentStartPosition + (FEndZoneOffset * CurrentSize.Height);
end;

function TVertexRayVisualizerComponent.CurrentSize : RVector2;
begin
  Result := RVector2.ONE;
  if assigned(FTimer) and assigned(FTimedSizeKeyPoints) then
  begin
    Result := Result * HMath.Interpolate(FTimedSizeKeyPoints, FTimer.ZeitDiffProzent, EnumInterpolationMode.imLinear, FTimer.Interval);
  end;
end;

function TVertexRayVisualizerComponent.CurrentStartPosition : RVector3;
begin
  if FStartZoneBinding <> '' then
      Result := Eventbus.Read(eiSubPositionByString, [FStartZoneBinding], FStartZoneGroup).AsType<RMatrix>.Translation
  else
      Result := Owner.DisplayPosition;
  Result := Result + FStartZoneOffset;
end;

destructor TVertexRayVisualizerComponent.Destroy;
begin
  FRayTexture.Free;
  FRays.Each(
    procedure(const Item : RRay)
    begin
      Item.Ray.Free;
    end);
  FRays.Free;
  FTimer.Free;
  inherited;
end;

procedure TVertexRayVisualizerComponent.InitRays;
var
  i : integer;
  Ray : RRay;
begin
  for i := 0 to FRays.Count - 1 do
  begin
    Ray.Ray := TVertexWorldspaceQuad.Create(VertexEngine);
    Ray.Ray.Texture := FRayTexture;
    Ray.Ray.BlendMode := BlendAdditive;
    Ray.Ray.Color := Ray.Ray.Color.SetAlphaF(FOpacity);
    Ray.Width := FWidth.random;
    if FStartWidth = 0 then Ray.Ray.Trapezial := RVector2.Create(1, 1)
    else Ray.Ray.Trapezial := RVector2.Create(Ray.Width / FStartWidth / 2, 1);
    Ray.Width := Ray.Width / Ray.Ray.Trapezial.X;
    Ray.Speed := FLongitudinalSpeed.random;
    Ray.RotSpeed := FRotationSpeed.random;

    Ray.Length := FLength.random;
    Ray.Offset := RVariedVector3.CreateRadialVaried(RVector3.ZERO, FEndposJitter).getRandomVector;
    FRays[i] := Ray;
  end;
end;

function TVertexRayVisualizerComponent.OnIdle : boolean;
var
  CurrentTime : int64;
  StartPosVec, EndPosVec, tempEnd, between : RVector3;
  textureOffset, ScaleFactor : single;
  i : integer;
begin
  Result := True;
  if assigned(FTimer) and FTimer.Expired then
      FreeAndNil(FTimer);

  StartPosVec := CurrentStartPosition;
  // never show invalid rays
  if StartPosVec.X0Z.IsZeroVector then Exit;

  EndPosVec := CurrentEndPosition;
  // never show invalid rays
  if EndPosVec.X0Z.IsZeroVector then Exit;

  if FScaleWithResource <> reNone then
      ScaleFactor := ResourcePercentage(FScaleWithResource, Eventbus.Read(eiResourceBalance, [ord(FScaleWithResource)], ComponentGroup), Eventbus.Read(eiResourceCap, [ord(FScaleWithResource)], ComponentGroup))
  else
      ScaleFactor := 0.0;

  CurrentTime := GameTimeManager.GetTimestamp;

  for i := 0 to FRays.Count - 1 do
  begin
    tempEnd := EndPosVec + FRays[i].Offset.RotateAxis(between.Normalize, CurrentTime / 1000 * FRays[i].RotSpeed);
    between := tempEnd - StartPosVec;
    FRays[i].Ray.Position := (StartPosVec).Lerp(tempEnd, 0.5);
    FRays[i].Ray.Up := between.Normalize;
    if FPlanar then FRays[i].Ray.Left := FRays[i].Ray.Up.Cross(RVector3.UNITY);
    FRays[i].Ray.Width := (FRays[i].Width + FScaleWidth * ScaleFactor) * CurrentSize.Width;
    FRays[i].Ray.Height := between.Length;
    textureOffset := ((CurrentTime / 1000) * (FRays[i].Speed / FRays[i].Length));
    FRays[i].Ray.CoordinateRect := RRectFloat.Create(0, textureOffset, 1, textureOffset + FRays[i].Ray.Height / FRays[i].Length);
    FRays[i].Ray.AddRenderJob;
  end;
end;

function TVertexRayVisualizerComponent.Planar : TVertexRayVisualizerComponent;
begin
  Result := self;
  FPlanar := True;
end;

function TVertexRayVisualizerComponent.ScaleWidth(ScaleWidth : single) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FScaleWidth := ScaleWidth;
end;

function TVertexRayVisualizerComponent.ScaleWith(Resource : EnumResource) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FScaleWithResource := Resource;
end;

function TVertexRayVisualizerComponent.SetEndposJitter(EndposJitter : single) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FEndposJitter := EndposJitter;
  InitRays;
end;

function TVertexRayVisualizerComponent.SetLength(Length : RVariedSingle) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FLength := Length;
  InitRays;
end;

function TVertexRayVisualizerComponent.SetLongitudinalSpeed(LongitudinalSpeed : RVariedSingle) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FLongitudinalSpeed := LongitudinalSpeed;
  InitRays;
end;

function TVertexRayVisualizerComponent.SetOpacity(Opacity : single) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FOpacity := Opacity;
  InitRays;
end;

function TVertexRayVisualizerComponent.SetRaycount(Count : integer) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FRays.Each(
    procedure(const Item : RRay)
    begin
      Item.Ray.Free;
    end);
  FRays.Clear;
  FRays.Count := Count;
  InitRays;
end;

function TVertexRayVisualizerComponent.SetRotationSpeed(RotationSpeed : RVariedSingle) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FRotationSpeed := RotationSpeed;
  InitRays;
end;

function TVertexRayVisualizerComponent.SetStartWidth(Width : single) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FStartWidth := Width;
  InitRays;
end;

procedure TVertexRayVisualizerComponent.SetTimes(const Values : TArray<integer>; var SourceArray : TArray<RVector2>; var TargetArray : TArray < RTuple < integer, RVector2 >> );
var
  i : integer;
begin
  assert(Length(Values) = Length(SourceArray), 'TAnimatorComponent.SetTimes: Time keys have to be same count as value keys!');
  System.SetLength(TargetArray, Length(Values));
  for i := 0 to Length(Values) - 1 do
      TargetArray[i] := RTuple<integer, RVector2>.Create(Values[i], SourceArray[i]);
  System.SetLength(SourceArray, 0);
  FTimer := TTimer.CreateAndStart(Values[high(Values)]);
end;

procedure TVertexRayVisualizerComponent.SetValues(const Values : TArray<single>; Axis : integer; var TargetArray : TArray<RVector2>);
var
  i : integer;
begin
  System.SetLength(TargetArray, Max(Length(Values), Length(TargetArray)));
  for i := 0 to Length(Values) - 1 do
      TargetArray[i].Element[Axis] := Values[i];
end;

function TVertexRayVisualizerComponent.SetWidth(Width : RVariedSingle) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FWidth := Width;
  InitRays;
end;

function TVertexRayVisualizerComponent.SizeKeypoints(Values : TArray<single>) : TVertexRayVisualizerComponent;
begin
  Result := self;
  SetValues(Values, 0, FSizeKeyPoints);
  SetValues(Values, 1, FSizeKeyPoints);
end;

function TVertexRayVisualizerComponent.SizeKeypointsLength(Values : TArray<single>) : TVertexRayVisualizerComponent;
begin
  Result := self;
  SetValues(Values, 1, FSizeKeyPoints);
end;

function TVertexRayVisualizerComponent.SizeKeypointsWidth(Values : TArray<single>) : TVertexRayVisualizerComponent;
begin
  Result := self;
  SetValues(Values, 0, FSizeKeyPoints);
end;

function TVertexRayVisualizerComponent.SizeTimes(Values : TArray<integer>) : TVertexRayVisualizerComponent;
begin
  Result := self;
  SetTimes(Values, FSizeKeyPoints, FTimedSizeKeyPoints);
end;

function TVertexRayVisualizerComponent.Texture(const FilePath : string) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FRayTexture := TTexture.CreateTextureFromFile(PATH_GRAPHICS + FilePath, GFXD.Device3D, mhGenerate, True);
end;

{ TVisualModificatorSizeComponent }

destructor TVisualModificatorSizeComponent.Destroy;
begin
  FDuration.Free;
  inherited;
end;

function TVisualModificatorSizeComponent.Keypoints(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
var
  i : integer;
begin
  Result := self;
  SetLength(FSizes, Length(Sizes));
  for i := 0 to Length(Sizes) - 1 do
      FSizes[i] := RVector3.Create(Sizes[i]);
end;

function TVisualModificatorSizeComponent.KeypointsX(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
var
  i, FormerSize : integer;
begin
  Result := self;
  FormerSize := Length(FSizes);
  SetLength(FSizes, Length(Sizes));
  for i := 0 to Length(Sizes) - 1 do
  begin
    if FormerSize <= i then
        FSizes[i] := RVector3.Create(Sizes[i])
    else
        FSizes[i].X := Sizes[i];
  end;
end;

function TVisualModificatorSizeComponent.KeypointsY(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
var
  i, FormerSize : integer;
begin
  Result := self;
  FormerSize := Length(FSizes);
  SetLength(FSizes, Length(Sizes));
  for i := 0 to Length(Sizes) - 1 do
  begin
    if FormerSize <= i then
        FSizes[i] := RVector3.Create(Sizes[i])
    else
        FSizes[i].Y := Sizes[i];
  end;
end;

function TVisualModificatorSizeComponent.KeypointsZ(const Sizes : TArray<single>) : TVisualModificatorSizeComponent;
var
  i, FormerSize : integer;
begin
  Result := self;
  FormerSize := Length(FSizes);
  SetLength(FSizes, Length(Sizes));
  for i := 0 to Length(Sizes) - 1 do
  begin
    if FormerSize <= i then
        FSizes[i] := RVector3.Create(Sizes[i])
    else
        FSizes[i].Z := Sizes[i];
  end;
end;

function TVisualModificatorSizeComponent.OnSize(Previous : RParam) : RParam;
var
  Size : RVector3;
  TargetSizes : TArray<RVector3>;
begin
  if not IsLocalCall then Exit;
  Size := Previous.AsVector3Default(RVector3.ONE);
  TargetSizes := FSizes;
  if assigned(FDuration) then
  begin
    if Length(FTimeKeys) > 0 then
        Result := Size * HMath.Interpolate(FTimeKeys, FDuration.ZeitDiffProzent(True), imCosinus)
    else
        Result := Size * HMath.Interpolate(TargetSizes, FDuration.ZeitDiffProzent(True), imCosinus)
  end
  else
      Result := Size * TargetSizes[high(TargetSizes)];
end;

function TVisualModificatorSizeComponent.Duration(Duration : integer) : TVisualModificatorSizeComponent;
begin
  Result := self;
  FDuration := TTimer.CreateAndStart(Duration);
end;

function TVisualModificatorSizeComponent.SetTargetSize(Size : single) : TVisualModificatorSizeComponent;
begin
  Result := self;
  SetLength(FSizes, 2);
  FSizes[0] := RVector3.ONE;
  FSizes[1] := RVector3.Create(Size);
end;

function TVisualModificatorSizeComponent.TimeKeys(const Times : TArray<integer>) : TVisualModificatorSizeComponent;
var
  i : integer;
begin
  Result := self;
  assert(Length(Times) = Length(FSizes), 'TVisualModificatorSizeComponent.TimeKeys: Timekeys and Values have to be equal sized!');
  SetLength(FTimeKeys, Min(Length(FSizes), Length(Times)));
  for i := 0 to Length(FTimeKeys) - 1 do
      FTimeKeys[i] := RTuple<integer, RVector3>.Create(Times[i], FSizes[i]);
end;

{ TPositionerAttacherComponent }

function TPositionerAttacherComponent.ApplyFront : TPositionerAttacherComponent;
begin
  Result := self;
  FUseFront := True;
end;

function TPositionerAttacherComponent.AttachToDestination : TPositionerAttacherComponent;
begin
  Result := self;
  FSource := False;
end;

function TPositionerAttacherComponent.AttachToSource : TPositionerAttacherComponent;
begin
  Result := self;
  FSource := True;
end;

constructor TPositionerAttacherComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FSubPositionGroup := [0, 1];
end;

function TPositionerAttacherComponent.InvertFront : TPositionerAttacherComponent;
begin
  Result := self;
  FInvertFront := True;
end;

function TPositionerAttacherComponent.TryGetTarget(out Target : RTarget) : boolean;
var
  Targets : ATarget;
begin
  if FSource then Targets := Eventbus.Read(eiLinkSource, []).AsATarget
  else Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
  if not Targets.HasIndex(FAttachIndex) then
  begin
    assert(False, Format('TPositionerAttacherComponent.OnIdle: Mounted to index %d, but it isn''t present!', [FAttachIndex]));
    Exit(False);
  end;
  Target := Targets[FAttachIndex];
  Result := True;
end;

function TPositionerAttacherComponent.OnAfterDeserialization : boolean;
begin
  Result := True;
  OnIdle;
end;

function TPositionerAttacherComponent.OnDisplayFront(PreviousFront : RParam) : RParam;
begin
  if FUseFront and IsLocalCall then
      Result := FFront
  else
      Result := PreviousFront;
end;

function TPositionerAttacherComponent.OnDisplayPosition(PreviousPosition : RParam) : RParam;
begin
  if IsLocalCall then
      Result := FPosition
  else
      Result := PreviousPosition;
end;

function TPositionerAttacherComponent.OnIdle : boolean;
var
  Target : RTarget;
  MatrixParam : RParam;
  Matrix : RMatrix;
  TargetPos, Front, Offset : RVector3;
  ent : TEntity;
begin
  Result := True;
  if not TryGetTarget(Target) then Exit;

  Front := RVector3.UNITZ;
  TargetPos := Target.GetTargetPosition.X0Y;
  Offset := FOffset;
  if Target.IsEntity then
  begin
    if Target.TryGetTargetEntity(ent) then
    begin
      if (FSubPosition <> '') then
      begin
        MatrixParam := ent.Eventbus.Read(eiSubPositionByString, [FSubPosition], FSubPositionGroup);
        if MatrixParam.IsEmpty then
            TargetPos := FLastTargetPos
        else
        begin
          Matrix := MatrixParam.AsType<RMatrix>;
          TargetPos := Matrix.Translation;
          Front := Matrix.Front;
        end;
      end
      else
      begin
        TargetPos := ent.DisplayPosition;
        Front := ent.DisplayFront;
      end;
      Owner.CollisionRadius := ent.CollisionRadius;
    end
    else TargetPos := FLastTargetPos;
  end;

  Offset := RMatrix.CreateSaveBase(Front, RVector3.UNITY) * Offset;

  FPosition := TargetPos + Offset;
  FLastTargetPos := TargetPos;
  FFront := Front;
  if FInvertFront then
      FFront := -FFront;

  if FDebug then
      LinePool.AddCoordinateSystem(RMatrix.CreateSaveBase(FFront, RVector3.UNITY) * RMatrix.CreateTranslation(FPosition));
end;

function TPositionerAttacherComponent.OnSubPositionByString(Name : RParam) : RParam;
var
  Target : RTarget;
  ent : TEntity;
begin
  Result := RPARAMEMPTY;
  if not TryGetTarget(Target) then Exit;

  if Target.IsEntity then
  begin
    ent := Target.GetTargetEntity;
    if assigned(ent) then
    begin
      Result := ent.Eventbus.Read(eiSubPositionByString, [name]);
    end;
  end;
end;

function TPositionerAttacherComponent.RenderDebug : TPositionerAttacherComponent;
begin
  Result := self;
  FDebug := True;
end;

function TPositionerAttacherComponent.SetIndex(Index : integer) : TPositionerAttacherComponent;
begin
  Result := self;
  FAttachIndex := index;
end;

function TPositionerAttacherComponent.Offset(OffsetX, OffsetY, OffsetZ : single) : TPositionerAttacherComponent;
begin
  Result := self;
  FOffset.X := OffsetX;
  FOffset.Y := OffsetY;
  FOffset.Z := OffsetZ;
end;

function TPositionerAttacherComponent.SetSubPosition(const SubPosition : string) : TPositionerAttacherComponent;
begin
  Result := self;
  FSubPosition := SubPosition;
end;

function TPositionerAttacherComponent.SetSubPositionGroup(const SubPosition : string; Group : TArray<byte>) : TPositionerAttacherComponent;
begin
  Result := self;
  FSubPosition := SubPosition;
  FSubPositionGroup := ByteArrayToComponentGroup(Group);
end;

{ TPositionerMeteorComponent }

constructor TPositionerMeteorComponent.Create(Owner : TEntity; Offset : RVector3);
begin
  inherited Create(Owner);
  FOffset := Offset;
end;

constructor TPositionerMeteorComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; Offset : RVector3);
begin
  inherited CreateGrouped(Owner, Group);
  FOffset := Offset;
end;

destructor TPositionerMeteorComponent.Destroy;
begin
  FFlyTimer.Free;
  inherited;
end;

procedure TPositionerMeteorComponent.Init(Offset : RVector3);
begin
  FTargetPosition := Owner.DisplayPosition;
  FStartPosition := FTargetPosition + Offset;
  FFlyTimer := TTimer.CreateAndStart(Eventbus.Read(eiCooldown, [], ComponentGroup).AsInteger);
end;

function TPositionerMeteorComponent.OnAfterDeserialization : boolean;
begin
  Result := True;
  Init(FOffset);
end;

function TPositionerMeteorComponent.OnDisplayPosition(PreviousPosition : RParam) : RParam;
begin
  Result := FStartPosition.Lerp(FTargetPosition, FFlyTimer.ZeitDiffProzent);
end;

function TPositionerMeteorComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  FFlyTimer.SetZeitDiffProzent(1.0);
  FFlyTimer.Pause;
end;

{ TPositionerSplineComponent }

function TPositionerSplineComponent.BindToSubPosition(const Name : string; TargetGroup : TArray<byte>) : TPositionerSplineComponent;
begin
  Result := self;
  FSub := name;
  FTargetGroup := ByteArrayToComponentGroup(TargetGroup);
end;

function TPositionerSplineComponent.BindToTargetSubPosition(const Name : string) : TPositionerSplineComponent;
begin
  Result := self;
  FTargetSub := name;
end;

function TPositionerSplineComponent.BothTangents(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
begin
  Result := self;
  FTangentStart.X := HorizontalRotation;
  FTangentStart.Y := VerticalRotation;
  FTangentStart.Z := Weight;
  FTangentEnd := FTangentStart;
end;

function TPositionerSplineComponent.BothTangentsAfterReached(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
begin
  Result := self;
  FTangentStartAfterReached.X := HorizontalRotation;
  FTangentStartAfterReached.Y := VerticalRotation;
  FTangentStartAfterReached.Z := Weight;
  FTangentEndAfterReached := FTangentStartAfterReached;
end;

constructor TPositionerSplineComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FMaxDistanceScaling := 10000;
  FTangentStart := RVector3.UNITZ;
  FTangentEnd := RVector3.UNITZ;
  FTargetSub := BIND_ZONE_HIT_ZONE;
end;

function TPositionerSplineComponent.StartOffset(OffsetX, OffsetY, OffsetZ : single) : TPositionerSplineComponent;
begin
  Result := self;
  FStartOffset.X := OffsetX;
  FStartOffset.Y := OffsetY;
  FStartOffset.Z := OffsetZ;
end;

function TPositionerSplineComponent.StartTangent(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
begin
  Result := self;
  FTangentStart.X := HorizontalRotation;
  FTangentStart.Y := VerticalRotation;
  FTangentStart.Z := Weight;
end;

function TPositionerSplineComponent.StartTangentRandom(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
begin
  Result := self;
  FTangentStart := RVariedVector3.Create(FTangentStart, RVector3.Create(HorizontalRotation, VerticalRotation, Weight)).getRandomVector;
end;

function TPositionerSplineComponent.OnAfterDeserialization : boolean;
var
  Creator : TEntity;
  Targets : ATarget;
  MatrixParam : RParam;
begin
  Result := True;
  FStartPos := Owner.Position;
  Creator := Game.EntityManager.GetEntityByID(Eventbus.Read(eiCreator, []).AsInteger);

  if (FSub <> '') and assigned(Creator) then
      MatrixParam := Creator.Eventbus.Read(eiSubPositionByString, [FSub], FTargetGroup)
  else
      MatrixParam := RPARAMEMPTY;

  if MatrixParam.IsEmpty then
  begin
    FStart := RMatrix.IDENTITY;
    FStart.Translation := FStartPos.X0Y;
    if assigned(Creator) then
    begin
      FStart.Front := Creator.DisplayFront;
      FStart.Up := Creator.DisplayUp;
      FStart.Left := FStart.Front.Cross(FStart.Up);
    end;
  end
  else FStart := MatrixParam.AsType<RMatrix>;

  Targets := Eventbus.Read(eiWelaSavedTargets, []).AsATarget;
  assert(Targets.Count = 1, Format('TPositionerSplineComponent.OnAfterDeserialization: Only one target is assumed to work with Splinecomponent got %d', [Targets.Count]));
  if Targets.Count > 0 then
      FTarget := Targets[0];
end;

function TPositionerSplineComponent.OnMoveTargetReached : boolean;
begin
  Result := True;
  FStart.Translation := FLastEndPosition;
  FStartPos := FTarget.GetTargetPosition;
  if not FTangentStartAfterReached.IsZeroVector then
      FTangentStart := FTangentStartAfterReached;
  if not FTangentEndAfterReached.IsZeroVector then
      FTangentEnd := FTangentEndAfterReached;
end;

function TPositionerSplineComponent.OnMoveTo(Target, Range : RParam) : boolean;
begin
  Result := True;
  FTarget := Target.AsType<RTarget>;
end;

function TPositionerSplineComponent.OrientStartWithTarget : TPositionerSplineComponent;
begin
  Result := self;
  FOrientStartWithTarget := True;
end;

function TPositionerSplineComponent.RenderDebug : TPositionerSplineComponent;
begin
  Result := self;
  FDebug := True;
end;

function TPositionerSplineComponent.RotateTangent(const HorizontalRotation, VerticalRotation, RotationSpeed : single) : TPositionerSplineComponent;
begin
  Result := self;
  FRotationSpeed := RotationSpeed;
  FRotationAxisHorizontal := HorizontalRotation;
  FRotationAxisVertical := VerticalRotation;
end;

function TPositionerSplineComponent.EndTangent(const HorizontalRotation, VerticalRotation, Weight : single) : TPositionerSplineComponent;
begin
  Result := self;
  FTangentEnd.X := HorizontalRotation;
  FTangentEnd.Y := VerticalRotation;
  FTangentEnd.Z := Weight;
end;

function TPositionerSplineComponent.MaxDistanceScaling(MaxDistanceScaling : single) : TPositionerSplineComponent;
begin
  Result := self;
  FMaxDistanceScaling := MaxDistanceScaling;
end;

function TPositionerSplineComponent.OnDisplayFront(PreviousFront : RParam) : RParam;
begin
  if FTarget.IsEmpty or FLastFront.IsZeroVector then
      Result := PreviousFront
  else
      Result := FLastFront;
end;

function TPositionerSplineComponent.OnDisplayPosition(PreviousPosition : RParam) : RParam;
var
  s : single;
  realDistance, startDistance, heightAngle : single;
  TargetEntity : TEntity;
  Target : RVector2;
  bitangent, dir : RVector3;
  Spline : RHermiteSpline;
  temp : RParam;
begin
  Result := PreviousPosition;
  if FTarget.IsEmpty then Exit;

  Target := FTarget.GetTargetPosition;
  startDistance := FStartPos.Distance(Target);
  realDistance := Owner.Position.Distance(Target);
  if startDistance <> 0 then s := 1.0 - HMath.Saturate(realDistance / startDistance)
  else s := 1.0;

  Spline.StartPosition := FStart * FStartOffset;

  if FTarget.IsEntity then
  begin
    if FTarget.TryGetTargetEntity(TargetEntity) then
    begin
      temp := TargetEntity.Eventbus.Read(eiSubPositionByString, [FTargetSub], [0, 1]);
      if not temp.IsEmpty then Spline.EndPosition := temp.AsType<RMatrix>.Translation
      else Spline.EndPosition := FTarget.GetTargetPosition.X0Y;
    end
    else Spline.EndPosition := FLastEndPosition; // if entity was present, but not anymore take last known position
  end
  else Spline.EndPosition := FTarget.GetTargetPosition.X0Y;

  if upProjectileWillMiss in Owner.UnitProperties then
  begin
    if Spline.EndPosition.Y > 2 then
        Spline.EndPosition := Spline.EndPosition + RVector3.UNITY// air
    else
        Spline.EndPosition := Spline.EndPosition.SetY(-1); // ground
  end;

  FLastEndPosition := Spline.EndPosition;

  dir := (Target - FStartPos).Normalize.X0Y;
  heightAngle := arccos(Min(1, Max(-1, Spline.Direction.Dot(Spline.Direction.SetY(0).Normalize))));
  bitangent := RVector3.UNITY.Cross(dir).Normalize;
  // clamp maximum scaling factor
  startDistance := Min(FMaxDistanceScaling, startDistance);
  if FOrientStartWithTarget then
      Spline.StartTangent := dir.RotateAxis(bitangent, -FTangentStart.X).RotateAxis(RVector3.UNITY, FTangentStart.Y).SetLength(FTangentStart.Z) * startDistance
  else
      Spline.StartTangent := FStart.Front.RotateAxis(FStart.Left, FTangentStart.X + heightAngle).RotateAxis(FStart.Up, FTangentStart.Y).SetLength(FTangentStart.Z) * startDistance;
  Spline.EndTangent := -((-dir).RotateAxis(bitangent, FTangentEnd.X - heightAngle).RotateAxis(RVector3.UNITY, FTangentEnd.Y).SetLength(FTangentEnd.Z) * startDistance);

  // apply rotation
  if FRotationSpeed > 0 then
      Spline.EndTangent := Spline.EndTangent.RotateAxis((-dir).RotateAxis(bitangent, FRotationAxisHorizontal - heightAngle).RotateAxis(RVector3.UNITY, FRotationAxisVertical), FRotationSpeed / 1000 * TimeManager.ZDiff);

  Result := Spline.getPosition(s);
  FLastFront := Spline.getTangent(s);
  if FDebug then
  begin
    LinePool.AddHermite(Spline, RColor.CRED, 128, False);
    LinePool.AddLine(Spline.StartPosition, Spline.StartPosition + Spline.StartTangent, RColor.CGREEN);
    LinePool.AddLine(Spline.EndPosition, Spline.EndPosition - Spline.EndTangent, RColor.CBLUE);
  end;
end;

{ TPositionerOffsetComponent }

constructor TPositionerOffsetComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FTargetGroup := ComponentGroup;
end;

destructor TPositionerOffsetComponent.Destroy;
begin
  FTransitionTimer.Free;
  inherited;
end;

function TPositionerOffsetComponent.Offset(X, Y, Z : single) : TPositionerOffsetComponent;
begin
  Result := self;
  FOffset := RVector3.Create(X, Y, Z);
end;

function TPositionerOffsetComponent.FinalOffset : RVector3;
begin
  if assigned(FTransitionTimer) then
      Result := FOffset * RCubicBezier.EASEOUT.Solve(FTransitionTimer.ZeitDiffProzent(True))
  else
      Result := FOffset;
end;

function TPositionerOffsetComponent.OnDisplayPosition(PreviousPosition : RParam) : RParam;
var
  Position : RVector3;
begin
  if not IsLocalCall(FTargetGroup) then
      Exit(PreviousPosition);
  if (FTargetGroup <> []) and PreviousPosition.IsEmpty then
      Position := Owner.DisplayPosition
  else
      Position := PreviousPosition.AsVector3;

  if FOverrideY then
      Position.Y := 0;

  Position := Position + FinalOffset;

  Result := Position;
end;

function TPositionerOffsetComponent.OverrideY : TPositionerOffsetComponent;
begin
  Result := self;
  FOverrideY := True;
end;

function TPositionerOffsetComponent.TargetGroup(Group : TArray<byte>) : TPositionerOffsetComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

function TPositionerOffsetComponent.Transition(Time : integer) : TPositionerOffsetComponent;
begin
  Result := self;
  FTransitionTimer := TTimer.CreateAndStart(Time);
end;

{ TAnimatorComponent }

function TAnimatorComponent.PlayAnimation(TimeKey : integer; const AnimationName : string; AnimationLength : integer) : TAnimatorComponent;
begin
  Result := self;
  HArray.Push < RTriple < integer, string, integer >> (FAnimations, RTriple<integer, string, integer>.Create(TimeKey, AnimationName, AnimationLength));
end;

function TAnimatorComponent.ActivateOnDie : TAnimatorComponent;
begin
  Result := self;
  assert(assigned(FTimer), 'TAnimatorComponent.ActivateOnDie: Must be called after a call to Duration!');
  FOnDie := True;
  FTimer.Pause;
end;

function TAnimatorComponent.ActivateOnFire : TAnimatorComponent;
begin
  Result := self;
  assert(assigned(FTimer), 'TAnimatorComponent.ActivateOnFire: Must be called after a call to Duration!');
  FOnFire := True;
  FTimer.Pause;
end;

function TAnimatorComponent.ActivateOnLose : TAnimatorComponent;
begin
  Result := self;
  assert(assigned(FTimer), 'TAnimatorComponent.ActivateOnLose: Must be called after a call to Duration!');
  FOnLose := True;
  FTimer.Pause;
end;

function TAnimatorComponent.ActivateOnPreFire : TAnimatorComponent;
begin
  Result := self;
  assert(assigned(FTimer), 'TAnimatorComponent.ActivateOnPreFire: Must be called after a call to Duration!');
  FOnPreFire := True;
  FTimer.Pause;
end;

destructor TAnimatorComponent.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TAnimatorComponent.Duration(TimeMs : integer) : TAnimatorComponent;
begin
  Result := self;
  FTimer := TTimer.CreateAndStart(TimeMs);
end;

function TAnimatorComponent.FreeGroupAfter : TAnimatorComponent;
begin
  Result := self;
  FFreeGroup := True;
end;

function TAnimatorComponent.FrontKeypointsX(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 0, FFrontKeypoints);
end;

function TAnimatorComponent.FrontKeypointsY(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 1, FFrontKeypoints);
end;

function TAnimatorComponent.FrontKeypointsZ(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 2, FFrontKeypoints);
end;

function TAnimatorComponent.FrontTimes(Values : TArray<integer>) : TAnimatorComponent;
begin
  Result := self;
  SetTimes(Values, FFrontKeypoints, FTimedFrontKeypoints);
end;

function TAnimatorComponent.HideAfter(TimeKey : integer) : TAnimatorComponent;
begin
  Result := self;
  FHideAfter := TimeKey;
end;

function TAnimatorComponent.HideUntil(TimeKey : integer) : TAnimatorComponent;
begin
  Result := self;
  FHideUntil := TimeKey;
end;

function TAnimatorComponent.InterpolationMode(Mode : EnumInterpolationMode) : TAnimatorComponent;
begin
  Result := self;
  FInterpolationMode := Mode;
end;

function TAnimatorComponent.PositionKeypointsX(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 0, FKeyPoints);
end;

function TAnimatorComponent.PositionKeypointsY(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 1, FKeyPoints);
end;

function TAnimatorComponent.PositionKeypointsZ(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 2, FKeyPoints);
end;

function TAnimatorComponent.PositionTimes(Values : TArray<integer>) : TAnimatorComponent;
begin
  Result := self;
  SetTimes(Values, FKeyPoints, FTimedKeyPoints);
end;

function TAnimatorComponent.Offset(X, Y, Z : single) : TAnimatorComponent;
begin
  Result := self;
  FOffset := RVector3.Create(X, Y, Z);
end;

function TAnimatorComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  if FOnDie then
      FTimer.Weiter;
end;

function TAnimatorComponent.OnDisplayFront(Previous : RParam) : RParam;
var
  newFront, Left : RVector3;
begin
  if not IsLocalCall or (not assigned(FFrontKeypoints) and not assigned(FTimedFrontKeypoints)) or (assigned(FTimer) and FTimer.Paused) then Exit(Previous);
  if Previous.IsEmpty and (CurrentEvent.CalledToGroup <> []) then
      Previous := Owner.DisplayFront;
  newFront := Previous.AsVector3;
  if assigned(FTimer) then
  begin
    Left := newFront.Cross(RVector3.UNITY).Normalize;
    if assigned(FTimedFrontKeypoints) then newFront := newFront.RotatePitchYawRoll(HMath.Interpolate(FTimedFrontKeypoints, FTimer.ZeitDiffProzent, FInterpolationMode, FTimer.Interval))
    else newFront := newFront.RotatePitchYawRoll(HMath.Interpolate(FFrontKeypoints, FTimer.ZeitDiffProzent, FInterpolationMode));
  end;
  Result := newFront;
end;

function TAnimatorComponent.OnDisplayPosition(Previous : RParam) : RParam;
var
  newPos : RVector3;
begin
  if not IsLocalCall or (not assigned(FKeyPoints) and not assigned(FTimedKeyPoints)) or (assigned(FTimer) and FTimer.Paused) then Exit(Previous);
  if Previous.IsEmpty and (CurrentEvent.CalledToGroup <> []) then
      Previous := Owner.DisplayPosition;
  newPos := Previous.AsVector3;
  if assigned(FTimer) then
  begin
    if assigned(FTimedKeyPoints) then newPos := newPos + HMath.Interpolate(FTimedKeyPoints, FTimer.ZeitDiffProzent, FInterpolationMode, FTimer.Interval)
    else newPos := newPos + HMath.Interpolate(FKeyPoints, FTimer.ZeitDiffProzent, FInterpolationMode);
  end;
  Result := newPos;
end;

function TAnimatorComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FOnFire then
      FTimer.Weiter;
end;

function TAnimatorComponent.OnIdle : boolean;
var
  i : integer;
begin
  Result := True;
  for i := Length(FAnimations) - 1 downto 0 do
  begin
    if not FTimer.Paused and (FTimer.TimeSinceStart >= FAnimations[i].a) then
    begin
      Eventbus.Trigger(eiPlayAnimation, [FAnimations[i].b, RParam.From<EnumAnimationPlayMode>(alSingle), FAnimations[i].c], ComponentGroup);
      HArray.Delete < RTriple < integer, string, integer >> (FAnimations, i);
    end;
  end;
  if not assigned(FTimer) or FTimer.Expired then
  begin
    if FFreeGroup and assigned(Game) then Game.EntityManager.FreeComponentGroup(Owner.ID, ComponentGroup)
    else DeferFree;
    Exit;
  end;
end;

function TAnimatorComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  if FOnLose and (Owner.TeamID = TeamID.AsInteger) then
      FTimer.Weiter;
end;

function TAnimatorComponent.OnPreFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FOnPreFire then
      FTimer.Weiter;
end;

function TAnimatorComponent.OnSize(Previous : RParam) : RParam;
var
  newSize : RVector3;
begin
  if not IsLocalCall or (not assigned(FSizeKeyPoints) and not assigned(FTimedSizeKeyPoints)) or (assigned(FTimer) and FTimer.Paused) then Exit(Previous);
  if Previous.IsEmpty and (CurrentEvent.CalledToGroup <> []) then
      Previous := Eventbus.Read(eiSize, []);
  newSize := Previous.AsVector3Default(RVector3.ONE);
  if assigned(FTimer) then
  begin
    if assigned(FTimedSizeKeyPoints) then
        newSize := newSize * HMath.Interpolate(FTimedSizeKeyPoints, FTimer.ZeitDiffProzent, FInterpolationMode, FTimer.Interval)
    else
        newSize := newSize * HMath.Interpolate(FSizeKeyPoints, FTimer.ZeitDiffProzent, FInterpolationMode);
  end;
  Result := newSize;
end;

function TAnimatorComponent.OnVisible(Previous : RParam) : RParam;
begin
  if IsLocalCall and
    (assigned(FTimer) and
    not FTimer.Paused and
    ((FHideUntil > 0) and (FTimer.TimeSinceStart <= FHideUntil)) or
    ((FHideAfter > 0) and (FTimer.TimeSinceStart > FHideAfter))) then
      Result := False
  else
      Result := Previous;
end;

procedure TAnimatorComponent.SetTimes(const Values : TArray<integer>; var SourceArray : TArray<RVector3>; var TargetArray : TArray < RTuple < integer, RVector3 >> );
var
  i : integer;
begin
  assert(Length(Values) = Length(SourceArray), 'TAnimatorComponent.SetTimes: Time keys have to be same count as value keys!');
  SetLength(TargetArray, Length(Values));
  for i := 0 to Length(Values) - 1 do
      TargetArray[i] := RTuple<integer, RVector3>.Create(Values[i], SourceArray[i]);
  SetLength(SourceArray, 0);
end;

procedure TAnimatorComponent.SetValues(const Values : TArray<single>; Axis : integer; var TargetArray : TArray<RVector3>);
var
  i : integer;
begin
  SetLength(TargetArray, Max(Length(Values), Length(TargetArray)));
  for i := 0 to Length(Values) - 1 do
      TargetArray[i].Element[Axis] := Values[i];
end;

function TAnimatorComponent.SizeKeypoints(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 0, FSizeKeyPoints);
  SetValues(Values, 1, FSizeKeyPoints);
  SetValues(Values, 2, FSizeKeyPoints);
end;

function TAnimatorComponent.SizeKeypointsXZ(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 0, FSizeKeyPoints);
  SetValues(Values, 2, FSizeKeyPoints);
end;

function TAnimatorComponent.SizeKeypointsY(Values : TArray<single>) : TAnimatorComponent;
begin
  Result := self;
  SetValues(Values, 1, FSizeKeyPoints);
end;

function TAnimatorComponent.SizeTimes(Values : TArray<integer>) : TAnimatorComponent;
begin
  Result := self;
  SetTimes(Values, FSizeKeyPoints, FTimedSizeKeyPoints);
end;

{ TMeshEffect }

function TMeshEffect.Additive : TMeshEffect;
begin
  Result := self;
  FBlendMode := BlendAdditive;
end;

procedure TMeshEffect.AssignToEntity(const Entity : TEntity);
var
  found : boolean;
begin
  InitOnEntity(Entity);
  found := False;
  Entity.Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(
    procedure(Component : TEntityComponent)
    begin
      if (Component is TMeshComponent) then
      begin
        if found then
            TMeshComponent(Component).AddMeshEffect(self.Clone(nil))
        else
            TMeshComponent(Component).AddMeshEffect(self);
        found := True;
      end;
    end)]);
end;

procedure TMeshEffect.InitShader(const ShaderName : string);
begin
  if ShaderName = '' then Exit;
  FHasShaderSetup := True;
  FCustomShader := ShaderName;
end;

function TMeshEffect.OverrideColorIdentity(ColorIdentity : EnumEntityColor) : TMeshEffect;
begin
  Result := self;
  FColorIdentityOverride := True;
  FColorIdentity := ColorIdentity;
end;

function TMeshEffect.OverrideGlowTexture : TMeshEffect;
begin
  Result := self;
  FGlowTextureOverride := True;
end;

procedure TMeshEffect.Reset;
begin
  // nothing to do here
end;

function TMeshEffect.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  assert(assigned(Effect), 'TMeshEffect.Clone: Base class got no initialized cloning class!');
  Result := Effect;
  Result.FOwningEntity := FOwningEntity;
  Result.FMesh := FMesh;
  Result.FCustomShader := FCustomShader;
  Result.FHasShaderSetup := FHasShaderSetup;
  Result.FColorIdentity := self.FColorIdentity;
  Result.FUseGlowOverride := self.FUseGlowOverride;
  Result.FNeedOwnPass := self.FNeedOwnPass;
  Result.FOwnPasses := self.FOwnPasses;
  Result.FOwnPassBlocks := self.FOwnPassBlocks;
  Result.FGlowTextureOverride := self.FGlowTextureOverride;
  Result.FBlendMode := self.FBlendMode;
  Result.FOrderValue := self.FOrderValue;
  Result.FColorIdentityOverride := self.FColorIdentityOverride;
end;

constructor TMeshEffect.Create();
begin
  FOrderValue := abs(integer(self.ClassType.ClassInfo));
end;

constructor TMeshEffect.CreateEmpty;
begin
end;

function TMeshEffect.Expired : boolean;
begin
  Result := False;
end;

procedure TMeshEffect.FinalizeOnMesh;
var
  i : integer;
begin
  if not IsMounted then Exit;
  if FGlowOverride then FMesh.GlowTexture := FOriginalGlowTexture;

  for i := FMesh.CustomShader.Count - 1 downto 0 do
    if FMesh.CustomShader[i].Tag = NativeUInt(self) then
        FMesh.CustomShader.Delete(i);
  FIsMounted := False;
end;

procedure TMeshEffect.InitializeOnMesh(const Mesh : TMesh);
var
  DefaultGlowTexture : string;
  Desc : RMeshShader;
  i : integer;
  Inserted : boolean;
begin
  if IsMounted then Exit;
  FMesh := Mesh;
  // build mesh shader description
  Desc := RMeshShader.Create(FCustomShader, nil, FNeedOwnPass, FOwnPasses, FOwnPassBlocks, FBlendMode, NativeUInt(self));
  if FHasShaderSetup then
      Desc.SetUp := SetUpShader;

  // insert shader at the right position regarding its order value
  Inserted := False;
  for i := 0 to FMesh.CustomShader.Count - 1 do
    if TMeshEffect(FMesh.CustomShader[i].Tag).OrderValue > self.OrderValue then
    begin
      Inserted := True;
      FMesh.CustomShader.Insert(i, Desc);
      break;
    end;
  if not Inserted then
      FMesh.CustomShader.Add(Desc);

  // global overrides
  if FUseGlowOverride and ((FMesh.GlowTexture = '') or FGlowTextureOverride) then
  begin
    FGlowOverride := True;
    case FColorIdentity of
      ecGreen : DefaultGlowTexture := 'GreenGlow.tga';
      ecBlack : DefaultGlowTexture := 'BlackGlow.tga';
      ecBlue : DefaultGlowTexture := 'BlueGlow.tga';
      ecColorless : DefaultGlowTexture := 'ColorlessGlow.tga';
    else
      DefaultGlowTexture := 'WhiteGlow.tga';
    end;
    FOriginalGlowTexture := FMesh.GlowTexture;
    FMesh.GlowTexture := AbsolutePath(PATH_GRAPHICS_EFFECTS_TEXTURES + DefaultGlowTexture);
  end;

  FIsMounted := True;
end;

procedure TMeshEffect.InitOnEntity(const Entity : TEntity);
begin
  FOwningEntity := Entity;
  if not FColorIdentityOverride then
      FColorIdentity := Entity.Eventbus.Read(eiColorIdentity, []).AsEnumType<EnumEntityColor>;
end;

procedure TMeshEffect.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin

end;

{ TMeshEffectGeneric }

function TMeshEffectGeneric.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectGeneric.CreateEmpty()
  else Result := Effect;
  Result := inherited Clone(Result);
  (Result as TMeshEffectGeneric).FLastDisplayedTeamID := FLastDisplayedTeamID;
  (Result as TMeshEffectGeneric).FTextureName := FTextureName;
  (Result as TMeshEffectGeneric).FTextureSlot := FTextureSlot;
  if assigned(FEffectTexture) then
    (Result as TMeshEffectGeneric).FEffectTexture := FEffectTexture.Clone();
end;

constructor TMeshEffectGeneric.Create(const ShaderName, TextureFilename : string);
begin
  FLastDisplayedTeamID := -1;
  FTextureSlot := tsVariable3;
  InitShader(ShaderName);
  if TextureFilename <> '' then
      FEffectTexture := TTexture.CreateTextureFromFile(AbsolutePath(TextureFilename), GFXD.Device3D, mhGenerate, True);
  inherited Create();
end;

destructor TMeshEffectGeneric.Destroy;
begin
  FEffectTexture.Free;
  inherited;
end;

function TMeshEffectGeneric.SetTexture(const TextureFilename : string) : TMeshEffectGeneric;
begin
  Result := self;
  if TextureFilename <> '' then
  begin
    if TextureFilename.Contains('%d') then FTextureName := TextureFilename
    else FEffectTexture := TTexture.CreateTextureFromFile(AbsolutePath(TextureFilename), GFXD.Device3D, mhGenerate, True);
  end;
end;

procedure TMeshEffectGeneric.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
var
  finalTextureName : string;
begin
  if (not assigned(FEffectTexture) or (FLastDisplayedTeamID <> GetDisplayedTeam(FOwningEntity.TeamID))) and (FTextureName <> '') then
  begin
    FLastDisplayedTeamID := GetDisplayedTeam(FOwningEntity.TeamID);
    finalTextureName := Format(FTextureName, [GetDisplayedTeam(FOwningEntity.TeamID)]);
    FEffectTexture.Free;
    FEffectTexture := TTexture.CreateTextureFromFile(AbsolutePath(finalTextureName), GFXD.Device3D, mhGenerate, True);
  end;
  if assigned(FEffectTexture) then
      CurrentShader.SetTexture(FTextureSlot, FEffectTexture);
end;

{ TMeshEffectSpawn }

function TMeshEffectSpawn.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectSpawn.CreateEmpty()
  else Result := Effect;
  Result := inherited Clone(Result);
  with (Result as TMeshEffectSpawn) do
  begin
    FSpawneffectTexture := self.FSpawneffectTexture.Clone;
    FSpawnTimer := TTimer.CreateAndStart(self.FSpawnTimer.Interval);
    FLegendary := self.FLegendary;
    FOverrideColor := self.FOverrideColor;
    FFrame := self.FFrame;
    FOffset := self.FOffset;
    FHeightFactor := self.FHeightFactor;
    FCullmode := self.FCullmode;
    FZDiff := self.FZDiff;
  end;
end;

constructor TMeshEffectSpawn.Create();
begin
  FHeightFactor := 1.0;
  FUseGlowOverride := True;
  FSpawneffectTexture := TTexture.CreateTextureFromFile(PATH_GRAPHICS_EFFECTS + 'Textures\SpawnMask.png', GFXD.Device3D, mhGenerate, True);
  FSpawnTimer := TTimer.CreateAndStart(2500);
  inherited Create();
  FOrderValue := ORDER_VALUE;
end;

destructor TMeshEffectSpawn.Destroy;
begin
  FSpawneffectTexture.Free;
  FSpawnTimer.Free;
  inherited;
end;

function TMeshEffectSpawn.Expired : boolean;
begin
  Result := inherited or FSpawnTimer.Expired;
end;

procedure TMeshEffectSpawn.FinalizeOnMesh;
begin
  inherited;
  FMesh.Cullmode := FCullmode;
end;

function TMeshEffectSpawn.HeightFactor(Factor : single) : TMeshEffectSpawn;
begin
  Result := self;
  FHeightFactor := Factor;
end;

procedure TMeshEffectSpawn.InitializeOnMesh(const Mesh : TMesh);
begin
  inherited InitializeOnMesh(Mesh);
  FSpawnTimer.Interval := EFFECT_TIMES[FColorIdentity];
  FSpawnTimer.Start;
  FSpawnTimer.Delay(FOffset);
  FCullmode := FMesh.Cullmode;
  FMesh.Cullmode := cmNone;
end;

procedure TMeshEffectSpawn.InitOnEntity(const Entity : TEntity);
var
  ShaderName : string;
begin
  inherited;
  case FColorIdentity of
    ecColorless : ShaderName := 'SpawnShader_Colorless.fx';
    ecGreen : ShaderName := 'SpawnShader_Green.fx';
    ecBlack :
      begin
        if FLegendary then
        begin
          ShaderName := 'SpawnShader_Black_Legendary.fx';
          FUseGlowOverride := False;
        end
        else ShaderName := 'SpawnShader_Black.fx';
      end;
    ecBlue :
      begin
        ShaderName := 'SpawnShader_Blue.fx';
        FNeedOwnPass := [rsWorld, rsGlow];
        FOwnPasses := BLUE_PASSES;
        FOwnPassBlocks := True;
      end;
  else
    ShaderName := 'SpawnShader_White.fx';
  end;
  InitShader(PATH_GRAPHICS_SHADER + ShaderName);
end;

function TMeshEffectSpawn.Legendary : TMeshEffectSpawn;
begin
  Result := self;
  FLegendary := True;
end;

function TMeshEffectSpawn.OffsetEffectTime(Offset : integer) : TMeshEffectSpawn;
begin
  Result := self;
  FOffset := Offset;
end;

function TMeshEffectSpawn.OverrideColor(Color : cardinal) : TMeshEffectSpawn;
begin
  Result := self;
  FOverrideColor := RColor.Create(Color);
end;

function TMeshEffectSpawn.OverrideEffectTime(Interval : integer) : TMeshEffectSpawn;
begin
  Result := self;
  FSpawnTimer.Interval := Interval;
end;

procedure TMeshEffectSpawn.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
var
  fadingColor : RColor;
begin
  if FFrame <> GFXD.FPSCounter.FrameCount then
  begin
    FFrame := GFXD.FPSCounter.FrameCount;
    FZDiff := FSpawnTimer.ZeitDiffProzent(True);
  end;
  if Stage = rsGlow then CurrentShader.SetShaderConstant<single>('glow', 1.0)
  else CurrentShader.SetShaderConstant<single>('glow', 0.0);
  CurrentShader.SetShaderConstant<single>('progress', FZDiff);
  if FOverrideColor.IsFullTransparent then fadingColor := RColor(GLOW_COLOR_MAP[FColorIdentity])
  else fadingColor := FOverrideColor;
  CurrentShader.SetShaderConstant<RVector3>('fading_color', fadingColor.RGB);
  if FColorIdentity in [ecGreen, ecColorless] then
  begin
    CurrentShader.SetShaderConstant<RVector3>('object_position', FMesh.Position - FOwningComponent.FinalModelOffset);
  end;
  if FColorIdentity = ecBlue then
  begin
    if Stage = rsGlow then GFXD.Device3D.SetRenderState(rsZENABLE, False);
    CurrentShader.SetShaderConstant<single>('model_height', FMesh.BoundingBoxTransformed.Max.Y * FHeightFactor);
    CurrentShader.SetShaderConstant<single>('pass_progress', PassIndex / (BLUE_PASSES - 1));
  end;
  if FColorIdentity <> ecGreen then
      CurrentShader.SetShaderConstant<single>('model_height', FMesh.BoundingBoxTransformed.Max.Y * FHeightFactor);
  if FColorIdentity = ecWhite then
  begin
    CurrentShader.SetTexture(tsVariable3, FSpawneffectTexture);
  end;
end;

{ TMeshEffectSpawnerSpawn }

function TMeshEffectSpawnerSpawn.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectSpawnerSpawn.Create()
  else Result := Effect;
  Result := inherited Clone(Result);
end;

constructor TMeshEffectSpawnerSpawn.Create();
begin
  InitShader(PATH_GRAPHICS_SHADER + 'SpawnerSpawnShader.fx');
  FSpawneffectTexture := TTexture.CreateTextureFromFile(PATH_GRAPHICS_EFFECTS + 'Textures\SpawnMask.png', GFXD.Device3D, mhGenerate, True);
  FSpawnTimer := TTimer.CreateAndStart(2500);
  FOrderValue := ORDER_VALUE;
end;

{ TMeshEffectTeamColor }

constructor TMeshEffectTeamColor.Create(const MaskFilename : string);
begin
  inherited Create(PATH_GRAPHICS_SHADER + 'TeamColoring.fx', MaskFilename);
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectTeamColor.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectTeamColor.Create('')
  else Result := Effect;
  Result := inherited Clone(Result);
end;

procedure TMeshEffectTeamColor.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
var
  target_hue : single;
begin
  inherited;
  if assigned(FOwningEntity) then target_hue := GetTeamColor(FOwningEntity.TeamID).HSV.X
  else target_hue := 0;
  CurrentShader.SetShaderConstant<single>('new_hue', target_hue);
end;

{ TMeshEffectMetal }

constructor TMeshEffectMetal.Create();
begin
  inherited Create('MetalShader.fx', '');
  FOrderValue := ORDER_VALUE;
  FTextureSlot := tsVariable2;
end;

function TMeshEffectMetal.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectMetal.Create()
  else Result := Effect;
  Result := inherited Clone(Result);
  (Result as TMeshEffectMetal).FColorOverride := FColorOverride;
end;

procedure TMeshEffectMetal.InitOnEntity(const Entity : TEntity);
var
  MetalTexture : string;
  Color : EnumEntityColor;
begin
  inherited;
  if FColorOverride <> ecColorless then
      Color := FColorOverride
  else
      Color := FColorIdentity;
  case Color of
    ecWhite : MetalTexture := PATH_GRAPHICS_EFFECTS + 'Metal\Metal_White.png';
    ecGreen : MetalTexture := PATH_GRAPHICS_EFFECTS + 'Metal\Metal_Green.png';
    ecBlack : MetalTexture := PATH_GRAPHICS_EFFECTS + 'Metal\Metal_Black.png';
    ecBlue : MetalTexture := PATH_GRAPHICS_EFFECTS + 'Metal\Metal_Blue.png';
    ecRed : MetalTexture := PATH_GRAPHICS_EFFECTS + 'Metal\Metal_Red.png';
  else
    MetalTexture := PATH_GRAPHICS_EFFECTS + 'Metal\Metal_Generic.png';
  end;
  SetTexture(MetalTexture);
end;

function TMeshEffectMetal.ShowAsColor(ColorOverride : EnumEntityColor) : TMeshEffectMetal;
begin
  Result := self;
  FColorOverride := ColorOverride;
end;

{ TMeshEffectMatcap }

constructor TMeshEffectMatcap.Create;
begin
  inherited Create('MatcapShader.fx', '');
  FTextureSlot := tsVariable2;
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectMatcap.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectMatcap.Create()
  else Result := Effect;
  Result := inherited Clone(Result);
end;

procedure TMeshEffectMatcap.InitOnEntity(const Entity : TEntity);
var
  MatcapTexture : string;
begin
  inherited;
  if not assigned(FEffectTexture) and (FTextureName = '') then
  begin
    MatcapTexture := PATH_GRAPHICS_EFFECTS + 'Textures\MatcapDefault.png';
    SetTexture(MatcapTexture);
  end;
end;

{ TMeshEffectSlidingTexture }

function TMeshEffectSlidingTexture.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectSlidingTexture.CreateEmpty()
  else Result := Effect;
  Result := inherited Clone(Result);
  (Result as TMeshEffectSlidingTexture).FSpeed := FSpeed;
  (Result as TMeshEffectSlidingTexture).FTiling := FTiling;
end;

constructor TMeshEffectSlidingTexture.Create(const TextureFilename : string);
begin
  inherited Create(PATH_GRAPHICS_SHADER + 'TextureOverlay.fx', TextureFilename);
  FSpeed := RVector2.Create(0, 0.1);
  FTiling := RVector2.Create(1, 1);
  FOrderValue := ORDER_VALUE;
end;

procedure TMeshEffectSlidingTexture.FinalizeOnMesh;
begin
  inherited;
  if FGlowOverride then FMesh.GlowTexture := '';
  if FFurOverride then FMesh.FurThickness := FFurThickness;
end;

procedure TMeshEffectSlidingTexture.InitializeOnMesh(const Mesh : TMesh);
begin
  inherited;
  if FMesh.HasFur then
  begin
    FFurOverride := True;
    FFurThickness := FMesh.FurThickness;
    FMesh.FurThickness := 0.01;
  end;
  if FMesh.GlowTexture = '' then
  begin
    FGlowOverride := True;
    FMesh.GlowTexture := AbsolutePath(PATH_GRAPHICS_EFFECTS_TEXTURES + 'WhiteGlow.tga');
  end;
end;

procedure TMeshEffectSlidingTexture.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  if Stage = rsGlow then CurrentShader.SetShaderConstant<single>('to_glow_stage', 1.0)
  else CurrentShader.SetShaderConstant<single>('to_glow_stage', 0.0);
  CurrentShader.SetShaderConstant<RVector2>('to_offset', GameTimeManager.FloatingTimestampSeconds * FSpeed);
  CurrentShader.SetShaderConstant<RVector2>('to_tiling', FTiling);
end;

function TMeshEffectSlidingTexture.Speed(const SpeedX, SpeedY : single) : TMeshEffectSlidingTexture;
begin
  Result := self;
  FSpeed := RVector2.Create(SpeedX, SpeedY);
end;

function TMeshEffectSlidingTexture.Tiling(const TilingX, TilingY : single) : TMeshEffectSlidingTexture;
begin
  Result := self;
  FTiling := RVector2.Create(TilingX, TilingY);
end;

{ TMeshEffectComponent }

function TMeshEffectComponent.ActivateOnDie : TMeshEffectComponent;
begin
  Result := self;
  FOnDie := True;
end;

function TMeshEffectComponent.ActivateOnFire : TMeshEffectComponent;
begin
  Result := self;
  FOnFire := True;
end;

function TMeshEffectComponent.ActivateOnLose : TMeshEffectComponent;
begin
  Result := self;
  FOnLose := True;
end;

function TMeshEffectComponent.ActivateOnPreFire : TMeshEffectComponent;
begin
  Result := self;
  FOnPreFire := True;
end;

function TMeshEffectComponent.ActivateOnWelaUnitProduced : TMeshEffectComponent;
begin
  Result := self;
  FOnWelaUnitProduced := True;
end;

procedure TMeshEffectComponent.ApplyEffects(Targets : TArray<TEntity>);
var
  Effect, GivenEffect : TMeshEffect;
  Effects : TObjectList<TMeshEffect>;
  i, j : integer;
  Entity : TEntity;
begin
  for j := 0 to Length(Targets) - 1 do
  begin
    Entity := Targets[j];
    for i := FDelayedEffects.Count - 1 downto 0 do
    begin
      Effect := FDelayedEffects[i];
      Effect.Reset;
      Effect.InitOnEntity(Entity);
      Entity.Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(
        procedure(Component : TEntityComponent)
        begin
          if (Component is TMeshComponent) then
          begin
            GivenEffect := Effect.Clone(nil);
            if not FAtTarget then
            begin
              GivenEffect.Managed := True;
              if not FEffects.TryGetValue(TMeshComponent(Component), Effects) then
              begin
                Effects := TObjectList<TMeshEffect>.Create;
                FEffects.Add(TMeshComponent(Component), Effects)
              end;
              Effects.Add(GivenEffect);
            end;
            TMeshComponent(Component).AddMeshEffect(GivenEffect);
          end;
        end)], FTargetGroup);
    end;
  end;
end;

function TMeshEffectComponent.ApplyToFireTarget : TMeshEffectComponent;
begin
  Result := self;
  FAtTarget := True;
end;

constructor TMeshEffectComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited CreateGrouped(Owner, Group);
  FEffects := TObjectDictionary < TMeshComponent, TObjectList < TMeshEffect >>.Create([doOwnsValues]);
  FTargetGroup := ComponentGroup;
  FDelayedEffects := TObjectList<TMeshEffect>.Create;
end;

destructor TMeshEffectComponent.Destroy;
begin
  FDelayedEffects.Free;
  Owner.Eventbus.Trigger(eiEnumerateComponents, [RParam.FromProc<ProcEnumerateEntityComponentCallback>(
    procedure(Component : TEntityComponent)
    var
      Effects : TObjectList<TMeshEffect>;
      i : integer;
    begin
      if (Component is TMeshComponent) and FEffects.TryGetValue(TMeshComponent(Component), Effects) then
      begin
        for i := 0 to Effects.Count - 1 do
            TMeshComponent(Component).RemoveMeshEffect(Effects[i]);
      end;
    end)], FTargetGroup);
  FEffects.Free;
  inherited;
end;

function TMeshEffectComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  if FOnDie then
      ApplyEffects([Owner]);
end;

function TMeshEffectComponent.OnFire(Targets : RParam) : boolean;
var
  TargetEntities : TArray<TEntity>;
  TargetsRaw : ATarget;
  i : integer;
  ent : TEntity;
begin
  Result := True;
  if FOnFire then
  begin
    if FAtTarget then
    begin
      TargetEntities := nil;
      TargetsRaw := Targets.AsATarget;
      for i := 0 to TargetsRaw.Count - 1 do
        if TargetsRaw[i].TryGetTargetEntity(ent) then
            HArray.Push<TEntity>(TargetEntities, ent);
      ApplyEffects(TargetEntities);
    end
    else ApplyEffects([Owner]);
  end;
end;

function TMeshEffectComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  if FOnLose and (Owner.TeamID = TeamID.AsInteger) then
      ApplyEffects([Owner]);
end;

function TMeshEffectComponent.OnPreFire(Targets : RParam) : boolean;
var
  TargetEntities : TArray<TEntity>;
  TargetsRaw : ATarget;
  i : integer;
  ent : TEntity;
begin
  Result := True;
  if FOnPreFire then
  begin
    if FAtTarget then
    begin
      TargetEntities := nil;
      TargetsRaw := Targets.AsATarget;
      for i := 0 to TargetsRaw.Count - 1 do
        if TargetsRaw[i].TryGetTargetEntity(ent) then
            HArray.Push<TEntity>(TargetEntities, ent);
      ApplyEffects(TargetEntities);
    end
    else ApplyEffects([Owner]);
  end;
end;

function TMeshEffectComponent.OnWelaUnitProduced(EntityID : RParam) : boolean;
var
  Entity : TEntity;
begin
  Result := True;
  if FOnWelaUnitProduced and Game.EntityManager.TryGetEntityByID(EntityID.AsInteger, Entity) then
      ApplyEffects([Entity]);
end;

function TMeshEffectComponent.SetEffect(const Effect : TMeshEffect) : TMeshEffectComponent;
begin
  Result := self;
  FDelayedEffects.Add(Effect);
  if not FOnDie and not FOnFire then ApplyEffects([Owner]);
end;

function TMeshEffectComponent.TargetGroup(const Group : TArray<byte>) : TMeshEffectComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TMeshEffectWobble }

constructor TMeshEffectWobble.Create(const VoidMask : string);
begin
  inherited Create(PATH_GRAPHICS_SHADER + 'WobbleShader.fx', VoidMask);
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectWobble.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectWobble.Create('')
  else Result := Effect;
  Result := inherited Clone(Result);
end;

procedure TMeshEffectWobble.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  // inherited;
  if assigned(FEffectTexture) then
      CurrentShader.SetTexture(FTextureSlot, FEffectTexture, stVertexShader);
  CurrentShader.SetShaderConstant<single>('time', GameTimeManager.FloatingTimestampSeconds * 0.1);
end;

{ TMeshEffectVoid }

function TMeshEffectVoid.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectVoid.Create()
  else Result := Effect;
  Result := inherited Clone(Result);
end;

constructor TMeshEffectVoid.Create;
begin
  inherited Create(PATH_GRAPHICS_SHADER + 'VoidShader.fx', '');
  FOrderValue := ORDER_VALUE;
end;

procedure TMeshEffectVoid.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('void_time', GameTimeManager.FloatingTimestampSeconds * 0.1);
  if assigned(FEffectTexture) then
      CurrentShader.SetShaderConstant<single>('void_aspect_ratio', FEffectTexture.AspectRatio);
  CurrentShader.SetShaderConstant<single>('void_screen_aspect_ratio', GFXD.MainScene.Size.Width / GFXD.MainScene.Size.Height);
end;

{ TMeshEffectWithTimekeys }

function TMeshEffectWithTimekeys.AddKey(TimeKey : integer; Value : single) : TMeshEffectWithTimekeys;
begin
  Result := self;
  HArray.Push < RTuple < integer, single >> (FTimedKeyPoints[high(FTimedKeyPoints)], RTuple<integer, single>.Create(TimeKey, Value));
end;

function TMeshEffectWithTimekeys.AddNextTimeLine : TMeshEffectWithTimekeys;
begin
  Result := self;
  SetLength(FTimedKeyPoints, Length(FTimedKeyPoints) + 1);
end;

function TMeshEffectWithTimekeys.AddPermaKey(Value : single) : TMeshEffectWithTimekeys;
begin
  Result := self;
  AddKey(0, Value);
  AddKey(MaxInt, Value);
end;

function TMeshEffectWithTimekeys.Clone(const Effect : TMeshEffect) : TMeshEffect;
var
  i : integer;
begin
  if not assigned(Effect) then Result := TMeshEffectWithTimekeys.CreateEmpty()
  else Result := Effect;
  Result := inherited Clone(Result);
  if assigned((Result as TMeshEffectWithTimekeys).FTimer) then
    (Result as TMeshEffectWithTimekeys).FTimer.Free;
  (Result as TMeshEffectWithTimekeys).FTimer := FTimer.Clone;
  SetLength((Result as TMeshEffectWithTimekeys).FTimedKeyPoints, Length(FTimedKeyPoints));
  for i := 0 to Length(FTimedKeyPoints) - 1 do
    (Result as TMeshEffectWithTimekeys).FTimedKeyPoints[i] := Copy(FTimedKeyPoints[i]);
end;

constructor TMeshEffectWithTimekeys.Create(Duration : integer);
begin
  inherited Create('', '');
  if Duration <= 0 then
      Duration := 10000000;
  FTimer := TTimer.CreateAndStart(Duration);
  SetLength(FTimedKeyPoints, 1);
end;

function TMeshEffectWithTimekeys.CurrentValue(Index : integer) : single;
var
  TimedKeyPoints : TArray<RTuple<integer, single>>;
begin
  assert(index < Length(FTimedKeyPoints), 'TMeshEffectWithTimekeys.CurrentValue: Not enough timelines!');
  TimedKeyPoints := FTimedKeyPoints[index];
  if assigned(TimedKeyPoints) then Result := HMath.Interpolate(TimedKeyPoints, FTimer.ZeitDiffProzent(True), imLinear, FTimer.Interval)
  else Result := 1 - FTimer.ZeitDiffProzent(True);
end;

destructor TMeshEffectWithTimekeys.Destroy;
begin
  FTimer.Free;
  inherited;
end;

function TMeshEffectWithTimekeys.Expired : boolean;
begin
  Result := inherited or FTimer.Expired;
end;

function TMeshEffectWithTimekeys.HasTimeLine(Index : integer) : boolean;
begin
  Result := Length(FTimedKeyPoints) > index;
end;

procedure TMeshEffectWithTimekeys.Reset;
begin
  inherited;
  FTimer.Start;
end;

{ TMeshEffectWarp }

constructor TMeshEffectWarp.Create(const TextureFilename : string; Duration : integer);
begin
  FUseGlowOverride := True;
  inherited Create(Duration);
  InitShader(PATH_GRAPHICS_SHADER + 'Warp.fx');
  SetTexture(TextureFilename);
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectWarp.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectWarp.Create('', 0)
  else Result := Effect;
  Result := inherited Clone(Result);
  with (Result as TMeshEffectWarp) do
  begin
    FSmoothStep := self.FSmoothStep;
  end;
end;

procedure TMeshEffectWarp.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('warp_smooth', FSmoothStep);
  CurrentShader.SetShaderConstant<single>('warp_progress', CurrentValue);
  if Stage = rsGlow then CurrentShader.SetShaderConstant<single>('warp_glow', 1.0)
  else CurrentShader.SetShaderConstant<single>('warp_glow', 0.0);
  CurrentShader.SetShaderConstant<RVector3>('warp_color', RColor.Create(GLOW_COLOR_MAP[FColorIdentity]).RGB);
end;

function TMeshEffectWarp.Smooth(Step : single) : TMeshEffectWarp;
begin
  Result := self;
  FSmoothStep := Step;
end;

{ TMeshEffectInvisible }

constructor TMeshEffectInvisible.Create();
begin
  FUseGlowOverride := True;
  inherited Create(PATH_GRAPHICS_SHADER + 'Invisible.fx', '');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectInvisible.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectInvisible.Create()
  else Result := Effect;
  Result := inherited Clone(Result);
  with (Result as TMeshEffectInvisible) do
  begin
    FSmoothStep := self.FSmoothStep;
    FSpan := self.FSpan;
    FSpeed := self.FSpeed;
  end;
end;

procedure TMeshEffectInvisible.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
var
  SliceStart, SliceEnd : single;
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('inv_smooth', FSmoothStep);
  SliceStart := frac(TimeManager.GetFloatingTimestamp * FSpeed);
  CurrentShader.SetShaderConstant<single>('inv_start', SliceStart);
  SliceEnd := frac(TimeManager.GetFloatingTimestamp * FSpeed + FSpan);
  CurrentShader.SetShaderConstant<single>('inv_end', SliceEnd);
  if Stage = rsGlow then CurrentShader.SetShaderConstant<single>('inv_glow', 1.0)
  else CurrentShader.SetShaderConstant<single>('inv_glow', 0.0);
  CurrentShader.SetShaderConstant<RVector3>('inv_color', RColor.Create(GLOW_COLOR_MAP[FColorIdentity]).RGB);
end;

function TMeshEffectInvisible.Smooth(Step : single) : TMeshEffectInvisible;
begin
  Result := self;
  FSmoothStep := Step;
end;

function TMeshEffectInvisible.Span(Span : single) : TMeshEffectInvisible;
begin
  Result := self;
  FSpan := Span;
end;

function TMeshEffectInvisible.Speed(Speed : single) : TMeshEffectInvisible;
begin
  Result := self;
  FSpeed := Speed;
end;

{ TMeshEffectGlow }

constructor TMeshEffectGlow.Create(Duration : integer);
begin
  FUseGlowOverride := True;
  inherited;
  InitShader(PATH_GRAPHICS_SHADER + 'GlowOvershoot.fx');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectGlow.FixedColorIdentity(ColorIdentity : EnumEntityColor) : TMeshEffectGlow;
begin
  Result := self;
  FFixedColorIdentity := True;
  FFixedColor := ColorIdentity;
end;

function TMeshEffectGlow.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectGlow.Create(0)
  else Result := Effect;
  Result := inherited Clone(Result);
  TMeshEffectGlow(Result).FFixedColorIdentity := FFixedColorIdentity;
  TMeshEffectGlow(Result).FFixedColor := FFixedColor;
end;

procedure TMeshEffectGlow.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
var
  ColorIdentity : EnumEntityColor;
begin
  inherited;
  if Stage = rsGlow then
      CurrentShader.SetShaderConstant<single>('go_is_glow_stage', 1)
  else
      CurrentShader.SetShaderConstant<single>('go_is_glow_stage', 0);
  CurrentShader.SetShaderConstant<single>('go_overshoot', CurrentValue);
  if FFixedColorIdentity then
      ColorIdentity := FFixedColor
  else
      ColorIdentity := FColorIdentity;
  CurrentShader.SetShaderConstant<RVector3>('go_color', RColor.Create(GLOW_COLOR_MAP[ColorIdentity]).RGB);
end;

{ TMeshEffectSpherify }

constructor TMeshEffectSpherify.Create(Duration : integer);
begin
  inherited;
  FPowFactor := 1.0;
  InitShader(PATH_GRAPHICS_SHADER + 'Spherify.fx');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectSpherify.PowFactor(PowFactor : single) : TMeshEffectSpherify;
begin
  Result := self;
  FPowFactor := PowFactor;
end;

function TMeshEffectSpherify.SetFixedCenter(X, Y, Z : single) : TMeshEffectSpherify;
begin
  Result := self;
  FUseFixedCenter := True;
  FFixedCenter := RVector3.Create(X, Y, Z);
end;

function TMeshEffectSpherify.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectSpherify.Create(0)
  else Result := Effect;
  Result := inherited Clone(Result);
  with (Result as TMeshEffectSpherify) do
  begin
    FUseFixedCenter := self.FUseFixedCenter;
    FFixedCenter := self.FFixedCenter;
    FPowFactor := self.FPowFactor;
  end;
end;

procedure TMeshEffectSpherify.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('spherify', CurrentValue);
  CurrentShader.SetShaderConstant<single>('spherify_pow_factor', FPowFactor);
  if FUseFixedCenter then
      CurrentShader.SetShaderConstant<RVector3>('spherify_center', FMesh.Position + FFixedCenter)
  else
      CurrentShader.SetShaderConstant<RVector3>('spherify_center', FMesh.BoundingSphereTransformed.Center);
end;

{ TMeshEffectHideAndGlow }

constructor TMeshEffectHideAndGlow.Create(Duration : integer; const TextureFilename : string);
begin
  inherited Create(Duration);
  SetTexture(TextureFilename);
  InitShader(PATH_GRAPHICS_SHADER + 'HideAndGlow.fx');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectHideAndGlow.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectHideAndGlow.Create(0, '')
  else Result := Effect;
  Result := inherited Clone(Result);
end;

procedure TMeshEffectHideAndGlow.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  if Stage = rsGlow then CurrentShader.SetShaderConstant<single>('hag_is_glow_stage', 1)
  else CurrentShader.SetShaderConstant<single>('hag_is_glow_stage', 0);
  CurrentShader.SetShaderConstant<single>('hag_overshoot', CurrentValue);
  CurrentShader.SetShaderConstant<RVector3>('hag_color', RColor.Create(GLOW_COLOR_MAP[ColorIdentity]).RGB);

  CurrentShader.SetShaderConstant<single>('hag_visibility', CurrentValue(1));
end;

{ RMatrixAdjustments }

function RMatrixAdjustments.Apply(const a : RMatrix) : RMatrix;
begin
  Result := a;
  if BindSwapXY then Result.SwapXY;
  if BindSwapXZ then Result.SwapXZ;
  if BindSwapYZ then Result.SwapYZ;
  if BindInvertX then Result.Column[0] := -Result.Column[0];
  if BindInvertY then Result.Column[1] := -Result.Column[1];
  if BindInvertZ then Result.Column[2] := -Result.Column[2];
  if not Offset.IsZeroVector then
      Result := Result * RMatrix.CreateTranslation(Offset);
  if not Rotation.IsZeroVector then
      Result := Result * RMatrix.CreateRotationPitchYawRoll(Rotation);
end;

{ TCameraShakerComponent }

function TCameraShakerComponent.ActivateNow : TCameraShakerComponent;
begin
  Result := self;
  Shake;
end;

function TCameraShakerComponent.ActivateOnCreate : TCameraShakerComponent;
begin
  Result := self;
  FShakeOnCreate := True;
end;

function TCameraShakerComponent.ActivateOnDie : TCameraShakerComponent;
begin
  Result := self;
  FShakeOnDie := True;
end;

function TCameraShakerComponent.ActivateOnFire : TCameraShakerComponent;
begin
  Result := self;
  FShakeOnFire := True;
end;

function TCameraShakerComponent.ActivateOnFireWarhead : TCameraShakerComponent;
begin
  Result := self;
  FShakeOnFireWarhead := True;
end;

function TCameraShakerComponent.ActivateOnFree : TCameraShakerComponent;
begin
  Result := self;
  FShakeOnFree := True;
end;

function TCameraShakerComponent.ActivateOnLose : TCameraShakerComponent;
begin
  Result := self;
  FShakeOnLose := True;
end;

procedure TCameraShakerComponent.BeforeComponentFree;
begin
  if FShakeOnFree and assigned(Game) and not Game.IsShuttingDown then
      Shake;
  if FStopOnFree and assigned(Game) and not Game.IsShuttingDown then
      Stop;
  inherited;
end;

constructor TCameraShakerComponent.CreateGrouped(Entity : TEntity; Groups : TArray<byte>);
begin
  inherited;
  FDuration := DEFAULT_DURATION;
  FStrength := DEFAULT_STRENGTH;
  FWaves := DEFAULT_WAVES;
  FShakerPositions := TList < ISharedData < RVector3 >>.Create;
  FCreatedShaker := TList<TCameraShaker>.Create;
end;

function TCameraShakerComponent.Delay(DelayTime : integer) : TCameraShakerComponent;
begin
  Result := self;
  FDelay := DelayTime;
end;

destructor TCameraShakerComponent.Destroy;
begin
  FShakerPositions.Free;
  FCreatedShaker.Free;
  inherited;
end;

function TCameraShakerComponent.Duration(DurationMs : integer) : TCameraShakerComponent;
begin
  Result := self;
  FDuration := DurationMs;
end;

function TCameraShakerComponent.Global : TCameraShakerComponent;
begin
  Result := self;
  FGlobal := True;
end;

function TCameraShakerComponent.Invert : TCameraShakerComponent;
begin
  Result := self;
  FInvert := True;
end;

function TCameraShakerComponent.NoFade : TCameraShakerComponent;
begin
  Result := self;
  FNoFade := True;
end;

function TCameraShakerComponent.OnAfterDeserialization : boolean;
begin
  Result := True;
  if FShakeOnCreate then
      Shake;
end;

function TCameraShakerComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  if FShakeOnDie then
      Shake;
  if FStopOnDie then
      Stop;
end;

function TCameraShakerComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FShakeOnFire then
      Shake;
end;

function TCameraShakerComponent.OnFireWarhead(Targets : RParam) : boolean;
begin
  Result := True;
  if FShakeOnFireWarhead then
      Shake;
end;

function TCameraShakerComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  if FShakeOnLose and (Owner.TeamID = TeamID.AsInteger) then
      Shake;
end;

function TCameraShakerComponent.PresetRotationLight : TCameraShakerComponent;
begin
  Result := self
    .RotationShaker(0.005, 0.005, 0.02)
    .Strength(0.05)
    .Duration(350)
    .Waves(6);
end;

function TCameraShakerComponent.PresetRotationMedium : TCameraShakerComponent;
begin
  Result := self
    .RotationShaker(0.005, 0.005, 0.02)
    .Strength(0.1)
    .Duration(500)
    .Waves(8);
end;

function TCameraShakerComponent.PresetRotationStrong : TCameraShakerComponent;
begin
  Result := self
    .RotationShaker(0.005, 0.005, 0.02)
    .Strength(0.5)
    .Duration(500)
    .Waves(8);
end;

function TCameraShakerComponent.PresetVectorLight : TCameraShakerComponent;
begin
  Result := self
    .VectorShaker(0, -1, 0)
    .Strength(0.01)
    .Duration(350)
    .Waves(4);
end;

function TCameraShakerComponent.PresetVectorMedium : TCameraShakerComponent;
begin
  Result := self
    .VectorShaker(0, -1, 0)
    .Strength(0.02)
    .Duration(500)
    .Waves(4);
end;

function TCameraShakerComponent.PresetVectorStrong : TCameraShakerComponent;
begin
  Result := self
    .VectorShaker(0, -1, 0)
    .Strength(0.1)
    .Duration(500)
    .Waves(4);
end;

function TCameraShakerComponent.RotationShaker(Yaw, Pitch, Roll : single) : TCameraShakerComponent;
begin
  Result := self;
  FShakerType := stRotation;
  FVector := RVector3.Create(Yaw, Pitch, Roll);
  FStrength := 1.0;
end;

procedure TCameraShakerComponent.Shake;
var
  CameraShaker : TCameraShaker;
begin
  if Eventbus.Read(eiExiled, []).AsBoolean then Exit;
  case FShakerType of
    stRadial : CameraShaker := TCameraShakerRadial.Create(FDuration, True, FStrength).Delay(FDelay);
    stVector : CameraShaker := TCameraShakerVector.Create(FDuration, True, FVector * FStrength).Delay(FDelay);
    stRotation : CameraShaker := TCameraShakerRotation.Create(FDuration, True, FVector * FStrength).Delay(FDelay);
  else
    raise ENotImplemented.Create('TCameraShakerComponent.Shake: Unknown shaker type!');
  end;
  CameraShaker.Invert := FInvert;
  CameraShaker.Waves := FWaves;
  CameraShaker.Global := FGlobal;
  CameraShaker.Position.SetData(Owner.DisplayPosition);
  if FNoFade then
      CameraShaker.NoFade;
  FShakerPositions.Add(CameraShaker.Position);
  GFXD.MainScene.Camera.AddShaker(CameraShaker);
  FCreatedShaker.Add(CameraShaker);
end;

procedure TCameraShakerComponent.Stop;
var
  i : integer;
begin
  for i := 0 to FCreatedShaker.Count - 1 do
      GFXD.MainScene.Camera.RemoveShaker(FCreatedShaker[i]);
end;

function TCameraShakerComponent.StopOnDie : TCameraShakerComponent;
begin
  Result := self;
  FStopOnDie := True;
end;

function TCameraShakerComponent.StopOnFree : TCameraShakerComponent;
begin
  Result := self;
  FStopOnFree := True;
end;

function TCameraShakerComponent.Strength(Radius : single) : TCameraShakerComponent;
begin
  Result := self;
  FStrength := Radius;
end;

function TCameraShakerComponent.VectorShaker(VectorX, VectorY, VectorZ : single) : TCameraShakerComponent;
begin
  Result := self;
  FShakerType := stVector;
  FVector := RVector3.Create(VectorX, VectorY, VectorZ).Normalize;
end;

function TCameraShakerComponent.Waves(Waves : integer) : TCameraShakerComponent;
begin
  Result := self;
  FWaves := Waves;
end;

{ TConditionalMeshTextureResource }

function TConditionalMeshTextureResource.Check(Component : TEntityComponent) : boolean;
var
  Resource : RParam;
begin
  Resource := Component.Owner.Balance(ResourceType, ComponentGroup);
  Result := not Resource.IsEmpty and ResourceCompare(ResourceType, Resource, Comparator, ReferenceValue);
end;

{ TConditionalMeshTextureTeam }

function TConditionalMeshTextureTeam.Check(Component : TEntityComponent) : boolean;
begin
  Result := GetDisplayedTeam(Component.Owner.TeamID) = TargetTeamID;
end;

{ TMeshEffectIce }

constructor TMeshEffectIce.Create(Duration : integer);
begin
  inherited;
  InitShader(PATH_GRAPHICS_SHADER + 'IceShader.fx');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectIce.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectIce.Create(0)
  else Result := Effect;
  Result := inherited Clone(Result);
end;

procedure TMeshEffectIce.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('ice_progress', CurrentValue);
end;

{ TMeshEffectColorOverlay }

function TMeshEffectColorOverlay.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectColorOverlay.Create(FColor.AsCardinal)
  else Result := Effect;
  Result := inherited Clone(Result);
  (Result as TMeshEffectColorOverlay).FColor := FColor;
end;

constructor TMeshEffectColorOverlay.Create(const Color : cardinal);
begin
  inherited Create();
  FColor := RColor.Create(Color);
  InitShader(PATH_GRAPHICS_SHADER + 'ColorOverlay.fx');
  FOrderValue := ORDER_VALUE;
end;

procedure TMeshEffectColorOverlay.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<RVector4>('co_color', FColor.RGBA);
end;

{ TVertexTraceComponent }

procedure TVertexTraceComponent.Activate;
begin
  Apply;
  FVertexTrace.StartTracking;
  if assigned(FDeactivateAfterTime) then FDeactivateAfterTime.Start;
end;

function TVertexTraceComponent.ActivateNow : TVertexTraceComponent;
begin
  Result := self;
  Activate;
end;

function TVertexTraceComponent.ActivateOnFire : TVertexTraceComponent;
begin
  Result := self;
  FActivateOnFire := True;
end;

function TVertexTraceComponent.ActivateOnPreFire : TVertexTraceComponent;
begin
  Result := self;
  FActivateOnPreFire := True;
end;

function TVertexTraceComponent.Additive : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.BlendMode := BlendAdditive;
end;

procedure TVertexTraceComponent.Apply;
begin
  inherited;
  if FFixedOrientation then
      FVertexTrace.Up := FFixedUp;
  if FLocalSpell then
      FVertexTrace.BasePosition := Owner.Position.X0Y;
  FVertexTrace.Position := FBindMatrix.Translation;
end;

function TVertexTraceComponent.Color(Color : cardinal) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.Color := RColor.Create(Color);
end;

constructor TVertexTraceComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FVertexTrace := TVertexTrace.Create(VertexEngine, nil, RVector3.ZERO, 0.5, 0.5, 1.5, 3.0, 1.0);
  FVertexTrace.OwnsTexture := True;
  FVertexTrace.Visible := True;
end;

procedure TVertexTraceComponent.Deactivate;
begin
  FVertexTrace.StopTracking;
end;

function TVertexTraceComponent.DeactivateAfterTime(TimeMs : integer) : TVertexTraceComponent;
begin
  Result := self;
  assert(not assigned(FDeactivateAfterTime), 'TVertexTraceComponent.DeactivateAfterTime: Only one time allowed!');
  FDeactivateAfterTime := TTimer.CreatePaused(TimeMs);
end;

function TVertexTraceComponent.DeactivateOnMoveTo : TVertexTraceComponent;
begin
  Result := self;
  FDeactivateOnMoveTo := True;
end;

destructor TVertexTraceComponent.Destroy;
begin
  FDeactivateAfterTime.Free;
  if assigned(ClientGame) and assigned(ClientGame.TraceManager) then
      ClientGame.TraceManager.AddTrace(FVertexTrace, Eventbus.Read(eiSpeed, []).AsSingleDefault(Max(FRollUpSpeed, 0.01)))
  else FVertexTrace.Free;
  inherited;
end;

function TVertexTraceComponent.FadeLength(FadeLength : single) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.FadeLength := FadeLength;
end;

function TVertexTraceComponent.FadeWidening(FadeWidening : single) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.FadeWidening := FadeWidening;
end;

procedure TVertexTraceComponent.Idle;
begin
  inherited;
  FVertexTrace.Visible := IsVisible;
  if assigned(FDeactivateAfterTime) and FDeactivateAfterTime.Expired then Deactivate;
  FVertexTrace.RollUp(FRollUpSpeed * GameTimeManager.ZDiff);
  FVertexTrace.AddRenderJob;
end;

function TVertexTraceComponent.LocalSpace : TVertexTraceComponent;
begin
  Result := self;
  FLocalSpell := True;
end;

function TVertexTraceComponent.MaxLength(MaxLength : single) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.MaxLength := MaxLength;
end;

function TVertexTraceComponent.OnAfterCreate : boolean;
begin
  Result := True;
  if not FActivateOnFire then Activate;
end;

function TVertexTraceComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  Deactivate;
end;

function TVertexTraceComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FActivateOnFire then Activate;
end;

function TVertexTraceComponent.OnMoveTo(Target, Range : RParam) : boolean;
begin
  Result := True;
  if FDeactivateOnMoveTo then Deactivate;
end;

function TVertexTraceComponent.OnPreFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FActivateOnPreFire then Activate;
end;

function TVertexTraceComponent.RollUpSpeed(RollUpSpeed : single) : TVertexTraceComponent;
begin
  Result := self;
  FRollUpSpeed := RollUpSpeed / 1000;
end;

function TVertexTraceComponent.SamplingDistance(SamplingDistance : single) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.TrackSetDistance := SamplingDistance;
end;

function TVertexTraceComponent.Width(Width : single) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.Trackwidth := Width;
end;

function TVertexTraceComponent.Texture(const Filename : string) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.Texture := TTexture.CreateTextureFromFile(PATH_GRAPHICS + Filename, GFXD.Device3D, mhGenerate, True);
end;

function TVertexTraceComponent.TexturePerDistance(TexturePerDistance : single) : TVertexTraceComponent;
begin
  Result := self;
  FVertexTrace.TexturePerDistance := TexturePerDistance;
end;

function TVertexTraceComponent.VisibleWithResource(ResourceID : EnumResource) : TVertexTraceComponent;
begin
  Result := self;
  FVisibleWithResource := ResourceID;
end;

{ TPositionerRotationComponent }

constructor TPositionerRotationComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>);
begin
  inherited;
  FTargetGroup := ComponentGroup;
  FRotationTimer := TTimer.Create(1000);
  FFactor := RVector3.ONE;
end;

destructor TPositionerRotationComponent.Destroy;
begin
  FRotationTimer.Free;
  FFadeIn.Free;
  inherited;
end;

function TPositionerRotationComponent.Factor(X, Y, Z : single) : TPositionerRotationComponent;
begin
  Result := self;
  FFactor := RVector3.Create(X, Y, Z);
end;

function TPositionerRotationComponent.FadeIn(Time : integer) : TPositionerRotationComponent;
begin
  Result := self;
  FFadeIn := TTimer.CreateAndStart(Time);
end;

function TPositionerRotationComponent.OnDisplayPosition(PreviousPosition : RParam) : RParam;
var
  Position, NewPosition : RVector3;
  Radius : single;
begin
  if not IsLocalCall(FTargetGroup) then
      Exit(PreviousPosition);
  if (FTargetGroup <> []) and PreviousPosition.IsEmpty then
      Position := Owner.DisplayPosition
  else
      Position := PreviousPosition.AsVector3;

  Radius := FRadius;
  if FScaleByEvent then
  begin
    if FScaleEvent = eiCollisionRadius then
        Radius := Radius + Owner.CollisionRadius
    else
        Radius := Radius + Eventbus.ReadHierarchic(FScaleEvent, [], ComponentGroup).AsSingle;
  end;
  NewPosition := RVector3.Create(Radius, 0, 0).RotatePitchYawRoll(FRotationOffset + (FRotationSpeed * (FRotationTimer.ZeitDiffProzent + FPhase)));
  NewPosition := NewPosition * FFactor;
  NewPosition := RMatrix.CreateSaveBase(Owner.DisplayFront, Owner.DisplayUp) * NewPosition;
  NewPosition := NewPosition + Position;
  if assigned(FFadeIn) and not FFadeIn.Expired then
      NewPosition := Position.Lerp(NewPosition, FFadeIn.ZeitDiffProzent(True));
  Result := NewPosition;
end;

function TPositionerRotationComponent.Phase(Phase : single) : TPositionerRotationComponent;
begin
  Result := self;
  FPhase := Phase;
end;

function TPositionerRotationComponent.Radius(Radius : single) : TPositionerRotationComponent;
begin
  Result := self;
  FRadius := Radius;
end;

function TPositionerRotationComponent.RadiusFromEvent(ScaleEvent : EnumEventIdentifier) : TPositionerRotationComponent;
begin
  Result := self;
  FScaleByEvent := True;
  FScaleEvent := ScaleEvent;
end;

function TPositionerRotationComponent.RotationOffset(RotationOffsetX, RotationOffsetY, RotationOffsetZ : single) : TPositionerRotationComponent;
begin
  Result := self;
  FRotationOffset.X := RotationOffsetX;
  FRotationOffset.Y := RotationOffsetY;
  FRotationOffset.Z := RotationOffsetZ;
end;

function TPositionerRotationComponent.RotationSpeed(RotationSpeedX, RotationSpeedY, RotationSpeedZ : single) : TPositionerRotationComponent;
begin
  Result := self;
  FRotationSpeed := RVector3.Create(RotationSpeedX, RotationSpeedY, RotationSpeedZ);
end;

function TPositionerRotationComponent.TargetGroup(Group : TArray<byte>) : TPositionerRotationComponent;
begin
  Result := self;
  FTargetGroup := ByteArrayToComponentGroup(Group);
end;

{ TMeshEffectSoulExtract }

constructor TMeshEffectSoulExtract.Create(Duration : integer);
begin
  inherited;
  FNeedOwnPass := [rsEffects];
  FOwnPasses := 1;
  InitShader(PATH_GRAPHICS_SHADER + 'SoulExtract.fx');
end;

function TMeshEffectSoulExtract.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectSoulExtract.Create(0)
  else Result := Effect;
  Result := inherited Clone(Result);
end;

procedure TMeshEffectSoulExtract.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('soul_progress', CurrentValue);
  CurrentShader.SetShaderConstant<single>('soul_height', FMesh.BoundingBoxTransformed.HalfExtents.Y);
  CurrentShader.SetShaderConstant<RVector3>('soul_target', FMesh.BoundingBoxTransformed.Top);
end;

{ TMeshEffectSoulGain }

constructor TMeshEffectSoulGain.Create(Duration : integer);
begin
  inherited;
  FColor := $FFBFFDED;
  FRadius := 0.3;
  FNeedOwnPass := [rsEffects];
  FOwnPasses := 1;
  InitShader(PATH_GRAPHICS_SHADER + 'SoulGain.fx');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectSoulGain.Radius(Radius : single) : TMeshEffectSoulGain;
begin
  Result := self;
  FRadius := Radius;
end;

function TMeshEffectSoulGain.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectSoulGain.Create(0)
  else Result := Effect;
  Result := inherited Clone(Result);
  (Result as TMeshEffectSoulGain).FColor := FColor;
  (Result as TMeshEffectSoulGain).FRadius := FRadius;
end;

function TMeshEffectSoulGain.Color(Color : cardinal) : TMeshEffectSoulGain;
begin
  Result := self;
  FColor := RColor.Create(Color);
end;

procedure TMeshEffectSoulGain.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('soul_gain_progress', CurrentValue);
  CurrentShader.SetShaderConstant<single>('soul_gain_radius', FRadius);
  CurrentShader.SetShaderConstant<RVector4>('soul_color', FColor.RGBA);
end;

{ TMeshEffectTint }

function TMeshEffectTint.Additive : TMeshEffectTint;
begin
  Result := self;
  FAdditive := True;
end;

function TMeshEffectTint.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectTint.Create(FTimer.Interval, FColor.AsCardinal)
  else Result := Effect;
  Result := inherited Clone(Result);
  (Result as TMeshEffectTint).FColor := FColor;
  (Result as TMeshEffectTint).FAdditive := FAdditive;
end;

constructor TMeshEffectTint.Create(Duration, Color : cardinal);
begin
  inherited Create(Duration);
  FColor := RColor.Create(Color);
  InitShader(PATH_GRAPHICS_SHADER + 'ColorOverlay.fx');
  FOrderValue := ORDER_VALUE;
end;

procedure TMeshEffectTint.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<RVector4>('co_color', FColor.RGBA * RVector4.Create(1, 1, 1, CurrentValue));
  CurrentShader.SetShaderConstant<boolean>('co_additive', FAdditive);
end;

{ TMeshEffectMelt }

function TMeshEffectMelt.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectMelt.Create(0)
  else Result := Effect;
  Result := inherited Clone(Result);
  with (Result as TMeshEffectMelt) do
  begin
    FMeltStep := self.FMeltStep;
    FMeltHeightOverride := self.FMeltHeightOverride;
  end;
end;

constructor TMeshEffectMelt.Create(Duration : integer);
begin
  inherited;
  FMeltStep := 0.1;
  FMeltHeightOverride := -1;
  InitShader(PATH_GRAPHICS_SHADER + 'Melt.fx');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectMelt.Height(Height : single) : TMeshEffectMelt;
begin
  Result := self;
  FMeltHeightOverride := Height;
end;

procedure TMeshEffectMelt.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('melt_progress', CurrentValue);
  if FMeltHeightOverride < 0 then
      CurrentShader.SetShaderConstant<single>('melt_model_height', FMesh.BoundingBoxTransformed.Max.Y)
  else
      CurrentShader.SetShaderConstant<single>('melt_model_height', FMeltHeightOverride);
  CurrentShader.SetShaderConstant<single>('melt_step', FMeltStep);
  CurrentShader.SetShaderConstant<RVector3>('melt_ref', FMesh.Position);
end;

function TMeshEffectMelt.Step(Step : single) : TMeshEffectMelt;
begin
  Result := self;
  FMeltStep := Step;
end;

{ TOrienterFrontComponent }

function TOrienterFrontComponent.Front(FrontX, FrontY, FrontZ : single) : TOrienterFrontComponent;
begin
  Result := self;
  FFront := RVector3.Create(FrontX, FrontY, FrontZ);
end;

function TOrienterFrontComponent.OnDisplayFront(const Previous : RParam) : RParam;
begin
  if not IsLocalCall then Exit(Previous);
  Result := FFront;
end;

{ TMeshEffectGhost }

function TMeshEffectGhost.Additive : TMeshEffectGhost;
begin
  Result := self;
  FAdditive := True;
end;

function TMeshEffectGhost.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectGhost.Create()
  else Result := Effect;
  Result := inherited Clone(Result);
  (Result as TMeshEffectGhost).FColor := FColor;
  (Result as TMeshEffectGhost).FAdditive := FAdditive;
  (Result as TMeshEffectGhost).FFactor := FFactor;
  (Result as TMeshEffectGhost).FOffset := FOffset;
end;

function TMeshEffectGhost.Color(Color : cardinal) : TMeshEffectGhost;
begin
  Result := self;
  FColor := RColor.Create(Color);
end;

constructor TMeshEffectGhost.Create();
begin
  inherited Create(PATH_GRAPHICS_SHADER + 'Ghost.fx', '');
  FOrderValue := ORDER_VALUE;
  FFactor := 1.0;
end;

function TMeshEffectGhost.Factor(Factor : single) : TMeshEffectGhost;
begin
  Result := self;
  FFactor := Factor;
end;

function TMeshEffectGhost.Offset(Offset : single) : TMeshEffectGhost;
begin
  Result := self;
  FOffset := Offset;
end;

procedure TMeshEffectGhost.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<RVector4>('ghost_color', FColor.RGBA);
  CurrentShader.SetShaderConstant<single>('ghost_factor', FFactor);
  CurrentShader.SetShaderConstant<single>('ghost_offset', FOffset);
  CurrentShader.SetShaderConstant<boolean>('ghost_additive', FAdditive);
end;

{ TLinkRayVisualizerComponent }

constructor TLinkRayVisualizerComponent.CreateGrouped(Owner : TEntity; ComponentGroup : TArray<byte>);
begin
  inherited CreateGrouped(Owner, ComponentGroup);
  FDestSubPosition := BIND_ZONE_HIT_ZONE;
end;

function TLinkRayVisualizerComponent.CurrentEndPosition : RVector3;
var
  TargetEntity : TEntity;
begin
  if EndPos.IsEmpty then Exit(RVector3.ZERO);
  if EndPos.TryGetTargetEntity(TargetEntity) and (FDestSubPosition <> '') then
      Result := TargetEntity.Eventbus.Read(eiSubPositionByString, [FDestSubPosition], [0, 1]).AsType<RMatrix>.Translation
  else
      Result := EndPos.GetTargetPosition.X0Y;
  Result := Result + FEndZoneOffset;
end;

function TLinkRayVisualizerComponent.CurrentStartPosition : RVector3;
begin
  Result := Eventbus.Read(eiDisplayPosition, [], ComponentGroup).AsVector3 + FStartZoneOffset;
end;

function TLinkRayVisualizerComponent.OnAfterDeserialization : boolean;
var
  Targets : ATarget;
begin
  Result := True;
  if EndPos.IsEmpty then
  begin
    Targets := Eventbus.Read(eiLinkDest, []).AsATarget;
    if Length(Targets) > 0 then
        EndPos := Targets[0];
  end;
end;

function TLinkRayVisualizerComponent.SetDestSubPosition(const SubPosition : string) : TVertexRayVisualizerComponent;
begin
  Result := self;
  FDestSubPosition := SubPosition;
end;

{ TConditionalMeshTextureUnitProperty }

function TConditionalMeshTextureUnitProperty.Check(Component : TEntityComponent) : boolean;
begin
  Result := MustHaveAny <= Component.Owner.UnitProperties;
end;

{ TMeshEffectStone }

constructor TMeshEffectStone.Create(Duration : integer);
begin
  inherited;
  InitShader(PATH_GRAPHICS_SHADER + 'StoneShader.fx');
  FOrderValue := ORDER_VALUE;
end;

function TMeshEffectStone.Clone(const Effect : TMeshEffect) : TMeshEffect;
begin
  if not assigned(Effect) then Result := TMeshEffectStone.Create(0)
  else Result := Effect;
  Result := inherited Clone(Result);
end;

procedure TMeshEffectStone.SetUpShader(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);
begin
  inherited;
  CurrentShader.SetShaderConstant<single>('stone_progress', CurrentValue);
end;

initialization

ScriptManager.ExposeConstant('ANIMATION_SPAWN', ANIMATION_SPAWN);
ScriptManager.ExposeConstant('ANIMATION_DEATH', ANIMATION_DEATH);
ScriptManager.ExposeConstant('ANIMATION_WALK', ANIMATION_WALK);
ScriptManager.ExposeConstant('ANIMATION_STAND', ANIMATION_STAND);
ScriptManager.ExposeConstant('ANIMATION_ATTACK', ANIMATION_ATTACK);
ScriptManager.ExposeConstant('ANIMATION_ATTACK2', ANIMATION_ATTACK2);
ScriptManager.ExposeConstant('ANIMATION_ATTACK_AIR', ANIMATION_ATTACK_AIR);
ScriptManager.ExposeConstant('ANIMATION_ATTACK_AIR2', ANIMATION_ATTACK_AIR2);
ScriptManager.ExposeConstant('ANIMATION_ATTACK_LOOP', ANIMATION_ATTACK_LOOP);
ScriptManager.ExposeConstant('ANIMATION_ABILITY_1', ANIMATION_ABILITY_1);

ScriptManager.ExposeType(TypeInfo(EnumInterpolationMode));
ScriptManager.ExposeType(TypeInfo(EnumMeshTexture));

ScriptManager.ExposeClass(TOrienterFrontInverterComponent);
ScriptManager.ExposeClass(TOrienterMovementComponent);
ScriptManager.ExposeClass(TOrienterSmoothRotateComponent);
ScriptManager.ExposeClass(TOrienterAutoRotationComponent);
ScriptManager.ExposeClass(TOrienterTargetComponent);
ScriptManager.ExposeClass(TOrienterFrontComponent);

ScriptManager.ExposeClass(TPositionerSplineComponent);
ScriptManager.ExposeClass(TPositionerOffsetComponent);
ScriptManager.ExposeClass(TPositionerAttacherComponent);
ScriptManager.ExposeClass(TPositionerMeteorComponent);
ScriptManager.ExposeClass(TPositionerRotationComponent);
ScriptManager.ExposeClass(TAnimatorComponent);

ScriptManager.ExposeClass(TAnimationComponent);
ScriptManager.ExposeClass(TLinkBulletVisualizerComponent);
ScriptManager.ExposeClass(TVertexRayVisualizerComponent);
ScriptManager.ExposeClass(TLinkRayVisualizerComponent);
ScriptManager.ExposeClass(TProductionPreviewComponent);

ScriptManager.ExposeClass(TVisualizerComponent);
ScriptManager.ExposeClass(TVertexTraceComponent);
ScriptManager.ExposeClass(TVertexQuadComponent);
ScriptManager.ExposeClass(TPointLightComponent);
ScriptManager.ExposeClass(TParticleEffectComponent);
ScriptManager.ExposeClass(TMeshComponent);

ScriptManager.ExposeClass(TMeshEffectComponent);
ScriptManager.ExposeClass(TMeshEffect);
ScriptManager.ExposeClass(TMeshEffectGeneric);
ScriptManager.ExposeClass(TMeshEffectMetal);
ScriptManager.ExposeClass(TMeshEffectMatcap);
ScriptManager.ExposeClass(TMeshEffectTeamColor);
ScriptManager.ExposeClass(TMeshEffectSpawn);
ScriptManager.ExposeClass(TMeshEffectSpawnerSpawn);
ScriptManager.ExposeClass(TMeshEffectSlidingTexture);
ScriptManager.ExposeClass(TMeshEffectWobble);
ScriptManager.ExposeClass(TMeshEffectWithTimekeys);
ScriptManager.ExposeClass(TMeshEffectGlow);
ScriptManager.ExposeClass(TMeshEffectGhost);
ScriptManager.ExposeClass(TMeshEffectSpherify);
ScriptManager.ExposeClass(TMeshEffectMelt);
ScriptManager.ExposeClass(TMeshEffectWarp);
ScriptManager.ExposeClass(TMeshEffectVoid);
ScriptManager.ExposeClass(TMeshEffectHideAndGlow);
ScriptManager.ExposeClass(TMeshEffectIce);
ScriptManager.ExposeClass(TMeshEffectStone);
ScriptManager.ExposeClass(TMeshEffectColorOverlay);
ScriptManager.ExposeClass(TMeshEffectSoulExtract);
ScriptManager.ExposeClass(TMeshEffectSoulGain);
ScriptManager.ExposeClass(TMeshEffectTint);
ScriptManager.ExposeClass(TMeshEffectInvisible);

ScriptManager.ExposeClass(TVisualModificatorSizeComponent);

ScriptManager.ExposeClass(TCameraShakerComponent);

end.
