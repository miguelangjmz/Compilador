%{
	#define _GNU_SOURCE
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include "listaSimbolos.h"
	#include "listaCodigo.h"
	extern int yylex();
	extern int yylineno;
	void yyerror(const char *msg);

	// Contador errores
	extern int c_errores;

	// Lista de símbolos
	Lista l;

	// Tipo de identificadores
	Tipo t;

	// Métodos de símbolos
	void imprimir_simbolos();

	// Contador string
	int c_string = 0;

	// Registros
	char regs[10];
	char * obtenerReg();
	void liberarReg(char * reg);
	void inicializarReg();
	void imprimirLC(ListaC codigo);
	void generar_data();

	// Etiquetas
	int c_etiquetas = 1;
	char *nuevaEtiqueta();

	// Registrar operaciones
	Operacion crearFuncionMIPS(char* op, char* res, char* arg1, char* arg2);
%}

/* Tipo de dato de variables semánticas */
%union{
	int entero;
	char *cadena;
	ListaC codigo;
}

%code requires {
	#include "listaCodigo.h"
}

%token <cadena> IDEN "id"
%token <cadena> ENTE "entero"
%token SUMA "+"
%token REST "-"
%token MULT "*"
%token DIVI "/"
%token IGUA "="
%token PYCO ";"
%token DDOT ":"
%token PARI "("
%token PARD ")"
%token PRIN "print"
%token READ "read"
%token ALLA "{"
%token CLLA "}"
%token PCON "¿"
%token FCON "?"
%token COMA ","
%token <cadena> STRI "string"
%token VARI "var"
%token CONS "const"
%token IFIF "if"
%token ELSE "else"
%token DODO "do" 
%token WHIL "while"
%token FORR "for"
%token ANDD "AND"
%token OROR "OR"
%token NOEQ "><"
%token EQEQ "=="
%token LESS "<"
%token LEEQ "<="
%token MORE ">"
%token MOEQ ">="

/* Para definir tipo datos de los no terminales */
%define parse.error verbose

/* Tipos de dato de no terminales */
%type <codigo> expression statement statement_list condicional
%type <codigo> print_item print_list read_list
%type <codigo> declarations identifier_list identifier

/* Asociatividades y precedencias (se indican a la vez)*/
%left "AND" "OR"
%left "+" "-"
%left "*" "/"
%precedence UMINUS
%precedence NOELSE
%precedence ELSE
%%
  
program : 	{ 
				l = creaLS();
				inicializarReg();
			}
 		"id" "(" ")" "{" declarations statement_list "}" {
			// Última acción
			if(c_errores == 0){
				generar_data();

				concatenaLC($6,$7);
				imprimirLC($6);
				// Liberamos memoria
				liberaLS(l);
				liberaLC($6);
			
			}
		}
		;

declarations : 	declarations "var" { t = VARIABLE; } identifier_list ";" {
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$,$4);
						liberaLC($4);
					} 	
				} 
			| 	declarations "const" { t = CONSTANTE; } identifier_list ";"	{
					if(c_errores == 0){
							$$ = $1;
							concatenaLC($$,$4);
							liberaLC($4);
					} 
				} 
			| 	%empty { 
					if(c_errores == 0){
						$$ = creaLC();
					} 
				}
			;	

identifier_list : 	identifier {
						if(c_errores == 0){
							$$ = $1;
						}
					} 
				| 	identifier_list "," identifier 	{
						if(c_errores == 0){
							$$ = $1;
							concatenaLC($$,$3);
							liberaLC($3);
						} 
					} 
				;

