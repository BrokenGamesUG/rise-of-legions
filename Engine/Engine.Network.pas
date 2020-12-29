unit Engine.Network;

interface

uses
  // System
  System.SyncObjs,
  System.SysUtils,
  System.Classes,
  Winapi.WinSock2,
  Winapi.Windows,
  Generics.Collections,
  // thirdparty
  IdURI,
  // Engine
  Engine.Log,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.Threads,
  Engine.Serializer.Json;

const

  PINGINTERVALL = 2000;
  // NETWORKTIMEOUT               = 40000;
  NETWORKTIMEOUT               = 0; // for now disabled, to dangerous
  MAXSEQUENCELENGTH            = MAXWORD;
  MAXDATACOUNT                 = MAXBYTE;
  ACCEPTTIMEOUT : integer      = 500; // Accepttime for the threadaccepttime in msec
  RECEIVESENDTIMEOUT : integer = 500; // Receivetimeout for the blocking socket msec

  // some special for TCPDeluxeSocket
  INACCESIBLECOMMANDS = 240; // all commands after INACCESIBLECOMMANDS can not used by application and are reserved for deluxesocket
  COMMAND_PING        = 241; // send for ping request
  COMMAND_PONG        = 242; // return from remote socket for ping request
  COMMAND_SYNCCLOCK   = 243; // Request to immediatly send package back
  COMMAND_RESYNCCLOCK = 244; // Return of a syncclock sample

  SYNCCLOCKSAMPLES  = 10;  // number of samples are collected before timedelta between peer and local is calculated
  SYNCCLOCKDISTANCE = 500; // timedistance in msec between samples

  // Flags             Bitmasken
  FLAG_NOFLAGS = 0; // no flags set
  FLAG_NRD     = 1; // 00000001    //Flag not redirect
  FLAG_2       = 2; // 00000010    //unused flags
  FLAG_3       = 4;
  // ...
  FLAG_8 = 128; // 10000000

  // Bytepositions of data in sequnce (e.g. TDatapacket or TCommandSequence)
  SEQUENCELENGTHBYTE = 1;
  MAGICNUMBERBYTE    = 3;
  COMMANDBYTE        = 4;
  FLAGBYTE           = 5;
  UNIQUEIDBYTE       = 6;
  DATACOUNTBYTE      = 7;
  DATABYTE           = 8;
  MAGICNUMBER        = $A8;

