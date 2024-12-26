/*
    Librería para gestionar el registro de errores y sucesos en un archivo log.
*/

#Requires AutoHotkey v2.0

NIVELES_DEBUG := Map("NINGUNO", 0, "BAJO", 1, "MEDIO", 2, "ALTO", 3)
NIVEL_GENERAL_DEBUG := "" ; Nivel general de debug a ser usado por defecto (0, 1, 2 o 3)
NOMBRE_LOG := ""          ; Nombre del archivo de log
ARCHIVO_LOG := ""         ; Archivo de log abierto
CODIGOS_ERRORES := Map("CORRECTO", 1, "ERR_VALOR", -1, "ERR_ARG", -2)
MENSAJES_ERRORES := Map(CODIGOS_ERRORES["CORRECTO"], "Todo correcto sin errores",
                        CODIGOS_ERRORES["ERR_VALOR"], "Valor erróneo",
                        CODIGOS_ERRORES[""])

/* Excepciones personalizadas */
class ArgumentoError extends Error {
    __New(mensaje, codigo) {
        this.message := mensaje
        this.what := codigo
    }
}


/*
    Inicializar todo lo necesario para comenzar laa gestión de log.

    ARGUMENTOS:
    - nombreLog: nombre del archivo de log a ser usado.
    - debug: Nivel de debug a ser usado por defecto: "ALTO", "MEDIO", "BAJO", "NINGUNO"
    - resetLog: Flag para saber si vacíar el archivo de log.
*/
InicializarDebug(nombreLog := "datos.log", debugGeneral := "ALTO", resetLog := false) {
    global ARCHIVO_LOG
    global NOMBRE_LOG
    global NIVEL_GENERAL_DEBUG

    try {
        NIVEL_GENERAL_DEBUG := NIVELES_DEBUG[debugGeneral]
    } catch UnsetItemError {
        throw ArgumentoError("Nivel debug de tipo " debugGeneral " no existente", TIPOS_ERRORES["ARGUMENTO"])
    }
    NOMBRE_LOG := nombreLog
    try {
        ARCHIVO_LOG := FileOpen(NOMBRE_LOG, resetLog ? "w" : "a")
    }
    catch OSError as e {
        throw ArgumentoError("Error al intentar abrir el archivo" NOMBRE_LOG ": " e.message, e.what, TIPOS_ERRORES["ERR_ARG"])
    }
    if (ARCHIVO_LOG == "")
        throw ArgumentoError("Error al intentar abrir el archivo" NOMBRE_LOG, "FileOpen", TIPOS_ERRORES["ERR_ARG"])

    return TIPOS_ERRORES["CORRECTO"]
}

/*
    Guarda un mensaje en un archivo Log
*/
GrabarMensajeLog(mensaje, debugMensaje, debugEntorno := "", archivoLog := "") {

}