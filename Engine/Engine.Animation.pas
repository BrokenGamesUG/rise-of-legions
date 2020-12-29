unit Engine.Animation;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  Generics.Collections,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Core,
  Engine.Core.Types,
  Engine.Log,
  Windows,
  Engine.Helferlein.VCLUtils;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  EnumAnimationBlendMode = (abDiscrete, abLinear, abCubic);
  EnumAnimationPlayMode = (alSingle, alLoop, alSymmetricLoop);
  EnumAnimationState = (asPlaying, asPaused, asStopped);

  EAnimationError = class(Exception);

  ProcPlaybackFinished = procedure of object;

  /// <summary> Define a timeframe for animation, where animation has to be displayed. Timeframe include the start and endtime.
  /// So testing a value will be Starttime <= value <= Endtime.</summary>
  RTimeframe = record
    /// <summary> Begin of the timeframe, value will be slightly greater as end of last timeframe (for continuously animations)</summary>
    Starttime : single;
    /// <summary> End of the timeframe</summary>
    Endtime : single;
    /// <summary> Returns true, if value is within timefrma</summary>
    function Within(Value : single) : boolean;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublic, vcPublished]) FIELDS([])}

  /// <summary> Data of a explicit animation. Any animation has a lange, name and usually some custom data.
  /// The animationdata has to calculate the animation for a timekey, but only if this animation is displayed this frame.</summary>
  TAnimationData = class abstract
    protected
      FName : string;
      FDefaultlength : Int64;
      FFrameCount : integer;
      procedure DoClone(Clone : TAnimationData); virtual;
    public
      /// <summary> Name of this animation. Value is used for every select of a animation, e.g. playback.</summary>
      property name : string read FName write FName;
      /// <summary> Length in ms of this animation. Value has to be provided, else the length will be Zero and this will cause errors.</summary>
      property DefaultLength : Int64 read FDefaultlength write FDefaultlength;
      property FrameCount : integer read FFrameCount;
      /// <summary> When this method is called by driver, the instance has to calculate and set the displaying of his animation.
      /// The method is only called, if this animation influences the current frame (weight > 0)</summary>
      procedure UpdateAnimation(const Timeframe : RTimeframe; Direction : integer; Weight : single); virtual; abstract;
      /// <summary> Create new animationdata which contains a subset of own animationdata.</summary>
      function ExtractPart(StartFrame, EndFrame : integer) : TAnimationData; virtual; abstract;
      /// <summary> Returns a deep copy of this. </summary>
      function Clone : TAnimationData; virtual; abstract;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  /// <summary> The AnimationDriver is the interface between lowlevel animation code and general controll code, independent from target(mesh, texture,...)
  /// of animation. A driver can controll any animation, like Gif-like-texture or skinned mesh animation. </summary>
  TAnimationDriver = class abstract
    protected
      /// <summary> Map AnimationData to name, important to access data fast</summary>
      FAnimationData : TObjectDictionary<string, TAnimationData>;
      /// <summary> Default constuctor, allocating memory.</summary>
      constructor Create;
      /// <summary> Update animation in dependency from timekey and direction
      /// <param name="Animation"> Name of animation for updating. If animation not exist,
      /// exception will be raised. </param>
      /// <param name="Timeframe"> The timeframe for what the animation is calculated, the starttime is the entime of the last timeframe
      /// from last rendered frame + small offset and the endtime is the currenttime. Values are in range 0..1.</param>
      /// <param name="Direction"> Direction for interpolation, Value can be -1 or +1 </param>
      /// <param name="Weight">Value betweene 0..1. Determines influence of animation.</param>
      /// </summary>
      procedure UpdateAnimation(const Animation : string; const Timeframe : RTimeframe; Direction : integer; Weight : single); virtual;
      /// <summary> Called if this frame no animation is diplayed, but driver will still influence the mesh, e.g. if driver
      /// has then to reset some data or make it possible to manually influence the mesh.</summary>
      procedure UpdateWithoutAnimation; virtual; abstract;
      /// <summary> Set necessary settings to shader.</summary>
      procedure SetShaderSettings(RenderContext : TRenderContext); virtual; abstract;
      /// <summary> Returns a bitmask of necessary shadercode for this animation.</summary>
      function GenerateShaderBitmask(CurrentStatus : EnumAnimationState) : SetDefaultShaderFlags; virtual; abstract;
    public
      /// <summary> Creates a new animation from target another animation that already exists. The new animation
      /// including all frames including startframe until endframe (also including). </summary>
      procedure CreateNewAnimation(const NewAnimationName, SourceAnimation : string; StartFrame, EndFrame : integer);
      /// <summary> Import animation from another file to current driver. Works with files containing only animations and
      /// files that also containing geometry.</summary>
      procedure ImportAnimationFromFile(const FileName : string; const OverrideName : string = ''); virtual; abstract;
      destructor Destroy; override;
  end;

  TAnimation = class
    protected const
      FADEOUT_LENGTH = 500;
    protected
      FPlayMode : EnumAnimationPlayMode;
      FName : string;
      FBlend : boolean;
      FLength : Int64;
      FStartTime, FEndTime, FEndFadeOut, FStartFadeOut : integer;
    public
      property Length : Int64 read FLength;
      property LoopMode : EnumAnimationPlayMode read FPlayMode write FPlayMode;
      constructor Create(const Name : string; CurrentTime : integer; Length : integer; PlayMode : EnumAnimationPlayMode; Blend : boolean);
      procedure Reset(CurrentTime : integer);
      /// <summary> Instruct animation to stop and start fadeout.</summary>
      procedure StartFadeOut(CurrentTime : integer);
      /// <summary> Returns (in range 0..1) the weight of current animationplayback in dependency of time.
      /// If animation is going end soon, it will beginn fadeout and weight is continuously decreasing.
      /// <param name="CurrentTime"> Currenttime</param></summary>
      function ComputeWeight(CurrentTime : integer) : single;
      /// <summary> Returns (in range 0..1) the position of current animationplayback in dependency of time.
      /// <param name="CurrentTime"> Currenttime</param></summary>
      function ComputeTimeKey(CurrentTime : integer; out finished : boolean) : single;
  end;

  /// <summary> The animtaionontroller is the "frontend" to control any animaion. This class has no direct logic to
  /// animate data. This is the function of TAnimationDriver. </summary>
  TAnimationController = class
    public type
      TAnimationInfo = class
        Name : string;
        Length : Int64;
        FrameCount : integer;
        constructor Create(Name : string; Length : Int64; FrameCount : integer);
      end;

      ProcStatusChanged = procedure(OldStatus, NewStatus : EnumAnimationState) of object;
    protected
      // no need of currentanimation, because first element on queue is always currentanimation
      // FCurrentAnimation : TAnimation;
      FStatus : EnumAnimationState;
      FDefaultAnimation : TAnimation;
      FAnimationStack : TObjectList<TAnimation>;
      FDrivers : TList<TAnimationDriver>;
      /// <summary> Save last framecount for animation to prevent double animationtime</summary>
      FFrameCounter : Int64;
      FLastPosition : single;
      FTimeStamp : RTuple<Int64, Int64>;
      procedure SetDefaultAnimation(Value : string);
      /// <summary> This method will manage all status changes</summary>
      procedure SetStatus(const Value : EnumAnimationState);
      function GetAnimationLength(const Name : string) : Int64;
      function GetCurrentTime : RTuple<Int64, Int64>;
      function GetDefaultAnimation : string;
      /// <summary> Throws an exception if the controller does not know ontroller the named animation. </summary>
      procedure AssertHasAnimation(const Animation : string);
    public
      /// <summary> If set (value <> ''), default animation is played until other playback
      /// is started or after all queued animations are played.</summary>
      property DefaultAnimation : string read GetDefaultAnimation write SetDefaultAnimation;
      /// <summary> A queue for all animation that is played. If a animation is finished,
      /// next element in queue is played. If queue is empty, DefaultAnimation is played</summary>
      /// property AnimationQueue : TAnimationQueue read FAnimationQueue;
      /// <summary> Current Status of playback, e.g. asPlaying or asStopped</summary>
      property Status : EnumAnimationState read FStatus write SetStatus;
      /// <summary> Return a list of animationinfo for every unique (different names) animation found
      /// in all drivers. Result is structured data.</summary>
      function GetAnimationInfoExtended : TObjectList<TAnimationInfo>;
      /// <summary> Return animationinfo for first animation found with this name
      /// in all drivers. Result is structured data. If no data was found returns nil</summary>
      function GetAnimationInfoExtendedForItem(const Animation : string) : TAnimationInfo;
      /// <summary> Return a list of animationinfo for every unique (different names) animation found
      /// in all drivers. Result is data formated as string, one line for every animation</summary>
      function GetAnimationInfo : TStrings;
      /// <summary> Returns whether the controller knows the named animation or not. </summary>
      function HasAnimation(const Animation : string) : boolean;

      function GetPosition : single;
      /// ///////////////////////////////////////////////////////////////////////
      /// commonmethods (destructor and constructor)
      /// <summary> Constructor for animationcontroller</summary>
      constructor Create;
      /// <summary> Update all driver data and compute new animationdata. It's necessary to idle every frame
      /// to keep animation up to date.</summary>
      procedure UpdateAnimations;
      /// <summary> Instruct all drivers to set necessary settings (e.g. copy bones to shader) in current shader.</summary>
      procedure SetShaderSettings(RenderContext : TRenderContext);
      /// <summary> Collect and return all necessary shaderbitmasks of all drivers.</summary>
      function GenerateShaderBitmask : SetDefaultShaderFlags;
      /// <summary> Common destructor will free allocated memory.</summary>
      destructor Destroy; override;
      /// ///////////////////////////////////////////////////////////////////////
      /// Controll methods
      /// <summary> Play a animation immediately and use smoothchange if activated.
      /// Play a animation will clear queue and add it. If animation is not found, will cause
      /// a error. Playback is done for every driver that provide a animation with given name.
      /// <param name="Animation"> Name of animation wants to play. Name will use case insensitiv.</param>
      /// <param name="PlayMode"> Controlls the playmode for playback. E.g. use alLoop
      /// to loop playback and alReverse to play animation backwards.</param>
      /// <param name="Length"> Control the length in ms of played animation. With this value
      /// e.g. movementanimationspeed can adjust to movmentspeed. If value = 0, use length
      /// from first driver providing the animation (and use value for all other driver with same animation)</param>
      /// <param name="Blend"> If True the new played animation is blended in current played animation, else not.
      /// The default value is true</param>
      /// </summary>
      procedure Play(const Animation : string; PlayMode : EnumAnimationPlayMode = alSingle; Length : Int64 = 0; Blend : boolean = True; TimeOffset : Int64 = 0);
      /// <summary> Interrupt playback but not reset timer. Caution! To resume playback
      /// don't use play, this will start playback from beginning</summary>
      procedure Pause;
      procedure Resume;
      /// <summary> Will stop animationplayback and clear complete queue.
      /// <param name="NoDefaultAnimation"> If True Stop will complete stop playback, otherwise defaultanimation
      /// is started.</param>
      /// </summary>
      procedure Stop(NoDefaultAnimation : boolean = False);
      /// ///////////////////////////////////////////////////////////////////////
      /// Driver methods
      /// <summary> Add a driver to list and from now on all actions called by controller will affect driver
      /// This will NOT own them, you have to free them on your own.
      /// After adding a driver to list, all animations are provided by them are accessible.
      /// Playback affects him on next play, independent started by play or by AnimationQueue</summary>
      /// <param name="Driver"> Driver that should be added</param>
      procedure AddDriver(Driver : TAnimationDriver); overload;
      procedure AddDriver(Driver : TObjectList<TAnimationDriver>); overload;
      /// <summary> Remove driver from list and controller will no longer affect driver.
      /// Remove driver will not free them!</summary>
      /// <param name="Driver"> Driver that should be removed</param>
      procedure RemoveDriver(Driver : TAnimationDriver);
  end;

