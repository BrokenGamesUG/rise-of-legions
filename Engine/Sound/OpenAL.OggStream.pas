unit OpenAL.OggStream;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Math,
  System.SyncObjs,
  Dialogs,
  OpenAL,
  Vorbisfile,
  Codec,
  Generics.Collections,
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.Threads;

type
  TOggStream = class;

  ISoundStreamingChannel = interface
    procedure UpdateVolumeLevel;
    procedure LoadDataIntoSource;
    function GetSource : TALUInt;
    property Source : TALUInt read GetSource;
    /// <summary> Return true if channel is out of data.</summary>
    function IsEmpty : boolean;
    procedure AddStream(const OggStream : TOggStream);
    procedure Play;
    procedure Stop;
  end;

  ProcOggStreamEvent = procedure(const Sender : TOggStream);

  EOggStream = class(Exception);

  EnumOggStatus = (oggStopped, oggPlaying, oggPause);

  EnumVolumeStatus = (volFadeIn, volFull, volFadeOut, volZero);

  TOggStreamData = class
    private const
      BUFFERSIZE           = 4096 * 8;
      VORBIS_LITTLE_ENDIAN = 0;
      VORBIS_16BIT_SAMPLE  = 2;
      VORBIS_DATA_SIGNED   = 1;
    private
      FOGGFile : TFileStream;
      FOggStreamFile : TOggVorbisFile;
      FVorbisInfo : TVorbisInfo;
      FFormat : TALEnum;
      FFilename : string;
      // loop playback
      FLoop : boolean;
      /// <summary> Return True if streaming of current stream is finished and stream can closed.</summary>
      function IsStreamingFinished : boolean;
      /// <summary> Open stream to read data and initialize buffers (load NO data).</summary>
      procedure OpenStream;
      /// <summary> Return True if stream is already opened for streaming.</summary>
      function IsStreamOpened : boolean;
      /// <summary> Close stream and reset all states to default.</summary>
      procedure CloseStream;
      /// <summary> Read and decode data from stream and write it into buffer.</summary>
      procedure LoadDataFromStream(const Buffer : TALUInt);

    public
  end;

  TOggStream = class(TObject)
    private
      FData : TThreadSafeData<TOggStreamData>;
      FOnPlaybackStopped : ProcOggStreamEvent;
      FStreamingChannel : ISoundStreamingChannel;
      FVolumeLock : TCriticalSection;
      FLogicalVolume : single;
      FFadingTimer : TTimer;
      FVolumeStatus : EnumVolumeStatus;
      FVolume : single;
      procedure SetVolume(const Value : single);
      function GetPosition : double;
      function GetPlayingStatus : EnumOggStatus;
      /// <summary> Compute the logical volume level of this stream.</summary>
      procedure UpdateLogicalVolume;
      function GetFileName : string;
      procedure SetStreamingChannel(const Value : ISoundStreamingChannel);
      function GetStreamingChannel : ISoundStreamingChannel;
      function GetIsLooping : boolean;
      procedure SetIsLooping(const Value : boolean);
    public
      property Loop : boolean read GetIsLooping write SetIsLooping;
      property FileName : string read GetFileName;
      property StreamingChannel : ISoundStreamingChannel read GetStreamingChannel write SetStreamingChannel;
      /// <summary> Called whenever the playback of the stream stops.</summary>
      property OnPlaybackStopped : ProcOggStreamEvent read FOnPlaybackStopped write FOnPlaybackStopped;
      /// <summary> Volume in Range 0..1, Value will be clamped in range, 0 = silence, 1 = full volume of the oggfile
      /// (without any amplification).</summary>
      property Volume : single read FVolume write SetVolume;
      property VolumeStatus : EnumVolumeStatus read FVolumeStatus write FVolumeStatus;
      property LogicalVolume : single read FLogicalVolume;
      property Position : double read GetPosition;
      /// <summary></summary>
      property Status : EnumOggStatus read GetPlayingStatus;
      /// <summary> default constructor...</summary>
      constructor Create;
      /// <summary> Open a new off musicfile for playback, if file not exist -> raise Exception</summary>
      procedure Open(pFileName : string);
      procedure Play;
      procedure Pause;
      procedure Stop;
      /// <summary> Starts fading the volume of the music file from zero to Volume. Starts also fade, if OGGStream is alread playing.</summary>
      procedure FadeIn(FadeDuration : LongWord);
      /// <summary> Starts fading the volume of the music file from Volume to zero. If fading of the file started while the file already
      /// fadein or out, the volumelevel will jump back to volume.</summary>
      procedure FadeOut(FadeDuration : LongWord);
      /// <summary> Free Stream, buffers and allocated data </summary>
      destructor Destroy; override;
  end;

  /// <summary> A channel is one output channel that can filled with streaming data that will queued played without any
  /// interruptions.</summary>
  TOggStreamingChannel = class(TInterfacedObject, ISoundStreamingChannel)
    private
      const
      BUFFER_COUNT = 4;
    private
      FSource : TALUInt;
      FBuffers : array [0 .. BUFFER_COUNT - 1] of TALUInt;
      FPlayList : TList<TOggStream>;
      FPlayListLock : TMultiReadExclusiveWriteSynchronizer;
      procedure UpdateVolumeLevel;
      procedure LoadDataIntoSource;
      function GetSource : TALUInt;
    public
      property Source : TALUInt read GetSource;
      /// <summary> Return true if channel is out of data.</summary>
      function IsEmpty : boolean;
      procedure AddStream(const OggStream : TOggStream);
      procedure Play;
      procedure Stop;
      constructor Create();
      destructor Destroy; override;
  end;

  TOggStreamingThread = class(TThread)
    strict private
      FWaitForPlayback : TThreadSafeObjectData<TList<ISoundStreamingChannel>>;
      FCurrentPlayback : TThreadSafeObjectData<TList<ISoundStreamingChannel>>;
    protected
      procedure Execute; override;
    public
      constructor Create;
      /// <summary> Starts playing the streams synced.</summary>
      procedure PlayChannelsSynced(Channels : array of ISoundStreamingChannel);
      procedure PlayChannel(const Channel : ISoundStreamingChannel);
      destructor Destroy; override;
  end;

