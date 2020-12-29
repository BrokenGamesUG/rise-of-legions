(*
  This file is a part of New Audio Components package 2.4
  Copyright (c) 2002-2008, Andrei Borovsky. All rights reserved.
  See the LICENSE file for more details.
  You can contact me at anb@symmetrica.net
*)

(* This unit is written by Sergei Borisov, <jr_ross@mail.ru>
   with some extensions by  A. Borovsky. *)

(* $Id: ACS_Tags.pas 1117 2010-01-22 09:28:59Z andrei.borovsky $ *)

unit ACS_Tags;

(* Title: ACS_Tags
    This unit contains classes for audio files tags handling. *)

interface

uses
  Windows, Classes, ACS_Types;

type

  TTagValueInfo = record
    Value: Variant;
  end;
  PTagValueInfo = ^TTagValueInfo;

  (* Ñlass: TAuTags
     The base class for all the tag classes. *)

  TAuTags = class(TPersistent)
  private
    FValues: TStrings;
    FEmpty: Boolean;
    FChanged: Boolean;

    function GetIdCount: Integer;
    function GetId(Index: Integer): AnsiString;
    function GetValue(const Id: AnsiString): Variant;
    procedure SetValue(const Id: AnsiString; const Value: Variant);
    function GetAsInteger(const Id: AnsiString): Integer;
    function GetAsString(const Id: AnsiString): AnsiString;
    function GetAsWideString(const Id: AnsiString): WideString;
  protected
    function AddId(const Id: AnsiString; const Default: Variant): Boolean;
  public
    constructor Create; reintroduce; virtual;
    destructor Destroy; override;

    class function Presents(InFile: HFILE): Boolean; virtual;

    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;


  (* Procedure: Clear
     Clears all the tag contents.
     Always call Clear before setting new tag values or simply opening a new file for output otherwise it will bear some old tags or even some empty tags may be added.*)

    procedure Clear;

    function ReadFromFile(InFile: HFILE): Boolean; virtual;
    function WriteToFile(OutFile: HFILE; Unicode: Boolean = True): Boolean; virtual;


   (* Property: Empty
      Returns True if the  tag cass contains no data. *)
    property Empty: Boolean read FEmpty;

    property Changed: Boolean read FChanged;

  (* Property: IdCount
     Returns the number of records in a tag object.*)
    property IdCount: Integer read GetIdCount;
  (* Property: Ids[Index: Integer]
     This property returns a tag Id based on its index. The valid vaues for indeces range from 0 to <IdCount> - 1.*)
    property Ids[Index: Integer]: AnsiString read GetId;
  (* Property: Values[const Id: AnsiString]
     This property returns a tag value based on its Id. All this works very much like name/value pairs in TStringList. *)
    property Values[const Id: AnsiString]: Variant read GetValue write SetValue; default;
  (* Property: AsInteger[const Id: AnsiString]
     Returns the value of the Id as Integer. Make sure the value is of appropriate type. *)
    property AsInteger[const Id: AnsiString]: Integer read GetAsInteger;
  (* Property: AsString[const Id: AnsiString]
     Returns the value of the Id as AnsiString. *)
    property AsString[const Id: AnsiString]: AnsiString read GetAsString;
  (* Property: AsWidString[const Id: AnsiString]
     Returns the value of the Id as WidString. *)
    property AsWideString[const Id: AnsiString]: WideString read GetAsWideString;
  end;

  { class TId3v1Tags }

  TId3v1TagsGenreId = 0 .. 147;

  TId3v1TagsInfo = packed record
    ID     : packed array [1 ..  3] of AnsiChar; // must be "TAG"
    Title  : packed array [1 .. 30] of AnsiChar; // title
    Artist : packed array [1 .. 30] of AnsiChar; // artist
    Album  : packed array [1 .. 30] of AnsiChar; // album
    Year   : packed array [1 ..  4] of AnsiChar; // year
    Comment: packed array [1 .. 30] of AnsiChar; // comment
    GenreId: {TId3v1TagsGenreId}Byte;        // genre ID
  end;

const
  Id3v1TagsGenreIdDefault = 12; // 'Other'

type

  TCommonTags = class(TAuTags)
  private
    function GetArtist: WideString;
    procedure SetArtist(const Value: WideString);
    function GetAlbum: WideString;
    procedure SetAlbum(const Value: WideString);
    function GetGenre: WideString;
    procedure SetGenre(const Value: WideString);
    function GetYear: AnsiString;
    procedure SetYear(const Value: AnsiString);
    function GetTrack: AnsiString;
    procedure SetTrack(const Value: AnsiString);
    function GetTitle: WideString;
    procedure SetTitle(const Value: WideString);
  public
    constructor Create; override;
  published
    property Artist: WideString read GetArtist write SetArtist;
    property Album: WideString read GetAlbum write SetAlbum;
    property Genre: WideString read GetGenre write SetGenre;
    property Year: AnsiString read GetYear write SetYear;
    property Track: AnsiString read GetTrack write SetTrack;
    property Title: WideString read GetTitle write SetTitle;
  end;



  (* Class: TId3v1Tags
     This class is for handling Id3V1 tags.

     Descends from <TAuTags> *)

  TId3v1Tags = class(TAuTags)
  private
    class function ReadTagsInfo(InFile: HFILE; var TagsInfo: TId3v1TagsInfo): Boolean;

    function GetTitle: AnsiString;
    procedure SetTitle(const Value: AnsiString);
    function GetArtist: AnsiString;
    procedure SetArtist(const Value: AnsiString);
    function GetAlbum: AnsiString;
    procedure SetAlbum(const Value: AnsiString);
    function GetYear: Word;
    procedure SetYear(Value: Word);
    function GetComment: AnsiString;
    procedure SetComment(const Value: AnsiString);
    function GetTrack: Byte;
    procedure SetTrack(Value: Byte);
    function GetGenre: AnsiString;
    procedure SetGenre(const Value: AnsiString);
    function GetGenreId: TId3v1TagsGenreId;
    procedure SetGenreId(Value: TId3v1TagsGenreId);
  public
    constructor Create; override;

    class function Presents(InFile: HFILE): Boolean; override;

    function ReadFromFile(InFile: HFILE): Boolean; override;
    function WriteToFile(OutFile: HFILE; Unicode: Boolean = True): Boolean; override;
  published
    property Title: AnsiString read GetTitle write SetTitle;
    property Artist: AnsiString read GetArtist write SetArtist;
    property Album: AnsiString read GetAlbum write SetAlbum;
    property Year: Word read GetYear write SetYear default 0;
    property Comment: AnsiString read GetComment write SetComment;
    property Track: Byte read GetTrack write SetTrack default 0;
    property Genre: AnsiString read GetGenre write SetGenre stored False;
    property GenreId: TId3v1TagsGenreId read GetGenreId write SetGenreId
      default Id3v1TagsGenreIdDefault;
  end;

  { class TId3v2Tags }

  TId3v2TagsInfo = packed record
    ID: packed array [1 .. 3] of AnsiChar;   // must be "ID3"
    Version: Byte;                       // version: 2 - 2.2.x, 3 - 2.3.x, 4 - 2.4.x
    Revision: Byte;                      // revision
    Flags: Byte;                         // flags
    Size: packed array [0 .. 3] of Byte; // tags info size excluding size of TId3v2TagsInfo structure
  end;

  (* Class: TId3v2Tags
     This class is for handling Id3v2 tags.

     Descends from <TAuTags> *)

  TId3v2Tags = class(TAuTags)
  private
    FNew: Boolean;

    class function ReadTagsInfo(InFile: HFILE; var TagsInfo: TId3v2TagsInfo): Boolean;

    function GetArtist: WideString;
    procedure SetArtist(const Value: WideString);
    function GetAlbum: WideString;
    procedure SetAlbum(const Value: WideString);
    function GetGenre: WideString;
    procedure SetGenre(const Value: WideString);
    function GetYear: AnsiString;
    procedure SetYear(const Value: AnsiString);
    function GetTrack: AnsiString;
    procedure SetTrack(const Value: AnsiString);
    function GetTitle: WideString;
    procedure SetTitle(const Value: WideString);
    function GetComment: WideString;
    procedure SetComment(const Value: WideString);
    function GetComposer: WideString;
    procedure SetComposer(const Value: WideString);
    function GetEncoder: WideString;
    procedure SetEncoder(const Value: WideString);
    function GetCopyright: WideString;
    procedure SetCopyright(const Value: WideString);
    function GetLanguage: WideString;
    procedure SetLanguage(const Value: WideString);
    function GetLink: WideString;
    procedure SetLink(const Value: WideString);
  public
    constructor Create; override;

    class function Presents(InFile: HFILE): Boolean; override;

    function ReadFromFile(InFile: HFILE): Boolean; override;
    function WriteToFile(OutFile: HFILE; Unicode: Boolean = True): Boolean; override;
  published
    property Artist: WideString read GetArtist write SetArtist;
    property Album: WideString read GetAlbum write SetAlbum;
    property Genre: WideString read GetGenre write SetGenre;
    property Year: AnsiString read GetYear write SetYear;
    property Track: AnsiString read GetTrack write SetTrack;
    property Title: WideString read GetTitle write SetTitle;
    property Comment: WideString read GetComment write SetComment;
    property Composer: WideString read GetComposer write SetComposer;
    property Encoder: WideString read GetEncoder write SetEncoder;
    property Copyright: WideString read GetCopyright write SetCopyright;
    property Language: WideString read GetLanguage write SetLanguage;
    property Link: WideString read GetLink write SetLink;
  end;

  { class TAPEv2Tags }

  TAPEv2Tags = class(TAuTags)
  private
    function GetArtist: WideString;
    procedure SetArtist(const Value: WideString);
    function GetComposer: WideString;
    procedure SetComposer(const Value: WideString);
    function GetAlbum: WideString;
    procedure SetAlbum(const Value: WideString);
    function GetDebutAlbum: WideString;
    procedure SetDebutAlbum(const Value: WideString);
    function GetPublisher: WideString;
    procedure SetPublisher(const Value: WideString);
    function GetConductor: WideString;
    procedure SetConductor(const Value: WideString);
    function GetCopyright: WideString;
    procedure SetCopyright(const Value: WideString);
    function GetISBN: AnsiString;
    procedure SetISBN(const Value: AnsiString);
    function GetISRC: AnsiString;
    procedure SetISRC(const Value: AnsiString);
    function GetBarCode: AnsiString;
    procedure SetBarCode(const Value: AnsiString);
    function GetLabelCode: AnsiString;
    procedure SetLabelCode(const Value: AnsiString);
    function GetCatalog: AnsiString;
    procedure SetCatalog(const Value: AnsiString);
    function GetLanguage: WideString;
    procedure SetLanguage(const Value: WideString);
    function GetGenre: WideString;
    procedure SetGenre(const Value: WideString);
    function GetYear: AnsiString;
    procedure SetYear(const Value: AnsiString);
    function GetRecordDate: AnsiString;
    procedure SetRecordDate(const Value: AnsiString);
    function GetRecordLocation: WideString;
    procedure SetRecordLocation(const Value: WideString);
    function GetFile: WideString;
    procedure SetFile(const Value: WideString);
    function GetRelated: WideString;
    procedure SetRelated(const Value: WideString);
    function GetAbstract: WideString;
    procedure SetAbstract(const Value: WideString);
    function GetBibliography: WideString;
    procedure SetBibliography(const Value: WideString);
    function GetTrack: AnsiString;
    procedure SetTrack(const Value: AnsiString);
    function GetTitle: WideString;
    procedure SetTitle(const Value: WideString);
    function GetSubTitle: WideString;
    procedure SetSubTitle(const Value: WideString);
    function GetComment: WideString;
    procedure SetComment(const Value: WideString);
  public
    constructor Create; override;
  published
    property Artist: WideString read GetArtist write SetArtist;
    property Composer: WideString read GetComposer write SetComposer;
    property Album: WideString read GetAlbum write SetAlbum;
    property DebutAlbum: WideString read GetDebutAlbum write SetDebutAlbum;
    property Publisher: WideString read GetPublisher write SetPublisher;
    property Conductor: WideString read GetConductor write SetConductor;
    property Copyright: WideString read GetCopyright write SetCopyright;
    property ISBN: AnsiString read GetISBN write SetISBN;
    property ISRC: AnsiString read GetISRC write SetISRC;
    property BarCode: AnsiString read GetBarCode write SetBarCode;
    property LabelCode: AnsiString read GetLabelCode write SetLabelCode;
    property Catalog: AnsiString read GetCatalog write SetCatalog;
    property Language: WideString read GetLanguage write SetLanguage;
    property Genre: WideString read GetGenre write SetGenre;
    property Year: AnsiString read GetYear write SetYear;
    property RecordDate: AnsiString read GetRecordDate write SetRecordDate;
    property RecordLocation: WideString read GetRecordLocation write SetRecordLocation;
    property File_: WideString read GetFile write SetFile;
    property Related: WideString read GetRelated write SetRelated;
    property Abstract: WideString read GetAbstract write SetAbstract;
    property Bibliography: WideString read GetBibliography write SetBibliography;
    property Track: AnsiString read GetTrack write SetTrack;
    property Title: WideString read GetTitle write SetTitle;
    property SubTitle: WideString read GetSubTitle write SetSubTitle;
    property Comment: WideString read GetComment write SetComment;
  end;

