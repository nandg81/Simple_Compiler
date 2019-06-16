%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

void yyerror(char *s);


void installid(char s[],int n);
int getid(char s[]);
void dis();
int relop(int a, int b, int c);
int neww,i;
char reg[7][10]={"t1","t2","t3","t4","t5","t6"};

extern FILE *yyout;
extern char *yylex();

struct table{
char name[10];
int val;
}symbol[53];
%}

%union{
int no;
char var[10];
}


%token <var> id
%token <no> num 
%token print EXIT IF ENDIF ELSE WHILE DO FOR RANGE IN ptable
%type <no>  start exp assignment term condn wloop dloop floop
%start start
%left and or 
%left '>' '<' eq ne ge le 
%left '+' '-' '%'
%left '*' '/'

%%


start	: EXIT ';'		{exit(0);}
	| print exp ';'		{ printf("Printing: %d\n",$2); fprintf(yyout,"%s := %d;\nprint %s;\n\n",reg[0],$2,reg[0]); }
	| print '"' id '"' ';'		{ printf("Printing: %s\n",$3); fprintf(yyout,"%s := %s;\nprint %s;\n\n",reg[0],$3,reg[0]); }
	| print '"' num '"' ';'		{ printf("Printing: %d\n",$3); fprintf(yyout,"%s := %d;\nprint %s;\n\n",reg[0],$3,reg[0]); }
	| assignment ';'		{;}
	| wloop		{;}
	| start wloop	{;}
	| una';'		{;}
	| start una';'	{;}
	| dloop		{;}
	| start dloop	{;}
	| floop		{;}
	| start floop	{;}
	| cexp		{;}
	| start cexp	{;}			
	| start print exp ';'  { {printf("Printing: %d \n",$3);} fprintf(yyout,"%s := %d;\nprint %s;\n\n",reg[0],$3,reg[0]); ; }
	| start print '"' id '"' ';'		{ printf("Printing: %s\n",$4); fprintf(yyout,"%s := %s;\nprint %s;\n\n",reg[0],$4,reg[0]); }
	| start print '"' num '"' ';'		{ printf("Printing: %d\n",$4); fprintf(yyout,"%s := %d;\nprint %s;\n\n",reg[0],$4,reg[0]); }	
	| start assignment ';'	{;}
	| start EXIT ';'	{exit(EXIT_SUCCESS);}
	| ptable ';' 		{ dis();}
	|start ptable ';'	{ dis();}
	| condn			{;}
	|start condn		{;}
        ;

		
assignment : id '=' exp  { {installid($1,$3);} fprintf(yyout,"%s := %d;\n %s := %s;\n\n",reg[0],$3,$1,reg[0]); ; }
			;
 condn	: IF '(' exp ')' '{' id '=' exp ';' '}' ELSE '{' id '=' exp ';''}' 	{ if($3>0){installid($6,$8);}else{installid($13,$15);} 
	fprintf(yyout,"%s := %d;\nif (!%s) goto _LABEL;\n%s := %d;\n%s := %s;\n_LABEL : else;\n%s := %d;\n%s := %s;\n\n",reg[0],$3,reg[0],reg[1],$8,$6,reg[1],reg[2],$15,$13,reg[2]); ;}
	| IF '(' exp ')' '{' id '=' exp ';' '}' ENDIF 				{ if($3>0){installid($6,$8);} 
fprintf(yyout,"%s := %d;\nif (%s);\n%s := %d;\n%s := %s;\n\n",reg[0],$3,reg[0],reg[1],$8,$6,reg[1]); ;} 

	| IF '(' exp ')' '{' id '=' exp ';' '}' ELSE '{' IF '(' exp ')' '{'id '=' exp ';''}' ELSE '{'id '=' exp ';''}' '}' 	{ if($3>0){installid($6,$8);}else{ if($15>0){installid($18,$20);}else{ installid($25,$27);} } 
fprintf(yyout, "if z %s goto _MAINELSE; \n%s := %d;\n%s := %s;\n\n _MAINELSE : else;\n if z %s goto _LABEL;\n%s := %d;\n%s := %s;\n_LABEL : else;\n%s := %d;\n%s := %s;\n\n;",reg[0],reg[1],$8,$6,reg[1],reg[2],reg[3],$20,$18,reg[3],reg[4],$27,$25,reg[4]); ; }

	| IF '(' exp ')' '{' print exp ';' '}' ELSE '{' print exp ';' '}' 	{ if($3>0){printf("Printing: %d\n",$7);}else{printf("Printing: %d\n",$13);} 
fprintf(yyout,"%s := %d;\nif (!%s) goto _LABEL;\n%s := %d;\nprint %s;\n_LABEL : else;\n%s := %d;\nprint %s;\n\n",reg[0],$3,reg[0],reg[1],$7,reg[1],reg[2],$13,reg[2]);; }

	|IF '(' exp ')' '{' print exp ';' '}' ENDIF 	{if($3>0){printf("Printing: %d\n",$7); }
fprintf(yyout,"%s := %d;\nif (%s); \n%s := %d \nPrint %s\n\n",reg[0],$3,reg[0],reg[1],$7,reg[1]) ; } 

	;

