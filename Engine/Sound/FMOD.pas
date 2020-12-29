unit FMOD;

(*
 Translated by Martin Lange 04.2018

 original:

 fmod.h - FMOD Studio Low Level API
 Copyright (c), Firelight Technologies Pty, Ltd. 2017.

 This header defines the C API. If you are programming in C++ use fmod_studio.hpp.
*)

interface

uses
  System.SysUtils,
  Winapi.Windows,
  FMOD.Common;

const
  // Enables logging for fmod if FMOD_LOGGING is defined, use only for debugging!
  {$IFDEF FMOD_LOGGING}
  FMOD32_LIBFILENAME = 'fmodL.dll';
  {$ELSE}
  FMOD32_LIBFILENAME = 'fmod.dll';
  {$ENDIF}


type

  (*
   Setup functions.
  *)

  TFMOD_System_SetOutput = function(System : PFMOD_SYSTEM; output : FMOD_OUTPUTTYPE) : FMOD_RESULT; stdcall;

var
  FMOD_System_SetOutput : TFMOD_System_SetOutput;

procedure InitFMODAPI(LibaryFileName : string = FMOD32_LIBFILENAME);
procedure ReleaseFMODAPI;

implementation

var
  FmodLibHandle : HMODULE = 0;

procedure ReadFMODSystem;
begin
  FMOD_System_SetOutput := GetProcAddress(FmodLibHandle, 'FMOD_System_SetOutput');
end;

procedure readProcedureAdresses; {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  ReadFMODSystem;
end;

procedure InitFMODAPI(LibaryFileName : string);
begin
  // no need to double load libary
  if FmodLibHandle = 0 then
  begin
    FmodLibHandle := LoadLibrary(PChar(ExpandFileName(LibaryFileName)));
    if FmodLibHandle <> 0 then
    begin
      readProcedureAdresses;
    end
    // handle = 0, an error occured
    else
        raise EFileNotFoundException.CreateFmt('InitFmodStudioAPI: Couldn''t load fmod libary from file "%s".', [ExpandFileName(LibaryFileName)]);
  end;
end;

procedure ReleaseFMODAPI;
begin
  if FmodLibHandle <> 0 then FreeLibrary(FmodLibHandle);
end;

end.
