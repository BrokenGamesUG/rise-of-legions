unit BaseConflict.EntityComponents.Client.Sound;

interface

uses
  // ------- Delphi ---------------
  System.Generics.Collections,
  System.SysUtils,
  System.RegularExpressions,
  System.Math,
  // ------- ThirdParty -----------
  FMOD.Common,
  FMOD.Studio.Common,
  FMOD.Studio.Classes,
  // ------- Engine ---------------
  Engine.Core,
  Engine.Vertex,
  Engine.GUI,
  Engine.Script,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Terrain,
  Engine.Math,
  Engine.Math.Collision3D,
  Engine.Log,
  // ------- Game --------
  BaseConflict.Map,
  BaseConflict.Game,
  BaseConflict.Constants,
  BaseConflict.Constants.Client,
  BaseConflict.Globals,
  BaseConflict.Types.Shared,
  BaseConflict.Types.Target,
  BaseConflict.Entity,
  BaseConflict.EntityComponents.Shared,
  BaseConflict.EntityComponents.Client,
  BaseConflict.Settings.Client,
  BaseConflict.Classes.Client;

type

  {$RTTI INHERIT}
  /// <summary>
  /// Component that plays a sound in reaction to the eiFire event.
  /// </summary>
  TSoundComponent = class(TEntityComponent)
    protected
      FSoundEvents : TObjectList<TFMODEventInstance>;
      FEventPath : string;
      FTargetPosition : RVector3;
      FStopGroupSet, FIsLoop, FIsLooping, FIsPiece : boolean;
      FStopGroup, FTriggerGroup, FCheckGroup : SetComponentGroup;
      FCheckOption : EnumClientOption;
      FOnFire, FOnCreate, FOnFree, FOnDie, FOnWarhead, FUsePositionOfTarget, FOnLoseHealth, FOnPreFire, FOnLose : boolean;
      FStopOnFire, FStopOnFree : boolean;
      FDelay : TTimer;
      FParameterBindings : TDictionary<EnumResource, string>;
      function IsTriggerEvent : boolean;
      function IsStopEvent : boolean;
      function TryGetFreeInstance(out Instance : TFMODEventInstance) : boolean;
      function Check : boolean;
      function CheckTargets(Targets : RParam) : boolean;
      procedure UpdateParameter(const Parameter : string; Value : single);
      procedure UpdatePosition(Instance : TFMODEventInstance);
      /// <summary> Main method called be every eventhandler (e.g. OnFire, OnDie) and do the magic (set volume, play the sound etc.)</summary>
      procedure Play();
      procedure Stop();
      procedure BeforeComponentFree; override;
    published
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      function OnIdle() : boolean;
      [XEvent(eiResourceBalance, epLower, etWrite)]
      function OnWriteHealth(ResourceID : RParam; Amount : RParam) : boolean;
      [XEvent(eiAfterCreate, epLast, etTrigger)]
      function OnAfterDeserialization() : boolean;
      [XEvent(eiFire, epLast, etTrigger)]
      function OnFire(Targets : RParam) : boolean;
      [XEvent(eiPreFire, epLast, etTrigger)]
      function OnPreFire(Targets : RParam) : boolean;
      [XEvent(eiFireWarhead, epLast, etTrigger)]
      function OnFireWarhead(Targets : RParam) : boolean;
      [XEvent(eiDie, epLast, etTrigger)]
      function OnDie(KillerID, KillerCommanderID : RParam) : boolean;
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      function OnLose(TeamID : RParam) : boolean;
    public
      constructor Create(Owner : TEntity; EventPath : string); reintroduce;
      constructor CreateGrouped(Owner : TEntity; Group : TArray<byte>; EventPath : string); reintroduce;
      /// <summary> If set, the sounded thing is a sub part of the entity with it's own position and orientation. </summary>
      function IsPiece : TSoundComponent;
      function IsLoop : TSoundComponent;
      function StopGroup(const StopGroup : TArray<byte>) : TSoundComponent;
      function CheckGroup(const CheckGroup : TArray<byte>) : TSoundComponent;
      function CheckOption(const Option : EnumClientOption) : TSoundComponent;
      function TriggerOnCreate() : TSoundComponent;
      function TriggerNow() : TSoundComponent;
      function TriggerOnFire() : TSoundComponent;
      function TriggerOnPreFire() : TSoundComponent;
      function TriggerOnFireWarhead() : TSoundComponent;
      function TriggerOnLose() : TSoundComponent;
      function TriggerOnLoseHealth() : TSoundComponent;
      function StopOnFire() : TSoundComponent;
      function StopOnFree() : TSoundComponent;
      function TriggerOnFree() : TSoundComponent;
      function TriggerOnDie() : TSoundComponent;
      function UsePositionOfTarget() : TSoundComponent;
      function BindParameterToResource(const ParameterName : string; Resource : EnumResource) : TSoundComponent;
      /// <summary> The sound will be delayed by some time after the trigger. </summary>
      function Delay(const DelayMs : Integer) : TSoundComponent;
      destructor Destroy; override;
  end;

  EnumSoundEvent = (
    seClick, seError, seCardPlayError, seHover, seEnterQueue, seReward,
    seClientStartUp, seCardboxOpen, seCardAscension, sePlayerLevelUp, seCardXPPush, seShopPurchase,
    seCardUnlock, seDialogOpen, seDialogClose, seAnnouncementStage, seAnnouncementShowdown
    );

