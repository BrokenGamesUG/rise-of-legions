unit FMOD.Common;

(* ==================================================================================================  */
 /*Translated by Martin Lange 09.2017                                                                  */
 /*    original:                                                                                       */
 /*                                                                                                    */
 /* FMOD Studio - Common C/C++ header file. Copyright (c), Firelight Technologies Pty, Ltd. 2004-2017. */
 /*                                                                                                    */
 /* This header is included by fmod.hpp (C++ interface) and fmod.h (C interface) therefore is the      */
 /* base header for all FMOD headers.                                                                  */
 /* ================================================================================================== *)

interface


{$MINENUMSIZE 4}
const
  (*
   FMOD version number.  Check this against FMOD::System::getVersion.
   0xaaaabbcc -> aaaa = major version number.  bb = minor version number.  cc = development version number.
  *)

  FMOD_VERSION = $00011001;

type
  (*
   FMOD types.
  *)
  FMOD_BOOL = Integer;

const
  FMOD_TRUE  = 1;
  FMOD_FALSE = 0;

type

  FMOD_SYSTEM = record
  end;

  PFMOD_SYSTEM = ^FMOD_SYSTEM;

  FMOD_SOUND = record
  end;

  PFMOD_SOUND = ^FMOD_SOUND;

  FMOD_CHANNELCONTROL = record
  end;

  PFMOD_CHANNELCONTROL = ^FMOD_CHANNELCONTROL;

  FMOD_CHANNEL = record
  end;

  PFMOD_CHANNEL = ^FMOD_CHANNEL;

  FMOD_CHANNELGROUP = record
  end;

  PFMOD_CHANNELGROUP = ^FMOD_CHANNELGROUP;

  FMOD_SOUNDGROUP = record
  end;

  PFMOD_SOUNDGROUP = ^FMOD_SOUNDGROUP;

  FMOD_REVERB3D = record
  end;

  PFMOD_REVERB3D = ^FMOD_REVERB3D;

  FMOD_DSP = record
  end;

  PFMOD_DSP = ^FMOD_DSP;

  FMOD_DSPCONNECTION = record
  end;

  PFMOD_DSPCONNECTION = ^FMOD_DSPCONNECTION;

  FMOD_POLYGON = record
  end;

  PFMOD_POLYGON = ^FMOD_POLYGON;

  FMOD_GEOMETRY = record
  end;

  PFMOD_GEOMETRY = ^FMOD_GEOMETRY;

  FMOD_SYNCPOINT = record
  end;

  PFMOD_SYNCPOINT = ^FMOD_SYNCPOINT;

  FMOD_ASYNCREADINFO = record
  end;

  PFMOD_ASYNCREADINFO = ^FMOD_ASYNCREADINFO;

  FMOD_MODE = UInt32;
  FMOD_TIMEUNIT = UInt32;
  FMOD_INITFLAGS = UInt32;
  FMOD_DEBUG_FLAGS = UInt32;
  FMOD_MEMORY_TYPE = UInt32;
  FMOD_SYSTEM_CALLBACK_TYPE = UInt32;
  FMOD_CHANNELMASK = UInt32;
  FMOD_DRIVER_STATE = UInt32;
  FMOD_PORT_TYPE = UInt32;
  FMOD_PORT_INDEX = UInt64;

  (* $ FMOD result start $ *)
  (*
   [ENUM]
   [
   [DESCRIPTION]
   error codes.  Returned from every function.

   [REMARKS]

   [SEE_ALSO]
   ]
  *)
  FMOD_RESULT = (
    FMOD_OK,                            // * No errors. */
    FMOD_ERR_BADCOMMAND,                // * Tried to call a function on a data type that does not allow this type of functionality (ie calling Sound::lock on a streaming sound). */
    FMOD_ERR_CHANNEL_ALLOC,             // * Error trying to allocate a channel. */
    FMOD_ERR_CHANNEL_STOLEN,            // * The specified channel has been reused to play another sound. */
    FMOD_ERR_DMA,                       // * DMA Failure.  See debug output for more information. */
    FMOD_ERR_DSP_CONNECTION,            // * DSP connection error.  Connection possibly caused a cyclic dependency or connected dsps with incompatible buffer counts. */
    FMOD_ERR_DSP_DONTPROCESS,           // * DSP return code from a DSP process query callback.  Tells mixer not to call the process callback and therefore not consume CPU.  Use this to optimize the DSP graph. */
    FMOD_ERR_DSP_FORMAT,                // * DSP Format error.  A DSP unit may have attempted to connect to this network with the wrong format, or a matrix may have been set with the wrong size if the target unit has a specified channel map. */
    FMOD_ERR_DSP_INUSE,                 // * DSP is already in the mixer's DSP network. It must be removed before being reinserted or released. */
    FMOD_ERR_DSP_NOTFOUND,              // * DSP connection error.  Couldn't find the DSP unit specified. */
    FMOD_ERR_DSP_RESERVED,              // * DSP operation error.  Cannot perform operation on this DSP as it is reserved by the system. */
    FMOD_ERR_DSP_SILENCE,               // * DSP return code from a DSP process query callback.  Tells mixer silence would be produced from read, so go idle and not consume CPU.  Use this to optimize the DSP graph. */
    FMOD_ERR_DSP_TYPE,                  // * DSP operation cannot be performed on a DSP of this type. */
    FMOD_ERR_FILE_BAD,                  // * Error loading file. */
    FMOD_ERR_FILE_COULDNOTSEEK,         // * Couldn't perform seek operation.  This is a limitation of the medium (ie netstreams) or the file format. */
    FMOD_ERR_FILE_DISKEJECTED,          // * Media was ejected while reading. */
    FMOD_ERR_FILE_EOF,                  // * End of file unexpectedly reached while trying to read essential data (truncated?). */
    FMOD_ERR_FILE_ENDOFDATA,            // * End of current chunk reached while trying to read data. */
    FMOD_ERR_FILE_NOTFOUND,             // * File not found. */
    FMOD_ERR_FORMAT,                    // * Unsupported file or audio format. */
    FMOD_ERR_HEADER_MISMATCH,           // * There is a version mismatch between the FMOD header and either the FMOD Studio library or the FMOD Low Level library. */
    FMOD_ERR_HTTP,                      // * A HTTP error occurred. This is a catch-all for HTTP errors not listed elsewhere. */
    FMOD_ERR_HTTP_ACCESS,               // * The specified resource requires authentication or is forbidden. */
    FMOD_ERR_HTTP_PROXY_AUTH,           // * Proxy authentication is required to access the specified resource. */
    FMOD_ERR_HTTP_SERVER_ERROR,         // * A HTTP server error occurred. */
    FMOD_ERR_HTTP_TIMEOUT,              // * The HTTP request timed out. */
    FMOD_ERR_INITIALIZATION,            // * FMOD was not initialized correctly to support this function. */
    FMOD_ERR_INITIALIZED,               // * Cannot call this command after System::init. */
    FMOD_ERR_INTERNAL,                  // * An error occurred that wasn't supposed to.  Contact support. */
    FMOD_ERR_INVALID_FLOAT,             // * Value passed in was a NaN, Inf or denormalized float. */
    FMOD_ERR_INVALID_HANDLE,            // * An invalid object handle was used. */
    FMOD_ERR_INVALID_PARAM,             // * An invalid parameter was passed to this function. */
    FMOD_ERR_INVALID_POSITION,          // * An invalid seek position was passed to this function. */
    FMOD_ERR_INVALID_SPEAKER,           // * An invalid speaker was passed to this function based on the current speaker mode. */
    FMOD_ERR_INVALID_SYNCPOINT,         // * The syncpoint did not come from this sound handle. */
    FMOD_ERR_INVALID_THREAD,            // * Tried to call a function on a thread that is not supported. */
    FMOD_ERR_INVALID_VECTOR,            // * The vectors passed in are not unit length, or perpendicular. */
    FMOD_ERR_MAXAUDIBLE,                // * Reached maximum audible playback count for this sound's soundgroup. */
    FMOD_ERR_MEMORY,                    // * Not enough memory or resources. */
    FMOD_ERR_MEMORY_CANTPOINT,          // * Can't use FMOD_OPENMEMORY_POINT on non PCM source data, or non mp3/xma/adpcm data if FMOD_CREATECOMPRESSEDSAMPLE was used. */
    FMOD_ERR_NEEDS3D,                   // * Tried to call a command on a 2d sound when the command was meant for 3d sound. */
    FMOD_ERR_NEEDSHARDWARE,             // * Tried to use a feature that requires hardware support. */
    FMOD_ERR_NET_CONNECT,               // * Couldn't connect to the specified host. */
    FMOD_ERR_NET_SOCKET_ERROR,          // * A socket error occurred.  This is a catch-all for socket-related errors not listed elsewhere. */
    FMOD_ERR_NET_URL,                   // * The specified URL couldn't be resolved. */
    FMOD_ERR_NET_WOULD_BLOCK,           // * Operation on a non-blocking socket could not complete immediately. */
    FMOD_ERR_NOTREADY,                  // * Operation could not be performed because specified sound/DSP connection is not ready. */
    FMOD_ERR_OUTPUT_ALLOCATED,          // * Error initializing output device, but more specifically, the output device is already in use and cannot be reused. */
    FMOD_ERR_OUTPUT_CREATEBUFFER,       // * Error creating hardware sound buffer. */
    FMOD_ERR_OUTPUT_DRIVERCALL,         // * A call to a standard soundcard driver failed, which could possibly mean a bug in the driver or resources were missing or exhausted. */
    FMOD_ERR_OUTPUT_FORMAT,             // * Soundcard does not support the specified format. */
    FMOD_ERR_OUTPUT_INIT,               // * Error initializing output device. */
    FMOD_ERR_OUTPUT_NODRIVERS,          // * The output device has no drivers installed.  If pre-init, FMOD_OUTPUT_NOSOUND is selected as the output mode.  If post-init, the function just fails. */
    FMOD_ERR_PLUGIN,                    // * An unspecified error has been returned from a plugin. */
    FMOD_ERR_PLUGIN_MISSING,            // * A requested output, dsp unit type or codec was not available. */
    FMOD_ERR_PLUGIN_RESOURCE,           // * A resource that the plugin requires cannot be found. (ie the DLS file for MIDI playback) */
    FMOD_ERR_PLUGIN_VERSION,            // * A plugin was built with an unsupported SDK version. */
    FMOD_ERR_RECORD,                    // * An error occurred trying to initialize the recording device. */
    FMOD_ERR_REVERB_CHANNELGROUP,       // * Reverb properties cannot be set on this channel because a parent channelgroup owns the reverb connection. */
    FMOD_ERR_REVERB_INSTANCE,           // * Specified instance in FMOD_REVERB_PROPERTIES couldn't be set. Most likely because it is an invalid instance number or the reverb doesn't exist. */
    FMOD_ERR_SUBSOUNDS,                 // * The error occurred because the sound referenced contains subsounds when it shouldn't have, or it doesn't contain subsounds when it should have.  The operation may also not be able to be performed on a parent sound. */
    FMOD_ERR_SUBSOUND_ALLOCATED,        // * This subsound is already being used by another sound, you cannot have more than one parent to a sound.  Null out the other parent's entry first. */
    FMOD_ERR_SUBSOUND_CANTMOVE,         // * Shared subsounds cannot be replaced or moved from their parent stream, such as when the parent stream is an FSB file. */
    FMOD_ERR_TAGNOTFOUND,               // * The specified tag could not be found or there are no tags. */
    FMOD_ERR_TOOMANYCHANNELS,           // * The sound created exceeds the allowable input channel count.  This can be increased using the 'maxinputchannels' parameter in System::setSoftwareFormat. */
    FMOD_ERR_TRUNCATED,                 // * The retrieved string is too long to fit in the supplied buffer and has been truncated. */
    FMOD_ERR_UNIMPLEMENTED,             // * Something in FMOD hasn't been implemented when it should be! contact support! */
    FMOD_ERR_UNINITIALIZED,             // * This command failed because System::init or System::setDriver was not called. */
    FMOD_ERR_UNSUPPORTED,               // * A command issued was not supported by this object.  Possibly a plugin without certain callbacks specified. */
    FMOD_ERR_VERSION,                   // * The version number of this file format is not supported. */
    FMOD_ERR_EVENT_ALREADY_LOADED,      // * The specified bank has already been loaded. */
    FMOD_ERR_EVENT_LIVEUPDATE_BUSY,     // * The live update connection failed due to the game already being connected. */
    FMOD_ERR_EVENT_LIVEUPDATE_MISMATCH, // * The live update connection failed due to the game data being out of sync with the tool. */
    FMOD_ERR_EVENT_LIVEUPDATE_TIMEOUT,  // * The live update connection timed out. */
    FMOD_ERR_EVENT_NOTFOUND,            // * The requested event, bus or vca could not be found. */
    FMOD_ERR_STUDIO_UNINITIALIZED,      // * The Studio::System object is not yet initialized. */
    FMOD_ERR_STUDIO_NOT_LOADED,         // * The specified resource is not loaded, so it can't be unloaded. */
    FMOD_ERR_INVALID_STRING,            // * An invalid string was passed to this function. */
    FMOD_ERR_ALREADY_LOCKED,            // * The specified resource is already locked. */
    FMOD_ERR_NOT_LOCKED,                // * The specified resource is not locked, so it can't be unlocked. */
    FMOD_ERR_RECORD_DISCONNECTED,       // * The specified recording driver has been disconnected. */
    FMOD_ERR_TOOMANYSAMPLES             // * The length provided exceeds the allowable limit. */
    );
  (* $ fmod result end $ *)