type
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  ENetworkException = class(Exception);
  EConnectionFailedException = class(ENetworkException);
  EProtocolError = class(Exception);

  OnReceiveProcedure = procedure(var Daten, IP : AnsiString) of object;

  EnumSocketType = (stTCP, stUDP);

  TSocket = Winapi.WinSock2.TSocket;

  /// <summary> Data structure represent the InetAddress, composed of IPAddress and Port.</summary>
  RInetAddress = record
    private
      FIPAddress : string;
      FPort : Word;
      FSockAdress : TSockAddr;
    public
      /// <summary> Returns the TSockAddrIn representation of this data structure, often used for winapi socket calls.</summary>
      property SockAddr : TSockAddr read FSockAdress;
      /// <summary> Returns the dot seperated IP-address of the InetAdress</summary>
      property IPAddress : string read FIPAddress;
      /// <summary> Returns the port of the InetAddress</summary>
      property Port : Word read FPort;
      /// <summary> Create the InetAddress structure by a TSockAddrIn record</summary>
      constructor Create(SockAddr : TSockAddr); overload;
      /// <summary> Create a InetAddress record by IPAddress, given as dezimal dot seperated Value and a port.
      /// A Url like google.de is NOT allowed for IPAddres, use instead <see cref="CreateByUrl"/></summary>
      constructor Create(IPAddress : string; Port : Word); overload;
      /// <summary> Create a InetAddress record by IPAddress:Port combination, given as dezimal dot seperated Value + ':'+ port.
      /// A Url like google.de is NOT allowed for IPAddres, use instead <see cref="CreateByUrl"/></summary>
      constructor Create(IPAddressAndPort : string); overload;
      /// <summary> Create a InetAddress record by Address, given as Url like google.de and a port. A IPAddress is also a valide Url.</summary>
      constructor CreateByUrl(Url : string; Port : Word); overload;
      /// <summary> Create a InetAddress record by Address and combination like google.de:80. A IPAddress is also a valide Url (e.g. 127.0.0.1:3141).</summary>
      constructor CreateByUrl(UrlAndPort : string); overload;
      /// <summary> If RInetAddress contains a valid address (IPAddress <> 0.0.0.0) and (port <> 0) returns True </summary>
      function IsValidAddress : boolean;
      class operator Implicit(Value : RInetAddress) : string;
      class operator Equal(a, b : RInetAddress) : boolean;
      class operator NotEqual(a, b : RInetAddress) : boolean;
  end;

  /// <summary> The TCommandSequence save data for sending in a packet. The recviever will use a
  /// parser to read data. Because format limititions data added schouldn't exceed max Word - 6 and datacount not max Byte
  /// Headerformat for packet
  /// Format: SequenceLength|MagicNumber|Command|Flags|UniqueID|DataCount|Data
  /// Byte      1    2      |     3     |   4   |  5  |    6   |    7    |  8 ...
  /// </summary>
  TCommandSequence = class
    private
      function GetCommand : Byte;
    protected
      FSequence : AnsiString;
      procedure SetUniqueID(UniqueID : Byte);
      function GetDataCount : Byte;
      function GetFlagNotRedirect : boolean;
      procedure SetFlagNotRedirect(const Value : boolean);
      function GetSize : Cardinal;
      constructor CreateCopy(const Sequence : AnsiString);
    public
      property Command : Byte read GetCommand;
      property Size : Cardinal read GetSize;
      property Sequence : AnsiString read FSequence;
      /// <summary> Returns how much data the sequence contains.</summary>
      property DataCount : Byte read GetDataCount;
      /// <summary> Controll what server will do with this sequence, true -> server process it and NOT redirect it to other clients. False -> redirect it</summary>
      property FlagNotRedirect : boolean read GetFlagNotRedirect write SetFlagNotRedirect;
      /// <summary> Create a TCommandSequence with Command. The command is used bye reciever to deciede what to do with this sequence</summary>
      constructor Create(Command : Byte);
      /// <summary> Add a arbitary source with Size to sequence</summary>
      procedure AddData(var Buffer; Size : Word); overload;
      /// <summary> Add a string with variable length to sequenze. This methode also add the length.</summary>
      procedure AddData(Value : string); overload;
      /// <summary> Add a Value with generic type to sequence. NOT usable for arrays, TObjects or other reference types
      /// because method would send the memoryadress not the data</summary>
      procedure AddData<T>(Value : T); overload;
      procedure AddDataArray<T>(ValueArray : TArray<T>);
      procedure AddStream(Stream : TStream);
      /// <summary> Return a independant copy of current instance.</summary>
      function GetCopy : TCommandSequence;
  end;

  /// <summary> The TDatapacket parsed data from a TCommandSequence and allow to read that data
  /// Because format limititions data added schouldn't exceed max Word - 6 and datacount not max Byte
  /// Headerformat for packet
  /// Format: SequenceLength|MagicNumber|Command|Flags|UniqueID|DataCount|Data
  /// Byte      1    2      |     3     |   4   |  5  |    6   |    7    |  8 ...
  /// </summary>
  TDatapacket = class
    protected
      FSender : RInetAddress;
      FSocketType : EnumSocketType;
      FCommand : Byte;
      FFlags : Byte;
      FUniqueID : Byte;
      FDataCount : Byte;
      FData, FUnparsedSequence : RawByteString;
      /// <summary> Parse the data, create the datapacket and delete all parsed data from "Sequence"</summary>
      function GetFlagNotRedirect : boolean;
      constructor Create(var Sequence : RawByteString; Sender : RInetAddress; SocketType : EnumSocketType);
    public
      /// <summary> Command of Datapacket. This command should use, to determine which data included.</summary>
      property Command : Byte read FCommand;
      /// <summary> If flag is true, Datapacket should not redirect by server to all clients.</summary>
      property FlagNotRedirect : boolean read GetFlagNotRedirect;
      /// <summary> Read a string from databuffer. If not enough data present -> raise ENetworkException</summary>
      function ReadString : string;
      /// <summary> Read a arbitrary type from databuffer. If not enough data present -> raise ENetworkException.
      /// DON'T use this method for refrencetypes like pointers or classes.
      /// Also DON'T use it for strings, use instead <see cref="ReadString"/></summary>
      function Read<T> : T; overload;
      /// <summary> Read a string from databuffer. If not enough data present -> raise ENetworkException</summary>
      function Read : string; overload;
      function ReadArray<T> : TArray<T>;
      function ReadList<T> : TList<T>;
      function ReadStream : TStream;
      /// <summary> Read a data into buffer. If not enough data present -> raise ENetworkException.
      /// DON'T use this method for refrencetypes like pointers or classes.
      /// <param name="Buffer"> Buffer to grabbing the data. Buffer has to big enough for incoming data.</param>
      /// <param name="Size"> Sie of data to load into buffer in bytes.</param>
      procedure ReadBuffer(var Buffer; Size : Word);
      /// <summary> Check if given Sequence contains enough data to parse a datapacket</summary>
      class function CheckEnoughData(const Sequence : AnsiString) : boolean;
      /// <summary> Returns complete datapacket as base64 encoded string (included the header).</summary>
      function AsBase64EncodedString : RawByteString;
  end;

  /// <summary> Collect data from arbitary source and split it in datapackets.</summary>
  TParser = class
    private
      FData : TQueue<TDatapacket>;
      function GetDataPacketIsAvailable : boolean;
    public
      property IsDataPacketAvailable : boolean read GetDataPacketIsAvailable;
      /// <summary> Default constructor, allocate resources.</summary>
      constructor Create;
      /// <summary> Add a sequence of data. After adding, data is splitted and ready to read via <see cref="GetDatapacket"/></summary>
      procedure AddSequence(var Sequence : RawByteString; Sender : RInetAddress; SocketType : EnumSocketType);
      /// <summary>Parst die Daten und zerlegt sie damit in Datenpakete,
      /// wenn nicht genug im Puffer(Sequenz) steht um die Daten zu parsen,
      /// wird NIL zurückgegeben </summary>
      function GetDatapacket : TDatapacket;
      destructor Destroy; override;
  end;

  TNetworkInfoData = class
    private
      Semaphore : TCriticalSection;
    public
      SendRate : RDataRate;
      TotalSendedDataAmount : int64;
      ReceiveRate : RDataRate;
      TotalDataReceived : int64;
      constructor Create;
      procedure DataSended(DataSize : int64);
      /// <summary> Optional </summary>
      procedure Idle;
      procedure DataReceived(DataSize : int64);
      function ToString : string; override;
      destructor Destroy; override;
  end;

  // Def. Gegenstelle: Der Rechner der mit diesem TCPSocket verbunden ist
  // und alle Daten empfängt die darüber versendet werden (wenn man Client ist, Gegenstelle=Server)
  TTCPClientSocket = class
    public type
      EnumTCPStatus =
        (
        TCPStDisconnected, // socket open but connection is lost or closed by user
        TCPStConnected     // socket open and successfull connected to a server
        );

      ProcNewData = reference to procedure(Data : string);

    private type
      TSendThread = class(TThread)
        private
          FSocket : TTCPClientSocket;
          /// <summary> Buffer of data that has to be sended. This buffer is shared between mainthread
          /// (or thread that uses the TTCPClientSocket) and the senddata thread.</summary>
          FSharedSendBuffer : TThreadSafeData<RawByteString>;
          FDataAvailable : TEvent;
          LocalBuffer : RawByteString;
        public
          constructor Create(Socket : TTCPClientSocket);
          procedure Execute; override;
          procedure SendData(const Data : RawByteString);
          destructor Destroy; override;
      end;

      TReceiveThread = class(TThread)
        private
          FSocket : TTCPClientSocket;
        public
          constructor Create(Socket : TTCPClientSocket);
          procedure Execute; override;
      end;
    private
      FSocket : TSocket; // Der Integerwert indentifiziert den Socket der Verbindung
      FStatus : EnumTCPStatus;
      FCritialSectionDisconnect : TCriticalSection;
      FRemoteInetAddress : RInetAddress;
      FUseNagle : boolean;
      FOnNewData : ProcNewData;
      FReceiveThread : TReceiveThread;
      FSendThread : TSendThread;
      FDisconnectReason : string;
      /// <summary> Socket operation only inform about the fact that an error has occured, but does not return the errorcode.
      /// So this method handle an occured error and processing the errorcode. But this only works in the same threadcontext
      /// as the socketcall was made.
      /// Will Return True if the error was serious and any further no further operation should be processed with socket.</summary>
      function HandleError : boolean;
      procedure SetupSocket;
      procedure Disconnect(const DisconnectReason : string);
      procedure SetUseNagle(const Value : boolean);
      /// <summary> Is called by thread that receives new data and so the context is the receiver thread.</summary>
      procedure ProcessNewData(const NewData : RawByteString); virtual;
      procedure SetOnNewData(const Value : ProcNewData); virtual;
    public
      /// <summary> Callback is called when socket receives new data. Data contain all availabe data.
      /// If ClearBuffer is set to true, all data is cleared after callback call. This is very important, if
      /// this callback is the only option that is used to processing the data, else the buffer will overflow.
      /// The callback is called in the context of the the mainthread.</summary>
      property OnNewData : ProcNewData read FOnNewData write SetOnNewData;
      /// <summary> Define if socket is using the Nagle algorithm to optimize the "payload to header" rate
      /// at cost of latency. Default is false.</summary>
      property UseNagle : boolean read FUseNagle write SetUseNagle;
      /// <summary> Inetaddress of RemoteMachine, because TCP is a point to point connection, it exist only one endpoint.</summary>
      property RemoteInetAddress : RInetAddress read FRemoteInetAddress;
      /// <summary> Status of socket. Receive and send data only works, if status is </summary>
      property Status : EnumTCPStatus read FStatus;
      /// <summary> After Socket has status disconnected, property contains reason for disconnect.</summary>
      property DisconnectReason : string read FDisconnectReason;
      constructor Create(const ServerInetAdress : RInetAddress); overload;
      constructor Create(Socket : TSocket; const RemoteInetAddress : RInetAddress); overload;
      procedure Send(const Data : RawByteString); virtual;
      function Receive : RawByteString;
      /// <summary> Close connection to remote. Will auto called when socket is freed.</summary>
      procedure CloseConnection;
      destructor Destroy; override;
  end;

  /// <summary> "Deluxe" version of TTCPClientSocket, means the socket is on higher level
  /// then a pure TTCPClientSocket. E.g. it returns parsed data.</summary>
  TTCPClientSocketDeluxe = class(TTCPClientSocket)

    private type
      TNetworkSyncedClock = class
        private
          FSocket : TTCPClientSocketDeluxe;
          FPeerTimeDelta : int64;
          FPeerClockType : EnumClockType;
          FSyncRequestsSended : integer;
          FSyncRequestTimer : TTimer;
          FOwnClockType : EnumClockType;
          FSyncSamples : TAdvancedList<int64>;
          procedure Idle;
          procedure ProcessSyncSample(Data : TDatapacket);
          procedure ProcessReSyncSample(Data : TDatapacket);
          constructor Create(Socket : TTCPClientSocketDeluxe);
          function GetPeerClockTimestamp : int64;
          procedure SetClockType(const Value : EnumClockType);
          procedure CalculatePeerTimeDelta;
          /// <summary> Sends peer a sync packages, that the peer will return as fast as possible.</summary>
          procedure SendSyncRequest;
          function GetTimeStamp(ClockType : EnumClockType) : int64;
        public
          /// <summary> Sets the clocktype that should use for local clock. Default is ctHighPerformanceCounter.
          /// HINT: After changing the clocktype, the clock will automatically resync.</summary>
          property LocalClockType : EnumClockType read FOwnClockType write SetClockType;
          /// <summary> Returns the current timestamp of peerconnection. If inital sync has not completed, this
          /// property will return -1.
          /// HINT: You has not to wait to use this value until IsClockSyncComplete is true, because already after first
          /// sync sample the property will provide a sample, BUT only after sync is complete, the clock will provide
          /// a precise peer clock.</summary>
          property PeerClockTimestamp : int64 read GetPeerClockTimestamp;
          /// <summary> Returns true if the synchronization to peer clock is completed.</summary>
          function IsClockSyncComplete : boolean;
          procedure ReSyncPeerClock;
          destructor Destroy; override;
      end;

      TMaintainThread = class(TThread)
        private
          FSocket : TTCPClientSocketDeluxe;
          FPingTimer : TTimer;
          FLastPingIDSent : LongWord;
        public
          property Socket : TTCPClientSocketDeluxe read FSocket;
          constructor Create(Socket : TTCPClientSocketDeluxe);
          procedure Execute; override;
          destructor Destroy; override;
      end;

    private
      FParser : TParser;
      /// <summary> Need a threadsafe ReceiveQueue, because receivethread and any other thread</summary>
      FReceiveQueue : TThreadSafeObjectData<TQueue<TDatapacket>>;
      FAutoPing : boolean;
      FPing : integer;
      FDisconnectPingTimeOut : integer;
      FLastPingIDReceived : LongWord; // all pongs with smaller ID as current are ignored
      FLastPingReceived : TTimer;
      FMaintainThread : TMaintainThread;
      FSyncedPeerClock : TNetworkSyncedClock;
      /// <summary> Saves all data that is alerady received but not proceded, because some data for current package is missing.
      /// CAUTION This variable is used in receiving thread context, so don't use them anywhere else.</summary>
      FReceiveBuffer : RawByteString;
      constructor CreateDeluxe;
      function GetDataPacketIsAvailable : boolean;
      function GetPing : integer;
      procedure SetDisconnectPingTimeOut(const Value : integer);
      /// <summary> Process all datapackets and check it is for intern use (like ping packtes).
      /// If pass = false datapacket will not pass to application</summary>
      procedure ProcessDataPacket(Data : TDatapacket; var Pass : boolean);
      procedure ProcessNewData(const NewData : RawByteString); override;
      procedure SetOnNewData(const Value : TTCPClientSocket.ProcNewData); override;
      /// <summary> Same as public senddata but without command check.</summary>
      procedure SendDataInternal(Data : TCommandSequence);
    public
      /// <summary> A synced peer clock, to get the current peertime.</summary>
      property PeerClock : TNetworkSyncedClock read FSyncedPeerClock;
      /// <summary> If true ping will all <see cref="PINGINTERVALL"/> ms updated.
      /// Default Value is true.</summary>
      property AutoPing : boolean read FAutoPing write FAutoPing;
      /// <summary> Returns the ping to remote socket. Only available if AutoPing is active, else returns always -1.</summary>
      property Ping : integer read GetPing;
      /// <summary> If for DisconnectPingTimeOut no pongpacket (ping reply) has received, it is assumed that connection is
      /// lost and will be closed. If DisconnectPingTimeOut = 0, it will be disabled, else the value is the timeout in msec.
      /// HINT: Only works if autoping is enbaled. Default value is <see cref="NETWORKTIMEOUT"/></summary>
      property DisconnectPingTimeOut : integer read FDisconnectPingTimeOut write SetDisconnectPingTimeOut;
      /// <summary> True if there is any datapackets waiting to be received, else false.</summary>
      property IsDataPacketAvailable : boolean read GetDataPacketIsAvailable;
      constructor Create(ServerInetAdress : RInetAddress); overload;
      constructor Create(Socket : TSocket; RemoteInetAddress : RInetAddress); overload;
      /// <summary> Sends data to remote socket.
      /// <param name="Data"> Data that should be sended. Socket will not own data, so don't forgt to free it after sending.</param></summary>
      procedure SendData(Data : TCommandSequence); overload;
      /// <summary> Shortcut for SendData with same properties, but will intern create a commandsequence of command
      /// and data in order of apperent in data. Data only supports simple types, no arrays, objects or other complex types.</summary>
      procedure SendData(Command : Byte; const Data : array of const); overload;
      /// <summary> Sends a simple command, internal use a TCommandSequence to send data.
      /// <param name="Command"> Command that should be sended.</param></summary>
      procedure SendCommand(Command : Byte);
      /// <summary> Sendmethod from parent (raw-)socket. Do not use it, use instead SendData!</summary>
      procedure Send(const Data : RawByteString); override;
      /// <summary> Shortcut to get current synced peer timestamp, if time is currently not available, return -1</summary>
      function GetCurrentPeerTime : int64;
      /// <summary> Return oldest datapacket available. If no data available, returns nil. Socket take no ownership
      /// so received TDatapacket has to be freed.</summary>
      function ReceiveDataPacket : TDatapacket;
      /// <summary> Returns True when socket is connected to remote. </summary>
      function IsConnected : boolean;
      /// <summary> Returns whether this connection has been closed. </summary>
      function IsDisconnected : boolean;
      destructor Destroy; override;
  end;

  TTCPServerSocket = class
    public type
      ProcNewTCPClient = reference to procedure(ClientSocket : TSocket; InetAddress : RInetAddress);
    private type
      TTCPServerSocketAcceptThread = class(TThread)
        private
          FServerSocket : TTCPServerSocket;
        protected
          procedure Execute; override;
        public
          constructor Create(ServerSocket : TTCPServerSocket);
      end;
    private
      FSocket : TSocket;
      FPort : Word;
      FAcceptThread : TThread;
      FNewClient : ProcNewTCPClient;
      FBindedInetAddress : RInetAddress;
      FThreadSafe : boolean;
      procedure NewClientSocket(ClientSocket : TSocket; InetAddress : RInetAddress);
    public
      /// <summary> Port where socket is listening for new connections. Is set on create.</summary>
      property Port : Word read FPort;
      /// <summary> If True, any new connection is handled in mainthread context.
      /// DEFAULT: True</summary>
      property ThreadSafe : boolean read FThreadSafe write FThreadSafe;
      /// <summary> Assigned method is called if a new client connected to ServerSocket. This call executed in a
      /// Critical Section -> no new Clients can connect until called end</summary>
      property OnNewTCPClient : ProcNewTCPClient read FNewClient write FNewClient;
      /// <summary> Create and setup a TCPServerSocket.</summary>
      /// <param name="Port"> Socket is assigned to port and will only accept clients that connected to this. The Port must
      /// in range from 1 to 65335.</param>
      constructor Create(Port : Word);
      /// <summary> Stops accpting new clients, unbind socket</summary>
      destructor Destroy; override;
  end;

  TWebSocketClientFrame = class
    strict private
    const
      FIN_BITMASK            = 128;
      OPCODE_BITMASK         = 31;
      MASK_BITMASK           = 128;
      PAYLOAD_LENGTH_BITMASK = 127;
      // Websocket opcodes see: https://tools.ietf.org/html/rfc6455#section-5.2
      OPCODE_CONTINUATION_FRAME = $0;
      OPCODE_TEXT_FRAME         = $1;
      OPCODE_BINARY_FRAME       = $2;
      OPCODE_CLOSE_CONNECTION   = $8;
      OPCODE_PING               = $9;
      OPCODE_PONG               = $A;
    public type
      WebsocketOpcode = (ocContinuation, ocText, ocBinary, ocClose, ocPing, ocPong);
    private
      FOpcode : WebsocketOpcode;
      FFin : boolean;
      FPayload : RawByteString;
      function GetTextPayload : string;
      procedure SetTextPayload(const Value : string);
    public
      /// <summary> Frame data. Is set after parsing.</summary>
      /// <summary> Fin Frame, no more frames expected for data.</summary>
      property Fin : boolean read FFin write FFin;
      property BinaryPayload : RawByteString read FPayload write FPayload;
      property TextPayload : string read GetTextPayload write SetTextPayload;
      property Opcode : WebsocketOpcode read FOpcode write FOpcode;

      function ParseFrame(var FrameData : RawByteString) : boolean;
      function BuildFrame : RawByteString;
      function PayloadAsJson : TJsonData;
      /// <summary> Standard constructor.</summary>
      constructor Create();
      /// <summary> Standard destructor.</summary>
      destructor Destroy; override;
  end;

  TWebSocketClient = class
    private type
      TTCPClientSocketWS = class(TTCPClientSocket)
        private
          FWebsocketClient : TWebSocketClient;
          procedure ProcessNewData(const NewData : RawByteString); override;
        public
          function IsConnected : boolean;
          constructor Create(const ServerInetAdress : RInetAddress; WebsocketClient : TWebSocketClient);
      end;

      /// <summary> Thread for sending ping frame to server every X (HEARTBEAT_INTERVAL) ms.</summary>
      THeartbeatThread = class(TThread)
        private const
          HEARTBEAT_INTERVAL = 5000; // ms
        strict private
          FWebSocket : TWebSocketClient;
          FHeartbeatTimer : TTimer;
        protected
          procedure Execute; override;
          constructor Create(WebSocket : TWebSocketClient);
        public
          destructor Destroy; override;
      end;
    private
      FSocket : TTCPClientSocketWS;
      FReceiveBuffer : RawByteString;
      FReceivedFrames : TThreadSafeObjectData<TQueue<TWebSocketClientFrame>>;
      FHeartbeatThread : THeartbeatThread;
      /// <summary> Caution! Called in receive thread contex.</summary>
      procedure ProcessNewData(const NewData : RawByteString);
    public
      procedure Connect(URI : string);
      procedure Disconnect;
      /// <summary> Returns True if at least one web socket frame is available.</summary>
      function IsFrameAvailable : boolean;
      /// <summary> Returns the oldest frame received, if no frame available, nil is returned.
      /// Caller will own returned frame (caller has to free instance)</summary>
      function ReceiveFrame : TWebSocketClientFrame;
      function IsConnected : boolean;
      function IsDisconnected : boolean;
      constructor Create;
      destructor Destroy; override;
  end;

  TUDPSocket = class
    private
      FSocket : TSocket;
      FBindedAdress : RInetAddress;
      /// <summary> Create a UDP socket. And bind it to port</summary>
      /// <param name="Port"> Port to which socket is binded, if Port = 0, system use a free port</param>
      /// <param name="NetworkAdapter"> Networkadapter used for communication ->
      /// if 0.0.0.0 is set, multihomedhost (use every adapter available) </param>
      constructor Create(Port : Word; NetworkAdapter : AnsiString = '0.0.0.0'); virtual;
      function Receive(out Sender : RInetAddress) : AnsiString; virtual;
      function getPort : Word;
      procedure Error;
    public
      /// <summary> Binded port of Socket</summary>
      property Port : Word read getPort;
      /// <summary> sends a datagram (AnsiString) to Receiver IP,
      /// use IP-adress 255.255.255.255 for broadcasting</summary>
      procedure Send(Receiver : RInetAddress; Data : AnsiString);
      /// <summary> Unbind socket </summary>
      destructor Destroy; override;
  end;

  TUDPSocketNonBlocking = class(TUDPSocket)
    private
    public
      /// <summary> Create a UDP socket. And bind it to port</summary>
      /// <param name="Port"> Port to which socket is binded, if Port = 0, system use a free port</param>
      /// <param name="NetworkAdapter"> Networkadapter used for communication ->
      /// if 0.0.0.0 is set, multihomedhost (use every adapter available) </param>
      constructor Create(Port : Word; NetworkAdapter : AnsiString = '0.0.0.0'); override;
      function Receive(out Sender : RInetAddress) : AnsiString; override;
  end;

  /// <summary> Convert S to HEX String.</summary>
