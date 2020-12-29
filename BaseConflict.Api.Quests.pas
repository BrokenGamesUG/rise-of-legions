unit BaseConflict.Api.Quests;

interface

uses
  // System
  System.SysUtils,
  System.Math,
  System.Classes,
  System.Generics.Collections,
  // Engine
  Engine.dXML,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.Threads,
  Engine.Helferlein.DataStructures,
  Engine.Network.RPC,
  Engine.DataQuery,
  // Game
  BaseConflict.Api,
  BaseConflict.Api.Types,
  BaseConflict.Api.Shared,
  BaseConflict.Api.Shop;

type
  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic, vcPrivate]) FIELDS([vcPublic, vcProtected]) PROPERTIES([vcPublic, vcPublished])}
  {$M+}
  TQuestManager = class;

  TQuest = class
    protected
      FQuestManager : TQuestManager;
    strict private
      FIdentifier : string;
      FReward : TLootlist;
      FCompleted : boolean;
      FRerollable : boolean;
      FID, FTargetProgress, FCurrentProgress : integer;
      FInvisible : boolean;
      procedure SetCurrentProgress(const Value : integer); virtual;
      procedure SetCompleted(const Value : boolean); virtual;
    published
      property CurrentProgress : integer read FCurrentProgress write SetCurrentProgress;
      property TargetProgress : integer read FTargetProgress;
      property Identifier : string read FIdentifier;
      property Invisible : boolean read FInvisible;
      property Reward : TLootlist read FReward;
      property Rerollable : boolean read FRerollable;
      [dXMLDependency('.Reward.Loot')]
      function ShownReward : TLootboxContent;
      [dXMLDependency('.Reward.Loot')]
      function ShownSecondaryReward : TLootboxContent;
      property Completed : boolean read FCompleted write SetCompleted;
      procedure Complete; virtual;
      /// <summary> After Quest is completed player can collect reward by calling method.
      /// This will also remove quest from quests list. Because quest count as completed after reward is collected.</summary>
      procedure CollectReward;
      procedure ReRoll; virtual;
    public
      property ID : integer read FID;
      /// <summary> Currently hacked to autocollect starter decks. </summary>
      function ShouldBeAutoCollected : boolean;
      constructor Create(QuestManager : TQuestManager; const ProgressData : RQuestProgress);
      destructor Destroy; override;
  end;

  TTutorialQuest = class(TQuest)
    public const
      // a list of all tutorial tasks
      {$REGION 'TASKS'}
      PLAYER_BUY_CARD               = 'PLAYER_BUY_CARD';
      PLAYER_START_GAME             = 'PLAYER_START_GAME';
      PLAYER_NAVIGATE_PLAY          = 'PLAYER_NAVIGATE_PLAY';
      PLAYER_NAVIGATE_DECKBUILDER   = 'PLAYER_NAVIGATE_DECKBUILDER';
      PLAYER_NAVIGATE_COLLECTION    = 'PLAYER_NAVIGATE_COLLECTION';
      PLAYER_NAVIGATE_SHOP          = 'PLAYER_NAVIGATE_SHOP';
      PLAYER_NAVIGATE_SHOP_CRYSTALS = 'PLAYER_NAVIGATE_SHOP_CRYSTALS';
      PLAYER_COLLECT_REWARD         = 'PLAYER_COLLECT_REWARD';
      PLAYER_REROLL_QUEST           = 'PLAYER_REROLL_QUEST';
      PLAYER_REROLL_TUTORIAL_QUEST  = 'PLAYER_REROLL_TUTORIAL_QUEST';
      PLAYER_PLAY_TUTORIAL          = 'PLAYER_PLAY_TUTORIAL';
      PLAYER_CARD_REACH_MAX_LEVEL   = 'PLAYER_CARD_REACH_MAX_LEVEL';
      PLAYER_CARD_ASCEND            = 'PLAYER_CARD_ASCEND';
      PLAYER_CARD_ASCEND_BRONZE     = 'PLAYER_CARD_ASCEND_BRONZE';
      PLAYER_CARD_ASCEND_SILVER     = 'PLAYER_CARD_ASCEND_SILVER';
      PLAYER_CARD_ASCEND_GOLD       = 'PLAYER_CARD_ASCEND_GOLD';
      PLAYER_CARD_ASCEND_CRYSTAL    = 'PLAYER_CARD_ASCEND_CRYSTAL';
      PLAYER_CARD_UNLOCK            = 'PLAYER_CARD_UNLOCK';
      PLAYER_DECK_ADD_CARD          = 'PLAYER_DECK_ADD_CARD';
      PLAYER_ADD_FRIEND             = 'PLAYER_ADD_FRIEND';
      PLAYER_CARD_LEVEL_TRIBUTE     = 'PLAYER_CARD_LEVEL_TRIBUTE';
      PLAYER_SET_PROFILE_ICON       = 'PLAYER_SET_PROFILE_ICON';
      PLAYER_SET_DECK_ICON          = 'PLAYER_SET_DECK_ICON';
      PLAYER_SET_DECK_NAME          = 'PLAYER_SET_DECK_NAME';
      PLAYER_OPEN_DIALOG_PREFIX     = 'PLAYER_OPEN_DIALOG_';
      PLAYER_OPEN_URL_PREFIX        = 'PLAYER_OPEN_URL_';
      {$ENDREGION}
    strict private
      FPlayerActionTask : string;
    published
      procedure ReRoll; override;
      procedure Complete; override;
    public
      property PlayerActionTask : string read FPlayerActionTask;
      constructor Create(QuestManager : TQuestManager; const ProgressData : RQuestProgress);
  end;

  TDailyQuest = class(TQuest)

  end;

  TWeeklyQuest = class(TQuest)

  end;

  TEventQuest = class(TQuest)

  end;

  TQuestManager = class(TInterfacedObject, IQuestBackchannel)
    protected
      procedure LoadQuests(const Data : RQuestData);
      function CreateQuest(const Data : RQuestProgress) : TQuest;
    strict private
      FQuests : TUltimateObjectList<TQuest>;
      FMaxReRolls, FOpenReRolls, FMaxDailyQuests, FFinishedQuests : integer;
      procedure SetFinishedQuests(const Value : integer); virtual;
      procedure SetMaxDailyQuests(const Value : integer); virtual;
      procedure SetMaxReRolls(const Value : integer); virtual;
      procedure SetOpenReRolls(const Value : integer); virtual;
      // ======================== Backchannels ===================
      procedure QuestUpdate(quest_data : RQuestProgress; created : boolean);
    published
      property Quests : TUltimateObjectList<TQuest> read FQuests;
      property OpenReRolls : integer read FOpenReRolls write SetOpenReRolls;
      property MaxReRolls : integer read FMaxReRolls write SetMaxReRolls;
      property MaxDailyQuests : integer read FMaxDailyQuests write SetMaxDailyQuests;
      property FinishedQuests : integer read FFinishedQuests write SetFinishedQuests;
      [dXMLDependency('.Quests')]
      function EventQuests : TArray<TEventQuest>;
      [dXMLDependency('.EventQuests')]
      function EventQuestsCount : integer;
      [dXMLDependency('.Quests')]
      function TutorialQuests : TArray<TTutorialQuest>;
      [dXMLDependency('.TutorialQuests')]
      function TutorialQuestsCount : integer;
      [dXMLDependency('.Quests')]
      function WeeklyQuests : TArray<TWeeklyQuest>;
      [dXMLDependency('.WeeklyQuests')]
      function WeeklyQuestsCount : integer;
      [dXMLDependency('.Quests')]
      function DailyQuests : TArray<TDailyQuest>;
      [dXMLDependency('.DailyQuests')]
      function DailyQuestsCount : integer;
      [dXMLDependency('.Quests.Completed')]
      function IsAnyQuestCompleted : boolean;
    public
      constructor Create;
      /// <summary> Game signals quest manager an action player does, to push quest progress
      /// of any quests that have player actions as task.
      /// <param name="EventIdentifier"> Action player has done from TTutorialQuest task constant list.</param>
      procedure SignalPlayerAction(const ActionIdentifier : string; ForceSend : boolean = False);
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  TQuestAction = class(TPromiseAction)
    private
      FQuestManager : TQuestManager;
    public
      property QuestManager : TQuestManager read FQuestManager;
      constructor Create(QuestManager : TQuestManager);
  end;

  [AQCriticalAction]
  TQuestActionLoadCurrentQuests = class(TQuestAction)
    public
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TQuestActionSendPlayerAction = class(TQuestAction)
    private
      FActionIdentifier : string;
    public
      constructor Create(QuestManager : TQuestManager; const ActionIdentifier : string);
      function Execute : boolean; override;
  end;

  [AQCriticalAction]
  TQuestActionCollectReward = class(TQuestAction)
    private
      FQuest : TQuest;
      FIndex : integer;
    public
      constructor Create(QuestManager : TQuestManager; Quest : TQuest);
      procedure Emulate; override;
      function Execute : boolean; override;
      function ExecuteSynchronized : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TQuestActionReRoll = class(TQuestAction)
    private
      FQuest : TQuest;
      FIndex : integer;
      FOpenReRolls : integer;
    public
      constructor Create(QuestManager : TQuestManager; Quest : TQuest);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  QuestManager : TQuestManager;

