/*
    @module error.ahk

    @description Gestión de los errores

    @requires Recordatorio de excepciones que lanza ahk ante eventos:
        - MethodError:
            - Si objeto carece de método ToString al llamarlo en String
        
        - TypeError:
            - Si un objeto a recorrer en un bucle no es Enumerator, no tiene función __Enum o ésta no devuelve un Enumerator.
            
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
    global ERR_FUNCION_ORIGEN := Map("ACTUAL", -1, "LLAMANTE", -2)  ; Errores establecidos en la documentación oficial

    /*
        @function Err_Lanzar
        @description Encapsular el lanzamiento de excepciones para lanzarlas con contenido personalizado.

        @param {Clase Error\Error} exepcion - Clase Error con el tipo de la nueva excepción a lanzar u objeto Error con la excepción a relanzar agregando información.
        @param {String} mensaje - Mensaje como primer argumento de la excepción lanzada
        @param {Integer} codigoError - Código del tipo de error ocurrido de entre los valores de ERR_ERRORES.
        @param {Integer} linea - Número de línea donde ocurre el error 
        @param {String} funcion - Nombre de la función donde ocurre la excepción
        @param {String} script - Nombre del script desde donde se lanza el error. Por defecto se toma la ruta completa.
        @param {String} fecha - Fecha del momento del error.

        @throws {TypeError} - Si alguno de los argumentos tiene un tipo incorrecto.

        @todo A_LineNumber como valor por defecto del argumento línea no guarda el número de línea de la llamada a esta función, sino el número de línea de la cabecera _Err_Lanzar. Para el nombre de la función y el script sí asigna el de los llamantes.
    */
    _Err_Lanzar(excepcion, mensaje, codigoError := "", linea := A_LineNumber, funcion := A_ThisFunc, script := A_ScriptFullPath, fecha := FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:")) {
        try {
            nombreArchivo := RegExReplace(String(script), ".*[\\/]", "")
            codigoError := String(codigoError)
            linea := String(linea)
            funcion := String(funcion)
            fecha := String(fecha)
        }
        catch  {
            excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") Los argumentos con información sobre el error deben ser String (o convertible a String).", ERR_FUNCION_ORIGEN["ACTUAL"], FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
        }
        else if excepcion is Class
            if !(excepcion.Prototype is Error)
                excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") El tipo de excepción a lanzar no es clase Error.", ERR_FUNCION_ORIGEN["ACTUAL"], FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
            else
                excepcion := excepcion("(" codigoError ") " mensaje, ERR_FUNCION_ORIGEN["LLAMANTE"], fecha ":" funcion " (L " linea ") [" nombreArchivo "]")
        else
            if !(excepcion is Error)
                excepcion := TypeError("(" ERR_ERRORES["ERR_ARG"] ") El objeto excepción a relanzar no es tipo Error.", -1, FormatTime(A_Now, "dd/MM/yyyy HH:mm:ss:") A_ThisFunc " (L " A_LineNumber ") [" RegExReplace(A_LineFile, ".*[\\/]", "") "]")
            else {
                excepcion.Message .= " (" codigoError ") " mensaje
                excepcion.Extra .= "`r`n" fecha ":" funcion " (L " linea ") [" nombreArchivo "]"
            }

        throw excepcion
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