function Dump(const S : string) : string;
function getIPAddress : string;
function GetAllIPAdress : TStrings;

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  InfoData : TNetworkInfoData;

implementation

var
  GlobalwsaData : TWSAData;

procedure HandleWSAError; overload; forward;
procedure HandleWSAError(ErrorCode : integer); overload; forward;

procedure HandleWSAError;
begin
  HandleWSAError(WSAGetLastError);
end;

procedure HandleWSAError(ErrorCode : integer);
var
  ErrorMessage : string;
  Len : integer;
begin
  // WSAEWOULDBLOCK is only a hint, no serious error, Value 0 is no Error
  if (ErrorCode = WSAEWOULDBLOCK) or (ErrorCode = 0) then exit;
  SetLength(ErrorMessage, 512);
  Len := Formatmessage(Format_Message_from_System,
    nil, ErrorCode, 0, @ErrorMessage[1], length(ErrorMessage), nil);
  SetLength(ErrorMessage, Len);
  ErrorMessage := inttostr(ErrorCode) + ': ' + ErrorMessage;
  if ErrorCode = WSAETIMEDOUT then
      raise EConnectionFailedException.Create(ErrorMessage)
  else
      raise ENetworkException.Create(ErrorMessage);
end;

// --------------------------------------------------------------------

function GetAllIPAdress : TStrings;
type
  PPInAddr = ^PInAddr;
var
  HostInfo : PHostEnt;
  HostName : array [0 .. 255] of AnsiChar;
  Addr : PPInAddr;
begin
  Result := TStringList.Create;
  Result.Clear;
  if gethostname(HostName, SizeOf(HostName)) = 0 then
  begin
    HostInfo := gethostbyname(HostName);
    if HostInfo <> nil then
    begin
      Addr := Pointer(HostInfo^.h_addr_list);
      if (Addr <> nil) and (Addr^ <> nil) then
        repeat
          Result.Add(string(inet_ntoa(Addr^^)));
          inc(Addr);
        until Addr^ = nil;
    end;
  end;
end;

function getIPAddress : string;
var
  phoste : PHostEnt;
  Buffer : AnsiString;
begin
  Result := '';
  SetLength(Buffer, 2048);
  gethostname(PAnsiChar(Buffer), SizeOf(Buffer));
  phoste := gethostbyname(PAnsiChar(Buffer));
  if phoste = nil then
      Result := '127.0.0.1'
  else
      Result := string(AnsiString(inet_ntoa(PInAddr(phoste^.h_addr_list^)^)));
end;

function Dump(const S : string) : string;
var
  i : integer;
begin
  Result := ''; // Ergebnis zunächst leer
  for i := 1 to length(S) do
  begin                                              // über alle Zeichen im String
    Result := Result + IntToHex(Ord(S[i]), 2) + #32; // hex-Wert + Leerzeichen
    if ((i mod 12) = 0) then                         // alle 12 Zeichen...
        Result := Result + #13#10;                   // ...neue Zeile anfangen
  end;
end;

{ TParser }

procedure TParser.AddSequence(var Sequence : RawByteString; Sender : RInetAddress; SocketType : EnumSocketType);
begin
  while TDatapacket.CheckEnoughData(Sequence) do
      FData.Enqueue(TDatapacket.Create(Sequence, Sender, SocketType));
end;

constructor TParser.Create;
begin
  FData := TQueue<TDatapacket>.Create;
end;

destructor TParser.Destroy;
begin
  FData.Free;
  inherited;
end;

function TParser.GetDatapacket : TDatapacket;
begin
  if FData.Count > 0 then Result := FData.Dequeue
  else Result := nil;
end;

function TParser.GetDataPacketIsAvailable : boolean;
begin
  Result := FData.Count > 0;
end;

{ TCommandSequence }

constructor TCommandSequence.Create(Command : Byte);
begin
  SetLength(FSequence, DATACOUNTBYTE);                     // set length to DATACOUNTBYTE, because this is the last Byte that coontains data
  PWord(@FSequence[SEQUENCELENGTHBYTE])^ := DATACOUNTBYTE; // use Word (2 Byte) as lengthcounter, so @Sequenz[1] and @Sequenz[2] are used
  PByte(@FSequence[MAGICNUMBERBYTE])^ := MAGICNUMBER;      // some protection and identifier
  PByte(@FSequence[COMMANDBYTE])^ := Command;
  PByte(@FSequence[FLAGBYTE])^ := FLAG_NOFLAGS; // no flags at start, Value = NOFLAG
  PByte(@FSequence[UNIQUEIDBYTE])^ := 0;        // from no member
  PByte(@FSequence[DATACOUNTBYTE])^ := 0;       // no Data available
end;

constructor TCommandSequence.CreateCopy(const Sequence : AnsiString);
begin
  FSequence := Sequence;
end;

procedure TCommandSequence.AddData(var Buffer; Size : Word);
var
  NewSeq : AnsiString;
begin
  if (length(FSequence) + Size) > MAXSEQUENCELENGTH then raise ENetworkException.Create('TCommandSequence.AddData: New Data will overrun max. sequence length.');
  if Size > 0 then
  begin
    // save data
    SetLength(NewSeq, Size);
    System.Move(Buffer, Pointer(@NewSeq[1])^, Size);
    // add new data to sequence
    FSequence := FSequence + NewSeq;
  end;
  // increase data count
  if (DataCount + 1) > MAXDATACOUNT then raise ENetworkException.Create('TCommandSequence.AddData: New Data will overrun max. datacount.');
  PByte(@FSequence[DATACOUNTBYTE])^ := DataCount + 1;
  // adjust sequence length to new length
  PWord(@FSequence[SEQUENCELENGTHBYTE])^ := (Word(length(FSequence)));
