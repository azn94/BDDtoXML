-- DTD 1

-- CREATION DES TYPES ET TABLES

-- DROP TABLE
drop table LesAirports;
/
drop table LesContinents;
/
drop table LesIslands;
/
drop table LesDeserts;
/
drop table LesMontagnes;
/
drop table LesProvinces;
/
drop table LesPays;
/
drop table LesMondials;
/

-- AIRPORT
drop type T_Airport force;
/
create or replace  type T_Airport as object (
   IATACODE     VARCHAR2(3 Byte), -- Inutile pour cet exercice
   NAME         VARCHAR2(100 Byte),
   COUNTRY      VARCHAR2(4 Byte), -- Utilise dans la methode toXML de T_Country
   CITY         VARCHAR2(50 Byte),
   PROVINCE     VARCHAR2(50 Byte), -- Inutile pour cet exercice
   ISLAND       VARCHAR2(50 Byte), -- Inutile pour cet exercice
   LATITUDE     NUMBER, -- Inutile pour cet exercice
   LONGITUDE    NUMBER, -- Inutile pour cet exercice
   ELEVATION    NUMBER, -- Inutile pour cet exercice
   GMTOFFSET    NUMBER, -- Inutile pour cet exercice
   
   member function toXML return XMLType
)
/

create or replace type T_ensAirport as table of T_Airport; -- Necessaire pour la methode toXML de T_Country qui necessite un ensemble d'aeroports.
/

create or replace type body T_Airport as
 member function toXML return XMLType is
   output XMLType;
   begin
      -- Comme dans la DTD l'element airport est EMPTY, pas de noeud fils
      -- <!ATTLIST airport name CDATA #REQUIRED nearCity CDATA #IMPLIED >
      if city is null then -- si city est une valeur nulle, on ne m'affiche pas (city est implied)
        output := XMLType.createxml('<airport name = "'||name||'" />');
      else
        output := XMLType.createxml('<airport name = "'||name||'" nearCity = "'||city||'" />');
      end if;
      return output;
   end;
end;
/

create table LesAirports of T_Airport; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/  

-- CONTINENT
drop type T_Continent force;
/

create or replace  type T_Continent as object (
   NAME         VARCHAR2(20 Byte),
   AREA         NUMBER(10), -- Inutile pour cet exercice
   CODEPAYS     VARCHAR2(4),  -- Ajoute pour la methode toXML de T_Country, afin de savoir a quel(s) continent(s) appartient le pays 
    -- On a en effet choisi de compresser l'information et d'exprimer la relation Pays-Continent dans T_Continent
    -- Par consequent, pour chaque relation Pays-Continent, on aura un element de type T_Continent
   PERCENTAGE   NUMBER, -- Ajoute pour la methode toXML de T_Continent, la DTD exige un attribut percent pour l'element continent
   
   member function toXML return XMLType
)
/

create or replace type T_ensContinent as table of T_Continent; -- Necessaire pour la methode toXML de T_Country qui necessite un ensemble de continents.
/

create or replace type body T_Continent as
 member function toXML return XMLType is
   output XMLType;
   begin 
      -- Comme dans la DTD l'élément continent est EMPTY, pas de noeud fils
      -- <!ATTLIST continent name CDATA #REQUIRED percent CDATA #REQUIRED >
      output := XMLType.createxml('<continent name = "'||name||'" percent = "'||percentage||'" />');
      return output;
   end;
end;
/

create table LesContinents of T_Continent; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/
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

create or replace type body T_Coordinates as
 member function toXML return XMLType is
   output XMLType;
   begin 
      -- Comme dans la DTD l'élément coordinates est EMPTY, pas de noeud fils
      -- <!ATTLIST coordinates latitude CDATA #REQUIRED longitude CDATA #REQUIRED>
      output := XMLType.createxml('<coordinates latitude = "'||latitude||'" longitude = "'||longitude||'" />');
      return output;
   end;
end;
/

-- ISLAND
drop type T_Island force;
/

