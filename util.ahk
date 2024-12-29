/*
    Librería con utilidades.
*/

#Requires AutoHotkey v2.0

#Include "error.ahk"

if (!IsSet(__UTIL_H__)) {
    global __UTIL_H__ := true

    /*
        @function Util_en
        @description Comprueba si un elemento está dentro de una estructura enumerable (tipo Enumerator u objeto que  contiene método __Enum). En caso de admitir dos argumentos, como Map o Array, comprueba los valores y no las claves o índices.

        @param {*} elem - valor a comprobar si está dentro de la lista.
        @param {Object<__Enum>} enum - Estructura enumerable (__Enum) donde comprobar el valor

        @returns {Boolean} - true o false si el elemento está o no dentro de la lista.

        @throws {ErrorArgumento} - Si el segundo argumento no es una estructura numerable __Enum

        @todo Comprobar el tipo concreto de excepción que lanza el for en los siguientes casos:
        - El argumento enum no ser enumerable.
        - En caso de ser enumerable no admitir dos argumentos.
    */
    _Util_en(elem, enum) {
        if (not enum.HasMethod("__Enum") and Type(enum) != "Enumerator")
            throw TypeError("El segundo argumento debe ser enumerable (__Enum o Enumerator)", A_ThisFunc "L" A_LineNumber ") " "[" A_ScriptName "]", ERROR_CODIGOS["ERR_ARG"])

        try {
            for , valor in enum 
                if (elem == valor)
                    return true
        }
        ; La excepción debería saltar solamente porque enum no admite dos argumentos.
        catch {
            ; Aquí ya no debería lanzar más excepciones porque enum es Enumerator o __Enum y obligatoriamente tiene que tener al menos un argumento. Además, en teoría, no hay excepciones en ahk por comparar tipos distintos.
            for valor in enum 
                if (elem == valor)
                    return true
        }

        return false
    }

    global Util_en := _Util_en

}

