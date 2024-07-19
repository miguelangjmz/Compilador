/* Analizador lexico */
%{
    #include "sintactico.tab.h"
    #include <stdio.h>
    #include <stdlib.h>
    #include <math.h>
    
    #define ERROR_STRING 0
	#define ERROR_ID_LENGTH 1
	#define ERROR_NUM_LENGTH 2
	#define ERROR_INV_CHAR 3
    
    int c_errores = 0;
    int inicio_comentario;
    void error_lexico();
    void error_comentario_sin_cerrar();
%}

/* Macros de ER */
L [a-zA-Z_$]
D [0-9]
ERROR [^a-zA-Z0-9$_,:?¿<>{};+\-*/=() \n\t\r]+

/* Opciones: Para actualizar la variable */
%option yylineno

/* contexto */
%x comentario



%%

["]([^"\n\\]|\\[ntr\\"])*["]	{	
									yylval.cadena = strdup(yytext);
								 	return STRI;
								}
["]([^"\n\\]|\\[ntr\\"])*		{ error_lexico(ERROR_STRING); }

"print"         	{return PRIN;}
"var"         		{return VARI;}
"const"         	{return CONS;}
"if"         		{return IFIF;}
"else"         		{return ELSE;}
"do"				{return DODO;}			
"while"         	{return WHIL;}
"for"				{return FORR;}	 	
"read"         		{return READ;}
"AND"				{return ANDD;}
"OR"				{return OROR;}


{L}({L}|{D})*   	{	
						if(yyleng < 33){
							yylval.cadena = strdup(yytext);
							return IDEN;
						}
						else{
							error_lexico(ERROR_ID_LENGTH);
						}
					}	/* yyleng para saber la longitud */
{D}+            	{
						if(atol(yytext) <= pow (2, 31)){
							yylval.cadena = strdup(yytext);
							return ENTE;
						}
						else{
							error_lexico(ERROR_NUM_LENGTH);
						}
					}	/* long l = atol(char *) */

"+"             	{return SUMA;}
"-"             	{return REST;}
"*"             	{return MULT;}
"/"             	{return DIVI;}
"="             	{return IGUA;}
"><"				{return NOEQ;}
"=="				{return EQEQ;}
"<"					{return LESS;}
"<="				{return LEEQ;}
">"					{return MORE;}
">=" 				{return MOEQ;}
";"             	{return PYCO;}
":" 			 	{return DDOT;}	
[ \n\t\r]+      	{}
"//".*          	{}
"/*"				{	
						BEGIN(comentario);
						inicio_comentario = yylineno;	
					}
<comentario>.|\n	{}
<comentario><<EOF>>	{
						error_comentario_sin_cerrar();
						return 0;
					}	
<comentario>"*/"	{BEGIN(INITIAL);}
"("             	{return PARI;}
")"             	{return PARD;}
"{"					{return ALLA;}
"}"					{return CLLA;}
"¿"					{return PCON;}
"?"					{return FCON;}
","					{return COMA;}

{ERROR}         	{error_lexico(ERROR_INV_CHAR);}
            
%%

void error_comentario_sin_cerrar(){
	printf("Comentario sin cerrar en la linea %d\n", yylineno);
	c_errores++;
}

void error_lexico(int tipo_error){
    printf("Error en linea %d: %s\n", yylineno, yytext);
    c_errores++;
    switch(tipo_error){
    case ERROR_STRING:
    	printf("Cadena de caracteres mal formada\n");
    	break;
    case ERROR_ID_LENGTH:
    	printf("Identificador demasiado largo\n");
    	break;
    case ERROR_NUM_LENGTH:
    	printf("El valor absoluto del entero supera 2^31\n");
    	break;
    case ERROR_INV_CHAR:
    	printf("Caracter invalido\n");
    	break; 
    default:
    	printf("Error desconocido\n");
    }
}