identifier :  	"id"  {
					PosicionLista p = buscaLS(l,$1);
					
					if (p != finalLS(l)) {
						printf("Identificador %s redeclarado. En linea %d\n",$1, yylineno);
						c_errores++;
					}
					else {
						Simbolo aux;
						aux.nombre = $1;
						aux.tipo = t;
						aux.valor = 0;
						insertaLS(l, finalLS(l), aux);
					}
					
					if(c_errores == 0){
						$$ = creaLC();
					} 
				}
			| 	"id" "=" expression 	{
					PosicionLista p = buscaLS(l,$1);
					if (p != finalLS(l)) {
						printf("Identificador %s redeclarado. En linea %d\n",$1, yylineno);
						c_errores++;
					}
					else {
						Simbolo aux;
						aux.nombre = $1;
						aux.tipo = t;
						aux.valor = 0;
						insertaLS(l, finalLS(l), aux);
					}
			
					if(c_errores == 0){
						$$ = $3;
						
						char *variable;
						asprintf(&variable, "_%s", $1);
						Operacion oper = crearFuncionMIPS("sw", recuperaResLC($3), variable, NULL);
						insertaLC($$,finalLC($$), oper);
						liberarReg(oper.res);
					}
				}
			;

statement_list :  	statement_list statement 	{
						if(c_errores == 0){
							$$ = $1;
							concatenaLC($$, $2);
							liberaLC($2);
						}
					}
				| 	%empty 	{
						if(c_errores == 0){
							$$ = creaLC();
						}
					}
				;

