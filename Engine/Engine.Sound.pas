unit Engine.Sound;

interface

uses
  OpenAL,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Log,
  System.SysUtils,
  OpenAL.OggStream,
  System.Classes,
  Generics.Collections,
  Windows,
  Dialogs,
  System.Math,
  System.UITypes;

type

  /// <summary> The type of a sound to make settings effecting all sounds of a type. </summary>
  EnumSoundType = (
    stMusic,
    stEffect,
    stGUI,
    // for individual purposes like alarms, voices, etc.
    stCustom1,
    stCustom2,
    stCustom3
    );

  Enum3DSoundDistanceModel =
    (dmDisabled,
    dmInverseDistance,
    dmInverseDistanceClamped,
    dmLinearDistance,
    dmLinearDistanceClamped,
    dmExponentialDistance,
    dmExponentialDistanceClamped);

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  ESoundException = class(Exception);

  TSoundManager = class;

  /// <summary> Handle to a source that valid status is maintained by soundmanager. Will prevent soundeffect from manipulate a
  /// old source that already used by another effect.</summary>
  TSoundHandle = class
    private
      FValid : boolean;
      FSource : TALuint;
      function GetSource : TALuint;
      constructor Create(Source : TALuint);
    public
      /// <summary> If true current handle to a sound source is valid and can be used and manipulated, else source is already used by
      /// another effect and is not valid anymore. Any use will cause an exception.</summary>
      property Valid : boolean read FValid;
      /// <summary> Get source of this handle. If handle is not valid, this will cause an exception.</summary>
      property Source : TALuint read GetSource;
  end;

  /// <summary> Controlclass for a soundeffect. Use soundmanager to load a sound.</summary>
  TSoundEffect = class
    private type
      /// <summary> Job for playing a sound delayed.</summary>
      TSoundjob = class
        FTargetSoundEffect : TSoundEffect;
        FDelayTimer : TTimer;
        constructor Create(Delay : integer; TargetSoundEffect : TSoundEffect);
        procedure Idle;
        destructor Destroy; override;
      end;
    private
      FForceFree : boolean;
      /// <summary> Target buffer for this effect containing sounddata.</summary>
      FBuffer : TALuint;
      FSoundManager : TSoundManager;
      FVolume : single;
      FLocalVolume : integer;
      FDelayedSounds : TList<TSoundjob>;
      FWaitForFree : boolean;
      // data for 3dsound
      FPosition : RVector3;
      FDirection : RVector3;
      FVelocity : RVector3;
      // define if a sound will effected by position to listener relation or not (an sound will played with full volume on any position)
      FIs3DSound : boolean;
      FHandles : TList<TSoundHandle>;
      FSoundType : EnumSoundType;
      FPitch : single;
      FFileName : string;
      constructor Create(Buffer : TALuint; Enable3DSound : boolean; FileName : string; SoundType : EnumSoundType; SourceSoundManager : TSoundManager);
      procedure SetVolume(const Value : integer);
      /// <summary> Process all delayed sounds. Automatically called by manager!</summary>
      procedure Idle;
      function CanDestroyed : boolean;
      procedure ForceFree;
      function GetLength : integer;
      procedure SetDirection(const Value : RVector3);
      procedure SetPosition(const Value : RVector3);
      procedure SetVelocity(const Value : RVector3);
      procedure UpdateVolume;
      procedure SetIs3DSound(const Value : boolean);
      procedure SetPitch(const Value : single);
      function GetName : string;
    public
      /// <summary> Soundname for display and debug.</summary>
      property name : string read GetName;
      /// <summary> Only for display name, will not use for get sound or anything else</summary>
      property FileName : string read FFileName;
      /// <summary> The category of sound this sound is assigned to. </summary>
      property SoundType : EnumSoundType read FSoundType;
      /// <summary> True if sound is 3D and will affected by listener to effect position relation.</summary>
      property Is3DSound : boolean read FIs3DSound write SetIs3DSound;
      /// <summary> Length of the sound in msec.</summary>
      property Length : integer read GetLength;
      /// <summary> Value to adjust only volume for SoundEffectPlayback. MaxValue = 100, MinValue = 0.  Value out of range are clamped.</summary>
      property Volume : integer read FLocalVolume write SetVolume;
      /// <summary> Pitch frequency. Range is [0.0 .. any]. Default is 1.0. Each reduction by 50 percent equals a pitch
      /// shift of -12 semitones (one octave reduction). Each doubling equals a pitch shift of 12
      /// semitones (one octave increase). Zero is not a legal value.</summary>
      property Pitch : single read FPitch write SetPitch;
      /// <summary> 3D position in worldspace of sound, only supported by 3D sounds.</summary>
      property Position : RVector3 read FPosition write SetPosition;
      /// <summary> 3D direction in worldspace of sound, only supported by 3D sounds. If direction is Zerovector, sound is NOT oriented,
      /// else sound will oriented into direction (like a loudspeaker).</summary>
      property Direction : RVector3 read FDirection write SetDirection;
      /// <summary> Velocity of sound, seperate for every axis, only supported by 3D sounds. Only used for some special 3D sound effects,
      /// like the doppeleffect. ATTENTION! Velocity is NOT used for moving the sound, even if velocity is <> ZERO, sound will stay on last set
      /// position.</summary>
      property Veloctiy : RVector3 read FVelocity write SetVelocity;
      /// <summary> Play soundeffect. Soundplayback is delayed by x msec. If sound is played delayed, call Idle of the soundmanager is necessary!
      /// ATTENTION!!! Everytime play is called, a new source is used to play effect. So any command (like set position or stops playback) will only
      /// affect the LAST source. So be careful in playing a sound multiple times!</summary>
      procedure Play(Delay : integer = 0; looping : boolean = False);
      /// <summary> Stops the playback of soundeffect. ATTENTION! If sounds is played multiple times, stop will only stops the playback of the last played sound.</summary>
      procedure Stop();
      /// <summary> Manually apply changes on 3D data to sound. It is only nessecary to call this method, if a sound is
      /// repostioned after playback. General a sound will automatically positioned at playback.</summary>
      procedure Update3D;
      /// <summary> Release all allocated resources if all are stopped. If sound is playing it will released after sound finished.</summary>
      destructor Destroy; override;
      /// <summary> Kabumm!</summary>
      procedure FreeInstance; override;
  end;

  TMusicDirector = class
    public type
      TLayer = class
        IntensityTriggerRange : RRange;
        OggStream : TOGGStream;
        LastStatusChange : LongWord;
        constructor Create(const FileName : string; const IntensityTriggerRange : RRange);
        procedure FadeIn(FadeDuration : LongWord);
        procedure FadeOut(FadeDuration : LongWord);
        function IsCurrentlyPlaying : boolean;
        destructor Destroy; override;
      end;
    private
      FLayer : TUltimateObjectList<TLayer>;
      /// <summary> Contains a muted intro for every layer.</summary>
      FDummyIntros : TObjectList<TOGGStream>;
      FPlaybackStarted : boolean;
      FLayerFadeOutTime : LongWord;
      FLayerFadeInTime : LongWord;
      FIntensityLevel : single;
      FLayerMinimumPlayingTime : LongWord;
      FVolume : LongWord;
      FIntro : TOGGStream;
      procedure Idle;
      procedure SetIntensityLevel(const Value : single);
      procedure SetVolume(const Value : LongWord);
      function GetLayer(index : integer) : TLayer;
      function GetLayerCount : integer;
    public
      /// <summary> Volume in Range 0..100, Value will be clamped in range, 0 = silence, 100 = full volume (without any amplification).</summary>
      property Volume : LongWord read FVolume write SetVolume;
      /// <summary> Time in msec to fade in a layer. For fading a linearfade is used.</summary>
      property LayerFadeInTime : LongWord read FLayerFadeInTime write FLayerFadeInTime;
      /// <summary> Time in msec to fade out a layer. For fading a linearfade is used.</summary>
      property LayerFadeOutTime : LongWord read FLayerFadeOutTime write FLayerFadeOutTime;
      /// <summary> Time in msec a layer is minimum played, this value is to prevent fast layer on-offs because
      /// of fast IntensityLevel changes.</summary>
      property LayerMinimumPlayingTime : LongWord read FLayerMinimumPlayingTime write FLayerMinimumPlayingTime;
      /// <summary> The IntensityLevel is the most important value of the MusicDirector and controls which layer
      /// will be currently played. The range of that value is not defined by the MusicDirector, else the values
      /// passed on the AddLayer call will define the meaningful range of that value. The value can be positive and negative
      /// to e.g. represent positive atmosphere and negative atmosphere by layers.
      /// HINT: Layervolume jiggiling caused by fast changes of the IntensityLevel will be automatically
      /// prevented by LayerMinimumPlayingTime. So DON'T smooth or adjust the IntensityLevel by application,
      /// this is done by the MusicDirector</summary>
      property IntensityLevel : single read FIntensityLevel write SetIntensityLevel;
      /// <summary> Adds a layer (a musicfile) to the director and setup the range within the layer is played.
      /// <param name="FileName"> Complete Filename of the musicfile, currently only ogg files are supported.</param> </summary>
      property LayerCount : integer read GetLayerCount;
      property Layer[index : integer] : TLayer read GetLayer;
      procedure AddLayer(FileName : string; const IntensityTriggerRange : RRange);
      /// <summary> Set a intro for the director. The intro begins to play, when play starts. The intro will played once completly
      /// and thereafter the layer will be starting playing.
      /// SetIntro after the playback has already started, will cause an error.</summary>
      procedure SetIntro(FileName : string);
      /// <summary> Remove all layers from director. Stops also the playback.</summary>
      procedure ClearLayers;
      /// <summary> Returns true if the MusicDirector is currently playing music, else false. This will also return true
      /// if all layers are currently muted, because no layer is in range of the IntensityLevel.</summary>
      function IsPlaying : boolean;
      /// <summary> Starts the playback of the musicdirector. Because the single layer need to played synrochonusly,
      /// after playback no layer can be added.</summary>
      procedure Play;
      /// <summary> Pauses the playback of the musicdirector. </summary>
      procedure Pause;
      /// <summary> Stops the playback of the musicdirector - stop the playback of every single layer and intro.</summary>
      procedure Stop;
      /// <summary> No special.</summary>
      constructor Create();
      /// <summary> Stops the playback and free all resources.</summary>
      destructor Destroy; override;

  end;

  /// <summary> Main class for loading and playing sounds, music. Also offers some method for global control, like set listener etc.</summary>
  TSoundManager = class
    public type
      EnumMusicPlayerStatus = (psPlaying, psStopped, psPause);

      TPlayList = class
        private
          FRandom : boolean;
          FRepeat : boolean;
          FStatus : EnumMusicPlayerStatus;
          FOggStream : TOGGStream;
          FPlayList, FCurrentPlayList : TStringList;
          FVolume : integer;
          FEndingTime : Cardinal;
          procedure SetVolume(const Value : integer);
          /// <summary> Value to adjust only volume for MusicPlayback. MaxValue = 100, MinValue = 0. Value out of range are clamped.</summary>
        public
          property Volume : integer read FVolume write SetVolume;
          /// <summary> provide current status of playlist, like music ist playing or stopped</summary>
          property Status : EnumMusicPlayerStatus read FStatus;
          /// <summary> If True the order of musicfiles played from PlayList is randomize.
          /// Every file will only choose once until all files are played.</summary>
          property Shuffle : boolean read FRandom write FRandom;
          /// <summary> If true the PlayList will again played after finished. Property doesn't named only Repeat, beause it is a reserved identifier in Delphi;)</summary>
          property RepeatList : boolean read FRepeat write FRepeat;
          /// <summary> Default constructor...boring;)</summary>
          constructor Create;
          /// <summary> Start playback all musicfiles from PlayList and continue if pause. If playback already in progress, nothing happens.</summary>
          procedure Play; overload;
          /// <summary> Play musicfile in ogg format instant, regardless if it is added to PlayList or not.
          /// Any other running MusicPlayback, from PlayList or departed Play calls, is immediately aborted. </summary>
          /// <param name="ContinuePlayListAfterFinish"> If True normal PlayList is played after finishing this file.</param>
          /// <param name="PlayTime"> Value in msec. If PlayTime <> 0 then playback is stopped after playtime</param>
          procedure Play(FileName : string; PlayTime : Cardinal = 0); overload;
          /// <summary> Pause the playback, an again call or "Play" call continue the playback.</summary>
          procedure Pause;
          /// <summary> Stops current playback and reset already played status of all files. </summary>
          procedure Stop;
          /// <summary> Start next musicplayback from playlist, current playback is stopped</summary>
          procedure NextMusicFile;
          /// <summary> Add musicfile in ogg formt to the end of PlayList. If file already exists in PlayList, nothing happens.</summary>
          procedure AddMusicFileToPlayList(FileName : string);
          /// <summary> Delete file from PlayList. If File is current played, it will NOT be stopped!!</summary>
          procedure DeleteMusicFileFromPlayList(FileName : string);
          /// <summary> Delete all musicfiles from PlayList. Current PlayBack will NOT be stopped!!</summary>
          procedure ClearPlayList;
          /// <summary> perform all updates, like loading new data for MusicStreaming</summary>
          procedure Idle;
          /// <summary> Free all allocated resources and stops playback.</summary>
          destructor Destroy; override;
      end;

    private type
      /// <summary> Collect all published handles to one source.</summary>
      TPublishedHandles = class
        PublishedSources : TObjectList<TSoundHandle>;
        Source : TALuint;
        /// <summary> Will invalidate all published handles and prevent </summary>
        procedure InvalidateHandles;
        constructor Create(Source : TALuint);
        destructor Destroy; override;
      end;

    private const
      EXTENDCOUNT       = 8;
      SOUND_MINDISTANCE = 200; // distance in ms between two identically sounds
    private
      FPlayList : TPlayList;
      FVolume : integer;
      FVolumeMap : TDictionary<EnumSoundType, integer>;
      FMuteMap : TDictionary<EnumSoundType, boolean>;
      FSoundEffects : TObjectList<TSoundEffect>;
      FSoundBuffers : TDictionary<string, TALuint>;
      // last timestamp of a played sound
      FLastPlayed : TDictionary<TALuint, int64>;
      FSoundSources : TList<TALuint>;
      FHandles : TObjectDictionary<TALuint, TPublishedHandles>;
      FRefrenceDistance : single;
      FMaxDistance : single;
      FListenerPosition : RVector3;
      FDistanceModel : Enum3DSoundDistanceModel;
      FRolloffFactor : single;
      FMusicDirector : TMusicDirector;
      procedure SetMasterVolume(const Value : integer);
      // load a WaveFile into Buffer
      function LoadSoundFileIntoBuffer(FileName : string) : TALuint;
      // unload all pooled buffers and delete them from dictionary
      procedure FreeSoundBuffers;
      function GetReadySource : TSoundHandle;
      /// <summary> Return true if extend was successfull else, false</summary>
      function ExtendSources : boolean;
      // Free all allocated soundsources and stop playback
      procedure FreeSoundSources;
      procedure SetDistanceModel(const Value : Enum3DSoundDistanceModel);
      procedure SetListenerPosition(const Value : RVector3);
      procedure SetMaxDistance(const Value : single);
      procedure SetReferenceDistance(const Value : single);
      procedure SetRolloffFactor(const Value : single);
      /// <summary> Prepare a source for playback by setting all global settings like distance model or max gain</summary>
      procedure SetUpSource(Source : TALuint);
      procedure SetUpAllSources;
      procedure SetVolumeForType(SoundType : EnumSoundType; Volume : integer);
      function GetVolumeType(SoundType : EnumSoundType) : integer;
      /// <summary> Return true if sound is allowed to play. This function will limite the number of simultaneous played sounds.</summary>
      function CheckSoundAllowedToPlay(Buffer : TALuint) : boolean;
    public
      // =========================== Settings for 3D Sound =====================
      property ListenerPosition : RVector3 read FListenerPosition write SetListenerPosition;
      property DistanceModel : Enum3DSoundDistanceModel read FDistanceModel write SetDistanceModel;
      property RolloffFactor : single read FRolloffFactor write SetRolloffFactor;
      property ReferenceDistance : single read FRefrenceDistance write SetReferenceDistance;
      property MaxDistance : single read FMaxDistance write SetMaxDistance;
      /// <summary>General volume for all SoundPlayback. MaxValue = 100, MinValue = 0. Value out of range are clamped.
      /// Default = 70.</summary>
      property Volume : integer read FVolume write SetMasterVolume;
      /// <summary> Value to adjust volume for a specific type. MaxValue = 100, MinValue = 0.  Value out of range are clamped.</summary>
      property VolumeForType[SoundType : EnumSoundType] : integer read GetVolumeType write SetVolumeForType;
      /// <summary> Mutes or unmutes a specific sound type. Muted sounds won't get played. </summary>
      procedure SetMute(SoundType : EnumSoundType; Muted : boolean);
      function IsMuted(SoundType : EnumSoundType) : boolean;
      property PlayList : TPlayList read FPlayList;
      property MusicDirector : TMusicDirector read FMusicDirector;
      /// <summary> Constructor, acquire soundcard</summary>
      constructor Create;
      /// <summary> Load a Soundeffect from file and return Controllclass for it. All further operation (like play etc.) are present in Controllclass.</summary>
      /// <param name="FileName"> Absolute filename of sound.</param>
      /// <param name="Enable3DSound"> If true sound will be treated as 3DSound and positionchanges will affect sound. Else sound will be treated as
      /// normale sound without any volumedropdown. ATTENTION! Only monosounds can be used as 3Dsound.</param>
      function LoadSoundEffect(FileName : string; Enable3DSound : boolean; SoundType : EnumSoundType; FailSilently : boolean = False) : TSoundEffect;
      /// <summary> Play musicfile in ogg format instantly. Any other running MusicPlayback, from PlayList or departed PlayMusic
      /// calls, is immediately aborted.</summary>
      /// <param name="PlayTime"> Value in msec. If PlayTime <> 0 then playback is stopped after playtime</param>
      procedure PlayMusic(FileName : string; PlayTime : Cardinal = 0);
      /// <summary> perform all updates, like loading new data for MusicStreaming</summary>
      procedure Idle();
      /// <summary> Immediately stop all sound (NOT music) playback.</summary>
      procedure StopAllSounds;
      /// <summary> Free all acquired resources, like soundcard, loaded SoundEffects etc.</summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  SoundManager : TSoundManager;