const
  (*
   [DEFINE]
   [
   [NAME]
   FMOD_INITFLAGS

   [DESCRIPTION]
   Initialization flags.  Use them with System::init in the *flags* parameter to change various behavior.

   [REMARKS]
   Use System::setAdvancedSettings to adjust settings for some of the features that are enabled by these flags.

   [SEE_ALSO]
   System::init
   System::update
   System::setAdvancedSettings
   Channel::set3DOcclusion
   ]
  *)
  FMOD_INIT_NORMAL                     = $00000000; // * Initialize normally */
  FMOD_INIT_STREAM_FROM_UPDATE         = $00000001; // * No stream thread is created internally.  Streams are driven from System::update.  Mainly used with non-realtime outputs. */
  FMOD_INIT_MIX_FROM_UPDATE            = $00000002; // * No mixer thread is created internally. Mixing is driven from System::update. Only applies to polling based output modes such as FMOD_OUTPUTTYPE_NOSOUND, FMOD_OUTPUTTYPE_WAVWRITER, FMOD_OUTPUTTYPE_DSOUND, FMOD_OUTPUTTYPE_WINMM,FMOD_OUTPUTTYPE_XAUDIO. */
  FMOD_INIT_3D_RIGHTHANDED             = $00000004; // * FMOD will treat +X as right, +Y as up and +Z as backwards (towards you). */
  FMOD_INIT_CHANNEL_LOWPASS            = $00000100; // * All FMOD_3D based voices will add a software lowpass filter effect into the DSP chain which is automatically used when Channel::set3DOcclusion is used or the geometry API.   This also causes sounds to sound duller when the sound goes behind the listener, as a fake HRTF style effect.  Use System::setAdvancedSettings to disable or adjust cutoff frequency for this feature. */
  FMOD_INIT_CHANNEL_DISTANCEFILTER     = $00000200; // * All FMOD_3D based voices will add a software lowpass and highpass filter effect into the DSP chain which will act as a distance-automated bandpass filter. Use System::setAdvancedSettings to adjust the center frequency. */
  FMOD_INIT_PROFILE_ENABLE             = $00010000; // * Enable TCP/IP based host which allows FMOD Designer or FMOD Profiler to connect to it, and view memory, CPU and the DSP network graph in real-time. */
  FMOD_INIT_VOL0_BECOMES_VIRTUAL       = $00020000; // * Any sounds that are 0 volume will go virtual and not be processed except for having their positions updated virtually.  Use System::setAdvancedSettings to adjust what volume besides zero to switch to virtual at. */
  FMOD_INIT_GEOMETRY_USECLOSEST        = $00040000; // * With the geometry engine, only process the closest polygon rather than accumulating all polygons the sound to listener line intersects. */
  FMOD_INIT_PREFER_DOLBY_DOWNMIX       = $00080000; // * When using FMOD_SPEAKERMODE_5POINT1 with a stereo output device, use the Dolby Pro Logic II downmix algorithm instead of the SRS Circle Surround algorithm. */
  FMOD_INIT_THREAD_UNSAFE              = $00100000; // * Disables thread safety for API calls. Only use this if FMOD low level is being called from a single thread, and if Studio API is not being used! */
  FMOD_INIT_PROFILE_METER_ALL          = $00200000; // * Slower, but adds level metering for every single DSP unit in the graph.  Use DSP::setMeteringEnabled to turn meters off individually. */
  FMOD_INIT_DISABLE_SRS_HIGHPASSFILTER = $00400000; // * Using FMOD_SPEAKERMODE_5POINT1 with a stereo output device will enable the SRS Circle Surround downmixer. By default the SRS downmixer applies a high pass filter with a cutoff frequency of 80Hz. Use this flag to diable the high pass fitler, or use FMOD_INIT_PREFER_DOLBY_DOWNMIX to use the Dolby Pro Logic II downmix algorithm instead. */
  (* [DEFINE_END] *)

