unit Engine.Expression;

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Log;

type

  EExpressionEvalError = class(Exception);
  EExpressionParseError = class(Exception);
  EExpressionOperandCountError = class(EExpressionEvalError);
  EExpressionOperandTypeMissmatch = class(EExpressionEvalError);

  EnumTokenType = (ttValue, ttGroup, ttIf, ttElse, ttNot, ttAnd, ttOr, ttEqual, ttNotEqual, ttGreaterThan, ttGreaterThanOrEqual,
    ttLessThan, ttLessThanOrEqual, ttComma, ttAssignment, ttIn,
    ttAdd, ttSubtract, ttMultiply, ttDivide, ttNewStatement);

  SetTokenType = set of EnumTokenType;

const
  TOKEN_MAP : array [EnumTokenType] of string =
    (
    '',
    '()',
    'IF',
    'ELSE',
    'NOT',
    'AND',
    'OR',
    '=',
    '<>',
    '>',
    '>=',
    '<',
    '<=',
    ',',
    ':=',
    'in',
    '+',
    '-',
    '*',
    '/',
    ';'
    );

  OPEN_BRACKET                      = '(';
  CLOSING_BRACKET                   = ')';
  SPACE                             = ' ';
  COMMA                             = ',';
  SEMICOLON                         = ';';
  TOKEN_DELIMITERS : TArray<string> = [OPEN_BRACKET, CLOSING_BRACKET, SPACE, COMMA, SEMICOLON];

