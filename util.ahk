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
        - Añadir la complejidad de cada función en la documentación.
        - Hacer un módulo de testing para cada librería.

        Pasos:
        - Modificar los Err_ArgError con la nueva modificación.
        - Revisar todas las llamadas a DefinePropEstandar y VerificarArg
        - Terminar Eliminar duplicados y usarlo en MapOrdenado
        - Probar si se puede hacer unset con Set para eliminar la función de comparación.
        - Tener en cuenta que si hay función de comparación en MapOrden no hace falta preocuparse si meter los valores en orden.
        - Adaptar Util y error a los errores personalizados.
        - Funcion MergeSort, MapOOrdenado y  MapPrioridades.
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
        @function Util_CrearRango

        @description Crear una lista con valores del 1 al número de elementos pasado.

        @param {Integer} numElementos - Número de elementos que tendrá la lista
        @param {Boolean} asc - Si los valores van de 1 al número de elementos, o del número de elementos a 1.

        @returns {Array} - Lista con los valores
    */
    Util_CrearRango(numElementos, asc := true) {
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
        @function Util_CrearListaRefs

        @description Crear una lista cuyos elementos son referencias a valores.

        @param {Integer} numElementos - Número de elementos que tendrá la lista

        @returns {Array} - Lista con las referencias como elementos.
    */
    Util_CrearListaRefs(numElementos) {
        numElementos := Err_VerificarArg_Prv(numElementos, "numElementos", 1, FuncArg.EsEntero, FuncArg.Entero, FuncArg.EsNatural)

        valoresRef := Array()
        Loop numElementos
            valoresRef.Push(Util_CrearVarRef())

        return valoresRef
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
        @function Util_DefinePropEstandar

        @description Definir una propiedad dinámica con sus métodos get y set. No tiene en consideración ni llama a la propiedad heredada, sobreescribiendo el comportamiento para el objeto en caso de que ya exista previamente o se herede (no es posible el uso de super fuera de la definición de clase). Para definir una propiedad que extienda la heredada hay que hacerlo en la definición de la clase y usando super.

        - Get devuelve el valor guardado. lanzará PropertyError si el valor interno no ha sido definido.
        - Set guardará el valor, aplicando previamente las funciones de verificación.

        @param {String} prop - Nombre de la propiedad.
        @param {FuncArg} funciones - Funciones de verificación tipo FuncArg usadas en el Set que serán llamadas en el orden en que son pasadas. A cada función se le pasa como único argumento el valor recibido.
        
        @throws {Error/Err_TipoArgError} - Si los argumentos no son de tipo correcto.
        @throws {PropertyError} - Si existe algún error al definir o acceder a la propiedad..

        @returns {Object} - Devuelve el objeto al cual se le ha definido la propiedad.
    */
    _Util_DefinePropEstandarM(obj, prop, funciones*) {
        Err_VerificarArg_Prv(prop, "prop", 2, FuncArg.EsCadena)

        for funcion in funciones {
            Err_VerificarArg_Prv(funcion, funcion.HasProp("Nombre") ? funcion.Nombre : "", 2 + A_Index, FuncArg.EsFuncArg)

            /* Aquí se verificaría la función para comprobar que no es maliciosa */
        }

        _Get(_obj) {
            try 
                return _obj.GetOwnPropDesc("_" prop).Value
            catch as e
                throw PropertyError.CrearErrorAHK("La propiedad " prop " no tiene aún ningún valor definido", , , , , e)
        }

        _Set(_obj, valor) {
            valorVerficado := Err_VerificarArg_Prv(valor, "value", 1, funciones*)

            try 
                _obj.DefineProp("_" prop, {Value: valorVerficado})
            catch as e
                throw PropertyError.CrearErrorAHK("No se puede guardar ningún valor en la propiedad " prop, , , , , e)
        }

        try 
            return obj.DefineProp(prop, {Get: _Get, Set: _Set})
        catch as e
            throw PropertyError.CrearErrorAHK("No se puede definir la propiedad " prop, , , , , e)
    }

    _Util_DefinePropEstandar(obj, prop, funciones*) {
        Err_VerificarArg_Prv(obj, "obj", 1, FuncArg((o) => o is Object, "Comprobar", "Debes pasar un objeto Object para definir la nueva propiedad"))

        return obj.DefinePropEstandar(prop, funciones*)
    }

    ; Se añade como método a Object
    Object.Prototype.DefineProp("DefinePropEstandar", {Call: _Util_DefinePropEstandarM})
    global Util_DefinePropEstandar := _Util_DefinePropEstandar


    /*
        @function Util_GetProp

        @description Obtener el valor de una propiedad de un objeto. Se busca en el objeto y en sus ancestros. Permite usar nombres de propiedades que no son válidos en AHK como identificadores, como los que contienen espacios o caracteres especiales.

        @param {Object} obj - Objeto del cual se quiere obtener la propiedad.
        @param {String} prop - Nombre de la propiedad.

        @throws {Err_TipoArgError} - Si los argumentos no son de tipo correcto.
        @throws {PropertyError} - Si no se puede acceder a la propiedad o no tiene ningún valor definido (solo Set).

        @returns {Object} - Valor de la propiedad. Si la propiedad tiene un método Get, se ejecutará y se devolverá el valor que retorne. Si la propiedad tiene un método Call, devolverá el propio método, y para ejecutarlo se deberá pasar como primer argumento el objeto. Si la propiedad tiene un valor definido, se devolverá ese valor.
        
        @nota Recuerda que Object.Prototype.Base == Any.Prototype; y Any.Prototype.Base == ""
    */
    Util_GetPropM(obj, prop) {
        Err_VerificarArg_Prv(prop, "prop", 2, FuncArg.EsCadena)
        verificarHasProp := true    
        _obj := obj

        Loop {
            if verificarHasProp and !_obj.HasProp(prop)
                break

            if !_obj.HasOwnProp(prop)
                verificarHasProp := false
            else { 
                desc := _obj.GetOwnPropDesc(prop)
                if desc.HasProp("Value")
                    return desc.Value
                if desc.HasProp("Get")
                    return (desc.Get)(obj)
                if desc.HasProp("Call")
                    return desc.Call
    
                verificarHasProp := true
            }

            _obj := _obj.Base

        } Until _obj == ""
    
        throw PropertyError.CrearErrorAHK("La propiedad " prop " no existe en el objeto")
    }

    Util_GetProp(obj, prop) {
        Err_VerificarArg_Prv(obj, "obj", 1, FuncArg((o) => o is Object, "Comprobar", "Debes pasar un objeto Object"))

        return obj.GetProp(prop)
    }

    Any.Prototype.DefineProp("GetProp", {Call: Util_GetPropM})


    Class Indexar {
        __New(obj) {
            this._obj := obj
        }

        __Item[prop] {
            get => this._obj.GetProp(prop)
            ; set => this._obj.SetProp(prop, value)
        }
    }
        
    Any.Prototype.DefineProp("__Item", {Get: (obj) => Indexar(obj)})


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

        @description Obtener una sublista formada con los elementos (índices reenumerados a partir de 1) que cumplan la condición de la funcion filtro.

        @param {Array} lista - Lista original a partir de la cual obtener la sublista.
        @param {Func} filtro - Función condición que recibirá el índice y valor de cada elemento. Devolverá true o false si cumple o no la condición. Tener en cuenta que el valor pasado de algún argumento puede no estar definido.
        @param {Boolean} nuevo - Si se crea una nueva lista o solo se modifica la original.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_FuncError} - Si filtro genera algún error al ser ejecutado.

        @returns {Array} - Sublista obtenida. Si se modifica la original es la misma lista cambiada. Si no, se devuelve una lista nueva.

        @complexity O(n^2) siendo n el número de elementos de la lista, si se modifica la lista original. O(n) si se crea una nueva lista.

        @todo Cuando se filtra por índice al modificar la lista, el valor obtenido en cada iteración no se usa en ningún momento y se pasa a filtro para nada. También a filtro se pasa índice inútilmente cuando se filtra por valor. El coste de solucionarlo consiste en escribir mucho más código con bucles for y llamadas a filtro específicas para cada caso, que por ahora no creo que compense.
    */
    _Util_SubListaM(lista, filtro, nuevo := false) {
        Err_VerificarArg_Prv(filtro, "filtro", 2, FuncArg.Admite2Args)

        if !nuevo {
            indice := lista.Length
            Loop lista.Length {
                try
                    if !filtro(indice, lista.Has(indice) ? lista[indice] : unset)
                        lista.RemoveAt(indice)              
                catch as e
                    throw Err_FuncArgError("Filtro no ejecutado correctamente", , , , , e, "filtro", 2, filtro)

                indice--
            }
        }
        else {
            _lista := lista
            lista := []
            for indice, valor in _lista
                try
                    if !!filtro(indice, valor?)
                        lista.Push(valor?)
                catch as e
                    throw Err_FuncArgError("Filtro no ejecutado correctamente", , , , , e, "filtro", 2, filtro)
        }

        return lista
    }
    
    ; Se añade como método a Array
    Array.Prototype.DefineProp("Sub", {Call: _Util_SubListaM})



    /*
        @function Util_SubDicc

        @description Obtener un subdiccionario formado con los elementos (clave, valor) que cumplan la condición de la funcion filtro.

        @param {Map} dicc - Diccionario a ser modificado.
        @param {Func} filtro - Función condición que recibirá la clave y valor de cada elemento. Devolverá true o false si cumple o no la condición.
        @param {Boolean} nuevo - Si se crea un nuevo diccionario o solo se modifica el original.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_FuncError} - Si filtro genera algún error al ser ejecutado.

        @returns {Map} - Subdiccionario obtenido. Si se modifica el original es el mismo diccionario cambiada. Si no, se devuelve un diccionario nuevo.

        @todo Cuando se filtra por índice al modificar la lista, el valor obtenido en cada iteración no se usa en ningún momento y se pasa a filtro para nada. También a filtro se pasa índice inútilmente cuando se filtra por valor. El coste de solucionarlo consiste en escribir mucho más código con bucles for y llamadas a filtro específicas para cada caso, que por ahora no creo que compense.
    */
    _Util_SubDiccM(dicc, filtro, nuevo := false) {
        Err_VerificarArg_Prv(filtro, "filtro", 2, FuncArg.Admite2Args)

        if !nuevo {
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
        else {
            _dicc := dicc
            dicc := Map()
            for clave, valor in _dicc
                try 
                    if !!filtro(clave, valor)
                        dicc[clave] := valor
                catch as e
                    throw Err_FuncArgError("Filtro no ejecutado correctamente", , , , , e, "filtro", 2, filtro)
        }

        return dicc
    }
    
    ; Se añade como método a Map
    Map.Prototype.DefineProp("Sub", {Call: _Util_SubDiccM})

        
    /*
        @function Util_SubEnumerableM

        @description Obtener una lista con los elementos de un enumerable que pasan un filtro. Cada elemento del enumerable estará formado por tantos valores como numRags y resultará en una sublista formada por esos valores. El filtro se aplicará en cada elemento a sus valores en las posiciones indicadas de los argumentos.

        @param {Object<__Enum>|Enumerator} enum - Objeto enumerable.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable.
        @param {Func} filtro - Función condición que recibirá, para cada elemento del enumerable, los valores de las posiciones en orden. 
        @param {Integer} posiciones - Serie de posiciones de los argumentos de un elemento del enumerable. Los valores en esas posiciones de los argumentos en cada elemento del enumerable se pasaran en orden a filtro. Si una posición no está definida se ignora. Si se introducen posiciones repetidas, se considera la primera introducida. Si no se introduce ninguna posición, se pasarán a filtro todos los argumentos del enumerable. Tener en cuenta que el valor pasado de algún argumento puede no estar definido.

        @throws {Err_TipoArgError|Err_MethodError} - Si hay algún error al verificar el enumerable.
        @throws {Err_ValorArgError} - Si los valores de los argumentos no son válidos.

        @return {Array} - Lista de elementos del enumerable que han pasado un filtro. Devuelve un array de arrays.
    */
    _Util_SubEnumerableM(enum, numArgs, filtro, posiciones*) {
        enum := Err_VerificarEnumerable(enum, numArgs)
        posiciones := Err_VerificarArg(posiciones, "posiciones", 3, FuncArg((l) => l.Length == 0 ? Util_CrearRango(numArgs) : l.LimpiarEnteros(1, numArgs, true), "Convertir", "Los valores de las posiciones no son válidos", Err_ValorArgError))
        Err_VerificarArg_Prv(filtro, "filtro", 3, FuncArg((f) => Err_AdmiteNumArgs(f, posiciones.Length), "Comprobar", "Filtro no es una función o no admite " posiciones.Length " argumentos"))

        resultado := Array()
        valoresRef := Util_CrearListaRefs(numArgs)

        while enum(valoresRef*) {
            valores := Array()
            subValores := Array()

            for valorRef in valoresRef
                valores.Push(%valorRef%?)

            for posicion in posiciones
                subValores.Push(valores.Has(posicion) ? valores[posicion] : unset)

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

        valoresRef := Util_CrearListaRefs(numArgs)

        cadena := ""
        while enum(valoresRef*) {
            for valorRef in valoresRef {
                try
                    cadena .= (IsSetRef(valorRef) ? String(%valorRef%) : "")
                catch
                    cadena .= "<*********>"
                
                cadena .= sepPartes " "
            }

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
        @function Util_InvertirIndicesValoresM

        @description Crear un diccionario tomando como clave cada valor de la lista y como valor el índice asociado a cada valor. Si un valor esta repetido, al convertirlo a clave del diccionario tendrá como valor su último índice.

        @param {Array} - Lista a invertir sus valores e índices.
        @param {Any} valorIndef - Valor que será usado para representar al valor indefinido en caso de haberlo en la lista. Si no está definido se ignoran los valores no definidos de la lista

        @returns {Map} - Diccionario con los valores de la lista como claves y los índices como valores.

        @complexity O(n) siendo n el número de elementos de la lista.
    */
    _Util_InvertirIndicesValoresM(lista, valorIndef?) {
        dicc := Map()

        if IsSet(valorIndef)
            for indice, valor in lista
                (!IsSet(valor) ? dicc[valorIndef] : dicc[valor]) := indice
        else
            for indice, valor in lista
                if IsSet(valor)
                    dicc[valor] := indice

        return dicc
    }

    _Util_InvertirIndicesValores(lista, valorIndef?) {
        Err_VerificarArg_Prv(lista, "lista", 1, FuncArg.EsLista)

        return lista.InvertirIndicesValores(valorIndef?)
    }

    Array.Prototype.DefineProp("InvertirIndicesValores", {Call: _Util_InvertirIndicesValoresM})
    global Util_InvertirIndicesValores := _Util_InvertirIndicesValores


    /*
        @function Util_InvertirClavesValoresM

        @description Invertir las claves y valores, de manera que los valores se conviertan en las claves y las claves en los valores. Si un valor esta repetido, el valor asociado que tendrá como clave será el de la última clave con dicho valor en el diccionario original.

        @param {Map} - Diccionario a invertir sus valores y clavess.

        @returns {Map} - Nuevo diccionario con los valores del diccionario original como claves y las claves como valores.
    */
    _Util_InvertirClavesValoresM(dicc) {
        _dicc := Map()

        for indice, valor in dicc
            _dicc[valor] := indice

        return _dicc
    }

    _Util_InvertirClavesValores(dicc) {
        Err_VerificarArg_Prv(dicc, "dicc", 1, FuncArg.EsDicc)

        return dicc.InvertirClavesValores()
    }

    Map.Prototype.DefineProp("InvertirClavesValores", {Call: _Util_InvertirClavesValoresM})
    global Util_InvertirClavesValores := _Util_InvertirClavesValores


    /*
        @function Util_InvertirOrdenM

        @description Invertir el orden de los elementos de una lista. Si nuevo es true, se crea una nueva lista con los elementos invertidos. Si no, se modifica la lista original.

        @param {Array} lista - Lista a invertir.
        @param {Boolean} nuevo - Si se crea una nueva lista o se modifica la original.

        @returns {Array} - Lista con los elementos invertidos.
    */
    _Util_InvertirOrdenM(lista, nuevo := false) {
        if !nuevo {
            Loop lista.Length // 2 {
                if lista.Has(A_Index) 
                    valor := lista[A_Index]
                indiceFinal := lista.Length - A_Index + 1

                if lista.Has(indiceFinal)
                    lista[A_Index] := lista[indiceFinal]
                else
                    lista.Delete(A_Index)

                if IsSet(valor)
                    lista[indiceFinal] := valor
                else
                    lista.Delete(indiceFinal)
            }
        }
        else {
            _lista := lista
            lista := []
            Loop _lista.Length {
                indice := _lista.Length - A_Index + 1
                lista.Push(_lista.Has(indice) ? _lista[indice] : unset)
            }
        }

        return lista
    }

    Array.Prototype.DefineProp("InvertirOrden", {Call: _Util_InvertirOrdenM})


    /*
        @function Util_ObtenerIndices
        
        @description Obtener una lista de índices de una lista. Se recorre la lista y, para cada elemento, comprueba si valor coincide con alguno de los valores pasados a la función (se aceptan valores no definidos). Si coincide, el índice se incluirá en la lista devuelta. Si no se pasa nigún valor, se devuelven los índices que tengan algún valor definido.

        @param {Array} lista - Lista de donde obtener los índices.
        @param {Any} valores - Serie de valores a ser comparado con cada elemento de la lista.

        @returns {Array} - Array de índices. Si se pasa valor, índices de los elementos que coinciden. Si no se pasa valor, índices con elementos definidos.

        @todo Se podría hacer más rápido creando un diccionario donde las claves son los valores, y así la comprobación sería inmediata. El problema es que los valores no definidos no se pueden guardar como clave, así que habría que usar una referencia a un objeto vacío {} para usarlo como clave y tenerlo en cuenta cuando se comprueba un valor no definido.
    */
    _Util_ObtenerIndices(lista, valores*) {
        indices := []

        if valores.Length > 0 {
            valoresDicc := valores.InvertirIndicesValores(indef := {})
            for indice, valor in lista
                if valoresDicc.Has(valor ?? indef)  ; Sin invertir lista valores usar valores.ContieneValorvalor(valor)
                    indices.Push(indice)

        }
        else {
            for indice, valor in lista
                if IsSet(valor)
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

        @todo Se podría hacer más rápido creando un diccionario donde las claves son los valores, y así la comprobación sería inmediata. El problema es que los valores no definidos no se pueden guardar como clave, así que habría que usar una referencia a un objeto vacío {} para usarlo como clave y tenerlo en cuenta cuando se comprueba un valor no definido.
    */
    _Util_ObtenerClavesM(dicc, valores*) {
        claves := []

        if valores.Length > 0 {
            valoresDicc := valores.InvertirIndicesValores()
            for clave, valor in dicc
                if valoresDicc.Has(valor)  ; Sin invertir lista valores usar valores.ContieneValorvalor(valor)
                    claves.Push(clave)

        }
        else {
            for clave, valor in dicc
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
        FA_RangoPosicion := FuncArg((p) => p > 0 and p <= numArgs, "Validar", "La posición debe estar entre 1 y numArgs")
        posClave := Err_VerificarArg_Prv(posClave, "posClave", 3, FuncArg.EsEntero, FuncArg.Entero, FA_RangoPosicion)

        valoresRef := Util_CrearListaRefs(numArgs)
        claves := Array()

        if pos_valor.Length > 0 {
            Err_VerificarArg_Prv(pos_valor, "pos_valor", 4, FuncArg((pv) => Ceil(pv.Length / 2) <= numArgs, "Validar", "El número de valores debe ser <= numArgs")) 

            while enum(valoresRef*) {
                if !IsSetRef(valoresRef[posClave])
                    continue

                valorOK := true
                Loop pos_valor.Length {
                    if !pos_valor.Has(A_Index) {
                        A_Index++
                        continue
                    }

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

                for valorRef in valoresRef
                    if A_Index != posClave and IsSetRef(valorRef) {
                        claves.Push(%valoresRef[posClave]%)
                        break
                    }
            }
        } 
        else
            while enum(valoresRef*)
                if IsSetRef(valoresRef[posClave])
                    claves.Push(%valoresRef[posClave]%)

        return claves
    }

    ; Se añade como método a Enumerator
    Enumerator.Prototype.DefineProp("Claves", {Call: _Util_ObtenerClaves})
    global Util_ObtenerClaves := _Util_ObtenerClaves


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

        valoresRef := Util_CrearListaRefs(numArgs)

        while enum(valoresRef*) {
            coincide := true
            Loop pos_valor.Length {
                posArg := Err_VerificarArg_Prv(pos_valor[A_Index], "pos_valor[" A_Index "]", 2 + A_Index, FuncArg.EsEntero, FuncArg.Entero, FuncArg((p) => p <= numArgs and p >= 1, "Validar", "La posición debe estar entre 1 y numArgs"))

                ; Si creamos un FuncArg podemos generar un bucle. ContieneValor es llamado en FuncArg.
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
    Map.Prototype.DefineProp("ContieneValor", {Call: (e, v) => _Util_ContieneValor(e, 2, 2, v)})
    Array.Prototype.DefineProp("ContieneValor", {Call: (e, v) => _Util_ContieneValor(e, 1, 1, v)})
    global Util_ContieneValor := _Util_ContieneValor


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
        fin := Err_VerificarArg_Prv(fin, "fin", 5, FuncArg.EsEntero, FuncArg.Entero, FuncArg((i) => inicio >= 1 and fin >= inicio, "Validar", "Los indices tienen que cumplir 1 <= inicio <= fin"))

        if lista.Length == 0 or (fin - inicio) <= 0
            return

        medio := (fin-inicio) // 2 + 1

        lista.Ordenar(lista, comparar, inicio, medio)
        lista.Ordenar(lista, comparar, medio+1, fin)

        _Util_Combinar_Prv(lista, comparar, inicio, medio, fin)
    }

    ; Se añade como método a Array
    Array.Prototype.DefineProp("Ordenar", {Call: _Util_OrdenarListaM})

    /*
        @function _Util_BusquedaBinaria_Prv

        @description Buscar un valor en una lista ordenada utilizando el algoritmo de búsqueda binaria. FUNCIÓN PARA USO INTERNO QUE NO COMPRUEBA NINGÚN ARGUMENTO.

        @param {Array} lista - Lista ordenada donde buscar el valor. Se supone de longitud > 0.
        @param {Any} valor - Valor a buscar.
        @param {Func} comparar - Función de comparación de un par de valores. Devuelve <0, 0 o >0.
        @param {Integer} inicio - Posición del primer elemento de la sublista. Se supone >= 1 y <= fin.
        @param {Integer} fin - Posición del último elemento de la sublista. Se supone >= inicio y <= lista.Length.

        @returns {Integer} - Posición del valor en la lista. Si no se encuentra, devuelve 0.

        @throws {Err_FuncArgError} - Si hay algún error al comparar los valores.

        @complexity O(log n) siendo n el número de elementos de la lista.
    */
    _Util_BusquedaBinaria_Prv(lista, valor, comparar := (a, b) => StrCompare(String(a), String(b), true), inicio := 1, fin := lista.Length) {
        if fin < inicio
            return 0

        medio := (fin + inicio) // 2
        
        try
            resultadoComp := comparar(lista[medio], valor)
        catch as e
            throw Err_FuncArgError("Error al comparar valores en la búsqueda binaria", , , , , e, "comparar", 3, comparar)

        if resultadoComp == 0
            return medio
        else if resultadoComp > 0
            return _Util_BusquedaBinaria_Prv(lista, valor, comparar, inicio, medio - 1)
        else
            return _Util_BusquedaBinaria_Prv(lista, valor, comparar, medio + 1, fin)
    }

    /*       
        @function _Util_BuscarValorM

        @description Buscar un valor en una lista.

        @param {Array} lista - Lista ordenada donde buscar el valor.
        @param {Any} valor - Valor a buscar.
        @param {Func} comparar - Función de comparación de un par de valores. Devuelve <0, 0 o >0. En búsqueda lineal solo se usa 0 o !0 (valores iguales o no)
        @param {Boolean} binaria - Indica si se realiza una búsqueda binaria (funciona en listas ya ordenadas). Si no, se realiza una busqueda secuencial.
        @param {Integer} inicio - Posición del primer elemento de la sublista.
        @param {Integer} fin - Posición del último elemento de la sublista.

        @returns {Integer} - Posición del valor en la lista. Si no se encuentra, devuelve 0.

        @complexity O(log n) siendo n el número de elementos de la lista, si la búsqueda es binaria en una lista ordenada; O(n) si la búsqueda es secuencial.
    */
    _Util_BuscarValorM(lista, valor, comparar := (a, b) => StrCompare(String(a), String(b), true), binaria := true, inicio := 1, fin := lista.Length) {
        if lista.Length == 0
            return 0
        Err_VerificarArg_Prv(comparar, "comparar", 3, FuncArg.EsLlamable)
        inicio := Err_VerificarArg_Prv(inicio, "inicio", 4, FuncArg.EsEntero, FuncArg.Entero)
        fin := Err_VerificarArg_Prv(fin, "fin", 5, FuncArg.EsEntero, FuncArg.Entero, FuncArg((f) => inicio >= 1 and f >= inicio and f <= lista.Length, "Validar", "Los indices tienen que cumplir 1 <= inicio <= fin <= lista.Length"))

        if !binaria {
            for indice, v in lista
                try
                    if comparar(v, valor) == 0
                        return indice
                catch as e
                    throw  Err_FuncArgError("Error al comparar valores en la búsqueda lineal", , , , , e, "comparar", 3, comparar)

            return 0
        }
        else
            return _Util_BusquedaBinaria_Prv(lista, valor, comparar, inicio, fin)
    }

    ; Se añade como método a Array
    Array.Prototype.DefineProp("BuscarValor", {Call: _Util_BuscarValorM})


    /*
        @function Util_LimpiarListaEnteros

        @description Obtener una lista en el mismo orden manteniendo los enteros que están dentro de de un rango y eliminando el resto (vacíos y no enteros). También se eliminan los enteros váĺidos duplicados (se mantiene el primer valor y se eliminan el resto duplicados).

        @param {Array} lista - Lista de valores.
        @param {Integer} minValor - Mínimo valor admitido entre los valores enteros en la lista
        @param {Integer} maxValor - Máximo valor admitido entre los valores enteros en la lista
        @param {Boolean} nuevo - Si se crea una nueva lista o solo se modifica la original.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_ValorArgError} - Si los valores de los argumentos no son válidos.

        @returns {Array} - Lista con los valores enteros dentro del rango sin duplicar y en el mismo orden una vez eliminado todo lo demás.
    */
    _Util_LimpiarListaEnterosM(lista, minValor?, maxValor?, nuevo := false) {
        if IsSet(minValor)
            minValor := Err_VerificarArg_Prv(minValor, "minValor", 2, FuncArg.EsEntero, FuncArg.Entero)
        if IsSet(maxValor)
            maxValor := Err_VerificarArg_Prv(maxValor, "maxValor", 3, FuncArg.EsEntero, FuncArg.Entero, FuncArg((n) => !IsSet(minValor) or n >= minValor, "Validar", "Debe cumplirse minValor <= maxValor"))

        return lista.Sub((_, v) => IsSet(v) and (v is Integer) and (!IsSet(minValor) or v >= minValor) and (!IsSet(maxValor) or v <= maxValor), nuevo).EliminarDuplicados(nuevo)
    }

    _Util_LimpiarListaEnteros(lista, minValor?, maxValor?, nuevo := false) {
        Err_VerificarArg_Prv(lista, "lista", 2, FuncArg.EsLista)
        return lista.LimpiarEnteros(minValor?, maxValor?, nuevo)
    }

    Array.Prototype.DefineProp("LimpiarEnteros", {Call: Util_LimpiarListaEnterosM})
    global Util_LimpiarListaEnteros := _Util_LimpiarListaEnteros


    /*
        @function Util_EliminarVaciosMA

        @decripción Eliminar los valores vacíos no definidos una lista. La lista se modifica quedando con los valores 
        no vacíos. 

        @param {Array} lista - Array a eliminar sus valores vacíos.
        @param {Boolean} nuevo - Si se crea una nueva lista o solo se modifica la original.

        @returns {Array} - Lista con los valores no vacíos.
    */
    _Util_EliminarVaciosMA(lista, nuevo := false) {
        if !nuevo {
            indice := lista.Length
            Loop lista.Length {
                if !lista.Has(indice)
                    lista.RemoveAt(indice)

                indice--
            }
        }
        else {
            _lista := lista
            lista := []
            for indice, valor in _lista
                if IsSet(valor)
                    lista.Push(valor)
        }

        return lista
    }

    ; Se añade como método a Array
    Array.Prototype.DefineProp("EliminarVacios", {Call: _Util_EliminarVaciosMA})


    /*
        @function Util_EliminarVacios

        @description Eliminar los elementos vacíos de un enumerable. Se consideran elementos vacíos aquellos cuyos valores en las posiciones indicadas de los argumentos no están definidos.

        @param {Object<__Enum>|Enumerator} enum - Objeto enumerable.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable.
        @param {Integer} posiciones - Serie de posiciones de los argumentos de cada elemento del enumerable. Los valores del elemento del enumerable en orden en esas posiciones son los que se pomprueban si están definidos. Si una posición de posiciones no está definida se ignora. Si se introducen posiciones repetidas, se considera solo la primera introducida. Si no se introduce ninguna posición, se comprueban todos los valores del elemento del enumerable.

        @throws {Err_TipoArgError|Err_MethodError} - Si hay algún error al verificar el enumerable.
        @throws {Err_ValorArgError} - Si los valores de los argumentos no son válidos.

        @returns {Array} - Lista de elementos del enumerable que tienen un valor definido. Devuelve un array de arrays.
    */
    _Util_EliminarVaciosM(enum, numArgs, posiciones*) {
        enum := Err_VerificarEnumerable(enum, numArgs)
        posiciones := Err_VerificarArg_Prv(posiciones, "posiciones", 3, FuncArg((l) => l.Length == 0 ? Util_CrearRango(numArgs) : l.LimpiarEnteros(1, numArgs, true), "Convertir", "Los valores de las posiciones no son válidos", Err_ValorArgError))
        
        resultado := Array()
        valoresRef := Util_CrearListaRefs(numArgs)

        while enum(valoresRef*) {
            valores := Array()

            for valorRef in valoresRef
                valores.Push(%valorRef%?)

            for posicion in posiciones
                if valores.Has(posicion) {
                    resultado.Push(valores)
                    break    
                }
        }

        return resultado
    }

    ; Se añade como método a Enumerator
    Enumerator.Prototype.DefineProp("EliminarVacios", {Call: _Util_EliminarVaciosM})
    global Util_EliminarVacios := _Util_EliminarVaciosM


    /*
        @function Util_EliminarDuplicadosMA

        @decripción Eliminar los valores duplicados de una lista. La lista se modifica quedando con los valores no duplicados. Si los valores son objetos, no se compara su contenido; solo su referencia. Es decir, que si dos elementos tienen como referenci el mismo objeto, se considera duplicado, pero si tienen como referencia objetos distintos que tienen el mismo contenido, se consideran elementos no duplicados.

        @param {Array} lista - Array a eliminar sus duplicados
        @param {Boolean} final - Si true se eliminan los elementos duplicados del final quedando como único no duplicado el primero; si false se eliminan los primeros elementos duplicados quedando como único no duplicado el último.
        @param {Boolean} nuevo - Si se crea una nueva lista o solo se modifica la original.

        @returns {Array} - Lista con los valores no duplicados.

        @complexity O(n^2) siendo n el número de elementos de la lista, si se modifica la lista original. Si se crea una nueva lista, la complejidad es O(n).
    */
    _Util_EliminarDuplicadosMA(lista, final := true, nuevo := false) {        
        valoresDup := Map()
        valorIndef := {}  ; Al usarse la referencia como clave, es única para este objeto.

        if !final ; Recorrer de fin a inicio: conservar la última aparición
            indice := incBorrar := incNoBorrar := -1
        else { ; Recorrer de inicio a fin: conservar la primera aparición
            indice := incNoBorrar := 1
            incBorrar := 0
        }

        if !nuevo {
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
        else {
            _lista := lista
            lista := []
            Loop _lista.Length {
                valor := _lista.Has(indice) ? _lista[indice] : valorIndef
                if !valoresDup.Has(valor) {
                    valoresDup[valor] := true
                    lista.Push(_lista.Has(indice) ? _lista[indice] : unset)
                }

                indice += incNoBorrar
            }

            if !final
                lista.InvertirOrden()
        }

        return lista
    }

    ; Se añade como método a Array
    Array.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosMA})


    /*
        @function Util_EliminarDuplicadosMM

        @decripción Eliminar los valores duplicados de un diccionario. Si los valores son objetos, no se compara su contenido; solo su referencia. Es decir, que si dos elementos tienen como referencia el mismo objeto, se considera duplicado, pero si tienen como referencia objetos distintos que tienen el mismo contenido, se consideran elementos no duplicados.

        @param {Map} dicc - Map a eliminar sus duplicados
        @param {Boolean} nuevo - Si se crea un nuevo diccionario o solo se modifica el original.

        @returns {Map} - Diccionario con los valores no duplicados.
    */
    _Util_EliminarDuplicadosMM(dicc, nuevo := false) {
        valoresDup := Map()

        if !nuevo {
            clavesBorrables := []

            for clave, valor in dicc
                if !valoresDup.Has(valor)
                    valoresDup[valor] := true
                else
                    clavesBorrables.Push(clave)

            for clave in clavesBorrables
                dicc.Delete(clave)
        }
        else {
            _dicc := dicc
            dicc := Map()
            for clave, valor in _dicc
                if !valoresDup.Has(valor) {
                    dicc[clave] := valor
                    valoresDup[valor] := true
                } 
        }

        return dicc
    }

    ; Se añade como método a Map
    Map.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosMM})


    /*
        @function Util_EliminarDuplicados

        @description Eliminar los elementos duplicados de un enumerable. Se consideran elementos duplicados aquellos que tienen iguales en orden los valores en las posiciones indicadas de los argumentos.

        @param {Object<__Enum>|Enumerator} enum - Objeto enumerable.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable.
        @param {Integer} posiciones - Serie de posiciones de los argumentos de cada elemento del enumerable. Los valores de cada elemento del enumerable en orden en esas posiciones son los que se comparan. Si una posición de posiciones no está definida se ignora. Si se introducen posiciones repetidas, se considera solo la primera introducida. Si no se introduce ninguna posición, se comparan todos los valores del elemento del enumerable. Tener en cuenta que el valor de algún argumento puede no estar definido.

        @throws {Err_TipoArgError|Err_MethodError} - Si hay algún error al verificar el enumerable.
        @throws {Err_ValorArgError} - Si los valores de los argumentos no son válidos.

        @return {Array} - Lista de elementos del enumerable no duplicados. Devuelve un array de arrays.
    */
    _Util_EliminarDuplicadosM(enum, numArgs, posiciones*) {
        enum := Err_VerificarEnumerable(enum, numArgs)
        posiciones := Err_VerificarArg_Prv(posiciones, "posiciones", 3, FuncArg((l) => l.Length == 0 ? Util_CrearRango(numArgs) : l.LimpiarEnteros(1, numArgs, true), "Convertir", "Los valores de las posiciones no son válidos", Err_ValorArgError))
        
        valoresDup := Map()
        resultado := Array()
        valoresRef := Util_CrearListaRefs(numArgs)

        while enum(valoresRef*) {
            valores := Array()
            subValores := Array()

            for valorRef in valoresRef
                valores.Push(%valorRef%?)

            for posicion in posiciones
                subValores.Push(valores.Has(posicion) ? valores[posicion] : unset)

            hash := Util_Hash("PLANO", subValores*).Hash
            if !valoresDup.Has(hash) {
                valoresDup[hash] := true
                resultado.Push(valores)
            }
        }

        return resultado
    }

    ; Se añade como método a Enumerator
    Enumerator.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosM})
    global Util_EliminarDuplicados := _Util_EliminarDuplicadosM


    /*
        @function Util_CadenaALista

        @description Convertir una cadena en una lista. Se puede indicar el separador de los elementos de la cadena. Si no se indica, se considera que el separador es el punto.

        @param {String} cadena - Cadena a convertir en lista.
        @param {String} separador - Separador de los elementos de la cadena.
        @param {String} caracteres - Caracteres a limpiar al final e inicio de cada elemento. Si no se pasa ningún valor, se eliminan los espacios en blanco y tabuladores.

        @returns {Array} - Lista con los elementos de la cadena.
    */
    Util_CadenaALista(cadena, separador := ".", caracteres?) {
        Err_VerificarArg_Prv(cadena, "cadena", 1, FuncArg.EsCadena)
        Err_VerificarArg_Prv(separador, "separador", 2, FuncArg.EsCadena)
        if IsSet(caracteres)
            Err_VerificarArg_Prv(caracteres, "caracteres", 3, FuncArg.EsCadena)

        try
            lista := StrSplit(cadena, separador)
        catch as e
            throw Err_TipoArgError("El argumento no es una cadena válida", , , , , e, "cadena", 1, cadena, Type(cadena))

        for valor in lista
            lista[A_Index] := Trim(valor, caracteres?)

        return lista
    }


    Util_CadenaADato(cadena) {
        tablaTransicion := Map(
            "inicio", Map(
                "recibe_}", "clave-valor|seccion"
            ), 
            "clave-valor|seccion", Map(
                "recibe_clave-valor", "clave-valor|seccion", 
                "recibe_seccion", "clave_valor|seccion"
            )
        )

        if RegExMatch(cadena, "U)^\s*{\s*(.*)\s*}\s*$", &resultado) != 0 {
            claves_valores := StrSplit(resultado[1], ",", A_Tab "`r`n" A_Space)
            dato := {}
            dato.__Item := Map()
            for clave_valor in claves_valores {
                if RegExMatch(clave_valor, "U)^(.+)\s*:\s*(.+)*$", &resultado) == 0
                    throw ValueError.CrearErrorAHK("El formato de " clave_valor " no es correcto como <propiedad: valor> de un objeto")

                prop := resultado[1]
                valor := Util_CadenaADato(resultado[2])
                dato.DefineProp(prop, {Value: valor})
            }
        }
        else if RegExMatch(cadena, "U)^\s*[\s*(.*)\s*]\s*$", &resultado) != 0 {
            valores := StrSplit(resultado[1], ",", A_Tab "`r`n" A_Space)
            dato := []
            for valor in valores {
                prop := resultado[1]
                valor := Util_CadenaADato(resultado[2])
                dato.DefineProp(prop, {Value: valor})
            }            
        }
        estado := "inicio"
        cadena := Trim(cadena)
        pos := 1

        while pos <= cadena.Length
        switch estado {
            case "inicio":
                if cadena[1] == "{"}"
                ; Implementar lógica para el estado "inicio"
                ; Aquí puedes agregar el código necesario para manejar este caso
                break

            default:
                
        }

    }


    /*
        @class Util_Hash

        @description Clase para crear objetos que generan un hash (de varios tipos) a partir de varios valores.

        @todo Mejorar la conversión a cadena de los float en HashPlano
    */
    class Util_Hash {
        static __New() {
            this._idObjeto := 1
            this._objetosId := Map()
            this.TIPO := Map("PLANO", 1, "MD5", 2, "SHA-1", 3, "SHA-2", 4, "SHA-3", 5)
        }

        /*
            @constructor

            @param {Integer|String} tipoHash - Tipo de algoritmo hash a aplicar. Se puede pasar el código entero o el nombre del tipo, ambos definidos en Util_Hash.TIPO
            @param {Any} valores - sucesión de valores a ser agregados. Los valores no definidos serán ignorados.
        */
        __New(tipoHash, valores*) {
            valores.EliminarVacios()
            this._valores := valores
            this.Tipo := tipoHash
        }

        /*
            @method _HasPlano

            @description Algoritmo hash plano que consiste en concatenar los valores almacenados en el objeto en una cadena resultante.

            @returns {String} - Cadena resultante con el hash generado.
        */
        _HashPlano() {
            resultado := ""
            for valor in this._valores {
                switch Type(valor) {
                    case "String":
                        resultado .= "S:" valor ":S"
                    case "Integer":
                        resultado .= "I:" String(valor) ":I"
                    case "Float":
                        resultado .= "F:" String(valor) ":F"
                    case "Object":
                        if !Util_Hash._objetosId.Has(valor)
                            Util_Hash._objetosId[valor] := Util_Hash._idObjeto++
                        resultado .= "O:" String(Util_Hash._objetosId[valor]) ":O"
                    default:
                        try
                            resultado .= "D:" String(valor) ":D"
                        catch as e
                            throw TypeError.CrearErrorAHK("El valor #" A_Index "guardado no puede convertirse a cadena", , , , , e)
                }
            }

            return resultado
        }

        /*
            @method AgregarValor

            @description Agregar valores que serán usados cuando se genere el hash.

            @param {Any} valores - sucesión de valores a ser agregados. Los valores no definidos serán ignorados.
        */
        AgregarValor(valores*) {
            valores.EliminarVacios()
            this._valores.Push(valores*)
        }

        /*
            @property Tipo

            @description Obtener y modificar el tipo de algoritmo hash a aplicar.

            @param {Integer|String} tipoHash - Tipo de algoritmo hash a aplicar. Se puede pasar el código entero o el nombre del tipo, ambos definidos en Util_Hash.TIPO

            @returns {Integer} - Código del tipo hash guardado.
        */
        Tipo {
            get => this._tipoHash

            set {
                if Util_Hash.TIPO.Has(value)
                    this._tipoHash := Util_Hash.TIPO[value]
                else {
                    if !IsInteger(value) or !Util_Hash.TIPO.ContieneValor(value)
                        throw Err_ValorArgError("El código del tipo de hash no es válido", , , , , , "Tipo", 1, value)

                    this._tipoHash := Integer(value)
                }
            }
        }

        /*
            @property Hash

            @description Obtener el hash generado a partir de los valores almacenados en el objeto. El tipo de hash generado depende del valor asignado a la propiedad Tipo. Esta propiedad solo tiene la función get.

            @return El hash generado.
        */
        Hash {
            get {
                switch this.Tipo {
                    case Util_Hash.TIPO["PLANO"]:
                        return this._HashPlano()
                        
                    case Util_Hash.TIPO["MD5"]:
                    case Util_Hash.TIPO["SHA-1"]:
                    case Util_Hash.TIPO["SHA-2"]:
                    case Util_Hash.TIPO["SHA-3"]:
                    default:
                }
            }
        }
    }


    /*
        @class Util_MapOrden

        @description 

        @todo Si el diccionario no tiene función para comparar las claves, éstas deben estar ordenadas en el orden en que se van metiendo.

    */
    class Util_MapOrden extends Map {
        static FACTOR_NM := 10  ; Número de veces de m a partir del cual se considera n mucho mayor que m.

        /*
            @static DesdeMap

            @description Obtener un objeto MapOrden a partir de un objeto Map. El objeto MapOrden obtenido puede ser el mismo objeto Map original modificado, o se puede crear uno completamente nuevo. En el caso de ser un objeto nuevo, aunque el diccionario Map se clona, sus valores no.

            @param {Map} dicc - Diccionario Map a partir del cual obtener un objeto MapOrden
            @param {Func} comparar - Función de comparación a ser usada por MapOrden. Tiene que admitir dos argumentos y devolver <0, 0 o >0 como resultado de la comparación. Si no se pasa función de comparación, el orden de los elementos es el orden en que queden las claves obtenidas del Map original.
            @param {Boolean} nuevo - Si se obtiene un objeto nuevo o solo se modifica el original.

            @throws {Err_TipoArgError} - Si no se pasa una función que admita dos argumentos para ser guardada.
            @throws {MethodError} - Si hay error al reordenar las claves.

            @returns {MapOrden} - El objeto MapOrden.

            @complexity O(n) si no se pasa comparar; O(n*log(n)) si se pasa comparar. Siendo n el número de elementos en dicc.
        */
        static DesdeMap(dicc, comparar?, nuevo := true) {
            Err_VerificarArg_Prv(dicc, "dicc", 1, FuncArg.EsDicc)

            _base := dicc.Base
            if nuevo
                dicc := dicc.Clone()
            dicc.Base := this.Prototype
            dicc._claves := dicc.Claves()
            
            if IsSet(comparar) {
                try
                    dicc.Comparar := comparar
                catch as e {
                    if !nuevo {
                        dicc.Base := _base
                        dicc._claves := unset
                        if dicc.HasProp("_comparar")
                            dicc._comparar := unset
                    }
                    throw e
                }                
            }

            return dicc
        }

        /*
            @constructor

            @param {Func} comparar - Función que admite dos valores a ser comparados. Devuelve <1, 0 o >1. Si no hay función de comparación, el orden del diccionario es el orden en que se meten las claves.
            @param {Object} args - lista de argumentos en orden clave y valor para ser guardados en el MapOrden. Misma estructura de argumentos que se pasan para crear un Map().

            @throws {Err_ValorArgError} - Si los valores args no permiten crear el diccionario.
            @throws {Err_TipoArgError} - Si la función de comparación no es válida.

            @complexity O(n) si no se pasa comparar; O(n*log(n)) si se pasa comparar. Siendo n el número de pares clave-valor
        */
        __New(comparar?, args*) {
            try
                super._New(args*)
            catch as e
                throw Err_ValorArgError("No se han podido crear el diccionario", , , , , e, "args", 1, args)

            if !IsSet(comparar)
                this._claves := args.Sub((i, v) => Mod(i, 2) == 1 and IsSet(v) and this.Has(v), true).EliminarDuplicados(false, true)
            else {
                this._claves := super.Claves()
                this.Comparar := comparar
            }
        }

        /*
            @method Claves
            
            @description Obtener las claves ya ordenadas del diccionario. Este método sobrecarga a Claves de Map. Si se pasan valores, se obtienen las claves que estén asociadas a ese valor.

            @param {Any} valores - Valores a los que se les quiere obtener las claves.

            @returns {Array} - Array de claves obtenidas.

            @complexity O(n) si no se pasa valores; O(n+m) si se pasan valores, donde n es el número de claves y m el número de valores.
        */
        Claves(valores*) {
            if valores.Length > 0 {
                _claves := []
                valoresDicc := valores.InvertirIndicesValores()
    
                for clave in this._claves
                    if valoresDicc.Has(super[clave])
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

            @complexity O(n*log(n)) en set; O(1) en get. Siendo n el número de claves.
        */
        Comparar {
            get {
                if this.HasProp("_comparar")
                    return this._comparar
                else
                    throw PropertyError.CrearErrorAHK("No hay guardada ninguna función de comparación")
            }

            set {
                Err_VerificarArg_Prv(value, "value", 1, FuncArg.Admite2Args)
                
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

            @complexity Siendo n el número de claves ya guardadas y m el número de pares clave-valor de args:
                - O(n + m) si no se pasa comparar.
                - O((n + m) log m) => O(n + m log m) si se pasa comparar y n es mucho mayor que m [m * Util_MapOrden.FACTOR_NM < n] o m == 1.
                - O(m + n log n) si se pasa comparar y n es similar a m [m * Util_MapOrden.FACTOR_NM > n]
        */
        Set(args*) {
            try
                super.Set(args*)
            catch as e
                throw Err_ValorArgError("No se han podido guardar los pares clave-valor", , , , , e, "args", 1, args)

            argsClaves := args.Sub((i, v) => Mod(i, 2) == 1 and IsSet(v) and this.Has(v), true)

            try
                comparar := this.Comparar

            if IsSet(comparar) {
                if argsClaves.Length > 1 and argsClaves.Length * Util_MapOrden.FACTOR_NM > this._claves.Length { ; Versión más óptima cuando n no es mucho mayor que m
                    this._claves := super.Claves()
                    this._claves.Ordenar(comparar)
                }
                else { ; Versión más óptima cuando n >>> m (por ej, 10 veces mayor) o m == 1
                    argsClaves := argsClaves.EliminarDuplicados(false, true)

                    try
                        argsClaves.Ordenar(comparar)
                    catch as e
                        throw MethodError.CrearErrorAHK("No se han podido ordenar las claves recibidas", , , , , e)

                    this._claves.Push(argsClaves*)
                    this._claves := this._claves.EliminarDuplicados(false, true)

                    try
                        _Util_Combinar_Prv(this._claves, comparar, 1, this._claves.Length - argsClaves.Length + 1, this._claves.Length)
                    catch as e
                        throw MethodError.CrearErrorAHK("Error al combinar las claves", , , , , e)
                }
            }
            else {
                this._claves.Push(argsClaves*)
                this._claves := this._claves.EliminarDuplicados(false, true)
            }
        }

        /*
            @method __Item

            @description Similar al método __Item de Map, pero reordenando las claves.

            @throws {Err_ValorArgError} - Si no se pueden guardar los valores como se haría en el Map.
            @throws {MethodError} - Si hay error al combinar las claves.

            @complexity O(n) siendo n el número de claves ya guardadas, con o sin función de comparar.
        */
        __Item[clave] {
            set {
                try
                    super[clave] := value
                catch as e
                    throw Err_ValorArgError("No se ha podido guarda el par clave-valor", , , , , e, "value", 1, value)
    
                try
                    comparar := this.Comparar
    
                if IsSet(comparar) {
                    if this._claves.BuscarValor(clave, comparar, true) == 0 {
                        this._claves.Push(clave)
                        try
                            _Util_Combinar_Prv(this._claves, comparar, 1, this._claves.Length, this._claves.Length)
                        catch as e
                            throw MethodError.CrearErrorAHK("Error al combinar las claves", , , , , e)
                    }
                }
                else {
                    indice := this._claves.BuscarValor(clave, (v1, v2) => !(v1 == v2), false)
                    if indice == 0
                        this._claves.Push(clave)
                    else if indice < this._claves.Length {
                        this._claves.RemoveAt(indice)
                        this._claves.Push(clave)
                    }
                }
            }
        }

        /*
            @method Enum

            @description Devolver una función que permite recorrer las claves del diccionario ordenadas. La función devuelve las claves y opcionalmente los valores asociados a las claves.

            @param {Integer} numArgs - Número de argumentos que admitirá la función devuelta. Si es 1, solo se devuelven las claves. Si es 2, se devuelven las claves y los valores asociados.

            @throws {Err_ValorArgError} - Si el número de argumentos no es 1 o 2.

            @returns {Func} - Función que permite recorrer las claves del diccionario ordenadas.

            @complexity O(1).
        */
        __Enum(numArgs) {
            Err_VerificarArg_Prv(numArgs, "numArgs", 1, , FuncArg((n) => n == 1 or n == 2, "Validar", "El número de argumentos tiene que ser 1 o 2"))

            Enum(claveRef?, valorRef?) {
                static indice := 1

                if this.Count < indice or this._claves.Length < indice
                    return false

                if IsSet(claveRef) {
                    Err_VerificarArg_Prv(claveRef, "claveRef", 1, FuncArg.EsReferencia)
                    %claveRef% := this._claves[indice++]
                }
                if IsSet(valorRef) {
                    Err_VerificarArg_Prv(valorRef, "valorRef", 2, FuncArg.EsReferencia)
                    %valorRef% := this[%claveRef%]
                }

                return true
            }

            return Enum
        }

        /*
            @method Delete

            @description Similar al método Delete de Map, pero eliminando también la clave de la ordenación de claves.

            @param {Object} - Clave a borrar.

            @throws {UnsetItemError} - Si la clave a borrar no existe.

            @complexity O(n) siendo n el número de claves.
        */
        Delete(clave) {
            try
                valor := super.Delete(clave)
            catch as e
                throw UnsetItemError.CrearErrorAHK("No existe la clave en el diccionario", , , , , e)

            this._claves.RemoveAt(this._claves.BuscarValor(clave, this.Comparar))

            return valor
        }

        /*
            @method Clear

            @description Similar al método Clear de Map, pero eliminando también todas las claves de la ordenación de claves

            @complexity O(n) siendo n el número de claves.
        */
        Clear() {
            super.Clear()
            this._claves := []
        }

        /*
            @method Clone

            @description Clonar el objeto MapOrden. Se clona el diccionario y las claves.

            @returns {MapOrden} - Clon del objeto MapOrden.

            @complexity O(n) siendo n el número de claves.
        */
        Clone() {
            _this := this.Clone()
            _this._claves := this.Claves()

            return _this
        }

        /*
            @property Valor

            @description Propiedad para acceder a los valores del diccionario por posición de clave ordenada. Se lanza UnsetItemError si no existe la clave en esa posición.

            @param {Integer} posClave - Posición de la clave en la ordenación de claves. 1 accede a la primera clave y -1 accede a la última.

            @throws {UnsetItemError} - Si no existe la clave en esa posición.

            @complexity O(1).
        */      
        Valor[posClave] {
            get {
                try
                    return this[this._claves[posClave]]
                catch as e
                    throw UnsetItemError.CrearErrorAHK("No existe clave en esa posición", , , , , e)
           }

            set {
                try
                    return this[this._claves[posClave]] := value
                catch as e
                    throw UnsetItemError.CrearErrorAHK("No existe clave en esa posición", , , , , e)
            }
        }

        /*
            @method ToString

            @description Devuelve una representación en cadena del objeto MapOrden.

            @param {Integer} numArgs - Número de argumentos que admitirá la representación en cadena. Si es 1, solo se devuelven las claves. Si es 2, se devuelven las claves y los valores asociados. (Para mantener la compatibilidad con ToString de Map)
            @param {String} sepGrupo - cadena para separar los pares clave-valor.
            @param {String} sepPartes - cadena para separar cada clave de cada valor.

            @returns {String} - Representación en cadena del objeto MapOrden.

            @complexity O(n) siendo n el número de claves.
        */
        ToString(numArgs := 2, sepGrupo := ";", sepPartes := ":") {
            sepGrupo := Err_VerificarArg_Prv(sepGrupo, "sepGrupo", 3, FuncArg.Cadena)
            sepPartes := Err_VerificarArg_Prv(sepPartes, "sepPartes", 4, FuncArg.Cadena)

            cadena := ""
            for clave in this._claves {
                try
                    cadena .= String(clave)
                catch
                    cadena .= "<No Imprimible>"
                
                if numArgs == 2 {
                    cadena .= sepPartes " "

                    try
                        cadena .= this[clave]
                    catch
                        cadena .= "<No Imprimible>"
                }

                cadena .= sepGrupo " "
            }

            return RTrim(cadena, sepGrupo " ")
        }
    }

    /*
        @class Util_ArbolMapOrden

        @description Estructura de árbol donde los nodos intermedios son diccionarios ordenados. Los valores de los nodos intermedios son las subclaves de los diccionarios, y los valores de los nodos finales son objetos Hoja con el valor asociado a la clave completa en el árbol. Cada clave completa en el árbol es la concatenación de las subclaves de los nodos intermedios desde la raíz hasta el nodo final. Cada diccionario intermedio que hace de nodo ordena las subclaves de ese nivel con StrCompare.
    */
    class Util_ArbolMapOrden {

        /*
            @class Hoja 

            @description Clase para los nodos finales del árbol para diferenciarlo de los nodos intermedios que son MapOrden (así un nodo final u hoja puede tener un valor de tipo MapOrden). Cada nodo final tiene un valor asociado a la clave completa en el árbol.        
        */
        class Hoja {
            __New(valor) => this._valor := valor
        }
        
        /*
            @constructor

            @param {Enumerable} enumerable - Enumerable que admite dos argumentos clave-valor, a partir del cual se crea el árbol. Cada clave es una cadena (String) completa del árbol formada por subclaves separadas por puntos.

            @throws {Err_TipoArgError|MethodError} - Si el argumento enum no es un enumerable válido.

            @complexity O(n * m) siendo n el número de claves del diccionario y m el número de subclaves.
        */
        __New(enum?) {            
            if IsSet(enum) {
                enum := Err_VerificarEnumerable(enum, 2)

                this._raiz := Util_MapOrden(StrCompare)
            
                for clave, valor in enum
                    this[clave] := valor
            }
            else
                this._raiz := Util_MapOrden(StrCompare)
        }

        /*
            @method Set
    
            @description Guardar una serie de valores en el árbol. Se pasa como argumentos los pares clave valor. Si una clave o valor no esá definido, se ignora.

            @param {String|Any} args - Pares clave valor a guardar en el árbol.

            @complexity O(n * m) siendo n el número de pares clave-valor y m el número de subclaves.
        */
        Set(args*) {
            Loop args.Length // 2
                if args.Has(A_Index) and args.Has(A_Index + 1)
                   this[args[A_Index]] := args[A_Index + 1]
        }

       /*
            @method _ObtenerValoresProf_Prv

            @description De manera recursiva en profundidad, obtener un diccionario ordenado MapOrden con todos los valores a partir de los nodos del árbol. Cada clave del diccionario devuelta en el diccionario es una clave completa del árbol asociado con cada valor. ***ESTA FUNCIÓN NO COMPRUEBA ARGUMENTOS. SOLO USO INTERNO ***

            @param {MapOrden} args - pares de valores Clave-Nodo. El nodo es el punto a partir del cual obtener todos los valores por debajo de él, y la clave es la localización (lista de subclaves) de ese nodo en el árbol.
            
            @returns {MapOrden} - Un diccionario MapOrden (sin función de comparación asignada) con todos los valores a partir de los nodos en el orden metidos. Cada clave asociada con cada valor es la clave completa en el árbol. El orden de las claves obtenidas en cada nodo es el mismo en el que se encuentran los valores a partir del nodo al realizar una búsqueda en profundidad DFS eligiendo en cada nivel los nodos en el orden en que están en el árbol.

            @complexity O(n) siendo n el número de nodos del árbol bajo el nodo.
       */
        static _ObtenerValoresProf_Prv(args*) {
            valores := Util_MapOrden()

            ObtenerValoresProf(clave, nodo) {
                if nodo is Util_ArbolMapOrden.Hoja
                    valores[clave] := nodo._valor
                else 
                    for subClave, subNodo in nodo
                        ObtenerValoresProf(clave "." subClave, subNodo)                        
            }

            Loop args.Length // 2 {
                clave := args[A_Index].ToString(1, ".")
                nodo := args[A_Index + 1]

                ObtenerValoresProf(clave, nodo)
            }

            return valores
        }


        /*
            @method _ObtenerValoresAnch_Prv

            @description De manera iterativa en anchura, obtener un diccionario ordenado MapOrden con todos los valores a partir de los nodos del árbol. Cada clave del diccionario devuelta en el diccionario es una clave completa del árbol asociado con cada valor. ***ESTA FUNCIÓN NO COMPRUEBA ARGUMENTOS. SOLO USO INTERNO ***

            @param {MapOrden} args - pares de valores Clave-Nodo. El nodo es el punto a partir del cual obtener todos los valores por debajo de él, y la clave es la localización (lista de subclaves) de ese nodo en el árbol.
            
            @returns {MapOrden} - Un diccionario MapOrden (sin función de comparación asignada) con todos los valores a partir de los nodos. Cada clave asociada con cada valor es la clave completa en el árbol. El orden de las claves es el mismo en el que se encuentran los valores a partir de cada nodo al realizar una búsqueda en anchura BFS eligiendo en cada nivel los nodos en el orden en que están en el árbol.

            @complexity O(n) siendo n el número de nodos del árbol bajo el nodo.
       */
        static _ObtenerValoresAnch_Prv(args*) {
            valores := Util_MapOrden()
            pilaNodos := Util_MapOrden( , args*)

            for clave, nodo in pilaNodos {
                _clave := clave.ToString(1, ".")
                if nodo is Util_ArbolMapOrden.Hoja
                    valores[_clave] := nodo._valor
                else
                    for subClave, subNodo in nodo
                        pilaNodos[_clave "." subClave] := subNodo
            }

            return valores
        }

        /*
            @method _ObtenerNodo_Prv

            @description Obtener un nodo a partir de subclaves que se aplican a partir de otro nodo. ***ESTA FUNCIÓN NO COMPRUEBA ARGUMENTOS. SOLO USO INTERNO ***

            @param {MapOrden} nodo - Nodo a partir del cual se aplican las subclaves.
            @param {Array} subClaves - Listado de subclaves a aplicar a partir del nodo. Si alguna subclave es una cadena vacía, se ignora. Si todas las subclaves son cadenas vacías, se devuelve el nodo.

            @throws {UnsetItemError} - Si no existe alguna subclave en el árbol a partir del nodo

            @returns {Util_ArbolMapOrden|Any} - El nodo resultante tras aplicar las subclaves.
        */
        static _ObtenerNodo_Prv(nodo, subClaves) {
            for subClave in subClaves {
                subClave := Trim(subClave)

                if subClave == ""
                    continue

                if nodo is Util_ArbolMapOrden.Hoja or !nodo.Has(subClave)
                    throw UnsetItemError.CrearErrorAHK("No existe el campo " subClave " de " subClaves.ToString(1, "."))

                nodo := nodo[subClave]
            }

            return nodo
        }

        /*
            @property Item

            @description Propiedad para acceder a los valores del árbol a partir de una clave. Si la clave no existe, se lanza UnsetItemError.  

            @param {String} clave - Clave en el árbol. Las subclaves se separan por puntos. Si se pasa una cadena vacía se obtienen todos los valores del árbol.
            @param {String} ordenValores - En Get, puede ser "prof" para un acceso recursivo o "anch" para un acceso iterativo.

            @returns {Any\MapOrden} - En set devuelve el valor que se acaba de guardar en la clave; en get devuelve un diccionario con todos los valores bajo esa clave. Si ordenValores es "prof", el orden de los valores es el obtenido en una búsqueda en profundidad bajo la clave; si es "anch", se hace búsqueda en anchura. EL MapOrden devuelto no tiene asignado una función de comparación.

            @throws {UnsetItemError} - Si no existe la clave en el árbol.

            @complexity en set O(m) siendo m el número de subclaves; en get O(n) siendo n el número de nodos del árbol.
        */
        __Item[clave, ordenValores := "prof"] {
            get {
                subClaves := Util_CadenaALista(Trim(clave, "." A_Space . A_Tab), ".")

                nodo := this._raiz

                if subClaves.Length > 0 {
                    nodo := Util_ArbolMapOrden._ObtenerNodo_Prv(nodo, subClaves)
                }

                return ordenValores == "prof" ? Util_ArbolMapOrden._ObtenerValoresProf_Prv(subClaves, nodo) : Util_ArbolMapOrden._ObtenerValoresAnch_Prv(subClaves, nodo)
            }

            set {
                subClaves := Util_CadenaALista(Trim(clave, "." A_Space . A_Tab), ".")

                if subClaves.Length == 0
                    throw UnsetItemError.CrearErrorAHK("Tienes que pasara alguna clave")

                nodo := this._raiz

                for subClave in subClaves {
                    if nodo is Util_ArbolMapOrden.Hoja
                        throw UnsetItemError.CrearErrorAHK("No se puede asignar un nodo en una clave que ya tiene un valor")

                    if subClaves.Length == A_Index {
                        if nodo.Has(subClave) and nodo[subClave] is Util_MapOrden
                            throw UnsetItemError.CrearErrorAHK("No se puede asignar el valor en un nodo intermedio")

                        nodo[subClave] := Util_ArbolMapOrden.Hoja(value)
                    }
                    else {
                        if !nodo.Has(subClave)
                            nodo[subClave] := Util_MapOrden(StrCompare)
                        
                        nodo := nodo[subClave]
                    }
                }
                
                return value
            }
        }

        /*
            @method _Delete

            @description Borrar la clave a partir de un nodo del árbol. Las subclaves que queden vacías al borrar la última subClave también se eliminan. ***ESTA FUNCIÓN NO COMPRUEBA ARGUMENTOS. SOLO USO INTERNO ***

            @param {MapOrden} nodo - Nodo del árbol.
            @param {Array} subClaves - Listado con las subclaves de la clave completa a borrar. Tiene que tener al menos una subclave.
            @param {Integer} indice - Índice de la subClave dentro de subClaves a partir de la cual se comprueba desde el nodo actual.
            @param {Boolean} borrarNodo - Si true se puede borrar cualquier tipo de nodo; si false solo se pueden borrar hojas y no nodos intermedios.

            @returns {MapOrden|Util_ArbolMapOrden.Hoja} - El nodo borrado.

            @throws {UnsetItemError} - Si no existe la clave en el árbol; si no se puede borrar un nodo que no es hoja.

            @complexity O(n) siendo n el número de subclaves.
        */
        static _Delete_Prv(nodo, subClaves, indice, borrarNodo := false) {
            if nodo is Util_ArbolMapOrden.Hoja or !nodo.Has(subClaves[indice])
                throw UnsetItemError.CrearErrorAHK("No existe el campo " subClaves[indice] " de " subClaves.ToString(1, ".") " clave en el árbol")

            if subClaves.Length == indice {
                if !borrarNodo and !(nodo[subClaves[indice]] is Util_ArbolMapOrden.Hoja)
                    throw UnsetItemError.CrearErrorAHK("No se puede borrar un nodo que no es hoja")
                    
                return nodo.Delete(subClaves[indice])
            }

            nodoHijo := nodo[subClaves[indice]]
            nodoBorrado := Util_ArbolMapOrden._Delete_Prv(nodoHijo, subClaves, indice + 1, borrarNodo)
            if nodoHijo.Count == 0
                nodo.Delete(subClaves[indice])

            return nodoBorrado
        }

        /*
            @method Delete

            @description Borrar la clave a partir de la raíz del árbol. Las subclaves que queden vacías al borrar la última subClave también se eliminan.

            @param {String} clave - Clave a borrar: subclaves separadas por puntos.
            @param {Boolean} borrarNodo - Si true se puede borrar cualquier tipo de nodo; si false solo se pueden borrar hojas y no nodos intermedios.

            @throws {UnsetItemError} - Si no existe la clave en el árbol; si no se puede borrar la raíz del árbol; si no se puede borrar un nodo que no es hoja.

            @returns {MapOrden|Util_ArbolMapOrden.Hoja} - El nodo resultante de borrar la clave.

            @complexity O(n) siendo n el número de subclaves de clave.
        */
        Delete(clave, borrarNodo := false) {
            subClaves := Util_CadenaALista(Trim(clave, "." A_Space . A_Tab), ".")

            if subClaves.Length == 0
                throw UnsetItemError.CrearErrorAHK("No se puede borrar la raíz del árbol. Tienes que pasar alguna clave")

            return Util_ArbolMapOrden._Delete_Prv(this._raiz, subClaves, 1, borrarNodo)
        }

        /*
            @method _BuscarNodosProf_Prv

            @description A partir de un nodo, busca subnodos que tengan una subclave relativa realizando una búsqueda en profundidad.

            @param {MapOrden} nodo - Nodo a partir del cual buscar.
            @param {String} claveNodo - Clave completa del nodo.
            @param {Array} claveRelativa - Listado con las subclaves relativas a buscar por debajo del nodo. Debe tener al menos una subclave con valor distinto de cadena vacía.

            @returns {Array} - Lista de pares clave-nodo encontrados según el orden obtenido por la búsqueda en profundidad.

            @complexity O(n) siendo n el número de nodos del árbol
        */
        static _BuscarNodosProf_Prv(nodo, claveNodo, claveRelativa) {
            nodosEncontrados := []

            BuscarNodosProf(nodo, claveNodo, claveRelativa) {
                if !(nodo is Util_ArbolMapOrden.Hoja) {
                    try
                        nodoEncontrado := Util_ArbolMapOrden._ObtenerNodo_Prv(nodo, claveRelativa)

                    for subClave, subNodo in nodo
                        if IsSet(nodoEncontrado) and claveRelativa[1] == subClave
                            nodosEncontrados.Push(claveNodo "." claveRelativa.ToString(1, "."), nodoEncontrado)
                        else
                            BuscarNodosProf(subNodo, claveNodo "." subClave, claveRelativa)
                }
            }

            BuscarNodosProf(nodo, claveNodo, claveRelativa)

            return nodosEncontrados
        }

        /*
            @method _BuscarNodosAnch_Prv

            @description A partir de un nodo, busca subnodos que tengan una subclave relativa realizando una búsqueda en anchura.

            @param {MapOrden} nodo - Nodo a partir del cual buscar.
            @param {String} claveNodo - Clave completa del nodo.
            @param {Array} claveRelativa - Listado con las subclaves relativas a buscar por debajo del nodo. Debe tener al menos una subclave con valor distinto de cadena vacía.

            @returns {Array} - Lista de pares clave-nodo encontrados según el orden obtenido de la búsqueda en anchura.

            @complexity O(n) siendo n el número de nodos del árbol
        */
        static _BuscarNodosAnch_Prv(nodo, claveNodo, claveRelativa) {
            nodosEncontrados := []
            pilaNodos := Util_MapOrden( , claveNodo, nodo)

            for clave, nodo in pilaNodos {
                try {
                    nodoEncontrado := Util_ArbolMapOrden._ObtenerNodo_Prv(nodo, claveRelativa)
                    nodosEncontrados.Push(Trim(claveNodo "." claveRelativa.ToString(1, "."), " ."), nodoEncontrado)
                }
                catch
                    nodoEncontrado := unset

                for subClave, subNodo in nodo
                    if !IsSet(nodoEncontrado) or claveRelativa[1] != subClave
                        pilaNodos[claveNodo "." subClave] := subNodo
            }

            return nodosEncontrados
        }

        /*
            @method Buscar

            @description Busca un valor en el árbol dado una clave.

            @param {String} claveRelativa - La subclave para buscar. Pueden ser varias subclaves concatenadas por puntos. 
            @param {String} tipoBusqueda - Tipo de búsqueda a realizar. Puede ser "prof" o "anch".
            @param {String} ordenValores - Tipo de ordenación de los valores encontrados. Puede ser "prof" o "anch".

            @returns {MapOrden} - Diccionario con los valores cuyas claves contienen la clave de búsqueda.
        */
        BuscarValores(claveRelativa, tipoBusqueda := "prof", ordenValores := "prof") {
            subClaves := Util_CadenaALista(Trim(claveRelativa, "." A_Space . A_Tab), ".")

            if subClaves.Length == 0
               throw UnsetItemError.CrearErrorAHK("Tienes que pasar alguna clave a buscar")

            switch tipoBusqueda {
                case "prof":
                    nodos := Util_ArbolMapOrden._BuscarNodosProf_Prv(this._raiz, "", subClaves)
                    
                case "anch":
                    nodos := Util_ArbolMapOrden._BuscarNodosAnch_Prv(this._raiz, "", subClaves)

                default:
                    throw Err_ValorArgError("El tipo de búsqueda no es válido", , , , , , "tipoBusqueda", 2, tipoBusqueda)                    
            }

            switch ordenValores {
                case "prof":
                    return Util_ArbolMapOrden._ObtenerValoresProf_Prv(nodos*)                    

                case "anch":
                    return Util_ArbolMapOrden._ObtenerValoresAnch_Prv(nodos*)

                default:
                    throw Err_ValorArgError("El tipo de ordenamiento no es válido", , , , , , "ordenValores", 3, ordenValores)                    
            }
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
}

