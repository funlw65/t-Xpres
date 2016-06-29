{
XpresParser
===========
Por Tito Hinostroza.

Unidad con funciones básicas del Analizador sintáctico(como el analizador de
expresiones aritméticas).
Se define la clase base "TCompilerBase", de donde debe derivarse el objeto
compilador a usar. La clase hace un análisis léxico sencillo en un lenguaje similar
al Pascal. Para personalizar al lenguaje, la clase ofrece la posibilidad de
sobreescribir algunos métodos críticos, o inclusive se puede reescribir la clase, si
las consideraciones de implementación lo requieren.
El diseño de esta unidad es un poco especial.
"TCompilerBase", usa variables estáticas definidas en esta unidad, para facilitar el
acceso a estas variables, desde fuera de la unidad (sin necesidad de referirse al
objeto).
De ello se deduce que solo se soporta crear una instacia de "TCompilerBase" a la
vez.
"TCompilerBase", se definió como una clase (porque en realidad pudo haberse creado
como un conjunto de métodos estáticos), para facilitar el poder sobreescribir
algunas rutinas y poder personalizar mejor a la unidad.

Aquí también se incluye el archivo en donde se implementará un intérprete/compilador.

Las variables pública más importantes de este módulo son:

 vars[]  -> almacena a las variables declaradas
 typs[]  -> almacena a los tipos declarados
 funcs[] -> almacena a las funciones declaradas
 cons[]  -> almacena a las constantes declaradas

Para mayor información sobre el uso del framework Xpres, consultar la documentación
técnica.
Para ver los cambios en esta versión, revisar el archivo cambios.txt.
}
unit XPresParser;
interface
uses
  Classes, SysUtils, fgl, Forms, LCLType, Dialogs, lclProc,
  SynEditHighlighter, SynFacilHighlighter, SynFacilBasic,
  XpresBas, XpresTypes, XpresElements, MisUtils;

type

{ TOperand }
//Operando
TOperand = object
public
  catOp: TCatOperan; //Categoría de operando
  typ  : TType;     //Referencia al tipo de dato
  txt  : string;    //Texto del operando o expresión, tal como aparece en la fuente
  ifun : integer;   //índice a funciones, en caso de que sea función
  rVar : TxpVar;    //referencia a la variable, en caso de que sea variable
  {---------------------------------------------------------
  Estos campos describen al operando, independientemente de que se le encuentree
  un tipo, válido. Si se le encuentra un tipo válido, se tendrá la referencia al tipo
  en "typ", y allí se tendrán los campos que describirán cómo se debe tratar realmente
  al operando. No tienen por qué coincidir con los campos equivalentes de "typ"}
  catTyp: TCatType;  //Categoría de Tipo de dato.
  size  : integer;   //Tamaño del operando en bytes.
  {---------------------------------------------------------}
{  estOp: integer;   Estado del operando. Usado para la generec. de código. No se define un
                    tipo específico, para dar libertad a la implementación a usarlo de la mejor
                    forma. La necesidad de este campo es debatible, pero se mantiene por
                    compatibilidad.}
  procedure Load; inline;  //carga el operador en registro o pila
  procedure Push; inline;  //pone el operador en la pila
  procedure Pop; inline;   //saca el operador en la pila
  function FindOperator(const oper: string): TOperator; //devuelve el objeto operador
  function GetOperator: Toperator;
  //Funciones para facilitar el acceso a campos de la variable, cuando sea variable
  function VarName: string; inline; //nombre de la variable, cuando sea de categ. coVariab
  function addr: TVarAddr; inline;  //dirección de la variable
  function bank: TVarBank; inline;  //banco o segmento
private
  Val  : TConsValue;
  procedure SetvalBool(AValue: boolean);
  procedure SetvalFloat(AValue: extended);
  procedure SetvalInt(AValue: Int64);
  procedure SetvalStr(AValue: string);
public
  //Campos de acceso a los valores constantes
  property valInt  : Int64 read val.ValInt write SetvalInt;
  property valFloat: extended read val.ValFloat write SetvalFloat;
  property valBool : boolean read val.ValBool write SetvalBool;
  property valStr  : string read val.ValStr write SetvalStr;
  //funciones de ayuda para adaptar los tipos numéricos
  function aWord: word; inline;  //devuelve el valor en Word
  function HByte: byte; inline;  //devuelve byte alto de valor entero
  function LByte: byte; inline;  //devuelve byte bajo de valor entero
  //campos para validar el rango de los valores
  function CanBeWord: boolean;   //indica si cae en el rango de un WORD
  function CanBeByte: boolean;   //indica si cae en el rango de un BYTE
  //Métodos para facilitar la implementación de intérpretes. Se puede obviar en compiladores
  //Permite obtener valores del operando, independiéntemente de la categoría de operando.
  function ReadBool: boolean;
  function ReadInt: int64;
  function ReadFloat: extended;
  function ReadStr: string;
end;

{ TCompilerBase }
{Clase base para crear al objeto compilador}
TCompilerBase = class
protected  //Eventos del compilador
  {Notar que estos eventos no se definen para usar métodos de objetos, sino que
  por comodidad para impementar el intérprete (y espero que por velocidad), usan
  simples procedimientos aislados}
  OnExprStart: procedure(const exprLevel: integer);  {Se genera al iniciar la
                                                      evaluación de una expresión.}
  OnExprEnd  : procedure(const exprLevel: integer; isParam: boolean);  {Se genera
                                             el terminar de evaluar una expresión}
  ExprLevel: Integer;  //Nivel de anidamiento de la rutina de evaluación de expresiones
  procedure ClearTypes;
  function CreateType(nom0: string; cat0: TCatType; siz0: smallint): TType;
  procedure CreateFunction(funName, varType: string);
  function CreateFunction(funName: string; typ: ttype; proc: TProcExecFunction
    ): TxpFun;
  function CreateSysFunction(funName: string; typ: ttype; proc: TProcExecFunction
    ): TxpFun;
  procedure CreateParam(fun: TxpFun; parName: string; typStr: string);
  function CaptureDelExpres: boolean;
  procedure CompileVarDeclar; virtual;
  procedure ClearVars;
  procedure ClearAllConst;
  procedure ClearAllFuncs;
  procedure ClearAllVars;
  procedure ClearFuncs;
  function CategName(cat: TCatType): string;
  procedure TipDefecBoolean(var Op: TOperand; tokcad: string);
  procedure TipDefecNumber(var Op: TOperand; toknum: string); virtual;
  procedure TipDefecString(var Op: TOperand; tokcad: string); virtual;
  function FindDuplicFunction: boolean;
  function EOExpres: boolean;
  function EOBlock: boolean;
  procedure SkipWhites; virtual;  //rutina para saltar blancos
  procedure GetExpression(const prec: Integer; isParam: boolean=false);
  procedure GetBoolExpression;
  procedure CreateVariable(const varName: string; typ: ttype);
  procedure CreateVariable(varName, varType: string);
  function FindVar(const varName: string; out idx: integer): boolean;
  function FindCons(const conName: string; out idx: integer): boolean;
  function FindFunc(const funName: string; out idx: integer): boolean;
  function FindPredefName(name: string): TIdentifType;
  function GetOperand: TOperand; virtual;
  function GetOperandP(pre: integer): TOperand;
  procedure CaptureParams; virtual;
  function FindFuncWithParams0(const funName: string; var idx: integer;
    idx0: integer=0): TFindFuncResult;
