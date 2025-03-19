#Requires AutoHotkey v2.0

#Include "debug.ahk"
#Include sesion.ahk
#Include error.ahk

if (!IsSet(__CONFIG_H__)) {
    global __CONFIG_H__ := true

    /*
        @class Config

        @description Clase para gestionar todos los datos de configuración.

        @todo Implementar la carga de la configuración desde un archivo .ini.
        Existen 4 capas de configuración: predeterminado, usuario, sistema y sesión (cambios en la propia la interfaz gráfica).
        La capa predeterminada está integrada en el código, las capas de usuario y sistema están en archivos de configuración, y la capa de sesión está solo en memoria. (Se podría hacer una capa específica por módulo de actividad y otra por turno de trabajo).

        En la ventana de configuración, los valores que aparecen son los cargados en memoria. Para guardar en los archivos o leer de los archivos de configuración, siempre se pedirá la confirmación del usuario. Todas las modificaciones en tiempo real de los valores de los parámetros de configuración se harán solo en memoria.

        Existe una pestaña para cada capa de configuración:
        - Pestaña actual o de sesión: es la pestaña con los valores actuales resultantes de todas las capas de configuración. Es decir, el valor mostrado por cada parámetro en esta capa es el que se está aplicando actualmente en la aplicación. Cada parámetro tendrá una mini-ventana emergente de info con el valor cargado en memoria por cada una de las capas de configuración. Si se modifica el valor del parámetro en esta ventana, inicialmente solo se modifica en memoria para la capa de sesión.
        Cada parámetro tiene un icono con varias opciones:
            - Restaurar a los valores de los archivos de configuración: se restauran en memoria los valores de los archivos de configuración y se elimina de la memoria el valor modificado en la capa de sesión.
            - Restaurar a los valores por defecto: se limpian de la memoria los valores obtenidos de los archivos de configuración y modificados en la sesión, dejando solo el valor por defecto.

        El valor en memoria de la configuración de usuario y de sistema es el mismo para las pestañas de configuración de usuario y de sistema. Es decir, si desde la pestaña de sesión se restaura un parámetro eliminando los valores de memoria de configuración de usuario, en la pestaña de configuración de usuario también se verá eliminado el valor de ese parámetro. Lo mismo para la capa de sistema.
        Existe un botón de guardar cambios en el archivo de configuración de usuario o de sistema, y lo que hace es guardar en cada parámetro el valor que se esté aplicando actualmente en la configuración. Si el valor aplicado en la configuración de sesión es el mismo que el de las configuraciones de usuario o de sistema, no se hace nada. Si no hay valor por encima de la capa de usuario o de sistema, y no hay valor en memoria para dicha capa, se elimina el parámetro en el archivo de configuración si estaba definido. Esto suele pasar después de restaurar a los valores por defecto al borrar los valores de memoria de configuración de usuario o de sistema.
        - Pestaña de usuario o de sistema: En esta pestaña se muestran los valores de los parámetros únicamente de configuración de usuario o de sistema. Si se modifica un valor en esta pestaña, se modifica en memoria para la capa de usuario o de sistema. Si se restaura un parámetro a su valor por defecto, se limpia el valor de memoria de la configuración de usuario o de sistema, nada más. El valor modificado en la sesión o en otra pestaña se manetiene en memoria. Si se restaura desde el archivo de configuración, solo se hace desde el archivo de configuración correspondiente a la ventana, modificando en memoria el valor de configuración de usuario o de sistema. Si se guarda, se guarda en el archivo de configuración correspondiente, aunque, al igual que la pestaña de configuración actual, se puede guardar en otros archivos de configuración.
        En lugar de la mini-ventana de info, se indica si el valor del parámetro es por haberlo modificado en el archivo de configuración o no.

        Cada vez que un parámetro cambia de valor, cambia su estado a Modificado. Los parámetros modificados son los que se comprueban para guardar en los archivos de configuración. 
        En la pestaña de configuración actual, al pulsar guardar en el archivo de configuración, el valor que se guarda es el valor actual (siempre se guarda para evitar incoherencias de modificaciones en memoria entre pestañas de configuración), a no ser que no haya ningún valor en ninguna configuración y el valor actual sea el de por defecto, en cuyo caso no se guarda, si no que se elimina el parámetro correspondiente en el archivo de configuración.


        ** ANTIGUO **
        Para cada parámetro en la ventana de configuración, lo que aparece es el valor con mayor precedencia. En una mini-ventana de info, se muestran los valores procedentes de las distintas capas. Todo cambio que se realice en la sesión inicialmente solo afecta a la capa de sesión y se guarda automáticamente en la capa de sesión.

        Existe una pestaña para cada capa de configuración. En cada pestaña se muestran los valores de los parámetros de configuración de esa capa. En la pestaña de sesión se muestran los valores con mayor prioridad de entre todas las capas. Si se modifica


        Cada parámetro tiene tres estados. No modificado, modificado o por defecto.
        - No modificado es el estado en el que está el parámetro con los valores recién obtenidos de los archivos de configuración sin haber modificado nada en la sesión.
        - Modificado es el estado en el que está el parámetro cuando se ha modificado en la sesión.
        - Por defecto es el estado en el que está el parámetro cuando se ha restaurado a los valores por defecto. Al restaurar, se eliminan los valores de todas las capas en memoria excepto la predeterminada. En el mini menú aparecería solo el valor predeterminado. 
        Toda modificación se guarda en tiempo real en la capa de sesión (no es necesario botón Aplicar). Si se cambia al estado Por defecto, en tiempo real se eliminan de memoria los valores de todas las capas excepto la predeterminada. El botón de guardar sirve para guardar a los archivos de configuración usuario y sistema los cambios realizados. Si un parámetro está en estado Modificado, se guarda el valor de la capa de sesión en memoria en la capa de usuario o sistema y, además, se guarda en el archivo de configuración elegido. Si un parámetro está en estado por defecto, al pulsar guardar cambios se elimina el valor del archivo de configuración usuario o sistema (Avisar de esto al usuario). Si un parámetro está en estado no modificado, no se hace nada.

        Al lado de cada parámetro hay un icono donde permite realizar las acciones de Restaurar de archivos de configuración (pasando el parámetro a estado No Modificado) o Restaurar a los valores por defecto (pasando el parámetro a estado Por Defecto) o guardar en archivo de configuración ese parámetro solo.

        En la ventana hay un botón de guardar cambios para guardar los cambios realizados en cada parámetro al archivo de configuración que se desee. También hay un boton de restaurar todos los parámetros a los valores por defecto y otro para restaurar todos los parámetros a los valores de los archivos de configuración.

        En la interfaz del usuario, dar la opción de modificar los valores de la capa de sesión en tiempo real en una ventana de edición, simulando un archivo de configuración, pero solo para la sesión actual. De manera que, en lugar de ir cambiando los valores con el ratón, se pueda hacer con el teclado. Y el contenido de esta ventana tiene que cambiar en tiempo real con el contenido de la ventana de configuración de la interfaz gráfica (se podría actualizar al pasar de esta ventana a la otra) Pero esto es solo en memoria, no hay un archivo de configuración real para la capa de sesión. Cuando se restaure un valor por defecto, en esta ventana debe aparecer un valor especial para ese parámetro indicando que va a ser eliminado de los archivos de configuración.
        Posibilidad: Hacer también la ventana de edición para los archivos de configuración usuario y sistema. De manera que al cambiar algo en el archivo de configuración, automáticamente se cambia en la capa de memoria correspondiente para ese parámetro.

        Los datos de la ventana de edición, ya sea de la capa de sesión, como de la capa de usuario o sistema, son los datos que están en memoria. No los datos de los archivos de configuración. Es decir, que si se modifica la ventana de edición para la capa de usuario, automáticamente se modifica en memoria (aparece en la mini-ventana) y es como si lo hubiese leído del archivo de configuración. Es decir, que los cambios aparecen a la vez en la ventana de edición y en la ventana de interfaz, ambos muestran los datos cargados en memoria. Para guardar al archivo de configuración, se necesita pulsar el botón de guardar cambios. Y el restaurar se hace desde los archivos.

        Para guardar se puede elegir el archivo de configuración al cual guardar, pero para restaurar desde los archivos de configuración se restauran todos los archivos de configuración a la vez.

        Es decir, lo que se haga durante la sesión en la capa de sesión se actualiza en memoria en tiempo real, pero cualquier cambio hacia los archivos de configuración, o restauración de valores desde los archivos de configuración, se necesita la confirmación del usuario. 

        Se podría hacer una opción que consiste en optimizar los archivos de configuración (ejecutada cada cierto tiempo o por el usuario si quiere un control total). Esta opción comprobaría para cada parámetro si su valor es igual al de mayor precedencia de las capas inferiores. Si es así, se elimina, ya que iba a tomar de todas formas el valor aunque no estuviese definido en esa capa. Esto se hace para evitar redundancias en los archivos de configuración.

        @todo Hacer mediante una máquina de estados y expresiones regulares un parser de Arrays y Objetos. Mediante la máquina de estados se comprueba toda la sintaxis y para los valores se comprueba que es un tipo de dato fundamental (Bool, Número, Cadena). Si es también un objeto un array, se pasa el parser de manera recursiva.
    */


    class Config {
        static __New() {
            this.NIVEL_RUTA := Map("usuario", "ruta/{}/config_usuario.ini", "sistema", "ruta/config_sistema.ini")
            this.NIVEL_PRIORIDAD := Map("defecto", 0, "sistema", 1, "usuario", 2, "sesion", 3)
            this.NIVEL_PRIORIDAD_INV := this.NIVEL_PRIORIDAD.InvertirClavesValores()
            this._diccInfo := Util_MapOrden(StrCompare, 
                "clave1", { ; Todas las Claves siempre en minúsculas
                    nombre: "Clave de ejemplo 1",
                    descripcion: "Expliación de la clave de ejemplo 1",
                    tipo: "Bool",
                    defecto: true,
                    validar: [FuncArg.CadenaABool] ; Lista de FuncArgs a aplicarse en orden para validar el valor
                }
                "clave2", { 
                    nombre: "Clave de ejemplo 2",
                    descripcion: "Expliación de la clave de ejemplo 2",
                    tipo: "Integer",
                    defecto: 0,
                    validar: [FuncArg.EsEntero, FuncArg.Entero] 
                }
            )
        }

        /*
            @constructor

            @description Constructor de la clase Config.
            Se crea un solo árbol porque tener uno por cada nivel es muy costoso a la hora de acceder a varios árboles para un solo valor. Se crean cuatro diccionarios, uno por cada nivel, porque restaurar los datos de configuración de un nivel es más sencillo, y la diferencia del coste de acceso entre acceder a un diccionario o a cuatro es similar.

            @param {string} idSesion - Identificador de la sesión.
        */
        __New(sesion) {
            this._sesion := sesion
            this.inicializarValores()
        }

        __Item[clave, nivel] {
            get {
                if this._diccValores.Has(clave)
                    return this._diccValores[clave].Valor[-1]
                
                valores := this._arbolValores[clave]

                return this._diccValores[clave]
            }
            
            set {

            }

        }

        __Enum(numArgs) {
            
        }

        Buscar(clave) {
        
        }

        /*
            @static _ObtenerDiccDesdeArchivo

            @description Obtiene un diccionario de pares clave-valor a partir de un archivo de configuración.

            @param {string} ruta - Ruta del archivo de configuración.

            @returns {Map} Diccionario de pares clave-valor.
            
            @todo Para mostrar la parte de cada línea que es errónea, en lugar de decir que en la línea ha habido un error sin indicar dónde exactamente, se puede hacer algo así:
            RegExMatch(Trim(A_LoopField), "Ui)(.*)\[([a-z_]\w*)\](.*)\")
            De manera que si el grupo 1 y 3 tienen texto, hay error, pudiendo reconstruir la línea con el error resaltado

            Si se usa secciones := IniRead(ruta), obtiene una lista de secciones que luegi habría que usar en bucle para obtener las claves de cada sección con clavesValor := IniRead(ruta, seccion). Sería mucho más sencillo, pero si meten el nombre de una sección mal, simplemente se ignora con todas sus claves, sin poder informar en el log de errores de configuración.
        */
        static _ObtenerDiccDesdeArchivo(ruta) {        
            _Err_VerificarArg_Prv(ruta, "ruta", 1, FuncArg.ExisteArchivo)

            seccion := clave := valor := ""
            estado := "seccion"
            resultado := ""
            valores := Map()

            ; Tabla de transición de la máquina de estados. [estado actual][evento] => nuevo estado
            ; Estados: "seccion": Estado inicial s0 que admite solo una [sección]
            ;          "clave-valor|seccion": Estado s1 que admite una clave=valor o una [sección]
            tablaTransicion := Map(
                "seccion", Map("recibe_seccion", "clave-valor|seccion"), 
                "clave-valor|seccion", Map(
                    "recibe_clave-valor", "clave-valor|seccion", 
                    "recibe_seccion", "clave_valor|seccion"
                )
            )

            ObtenerSeccion() {
                if RegExMatch(linea, 'iU)^\s*\[\s*([_a-z]\w*(\.[_a-z]\w*))*\s*\]\s*$', &resultado) == 0
                    return false

                seccion := StrLower(resultado[1])
                return true
            }

            ObtenerClaveValor() {
                if RegExMatch(linea, "^\s*(?i)([a-z_]\w*)(?-i)\s*=\s*([^\s].*?)\s*$", &resultado) == 0
                    return false

                clave := StrLower(resultado[1])
                valor := resultado[2]
                return true
            }

            Loop read, ruta {
                linea := Trim(A_LoopReadLine)
                if linea = ""
                    continue

                if ObtenerSeccion() {
                    estado := tablaTransicion[estado]["recibe_seccion"]
                    continue
                }

                switch estado {
                    case "seccion":
                        ;Log.Error("(L " A_Index "): Se espera [sección] en el archivo de configuración " ruta ": " linea)
                        continue
                    
                    case "clave-valor|seccion":
                        if !ObtenerClaveValor() {
                            ;Log.Error("Se espera clave = valor o nueva [seccion] en el archivo de configuración " ruta " A_LoopField)
                            continue
                        }

                        clave := seccion "." clave
                        if !this._diccValores.Has(clave) {
                            ;Log.Error("Clave de configuración no reconocida: " clave)
                            continue
                        }

                        try
                            valores[clave] := _Err_VerificarArg_Prv(valor, clave, , Config._diccInfo[clave].validar*) 
                        catch as e {
                            ;Log.Error("L( "A_Index ") Valor de configuración no válido para la clave " clave ": " e.Message)
                            continue
                        }
                        
                        estado := tablaTransicion[estado]["recibe_clave-valor"]
                }
            }

            return valores
        }

        /*
            @method CargarArchivo

            @description Carga los valores de configuración de un nivel desde un archivo.

            @param {string} nivel - Nivel de configuración a cargar.
        */
        CargarArchivo(nivel) {
            if !this.NIVEL_RUTA.Has(nivel)
                throw Err_ValorArgError("Nivel de configuración no existente", , , , , , "nivel", 1, nivel)
                
            ruta := this.NIVEL_RUTA[nivel]
            if nivel == "usuario" 
                ruta := Format(ruta, Usuarios.LISTA[this._sesion.idUsuario].dni)

            try
                tmpDiccValores := Config._ObtenerDiccDesdeArchivo(ruta)
            catch as e {
                ;Log.Error("Error al leer el archivo de configuración " ruta ": " e.Message)
                return
            }

            prioridad := this.NIVEL_PRIORIDAD[nivel]
            for clave, valores in this._diccValores {
                if tmpDiccValores.Has(clave) {
                    valores[prioridad] := tmpDiccValores[clave]
                }
                else if valores.Has(prioridad)
                    valores.Delete(prioridad)
            }
        }


        /*
            @method inicializarValores

            @description Inicializa todos los valores de configuración.
        */
        InicializarValores() {
            this._arbolValores := Util_ArbolMapOrden()
            this._diccValores := Util_MapOrden()

            prioridadDefecto := Config.NIVEL_PRIORIDAD["defecto"]
            for clave, info in this._diccInfo {
                valores := Util_MapOrden((pr1, pr2) => pr1 > pr2)
                this._diccValores[clave] := this._arbolValores[clave] := valores
                valores[prioridadDefecto] := info.defecto
            }

            for nivel in Config.NIVEL_RUTA
                this.CargarArchivo(nivel)

            ; Se ordena el diccionario de valores por claves.
            this._diccValores.Comparar := StrCompare
        }
    }

    /*
    */

    _IniciarLogs() {
        for grupoLog, datosLog in logs {
            GestionLogs.crearGrupoLog(grupoLog, datosLog)
        }

    CargarConfig {

    }

    GuardarConfig {

    }
    CambiarParametro
    ObtenerParametro
}
