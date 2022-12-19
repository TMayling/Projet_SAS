/*-------------------------------------*/
/*------------ QUESTION 1 -------------*/
/*-------------------------------------*/

/* ---- Création des librairies ----*/

LIBNAME XL_2017 XLSX '/home/u62478841/TD6/Hospi_2017.xlsx';
LIBNAME XL_2018 XLSX '/home/u62478841/TD6/Hospi_2018.xlsx';
LIBNAME XL_2019 XLSX '/home/u62478841/TD6/Hospi_2019.xlsx';


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

		/*Transpose*/
		
			/*2017*/
PROC TRANSPOSE data=XL_2017."lits et places"n out=XL_2017."lits et places t"n;
  VAR valeur;
  ID indicateur;
  BY finess;
RUN;
			/*2018*/
PROC TRANSPOSE data=XL_2018."lits et places"n out=XL_2018."lits et places t"n;
  VAR valeur;
  ID indicateur;
  BY finess;
RUN;
			/*2019*/
PROC TRANSPOSE data=XL_2019."lits et places"n out=XL_2019."lits et places t"n;
  VAR valeur;
  ID indicateur;
  BY finess;
RUN;

		/*On enlève les colonnes inutiles*/
/*Prendre le code de Quentin qui est plus propre*/	
			/*2017*/
data XL_2017."lits et places t"n;
  set XL_2017."lits et places t"n (drop=_NAME_ _LABEL_:);
run;
			/*2018*/
data XL_2018."lits et places t"n;
  set XL_2018."lits et places t"n (drop=_NAME_ _LABEL_:);
run;
			/*2019*/
data XL_2019."lits et places t"n;
  set XL_2019."lits et places t"n (drop=_NAME_ _LABEL_:);
run;

		/* Jointure entre les feuilles */
		
			/*2017*/
data XL_2017."data2017"n;
   merge XL_2017."Etablissement"n XL_2017."lits et places t"n XL_2017."Activité Globale"n ;
   by finess;
run;
			/*2018*/
data XL_2017."data2018"n;
   merge XL_2018."Etablissement"n XL_2018."lits et places t"n XL_2018."Activité Globale"n ;
   by finess;
run;
			/*2019*/
data XL_2017."data2019"n;
   merge XL_2019."Etablissement"n XL_2019."lits et places t"n XL_2019."Activité Globale"n ;
   by finess;
run;
		
		/* Ajout de l'année à chaque fichier*/
		
			/*2017*/
data xl_2017."data2017"n;
 set xl_2017."data2017"n;
 annee = "2017";
run;
			/*2018*/
data xl_2017."data2018"n;
 set xl_2017."data2018"n;
 annee = "2018";
run;
			/*2019*/
data xl_2017."data2019"n;
 set xl_2017."data2019"n;
 annee = "2019";
run;

		/* Concaténation */

data XL_2017.XL_global;
   set XL_2017."data2017"n XL_2017."data2018"n XL_2017."data2019"n;
run;
			/*On vérifie que toutes les lignes aient été intégrées*/
proc freq data=XL_2017.XL_global;
	TABLES annee;
run;


	/*Modification des types de données*/
	
* Avoir le type des variables;
proc contents
     data = XL_2017.XL_global
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
data XL_2017.XL_global2;
	 set XL_2017.XL_global;
	 
	 array nums[*] &numerics;

     do i = 1 to dim(nums);
          nums[i] = tranwrd(nums[i], ',', '.');
     end;
run;

* Au lieu d'écrire nom_colonne = nom_colonne_C pour toutes les variables, on utilise notre liste créée précédemment;
data XL_2017.XL_global2;
	 set XL_2017.XL_global2;
     rename &conversions;
run;

* On change les types;
data XL_2017.XL_global2;
     set XL_2017.XL_global2;

     array nums[*] &numerics;
     array chars[*] &characters;

     do i = 1 to dim(nums);
          nums[i] = input(chars[i], BEST32.);
     end;
*On drop les colonnes avant la conversion;
     drop i &characters;
run;

	/*Détection des données manquantes*/

proc means data = XL_2017.XL_global2 n nmiss;
  var _numeric_;
