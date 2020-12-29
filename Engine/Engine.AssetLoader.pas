unit Engine.AssetLoader;

interface

uses
  Generics.Collections,
  System.SysUtils,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.AssetLoader.MeshAsset;

type
  EnumAssetType = (atUnknown, atMesh, atTexture, atSound, atMusic);
  EUnsupportedFormat = class(Exception);

  /// <summary> Prototype version of a Assetloader. Inherite them to implement an
  /// concret loader for a fileformat.</summary>
  TAssetLoader = class abstract
    private
    public
      /// <summary> Loads an asset with registered extension and given filename.
      /// <param name="paramname">FileName of to be loading asset.</param></summary>
      function LoadAsset(FileName : string) : TObject; virtual; abstract;
  end;

  /// <summary> Loads assets (e.g. mesh, texture, sound) from varius of formats into a specfifc
  /// engine own format (class structure).</summary>
  TAssetManager = class
    private
      // map a fileextension to loader
      class var FLoader : TObjectDictionary<string, TAssetLoader>;
      class function GetLoader(FileExtension : string) : TAssetLoader;
      class function ClearExtension(FileExtension : string) : string;
    public
      /// <summary> Register a new loader for any number of formats. Fileformats are determined by
      /// extensions. So the loader must can read any fileformat for which he has registered.
      /// <param name="Loader"> Target instance of a loader.</param>
      /// <param name="FileExtensions"> An array of fileextensions that are supported to load by the loader.
      /// Supported extensions formattings: ".ext", "ext" and "*.ext"</param></summary>
      class procedure RegisterLoader(Loader : TAssetLoader; FileExtensions : array of string);
      /// <summary> Loads a meshasst with given filename.</summary>
      class function LoadMesh(FileName : string) : TMeshAsset;
      /// <summary> Init class.</summary>
      class constructor Create();
      /// <summary> Free allcated ressources.</summary>
      class destructor Destroy;
  end;

implementation

{ TAssetManager }

class function TAssetManager.ClearExtension(FileExtension : string) : string;
begin
  result := TrimLeft(FileExtension, ['*', '.']).ToLowerInvariant;
end;

class constructor TAssetManager.Create;
begin
  // do not own value, because if loader is registered to multiple fileformats, free dict would
  // try to multiple free single loaderinstance
  FLoader := TObjectDictionary<string, TAssetLoader>.Create([]);
end;

class destructor TAssetManager.Destroy;
begin
  inherited;
  Harray.FreeAllObjects<TAssetLoader>(HArray.RemoveDuplicates<TAssetLoader>(FLoader.Values.ToArray));
  FLoader.Free;
end;

class function TAssetManager.GetLoader(FileExtension : string) : TAssetLoader;
begin
  if not FLoader.TryGetValue(ClearExtension(FileExtension), result) then
    raise EUnsupportedFormat.CreateFmt('AssetManager: No loader for format "%s" registered!', [FileExtension]);
end;

class function TAssetManager.LoadMesh(FileName : string) : TMeshAsset;
begin
  result := TMeshAsset(GetLoader(ExtractFileExt(FileName)).LoadAsset(FileName));
end;

class procedure TAssetManager.RegisterLoader(Loader : TAssetLoader; FileExtensions : array of string);
var
  FileExtension : string;
begin
  assert(assigned(Loader));
  for FileExtension in FileExtensions do
  begin
    FLoader.Add(ClearExtension(FileExtension), Loader);
  end;
end;

end.