const
  Id3v1Genres: array [TId3v1TagsGenreId] of AnsiString = (
    'Blues',
    'Classic Rock',
    'Country',
    'Dance',
    'Disco',
    'Funk',
    'Grunge',
    'Hip-Hop',
    'Jazz',
    'Metal',
    'New Age',
    'Oldies',
    'Other',
    'Pop',
    'R&B',
    'Rap',
    'Reggae',
    'Rock',
    'Techno',
    'Industrial',
    'Alternative',
    'Ska',
    'Death metal',
    'Pranks',
    'Soundtrack',
    'Euro-Techno',
    'Ambient',
    'Trip-Hop',
    'Vocal',
    'Jazz+Funk',
    'Fusion',
    'Trance',
    'Classical',
    'Instrumental',
    'Acid',
    'House',
    'Game',
    'Sound Clip',
    'Gospel',
    'Noise',
    'Alt. Rock',
    'Bass',
    'Soul',
    'Punk',
    'Space',
    'Meditative',
    'Instrumental pop',
    'Instrumental rock',
    'Ethnic',
    'Gothic',
    'Darkwave',
    'Techno-Industrial',
    'Electronic',
    'Pop-Folk',
    'Eurodance',
    'Dream',
    'Southern Rock',
    'Comedy',
    'Cult',
    'Gangsta',
    'Top 40',
    'Christian Rap',
    'Pop/Funk',
    'Jungle',
    'Native American',
    'Cabaret',
    'New Wave',
    'Psychedelic',
    'Rave',
    'Showtunes',
    'Trailer',
    'Lo-Fi',
    'Tribal',
    'Acid Punk',
    'Acid Jazz',
    'Polka',
    'Retro',
    'Musical',
    'Rock & Roll',
    'Hard Rock',
    'Folk',
    'Folk-Rock',
    'National Folk',
    'Swing',
    'Fast Fusion',
    'Bebob',
    'Latin',
    'Revival',
    'Celtic',
    'Bluegrass',
    'Avantgarde',
    'Gothic Rock',
    'Progressive Rock',
    'Psychedelic Rock',
    'Symphonic Rock',
    'Slow Rock',
    'Big Band',
    'Chorus',
    'Easy Listening',
    'Acoustic',
    'Humour',
    'Speech',
    'Chanson',
    'Opera',
    'Chamber music',
    'Sonata',
    'Symphony',
    'Booty Bass',
    'Primus',
    'Porn Groove',
    'Satire',
    'Slow Jam',
    'Club',
    'Tango',
    'Samba',
    'Folklore',
    'Ballad',
    'Power Ballad',
    'Rhythmic soul',
    'Freestyle',
    'Duet',
    'Punk Rock',
    'Drum Solo',
    'A Cappella',
    'Euro-House',
    'Dance Hall',
    'Goa',
    'Drum & Bass',
    'Club-House',
    'Hardcore',
    'Terror',
    'Indie',
    'BritPop',
    'Negerpunk',
    'Polsk Punk',
    'Beat',
    'Christian Gangsta Rap',
    'Heavy Metal',
    'Black Metal',
    'Crossover',
    'Contemporary Christian',
    'Christian Rock',
    'Merengue',
    'Salsa',
    'Thrash Metal',
    'Anime',
    'JPop',
    'Synthpop'
  );

  _id3v1_Artist  = 'artist';
  _id3v1_Album   = 'album';
  _id3v1_Genre   = 'genre';
  _id3v1_Year    = 'year';
  _id3v1_Track   = 'track';
  _id3v1_Title   = 'title';
  _id3v1_Comment = 'comment';

  _id3v2old_Artist    = 'TP1';
  _id3v2old_Album     = 'TAL';
  _id3v2old_Genre     = 'TCO';
  _id3v2old_Year      = 'TYE';
  _id3v2old_Track     = 'TRK';
  _id3v2old_Title     = 'TT2';
  _id3v2old_Comment   = 'COM';
  _id3v2old_Composer  = 'TCM';
  _id3v2old_Encoder   = 'TEN';
  _id3v2old_Copyright = 'TCR';
  _id3v2old_Language  = 'TLA';
  _id3v2old_Link      = 'WXX';

  _id3v2new_Artist    = 'TPE1';
  _id3v2new_Album     = 'TALB';
  _id3v2new_Genre     = 'TCON';
  _id3v2new_Year      = 'TYER';
  _id3v2new_Track     = 'TRCK';
  _id3v2new_Title     = 'TIT2';
  _id3v2new_Comment   = 'COMM';
  _id3v2new_Composer  = 'TCOM';
  _id3v2new_Encoder   = 'TENC';
  _id3v2new_Copyright = 'TCOP';
  _id3v2new_Language  = 'TLAN';
  _id3v2new_Link      = 'WXXX';

  _id3v2_Album_Id     =  0;
  _id3v2_Artist_Id    =  1;
  _id3v2_Genre_Id     =  2;
  _id3v2_Title_Id     =  3;
  _id3v2_Track_Id     =  4;
  _id3v2_Year_Id      =  5;
  _id3v2_Comment_Id   =  6;
  _id3v2_Composer_Id  =  7;
  _id3v2_Encoder_Id   =  8;
  _id3v2_Copyright_Id =  9;
  _id3v2_Language_Id  = 10;
  _id3v2_Link_Id      = 11;

  // frames ID for v2.2.x (when first index is False) and v2.3.x & v2.4.x (when first index is True)
  _id3v2_tags: array [Boolean, _id3v2_Album_Id .. _id3v2_Link_Id] of AnsiString =
    ((_id3v2old_Album,
      _id3v2old_Artist,
      _id3v2old_Genre,
      _id3v2old_Title,
      _id3v2old_Track,
      _id3v2old_Year,
      _id3v2old_Comment,
      _id3v2old_Composer,
      _id3v2old_Encoder,
      _id3v2old_Copyright,
      _id3v2old_Language,
      _id3v2old_Link),
     (
      _id3v2new_Album,
      _id3v2new_Artist,
      _id3v2new_Genre,
      _id3v2new_Title,
      _id3v2new_Track,
      _id3v2new_Year,
      _id3v2new_Comment,
      _id3v2new_Composer,
      _id3v2new_Encoder,
      _id3v2new_Copyright,
      _id3v2new_Language,
      _id3v2new_Link));

  _ape_Artist         = 'Artist';
  _ape_Composer       = 'Composer';
  _ape_Album          = 'Album';
  _ape_DebutAlbum     = 'Debut album';
  _ape_Publisher      = 'Publisher';
  _ape_Conductor      = 'Conductor';
  _ape_Copyright      = 'Copyright';
  _ape_ISBN           = 'ISBN';
  _ape_ISRC           = 'ISRC';
  _ape_BarCode        = 'EAN/UPC';
  _ape_LabelCode      = 'LC';
  _ape_Catalog        = 'Catalog';
  _ape_Language       = 'Language';
  _ape_Genre          = 'Genre';
  _ape_Year           = 'Year';
  _ape_RecordDate     = 'Record Date';
  _ape_RecordLocation = 'Record Location';
  _ape_File           = 'File';
  _ape_Related        = 'Related';
  _ape_Abstract       = 'Abstract';
  _ape_Bibliography   = 'Bibliography';
  _ape_Track          = 'Track';
  _ape_Title          = 'Title';
  _ape_SubTitle       = 'Subtitle';
  _ape_Comment        = 'Comment';

  _vorbis_Album     : AnsiString = 'album';
  _vorbis_Artist    : AnsiString = 'artist';
  _vorbis_Date      : AnsiString = 'date';
  _vorbis_Genre     : AnsiString = 'genre';
  _vorbis_Title     : AnsiString = 'title';
  _vorbis_Track     : AnsiString = 'tracknumber';
  _vorbis_Disc      : AnsiString = 'discnumber';
  _vorbis_Reference : AnsiString = 'replaygain_reference_loudness';
  _vorbis_TrackGain : AnsiString = 'replaygain_track_gain';
  _vorbis_TrackPeak : AnsiString = 'replaygain_track_peak';
  _vorbis_AlbumGain : AnsiString = 'replaygain_album_gain';
  _vorbis_AlbumPeak : AnsiString = 'replaygain_album_peak';

