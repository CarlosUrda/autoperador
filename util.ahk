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

/* En lugar del include se llamaría (dentro de Util??) a la función del módulo para ejecutarla, y solo se ejecutaría en teoría una vez si está en la librería */
#Include "error.ahk"

;if (!IsSet(__UTIL_H__)) {
;    global __UTIL_H__ := true

Util() {
    static ejecutado := false
    if ejecutado
        return
    ejecutado := true

    /*
        @function Util_Clase

        @description Obtener el objeto Clase del tipo de un objeto. Es decir, el objeto Clase a partir de la cual, gracias a su prototipo, se creó la instancia del objeto.

        @throws {TypeError} - Si el tipo del valor no es una clase, o es una clase cuyo prototipo no coincide con la base prototipo del valor. Es decir, que el valor no se creó a partir del prototipo de su tipo clase.

        @returns {Class} - Objeto Clase tipo del objeto.
    */
    Util_Clase(valor) {
        try 
            clase := %Type(valor)%

        if !IsSet(clase) or !(clase is Class)
            throw Err_Error.ExtenderErr(TypeError("El tipo del valor no es una Clase"))
        if clase.Prototype != valor.Base
            throw Err_Error.ExtenderErr(TypeError("El prototipo de la clase tipo no coincide con la base prototipo del valor. Es decir, el objeto no se creó a partir del prototipo del tipo clase."))

        return clase
    }

    Object.Prototype.DefineProp("Clase", {Call: Util_Clase})


    /*
        @function Util_EsBase_Prv

        @description Saber si un objeto clase es ancestro (se hereda de él). Esta función no verifica los argumentos, por lo que SOLO DEBE SER USADA INTERNAMENTE POR MOTIVOS DE SEGURIDAD.

        @param {Class} clase - Clase a partir de la cual comprobar si otra clase es ancestro.
        @param {Class} ancestro - Clase a comprobar si es ancestro de clase.

        @returns {Boolean} - Devuelve true o false si es ancestro o no.
    */
    _Util_EsBase_Prv(clase, baseRaiz) {
        if clase == baseRaiz or baseRaiz.Base == clase
            return false

        while (clase := clase.Base) != baseRaiz
            if clase == Any
                return false

        return true
    }

    /*
        @function Util_EsBase

        @description Saber si un objeto clase es ancestro (se hereda de él).

        @param {Class} clase - Clase a partir de la cual comprobar si otra clase es ancestro.
        @param {Class} baseRaiz - Clase a comprobar si es ancestro de clase.

        @returns {Boolean} - Devuelve true o false si es ancestro o no.        
    */
    _Util_EsBaseM(clase, baseRaiz) {
        Err_VerificarArg_Prv(baseRaiz, "baseRaiz", 2, Es_Clase(o) => o is Class)
        return _Util_EsBase_Prv(clase, baseRaiz)
    }

    _Util_EsBase(clase, baseRaiz) {
        Err_VerificarArg_Prv(clase, "clase", 1, Es_Clase(o) => o is Class)
        return clase.EsAncestro(baseRaiz)
    }

    Class.Prototype.DefineProp("EsBase", {Call: _Util_EsBaseM})
    global Util_EsBase := _Util_EsBase


    /*
        @function Util_EsDescendiente

        @description Saber si un objeto clase es descendiente o heredero.
    */
    _Util_EsDescendienteM(clase, descendiente) {
        Err_VerificarArg_Prv(descendiente, "descendiente", 2, Es_Clase(o) => o is Class)
        return _Util_EsBase_Prv(descendiente, clase)
    }

    _Util_EsDescendiente(clase, descendiente) {
        Err_VerificarArg_Prv(clase, "clase", 1, Es_Clase(o) => o is Class)      
        return clase.EsDescendiente(descendiente)
    }

    Class.Prototype.DefineProp("EsDescendiente", {Call: _Util_EsDescendienteM})
    global Util_EsDescendiente := _Util_EsDescendiente

    
    /*
        @function Util_CambiarBase

        @description Modificar la herencia de una clase. Toda la jerarquía desde la clase hasta un ancestro o base raíz (no incluido) se convierte en heredera de una nueva base clase, dejando de heredar de base raíz. La nueva base se convierte en la clase a partir de la cual hereda toda la jerarquía que existía por debajo del ancestro base raíz.
        La búsqueda y el recorrido de la herencia se hace usado solo la propiedad Base de las clases. Si la base del prototipo no coincide con el prototipo de la base no se tiene en cuenta. Cuando finalmente se cambia el padre de una clase, se cambia también el padre del prototipo para que apunte al prototipo del padre.

        @param {Class} clase - Clase a partir de la cual se va a obtener la clase inmediatamente inferior a su base raíz, siendo ésta la que cambiará su padre por la nueva base. Si la base raíz es la base inmediata (padre) de la clase, se cambia directamente la base de clase.
        @param {Clase} baseNueva - Clase que será la nueva Base.
        @param {Clase} baseRaiz - Base ancestro de la clase a partir de la cual toda su herencia tendrá como nueva base baseNueva.

        @returns {Clase} La clase de la jerarquía que ha cambiado su Base.

        @throws {Error/Err_ValorArgError} - Si alguno de los valores de los argumentos no cumple la condición para poder realizar el cambio.
        @throws {Error/Err_TipoArgError} - Si la baseNueva o baseRaíz no son de tiop Class.

        @todo Hacerlo genérico para cualquier árbol cuyo nodo pueda acceder al padre.
        Si se supiese el hijo de una clase, se podría hacer esta función simplemente pasando la baseRaiz y la baseNueva, de manera que se acedería al hijo de la baseRaiz y se cambiaría su base por la nueva. Si se quisiese cambiar la base directa de una clase, simplemente se pasaría como base raíz su base actual.
    */
    _Util_CambiarBaseM(clase, baseNueva, baseRaiz := clase.Base) {
        switch {
            case clase == Object or clase == Any:
                infoError := {mensaje: "Ni Object ni Any pueden cambiar de base", nombreArg: "this", valorArg: clase, numArg: 1}
            case baseNueva == clase:
                infoError := {mensaje: "La baseNueva no puede ser la misma que clase", nombreArg: "baseNueva", numArg: 2, valorArg: baseNueva}
            case baseRaiz == clase:
                infoError := {mensaje: "La baseRaiz no puede ser la misma que clase", nombreArg: "baseRaiz", numArg: 3, valorArg: baseRaiz}
            case baseRaiz == Any:
                infoError := {mensaje: "La baseRaiz no puede ser Any", nombreArg: "baseRaiz", numArg: 3, valorArg: baseRaiz}
            case clase.EsDescendiente(baseNueva): ; Se comprueba además si baseNueva es Class
                infoError := {mensaje: "La baseNueva no puede ser descendiente de la clase", nombreArg: "baseNueva", numArg: 2, valorArg: baseNueva}
        }
        if IsSet(infoError)
            throw !Err_ErroresPersonalizadosActivos ? Error(infoError.mensaje) : Err_ValorArgError(infoError.mensaje, , , , , , infoError.nombreArg, infoError.numArg, infoError.valorArg)

        if baseNueva == baseRaiz
            return clase

        if baseRaiz != clase.Base {
            Err_VerificarArg_Prv(baseRaiz, "baseRaiz", 3, Es_Clase(o) => o is Class)

            Loop { ; Loop en lugar de while para aprovechar la comparación anterior necesaria.
                if clase.Base == baseNueva
                    infoError := {mensaje: "La baseNueva no puede ser ascendente de la clase y no ascendente de baseRaiz", arg: baseNueva, numArg: 2}
                else if clase.Base == Object
                    infoError := {mensaje: "La baseRaiz no es ascendente de la clase", arg: baseRaiz, numArg: 3}
                if IsSet(infoError)
                    throw !Err_ErroresPersonalizadosActivos ? Error(infoError.mensaje) : Err_ValorArgError(infoError.mensaje, , , , , , infoError.nombreArg, infoError.numArg, infoError.valorArg)
            } Until (clase := clase.Base).Base == baseRaiz
        }

        clase.Base := baseNueva
        clase.Prototype.Base := baseNueva.Prototype

        return clase
    }
    
    _Util_CambiarBase(clase, baseNueva, baseRaiz?) {
        Err_VerificarArg_Prv(clase, "clase", 1, Es_Clase(o) => o is Class)
        
        return clase.CambiarBase(baseNueva, baseRaiz?)
    }

    ; Se añade como método a Class
    Class.Prototype.DefineProp("CambiarBase", {Call: _Util_CambiarBaseM})
    global Util_CambiarBase := _Util_CambiarBase


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

        @description Obtener el nombre de la función llamante de la actual que, a su vez, está llamando a Util_llamante.

        @throws {UnsetError} - Si no existe función llamante, como en el caso de invocar esta función desde un ámbito global de script.

        @returns {String} - Nombre de la función llamante de la actual.
    */
    _Util_Llamante() {
        try {
            throw Error("", ERR_FUNCION_ORIGEN["PADRE_LLAMANTE"])
        }
        catch Error as e {
            if String(e.What) == String(ERR_FUNCION_ORIGEN["PADRE_LLAMANTE"])
                throw UnsetError.CrearErrorAHK("No existe función llamante")
            return e.What
        }
    }

    global Util_Llamante := _Util_Llamante

    /*
        @function Util_DefinePropEstandar_Prv

        @description Definir una propiedad dinámica con sus métodos get y set. No tiene en consideración ni llama a la propiedad heredada, sobreescribiendo el comportamiento para el objeto en caso de que ya exista previamente o se herede (no es posible el uso de super fuera de la definición de clase). Para definir una propiedad que extienda la heredada hay que hacerlo en la definición de la clase y usando super. Versión Prv PARA SOLO USO INTERNO. YA QUE NO COMPRUEBA NINGUNO DE LOS ARGUMENTOS.
        - Get devuelve el valor guardado. lanzará PropertyError si el valor interno no ha sido definido.
        - Set guardará el valor, previamente comprobado el tipo y el valor, convirtíendolo a otro valor. Si no puede grabar el valor internamente lanzaŕa PropertyError. Además, lanza TypeError/Err_TipoArgError si el valor no es el tipo correcto; ValueError/Err_ValorError si el valor no pasa validación; Err_ArgError si no se puede convertir.

        @param {String} prop - Nombre de la propiedad.
        @param {Func} comprobarTipo - Función que devolverá true o false si el valor no es del tipo correcto.
        @param {Func} validarValor - Función que devolverá true o false si el valor no es valido. Esta función supone que el tipo del valor es el correcto.
        @param {Func} convertirValor - Función que devolverá el valor convertido. Esta función supone que el tipo del valor es el correcto y que pasa la validación.

        @throws {MethodError} - Si existe algún error al definir la propiedad con DefineProp.

        @returns {Object} - Devuelve el objeto al cual se le ha definido la propiedad.
    */
    _Util_DefinePropEstandar_Prv(obj, prop, comprobarTipo?, validarValor?, convertirValor?) {
        _Get(_obj) {
            try 
                return _obj.%"_" prop%
            catch as e
                throw PropertyError.CrearErrorAHK("La propiedad " prop " no tiene aún ningún valor definido", , , , , e)
        }

        _Set(_obj, valor) {
            valorVerficado := Err_VerificarArg_Prv(valor, "value", 1, comprobarTipo?, validarValor?, convertirValor?)

            try 
                return (_obj.%"_" prop% := valorVerficado)
            catch as e
                throw PropertyError.CrearErrorAHK("No se puede guardar ningún valor en la propiedad " prop, , , , , e)
        }

        try 
            return obj.DefineProp(prop, {Get: _Get, Set: _Set})
        catch as e
            throw MethodError.CrearErrorAHK("No se puede definidir la propiedad " prop, , , , , e)
    }

    
    /*
        @function Util_DefinePropEstandar

        @description Definir una propiedad dinámica con sus métodos get y set. No tiene en consideración ni llama a la propiedad heredada, sobreescribiendo el comportamiento para el objeto en caso de que ya exista previamente o se herede (no es posible el uso de super fuera de la definición de clase). Para definir una propiedad que extienda la heredada hay que hacerlo en la definición de la clase y usando super.

        - Get devuelve el valor guardado. lanzará PropertyError si el valor interno no ha sido definido.
        - Set guardará el valor, previamente comprobado el tipo y el valor, convirtíendolo a otro valor. Si no puede grabar el valor internamente lanzaŕa PropertyError. Además, lanza TypeError/Err_TipoArgError si el valor no es el tipo correcto; ValueError/Err_ValorError si el valor no pasa validación; Err_ArgError si no se puede convertir.

        @param {String} prop - Nombre de la propiedad.
        @param {Func} comprobarTipo - Función que devolverá true o false si el valor no es del tipo correcto.
        @param {Func} validarValor - Función que devolverá true o false si el valor no es valido. Esta función supone que el tipo del valor es el correcto.
        @param {Func} convertirValor - Función que devolverá el valor convertido. Esta función supone que el tipo del valor es el correcto y que pasa la validación.

        @throws {TypeError/Err_TipoArgError} - Si los argumentos no son de tipo correcto.

        @returns {Object} - Devuelve el objeto al cual se le ha definido la propiedad.
    */
        _Util_DefinePropEstandarM(obj, prop, comprobarTipo?, validarValor?, convertirValor?) {
        prop := Err_VerificarArg_Prv(prop, "prop", 2, , , String)
        if IsSet(comprobarTipo) {
            EsFunc(f) => Err_AdmiteNumArgs(f, 1)
            EsFunc.Mensaje := "No es una función o no admite un argumento"
            Err_VerificarArg_Prv(comprobarTipo, "comprobarTipo", 3, EsFunc)
            
            /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo comprueba el tipo de un valor sin lanzar excepciones */
        }
        if IsSet(validarValor) {
            Err_VerificarArg_Prv(validarValor, "validarValor", 4, EsFunc)
            
            /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo comprueba el valor suponiendo que el tipo ha sido ya comprobado anteriormente, sin lanzar excepciones */
        }
        if IsSet(convertirValor) {
            Err_VerificarArg_Prv(convertirValor, "convertirValor", 5, EsFunc)
            
            /* Aquí se verificaría la función para comprobar que no es maliciosa y que realmente solo convierte el valor, sin lanzar excepciones, suponiendo que el tipo y el valor han sido comprobados anteriormente */
        }

        return  _Util_DefinePropEstandar_Prv(obj, prop, comprobarTipo?, validarValor?, convertirValor?)
    }

    _Util_DefinePropEstandar(obj, prop, comprobarTipo?, validarValor?, convertirValor?) {
        if !(obj is Object)
            throw Err_TipoArgError("Debes pasar un Object para definir la nueva propiedad", , , , , , "obj", 1, Type(obj))

        return obj.DefinePropEstandar(prop, comprobarTipo, validarValor, convertirValor)
    }

    ; Se añade como método a Object
    Object.Prototype.DefineProp("DefinePropEstandar", {Call: _Util_DefinePropEstandarM})
    global Util_DefinePropEstandar := _Util_DefinePropEstandar

        
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
        
        @description Obtener una cadena a partir de los valores de objeto enumerable <__Enum> o Enumerator (llamable cuyos argumentos son VarRef) .

        @param {Object<__Enum>|Enumerator} enum - Objeto enumerable cuyos valores se van a convertir a una cadena.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable por cada elemento. Puede ser 0 si el enum no tiene argumentos, pero devuelve una cadena vacía.
        @param {String} sepGrupo - cadena para separar los grupos de valores obtenidos en cada llamada al enumerable. Separador entre entradas.
        @param {String} sepPartes - cadena para separar cada uno de los valores obtenidos en una llamada al enumerable. Separador entre elementos de una entrada. Si numArgs == 1 se ignora.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_ArgError} - Si el enumerable no es válido o no admite ese número de argumentos.

        @returns {String} Devuelve un String de los valores de la lista convertidos a cadena..
    */
    _Util_EnumerableACadenaM(enum, numArgs := 1, sepGrupo := ";", sepPartes := ":") {
        Ve(e) => Err_VerificarEnumerable(e, numArgs)
        Ve.Mensaje := "Enumerable no válido: número de argumentos incompatible o tipo de objeto incorrecto"
        enum := Err_VerificarArg_Prv(enum, "enum", 1, , , Ve)
        S(s) => String(s)
        S.Mensaje := "Los separadores deben de ser una cadena",
        sepGrupo := Err_VerificarArg_Prv(sepGrupo, "sepGrupo", 3, , , S)
        sepPartes := Err_VerificarArg_Prv(sepPartes, "sepPartes", 4, , , S)

        valoresRef := Array()
        Loop numArgs
            valoresRef.Push(Util_CrearVarRef())

        cadena := ""
        while enum(valoresRef*) {
            for valorRef in valoresRef
                cadena .= (%valorRef% ?? "") sepPartes " "

            cadena := RTrim(cadena, sepPartes " ") sepGrupo " "
        }

        return RTrim(cadena, sepGrupo " ")
    }

    _Util_EnumerableACadena(enum, numArgs, sepGrupo := ";", sepPartes := ":") {
        Err_VerificarEnumerable(enum, numArgs)
        enum.ToString(enum, numArgs, sepGrupo, sepPartes)
    }
    
    ; Se añade como método a Map, Array y Enumerator
    Enumerator.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadenaM})
    Array.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadenaM})
    Map.Prototype.DefineProp("ToString", {Call: (m, n?, sg?, sp?) => _Util_EnumerableACadenaM(m, n ?? 2, sg?, sp?)})
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

        @todo Si el diccionario no tiene función para comparar las claves, éstas deben estar ordenadas en el orden en que se van metiendo.

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
        @description Comprueba si un elemento está dentro de los valores de un objeto enumerable.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable donde comprobar el valor
        @param {Any} valor - valor a comprobar si está dentro del enum.
        @param {Integer} numArgs - Número de argumentos >= 1 que admite el enumerable por cada elemento.
        @param {Integer} posValor - Posición de los argumentos del enumerable a comparar el valor.

        @returns {Boolean} - true o false si el elemento está o no dentro de la lista.

        @throws {Err_TipoArgError} - Si el tipo de algún argumento es incorrecto.
        @throws {Err_ValorArgError} - Si el valor de algún argumento no es válido.
        @throws {Err_ArgError} - Si el enumerable no es válido o no admite ese número de argumentos.
    */
    _Util_ContieneValor(enum, valor, numArgs := 2, posValor := 2) {
        Ve(e) => Err_VerificarEnumerable(e, numArgs)
        Ve.Mensaje := "Enumerable no válido: número de argumentos incompatible o tipo de objeto incorrecto"
        enum := Err_VerificarArg_Prv(enum, "enum", 1, , , Ve)

        Vp(pos) => pos >= 1 and pos <= numArgs
        Vp.Mensaje := "La posición del valor tiene que estar entre 1 y el número de argumentos"
        Err_VerificarArg_Prv(posValor, "posValor", 4, IsInteger, Vp, Integer)

        valoresRef := Array()
        Loop numArgs
            valoresRef.Push(Util_CrearVarRef())

        while enum(valoresRef*)
            if IsSet(%valoresRef[posValor]%) and %valoresRef[posValor]% == valor
                return true

        return false
    }

    ; Se añade Util_ContieneValor como método a Map y Array
    Enumerator.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Map.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Array.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    global Util_ContieneValor := _Util_ContieneValor
   
}

