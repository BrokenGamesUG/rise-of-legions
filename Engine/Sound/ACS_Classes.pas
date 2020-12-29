(*
  This file is a part of New Audio Components package 2.6
  Copyright (c) 2002-2010, Andrei Borovsky. All rights reserved.
  See the LICENSE file for more details.
  You can contact me at anb@symmetrica.net
*)

(* $Id: ACS_Classes.pas 1246 2010-07-22 09:54:46Z andrei.borovsky $ *)

unit ACS_Classes;

(* Title: ACS_Classes 
    NewAC core classes. *)

interface

uses

{$IFDEF WIN32}
  Windows,
{$ENDIF}
  {FastMove,} Classes, SysUtils, SyncObjs,
  ACS_Types, ACS_Procs, ACS_Tags;

type

  TOutputStatus = (tosPlaying, tosPaused, tosIdle);

  TFileOutputMode = (foRewrite = 0, foAppend);

  TOutputFunc = function(Abort : Boolean):Boolean of object;

  //TThreadDoneEvent = procedure of object;

  TThreadExceptionEvent = procedure(Sender : TComponent) of object;

  THandleException = procedure(Sender : TComponent; const Msg : String) of object;

  TOutputDoneEvent = procedure(Sender : TComponent) of object;

  TOutputProgressEvent = procedure(Sender : TComponent) of object;

  TGenericEvent = procedure(Sender : TComponent) of object;

{$IFDEF LINUX}
// File access mask constants
const

  famUserRead = 64;
  famUserWrite = 128;
  famGroupRead = 8;
  famGroupWrite = 16;
  famOthersRead = 1;
  famOthersWrite = 2;

{$ENDIF}

type

  EAuException = class(Exception)
  end;

  (* Class: TAuFileStream
      TFileStream analog that handles Unicode. *)

  TAuFileStream = class(THandleStream)
  public
    constructor Create(const FileName: WideString; Mode: Word); overload;
    constructor Create(const FileName: WideString; Mode: Word; Rights: Cardinal); overload;
    destructor Destroy; override;
  end;

  (* Class: TAuThread
      Custom TThread descendant that does something. *)

  TAuThread = class(TThread)
  private
    PauseEvent : TEvent;
    SoftSleepEvent : TEvent;
  public
    DoNotify : Boolean; // Flag that determines if OnDone should be raised a the end of output
                        // default value is True, may be set to False in Stop method.
    Stopped : Boolean;  // Flag that tells when the output is actually stopped.
                        // Used when DoNotify is set to False.
    Parent : TComponent;
//    bSuspend : Boolean;
    Stop : Boolean;
    SetPause, Paused : Boolean;
    Delay : Integer;
    Sleeping : Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure WaitForPause;
    procedure Execute; override;
    procedure SoftSleep;
    procedure SoftWake;
    procedure SoftPause;
  end;