implementation

{ TAnimationController }

procedure TAnimationController.AddDriver(Driver : TAnimationDriver);
begin
  assert(not FDrivers.Contains(Driver));
  FDrivers.Add(Driver);
end;

procedure TAnimationController.AddDriver(Driver : TObjectList<TAnimationDriver>);
var
  i : integer;
begin
  if assigned(Driver) then
    for i := 0 to Driver.count - 1 do
    begin
      assert(not FDrivers.Contains(Driver[i]));
      FDrivers.Add(Driver[i]);
    end;
end;

constructor TAnimationController.Create;
begin
  FAnimationStack := TObjectList<TAnimation>.Create();
  FDrivers := TList<TAnimationDriver>.Create;
  // On default no defaultanimation is set
  FDefaultAnimation := nil;
  FStatus := asStopped;
end;

destructor TAnimationController.Destroy;
begin
  FDefaultAnimation.Free;
  FAnimationStack.Free;
  FDrivers.Free;
  inherited;
end;

function TAnimationController.GenerateShaderBitmask : SetDefaultShaderFlags;
var
  Driver : TAnimationDriver;
begin
  result := [];
  // give any registered driver a chance to set own bits for shaderselection
  for Driver in FDrivers do
    if assigned(Driver) then
    begin
      result := result + Driver.GenerateShaderBitmask(Status);
    end;