type

  TVorbisTags = class(TAuTags)
  private
    function GetAlbum : WideString;
    procedure SetAlbum(Value : WideString);
    function GetArtist :  WideString;
    procedure SetArtist(Value : WideString);
    function GetDate :  WideString;
    procedure SetDate(Value : WideString);
    function GetGenre :  WideString;
    procedure SetGenre(Value : WideString);
    function GetTitle : WideString;
    procedure SetTitle(Value : WideString);
    function GetTrack : WideString;
    procedure SetTrack(Value : WideString);
    function GetDisc : WideString;
    procedure SetDisc(Value : WideString);
    function GetReference : WideString;
    procedure SetReference(Value : WideString);
    function GetTrackGain : WideString;
    procedure SetTrackGain(Value : WideString);
    function GetTrackPeak : WideString;
    procedure SetTrackPeak(Value : WideString);
    function GetAlbumGain : WideString;
    procedure SetAlbumGain(Value : WideString);
    function GetAlbumPeak : WideString;
    procedure SetAlbumPeak(Value : WideString);
  public
    constructor Create; override;
  published
    property Album : WideString read GetAlbum write SetAlbum;
    property Artist : WideString read GetArtist write SetArtist;
    property Date : WideString read GetDate write SetDate;
    property Genre : WideString read GetGenre write SetGenre;
    property Title : WideString read GetTitle write SetTitle;
    property Track : WideString read GetTrack write SetTrack;
    property Disc : WideString read GetDisc write SetDisc;
    property Reference : WideString read GetReference write SetReference;
    property TrackGain : WideString read GetTrackGain write SetTrackGain;
    property TrackPeak : WideString read GetTrackPeak write SetTrackPeak;
    property AlbumGain : WideString read GetAlbumGain write SetAlbumGain;
    property AlbumPeak : WideString read GetAlbumPeak write SetAlbumPeak;
  end;


  procedure ReadApe2Tags(Stream : TStream; const Tags : TAPEv2Tags);

implementation

uses
  SysUtils, Variants;


function _min(n1, n2: Integer): Integer;
begin
  if n1 < n2 then
    Result := n1
  else
    Result := n2;
end;

{$WARNINGS OFF}

{ class TAuTags }

constructor TAuTags.Create;
begin
  inherited Create();

  FValues := TStringList.Create();
  TStringList(FValues).CaseSensitive := False;
  TStringList(FValues).Duplicates := dupIgnore;
  TStringList(FValues).Sorted := True;

  FEmpty := True;
end;

destructor TAuTags.Destroy;
var
  i: Integer;
begin
  for i := 0 to FValues.Count - 1 do
    Dispose(PTagValueInfo(Pointer(FValues.Objects[i])));
  FValues.Free();

  inherited;
end;

class function TAuTags.Presents(InFile: HFILE): Boolean;
begin
  Result := (InFile <> INVALID_HANDLE_VALUE);
end;

function TAuTags.GetIdCount: Integer;
begin
  Result := FValues.Count;
end;

function TAuTags.GetId(Index: Integer): AnsiString;
begin
  if (Index >= 0) and (Index < FValues.Count) then
    Result := FValues[Index]
  else
    Result := '';
end;

function TAuTags.GetValue(const Id: AnsiString): Variant;
var
 n: Integer;
begin
  n := FValues.IndexOf(Id);
  if n >= 0 then
    Result := PTagValueInfo(Pointer(FValues.Objects[n])).Value
  else
    Result := Null;
end;

procedure TAuTags.SetValue(const Id: AnsiString; const Value: Variant);
var
  n: Integer;
  p_value_info: PTagValueInfo;
begin
  n := FValues.IndexOf(Id);
  if n >= 0 then begin
    p_value_info := Pointer(FValues.Objects[n]);
    if not VarSameValue(Value, p_value_info.Value) then begin
      p_value_info.Value := Value;

      FEmpty := False;
      FChanged := True;
    end;
  end;
end;

function TAuTags.GetAsInteger(const Id: AnsiString): Integer;
var
  n: Integer;
  tag_value: Variant;
begin
  Result := 0;

  n := FValues.IndexOf(Id);
  if n >= 0 then begin
    tag_value := PTagValueInfo(Pointer(FValues.Objects[n])).Value;
    case VarType(tag_value) of
      varByte,
      varShortInt,
      varWord,
      varSmallint,
      varLongWord,
      varInteger :
        Result := tag_value;
      varString,
      varOleStr  :
        if TryStrToInt(tag_value, n) then
          Result := n;
    end;
  end;
end;

function TAuTags.GetAsString(const Id: AnsiString): AnsiString;
var
  n: Integer;
  tag_value: Variant;
begin
  Result := '';

  n := FValues.IndexOf(Id);
  if n >= 0 then begin
    tag_value := PTagValueInfo(Pointer(FValues.Objects[n])).Value;
    case VarType(tag_value) of
      varByte,
      varShortInt,
      varWord,
      varSmallint,
      varLongWord,
      varInteger :
        Result := IntToStr(tag_value);
      varString,
      varOleStr  :
        Result := tag_value;
    end;
  end;
end;

function TAuTags.GetAsWideString(const Id: AnsiString): WideString;
var
  n: Integer;
  tag_value: Variant;
