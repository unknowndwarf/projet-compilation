grammar Calculette;

@header {
    // On importe la hashmap
    import java.util.HashMap;
}

@members {

    HashMap<String, Integer> memoire = new HashMap<String, Integer>();
    HashMap<String, String> type_variable = new HashMap<String, String>();
    int adr_variable = 0;

    int label = 1;

    private String genere_label() 
    { 
        label ++;
        return Integer.toString(label);
    }
}

calcul returns [ String code ] 
@init{ $code = new String(); } // On initialise $code
@after{ System.out.println($code); } // On affiche le code MVaP stocké dans code
    : (decl { $code += $decl.code; })*
    NEWLINE*
    (instruction { $code += $instruction.code; })*
    { $code += " HALT\n"; }
    
;

finInstruction
    : (NEWLINE | ';')+
;

decl returns [ String code ]
    : TYPE IDENTIFIANT finInstruction 
        {
            type_variable.put($IDENTIFIANT.text, $TYPE.text);
            memoire.put($IDENTIFIANT.text, adr_variable);  
            adr_variable++;
            if ($TYPE.text.equals("int") || $TYPE.text.equals("bool")) { $code = "PUSHI 0\n"; }
            else { $code = "PUSHF 0.0\n"; }
        }

    // Initialisation de la première variable à 0 juste pour lui donner une valeur 
    // IDENTIFIANT.text = valeur de l'identifiant (si int x, identifiant.text = x)
    // hashmap[identifiant]=place sur la pile qu'on lui attribue, place commence par 0 et s'incrémente pour chaque variable
;

exprA returns[String code]
    : '(' a=exprA ')' {$code = $a.code;}
    | a=exprA operateur = ('/' | '*') b=exprA 
        { 
            if ($operateur.text.equals("/")) { $code = $a.code + $b.code + "DIV\n"; }
            else { $code = $a.code + $b.code + "MUL\n"; }
        }
    | a=exprA '+' b=exprA { $code = $a.code + $b.code + "ADD\n"; }
    | a=exprA '-' b=exprA { $code = $a.code + $b.code + "SUB\n"; }
    | '-' a=exprA { $code = $a.code + $a.code + "SUB\n" + $a.code + "SUB\n"; }      
    | ENTIER { $code = "PUSHI " + $ENTIER.text + "\n"; }
    | IDENTIFIANT
        {  if (type_variable.get($IDENTIFIANT.text).equals("int"))
                $code = "PUSHG " + memoire.get($IDENTIFIANT.text) + "\n"; } 
;

exprB returns[String code]
    : a = exprB '->' b = exprB { $code = "PUSHI 1\n" + $a.code + "SUB\n" + $b.code + "ADD\nPUSHI 0\nNEQ\n"; } // a -> b c'est (non a) ou b 
    |  '(' a=exprB ')' { $code = $a.code; }
    | 'not' a=exprB { $code = "PUSHI 1\n" + $a.code + "SUB\n"; }
    | a=exprB 'and' b=exprB { $code = $a.code + $b.code + "MUL\n"; }
    | a=exprB 'or' b=exprB { $code = $a.code + $b.code + "ADD\nPUSHI 0\nNEQ\n"; }
    | c=exprA '<' d=exprA { $code = $c.code + $d.code + "INF\n"; }
    | c=exprA '<=' d=exprA { $code = $c.code + $d.code + "INFEQ\n"; }
    | c=exprA '==' d=exprA { $code = $c.code + $d.code + "EQUAL\n"; }
    | c=exprA '>' d=exprA { $code = $c.code + $d.code + "SUP\n"; }
    | c=exprA '>=' d=exprA { $code = $c.code + $d.code + "SUPEQ\n"; }
    | c=exprA '<>' d=exprA { $code = $c.code + $d.code + "NEQ\n"; }
    | 'true' { $code = "PUSHI 1\n"; }
    | 'false' {$code = "PUSHI 0\n"; }
    | BOOL {$code = $BOOL.text; }
    | IDENTIFIANT
        {  if (type_variable.get($IDENTIFIANT.text).equals("bool"))
                $code = "PUSHG " + memoire.get($IDENTIFIANT.text) + "\n"; }                    
;

exprF returns[String code] // Un float doit être écrit avec un point 
    : '(' a=exprF ')' {$code = $a.code;}
    | a=exprF operateur = ('/' | '*') b=exprF 
        { 
            if ($operateur.text.equals("/")) { $code = $a.code + $b.code + "FDIV\n"; }
            else { $code = $a.code + $b.code + "FMUL\n"; }
        }
    | a=exprF '+' b=exprF {$code = $a.code + $b.code + "FADD\n"; }
    | a=exprF '-' b=exprF {$code = $a.code + $b.code + "FSUB\n" ;}
    | '-' a=exprF {$code = $a.code + $a.code + "FSUB\n" + $a.code + "FSUB\n" ;}      
    | FLOAT {$code = "PUSHF " + $FLOAT.text + "\n" ;}  
    | IDENTIFIANT
        {  if (type_variable.get($IDENTIFIANT.text).equals("float"))
                $code = "PUSHG " + memoire.get($IDENTIFIANT.text) + "\n"; } 
