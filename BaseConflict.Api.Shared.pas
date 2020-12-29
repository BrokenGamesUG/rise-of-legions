unit BaseConflict.Api.Shared;

interface

/// ////////////////////////////////////////////////////////////////////////////
/// ///////////////////// ABOUT ////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// This unit contains all types or methods that are used by other api units.
/// The main target is to avoid crossreferences, so it is totaly forbidden to
/// add any .api unit (except types and first level .api) to the uses clausel.
/// ////////////////////////////////////////////////////////////////////////////

uses
  // System
  System.SysUtils,
  // Engine
  Engine.Helferlein,
  Engine.DataQuery,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Helferlein.Windows,
  Engine.Network.RPC,
  // Game
  BaseConflict.Constants.Cards,
  BaseConflict.Constants.Client,
  BaseConflict.Api,
  BaseConflict.Api.Types;

type

  {$RTTI EXPLICIT METHODS([vcPublished, vcPublic, vcPrivate]) FIELDS([vcPublic, vcProtected]) PROPERTIES([vcPublic, vcPublished])}
  /// <summary> Describes an unique currency like gold or a premium currency like broken points.</summary>
  TCurrency = class
    private
      FUID : string;
      FServerName : string;
      function GetName : string;
    public
      property UID : string read FUID;
      property name : string read GetName;
      property ServerName : string read FServerName;
      function Icon : string;
      constructor Create(Data : RCurrency);
  end;

  TCurrencyManager = class
    private
      FCurrencies : TUltimateObjectList<TCurrency>;
      procedure LoadCurrencies(const Data : ARCurrency);
    public
      property Currencies : TUltimateObjectList<TCurrency> read FCurrencies;
      /// <summary> Returns a currency by his uid. Will raise exception if currency not found.
      /// CAUTION! Never free the currency returned. The reference is managed by manager and used in whole
      /// app, so freeing them will cause access violations.</summary>
      function GetCurrencyByUID(CurrencyUID : string) : TCurrency;
      function TryGetCurrencyByUID(const CurrencyUID : string; out Currency : TCurrency) : boolean;
      constructor Create();
      destructor Destroy; override;
  end;

  /// <summary> Describes on cost for an itemoffer.</summary>
  RCost = record
    Amount : integer;
    Currency : TCurrency;
    constructor Create(Amount : integer; Currency : TCurrency);
  end;

  [AQCriticalAction]
  TCurrencyManagerLoadCurrencies = class(TPromiseAction)
    private
      FCurrencyManager : TCurrencyManager;
    public
      property CurrencyManager : TCurrencyManager read FCurrencyManager;
      constructor Create(CurrencyManager : TCurrencyManager);
      function Execute : boolean; override;
      procedure Rollback; override;
  end;

  TVersionedItem = class(TInterfacedObject)
    private
      FClientVersion, FServerVersion : integer;
    public
      /// <summary> Should be called if backchannel notify change. </summary>
      procedure IncFromServer;
      /// <summary> Should be called if client emulate change. </summary>
      procedure IncFromClient;
      /// <summary> Should be called if client rollback change. </summary>
      procedure DecFromClient;
      /// <summary> Returns whether there are pending changes on the server. </summary>
      function IsClientAhead : boolean;
      /// <summary> Returns whether there are pending changes on the client. </summary>
      function IsServerAhead : boolean;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  CurrencyManager : TCurrencyManager;

implementation


{ RCost }

constructor RCost.Create(Amount : integer; Currency : TCurrency);
begin
  self.Amount := Amount;
  self.Currency := Currency;
end;

{ TCurrency }

constructor TCurrency.Create(Data : RCurrency);
begin
  FUID := Data.UID;
  FServerName := Data.name;
end;

function TCurrency.GetName : string;
begin
  Result := _('§shop_currency_name_' + FUID);
end;

function TCurrency.Icon : string;
begin
  Result := HClient.CurrencyIcon(FUID);
end;

{ TCurrencyManagerLoadCurrencies }

constructor TCurrencyManagerLoadCurrencies.Create(CurrencyManager : TCurrencyManager);
begin
  inherited Create();
  FCurrencyManager := CurrencyManager;
end;

function TCurrencyManagerLoadCurrencies.Execute : boolean;
var
  promise : TPromise<ARCurrency>;
begin
  promise := ShopApi.GetCurrencies;
  promise.WaitForData;
  if promise.WasSuccessful then
  begin
    DoSynchronized(
      procedure()
      begin
        CurrencyManager.LoadCurrencies(promise.Value);
      end);
  end
  else
      HandlePromiseError(promise);
  Result := promise.WasSuccessful;
  promise.Free;
end;

procedure TCurrencyManagerLoadCurrencies.Rollback;
begin
  CurrencyManager.Currencies.Clear;
end;

{ TCurrencyManager }

constructor TCurrencyManager.Create;
begin
  FCurrencies := TUltimateObjectList<TCurrency>.Create();
  MainActionQueue.DoAction(TCurrencyManagerLoadCurrencies.Create(self));
end;

destructor TCurrencyManager.Destroy;
begin
  FCurrencies.Free;
  inherited;
end;

function TCurrencyManager.GetCurrencyByUID(CurrencyUID : string) : TCurrency;
begin
  if not TryGetCurrencyByUID(CurrencyUID, Result) then
      raise ENotFoundException.Create('TCurrencyManager.GetCurrencyByUID: Could not found currency with uid ' + CurrencyUID + '!');
end;

procedure TCurrencyManager.LoadCurrencies(const Data : ARCurrency);
var
  currency_data : RCurrency;
begin
  for currency_data in Data do
      FCurrencies.Add(TCurrency.Create(currency_data));
end;

function TCurrencyManager.TryGetCurrencyByUID(const CurrencyUID : string; out Currency : TCurrency) : boolean;
var
  CurrencyTemp : TCurrency;
begin
  CurrencyTemp := Currencies.Query.Get(F('UID') = CurrencyUID, True);
  if assigned(CurrencyTemp) then
  begin
    Result := True;
    Currency := CurrencyTemp;
  end
  else
      Result := False;
end;

{ TVersionedItem }

procedure TVersionedItem.DecFromClient;
begin
  dec(FClientVersion);
end;

procedure TVersionedItem.IncFromClient;
begin
  inc(FClientVersion);
end;

procedure TVersionedItem.IncFromServer;
begin
  inc(FServerVersion);
end;

function TVersionedItem.IsClientAhead : boolean;
begin
  Result := FClientVersion > FServerVersion;
end;

function TVersionedItem.IsServerAhead : boolean;
begin
  Result := FClientVersion < FServerVersion;
end;

end.
