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


if (!IsSet(__ERR_H__)) 
    global __ERR_H__ := true

    /*** VALORES GLOBALES ***/

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
    global Err_ErroresPersonalizadosActivo := true




    /*** FUNCIONES DE MENSAJE DE ERRORES ***/

    /*
        * Hacer un método para excepciones Err_Error *
        @function ErrMsgBox
        
        @description Mostar un mensaje MsgBox con la información de una excepcion

        @param {Error} e - Objeto clase Error con la información de la excepción.
    */
    Err_Error.Prototype.DefineProp("MsgBox", {Call: (e) => MsgBox(e)})




    /*** FUNCIONES DE COMPROBACIÓN DE ERRORES ***/

    /*
        @function Err_EsLlamable

        @description Comprobar si un objeto es o actúa como una función: es llamable.

        @param {Object} f - Objeto a comprobar.

        @returns true o false si es o no llamable.
    */
    Err_EsLlamable(f) => f is Func or (f.HasMethod("Call") and f.Call is Func and f.Call.MinParams >= 1)


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
       ; No podemos llamar a Err_VerificarArg (ni DefinirPropEstandar) porque necesitamos FuncArg y crearíamos un bucle

        if !IsInteger(numArgs) {
            m := "El valor de numArgs debe ser entero"
            throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m, , , , , , "numArgs", 2, numArgs, Type(numArgs))
        }

        numArgs := Integer(numArgs)
        if numArgs < 0 {
            m := "El número de argumentos debe ser entero >= 0"
            throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_ValorArgError(m, , , , , , "numArgs", 2, numArgs)
        }

        return numArgs >= funcion.MinParams and (numArgs <= funcion.MaxParams or funcion.IsVariadic)
    }

    _Err_AdmiteNumArgs(funcion, numArgs) {
       ; No podemos llamar a Err_VerificarArg (ni DefinirPropEstandar) porque necesitamos FuncArg y crearíamos un bucle

        if !Err_EsLlamable(funcion) {
            m := "No has pasado una función o un objeto llamable"
            throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m, , , , , , "funcion", 1, funcion, Type(funcion))
        }

        if !(funcion is Func) {
            funcion := funcion.Call
            numArgs++ ; Se tiene en cuenta this recibido por Call
        }
        
        return funcion.AdmiteNumArgs(numArgs)
    }

    ; Se añade como método a Func
    Func.Prototype.DefineProp("AdmiteNumArgs", {Call: _Err_AdmiteNumArgsM})
    global Err_AdmiteNumArgs := _Err_AdmiteNumArgs

    
    /*
        @function Err_VerificarArgsRef

        @description Verificar que los argumentos de una función tienen que ser pasados por referencia. Tener en cuenta que si se pasa un método de un objeto (como Call), el primer argumento es el objeto this.

        @param {Func} funcion - Función u objeto llamable a comprobar sus argumentos.
        @param {Integer} posArgs - Serie de posiciones de los argumentos que se serán comprobados. Si no se pasa nada, se comprobarán todos los argumentos de la función sin incluir los variables. Si una posición se pasa repetida, en el resultado solo aparece una vez.
        @param {Boolean} recibeThis - Si la función recibe this como primer argumento. Muy útil por si se pasa una función Call de un objeto llamable.

        @returns {Map} Diccionario con un valor Bool por cada posición solicitada (clave), indicando si el argumento de las posición es por referencia (true) o no (false)
    */
    _Err_VerificarArgsRefM(funcion, recibeThis := false, posArgs*) {
        inc := !!recibeThis

        if posArgs.Lenght == 0
            posArgs := Util_CrearLista(funcion.MaxParams - inc)

        resultado := Map()
        for posArg in posArgs {
            posArg := _Err_VerificarArg_Prv(posArg, "posArgs[" A_Index "]", 2 + A_Index, FuncArg(IsInteger, FuncArg.TIPO_FUNC["Comprobar"]), FuncArg(Integer, FuncArg.TIPO_FUNC["Convertir"]))

            try
                resultado[posArg] := funcion.IsByRef(posArg + inc)
            catch as e
                throw Err_ValorArgError("La posición " posArg "del argumento no es válida en la función", , , , , e, "posArgs[" A_Index "]", 2, posArg)
        }
        
        return resultado
    }

    _Err_VerificarArgsRef(funcion, posArgs*) {
        _Err_VerificarArg_Prv(funcion, "funcion", 1, FuncArg(Err_EsLlamable, FuncArg.TIPO_FUNC["Comprobar"]))
        ; No se comprueba posArgs porque se comprueba luego al recorrerla. Si no se recorrería dos veces.

        return !(funcion is Func) ?  funcion.Call.VerificarArgsRef(true, posArgs*) : funcion.VerificarArgsRef(false, posArgs*)
    }

    Func.Prototype.DefineProp("VerificarArgsRef", {Call: _Err_VerificarArgsRefM})
    global Err_VerificarArgsRef := _Err_VerificarArgsRef


    /*
        @function Err_VerificarEnumerable

        @description Comprobar que un objeto puede pasar como Enumerator que admite un número de argumentos: teniendo método __Enum que devuelve un objeto Enumerator (llamable cuyos argumentos son VarRef) o siendo en sí mismo un objeto Enumerator. Sigue la secuencia de AHK a la hora de evaluar un enumerable.

        @param {Object<__Enum>|Enumerator} enum - Enumerator a comprobar.
        @param {Integer} numArgs - Número de argumentos que debe admitir el Enumerator por cada elemento.

        @returns Enumerator obtenido a partir de enum. Queda definido el número de argumentos que admite por numArgs.

        @throws {Err_MethodError} - Si se lanza algún error al ejecutar enum.__Enum.
        @throws {Err_TipoArgError} - Si el objeto devuelto por __Enum, o el propio enum en su defecto, no es llamable o no admite el número de argumentos numArgs (todos por referencia).

        @todo Comprobar que el enumerator no va a ejecutar ningún tipo de código malicioso.
        ¿Restringir la función a Enumerator en lugar de aceptarla siendo simplemente Llamable (Call)? Un Enumerator es una función que admite 
    */
    _Err_VerificarEnumerable(enum, numArgs) {
        ; numArgs se verifica en AdmiteNumArgs y en __Enum

        if enum.HasMethod("__Enum") {
            try 
                enum := enum.__Enum(numArgs)
            catch as e {
                m := "__Enum(numArgs) da error y no puede obtener ningún resultado"
                throw !Err_ErroresPersonalizadosActivo ? Error(m) : MethodError.CrearErrorAHK(m, , , , , e)
            }

            mensajeBase := "El objeto obtenido de __Enum"
        }
        else
            mensajeBase := "El propio objeto enum (no hay __Enum)"

        if !Err_AdmiteNumArgs(enum, numArgs) {
            m := mensajeBase . " no admite el número de argumentos"
            throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m, , , , , , "enum", 1, enum, Type(enum))
        }

        ; No se comprueba si esto lanza excepción porque enum es llamable y admite el número de argumentos.      
        posArgs := Util_ObtenerClaves(Err_VerificarArgsRef(enum, Util_CrearLista(numArgs), 2, false))
        if posArgs.Length != 0 {
            m := mensajeBase . " no admite parámetros por referencia en sus argumentos #" posArgs
            throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m , , , , , , "enum", 1, enum, Type(enum))
        }

        /* Aquí se comprobaría si la ejecución del Enumerator es maliciosa, pero sin ejecutarlo porque entonces ya no se podría reutilizar */       

        return enum
    }

    global Err_VerificarEnumerable := _Err_VerificarEnumerable


    /*
        @function Err_VerificarArg_Prv

        @description Verificar un argumento para comprobar si es válido y cumple ciertas condiciones. Solo comprueba el valor del argumento y no hace ninguna verificación del resto de parámetros, por lo que ESTA FUNCIÓN SOLO DEBE SER USADA INTERNAMENTE POR MOTIVOS DE SEGURIDAD.

        @param {Object} valorArg - Valor del argumento a comprobar.
        @param {String} nombreArg - Nombre del argumento.
        @param {Integer} posArg - Posición del argumento.
        @param {FuncArg} funciones - Funciones de verificación FuncArg que serán llamadas en el orden en que son pasadas. A cada función se le pasa como único argumento valorArg.

        @returns El valor del argumento convertido si existe función de convertir, o el propio valor si no existe.

        @throws {Error/Err_ArgError} - Se lanzará el tipo de Err_ArgError asociado con la función FuncArg que provoque la excepción.
    */
    _Err_VerificarArg_Prv(valorArg, nombreArg?, posArg?, funciones*) {
        for funcion in funciones {
            if funcion.CodigoTipoFunc == FuncArg.TIPO_FUNC["Convertir"] {
                try
                    valorArg := funcion(valorArg)
                catch as e
                    esCorrecto := false
            }
            else {
                try
                    esCorrecto := funcion(valorArg) 
                catch as e
                    esCorrecto := false
            }

            if IsSet(esCorrecto) and !esCorrecto {
                switch funcion.TipoError {
                    case Err_TipoArgError:
                        argsExtra := [Type(valorArg)]
                    default:
                        argsExtra := []              
                }

                throw !Err_ErroresPersonalizadosActivo ? Error(funcion.Mensaje) : funcion.TipoError(funcion.Mensaje, , , , , e?, nombreArg?, posArg?, valorArg, argsExtra*)
            }
        }

        return valorArg
    }

    global Err_VerificarArg_Prv := _Err_VerificarArg_Prv


    /*
        @function Err_VerificarArg

        @description Verificar un argumento para comprobar si es válido y cumple ciertas condiciones de tipo y valor. 

        @param {Object} valorArg - Valor del argumento a comprobar.
        @param {String} nombreArg - Nombre del argumento.
        @param {Integer} posArg - Posición del argumento.
        @param {FuncArg} funciones - Funciones de verificación FuncArg que serán llamadas en el orden en que son pasadas. A cada función se le pasa como único argumento valorArg.

        @returns El valor del argumento convertido si existe función de convertir, o el propio valor si no existe.

        @throws {Error/Err_ArgError} - Se lanzará el tipo de Err_ArgError asociado con la función FuncArg que provoque la excepción.
    */
    _Err_VerificarArg(valorArg, nombreArg?, posArg?, funciones*) {
        ; nombreArg y posArg solo sirven de información a ser incluida en el error lanzado en caso de fallo en la verificación. Ambos ya se comprueban en el único sitio donde se usan: constructor del Error a lanzar si falla la verificación.

        for funcion in funciones {
            _Err_VerificarArg_Prv(funcion, "funciones[" A_Index "]", 3 + A_Index, FuncArg((f) => f is FuncArg, FuncArg.TIPO_FUNC["Comprobar"], "No es una función FuncArg"))

            /* Aquí se verificaría la función para comprobar que no es maliciosa */
        }

        return _Err_VerificarArg_Prv(valorArg, nombreArg?, posArg?, funciones*)
    }

    global Err_VerificarArg := _Err_VerificarArg




    /*** TIPOS DE DATOS PARA COMPROBACIÓN DE ERRORES ***/
    
    /*
        @class FuncArg

        @description Tipo usado para envolver las funciones que serán usadas en la verificación de los argumentos (Err_VerificarArg). La función a envolver puede ser un objeto llamable o de tipo Func. Los tipos de función que puede envolver son:
        - "Comprobar": Admite un argumento y devuelve true/false. Sirven para hacer comprobaciones del tipo de dato del argumento. Por defecto lanzan Err_TipoArgError en caso de no pasar la comprobación o lanzar algún error.
        - "Validar": Admite un argumento y devuelve true/false. Sirven para validar el valor del argumento. Por defecto lanzan Err_ValorArgError en caso de no pasar la validación o lanzar algún error.
        - "Convertir": Admite un argumento y devuelve un valor. Sirven para realizar conversiones en el argumento. Por defecto lanzan Err_FuncArgError en caso de no poder realizar la conversión o lanzar algún error.
        Los tipos de error asociados con la función tienen que ser Err_ArgError.
    */
    class FuncArg {
        static TIPO_FUNC := Map("Comprobar", 1, "Validar", 2, "Convertir", 3)
        static _TIPO_ERROR := Map(this.TIPOS_FUNC["Comprobar"], Err_TipoArgError, this.TIPOS_FUNC["Validar"], Err_ValorArgError, this.TIPOS_FUNC["Convertir"], Err_FuncArgError)
        static _MENSAJES := Map(this.TIPOS_FUNC["Comprobar"], "El valor no cumple la comprobación", this.TIPOS_FUNC["Validar"], "El valor no cumple la validación", this.TIPOS_FUNC["Convertir"], "No se ha podido aplicar al valor la conversión")

        __New(funcion, codigoTipoFunc, mensaje?, tipoError?) {
            ; No podemos usar Err_VerificarArg (ni DefinirPropEstandar) porque crearíamos un bucle

            this.Funcion := funcion
            this.CodigoTipoFunc := codigoTipoFunc         
            if IsSet(mensaje)
                this.Mensaje := mensaje
            if IsSet(tipoError) 
                this.TipoError := tipoError            
        }

        Call(arg) => (this.Funcion)(arg)

        Mensaje {
            get => this.HasProp("_mensaje") ? this._mensaje : FuncArg._MENSAJES[this.CodigoTipoFunc] . (this.Funcion is Func) ? this.Funcion.Name : ""

            set {
                try
                    this._mensaje := String(value)
                catch as e {
                    m := "El mensaje debe ser una cadena o convertible a cadena"
                    throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m, , , , , , "Mensaje", 1, value, Type(value))
                }
            }
        }

        CodigoTipoFunc {
            get => this._codigoTipoFunc

            set {
                if !this.TIPO_FUNC.ContieneValor(value) {
                    m := "El código del tipo de función no es válido"
                    throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_ValorArgError(m, , , , , , "CodigoTipoFunc", 1, value)
                }

                this._codigoTipoFunc := Integer(value)
            }
        }

        TipoError {
            get => this.HasProp("_tipoError") ? this._tipoError : FuncArg._TIPO_ERROR[this.CodigoTipoFunc]

            set {
                if !(value is Class) or (value != Err_ArgError and !value.HasBase(Err_ArgError)) {
                    m := "El tipo de error no es Err_ArgError"
                    throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m, , , , , , "TipoError", 1, value, Type(value))
                }

                this._tipoError := value
            }
        }

        Funcion {
            get => this._funcion

            set {
                if !_Err_AdmiteNumArgs(value, 1) {
                    m := "No has pasado una función u objeto llamable, o no admite 1 argumento"
                    throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m, , , , , , "Funcion", 1, value, Type(value))
                }

                this._funcion := value
            }
        }
    }




    /*** EXCEPCIONES PERSONALIZADAS ***/

    /*
        @class Err_Error

        @description Error padre del que heredan todos los errores.

        @todo Usar la versión privada de DefinirPropEstandar una vez se compruebe que funciona.
    */
    class Err_Error extends Error {
        static __New() {
            Err_ErroresPersonalizadosActivo := false

            this.ERRORES := Map("NULL", 0, "CORRECTO", 1, "ERROR", -1, "ARG", -2, "VALOR", -3, "VALOR_ARG", -4, "TIPO", -5, "TIPO_ARG", -6, "ARCHIVO", -7, "OBJETO", -8, "INDICE", -9, "FUNCION", -10, "FUNCION_ARG", -11, "NUM_ARGS", -12, "INDEF", -13, "PROP_INDEF", -14, "MIEMBRO_INDEF", -15, "METODO_INDEF", -16, "CLAVE_INDEF", -17, "MEMORIA", -18, "OS", -19, "VENTANA", -20, "TIEMPO_RESPUESTA", -21, "DIV0", -22)
            ; *** Si ACCIONES e INFO_CODIGO no se termina usando, quitarlo ***
            this.ACCIONES := Map("NULL", NULL, "CONTINUAR", 1, "PARAR_FUNCION", 2, "PARAR_PROGRAMA", 3)
            this.INFO_CODIGOS := Map(
                this.ERRORES["NULL"], Map("nombre", "NULL", "accion", this.ACCIONES["NULL"], "mensaje", NULL),
                this.ERRORES["CORRECTO"], Map("nombre", "CORRECTO", "accion", this.ACCIONES["CONTINUAR"], "mensaje", "Ejecución realizada correcta"),
                this.ERRORES["ERROR"], Map("nombre", "ERROR", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error"),
                this.ERRORES["ARG"], Map("nombre", "ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Argumento erróneo"),
                this.ERRORES["VALOR"], Map("nombre", "VALOR", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Valor erróneo"),
                this.ERRORES["VALOR_ARG"], Map("nombre", "VALOR_ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Valor de argumento erróneo"),
                this.ERRORES["TIPO"], Map("nombre", "TIPO", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato erróneo"),
                this.ERRORES["TIPO_ARG"], Map("nombre", "TIPO_ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato de argumento erróneo"),
                this.ERRORES["ARCHIVO"], Map("nombre", "ARCHIVO", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error al gestionar un archivo"),
                this.ERRORES["OBJETO"], Map("nombre", "OBJETO", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error al crear un objeto"),
                this.ERRORES["INDICE"], Map("nombre", "INDICE", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Índice erróneo o sin valor definido"),
                this.ERRORES["FUNCION"], Map("nombre", "FUNCION", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función"),
                this.ERRORES["FUNCION_ARG"], Map("nombre", "FUNCION_ARG", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función pasada por argumento"),
                this.ERRORES["NUM_ARGS"], Map("nombre", "NUM_ARGS", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Número incorrecto de argumentos pasados"),
                this.ERRORES["INDEF"], Map("nombre", "INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Valor no definido"),
                this.ERRORES["PROP_INDEF"], Map("nombre", "PROP_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "La propiedad no tiene ningún valor"),
                this.ERRORES["MIEMBRO_INDEF"], Map("nombre", "MIEMBRO_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "No existe el miembro"),
                this.ERRORES["METODO_INDEF"], Map("nombre", "METODO_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "No existe el método"),
                this.ERRORES["CLAVE_INDEF"], Map("nombre", "CLAVE_INDEF", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "No existe el elemento indexado por clave"),
                this.ERRORES["MEMORIA"], Map("nombre", "MEMORIA", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error de memoria"),
                this.ERRORES["OS"], Map("nombre", "OS", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error del S.O."),
                this.ERRORES["VENTANA"], Map("nombre", "VENTANA", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Error de ventana o de alguno de sus componentes"),
                this.ERRORES["TIEMPO_RESPUESTA"], Map("nombre", "TIEMPO_RESPUESTA", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "Tiempo de respuesta agotado"),
                this.ERRORES["DIV0"], Map("nombre", "DIV0", "accion", this.ACCIONES["PARAR_FUNCION"], "mensaje", "División por 0")
            )
        
            ; Se añaden las propiedades nuevas al prototipo de Err_Error

            S(s) => String(s)
            S.Mensaje := "Debes pasar una cadena o un valor convertible a cadena"
            S.TipoError := Err_FuncArgError
            this.Prototype.DefinePropEstandar("Message", S)
            ;this.Prototype.DefinePropEstandar("What", Es_String, , String, true) ; Mejor dejar What como está porque no se sabe muy bien qué formato admite
            this.Prototype.DefinePropEstandar("Extra", S)

            Entero(i) => Integer(i)
            Entero.TipoError := Err_FuncArgError
            ValidarCodigo(c) => this.ERRORES.ContieneValor(c)
            ValidarCodigo.Mensaje := "El código de error no está incluido en la lista de códigos"
            ValidarCodigo.TipoError := Err_ValorArgError
            this.Prototype.DefinePropEstandar("Codigo", Entero, ValidarCodigo)

            ValidarFecha(f) => FormatTime(f) != ""
            ValidarFecha.Mensaje := "La fecha no está en un formato válido YYYYMMDDHH24MISS"
            ValidarFecha.TipoError := Err_ValorArgError
            this.Prototype.DefinePropEstandar("Fecha", ValidarFecha, S)

            ComprobarError(e) => e is Error
            ComprobarError.Mensaje := "La excepción previa tiene que ser tipo Error"
            ComprobarError.TipoError := Err_TipoArgError
            this.Prototype.DefinePropEstandar("ErrorPrevio", ComprobarError)

            Err_ErroresPersonalizadosActivo := true
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
        __New(mensaje, what := ERR_FUNCION_ORIGEN["ACTUAL"], extra?, codigo := Err_Error.ERRORES["ERROR"], fecha := A_Now, errorPrevio?) {
            ; AHK no lanza un nuevo Error si falla la creación de super. Termina el programa evitando posibles bucles.
            super.__New(mensaje, what, extra?)
            Err_ErroresPersonalizadosActivo := false
            this.Codigo := codigo
            this.Fecha := fecha
            if IsSet(errorPrevio)
                this.ErrorPrevio := errorPrevio
            Err_ErroresPersonalizadosActivo := true
        }


        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String (no se muestra la pila Stack)

            @param {String} texto - Cadena a añadir al mensaje antes de los errores previos.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""
    
            texto := "[" FormatTime(this.Fecha, "dd/MM/yyyy HH:mm:ss] (") String(this.Codigo) ") " String(this.Message) ". " String(this.Extra) . texto "'r'n"
            try
                texto .= "Previo => " this.ErrorPrevio "'r'n"
            
            return texto
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
            Err_ErroresPersonalizadosActivo := false

            ; USO PRIVADO INTERNO EXCLUSIVAMENTE
            this._ERRORES_AHK := Map(MemoryError, {nombre: "MemoryError", codigo: super.ERRORES["MEMORIA"]}, OSError, {nombre: "OSError", codigo: super.ERRORES["OS"]}, TargetError, {nombre: "TargetError", codigo: super.ERRORES["VENTANA"]}, TimeOutError, {nombre: "TimeOutError", codigo: super.ERRORES["TIEMPO_RESPUESTA"]}, TypeError, {nombre: "TypeError", codigo: super.ERRORES["TIPO"]}, UnsetError, {nombre: "UnsetError", codigo: super.ERRORES["INDEF"]}, MemberError, {nombre: "MemberError", codigo: super.ERRORES["MIEMBRO_INDEF"]}, PropertyError, {nombre: "PropertyError", codigo: super.ERRORES["PROP_INDEF"]}, MethodError, {nombre: "MethodError", codigo: super.ERRORES["METODO_INDEF"]}, UnsetItemError, {nombre: "UnsetItemError", codigo: super.ERRORES["CLAVE_INDEF"]}, ValueError, {nombre: "ValueError", codigo: super.ERRORES["VALOR"]}, IndexError, {nombre: "IndexError", codigo: super.ERRORES["INDICE"]}, ZeroDivisionError, {nombre: "ZeroDivisionError", codigo: super.ERRORES["DIV0"]})

            for tipoErrorAHK in this._ERRORES_AHK
                if tipoErrorAHK.Base == Error
                    tipoErrorAHK.CambiarBase(this, Error)      

            Err_ErroresPersonalizadosActivo := true
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
            Err_ErroresPersonalizadosActivo := false

            ComprobarTipo(e) => e != Err_ErrorAHK and e.HasBase(Err_ErrorAHK)
            ComprobarTipo.Mensaje := "CrearError solo se puede usar desde los tipos de error predefinidos AHK herederos de Err_Error"
            ComprobarTipo.TipoError := Err_TipoArgError
            tipoErrorAHK := Err_VerificarArg_Prv(this, "this", 0, ComprobarTipo)

            excepcion := tipoErrorAHK(mensaje?, what, extra?)
            excepcion.Codigo := codigo ?? this._ERRORES_AHK[tipoErrorAHK].codigo
            excepcion.Fecha := fecha
            if IsSet(errorPrevio)
                excepcion.ErrorPrevio := errorPrevio

            Err_ErroresPersonalizadosActivo := true

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
            Err_ErroresPersonalizadosActivo := false

            VP(i) => i >= 0
            VP.Mensaje := "La posición del argumento debe ser entero >= 0 (0 para this)"
            VP.TipoError := Err_ValorArgError
            Entero(i) => Integer(i)
            Entero.TipoError := Err_FuncArgError
            this.Prototype.DefinePropEstandar("PosArg", Entero, VP)

            S(s) => String(s)
            S.Mensaje := "El nombre de argumento debe ser una cadena o convertible a cadena"
            S.TipoError := Err_FuncArgError
            this.Prototype.DefinePropEstandar("NombreArg", S)

            this.Prototype.DefinePropEstandar("ValorArg")

            Err_ErroresPersonalizadosActivo := true
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
            @param {Object} ValorArg - Valor del argumento involucrado en el error. Si no está definido, la propiedad ValorArg queda indefinida; si está definido se la guarda el valor.

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := Err_Error.ERRORES["ARG"], fecha?, errorPrevio?, nombreArg?, posArg?, valorArg?) {
            super.__New(mensaje, what, extra, codigo, fecha)

            Err_ErroresPersonalizadosActivo := false

            if IsSet(nombreArg)
                this.NombreArg := nombreArg
            if IsSet(posArg)
                this.PosArg := posArg
            if IsSet(posArg)
                this.ValorArg := valorArg

            Err_ErroresPersonalizadosActivo := true
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes de los errores previos.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""

            _texto := ". NombreArg: "
            try
                _texto .= this.NombreArg
            catch 
                _texto.= "<Sin nombre>"

            _texto .= ". #Arg: "
            try
                _texto .= this.PosArg
            catch
                _texto .= "<Sin posición>"

            _texto .= ". ValorArg: "
            try
                texto .= String(this.ValorArg)
            catch PropertyError
                texto .= " <Sin valor>"
            catch
                texto .= " <No imprimible>"

            return super.ToString(_texto . texto)
        }
    }

    class Err_TipoArgError extends Err_ArgError {
        static __New() {
            Err_ErroresPersonalizadosActivo := false

            S(s) => String(s)
            S.Mensaje := "El nombre de argumento debe ser una cadena o convertible a cadena"
            S.TipoError := Err_FuncArgError
            EsClase(s) => %String(s)% is Class
            EsClase.Mensaje := "La cadena tipo de dato no representa ninguna Clase"
            this.Prototype.DefinePropEstandar("TipoArg", Err_Cadena, Err_Clase)

            Err_ErroresPersonalizadosActivo := true
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
        __New(mensaje, what?, extra?, codigo := Err_Error.ERRORES["TIPO_ARG"], fecha?, errorPrevio?, nombreArg?, posArg?, valorArg?, tipoArg?) {
            super.__New(mensaje, what?, extra?, codigo, fecha?, nombreArg?, posArg?, valorArg?)
            Err_ErroresPersonalizadosActivo := false
            if IsSet(tipoArg)
                this.TipoArg := tipoArg
            Err_ErroresPersonalizadosActivo := true
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes de los errores previos.
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
            Err_ErroresPersonalizadosActivo := false
            Err_ErroresPersonalizadosActivo := true
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
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["VALOR_ARG"], fecha?, errorPrevio?, nombreArg?, posArg?, valorArg?) {
            super.__New(mensaje, what, extra, codigo, fecha, nombreArg, posArg)
            if IsSet(valorArg)
                this.ValorArg := valorArg           
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes de los errores previos.
        */
        ToString(texto?) {
            return super.ToString(texto)
        }
    }

    class Err_FuncArgError extends Err_ArgError {
    }

    class Err_FuncError extends Err_ErrorNoAHK {
        static __New() {
            Err_ErroresPersonalizadosActivo := false

            EsFunc(f) => f is Func
            EsFunc.Mensaje := "No has pasado una función relacionada con el error"
            this.Prototype.DefinePropEstandar("Funcion", EsFunc)

            Err_ErroresPersonalizadosActivo := true
        }

        /*
            @method Constructor

            @param {String} mensaje - Mensaje a guardar en la propiedad Message ya existente en la excepción.
            @param {String} what - Info a guardr rn la propiedad What ya existente en la excepción.
            @param {String} extra - Info extra a guardr rn la propiedad Extra ya existente en la excepción.
            @param {String} codigo - Código del tipo de error. Se deja String para dar la posiblida de introducir letras como código. Se guarda como nueva propiedad Codigo.
            @param {String} fecha - Fecha en formato YYYYMMDDHH24MISS. Se guarda como nueva propiedad Fecha.
            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.
            @param {Func} funcion - Función relacionada con el error.
            

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si la posición del argumento es < 1 o la fecha está en formato incorrecto.
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["FUNCION"], fecha?, errorPrevio?, funcion?) {
            super.__New(mensaje, what?, extra?, codigo, fecha?, errorPrevio?)

            Err_ErroresPersonalizadosActivo := false
            
            if IsSet(funcion)
                this.Funcion := funcion

            Err_ErroresPersonalizadosActivo := true
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes de los errores previos.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""
            try
                _texto := ". NombreFuncion: " this.Funcion.Name

            return super.ToString((_texto ?? "") . texto)
        }
    }

    class Err_NumArgsError extends Err_FuncError { 
        static __New() {
            Err_ErroresPersonalizadosActivo := false

            Vna(n) => n >= 0
            Vna.Mensaje := "El número de argumentos del error debe ser >= 0"
            this.Prototype.DefinePropEstandar("NumArgs", IsInteger, Vna, Integer)

            Err_ErroresPersonalizadosActivo := true
        }

        /*
            @method Constructor

            @param {Error} errorPrevio - Error previo que lanzó el sistema como causa del problema.

            @throws {TypeError} - Si los argumentos no tienen tipos correctos
            @throws {ValueError} - Si el número de argumentos no es un entero >= 0
        */
        __New(mensaje, what?, extra?, codigo := ERR_ERRORES["NUM_ARGS"], fecha?, errorPrevio?, funcion?, numArgs?) {
            super.__New(mensaje, what?, extra?, codigo, fecha?, errorPrevio?, funcion?)

            Err_ErroresPersonalizadosActivo := false
            
            if IsSet(numArgs)
                this.NumArgs := numArgs

            Err_ErroresPersonalizadosActivo := true
        }

        /*
            @method ToString

            @description Convertir la información de la excepción a una cadena String.

            @param {String} texto - Cadena a añadir al mensaje antes de los errores previos.
        */
        ToString(texto?) {
            texto := IsSet(texto) ? ". " Err_VerificarArg_Prv(texto, "texto", 1, , , String) : ""

            try
                _texto := ". NumArgs: " this.NumArgs

            return super.ToString((_texto ?? "") . texto)
        }
    }

    class Err_EnumeratorError extends Err_FuncError {
    }

    class Err_ObjetoError extends Err_ErrorNoAHK {
    }
   