type

  TToken = class
    private
      FTokenType : EnumTokenType;
    public
      property TokenType : EnumTokenType read FTokenType;
      function IsType(const TokenType : EnumTokenType) : boolean; overload;
      function IsType(const TokenTypes : SetTokenType) : boolean; overload;
      constructor Create(const TokenType : EnumTokenType);
  end;

  TTokenValue = class(TToken)
    private
      FValue : string;
    public
      property Value : string read FValue;
      constructor Create(const Value : string);
  end;

  TTokenGroup = class(TToken)
    private
      FInnerTokens : TObjectList<TToken>;
    public
      property InnerTokens : TObjectList<TToken> read FInnerTokens;
      constructor Create();
      destructor Destroy; override;
  end;

  TTokenizer = class
    strict private
      FTokenDictionary : TCaseInsensitiveDictionary<EnumTokenType>;
      FTokens : TObjectList<TToken>;
      procedure Tokenize(const Text : string);
    public
      property Tokens : TObjectList<TToken> read FTokens;
      constructor Create(const Text : string);
      destructor Destroy; override;
  end;

  TExpressionContext = class(TCaseInsensitiveDictionary<TValue>)
    strict private
      class var FRttiContext : TRttiContext;
      class var FEnumTypeMap : TCaseInsensitiveDictionary<TRttiOrdinalType>;
      class constructor CreateTExpressionContext;
      class destructor DestroyTExpressionContext;
    private
      FSuppressNotifies : boolean;
    protected
      procedure KeyNotify(const Key : string; Action : TCollectionNotification); override;
      procedure ValueNotify(const Value : TValue; Action : TCollectionNotification); override;
    public
      class function GetEnumTypeByStringValue(const AValue : string) : TRttiOrdinalType;
      /// <summary> If True, notifications will not send for changes.</summary>
      property SuppressNotifies : boolean read FSuppressNotifies write FSuppressNotifies;
      procedure AddOrSetValue(const Key : string; const Value : TValue);
      function Clone : TExpressionContext;
  end;

  {$REGION 'Expression Tree Nodes'}

  TExpressionTreeNode = class
    protected
      FChildren : TObjectList<TExpressionTreeNode>;
    public
      property Children : TObjectList<TExpressionTreeNode> read FChildren;
      constructor Create();
      function Eval(const Context : TExpressionContext) : TValue; virtual; abstract;
      destructor Destroy; override;
  end;

  /// <summary> Special node that contains subnodes, where any node is a statement and stands for himself</summary>
  TExpressionTreeNodeStatements = class(TExpressionTreeNode)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeField = class(TExpressionTreeNode)
    private
      FInstanceName : string;
      FPath, FPathWithParams : string;
    public
      property InstanceName : string read FInstanceName;
      property Path : string read FPath;
      property PathWithParams : string read FPathWithParams;
      constructor Create(const FieldDescriptor : string; Parameters : array of TExpressionTreeNode);
      function Eval(const Context : TExpressionContext) : TValue; override;
      procedure Assign(const Context : TExpressionContext; Value : TValue);
  end;

  TExpressionTreeNodeValue = class(TExpressionTreeNode)
    private
      FValue : TValue;
    public
      constructor Create(const Value : TValue);
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOperator = class(TExpressionTreeNode)
    protected
      FOperands : TArray<TValue>;
      procedure CheckAndLoadOperands(OperandCount : integer; const Context : TExpressionContext);
      procedure CheckAndLoadOperand(OperandIndex, OperandCount : integer; const Context : TExpressionContext);
  end;

  TExpressionTreeNodeOpAnd = class(TExpressionTreeNodeOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpOr = class(TExpressionTreeNodeOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpNot = class(TExpressionTreeNodeOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpIfThen = class(TExpressionTreeNodeOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpAssignement = class(TExpressionTreeNodeOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeComparingOperator = class(TExpressionTreeNodeOperator)
    protected
      function CompareValue(const Left, Right : TValue) : integer;
      function SameValue(const Left, Right : TValue) : boolean;
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpEqual = class(TExpressionTreeNodeComparingOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpNotEqual = class(TExpressionTreeNodeComparingOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpGreaterThan = class(TExpressionTreeNodeComparingOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpLessThan = class(TExpressionTreeNodeComparingOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpGreaterThanOrEqual = class(TExpressionTreeNodeComparingOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpLessThanOrEqual = class(TExpressionTreeNodeComparingOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpIn = class(TExpressionTreeNodeComparingOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeArithmeticOperator = class(TExpressionTreeNodeOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpAdd = class(TExpressionTreeNodeArithmeticOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpSubtract = class(TExpressionTreeNodeArithmeticOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpMultiply = class(TExpressionTreeNodeArithmeticOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;

  TExpressionTreeNodeOpDivide = class(TExpressionTreeNodeArithmeticOperator)
    public
      function Eval(const Context : TExpressionContext) : TValue; override;
  end;
  {$ENDREGION}

  TExpression = class
    private
      FRootNode : TExpressionTreeNode;
      FRawExpression : string;
      function GetVariableNamesForNode(Node : TExpressionTreeNode) : TList<string>;
      function GetVariableFullpathsForNode(Node : TExpressionTreeNode) : TArray<string>;
    public
      class function FastEval(const Expression : string; Context : TExpressionContext) : TValue; overload; static;
      class function FastEval(const Expression : string) : TValue; overload; static;
    public
      property RawExpression : string read FRawExpression;
      constructor Create(RootNode : TExpressionTreeNode); overload;
      constructor Create(const Expression : string); overload;
      function Eval(Context : TExpressionContext) : TValue;
      function GetVariableNames : TList<string>;
      function GetVariableFullpaths : TArray<string>;
      destructor Destroy; override;
  end;

  /// <summary> Helper tool to easily creates expression in delphi.</summary>
  RExpressionBuilder = record
    strict private
      FExpressionTree : TExpressionTreeNode;
    private
      function GetExpression : TExpression;
      property ExpressionTree : TExpressionTreeNode read FExpressionTree write FExpressionTree;
    public
      property Expression : TExpression read GetExpression;
      /// <summary> Creates a part of a Expression that is a descriptor for a field.
      /// the descriptor will obtained until the Expression is checked against a value.
      /// Than the descriptor will Evald to an concret value.</summary>
      constructor CreateFieldDescriptor(const FieldDescriptor : string; Parameters : array of RExpressionBuilder);
      constructor IfThen(const ACondition, ATrue, AFalse : RExpressionBuilder);
      constructor Assignement(const Target, Value : RExpressionBuilder);
      class function Empty : RExpressionBuilder; static;
      class operator BitwiseAnd(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator BitwiseOr(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator LogicalNot(const a : RExpressionBuilder) : RExpressionBuilder;
      class operator in (a : RExpressionBuilder; b : RExpressionBuilder) : RExpressionBuilder;
      class operator Equal(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator NotEqual(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator GreaterThan(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator LessThan(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator LessThanOrEqual(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator GreaterThanOrEqual(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator Add(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator Subtract(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator Multiply(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator Divide(const a, b : RExpressionBuilder) : RExpressionBuilder;
      class operator Explicit(a : integer) : RExpressionBuilder;
      class operator Explicit(a : single) : RExpressionBuilder;
      class operator Explicit(a : boolean) : RExpressionBuilder;
      class operator Explicit(a : TValue) : RExpressionBuilder;
      class operator Explicit(const a : string) : RExpressionBuilder;
  end;

implementation

{ TExpressionTreeNode }

constructor TExpressionTreeNode.Create;
begin
  FChildren := TObjectList<TExpressionTreeNode>.Create();
end;

destructor TExpressionTreeNode.Destroy;
begin
  FChildren.Free;
  inherited;
end;

{ TExpressionTreeNodeValue }

constructor TExpressionTreeNodeValue.Create(const Value : TValue);
begin
  inherited Create();
  FValue := Value;
end;

function TExpressionTreeNodeValue.Eval(const Context : TExpressionContext) : TValue;
begin
  result := FValue;
end;

{ RExpressionBuilder }

class operator RExpressionBuilder.Add(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpAdd.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

constructor RExpressionBuilder.Assignement(const Target, Value : RExpressionBuilder);
begin
  ExpressionTree := TExpressionTreeNodeOpAssignement.Create();
  ExpressionTree.Children.Add(Target.ExpressionTree);
  ExpressionTree.Children.Add(Value.ExpressionTree);
end;

class operator RExpressionBuilder.BitwiseAnd(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpAnd.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.BitwiseOr(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpOr.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

constructor RExpressionBuilder.CreateFieldDescriptor(const FieldDescriptor : string; Parameters : array of RExpressionBuilder);
var
  NodeParameters : TArray<TExpressionTreeNode>;
begin
  SetLength(NodeParameters, length(Parameters));
  NodeParameters := HArray.Map<RExpressionBuilder, TExpressionTreeNode>(Parameters,
    function(const Value : RExpressionBuilder) : TExpressionTreeNode
    begin
      result := Value.ExpressionTree;
    end);
  ExpressionTree := TExpressionTreeNodeField.Create(FieldDescriptor, NodeParameters);
end;

class operator RExpressionBuilder.Divide(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpDivide.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class function RExpressionBuilder.Empty : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeValue.Create(TValue.Empty);
end;

class operator RExpressionBuilder.Equal(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpEqual.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.Explicit(const a : string) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeValue.Create(a);
end;

class operator RExpressionBuilder.Explicit(a : boolean) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeValue.Create(a);
end;

class operator RExpressionBuilder.Explicit(a : integer) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeValue.Create(a);
end;

class operator RExpressionBuilder.Explicit(a : TValue) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeValue.Create(a);
end;

class operator RExpressionBuilder.Explicit(a : single) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeValue.Create(a);
end;

function RExpressionBuilder.GetExpression : TExpression;
begin
  result := TExpression.Create(ExpressionTree);
end;

class operator RExpressionBuilder.GreaterThan(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpGreaterThan.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.GreaterThanOrEqual(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpGreaterThanOrEqual.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

constructor RExpressionBuilder.IfThen(const ACondition, ATrue, AFalse : RExpressionBuilder);
begin
  ExpressionTree := TExpressionTreeNodeOpIfThen.Create();
  ExpressionTree.Children.Add(ACondition.ExpressionTree);
  ExpressionTree.Children.Add(ATrue.ExpressionTree);
  ExpressionTree.Children.Add(AFalse.ExpressionTree);
end;

class operator RExpressionBuilder.in(a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpIn.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.LessThan(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpLessThan.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.LessThanOrEqual(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpLessThanOrEqual.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.LogicalNot(const a : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpNot.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
end;

class operator RExpressionBuilder.Multiply(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpMultiply.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.NotEqual(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpNotEqual.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

class operator RExpressionBuilder.Subtract(const a, b : RExpressionBuilder) : RExpressionBuilder;
begin
  result.ExpressionTree := TExpressionTreeNodeOpSubtract.Create();
  result.ExpressionTree.Children.Add(a.ExpressionTree);
  result.ExpressionTree.Children.Add(b.ExpressionTree);
end;

{ TExpressionTreeNodeOperator }

procedure TExpressionTreeNodeOperator.CheckAndLoadOperands(OperandCount : integer; const Context : TExpressionContext);
var
  i : integer;
begin
  if Children.Count <> OperandCount then
      raise EExpressionOperandCountError.CreateFmt('%s: Expected %d operands, but found %d',
      [Self.ClassName, OperandCount, Children.Count]);
  SetLength(FOperands, OperandCount);
  for i := 0 to OperandCount - 1 do
      FOperands[i] := FChildren[i].Eval(Context);
end;

procedure TExpressionTreeNodeOperator.CheckAndLoadOperand(OperandIndex, OperandCount : integer; const Context : TExpressionContext);
begin
  if Children.Count <> OperandCount then
      raise EExpressionOperandCountError.CreateFmt('%s: Expected %d operands, but found %d',
      [Self.ClassName, OperandCount, Children.Count]);
  if (OperandIndex < 0) or (OperandIndex >= OperandCount) then
      raise EExpressionOperandCountError.CreateFmt('%s: Tried to load invalid operand with index %d, but only have %d.',
      [Self.ClassName, OperandIndex, Children.Count]);
  SetLength(FOperands, OperandCount);
  FOperands[OperandIndex] := FChildren[OperandIndex].Eval(Context);
end;

{ TExpressionTreeNodeOpAnd }

function TExpressionTreeNodeOpAnd.Eval(const Context : TExpressionContext) : TValue;
begin
  CheckAndLoadOperand(0, 2, Context);
  if not FOperands[0].AsBoolean then
      result := False
  else
  begin
    CheckAndLoadOperand(1, 2, Context);
    result := FOperands[1].AsBoolean;
  end;
end;

{ TExpressionTreeNodeOpOr }

function TExpressionTreeNodeOpOr.Eval(const Context : TExpressionContext) : TValue;
begin
  CheckAndLoadOperand(0, 2, Context);
  if FOperands[0].AsBoolean then
      result := True
  else
  begin
    CheckAndLoadOperand(1, 2, Context);
    result := FOperands[1].AsBoolean;
  end;
end;

{ TExpressionTreeNodeOpNot }

function TExpressionTreeNodeOpNot.Eval(const Context : TExpressionContext) : TValue;
begin
  CheckAndLoadOperands(1, Context);
  result := not FOperands[0].AsBoolean;
end;

{ TExpressionTreeNodeComparingOperator }

function TExpressionTreeNodeComparingOperator.CompareValue(const Left, Right : TValue) : integer;
begin
  result := Left.CompareValue(Right);
end;

function TExpressionTreeNodeComparingOperator.Eval(const Context : TExpressionContext) : TValue;
begin
  CheckAndLoadOperands(2, Context);
end;

function TExpressionTreeNodeComparingOperator.SameValue(const Left, Right : TValue) : boolean;
begin
  result := Left.SameValue(Right);
end;

{ TExpressionTreeNodeOpEqual }

function TExpressionTreeNodeOpEqual.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  result := SameValue(FOperands[0], FOperands[1]);
end;

{ TExpressionTreeNodeOpNotEqual }

function TExpressionTreeNodeOpNotEqual.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  result := not SameValue(FOperands[0], FOperands[1]);
end;

{ TExpressionTreeNodeOpGreaterThan }

function TExpressionTreeNodeOpGreaterThan.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) > 0;
end;

{ TExpressionTreeNodeOpLessThan }

function TExpressionTreeNodeOpLessThan.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) < 0;
end;

{ TExpressionTreeNodeOpGreaterThanOrEqual }

function TExpressionTreeNodeOpGreaterThanOrEqual.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) >= 0;
end;

{ TExpressionTreeNodeOpLessThanOrEqual }

function TExpressionTreeNodeOpLessThanOrEqual.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  result := CompareValue(FOperands[0], FOperands[1]) <= 0;
end;

{ TExpressionTreeNodeOpIn }

function TExpressionTreeNodeOpIn.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  result := FOperands[1].Contains(FOperands[0]);
end;

{ TExpressionTreeNodeArithmeticOperator }

function TExpressionTreeNodeArithmeticOperator.Eval(const Context : TExpressionContext) : TValue;
begin
  CheckAndLoadOperands(2, Context);
end;

{ TExpressionTreeNodeOpMultiply }

function TExpressionTreeNodeOpMultiply.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  if FOperands[0].IsNumeric and FOperands[1].IsNumeric then
      result := FOperands[0].Multiply(FOperands[1])
  else
    if FOperands[0].IsSet and FOperands[1].IsSet then
      result := FOperands[0].Intersect(FOperands[1])
  else raise EOperandTypeMissmatch.CreateFmt('TExpressionTreeNodeOpMultiply.Eval: Operand multiply is for "%s" and "%s" not supported.',
      [FOperands[0].GetRttiType.Name, FOperands[1].GetRttiType.Name]);
end;

{ TExpression }

constructor TExpression.Create(RootNode : TExpressionTreeNode);
begin
  FRootNode := RootNode;
end;

constructor TExpression.Create(const Expression : string);
var
  Constants : TCaseInsensitiveDictionary<TValue>;

function ParseExpression(Tokens : TObjectList<TToken>) : RExpressionBuilder; forward;

  procedure Expect(Tokens : TObjectList<TToken>; TokenTypes : SetTokenType);
  begin
    if not Tokens.First.IsType(TokenTypes) then
        raise EExpressionParseError.CreateFmt('TExpression.Create: Expect %s, but found %s.',
        [HRtti.SetToString<SetTokenType>(TokenTypes), HRtti.EnumerationToString<EnumTokenType>(Tokens.First.TokenType)]);
  end;

  function ParseValue(Tokens : TObjectList<TToken>) : RExpressionBuilder;
    function ParseParameter(Tokens : TObjectList<TToken>) : TArray<RExpressionBuilder>;
    var
      Parameters : TList<RExpressionBuilder>;
      SubTokens : TObjectList<TToken>;
    begin
      SubTokens := TObjectList<TToken>.Create;
      Parameters := TList<RExpressionBuilder>.Create;
      while Tokens.Count > 0 do
      begin
        SubTokens.Clear;
        while (Tokens.Count > 0) and not Tokens.First.IsType(ttComma) do
          // extract token, because subtokens list will take ownership
            SubTokens.Add(Tokens.Extract(Tokens.First));
        // if there are tokens left, first will be comma and ca deleted
        if Tokens.Count > 0 then
        begin
          assert(Tokens.First.IsType(ttComma));
          Tokens.Delete(0);
        end;
        if SubTokens.Count < 0 then
            raise EExpressionParseError.Create('TExpression.Create.ParseParameter: Error on parsing parameters.');
        Parameters.Add(ParseExpression(SubTokens));
      end;
      result := Parameters.ToArray;
      Parameters.Free;
      SubTokens.Free;
    end;

  var
    Value : string;
    ATValue : TValue;
    AInteger : integer;
    ASingle : single;
    Parameters : TArray<RExpressionBuilder>;
    ValueFormatSettings : TFormatSettings;
    OrdinalType : TRttiOrdinalType;
  begin
    assert(Tokens.First.IsType(ttValue));
    Value := TTokenValue(Tokens.First).Value;
    Tokens.Delete(0);
    ValueFormatSettings := TFormatSettings.Invariant;
    // first try to convert to number (before test for callable, else . would confuse test)
    if TryStrToFloat(Value, ASingle, ValueFormatSettings) then
    begin
      // integer would also detected as float, so try as integer
      if TryStrToInt(Value, AInteger) then
          result := RExpressionBuilder(AInteger)
      else
          result := RExpressionBuilder(ASingle);
    end
    // callable (member of a instance and/or parameter that will calling)
    else if Value.Contains('.') or ((Tokens.Count > 0) and (Tokens.First.IsType(ttGroup))) then
    begin
      // parameter of a callable will be surrounded by "( )" -> this will create a group
      if (Tokens.Count > 0) and (Tokens.First.IsType(ttGroup)) then
      begin
        Parameters := ParseParameter(TTokenGroup(Tokens.First).InnerTokens);
        Tokens.Delete(0);
      end
      else
          Parameters := nil;
      result := RExpressionBuilder.CreateFieldDescriptor(Value, Parameters);
    end
    // simple Value
    else
    begin
      // some constants exists for an string, like True
      if Constants.TryGetValue(Value, ATValue) then
          result := RExpressionBuilder(ATValue)

      else
      begin
        // try to convert to enum
        OrdinalType := TExpressionContext.GetEnumTypeByStringValue(Value);
        if OrdinalType <> nil then
        begin
          AInteger := GetEnumValue(OrdinalType.Handle, Value);
          ATValue := TValue.FromOrdinal(OrdinalType.Handle, AInteger);
          result := RExpressionBuilder(ATValue);
        end
        // if no constant or ordinal value, string will works all time
        else
            result := RExpressionBuilder(Value);
      end;
    end;
  end;

  function ParseExpression(Tokens : TObjectList<TToken>) : RExpressionBuilder;
  var
    FirstOperand, SecondOperand, Condition : RExpressionBuilder;
    Operation : EnumTokenType;
  begin
    // parse first operand
    Expect(Tokens, [ttValue, ttGroup, ttIf, ttNot]);
    case Tokens.First.TokenType of
      ttGroup :
        begin
          FirstOperand := ParseExpression(TTokenGroup(Tokens.First).InnerTokens);
          Tokens.Delete(0);
        end;
      // single value, member or simple value
      ttValue : FirstOperand := ParseValue(Tokens);
      // negate following value/group
      ttNot :
        begin
          Tokens.Delete(0);
          Expect(Tokens, [ttValue, ttGroup]);
          case Tokens.First.TokenType of
            ttGroup :
              begin
                FirstOperand := not ParseExpression(TTokenGroup(Tokens.First).InnerTokens);
                Tokens.Delete(0);
              end;
            ttValue : FirstOperand := not ParseValue(Tokens);
          end;
        end;
      // IfThen with empty True Value
      ttIf : FirstOperand := RExpressionBuilder(TValue.Empty);
    end;
    // are there more tokens? if not, first operand is complete expression
    // or if next token is else, current expression is the condition of an IfThen,
    // so condition finished
    if (Tokens.Count <= 0) or Tokens.First.IsType([ttElse, ttNewStatement]) then
        result := FirstOperand
    else
    begin
      Expect(Tokens, [ttIf, ttAnd, ttOr, ttEqual, ttNotEqual, ttGreaterThan, ttGreaterThanOrEqual, ttLessThan, ttLessThanOrEqual,
        ttAssignment, ttIn, ttAdd, ttSubtract, ttMultiply, ttDivide, ttNewStatement]);
      Operation := Tokens.First.TokenType;
      Tokens.Delete(0);

      case Operation of
        ttAnd, ttOr, ttEqual, ttNotEqual, ttGreaterThan, ttGreaterThanOrEqual, ttLessThan, ttLessThanOrEqual, ttAssignment,
          ttIn, ttAdd, ttSubtract, ttMultiply, ttDivide :
          begin
            SecondOperand := ParseExpression(Tokens);
            case Operation of
              ttAnd : result := FirstOperand and SecondOperand;
              ttOr : result := FirstOperand or SecondOperand;
              ttEqual : result := FirstOperand = SecondOperand;
              ttNotEqual : result := FirstOperand <> SecondOperand;
              ttGreaterThan : result := FirstOperand > SecondOperand;
              ttGreaterThanOrEqual : result := FirstOperand >= SecondOperand;
              ttLessThan : result := FirstOperand < SecondOperand;
              ttLessThanOrEqual : result := FirstOperand <= SecondOperand;
              ttIn : result := FirstOperand in SecondOperand;
              ttAssignment : result := RExpressionBuilder.Assignement(FirstOperand, SecondOperand);
              ttAdd : result := FirstOperand + SecondOperand;
              ttSubtract : result := FirstOperand - SecondOperand;
              ttMultiply : result := FirstOperand * SecondOperand;
              ttDivide : result := FirstOperand / SecondOperand;
            end;
          end;
        ttIf :
          begin
            Condition := ParseExpression(Tokens);
            // if no more tokens left, short (without else) IfThen version is used
            if (Tokens.Count > 0) and not Tokens.First.IsType(ttNewStatement) then
            begin
              Expect(Tokens, [ttElse]);
              Tokens.Delete(0);
              SecondOperand := ParseExpression(Tokens);
            end
            else
                SecondOperand := RExpressionBuilder(TValue.Empty);
            result := RExpressionBuilder.IfThen(Condition, FirstOperand, SecondOperand);
          end;
      else raise ENotImplemented.CreateFmt('TExpression.Parse: Operator "%s" not implemented',
          [HRtti.EnumerationToString<EnumTokenType>(Operation)]);
      end;
    end;
  end;

var
  Tokenizer : TTokenizer;
  Node : TExpressionTreeNode;
begin
  FRawExpression := Expression;
  Tokenizer := TTokenizer.Create(Expression);
  Constants := TCaseInsensitiveDictionary<TValue>.Create;
  Constants.Add('TRUE', True);
  Constants.Add('FALSE', False);
  Constants.Add('NIL', nil);
  Constants.Add('''''', '');
  Constants.Add('0x28', '(');
  Constants.Add('0x29', ')');
  Constants.Add('''-''', '-');
  // FRootNode := ParseExpression(Tokenizer.Tokens).ExpressionTree;
  FRootNode := TExpressionTreeNodeStatements.Create;
  while Tokenizer.Tokens.Count > 0 do
  begin
    Node := ParseExpression(Tokenizer.Tokens).ExpressionTree;
    FRootNode.Children.Add(Node);
    if Tokenizer.Tokens.Count > 0 then
    begin
      if Tokenizer.Tokens.First.IsType(ttNewStatement) then
          Tokenizer.Tokens.Delete(0)
      else
          raise EExpressionParseError.CreateFmt('TExpression.Create: Unpected end of expression, expect ; or EOF, but found %s',
          [HRtti.EnumerationToString<EnumTokenType>(Tokenizer.Tokens.First.TokenType)]);
    end;
  end;
  Tokenizer.Free;
  Constants.Free;
end;

destructor TExpression.Destroy;
begin
  FRootNode.Free;
  inherited;
end;

function TExpression.Eval(Context : TExpressionContext) : TValue;
begin
  result := FRootNode.Eval(Context);
end;

class function TExpression.FastEval(const Expression : string; Context : TExpressionContext) : TValue;
var
  ExpressionEvaluator : TExpression;
begin
  ExpressionEvaluator := TExpression.Create(Expression);
  result := ExpressionEvaluator.Eval(Context);
  ExpressionEvaluator.Free;
end;

class function TExpression.FastEval(const Expression : string) : TValue;
var
  Context : TExpressionContext;
begin
  Context := TExpressionContext.Create;
  result := TExpression.FastEval(Expression, Context);
  Context.Free;
end;

function TExpression.GetVariableFullpaths : TArray<string>;
begin
  result := GetVariableFullpathsForNode(FRootNode);
end;

function TExpression.GetVariableFullpathsForNode(Node : TExpressionTreeNode) : TArray<string>;
var
  Child : TExpressionTreeNode;
begin
  if Node is TExpressionTreeNodeField then
      result := [TExpressionTreeNodeField(Node).InstanceName + '.' + TExpressionTreeNodeField(Node).Path]
  else
      result := [];
  for Child in Node.Children do
      result := result + GetVariableFullpathsForNode(Child);
end;

function TExpression.GetVariableNames : TList<string>;
begin
  result := GetVariableNamesForNode(FRootNode);
end;

function TExpression.GetVariableNamesForNode(Node : TExpressionTreeNode) : TList<string>;
var
  Child : TExpressionTreeNode;
  ChildList : TList<string>;
begin
  result := TList<string>.Create;
  if Node is TExpressionTreeNodeField then
      result.Add(TExpressionTreeNodeField(Node).InstanceName);
  for Child in Node.Children do
  begin
    ChildList := GetVariableNamesForNode(Child);
    result.AddRange(ChildList);
    ChildList.Free;
  end;
end;

{ TExpressionTreeNodeField }

procedure TExpressionTreeNodeField.Assign(const Context : TExpressionContext; Value : TValue);
var
  Instance : TValue;
  i : integer;
  Parameters : TArray<TValue>;
begin
  if Context.TryGetValue(FInstanceName, Instance) then
  begin
    SetLength(Parameters, Children.Count);
    for i := 0 to Children.Count - 1 do
        Parameters[i] := Children[i].Eval(Context);
    Instance.Assign(FPathWithParams, Value, Parameters, True);
  end;
end;

constructor TExpressionTreeNodeField.Create(const FieldDescriptor : string; Parameters : array of TExpressionTreeNode);
var
  SplittedText : TArray<string>;
begin
  inherited Create();
  assert(not FieldDescriptor.IsEmpty);
  SplittedText := HString.Split(FieldDescriptor, ['.'], False, 2);
  FInstanceName := SplittedText[0];
  if length(SplittedText) > 1 then
  begin
    FPath := SplittedText[1];
    if length(Parameters) > 0 then
        FPathWithParams := FPath + '(' + string.Join(',', HArray.Generate<string>(length(Parameters), 'param')) + ')'
    else
        FPathWithParams := FPath;
  end;
  Children.AddRange(Parameters);
end;

function TExpressionTreeNodeField.Eval(const Context : TExpressionContext) : TValue;
var
  Parameters : TArray<TValue>;
  i : integer;
  Instance : TValue;
begin
  if Context.TryGetValue(FInstanceName, Instance) then
  begin
    SetLength(Parameters, Children.Count);
    for i := 0 to Children.Count - 1 do
        Parameters[i] := Children[i].Eval(Context);
    result := Instance.Resolve(FPathWithParams, Parameters, False);
  end
  else result := TValue.Empty;
end;

{ TToken }

function TToken.IsType(const TokenType : EnumTokenType) : boolean;
begin
  result := IsType([TokenType]);
end;

constructor TToken.Create(const TokenType : EnumTokenType);
begin
  FTokenType := TokenType;
end;

function TToken.IsType(const TokenTypes : SetTokenType) : boolean;
begin
  result := TokenType in TokenTypes;
end;

{ TTokenizer }

constructor TTokenizer.Create(const Text : string);
var
  TokenType : EnumTokenType;
begin
  FTokenDictionary := TCaseInsensitiveDictionary<EnumTokenType>.Create();
  // init TokenMap (dict)
  for TokenType := low(EnumTokenType) to high(EnumTokenType) do
      FTokenDictionary.Add(TOKEN_MAP[TokenType], TokenType);
  FTokens := TObjectList<TToken>.Create();
  Tokenize(Text);
end;

destructor TTokenizer.Destroy;
begin
  FTokenDictionary.Free;
  FTokens.Free;
  inherited;
end;

procedure TTokenizer.Tokenize(const Text : string);
var
  Parts : TList<string>;
procedure ReadGroup(TargetTokenList : TObjectList<TToken>); forward;

/// <summary> Use first part and create a token from it, will remove it from parts.</summary>
  procedure CreateToken(TargetTokenList : TObjectList<TToken>);
  var
    TokenType : EnumTokenType;
  begin
    assert(not HArray.Contains([OPEN_BRACKET, CLOSING_BRACKET, SPACE], Parts.First));
    // only values not contained in dict
    if FTokenDictionary.TryGetValue(Parts.First, TokenType) then
        TargetTokenList.Add(TToken.Create(TokenType))
    else
        TargetTokenList.Add(TTokenValue.Create(Parts.First));
    Parts.Delete(0);
  end;

  procedure ReadParts(TargetTokenList : TObjectList<TToken>);
  begin
    while Parts.Count > 0 do
    begin
      // ignore space, it is only a delimiter that does not matter anymore
      if (Parts.First = SPACE) then
          Parts.Delete(0)
      else
      begin
        // ( -> new group
        if Parts.First = OPEN_BRACKET then
            ReadGroup(TargetTokenList)
        else if Parts.First = CLOSING_BRACKET then
            raise EExpressionParseError.Create('TTokenizer.Tokenize: Bracket error, unexpected ")" found. Expression: ''' + Text + '''')
        else
            CreateToken(TargetTokenList);
      end;
    end;
  end;

  procedure ReadGroup(TargetTokenList : TObjectList<TToken>);
  var
    TokenGroup : TTokenGroup;
  begin
    assert(Parts.First = OPEN_BRACKET);
    Parts.Delete(0);
    TokenGroup := TTokenGroup.Create;
    TargetTokenList.Add(TokenGroup);
    // closing bracket will close a group
    while (Parts.Count > 0) and (Parts.First <> CLOSING_BRACKET) do
    begin
      // ignore space, it is only a delimiter that does not matter anymore
      if (Parts.First = SPACE) then
          Parts.Delete(0)
      else
      begin
        // ( -> new group
        if Parts.First = OPEN_BRACKET then
            ReadGroup(TokenGroup.InnerTokens)
        else
            CreateToken(TokenGroup.InnerTokens);
      end;
    end;
    if Parts.Count <= 0 then
        raise EExpressionParseError.Create('TTokenizer.Tokenize: Unexpected end of expression, missing ")". Expression: ''' + Text + '''')
    else
    begin
      assert(Parts.First = CLOSING_BRACKET);
      Parts.Delete(0);
    end;
  end;

var
  Part : string;
begin
  Parts := TList<string>.Create;
  for Part in HString.Split(Text, TOKEN_DELIMITERS, True) do
      Parts.Add(Part);

  // finally tokenize
  ReadParts(Tokens);

  Parts.Free;
end;

{ TTokenGroup }

constructor TTokenGroup.Create();
begin
  inherited Create(ttGroup);
  FInnerTokens := TObjectList<TToken>.Create();
end;

destructor TTokenGroup.Destroy;
begin
  FInnerTokens.Free;
  inherited;
end;

{ TTokenValue }

constructor TTokenValue.Create(const Value : string);
begin
  inherited Create(ttValue);
  FValue := Value;
end;

{ TExpressionTreeNodeOpIfThen }

function TExpressionTreeNodeOpIfThen.Eval(const Context : TExpressionContext) : TValue;
begin
  if Children.Count <> 3 then
      raise EExpressionOperandCountError.CreateFmt('%s: Expected %d operands, but found %d',
      [Self.ClassName, 3, Children.Count]);
  if FChildren[0].Eval(Context).AsBoolean then
      result := FChildren[1].Eval(Context)
  else
      result := FChildren[2].Eval(Context);
end;

{ TExpressionContext }

class constructor TExpressionContext.CreateTExpressionContext;
var
  RttiType : TRttiType;
  OrdinalType : TRttiOrdinalType;
  OrdValue : integer;
  Value : TValue;
  StringValue : string;
begin
  FEnumTypeMap := TCaseInsensitiveDictionary<TRttiOrdinalType>.Create;
  FRttiContext := TRttiContext.Create;
  for RttiType in FRttiContext.GetTypes do
  begin
    if RttiType.TypeKind = tkEnumeration then
    begin
      OrdinalType := RttiType.AsOrdinal;
      for OrdValue := OrdinalType.MinValue to OrdinalType.MaxValue do
      begin
        Value := TValue.FromOrdinal(OrdinalType.Handle, OrdValue);
        StringValue := Value.ToString;
        if not FEnumTypeMap.ContainsKey(StringValue) then
            FEnumTypeMap.Add(StringValue, OrdinalType)
        else
            FEnumTypeMap[StringValue] := nil;
      end;
    end;
  end;
end;

class destructor TExpressionContext.DestroyTExpressionContext;
begin
  FEnumTypeMap.Free;
  FRttiContext.Free;
end;

class function TExpressionContext.GetEnumTypeByStringValue(const AValue : string) : TRttiOrdinalType;
begin
  if not FEnumTypeMap.TryGetValue(AValue, result) then
      result := nil;
end;

procedure TExpressionContext.KeyNotify(const Key : string; Action : TCollectionNotification);
begin
  if not SuppressNotifies then
      inherited;
end;

procedure TExpressionContext.ValueNotify(const Value : TValue; Action : TCollectionNotification);
begin
  if not SuppressNotifies then
      inherited;
end;

procedure TExpressionContext.AddOrSetValue(const Key : string; const Value : TValue);
var
  wasPresent : boolean;
begin
  wasPresent := not SuppressNotifies and ContainsKey(Key);
  inherited AddOrSetValue(Key, Value);
  if wasPresent then KeyNotify(Key, cnAdded);
end;

function TExpressionContext.Clone : TExpressionContext;
var
  Item : TPair<string, TValue>;
begin
  result := TExpressionContext.Create;
  for Item in Self do
      result.Add(Item.Key, Item.Value);
end;

{ TExpressionTreeNodeOpAssignement }

function TExpressionTreeNodeOpAssignement.Eval(const Context : TExpressionContext) : TValue;
var
  Value : TValue;
begin
  if Children.Count <> 2 then
      raise EExpressionOperandCountError.CreateFmt('%s: Expected %d operands, but found %d',
      [Self.ClassName, 2, Children.Count]);
  Value := FChildren[1].Eval(Context);
  result := Value;
  if FChildren[0] is TExpressionTreeNodeField then
  begin
    TExpressionTreeNodeField(FChildren[0]).Assign(Context, Value);
  end
  else
      raise EExpressionOperandTypeMissmatch.CreateFmt('%s: Can only assign fields and properties values.', [Self.ClassName]);
end;

{ TExpressionTreeNodeOpAdd }

function TExpressionTreeNodeOpAdd.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  if (FOperands[0].IsNumeric and FOperands[1].IsNumeric) or (FOperands[0].IsString and FOperands[1].IsString) then
      result := FOperands[0].Add(FOperands[1])
  else raise EOperandTypeMissmatch.CreateFmt('TExpressionTreeNodeOpMultiply.Eval: Operand add is for "%s" and "%s" not supported.',
      [FOperands[0].GetRttiType.Name, FOperands[1].GetRttiType.Name]);
end;

{ TExpressionTreeNodeOpSubtract }

function TExpressionTreeNodeOpSubtract.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  if FOperands[0].IsNumeric and FOperands[1].IsNumeric then
      result := FOperands[0].Subtract(FOperands[1])
  else raise EOperandTypeMissmatch.CreateFmt('TExpressionTreeNodeOpMultiply.Eval: Operand subtract is for "%s" and "%s" not supported.',
      [FOperands[0].GetRttiType.Name, FOperands[1].GetRttiType.Name]);
end;

{ TExpressionTreeNodeOpDivide }

function TExpressionTreeNodeOpDivide.Eval(const Context : TExpressionContext) : TValue;
begin
  inherited;
  if FOperands[0].IsNumeric and FOperands[1].IsNumeric then
      result := FOperands[0].Divide(FOperands[1])
  else raise EOperandTypeMissmatch.CreateFmt('TExpressionTreeNodeOpMultiply.Eval: Operand divide is for "%s" and "%s" not supported.',
      [FOperands[0].GetRttiType.Name, FOperands[1].GetRttiType.Name]);
end;

{ TExpressionTreeNodeStatements }

function TExpressionTreeNodeStatements.Eval(const Context : TExpressionContext) : TValue;
var
  Child : TExpressionTreeNode;
  i : integer;
begin
  result := TValue.Empty;
  // ---------------------------------------WARNING-------------------------------
  // Only the last statement can change the tree, as otherwise this node could be freed
  // and then the next statement would explode as it work on invalid data.
  // -----------------------------------------------------------------------------
  // use as result first non empty value
  for i := 0 to Children.Count - 1 do
  begin
    Child := Children[i];
    if result.IsEmpty then
        result := Child.Eval(Context)
    else
        Child.Eval(Context);
  end;
end;

end.