(* Class: TAuInput
    The ancestor class for all input components. *)

  TAuInput = class(TComponent)
  protected
    FPosition : Int64;
    FSize : Int64; // total _uncompressed_ audio stream size in bytes
    FSampleSize : Word; // size of one frame in bytes (fot 16 bps stereo FSampleSize is 4).
    FSeekable : Boolean;
    Busy : Boolean;
    BufStart, BufEnd : LongWord;
    DataCS : TCriticalSection;
    _EndOfStream : Boolean;
    FFloatRequested : Boolean;
    (* We don't declare the buffer variable here
     because different descendants may need different buffer sizes *)
    function GetBPS : LongWord; virtual; abstract;
    function GetCh : LongWord; virtual; abstract;
    function GetSR : LongWord; virtual; abstract;
    function GetTotalTime : LongWord; virtual;
    function GetTotalSamples : Int64; virtual;
    procedure InitInternal; virtual; abstract;
    procedure FlushInternal; virtual; abstract;
    procedure GetDataInternal(var Buffer : Pointer; var Bytes : LongWord); virtual; abstract;
    procedure SetRequestFloat(rf : Boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    (* Procedure: GetData
        This method retrieves input data. You specify the number of bytes you
        want to get, but you may get less and it should not be considered as
        an end of input indication. When the end of input is reached GetData
        sets Buffer to nil and Bytes to 0.


      Parameters:

        Buffer - This is the variable where GetData will put a pointer to a
          data buffer. Unlike many other data reading functions GetData
          doesn't take our buffer pointer but provides you with its own.
        Bytes - When you call GetData you pass to Bytes the number of bytes
          you want to get. When the method returns the Bytes variable holds
          the number of bytes in the Buffer.

      Note:
      Usually you should not call this method directly.
    *)
    procedure GetData(var Buffer : Pointer; var Bytes : LongWord); virtual;
    (* Function: CopyData
        Writes no more than BufferSize data into Buffer

      Parameters:

        Buffer: Pointer - the buffer to write to
        BufferSize: Integer - the number of bytes to write
    *)
    function CopyData(Buffer : Pointer; BufferSize : Integer) : LongWord;
    (* Function: FillBuffer
        The same as <CopyData> but tries to fill the Buffer. EOF is set to
        True if end of data was reached while filling the buffer, the buffer
        itself may still contain valid data.

      Parameters:

        Buffer: Pointer - the buffer to write to
        BufferSize: Integer - the number of bytes to write
        var EOF: Boolean - set to True if end of data was reached while filling
          the buffer.

      Returns:

        Integer - Number of bytes written
    *)
    function FillBuffer(Buffer : Pointer; BufferSize : LongWord; var EOF : Boolean) : LongWord;
    function FillBufferUnprotected(Buffer : Pointer; BufferSize : LongWord; var EOF : Boolean) : LongWord;
    procedure Reset; virtual;

    (* Procedure: Init
     This method prepares input component for reading data. Usually this
     method is called internally by the output or converter component to which
     the input component is assigned. You can call this method if you want to
     get direct access to the audio stream. In such a case the sequence of
     calls should look like this.

  > InputComponent.Init;
  > InputComponent.GetData(...); // in a loop
  > InputComponent.Flush;
    *)
    procedure Init;// virtual;

    (* Procedure: Flush

    This method closes the current input (opened with <Init>), clearing up all
    temporary structures allocated during data transfer. Usually this method is
    called internally by the output or converter component to which the input
    component is assigned. You can call this method if you want to get direct
    access to the audio stream. In such a case the sequence of calls should
    look like this.

  > InputComponent.Init;
  > InputComponent.GetData(...); // in a loop
  > InputComponent.Flush;
    *)
    procedure Flush;
    procedure _Lock;
    procedure _Unlock;
    procedure _Pause; virtual;
    procedure _Resume; virtual;
    procedure _Jump(Offs : Integer); virtual;
    (* Property: BitsPerSample
       The number of bits per sample in the input stream. Possible values are 8, 16, and 24.*)
    property BitsPerSample : LongWord read GetBPS;
    property IsBusy : Boolean read Busy;
    (* Property: Position
       The current reading position in the input stream in bytes.*)
    property Position : Int64 read FPosition;
    (* Property: SampleRate
       The input stream sample rate in Herz.*)
    property SampleRate : LongWord read GetSR;
    (* Property: Channels
       The number of channels in the input stream. Possible values are 1 (mono), 2 (stereo)... and may be more.*)
    property Channels : LongWord read GetCh;

    (* Property: Size
        A read only property which returns input data size in bytes. The value
        of this property becomes valid after <Init> has been called. For some
        inputs (like <TDXAudioIn>) the data size may be not known in advance.
        In this case Size returns -1  *)
    property Size : Int64 read FSize;

    (* Property: TotalSamples
        A read only property which returns number of samples (frames) in the
        input stream. TotalSamples value may be valid only if the <Size> of
        the input is known.
    *)
     property TotalSamples : Int64 read GetTotalSamples;
    (* Property: TotalTime
        A read only property which returns input playback time in seconds.
        TotalTime value may be valid only if the <Size> of the input is known.
    *)
    property TotalTime : LongWord read GetTotalTime;
   (* Property: Seekable
    This read only property indicates when the input is seekable. *)
    property Seekable : Boolean read FSeekable;
    property RequestFloat : Boolean read FFloatRequested write SetRequestFloat;
  end;

(* Class: TAuOutput
    The ancestor class for all output components. *)

  TAuOutput = class(TComponent)
  protected
    FStopped : Boolean; // indicates that the output is terminated by calling Stop
                        // So that Done could know the output is stopped forcibly. Currently only TWaveOut usese this.
                        // Set to True by Stop and to False in WhenDone.
    FExceptionMessage : String;
    CanOutput : Boolean;
    CurProgr : Integer;
    Thread : TAuThread;
    FInput : TAuInput;
    FOnDone : TOutputDoneEvent;
    FOnSyncDone : TOutputDoneEvent;
    FOnProgress : TOutputProgressEvent;
    Busy : Boolean;  // Set to true by Run and to False by WhenDone.
    FOnThreadException : TThreadExceptionEvent;
    RunCS : TCriticalSection;
    function GetPriority : {$IFDEF LINUX} Integer; {$ENDIF} {$IFDEF WIN32} TThreadPriority; {$ENDIF}
    function GetProgress : Integer;
    procedure SetInput(vInput : TAuInput); virtual;
    procedure SetPriority(Priority : {$IFDEF LINUX} Integer {$ENDIF} {$IFDEF WIN32} TThreadPriority {$ENDIF});
    procedure WhenDone; // Calls descendant's Done method
    function GetTE : Integer;
    function GetStatus : TOutputStatus;
    function DoOutput(Abort : Boolean):Boolean; virtual; abstract;
    procedure Done; virtual; abstract; // Calls FInput.Flush
    procedure Prepare; virtual; abstract; // Calls FInput.init
    function GetDelay : Integer;
    procedure SetDelay(Value : Integer);
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    {$IFDEF WIN32}
    procedure Abort;
    {$ENDIF}
    (* Procedure: Pause
       Pauses the output. *)
    procedure Pause;
    (* Procedure: Resume
        Resumes previously paused output. *)
    procedure Resume;
    (* Procedure: Run
        After an input component has been assigned, call Run to start the
        audio processing chain. When called, Run returns at once while the
        actual audio processing goes on in the different thread. You will get
        <OnProgress> events while audio processing continues and an <OnDone>
        event when the job is done.*)
    procedure Run;
    (* Procedure: BlockingRun
        In some situations, such as console programs or DUnit test units,
        background processing is not desirable. In these cases, call
        BlockingRun to run the output component and wait until all operations
      	are complete before returning from the method. It is only fair to note
      	that since there is no way to abort, pause, or stop the procedure once
      	it has started, if used improperly this method can lock your program.
      	If you are unsure which method to use, use the <Run> method. Under
      	normal circumstances, call <Run> to allow audio processing to go on in
      	the background while your application is free to respond to events. *)
    procedure BlockingRun;
    (* Procedure: Stop
      Stops the busy component or does nothing if the component is idle.

      Parameters:
         Async: Boolean = True - If this parameter value is set to True (the
         default), Stop is called in an asynchronous mode. In this mode the
         method returns at once and OnDone event is raised when output is
         actually finished.
         If this parameter is set to False the Stop method
         is called in blocking mode. In this mode it returns only after the output
         is actually done. No event is raised in this case.*)
    procedure Stop(Async : Boolean = True);
    // Please describe Delay.
    (* Property: Delay
        Sets the delay, affects CPU usage. *)
    property Delay : Integer read GetDelay write SetDelay;
    (* Property: ThreadPriority
        This property allows you to set the priority of the output thread.*)
    property ThreadPriority : {$IFDEF LINUX} Integer {$ENDIF} {$IFDEF WIN32} TThreadPriority {$ENDIF} read GetPriority write SetPriority;
    (* Property: Progress
        Read Progress to get the output progress in percents.
        This value is meaningful only after the input component has been set
        and only if the input component can tell the size of its stream.*)
    property Progress : Integer read GetProgress;
    (* Property: Status
        This read only property indicates the output component's current status.
        Possible values are:

        tosPlaying - the component is performing its task;
        tosPaused - the component is paused (the <Pause> method was called)
        tosIdle - the component is idle
    *)
    property Status : TOutputStatus read GetStatus;
    (* Property: TimeElapsed
       The time in seconds that has passed since the playback was started.
       Useful for real time components like <TDXAudioOut>.*)
    property TimeElapsed : Integer read GetTE;
    (* Property: ExceptionMessage
       Most exceptions that may occur during NewAC operation are suppressed.
       If an exception occurs, the operation is stopped and the
       <OnThreadException> event is raised. ExceptionMessage holds the
       exception text. *)
    property ExceptionMessage : String read FExceptionMessage;
  published
    (* Property: Input
       This property allows you to set the input component for the output
       component. The valid input components must be descendants of
       <TAuInput>. *)
    property Input : TAuInput read Finput write SetInput;
    (* Property: OnDone
       Raised when the component has finished its job or was stopped
       asynchronously. From this event handler you can perform any action on
       the output component, even remove the component itself! *)
    property OnDone : TOutputDoneEvent read FOnDone write FOndone;
    (* Property: OnProgress
       OnProgress event is raised periodically to indicate output progress.
       Use <Progress> property to get the progress value. OnProgress event is
       sent asynchronously and you can perform any action on the output
       component from the event handler. *)
    property OnProgress : TOutputProgressEvent read FOnProgress write FOnProgress;
    (* Property: OnThreadException
       This event is raised if an exception has occurred. Exception string is stored in <ExceptionMessage>. *)
    property OnThreadException : TThreadExceptionEvent read FOnThreadException write FOnThreadException;
   (* Property: OnSyncDone
      The synchronous analogue of the <OnDone> event. This event is called from an audio output thread and is not synchronized with the main (GUI) thread so be careful with the methods you call from the handler.
      DO NOT modify any of your GUI controls from this event's handler *)
    property OnSyncDone : TOutputDoneEvent read FOnSyncDone write FOnSyncDone;
  end;

(* Class: TAuStreamedInput
    A descendant of <TAuInput> to deal with streams. *)

  TAuStreamedInput = class(TAuInput)
  protected
    FStream : TStream;
    FStreamAssigned : Boolean;
    FStartSample, FEndSample : Int64;
    FLoop : Boolean;
    FTotalSamples : Int64;
    procedure SetStream(aStream : TStream); virtual;
    (* Function: SeekInternal
      This abstract method should be overridden with an implementation
      dependong on whether your input component is seekable or not. If your
      component is not seekable then you can write a method like the following.
      
      > function TMyComponent.SeekInternal(var SampleNum : Int64) : Boolean;
      > begin
      >   Result := False;
      > end;
      
      If you want to make your component seekable you have to implement real
      seeking in this function. *)
    function SeekInternal(var SampleNum : Int64) : Boolean; virtual; abstract;
     (* Property: EndSample
        Set this property's value to the sample (frame) you want the input to
        stop playing at. By default it is set to -1 which indicates "play to
        the end of input." Changing this property value has an effect only
        when the component is idle. *)
    property EndSample : Int64 read FEndSample write FEndSample;
    (* Property: Loop
        If set to True, the input loops (i.e. starts again from the beginning
        after it is finished). *)
    property Loop : Boolean read FLoop write FLoop;
    (* Property: StartSample
        Set this property's value to the sample (frame) you want the input to
        start playing from. By default it is set to 0. Calling the <Seek>
        method when the component is idle has the same effect. Note that when
        you set <StartSample> and <EndSample> properties you define a subrange
        of the input data. All further operations, such as playback and
        <Seek>ing will be performed within this subrange. The StartSample and
        <EndSample> values also affect the <TotalSamples> and <Size> values,
        returned by the component. *)
    property StartSample : Int64 read FStartSample write FStartSample;
  public
    (* Property: Stream
      Use this property to set the input data stream for the input component.
      Any TStream descendant may be used as a data source. Note that if you
      set Stream, you own it, that is you have to create, destroy and position
      the stream explicitly (the data playback will be started from the current position within the stream). In TAuFileIn descendants the value assigned to
      this property takes over the FileName property, i. e. if both Stream and
      FileName properties are assigned, the stream and not the file will be
      used for the actual input. To unassign this property set it to nil. If
      the stream is seekable it will be reset to the beginning at the end of
      the playback. *)
    property Stream : TStream read FStream write SetStream;
    procedure GetData(var Buffer : Pointer; var Bytes : LongWord); override;
    (* Function: Seek
        This method allows you to change the current playing position in the
        the input component. If the input component is stopped or paused,
        calling Seek sets the sample from which the playback will begin. Note
        that not all inputs are seekable.

      Parameters:
        SampleNum - The number of sample (frame) to play from. This number is
          set relative to the value of <StartSample>.

      Returns:
        Boolean - A False value indicates that either a seek failed (you are
          seeking beyond the end of file or the <EndSample> value) or that the
          input stream is not seekable.
    *)
    function Seek(SampleNum : Int64) : Boolean;
    constructor Create(AOwner: TComponent); override;
  end;

  TAuSeekableStreamedInput = class(TAuStreamedInput)
    public
      property StartSample;
      property EndSample;
  end;

(* Class: TAuStreamedOutput
    A descendant of <TAuOutput> to deal with streams. *)

  TAuStreamedOutput = class(TAuOutput)
  protected
    FStream : TStream;
    FStreamAssigned : Boolean;
    procedure SetStream(aStream : TStream);
  public
    property Stream : TStream read FStream write SetStream;
  end;

  (* Class: TAuFileIn
      A descendant of <TAuStreamedInput> to deal with files and streams.
      All the components that read files descend from this class. *)

  TAuFileIn = class(TAuStreamedInput)
  private
    procedure SetWideFileName(const FN : WideString);
    procedure SetFileName(const FN : TFileName);
  protected
    OpenCS : TCriticalSection;
    FFileName : TFileName; // Used only for display
    FWideFileName : WideString;
    FOpened : Integer;
    FValid : Boolean;
    FBPS : LongWord;  // bits per sample
    FSR : LongWord;   // sample rate
    FChan : LongWord; // Number of channels
    FTime : LongWord;
    function GetBPS : LongWord; override;
    function GetCh : LongWord; override;
    function GetSR : LongWord; override;
//    function GetTime : Integer;
    function GetValid : Boolean;
    function GetTotalSamples : Int64; override;
    procedure SetStream(aStream : TStream); override;

    (* Note on FSize calculation:
      FSize is calculated in OpenFile method as the FULL file size. More
      precise calculations regarding StartSample/EndSample are done in Init.
      *)

    (* Procedure: OpenFile
        Opens the file or stream if it is not already open. For performance
        reasons the file is opened when any of its data is accessed the first
        time and is then kept open until it is done with. The descendants'
        FileOpen implementations use the FOpened constant to check if the file
        is already opened.

        Note:
        This method is called internally by <TAuInput.Init>, you should never
        call it directly. *)
    procedure OpenFile; virtual; abstract;
    (* Procedure: CloseFile
        Closes the file opened with <OpenFile>. Sets the FOpened constant to
        0.

        Note:
        This method is called internally by <TAuInput.Flush>, you should never
        call it directly. *)
    procedure CloseFile; virtual; abstract;
    function GetTotalTime : LongWord; override;
    procedure FlushInternal; override;
    procedure InitInternal; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    (* Function: SetStartTime
      This function is a wrapper around StartSample property, provided for convenience.
      It allows you to set playback start position in minutes and seconds.
      
      Parameters:
        Minutes : LongWord - Minutes 
        Seconds : LongWord - Seconds 
        
    Note:
    
    > SetStartTime(1, 30);
    and
    > SetStartTime(0, 90);
    are both allowed.
    *)
    function SetStartTime(Minutes, Seconds : LongWord) : Boolean;
    (* Function: SetEndTime
      This function is a wrapper around EndSample property, provided for
      convenience. It allows you to set playback stop position in minutes and
      seconds.

      Parameters:
        Minutes : LongWord - Minutes 
        Seconds : LongWord - Seconds 
    *)
    function SetEndTime(Minutes, Seconds : LongWord) : Boolean;
    procedure Reset; override;
    procedure _Jump(Offs : Integer); override;
//    property Time : Integer read GetTime;
    (* Property: Valid
      Read this property to determine if the file is valid. It is a good
      practice to check this property before performing other operations on
      audio stream. Note however that True returned by Valid doesn't guarantee
      the file is fully playable. It indicates only that the file could be
      opened successfully and the file headers were correct.
      This property also returns False if the decoder library required to play the file cannot be loaded. *)
    property Valid : Boolean read GetValid;
    (* Property: WideFileName
        Allows you to handle file names in Unicode. Setting its value
        overrides the value set to FileName. *)
    property WideFileName : WideString read FWideFileName write SetWideFileName;
  published
    (* Property: Filename
        File name in 8-bit encoding. Setting this property's value overrides
        the value set to <WideFileName>. *)
    property FileName : TFileName read FFileName write SetFileName stored True;
    property Loop;
  end;

  (* Class: TAuTaggedFileIn
      Descends from <TAuFileIn>, this class is an ancestor of the file input
      components that use tags. *)

  TAuTaggedFileIn = class(TAuFileIn)
  private
    FId3v1Tags: TId3v1Tags;
    FId3v2Tags: TId3v2Tags;
    FAPEv2Tags: TAPEv2Tags;
    FCommonTags : TCommonTags;

    procedure SetId3v1Tags(Value: TId3v1Tags);
    procedure SetId3v2Tags(Value: TId3v2Tags);
    procedure SetAPEv2Tags(Value: TAPEv2Tags);
    procedure SetCommonTags(Value: TCommonTags);
  protected
(* Ross--- *)
    property _Id3v1Tags: TId3v1Tags read FId3v1Tags write SetId3v1Tags;
    property _Id3v2Tags: TId3v2Tags read FId3v2Tags write SetId3v2Tags;
    property _APEv2Tags: TAPEv2Tags read FAPEv2Tags write SetAPEv2Tags;
(* ---Ross *)
    property _CommonTags : TCommonTags read FCommonTags write SetCommonTags;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    (* Property: CommonTags
       Contains the tag values common to the different tag formats *)
    property CommonTags : TCommonTags read FCommonTags;
  end;

  (* Class: TAuFileOut
      A descendant of <TAuStreamedOutput> to deal with files and streams. *)

  TAuFileOut = class(TAuStreamedOutput)
  private
    procedure SetWideFileName(const FN : WideString);
    procedure SetFileName(const FN : TFileName);
  protected
    FFileName : TFileName; // Used for display only
    FWideFileName : WideString;
    FFileMode : TFileOutputMode;
    FAccessMask : Integer;
    FShareMode :  Word;
    procedure SetFileMode(aMode : TFileOutputMode); virtual;
    (* Property: FileMode
       This property can take one of two values foRewrite (default) and
       foAppend. In the foRewrite mode the new file overwrites the previous
       one (if it existed). In the foAppend mode the new content is added to
       the existing. Currently only <TWaveOut> and <TVorbisOut> components
       support this mode. *)
    property FileMode : TFileOutputMode read FFileMode write SetFileMode;
  public
    constructor Create(AOwner: TComponent); override;
{$IFDEF LINUX}
    property AccessMask : Integer read FAccessMask write FAccessMask;
{$ENDIF}
    (* Property: WideFileName
        Allows you to handle file names in Unicode. Setting its value
        overrides the value set to FileName. *)
    property WideFileName : WideString read FWideFileName write SetWideFileName;
  published
    (* Property: Filename
        File name in 8-bit encoding. Setting this property's value overrides
        the value set to <WideFileName>. *)
    property FileName : TFileName read FFileName write SetFileName;
    (* Property: ShareMode
        This property stores the share mode flags (like fmShareExclusive, fmShareDenyRead) that are applied to the files being created.
        Since Delphi 2010 has some problems with these flags, the default value is zero.
    *)
    property ShareMode : Word read FShareMode write FShareMode;
  end;

  (* Class: TAuTaggedFileOut
      Descends from <TAuFileOut>, this class is an ancestor of the file output
      components that use Id3v* tags. *)

  TAuTaggedFileOut = class(TAuFileOut)
  private
(* Ross--- *)
    FId3v1Tags: TId3v1Tags;
    FId3v2Tags: TId3v2Tags;
    FAPEv2Tags: TAPEv2Tags;

    procedure SetId3v1Tags(Value: TId3v1Tags);
    procedure SetId3v2Tags(Value: TId3v2Tags);
    procedure SetAPEv2Tags(Value: TAPEv2Tags);
(* ---Ross *)
  protected
(* Ross--- *)
    property Id3v1Tags: TId3v1Tags read FId3v1Tags write SetId3v1Tags;
    property Id3v2Tags: TId3v2Tags read FId3v2Tags write SetId3v2Tags;
    property APEv2Tags: TAPEv2Tags read FAPEv2Tags write SetAPEv2Tags;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
(* ---Ross *)
  end;

   (* Class: TAuConverter
      Descends from <TAuInput>, the base class for all converter components.
      Converters are laced between input and output in the audio-processing chain.
      See NewAC Introduction for more information on the converters. *)

  TAuConverter = class(TAuInput)
  protected
    FInput : TAuInput;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetInput(aInput : TAuInput); virtual;
    function GetBPS : LongWord; override;
    function GetCh : LongWord; override;
    function GetSR : LongWord; override;
  public
    procedure GetData(var Buffer : Pointer; var Bytes : LongWord); override;
    procedure _Pause; override;
    procedure _Resume; override;
    procedure _Jump(Offs : Integer); override;
  published
    (* Property: Input
       Like the output components, converters can be assigned an input. Unlike
       the output components converters themselves can be input sources (for
       output components and other converters). *)
    property Input : TAuInput read FInput write SetInput;
  end;

 (* Class: TAudioTap
      This is the base class for all "audio tap components". Technically audio
      taps are converters as they sit between input and output components in
      the audio-processing chain. But audio taps do not modify audio data
      passing trough them. Instead they write everithing passing through into
      some audio file.

      The main goal of audio tap components is to make the audio-processing
      chain to perform several tasks at once: record while you listen, save
      data at several formats simultaneously, etc.

      Descends from <TAuConverter>.
 *)
 
  TAudioTap = class(TAuConverter)
  private
    function GetStatus : TOutputStatus;
    procedure SetFileName(Value : String);
    procedure SetWideFileName(Value : WideString);
  protected
    FFileName : String;
    FWideFileName : WideString;
    FRecording, FStarting, FPaused, FStopping : Boolean;
    procedure StartRecordInternal; virtual; abstract;
    procedure StopRecordInternal; virtual; abstract;
    procedure WriteDataInternal(Buffer : Pointer; BufferLength : LongWord); virtual; abstract;
    function GetBPS : LongWord; override;
    function GetCh : LongWord; override;
    function GetSR : LongWord; override;
    procedure GetDataInternal(var Buffer : Pointer; var Bytes : LongWord); override;
    procedure InitInternal; override;
    procedure FlushInternal; override;
  public
    procedure _Pause; override;
    procedure _Resume; override;
    (* Procedure: StartRecord
       Call this method to start recording audio data passing through an audio tap. *)
    procedure StartRecord;
    (* Procedure: StopRecord
       Call this method to stop recording. *)
    procedure StopRecord;
    (* Procedure: PauseRecord
       Call this method to pause recording. *)
    procedure PauseRecord;
    (* Procedure: ResumeRecord
       Call this method to resume paused recording. *)
    procedure ResumeRecord;
    (* Property: Status
       Read this property to get the component status.
       The possible values are tosIdle (the component passes data through without recording),
       tosPlaying (the component records data) and tpsPaused. *)
    property Status : TOutputStatus read GetStatus;
    (* Property: WideFileName
       Use this property to set or get the file name the data is written to in Unicode charset.
       The value assigned to this prperty overrides <FileName> *)
    property WideFileName : WideString read FWideFileName write SetWideFileName;
  published
    (* Property: FileName
       Use this property to set or get the file name the data is written to in 8-bit charset.
       The value assigned to this prperty overrides <WideFileName> *)
    property FileName : String read FFileName write SetFileName;
  end;


const

  STREAM_BUFFER_SIZE = $100000;

type

  TEventType = (etOnProgress, etOnDone, etGeneric, etNonGUI);

  TEventRecord = record
    _type : TEventType;
    Sender : TComponent;
    case i : Integer of
      1 : (DoneEvent : TOutputDoneEvent; Thread : TAuThread;);
      2 : (ProgressEvent : TOutputProgressEvent;);
      3 : (GenericEvent : TGenericEvent;);
   end;

   PEventRecord = ^TEventRecord;

  (*
   This is an internal class, no urgent need to document it.
   *)

  TEventHandler = class(TThread)
  private
    Events : TList;
    CS : TCriticalSection;
    _Evt : TEvent;
    CurrentEvent : PEventRecord;
    BlockedSender : TComponent;
    procedure AddEvent(Event : PEventRecord);
    procedure PrependEvent(Event : PEventRecord);
    function GetEvent : PEventRecord;
    procedure CallHandler;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PostOnProgress(Sender : TComponent; Handler :TOutputProgressEvent);
    procedure PostOnDone(Sender : TComponent; Thread : TAuThread);
    procedure PostGenericEvent(Sender : TComponent; Handler : TGenericEvent);
    procedure PostNonGuiEvent(Sender : TComponent; Handler : TGenericEvent);
    procedure Execute; override;
    procedure ClearEvents(Sender : TComponent);
    procedure BlockEvents(Sender : TComponent);
    procedure UnblockEvents(Sender : TComponent);
  end;

  const
    cbmBlocking = 1;
    cbmNonBlocking = 2;
    cbmAlwaysRead = 4;


type

  TCircularBuffer = class(TObject)
  private
    FBuffer : PBuffer8;
    FP : Pointer;
    FBufSize : LongWord;
    ReadPos, WritePos : Int64;
    CS : TCriticalSection;
    Flags : Word;
    FBreak : Boolean;
    FEOF : Boolean;
  public
    constructor Create(BufSize : LongWord; Mode : Word = cbmBlocking);
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
    procedure ExposeSingleBufferWrite(var Buffer : Pointer; var Bytes : LongWord);
    procedure ExposeSingleBufferRead(var Buffer : Pointer; var Bytes : LongWord);
//    procedure ExposeDoubleBufferWrite(var Buffer1 : Pointer; var Bytes1 : LongWord; var Buffer2 : Pointer; var Bytes2 : LongWord);
//    procedure ExposeDoubleBufferRead(var Buffer1 : Pointer; var Bytes1 : LongWord; var Buffer2 : Pointer; var Bytes2 : LongWord);
    procedure AddBytesWritten(Bytes : LongWord);
    procedure AddBytesRead(Bytes : LongWord);
    function Read(Buf : Pointer; BufSize : LongWord) : LongWord;
    function Write(Buf : Pointer; BufSize : LongWord) : LongWord;
    function WouldWriteBlock : Boolean;
    function WouldReadBlock : Boolean;
    function FreeSpace : LongWord;
    procedure Reset;
    procedure Reset2;
    procedure Stop;
    property EOF : Boolean read FEOF write FEOF;
  end;

  const
     AuCacheSize = $8000000;

  type

  TCacheThread  = class(TThread)
  public
    FCS : TCriticalSection;
    B : array[0..AuCacheSize-1] of Byte;
    Buf : TCircularBuffer;
    h : Thandle;
    Stopped : Boolean;
    procedure Execute; override;
  end;

  TAuCachedStream = class(TAuFileStream)
  private
    FCBuffer : TCircularBuffer;
    FThread : TCacheThread;
    FPosition : Int64;
  public
    constructor Create(const AFileName: string; Mode: Word; Cached : Boolean); overload;
    constructor Create(const AFileName: string; Mode: Word; Rights: Cardinal; Cached : Boolean); overload;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;


   (* Class: TAuFIFOStream
      This class implements the FIFO queue with a TStream-compatible interface.
      The first thing you write to the stream is the first thing you will read from it.
      The TAuFIFOStream operates on assumption that one agent is constantly writing the data to it while other is constantly reading.
      The stream is not seekable and the Size property has no meaning for it.
      Descends from TStream.
   *)

  TAuFIFOStream = class(TStream)
  private
    FCircularBuffer : TCircularBuffer;
    FBytesLocked : LongWord;
    procedure SetEOF(v : Boolean);
    function GetEOF : Boolean;
  protected
    function GetSize: Int64; {$IF CompilerVersion > 18}override;{$IFEND}
    procedure SetSize(NewSize: Longint); overload; override;
    procedure SetSize(const NewSize: Int64); overload; override;
  public
    (* Procedure: Create
       The TAuFIFOStream constructor.
       BufSize is the internal buffer size in bytes.
       Set PadWithZeros if you want <Read> to never block and return zero-filled buffer when there is no data.
    *)
    constructor Create(BufSize : LongWord; PadWithZeros : Boolean = False);
    destructor Destroy; override;
    (* Function: Read
       This function reimplements that of TStream.
       If you created the stream with PadWithZeros equal to False, Read will block until there is some data in the buffer.
       See also <WouldReadBlock>, <EOF>.
       If Read returns 0 it means that there is no data in the buffer and the writer will not write any new data.
    *)
    function Read(var Buffer; Count: Longint): Longint; override;
    (* Function: Write
       This function reimplements that of TStream. Write returns only after all the data has been written or <Reset> is called (or <EOF> is set to True).
       The size of the data to be written may be more than the size of the internal buffer.
       Write will block if there is not enough free space in the buffer (until enough data is read by the reader).
       See also <WouldWriteBlock>.
    *)
    function Write(const Buffer; Count: Longint): Longint; override;
    (* Function: Seek
       This function reimplements that of TStream. Since TAuFIFOStream is non-seekable, it does nothing.
    *)
    function Seek(Offset: Longint; Origin: Word): Longint; overload; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    (* Function: WouldReadBlock
       This function returns True if the <Read> would block (that is there is no data in the buffer) and False otherwise.
    *)
    function WouldReadBlock : Boolean;
    (* Function: WouldWriteBlock
       This function returns True if the <Write> would block (that is there is not enough free space in the buffer to write Bytes bytes) and False otherwise.
    *)
    function WouldWriteBlock(Bytes : LongWord = 1) : Boolean;
    procedure LockReadBuffer(var Buffer : Pointer; var Bytes : LongWord);
    procedure ReleaseReadBuffer;
    (* Procedure: Reset
       Call this to reset the stream.
       Any blocked call to <Read> or <Write> returns immediately.
    *)
    procedure Reset;
    (* Property: EOF
      The writer sets this property to True when it has written all the data.
      After this the reader reads all the data that is left in the buffer and then <Read> calls start returning 0 as the resulting value (which is the End of File indicator for the reader).

    *)
    property EOF : Boolean read GetEOF write SetEOF;
  end;

procedure CreateEventHandler;
procedure ReleaseEventHandler;

var
  EventHandler : TEventHandler;
  LoadLibCS : TCriticalSection;

implementation

var
  RCount : Integer;

procedure CreateEventHandler;
begin
  if RCount = 0 then
  begin
    EventHandler := TEventHandler.Create;
    EventHandler.FreeOnTerminate := False;
  end;
  Inc(RCount);
end;

procedure ReleaseEventHandler;
begin
  Dec(RCount);
  if RCount = 0 then
  begin
    EventHandler.Terminate;
    EventHandler._Evt.Release;
    EventHandler.WaitFor;
    EventHandler.Free;
  end;
end;

  constructor TEventHandler.Create;
  begin
    inherited Create(False);
    Events := TList.Create;
    CS := TCriticalSection.Create;
    _Evt := TEvent.Create(nil, False, False, 'mainevent');
  end;

  destructor TEventHandler.Destroy;
  begin
    Events.Free;
    CS.Free;
    _Evt.Free;
  end;

  procedure TEventHandler.ClearEvents;
  var
    i : Integer;
    e : PEventRecord;
  begin
    CS.Enter;
    i := 0;
    while i < Events.Count do
    begin
      e := Events.Items[i];
      if e.Sender = Sender then
      begin
        Events.Extract(e);
        Dispose(e);
      end
      else
        Inc(i);
    end;
    CS.Leave;
  end;

  procedure TEventHandler.BlockEvents;
  begin
    CS.Enter;
    BlockedSender := Sender;
    CS.Leave;
  end;

  procedure TEventHandler.UnblockEvents;
  begin
    CS.Enter;
    BlockedSender := nil;
    CS.Leave;
  end;


  procedure TEventHandler.AddEvent;
  begin
    CS.Enter;
    if Event.Sender <> BlockedSender then
      Events.Add(Event);
    CS.Leave;
    _Evt.SetEvent;
  end;

  procedure TEventHandler.PrependEvent;
  begin
    CS.Enter;
    if Event.Sender <> BlockedSender then
      Events.Insert(0, Event);
    CS.Leave;
    _Evt.SetEvent;
  end;


  function TEventHandler.GetEvent;
  begin
    CS.Enter;
    Result := Events.First;
    Events.Extract(Result);
    CS.Leave;
  end;

  procedure TEventHandler.CallHandler;
  begin
    if CurrentEvent._type = etOnDone then
        CurrentEvent.DoneEvent(CurrentEvent.Sender)
    else
    if CurrentEvent._type = etOnProgress then
        CurrentEvent.ProgressEvent(CurrentEvent.Sender)
    else
        CurrentEvent.GenericEvent(CurrentEvent.Sender);
  end;

  procedure TEventHandler.Execute;
  begin
    while not Terminated do
    begin
      while Events.Count > 0 do
      begin
        CurrentEvent := GetEvent;
        if CurrentEvent._type = etOnDone then
        begin
          while not CurrentEvent.Thread.Sleeping do
            Sleep(10);
          TAuOutput(CurrentEvent.Sender).Busy := False;
          ClearEvents(CurrentEvent.Sender);
          if (Assigned(TAuOutput(CurrentEvent.Sender).FOnDone)) and (TAuOutput(CurrentEvent.Sender).Thread.DoNotify) then
          begin
            CurrentEvent.DoneEvent := TAuOutput(CurrentEvent.Sender).FOnDone;
            Synchronize(CallHandler);
          end;
        end else
        if CurrentEvent._type = etNonGui then
                CallHandler
        else
        Synchronize(CallHandler);
        Dispose(CurrentEvent);
      end;
      _Evt.WaitFor(100);
    end;
  end;

  procedure TEventHandler.PostOnDone;
  var
    e : PEventRecord;
  begin
    New(e);
    e._type := etOnDone;
    e.Sender := Sender;
    e.Thread := Thread;
    AddEvent(e);
  end;

  procedure TEventHandler.PostOnProgress;
  var
    e : PEventRecord;
  begin
    New(e);
    e._type := etOnProgress;
    e.Sender := Sender;
    e.ProgressEvent := Handler;
    AddEvent(e);
  end;

  procedure TEventHandler.PostGenericEvent;
  var
    e : PEventRecord;
  begin
    New(e);
    e._type := etGeneric;
    e.Sender := Sender;
    e.GenericEvent := Handler;
    AddEvent(e);
  end;

  procedure TEventHandler.PostNonGuiEvent;
  var
    e : PEventRecord;
  begin
    New(e);
    e._type := etNonGui;
    e.Sender := Sender;
    e.GenericEvent := Handler;
    PrependEvent(e);
  end;


  constructor TAuInput.Create;
  begin
    inherited Create(AOwner);
    DataCS := TCriticalSection.Create;
  end;

  destructor TAuInput.Destroy;
  begin
    FreeAndNil(DataCS);
    inherited Destroy;
  end;

  procedure TAuInput.Init;
  var
    eflag : Boolean;
    Msg : String;
  begin
    eflag := False;
    DataCS.Enter;
    try
      _EndOfStream := False;
      InitInternal;
    except
      on E : Exception do
      begin
        _EndOfStream := True;
        eflag := True;
        Msg := E.Message;
      end;
    end;
    DataCS.Leave;
    if eflag then raise EAuException.Create(Msg);
  end;

  procedure TAuInput.Flush;
  begin
    DataCS.Enter;
    try
      FlushInternal;
    finally
      DataCS.Leave;
    end;
  end;

  procedure TAuInput.GetData;
  begin
    DataCS.Enter;
    try
      GetDataInternal(Buffer, Bytes);
    finally
      DataCS.Leave;
    end;
  end;

  constructor TAuThread.Create;
  begin
    inherited Create(False);
    PauseEvent := TEvent.Create(nil, False, False, '');
    SoftSleepEvent := TEvent.Create(nil, False, False, '');
    Sleeping := False;
  end;

  destructor TAuThread.Destroy;
  begin
    PauseEvent.Free;
    SoftSleepEvent.Free;
    inherited Destroy;
  end;

  procedure TAuThread.WaitForPause;
  begin
    PauseEvent.WaitFor(5000);
  end;

  procedure TAuThread.SoftSleep;
  begin
    SoftSleepEvent.ResetEvent;
    Sleeping := True;
    SoftSleepEvent.WaitFor(INFINITE);
    Sleeping := False;
  end;

  procedure TAuThread.SoftPause;
  begin
    SoftSleepEvent.ResetEvent;
    Paused := True;
    PauseEvent.SetEvent;
    SoftSleepEvent.WaitFor(INFINITE);
    Paused := False;
  end;

  procedure TAuThread.SoftWake;
  begin
    SoftSleepEvent.SetEvent;
  end;

  procedure TAuThread.Execute;
  var
    ParentComponent : TAuOutput;
    Res : Boolean;
  begin
    Sleeping := True;
    ParentComponent := TAuOutput(Parent);
    SoftSleep;
    Stop := False;
    while not Terminated do
    begin
      try
        ParentComponent.Prepare;
        Res := True;
        ParentComponent.CanOutput := True;
        SetPause := False;
        Paused := False;
        PauseEvent.ResetEvent;
        while (not Stop) and Res do
        begin
          if Delay > 5 then sleep(Delay);
          if ParentComponent.Progress <> ParentComponent.CurProgr then
          begin
            ParentComponent.CurProgr := ParentComponent.Progress;
            if Assigned(ParentComponent.FOnProgress)
              then EventHandler.PostOnProgress(ParentComponent, ParentComponent.FOnProgress);
          end;
          if SetPause then
          begin
            SetPause := False;
            SoftPause;
          end;
          Res := ParentComponent.DoOutput(Stop);
        end; // while (not Stop) and Res do
        Stop := False;
      except
        on E : Exception do
        begin
          (Parent as TAuOutput).FExceptionMessage := E.Message;
          if Assigned((Parent as TAuOutput).FOnThreadException) then
             EventHandler.PostGenericEvent(Parent, (Parent as TAuOutput).FOnThreadException);
          Stop := True;
        end;
      end;
      try
        ParentComponent.WhenDone;
      except
        ParentComponent.Busy := False;
      end;
      if Assigned(ParentComponent.FOnSyncDone) then
         ParentComponent.FOnSyncDone(ParentComponent);
       //else
         EventHandler.PostOnDone(Parent, Self);
       if not ParentComponent.Busy then
       begin
         Stopped := True;
         if not Terminated then Self.SoftSleep;
       end;
    end; //  while not Terminated do
  end;

procedure TAuOutput.BlockingRun;
var
  bAbort: Boolean;
begin
  Busy := True;
  Prepare;
  bAbort := False;
  CanOutput := True;
  while DoOutput(bAbort) do;
  WhenDone;
end;

constructor TAuOutput.Create;
  begin
    inherited Create(AOwner);
    if not (csDesigning in ComponentState) then
    begin
      FStopped := False;
      RunCS := TCriticalSection.Create;
      Thread := TAuThread.Create;
      Thread.Parent := Self;
      Thread.DoNotify := True;
      Thread.FreeOnTerminate := False;
     CreateEventHandler;
    end;
  end;

  destructor TAuOutput.Destroy;
  begin
      if not (csDesigning in ComponentState) then
      begin
        Stop(False);
        Thread.Terminate;
        while Thread.Sleeping do
          Thread.SoftWake;
        Thread.WaitFor;
        Thread.Free;
        ReleaseEventHandler;
        RunCS.Free;
      end;
    inherited Destroy;
  end;

  procedure TAuOutput.WhenDone;
  begin
    if not Busy then Exit;
    CanOutput := False;
    Done;
    FStopped := False;
    Busy := False;
  end;

  procedure TAuOutput.Run;
  begin
    RunCS.Enter;
    FExceptionMessage := '';
    if Busy then
    begin
      RunCS.Leave;
      raise EAuException.Create('Component is Busy');
    end;
    Busy := True;
    if not Assigned(FInput) then
    begin
      RunCS.Leave;
      raise EAuException.Create('Input is not assigned');
    end;
    try
      Thread.Stopped := False;
      while Thread.Sleeping do
      begin
        Thread.Stop := False;
        Thread.SoftWake;
      end;
    finally
      RunCS.Leave;
    end;
  end;

  procedure TAuOutput.Stop;
  var
    e : TOutputDoneEvent;
  begin
    if  GetCurrentThreadID = Thread.ThreadID then
      raise EAuException.Create('You are trying to stop this thread from the thread itself!');
    FStopped := True;
    if Thread = nil then
      Exit;
    if not Async then
    begin
//      e := FOnSyncDone;
//      FOnSyncDone := nil;
    end;
    Thread.DoNotify := Async;
//    Thread.Stopped := False;
    Thread.Stop := True;
    while Thread.Paused do
    begin
      Thread.SoftWake;
      sleep(0);
    end;
    if not Async then
    begin
      EventHandler.BlockEvents(Self);
      EventHandler.ClearEvents(Self);
      while (not Thread.Sleeping) and (not Thread.Stopped) do
      begin
        sleep(0);
        if GetCurrentThreadID = MainThreadID then
          CheckSynchronize; // to release possible deadlocks
      end;
      EventHandler.UnblockEvents(Self);
      Thread.DoNotify := True;
//      FOnSyncDone := e;
    end;
  end;

  function TAuOutput.GetStatus;
  begin
    if Busy then
    begin
      if Self.Thread.Paused then Result := tosPaused
      else Result := tosPlaying;
    end else Result := tosIdle;
  end;

  procedure TAuOutput.SetPriority;
  begin
    Thread.Priority := Priority;
  end;

  function TAuOutput.GetPriority;
  begin
    Result := Thread.Priority;
  end;

  procedure TAuOutput.SetInput;
  begin
    if Busy then
    begin
      Stop(False);
      FInput := vInput;
      Run;
    end else
    FInput := vInput;
  end;

  function  TAuOutput.GetProgress;
  begin
    if not Assigned(Finput) then
    begin
      Result := 0;
      Exit;
    end;
    case Finput.Size of
      0: Result := 0;
      -1: Result := -1;
      else Result := Round((FInput.Position/FInput.Size)*100);
    end;
  end;

  procedure TAuOutput.Pause;
  begin
    if FInput = nil then
      raise EAuException.Create('Input is not assigned.');
    If Busy then
    begin
      Thread.SetPause := True;
      Thread.WaitForPause;
      FInput._Pause;
    end;
  end;

  procedure TAuOutput.Resume;
  begin
    If Busy and Thread.Paused then
    begin
      FInput._Resume;
      while Thread.Paused do
      Thread.SoftWake;
    end;
  end;


  constructor TAuStreamedInput.Create;
  begin
    inherited Create(AOwner);
    FStartSample := 0;
    FEndSample := -1;
    FSeekable := True;
    FTotalSamples := 0;
  end;

  function TAuFileIn.GetBPS;
  begin
    OpenFile; // Open the file if it is not already opened
    Result := FBPS;
  end;

  function TAuFileIn.GetCh;
  begin
    OpenFile; // Open the file if it is not already opened
    Result := FChan;
  end;

  function TAuFileIn.GetSR;
  begin
    OpenFile; // Open the file if it is not already opened
    Result := FSR;
  end;

(*  function TAuFileIn.GetTime;
  begin
    if FSeekable then
    begin
      OpenFile; // Open the file if it is not already opened
      Result := FTime;
    end else Result := FTime;
  end;*)

  function TAuFileIn.GetValid;
  begin
(* Ross---
    if (not FStreamAssigned) and (FileName = '') then
 ---Ross *)
(* Ross--- *)
    if (not FStreamAssigned) and (WideFileName = '') then
(* ---Ross *)
    begin
//      Result := False;
    end else
    begin
//      if (not FStreamAssigned) then FStream := nil;
      try
        OpenFile; // Open the file if it is not already opened
      except
        FValid := False;
      end;
      if not FValid then
      begin
        if Self.FOpened = 0 then
        begin
          if (not FStreamAssigned) and (FStream <> nil) then FStream.Free;
        end else // if Self.FOpened = 0
        begin
          try
            CloseFile;
          except;
          end;
        end;  // if Self.FOpened = 0 then ... else
      end; // if not FValid then
    end; // else
    Result := FValid;
  end;

  procedure TAuFileIn.InitInternal;
  begin
    if Busy then raise EAuException.Create('The component is Busy');
    if not FStreamAssigned then
    if FWideFileName = '' then raise EAuException.Create('The file name is not assigned');
    Busy := True;

    FPosition := 0;


    OpenFile; // After calling this method we should know FChan, FBPS, FSR, and FSize

    if not FValid then
    begin
      FSampleSize := 8;
      FSR := 8000;
      FBPS := 8;
      FChan := 1;
      FTotalSamples := 0;
      FSize := 0;
      FTime := 0;
      Exit;
    end;

    FSampleSize := FChan*FBPS div 8;
    FTotalSamples := FSize div FSampleSize;
    FTime := FTotalSamples div FSR;

    if FStartSample > 0 then
    begin
     Seek(0);
     FPosition := 0;
    end; 
    if (FStartSample > 0) or (FEndSample <> -1) then
    begin
      if FEndSample > FTotalSamples then FEndSample := -1;
      if FEndSample = -1 then
        FTotalSamples :=  FTotalSamples - FStartSample + 1
      else
         FTotalSamples := FEndSample - FStartSample + 1;
      FSize := FTotalSamples*FSampleSize;
    end;

    BufStart := 1;
    BufEnd := 0;
  end;

  procedure TAuFileIn.FlushInternal;
  begin
    CloseFile;
    FStartSample := 0;
    FEndSample := -1;
    Busy := False;
  end;

  function TAuStreamedInput.Seek;
  begin
    Result := False;
    if not FSeekable then
    begin
      Exit;
    end;
    if (FTotalSamples <> 0) and (SampleNum > FTotalSamples)  then
    begin
      Result := False;
      Exit;
    end;
    DataCS.Enter;
    if not Busy then
    begin
      StartSample := SampleNum;
      FPosition := SampleNum*FSampleSize;
      EndSample := -1;
      Result := True;
    end else
    begin
      try
        Inc(SampleNum, FStartSample);
        Result := SeekInternal(SampleNum);
        FPosition := (SampleNum - FStartSample)*FSampleSize;
      except
      end;
    end;
    DataCS.Leave;
  end;

  procedure TAuFileIn._Jump;
  var
    Curpos : Double;
    Cursample : Integer;
  begin
    if (not FSeekable) or (FSize = 0) then Exit;
    Curpos := FPosition/FSize + offs/1000;
    if Curpos < 0 then Curpos := 0;
    if Curpos > 1 then Curpos := 1;
    Cursample := Round(Curpos*FTotalSamples);
    Seek(Cursample);
  end;

  function TAuOutput.GetTE;
  begin
     if not Assigned(FInput) then
     Result := 0
     else
     Result := Round(FInput.Position/((FInput.BitsPerSample shr 3) *FInput.Channels*FInput.SampleRate));
  end;

  function TAuOutput.GetDelay;
  begin
    if Assigned(Thread) then Result := Thread.Delay
    else Result := 0;
  end;

  procedure TAuOutput.SetDelay;
  begin
    if Assigned(Thread) then
    if Value <= 100 then Thread.Delay := Value;
  end;

  function TAuInput.GetTotalTime;
  begin
    Result := 0;  // Default result for the streams.
  end;

  function TAuFileIn.GetTotalTime;
  begin
    Result := 0;
    OpenFile;
    if (SampleRate = 0) or (Channels = 0) or (BitsPerSample = 0) then Exit;
    Result := Round(Size/(SampleRate*Channels*(BitsPerSample shr 3)));
  end;

  procedure TAuStreamedInput.SetStream;
  begin
    FStream := aStream;
    if FStream <> nil then FStreamAssigned := True
    else FStreamAssigned := False;
  end;

  procedure TAuStreamedOutput.SetStream;
  begin
    FStream := aStream;
    if FStream <> nil then FStreamAssigned := True
    else FStreamAssigned := False;
  end;

  procedure TAuOutput.Notification;
  begin
    // Remove the following two lines if they cause troubles in your IDE
    if (AComponent = FInput) and (Operation = opRemove )
    then Input := nil;
    inherited Notification(AComponent, Operation);
  end;


  procedure TAuInput.Reset;
  begin
    try
      Flush;
    except
    end;
    Busy := False;
  end;

  procedure TAuFileIn.Reset;
  begin
    inherited Reset;
    FOpened := 0;
  end;


  constructor TAuFileOut.Create;
  begin
    inherited Create(AOwner);
    {$IFDEF LINUX}
    FAccessMask := $1B6; // rw-rw-rw-
    {$ENDIF}
  end;

  procedure TAuFileOut.SetFileMode;
  begin
    FFileMode := foRewrite;
  end;

  procedure TAuConverter.Notification;
  begin
    // Remove the following two lines if they cause troubles in your IDE
    if (AComponent = FInput) and (Operation = opRemove )
    then Input := nil;
    inherited Notification(AComponent, Operation);
  end;

  procedure TAuConverter.SetInput;
  begin
    if aInput = Self then Exit;
    _Lock;
    try
      if Busy then
      begin
        FInput.Flush;
        aInput.Init;
        FInput := aInput;
      end else
      FInput := aInput;
    finally
      _Unlock;
    end;  
  end;

  function TAuFileIn.SetStartTime;
  var
    Sample : LongWord;
  begin
    Result := False;
    if not FSeekable then Exit;
    OpenFile;
    Sample := (Minutes*60+Seconds)*FSR;
    if Sample > FTotalSamples then Exit;
    FStartSample := Sample;
    Result := True;
  end;

  function TAuFileIn.SetEndTime;
  var
    Sample : Integer;
  begin
    Result := False;
    if not FSeekable then Exit;
    OpenFile;
    Sample := (Minutes*60+Seconds)*FSR;
    if Sample > FTotalSamples then Exit;
    FEndSample := Sample;
    Result := True;
  end;

  constructor TAuFileIn.Create;
  begin
    inherited Create(AOwner);
    OpenCS := TCriticalSection.Create;
  end;

  destructor TAuFileIn.Destroy;
  begin
    CloseFile;
    OpenCS.Free;
    inherited Destroy;
  end;

(*  procedure TAuThread.CallOnDone;
  begin
    if Assigned((Parent as TAuOutput).FOnDone) then
       (Parent as TAuOutput).FOnDone(Parent);
  end; *)

{$IFDEF WIN32}
  procedure TAuOutput.Abort;
  begin
    TerminateThread(Thread.Handle, 0);
    WhenDone;
  end;
{$ENDIF}

  function TAuInput.CopyData;
  var
    P : Pointer;
  begin
    Result := BufferSize;
    GetData(P, Result);
    if P <> nil then
      Move(P^, Buffer^,  Result);
  end;

  function TAuInput.FillBuffer;
  var
    P : PByteArray;
    P1 : Pointer;
    r : LongWord;
  begin
    P := Buffer;
    r := BufferSize;
    Result := 0;
    while (BufferSize - Result > 0) and (r > 0) do
    begin
      r := BufferSize - Result;
      GetData(P1, r);
      if P1 <> nil then
        Move(P1^, P[Result], r);
      Result := Result + r;
    end;
    EOF := r = 0;
  end;

  function TAuInput.FillBufferUnprotected;
  var
    P : PByteArray;
    P1 : Pointer;
    r : LongWord;
  begin
    if Buffer = nil then
    begin
      Result := 0;
      Exit;
    end;
    try
      DataCS.Enter;
      P := Buffer;
      r := BufferSize;
      Result := 0;
      while (BufferSize - Result > 0) and (r > 0) do
      begin
        r := BufferSize - Result;
        GetDataInternal(P1, r);
        Move(P1^, P[Result], r);
        Result := Result + r;
      end;
      Inc(FPosition, Result);
    finally
      DataCS.Leave;
    end;
    EOF := r = 0;
  end;


  constructor TAuFileStream.Create(const FileName: WideString; Mode: Word);
  begin
    Create(FileName, Mode, 0);
  end;

  constructor TAuFileStream.Create(const FileName: WideString; Mode: Word; Rights: Cardinal);
  const
    AccessMode: array[0..2] of LongWord = (
      GENERIC_READ,
      GENERIC_WRITE,
      GENERIC_READ or GENERIC_WRITE);
    ShareMode: array[0..4] of LongWord = (
      0,
      0,
      FILE_SHARE_READ,
      FILE_SHARE_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE);
  begin
    if Mode = fmCreate then
      inherited Create(
      CreateFileW(PWideChar(FileName), GENERIC_READ or GENERIC_WRITE,
      0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0))
    else
      inherited Create(CreateFileW(PWideChar(FileName), AccessMode[Mode and 3],
        ShareMode[(Mode and $F0) shr 4], nil, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, 0));
    {$IF CompilerVersion >= 20 }
    if FHandle = INVALID_HANDLE_VALUE then
    {$IFEND}
    {$IF CompilerVersion < 20 }
    if FHandle < 0 then
    {$IFEND}
      raise EAuException.Create(SysErrorMessage(GetLastError));
  end;

  destructor TAuFileStream.Destroy;
  begin
    {$IFDEF UNICODE}
    if FHandle <> INVALID_HANDLE_VALUE then FileClose(FHandle);
    {$ENDIF}
    {$IFNDEF UNICODE}
    if FHandle >= 0 then FileClose(FHandle);
    {$ENDIF}
    inherited Destroy;
  end;

(* Ross--- *)
  procedure TAuTaggedFileIn.SetId3v1Tags(Value: TId3v1Tags);
  begin
    FId3v1Tags.Assign(Value);
  end;

  procedure TAuTaggedFileIn.SetId3v2Tags(Value: TId3v2Tags);
  begin
    FId3v2Tags.Assign(Value);
  end;

  procedure TAuTaggedFileIn.SetAPEv2Tags(Value: TAPEv2Tags);
  begin
    FAPEv2Tags.Assign(Value);
  end;

  procedure TAuTaggedFileIn.SetCommonTags(Value: TCommonTags);
  begin
    FCommonTags.Assign(Value);
  end;

(* ---Ross *)
  procedure TAuFileIn.SetWideFileName;
  begin
    CloseFile;
//    StartSample := 0;
//    EndSample := -1;
    FWideFileName := FN;
    FFileName := '';
  end;

  procedure TAuFileIn.SetFileName;
  begin
    CloseFile;
//    StartSample := 0;
//    EndSample := -1;
    FWideFileName := FN;
    FFileName := FN;
  end;

(* Ross--- *)
  procedure TAuTaggedFileOut.SetId3v1Tags(Value: TId3v1Tags);
  begin
    FId3v1Tags.Assign(Value);
  end;

  procedure TAuTaggedFileOut.SetId3v2Tags(Value: TId3v2Tags);
  begin
    FId3v2Tags.Assign(Value);
  end;

  procedure TAuTaggedFileOut.SetAPEv2Tags(Value: TAPEv2Tags);
  begin
    FAPEv2Tags.Assign(Value);
  end;

(* ---Ross *)
  procedure TAuFileOut.SetWideFileName;
  begin
    FWideFileName := FN;
    FFileName := '';
  end;

  procedure TAuFileOut.SetFileName;
  begin
    FWideFileName := FN;
    FFileName := FN;
  end;

  constructor TAuTaggedFileIn.Create;
  begin
    inherited Create(AOwner);
(* Ross--- *)
    FId3v1Tags := TId3v1Tags.Create();
    FId3v2Tags := TId3v2Tags.Create();
    FAPEv2Tags := TAPEv2Tags.Create();
(* ---Ross *)
    FCommonTags := TCommonTags.Create();
  end;

  destructor TAuTaggedFileIn.Destroy;
  begin
(* Ross--- *)
    FId3v1Tags.Free();
    FId3v2Tags.Free();
    FAPEv2Tags.Free();
(* ---Ross *)
    FCommonTags.Free();
    inherited Destroy;
  end;

  constructor TAuTaggedFileOut.Create;
  begin
    inherited Create(AOwner);
(* Ross--- *)
    FId3v1Tags := TId3v1Tags.Create();
    FId3v2Tags := TId3v2Tags.Create();
    FAPEv2Tags := TAPEv2Tags.Create();
(* ---Ross *)
  end;

  destructor TAuTaggedFileOut.Destroy;
  begin
    FId3v1Tags.Free;
    FId3v2Tags.Free;
    FAPEv2Tags.Free;
    inherited Destroy;
  end;

  function TAuFileIn.GetTotalSamples;
  begin
    OpenFile;
    if FSize > 0 then
    FTotalSamples := FSize div (FChan*FBPS div 8)
    else FTotalSamples := -1;
    Result := FTotalSamples;
  end;

procedure TAuFileIn.SetStream;
begin
  CloseFile;
  inherited SetStream(aStream);
end;

procedure TAuInput._Lock;
begin
  DataCS.Enter;
end;

procedure TAuInput._Unlock;
begin
  DataCS.Leave;
end;

procedure TAuInput._Pause;
begin
// Nothing to do here, may be overridden in descendants.
end;

procedure TAuInput._Resume;
begin
// Nothing to do here, may be overridden in descendants.
end;


procedure TAuStreamedInput.GetData;
var
  tmpBytes : LongWord;
begin
  DataCS.Enter;
  tmpBytes := Bytes;
  try
    if _EndOfStream then
    begin
      Buffer :=  nil;
      Bytes := 0;
    end else
    begin
      GetDataInternal(Buffer, Bytes);
      if Bytes = 0 then
        _EndOfStream := True
      else
      begin
        Inc(FPosition, Bytes);
        if (FSize > 0) and (FPosition >= FSize) then
        begin
          _EndOfStream := True;
          if FPosition > FSize then
          begin
            Bytes := Bytes - (FPosition - FSize);
            FPosition := FSize;
          end;
        end;
      end;
      if _EndOfStream and FLoop then
      begin
        _EndOfStream := False;
        if FSeekable then
          SeekInternal(FStartSample)
        else
        begin
          Flush;
          Init;
        end;
        FPosition := 0;
        Bytes := tmpBytes;
        GetDataInternal(Buffer, Bytes);
        if Bytes = 0 then
          _EndOfStream := True
          else
          begin
            Inc(FPosition, Bytes);
              if (FSize > 0) and (FPosition >= FSize) then
            _EndOfStream := True;
         end;
      end;  // if _EndOfStream and FLoop then
    end; // if _EndOfStream then ... else
  finally
    DataCS.Leave;
  end;
end;

procedure TAuConverter.GetData;
begin
  DataCS.Enter;
  try
    if _EndOfStream then
    begin
      Buffer :=  nil;
      Bytes := 0;
    end else
    begin
      GetDataInternal(Buffer, Bytes);
      Inc(FPosition, Bytes);
      if (FSize > 0) and (FPosition > FSize) then
      begin
        Dec(Bytes, FPosition - FSize);
        _EndOfStream := True
      end;
      if Bytes = 0 then
        _EndOfStream := True
    end;
  finally
    DataCS.Leave;
  end;
end;

procedure TAuConverter._Pause;
begin
  FInput._Pause;
end;

procedure TAuConverter._Resume;
begin
  FInput._Resume;
end;


function TAuInput.GetTotalSamples;
begin
  Result := 0;
end;

procedure TAuInput.SetRequestFloat(rf: Boolean);
begin
  FFloatRequested := rf;
end;

procedure TAuInput._Jump(Offs : Integer);
begin
end;


function TAudioTap.GetStatus;
begin
  if FRecording then
  begin
    if not FPaused then
      Result := tosPlaying
    else
      Result := tosPaused;
 end else
   Result := tosIdle;
end;

function TAudioTap.GetBPS;
begin
  Result := FInput.BitsPerSample;
end;

function TAudioTap.GetCh;
begin
  Result := FInput.Channels;
end;

function TAudioTap.GetSR;
begin
  Result := FInput.SampleRate;
end;

procedure TAudioTap.SetFileName;
begin
  FFileName := Value;
  FWideFileName := Value;
end;

procedure TAudioTap.SetWideFileName;
begin
  FFileName := '';
  FWideFileName := Value;
end;

procedure TAudioTap.InitInternal;
begin
  if not Assigned(FInput) then
  raise EAuException.Create('Input not assigned');
  FInput.Init;
  Busy := True;
  FSize := FInput.Size;
  FPosition := 0;
end;

procedure TAudioTap.GetDataInternal;
begin
  FInput.GetDataInternal(Buffer, Bytes);
  if FRecording then
  begin
    if (Bytes = 0) or FStopping then
    begin
      FRecording := False;
      FStopping := False;
      FPaused := False;
      FStarting := False;
      StopRecordInternal;
    end else
    begin
      if not FPaused then
      begin
        WriteDataInternal(Buffer, Bytes);
      end;
    end;
  end else // if FRecording then
  begin
    if (Bytes <> 0) and FStarting then
    begin
      FStarting := False;
      FRecording := True;
      StartRecordInternal;
      WriteDataInternal(Buffer, Bytes);
    end;
  end;
end;

procedure TAudioTap.FlushInternal;
begin
  Finput.Flush;
  if FRecording then
  begin
    FRecording := False;
    FStopping := False;
    FPaused := False;
    FStarting := False;
    StopRecordInternal;
  end;
  Busy := False;
end;

procedure TAudioTap._Pause;
begin
 if FRecording then PauseRecord;
 FInput._Pause;
end;

procedure TAudioTap._Resume;
begin
  FInput._Resume;
  if FRecording then ResumeRecord;
end;

procedure TAudioTap.StartRecord;
begin
  if not FRecording then FStarting := True;
end;

procedure TAudioTap.PauseRecord;
begin
  if FRecording then FPaused := True;
end;

procedure TAudioTap.ResumeRecord;
begin
  FPaused := False;
end;

procedure TAudioTap.StopRecord;
begin
  if FRecording then FStopping := True;
end;

constructor TCircularBuffer.Create;
begin
  inherited Create;
  FBufSize := BufSize;
  GetMem(FP, BufSize+15);
 // LongWord(FP) := LongWord(FP) + 15 - ((LongWord(FP) + 15) mod 16);
  FBufSize := BufSize;
  FBuffer := FP;
  CS := TCriticalSection.Create;
end;

destructor TCircularBuffer.Destroy;
begin
  FreeMem(FP);
  CS.Free;
  inherited Destroy;
end;

procedure TCircularBuffer.Lock;
begin
  CS.Enter;
end;

procedure TCircularBuffer.Unlock;
begin
  CS.Leave;
end;

procedure TCircularBuffer.ExposeSingleBufferWrite;
var
  WritePtrPos, ReadPtrPos : LongWord;
begin
  WritePtrPos := WritePos mod FBufSize;
  ReadPtrPos := ReadPos  mod FBufSize;
  Buffer := @FBuffer[WritePtrPos];
  if WritePtrPos > ReadPtrPos then
  begin
    Bytes := FBufSize - WritePtrPos;
  end else
  if WritePtrPos = ReadPtrPos then
  begin
     Bytes := FBufSize - WritePos + ReadPos;
     if Bytes > FBufSize - WritePtrPos then
       Bytes := FBufSize - WritePtrPos;
  end else
  begin
    Bytes := ReadPtrPos - WritePtrPos;
  end;
end;

procedure TCircularBuffer.ExposeSingleBufferRead;
var
  WritePtrPos, ReadPtrPos : LongWord;
begin
  WritePtrPos := WritePos mod FBufSize;
  ReadPtrPos := ReadPos  mod FBufSize;
  Buffer := @FBuffer[ReadPtrPos];
  if WritePtrPos > ReadPtrPos then
  begin
    Bytes := WritePtrPos - ReadPtrPos;
  end else
  if WritePtrPos = ReadPtrPos then
  begin
    Bytes := WritePos - ReadPos;
    if Bytes > FBufSize - ReadPtrPos then
      Bytes := FBufSize - ReadPtrPos
  end else
  begin
    Bytes := FBufSize - ReadPtrPos;
  end;
end;

procedure TCircularBuffer.AddBytesWritten;
begin
  WritePos := WritePos + Bytes;
end;


procedure TCircularBuffer.AddBytesRead;
begin
  ReadPos := ReadPos + Bytes;
end;

function TCircularBuffer.Read;
var
  sp1, l : LongWord;
  _Buf : PBuffer8;
  P : Pointer;
begin
  sp1 := LongWord(WritePos - ReadPos);
  if sp1 = 0 then
  begin
    if ((Flags and cbmAlwaysRead)  <> 0) and (not FEOF) then
    begin
       FillChar(Buf^, BufSize, 0);
       Result := BufSize;
       Exit;
    end else
    begin
      while sp1 = 0 do
      begin
        if FEOF then
        begin
          WritePos := 0;
          ReadPos := 0;
          Result := 0;
          Exit;
        end;
        Sleep(1);
        if FBreak then
        begin
          Result := 0;
          Exit;
        end;
        sp1 := LongWord(WritePos - ReadPos);
      end;
    end;
  end;
  _Buf := Buf;
//  CS.Enter;
  ExposeSingleBufferRead(P, l);
//  CS.Leave;
  if l >= BufSize then
  begin
    Move(P^, _Buf[0], BufSize);
    Result := BufSize;
    ReadPos := ReadPos + BufSize;
  end else
  begin
    Move(P^, _Buf[0], l);
    Result := l;
    ReadPos := ReadPos + l;
  end;
end;

function TCircularBuffer.Write(Buf: Pointer; BufSize: Cardinal) : LongWord;
var
  sp1, l : LongWord;
  P : Pointer;
  _Buf : PBuffer8;
begin
  _Buf := Buf;
  if FEOF then
  begin
    Result := 0;
    Exit;
  end;
  sp1 := ReadPos + FBufSize - WritePos;
  if sp1 = 0 then
  begin
    while sp1 = 0 do
    begin
      Sleep(1);
      if FBreak then
      begin
        Result := 0;
        Exit;
      end;
      sp1 := LongWord(ReadPos + FBufSize - WritePos);
    end;
  end;
//  CS.Enter;
  ExposeSingleBufferWrite(P, l);
//  CS.Leave;
  if l >= BufSize then
  begin
    Move(_Buf[0], P^, BufSize);
    Result := BufSize;
    WritePos := WritePos + BufSize;
  end else
  begin
    Move(_Buf[0], P^, l);
    Result := l;
    WritePos := WritePos + l;
  end;
end;

function TCircularBuffer.WouldWriteBlock;
begin
  Result := ReadPos + FBufSize - WritePos = 0;
end;

function TCircularBuffer.WouldReadBlock;
begin
  Result := WritePos - ReadPos = 0;
end;

function TCircularBuffer.FreeSpace;
begin
  Result := ReadPos + FBufSize - WritePos;
end;

procedure TCircularBuffer.Reset;
begin
  CS.Enter;
  ReadPos := 0;
  WritePos := 0;
  FBreak := False;
  FEOF := False;
  CS.Leave;
end;

procedure TCircularBuffer.Reset2;
begin
 ReadPos := WritePos;
end;


procedure TCircularBuffer.Stop;
begin
  CS.Enter;
  ReadPos := 0;
  WritePos := 0;
  FBreak := True;
  FEOF := True;
  CS.Leave;
end;

function TAuConverter.GetBPS;
begin
  if Assigned(FInput) then
  begin
    Result := FInput.BitsPerSample;
    if not FFloatRequested then
       Result := Result mod 128;
  end else
    Result := 0;
end;

function TAuConverter.GetCh;
begin
  if Assigned(FInput) then
    Result := FInput.Channels
  else
    Result := 0;
end;

function TAuConverter.GetSR;
begin
  if Assigned(FInput) then
    Result := FInput.SampleRate
  else
    Result := 0;
end;


procedure TAuConverter._Jump(Offs: Integer);
begin
  if Assigned(FInput) then
    FInput._Jump(Offs);
end;

constructor TAuFIFOStream.Create;
var
  f : Word;
begin
  inherited Create();
  f := cbmBlocking;
  if PadWithZeros then f := f + cbmAlwaysRead;
  FCircularBuffer := TCircularBuffer.Create(BufSize, f);
  FBytesLocked := 0;
end;

destructor TAuFIFOStream.Destroy;
begin
  FCircularBuffer.EOF := True;
  FCircularBuffer.CS.Enter;
  Sleep(0);
  FCircularBuffer.CS.Leave;
  FCircularBuffer.Free;
  inherited;
end;

procedure TAuFIFOStream.SetEOF(v: Boolean);
begin
  FCircularBuffer.EOF := v;
end;

function TAuFIFOStream.GetEOF;
begin
  Result := FCircularBuffer.EOF;
end;

procedure TAuFIFOStream.SetSize(NewSize: Integer);
begin

end;

procedure TAuFIFOStream.SetSize(const NewSize: Int64);
begin

end;

function TAuFIFOStream.GetSize;
begin
  Result := FCircularBuffer.WritePos;
end;

function TAuFIFOStream.Seek(Offset: Integer; Origin: Word) : LongInt;
begin
  Result := 0;
end;

function TAuFIFOStream.Seek(const Offset: Int64; Origin: TSeekOrigin) : Int64;
begin
  Result := 0;
end;

function TAuFIFOStream.WouldReadBlock;
begin
  Result := (FCircularBuffer.WritePos - FCircularBuffer.ReadPos = 0) and (not FCircularBuffer.EOF);
end;

function TAuFIFOStream.WouldWriteBlock;
begin
  Result := FCircularBuffer.FBufSize - (FCircularBuffer.WritePos - FCircularBuffer.ReadPos) < Bytes;
end;

function TAuFIFOStream.Read(var Buffer; Count: Integer) : Integer;
begin
  Result := Integer(FCircularBuffer.Read(@Buffer, LongWord(Count)));
end;

function TAuFIFOStream.Write(const Buffer; Count: Integer) : Integer;
var
  l : Integer;
  B : PBuffer8;
begin
  l := 0;
  B := @Buffer;
  while l < Count do
    l := l + Integer(FCircularBuffer.Write(@B[l], LongWord(Count - l)));
  Result := l;
end;

procedure TAuFIFOStream.Reset;
begin
  FCircularBuffer.Reset;
end;

procedure TAuFIFOStream.LockReadBuffer(var Buffer: Pointer; var Bytes: Cardinal);
begin
  FCircularBuffer.ExposeSingleBufferRead(Buffer, Bytes);
  FBytesLocked := Bytes;
end;

procedure TAuFIFOStream.ReleaseReadBuffer;
begin
  FCircularBuffer.AddBytesRead(FBytesLocked);
  FBytesLocked := 0;
end;

procedure TCacheThread.Execute;
var
  bf : LongWord;
  br, t : LongWord;
begin
  Stopped := False;
  while not Terminated do
  begin
    bf := Buf.FreeSpace;
    if bf > Buf.FBufSize div 16 then
    begin
      if (bf > Buf.FBufSize div 2) then
      begin
        Sleep(1);
      end;

      t := 0;
      FCS.Enter;
      if ReadFile(h, B[0], bf, br, nil) then
      begin
        if br > bf then raise Exception.Create('Error Message');
        while t < br  do
          t := t + Buf.Write(@B[t], br - t);
      end else
      begin
        FCS.Leave;
        Break;
      end;
      FCS.Leave;
    end;
    Sleep(0);
  end;
  Buf.EOF := True;
  Stopped := True;
end;

  constructor TAuCachedStream.Create(const AFileName: string; Mode: Word; Cached : Boolean);
  begin
    Create(AFileName, Mode);
    FCBuffer := TCircularBuffer.Create(AuCacheSize);
    FThread := TCacheThread.Create(True);
    FThread.FCS := TCriticalSection.Create;
    FThread.FreeOnTerminate := False;
    FPosition := 0;
    FThread.h := Handle;
    FThread.Buf := FCBuffer;
    FThread.Resume;
  end;

  constructor TAuCachedStream.Create(const AFileName: string; Mode: Word; Rights: Cardinal; Cached : Boolean);
  begin
    Create(AFileName, Mode, Rights);
    FThread.FCS := TCriticalSection.Create;
    FCBuffer := TCircularBuffer.Create(AuCacheSize);
    FThread := TCacheThread.Create(True);
    FThread.FreeOnTerminate := False;
    FPosition := 0;
    FThread.h := Handle;
    FThread.Buf := FCBuffer;
    FThread.Resume;
  end;

  destructor TAuCachedStream.Destroy;
  begin
    FThread.Terminate;
    while not FThread.Stopped do
      Sleep(0);
    FCBuffer.Free;
    FThread.FCS.Free;
    inherited Destroy;
  end;

  function TAuCachedStream.Read(var Buffer; Count: Longint): Longint;
  begin
//    FThread.FCS.Enter;
    Result := FCBuffer.Read(@Buffer, Count);
    Inc(FPosition, Result);
//    FThread.FCS.Leave;
  end;

  function TAuCachedStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
  begin
{    if (Origin = soCurrent) and (Offset = 0) then
    begin
      Result := FPosition;
      Exit;
    end; }

    FThread.FCS.Enter;
      FCBuffer.ReadPos := FCBuffer.WritePos; //.Reset;
      FPosition := FileSeek(Handle, Offset, Ord(Origin));
    Result := FPosition;
    FThread.FCS.Leave;
  end;


initialization

 RCount := 0;
 LoadLibCS := TCriticalSection.Create;
 //EventHandler := TEventHandler.Create;

finalization
 LoadLibCS.Free;
//  if EventHandler <> nil then
//    EventHandler.Free;

end.