private
  procedure Evaluar(var Op1: TOperand; opr: TOperator; var Op2: TOperand);
  function GetExpressionCore(const prec: Integer): TOperand;
public
  xLex  : TSynFacilSyn; //resaltador - lexer
  //variables públicas del compilador
  ejecProg: boolean;   //Indica que se está ejecutando un programa o compilando
  DetEjec: boolean;   //para detener la ejecución (en intérpretes)

  typs  : TTypes;       //lista de tipos (El nombre "types" ya está reservado)
  func0 : TxpFun;      //función interna para almacenar parámetros
  cons  : TxpCons;  //lista de constantes
  vars  : TxpVars;  //lista de variables
  funcs : TxpFuns;  //lista de funciones
public  //Manejo de errores
  PErr  : TPError;     //Objeto de Error
  function HayError: boolean;
  procedure GenError(msg: string);
  procedure GenError(msg: String; const Args: array of const);
  function ErrorFile: string;
  function ErrorLine: integer;
  function ErrorCol: integer;
  procedure ShowError;
public  //Inicialización
  constructor Create; virtual;
  destructor Destroy; override;
end;

var
  {Variables globales. Realmente deberían ser campos de TCompilerBase. Se ponen aquí,
   para que puedan ser accedidas fácilmente desde el archivo "interprte.pas"}

  nIntVar : integer;    //número de variables internas
  nIntFun : integer;    //número de funciones internas
  nIntCon : integer;    //número de constantes internas

  cIn    : TContexts;   //entrada de datos
  p1, p2 : TOperand;    //Pasa los operandos de la operación actual
  res    : TOperand;    //resultado de la evaluación de la última expresión.
  catOperation: TCatOperation;  //combinación de categorías de los operandos
  //referencias obligatorias
  tkEol     : TSynHighlighterAttributes;
  tkIdentif : TSynHighlighterAttributes;
  tkKeyword : TSynHighlighterAttributes;
  tkNumber  : TSynHighlighterAttributes;
  tkString  : TSynHighlighterAttributes;
  tkOperator: TSynHighlighterAttributes;
  tkBoolean : TSynHighlighterAttributes;
  tkSysFunct: TSynHighlighterAttributes;
  //referencias adicionales
  {Estas referencias no deberían declararse aquí,sino que deben ser propias de cada
  implementación}
//  tkExpDelim: TSynHighlighterAttributes;
//  tkBlkDelim: TSynHighlighterAttributes;
  tkType    : TSynHighlighterAttributes;
//  tkOthers  : TSynHighlighterAttributes;

implementation
uses Graphics;

{TCompilerBase}
function TCompilerBase.HayError: boolean;
begin
  Result := PErr.HayError;
end;
procedure TCompilerBase.GenError(msg: string);
{Función de acceso rápido para Perr.GenError(). Pasa como posición a la posición
del contexto actual. Realiza la traducción del mensaje también.}
begin
  if (cIn = nil) or (cIn.curCon = nil) then
    Perr.GenError(dic(msg),'',1)
  else
    Perr.GenError(dic(msg), cIn.curCon);
end;
procedure TCompilerBase.GenError(msg: String; const Args: array of const);
{Versión con parámetros de GenError.}
begin
  if (cIn = nil) or (cIn.curCon = nil) then
    Perr.GenError(dic(msg, Args),'',1)
  else
    Perr.GenError(dic(msg, Args), cIn.curCon);
end;
function TCompilerBase.ErrorFile: string;
begin
  Result:= Perr.ArcError;
end;
function TCompilerBase.ErrorLine: integer;
begin
  Result := Perr.nLinError;
end;
function TCompilerBase.ErrorCol: integer;
begin
  Result := Perr.nColError;
end;
procedure TCompilerBase.ShowError;
begin
  Application.MessageBox(PChar(Perr.TxtErrorRC),
                         PChar(Perr.NombPrograma), MB_ICONEXCLAMATION);
//  Perr.Show;
end;

function TCompilerBase.FindVar(const varName:string; out idx: integer): boolean;
//Busca el nombre dado para ver si se trata de una variable definida
//Si encuentra devuelve TRUE y actualiza el índice.
var
  tmp: String;
  i: Integer;
begin
  Result := false;
  tmp := upCase(varName);
  for i:=0 to vars.Count-1 do begin
    if Upcase(vars[i].nom)=tmp then begin
      idx := i;
      exit(true);
    end;
  end;
end;
function TCompilerBase.FindFunc(const funName:string; out idx: integer): boolean;
//Busca el nombre dado para ver si se trata de una función definida
//Si encuentra devuelve TRUE y actualiza el índice.
var
  tmp: String;
  i: Integer;
begin
  Result := false;
  tmp := upCase(funName);
  for i:=0 to funcs.Count-1 do begin
    if Upcase(funcs[i].name)=tmp then begin
      idx := i;
      exit(true);
    end;
  end;
end;
function TCompilerBase.FindCons(const conName:string; out idx: integer): boolean;
//Busca el nombre dado para ver si se trata de una constante definida
//Si encuentra devuelve TRUE y actualiza el índice.
var
  tmp: String;
  i: Integer;
begin
  Result := false;
  tmp := upCase(conName);
  for i:=0 to cons.Count-1 do begin
    if Upcase(cons[i].name)=tmp then begin
      idx := i;
      exit(true);
    end;
  end;
