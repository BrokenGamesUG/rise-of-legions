unit Engine.Preloader;

interface

uses
  // ----------- Delphi -------------
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Classes,
  System.SysUtils,
  System.Threading,
  Winapi.ActiveX,
  // --------- ThirdParty -----------
  // --------- Engine ------------
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Windows,
  Engine.ParticleEffects,
  Engine.Script,
  Engine.Serializer,
  Engine.Mesh,
  Engine.Math,
  Engine.Core,
  Engine.GfxApi,
  Engine.Log;

type
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  EnumAssetCategory = (acUnknown, acModel, acTexture, acXMLFile, acScriptFile, acParticleEffect, acShader);

  TAssetPreloaderBaseClass = class;

  TAssetPreloaderFileInfo = class
    strict private
      FFileName : string;
      FFileExtension : string;
      FFileSize : int64;
      FPreloader : TAssetPreloaderBaseClass;
    public
      property FileName : string read FFileName write FFileName;
      property FileSize : int64 read FFileSize write FFileSize;
      property FileExtension : string read FFileExtension write FFileExtension;
      property Preloader : TAssetPreloaderBaseClass read FPreloader write FPreloader;
      constructor Create(const FileName : string); overload;
      constructor Create; overload;
      function PreloadFile : TAssetPreloaderFileInfo;
      function Clone : TAssetPreloaderFileInfo;
  end;

  RAssetPreloaderFileRecord = packed record
    FileName : ShortString;
    FileExtension : ShortString;
    FileSize : int64;
  end;

  ARAssetPreloaderFileRecord = TArray<RAssetPreloaderFileRecord>;

  RAssetPreloaderCacheItem = record
    Path : string;
    Files : ARAssetPreloaderFileRecord;
  end;

  ARAssetPreloaderCacheItem = TArray<RAssetPreloaderCacheItem>;

  EPreloaderCacheDumpError = class(Exception);

  /// <summary> Class for saving and loading preloader chache to file using
  /// a custom binary file format.</summary>
  TPreloaderCacheDump = class
    private const
      FILE_IDENTIFIER : string[4]  = '%PRC';
      CURRENT_VERSION : string[4]  = 'V.01';
      HEADER_PROTECTOR : string[4] = AnsiChar($9A) + AnsiChar($4D) + AnsiChar($0A) + AnsiChar($4E);
      CHUNK_PROTECTOR : string[4]  = AnsiChar($4F) + AnsiChar($E0) + AnsiChar($5A) + AnsiChar($94);
    private type
      /// <summary> Preheader is read before any other data is read from file and should NEVER
      /// changed, because changes of different formats will only determined after prehader was read.</summary>
      RPreHeader = packed record
        FileIdentifier : string[4];
        /// <summary> Inspired by PNG fileformat 4 bytes for minimum file missuse safety.</summary>
        Protector : string[4];
        Version : string[4];
        HeaderLength : UInt32;
        class function Create : RPreHeader; static;
      end;

      /// <summary> Basedata for texture. Some of this data is necessary to process further data that is saved.</summary>
      RHeader = packed record
        CacheItemCount : integer;
      end;

      RCacheItemHeader = packed record
        Protector : string[4];
        Path : ShortString;
        FileCount : integer;
      end;
    private
      FData : ARAssetPreloaderCacheItem;
    public
      /// <summary> Data of preloader cachedump using simple datastructures. Transformation has to done outside.</summary>
      property Data : ARAssetPreloaderCacheItem read FData write FData;
      /// <summary> Saving data to file using custom binary file format.</summary>
      procedure SaveToFile(const FileName : string);
      /// <summary> Loading data from file using custom binary file format.</summary>
      procedure LoadFromFile(const FileName : string);
  end;

  /// <summary> Basetype for preloading an assettype, every assettype will register his own preloader class.</summary>
  TAssetPreloaderBaseClass = class
    strict private
      FSupportedFileExtensions : TList<string>;
      FSupportThreadLoading : boolean;
      FCategory : EnumAssetCategory;
    protected
      constructor InternalCreate(const SupportedExtensions : string; Category : EnumAssetCategory);
    public
      /// <summary> If True, any file preloaded by this class can be loaded by thread. If this
      /// is done also depends on other factors.</summary>
      property SupportThreadLoading : boolean read FSupportThreadLoading write FSupportThreadLoading;
      property Category : EnumAssetCategory read FCategory;
      function CanPreloadFile(FileInfo : TAssetPreloaderFileInfo) : boolean;
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); virtual; abstract;
      constructor Create; virtual; abstract;
      destructor Destroy; override;
  end;

  CAssetPreloadBaseClass = class of TAssetPreloaderBaseClass;

  TTextureAssetPreloaderClass = class(TAssetPreloaderBaseClass)
    public const
      SUPPORTED_EXTENSIONS = '.tga|.png|.jpg|.tex';
      ASSET_CATEGORY       = acTexture;
    public
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); override;
      constructor Create; override;
  end;

  TModelAssetPreloaderClass = class(TAssetPreloaderBaseClass)
    public const
      SUPPORTED_EXTENSIONS = '.fbx|.obj|.3ds|.msh';
      ASSET_CATEGORY       = acModel;
    public
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); override;
      constructor Create; override;
  end;

  TXMLFileAssetPreloaderClass = class(TAssetPreloaderBaseClass)
    public const
      SUPPORTED_EXTENSIONS = '.bcc|.bcm|.ter|.xml|.veg|.wat|.gui|.gco';
      ASSET_CATEGORY       = acXMLFile;
    public
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); override;
      constructor Create; override;
  end;

  TScriptFileAssetPreloaderClass = class(TAssetPreloaderBaseClass)
    public const
      SUPPORTED_EXTENSIONS = '.ets|.sps|.dws';
      ASSET_CATEGORY       = acScriptFile;
    public
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); override;
      constructor Create; override;
  end;

  TParticleEffectAssetPreloaderClass = class(TAssetPreloaderBaseClass)
    public const
      SUPPORTED_EXTENSIONS = '.pfx';
      ASSET_CATEGORY       = acParticleEffect;
    public
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); override;
      constructor Create; override;
  end;

  TShaderAssetPreloaderClass = class(TAssetPreloaderBaseClass)
    public const
      SUPPORTED_EXTENSIONS = '.fx';
      ASSET_CATEGORY       = acShader;
    public
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); override;
      constructor Create; override;
  end;

  TCompiledShaderAssetPreloaderClass = class(TAssetPreloaderBaseClass)
    public const
      SUPPORTED_EXTENSIONS = '.cvs|.cps';
      ASSET_CATEGORY       = acShader;
    public
      procedure Preload(FileEntry : TAssetPreloaderFileInfo); override;
      constructor Create; override;
  end;

  TPreloaderJobQueue = class
    private
      type
      EnumJobStatus = (jsWaiting{ default job status }, jsDoWork, jsSuccesful, jsException);

      TPreloaderWorkerThread = class;

      TPreloaderJob = class abstract
        protected
          FCanBeDoneInThread : boolean;
          FStatus : EnumJobStatus;
          FErrorMessage : string;
          FWorkerThread : TPreloaderWorkerThread;
          procedure DoInnerWork; virtual; abstract;
        public
          property CanBeDoneInThread : boolean read FCanBeDoneInThread;
          property Status : EnumJobStatus read FStatus;
          /// <summary> If True, job work was done within thread.</summary>
          function IsDoneByThread : boolean;
          /// <summary> Returns True if job is in any finished state.</summary>
          function IsFinished : boolean;
          /// <summary> Returns error (exception) message if status of job is jsException
          /// else will raise ENotFoundException.</summary>
          function GetErrorMessage : string;
          /// <summary> Returns FileName Or path for job. Only for debug purpose!</summary>
          function GetDebugFileName : string; virtual; abstract;
          /// <summary> </summary>
          procedure PrepareWork;
          /// <summary> Will do jobs work.</summary>
          procedure DoWork(WorkerThread : TPreloaderWorkerThread);
      end;

      /// <summary> Job for preloading an asset.</summary>
      TPreloaderLoadAssertJob = class(TPreloaderJob)
        strict private
          FFileInfo : TAssetPreloaderFileInfo;
        protected
          procedure DoInnerWork; override;
        public
          property FileInfo : TAssetPreloaderFileInfo read FFileInfo;
          constructor Create(FileInfo : TAssetPreloaderFileInfo);
          function GetDebugFileName : string; override;
          destructor Destroy; override;
      end;

      /// <summary> Job for collecting all files from filepath.</summary>
      TPreloaderCollectFilesJob = class(TPreloaderJob)
        strict private
          FCollectedFiles : TList<TAssetPreloaderFileInfo>;
          FFilePath : string;
        protected
          procedure DoInnerWork; override;
        public
          function GetCollectedFiles : TList<TAssetPreloaderFileInfo>;
          function GetDebugFileName : string; override;
          constructor Create(const FilePath : string);
          destructor Destroy; override;
      end;

      TPreloaderWorkerThread = class(TThread)
        strict private
          FPreloaderJobQueue : TPreloaderJobQueue;
          /// <summary> </summary>
          FIsAliveTimer : TTimer;
        protected
          procedure Execute; override;
        public
          constructor Create(PreloaderJobQueue : TPreloaderJobQueue);
          function IsAlive : boolean;
          procedure ResetAliveTimer;
          destructor Destroy; override;
      end;

    strict private
      FJobsToDo : TThreadList<TPreloaderJob>;
      FJobsFinished : TObjectList<TPreloaderJob>;
      FJobsToDoCount : integer;
      FAllowThreadWorker : boolean;
      FThreadsStarted : boolean;
      FWorkerThreads : TObjectList<TPreloaderWorkerThread>;
      FMainThreadHasDoneWork : boolean;
      function GetThreadCount : integer;
    protected
      property JobsToDo : TThreadList<TPreloaderJob> read FJobsToDo;
      function GetJobForThread : TPreloaderJob;
    public
      property AllowThreadWorker : boolean read FAllowThreadWorker write FAllowThreadWorker;
      property JobsFinished : TObjectList<TPreloaderJob> read FJobsFinished;
      property JobsToDoCount : integer read FJobsToDoCount;
      property ThreadCount : integer read GetThreadCount;
      procedure AddLoadAssertJob(const FileInfo : TAssetPreloaderFileInfo);
      procedure AddCollectFilesJob(const FilePath : string);
      /// <summary> Work, work. Will return True, if an job was done this call.</summary>
      procedure DoWorkMainThread;
      function IsStuck : boolean;
      constructor Create;
      destructor Destroy; override;
  end;

  ProcPreloadFileFailed = procedure(const FileName, ErrorMessage : string) of object;

  TAssetPreloader = class
    private type
      EnumCacheFileFormat = (cfXml, cfBinary);

    private const
      MAXTIMETOLOADPERFRAME = 1000 / 15; // ms
      PRELOADER_CLASSES : array [0 .. 6] of CAssetPreloadBaseClass =
        (
        TTextureAssetPreloaderClass,
        TModelAssetPreloaderClass,
        TXMLFileAssetPreloaderClass,
        TScriptFileAssetPreloaderClass,
        TParticleEffectAssetPreloaderClass,
        TShaderAssetPreloaderClass,
        TCompiledShaderAssetPreloaderClass
        );
    private
      FFileList : TObjectList<TAssetPreloaderFileInfo>;
      FPreloaderQueue : TPreloaderJobQueue;
      FAllowThreadedPreloading : boolean;
      FTotalFileSize : int64;
      FFilesDoneSize : int64;
      FJobDoneInThreads : integer;
      // FLastType : EnumAssetCategory;
      FTimeUsed : TTimer;
      /// <summary> Caches the recursive path search. If cache is enabled and a relative path is added,
      /// cache is used to determine files within path instead of query filesystem.</summary>
      FCache : TCaseInsensitiveObjectDictionary<TObjectList<TAssetPreloaderFileInfo>>;
      FCacheEnabled : boolean;
      FCacheFileFormat : EnumCacheFileFormat;
      FFirst : boolean;
      FOnPreloadFileFailed : ProcPreloadFileFailed;
      procedure AddFileInfo(FileInfo : TAssetPreloaderFileInfo);
      /// <summary> Collect all files from path saved in FPreLoadList and collect they infos.</summary>
      procedure CollectAllFileInfos(const FilePath : string);
      function GetProgress : single;
      function GetDone : boolean;
    private
      class var VPreloaderList : TObjectList<TAssetPreloaderBaseClass>;
      class var VIgnoreFilePatterns : TStrings;
      class function IsOnIgnoreList(const FileName : string) : boolean;
      class function DeterminePreloaderClass(FileInfo : TAssetPreloaderFileInfo) : TAssetPreloaderBaseClass;
      class function TryCollectFileInfo(FileName : string; out FileInfo : TAssetPreloaderFileInfo) : boolean;
    public
      /// <summary> When adding files, any filename containing pattern from these list will be ignored.</summary>
      class property IgnoreFilePatterns : TStrings read VIgnoreFilePatterns write VIgnoreFilePatterns;
    public
      property OnPreloadFileFailed : ProcPreloadFileFailed read FOnPreloadFileFailed write FOnPreloadFileFailed;
      /// <summary> If Cache enabled, add file or path will first look in cache and using data
      /// and only collect data from filesystem on cache miss.</summary>
      property CacheEnabled : boolean read FCacheEnabled write FCacheEnabled;
      /// <summary> Sets file format for loading and saving cache dump to file.</summary>
      property CacheFileFormat : EnumCacheFileFormat read FCacheFileFormat write FCacheFileFormat;
      /// <summary> If True, preloader will preload file using threads when preloader class supports it.
      /// Else, or if not supported, file will be preloaded while DoWork</summary>
      property AllowThreadedPreloading : boolean read FAllowThreadedPreloading;
      /// <summary> Size in bytes of loaded files. </summary>
      property FilesDoneSize : int64 read FFilesDoneSize;
      /// <summary> Size in bytes of all files to load. </summary>
      property TotalFileSize : int64 read FTotalFileSize;
      /// <summary> Amount of pending jobs. </summary>
      function PendingJobs : integer;
      /// <summary> Progress of PreLoading in range [0..1]</summary>
      property Progress : single read GetProgress;
      /// <summary> False while preloading is NOT finsihed, if finished done = True</summary>
      property Done : boolean read GetDone;
      /// <summary> Returns last from mainthread loaded fileinfo. Habbahabba (Kat)</summary>
      function GetLastLoaded : TAssetPreloaderFileInfo;
      function TryGetLastLoaded(out FileInfo : TAssetPreloaderFileInfo) : boolean;
      /// <summary></summary>
      constructor Create(AllowThreadedPreloading : boolean = False);
      /// <summary> Adds a file or path to be preloaded. If a path is set, all files recursive will be added to preloader
      /// as long as a preloader class for file is registered and path does not contain any IgnoreFilePattern.</summary>
      procedure AddPreloadPathOrFile(const FilePath : string); overload;
      procedure AddPreloadPathOrFile(FilePathList : array of string); overload;
      /// <summary> Creates a cachefile to filesystem saves to current build cache.</summary>
      procedure SaveCacheToFile(const FileName : string);
      /// <summary> Loads a chachfile from filsystem to load a previous build cache.</summary>
      procedure LoadCacheFromFile(const FileName : string);
      /// <summary> Preloading all files that are not preloaded using threads. Try to use max MAXTIMETOLOADPERFRAME ms
      /// to preload files. In fact it can be much longer when preloading a single file need more time.</summary>
      procedure DoWork;
      /// <summary> Return True if preloader got stuck while preloading files.
      /// Got stuck means, main thread has not done any work last DoWork call and not workerthread is alive.
      /// Worker thread is alive, when worker thread has done work in last 5 seconds.
      /// CAUTION: Will only return valid result if called after DoWork.</summary>
      function IsStuck : boolean;
      destructor Destroy; override;
      class constructor Create;
      class destructor Destroy;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  // {$DEFINE PRELOADER_DEBUG_ENABLED}

