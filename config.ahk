#Requires AutoHotkey v2.0

#Include "debug.ahk"

if (!IsSet(__CONFIG_H__)) {
    global __CONFIG_H__ := true

    /*
        @class Config

        @description Clase para gestionar todos los datos de configuración.
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
