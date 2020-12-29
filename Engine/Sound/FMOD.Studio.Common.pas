unit FMOD.Studio.Common;

interface

uses
  FMOD.Common;

type

  (*
   FMOD Studio types.
  *)

  FMOD_STUDIO_SYSTEM = record
  end;

  PFMOD_STUDIO_SYSTEM = ^FMOD_STUDIO_SYSTEM;

  FMOD_STUDIO_EVENTDESCRIPTION = record
  end;

  PFMOD_STUDIO_EVENTDESCRIPTION = ^FMOD_STUDIO_EVENTDESCRIPTION;
  PPFMOD_STUDIO_EVENTDESCRIPTION = ^FMOD_STUDIO_EVENTDESCRIPTION;

  FMOD_STUDIO_EVENTINSTANCE = record
  end;

  PFMOD_STUDIO_EVENTINSTANCE = ^FMOD_STUDIO_EVENTINSTANCE;
  PPFMOD_STUDIO_EVENTINSTANCE = ^PFMOD_STUDIO_EVENTINSTANCE;

  FMOD_STUDIO_PARAMETERINSTANCE = record
  end;

  PFMOD_STUDIO_PARAMETERINSTANCE = ^FMOD_STUDIO_PARAMETERINSTANCE;

  FMOD_STUDIO_BUS = record
  end;

  PFMOD_STUDIO_BUS = ^FMOD_STUDIO_BUS;
  PPFMOD_STUDIO_BUS = ^PFMOD_STUDIO_BUS;

  FMOD_STUDIO_VCA = record
  end;

  PFMOD_STUDIO_VCA = ^FMOD_STUDIO_VCA;
  PPFMOD_STUDIO_VCA = ^PFMOD_STUDIO_VCA;

  FMOD_STUDIO_BANK = record
  end;

  PFMOD_STUDIO_BANK = ^FMOD_STUDIO_BANK;
  PPFMOD_STUDIO_BANK = ^PFMOD_STUDIO_BANK;

  FMOD_STUDIO_COMMANDREPLAY = record
  end;

  PFMOD_STUDIO_COMMANDREPLAY = ^FMOD_STUDIO_COMMANDREPLAY;

const

  (* Makes sure enums are 32bit. *)
  {$MINENUMSIZE 4}
  (*
   [DEFINE]
   [
   [NAME]
   FMOD_STUDIO_INITFLAGS

   [DESCRIPTION]
   Studio System initialization flags.
   Use them with Studio::System::initialize in the *studioflags* parameter to change various behavior.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::initialize
   ]
  *)

  FMOD_STUDIO_INIT_NORMAL                = $00000000; // * Initialize normally. */
  FMOD_STUDIO_INIT_LIVEUPDATE            = $00000001; // * Enable live update. */
  FMOD_STUDIO_INIT_ALLOW_MISSING_PLUGINS = $00000002; // * Load banks even if they reference plugins that have not been loaded. */
  FMOD_STUDIO_INIT_SYNCHRONOUS_UPDATE    = $00000004; // * Disable asynchronous processing and perform all processing on the calling thread instead. */
  FMOD_STUDIO_INIT_DEFERRED_CALLBACKS    = $00000008; // * Defer timeline callbacks until the main update. See Studio::EventInstance::setCallback for more information. */
  FMOD_STUDIO_INIT_LOAD_FROM_UPDATE      = $00000010; // * No additional threads are created for bank and resource loading.  Loading is driven from Studio::System::update.  Mainly used in non-realtime situations. */
  (* [DEFINE_END] *)

type
  FMOD_STUDIO_INITFLAGS = UInt32;

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These values describe the loading status of various objects.

   [REMARKS]
   Calling Studio::System::loadBankFile, Studio::System::loadBankMemory or Studio::System::loadBankCustom
   will trigger loading of metadata from the bank.

   Calling Studio::EventDescription::loadSampleData, Studio::EventDescription::createInstance
   or Studio::Bank::loadSampleData may trigger asynchronous loading of sample data.

   [SEE_ALSO]
   Studio::EventDescription::getSampleLoadingState
   Studio::Bank::getLoadingState
   Studio::Bank::getSampleLoadingState
   ]
  *)

  FMOD_STUDIO_LOADING_STATE = (
    FMOD_STUDIO_LOADING_STATE_UNLOADING, // * Currently unloading. */
    FMOD_STUDIO_LOADING_STATE_UNLOADED,  // * Not loaded. */
    FMOD_STUDIO_LOADING_STATE_LOADING,   // * Loading in progress. */
    FMOD_STUDIO_LOADING_STATE_LOADED,    // * Loaded and ready to play. */
    FMOD_STUDIO_LOADING_STATE_ERROR      // * Failed to load and is now in error state. */
    );

  (*
   [ENUM]
   [
   [DESCRIPTION]
   Specifies how to use the memory buffer passed to Studio::System::loadBankMemory.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::loadBankMemory
   Studio::Bank::unload
   ]
  *)
  FMOD_STUDIO_LOAD_MEMORY_MODE =
    (
    FMOD_STUDIO_LOAD_MEMORY,     // * When passed to Studio::System::loadBankMemory, FMOD duplicates the memory into its own buffers. Your buffer can be freed after Studio::System::loadBankMemory returns. */
    FMOD_STUDIO_LOAD_MEMORY_POINT// * This differs from FMOD_STUDIO_LOAD_MEMORY in that FMOD uses the memory as is, without duplicating the memory into its own buffers. Cannot not be freed after load, only after calling Studio::Bank::unload. */
    );