;


expression returns [ String code ]
    : exprA { $code = $exprA.code; }
    | exprB { $code = $exprB.code; }
    | exprF {$code = $exprF.code;}
;

instruction returns [ String code ]
    : expression finInstruction
        {
            $code = $expression.code + "POP\n";
        }
    | assignation finInstruction { $code = $assignation.code; }
    | finInstruction
        {
            $code="";
        }
    | afficher { $code = $afficher.code; }
    | lire { $code = $lire.code; }
    | bloc { $code = $bloc.code; }
    | struct_if_else { $code = $struct_if_else.code; }
    | struct_if { $code = $struct_if.code; }
    | struct_repeter_tant_que { $code = $struct_repeter_tant_que.code;}
;

assignation returns [ String code ]
    : IDENTIFIANT '=' expression
        {
            $code = $expression.code + "STOREG " + memoire.get($IDENTIFIANT.text) + "\n"; 
        } // Ici on range la valeur à l'adresse dans le hashmap
    | IDENTIFIANT operateur=('+' | '-' | '*' | '/') expression 
        {
            $code = "PUSHG" + memoire.get($IDENTIFIANT.text) + "\n";
            $code += $expression.code + $operateur.getText() + "\n" + "STOREG " + memoire.get($IDENTIFIANT.text) + "\n";
        }
;

lire returns [ String code ]
    : 'lire' '('IDENTIFIANT')' 
        { $code = "READ\n" + "STOREG " + memoire.get($IDENTIFIANT.text) + "\n"; }
;

afficherA returns [ String code ]
    : 'afficher' '(' exprA ')' { $code = $exprA.code + "WRITE\nPOP\n"; }
;

afficherB returns [ String code ]
    : 'afficher' '(' exprB ')' { $code = $exprB.code + "WRITE\nPOP\n"; }
; 

afficher_float returns [ String code ]
    : 'afficher' '(' exprF ')' { $code = $exprF.code + "WRITEF\nPOP\n"; }
;

afficher returns [ String code ]
    : afficherA { $code = $afficherA.code; }
    | afficherB { $code = $afficherB.code; }
    | afficher_float { $code = $afficher_float.code; }
;

bloc returns [ String code ]
    @init {$code = new String();}
    : '{' NEWLINE? (instruction { $code += $instruction.code; })* NEWLINE? '}'
;

struct_repeter_tant_que returns [ String code ] 
    : 'repeter' instruction NEWLINE?
      'tantque' '(' exprB ')' NEWLINE?
    {
        String label_boucle = genere_label();
        String label_sortie = genere_label();
        $code = $instruction.code + "\n";
        $code += "LABEL " + label_boucle + "\n";
        $code += $exprB.code + "JUMPF " + label_sortie + "\n";
        $code += $instruction.code;
        $code += "JUMP " + label_boucle + "\n";
        $code += "LABEL " + label_sortie + "\n";
    }
;

struct_if_else returns [ String code ]
    : 'si' '(' exprB ')' NEWLINE? a = instruction NEWLINE?
      'sinon' NEWLINE? b = instruction 
        {
            String label_else = genere_label(); // On créer nos "checkpoints" avec les labels
            String label_sortie = genere_label();
            $code = $exprB.code + "JUMPF " + label_else + "\n"; //Si condition fausse, ça jump vers le else, sinon il continue
            $code += $a.code + "JUMP " + label_sortie + "\n"; // Ici il fait l'instruction du if et jump en dehors du if else
            $code += "LABEL " + label_else + "\n"; // Créer un LABEL vers le else
            $code += $b.code; // Réalise l'instruction du else
            $code += "JUMP " + label_sortie + "\n"; // Ici on jump en dehors du if else
            $code += "LABEL " + label_sortie + "\n"; // Déclaration du LABEL de sortie du if else
        }
;

struct_if returns [ String code ]
    : 'si' '(' exprB ')' NEWLINE? instruction NEWLINE?
        { 
            String label_sortie = genere_label();
            $code = $exprB.code + "JUMPF " + label_sortie + "\n";
            $code += $instruction.code;
            $code += "JUMP " + label_sortie + "\n";
            $code += "LABEL " + label_sortie + "\n";
        }
;

// Nous n'avons pas réussi à réaliser l'exposant. 

// lexer
NEWLINE : '\r'? '\n';
ENTIER : ('0'..'9')+;
BOOL : ('true'|'false');
FLOAT : ('0'..'9')+ '.' ('0'..'9')*;
TYPE : 'int' | 'float' | 'bool'; // pour pouvoir gérer des entiers, Booléens et floats
IDENTIFIANT : ('a'..'z' | 'A'..'Z' | '_') ('a'..'z' | 'A'..'Z' | '_' | '0'..'9')*;
WS : (' ' | '\t')+ -> skip;
UNMATCH : . -> skip;