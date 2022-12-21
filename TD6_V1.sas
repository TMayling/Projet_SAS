/*-------------------------------------*/
/*------------ QUESTION 1 -------------*/
/*-------------------------------------*/

/* ---- Création des librairies ----*/

options validvarname=any; /*Evite les erreurs de conversions dans les noms de variables*/

/* Création des librairies */
LIBNAME XL_2017 XLSX '/home/u62478841/TD6/Hospi_2017.xlsx';
LIBNAME XL_2018 XLSX '/home/u62478841/TD6/Hospi_2018.xlsx';
LIBNAME XL_2019 XLSX '/home/u62478841/TD6/Hospi_2019.xlsx';

/*Supprimer les librairies - osef on l'enlevera avant de rendre*/
/*libname XL_2017 clear;
libname XL_2018 clear;
libname XL_2019 clear;*/

/*-------------------------------------*/
/*------------ QUESTION 2 -------------*/
/*-------------------------------------*/

/* ---- Analyse ----*/

/* Chaque fichier est composé de 4 feuilles :
	- Indacteur : Décrit les différents indicateurs du dataset
	- Etablissement : Catégorie de l'établissement et classification des tailles de services
	- Lits et places : variables concernant le nb de lits par services 
	- Activités globales : Autres variables 
*/

/* ---- Problèmes de qualité ----*/
	/*Détection de doublons*/
	
proc sort data=XL_2017."lits et places"n;
	by finess;
run;

proc sort data=XL_2018."lits et places"n;
	by finess;
run;

proc sort data=XL_2019."lits et places"n;
	by finess;
run;

/* Il y a des doublons dans les ID finess car la colonne indicateur contient plusieurs modalités.
On pourrait dépivoter les colonnes "indicateur" et "valeurs" pour avoir une colonne finess
sans doublon. Ce qui faciliterait l'analyse et la jointure entre plusieurs fichiers */

	/* Amélioration du fichier : On va réunir toutes les feuilles en un seul dataset */

/* 2017 */

proc sort data=XL_2017."LITS ET PLACES"n;
by finess;
run;

proc transpose data=XL_2017."LITS ET PLACES"n out=XL_2017."lits_transpose"n (drop = _name_ _label_);
by finess;
var Valeur;
id Indicateur;
run;

DATA XL_2017.data2017; 
  Merge XL_2017."lits_transpose"n XL_2017."Etablissement"n XL_2017."Activité Globale"n;
  BY finess; 
RUN;

data XL_2017.data2017;
set XL_2017.data2017;
year=2017;
run;

/* 2018 */

proc sort data=XL_2018."LITS ET PLACES"n;
by finess;
run;
proc transpose data=XL_2018."LITS ET PLACES"n out=XL_2018.lits_transpose (drop = _name_ _label_);
by finess;
var Valeur;
id Indicateur;
run;
DATA XL_2018.data2018; 
  Merge XL_2018."lits_transpose"n XL_2018."Etablissement"n XL_2018."Activité Globale"n;
  BY finess; 
RUN;
data XL_2018.data2018;
set XL_2018.data2018;
year=2018;
run;


/* 2019 */

proc sort data=XL_2019."LITS ET PLACES"n;
by finess;
run;

proc transpose data=XL_2019."LITS ET PLACES"n out=XL_2019.lits_transpose (drop = _name_ _label_);
by finess;
var Valeur;
id Indicateur;
run;

DATA XL_2019.data2019; 
  Merge XL_2019."lits_transpose"n XL_2019."Etablissement"n XL_2019."Activité Globale"n;
  BY finess; 
RUN;

data XL_2019.data2019;
set XL_2019.data2019;
year=2019;
run;

/*Regroupement des données des 3 années*/
DATA XL_2019.data_global_prep; 
  set XL_2017.data2017 XL_2018.data2018 XL_2019.data2019;
RUN;

	/*Modification des types de données*/
	
* Avoir le type des variables;
proc contents
     data = XL_2019.data_global_prep
          noprint
     out = vars1 (keep = name type);
run; *Toutes les variables sont en varchar (type 2);

proc sql;
     * On créer une liste qui va contenir les noms actuels des colonnes;
     
     select name
     into :numerics
          separated by ' '
     from vars1
     where type = 2
     and name not IN("finess","rs","cat","taille_MCO","taille_M","taille_C","taille_O","Indicateur","RH7","CI_A16_1","CI_A16_2","CI_A16_3","CI_A16_4"); *Variable dont on ne souhaite pas changer le type;

     * On créer une liste qui va contenir les noms actuels des colonnes avec un C en plus pour pouvoir remplacer par leurs noms de base;
     select trim(name) || 'C'
     into :characters
          separated by ' '
     from vars1
     where type = 2
     and name not IN("finess","rs","cat","taille_MCO","taille_M","taille_C","taille_O","Indicateur","RH7","CI_A16_1","CI_A16_2","CI_A16_3","CI_A16_4");
     
     * On créer une liste nom_colonne = nom_colonne_C;
     select cats(name, ' = ' , name, 'C')
     into :conversions
          separated by ' '
     from vars1
     where type = 2
     and name not IN("finess","rs","cat","taille_MCO","taille_M","taille_C","taille_O","Indicateur","RH7","CI_A16_1","CI_A16_2","CI_A16_3","CI_A16_4");
quit;

* On remplace les virgules par des points pour éviter les soucis de conversions;
data XL_2019.data_global;
	 set XL_2019.data_global_prep;
	 
	 array nums[*] &numerics;

     do i = 1 to dim(nums);
          nums[i] = tranwrd(nums[i], ',', '.');
     end;
