unit BaseConflict.Api.Messages;

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
  TMessageInbox = class;

  TMessageAttachment = class(TLootboxContent);

  TMessage = class
    strict private
      FID : integer;
      FMessageBox : TMessageInbox;
      FSubject : string;
      FText : string;
      FAttachments : TUltimateObjectList<TMessageAttachment>;
    published
      property Subject : string read FSubject;
      property Text : string read FText;
      property Attachments : TUltimateObjectList<TMessageAttachment> read FAttachments;
      [dXMLDependency('.Attachments')]
      function HasWideItems : boolean;
      procedure MarkAsReadAndCollectItems;
    public
      property ID : integer read FID;
      property MessageBox : TMessageInbox read FMessageBox;
      constructor Create(MessageBox : TMessageInbox; const MessageData : RMessage);
      destructor Destroy; override;
  end;

  ProcOnNewMessage = procedure(const Msg : TMessage) of object;

  TMessageInbox = class(TInterfacedObject, IMessageBackchannel)
    protected
      FOnNewMessage : ProcOnNewMessage;
      procedure LoadMessages(const Data : ARMessage);
    strict private
      FMessages : TUltimateObjectList<TMessage>;
      // ======================== Backchannels ===================
      procedure NewMessage(message_data : RMessage);
    published
      property Messages : TUltimateObjectList<TMessage> read FMessages;
    public
      property OnNewMessage : ProcOnNewMessage read FOnNewMessage write FOnNewMessage;
      constructor Create;
      destructor Destroy; override;
  end;

  {$REGION 'Actions'}

  [AQCriticalAction]
  TMessageActionLoadUnreadMessages = class(TPromiseAction)
    private
      FMessageBox : TMessageInbox;
    public
      constructor Create(MessageBox : TMessageInbox);
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  [AQCriticalAction]
  TMessageActionReadMessageAndCollectItems = class(TPromiseAction)
    private
      FMessage : TMessage;
      FIndex : integer;
    public
      constructor Create(AMessage : TMessage);
      procedure Emulate; override;
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  {$ENDREGION}
  {$M-}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  MessageInbox : TMessageInbox;

implementation

{ TMessageInbox }

constructor TMessageInbox.Create;
begin
  FMessages := TUltimateObjectList<TMessage>.Create;
  MainActionQueue.DoAction(TMessageActionLoadUnreadMessages.Create(self));
  RPCHandlerManager.SubscribeHandler(self);
end;

destructor TMessageInbox.Destroy;
begin
  RPCHandlerManager.SubscribeHandler(self);
  FMessages.Free;
  inherited;
end;

procedure TMessageInbox.LoadMessages(const Data : ARMessage);
begin
  Messages.AddRange(HArray.Map<RMessage, TMessage>(Data,
    function(const message_data : RMessage) : TMessage
    begin
      Result := TMessage.Create(self, message_data);
    end));
end;

procedure TMessageInbox.NewMessage(message_data : RMessage);
begin
  Messages.add(TMessage.Create(self, message_data));
  if assigned(OnNewMessage) then OnNewMessage(Messages.Last);
end;

{ TMessage }

constructor TMessage.Create(MessageBox : TMessageInbox; const MessageData : RMessage);
var
  i : integer;
  ShopItem : TShopItem;
begin
  FAttachments := TUltimateObjectList<TMessageAttachment>.Create;
  for i := 0 to length(MessageData.Attachments) - 1 do
  begin
    if shop.TryResolveShopItemByID(MessageData.Attachments[i].shopitem_id, ShopItem) then
        FAttachments.add(TMessageAttachment.Create(ShopItem, MessageData.Attachments[i].amount))
  end;
  FMessageBox := MessageBox;
  FID := MessageData.ID;
  FSubject := MessageData.Subject;
  FText := MessageData.Text;
end;

destructor TMessage.Destroy;
begin
  FAttachments.Free;
  inherited;
end;

function TMessage.HasWideItems : boolean;
var
  i : integer;
begin
  Result := False;
  for i := 0 to FAttachments.Count - 1 do
    if FAttachments[i].ShopItem.ItemType in [itCard, itSkin, itDeckSlot] then
        Result := True;
end;

procedure TMessage.MarkAsReadAndCollectItems;
begin
  MainActionQueue.DoAction(TMessageActionReadMessageAndCollectItems.Create(self));
end;

{ TMessageActionLoadUnreadMessages }

constructor TMessageActionLoadUnreadMessages.Create(MessageBox : TMessageInbox);
begin
  FMessageBox := MessageBox;
  inherited Create;
end;

function TMessageActionLoadUnreadMessages.Execute : boolean;
var
  Promise : TPromise<ARMessage>;
begin
  Promise := MessageApi.GetUnreadMessages;
  Promise.WaitForData;
  if Promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        FMessageBox.LoadMessages(Promise.Value);
      end);
  end
  else
      HandlePromiseError(Promise);
  Result := Promise.WasSuccessful;
  Promise.Free;
end;

procedure TMessageActionLoadUnreadMessages.Rollback;
begin
  FMessageBox.Messages.Clear;
end;

{ TMessageActionReadMessageAndCollectItems }

constructor TMessageActionReadMessageAndCollectItems.Create(AMessage : TMessage);
begin
  FMessage := AMessage;
  inherited Create;
end;

procedure TMessageActionReadMessageAndCollectItems.Emulate;
begin
  FIndex := FMessage.MessageBox.Messages.IndexOf(FMessage);
  FMessage.MessageBox.Messages.Extract(FMessage);
end;

function TMessageActionReadMessageAndCollectItems.Execute : boolean;
var
  Promise : TPromise<boolean>;
begin
  Promise := MessageApi.ReadMessageAndCollectItems(FMessage.ID);
  // currently nothing todo, because backchannels will do the unlock
  Result := self.HandlePromise(Promise);
  if Result then
      FMessage.Free;
end;

procedure TMessageActionReadMessageAndCollectItems.Rollback;
begin
  FMessage.MessageBox.Messages.Insert(FIndex, FMessage);
end;

end.
