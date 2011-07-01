//~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
//
// Unidad: HiloBusqueda.pas
//
// Prop�sito:
//    Implementa un descendiente de TThread que realiza una b�squeda de archivos dentro de una
//    carpeta y sus correspondientes subcarpetas.
//    Esta clase puede utilizarse directamente, como cualquier otro TThread, pero est� dise�ada
//    para ser usada desde el componentes TBuscador, definido en Buscador.pas
//
// Autor:          Salvador Jover (www.sjover.com) y JM (www.lawebdejm.com)
// Fecha:          01/07/2003
// Observaciones:  Unidad creada en Delphi 5
// Copyright:      Este c�digo es de dominio p�blico y se puede utilizar y/o mejorar siempre que
//                 SE HAGA REFERENCIA AL AUTOR ORIGINAL, ya sea a trav�s de estos comentarios
//                 o de cualquier otro modo.
//
//~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
unit HiloBusqueda;

interface

uses classes, windows;


type
   THiloBusqueda = class; // forward

   TOnEncontrado = procedure(sender: THiloBusqueda; ruta: string)   of object;
   TOnEnd        = procedure(sender: THiloBusqueda; total: integer) of object;


   THiloBusqueda = class(TThread)
   private
      FRuta:        string;    // ruta a buscar
      FSubcarpetas: boolean;

      FRutaEncontrado: string; // aux para pasar a m�todo sincronizado

      FOnEncontrado: TOnEncontrado;
      FOnEnd:        TOnEnd;

      function BuscarArchivos(const carpeta: string): integer;
      function BuscarSubcarpetas(const carpeta: string): integer;

      function GetTotalEncontrado: integer;

   protected
      procedure DoCallOnEncontrado;
      procedure CallOnEncontrado(const ruta: string);

      procedure CallOnEnd;

      function BuscarEnCarpeta(carpeta: string): integer; virtual;

      procedure Execute; override;   // M�todo execute de la clase TThread

   public
      constructor Create(const ARuta: string; const ASubcarpetas: boolean); reintroduce;

      property Ruta:        string  read FRuta;
      property Subcarpetas: boolean read FSubcarpetas;
      property TotalEncontrado: integer read GetTotalEncontrado;

      property OnEncontrado: TOnEncontrado read FOnEncontrado write FOnEncontrado;
      property OnEnd:        TOnEnd        read FOnEnd        write FOnEnd;
   end;


   TIteradorHilos = class;

   //
   // Clase auxiliar que define una lista de hilos
   //
   TListaHilos = class(TList)
   private
      function GetHilo(i: integer): THiloBusqueda;

   public
      function CreateIterator: TIteradorHilos;
      procedure ReleaseIterator(var it: TIteradorHilos);

      property Items[i: integer]: THilobusqueda read GetHilo; default;
   end;


   //
   // Un iterador para recorrer la lista de hilos
   //
   TIteradorHilos = class(TObject)
   private
      FListaHilos: TListaHilos;

      FIndex:   integer;

      function GetCurrent:  THiloBusqueda;
      function GetFirst:    THiloBusqueda;
      function GetLast:     THiloBusqueda;
      function GetNext:     THiloBusqueda;
      function GetPrevious: THiloBusqueda;

   public
      constructor Create(lista: TListaHilos);

      property Current:  THiloBusqueda read GetCurrent;
      property First:    THiloBusqueda read GetFirst;
      property Last:     THiloBusqueda read GetLast;
      property Next:     THiloBusqueda read GetNext;
      property Previous: THiloBusqueda read GetPrevious;
   end;


implementation


uses SysUtils;


//
// Se incluye un m�dulo donde se definen funciones para compatibilidad.
//
{$I ..\compatible.inc}



//
// TIteratorHilos
//


//  Proc/Fun     : constructor Create
//
//  Valor retorno: vac�o
//  Parametros   : lista: TListaHilos
//
//  Comentarios  : Contructor de la clase TIteradorHilos.
//                 Recae sobre esta clase la responsabilidad de recorrer la
//                 lista de hilos, y entregar al buscador una referencia a los
//                 mismos. Para esto dispone de los m�todos apropiados para
//                 avanzar secuencialmente, almacenando la posici�n actual en la
//                 variable FIndex.
//                 TIterador actua a traves de la clase TListaHilos
//
constructor TIteradorHilos.Create(lista: TListaHilos);
begin
   inherited Create;

   FListaHilos := lista;
   FIndex      := -1;
