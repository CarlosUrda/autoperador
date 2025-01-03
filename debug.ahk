/*
    Librería para gestionar el registro de errores y sucesos en un archivo log.

    @todo En GestorLog dar la opción de para un nombre de Log que su log sea NULL, ya que el nombre de log estará usado por todo el código, pero en caso de no querer usarlo no hay necesidad de crear un log desactivado, abriendo el archivo para nada.
*/

#Requires AutoHotkey v2.0

#Include "util.ahk"
#Include "error.ahk"



/*
    @class RegLog
    @description Clase para encapsular un archivo de Log.

    @property {Number} NivelMinimo - Obtener o cambiar el valor del nivel mínimo de los mensajes.

    @method Vaciar - Vaciar el contenido del archivo log.
    @method AsignarArchivo - Abre un archivo asignándolo internamente al objeto log.
    @method EscribirMensaje - Escribe un mensaje como una línea en el archivo del log.

    @static
        - {Map} NIVELES - Niveles de criticidad de los mensajes a ser mostrados en el log.
*/
class RegLog {
    static NIVELES := Map("INFORMACION", 0, "AVISO", 1, "MEDIO", 2, "CRITICO", 3)

    /*
        @method Constructor

        @param {String} nombreArchivo - Nombre del archivo de log a abrir o crear.
        @param {Boolean} vaciarLog - Si true se crea el archivo de log vacío (modo "w" al abrirlo); si false se abre manteniendo su contenido posicionándose al final (modo "a").
        @param {Number} nivelMinimo - Umbral mínimo que deberán tener los mensajes para poder ser registrados en el log
        @param {Boolean} activo - Si false impide que se escriban mensajes en el log.

        @throws {ValueError} - Si el argumentos nivelMinimo no tiene valor correcto de Log.NIVELES
        @throws {OSError} - Si hay problemas al asignar el archivo al log.
    */
    __New(nombreArchivo, vaciarLog := true, nivelMinimo := this.NIVELES["INFORMACION"], activo := true) {
        if not Util_enValores(nivelMinimo, this.NIVELES)
            ErrLanzar(ValueError, "nivelMinimo " nivelMinimo " debe ser valor de nivel contenido en Log.NIVELES", ERR_ERRORES["ERR_ARG"])

        this._nivelMinimo := nivelMinimo
        this.Activo := activo

        try 
            this.AsignarArchivo(nombreArchivo, vaciarLog)
        catch as e
            ErrMsgBox(e)
            ErrLanzar(OSError, "El archivo " nombreArchivo " no puede asignarse al log", ERR_ERRORES["ERR_ARCHIVO"])
    }

    
    /*
        @method Destructor de Log
    */
    __Delete() {
        try {
            this._archivo.Close()
        }
        catch as e
            ErrLanzar(OSError, "El archivo " this._nombreArchivo " no puede cerrarse: " e.Message, ERR_ERRORES["ERR_ARCHIVO"])
    }


    /*
        @method AsignarArchivo

        @description Abrir un archivo para dejarlo asignarlo a este log.

        @param {String} nombreArchivo - Nombre del archivo de log a abrir o crear.
        @param {Boolean} vaciarLog - Si true se crea el archivo de log vacío (modo "w" al abrirlo); si false se abre manteniendo su contenido posicionándose al final (modo "a").

        @throws {OSError} - Si hay problemas al abrir el archivo.
    */
    AsignarArchivo(nombreArchivo, vaciarLog) {
        try 
            this._archivo := FileOpen(nombreArchivo, vaciarLog ? "w" : "a")
        catch as e
            ErrLanzar(OSError, "El archivo " nombreArchivo " no puede abrirse: " e.Message, ERR_ERRORES["ERR_ARCHIVO"])

        this._nombreArchivo = nombreArchivo
    }


