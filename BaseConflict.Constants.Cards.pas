unit BaseConflict.Constants.Cards;

interface

uses
  Generics.Collections,
  SysUtils,
  RegularExpressions,
  Math,
  StrUtils,
  Engine.Math,
  Engine.Script,
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows;

type
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  DUnitUUID = string;

  EnumCardType = (ctDrop, ctSpell, ctBuilding, ctSpawner);
  SetCardType = set of EnumCardType;

  EnumEntityColor = (ecColorless, ecBlack, ecGreen, ecRed, ecBlue, ecWhite);
  SetEntityColor = set of EnumEntityColor;

  SetTechLevels = set of byte;
  EnumLeague = (leNone, leStone, leBronze, leSilver, leGold, leCrystal);
  SetLeagues = set of byte;

  EnumDamageType = (
    dtSiege, dtTrue, dtIgnoreArmor,
    dtRanged, dtMelee, dtSplash, dtSpell, dtAbility,
    dtReflected, dtIrredirectable, dtRedirected, dtAntiAir, dtHoT, dtDoT, dtFlatHeal, dtOverheal,
    dtCharge);

  SetDamageType = set of EnumDamageType;

  EnumArmorType = (atUnarmored, atLight, atMedium, atHeavy, atFortified);

const

  // all non-special armor types aka the armor class chain
  ARMORY_TYPES_NORMAL = [atUnarmored .. atHeavy];

type
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  TTranslationVariable = class abstract
    protected
      FKey, FSpanClass : string;
    public
      constructor Create(const Key, SpanClass : string);
      function Apply(const Text : string) : string; virtual;
  end;

  TTranslationStringVariable = class(TTranslationVariable)
    protected
      FValue : string;
    public
      constructor Create(const Key, SpanClass : string; Value : string);
      function Apply(const Text : string) : string; override;
  end;

  TTranslationIntegerVariable = class(TTranslationVariable)
    protected
      FValue, FFractional : integer;
      FIsPercentage : boolean;
    public
      constructor Create(const Key, SpanClass : string; Value, Fractional : integer; IsPercentage : boolean);
      function Apply(const Text : string) : string; override;
  end;

  RAbilityDescription = record
    public
      Identifier, name, Hint : string;
      constructor Create(const Identifier : string; Variables : TList<TTranslationVariable>);
  end;

  TCardDescription = class
    public
      IsFilled : boolean;
      Identifier, name, ShortDescription, Description : string;
      procedure Fill(const Identifier : string; Variables : TList<TTranslationVariable>);
  end;

  /// <summary> Contains info about a card. </summary>
  TCardInfo = class
    private
      FUID, FBaseUID, FFilename, FSkinID : string;
      FTechlevel : integer;
      FCardType : EnumCardType;
      FCardColors : SetEntityColor;
      FLeague, FLevel : integer;
      constructor Create(CardType : EnumCardType; Colors : SetEntityColor; Filename : string; Techlevel : integer);
      function Clone(League, Level : integer) : TCardInfo;
    public
      property UID : string read FUID;
      property BaseUID : string read FBaseUID;
      property Filename : string read FFilename;
      property SkinID : string read FSkinID;
      property Techlevel : integer read FTechlevel;
      property CardType : EnumCardType read FCardType;
      [ScriptExcludeMember]
      property CardColors : SetEntityColor read FCardColors;
      property Level : integer read FLevel;
      property League : integer read FLeague;
      function HasSkin : boolean;
      function SkinFileSuffix : string;
      // type
      function IsSpell : boolean;
      function IsBuilding : boolean;
      function IsSpawner : boolean;
      function IsLegendary : boolean;
      function IsEpic : boolean;
      function IsDrop : boolean;
      // cost
      function GoldCost : integer;
      function WoodCost : integer;
      function MaxCost : integer;
      function ChargeCount : integer;
      function ChargeCooldown : integer;
      // stats
      function AttackDamage : single;
      function AttackCooldown : integer;
      function AttackRange : single;
      function DPS : single;
      function Health : single;
      function Energy : integer;
      function HasEnergy : boolean;
      function EnergyCap : integer;
      function SquadSize : integer;
      function IsRanged : boolean;
      function IsSiege : boolean;
      function IsSupporter : boolean;
      function DamageType : EnumDamageType;
      function ArmorType : EnumArmorType;
      function SkillList : string;
      [ScriptExcludeMember]
      function Skills : TArray<RAbilityDescription>;
      function HasSkills : boolean;
      function Keywords : TArray<string>;
      function HasKeywords : boolean;
      function AttackValue : integer;
      function DefenseValue : integer;
      function UtilityValue : integer;
      // spell meta data
      function SpellIsSingleTarget : boolean;
      function SpellIsAreaTarget : boolean;
      function SpellIsCharmTarget : boolean;
      function SpellIsAllyTarget : boolean;
      function SpellIsEnemyTarget : boolean;
      function SpellHasTwoTargets : boolean;
      // meta
      function Name : string;
      function ShortDescription : string;
      function Description : string;
      /// <summary> If the card is a spawner or drop, this is the spawned units filename otherwise its the cards filename. </summary>
      function UnitFilename : string;
      function SkinnedUnitFilename : string;
    public
      class function Compare(const Left, Right : TCardInfo) : integer;
  end;

  IHasCardInfo = interface
    function GetID : integer;
    function CardInfo : TCardInfo;
  end;

  EnumCardStringInfo = (ciName, ciShortDescription, ciDescription);

  /// <summary> Helper methods for all card relevant actions. </summary>
  TCardInfoManager = class
    strict private
      FServerUnitMapping : TObjectDictionary<string, TCardInfo>;
      FCardInfoCache : TObjectDictionary<string, TObjectDictionary<RTuple<integer, integer>, TCardInfo>>;
    private
      procedure AddCard(const UID : string; CardInfo : TCardInfo; SkinID : string = '');
      procedure AddSkin(const BaseUID, UID, SkinID : string);
    public
      constructor Create;
      function GetAllCardUIDs : TArray<string>;
      /// <summary> Resolves a card uid to its meta info. Result may be nil, if data is not present in client. </summary>
      function ResolveCardUID(const CardUID : string; League, Level : integer) : TCardInfo;
      function TryResolveCardUID(const CardUID : string; League, Level : integer; out CardInfo : TCardInfo) : boolean;
      function ScriptFilenameToCardInfo(const ScriptFile, SkinID : string; League, Level : integer) : TCardInfo;
      /// <summary> Resolves a script filename to the translated name of that unit. </summary>
      function ScriptFilenameToCardStringInfo(const ScriptFile, SkinID : string; League : integer; InfoType : EnumCardStringInfo = ciName) : string;
      /// <summary> Transforms a filename to the identifier of a unit, used by localization or to create the base unit of a drop or template. </summary>
      function ScriptFilenameToCardIdentifier(const ScriptFile : string) : string;
      function ScriptFilenameToCardColors(const ScriptFile : string) : SetEntityColor;
      function ScriptFilenameToCardType(const ScriptFile : string) : EnumCardType;
      function EntityColorsToFolder(const EntityColors : SetEntityColor) : string;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

const
  ALL_COLORS : SetEntityColor    = [low(EnumEntityColor) .. high(EnumEntityColor)];
  ALL_TECHLEVELS : SetTechLevels = [1, 2, 3];
  ALL_LEAGUES : SetLeagues       = [1, 2, 3, 4, 5];
  ALL_CARDTYPES : SetCardType    = [low(EnumCardType) .. high(EnumCardType)];
  MIN_LEAGUE                     = 1;
  MAX_LEAGUE                     = 5;
  MIN_LEVEL                      = 1;
  MAX_LEVEL                      = 5;
  DISABLE_LEAGUE_SYSTEM          = False;
  DEFAULT_LEAGUE                 = MAX_LEAGUE - 1;
  DEFAULT_LEVEL                  = MAX_LEVEL;

  FILE_EXTENSION_SPELL     = '.sps';
  FILE_IDENTIFIER_DROP     = 'Drop';
  FILE_IDENTIFIER_SPAWNER  = 'Spawner';
  FILE_IDENTIFIER_BUILDING = 'Building';
  FILE_IDENTIFIER_GOLEMS   = 'Golems';
  FILE_IDENTIFIER_SPELL    = 'Spell';
  FILE_EXTENSION_ENTITY    = '.ets';

  SKIN_GROUP_DEFAULT    = 'default';
  SKIN_GROUP_CRUSADER   = 'crusader';
  SKIN_GROUP_MACHINE    = 'machine';
  SKIN_GROUP_RAINBOW    = 'rainbow';
  SKIN_GROUP_SNOW       = 'snow';
  SKIN_GROUP_UNDERWORLD = 'underworld';
  SKIN_GROUP_WOODLANDS  = 'woodlands';
  SKIN_GROUP_WIP        = 'wip';
  SKIN_GROUP_PUR        = 'pur';
  SKIN_GROUP_SCILL      = 'scill';
  SKIN_GROUP_TOURNAMENT = 'tournament';
  SKIN_GROUP_SPRING     = 'spring';
  SKIN_GROUP_SUMMER     = 'summer';
  SKIN_GROUP_STEAM      = 'steam';
  SKIN_GROUP_ROFL       = 'rofl';
  SKIN_GROUP_INFLAMED   = 'inflamed';
  SKIN_GROUP_POPULAR    = 'popular';

var
  CardInfoManager : TCardInfoManager;

implementation