end;

function TAnimationController.GetAnimationInfo : TStrings;
var
  ExtendedInfo : TObjectList<TAnimationInfo>;
  InfoData : TAnimationInfo;
begin
  ExtendedInfo := GetAnimationInfoExtended;
  assert(assigned(ExtendedInfo));
  result := TStringList.Create;
  for InfoData in ExtendedInfo do
  begin
    result.Add(Format('Name: %s, Length: %d, Frames: %d', [InfoData.Name, InfoData.Length, InfoData.FrameCount]));
  end;
  ExtendedInfo.Free;
end;

function TAnimationController.GetAnimationInfoExtended : TObjectList<TAnimationInfo>;
var
  CollectedData : TDictionary<string, TAnimationInfo>;
  Data : TAnimationData;
  Driver : TAnimationDriver;
begin
  CollectedData := TDictionary<string, TAnimationInfo>.Create();
  for Driver in FDrivers do
  begin
    for Data in Driver.FAnimationData.Values do
    begin
      if not CollectedData.ContainsKey(Data.Name.ToLowerInvariant) then
          CollectedData.Add(Data.Name.ToLowerInvariant, TAnimationInfo.Create(Data.Name, Data.DefaultLength, Data.FrameCount));
    end;
  end;
  result := TObjectList<TAnimationInfo>.Create(CollectedData.Values);
  CollectedData.Free;
