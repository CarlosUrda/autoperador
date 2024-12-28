#Requires AutoHotkey v2.0

if (!IsSet(__ERROR_H__)) {
    global __ERROR_H__ := true

    /* Excepciones personalizadas */
    class ArgumentoError extends Error {
        __New(mensaje, funcion := "", codigo := "") {
            this.Message := mensaje
            if (funcion != "")
                this.What := funcion
            if (codigo != "")
                this.Extra := codigo
        }
    }
}