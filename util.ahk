/*
    Librería con utilidades.

    @todo 
        - Incluir los mensajes de log en esta librería. Quizás esto no es necesario y los mensajes de log los registra quien usa esta librería, como testing.
        - Tener en cuenta que en todas las funciones donde se admite un enumerator o un objeto con método __Enum que devuelve un Enumerator para ser recorrido hay un agujero de seguridad, ya que se va a llamar a una función repetidamente en un bucle sin saber qué puede hacer dicha función. No se soluciona restringiendo los argumentos a tipos Map o Array, ya que se puede redefinir el método __Enum en el prototipo de esas clases y seguiría llamándose a la función que quiere el llamante.
        - Las funciones que luego se definen como métodos y reciben como primer argumento el objeto this, la comprobación de dicho this es redundante para los métodos. Se podría hacer una función sin la comprobación de errores del primer argumento, y definir ésa como método para el prototipo. Y luego hacer otra función que cuomprueba el primer argumento y luego llama a ese método para ese argumento, a modo de envoltorio.
        - Que MapOrdenado se pueda ordenar por claves o por valores. Solo hay que comparar los valores en lugar de las claves al ordenar.
        - Hacer ToString en las nuevas clases.
        - Cambiar las llamadas a Err_Lanzar venga de capturar una expeción para relanzarla. Si además capturo una excepción que he lanzado yo desde mi código no hace falta volver a meter el código de error como argumento.
        - Hace un módulo de testing por cada librería, donde se pruebe cada función.

        Pasos:
        - Funciones definir propiedades genérica
        - Acabar los errores personalizados.
        - Adaptar Util y error a los errores personalizados.
        - Funcion MergeSort, MapORdenado y  MapPrioridades.
        - Probar debug.
        - Hacer testing de todo usando debug.
        - Acabar config
        - Refactorizar código dataprotector
        

*/

#Requires AutoHotkey v2.0

#Include "error.ahk"