const
  (*
   [DEFINE]
   [
   [NAME]
   FMOD_STUDIO_LOAD_MEMORY_ALIGNMENT

   [DESCRIPTION]
   The required alignment of the buffer for Studio::System::loadBankMemory when using FMOD_STUDIO_LOAD_MEMORY_POINT.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::loadBankMemory
   FMOD_STUDIO_LOAD_MEMORY_MODE
   ]
  *)
  FMOD_STUDIO_LOAD_MEMORY_ALIGNMENT = 32;
  (* [DEFINE_END] *)

type
  (*
   [ENUM]
   [
   [DESCRIPTION]
   Describes the type of a parameter.

   [REMARKS]
   There are two primary types of parameters: game controlled and automatic.
   Game controlled parameters receive their value from the API using
   Studio::EventInstance::setParameterValue. Automatic parameters are updated inside
   FMOD based on the positional information of the event and listener.

   **Horizontal angle** means the angle between vectors projected onto the
   listener's XZ plane (for the EVENT_ORIENTATION and DIRECTION parameters)
   or the global XZ plane (for the LISTENER_ORIENTATION parameter).

   [SEE_ALSO]
   FMOD_STUDIO_PARAMETER_DESCRIPTION
   Studio::EventInstance::setParameterValue
   Studio::EventInstance::set3DAttributes
   Studio::System::setListenerAttributes
   ]
  *)
  FMOD_STUDIO_PARAMETER_TYPE = (
    FMOD_STUDIO_PARAMETER_GAME_CONTROLLED,                // * Controlled via the API using Studio::EventInstance::setParameterValue. */
    FMOD_STUDIO_PARAMETER_AUTOMATIC_DISTANCE,             // * Distance between the event and the listener. */
    FMOD_STUDIO_PARAMETER_AUTOMATIC_EVENT_CONE_ANGLE,     // * Angle between the event's forward vector and the vector pointing from the event to the listener (0 to 180 degrees). */
    FMOD_STUDIO_PARAMETER_AUTOMATIC_EVENT_ORIENTATION,    // * Horizontal angle between the event's forward vector and listener's forward vector (-180 to 180 degrees). */
    FMOD_STUDIO_PARAMETER_AUTOMATIC_DIRECTION,            // * Horizontal angle between the listener's forward vector and the vector pointing from the listener to the event (-180 to 180 degrees). */
    FMOD_STUDIO_PARAMETER_AUTOMATIC_ELEVATION,            // * Angle between the listener's XZ plane and the vector pointing from the listener to the event (-90 to 90 degrees). */
    FMOD_STUDIO_PARAMETER_AUTOMATIC_LISTENER_ORIENTATION, // * Horizontal angle between the listener's forward vector and the global positive Z axis (-180 to 180 degrees). */

    FMOD_STUDIO_PARAMETER_MAX// * Maximum number of parameter types supported. */
    );

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Information for loading a bank with Studio::System::loadBankCustom.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::loadBankCustom
   ]
  *)
  FMOD_STUDIO_BANK_INFO = record
    size : Integer;                           // * The size of this struct (for binary compatibility) */
    userdata : Pointer;                       // * User data to be passed to the file callbacks */
    userdatalength : Integer;                 // * If this is non-zero, userdata will be copied internally */
    opencallback : FMOD_FILE_OPEN_CALLBACK;   // * Callback for opening this file. */
    closecallback : FMOD_FILE_CLOSE_CALLBACK; // * Callback for closing this file. */
    readcallback : FMOD_FILE_READ_CALLBACK;   // * Callback for reading from this file. */
    seekcallback : FMOD_FILE_SEEK_CALLBACK;   // * Callback for seeking within this file. */
  end;

  PFMOD_STUDIO_BANK_INFO = ^FMOD_STUDIO_BANK_INFO;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Structure describing an event parameter.

   [REMARKS]

   [SEE_ALSO]
   Studio::EventDescription::getParameter
   FMOD_STUDIO_PARAMETER_TYPE
   ]
  *)
  FMOD_STUDIO_PARAMETER_DESCRIPTION = record

    name : PAnsiChar;                            // * Name of the parameter. */
    index : Integer;                             // * Index of parameter */
    minimum : Single;                            // * Minimum parameter value. */
    maximum : Single;                            // * Maximum parameter value. */
    defaultvalue : Single;                       // * Default value */
    parameter_type : FMOD_STUDIO_PARAMETER_TYPE; // * Type of the parameter */  --- remarks: renamed type -> parameter_type
  end;

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These definitions describe a user property's type.

   [REMARKS]

   [SEE_ALSO]
   FMOD_STUDIO_USER_PROPERTY
   ]
  *)
  FMOD_STUDIO_USER_PROPERTY_TYPE = (
    FMOD_STUDIO_USER_PROPERTY_TYPE_INTEGER, // * Integer property */
    FMOD_STUDIO_USER_PROPERTY_TYPE_BOOLEAN, // * Boolean property */
    FMOD_STUDIO_USER_PROPERTY_TYPE_FLOAT,   // * Float property */
    FMOD_STUDIO_USER_PROPERTY_TYPE_STRING   // * String property */
    );

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These definitions describe built-in event properties.

   [REMARKS]
   For FMOD_STUDIO_EVENT_PROPERTY_CHANNELPRIORITY, a value of -1 uses the priority
   set in FMOD Studio, while other values override it. This property uses the same
   system as Channel::setPriority; this means lower values are higher priority
   (i.e. 0 is the highest priority while 256 is the lowest).

   [SEE_ALSO]
   Studio::EventInstance::getProperty
   Studio::EventInstance::setProperty
   ]
  *)
  FMOD_STUDIO_EVENT_PROPERTY = (
    FMOD_STUDIO_EVENT_PROPERTY_CHANNELPRIORITY,    // * Priority to set on low-level channels created by this event instance (-1 to 256). */
    FMOD_STUDIO_EVENT_PROPERTY_SCHEDULE_DELAY,     // * Schedule delay to synchronized playback for multiple tracks in DSP clocks, or -1 for default. */
    FMOD_STUDIO_EVENT_PROPERTY_SCHEDULE_LOOKAHEAD, // * Schedule look-ahead on the timeline in DSP clocks, or -1 for default. */
    FMOD_STUDIO_EVENT_PROPERTY_MINIMUM_DISTANCE,   // * Override the event's 3D minimum distance, or -1 for default. */
    FMOD_STUDIO_EVENT_PROPERTY_MAXIMUM_DISTANCE,   // * Override the event's 3D maximum distance, or -1 for default. */
    FMOD_STUDIO_EVENT_PROPERTY_MAX                 // * Maximum number of event properties supported. */
    );

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Structure describing a user property.

   [REMARKS]

   [SEE_ALSO]
   Studio::EventDescription::getUserProperty
   ]
  *)
  FMOD_STUDIO_USER_PROPERTY = record
    name : PAnsiChar;                               // * Name of the user property. */
    property_type : FMOD_STUDIO_USER_PROPERTY_TYPE; // * Type of the user property. Use this to select one of the following values. */
    case Integer of
      0 : (intvalue : Integer);      // * Value of the user property. Only valid when type is FMOD_STUDIO_USER_PROPERTY_TYPE_INTEGER. */
      1 : (boolvalue : FMOD_BOOL);   // * Value of the user property. Only valid when type is FMOD_STUDIO_USER_PROPERTY_TYPE_BOOLEAN. */
      2 : (floatvalue : Single);     // * Value of the user property. Only valid when type is FMOD_STUDIO_USER_PROPERTY_TYPE_FLOAT. */
      3 : (stringvalue : PAnsiChar); // * Value of the user property. Only valid when type is FMOD_STUDIO_USER_PROPERTY_TYPE_STRING. */
  end;

