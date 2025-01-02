/* 
    Cosas pendientes:
    - No usar números mágicos
    - Factorizar creando funciones.
    - Comprobar todos los posibles errores.

    MEJORAS:
    - Alertas por políticas que fallan: en Sessions cada 15 min actualizar y revisar el estado de las políticas:
        * Si ha finalizado correctamente se graba el peso.
        * Si ha finalizado con errores: saltar alerta
        * Si no ha finalizado se deja pendiente.
    
*/

#Requires AutoHotkey v2.0



CrearExcel(ruta, hoja) {
    xlApp := ComObject("Excel.Application")
    xlApp.Visible := True  ; Opcional: Mostrar Excel para depuración
    xlWorkbook := xlApp.Workbooks.Open(ruta)
    xlSheet := xlWorkbook.Sheets(hoja) 
    return xlSheet
}


CoordMode("Mouse", "Window")  ; Configura coordenadas relativas a la ventana activa

; Activar la ventana de HP Data Protector
ventana := "HP Data Protector Manager"
; Coordenadas relativas para el menú desplegable "Internal Database"
xMenu := 56
yMenu := 60
nombreArchivo := "pesos.txt"
rutaExcel := "\\Salud.madrid.org\jcespeciales\Srv Administracion Sistemas\Explotacion\Actividades Operacion\Utilidades\TablasCopiasBackupCPDExt\Monitorización\DP_CPDExt_23122024_al_29122024.xlsx"

nombreServ := StatusBarGetText(3, WinGetID("A"))
nombreServ := ControlGetText("msctls_statusbar321", "A")
; Envía SB_GETTEXT para obtener el texto de una parte específica de la barra de estado (índice 0, 1, 2, etc.)
nombreServ := SendMessage(0x0400 + 0x0020, 2, 0, "msctls_statusbar321", "A")
MsgBox(nombreServ)
excel := CrearExcel(rutaExcel, 1)

/*
    Gestionar las políticas de un solo servidor conectado en una ventana de DP.

    ARGUMENTOS:
    - idVentana: id de la ventana con la instancia del servidor DP.
    - nombreServidor: nombre del servidor conectado.
    - excel: objeto excel donde ir volcando los datos.
    - nombreLog

*/
GestionarServidor(idVentana, nombreServidor, excel, archivoDatos)
WinActivate(ventana)  ; Asegura que la ventana esté activa
Sleep(500)  ; Pausa para asegurarse de que la ventana esté lista

MouseClick("left", xMenu, yMenu)  
Sleep(300)

; Seleccionar "Devices & Media" para que después se seleccione Internal Database reseteado
Send("{Up 6}")  ; Ajusta este número según la posición de "Internal Database"
Sleep(200)
Send("{Enter}")
Sleep(500)


; Hacer clic en el menú desplegable "Internal Database"
MouseClick("left", xMenu, yMenu)  ; Coordenadas relativas para el menú desplegable
Sleep(300)

; Seleccionar "Internal Database"
Send("{Down 6}")  ; Ajusta este número según la posición de "Internal Database"
Sleep(200)
Send("{Enter}")
Sleep(500)

; Mover el foco al árbol de navegación
Send("{Tab 2}")  ; Mueve el foco al panel izquierdo 
Sleep(300)

ctrlPanelArbol := ControlGetFocus("A")
ControlGetPos(&xPanelArbol, &yPanelArbol, &anchoPanelArbol, &altoPanelArbol, ctrlPanelArbol, WinGetID("A"))
xPestannaGeneral := xPanelArbol + anchoPanelArbol + 50
yPestannaGeneral := yPanelArbol + 38
xPestannaMessages := xPestannaGeneral + 50
yPestannaMessages := yPestannaGeneral

; Asegurarse de que Internal Database no está desplegado
Send("{Left}")
Sleep(300)

; Desplegar Internal Database
Send("{Right}")

; Seleccionar "Sessions"
Send("{Down 2}")  ; Ajusta el número para llegar a "Sessions"
Sleep(300)
Send("{Right}")
Sleep(700)

ctrlPestannas := ""
ctrlGeneral := ""
archivo := FileOpen(nombreArchivo, "w")

; Recorre las sesiones y extrae los datos
Loop 10 {
    ; Seleccionar la siguiente sesión
    Send("{Down}")
    Sleep(200)              

    ; Acceder "Propiedades"
    Send("!{Enter}")
    Sleep(1000)

    ; Hacer clic en pestaña General (Coordenadas relativas)
    MouseClick("left", xPestannaGeneral, yPestannaGeneral, 3)
    Sleep(200)

    ;ctrlPestannas := ControlGetFocus("A")
    Send("{Tab}")
    Sleep(200)
    ctrlGeneral := ControlGetFocus("A")

    /*
    ; NO SÉ POR QUÉ IGNORA COMPLETAMENTE CTRL+TAB!!
    ControlSend("^Tab", ctrlPanelArbol, WinGetID("A"))
    Sleep(2000)
    Send("^Tab")
    Sleep(2000)
    Send("^Tab")
    Sleep(2000)
    */
    listado := ListViewGetContent("", ctrlGeneral, WinGetID("A"))
    if (listado == "") {
        MsgBox("No se pudieron obtener los datos de la pestaña General.")
        Continue
    }

    if !RegExMatch(listado, "Specification\s+([^\r\n]+)", &nombrePolitica) or nombrePolitica.1 == "" {
        MsgBox("No se pudo obtener el nombre de la política")
        Continue
    }

    if !RegExMatch(listado, "Start Time\s+\d{2}/\d{2}/\d{4}\s+(\d{1,2}:\d{2})", &horasMinutos) or horasMinutos.1 == "" {
        MsgBox("No se pudo obtener la hora:minutos de inicio de la política " nombrePolitica.1)
        Continue
    }

    ; Hacer clic en pestaña Messages (Coordenadas relativas)
    MouseClick("left", xPestannaMessages, yPestannaMessages)
    Sleep(200)
    
    A_Clipboard := ""
    ; Copiar el contenido de Messages
    Send("^a")  ; Seleccionar todo
    Sleep(200)
    Send("^c")  ; Copiar al portapapeles
    Sleep(200)

    ClipWait
    ; Extraer "Mbytes Total" del contenido copiado
    if A_Clipboard == "" {
        MsgBox("Error: No se ha podido obtener el contenido de la pestaña Messages de " nombrePolitica.1)
        Continue
    }
    RegExMatch(A_Clipboard, "Mbytes Total\s*[:.]*\s*(\d+)", &mbytes)
    if (!mbytes or mbytes.1 == "") {
        MsgBox("La política " nombrePolitica.1 " no tiene Mbytes total")
        Continue
    }

    archivo.WriteLine(horasMinutos.1 " " nombrePolitica.1 " " mbytes.1)

    ; Volver el foco al panel árbol
    ControlFocus(ctrlPanelArbol, WinGetID("A"))
    Sleep(200)
}

archivo.Close()
MsgBox("Procesamiento completado. Los datos se han guardado en session_data.txt")