end;


//  Proc/Fun     : function GetCurrent
//
//  Valor retorno: THiloBusqueda
//  Parametros   : vac�o
//
//  Comentarios  : Obtener una referencia la hilo actual, indicado por el indice.
//                 Si se ha creado en ese momento la lista devuelve la posici�n
//                 neutra (-1) 'No hay selecci�n'
//
function TIteradorHilos.GetCurrent: THiloBusqueda;
begin
   if FIndex = -1 then
      result := nil
   else
      result := FListaHilos[FIndex];
end;


//  Proc/Fun     : function GetFirst
//
//  Valor retorno: THiloBusqueda
//  Parametros   : vacio
//
//  Comentarios  : Obtener una referencia al primer hilo de la lista.
//
function TIteradorHilos.GetFirst: THiloBusqueda;
begin
   FIndex := 0;
   result := GetCurrent;
end;


//  Proc/Fun     : function GetLast
//
//  Valor retorno: THiloBusqueda
//  Parametros   : vac�o
//
//  Comentarios  : Obtener una referencia al �ltimo hilo de la lista
//
function TIteradorHilos.GetLast: THiloBusqueda;
begin
   FIndex := FListaHilos.count - 1;
   result := GetCurrent;
end;


//  Proc/Fun     : function GetNext
//
//  Valor retorno: THiloBusqueda
//  Parametros   : vac�o
//
//  Comentarios  : Obtener una referencia al siguiente hilo de la lista. Se
//                 incrementar� FIndex
//
function TIteradorHilos.GetNext: THiloBusqueda;
begin
   Inc(FIndex);
   if (FIndex >= FListaHilos.count) then
      FIndex   := -1;

   result := GetCurrent;
end;


//  Proc/Fun     : function GetPrevious
//
//  Valor retorno: THiloBusqueda
//  Parametros   : vac�o
//
//  Comentarios  : Obtener una referencia al anterior hilo de la lista. Se
//                 decrementa FIndex.
//
function TIteradorHilos.GetPrevious: THiloBusqueda;
begin
   Dec(FIndex);
   result := GetCurrent;
end;



//
// TListaHilos
//


//  Proc/Fun     : function GetHilo
//
//  Valor retorno: THiloBusqueda
//  Parametros   : i: integer
//
//  Comentarios  : Metodo para la obtenci�n de la referencia al hilo. Es la
//                 propiedad de lectura del item de la lista y cuando se produce
//                 una asignaci�n es invocado.
//
function TListaHilos.GetHilo(i: integer): THiloBusqueda;
begin
   result := THiloBusqueda(inherited items[i]);
end;


//  Proc/Fun     : function CreateIterator
//
//  Valor retorno: TIteradorHilos
//  Parametros   : vac�o
//
//  Comentarios  :  M�todo de creaci�n del iterador. Obtenemos una referencia
//                  al mismo que nos permitir� finalmente destruirlo, cuando ya
//                  no nos es necesario.
//
function TListaHilos.CreateIterator: TIteradorHilos;
begin
   result := TIteradorHilos.Create(self);
end;


//  Proc/Fun     : procedure ReleaseIterator
//
//  Valor retorno: vac�o
//  Parametros   : var it: TIteradorHilos
//
//  Comentarios  : M�todo para la destrucci�n del iterador. TBuscador har� la
//                 invocaci�n necesaria con la referencia obtenida anteriormente
//                 en la funci�n creadora
//
procedure TListaHilos.ReleaseIterator(var it: TIteradorHilos);
begin
   it.Free;
   it := nil;
end;




//
// THiloBusqueda
//


//  Proc/Fun     : constructor Create
//
//  Valor retorno: vac�o
//  Parametros   : const ARuta: string; const ASubcarpetas: boolean
//
//  Comentarios  : Constructor del thread.
//
constructor THiloBusqueda.Create(const ARuta: string; const ASubcarpetas: boolean);
begin
   inherited Create(true);

   FRuta := ARuta;
   FSubcarpetas := ASubcarpetas;
end;


//  Proc/Fun     : procedure Execute
//
//  Valor retorno: vac�o
//  Parametros   : vac�o
//
//  Comentarios  : M�todo que sobrescribe Execute en el descendiente.
//                 Lanzamos el hilo de ejecuci�n y la exploraci�n de carpetas
//
procedure THiloBusqueda.Execute;
begin
   //
   // Iniciamos el �rbol de b�squedas
   //
   ReturnValue := BuscarEnCarpeta(FRuta);
   //Esta rutina no da problemas en delphi 5 pero en delphi 6 debe comentarse ya que
   //produce una excepci�n. En principio no resulta necesaria ya que est� asignado el
   //evento onTerminate
   //  Synchronize(CallOnEnd);
