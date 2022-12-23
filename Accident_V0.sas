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