statement :   	"id" "=" expression ";" 	{
					PosicionLista p = buscaLS(l,$1);
					if (p != finalLS(l)) {
						Simbolo aux = recuperaLS(l,p);
						
						if (aux.tipo == CONSTANTE){
							printf("Identificador %s asociado a una constante, no se puede redefinir. En la linea %d\n",$1, yylineno);
							c_errores++;
						}
					}
					else {
						printf("Identificador %s no declarado. En la linea %d\n",$1, yylineno);
						c_errores++;
					}

					if(c_errores == 0){
						$$ = $3;
						char *variable;
						asprintf(&variable, "_%s", $1);
						Operacion oper = crearFuncionMIPS("sw", recuperaResLC($3), variable, NULL);
						insertaLC($$, finalLC($$),oper);
						liberarReg(oper.res);
					}
				}
			| 	"{" statement_list "}" 	{
					if(c_errores == 0){
						$$ = $2;
					}
				}
			| 	"if" "(" condicional ")" statement "else" statement { 
					if(c_errores == 0){
						$$ = $3;

						char * registro = recuperaResLC($3);
						char * etiqueta = nuevaEtiqueta();
						Operacion oper = crearFuncionMIPS("beqz", registro, etiqueta, NULL);	
						insertaLC($$, finalLC($$), oper);
						liberarReg(registro);

						concatenaLC($$,$5);

						char * etiqueta2 = nuevaEtiqueta(); 
						oper = crearFuncionMIPS("b", etiqueta2, NULL, NULL);
						insertaLC($$,finalLC($$), oper);
	
						asprintf(&etiqueta, "%s:", etiqueta);
						oper = crearFuncionMIPS("etiq", etiqueta, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);

						concatenaLC($$,$7);

						asprintf(&etiqueta2, "%s:", etiqueta2);
						oper = crearFuncionMIPS("etiq", etiqueta2, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);
					} 
				}
			| 	"if" "(" error ")" statement "else" statement { 
					yyerror("Error al declarar una condición en un if-else.\n");
					
				}
			| 	"if" "(" condicional ")" statement %prec NOELSE { 
					if(c_errores == 0){
						$$ = $3;

						char * registro = recuperaResLC($3);
						char * etiqueta = nuevaEtiqueta();
						Operacion oper = crearFuncionMIPS("beqz", registro, etiqueta, NULL);	
						insertaLC($$, finalLC($$), oper);
						liberarReg(registro);

						concatenaLC($$,$5);

						asprintf(&etiqueta, "%s:", etiqueta);
						oper = crearFuncionMIPS("etiq", etiqueta, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);
					} 
				}
			| 	"if" "(" error ")" statement %prec NOELSE { 
					yyerror("Error al declarar una condición en un if.\n");
				}
			| 	"while" "(" condicional ")" statement { 
					if(c_errores == 0){
						$$ = creaLC();
						
						char * etiqueta = nuevaEtiqueta();
						char * etiqueta2 = nuevaEtiqueta();

						char *aux_etiqueta;
						asprintf(&aux_etiqueta, "%s:", etiqueta);
						Operacion oper = crearFuncionMIPS("etiq", aux_etiqueta, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);

						concatenaLC($$, $3);
						char * registro = recuperaResLC($3);
						
						oper = crearFuncionMIPS("beqz", registro, etiqueta2, NULL);
						insertaLC($$, finalLC($$), oper);
						liberarReg(registro);

						concatenaLC($$,$5);

						oper = crearFuncionMIPS("b", etiqueta, NULL, NULL);
						insertaLC($$, finalLC($$), oper);

						asprintf(&etiqueta2, "%s:", etiqueta2);
						oper = crearFuncionMIPS("etiq", etiqueta2, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);

						liberaLC($3);
						liberaLC($5);
					} 
				}
			| 	"while" "(" error ")" statement { 
				yyerror("Error al declarar una condición en un while.\n");
				}
			| 	"do"  statement  "while" "(" condicional ")"  ";" {
					if(c_errores == 0){
						$$ = creaLC();
												
						char * etiqueta = nuevaEtiqueta();
						char *aux_etiqueta;
						asprintf(&aux_etiqueta, "%s:", etiqueta);
						Operacion oper = crearFuncionMIPS("etiq",aux_etiqueta, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);

						concatenaLC($$, $2);
						
						concatenaLC($$, $5);

						char * registro = recuperaResLC($5);
						

						oper = crearFuncionMIPS("bnez",registro, etiqueta, NULL);
						insertaLC($$, finalLC($$), oper);

						liberarReg(registro);
						liberaLC($2);
						liberaLC($5);
					}
				} 
			| 	"do"  statement  "while" "(" error ")"  ";" {	
					yyerror("Error al declarar una condición en un do-while.\n");
				}	
			|	"for" "(" "id" ":" expression ":" condicional ":" "entero" ")" statement {
				// Validamos que el id esta declarado 
				PosicionLista p = buscaLS(l,$3);
					if (p == finalLS(l)) {
						printf("Error en la linea %d. El identificador de control usado en el bucle for debe estar declarado previamente\n", yylineno);
						c_errores++;
						
					}

					if(c_errores == 0){

						$$ = $5;

						char * identificador;	//Cargamos en un registro id
						asprintf(&identificador, "_%s", $3);
						
						char * registro_min = recuperaResLC($5); // Recuperamos el valor min

						Operacion oper = crearFuncionMIPS("sw", registro_min , identificador, NULL); //Lo guardamos por si lo usa el statement
						insertaLC($$, finalLC($$), oper);
						liberarReg(registro_min);

						char * etiqueta_entrada = nuevaEtiqueta(); // Anadimos etiqueta
						char * aux_etiqueta_entrada;
						asprintf(&aux_etiqueta_entrada, "%s:", etiqueta_entrada);
						oper =  crearFuncionMIPS("etiq", aux_etiqueta_entrada, NULL, NULL);
						insertaLC($$, finalLC($$), oper);

						concatenaLC($$,$11); // Anadimos el statement

						oper = crearFuncionMIPS("lw", obtenerReg(), identificador, NULL);
						insertaLC($$, finalLC($$), oper);

						oper = crearFuncionMIPS("add", oper.res, oper.res, $9);
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.res);

						oper = crearFuncionMIPS("sw",oper.res, identificador, NULL); // Lo guardamos por si lo usa el statement
						insertaLC($$, finalLC($$), oper);
						
						concatenaLC($$,$7);
					
						char * registro_cond = recuperaResLC($7);

						oper = crearFuncionMIPS("bnez", registro_cond, etiqueta_entrada, NULL);
						insertaLC($$, finalLC($$), oper);
					} 
				}
			|	"for" "(" "id" ":" expression ":" error ":" "entero" ")" statement {
					yyerror("Error al declarar una condición en un for.\n");
				}
			| 	"print" "(" print_list ")" ";" { if ( c_errores == 0 ) $$ = $3; }
			| 	"print" "(" error ")" ";" { yyerror("Error al imprimir.\n"); }
			| 	"read" "(" read_list ")" ";" { if ( c_errores == 0 ) $$ = $3; }
			| 	"read" "(" error ")" ";" { yyerror("Error al leer.\n"); }
			|	error ";" {yyerror("Error al declarar una sentencia\n");}
			;
		
