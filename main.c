#include <stdio.h>
#include <stdlib.h>
extern int yyparse();
extern char *yytext;
extern 	FILE *yyin;

int main(int argc, char *argv[]){

	if(argc != 2){
		printf("Uso: %s entrada.txt\n", argv[0]);
		exit(1);
	}

	yyin = fopen(argv[1], "r");
	if (yyin == NULL){
		printf("Archivo no se puede abrir %s\n", argv[1]);
		exit(2);
	}

    
    	int res = yyparse();
    	//printf("Resultado: %d\n" ,res);
    	fclose(yyin);
}