run;

* Au lieu d'écrire nom_colonne = nom_colonne_C pour toutes les variables, on utilise notre liste créée précédemment;
data XL_2019.data_global;
	 set XL_2019.data_global;
     rename &conversions;
run;

* On change les types;
data XL_2019.data_global;
     set XL_2019.data_global;

     array nums[*] &numerics;
     array chars[*] &characters;

     do i = 1 to dim(nums);
          nums[i] = input(chars[i], BEST32.);
     end;
*On drop les colonnes avant la conversion;
     drop i &characters;
run;

	/*Détection des données manquantes*/

proc means data = XL_2019.data_global n nmiss;
  var _numeric_;
run;

	/*Détection des outliers*/

proc univariate data=XL_2019.data_global robustscale plot;
var CI_A11;
run; 

/*-------------------------------------*/
/*------------ QUESTION 3 -------------*/
/*-------------------------------------*/


PROC TABULATE DATA = XL_2019.data_global ;
   CLASS year finess ;
   TABLE (year),
         (finess)*
         (N) ;
RUN ;

/*Analyse des établissements qui sont apparus : aucun*/
PROC SQL;
SELECT finess
FROM XL_2019.data_global
WHERE year = 2019
AND finess not in(SELECT finess FROM XL_2019.data_global WHERE year = 2017 OR year = 2018);
QUIT;


/*-------------------------------------*/
/*------------ QUESTION 4 -------------*/
/*-------------------------------------*/

/*Est-ce-que des établissements ont changé de taille: aucun*/

PROC SQL;
SELECT finess
FROM XL_2019.data_global
WHERE year = 2019
AND taille_MCO not in(SELECT taille_MCO FROM XL_2019.data_global WHERE year = 2017 OR year = 2018)
AND taille_M not in(SELECT taille_M FROM XL_2019.data_global WHERE year = 2017 OR year = 2018)
AND taille_C not in(SELECT taille_C FROM XL_2019.data_global WHERE year = 2017 OR year = 2018)
AND taille_O not in(SELECT taille_O FROM XL_2019.data_global WHERE year = 2017 OR year = 2018);
QUIT;


/*-------------------------------------*/
/*------------ QUESTION 5 -------------*/
/*-------------------------------------*/


proc sql; 
select taille_M,min(CI_AC1) as min_lits, max(CI_AC1) as max_lits
from XL_2019.data_global
group by taille_M;
quit;



/*-------------------------------------*/
/*------------ QUESTION 6 -------------*/
/*-------------------------------------*/

/*Création d'une nouvelle variable CI_ACTOT*/
data XL_2019.data_global;
set XL_2019.data_global;
CI_ACtot = sum(CI_AC1, CI_AC6, CI_AC8);
run;

/*Tableau croisé*/
PROC TABULATE DATA = XL_2019.data_global;
   class cat year;
   Var CI_AC1 CI_AC6 CI_AC8 CI_ACtot;
   tables cat='',year=''*(CI_AC1='Nb_lits_M'*(sum='') CI_AC6='Nb_lits_C'*(sum='') CI_AC8='Nb_lits_O'*(sum='') CI_ACtot='Total'*(sum=''));
RUN;


/*-------------------------------------*/
/*------------ QUESTION 7 -------------*/
/*-------------------------------------*/

/*Les départements d'outre-mer sont tous regroupés dans "97"*/
/*Dep 98?*/

/*Résultat en Proc SAS*/

data XL_2019.data_global;
set XL_2019.data_global;
dep = substr(finess, 1, 2) ;
run;

PROC TABULATE DATA = XL_2019.data_global;
   class cat dep finess;
   tables dep='',cat=''*N='Nb Etab' N='Total';   /*VERIFIER LES DATA*/
RUN;

/*Résultat en SQL*/

PROC SQL;
select dep,
count(distinct finess) as nb_etab,
cat
from XL_2019.data_global
group by dep, cat;
QUIT;


/*-------------------------------------*/
/*------------ QUESTION 8 -------------*/
/*-------------------------------------*/

PROC SQL;
select CI_E6 as niveau_maternite,
cat,
sum(CI_A11) as nb_accouchement,
sum(CI_AC8) as nb_lits_obstetrique,
min(CI_A11) as min
from XL_2019.data_global;
group by cat, niveau_maternite;
QUIT;

PROC SQL OUTOBS=5;
select finess,
sum(CI_A11) as nb_accouchement,
sum(CI_AC8) as nb_lits_obstetrique
from XL_2019.data_global;
group by finess
order by nb_accouchement desc, nb_lits_obstetrique desc;
QUIT;   /*VERIFS*/

/*-------------------------------------*/
/*------------ QUESTION 9 -------------*/
/*-------------------------------------*/

PROC SQL;
select dep,
sum(CI_A11) as nb_accouchement,
sum(CI_AC8) as nb_lits_obstetrique,
min(CI_A11) as min_nb_accouchement
from XL_2019.data_global
group by dep
order by nb_accouchement desc, nb_lits_obstetrique desc;
QUIT;



/*-------------------------------------*/
/*------------ QUESTION 10 -------------*/
/*-------------------------------------*/





/*-------------------------------------*/
/*------------ QUESTION 11 -------------*/
/*-------------------------------------*/





/*-------------------------------------*/
/*------------ QUESTION 12 -------------*/
/*-------------------------------------*/



		