{
XpresTypes
==========
Por Tito Hinostroza.

Definiciones básicas para el manejo de expresiones.
Aquí están definidas los objetos claves para el manejo de expresiones:
Los tipos, los operadores y las operaciones
}
unit XpresTypes;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, fgl;

type  //tipos enumerados

  //categorías básicas de tipo de datos
  TCatType=(
    t_integer,  //números enteros
    t_uinteger, //enteros sin signo
    t_float,    //de coma flotante
    t_string,   //cadena de caracteres
    t_boolean,  //booleano
    t_enum      //enumerado
  );

  {Espacio para almacenar a los posibles valores de una constante.
  Debe tener campos para los tipos básicos de variable haya en "TCatType" y para valores
  estructurados}
  TConsValue = record
    ValInt  : Int64;    //Para alojar a los valores t_integer y t_uinteger
    ValFloat: extended; //Para alojar a los valores t_float
    ValBool : boolean;  //Para alojar a los valores t_boolean
    ValStr  : string;   //Para alojar a los valores t_string
  end;

  //Categoría de Operando
  TCatOperan = (
    coConst =%00,  //Constante. Inlcuyendo expresiones de constantes evaluadas.
    coVariab=%01,  //Variable. Variable única.
    coExpres=%10   //Expresión. Algo que requiere cálculo (incluyendo a una función).
  );
  {Categoría de operación. Se construye para poder representar dos valores de TCatOperan
   en una solo valor byte (juntando sus bits), para facilitar el uso de un CASE ... OF}
  TCatOperation =(
    coConst_Const=  %0000,
    coConst_Variab= %0001,
    coConst_Expres= %0010,
    coVariab_Const= %0100,
    coVariab_Variab=%0101,
    coVariab_Expres=%0110,
    coExpres_Const= %1000,
    coExpres_Variab=%1001,
    coExpres_Expres=%1010
  );

  TType = class;

  //Eventos
  TProcExecOperat = procedure of object;
  TProcDefineVar = procedure(const varName, varInitVal: string) of object;
  {Evento para cargar un  operando en la pila.
  "OpPtr" debería ser "TOperand", pero aún no se define "TOperand".}
  TProcLoadOperand = procedure(const OpPtr: pointer) of object;

  //Tipo operación
  TxpOperation = class
    OperatType : TType;   //tipo de Operando sobre el cual se aplica la operación.
    proc       : TProcExecOperat;  //Procesamiento de la operación
  end;

  TxpOperations = specialize TFPGObjectList<TxpOperation>; //lista de operaciones

  { TxpOperator }
  //Operador
  TxpOperator = class
    txt: string;    //cadena del operador '+', '-', '++', ...
    pre: byte;      //precedencia
    nom: string;    //nombre de la operación (suma, resta)
    idx: integer;   //ubicación dentro de un arreglo
    Operation: TProcExecOperat;  {Operación asociada al Operador. Usado cuando es un
                                 operador unario. NO IMPLEMENTADO.}
    Operations: TxpOperations;  //operaciones soportadas. Debería haber tantos como
                              //Num. Operadores * Num.Tipos compatibles.
    function CreateOperation(OperadType: TType; proc: TProcExecOperat): TxpOperation;  //Crea operación
    function FindOperation(typ0: TType): TxpOperation;  //Busca una operación para este operador
    constructor Create;
    destructor Destroy; override;
  end;

  TxpOperators = specialize TFPGObjectList<TxpOperator>; //lista de operadores

  { TType }
  //"Tipos de datos"
  TType = class
    name : string;      //nombre del tipo ("int8", "int16", ...)
    cat  : TCatType;    //categoría del tipo (numérico, cadena, etc)
    size : smallint;    //tamaño en bytes del tipo
    idx  : smallint;    //ubicación dentro de la matriz de tipos
    OperationLoad: TProcExecOperat; {Evento. Es llamado cuando se pide evaluar una
                                 expresión de un solo operando de este tipo. Es un caso
                                 especial que debe ser tratado por la implementación}
    OnGlobalDef: TProcDefineVar; {Evento. Es llamado cada vez que se encuentra la
                                  declaración de una variable (de este tipo) en el ámbito global.}
    OnLocalDef: TProcDefineVar;  {Evento. Es llamado cada vez que se encuentra la
                                  declaración de una variable (de este tipo) en un ámbito local.}
    OnPush  : TProcLoadOperand; {Evento. Es llamado cuando se pide cargar un operando
                                 (de este tipo) en la pila. }
    OnPop   : TProcLoadOperand; {Evento. Es llamado cuando se pide cargar un operando
                                 (de este tipo) en la pila. }
    Operators: TxpOperators;      //operadores soportados
    function CreateOperator(txt0: string; jer0: byte; name0: string): TxpOperator; //Crea operador
    function FindOperator(const Opr: string): TxpOperator;  //indica si el operador está definido
    constructor Create;
    destructor Destroy; override;
  end;

  //Lista de tipos
  TTypes = specialize TFPGObjectList<TType>; //lista de bloques