end;
function TCompilerBase.FindPredefName(name: string): TIdentifType;
//Busca un identificador e indica si ya existe el nombre, sea como variable,
//función o constante.
var i: integer;
begin
  //busca como variable
  if FindVar(name,i) then begin
     exit(idtVar);
  end;
  //busca como función
  if FindFunc(name,i) then begin
     exit(idtFunc);
  end;
  //busca como constante
  if FindCons(name,i) then begin
     exit(idtCons);
  end;
  //no lo encuentra
  exit(idtNone);
end;

//Manejo de tipos
function TCompilerBase.CreateType(nom0: string; cat0: TCatType; siz0: smallint): TType;
//Crea una nueva definición de tipo en el compilador. Devuelve referencia al tipo recien creado
var r: TType;
  i: Integer;
begin
  //verifica nombre
  for i:=0 to typs.Count-1 do begin
    if typs[i].name = nom0 then begin
      GenError('Identificador de tipo duplicado.');
      exit;
    end;
  end;
  //configura nuevo tipo
  r := TType.Create;
  r.name:=nom0;
  r.cat:=cat0;
  r.size:=siz0;
  r.idx:=typs.Count;  //toma ubicación
//  r.amb:=;  //debe leer el bloque actual
  //agrega
  typs.Add(r);
  Result:=r;   //devuelve índice al tipo
end;
procedure TCompilerBase.ClearTypes;  //Limpia los tipos
begin
  typs.Clear;
end;
procedure TCompilerBase.ClearVars;
//Limpia todas las variables creadas por el usuario.
begin
  vars.Count:=nIntVar;  //deja las del sistema
end;
procedure TCompilerBase.ClearAllVars;
//Elimina todas las variables, incluyendo las predefinidas.
begin
  nIntVar := 0;
  vars.Clear;
end;
procedure TCompilerBase.ClearFuncs;
//Limpia todas las funciones creadas por el usuario.
begin
  funcs.Count := nIntFun;  //deja las del sistema
end;
procedure TCompilerBase.ClearAllFuncs;
//Elimina todas las funciones, incluyendo las predefinidas.
begin
  nIntFun := 0;
  funcs.Clear;
end;
procedure TCompilerBase.ClearAllConst;
//Elimina todas las funciones, incluyendo las predefinidas.
begin
  nIntCon := 0;
  cons.Clear;
end;

function TCompilerBase.CreateFunction(funName: string; typ: ttype; proc: TProcExecFunction): TxpFun;
//Crea una nueva función y devuelve un índice a la función.
var
  r : TxpFun;
  i: Integer;
begin
  //verifica si existe como variable
  if FindVar(funName, i) then begin
    GenError('Identificador duplicado: "' + funName + '".');
    exit;
  end;
  //verifica si existe como constante
  if FindCons(funName, i)then begin
    GenError('Identificador duplicado: "' + funName + '".');
    exit;
  end;
  //puede existir como función, no importa (sobrecarga)
  //registra la función en la tabla
  r := TxpFun.Create;
  r.name:= funName;
  r.typ := typ;
  r.proc:= proc;
  r.ClearParams;
  //agrega
  funcs.Add(r);
  Result := r;
end;
procedure TCompilerBase.CreateFunction(funName, varType: string);
//Define una nueva función en memoria.
var t: ttype;
  hay: Boolean;
begin
  //Verifica el tipo
  hay := false;
  for t in typs do begin
    if t.name=varType then begin
       hay:=true; break;
    end;
  end;
  if not hay then begin
    GenError('Tipo "' + varType + '" no definido.');
    exit;
  end;
  CreateFunction(funName, t, nil);
  //Ya encontró tipo, llama a evento
//  if t.OnGlobalDef<>nil then t.OnGlobalDef(funName, '');
end;
function TCompilerBase.CreateSysFunction(funName: string; typ: ttype; proc: TProcExecFunction): TxpFun;
//Crea una función del sistema o interna. Estas funciones estan siempre disponibles.
//Las funciones internas deben crearse todas al inicio.
begin
  Result := CreateFunction(funName, typ, proc);
  Inc(nIntFun);  //leva la cuenta
end;
procedure TCompilerBase.CreateParam(fun: TxpFun; parName: string; typStr: string
  );
//Crea un parámetro para una función
var
  hay: Boolean;
  typStrL: String;
  t : TType;
begin
  //busca tipo
  typStrL := LowerCase(typStr);
  for t in typs do begin
    if t.name = typStrL then begin
       hay:=true; break;
    end;
  end;
  if not hay then begin
    GenError('Undefined type "%s"', [typStr]);
    exit;
  end;
  //agrega
  fun.CreateParam(parName, t);
end;
function TCompilerBase.FindFuncWithParams0(const funName: string; var idx: integer;
  idx0 : integer = 0): TFindFuncResult;
{Busca una función que coincida con el nombre "funName" y con los parámetros de funcs[0]
El resultado puede ser:
 TFF_NONE   -> No se encuentra.
 TFF_PARTIAL-> Se encuentra solo el nombre.
 TFF_FULL   -> Se encuentra y coninciden sus parámetros, actualiza "idx".
"idx0", es el índice inicial desde donde debe buscar. Permite acelerar las búsquedas, cuando
ya se ha explorado antes.
}
var
  tmp: String;
  params : string;   //parámetros de la función
  i: Integer;
  hayFunc: Boolean;
begin
  Result := TFF_NONE;   //por defecto
  hayFunc := false;
  tmp := UpCase(funName);
  for i:=idx0 to funcs.Count-1 do begin  //no debe empezar en 0, porque allí está func[0]
    if Upcase(funcs[i].name)= tmp then begin
      //coincidencia, compara
      hayFunc := true;  //para indicar que encontró el nombre
      if funcs[i].SameParams(func0) then begin
        idx := i;    //devuelve ubicación
        Result := TFF_FULL; //encontró
        exit;
      end;
    end;
  end;
  //si llego hasta aquí es porque no encontró coincidencia
  if hayFunc then begin
    //Encontró al menos el nombre de la función, pero no coincide en los parámetros
    Result := TFF_PARTIAL;
    {Construye la lista de parámetros de las funciones con el mismo nombre. Solo
    hacemos esta tarea pesada aquí, porque  sabemos que se detendrá la compilación}
    params := '';   //aquí almacenará la lista
{    for i:=idx0 to high(funcs) do begin  //no debe empezar 1n 0, porque allí está func[0]
      if Upcase(funcs[i].name)= tmp then begin
        for j:=0 to high(funcs[i].pars) do begin
          params += funcs[i].pars[j].name + ',';
        end;
        params += LineEnding;
      end;
    end;}
  end;