var
  OggStreamingThread : TOggStreamingThread;

implementation


procedure ALCheck;
var
  Error : Integer;
begin
  Error := alGetError;
  case Error of
    AL_NO_ERROR :;
    AL_INVALID_NAME : HLog.Log('AL_INVALID_NAME: a bad name (ID) was passed to an OpenAL function');
    AL_INVALID_ENUM : HLog.Log('AL_INVALID_ENUM:  an invalid enum value was passed to an OpenAL function');
    AL_INVALID_VALUE : HLog.Log('AL_INVALID_VALUE: an invalid value was passed to an OpenAL function');
    AL_INVALID_OPERATION : HLog.Log('AL_INVALID_OPERATION: the requested operation is not valid ');
    AL_OUT_OF_MEMORY : HLog.Log('AL_OUT_OF_MEMORY: the requested operation resulted in OpenAL running out of memory');
  end;
end;

function ALErrorString(Code : Integer) : string;
begin
  case Code of
    OV_EREAD : Result := 'Read from Media.';
    OV_ENOTVORBIS : Result := 'Not Vorbis data.';
    OV_EVERSION : Result := 'Vorbis version mismatch.';
    OV_EBADHEADER : Result := 'Invalid Vorbis header.';
    OV_EFAULT : Result := 'nternal logic fault (bug or heap/stack corruption.';
  else
    Result := 'Unknown Ogg error.';
  end;
end;

constructor TOggStream.Create;
begin
  FData := TThreadSafeObjectData<TOggStreamData>.Create(TOggStreamData.Create);
  FVolumeLock := TCriticalSection.Create;
  FFadingTimer := TTimer.Create;
end;

procedure TOggStream.Open(pFileName : string);
begin
  // if Assigned(OGGFile) then OGGFile.Free;
  if not FileExists(pFileName) then raise Exception.Create('TOGGStream.Open: File "' + pFileName + '" not found.');
  FData.Lock.FFilename := pFileName;
  FData.Unlock;
end;