begin
  Result := '';

  n := FValues.IndexOf(Id);
  if n >= 0 then begin
    tag_value := PTagValueInfo(Pointer(FValues.Objects[n])).Value;
    case VarType(tag_value) of
      varByte,
      varShortInt,
      varWord,
      varSmallint,
      varLongWord,
      varInteger :
        Result := IntToStr(tag_value);
      varString,
      varOleStr,
      258  :
        Result := tag_value;
    end;
  end;
end;

function TAuTags.AddId(const Id: AnsiString; const Default: Variant): Boolean;
var
  p_value_info: PTagValueInfo;
begin
  Result := (Id <> '');
  if Result and (FValues.IndexOf(Id) < 0) then begin
    New(p_value_info);
    p_value_info.Value := Default;
    FValues.AddObject(Id, Pointer(p_value_info));
  end;
end;

procedure TAuTags.Assign(Source: TPersistent);
var
  i: Integer;
  tag_id: AnsiString;
begin
  if Source is TAuTags then begin
    Clear();

    for i := 0 to TAuTags(Source).IdCount - 1 do begin
      tag_id := TAuTags(Source).Ids[i];
      Values[tag_id] := TAuTags(Source).Values[tag_id];
    end;
  end
  else
    inherited;
end;

procedure TAuTags.AssignTo(Dest: TPersistent);
var
  i: Integer;
  tag_id: AnsiString;
begin
  if Dest is TAuTags then begin
    TAuTags(Dest).Clear();

    for i := 0 to IdCount - 1 do begin
      tag_id := Ids[i];
      TAuTags(Dest).Values[tag_id] := Values[tag_id];
    end;
  end
  else
    inherited;
end;

procedure TAuTags.Clear;
var
  i: Integer;
begin
  for i := 0 to FValues.Count - 1 do
    PTagValueInfo(Pointer(FValues.Objects[i])).Value := Null;

  FEmpty := True;
  FChanged := True;
end;

function TAuTags.ReadFromFile(InFile: HFILE): Boolean;
begin
  Result := (InFile <> INVALID_HANDLE_VALUE);
  if Result then
    Clear();
end;

function TAuTags.WriteToFile(OutFile: HFILE; Unicode: Boolean = True): Boolean;
begin
  Result := (OutFile <> INVALID_HANDLE_VALUE);
end;


{ class TId3v1Tags }

constructor TId3v1Tags.Create;
begin
  inherited;

  AddId(_id3v1_Artist, Null);
  AddId(_id3v1_Album, Null);
  AddId(_id3v1_Genre, Id3v1TagsGenreIdDefault);
  AddId(_id3v1_Year, Null);
  AddId(_id3v1_Track, Null);
  AddId(_id3v1_Title, Null);
  AddId(_id3v1_Comment, Null);
end;

class function TId3v1Tags.Presents(InFile: HFILE): Boolean;
var
  file_pos: Cardinal;
  tags_info: TId3v1TagsInfo;
begin
  Result := (InFile <> INVALID_HANDLE_VALUE);
  if Result then begin
    file_pos := SetFilePointer(InFile, 0, nil, FILE_CURRENT);
    Result := (file_pos <> $FFFFFFFF);
    if Result then
      try
        Result := ReadTagsInfo(InFile, tags_info);
      finally
        SetFilePointer(InFile, file_pos, nil, FILE_BEGIN);
      end;
  end;
end;

const
  ID3V1_ID = 'TAG';

class function TId3v1Tags.ReadTagsInfo(InFile: HFILE; var TagsInfo: TId3v1TagsInfo): Boolean;
var
  bytes_read: Cardinal;
begin
  Result :=
    (SetFilePointer(InFile, - SizeOf(TagsInfo), nil, FILE_END) <> $FFFFFFFF) and
    ReadFile(InFile, TagsInfo, SizeOf(TagsInfo), bytes_read, nil) and
    (bytes_read = SizeOf(TagsInfo)) and
    (TagsInfo.ID = ID3V1_ID);
end;

function TId3v1Tags.GetTitle: AnsiString;
begin
  Result := AsString[_id3v1_Title];
end;

procedure TId3v1Tags.SetTitle(const Value: AnsiString);
begin
  Values[_id3v1_Title] := Value;
end;

function TId3v1Tags.GetArtist: AnsiString;
var
  tag_value: Variant;
begin
  tag_value := Values[_id3v1_Artist];
  if VarIsType(tag_value, [varString, varOleStr]) then
    Result := tag_value;
end;

procedure TId3v1Tags.SetArtist(const Value: AnsiString);
begin
  Values[_id3v1_Artist] := Value;
end;

function TId3v1Tags.GetAlbum: AnsiString;
begin
  Result := AsString[_id3v1_Album];
end;

procedure TId3v1Tags.SetAlbum(const Value: AnsiString);
begin
  Values[_id3v1_Album] := Value;
end;

function TId3v1Tags.GetYear: Word;
begin
  Result := AsInteger[_id3v1_Year];
end;

procedure TId3v1Tags.SetYear(Value: Word);
begin
  Values[_id3v1_Year] := Value;
end;

function TId3v1Tags.GetComment: AnsiString;
begin
  Result := AsString[_id3v1_Comment];
end;

procedure TId3v1Tags.SetComment(const Value: AnsiString);
begin
  Values[_id3v1_Comment] := Value;
end;

function TId3v1Tags.GetTrack: Byte;
begin
  Result := AsInteger[_id3v1_Track];
end;

procedure TId3v1Tags.SetTrack(Value: Byte);
begin
  Values[_id3v1_Track] := Value;
end;

function TId3v1Tags.GetGenre: AnsiString;
begin
  Result := Id3v1Genres[GenreId];
end;

procedure TId3v1Tags.SetGenre(const Value: AnsiString);
var
  i: TId3v1TagsGenreId;
  buf: AnsiString;
begin
  buf := Trim(Value);
  for i := Low(i) to High(i) do
    if SameText(buf, Id3v1Genres[i]) then begin
      Values[_id3v1_Genre] := i;

      Break;
    end;
end;

function TId3v1Tags.GetGenreId: TId3v1TagsGenreId;
var
  n: Integer;
begin
  n := AsInteger[_id3v1_Genre];
  if n in [Low(Result) .. High(Result)] then
    Result := n
  else
    Result := 12; // other
end;

procedure TId3v1Tags.SetGenreId(Value: TId3v1TagsGenreId);
begin
  Values[_id3v1_Genre] := Value;
end;

function TId3v1Tags.ReadFromFile(InFile: HFILE): Boolean;
var
  tags_info: TId3v1TagsInfo;