print_list :  	print_item{ if ( c_errores == 0 ) $$ = $1; }
			| 	print_list "," print_item { 
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);
						liberaLC($3);
					} 
				}
			;

print_item :  	expression { 
					if(c_errores == 0){
						$$ = $1;
						Operacion oper = crearFuncionMIPS("li", "$v0", "1", NULL);
						insertaLC($$, finalLC($$), oper);

						oper = crearFuncionMIPS("move", "$a0", recuperaResLC($1), NULL);
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg1);

						oper = crearFuncionMIPS("syscall", NULL, NULL, NULL);
						insertaLC($$, finalLC($$), oper);
					}
				}
			| 	"string" {
					if(c_errores == 0){
						Simbolo aux; 
						aux.nombre = $1;
						aux.tipo = CADENA;
						aux.valor = c_string;
						insertaLS(l, finalLS(l), aux);

						$$ = creaLC();
						Operacion oper = crearFuncionMIPS("li", "$v0", "4", NULL);
						insertaLC($$, finalLC($$), oper);

						char * str;
						asprintf(&str, "$str%d", c_string++);
						oper = crearFuncionMIPS("la", "$a0", str, NULL);
						insertaLC($$, finalLC($$), oper);

						oper = crearFuncionMIPS("syscall", NULL, NULL, NULL);
						insertaLC($$, finalLC($$), oper);
					}
				}
			;

read_list :		"id" {
					PosicionLista p = buscaLS(l,$1);
					if (p != finalLS(l)) {
						
						Simbolo aux = recuperaLS(l,p);
						
						if (aux.tipo == CONSTANTE){
							printf("Identificador %s asociado a una constante, no se puede modificar con 'read'. En la linea %d\n",$1, yylineno);
							c_errores++;
						}
					}
					else {
						printf("Identificador %s no declarado en linea %d\n",$1, yylineno);
						c_errores++;
					}

					if(c_errores == 0){
						$$ = creaLC();
						Operacion oper = crearFuncionMIPS("li", "$v0", "5", NULL);
						insertaLC($$, finalLC($$), oper);

						oper = crearFuncionMIPS("syscall", NULL, NULL, NULL);
						insertaLC($$, finalLC($$), oper);

						char *variable;
						asprintf(&variable, "_%s", $1);
						oper = crearFuncionMIPS("sw", "$v0", variable, NULL);
						insertaLC($$, finalLC($$), oper);
					}	
				}
			| 	read_list "," "id" {
					PosicionLista p = buscaLS(l,$3);
					if (p != finalLS(l)) {
						
						Simbolo aux = recuperaLS(l,p);
						
						if (aux.tipo == CONSTANTE){
							printf("Identificador %s asociado a una constante, no se puede modificar con 'read'. En la linea %d\n",$3, yylineno);
							c_errores++;
						}
					}
					else {
						printf("No se puede leer en el identificador %s, no está declarado. En linea %d\n",$3, yylineno);
						c_errores++;
					}

					$$ = $1;
					
					if(c_errores == 0){
						Operacion oper = crearFuncionMIPS("li", "$v0", "5", NULL);
						insertaLC($$, finalLC($$), oper);

						oper = crearFuncionMIPS("syscall", NULL, NULL, NULL);
						insertaLC($$, finalLC($$), oper);

						char *variable;
						asprintf(&variable, " _%s", $3);
						oper = crearFuncionMIPS("sw", "$v0", variable, NULL);
						insertaLC($$, finalLC($$), oper);
					}				
				}
			;