const

  (*
   [DEFINE]
   [
   [NAME]
   FMOD_STUDIO_SYSTEM_CALLBACK_TYPE

   [DESCRIPTION]
   These callback types are used with Studio::System::setCallback.

   [REMARKS]

   [SEE_ALSO]
   FMOD_STUDIO_SYSTEM_CALLBACK
   Studio::System::setCallback
   ]
  *)
  FMOD_STUDIO_SYSTEM_CALLBACK_PREUPDATE   = $00000001; // * Called at the start of the main Studio update.  For async mode this will be on its own thread. */
  FMOD_STUDIO_SYSTEM_CALLBACK_POSTUPDATE  = $00000002; // * Called at the end of the main Studio update.  For async mode this will be on its own thread. */
  FMOD_STUDIO_SYSTEM_CALLBACK_BANK_UNLOAD = $00000004; // * Called when bank has just been unloaded, after all resources are freed. CommandData will be the bank handle.*/
  FMOD_STUDIO_SYSTEM_CALLBACK_ALL         = $FFFFFFFF; // * Pass this mask to Studio::System::setCallback to receive all callback types. */
  (* [DEFINE_END] *)

type
  FMOD_STUDIO_SYSTEM_CALLBACK_TYPE = UInt32;

const
  (*
   [DEFINE]
   [
   [NAME]
   FMOD_STUDIO_EVENT_CALLBACK_TYPE

   [DESCRIPTION]
   These callback types are used with FMOD_STUDIO_EVENT_CALLBACK.

   [REMARKS]
   The data passed to the event callback function in the *parameters* argument varies based on the callback type.

   FMOD_STUDIO_EVENT_CALLBACK_STARTING is called when:

   * Studio::EventInstance::start has been called on an event which was not already playing.  The event will
   remain in this state until its sample data has been loaded.  If the event could not be started due to
   polyphony, then FMOD_STUDIO_EVENT_CALLBACK_START_FAILED will be called instead.

   FMOD_STUDIO_EVENT_CALLBACK_STARTED is called when:

   * The event has commenced playing.  Normally this callback will be issued immediately
   after FMOD_STUDIO_EVENT_CALLBACK_STARTING, but may be delayed until sample data has loaded.

   FMOD_STUDIO_EVENT_CALLBACK_RESTARTED is called when:

   * Studio::EventInstance::start has been called on an event which was already playing.

   FMOD_STUDIO_EVENT_CALLBACK_STOPPED is called when:

   * The event has stopped due to Studio::EventInstance::stop being called with FMOD_STUDIO_STOP_IMMEDIATE.
   * The event has finished fading out after Studio::EventInstance::stop was called with FMOD_STUDIO_STOP_ALLOWFADEOUT.
   * The event has stopped naturally by reaching the end of the timeline, and no further sounds can be triggered due to
   parameter changes.

   FMOD_STUDIO_EVENT_CALLBACK_START_FAILED is called when:

   * Studio::EventInstance::start has been called but the polyphony settings did not allow the event to start.  In
   this case none of FMOD_STUDIO_EVENT_CALLBACK_STARTING, FMOD_STUDIO_EVENT_CALLBACK_STARTED and FMOD_STUDIO_EVENT_CALLBACK_STOPPED
   will not be called.

   FMOD_STUDIO_EVENT_CALLBACK_CREATE_PROGRAMMER_SOUND is called when:

   * A programmer sound is about to play. FMOD expects the callback to provide an FMOD::Sound object for it to use.

   FMOD_STUDIO_EVENT_CALLBACK_DESTROY_PROGRAMMER_SOUND is called when:

   * A programmer sound has stopped playing. At this point it is safe to release the FMOD::Sound object that was used.

   [SEE_ALSO]
   Studio::EventDescription::setCallback
   Studio::EventInstance::setCallback
   FMOD_STUDIO_EVENT_CALLBACK
   ]
  *)
  FMOD_STUDIO_EVENT_CALLBACK_CREATED                  = $00000001; // * Called when an instance is fully created. Parameters = unused. */
  FMOD_STUDIO_EVENT_CALLBACK_DESTROYED                = $00000002; // * Called when an instance is just about to be destroyed. Parameters = unused. */
  FMOD_STUDIO_EVENT_CALLBACK_STARTING                 = $00000004; // * Called when an instance is preparing to start. Parameters = unused. */
  FMOD_STUDIO_EVENT_CALLBACK_STARTED                  = $00000008; // * Called when an instance starts playing. Parameters = unused. */
  FMOD_STUDIO_EVENT_CALLBACK_RESTARTED                = $00000010; // * Called when an instance is restarted. Parameters = unused. */
  FMOD_STUDIO_EVENT_CALLBACK_STOPPED                  = $00000020; // * Called when an instance stops. Parameters = unused. */
  FMOD_STUDIO_EVENT_CALLBACK_START_FAILED             = $00000040; // * Called when an instance did not start, e.g. due to polyphony. Parameters = unused. */
  FMOD_STUDIO_EVENT_CALLBACK_CREATE_PROGRAMMER_SOUND  = $00000080; // * Called when a programmer sound needs to be created in order to play a programmer instrument. Parameters = FMOD_STUDIO_PROGRAMMER_SOUND_PROPERTIES. */
  FMOD_STUDIO_EVENT_CALLBACK_DESTROY_PROGRAMMER_SOUND = $00000100; // * Called when a programmer sound needs to be destroyed. Parameters = FMOD_STUDIO_PROGRAMMER_SOUND_PROPERTIES. */
  FMOD_STUDIO_EVENT_CALLBACK_PLUGIN_CREATED           = $00000200; // * Called when a DSP plugin instance has just been created. Parameters = FMOD_STUDIO_PLUGIN_INSTANCE_PROPERTIES. */
  FMOD_STUDIO_EVENT_CALLBACK_PLUGIN_DESTROYED         = $00000400; // * Called when a DSP plugin instance is about to be destroyed. Parameters = FMOD_STUDIO_PLUGIN_INSTANCE_PROPERTIES. */
  FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER          = $00000800; // * Called when the timeline passes a named marker.  Parameters = FMOD_STUDIO_TIMELINE_MARKER_PROPERTIES. */
  FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_BEAT            = $00001000; // * Called when the timeline hits a beat in a tempo section.  Parameters = FMOD_STUDIO_TIMELINE_BEAT_PROPERTIES. */
  FMOD_STUDIO_EVENT_CALLBACK_SOUND_PLAYED             = $00002000; // * Called when the event plays a sound.  Parameters = FMOD::Sound. */
  FMOD_STUDIO_EVENT_CALLBACK_SOUND_STOPPED            = $00004000; // * Called when the event finishes playing a sound.  Parameters = FMOD::Sound. */
  FMOD_STUDIO_EVENT_CALLBACK_ALL                      = $FFFFFFFF; // * Pass this mask to Studio::EventDescription::setCallback or Studio::EventInstance::setCallback to receive all callback types. */
  (* [DEFINE_END] *)