if (!IsSet(__UTIL_H__)) {
    global __UTIL_H__ := true

    /*
        @function Util_CrearVarRef

        @description Obtener la referencia a una variable sin necesidad de definir la variable manualmente en el código, ya que no se permite usar %"nombre_variable"% := 0 para definir variables de manera dinámica. 

        @returns {VarRef} Referencia a la variable. Para acceder al contenido usar el valor devuelto en %valor%
    */
    _Util_CrearVarRef() {
        variable := NULL
        return &variable
    }

    global Util_CrearVarRef := _Util_CrearVarRef


    /*
        @function Util_Llamante

        @description Obtener el nombre de la función llamante de la actual que llama a esta propia función.

        @returns Nombre de la función llamante de la actual.
    */
    _Util_Llamante() {
        try {
            throw Error(, ERR_FUNCION_ORIGEN["PADRE_LLAMANTE"])
        }
        catch Error as e {
           return e.What
        }
    }

    global Util_Llamante := _Util_Llamante


    /*
        @function Util_VerificarArg

    */
    _Util_VerificarArg(valorArg, nombreArg, posArg?, comprobarTipo?, validarValor?, convertirValor?, erroresAHK := false) {
        if Util_Llamante() != "_Util_VerificarArg" {
            if IsSet(nombreArg)
                _Util_VerificarArg(nombreArg, "nombreArg", 2, EsString(s) => Err_EsCadena(s), , String, erroresAHK)
            if IsSet(posArg)
                _Util_VerificarArg(posArg, "posArg", 3, IsInteger, Entero_mayor_que_1(v) => v >= 1, , erroresAHK)
            if IsSet(comprobarTipo)
                _Util_VerificarArg(comprobarTipo, "comprobarTipo", 4, EsFuncion(f) => f is Func, , , erroresAHK)
            _Util_VerificarArg(validarValor, "validarValor", 5, EsFuncion, , , erroresAHK)
            _Util_VerificarArg(validarValor, "convertirValor", 5, EsFuncion, , , erroresAHK)
        }

        if IsSet(comprobarTipo) and !comprobarTipo(valorArg) {
            mensaje := "(" ERR_ERRORES["ERR_TIPO_ARG"] ") El tipo del valor no cumple " comprobarTipo.Name
            throw !erroresAHK ? Err_TipoArgError(mensaje, , , , , , nombreArg, posArg, Type(valorArg)) : Err_Error.ExtenderErr(TypeError(mensaje), , , ERR_ERRORES["ERR_TIPO_ARG"])
        }
        else if IsSet(validarValor) and !validarValor(valorArg) {
            mensaje := "(" ERR_ERRORES["ERR_VALOR_ARG"] ") El valor no cumple la validación de " validarValor.Name
            throw !erroresAHK ? Err_ValorArgError(mensaje, , , , , , nombreArg, posArg, valorArg) : Err_Error.ExtenderErr(ValueError(mensaje), , , ERR_ERRORES["ERR_VALOR_ARG"])
        }

        return IsSet(convertirValor) ? convertirValor(valorArg) : valorArg

    }

    global Util_VerificarArg := _Util_VerificarArg


    /*
        @function Util_DefinePropEstandar

        @description Definir una propiedad dinámica con sus métodos get y set que gestionará una propiedad valor interna. 
        - Get lanzará PropertyError si el valor interno no ha sido definido. 
        - Set guardará el valor, previamente comprobado el tipo y el valor, convirtíendolo a otro valor. Lanza TypeError/Err_TipoArgError si el valor no es el tipo correcto; ValueError/Err_ValorError si el valor no pasa validación.

        @param {String} prop - Nombre de la propiedad.
        @param {Func} comprobarTipo - Función que devolverá true o false si el valor no es del tipo correcto. NOTA: No se comprueba si lanza algún error.
        @param {Func} validarValor - Función que devolverá true o false si el valor no es valido. Esta función supone que el tipo del valor es el correcto. NOTA: No se comprueba si lanza algún error.
        @param {Func} convertirValor - Función que devolverá el valor convertido. Esta función supone que el tipo del valor es el correcto y que pasa la validación. NOTA: No se comprueba si lanza algún error.
        @param {Boolean} erroresAHK - Si se desea que el método lance solo errores predefinidos.

        @throws {TypeError/Err_TipoArgError} - Si los argumentos no son de tipo correcto.
    */
    _Util_DefinePropEstandarM(obj, prop, comprobarTipo?, validarValor?, convertirValor?, erroresAHK := false) {
        if !Err_EsCadena(prop) 
            argumento := Map("nombre", "prop", "numero", 2, "tipo", "String", "error", ERR_ERRORES["ERR_TIPO_ARG"])
        else if IsSet(comprobarTipo) {
            if !(comprobarTipo is Func)
                argumento := Map("nombre", "comprobarTipo", "numero", 3, "tipo", "Func", "error", ERR_ERRORES["ERR_TIPO_ARG"])
            else {
                /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo comprueba el tipo de un valor sin lanzar excepciones */
            }
        }
        if !IsSet(argumento) and IsSet(validarValor) {
            if !(validarValor is Func)
                argumento := Map("nombre", "validarValor", "numero", 4, "tipo", "Func", "error", ERR_ERRORES["ERR_TIPO_ARG"])
            else {
                /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo comprueba el valor suponiendo que el tipo ha sido ya comprobado anteriormente, sin lanzar excepciones */
            }
        }
        if !IsSet(argumento) and IsSet(convertirValor) {
            if !(convertirValor is Func)
                argumento := Map("nombre", "convertirValor", "numero", 5, "tipo", "Func", "error", ERR_ERRORES["ERR_TIPO_ARG"])
            else {
                /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo convierte el valor, sin lanzar excepciones, suponiendo que el tipo y el valor han sido comprobados anteriormente */
            }
        }

        if IsSet(argumento) {
            switch argumento["error"] {
                case ERR_ERRORES["ERR_TIPO_ARG"]:
                    mensaje := "(" argumento["error"] ") El argumento " argumento["nombre"] " debe ser " argumento["tipo"] 
                    throw !erroresAHK ? Err_TipoArgError(mensaje, , , , , , argumento["nombre"], argumento["numero"], Type(prop)) : Err_Error.ExtenderErr(Type(mensaje), , , argumento["error"])

                /* Si la verificación de las funciones generan otros errores se considerarían aquí */
            }
        }

        _Get(_obj) {
            if !_obj.HasProp(%"_" prop%)
                throw Err_Error.ExtenderErr(PropertyError("La propiedad " prop " no tiene ningún valor"), , , ERR_ERRORES["ERR_PROP_INDEF"]) 
            
            return _obj.%"_" prop%
        }

        _Set(_obj, valor) {
            if IsSet(comprobarTipo) and !comprobarTipo(valor) {
                mensaje := "(" ERR_ERRORES["ERR_TIPO_ARG"] ") El tipo del valor no cumple " comprobarTipo.Name
                throw !erroresAHK ? Err_TipoArgError(mensaje, , , , , , "value", 2, Type(valor)) : Err_Error.ExtenderErr(TypeError(mensaje), , , ERR_ERRORES["ERR_TIPO_ARG"])
            }
            else if IsSet(comprobarTipo) and !validarValor(valor) {
                mensaje := "(" ERR_ERRORES["ERR_VALOR_ARG"] ") El valor no cumple la validación de " validarValor.Name
                throw !erroresAHK ? Err_ValorArgError(mensaje, , , , , , "value", 2, valor) : Err_Error.ExtenderErr(ValueError(mensaje), , , ERR_ERRORES["ERR_VALOR_ARG"])
            }

            return (_obj.%"_" prop% := IsSet(convertirValor) ? convertirValor(valor) : valor)
        }

        obj.DefineProp(prop, {Get: _Get, Set: _Set})
    }

    _Util_DefinePropEstandar(obj, prop, comprobarTipo?, validarValor?, convertirValor?) {
        if !(obj is Object)
            throw Err_TipoArgError("(" ERR_ERRORES["ERR_TIPO_ARG"] ") Debes pasar un Object para definir la nueva propiedad", , , ERR_ERRORES["ERR_TIPO_ARG"], , , "obj", 1, Type(obj))

        return obj.DefinePropEstandar(prop, comprobarTipo, validarValor, convertirValor)
    }

    ; Se añade como método a Object
    Object.Prototype.DefineProp("DefinePropEstandar", {Call: _Util_DefinePropEstandarM})
    global Util_DefinePropEstandar := _Util_DefinePropEstandar


    /*
        @function Util_DefinePropEntero

        @description Definir una propiedad dinámica con sus métodos get y set que gestionará una propiedad valor interna de tipo entero. 
        - Get devolverá "" si el valor cadena interno no ha sido definido. 
        - Set guardará el valor comprobando que es una cadena y pasa un filtro (opcional). Lanza MethodError/Err_TipoArgError si el valor no es cadena o convertible a String; ValueError/Err_ValorError si el valor no pasa el filtro; cualquier otro error predefinido/Err_FuncError si existe algún error al llamar a filtro(value)

        @param {String} prop - Nombre de la propiedad.
        @param {Func} filtro - Función filtro que se aplica al valor a ser guardado en la propiedad dentro de Set. El nombre de la función debe ser descriptivo ya que aparecerá en el mensaje de error. Devolverá true o false dependiendo si el valor pasa el filtro o no.
        @param {Boolean} erroresAHK - Si se desea que el método lance solo errores predefinidos.

        @throws {MethodError/Err_TipoArgError} - Si la propiedad no es String o convertible a String
        @throws {TypeError/Err_TipoArgError} - Si el filtro no es una función
        */
    _Util_DefinePropEnteroM(obj, prop, filtro?, erroresAHK := false) {
        try {
            prop := String(prop)                
        }
        catch as e {
            mensaje := "(" ERR_ERRORES["ERR_TIPO_ARG"] ") El nombre de la propiedad debe ser String (o convertible a String)"
            throw !erroresAHK ? Err_TipoArgError(mensaje, , , , , e, "prop", 2, Type(prop)) : Err_Error.ExtenderErr(e, mensaje, , ERR_ERRORES["ERR_TIPO_ARG"])
        }

        if IsSet(filtro) 
            if !(filtro is Func) {
                mensaje := "(" ERR_ERRORES["ERR_TIPO_ARG"] ") El filtro debe ser una función"
                throw !erroresAHK ? Err_TipoArgError(mensaje, , , , , , "filtro", 3, Type(filtro)) : Err_Error.ExtenderErr(TypeError(mensaje), , , ERR_ERRORES["ERR_TIPO_ARG"])
            }
            else {
                /* Aquí se verificaría la función para comprobar que no es maliciosa */
            }
    
        _Get(_obj) {
            if !_obj.HasProp(%"_" prop%)
                throw Err_Error.ExtenderErr(PropertyError("La propiedad " prop " no tiene ningún valor"), , , ERR_ERRORES["ERR_PROP_INDEF"]) 
            
            return _obj.%"_" prop%
        }

        _Set(_obj, valor) {
            if !IsInteger(valor) {
                mensaje := "(" ERR_ERRORES["ERR_TIPO_ARG"] ") El valor de " prop " debe ser Entero (o convertible a Integer)"
                throw !erroresAHK ? Err_TipoArgError(mensaje, , , , , e, "value", 2, Type(valor)) : Err_Error.ExtenderErr(TypeError(mensaje), , , ERR_ERRORES["ERR_TIPO_ARG"])
            }
   
            if IsSet(filtro) {
                try {
                    if !filtro(valor) {
                        mensaje := "(" ERR_ERRORES["ERR_VALOR_ARG"] ") El valor de " prop " no pasa el filtro " filtro.Name
                        throw !erroresAHK ? Err_ValorArgError(mensaje, , , , , , "value", 2, valor) : Err_Error.ExtenderErr(ValueError(mensaje), , , ERR_ERRORES["ERR_VALOR_ARG"])
                    }
                }
                catch as e {
                    mensaje := "(" ERR_ERRORES["ERR_FUNCION_ARG"] ") La función " filtro.Name " pasada por filtro ha generado un error"
                    throw !erroresAHK ? Err_FuncError(mensaje, , , , , e, filtro.Name) : Err_Error.ExtenderErr(e, mensaje, , ERR_ERRORES["ERR_FUNCION"]) 
                }
            }

            _obj.%"_" prop% := Integer(valor)
        }

        obj.DefineProp(prop, {Get: _Get, Set: _Set})
    }

    _Util_DefinePropCadena(obj, prop, filtro?) {
        if !(obj is Object)
            throw Err_TipoArgError("(" ERR_ERRORES["ERR_TIPO_ARG"] ") Debes pasar un Object para definir la nueva propiedad", , , ERR_ERRORES["ERR_TIPO_ARG"], , , "obj", 1, Type(obj))

        return obj.DefinePropCadena(prop, filtro)
    }

    ; Se añade como método a Object
    Object.Prototype.DefineProp("DefinePropCadena", {Call: _Util_DefinePropCadenaM})
    global Util_DefinePropCadena := _Util_DefinePropCadena

    
    /*
        @function Util_AmpliarArgs

        @description Envolver a una función en otra para recibir más argumentos de los que realmente admite, de los cuales solo se elegirán los deseados que se pasarán en orden a la función real. 

        @param {Array} flagArgs - Array de Boolean, uno por cada argumento en orden que recibirá la función envoltorio. Si es true, el argumento se pasará a la función real; si es false, ese argumento no se pasará. El número de elementos debe ser igual o mayor al número de argumentos que se pasará a la función envoltorio. Los argumentos no considerados por flagArgs serán ignorados.

        @throws {TypeError} - Si los tipos de los argumentos son erróneos.
        @throws {ErrorNumArgumentos} - (Lanzado por la función resultante envoltorio) Si el número de flags es mayor que el número de argumentos recibidos.

        @returns {Func} - Función envoltorio que podrá recibir los argumentos ampliados.
    */
    _Util_AmpliarArgsM(funcion, filtro) {
        _Funcion(args*) {
            if args.Length < flagArgs.Length
                Err_Lanzar(ErrorNumArgumentos, "Número de argumentos insuficientes para ser filtrados", ERR_ERRORES["ERR_NUM_ARGS"], A_LineNumber)

            _args := []
            for flag in flagArgs
                if flag {
                    _args.Length++
                    if args.Has(A_Index)
                        _args[-1] := args[A_Index]
                }

            if !funcion.AdmiteNumArgs(_args.Length)
                Err_Lanzar(ErrorNumArgumentos, "La función no admite ", _args.Length " argumentos" ERR_ERRORES["ERR_NUM_ARGS"], A_LineNumber)

            return funcion(_args*)
        }

        return _Funcion
    }

    _Util_AmpliarArgs(funcion, filtro) {
        if !(funcion is Func)
            Err_Lanzar(TypeError, "El argumento filtro no es un Func", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        return _Util_AmpliarArgsM(funcion, filtro)
    }

    ; Se añade como método a Map, Array y Enumerator
    Func.Prototype.DefineProp("AmpliarArgs", {Call: _Util_AmpliarArgsM})
    global Util_AmpliarArgs := _Util_AmpliarArgs


    /*
        @function Util_AmpliarArgs

        @description Envolver a una función para que reciba llamadas con menos argumentos de los que realmente admite, eligiendo la posición en orden donde irán en la llamada a la función real. 

        @param {Array} flagArgs - Array de Boolean, uno por cada argumento en orden que recibirá la llamada a la función real. Si es true, ese argumento se pasará a la función real; si es false, ese argumento no se pasará. El número de elementos debe ser igual o mayor al número de argumentos que se pasará a la función envoltorio. Los argumentos no considerados por flagArgs serán ignorados.

        @returns {Func} - Función envoltorio que podrá recibir los argumentos ampliados.
    */
    Util_ReducirArgs(funcion, flagArgs*) {
        if !Err_EsFuncion(funcion)
            Err_Lanzar(TypeError, "El argumento filtro no es un Func", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        if !(flagArgs is Array) or flagArgs.Length == 0
            Err_Lanzar(TypeError, "Debes pasar un Array no vacío de valores Boolean", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        _Funcion(args*) {
            if args.Length < flagArgs.Length
                Err_Lanzar(ErrorNumArgumentos, "Número de argumentos insuficientes", ERR_ERRORES["ERR_NUM_ARGS"], A_LineNumber)

            _args := []
            for flag in flagArgs
                if flag {
                    _args.Length++
                    if args.Has(A_Index)
                        _args[-1] := args[A_Index]
                }

            return funcion(_args*)
        }

        return _Funcion
    }

        

    /*
        @function Util_SubLista

        @description Obtener una sublista formada con los elementos de una lista (índices enumerados a partir de 1) que cumplan la condición de la funcion filtro. La lista debe ser un Array en caso de ser modificada. Si no va a ser modificada, la lista debe comportarse como un Array al iterar sobre ella (si solo se itera sobre un argumento, obtener cada valor y no el índice).

        @param {Array} lista - Lista de la cual obtener la sublista
        @param {Func} filtro - Función condición que recibirá el índice y valor de cada elemento. Devolverá true o false si cumple o no la condición. 
        @param {Boolean} modificar - Si true modifica la lista pasada como argumento dejándola como la sublista. Si false, deja la lista original intacta.

        @returns {Array} - Sublista con los valores obtenidos. Si modificar es true devuelve la misma lista pasada por argumento modificada. Si es false, devuelve una nueva lista.

        @throws {TypeError} - Si los tipos de los argumentos no son correctos.
        @throws {ErrorEnumerator} - Si lista no puede generar un Enumerator correcto a ser recorrido.
        @throws {ErrorFuncion} - Si filtro genera algún error al ser ejecutado.
        @throws {Error} - Si ocurre algún otro error.

        @todo Cuando se filtra por índice al modificar la lista, el valor obtenido en cada iteración no se usa en ningún momento y se pasa a filtro para nada. También a filtro se pasa índice inútilmente cuando se filtra por valor. El coste de solucionarlo consiste en escribir mucho más código con bucles for y llamadas a filtro específicas para cada caso, que por ahora no creo que compense.
    */
    Util_SubLista(lista, filtro, modificar := false) {
        try
            admiteNumArgs := Err_AdmiteNumArgs(filtro, 2)
        catch TypeError as e
            Err_Lanzar(e, "Argumento filtro no es una función válida")
        else if !admiteNumArgs
            Err_Lanzar(TypeError, "Argumento filtro no admite argumentos índice y valor", ERR_ERRORES["ERR_NUM_ARGS"])

        if modificar {
            if !(lista is Array)
                Err_Lanzar(TypeError, "El argumento lista no es un Array", ERR_ERRORES["ERR_ARG"], A_LineNumber)
            
            try
                _enum := Err_VerificarEnumerator(lista.Clone(), 2)
            catch as e {
                e := e.Clonar(ErrorEnumerator)
                Err_Lanzar(e, "La lista no se admite como un Enumerator válido")                
            }

            removidos := 0
            for i, valor in _enum 
                try 
                    if !filtro(i, valor) {
                        lista.RemoveAt(i-removidos)
                        removidos++
                    }
                catch as e {
                    e := e.Clonar(ErrorFuncio)
                    Err_Lanzar(e, "Error en la función filtro: " e.Message, ERR_ERRORES["ERR_FUNCION"], A_LineNumber)                            
                }
        }
        else {
            try
                _enum := Err_VerificarEnumerator(lista, 1)
            catch as e
                Err_Lanzar(e, "Argumento lista no se admite como un Enumerator válido")
            
            lista := Array()

            ; Usando A_Index evitamos el problema de un Enumerator con un solo argumento
            for valor in _enum
                try
                    if filtro(A_Index, valor)
                        lista.Push(valor)
                catch as e
                    Err_Lanzar(e, "Error en la función filtro: " e.Message, ERR_ERRORES["ERR_FUNCION"], A_LineNumber)                            
        }

        return lista
    }



    /*
        @function Util_SubMap

        @description Obtener un submap formado con los elementos de un diccionario que cumplan la condición de la funcion filtro. La lista debe ser un Map en caso de ser modificada. Si no va a ser modificada, la lista debe comportarse como un Map al iterar sobre ella, considerando clave y valor.

        @param {Map} dicc - Map de la cual obtener el diccionario.
        @param {Func} filtro - Función condición que recibirá la clave y valor de cada elemento. Devolverá true o false si cumple o no la condición. 
        @param {Boolean} modificar - Si true modifica el diccionario pasado como argumento dejándolo como el submap. Si false, deja el map original intacto.

        @returns {Map} - Submap con los valores obtenidos. Si modificar es true devuelve el mismo map pasado por argumento modificado. Si es false, devuelve un nuevo map.

        @throws {TypeError} - Si los tipos de los argumentos no son correctos.
        @throws {Error} - Si ocurre algún otro error.

        @todo Cuando se filtra por clave al modificar el diccionario, el valor obtenido en cada iteración no se usa en ningún momento y se pasa a filtro para nada. También a filtro se pasa clave inútilmente cuando se filtra por valor. El coste de solucionarlo consiste en escribir mucho más código con bucles for y llamadas a filtro específicas para cada caso, que por ahora no creo que compense.
    */
    Util_SubMap(dicc, filtro, modificar := false) {
        try
            admiteNumArgs := Err_AdmiteNumArgs(filtro, 2)
        catch TypeError as e
            Err_Lanzar(e, "Argumento filtro no es una función válida")
        else if !admiteNumArgs
            Err_Lanzar(TypeError, "Argumento filtro no admite argumentos clave y valor")
 
        if modificar {
            if !(dicc is Map)
                Err_Lanzar(TypeError, "El argumento dicc no es un Map", ERR_ERRORES["ERR_ARG"], A_LineNumber)
            
            try
                _enum := Err_VerificarEnumerator(dicc.Clone(), 2)
            catch as e
                Err_Lanzar(e, "El diccionario no puede ser usado como un Enumerator válido")

            for clave, valor in _enum 
                try
                    if !filtro(clave, valor)
                        dicc.Delete(clave)
                catch as e
                    Err_Lanzar(e, "Error en la función filtro: " e.Message, ERR_ERRORES["ERR_FUNCION"], A_LineNumber)                            
        }
        else {          
            try
                _enum := Err_VerificarEnumerator(dicc, 2)
            catch as e
                Err_Lanzar(e, "El diccionario no puede ser usado como un Enumerator válido")

            dicc := Map()

            for clave, valor in _enum
                try
                    if filtro(clave, valor)
                        dicc[clave] := valor
                catch as e
                    Err_Lanzar(e, "Error en la función filtro: " e.Message, ERR_ERRORES["ERR_FUNCION"], A_LineNumber)                            
        }

        return dicc
    }
        

    /*
        @function Util_EnumerableACadena
        
        @description Obtener una cadena a partir de los valores de objeto enumerable <__Enum> o Enumerator.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable cuyos valores se van a convertir a una cadena.
        @param {Boolean} numArgs - Número de argumentos que admitirá el enumerable.
        @param {String} sepGrupo - cadena para separar los grupos de valores obtenidos en cada llamada al enumerable. Separador entre entradas.
        @param {String} sepPartes - cadena para separar cada uno de los valores obtenidos en una llamada al enumerable. Separador entre elementos de una entrada. Si numArgs == 1 se ignora.

        @throws {TypeError} - Si los tipos de los argumentos no son correctos.

        @returns {String} Devuelve un String de los valores de la lista convertidos a cadena..
    */
    _Util_EnumerableACadena(enum, numArgs, sepGrupo := ";", sepPartes := ":") {
        try {
            sepGrupo := String(sepGrupo)
            sepPartes := String(sepPartes)
        }
        catch as e
            throw Err_Error.ExtenderErr(e, "Los separadores deben de ser una cadena", , ERR_ERRORES["ERR_TIPO_ARG"])
        
        /**/ */
        if !IsInteger(posArg) or (posArg := Integer(posArg) < 1)
            throw ValueError("(" ERR_ERRORES["ERR_VALOR_ARG"] ") El número del argumento debe ser un entero >= 1")


        cadena := ""

        try {
            if mostrarClaves {
                for clave, valor in enum {
                    indice := clave
                    cadena .= String(clave) separadorClave " " (IsSet(valor) ? String(valor) : "") separador " "
                }
            }
            else {
                for i, valor in enum {
                    indice := i
                    cadena .= IsSet(valor) ? String(valor) separador " " : ""
                }
            }
        }
        catch TypeError as e
            Err_Lanzar(e, "El argumento enum debe ser enumerable (Object<__Enum> o Enumerator)", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        catch MethodError as e
            Err_Lanzar(e, "El valor índice " indice " de la lista no puede convertirse a String", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        catch as e {
            try
                for valor in enum
                    cadena .= (IsSet(valor) ? String(valor) : "") separador " "
            catch MethodError as e
                Err_Lanzar(e, "Un valor de la lista no puede convertirse a String", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        }
        
        return RTrim(cadena, separador " ")
    }
    
    ; Se añade como método a Map, Array y Enumerator
    Enumerator.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadena})
    Array.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadena})
    Map.Prototype.DefineProp("ToString", {Call: (e, n?, s?, sc?) =>_Util_EnumerableACadena(e, m, s?, sc?)})
    global Util_EnumerableACadena := _Util_EnumerableACadena
  

    /*
        @function Util_ObtenerClaves
        
        @description Obtener las claves o índices de un objeto enumerable <__Enum> o Enumerator asociadas con valores definidos. Si se pasa un valor, obtiene las claves asociadas con ese único valor. Clave (1º argumento) y Valor (2º argumento) del enumerable.

        @param {*} valor - valor a obtener sus claves. Si no se pasa se obtienen todas las claves que tengan algún valor definido.
        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable de donde obtener las claves.

        @throws {TypeError} - Si el tipos del argumentos no es correcto.
        @throws {¿Error?} - Si la función enumerable no admite dos argumentos clave-valor.

        @returns {Array} - Array de claves obtenidas
    */
    _Util_ObtenerClaves(enum, valor?) {
        claves := []
        try {
            if (IsSet(valor)) {
                for clave, _valor in enum 
                    if IsSet(_valor) and (_valor == valor)
                        claves.Push(clave)
            }
            else {
                for clave, _valor in enum
                    if IsSet(_valor)
                        claves.Push(clave)
            }
        }
        catch TypeError as e
            Err_Lanzar(e, "El argumento enum debe ser Enumerator o tener función __Enum y que ésta devuelva un Enumerator", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        catch as e
            Err_Lanzar(e, "El enumerator de enum no admite dos parámetros clave-valor", ERR_ERRORES["ERR_NUM_ARGS"], A_LineNumber)

        return claves
    }

    ; Se añade como método a Map y Array
    Map.Prototype.DefineProp("Claves", {Call: _Util_ObtenerClaves})
    Array.Prototype.DefineProp("IndicesConValor", {Call: _Util_ObtenerClaves})
    global Util_ObtenerClaves := _Util_ObtenerClaves


    /*
        @function Util_OrdenarArray
    */
    _Util_OrdenarArray(lista, comparar, asc := true, modificar := false) {
        if !(lista is Array)        
            Err_Lanzar(TypeError, "El argumento lista no es un Array", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        if lista.Length <= 1
            return modificar ? lista : lista.Clone()


    }


    /*
        @class Util_MapOrdenado

        @description 

    */
    class Util_MapOrden extends Map {

        __New(comparar := (a, b) => StrCompare(String(a), String(b), true), asc := true, args*) {
            if !(comparar is Func)
                Err_Lanzar(TypeError, "El argumento comparar no es una función", ERR_ERRORES["ERR_ARG"], A_LineNumber)

            super._New(args*)
            this._claves := this.Claves
            this._comparar := comparar
            this._asc := asc

        }

        Set(args*) {
            super.Set(args*)
        }

        ToString() {
            
        }
    }

    /*
        @class 
    */
    class Util_MapValorPrioritario extends Map {
        /*
            @method Constructor

            @param {Array|Map|Object} args - lista variable de argumentos formado por los pares clave - valor, similar a los argumentos pasados a un Map. Valor puede ser uno de los siguientes tipos:
            - {Array} - 
            - {Map} - 
            - {Object} - 
            La diferencia con Map es que valor será un array de valores ordenados por prioridad de menor a mayor (menor a mayor índice). Si valor no es un Array, se crea uno con el valor como único elemento. Si valor no está definido, se crea como valor un array vacío.

            @throws Propaga los errores que pueda lanzar Map al crear el diccionario.
        */
        __New(args*) {
            for i, valor in args() { ; Probar OwnProps()
                if Mod(i, 2) != 0
                    continue

                if IsSet(valor)
                    args[i] := Type(valor) != "Array" ? Array(valor) : valor.Clone()
                else
                    args[i] := Array()

            }

            super.__New(args*)
        }


        /*
            @property __Item

            @param {Integer|String|Object} clave - clave de acceso a una entrada de Map.
            @param {Integer} indice - índice del array para acceder a uno de los valores. A mayor índice mayor prioridad. Si está indefinido se obtiene el valor del índice más alto (mayor prioridad).

            @method
                get -
        */
        __Item[clave, indice?, maxValor?] {
            get {
                if IsSet(indice) {

                }
                if IsSet(indice) {
                    super[clave][indice]
                }

            }

            set {

            }
        }

        ToString() {

        }
    }


    /*
        @function Util_ContieneValor
        @description Comprueba si un elemento está dentro de los valores de un objeto enumerable (Enumerator u objeto con método __Enum). En caso de admitir el enum dos argumentos, como Map o Array, comprueba los valores (2º argumento) y no las claves o índices.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable donde comprobar el valor
        @param {Any} valor - valor a comprobar si está dentro del enum.

        @returns {Boolean} - true o false si el elemento está o no dentro de la lista.

        @throws {TypeError} - Si el argumento enum no es un objeto Enumerable o __Enum

        @todo Comprobar el tipo concreto de excepción que lanza el for en los siguientes casos:
        - El argumento enum no ser enumerable.
        - En caso de ser enumerable no admitir dos argumentos.
    */
    _Util_ContieneValor(enum, valor) {
        try {
            for , _valor in enum 
                if IsSet(_valor) and (_valor == valor)
                    return true
        }
        ; TypeError se captura si enum no es Enumerator, no tiene función __Enum o ésta no devuelve Enumerator
        catch TypeError as e {
            Err_Lanzar(e, "El argumento enum debe ser Enumerator o tener función __Enum y que devuelva Enumerator", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        }
        ; Aquí solo debe entrar porque enum no admite dos argumentos.
        catch {
            ; Este bucle ya no debe lanzar más excepciones porque, en teoría, no hay excepciones en ahk por comparar tipos distintos.
            for _valor in enum 
                if IsSet(_valor) and (_valor == valor)
                    return true
        }

        return false
    }

    ; Se añade Util_ContieneValor como método a Map y Array
    Enumerator.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Map.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Array.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    global Util_ContieneValor := _Util_ContieneValor
   
}