create or replace  type T_Island as object (
   NAME         VARCHAR2(35 Byte),
   ISLANDS      VARCHAR2(35 Byte), -- Inutile pour cet exercice
   AREA         NUMBER, -- Inutile pour cet exercice
   HEIGHT       NUMBER, -- Inutile pour cet exercice
   TYPE         VARCHAR2(10 Byte), -- Inutile pour cet exercice
   COORDINATES  T_Coordinates, -- On a remplace GEOCOORD par notre nouveau type T_coordinates
   CODEPROVINCE VARCHAR(35 Byte), -- Ajoute pour la methode toXML de T_Province, afin de savoir a quelle province appartient l'ile
   
   member function toXML return XMLType
)
/

create or replace type T_ensIsland as table of T_Island; -- Necessaire pour la methode toXML de T_Province qui necessite un ensemble d'iles.
/

create or replace type body T_Island as
 member function toXML return XMLType is
   output XMLType;
   begin 
      -- Comme dans la DTD l'element island a pour fils (coordinates?), il peut avoir un fils de type coordinates (le ? signifiant 0 ou 1)
      -- <!ATTLIST island name CDATA #REQUIRED >
      output := XMLType.createxml('<island name = "'||name||'"/>');
      if coordinates.latitude is not null and coordinates.longitude is not null then -- si coordinates est non nulle (sinon, on n'affiche pas de fils pour cet element island)
        output := XMLType.appendchildxml(output,'island',coordinates.toXML());
      end if;
      return output;
   end;
end;
/

create table LesIslands of T_Island; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD
/

-- DESERT

drop type T_Desert force;
/
create or replace  type T_Desert as object (
   NAME         VARCHAR2(35 Byte),
   AREA         NUMBER,
   COORDINATES  T_coordinates, -- On a remplace GEOCOORD par T_coordinates, inutile pour cet exercice 
   CODEPROVINCE VARCHAR2(35 Byte), -- Ajoute pour la methode toXML de province, afin de savoir a quelle province appartient le desert
   
   member function toXML return XMLType
)
/

create or replace type T_ensDesert as table of T_Desert;  -- Necessaire pour la methode toXML de T_Province qui necessite un ensemble de deserts.
/

create or replace type body T_Desert as
 member function toXML return XMLType is
   output XMLType;
   begin
      -- Comme dans la DTD l'element desert est EMPTY, pas de noeud fils
       -- <!ATTLIST desert name CDATA #REQUIRED area CDATA #IMPLIED >
      if area is not null then -- si area est non nulle on le met en attribut
        output := XMLType.createxml('<desert name = "'||name||'" area = "'||area||'" />');
      else -- sinon il n'y a qu'un attribut name
        output := XMLType.createxml('<desert name = "'||name||'" />');
      end if;
      return output;
   end;
end;
/

create table LesDeserts of T_Desert; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/

-- MONTAGNES 
drop type T_Montagne force;
/
create or replace  type T_Montagne as object (
   NAME         VARCHAR2(35 Byte),
   MOUNTAINS    VARCHAR2(35 Byte),  -- Inutile pour cet exercice
   HEIGHT       NUMBER,
   TYPE         VARCHAR2(10 Byte),  -- Inutile pour cet exercice
   COORDINATES  T_coordinates, -- Inutile pour cet exercice -- On a remplace GEOCOORD par T_coordinates
   CODEPROVINCE VARCHAR2(35 Byte), -- Ajoute pour la methode toXML de T_Province, afin de savoir a quelle province appartient la montagne
   
   member function toXML return XMLType
)
/

create or replace type T_ensMontagne as table of T_Montagne;  -- Necessaire pour la methode toXML de T_Province qui necessite un ensemble de montagnes.
/

create or replace type body T_Montagne as
 member function toXML return XMLType is
   output XMLType;
   begin
      -- Comme dans la DTD l'element montagne est EMPTY, pas de noeud fils
      -- <!ATTLIST mountain name CDATA #REQUIRED height CDATA #REQUIRED >
      output := XMLType.createxml('<mountain name = "'||name||'" height = "'||height||'" />');
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
   COUNTRY      VARCHAR2(4 Byte), -- Utilise dans la methode toXML de T_Country
   POPULATION   NUMBER, -- Inutile pour cet exercice
   AREA         NUMBER, -- Inutile pour cet exercice
   CAPITAL      VARCHAR2(35 Byte),
   CAPPROV      VARCHAR2(35 Byte), -- Inutile pour cet exercice
   
   member function toXML return XMLType
)
/

