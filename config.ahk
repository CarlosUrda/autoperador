#Requires AutoHotkey v2.0

#Include "debug.ahk"

if (!IsSet(__CONFIG_H__)) {
    global __CONFIG_H__ := true

    /*
    */
    global logs := Map("GENERAL", ["archivo", "padre"])

    /*
    */
    _IniciarLogs() {
        for grupoLog, datosLog in logs {
            GestionLogs.crearGrupoLog(grupoLog, datosLog)
        }

    global IniciarLogs := _IniciarLogs

    }
}