type
  FMOD_STUDIO_EVENT_CALLBACK_TYPE = UInt32;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   This structure holds information about a programmer sound.

   [REMARKS]
   This data is passed to the event callback function when type is FMOD_STUDIO_EVENT_CALLBACK_CREATE_PROGRAMMER_SOUND
   or FMOD_STUDIO_EVENT_CALLBACK_DESTROY_PROGRAMMER_SOUND.

   The provided sound should be created with the FMOD_LOOP_NORMAL mode bit set. FMOD will set this bit internally if
   it is not set, possibly incurring a slight performance penalty.

   To support non-blocking loading of FSB subsounds, you can specify the subsound you want to use by setting the
   subsoundIndex field. This will cause FMOD to wait until the provided sound is ready and then get the specified
   subsound from it.

   [SEE_ALSO]
   FMOD_STUDIO_EVENT_CALLBACK
   FMOD_STUDIO_SOUND_INFO
   Studio::EventDescription::setCallback
   Studio::EventInstance::setCallback
   Studio::System::getSoundInfo
   ]
  *)
  FMOD_STUDIO_PROGRAMMER_SOUND_PROPERTIES = record
    name : PAnsiChar;        // * The name of the programmer instrument (set in FMOD Studio). */
    sound : PFMOD_SOUND;     // * The programmer-created sound. This should be filled in by the create callback, and cleaned up by the destroy callback. The provided sound should be created with the FMOD_LOOP_NORMAL mode bit set. This can be cast to/from FMOD::Sound* type. */
    subsoundIndex : Integer; // * The index of the subsound to use. This should be filled in by the create callback, or set to -1 if the provided sound should be used directly. Defaults to -1. */
  end;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   This structure holds information about a DSP plugin instance.

   [REMARKS]
   This data is passed to the event callback function when type is FMOD_STUDIO_EVENT_CALLBACK_PLUGIN_CREATED
   or FMOD_STUDIO_EVENT_CALLBACK_PLUGIN_DESTROYED.

   [SEE_ALSO]
   FMOD_STUDIO_EVENT_CALLBACK
   Studio::EventDescription::setCallback
   Studio::EventInstance::setCallback
   ]
  *)
  FMOD_STUDIO_PLUGIN_INSTANCE_PROPERTIES = record
    name : PAnsiChar; // * The name of the plugin effect or sound (set in FMOD Studio). */
    dsp : PFMOD_DSP;  // * The DSP plugin instance. This can be cast to FMOD::DSP* type. */
  end;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   This structure holds information about a marker on the timeline.

   [REMARKS]
   This data is passed to the event callback function when type is FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER.

   [SEE_ALSO]
   FMOD_STUDIO_EVENT_CALLBACK
   Studio::EventDescription::setCallback
   Studio::EventInstance::setCallback
   ]
  *)
  FMOD_STUDIO_TIMELINE_MARKER_PROPERTIES = record
    name : PAnsiChar;   // * The marker name */
    position : Integer; // * The position of the marker on the timeline in milliseconds. */
  end;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   This structure holds information about a beat on the timeline.

   [REMARKS]
   This data is passed to the event callback function when type is FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_BEAT.

   [SEE_ALSO]
   FMOD_STUDIO_EVENT_CALLBACK
   Studio::EventDescription::setCallback
   Studio::EventInstance::setCallback
   ]
  *)
  FMOD_STUDIO_TIMELINE_BEAT_PROPERTIES = record
    bar : Integer;                // * The bar number (starting from 1). */
    beat : Integer;               // * The beat number within the bar (starting from 1). */
    position : Integer;           // * The position of the beat on the timeline in milliseconds. */
    tempo : Single;               // * The current tempo in beats per minute. */
    timesignatureupper : Integer; // * The current time signature upper number (beats per bar). */
    timesignaturelower : Integer; // * The current time signature lower number (beat unit). */
  end;

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These values describe the playback state of an event instance.

   [REMARKS]

   [SEE_ALSO]
   Studio::EventInstance::getPlaybackState
   Studio::EventInstance::start
   Studio::EventInstance::stop
   FMOD_STUDIO_EVENT_CALLBACK_TYPE
   ]
  *)
  FMOD_STUDIO_PLAYBACK_STATE = (
    FMOD_STUDIO_PLAYBACK_PLAYING,    // * Currently playing. */
    FMOD_STUDIO_PLAYBACK_SUSTAINING, // * The timeline cursor is paused on a sustain point. */
    FMOD_STUDIO_PLAYBACK_STOPPED,    // * Not playing. */
    FMOD_STUDIO_PLAYBACK_STARTING,   // * Start has been called but the instance is not fully started yet. */
    FMOD_STUDIO_PLAYBACK_STOPPING    // * Stop has been called but the instance is not fully stopped yet. */
    );

  (*
   [ENUM]
   [
   [DESCRIPTION]
   Controls how to stop playback of an event instance.

   [REMARKS]

   [SEE_ALSO]
   Studio::EventInstance::stop
   Studio::Bus::stopAllEvents
   ]
  *)
  FMOD_STUDIO_STOP_MODE = (
    FMOD_STUDIO_STOP_ALLOWFADEOUT, // * Allows AHDSR modulators to complete their release, and DSP effect tails to play out. */
    FMOD_STUDIO_STOP_IMMEDIATE     // * Stops the event instance immediately. */
    );