end;

procedure TCommandSequence.AddData(Value : string);
begin
  assert(length(Value) < MAXSEQUENCELENGTH);
  AddData<Word>(Word(length(Value)));
  AddData(PChar(Value)^, length(Value) * SizeOf(Char));
end;

procedure TCommandSequence.AddData<T>(Value : T);
begin
  AddData(Pointer(@Value)^, SizeOf(T));
end;

procedure TCommandSequence.AddDataArray<T>(ValueArray : TArray<T>);
var
  i : integer;
begin
  assert((length(ValueArray) * SizeOf(T)) < MAXSEQUENCELENGTH);
  AddData<integer>(length(ValueArray));
  if length(ValueArray) > 0 then
      AddData(ValueArray[0], length(ValueArray) * SizeOf(T))
    // add zerodummydata to increase datacounter
  else AddData(i, 0);
end;

procedure TCommandSequence.AddStream(Stream : TStream);
var
  Data : TArray<Byte>;
begin
  assert(Stream.Size < MAXSEQUENCELENGTH);
  SetLength(Data, Stream.Size);
  Stream.ReadBuffer(Data[0], Stream.Size);
  AddDataArray<Byte>(Data);
  Data := nil;
end;

function TCommandSequence.GetCommand : Byte;
begin
  Result := PByte(@FSequence[COMMANDBYTE])^;
end;

function TCommandSequence.GetCopy : TCommandSequence;
begin
  Result := TCommandSequence.CreateCopy(self.Sequence);
end;

function TCommandSequence.GetDataCount : Byte;
begin
  Result := PByte(@FSequence[DATACOUNTBYTE])^;
end;

function TCommandSequence.GetFlagNotRedirect : boolean;
begin
  Result := (PByte(@FSequence[FLAGBYTE])^) = (PByte(@FSequence[FLAGBYTE])^ or FLAG_NRD);
end;

function TCommandSequence.GetSize : Cardinal;
begin
  Result := length(FSequence);
end;

procedure TCommandSequence.SetFlagNotRedirect(const Value : boolean);
begin
  if Value then PByte(@FSequence[FLAGBYTE])^ := PByte(@FSequence[FLAGBYTE])^ or FLAG_NRD
  else PByte(@FSequence[FLAGBYTE])^ := PByte(@FSequence[FLAGBYTE])^ and not FLAG_NRD
end;

procedure TCommandSequence.SetUniqueID(UniqueID : Byte);
begin
  PByte(@FSequence[UNIQUEIDBYTE])^ := UniqueID;
end;

{ TTCPServerSocket }

destructor TTCPServerSocket.Destroy;
begin
  FAcceptThread.Free;
  if CloseSocket(FSocket) = SOCKET_ERROR then HandleWSAError;
end;

procedure TTCPServerSocket.NewClientSocket(ClientSocket : TSocket; InetAddress : RInetAddress);
var
  code : TThreadProcedure;
begin
  code := procedure()
    begin
      if Assigned(FNewClient) then FNewClient(ClientSocket, InetAddress)
      else raise ENetworkException.Create('TTCPServerSocket.NewClientSocket: New client connected, but no method for this event is assigned.');
    end;
  if ThreadSafe then
      HThread.DoWorkSynchronized(code)
  else
      HThread.DoWork(code);
end;

constructor TTCPServerSocket.Create(Port : Word);
var
  SockAddr : TSockAddr;
  Mode : Cardinal;
