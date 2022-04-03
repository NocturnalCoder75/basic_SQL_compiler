%{
	#include <iostream>
	#include <string>
	#include <vector>
	#include "../header/node.h"
	extern int yylex();
	int yyerror(const char*);
%}
%union
{
	std::string* string;
	int ival;
	std::vector<std::string*>* string_array;
	col_list* cols;
	col* column;
	reference* refer;
	reference_list* refer_list;
	cond* condition;
}



%token CREATE TABLE CHECK PRIMARY KEY FOREIGN REFERENCES
%token CHAR INT DECIMAL 
%token OPEN_PAR CLOSE_PAR SEMICOLON COMMA 
%token OR AND
%token GE GT LE LT E NE


%token <string> IDENTIFIER;
%token <ival> NUMBER;

%type <string_array> primary_key
%type <string_array> columns
%type <string> column
%type <cols> definitions
%type <column> definition
%type <column> attr_type
%type <refer> foreign_key
%type <refer_list> foreign_keys
%type <condition> expr or_expr and_expr
%type <condition> condition

%start create_stmt

%%


create_stmt:CREATE TABLE IDENTIFIER OPEN_PAR definitions COMMA primary_key COMMA foreign_keys CLOSE_PAR SEMICOLON
		{ // i need to check whether the table exist 
			// if so then the raise an error
			// otherwise i need to create the table
			std::cout<<"table create statement top \n";
			std::cout<<"|";
			for(auto i : *$7)
				std::cout<<i<<"|";
	}
	;

primary_key:PRIMARY KEY OPEN_PAR columns CLOSE_PAR {$$=$4;}
		 ;

foreign_keys:  {$$=nullptr;}
		  | foreign_key { $$=new reference_list;$$->push_back($1); }
		  | foreign_keys COMMA foreign_key { $1->push_back($3); $$=$1;  }
		  ;
foreign_key:FOREIGN KEY OPEN_PAR column CLOSE_PAR REFERENCES IDENTIFIER OPEN_PAR column CLOSE_PAR 
		{ $$=new reference(*$7,*$9,*$4); delete $7; delete $9;delete $4; }
	;


columns:column { $$=new std::vector<std::string*>(); $$->push_back($1); }
	  |columns COMMA column {$1->push_back($3);$$=$1;}
	  ;
column:IDENTIFIER;



definitions:definition { $$=new col_list(); $$->push_back($1); }
		|definitions COMMA definition { $1->push_back($3);$$=$1; }
		;

definition: IDENTIFIER attr_type { $2->column_name=*$1; $$=$2; delete $1; }
		| IDENTIFIER attr_type CHECK expr { $2->column_name=*$1;
			$2->conditions=$4; 
			$$=$2;
			delete $1;
			}
		;
attr_type	:CHAR OPEN_PAR NUMBER CLOSE_PAR { $$=new col(CHAR,$3,""); }
		|INT OPEN_PAR NUMBER CLOSE_PAR { $$=new col(INT,$3,""); } 
		|DECIMAL OPEN_PAR NUMBER CLOSE_PAR { $$=new col(DECIMAL,$3,""); }
		|INT { $$=new col(INT,8,""); }
		|DECIMAL { $$=new col(DECIMAL,8,""); }
		;



	/*start of the expression part */
expr:or_expr  { $$=$1;}
or_expr:and_expr { $$=$1;}
	  | or_expr OR and_expr {  
		$$=new cond(OR,-1,"");
		$$->left=$1;
		$$->right=$3;
		}
		;

and_expr:and_expr AND condition {
		$$=new cond(AND,-1,"");
		$$->left=$1;
		$$->right=$3;
		}
	| condition { $$=$1;}
	;
condition:  IDENTIFIER GE NUMBER { $$=new cond(GE,$3,*$1); delete $1; }
		| IDENTIFIER GT NUMBER { $$=new cond(GT,$3,*$1); delete $1; }
		| IDENTIFIER NE NUMBER { $$=new cond(NE,$3,*$1);	delete $1; }
		| IDENTIFIER LT NUMBER { $$=new cond(LT,$3,*$1);	delete $1; }
		| IDENTIFIER LE NUMBER { $$=new cond(LE,$3,*$1);	delete $1; }
		| IDENTIFIER E NUMBER  { $$=new cond(E,$3,*$1); 	delete $1; }
		| OPEN_PAR expr CLOSE_PAR { $$=$2;}
		;
	/* ending of the expression part */



%%


int yyerror(char const *s)
{
	std::cout<<"[ERROR] : "<<s;
	exit(0);
}


int main()
{
	yyparse();
	return 0;
}


