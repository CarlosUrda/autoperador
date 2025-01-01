/*
    Librería para gestionar el registro de errores y sucesos en un archivo log.
*/

#Requires AutoHotkey v2.0

#Include "util.ahk"
#Include "error.ahk"


NOMBRE_LOG          := "" ; Nombre del archivo de log
ARCHIVO_LOG         := "" ; Archivo de log abierto


/*
    @class Log
    @description Clase para encapsular un archivo de Log.

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
        @param {Boolean} vaciarLog - Si true se crea el archivo de log vacío (modo "w" al abrirlo); si false se abre manteniendo su contenido posicionándose al final (modo "a").
        @param {Number} nivelMinimo - Umbral mínimo que deberán tener los mensajes para poder ser registrados en el log

        @throws {ValueError} - Si el argumentos nivelMinimo no tiene valor correcto de Log.NIVELES
        @throws {OSError} - Si hay problemas al abrir el archivo o moverse dentro al inicializarlo.
    */
    __New(nombreArchivo, vaciarLog := true, nivelMinimo := this.NIVELES["INFORMACION"]) {
        if not Util_enValores(nivelMinimo, this.NIVELES)
            ErrLanzar(ValueError, "nivelMinimo " nivelMinimo " debe ser valor de nivel contenido en Log.NIVELES", ERR_ERRORES["ERR_ARG"])

        this._nivelMinimo := nivelMinimo

        try 
            this._archivo := FileOpen(nombreArchivo, vaciarLog ? "w" : "a")
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


    /*
        @method EscribirMensaje
        @descripcion escribir un mensaje en el archivo de este objeto Log.      

        @param mensaje {String} - Cadena de texto a escribir como mensaje
        @param nivelMensaje {Number} - nivel de importancia del mensaje (valor posible de Log.NIVELES)

        @return {Number} - Número de bytes (no caracteres) escritos. Si el nivel del mensaje no es mínimo el nivel del Log, el mensaje no es escrito y devuelve 0.
    */
    EscribirMensaje(mensaje, nivelMensaje) {
        if not Util_enValores(nivelMensaje, this.NIVELES)
            ErrLanzar(ValueError, "NivelMensaje debe ser valor válido de nivel contenido en Log.NIVELES", ERR_ERRORES["ERR_ARG"])

        return (nivelMensaje < this._nivelMinimo) ? 0 : this._archivo.WriteLine(mensaje)
   }
}


/*
    @class GrupoLog
    @description Clase para encapsular un log como un grupo de tipos de mensajes para ese log
*/
class GrupoLog {
    __New(nombre, logPadre, nombreArchivo, vaciarLog := true, nivelMinimo := Log.NIVELES["INFORMACION"], activado := true) {
        if Type(logPadre) != "Log"
            ErrLanzar(TypeError, "El padre no es un objeto tipo Log", ERR_ERRORES["ERR_TIPO"])

        try {
            this._log := Log(nombreArchivo, vaciarLog, nivelMinimo)
        }
        catch as e {
            ErrMsgBox(e)
            ErrLanzar(ObjetoError, "No se ha podido crear el objeto Log " nombreArchivo, ERR_ERRORES["ERR_OBJETO"])
        }

        this._nombre := nombre
        this._logPadre:= logPadre
        this._activado := activado
        
    }
}


/*
    @class GestionLogs
    @description Clase para gestionar los logs que se van a usar en un programa.

    @static
        - {Map} logAsociados - Contiene el objeto Log asociado con cada elemento ("GLOBAL" todo el programa)
*/
class GestionLogs {

    static _gruposLogs := Map("GLOBAL", Map("log", NULL, "padre", NULL))

    static asignarLog(log) {

    }

    /*
        @method crearGrupoLog
        @description Crear un objeto Log asociado a un grupo de tipos de mensajes determinados.

        @param {String} nombreGrupo - Nombre del grupo de tipos de mensajes que irán a este log.
        @param {String} nombreArchivo - Nombre del archivo de log a abrir o crear.
        @param {Boolean} vaciarLog - Si true se crea el archivo de log vacío (modo "w" al abrirlo); si false se abre manteniendo su contenido posicionándose al final (modo "a").
        @param {Number} nivelMinimo - Umbral mínimo que deberán tener los mensajes para poder ser registrados en el log

        @throws {ObjetoError} - Si existe algún error al crear el objeto Log
        
    */
    static crearGrupoLog(nombreGrupo, nombreArchivo, vaciarLog, nivelMinimo) {
        try {
            log := Log(nombreArchivo, vaciarLog, nivelMinimo)
        }
        catch as e {
            MsgBox(e.What " - " e.Message, "ERROR " e.Extra ": " ERR_INFO_CODIGOS[e.Extra]["nombre"] " - " ERR_INFO_CODIGOS[e.Extra]["mensaje"])
            ErrLanzar(ObjetoError, "No se ha podido crear el objeto Log " nombreArchivo, ERR_ERRORES["ERR_OBJETO"])
        }
        try {
            this._grupoLogs[nombreGrupo] := 
        }
    }

    static ObtenerLog(grupoLog) {

    }

    /*
    */
    static EscribirMensaje(mensaje, nivelMensaje, grupoLog) {
        log := this.ObtenerLog()
        if log == NULL
            return 0

        return log.EscribirMensaje(mensaje, nivelMensaje)

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