implementation

function AL_FormatError(ErrorCode : TALenum) : string;
begin
  case ErrorCode of
    AL_INVALID_NAME : result := 'AL_INVALID_NAME';
    AL_INVALID_ENUM : result := 'AL_INVALID_ENUM';
    AL_INVALID_VALUE : result := 'AL_INVALID_VALUE';
    AL_INVALID_OPERATION : result := 'AL_INVALID_OPERATION';
    AL_OUT_OF_MEMORY : result := 'AL_OUT_OF_MEMORY';
  else
    result := Format('Unknown errorcode "%s"', [IntToHex(ErrorCode, 4)]);
  end;
end;

procedure ReportError(Error : TALenum);
begin
  HLog.Log(Format('ALError: %s', [AL_FormatError(Error)]))
end;

function ALCheckForErrors() : boolean;
var
  Error : TALenum;
begin
  Error := alGetError;
  if Error <> AL_NO_ERROR then
  begin
    ReportError(Error);
    // found error
    result := False;
  end
  // no error found, return alright
  else result := True;
end;

{ TSoundManager.TPlayList }

procedure TSoundManager.TPlayList.AddMusicFileToPlayList(FileName : string);
begin
  if AnsiUpperCase(ExtractFileExt(FileName)) <> '.OGG' then raise Exception.Create('TSoundManager.TPlayList.AddMusicFileToPlayList: Unsupported fileformat. Only support ogg files.');
  if not FileExists(FileName) then Exception.Create('TSoundManager.TPlayList.AddMusicFileToPlayList: Musicfile "' + FileName + '" not found.');
  // discard already existing files
  if FPlayList.IndexOf(FileName) > 0 then Exit;
  FPlayList.Add(FileName);
  FCurrentPlayList.Add(FileName);