const
  (*
   [DEFINE]
   [
   [NAME]
   FMOD_STUDIO_LOAD_BANK_FLAGS

   [DESCRIPTION]
   Flags passed into Studio loadBank commands to control bank load behaviour.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::loadBankFile
   Studio::System::loadBankMemory
   Studio::System::loadBankCustom
   ]
  *)
  FMOD_STUDIO_LOAD_BANK_NORMAL             = $00000000; // * Standard behaviour. */
  FMOD_STUDIO_LOAD_BANK_NONBLOCKING        = $00000001; // * Bank loading occurs asynchronously rather than occurring immediately. */
  FMOD_STUDIO_LOAD_BANK_DECOMPRESS_SAMPLES = $00000002; // * Force samples to decompress into memory when they are loaded, rather than staying compressed. */
  (* [DEFINE_END] *)

type

  FMOD_STUDIO_LOAD_BANK_FLAGS = UInt32;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Settings for advanced features like configuring memory and cpu usage.

   [REMARKS]
   Members marked with [r] mean the variable is modified by FMOD and is for reading purposes only.  Do not change this value.<br>
   Members marked with [w] mean the variable can be written to.  The user can set the value.<br>
   Members marked with [r/w] are either read or write depending on if you are using System::setAdvancedSettings (w) or System::getAdvancedSettings (r).

   [SEE_ALSO]
   Studio::System::setAdvancedSettings
   Studio::System::getAdvancedSettings
   FMOD_MODE
   ]
  *)
  FMOD_STUDIO_ADVANCEDSETTINGS = record
    cbsize : Integer;                 // * [w]   Size of this structure.  Use sizeof(FMOD_STUDIO_ADVANCEDSETTINGS)  NOTE: This must be set before calling Studio::System::getAdvancedSettings or Studio::System::setAdvancedSettings! */
    commandqueuesize : UInt32;        // * [r/w] Optional. Specify 0 to ignore. Specify the command queue size for studio async processing.  Default 32kB. */
    handleinitialsize : UInt32;       // * [r/w] Optional. Specify 0 to ignore. Specify the initial size to allocate for handles.  Memory for handles will grow as needed in pages. Default 8192 * sizeof(void*) */
    studioupdateperiod : Integer;     // * [r/w] Optional. Specify 0 to ignore. Specify the update period of Studio when in async mode, in milliseconds.  Will be quantised to the nearest multiple of mixer duration.  Default is 20ms. */
    idlesampledatapoolsize : Integer; // * [r/w] Optional. Specify 0 to ignore. Specify the amount of sample data to keep in memory when no longer used, to avoid repeated disk IO.  Use -1 to disable.  Default is 256kB. */
  end;

  PFMOD_STUDIO_ADVANCEDSETTINGS = ^FMOD_STUDIO_ADVANCEDSETTINGS;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Performance information for FMOD Studio and low level systems.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::getCPUUsage
   ]
  *)
  FMOD_STUDIO_CPU_USAGE = record
    dspusage : Single;      // * Returns the % CPU time taken by DSP processing on the low level mixer thread. */
    streamusage : Single;   // * Returns the % CPU time taken by stream processing on the low level stream thread. */
    geometryusage : Single; // * Returns the % CPU time taken by geometry processing on the low level geometry thread. */
    updateusage : Single;   // * Returns the % CPU time taken by low level update, called as part of the studio update. */
    studiousage : Single;   // * Returns the % CPU time taken by studio update, called from the studio thread. Does not include low level update time. */
  end;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Information for a single buffer in FMOD Studio.

   [REMARKS]

   [SEE_ALSO]
   FMOD_STUDIO_BUFFER_USAGE
   ]
  *)
  FMOD_STUDIO_BUFFER_INFO = record
    currentusage : Integer; // * Current buffer usage in bytes. */
    peakusage : Integer;    // * Peak buffer usage in bytes. */
    capacity : Integer;     // * Buffer capacity in bytes. */
    stallcount : Integer;   // * Cumulative number of stalls due to buffer overflow. */
    stalltime : Single;     // * Cumulative amount of time stalled due to buffer overflow, in seconds. */
  end;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Information for FMOD Studio buffer usage.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::getBufferUsage
   Studio::System::resetBufferUsage
   FMOD_STUDIO_BUFFER_INFO
   ]
  *)
  FMOD_STUDIO_BUFFER_USAGE = record
    studiocommandqueue : FMOD_STUDIO_BUFFER_INFO; // * Information for the Studio Async Command buffer, controlled by FMOD_STUDIO_ADVANCEDSETTINGS commandQueueSize. */
    studiohandle : FMOD_STUDIO_BUFFER_INFO;       // * Information for the Studio handle table, controlled by FMOD_STUDIO_ADVANCEDSETTINGS handleInitialSize. */
  end;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Information for loading a sound from a sound table.

   [REMARKS]
   The name_or_data member points into FMOD internal memory, which will become
   invalid if the sound table bank is unloaded.

   If mode flags such as FMOD_CREATESTREAM, FMOD_CREATECOMPRESSEDSAMPLE or FMOD_NONBLOCKING are required,
   it is up to the user to OR them together when calling System::createSound.

   [SEE_ALSO]
   Studio::System::getSoundInfo
   System::createSound
   ]
  *)
  FMOD_STUDIO_SOUND_INFO = record
    name_or_data : PAnsiChar;        // * The filename or memory buffer that contains the sound. */
    mode : FMOD_MODE;                // * Mode flags required for loading the sound. */
    exinfo : FMOD_CREATESOUNDEXINFO; // * Extra information required for loading the sound. */
    subsoundIndex : Integer;         // * Subsound index for loading the sound. */
  end;

