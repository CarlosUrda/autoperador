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
        - Aunque se verifica el enumerable en las funciones que reciben uno, y al recorrerlo tiene que recibir el número de argumentos correcto y por referencia, no se comprueba que, por lo que sea, dentro de la ejecución de cada iteración del enumerable se cometa un fallo. Digamos que verificarEnumerable comrpueba que está todo bien hasta que se entra dentro del enumerable en la ejecución de cada iteración. Si se termina comprobando esto, se debe propagar un error Err_EnumerableError.

        Pasos:
        - Modificar los Err_ArgError con la nueva modificación.
        - Revisar todas las llamadas a DefinePropEstandar y VerificarArg
        - Terminar Eliminar duplicados y usarlo en MapOrdenado
        - Probar si se puede hacer unset con Set para eliminar la función de comparación.
        - Tener en cuenta que si hay función de comparación en MapOrden no hace falta preocuparse si meter los valores en orden.
        - Adaptar Util y error a los errores personalizados.
        - Funcion MergeSort, MapORdenado y  MapPrioridades.
        - Probar debug.
        - Hacer testing de todo usando debug.
        - Acabar config
        - Refactorizar código dataprotector
        

*/


#Requires AutoHotkey v2.0

; En lugar del include se llamaría (dentro de Util??) a la función del módulo para ejecutarla, y solo se ejecutaría en teoría una vez si está en la librería 
#Include "error.ahk"