wloop	: WHILE '(' exp le exp ')' '{' print exp ';' id '=' exp '+' exp ';' '}' { neww=$3;while(neww<=$5){printf("Printing: %d\n",neww);neww=neww+$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s <= %d; \nif (%s) goto L2;\ngoto L3;\nL2: print %s;\n%s := %s + %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp ge exp ')' '{' print exp ';' id '=' exp '+' exp ';' '}' { neww=$3;while(neww>=$5){printf("Printing: %d\n",neww);neww=neww+$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s >= %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s + %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp eq exp ')' '{' print exp ';' id '=' exp '+' exp ';' '}' { neww=$3;while(neww==$5){printf("Printing: %d\n",neww);neww=neww+$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s == %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s + %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp ne exp ')' '{' print exp ';' id '=' exp '+' exp ';' '}' { neww=$3;while(neww!=$5){printf("Printing: %d\n",neww);neww=neww+$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s != %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s + %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp '>' exp ')' '{' print exp ';' id '=' exp '+' exp ';' '}' { neww=$3;while(neww>$5){printf("Printing: %d\n",neww);neww=neww+$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s > %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s + %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp '<' exp ')' '{' print exp ';' id '=' exp '-' exp ';' '}' { neww=$3;while(neww<$5){printf("Printing: %d\n",neww);neww=neww-$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s < %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s - %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp le exp ')' '{' print exp ';' id '=' exp '-' exp ';' '}' { neww=$3;while(neww<=$5){printf("Printing: %d\n",neww);neww=neww-$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s <= %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s - %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp ge exp ')' '{' print exp ';' id '=' exp '-' exp ';' '}' { neww=$3;while(neww>=$5){printf("Printing: %d\n",neww);neww=neww-$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s >= %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s - %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp eq exp ')' '{' print exp ';' id '=' exp '-' exp ';' '}' { neww=$3;while(neww==$5){printf("Printing: %d\n",neww);neww=neww-$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s == %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s - %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} |
	WHILE '(' exp ne exp ')' '{' print exp ';' id '=' exp '-' exp ';' '}' { neww=$3;while(neww!=$5){printf("Printing: %d\n",neww);neww=neww-$15; }installid($11,neww);
fprintf(yyout,"L1: %s = %s != %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s - %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]); } |
	WHILE '(' exp '>' exp ')' '{' print exp ';' id '=' exp '-' exp ';' '}' { neww=$3;while(neww>$5){printf("Printing: %d\n",neww);neww=neww-$15; }installid($11,neww);
fprintf(yyout,"L1: %s = %s > %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s - %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]); } |
	WHILE '(' exp '<' exp ')' '{' print exp ';' id '=' exp '-' exp ';' '}' { neww=$3;while(neww<$5){printf("Printing: %d\n",neww);neww=neww-$15; }installid($11,neww); 
fprintf(yyout,"L1: %s = %s < %d; \nif (%s) goto L2;\ngoto L3;\nL2:print %s;\n%s := %s- %d;\n%s := %s;\ngoto L1;\nL3:\n\n",reg[1],$11,$5,reg[1],reg[0],reg[0],reg[0],$15,$11,reg[0]);} 
;

dloop	: DO '{' print exp ';' id '=' exp '+' exp ';' '}' WHILE '(' exp le exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww+$10; }while(neww<=$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s + %d;\n%s := %s;\n%s = %s <= %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
	DO '{' print exp ';' id '=' exp '+' exp ';' '}' WHILE '(' exp ge exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww+$10; }while(neww>=$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s + %d;\n%s := %s;\n%s = %s >= %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '+' exp ';' '}' WHILE '(' exp eq exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww+$10; }while(neww==$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s + %d;\n%s := %s;\n%s = %s == %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '+' exp ';' '}' WHILE '(' exp ne exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww+$10; }while(neww!=$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s + %d;\n%s := %s;\n%s = %s != %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '+' exp ';' '}' WHILE '(' exp '<' exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww+$10; }while(neww<$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s + %d;\n%s := %s;\n%s = %s < %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '+' exp ';' '}' WHILE '(' exp '>' exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww+$10; }while(neww>$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s + %d;\n%s := %s;\n%s = %s > %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '-' exp ';' '}' WHILE '(' exp le exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww-$10; }while(neww<=$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s - %d;\n%s := %s;\n%s = %s <= %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '-' exp ';' '}' WHILE '(' exp ge exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww-$10; }while(neww>=$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s - %d;\n%s := %s;\n%s = %s >= %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '-' exp ';' '}' WHILE '(' exp eq exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww-$10; }while(neww==$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s - %d;\n%s := %s;\n%s = %s == %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '-' exp ';' '}' WHILE '(' exp ne exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww-$10; }while(neww!=$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s - %d;\n%s := %s;\n%s = %s != %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '-' exp ';' '}' WHILE '(' exp '<' exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww-$10; }while(neww<$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s - %d;\n%s := %s;\n%s = %s < %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} |
DO '{' print exp ';' id '=' exp '-' exp ';' '}' WHILE '(' exp '>' exp ')' ';' { neww=$15;do{printf("Printing: %d\n",neww);neww=neww-$10; }while(neww>$17);installid($6,neww); 
fprintf(yyout,"L1: print %s;\n%s := %s - %d;\n%s := %s;\n%s = %s > %d; \nif (%s) goto L1;\n\n",reg[0],reg[0],reg[0],$10,$6,reg[0],reg[1],$6,$17,reg[1]);} 
;

floop	: FOR '(' id '=' num ';' exp le exp ';' id '=' exp '+' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<=$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s <= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]);} |
FOR '(' id '=' num ';' exp ge exp ';' id '=' exp '+' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>=$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s >= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]);} |
FOR '(' id '=' num ';' exp '<' exp ';' id '=' exp '+' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s < %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]); }|
FOR '(' id '=' num ';' exp '>' exp ';' id '=' exp '+' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s > %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]);} |
FOR '(' id '=' num ';' exp le exp ';' id '=' exp '-' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<=$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s <= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]);} |
FOR '(' id '=' num ';' exp ge exp ';' id '=' exp '-' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>=$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s >= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]);} |
FOR '(' id '=' num ';' exp '<' exp ';' id '=' exp '-' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s < %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]); }|
FOR '(' id '=' num ';' exp '>' exp ';' id '=' exp '-' exp ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s > %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - %d;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$15,$11,reg[0],reg[0]);}|
FOR id IN RANGE '(' exp ')' ':' print id {neww=$6;installid($2,$6);for(i=0;i<neww;i++)printf("Printing: %d\n",i);installid($2,$6);
fprintf(yyout,"%s := 0;\n%s := %s;\nL1: %s := %s < %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$2,reg[0],reg[1],$2,$6,reg[1],reg[0],reg[0],$2,reg[0],$10);}|
FOR id IN RANGE '(' exp ',' exp ')' ':' print id {neww=$8;installid($2,$6);for(i=$6;i<neww;i++)printf("Printing: %d\n",i);installid($2,$8);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s < %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$6,$2,reg[0],reg[1],$2,$8,reg[1],reg[0],reg[0],$2,reg[0],$12);}|
FOR '(' id '=' num ';' exp le exp ';' unap ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<=$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s <= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}|
FOR '(' id '=' num ';' exp ge exp ';' unap ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>=$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s >= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}|
FOR '(' id '=' num ';' exp '<' exp ';' unap ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s < %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}|
FOR '(' id '=' num ';' exp '>' exp ';' unap ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>$9;neww=neww+1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s > %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s + 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}|
FOR '(' id '=' num ';' exp le exp ';' unam ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<=$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s <= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}|
FOR '(' id '=' num ';' exp ge exp ';' unam ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>=$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s >= %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}|
FOR '(' id '=' num ';' exp '<' exp ';' unam ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww<$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s < %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}|
FOR '(' id '=' num ';' exp '>' exp ';' unam ')' '{' print exp ';' '}' {installid($3,$5);for(neww=$5;neww>$9;neww=neww-1){printf("Printing: %d\n",neww);}installid($3,neww);
fprintf(yyout,"%s := %d;\n%s := %s;\nL1: %s := %s > %d;\nif(%s) goto L2;\ngoto L3;\nL4: %s := %s - 1;\n%s := %s;\ngoto L1;\nL2: print %s;\ngoto L4;\nL3: \n\n",reg[0],$5,$3,reg[0],reg[1],$3,$9,reg[1],reg[0],reg[0],$3,reg[0],reg[0]);}
;