implementation

{ TQuest }

procedure TQuest.CollectReward;
begin
  assert(Completed);
  MainActionQueue.DoAction(TQuestActionCollectReward.Create(FQuestManager, self));
  FQuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_COLLECT_REWARD);
end;

procedure TQuest.Complete;
begin
  Completed := True;
end;

constructor TQuest.Create(QuestManager : TQuestManager; const ProgressData : RQuestProgress);
begin
  FIdentifier := ProgressData.Quest.Identifier;
  FInvisible := ProgressData.Quest.Invisible;
  if length(ProgressData.Quest.Reward.loot) > 0 then
      FReward := TLootlist.Create(ProgressData.Quest.Reward);
  FID := ProgressData.ID;
  FRerollable := ProgressData.Quest.Rerollable;
  FTargetProgress := ProgressData.Quest.target_count;
  FCurrentProgress := ProgressData.counter;
  Completed := ProgressData.Completed;
  FQuestManager := QuestManager;
end;

destructor TQuest.Destroy;
begin
  FReward.Free;
  inherited;
end;

procedure TQuest.ReRoll;
begin
  MainActionQueue.DoAction(TQuestActionReRoll.Create(self.FQuestManager, self));
  FQuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_REROLL_QUEST);
end;

procedure TQuest.SetCompleted(const Value : boolean);
begin
  FCompleted := Value;
  if FCompleted then
  begin
    CurrentProgress := TargetProgress;
    if assigned(FQuestManager) then
        FQuestManager.FinishedQuests := FQuestManager.FinishedQuests + 1;
  end;
