unit BaseConflict.Api.Shop;

interface

uses
  // System
  System.SysUtils,
  System.Math,
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections,
  // 3rd party
  steam_api,
  steamtypes,
  isteamuser_,
  isteamapps_,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Network.RPC,
  Engine.DataQuery,
  Engine.Serializer.JSON,
  Engine.GUI,
  Engine.dXML,
  Engine.Math,
  // Game
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Client,
  BaseConflict.Api,
  BaseConflict.Api.Types,
  BaseConflict.Api.Shared,
  BaseConflict.Api.Cards;

const
  CURRENCY_GOLD     = 'currency_gold';
  CURRENCY_DIAMONDS = 'currency_diamonds';
  CURRENCY_FREE_XP  = 'currency_free_exp';

type

  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic, vcPrivate]) FIELDS([vcPublic, vcProtected]) PROPERTIES([vcPublic, vcPublished])}
  {$M+}
  EnumShopCategory = (scCards, scCurrency, scCredits, scDiamonds, scPremiumTime, scIcons, scBonuscode, scBundles, scSkins, scBooster);
  SetShopCategory = set of EnumShopCategory;

  EnumDefaultCurrency = (dcGold, dcDiamonds, dcFreeXP);

  TShop = class;
  TShopItem = class;
  TInventoryItem = class;
  TLootbox = class;
  TDraftbox = class;
  TLootboxContent = class;

  /// <summary> There maybe some more shopoffers on serverside, but on clientside only shopoffers that are currently active
  /// will be displayed.</summary>
  TShopItemOffer = class
    private
      FID : integer;
      FShopItem : TShopItem;
      /// <summary> Inidicates if offer is for real money of ingame money.</summary>
      FRealMoney, FHasHardCurrency : boolean;
      procedure EmulateBuy(const Amount : integer);
      procedure RollbackBuy(const Amount : integer);
    strict private
      FCosts : TUltimateList<RCost>;
    published
      property Costs : TUltimateList<RCost> read FCosts;
      /// <summary> Returns True, if this offer can be payed with the current amount of currency the
      /// player owns.</summary>
      [dXMLDependency('shop.Shop.Balances.Balance')]
      function IsPayable : boolean;
      [dXMLDependency('shop.Shop.Balances.Balance')]
      function IsPayableTimes10 : boolean;
      /// <summary> True if costs contain any diamonds. </summary>
      property HasHardCurrency : boolean read FHasHardCurrency;
    public
      /// <summary> The owning shop item. </summary>
      property ShopItem : TShopItem read FShopItem;
      property RealMoney : boolean read FRealMoney;
      /// <summary> Only valid if real money is true. </summary>
      function RealMoneyString : string;
      /// <summary> Buy offer and spend currency to pay cost. Will automatically add items (e.g. currency or cards)
      /// to profile. Will buy item linked to offer amount times.</summary>
      procedure Buy(Amount : integer);
      function IsPayableTimes(Times : integer) : boolean;
      function BalanceAfterPurchase : TArray<RCost>;
      constructor Create(ShopItem : TShopItem; const Data : ROffer);
      destructor Destroy; override;
  end;

  EnumShopItemType = (
    itInvalid,
    itPremiumTime,
    itSkin,
    itCard,
    itDraftbox,
    itLootbox,
    itIcon,
    itDeckSlot,
    itLootList,
    itCredits,
    itDiamonds,
    itCurrency,
    itPlayerXP,
    itRandomCard,
    itDisenchantedCard);

  TShopItem = class abstract
    private
      FName : string;
      FID : integer;
      FShop : TShop;
      FPurchasesCount : integer;
      FPurchasesLimitedTo : integer;
      FTimeToBuy : integer;
      /// <summary> Emulates the impact of buying this shophitem count times.
      /// Data returned is saved by action and passed to another methods (execute or rollback) on call.</summary>
      function EmulateBuy(Count : integer) : TObject; virtual; abstract;
      /// <summary> After successful call, maybe data has to applied on emulated data.</summary>
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); virtual; abstract;
      /// <summary> Rollback buy when failed.</summary>
      procedure RollbackBuy(const AObject : TObject; Count : integer); virtual; abstract;
      function GetCategories : SetShopCategory; virtual; abstract;
      function GetDisplayName : string; virtual;
      procedure SetPurchasesCount(const Value : integer); virtual;
    strict private
      FOffers : TUltimateObjectList<TShopItemOffer>;
    published
      property Offers : TUltimateObjectList<TShopItemOffer> read FOffers;
      property PurchasesCount : integer read FPurchasesCount write SetPurchasesCount;
      property PurchasesLimitedTo : integer read FPurchasesLimitedTo;
      property TimeToBuy : integer read FTimeToBuy;
      [dXMLDependency('.PurchasesCount', '.PurchasesLimitedTo')]
      function MaxPurchasesReached : boolean; virtual;
    public
      property ID : integer read FID;
      property name : string read FName;
      property DisplayName : string read GetDisplayName;
      property Categories : SetShopCategory read GetCategories;
      function IsTimeLimited : boolean;
      function PurchasableBySoftcurrency : boolean; virtual;
      function ItemType : EnumShopItemType; virtual;
      function CostOrderValue(CurrencyUID : string) : integer;
      /// <summary> Returns whether an item should be displayed within shop. </summary>
      function IsVisible : boolean; virtual;
      constructor Create(Shop : TShop; Data : TApiShopItem);
      destructor Destroy; override;
  end;

  TShopItemBuyCardInstance = class(TShopItem)
    private
      FCard : TCard;
      FLeague : integer;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    published
      /// <summary> Target card which player will buy a instance.</summary>
      property Card : TCard read FCard;
    public
      function CardInfo : TCardInfo;
      function League : integer;
      [dXMLDependency('.Card.Unlocked')]
      function PurchasableBySoftcurrency : boolean; override;
      function IsVisible : boolean; override;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemBuyCard);
  end;

  TShopItemUnlockSkin = class(TShopItem)
    private
      FSkin : TCardSkin;
      FCard : TCard;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    published
      property Skin : TCardSkin read FSkin;
      property Card : TCard read FCard;
      [dXMLDependency('.Skin.Unlocked')]
      function MaxPurchasesReached : boolean; override;
    public
      function CardInfo : TCardInfo;
      function League : integer;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemUnlockSkin);
  end;

  TShopItemRandomUnlockedCard = class(TShopItem)
    private
      FLeague : integer;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    public
      property League : integer read FLeague;
      function IsVisible : boolean; override;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemRandomCard);
  end;

  TShopItemBuyCurrency = class(TShopItem)
    private
      FCurrency : TCurrency;
      FAmount : integer;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
      function GetDisplayName : string; override;
    public
      property Currency : TCurrency read FCurrency;
      property Amount : integer read FAmount;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemBuyCurrency);
  end;

  TShopItemGainPlayerExperience = class(TShopItem)
    private
      FAmount : integer;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    public
      property Amount : integer read FAmount;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemGainPlayerExperience);
  end;

  TShopItemLootbox = class(TShopItem)
    private
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    public
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemLootbox);
  end;

  TShopItemDraftbox = class(TShopItem)
    private
      FLeague : integer;
      FTypeIdentifier : string;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    published
      property TypeIdentifier : string read FTypeIdentifier;
    public
      function IsCardBox : boolean;
      function IsSkinBox : boolean;
      property League : integer read FLeague;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemDraftbox);
  end;

  TShopItemUnlockIcon = class(TShopItem)
    private
      FIconIdentifier : string;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    public
      property Icon : string read FIconIdentifier;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemUnlockIcon);
  end;

  TShopItemPremiumAccount = class(TShopItem)
    private
      FDays : integer;
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    public
      property Days : integer read FDays;
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemPremiumAccount);
  end;

  TShopItemDeckSlot = class(TShopItem)
    private
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    public
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemDeckSlot);
  end;

  TShopItemLootList = class(TShopItem)
    private
      function GetCategories : SetShopCategory; override;
      function EmulateBuy(Count : integer) : TObject; override;
      procedure ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer); override;
      procedure RollbackBuy(const AObject : TObject; Count : integer); override;
    public
      function ItemType : EnumShopItemType; override;
      constructor Create(Shop : TShop; Data : TApiShopItemLootList);
  end;

  /// <summary> Describes the current balance for an currency the player owns.</summary>
  TBalance = class(TVersionedItem)
    strict private
      FBalance : integer;
      FCurrency : TCurrency;
      procedure SetBalance(const Value : integer); virtual;
    private
      // update balance from serverdata and return True if balance has changed
      // else false
      function UpdateBalance(balance_data : RBalance) : boolean;
      // update balance using clientdata
      procedure ChargeBalance(BalanceDifference : integer);
      // rollback the charge of balance
      procedure RollbackChargeBalance(BalanceDifference : integer);
    published
      property Balance : integer read FBalance write SetBalance;
      property Currency : TCurrency read FCurrency;
    public
      constructor Create(Balance : integer; Currency : TCurrency);
  end;

  EnumTransactionState = (tsNone, tsProcessing, tsSuccessful, tsAborted, tsFailed);

  /// <summary> Observing steam for changed dlc ownership and inform shop, if new dlc was installed.</summary>
  TShopDLCObserverThread = class(TThread)
    private const
      POLLING_RATE = 1000;
    strict private
      FNotOwnedDLCList : TList<AppId_t>;
      FTimer : TTimer;
    protected
      procedure Execute; override;
    public
      constructor Create;
      destructor Destroy; override;
  end;

  RReward = record
    ShopItem : TShopItem;
    Amount : integer;
  end;

  ARReward = TArray<RReward>;

  ProcRewardGained = procedure(Rewards : TArray<RReward>) of object;

  TShop = class(TInterfacedObject, IShop, ILoot)
    private
      FLastRealMoneyTransactionState : EnumTransactionState;
      FOnInventoryLoaded : ProcOfObject;
      FOnRewardGained : ProcRewardGained;
      FObserverThread : TShopDLCObserverThread;
      FPlayerCurrencyCode : string;
      procedure LoadBalance(const Data : RBalanceData);
      procedure LoadShopItems(const Data : ATApiShopItem; const PurchaseData : ARShopPurchase);
      procedure LoadInventory(const DraftData : ARDraftBox; const LootData : ARLootbox);
      procedure ChargeAccount(Costs : array of RCost; Sign : integer; Rollback : boolean);
      /// <summary> Will called by steamapi when player gets DLC ownership and install it.</summary>
      procedure SteamDLCInstalledCallback(const Data : DlcInstalled_t);
      // backchannels
      procedure BalanceUpdate(balance_data : RBalance);
      procedure NewDraftBox(draftbox_data : RDraftBox);
    strict private
      FItems : TUltimateObjectList<TShopItem>;
      FBalances : TUltimateObjectList<TBalance>;
      FInventory : TUltimateObjectList<TInventoryItem>;
    published
      property PlayerCurrencyCode : string read FPlayerCurrencyCode;
      property Balances : TUltimateObjectList<TBalance> read FBalances;
      property Items : TUltimateObjectList<TShopItem> read FItems;
      property Inventory : TUltimateObjectList<TInventoryItem> read FInventory;
    public
      property OnInventoryLoaded : ProcOfObject read FOnInventoryLoaded write FOnInventoryLoaded;
      property OnRewardGained : ProcRewardGained read FOnRewardGained write FOnRewardGained;
      property LastRealMoneyTransactionState : EnumTransactionState read FLastRealMoneyTransactionState;

      [dXMLDependency('.Balances')]
      function Balance(const Currency : EnumDefaultCurrency) : TBalance;
      [dXMLDependency('.Balances')]
      function BalanceByUID(const CurrencyUID : string) : TBalance;
      [dXMLDependency('.Balances')]
      function BalanceByCurrency(const Currency : TCurrency) : TBalance;

      [dXMLDependency('.Balances')]
      function CanPayCosts(Costs : TUltimateList<RCost>) : boolean;
      /// <summary> Charge account by subtract the costs from accounts. This will only applied locally
      /// and is not submitted to server.</summary>
      procedure PayCosts(Costs : array of RCost);
      /// <summary> Charge account by adding the costs to account. Only locally. Method is used
      /// for rollback payed costs.</summary>
      procedure RollbackPayedCosts(Costs : array of RCost);
      /// <summary> Charge account by give player some money.</summary>
      procedure CreditCurrency(CreditItems : array of RCost);
      /// <summary> Take them the money away.</summary>
      procedure RollbackCreditCurrency(CreditItems : array of RCost);
      procedure CallRewardGained(Rewards : TArray<RReward>); overload;
      procedure CallRewardGained(Rewards : TArray<TLootboxContent>); overload;

      procedure RedeemKeycode(const Key : string);
      function ResolveShopItemByID(const ID : integer) : TShopItem;
      function TryResolveShopItemByID(const ID : integer; out ShopItem : TShopItem) : boolean;
      function ResolveShopItemByName(const Name : string) : TShopItem;
      function TryResolveShopItemByName(const Name : string; out ShopItem : TShopItem) : boolean;
      function ResolveShopItemBuyCardInstance(const Card : TCard) : TShopItemBuyCardInstance;
      function TryResolveShopItemBuyCardInstance(const Card : TCard; out ShopItem : TShopItemBuyCardInstance) : boolean;

      constructor Create;
      destructor Destroy; override;
  end;

  TInventoryItem = class
    // + Level
    private const
      LID_LEVEL_REWARD = 'player_level_reward_box_';
    strict private
      FOpened : boolean;
      procedure SetOpened(const Value : boolean); virtual;
    protected
      FID : integer;
      FTypeIdentifier : string;
    published
      property Opened : boolean read FOpened write SetOpened;
      property TypeIdentifier : string read FTypeIdentifier;
    public
      /// <summary> Returns whether this box is the reward to reach a certain level. </summary>
      function IsLevelReward : boolean;
      /// <summary> Returns the level which was this box rewarded for. Only valid in conjunction with IsLevelReward, otherwise returns -1.</summary>
      function RewardForPlayerLevel : integer;
  end;

  TLootboxContent = class
    strict protected
      FShopItem : TShopItem;
      FAmount : integer;
    published
      /// <summary> The shopitem the player will receive from lootbox.</summary>
      property ShopItem : TShopItem read FShopItem;
      /// <summary> The amount of shopitems the player will receive from lootbox.</summary>
      property Amount : integer read FAmount;
    public
      constructor Create(ShopItem : TShopItem; Amount : integer);
  end;

  TLootbox = class(TInventoryItem)
    private
      FContent : TUltimateObjectList<TLootboxContent>;
    published
      property Content : TUltimateObjectList<TLootboxContent> read FContent;
      procedure OpenAndReceiveLoot;
    public
      constructor Create(Data : RLootbox);
      destructor Destroy; override;
  end;

  TLootList = class
    private
      FLoot : TUltimateObjectList<TLootboxContent>;
    published
      property Content : TUltimateObjectList<TLootboxContent> read FLoot;
    public
      constructor Create(Data : RLootList);
      destructor Destroy; override;
  end;

  TDraftBoxChoice = class(TLootboxContent)
    strict private
      FChoiceID : integer;
    public
      property ChoiceID : integer read FChoiceID;
      constructor Create(ShopItem : TShopItem; Amount : integer; ChoiceID : integer);
  end;

  TDraftbox = class(TInventoryItem)
    private
      FLeague : integer;
      FChoices : TUltimateObjectList<TDraftBoxChoice>;
    published
      property Choices : TUltimateObjectList<TDraftBoxChoice> read FChoices;
      procedure DraftItem(Item : TDraftBoxChoice);
    public
      function IsCardBox : boolean;
      function IsSkinBox : boolean;
      property League : integer read FLeague;
      constructor Create(Data : RDraftBox);
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  TShopAction = class(TPromiseAction)
    private
      FShop : TShop;
    public
      property Shop : TShop read FShop;
      constructor Create(Shop : TShop);
  end;

  [AQCriticalAction]
  TShopActionLoadBalance = class(TShopAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TShopActionLoadShopItems = class(TShopAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TShopActionLoadInventory = class(TShopAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TShopItemOfferActionBuy = class(TPromiseAction)
    private
      FOffer : TShopItemOffer;
      FAmount : integer;
      FEmulatedData : TObject;
    public
      property Offer : TShopItemOffer read FOffer;
      property Amount : integer read FAmount;
      property EmulatedData : TObject read FEmulatedData;
      constructor Create(Offer : TShopItemOffer; Amount : integer);
      procedure Emulate; override;
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TShopItemOfferActionBuyForRealMoney = class(TShopItemOfferActionBuy)
    private
      FBuyAuthorized : integer;
      FOrderID : UInt64;
      procedure SteamMicroTxnAuthorizationResponseCallback(const Data : MicroTxnAuthorizationResponse_t);
    public
      procedure Emulate; override;
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TLootboxActionOpen = class(TPromiseAction)
    private
      FLootbox : TLootbox;
    public
      constructor Create(Lootbox : TLootbox);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TDraftBoxActionDraftItem = class(TPromiseAction)
    private
      FDraftBox : TDraftbox;
      FChoiceID : integer;
    public
      property DraftBox : TDraftbox read FDraftBox;
      constructor Create(DraftBox : TDraftbox; ChoiceID : integer);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TShopActionUpdateDLCOwnership = class(TPromiseAction)
    public
      function Execute : boolean; override;
  end;

  [AQCriticalAction]
  TShopActionRedeemKeycode = class(TPromiseAction)
    private
      FKeycode : string;
    public
      constructor Create(const Keycode : string);
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
  end;

  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  Shop : TShop;

const
  DLC_SYSTEM_ENABLED = False;

implementation

uses
  {$IF not defined(MAPEDITOR)}
  BaseConflictMainUnit,
  {$ENDIF}
  BaseConflict.Globals.Client,
  BaseConflict.Classes.Gamestates.GUI,
  BaseConflict.Api.Profile;

{ TShopOffer }

function TShopItemOffer.BalanceAfterPurchase : TArray<RCost>;
var
  i : integer;
begin
  setLength(Result, FCosts.Count);
  for i := 0 to FCosts.Count - 1 do
  begin
    Result[i].Currency := FCosts[i].Currency;
    Result[i].Amount := Shop.BalanceByCurrency(FCosts[i].Currency).Balance - FCosts[i].Amount;
  end;
end;

procedure TShopItemOffer.Buy(Amount : integer);
begin
  if IsPayable then
  begin
    if FRealMoney then
        MainActionQueue.DoAction(TShopItemOfferActionBuyForRealMoney.Create(self, Amount))
    else MainActionQueue.DoAction(TShopItemOfferActionBuy.Create(self, Amount));
  end;
end;

constructor TShopItemOffer.Create(ShopItem : TShopItem; const Data : ROffer);
var
  cost_data : RCostRaw;
begin
  FCosts := TUltimateList<RCost>.Create();
  FShopItem := ShopItem;
  FID := Data.ID;
  FRealMoney := Data.real_money;
  for cost_data in Data.Costs do
  begin
    FCosts.Add(RCost.Create(cost_data.Amount, CurrencyManager.GetCurrencyByUID(cost_data.currency_uid)));
    if FCosts.Last.Currency.UID = CURRENCY_DIAMONDS then FHasHardCurrency := True;
  end;
end;

destructor TShopItemOffer.Destroy;
begin
  FCosts.Free;
  inherited;
end;

procedure TShopItemOffer.EmulateBuy(const Amount : integer);
begin
  FShopItem.FShop.PayCosts(Costs.ToArray);
end;

function TShopItemOffer.IsPayable : boolean;
begin
  Result := IsPayableTimes(1);
end;

function TShopItemOffer.IsPayableTimes(Times : integer) : boolean;
var
  cost : RCost;
begin
  if FRealMoney then
      Result := True
  else
  begin
    Result := True;
    for cost in FCosts do
    begin
      Result := Result and (FShopItem.FShop.BalanceByUID(cost.Currency.UID).Balance >= cost.Amount * Times);
    end;
  end;
end;

function TShopItemOffer.IsPayableTimes10 : boolean;
begin
  Result := IsPayableTimes(10);
end;

function TShopItemOffer.RealMoneyString : string;
begin
  if RealMoney and not Costs.IsEmpty then
  begin
    Result := Inttostr(Costs[0].Amount div 100) + FormatSettings.DecimalSeparator + Inttostr(Costs[0].Amount mod 100);
    if Costs[0].Currency.UID = 'EUR' then Result := Result + ' €'
    else if Costs[0].Currency.UID = 'GBP' then Result := '£' + Result
    else if Costs[0].Currency.UID = 'USD' then Result := '$' + Result
    else if Costs[0].Currency.UID = 'BRL' then Result := 'R$' + Result
    else if Costs[0].Currency.UID = 'RUB' then Result := '₽ ' + Result
    else if Costs[0].Currency.UID = 'PLN' then Result := Result + ' zł'
    else Result := '? ' + Result;
  end
  else Result := '';
end;

procedure TShopItemOffer.RollbackBuy(const Amount : integer);
begin
  FShopItem.FShop.RollbackPayedCosts(Costs.ToArray);
end;

{ TShopItem }

function TShopItem.CostOrderValue(CurrencyUID : string) : integer;
var
  i, j : integer;
begin
  Result := MaxInt;
  for i := 0 to Offers.Count - 1 do
    for j := 0 to Offers[i].Costs.Count - 1 do
      if Offers[i].Costs[j].Currency.UID = CurrencyUID then
          Result := Min(Result, Offers[i].Costs[j].Amount);
end;

constructor TShopItem.Create(Shop : TShop; Data : TApiShopItem);
var
  offer_data, offer_data_copy : ROffer;
  DefaultCost, cost : RCostRaw;
  CostQuery : IDataQuery<RCostRaw>;
begin
  FOffers := TUltimateObjectList<TShopItemOffer>.Create();
  FShop := Shop;
  FName := Data.Name;
  FID := Data.ID;
  FPurchasesLimitedTo := Data.purchases_limited_to;
  FTimeToBuy := Data.time_to_buy;
  Data.Offers := HArray.Sort<ROffer>(Data.Offers,
    function(const L, R : ROffer) : integer
    begin
      if (length(L.Costs) > 0) and (length(R.Costs) > 0) then
          Result := -CompareStr(L.Costs[0].currency_uid, R.Costs[0].currency_uid)
      else
          Result := L.ID - R.ID;
    end);
  for offer_data in Data.Offers do
  begin
    if offer_data.real_money then
    begin
      offer_data_copy := offer_data;
      CostQuery := TDelphiDataQuery<RCostRaw>.CreateInterface(offer_data.Costs);
      DefaultCost := CostQuery.Get(F('currency_uid') = 'USD');
      if CostQuery.TryGet(F('currency_uid') = Shop.PlayerCurrencyCode, cost) then
          offer_data_copy.Costs := [cost]
      else
          offer_data_copy.Costs := [DefaultCost];
      FOffers.Add(TShopItemOffer.Create(self, offer_data_copy))
    end
    else
        FOffers.Add(TShopItemOffer.Create(self, offer_data))
  end;
end;

destructor TShopItem.Destroy;
begin
  FOffers.Free;
  inherited;
end;

function TShopItem.GetDisplayName : string;
begin
  Result := Format('%s', [HInternationalizer.TranslateTextRecursive('§shop_item_name_' + name)]);;
end;

function TShopItem.IsTimeLimited : boolean;
begin
  Result := FTimeToBuy >= 0;
end;

function TShopItem.IsVisible : boolean;
begin
  // only show items which have offers for
  Result := Offers.Count > 0;
end;

function TShopItem.ItemType : EnumShopItemType;
begin
  Result := itInvalid;
end;

function TShopItem.MaxPurchasesReached : boolean;
begin
  Result := (PurchasesLimitedTo > 0) and (PurchasesCount >= PurchasesLimitedTo);
end;

function TShopItem.PurchasableBySoftcurrency : boolean;
begin
  Result := True;
end;

procedure TShopItem.SetPurchasesCount(const Value : integer);
begin
  FPurchasesCount := Value;
end;

{ TShop }

function TShop.Balance(const Currency : EnumDefaultCurrency) : TBalance;
begin
  case Currency of
    dcGold : Result := BalanceByUID(CURRENCY_GOLD);
    dcDiamonds : Result := BalanceByUID(CURRENCY_DIAMONDS);
    dcFreeXP : Result := BalanceByUID(CURRENCY_FREE_XP);
  else
    raise ENotImplemented.Create('TShop.Balance: Missing implementation of default currency ' + HRtti.EnumerationToString<EnumDefaultCurrency>(Currency));
  end;
end;

function TShop.BalanceByCurrency(const Currency : TCurrency) : TBalance;
begin
  Result := FBalances.Query.Get(F('Currency') = Currency);
end;

function TShop.BalanceByUID(const CurrencyUID : string) : TBalance;
begin
  Result := FBalances.Query.Get(F('Currency.UID') = CurrencyUID, True);
end;

procedure TShop.BalanceUpdate(balance_data : RBalance);
var
  Balance : TBalance;
begin
  Balance := Balances.Query.Get(F('Currency.UID') = balance_data.currency_uid);
  if Balance.UpdateBalance(balance_data) then
      Balances.SignalItemChanged(Balance);
end;

procedure TShop.CallRewardGained(Rewards : TArray<RReward>);
begin
  if assigned(OnRewardGained) and (length(Rewards) > 0) then
      OnRewardGained(Rewards);
end;

procedure TShop.CallRewardGained(Rewards : TArray<TLootboxContent>);
var
  RawRewards : TArray<RReward>;
  i : integer;
begin
  setLength(RawRewards, length(Rewards));
  for i := 0 to length(Rewards) - 1 do
  begin
    RawRewards[i].ShopItem := Rewards[i].ShopItem;
    RawRewards[i].Amount := Rewards[i].Amount;
  end;
  RawRewards := HArray.Filter<RReward>(RawRewards,
    function(const Value : RReward) : boolean
    begin
      Result := Value.ShopItem.IsVisible or (Value.ShopItem.ItemType <> itCurrency);
    end);
  RawRewards := HArray.Sort<RReward>(RawRewards,
    function(const L, R : RReward) : integer
    begin
      Result := -(ord(L.ShopItem.IsVisible) - ord(R.ShopItem.IsVisible));
      if Result = 0 then
          Result := L.ShopItem.ID - R.ShopItem.ID;
    end);
  CallRewardGained(RawRewards);
end;

function TShop.CanPayCosts(Costs : TUltimateList<RCost>) : boolean;
var
  i : integer;
begin
  Result := True;
  if not assigned(Costs) then exit;
  for i := 0 to Costs.Count - 1 do
      Result := Result and (Costs[i].Amount <= BalanceByCurrency(Costs[i].Currency).Balance)
end;

procedure TShop.ChargeAccount(Costs : array of RCost; Sign : integer; Rollback : boolean);
var
  cost : RCost;
  Balance : TBalance;
begin
  for cost in Costs do
  begin
    Balance := self.BalanceByCurrency(cost.Currency);
    if not Rollback then
        Balance.ChargeBalance(cost.Amount * Sign)
    else
        Balance.RollbackChargeBalance(cost.Amount * Sign);
    Balances.SignalItemChanged(Balance);
  end;
end;

procedure TShop.PayCosts(Costs : array of RCost);
begin
  ChargeAccount(Costs, -1, False);
end;

constructor TShop.Create;
begin
  FItems := TUltimateObjectList<TShopItem>.Create;
  FBalances := TUltimateObjectList<TBalance>.Create();
  FInventory := TUltimateObjectList<TInventoryItem>.Create();
  RPCHandlerManager.SubscribeHandler(self);
  {$IFDEF STEAM}
  if DLC_SYSTEM_ENABLED then
      FObserverThread := TShopDLCObserverThread.Create;
  {$ENDIF}
  MainActionQueue.DoAction(TShopActionLoadBalance.Create(self));
  MainActionQueue.DoAction(TShopActionLoadShopItems.Create(self));
  MainActionQueue.DoAction(TShopActionLoadInventory.Create(self));
end;

procedure TShop.CreditCurrency(CreditItems : array of RCost);
begin
  ChargeAccount(CreditItems, +1, False);
end;

destructor TShop.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  FObserverThread.Free;
  FInventory.Free;
  FItems.Free;
  FBalances.Free;
  inherited;
end;

procedure TShop.RedeemKeycode(const Key : string);
begin
  MainActionQueue.DoAction(TShopActionRedeemKeycode.Create(Key));
end;

procedure TShop.RollbackCreditCurrency(CreditItems : array of RCost);
begin
  ChargeAccount(CreditItems, +1, True);
end;

procedure TShop.RollbackPayedCosts(Costs : array of RCost);
begin
  ChargeAccount(Costs, -1, True);
end;

procedure TShop.SteamDLCInstalledCallback(const Data : DlcInstalled_t);
begin
  noop;
end;

function TShop.ResolveShopItemBuyCardInstance(const Card : TCard) : TShopItemBuyCardInstance;
begin
  if not TryResolveShopItemBuyCardInstance(Card, Result) then
      Result := nil;
end;

function TShop.ResolveShopItemByID(const ID : integer) : TShopItem;
begin
  if not TryResolveShopItemByID(ID, Result) then
      raise ENotFoundException.CreateFmt('TShop.ResolveShopItemByID: Did not found shopitem with id %d!', [ID]);
end;

function TShop.ResolveShopItemByName(const Name : string) : TShopItem;
begin
  if not TryResolveShopItemByName(name, Result) then
      raise ENotFoundException.CreateFmt('TShop.ResolveShopItemByName: Did not found shopitem with name %s!', [name]);
end;

function TShop.TryResolveShopItemBuyCardInstance(const Card : TCard; out ShopItem : TShopItemBuyCardInstance) : boolean;
var
  Item : TShopItem;
begin
  Item := Shop.Items.Query.Get((F('ItemType') = RQuery.From<EnumShopItemType>(itCard)) and F('IsVisible') and (F('Card') = Card), True);
  if assigned(Item) then
  begin
    Result := True;
    ShopItem := Item as TShopItemBuyCardInstance;
  end
  else
      Result := False;
end;

function TShop.TryResolveShopItemByID(const ID : integer; out ShopItem : TShopItem) : boolean;
var
  Item : TShopItem;
begin
  Item := Shop.Items.Query.Get(F('ID') = ID, True);
  if assigned(Item) then
  begin
    Result := True;
    ShopItem := Item;
  end
  else
      Result := False;
end;

function TShop.TryResolveShopItemByName(const Name : string; out ShopItem : TShopItem) : boolean;
var
  Item : TShopItem;
begin
  Item := Shop.Items.Query.Get(F('Name') = name, True);
  if assigned(Item) then
  begin
    Result := True;
    ShopItem := Item;
  end
  else
      Result := False;
end;

procedure TShop.LoadBalance(const Data : RBalanceData);
var
  balance_data : RBalance;
  AddedBalances : TList<TBalance>;
begin
  AddedBalances := TList<TBalance>.Create;
  FPlayerCurrencyCode := Data.player_currency;
  for balance_data in Data.Balances do
  begin
    AddedBalances.Add(TBalance.Create(balance_data.Balance, CurrencyManager.GetCurrencyByUID(balance_data.currency_uid)));
  end;
  FBalances.AddRange(AddedBalances);
  AddedBalances.Free;
end;

procedure TShop.LoadInventory(const DraftData : ARDraftBox; const LootData : ARLootbox);
var
  LootboxData : RLootbox;
  DraftBoxData : RDraftBox;
  InventoryList : TList<TInventoryItem>;
begin
  Inventory.Clear;
  InventoryList := TList<TInventoryItem>.Create;
  for DraftBoxData in DraftData do
      InventoryList.Add(TDraftbox.Create(DraftBoxData));
  for LootboxData in LootData do
      InventoryList.Add(TLootbox.Create(LootboxData));
  Inventory.AddRange(InventoryList);
  InventoryList.Free;
  if assigned(OnInventoryLoaded) then OnInventoryLoaded();
end;

procedure TShop.LoadShopItems(const Data : ATApiShopItem; const PurchaseData : ARShopPurchase);
var
  ShopItem : TShopItem;
  ShopItemData : TApiShopItem;
  AddedShopItems : TList<TShopItem>;
  PurchaseCountQuery : IDataQuery<RShopPurchase>;
  PurchaseCount : RShopPurchase;
begin
  PurchaseCountQuery := TDelphiDataQuery<RShopPurchase>.CreateInterface(PurchaseData);
  AddedShopItems := TList<TShopItem>.Create;
  for ShopItemData in Data do
  begin
    // disenchanted card inherits from unlock card and so must before it
    if ShopItemData is TApiShopItemUnlockSkin then
        AddedShopItems.Add(TShopItemUnlockSkin.Create(self, ShopItemData as TApiShopItemUnlockSkin))
    else if ShopItemData is TApiShopItemBuyCard then
        AddedShopItems.Add(TShopItemBuyCardInstance.Create(self, ShopItemData as TApiShopItemBuyCard))
    else if ShopItemData is TApiShopItemRandomCard then
        AddedShopItems.Add(TShopItemRandomUnlockedCard.Create(self, ShopItemData as TApiShopItemRandomCard))
    else if ShopItemData is TApiShopItemBuyCurrency then
        AddedShopItems.Add(TShopItemBuyCurrency.Create(self, ShopItemData as TApiShopItemBuyCurrency))
    else if ShopItemData is TApiShopItemGainPlayerExperience then
        AddedShopItems.Add(TShopItemGainPlayerExperience.Create(self, ShopItemData as TApiShopItemGainPlayerExperience))
    else if ShopItemData is TApiShopItemLootbox then
        AddedShopItems.Add(TShopItemLootbox.Create(self, ShopItemData as TApiShopItemLootbox))
    else if ShopItemData is TApiShopItemDraftbox then
        AddedShopItems.Add(TShopItemDraftbox.Create(self, ShopItemData as TApiShopItemDraftbox))
    else if ShopItemData is TApiShopItemUnlockIcon then
        AddedShopItems.Add(TShopItemUnlockIcon.Create(self, ShopItemData as TApiShopItemUnlockIcon))
    else if ShopItemData is TApiShopItemPremiumAccount then
        AddedShopItems.Add(TShopItemPremiumAccount.Create(self, ShopItemData as TApiShopItemPremiumAccount))
    else if ShopItemData is TApiShopItemDeckSlot then
        AddedShopItems.Add(TShopItemDeckSlot.Create(self, ShopItemData as TApiShopItemDeckSlot))
    else if ShopItemData is TApiShopItemLootList then
        AddedShopItems.Add(TShopItemLootList.Create(self, ShopItemData as TApiShopItemLootList))
    else
        raise EUnsupportedException.CreateFmt('TShop.LoadShopItem: Could not load data for class "%s"', [ShopItemData.ClassName]);
    ShopItem := AddedShopItems.Last;
    if PurchaseCountQuery.TryGet(F('shopitem_id') = ShopItem.ID, PurchaseCount) then
        ShopItem.PurchasesCount := PurchaseCount.Count;
  end;
  Items.AddRange(AddedShopItems);
  AddedShopItems.Free;
end;

procedure TShop.NewDraftBox(draftbox_data : RDraftBox);
begin
  if not Inventory.Query.Filter(F('FID') = draftbox_data.ID).exists() then
  begin
    Inventory.Add(TDraftbox.Create(draftbox_data));
  end;
end;

{ TBalance }

procedure TBalance.ChargeBalance(BalanceDifference : integer);
begin
  Balance := Balance + BalanceDifference;
  IncFromClient;
end;

constructor TBalance.Create(Balance : integer; Currency : TCurrency);
begin
  FBalance := Balance;
  FCurrency := Currency;
end;

procedure TBalance.RollbackChargeBalance(BalanceDifference : integer);
begin
  Balance := Balance - BalanceDifference;
  DecFromClient;
end;

procedure TBalance.SetBalance(const Value : integer);
begin
  FBalance := Value;
end;

function TBalance.UpdateBalance(balance_data : RBalance) : boolean;
begin
  IncFromServer;
  if IsServerAhead then
  begin
    Balance := balance_data.Balance;
    IncFromClient;
    Result := True;
  end
  else if IsClientAhead then
  begin
    Result := False;
  end
  else
  begin
    Balance := balance_data.Balance;
    Result := True;
  end;
end;

{ TShopAction }

constructor TShopAction.Create(Shop : TShop);
begin
  inherited Create;
  FShop := Shop;
end;

{ TShopActionLoadShopItems }

function TShopActionLoadShopItems.Execute : boolean;
var
  promise : TPromise<ATApiShopItem>;
  promisePurchases : TPromise<ARShopPurchase>;
begin
  promise := ShopApi.GetShopItems;
  promisePurchases := ShopApi.GetShopPurchasesCount;
  promise.WaitForData;
  promisePurchases.WaitForData;
  if TPromise.CheckPromisesWereSuccessfull([promise, promisePurchases], FErrorMsg) then
  begin
    Result := True;
    DoSynchronized(
      procedure()
      begin
        FShop.LoadShopItems(promise.Value, promisePurchases.Value);
        HArray.FreeAllObjects<TApiShopItem>(promise.Value);
      end);
  end
  else
      Result := False;
  promise.Free;
  promisePurchases.Free;
end;

procedure TShopActionLoadShopItems.Rollback;
begin
  FShop.Items.Clear;
end;

{ TShopActionLoadBalance }

function TShopActionLoadBalance.Execute : boolean;
var
  promise : TPromise<RBalanceData>;
begin
  promise := ShopApi.GetBalance;
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        FShop.LoadBalance(promise.Value);
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TShopActionLoadBalance.Rollback;
begin
  FShop.Balances.Clear;
end;

{ TShopItemBuyCardInstance }

function TShopItemBuyCardInstance.CardInfo : TCardInfo;
begin
  Result := CardInfoManager.ResolveCardUID(Card.UID, self.League, 1);
end;

constructor TShopItemBuyCardInstance.Create(Shop : TShop; Data : TApiShopItemBuyCard);
begin
  inherited Create(Shop, Data);
  FCard := CardManager.Cards.Query.Get(F('UID') = Data.card_uid);
  FLeague := Data.card_tier;
end;

function TShopItemBuyCardInstance.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
end;

procedure TShopItemBuyCardInstance.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
  // comes via backchannel
end;

function TShopItemBuyCardInstance.GetCategories : SetShopCategory;
begin
  Result := [scCards];
end;

function TShopItemBuyCardInstance.IsVisible : boolean;
begin
  // we now show all cards, but disable soft currency offers
  Result := inherited; // and Card.Unlocked
end;

function TShopItemBuyCardInstance.ItemType : EnumShopItemType;
begin
  Result := itCard;
end;

function TShopItemBuyCardInstance.League : integer;
begin
  Result := Max(Card.League, self.FLeague);
end;

function TShopItemBuyCardInstance.PurchasableBySoftcurrency : boolean;
begin
  Result := Card.Unlocked;
end;

procedure TShopItemBuyCardInstance.RollbackBuy(const AObject : TObject; Count : integer);
begin
end;

{ TShopItemBuyCurrency }

constructor TShopItemBuyCurrency.Create(Shop : TShop; Data : TApiShopItemBuyCurrency);
begin
  inherited Create(Shop, Data);
  FCurrency := CurrencyManager.GetCurrencyByUID(Data.currency_uid);
  FAmount := Data.Amount;
end;

function TShopItemBuyCurrency.EmulateBuy(Count : integer) : TObject;
var
  cost : TObjectWrapper<RCost>;
begin
  cost := TObjectWrapper<RCost>.Create(RCost.Create(Amount * Count, Currency));
  Shop.CreditCurrency([cost.Value]);
  Result := cost;
end;

procedure TShopItemBuyCurrency.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
  // only clean up
  AObject.Free;
end;

function TShopItemBuyCurrency.GetCategories : SetShopCategory;
begin
  if Currency.UID = CURRENCY_DIAMONDS then
      Result := [scDiamonds]
  else if Currency.UID = CURRENCY_GOLD then
      Result := [scCredits]
  else
      Result := [scCurrency];
end;

function TShopItemBuyCurrency.GetDisplayName : string;
begin
  Result := HInternationalizer.TranslateTextRecursive(Format('%s (%dx %s)', ['§shop_item_name_' + name, Amount, Currency.Name]));
end;

function TShopItemBuyCurrency.ItemType : EnumShopItemType;
begin
  if Currency.UID = CURRENCY_DIAMONDS then
      Result := itDiamonds
  else if Currency.UID = CURRENCY_GOLD then
      Result := itCredits
  else
      Result := itCurrency;
end;

procedure TShopItemBuyCurrency.RollbackBuy(const AObject : TObject; Count : integer);
begin
  Shop.RollbackCreditCurrency([TObjectWrapper<RCost>(AObject).Value]);
  AObject.Free;
end;

{ TShopItemOfferActionBuy }

constructor TShopItemOfferActionBuy.Create(Offer : TShopItemOffer; Amount : integer);
begin
  inherited Create();
  FOffer := Offer;
  FAmount := Amount;
end;

procedure TShopItemOfferActionBuy.Emulate;
begin
  Offer.EmulateBuy(Amount);
  FEmulatedData := Offer.FShopItem.EmulateBuy(Amount);
end;

function TShopItemOfferActionBuy.Execute : boolean;
var
  promise : TPromise<TJSONData>;
  JsonData : TJSONData;
begin
  promise := ShopApi.BuyOffer(Offer.FID, Amount);
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    JsonData := promise.Value;
    Offer.FShopItem.ExecuteBuy(EmulatedData, JsonData, Amount);
    JsonData.Free;
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

function TShopItemOfferActionBuy.ExecuteSynchronized : boolean;
begin
  Result := True;
  Offer.ShopItem.PurchasesCount := Offer.ShopItem.PurchasesCount + 1;
end;

procedure TShopItemOfferActionBuy.Rollback;
begin
  Offer.RollbackBuy(Amount);
  Offer.FShopItem.RollbackBuy(FEmulatedData, Amount);
end;

{ TShopItemOfferActionBuyForRealMoney }

procedure TShopItemOfferActionBuyForRealMoney.Emulate;
begin
  // do nothing, because through steam overlay and steam microtransactions we have to wait for server response
  Shop.FLastRealMoneyTransactionState := tsProcessing;
end;

function TShopItemOfferActionBuyForRealMoney.Execute : boolean;
var
  promise : TPromise<boolean>;
  finalizePromise : TPromise<TJSONData>;
  JsonData : TJSONData;
  Timer : TTimer;
begin
  if SteamUtils.IsOverlayEnabled then
  begin
    // player has up to 10 minutes to pay
    Timer := TTimer.CreateAndStart(10 * 60 * 1000);
    FBuyAuthorized := -1;
    finalizePromise := nil;
    HSteamAPI<MicroTxnAuthorizationResponse_t>.RegisterCallback(SteamMicroTxnAuthorizationResponseCallback);
    promise := ShopApi.BuyOfferForRealMoney(Offer.FID, Amount, Offer.FShopItem.DisplayName);
    promise.WaitForData;
    if promise.WasSuccessful then
    begin
      while (FBuyAuthorized = -1) and not Timer.Expired do
      begin
        sleep(10);
      end;
      finalizePromise := ShopApi.FinalizeInGamePurchase(FOrderID, FBuyAuthorized);
      finalizePromise.WaitForData;
      if finalizePromise.WasSuccessful then
      begin
        JsonData := finalizePromise.Value;
        if (FBuyAuthorized = 1) then
        begin
          // currently backchannel has to unlock the stuff
        end;
        JsonData.Free;
      end
      else
          HandlePromiseError(finalizePromise);
    end
    else
        HandlePromiseError(promise);
    HSteamAPI<MicroTxnAuthorizationResponse_t>.UnregisterCallback(SteamMicroTxnAuthorizationResponseCallback);
    Result := promise.WasSuccessful and (FBuyAuthorized >= 0) and finalizePromise.WasSuccessful;
    finalizePromise.Free;
    promise.Free;
    Timer.Free;
  end
  else
  begin
    FErrorMsg := Inttostr(13);
    Result := False;
  end;
end;

function TShopItemOfferActionBuyForRealMoney.ExecuteSynchronized : boolean;
begin
  Result := True;
  if FBuyAuthorized < 0 then Shop.FLastRealMoneyTransactionState := tsFailed
  else if FBuyAuthorized = 0 then Shop.FLastRealMoneyTransactionState := tsAborted
  else
  begin
    Shop.FLastRealMoneyTransactionState := tsSuccessful;
    Offer.ShopItem.PurchasesCount := Offer.ShopItem.PurchasesCount + 1;
  end;
end;

procedure TShopItemOfferActionBuyForRealMoney.Rollback;
begin
  Shop.FLastRealMoneyTransactionState := tsFailed;
end;

procedure TShopItemOfferActionBuyForRealMoney.SteamMicroTxnAuthorizationResponseCallback(const Data : MicroTxnAuthorizationResponse_t);
begin
  assert(Data.m_unAppID = SteamAppID);
  FOrderID := Data.m_ulOrderID;
  FBuyAuthorized := Data.m_bAuthorized;
end;

{ TLootbox }

constructor TLootbox.Create(Data : RLootbox);
var
  Content_Data : RLootboxContent;
begin
  FID := Data.ID;
  Opened := Data.Opened;
  FTypeIdentifier := Data.type_identifier;
  FContent := TUltimateObjectList<TLootboxContent>.Create(
    TComparer<TLootboxContent>.Construct(
    function(const L, R : TLootboxContent) : integer
    begin
      Result := ord(L.ShopItem.ItemType) - ord(R.ShopItem.ItemType);
    end
    ));
  for Content_Data in Data.Content do
  begin
    FContent.Add(TLootboxContent.Create(Shop.ResolveShopItemByID(Content_Data.shopitem_id), Content_Data.shopitem_count));
  end;
  FContent.Sort;
end;

destructor TLootbox.Destroy;
begin
  FContent.Free;
  inherited;
end;

procedure TLootbox.OpenAndReceiveLoot;
begin
  MainActionQueue.DoAction(TLootboxActionOpen.Create(self));
end;

{ TLootboxContent }

constructor TLootboxContent.Create(ShopItem : TShopItem; Amount : integer);
begin
  FShopItem := ShopItem;
  FAmount := Amount;
end;

{ TLootboxOpenAction }

constructor TLootboxActionOpen.Create(Lootbox : TLootbox);
begin
  inherited Create;
  FLootbox := Lootbox;
end;

procedure TLootboxActionOpen.Emulate;
begin
  FLootbox.Opened := True;
end;

function TLootboxActionOpen.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := LootApi.OpenLootbox(FLootbox.FID);
  // currently nothing todo, because backchannels will do the unlock
  Result := self.HandlePromise(promise);
end;

procedure TLootboxActionOpen.Rollback;
begin
  FLootbox.Opened := False;
end;

{ TShopItemGainPlayerExperience }

constructor TShopItemGainPlayerExperience.Create(Shop : TShop; Data : TApiShopItemGainPlayerExperience);
begin
  inherited Create(Shop, Data);
  FAmount := Data.Amount;
end;

function TShopItemGainPlayerExperience.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
  // no emulating supported
end;

procedure TShopItemGainPlayerExperience.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
  DoSynchronized(
    procedure()
    begin
      UserProfile.GainExperience(Amount * Count);
    end);
end;

function TShopItemGainPlayerExperience.GetCategories : SetShopCategory;
begin
  Result := [scCurrency];
end;

function TShopItemGainPlayerExperience.ItemType : EnumShopItemType;
begin
  Result := itPlayerXP;
end;

procedure TShopItemGainPlayerExperience.RollbackBuy(const AObject : TObject; Count : integer);
begin
  // no emulating supported
end;

{ TShopItemLootbox }

constructor TShopItemLootbox.Create(Shop : TShop; Data : TApiShopItemLootbox);
begin
  inherited Create(Shop, Data);
end;

function TShopItemLootbox.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
  // no emulating supported
end;

procedure TShopItemLootbox.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
  assert(Data.IsArray);
  // add all lootboxes to inventory that are created from buy
  DoSynchronized(
    procedure()
    var
      LootboxData : RLootbox;
    begin
      for LootboxData in Data.AsType<ARLootbox> do
      begin
        Shop.Inventory.Add(TLootbox.Create(LootboxData));
      end;
    end);
end;

function TShopItemLootbox.GetCategories : SetShopCategory;
begin
  Result := [scBooster];
end;

function TShopItemLootbox.ItemType : EnumShopItemType;
begin
  Result := itLootbox;
end;

procedure TShopItemLootbox.RollbackBuy(const AObject : TObject; Count : integer);
begin
  // no emulating supported
end;

{ TShopActionLoadInventoryContent }

function TShopActionLoadInventory.Execute : boolean;
var
  promiseDraftboxes : TPromise<ARDraftBox>;
  promiseLootboxes : TPromise<ARLootbox>;
begin
  promiseDraftboxes := ShopApi.GetInventoryDraftboxes;
  promiseLootboxes := ShopApi.GetInventoryLootboxes;
  promiseDraftboxes.WaitForData;
  promiseLootboxes.WaitForData;
  if promiseDraftboxes.WasSuccessful and promiseLootboxes.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        FShop.LoadInventory(promiseDraftboxes.Value, promiseLootboxes.Value);
      end);
  end
  else
  begin
    if not promiseDraftboxes.WasSuccessful then
        HandlePromiseError(promiseDraftboxes)
    else
        HandlePromiseError(promiseLootboxes);
  end;
  Result := promiseDraftboxes.WasSuccessful and promiseLootboxes.WasSuccessful;
  promiseDraftboxes.Free;
  promiseLootboxes.Free;
end;

procedure TShopActionLoadInventory.Rollback;
begin
  inherited;
  FShop.Inventory.Clear;
end;

{ TLootList }

constructor TLootList.Create(Data : RLootList);
var
  ContentData : RLootboxContent;
  ShopItem : TShopItem;
begin
  FLoot := TUltimateObjectList<TLootboxContent>.Create(
    TComparer<TLootboxContent>.Construct(
    function(const L, R : TLootboxContent) : integer
    begin
      Result := ord(L.ShopItem.ItemType) - ord(R.ShopItem.ItemType);
    end
    ));
  for ContentData in Data.loot do
    if Shop.TryResolveShopItemByID(ContentData.shopitem_id, ShopItem) then
    begin
      FLoot.Add(TLootboxContent.Create(ShopItem, ContentData.shopitem_count));
    end;
  FLoot.Sort;
end;

destructor TLootList.Destroy;
begin
  FLoot.Free;
end;

{ TShopItemRandomUnlockedCard }

constructor TShopItemRandomUnlockedCard.Create(Shop : TShop; Data : TApiShopItemRandomCard);
begin
  inherited Create(Shop, Data);
  FLeague := Data.card_tier;
end;

function TShopItemRandomUnlockedCard.EmulateBuy(Count : integer) : TObject;
begin
  // we don't now card
  Result := nil;
end;

procedure TShopItemRandomUnlockedCard.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
  raise ENotImplemented.Create('TShopItemRandomUnlockedCard.ExecuteBuy');
end;

function TShopItemRandomUnlockedCard.GetCategories : SetShopCategory;
begin
  Result := [scCurrency];
end;

function TShopItemRandomUnlockedCard.IsVisible : boolean;
begin
  Result := False;
end;

function TShopItemRandomUnlockedCard.ItemType : EnumShopItemType;
begin
  Result := itRandomCard;
end;

procedure TShopItemRandomUnlockedCard.RollbackBuy(const AObject : TObject; Count : integer);
begin
  raise ENotImplemented.Create('TShopItemRandomUnlockedCard.RollbackBuy');
end;

{ TShopDLCObserverThread }

constructor TShopDLCObserverThread.Create;
begin
  FTimer := TTimer.Create(POLLING_RATE);
  FNotOwnedDLCList := TList<AppId_t>.Create;
  inherited Create(False);
end;

destructor TShopDLCObserverThread.Destroy;
begin
  inherited;
  FNotOwnedDLCList.Free;
  FTimer.Free;
end;

procedure TShopDLCObserverThread.Execute;
var
  DLCCount, i : integer;
  AppId : AppId_t;
  IsAvailable : boolean;
  Name : string;
  Success : boolean;
begin
  // before start observing, we need current state
  DLCCount := SteamApps.GetDLCCount;
  for i := 0 to DLCCount - 1 do
  begin
    Success := SteamApps.BGetDLCDataByIndex(i, AppId, IsAvailable, name);
    if Success then
    begin
      // only save DLC id's if player is not owning it, already owned dlc's are not intressted to observed
      if not SteamApps.BIsDlcInstalled(AppId) then
          FNotOwnedDLCList.Add(AppId);
    end;
  end;
  FTimer.Start;
  // only observe dlc's, if not already all owned by players
  while not Terminated and (FNotOwnedDLCList.Count > 0) do
  begin
    if FTimer.Expired then
    begin
      for i := FNotOwnedDLCList.Count - 1 downto 0 do
      begin
        if SteamApps.BIsDlcInstalled(FNotOwnedDLCList[i]) then
        begin
          DoSynchronized(
            procedure()
            begin
              MainActionQueue.DoAction(TShopActionUpdateDLCOwnership.Create);
            end);
          // stop observing dlc, if it was installed
          FNotOwnedDLCList.Delete(i);
        end;
      end;
      FTimer.Start;
    end;
    sleep(100);
  end;
end;

{ TShopActionUpdateDLCOwnership }

function TShopActionUpdateDLCOwnership.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := ShopApi.DlcOwnershipChanged();
  promise.WaitForData;
  promise.Free;
  Result := True;
end;

{ TDraftBoxChoice }

constructor TDraftBoxChoice.Create(ShopItem : TShopItem; Amount, ChoiceID : integer);
begin
  inherited Create(ShopItem, Amount);
  FChoiceID := ChoiceID;
end;

{ TDraftBox }

constructor TDraftbox.Create(Data : RDraftBox);
var
  choice_data : RDraftBoxChoice;
begin
  FChoices := TUltimateObjectList<TDraftBoxChoice>.Create;
  FID := Data.ID;
  FTypeIdentifier := Data.type_identifier;
  Opened := Data.Opened;
  FLeague := Data.League;
  Data.Choices := HArray.Sort<RDraftBoxChoice>(Data.Choices,
    function(const L, R : RDraftBoxChoice) : integer
    begin
      Result := ord(Shop.ResolveShopItemByID(L.shopitem_id).ItemType) - ord(Shop.ResolveShopItemByID(R.shopitem_id).ItemType);
    end);
  for choice_data in Data.Choices do
  begin
    FChoices.Add(TDraftBoxChoice.Create(Shop.ResolveShopItemByID(choice_data.shopitem_id), choice_data.shopitem_count, choice_data.choice_id));
  end;
end;

function TDraftbox.IsCardBox : boolean;
begin
  Result := not IsSkinBox;
end;

function TDraftbox.IsSkinBox : boolean;
begin
  Result := TypeIdentifier.StartsWith('skin', True);
end;

destructor TDraftbox.Destroy;
begin
  FChoices.Free;
  inherited;
end;

procedure TDraftbox.DraftItem(Item : TDraftBoxChoice);
begin
  MainActionQueue.DoAction(TDraftBoxActionDraftItem.Create(self, Item.ChoiceID));
end;

{ TDraftBoxActionDraftItem }

constructor TDraftBoxActionDraftItem.Create(DraftBox : TDraftbox; ChoiceID : integer);
begin
  FDraftBox := DraftBox;
  FChoiceID := ChoiceID;
  inherited Create;
end;

procedure TDraftBoxActionDraftItem.Emulate;
begin
  DraftBox.Opened := True;
end;

function TDraftBoxActionDraftItem.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := LootApi.DraftItemFromDraftBox(DraftBox.FID, FChoiceID);
  // currently nothing todo, because backchannels will do the unlock
  Result := self.HandlePromise(promise);
end;

procedure TDraftBoxActionDraftItem.Rollback;
begin
  DraftBox.Opened := False;
end;

{ TInventoryItem }

procedure TInventoryItem.SetOpened(const Value : boolean);
begin
  FOpened := Value;
end;

function TInventoryItem.IsLevelReward : boolean;
begin
  Result := FTypeIdentifier.StartsWith(BaseConflict.Api.Shop.TInventoryItem.LID_LEVEL_REWARD, True);
end;

function TInventoryItem.RewardForPlayerLevel : integer;
var
  Level : string;
begin
  if not IsLevelReward then exit(-1);
  Level := TypeIdentifier.Replace(BaseConflict.Api.Shop.TInventoryItem.LID_LEVEL_REWARD, '', [rfIgnoreCase]);
  if not TryStrToInt(Level, Result) then Result := -1;
end;

{ TShopItemDraftbox }

constructor TShopItemDraftbox.Create(Shop : TShop; Data : TApiShopItemDraftbox);
begin
  inherited Create(Shop, Data);
  FLeague := Data.League;
  FTypeIdentifier := Data.type_identifier;
end;

function TShopItemDraftbox.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
end;

procedure TShopItemDraftbox.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin

end;

function TShopItemDraftbox.GetCategories : SetShopCategory;
begin
  Result := [scCurrency];
end;

function TShopItemDraftbox.ItemType : EnumShopItemType;
begin
  Result := itDraftbox;
end;

procedure TShopItemDraftbox.RollbackBuy(const AObject : TObject; Count : integer);
begin

end;

function TShopItemDraftbox.IsCardBox : boolean;
begin
  Result := not IsSkinBox;
end;

function TShopItemDraftbox.IsSkinBox : boolean;
begin
  Result := TypeIdentifier.StartsWith('skin', True);
end;

{ TShopItemUnlockIcon }

constructor TShopItemUnlockIcon.Create(Shop : TShop; Data : TApiShopItemUnlockIcon);
begin
  inherited Create(Shop, Data);
  FIconIdentifier := Data.icon_identifier;
end;

function TShopItemUnlockIcon.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
end;

procedure TShopItemUnlockIcon.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
  // comes via backchannel
end;

function TShopItemUnlockIcon.GetCategories : SetShopCategory;
begin
  Result := [scIcons]
end;

function TShopItemUnlockIcon.ItemType : EnumShopItemType;
begin
  Result := itIcon;
end;

procedure TShopItemUnlockIcon.RollbackBuy(const AObject : TObject; Count : integer);
begin

end;

{ TShopActionRedeemKeycode }

constructor TShopActionRedeemKeycode.Create(const Keycode : string);
begin
  inherited Create();
  FKeycode := Keycode;
end;

function TShopActionRedeemKeycode.Execute : boolean;
var
  promise : TPromise<ARLootboxContent>;
begin
  promise := ShopApi.RedeemKey(FKeycode);
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        Shop.CallRewardGained(HArray.MapFiltered<RLootboxContent, RReward>(promise.Value,
          function(const Item : RLootboxContent; out Reward : RReward) : boolean
          var
            res : RReward;
          begin
            res.ShopItem := nil;
            res.Amount := Item.shopitem_count;
            Result := Shop.TryResolveShopItemByID(Item.shopitem_id, res.ShopItem);
            if Result then
                Reward := res;
          end));
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

function TShopActionRedeemKeycode.ExecuteSynchronized : boolean;
begin
  if FKeycode = 'ACCOUNT_RESET' then
  begin
    {$IF not defined(MAPEDITOR)}
    ShutdownApplication := True;
    {$ENDIF}
  end;
  Result := True;
end;

{ TShopItemPremiumAccount }

constructor TShopItemPremiumAccount.Create(Shop : TShop; Data : TApiShopItemPremiumAccount);
begin
  inherited Create(Shop, Data);
  FDays := Data.Days;
end;

function TShopItemPremiumAccount.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
end;

procedure TShopItemPremiumAccount.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin

end;

function TShopItemPremiumAccount.GetCategories : SetShopCategory;
begin
  Result := [scPremiumTime];
end;

function TShopItemPremiumAccount.ItemType : EnumShopItemType;
begin
  Result := itPremiumTime;
end;

procedure TShopItemPremiumAccount.RollbackBuy(const AObject : TObject; Count : integer);
begin

end;

{ TShopItemDeckSlot }

constructor TShopItemDeckSlot.Create(Shop : TShop; Data : TApiShopItemDeckSlot);
begin
  inherited Create(Shop, Data);
end;

function TShopItemDeckSlot.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
end;

procedure TShopItemDeckSlot.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
end;

function TShopItemDeckSlot.GetCategories : SetShopCategory;
begin
  Result := [];
end;

function TShopItemDeckSlot.ItemType : EnumShopItemType;
begin
  Result := itDeckSlot;
end;

procedure TShopItemDeckSlot.RollbackBuy(const AObject : TObject; Count : integer);
begin
end;

{ TShopItemLootList }

constructor TShopItemLootList.Create(Shop : TShop; Data : TApiShopItemLootList);
begin
  inherited Create(Shop, Data);
end;

function TShopItemLootList.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
end;

procedure TShopItemLootList.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin

end;

function TShopItemLootList.GetCategories : SetShopCategory;
begin
  if self.Name.ToLowerInvariant.Contains('bundle') then
      Result := [scBundles]
  else
      Result := [];
end;

function TShopItemLootList.ItemType : EnumShopItemType;
begin
  Result := itLootList;
end;

procedure TShopItemLootList.RollbackBuy(const AObject : TObject; Count : integer);
begin

end;

{ TShopItemUnlockSkin }

function TShopItemUnlockSkin.CardInfo : TCardInfo;
begin
  Result := Skin.CardInfo;
end;

constructor TShopItemUnlockSkin.Create(Shop : TShop; Data : TApiShopItemUnlockSkin);
begin
  inherited Create(Shop, Data);
  FCard := CardManager.Cards.Query.Get(F('UID') = Data.card_uid);
  FSkin := Card.Skins.Query.Get(F('UID') = Data.skin_uid);
end;

function TShopItemUnlockSkin.EmulateBuy(Count : integer) : TObject;
begin
  Result := nil;
end;

procedure TShopItemUnlockSkin.ExecuteBuy(const AObject : TObject; const Data : TJSONData; Count : integer);
begin
end;

function TShopItemUnlockSkin.GetCategories : SetShopCategory;
begin
  Result := [scSkins];
end;

function TShopItemUnlockSkin.ItemType : EnumShopItemType;
begin
  Result := itSkin;
end;

function TShopItemUnlockSkin.League : integer;
begin
  Result := Card.League;
end;

function TShopItemUnlockSkin.MaxPurchasesReached : boolean;
begin
  Result := Skin.Unlocked;
end;

procedure TShopItemUnlockSkin.RollbackBuy(const AObject : TObject; Count : integer);
begin
end;

end.