run;

	/*Détection des outliers*/

proc univariate data=XL_2017.XL_global2 robustscale plot;
var CI_A11;
run; 

/*-------------------------------------*/
/*------------ QUESTION 3 -------------*/
/*-------------------------------------*/


PROC TABULATE DATA = XL_2017.XL_global2 ;
   CLASS annee finess ;
   TABLE (annee),
         (finess)*
         (N) ;
RUN ;

/*Analyse des établissements qui sont apparus : aucun*/
PROC SQL;
SELECT finess
FROM XL_2017.XL_global2
WHERE annee = 2019
AND finess not in(SELECT finess FROM XL_2017.XL_global2 WHERE annee = 2017 OR annee = 2018);
QUIT;


/*-------------------------------------*/
/*------------ QUESTION 4 -------------*/
/*-------------------------------------*/

/*Est-ce-que des établissements ont changé de taille: aucun*/

PROC SQL;
SELECT finess
FROM XL_2017.XL_global2
WHERE annee = 2019
AND taille_MCO not in(SELECT taille_MCO FROM XL_2017.XL_global2 WHERE annee = 2017 OR annee = 2018)
AND taille_M not in(SELECT taille_M FROM XL_2017.XL_global2 WHERE annee = 2017 OR annee = 2018)
AND taille_C not in(SELECT taille_C FROM XL_2017.XL_global2 WHERE annee = 2017 OR annee = 2018)
AND taille_O not in(SELECT taille_O FROM XL_2017.XL_global2 WHERE annee = 2017 OR annee = 2018);
QUIT;


/*-------------------------------------*/
/*------------ QUESTION 5 -------------*/
/*-------------------------------------*/


proc sql; 
select taille_M,min(CI_AC1) as min_lits, max(CI_AC1) as max_lits
from XL_2017.XL_global2
group by taille_M;
quit;



/*-------------------------------------*/
/*------------ QUESTION 6 -------------*/
/*-------------------------------------*/

/*Code Quentin*/

data XL_2017.XL_global2;
set XL_2017.XL_global2;
CI_ACtot = sum(CI_AC1, CI_AC6, CI_AC8);
run;


PROC TABULATE DATA = XL_2017.XL_global2;;
   class cat annee;
   Var CI_AC1 CI_AC6 CI_AC8 CI_ACtot;
   tables cat='',annee=''*(CI_AC1='Nb_lits_M'*(sum='') CI_AC6='Nb_lits_C'*(sum='') CI_AC8='Nb_lits_O'*(sum='') CI_ACtot='Total'*(sum=''));
RUN;


/*-------------------------------------*/
/*------------ QUESTION 7 -------------*/
/*-------------------------------------*/

/*Les départements d'outre-mer sont tous regroupés dans "97"*/
/*Dep 98?*/

/*Résultat en Proc SAS*/

data XL_2017.XL_global2;
set XL_2017.XL_global2;
dep = substr(finess, 1, 2) ;
run;


PROC TABULATE DATA = XL_2017.XL_global2;
   class cat dep finess;
   tables dep='',cat=''*N='Nb Etab' N='Total';   /*VERIFIER LES DATA*/
RUN;

/*Résultat en SQL*/

PROC SQL;
select substr(finess,1,2) as dep,
count(distinct finess) as nb_etab,
cat
from XL_2017.XL_global2
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
from XL_2017.XL_global2;
group by cat, niveau_maternite;
QUIT;

PROC SQL OUTOBS=5;
select finess,
sum(CI_A11) as nb_accouchement,
sum(CI_AC8) as nb_lits_obstetrique
from XL_2017.XL_global2;
group by finess
order by nb_accouchement desc, nb_lits_obstetrique desc;
QUIT;   /*VERIFS*/

/*-------------------------------------*/
/*------------ QUESTION 9 -------------*/
/*-------------------------------------*/

PROC SQL;
select substr(finess,1,2) as dep,
sum(CI_A11) as nb_accouchement,
min(CI_A11) as min
sum(CI_AC8) as nb_lits_obstetrique
from XL_2017.XL_global2;
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



		