end;

procedure TQuest.SetCurrentProgress(const Value : integer);
begin
  FCurrentProgress := Value;
end;

function TQuest.ShouldBeAutoCollected : boolean;
begin
  Result := assigned(Reward) and (Reward.Content.Count = 1) and (Reward.Content.First.ShopItem.ItemType = itLootList);
end;

function TQuest.ShownReward : TLootboxContent;
begin
  if assigned(Reward) and (Reward.Content.Count >= 1) then
      Result := Reward.Content.First
  else
      Result := nil;
end;

function TQuest.ShownSecondaryReward : TLootboxContent;
begin
  if assigned(Reward) and (Reward.Content.Count >= 2) and not(Reward.Content[1].ShopItem.ItemType = itCurrency) then
      Result := Reward.Content[1]
  else
      Result := nil;
end;

{ TQuestManager }

constructor TQuestManager.Create;
begin
  FQuests := TUltimateObjectList<TQuest>.Create;
  RPCHandlerManager.SubscribeHandler(self);
  MainActionQueue.DoAction(TQuestActionLoadCurrentQuests.Create(self));
  FOpenReRolls := 1;
  FMaxReRolls := 1;
  FMaxDailyQuests := 3;
end;

function TQuestManager.CreateQuest(const Data : RQuestProgress) : TQuest;
begin
  case Data.Quest.quest_type of
    qtTutorial : Result := TTutorialQuest.Create(self, Data);
    qtDaily : Result := TDailyQuest.Create(self, Data);
    qtWeekly : Result := TWeeklyQuest.Create(self, Data);
    qtEvent : Result := TEventQuest.Create(self, Data);
  else raise ENotFoundException.CreateFmt('TQuestManager.CreateQuest: Questtype "%s" not implemented.', [HRtti.EnumerationToString<EnumQuestType>(Data.Quest.quest_type)]);
  end;
  Data.Quest.custom_task_data.Free;
