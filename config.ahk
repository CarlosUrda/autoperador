#Requires AutoHotkey v2.0

#Include "debug.ahk"

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
    */


    class Config {
        static __New() {
            this.NIVEL_RUTA := Map("usuario", "config_usuario.ini", "sistema", "config_sistema.ini")
            this.NIVEL_PRIORIDAD := Map("defecto", 0, "sistema", 1, "usuario", 2, "sesion", 3)
            this.NIVEL_PRIORIDAD_INV := this.NIVEL_PRIORIDAD.InvertirClavesValores()
            this._diccInfo := Util_MapOrden(StrCompare, 
                "configuracion", {
                    nombre: "Configuración",
                    descripcion: "Configuración de la aplicación",
                    tipo: "bool",
                    defecto: true,
                    validar: FuncArg.EsBool,
                    convertir: true
                }
            )
            this._diccValores := Util_MapOrden()
            this._arbolValores := Util_ArbolMapOrden()
        }

        static CargarArchivo(nivel) {
            if !this.NIVEL_RUTA.Has(nivel)
                throw Err_ValorArgError("Nivel de configuración no existente", , , , , , "nivel", 1, nivel)
                
            FileEncoding "UTF-8"

            valores := Map()
            resultado := ""

            Loop read ruta {
                emparejados := RegExMatch(A_LoopReadLine, '^\s*"([^"]+)"\s*:\s*(.+)\s*$', &resultado)
                if emparejados != 2 {
                    ;Log.Error("Línea de configuración no reconocida: " A_LoopReadLine)
                    continue
                }

                clave := resultado[1]
                valor := RTrim(resultado[2], ",") 

                if !this._diccInfo.Has(clave) {
                    ;Log.Error("Clave de configuración no reconocida: " clave)
                    continue
                }

                if !this._diccInfo[clave].validar(valor) {
                    ;Log.Error("Valor de configuración no válido para la clave " clave ": " this._diccInfo[clave].validar.Mensaje)
                    continue
                }
                
                ; Aqui hay que evaluar el valor para convertirlo al tipo que corresponda
                valores[clave] := valor                
            }

            return valores
        }


        static inicializar() {
            for nivel, ruta in this.NIVEL_RUTA
                if FileExist(ruta) != "" {
                    try
                        this._diccNivelValores[nivel] := this.LeerArchivo(ruta)
                    catch as e
                        ;Log.Error("Error al leer el archivo de configuración de " nivel ": " e.Message)
                }
                else
                    ; Log.Error("No se ha encontrado el archivo de configuración de " nivel ": " ruta)

            for clave in this._diccInfo {
                valores := Util_MapOrden((pr1, pr2) => pr1 > pr2)

                for nivel, valoresNivel in this._diccNivelValores
                    if valoresNivel.Has(clave)                 
                        valores[this.NIVEL_PRIORIDAD[nivel]] := valoresNivel[clave]

                try
                    this._arbolValores[clave] := valores
                catch as e
                    ;Log.Error("Error al cargar en el árbol los valores de configuración de la clave " clave ": " e.Message)
            }
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
