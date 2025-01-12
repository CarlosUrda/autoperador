/*
    Librería con utilidades.

    @todo Incluir los mensajes de log en esta librería.
*/

#Requires AutoHotkey v2.0

#Include "error.ahk"


if (!IsSet(__UTIL_H__)) {
    global __UTIL_H__ := true


    /*
        @function Util_SubLista

        @description Obtener una sublista formada con los elementos de una lista que cumplan la condición de la funcion filtro.

        @param {Array} lista - Lista de la cual obtener la sublista
        @param {Func} filtro(indice, valor) - Función condición que se aplicará a cada par índice-valor de la lista. Recibirá como argumentos el índice y el valor y devolverá true o false si cumple o no la condición.
        @param {Boolean} modificar - Si true modifica la lista pasada como argumento dejándola como la sublista. Si false, deja la lista original intacta.

        @returns {Array} - Sublista con los valores obtenidos. Si modificar es true devuelve la misma lista pasada por argumento modificada. Si es false, devuelve una nueva lista.

        @throws {TypeError} - Si los tipos de los argumentos no son correctos.
        @throws {ErrorFuncion} - Si ocurre algún error con la función filtro.
    */
    Util_SubLista(lista, filtro, modificar := false) {
        if !(lista is Array)
            Err_Lanzar(TypeError, "El argumento lista no es un Array", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        if !(filtro is Func)
            Err_Lanzar(TypeError, "El argumento filtro no es un Func", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        if filtro.MinParams > 2 || filtro.MaxParams < 2
            Err_Lanzar(TypeError, "El argumento funcion no admite dos argumentos indice y valor", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        try {
            if modificar {
                for i, valor in lista.Clone() 
                    if !filtro(i, valor) 
                        lista.RemoveAt(i)

                return lista
            }
            else {
                _lista := Array()

                for i, valor in lista 
                    if filtro(i, valor)
                        _lista.Push(valor)

                return _lista
            }
        }
        catch as e
            Err_Lanzar(ErrorFuncion, "Error en la función filtro: " e.Message, ERR_ERRORES["ERR_FUNCION"], A_LineNumber)

    }



    /*
        @function Util_SubMap

        @description Obtener un subdiccionario formado con los pares clave-valor de un diccionario que cumplan la condición de la funcion filtro.

        @param {Map} dicc - Diccionario de la cual obtener el submap
        @param {Func} filtro(clave, valor) - Función filtro que se aplicará a cada par clave-valor de la lista. Recibirá como argumentos la clave y el valor y devolverá true o false si cumple o no la condición.
        @param {Boolean} modificar - Si true modifica el map pasado como argumento dejándolo como el submap. Si false, deja el diccionaro original intacto.

        @returns {Map} - Submap con los valores obtenidos. Si modificar es true devuelve el mismo map pasado por argumento modificado. Si es false, devuelve un nuevo map.

        @throws {TypeError} - Si los tipos de los argumentos no son correctos.
        @throws {ErrorFuncion} - Si ocurre algún error con la función filtro.
    */
    Util_SubMap(dicc, filtro, modificar := false) {
        if !(dicc is Map)
            Err_Lanzar(TypeError, "El argumento dicc no es un Map", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        if !(filtro is Func)
            Err_Lanzar(TypeError, "El argumento filtro no es un Func", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        if filtro.MinParams > 2 || filtro.MaxParams < 2
            Err_Lanzar(TypeError, "El argumento funcion filtro no admite dos argumentos clave y valor", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        try {
            if modificar {
                for clave, valor in dicc.Clone() 
                    if !filtro(clave, valor) 
                        dicc.Delete(clave)

                return dicc
            }
            else {
                _dicc := Map()

                for clave, valor in dicc 
                    if filtro(clave, valor)
                        _dicc[clave] := valor

                return _dicc
            }
        }
        catch as e
            Err_Lanzar(ErrorFuncion, "Error en la función filtro: " e.Message, ERR_ERRORES["ERR_FUNCION"], A_LineNumber)
    }        


    /*
        @function Util_EnumerableACadena
        
        @description Obtener una cadena a partir de los valores de objeto enumerable <__Enum> o Enumerator.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable cuyos valores se van a convertir a una cadena.
        @param {Boolean} mostrarClaves - Si se desean obtener las claves en la cadena 
        @param {String} separador - cadena para separar los valores.
        @param {String} separadorClave - cadena para separar las claves de los valores.

        @throws {TypeError} - Si los tipos de los argumentos no son correctos.

        @returns {String} Devuelve un String de los valores de la lista convertidos a cadena..
    */
    _Util_EnumerableACadena(enum, mostrarClaves := false, separador := ";", separadorClave := ":") {
        try
            separador := String(separador)
        catch as e
            Err_Lanzar(e, "El separador no puede convertirse a String", ERR_ERRORES["ERR_ARG"], A_LineNumber)

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
    Map.Prototype.DefineProp("ToString", {Call: (e, m := true, s?, sc?) =>_Util_EnumerableACadena(e, m, s?, sc?)})
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

            @param {Integer|String|Object reference} clave - clave de acceso a una entrada de Map.
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

        @param {*} elem - valor a comprobar si está dentro de la lista.
        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable donde comprobar el valor

        @returns {Boolean} - true o false si el elemento está o no dentro de la lista.

        @throws {TypeError} - Si el argumento enum no es un objeto Enumerable o __Enum

        @todo Comprobar el tipo concreto de excepción que lanza el for en los siguientes casos:
        - El argumento enum no ser enumerable.
        - En caso de ser enumerable no admitir dos argumentos.
    */
    _Util_ContieneValor(enum, elem) {
        try {
            for , valor in enum 
                if IsSet(valor) and (elem == valor)
                    return true
        }
        ; TypeError se captura si enum no es Enumerator, no tiene función __Enum o ésta no devuelve Enumerator
        catch TypeError as e {
            Err_Lanzar(e, "El argumento enum debe ser Enumerator o tener función __Enum y que devuelva Enumerator", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        }
        ; Aquí solo debe entrar porque enum no admite dos argumentos.
        catch {
            ; Este bucle ya no debe lanzar más excepciones porque, en teoría, no hay excepciones en ahk por comparar tipos distintos.
            for valor in enum 
                if IsSet(valor) and (elem == valor)
                    return true
        }

        return false
    }

    ; Se añade Util_ContieneValor como método a Map y Array
    Enumerator.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Map.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Array.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    global Util_ContieneValor := _Util_ContieneValor

    
    /*
    - Que MapOrdenado se pueda ordenar por claves o por valores. Solo hay que comparar los valores en lugar de las claves al ordenar.
    - Hacer ToString en las nuevas clases.
    - Cambiar las llamadas a Err_Lanzar cuando se capture una expeción para relanzarla.
    */

}