uses
  BaseConflict.Constants,
  BaseConflict.Globals,
  BaseConflict.Classes.Shared;

{ TCardInfoManager }

function TCardInfoManager.ScriptFilenameToCardColors(const ScriptFile : string) : SetEntityColor;
var
  lowerScriptFile : string;
begin
  lowerScriptFile := ScriptFile.ToLowerInvariant;
  if lowerScriptFile.Contains('green\') then Result := [ecGreen]
  else if lowerScriptFile.Contains('white\') then Result := [ecWhite]
  else if lowerScriptFile.Contains('black\') then Result := [ecBlack]
  else if lowerScriptFile.Contains('red\') then Result := [ecRed]
  else if lowerScriptFile.Contains('blue\') then Result := [ecBlue]
  else if lowerScriptFile.Contains('colorless\') or lowerScriptFile.Contains('golems\') or lowerScriptFile.Contains('neutral\') or lowerScriptFile.Contains('scenario\') then Result := [ecColorless]
  else if lowerScriptFile.Contains('greenwhite\') then Result := [ecGreen, ecWhite]
  else if lowerScriptFile.Contains('blackwhite\') then Result := [ecBlack, ecWhite]
  else if lowerScriptFile.Contains('blackgreen\') then Result := [ecBlack, ecGreen]
  else Result := [];
end;

function TCardInfoManager.ScriptFilenameToCardIdentifier(const ScriptFile : string) : string;
begin
  Result := ExtractFileName(ScriptFile);
  Result := ChangeFileExt(Result, '');
  Result := HString.Replace(Result, [FILE_IDENTIFIER_DROP, FILE_IDENTIFIER_SPAWNER, FILE_IDENTIFIER_BUILDING, FILE_IDENTIFIER_SPELL])
end;

function TCardInfoManager.ScriptFilenameToCardInfo(const ScriptFile, SkinID : string; League, Level : integer) : TCardInfo;
var
  CardInfo : TCardInfo;
begin
  Result := nil;
  for CardInfo in FServerUnitMapping.Values do
    if SameText(CardInfo.Filename, ScriptFile) and SameText(CardInfo.SkinID, SkinID) then
        exit(ResolveCardUID(CardInfo.UID, League, Level));
end;

function TCardInfoManager.ScriptFilenameToCardStringInfo(const ScriptFile, SkinID : string; League : integer; InfoType : EnumCardStringInfo) : string;
var
  LangKey, LangKeyPrefix, TypeKey, SkinKey : string;
  CardType : EnumCardType;
begin
  LangKeyPrefix := '';
  case InfoType of
    ciName : LangKeyPrefix := 'card_name_';
    ciShortDescription : LangKeyPrefix := 'card_short_description_';
    ciDescription : LangKeyPrefix := 'card_description_';
  end;
  CardType := ScriptFilenameToCardType(ScriptFile);
  case CardType of
    ctDrop : TypeKey := '_drop';
    ctSpell : TypeKey := '';
    ctBuilding : TypeKey := '';
    ctSpawner : TypeKey := '_spawner';
  else TypeKey := '';
  end;
  if SkinID <> '' then
      SkinKey := '_' + SkinID
  else
      SkinKey := '';
  LangKey := '§' + LangKeyPrefix + ScriptFilenameToCardIdentifier(ScriptFile).Replace(FILE_IDENTIFIER_GOLEMS, '') + SkinKey;
  // first try entity with league and card type
  if not _(LangKey + TypeKey + '_' + Inttostr(League), Result) and
    not _(LangKey + TypeKey, Result) and
    not _(LangKey + '_' + Inttostr(League), Result) and
    not _(LangKey, Result) then
  begin
    // then try same without suffixes
    LangKey := '§' + LangKeyPrefix + ScriptFilenameToCardIdentifier(TRegex.SubstituteDirect(ScriptFile, '(_\w+)', ''));
    if not _(LangKey + TypeKey + '_' + Inttostr(League), Result) and
      not _(LangKey + TypeKey, Result) and
      not _(LangKey + '_' + Inttostr(League), Result) then
        Result := _(LangKey);
  end;
end;

function TCardInfoManager.ScriptFilenameToCardType(const ScriptFile : string) : EnumCardType;
begin
  if ContainsText(ScriptFile, FILE_IDENTIFIER_SPAWNER) then Result := ctSpawner
  else if ContainsText(ScriptFile, FILE_IDENTIFIER_BUILDING) then Result := ctBuilding
  else if ContainsText(ScriptFile, FILE_EXTENSION_SPELL) or ContainsText(ScriptFile, FILE_IDENTIFIER_SPELL) then Result := ctSpell
  else Result := ctDrop;
end;

procedure TCardInfoManager.AddCard(const UID : string; CardInfo : TCardInfo; SkinID : string);
begin
  CardInfo.FUID := UID;
  // unskinned cards have themselves as base
  if CardInfo.BaseUID = '' then
      CardInfo.FBaseUID := CardInfo.UID;
  CardInfo.FSkinID := SkinID;
  FServerUnitMapping.Add(UID, CardInfo);
end;

procedure TCardInfoManager.AddSkin(const BaseUID, UID, SkinID : string);
var
  CardInfo : TCardInfo;
begin
  CardInfo := FServerUnitMapping[BaseUID];
  // if first skin is added to a card its default entry is the default skin
  if not CardInfo.HasSkin then
      CardInfo.FSkinID := SKIN_GROUP_DEFAULT;
  CardInfo := CardInfo.Clone(MAX_LEAGUE, MAX_LEVEL);
  CardInfo.FBaseUID := BaseUID;
  AddCard(UID, CardInfo, SkinID);
end;

constructor TCardInfoManager.Create;
begin
  FServerUnitMapping := TObjectDictionary<string, TCardInfo>.Create([doOwnsValues]);
  FCardInfoCache := TObjectDictionary < string, TObjectDictionary < RTuple<integer, integer>, TCardInfo >>.Create([doOwnsValues]);
end;

destructor TCardInfoManager.Destroy;
begin
  FServerUnitMapping.Free;
  FCardInfoCache.Free;
  inherited;
end;

function TCardInfoManager.EntityColorsToFolder(const EntityColors : SetEntityColor) : string;
begin
  Result := '';
  if ecBlack in EntityColors then Result := Result + 'Black';
  if ecBlue in EntityColors then Result := Result + 'Blue';
  if ecColorless in EntityColors then Result := Result + 'Colorless';
  if ecGreen in EntityColors then Result := Result + 'Green';
  if ecRed in EntityColors then Result := Result + 'Red';
  if ecWhite in EntityColors then Result := Result + 'White';
  Result := Result + '\';
end;

function TCardInfoManager.GetAllCardUIDs : TArray<string>;
begin
  Result := FServerUnitMapping.Keys.ToArray;
end;

function TCardInfoManager.ResolveCardUID(const CardUID : string; League, Level : integer) : TCardInfo;
begin
  if DISABLE_LEAGUE_SYSTEM then
  begin
    League := DEFAULT_LEAGUE;
    Level := DEFAULT_LEVEL;
  end;
  // replace is hack for dui
  if not TryResolveCardUID(CardUID.Replace('_', '-'), League, Level, Result) then Result := nil;
end;

function TCardInfoManager.TryResolveCardUID(const CardUID : string; League, Level : integer; out CardInfo : TCardInfo) : boolean;
var
  CardInfos : TObjectDictionary<RTuple<integer, integer>, TCardInfo>;
  Res : TCardInfo;
begin
  if DISABLE_LEAGUE_SYSTEM then
  begin
    League := DEFAULT_LEAGUE;
    Level := DEFAULT_LEVEL;
  end;

  if not FCardInfoCache.TryGetValue(CardUID, CardInfos) then
  begin
    CardInfos := TObjectDictionary<RTuple<integer, integer>, TCardInfo>.Create([doOwnsValues]);
    FCardInfoCache.Add(CardUID, CardInfos);
  end;
  if not CardInfos.TryGetValue(RTuple<integer, integer>.Create(League, Level), Res) then
  begin
    if FServerUnitMapping.TryGetValue(CardUID, Res) then
    begin
      Res := Res.Clone(League, Level);
      CardInfos.Add(RTuple<integer, integer>.Create(League, Level), Res);
    end
    else
    begin
      HLog.Write(elWarning, 'TCardInfoManager.ResolveCardUID: Card "%s" is not present in client!', [CardUID]);
      exit(False);
    end;
  end;
  CardInfo := Res;
  Result := True;
end;

{ TCardInfo }

function TCardInfo.ArmorType : EnumArmorType;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiArmorType, []).AsEnumType<EnumArmorType>;
end;

function TCardInfo.AttackCooldown : integer;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiCooldown, [GROUP_MAINWEAPON]).AsInteger;
end;

function TCardInfo.AttackDamage : single;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiWelaDamage, [GROUP_MAINWEAPON]).AsSingle;
end;

function TCardInfo.AttackRange : single;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiWelaRange, [GROUP_MAINWEAPON]).AsSingle;
end;

function TCardInfo.AttackValue : integer;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiCardStats, [], ord(reMetaAttack)).AsInteger;
end;

function TCardInfo.ChargeCooldown : integer;
begin
  if IsSpell then
  begin
    Result := EntityDataCache.Read(Filename, League, Level, eiCooldown, [1]).AsInteger;
  end
  else
      Result := EntityDataCache.Read(Filename, League, Level, eiCooldown, []).AsInteger;
end;

function TCardInfo.ChargeCount : integer;
begin
  Result := EntityDataCache.Read(Filename, League, Level, eiResourceCap, [], ord(reCharge)).AsInteger;
end;

function TCardInfo.Clone(League, Level : integer) : TCardInfo;
begin
  Result := TCardInfo.Create(
    self.CardType,
    self.CardColors,
    self.Filename,
    self.Techlevel);
  Result.FLeague := League;
  Result.FLevel := Level;
  Result.FUID := self.UID;
  Result.FBaseUID := self.BaseUID;
  Result.FSkinID := self.SkinID;
end;

class function TCardInfo.Compare(const Left, Right : TCardInfo) : integer;
var
  Inverse : boolean;
  L, R : TCardInfo;
begin
  Result := 0;
  L := Left;
  R := Right;
  if not assigned(R) and not assigned(L) then exit;
  Inverse := assigned(R) and not assigned(L);
  if Inverse then HGeneric.Swap<TCardInfo>(L, R);

  if assigned(L) then
  begin
    if not assigned(R) then
    begin
      if L.IsSpawner then Result := 1
      else Result := -1;
    end
    else
    begin
      // split for spawners
      if L.IsSpawner and not R.IsSpawner then Result := 1
      else if not L.IsSpawner and R.IsSpawner then Result := -1
        // split for techlevel
      else if L.Techlevel <> R.Techlevel then Result := L.Techlevel - R.Techlevel
        // split for spells
      else if L.IsSpell and not R.IsSpell then Result := 1
      else if not L.IsSpell and R.IsSpell then Result := -1
        // split for buildings
      else if L.IsBuilding and not R.IsBuilding then Result := 1
      else if not L.IsBuilding and R.IsBuilding then Result := -1
        // order groups by filename
      else if L.Filename <> R.Filename then Result := CompareText(L.Filename, R.Filename)
        // order by league
      else if L.League <> R.League then Result := L.League - R.League
      else Result := L.Level - R.Level;
    end;
  end;
  if Inverse then Result := -Result;
end;

constructor TCardInfo.Create(CardType : EnumCardType; Colors : SetEntityColor; Filename : string; Techlevel : integer);
begin
  FLeague := MAX_LEAGUE;
  FLevel := MAX_LEVEL;
  FCardType := CardType;
  FCardColors := Colors;
  FFilename := Filename;
  FTechlevel := Techlevel;
end;

function TCardInfo.DamageType : EnumDamageType;
begin
  if IsSiege then Result := dtSiege
  else if IsRanged then Result := dtRanged
  else Result := dtMelee;
end;

function TCardInfo.DefenseValue : integer;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiCardStats, [], ord(reMetaDefense)).AsInteger;
end;

function TCardInfo.DPS : single;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiCooldown, [GROUP_MAINWEAPON]).AsInteger;
  if Result <= 0 then Result := 0
  else Result := EntityDataCache.Read(UnitFilename, League, Level, eiWelaDamage, [GROUP_MAINWEAPON]).AsSingle / (Result / 1000.0);
end;

function TCardInfo.Energy : integer;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiResourceBalance, [], ord(reMana)).AsInteger;
end;

function TCardInfo.EnergyCap : integer;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiResourceCap, [], ord(reMana)).AsInteger;
end;