    /*
        @property Activo

        @method get - Obtiene el valor del flag activo
        @method set - Cambia el flag a true (valor != 0) o false (valor == 0)
    */
    Activo {
        get => this._activo
        set => this._activo := value != false
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
                ErrLanzar(ValueError, "El valor debe ser un nivel contenido en Log.NIVELES", ERR_ERRORES["ERR_ARG"])
    
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
    @description Clase para asociar un log con un grupo de tipos de mensajes para ese log. Sirve para poder etiquetar un Log mediante un nombre guardando toda la información relacionada con el Log.

    @param nombreGrupo {String} - Nombre del grupo asociado a un log.
    @param grupoLogPadre {GrupoLog} - GrupoLog de jerarquia superior a usar en caso de
    @param nombreArchivo {String} - Nombre del archivo de Log

*/
/*
class GrupoLog {
    __New(nombreGrupo, grupoLogPadre, nombreArchivo, vaciarLog := true, nivelMinimo := Log.NIVELES["INFORMACION"], activado := true) {
        if grupoLogPadre != NULL and Type(grupoLogPadre) != "GrupoLog"
            ErrLanzar(TypeError, "El padre no es un objeto tipo Log", ERR_ERRORES["ERR_TIPO"])

        if nombreArchivo == NULL
            this._log := NULL
        else
            try {
                this._log := Log(nombreArchivo, vaciarLog, nivelMinimo)
            }
            catch as e {
                ErrMsgBox(e)
                ErrLanzar(ObjetoError, "No se ha podido crear el objeto Log " nombreArchivo, ERR_ERRORES["ERR_OBJETO"])
            }

        this._nombre := nombreGrupo
        this._grupoLogPadre:= grupoLogPadre
        this._activado := activado
        
    }
}
*/


/*
    @class GestionLogs
    @description Clase para gestionar los logs que se van a usar en un programa.

    @method crearLog - 

    @static
        - _logs {Map} - Diccionario donde se guardan los logs, etiquetando cada uno con un nombre que lo identifica de manera única. La clave es el nombre usado para etiquetar al log y el valor es otro Map que contiene los valores: 
            "log" {Log} - Objeto log.
            "padre" {String} - Nombre de la etiqueta del log padre.
            "activado" {Boolean} - Si false el log no se usará y no se volcarán mensajes.
*/
class GestionLogs {

    static _logs := Map("GLOBAL", Map("log", NULL, "padre", NULL, "activado", true))

    static asignarLog(log) {

    }

    /*
        @method crearGrupoLog
        @description Crea un log asociándolo con un nombre que lo identifica. Sirve para poder etiquetar un Log mediante un nombre guardando información adicional relacionada con el Log.

        @param {String} nombreLog - Etiqueta para identificar al log.
        @param {String} nombreArchivo - Nombre del archivo que se asignará al log.
        @param {String} nombreLogPadre - Etiqueta para identificar al log padre.
        @param {Boolean} vaciarLog - Si true se crea el archivo de log vacío (modo "w" al abrirlo); si false se abre manteniendo su contenido posicionándose al final (modo "a").
        @param {Number} nivelMinimo - Umbral mínimo que deberán tener los mensajes para poder ser registrados en el log

        @throws {ValueError} - Si existe algún error al crear el objeto Log
        @throws {ObjetoError} - Si existe algún error al crear el objeto Log
        
    */
    static CrearLog(nombreLog, nombreArchivo, nombreLogPadre, vaciarLog := true, nivelMinimo := Log.NIVELES["INFORMACION"], activado := true) {
        if nombreLogPadre != NULL and not this.existeLog(nombreLogPadre)
            ErrLanzar(ValueError, "El nombre del log padre no existe", ERR_ERRORES["ERR_ARG"])
        if nombreLog == NULL
            ErrLanzar(ValueError, "El nombre que identifica al log no puede estar vacío", ERR_ERRORES["ERR_ARG"])

        try {
            this._logs[nombreLog] := Map("log", Log(nombreArchivo, vaciarLog, nivelMinimo), "padre", nombreLogPadre, "activado", activado)
        }
        catch as e {
            ErrMsgBox(e)
            ErrLanzar(ObjetoError, "No se ha podido crear el objeto Log para " nombreArchivo, ERR_ERRORES["ERR_OBJETO"])
        }
    }


    /*
        @method existeLog
        @description Muestra si se ha creado previamente un log bajo ese nombre.

        @param nombreLog {String} - Nombre del log a comprobar si existe.
        
        @return true si el log existe, o false si no.
    */
    static ExisteLog(nombreLog) {
        return this._logs.Has(nombreLog)
    }


    /*
        @method EscribirLog
        @description Escribir un mensaje en un log

        @param nombreLog {String} - Nombre que idenrtifica al log.
        @param mensaje {String} - Mensaje a ser escrito en el log.
        @param nivelMensaje {Number} - Criticidad del mensaje cuyo valor debe estar en Log.NIVELES.

        @returns {Number} - Número de bytes escritos en el log
    */
    static EscribirLog(nombreLog, mensaje, nivelMensaje) {
        if not this.ExisteLog(nombreLog) {
            ErrLanzar(ValueError, "No existe ningún log con el nombre " nombreLog, ERR_ERRORES["ERR_ARG"])
        }

        infoLog := this._logs[nombreLog]
        if not infoLog["activado"]
            return 0

        log := infoLog["delegar"] ? this._logs[infoLog["padre"]]["log"] : infoLog[nombreLog]["log"]

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

