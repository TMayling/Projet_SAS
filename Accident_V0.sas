/* ---- Création des librairies ----*/

options validvarname=any; /*Evite les erreurs de conversions dans les noms de variables*/

/* Création des librairies */
LIBNAME Projet '/home/u62479205/Projet_Accident';

/*Création des csv*/
proc import out=Projet.carac
    datafile='/home/u62479205/Projet_Accident/carcteristiques-2021.csv'
    dbms=csv
    replace;
    delimiter=";";
    getnames=YES;
run;

proc import out=Projet.lieux
    datafile='/home/u62479205/Projet_Accident/lieux-2021.csv'
    dbms=csv
    replace;
    delimiter=";";
    getnames=YES;
run;

proc import out=Projet.usagers
    datafile='/home/u62479205/Projet_Accident/usagers-2021.csv'
    dbms=csv
    replace;
    delimiter=";";
    getnames=YES;
run;

proc import out=Projet.veh
    datafile='/home/u62479205/Projet_Accident/vehicules-2021.csv'
    dbms=csv
    replace;
    delimiter=";";
    getnames=YES;
run;

/*Première jointure au niveau des accidents*/
	/*Proc sort pour faire les jointures*/
	
PROC SORT data = Projet.carac;
by Num_Acc;
RUN;

PROC SORT data = Projet.lieux;
by Num_Acc;
RUN;

PROC SORT data = Projet.veh;
by Num_Acc id_vehicule;
RUN;

PROC SORT data = Projet.usagers;
by Num_Acc id_vehicule;
RUN;


DATA Projet.data_prep; 
  Merge Projet.carac Projet.lieux Projet.veh;
  BY Num_Acc; 
RUN;

DATA Projet.data_global;
	Merge Projet.data_prep Projet.usagers;
	BY Num_Acc id_vehicule;
RUN;


/*Replace -1 par .*/

data Projet.data_global;
set Projet.data_global;
array Var _CHARACTER_;
            do over Var;
            if Var=-1 then Var=.;
            end;
run ;

/* 1-Stats descriptives */
/* 1.1-Départements avec le plus d'accidents*/
PROC SQL;
SELECT count(distinct Num_acc) as nb_accidents,
dep
from Projet.data_global
group by dep
order by nb_accidents desc;
QUIT;

/* 1.2-Plus d'accidents en agglomération que hors agglomération*/
PROC SQL;
SELECT count(distinct Num_acc) as nb_accidents,
agg
from Projet.data_global
group by agg
order by nb_accidents desc;
QUIT;

/* 1.3-Mois avec le plus d'accidents*/
PROC SQL;
SELECT count(distinct Num_acc) as nb_accidents,
mois
from Projet.data_global
group by mois
order by nb_accidents desc;
QUIT;

/* 1.4-Communes avec le plus d'accidents*/
PROC SQL OUTOBS=10;
SELECT count(distinct Num_acc) as nb_accidents,
com
from Projet.data_global
group by com
order by nb_accidents desc;
QUIT;

/* 1.5-Nombre d'accidents, de véhicules et de victimes recensés*/
PROC SQL;
SELECT count(distinct Num_acc) as nb_accidents,
count(distinct id_vehicule) as nb_vehicules,
count(id_vehicule) as nb_victimes
from Projet.data_global;
QUIT;

/* 1.6-Nombre d'accidents par voiture*/
PROC SQL OUTOBS=10;
SELECT count(distinct Num_acc) as nb_accidents,
catu
from Projet.data_global
group by catu
order by nb_accidents desc;
QUIT;

/*2-Statistiques inférentielles*/
/*2.1-Décomposition des gravités de blessure selon la catégorie de victime (en %)*/
Data Q2_1;
Set Projet.data_global(rename=(Num_acc=Num_acc_old));
Num_acc =  INPUT(Num_acc_old,f8.);
drop Num_acc_old;
RUN;

PROC TABULATE DATA = Q2_1;
   class catu grav;
   Var Num_acc;
   tables catu='Catégorie usager',grav='gravité'*(Num_acc=''*(ROWPCTN=''));
RUN;