cexp	: id '=' exp '?' exp ':' exp ';' {if($3>0){installid($1,$5);printf("%s = %d\n",$1,$5);}else{installid($1,$7);printf("%s = %d\n",$1,$7);}
fprintf(yyout,"%s := %d;\nif(%s) goto L1;\n%s := %d;\n%s := %s;\ngoto L2;\nL1: %s := %d;\n%s := %s;\nL2:\n\n",reg[0],$3,reg[0],reg[1],$7,$1,reg[1],reg[1],$5,$1,reg[1]); };
  
exp    	: term                 { {$$ = $1;} /*fprintf(yyout,"%s := %d;\n ",reg[0],$1);*/ ; } 
       	| exp '+' exp          { {$$ = $1 + $3;} /*fprintf(yyout,"%s := %d + %d;\n ",reg[0],$1,$3);*/ ; } 
       	| exp '-' exp          { {$$ = $1 - $3;} /*fprintf(yyout,"%s := %d - %d;\n ",reg[0],$1,$3);*/ ; }
	| exp '*' exp	       { {$$ = $1 * $3;} /*fprintf(yyout,"%s := %d * %d;\n ",reg[0],$1,$3);*/ ; }
	| exp '/' exp	       { {$$ = $1 / $3;} /*fprintf(yyout,"%s := %d / %d;\n ",reg[0],$1,$3);*/ ; }
	| exp '%'exp		{ {$$= $1 % $3;}}	
	| exp '>' exp		{ {$$ =relop($1,$3,1);} /*fprintf(yyout,"%s := %c > %d;\n ",reg[0],$1,$3); */;} 
	| exp '<' exp		{ {$$ =relop($1,$3,2);} /*fprintf(yyout,"%s := %c < %d;\n ",reg[0],$1,$3); */;}
	| exp eq exp		{ {$$ =relop($1,$3,3);} /*fprintf(yyout,"%s := %c eq %d;\n ",reg[0],$1,$3); */;}
	| exp ne exp		{ {$$ =relop($1,$3,4);} /*fprintf(yyout,"%s := %c neq %d;\n ",reg[0],$1,$3); */;}
	| exp ge exp		{ {$$ =relop($1,$3,5);} /*fprintf(yyout,"%s := %c ge %d;\n ",reg[0],$1,$3); */;}
	| exp le exp		{ {$$ =relop($1,$3,6);} /*fprintf(yyout,"%s := %c le %d;\n ",reg[0],$1,$3); */;}
	| '(' exp ')'		{ {$$ = $2;} /*fprintf(yyout,"%s := %d;\n ",reg[0],$2); */;}
	| exp and exp		{ {$$ =relop($1,$3,7);} /*fprintf(yyout,"%s := %c and %d;\n ",reg[0],$1,$3);*/ ;}
	| exp or exp		{ {$$ =relop($1,$3,8);} /*fprintf(yyout,"%s := %c or %d;\n ",reg[0],$1,$3);*/ ;}
	;