end;

procedure TSoundManager.TPlayList.ClearPlayList;
begin
  FPlayList.Free;
  FCurrentPlayList.Free;
end;

constructor TSoundManager.TPlayList.Create;
begin
  FOggStream := TOGGStream.Create;
  FPlayList := TStringList.Create;
  FCurrentPlayList := TStringList.Create;
  FStatus := psStopped;
  Randomize;
  FVolume := 100;
end;

procedure TSoundManager.TPlayList.DeleteMusicFileFromPlayList(FileName : string);
begin
  if FPlayList.IndexOf(FileName) < 0 then raise Exception.Create('TSoundManager.TPlayList.DeleteMusicFileFromPlayList: Musicfile "' + FileName + '" not present in PlayList.');
  FPlayList.Delete(FPlayList.IndexOf(FileName));
  if FCurrentPlayList.IndexOf(FileName) > 0 then FCurrentPlayList.Delete(FCurrentPlayList.IndexOf(FileName));
end;

destructor TSoundManager.TPlayList.Destroy;
begin
  FOggStream.Free;
  FPlayList.Free;
  FCurrentPlayList.Free;
  inherited;
end;

procedure TSoundManager.TPlayList.Idle;
begin
  if ((FOggStream.Status = oggStopped) or ((FEndingTime > 0) and (FEndingTime < GetTickCount))) and (Status = psPlaying) then
      NextMusicFile;