end;

function TQuestManager.DailyQuests : TArray<TDailyQuest>;
begin
  Result := HArray.Cast<TQuest, TDailyQuest>(Quests.Query.Filter((F('.') = TDailyQuest) and not F('Invisible')).ToArray);
end;

function TQuestManager.DailyQuestsCount : integer;
begin
  Result := length(DailyQuests);
end;

destructor TQuestManager.Destroy;
begin
  RPCHandlerManager.UnsubscribeHandler(self);
  FQuests.Free;
  inherited;
end;

function TQuestManager.EventQuests : TArray<TEventQuest>;
begin
  Result := HArray.Cast<TQuest, TEventQuest>(Quests.Query.Filter((F('.') = TEventQuest) and not F('Invisible')).ToArray);
end;

function TQuestManager.EventQuestsCount : integer;
begin
  Result := length(EventQuests);
end;

function TQuestManager.IsAnyQuestCompleted : boolean;
begin
  Result := Quests.Query.Filter(F('Completed') and not F('Invisible')).Exists;
end;

procedure TQuestManager.LoadQuests(const Data : RQuestData);
var
  ProgressDataItem : RQuestProgress;
  AddedQuests : TList<TQuest>;
begin
  MaxReRolls := Data.max_rerolls;
  OpenReRolls := Data.rerolls;
  AddedQuests := TList<TQuest>.Create;
  Quests.Clear;
  // load progress data
  for ProgressDataItem in Data.Quests do
      AddedQuests.add(CreateQuest(ProgressDataItem));
  Quests.AddRange(AddedQuests);
  AddedQuests.Free;
end;

procedure TQuestManager.SetFinishedQuests(const Value : integer);
begin
  FFinishedQuests := Value;
end;

procedure TQuestManager.SetMaxDailyQuests(const Value : integer);
begin
  FMaxDailyQuests := Value;
end;

procedure TQuestManager.SetMaxReRolls(const Value : integer);
begin
  FMaxReRolls := Value;
end;

procedure TQuestManager.SetOpenReRolls(const Value : integer);
begin
  FOpenReRolls := Value;
end;

procedure TQuestManager.QuestUpdate(quest_data : RQuestProgress; created : boolean);
var
  Quest : TQuest;
begin
  if created and not Quests.Query.Filter(F('ID') = quest_data.ID).Exists() then
  begin
    Quest := CreateQuest(quest_data);
    Quests.add(Quest);
  end
  else
  begin
    Quest := Quests.Query.Get(F('ID') = quest_data.ID, True);
    if assigned(Quest) then
    begin
      if quest_data.Completed then
          Quest.Complete
      else
          Quest.Completed := quest_data.Completed;
      Quest.CurrentProgress := quest_data.counter;
    end;
  end;
end;

procedure TQuestManager.SignalPlayerAction(const ActionIdentifier : string; ForceSend : boolean);
begin
  if ForceSend or (Quests.Query.Filter((F('.') = TTutorialQuest) and (F('PlayerActionTask') = ActionIdentifier)).Exists) then
      MainActionQueue.DoAction(TQuestActionSendPlayerAction.Create(self, ActionIdentifier));
end;

function TQuestManager.TutorialQuests : TArray<TTutorialQuest>;
begin
  Result := HArray.Cast<TQuest, TTutorialQuest>(Quests.Query.Filter((F('.') = TTutorialQuest) and not F('Invisible')).ToArray);
end;

function TQuestManager.TutorialQuestsCount : integer;
begin
  Result := length(TutorialQuests);
end;

function TQuestManager.WeeklyQuests : TArray<TWeeklyQuest>;
begin
  Result := HArray.Cast<TQuest, TWeeklyQuest>(Quests.Query.Filter((F('.') = TWeeklyQuest) and not F('Invisible')).ToArray);
end;

function TQuestManager.WeeklyQuestsCount : integer;
begin
  Result := length(WeeklyQuests);
end;

{ TTutorialQuest }

procedure TTutorialQuest.Complete;
begin
  if not Completed then
  begin
    inherited;
    if self.FPlayerActionTask = TTutorialQuest.PLAYER_REROLL_TUTORIAL_QUEST then
        CollectReward;
  end;