type
  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Structure describing a globally unique identifier.

   [REMARKS]

   [SEE_ALSO]
   System::getDriverInfo
   ]
  *)
  FMOD_GUID = record
    Data1 : UInt32;                 // * Specifies the first 8 hexadecimal digits of the GUID */
    Data2 : UInt16;                 // * Specifies the first group of 4 hexadecimal digits.   */
    Data3 : UInt16;                 // * Specifies the second group of 4 hexadecimal digits.  */
    Data4 : array [0 .. 7] of Byte; // * Array of 8 bytes. The first 2 bytes contain the third group of 4 hexadecimal digits. The remaining 6 bytes contain the final 12 hexadecimal digits. */
  end;

  PFMOD_GUID = ^FMOD_GUID;

  (*
   [ENUM]
   [
   [DESCRIPTION]
   Used to distinguish if a FMOD_CHANNELCONTROL parameter is actually a channel or a channelgroup.

   [REMARKS]
   Cast the FMOD_CHANNELCONTROL to an FMOD_CHANNEL/FMOD::Channel, or FMOD_CHANNELGROUP/FMOD::ChannelGroup if specific functionality is needed for either class.
   Otherwise use as FMOD_CHANNELCONTROL/FMOD::ChannelControl and use that API.

   [SEE_ALSO]
   Channel::setCallback
   ChannelGroup::setCallback
   ]
  *)
  FMOD_CHANNELCONTROL_TYPE = (
    FMOD_CHANNELCONTROL_CHANNEL,
    FMOD_CHANNELCONTROL_CHANNELGROUP
    );

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Structure describing a point in 3D space.

   [REMARKS]
   FMOD uses a left handed co-ordinate system by default.<br>
   To use a right handed co-ordinate system specify FMOD_INIT_3D_RIGHTHANDED from FMOD_INITFLAGS in System::init.

   [SEE_ALSO]
   System::set3DListenerAttributes
   System::get3DListenerAttributes
   Channel::set3DAttributes
   Channel::get3DAttributes
   Channel::set3DCustomRolloff
   Channel::get3DCustomRolloff
   Sound::set3DCustomRolloff
   Sound::get3DCustomRolloff
   Geometry::addPolygon
   Geometry::setPolygonVertex
   Geometry::getPolygonVertex
   Geometry::setRotation
   Geometry::getRotation
   Geometry::setPosition
   Geometry::getPosition
   Geometry::setScale
   Geometry::getScale
   FMOD_INITFLAGS
   ]
  *)
  FMOD_VECTOR = record
    x : single; // * X co-ordinate in 3D space. */
    y : single; // * Y co-ordinate in 3D space. */
    z : single; // * Z co-ordinate in 3D space. */
  end;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Structure describing a position, velocity and orientation.

   [REMARKS]

   [SEE_ALSO]
   FMOD_VECTOR
   FMOD_DSP_PARAMETER_3DATTRIBUTES
   ]
  *)
  FMOD_3D_ATTRIBUTES = record
    position : FMOD_VECTOR; // * The position of the object in world space, measured in distance units.  */
    velocity : FMOD_VECTOR; // * The velocity of the object measured in distance units **per second**.  */
    forward : FMOD_VECTOR;  // * The forwards orientation of the object.  This vector must be of unit length (1.0) and perpendicular to the up vector. */
    up : FMOD_VECTOR;       // * The upwards orientation of the object.  This vector must be of unit length (1.0) and perpendicular to the forward vector. */
  end;

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These callback types are used with Channel::setCallback.

   [REMARKS]
   Each callback has commanddata parameters passed as int unique to the type of callback.<br>
   See reference to FMOD_CHANNELCONTROL_CALLBACK to determine what they might mean for each type of callback.<br>
   <br>
   <b>Note!</b>  Currently the user must call System::update for these callbacks to trigger!

   [SEE_ALSO]
   Channel::setCallback
   ChannelGroup::setCallback
   FMOD_CHANNELCONTROL_CALLBACK
   System::update
   ]
  *)
  FMOD_CHANNELCONTROL_CALLBACK_TYPE = (
    FMOD_CHANNELCONTROL_CALLBACK_END,          // * Called when a sound ends. */
    FMOD_CHANNELCONTROL_CALLBACK_VIRTUALVOICE, // * Called when a voice is swapped out or swapped in. */
    FMOD_CHANNELCONTROL_CALLBACK_SYNCPOINT,    // * Called when a syncpoint is encountered.  Can be from wav file markers. */
    FMOD_CHANNELCONTROL_CALLBACK_OCCLUSION,    // * Called when the channel has its geometry occlusion value calculated.  Can be used to clamp or change the value. */

    FMOD_CHANNELCONTROL_CALLBACK_MAX// * Maximum number of callback types supported. */
    );

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These definitions describe the native format of the hardware or software buffer that will be used.

   [REMARKS]
   This is the format the native hardware or software buffer will be or is created in.

   [SEE_ALSO]
   System::createSound
   Sound::getFormat
   ]
  *)
  FMOD_SOUND_FORMAT = (
    FMOD_SOUND_FORMAT_NONE,      // * Unitialized / unknown. */
    FMOD_SOUND_FORMAT_PCM8,      // * 8bit integer PCM data. */
    FMOD_SOUND_FORMAT_PCM16,     // * 16bit integer PCM data. */
    FMOD_SOUND_FORMAT_PCM24,     // * 24bit integer PCM data. */
    FMOD_SOUND_FORMAT_PCM32,     // * 32bit integer PCM data. */
    FMOD_SOUND_FORMAT_PCMFLOAT,  // * 32bit floating point PCM data. */
    FMOD_SOUND_FORMAT_BITSTREAM, // * Sound data is in its native compressed format. */

    FMOD_SOUND_FORMAT_MAX// * Maximum number of sound formats supported. */
    );

  (*
   [ENUM]
   [
   [DESCRIPTION]
   When creating a multichannel sound, FMOD will pan them to their default speaker locations, for example a 6 channel sound will default to one channel per 5.1 output speaker.<br>
   Another example is a stereo sound.  It will default to left = front left, right = front right.<br>
   <br>
   This is for sounds that are not 'default'.  For example you might have a sound that is 6 channels but actually made up of 3 stereo pairs, that should all be located in front left, front right only.

   [REMARKS]

   [SEE_ALSO]
   FMOD_CREATESOUNDEXINFO
   FMOD_MAX_CHANNEL_WIDTH
   ]
  *)
  FMOD_CHANNELORDER = (
    FMOD_CHANNELORDER_DEFAULT,    // * Left, Right, Center, LFE, Surround Left, Surround Right, Back Left, Back Right (see FMOD_SPEAKER enumeration)   */
    FMOD_CHANNELORDER_WAVEFORMAT, // * Left, Right, Center, LFE, Back Left, Back Right, Surround Left, Surround Right (as per Microsoft .wav WAVEFORMAT structure master order) */
    FMOD_CHANNELORDER_PROTOOLS,   // * Left, Center, Right, Surround Left, Surround Right, LFE */
    FMOD_CHANNELORDER_ALLMONO,    // * Mono, Mono, Mono, Mono, Mono, Mono, ... (each channel all the way up to FMOD_MAX_CHANNEL_WIDTH channels are treated as if they were mono) */
    FMOD_CHANNELORDER_ALLSTEREO,  // * Left, Right, Left, Right, Left, Right, ... (each pair of channels is treated as stereo all the way up to FMOD_MAX_CHANNEL_WIDTH channels) */
    FMOD_CHANNELORDER_ALSA,       // * Left, Right, Surround Left, Surround Right, Center, LFE (as per Linux ALSA channel order) */

    FMOD_CHANNELORDER_MAX// * Maximum number of channel orderings supported. */
    );

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These definitions describe the type of song being played.

   [REMARKS]

   [SEE_ALSO]
   Sound::getFormat
   ]
  *)
  FMOD_SOUND_TYPE = (
    FMOD_SOUND_TYPE_UNKNOWN,          // * 3rd party / unknown plugin format. */
    FMOD_SOUND_TYPE_AIFF,             // * AIFF. */
    FMOD_SOUND_TYPE_ASF,              // * Microsoft Advanced Systems Format (ie WMA/ASF/WMV). */
    FMOD_SOUND_TYPE_DLS,              // * Sound font / downloadable sound bank. */
    FMOD_SOUND_TYPE_FLAC,             // * FLAC lossless codec. */
    FMOD_SOUND_TYPE_FSB,              // * FMOD Sample Bank. */
    FMOD_SOUND_TYPE_IT,               // * Impulse Tracker. */
    FMOD_SOUND_TYPE_MIDI,             // * MIDI. */
    FMOD_SOUND_TYPE_MOD,              // * Protracker / Fasttracker MOD. */
    FMOD_SOUND_TYPE_MPEG,             // * MP2/MP3 MPEG. */
    FMOD_SOUND_TYPE_OGGVORBIS,        // * Ogg vorbis. */
    FMOD_SOUND_TYPE_PLAYLIST,         // * Information only from ASX/PLS/M3U/WAX playlists */
    FMOD_SOUND_TYPE_RAW,              // * Raw PCM data. */
    FMOD_SOUND_TYPE_S3M,              // * ScreamTracker 3. */
    FMOD_SOUND_TYPE_USER,             // * User created sound. */
    FMOD_SOUND_TYPE_WAV,              // * Microsoft WAV. */
    FMOD_SOUND_TYPE_XM,               // * FastTracker 2 XM. */
    FMOD_SOUND_TYPE_XMA,              // * Xbox360 XMA */
    FMOD_SOUND_TYPE_AUDIOQUEUE,       // * iPhone hardware decoder, supports AAC, ALAC and MP3. */
    FMOD_SOUND_TYPE_AT9,              // * PS4 / PSVita ATRAC 9 format */
    FMOD_SOUND_TYPE_VORBIS,           // * Vorbis */
    FMOD_SOUND_TYPE_MEDIA_FOUNDATION, // * Windows Store Application built in system codecs */
    FMOD_SOUND_TYPE_MEDIACODEC,       // * Android MediaCodec */
    FMOD_SOUND_TYPE_FADPCM,           // * FMOD Adaptive Differential Pulse Code Modulation */

    FMOD_SOUND_TYPE_MAX// * Maximum number of sound types supported. */
    );

  (*
   FMOD Callbacks
  *)

  FMOD_DEBUG_CALLBACK = function(flags : FMOD_DEBUG_FLAGS; filename : PAnsiChar; line : Integer; func : PAnsiChar; message : PAnsiChar) : FMOD_RESULT; stdcall; // --- remarks renamed file -> filename

  FMOD_SYSTEM_CALLBACK = function(system : PFMOD_SYSTEM; callback_type : FMOD_SYSTEM_CALLBACK_TYPE; commanddata1 : Pointer; commanddata2 : Pointer; userdata : Pointer) : FMOD_RESULT; stdcall;

  FMOD_CHANNELCONTROL_CALLBACK = function(channelcontrol : PFMOD_CHANNELCONTROL; controltype : FMOD_CHANNELCONTROL_TYPE; callbacktype : FMOD_CHANNELCONTROL_CALLBACK_TYPE; commanddata1 : Pointer; commanddata2 : Pointer) : FMOD_RESULT; stdcall;

  FMOD_SOUND_NONBLOCK_CALLBACK = function(sound : PFMOD_SOUND; result : FMOD_RESULT) : FMOD_RESULT; stdcall;
  FMOD_SOUND_PCMREAD_CALLBACK = function(sound : PFMOD_SOUND; data : Pointer; datalen : UInt32) : FMOD_RESULT; stdcall;
  FMOD_SOUND_PCMSETPOS_CALLBACK = function(sound : PFMOD_SOUND; subsound : Integer; position : UInt32; postype : FMOD_TIMEUNIT) : FMOD_RESULT; stdcall;

  FMOD_FILE_OPEN_CALLBACK = function(name : PAnsiChar; var filesize : UInt32; var handle : Pointer; userdata : Pointer) : FMOD_RESULT; stdcall;
  FMOD_FILE_CLOSE_CALLBACK = function(handle : Pointer; userdata : Pointer) : FMOD_RESULT; stdcall;
  FMOD_FILE_READ_CALLBACK = function(handle : Pointer; buffer : Pointer; sizebytes : UInt32; var bytesread : UInt32; userdata : Pointer) : FMOD_RESULT; stdcall;
  FMOD_FILE_SEEK_CALLBACK = function(handle : Pointer; pos : UInt32; userdata : Pointer) : FMOD_RESULT; stdcall;
  FMOD_FILE_ASYNCREAD_CALLBACK = function(info : PFMOD_ASYNCREADINFO; userdata : Pointer) : FMOD_RESULT; stdcall;
  FMOD_FILE_ASYNCCANCEL_CALLBACK = function(info : PFMOD_ASYNCREADINFO; userdata : Pointer) : FMOD_RESULT; stdcall;

  FMOD_MEMORY_ALLOC_CALLBACK = function(size : UInt32; memory_type : FMOD_MEMORY_TYPE; sourcestr : PAnsiChar) : Pointer; stdcall;
  FMOD_MEMORY_REALLOC_CALLBACK = function(ptr : Pointer; size : UInt32; memory_type : FMOD_MEMORY_TYPE; sourcestr : PAnsiChar) : Pointer; stdcall;
  FMOD_MEMORY_FREE_CALLBACK = procedure(ptr : Pointer; memory_type : FMOD_MEMORY_TYPE; sourcestr : PAnsiChar); stdcall;

  FMOD_3D_ROLLOFF_CALLBACK = function(channelcontrol : PFMOD_CHANNELCONTROL; distance : single) : single; stdcall;

  (*
   [STRUCTURE]
   [
   [DESCRIPTION]
   Use this structure with System::createSound when more control is needed over loading.
   The possible reasons to use this with System::createSound are:

   - Loading a file from memory.
   - Loading a file from within another larger (possibly wad/pak) file, by giving the loader an offset and length.
   - To create a user created / non file based sound.
   - To specify a starting subsound to seek to within a multi-sample sounds (ie FSB/DLS) when created as a stream.
   - To specify which subsounds to load for multi-sample sounds (ie FSB/DLS) so that memory is saved and only a subset is actually loaded/read from disk.
   - To specify 'piggyback' read and seek callbacks for capture of sound data as fmod reads and decodes it.  Useful for ripping decoded PCM data from sounds as they are loaded / played.
   - To specify a MIDI DLS sample set file to load when opening a MIDI file.

   See below on what members to fill for each of the above types of sound you want to create.

   [REMARKS]
   This structure is optional!  Specify 0 or NULL in System::createSound if you don't need it!

   <u>Loading a file from memory.</u>

   - Create the sound using the FMOD_OPENMEMORY flag.
   - Mandatory.  Specify 'length' for the size of the memory block in bytes.
   - Other flags are optional.

   <u>Loading a file from within another larger (possibly wad/pak) file, by giving the loader an offset and length.</u>

   - Mandatory.  Specify 'fileoffset' and 'length'.
   - Other flags are optional.

   <u>To create a user created / non file based sound.</u>

   - Create the sound using the FMOD_OPENUSER flag.
   - Mandatory.  Specify 'defaultfrequency, 'numchannels' and 'format'.
   - Other flags are optional.

   <u>To specify a starting subsound to seek to and flush with, within a multi-sample stream (ie FSB/DLS).</u>

   - Mandatory.  Specify 'initialsubsound'.

   <u>To specify which subsounds to load for multi-sample sounds (ie FSB/DLS) so that memory is saved and only a subset is actually loaded/read from disk.</u>

   - Mandatory.  Specify 'inclusionlist' and 'inclusionlistnum'.

   <u>To specify 'piggyback' read and seek callbacks for capture of sound data as fmod reads and decodes it.  Useful for ripping decoded PCM data from sounds as they are loaded / played.</u>

   - Mandatory.  Specify 'pcmreadcallback' and 'pcmseekcallback'.

   <u>To specify a MIDI DLS sample set file to load when opening a MIDI file.</u>

   - Mandatory.  Specify 'dlsname'.

   Setting the 'decodebuffersize' is for cpu intensive codecs that may be causing stuttering, not file intensive codecs (ie those from CD or netstreams) which are normally
   altered with System::setStreamBufferSize.  As an example of cpu intensive codecs, an mp3 file will take more cpu to decode than a PCM wav file.

   If you have a stuttering effect, then it is using more cpu than the decode buffer playback rate can keep up with.  Increasing the decode buffersize will most likely solve this problem.

   FSB codec.  If inclusionlist and numsubsounds are used together, this will trigger a special mode where subsounds are shuffled down to save memory.  (useful for large FSB
   files where you only want to load 1 sound).  There will be no gaps, ie no null subsounds.  As an example, if there are 10,000 subsounds and there is an inclusionlist with only 1 entry,
   and numsubsounds = 1, then subsound 0 will be that entry, and there will only be the memory allocated for 1 subsound.  Previously there would still be 10,000 subsound pointers and other
   associated codec entries allocated along with it multiplied by 10,000.

   Members marked with [r] mean the variable is modified by FMOD and is for reading purposes only.  Do not change this value.<br>
   Members marked with [w] mean the variable can be written to.  The user can set the value.

   [SEE_ALSO]
   System::createSound
   System::setStreamBufferSize
   FMOD_MODE
   FMOD_SOUND_FORMAT
   FMOD_SOUND_TYPE
   FMOD_CHANNELMASK
   FMOD_CHANNELORDER
   FMOD_MAX_CHANNEL_WIDTH
   ]
  *)
  FMOD_CREATESOUNDEXINFO = record
    cbsize : Integer;           // * [w]   Size of this structure.  This is used so the structure can be expanded in the future and still work on older versions of FMOD Studio. */
    length : UInt32;            // * [w]   Optional. Specify 0 to ignore. Number of bytes to load starting at 'fileoffset', or size of sound to create (if FMOD_OPENUSER is used).  Required if loading from memory.  If 0 is specified, then it will use the size of the file (unless loading from memory then an error will be returned). */
    fileoffset : UInt32;        // * [w]   Optional. Specify 0 to ignore. Offset from start of the file to start loading from.  This is useful for loading files from inside big data files. */
    numchannels : Integer;      // * [w]   Optional. Specify 0 to ignore. Number of channels in a sound mandatory if FMOD_OPENUSER or FMOD_OPENRAW is used.  Can be specified up to FMOD_MAX_CHANNEL_WIDTH. */
    defaultfrequency : Integer; // * [w]   Optional. Specify 0 to ignore. Default frequency of sound in Hz, mandatory if FMOD_OPENUSER or FMOD_OPENRAW is used.  Other formats use the frequency determined by the file format. */
    format : FMOD_SOUND_FORMAT; // * [w]   Optional. Specify 0 or FMOD_SOUND_FORMAT_NONE to ignore. Format of the sound, mandatory if FMOD_OPENUSER or FMOD_OPENRAW is used.  Other formats use the format determined by the file format.   */
    decodebuffersize : UInt32;  // * [w]   Optional. Specify 0 to ignore. For streams.  This determines the size of the double buffer (in PCM samples) that a stream uses.  Use this for user created streams if you want to determine the size of the callback buffer passed to you.  Specify 0 to use FMOD's default size which is currently equivalent to 400ms of the sound format created/loaded. */
    initialsubsound : Integer;  // * [w]   Optional. Specify 0 to ignore. In a multi-sample file format such as .FSB/.DLS, specify the initial subsound to seek to, only if FMOD_CREATESTREAM is used. */
    numsubsounds : Integer;     // * [w]   Optional. Specify 0 to ignore or have no subsounds.  In a sound created with FMOD_OPENUSER, specify the number of subsounds that are accessable with Sound::getSubSound.
    // If not created with FMOD_OPENUSER, this will limit the number of subsounds loaded within a multi-subsound file.  If using FSB, then if FMOD_CREATESOUNDEXINFO::inclusionlist is used, this will shuffle subsounds down so that there are not any gaps.  It will mean that the indices of the sounds will be different. */
    inclusionlist : PInteger;                             // * [w]   Optional. Specify 0 to ignore. In a multi-sample format such as .FSB/.DLS it may be desirable to specify only a subset of sounds to be loaded out of the whole file.  This is an array of subsound indices to load into memory when created. */
    inclusionlistnum : Integer;                           // * [w]   Optional. Specify 0 to ignore. This is the number of integers contained within the inclusionlist array. */
    pcmreadcallback : FMOD_SOUND_PCMREAD_CALLBACK;        // * [w]   Optional. Specify 0 to ignore. Callback to 'piggyback' on FMOD's read functions and accept or even write PCM data while FMOD is opening the sound.  Used for user sounds created with FMOD_OPENUSER or for capturing decoded data as FMOD reads it. */
    pcmsetposcallback : FMOD_SOUND_PCMSETPOS_CALLBACK;    // * [w]   Optional. Specify 0 to ignore. Callback for when the user calls a seeking function such as Channel::setTime or Channel::setPosition within a multi-sample sound, and for when it is opened.*/
    nonblockcallback : FMOD_SOUND_NONBLOCK_CALLBACK;      // * [w]   Optional. Specify 0 to ignore. Callback for successful completion, or error while loading a sound that used the FMOD_NONBLOCKING flag.  Also called duing seeking, when setPosition is called or a stream is restarted. */
    dlsname : PAnsiChar;                                  // * [w]   Optional. Specify 0 to ignore. Filename for a DLS sample set when loading a MIDI file. If not specified, on Windows it will attempt to open /windows/system32/drivers/gm.dls or /windows/system32/drivers/etc/gm.dls, on Mac it will attempt to load /System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls, otherwise the MIDI will fail to open. Current DLS support is for level 1 of the specification. */
    encryptionkey : PAnsiChar;                            // * [w]   Optional. Specify 0 to ignore. Key for encrypted FSB file.  Without this key an encrypted FSB file will not load. */
    maxpolyphony : Integer;                               // * [w]   Optional. Specify 0 to ignore. For sequenced formats with dynamic channel allocation such as .MID and .IT, this specifies the maximum voice count allowed while playing.  .IT defaults to 64.  .MID defaults to 32. */
    userdata : Pointer;                                   // * [w]   Optional. Specify 0 to ignore. This is user data to be attached to the sound during creation.  Access via Sound::getUserData.  Note: This is not passed to FMOD_FILE_OPEN_CALLBACK - use fileuserdata for that. */
    suggestedsoundtype : FMOD_SOUND_TYPE;                 // * [w]   Optional. Specify 0 or FMOD_SOUND_TYPE_UNKNOWN to ignore.  Instead of scanning all codec types, use this to speed up loading by making it jump straight to this codec. */
    fileuseropen : FMOD_FILE_OPEN_CALLBACK;               // * [w]   Optional. Specify 0 to ignore. Callback for opening this file. */
    fileuserclose : FMOD_FILE_CLOSE_CALLBACK;             // * [w]   Optional. Specify 0 to ignore. Callback for closing this file. */
    fileuserread : FMOD_FILE_READ_CALLBACK;               // * [w]   Optional. Specify 0 to ignore. Callback for reading from this file. */
    fileuserseek : FMOD_FILE_SEEK_CALLBACK;               // * [w]   Optional. Specify 0 to ignore. Callback for seeking within this file. */
    fileuserasyncread : FMOD_FILE_ASYNCREAD_CALLBACK;     // * [w]   Optional. Specify 0 to ignore. Callback for seeking within this file. */
    fileuserasynccancel : FMOD_FILE_ASYNCCANCEL_CALLBACK; // * [w]   Optional. Specify 0 to ignore. Callback for seeking within this file. */
    fileuserdata : Pointer;                               // * [w]   Optional. Specify 0 to ignore. User data to be passed into the file callbacks. */
    filebuffersize : Integer;                             // * [w]   Optional. Specify 0 to ignore. Buffer size for reading the file, -1 to disable buffering, or 0 for system default. */
    channelorder : FMOD_CHANNELORDER;                     // * [w]   Optional. Specify 0 to ignore. Use this to differ the way fmod maps multichannel sounds to speakers.  See FMOD_CHANNELORDER for more. */
    channelmask : FMOD_CHANNELMASK;                       // * [w]   Optional. Specify 0 to ignore. Use this to specify which channels map to which speakers.  See FMOD_CHANNELMASK for more. */
    initialsoundgroup : PFMOD_SOUNDGROUP;                 // * [w]   Optional. Specify 0 to ignore. Specify a sound group if required, to put sound in as it is created. */
    initialseekposition : UInt32;                         // * [w]   Optional. Specify 0 to ignore. For streams. Specify an initial position to seek the stream to. */
    initialseekpostype : FMOD_TIMEUNIT;                   // * [w]   Optional. Specify 0 to ignore. For streams. Specify the time unit for the position set in initialseekposition. */
    ignoresetfilesystem : Integer;                        // * [w]   Optional. Specify 0 to ignore. Set to 1 to use fmod's built in file system. Ignores setFileSystem callbacks and also FMOD_CREATESOUNEXINFO file callbacks.  Useful for specific cases where you don't want to use your own file system but want to use fmod's file system (ie net streaming). */
    audioqueuepolicy : UInt32;                            // * [w]   Optional. Specify 0 or FMOD_AUDIOQUEUE_CODECPOLICY_DEFAULT to ignore. Policy used to determine whether hardware or software is used for decoding, see FMOD_AUDIOQUEUE_CODECPOLICY for options (iOS >= 3.0 required, otherwise only hardware is available) */
    minmidigranularity : UInt32;                          // * [w]   Optional. Specify 0 to ignore. Allows you to set a minimum desired MIDI mixer granularity. Values smaller than 512 give greater than default accuracy at the cost of more CPU and vice versa. Specify 0 for default (512 samples). */
    nonblockthreadid : Integer;                           // * [w]   Optional. Specify 0 to ignore. Specifies a thread index to execute non blocking load on.  Allows for up to 5 threads to be used for loading at once.  This is to avoid one load blocking another.  Maximum value = 4. */
    fsbguid : PFMOD_GUID;                                 // * [r/w] Optional. Specify 0 to ignore. Allows you to provide the GUID lookup for cached FSB header info. Once loaded the GUID will be written back to the pointer. This is to avoid seeking and reading the FSB header. */
  end;

  (*
   [ENUM]
   [
   [DESCRIPTION]
   These output types are used with System::setOutput / System::getOutput, to choose which output method to use.

   [REMARKS]
   To pass information to the driver when initializing fmod use the *extradriverdata* parameter in System::init for the following reasons.

   - FMOD_OUTPUTTYPE_WAVWRITER     - extradriverdata is a pointer to a char * file name that the wav writer will output to.
   - FMOD_OUTPUTTYPE_WAVWRITER_NRT - extradriverdata is a pointer to a char * file name that the wav writer will output to.
   - FMOD_OUTPUTTYPE_DSOUND        - extradriverdata is cast to a HWND type, so that FMOD can set the focus on the audio for a particular window.
   - FMOD_OUTPUTTYPE_PS3           - extradriverdata is a pointer to a FMOD_PS3_EXTRADRIVERDATA struct. This can be found in fmodps3.h.
   - FMOD_OUTPUTTYPE_XAUDIO        - (Xbox360) extradriverdata is a pointer to a FMOD_360_EXTRADRIVERDATA struct. This can be found in fmodxbox360.h.

   Currently these are the only FMOD drivers that take extra information.  Other unknown plugins may have different requirements.

   Note! If FMOD_OUTPUTTYPE_WAVWRITER_NRT or FMOD_OUTPUTTYPE_NOSOUND_NRT are used, and if the System::update function is being called
   very quickly (ie for a non realtime decode) it may be being called too quickly for the FMOD streamer thread to respond to.
   The result will be a skipping/stuttering output in the captured audio.

   To remedy this, disable the FMOD streamer thread, and use FMOD_INIT_STREAM_FROM_UPDATE to avoid skipping in the output stream,
   as it will lock the mixer and the streamer together in the same thread.

   [SEE_ALSO]
   System::setOutput
   System::getOutput
   System::init
   System::update
   ]
  *)
  FMOD_OUTPUTTYPE = (
    FMOD_OUTPUTTYPE_AUTODETECT, // * Picks the best output mode for the platform. This is the default. *//

    FMOD_OUTPUTTYPE_UNKNOWN,       // * All - 3rd party plugin, unknown. This is for use with System::getOutput only. *//
    FMOD_OUTPUTTYPE_NOSOUND,       // * All - Perform all mixing but discard the final output. *//
    FMOD_OUTPUTTYPE_WAVWRITER,     // * All - Writes output to a .wav file. *//
    FMOD_OUTPUTTYPE_NOSOUND_NRT,   // * All - Non-realtime version of FMOD_OUTPUTTYPE_NOSOUND. User can drive mixer with System::update at whatever rate they want. *//
    FMOD_OUTPUTTYPE_WAVWRITER_NRT, // * All - Non-realtime version of FMOD_OUTPUTTYPE_WAVWRITER. User can drive mixer with System::update at whatever rate they want. *//

    FMOD_OUTPUTTYPE_DSOUND,     // * Win                  - Direct Sound.                        (Default on Windows XP and below) *//
    FMOD_OUTPUTTYPE_WINMM,      // * Win                  - Windows Multimedia. *//
    FMOD_OUTPUTTYPE_WASAPI,     // * Win//WinStore//XboxOne - Windows Audio Session API.           (Default on Windows Vista and above, Xbox One and Windows Store Applications) *//
    FMOD_OUTPUTTYPE_ASIO,       // * Win                  - Low latency ASIO 2.0. *//
    FMOD_OUTPUTTYPE_PULSEAUDIO, // * Linux                - Pulse Audio.                         (Default on Linux if available) *//
    FMOD_OUTPUTTYPE_ALSA,       // * Linux                - Advanced Linux Sound Architecture.   (Default on Linux if PulseAudio isn't available) *//
    FMOD_OUTPUTTYPE_COREAUDIO,  // * Mac//iOS              - Core Audio.                          (Default on Mac and iOS) *//
    FMOD_OUTPUTTYPE_XAUDIO,     // * Xbox 360             - XAudio.                              (Default on Xbox 360) *//
    FMOD_OUTPUTTYPE_PS3,        // * PS3                  - Audio Out.                           (Default on PS3) *//
    FMOD_OUTPUTTYPE_AUDIOTRACK, // * Android              - Java Audio Track.                    (Default on Android 2.2 and below) *//
    FMOD_OUTPUTTYPE_OPENSL,     // * Android              - OpenSL ES.                           (Default on Android 2.3 and above) *//
    FMOD_OUTPUTTYPE_WIIU,       // * Wii U                - AX.                                  (Default on Wii U) *//
    FMOD_OUTPUTTYPE_AUDIOOUT,   // * PS4//PSVita           - Audio Out.                           (Default on PS4 and PS Vita) *//
    FMOD_OUTPUTTYPE_AUDIO3D,    // * PS4                  - Audio3D. *//
    FMOD_OUTPUTTYPE_ATMOS,      // * Win                  - Dolby Atmos (WASAPI). *//
    FMOD_OUTPUTTYPE_WEBAUDIO,   // * Web Browser          - JavaScript webaudio output.          (Default on JavaScript) *//
    FMOD_OUTPUTTYPE_NNAUDIO,    // * NX                   - NX nn::audio.                        (Default on NX) *//
    FMOD_OUTPUTTYPE_WINSONIC,   // * Win10 // XboxOne      - Windows Sonic. *//

    FMOD_OUTPUTTYPE_MAX // * Maximum number of output types supported. */
    );

  {$MINENUMSIZE 1}

implementation

end.