implementation

{ TAssetsPreLoaderThread }

procedure TAssetPreloader.AddFileInfo(FileInfo : TAssetPreloaderFileInfo);
begin
  assert(assigned(FileInfo));
  FTotalFileSize := FTotalFileSize + FileInfo.FileSize;
  FPreloaderQueue.AddLoadAssertJob(FileInfo);
end;

procedure TAssetPreloader.AddPreloadPathOrFile(FilePathList : array of string);
var
  FilePath : string;
begin
  for FilePath in FilePathList do
      AddPreloadPathOrFile(FilePath);
end;

procedure TAssetPreloader.AddPreloadPathOrFile(const FilePath : string);
begin
  CollectAllFileInfos(FilePath);
end;

procedure TAssetPreloader.CollectAllFileInfos(const FilePath : string);
var
  FileName : string;
  Files : TStrings;
  CachedFiles : TObjectList<TAssetPreloaderFileInfo>;
  FileInfo : TAssetPreloaderFileInfo;
begin
  if CacheEnabled and FCache.TryGetValue(FilePath, CachedFiles) then
  begin
    for FileInfo in CachedFiles do
        AddFileInfo(FileInfo.Clone);
  end
  else if AllowThreadedPreloading then
  begin
    FPreloaderQueue.AddCollectFilesJob(FilePath);
  end
  else
  begin
    Files := TStringList.Create;
    // get all files from path
    if HFileIO.IsDirectory(FilePath) then
        HFileIO.FindAllFiles(Files, FilePath)
    else
        Files.Add(FilePath);
    // add files to preloading
    for FileName in Files do
      if not IsOnIgnoreList(FileName) and TryCollectFileInfo(FileName, FileInfo) then
      begin
        AddFileInfo(FileInfo);
        // add info to cache, as they does not exists
        if CacheEnabled then
        begin
          if not FCache.TryGetValue(FilePath, CachedFiles) then
          begin
            CachedFiles := TObjectList<TAssetPreloaderFileInfo>.Create();
            FCache.Add(FilePath, CachedFiles);
          end;
          CachedFiles.Add(FileInfo.Clone);
        end;
      end;
    Files.Free;
  end;
