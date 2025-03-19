/*
    Esto debería estar más adelante en el servidor central. Es allí donde debe conectarse el usuario iniciando la sesión, y en este módulo simplemente se obtiene el id de la sesión necesario para registrar las acciones. La lista de usuarios posibles y de sesiones debe estar en la bbdd central. Temporalmente se guardará todo eso en un archivo local para este módulo. Cuando se cree el módulo central se meterán esos datos en una bbdd
*/

#Include error.ahk

/*
    @class Usuarios

    @description Clase que se encarga de gestionar los usuarios.
*/
class Usuarios {
    static __New() {
        this._RUTA := "ruta/usuarios.csv"
        this.LISTA := Map()
    }

    /*
        @static CargarUsuarios

        @description Carga los usuarios desde el archivo de usuarios.
    */
    static CargarUsuarios() {
        indiceCorrecto := Map(1, 4, 2, 1, 3, 2, 4, 3) ; Mapear la posición en la línea con el índice en los argumentos.

        Loop read Usuarios._RUTA {
            datosUsuario := []
            datosUsuario.Capacity := indiceCorrecto.Length

            Loop parse A_LoopReadLine, "," 
                datosUsuario[indiceCorrecto[A_Index]] := A_LoopField

            usuario := Usuario.__New(datosUsuario*)
            Usuarios.LISTA[usuario._id] := usuario
        }
    }

    static GuardarUsuarios() {

    }

    static AgregarUsuario(usuario) {

    }
}


/*
    @class Usuario

    @description Clase que representa a un usuario.
*/
class Usuario {
    static __New() {
        this._id := 0
    }

    __New(nombre, apellido, dni, id?) {
        this._id := id ?? ++Usuario._id
        this._nombre := nombre
        this._apellido := apellido
        this._dni := dni
    }
}

class Sesiones {
    static __New() {
        this.RUTA := "sesiones.csv"
    }
}

/*
    @class Sesion

    @description Clase que representa una sesión de un usuario.
*/
class Sesion {
    static __New() {
        this._id := 0
    }

    __New(idUsuario, turno, lugar, horaInicio?, idSesion?) {
        this._id := idSesion ?? ++Sesion._id
        this._turno = turno
        this._lugar = lugar
        this._usuario = idUsuario
        this._horaInicio = horaInicio ?? A_Now        
        this._abierta := true
    }

    /*
        @method Finalizar

        @description Finaliza la sesión marcando la hora de cierre.
    */
    Finalizar(horaFin?) {
        this._horaFin = horaFin ?? A_Now
        this._abierta := false
    }

    Guardar() {
        cadenaSesion := this._id "," this._idUsuario "," this._turno "," this._lugar "," this._horaInicio "," this._horaFin
        try 
            FileAppend(cadenaSesion, Sesiones.RUTA, "UTF-8")
        catch as e
            throw Err_ErrorAHK.CrearErrorAHK("Error al guardar la sesión", , , , , e)
    }
}