var
  nullOper : TxpOperator; //Operador nulo. Usado como valor cero.

implementation

{function TCompilerBase.CategName(cat: TCatType): string;
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
end;}

{ TxpOperator }
function TxpOperator.CreateOperation(OperadType: TType; proc: TProcExecOperat
  ): TxpOperation;
var
  r: TxpOperation;
begin
  //agrega
  r := TxpOperation.Create;
  r.OperatType:=OperadType;
  r.proc:=proc;
  //agrega
  operations.Add(r);
  Result := r;
end;
function TxpOperator.FindOperation(typ0: TType): TxpOperation;
{Busca, si encuentra definida, alguna operación, de este operador con el tipo indicado.
Si no lo encuentra devuelve NIL}
var
  r: TxpOperation;
begin
  Result := nil;
  for r in Operations do begin
    if r.OperatType = typ0 then begin
      exit(r);
    end;
  end;
end;
constructor TxpOperator.Create;
begin
  Operations := TxpOperations.Create(true);
end;
destructor TxpOperator.Destroy;
begin
  Operations.Free;
  inherited Destroy;
end;

{ TxpType }
function TType.CreateOperator(txt0: string; jer0: byte; name0: string): TxpOperator;
{Permite crear un nuevo ooperador soportado por este tipo de datos. Si hubo error,
devuelve NIL. En caso normal devuelve una referencia al operador creado}
var
  r: TxpOperator;  //operador
begin
  //verifica nombre
  if FindOperator(txt0)<>nullOper then begin
    Result := nil;  //indica que hubo error
    exit;
  end;
  //inicia
  r := TxpOperator.Create;
  r.txt:=txt0;
  r.pre:=jer0;
  r.nom:=name0;
  r.idx:=Operators.Count;
  //agrega
  Operators.Add(r);
  Result := r;
end;
function TType.FindOperator(const Opr: string): TxpOperator;
//Recibe la cadena de un operador y devuelve una referencia a un objeto TxpOperator, del
//tipo. Si no está definido el operador para este tipo, devuelve nullOper.
var
  i: Integer;
begin
  Result := nullOper;   //valor por defecto
  for i:=0 to Operators.Count-1 do begin
    if Operators[i].txt = upCase(Opr) then begin
      exit(Operators[i]); //está definido
    end;
  end;
  //no encontró
  Result.txt := Opr;    //para que sepa el operador leído
end;
constructor TType.Create;
begin
  Operators := TxpOperators.Create(true);  //crea contenedor de Contextos, con control de objetos.
end;
destructor TType.Destroy;
begin
  Operators.Free;
  inherited Destroy;
end;

initialization
  //crea el operador NULL
  nullOper := TxpOperator.Create;

finalization
  nullOper.Free;

end.

