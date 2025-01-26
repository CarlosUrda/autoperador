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

    /*** VALORES GLOBALES Y CÓDIGOS DE ERRORES ***/

    /*
        @global NULL {String} - En ahk una cadena vacía se usa como null o valor indefinido.
    */
    global NULL := ""


    /*
        Tipos de errores con su código correspondiente y acciones a realizar para cada uno de ellos.

        NULL: No existe el código de error o se deconoce.
    */
    global ERR_FUNCION_ORIGEN := Map("ACTUAL", -1, "LLAMANTE", -2, "PADRE_LLAMANTE", -3, "ABUELO_LLAMANTE", -4)  ; Códigos de la documentación oficial

    ; Flag para saber si se pueden lanzar errores personalizados tipo Err_Error y su herencia, o solo se pueden lanzar errores tipo Error. No se pasa este valor como argumento porque afecta también a get y set y no se puede pasar por argumento en estos casos. Desactivar durante la creación y definición de errores personalizados Err_Error para evitar bucles lanzando errores que justo estoy definiendo y creando. Los métodos usandos en la creación y definición de la jerarquía Err_Error tienen que tener en cuenta este flag a la hora de lanzar errores. SOLO DEBE SER USAR INTERNAMENTE POR MOTIVOS DE ESTABILIDAD.
    global Err_ErroresPersonalizadosActivos := true



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
    _Err_AdmiteNumArgsM(funcion, numArgs) {
        ValidarNumArgs(n) => Integer(numArgs) >= 0
        ValidarNumArgs.Mensaje := "El número de argumentos debe ser entero >= 0"
        _Err_VerificarArg_Prv(numArgs, "numArgs", 2, IsInteger, ValidarNumArgs, Integer)

        return funcion.MaxParams >= numArgs and funcion.MinParams <= numArgs
    }

    _Err_AdmiteNumArgs(funcion, numArgs) {
        funcion := _Err_VerificarArg_Prv(funcion, "funcion", 1, Err_EsLlamable, (f) => f.Call)
        
        return funcion.AdmiteNumArgs(numArgs)
    }

    ; Se añade como método a Func
    Func.Prototype.DefineProp("AdmiteNumArgs", {Call: _Err_AdmiteNumArgsM})
    global Err_AdmiteNumArgs := _Err_AdmiteNumArgs

    
    /*
        @function Err_VerificarEnumerable

        @description Comprobar que un objeto puede pasar como Enumerator que admite un número de argumentos: teniendo método __Enum que devuelve un objeto Enumerator (llamable cuyos argumentos son VarRef) o siendo en sí mismo un objeto Enumerator. Sigue la secuencia de AHK a la hora de evaluar un enumerable.

        @param {Object<__Enum>|Enumerator} enum - Enumerator a comprobar.
        @param {Integer} numArgs - Número de argumentos que debe admitir el Enumerator por cada elemento.

        @returns Enumerator obtenido a partir de enum. Queda definido el número de argumentos que admite por numArgs.

        @throws {Err_MethodError} - Si se lanza algún error al ejecutar enum.__Enum.
        @throws {Err_TipoArgError} - Si el objeto devuelto por __Enum, o el propio enum en su defecto, no es llamable o no admite el número de argumentos numArgs (todos por referencia).
        @throws {Err_ValueError} - Si el Enumerator no admite numArgs como número de argumentos o éste no es número válido entero >= 0 (se permiten enumerators con 0 argumentos).

        @todo Comprobar que el enumerator no va a ejecutar ningún tipo de código malicioso.
        ¿Restringir la función a Enumerator en lugar de aceptarla siendo simplemente Llamable (Call)? Un Enumerator es una función que admite 
    */
    _Err_VerificarEnumerable(enum, numArgs) {
        ; numArgs se verifica en Err_AdmineNumArgs y en __Enum

        if enum.HasMethod("__Enum") {
            try 
                enum := enum.__Enum(numArgs)
            catch as e
                throw MethodError.CrearErrorAHK("__Enum(numArgs) da error y no puede obtener ningún resultado", , , , , e)

            mensajeBase := "El objeto obtenido de __Enum"
        }
        else
            mensajeBase := "El propio objeto enum (no hay __Enum)"

        Ll(e) => Err_EsLlamable(e) ; Se podría restringir y solo permitir tipo Enumerator
        Ll.Mensaje := mensajeBase " no puede ser llamado como una función"
        enum := Err_VerificarArg_Prv(enum, "enum", 1, Ll)

        Ad(n) => enum.Call.AdmiteNumArgs(n) ; Aunque __Enum(numArgs) haya funcionado, se verifica el enumerator devuelto
        Ad.Mensaje := mensajeBase "no admite el número de argumentos"
        enum := Err_VerificarArg_Prv(numArgs, "numArgs", 2, , Ad)

        Loop numArgs
            if !enum.Call.IsByRef(A_Index)
                throw Err_TipoArgError(mensajeBase "no admite por referencia el parámetro #" A_Index, , , , , , "enum", 1, Type(enum))

        /* Aquí se comprobaría si la ejecución del Enumerator es maliciosa, pero sin ejecutarlo porque entonces ya no se podría reutilizar */       

        return enum
    }

    global Err_VerificarEnumerable := _Err_VerificarEnumerable


    /*
        @function Err_VerificarArg_Prv

        @description Verificar un argumento para comprobar si es válido y cumple ciertas condiciones de tipo y valor. Solo comprueba el valor del argumento y no hace ninguna verificación del resto de parámetros, por lo que ESTA FUNCIÓN SOLO DEBE SER USADA INTERNAMENTE POR MOTIVOS DE SEGURIDAD.

        @param {Object} valorArg - Valor del argumento a comprobar.
        @param {String} nombreArg - Nombre del argumento.
        @param {Integer} posArg - Posición del argumento.
        @param {Func} comprobarTipo - Función que devolverá true o false si el valor no es del tipo correcto. Si el objeto Func tiene la propiedad Mensaje se usa como mensaje de error en la excepción si no se cumple el Tipo. Si no tiene propiedad Mensaje, se usa el nombre de la función en el mensaje de error. Si lanza algún error se considera igual que si valorArg no cumpliese el tipo correcto, y no como un problema de la función en sí misma (para comprobar la función está Err_VerificarArg)
        @param {Func} validarValor - Función que devolverá true o false si el valor no es valido. Esta función supone que el tipo del valor es el correcto. Si el objeto Func tiene la propiedad Mensaje se usa como mensaje de error en la excepción si no se cumple la validación. Si no tiene propiedad Mensaje, se usa el nombre de la función en el mensaje de error. Si lanza algún error se considera igual que si valorArg no cumple el valor correcto y no como un problema de la función en sí misma (para comprobar la función está Err_VerificarArg)
        @param {Func} convertirValor - Función que devolverá el valor convertido. Si lanza algún error se considera un error de    y no como un problema de la función en sí misma (para comprobar la función está Err_VerificarArg)

        @returns El valor del argumento convertido si existe función de convertir, o el propio valor si no existe.

        @throws {Error/Err_TipoArgError} - Si el valorArg no es de tipo correcto.        
        @throws {Error/Err_ValorArgError} - Si el valorArg no ecumple la validación del valor..
        @throws {Error/Err_ArgError} - Si el valorArg no puede ser convertido.
    */
    _Err_VerificarArg_Prv(valorArg, nombreArg?, posArg?, comprobarTipo?, validarValor?, convertirValor?) {
        infoFunciones := Map()
        if IsSet(comprobarTipo)
            infoFunciones[comprobarTipo] := {mensaje: "El tipo del valor no cumple", tipoError: Err_TipoArgError, argError: Type(valorArg)}
        if IsSet(comprobarTipo)
            infoFunciones[validarValor] := {mensaje: "El valor no cumple la validación de", tipoError: Err_ValorArgError, argError: valorArg}

        for funcion, info in infoFunciones {
            try
                esCorrecto := funcion(valorArg) 
            catch as e
                esCorrecto := false
            
            if !esCorrecto {
                ; Se usa Err_EsCadena porque no queremos lanzar más excepciones llegados a este punto.
                mensaje := funcion.HasProp("Mensaje") and Err_EsCadena(funcion.Mensaje) ? String(funcion.Mensaje) : info.mensaje " " funcion.Name
                throw !Err_ErroresPersonalizadosActivos ? Error(mensaje) : info.tipoError(mensaje, , , , , e?, nombreArg?, posArg?, info.argError)
            }
        }

        try
            return IsSet(convertirValor) ? convertirValor(valorArg) : valorArg
        catch as e {
            mensaje := convertirValor.HasProp("Mensaje") and Err_EsCadena(convertirValor.Mensaje) ? String(convertirValor.Mensaje) : "El valor no se puede convertir con " convertirValor.Name
            throw !Err_ErroresPersonalizadosActivos ? Error(mensaje) : Err_ArgError(mensaje, , , , , e?, nombreArg?, posArg?)
        }
    }

    global Err_VerificarArg_Prv := _Err_VerificarArg_Prv


    /*
        @function Err_VerificarArg

        @description Verificar un argumento para comprobar si es válido y cumple ciertas condiciones de tipo y valor. 

        @param {Object} valorArg - Valor del argumento a comprobar.
        @param {String} nombreArg - Nombre del argumento.
        @param {Integer} posArg - Posición del argumento.
        @param {Func} comprobarTipo - Función que devolverá true o false si el valor no es del tipo correcto. Si el objeto Func tiene la propiedad Mensaje se usa como mensaje de error en la excepción si no se cumple el Tipo. Si no tiene propiedad Mensaje, se usa el nombre de la función en el mensaje de error.
        @param {Func} validarValor - Función que devolverá true o false si el valor no es valido. Esta función supone que el tipo del valor es el correcto. Si el objeto Func tiene la propiedad Mensaje se usa como mensaje de error en la excepción si no se cumple la validación. Si no tiene propiedad Mensaje, se usa el nombre de la función en el mensaje de error.
        @param {Func} convertirValor - Función que devolverá el valor convertido. Esta función supone que el tipo del valor es el correcto y que pasa la validación.

        @returns El valor del argumento convertido si existe función de convertir, o el propio valor si no existe.

        @throws {TypeError/Err_TipoArgError} - Si algún argumento no es de tipo correcto.        
        @throws {ValueError/Err_ValorArgError} - Si algún argumento no ecumple la validación de valor.
    */
    _Err_VerificarArg(valorArg, nombreArg?, posArg?, comprobarTipo?, validarValor?, convertirValor?) {
        ; nombreArg y posArg solo sirven de información a ser incluida en el error lanzado en caso de fallo en la verificación. Ambos ya se comprueban en el único sitio donde se usan: constructor del Error a lanzar si falla la verificación.

        if IsSet(comprobarTipo) {
            EsFunc(f) => _Err_AdmiteNumArgs(f, 1)
            EsFunc.Mensaje := "No es una función o no admite un argumento"
            _Err_VerificarArg_Prv(comprobarTipo, "comprobarTipo", 4, EsFunc)

            /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo comprueba el tipo de un valor sin lanzar excepciones */
        }
        if IsSet(validarValor) {
            _Err_VerificarArg_Prv(validarValor, "validarValor", 5, EsFunc)

            /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo comprueba el valor suponiendo que el tipo ha sido ya comprobado anteriormente, sin lanzar excepciones */
        }
        if IsSet(convertirValor) {
            _Err_VerificarArg_Prv(convertirValor, "convertirValor", 6, EsFunc)

            /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo convierte el valor, sin lanzar excepciones, suponiendo que el tipo y el valor han sido comprobados anteriormente */
        }

        return _Err_VerificarArg_Prv(valorArg, nombreArg?, posArg?, comprobarTipo?, validarValor?, convertirValor?)
    }

    global Err_VerificarArg := _Err_VerificarArg

    
    
    /*** EXCEPCIONES PERSONALIZADAS ***/

    /*
        @class Err_Error

        @description Error padre del que heredan todos los errores.
    */
    class Err_Error extends Error {
        static __New() {
            Err_ErroresPersonalizadosActivos := false

            this.ERRORES := Map("NULL", 0, "CORRECTO", 1, "ERR_ERROR", -1, "ERR_ARG", -2, "ERR_VALOR", -3, "ERR_VALOR_ARG", -4, "ERR_TIPO", -5, "ERR_TIPO_ARG", -6, "ERR_ARCHIVO", -7, "ERR_OBJETO", -8, "ERR_INDICE", -9, "ERR_FUNCION", -10, "ERR_FUNCION_ARG", -11, "ERR_NUM_ARGS", -12, "ERR_INDEF", -13, "ERR_PROP_INDEF", -14, "ERR_MIEMBRO_INDEF", -15, "ERR_METODO_INDEF", -16, "ERR_CLAVE_INDEF", -17, "ERR_MEMORIA", -18, "ERR_OS", -19, "ERR_VENTANA", -20, "ERR_TIEMPO_RESPUESTA", -21, "ERR_DIV0", -22)
            ; *** Si ACCIONES e INFO_CODIGO no se termina usando, quitarlo ***
            this.ACCIONES := Map("NULL", NULL, "CONTINUAR", 1, "PARAR_FUNCION", 2, "PARAR_PROGRAMA", 3)
            this.INFO_CODIGOS := Map(
                this.ERRORES["NULL"], Map("nombre", "NULL", "accion", this.ACCIONES["NULL"], "mensaje", NULL),
                this.ERRORES["CORRECTO"], Map("nombre", "CORRECTO", "accion", this.ACCIONES["CONTINUAR"], "mensaje", "Ejecución realizada correcta"),
                this.ERRORES["ERR_ERROR"], Map("nombre", "ERR_ERROR", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error"),
                this.ERRORES["ERR_ARG"], Map("nombre", "ERR_ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Argumento erróneo"),
                this.ERRORES["ERR_VALOR"], Map("nombre", "ERR_VALOR", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Valor erróneo"),
                this.ERRORES["ERR_VALOR_ARG"], Map("nombre", "ERR_VALOR_ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Valor de argumento erróneo"),
                this.ERRORES["ERR_TIPO"], Map("nombre", "ERR_TIPO", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato erróneo"),
                this.ERRORES["ERR_TIPO_ARG"], Map("nombre", "ERR_TIPO_ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato de argumento erróneo"),
                this.ERRORES["ERR_ARCHIVO"], Map("nombre", "ERR_ARCHIVO", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error al gestionar un archivo"),
                this.ERRORES["ERR_OBJETO"], Map("nombre", "ERR_OBJETO", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error al crear un objeto"),
                this.ERRORES["ERR_INDICE"], Map("nombre", "ERR_INDICE", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Índice erróneo o sin valor definido"),
                this.ERRORES["ERR_FUNCION"], Map("nombre", "ERR_FUNCION", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función"),
                this.ERRORES["ERR_FUNCION_ARG"], Map("nombre", "ERR_FUNCION_ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función pasada por argumento"),
                this.ERRORES["ERR_NUM_ARGS"], Map("nombre", "ERR_NUM_ARGS", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Número incorrecto de argumentos pasados"),
                this.ERRORES["ERR_INDEF"], Map("nombre", "ERR_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Valor no definido"),
                this.ERRORES["ERR_PROP_INDEF"], Map("nombre", "ERR_PROP_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "La propiedad no tiene ningún valor"),
                this.ERRORES["ERR_MIEMBRO_INDEF"], Map("nombre", "ERR_MIEMBRO_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "No existe el miembro"),
                this.ERRORES["ERR_METODO_INDEF"], Map("nombre", "ERR_METODO_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "No existe el método"),
                this.ERRORES["ERR_CLAVE_INDEF"], Map("nombre", "ERR_CLAVE_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "No existe el elemento indexado por clave"),
                this.ERRORES["ERR_MEMORIA"], Map("nombre", "ERR_MEMORIA", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error de memoria"),
                this.ERRORES["ERR_OS"], Map("nombre", "ERR_OS", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error del S.O."),
                this.ERRORES["ERR_VENTANA"], Map("nombre", "ERR_VENTANA", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error de ventana o de alguno de sus componentes"),
                this.ERRORES["ERR_TIEMPO_RESPUESTA"], Map("nombre", "ERR_TIEMPO_RESPUESTA", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Tiempo de respuesta agotado"),
                this.ERRORES["ERR_DIV0"], Map("nombre", "ERR_DIV0", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "División por 0")
            )
        
            /* Se añaden las propiedades nuevas al prototipo de Err_Error */

            Sm(s) => String(s)
            Sm.Mensaje := "El mensaje debe ser una cadena o convertible a cadena"
            this.Prototype.DefinePropEstandar("Message", , , Sm)
            ;this.Prototype.DefinePropEstandar("What", Es_String, , String, true) ; Mejor dejar What como está porque no se sabe muy bien qué formato admite
            Se(s) => String(s)
            Se.Mensaje := "Extra debe ser una cadena o convertible a cadena"
            this.Prototype.DefinePropEstandar("Extra", , , Se)

            ValidarCodigo(c) => this.ERRORES.ContieneValor(c)
            ValidarCodigo.Mensaje := "El código de error no está incluido en la lista de códigos"
            this.Prototype.DefinePropEstandar("Codigo", IsInteger, ValidarCodigo, Integer)

            ValidarFecha(f) => FormatTime(f) != ""
            ValidarFecha.Mensaje := "La fecha no está en un formato válido YYYYMMDDHH24MISS"
            this.Prototype.DefinePropEstandar("Fecha", , ValidarFecha, String)

            ComprobarError(e) => e is Error
            ComprobarError.Mensaje := "La excepción previa tiene que ser tipo Error"
            this.Prototype.DefinePropEstandar("ErrorPrevio", ComprobarError)

            Err_ErroresPersonalizadosActivos := true
        }

        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info sobre la función desde donde se llamó la excepción: -1 función actual que la lanzó, -2 padre llamante de la función actual, -3 padre del padre, etc. Por defecto toma la función que llamó al constructor de Error, siendo distinto de -1 que obtiene la función que lanzó la excepción. Por eso aquí se toma por defecto -1 en lugar de dejarlo indefinido, para que la función sea la que lanzó este error personalizado y no el __New que llama al super.__New().
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la fecha no tiene el formato correcto.
        */
        __New(mensaje, what := ERR_FUNCION_ORIGEN["ACTUAL"], extra?, codigo := ERR_ERRORES["ERR_ERROR"], fecha := A_Now, errorPrevio?) {
            ; AHK no lanza un nuevo Error si falla la creación de super. Termina el programa evitando posibles bucles.
            super.__New(mensaje, what, extra?)
            Err_ErroresPersonalizadosActivos := false
            this.Codigo := codigo
            this.Fecha := fecha
            if IsSet(errorPrevio)
                this.ErrorPrevio := errorPrevio
            Err_ErroresPersonalizadosActivos := true
        }


        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String (no se muestra la pila Stack)

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""
    
            _texto := "[" FormatTime(this.Fecha, "dd/MM/yyyy HH:mm:ss] (") String(this.Codigo) ") " String(this.Message) ". " String(this.Extra) . texto "'r'n"
            try
                _texto .= "Previo => " this.ErrorPrevio "'r'n"
            
            return _texto
        }
    }


    /*
        @class Err_ErrorAHK

        @description Clase de la que heredarán todos los tipos de predefinidos por AHK (excepto Error).
    */
    class Err_ErrorAHK extends Err_Error {
        /*
            @static Constructor

            @@description Define parámetros asociados a los errores AHK y cuelga toda la jerarquía de errores predefinidos (excepto Error) de Err_ErrorAHK
        */
        static __New() {
            Err_ErroresPersonalizadosActivos := false

            ; USO PRIVADO INTERNO EXCLUSIVAMENTE
            this._ERRORES_AHK := Map(MemoryError, {nombre: "MemoryError", codigo: super.ERRORES["ERR_MEMORIA"]}, OSError, {nombre: "OSError", codigo: super.ERRORES["ERR_OS"]}, TargetError, {nombre: "TargetError", codigo: super.ERRORES["ERR_VENTANA"]}, TimeOutError, {nombre: "TimeOutError", codigo: super.ERRORES["ERR_TIEMPO_RESPUESTA"]}, TypeError, {nombre: "TypeError", codigo: super.ERRORES["ERR_TIPO"]}, UnsetError, {nombre: "UnsetError", codigo: super.ERRORES["ERR_INDEF"]}, MemberError, {nombre: "MemberError", codigo: super.ERRORES["ERR_MIEMBRO_INDEF"]}, PropertyError, {nombre: "PropertyError", codigo: super.ERRORES["ERR_PROP_INDEF"]}, MethodError, {nombre: "MethodError", codigo: super.ERRORES["ERR_METODO_INDEF"]}, UnsetItemError, {nombre: "UnsetItemError", codigo: super.ERRORES["ERR_CLAVE_INDEF"]}, ValueError, {nombre: "ValueError", codigo: super.ERRORES["ERR_VALOR"]}, IndexError, {nombre: "IndexError", codigo: super.ERRORES["ERR_INDICE"]}, ZeroDivisionError, {nombre: "ZeroDivisionError", codigo: super.ERRORES["ERR_DIV0"]})

            for tipoErrorAHK in this._ERRORES_AHK
                if tipoErrorAHK.Base == Error
                    tipoErrorAHK.CambiarBase(this, Error)      

            Err_ErroresPersonalizadosActivos := true
        }
        
        /*
            @static CrearErrorAHK

            @description Crear un objeto error de tipo error predefinido AHK heredero de Err_ErrorAHK, extendiendo su información completando las propiedades que faltan. Solo se puede usar desde las clases heredadas de CrearError

            @param {String} mensaje - Mensaje del error.
            @param {String} what - Información de la propiedad what. Por defecto la función que llamó a CrearError.
            @param {String} extra - Información tomada como propiedad extra.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Por defecto el código asignado para this (tipo de error AHK).
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.

            @returns {Subclass<Err_ErrorAHK>} Excepción creada.
        */
        static CrearErrorAHK(mensaje?, what := ERR_FUNCION_ORIGEN["LLAMANTE"], extra?, codigo?, fecha := A_Now, errorPrevio?) {
            Err_ErroresPersonalizadosActivos := false

            ComprobarTipo(e) => e != Err_ErrorAHK and e.HasBase(Err_ErrorAHK)
            ComprobarTipo.Mensaje := "CrearError solo se puede usar desde los tipos de error predefinidos AHK herederos de Err_Error"
            tipoErrorAHK := Err_VerificarArg_Prv(this, "this", 0, ComprobarTipo)

            excepcion := tipoErrorAHK(mensaje?, what, extra?)
            excepcion.Codigo := codigo ?? this._ERRORES_AHK[tipoErrorAHK].codigo
            excepcion.Fecha := fecha
            if IsSet(errorPrevio)
                excepcion.ErrorPrevio := errorPrevio

            Err_ErroresPersonalizadosActivos := true

            return excepcion
        }            

    }

    /*
        @class Err_ErrorNoAHK

        @description Clase de la que heredarán todos los tipos de errores nuevos personalizados que no son predefinidos por AHK.
    */
    class Err_ErrorNoAHK extends Err_Error {
    }

    /*
        @class ErrorArgumento

        @decription Errores relacionados con los argumentos recibidos en la función o método donde ocurre el error.
    */
    class Err_ArgError extends Err_ErrorNoAHK { 
        static __New() {
            Err_ErroresPersonalizadosActivos := false

            VP(i) => Integer(i) >= 0
            VP.Mensaje := "La posición del argumento debe ser entero >= 0 (0 para this)"
            this.Prototype.DefinePropEstandar("PosArg", Es_Entero(i) => IsInteger(i), VP, Integer)

            S(s) => String(s)
            S.Mensaje := "El nombre de argumento debe ser una cadena o convertible a cadena"
            this.Prototype.DefinePropEstandar("NombreArg", , , S)

            Err_ErroresPersonalizadosActivos := true
        }

        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.
            @param {String} nombreArg - Nombre del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios. Se guarda como nueva propiedad NombreArg
            @param {String} posArg - Número de posición del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad PosArg

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_ARG"], fecha?, errorPrevio?, nombreArg?, posArg?) {
            super.__New(mensaje, what, extra, codigo, fecha)

            Err_ErroresPersonalizadosActivos := false

            if IsSet(nombreArg)
                this.NombreArg := nombreArg
            if IsSet(posArg)
                this.PosArg := posArg

            Err_ErroresPersonalizadosActivos := true
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""
            try
                _texto := ". NombreArg: " this.NombreArg
            try
                _texto := ". #Arg: " this.PosArg

            return super.ToString((_texto ?? "") . texto)
        }
    }

    class Err_TipoArgError extends Err_ArgError {
        static __New() {
            Err_ErroresPersonalizadosActivos := false

            EsClase(s) => %String(s)% is Class
            EsClase.Mensaje := "La cadena tipo de dato no representa ninguna Clase"
            this.Prototype.DefinePropEstandar("TipoArg", , EsClase, String)

            Err_ErroresPersonalizadosActivos := true
        }

        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.
            @param {String} nombreArg - Nombre del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios. Se guarda como nueva propiedad NombreArg
            @param {String} posArg - Número de posición del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad PosArg
            @param {String} tipoArg - Nombre del tipo de argumento que ha generado el error. Si son varios posibles tipos de varios argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad TipoArg

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_TIPO_ARG"], fecha?, errorPrevio?, nombreArg?, posArg?, tipoArg?) {
            super.__New(mensaje, what, extra, codigo, fecha, nombreArg, posArg)
            Err_ErroresPersonalizadosActivos := false
            if IsSet(tipoArg)
                this.TipoArg := tipoArg
            Err_ErroresPersonalizadosActivos := true
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""
            try
                _texto := ". NombreArg: " this.TipoArg

            return super.ToString((_texto ?? "") . texto)
        }
    }

    class Err_ValorArgError extends Err_ArgError {
        static __New() {
            Err_ErroresPersonalizadosActivos := false
            this.Prototype.DefinePropEstandar("ValorArg")
            Err_ErroresPersonalizadosActivos := true
        }

        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.
            @param {String} nombreArg - Nombre del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios. Se guarda como nueva propiedad NombreArg
            @param {String} posArg - Número de posición del argumento que ha generado el error. Si son varios posibles argumentos, separarlos por espacios en orden respecto a los nombres. Se guarda como nueva propiedad PosArg
            @param {Any} ValorArg - Valor del argumento que genera el error. Si no está definido, la propiedad ValorArg queda indefinida; si está definido se la guarda el valor. Se puede pasar una lista de valores en caso de haber varios, aunque internamente no considera si son varios o un solo valor lista. Simplemente.

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_VALOR_ARG"], fecha?, errorPrevio?, nombreArg?, posArg?, valorArg?) {
            super.__New(mensaje, what, extra, codigo, fecha, nombreArg, posArg)
            if IsSet(valorArg)
                this.ValorArg := valorArg           
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes del texto de la propiedad Extra.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""
            try
                _texto := ". ValorArg: " Err_EsCadena(this.ValorArg) ? String(this.ValorArg) : " **** "

            return super.ToString((_texto ?? "") . texto)
        }
    }

    class Err_FuncArgError extends Err_ArgError {
    }

    class Err_FuncError extends Err_ErrorNoAHK {
        static __New() {
            Err_ErroresPersonalizadosActivos := false

            EsClase(s) => %String(s)% is Class
            EsClase.Mensaje := "La cadena tipo de dato no representa ninguna Clase"
            this.Prototype.DefinePropEstandar("NombreFunc", , EsClase, String)

            Err_ErroresPersonalizadosActivos := true
        }

        /*
            @method Constructor

            @throws {TypeError} - Si los argumentos no tienen tipos correctos

            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.

        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_FUNCION"], fecha?, errorPrevio?, funcion?) {
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

            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si el número de argumentos no es un entero >= 0
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["ERR_NUM_ARGS"], fecha?, errorPrevio?, funcion?, numArgs?) {
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

    class Err_ObjetoError extends Err_ErrorNoAHK {
    }
}   