end;
function TCompilerBase.FindDuplicFunction: boolean;
//Verifica si la última función agregada, está duplicada con alguna de las
//funciones existentes. Permite la sobrecarga. Si encuentra la misma
//función definida 2 o más veces, genera error y devuelve TRUE.
//DEbe llamarse siempre, después de definir una función nueva.
var
  ufun : String;
  i,j,n: Integer;
  tmp: String;
begin
  Result := false;
  n := funcs.Count-1;  //última función
  ufun := funcs[n].name;
  //busca sobrecargadas en las funciones anteriores
  for i:=0 to n-1 do begin
    if funcs[i].name = ufun then begin
      //hay una sobrecargada, verifica tipos de parámetros
      if not funcs[i].SameParams(funcs[n]) then break;
      //Tiene igual cantidad de parámetros y del mismo tipo. Genera Error
      tmp := '';
      for j := 0 to High(funcs[i].pars) do begin
        tmp += funcs[n].pars[j].name+', ';
      end;
      if length(tmp)>0 then tmp := copy(tmp,1,length(tmp)-2); //quita coma final
      GenError('Función '+ufun+'( '+tmp+' ) duplicada.');
      exit(true);
    end;
  end;
end;
function TCompilerBase.CategName(cat: TCatType): string;
begin
   case cat of
   t_integer: Result := 'Numérico';
   t_uinteger: Result := 'Numérico sin signo';
   t_float: Result := 'Flotante';
   t_string: Result := 'Cadena';
   t_boolean: Result := 'Booleano';
   t_enum: Result := 'Enumerado';
   else Result := 'Desconocido';
   end;
end;
function TCompilerBase.EOExpres: boolean; inline;
//Indica si se ha llegado al final de una expresión.
begin
  Result := cIn.tok = ';';  //en este caso de ejemplo, usamos putno y coma
  {En la práctica, puede ser conveniente definir un tipo de token como "tkExpDelim", para
   mejorar el tiempo de respuesta del procesamiento, de modo que la condición sería:
     Result := cIn.tokType = tkExpDelim;
  }
end;
function TCompilerBase.EOBlock: boolean; inline;
//Indica si se ha llegado el final de un bloque
begin
  Result := false;
  {No está implementado aquí, pero en la práctica puede ser conveniente definir un tipo de token
   como "tkBlkDelim", para mejorar el tiempo de respuesta del procesamiento, de modo que la
   condición sería:
  Result := cIn.tokType = tkBlkDelim;}
end;
procedure TCompilerBase.SkipWhites;
{Se crea como rutina aparte, para facilitar el poder cambiar el comportamiento y
adaptarlo al modo de trabajo del lenguaje.}
begin
  cIn.SkipWhites;
end;

{ Rutinas del compilador }
function TCompilerBase.CaptureDelExpres: boolean;
//Verifica si sigue un delimitador de expresión. Si encuentra devuelve false.
begin
  SkipWhites;
  if EOExpres then begin //encontró
    cIn.Next;   //pasa al siguiente
    exit(true);
  end else begin   //es un error
    GenError('Se esperaba ";"');
    exit(false);  //sale con error
  end;

end;
procedure TCompilerBase.TipDefecNumber(var Op: TOperand; toknum: string);
//Devuelve el tipo de número entero o flotante más sencillo que le corresponde a un token
//que representa a una constante numérica.
//Su forma de trabajo es buscar el tipo numérico más pequeño que permita alojar a la
//constante numérica indicada.

var
  n: int64;   //para almacenar a los enteros
  f: extended;  //para almacenar a reales
  i: Integer;
  menor: Integer;
  imen: integer;
begin
  if pos('.',toknum) <> 0 then begin  //es flotante
    Op.catTyp := t_float;   //es flotante
    try
      f := StrToFloat(toknum);  //carga con la mayor precisión posible
    except
      Op.typ := nil;
      GenError('Número decimal no válido.');
      exit;
    end;
    //busca el tipo numérico más pequeño que pueda albergar a este número
    Op.size := 4;   //se asume que con 4 bytes bastará
    {Aquí se puede decidir el tamaño de acuerdo a la cantidad de decimales indicados}

    Op.valFloat := f;  //debe devolver un extended
    menor := 1000;
    for i:=0 to typs.Count-1 do begin
      { TODO : Se debería tener una lista adicional TFloatTypes, para acelerar la
      búsqueda}
      if (typs[i].cat = t_float) and (typs[i].size>=Op.size) then begin
        //guarda el menor
        if typs[i].size < menor then  begin
           imen := i;   //guarda referencia
           menor := typs[i].size;
        end;
      end;
    end;
    if menor = 1000 then  //no hubo tipo
      Op.typ := nil
    else  //encontró
      Op.typ:=typs[imen];

  end else begin     //es entero
    Op.catTyp := t_integer;   //es entero
    //verificación de longitud de entero
    if length(toknum)>=19 then begin  //solo aquí puede haber problemas
      if toknum[1] = '-' then begin  //es negativo
        if length(toknum)>20 then begin
          GenError('Número muy grande. No se puede procesar. ');
          exit
        end else if (length(toknum) = 20) and  (toknum > '-9223372036854775808') then begin
          GenError('Número muy grande. No se puede procesar. ');
          exit
        end;
      end else begin  //es positivo
        if length(toknum)>19 then begin
          GenError('Número muy grande. No se puede procesar. ');
          exit
        end else if (length(toknum) = 19) and  (toknum > '9223372036854775807') then begin
          GenError('Número muy grande. No se puede procesar. ');
          exit
        end;
      end;
    end;
    //conversión. aquí ya no debe haber posibilidad de error
    n := StrToInt64(toknum);
    if (n>= -128) and  (n<=127) then
        Op.size := 1
    else if (n>= -32768) and (n<=32767) then
        Op.size := 2
    else if (n>= -2147483648) and (n<=2147483647) then
        Op.size := 4
    else if (n>= -9223372036854775808) and (n<=9223372036854775807) then
        Op.size := 8;
    Op.valInt := n;   //copia valor de constante entera
    //busca si hay tipo numérico que soporte esta constante
{      Op.typ:=nil;
    for i:=0 to typs.Count-1 do begin
      if (typs[i].cat = t_integer) and (typs[i].size=Op.size) then
        Op.typ:=typs[i];  //encontró
    end;}
    //busca el tipo numérico más pequeño que pueda albergar a este número
    menor := 1000;
    for i:=0 to typs.Count-1 do begin
      { TODO : Se debería tener una lista adicional  TIntegerTypes, para acelerar la
      búsqueda}
      if (typs[i].cat = t_integer) and (typs[i].size>=Op.size) then begin
        //guarda el menor
        if typs[i].size < menor then  begin
           imen := i;   //guarda referencia
           menor := typs[i].size;
        end;
      end;
    end;
    if menor = 1000 then  //no hubo tipo
      Op.typ := nil
    else  //encontró
      Op.typ:=typs[imen];
  end;
