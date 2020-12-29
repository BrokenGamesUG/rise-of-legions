unit Engine.Script;

interface

uses
  // Delphi
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  Vcl.Dialogs,
  Vcl.Forms,
  Winapi.Windows,
  // 3rd Party
  dwsComp,
  dwsRTTIExposer,
  dwsExprs,
  dwsSymbols,
  dwsStack,
  dwsFunctions,
  dwsInfoClasses,
  dwsUnitSymbols,
  dwsDataContext,
  dwsInfo,
  dwsErrors,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.Threads,
  Engine.Math,
  Engine.Log;

const
  SCRIPTUNITEXTENSION = '.dws';

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  /// <summary> Marks a member (property, field, method) to be excluded from publishing in script.</summary>
  ScriptExcludeMember = dwsNotPublished;

  /// <summary> Marks a member (property, field, method) to be included at publishing in script.</summary>
  ScriptIncludeMember = dwsPublished;

  /// <summary> Marks all members (property, field, method) of a class to be excluded from publishing in script.</summary>
  ScriptExcludeAll = dwsPublishNothing;

  TFuncInfoHelper = class helper for TInfoFunc
    function GetParameterIdentifiers : TStrings;
  end;

  TProgramInfoExtender = class helper for TProgramInfo
    function GetFunctions : TList<string>;
    function GetGlobalVariables : TStrings;
  end;

  EScriptCompileException = class(Exception);

  EScriptExecuteException = class(Exception);
  EScriptExposeException = class(Exception);

  RScriptReturnValue = record
    private
      FResultValue : Variant;
      FExternalObject : TObject;
      FIsEmpty : boolean;
    public
      constructor Create(ResultValue : Variant; ExternalObject : TObject);
      class function GetEmpty : RScriptReturnValue; static;
      // function AsInteger : Integer;
      // function AsTValue : TValue;
  end;

  TNewScriptCodeMethod = procedure of object;

  TScriptmanager = class;

  TScript = class
    private type
      TScriptInfo = class
        private type
          TFunctionInfo = class
            Name : string;
            ParameterCount : integer;
            constructor Create(Name : string; ParameterCount : integer);
          end;
        private
          FTargetScript : TScript;
          FFunctions : TObjectDictionary<string, TFunctionInfo>;
          FGlobalVariables : TStrings;
          constructor Create(TargetScript : TScript);
        public
          property Functions : TObjectDictionary<string, TFunctionInfo> read FFunctions;
          property GlobalVariables : TStrings read FGlobalVariables;
          destructor Destroy; override;
      end;
    private
      FExecutionContext : IdwsProgramExecution;
      FProgramm : IdwsProgram;
      FRttiContext : TRttiContext;
      FScriptSideObjects : TDictionary<TObject, IScriptObj>;
      FInfo : TScriptInfo;
      FOnNewScriptCode : TNewScriptCodeMethod;
      FScriptFileName : string;
      FParentScriptManager : TScriptmanager;
      constructor Create(Script : IdwsProgram; ParentScriptManager : TScriptmanager; ScriptFileName : string);
      procedure ApplyNewScript(NewScript : IdwsProgram);
    public
      /// <summary> Assigned method will called, after newscriptcode assigned to this code by ScriptManager.
      /// Useful to load new info data...</summary>
      // property OnNewScriptCode : TNewScriptCodeMethod read FOnNewScriptCode write FOnNewScriptCode;
      /// <summary> Publish some infos for </summary>
      property Info : TScriptInfo read FInfo;
      (* /// <summary> Execute a script procedure</summary>
       /// <param name="Name"> Name of procedure which should execute</param>
       // procedure ExecuteProcedure(Name : string); overload;
       /// <summary> Execute a script procedure</summary>
       /// <param name="Name"> Name of procedure which should execute</param>
       /// <param name="Parameter"> A arbitary sized array of Variant. If ParameterCount doens't match ProcedureParamCount, raise Exception</param>
       // procedure ExecuteProcedure(Name : string; Parameter : array of TValue);
       { /// <summary> Execute a script function</summary>
       /// <param name="Name"> Name of procedure which should execute</param>
       /// <returns> ReturnValue of genrictype T of script function</returns>
       /// <param name="Parameter"> A arbitary sized array of Variant. If ParameterCount doens't match ProcedureParamCount, raise Exception</param>
       function ExecuteFunction<T>(Name : string) : T; overload; *)
      /// <summary> Execute a script procedure</summary>
      /// <param name="Name"> Name of procedure which should execute</param>
      /// /// <returns> ReturnValue of genrictype T of script function</returns> }
      function ExecuteFunction(Name : string; Parameter : array of TValue; ResultTypeInfo : Pointer) : TValue; overload;
      /// <summary> Need the script to be run before. So call RunMain before using this. </summary>
      function GetGlobalVariableValue<T>(Name : string) : T;
      /// <summary> Need the script to be run before. So call RunMain before using this. </summary>
      function TryGetGlobalVariableValue<T>(Name : string; out Value : T) : boolean;
      procedure SetGlobalVariableValue<T>(Name : string; Value : T);
      /// <summary> Set "Value" to global script variable if exist and returns value could set.
      /// If variable not exist in script, no error or exception will trigger. </summary>
      /// <returns> True if variable with "name" found and value set correct. </returns>
      function SetGlobalVariableValueIfExist<T>(Name : string; Value : T) : boolean;
      /// <summary> Run the mainpart from script</summary>
      procedure RunMain;
      /// <summary> Release all allocated resources</summary>
      destructor Destroy; override;
  end;

  /// <summary> Compile scripts and provide methods to publish classes, variables etc in script.
  /// For scriptlanguage documentation <see cref="http://code.google.com/p/dwscript/wiki/Language"/></summary>
  TScriptmanager = class
    private type
      TFunctionMethodInvoker = class
        private
          FInvokeRttiType : TRttiInvokableType;
          FProcOrMeth : TValue;
          FTypParams : array of TRTTIType;
          FNameParams : array of string;
          FVarParams : array of integer;
          FTypResult : TRTTIType;
        public
          constructor Create(RttiType : TRttiInvokableType; CodeAdress : TValue);
          procedure Invoke(Info : TProgramInfo);
          destructor Destroy; override;
      end;

    private
      FCompiler : TDelphiWebScript;
      FCompilerExtender : TdwsUnit;
      FRttiContext : TRttiContext;
      // cache for compile scripts, filename => compile script
      FCompiledScripts : TThreadSafeObjectDictionary<string, IdwsProgram>;
      // saves for every file the published TScripts
      FPublishedScripts : TThreadSafeObjectDictionary<string, TList<TScript>>;
      FFunctionMethodInvoker : TObjectList<TFunctionMethodInvoker>;
      // dependancy unit/inlcude => script files
      FScriptDependancies : TObjectDictionary<string, TList<string>>;
      FUnitSearchPath : string;
      FDefines : TStrings;
      // if true, any unit/include loaded through NeedUnit will be recorded on FDependancyList
      FRecordDependancies : boolean;
      // list containing dependancies for current dependancy record, will not used for any other purpose
      FDependancyList : TList<string>;
      function NeedUnit(const unitName : string; var unitSource : string) : IdwsUnit;
      procedure NeedSourceForInclude(const scriptName : string; var scriptSource : string);
      function CompileScriptInternal(ScriptCode : string; ErrorOutput : TStrings) : IdwsProgram;
      procedure ExposeFunctionOrMethod(Name : string; Adress : TValue; RttiInfo : Pointer);
      procedure RemovePublishedScript(ScriptToRemove : TScript);
      procedure OnScriptChanged(const Filepath, Filecontent : string);
      procedure OnUnitChanged(const Filepath, Filecontent : string);
      procedure StartRecordDependancies;
      procedure StopRecordDependancies;
    public
      const
      SCRIPT_SELF_PATH_TAG = 'SCRIPTFILE_FILEPATH';
      SCRIPT_SELF_NAME_TAG = 'SCRIPTFILE_NAME';
    var
      property CustomExpose : TdwsUnit read FCompilerExtender;
      /// <summary> List of defines, will add to every script compiled independent from which source (string, file)
      /// HINT: add them as plane string without {$ }</summary>
      property Defines : TStrings read FDefines;
      /// <summary> Path to unitdir. If defined uses every file will try to load from dir.</summary>
      property UnitSearchPath : string read FUnitSearchPath write FUnitSearchPath;
      /// <summary> Default constructor, nothing special</summary>
      constructor Create;
      /// <summary> Compile a script. If script need a exposed class or GlobalVariable - expose them first.
      /// HINT: For plain scriptcode NO caching is used, scriptfile will only compiled.</summary>
      /// <param name="Script"> Script as String</param>
      /// <param name="ErrorOutput"> Contains compileerrors, if some occurs. Can be nil, then errors will cause a exception.</param>
      function CompileScript(ScriptCode : string; ErrorOutput : TStrings = nil) : TScript;
      /// <summary> Compile a script from file. If script need a exposed class or GlobalVariable - expose them first.
      /// All scripfiles are cached.</summary>
      /// <param name="Scriptfile"> Scriptfile in textformat to load script from.</param>
      function CompileScriptFromFile(FileName : string; ErrorOutput : TStrings = nil) : TScript;
      /// <summary> ReCompile script and notify all published script to reload new script.</summary>
      procedure RecompileScript(PreviousScriptFile : string; NewScript : string; ErrorOutput : TStrings);
      /// <summary> Clears the complete ScriptManager cache.</summary>
      procedure ClearCache;
      /// <summary> Expose a class (using Rtti) in every script will be compiled. This class and all methods can used in script</summary>
      /// <param name="AClass"> Class to published</param>
      procedure ExposeClass(AClass : TClass);
      procedure ExposeType(AType : Pointer);
      procedure ExposeFunction(Name : string; CodeAdress : Pointer; FunctionInfo : Pointer);
      procedure ExposeMethod(Name : string; Instance : TObject; MethodInfo : Pointer);
      procedure ExposeConstant(Name : string; Value : TValue);
      /// <summary> Publish a variable in every script compiled. This variable can accessed in script. Variable has generictype T.
      /// PublishedVariable is empty. Accessing a empty variable in script will cause a AccessViolation.</summary>
      /// <param name="Name"> </param>
      // procedure PublishVariable<T>(Name : String);
      /// <summary> Release all allocated resources</summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  ScriptManager : TScriptmanager;

implementation


{ TScript }

procedure TScript.ApplyNewScript(NewScript : IdwsProgram);
var
  VariableName : string;
  Variables : TDictionary<string, TData>;
begin
  Variables := TDictionary<string, TData>.Create;
  // save current var values
  for VariableName in FInfo.FGlobalVariables do
  begin
    Variables.Add(VariableName.ToLowerInvariant, FExecutionContext.Info.Vars[VariableName].Data);
  end;
  // kill old script and load new
  FExecutionContext.EndProgram;
  FExecutionContext := nil;
  FProgramm := NewScript;
  FExecutionContext := FProgramm.BeginNewExecution;
  FInfo.Free;
  FInfo := TScriptInfo.Create(self);
  // load old var value in to new script
  for VariableName in FInfo.FGlobalVariables do
  begin
    // check if variable available, because variables could change
    if Variables.ContainsKey(VariableName.ToLowerInvariant) then
    begin
      FExecutionContext.Info.Vars[VariableName].Data := Variables[VariableName.ToLowerInvariant];
    end;
  end;
  Variables.Free;
  if Assigned(FOnNewScriptCode) then FOnNewScriptCode();
end;

constructor TScript.Create(Script : IdwsProgram; ParentScriptManager : TScriptmanager; ScriptFileName : string);
begin
  FParentScriptManager := ParentScriptManager;
  FScriptFileName := ScriptFileName;
  FRttiContext := TRttiContext.Create;
  FScriptSideObjects := TDictionary<TObject, IScriptObj>.Create();
  FProgramm := Script;
  FExecutionContext := FProgramm.BeginNewExecution;
  FInfo := TScriptInfo.Create(self);
  // FProgramm.Execute();
  // FExecutionContext2 := FProgramm.BeginNewExecution;
end;

destructor TScript.Destroy;
begin
  if Assigned(FParentScriptManager) then FParentScriptManager.RemovePublishedScript(self);
  FInfo.Free;
  FScriptSideObjects.Free;
  FRttiContext.Free;
  FExecutionContext.EndProgram;
  FExecutionContext := nil;
  FProgramm := nil;
  inherited;
end;

function TScript.ExecuteFunction(Name : string; Parameter : array of TValue; ResultTypeInfo : Pointer) : TValue;
var
  FuncInfo, localResult : IInfo;
  ParameterIdentifiers : TStrings;
  i : integer;
  tmpResult : TValue;
  RttiType : TRTTIType;
begin
  FuncInfo := FExecutionContext.Info.Func[name];
  // FProgramm.ProgramObject.Attributes.AttributesFor(nil)[0].Symbol.Description
  ParameterIdentifiers := TInfoFunc(FuncInfo).GetParameterIdentifiers;
  if (length(Parameter) <> ParameterIdentifiers.Count) then
      raise EScriptExecuteException.Create('TScript.ExecuteFunction: Parametercount doesn''t match.');
  for i := 0 to ParameterIdentifiers.Count - 1 do
  begin
    TdwsRTTIInvoker.AssignIInfoFromValue(FuncInfo.Parameter[ParameterIdentifiers[i]], Parameter[i], FRttiContext.GetType(Parameter[i].TypeInfo), FExecutionContext.Info);
  end;
  localResult := FuncInfo.Call;
  if Assigned(localResult) and Assigned(ResultTypeInfo) then
  begin
    RttiType := FRttiContext.GetType(ResultTypeInfo);
    if RttiType.TypeKind = tkClass then
    begin
      assert(Assigned(localResult.ScriptObj));
      Result := localResult.ExternalObject;
    end
    else
    begin
      tmpResult := TdwsRTTIInvoker.ValueFromIInfo(RttiType, localResult);
      Result := tmpResult;
    end;
  end;
  ParameterIdentifiers.Free;
end;

function TScript.GetGlobalVariableValue<T>(Name : string) : T;
var
  tmpResult : TValue;
  Context : TRttiContext;
  RttiType : TRTTIType;
  VarValue : IInfo;
begin
  Context := TRttiContext.Create;
  RttiType := Context.GetType(TypeInfo(T));
  VarValue := FExecutionContext.Info.Vars[name];
  tmpResult := TdwsRTTIInvoker.ValueFromIInfo(RttiType, VarValue);
  Result := tmpResult.AsType<T>;
  Context.Free;
  VarValue := nil;
end;

procedure TScript.RunMain;
begin
  FExecutionContext.RunProgram(0);
end;

procedure TScript.SetGlobalVariableValue<T>(Name : string; Value : T);
var
  tmpValue : TValue;
  Context : TRttiContext;
  RttiType : TRTTIType;
begin
  assert(FInfo.GlobalVariables.IndexOf(name) >= 0);
  Context := TRttiContext.Create;
  RttiType := Context.GetType(TypeInfo(T));
  tmpValue := TValue.From<T>(Value);
  TdwsRTTIInvoker.AssignIInfoFromValue(FExecutionContext.Info.Vars[name], tmpValue, RttiType, FExecutionContext.Info);
  Context.Free;
end;

function TScript.SetGlobalVariableValueIfExist<T>(Name : string; Value : T) : boolean;
begin
  Result := FInfo.GlobalVariables.IndexOf(name) >= 0;
  if Result then
      SetGlobalVariableValue<T>(name, Value);
end;

function TScript.TryGetGlobalVariableValue<T>(Name : string; out Value : T) : boolean;
begin
  Result := FInfo.GlobalVariables.IndexOf(name) >= 0;
  if Result then Value := GetGlobalVariableValue<T>(name);
end;

{ TScriptmanager }

function TScriptmanager.CompileScriptFromFile(FileName : string; ErrorOutput : TStrings) : TScript;
var
  lowerFileName, ScriptContent : string;
  CompiledScript : IdwsProgram;
  CustomErrorOutput : boolean;
  AList : TList<string>;
  LowerUnitFileName : string;
  PublishedScripts : TObjectDictionary<string, TList<TScript>>;
  CompiledScripts : TObjectDictionary<string, IdwsProgram>;
begin
  Result := nil;
  if FileExists(FileName) then
  begin
    lowerFileName := FileName.ToLowerInvariant;
    // if scriptfile is not cached, compile it
    if FCompiledScripts.TryGetValue(lowerFileName, CompiledScript) then
        Result := TScript.Create(CompiledScript, self, lowerFileName)
    else
    begin
      CompiledScripts := FCompiledScripts.ExclusiveLock;
      // test a second time, as two threads could reach ExclusiveLock at the same time
      if FCompiledScripts.TryGetValue(lowerFileName, CompiledScript) then
          Result := TScript.Create(CompiledScript, self, lowerFileName)
      else
      begin
        try
          ContentManager.SubscribeToFile(FileName, OnScriptChanged, ScriptContent, True);
          if not Assigned(ErrorOutput) then
          begin
            ErrorOutput := TStringList.Create;
            CustomErrorOutput := True;
          end
          else CustomErrorOutput := False;
          ScriptContent := ScriptContent.Replace(SCRIPT_SELF_PATH_TAG, '''' + FileName + '''');
          ScriptContent := ScriptContent.Replace(SCRIPT_SELF_NAME_TAG, '''' + ExtractFileName(FileName) + '''');
          StartRecordDependancies;
          CompiledScript := CompileScriptInternal(ScriptContent, ErrorOutput);
          StopRecordDependancies;

          // build entries dependancies to hot reload script also if any include/unit changed
          for LowerUnitFileName in FDependancyList do
          begin
            if not FScriptDependancies.TryGetValue(LowerUnitFileName, AList) then
            begin
              AList := TList<string>.Create;
              FScriptDependancies.Add(LowerUnitFileName, AList);
              ContentManager.SubscribeToFile(LowerUnitFileName, OnUnitChanged, True);
            end;
            // through CompiledScripts caching, this codeblock should never executed for same file more than once
            assert(not AList.Contains(lowerFileName));
            AList.Add(lowerFileName);
          end;

          if Assigned(CompiledScript) then
          begin
            Result := TScript.Create(CompiledScript, self, lowerFileName);
            // add new script to scriptcache
            CompiledScripts.Add(lowerFileName, Result.FProgramm);
          end;
          // use catched errors to add filename to erroroutput
          if CustomErrorOutput then
          begin
            if (ErrorOutput.Count > 0) then raise EScriptCompileException.Create(Format('Error while compiling scriptfile (%s): %s', [FileName, ErrorOutput.Text]));
            ErrorOutput.Free;
          end;
        finally
          FCompiledScripts.ExclusiveUnlock;
        end;
      end;
    end;
    PublishedScripts := FPublishedScripts.ExclusiveLock;
    try
      // add result to list - required for recompile script
      if not PublishedScripts.ContainsKey(lowerFileName) then
          PublishedScripts.Add(lowerFileName, TList<TScript>.Create);
      PublishedScripts[lowerFileName].Add(Result);
    finally
      FPublishedScripts.ExclusiveUnlock;
    end;
  end
  else HLog.Write(elError, 'TScriptmanager.CompileScriptFromFile: Can''t find scriptfile "%s".', [FileName], EFileNotFoundException);
end;

function TScriptmanager.CompileScriptInternal(ScriptCode : string; ErrorOutput : TStrings) : IdwsProgram;
var
  i : integer;
begin
  for i := 0 to FDefines.Count - 1 do ScriptCode := '{$DEFINE ' + FDefines[i] + '}' + sLineBreak + ScriptCode;
  // custom preprocessor steps
  // resolve #define
  ScriptCode := HPreProcessor.ResolveDefines(ScriptCode);
  // final compilation of script
  Result := FCompiler.Compile(ScriptCode);
  if Result.Msgs.Count > 0 then
  begin
    if Assigned(ErrorOutput) then
    begin
      for i := 0 to Result.Msgs.Count - 1 do
          ErrorOutput.Add(Result.Msgs[i].AsInfo)
    end
    else
    begin
      HLog.Log(Result.Msgs.AsInfo + sLineBreak + ScriptCode);
      raise EScriptCompileException.Create(Result.Msgs.AsInfo);
    end;
    Result := nil;
  end;
end;

constructor TScriptmanager.Create;
begin
  FRttiContext := TRttiContext.Create;
  FPublishedScripts := TThreadSafeObjectDictionary < string, TList < TScript >>.Create([doOwnsValues]);
  FCompiledScripts := TThreadSafeObjectDictionary<string, IdwsProgram>.Create([]);
  FFunctionMethodInvoker := TObjectList<TFunctionMethodInvoker>.Create;
  FDefines := TStringList.Create;
  FDependancyList := TList<string>.Create;
  FScriptDependancies := TObjectDictionary < string, TList < string >>.Create([doOwnsValues]);
  FRecordDependancies := False;
  FCompiler := TDelphiWebScript.Create(nil);
  FCompilerExtender := TdwsUnit.Create(nil);
  FCompilerExtender.unitName := 'CompilerExtender';
  FCompilerExtender.Script := FCompiler;
  FCompiler.OnNeedUnit := NeedUnit;
  FCompiler.OnInclude := NeedSourceForInclude;
end;

destructor TScriptmanager.Destroy;
begin
  FPublishedScripts.Free;
  FCompiledScripts.Free;
  FDefines.Free;
  FDependancyList.Free;
  FScriptDependancies.Free;
  // important FCompiler must be free before Extender!!! Otherwise problems
  FCompiler.Free;
  FCompilerExtender.Free;
  FRttiContext.Free;
  FFunctionMethodInvoker.Free;
  inherited;
end;

procedure TScriptmanager.NeedSourceForInclude(const scriptName : string; var scriptSource : string);
begin
  NeedUnit(scriptName, scriptSource);
  scriptSource := HPreProcessor.ResolveDefines(scriptSource);
end;

function TScriptmanager.NeedUnit(const unitName : string; var unitSource : string) : IdwsUnit;
var
  UnitFileName : string;
begin
  Result := nil;
  if FUnitSearchPath = '' then raise EScriptCompileException.Create('TScriptmanager.NeedUnit: No UnitSearchPath set.');
  UnitFileName := FormatDateiPfad(IncludeTrailingPathDelimiter(UnitSearchPath) + unitName);
  if not FileExists(UnitFileName) then raise EScriptCompileException.Create('TScriptmanager.NeedUnit: Unit "' + UnitFileName + '" not found.')
  else unitSource := ReadFileInString(UnitFileName);
  if FRecordDependancies then
      FDependancyList.Add(UnitFileName.ToLowerInvariant);
end;

procedure TScriptmanager.OnScriptChanged(const Filepath, Filecontent : string);
var
  lowerFileName : string;
  Errors : TStringList;
  finalFileContent : string;
begin
  lowerFileName := Filepath.ToLowerInvariant;
  Errors := TStringList.Create;
  finalFileContent := Filecontent.Replace(SCRIPT_SELF_PATH_TAG, '''' + Filepath + '''');
  finalFileContent := finalFileContent.Replace(SCRIPT_SELF_NAME_TAG, '''' + ExtractFileName(Filepath) + '''');
  RecompileScript(lowerFileName, finalFileContent, Errors);
  if Errors.Count > 0 then
  begin
    {$IFDEF DEBUG}
    AllocConsole();
    writeln(Errors.Text);
    {$ENDIF}
  end;
  Errors.Free;
end;

procedure TScriptmanager.OnUnitChanged(const Filepath, Filecontent : string);
var
  ScriptFile : string;
begin
  for ScriptFile in FScriptDependancies[Filepath.ToLowerInvariant] do
  begin
    OnScriptChanged(ScriptFile, ContentManager.FileToString(ScriptFile));
  end;
end;

procedure TScriptmanager.RecompileScript(PreviousScriptFile, NewScript : string; ErrorOutput : TStrings);
var
  lowerFileName : string;
  CompiledScript : IdwsProgram;
  AScript : TScript;
  PublishedScripts : TObjectDictionary<string, TList<TScript>>;
begin
  lowerFileName := PreviousScriptFile.ToLowerInvariant;
  // removed because it should be possible to test a new script without usage in code
  // if not(FCompiledScripts.ContainsKey(lowerFileName) and FPublishedScripts.ContainsKey(lowerFileName)) then
  // raise EScriptCompileException.Create('TScriptmanager.RecompileScript: Can''t recompile script, "' + PreviousScriptFile + '" not published to any script yet.');
  CompiledScript := CompileScriptInternal(NewScript, ErrorOutput);
  if (FCompiledScripts.ContainsKey(lowerFileName) and FPublishedScripts.ContainsKey(lowerFileName)) then
  begin
    if Assigned(CompiledScript) then
    begin
      FCompiledScripts.ExclusiveLock;
      begin
        FCompiledScripts[lowerFileName] := nil;
        FCompiledScripts[lowerFileName] := CompiledScript;
      end;
      FCompiledScripts.ExclusiveUnlock;
      PublishedScripts := FPublishedScripts.ExclusiveLock;
      begin
        for AScript in PublishedScripts[lowerFileName] do
        begin
          AScript.ApplyNewScript(CompiledScript);
        end;
      end;
      FPublishedScripts.ExclusiveUnlock;
    end;
  end;
end;

procedure TScriptmanager.RemovePublishedScript(ScriptToRemove : TScript);
var
  index : integer;
  Scripts : TList<TScript>;
  PublishedScripts : TObjectDictionary<string, TList<TScript>>;
begin
  PublishedScripts := FPublishedScripts.ExclusiveLock;
  begin
    assert(PublishedScripts.ContainsKey(ScriptToRemove.FScriptFileName));
    Scripts := PublishedScripts[ScriptToRemove.FScriptFileName];
    index := Scripts.IndexOf(ScriptToRemove);
    assert(index >= 0);
    Scripts.Delete(index);
  end;
  FPublishedScripts.ExclusiveUnlock;
end;

procedure TScriptmanager.StartRecordDependancies;
begin
  FDependancyList.Clear;
  FRecordDependancies := True;
end;

procedure TScriptmanager.ClearCache;
begin
  FPublishedScripts.Clear;
  FCompiledScripts.Clear;
  FScriptDependancies.Clear;
end;

function TScriptmanager.CompileScript(ScriptCode : string; ErrorOutput : TStrings = nil) : TScript;
begin
  Result := TScript.Create(CompileScriptInternal(ScriptCode, ErrorOutput), nil, '');
end;

procedure TScriptmanager.StopRecordDependancies;
begin
  FRecordDependancies := False;
end;

procedure TScriptmanager.ExposeClass(AClass : TClass);
begin
  ExposeType(AClass.ClassInfo);
end;

procedure TScriptmanager.ExposeConstant(Name : string; Value : TValue);
var
  Constant : TdwsConstant;
begin
  Constant := FCompilerExtender.Constants.Add;
  Constant.Name := name;
  Constant.Value := Value.AsVariant;
  Constant.DataType := TdwsUnit.RTTITypeToScriptType(FRttiContext.GetType(Value.TypeInfo));
end;

procedure TScriptmanager.ExposeFunction(Name : string; CodeAdress : Pointer; FunctionInfo : Pointer);
var
  AdressAsTValue : TValue;
begin
  TValue.Make(NativeUInt(CodeAdress), FunctionInfo, AdressAsTValue);
  ExposeFunctionOrMethod(name, AdressAsTValue, FunctionInfo);
end;

procedure TScriptmanager.ExposeFunctionOrMethod(Name : string; Adress : TValue; RttiInfo : Pointer);
var
  ScriptFunc : TdwsFunction;
  FuncMethRttiInfo : TRttiInvokableType;
  TmpType : TRTTIType;
  Parameter : TRttiParameter;
begin
  assert(not Adress.IsEmpty and Assigned(RttiInfo));
  assert(name <> '');
  TmpType := FRttiContext.GetType(RttiInfo);
  // Func.OnEval
  if TmpType is TRttiInvokableType then
  begin
    FuncMethRttiInfo := TmpType as TRttiInvokableType;
    ScriptFunc := FCompilerExtender.Functions.Add(name);
    for Parameter in FuncMethRttiInfo.GetParameters do
    begin
      ScriptFunc.Parameters.Add(Parameter.Name, TdwsUnit.RTTITypeToScriptType(Parameter.ParamType));
    end;
    if Assigned(FuncMethRttiInfo.ReturnType) then
    begin
      assert(FuncMethRttiInfo.ReturnType.Name <> '');
      ScriptFunc.ResultType := TdwsUnit.RTTITypeToScriptType(FuncMethRttiInfo.ReturnType);
    end;
    FFunctionMethodInvoker.Add(TFunctionMethodInvoker.Create(FuncMethRttiInfo, Adress));
    ScriptFunc.OnEval := FFunctionMethodInvoker.Last.Invoke;
  end
  else raise EScriptExposeException.Create('TScriptmanager.ExposeFunctionOrMethode: Function or Method "' + name + '" has not invokable type.');
end;

procedure TScriptmanager.ExposeMethod(Name : string; Instance : TObject; MethodInfo : Pointer);
var
  CodeAdress : TMethod;
begin
  assert(Assigned(Instance) and Assigned(MethodInfo));
  assert(name <> '');
  CodeAdress.Code := Instance.MethodAddress(name);
  CodeAdress.Data := Pointer(Instance);
  if not Assigned(CodeAdress.Code) then raise EScriptExposeException.Create('TScriptmanager.ExposeMethod: Could not find method "' + name + '" in instance of type "' + Instance.ClassName + '".');
  ExposeFunctionOrMethod(name, TValue.From<TMethod>(CodeAdress), MethodInfo);
end;

procedure TScriptmanager.ExposeType(AType : Pointer);
begin
  FCompilerExtender.ExposeRTTI(AType, [eoExposeVirtual, eoExposePublic, eoNoFreeOnCleanup]);
end;

{ procedure TScriptmanager.PublishVariable<T>(Name: String);
 var Variable : TdwsGlobal;
 AObject : TdwsInstance;
 Wrapper : TValueWrapper<T>;
 RttiType : TRttiType;
 begin
 if FPublishedVariables.ContainsKey(Name) then raise EScriptCompileException.Create('TScriptmanager.PublishVariable: A variable with name "'+name+'" already exist.');
 // get Rttitype to get typename or classname
 RttiType := FRttiContext.GetType(TypeInfo(T));
 // if a class instance
 if RttiType.IsInstance then
 begin
 Wrapper := TValueWrapperForObject<T>.Create;
 FPublishedVariables.Add(Name, Wrapper);
 AObject := FCompilerExtender.Instances.Add;
 AObject.AutoDestroyExternalObject := False;
 AObject.DataType := RttiType.Name;
 AObject.Name := Name;
 AObject.OnInstantiate := TValueWrapperForObject<T>(Wrapper).OnAccess;
 end
 // if other type
 else
 begin
 Wrapper := TValueWrapperForObject<T>.Create;
 FPublishedVariables.Add(Name, Wrapper);
 Variable := FCompilerExtender.Variables.Add;
 Variable.Name := Name;
 Variable.DataType := FCompilerExtender.RTTITypeToScriptType(RttiType);
 Variable.OnReadVar := TValueWrapperForVariable<T>(Wrapper).OnRead;
 Variable.OnWriteVar := TValueWrapperForVariable<T>(Wrapper).OnWrite;
 end;
 end; }

{ RScriptReturnValue }

constructor RScriptReturnValue.Create(ResultValue : Variant;
  ExternalObject : TObject);
begin
  FResultValue := ResultValue;
  FExternalObject := ExternalObject;
  FIsEmpty := False;
end;

class function RScriptReturnValue.GetEmpty : RScriptReturnValue;
begin
  Result.FIsEmpty := True;
end;

{ TFuncInfoHelper }

{$HINTS OFF}


function TFuncInfoHelper.GetParameterIdentifiers : TStrings;
var
  i : integer;
begin
  Result := TStringList.Create;

  for i := 0 to FParams.Count - 1 do
      Result.Add(FParams[i].Name);

end;
{$HINTS ON}

{ TScript.TScriptInfo }

constructor TScript.TScriptInfo.Create(TargetScript : TScript);
var
  FuntionNames : TList<string>;
  FunctionName : string;
  Parameter : TStrings;
begin
  FTargetScript := TargetScript;
  FFunctions := TObjectDictionary<string, TFunctionInfo>.Create([doOwnsValues]);
  FuntionNames := FTargetScript.FExecutionContext.Info.GetFunctions;
  for FunctionName in FuntionNames do
  begin
    Parameter := TInfoFunc(FTargetScript.FExecutionContext.Info.Func[FunctionName]).GetParameterIdentifiers;
    FFunctions.Add(FunctionName, TFunctionInfo.Create(FunctionName, Parameter.Count));
    Parameter.Free;
  end;
  FGlobalVariables := FTargetScript.FExecutionContext.Info.GetGlobalVariables;
  FuntionNames.Free;
end;

destructor TScript.TScriptInfo.Destroy;
begin
  FFunctions.Free;
  FGlobalVariables.Free;
  inherited;
end;

{ TScript.TScriptInfo.TFunctionInfo }

constructor TScript.TScriptInfo.TFunctionInfo.Create(Name : string; ParameterCount : integer);
begin
  self.Name := name;
  self.ParameterCount := ParameterCount;
end;

{ TProgramInfoExtender }
{$HINTS OFF}


function TProgramInfoExtender.GetFunctions : TList<string>;
var
  i : integer;
begin
  Result := TList<string>.Create;

  for i := 0 to Table.Count - 1 do
    if Table.Symbols[i] is TFuncSymbol then
        Result.Add(Table.Symbols[i].Name);

end;
{$HINTS ON}
{$HINTS OFF}


function TProgramInfoExtender.GetGlobalVariables : TStrings;
var
  i : integer;
begin
  Result := TStringList.Create;

  for i := 0 to Table.Count - 1 do
    if Table.Symbols[i] is TDataSymbol then
        Result.Add(Table.Symbols[i].Name.ToLowerInvariant);

end;
{$HINTS ON}

{ TScriptmanager.TFunctionMethodInvoker }

constructor TScriptmanager.TFunctionMethodInvoker.Create(RttiType : TRttiInvokableType; CodeAdress : TValue);
var
  methParams : TArray<TRttiParameter>;
  param : TRttiParameter;
  i, k, ParamCount : integer;
begin
  FInvokeRttiType := RttiType;
  FProcOrMeth := CodeAdress;
  methParams := FInvokeRttiType.GetParameters;
  ParamCount := length(methParams);
  SetLength(FTypParams, ParamCount);
  SetLength(FNameParams, ParamCount);
  k := 0;
  for i := 0 to ParamCount - 1 do
  begin
    param := methParams[i];
    FTypParams[i] := param.ParamType;
    FNameParams[i] := param.Name;
    if (pfVar in param.Flags) then
    begin
      SetLength(FVarParams, k + 1);
      FVarParams[k] := i;
      Inc(k);
    end;
  end;
  FTypResult := FInvokeRttiType.ReturnType;
end;

destructor TScriptmanager.TFunctionMethodInvoker.Destroy;
begin
  FTypParams := nil;
  FNameParams := nil;
  FVarParams := nil;
  inherited;
end;

procedure TScriptmanager.TFunctionMethodInvoker.Invoke(Info : TProgramInfo);
  procedure PrepareParams(Info : TProgramInfo; var params : TArray<TValue>);
  var
    i : integer;
  begin
    SetLength(params, length(FTypParams));
    for i := 0 to high(FTypParams) do
    begin
      params[i] := TdwsRTTIInvoker.ValueFromParam(Info, FNameParams[i], FTypParams[i]);
    end;
  end;

var
  params : TArray<TValue>;
  ResultValue : TValue;
  i : integer;
begin
  PrepareParams(Info, params);
  ResultValue := FInvokeRttiType.Invoke(FProcOrMeth, params);
  if FTypResult <> nil then
  begin
    if ResultValue.Kind = tkClass then
        Info.ResultVars.Value := Info.RegisterExternalObject(ResultValue.AsObject)
    else TdwsRTTIInvoker.AssignIInfoFromValue(Info.ResultVars, ResultValue, FTypResult, Info);
  end;
  for i in FVarParams do
      TdwsRTTIInvoker.AssignIInfoFromValue(Info.Vars[FNameParams[i]], params[i], FTypParams[i], Info);
end;

initialization

ScriptManager := TScriptmanager.Create;

finalization

FreeAndNil(ScriptManager);

end.