create or replace type T_ensProvince as table of T_Province; -- Necessaire pour la methode toXML de T_Country qui necessite un ensemble de provinces.
/

create or replace type body T_Province as
 member function toXML return XMLType is
   output XMLType;
   
   -- Utilisation des types ensemblistes precedemment definis rien que pour cette methode
   tmpmontagne T_ensMontagne;
   tmpdesert T_ensDesert;
   tmpisland T_ensIsland;
   
   begin
      -- Comme dans la DTD l'element province a pour fils (mountain|desert)* et island*, on peut avoir jusqu'a trois types de noeuds differents
      -- <!ATTLIST province name CDATA #REQUIRED capital CDATA #REQUIRED >
      output := XMLType.createxml('<province name = "'||name||'" capital = "'||capital||'" />');
      -- Pour la generation XML du noeud province, on a decide de ne traiter qu'un cas particulier de la DTD dans lequel l'element province a pour fils dans l'ordre, des montagnes, des deserts puis des iles. En effet, ce cas est bien plus facile a traiter et il respecte tout de meme la DTD comme voulu.
      
      -- Creation des fils mountain
      
      select value(m) bulk collect into tmpmontagne
      from LesMontagnes m 
      where self.name = m.codeprovince ;  
      if tmpmontagne.COUNT != 0 then -- S'il n'y a pas de montagne dans cette province (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils mountain
        for indx IN 1..tmpmontagne.COUNT
        loop
           output := XMLType.appendchildxml(output,'province', tmpmontagne(indx).toXML());   
        end loop;
      end if;
      
      -- Creation des fils desert
      
      select value(d) bulk collect into tmpdesert
      from LesDeserts d
      where self.name = d.codeprovince ;  
      if tmpdesert.COUNT != 0 then -- S'il n'y a pas de desert dans cette province (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils desert
        for indx IN 1..tmpDesert.COUNT
        loop
           output := XMLType.appendchildxml(output,'province', tmpdesert(indx).toXML());   
        end loop;
      end if;
      
      -- Creation des fils island
      
      select value(i) bulk collect into tmpisland
      from LesIslands i
      where self.name = i.codeprovince ;  
      if tmpisland.COUNT != 0 then  -- S'il n'y a pas d'ile dans cette province (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils island
        for indx IN 1..tmpisland.COUNT
        loop
           output := XMLType.appendchildxml(output,'province', tmpisland(indx).toXML());   
        end loop;
      end if;
      
      return output;
   end;
end;
/

create table LesProvinces of T_Province;  -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD   
/
           
-- COUNTRY
drop type T_Country force;
/
create or replace  type T_Country as object (
   NAME         VARCHAR2(35 Byte),
   CODE         VARCHAR2(4 Byte),
   CAPITAL      VARCHAR2(35 Byte),  -- Inutile pour cet exercice
   PROVINCE     VARCHAR2(35 Byte),  -- Inutile pour cet exercice
   AREA         NUMBER,  -- Inutile pour cet exercice
   POPULATION   NUMBER,  -- Inutile pour cet exercice
   
   member function toXML return XMLType
)
/

create or replace type T_ensCountry as table of T_Country; -- Necessaire pour la methode toXML de T_Mondial qui necessite un ensemble de pays.
/

create or replace type body T_Country as
 member function toXML return XMLType is
   output XMLType;
   
   -- Utilisation des types ensemblistes precedemment definis rien que pour cette methode
   tmpcontinent T_ensContinent;
   tmpprovince T_ensProvince;
   tmpairport T_ensAirport;
   
   begin
      -- Comme dans la DTD l'element country a pour fils continent+, province+ et airport*, il y a necessairement au moins deux fils de types differents (continent et province) et il peut y avoir un ou plusieurs fils de type airport (le * signifiant 0 ou plus)
      -- <!ATTLIST country idcountry ID #REQUIRED nom CDATA #REQUIRED>
      output := XMLType.createxml('<country idcountry = "'||code||'" nom = "'||name||'" />');
      
      -- Creation des fils continent
      
      select value(c) bulk collect into tmpcontinent
      from LesContinents c
      where self.code = c.codepays ;  
      for indx IN 1..tmpcontinent.COUNT
      loop
         output := XMLType.appendchildxml(output,'country', tmpcontinent(indx).toXML());   
      end loop;
    
      -- Creation des fils province
      
      select value(p) bulk collect into tmpprovince
      from LesProvinces p
      where self.code = p.country ;  
      for indx IN 1..tmpprovince.COUNT
      loop
         output := XMLType.appendchildxml(output,'country', tmpprovince(indx).toXML());   
      end loop;
         
      -- Creation des fils airport
      
      select value(a) bulk collect into tmpairport
      from LesAirports a
      where self.code = a.country ;
      if tmpairport.COUNT != 0 then  -- S'il n'y a pas d'aeroport dans ce pays (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils airport
        for indx IN 1..tmpairport.COUNT
        loop
           output := XMLType.appendchildxml(output,'country', tmpairport(indx).toXML());   
        end loop;
      end if;

      return output;
   end;
end;
/

create table LesPays of T_Country; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
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
   tmpcountry T_ensCountry;
   
   begin
      -- Comme dans la DTD l'element mondial a pour fils country+, il n’a qu’un seul type de noeud fils
      output := XMLType.createxml('<mondial/>');
      select value(p) bulk collect into tmpcountry
      from LesPays p; -- Le monde contient tous les pays
      for indx IN 1..tmpcountry.COUNT
      loop
         output := XMLType.appendchildxml(output,'mondial', tmpcountry(indx).toXML());   
      end loop;
      return output;
   end;
end;
/

create table LesMondials of T_Mondial; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
/
-- INSERTIONS
-- On insere les valeurs dans nos tables en partant des tables de mondial_synonym.sql donnees.
-- On a choisi d'inserer toutes les donnees dans les tables, meme celles que l'on n'utilise pas (puisqu'elles sont inutiles pour cet exercice)

insert into LesMondials values( T_Mondial(1)); -- Le premier monde est arbitrairement le numero 1


insert into LesPays
  select T_Country(c.NAME, c.CODE, c.CAPITAL, c.PROVINCE, c.AREA, c.POPULATION) 
  from COUNTRY c;

insert into LesProvinces
   select T_Province(p.NAME, p.COUNTRY, p.POPULATION, p.AREA, p.CAPITAL, p.CAPPROV)
   from PROVINCE p;
       
insert into LesMontagnes
  select T_Montagne(m.NAME,m.MOUNTAINS, m.HEIGHT, m.TYPE, T_Coordinates(m.COORDINATES.latitude, m.COORDINATES.longitude),  g.PROVINCE)   
  from MOUNTAIN m, GEO_MOUNTAIN g
  where g.MOUNTAIN = m.NAME;
 
insert into LesDeserts
  select T_Desert(d.NAME, d.AREA,T_Coordinates(d.COORDINATES.latitude, d.COORDINATES.longitude), g.PROVINCE)
  from DESERT d, GEO_DESERT g
  where g.DESERT = d.NAME;
         
insert into LesIslands
  select T_Island(i.NAME,i.ISLANDS, i.AREA, i.HEIGHT, i.TYPE, T_Coordinates(i.COORDINATES.latitude, i.COORDINATES.longitude), g.PROVINCE)
  from ISLAND i, GEO_ISLAND g
   where g.ISLAND = i.NAME;

insert into LesContinents
  select T_Continent(c.NAME,c.AREA, e.COUNTRY, e.PERCENTAGE)
  from CONTINENT c, ENCOMPASSES e
  where c.NAME = e.CONTINENT;
   
insert into LesAirports
  select T_Airport(a.IATACODE, a.NAME, a.COUNTRY, a.CITY, a.PROVINCE, a.ISLAND, a.LATITUDE, a.LONGITUDE, a.ELEVATION, a.GMTOFFSET)
  from AIRPORT a;

-- exporter le resultat dans un fichier
WbExport -type=text
         -file='mondial.xml'
         -createDir=true
         -encoding=UTF-8
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/

select m.toXML().getClobVal() 
from LesMondials m;