procedure TOggStream.SetIsLooping(const Value : boolean);
begin
  FData.Lock.FLoop := Value;
  FData.Unlock;
end;

procedure TOggStream.SetStreamingChannel(const Value : ISoundStreamingChannel);
begin
  if Status = oggStopped then
  begin
    FStreamingChannel := nil;
    if Value <> nil then
    begin
      Value.AddStream(self);
      FStreamingChannel := Value;
    end;
  end
  else raise ENotFoundException.Create('TOggStream.SetStreamingChannel: Can''t change steamingchannel if playback already started.');
end;

procedure TOggStream.SetVolume(const Value : single);
begin
  FVolume := EnsureRange(Value, 0, 1);
end;

procedure TOggStream.Stop;
begin
  StreamingChannel.Stop;
end;

procedure TOggStream.UpdateLogicalVolume;
begin
  FVolumeLock.Enter;
  case FVolumeStatus of
    volFadeIn : FLogicalVolume := FVolume * FFadingTimer.ZeitDiffProzent(True);
    volFull : FLogicalVolume := FVolume;
    volFadeOut : FLogicalVolume := FVolume * (1 - FFadingTimer.ZeitDiffProzent(True));
    volZero : FLogicalVolume := 0;
  else
    FLogicalVolume := 0;
  end;
  FVolumeLock.Leave;
end;

destructor TOggStream.Destroy;
begin
  Stop;
  FFadingTimer.Free;
  FData.Free;
  FVolumeLock.Free;
  inherited;
end;

procedure TOggStream.Pause;
begin
  if Status = oggPlaying then
      alSourcePause(StreamingChannel.Source);
end;

procedure TOggStream.Play;
begin
  if Status <> oggPlaying then
  begin
    if Status = oggPause then
        alSourcePlay(StreamingChannel.Source)
    else
    begin
      StreamingChannel.Play;
      StreamingChannel.AddStream(self);
    end;
  end;
end;

procedure TOggStream.FadeIn(FadeDuration : LongWord);
begin
  FVolumeLock.Enter;
  FVolumeStatus := volFadeIn;
  FFadingTimer.Interval := FadeDuration;
  FFadingTimer.Start;
  FVolumeLock.Leave;
end;

procedure TOggStream.FadeOut(FadeDuration : LongWord);
begin
  FVolumeLock.Enter;
  FVolumeStatus := volFadeOut;
  FFadingTimer.Interval := FadeDuration;
  FFadingTimer.Start;
  FVolumeLock.Leave;
end;

function TOggStream.GetPosition : double;
begin
  FData.Lock;
  if FData.Data.IsStreamOpened then
      Result := ov_time_tell(FData.Data.FOggStreamFile)
  else
      Result := 0;
  FData.Unlock;
end;

function TOggStream.GetStreamingChannel : ISoundStreamingChannel;
begin
  // there must be always a streamingchannel
  if not assigned(FStreamingChannel) then
  begin
    FStreamingChannel := TOggStreamingChannel.Create;
    FStreamingChannel.AddStream(self);
  end;
  Result := FStreamingChannel;
end;

function TOggStream.GetFileName : string;
begin
  Result := FData.Lock.FFilename;
  FData.Unlock;
end;

function TOggStream.GetIsLooping : boolean;
begin
  Result := FData.Lock.FLoop;
  FData.Unlock;
end;

function TOggStream.GetPlayingStatus : EnumOggStatus;
var
  Status : TALint;
begin
  alGetSourcei(StreamingChannel.Source, AL_SOURCE_STATE, @Status);
  case Status of
    AL_PLAYING : Result := oggPlaying;
    AL_STOPPED : Result := oggStopped;
    AL_PAUSED : Result := oggPause;
  else Result := oggStopped;
  end;
end;

{ TOggStreamingThread }

constructor TOggStreamingThread.Create;
begin
  FWaitForPlayback := TThreadSafeObjectData < TList < ISoundStreamingChannel >>.Create(TList<ISoundStreamingChannel>.Create);
  FCurrentPlayback := TThreadSafeObjectData < TList < ISoundStreamingChannel >>.Create(TList<ISoundStreamingChannel>.Create);
  inherited Create(False);