end;
procedure TCompilerBase.TipDefecString(var Op: TOperand; tokcad: string);
//Devuelve el tipo de cadena encontrado en un token
var
  i: Integer;
begin
  Op.catTyp := t_string;   //es cadena
  Op.size:=length(tokcad);
  //toma el texto
  Op.valStr := copy(cIn.tok,2, length(cIn.tok)-2);   //quita comillas
  //////////// Verifica si hay tipos string definidos ////////////
  Op.typ:=nil;
  //Busca primero tipo string (longitud variable)
  for i:=0 to typs.Count-1 do begin
    { TODO : Se debería tener una lista adicional  TStringTypes, para acelerar la
    búsqueda}
    //x := typs[i];
    if (typs[i].cat = t_string) and (typs[i].size=-1) then begin  //busca un char
      Op.typ:=typs[i];  //encontró
      break;
    end;
  end;
  if Op.typ=nil then begin
    //no hubo "string", busca al menos "char", para generar ARRAY OF char
    for i:=0 to typs.Count-1 do begin
      { TODO : Se debería tener una lista adicional  TStringTypes, para acelerar la
      búsqueda}
      if (typs[i].cat = t_string) and (typs[i].size=1) then begin  //busca un char
        Op.typ:=typs[i];  //encontró
        break;
      end;
    end;
  end;
end;
procedure TCompilerBase.TipDefecBoolean(var Op: TOperand; tokcad: string);
//Devuelve el tipo de cadena encontrado en un token
var
  i: Integer;
begin
  Op.catTyp := t_boolean;   //es flotante
  Op.size:=1;   //se usará un byte
  //toma valor constante
  Op.valBool:= (tokcad[1] in ['t','T']);
  //verifica si hay tipo boolean definido
  Op.typ:=nil;
  for i:=0 to typs.Count-1 do begin
    { TODO : Se debería tener una lista adicional  TBooleanTypes, para acelerar la
    búsqueda}
    if (typs[i].cat = t_boolean) then begin  //basta con que haya uno
      Op.typ:=typs[i];  //encontró
      break;
    end;
  end;
end;
procedure TCompilerBase.CaptureParams;
//Lee los parámetros de una función en la función interna funcs[0]
begin
  SkipWhites;
  func0.ClearParams;
  if EOBlock or EOExpres then begin
    //no tiene parámetros
  end else begin
    //Debe haber parámetros
    if cIn.tok<>'(' then begin
      GenError('Se esperaba "("'); exit;
    end;
    cin.Next;
    repeat
      GetExpression(0, true);  //captura parámetro
      if perr.HayError then exit;   //aborta
      //guarda tipo de parámetro
      func0.CreateParam('',res.typ);
      if cIn.tok = ',' then begin
        cIn.Next;   //toma separador
        SkipWhites;
      end else begin
        //no sigue separador de parámetros,
        //debe terminar la lista de parámetros
        //¿Verificar EOBlock or EOExpres ?
        break;
      end;
    until false;
    //busca paréntesis final
    if cIn.tok<>')' then begin
      GenError('Se esperaba ")"'); exit;
    end;
    cin.Next;
  end;
end;
function TCompilerBase.GetOperand: TOperand;
{Parte de la funcion analizadora de expresiones que genera codigo para leer un operando.
Debe devolver el tipo del operando y también el valor (obligatorio para el caso
de intérpretes y opcional para compiladores)}
var
  i: Integer;
  ivar: Integer;
  ifun: Integer;
  tmp: String;
