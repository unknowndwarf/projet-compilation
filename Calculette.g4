grammar Calculette;
//règles de la grammaire


start
 : expr fin_expression {System.out.println ($expr.code + "WRITE\nPOP\nHALT\n");}
 | exprB fin_expression {System.out.println ($exprB.code + "WRITE\nPOP\nHALT\n");}
;    

expr returns[String code]
    : '(' a=expr ')' {$code = $a.code;}
    | a=expr '/' b=expr {$code = $a.code + $b.code + "DIV\n" ;}
    | a=expr '*' b=expr {$code = $a.code + $b.code + "MUL\n" ;}
    | a=expr '+' b=expr {$code = $a.code + $b.code + "ADD\n" ;}
    | a=expr '-' b=expr {$code = $a.code + $b.code + "SUB\n" ;}
    | '-' a=expr {$code = $a.code + $a.code + "SUB\n" + $a.code + "SUB\n" ;}      
    | ENTIER {$code = "PUSHI " + $ENTIER.text + "\n" ;}   
;

exprB returns[String code]
    : a = exprB '->' b = exprB {$code = "PUSHI 1\n" + $a.code + "SUB\n" + $b.code + "ADD\nPUSHI 0\nNEQ\n" ;} // a -> b c'est (non a) ou b 
    |  '(' a=exprB ')' {$code = $a.code;}
    | 'not' a=exprB {$code = "PUSHI 1\n" + $a.code + "SUB\n" ;}
    | a=exprB 'and' b=exprB {$code = $a.code + $b.code + "MUL\n" ;}
    | a=exprB 'or' b=exprB {$code = $a.code + $b.code + "ADD\nPUSHI 0\nNEQ\n" ;}
    | c=expr '<' d=expr {$code = $c.code + $d.code + "INF\n" ;}
    | c=expr '<=' d=expr {$code = $c.code + $d.code + "INFEQ\n" ;}
    | c=expr '==' d=expr {$code = $c.code + $d.code + "EQUAL\n" ;}
    | 'true' {$code = "PUSHI 1\n" ;}
    | 'false' {$code = "PUSHI 0\n" ;}
    | BOOL {$code = $BOOL.text ;}                     
;

fin_expression
 : EOF | NEWLINE | ';'
;

NEWLINE : '\r'? '\n';
WS : (' '|'\t')+ -> skip;
ENTIER : ('0'..'9')+;
BOOL : ('true'|'false');
UNMATCH : . -> skip;