function TCardInfo.GoldCost : integer;
begin
  Result := round(EntityDataCache.Read(Filename, League, Level, eiResourceCost, [], ord(reGold)).AsSingle);
end;

function TCardInfo.HasEnergy : boolean;
begin
  Result := EnergyCap > 0;
end;

function TCardInfo.HasKeywords : boolean;
begin
  Result := length(Keywords) > 0;
end;

function TCardInfo.HasSkills : boolean;
begin
  Result := length(Skills) > 0;
end;

function TCardInfo.HasSkin : boolean;
begin
  Result := SkinID <> '';
end;

function TCardInfo.Health : single;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiResourceCap, [], ord(reHealth)).AsSingle;
end;

function TCardInfo.IsBuilding : boolean;
begin
  Result := CardType = ctBuilding;
end;

function TCardInfo.IsDrop : boolean;
begin
  Result := CardType = ctDrop;
end;

function TCardInfo.IsEpic : boolean;
begin
  Result := upEpic in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.IsLegendary : boolean;
begin
  Result := upLegendary in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.IsRanged : boolean;
begin
  Result := dtRanged in EntityDataCache.Read(UnitFilename, League, Level, eiDamageType, [GROUP_MAINWEAPON]).AsType<SetDamageType>;
end;

function TCardInfo.IsSiege : boolean;
begin
  Result := dtSiege in EntityDataCache.Read(UnitFilename, League, Level, eiDamageType, [GROUP_MAINWEAPON]).AsType<SetDamageType>;
end;

function TCardInfo.IsSpawner : boolean;
begin
  Result := CardType = ctSpawner;
end;

function TCardInfo.IsSpell : boolean;
begin
  Result := CardType = ctSpell;
end;

function TCardInfo.IsSupporter : boolean;
begin
  Result := upSupporter in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.MaxCost : integer;
begin
  Result := round(Max(EntityDataCache.Read(Filename, League, Level, eiResourceCost, [], ord(reGold)).AsSingle, EntityDataCache.Read(Filename, League, Level, eiResourceCost, [], ord(reWood)).AsSingle));
end;

function TCardInfo.Name : string;
begin
  Result := CardInfoManager.ScriptFilenameToCardStringInfo(Filename, SkinID, League, ciName);
end;

function TCardInfo.ShortDescription : string;
var
  CardDescription : TCardDescription;
begin
  Result := '';
  CardDescription := TCardDescription.Create;
  EntityDataCache.Trigger(Filename, League, Level, eiBuildAbilityList, [nil, nil, CardDescription]);
  if CardDescription.IsFilled then
      Result := CardDescription.ShortDescription
  else
      Result := CardInfoManager.ScriptFilenameToCardStringInfo(Filename, SkinID, League, ciShortDescription);
  CardDescription.Free;
end;

function TCardInfo.Description : string;
var
  CardDescription : TCardDescription;
begin
  Result := '';
  CardDescription := TCardDescription.Create;
  EntityDataCache.Trigger(Filename, League, Level, eiBuildAbilityList, [nil, nil, CardDescription]);
  if CardDescription.IsFilled then
      Result := CardDescription.Description
  else
      Result := CardInfoManager.ScriptFilenameToCardStringInfo(Filename, SkinID, League, ciDescription);
  CardDescription.Free;
end;

function TCardInfo.SkillList : string;
var
  Abilities : TList<RAbilityDescription>;
  List : TList<string>;
  i : integer;
begin
  Result := '';
  Abilities := TList<RAbilityDescription>.Create;
  List := TList<string>.Create;
  EntityDataCache.Trigger(UnitFilename, League, Level, eiBuildAbilityList, [Abilities, nil, nil]);
  for i := 0 to Abilities.Count - 1 do
      List.Add(Abilities[i].Name);
  Result := HString.Join(List.ToArray, ', ');
  Abilities.Free;
  List.Free;
end;

function TCardInfo.Skills : TArray<RAbilityDescription>;
var
  SkillList : TList<RAbilityDescription>;
begin
  SkillList := TList<RAbilityDescription>.Create;
  EntityDataCache.Trigger(UnitFilename, League, Level, eiBuildAbilityList, [SkillList, nil, nil]);
  Result := SkillList.ToArray;
  SkillList.Free;
end;

function TCardInfo.SkinFileSuffix : string;
begin
  if HasSkin then
      Result := '_' + SkinID
  else
      Result := '';
end;

function TCardInfo.SkinnedUnitFilename : string;
begin
  if UnitFilename.Contains('.') then
      Result := UnitFilename.Replace('.', SkinFileSuffix + '.')
  else
      Result := UnitFilename + SkinFileSuffix;
end;

function TCardInfo.SpellHasTwoTargets : boolean;
begin
  Result := upSpellDoubleArea in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.SpellIsAllyTarget : boolean;
begin
  Result := upSpellAlly in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.SpellIsAreaTarget : boolean;
begin
  Result := upSpellArea in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.SpellIsCharmTarget : boolean;
begin
  Result := upSpellCharm in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.SpellIsEnemyTarget : boolean;
begin
  Result := upSpellEnemy in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.SpellIsSingleTarget : boolean;
begin
  Result := upSpellSingle in EntityDataCache.Read(UnitFilename, League, Level, eiUnitProperties, []).AsSetType<SetUnitProperty>;
end;

function TCardInfo.Keywords : TArray<string>;
var
  KeywordList : TList<string>;
begin
  KeywordList := TList<string>.Create;
  EntityDataCache.Trigger(UnitFilename, League, Level, eiBuildAbilityList, [nil, KeywordList, nil]);
  Result := KeywordList.ToArray;
  KeywordList.Free;
end;

function TCardInfo.SquadSize : integer;
begin
  Result := EntityDataCache.Read(Filename, League, Level, eiWelaCount, [GROUP_DROP_SPAWNER]).AsIntegerDefault(1);
end;

function TCardInfo.UnitFilename : string;
begin
  if CardType in [ctDrop, ctSpawner, ctBuilding] then Result := ExtractFilePath(Filename) + CardInfoManager.ScriptFilenameToCardIdentifier(Filename)
  else Result := Filename;
end;