end;

//******************
//  Ver nota aclaratoria final sobre el algoritmo recursivo de busqueda
//  empleado.
//******************

//  Proc/Fun     : function BuscarEnCarpeta
//
//  Valor retorno: Integer
//  Parametros   : carpeta: string
//
//  Comentarios  : Primer paso del algoritmo recursivo de busqueda
//                 Ver explicaci�n adicional mas abajo.
//
function THiloBusqueda.BuscarEnCarpeta(carpeta: string): integer;
var
   ret: integer;
begin
   result := 0;

   //
   // primera vuelta para buscar los archivos en esta carpeta
   //
   ret := BuscarArchivos(PChar(carpeta));
   if ret = -1 then
   begin
      result := ret;
      exit;
   end
   else
      Inc(result, ret);

   //
   // segunda vuelta para buscar las subcarpetas de esta carpeta
   //
   if FSubcarpetas and (not Terminated) then
   begin
      ret := BuscarSubcarpetas(carpeta);
      if ret = -1 then
      begin
         result := ret;
         exit;
      end
      else
         Inc(result, ret);
   end;
end;


//  Proc/Fun     : function BuscarArchivos
//
//  Valor retorno: Integer
//  Parametros   : const carpeta: string
//
//  Comentarios  : Resuelve las coincidencias sobre la carpeta actual y lanza
//                 los enventos que resuelven los encuentros (coincidencia token
//                 y fichero explorado)
//
function THiloBusqueda.BuscarArchivos(const carpeta: string): integer;
var
   FindData:     WIN32_FIND_DATA;
   SearchHandle: THandle;
begin
   result := 0;

   SearchHandle := FindFirstFile(PChar(carpeta), FindData);
   if SearchHandle <> INVALID_HANDLE_VALUE then
   begin
      // Se itera en la carpeta actual
      repeat

         // si no es carpeta, es que lo ha encontrado
         if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0) then
         begin
            // encontrado
            FRutaEncontrado := ExtractFilePath(carpeta) + FindData.cFileName;
            Synchronize(DoCallOnEncontrado);

            Inc(result);
         end;

      until not FindNextFile(SearchHandle, FindData) or Terminated;

      // error en alg�n paso de la b�squeda
      if GetLastError <> ERROR_NO_MORE_FILES then
      begin
         result := -1;
      end;

      Windows.FindClose(SearchHandle);

   end
   else
      if GetLastError() = ERROR_FILE_NOT_FOUND then
         result := 0
      else
         result := -1;
end;


//  Proc/Fun     : function BuscarSubcarpetas
//
//  Valor retorno: Integer
//  Parametros   : const carpeta: string
//
//  Comentarios  : Segundo paso del algoritmo de busqueda. Busqueda de subcarpetas
//                 e invocaci�n del procedimiento inicial BuscarEnCarpeta, generando
//                 la recursividad y garantizando la exploraci�n de todo el arbor de
//                 directorios bajo la ruta indicada.
//
function THiloBusqueda.BuscarSubcarpetas(const carpeta: string): integer;
var
   FindData:     WIN32_FIND_DATA;
   SearchHandle: THandle;
   ret:          integer;
   mascara:      string;
   dir:          string;
begin
   result := 0;

   mascara := '\' + ExtractFileName(carpeta);
   dir     := ExtractFilePath(carpeta);
   dir     := IncludeTrailingBackSlash(dir) + '*.*';

   SearchHandle := FindFirstFile(PChar(dir), FindData);
   if SearchHandle <> INVALID_HANDLE_VALUE then
   begin
      // Se itera en la carpeta actual
      repeat

         // si es carpeta, hay que llamar recursivamente
         if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and
            (FindData.cFileName[0] <> '.')  then
         begin
            dir := ExtractFilePath(carpeta);
            dir := IncludeTrailingBackSlash(dir) + FindData.cFileName + mascara;

            ret := BuscarEnCarpeta(dir);
            if ret = -1 then
               result := -1
            else
               Inc(result, ret);
         end;

      until (not FindNextFile(SearchHandle, FindData)) or Terminated or (result = -1);

      // error en alg�n paso de la b�squeda
      if GetLastError <> ERROR_NO_MORE_FILES then
      begin
         result := -1;
      end;

      Windows.FindClose(SearchHandle);

   end
   else
      if GetLastError() = ERROR_FILE_NOT_FOUND then
         result := 0
      else
         result := -1;