const
  (*
   [DEFINE]
   [
   [NAME]
   FMOD_STUDIO_COMMANDCAPTURE_FLAGS

   [DESCRIPTION]
   Flags passed into Studio::System::startCommandCapture.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::startCommandCapture
   ]
  *)
  FMOD_STUDIO_COMMANDCAPTURE_NORMAL             = $00000000; // * Standard behaviour. */
  FMOD_STUDIO_COMMANDCAPTURE_FILEFLUSH          = $00000001; // * Call file flush on every command. */
  FMOD_STUDIO_COMMANDCAPTURE_SKIP_INITIAL_STATE = $00000002; // * Normally the initial state of banks and instances is captured, unless this flag is set. */
  (* [DEFINE_END] *)

type
  FMOD_STUDIO_COMMANDCAPTURE_FLAGS = UInt32;

const
  (*
   [DEFINE]
   [
   [NAME]
   FMOD_STUDIO_COMMANDREPLAY_FLAGS

   [DESCRIPTION]
   Flags passed into Studio::System::loadCommandReplay.

   [REMARKS]

   [SEE_ALSO]
   Studio::System::loadCommandReplay
   ]
  *)
  FMOD_STUDIO_COMMANDREPLAY_NORMAL       = $00000000; // * Standard behaviour. */
  FMOD_STUDIO_COMMANDREPLAY_SKIP_CLEANUP = $00000001; // * Normally the playback will release any created resources when it stops, unless this flag is set. */
  FMOD_STUDIO_COMMANDREPLAY_FAST_FORWARD = $00000002; // * Play back at maximum speed, ignoring the timing of the original replay. */
  (* [DEFINE_END] *)