end;

class constructor TAssetPreloader.Create;
var
  PreloadClass : CAssetPreloadBaseClass;
begin
  VPreloaderList := TObjectList<TAssetPreloaderBaseClass>.Create;
  for PreloadClass in PRELOADER_CLASSES do
      VPreloaderList.Add(PreloadClass.Create);
  VIgnoreFilePatterns := TStringList.Create;
end;

class destructor TAssetPreloader.Destroy;
begin
  VPreloaderList.Free;
  VIgnoreFilePatterns.Free;
end;

class function TAssetPreloader.TryCollectFileInfo(FileName : string; out FileInfo : TAssetPreloaderFileInfo) : boolean;
var
  Preloader : TAssetPreloaderBaseClass;
begin
  result := FileExists(FileName);
  if result then
  begin
    FileInfo := TAssetPreloaderFileInfo.Create(FileName);
    // determine preloading class
    Preloader := TAssetPreloader.DeterminePreloaderClass(FileInfo);
    // skip any files that can't be preloded
    if assigned(Preloader) then
        FileInfo.Preloader := Preloader
    else
    begin
      result := False;
      FileInfo.Free;
      FileInfo := nil;
    end;
  end
  else
      Hlog.Write(elWarning, 'TAssetPreloader.TryCollectFileInfo: "' + FileName + '" not found!')
