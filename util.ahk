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
            Err_Lanzar(TypeError, "El argumento lista no es un Array", ERR_ERRORES["ERR_ARG"])
        if !(filtro is Func)
            Err_Lanzar(TypeError, "El argumento filtro no es un Func", ERR_ERRORES["ERR_ARG"])
        if filtro.MinParams > 2 || filtro.MaxParams < 2
            Err_Lanzar(TypeError, "El argumento funcion no admite dos argumentos indice y valor", ERR_ERRORES["ERR_ARG"])

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
            Err_Lanzar(ErrorFuncion, "Error en la función filtro: " e.Message, ERR_ERRORES["ERR_FUNCION"])

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
            Err_Lanzar(TypeError, "El argumento dicc no es un Map", ERR_ERRORES["ERR_ARG"])
        if !(filtro is Func)
            Err_Lanzar(TypeError, "El argumento filtro no es un Func", ERR_ERRORES["ERR_ARG"])
        if filtro.MinParams > 2 || filtro.MaxParams < 2
            Err_Lanzar(TypeError, "El argumento funcion filtro no admite dos argumentos clave y valor", ERR_ERRORES["ERR_ARG"])

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

        @throws {TypeError} - Si los tipos de los argumentos no son correctos.

        @returns {String} Devuelve un String de los valores de la lista convertidos a cadena..
    */
    _Util_EnumerableACadena(enum, mostrarClaves := false) {
        if (!enum.HasMethod("__Enum") and !(enum is Enumerator))
            Err_Lanzar(TypeError, "El argumento enum debe ser enumerable (Object<__Enum> o Enumerator)", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        cadena := ""

        try {
            if mostrarClaves {
                for clave, valor in enum {
                    indice := clave
                    cadena .= String(clave) ": " (IsSet(valor) ? String(valor) : "") "; "
                }
            }
            else {
                for i, valor in enum {
                    indice := i
                    cadena .= IsSet(valor) ? String(valor) "; " : ""
                }
            }
        }
        catch MethodError as e
            Err_Lanzar(MethodError, "El valor índice " indice " de la lista no puede convertirse a String", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        catch as e {
            try
                for valor in enum
                    cadena .= (IsSet(valor) ? String(valor) : "") "; "
            catch MethodError as e
                Err_Lanzar(MethodError, "Un valor de la lista no puede convertirse a String", ERR_ERRORES["ERR_ARG"], A_LineNumber)
        }
        
        return RTrim(cadena, "; ")
    }
    
    ; Se añade como método a Map y Array
    Array.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadena})
    Map.Prototype.DefineProp("ToString", {Call: _Util_EnumerableACadena.Bind(, true)})
    global Util_EnumerableACadena := _Util_EnumerableACadena

    
    /*
        @function Util_ObtenerClaves
        
        @description Obtener las claves o índices de un objeto enumerable <__Enum> o Enumerator cuyos valores estén definidos.

        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable de donde obtener las claves.

        @throws {TypeError} - Si el tipos del argumentos no es correcto.
        @throws {MethodError} - Si la función enumerable no admite dos argumentos clave-valor.

        @returns Devuelve un Array con las claves del objeto enumerable. Las claves pueden estar desordenadas.
    */
    _Util_ObtenerClaves(enum) {
        if (!enum.HasMethod("__Enum") and !(enum is Enumerator))
            Err_Lanzar(TypeError, "El argumento enum debe ser enumerable (Object<__Enum> o Enumerator)", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        claves := []

        try 
            for clave, valor in enum
                if IsSet(valor)
                    claves.Push(clave)
        catch as e
            Err_Lanzar(MethodError, "El enumerator obtenido del argumento enum no admite dos parámetros clave-valor", ERR_ERRORES["ERR_NUM_ARGS"], A_LineNumber)


        return claves
    }

    ; Se añade como propiedad a Map y Array
    Map.Prototype.DefineProp("Claves", {Get: _Util_ObtenerClaves})
    Array.Prototype.DefineProp("IndicesConValor", {Get: _Util_ObtenerClaves})
    global Util_ObtenerClaves := _Util_ObtenerClaves




    /*
        @function Util_ContieneValor
        @description Comprueba si un elemento está dentro de los valores de un objeto enumerable (Enumerator u objeto con método __Enum). En caso de admitir el enum dos argumentos, como Map o Array, comprueba los valores y no las claves o índices.

        @param {*} elem - valor a comprobar si está dentro de la lista.
        @param {Enumerator|Object<__Enum>} enum - Objeto enumerable donde comprobar el valor

        @returns {Boolean} - true o false si el elemento está o no dentro de la lista.

        @throws {TypeError} - Si el argumento enum no es un objeto Enumerable o __Enum

        @todo Comprobar el tipo concreto de excepción que lanza el for en los siguientes casos:
        - El argumento enum no ser enumerable.
        - En caso de ser enumerable no admitir dos argumentos.
    */
    _Util_ContieneValor(enum, elem) {
        if (!enum.HasMethod("__Enum") and !(enum is Enumerator))
            Err_Lanzar(TypeError, "El argumento enum debe ser enumerable (__Enum o Enumerator)", ERR_ERRORES["ERR_ARG"], A_LineNumber)

        try {
            for , valor in enum 
                if IsSet(valor) and (elem == valor)
                    return true
        }
        ; La excepción debería saltar solamente porque enum no admite dos argumentos.
        catch {
            ; Aquí ya no debería lanzar más excepciones porque enum es Enumerator o __Enum y obligatoriamente tiene que tener al menos un argumento. Además, en teoría, no hay excepciones en ahk por comparar tipos distintos.
            for valor in enum 
                if IsSet(valor) and (elem == valor)
                    return true
        }

        return false
    }

    ; Se añade Util_ContieneValor como método a Map y Array
    Map.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    Array.Prototype.DefineProp("ContieneValor", {Call: _Util_ContieneValor})
    global Util_ContieneValor := _Util_ContieneValor

    
}