end;


//  Proc/Fun     : procedure DoCallOnEncontrado
//
//  Valor retorno: vac�o
//  Parametros   : vac�o
//
//  Comentarios  :  Este m�todo es invocado cada vez que es encontrada una coincidencia
//                  token - archivo, desencadenando en su invocaci�n el evento OnEncontrado
//                  del que se sirve el componente buscador para su comunicacion. Esto es,
//                  nos valemos del metodo en una comunicaci�n desde el hilo hacia el
//                  buscador, para que �ste, tras hacer lo que crea conveniente, genere la
//                  comunicaci�n a la aplicaci�n usuaria
//
procedure THiloBusqueda.DoCallOnEncontrado;
begin
   CallOnEncontrado(FRutaEncontrado);
end;


//  Proc/Fun     : procedure CallOnEncontrado
//
//  Valor retorno: vac�o
//  Parametros   : const ruta: string
//
//  Comentarios  : Evento de comunicaci�n entre THiloBusqueda y nuestro buscador
//
procedure THiloBusqueda.CallOnEncontrado(const ruta: string);
begin
   if Assigned(FOnEncontrado) and not Terminated then
      FOnEncontrado(self, ruta);
end;


//  Proc/Fun     : procedure CallOnEnd
//
//  Valor retorno: vac�o
//  Parametros   : vac�o
//
//  Comentarios  :  Se persiguen los mismo objetivos que en nuestro m�todo y
//                  evento anterior
//                  Se establece una comunicaci�n THiloBusqueda -> Buscador para
//                  que este la pueda establecer hacia la aplicaci�n usuaria
//
procedure THiloBusqueda.CallOnEnd;
begin
   if Assigned(FOnEnd) and not Terminated then
      FOnEnd(self, ReturnValue);
end;


//  Proc/Fun     : function GetTotalEncontrado
//
//  Valor retorno: Integer
//  Parametros   : Vacio
//
//  Comentarios  : Procedimiento de lectura del total de encontrados
//
function THiloBusqueda.GetTotalEncontrado: integer;
begin
   result := ReturnValue;
end;


