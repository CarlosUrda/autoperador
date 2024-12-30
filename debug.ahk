/*
    Librería para gestionar el registro de errores y sucesos en un archivo log.
*/

#Requires AutoHotkey v2.0

#Include "util.ahk"


NOMBRE_LOG          := "" ; Nombre del archivo de log
ARCHIVO_LOG         := "" ; Archivo de log abierto


/*
    Clase para encapsular un archivo de Log.

    @property {Number} NivelMinimo - Obtener o cambiar el valor del nivel mínimo de los mensajes.

    @method Vaciar - Vaciar el contenido del archivo log.

    @static
        - {Map} NIVELES - Tipos de niveles de los mensajes a ser mostrados en el log.
*/
class Log {
    static NIVELES := Map("INFORMACION", 0, "AVISO", 1, "MEDIO", 2, "CRITICO", 3)

    /*
        @method Constructor

        @param {String} nombreArchivo - Nombre del archivo de log a abrir o crear.
        @param {String} modo - Modo de inicio del archivo ("w" para crear el archivo vacío; "a" para abrir desde el final del archivo)
        @param {Number} nivelMinimo - Umbral mínimo que deberán tener los mensajes para poder ser registrados en el log

        @throws {ValueError} - Si los argumentos nivelMinimo o modo no tienen valores correctos
        @throws {OSError} - Si hay problemas al abrir el archivo o moverse dentro al inicializarlo.
    */
    __New(nombreArchivo, modo := "w", nivelMinimo := this.NIVELES["INFORMACION"]) {
        if not Util_enValores(nivelMinimo, this.NIVELES)
            ErrLanzar(ValueError, "Primer argumento debe ser valor de nivel contenido en Log.NIVELES", ERR_ERRORES["ERR_ARG"])

        if (modo != "w" and modo != "a")
            ErrLanzar(ValueError, "El tercer argumento debe ser un modo válido ('w' o 'a')", ERR_ERRORES["ERR_ARG"])

        this._nivelMinimo := nivelMinimo

        try 
            this._archivo := FileOpen(nombreArchivo, modo)
        catch as e
            ErrLanzar(OSError, "El archivo " nombreArchivo " no puede abrirse: " e.message, ERR_ERRORES["ERR_ARCHIVO"])
        
        this._nombreArchivo = nombreArchivo

    }

    
    /*
        @method Destructor de Log
    */
    __Delete() {
        this._archivo.Close()
    }


    /*
        @property NivelMinimo
        
        @method get - obtiene el valor de la propiedad
        @method set - cambia el valor de la propiedad. Debe ser un valor de nivel válido en Log.NIVELES

        @throws {ValueError} - Si al fijar el nivelMinimo no es un valor correcto Log.NIVELES
    */
    NivelMinimo {
        get => this._nivelMinimo
        set {
            if not Util_enValores(value, this.NIVELES)
                ErrLanzar(ValueError, "El valor debe ser un nivel contenido en Log.NIVELES", ERR_ERRORES["ERR_ARG"]))
    
            this._nivelMinimo := value
        }
    }

    /*
        @method Vaciar
        @description Vaciar el contenido del archivo de Log

        @throws {OSError} - Si no se puede empezar la posición desde el inicio del archivo.
    */
    Vaciar() {
        if not this._archivo.Seek(0)
            ErrLanzar(OSError, "Error al posicionarse al inicio del archivo", ERR_ERRORES["ERR_ARCHIVO"])

        this._archivo.Length := 0      

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