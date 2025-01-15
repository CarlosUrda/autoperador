/*
    @module error.ahk

    @description Gestión de los errores

    @requires Recordatorio de excepciones que lanza ahk ante eventos:
        - MethodError:
            - Si objeto carece de método ToString al llamarlo en String
        
        - TypeError:
            - Si un objeto a recorrer en un bucle no es Enumerator, no tiene función __Enum o ésta no devuelve un Enumerator.
            
    @todo Solucionar el tener que pasar el número de línea en cada llamada a Err_Lanzar porque al asignarlo como valor por defecto toma el valor de la línea de la función Err_Lanzar, mientras que en el caso del nombre de la función sí toma como valor por defecto la función que le llama (aunque no es seguro que esto último lo vaya a hacer siempre)
*/


#Requires AutoHotkey v2.0


if (!IsSet(__ERR_H__)) {
    global __ERR_H__ := true

    /*
        @global NULL {String} - En ahk una cadena vacía se usa como null o valor indefinido.
    */
    global NULL := ""


    /*
        Tipos de errores con su código correspondiente y acciones a realizar para cada uno de ellos.

        NULL: No existe el código de error o se deconoce.
    */
    global ERR_ERRORES := Map("NULL", 0, "CORRECTO", 1, "ERR_ERROR", -1, "ERR_VALOR", -2, "ERR_ARG", -3, "ERR_ARCHIVO", -4, "ERR_OBJETO", -5, "ERR_TIPO", -6, "ERR_INDICE", -7, "ERR_FUNCION", -8, "ERR_NUM_ARGS", -9)
    global ERR_ACCIONES := Map("NULL", NULL, "CONTINUAR", 1, "PARAR_FUNCION", 2, "PARAR_PROGRAMA", 3)
    global ERR_INFO_CODIGOS := Map(
        ERR_ERRORES["NULL"], Map("nombre", "NULL", "accion", ERR_ACCIONES["NULL"], "mensaje", NULL),
        ERR_ERRORES["CORRECTO"], Map("nombre", "CORRECTO", "accion", ERR_ACCIONES["CONTINUAR"], "mensaje", "Ejecución realizada correcta"),
        ERR_ERRORES["ERR_ERROR"], Map("nombre", "ERR_ERROR", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error"),
        ERR_ERRORES["ERR_VALOR"], Map("nombre", "ERR_VALOR", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Valor erróneo"),
        ERR_ERRORES["ERR_ARG"], Map("nombre", "ERR_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Argumento erróneo"),
        ERR_ERRORES["ERR_ARCHIVO"], Map("nombre", "ERR_ARCHIVO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al gestionar un archivo"),
        ERR_ERRORES["ERR_OBJETO"], Map("nombre", "ERR_OBJETO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al crear un objeto"),
        ERR_ERRORES["ERR_TIPO"], Map("nombre", "ERR_TIPO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato erróneo"),
        ERR_ERRORES["ERR_INDICE"], Map("nombre", "ERR_INDICE", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Índice o clave errónea"),
        ERR_ERRORES["ERR_FUNCION"], Map("nombre", "ERR_FUNCION", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función"),
        ERR_ERRORES["ERR_NUM_ARGS"], Map("nombre", "ERR_NUM_ARGS", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Número incorrecto de argumentos pasados")
    )
    global ERR_FUNCION_ORIGEN := Map("ACTUAL", -1, "LLAMANTE", -2)  ; Errores establecidos en la documentación oficial

    /*
        @function Err_Lanzar
        @description Encapsular el lanzamiento de excepciones para lanzarlas con contenido personalizado.

        @param {Clase Error\Error} exepcion - Clase Error con el tipo de la nueva excepción a lanzar u objeto Error con la excepción a relanzar agregando información.
        @param {String} mensaje - Mensaje como primer argumento de la excepción lanzada
        @param {Integer} codigoError - Código del tipo de error ocurrido de entre los valores de ERR_ERRORES.
        @param {Integer} linea - Número de línea donde ocurre el error 
        @param {String} funcion - Nombre de la función donde ocurre la excepción
        @param {String} script - Nombre del script desde donde se lanza el error. Por defecto se toma la ruta completa.
        @param {String} fecha - Fecha del momento del error.

        @throws {TypeError} - Si alguno de los argumentos tiene un tipo incorrecto.

        @todo A_LineNumber como valor por defecto del argumento línea no guarda el número de línea de la llamada a esta función, sino el número de línea de la cabecera _Err_Lanzar. Para el nombre de la función y el script sí asigna el de los llamantes.
    */
    _Err_Lanzar(excepcion, mensaje, codigoError := "", linea := A_LineNumber, funcion := A_ThisFunc, script := A_ScriptFullPath, fecha := FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:")) {
        try {
            nombreArchivo := RegExReplace(String(script), ".*[\\/]", "")
            codigoError := String(codigoError)
            linea := String(linea)
            funcion := String(funcion)
            fecha := String(fecha)
        }
        catch  {
            excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") Los argumentos con información sobre el error deben ser String (o convertible a String).", ERR_FUNCION_ORIGEN["ACTUAL"], FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
        }
        else if excepcion is Class
            if !(excepcion.Prototype is Error)
                excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") El tipo de excepción a lanzar no es clase Error.", ERR_FUNCION_ORIGEN["ACTUAL"], FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
            else
                excepcion := excepcion("(" codigoError ") " mensaje, ERR_FUNCION_ORIGEN["LLAMANTE"], fecha ":" funcion " (L " linea ") [" nombreArchivo "]")
        else if !(excepcion is Error)
            excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") El objeto excepción a relanzar no es tipo Error.", -1, FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
        else {
            excepcion.Message .= " (" codigoError ") " mensaje
            excepcion.Extra .= "`r`n" fecha ":" funcion " (L " linea ") [" nombreArchivo "]"
        }

        throw excepcion
    } 
    
    ; Se añade Err_Lanzar como método a Error
    Error.Prototype.DefineProp("Lanzar", {Call: _Err_Lanzar})
    global Err_Lanzar := _Err_Lanzar


    /*
        @function ErrMsgBox
        
        @description Mostar un mensaje MsgBox con la información de una excepcion

        @param {Error} e - Objeto clase Error con la información de la excepción.
    */
    global Err_MsgBox := e => MsgBox(e.What " - " e.Message, "ERROR " e.Extra ": " ERR_INFO_CODIGOS[e.Extra]["nombre"] " - " ERR_INFO_CODIGOS[e.Extra]["mensaje"])

    ; Se añade Err_MsgBox como método a Error
    Error.Prototype.DefineProp("MsgBox", {Call: Err_MsgBox})


    /*
        @function Err_ClonarError

        @description Clonar el contenido de un objeto Error (o extendiendo a Error) a otro objeto de otro tipo Error

        @param {Error} objErrorOrigen - Objeto Error que será clonado.
        @param {Class} tipoErrorDestino - Tipo de Error que será el nuevo objeto clonado. Si no está definido se clona el objeto origen directamente.

        @returns {Error} - Objeto clonado de tipo Error.
    */  
    _Err_Clonar(objOrigen, tipoDestino?) {
        if !IsSet(tipoDestino)
            return objOrigen.Clone()

        if !(objOrigen is Error) or !(tipoDestino is Class) or !(tipoDestino.Prototype is Error)
            Err_Lanzar(TypeError, "Los argumentos deben ser de tipo Error", ERR_ERRORES["ERR_ARG"])

        try
            _enum := Err_VerificarEnumerator(objOrigen, 2)
        catch as e
            Err_Lanzar(e, "La lista no se admite como un Enumerator válido")

        /* No sé si usar OwnProps */
        try {
            objDestino := tipoDestino(objOrigen.Message)
            objDestino.What := objOrigen.What
            objDestino.Extra := objOrigen.Extra
            objDestino.File := objOrigen.File
            objDestino.Line := objOrigen.Line
            objDestino.Stack := objOrigen.Stack
        }
        catch as e
            Err_Lanzar(MemoryError, "No se ha podido clonar el objeto al nuevo obk")

        return objOrigen
    }

    ; Se añade Err_Clonar como método a Error
    Error.Prototype.DefineProp("Clonar", {Call: _Err_Clonar})
    global Err_Clonar := _Err_Clonar


    /*
        @function Err_EsFuncion

        @description Comprobar si un objeto es o actúa como una función: es llamable.

        @param {Any} f - Objeto a comprobar.

        @returns true o false si es o no llamable.
    */
    Err_EsFuncion := f => f is Func or f.HasMethod("Call")


    /*
        @function Err_AdmiteNumArgs

        @description Comprobar si una función admite un número de argumentos.

        @param {Func} funcion - Función a comprobar.
        @param {Func} numArgs - Número de argumentos a comprobar.

        @throws {TypeError} - Si función no es llamable.

        @returns true o false.
    */
    _Err_AdmiteNumArgs(funcion, numArgs) {
        if !(funcion is Func)
            if funcion.HasMethod("Call")
                funcion := funcion.Call
            else
                Err_Lanzar(TypeError, "La función no es llamable", ERR_ERRORES["ERR_ARG"])
        
        return funcion.MaxParams >= numArgs and funcion.MinParams <= numArgs
    }

    ; Se añade como método a Map, Array y Enumerator
    Func.Prototype.DefineProp("AdmiteNumArgs", {Call: _Err_AdmiteNumArgs})
    global Err_AdmiteNumArgs := _Err_AdmiteNumArgs

    
    /*
        @function Err_VerificarEnumerator

        @description Comprobar que un objeto puede pasar como Enumerator siendo de tipo Func, teniendo un método Call, o un método __Enum que devuelva un Enumerator.
        En caso de obtener el Enumerator a patrir de __Enum, existe la posibilidad de que el número máximo de argumentos que admita dicho Enumerator quede definido por el valor de numArgs usado al llamar a __Enum.

        @param {Enumerator|Object<__Enum>} enum - Enumerator a comprobar.
        @param {Integer} numArgs - Número de argumentos que debe admitir el Enumerator.

        @returns Enumerator obtenido a partir de enum

        @throws {TypeError} - Si el argumento enum no es Enumerator, no tiene un método Call ni __Enum o éste último método no devuelve un Enumerator.
        @throws {ErrorNumArgumentos} - SI el Enumerator no admite como número de argumentos o no es número válido (entero >= 0).

        @todo Comprobar que el enumerator no va a ejecutar ningún tipo de código malicioso.
    */
    _Err_VerificarEnumerator(enum, numArgs) {
        if !IsInteger(numArgs) or (numArgs := Integer(numArgs) < 0)
            Err_Lanzar(ErrorNumArgumentos, "El número de argumentos debe de ser un entero >= 0", ERR_ERRORES["ERR_ARG"])

        try {
            admiteNumArgs := Err_AdmiteNumArgs(enum, numArgs)
        }
        catch TypeError {
            if enum.HasMethod("__Enum") {
                try
                    enum := enum.__Enum(numArgs)
                catch as e {
                    e := ;   ***** Clonar ErrNumArgs *****
                    Err_Lanzar(e, "El Enumerator a obtener de __Enum no admite " String(numArgs) " argumentos", ERR_ERRORES["ERR_NUM_ARGS"])
                }

                try
                    admiteNumArgs := Err_AdmiteNumArgs(enum, numArgs)
                catch TypeError as es
                    Err_Lanzar(e, "El método __Enum no devuelve un Enumerator")
            else
                Err_Lanzar(TypeError, "Argumento enum no es Enumeratior ni tiene __Enum", ERR_ERRORES["ERR_ARG"])
            }
        }
       
        if !admiteNumArgs
            Err_Lanzar(ErrorNumArgumentos, "El enumerator de enum no admite el número de argumentos", ERR_ERRORES["ERR_NUM_ARGS"])

        /* Aquí se comprobaría si la ejecución del Enumerator es maliciosa, pero sin ejecutarlo porque entonces ya no se podría reutilizar */       

        return enum
    }

    global Err_VerificarEnumerator := _Err_VerificarEnumerator

    
    /* Excepciones personalizadas */

    class ErrorNumArgumentos extends Error { 
    }

    class ErrorFuncion extends Error {
    }

    class ErrorEnumerator extends Error {
    }

    class ObjetoError extends Error {
    }
}   