type
  FMOD_STUDIO_COMMANDREPLAY_FLAGS = UInt32;

  (*
   [ENUM]
   [
   [DESCRIPTION]
   Used to distinguish the types used in command replays.

   [REMARKS]

   [SEE_ALSO]
   ]
  *)
  FMOD_STUDIO_INSTANCETYPE = (
    FMOD_STUDIO_INSTANCETYPE_NONE,
    FMOD_STUDIO_INSTANCETYPE_SYSTEM,
    FMOD_STUDIO_INSTANCETYPE_EVENTDESCRIPTION,
    FMOD_STUDIO_INSTANCETYPE_EVENTINSTANCE,
    FMOD_STUDIO_INSTANCETYPE_PARAMETERINSTANCE,
    FMOD_STUDIO_INSTANCETYPE_BUS,
    FMOD_STUDIO_INSTANCETYPE_VCA,
    FMOD_STUDIO_INSTANCETYPE_BANK,
    FMOD_STUDIO_INSTANCETYPE_COMMANDREPLAY
    );

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Information about a single command in a command replay file.

   [REMARKS]
   This information has metadata about the command at the given index.  Note that the handle fields are
   from the recorded session, and will no longer correspond to any actual object type in the current
   system.

   [SEE_ALSO]
   Studio::CommandReplay::getCommandInfo
   ]
  *)
  FMOD_STUDIO_COMMAND_INFO = record
    commandname : PAnsiChar;                 // * The full name of the API function for this command. */
    parentcommandindex : Integer;            // * For commands that operate on an instance, this is the command that created the instance. */
    framenumber : Integer;                   // * The frame the command belongs to. */
    frametime : Single;                      // * The playback time at which this command will be executed. */
    instancetype : FMOD_STUDIO_INSTANCETYPE; // * The type of object that this command uses as an instance. */
    outputtype : FMOD_STUDIO_INSTANCETYPE;   // * The type of object that this command outputs, if any. */
    instancehandle : UInt32;                 // * The original handle value of the instance.  This will no longer correspond to any actual object in playback. */
    outputhandle : UInt32;                   // * The original handle value of the command output.  This will no longer correspond to any actual object in playback. */
  end;

  (*
   FMOD Studio callbacks.
  *)
  FMOD_STUDIO_SYSTEM_CALLBACK = function(system : PFMOD_STUDIO_SYSTEM; callback_type : FMOD_STUDIO_SYSTEM_CALLBACK_TYPE; commanddata : Pointer; userdata : Pointer) : FMOD_RESULT; stdcall;

  FMOD_STUDIO_EVENT_CALLBACK = function(callback_type : FMOD_STUDIO_EVENT_CALLBACK_TYPE; event : PFMOD_STUDIO_EVENTINSTANCE; parameters: Pointer) : FMOD_RESULT; stdcall;
  FMOD_STUDIO_COMMANDREPLAY_FRAME_CALLBACK = function(replay : FMOD_STUDIO_COMMANDREPLAY; commandIndex : Integer; currentTime : single;  userdata: Pointer) : FMOD_RESULT; stdcall;
  FMOD_STUDIO_COMMANDREPLAY_LOAD_BANK_CALLBACK = function(replay: FMOD_STUDIO_COMMANDREPLAY; commandIndex : Integer; const bankGuid : PFMOD_GUID; bankFilename : PAnsiChar; flags : FMOD_STUDIO_LOAD_BANK_FLAGS; var bank: FMOD_STUDIO_BANK; userdata: Pointer) : FMOD_RESULT; stdcall;
  FMOD_STUDIO_COMMANDREPLAY_CREATE_INSTANCE_CALLBACK = function(replay : PFMOD_STUDIO_COMMANDREPLAY; commandIndex : Integer; eventDescription : PFMOD_STUDIO_EVENTDESCRIPTION; var instance : PFMOD_STUDIO_EVENTINSTANCE; userdata : Pointer) : FMOD_RESULT; stdcall;

  {$MINENUMSIZE 1}

implementation

end.