end;

constructor TTutorialQuest.Create(QuestManager : TQuestManager; const ProgressData : RQuestProgress);
begin
  inherited Create(QuestManager, ProgressData);
  if ProgressData.Quest.custom_task_data.HasField('player_action_task') then
      FPlayerActionTask := ProgressData.Quest.custom_task_data['player_action_task'].AsValue.AsString
  else
      FPlayerActionTask := self.Identifier;
end;

procedure TTutorialQuest.ReRoll;
begin
  FQuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_REROLL_QUEST);
  FQuestManager.SignalPlayerAction(TTutorialQuest.PLAYER_REROLL_TUTORIAL_QUEST);
end;

{ TQuestAction }

constructor TQuestAction.Create(QuestManager : TQuestManager);
begin
  FQuestManager := QuestManager;
  inherited Create;
end;

{ TQuestActionLoadCurrentQuests }

function TQuestActionLoadCurrentQuests.Execute : boolean;
var
  QuestProgressPromise : TPromise<RQuestData>;
begin
  QuestProgressPromise := QuestApi.GetCurrentQuestData;
  QuestProgressPromise.WaitForData;
  if QuestProgressPromise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        QuestManager.LoadQuests(QuestProgressPromise.Value);
      end);

  end
  else
      HandlePromiseError(QuestProgressPromise);
  Result := QuestProgressPromise.WasSuccessful;
  QuestProgressPromise.Free;
end;

procedure TQuestActionLoadCurrentQuests.Rollback;
begin
  QuestManager.Quests.Clear;
end;

{ TQuestActionSendPlayerAction }

constructor TQuestActionSendPlayerAction.Create(QuestManager : TQuestManager; const ActionIdentifier : string);
begin
  FActionIdentifier := ActionIdentifier;
  inherited Create(QuestManager);
end;

function TQuestActionSendPlayerAction.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := QuestApi.SendPlayerAction(FActionIdentifier);
  Result := self.HandlePromise(promise);
end;
{ TQuestActionCollectReward }

constructor TQuestActionCollectReward.Create(QuestManager : TQuestManager; Quest : TQuest);
begin
  FQuest := Quest;
  inherited Create(QuestManager);
end;

procedure TQuestActionCollectReward.Emulate;
begin
  FIndex := QuestManager.Quests.IndexOf(FQuest);
  QuestManager.Quests.Extract(FQuest);
end;

function TQuestActionCollectReward.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := QuestApi.CollectReward(FQuest.ID);
  // currently nothing todo, because backchannels will do the unlock
  Result := self.HandlePromise(promise);
end;

function TQuestActionCollectReward.ExecuteSynchronized : boolean;
begin
  Shop.CallRewardGained(FQuest.Reward.Content.Query.Filter((F('ShopItem') = TShopItemBuyCurrency) or (F('ShopItem') = TShopItemUnlockIcon) or (F('ShopItem') = TShopItemLootList)).ToArray());
  FQuest.Free;
  Result := True;
end;

procedure TQuestActionCollectReward.Rollback;
begin
  QuestManager.Quests.Insert(FIndex, FQuest);
end;

{ TQuestActionReRoll }

constructor TQuestActionReRoll.Create(QuestManager : TQuestManager; Quest : TQuest);
begin
  FQuest := Quest;
  inherited Create(QuestManager);
end;

procedure TQuestActionReRoll.Emulate;
begin
  FOpenReRolls := QuestManager.OpenReRolls;
  QuestManager.OpenReRolls := QuestManager.OpenReRolls - 1;
  FIndex := QuestManager.Quests.IndexOf(FQuest);
  QuestManager.Quests.Extract(FQuest);
end;

function TQuestActionReRoll.Execute : boolean;
var
  promise : TPromise<boolean>;
begin
  promise := QuestApi.ReRoll(FQuest.ID);
  // currently nothing todo, because backchannels will do the unlock
  Result := self.HandlePromise(promise);
end;

procedure TQuestActionReRoll.Rollback;
begin
  QuestManager.OpenReRolls := FOpenReRolls;
  QuestManager.Quests.Insert(FIndex, FQuest);
end;

end.