end;

function TAnimationController.GetAnimationInfoExtendedForItem(const Animation : string) : TAnimationInfo;
var
  Driver : TAnimationDriver;
begin
  result := nil;
  for Driver in FDrivers do
  begin
    if Driver.FAnimationData.ContainsKey(Animation) then
    begin
      result := TAnimationInfo.Create(Driver.FAnimationData[Animation].Name, Driver.FAnimationData[Animation].DefaultLength, Driver.FAnimationData[Animation].FrameCount);
      break;
    end;
  end;
end;

function TAnimationController.GetAnimationLength(const Name : string) : Int64;
var
  Driver : TAnimationDriver;
begin
  result := 0;
  AssertHasAnimation(name);
  for Driver in FDrivers do
  begin
    if Driver.FAnimationData.ContainsKey(name) then
    begin
      result := Driver.FAnimationData[name].DefaultLength;
      break;
    end;
  end;
end;

function TAnimationController.GetCurrentTime : RTuple<Int64, Int64>;
begin
  // uses last time frame if pause
  if Status = asPaused then
      FFrameCounter := GFXD.FPSCounter.FrameCount
  else
  begin
    // prevent get different timekey per frame if UpdateAnimations is called more then once per frame
    if GFXD.FPSCounter.FrameCount <> FFrameCounter then
    begin
      // new timeframe starts 1 ms after last timeframe
      FTimeStamp.a := FTimeStamp.b + 1;
      FTimeStamp.b := TimeManager.GetTimestamp;
      FFrameCounter := GFXD.FPSCounter.FrameCount;
    end;
  end;
  result := FTimeStamp;
