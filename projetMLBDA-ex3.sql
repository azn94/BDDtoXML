-- CREATION DES TYPES ET TABLES

-- DROP TABLE
drop table LesBorders;
/
drop table LesMontagnes;
/
drop table LesProvinces;
/
drop table lesOrganizations;
/
drop table LesCountries;
/
drop table LesContinents;
/
drop table LesMondials;
/

-- Border
drop type T_Border force;
/

create or replace  type T_Border as object (
   COUNTRY1     VARCHAR2(4 Byte),
   COUNTRY2     VARCHAR2(4 Byte),
   LENGTH       NUMBER,
   BOOLEAN      NUMBER, -- Ajoute pour sa methode toXML afin de savoir lequel des deux pays afficher
   
   -- On a en effet du faire un choix pour modeliser l'element border de la DTD puisque dans la methode toXML de T_Country 
   -- on veut afficher les pays frontaliers. Il ne faut donc pas afficher le pays lui meme mais son pays frontalier. 
   -- Pour ce faire, on introduit une sorte de "booleen" qui definira lequel des deux pays afficher (l'autre etant le pays dont on cherche les voisins). 
   -- Cette donnee aura donc la valeur 1 si le pays 1 est celui dont on veut recuperer les pays frontaliers 
   -- (c'est-a-dire que dans ce cas, la methode toXML de T_Border doit afficher le country 2) et aura la valeur 2 si le pays 2 est celui 
   -- dont on veut recuperer les pays frontaliers (c'est-a-dire que dans ce cas la methode toXML de T_Border doit afficher le country 1).
   
   member function toXML return XMLType
)
/

create or replace type T_ensBorder as table of T_Border; -- Necessaire pour la methode toXML de T_Country qui necessite un ensemble de pays frontaliers.
/

create or replace type body T_Border as
 member function toXML return XMLType is
   output XMLType;
   begin
      -- Comme dans la DTD l'élément border est EMPTY, pas de noeud fils
      -- <!ATTLIST border countryCode CDATA #REQUIRED length CDATA #REQUIRED >
      if BOOLEAN = 2 then -- On veut récupérer le pays frontalier de country2
        output := XMLType.createxml('<border countryCode = "'||country1||'" length = "'||length||'"/>');
      else -- On veut récupérer le pays frontalier de country1
        output := XMLType.createxml('<border countryCode = "'||country2||'" length = "'||length||'"/>');
      end if;
      return output;
   end;
end;
/
create table LesBorders of T_Border; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 

-- COORDINATES

-- N'apparait pas dans la DataBase (Geocoord est vide) mais on en a besoin pour respecter la DTD.

drop type T_Coordinates force;
/

create or replace  type T_Coordinates as object (
   LATITUDE     NUMBER, -- Ajoute pour sa methode toXML, la DTD exige un attribut latitude pour l'element coordinates
   LONGITUDE    NUMBER, -- Ajoute pour sa methode toXML, la DTD exige un attribut longitude pour l'element coordinates

   member function toXML return XMLType
)
/

-- MONTAGNES 
drop type T_Montagne force;
/
create or replace  type T_Montagne as object (
   NAME         VARCHAR2(35 Byte),
   MOUNTAINS    VARCHAR2(35 Byte),  
   HEIGHT       NUMBER,
   TYPE         VARCHAR2(10 Byte),  
   COORDINATES  T_coordinates, 
   CODEPROVINCE VARCHAR2(35 Byte), -- ajoute
   
   member function toXML return XMLType
)
/

create or replace type T_ensMontagne as table of T_Montagne;  -- Necessaire pour la methode toXML de T_Province qui necessite un ensemble de montagnes.
/

create or replace type body T_Montagne as
 member function toXML return XMLType is
   output XMLType;
   begin
      output := XMLType.createxml('<mountain name = "'||self.name||'" height = "'||self.height||'" latitude = "'||self.coordinates.latitude||'" longitude = "'||self.coordinates.longitude||'" />');
            
return output;
   end;
end;
/

create table LesMontagnes of T_Montagne; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/

-- PROVINCE 
drop type T_Province force;
/
create or replace  type T_Province as object (
   NAME         VARCHAR2(35 Byte),
   COUNTRY      VARCHAR2(4 Byte),
   POPULATION   NUMBER,
   AREA         NUMBER,
   CAPITAL      VARCHAR2(35 Byte),
   CAPPROV      VARCHAR2(35 Byte),
   
   member function toXML return XMLType
)
/

create or replace type T_ensProvince as table of T_Province; -- Necessaire pour la methode toXML de T_Country qui necessite un ensemble de provinces.
/

create or replace type body T_Province as
 member function toXML return XMLType is
   output XMLType;

   -- Utilisation du type ensembliste precedemment defini rien que pour cette methode
   tmpmontagne T_ensMontagne;
   
   begin
      output := XMLType.createxml('<province name = "'||self.name||'" />');
       
      -- Creation des fils mountain
      
      select value(m) bulk collect into tmpmontagne
      from LesMontagnes m 
      where self.name = m.codeprovince ;  
      if tmpmontagne.COUNT != 0 then -- S'il n'y a pas de montagne dans cette province (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils mountain
        for indx IN 1..tmpmontagne.COUNT
        loop
           output := XMLType.appendchildxml(output,'province', tmpmontagne(indx).toXML());   
        end loop;
      else
        output := XMLType.appendchildxml(output,'province', XMLType('<mountain name = "''" />')); 
      end if;

      return output;
   end;
end;
/

create table LesProvinces of T_Province;  -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD   
/

-- ORGANIZATION

drop type T_Organization force;
/
create or replace  type T_Organization as object (
   ABREVIATION  VARCHAR2(12 Byte),
   NAME         VARCHAR2(80 Byte),
   CITY         VARCHAR2(35 Byte),
   COUNTRY      VARCHAR2(4 Byte),
   PROVINCE     VARCHAR2(35 Byte),
   ESTABLISHED  DATE,
   
   member function toXML return XMLType
)
/

create or replace type T_ensOrganization as table of T_Organization; -- Necessaire pour la methode toXML de T_Mondial qui necessite un ensemble d'organisation.
/

create or replace type body T_Organization as
 member function toXML return XMLType is
   output XMLType;
   begin
      if ESTABLISHED is not null then
        output := XMLType.createxml('<organization established = "'||to_char(established,'YYYY/MM/DD')||'" name = "'||self.name||'"/>');
      else
        output := XMLType.createxml('<organization name = "'||self.name||'"/>');
      end if;
      return output;
   end;
end;
/

create table LesOrganizations of T_Organization; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD   
/ 
-- COUNTRY
drop type T_Country force;
/
create or replace  type T_Country as object (
   NAME         VARCHAR2(35 Byte),
   CODE         VARCHAR2(4 Byte),
   CAPITAL      VARCHAR2(35 Byte),
   PROVINCE     VARCHAR2(35 Byte),
   AREA         NUMBER,
   POPULATION   NUMBER, 
   CONTINENT    VARCHAR2(20 Byte),
   
   member function frontiere return Number,
   member function toXML return XMLType
)
/

create or replace type T_ensCountry as table of T_Country;
/

create or replace type body T_Country as

 -- Fonction frontiere : retourne la longueur totale de la frontière du pays, c'est-a-dire la somme des longueurs des frontières avec chacun de ses voisins.

   member function frontiere return Number is
   res Number;
   begin
      begin
      select sum(b.length) into res 
      from LesBorders b
      where self.code = b.country1 or self.code = b.country2;
      end;
      if res is null then
        res := 0;
      end if;
      return res;
   end;
   
-- Fonction toXML
 member function toXML return XMLType is
   output XMLType;
   
   -- Utilisation des types ensemblistes precedemment definis rien que pour cette methode
   tmporganization T_ensOrganization;
   tmpprovince T_ensProvince;
   begin
    output := XMLType.createxml('<pays name = "'||name||'" code = "'||code||'" population = "'||population||'" frontiere = "'||frontiere()||'"/>');
    
    -- Creation des fils Organizations
    
      select value(o) bulk collect into tmporganization
      from LesOrganizations o
      where self.code = o.country
      Order by o.established;  
      for indx IN 1..tmporganization.COUNT
      loop
         output := XMLType.appendchildxml(output,'pays', tmporganization(indx).toXML());   
      end loop;
      
    -- Creation des fils provinces
      
      select value(p) bulk collect into tmpprovince
      from LesProvinces p
      where self.code = p.country;  
      for indx IN 1..tmpprovince.COUNT
      loop
         output := XMLType.appendchildxml(output,'pays', tmpprovince(indx).toXML());   
      end loop;
    return output;
   end;
end;
/

create table LesCountries of T_Country; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/

-- CONTINENT
drop type T_Continent force;
/

create or replace  type T_Continent as object (
   NAME         VARCHAR2(20 Byte),
   AREA         NUMBER(10),
  
   member function toXML return XMLType
)
/

create or replace type T_ensContinent as table of T_Continent; -- Necessaire pour la methode toXML de T_Mondial qui necessite un ensemble de continents.
/

create or replace type body T_Continent as
 member function toXML return XMLType is
   output XMLType;
   
   -- Utilisation du type ensembliste precedemment defini rien que pour cette methode
   tmpcountry T_ensCountry;
   
   begin 
      output := XMLType.createxml('<continent name = "'||name||'"/>');
      
      -- Creation des Countries
      
      select value(c) bulk collect into tmpcountry
      from LesCountries c -- Le monde contient tous les pays
      where self.name = c.continent;
      for indx IN 1..tmpcountry.COUNT
      loop
         output := XMLType.appendchildxml(output,'continent', tmpcountry(indx).toXML());   
      end loop;
      return output;
   end;
end;
/

create table LesContinents of T_Continent; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/

-- MONDIAL
-- N'apparait pas dans la DataBase mais on en a besoin pour respecter la DTD.

drop type T_Mondial force;
/
create or replace  type T_Mondial as object (
   ID           NUMBER, -- Ajoute pour numeroter les mondes, pour qu'il y ait une donnee dans le type T_Mondial 

   member function toXML return XMLType
)
/

create or replace type body T_Mondial as
 member function toXML return XMLType is
   output XMLType;
   -- Utilisation du type ensembliste precedemment defini rien que pour cette methode
   tmpcontinent T_ensContinent;
   begin
      output := XMLType.createxml('<ex3/>');
      select value(c) bulk collect into tmpcontinent
      from LesContinents c;
      for indx IN 1..tmpcontinent.COUNT
      loop
         output := XMLType.appendchildxml(output,'ex3', tmpcontinent(indx).toXML());   
      end loop;
      return output;
   end;
end;
/

create table LesMondials of T_Mondial; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/

-- INSERTIONS
-- On insere les valeurs dans nos tables en partant des tables de mondial_synonym.sql donnees.
-- On a choisi d'inserer toutes les donnees dans les tables, meme celles que l'on n'utilise pas puisqu'inutiles pour cet exercice

insert into LesMondials values( T_Mondial(1)); -- Le premier monde est arbitrairement le numero 1

insert into LesCountries
  select T_Country(c.NAME, c.CODE, c.CAPITAL, c.PROVINCE, c.AREA, c.POPULATION, e.CONTINENT)  
  from COUNTRY c, ENCOMPASSES e
  where c.CODE = e.COUNTRY;
  
insert into LesContinents
  select T_Continent(c.NAME, c.AREA)  
  from CONTINENT c;
  
insert into LesOrganizations
  select T_Organization(o.ABBREVIATION, o.NAME, o.CITY, O.COUNTRY, o.PROVINCE, o.ESTABLISHED)
  from ORGANIZATION o;
  
insert into LesProvinces
  select T_Province(p.NAME, p.COUNTRY, p.POPULATION, p.AREA, p.CAPITAL, p.CAPPROV)
  from PROVINCE p;
  
insert into LesMontagnes
  select T_Montagne(m.NAME, m.MOUNTAINS, m.HEIGHT, m.TYPE, T_Coordinates(m.COORDINATES.latitude, m.COORDINATES.longitude), g.PROVINCE)
  from  Mountain m, geo_mountain g
  where m.name = g.mountain;
  
insert into LesBorders
 select T_Border(b.COUNTRY1, b.COUNTRY2, b.LENGTH,1)  -- Par défaut, la donnée BOOLEAN de T_Border vaut 1, c'est-a-dire que country1 est le pays dont on cherche les voisins
 from Borders b;
 
-- exporter le resultat dans un fichier

WbExport -type=text
         -file='exercice3.xml'
         -createDir=true
         -encoding=UTF-8
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/
select m.toXML().getClobVal() 
from LesMondials m;