end;

function TAssetPreloader.TryGetLastLoaded(out FileInfo : TAssetPreloaderFileInfo) : boolean;
begin
  result := FFileList.Count > 0;
  if result then
      FileInfo := FFileList.Last
end;

constructor TAssetPreloader.Create(AllowThreadedPreloading : boolean);
begin
  FCacheEnabled := True;
  FCacheFileFormat := cfBinary;
  FFirst := True;
  FFileList := TObjectList<TAssetPreloaderFileInfo>.Create(
    TComparer<TAssetPreloaderFileInfo>.Construct(
    function(const L, R : TAssetPreloaderFileInfo) : integer
    begin
      result := ord(L.Preloader.Category) - ord(R.Preloader.Category);
    end));
  FPreloaderQueue := TPreloaderJobQueue.Create;
  FPreloaderQueue.AllowThreadWorker := AllowThreadedPreloading;
  FAllowThreadedPreloading := AllowThreadedPreloading;
  FFilesDoneSize := 0;
  FTotalFileSize := 0;
  FTimeUsed := TTimer.CreateAndStart(round(MAXTIMETOLOADPERFRAME));
  FCache := TCaseInsensitiveObjectDictionary < TObjectList < TAssetPreloaderFileInfo >>.Create([doOwnsValues]);
end;

destructor TAssetPreloader.Destroy;
begin
  FPreloaderQueue.Free;
  FFileList.Free;
  FTimeUsed.Free;
  FCache.Free;
end;

class function TAssetPreloader.DeterminePreloaderClass(FileInfo : TAssetPreloaderFileInfo) : TAssetPreloaderBaseClass;
var
  Preloader : TAssetPreloaderBaseClass;
begin
  result := nil;
  for Preloader in TAssetPreloader.VPreloaderList do
  begin
    if Preloader.CanPreloadFile(FileInfo) then
    begin
      result := Preloader;
      break;
    end;
  end;
end;

procedure TAssetPreloader.DoWork;
var
  FileInfo : TAssetPreloaderFileInfo;
  JobFinished : TPreloaderJobQueue.TPreloaderJob;
begin
  // first time DoWork is executed, preloader list is sorted
  if FFirst then
  begin
    FFileList.Sort;
    FFirst := False;
  end;

  FTimeUsed.Start;
  repeat
      FPreloaderQueue.DoWorkMainThread;
  until FTimeUsed.Expired or (FPreloaderQueue.JobsToDoCount <= 0);

  for JobFinished in FPreloaderQueue.JobsFinished do
  begin
    // for debug
    if JobFinished.IsDoneByThread then
        inc(FJobDoneInThreads);
    assert(JobFinished.IsFinished);
    // handle jobs with error
    if JobFinished.Status = jsException then
    begin
      if assigned(FOnPreloadFileFailed) then
          OnPreloadFileFailed(JobFinished.GetDebugFileName, 'TContentManager.ObservationEnabled: ' + BoolToStr(ContentManager.ObservationEnabled, True) + ', ' + JobFinished.GetErrorMessage);
    end
    else
    begin
      // collect data from succesful jobs
      assert(JobFinished.Status = jsSuccesful);
      if JobFinished is TPreloaderJobQueue.TPreloaderLoadAssertJob then
      begin
        FileInfo := TPreloaderJobQueue.TPreloaderLoadAssertJob(JobFinished).FileInfo;
        FFilesDoneSize := FFilesDoneSize + FileInfo.FileSize;
      end
      else if JobFinished is TPreloaderJobQueue.TPreloaderCollectFilesJob then
      begin
        for FileInfo in TPreloaderJobQueue.TPreloaderCollectFilesJob(JobFinished).GetCollectedFiles do
            AddFileInfo(FileInfo);
      end;
    end;
  end;
  // all finished jobs proceded
  FPreloaderQueue.JobsFinished.Clear;

  {$IFDEF PRELOADER_DEBUG_ENABLED}
  if not Done then
      Hlog.Console('Preloader: Main, %d | ThreadCount, %d | State, %s/%s | ThreadWork, %d',
      [FPreloaderQueue.JobsToDoCount, FPreloaderQueue.ThreadCount, HString.IntToStrBandwidth(FFilesDoneSize),
      HString.IntToStrBandwidth(FTotalFileSize), FJobDoneInThreads]);
  {$ENDIF}