end;

function TAnimationController.GetDefaultAnimation : string;
begin
  if assigned(FDefaultAnimation) then
      result := FDefaultAnimation.FName
  else result := '';
end;

function TAnimationController.GetPosition : single;
begin
  result := FLastPosition;
end;

function TAnimationController.HasAnimation(const Animation : string) : boolean;
var
  Driver : TAnimationDriver;
begin
  result := False;
  for Driver in FDrivers do
    if Driver.FAnimationData.ContainsKey(Animation) then
    begin
      result := True;
      break;
    end;
end;

procedure TAnimationController.AssertHasAnimation(const Animation : string);
begin
  if not HasAnimation(Animation) then
      raise EAnimationError.CreateFmt('TAnimationController: Animation %s was not found.', [Animation]);
end;

procedure TAnimationController.UpdateAnimations;
var
  Driver : TAnimationDriver;
  i : integer;
  weightRemaining, Weight : single;
  Timeframe : RTimeframe;
  finished : boolean;
begin
  if FFrameCounter <> GFXD.FPSCounter.FrameCount then
  begin
    if Status in [asPlaying, asPaused] then
    begin
      weightRemaining := 1;
      for i := FAnimationStack.count - 1 downto 0 do
      begin
        // map system timestamps to values betwenn 0..1
        // calculate timeframe, because some animationeffects, like souns needs a time span, a not a point in time
        // else a sound does not know if it was the time to play
        Timeframe.Starttime := FAnimationStack[i].ComputeTimeKey(GetCurrentTime.a, finished);
        Timeframe.Endtime := FAnimationStack[i].ComputeTimeKey(GetCurrentTime.b, finished);

        if i = 0 then FLastPosition := Timeframe.Endtime;
        if not finished and (weightRemaining > 0) then
        // as long as animation not expired
        begin
          Weight := FAnimationStack[i].ComputeWeight(GetCurrentTime.b);
          if Weight > weightRemaining then
              Weight := weightRemaining;
          // no other animation exists, can't fade to another animation
          if (FAnimationStack.count = 1) and not assigned(FDefaultAnimation) then Weight := weightRemaining;
          for Driver in FDrivers do
          begin
            Driver.UpdateAnimation(FAnimationStack[i].FName, Timeframe, 1, Weight);
          end;
          weightRemaining := weightRemaining - Weight;
        end
        // animation has end? time to delete
        else
        begin
          FAnimationStack.Delete(i);
          if assigned(FDefaultAnimation) and (FAnimationStack.count <= 0) then
              FDefaultAnimation.Reset(GetCurrentTime.b);
        end;
      end;
      if (FAnimationStack.count = 0) and not assigned(FDefaultAnimation) then
      begin
        Status := asStopped;
        for Driver in FDrivers do
            Driver.UpdateWithoutAnimation();
        Exit;
      end;
      if (weightRemaining > 0.01) then
      begin
        if assigned(FDefaultAnimation) then
        begin
          for Driver in FDrivers do
          begin
            Timeframe.Starttime := FDefaultAnimation.ComputeTimeKey(GetCurrentTime.a, finished);
            Timeframe.Endtime := FDefaultAnimation.ComputeTimeKey(GetCurrentTime.b, finished);
            Driver.UpdateAnimation(FDefaultAnimation.FName, Timeframe, 1, weightRemaining);
          end;
        end;
      end;
    end
    else
    begin
      for Driver in FDrivers do
          Driver.UpdateWithoutAnimation();
    end;
  end;
