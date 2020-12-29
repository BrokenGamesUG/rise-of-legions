unit BaseConflict.Types.Client;

interface

uses
  BaseConflict.Constants;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  EnumGameStatus = (gsPreparing, gsRunning, gsReconnecting, gsAborted, gsCrashed, gsFinishing, gsFinished);

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation


end.