end;

destructor TOggStreamingThread.Destroy;
begin
  inherited;
  FWaitForPlayback.Free;
  FCurrentPlayback.Free;
end;

procedure TOggStreamingThread.Execute;
var
  Channel : ISoundStreamingChannel;
  i : Integer;
  Sources : TArray<TALint>;
begin
  while not Terminated do
  begin
    // 1. Transfer all stream from incoming queue to playback list
    // this include init, load data, playback and add to list
    FWaitForPlayback.Lock;
    SetLength(Sources, FWaitForPlayback.Data.Count);
    for i := 0 to FWaitForPlayback.Data.Count - 1 do
    begin
      Channel := FWaitForPlayback.Data[i];
      Channel.LoadDataIntoSource;
      Sources[i] := Channel.Source;
    end;
    // play all streams on waitlist sync
    if FWaitForPlayback.Data.Count > 0 then
        alSourcePlayv(length(Sources), @Sources[0]);
    // finally add all stream to playbacklist and remove them from waitlist
    FCurrentPlayback.Lock;
    FCurrentPlayback.Data.AddRange(FWaitForPlayback.Data);
    FWaitForPlayback.Data.Clear;
    FWaitForPlayback.Unlock;

    // 2. Update all streams by filling empty buffers with new data
    for i := FCurrentPlayback.Data.Count - 1 downto 0 do
    begin
      FCurrentPlayback.Data[i].UpdateVolumeLevel;
      FCurrentPlayback.Data[i].LoadDataIntoSource;
      if FCurrentPlayback.Data[i].IsEmpty then
          FCurrentPlayback.Data.Delete(i);
    end;
    FCurrentPlayback.Unlock;
    sleep(10);
  end;
end;

procedure TOggStreamingThread.PlayChannel(const Channel : ISoundStreamingChannel);
begin
  PlayChannelsSynced([Channel]);
end;

procedure TOggStreamingThread.PlayChannelsSynced(Channels : array of ISoundStreamingChannel);
var
  i : Integer;
begin
  FWaitForPlayback.Lock;
  for i := 0 to length(Channels) - 1 do
    // prevent double add of a channel
    if not FWaitForPlayback.Data.Contains(Channels[i]) then
        FWaitForPlayback.Data.Add(Channels[i]);
  FWaitForPlayback.Unlock;
end;

{ TOggStreamData }

procedure TOggStreamData.CloseStream;
begin
  if IsStreamOpened then
  begin
    ov_clear(FOggStreamFile);
    FillChar(FOggStreamFile, SizeOf(TOggVorbisFile), 0);
    FillChar(FVorbisInfo, SizeOf(TVorbisInfo), 0);
    FFormat := 0;
    FOGGFile := nil;
  end;
end;

function TOggStreamData.IsStreamOpened : boolean;
begin
  Result := assigned(FOGGFile);
end;

procedure TOggStreamData.LoadDataFromStream(const Buffer : TALUInt);
var
  Data : Pointer;
  Size : Integer;
  Section : Integer;
  Res : Integer;