begin
  PErr.Clear;
  SkipWhites;
  if cIn.tokType = tkNumber then begin  //constantes numéricas
    Result.catOp:=coConst;       //constante es Mono Operando
    Result.txt:= cIn.tok;     //toma el texto
    TipDefecNumber(Result, cIn.tok); //encuentra tipo de número, tamaño y valor
    if pErr.HayError then exit;  //verifica
    if Result.typ = nil then begin
        GenError('No hay tipo definido para albergar a esta constante numérica');
        exit;
      end;
    cIn.Next;    //Pasa al siguiente
  end else if cIn.tokType = tkIdentif then begin  //puede ser variable, constante, función
    if FindVar(cIn.tok, ivar) then begin
      //es una variable
      Result.rvar:=vars[ivar];   //guarda referencia a la variable
      Result.catOp:=coVariab;    //variable
      Result.catTyp:= vars[ivar].typ.cat;  //categoría
      Result.typ:=vars[ivar].typ;
      Result.txt:= cIn.tok;     //toma el texto
      cIn.Next;    //Pasa al siguiente
    end else if FindFunc(cIn.tok, ifun) then begin  //no es variable, debe ser función
      tmp := cIn.tok;  //guarda nombre de función
      cIn.Next;    //Toma identificador
      CaptureParams;  //primero lee parámetros
      if HayError then exit;
      //busca como función
      case FindFuncWithParams0(tmp, i, ifun) of  //busca desde ifun
      //TFF_NONE:      //No debería pasar esto
      TFF_PARTIAL:   //encontró la función, pero no coincidió con los parámetros
         GenError('Error en tipo de parámetros de '+ tmp +'()');
      TFF_FULL:     //encontró completamente
        begin   //encontró
          Result.ifun:=i;      //guarda referencia a la función
          Result.catOp :=coExpres; //expresión
          Result.txt:= cIn.tok;    //toma el texto
    //      Result.catTyp:= funcs[i].typ.cat;  //no debería ser necesario
          Result.typ:=funcs[i].typ;
          funcs[i].proc(funcs[i]);  //llama al código de la función
          exit;
        end;
      end;
    end else begin
      GenError('Identificador desconocido: "' + cIn.tok + '"');
      exit;
    end;
  end else if cIn.tokType = tkSysFunct then begin  //es función de sistema
    //Estas funciones debem crearse al iniciar el compilador y están siempre disponibles.
    tmp := cIn.tok;  //guarda nombre de función
    cIn.Next;    //Toma identificador
    CaptureParams;  //primero lee parámetros en func[0]
    if HayError then exit;
    //buscamos una declaración que coincida.
    case FindFuncWithParams0(tmp, i) of
    TFF_NONE:      //no encontró ni la función
       GenError('Función no implementada: "' + tmp + '"');
    TFF_PARTIAL:   //encontró la función, pero no coincidió con los parámetros
       GenError('Error en tipo de parámetros de '+ tmp +'()');
    TFF_FULL:     //encontró completamente
      begin   //encontró
        Result.ifun:=i;      //guarda referencia a la función
        Result.catOp :=coExpres; //expresión
        Result.txt:= cIn.tok;    //toma el texto
  //      Result.catTyp:= funcs[i].typ.cat;  //no debería ser necesario
        Result.typ:=funcs[i].typ;
        funcs[i].proc(funcs[i]);  //llama al código de la función
        exit;
      end;
    end;
  end else if cIn.tokType = tkBoolean then begin  //true o false
    Result.catOp:=coConst;       //constante es Mono Operando
    Result.txt:= cIn.tok;     //toma el texto
    TipDefecBoolean(Result, cIn.tok); //encuentra tipo de número, tamaño y valor
    if pErr.HayError then exit;  //verifica
    if Result.typ = nil then begin
       GenError('No hay tipo definido para albergar a esta constante booleana');
       exit;
     end;
    cIn.Next;    //Pasa al siguiente
  end else if cIn.tok = '(' then begin  //"("
    cIn.Next;
    GetExpression(0);
    Result := res;
    if PErr.HayError then exit;
    If cIn.tok = ')' Then begin
       cIn.Next;  //lo toma
    end Else begin
       GenError('Error en expresión. Se esperaba ")"');
       Exit;       //error
    end;
  end else if (cIn.tokType = tkString) then begin  //constante cadena
    Result.catOp:=coConst;     //constante es Mono Operando
