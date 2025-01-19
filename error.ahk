/*
    @module error.ahk

    @description Gestión de los errores

    @requires Recordatorio de excepciones que lanza ahk ante eventos:
        - MethodError:
            - Si objeto carece de método ToString al llamarlo en String
        
        - TypeError:
            - Si un objeto a recorrer en un bucle no es Enumerator, no tiene función __Enum o ésta no devuelve un Enumerator.
            
    @requires El problema de lanzar excepciones desde las clases Err es que no puedo hacerlo con excepciones delas propias clases que estoy creando, tienen que ser excepciones predefeinidas.

    @todo Solucionar el tener que pasar el número de línea en cada llamada a Err_Lanzar porque al asignarlo como valor por defecto toma el valor de la línea de la función Err_Lanzar, mientras que en el caso del nombre de la función sí toma como valor por defecto la función que le llama (aunque no es seguro que esto último lo vaya a hacer siempre)
    Opciones para tratar las excepciones predefinidas:
    - Dejarlas propagarse sin hacer nada.
    - Capturarlas y extenderlas haciéndolas formar parte de Err_Error.
    - Capturarlas y guardarlas como una propiedad de una nueva excepción lanzada Err_Error
*/


#Requires AutoHotkey v2.0


if (!IsSet(__ERR_H__)) {
    global __ERR_H__ := true

    /*** VALORES Y CÓDIGOS DE ERRORES ***/

    /*
        @global NULL {String} - En ahk una cadena vacía se usa como null o valor indefinido.
    */
    global NULL := ""


    /*
        Tipos de errores con su código correspondiente y acciones a realizar para cada uno de ellos.

        NULL: No existe el código de error o se deconoce.
    */
    global ERR_ERRORES := Map("NULL", 0, "CORRECTO", 1, "ERR_ERROR", -1, "ERR_ARG", -2, "ERR_VALOR", -3, "ERR_VALOR_ARG", -4, "ERR_TIPO", -5, "ERR_TIPO_ARG", -6, "ERR_ARCHIVO", -7, "ERR_OBJETO", -8, "ERR_INDICE", -9, "ERR_FUNCION", -10, "ERR_FUNCION_ARGS", -11, "ERR_NUM_ARGS", -12, "ERR_PROP_INDEF", -13)
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
        ERR_ERRORES["ERR_FUNCION_ARG"], Map("nombre", "ERR_FUNCION_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función pasada por argumento"),
        ERR_ERRORES["ERR_NUM_ARGS"], Map("nombre", "ERR_NUM_ARGS", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Número incorrecto de argumentos pasados"),
        ERR_ERRORES["ERR_PROP_INDEF"], Map("nombre", "ERR_PROP_INDEF", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "La propiedad no tiene ningún valor")
    )
    global ERR_FUNCION_ORIGEN := Map("ACTUAL", -1, "LLAMANTE", -2, "PADRE_LLAMANTE", -3)  ; Códigos establecidos en la documentación oficial



    /*** FUNCIONES DE MENSAJE DE ERRORES ***/

    /*
        * Hacer un método para excepciones Err_Error *
        @function ErrMsgBox
        
        @description Mostar un mensaje MsgBox con la información de una excepcion

        @param {Error} e - Objeto clase Error con la información de la excepción.
    */
    global Err_MsgBox := e => MsgBox(String(e), )
    excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") El tipo de excepción a lanzar no es clase Error.", ERR_FUNCION_ORIGEN["ACTUAL"], FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
    nombreArchivo := RegExReplace(String(script), ".*[\\/]", "")

    ; Se añade Err_MsgBox como método a Error
    Error.Prototype.DefineProp("MsgBox", {Call: Err_MsgBox})



    /*** FUNCIONES DE COMPROBACIÓN DE ERRORES ***/

    /*
        @function Err_EsLlamable

        @description Comprobar si un objeto es o actúa como una función: es llamable.

        @param {Object} f - Objeto a comprobar.

        @returns true o false si es o no llamable.
    */
    Err_EsLlamable := f => f is Func or f.HasMethod("Call")


    /*
        @function Err_EsCadena

        @description Comprobar si un objeto es cadena o es convertible a cadena (String).

        @param {Object} cadena - Objeto a comprobar.

        @returns true o false si es o no cadena.
    */
    _Err_EsCadena(cadena) {
        try 
            String(cadena)
        catch
            return false

        return true
    }

    global Err_EsCadena := _Err_EsCadena


    /*
        @function Err_AdmiteNumArgs

        @description Comprobar si una función admite un número de argumentos.

        @param {Func} funcion - Función a comprobar.
        @param {Func} numArgs - Número de argumentos a comprobar.

        @throws {TypeError} - Si no es una función.

        @returns true o false.
    */
    _Err_AdmiteNumArgs(funcion, numArgs) {
        if !(funcion is Func)
            Err_Lanzar(TypeError, "El argumentoo no es una función", ERR_ERRORES["ERR_ARG"])
        
        return funcion.MaxParams >= numArgs and funcion.MinParams <= numArgs
    }

    ; Se añade como método a Func
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

    
    
    /*** EXCEPCIONES PERSONALIZADAS ***/

    /*
        @class Err_Error

        @description Error padre del que heredan todos los errores personalizados Err_.
        NOTA: Toda función que es llamada desde la creación de un objeto Err_Error debe tener la opción de lanzar solo errores predefinidos erroresAHK, si no puede generar un conflicto por lanzar errores Err_Error a la vez que se está creando un objeto Err_Error.
    */
    class Err_Error extends Error {
        /*
            @static ExtenderErr

            @description Modificar un objeto excepción Error para que sea heredera de Err_Error y extender su información completando las propiedades que faltan y concatenando más información a las ya existentes.

            @param {String} mensaje - Mensaje a concatenarse a la propiedad Message ya existente en la excepción.
            @param {String} extra - Info extra a concatenarse a la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.

            @returns Excepción modificada.
        */
        static ExtenderErr(excepcion, mensaje?, extra?, codigo := ERR_ERRORES["ERR_ERROR"], fecha := A_Now, erroresAHK := false) {
            if excepcion is Err_Error
                throw Err_TipoArgError("La excepción ya es tipo Err_Error", , "Arg: excepcion; Tipo: " Type(excepcion), ERR_ERRORES["ERR_TIPO_ARG"], , "excepcion", Type(excepcion))

            if !(excepcion is Error)
                throw Err_TipoArgError("La excepción no es tipo Error", , "Arg: excepcion; Tipo: " Type(excepcion), ERR_ERRORES["ERR_TIPO_ARG"], , "excepcion", Type(excepcion))

            excepcion.Base.Base := this.Prototype

            ; Se deja que se propague directamente cualquier excepción al no poder extender la información de la excepción capturada (estoy dentro del método que lo hace)
            this.Message .= IsSet(mensaje) ? ". " String(mensaje) : ""
            this.Extra .= IsSet(extra) ? ". " String(extra) : ""
            /* Comprobar siempre que el código de error es uno de los definidos, como en comprobarArgs de Debug.ahk */
            this.Codigo := String(codigo)
            this.Fecha := String(fecha)
            if FormatTime(this.Fecha) == ""
                throw Err_ValorArgError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") La fecha " this.Fecha " no está en formato YYYYMMDDHH24MISS", , , ERR_ERRORES["ERR_VALOR_ARG"], , "fecha", this.Fecha)

            return excepcion
        }

        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorAHK - Error predefinido de ahk que lanzó el sistema como causa del problema.

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la fecha no tiene el formato correcto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_ERROR"], fecha := A_Now, errorAHK?) {
            super.__New(mensaje, what, extra)
            this.DefinePropCadena("Codigo", true)
            this.Codigo := codigo
            this.Fecha := fecha
            this.ExcepAHK := errorAHK
        }

        /*
            @property Fecha

            @description {String} Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha..

            @throws {TypeError} - La fecha no es String o convertible a String
            @throws {ValueError} - Si la fecha no tiene el formato correcto.

        */
        Fecha {
            get => this._fecha

            set {
                try {
                    this._fecha := String(value)
                }
                catch {
                    throw this.ExtenderErr(e, "(" ERR_ERRORES["ERR_TIPO_ARG"] ") lA fecha debe ser String (o convertible a String)", , ERR_ERRORES["ERR_TIPO_ARG"])
                }
        
                if FormatTime(this._fecha) == ""
                    throw ValueError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") La fecha no está en formato YYYYMMDDHH24MISS")    
            }    
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
            @param {Boolean} extra - Si true, se añade la información de la propiedad Extra.
        */
        ToString(texto := "", extra := false) {
            return "[" FormatTime(this.Fecha, "dd/MM/yyyy HH:mm:ss] (") String(this.Codigo) ") " String(this.Mensaje) " " String(texto) !!extra ?  "'r'n" String(this.Extra) : ""
        }
    }

    /*
        @class ErrorArgumento

        @decription Errores relacionados con los argumentos recibidos en la función o método donde ocurre el error.
    */
    class Err_ArgError extends Err_Error { 
        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorAHK - Error predefinido de ahk que lanzó el sistema como causa del problema.
            @param {String} nombreArg - Nombre del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios. Se guarda como nueva propiedad NombreArg
            @param {String} posArg - Número de posición del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad PosArg

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_ARG"], fecha?, errorAHK?, nombreArg?, posArg?) {
            if !IsSet(posArg)
                posArg := ""
            else if !IsInteger(posArg) 
                throw TypeError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") El número del argumento debe ser un entero")
            else if (posArg := Integer(posArg)) < 1
                throw ValueError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") El número del argumento debe ser un entero >= 1")

            super.__New(mensaje, what, extra, codigo, fecha)
            super._AgregarPropsCadena(Map("NombreArg", nombreArg ?? "", "PosArg", posArg), !IsSet(extra))
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
            @param {Boolean} extra - Si true, se añade la información de la propiedad Extra.
        */
        ToString(texto := "", extra := false) {
            return super.ToString(". Arg: " this.NombreArg ". #: " this.PosArg ". " texto, extra)
        }
        
    }

    class Err_TipoArgError extends Err_ArgError {
        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorAHK - Error predefinido de ahk que lanzó el sistema como causa del problema.
            @param {String} nombreArg - Nombre del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios. Se guarda como nueva propiedad NombreArg
            @param {String} posArg - Número de posición del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad PosArg
            @param {String} tipoArg - Nombre del tipo de argumento que ha generado el error. Si son varios posibles tipos de varios argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad TipoArg

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_TIPO_ARG"], fecha?, errorAHK?, nombreArg?, posArg?, tipoArg?) {
            super.__New(mensaje, what, extra, codigo, fecha, nombreArg, posArg)
            super._NuevasPropsCadena(Map("tipoArg", tipoArg ?? ""), !IsSet(extra))
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

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorAHK - Error predefinido de ahk que lanzó el sistema como causa del problema.
            @param {String} nombreArg - Nombre del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios. Se guarda como nueva propiedad NombreArg
            @param {String} posArg - Número de posición del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad PosArg
            @param {Any} ValorArg - Valor del argumento que genera el error. Si no está definido, la propiedad ValorArg queda indefinida; si está definido se la guarda el valor. Se puede pasar una lista de valores en caso de haber varios, aunque internamente no considera si son varios o un solo valor lista. Simplemente.

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_VALOR_ARG"], fecha?, errorAHK?, nombreArg?, posArg?, valorArg?) {
            super.__New(mensaje, what, extra, codigo, fecha, nombreArg, posArg)

            if IsSet(valorArg) {
                this.valorArg := valorArg

                try {
                    if valorArg is Map
                        _valorArg := Util_EnumerableACadena(valorArg, 2)
                    else if valorArg is Array
                        _valorArg := Util_EnumerableACadena(valorArg, 1)
                    else 
                        _valorArg := String(valorArg)
                    VarRef
                }
                catch { ; Si no es convertible a String solo se guarda su valor
                }  
                else
                    this.Extra .= IsSet(extra) ? "" : " ValorArg: " _valorArg
            }
            
        }
    }

    class Err_FuncArgError extends Err_ArgError {
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_FUNCION_ARG"], fecha?, errorAHK?, nombreArg?, posArg?, funcion?) {
            super.__New(mensaje, what, extra, codigo, fecha, errorAHK, nombreArg, posArg)
            super._NuevasPropsCadena(Map("funcion", funcion ?? ""), !IsSet(extra))
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

    class Err_FuncError extends Err_Error {
        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_FUNCION"], fecha?, errorAHK?, funcion?) {
            super.__New(mensaje, what, extra, codigo, fecha)
            super._NuevasPropsCadena(Map("funcion", funcion ?? ""), !IsSet(extra))
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
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_NUM_ARGS"], fecha?, errorAHK?, funcion?, numArgs?) {
            if !IsSet(numArgs)
                numArgs := ""
            else if !IsInteger(numArgs) 
                throw TypeError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") El número de argumentos debe ser un entero")
            else if (numArgs := Integer(numArgs)) < 0
                throw ValueError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") El número de argumentos debe ser un entero >= 0")

            super.__New(mensaje, what, extra, codigo, fecha, funcion)
            super._AgregarPropsCadena(Map("numArgs", numArgs), !IsSet(extra))
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

    class Err_EnumeratorError extends Err_FuncError {
    }

    class Err_ObjetoError extends Error {
    }
}   