begin
  Size := 0;
  GetMem(Data, BUFFERSIZE + SizeOf(Size));
  // read data until buffer is full
  while (Size < BUFFERSIZE) do
  begin
    // read decoded data from ogg stream
    Res := ov_read(FOggStreamFile, PByteArray(Data)^[Size], BUFFERSIZE - Size, VORBIS_LITTLE_ENDIAN, VORBIS_16BIT_SAMPLE, VORBIS_DATA_SIGNED, @Section);
    // Res > 0 -> res bytes was read
    if Res > 0 then
        Size := Size + Res
    else
      // res < 0 -> error occur on read data
      if Res < 0 then HLog.Log('TOGGStream.Stream: ' + ALErrorString(Res))
        // res = 0, EOF (end of stream)
      else
      begin
        if FLoop then
        begin
          Res := ov_time_seek(FOggStreamFile, 0);
          if Res <> 0 then HLog.Log('TOGGStream.Stream: ' + ALErrorString(Res))
        end
        else
            break;
      end;
  end;
  if Size = 0 then
  begin
    FreeMem(Data);
  end;
  alBufferData(Buffer, FFormat, Data, Size, FVorbisInfo.Rate);
  ALCheck;
  FreeMem(Data);
  // var
  // Data : PByte;
  // ReadDataCount : Integer;
  // Section : Integer;
  // Res : Integer;
  // begin
  // ReadDataCount := 0;
  // GetMem(Data, BUFFERSIZE + 4);
  // // read data until buffer is full
  // while (ReadDataCount < BUFFERSIZE) do
  // begin
  // // read decoded data from ogg stream
  // Res := ov_read(FOggStreamFile, Data^, BUFFERSIZE - ReadDataCount, VORBIS_LITTLE_ENDIAN, VORBIS_16BIT_SAMPLE, VORBIS_DATA_SIGNED, @Section);
  // // Res > 0 -> res bytes was read
  // if Res > 0 then
  // begin
  // ReadDataCount := ReadDataCount + Res;
  // inc(Data, ReadDataCount);
  // end
  // // res < 0 -> error occur on read data
  // else if Res < 0 then HLog.Log('TOGGStream.Stream: ' + ALErrorString(Res))
  // // res = 0, EOF (end of stream)
  // else
  // begin
  // if FLoop then
  // begin
  // Res := ov_time_seek(FOggStreamFile, 0);
  // if Res <> 0 then HLog.Log('TOGGStream.Stream: ' + ALErrorString(Res))
  // end
  // else
  // break;
  // end;
  // end;
  // if ReadDataCount > 0 then
  // begin
  // alBufferData(Buffer, FFormat, Data, ReadDataCount, FVorbisInfo.Rate);
  // ALCheck;
  // FreeMem(Data, BUFFERSIZE + 4);
  // end
  // else
  // FreeMem(Data);
end;

procedure TOggStreamData.OpenStream;
var
  Res : Integer;
begin
  FillChar(FOggStreamFile, SizeOf(FOggStreamFile), 0);
  FOGGFile := TFileStream.Create(FFilename, fmOpenRead or fmShareDenyWrite);
  // we can't use ov_open in Delphi, as this function works with C-filehandles. So
  // we use ov_open_callbacks instead which uses a filestream.
  Res := ov_open_callbacks(FOGGFile, FOggStreamFile, nil, 0, ops_callbacks);
  if Res <> 0 then
      raise Exception.Create('TOGGStream.Open: Could not open Ogg stream. [' + ALErrorString(Res) + ']');
  // Get some infos out of the OGG-file
  FVorbisInfo := ov_info(FOggStreamFile, -1)^;
  if FVorbisInfo.Channels = 1 then
      FFormat := AL_FORMAT_MONO16
  else
  begin
    assert(FVorbisInfo.Channels = 2);
    FFormat := AL_FORMAT_STEREO16;
  end;
end;

function TOggStreamData.IsStreamingFinished : boolean;
begin
  Result := (FOggStreamFile.offset >= FOggStreamFile.end_v) and not FLoop;
end;

{ TOggStreamingChannel }

procedure TOggStreamingChannel.AddStream(const OggStream : TOggStream);
begin
  FPlayListLock.BeginRead;
  if not FPlayList.Contains(OggStream) then
      FPlayList.Add(OggStream);
  FPlayListLock.EndRead;
end;

constructor TOggStreamingChannel.Create;
begin
  FPlayList := TList<TOggStream>.Create;
  FPlayListLock := TMultiReadExclusiveWriteSynchronizer.Create;
  // Prepare OpenAL for OGG-Streaming (i.e. generate buffers and sources)
  ALCheck;
  alGenBuffers(BUFFER_COUNT, @FBuffers[0]);
  ALCheck;
  alGenSources(1, @FSource);
  ALCheck;
  alSource3f(FSource, AL_POSITION, 0, 0, 0);
  alSource3f(FSource, AL_VELOCITY, 0, 0, 0);
  alSource3f(FSource, AL_DIRECTION, 0, 0, 0);
  alSourcef(FSource, AL_ROLLOFF_FACTOR, 0);
  alSourcei(FSource, AL_SOURCE_RELATIVE, AL_TRUE);
  ALCheck;
