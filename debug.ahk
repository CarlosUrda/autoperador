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
        @param {Number} nivelMinimo - Nivel mínimo de criticidad que deberán tener los mensajes para poder ser registrados en el log
        @param {Boolean} vaciarLog - true se crea el archivo de log vacío (modo "w" al abrirlo); false lo abre manteniendo su contenido posicionándose al final (modo "a").
        @param {Boolean} activo - Si false impide que se escriban mensajes en el log.

        @throws {ValueError} - Si el argumentos nivelMinimo no tiene valor correcto de Log.NIVELES
        @throws {OSError} - Si hay problemas al asignar el archivo al log.
    */
    __New(nombreArchivo, nivelMinimo := this.NIVELES["INFORMACION"], vaciarLog := true, activo := true) {
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

        @description Abrir un archivo dejándolo asignarlo a este log.

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
        set => this._activo := !!value
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
    @class ContenedorLogs
    @description Clase contenedor para guardar logs asociados a un nombre.

    @static
        - _infoLogs {Map} - Diccionario donde se guardan los logs, etiquetando cada uno con un nombre que lo identifica de manera única. La clave es el nombre usado para etiquetar al log y el valor es otro Map que contiene los valores: 
            "log" {RegLog} - Objeto Reglog.
            "padre" {String} - Nombre de la etiqueta del log padre.
            "delegar" {Boolean} - Si false el log no se usará y no se volcarán mensajes.
*/
class ContenedorLogs {

    static _infoLogs := Map("GLOBAL", Map("log", NULL, "padre", NULL, "delegar", false))


    /*
        @method _ComprobarArgs

        @description Comprobar los argumentos que se pasan a los distintos métodos de ContenedorLogs

        @param {Map} args - Diccionario con el par (nombre de argumento, valor)
        @param {Number} linea - Número de línea donde ocurre el error en la función llamante
        @param {String} funcion - Nombre de la función llamante.

        @throws {ValueError} - Si el nombreLog no es válido.
        @trhows {IndexError} - Si el nombre del log o del padre no existe en el contenedor.
        @throws {TypeError} - Si el objeto Log no es de tipo RegLog

    */
    static _ComprobarArgs(args, linea := A_LineNumber, funcion := A_ThisFunc) {
        for arg, valor in args {
            switch arg {
                case "nombreLog":
                    if not this.ExisteLog(valor)
                        ErrLanzar(IndexError, "El log " valor " no existe en el contenedor", ERR_ERRORES["ERR_ARG"], linea, funcion)

                case "nombreLog_repe":
                    if valor == NULL or this.ExisteLog(valor)
                        ErrLanzar(ValueError, "Nombre de log " valor " a agregar no válido: Ya existe o es vacío)", ERR_ERRORES["ERR_ARG"], linea, funcion)
            
                case "nombreLogPadre":
                    if valor != NULL and not this.ExisteLog(valor)
                        ErrLanzar(IndexError, "El nombre " valor " del log padre no existe en el contenedor", ERR_ERRORES["ERR_ARG"], linea, funcion)

                case "regLog":
                    if valor != NULL and Type(valor) != "RegLog"
                        ErrLanzar(TypeError, "El argumento regLog no es de tipo correcto", ERR_ERRORES["ERR_ARG"], linea, funcion)
            
            }
        }

    }

    /*
        @property __Item

        @description Acceder al objeto RegLog asociado con un nombre de log. 

        @param {String} nombreLog - Nombre del log a obtener o modificar.

        @method get - Obtiene el objeto RegLog asociado con el nombreLog. Si el nombre de log tiene activado la delegación al padre, se obtiene el RegLog del primer padre que no delega.
        @method set - Cambia el objeto RegLog asociado con el nombreLog.
    */
    static __Item[nombreLog] {
        get {
            this._ComprobarArgs(Map("nombreLog", nombreLog))

            infoLog := this._infoLogs[nombreLog]

            if infoLog["delegar"] {
                return infoLog["padre"] == NULL ? NULL : this[infoLog["padre"]]
            }

            return infoLog["log"]
        }

        set {
            this._ComprobarArgs(Map("nombreLog", nombreLog), A_LineNumber, A_ThisFunc)

            if value != NULL and Type(value) != "RegLog"
                ErrLanzar(TypeError, "El valor no es de tipo correcto RegLog", ERR_ERRORES["ERR_TIPO"])
    
            this._infoLogs[nombreLog]["log"] := value
        }
    }

    /*
        @method CambiarPadre

        @description Cambiar el nombre del log del padre.

        @param {String} nombreLog - Nombre del log a cambiar su padre.
        @param {String} nombreLogPadre - Etiqueta para identificar al log padre. NULL sin padre

        @trhows {IndexError} - Si el nombre del log o del padre no existe en el contenedor.
    */
    static CambiarPadre(nombreLog, nombreLogPadre, delegar) {
        this._ComprobarArgs(Map("nombreLog", nombreLog, "nombreLogPadre", nombreLogPadre))

        this._infoLogs[nombreLog]["padre"] := nombreLogPadre
        this._infoLogs[nombreLog]["delegar"] := !!delegar
    }


    /*
        @method Delegar

        @description Cambiar la delegación al padre.

        @param {String} nombreLog - Nombre del log a cambiar su delegación.
        @param {Boolean} delegar - true ignora el log de nombreLog y usa el del padre.

        @trhows {IndexError} - Si el nombre del log no existe en el contenedor.
    */
    static Delegar(nombreLog, delegar) {
        this._ComprobarArgs(Map("nombreLog", nombreLog))

        this._infoLogs[nombreLog]["delegar"] := !!delegar

    }


    /*
        @method AgregarLog
        @description Agrega un log al contenedor de logs asociándolo con un nombre que lo identifica.

        @param {String} nombreLog - Etiqueta para identificar al log.
        @param {String|NULL} regLog - Objeto RegLog asociado al nombreLog. Puede ser NULL.
        @param {String} nombreLogPadre - Etiqueta para identificar al log padre. NULL si no tiene log padre.
        @param {Boolean} delegar - true ignora ese log y usa el del padre.
        
        @throws {ValueError} - Si existe algún error con los valores de los argumentos.
        @throws {TypeError} - Si el objeto Log no es de tipo RegLog
        @trhows {IndexError} - Si el nombre del padre no existe en el contenedor.
        
    */
    static AgregarLog(nombreLog, regLog := NULL, nombreLogPadre := NULL, delegar := false) {
        this._ComprobarArgs(Map("nombreLog_repe", nombreLog, "regLog", regLog, "nombreLogPadre", nombreLogPadre))

        this._infoLogs[nombreLog] := Map("log", regLog, "padre", nombreLogPadre, "delegar", delegar)
    }


    /*
        @method existeLog
        @description Muestra si se ha creado previamente un log bajo ese nombre.

        @param nombreLog {String} - Nombre del log a comprobar si existe.
        
        @return true si el log existe, o false si no.
    */
    static ExisteLog(nombreLog) {
        return this._infoLogs.Has(nombreLog)
    }


    /*
        @method EscribirLog
        @description Escribir un mensaje en el log asociado a nombreLog. Esta función envuelve a EscribirMensaje de un objeto RegLog y existe para no tener que comprobar si nombreLog no tiene ningún log asociado.

        @param nombreLog {String} - Nombre que idenrtifica al log.
        @param mensaje {String} - Mensaje a ser escrito en el log.
        @param nivelMensaje {Number} - Criticidad del mensaje cuyo valor debe estar en Log.NIVELES.

        @trhows {IndexError} - Si el nombreLog no existe en el contenedor.

        @returns {Number} - Número de bytes escritos en el log
    */
    static EscribirLog(nombreLog, mensaje, nivelMensaje) {
        if not this.ExisteLog(nombreLog) {
            ErrLanzar(IndexError, "No existe ningún log con el nombre " nombreLog, ERR_ERRORES["ERR_ARG"])
        }

        regLog := this[nombreLog]
        if regLog == NULL
            return 0

        return regLog.EscribirMensaje(mensaje, nivelMensaje)
    }

}