expression :  	expression "+" expression {
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);
						
						Operacion oper = crearFuncionMIPS("add",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}	
				}
			| 	expression "-" expression {
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("sub",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}	
				}
			| 	expression "*" expression {
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("mul",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}	
				}
			| 	expression "/" expression {
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("div",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}	
				}
			| 	"-" expression %prec UMINUS {
					if(c_errores == 0){
						$$ = $2;

						Operacion oper = crearFuncionMIPS("neg",recuperaResLC($2), recuperaResLC($2), NULL);;
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$, oper.res);
						
					}	
				}
			| 	"(" expression ")" 	{
					if(c_errores == 0){
						$$ = $2;
					} 				
				}
			| 	"id" {
					PosicionLista p = buscaLS(l,$1);
					if (p == finalLS(l)) {
						printf("Identificador %s inexistente. En la linea %d\n",$1, yylineno);
					}

					if(c_errores == 0){
						$$ = creaLC();

						char *variable;
						asprintf(&variable, "_%s", $1);
						Operacion oper = crearFuncionMIPS("lw", obtenerReg(), variable, NULL);
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$, oper.res);	
					}
				}
			| 	"entero" {
					if(c_errores == 0){
						$$ = creaLC();
						Operacion oper = crearFuncionMIPS("li", obtenerReg(), $1, NULL);
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$, oper.res);
					}
				}		
			;
condicional : 	condicional "AND" condicional{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("and",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}
				} 
			| 	condicional "OR" condicional{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("or",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}
				} 
			| 	expression "<" expression{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("slt",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}
				} 
			| 	expression "<=" expression{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("sle",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}
				}
			| 	expression ">" expression{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("sgt",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}
				} 
			| 	expression ">=" expression{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						Operacion oper = crearFuncionMIPS("sge",recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg2);
						liberaLC($3);
						guardaResLC($$, oper.res);
					}
				}
			| 	expression "><" expression{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						char * etiqueta = nuevaEtiqueta();
						char * etiqueta2 = nuevaEtiqueta();

						Operacion oper = crearFuncionMIPS("bne", recuperaResLC($1), recuperaResLC($3), etiqueta);
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg1);
						
						char * registro = obtenerReg();

						oper = crearFuncionMIPS("li", registro, "0", NULL);
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$, oper.res);

						oper = crearFuncionMIPS("b", etiqueta2, NULL, NULL);
						insertaLC($$, finalLC($$), oper);

						asprintf(&etiqueta, "%s:", etiqueta);
						oper = crearFuncionMIPS("etiq",etiqueta, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);

						oper = crearFuncionMIPS("li", registro, "1", NULL);
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$, oper.res);

						asprintf(&etiqueta2, "%s:", etiqueta2);
						oper = crearFuncionMIPS("etiq",etiqueta2, NULL, NULL);
						liberaLC($3);
						liberarReg(registro);
						insertaLC($$, finalLC($$) ,oper);
					}
				} 
			| 	expression "==" expression{
					if(c_errores == 0){
						$$ = $1;
						concatenaLC($$, $3);

						char * etiqueta = nuevaEtiqueta();
						char * etiqueta2 = nuevaEtiqueta();

						Operacion oper = crearFuncionMIPS("beq", recuperaResLC($1), recuperaResLC($3), etiqueta);
						insertaLC($$, finalLC($$), oper);
						liberarReg(oper.arg1);
						
						char * registro = obtenerReg();

						oper = crearFuncionMIPS("li", registro, "0", NULL);
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$, oper.res);

						oper = crearFuncionMIPS("b", etiqueta2, NULL, NULL);
						insertaLC($$, finalLC($$), oper);

						asprintf(&etiqueta, "%s:", etiqueta);
						oper = crearFuncionMIPS("etiq",etiqueta, NULL, NULL);
						insertaLC($$, finalLC($$) ,oper);

						oper = crearFuncionMIPS("li", registro, "1", NULL);
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$, oper.res);

						asprintf(&etiqueta2, "%s:", etiqueta2);
						oper = crearFuncionMIPS("etiq",etiqueta2, NULL, NULL);
						liberaLC($3);
						liberarReg(registro);
						insertaLC($$, finalLC($$) ,oper);
					}
				}
			| 	 expression   {  
					if(c_errores == 0){
						$$ = $1;
					} 				
				}
			| 	"¿" condicional "?" 	{
					if(c_errores == 0){
						$$ = $2;
					} 				
				}	
				
  