const

  SOUND_EVENT_PATHS : array [EnumSoundEvent] of string = (
    'event:/ui/button/generic',
    'event:/ui/meta/error',
    'event:/ui/card/play_error',
    'event:/ui/button/hover',
    'event:/ui/meta/enter_queue',
    'event:/ui/meta/reward',
    'event:/ui/meta/client_startup',
    'event:/ui/meta/card_box_open',
    'event:/ui/meta/card_ascension',
    'event:/ui/meta/player_level_up',
    'event:/ui/meta/card_push_xp',
    'event:/ui/meta/shop_purchase',
    'event:/ui/meta/card_unlock',
    'event:/ui/meta/dialog_open',
    'event:/ui/meta/dialog_close',
    'event:/ui/core/stage',
    'event:/ui/core/showdown'
    );

type

  /// <summary> Component for the global entity that controls settings and global soundeffects like "click". </summary>
  TGlobalSoundManagerComponent = class(TEntityComponent)
    protected
      FSounds : array [EnumSoundEvent] of TFMODEventInstance;
      procedure OnGuiClick(const Sender : RGUIEvent);
      procedure HandleOption(Option : EnumClientOption);
    published
      [XEvent(eiClientOption, epLast, etTrigger, esGlobal)]
      /// <summary> Adjusts sound levels if user change any sound setting. </summary>
      function OnClientOption(Option : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      function PlaySound(const SoundEvent : EnumSoundEvent) : boolean;
      // fancy properties only for easier access to play sounds without having to declare every method
      property PlayClick : boolean index seClick read PlaySound;
      property PlayError : boolean index seError read PlaySound;
      property PlayCardError : boolean index seCardPlayError read PlaySound;
      property PlayHover : boolean index seHover read PlaySound;
      property PlayEnterQueue : boolean index seEnterQueue read PlaySound;
      property PlayReward : boolean index seReward read PlaySound;
      property PlayClientStartUp : boolean index seClientStartUp read PlaySound;
      property PlayCardboxOpen : boolean index seCardboxOpen read PlaySound;
      property PlayCardAscension : boolean index seCardAscension read PlaySound;
      property PlayPlayerLevelUp : boolean index sePlayerLevelUp read PlaySound;
      property PlayCardXPPush : boolean index seCardXPPush read PlaySound;
      property PlayShopPurchase : boolean index seShopPurchase read PlaySound;
      property PlayCardUnlock : boolean index seCardUnlock read PlaySound;
      property PlayDialogOpen : boolean index seDialogOpen read PlaySound;
      property PlayDialogClose : boolean index seDialogClose read PlaySound;
      property PlayAnnouncementStage : boolean index seAnnouncementStage read PlaySound;
      property PlayAnnouncementShowdown : boolean index seAnnouncementShowdown read PlaySound;
      destructor Destroy; override;
  end;

  /// <summary> Component for the game entity that controls the background music and also manage music
  /// if game is finished.</summary>
  TGameSoundManagerComponent = class(TEntityComponent)
    protected
      FMusicEvent : TFMODEventInstance;
      FLooseEvent, FWinEvent : TFMODEventInstance;
      /// <summary> Returns the intensity level of the current game</summary>
      function RetrieveIntensityLevel : single;
    published
      [XEvent(eiGameCommencing, epLast, etTrigger, esGlobal)]
      /// <summary> Start music if game starts. </summary>
      function OnGameCommencing() : boolean;
      [XEvent(eiIdle, epMiddle, etTrigger, esGlobal)]
      function OnIdle() : boolean;
      [XEvent(eiLose, epLast, etTrigger, esGlobal)]
      /// <summary> Play loose or win cue if depends on team of current player.</summary>
      function OnLose(TeamID : RParam) : boolean;
    public
      constructor Create(Owner : TEntity); override;
      destructor Destroy; override;
  end;

implementation

uses
  {$IFNDEF MAPEDITOR}
  BaseConflictMainUnit,
  {$ENDIF}
  BaseConflict.Globals.Client;

function Vector3ToFMODVector(const Vector3 : RVector3) : FMOD_VECTOR;
begin
  Result.x := Vector3.x;
  Result.y := Vector3.y;
  Result.z := Vector3.z;
end;

{ TSoundComponent }

procedure TSoundComponent.BeforeComponentFree;
begin
  if FOnFree and assigned(Game) and not Game.IsShuttingDown then
      Play();
  inherited;
end;

function TSoundComponent.BindParameterToResource(const ParameterName : string; Resource : EnumResource) : TSoundComponent;
begin
  Result := self;
  FParameterBindings.Add(Resource, ParameterName);
end;

function TSoundComponent.Check : boolean;
begin
  Result := (FCheckGroup = []) or assigned(FDelay);
  if not Result then
      Result := Eventbus.Read(eiIsReady, [], FCheckGroup).AsBooleanDefaultTrue;
end;

function TSoundComponent.CheckGroup(const CheckGroup : TArray<byte>) : TSoundComponent;
begin
  Result := self;
  FCheckGroup := ByteArrayToComponentGroup(CheckGroup);
end;

function TSoundComponent.CheckOption(const Option : EnumClientOption) : TSoundComponent;
begin
  Result := self;
  FCheckOption := Option;
end;

function TSoundComponent.CheckTargets(Targets : RParam) : boolean;
begin
  Result := FCheckGroup = [];
  if not Result then
      Result := Eventbus.Read(eiWelaTargetPossible, [Targets], FCheckGroup).AsRTargetValidity.IsValid;
end;

constructor TSoundComponent.Create(Owner : TEntity; EventPath : string);
begin
  CreateGrouped(Owner, [], EventPath);
end;

constructor TSoundComponent.CreateGrouped(Owner : TEntity; Group : TArray<byte>; EventPath : string);
begin
  inherited CreateGrouped(Owner, Group);
  FParameterBindings := TDictionary<EnumResource, string>.Create;
  FSoundEvents := TObjectList<TFMODEventInstance>.Create;
  FTriggerGroup := ComponentGroup;
  FEventPath := EventPath;
end;

function TSoundComponent.Delay(const DelayMs : Integer) : TSoundComponent;
begin
  Result := self;
  FDelay := TTimer.CreatePaused(DelayMs);
end;

destructor TSoundComponent.Destroy;
begin
  if FStopOnFree then
      Stop;
  FSoundEvents.Free;
  FParameterBindings.Free;
  FDelay.Free;
  inherited;
end;

function TSoundComponent.TryGetFreeInstance(out Instance : TFMODEventInstance) : boolean;
var
  i : Integer;
  newInstance : TFMODEventInstance;
begin
  Result := False;
  // if IsLoop, we always take only one instance, to prevent accidental superposition
  for i := 0 to FSoundEvents.Count - 1 do
    if FIsLoop or (FSoundEvents[i].PlaybackState = FMOD_STUDIO_PLAYBACK_STOPPED) then
    begin
      Instance := FSoundEvents[i];
      exit(True);
    end;
  if assigned(SoundSystem) then
  begin
    newInstance := SoundSystem.GetEventInstance(FEventPath);
    if assigned(newInstance) then
    begin
      FSoundEvents.Add(newInstance);
      Instance := newInstance;
      Result := True;
    end;
  end;
end;

function TSoundComponent.IsLoop : TSoundComponent;
begin
  Result := self;
  FIsLoop := True;
end;

function TSoundComponent.IsPiece : TSoundComponent;
begin
  Result := self;
  FIsPiece := True;
end;

function TSoundComponent.IsStopEvent : boolean;
begin
  Result := FStopGroupSet and ((CurrentEvent.CalledToGroup = []) or (CurrentEvent.CalledToGroup * FStopGroup <> []));
end;

function TSoundComponent.IsTriggerEvent : boolean;
begin
  Result := (CurrentEvent.CalledToGroup = []) or (CurrentEvent.CalledToGroup * FTriggerGroup <> [])
end;

function TSoundComponent.OnAfterDeserialization() : boolean;
begin
  Result := True;
  if FOnCreate and IsTriggerEvent and Check then
      Play();
end;

function TSoundComponent.OnDie(KillerID, KillerCommanderID : RParam) : boolean;
begin
  Result := True;
  if FOnDie and IsTriggerEvent and Check then
      Play();
end;

function TSoundComponent.OnFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FUsePositionOfTarget then
  begin
    FTargetPosition := Targets.AsATarget.First.GetTargetPosition.X0Y;
  end;
  if FOnFire and IsTriggerEvent and Check and CheckTargets(Targets) then
      Play();
  if FStopOnFire and IsStopEvent then
      Stop();
end;

function TSoundComponent.OnFireWarhead(Targets : RParam) : boolean;
begin
  Result := True;
  if FOnWarhead and IsTriggerEvent and Check and CheckTargets(Targets) then
      Play();
end;

function TSoundComponent.OnIdle : boolean;
begin
  Result := True;
  if assigned(FDelay) and not FDelay.Paused and FDelay.Expired then
  begin
    FreeAndNil(FDelay);
    if Check then
        Play;
  end;
end;

function TSoundComponent.OnLose(TeamID : RParam) : boolean;
begin
  Result := True;
  if FOnLose and (Owner.TeamID = TeamID.AsInteger) and Check then
      Play;
end;

function TSoundComponent.OnPreFire(Targets : RParam) : boolean;
begin
  Result := True;
  if FUsePositionOfTarget then
  begin
    FTargetPosition := Targets.AsATarget.First.GetTargetPosition.X0Y;
  end;
  if FOnPreFire and IsTriggerEvent and Check and CheckTargets(Targets) then
      Play();
end;

function TSoundComponent.OnWriteHealth(ResourceID, Amount : RParam) : boolean;
var
  Resource : EnumResource;
  Parameter : string;
begin
  Result := True;
  Resource := EnumResource(ResourceID.AsInteger);
  // update resource bindings
  if FParameterBindings.TryGetValue(Resource, Parameter) then
      UpdateParameter(Parameter, ResourceAsSingle(Resource, Amount));

  // trigger on health loss
  if FOnLoseHealth and (Resource = reHealth) and (Amount.AsSingle < Owner.BalanceSingle(reHealth)) and Check then
      Play;
end;

procedure TSoundComponent.Play;
var
  causedByPlayer : boolean;
  Instance : TFMODEventInstance;
  Resource : EnumResource;
  Parameter : string;
begin
  if assigned(FDelay) and FDelay.Paused then
      FDelay.Start
  else
    if not assigned(FDelay) or FDelay.Expired then
  begin
    if (FCheckOption = coGeneralNone) or Settings.GetBooleanOption(FCheckOption) then
    begin
      // is playback caused by player or teammate/opponent/bot
      causedByPlayer := assigned(ClientGame) and (Eventbus.Read(eiOwnerCommander, []).AsInteger = ClientGame.CommanderManager.ActiveCommander.ID);
      if (not FIsLoop or not FIsLooping) and TryGetFreeInstance(Instance) then
      begin
        UpdatePosition(Instance);
        if causedByPlayer then
            Instance.ParameterValue['caused_by_player'] := 1
        else
            Instance.ParameterValue['caused_by_player'] := 0;
        // init resource bindings
        for Resource in FParameterBindings.Keys do
        begin
          Parameter := FParameterBindings[Resource];
          UpdateParameter(Parameter, ResourceAsSingle(Resource, Owner.Balance(Resource, ComponentGroup)));
        end;
        Instance.Start;
        FIsLooping := True;
      end;
    end;
  end;
end;

procedure TSoundComponent.Stop;
var
  i : Integer;
begin
  for i := 0 to FSoundEvents.Count - 1 do
      FSoundEvents[i].Stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
  FIsLooping := False;
end;

function TSoundComponent.StopGroup(const StopGroup : TArray<byte>) : TSoundComponent;
begin
  Result := self;
  FStopGroupSet := True;
  FStopGroup := ByteArrayToComponentGroup(StopGroup);
  FTriggerGroup := FTriggerGroup - FStopGroup;
end;

function TSoundComponent.StopOnFire() : TSoundComponent;
begin
  Result := self;
  FStopOnFire := True;
end;

function TSoundComponent.StopOnFree : TSoundComponent;
begin
  Result := self;
  FStopOnFree := True;
end;

function TSoundComponent.TriggerNow : TSoundComponent;
begin
  Result := self;
  if Check then
      Play;
end;

function TSoundComponent.TriggerOnCreate() : TSoundComponent;
begin
  Result := self;
  FOnCreate := True;
end;

function TSoundComponent.TriggerOnDie : TSoundComponent;
begin
  Result := self;
  FOnDie := True;
end;

function TSoundComponent.TriggerOnFire() : TSoundComponent;
begin
  Result := self;
  FOnFire := True;
end;

function TSoundComponent.TriggerOnFireWarhead : TSoundComponent;
begin
  Result := self;
  FOnWarhead := True;
end;

function TSoundComponent.TriggerOnFree : TSoundComponent;
begin
  Result := self;
  FOnFree := True;
end;

function TSoundComponent.TriggerOnLose : TSoundComponent;
begin
  Result := self;
  FOnLose := True;
end;

function TSoundComponent.TriggerOnLoseHealth : TSoundComponent;
begin
  Result := self;
  FOnLoseHealth := True;
end;

function TSoundComponent.TriggerOnPreFire : TSoundComponent;
begin
  Result := self;
  FOnPreFire := True;
end;

procedure TSoundComponent.UpdateParameter(const Parameter : string; Value : single);
var
  i : Integer;
begin
  for i := 0 to FSoundEvents.Count - 1 do
      FSoundEvents[i].ParameterValue[Parameter] := Value;
end;

procedure TSoundComponent.UpdatePosition(Instance : TFMODEventInstance);
var
  FMOD3DAttributes : FMOD_3D_ATTRIBUTES;
begin
  FMOD3DAttributes.velocity := Vector3ToFMODVector(RVector3.Create(0, 0, 0));
  FMOD3DAttributes.up := Vector3ToFMODVector(RVector3.Create(0, 1, 0));
  FMOD3DAttributes.forward := Vector3ToFMODVector(RVector3.Create(0, 0, 1));
  if FUsePositionOfTarget then
      FMOD3DAttributes.Position := Vector3ToFMODVector(FTargetPosition)
  else
  begin
    if FIsPiece then
        FMOD3DAttributes.Position := Vector3ToFMODVector(Eventbus.ReadHierarchic(eiDisplayPosition, [], ComponentGroup).AsVector3)
    else
        FMOD3DAttributes.Position := Vector3ToFMODVector(Owner.DisplayPosition);
  end;
  Instance.Attributes3D := FMOD3DAttributes;
end;

function TSoundComponent.UsePositionOfTarget : TSoundComponent;
begin
  Result := self;
  FUsePositionOfTarget := True;
end;

{ TGameSoundManagerComponent }

constructor TGameSoundManagerComponent.Create(Owner : TEntity);
begin
  inherited;
  FWinEvent := SoundSystem.GetEventInstance('event:/music/cue/win');
  FLooseEvent := SoundSystem.GetEventInstance('event:/music/cue/loose');
  FMusicEvent := SoundSystem.GetEventInstance('event:/music/game/core');
end;

destructor TGameSoundManagerComponent.Destroy;
begin
  FWinEvent.Stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
  FLooseEvent.Stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
  FMusicEvent.Stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
  FWinEvent.Free;
  FLooseEvent.Free;
  FMusicEvent.Free;
  inherited;
end;

function TGameSoundManagerComponent.OnGameCommencing : boolean;
begin
  Result := True;
  FMusicEvent.Start;
end;

function TGameSoundManagerComponent.OnIdle : boolean;
var
  ListenerAttributes : FMOD_3D_ATTRIBUTES;
  Position, up, Front : RVector3;
begin
  Result := True;

  Position := GFXD.MainScene.Camera.ViewingFrustum.Planes[2].IntersectRay(RRay.Create(GFXD.MainScene.Camera.Target, RVector3.UNITY));
  Front := -RVector3.UNITY;
  up := GFXD.MainScene.Camera.CameraDirection.Orthogonalize(Front).Normalize;

  { // old listener position same as camera
   Position := GFXD.Camera.Position;
   Front := GFXD.Camera.CameraDirection.Normalize;
   up := GFXD.Camera.up.Orthogonalize(GFXD.Camera.CameraDirection).Normalize;
  }

  // update listener position and other settings to current camera
  ListenerAttributes.Position := Vector3ToFMODVector(Position);
  ListenerAttributes.up := Vector3ToFMODVector(up);
  ListenerAttributes.velocity := Vector3ToFMODVector(RVector3.ZERO);
  ListenerAttributes.forward := Vector3ToFMODVector(Front);
  SoundSystem.ListenerAttributes[0] := ListenerAttributes;

  FMusicEvent.ParameterValue['intensity_level'] := RetrieveIntensityLevel;
end;

function TGameSoundManagerComponent.OnLose(TeamID : RParam) : boolean;
var
  PlayerTeamID : Integer;
begin
  Result := True;
  PlayerTeamID := ClientGame.CommanderManager.ActiveCommanderTeamID;
  // play jingle only for players
  if PlayerTeamID >= 0 then
  begin
    // team of current player has lost
    if PlayerTeamID = TeamID.AsInteger then
        FLooseEvent.Start
    else
        FWinEvent.Start;
  end;
end;

function TGameSoundManagerComponent.RetrieveIntensityLevel : single;
begin
  Result := GlobalEventbus.Read(eiShortestBattleFrontDistance, []).AsSingle; // Returns 48, 96 or 144
  if Result <= 0 then
      Result := 144.0;
  Result := Max(0, 2.0 - Max(0, (Result / 48.0) - 1));
end;

{ TGlobalSoundManagerComponent }

constructor TGlobalSoundManagerComponent.Create(Owner : TEntity);
var
  Option : EnumSoundOptions;
  SoundEvent : EnumSoundEvent;
begin
  inherited;
  for SoundEvent := low(EnumSoundEvent) to high(EnumSoundEvent) do
      FSounds[SoundEvent] := SoundSystem.GetEventInstance(SOUND_EVENT_PATHS[SoundEvent]);

  GUI.SubscribeToEvent(geClick, OnGuiClick);
  GUI.SubscribeToEvent(geRightClick, OnGuiClick);
  // init and load sound options
  for Option := low(EnumSoundOptions) to high(EnumSoundOptions) do HandleOption(Option);
end;

destructor TGlobalSoundManagerComponent.Destroy;
var
  SoundEvent : EnumSoundEvent;
begin
  GUI.UnsubscribeFromEvent(geClick, OnGuiClick);
  GUI.UnsubscribeFromEvent(geRightClick, OnGuiClick);
  for SoundEvent := low(EnumSoundEvent) to high(EnumSoundEvent) do
      FSounds[SoundEvent].Free;
  inherited;
end;

procedure TGlobalSoundManagerComponent.HandleOption(Option : EnumClientOption);
begin
  {$IFNDEF MAPEDITOR}
  if assigned(GameStateManager) then
      GameStateManager.UpdateSoundSettings(Option);
  {$ENDIF}
end;

function TGlobalSoundManagerComponent.OnClientOption(Option : RParam) : boolean;
begin
  Result := True;
  HandleOption(Option.AsType<EnumClientOption>);
end;

procedure TGlobalSoundManagerComponent.OnGuiClick(const Sender : RGUIEvent);
begin
  if Sender.IsValid and Sender.Component.HasClass('invalid') then
      PlayError
  else
      PlayClick;
end;

function TGlobalSoundManagerComponent.PlaySound(const SoundEvent : EnumSoundEvent) : boolean;
begin
  FSounds[SoundEvent].Start;
  Result := True;
end;

initialization

ScriptManager.ExposeClass(TSoundComponent);

end.