function TCardInfo.UtilityValue : integer;
begin
  Result := EntityDataCache.Read(UnitFilename, League, Level, eiCardStats, [], ord(reMetaUtility)).AsInteger;
end;

function TCardInfo.WoodCost : integer;
begin
  Result := round(EntityDataCache.Read(Filename, League, Level, eiResourceCost, [], ord(reWood)).AsSingle);
end;

{ TTranslationVariable }

function TTranslationVariable.Apply(const Text : string) : string;
begin
  Result := Text;
end;

constructor TTranslationVariable.Create(const Key, SpanClass : string);
begin
  FKey := Key;
  FSpanClass := SpanClass;
end;

{ TTranslationIntegerVariable }

function TTranslationIntegerVariable.Apply(const Text : string) : string;
var
  ValueText : string;
begin
  Result := inherited Apply(Text);
  ValueText := Inttostr(FValue);
  if FFractional <> 0 then
      ValueText := ValueText + HInternationalizer.DecimalSeparator + Inttostr(FFractional);
  if FIsPercentage then
      ValueText := HInternationalizer.MakePercentage(ValueText);
  if FSpanClass <> '' then
      ValueText := '<span class="keyword ' + FSpanClass + '">' + ValueText + '</span>';
  Result := Result.Replace('%(' + FKey + ')', ValueText);
end;

constructor TTranslationIntegerVariable.Create(const Key, SpanClass : string; Value, Fractional : integer; IsPercentage : boolean);
begin
  inherited Create(Key, SpanClass);
  FValue := Value;
  FFractional := Fractional;
  FIsPercentage := IsPercentage;
end;

{ RAbilityDescription }

constructor RAbilityDescription.Create(const Identifier : string; Variables : TList<TTranslationVariable>);
var
  i : integer;
