#Requires AutoHotkey v2.0

if (!IsSet(__ERR_H__)) {
    global __ERR_H__ := true

    /*
     Tipos de errores con su código correspondiente y acciones a realizar para cada uno de ellos.
    */
    ERR_ERRORES := Map("CORRECTO", 1, "ERR_VALOR", -1, "ERR_ARG", -2)
    ERR_ACCIONES := Map("CONTINUAR", 0, "PARAR_FUNCION", 1, "PARAR_PROGRAMA", 2)
    ERR_INFO_CODIGOS := Map(
        ERR_ERRORES["CORRECTO"], Map("nombre", "CORRECTO", "accion", ERR_ACCIONES["CONTINUAR"], "mensaje", "Ejecución realizada correcta"),
        ERR_ERRORES["ERR_VALOR"], Map("nombre", "ERR_VALOR", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Valor erróneo"),
        ERR_ERRORES["ERR_ARG"], Map("nombre", "ERR_ARG", "accion", ERR_ACCIONES["PARAR_FUNCION"], "mensaje", "Argumento erróneo")
    )


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
}   