if (!IsSet(__UTIL_H__)) {
    global __UTIL_H__ := true

/* Util() {
    static ejecutado := false
    if ejecutado
        return
    ejecutado := true
 */
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
            throw Err_TipoArgError("El tipo del valor no es una Clase", , , , , , "valor", 1, valor, Type(valor))
        if clase.Prototype != valor.Base
            throw Err_TipoArgError("El prototipo del tipo de valor no coincide con la base prototipo del valor. Es decir, el objeto no se creó a partir del prototipo de su tipo", , , , , , "valor", 1, valor, Type(valor))

        return clase
    }

    Object.Prototype.DefineProp("Clase", {Call: Util_Clase})


    /*
        @function Util_CrearLista

        @description Crear una lista con valores del 1 al número de elementos pasado.

        @param {Integer} numElementos - Número de elementos que tendrá la lista
        @param {Boolean} asc - Si los valores van de 1 al número de elementos, o del número de elementos a 1.

        @returns {Array} - Lista con los valores
    */
    Util_CrearLista(numElementos, asc := true) {
        numElementos := Err_VerificarArg_Prv(numElementos, "numElementos", 1, FuncArg.EsEntero, FuncArg.Entero, FuncArg.EsNatural)

        lista := []
        if !asc {
            valor := numElementos + 1
            factor := -1
        }
        else {
            valor := 0
            factor := 1
        }

        Loop numElementos
            lista.Push(valor + factor*A_Index)

        return lista
    }


    /*
        @function Util_EsDescendiente

        @description Saber si un objeto clase es descendiente o heredero.
    */
    _Util_EsDescendienteM(clase, descendiente) {
        Err_VerificarArg_Prv(descendiente, "descendiente", 2, FuncArg.EsClase)
        return descendiente.HasBase(clase)
    }

    _Util_EsDescendiente(clase, descendiente) {
        Err_VerificarArg_Prv(clase, "clase", 1, FuncArg.EsClase)
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
            throw !Err_ErroresPersonalizadosActivo ? Error(infoError.mensaje) : Err_ValorArgError(infoError.mensaje, , , , , , infoError.nombreArg, infoError.numArg, infoError.valorArg)

        if baseNueva == baseRaiz
            return clase

        if baseRaiz != clase.Base {
            Err_VerificarArg_Prv(baseRaiz, "baseRaiz", 3, FuncArg.EsClase)

            Loop { ; Loop en lugar de while para aprovechar la comparación anterior necesaria.
                if clase.Base == baseNueva
                    infoError := {mensaje: "La baseNueva no puede ser ascendente de la clase y no ascendente de baseRaiz", arg: baseNueva, numArg: 2}
                else if clase.Base == Object
                    infoError := {mensaje: "La baseRaiz no es ascendente de la clase", arg: baseRaiz, numArg: 3}
                if IsSet(infoError)
                    throw !Err_ErroresPersonalizadosActivo ? Error(infoError.mensaje) : Err_ValorArgError(infoError.mensaje, , , , , , infoError.nombreArg, infoError.numArg, infoError.valorArg)
            } Until (clase := clase.Base).Base == baseRaiz
        }

        clase.Base := baseNueva
        clase.Prototype.Base := baseNueva.Prototype

        return clase
    }
    
    _Util_CambiarBase(clase, baseNueva, baseRaiz?) {
        Err_VerificarArg_Prv(clase, "clase", 1, FuncArg.EsClase)
        
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

        @description Definir una propiedad dinámica con sus métodos get y set. La nueva propiedad no tiene en consideración ni llama a la propiedad heredada, sobreescribiendo el comportamiento para el objeto en caso de ya existir previamente o se herede (no es posible el uso de super fuera de la definición de clase). Para definir una propiedad que extienda la heredada hay que hacerlo en la definición de la clase y usando super. Versión Prv PARA SOLO USO INTERNO. YA QUE NO COMPRUEBA NINGUNO DE LOS ARGUMENTOS.
        - Get devuelve el valor guardado. lanzará PropertyError si el valor interno no ha sido definido.
        - Set guardará el valor, aplicando previamente las funciones de verificación.

        @param {String} prop - Nombre de la propiedad.
        @param {FuncArg} funciones - Funciones de verificación tipo FuncArg usadas en el Set que serán llamadas en el orden en que son pasadas. A cada función se le pasa como único argumento el valor recibido.

        @throws {MethodError} - Si existe algún error al definir la propiedad con DefineProp.

        @returns {Object} - Devuelve el objeto al cual se le ha definido la propiedad.
    */
    _Util_DefinePropEstandar_Prv(obj, prop, funciones*) {
        _Get(_obj) {
            try 
                return _obj.%"_" prop%
            catch as e
                throw PropertyError.CrearErrorAHK("La propiedad " prop " no tiene aún ningún valor definido", , , , , e)
        }

        _Set(_obj, valor) {
            valorVerficado := Err_VerificarArg_Prv(valor, "value", 1, funciones*)

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
        - Set guardará el valor, aplicando previamente las funciones de verificación.

        @param {String} prop - Nombre de la propiedad.
        @param {FuncArg} funciones - Funciones de verificación tipo FuncArg usadas en el Set que serán llamadas en el orden en que son pasadas. A cada función se le pasa como único argumento el valor recibido.
        
        @throws {Error/Err_TipoArgError} - Si los argumentos no son de tipo correcto.

        @returns {Object} - Devuelve el objeto al cual se le ha definido la propiedad.
    */
    _Util_DefinePropEstandarM(obj, prop, funciones*) {
        prop := Err_VerificarArg_Prv(prop, "prop", 2, FuncArg.Cadena)

        for funcion in funciones {
            Err_VerificarArg_Prv(funcion, funcion.HasProp("Nombre") ? funcion.Nombre : "", 2 + A_Index, FuncArg.EsFuncArg)

            /* Aquí se verificaría la función para comprobar que no es maliciosa */
        }

        return  _Util_DefinePropEstandar_Prv(obj, prop, funciones*)
    }

    _Util_DefinePropEstandar(obj, prop, funciones*) {
        Err_VerificarArg_Prv(obj, "obj", 1, FuncArg((o) => o is Object, FuncArg.TIPO_FUNC["Comprobar"], "Debes pasar un objeto Object para definir la nueva propiedad"))

        return obj.DefinePropEstandar(prop, funciones*)
    }

    ; Se añade como método a Object
    Object.Prototype.DefineProp("DefinePropEstandar", {Call: _Util_DefinePropEstandarM})
    global Util_DefinePropEstandar := _Util_DefinePropEstandar

        
    /*
        @function Util_ExpandirArgs

        @description Envolver a una función para poder recibir más argumentos. La nueva función envoltorio será la que reciba los argumentos, pero serán filtrados antes de pasárselos a la función real: aquellos que pasen el filtro se pasarán en orden a la primera función. 

        @param {Func} funcion - Función a ser envuelta y que recibirá en orden los argumentos que pasan el filtro.
        @param {Func} filtro - Función que recibirá como argumentos la posición y el valor de cada argumento de la función envoltorio. Si devuelve true, el argumento se pasará a la función; si devuelve false, se desecha. Tener en cuenta que el valor pasado de algún argumento puede no estar definido.

        @throws {Err_FuncArgError} - Si ocurre un error al ejecutar el filtro
        @throws {ErrorNumArgumentos} - Si la función no admite el número de argumentos pasados tras el filtro..

        @returns {Func} - Función envoltorio que será la que reciba los argumentos a ser filtrados.
    */
    _Util_ExpandirArgsM(funcion, filtro) {
        Err_VerificarArg_Prv(filtro, "filtro", 2, FuncArg.Admite2Args)

        _Funcion(args*) {            
            _args := args
            for arg in args
                try
                    if !filtro(A_index, arg?)
                        _args.RemoveAt(A_Index)
                catch as e
                    throw Err_FuncArgError("Filtro no ejecutado correctamente", , , , , e, "filtro", 2, filtro)

            try 
                return funcion(_args*)
            catch as e
                throw Err_NumArgsError("Número de argumentos erróneos", , , , , e, funcion, _args.Length)
        }

        return _Funcion
    }

    _Util_ExpandirArgs(funcion, filtro) {
        Err_VerificarArg_Prv(funcion, "funcion", 1, FuncArg.EsLlamable)

        return _Util_ExpandirArgsM(funcion, filtro)
    }

    ; Se añade como método a Map, Array y Enumerator
    Func.Prototype.DefineProp("ExpandirArgs", {Call: _Util_ExpandirArgsM})
    global Util_ExpandirArgs := _Util_ExpandirArgs



    /*
        @function Util_SubLista

        @description Modificar un array obteniendo una sublista formada con los elementos (índices reenumerados a partir de 1) que cumplan la condición de la funcion filtro.

        @param {Array} lista - Lista a ser modifcada.
        @param {Func} filtro - Función condición que recibirá el índice y valor de cada elemento. Devolverá true o false si cumple o no la condición. Tener en cuenta que el valor pasado de algún argumento puede no estar definido.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_FuncError} - Si filtro genera algún error al ser ejecutado.

        @todo Cuando se filtra por índice al modificar la lista, el valor obtenido en cada iteración no se usa en ningún momento y se pasa a filtro para nada. También a filtro se pasa índice inútilmente cuando se filtra por valor. El coste de solucionarlo consiste en escribir mucho más código con bucles for y llamadas a filtro específicas para cada caso, que por ahora no creo que compense.
    */
    _Util_SubListaM(lista, filtro) {
        Err_VerificarArg_Prv(filtro, "filtro", 2, FuncArg.Admite2Args)
        ; enum := Err_VerificarEnumerable(lista, 2)

        indice := lista.Lenght + indice + 1
        Loop lista.Length {
            try
                if !filtro(indice, lista[indice]?)
                    lista.RemoveAt(indice)              
            catch as e
                throw Err_FuncArgError("Filtro no ejecutado correctamente", , , , , e, "filtro", 2, filtro)

            indice--
        }
    }
    
    ; Se añade como método a Array
    Array.Prototype.DefineProp("Sub", {Call: _Util_SubListaM})



    /*
        @function Util_SubDicc

        @description Modificar un map obteniendo un subdiccionario formado con los elementos (clave, valor) que cumplan la condición de la funcion filtro.

        @param {Map} dicc - Diccionario a ser modificado.
        @param {Func} filtro - Función condición que recibirá la clave y valor de cada elemento. Devolverá true o false si cumple o no la condición.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_FuncError} - Si filtro genera algún error al ser ejecutado.

        @todo Cuando se filtra por índice al modificar la lista, el valor obtenido en cada iteración no se usa en ningún momento y se pasa a filtro para nada. También a filtro se pasa índice inútilmente cuando se filtra por valor. El coste de solucionarlo consiste en escribir mucho más código con bucles for y llamadas a filtro específicas para cada caso, que por ahora no creo que compense.
    */
    _Util_SubDiccM(dicc, filtro) {
        Err_VerificarArg_Prv(filtro, "filtro", 2, FuncArg.Admite2Args)
        ;enum := Err_VerificarEnumerable(dicc, 2)

        borrables := []
        for clave, valor in dicc
            try 
                if !filtro(clave, valor)
                    borrables.Push(clave)
            catch as e
                throw Err_FuncArgError("Filtro no ejecutado correctamente", , , , , e, "filtro", 2, filtro)

        for clave in borrables
            dicc.Delete(clave)
    }
    
    ; Se añade como método a Map
    Map.Prototype.DefineProp("Sub", {Call: _Util_SubDiccM})

        
    /*
        @function Util_SubEnumerableM

        @description Obtener un array con los elementos de un enumerable que pasan un filtro. Si el enumrable admite varios argumentos, cada elemento dentro de la lista resultante será un array con los valores de cada elemento del enumerable.

        @param {Object<__Enum>|Enumerator} enum - Objeto enumerable.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable.
        @param {Func} filtro - Función condición que recibirá, para cada elemento del enumerable, los valores de las posiciones en orden. 
        @param {Integer} posiciones - Serie de posiciones de los argumentos de un elemento del enumerable. Los valores de esas posiciones de los argumentos en cada elemento del enumerable se pasaran en orden a filtro. Si una posición no está, definida se ignora. Si se introducen posiciones repetidas, se considera la primera introducida. Si no se introduce ninguna posición, se pasarán a filtro todos los argumentos del enumerable. Tener en cuenta que el valor pasado de algún argumento puede no estar definido.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_ValorArgError} - Si los valores de los argumentos no son válidos.
        @throws {Err_FuncArgError} - Si filtro genera algún error al ser ejecutado.

        @return {Array} - Lista de elementos del enumerable que han pasado un filtro. Si cada elemento está formado por varios valores (tantos como numArgs), devuelve un array de arrays.
    */
    _Util_SubEnumerableM(enum, numArgs, filtro, posiciones*) {
        enum := Err_VerificarEnumerable(enum, numArgs)

        if posiciones.Length == 0
            _posiciones := Util_CrearLista(numArgs)
        else {
            _posiciones := []
            for posicion in posiciones
                if IsSet(posicion)
                    _posiciones.Push(Err_VerificarArg_Prv(posicion, "posiciones[" A_Index "]", 3 + A_Index, FuncArg.EsEntero, FuncArg.Entero, FuncArg((p) => p >= 1 and p <= numArgs, FuncArg.TIPO_FUNC["Validar"], "Cada posición tiene que estar entre 1 y el numArgs del enumerable")))

            _posiciones.EliminarDuplicados()
        }

        Err_VerificarArg_Prv(filtro, "filtro", 3, FuncArg((f) => Err_AdmiteNumArgs(f, _posiciones.Length), FuncArg.TIPO_FUNC["Comprobar"], "Filtro no es una función o no admite " _posiciones.Length " argumentos"))

        resultado := Array()
        valoresRef := Array()
        Loop numArgs
            valoresRef.Push(Util_CrearVarRef())

        while enum(valoresRef*) {
            valores := Array()
            subValores := Array()

            for valorRef in valoresRef
                valores.Push(%valorRef%?)

            for posicion in _posiciones
                subValores.Push(valores[posicion]?)

            try
                if filtro(subValores*)
                    resultado.Push(valores)
            catch as e
                throw Err_FuncArgError("Filtro no ejecutado correctamente", , , , , e, "filtro", 2, filtro)
        }

        return resultado
    }
    
    Enumerator.Prototype.DefineProp("Sub", {Call: _Util_SubEnumerableM})


    /*
        @function Util_EnumerableACadena
        
        @description Obtener una cadena a partir de los valores de objeto enumerable <__Enum> o Enumerator (llamable cuyos argumentos son VarRef) .

        @param {Object<__Enum>|Enumerator} enum - Objeto enumerable cuyos valores se van a convertir a una cadena.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable por cada elemento. Puede ser 0 si el enum no tiene argumentos, pero devuelve una cadena vacía.
        @param {String} sepGrupo - cadena para separar los grupos de valores obtenidos en cada llamada al enumerable. Separador entre entradas.
        @param {String} sepPartes - cadena para separar cada uno de los valores obtenidos en una llamada al enumerable. Separador entre elementos de una entrada. Si numArgs == 1 se ignora.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_FuncError} - Si hay fallo al recorrer el enumerable.

        @returns {String} Devuelve un String de los valores de la lista convertidos a cadena..
    */
    _Util_EnumerableACadenaM(enum, numArgs := 1, sepGrupo := ";", sepPartes := ":") {
        enum := Err_VerificarEnumerable(enum, numArgs)
        sepGrupo := Err_VerificarArg_Prv(sepGrupo, "sepGrupo", 3, FuncArg.Cadena)
        sepPartes := Err_VerificarArg_Prv(sepPartes, "sepPartes", 4, FuncArg.Cadena)

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

    ; Se añade como método a Map, Array y Enumerator
    Enumerator.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadenaM})
    Array.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadenaM})
    Map.Prototype.DefineProp("ToString", {Call: (m, n?, sg?, sp?) => _Util_EnumerableACadenaM(m, n ?? 2, sg?, sp?)})
    global Util_EnumerableACadena := _Util_EnumerableACadenaM
  

    /*
        @function Util_ObtenerIndices
        
        @description Obtener una lista de índices de una lista. Se recorre la lista y, para cada elemento, comprueba si valor coincide. Si coincide, el índice se incluirá en la lista devuelta. Si no se pasa nigún valor, se devuelven los índices que tengan algún valor definido.

        @param {Array} lista - Lista de donde obtener los índices.
        @param {Object} valor - Valor a ser comparado con cada elemento de la lista.

        @returns {Array} - Array de índices. Si se pasa valor, índices de los elementos que coinciden. Si no se pasa valor, índices con elementos definidos.
    */
    _Util_ObtenerIndices(lista, valor?) {
        ;enum := Err_VerificarEnumerable(lista, 2)

        indices := []

        if IsSet(valor) {
            for indice, _valor in lista
                if IsSet(_valor) and _valor == valor
                    indices.Push(indice)

        }
        else {
            for indice, _valor in lista
                if IsSet(_valor)
                    indices.Push(indice)
        }

        return indices
    }

    Array.Prototype.DefineProp("Indices", {Call: _Util_ObtenerIndices})
    global Util_ObtenerIndices := _Util_ObtenerIndices


    /*
        @function Util_ObtenerClavesM
        
        @description Obtener una lista de claves de un diccionario. Se recorre el diccionario y, para cada elemento, comprueba si valor coincide. Si coincide, la clave se incluirá en la lista devuelta. Si no se pasa nigún valor, se devuelven todas las claves.

        @param {Map} dicc - Diccionario de donde obtener las claves.
        @param {Object} valor - Valor a ser comparado con el valor de cada elemento del diccionario.

        @returns {Array} - Array de claves. Si se pasa valor, claves cuyo valor coincide. Si no se pasa valor, todas las claves del diccionario.
    */
    _Util_ObtenerClavesM(dicc, valor?) {
        ;enum := Err_VerificarEnumerable(dicc, 2)

        claves := []

        if IsSet(valor) {
            for clave, _valor in dicc
                if _valor == valor
                    claves.Push(clave)

        }
        else {
            for clave, _valor in dicc
                claves.Push(clave)
        }

        return claves
    }

    Map.Prototype.DefineProp("Claves", {Call: _Util_ObtenerClavesM})
    global Util_ObtenerClavesM := _Util_ObtenerClavesM


    /*
        @function Util_ObtenerClaves
        
        @description Obtener una lista de claves de un enumerable. Va recorriendo el enumerable y, para cada elemento, comprueba si los valores de pos_valor coinciden con los valores de las posiciones de los argumentos corespondientes del enumerable. Si coinciden todos, la clave se incluirá en la lista devuelta. Si no se meten valores a comparar, se devuelven las claves con dos condiciones:
        - Si solo hay un argumento en el enumerable, y éste es la clave, se incluye en la lista de salida si es un valor definido.
        - Si hay más argumentos además de la clave, solo se incluye la clave si alguno del resto de argumentos es definido. Si todos los demás no están definidos, la clave no se incluye.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable de donde obtener los primeros valores.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable por cada elemento.
        @param {Integer} posClave - Posición, dentro de los argumentos, de la clave de cada elemento del enumerable
        @param {Integer, Object} pos_valor - Serie de pares de argumentos (posición, valor). Se indica, para cada posición de los argumentos del enumerable, el valor que tiene que contener.

        @throws {Err_TipoArgError} - Si el tipos del argumentos no es correcto.
        @throws {Err_ValorArgError} - Si el valor de algún argumento no es válido.

        @returns {Array} - Array de claves obtenidas

        @todo Se puede mejorar permitiendo que la clave esté formada por varios valores.
    */
    _Util_ObtenerClaves(enum, numArgs, posClave, pos_valor*) {
        enum := Err_VerificarEnumerable(enum, numArgs)
        FA_RangoPosicion := FuncArg((p) => p > 0 and p <= numArgs, FuncArg.TIPO_FUNC["Validar"], "La posición debe estar entre 1 y numArgs")
        posClave := Err_VerificarArg_Prv(posClave, "posClave", 3, FuncArg.EsEntero, FuncArg.Entero, FA_RangoPosicion)

        valoresRef := Array()
        Loop numArgs
            valoresRef.Push(Util_CrearVarRef())
        claves := Array()

        if pos_valor.Length > 0 {
            Err_VerificarArg_Prv(pos_valor, "pos_valor", 4, FuncArg((pv) => Ceil(pv.Length / 2) <= numArgs, FuncArg.TIPO_FUNC["Validar"], "El número de valores debe ser <= numArgs")) 

            while enum(valoresRef*) {
                if !IsSetRef(valoresRef[posClave])
                    continue

                valorOK := true
                Loop pos_valor.Length {
                    posArg := Err_VerificarArg_Prv(pos_valor[A_Index], "pos_valor[" A_Index "]", 3 + A_Index, FuncArg.EsEntero, FuncArg.Entero, FA_RangoPosicion)

                    if !((!IsSetRef(valoresRef[posArg]) and !pos_valor.Has(++A_Index)) or (IsSetRef(valoresRef[posArg]) and pos_valor.Has(A_Index) and %valoresRef[posArg]% == pos_valor[A_Index])) {
                        valorOK := false
                        break
                    }
                }

                if valorOK
                    claves.Push(%valoresRef[posClave]%)
            }
        }
        else if numArgs > 1 {
            while enum(valoresRef*) {
                if !IsSetRef(valoresRef[posClave])
                    continue

                valorOK := false
                for valorRef in valoresRef
                    if A_Index != posClave and IsSetRef(valorRef) {
                        valorOK := true
                        break
                    }
                
                if valorOK
                    claves.Push(%valoresRef[posClave]%)
            }
        } 
        else
            while enum(valoresRef*)
                if !IsSetRef(valoresRef[posClave])
                    claves.Push(%valoresRef[posClave]%)

        return claves
    }

    ; Se añade como método a Enumerator
    Enumerator.Prototype.DefineProp("Claves", {Call: _Util_ObtenerClaves})
    global Util_ObtenerClaves := _Util_ObtenerClaves


    /*
        @function _Util_Combinar_Prv

        @description Ordenar la combinación dos sublistas seguidas dentro de una lista como parte del algoritmo MergeSort (_Util_OrdenarListaM). Las dos sublistas tienen que estar ordenadas por separado y ser contiguas.

        @param {Array} lista - Contiene las dos sublistas contiguas. Queda modificada tras la ordenación.
        @param {Func} comparar - Función de comparación de un par de valores. Devuelve <0, 0 o >0.
        @param {Integer} inicio - Indice del primero elemento de la primera sublista
        @param {Integer} medio - Indice del último elemento de la primera sublista. Medio+1 es el índice del primer elemento de la segunda sublista.
        @param {Integer} fin - Indice del último elemento de la segunda sublista.
    */
    _Util_Combinar_Prv(lista, comparar, inicio, medio, fin) {
        indiceIzq := inicio
        indiceDcha := medio + 1

        while (indiceIzq <= medio and indiceDcha <= fin) {
            if comparar(lista[indiceIzq], lista[indiceDcha]) > 0 {
                valor := lista[indiceDcha]
                lista.RemoveAt(indiceDcha)
                lista.InsertAt(indiceIzq)
                indiceDcha++
                medio++
            }
            indiceIzq++
        }
    }

    /*
        @function Util_OrdenarListaM

        @description Ordenar una sublista dentro de una lista. La lista queda modificada, pero solo las posiciones de los elementos de la sublista.

        @param {Func} comparar - Función de comparación de un par de valores. Devuelve <0, 0 o >0.
        @param {Integer} inicio - Posición del primer elemento de la sublista.
        @param {Integer} fin - Posición del último elemento de la sublista.
    */
    _Util_OrdenarListaM(lista, comparar := (a, b) => StrCompare(String(a), String(b), true), inicio := 1, fin := lista.Length) {
        inicio := Err_VerificarArg_Prv(inicio, "inicio", 4, FuncArg.EsEntero, FuncArg.Entero)
        fin := Err_VerificarArg_Prv(fin, "fin", 5, FuncArg.EsEntero, FuncArg.Entero, FuncArg((i) => inicio >= 1 and fin >= inicio, FuncArg.TIPO_FUNC["Validar"], "Los indices tienen que cumplir 1 <= inicio <= fin"))

        if lista.Length == 0 or (fin - inicio) <= 0
            return

        medio := (fin-inicio) // 2 + 1

        lista.Ordenar(lista, comparar, inicio, medio)
        lista.Ordenar(lista, comparar, medio+1, fin)

        _Util_Combinar_Prv(lista, comparar, inicio, medio, fin)
    }

    ; Se añade como método a Map y Array
    Array.Prototype.DefineProp("Ordenar", {Call: _Util_OrdenarListaM})


    /*
        @function Util_EliminarDuplicadosMA

        @decripción Eliminar los valores duplicados de una lista. La lista se modifica quedando con los valores no duplicados. Si los valores son objetos, no se compara su contenido; solo su referencia. Es decir, que si dos elementos tienen como referenci el mismo objeto, se considera duplicado, pero si tienen como referencia objetos distintos que tienen el mismo contenido, se consideran elementos no duplicados.

        @param {Array} lista - Array a eliminar sus duplicados
        @param {Boolean} final - Si true se eliminan los elementos duplicados empezando por el final quedando como único no duplicado el primero; si false se eliminan los elementos duplicados desde el principio quedando como único no duplicado el último.
    */
    _Util_EliminarDuplicadosMA(lista, final := true) {        
        valoresDup := Map()

        if !!final {
            indice := incNoBorrar := 1
            incBorrar := 0
        }
        else
            indice := incBorrar := incNoBorrar := -1

        valorIndef := {}  ; Al usarse la referencia como clave, es única para este objeto.
        Loop lista.Length {
            valor := lista.Has(indice) ? lista[indice] : valorIndef
            if !valoresDup.Has(valor) {
                valoresDup[valor] := true
                indice += incNoBorrar
            }
            else {
                lista.RemoveAt(indice)
                indice += incBorrar
            }
        }
    }

    ; Se añade como método a Array
    Array.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosMA})


    /*
        @function Util_EliminarDuplicadosMM

        @decripción Eliminar los valores duplicados de un diccionario. El diccionario se modifica quedando con los valores no duplicados. Si los valores son objetos, no se compara su contenido; solo su referencia. Es decir, que si dos elementos tienen como referenci el mismo objeto, se considera duplicado, pero si tienen como referencia objetos distintos que tienen el mismo contenido, se consideran elementos no duplicados.

        @param {Map} dicc - Map a eliminar sus duplicados
    */
    _Util_EliminarDuplicadosMM(dicc) {
        valoresDup := Map()
        clavesBorrables := []

        for clave, valor in dicc
            if !valoresDup.Has(valor) {
                clavesBorrables.Push(clave)
                valoresDup[valor] := true
            }

        for clave in clavesBorrables
            dicc.Delete(clave)
    }

    ; Se añade como método a Map
    Map.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosMM})


    /*
        @function Util_EliminarDuplicados

        @decripción Eliminar los valores duplicados de un enum. El diccionario se modifica quedando con los valores no duplicados. Si los valores son objetos, no se compara su contenido; solo su referencia. Es decir, que si dos elementos tienen como referenci el mismo objeto, se considera duplicado, pero si tienen como referencia objetos distintos que tienen el mismo contenido, se consideran elementos no duplicados.

        @param {Map} dicc - Map a eliminar sus duplicados
    */
    _Util_EliminarDuplicadosM(enum, numArgs, posiciones*) {
        valoresDup := Map()

        for clave, valor in dicc
            if !valoresDup.Has(valor)
                valoresDup[valor] := true
            else
                dicc.Delete(clave)
    }

    ; Se añade como método a Enumerator
    Enumerator.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosM})
    global Util_EliminarDuplicados := _Util_EliminarDuplicadosM


    /*
        @class Util_MapOrdenado

        @description 

        @todo Si el diccionario no tiene función para comparar las claves, éstas deben estar ordenadas en el orden en que se van metiendo.

    */
    class Util_MapOrden extends Map {
        /*
            @static Convertir

            @description Convertir un objeto Map a MapOrden. El objeto pasado queda modificado pasando a ser de tipo MapOrden

            @param {Map} dicc - Diccionario Map a ser convertido.
            @param {Func} comparar - Función de comparación a ser usada por MapOrden. Tiene que admitir dos argumentos y devolver <0, 0 o >0 como resultado de la comparación. Si no se pasa función de comparación, el orden de los elementos es el orden en que se van introduciendo.

            @throws {Err_TipoArgError} - Si dicc no es Map o comparar no es Func.
            @throws {Err_FuncError} - Si no puede ordenar las claves.

            @returns {MapOrden} - El objeto Map convertido a MapOrden.
        */
        static Convertir(dicc, comparar?) {
            Err_VerificarArg_Prv(dicc, "dicc", 1, Es_Map(d) => dicc is Map)

            _base := dicc.Base
            dicc.Base := this.Prototype
            dicc._claves := dicc.Claves()
            if IsSet(comparar) {
                ; Aquí No hay que preocuparse por meterlos en orden
                try
                    dicc.Comparar := comparar
                catch as e {
                    dicc.Base := _base
                    dicc._claves := unset
                    if dicc.HasProp("_comparar")
                        dicc._comparar := unset
                    throw e
                }
                
            }

            return dicc
        }

        /*
            @static Convertir

            @description Crear un objeto MapOrden a partir de un objeto Map. El objeto MapOrden obtenido es nuevo, aunque los elementos del diccionario no se clonan.

            @param {Map} dicc - Diccionario Map a partir del cual crear un MapOrden.
            @param {Func} comparar - Función de comparación a ser usada por MapOrden. Tiene que admitir dos argumentos y devolver <0, 0 o >0 como resultado de la comparación.

            @throws {Err_TipoArgError} - Si dicc no es Map o comparar no es Func.
            @throws {Err_FuncError} - Si no puede ordenar las claves.

            @returns {MapOrden} - El objeto MapOrden creado.
        */
        static Crear(dicc, comparar?) {
            Err_VerificarArg_Prv(dicc, "dicc", 1, Es_Map(d) => dicc is Map)

            dicc := dicc.Clone()
            dicc.Base := this.Prototype
            dicc._claves := dicc.Claves()
            if IsSet(comparar)
                dicc.Comparar := comparar

            return dicc
        }

        /*
            @constructor

            @param {Object} args - lista de argumentos en orden clave y valor para ser guardados en el MapOrden. Misma estructura de argumentos que se pasan para crear un Map().
            @param {Func} comparar - Función que admite dos valores a ser comparados. Devuelve <1, 0 o >1. Si no hay función de comparación, el orden del diccionario es el mismo como se metieron los valores.

            @throws {Err_ValorArgError} - Si los valores args no permiten crear el diccionario.
            @throws {Err_TipoArgError} - Si la función de comparación no es válida.
        */
        __New(comparar?, args*) {
            try
                super._New(args*)
            catch as e
                throw Err_ValorArgError("No se han podido crear el diccionario", , , , , e, "args", 1, args)

            if !IsSet(comparar) {
                args.SubLista((i, v) => Mod(i, 2) == 1 and this.Has(v))
                args.EliminarDuplicados(false) ; Otra opción es usar la función filtro.
                this._claves := args
            }
            else {
                Err_VerificarArg_Prv(comparar, "comparar", 1, FuncArg.Admite2Args)
                this._claves := this.Claves
                try
                    this._claves.Ordenar(comparar)
                catch as e
                    throw MethodError.CrearErrorAHK("No se han podido ordenar las claves", , , , , e)
            }
        }

        /*
            @method Claves
            
            @description Obtener las claves ya ordenadas del diccionario. Este método sobrecarga a Claves de Map. Si se pasan valores, se obtienen las claves que estén asociadas a ese valor.

            @param {Object} valor - Valores a ser comparado con los de cada clave.

            @returns {Array} - Array de claves obtenidas.
        */
        Claves(valor?) {
            if IsSet(valor) {
                _claves := []
                for clave in this._claves
                    if this[clave] == valor
                        _claves.Push(clave)

                return _claves
            }
 
            return this._claves.Clone()
        }


        /*
            @property Comparar

            @description Propiedad para guardar y obtener la función de comparación. Al guardar la función se reordenan las claves.

            @throws {PropertyError} - Si al obtener la función con get no hay ninguna guardada.
            @throws {Err_TipoArgError} - Si no se pasa una función que admita dos argumentos para ser guardada.
            @throws {MethodError} - Si hay error al reordenar las claves.
        */
        Comparar {
            get {
                if this.HasProp("_comparar")
                    return this._comparar
                else
                    throw PropertyError.CrearErrorAHK("No hay guardada ninguna función de comparación")
            }

            set {
                EF(f) => f is Func and f.AdmiteNumArgs(2)
                EF.Mensaje := "No es función o no admite 2 argumentos"
                Err_VerificarArg_Prv(value, "value", 1, Ef)
                
                this._comparar := value
                try
                    this._claves.Ordenar(value)
                catch as e
                    throw MethodError.CrearErrorAHK("No se han podido reordenar las claves", , , , , e)
            }
        }

        /*
            @method Set

            @description Similar al método Set de Map, pero reordenando todas las claves.

            @throws {MethodError} - Si hay error al reordenar las claves.
            @throws {Err_ValorArgError} - Si no se pueden guardar los valores como se haría en el Map.
        */
        Set(args*) {
            try
                super.Set(args*)
            catch as e
                throw Err_ValorArgError("No se han podido guardar los pares clave-valor", , , , , e, "args", 1, args)

            args.SubLista((i, v) => Mod(i, 2) == 1 and IsSet(v))
            try
                comparar := this.Comparar

            if IsSet(comparar) {
                try
                    args.Ordenar(comparar)
                catch as e
                    throw MethodError.CrearErrorAHK("No se han podido ordenar las claves", , , , , e)

                this._claves.Push(args*)
                _Util_Combinar_Prv(this._claves, comparar, 1, this._claves.Length-args.Length+1, this._claves.Length)
            }
            else
                this._claves.Push(args*)
                

        }

        __Enum(numArgs) {
            Va(n) => n == 1 or n == 2
            Va.Mensaje := "El número de argumentos debe ser 1 o 2"
            Err_VerificarArg_Prv(numArgs, "numArgs", 1, , Va)

            Enum(&clave, &valor?) {
                static indice := 1

                if this.Count < indice or this._claves.Length < indice
                    return false

                clave := this._claves[indice++]
                if IsSet(valor)
                    valor := this[clave]

                return true
            }

            return Enum
        }

        /*
            @method Delete

            @description Similar al método Delete de Map, pero eliminando también la clave de la ordenación de claves.

            @param {Object} - Clave a borrar.

            @throws {UnsetItemError} - Si la clave a borrar no existe.
        */
        Delete(clave) {
            indices := this._claves.IndicesConValor(clave)
            if indices.Length == 0
                mensaje := "No existe la clave en la lista ordenada de claves"
            else
                try
                    super.Delete(clave)
                catch as e
                    mensaje := "No existe la clave en el diccionario"

            if IsSet(mensaje)
                throw UnsetItemError.CrearErrorAHK(mensaje, , , , , e?)
            
            this._claves.RemoveAt(indices[1])
        }

        Clear() {
            super.Clear()
            this._claves := []
        }
    }

    /*
        @class MapPrioridad

        Cada clave tiene como valor un MapOrden, donde a su vez las claves para cada valor son objetos Prioridad {Nombre y valor prioridad}. Estos objetos se tienen que crear desde fuera para tener la referencia y poder acceder al valor de una prioridad concreta
        El operador [] para acceder a cada elemento tiene dos valore [clave, referencia objeto prioridad]. En el caso de no haber referencia y solo clave, con get se devuelve el valor con mayor prioridad y con set se fija el valor con mayor prioridad, lanzando UnsetItem si no hay ningún valor guardado aún.
        Para guardar los valores, se pasa un Map con un valor por cada prioridad.
        MVP[clave] := valor ; guarda en el de mayor prioridad
        MVP[clave] := Map ; guarda los valores por cada prioridad
        Si se quieren meter muchos valores, usar función Set

    */
    class Util_MapPrioridad extends Map {
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

            Si no existe la prioridad, dar la opción de obtener el valor con la prioridad más alta de entre las que están por debajo
            @method
                get -
        */
        __Item[clave, prioridad?, extricto := true] {
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
        @description Comprueba si una serie de valores coinciden con valores de algún elemento de un objeto enumerable.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable donde comprobar el valor
        @param {Integer} numArgs - Número de argumentos >= 1 que admite el enumerable por cada elemento.
        @param {Integer, Object} pos_valor - Serie de pares de argumentos (posición, valor). Se indica, para cada posición de los argumentos del enumerable, el valor que tiene que contener.

        @returns {Boolean} - true o false si el elemento está o no dentro de la lista.

        @throws {Err_TipoArgError} - Si el tipo de algún argumento es incorrecto.
        @throws {Err_ValorArgError} - Si el valor de algún argumento no es válido.
    */
    _Util_ContieneValor(enum, numArgs, pos_valor*) {
        enum := Err_VerificarEnumerable(enum, numArgs)
           
        if Ceil(pos_valor.Length / 2) > numArgs {
            m := "El número de valores debe ser <= numArgs"
            throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_ValorArgError(m , , , , , , "pos_valor", 3, pos_valor)
        }

        if numArgs == 0
            return false

        valoresRef := Array()
        Loop numArgs
            valoresRef.Push(Util_CrearVarRef())

        while enum(valoresRef*) {
            coincide := true
            Loop pos_valor.Length {
                posArg := pos_valor[A_Index]

                if !IsInteger(posArg) {
                    m := "La posición debe ser un entero"
                    throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_TipoArgError(m , , , , , , "pos_valor[" A_Index "]", 2 + A_Index, posArg, Type(posArg))
                }

                posArg := Integer(posArg)

                if posArg > numArgs or posArg < 1 {
                    m := "La posición debe estar entre 1 y numArgs"
                    throw !Err_ErroresPersonalizadosActivo ? Error(m) : Err_ValorArgError(m , , , , , , "pos_valor[" A_Index "]", 2 + A_Index, posArg)
                }

                if !((!IsSetRef(valoresRef[posArg]) and !pos_valor.Has(++A_Index)) or (IsSetRef(valoresRef[posArg]) and pos_valor.Has(A_Index) and %valoresRef[posArg]% == pos_valor[A_Index])) {
                    coincide := false
                    break
                }
            }

            if coincide                    
                return true
        }

        return false
    }

    ; Se añade Util_ContieneValor como método a Map y Array
    Enumerator.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Map.Prototype.DefineProp("ContieneValor", {Call: (v) => _Util_ContieneValor(2, 2, v)})
    Array.Prototype.DefineProp("ContieneValor", {Call: (v) => _Util_ContieneValor(1, 1, v)})
    global Util_ContieneValor := _Util_ContieneValor
   
}

