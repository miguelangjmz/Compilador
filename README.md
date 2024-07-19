# Compilador Mini-C
Un pequeño compilador de una versión simplificada de C. ( y está escrito en C xD)
De momento el lenguaje que puede compilar tiene las funciones básicas de condicionales, bucles y print y read.
# Qué necesitas para su funcionamiento
Para ejecutar el compilador con una entrada necesitarás tener instalado el compilador de C, gcc; y los analizadores Flex y Bison. Además, el código ensamblador generado es MIPS por lo que necesitarás algún entorno para ejecutarlo, las opciones que yo uso son "spim" o MARS.
Una vez instalado todo, con el fichero de entrada (al que debes llamar entrada) que contiene el código en lenguaje Mini-C debes seguir los siguientes pasos para compilarlo.
```
make run
spim -f salida.s
```
O, en el caso en el que tengas MARS

```
make run
mars salida.s
```

# Documentación
El fichero "entrada" contiene un pequeño fragmento de cógido Mini-C que se puede compilar. Si me aburro mucho escribiré la documentación para que puedas crear código Mini-C. B)

