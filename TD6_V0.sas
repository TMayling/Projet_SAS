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

	/* Amélioration du fichier */
		/*Dépivoter les colonnes Indicateur et Valeur de la feuille Lits et Places*/

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


data XL_2017."data2017"n;
   merge XL_2017."Etablissement"n XL_2017."lits et places t"n XL_2017."Activité Globale"n ;
   by finess;
run;

data XL_2017."data2018"n;
   merge frst_… second_…;
   by x y;
run;

data XL_2017."data2019"n;
   merge frst_… second_…;
   by x y;
run;
		








		/* Concaténation */

data LIB_TD3.cars_global;
   set LIB_TD3.cars_asia LIB_TD3.cars_usa cars_europe1;
run;





	/*Détection des données manquantes*/

	
	/*Détection des outliers*/
	
	