end;

function TAssetPreloader.GetDone : boolean;
begin
  result := (FFilesDoneSize >= FTotalFileSize) and (FPreloaderQueue.JobsToDoCount <= 0);
end;

function TAssetPreloader.GetProgress : single;
begin
  result := FFilesDoneSize / FTotalFileSize;
end;

class function TAssetPreloader.IsOnIgnoreList(const FileName : string) : boolean;
var
  IgnoreItem : string;
begin
  result := False;
  for IgnoreItem in IgnoreFilePatterns do
  begin
    if FileName.ToLowerInvariant.Contains(IgnoreItem.ToLowerInvariant) then
    begin
      result := True;
      Exit;
    end;
  end;
end;

function TAssetPreloader.IsStuck : boolean;
begin
  result := FPreloaderQueue.IsStuck;
end;

function TAssetPreloader.GetLastLoaded : TAssetPreloaderFileInfo;
begin
  if not TryGetLastLoaded(result) then
      result := nil;
end;

procedure TAssetPreloader.LoadCacheFromFile(const FileName : string);
var
  CacheDump : TList<RAssetPreloaderCacheItem>;
  CacheDumpBinary : TPreloaderCacheDump;
  CacheItem : RAssetPreloaderCacheItem;
  FilesData : TArray<TAssetPreloaderFileInfo>;
  Files : TObjectList<TAssetPreloaderFileInfo>;
  Item : RAssetPreloaderFileRecord;
  Info : TAssetPreloaderFileInfo;
  i : integer;
begin
  CacheDump := TList<RAssetPreloaderCacheItem>.Create;
  if CacheFileFormat = cfXml then
  begin
    HXMLSerializer.LoadObjectFromFile(CacheDump, FileName);
  end
  else if CacheFileFormat = cfBinary then
  begin
    CacheDumpBinary := TPreloaderCacheDump.Create;
    CacheDumpBinary.LoadFromFile(FileName);
    CacheDump.AddRange(CacheDumpBinary.Data);
    CacheDumpBinary.Free;
  end;
  for CacheItem in CacheDump do
  begin
    SetLength(FilesData, length(CacheItem.Files));
    for i := 0 to length(FilesData) - 1 do
    begin
      Item := CacheItem.Files[i];
      Info := TAssetPreloaderFileInfo.Create;
      Info.FileName := HFilepathManager.RelativeToAbsolute(string(Item.FileName));
      Info.FileSize := Item.FileSize;
      Info.FileExtension := string(Item.FileExtension);
      Info.Preloader := DeterminePreloaderClass(Info);
      assert(assigned(Info.Preloader));
      FilesData[i] := Info;
    end;
    Files := TObjectList<TAssetPreloaderFileInfo>.Create;
    Files.AddRange(FilesData);
    FCache.Add(HFilepathManager.RelativeToAbsolute(CacheItem.Path), Files);
  end;
  CacheDump.Free;
end;

function TAssetPreloader.PendingJobs : integer;
begin
  result := FPreloaderQueue.JobsToDoCount;
end;

procedure TAssetPreloader.SaveCacheToFile(const FileName : string);
var
  CacheDumpData : ARAssetPreloaderCacheItem;
  CacheDumpXML : TList<RAssetPreloaderCacheItem>;
  CacheDumpBinary : TPreloaderCacheDump;
begin
  CacheDumpData := HArray.Map<TPair<string, TObjectList<TAssetPreloaderFileInfo>>, RAssetPreloaderCacheItem>(FCache.ToArray,
    function(const Item : TPair < string, TObjectList < TAssetPreloaderFileInfo >> ) : RAssetPreloaderCacheItem
    begin
      result.Path := HFilepathManager.AbsoluteToRelative(Item.Key);
      result.Files := HArray.Map<TAssetPreloaderFileInfo, RAssetPreloaderFileRecord>(Item.Value.ToArray,
        function(const Item : TAssetPreloaderFileInfo) : RAssetPreloaderFileRecord
        begin
          result.FileName := ShortString(HFilepathManager.AbsoluteToRelative(Item.FileName));
          result.FileExtension := ShortString(Item.FileExtension);
          result.FileSize := Item.FileSize;
        end);
    end);
  if CacheFileFormat = cfXml then
  begin
    CacheDumpXML := TList<RAssetPreloaderCacheItem>.Create;
    CacheDumpXML.AddRange(CacheDumpData);
    HXMLSerializer.SaveObjectToFile(CacheDumpXML, FileName);
    CacheDumpXML.Free;
  end
  else if CacheFileFormat = cfBinary then
  begin
    CacheDumpBinary := TPreloaderCacheDump.Create();
    CacheDumpBinary.Data := CacheDumpData;
    CacheDumpBinary.SaveToFile(FileName);
    CacheDumpBinary.Free;
  end;
end;

{ TModelAssetPreloaderClass }

constructor TModelAssetPreloaderClass.Create;
begin
  inherited InternalCreate(SUPPORTED_EXTENSIONS, ASSET_CATEGORY);
end;

procedure TModelAssetPreloaderClass.Preload(FileEntry : TAssetPreloaderFileInfo);
var
  PreloadedObject : TObject;
begin
  PreloadedObject := TMeshAnimatedGeometry.CreateFromFile(FileEntry.FileName, GFXD);
  PreloadedObject.Free;
end;

{ TAssetPreloaderBaseClass }

function TAssetPreloaderBaseClass.CanPreloadFile(FileInfo : TAssetPreloaderFileInfo) : boolean;
begin
  result := FSupportedFileExtensions.Contains(FileInfo.FileExtension);
end;

destructor TAssetPreloaderBaseClass.Destroy;
begin
  FSupportedFileExtensions.Free;
  inherited;
end;

constructor TAssetPreloaderBaseClass.InternalCreate(const SupportedExtensions : string; Category : EnumAssetCategory);
var
  SupportedExtensionsList : TArray<string>;
  i : integer;