una	: unap|unam	;

unap	: id '+' '+' 	{installid($1,getid($1)+1);/*printf("%s = %d\n",$1,getid($1));*/fprintf(yyout,"%s := %s;\n%s := %s + 1;\n %s := %s\n\n",reg[0],$1,reg[0],reg[0],$1,reg[0]);} |
	  '+' '+' id 	{installid($3,getid($3)+1);/*printf("%s = %d\n",$3,getid($3));*/fprintf(yyout,"%s := %s;\n%s := %s + 1;\n %s := %s\n\n",reg[0],$3,reg[0],reg[0],$3,reg[0]);};

unam	: id '-' '-' 	{installid($1,getid($1)-1);/*printf("%s = %d\n",$1,getid($1));*/fprintf(yyout,"%s := %s;\n%s := %s - 1;\n %s := %s\n\n",reg[0],$1,reg[0],reg[0],$1,reg[0]);} |
	  '-' '-' id 	{installid($3,getid($3)-1);/*printf("%s = %d\n",$3,getid($3));*/fprintf(yyout,"%s := %s;\n%s := %s - 1;\n %s := %s\n\n",reg[0],$3,reg[0],reg[0],$3,reg[0]);};

term   	: num                {$$ = $1;}
	|id			{$$=getid($1);}
