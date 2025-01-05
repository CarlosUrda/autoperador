/*
    Librería para gestionar el registro de errores y sucesos en un archivo log.

    @todo En GestorLog dar la opción de para un nombre de Log que su log sea NULL, ya que el nombre de log estará usado por todo el código, pero en caso de no querer usarlo no hay necesidad de crear un log desactivado, abriendo el archivo para nada.
*/

#Requires AutoHotkey v2.0

#Include "util.ahk"
#Include "error.ahk"


if (!IsSet(__REGLOG_H__)) {
    global __REGLOG_H__ := true

    /* 
        @global {Boolean} Variable para saber si se deben imprimir mensajes de error al fallar la librería RegLog.
    */
    global REGLOG_DEBUG := true


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
            @static _ComprobarArgs

            @description Comprobar los argumentos que se pasan a los distintos métodos.

            @param {Map} args - Diccionario con el par (nombre de argumento, valor)
            @param {Number} linea - Número de línea donde ocurre el error en la función llamante
            @param {String} funcion - Nombre de la función llamante.
            @param {Number} codigoError - Número de código del error. Si el código no está entre los valores de ERR_ERRORES se ignora al lanzar la excepción.

            @throws {ValueError} - Si el argumentos nivelMinimo no tiene valor correcto de Log.NIVELES

            @todo Enviar un codigoError por cada argumento a comprobar, aunque puede que sea innecesario porque al llamar a esta función se hace para comprobar varios valores a la vez, y el código de error suele ser el mismo para todos (por ejemplo, ERR_ARG).
        */
        static _ComprobarArgs(args, linea := A_LineNumber, funcion := A_ThisFunc, codigoError?) {
            ; Esta comprobación podría sobrar ya que es un método privado solo llamado internamente, y en teoría voy a pasar siempre un código correcto.
            if IsSet(codigoError) and not Util_enValores(codigoError, ERR_ERRORES)
                codigoError := unset

            for arg, valor in args {
                switch arg {
                    case "nivel":
                        if not Util_enValores(valor, this.NIVELES)
                            Err_Lanzar(ValueError, "El nivel " valor " debe ser un valor contenido en Log.NIVELES", codigoError?, linea, funcion)
                }
            }
        }
                

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
            this._ComprobarArgs(Map("nivel", nivelMinimo), , , ERR_ERRORES["ERR_ARG"])
            this._nivelMinimo := nivelMinimo
            this.Activo := activo

            try 
                this.AsignarArchivo(nombreArchivo, vaciarLog)
            catch as e
                if REGLOG_DEBUG
                    ErrMsgBox(e)
                Err_Lanzar(OSError, "El archivo " nombreArchivo " no puede asignarse al log", ERR_ERRORES["ERR_ARCHIVO"])
        }

        
        /*
            @method Destructor de Log
        */
        __Delete() {
            try {
                this._archivo.Close()
            }
            catch as e
                Err_Lanzar(OSError, "El archivo " this._nombreArchivo " no puede cerrarse: " e.Message, ERR_ERRORES["ERR_ARCHIVO"])
        }


        /*
            @method AsignarArchivo

            @description Abrir un archivo dejándolo asignarlo a este log.

            @param {String} nombreArchivo - Nombre del archivo de log a abrir o crear.
            @param {Boolean} vaciarLog - Si true se crea el archivo de log vacío (modo "w" al abrirlo); si false se abre manteniendo su contenido posicionándose al final (modo "a").

            @throws {OSError} - Si hay problemas al abrir el archivo.

            @returns ERR_ERRORES["CORRECTO"] si se ejecuta correctamente.
        */
        AsignarArchivo(nombreArchivo, vaciarLog) {
            try 
                this._archivo := FileOpen(nombreArchivo, vaciarLog ? "w" : "a")
            catch as e
                Err_Lanzar(OSError, "El archivo " nombreArchivo " no puede abrirse: " e.Message, ERR_ERRORES["ERR_ARCHIVO"])

            this._nombreArchivo = nombreArchivo

            return ERR_ERRORES["CORRECTO"]
        }


        /*
            @property Activo

            @method get - Obtiene el valor del flag activo
            @method set - Cambia el flag a true o false
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
                this._ComprobarArgs(Map("nivel", value))      
                this._nivelMinimo := value
            }
        }

        /*
            @method Vaciar
            @description Vaciar el contenido del archivo de Log

            @throws {OSError} - Si no se puede empezar la posición desde el inicio del archivo.

            @returns ERR_ERRORES["CORRECTO"] si se ejecuta correctamente.
        */
        Vaciar() {
            if not this._archivo.Seek(0)
                Err_Lanzar(OSError, "Error al posicionarse al inicio del archivo", ERR_ERRORES["ERR_ARCHIVO"])

            this._archivo.Length := 0      

            return ERR_ERRORES["CORRECTO"]
        }


        /*
            @method EscribirMensaje
            @descripcion Escribir un mensaje en el archivo de este objeto Log.      

            @param mensaje {String} - Cadena de texto a escribir como mensaje
            @param nivelMensaje {Number} - nivel de importancia del mensaje (valor posible de Log.NIVELES)

            @return {Number} - Número de bytes (no caracteres) escritos. Si el nivel de criticidad del mensaje no es mínimo el nivel del Log o el log no está activo, el mensaje no es escrito y devuelve 0.
        */
        EscribirMensaje(mensaje, nivelMensaje) {
            this._ComprobarArgs(Map("nivel", nivelMensaje), , , ERR_ERRORES["ERR_ARG"])

            return (!this.activo or nivelMensaje < this._nivelMinimo) ? 0 : this._archivo.WriteLine(mensaje)
        }
    }



    /*
        @class ContenedorLogs
        @description Clase contenedor para guardar por cada entrada toda la información asociada a un log.

        @static
            - _infoLogs {Map} - Diccionario donde se guarda por cada entrada toda la información de cada log. La clave es el nombre para identificar al log y el valor es un Map que contiene los valores: 
                "log" {RegLog} - Objeto Reglog.
                "padre" {String} - Nombre de la etiqueta del log padre.
                "delegar" {Boolean} - Si false el log no se usará y no se volcarán mensajes.
            Si la clave nombreLog existe signifca que está operativo, aunque puede que no tenga asignado aún ningún RegLog y, mientras sea así, no volcará ningún dato. Si la clave nombreLog no existe significa que a través de nombreLog nunca se podrá acceder a ningún RegLog, siendo un tipo de log inexistente. Esto se hace para dar la opción de desactivar el volcado de registros a un nombreLog sin tener que tocar el código donde está indicado escribir datos en ese nombreLog. SImplemente eliminando el RegLog asociado a ese nombreLog, o cambiando a inactivo el propio RegLog asociado, ya no volcaría nada a través de ese nombreLog.
    */
    class ContenedorLogs {

        static _infoLogs := Map()


        /*
            @method _ComprobarArgs

            @description Comprobar los argumentos que se pasan a los distintos métodos de ContenedorLogs. Nombre de argumentos a comprobar y saltan error:
                - nombreLog: si el valor no existe como nombreLog en el contenedor.
                - nombreLogRepe: si el valor ya existe como nombreLog en el contenedor o es NULL
                - nombreLogPadre: si el valor no es NULL y no existe como nombreLog en el contenedor.
                - regLog: si el valor no es NULL y no es de tipo RegLog.

            @param {Map} args - Diccionario con el par (nombre de argumento, valor)
            @param {Number} linea - Número de línea donde ocurre el error en la función llamante
            @param {String} funcion - Nombre de la función llamante.
            @param {Number} codigoError - Número de código del error. Si el código no está entre los valores de ERR_ERRORES se ignora al lanzar la excepción.

            @throws {ValueError} - Si el nombreLog no es válido.
            @trhows {IndexError} - Si el nombre del log o del padre no existe en el contenedor.
            @throws {TypeError} - Si el objeto Log no es de tipo RegLog

            @todo Enviar un codigoError por cada argumento a comprobar, aunque puede que sea innecesario porque al llamar a esta función se hace para comprobar varios valores a la vez, y el código de error suele ser el mismo para todos (por ejemplo, ERR_ARG).
        */
        static _ComprobarArgs(args, linea := A_LineNumber, funcion := A_ThisFunc, codigoError?) {
            ; Esta comprobación podría sobrar ya que es un método privado solo llamado internamente, y en teoría voy a pasar siempre un código correcto.
            if IsSet(codigoError) and not Util_enValores(codigoError, ERR_ERRORES)
                codigoError := unset

            for arg, valor in args {
                switch arg {
                    case "nombreLog":
                        if not this.ExisteLog(valor)
                            Err_Lanzar(IndexError, "El nombre de log " valor " no existe en el contenedor", codigoError?, linea, funcion)

                    case "nombreLog_repe":
                        if valor == NULL or this.ExisteLog(valor)
                            Err_Lanzar(ValueError, "Nombre de log " valor " a agregar no válido: Ya existe o es vacío)", codigoError?, linea, funcion)
                
                    case "nombreLogPadre":
                        if valor != NULL and not this.ExisteLog(valor)
                            Err_Lanzar(IndexError, "El nombre " valor " del log padre no existe en el contenedor", codigoError?, linea, funcion)

                    case "regLog":
                        if valor != NULL and Type(valor) != "RegLog"
                            Err_Lanzar(TypeError, "El valor no es de tipo correcto RegLog", codigoError?, linea, funcion)
                
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
                this._ComprobarArgs(Map("nombreLog", nombreLog), , , ERR_ERRORES["ERR_INDICE"])

                infoLog := this._infoLogs[nombreLog]

                if infoLog["delegar"] {
                    return infoLog["padre"] == NULL ? NULL : this[infoLog["padre"]]
                }

                return infoLog["log"]
            }

            set {
                this._ComprobarArgs(Map("nombreLog", nombreLog, "regLog", value), , , ERR_ERRORES["ERR_INDICE"])

                this._infoLogs[nombreLog]["log"] := value
            }
        }


        /*
            @method CambiarPadre

            @description Cambiar el nombre del log del padre.

            @param {String} nombreLog - Nombre del log a cambiar su padre.
            @param {String} nombreLogPadre - Etiqueta para identificar al log padre. NULL sin padre. Sin valor no se cambia el padre.
            @param {Boolean} delegar - true ignora el log asociado a nombreLog y usa el del padre. Sin valor no se cambia.

            @returns ERR_ERRORES["CORRECTO"] si se ejecuta correctamente.

            @trhows {IndexError} - Si el nombre del log o del padre no existe en el contenedor.
        */
        static CambiarPadre(nombreLog, nombreLogPadre?, delegar?) {
            this._ComprobarArgs(Map("nombreLog", nombreLog, "nombreLogPadre", nombreLogPadre), , , ERR_ERRORES["ERR_ARG"])

            if IsSet(nombreLogPadre)
                this._infoLogs[nombreLog]["padre"] := nombreLogPadre
            if IsSet(delegar)
                this._infoLogs[nombreLog]["delegar"] := !!delegar

            return ERR_ERRORES["CORRECTO"]
        }


        /*
            @method AgregarLog
            @description Agrega una entrada con toda la información de un log al contenedor de logs.

            @param {String} nombreLog - Etiqueta para identificar al log.
            @param {String|NULL} regLog - Objeto RegLog asociado al nombreLog. Puede ser NULL.
            @param {String} nombreLogPadre - Etiqueta para identificar al log padre. NULL si no tiene log padre.
            @param {Boolean} delegar - true ignora ese log y usa el del padre.
            
            @throws {ValueError} - Si existe algún error con los valores de los argumentos.
            @throws {TypeError} - Si el objeto Log no es de tipo RegLog
            @trhows {IndexError} - Si el nombre del padre no existe en el contenedor.
            
            @returns ERR_ERRORES["CORRECTO"] si se ejecuta correctamente.
        */
        static AgregarLog(nombreLog, regLog := NULL, nombreLogPadre := NULL, delegar := false) {
            this._ComprobarArgs(Map("nombreLog_repe", nombreLog, "regLog", regLog, "nombreLogPadre", nombreLogPadre), , , ERR_ERRORES["ERR_ARG"])

            this._infoLogs[nombreLog] := Map("log", regLog, "padre", nombreLogPadre, "delegar", delegar)

            return ERR_ERRORES["CORRECTO"]
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
            @method MetodoRegLog

            @description Ejecutar cualquier método del objeto RegLog asociado con el noombre de un log registrado en el contenedor. Si no existe objeto RegLog asociado al nombre de log, el método no hace nada. En caso de que se necesite saber específicamente qué hacer si existe objeto RegLog o no se tendrá que obtener directamente mediante ContenedorLogs[] el objeto RegLog.

            @throws {MemeberError} - Si el objeto RegLog no admite el método o los argumentos.

            @returns Si el nombre del log no tiene asociado ningún RegLog retorna sin valor. Si tiene asociado un RegLog, devuelve el mismo valor retornado por el método.
        */
        static MetodoRegLog(nombreLog, metodo, args*) {
            this._ComprobarArgs(Map("nombreLog", nombreLog), , , ERR_ERRORES["ERR_ARG"])

            regLog := this[nombreLog]
            if regLog == NULL
                return

            try {
                return regLog.%metodo%(args*)
            }
            catch as e {
                Err_Lanzar(MemberError, "Error al invocar al método " metodo ": " e.Message, ERR_ERRORES["ERR_ARG"])
            }
        }
    }
}