end;

procedure TSoundManager.TPlayList.NextMusicFile;
var
  NextFile : string;
begin
  if FPlayList.Count <= 0 then Exit;
  if (FCurrentPlayList.Count <= 0) or (Status = psStopped) then
  begin
    if RepeatList or (Status = psStopped) then
    begin
      FCurrentPlayList.Clear;
      FCurrentPlayList.AddStrings(FPlayList);
    end
    else
    begin
      Stop;
      Exit;
    end;
  end;
  NextFile := FCurrentPlayList[HGeneric.TertOp<integer>(Shuffle, random(FCurrentPlayList.Count), 0)];
  FCurrentPlayList.Delete(FCurrentPlayList.IndexOf(NextFile));
  Stop;
  Play(NextFile);
end;

procedure TSoundManager.TPlayList.Pause;
begin
  FOggStream.Pause;
  FStatus := psPause;
end;

procedure TSoundManager.TPlayList.Play;
begin
  case Status of
    psPlaying :;
    psStopped : NextMusicFile;
    psPause :
      begin
        FOggStream.Play;
        FStatus := psPlaying;
      end;
  end;
end;

procedure TSoundManager.TPlayList.Play(FileName : string; PlayTime : Cardinal);
begin
  if AnsiUpperCase(ExtractFileExt(FileName)) <> '.OGG' then raise Exception.Create('TSoundManager.TPlayList.Play: Unsupported fileformat. Only support ogg files.');
  if not FileExists(FileName) then Exception.Create('TSoundManager.TPlayList.Play: Musicfile "' + FileName + '" not found.');
  if FStatus = psPlaying then Stop;
  FOggStream.Open(FileName);
  FOggStream.Play;
  FStatus := psPlaying;
  if PlayTime <> 0 then FEndingTime := GetTickCount + PlayTime
  else FEndingTime := 0;
end;

procedure TSoundManager.TPlayList.SetVolume(const Value : integer);
begin
  FVolume := Value;
  FOggStream.Volume := (Value / 100);
end;

procedure TSoundManager.TPlayList.Stop;
begin
  FOggStream.Stop;
  FStatus := psStopped;
end;

{ TSoundManager }

procedure TSoundManager.FreeSoundBuffers;
var
  Buffer : TALuint;
begin
  for Buffer in FSoundBuffers.Values do
  begin
    AlDeleteBuffers(1, @Buffer);
  end;
  FSoundBuffers.Clear;
end;

procedure TSoundManager.FreeSoundSources;
var
  Sources : TArray<TALuint>;
begin
  Sources := FSoundSources.ToArray;
  AlDeleteSources(Length(Sources), @Sources[0]);
end;

constructor TSoundManager.Create;
var
  CorrectInit : boolean;
  orientation : array [0 .. 5] of TALFloat;
begin
  CorrectInit := InitOpenAL;
  if not CorrectInit then
  begin
    MessageDlg('Couldn''t initialize openAL. Pleses install openAL 1.1 libraries.', mtError, [mbOK], 0);
    halt;
  end;
  AlutInit(nil, []);
  OggStreamingThread := TOggStreamingThread.Create;
  FVolumeMap := TDictionary<EnumSoundType, integer>.Create();
  FLastPlayed := TDictionary<TALuint, int64>.Create();
  FMuteMap := TDictionary<EnumSoundType, boolean>.Create;
  FPlayList := TPlayList.Create;
  FSoundEffects := TObjectList<TSoundEffect>.Create(False);
  FSoundBuffers := TDictionary<string, TALuint>.Create;
  FSoundSources := TList<TALuint>.Create;
  FHandles := TObjectDictionary<TALuint, TPublishedHandles>.Create([doOwnsValues]);
  Volume := 70;
  // setup listener
  orientation[0] := 0;
  orientation[1] := 0;
  orientation[2] := 1;
  orientation[3] := 0;
  orientation[4] := -1;
  orientation[5] := 0;
  alListenerfv(AL_ORIENTATION, @orientation[0]);
  ALCheckForErrors;
  FMusicDirector := TMusicDirector.Create;
  FMusicDirector.LayerFadeInTime := 2000;
  FMusicDirector.LayerFadeOutTime := 2000;
  FMusicDirector.LayerMinimumPlayingTime := 10000;
  VolumeForType[stMusic] := 70;
end;

destructor TSoundManager.Destroy;
var
  i : integer;
begin
  FLastPlayed.Free;
  FVolumeMap.Free;
  FMuteMap.Free;
  FHandles.Free;
  FreeSoundSources();
  FSoundSources.Free;
  // ClearBuffers and dictionary
  FreeSoundBuffers();
  FSoundBuffers.Free;
  for i := FSoundEffects.Count - 1 downto 0 do
      FSoundEffects[i].ForceFree;
  FSoundEffects.Free;
  FPlayList.Free;
  FMusicDirector.Free;
  OggStreamingThread.Free;
  AlutExit();
  inherited;
end;

function TSoundManager.ExtendSources : boolean;
var
  NewSources : array of TALuint;
  Error : TALenum;