begin
  self.Identifier := Identifier;
  self.Name := HInternationalizer.TranslateTextRecursive('§unitability_name_' + Identifier).Replace(' ', #160);
  self.Hint := HInternationalizer.TranslateTextRecursive('§unitability_hint_' + Identifier);
  for i := 0 to Variables.Count - 1 do
  begin
    self.Name := Variables[i].Apply(self.Name);
    self.Hint := Variables[i].Apply(self.Hint);
  end;
end;

{ TTranslationStringVariable }

function TTranslationStringVariable.Apply(const Text : string) : string;
var
  ValueText : string;
begin
  Result := inherited Apply(Text);
  ValueText := FValue;
  if FSpanClass <> '' then
      ValueText := '<span class="keyword ' + FSpanClass + '">' + ValueText + '</span>';
  Result := Result.Replace('%(' + FKey + ')', ValueText);
end;

constructor TTranslationStringVariable.Create(const Key, SpanClass : string; Value : string);
begin
  inherited Create(Key, SpanClass);
  FValue := Value;
end;

{ TCardDescription }

procedure TCardDescription.Fill(const Identifier : string; Variables : TList<TTranslationVariable>);
var
  i : integer;
begin
  IsFilled := True;
  self.Identifier := Identifier;
  self.Name := HInternationalizer.TranslateTextRecursive('§card_name_' + Identifier);
  self.ShortDescription := HInternationalizer.TranslateTextRecursive('§card_short_description_' + Identifier);
  self.Description := HInternationalizer.TranslateTextRecursive('§card_description_' + Identifier);
  for i := 0 to Variables.Count - 1 do
  begin
    self.ShortDescription := Variables[i].Apply(self.ShortDescription);
    self.Description := Variables[i].Apply(self.Description);
  end;
end;

initialization

CardInfoManager := TCardInfoManager.Create;

/// /// White /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// spawner
CardInfoManager.AddCard('30b4f36d-03d4-413c-8e9c-dc9f70346c15', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\ArcherSpawner', 1));
CardInfoManager.AddSkin('30b4f36d-03d4-413c-8e9c-dc9f70346c15', '417f384a-7eb4-49d2-ad88-5b3904a01398', SKIN_GROUP_ROFL);
CardInfoManager.AddSkin('30b4f36d-03d4-413c-8e9c-dc9f70346c15', '48ae7ebe-0e3a-4955-80a8-29316e20e936', SKIN_GROUP_INFLAMED);
CardInfoManager.AddCard('0fc18397-7dfc-4df8-938c-940e5dbb34f0', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\AvengerSpawner', 3));
CardInfoManager.AddCard('19439e1a-aec8-4a83-909b-cd8741d81271', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\BallistaSpawner', 1));
CardInfoManager.AddCard('8b1471e4-a394-4d11-836c-06e9187135a7', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\DefenderSpawner', 3));
CardInfoManager.AddCard('212b4d7e-65f9-43fa-a3df-50b31dd3da8f', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\FootmanSpawner', 1));
CardInfoManager.AddSkin('212b4d7e-65f9-43fa-a3df-50b31dd3da8f', '21f58162-fc78-4acf-8a95-0735ec45f078', SKIN_GROUP_MACHINE);
CardInfoManager.AddSkin('212b4d7e-65f9-43fa-a3df-50b31dd3da8f', '6e2f39cd-82a3-4c94-9f90-5e17a65ed2c5', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('212b4d7e-65f9-43fa-a3df-50b31dd3da8f', 'c42dc08a-fa5c-4fa3-8f61-cc1a132804c3', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('11fbcd20-31d6-43d7-aba0-528163cdcb3d', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\HeavyGunnerSpawner', 2));
CardInfoManager.AddCard('43d78d4c-793e-4023-9c89-8caf1942b0d6', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\MarksmanSpawner', 2));
CardInfoManager.AddSkin('43d78d4c-793e-4023-9c89-8caf1942b0d6', 'abfd1ecc-bab3-49f3-9a98-e454ad0fbd27', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('cfd5b8a3-b414-423f-9fd4-6414cfb8ca67', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\PriestSpawner', 1));
CardInfoManager.AddSkin('cfd5b8a3-b414-423f-9fd4-6414cfb8ca67', '557ebd10-cdbe-4a1b-801b-67ee65d56822', SKIN_GROUP_WIP);
CardInfoManager.AddCard('0fb667e6-5c8b-4488-85ba-d932dbff8148', TCardInfo.Create(ctSpawner, [ecWhite], 'Units\White\MonkSpawner', 1));
CardInfoManager.AddSkin('0fb667e6-5c8b-4488-85ba-d932dbff8148', '5a1b91b8-41b4-4913-8a67-c9543272c6ad', SKIN_GROUP_UNDERWORLD);

// drops
CardInfoManager.AddCard('51c25adb-3f4b-4e89-a972-15c2080933b9', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\ArcherDrop', 1));
CardInfoManager.AddSkin('51c25adb-3f4b-4e89-a972-15c2080933b9', '2d74b457-5029-4fec-8b92-9b5945ba48ee', SKIN_GROUP_ROFL);
CardInfoManager.AddSkin('51c25adb-3f4b-4e89-a972-15c2080933b9', '4bb5dc05-4f82-453c-be15-8a2391a85581', SKIN_GROUP_INFLAMED);
CardInfoManager.AddCard('ad3f1e1f-8c32-444e-acdc-9e01416890a1', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\AvengerDrop', 3));
CardInfoManager.AddCard('d6775352-3586-4a2d-af0f-b3149d59dbec', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\BallistaDrop', 1));
CardInfoManager.AddCard('21780eb8-3d2c-4c97-b279-59971475f3f8', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\DefenderDrop', 3));
CardInfoManager.AddSkin('21780eb8-3d2c-4c97-b279-59971475f3f8', 'c5b74530-c1ee-45e0-8799-930d21585689', SKIN_GROUP_POPULAR);
CardInfoManager.AddCard('4a3d81c7-8c6b-454d-9469-95f6cf394c9b', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\FootmanDrop', 1));
CardInfoManager.AddSkin('4a3d81c7-8c6b-454d-9469-95f6cf394c9b', 'e83c321e-b0f7-4531-a1a7-0aa0b3f838fb', SKIN_GROUP_MACHINE);
CardInfoManager.AddSkin('4a3d81c7-8c6b-454d-9469-95f6cf394c9b', '62ef3759-94df-4511-bcb1-663f5b0088b7', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('4a3d81c7-8c6b-454d-9469-95f6cf394c9b', 'ffe7ab82-78f0-4e5f-b206-17483aa7bf13', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('5f0ce2b0-9e9b-4d1e-8c73-b55a7dd07963', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\HeavyGunnerDrop', 2));
CardInfoManager.AddCard('2af612dd-726d-4fa3-85ef-0d4192095da2', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\MarksmanDrop', 2));
CardInfoManager.AddSkin('2af612dd-726d-4fa3-85ef-0d4192095da2', '1a6dd801-e33b-4972-8b04-2d2e45277785', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('16bb2970-7977-4914-9d1c-287806f4e3db', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\PriestDrop', 1));
CardInfoManager.AddSkin('16bb2970-7977-4914-9d1c-287806f4e3db', '21eb2c26-9c50-4b30-977d-501dde0adb3e', SKIN_GROUP_WIP);
CardInfoManager.AddCard('f1dc5d00-f59f-4616-b3d7-beed8119cbad', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\MonkDrop', 1));
CardInfoManager.AddSkin('f1dc5d00-f59f-4616-b3d7-beed8119cbad', '686dfc20-b44c-49c7-9dff-6499237ad370', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddCard('d8e38876-95b0-4566-9185-fbac1d02e143', TCardInfo.Create(ctDrop, [ecWhite], 'Units\White\PatronSaintDrop', 3));
CardInfoManager.AddSkin('d8e38876-95b0-4566-9185-fbac1d02e143', '7beb986e-a8fa-460c-a054-44f7b866de16', SKIN_GROUP_MACHINE);

// building
CardInfoManager.AddCard('893292ed-8619-4514-b7e2-8cf80eceb397', TCardInfo.Create(ctBuilding, [ecWhite], 'Units\White\MonumentOfLightBuilding', 3));
CardInfoManager.AddSkin('893292ed-8619-4514-b7e2-8cf80eceb397', '40e8ec29-19d8-45f8-b450-d05127235bf4', SKIN_GROUP_SUMMER);
CardInfoManager.AddCard('3e6d5b8a-6d04-4427-9b8b-b498e7c4ee04', TCardInfo.Create(ctBuilding, [ecWhite], 'Units\White\SuntowerBuilding', 2));

// spells
CardInfoManager.AddCard('527dd787-d8e9-4817-b45a-13b72495dbf7', TCardInfo.Create(ctSpell, [ecWhite], 'Spells\White\HailOfArrows.sps', 2));
CardInfoManager.AddCard('a62ca9b8-35ec-4995-a44e-182fbe686523', TCardInfo.Create(ctSpell, [ecWhite], 'Spells\White\PromiseOfLife.sps', 2));
CardInfoManager.AddCard('c9ed10c4-bfda-4b7c-b8e9-e3c78981f9bf', TCardInfo.Create(ctSpell, [ecWhite], 'Spells\White\SurgeOfLight.sps', 1));
CardInfoManager.AddCard('e79286f7-cbea-474a-8717-7ef96bfd832a', TCardInfo.Create(ctSpell, [ecWhite], 'Spells\White\LightPulse.sps', 1));
CardInfoManager.AddCard('151333f7-1e43-4f80-9740-7ecf27da1404', TCardInfo.Create(ctSpell, [ecWhite], 'Spells\White\ShieldsUp.sps', 1));
CardInfoManager.AddCard('aea72381-f9fb-4bab-bd42-42548b20262a', TCardInfo.Create(ctSpell, [ecWhite], 'Spells\White\SolarFlare.sps', 3));

/// /// Green /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// spawner
CardInfoManager.AddCard('ad662053-56a2-4d57-bb17-288c43cc6612', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\GroundbreakerSpawner', 3));
CardInfoManager.AddCard('494c87c8-6df5-4b91-aa5c-53178be43ec8', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\WispSpawner', 1));
CardInfoManager.AddCard('d3b707ce-1619-4e14-a61c-bce039083381', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\OracleSpawner', 3));
CardInfoManager.AddSkin('d3b707ce-1619-4e14-a61c-bce039083381', '2a692620-505f-40ce-b020-0078850c08e2', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('d3b707ce-1619-4e14-a61c-bce039083381', 'acfd1d94-8ced-4d6b-beb0-77a68ae8678d', SKIN_GROUP_CRUSADER);
CardInfoManager.AddCard('82b5fa7d-b4f5-461a-be32-2366db17a24a', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\RootDudeSpawner', 2));
CardInfoManager.AddCard('32ac1b2a-c98a-4d6f-a25b-fef1c6d463dc', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\RootlingSpawner', 1));
CardInfoManager.AddSkin('32ac1b2a-c98a-4d6f-a25b-fef1c6d463dc', 'ff4ee4e9-17e0-46fb-8b8d-fffee797edbc', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('32ac1b2a-c98a-4d6f-a25b-fef1c6d463dc', '3bcbd07d-2df4-4139-afa0-4c82c0300c59', SKIN_GROUP_MACHINE);
CardInfoManager.AddCard('e47ee3c7-5acf-45a5-954e-bec81eda2022', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\ThistleSpawner', 1));
CardInfoManager.AddSkin('e47ee3c7-5acf-45a5-954e-bec81eda2022', 'd2d69998-cd26-4da8-948a-8e85897a152d', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('e47ee3c7-5acf-45a5-954e-bec81eda2022', 'eab283ff-e226-49a1-8a67-fcd9ea66e5cc', SKIN_GROUP_SCILL);
CardInfoManager.AddCard('ed0e3831-4b25-4437-9a88-797832387a95', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\WoodwalkerSpawner', 2), SKIN_GROUP_DEFAULT);
CardInfoManager.AddCard('08563ec3-ebb6-4865-9bcb-89aae6dc560c', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\HeartOfTheForestSpawner', 1));
CardInfoManager.AddCard('6be2f2c1-2916-4f85-84c4-1159d31596e6', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\SporeSpawner', 2));
CardInfoManager.AddCard('499b7ca8-b1f8-4c84-a2d1-8dd0660a4ce2', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\BrratuSpawner', 3));
CardInfoManager.AddCard('f51d56a6-8f25-4f53-ad2d-bb6e4b2c7c1c', TCardInfo.Create(ctSpawner, [ecGreen], 'Units\Green\SaplingSpawner', 1));
CardInfoManager.AddSkin('f51d56a6-8f25-4f53-ad2d-bb6e4b2c7c1c', '80bea52b-f377-44cb-a99d-8e39f8a2c7a5', SKIN_GROUP_SNOW);

// drops
CardInfoManager.AddCard('3e17f75d-eb92-4fbe-8e7e-857fdec8f3fe', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\GroundbreakerDrop', 3));
CardInfoManager.AddCard('be51818a-4a38-47d1-a06e-178b60b23bfa', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\WispDrop', 1));
CardInfoManager.AddCard('cb1b6a30-980c-4a2e-81ad-72c3b336b2ec', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\OracleDrop', 3));
CardInfoManager.AddSkin('cb1b6a30-980c-4a2e-81ad-72c3b336b2ec', '67be9bf3-3e75-406b-ab07-f7c602bc67f7', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('cb1b6a30-980c-4a2e-81ad-72c3b336b2ec', '89083900-d2e8-453c-a94d-250db5f8dd95', SKIN_GROUP_CRUSADER);
CardInfoManager.AddCard('88064f15-f5bb-45f7-8170-b9caa19249db', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\RootDudeDrop', 2));
CardInfoManager.AddCard('cc7f4ee1-ee58-47ff-9279-f4716aff562a', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\RootlingDrop', 1));
CardInfoManager.AddSkin('cc7f4ee1-ee58-47ff-9279-f4716aff562a', '3a45787b-1ae9-4c2e-b886-b3d61c61f132', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('cc7f4ee1-ee58-47ff-9279-f4716aff562a', 'b188235d-b72b-43ea-8d0e-871577415578', SKIN_GROUP_MACHINE);
CardInfoManager.AddCard('cadcde81-8c98-4091-ad62-7bc9cc3e179a', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\ThistleDrop', 1));
CardInfoManager.AddSkin('cadcde81-8c98-4091-ad62-7bc9cc3e179a', 'fb7e7ecd-be97-4507-9073-42459598f474', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddSkin('cadcde81-8c98-4091-ad62-7bc9cc3e179a', '0a25f4b6-87f2-442e-89c6-0b805997c9bb', SKIN_GROUP_SCILL);
CardInfoManager.AddCard('d55cdfba-c432-4b7e-9a7a-55a8b51e6a54', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\WoodwalkerDrop', 2), SKIN_GROUP_DEFAULT);
CardInfoManager.AddCard('18a8178c-6954-44df-97ae-be44ea3bee1f', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\HeartOfTheForestDrop', 1));
CardInfoManager.AddCard('b2635c4d-c693-403b-980a-cb2e45703078', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\SporeDrop', 2));
CardInfoManager.AddCard('1b4dbb14-635e-4bc0-8c46-8d07fe3b526d', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\BrratuDrop', 3));
CardInfoManager.AddSkin('1b4dbb14-635e-4bc0-8c46-8d07fe3b526d', 'f8af4151-a2af-4820-bb46-1c3ae9d021f4', SKIN_GROUP_UNDERWORLD);
CardInfoManager.AddCard('67e7217d-4b1a-4366-a3e5-b71bca952d1a', TCardInfo.Create(ctDrop, [ecGreen], 'Units\Green\SaplingDrop', 1));
CardInfoManager.AddSkin('67e7217d-4b1a-4366-a3e5-b71bca952d1a', 'e1eb10e7-6dae-420d-9ac7-49a80697f5cb', SKIN_GROUP_SNOW);

// buildings
CardInfoManager.AddCard('5e616d06-5022-4e13-8c1a-b16313d0a369', TCardInfo.Create(ctBuilding, [ecGreen], 'Units\Green\ForestGuardianBuilding', 2));
CardInfoManager.AddSkin('5e616d06-5022-4e13-8c1a-b16313d0a369', '068aaacc-50f4-4a06-9ce0-6f4c45c1f7a0', SKIN_GROUP_SPRING);
CardInfoManager.AddCard('745363e6-12ac-47dd-acaf-e6956b9c9526', TCardInfo.Create(ctBuilding, [ecGreen], 'Units\Green\SaplingFarmBuilding', 1));
CardInfoManager.AddSkin('745363e6-12ac-47dd-acaf-e6956b9c9526', '75b40857-3521-415c-a9ac-2841b32b0ad5', SKIN_GROUP_SNOW);

// spells
CardInfoManager.AddCard('902aa87b-7b2c-4508-91b9-bb20944c26d8', TCardInfo.Create(ctSpell, [ecGreen], 'Spells\Green\EntanglingRoots.sps', 1));
CardInfoManager.AddCard('e7399731-f68e-46d8-9c32-bc18679ba52e', TCardInfo.Create(ctSpell, [ecGreen], 'Spells\Green\GiantGrowth.sps', 1));
CardInfoManager.AddCard('a0c3d296-9f04-4cf3-b80d-7f207928b22d', TCardInfo.Create(ctSpell, [ecGreen], 'Spells\Green\EvolveThistle.sps', 3), SKIN_GROUP_DEFAULT);
CardInfoManager.AddCard('3b2e5e43-aa5c-4957-8d0f-9831e46846ea', TCardInfo.Create(ctSpell, [ecGreen], 'Spells\Green\EvolveOracle.sps', 2), SKIN_GROUP_DEFAULT);
CardInfoManager.AddCard('14501389-854c-4634-ac55-bf55950546f7', TCardInfo.Create(ctSpell, [ecGreen], 'Spells\Green\HealingGarden.sps', 2));
CardInfoManager.AddCard('6cccc3b4-4a60-4da9-bb06-04576bd9c2a9', TCardInfo.Create(ctSpell, [ecGreen], 'Spells\Green\SaplingCharge.sps', 3), SKIN_GROUP_DEFAULT);

/// /// Black /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// spawner
CardInfoManager.AddCard('1b2f89a9-d13f-408f-aae5-593fdffe1da3', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\VoidBaneSpawner', 1));
CardInfoManager.AddSkin('1b2f89a9-d13f-408f-aae5-593fdffe1da3', '930670b6-8ac4-48cd-b7dc-9c57faa77b46', SKIN_GROUP_CRUSADER);
CardInfoManager.AddSkin('1b2f89a9-d13f-408f-aae5-593fdffe1da3', 'b514a904-4ea2-450e-8a24-24ba01c3c706', SKIN_GROUP_RAINBOW);
CardInfoManager.AddCard('4db51640-3a58-447e-b743-a61ba44db1fc', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\VoidBowmanSpawner', 1));
CardInfoManager.AddSkin('4db51640-3a58-447e-b743-a61ba44db1fc', 'd8c812fc-a778-4c5a-bcaa-71014de6b0ab', SKIN_GROUP_RAINBOW);
CardInfoManager.AddCard('31f855cc-b85e-4325-b673-9de5ebb7389f', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\VoidSkeletonSpawner', 1));
CardInfoManager.AddSkin('31f855cc-b85e-4325-b673-9de5ebb7389f', '794315a1-00f4-4b3b-8e80-b19ad529a69b', SKIN_GROUP_CRUSADER);
CardInfoManager.AddCard('839aa57d-6080-422d-87d2-1361f830205a', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\VoidWormSpawner', 1));
CardInfoManager.AddSkin('839aa57d-6080-422d-87d2-1361f830205a', '543d70e8-9b66-493f-a9a9-8dd3930ce568', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('719edbd1-0bf1-4992-9e9d-6dec068c28e9', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\VoidCauldronSpawner', 2));
CardInfoManager.AddCard('c83b7eae-1337-4771-8e86-1978ef5e512f', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\VoidSlimeSpawner', 2));
CardInfoManager.AddCard('a22ae2f6-3be4-4113-8b74-0210c16d6e72', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\FrostgoyleSpawner', 2));
CardInfoManager.AddCard('2e995bd0-1287-475b-9479-6c36f64cdd63', TCardInfo.Create(ctSpawner, [ecBlack], 'Units\Black\VoidWraithSpawner', 3));

// drops
CardInfoManager.AddCard('08acfdc0-353f-4300-9f17-9323df2dd8be', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VoidBaneDrop', 1));
CardInfoManager.AddSkin('08acfdc0-353f-4300-9f17-9323df2dd8be', '07a7f4ab-0612-4e0f-915c-173fa26afc9f', SKIN_GROUP_CRUSADER);
CardInfoManager.AddSkin('08acfdc0-353f-4300-9f17-9323df2dd8be', '1d6fa41a-6163-4a7f-b134-7c4b405b6208', SKIN_GROUP_RAINBOW);
CardInfoManager.AddCard('8e3a2311-2d4b-4ba2-a1a0-e464b8a9066e', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VoidBowmanDrop', 1));
CardInfoManager.AddSkin('8e3a2311-2d4b-4ba2-a1a0-e464b8a9066e', '4bbf5033-7cf7-457a-abed-c11b767c3204', SKIN_GROUP_RAINBOW);
CardInfoManager.AddCard('bb588865-ea26-4cec-930a-7753ca688afe', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VoidSkeletonDrop', 1));
CardInfoManager.AddSkin('bb588865-ea26-4cec-930a-7753ca688afe', 'e258d822-7017-4bfe-9860-61d82826084d', SKIN_GROUP_CRUSADER);
CardInfoManager.AddCard('255b7bfc-c783-4de9-987c-14a7d9d67a38', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VoidWormDrop', 1));
CardInfoManager.AddSkin('255b7bfc-c783-4de9-987c-14a7d9d67a38', '009951cc-1bc1-43d6-83d4-1f15cd98d33a', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('6b1674a6-540f-414f-b1b9-e0727c16aa9d', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VoidCauldronDrop', 2));
CardInfoManager.AddCard('390b7f96-2514-41f2-a766-0b19728dea63', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VoidSlimeDrop', 2));
CardInfoManager.AddCard('b1298880-5a1e-4ea6-8996-c870a8b8b341', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\FrostgoyleDrop', 2));
CardInfoManager.AddCard('18b3c477-ae79-406e-af47-70c124ef6c3f', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VoidWraithDrop', 3));
CardInfoManager.AddCard('81325cdc-aa3b-4fba-a10b-5b1859652b0a', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\TyrusDrop', 3));
CardInfoManager.AddSkin('81325cdc-aa3b-4fba-a10b-5b1859652b0a', '4415a748-3482-4264-94a4-4fef44d076b8', SKIN_GROUP_INFLAMED);
CardInfoManager.AddCard('2f5d127b-fff1-4103-8df6-5234fdbfbe63', TCardInfo.Create(ctDrop, [ecBlack], 'Units\Black\VecraDrop', 3));
CardInfoManager.AddSkin('2f5d127b-fff1-4103-8df6-5234fdbfbe63', '4aa609ff-92de-4168-80f4-029181ea459a', SKIN_GROUP_WOODLANDS);

// buildings
CardInfoManager.AddCard('15745e9e-2b63-41bf-ade7-393fef69e20d', TCardInfo.Create(ctBuilding, [ecBlack], 'Units\Black\FrostgoyleFountainBuilding', 2));
CardInfoManager.AddCard('9e053b0b-e2f3-4a0f-95a0-1f909214304b', TCardInfo.Create(ctBuilding, [ecBlack], 'Units\Black\VoidAltarBuilding', 3));

// spells
CardInfoManager.AddCard('0642574f-fc6b-4da4-9766-2cc296c9d16a', TCardInfo.Create(ctSpell, [ecBlack], 'Spells\Black\Frostspear.sps', 1));
CardInfoManager.AddCard('626e356a-4716-4576-8dce-4258b67a623b', TCardInfo.Create(ctSpell, [ecBlack], 'Spells\Black\Frenzy.sps', 1));
CardInfoManager.AddCard('8fcce8be-380f-4aa1-b59b-8dce7ead68a5', TCardInfo.Create(ctSpell, [ecBlack], 'Spells\Black\OnTheEdge.sps', 2));
CardInfoManager.AddCard('b5c11a5b-3f35-465a-a625-c6d97a27586c', TCardInfo.Create(ctSpell, [ecBlack], 'Spells\Black\Freeze.sps', 2));
CardInfoManager.AddCard('ed98d788-32de-4b77-9785-f46a654b7306', TCardInfo.Create(ctSpell, [ecBlack], 'Spells\Black\PermaFrost.sps', 2));
CardInfoManager.AddCard('1ea85356-c5b1-4895-84e1-0ad7ceb9cd25', TCardInfo.Create(ctSpell, [ecBlack], 'Spells\Black\RipOutSoul.sps', 2));
CardInfoManager.AddCard('7334d609-9c1a-4b99-a463-459e54572e82', TCardInfo.Create(ctSpell, [ecBlack], 'Spells\Black\ShatterIce.sps', 3));

/// /// Blue /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// templates
CardInfoManager.AddCard('2adaae11-1e18-4d82-bd0b-e350db49d6e7', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\DamperDroneSpawner', 1));
CardInfoManager.AddSkin('2adaae11-1e18-4d82-bd0b-e350db49d6e7', '5fa623cd-ae15-40fe-978a-ab674b93dc1d', SKIN_GROUP_SCILL);
CardInfoManager.AddSkin('2adaae11-1e18-4d82-bd0b-e350db49d6e7', '38201fe5-79a0-43d9-9009-89c316bf257c', SKIN_GROUP_POPULAR);
CardInfoManager.AddCard('e253f975-4971-4aac-bf15-dab47eacf1b3', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\GatlingDroneSpawner', 1));
CardInfoManager.AddSkin('e253f975-4971-4aac-bf15-dab47eacf1b3', 'f146ce44-445e-49af-9978-14d30377ea3e', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('59567d94-1d18-40aa-bdc0-aaaa4961f82f', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\AtlasSpawner', 1));
CardInfoManager.AddCard('99850656-3a3d-4e75-b4a5-9b4b28566bcf', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\ShieldDroneSpawner', 2));
CardInfoManager.AddCard('428b49e0-b595-4f87-b266-0ff30b9458b6', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\PhaseDroneSpawner', 2));
CardInfoManager.AddSkin('428b49e0-b595-4f87-b266-0ff30b9458b6', '3579d179-0c09-4c90-a553-ca0d18ef6c25', SKIN_GROUP_PUR);
CardInfoManager.AddSkin('428b49e0-b595-4f87-b266-0ff30b9458b6', '3495b55d-ba55-4521-8607-72c2e584f5aa', SKIN_GROUP_CRUSADER);
CardInfoManager.AddCard('a177d679-b39d-4acc-8bf1-cf8c15a39d6e', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\InductionerSpawner', 2));
CardInfoManager.AddCard('2cf7d252-a490-4d12-b0db-12fa3f65bc90', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\AirdominatorSpawner', 3));
CardInfoManager.AddCard('99a6f2bf-11ea-4604-b45a-080c38079fbc', TCardInfo.Create(ctSpawner, [ecBlue], 'Units\Blue\BombardierSpawner', 3));

// drops
CardInfoManager.AddCard('6ae06699-eb38-4406-82e5-57ecf84f05e3', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\DamperDroneDrop', 1));
CardInfoManager.AddSkin('6ae06699-eb38-4406-82e5-57ecf84f05e3', '54932ebb-f796-41b4-8a19-69b59cd1ce71', SKIN_GROUP_SCILL);
CardInfoManager.AddSkin('6ae06699-eb38-4406-82e5-57ecf84f05e3', '2c386ff9-bf54-42db-8d71-106a64f2bfde', SKIN_GROUP_POPULAR);
CardInfoManager.AddCard('fa9a8fb1-709d-4d9a-ae0b-f3c1bd373e92', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\GatlingDroneDrop', 1));
CardInfoManager.AddSkin('fa9a8fb1-709d-4d9a-ae0b-f3c1bd373e92', '4e78ac7a-0003-4419-92d6-7283ddf49ba7', SKIN_GROUP_WOODLANDS);
CardInfoManager.AddCard('8bcbcf56-a10b-4d08-ac3b-7642a96c03cd', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\AtlasDrop', 1));
CardInfoManager.AddSkin('8bcbcf56-a10b-4d08-ac3b-7642a96c03cd', 'f1a171e8-c3c1-490e-a628-7c847222ce18', SKIN_GROUP_POPULAR);
CardInfoManager.AddCard('ac94c13d-ecd4-4315-8edf-bc6a0578787c', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\ShieldDroneDrop', 2));
CardInfoManager.AddCard('937c13c0-0b05-474a-bfca-9a58a29840f9', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\PhaseDroneDrop', 2));
CardInfoManager.AddSkin('937c13c0-0b05-474a-bfca-9a58a29840f9', '9a233a37-c556-4c0b-b2ca-462471ddc2f6', SKIN_GROUP_PUR);
CardInfoManager.AddSkin('937c13c0-0b05-474a-bfca-9a58a29840f9', 'a0e77f75-1cdd-43f8-9946-7f7f810ab3a2', SKIN_GROUP_CRUSADER);
CardInfoManager.AddCard('d84d3bc8-cc20-49cd-850e-add89caf6469', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\InductionerDrop', 2));
CardInfoManager.AddCard('94321982-2815-4b5f-b69d-5406fe51dff7', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\AirDominatorDrop', 3));
CardInfoManager.AddCard('27da1428-3c4f-4984-afc9-4337a7f0694f', TCardInfo.Create(ctDrop, [ecBlue], 'Units\Blue\BombardierDrop', 3));

// buildings
CardInfoManager.AddCard('d03f561e-257e-4ed0-8b60-3b75b93f04f8', TCardInfo.Create(ctBuilding, [ecBlue], 'Units\Blue\GatlingTurretBuilding', 1));
CardInfoManager.AddSkin('d03f561e-257e-4ed0-8b60-3b75b93f04f8', 'f52450a3-4a61-457d-9cf5-b6418782ee8b', SKIN_GROUP_STEAM);
CardInfoManager.AddCard('9772187b-4fc2-4836-bd76-1a6aef4c514d', TCardInfo.Create(ctBuilding, [ecBlue], 'Units\Blue\ObserverDroneBuilding', 1));
CardInfoManager.AddSkin('9772187b-4fc2-4836-bd76-1a6aef4c514d', '94f02ad3-cfda-43b8-9945-241f996ee4b8', SKIN_GROUP_STEAM);
CardInfoManager.AddCard('1e5e5ab0-0303-41b6-8c7e-9dfe15bcdd6b', TCardInfo.Create(ctBuilding, [ecBlue], 'Units\Blue\AmmoFactoryBuilding', 2));
CardInfoManager.AddCard('9456d83a-fc80-45ea-9b17-d3abdb9f2c70', TCardInfo.Create(ctBuilding, [ecBlue], 'Units\Blue\MissileTurretBuilding', 2));
CardInfoManager.AddSkin('9456d83a-fc80-45ea-9b17-d3abdb9f2c70', 'e9e73956-a7fa-462f-a646-60d0bd972d41', SKIN_GROUP_STEAM);
CardInfoManager.AddCard('747c7921-758c-4cd6-a114-8b40c5983bc8', TCardInfo.Create(ctBuilding, [ecBlue], 'Units\Blue\AegisBuilding', 3));
CardInfoManager.AddSkin('747c7921-758c-4cd6-a114-8b40c5983bc8', '16ef37ad-2cdb-46a3-9e14-37f07e187ed8', SKIN_GROUP_STEAM);

// spells
CardInfoManager.AddCard('bfd3d896-863b-469d-9b5b-ca8a1123c5e9', TCardInfo.Create(ctSpell, [ecBlue], 'Spells\Blue\EnergyRift.sps', 1));
CardInfoManager.AddCard('0d21dcff-3bc5-474f-a320-8702ca6fbc82', TCardInfo.Create(ctSpell, [ecBlue], 'Spells\Blue\AmmoRefill.sps', 1));
CardInfoManager.AddCard('f0f57263-91a4-403f-9791-6cb2c0663f28', TCardInfo.Create(ctSpell, [ecBlue], 'Spells\Blue\Relocate.sps', 1));
CardInfoManager.AddCard('2b3cf678-a40c-4782-ad51-a54f3011d604', TCardInfo.Create(ctSpell, [ecBlue], 'Spells\Blue\InverseGravity.sps', 2));
CardInfoManager.AddCard('ca9224e6-cea9-4adc-b2ee-9c2e22a58684', TCardInfo.Create(ctSpell, [ecBlue], 'Spells\Blue\FactoryReset.sps', 2));
CardInfoManager.AddCard('ad9586b2-3697-41fa-9973-e6ef197a391f', TCardInfo.Create(ctSpell, [ecBlue], 'Spells\Blue\FluxField.sps', 2));
CardInfoManager.AddCard('8e13cdb7-ea45-4afd-a1f7-6c1a2af6a7de', TCardInfo.Create(ctSpell, [ecBlue], 'Spells\Blue\OrbitalStrike.sps', 3));

/// /// Golems /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// templates
CardInfoManager.AddCard('37682981-4d24-4823-b596-4ec4b137f78e', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsSmallMeleeGolemSpawner', 1));
CardInfoManager.AddCard('a163c919-c376-4a5f-ac42-a984ab10448c', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsMediumMeleeGolemSpawner', 2));
CardInfoManager.AddSkin('a163c919-c376-4a5f-ac42-a984ab10448c', '7cc9f8ee-c40a-4740-a1a0-2dfc4d929a88', SKIN_GROUP_INFLAMED);
CardInfoManager.AddCard('42a04494-9aae-4311-9ad7-e0e4ddd4e4f4', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsBigMeleeGolemSpawner', 3));
CardInfoManager.AddCard('725ee15d-f806-4b79-a6f8-945e06523e0d', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsSmallRangedGolemSpawner', 1));
CardInfoManager.AddCard('fe0c51f3-a060-4869-afe7-23b785eccf5c', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsSmallCasterGolemSpawner', 1));
CardInfoManager.AddCard('c000900e-cf90-4e83-8198-b869b8e3ff29', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsBigCasterGolemSpawner', 3));
CardInfoManager.AddCard('2a045181-9350-42da-856a-1f6d88117e1b', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsSmallFlyingGolemSpawner', 2));
CardInfoManager.AddCard('23a2d2d4-faf5-4af6-85c0-997500ed0307', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsBigFlyingGolemSpawner', 3));
CardInfoManager.AddCard('a111e17c-00ca-490d-83b5-ae146ab42f45', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Golems\GolemsSiegeGolemSpawner', 2));

// drops
CardInfoManager.AddCard('87facebc-f094-41da-83d4-d4c09a571fa0', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsSmallMeleeGolemDrop', 1));
CardInfoManager.AddCard('f68be11b-21bc-4819-88d3-6c1f2b479322', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsMediumMeleeGolemDrop', 2));
CardInfoManager.AddSkin('f68be11b-21bc-4819-88d3-6c1f2b479322', 'f4896b1b-75ea-472b-969a-a7a7e46e132a', SKIN_GROUP_INFLAMED);
CardInfoManager.AddCard('ac6c6bf4-3e5c-41c5-a01b-110cdf8bc0b5', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsBigMeleeGolemDrop', 3));
CardInfoManager.AddCard('cb975a37-9514-4eb0-88ea-a00d732fe1b4', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsSmallRangedGolemDrop', 1));
CardInfoManager.AddCard('e82aec92-3f4d-4de8-880a-8fc17490db04', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsSmallCasterGolemDrop', 1));
CardInfoManager.AddCard('5509fbc2-4e3d-485c-8369-38b0132b4b4f', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsBigCasterGolemDrop', 3));
CardInfoManager.AddCard('2c0a8529-72e9-40c4-b34c-05300778e2aa', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsSmallFlyingGolemDrop', 2));
CardInfoManager.AddCard('0b86a588-ec6c-4ae1-a029-f1e85e53899e', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsBigFlyingGolemDrop', 3));
CardInfoManager.AddCard('aa359732-9770-4ce0-a145-8069efbebaa5', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsSiegeGolemDrop', 2));

CardInfoManager.AddCard('6e1b4102-f795-470f-948a-3dfd5555c544', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Golems\GolemsBossGolemDrop', 3));
CardInfoManager.AddSkin('6e1b4102-f795-470f-948a-3dfd5555c544', 'a54a3e84-20fb-447b-9594-5da9a05d123b', SKIN_GROUP_TOURNAMENT);
CardInfoManager.AddSkin('6e1b4102-f795-470f-948a-3dfd5555c544', '58a60298-ae14-4a5d-8784-a1f00a1b9d34', SKIN_GROUP_INFLAMED);

// buildings
CardInfoManager.AddCard('3c6b7af4-6ed6-400e-a5b6-702ebb50ffb6', TCardInfo.Create(ctBuilding, [ecColorless], 'Units\Golems\GolemsSmallGolemTowerBuilding', 1));
CardInfoManager.AddCard('7e6d25bb-932b-45f0-bec5-f80cc8c86852', TCardInfo.Create(ctBuilding, [ecColorless], 'Units\Golems\GolemsBigGolemTowerBuilding', 3));
CardInfoManager.AddCard('df65a92f-8e0d-4190-a1a1-1fda710bc5c2', TCardInfo.Create(ctBuilding, [ecColorless], 'Units\Golems\GolemsMeleeGolemTowerBuilding', 2));

// spells
CardInfoManager.AddCard('834b422d-cad6-4c06-9f18-c2612f19d86d', TCardInfo.Create(ctSpell, [ecColorless], 'Spells\Golems\EchoesOfTheFuture.sps', 1));
CardInfoManager.AddCard('a216f0e1-9287-473e-8974-4f09d3a07b4f', TCardInfo.Create(ctSpell, [ecColorless], 'Spells\Golems\Cataclysm.sps', 1));
CardInfoManager.AddCard('226c716c-694d-4108-b4a5-26c46cd0ffd9', TCardInfo.Create(ctSpell, [ecColorless], 'Spells\Golems\Petrify.sps', 2));
CardInfoManager.AddCard('0dbdb542-2e81-4278-8e8f-d6c4b154a434', TCardInfo.Create(ctSpell, [ecColorless], 'Spells\Golems\StoneCircle.sps', 2));
CardInfoManager.AddCard('3bbf6ae8-36da-4326-8ad3-c0f859b62ebb', TCardInfo.Create(ctSpell, [ecColorless], 'Spells\Golems\Earthquake.sps', 3));

/// /// Colorless /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// templates
CardInfoManager.AddCard('3c8eb374-e04b-4c20-b394-ffda5ef1834b', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\SmallMeleeGolemSpawner', 1));
CardInfoManager.AddCard('50585e07-2f44-4d4e-9a85-c736727f822f', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\MediumMeleeGolemSpawner', 2));
CardInfoManager.AddCard('6c4a4875-e884-4072-9e71-2f255ab6e487', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\BigMeleeGolemSpawner', 3));
CardInfoManager.AddCard('0a104943-4bce-4185-a372-a3ebf241c6ab', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\SmallRangedGolemSpawner', 1));
CardInfoManager.AddCard('dbf48014-5627-42a8-b21d-edf871194904', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\SmallCasterGolemSpawner', 1));
CardInfoManager.AddCard('bc45a23d-16f6-4d65-b0ec-5e8472bcc33c', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\BigCasterGolemSpawner', 3));
CardInfoManager.AddCard('adb48ea1-2e70-430f-adf3-a20631f3bc2e', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\SmallFlyingGolemSpawner', 2));
CardInfoManager.AddCard('41cfe2b9-f701-4e21-a52a-97d9253896be', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\BigFlyingGolemSpawner', 3));
CardInfoManager.AddCard('eb818adc-2cbb-4c5b-b9a7-ca37454e506e', TCardInfo.Create(ctSpawner, [ecColorless], 'Units\Colorless\SiegeGolemSpawner', 2));

// drops
CardInfoManager.AddCard('1008eaa7-3edc-4929-84bd-16ce34229ec4', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\SmallMeleeGolemDrop', 1));
CardInfoManager.AddCard('d1476b05-b537-4fbf-88e5-142478648b49', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\MediumMeleeGolemDrop', 2));
CardInfoManager.AddCard('b32092c6-24dc-49b1-9d33-82e2803b2b46', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\BigMeleeGolemDrop', 3));
CardInfoManager.AddCard('cc5ff47e-d099-466a-bb1b-7fd28d896cf2', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\SmallRangedGolemDrop', 1));
CardInfoManager.AddCard('36cd039d-45d7-4120-9905-91f701c10944', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\SmallCasterGolemDrop', 1));
CardInfoManager.AddCard('ed8a6758-3176-4ce1-b61a-53aec88877c0', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\BigCasterGolemDrop', 3));
CardInfoManager.AddCard('9f705b01-1dbc-453e-a66d-6a16e6e91112', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\SmallFlyingGolemDrop', 2));
CardInfoManager.AddCard('5b2cbf6c-3e44-44e5-bd7a-9ed9c02702a9', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\BigFlyingGolemDrop', 3));
CardInfoManager.AddCard('f836db3f-53d3-4079-84b9-a288594d65cf', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\SiegeGolemDrop', 2));

CardInfoManager.AddCard('ONLY FOR SANDBOX DEBUG PURPOSESSSSSS', TCardInfo.Create(ctDrop, [ecColorless], 'Units\Colorless\BossGolemDrop', 3));

// buildings
CardInfoManager.AddCard('5e0f23c3-e179-45fd-88fc-1034d3eea338', TCardInfo.Create(ctBuilding, [ecColorless], 'Units\Colorless\SmallGolemTowerBuilding', 1));
CardInfoManager.AddCard('fcf7e1b7-35d4-4c61-b3e1-49507877bfb5', TCardInfo.Create(ctBuilding, [ecColorless], 'Units\Colorless\BigGolemTowerBuilding', 3));
CardInfoManager.AddCard('c57c13bf-c542-4dc1-8396-b69e2bb7e093', TCardInfo.Create(ctBuilding, [ecColorless], 'Units\Colorless\MeleeGolemTowerBuilding', 2));

// spells
// no spells for neutral

ScriptManager.ExposeType(TypeInfo(EnumEntityColor));
ScriptManager.ExposeType(TypeInfo(EnumArmorType));
ScriptManager.ExposeType(TypeInfo(EnumDamageType));
ScriptManager.ExposeType(TypeInfo(EnumCardType));

ScriptManager.ExposeClass(TCardInfo);

ScriptManager.ExposeConstant('SKIN_GROUP_DEFAULT', SKIN_GROUP_DEFAULT);
ScriptManager.ExposeConstant('SKIN_GROUP_CRUSADER', SKIN_GROUP_CRUSADER);
ScriptManager.ExposeConstant('SKIN_GROUP_MACHINE', SKIN_GROUP_MACHINE);
ScriptManager.ExposeConstant('SKIN_GROUP_RAINBOW', SKIN_GROUP_RAINBOW);
ScriptManager.ExposeConstant('SKIN_GROUP_SNOW', SKIN_GROUP_SNOW);
ScriptManager.ExposeConstant('SKIN_GROUP_UNDERWORLD', SKIN_GROUP_UNDERWORLD);
ScriptManager.ExposeConstant('SKIN_GROUP_WOODLANDS', SKIN_GROUP_WOODLANDS);
ScriptManager.ExposeConstant('SKIN_GROUP_WIP', SKIN_GROUP_WIP);
ScriptManager.ExposeConstant('SKIN_GROUP_PUR', SKIN_GROUP_PUR);
ScriptManager.ExposeConstant('SKIN_GROUP_INFLAMED', SKIN_GROUP_INFLAMED);
ScriptManager.ExposeConstant('SKIN_GROUP_SCILL', SKIN_GROUP_SCILL);
ScriptManager.ExposeConstant('SKIN_GROUP_TOURNAMENT', SKIN_GROUP_TOURNAMENT);
ScriptManager.ExposeConstant('SKIN_GROUP_SPRING', SKIN_GROUP_SPRING);
ScriptManager.ExposeConstant('SKIN_GROUP_SUMMER', SKIN_GROUP_SUMMER);
ScriptManager.ExposeConstant('SKIN_GROUP_STEAM', SKIN_GROUP_STEAM);
ScriptManager.ExposeConstant('SKIN_GROUP_ROFL', SKIN_GROUP_ROFL);
ScriptManager.ExposeConstant('SKIN_GROUP_POPULAR', SKIN_GROUP_POPULAR);

finalization

FreeAndNil(CardInfoManager);

end.
