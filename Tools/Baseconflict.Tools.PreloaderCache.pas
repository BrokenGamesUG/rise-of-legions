unit Baseconflict.Tools.PreloaderCache;

interface

uses
  Baseconflict.Tools.Main,
  Baseconflict.Constants,
  Baseconflict.Constants.Cards,
  Baseconflict.Constants.Client,
  Baseconflict.Constants.Scenario,
  // Delphi
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Log,
  Engine.Preloader;

type
  TBuildPreloaderCacheCommand = class(TCommand)
    public
      procedure Execute; override;
      constructor Create();
  end;

implementation

{ TBuildPreloaderCacheCommand }

constructor TBuildPreloaderCacheCommand.Create;
begin
  inherited Create('Build Preloader Cache', 'buildpreloadercache', 'Builds preloader cache and save file.');
end;

procedure TBuildPreloaderCacheCommand.Execute;
const
  PRELOADASSETS : TArray<string> = [
    PATH_SCRIPT,
    PATH_GRAPHICS_EFFECTS,
    PATH_GRAPHICS_ENVIRONMENT,
    PATH_GRAPHICS_GAMEPLAY,
    PATH_PRECOMPILEDSHADERCACHE,
    PATH_HUD,
    PATH_GUI_SHARED,
    PATH_GRAPHICS_UNITS + 'Neutral\',
    PATH_GRAPHICS_UNITS + 'Shared\',
    PATH_GUI,
    PATH_MAP + '\' + MAP_SINGLE,
    PATH_MAP + '\' + MAP_DOUBLE,
    PATH_GRAPHICS_UNITS,
    PATH_GRAPHICS_UNITS + 'Colorless\',
    PATH_GRAPHICS_UNITS + 'Scenario\',
    PATH_GUI + 'Spelltarget\',
    PATH_GUI + 'MainMenu\Shared\Card\',
    PATH_GUI + PATH_GUI_RELATIVE_SHARED_CARD_ICONS_PATH
    ];
  PRELOADER_IGNORE : TArray<string> = [
    '.png',
    '.tga',
    '.jpg',
    '.dds',
    '.bmp',
    '.fbx'
    ];

var
  AssetPreloader : TAssetPreloader;
  RelativeWorkingPath, AssetPath, CardUID : string;
  CardInfo : TCardInfo;
begin
  RelativeWorkingPath := HFilepathManager.RelativeWorkingPath;
  if ParamCount >= 2 then
      HFilepathManager.RelativeWorkingPath := ParamStr(2)
  else
      HFilepathManager.RelativeWorkingPath := '\..\';
  try
    Writeln('Building preloader cache...');
    AssetPreloader := TAssetPreloader.Create(False);
    AssetPreloader.IgnoreFilePatterns.AddStrings(HArray.Create<string>(PRELOADER_IGNORE));
    for AssetPath in PRELOADASSETS do
    begin
      Writeln('Adding ', AssetPath, ' to preloader');
      AssetPreloader.AddPreloadPathOrFile(AbsolutePath(AssetPath));
    end;
    for CardUID in CardInfoManager.GetAllCardUIDs do
      if CardInfoManager.TryResolveCardUID(CardUID, MAX_LEAGUE, MAX_LEVEL, CardInfo) and not CardInfo.IsSpell then
      begin
        Writeln('Adding ', CardInfo.Name, ' to preloader');
        AssetPreloader.AddPreloadPathOrFile(AbsolutePath(PATH_GRAPHICS + CardInfo.SkinnedUnitFilename + '\'));
      end;
    Writeln('Building preloader cache...done');
    AssetPreloader.SaveCacheToFile(AbsolutePath(PRELOADER_CACHE_FILENAME));
    AssetPreloader.IgnoreFilePatterns.Clear;
    Writeln('Preloader cache saved to "', AbsolutePath(PRELOADER_CACHE_FILENAME), '"');
  finally
    HFilepathManager.RelativeWorkingPath := RelativeWorkingPath;
  end;

end;

end.