begin
  Result :=
    inherited ReadFromFile(InFile) and
    ReadTagsInfo(InFile, tags_info);
  if Result then begin
    Title  := Trim(tags_info.Title);
    Artist := Trim(tags_info.Artist);
    Album  := Trim(tags_info.Album);
    Year   := StrToIntDef(Trim(tags_info.Year), 0);

    if ((tags_info.Comment[Pred(High(tags_info.Comment))] = #0) and
        (tags_info.Comment[High(tags_info.Comment)] <> #0)) or
       ((tags_info.Comment[Pred(High(tags_info.Comment))] = #32) and
        (tags_info.Comment[High(tags_info.Comment)] <> #32))
    then begin
      Comment := Trim(Copy(tags_info.Comment,
        Low(tags_info.Comment), High(tags_info.Comment) - 2));
      Track := Byte(tags_info.Comment[High(tags_info.Comment)]);
    end
    else begin
      Comment := Trim(tags_info.Comment);
      Track := 0;
    end;
    GenreId := tags_info.GenreId;
  end;
end;

function TId3v1Tags.WriteToFile(OutFile: HFILE; Unicode: Boolean = True): Boolean;
var
  tags_info: TId3v1TagsInfo;
  buf: AnsiString;
  bytes_written: Cardinal;
begin
  Result :=
    inherited WriteToFile(OutFile) and
    (SetFilePointer(OutFile, 0, nil, FILE_END) <> $FFFFFFFF);
  if Result then begin
    FillChar(tags_info, SizeOf(tags_info), 0);

    tags_info.ID := ID3V1_ID;
    Move(Title[1], tags_info.Title[1],
      _min(Length(Title), SizeOf(tags_info.Title)));
    Move(Artist[1], tags_info.Artist[1],
      _min(Length(Artist), SizeOf(tags_info.Artist)));
    Move(Album[1], tags_info.Album[1],
      _min(Length(Album), SizeOf(tags_info.Album)));
    buf := IntToStr(Year);
    Move(buf[1], tags_info.Year[1],
      _min(Length(buf), SizeOf(tags_info.Year)));

    if Track <> 0 then begin
      Move(Comment[1], tags_info.Comment[1],
        _min(Length(Comment), SizeOf(tags_info.Comment) - 2));
      tags_info.Comment[Pred(High(tags_info.Comment))] := #0;
      tags_info.Comment[High(tags_info.Comment)] := AnsiChar(Track);
    end
    else
      Move(Comment[1], tags_info.Comment[1],
        _min(Length(Comment), SizeOf(tags_info.Comment)));

    tags_info.GenreId := GenreId;

    Result :=
      WriteFile(OutFile, tags_info, SizeOf(tags_info), bytes_written, nil) and
      (bytes_written = SizeOf(tags_info));
  end;
end;


{ class TId3v2Tags }

constructor TId3v2Tags.Create;
var
  i: Integer;
begin
  inherited;

  FNew := True;

  for i := Low(_id3v2_tags[False]) to High(_id3v2_tags[False]) do begin
    AddId(_id3v2_tags[False, i], Null);
    AddId(_id3v2_tags[True, i], Null);
  end;
end;

const
  ID3V2_ID = 'ID3';

  ID3V2_VERSION_2_2 = 2;
  ID3V2_VERSION_2_3 = 3;
  ID3V2_VERSION_2_4 = 4;

class function TId3v2Tags.Presents(InFile: HFILE): Boolean;
var
  file_pos: Cardinal;
  tags_info: TId3v2TagsInfo;
begin
  Result := (InFile <> INVALID_HANDLE_VALUE);
  if Result then begin
    file_pos := SetFilePointer(InFile, 0, nil, FILE_CURRENT);
    Result := (file_pos <> $FFFFFFFF);
    if Result then
      try
        Result := ReadTagsInfo(InFile, tags_info);
      finally
        SetFilePointer(InFile, file_pos, nil, FILE_BEGIN);
      end;
  end;
end;

class function TId3v2Tags.ReadTagsInfo(InFile: HFILE; var TagsInfo: TId3v2TagsInfo): Boolean;
var
  bytes_read: Cardinal;
begin
  Result :=
    ReadFile(InFile, TagsInfo, SizeOf(TagsInfo), bytes_read, nil) and
    (bytes_read = SizeOf(TagsInfo)) and
    (TagsInfo.ID = ID3V2_ID) and
    (TagsInfo.Revision < $FF) and
    (
     ((TagsInfo.Version = ID3V2_VERSION_2_2) and (TagsInfo.Flags and $3F = 0)) or
     ((TagsInfo.Version = ID3V2_VERSION_2_3) and (TagsInfo.Flags and $1F = 0)) or
     ((TagsInfo.Version = ID3V2_VERSION_2_4) and (TagsInfo.Flags and $0F = 0))
    ) and
    (TagsInfo.Size[0] and $80 = 0) and
    (TagsInfo.Size[1] and $80 = 0) and
    (TagsInfo.Size[2] and $80 = 0) and
    (TagsInfo.Size[3] and $80 = 0);
end;

constructor TCommonTags.Create;
begin
  inherited Create();
  AddId('Title', '');
  AddId('Album', '');
  AddId('Artist', '');
  AddId('Genre', '');
  AddId('Year', '');
  AddId('Track', '');
end;

function TCommonTags.GetArtist;
begin
  Result := AsWideString['Artist'];
end;

procedure TCommonTags.SetArtist;
begin
  Values['Artist'] := Value;
end;

function TCommonTags.GetTitle;
begin
  Result := AsWideString['Title'];
end;

procedure TCommonTags.SetTitle;
begin
  Values['Title'] := Value;
end;

function TCommonTags.GetAlbum;
begin
  Result := AsWideString['Album'];
end;

procedure TCommonTags.SetAlbum;
begin
  Values['Album'] := Value;
end;

function TCommonTags.GetGenre;
begin
  Result := AsWideString['Genre'];
end;

procedure TCommonTags.SetGenre;
begin
  Values['Genre'] := Value;
end;

function TCommonTags.GetYear;
begin
  Result := AsString['Year'];
end;

procedure TCommonTags.SetYear;
begin
  Values['Year'] := Value;
end;

function TCommonTags.GetTrack;
begin
  Result := AsString['Track'];
end;

procedure TCommonTags.SetTrack;
begin
  Values['Track'] := Value;
end;

function TId3v2Tags.GetArtist: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Artist_Id]];
end;

procedure TId3v2Tags.SetArtist(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Artist_Id]] := Value;
end;

function TId3v2Tags.GetAlbum: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Album_Id]];
end;

procedure TId3v2Tags.SetAlbum(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Album_Id]] := Value;
end;

function TId3v2Tags.GetGenre: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Genre_Id]];
end;

procedure TId3v2Tags.SetGenre(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Genre_Id]] := Value;
end;

function TId3v2Tags.GetYear: AnsiString;
begin
  Result := AsString[_id3v2_tags[FNew, _id3v2_Year_Id]];
end;

procedure TId3v2Tags.SetYear(const Value: AnsiString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Year_Id]] := Value;
end;

function TId3v2Tags.GetTrack: AnsiString;
begin
  Result := AsString[_id3v2_tags[FNew, _id3v2_Track_Id]];
end;

procedure TId3v2Tags.SetTrack(const Value: AnsiString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Track_Id]] := Value;
end;

function TId3v2Tags.GetTitle: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Title_Id]];
end;

procedure TId3v2Tags.SetTitle(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Title_Id]] := Value;
end;

function TId3v2Tags.GetComment: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Comment_Id]];
end;

procedure TId3v2Tags.SetComment(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Comment_Id]] := Value;
end;

function TId3v2Tags.GetComposer: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Composer_Id]];
end;

procedure TId3v2Tags.SetComposer(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Composer_Id]] := Value;
end;

function TId3v2Tags.GetEncoder: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Encoder_Id]];
end;

procedure TId3v2Tags.SetEncoder(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Encoder_Id]] := Value;
end;

function TId3v2Tags.GetCopyright: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Copyright_Id]];
end;

procedure TId3v2Tags.SetCopyright(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Copyright_Id]] := Value;
end;

function TId3v2Tags.GetLanguage: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Language_Id]];
end;

procedure TId3v2Tags.SetLanguage(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Language_Id]] := Value;
end;

function TId3v2Tags.GetLink: WideString;
begin
  Result := AsWideString[_id3v2_tags[FNew, _id3v2_Link_Id]];
end;

procedure TId3v2Tags.SetLink(const Value: WideString);
begin
  Values[_id3v2_tags[FNew, _id3v2_Link_Id]] := Value;
end;

const
  ID3V2_FLAG_UNSYNC               = $80;
  ID3V2_FLAG_EXT_HEADER_PRESENT   = $40;
  ID3V2_FLAG_EXPERIMENTAL         = $20;
  ID3V2_FLAG_FOOTER_PRESENT       = $10;

  ID3V2_EXT_FLAG_TAG_IS_UPDATE    = $40;
  ID3V2_EXT_FLAG_CRC_PRESENT      = $20;
  ID3V2_EXT_FLAG_TAG_RESTRICTIONS = $10;

  // frames count and tag size restrictions
  ID3V2_RESTRICTION_SIZE_128_1MB  = $00; // 00xxxxxx - max 128 frames and 1 MB total tag size
  ID3V2_RESTRICTION_SIZE_64_128KB = $40; // 01xxxxxx - max 64 frames and 128 KB total tag size
  ID3V2_RESTRICTION_SIZE_32_40KB  = $80; // 10xxxxxx - max 32 frames and 40 KB total tag size
  ID3V2_RESTRICTION_SIZE_32_4KB   = $C0; // 11xxxxxx - max 32 frames and 4 KB total tag size
  ID3V2_RESTRICTION_SIZE_MASK     = $C0;

  // strings encoding restrictions
  ID3V2_RESTRICTION_STRENC_MULTI  = $00; // xx0xxxxx - no restrictions
  ID3V2_RESTRICTION_STRENC_SINGLE = $20; // xx1xxxxx - strings are only encoded with
                                         //            ISO-8859-1 [ISO-8859-1] or UTF-8 [UTF-8]
  ID3V2_RESTRICTION_STRENC_MASK   = $20;

  // strings size restrictions
  ID3V2_RESTRICTION_STR_UNLIMITED = $00; // xxx00xxx - no restrictions
  ID3V2_RESTRICTION_STR_1024      = $08; // xxx01xxx - no AnsiString is longer than
                                         //            1024 characters
  ID3V2_RESTRICTION_STR_128       = $10; // xxx10xxx - no AnsiString is longer than
                                         //            128 characters
  ID3V2_RESTRICTION_STR_30        = $18; // xxx11xxx - no AnsiString is longer than
                                         //            30 characters
  ID3V2_RESTRICTION_STR_MASK      = $18;

  // imags encoding restrictions
  ID3V2_RESTRICTION_IMGENC_MULTI  = $00; // xxxxx0xx - no restrictions
  ID3V2_RESTRICTION_IMGENC_SINGLE = $04; // xxxxx1xx - images are encoded only with
                                         //            PNG [PNG] or JPEG [JFIF]
  ID3V2_RESTRICTION_IMGENC_MASK   = $04;

  // images size restrictions
  ID3V2_RESTRICTION_IMG_UNLIMITED = $00; // xxxxxx00 - no restrictions
  ID3V2_RESTRICTION_IMG_256x256   = $01; // xxxxxx01 - all images are
                                         //            256x256 pixels or smaller
  ID3V2_RESTRICTION_IMG_64x64     = $02; // xxxxxx10 - all images are
                                         //            64x64 pixels or smaller
  ID3V2_RESTRICTION_IMG_64x64PREC = $03; // xxxxxx11 - all images are
                                         //            exactly 64x64 pixels,
                                         //            unless required otherwise
  ID3V2_RESTRICTION_IMG_MASK      = $03;

  ID3V2_FRAME_ANSI_ID  = #$00;
  ID3V2_FRAME_UTF16_ID = #$01;
  ID3V2_FRAME_UTF8_ID  = #$03; // ???

  ID3V2_FRAME_FLAG_DISCARD_WHEN_TAG_ALTERED  = $8000;
  ID3V2_FRAME_FLAG_DISCARD_WHEN_FILE_ALTERED = $4000;
  ID3V2_FRAME_FLAG_READ_ONLY                 = $2000;
  ID3V2_FRAME_FLAG_COMPRESSED                = $0080;
  ID3V2_FRAME_FLAG_ENCRYPTED                 = $0040;
  ID3V2_FRAME_FLAG_GROUPED                   = $0020;