begin
  FSupportedFileExtensions := TList<string>.Create;
  FCategory := Category;
  SupportedExtensionsList := SupportedExtensions.Split(['|']);
  for i := 0 to length(SupportedExtensionsList) - 1 do
      SupportedExtensionsList[i] := SupportedExtensionsList[i].ToLowerInvariant;
  FSupportedFileExtensions.AddRange(SupportedExtensionsList);
end;

{ TAssetPreloaderFileEntry }

constructor TAssetPreloaderFileInfo.Create(const FileName : string);
begin
  FFileName := FileName;
  FFileSize := HFileIO.GetFileSize(FileName);
  FFileExtension := ExtractFileExt(FileName).ToLowerInvariant;
end;

function TAssetPreloaderFileInfo.Clone : TAssetPreloaderFileInfo;
begin
  result := TAssetPreloaderFileInfo.Create();
  result.FFileName := FileName;
  result.FFileSize := FileSize;
  result.FFileExtension := FileExtension;
  result.FPreloader := Preloader;
end;

constructor TAssetPreloaderFileInfo.Create;
begin
end;

function TAssetPreloaderFileInfo.PreloadFile : TAssetPreloaderFileInfo;
begin
  if assigned(Preloader) then
      Preloader.Preload(self);
  result := self;
end;

{ TTextureAssetPreloaderClass }

constructor TTextureAssetPreloaderClass.Create;
begin
  inherited InternalCreate(SUPPORTED_EXTENSIONS, ASSET_CATEGORY);
  SupportThreadLoading := False;
end;

procedure TTextureAssetPreloaderClass.Preload(FileEntry : TAssetPreloaderFileInfo);
var
  PreloadedObject : TObject;