{
//*****************
     NOTA ACLARATORIA:
        Esta nota es un peque�o estracto del art�culo "TThread VI: Un buscador
        de Archivos (y II)" de quien escribe estas lineas y publicado en S�ntesis
        en su n�mero 16, y que explican brevemente el algoritmo dise�ado por
        Jose Manuel Navarro.
//*****************
...
Vamos a suponer que deseamos iniciar una b�squeda cualquiera. En ocasiones
resultar�a interesante crear tres o cuatro carpetas y un par de archivos en
el interior de ellas para simular �sta, y hacer un seguimiento desde Delphi,
paso por paso, en la exploraci�n de este peque�o �rbol. Yo lo he hecho as�.
Puse un punto de parada justo en la linea que invoca Execute, y voy avanzando
paso a paso mediante la pulsaci�n de F7, siguiendo en un la ventana de c�digo
el valor de algunas de las variables. Supongamos que lo hacemos as�:

procedure TJMBuscador.Execute;
begin
   fCountRes:= 0;
   if FRutas.count = 0 then
   	raise ESinRutas.Create('No hay rutas de b�squeda configuradas.');

   if FEstado in [ebPausado, ebBuscando] then
   	raise EBuscando.Create('La b�squeda ya est� activa.');

   FEstado := ebPausado;
   FResultado.Clear;

   CrearBusquedas;

   Pausado := false;
end;

fCountRes representa al total de coincidencias encontradas por el buscador. Tras
inicializar este valor, y comprobar que existen rutas asignadas y que el componente
no se haya ya en estado de b�squeda o pausado, inicializa tambi�n la lista de
resultados y procede a crear cada uno de los hilos necesarios en CrearBusquedas.
Hecho esto, puede activar la ejecuci�n del buscador. Un detalle que puede resultar
de inter�s para los compa�eros que se inician, es observar como la misma propiedad,
nos puede ayudar  a desencadenar acciones a trav�s de su escritura.

   FEstado := ebPausado;
   ...
   Pausado := false;

Juega Jose Manuel modificando directamente el valor de la variable fEstado,
que almacena el estado real del buscador, mientras que en un momento posterior,
lineas mas abajo, lo hace invocando a la propiedad Pausado, que no solo incidir�
sobre la misma variable, sino que, como efecto colateral y tras varias rutinas
de c�digo, invocara finalmente al m�todo Resume de cada uno de los hilos.
Nos podemos adelantar al momento en que se inicia la ejecuci�n de uno de los
hilos creados en CrearBusquedas, y lanzados tras la asignaci�n de Pausado a false.
El m�todo Execute del hilo consta b�sicamente de una sola linea de c�digo:

   ReturnValue := BuscarEnCarpeta(FRuta);

Esto nos lleva a comentar el primer punto clave del desarrollo del algoritmo.
La invocaci�n de BuscarEnCarpeta( ) para inicializar la b�squeda en un nuevo
directorio. En este punto se inicia una nueva b�squeda, y como ya os deb�is
imaginar, ser� esta misma rutina la que llamada posteriormente y desde otro
tramo de c�digo genere la recursividad.

function TJMHiloBusqueda.BuscarEnCarpeta(carpeta: string): integer;
var
	ret: integer;
begin
	result := 0;

   //
   // primera vuelta para buscar los archivos en esta carpeta
   //
   ret := BuscarArchivos(PChar(carpeta));
   if ret = -1 then
   begin
   	result := ret;
     exit;
   end
   else
   	Inc(result, ret);

   //
   // segunda vuelta para buscar las subcarpetas de esta carpeta
   //
   if FSubcarpetas and (not Terminated) then
   begin
	   ret := BuscarSubcarpetas(carpeta);
      if ret = -1 then
      begin
      	result := ret;
        exit;
      end
      else
      	Inc(result, ret);
   end;
end;

Podemos subdividir la implementaci�n de este procedimiento en dos fases
diferenciadas, de la misma forma que ya hemos hecho anteriormente: La fase de
b�squeda de coincidencias en la carpeta actual y una segunda fase, que Jose Manuel
denomina �segunda vuelta...� en esos comentarios de c�digo y cuyo punto central
es la invocaci�n de BuscarSubcarpetas. L�gicamente, solo se entrar� en esta fase
si fSubcarpetas tiene valor verdadero, si queremos explorar las subcarpetas y si
el hilo no ha sido finalizado prematuramente (not Terminate).
Veamos que pasa en el interior del m�todo BuscarSubcarpeta. Prescindimos de
aquellos trozos de c�digo que resultan mas accesorios. Remarco en otro color la
llamada a BuscarEnCarpeta:

function TJMHiloBusqueda.BuscarSubcarpetas(const carpeta: string): integer;
var
   FindData:     WIN32_FIND_DATA;
   SearchHandle: THandle;
   ret: 			  integer;
   mascara:      string;
   dir:          string;
begin
   result := 0;

   mascara := '\' + ExtractFileName(carpeta);
   dir     := ExtractFilePath(carpeta);
   dir     := IncludeTrailingBackSlash(dir) + '*.*';

   SearchHandle := FindFirstFile(PChar(dir), FindData);
   if SearchHandle <> INVALID_HANDLE_VALUE then
   begin
      // Se itera en la carpeta actual
      repeat

         // si es carpeta, hay que llamar recursivamente
         if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and
            (FindData.cFileName[0] <> '.')  then
         begin
			   dir := ExtractFilePath(carpeta);
            dir := IncludeTrailingBackSlash(dir) + FindData.cFileName + mascara;

            ret := BuscarEnCarpeta(dir);
            if ret = -1 then
               result := -1
            else
               Inc(result, ret);
         end;

      until (not FindNextFile(SearchHandle, FindData)) or Terminated or (result = -1);

   ...
   ...

end;

Nos quedamos con los dos puntos claves de la implementaci�n. El primero es la
obtenci�n de la nueva ruta y que se representa en el par�metro dir, remarcado
en color naranja. El segundo punto clave es la llamada a BuscarEnCarpeta una vez
que se ha modificado anteriormente la variable dir con los valores correctos.
El bucle repeat ... until, que encierra este c�digo, garantiza que la exploraci�n
se va hacer para cada uno de los directorios que componen la carpeta actual.
Si este ciclo, tal y como lo hemos contado, lo trasladamos al interior de cada
uno de los directorios encontrados, garantizamos que la b�squeda se va a mantener
mientras quede alguna carpeta por explorar, recorriendo en profundidad todo el
�rbol de directorios
...
}

end.