end;

procedure TAnimationController.Pause;
begin
  if Status = asPlaying then
      Status := asPaused;
end;

procedure TAnimationController.Play(const Animation : string; PlayMode : EnumAnimationPlayMode; Length : Int64; Blend : boolean; TimeOffset : Int64);
var
  playtime : Int64;
begin
  AssertHasAnimation(Animation);
  // without blending, all current playing animations will be overwriten, so drop them
  if not Blend then
      FAnimationStack.Clear;
  // if any animation already playing, time to fade them out
  if FAnimationStack.count > 0 then
      FAnimationStack.Last.StartFadeOut(GetCurrentTime.b - TimeOffset);
  if Length <= 0 then
      playtime := GetAnimationLength(Animation)
  else playtime := Length;
  FAnimationStack.Add(TAnimation.Create(Animation, GetCurrentTime.b - TimeOffset, playtime, PlayMode, Blend));
  Status := asPlaying;
end;

procedure TAnimationController.RemoveDriver(Driver : TAnimationDriver);
begin
  assert(assigned(Driver));
  assert(FDrivers.Contains(Driver));
  FDrivers.Remove(Driver);
end;

procedure TAnimationController.Resume;
begin
  if Status = asPaused then
      Status := asPlaying;
end;

procedure TAnimationController.SetDefaultAnimation(Value : string);
begin
  AssertHasAnimation(Value);
  if assigned(FDefaultAnimation) then
      FDefaultAnimation.Free;
  FDefaultAnimation := TAnimation.Create(Value, GetCurrentTime.b, GetAnimationLength(Value), alLoop, True);
  if (Status = asStopped) then
      Status := asPlaying;
end;

procedure TAnimationController.SetShaderSettings(RenderContext : TRenderContext);
var
  Driver : TAnimationDriver;
begin
  // if Status in [asPlaying, asPaused] then TODO
  begin
    for Driver in FDrivers do
    begin
      Driver.SetShaderSettings(RenderContext);
    end;
  end;
end;

procedure TAnimationController.SetStatus(const Value : EnumAnimationState);
begin
  // only apply changes, prevent skipping (double play) or some other undefined behavior
  if Status <> Value then
  begin
    // status = OldStatus, Value = NewStatus
    case Value of
      asPlaying :
        begin
          // if there is no animation to play, go immediately to stop
          if (FAnimationStack.count > 0) or assigned(FDefaultAnimation) then
          begin
            FStatus := asPlaying;
          end
          else FStatus := asStopped;
        end;
      asPaused :
        begin
          if Status <> asStopped then
          begin
            FStatus := asPaused;
          end;
        end;
      asStopped :
        begin
          // Stop -> all queued data obsolete and drop current animation
          FAnimationStack.Clear;
          // all playback is stopped
          FStatus := asStopped;
        end;
    end;
  end;
end;

procedure TAnimationController.Stop(NoDefaultAnimation : boolean = False);
begin
  Status := asStopped;
end;

{ TAnimationDriver }

constructor TAnimationDriver.Create;
begin
  FAnimationData := TObjectDictionary<string, TAnimationData>.Create([doOwnsValues]);
end;

procedure TAnimationDriver.CreateNewAnimation(const NewAnimationName : string; const SourceAnimation : string; StartFrame, EndFrame : integer);
var
  newAnimation : TAnimationData;
