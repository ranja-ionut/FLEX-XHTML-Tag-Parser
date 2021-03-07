%{
    #include <stdio.h>
    
    /* 
        `indents` reprezinta nivelul de imbricare curent.
        
        Este initializat cu -1 pentru a deveni 0 cand va fi gasit primul tag valid. 
    */
    int indents = -1;
    
    /* 
        `spaces` reprezinta numarul de spatii (' ') care vor prefixa tag-ul curent,
        conform cu valoarea variabilei `indents`.
    */
    int spaces = 0; 
%}

%s START_TAG IN_TAG IN_ATTRIBUTE IN_QUOTE IN_APOSTROPHE CDATA IGNORE
    /* 
        WORD reprezinta un cuvant specific atat pentru tag cat si pentru atribute. 
        Poate contine ':' sau '-' si se poate termina intr-o cifra (<h1>).
    */
WORD [A-Za-z:-]+[0-9]?
    /* TAG reprezinta inceputul unui tag valid. */
TAG <{WORD}
    /* 
        VALUE reprezinta orice de oricate ori, dar fara quotes (") sau apostrophe ('), 
        in functie de ceea ce s-a folosit pentru a delimita valoarea din atribut.
    */
VALUE (\"[^\"]*\")|(\'[^\']*\')
    /* 
        QUOTE reprezinta orice fara (") care se termina in ("). 
    */
QUOTE ([^\"]*\")
    /* 
        APOSTROPHE reprezinta orice fara (') care se termina in ('). 
    */
APOSTROPHE ([^\']*\')
    /* 
        GAT este complementar lui TAG si reprezinta sfarsitul unui tag valid. 
    */
GAT "</"{WORD}[ \n]*>
    /*
        CDATA reprezinta constructia speciala care delimiteaza inceputul unui script. 
    */
CDATA "<![CDATA["
    /*
        ATADC este complementar lui CDATA si reprezinta constructia speciala ce marcheaza sfarsitul script-ului. 
    */
ATADC "]]>"
    /*
        COM reprezinta constructia ce marcheaza inceputul unui comentariu.
    */
COM "<!--"
    /*
        MOC este complentar lui COM si reprezinta sfarsitul comentariului. 
    */
MOC "-->"

%%
    /* Starile initiale care decid ce fel de constructie am intalnit */
<INITIAL>{TAG}      {   /* S-a facut match pe un tag de forma `<tag` */
                        yyless(1);          /* Se scoate < din `<tag` */
                        BEGIN(START_TAG);   /* Se trece in stare START_TAG */
                        indents++;          /* Se incrementeaza numarul de imbricari */
                        unput(' ');         /* Se pune un spatiu (' ') inapoi pe banda */
                    }
<INITIAL>{GAT}      {   /* S-a facut match pe un tag de forma `</tag>` */
                        indents--;          /* Decrementam numarul de imbricari, deoarece am inchis un tag */
                    }
<INITIAL>{CDATA}    {   /* S-a facut match pe constuctia speciala CDATA */
                        BEGIN(CDATA);       /* Se trece in starea CDATA */
                    }
<INITIAL>{COM}      {   /* S-a facut match pe constructia speciala de comentariu */
                        BEGIN(IGNORE);      /* Se trece in starea IGNORE */
                    }
    /* Starile speciale care ignora totul pana intalnesc constructia de intoarcere la starea initiala. */
<IGNORE>{MOC}   {   /* S-a facut match pe constructia speciala ce marcheza sfarsitul unui comentariu */
                    BEGIN(INITIAL);     /* Ne intoarcem in starea initiala */
                }
<CDATA>{ATADC}  {   /* S-a facut match pe constructia speciala ce marcheaza sfarsitul CDATA */
                    BEGIN(INITIAL);     /* Ne intoarcem in starea initiala */
                }
    /* Starile ce marcheaza inceputul unui tag fara partea < din `<tag` */
<START_TAG>" "                  {   /* Am intalnit un spatiu introdus de starea anterioara sau starea curenta */
                                    if (spaces != indents) {    /* daca nu am afisat inca toate spatiile */
                                        ECHO;                   /* afisam inca un spatiu */
                                        unput(' ');             /* introducem inca un spatiu pe banda de intare */
                                        spaces++;               /* crestem numarul de spatii afisate */
                                    }
                                }
<START_TAG>{WORD}/[ \n]*{WORD}  {   /* Am intalnit un tag care are atribute: (tag attribute) = value ... */
                                    ECHO;               /* Afisam tag-ul */
                                    printf(" ::");      /* Afisam string-ul specific "::" */
                                    BEGIN(IN_TAG);      /* Intram in starea IN_TAG */
                                }
<START_TAG>{WORD}/[ \n]*">"     {   /* Am intalnit un tag care nu are atribute: tag > */
                                    ECHO;               /* Afisam tag-ul */
                                    spaces = 0;         /* Resetam numarul de spatii afisate */
                                    BEGIN(INITIAL);     /* Ne intoarcem in starea initiala */
                                    printf("\n");       /* Trecem pe alt rand */
                                }
<START_TAG>{WORD}/[ \n]*"/>"    {   /* Am intalnit un tag fara atribute care s-a inchis singur: tag/> */
                                    ECHO;               /* Afisam tag-ul */
                                    indents--;          /* Decrementam numarul de imbricari */
                                    spaces = 0;         /* Resetam numarul de spatii afisate */
                                    BEGIN(INITIAL);     /* Ne intoarcem in starea initiala */
                                    printf("\n");       /* Trecem pe alt rand */
                                }
    /* Starile ce marcheaza faptul ca ne aflam in interiorul unui tag */
<IN_TAG>{WORD}/[ \n]*"="        {   /* Am gasit atribut: (attribute = ) */
                                    printf(" ");            /* Afisam un spatiu, deoarece inainte am avut fie " ::", fie o valoare */
                                    ECHO;                   /* Afisam atributul */
                                    BEGIN(IN_ATTRIBUTE);    /* Intram in starea IN_ATTRIBUTE */
                                }
<IN_ATTRIBUTE>"="               {   /* Am intalnit separatorul atribut = valoare */ 
                                    printf(" : ");          /* Inlocuim cu " : " constructia "=" */ 
                                }
<IN_ATTRIBUTE>{VALUE}           {   /* Am intalnit o valoare */
                                    /* In functie de ce separator (" sau ') a fost folosit, vom intra in starea corespunzatoare */
                                    BEGIN(yytext[0] == '"' ? IN_QUOTE : IN_APOSTROPHE);
                                    yyless(1);              /* Inlaturam primul separator, adica " din "value" sau ' din 'value' */
                                }
<IN_QUOTE>{QUOTE}               {   /* Separatorul a fost " */
                                    yyless(yyleng - 1);     /* Inlaturam perechea separatorului, adica " din value" */
                                    ECHO;                   /* Afisam valoarea */
                                    printf(" ;");           /* Afisam " ;" dupa ce am terminat cu atributul */
                                    BEGIN(IN_TAG);          /* Ne intoarcem in starea IN_TAG */
                                }
<IN_APOSTROPHE>{APOSTROPHE}     {   /* Separatorul a fost ' */
                                    yyless(yyleng - 1);     /* Inlaturam perechea separatorului, adica ' din value' */
                                    ECHO;                   /* Afisam valoarea */
                                    printf(" ;");           /* Afisam " ;" dupa ce am terminat cu atributul */
                                    BEGIN(IN_TAG);          /* Ne intoarcem in starea IN_TAG */
                                }
<IN_TAG>">"                     {   /* Am ajuns la finalul unui tag ce nu se incheie singur */
                                    spaces = 0;             /* Resetam numarul de spatii afisate */
                                    BEGIN(INITIAL);         /* Ne intoarcem in starea initiala */
                                    printf("\n");           /* Trecem pe alt rand */
                                }
<IN_TAG>"/>"                    {   /* Am ajuns la finalul unuit tag ce se incheie singur */
                                    spaces = 0;             /* Resetam numarul de spatii afisate */
                                    indents--;              /* Decrementam numarul de imbricari */
                                    BEGIN(INITIAL);         /* Ne intoarcem in starea initiala */
                                    printf("\n");           /* Trecem pe alt rand */
                                }
.|\n   { ; } /* Ignora orice nu face parte din starile de mai sus */
%%

int main(int argc, char **argv) {
    /* Verifica daca a fost primit un fisier la intrare. */
    if (argc == 1) {
        printf("[Error] Trebuie specificat numele fisierului de intrare.\n");
        exit(1);
    }

    /* Deschide fisierul pentru a citi din el. */
    yyin = fopen(argv[1], "r");

    /* Afiseaza mesaj de eroare daca nu am putut deschide fisierul. */
    if (!yyin) {
        printf("[Error] Nu se poate deschide fisierul %s.\n", argv[1]);
        exit(2);
    }

    /* Apeleaza analizorul lexical. */
    yylex();
}