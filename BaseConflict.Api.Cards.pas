unit BaseConflict.Api.Cards;

interface

uses
  // System
  System.SysUtils,
  System.DateUtils,
  System.Math,
  Generics.Collections,
  // Engine
  Engine.dXML,
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Network.RPC,
  Engine.DataQuery,
  // Game
  BaseConflict.Constants,
  BaseConflict.Constants.Cards,
  BaseConflict.Api,
  BaseConflict.Api.Types,
  BaseConflict.Api.Shared;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  {$M+}
  TCardManager = class;
  TCard = class;

  EnumRequirementType = (rtPlayerLevel, rtCardUnlocked, rtGameEvent);

  TCardRequirement = class
    private
      FID : integer;
      function GetCurrentValue : integer; virtual; abstract;
      function GetTargetValue : integer; virtual; abstract;
      procedure SetCurrentValue(const Value : integer); virtual;
    published
      function RequirementType : EnumRequirementType; virtual; abstract;
      property CurrentValue : integer read GetCurrentValue write SetCurrentValue;
      property TargetValue : integer read GetTargetValue;
      /// <summary> Value 0..1 thats indicates how progressed the requirement is fulfilled. If the value is 1, the
      /// requirement is fulfilled.</summary>
      [dXMLDependency('.CurrentValue', '.TargetValue')]
      function Progress : single;
      /// <summary> Returns True if requirement is completely fulfilled, else false.</summary>
      [dXMLDependency('.Progress')]
      function IsFulfilled : boolean;
    public
      property ID : integer read FID;
      constructor Create(Data : TApiCardRequirement);
  end;

  TCardRequirementPlayerLevel = class(TCardRequirement)
    private
      FRequiredPlayerLevel : integer;
      function GetCurrentValue : integer; override;
      function GetTargetValue : integer; override;
    published
      function RequirementType : EnumRequirementType; override;
      property RequiredPlayerLevel : integer read FRequiredPlayerLevel;
    public
      constructor Create(Data : TApiCardRequirementPlayerLevel);
  end;

  TCardRequirementCardUnlocked = class(TCardRequirement)
    private
      FRequiredCard : TCard;
      function GetCurrentValue : integer; override;
      function GetTargetValue : integer; override;
      // override it, because on unlock, requirement needs to updated
      procedure SetCurrentValue(const Value : integer); override;
    published
      function RequirementType : EnumRequirementType; override;
      property RequiredCard : TCard read FRequiredCard;
    public
      constructor Create(Data : TApiCardRequirementCardUnlocked);
  end;

  /// <summary> Baseclass for requirements with game event </summary>
  TCardRequirementGameEvent = class(TCardRequirement)
    strict private
      FUseTimes : integer;
      FGameEventIdentifier : string;
      FSingleGame : boolean;
      function GetTargetValue : integer; override;
    private
      FCurrentValue : integer;
      function GetCurrentValue : integer; override;
      procedure SetCurrentValue(const Value : integer); override;
    published
      function RequirementType : EnumRequirementType; override;
      property GameEventIdentifier : string read FGameEventIdentifier;
      property UseTimes : integer read FUseTimes;
      function EventText : string;
    public
      constructor Create(Data : TApiCardRequirementGameEvent);
  end;

  TCardSkin = class
    strict private
      FID : integer;
      FUID : string;
      FName : string;
      FUnlocked : boolean;
      procedure SetUnlocked(const Value : boolean); virtual;
    published
      /// <summary> If True, skin is unlocked by current player, else false.</summary>
      property Unlocked : boolean read FUnlocked write SetUnlocked;
    public
      property ID : integer read FID;
      property UID : string read FUID;
      /// <summary> Serverskinname. Should not be displayed directly to user, mainly for
      /// debugging.</summary>
      property name : string read FName;
      /// <summary> Returns the skinned cards meta data. </summary>
      function CardInfo : TCardInfo;
      constructor Create(const Data : RCardSkin);
  end;

  TCard = class
    private
      procedure AddRequirement(const Data : TApiCardRequirement);
    strict private
      FID : integer;
      FUID : string;
      FColors : SetEntityColor;
      FName : string;
      FStartingLeague : integer;
      FUnlocked : boolean;
      FSkins : TUltimateObjectList<TCardSkin>;
      FCardManager : TCardManager;
      function GetColorCount : integer;
    strict private
      FRequirements : TUltimateObjectList<TCardRequirement>;
      procedure SetUnlocked(const Value : boolean); virtual;
    published
      property CardManager : TCardManager read FCardManager;
      /// <summary> If True, card is unlocked by current player, else false.</summary>
      property Unlocked : boolean read FUnlocked write SetUnlocked;
      /// <summary> Starting with League the card will available and cards buyed will have this League.
      /// It is impossible that any card instance of this card with lower League exists, but it will
      /// be common that card instances will have a higher League. </summary>
      property League : integer read FStartingLeague;
      /// <summary> Requirements to unlock this card. </summary>
      property Requirements : TUltimateObjectList<TCardRequirement> read FRequirements;
      property Skins : TUltimateObjectList<TCardSkin> read FSkins;
      [dXMLDependency('.CardManager.PlayerCards')]
      function OwnCount : integer;
      /// <summary> Returns true if requirements can make progress (all unlock and level requirements are fulfilled). </summary>
      [dXMLDependency('.Requirements', '.Requirements.IsFulfilled', '.Unlocked')]
      function IsUnlockable : boolean;
    public
      /// <summary> Only client. No real server id. </summary>
      property ID : integer read FID;
      property UID : string read FUID;
      /// <summary> Servercardname. Should not be displayed directly to user, mainly for
      /// debugging.</summary>
      property name : string read FName;
      /// <summary> Colors of this card.</summary>
      property Colors : SetEntityColor read FColors;
      /// <summary> Returns the number of colors this card has.</summary>
      property ColorCount : integer read GetColorCount;
      /// <summary> Returns wheter there are any skins for this card except the default skin available. </summary>
      function HasSkins : boolean;
      /// <summary> Returns True if the card can be owned by players.</summary>
      function IsObtainableByPlayers : boolean;
      /// <summary> Returns the first color in colors. Should only used for singlecolor cards.</summary>
      function GetSingleColor : EnumEntityColor;
      /// <summary> Only for testproject.</summary>
      function GetFullName : string;
      /// <summary> Returns the cards meta data. </summary>
      function CardInfo : TCardInfo;
      constructor Create(ID : integer; const Data : RCard; CardManager : TCardManager);
      destructor Destroy; override;
  end;

  TCardInstance = class(TVersionedItem)
    private
      FCardManager : TCardManager;
      FID : integer;
      FOriginCard : TCard;
      procedure GainExperience(ExperiencePoints : integer);
    strict private
      FDisenchantValue : TUltimateList<RCost>;
      FLeague, FExperiencePoints : integer;
      FChargeLevel : integer;
      FUpgradePoints : integer;
      FCreated : TDateTime;
      FNew : boolean;
      function GetIsLeagueUpgradable : boolean;
      function GetIsMaxLevel : boolean;
      function GetLevel : integer;
      function GetLevelProgress : single;
      procedure SetExperiencePoints(const Value : integer); virtual;
      procedure SetLeague(const Value : integer); virtual;
      procedure SetChargeLevel(const Value : integer); virtual;
      procedure SetUpgradePoints(const Value : integer); virtual;
      function GetTotalUpgradePoints : integer; virtual;
      function GetUpgradeProgress : single; virtual;
      procedure SetCreated(const Value : TDateTime); virtual;
      procedure SetNew(const Value : boolean); virtual;
    published
      property Created : TDateTime read FCreated write SetCreated;
      property New : boolean read FNew write SetNew;
      /// <summary> Current League of card, while cardinstance is not max League, it can be upgraded.</summary>
      property League : integer read FLeague write SetLeague;
      /// <summary> Returns True if local requirements are fulfilled (League not max League and enough exp collected).</summary>
      [dXMLDependency('.League', '.ExperiencePoints')]
      property IsLeagueUpgradable : boolean read GetIsLeagueUpgradable;
      /// <summary> Return True if this card is already max League and so can not upgraded anymore.</summary>
      [dXMLDependency('.League')]
      function IsMaxLeague : boolean;

      /// <summary> Total experience points that are required for next league.</summary>
      [dXMLDependency('.League')]
      function TotalExperiencePointsRequiredForNextLeague : integer;
      /// <summary> The amount of experience points needed to reach next league from current point. </summary>
      [dXMLDependency('.ExperiencePoints', '.League')]
      function ExperiencePointsRequiredForNextLeague : integer;
      /// <summary> Returns the experience worth of the card, when card is sacrificed to push xp.</summary>
      function GetExperienceValue : integer;
      /// <summary> The current exp points the card has collected. The exp points will reset to 0 if
      /// a card is upgraded to next League.</summary>
      property ExperiencePoints : integer read FExperiencePoints write SetExperiencePoints;
      /// <summary> The amount of experience points needed to reach next level from current point.</summary>
      [dXMLDependency('.ExperiencePoints', '.League')]
      function ExperiencePointsRequiredForNextLevel : integer;

      /// <summary> The current level of this card. Levels are resetting at every new league. </summary>
      [dXMLDependency('.ExperiencePoints')]
      property Level : integer read GetLevel;
      /// <summary> Returns whether this card has reached the maximum level for this league. </summary>
      [dXMLDependency('.ExperiencePoints')]
      property IsMaxLevel : boolean read GetIsMaxLevel;
      /// <summary> The progress to the next level in [0.0..1.0]. </summary>
      [dXMLDependency('.ExperiencePoints')]
      property LevelProgress : single read GetLevelProgress;

      /// <summary> Upgrade points of current card. When card has total upgrade points reached, it will upgrade league.</summary>
      property CurrentUpgradePoints : integer read FUpgradePoints write SetUpgradePoints;
      [dXMLDependency('.League')]
      property TotalUpgradePoints : integer read GetTotalUpgradePoints;
      [dXMLDependency('.CurrentUpgradePoints', '.TotalUpgradePoints')]
      property UpgradeProgress : single read GetUpgradeProgress;
      /// <summary> Returns the upgrade cost of card, if payed with gold.</summary>
      [dXMLDependency('.League', '.CurrentUpgradePoints')]
      function UpgradeGoldCost : RCost;
      /// <summary> Returns the upgrade cost of card, if payed with premium.</summary>
      [dXMLDependency('.League', '.CurrentUpgradePoints')]
      function UpgradePremiumCost : RCost;
      /// <summary> Upgrade a card to next League, sacrificing cards as upgrade cost.</summary>
      procedure UpgradeCardUseGold(CardSacrifices : TArray<TCardInstance>);
      procedure UpgradeCardUsePremium(CardSacrifices : TArray<TCardInstance>);

      /// <summary> Gain experience for card by sacrificing another cards.</summary>
      procedure PushCardXPBySacrifice(CardSacrifices : TArray<TCardInstance>);
      /// <summary> Returns the summed XP of the card. </summary>
      function GetXPBySacrifice(CardSacrifices : TArray<TCardInstance>) : integer;

      /// <summary> Returns the cards meta data. </summary>
      [dXMLDependency('.League', '.ExperiencePoints')]
      function CardInfo : TCardInfo;
    public
      property ID : integer read FID write FID;
      property OriginCard : TCard read FOriginCard;
      function IsInAnyDeck : boolean;
      function UpgradePointsValue(const Target : TCardInstance) : integer;
      function ExperiencePointsValue(const Target : TCardInstance) : integer;
      /// <summary> Sets new to false. </summary>
      procedure HasBeenSeen;
      /// <summary> Load Data</summary>
      constructor Create(const Data : RCardInstance; CardManager : TCardManager; IsNew : boolean = False);
      /// <summary> Create a new instance that does not exist at the point where the instance is created.</summary>
      constructor CreateNew(OriginCard : TCard; CardManager : TCardManager);
      destructor Destroy; override;
  end;

  TCardConstants = class
    private
      FGoldCurrency : TCurrency;
      FPremiumCurrency : TCurrency;
      FMaxLeague, FLevelPerLeague : integer;
      FLeagueTable : TDictionary<integer, integer>;
      FLegendaryMultiplier : single;
      FUpgradeGoldCostTable : TDictionary<integer, integer>;
      FGoldValueTable : TDictionary<integer, integer>;
      FExperienceValueTable : TDictionary<integer, integer>;
      FMaxChargeLevel : integer;
    public
      /// <summary> Currency used to represent gold.</summary>
      property GoldCurrency : TCurrency read FGoldCurrency;
      property PremiumCurrency : TCurrency read FPremiumCurrency;
      property LegendaryMultiplier : single read FLegendaryMultiplier;
      /// <summary> League => Gold value of card.</summary>
      property GoldValueTable : TDictionary<integer, integer> read FGoldValueTable;
      /// <summary> League => Upgrade gold cost.</summary>
      property UpgradeGoldCostTable : TDictionary<integer, integer> read FUpgradeGoldCostTable;
      /// <summary> Maximum charge level a card can upgraded to.</summary>
      property MaxChargeLevel : integer read FMaxChargeLevel;
      /// <summary> Maximum League a card can upgraded to.</summary>
      property MaxLeague : integer read FMaxLeague;
      /// <summary> Sublevels which has a card between two leagues. </summary>
      property LevelPerLeague : integer read FLevelPerLeague;
      /// <summary> Experience for a card required to be upgrade to next League respectively the max experience a card can gain for
      /// current League.
      /// League => Maximum exp for League.</summary>
      property LeagueTable : TDictionary<integer, integer> read FLeagueTable;
      /// <summary> Experience a card is worth, if card would sacrificed to boost another card.
      /// League => exp</summary>
      property ExperienceValueTable : TDictionary<integer, integer> read FExperienceValueTable;
      /// <summary> Returns the current card level for given card league and experience points.</summary>
      function GetCardLevel(League, ExperiencePoints : integer) : integer;
      /// <summary> Returns a value between 0..1 describing the progress a card has made to levelup.</summary>
      function GetLevelProgress(League, ExperiencePoints : integer) : single;
      /// <summary> Returns the required xp to reach the next level.</summary>
      function GetRequiredXPToLevelUp(League, ExperiencePoints : integer) : integer;
      constructor Create(const Data : RCardConstants);
      destructor Destroy; override;
  end;

  ProcCardUnlocked = procedure(UnlockedCard : TCard) of object;

  TCardManager = class(TInterfacedObject, ICardBackchannel)
    private
      FCards : TUltimateObjectList<TCard>;
      FPlayerCards : TUltimateObjectList<TCardInstance>;
      FCardConstants : TCardConstants;
      FOnCardUnlocked : ProcCardUnlocked;
      FCardsLoaded : ProcCallback;
      procedure LoadCards(const Data : ARCard; const UnlockData : RUnlockData);
      // add all requriements to all cards
      procedure LoadCardRequirements(const Data : AApiCardRequirement; const ProgressData : ARCardRequirementProgress);
      procedure LoadPlayerCards(const Data : ARCardInstance);
      // similar to load, but do not drop data before and looking for duplicates
      procedure AddPlayerCards(const Data : ARCardInstance);
      // Backchannel
      procedure CardUnlocked(card_uid : string);
      procedure SkinUnlocked(skin_uid, card_uid : string);
      procedure CardInstanceChanged(card_instance : RCardInstance; Created : boolean);
      procedure CardUnlockProgressUpdate(requirement_id : integer; Progress : integer);
      procedure SignalCardUnlocked(UnlockedCard : TCard);
      procedure SignalCardsLoaded();
    published
      /// <summary> All cards that are currently available in game. This cards are not implicity owned by player,
      /// this is only a overview which cards are available. If a user unlocked a card, it will be displayed by
      /// unlock variable within card. If a user loot or buy a card, it will listed in playercards and NOT
      /// in this list. A card is only a pattern, which have no progress like experience points.</summary>
      property Cards : TUltimateObjectList<TCard> read FCards;
      /// <summary> All cardinstances that the player owns. A card instance is a buyed or looted card which
      /// has progress and also can sacrificed.</summary>
      property PlayerCards : TUltimateObjectList<TCardInstance> read FPlayerCards;
      /// <summary> Chose a startedeck, that will give user some cards for free and autocreate a deck containing these cards.</summary>
      procedure ChooseStarterDeck(const Choice : EnumEntityColor);
      [dXMLDependency('.PlayerCards.New')]
      function HasAnyNewCard : boolean;
    public
      /// <summary> Called if a new card is unlocked and can now buyed in shop.</summary>
      property OnCardUnlocked : ProcCardUnlocked read FOnCardUnlocked write FOnCardUnlocked;
      /// <summary> Called after the cards are fully loaded..</summary>
      property OnCardsLoaded : ProcCallback read FCardsLoaded write FCardsLoaded;
      property CardConstants : TCardConstants read FCardConstants;
      /// <summary> Sets all new flags of all cards to false. </summary>
      procedure CleanAllNewFlags;
      /// <summary> Shortcut, Returns an array of all cards that are already unlocked by player, and so can be
      /// buyed on shop.</summary>
      function GetAllUnlockedCards : TArray<TCard>;
      /// <summary> Load all data from server.</summary>
      constructor Create;
      /// <summary> Kadabumm.</summary>
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  TCardManagerAction = class(TPromiseAction)
    private
      FCardManager : TCardManager;
    public
      property CardManager : TCardManager read FCardManager;
      constructor Create(CardManager : TCardManager);
  end;

  [AQCriticalAction]
  TCardManagerActionLoadCards = class(TCardManagerAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TCardManagerActionLoadPlayerCards = class(TCardManagerAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TCardManagerActionLoadCardConstants = class(TCardManagerAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TCardManagerActionChoseStarterDeck = class(TCardManagerAction)
    private
      FServerChoice : integer;
      FChoice : EnumEntityColor;
    public
      property ServerChoice : integer read FServerChoice;
      constructor Create(Choice : EnumEntityColor; CardManager : TCardManager);
      procedure Emulate; override;
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
      procedure Rollback; override;
  end;

  TCardInstanceAction = class(TPromiseAction)
    private
      FCardInstance : TCardInstance;
    public
      property CardInstance : TCardInstance read FCardInstance;
      constructor Create(CardInstance : TCardInstance);
  end;

  [AQCriticalAction]
  TCardInstanceActionUpgradeCard = class(TCardInstanceAction)
    private
      FOldLeague, FOldExperience : integer;
      FOldUpgradePoints : integer;
      FPayedAscendCost : RCost;
      FCardSacrifices : TArray<TCardInstance>;
      FUsedCurrency : TCurrency;
    public
      constructor Create(CardInstance : TCardInstance; CardSacrifices : TArray<TCardInstance>; Currency : TCurrency);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TCardInstanceActionPushCardXPBySacrifice = class(TCardInstanceAction)
    private
      FOldExperience : integer;
      FCardSacrifices : TArray<TCardInstance>;
    public
      constructor Create(CardInstance : TCardInstance; CardSacrifices : TArray<TCardInstance>);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  CardManager : TCardManager;

implementation

uses
  BaseConflict.Api.Account,
  BaseConflict.Api.Profile,
  BaseConflict.Api.Shop,
  BaseConflict.Api.Deckbuilding;

{ TCardManagerAction }

constructor TCardManagerAction.Create(CardManager : TCardManager);
begin
  inherited Create();
  FCardManager := CardManager;
end;

{ TCard }

procedure TCard.AddRequirement(const Data : TApiCardRequirement);
begin
  if Data is TApiCardRequirementPlayerLevel then
      Requirements.Insert(0, TCardRequirementPlayerLevel.Create(Data as TApiCardRequirementPlayerLevel))
  else if Data is TApiCardRequirementCardUnlocked then
      Requirements.Insert(0, TCardRequirementCardUnlocked.Create(Data as TApiCardRequirementCardUnlocked))
  else if Data is TApiCardRequirementGameEvent then
      Requirements.Add(TCardRequirementGameEvent.Create(Data as TApiCardRequirementGameEvent))
  else
      raise EUnsupportedException.CreateFmt('TCard.AddRequirement: Could not load data for class "%s"', [Data.ClassName]);
end;

function TCard.CardInfo : TCardInfo;
begin
  Result := CardInfoManager.ResolveCardUID(UID, self.League, 1);
end;

constructor TCard.Create(ID : integer; const Data : RCard; CardManager : TCardManager);
var
  skin_data : RCardSkin;
begin
  FID := ID;
  FCardManager := CardManager;
  FUID := Data.UID;
  FName := Data.name;
  FColors := Data.Colors;
  FStartingLeague := Data.starting_tier;
  FRequirements := TUltimateObjectList<TCardRequirement>.Create();
  FSkins := TUltimateObjectList<TCardSkin>.Create();
  for skin_data in Data.Skins do
  begin
    FSkins.Add(TCardSkin.Create(skin_data));
  end;
end;

destructor TCard.Destroy;
begin
  FreeAndNil(FRequirements);
  FreeAndNil(FSkins);
  inherited;
end;

function TCard.GetColorCount : integer;
var
  Color : EnumEntityColor;
begin
  // there is no direct way to get the number of elements within set, so we need to count
  Result := 0;
  for Color in Colors do
      inc(Result);
end;

function TCard.GetFullName : string;
begin
  Result := name;
end;

function TCard.GetSingleColor : EnumEntityColor;
begin
  Result := EnumEntityColor.ecColorless;
  // we need only the first color within set
  for Result in Colors do
      break;
end;

function TCard.HasSkins : boolean;
begin
  Result := FSkins.Count > 0;
end;

function TCard.IsObtainableByPlayers : boolean;
begin
  Result := CardInfo.CardColors * [ecColorless, ecWhite, ecBlack, ecBlue, ecGreen] <> [];
  Result := Result and (not(ecColorless in CardInfo.CardColors) or CardInfo.Filename.Contains('Golems'));
end;

function TCard.IsUnlockable : boolean;
var
  i : integer;
begin
  Result := True;
  if not Unlocked then
  begin
    for i := 0 to Requirements.Count - 1 do
        Result := Result and
        (not(Requirements[i].RequirementType in [rtPlayerLevel, rtCardUnlocked]) or
        Requirements[i].IsFulfilled);
  end;
end;

function TCard.OwnCount : integer;
begin
  Result := 0;
  if assigned(CardManager) then
  begin
    Result := CardManager.PlayerCards.Query.Filter(F('OriginCard') = self).Count;
  end;
end;

procedure TCard.SetUnlocked(const Value : boolean);
begin
  FUnlocked := Value;
end;

{ TCardManager }

procedure TCardManager.AddPlayerCards(const Data : ARCardInstance);
var
  Item : RCardInstance;
begin
  for Item in Data do
  begin
    if not PlayerCards.Query.Filter(F('ID') = Item.ID).Exists then
        PlayerCards.Add(TCardInstance.Create(Item, self))
  end;
end;

procedure TCardManager.CardInstanceChanged(card_instance : RCardInstance; Created : boolean);
var
  CardInstance : TCardInstance;
begin
  CardInstance := PlayerCards.Query.Get(F('ID') = card_instance.ID, True);
  if Created and not assigned(CardInstance) then
  begin
    CardInstance := TCardInstance.Create(card_instance, self, True);
    PlayerCards.Add(CardInstance);
  end;
  if not assigned(CardInstance) then exit;
  CardInstance.IncFromServer;
  assert(CardInstance.IsServerAhead or CardInstance.IsClientAhead or
    ((CardInstance.ExperiencePoints = card_instance.experience_points) and (CardInstance.League = card_instance.tier)),
    'TCardManager.CardInstanceChanged: Backchannel sent data which were different from local state!');
  if CardInstance.IsServerAhead then
  begin
    CardInstance.ExperiencePoints := card_instance.experience_points;
    CardInstance.CurrentUpgradePoints := card_instance.ascension_progress;
    CardInstance.League := card_instance.tier;
    // client now catched up
    CardInstance.IncFromClient;
  end;
end;

procedure TCardManager.CardUnlocked(card_uid : string);
var
  Card : TCard;
  Requirement : TCardRequirement;
begin
  Card := Cards.Query.Get(F('UID') = card_uid);
  Card.Unlocked := True;
  SignalCardUnlocked(Card);

  for Card in FCards do
  begin
    Requirement := Card.Requirements.Query.Get((F('.') = TCardRequirementCardUnlocked) and (F('RequiredCard.uid') = card_uid), True);
    if assigned(Requirement) then
    begin
      assert(Requirement is TCardRequirementCardUnlocked);
      TCardRequirementGameEvent(Requirement).CurrentValue := 1;
    end;
  end;
end;

procedure TCardManager.CardUnlockProgressUpdate(requirement_id, Progress : integer);
var
  Requirement : TCardRequirement;
  Card : TCard;
begin
  Requirement := nil;
  for Card in FCards do
  begin
    Requirement := Card.Requirements.Query.Get(F('FID') = requirement_id, True);
    if assigned(Requirement) then
    begin
      assert(Requirement is TCardRequirementGameEvent);
      TCardRequirementGameEvent(Requirement).CurrentValue := Progress;
      // ID is unique, so stop searching if requirment with target id was found
      break;
    end;
  end;
  assert(assigned(Requirement));
end;

procedure TCardManager.ChooseStarterDeck(const Choice : EnumEntityColor);
begin
  // if not UserProfile.StarterDeckChosen then
  // 2 begin
  MainActionQueue.DoAction(TCardManagerActionChoseStarterDeck.Create(Choice, self));
  // end
  // else raise EUnsupportedException.Create('TCardManager.ChooseStarterDeck: Starterdeck already chosen.');
end;

procedure TCardManager.CleanAllNewFlags;
var
  i : integer;
begin
  for i := 0 to FPlayerCards.Count - 1 do
      FPlayerCards[i].HasBeenSeen;
end;

constructor TCardManager.Create;
begin
  FCards := TUltimateObjectList<TCard>.Create;
  FPlayerCards := TUltimateObjectList<TCardInstance>.Create;
  RPCHandlerManager.SubscribeHandler(self);
  MainActionQueue.DoAction(TCardManagerActionLoadCardConstants.Create(self));
  MainActionQueue.DoAction(TCardManagerActionLoadCards.Create(self));
  MainActionQueue.DoAction(TCardManagerActionLoadPlayerCards.Create(self));
end;

destructor TCardManager.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  FCards.Free;
  FPlayerCards.Free;
  FCardConstants.Free;
  inherited;
end;

function TCardManager.GetAllUnlockedCards : TArray<TCard>;
begin
  Result := Cards.Query.Filter(F('Unlocked')).ToArray;
end;

function TCardManager.HasAnyNewCard : boolean;
begin
  Result := PlayerCards.Query.Filter(F('New') = True).Exists;
end;

procedure TCardManager.LoadCardRequirements(const Data : AApiCardRequirement; const ProgressData : ARCardRequirementProgress);
var
  requirement_data : TApiCardRequirement;
  Progress : RCardRequirementProgress;
begin
  for requirement_data in Data do
      Cards.Query.Get(F('UID') = requirement_data.card_uid).AddRequirement(requirement_data);
  for Progress in ProgressData do
  begin
    Cards.Query.Get(F('UID') = Progress.card_uid)
      .Requirements.Query.Get(F('ID') = Progress.requirement_id)
      .CurrentValue := Progress.Progress;
  end;
end;

procedure TCardManager.LoadCards(const Data : ARCard; const UnlockData : RUnlockData);
var
  Card : TCard;
  Skin : TCardSkin;
  CardData : RCard;
  CardUnlock : RCardUnlock;
  SkinUnlock : RSkinUnlock;
  AddedCards : TUltimateList<TCard>;
begin
  AddedCards := TUltimateList<TCard>.Create;
  // first load all non skins
  for CardData in Data do
      AddedCards.Add(TCard.Create(AddedCards.Count, CardData, self));
  for CardUnlock in UnlockData.card_unlocks do
  begin
    Card := AddedCards.Query.Get(F('UID') = CardUnlock.card_uid);
    Card.Unlocked := True;
  end;

  for SkinUnlock in UnlockData.skin_unlocks do
  begin
    Card := AddedCards.Query.Get(F('UID') = SkinUnlock.card_uid);
    Skin := Card.Skins.Query.Get(F('ID') = SkinUnlock.skin_id);
    Skin.Unlocked := True;
  end;

  self.Cards.AddRange(AddedCards);
  AddedCards.Free;
end;

procedure TCardManager.LoadPlayerCards(const Data : ARCardInstance);
begin
  PlayerCards.Clear;
  PlayerCards.AddRange(HArray.Map<RCardInstance, TCardInstance>(Data,
    function(const Item : RCardInstance) : TCardInstance
    begin
      Result := TCardInstance.Create(Item, self)
    end));
end;

procedure TCardManager.SignalCardsLoaded;
begin
  if assigned(OnCardsLoaded) then OnCardsLoaded();
end;

procedure TCardManager.SignalCardUnlocked(UnlockedCard : TCard);
begin
  if assigned(OnCardUnlocked) then
      OnCardUnlocked(UnlockedCard);
end;

procedure TCardManager.SkinUnlocked(skin_uid, card_uid : string);
var
  Card : TCard;
begin
  Card := Cards.Query.Get(F('UID') = card_uid);
  Card.Skins.Query.Get(F('UID') = skin_uid).Unlocked := True;
end;

{ TCardInstance }

function TCardInstance.CardInfo : TCardInfo;
begin
  Result := CardInfoManager.ResolveCardUID(OriginCard.UID, self.League, self.Level);
end;

constructor TCardInstance.Create(const Data : RCardInstance; CardManager : TCardManager; IsNew : boolean);
begin
  FCardManager := CardManager;
  FID := Data.ID;
  FExperiencePoints := Data.experience_points;
  FUpgradePoints := Data.ascension_progress;
  FLeague := Data.tier;
  FOriginCard := CardManager.Cards.Query.Get(F('UID') = Data.origin_card_uid);
  FCreated := Data.Created;
  if ecWhite in FOriginCard.Colors then
      FCreated := IncSecond(FCreated, 3);
  FNew := IsNew;
end;

constructor TCardInstance.CreateNew(OriginCard : TCard; CardManager : TCardManager);
begin
  FCardManager := CardManager;
  // new card instance has no id
  FID := -1;
  FExperiencePoints := 0;
  FLeague := OriginCard.League;
  FOriginCard := OriginCard;
end;

procedure TCardInstance.GainExperience(ExperiencePoints : integer);
begin
  self.ExperiencePoints := Min(TotalExperiencePointsRequiredForNextLeague, self.ExperiencePoints + ExperiencePoints);
end;

destructor TCardInstance.Destroy;
begin
  FDisenchantValue.Free;
  inherited;
end;

function TCardInstance.ExperiencePointsRequiredForNextLeague : integer;
begin
  Result := TotalExperiencePointsRequiredForNextLeague - ExperiencePoints;
end;

function TCardInstance.ExperiencePointsRequiredForNextLevel : integer;
begin
  Result := FCardManager.CardConstants.GetRequiredXPToLevelUp(League, ExperiencePoints);
end;

function TCardInstance.ExperiencePointsValue(const Target : TCardInstance) : integer;
begin
  Result := GetExperienceValue;
end;

function TCardInstance.TotalExperiencePointsRequiredForNextLeague : integer;
begin
  Result := FCardManager.CardConstants.LeagueTable[League];
end;

function TCardInstance.GetExperienceValue : integer;
begin
  Result := FCardManager.CardConstants.ExperienceValueTable[League]
end;

function TCardInstance.GetIsLeagueUpgradable : boolean;
begin
  Result := not IsMaxLeague and (ExperiencePoints >= TotalExperiencePointsRequiredForNextLeague);
end;

function TCardInstance.GetIsMaxLevel : boolean;
begin
  Result := Level >= FCardManager.CardConstants.LevelPerLeague;
end;

function TCardInstance.GetLevel : integer;
begin
  Result := CardManager.CardConstants.GetCardLevel(League, ExperiencePoints);
end;

function TCardInstance.GetLevelProgress : single;
begin
  Result := CardManager.CardConstants.GetLevelProgress(League, ExperiencePoints);
end;

function TCardInstance.GetTotalUpgradePoints : integer;
begin
  if League = MAX_LEAGUE then
      Result := 1000000
  else
  begin
    Result := FCardManager.CardConstants.UpgradeGoldCostTable[League];
    if OriginCard.CardInfo.IsLegendary then
        Result := round(Result * FCardManager.CardConstants.LegendaryMultiplier);
  end;
end;

function TCardInstance.GetUpgradeProgress : single;
begin
  Result := TotalUpgradePoints / CurrentUpgradePoints;
end;

function TCardInstance.GetXPBySacrifice(CardSacrifices : TArray<TCardInstance>) : integer;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to length(CardSacrifices) - 1 do
      Result := Result + CardSacrifices[i].GetExperienceValue;
end;

procedure TCardInstance.HasBeenSeen;
begin
  self.New := False;
end;

function TCardInstance.UpgradeGoldCost : RCost;
begin
  Result.Amount := -1;
  Result.Currency := FCardManager.CardConstants.GoldCurrency;
  if IsMaxLeague then exit;

  Result.Amount := FCardManager.CardConstants.UpgradeGoldCostTable[League];
  if OriginCard.CardInfo.IsLegendary then
      Result.Amount := round(Result.Amount * FCardManager.CardConstants.LegendaryMultiplier);
  Result.Amount := Result.Amount - CurrentUpgradePoints;
end;

function TCardInstance.UpgradePointsValue(const Target : TCardInstance) : integer;
begin
  Result := FCardManager.CardConstants.GoldValueTable[League];
  if CardInfo.IsLegendary then
      Result := round(Result * FCardManager.CardConstants.LegendaryMultiplier);
end;

function TCardInstance.UpgradePremiumCost : RCost;
begin
  Result := UpgradeGoldCost;
  Result.Currency := FCardManager.CardConstants.PremiumCurrency;
  Result.Amount := Result.Amount div 4;
end;

function TCardInstance.IsInAnyDeck : boolean;
begin
  Result := Deckbuilding.IsCardInAnyDeck(self);
end;

function TCardInstance.IsMaxLeague : boolean;
begin
  // ToDo Remove Crystal League Block
  Result := (League >= FCardManager.CardConstants.MaxLeague) or (League >= MAX_LEAGUE - 1);
end;

procedure TCardInstance.PushCardXPBySacrifice(CardSacrifices : TArray<TCardInstance>);
begin
  if ExperiencePointsRequiredForNextLeague > 0 then
  begin
    MainActionQueue.DoAction(TCardInstanceActionPushCardXPBySacrifice.Create(self, CardSacrifices));
  end
  else
      raise Exception.Create('TCardInstance.PushCardXPBySacrifice: Card already maximum Level, can''t push the experience points.');

end;

procedure TCardInstance.SetChargeLevel(const Value : integer);
begin
  FChargeLevel := Value;
end;

procedure TCardInstance.SetCreated(const Value : TDateTime);
begin
  FCreated := Value;
end;

procedure TCardInstance.SetExperiencePoints(const Value : integer);
begin
  FExperiencePoints := Value;
end;

procedure TCardInstance.SetLeague(const Value : integer);
begin
  FLeague := Value;
end;

procedure TCardInstance.SetNew(const Value : boolean);
begin
  FNew := Value;
end;

procedure TCardInstance.SetUpgradePoints(const Value : integer);
begin
  FUpgradePoints := Value;
end;

procedure TCardInstance.UpgradeCardUseGold(CardSacrifices : TArray<TCardInstance>);
begin
  if League < FCardManager.CardConstants.MaxLeague then
  begin
    MainActionQueue.DoAction(TCardInstanceActionUpgradeCard.Create(self, CardSacrifices, CardManager.CardConstants.GoldCurrency));
  end
  else
      raise Exception.Create('TCardInstance.UpgradeCard: Card already maximum League, can''t upgrade it to next League.');
end;

procedure TCardInstance.UpgradeCardUsePremium(CardSacrifices : TArray<TCardInstance>);
begin
  if League < FCardManager.CardConstants.MaxLeague then
  begin
    MainActionQueue.DoAction(TCardInstanceActionUpgradeCard.Create(self, CardSacrifices, CardManager.CardConstants.PremiumCurrency));
  end
  else
      raise Exception.Create('TCardInstance.UpgradeCard: Card already maximum League, can''t upgrade it to next League.');
end;

{ TCardManagerActionLoadPlayerCards }

function TCardManagerActionLoadPlayerCards.Execute : boolean;
var
  promise : TPromise<ARCardInstance>;
begin
  promise := CardApi.GetPlayerCards;
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        CardManager.LoadPlayerCards(promise.Value);
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TCardManagerActionLoadPlayerCards.Rollback;
begin
  CardManager.PlayerCards.Clear;
end;

{ TCardManagerActionLoadCards }

function TCardManagerActionLoadCards.Execute : boolean;
var
  promiseCards : TPromise<ARCard>;
  promiseUnlocks : TPromise<RUnlockData>;
  promiseRequirements : TPromise<AApiCardRequirement>;
  promiseRequirementProgress : TPromise<ARCardRequirementProgress>;
begin
  promiseCards := CardApi.GetAllCards;
  promiseUnlocks := CardApi.GetAllUnlocks;
  promiseRequirements := CardApi.GetCardRequirements;
  promiseRequirementProgress := CardApi.GetCardRequirementProgress;
  promiseCards.WaitForData;
  promiseUnlocks.WaitForData;
  promiseRequirements.WaitForData;
  promiseRequirementProgress.WaitForData;
  if TPromise.CheckPromisesWereSuccessfull([promiseCards, promiseRequirements,
    promiseUnlocks, promiseRequirementProgress], FErrorMsg) then
  begin
    DoSynchronized(
      procedure()
      begin
        CardManager.LoadCards(promiseCards.Value, promiseUnlocks.Value);
        CardManager.LoadCardRequirements(promiseRequirements.Value, promiseRequirementProgress.Value);
        CardManager.SignalCardsLoaded;
        // because nobody else will free the objects
        HArray.FreeAllObjects<TApiCardRequirement>(promiseRequirements.Value);
      end);
    Result := True;
  end
  else
      Result := False;
  promiseCards.Free;
  promiseUnlocks.Free;
  promiseRequirements.Free;
  promiseRequirementProgress.Free;
end;

procedure TCardManagerActionLoadCards.Rollback;
begin
  CardManager.Cards.Clear;
end;

{ TCardRequirement }

function TCardRequirement.Progress : single;
begin
  Result := EnsureRange(CurrentValue / TargetValue, 0.0, 1.0);
end;

procedure TCardRequirement.SetCurrentValue(const Value : integer);
begin
  // will not implemented, because only used by some requirements
  raise ENotImplemented.Create('TCardRequirement.SetCurrentValue');
end;

constructor TCardRequirement.Create(Data : TApiCardRequirement);
begin
  FID := Data.ID;
end;

function TCardRequirement.IsFulfilled : boolean;
begin
  Result := Progress >= 1;
end;

{ TCardRequirementPlayerLevel }

constructor TCardRequirementPlayerLevel.Create(Data : TApiCardRequirementPlayerLevel);
begin
  inherited Create(Data);
  FRequiredPlayerLevel := Data.minimum_player_level;
end;

function TCardRequirementPlayerLevel.GetCurrentValue : integer;
begin
  Result := UserProfile.Level;
end;

function TCardRequirementPlayerLevel.GetTargetValue : integer;
begin
  Result := RequiredPlayerLevel;
end;

function TCardRequirementPlayerLevel.RequirementType : EnumRequirementType;
begin
  Result := rtPlayerLevel;
end;

{ TCardRequirementCardUnlocked }

constructor TCardRequirementCardUnlocked.Create(Data : TApiCardRequirementCardUnlocked);
begin
  inherited Create(Data);
  FRequiredCard := CardManager.Cards.Query.Get(F('UID') = Data.require_card_unlocked_uid);
end;

function TCardRequirementCardUnlocked.GetCurrentValue : integer;
begin
  if RequiredCard.Unlocked then
      Result := 1
  else
      Result := 0;
end;

function TCardRequirementCardUnlocked.GetTargetValue : integer;
begin
  Result := 1;
end;

function TCardRequirementCardUnlocked.RequirementType : EnumRequirementType;
begin
  Result := rtCardUnlocked;
end;

procedure TCardRequirementCardUnlocked.SetCurrentValue(const Value : integer);
begin
  // only exists to trigger get
end;

{ TCardConstants }

constructor TCardConstants.Create(const Data : RCardConstants);
var
  Entry : RApiTableEntry;
begin
  FMaxLeague := Data.card_max_tier;
  FLevelPerLeague := Data.card_level_per_tier;
  FLegendaryMultiplier := Data.card_gold_legendary_multiplier;
  FGoldCurrency := CurrencyManager.GetCurrencyByUID(Data.gold_currency_uid);
  FPremiumCurrency := CurrencyManager.GetCurrencyByUID(Data.premium_currency_uid);
  FUpgradeGoldCostTable := TDictionary<integer, integer>.Create();
  for Entry in Data.card_upgrade_gold_cost do
      FUpgradeGoldCostTable.Add(Entry.key, Entry.Value);
  FGoldValueTable := TDictionary<integer, integer>.Create();
  for Entry in Data.card_gold_value_table do
      FGoldValueTable.Add(Entry.key, Entry.Value);
  FLeagueTable := TDictionary<integer, integer>.Create();
  for Entry in Data.card_level_table do
      FLeagueTable.Add(Entry.key, Entry.Value);
  FExperienceValueTable := TDictionary<integer, integer>.Create();
  for Entry in Data.card_experience_value_table do
      FExperienceValueTable.Add(Entry.key, Entry.Value);
end;

destructor TCardConstants.Destroy;
begin
  FUpgradeGoldCostTable.Free;
  FGoldValueTable.Free;
  FLeagueTable.Free;
  FExperienceValueTable.Free;
  inherited;
end;

function TCardConstants.GetCardLevel(League, ExperiencePoints : integer) : integer;
begin
  Result := EnsureRange(Trunc(ExperiencePoints / LeagueTable[League] * (LevelPerLeague - 1)), 0, LevelPerLeague - 1) + 1;
end;

function TCardConstants.GetLevelProgress(League, ExperiencePoints : integer) : single;
begin
  // sepcial: if max level, progress is 100% (normally it would be 0%, because a new level is reached)
  if GetCardLevel(League, ExperiencePoints) = LevelPerLeague then
      Result := 1
  else
      Result := Frac(ExperiencePoints / LeagueTable[League] * (LevelPerLeague - 1));
end;

function TCardConstants.GetRequiredXPToLevelUp(League, ExperiencePoints : integer) : integer;
begin
  if (ExperiencePoints >= LeagueTable[League]) then exit(0);
  Result := (LeagueTable[League] div (LevelPerLeague - 1)); // XP per level
  Result := Result - (ExperiencePoints mod Result); // remove already done level from CardXP and take step to next level
end;

{ TCardManagerActionLoadCardConstants }

function TCardManagerActionLoadCardConstants.Execute : boolean;
var
  promise : TPromise<RCardConstants>;
begin
  promise := CardApi.GetCardConstants;
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        CardManager.FCardConstants := TCardConstants.Create(promise.Value);
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TCardManagerActionLoadCardConstants.Rollback;
begin
  FreeAndNil(CardManager.FCardConstants);
end;

{ TCardInstanceAction }

constructor TCardInstanceAction.Create(CardInstance : TCardInstance);
begin
  inherited Create;
  FCardInstance := CardInstance;
end;

{ TCardInstanceActionUpgradeCard }

constructor TCardInstanceActionUpgradeCard.Create(CardInstance : TCardInstance; CardSacrifices : TArray<TCardInstance>; Currency : TCurrency);
begin
  inherited Create(CardInstance);
  FCardSacrifices := CardSacrifices;
  FUsedCurrency := Currency;
end;

procedure TCardInstanceActionUpgradeCard.Emulate;
var
  CardSacrifice : TCardInstance;
begin
  FOldExperience := CardInstance.ExperiencePoints;
  FOldUpgradePoints := CardInstance.CurrentUpgradePoints;
  FOldLeague := CardInstance.League;
  // remove all cards that are sacrificed to upgrade card
  for CardSacrifice in FCardSacrifices do
  begin
    CardInstance.CurrentUpgradePoints := Min(CardInstance.CurrentUpgradePoints + CardSacrifice.UpgradePointsValue(CardInstance), CardInstance.TotalUpgradePoints);
    CardManager.PlayerCards.Extract(CardSacrifice);
  end;
  FPayedAscendCost.Currency := FUsedCurrency;
  if FUsedCurrency = CardManager.CardConstants.GoldCurrency then
      FPayedAscendCost.Amount := CardInstance.TotalUpgradePoints - CardInstance.CurrentUpgradePoints
  else if FUsedCurrency = CardManager.CardConstants.PremiumCurrency then
      FPayedAscendCost.Amount := (CardInstance.TotalUpgradePoints - CardInstance.CurrentUpgradePoints) div 4
  else
      assert(False);
  Shop.PayCosts([FPayedAscendCost]);
  CardInstance.League := Min(CardInstance.FCardManager.CardConstants.MaxLeague, CardInstance.League + 1);
  CardInstance.CurrentUpgradePoints := 0;
  CardInstance.ExperiencePoints := 0;
  CardInstance.FCardManager.PlayerCards.SignalItemChanged(CardInstance);
  CardInstance.IncFromClient;
end;

function TCardInstanceActionUpgradeCard.Execute : boolean;
var
  CardSacrificeIds : TArray<integer>;
begin
  CardSacrificeIds := TDelphiDataQuery<TCardInstance>.CreateInterface(FCardSacrifices).ValuesAsInteger('ID');
  Result := HandlePromise(CardApi.UpgradeCardInstance(CardInstance.FID, CardSacrificeIds, FUsedCurrency = CardManager.CardConstants.PremiumCurrency));
  if Result then
      HArray.FreeAllObjects<TCardInstance>(FCardSacrifices);
end;

procedure TCardInstanceActionUpgradeCard.Rollback;
var
  CardSacrifice : TCardInstance;
begin
  CardInstance.League := FOldLeague;
  CardInstance.CurrentUpgradePoints := FOldUpgradePoints;
  CardInstance.ExperiencePoints := FOldExperience;
  CardInstance.FCardManager.PlayerCards.SignalItemChanged(CardInstance);
  CardInstance.DecFromClient;
  Shop.RollbackPayedCosts([FPayedAscendCost]);
  for CardSacrifice in FCardSacrifices do
  begin
    CardManager.PlayerCards.Add(CardSacrifice);
  end;
end;

{ TCardRequirementGameEvent }

constructor TCardRequirementGameEvent.Create(Data : TApiCardRequirementGameEvent);
begin
  inherited Create(Data);
  FSingleGame := Data.single_game;
  FUseTimes := Data.use_times;
  FGameEventIdentifier := Data.game_event_identifier;
end;

function TCardRequirementGameEvent.EventText : string;
  procedure Split(const Identifier : string; out Prefix, Value : string);
  var
    i : integer;
  begin
    Prefix := '';
    Value := '';
    for i := 0 to length(GAME_STATISTIC_EVENTS) - 1 do
      if Identifier.StartsWith(GAME_STATISTIC_EVENTS[i]) then
      begin
        Prefix := GAME_STATISTIC_EVENTS[i];
        Value := Identifier.Replace(GAME_STATISTIC_EVENTS[i], '');
      end;
  end;

var
  Prefix, Value, KeyPrefix : string;
begin
  KeyPrefix := '§card_requirement_event_';
  if FSingleGame then KeyPrefix := KeyPrefix + 'single_';

  Split(GameEventIdentifier, Prefix, Value);
  if Prefix <> '' then
  begin
    // resolve passed value
    if Prefix.StartsWith('unit') or (Prefix = GSE_CARD_PLAY_PREFIX) then
        Value := _('§card_name_' + Value.Replace(FILE_IDENTIFIER_GOLEMS.ToLowerInvariant, ''))
    else if Prefix.StartsWith('wela') then
        Value := _('§unitability_name_' + Value);

    // first try as is, for individual events
    if _(KeyPrefix + GameEventIdentifier, [UseTimes, Value], Result) or
      _(KeyPrefix + GameEventIdentifier, [UseTimes], Result) or
      _(KeyPrefix + GameEventIdentifier, Result) then
        exit;

    // try generic form of event
    if _(KeyPrefix + Prefix, [UseTimes, Value], Result) or
      _(KeyPrefix + Prefix, [UseTimes], Result) or
      _(KeyPrefix + Prefix, Result) then
        exit;

    Result := KeyPrefix + GameEventIdentifier;
  end
  else
  begin
    // try complete custom event
    if _(KeyPrefix + GameEventIdentifier, [UseTimes], Result) or
      _(KeyPrefix + GameEventIdentifier, Result) then
        exit;

    Result := KeyPrefix + GameEventIdentifier;
  end;
end;

function TCardRequirementGameEvent.GetCurrentValue : integer;
begin
  Result := FCurrentValue;
end;

function TCardRequirementGameEvent.GetTargetValue : integer;
begin
  Result := UseTimes;
end;

function TCardRequirementGameEvent.RequirementType : EnumRequirementType;
begin
  Result := rtGameEvent;
end;

procedure TCardRequirementGameEvent.SetCurrentValue(const Value : integer);
begin
  FCurrentValue := Value;
end;

{ TCardManagerActionChoseStarterDeck }

constructor TCardManagerActionChoseStarterDeck.Create(Choice : EnumEntityColor; CardManager : TCardManager);
begin
  inherited Create(CardManager);
  FChoice := Choice;
  case Choice of
    ecWhite : FServerChoice := 0;
    ecGreen : FServerChoice := 1;
    ecBlack : FServerChoice := 2;
  else raise EUnsupportedException.Create('TCardManager.ChooseStarterDeck: Invalid startdeck choice.');
  end;
end;

procedure TCardManagerActionChoseStarterDeck.Emulate;
begin
end;

function TCardManagerActionChoseStarterDeck.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := ShopApi.ChooseStarterDeck(ServerChoice);
  promise.WaitForData;
  if not promise.WasSuccessful then
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

function TCardManagerActionChoseStarterDeck.ExecuteSynchronized : boolean;
begin
  Result := True;
  UserProfile.TutorialPlayed := True;
end;

procedure TCardManagerActionChoseStarterDeck.Rollback;
begin
  UserProfile.TutorialPlayed := False;
end;

{ TCardInstanceActionPushCardXPBySacrifice }

constructor TCardInstanceActionPushCardXPBySacrifice.Create(CardInstance : TCardInstance; CardSacrifices : TArray<TCardInstance>);
begin
  inherited Create(CardInstance);
  FCardSacrifices := CardSacrifices;
end;

procedure TCardInstanceActionPushCardXPBySacrifice.Emulate;
var
  CardSacrifice : TCardInstance;
  TotalExperience : integer;
begin
  FOldExperience := CardInstance.ExperiencePoints;
  TotalExperience := 0;
  // collect experience and sacrifice card
  for CardSacrifice in FCardSacrifices do
  begin
    TotalExperience := TotalExperience + CardSacrifice.GetExperienceValue;
  end;
  CardManager.PlayerCards.ExtractRange(FCardSacrifices);
  CardInstance.GainExperience(TotalExperience);
  CardInstance.FCardManager.PlayerCards.SignalItemChanged(CardInstance);
  CardInstance.IncFromClient;
end;

function TCardInstanceActionPushCardXPBySacrifice.Execute : boolean;
var
  CardSacrificeIds : TArray<integer>;
begin
  CardSacrificeIds := TDelphiDataQuery<TCardInstance>.CreateInterface(FCardSacrifices).ValuesAsInteger('ID');
  Result := HandlePromise(CardApi.PushCardInstanceExperienceBySacrifice(CardInstance.FID, CardSacrificeIds));
  if Result then
      HArray.FreeAllObjects<TCardInstance>(FCardSacrifices);
end;

procedure TCardInstanceActionPushCardXPBySacrifice.Rollback;
var
  CardSacrifice : TCardInstance;
begin
  CardInstance.ExperiencePoints := FOldExperience;
  CardInstance.FCardManager.PlayerCards.SignalItemChanged(CardInstance);
  CardInstance.DecFromClient;
  for CardSacrifice in FCardSacrifices do
  begin
    CardManager.PlayerCards.Add(CardSacrifice);
  end;
end;

{ TCardSkin }

function TCardSkin.CardInfo : TCardInfo;
begin
  Result := CardInfoManager.ResolveCardUID(UID, MAX_LEAGUE, MAX_LEVEL);
end;

constructor TCardSkin.Create(const Data : RCardSkin);
begin
  FID := Data.ID;
  FName := Data.name;
  FUID := Data.UID;
end;

procedure TCardSkin.SetUnlocked(const Value : boolean);
begin
  FUnlocked := Value;
end;

end.
