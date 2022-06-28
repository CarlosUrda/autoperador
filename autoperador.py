import psutil
import re
import os
import sys





# EMPEZAR A UNIFICAR TODAS LAS FUNCIONES EN UN PAQUETE UTIL AGRUPANDO LAS 
# FUNCIONES DE FUNCIONALIDAD SIMILAR POR MÓDULOS. Si es posible, crear clases
# que extiendan otras clases, como Object File

def fileReplacePattern(file, pattern, repl, count=0, flags=0):
    """
    Reemplazar una cadena de un archivo usando re.sub sobre el contenido del
    archivo.

    ARGUMENTOS:
        - file: file object donde remplazar la cadena,
        - pattern: cadena a ser reemplazada en el archivo. Puede ser una
        expresión regular.
        - repl: cadena de reemplazo o una función que recibe cada ocurrencia
        de pattern como un objeto re.match y devuelve la cadena a sustituir.
        - count: número de ocurrencias de la cadena a ser reemplazadas. Si es 0
        se reemplazan todas las ocurrencias.
        - flags: modificadores para aplicar en la regex.
    """
    file.seek(0, os.SEEK_SET)
    oldData = file.readall()
    newData = re.sub(pattern, repl, oldData, count, flags)
    file.truncate(0)
    file.write(newData)




FILE_START_PATTERN_INCLUDED = 0b1
FILE_END_PATTERN_INCLUDED = 0b01


def fileGetData(file, startPattern, endPattern, startCount=0, endCount=0, \
        flags=0):
    """
    Obtener una sección de un archivo contenida entre un patrón de origen
    y un patrón de destino.

    ARGUMENTOS:
        - startPattern: patrón de origen (puede ser regex) desde el cual
        obtener los datos.
        - endPattern: patrón final hasta donde obtener los datos.
        - startCount: número de ocurrencia del patrón de inicio desde donde
        obtener los datos.
        - endCount: número de ocurrencia del patrón final hasta donde
        obtener los datos.
        - flags: 
            FILE_START_PATTERN_INCLUDED: Incluir el patrón de inicio en
            los datos obtenidos.
            FILE_END_PATTERN_INCLUDED: Incluir el patrón final en los
            datos obtenidos.
    """
    

# Constantes relacionadas con Textify
FILE_NAME_TEXTIFY_INI = rf"C:\Users\{userDNI}\AppData\Local\Programs\Textify\Textify.ini"
FILE_NAME_TEXTIFY_EXE = rf"C:\Users\{userDNI}\AppData\Local\Programs\Textify\Textify.ini"

class Textify():
    iniFilePath = None
    exeFilePath = None
    MOUSE_CODES = {"right": 0x02, "left": 0x01, "middle": 0x04}
    CODE_MOUSES = dict((reversed(i) for i in Textify.MOUSE_CODES.items()))
    KEY_CODES = {"ctrl": 0x11, "shift": 0x10, "alt": 0x12}
    CODE_KEYS = dict((reversed(i) for i in Textify.KEY_CODES.items()))
    
    @classmethod
    def 

    @classmethod
    def init(cls, iniFilePath, exeFilePath):
        cls.iniFilePath = iniFilePath
    path
    shortcutMouse
    shortcutKeys
    isRunning
    run


def getTextifyShortcut():
    """
    Obtener los atajos de ratón y teclado establecidos en Textify.
    """

def setTextifyShortcut(shortcut):
    """
    Establecer los atajos de ratón y teclado en Textify.

    ARGUMENTOS:
        - shorcut: Lista conteniendo el par (botón de ratón, atajos teclado). 
        Botón puede ser uno solo de los valores: "left", "middle", "right".
        Atajos es lista de uno o varios de los valores: "alt", "ctrl", "shift".
    """

def getTextifyText(x, y, shortcut=None):
    """
    Obtener el texto de la posición x, y en pantalla obtenido a través
    de la aplicación Textify.

    ARGUMENTOS:
        x: coordenada x de pantalla.
        y: coordenada y de pantalla.

    RETORNO:
        Str con el texto obtenido por Textify en esa posición.
    """
    with open(FILE_NAME_TEXTIFY_INI, "r+") as fileTextifyIni:

    if shorcut is None:

    # Comprobar que Textify está ejecutándose.
    # Aplicar el atajo de Textify en la posición indicada.
    # Copiar el texto, salir de Textify
    # Devolver el texto.


# Hacer función genérica de pequeñas tareas.
# Toda pequeña Tarea parte de una posición concreta donde pinchar, que
# dependerá de la comprobación de una imagen dentro de toda la pantalla.
# locateOnScreen() de pyAutoGUI

# Crear imágenes de referencia para distintas resoluciones. La resolución se
# obtiene con pyautogui.size()


# Hay dos tipos de funciones: las básicas o compuestas. Las básicas solo realizan una acción
# y tienen solo los argumentos para realizar esa única acción (P. ej: getTextify)
# Las compuestas tienen como primer grupo de argumentos las funciones (básicas o compuestas)
# que va a realizar junto con los nombres de los argumentos que admiten esas funciones, y 
# como segundo grupo de argumento un diccionario con los valores para los distintos argumentos
# de todas las fnciones que va a ejecutar. Una función compuesta puede pasarse en la lista de 
# argumentos como el resultado de un wrap de la función genérica fijando el primer grupo de 
# argumentos con las tareas ya definidas que va a realizar la función genérica.
# Existe un diccionario global para las funciones complejas donde se define las tareas a
# realizar para cada una. Esas tareas son las c

def multipleTasks( tasks, valueArgs):
    """
    Función genérica para realizar una lista de tareas en orden una detrás de 
    otra.

    ARGUMENTOS:
        - tasks: lista de tareas. Cada argumento pasado es a su vez un 
        indexable donde el primer argumento es la función que realiza la tarea
        y el segundo argumento es una lista de nombres de los argumentos que
        tiene dicha función.
        - tasksValueArgs: diccionario que contiene el valor que se pasará como
        argumento a las tareas a realizar. Las claves/valor son el nombre de
        los argumntos y el valor que se pasará a la función de la tarea para
        ese argumento.
    """


def getParams(file, sep="="):
    """
    Obtener los parámetros y sus valores de un archivo. Debe existir un
    parámetro y su valor por cada línea con el formato param=valor

    ARGUMENTOS:
        - file: archivo con los parámetros y sus valores.
        - sep: separador entre el parámetro y el valor

    RETORNO:
        Diccionario formado por los parámetros y sus valores. Se mantiene el
        caso tal y como está en el archivo, eliminando espacios en blanco al
        inicio y al final de cada parámetro y de cada valor.
    """
    paramsValues = [map(str.strip, line.split(sep, 1)) for line in file]
    return dict(paramsValues)



def main():
    """
    FUnción principal
    """
    FILE_NAME_INI = "autoperador.ini"

    userDNI = sys.argv[1] # Obtener DNI del usuario

    with open(FILE_NAME_INI) as fileIni:
        paramsValues = getParams(fileIni)

    user_fieldparamsValues["user_field"]
    paramsValues["textify_exe_path"].replace(



if __name__ in ("__main__", "__console__"):
    main()