begin
  // clear errorstate
  ALCheckForErrors;
  // extend SourceArray and bind new sources with buffer
  SetLength(NewSources, EXTENDCOUNT);
  alGenSources(EXTENDCOUNT, @NewSources[0]);
  Error := alGetError;
  // any Error? Discard extended array
  if Error <> AL_NO_ERROR then
  begin
    case Error of
      AL_OUT_OF_MEMORY : Exit(False);
    else
      begin
        ReportError(Error);
        Exit(False);
      end;
    end;
  end;
  // reach code? anything fine, add new sources
  FSoundSources.AddRange(NewSources);
  NewSources := nil;
  result := True;
end;

function TSoundManager.GetReadySource : TSoundHandle;
var
  state : TALInt;
  i : integer;
  Source : TALuint;
  publishedHandles : TPublishedHandles;
begin
  // clear error state
  ALCheckForErrors();
  Source := AL_NONE;
  // search for ready source
  for i := 0 to FSoundSources.Count - 1 do
  begin
    alGetSourcei(FSoundSources[i], AL_SOURCE_STATE, @state);
    ALCheckForErrors();
    // found any ready source, stop searching
    if state <> AL_PLAYING then
    begin
      Source := FSoundSources[i];
      break;
    end;
  end;
  // no ready source found, try to extend array and use first new source
  if Source = AL_NONE then
  begin
    if ExtendSources() then
    begin
      Source := FSoundSources.Last;
    end
    else Source := AL_NONE;
  end;
  // any usable source found? create and save handle,
  // old handles to source will now be invalid, because source is used for another soundeffect
  if (Source <> AL_NONE) then
  begin
    // prepare source
    SetUpSource(Source);
    if not FHandles.TryGetValue(Source, publishedHandles) then
    begin
      publishedHandles := TPublishedHandles.Create(Source);
      FHandles.Add(Source, publishedHandles);
    end;
    // old handles should not longer used
    publishedHandles.InvalidateHandles;
    result := TSoundHandle.Create(Source);
    publishedHandles.PublishedSources.Add(result);
  end
  else
      result := nil;
end;

function TSoundManager.GetVolumeType(SoundType : EnumSoundType) : integer;
begin
  if not FVolumeMap.TryGetValue(SoundType, result) then result := 70;
end;

procedure TSoundManager.Idle;
var
  i : integer;
begin
  PlayList.Idle;
  MusicDirector.Idle;
  for i := FSoundEffects.Count - 1 downto 0 do
      FSoundEffects[i].Idle;
end;

function TSoundManager.IsMuted(SoundType : EnumSoundType) : boolean;
begin
  if not FMuteMap.TryGetValue(SoundType, result) then result := False;
end;

function TSoundManager.LoadSoundEffect(FileName : string; Enable3DSound : boolean; SoundType : EnumSoundType; FailSilently : boolean) : TSoundEffect;
var
  Buffer : TALuint;
begin
  FileName := AbsolutePath(FileName);
  if not FileExists(FileName) then
  begin
    HLog.ProcessError(FailSilently, 'TSoundEffect.Create: Soundfile "' + FileName + '" doesn''t exist.', EFileNotFoundException);
    Exit(nil);
  end;
  if AnsiUpperCase(ExtractFileExt(FileName)) <> '.WAV' then
  begin
    HLog.ProcessError(FailSilently, 'TSoundEffect.Create: Unsupported fileformat, only supports wav format for soundeffects!', ESoundException);
    Exit(nil);
  end;

  // File not already exist load them and add to pool
  if not FSoundBuffers.TryGetValue(AnsiUpperCase(FileName), Buffer) then
  begin
    Buffer := LoadSoundFileIntoBuffer(FileName);
    FSoundBuffers.Add(AnsiUpperCase(FileName), Buffer);
  end;
  result := TSoundEffect.Create(Buffer, Enable3DSound, FileName, SoundType, self);
  FSoundEffects.Add(result);
end;

function TSoundManager.LoadSoundFileIntoBuffer(FileName : string) : TALuint;
var
  Format : TALenum;
  size : TALSizei;
  freq : TALSizei;
  loop : TALInt;
  data : TALVoid;
begin
  // load data from wav and write it to buffer
  AlutLoadWavFile(FileName, Format, data, size, freq, loop);
  AlGenBuffers(1, @result);
  AlBufferData(result, Format, data, size, freq);
  AlutUnloadWav(Format, data, size, freq);
end;

procedure TSoundManager.PlayMusic(FileName : string; PlayTime : Cardinal);
begin
  FPlayList.Play(AbsolutePath(FileName), PlayTime);
end;

procedure TSoundManager.SetDistanceModel(const Value : Enum3DSoundDistanceModel);
var
  model : TALenum;
begin
  // clear error state
  ALCheckForErrors;
  FDistanceModel := Value;
  case Value of
    dmDisabled : model := AL_NONE;
    dmInverseDistance : model := AL_INVERSE_DISTANCE;
    dmInverseDistanceClamped : model := AL_INVERSE_DISTANCE_CLAMPED;
    dmLinearDistance : model := AL_LINEAR_DISTANCE;
    dmLinearDistanceClamped : model := AL_LINEAR_DISTANCE_CLAMPED;
    dmExponentialDistance : model := AL_EXPONENT_DISTANCE;
    dmExponentialDistanceClamped : model := AL_EXPONENT_DISTANCE_CLAMPED;
  else model := AL_NONE;
  end;
  alDistanceModel(model);
  ALCheckForErrors;
end;

procedure TSoundManager.SetListenerPosition(const Value : RVector3);
begin
  FListenerPosition := Value;
  alListener3f(AL_POSITION, Value.X, Value.Y, Value.Z);
end;

procedure TSoundManager.SetMaxDistance(const Value : single);
begin
  FMaxDistance := Value;
  SetUpAllSources;
end;

procedure TSoundManager.SetMute(SoundType : EnumSoundType; Muted : boolean);
var
  SFX : TSoundEffect;
begin
  FMuteMap.AddOrSetValue(SoundType, Muted);

  if SoundType <> stMusic then
  begin
    for SFX in FSoundEffects do
      if (SFX.SoundType = SoundType) and Muted then SFX.Stop;
  end
  else if Muted then PlayList.Stop;
end;

procedure TSoundManager.SetReferenceDistance(const Value : single);
begin
  FRefrenceDistance := Value;
  SetUpAllSources;
end;

procedure TSoundManager.SetRolloffFactor(const Value : single);
begin
  FRolloffFactor := Value;
  SetUpAllSources;
end;

procedure TSoundManager.SetUpAllSources;
var
  Source : TALuint;
begin
  for Source in FSoundSources do
  begin
    SetUpSource(Source);
  end;
end;