begin
  if FileEntry.FileName.Contains('GUI') then
  begin
    if FileEntry.FileName.Contains('Shared\CardIcons\') then
        PreloadedObject := TTexture.CreateTextureFromFile(FileEntry.FileName, GFXD.Device3D, mhLoad, False, True)
    else
        PreloadedObject := TTexture.CreateTextureFromFile(FileEntry.FileName, GFXD.Device3D, mhGenerate, False, True);
  end
  else
      PreloadedObject := TTexture.CreateTextureFromFile(FileEntry.FileName, GFXD.Device3D, mhGenerate, True, True);
  PreloadedObject.Free;
end;

{ TXMLFileAssetPreloaderClass }

constructor TXMLFileAssetPreloaderClass.Create;
begin
  inherited InternalCreate(SUPPORTED_EXTENSIONS, ASSET_CATEGORY);
end;

procedure TXMLFileAssetPreloaderClass.Preload(FileEntry : TAssetPreloaderFileInfo);
begin
  CoInitialize(nil);
  TXMLSerializer.PreLoadXMLFile(FileEntry.FileName);
end;

{ TScriptFileAssetPreloaderClass }

constructor TScriptFileAssetPreloaderClass.Create;
begin
  inherited InternalCreate(SUPPORTED_EXTENSIONS, ASSET_CATEGORY);
  SupportThreadLoading := True;
end;

procedure TScriptFileAssetPreloaderClass.Preload(FileEntry : TAssetPreloaderFileInfo);
var
  PreloadedObject : TObject;
begin
  PreloadedObject := ScriptManager.CompileScriptFromFile(FileEntry.FileName);
  PreloadedObject.Free;
end;

{ TParticleEffectAssetPreloaderClass }

constructor TParticleEffectAssetPreloaderClass.Create;
begin
  inherited InternalCreate(SUPPORTED_EXTENSIONS, ASSET_CATEGORY);
end;

procedure TParticleEffectAssetPreloaderClass.Preload(FileEntry : TAssetPreloaderFileInfo);
var
  PreloadedObject : TObject;
begin
  PreloadedObject := ParticleEffectEngine.CreateParticleEffectFromFile(FileEntry.FileName);
  PreloadedObject.Free;
end;

{ TShaderAssetPreloaderClass }

constructor TShaderAssetPreloaderClass.Create;
begin
  inherited InternalCreate(SUPPORTED_EXTENSIONS, ASSET_CATEGORY);
  SupportThreadLoading := True;
end;

procedure TShaderAssetPreloaderClass.Preload(FileEntry : TAssetPreloaderFileInfo);
begin
  ContentManager.PreloadFileIntoText(FileEntry.FileName)
end;

{ TCompiledShaderAssetPreloaderClass }

constructor TCompiledShaderAssetPreloaderClass.Create;
begin
  inherited InternalCreate(SUPPORTED_EXTENSIONS, ASSET_CATEGORY);
  SupportThreadLoading := True;
end;

procedure TCompiledShaderAssetPreloaderClass.Preload(FileEntry : TAssetPreloaderFileInfo);
begin
  ContentManager.PreloadFileIntoMemory(FileEntry.FileName);
end;

{ TPreloaderCacheDump }

procedure TPreloaderCacheDump.LoadFromFile(const FileName : string);
var
  FileStream : TFileStream;
  i, i2 : integer;
  PreHeader : RPreHeader;
  Header : RHeader;
  CacheItemHeader : RCacheItemHeader;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    FileStream.Read(PreHeader, SizeOf(RPreHeader));
    if not((PreHeader.Protector = HEADER_PROTECTOR) and (PreHeader.FileIdentifier = FILE_IDENTIFIER) and (PreHeader.Version = CURRENT_VERSION)) then
        raise EPreloaderCacheDumpError.CreateFmt('TPreloaderCacheDump.LoadCacheFromFile: Invalid fileformat. StreamSize: %d, StreamPosition: %d', [FileStream.Size, FileStream.Position]);
    FileStream.Read(Header, SizeOf(RHeader));
    SetLength(FData, Header.CacheItemCount);
    for i := 0 to Header.CacheItemCount - 1 do
    begin
      FileStream.Read(CacheItemHeader, SizeOf(RCacheItemHeader));
      if CacheItemHeader.Protector <> CHUNK_PROTECTOR then
          raise EPreloaderCacheDumpError.Create('TPreloaderCacheDump.LoadCacheFromFile: Invalid chunk protector.');
      FData[i].Path := string(CacheItemHeader.Path);
      SetLength(FData[i].Files, CacheItemHeader.FileCount);
      for i2 := 0 to CacheItemHeader.FileCount - 1 do
          FileStream.Read(FData[i].Files[i2], SizeOf(RAssetPreloaderFileRecord));
    end;
  finally
    FileStream.Free;
  end;
end;

procedure TPreloaderCacheDump.SaveToFile(const FileName : string);
var
  FileStream : TFileStream;
  i, i2 : integer;
  PreHeader : RPreHeader;
  Header : RHeader;
  CacheItemHeader : RCacheItemHeader;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    PreHeader := RPreHeader.Create;
    FileStream.Write(PreHeader, SizeOf(RPreHeader));
    Header.CacheItemCount := length(FData);
    FileStream.Write(Header, SizeOf(RHeader));
    for i := 0 to length(FData) - 1 do
    begin
      assert(length(FData[i].Path) <= 255);
      CacheItemHeader.Protector := TPreloaderCacheDump.CHUNK_PROTECTOR;
      CacheItemHeader.Path := ShortString(FData[i].Path);
      CacheItemHeader.FileCount := length(FData[i].Files);
      FileStream.Write(CacheItemHeader, SizeOf(RCacheItemHeader));
      for i2 := 0 to length(FData[i].Files) - 1 do
          FileStream.Write(FData[i].Files[i2], SizeOf(RAssetPreloaderFileRecord));
    end;
  finally
    FileStream.Free;
  end;
end;

{ TPreloaderCacheDump.RPreHeader }

class function TPreloaderCacheDump.RPreHeader.Create : RPreHeader;
begin
  result.FileIdentifier := TPreloaderCacheDump.FILE_IDENTIFIER;
  result.Protector := TPreloaderCacheDump.HEADER_PROTECTOR;
  result.Version := TPreloaderCacheDump.CURRENT_VERSION;
  result.HeaderLength := SizeOf(TPreloaderCacheDump.RHeader);
end;

{ TPreloaderJobQueue.TPreloaderLoadAssertJob }

constructor TPreloaderJobQueue.TPreloaderLoadAssertJob.Create(FileInfo : TAssetPreloaderFileInfo);
begin
  FStatus := jsWaiting;
  FCanBeDoneInThread := FileInfo.Preloader.SupportThreadLoading;
  FFileInfo := FileInfo;
end;

destructor TPreloaderJobQueue.TPreloaderLoadAssertJob.Destroy;
begin
  FFileInfo.Free;
  inherited;
end;

procedure TPreloaderJobQueue.TPreloaderLoadAssertJob.DoInnerWork;
begin
  FFileInfo.PreloadFile();
end;

function TPreloaderJobQueue.TPreloaderLoadAssertJob.GetDebugFileName : string;
begin
  result := FFileInfo.FileName;
end;

{ TPreloaderJobQueue.TPreloaderCollectFilesJob }

constructor TPreloaderJobQueue.TPreloaderCollectFilesJob.Create(const FilePath : string);
begin
  FStatus := jsWaiting;
  FCollectedFiles := TList<TAssetPreloaderFileInfo>.Create;
  FFilePath := FilePath;
  FCanBeDoneInThread := True;
end;

destructor TPreloaderJobQueue.TPreloaderCollectFilesJob.Destroy;
begin
  FCollectedFiles.Free;
  inherited;
end;

procedure TPreloaderJobQueue.TPreloaderCollectFilesJob.DoInnerWork;
var
  FileName : string;
  Files : TStrings;
  FileInfo : TAssetPreloaderFileInfo;
begin
  Files := TStringList.Create;
  try
    // get all files from path
    if HFileIO.IsDirectory(FFilePath) then
        HFileIO.FindAllFiles(Files, FFilePath, '*.*', True,
        procedure(const LastItemFound : string; CurrentFileCount : integer; var Cancel : boolean)
        begin
          if assigned(FWorkerThread) then
              FWorkerThread.ResetAliveTimer;
        end)
    else
        Files.Add(FFilePath);
    // add files to preloading
    for FileName in Files do
    begin
      if assigned(FWorkerThread) then
          FWorkerThread.ResetAliveTimer;
      if not TAssetPreloader.IsOnIgnoreList(FileName) and TAssetPreloader.TryCollectFileInfo(FileName, FileInfo) then
          FCollectedFiles.Add(FileInfo);
    end;
  finally
    Files.Free;
  end;
end;

function TPreloaderJobQueue.TPreloaderCollectFilesJob.GetCollectedFiles : TList<TAssetPreloaderFileInfo>;
begin
  if Status = jsSuccesful then
      result := FCollectedFiles
  else
      raise ENotSupportedException.Create('TPreloaderJobQueue.TPreloaderCollectFilesJob.GetCollectedFiles: Job is not finished succesul.');
end;

function TPreloaderJobQueue.TPreloaderCollectFilesJob.GetDebugFileName : string;
begin
  result := FFilePath;
end;

{ TPreloaderJobQueue.TPreloaderJob }

procedure TPreloaderJobQueue.TPreloaderJob.DoWork(WorkerThread : TPreloaderWorkerThread);
begin
  FWorkerThread := WorkerThread;
  try
    DoInnerWork;
    FStatus := jsSuccesful;
  except
    on e : Exception do
    begin
      FStatus := jsException;
      FErrorMessage := e.ClassName + ': ' + e.ToString;
    end;
  end;
end;

function TPreloaderJobQueue.TPreloaderJob.GetErrorMessage : string;
begin
  result := '';
  if Status = jsException then
      result := FErrorMessage
  else
      raise ENotFoundException.Create('TPreloaderJobQueue.TPreloaderJob.GetErrorMessage: Job has NOT status jsException.');
end;

function TPreloaderJobQueue.TPreloaderJob.IsDoneByThread : boolean;
begin
  result := assigned(FWorkerThread);
end;

function TPreloaderJobQueue.TPreloaderJob.IsFinished : boolean;
begin
  result := Status in [jsSuccesful, jsException];
end;

procedure TPreloaderJobQueue.TPreloaderJob.PrepareWork;
begin
  FStatus := jsDoWork;
end;

{ TPreloaderJobQueue }

procedure TPreloaderJobQueue.AddCollectFilesJob(const FilePath : string);
var
  List : TList<TPreloaderJob>;
begin
  List := FJobsToDo.LockList;
  try
    List.Insert(0, TPreloaderCollectFilesJob.Create(FilePath));
  finally
    FJobsToDo.UnlockList;
  end;
end;

procedure TPreloaderJobQueue.AddLoadAssertJob(const FileInfo : TAssetPreloaderFileInfo);
begin
  FJobsToDo.Add(TPreloaderLoadAssertJob.Create(FileInfo));
end;

constructor TPreloaderJobQueue.Create;
begin
  FJobsToDo := TThreadList<TPreloaderJob>.Create;
  FJobsFinished := TObjectList<TPreloaderJob>.Create;
  FWorkerThreads := TObjectList<TPreloaderWorkerThread>.Create;
  FWorkerThreads.OwnsObjects := False;
end;

destructor TPreloaderJobQueue.Destroy;
var
  WorkerThread : TPreloaderWorkerThread;
begin
  // abandon threads to own, to dodge synchronize on stucked thread while loading
  for WorkerThread in FWorkerThreads do
  begin
    WorkerThread.FreeOnTerminate := True;
    WorkerThread.Terminate;
  end;
  FWorkerThreads.Free;
  FJobsToDo.Free;
  FJobsFinished.Free;
  inherited;
end;

procedure TPreloaderJobQueue.DoWorkMainThread;
var
  i : integer;
  Job : TPreloaderJob;
  Jobs : TList<TPreloaderJob>;
begin
  FMainThreadHasDoneWork := False;
  if not FThreadsStarted and AllowThreadWorker then
  begin
    FThreadsStarted := True;
    // reserve one thread for mainthread
    for i := 1 to (TThread.ProcessorCount * 4) do
    begin
      FWorkerThreads.Add(TPreloaderWorkerThread.Create(self));
    end;
  end;
  Job := nil;
  Jobs := JobsToDo.LockList;
  try
    // try get any waiting not thread supporting job
    for i := 0 to Jobs.Count - 1 do
    begin
      if (Jobs[i].Status = jsWaiting) and not Jobs[i].CanBeDoneInThread then
      begin
        Job := Jobs[i];
        // job found
        break;
      end;
    end;
    // no not thread supporting job, get any waiting job
    if not assigned(Job) then
      for i := 0 to Jobs.Count - 1 do
      begin
        if (Jobs[i].Status = jsWaiting) then
        begin
          Job := Jobs[i];
          // job found
          break;
        end;
      end;

    // any job found
    if assigned(Job) then
        Job.PrepareWork;
  finally
    JobsToDo.UnlockList;
  end;

  // do job work
  if assigned(Job) then
  begin
    Job.DoWork(nil);
    assert(Job.IsFinished);
    FMainThreadHasDoneWork := True;
  end;

  // and finally move finished jobs to another list
  Jobs := JobsToDo.LockList;
  try
    for i := Jobs.Count - 1 downto 0 do
    begin
      Job := Jobs[i];
      if Job.IsFinished then
      begin
        JobsFinished.Add(Job);
        Jobs.Delete(i);
      end;
    end;
    FJobsToDoCount := Jobs.Count;
  finally
    JobsToDo.UnlockList;
  end;

end;

function TPreloaderJobQueue.GetJobForThread : TPreloaderJob;
var
  i : integer;
  Jobs : TList<TPreloaderJob>;
begin
  result := nil;
  Jobs := JobsToDo.LockList;
  try
    // try get any waiting not thread supporting job
    for i := 0 to Jobs.Count - 1 do
    begin
      if (Jobs[i].Status = jsWaiting) and Jobs[i].CanBeDoneInThread then
      begin
        result := Jobs[i];
        // job found
        break;
      end;
    end;
    // any job found
    if assigned(result) then
        result.PrepareWork;
  finally
    JobsToDo.UnlockList;
  end;

end;

function TPreloaderJobQueue.GetThreadCount : integer;
begin
  result := FWorkerThreads.Count;
end;

function TPreloaderJobQueue.IsStuck : boolean;
var
  WorkerThread : TPreloaderWorkerThread;
  IsAlive : boolean;
begin
  IsAlive := FMainThreadHasDoneWork;
  if not IsAlive then
    for WorkerThread in FWorkerThreads do
    begin
      IsAlive := WorkerThread.IsAlive;
      if IsAlive then
          break;
    end;
  result := not IsAlive;
end;

{ TPreloaderJobQueue.TPreloaderWorkerThread }

constructor TPreloaderJobQueue.TPreloaderWorkerThread.Create(PreloaderJobQueue : TPreloaderJobQueue);
begin
  FPreloaderJobQueue := PreloaderJobQueue;
  FIsAliveTimer := TTimer.Create(5000);
  inherited Create(False);
end;

destructor TPreloaderJobQueue.TPreloaderWorkerThread.Destroy;
begin
  inherited;
  FIsAliveTimer.Free;
end;

procedure TPreloaderJobQueue.TPreloaderWorkerThread.Execute;
var
  Job : TPreloaderJob;
begin
  while not Terminated do
  begin
    Job := FPreloaderJobQueue.GetJobForThread;
    if assigned(Job) then
    begin
      Job.DoWork(self);
      ResetAliveTimer;
    end
    else
        sleep(10);
  end;
end;

function TPreloaderJobQueue.TPreloaderWorkerThread.IsAlive : boolean;
begin
  result := not FIsAliveTimer.Expired;
end;

procedure TPreloaderJobQueue.TPreloaderWorkerThread.ResetAliveTimer;
begin
  FIsAliveTimer.Start;
end;

end.
