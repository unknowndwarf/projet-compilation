grammar Calculette;

@header {
    // On importe la hashmap
    import java.util.HashMap;
}

@members {
    // variables et fonctions globales
    HashMap<String, Integer> memoire = new HashMap<String, Integer>();
    int adr_variable = 0;
}

calcul returns [ String code ] //start
@init{ $code = new String(); } // On initialise $code, pour ensuite l'utiliser comme accumulateur
@after{ System.out.println($code); } // on affiche le code MVaP stocké dans code
    : (decl { $code += $decl.code; })*
    NEWLINE*
    (instruction { $code += $instruction.code; })*
    { $code += " HALT\n"; }
    EOF 
;

finInstruction
    : (NEWLINE | ';')+
;

decl returns [ String code ]
    : TYPE IDENTIFIANT finInstruction 
        {
            memoire.put(IDENTIFIANT.text, adr_variable);  
            adr_variable++;
            $code = "PUSHI 0\n";
        }

    // Initialisation de la première variable à 0 juste pour lui donner une valeur 
    // IDENTIFIANT.text = valeur de l'identifiant (si int x, identifiant.text = x)
    // hashmap[identifiant]=place sur la pile qu'on lui attribue, place commence par 0 et s'incrémente pour chaque variable
;

exprA returns[String code]
    : '(' a=exprA ')' {$code = $a.code;}
    | a=exprA '/' b=exprA {$code = $a.code + $b.code + "DIV\n" ;}
    | a=exprA '*' b=exprA {$code = $a.code + $b.code + "MUL\n" ;}
    | a=exprA '+' b=exprA {$code = $a.code + $b.code + "ADD\n" ;}
    | a=exprA '-' b=exprA {$code = $a.code + $b.code + "SUB\n" ;}
    | '-' a=exprA {$code = $a.code + $a.code + "SUB\n" + $a.code + "SUB\n" ;}      
    | ENTIER {$code = "PUSHI " + $ENTIER.text + "\n" ;}   
;

exprB returns[String code]
    : a = exprB '->' b = exprB {$code = "PUSHI 1\n" + $a.code + "SUB\n" + $b.code + "ADD\nPUSHI 0\nNEQ\n" ;} // a -> b c'est (non a) ou b 
    |  '(' a=exprB ')' {$code = $a.code;}
    | 'not' a=exprB {$code = "PUSHI 1\n" + $a.code + "SUB\n" ;}
    | a=exprB 'and' b=exprB {$code = $a.code + $b.code + "MUL\n" ;}
    | a=exprB 'or' b=exprB {$code = $a.code + $b.code + "ADD\nPUSHI 0\nNEQ\n" ;}
    | c=exprA '<' d=exprA {$code = $c.code + $d.code + "INF\n" ;}
    | c=exprA '<=' d=exprA {$code = $c.code + $d.code + "INFEQ\n" ;}
    | c=exprA '==' d=exprA {$code = $c.code + $d.code + "EQUAL\n" ;}
    | 'true' {$code = "PUSHI 1\n" ;}
    | 'false' {$code = "PUSHI 0\n" ;}
    | BOOL {$code = $BOOL.text ;}                     
;

exprF returns[String code]
    : '(' a=exprA ')' {$code = $a.code;}
    | a=exprA '/' b=exprA {$code = $a.code + $b.code + "DIV\n" ;}
    | a=exprA '*' b=exprA {$code = $a.code + $b.code + "MUL\n" ;}
    | a=exprA '+' b=exprA {$code = $a.code + $b.code + "ADD\n" ;}
    | a=exprA '-' b=exprA {$code = $a.code + $b.code + "SUB\n" ;}
    | '-' a=exprA {$code = $a.code + $a.code + "SUB\n" + $a.code + "SUB\n" ;}      
    | FLOAT {$code = "PUSHI " + $FLOAT.text + "\n" ;}   
;


expression returns [ String code ]
    : exprA finInstruction
    | exprB finInstruction 
    | exprF finInstruction
;

instruction returns [ String code ]
    : expression finInstruction
        {
            $code = $expression.code;
        }
    | assignation finInstruction
        {
            $code = $expression.code;
        }
    | finInstruction
        {
            $code="";
        }
;

assignation returns [ String code ]
    : IDENTIFIANT '=' expression
        {
            $code = $expression.code;
            $code += "STOREG " + memoire.get(IDENTIFIANT.text) + "\n"; 
        } // Ici on range la valeur à l'adresse dans le hashmap
    | IDENTIFIANT operateur=('+' | '-' | '*' | '/') expression 
        {
            $code = "PUSHG" + memoire.get(IDENTIFIANT.text) + "\n";
            $code += expression.code + $operateur.getText() + "\n" + STOREG " + memoire.get(IDENTIFIANT.text) + "\n";
        }
;


// lexer
NEWLINE : '\r'? '\n';
TYPE : 'int' | 'float' | 'bool'; // pour pouvoir gérer des entiers, Booléens et floats
IDENTIFIANT : '([a-z][A-Z])+ ([a-z][A-Z][0-9])*'; //règle pour les limites du nom de variable , nom de variable (IDENTIFIANT) : ça commence obligatoirement par une lettre (majuscule ou minuscule)
                // et après, tu peux avoir des lettres ou des chiffres => x12e
ENTIER : ('0'..'9')+;
BOOL : ('true'|'false');
FLOAT : ('0'..'9')+ '.' ('0'..'9')* | '.' ('0'..'9')+ | ('0'..'9');