begin
  FThreadSafe := True;
  FPort := Port;
  if (Port <= 0) then raise ENetworkException.Create('TTCPServerSocket.Create: Port out of valid range.');
  // Zero -> no error
  FSocket := Socket(AF_INET, SOCK_STREAM, IPProto_TCP);
  if FSocket = INVALID_SOCKET then HandleWSAError;
  FBindedInetAddress := RInetAddress.Create('0.0.0.0', Port);
  SockAddr := FBindedInetAddress.SockAddr;
  if bind(FSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR then HandleWSAError;
  if listen(FSocket, SOMAXCONN) = SOCKET_ERROR then HandleWSAError;
  // set mode to non blocking
  Mode := 1;

  {$WARNINGS OFF}
  {$R-}
  if ioctlsocket(FSocket, FIONBIO, Mode) = SOCKET_ERROR then HandleWSAError;
  {$R+}
  {$WARNINGS ON}
  FAcceptThread := TTCPServerSocketAcceptThread.Create(self);
end;

{ TTCPServerSocket.TTCPServerSocketAcceptThread }

constructor TTCPServerSocket.TTCPServerSocketAcceptThread.Create(ServerSocket : TTCPServerSocket);
begin
  inherited Create(False);
  self.FServerSocket := ServerSocket;
end;

procedure TTCPServerSocket.TTCPServerSocketAcceptThread.Execute;
var
  SockAddr : TSockAddr;
  Addrlen : integer;
  NewSocket : TSocket;
  SocketFDSet : TFDSet;
  TimeOut : timeval;
  // res : integer;
begin
  NameThreadForDebugging('TCPServerAcceptThread');
  Addrlen := SizeOf(SockAddr);
  SocketFDSet.fd_count := 1;
  SocketFDSet.fd_array[0] := FServerSocket.FSocket;
  TimeOut.tv_sec := (ACCEPTTIMEOUT) div 1000;
  TimeOut.tv_usec := (ACCEPTTIMEOUT) mod 1000;
  while not terminated do
  begin
    SocketFDSet.fd_count := 1;
    // no error checking, because will throw error if timeout achieve
    { res := }select(0, @SocketFDSet, nil, nil, @TimeOut);
    NewSocket := accept(FServerSocket.FSocket, @SockAddr, @Addrlen);
    if (NewSocket <> INVALID_SOCKET) then FServerSocket.NewClientSocket(NewSocket, RInetAddress.Create(SockAddr))
    else if NewSocket = INVALID_SOCKET then HandleWSAError;
  end;
end;

{ TUDPSocket }

destructor TUDPSocket.Destroy;
begin
  CloseSocket(FSocket);
end;

function TUDPSocket.getPort : Word;
begin
  Result := FBindedAdress.Port;
end;

constructor TUDPSocket.Create(Port : Word; NetworkAdapter : AnsiString = '0.0.0.0');
var
  SockAddr : TSockAddr;
  SockAddrLength : integer;
  Value : boolean;
  InstalledNetAdapter : TStrings;
begin
  InstalledNetAdapter := GetAllIPAdress;
  FSocket := Socket(AF_INET, SOCK_DGRAM, IPProto_UDP);
  if (FSocket = INVALID_SOCKET) then Error;
  // check NetworkAdapter is a installed valid adapteraddress
  if (NetworkAdapter <> '0.0.0.0') and (InstalledNetAdapter.IndexOf(string(NetworkAdapter)) < 0) then
      raise ENetworkException.Create('TUDPSocket.Create: A NetworkAdapter with address "' + string(NetworkAdapter) + '" was not found.');
  InstalledNetAdapter.Free;
  SockAddr := RInetAddress.Create(string(NetworkAdapter), Port).SockAddr;
  if bind(FSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR then Error;
  SockAddrLength := SizeOf(SockAddr);
  // get binded address and port
  if getsockname(FSocket, SockAddr, SockAddrLength) = SOCKET_ERROR then Error;
  FBindedAdress := RInetAddress.Create(SockAddr);
  // activate broadcasting for UDPSocket
  Value := True;
  if SetSockOpt(FSocket, SOL_SOCKET, SO_BROADCAST, @Value, 1) = SOCKET_ERROR then Error;
end;

function TUDPSocket.Receive(out Sender : RInetAddress) : AnsiString;
var
  RecvBytes, Addrlen : integer;
  SockAddr : TSockAddr;
  Buf : AnsiString;
begin
  SetLength(Buf, 1024);
  Addrlen := SizeOf(SockAddr);
  RecvBytes := recvfrom(FSocket, Buf[1], length(Buf), 0, SockAddr, Addrlen);
  if RecvBytes = SOCKET_ERROR then Error;
  SetLength(Buf, RecvBytes);
  Result := Buf;
  if length(Result) > 0 then Sender := RInetAddress.Create(SockAddr);
  InfoData.DataReceived(length(Result));
end;

procedure TUDPSocket.Send(Receiver : RInetAddress; Data : AnsiString);
var
  SockAddr : TSockAddr;
  Addrlen : integer;
begin
  if Receiver.IsValidAddress then
  begin
    InfoData.DataSended(length(Data));
    Addrlen := SizeOf(SockAddr);
    SockAddr := Receiver.SockAddr;
    if SendTo(FSocket, Data[1], length(Data), 0, @SockAddr, Addrlen) = SOCKET_ERROR then Error;
  end;
end;

procedure TUDPSocket.Error;
var
  ErrorCode : integer;
begin
  ErrorCode := WSAGetLastError;
  case ErrorCode of
    WSAEWOULDBLOCK : exit;
    WSAECONNABORTED, WSAECONNRESET : exit;
  else HandleWSAError(ErrorCode);
  end;
end;

{ TTCPClientSocket }

destructor TTCPClientSocket.Destroy;
begin
  FreeAndNil(FSendThread);
  Disconnect('Socket destroy.');
  FreeAndNil(FReceiveThread);
  FCritialSectionDisconnect.Free;
  inherited;
end;

procedure TTCPClientSocket.Disconnect(const DisconnectReason : string);
begin
  FCritialSectionDisconnect.Enter;
  try
    if Status <> TCPStDisconnected then
    begin
      FDisconnectReason := DisconnectReason;
      FStatus := TCPStDisconnected;
      if FSocket > 0 then
      begin
        if CloseSocket(FSocket) = SOCKET_ERROR then
            HandleWSAError;
      end;
    end;
  finally
    FCritialSectionDisconnect.Leave;
  end;
end;

procedure TTCPClientSocket.SetOnNewData(const Value : ProcNewData);
begin
  FOnNewData := Value;
end;

procedure TTCPClientSocket.SetupSocket;
var
  Value : boolean;
  WordValue : LongWord;
  LingerData : linger;
  Result : integer;
begin
  Value := True;
  // activate automated sending of keepalive packages, this will prevent that the connection is closed
  // because there was not data sended for a while between peer and local
  Result := SetSockOpt(FSocket, SOL_SOCKET, SO_KEEPALIVE, @Value, SizeOf(Value));
  if Result = SOCKET_ERROR then HandleError;
  // specifies how that socket should behave when data is queued to be sent and the closesocket function is called on the socket
  // activate linger
  LingerData.l_onoff := 1;
  // wait max 3 seconds to send data
  LingerData.l_linger := 3;
  Result := SetSockOpt(FSocket, SOL_SOCKET, SO_LINGER, @LingerData, SizeOf(LingerData));
  if Result = SOCKET_ERROR then HandleError;
  // set socket to blocking mode, because Threads will send and receive data
  WordValue := 0;
  Result := ioctlsocket(FSocket, integer(FIONBIO), WordValue);
  if Result = SOCKET_ERROR then HandleError;
  // on default don't use Nagle
  UseNagle := False;
  // start threads for receiving and sending data
  FReceiveThread := TReceiveThread.Create(self);
  FSendThread := TSendThread.Create(self);
end;

procedure TTCPClientSocket.SetUseNagle(const Value : boolean);
var
  tmpBool : boolean;
begin
  FUseNagle := Value;
  // use negated value, because setopt set if nagle is NOT used
  tmpBool := not Value;
  if SetSockOpt(FSocket, IPProto_TCP, TCP_NODELAY, @tmpBool, SizeOf(boolean)) = SOCKET_ERROR then
      HandleError;
end;

constructor TTCPClientSocket.Create(const ServerInetAdress : RInetAddress);
var
  SockAddr : TSockAddr;
  SeriousError : boolean;
begin
  FCritialSectionDisconnect := TCriticalSection.Create;
  SeriousError := False;
  // Create socket and connect to server
  FSocket := Socket(AF_INET, SOCK_STREAM, IPProto_TCP);
  if FSocket = INVALID_SOCKET then
      SeriousError := HandleError;
  if not SeriousError then
  begin
    FRemoteInetAddress := ServerInetAdress;
    SockAddr := ServerInetAdress.SockAddr;
    if Connect(FSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR then
        SeriousError := HandleError;
    // only make further operations, if we are connected successful
    if not SeriousError then
    begin
      SetupSocket;
      FStatus := TCPStConnected;
    end;
  end;
end;

procedure TTCPClientSocket.CloseConnection;
begin
  Disconnect('Connection closed by code (TTCPClientSocket.CloseConnection).')
end;

constructor TTCPClientSocket.Create(Socket : TSocket; const RemoteInetAddress : RInetAddress);
begin
  FCritialSectionDisconnect := TCriticalSection.Create;
  FSocket := Socket;
  SetupSocket;
  FRemoteInetAddress := RemoteInetAddress;
  FStatus := TCPStConnected;
end;

function TTCPClientSocket.Receive : RawByteString;
begin
  raise ENotImplemented.Create('TTCPClientSocket.Receive');
end;

procedure TTCPClientSocket.Send(const Data : RawByteString);
begin
  if (Status <> TCPStDisconnected) and Assigned(FSendThread) then
  begin
    FSendThread.SendData(Data);
  end;
end;

function TTCPClientSocket.HandleError : boolean;
var
  ErrorCode : integer;
  ErrorMessage : string;
begin
  ErrorCode := WSAGetLastError;
  case ErrorCode of
    WSAEWOULDBLOCK : exit(False);
    WSAECONNABORTED, WSAECONNRESET, WSAEINTR, WSAESHUTDOWN, WSAENOTSOCK :
      begin
        Result := True;
        ErrorMessage := Format('ErrorCode: %d, Msg: %s', [ErrorCode, SysErrorMessage(ErrorCode)]);
        Disconnect(ErrorMessage);
      end;
  else
    begin
      Result := True;
      HandleWSAError(ErrorCode);
    end;
  end;
end;

procedure TTCPClientSocket.ProcessNewData(const NewData : RawByteString);
begin
  HThread.DoWorkSynchronized(
    procedure
    begin
      if Assigned(OnNewData) then
          OnNewData(string(NewData));
    end);

end;

{ TDatapacket }

function TDatapacket.AsBase64EncodedString : RawByteString;
begin
  Result := EncodeBase64(FUnparsedSequence);
end;

class function TDatapacket.CheckEnoughData(const Sequence : AnsiString) : boolean;
begin
  // first check enough data for read datalength field
  Result := (length(Sequence) >= (DATABYTE - 1))
  // second check data long enough (against datalength field)
    and (length(Sequence) >= PWord(@Sequence[SEQUENCELENGTHBYTE])^);
end;

constructor TDatapacket.Create(var Sequence : RawByteString; Sender : RInetAddress; SocketType : EnumSocketType);
var
  DataPacketLength : Word;
begin
  // only parse data if enough data available
  assert(CheckEnoughData(Sequence));
  // a test to check dataintegrity
  if (PByte(@Sequence[MAGICNUMBERBYTE])^ <> MAGICNUMBER) then ENetworkException.Create('TDatapacket.Create: Error on parsing data. Magicnumber is missing.');
  FSender := Sender;
  FSocketType := SocketType;
  FDataCount := PByte(@Sequence[DATACOUNTBYTE])^;
  FCommand := PByte(@Sequence[COMMANDBYTE])^;
  FUniqueID := PByte(@Sequence[UNIQUEIDBYTE])^;
  DataPacketLength := PWord(@Sequence[SEQUENCELENGTHBYTE])^;
  FUnparsedSequence := Copy(Sequence, 1, DataPacketLength);
  FData := Copy(Sequence, DATABYTE, DataPacketLength - (DATABYTE - 1));
  FFlags := PByte(@Sequence[FLAGBYTE])^;
  Delete(Sequence, 1, DataPacketLength);
end;

function TDatapacket.GetFlagNotRedirect : boolean;
begin
  Result := (FFlags and FLAG_NRD) <> 0
end;

function TDatapacket.Read : string;
begin
  Result := ReadString;
end;

function TDatapacket.Read<T> : T;
begin
  ReadBuffer(Result, SizeOf(T));
end;

function TDatapacket.ReadArray<T> : TArray<T>;
var
  ArrayLength : integer;
begin
  ArrayLength := read<integer>;
  SetLength(Result, ArrayLength);
  if ArrayLength > 0 then
      ReadBuffer(Result[0], ArrayLength * SizeOf(T))
    // readdummy to decrease datacounter
  else ReadBuffer(ArrayLength, 0);
end;

procedure TDatapacket.ReadBuffer(var Buffer; Size : Word);
begin
  if length(FData) < Size then raise ENetworkException.Create('TDatapacket.ReadBuffer: Not enough data.');
  if FDataCount <= 0 then raise ENetworkException.Create('TDatapacket.ReadBuffer: DataCount already 0.');
  if Size > 0 then
  begin
    System.Move(Pointer(@FData[1])^, Buffer, Size);
    Delete(FData, 1, Size);
  end;
  dec(FDataCount);
end;

function TDatapacket.ReadList<T> : TList<T>;
begin
  Result := TList<T>.Create;
  Result.AddRange(ReadArray<T>());
end;

function TDatapacket.ReadStream : TStream;
var
  Data : TArray<Byte>;
begin
  Result := TMemoryStream.Create;
  Data := ReadArray<Byte>();
  Result.WriteBuffer(Data, length(Data));
  Result.Position := 0;
  Data := nil;
end;

function TDatapacket.ReadString : string;
var
  StringLength : Word;
begin
  StringLength := read<Word>;
  if StringLength > 0 then
  begin
    SetLength(Result, StringLength);
    ReadBuffer(Pointer(@Result[1])^, StringLength * SizeOf(Char))
  end
  else Result := '';
end;

{ TUDPSocket_NonBlocking }

constructor TUDPSocketNonBlocking.Create(Port : Word;
NetworkAdapter :
  AnsiString = '0.0.0.0');
var
  x : Cardinal;
begin
  inherited;
  // set mode to non blocking
  x := 1;
  {$WARNINGS OFF}
  {$R-}
  if ioctlsocket(FSocket, FIONBIO, x) = SOCKET_ERROR then Error;
  {$R+}
  {$WARNINGS ON}
end;

function TUDPSocketNonBlocking.Receive(out Sender : RInetAddress) : AnsiString;
begin
  Result := inherited Receive(Sender);
end;

{ RInetAdress }

constructor RInetAddress.Create(IPAddress : string; Port : Word);
begin
  Create(IPAddress + ':' + inttostr(Port));
end;

constructor RInetAddress.CreateByUrl(Url : string; Port : Word);
var
  HostEnt : PHostEnt;
begin
  // resolve Url to IP
  HostEnt := gethostbyname(PAnsiChar(AnsiString(Url)));
  if HostEnt = nil then HandleWSAError;
  Create(string(inet_ntoa(PInAddr(HostEnt^.h_addr_list^)^)), Port);
end;

constructor RInetAddress.Create(IPAddressAndPort : string);
var
  Items : TStrings;
  AddrLength : integer;
begin
  // clear address
  IPAddressAndPort := IPAddressAndPort.Replace(' ', '');
  Items := Split(IPAddressAndPort, ':');
  if Items.Count <> 2 then raise ENetworkException.Create('RInetAddress.Create: Incorrect address:port.');
  FIPAddress := Items[0];
  FPort := StrToInt(Items[1]);
  Items.Free;
  AddrLength := SizeOf(TSockAddr);
  if FPort = 0 then IPAddressAndPort := FIPAddress;
  if WSAStringToAddress(PChar(IPAddressAndPort), AF_INET, nil, FSockAdress, AddrLength) = SOCKET_ERROR then HandleWSAError;
end;

constructor RInetAddress.CreateByUrl(UrlAndPort : string);
var
  Items : TStrings;
begin
  // clear string by remove all spaces
  UrlAndPort := UrlAndPort.Replace(' ', '');
  Items := Split(UrlAndPort, ':');
  if Items.Count <> 2 then raise ENetworkException.Create('RInetAddress.CreateByUrl: Incorrect Url:port.');
  CreateByUrl(Items[0], StrToInt(Items[1]));
  Items.Free;
end;

class operator RInetAddress.Equal(a, b : RInetAddress) : boolean;
begin
  Result := (a.Port = b.Port) and (AnsiCompareText(a.IPAddress, b.IPAddress) = 0);
end;

constructor RInetAddress.Create(SockAddr : TSockAddr);
var
  StringBuffer : string;
  Count : Cardinal;
  Items : TStrings;
begin
  FSockAdress := SockAddr;
  // extract IPAddress and port from sockaddress
  SetLength(StringBuffer, 512);
  Count := length(StringBuffer);
  if WSAAddressToString(FSockAdress, SizeOf(TSockAddr), nil, PChar(StringBuffer), Count) = SOCKET_ERROR then HandleWSAError;
  SetLength(StringBuffer, Count - 1);
  Items := Split(StringBuffer, ':');
  FIPAddress := Items[0];
  FPort := StrToInt(Items[1]);
  Items.Free;
end;

class operator RInetAddress.Implicit(Value : RInetAddress) : string;
begin
  Result := Value.IPAddress + ':' + inttostr(Value.Port);
end;

function RInetAddress.IsValidAddress : boolean;
begin
  Result := (Port <> 0) and ((IPAddress <> '') and (IPAddress <> '0.0.0.0'));
end;

class operator RInetAddress.NotEqual(a, b : RInetAddress) : boolean;
begin
  Result := not(a = b);
end;

{ TNetworkInfoData }

constructor TNetworkInfoData.Create;
begin
  ReceiveRate := RDataRate.Create(1000);
  SendRate := RDataRate.Create(1000);
  Semaphore := TCriticalSection.Create();
end;

procedure TNetworkInfoData.DataReceived(DataSize : int64);
begin
  if not Assigned(self) then exit;
  Semaphore.Acquire;
  ReceiveRate.AddData(DataSize);
  TotalDataReceived := TotalDataReceived + DataSize;
  Semaphore.Release;
end;

procedure TNetworkInfoData.DataSended(DataSize : int64);
begin
  if not Assigned(self) then exit;
  Semaphore.Acquire;
  SendRate.AddData(DataSize);
  TotalSendedDataAmount := TotalSendedDataAmount + DataSize;
  Semaphore.Release;
end;

destructor TNetworkInfoData.Destroy;
begin
  Semaphore.Free;
  inherited;
end;

procedure TNetworkInfoData.Idle;
begin
  if not Assigned(self) then exit;
  Semaphore.Acquire;
  SendRate.Compute;
  ReceiveRate.Compute;
  Semaphore.Release;
end;

function TNetworkInfoData.ToString : string;
begin
  if not Assigned(self) then exit;
  Semaphore.Acquire;
  Result :=
    'SendedData: ' + FormatByteSize(SendRate.GetDataRate) + '/sec (Total: ' + FormatByteSize(TotalSendedDataAmount) + ')' + sLineBreak +
    'ReceivedData: ' + FormatByteSize(ReceiveRate.GetDataRate) + '/sec (Total: ' + FormatByteSize(TotalDataReceived) + ')' + sLineBreak;
  Semaphore.Release;
end;

{ TTCPClientSocketDeluxe }

constructor TTCPClientSocketDeluxe.Create(ServerInetAdress : RInetAddress);
begin
  inherited Create(ServerInetAdress);
  if Status = TCPStConnected then
      CreateDeluxe;
end;

constructor TTCPClientSocketDeluxe.CreateDeluxe;
begin
  FParser := TParser.Create;
  FAutoPing := True;
  FDisconnectPingTimeOut := NETWORKTIMEOUT;
  FLastPingReceived := TTimer.CreateAndStart(FDisconnectPingTimeOut);
  FReceiveQueue := TThreadSafeObjectData < TQueue < TDatapacket >>.Create(TQueue<TDatapacket>.Create);
  FSyncedPeerClock := TNetworkSyncedClock.Create(self);
  FSyncedPeerClock.ReSyncPeerClock;
  FMaintainThread := TMaintainThread.Create(self);
end;

destructor TTCPClientSocketDeluxe.Destroy;
begin
  FMaintainThread.Free;
  inherited;
  FParser.Free;
  FReceiveQueue.Free;
  FLastPingReceived.Free;
  FSyncedPeerClock.Free;
end;

constructor TTCPClientSocketDeluxe.Create(Socket : TSocket; RemoteInetAddress : RInetAddress);
begin
  CreateDeluxe;
  inherited Create(Socket, RemoteInetAddress);
end;

function TTCPClientSocketDeluxe.GetCurrentPeerTime : int64;
begin
  if Assigned(PeerClock) then
      Result := PeerClock.GetPeerClockTimestamp
  else
      Result := -1;
end;

function TTCPClientSocketDeluxe.GetDataPacketIsAvailable : boolean;
begin
  FReceiveQueue.Lock;
  Result := FReceiveQueue.Data.Count > 0;
  FReceiveQueue.Unlock;
end;

function TTCPClientSocketDeluxe.GetPing : integer;
begin
  if AutoPing and IsConnected then
      Result := FPing
  else Result := -1;
end;

function TTCPClientSocketDeluxe.IsConnected : boolean;
begin
  Result := Status = TCPStConnected;
end;

function TTCPClientSocketDeluxe.IsDisconnected : boolean;
begin
  Result := Status = TCPStDisconnected;
end;

procedure TTCPClientSocketDeluxe.ProcessDataPacket(Data : TDatapacket; var Pass : boolean);
var
  ID : Cardinal;
  Timestamp : int64;
  outData : TCommandSequence;
begin
  // assume that packet contain some intern data (command)
  Pass := False;
  case Data.Command of
    // if ping only returnsdata in pongpacket
    COMMAND_PING :
      begin
        ID := Data.Read<Cardinal>;
        Timestamp := Data.Read<int64>;
        outData := TCommandSequence.Create(COMMAND_PONG);
        outData.AddData<Cardinal>(ID);
        outData.AddData<int64>(Timestamp);
        SendDataInternal(outData);
        Data.Free;
        outData.Free;
      end;
    COMMAND_PONG :
      begin
        ID := Data.Read<Cardinal>;
        Timestamp := Data.Read<int64>;
        assert(FLastPingIDReceived <> ID);
        // only process new pings
        if FLastPingIDReceived < ID then
        begin
          FLastPingIDReceived := ID;
          FPing := integer(TimeManager.GetTimeStamp - Timestamp);
          FLastPingReceived.Start;
        end;
        Data.Free;
      end;
    COMMAND_SYNCCLOCK :
      begin
        PeerClock.ProcessSyncSample(Data);
        Data.Free;
      end;
    COMMAND_RESYNCCLOCK :
      begin
        PeerClock.ProcessReSyncSample(Data);
        Data.Free;
      end;
    // okay, contains no intern data, so pass them to application
  else Pass := True;
  end;
end;

procedure TTCPClientSocketDeluxe.ProcessNewData(const NewData : RawByteString);
var
  Data : TDatapacket;
  Pass : boolean;
begin
  FReceiveBuffer := FReceiveBuffer + NewData;
  FParser.AddSequence(FReceiveBuffer, RemoteInetAddress, stTCP);
  while FParser.IsDataPacketAvailable do
  begin
    Data := FParser.GetDatapacket;
    Pass := True;
    ProcessDataPacket(Data, Pass);
    if Pass then
    begin
      FReceiveQueue.Lock;
      FReceiveQueue.Data.Enqueue(Data);
      FReceiveQueue.Unlock;
    end;
  end;
end;

function TTCPClientSocketDeluxe.ReceiveDataPacket : TDatapacket;
begin
  FReceiveQueue.Lock;
  if FReceiveQueue.Data.Count > 0 then
      Result := FReceiveQueue.Data.Dequeue
  else Result := nil;
  FReceiveQueue.Unlock;
end;

procedure TTCPClientSocketDeluxe.Send(const Data : RawByteString);
begin
  raise ENetworkException.Create('TTCPClientSocketDeluxe.Send: Should not be used!');
end;

procedure TTCPClientSocketDeluxe.SendCommand(Command : Byte);
var
  Sequence : TCommandSequence;
begin
  Sequence := TCommandSequence.Create(Command);
  SendData(Sequence);
  Sequence.Free;
end;

procedure TTCPClientSocketDeluxe.SendData(Command : Byte; const Data : array of const);
var
  i : integer;
  seq : TCommandSequence;
  Item : TVarRec;
begin
  seq := TCommandSequence.Create(Command);
  // add all data to sequence
  for i := 0 to high(Data) do
  begin
    Item := TVarRec(Data[i]);
    case Item.VType of
      vtInteger : seq.AddData<integer>(Item.VInteger);
      vtBoolean : seq.AddData<boolean>(Item.VBoolean);
      vtString : seq.AddData(string(Item.VString));
      vtWideString : seq.AddData(WideString(Item.VWideString));
      vtAnsiString : seq.AddData(AnsiString(Item.VAnsiString));
      vtUnicodeString : seq.AddData(UnicodeString(Item.VUnicodeString));
      vtPointer, vtPChar, vtChar, vtCurrency, vtExtended, vtObject, vtClass, vtWideChar, vtPWideChar,
        vtVariant, vtInterface, vtInt64 : HLog.Write(elError, 'TTCPClientSocketDeluxe.SendData: Datatype not supported.', ENotSupportedException);
    end;
  end;
  SendData(seq);
  seq.Free;
end;

procedure TTCPClientSocketDeluxe.SendDataInternal(Data : TCommandSequence);
begin
  inherited Send(Data.Sequence);
end;

procedure TTCPClientSocketDeluxe.SendData(Data : TCommandSequence);
begin
  assert(Data.Command < INACCESIBLECOMMANDS);
  inherited Send(Data.Sequence);
end;

procedure TTCPClientSocketDeluxe.SetDisconnectPingTimeOut(const Value : integer);
begin
  FDisconnectPingTimeOut := Value;
  FLastPingReceived.Interval := Value;
  FLastPingReceived.Start;
end;

procedure TTCPClientSocketDeluxe.SetOnNewData(const Value : TTCPClientSocket.ProcNewData);
begin
  HLog.Write(elError, 'TTCPClientSocketDeluxe: OnNewData callback not supported by TTCPClientSocketDeluxe', ENotSupportedException);
end;

{ TTCPClientSocketDeluxe.TNetworkSyncedClock }

procedure TTCPClientSocketDeluxe.TNetworkSyncedClock.CalculatePeerTimeDelta;
var
  median : int64;
  sum : int64;
  Count, i : integer;
begin
  assert(FSyncSamples.Count > 0);
  sum := 0;
  Count := 0;
  // get median of the samplelist
  FSyncSamples.Sort;
  median := FSyncSamples[FSyncSamples.Count div 2];
  // if a value is more greater than 1.5 times higher discard them, because this is only a outlier or a resended TCP package
  for i := 0 to FSyncSamples.Count - 1 do
  begin
    if abs(FSyncSamples[i]) < abs(1.5 * median) then
    begin
      sum := sum + FSyncSamples[i];
      inc(Count);
    end;
  end;
  if Count > 0 then
      FPeerTimeDelta := sum div Count
  else
      FPeerTimeDelta := int64.MinValue;
end;

function TTCPClientSocketDeluxe.TNetworkSyncedClock.IsClockSyncComplete : boolean;
begin
  Result := FSyncSamples.Count >= SYNCCLOCKSAMPLES;
end;

constructor TTCPClientSocketDeluxe.TNetworkSyncedClock.Create(Socket : TTCPClientSocketDeluxe);
begin
  assert(Assigned(Socket));
  FSocket := Socket;
  FSyncRequestTimer := TTimer.Create(SYNCCLOCKDISTANCE);
  FSyncSamples := TAdvancedList<int64>.Create;
  // mark SyncedClock as not synced yet
  FPeerTimeDelta := int64.MinValue;
  FOwnClockType := ctHighPerformanceCounter;
end;

destructor TTCPClientSocketDeluxe.TNetworkSyncedClock.Destroy;
begin
  FSyncSamples.Free;
  FSyncRequestTimer.Free;
  inherited;
end;

function TTCPClientSocketDeluxe.TNetworkSyncedClock.GetPeerClockTimestamp : int64;
var
  PeerTimeDelta : int64;
begin
  PeerTimeDelta := FPeerTimeDelta;
  // if FPeerTimeDelta = integer.MinValue, clock is currently not synced
  if PeerTimeDelta <> int64.MinValue then
  begin
    Result := GetTimeStamp(FPeerClockType) + PeerTimeDelta;
  end
  else Result := -1;
end;

function TTCPClientSocketDeluxe.TNetworkSyncedClock.GetTimeStamp(ClockType : EnumClockType) : int64;
begin
  case ClockType of
    ctHighPerformanceCounter :
      begin
        assert(TimeManager.HighPerformanceCounter, 'Blame Tobi, because TTimeManager has a global variable that effect every class.');
        Result := TimeManager.GetTimeStamp;
      end;
    ctGetTickCount : Result := GetTickCount;
  else
    raise ENotImplemented.Create('TTCPClientSocketDeluxe.TNetworkSyncedClock.GetTimeStamp: Unsupported clocktype!');
  end;
end;

procedure TTCPClientSocketDeluxe.TNetworkSyncedClock.Idle;
begin
  // do sync process needs more samples and is the distance between samples long enough, then request another sample
  if (FSyncRequestsSended <= SYNCCLOCKSAMPLES) and FSyncRequestTimer.Expired then
  begin
    SendSyncRequest;
    // go for another round
    FSyncRequestTimer.Start;
  end;
end;

procedure TTCPClientSocketDeluxe.TNetworkSyncedClock.ProcessReSyncSample(Data : TDatapacket);
var
  ClockType : EnumClockType;
  peerTimeStamp : int64;
  localTimeStamp : int64;
  currentTimeStamp : int64;
  latency, timedelta : int64;
begin
  assert(Data.Command = COMMAND_RESYNCCLOCK);
  ClockType := Data.Read<EnumClockType>;
  // if clocktype has changed since the sync has changed, drop this package, because the values c
  if LocalClockType = ClockType then
  begin
    localTimeStamp := Data.Read<int64>;
    peerTimeStamp := Data.Read<int64>;
    currentTimeStamp := GetTimeStamp(ClockType);
    // dived RTT by 2 to get latency between local and peer (one direction instead of roundtrip)
    latency := (currentTimeStamp - localTimeStamp) div 2;
    timedelta := peerTimeStamp - (currentTimeStamp - latency);
    FSyncSamples.Add(timedelta);
    CalculatePeerTimeDelta;
  end;
end;

procedure TTCPClientSocketDeluxe.TNetworkSyncedClock.ProcessSyncSample(Data : TDatapacket);
var
  peerClockType : EnumClockType;
  peerTimeStamp : int64;
  localTimeStamp : int64;
  SendData : TCommandSequence;
begin
  // if a syncdata package was received, only need to send the package with some data back
  assert(Data.Command = COMMAND_SYNCCLOCK);
  peerClockType := Data.Read<EnumClockType>;
  peerTimeStamp := Data.Read<int64>;
  localTimeStamp := GetTimeStamp(peerClockType);
  SendData := TCommandSequence.Create(COMMAND_RESYNCCLOCK);
  SendData.AddData<EnumClockType>(peerClockType);
  SendData.AddData<int64>(peerTimeStamp);
  SendData.AddData<int64>(localTimeStamp);
  FSocket.SendDataInternal(SendData);
  SendData.Free;
end;

procedure TTCPClientSocketDeluxe.TNetworkSyncedClock.ReSyncPeerClock;
begin
  // first reset all status variables
  FSyncRequestsSended := 0;
  FSyncSamples.Clear;
  FSyncRequestTimer.Start;
  // and immediately send the first sync sample
  SendSyncRequest;
end;

procedure TTCPClientSocketDeluxe.TNetworkSyncedClock.SendSyncRequest;
var
  Data : TCommandSequence;
begin
  Data := TCommandSequence.Create(COMMAND_SYNCCLOCK);
  Data.AddData<EnumClockType>(LocalClockType);
  case LocalClockType of
    ctHighPerformanceCounter : Data.AddData<int64>(TimeManager.GetTimeStamp);
    ctGetTickCount : Data.AddData<int64>(GetTickCount);
  end;
  inc(FSyncRequestsSended);
  FSocket.SendDataInternal(Data);
  Data.Free;
end;

procedure TTCPClientSocketDeluxe.TNetworkSyncedClock.SetClockType(const Value : EnumClockType);
begin
  if FOwnClockType <> Value then
  begin
    FOwnClockType := Value;
    ReSyncPeerClock;
  end;
end;

{ TTCPClientSocket.TSendThread }

constructor TTCPClientSocket.TSendThread.Create(Socket : TTCPClientSocket);
var
  Uid : TGuid;
begin
  FSharedSendBuffer := TThreadSafeData<RawByteString>.Create('');
  CreateGuid(Uid);
  FDataAvailable := TEvent.Create(nil, True, False, GuidToString(Uid));
  FSocket := Socket;
  inherited Create(False);
end;

destructor TTCPClientSocket.TSendThread.Destroy;
begin
  inherited;
  FSharedSendBuffer.Free;
  FDataAvailable.Free;
  assert(LocalBuffer = '', 'Sendthreadbuffer was not empty on destroy socket.');
end;

procedure TTCPClientSocket.TSendThread.Execute;
var
  // data in localbuffer only exists here, so if this data is not sended, it will be lost forever
  BytesSended : integer;
  waitResult : TWaitResult;
begin
  NameThreadForDebugging('TCPClientSocketSendThread');
  FSocket.UseNagle := False;
  LocalBuffer := '';
  while not terminated do
  begin
    // wait for Event that signales that data is available
    waitResult := FDataAvailable.WaitFor(RECEIVESENDTIMEOUT);
    // only send data if signal was really triggered and not if timeout occurs or any other event occurs
    if waitResult = TWaitResult.wrSignaled then
    begin
      repeat
        // if event was triggerd, reset the event to not triggered
        // do it every loop iteration, because adding data to shared buffer will also set the data available event
        FDataAvailable.ResetEvent;
        // before send data, we have do gets the data from shared buffer
        FSharedSendBuffer.Lock;
        LocalBuffer := LocalBuffer + FSharedSendBuffer.Data;
        // now the shared data is in localbuffer and so it can be cleared from shared buffer
        FSharedSendBuffer.Data := '';
        FSharedSendBuffer.Unlock;
        // send data and handle error if any occurs
        if LocalBuffer <> '' then
        begin
          BytesSended := Winapi.WinSock2.Send(FSocket.FSocket, LocalBuffer[1], length(LocalBuffer), 0);
        end
        else
            BytesSended := 0;
        if BytesSended = SOCKET_ERROR then
        begin
          // abort sending data if any serious error occurs
          if FSocket.HandleError then
          begin
            LocalBuffer := '';
            exit;
          end;
        end
        else
        begin
          // log info
          InfoData.DataSended(BytesSended);
          // if all bytes sended, clear buffer, else only clear the bytes sended
          if BytesSended >= length(LocalBuffer) then
              LocalBuffer := ''
          else
              Delete(LocalBuffer, 1, BytesSended);
        end;
        // repeat the sendprogress if not all data could be sended with one send call
      until (LocalBuffer = '');
    end;
  end;
end;

procedure TTCPClientSocket.TSendThread.SendData(const Data : RawByteString);
begin
  // lock SendDataBuffer
  FSharedSendBuffer.Lock;
  // add new data to SendBuffer, don't discard existing data
  FSharedSendBuffer.Data := FSharedSendBuffer.Data + Data;
  FSharedSendBuffer.Unlock;
  // and finally set event to "wakeup" thread and resume send processing
  FDataAvailable.SetEvent;
end;

{ TTCPClientSocket.TReceiveThread }

constructor TTCPClientSocket.TReceiveThread.Create(Socket : TTCPClientSocket);
begin
  FSocket := Socket;
  inherited Create(False);
end;

procedure TTCPClientSocket.TReceiveThread.Execute;
var
  SocketFDSet : TFDSet;
  TimeOut : timeval;
  SelectResult, RecvBytes : integer;
  Buf : RawByteString;
begin
  NameThreadForDebugging('TCPClientSocketReceiveThread');
  // receiving data until thread is killed, if
  while not terminated do
  begin
    // one thread for one socket, so only check if this socket provide data
    SocketFDSet.fd_count := 1;
    SocketFDSet.fd_array[0] := FSocket.FSocket;
    // set timeout for wait for data, timeout is needed, to ensure that thread can
    // terminate in an reasonable time
    TimeOut.tv_sec := (RECEIVESENDTIMEOUT) div 1000;
    TimeOut.tv_usec := (RECEIVESENDTIMEOUT) mod 1000;
    // and now wait for data
    SelectResult := select(0, @SocketFDSet, nil, nil, nil);
    // receive data if the socket provide any data and has no error
    if (SelectResult > 0) and not(SelectResult = SOCKET_ERROR) then
    begin
      SetLength(Buf, MAXSEQUENCELENGTH);
      ZeroMemory(@Buf[1], MAXSEQUENCELENGTH);
      RecvBytes := Recv(FSocket.FSocket, Buf[1], length(Buf), 0);
      // if receiving was successfull redirect data to socket class
      if RecvBytes <> SOCKET_ERROR then
      begin
        SetLength(Buf, RecvBytes);
        if RecvBytes > 0 then
            FSocket.ProcessNewData(Buf);
      end
      // abort receive data if any serious error occurs
      else if FSocket.HandleError then
          exit;
    end
    else
    // if there was not data, check SelectResult of select for errors
    begin
      if SelectResult = SOCKET_ERROR then
      begin
        // abort receive data if any serious error occurs
        if FSocket.HandleError then
            exit;
      end;
    end;
  end;
end;

var
  ErrorCode : integer;

  { TTCPClientSocketDeluxe.TMaintainThread }

constructor TTCPClientSocketDeluxe.TMaintainThread.Create(Socket : TTCPClientSocketDeluxe);
begin
  FSocket := Socket;
  FPingTimer := TTimer.CreateAndStart(PINGINTERVALL);
  inherited Create(False);
end;

destructor TTCPClientSocketDeluxe.TMaintainThread.Destroy;
begin
  inherited;
  FPingTimer.Free;

end;

procedure TTCPClientSocketDeluxe.TMaintainThread.Execute;
var
  Data : TCommandSequence;
begin
  NameThreadForDebugging('TCPClientSocketDeluxeMaintainThread');
  while not terminated do
  begin
    // send ping
    if (Socket.AutoPing = True) then
    begin
      if FPingTimer.Expired then
      begin
        FPingTimer.Start;
        Data := TCommandSequence.Create(COMMAND_PING);
        inc(FLastPingIDSent);
        Data.AddData<Cardinal>(FLastPingIDSent);
        Data.AddData<int64>(TimeManager.GetTimeStamp);
        Socket.SendDataInternal(Data);
        Data.Free;
      end;
    end;
    Socket.PeerClock.Idle;
    // check if connection is lost (only if autocheck is active)
    if (Socket.DisconnectPingTimeOut > 0) and Socket.AutoPing and Socket.FLastPingReceived.Expired then
    begin
      Socket.Disconnect('Ping Timeout');
    end;
    // slow down maintain data to prevent thread from heavy load CPU
    // but not to slow, so thread can be killed within short time
    sleep(100);
  end;
end;

{ TWebSocketClient }

procedure TWebSocketClient.Connect(URI : string);
var
  ParsedUri : TIdUri;
  Protocol, Host : string;
  Port : Word;
  Request : TStringBuilder;
  Uid : TGuid;
  RequestPath, WebSocketKey : string;
begin

  ParsedUri := TIdUri.Create(URI);
  Request := TStringBuilder.Create;
  try
    Protocol := ParsedUri.Protocol;
    if not SameText(Protocol, 'ws') then
        raise EProtocolError.Create('TWebSocketClient.Connect: Current only "ws" protocol is supported for websockets.');
    Host := ParsedUri.Host;
    // default port for websocket is port 80 as http
    Port := Word(HGeneric.TertOp<integer>(not ParsedUri.Port.IsEmpty, ParsedUri.Port.ToInteger, 80));
    // connect to server using a standard tcp connection
    HLog.Write(elInfo, 'TWebSocketClient.Connect: Connecting to ' + URI);
    FSocket := TTCPClientSocketWS.Create(RInetAddress.CreateByUrl(Host, Port), self);
    HLog.Write(elInfo, 'TWebSocketClient.Connect: IsConnected ' + FSocket.IsConnected.ToString);
    // build HTTP GET request but with upgrade to signal server a websocket
    RequestPath := ParsedUri.Path + ParsedUri.Document;
    if not ParsedUri.Params.IsEmpty then
        RequestPath := RequestPath + '?' + ParsedUri.Params;
    Request.AppendLine('GET ' + RequestPath + ' HTTP/1.1');
    Request.AppendLine('Host: ' + ParsedUri.Host);
    Request.AppendLine('Upgrade: websocket');
    Request.AppendLine('Connection: Upgrade');
    Request.AppendLine('Origin: ' + ParsedUri.Protocol + '://' + ParsedUri.Host);
    CreateGuid(Uid);
    WebSocketKey := string(EncodeBase64(GUIDToRawByte(Uid)));
    Request.AppendLine('Sec-WebSocket-Key: ' + WebSocketKey);
    Request.AppendLine('Sec-WebSocket-Version: 13');
    // complete standard http request with empty line
    Request.AppendLine;
    FSocket.Send(AnsiString(Request.ToString));
    // create heartbeat thread to prevent server from disconnect client connection
    // cause of inactivity
    FHeartbeatThread.Free;
    FHeartbeatThread := THeartbeatThread.Create(self);
  finally
    Request.Free;
    ParsedUri.Free;
  end;
end;

constructor TWebSocketClient.Create;
begin
  FReceivedFrames := TThreadSafeObjectData < TQueue < TWebSocketClientFrame >>.Create(TQueue<TWebSocketClientFrame>.Create);
end;

destructor TWebSocketClient.Destroy;
begin
  Disconnect;
  FReceivedFrames.Free;
  inherited;
end;

procedure TWebSocketClient.Disconnect;
begin
  FreeAndNil(FHeartbeatThread);
  FreeAndNil(FSocket);
end;

function TWebSocketClient.IsConnected : boolean;
begin
  Result := Assigned(FSocket) and (FSocket.Status = TCPStConnected);
end;

function TWebSocketClient.IsDisconnected : boolean;
begin
  Result := not IsConnected;
end;

function TWebSocketClient.IsFrameAvailable : boolean;
begin
  FReceivedFrames.Lock;
  Result := FReceivedFrames.Data.Count > 0;
  FReceivedFrames.Unlock;
end;

procedure TWebSocketClient.ProcessNewData(const NewData : RawByteString);
var
  Frame, SendFrame : TWebSocketClientFrame;
  Sucessfull : boolean;
begin
  // parse non http data (starts NOT with HTTP)
  if not(Pos('HTTP', string(NewData)) > 0) then
  begin
    FReceiveBuffer := FReceiveBuffer + NewData;
    Sucessfull := True;
    while Sucessfull do
    begin
      Frame := TWebSocketClientFrame.Create;
      try
        Sucessfull := Frame.ParseFrame(FReceiveBuffer);
        if Sucessfull then
        begin
          // user data, add them as frame to list
          if Frame.Opcode in [ocText, ocBinary] then
          begin
            FReceivedFrames.Lock;
            FReceivedFrames.Data.Enqueue(Frame);
            FReceivedFrames.Unlock;
          end
          // whenever socket receives a ping answer with pong,
          // TODO: Add data received from ping to pong
          else if Frame.Opcode = ocPing then
          begin
            SendFrame := TWebSocketClientFrame.Create;
            SendFrame.Opcode := ocPong;
            SendFrame.Fin := True;
            FSocket.Send(SendFrame.BuildFrame);
            SendFrame.Free;
            Frame.Free;
          end
          else if Frame.Opcode = ocPong then
          begin
            // nothing todo as pong frame is only the reply for sended ping
            // frames
            Frame.Free;
          end
          else if Frame.Opcode = ocClose then
          begin
            // protocol says, receiving close frame should be replied with
            // close frame
            // see https://tools.ietf.org/html/rfc6455#section-1.4
            SendFrame := TWebSocketClientFrame.Create;
            SendFrame.Opcode := ocClose;
            SendFrame.Fin := True;
            if Assigned(FSocket) then
                FSocket.Send(SendFrame.BuildFrame);
            SendFrame.Free;
            Frame.Free;
            Disconnect;
          end
          else
              Frame.Free;
        end
        else
            Frame.Free;
      except
        on E : EProtocolError do
            Frame.Free;
      end;
    end;
  end
  else
    if not(Pos('HTTP/1.1 101 Switching Protocols', string(NewData)) > 0) then
      HLog.Write(elWarning, 'TWebSocketClient.ProcessNewData: ' + string(NewData));
end;

function TWebSocketClient.ReceiveFrame : TWebSocketClientFrame;
begin
  FReceivedFrames.Lock;
  if FReceivedFrames.Data.Count > 0 then
      Result := FReceivedFrames.Data.Dequeue
  else
      Result := nil;
  FReceivedFrames.Unlock;
end;

{ TWebSocketClient.TTCPClientSocketWS }

constructor TWebSocketClient.TTCPClientSocketWS.Create(const ServerInetAdress : RInetAddress; WebsocketClient : TWebSocketClient);
begin
  FWebsocketClient := WebsocketClient;
  inherited Create(ServerInetAdress);
end;

function TWebSocketClient.TTCPClientSocketWS.IsConnected : boolean;
begin
  Result := Assigned(FWebsocketClient) and FWebsocketClient.IsConnected;
end;

procedure TWebSocketClient.TTCPClientSocketWS.ProcessNewData(const NewData : RawByteString);
begin
  FWebsocketClient.ProcessNewData(NewData);
end;

{ TWebSocketClientFrame }

function TWebSocketClientFrame.BuildFrame : RawByteString;
var
  Stream : TMemoryStream;
  Data : Byte;
begin
  Stream := TMemoryStream.Create;
  Data := 0;
  if Fin then
      Data := Data or FIN_BITMASK;
  case Opcode of
    ocContinuation : Data := Data or OPCODE_CONTINUATION_FRAME;
    ocText : Data := Data or OPCODE_TEXT_FRAME;
    ocBinary : Data := Data or OPCODE_BINARY_FRAME;
    ocClose : Data := Data or OPCODE_CLOSE_CONNECTION;
    ocPing : Data := Data or OPCODE_PING;
    ocPong : Data := Data or OPCODE_PONG;
  end;
  Stream.WriteByte(Data);
  assert(length(FPayload) = 0);
  // no payload, no mask
  Data := 0;
  Stream.WriteByte(Data);
  Stream.Position := 0;
  SetLength(Result, Stream.Size);
  Stream.ReadBuffer(Result[1], Stream.Size);
  Stream.Free;
end;

constructor TWebSocketClientFrame.Create;
begin
end;

destructor TWebSocketClientFrame.Destroy;
begin
  inherited;
end;

function TWebSocketClientFrame.GetTextPayload : string;
begin
  Result := Utf8ToString(FPayload);
end;

function TWebSocketClientFrame.ParseFrame(var FrameData : RawByteString) : boolean;
var
  Stream : TMemoryStream;
  Data : Byte;
  OpcodeData : Byte;
  PayloadLength : UInt64;
  PayloadMasked : boolean;
begin
  Result := False;
  // only parse data if at least header data is present
  if length(FrameData) >= 2 then
  begin
    Stream := TMemoryStream.Create;
    try
      Stream.WriteBuffer(FrameData[1], length(FrameData));
      Stream.Position := 0;
      Stream.ReadData(Data);
      FFin := (Data and FIN_BITMASK) <> 0;
      OpcodeData := Data and OPCODE_BITMASK;
      case OpcodeData of
        OPCODE_CONTINUATION_FRAME : FOpcode := ocContinuation;
        OPCODE_TEXT_FRAME : FOpcode := ocText;
        OPCODE_BINARY_FRAME : FOpcode := ocBinary;
        OPCODE_CLOSE_CONNECTION : FOpcode := ocClose;
        OPCODE_PING : FOpcode := ocPing;
        OPCODE_PONG : FOpcode := ocPong;
      end;
      Stream.ReadData(Data);
      PayloadLength := Data and PAYLOAD_LENGTH_BITMASK;
      PayloadMasked := (Data and MASK_BITMASK) > 0;
      assert(not PayloadMasked);
      if PayloadLength = 126 then
          PayloadLength := Swap(Stream.ReadWord)
      else if PayloadLength = 127 then
          PayloadLength := Swap64(Stream.ReadAny<UInt64>);
      if Stream.Size - Stream.Position >= PayloadLength then
      begin
        if PayloadLength > 0 then
        begin
          SetLength(FPayload, PayloadLength);
          Stream.ReadBuffer(FPayload[1], PayloadLength);
        end
        else
            FPayload := '';
        // delete all parsed data
        Delete(FrameData, 1, Stream.Position);
        Result := True;
      end;
    finally
      Stream.Free;
    end;
  end;
end;

function TWebSocketClientFrame.PayloadAsJson : TJsonData;
begin
  Result := TJSONSerializer.ParseJSON(TextPayload);
end;

procedure TWebSocketClientFrame.SetTextPayload(const Value : string);
begin

end;

{ TWebSocketClient.THeartbeatThread }

constructor TWebSocketClient.THeartbeatThread.Create(WebSocket : TWebSocketClient);
begin
  FWebSocket := WebSocket;
  FHeartbeatTimer := TTimer.Create(HEARTBEAT_INTERVAL);
  inherited Create(False);
end;

destructor TWebSocketClient.THeartbeatThread.Destroy;
begin
  inherited;
  FHeartbeatTimer.Free;
end;

procedure TWebSocketClient.THeartbeatThread.Execute;
var
  PingFrame : TWebSocketClientFrame;
begin
  while not terminated do
  begin
    if FHeartbeatTimer.Expired and FWebSocket.IsConnected then
    begin
      PingFrame := TWebSocketClientFrame.Create;
      PingFrame.Opcode := ocPing;
      PingFrame.Fin := True;
      if Assigned(FWebSocket.FSocket) then
          FWebSocket.FSocket.Send(PingFrame.BuildFrame);
      PingFrame.Free;
      FHeartbeatTimer.Start;
    end
    else sleep(500);
  end;
end;

initialization

ErrorCode := WSAStartup(MakeWord(2, 2), GlobalwsaData);
if ErrorCode <> 0 then
    HandleWSAError(ErrorCode);
InfoData := TNetworkInfoData.Create;

finalization

WSACleanup;
FreeAndNil(InfoData);

end.
