unit BaseConflict.Api.Deckbuilding;

interface

uses
  // System
  System.SysUtils,
  System.Math,
  Generics.Defaults,
  // Engine
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Network.RPC,
  Engine.DataQuery,
  Engine.dXML,
  // Game
  BaseConflict.Constants.Cards,
  BaseConflict.Api,
  BaseConflict.Api.Types,
  BaseConflict.Api.Cards;

type

  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic, vcPrivate]) FIELDS([vcPublic, vcProtected]) PROPERTIES([vcPublic, vcPublished])}
  {$M+}
  TDeckManager = class;
  TDeck = class;

  ProcDeckChanged = reference to procedure(const Sender : TDeck);

  TDeckCard = class
    strict private
      FOwner : TDeck;
      FCardInstance : TCardInstance;
      FSkin : TCardSkin;
      FID : integer;
      procedure SetSkin(const Value : TCardSkin); virtual;
    protected
      function Clone : TDeckCard;
      function GetData : RDeckCard;
      class function GetEmptyData : RDeckCard;
    published
      property ID : integer read FID;
      property CardInstance : TCardInstance read FCardInstance;
      property Skin : TCardSkin read FSkin write SetSkin;
    public
      function CardInfo : TCardInfo;
      function SlotIndex : integer;
      constructor Create(Owner : TDeck; const DeckCard : RDeckCard); overload;
      constructor Create(Owner : TDeck; CardInstance : TCardInstance); overload;
  end;

  TDeck = class
    private const
      DECKSLOT_COUNT = 12;
    private
      FID : integer;
      FCardslots : TUltimateObjectList<TDeckCard>;
      FDeckbuildingManager : TDeckManager;
      FOnChange : ProcDeckChanged;
      FFormerDeck : TUltimateObjectList<TDeckCard>;
      // methods to load data from api and save to
      function GetDeckData : RDeck;
      procedure SignalChange();
      constructor CreateWithData(const DeckData : RDeck; DeckbuildingManager : TDeckManager);
      constructor CreateEmpty(DeckbuildingManager : TDeckManager);
      procedure SortDeckList(DeckList : TUltimateObjectList<TDeckCard>);
      function CloneCardslots : TUltimateObjectList<TDeckCard>;
      function StartDeckUpdate : TUltimateObjectList<TDeckCard>;
      procedure SubmitDeckUpdate(const NewDeck : TUltimateObjectList<TDeckCard>);
    strict private
      FName, FIcon : string;
      FNew : boolean;
      procedure SetName(const Value : string); virtual;
      procedure SetIcon(const Value : string); virtual;
      procedure SetNew(const Value : boolean); virtual;
    published
      /// <summary> Name of the deck.</summary>
      property name : string read FName write SetName;
      /// <summary> Iconidentifier of the deck.</summary>
      property Icon : string read FIcon write SetIcon;
      /// <summary> Is the deck shown as new.</summary>
      property New : boolean read FNew write SetNew;
      property Cards : TUltimateObjectList<TDeckCard> read FCardslots;
      /// <summary> The different colors used in this deck. </summary>
      [dXMLDependency('.Cards')]
      function Colors : SetEntityColor;
      /// <summary> The number of different colors used in this deck. </summary>
      [dXMLDependency('.Colors')]
      function ColorCount : integer;
      /// <summary> The league of this deck, which depends on the maximum card league. </summary>
      [dXMLDependency('.Cards.CardInstance.League')]
      function League : integer;

      /// <summary> Adds this card to the deck and resort the deck. If card is already in the deck, nothing happens </summary>
      procedure AddCard(const Card : TCardInstance);
      /// <summary> Removes this card from the deck and resort the deck. If card is not part of the deck, nothing happens. </summary>
      procedure RemoveCard(const Card : TDeckCard);
    public
      /// <summary> Called if any data of the deck has changed.</summary>
      property OnChange : ProcDeckChanged read FOnChange write FOnChange;
      /// <summary> Unique ID of this deck, this id connect the deck to instance on server.</summary>
      property ID : integer read FID;
      /// <summary> Returns whether this card card could be put into the deck or not. </summary>
      [dXMLDependency('.Cards')]
      function CanAddCard(const CardInstance : TCardInstance) : boolean;
      /// <summary> Returns whether this card is in the deck or not. </summary>
      [dXMLDependency('.Cards')]
      function ContainsCard(const CardInstance : TCardInstance) : boolean;
      /// <summary> Returns whether this card can be added regarding the color restriction. </summary>
      [dXMLDependency('.Cards')]
      function ColorCheckCard(const CardInstance : TCardInstance) : boolean;
      [dXMLDependency('.Cards')]
      /// <summary> Returns whether this deck already have an epic card. </summary>
      function EpicCheckCard(const CardInstance : TCardInstance) : boolean;
      /// <summary> Returns whether this deck is filled up with cards. </summary>
      [dXMLDependency('.Cards')]
      function IsFull : boolean;
      /// <summary> Returns whether this deck has no cards in it. </summary>
      [dXMLDependency('.Cards')]
      function IsEmpty : boolean;
      /// <summary> Returns whether this slot is free. Returns false for slots not in range. </summary>
      function IsSlotFree(SlotIndex : integer) : boolean;
      /// <summary> Returns the count of cardslots. The count is predefinded and controlled by user and can't changed.</summary>
      function CardSlotCount : integer;
      /// <summary> Deletes the deck on server and remove it from deckmanager.</summary>
      procedure Delete();
      /// <summary> Sets new to false. </summary>
      procedure HasBeenSeen;
      destructor Destroy; override;
  end;

  TDeckManager = class(TInterfacedObject, IDeckbuildingBackchannel)
    private
      procedure LoadDecks(const Decks : ARDeck);
      // backchannel
      procedure DeckCreated(deck_data : RDeck);
    strict private
      FDecks : TUltimateObjectList<TDeck>;
    published
      property Decks : TUltimateObjectList<TDeck> read FDecks;
      [dXMLDependency('.Decks.New')]
      function HasAnyNewDeck : boolean;
    public
      /// <summary> Created a new deck and return instance. Any changes on deck will
      /// displayed instantly but will not send to server until deck creation is finsihed. Will automtically set
      /// deck to editing mode. </summary>
      function CreateNewDeck : TDeck;
      function IsCardInAnyDeck(const CardInstance : TCardInstance) : boolean;
      /// <summary> Returns the first non-empty deck of the user. Returns nil if none found. </summary>
      function GetDefaultDeck : TDeck;
      constructor Create;
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  /// <summary> Parent class for any action targeting deckmanager.</summary>
  TDeckManagerAction = class(TPromiseAction)
    private
      FDeckManager : TDeckManager;
    public
      constructor Create(DeckManager : TDeckManager);
  end;

  [AQCriticalAction]
  TDeckManagerActionLoadDecks = class(TDeckManagerAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TDeckManagerActionCreateDeck = class(TDeckManagerAction)
    private
      FCreatedDeck : TDeck;
    public
      property CreatedDeck : TDeck read FCreatedDeck;
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  /// <summary> Parent class for any action targeting deck. Will save deck on execute to server.</summary>
  TDeckAction = class(TPromiseAction)
    private
      FDeck : TDeck;
      FCleanedName : string;
    public
      constructor Create(deck : TDeck);
      /// <summary> Sends the complete deck to server.</summary>
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
  end;

  TDeckActionChangeName = class(TDeckAction)
    private
      FOldName, FNewName : string;
    public
      constructor Create(deck : TDeck; NewName : string);
      procedure Emulate; override;
      procedure Rollback; override;
  end;

  TDeckActionChangeIcon = class(TDeckAction)
    private
      FOldIcon, FNewIcon : string;
    public
      constructor Create(deck : TDeck; NewIcon : string);
      procedure Emulate; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TDeckActionChangeDeck = class(TDeckAction)
    private
      FOldDeck : TUltimateObjectList<TDeckCard>;
      FNewDeck : TUltimateObjectList<TDeckCard>;
    public
      /// <summary> Both lists are managed by the action. </summary>
      constructor Create(deck : TDeck; OldDeck, NewDeck : TUltimateObjectList<TDeckCard>);
      procedure Emulate; override;
      procedure Rollback; override;
      destructor Destroy; override;
  end;

  [AQCriticalAction]
  TDeckActionDelete = class(TDeckAction)
    public
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;
  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
var
  Deckbuilding : TDeckManager;

implementation

{ TDeck }

constructor TDeck.CreateWithData(const DeckData : RDeck; DeckbuildingManager : TDeckManager);
var
  i : integer;
begin
  CreateEmpty(DeckbuildingManager);
  FName := DeckData.Name;
  FID := DeckData.ID;
  FIcon := DeckData.icon_identifier;
  // fill deck with content, because content has to be unlocked by user, get a copy from
  // deckbuildingmanager
  assert(Cards.Count = length(DeckData.Cards));
  for i := 0 to min(Cards.Count, length(DeckData.Cards)) - 1 do
  begin
    if DeckData.Cards[i].card_id > 0 then
    begin
      FCardslots[i] := TDeckCard.Create(self, DeckData.Cards[i]);
    end
    else
        FCardslots[i] := nil;
  end;
end;

function TDeck.ColorCheckCard(const CardInstance : TCardInstance) : boolean;
var
  Color : EnumEntityColor;
  NewDeckColors : SetEntityColor;
  ColorCount : integer;
begin
  NewDeckColors := Colors + CardInstance.CardInfo.CardColors;
  NewDeckColors := NewDeckColors - [ecColorless];
  ColorCount := 0;
  for Color in NewDeckColors do
      ColorCount := ColorCount + 1;
  Result := ColorCount <= 2;
end;

function TDeck.ColorCount : integer;
var
  Color : EnumEntityColor;
begin
  Result := 0;
  for Color in Colors do
    if Color <> ecColorless then
        Result := Result + 1;
end;

function TDeck.Colors : SetEntityColor;
var
  i : integer;
begin
  Result := [];
  for i := 0 to FCardslots.Count - 1 do
    if assigned(FCardslots[i]) and not(FCardslots[i].CardInstance.CardInfo.CardColors <= Result) then
        Result := Result + FCardslots[i].CardInstance.CardInfo.CardColors;
end;

function TDeck.ContainsCard(const CardInstance : TCardInstance) : boolean;
begin
  Result := Cards.Extra.Any(
    function(Instance : TDeckCard) : boolean
    begin
      Result := assigned(Instance) and (Instance.CardInstance = CardInstance);
    end);
end;

constructor TDeck.CreateEmpty(DeckbuildingManager : TDeckManager);
var
  i : integer;
begin
  FDeckbuildingManager := DeckbuildingManager;
  FCardslots := TUltimateObjectList<TDeckCard>.Create;
  for i := 0 to DECKSLOT_COUNT - 1 do FCardslots.Add(nil);
  FID := -1;
end;

procedure TDeck.Delete;
begin
  MainActionQueue.DoAction(TDeckActionDelete.Create(self));
end;

destructor TDeck.Destroy;
begin
  FCardslots.Free;
  inherited;
end;

function TDeck.EpicCheckCard(const CardInstance : TCardInstance) : boolean;
begin
  Result := True;
  if CardInstance.CardInfo.IsEpic then
  begin
    Result := not Cards.Extra.Any(
      function(Instance : TDeckCard) : boolean
      begin
        Result := assigned(Instance) and Instance.CardInfo.IsEpic;
      end);
  end;
end;

procedure TDeck.AddCard(const Card : TCardInstance);
var
  NewDeck : TUltimateObjectList<TDeckCard>;
  i : integer;
begin
  if assigned(Card) and not IsFull and CanAddCard(Card) then
  begin
    NewDeck := StartDeckUpdate;
    for i := 0 to NewDeck.Count - 1 do
      if NewDeck[i] = nil then
      begin
        NewDeck[i] := TDeckCard.Create(self, Card);
        break;
      end;
    SubmitDeckUpdate(NewDeck);
  end;
end;

function TDeck.CanAddCard(const CardInstance : TCardInstance) : boolean;
begin
  Result := not ContainsCard(CardInstance) and ColorCheckCard(CardInstance) and EpicCheckCard(CardInstance);
end;

function TDeck.CardSlotCount : integer;
begin
  Result := Cards.Count;
end;

function TDeck.CloneCardslots : TUltimateObjectList<TDeckCard>;
var
  i : integer;
begin
  Result := TUltimateObjectList<TDeckCard>.Create();
  for i := 0 to Cards.Count - 1 do
  begin
    if assigned(Cards[i]) then
        Result.Add(Cards[i].Clone)
    else
        Result.Add(nil);
  end;
end;

function TDeck.GetDeckData : RDeck;
var
  i : integer;
begin
  assert(FID <> -1);
  Result.ID := FID;
  Result.Name := name;
  Result.icon_identifier := Icon;
  assert(CardSlotCount = FCardslots.Count);
  setlength(Result.Cards, CardSlotCount);
  for i := 0 to CardSlotCount - 1 do
  begin
    if FCardslots[i] <> nil then
        Result.Cards[i] := FCardslots[i].GetData
    else
        Result.Cards[i] := TDeckCard.GetEmptyData;
  end;
end;

procedure TDeck.HasBeenSeen;
begin
  self.New := False;
end;

function TDeck.IsEmpty : boolean;
begin
  Result := not Cards.Extra.Any(
    function(Instance : TDeckCard) : boolean
    begin
      Result := assigned(Instance);
    end);
end;

function TDeck.IsFull : boolean;
begin
  Result := Cards.Extra.All(
    function(Instance : TDeckCard) : boolean
    begin
      Result := assigned(Instance);
    end);
end;

function TDeck.IsSlotFree(SlotIndex : integer) : boolean;
begin
  Result := InRange(SlotIndex, 0, CardSlotCount - 1) and not assigned(FCardslots[SlotIndex]);
end;

function TDeck.League : integer;
var
  i : integer;
begin
  Result := 1; // if no card contained take 1
  for i := 0 to Cards.Count - 1 do
    if assigned(Cards[i]) then Result := Max(Result, Cards[i].CardInstance.League);
end;

procedure TDeck.RemoveCard(const Card : TDeckCard);
var
  index : integer;
  NewDeck : TUltimateObjectList<TDeckCard>;
begin
  if assigned(Card) and Cards.Query.TryGetIndex(F('.') = Card, index) then
  begin
    NewDeck := StartDeckUpdate;
    NewDeck[index] := nil;
    SubmitDeckUpdate(NewDeck);
  end;
end;

procedure TDeck.SetIcon(const Value : string);
begin
  if MainActionQueue.IsActive then FIcon := Value
  else MainActionQueue.DoAction(TDeckActionChangeIcon.Create(self, Value));
end;

procedure TDeck.SetName(const Value : string);
begin
  if MainActionQueue.IsActive then FName := Value
  else MainActionQueue.DoAction(TDeckActionChangeName.Create(self, Value));
end;

procedure TDeck.SetNew(const Value : boolean);
begin
  FNew := Value;
end;

procedure TDeck.SignalChange;
begin
  FDeckbuildingManager.Decks.SignalItemChanged(self);
  if assigned(OnChange) then OnChange(self);
end;

procedure TDeck.SortDeckList(DeckList : TUltimateObjectList<TDeckCard>);
begin
  DeckList.Sort(TComparer<TDeckCard>.Construct(
    function(const Left, Right : TDeckCard) : integer
    var
      LCardInfo, RCardInfo : TCardInfo;
    begin
      if assigned(Left) then
          LCardInfo := Left.CardInfo
      else
          LCardInfo := nil;
      if assigned(Right) then
          RCardInfo := Right.CardInfo
      else
          RCardInfo := nil;
      Result := TCardInfo.Compare(LCardInfo, RCardInfo);
    end));
end;

function TDeck.StartDeckUpdate : TUltimateObjectList<TDeckCard>;
begin
  FFormerDeck := CloneCardslots;
  Result := CloneCardslots;
end;

procedure TDeck.SubmitDeckUpdate(const NewDeck : TUltimateObjectList<TDeckCard>);
begin
  SortDeckList(NewDeck);
  MainActionQueue.DoAction(TDeckActionChangeDeck.Create(self, FFormerDeck, NewDeck));
end;

{ TDeckbuildingManager }

constructor TDeckManager.Create;
begin
  assert(assigned(CardManager), 'DeckManager depends on CardManager');
  FDecks := TUltimateObjectList<TDeck>.Create;
  RPCHandlerManager.SubscribeHandler(self);
  MainActionQueue.DoAction(TDeckManagerActionLoadDecks.Create(self));
end;

function TDeckManager.CreateNewDeck : TDeck;
var
  Action : TDeckManagerActionCreateDeck;
begin
  Action := TDeckManagerActionCreateDeck.Create(self);
  // this will create the deck, but first emulate the creation
  MainActionQueue.DoAction(Action);
  Result := Action.CreatedDeck;
end;

procedure TDeckManager.DeckCreated(deck_data : RDeck);
var
  deck : TDeck;
begin
  if not Decks.Query.Filter(F('ID') = deck_data.ID).Exists then
  begin
    deck := TDeck.CreateWithData(deck_data, self);
    deck.New := True;
    deck.SortDeckList(deck.Cards);
    Decks.Add(deck);
    // this will save the deck translated deckname and sorted cards
    deck.Name := HInternationalizer.TranslateTextRecursive('§deck_preset_title_' + deck.Name);
  end;
end;

destructor TDeckManager.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  FDecks.Free;
  inherited;
end;

function TDeckManager.GetDefaultDeck : TDeck;
var
  i : integer;
begin
  for i := 0 to Decks.Count - 1 do
    if not Decks[i].IsEmpty then exit(Decks[i]);
  Result := nil;
end;

function TDeckManager.HasAnyNewDeck : boolean;
begin
  Result := Decks.Query.Filter(F('New') = True).Exists;
end;

function TDeckManager.IsCardInAnyDeck(const CardInstance : TCardInstance) : boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to Decks.Count - 1 do
    if Decks[i].ContainsCard(CardInstance) then exit(True);
end;

procedure TDeckManager.LoadDecks(const Decks : ARDeck);
var
  deck : RDeck;
begin
  FDecks.Clear;
  for deck in Decks do
  begin
    FDecks.Add(TDeck.CreateWithData(deck, self));
  end;
end;

{ TCreateDeckAction }

procedure TDeckManagerActionCreateDeck.Emulate;
begin
  FCreatedDeck := TDeck.CreateEmpty(FDeckManager);
  FDeckManager.Decks.Add(FCreatedDeck);
end;

function TDeckManagerActionCreateDeck.Execute : boolean;
var
  promise : TPromise<integer>;
begin
  promise := DeckBuildingAPI.CreateDeck;
  promise.WaitForData;
  if promise.WasSuccessful then
      FCreatedDeck.FID := promise.Value
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TDeckManagerActionCreateDeck.Rollback;
begin
  // Remove it from list and free deck
  FDeckManager.Decks.Remove(FCreatedDeck);
end;

{ TChangeNameDeckAction }

constructor TDeckActionChangeName.Create(deck : TDeck; NewName : string);
begin
  inherited Create(deck);
  FNewName := NewName;
end;

procedure TDeckActionChangeName.Emulate;
begin
  FOldName := FDeck.Name;
  FDeck.Name := FNewName;
  FDeck.SignalChange;
end;

procedure TDeckActionChangeName.Rollback;
begin
  FDeck.Name := FOldName;
  FDeck.SignalChange;
end;

{ TDeckAction }

constructor TDeckAction.Create(deck : TDeck);
begin
  inherited Create();
  FDeck := deck;
end;

function TDeckAction.Execute : boolean;
var
  promise : TPromise<string>;
begin
  promise := DeckBuildingAPI.ChangeDeck(FDeck.ID, FDeck.GetDeckData);
  promise.WaitForData;
  if not promise.WasSuccessful then
      HandlePromiseError(promise)
  else
      FCleanedName := promise.Value;
  Result := promise.WasSuccessful;
  promise.Free;
end;

function TDeckAction.ExecuteSynchronized : boolean;
begin
  Result := True;
  if assigned(FDeck) and (FCleanedName <> FDeck.Name) then
      FDeck.Name := FCleanedName;
end;

{ TDeckActionDelete }

procedure TDeckActionDelete.Emulate;
begin
  FDeck.FDeckbuildingManager.Decks.Extract(FDeck)
end;

function TDeckActionDelete.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := DeckBuildingAPI.DeleteDeck(FDeck.ID);
  promise.WaitForData;
  if promise.WasSuccessful or (promise.ErrorAsErrorCode = ecUnknownDeck) then
      FreeAndNil(FDeck)
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TDeckActionDelete.Rollback;
begin
  FDeck.FDeckbuildingManager.Decks.Add(FDeck);
end;

{ TDeckActionChangeDeck }

constructor TDeckActionChangeDeck.Create(deck : TDeck; OldDeck, NewDeck : TUltimateObjectList<TDeckCard>);
begin
  inherited Create(deck);
  FOldDeck := OldDeck;
  FNewDeck := NewDeck;
end;

destructor TDeckActionChangeDeck.Destroy;
begin
  FOldDeck.Free;
  FNewDeck.Free;
  inherited;
end;

procedure TDeckActionChangeDeck.Emulate;
begin
  FDeck.Cards.Clear;
  FDeck.Cards.AddRange(FNewDeck);
  // FNewDeck item ownership is taken over by deck
  FNewDeck.OwnsObjects := False;
  FDeck.SignalChange;
end;

procedure TDeckActionChangeDeck.Rollback;
begin
  FDeck.Cards.Clear;
  FDeck.Cards.AddRange(FOldDeck);
  // FOldDeck item ownership is taken over by deck
  FOldDeck.OwnsObjects := False;
  FDeck.SignalChange;
end;

{ TDeckActionChangeIcon }

constructor TDeckActionChangeIcon.Create(deck : TDeck; NewIcon : string);
begin
  inherited Create(deck);
  FNewIcon := NewIcon;
end;

procedure TDeckActionChangeIcon.Emulate;
begin
  FOldIcon := FDeck.Icon;
  FDeck.Icon := FNewIcon;
  FDeck.SignalChange;
end;

procedure TDeckActionChangeIcon.Rollback;
begin
  FDeck.Icon := FOldIcon;
  FDeck.SignalChange;
end;

{ TDeckManagerAction }

constructor TDeckManagerAction.Create(DeckManager : TDeckManager);
begin
  inherited Create();
  FDeckManager := DeckManager;
end;

{ TDeckManagerLoadDecks }

function TDeckManagerActionLoadDecks.Execute : boolean;
var
  promise : TPromise<ARDeck>;
begin
  promise := DeckBuildingAPI.GetDecks;
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        FDeckManager.LoadDecks(promise.Value);
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TDeckManagerActionLoadDecks.Rollback;
begin
  FDeckManager.Decks.Clear;
end;

{ TDeckCard }

function TDeckCard.CardInfo : TCardInfo;
begin
  if assigned(Skin) then
      Result := Skin.CardInfo
  else
      Result := CardInstance.CardInfo;
end;

function TDeckCard.Clone : TDeckCard;
begin
  Result := TDeckCard.Create(FOwner, self.GetData);
end;

constructor TDeckCard.Create(Owner : TDeck; const DeckCard : RDeckCard);
begin
  FOwner := Owner;
  FCardInstance := CardManager.PlayerCards.Query.Get(F('ID') = DeckCard.card_id);
  if DeckCard.skin_id > 0 then
      FSkin := CardInstance.OriginCard.Skins.Query.Get(F('ID') = DeckCard.skin_id);
end;

constructor TDeckCard.Create(Owner : TDeck; CardInstance : TCardInstance);
begin
  FOwner := Owner;
  FCardInstance := CardInstance;
end;

function TDeckCard.GetData : RDeckCard;
begin
  Result.card_id := CardInstance.ID;
  if assigned(Skin) then
      Result.skin_id := Skin.ID
  else
      Result.skin_id := -1;
end;

class function TDeckCard.GetEmptyData : RDeckCard;
begin
  Result.card_id := -1;
  Result.skin_id := -1;
end;

procedure TDeckCard.SetSkin(const Value : TCardSkin);
var
  NewDeck : TUltimateObjectList<TDeckCard>;
begin
  NewDeck := FOwner.StartDeckUpdate;
  NewDeck[SlotIndex].FSkin := Value;
  FOwner.SubmitDeckUpdate(NewDeck);
end;

function TDeckCard.SlotIndex : integer;
begin
  Result := FOwner.Cards.IndexOf(self);
end;

end.