procedure TSoundManager.SetUpSource(Source : TALuint);
begin
  // clear all errorcodes
  ALCheckForErrors;
  // don't allow any amplification
  alSourcef(Source, AL_MAX_GAIN, 1);
  ALCheckForErrors;
  // source can be totaly mute
  alSourcef(Source, AL_MIN_GAIN, 0);
  ALCheckForErrors;
  // settings for 3D sound
  alSourcef(Source, AL_MAX_DISTANCE, FMaxDistance);
  alSourcef(Source, AL_REFERENCE_DISTANCE, FRefrenceDistance);
  alSourcef(Source, AL_ROLLOFF_FACTOR, FRolloffFactor);
  ALCheckForErrors;
end;

procedure TSoundManager.SetVolumeForType(SoundType : EnumSoundType; Volume : integer);
var
  SFX : TSoundEffect;
begin
  ALCheckForErrors;
  Volume := HMath.clamp(Volume, 0, 100);
  FVolumeMap.AddOrSetValue(SoundType, Volume);

  if SoundType <> stMusic then
  begin
    for SFX in FSoundEffects do
      if SFX.SoundType = SoundType then
      begin
        SFX.UpdateVolume;
      end;
  end
  else
  begin
    PlayList.Volume := Volume;
    MusicDirector.Volume := Volume;
  end;
  ALCheckForErrors;
end;

procedure TSoundManager.StopAllSounds;
var
  Source : TALInt;
begin
  ALCheckForErrors;
  for Source in FSoundSources do
  begin
    alSourceStop(Source);
    ALCheckForErrors;
  end;
end;

function TSoundManager.CheckSoundAllowedToPlay(Buffer : TALuint) : boolean;
  function GetBufferLength(Buffer : TALuint) : integer;
  var
    sizeInBytes, channels, bits, frequency : TALInt;
  begin
    sizeInBytes := 0;
    channels := 1;
    bits := 1;
    frequency := 1;
    alGetBufferi(Buffer, AL_SIZE, @sizeInBytes);
    alGetBufferi(Buffer, AL_CHANNELS, @sizeInBytes);
    alGetBufferi(Buffer, AL_BITS, @sizeInBytes);
    alGetBufferi(Buffer, AL_FREQUENCY, @sizeInBytes);
    result := round((sizeInBytes * 8 / (channels * bits)) / frequency * 1000);
  end;

var
  timeStamp : int64;
begin
  timeStamp := TimeManager.GetTimestamp;
  // only play a sound, if it was not played SOUND_MINDISTANCE msec before or
  // length of sound before
  if FLastPlayed.ContainsKey(Buffer) then
  begin
    if ((timeStamp - FLastPlayed[Buffer]) > Min(SOUND_MINDISTANCE, GetBufferLength(Buffer))) then
    begin
      FLastPlayed[Buffer] := timeStamp;
      result := True;
    end
    else
        result := False;
  end
  else
  begin
    // never played before, go ahead
    FLastPlayed.Add(Buffer, timeStamp);
    result := True;
  end;
end;

procedure TSoundManager.SetMasterVolume(const Value : integer);
begin
  ALCheckForErrors;
  FVolume := HMath.clamp(Value, 0, 100);
  alListenerf(AL_GAIN, FVolume / 100);
  ALCheckForErrors;
end;

{ TSoundEffect }

function TSoundEffect.CanDestroyed : boolean;
begin
  // no delay -> kill sounds
  result := (FDelayedSounds.Count = 0) or FForceFree;
end;

constructor TSoundEffect.Create(Buffer : TALuint; Enable3DSound : boolean; FileName : string; SoundType : EnumSoundType; SourceSoundManager : TSoundManager);
var
  channels : TALInt;
begin
  FFileName := FileName;
  FSoundType := SoundType;
  FSoundManager := SourceSoundManager;
  FDelayedSounds := TList<TSoundjob>.Create;
  FIs3DSound := Enable3DSound;
  if FIs3DSound then
  begin
    alGetBufferi(Buffer, AL_CHANNELS, @channels);
    if channels <> 1 then
        HLog.Log('TSoundEffect.Create: 3DSound only for mono wav files supported. "' + FileName + '" has ' + Inttostr(channels) + ' channels.');
  end;
  ALCheckForErrors;
  FBuffer := Buffer;
  Volume := 100;
  FPitch := 1.0;
  FHandles := TList<TSoundHandle>.Create;
  FPosition := RVector3.ZERO;
  FDirection := RVector3.ZERO;
  FVelocity := RVector3.ZERO;
end;

destructor TSoundEffect.Destroy;
begin
  // delayed freeinstance
  FWaitForFree := True;
  inherited;
end;

procedure TSoundEffect.ForceFree;
begin
  FForceFree := True;
  self.Free;
end;

procedure TSoundEffect.FreeInstance;
var
  i : integer;
begin
  // delayed freeinstance
  if CanDestroyed then
  begin
    FSoundManager.FSoundEffects.Remove(self);
    // first clear all delayed sounds
    for i := FDelayedSounds.Count - 1 downto 0 do
    begin
      FDelayedSounds[i].Free;
    end;
    FDelayedSounds.Free;
    FHandles.Free;
    inherited;
  end;
end;

function TSoundEffect.GetLength : integer;
var
  sizeInBytes, channels, bits, frequency : TALInt;
begin
  sizeInBytes := 0;
  channels := 1;
  bits := 1;
  frequency := 1;
  alGetBufferi(FBuffer, AL_SIZE, @sizeInBytes);
  alGetBufferi(FBuffer, AL_CHANNELS, @sizeInBytes);
  alGetBufferi(FBuffer, AL_BITS, @sizeInBytes);
  alGetBufferi(FBuffer, AL_FREQUENCY, @sizeInBytes);
  result := round((sizeInBytes * 8 / (channels * bits)) / frequency * 1000);
end;

function TSoundEffect.GetName : string;
begin
  result := ChangeFileExt(ExtractFileName(FileName), '');
end;

procedure TSoundEffect.Idle;
var
  i : integer;
begin
  for i := FDelayedSounds.Count - 1 downto 0 do
  begin
    FDelayedSounds[i].Idle;
  end;
  // manage self
  if FWaitForFree and CanDestroyed then
      self.Free;
end;

procedure TSoundEffect.Play(Delay : integer; looping : boolean);
var
  HandleToSource : TSoundHandle;