type
  TId3v2ExtHeader = packed record
    Size: packed array [0 .. 3] of Byte; // size of header
    ExtFlagsSize: Byte;                  // in bytes; must be $01
    ExtFlags: Byte;                      // extended flags
  end;
  PId3v2ExtHeader = ^TId3v2ExtHeader;

  TId3v2FrameHeaderOld = packed record   // frame header for v2.2.x
    ID: packed array [1 .. 3] of AnsiChar;   // frame ID
    Size: packed array [0 .. 2] of Byte; // frame size excluding size of TId3v2FrameHeaderOld structure
  end;
  PId3v2FrameHeaderOld = ^TId3v2FrameHeaderOld;

  TId3v2FrameHeaderNew = packed record   // frame header for v2.3.x & v2.4.x
    ID: packed array [1 .. 4] of AnsiChar;   // frame ID
    Size: packed array [0 .. 3] of Byte; // frame size excluding size of TId3v2FrameHeaderNew structure
    Flags: Word;                         // frame flags
  end;
  PId3v2FrameHeaderNew = ^TId3v2FrameHeaderNew;

  TId3v2TagsFooter = packed record
    ID: packed array [1 .. 3] of AnsiChar;   // must be "3DI"
    Version: Byte;                       // doubled Version in header (must be $04)
    Revision: Byte;                      // doubled Revision in header (must be 0???)
    Flags: Byte;                         // doubled Flags in header
    Size: packed array [0 .. 3] of Byte; // doubled Size in header
  end;
  PId3v2TagsFooter = ^TId3v2TagsFooter;