end;

function TOggStreamingChannel.GetSource : TALUInt;
begin
  Result := FSource;
end;

function TOggStreamingChannel.IsEmpty : boolean;
var
  Status : TALint;
begin
  alGetSourcei(Source, AL_SOURCE_STATE, @Status);
  Result := (FPlayList.Count <= 0) and not((Status = AL_PLAYING) or (Status = AL_PAUSED));
end;

procedure TOggStreamingChannel.LoadDataIntoSource;
var
  StreamData : TOggStreamData;
  Stream : TOggStream;
  EmptyBuffers : TArray<TALUInt>;
  Status : TALint;
  Processed, FilledBufferCount : Integer;
begin
  alGetSourcei(Source, AL_SOURCE_STATE, @Status);
  ALCheck;
  // if source currently not already playing, all buffers need to filled with data
  if (Status = AL_INITIAL) or (Status = AL_STOPPED) then
      EmptyBuffers := HArray.ConvertDynamicToTArray<TALUInt>(FBuffers)
  else
  // else only fill already processed buffers
  begin
    alGetSourcei(FSource, AL_BUFFERS_PROCESSED, @Processed);
    ALCheck;
    SetLength(EmptyBuffers, Processed);
    alSourceUnqueueBuffers(FSource, Processed, @EmptyBuffers[0]);
    ALCheck;
  end;

  FPlayListLock.BeginRead;
  FilledBufferCount := 0;
  begin
    while (FPlayList.Count > 0) and (FilledBufferCount < length(EmptyBuffers)) do
    begin
      Stream := FPlayList.First;
      StreamData := FPlayList.First.FData.Lock;
      // open stream to read data if not already opened
      if not StreamData.IsStreamOpened then
          StreamData.OpenStream;
      // a buffer was filled with data
      StreamData.LoadDataFromStream(EmptyBuffers[FilledBufferCount]);
      inc(FilledBufferCount);
      // after a stream is completly streamed, remove it from channel
      if StreamData.IsStreamingFinished then
      begin
        FPlayListLock.BeginWrite;
        begin
          StreamData.CloseStream;
          FPlayList.Delete(0);
        end;
        FPlayListLock.EndWrite;
      end;
      Stream.FData.Unlock;
    end;
    alSourceQueueBuffers(FSource, FilledBufferCount, @EmptyBuffers[0]);
    ALCheck;
  end;
  FPlayListLock.EndRead;
end;

procedure TOggStreamingChannel.Play;
var
  Status : TALint;
begin
  alGetSourcei(Source, AL_SOURCE_STATE, @Status);
  ALCheck;
  if (Status = AL_INITIAL) or (Status = AL_STOPPED) then
  begin
    OggStreamingThread.PlayChannel(self);
  end;
end;

destructor TOggStreamingChannel.Destroy;
begin
  Stop;
  FPlayList.Free;

  ALCheck;
  alDeleteSources(1, @FSource);
  ALCheck;
  alDeleteBuffers(BUFFER_COUNT, @FBuffers[0]);
  ALCheck;

  FPlayListLock.Free;
  inherited;
end;

procedure TOggStreamingChannel.Stop;
var
  Stream : TOggStream;
begin
  FPlayListLock.BeginWrite;
  begin
    for Stream in FPlayList do
    begin
      Stream.FData.Lock.CloseStream;
      Stream.FData.Unlock;
    end;
    FPlayList.Clear;
    ALCheck;
    alSourceStop(FSource);
    ALCheck;
    alSourcei(FSource, AL_BUFFER, AL_NONE);
    ALCheck;
  end;
  FPlayListLock.EndWrite;
end;

procedure TOggStreamingChannel.UpdateVolumeLevel;
var
  Stream : TOggStream;
begin
  FPlayListLock.BeginRead;
  if FPlayList.Count > 0 then
  begin
    Stream := FPlayList.First;
    Stream.UpdateLogicalVolume;
    alSourcef(FSource, AL_GAIN, Stream.FLogicalVolume);
    ALCheck;
  end;
  FPlayListLock.EndRead;
end;

end.