begin
  if FSoundManager.IsMuted(FSoundType) then Exit;
  // clear error state
  ALCheckForErrors;
  // delay <= 0? no delay necessary
  if (Delay <= 0) then
  begin
    HandleToSource := FSoundManager.GetReadySource;
    // no source found, skip soundplayback and report error
    if HandleToSource <> nil then
    begin
      FHandles.Add(HandleToSource);
      assert(HandleToSource.Valid);
      // assign sounddata (buffer)
      AlSourcei(HandleToSource.GetSource, AL_BUFFER, FBuffer);
      ALCheckForErrors();

      // adjust volume
      alSourcef(HandleToSource.GetSource, AL_GAIN, FVolume);
      ALCheckForErrors();

      // adjust pitch
      alSourcef(HandleToSource.GetSource, AL_PITCH, FPitch);
      ALCheckForErrors();

      // set 3d properties
      Update3D;

      if looping then AlSourcei(HandleToSource.GetSource, AL_LOOPING, AL_TRUE)
      else AlSourcei(HandleToSource.GetSource, AL_LOOPING, AL_FALSE);

      // finally play
      if FSoundManager.CheckSoundAllowedToPlay(FBuffer) then
          AlSourcePlay(HandleToSource.GetSource);
      ALCheckForErrors();
    end
    else HLog.Log('TSoundEffect.Play: No ready source was found.');
  end
  else
  begin
    FDelayedSounds.Add(TSoundjob.Create(Delay, self))
  end;
end;

procedure TSoundEffect.SetDirection(const Value : RVector3);
begin
  if not Is3DSound then
      HLog.Write(elError, 'TSoundEffect.SetDirection: Set 3D data for non 3d sound is not supported!', ENotSupportedException);
  FDirection := Value;
end;

procedure TSoundEffect.SetIs3DSound(const Value : boolean);
begin
  if Value = FIs3DSound then Exit;
  FIs3DSound := Value;
  if not FIs3DSound then
  begin
    FPosition := RVector3.ZERO;
    FDirection := RVector3.ZERO;
    FVelocity := RVector3.ZERO;
  end;
  Update3D;
end;

procedure TSoundEffect.SetPitch(const Value : single);
begin
  FPitch := Value;
end;

procedure TSoundEffect.SetPosition(const Value : RVector3);
begin
  if not Is3DSound then
      HLog.Write(elError, 'TSoundEffect.SetDirection: Set 3D data for non 3d sound is not supported!', ENotSupportedException);
  FPosition := Value;
end;

procedure TSoundEffect.SetVelocity(const Value : RVector3);
begin
  if not Is3DSound then
      HLog.Write(elError, 'TSoundEffect.SetDirection: Set 3D data for non 3d sound is not supported!', ENotSupportedException);
  FVelocity := Value;
end;

procedure TSoundEffect.SetVolume(const Value : integer);
begin
  FLocalVolume := HMath.clamp(Value, 0, 100);
  UpdateVolume;
end;

procedure TSoundEffect.Stop;
var
  handle : TSoundHandle;
begin
  for handle in FHandles do
  begin
    if handle.Valid then
        alSourceStop(handle.GetSource);
  end;
end;

procedure TSoundEffect.Update3D;
begin
  ALCheckForErrors;
  // only update last handle, because naturally if a soundeffect multiple plays a sound only new sound want to be controlled
  // like fire and forgot
  if (FHandles.Count > 0) and FHandles.Last.Valid then
  begin
    if Is3DSound then
        AlSourcei(FHandles.Last.GetSource, AL_SOURCE_RELATIVE, AL_FALSE)
    else
        AlSourcei(FHandles.Last.GetSource, AL_SOURCE_RELATIVE, AL_TRUE);
    alSource3f(FHandles.Last.GetSource, AL_POSITION, FPosition.X, FPosition.Y, FPosition.Z);
    alSource3f(FHandles.Last.GetSource, AL_VELOCITY, FVelocity.X, FVelocity.Y, FVelocity.Z);
    alSource3f(FHandles.Last.GetSource, AL_DIRECTION, FDirection.X, FDirection.Y, FDirection.Z);
  end;
  ALCheckForErrors;
end;

procedure TSoundEffect.UpdateVolume;
begin
  FVolume := (FLocalVolume / 100.0) * (FSoundManager.VolumeForType[FSoundType] / 100.0);
end;

{ TSoundEffect.TSoundjob }

constructor TSoundEffect.TSoundjob.Create(Delay : integer; TargetSoundEffect : TSoundEffect);
begin
  FDelayTimer := TTimer.CreateAndStart(Delay);
  FTargetSoundEffect := TargetSoundEffect;
end;

destructor TSoundEffect.TSoundjob.Destroy;
begin
  FDelayTimer.Free;
  FTargetSoundEffect.FDelayedSounds.Remove(self);
  inherited;
end;

procedure TSoundEffect.TSoundjob.Idle;
begin
  if FDelayTimer.Expired then
  begin
    FTargetSoundEffect.Play();
    self.Free;
  end;
end;

{ TSoundHandle }

constructor TSoundHandle.Create(Source : TALuint);
begin
  FSource := Source;
  // every new handle is valid
  FValid := True;
end;

function TSoundHandle.GetSource : TALuint;
begin
  if not Valid then
      raise ESoundException.Create('TSoundHandle.GetSource: Tried to access an invalid handle. Handle is not valid anymore.');
  result := FSource;
end;

{ TSoundManager.TPublishedHandles }

constructor TSoundManager.TPublishedHandles.Create(Source : TALuint);
begin
  PublishedSources := TObjectList<TSoundHandle>.Create();
  self.Source := Source;
end;

destructor TSoundManager.TPublishedHandles.Destroy;
begin
  PublishedSources.Free;
  inherited;
end;

procedure TSoundManager.TPublishedHandles.InvalidateHandles;
var
  i : integer;
begin
  for i := PublishedSources.Count - 1 downto 0 do
  begin
    // if any not valid handle found, it can assumed that all older handles (before current handles) already invalid
    if not PublishedSources[i].Valid then
        Exit;
    // invalidate
    PublishedSources[i].FValid := False;
  end;
end;

{ TMusicDirector.TLayer }

constructor TMusicDirector.TLayer.Create(const FileName : string; const IntensityTriggerRange : RRange);
begin
  if not FileExists(FileName) then
  begin
    raise EFileNotFoundException.CreateFmt('TMusicDirector.TLayer.Create: Could not find the file "%s".', [FileName]);
  end;
  if ExtractFileExt(FileName).ToLowerInvariant <> '.ogg' then
  begin
    raise EUnsupportedFileformat.CreateFmt('TMusicDirector.TLayer.Create: Currently the soundengine only supports Ogg files, so the file "%s" is not supported.', [FileName]);
  end;
  OggStream := TOGGStream.Create;
  OggStream.Open(FileName);
  self.IntensityTriggerRange := IntensityTriggerRange;
end;

destructor TMusicDirector.TLayer.Destroy;
begin
  OggStream.Free;
  inherited;
end;

procedure TMusicDirector.TLayer.FadeIn(FadeDuration : LongWord);
begin
  if not IsCurrentlyPlaying then
  begin
    LastStatusChange := GetTickCount;
    OggStream.FadeIn(FadeDuration);
  end;
