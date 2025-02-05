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

/* En lugar del include se llamaría (dentro de Util??) a la función del módulo para ejecutarla, y solo se ejecutaría en teoría una vez si está en la librería */
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
            throw Err_Error.ExtenderErr(TypeError("El tipo del valor no es una Clase"))
        if clase.Prototype != valor.Base
            throw Err_Error.ExtenderErr(TypeError("El prototipo de la clase tipo no coincide con la base prototipo del valor. Es decir, el objeto no se creó a partir del prototipo del tipo clase."))

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
        numElementos := Err_VerificarArg_Prv(numElementos, "numElementos", 1, IsInteger, (n) => n >= 0, Integer)

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
        Err_VerificarArg_Prv(descendiente, "descendiente", 2, Es_Clase(o) => o is Class)
        return descendiente.HasBase(clase)
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
            throw !Err_ErroresPersonalizadosActivo ? Error(infoError.mensaje) : Err_ValorArgError(infoError.mensaje, , , , , , infoError.nombreArg, infoError.numArg, infoError.valorArg)

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
                    throw !Err_ErroresPersonalizadosActivo ? Error(infoError.mensaje) : Err_ValorArgError(infoError.mensaje, , , , , , infoError.nombreArg, infoError.numArg, infoError.valorArg)
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
        - Set guardará el valor, aplicando previamente las funciones de verificación.

        @param {String} prop - Nombre de la propiedad.
        @param {Func} funciones - Funciones de verificación usadas en el Set que serán llamadas en el orden en que son pasadas. A cada función se le pasa como único argumento el valor recibido. Cada función tiene que tener obligatoriamente un campo TipoError con un tipo Err_ArgError que será lanzado en caso de que el valor no pase la validación de la función. Puede tener una propiedad opcional Mensaje con el texto que será usado al lanzar el mensaje. 
        Si el tipo de error asociado es Err_FuncArgError la función se usará como conversión del valor recibido, y lo que devuelva se usará como nuevo valor obtenido. El resto de funciones devolverán true o false si no pasan la validación. Todas las funciones pueden devolver excepciones, en cuyo caso se toma como que no ha pasasdo el filtro de la función.

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
        @param {Func} funciones - Funciones de verificación usadas en el Set que serán llamadas en el orden en que son pasadas. A cada función se le pasa como único argumento el valor recibido. Cada función tiene que tener obligatoriamente un campo TipoError con un tipo Err_ArgError que será lanzado en caso de que el valor no pase la validación de la función. Puede tener una propiedad opcional Mensaje con el texto que será usado al lanzar el mensaje. 
        Si el tipo de error asociado es Err_FuncArgError la función se usará como conversión del valor recibido, y lo que devuelva se usará como nuevo valor obtenido. El resto de funciones devolverán true o false si no pasan la validación. Todas las funciones pueden devolver excepciones, en cuyo caso se toma como que no ha pasasdo el filtro de la función.
        
        @throws {Error/Err_TipoArgError} - Si los argumentos no son de tipo correcto.

        @returns {Object} - Devuelve el objeto al cual se le ha definido la propiedad.
    */
    _Util_DefinePropEstandarM(obj, prop, funciones*) {
        prop := Err_VerificarArg_Prv(prop, "prop", 2, , , String)

        FuncOK(f) => _Err_AdmiteNumArgs(f, 1) and f.HasProp("TipoError") and f.TipoError.HasBase(Err_ArgError)
        FuncOK.Mensaje := "No es una función, no admite un argumento o no tiene propiedad TipoError con un tipo Err_ArgError"
        FuncOK.TipoError := Err_TipoArgError

        for funcion in funciones {
            Err_VerificarArg_Prv(funcion, , 2 + A_Index, FuncOK)

            /* Aquí se verificaría la función para comprobar que no es maliciosa */
        }

        return  _Util_DefinePropEstandar_Prv(obj, prop, funciones*)
    }

    _Util_DefinePropEstandar(obj, prop, funciones*) {
        ObjOK(o) => o is Object
        ObjOK.Mensaje := "Debes pasar un Object para definir la nueva propiedad"
        ObjOK.TipoError := Err_TipoArgError
        Err_VerificarArg_Prv(obj, "obj", 1, ObjOK)

        return obj.DefinePropEstandar(prop, funciones*)
    }

    ; Se añade como método a Object
    Object.Prototype.DefineProp("DefinePropEstandar", {Call: _Util_DefinePropEstandarM})
    global Util_DefinePropEstandar := _Util_DefinePropEstandar

        
    /*
        @function Util_FiltrarArgs

        @description Envolver a una función en otra que será la que reciba los argumentos para ser filtrados; aquellos que pasen el filtro se pasarán en orden a la primera función. 

        @param {Func} funcion - Función a ser envuelta y que recibirá en orden los argumentos que pasan el filtro.
        @param {Func} filtro - Función que recibirá como argumentos la posición y el valor de cada argumento de la función envoltorio. Si devuelve true, el argumento se pasará a la función; si devuelve false, se desecha. Tener en cuenta que el valor pasado de algún argumento puede no estar definido.

        @throws {TypeError} - Si los tipos de los argumentos son erróneos.
        @throws {ErrorNumArgumentos} - Si la función no admite el número de argumentos pasados tras el filtro..

        @returns {Func} - Función envoltorio que será la que reciba los argumentos a ser filtrados.
    */
    _Util_FiltrarArgsM(funcion, filtro) {
        Ff(f) => Err_AdmiteNumArgs(f, 2)
        Ff.Mensaje := "No es una función o no admite 2 argumentos pos, valor"
        Err_VerificarArg_Prv(filtro, "filtro", 2, Ff)

        _Funcion(args*) {            
            _args := args
            for arg in args
                try
                    if !filtro(A_index, arg?)
                        _args.RemoveAt(A_Index)
                catch as e
                    throw Err_FuncError("Filtro no ejecutado correctamente", , , , , e, filtro)

            try 
                return funcion(_args*)
            catch as e
                throw Err_NumArgsError("Número de argumentos erróneos", , , , , e, funcion, _args.Length)
        }

        return _Funcion
    }

    _Util_FiltrarArgs(funcion, filtro) {
        Err_VerificarArg_Prv(funcion, "funcion", 1, EsFunc(f) => f is Func)

        return _Util_FiltrarArgsM(funcion, filtro)
    }

    ; Se añade como método a Map, Array y Enumerator
    Func.Prototype.DefineProp("FiltrarArgs", {Call: _Util_FiltrarArgsM})
    global Util_FiltrarArgs := _Util_FiltrarArgs



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
        Ff(f) => Err_AdmiteNumArgs(f, 2)
        Ff.Mensaje := "No es una función o no admite 2 argumentos índice, valor"
        Err_VerificarArg_Prv(filtro, "filtro", 2, Ff)

        enum := Err_VerificarEnumerable(lista, 2)
        borrables := []
        for i, valor in enum
            try 
                if !filtro(i, valor?)
                    borrables.Push(i)
            catch as e
                throw Err_FuncError("Filtro no ejecutado correctamente", , , , , e, filtro)

        i := -1
        Loop borrables.Length
            lista.RemoveAt(borrables[i--])

    }
    
    ; Se añade como método a Array
    Array.Prototype.DefineProp("SubLista", {Call: _Util_SubListaM})



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
        Ff(f) => Err_AdmiteNumArgs(f, 2)
        Ff.Mensaje := "No es una función o no admite 2 argumentos clave, valor"
        Err_VerificarArg_Prv(filtro, "filtro", 2, Ff)
        enum := Err_VerificarEnumerable(dicc, 2)

        borrables := []
        for clave, valor in enum
            try 
                if !filtro(clave, valor)
                    borrables.Push(clave)
            catch as e
                throw Err_FuncError("Filtro no ejecutado correctamente", , , , , e, filtro)

        for clave in borrables
            dicc.Delete(clave)
    }
    
    ; Se añade como método a Map
    Map.Prototype.DefineProp("SubDicc", {Call: _Util_SubDiccM})

        
    /*
        @function Util_SubEnumerable

        @description Obtener un array con los elementos de un enumerable que pasan un filtro. Si el enumerable admite varios argumentos, cada elemento dentro de la lista resultante será un array con los valores de cada elemento del enumerable.

        @param {Object<__Enum>|Enumerator} enum - Lista de la cual obtener la sublista
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable.
        @param {Func} filtro - Función condición que recibirá como argumentos todos los valores de cada elemento del enumerable. Devolverá true o false si cumple o no la condición. tener en cuenta que puede recibir valores no definidos.

        @throws {Err_TipoArgError} - Si los tipos de los argumentos no son correctos.
        @throws {Err_FuncError} - Si filtro genera algún error al ser ejecutado.

        @return {Array} - Lista de elementos del enumerable que han pasado un filtro. Si cada elemento está formado por varios valores (tantos como numArgs), devuelve un array de arrays.
    */
    Util_SubEnumerable(enum, numArgs, filtro) {
        Ff(f) => Err_AdmiteNumArgs(f, numArgs)
        Ff.Mensaje := "No es una función o no admite numArgs"
        Err_VerificarArg_Prv(filtro, "filtro", 2, Ff)

        enum := Err_VerificarEnumerable(enum, numArgs)

        resultado := Array()
        valoresRef := Array()
        Loop numArgs
            valoresRef.Push(Util_CrearVarRef())

        try
            while enum(valoresRef*) {
                valores := Array()
                for valorRef in valoresRef
                    valores.Push(%valorRef%?)

                try
                    if filtro(valores*)
                        resultado.Push(Array(valores*))
                catch as e
                    throw Err_FuncError("Filtro no ejecutado correctamente", , , , , e, filtro)
            }
        catch as e 
            throw Err_FuncError("Fallo al recorrer el enumerable", , , , , e, enum)

        return resultado
    }
    

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
        enum := Err_VerificarEnumerable(e, numArgs)
        S(s) => String(s)
        S.Mensaje := "Los separadores deben de ser una cadena",
        sepGrupo := Err_VerificarArg_Prv(sepGrupo, "sepGrupo", 3, , , S)
        sepPartes := Err_VerificarArg_Prv(sepPartes, "sepPartes", 4, , , S)

        valoresRef := Array()
        Loop numArgs
            valoresRef.Push(Util_CrearVarRef())

        cadena := ""
        try
            while enum(valoresRef*) {
                for valorRef in valoresRef
                    cadena .= (%valorRef% ?? "") sepPartes " "

                cadena := RTrim(cadena, sepPartes " ") sepGrupo " "
            }
        catch as e 
            throw Err_FuncError("Fallo al recorrer el numerable", , , , , e, enum)

        return RTrim(cadena, sepGrupo " ")
    }
  
    ; Se añade como método a Map, Array y Enumerator
    Enumerator.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadenaM})
    Array.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadenaM})
    Map.Prototype.DefineProp("ToString", {Call: (m, n?, sg?, sp?) => _Util_EnumerableACadenaM(m, n ?? 2, sg?, sp?)})
    global Util_EnumerableACadena := _Util_EnumerableACadenaM
  

    /*
        @function Util_ObtenerClaves
        
        @description Obtener la lista formada por el primer valor de cada uno de los elementos de un enumerable. En caso de Array se obtiene lista de índices, y en caso de Map se obtiene lista de claves. Si se pasan valores, los primeros valores (claves/índices) obtenidos son los de aquellos elementos cuyo resto de valores coincide con los valores pasados en orden; en cuanto se pasan valores, solo pasan el filtro aquellos elementos que cumplen esta condición. Si no se pasan valores, se obtienen los primeros valores de aquellos elementos que tienen entre el resto de valores algún valor definido.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable de donde obtener los primeros valores.
        @param {Integer} numArgs - Número de argumentos que admitirá el enumerable por cada elemento.
        @param {Object} valores - Valores a ser comparados con los de cada elemento del enumerable. El número de valores, si se pasan, debe ser igual a numArgs-1.

        @throws {TypeError} - Si el tipos del argumentos no es correcto.
        @throws {¿Error?} - Si la función enumerable no admite dos argumentos clave-valor.

        @returns {Array} - Array de claves obtenidas

        @todo Mejorar para admiitir que la clave esté formada por varios valores.
    */
    _Util_ObtenerClaves(enum, numArgs, posClave, pos_valor*) {
        enum := Err_VerificarEnumerable(e, numArgs)
        if numArgs == 0 ; Si el enum admite 0 args, no hace falta hacer más. No hay error.
            return []

        valoresRef := Array()
        Loop numArgs-1
            valoresRef.Push(Util_CrearVarRef())
        clave := NULL
        claves := Array()

        if IsSet(valores) {
            Err_VerificarArg_Prv(valores, "valores", 3, FuncArg((v) => v.Length <= numArgs-1, FuncArg.TIPO_FUNC["Validar"], "El número de valores debe ser igual al numArgs-1 del enumerable"))
            valores.Length := numArgs-1

            try
                while enum(&clave, valoresRef*) {
                    claveOK := true
                    for valorRef in valoresRef
                        if !(!IsSet(%valorRef%) and !IsSet(valores[A_Index]) or (IsSet(%valorRef%) and IsSet(valores[A_Index]) and valores[A_Index] == %valorRef%)) {
                            claveOK := false
                            break
                        }
                    
                    if claveOK
                        claves.Push(clave)
                }
            catch as e 
                throw Err_FuncError("Fallo al recorrer el numerable", , , , , e, enum)    
        }
        else {
            try                 
                while enum(&clave, valoresRef*) {
                    claveOK := false
                    for valorRef in valoresRef
                        if IsSet(%valorRef%) {
                            claveOK := true
                            break
                        }
                    
                    if claveOK
                        claves.Push(clave)
                }
            catch as e 
                throw Err_FuncError("Fallo al recorrer el numerable", , , , , e, enum)    
        }

        return claves
    }




    _Util_ContieneValor(enum, numArgs, pos_valor*) {
        enum := Err_VerificarEnumerable(enum, numArgs)
           
        if Ceil(pos_valor.Length / 2) != numArgs {
            m := "El número de valores debe ser igual a numArgs del enumerable"
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

                if !((!IsSet(%valoresRef[posArg]%) and !pos_valor.Has(++A_Index)) or (IsSet(%valoresRef[posArg]%) and pos_valor.Has(A_Index) and %valoresRef[posArg]% == pos_valor[A_Index])) {
                    coincide := false
                    break
                }
            }

            if coincide                    
                return true
        }

        return false
    }






    ; Se añade como método a Map y Array
    Map.Prototype.DefineProp("Claves", {Call: (m, v*) => _Util_ObtenerClaves(m, 2, v*)})
    Array.Prototype.DefineProp("IndicesConValor", {Call: (a, v*) => _Util_ObtenerClaves(a, 2, v*)})
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
        Vi(i) => inicio >= 1 and fin >= inicio
        Vi.Mensaje := "Los indices tienen que cumplir 1 <= inicio <= fin"
        Vi.TipoError := Err_ValorArgError
        Integer.TipoError := Err_FuncArgError
        inicio := Err_VerificarArg_Prv(inicio, "inicio", 4, Integer)
        fin := Err_VerificarArg_Prv(fin, "fin", 5, Integer, Vi)

        if lista.Length == 0 or (fin - inicio) <= 0
            return

        medio := (fin-inicio) // 2 + 1

        lista.Ordenar(lista, comparar, inicio, medio)
        lista.Ordenar(lista, comparar, medio+1, fin)

        _Util_Combinar_Prv(lista, comparar, inicio, medio, fin)
    }

    ; Se añade como método a Map y Array
    Array.Prototype.DefineProp("Ordenar", {Call: _Util_OrdenarListaM})
    global Util_OrdenarLista := _Util_OrdenarListaM


    /*
        @function Util_EliminarDuplicadosMA

        @decripción Eliminar los valores duplicados de una lista. La lista se modifica quedando con los valores no duplicados. 

        @param {Array} lista - Array a eliminar sus duplicados
        @param {Boolean} final - Si true se eliminan los elementos duplicados empezando por el final quedando como único no duplicado el primero; si false se eliminan los elementos duplicados desde el principio quedando como único no duplicado el último.
    */
    _Util_EliminarDuplicadosMA(lista, final := true) {        
        valoresDup := Map()
        indicesDup := Array()

        indice := inc := final ? 1 : -1
        Loop lista.Length {
            if !valoresDup.Has(lista[indice])
                valoresDup[lista[indice]] := true
            else
                indicesDup.Push(indice)

            indice += inc
        }

        indice := inc := final ? -1 : 1
        Loop indicesDup.Length {
            lista.RemoveAt(indicesDup[indice])
            indice += inc
        }
    }

    ; Se añade como método a Array
    Array.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosMA})


    /*
        @function Util_EliminarDuplicadosMM

        @decripción Eliminar los valores duplicados de un diccionario. El diccionario se modifica quedando con los valores no duplicados. 

        @param {Map} dicc - Map a eliminar sus duplicados
    */
    _Util_EliminarDuplicadosMM(dicc) {       
        valoresDup := Map()
        clavesDup := Array()

        for clave, valor in dicc {
            if !valoresDup.Has(dicc[clave])
                valoresDup[dicc[clave]] := true
            else
                clavesDup.Push(clave)
        }

        for clave in clavesDup
            dicc.Delete(clave)
    }

    ; Se añade como método a Map
    Map.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicadosMM})


    /*
        @function _Util_EliminarDuplicados

        @decripción Eliminar los valores duplicados obtenidos de un  un diccionario. El diccionario se modifica quedando con los valores no duplicados. 

        @param {Map} dicc - Map a eliminar sus duplicados
    */
    _Util_EliminarDuplicados_Prv(enum, numArgs := 2) {
        valoresDup := Map()
        clavesDup := Array()

        for clave, valor in dicc {
            if !valoresDup.Has(dicc[clave])
                valoresDup[dicc[clave]] := true
            else
                clavesDup.Push(clave)
        }

        for clave in clavesDup
            dicc.Delete(clave)
    }

    _Util_EliminarDuplicados(enum, numArgs := 2) => _Util_EliminarDuplicados_Prv(Err_VerificarEnumerable(enum, numArgs), numArgs)

    ; Se añade como método a Map
    Enumerator.Prototype.DefineProp("EliminarDuplicados", {Call: _Util_EliminarDuplicados_Prv})


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
            @param {Func} comparar - Función de comparación a ser usada por MapOrden. Tiene que admitir dos argumentos y devolver <0, 0 o >0 como resultado de la comparación.

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
            @param {Func} comparar - Si no hay función de comparación, el orden del diccionario queda asignado el orden de insercción de los valores.
        */
        __New(comparar?, args*) {
            try
                super._New(args*)
            catch as e
                throw Err_ValorArgError("No se han podido crear el diccionario", , , , , e, "args", 1, args)

            args.SubLista((i, v) => Mod(i, 2) == 1 and IsSet(v) and )
            this._claves := args

            if IsSet(comparar) {
                this.Comparar := comparar
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
        @param {Integer, Object} pos_valor - Serie de pares de argumentos (posición, valor). Se indica para cada posición de los argumentos del enumerable el valor que tiene que contener.

        @returns {Boolean} - true o false si el elemento está o no dentro de la lista.

        @throws {Err_TipoArgError} - Si el tipo de algún argumento es incorrecto.
        @throws {Err_ValorArgError} - Si el valor de algún argumento no es válido.
    */
    _Util_ContieneValor(enum, numArgs, pos_valor*) {
        enum := Err_VerificarEnumerable(enum, numArgs)
           
        if Ceil(pos_valor.Length / 2) != numArgs {
            m := "El número de valores debe ser igual a numArgs del enumerable"
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

                if !((!IsSet(%valoresRef[posArg]%) and !pos_valor.Has(++A_Index)) or (IsSet(%valoresRef[posArg]%) and pos_valor.Has(A_Index) and %valoresRef[posArg]% == pos_valor[A_Index])) {
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

