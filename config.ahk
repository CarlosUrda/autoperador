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
        - Pestaña actual o de sesión: es la pestaña con los valores actuales resultantes de todas las capas de configuración. Es decir, el valor mostrado por cada parámetro en esta capa es el que se está aplicando en la aplicación. Cada parámetro tendrá una mini-ventana emergente de info con el valor cargado en memoria por cada una de las capas de configuración. Si se modifica el valor del parámetro en esta ventana, inicialmente solo se modifica para la capa de sesión.

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

        class 
        static NOMBRE_ARCHIVO_CONFIG := "config.ini"
        static _clavesPorSeccion := Map("Seccion", Map("clave"))
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