begin
  if FAnimationData.ContainsKey(NewAnimationName) then
      HLog.Write(elWarning, 'TAnimationDriver: Animation "%s" already exists!', [NewAnimationName], EAlreadyExists)
  else
    if FAnimationData.ContainsKey(SourceAnimation) then
  begin
    newAnimation := FAnimationData[SourceAnimation].ExtractPart(StartFrame, EndFrame);
    newAnimation.Name := NewAnimationName;
    FAnimationData.Add(NewAnimationName, newAnimation);
  end
  // else raise ENotFoundException.CreateFmt('TAnimationDriver: Animation "%s" was not found.', [SourceAnimation]);
end;

destructor TAnimationDriver.Destroy;
begin
  FAnimationData.Free;
  inherited;
end;

procedure TAnimationDriver.UpdateAnimation(const Animation : string; const Timeframe : RTimeframe; Direction : integer; Weight : single);
begin
  if FAnimationData.ContainsKey(Animation) then
      FAnimationData[Animation].UpdateAnimation(Timeframe, Direction, Weight);
end;

{ TAnimation }

function TAnimation.ComputeTimeKey(CurrentTime : integer; out finished : boolean) : single;
begin
  result := Frac((CurrentTime - FStartTime) / (FEndTime - FStartTime));
  finished := (CurrentTime - FEndFadeOut > FADEOUT_LENGTH) and not(FEndFadeOut = 0);
end;

function TAnimation.ComputeWeight(CurrentTime : integer) : single;
begin
  assert(CurrentTime >= 0);
  if FBlend then
  begin
    if (CurrentTime < FStartFadeOut) and (FStartFadeOut > 0) then
    begin
      result := 1 - ((FStartFadeOut - CurrentTime) / FADEOUT_LENGTH);
    end
    else if (CurrentTime > FEndFadeOut) and (FEndFadeOut > 0) then
    begin
      result := 1 - ((CurrentTime - FEndFadeOut) / FADEOUT_LENGTH);
    end
    else
        result := 1;
  end
  else result := 1;

  assert(HMath.inRange(result, 0, 1));
end;

constructor TAnimation.Create(const Name : string; CurrentTime : integer; Length : integer; PlayMode : EnumAnimationPlayMode; Blend : boolean);
begin
  FPlayMode := PlayMode;
  FName := name;
  FBlend := Blend;
  FLength := Max(1, Length);
  Reset(CurrentTime);
end;

procedure TAnimation.Reset(CurrentTime : integer);
begin
  FStartTime := CurrentTime;
  FEndTime := CurrentTime + FLength;
  if not(FPlayMode in [alLoop, alSymmetricLoop]) then
  begin
    FEndFadeOut := FEndTime - FADEOUT_LENGTH;
    FStartFadeOut := CurrentTime + FADEOUT_LENGTH;
  end
  else
  begin
    FEndFadeOut := 0;
    FStartFadeOut := CurrentTime + FADEOUT_LENGTH;
  end;
  assert(FEndTime >= FStartTime);
end;

procedure TAnimation.StartFadeOut(CurrentTime : integer);
begin
  FEndFadeOut := CurrentTime;
end;

{ TAnimationController.TAnimationInfo }

constructor TAnimationController.TAnimationInfo.Create(Name : string; Length : Int64; FrameCount : integer);
begin
  self.Name := name;
  self.Length := Length;
  self.FrameCount := FrameCount;
end;

{ RTimeframe }

function RTimeframe.Within(Value : single) : boolean;
begin
  result := HMath.inRange(Value, self.Starttime, self.Endtime);
end;

{ TAnimationData }

procedure TAnimationData.DoClone(Clone : TAnimationData);
begin
  Clone.FName := FName;
  Clone.FDefaultlength := FDefaultlength;
  Clone.FFrameCount := FFrameCount;
end;

end.