end;

procedure TMusicDirector.TLayer.FadeOut(FadeDuration : LongWord);
begin
  if IsCurrentlyPlaying then
  begin
    LastStatusChange := GetTickCount;
    OggStream.FadeOut(FadeDuration);
  end;
end;

function TMusicDirector.TLayer.IsCurrentlyPlaying : boolean;
begin
  result := not(OggStream.VolumeStatus in [volZero, volFadeOut]);
end;

{ TMusicDirector }

procedure TMusicDirector.AddLayer(FileName : string; const IntensityTriggerRange : RRange);
var
  StreamingChannel : ISoundStreamingChannel;
  Stream : TOGGStream;
begin
  if not IsPlaying then
  begin
    FileName := AbsolutePath(FileName);
    if Assigned(FIntro) then
    begin
      if FLayer.Count = 0 then
          StreamingChannel := FIntro.StreamingChannel
      else
      begin
        Stream := TOGGStream.Create;
        Stream.Open(FIntro.FileName);
        // mute dummy intro
        Stream.VolumeStatus := volZero;
        FDummyIntros.Add(Stream);
        StreamingChannel := Stream.StreamingChannel;
      end;
      FLayer.Add(TLayer.Create(FileName, IntensityTriggerRange));
      FLayer.Last.OggStream.StreamingChannel := StreamingChannel;
      FLayer.Last.OggStream.loop := True;
      SetVolume(Volume);
    end
    else
    begin
      FLayer.Add(TLayer.Create(FileName, IntensityTriggerRange));
      FLayer.Last.OggStream.loop := True;
      SetVolume(Volume);
    end;
  end
  else
      raise ESoundException.Create('TMusicDirector.AddLayer: Can''t add layer to MusicDirector while playback is already started.');
end;

procedure TMusicDirector.ClearLayers;
begin
  Stop;
  FreeAndNil(FIntro);
  FDummyIntros.Clear;
  FLayer.Clear;
end;

constructor TMusicDirector.Create;
begin
  FLayer := TUltimateObjectList<TLayer>.Create;
  FDummyIntros := TObjectList<TOGGStream>.Create();
  FIntensityLevel := 0;
  Volume := 100;
end;

destructor TMusicDirector.Destroy;
begin
  // Stop;
  FDummyIntros.Free;
  FIntro.Free;
  FLayer.Free;
  inherited;
end;

function TMusicDirector.GetLayer(index : integer) : TLayer;
begin
  result := FLayer[index];
end;

function TMusicDirector.GetLayerCount : integer;
begin
  result := FLayer.Count;
end;

procedure TMusicDirector.Idle;
var
  Layer : TLayer;
  shouldPlaying : boolean;
  CurrentTimestamp : LongWord;
begin
  if IsPlaying then
  begin
    CurrentTimestamp := GetTickCount;
    for Layer in FLayer do
    begin
      // ensure the timings of the layer will not differ to much
      // if not SameValue(Layer.OggStream.Position, Position, 0.1) then
      // Layer.OggStream.Position := Position;
      shouldPlaying := Layer.IntensityTriggerRange.InRange(IntensityLevel);
      // differ the status between layer and should playing, do something
      if shouldPlaying <> Layer.IsCurrentlyPlaying then
      begin
        if shouldPlaying then
            Layer.FadeIn(LayerFadeInTime)
        else
          // only stops (fade out) a layer if the layer was at least for LayerMinimumPlayingTime playing
          if (CurrentTimestamp - Layer.LastStatusChange) >= LayerMinimumPlayingTime then
              Layer.FadeOut(LayerFadeOutTime);
      end;
    end;
  end;
end;

function TMusicDirector.IsPlaying : boolean;
begin
  result := FPlaybackStarted;
end;

procedure TMusicDirector.Play;
var
  channels : TArray<ISoundStreamingChannel>;
  i : integer;
begin
  if not FPlaybackStarted then
  begin
    FPlaybackStarted := True;
    SetLength(channels, FLayer.Count);
    for i := 0 to FLayer.Count - 1 do
    begin
      channels[i] := FLayer[i].OggStream.StreamingChannel;
      channels[i].AddStream(FLayer[i].OggStream);
      if FLayer[i].IntensityTriggerRange.InRange(IntensityLevel) then
          FLayer[i].OggStream.VolumeStatus := volFull
      else
          FLayer[i].OggStream.VolumeStatus := volZero;
    end;
    OggStreamingThread.PlayChannelsSynced(channels);
  end;

end;

procedure TMusicDirector.SetIntensityLevel(const Value : single);
begin
  FIntensityLevel := Value;
end;

procedure TMusicDirector.SetIntro(FileName : string);
begin
  if not FPlaybackStarted then
  begin
    FileName := AbsolutePath(FileName);
    FreeAndNil(FIntro);
    if not FileExists(FileName) then
        raise EFileNotFoundException.CreateFmt('TMusicDirector.SetIntro: Could not find the file "%s".', [FileName]);
    if ExtractFileExt(FileName).ToLowerInvariant <> '.ogg' then
        raise EUnsupportedFileformat.CreateFmt('TMusicDirector.SetIntro: Currently the soundengine only supports Ogg files, so the file "%s" is not supported.', [FileName]);
    if FLayer.Count > 0 then
        raise EOggStream.Create('TMusicDirector.SetIntro: Can''t set intro to MusicDirector if any layer is already set, layers need to know if there is a intro or not.');
    FIntro := TOGGStream.Create;
    FIntro.Open(FileName);
    SetVolume(Volume);
  end
  else raise EOggStream.Create('TMusicDirector.SetIntro: Can''t set intro to MusicDirector while playback is already started.');
end;

procedure TMusicDirector.SetVolume(const Value : LongWord);
var
  Layer : TLayer;
begin
  FVolume := EnsureRange(Value, 0, 100);
  if Assigned(FIntro) then
      FIntro.Volume := FVolume / 100;
  for Layer in FLayer do
  begin
    Layer.OggStream.Volume := FVolume / 100;
  end;
end;

procedure TMusicDirector.Pause;
begin
  if FPlaybackStarted then
  begin
    FPlaybackStarted := False;
    if Assigned(FIntro) then
        FIntro.Pause;
    FLayer.Extra.Each(
      procedure(const Layer : TLayer)
      begin
        Layer.OggStream.Pause;
      end);
  end;
end;

procedure TMusicDirector.Stop;
begin
  if FPlaybackStarted then
  begin
    FPlaybackStarted := False;
    if Assigned(FIntro) then
        FIntro.Stop;
    FLayer.Extra.Each(
      procedure(const Layer : TLayer)
      begin
        Layer.OggStream.Stop;
      end);
  end;
end;

end.
