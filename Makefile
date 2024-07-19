sintactico : main.c sintactico.tab.c lex.yy.c listaSimbolos.c listaCodigo.c
	gcc -g main.c sintactico.tab.c lex.yy.c listaSimbolos.c listaCodigo.c -lfl -o sintactico
lex.yy.c : lexico.l sintactico.tab.h
	flex lexico.l
sintactico.tab.h sintactico.tab.c : sintactico.y
	bison -d -v sintactico.y 
clear :
	rm -f sintactico.tab.* sintactico lex.yy.c salida.s
run : entrada sintactico
	./sintactico entrada > salida.s
	#spim -f salida.s

run_opcional : entrada sintactico
	./sintactico entrada_opcional > salida.s

err : entrada_errores sintactico
	./sintactico entrada_errores > salida.s


