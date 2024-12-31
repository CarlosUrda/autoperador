#Requires AutoHotkey v2.0

#Include "util.ahk"

if (!IsSet(__ERR_H__)) {
    global __ERR_H__ := true

    /*
     Tipos de errores con su código correspondiente y acciones a realizar para cada uno de ellos.
    */
    ERR_ERRORES := Map("NINGUNO", NULL, "CORRECTO", 1, "ERR_VALOR", -1, "ERR_ARG", -2, "ERR_ARCHIVO", -3, "ERR_OBJETO", -4, "ERR_TIPO", -5)
    ERR_ACCIONES := Map("NINGUNO", NULL, "CONTINUAR", 1, "PARAR_FUNCION", 2, "PARAR_PROGRAMA", 3)
    ERR_INFO_CODIGOS := Map(
        ERR_ERRORES["CORRECTO"], Map("nombre", "CORRECTO", "accion", ERR_ACCIONES["CONTINUAR"], "mensaje", "Ejecución realizada correcta"),
        ERR_ERRORES["ERR_VALOR"], Map("nombre", "ERR_VALOR", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Valor erróneo"),
        ERR_ERRORES["ERR_ARG"], Map("nombre", "ERR_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Argumento erróneo")
        ERR_ERRORES["ERR_ARCHIVO"], Map("nombre", "ERR_ARCHIVO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al gestionar un archivo")
        ERR_ERRORES["ERR_OBJETO"], Map("nombre", "ERR_OBJETO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Error al crear un objeto")
        ERR_ERRORES["ERR_TIPO"], Map("nombre", "ERR_TIPO", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Tipo de dato erróneo")
    )

    /*
        @function Lanzar
        @description Encapsular el lanzamiento de excepciones para lanzarlas con contenido predefinido

        @param tipoExepcion {Error} - Objeto clase Error con el tipo de excepción a lanzar.
        @param mensaje {String} - Mensaje como primer argumento de la excepción lanzada
        @param codigoError {Numbre} - Código del tipo de error ocurrido de entre los valores de ERR_ERRORES.
        @param fecha {String} - Fecha del momento del error.
        @param funcion {String} - Nombre de la función donde ocurre la excepción
        @param linea {Number} - Número de línea donde ocurre el error 
        @param script {String} - Nombre del archivo del script
    */
    _ErrLanzar(tipoExcepcion, mensaje, codigoError := ERR_ERRORES["NINGUNO"], fecha := A_Now, funcion := A_ThisFunc, linea := A_LineNumber, script := A_ScriptName) {
        throw tipoExcepcion(mensaje, fecha ": " funcion " (L " linea ") [" script "]", codigoError)
    } 
    
    global ErrLanzar := _ErrLanzar

    /*
        @function ErrMsgBox
        @description Mostar un mensaje MsgBox con la información de una excepcion

        @param e {Error} - Objeto clase Error con la información de la excepción.
    */
    global ErrMsgBox := e => MsgBox(e.What " - " e.Message, "ERROR " e.Extra ": " ERR_INFO_CODIGOS[e.Extra]["nombre"] " - " ERR_INFO_CODIGOS[e.Extra]["mensaje"])

    
    /* Excepciones personalizadas */

    class ErrorArgumento extends Error {
        __New(mensaje, funcion := "", codigo := "") {
            this.Message := mensaje
            if (funcion != "")
                this.What := funcion
            if (codigo != "")
                this.Extra := codigo
        }
    }


    class ObjetoError extends Error {
    }
}   