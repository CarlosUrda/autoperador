/*
    @module error.ahk

    @description Gestión de los errores

    @todo Solucionar el tener que pasar el número de línea en cada llamada a Err_Lanzar porque al asignarlo como valor por defecto toma el valor de la línea de la función Err_Lanzar, mientras que en el caso del nombre de la función sí toma como valor por defecto la función que le llama (aunque no es seguro que esto último lo vaya a hacer siempre)
*/


#Requires AutoHotkey v2.0


if (!IsSet(__ERR_H__)) {
    global __ERR_H__ := true

    /*
        @global NULL {String} - En ahk una cadena vacía se usa como null o valor indefinido.
    */
    global NULL := ""


    /*
        Tipos de errores con su código correspondiente y acciones a realizar para cada uno de ellos.

        NULL: No existe el código de error o se deconoce.
    */
    global ERR_ERRORES := Map("NULL", 0, "CORRECTO", 1, "ERR_VALOR", -1, "ERR_ARG", -2, "ERR_ARCHIVO", -3, "ERR_OBJETO", -4, "ERR_TIPO", -5, "ERR_INDICE", -6, "ERR_FUNCION", -7, "ERR_NUM_ARGS", -8)
    global ERR_ACCIONES := Map("NULL", NULL, "CONTINUAR", 1, "PARAR_FUNCION", 2, "PARAR_PROGRAMA", 3)
    global ERR_INFO_CODIGOS := Map(
        ERR_ERRORES["NULL"], Map("nombre", "NULL", "accion", ERR_ACCIONES["NULL"], "mensaje", NULL),
        ERR_ERRORES["CORRECTO"], Map("nombre", "CORRECTO", "accion", ERR_ACCIONES["CONTINUAR"], "mensaje", "Ejecución realizada correcta"),
        ERR_ERRORES["ERR_VALOR"], Map("nombre", "ERR_VALOR", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Valor erróneo"),
        ERR_ERRORES["ERR_ARG"], Map("nombre", "ERR_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Argumento erróneo"),
        ERR_ERRORES["ERR_ARCHIVO"], Map("nombre", "ERR_ARCHIVO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al gestionar un archivo"),
        ERR_ERRORES["ERR_OBJETO"], Map("nombre", "ERR_OBJETO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al crear un objeto"),
        ERR_ERRORES["ERR_TIPO"], Map("nombre", "ERR_TIPO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato erróneo"),
        ERR_ERRORES["ERR_INDICE"], Map("nombre", "ERR_INDICE", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Índice o clave errónea"),
        ERR_ERRORES["ERR_FUNCION"], Map("nombre", "ERR_FUNCION", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error en la función"),
        ERR_ERRORES["ERR_NUM_ARGS"], Map("nombre", "ERR_NUM_ARGS", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Número incorrecto de argumentos pasados")
    )

    /*
        @function Err_Lanzar
        @description Encapsular el lanzamiento de excepciones para lanzarlas con contepernido predefinido

        @param {Error} tipoExepcion - Objeto clase Error con el tipo de excepción a lanzar.
        @param {String} mensaje - Mensaje como primer argumento de la excepción lanzada
        @param {Numbre} codigoError - Código del tipo de error ocurrido de entre los valores de ERR_ERRORES.
        @param {Integer} linea - Número de línea donde ocurre el error 
        @param {String} funcion - Nombre de la función donde ocurre la excepción
        @param {String} script - Nombre del archivo del script
        @param {String} fecha - Fecha del momento del error.
    */
    _Err_Lanzar(tipoExcepcion, mensaje, codigoError?, linea := A_LineNumber, funcion := A_ThisFunc, script := A_ScriptName, fecha := A_Now) {
        if tipoExcepcion.Prototype is Error
            throw tipoExcepcion((IsSet(codigoError) ? "(" codigoError ") " : "") mensaje, funcion, FormatTime(fecha, "dd/MM/yyyy HH:mm:ss") ": " String(funcion) " (L " String(linea) ") [" String(script) "]")
        else
            throw TypeError("La excepción a lanzar no es válida como tipo Error.", ERR_ERRORES["ERR_ARG"])
    } 
    
    global Err_Lanzar := _Err_Lanzar


    /*
        @function ErrMsgBox
        @description Mostar un mensaje MsgBox con la información de una excepcion

        @param {Error} e - Objeto clase Error con la información de la excepción.
    */
    global ErrMsgBox := e => MsgBox(e.What " - " e.Message, "ERROR " e.Extra ": " ERR_INFO_CODIGOS[e.Extra]["nombre"] " - " ERR_INFO_CODIGOS[e.Extra]["mensaje"])

    

    /* Excepciones personalizadas */

    class ErrorArgumento extends Error {
        __New(mensaje, funcion?, codigo?) {
            this.Message := mensaje
            if IsSet(funcion)
                this.What := funcion
            if IsSet(codigo)
                this.Extra := codigo
        }
    }


    class ErrorFuncion extends Error {
        __New(mensaje, funcion?, codigo?) {
            this.Message := mensaje
            if IsSet(funcion)
                this.What := funcion
            if IsSet(codigo)
                this.Extra := codigo
        }
    }

    class ObjetoError extends Error {
    }
}   