//    Result.txt:= cIn.tok;     //toma el texto
    TipDefecString(Result, cIn.tok); //encuentra tipo de número, tamaño y valor
    if pErr.HayError then exit;  //verifica
    if Result.typ = nil then begin
       GenError('No hay tipo definido para albergar a esta constante cadena');
       exit;
     end;
    cIn.Next;    //Pasa al siguiente
{  end else if (cIn.tokType = tkOperator then begin
   //los únicos símbolos válidos son +,-, que son parte de un número
    }
  end else begin
    //No se reconoce el operador
    GenError('Se esperaba operando');
  end;
end;
procedure TCompilerBase.CreateVariable(const varName: string; typ: ttype);
var
  r : TxpVar;
begin
  //verifica nombre
  if FindPredefName(varName) <> idtNone then begin
    GenError('Identificador duplicado: "' + varName + '".');
    exit;
  end;
  //registra variable en la tabla
  r := TxpVar.Create;
  r.nom:=varName;
  r.typ := typ;   //fija  referencia a tipo
  vars.Add(r);
  //Ya encontró tipo, llama a evento
  if typ.OnGlobalDef<>nil then typ.OnGlobalDef(varName, '');
end;
procedure TCompilerBase.CreateVariable(varName, varType: string);
{Agrega una variable a la tabla de variables.
 Los tipos siempre aparecen en minúscula.}
var t: ttype;
  hay: Boolean;
begin
  //Verifica el tipo
  hay := false;
  for t in typs do begin
    if t.name=varType then begin
       hay:=true; break;
    end;
  end;
  if not hay then begin
    GenError('Tipo "' + varType + '" no definido.');
    exit;
  end;
  CreateVariable(varName, t);
  //puede salir con error
end;
procedure TCompilerBase.CompileVarDeclar;
{Compila la declaración de variables. Usa una sintaxis, sencilla, similar a la de
 Pascal. Lo normal sería que se sobreescriba este método para adecuarlo al lenguaje
 que se desee implementar. }
var
  varType: String;
  varName: String;
  varNames: array of string;  //nombre de variables
  n: Integer;
  tmp: String;
begin
  setlength(varNames,0);  //inicia arreglo
  //procesa variables res,b,c : int;
  repeat
    SkipWhites;
    //ahora debe haber un identificador de variable
    if cIn.tokType <> tkIdentif then begin
      GenError('Se esperaba identificador de variable.');
      exit;
    end;
    //hay un identificador
    varName := cIn.tok;
    cIn.Next;  //lo toma
    SkipWhites;
    //sgrega nombre de variable
    n := high(varNames)+1;
    setlength(varNames,n+1);  //hace espacio
    varNames[n] := varName;  //agrega nombre
    if cIn.tok <> ',' then break; //sale
    cIn.Next;  //toma la coma
  until false;
  //usualmente debería seguir ":"
  if cIn.tok = ':' then begin
    //debe venir el tipo de la variable
    cIn.Next;  //lo toma
    SkipWhites;
    if (cIn.tokType <> tkType) then begin
      GenError('Se esperaba identificador de tipo.');
      exit;
    end;
    varType := cIn.tok;   //lee tipo
    cIn.Next;
    //reserva espacio para las variables
    for tmp in varNames do begin
      CreateVariable(tmp, lowerCase(varType));
      if Perr.HayError then exit;
    end;
  end else begin
    GenError('Se esperaba ":" o ",".');
    exit;
  end;
  if not CaptureDelExpres then exit;
  SkipWhites;
end;
procedure TCompilerBase.Evaluar(var Op1: TOperand; opr: TOperator; var Op2: TOperand);
{Ejecuta una operación con dos operandos y un operador. "opr" es el operador de Op1.
El resultado debe devolverse en "res". En el caso de intérpretes, importa el
resultado de la Operación.
En el caso de compiladores, lo más importante es el tipo del resultado, pero puede
usarse también "res" para cálculo de expresiones constantes.
}
var
  o: TxOperation;
begin
   debugln(space(ExprLevel)+' Eval('+Op1.txt + ',' + Op2.txt+')');
   PErr.IniError;
   //Busca si hay una operación definida para: <tipo de Op1>-opr-<tipo de Op2>
   o := opr.FindOperation(Op2.typ);
   if o = nil then begin
//      GenError('No se ha definido la operación: (' +
//                    Op1.typ.name + ') '+ opr.txt + ' ('+Op2.typ.name+')');
      GenError('Operación no válida: (' +
                    Op1.typ.name + ') '+ opr.txt + ' ('+Op2.typ.name+')');
      Exit;
    end;
   {Llama al evento asociado con p1 y p2 como operandos. Debe devolver el resultado
   en "res"}
   p1 := Op1; p2 := Op2;  { TODO : Debe optimizarse }
   catOperation := TCatOperation((Ord(Op1.catOp) << 2) or ord(Op2.catOp)); //junta categorías de operandos
   o.proc;      //Ejecuta la operación
   //El resultado debe estar en "res"
   //Completa campos de "res", si es necesario
//   res.txt := Op1.txt + opr.txt + Op2.txt;   //texto de la expresión
//   res.uop := opr;   //última operación ejecutada
End;
function TCompilerBase.GetOperandP(pre: integer): TOperand;
//Toma un operando realizando hasta encontrar un operador de precedencia igual o menor
//a la indicada
var
  Op1: TOperand;
  Op2: TOperand;
  opr: TOperator;
  pos: TPosCont;
begin
  debugln(space(ExprLevel)+' CogOperando('+IntToStr(pre)+')');
  Op1 :=  GetOperand;  //toma el operador
  if pErr.HayError then exit;
  //verifica si termina la expresion
  pos := cIn.PosAct;    //Guarda por si lo necesita
  SkipWhites;
  opr := Op1.GetOperator;
  if opr = nil then begin  //no sigue operador
    Result:=Op1;
  end else if opr=nullOper then begin  //hay operador pero, ..
    //no está definido el operador siguente para el Op1, (no se puede comparar las
    //precedencias) asumimos que aquí termina el operando.
    cIn.PosAct := pos;   //antes de coger el operador
    GenError('No está definido el operador: '+ opr.txt + ' para tipo: '+Op1.typ.name);
    exit;
//    Result:=Op1;
  end else begin  //si está definido el operador (opr) para Op1, vemos precedencias
    If opr.jer > pre Then begin  //¿Delimitado por precedencia de operador?
      //es de mayor precedencia, se debe evaluar antes.
      Op2 := GetOperandP(pre);  //toma el siguiente operando (puede ser recursivo)
      if pErr.HayError then exit;
      Evaluar(Op1, opr, Op2);  //devuelve en "res"
      Result:=res;
    End else begin  //la precedencia es menor o igual, debe salir
      cIn.PosAct := pos;   //antes de coger el operador
      Result:=Op1;
    end;
  end;
end;
function TCompilerBase.GetExpressionCore(const prec: Integer): TOperand; //inline;
{Analizador de expresiones. Esta es probablemente la función más importante del
 compilador. Procesa una expresión en el contexto de entrada llama a los eventos
 configurados para que la expresión se evalúe (intérpretes) o se compile (compiladores).
 Devuelve un operando con información sobre el resultado de la expresión.}
var
  Op1, Op2  : TOperand;   //Operandos
  opr1: TOperator;  //Operadores
begin
  Op1.catTyp:=t_integer;    //asumir opcion por defecto
  Op2.catTyp:=t_integer;   //asumir opcion por defecto
  pErr.Clear;
  //----------------coger primer operando------------------
  Op1 := GetOperand; if pErr.HayError then exit;
  debugln(space(ExprLevel)+' Op1='+Op1.txt);
  //verifica si termina la expresion
  SkipWhites;
  opr1 := Op1.GetOperator;
  if opr1 = nil then begin  //no sigue operador
    //Expresión de un solo operando. Lo carga por si se necesita
    Op1.Load;   //carga el operador para cumplir. Este evento no debería ser necesario.
    Result:=Op1;
    exit;  //termina ejecucion
  end;
  //------- sigue un operador ---------
  //verifica si el operador aplica al operando
  if opr1 = nullOper then begin
    GenError('No está definido el operador: '+ opr1.txt + ' para tipo: '+Op1.typ.name);
    exit;
  end;
  //inicia secuencia de lectura: <Operador> <Operando>
  while opr1<>nil do begin
    //¿Delimitada por precedencia?
    If opr1.jer <= prec Then begin  //es menor que la que sigue, expres.
      Result := Op1;  //solo devuelve el único operando que leyó
      exit;
    End;
{    //--------------------coger operador ---------------------------
	//operadores unitarios ++ y -- (un solo operando).
    //Se evaluan como si fueran una mini-expresión o función
	if opr1.id = op_incremento then begin
      case Op1.catTyp of
        t_integer: Cod_IncremOperanNumerico(Op1);
      else
        GenError('Operador ++ no es soportado en este tipo de dato.',PosAct);
        exit;
      end;
      opr1 := cogOperador; if pErr.HayError then exit;
      if opr1.id = Op_ninguno then begin  //no sigue operador
        Result:=Op1; exit;  //termina ejecucion
      end;
    end else if opr1.id = op_decremento then begin
      case Op1.catTyp of
        t_integer: Cod_DecremOperanNumerico(Op1);
      else
        GenError('Operador -- no es soportado en este tipo de dato.',PosAct);
        exit;
      end;
      opr1 := cogOperador; if pErr.HayError then exit;
      if opr1.id = Op_ninguno then begin  //no sigue operador
        Result:=Op1; exit;  //termina ejecucion
      end;
    end;}
    //--------------------coger segundo operando--------------------
    Op2 := GetOperandP(Opr1.jer);   //toma operando con precedencia
    debugln(space(ExprLevel)+' Op2='+Op2.txt);
    if pErr.HayError then exit;
    //prepara siguiente operación
    Evaluar(Op1, opr1, Op2);    //evalua resultado en "res"
    Op1 := res;
    if PErr.HayError then exit;
    SkipWhites;
    opr1 := Op1.GetOperator;   {lo toma ahora con el tipo de la evaluación Op1 (opr1) Op2
                                porque puede que Op1 (opr1) Op2, haya cambiado de tipo}
  end;  //hasta que ya no siga un operador
  Result := Op1;  //aquí debe haber quedado el resultado
end;
procedure TCompilerBase.GetExpression(const prec: Integer; isParam: boolean = false
    //indep: boolean = false
    );
{Envoltura para GetExpressionCore(). Se coloca así porque GetExpressionCore()
tiene diversos puntos de salida y Se necesita llamar siempre a expr_end() al
terminar.
Toma una expresión del contexto de entrada y devuelve el resultado em "res".
"isParam" indica que la expresión evaluada es el parámetro de una función.
"indep", indica que la expresión que se está evaluando es anidada pero es independiente
de la expresion que la contiene, así que se puede liberar los registros o pila.
}
{ TODO : Para optimizar debería existir solo GetExpression() y no GetExpressionCore() }
begin
  Inc(ExprLevel);  //cuenta el anidamiento
  debugln(space(ExprLevel)+'>Inic.expr');
  if OnExprStart<>nil then OnExprStart(ExprLevel);  //llama a evento
  res := GetExpressionCore(prec);
  if PErr.HayError then exit;
  if OnExprEnd<>nil then OnExprEnd(ExprLevel, isParam);    //llama al evento de salida
  debugln(space(ExprLevel)+'>Fin.expr');
  Dec(ExprLevel);
  if ExprLevel = 0 then debugln('');
end;
procedure TCompilerBase.GetBoolExpression;
//Simplifica la evaluación de expresiones booleanas, validando el tipo
begin
  GetExpression(0);  //evalua expresión
  if PErr.HayError then exit;
  if res.Typ.cat <> t_boolean then begin
    GenError('Se esperaba expresión booleana');
  end;
end;

{function GetNullExpression(): TOperand;
//Simplifica la evaluación de expresiones sin dar error cuando encuentra algún delimitador
begin
  if
  GetExpression(0);  //evalua expresión
  if PErr.HayError then exit;
end;}

constructor TCompilerBase.Create;
begin
  PErr.IniError;   //inicia motor de errores
  //Inicia lista de tipos
  typs := TTypes.Create(true);
  cons := TxpCons.Create(true);
  vars := TxpVars.Create(true);
  funcs := TxpFuns.Create(true);
  //Inicia variables, funciones y constantes
  ClearAllVars;
  ClearAllFuncs;
  ClearAllConst;
  //inicia la sintaxis
  xLex := TSynFacilSyn.Create(nil);   //crea lexer
  func0 := TxpFun.Create;  //crea la función 0, para uso interno

  if HayError then PErr.Show;
  cIn := TContexts.Create(xLex); //Crea lista de Contextos
  ejecProg := false;
end;
destructor TCompilerBase.Destroy;
begin
  cIn.Destroy; //Limpia lista de Contextos
  func0.Destroy;
  xLex.Free;
  funcs.Destroy;
  vars.Destroy;
  cons.Destroy;
  typs.Free;
  inherited Destroy;
end;

{ TOperand }
function TOperand.VarName: string; inline;
begin
  Result := rvar.nom;
end;
function TOperand.addr: TVarAddr;
begin
  Result := rvar.addr;
end;
function TOperand.bank: TVarBank;
begin
  Result := rvar.bank;
end;

procedure TOperand.SetvalBool(AValue: boolean);
begin
  val.ValBool:=AValue;
end;

procedure TOperand.SetvalFloat(AValue: extended);
begin
//  if FvalFloat=AValue then Exit;
  val.ValFloat:=AValue;
end;

procedure TOperand.SetvalInt(AValue: Int64);
begin
//  if FvalInt=AValue then Exit;
  val.ValInt:=AValue;
end;

procedure TOperand.SetvalStr(AValue: string);
begin
  val.ValStr:=AValue;
end;

function TOperand.aWord: word;
begin
  Result := word(valInt);
end;

function TOperand.HByte: byte; inline;
begin
  Result := HI(word(valInt));
end;
function TOperand.LByte: byte; inline;
begin
  Result := LO(word(valInt));
end;

function TOperand.CanBeWord: boolean;
{Indica si el valor constante que contiene, puede ser convertido a un WORD sin pérdida}
begin
  Result := (valInt>=0) and (valInt<=$ffff);
end;
function TOperand.CanBeByte: boolean;
{Indica si el valor constante que contiene, puede ser convertido a un BYTE sin pérdida}
begin
  Result := (valInt>=0) and (valInt<=$ff);
end;

procedure TOperand.Load; inline;
begin
  //llama al evento de carga
  if typ.OnLoad <> nil then typ.OnLoad(@self);
end;
procedure TOperand.Push;
begin
  //llama al evento de pila
  if typ.OnPush <> nil then typ.OnPush(@self);
end;
procedure TOperand.Pop;
begin
  //llama al evento de pila
  if typ.OnPop <> nil then typ.OnPop(@self);
end;

function TOperand.FindOperator(const oper: string): TOperator;
//Recibe la cadena de un operador y devuelve una referencia a un objeto Toperator, del
//operando. Si no está definido el operador para este operando, devuelve nullOper.
begin
  Result := typ.FindOperator(oper);
end;
function TOperand.GetOperator: Toperator;
//Lee del contexto de entrada y toma un operador. Si no encuentra un operador, devuelve NIL.
//Si el operador encontrado no se aplica al operando, devuelve nullOper.
begin
  if cIn.tokType <> tkOperator then exit(nil);
  //hay un operador
  Result := typ.FindOperator(cIn.tok);
  cIn.Next;   //toma el token
end;
{Métodos de ayuda para implementar intérpretes}
function TOperand.ReadBool: boolean;
begin
  case catOp of
  coConst   : Result := valBool;
  coVariab: Result := rvar.valBool;
  coExpres  : Result := valBool;   //por norma, lo leemos de aquí.
  end;
end;
function TOperand.ReadInt: int64;
begin
  case catOp of
  coConst   : Result := valInt;
  coVariab: Result := rvar.valInt;
  coExpres  : Result := valInt;   //por norma, lo leemos de aquí.
  end;
end;
function TOperand.ReadFloat: extended;
begin
  case catOp of
  coConst   : Result := valFloat;
  coVariab: Result := rvar.valFloat;
  coExpres  : Result := valFloat;   //por norma, lo leemos de aquí.
  end;
end;
function TOperand.ReadStr: string;
begin
  case catOp of
  coConst   : Result := valStr;
  coVariab: Result := rvar.valStr;
  coExpres  : Result := valStr;   //por norma, lo leemos de aquí.
  end;
end;

end.
