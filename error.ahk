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
    global ERR_ERRORES := Map("NULL", 0, "CORRECTO", 1, "ERR_ERROR", -1, "ERR_ARG", -2, "ERR_VALOR", -3, "ERR_VALOR_ARG", -4, "ERR_TIPO", -5, "ERR_TIPO_ARG", -6, "ERR_ARCHIVO", -7, "ERR_OBJETO", -8, "ERR_INDICE", -9, "ERR_FUNCION", -10, "ERR_NUM_ARGS", -11)
    global ERR_ACCIONES := Map("NULL", NULL, "CONTINUAR", 1, "PARAR_FUNCION", 2, "PARAR_PROGRAMA", 3)
    global ERR_INFO_CODIGOS := Map(
        ERR_ERRORES["NULL"], Map("nombre", "NULL", "accion", ERR_ACCIONES["NULL"], "mensaje", NULL),
        ERR_ERRORES["CORRECTO"], Map("nombre", "CORRECTO", "accion", ERR_ACCIONES["CONTINUAR"], "mensaje", "Ejecución realizada correcta"),
        ERR_ERRORES["ERR_ERROR"], Map("nombre", "ERR_ERROR", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error"),
        ERR_ERRORES["ERR_ARG"], Map("nombre", "ERR_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Argumento erróneo"),
        ERR_ERRORES["ERR_VALOR"], Map("nombre", "ERR_VALOR", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Valor erróneo"),
        ERR_ERRORES["ERR_VALOR_ARG"], Map("nombre", "ERR_VALOR_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Valor de argumento erróneo"),
        ERR_ERRORES["ERR_TIPO"], Map("nombre", "ERR_TIPO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato erróneo"),
        ERR_ERRORES["ERR_TIPO_ARG"], Map("nombre", "ERR_TIPO_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato de argumento erróneo"),
        ERR_ERRORES["ERR_ARCHIVO"], Map("nombre", "ERR_ARCHIVO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al gestionar un archivo"),
        ERR_ERRORES["ERR_OBJETO"], Map("nombre", "ERR_OBJETO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al crear un objeto"),
        ERR_ERRORES["ERR_INDICE"], Map("nombre", "ERR_INDICE", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Índice o clave errónea"),
        ERR_ERRORES["ERR_FUNCION"], Map("nombre", "ERR_FUNCION", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función"),
        ERR_ERRORES["ERR_NUM_ARGS"], Map("nombre", "ERR_NUM_ARGS", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Número incorrecto de argumentos pasados")
    )
    global ERR_FUNCION_ORIGEN := Map("ACTUAL", -1, "LLAMANTE", -2)  ; Errores establecidos en la documentación oficial


    /*
        @function Err_ExtenderInfo
        @description Añadir información a la ya existente en una excepción. Simplemente concatena la información pasada a cada campo de la excepción correspondiente. Si una 

        @param {Error} excepcion - Objeto Error con la excepción a ampliar su información.
        @param {Map} props - Diccionario con un valor por cada propiedad que desea ser ampliado.

        @throws {TypeError} - Si alguno de los argumentos tiene un tipo incorrecto.
    */
    _Err_ExtenderInfoM(excepcion, props) {
        if !(props is Map)
            throw Err_TipoArgError("Las propiedades deben estar en un diccionario", , , ERR_ERRORES["ERR_TIPO_ARG"], , "props", Type(props))

        try {
            _enum := Err_VerificarEnumerator(props, 2)
        }
        catch e
            throw e

        for prop, valor in props {
            try {
                if !excepcion.HasProp(prop)
                    continue
            }
            catch
                ; Si salta una excepción al saber si tiene la propiedad

            try {
                excepcion.%prop% .= " " String(valor)
            }
            catch as e {
                throw Err_ValorArgError("")
            }
        }

        try {
            nombreArchivo := RegExReplace(String(script), ".*[\\/]", "")
            codigoError := String(codigoError)
            FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:")
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
    
    _Err_ExtenderInfo(excepcion, props) {
        if !(excepcion is Error)
            throw Err_TipoArgError("El objeto pasado no es una excepción Error", , , ERR_ERRORES["ERR_TIPO_ARG"], , "props", Type(props))

        return _Err_ExtenderInfoM(excepcion, props)
    }

    ; Se añade Err_Lanzar como método a Error
    Error.Prototype.DefineProp("ExtenderInfo", {Call: _Err_ExtenderInfoM})
    global Err_ExtenderInfo := _Err_ExtenderInfo


    /*
        @function ErrMsgBox
        
        @description Mostar un mensaje MsgBox con la información de una excepcion

        @param {Error} e - Objeto clase Error con la información de la excepción.
    */
    global Err_MsgBox := e => MsgBox(String(e), )
    excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") El tipo de excepción a lanzar no es clase Error.", ERR_FUNCION_ORIGEN["ACTUAL"], FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
    nombreArchivo := RegExReplace(String(script), ".*[\\/]", "")

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

    /*
        @class Err_Error

        @description Error padre del que heredan todos los errores personalizados Err_
    */
    class Err_Error extends Error {
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_ERROR"], fecha := A_Now) {
            super.__New(mensaje, what, extra)

            try {
                this.Codigo := String(codigo)
                this.Fecha := String(fecha)
            }
            catch {
                throw TypeError("(" ERR_ERRORES["ERR_TIPO_ARG"] ") Los argumentos deben ser String (o convertible a String).")
            }

            if FormatTime(this.Fecha) == ""
                throw ValueError("(" ERR_ERRORES["ERR_TIPO_ARG"] ") La fecha no está en formato YYYYMMDDHH24MISS")
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
            @param {Boolean} extra - Si true, se añade la información de la propiedad Extra.
        */
        ToString(texto := "", extra := false) {
            return "[" FormatTime(this.Fecha, "dd/MM/yyyy HH:mm:ss] (") String(this.Codigo) ") " String(this.Mensaje) " " String(texto) (Boolean(extra) ?  "'r'n" String(this.Extra) : "")
        }
    }

    /*
        @class ErrorArgumento

        @decription Errores relacionados con los argumentos recibidos en la función o método donde ocurre el error.
    */
    class Err_ArgError extends Err_Error { 
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
        */
        __New(mensaje, what?, extra?, codigo?, fecha?, nombreArg?) {
            super.__New(mensaje, what, extra, codigo, fecha)

            try {
                this.NombreArg := String(nombreArg ?? "")
            }
            catch {
                throw TypeError("(" ERR_ERRORES["ERR_TIPO_ARG"] ") El argumento nombreArg debe ser String (o convertible a String)")
            }
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
            @param {Boolean} extra - Si true, se añade la información de la propiedad Extra.
        */
        ToString(texto := "", extra := false) {
            return super.ToString("- Arg: " this.nombreArg " " texto, extra)
        }
        
    }

    class Err_TipoArgError extends Err_ArgError {
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
        */
        __New(mensaje, what?, extra?, codigo?, fecha?, nombreArg?, tipoArg?) {
            super.__New(mensaje, what, extra, codigo, fecha, nombreArg)

            try {
                this.tipoArg := String(tipoArg ?? "")
            }
            catch {
                throw TypeError("(" ERR_ERRORES["ERR_TIPO_ARG"] ") El argumento tipoArg debe ser String (o convertible a String)")
            }
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
            @param {Boolean} extra - Si true, se añade la información de la propiedad Extra.
        */
        ToString(texto := "", extra := false) {
            return super.ToString("- Tipo: " this.tipoArg " " texto, extra)
        }
    }

    class Err_ValorArgError extends Err_ArgError {
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
        */
        __New(mensaje, what?, extra?, codigo?, fecha?, nombreArg?, valorArg?) {
            super.__New(mensaje, what, extra, codigo, fecha, nombreArg)

            if IsSet(valorArg)
                this.valorArg := valorArg
        }
    }

    class Err_FuncError extends Err_Error {
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
        */
        __New(mensaje, what?, extra?, codigo?, fecha?, funcion?) {
            super.__New(mensaje, what, extra, codigo, fecha)

            try {
                this.Funcion := String(funcion ?? "")
            }
            catch {
                throw TypeError("(" ERR_ERRORES["ERR_TIPO_ARG"] ") El argumento funcion debe ser String (o convertible a String)")
            }
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
            @param {Boolean} extra - Si true, se añade la información de la propiedad Extra.
        */
        ToString(texto := "", extra := false) {
            return super.ToString("- Func: " this.Funcion " " texto, extra)
        }
    }

    class Err_NumArgsError extends Err_FuncError { 
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si el número de argumentos no es un entero >= 0
        */
        __New(mensaje, what?, extra?, codigo?, fecha?, funcion?, numArgs?) {
            super.__New(mensaje, what, extra, codigo, fecha, funcion)

            if !IsSet(numArgs)
                this.NumArgs := ""
            else {
                if !IsInteger(numArgs) or (numArgs := Integer(numArgs) < 0)
                    throw ValueError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") El número de argumentos debe ser un entero >= 0")

                this.NumArgs := String(numArgs)
            }
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
            @param {Boolean} extra - Si true, se añade la información de la propiedad Extra.
        */
        ToString(texto := "", extra := false) {
            return super.ToString("- NumArgs: " this.numArgs " " texto, extra)
        }
    }

    class ErrorEnumerator extends Err_FuncError {
    }

    class ErrorObjeto extends Error {
    }
}   