%%

void yyerror(const char *msg){
	printf("Error en linea %d: %s\n", yylineno, msg);
	c_errores++;
}

void imprimir_simbolos(){
	PosicionLista p = inicioLS(l);
	while (p != finalLS(l)) {
		Simbolo aux = recuperaLS(l,p);
		char *tipo;
		switch (aux.tipo) {
			case VARIABLE:
				tipo = "variable";
				break;
			case CONSTANTE:
				tipo = "constante";
				break;
			default:
				tipo = "otro";
		}
		printf("%s es %s\n",aux.nombre,tipo);    
		p = siguienteLS(l,p);
	}
}

void generar_data(){
	printf("##############################\n##### Seccion de datos  ######\n##############################\n ");
	printf("	.data\n");
	PosicionLista p = inicioLS(l);
	while(p!=finalLS(l)){
		Simbolo aux = recuperaLS(l, p);
		if(aux.tipo == CADENA){
			printf("$str%d:.asciiz %s\n", aux.valor, aux.nombre);
		} else {
			printf("_%s:.word %d\n", aux.nombre, aux.valor);
		}
		p = siguienteLS(l, p);
	}
}

char * obtenerReg() {
	for(int i = 0; i < 10; i++){
		if(regs[i] == 0){
			char * reg;
			asprintf(&reg,"$t%d",i);
			regs[i] = 1;
			return reg;
		}
	}
	printf("Error: registros agotados\n");
	exit(1);
}

void liberarReg(char * reg) {
	int idx = atoi(&(reg[2]));
	if(idx > 10){
		printf("Error: índice demasiado alto\n");
		exit(1);
	}
	regs[idx] = 0;
}

void inicializarReg() {
	memset(regs, 0, sizeof(regs));
}

void imprimirLC(ListaC codigo1){
	printf("##############################\n##### Seccion de codigo ######\n##############################\n ");
	printf("	.text\n	.globl main\nmain:\n");
	PosicionListaC p = inicioLC(codigo1);
	Operacion oper;
  	while (p != finalLC(codigo1)) {
		oper = recuperaLC(codigo1,p);
		if(!strcmp (oper.op, "etiq")){
			printf("%s", oper.res);
		}
		else{
			printf("	%s",oper.op);
			if (oper.res) printf(" %s",oper.res);
			if (oper.arg1) printf(",%s",oper.arg1);
			if (oper.arg2) printf(",%s",oper.arg2);
		}
		printf("\n");
		p = siguienteLC(codigo1,p);
  	}
	printf("### Final del codigo ###\n");
  	printf("	li $v0,10\n	syscall\n");
}

char* nuevaEtiqueta(){
	char *aux;
	asprintf(&aux, "$l%d", c_etiquetas++);
	return aux;
}

Operacion crearFuncionMIPS(char * op, char * res, char * arg1, char * arg2){ 
	Operacion oper;
	oper.op = op;
	oper.res = res;
	oper.arg1 = arg1;
	oper.arg2 = arg2;
	return oper;
} 