;
%%
int relop(int a , int b ,int op)
{
switch(op){
case 1:if(a>b){return 1;} else{return 0;} break;
case 2:if(a<b){return 1;} else{return 0;} break;
case 3:if(a==b){return 1;} else{return 0;} break;
case 4:if(a!=b){return 1;} else{return 0;} break;
case 5:if(a>=b){return 1;} else{return 0;} break;
case 6:if(a<=b){return 1;} else{return 0;} break;
case 7:if(a>0 && b>0 ){return 1;}else{return 0;}break;
case 8:if(a>0 || b>0 ){return 1;}else{return 0;}break;
}
}

void dis()
{
int i;
printf("index\tvar\tval\n");
for(i=0;i<53;i++)
{
 if(symbol[i].val!=-101)
 printf("%d\t%s\t%d\n",i,symbol[i].name,symbol[i].val);
}
}

void installid(char str[],int n){
int index,i;
index=str[0]%53;
i=index;
if(strcmp(str,symbol[i].name)==0||symbol[i].val==-101)
{
symbol[index].val=n;
strcpy(symbol[index].name,str);
}
else
{
i=(i+1)%53;
 	while(i!=index)
	{
		if(strcmp(str,symbol[i].name)==0||symbol[i].val==-101)
		{
			symbol[i].val=n;
			strcpy(symbol[i].name,str);
			break;
		}
	i=(i+1)%53;
	}
}

}


int getid(char str[]){
int index,i;
index=str[0]%53;
i=index;
if(strcmp(str,symbol[index].name)==0)
{
return(symbol[index].val);
}
else
{i=(i+1)%53;
 	while(i!=index)
	{
		if(strcmp(str,symbol[i].name)==0)
		{
			return (symbol[i].val);
			break;
		}
	i=(i+1)%53;
	}
	if(i==index)
	{
		printf("not initialised.");
	}
}

}


void yyerror (char *s) {fprintf (stdout, "%s\n", s);} 

int main()
{

int i;

 for(i=0;i<53;i++)
{
symbol[i].val=-101;
}

yyout = fopen("output.txt","a");
/* if(yyout==NULL)
{
	printf("error!!");
}
else
{
	printf("file opened");
} */

//fprintf(yyout,"%s",reg[0]);
//fprintf("\n%s",ftell(yyout));

 return yyparse();

}