function TId3v2Tags.ReadFromFile(InFile: HFILE): Boolean;

  function get_tags_size(const tags_info: TId3v2TagsInfo): Cardinal;
  begin
    Result :=
      SizeOf(tags_info) +
      ((Integer(tags_info.Size[0]) shl 21) or
       (Integer(tags_info.Size[1]) shl 14) or
       (Integer(tags_info.Size[2]) shl  7) or
       (Integer(tags_info.Size[3]))
      );
    if tags_info.Flags and ID3V2_FLAG_FOOTER_PRESENT = ID3V2_FLAG_FOOTER_PRESENT then
      Inc(Result, SizeOf(TId3v2TagsFooter));
  end;

  function set_tag_item(const id, data: AnsiString;
    const tags_info: TId3v2TagsInfo): Boolean;
  const
    start_char_pos: array [Boolean] of Integer = (2, 4);
  var
    i: Integer;
    a_buf: AnsiString;
    w_buf: WideString;
  begin
    for i := Low(_id3v2_tags[False]) to High(_id3v2_tags[False]) do begin
      Result := (_id3v2_tags[FNew, i] = id);
      if Result then begin
        if i = _id3v2_Comment_Id then begin
          { TODO }
        end
        else
          case data[1] of
            ID3V2_FRAME_ANSI_ID   : begin
              a_buf := PAnsiChar(@(data[start_char_pos[False]]));
              SetValue(id, a_buf);
            end;
            ID3V2_FRAME_UTF16_ID: begin
              w_buf := PWideChar(@(data[start_char_pos[
                (Length(data) >= 3) and (data[2] = #$FF) and (data[3] = #$FE)]]));
              SetValue(id, w_buf);
            end;
            ID3V2_FRAME_UTF8_ID: begin
              w_buf := UTF8Decode(PAnsiChar(@(data[start_char_pos[False]])));
              SetValue(id, w_buf);
            end;
            else
              Result := False;
          end;

        Break;
      end;
    end;
  end;

  function read_frames_old(var tags_info: TId3v2TagsInfo): Boolean;
  var
    start_file_pos, end_tag_pos, file_size, file_pos, bytes_read: Cardinal;
    frame: TId3v2FrameHeaderOld;
    data_size: Cardinal;
    data: AnsiString;
  begin
    start_file_pos := SetFilePointer(InFile, 0, nil, FILE_CURRENT);
    Result := (start_file_pos <> $FFFFFFFF);
    if Result then begin
      end_tag_pos := start_file_pos + get_tags_size(tags_info) - SizeOf(tags_info);
      file_size := GetFileSize(InFile, nil);
      Result := (end_tag_pos <= file_size);
      if Result then
        try
          file_pos := start_file_pos;
          repeat
            Result :=
              ReadFile(InFile, frame, SizeOf(frame), bytes_read, nil) and
              (bytes_read = SizeOf(frame)) and
              (frame.ID[1] in ['A' .. 'Z']);
            Inc(file_pos, bytes_read);
            Result := (file_pos < end_tag_pos) and Result;

            if not Result then
              Break;

            data_size :=
              Integer(frame.Size[0]) shl 16 +
              Integer(frame.Size[1]) shl  8 +
              Integer(frame.Size[2]);
            if data_size > 0 then begin
              SetLength(data, data_size + 1);
              FillChar(data[1], Length(data), 0);

              Result :=
                ReadFile(InFile, data[1], data_size, bytes_read, nil) and
                (bytes_read = data_size);
              Inc(file_pos, bytes_read);
              Result := (file_pos <= end_tag_pos) and Result;

              if not Result then
                Break;

              set_tag_item(frame.ID, data, tags_info);
            end;
          until file_pos >= end_tag_pos;
        finally
          if not Result then
            SetFilePointer(InFile, start_file_pos, nil, FILE_BEGIN);
        end;
    end;
  end;

  function read_frames_new(var tags_info: TId3v2TagsInfo): Boolean;
  var
    start_file_pos, end_tag_pos, file_size, file_pos, bytes_read: Cardinal;
    frame: TId3v2FrameHeaderNew;
    data_size: Cardinal;
    data: AnsiString;
  begin
    start_file_pos := SetFilePointer(InFile, 0, nil, FILE_CURRENT);
    Result := (start_file_pos <> $FFFFFFFF);
    if Result then begin
      end_tag_pos := start_file_pos + get_tags_size(tags_info) - SizeOf(tags_info);
      file_size := GetFileSize(InFile, nil);
      Result := (end_tag_pos <= file_size);
      if Result then
        try
          file_pos := start_file_pos;
          repeat
            Result :=
              ReadFile(InFile, frame, SizeOf(frame), bytes_read, nil) and
              (bytes_read = SizeOf(frame)) and
              (frame.ID[1] in ['A' .. 'Z']);
            Inc(file_pos, bytes_read);
            Result := (file_pos < end_tag_pos) and Result;

            if not Result then
              Break;

            data_size :=
              Integer(frame.Size[0]) shl 24 +
              Integer(frame.Size[1]) shl 16 +
              Integer(frame.Size[2]) shl  8 +
              Integer(frame.Size[3]);
            if data_size > 0 then begin
              SetLength(data, data_size + 2);
              FillChar(data[1], Length(data), 0);

              Result :=
                ReadFile(InFile, data[1], data_size, bytes_read, nil) and
                (bytes_read = data_size);
              Inc(file_pos, bytes_read);
              Result := (file_pos <= end_tag_pos) and Result;

              if not Result then
                Break;

              {if frame.Flags and ID3V2_FRAME_FLAG_DISCARD_WHEN_TAG_ALTERED = 0 then}
                set_tag_item(frame.ID, data, tags_info);
            end;
          until file_pos >= end_tag_pos;
        finally
          if not Result then
            SetFilePointer(InFile, start_file_pos, nil, FILE_BEGIN);
        end;
    end;
  end;

var
  file_pos: Cardinal;
  tags_info: TId3v2TagsInfo;
begin
  Result := inherited ReadFromFile(InFile);
  if Result then begin
    file_pos := SetFilePointer(InFile, 0, nil, FILE_CURRENT);
    Result :=
      (file_pos <> $FFFFFFFF) and
      ReadTagsInfo(InFile, tags_info);
    if Result then
      try
        FNew := (tags_info.Version <> ID3V2_VERSION_2_2);

        if FNew then
          read_frames_new(tags_info)
        else
          read_frames_old(tags_info);
      finally
        SetFilePointer(InFile, file_pos + get_tags_size(tags_info), nil, FILE_BEGIN);
      end;
  end;
end;

{$DEFINE USE_ID3V2_4}

function TId3v2Tags.WriteToFile(OutFile: HFILE; Unicode: Boolean = True): Boolean;
const
  encoding_flags: array [Boolean] of AnsiChar = (
    ID3V2_FRAME_ANSI_ID,
{$IFDEF USE_ID3V2_4}
    ID3V2_FRAME_UTF8_ID
{$ELSE}
    ID3V2_FRAME_UTF16_ID
{$ENDIF}
  );
var
  ms: TMemoryStream;
  i: Integer;
  size, data_size, tags_size, full_data_size, padding_size: Cardinal;
  frame_is_unicode: Boolean;
  buf: AnsiString;
  w_buf: WideString;
  frame: TId3v2FrameHeaderNew;
  tags_info: TId3v2TagsInfo;
  h_mapping: THandle;
  p_mapping: Pointer;
begin
  Result := inherited WriteToFile(OutFile);
  if Result then begin
    ms := TMemoryStream.Create();
    try
      for i := Low(_id3v2_tags[True]) to High(_id3v2_tags[True]) do
        if i = _id3v2_Comment_Id then begin
          { TODO }
        end
        else begin
          frame_is_unicode := Unicode and
            VarIsType(Values[_id3v2_tags[True, i]], varOleStr);
          if frame_is_unicode then begin
            w_buf := AsWideString[_id3v2_tags[True, i]];
            if w_buf = '' then
              Break;

{$IFDEF USE_ID3V2_4}
            buf := UTF8Encode(w_buf);
{$ELSE}
            SetLength(buf, Length(w_buf) * SizeOf(w_buf[1]));
            Move(w_buf[1], buf[1], Length(buf));
            buf := #$FF#$FE + buf;
{$ENDIF}
          end
          else begin
            buf := AsString[_id3v2_tags[True, i]];
            if buf = '' then
              Break;
          end;
          buf := encoding_flags[frame_is_unicode] + buf;

          data_size := Length(buf);

          PCardinal(@(frame.ID))^ := PCardinal(@(_id3v2_tags[True, i][1]))^;
          frame.Size[0] := data_size shr 24;
          frame.Size[1] := data_size shr 16;
          frame.Size[2] := data_size shr  8;
          frame.Size[3] := data_size;
          frame.Flags := 0;

          ms.Write(frame, SizeOf(frame));
          ms.Write(buf[1], Length(buf));
        end;

      data_size := ms.Size;
      padding_size := 16 - ((SizeOf(tags_info) + data_size) mod 16);
      full_data_size := data_size + padding_size;

      tags_info.ID := ID3V2_ID;
      tags_info.Version :=
{$IFDEF USE_ID3V2_4}
        ID3V2_VERSION_2_4
{$ELSE}
        ID3V2_VERSION_2_3
{$ENDIF}
        ;
      tags_info.Revision := 0;
      tags_info.Flags := {ID3V2_FLAG_UNSYNC}0;
      tags_info.Size[0] := (full_data_size shr 21) and $7F;
      tags_info.Size[1] := (full_data_size shr 14) and $7F;
      tags_info.Size[2] := (full_data_size shr  7) and $7F;
      tags_info.Size[3] := full_data_size and $7F;

      tags_size := SizeOf(tags_info) + full_data_size;

      size := SetFilePointer(OutFile, tags_size, nil, FILE_END);
      Result :=
        (size <> $FFFFFFFF) and
        SetEndOfFile(OutFile);
      if Result then begin
        h_mapping := CreateFileMapping(
          OutFile,
          nil,
          PAGE_READWRITE,
          0, size,
          nil);
        Result := (h_mapping <> 0);
        if Result then
          try
            p_mapping := MapViewOfFile(h_mapping, FILE_MAP_WRITE, 0, 0, 0);
            Result := (p_mapping <> nil);
            if Result then
              try
                Move(p_mapping^, PAnsiChar(p_mapping)[tags_size], size - tags_size);
                Move(tags_info, p_mapping^, SizeOf(tags_info));
                Move(ms.Memory^, PAnsiChar(p_mapping)[SizeOf(tags_info)], data_size);
                FillChar(
                  PAnsiChar(p_mapping)[SizeOf(tags_info) + data_size], padding_size, 0);
              finally
                try
                  FlushViewOfFile(p_mapping, 0);
                finally
                  UnmapViewOfFile(p_mapping);
                end;
              end;
          finally
            CloseHandle(h_mapping);
          end;
      end;
    finally
      ms.Free();
    end;
  end;
end;


{ class TAPEv2Tags }

constructor TAPEv2Tags.Create;
begin
  inherited;

  AddId(_ape_Artist, Null);
  AddId(_ape_Composer, Null);
  AddId(_ape_Album, Null);
  AddId(_ape_DebutAlbum, Null);
  AddId(_ape_Publisher, Null);
  AddId(_ape_Conductor, Null);
  AddId(_ape_Copyright, Null);
  AddId(_ape_ISBN, Null);
  AddId(_ape_ISRC, Null);
  AddId(_ape_BarCode, Null);
  AddId(_ape_LabelCode, Null);
  AddId(_ape_Catalog, Null);
  AddId(_ape_Language, Null);
  AddId(_ape_Genre, Null);
  AddId(_ape_Year, Null);
  AddId(_ape_RecordDate, Null);
  AddId(_ape_RecordLocation, Null);
  AddId(_ape_File, Null);
  AddId(_ape_Related, Null);
  AddId(_ape_Abstract, Null);
  AddId(_ape_Bibliography, Null);
  AddId(_ape_Track, Null);
  AddId(_ape_Title, Null);
  AddId(_ape_SubTitle, Null);
  AddId(_ape_Comment, Null);
end;

function TAPEv2Tags.GetArtist: WideString;
begin
  Result := AsWideString[_ape_Artist];
end;

procedure TAPEv2Tags.SetArtist(const Value: WideString);
begin
  Values[_ape_Artist] := Value;
end;

function TAPEv2Tags.GetComposer: WideString;
begin
  Result := AsWideString[_ape_Composer];
end;

procedure TAPEv2Tags.SetComposer(const Value: WideString);
begin
  Values[_ape_Composer] := Value;
end;

function TAPEv2Tags.GetAlbum: WideString;
begin
  Result := AsWideString[_ape_Album];
end;

procedure TAPEv2Tags.SetAlbum(const Value: WideString);
begin
  Values[_ape_Album] := Value;
end;

function TAPEv2Tags.GetDebutAlbum: WideString;
begin
  Result := AsWideString[_ape_DebutAlbum];
end;

procedure TAPEv2Tags.SetDebutAlbum(const Value: WideString);
begin
  Values[_ape_DebutAlbum] := Value;
end;

function TAPEv2Tags.GetPublisher: WideString;
begin
  Result := AsWideString[_ape_Publisher];
end;

procedure TAPEv2Tags.SetPublisher(const Value: WideString);
begin
  Values[_ape_Publisher] := Value;
end;

function TAPEv2Tags.GetConductor: WideString;
begin
  Result := AsWideString[_ape_Conductor];
end;

procedure TAPEv2Tags.SetConductor(const Value: WideString);
begin
  Values[_ape_Conductor] := Value;
end;

function TAPEv2Tags.GetCopyright: WideString;
begin
  Result := AsWideString[_ape_Copyright];
end;

procedure TAPEv2Tags.SetCopyright(const Value: WideString);
begin
  Values[_ape_Copyright] := Value;
end;

function TAPEv2Tags.GetISBN: AnsiString;
begin
  Result := AsString[_ape_ISBN];
end;

procedure TAPEv2Tags.SetISBN(const Value: AnsiString);
begin
  Values[_ape_ISBN] := Value;
end;

function TAPEv2Tags.GetISRC: AnsiString;
begin
  Result := AsString[_ape_ISRC];
end;

procedure TAPEv2Tags.SetISRC(const Value: AnsiString);
begin
  Values[_ape_ISRC] := Value;
end;

function TAPEv2Tags.GetBarCode: AnsiString;
begin
  Result := AsString[_ape_BarCode];
end;

procedure TAPEv2Tags.SetBarCode(const Value: AnsiString);
begin
  Values[_ape_BarCode] := Value;
end;

function TAPEv2Tags.GetLabelCode: AnsiString;
begin
  Result := AsString[_ape_LabelCode];
end;

procedure TAPEv2Tags.SetLabelCode(const Value: AnsiString);
begin
  Values[_ape_LabelCode] := Value;
end;

function TAPEv2Tags.GetCatalog: AnsiString;
begin
  Result := AsString[_ape_Catalog];
end;

procedure TAPEv2Tags.SetCatalog(const Value: AnsiString);
begin
  Values[_ape_Catalog] := Value;
end;

function TAPEv2Tags.GetLanguage: WideString;
begin
  Result := AsWideString[_ape_Language];
end;

procedure TAPEv2Tags.SetLanguage(const Value: WideString);
begin
  Values[_ape_Language] := Value;
end;

function TAPEv2Tags.GetGenre: WideString;
begin
  Result := AsWideString[_ape_Genre];
end;

procedure TAPEv2Tags.SetGenre(const Value: WideString);
begin
  Values[_ape_Genre] := Value;
end;

function TAPEv2Tags.GetYear: AnsiString;
begin
  Result := AsWideString[_ape_Year];
end;

procedure TAPEv2Tags.SetYear(const Value: AnsiString);
begin
  Values[_ape_Year] := Value;
end;

function TAPEv2Tags.GetRecordDate: AnsiString;
begin
  Result := AsString[_ape_RecordDate];
end;

procedure TAPEv2Tags.SetRecordDate(const Value: AnsiString);
begin
  Values[_ape_RecordDate] := Value;
end;

function TAPEv2Tags.GetRecordLocation: WideString;
begin
  Result := AsWideString[_ape_RecordLocation];
end;

procedure TAPEv2Tags.SetRecordLocation(const Value: WideString);
begin
  Values[_ape_RecordLocation] := Value;
end;

function TAPEv2Tags.GetFile: WideString;
begin
  Result := AsWideString[_ape_File];
end;

procedure TAPEv2Tags.SetFile(const Value: WideString);
begin
  Values[_ape_File] := Value;
end;

function TAPEv2Tags.GetRelated: WideString;
begin
  Result := AsWideString[_ape_Related];
end;

procedure TAPEv2Tags.SetRelated(const Value: WideString);
begin
  Values[_ape_Related] := Value;
end;

function TAPEv2Tags.GetAbstract: WideString;
begin
  Result := AsWideString[_ape_Abstract];
end;

procedure TAPEv2Tags.SetAbstract(const Value: WideString);
begin
  Values[_ape_Abstract] := Value;
end;

function TAPEv2Tags.GetBibliography: WideString;
begin
  Result := AsWideString[_ape_Bibliography];
end;

procedure TAPEv2Tags.SetBibliography(const Value: WideString);
begin
  Values[_ape_Bibliography] := Value;
end;

function TAPEv2Tags.GetTrack: AnsiString;
begin
  Result := AsString[_ape_Track];
end;

procedure TAPEv2Tags.SetTrack(const Value: AnsiString);
begin
  Values[_ape_Track] := Value;
end;

function TAPEv2Tags.GetTitle: WideString;
begin
  Result := AsWideString[_ape_Title];
end;

procedure TAPEv2Tags.SetTitle(const Value: WideString);
begin
  Values[_ape_Title] := Value;
end;

function TAPEv2Tags.GetSubTitle: WideString;
begin
  Result := AsWideString[_ape_SubTitle];
end;

procedure TAPEv2Tags.SetSubTitle(const Value: WideString);
begin
  Values[_ape_SubTitle] := Value;
end;

function TAPEv2Tags.GetComment: WideString;
begin
  Result := AsWideString[_ape_Comment];
end;

procedure TAPEv2Tags.SetComment(const Value: WideString);
begin
  Values[_ape_Comment] := Value;
end;


{ class TVorbisTags }

constructor TVorbisTags.Create;
begin
  inherited Create;
  AddId(_vorbis_Album, Null);
  AddId(_vorbis_Artist, Null);
  AddId(_vorbis_Date, Null);
  AddId(_vorbis_Genre, Null);
  AddId(_vorbis_Title, Null);
  AddId(_vorbis_Track, Null);
  AddId(_vorbis_Disc, Null);
  AddId(_vorbis_Reference, Null);
  AddId(_vorbis_TrackGain, Null);
  AddId(_vorbis_TrackPeak, Null);
  AddId(_vorbis_AlbumGain, Null);
  AddId(_vorbis_AlbumPeak, Null);
end;

function TVorbisTags.GetAlbum;
begin
  Result := AsWideString[_vorbis_Album];
end;

procedure TVorbisTags.SetAlbum;
begin
  Values[_vorbis_Album] := Value;
end;

function TVorbisTags.GetArtist;
begin
  Result := AsWideString[_vorbis_Artist];
end;

procedure TVorbisTags.SetArtist;
begin
  Values[_vorbis_Artist] := Value;
end;

function TVorbisTags.GetDate;
begin
  Result := AsWideString[_vorbis_Date];
end;

procedure TVorbisTags.SetDate;
begin
  Values[_vorbis_Date] := Value;
end;

function TVorbisTags.GetGenre;
begin
  Result := AsWideString[_vorbis_Genre];
end;

procedure TVorbisTags.SetGenre;
begin
  Values[_vorbis_Genre] := Value;
end;

function TVorbisTags.GetTitle;
begin
  Result := AsWideString[_vorbis_Title];
end;

procedure TVorbisTags.SetTitle;
begin
  Values[_vorbis_Title] := Value;
end;

function TVorbisTags.GetTrack;
begin
  Result := AsWideString[_vorbis_Track];
end;

procedure TVorbisTags.SetTrack;
begin
  Values[_vorbis_Track] := Value;
end;

function TVorbisTags.GetDisc : WideString;
begin
  Result := AsWideString[_vorbis_Disc];
end;

procedure TVorbisTags.SetDisc(Value : WideString);
begin
  Values[_vorbis_Disc] := Value;
end;

function TVorbisTags.GetReference : WideString;
begin
  Result := AsWideString[_vorbis_Reference];
end;

procedure TVorbisTags.SetReference(Value : WideString);
begin
  Values[_vorbis_Reference] := Value;
end;

function TVorbisTags.GetTrackGain : WideString;
begin
  Result := AsWideString[_vorbis_TrackGain];
end;

procedure TVorbisTags.SetTrackGain(Value : WideString);
begin
  Values[_vorbis_TrackGain] := Value;
end;

function TVorbisTags.GetTrackPeak : WideString;
begin
  Result := AsWideString[_vorbis_TrackPeak];
end;

procedure TVorbisTags.SetTrackPeak(Value : WideString);
begin
  Values[_vorbis_TrackPeak] := Value;
end;

function TVorbisTags.GetAlbumGain : WideString;
begin
  Result := AsWideString[_vorbis_AlbumGain];
end;

procedure TVorbisTags.SetAlbumGain(Value : WideString);
begin
  Values[_vorbis_AlbumGain] := Value;
end;

function TVorbisTags.GetAlbumPeak : WideString;
begin
  Result := AsWideString[_vorbis_AlbumPeak];
end;

procedure TVorbisTags.SetAlbumPeak(Value : WideString);
begin
  Values[_vorbis_AlbumPeak] := Value;
end;

(* APE v 2 tags reading routine by A. Borovsky. *)

procedure ReadApe2Tags(Stream : TStream; const Tags : TAPEv2Tags);
var
 Header : TApev2TagsHeader;
 i, j : Integer;
 key : array[0..511] of AnsiChar;
 ValueLen, Flags : Integer;
 S : AnsiString;
begin
  Stream.Seek(-SizeOf(TApev2TagsHeader), soFromEnd);
  Stream.Read(Header, SizeOf(TApev2TagsHeader));
  if (Header.Preamble <> 'APETAGEX') or (Header.Version <> 2000) then
    Exit;
  Stream.Seek(-Header.TagSize, soFromEnd);
  for i := 0 to Header.ItemsCount - 1 do
  begin
    Stream.Read(ValueLen, 4);
    Stream.Read(Flags, 4);
    j := -1;
    repeat
      Inc(j);
      Stream.Read(key[j], 1);
    until key[j] = #0;
    SetLength(S, ValueLen);
    Stream.Read(S[1], ValueLen);
    if (Flags and $6) <> 0 then
      Continue; // This tag is not UTF-8 encoded text, skip it.
    if PAnsiChar(@key[0]) = _ape_Artist then
      Tags.SetArtist(Utf8Decode(Utf8String(S)))
    else
    if PAnsiChar(@key[0]) = _ape_Album then
      Tags.SetAlbum(Utf8Decode(Utf8String(S)))
    else
    if PAnsiChar(@key[0]) = _ape_Copyright then
      Tags.SetCopyright(Utf8Decode(Utf8String(S)))
    else
    if PAnsiChar(@key[0]) = _ape_Genre then
      Tags.SetGenre(Utf8Decode(Utf8String(S)))
    else
    if PAnsiChar(@key[0]) = _ape_Year then
      Tags.SetYear(Utf8Decode(Utf8String(S)))
    else
    if PAnsiChar(@key[0]) = _ape_Track then
      Tags.SetTrack(Utf8Decode(Utf8String(S)))
    else
    if PAnsiChar(@key[0]) = _ape_Title then
      Tags.SetTitle(Utf8Decode(Utf8String(S)));
  end;
end;

{$WARNINGS ON}

end.

