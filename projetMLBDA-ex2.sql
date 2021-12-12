-- CREATION DES TYPES ET TABLES

-- DROP TABLE

drop table LesBorders;
/
drop table LesContinents;
/
drop table LesIslands;
/
drop table LesDeserts;
/
drop table LesMontagnes;
/
drop table LesPays;
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
/

-- CONTINENT
drop type T_Continent force;
/

create or replace  type T_Continent as object (
   NAME         VARCHAR2(20 Byte),
   AREA         NUMBER(10), -- Inutile pour cet exercice
   CODEPAYS     VARCHAR2(4),-- Ajoute pour les methodes toXML et continentPrincipal de T_Country, afin de connaitre les pays frontaliers situes dans le même continent
   PERCENTAGE   NUMBER, -- Ajoute pour la methode continentPrincipal de T_Country, afin de savoir dans quel continent est la plus grande partie d'un pays
   
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
   COORDINATES  T_COORDINATES, -- On a remplace GEOCOORD par notre nouveau type T_coordinates
   CODEPAYS     VARCHAR(4 Byte), -- Ajoute pour la methode toXML de T_Geo, afin de savoir a quel pays appartient l'ile
   
   member function toXML return XMLType
)
/

create or replace type T_ensIsland as table of T_Island; -- Necessaire pour la methode toXML de T_Geo qui necessite un ensemble d'iles.
/

create or replace type body T_Island as
 member function toXML return XMLType is
   output XMLType;
   begin 
      -- <!ELEMENT island (coordinates?) > 
      -- <!ATTLIST island name CDATA #REQUIRED >
      output := XMLType.createxml('<island name = "'||name||'"/>');
      if coordinates.latitude is not null and coordinates.longitude is not null then -- si coordinates est non nulle (sinon, on n'affiche pas de fils pour cet element island)
        output := XMLType.appendchildxml(output,'island', coordinates.toXML()); 
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
   -- COORDINATES  GEOCOORD, -- On a remplace GEOCOORD par T_coordinates, inutile pour cet exercice
   CODEPAYS     VARCHAR2(4 Byte), -- Ajoute pour la methode toXML de T_Geo, afin de savoir a quel pays appartient le desert
   
   member function toXML return XMLType
)
/

create or replace type T_ensDesert as table of T_Desert; -- Necessaire pour la methode toXML de T_Geo qui necessite un ensemble de deserts.
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

create table LesDeserts of T_Desert;-- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD
/
-- MONTAGNES 
drop type T_Montagne force;
/
create or replace  type T_Montagne as object (
   NAME         VARCHAR2(35 Byte),
   MOUNTAINS    VARCHAR2(35 Byte), -- Inutile pour cet exercice
   HEIGHT       NUMBER,
   TYPE         VARCHAR2(10 Byte), -- Inutile pour cet exercice
   -- COORDINATES  GEOCOORD, -- Inutile pour cet exercice -- On a remplace GEOCOORD par T_coordinates

   CODEPAYS     VARCHAR2(4 Byte), -- Ajoute pour la methode toXML de T_Geo, afin de savoir a quel pays appartient la montagne
   
   member function toXML return XMLType
)
/

create or replace type T_ensMontagne as table of T_Montagne;   -- Necessaire pour la methode toXML de T_Geo qui necessite un ensemble de montagnes.
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

-- GEO
 
drop type T_Geo force;
/
create or replace  type T_Geo as object (
   CODEPAYS     VARCHAR2(4 Byte),  -- Ajoute pour sa methode toXML afin de trouver les montagnes, iles et deserts du pays
   
   member function toXML return XMLType
)
/

create or replace type body T_Geo as
 member function toXML return XMLType is
   output XMLType;
   
   -- Utilisation des types ensemblistes precedemment definis rien que pour cette methode

   tmpmontagne T_ensMontagne;
   tmpdesert T_ensDesert;
   tmpisland T_ensIsland;
   
   begin
      -- Comme dans la DTD l'element geo a pour fils (mountain|desert)* et island*, on peut avoir jusqu'a trois types de noeuds differents
      output := XMLType.createxml('<geo/>');
      -- Pour la generation XML du noeud geo, on a decide de ne traiter qu'un cas particulier de la DTD dans lequel l'element geo a pour fils dans l'ordre, des montagnes, des deserts puis des iles. En effet, ce cas est bien plus facile a traiter et il respecte tout de meme la DTD comme voulu.

      -- Creation des fils mountain
      
      select value(m) bulk collect into tmpmontagne
      from LesMontagnes m 
      where self.codepays = m.codepays ;  
      if tmpmontagne.COUNT != 0 then -- S'il n'y a pas de montagne dans ce pays (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils mountain
        for indx IN 1..tmpmontagne.COUNT
        loop
           output := XMLType.appendchildxml(output,'geo', tmpmontagne(indx).toXML());   
        end loop;
      end if;
      
      -- Creation des fils desert
      
      select value(d) bulk collect into tmpdesert
      from LesDeserts d
      where self.codepays = d.codepays ;  
      if tmpdesert.COUNT != 0 then -- S'il n'y a pas de desert dans ce pays (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils desert
        for indx IN 1..tmpDesert.COUNT
        loop
           output := XMLType.appendchildxml(output,'geo', tmpdesert(indx).toXML());   
        end loop;
      end if;
      
      -- Creation des fils island
      
      select value(i) bulk collect into tmpisland
      from LesIslands i
      where self.codepays = i.codepays ;  
      if tmpisland.COUNT != 0 then  -- S'il n'y a pas d'ile dans ce pays (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils island
        for indx IN 1..tmpisland.COUNT
        loop
           output := XMLType.appendchildxml(output,'geo', tmpisland(indx).toXML());   
        end loop;
      end if;
    
      return output;
   end;
end;
/
        
-- COUNTRY
drop type T_Country force;
/
create or replace  type T_Country as object (
   NAME         VARCHAR2(35 Byte),
   CODE         VARCHAR2(4 Byte),
   CAPITAL      VARCHAR2(35 Byte), -- Inutile pour cet exercice
   PROVINCE     VARCHAR2(35 Byte), -- Inutile pour cet exercice
   AREA         NUMBER, -- Inutile pour cet exercice
   POPULATION   NUMBER, -- Inutile pour cet exercice
   
   member function peak return NUMBER,
   member function continentPrincipal return VARCHAR2,
   member function blength return NUMBER,
   member function toXML return XMLType
)
/

create or replace type T_ensCountry as table of T_Country; -- Necessaire pour la methode toXML de T_Mondial qui necessite un ensemble de pays.
/

create or replace type body T_Country as

-- Fonction peak : retourne la hauteur de la plus haute montagne du pays. S'il n'y a pas de montagne, retourne 0
  member function peak return Number is
    highest Number;
    begin
      select max(m.HEIGHT) collect into highest
      from LesMontagnes m
      where self.code = m.codepays;
      if highest is null then
        highest := 0;
      end if;
      return highest;
   end;

-- Fonction continentPrincipal : retourne le nom du contient principal du pays, c'est-a-dire le nom du continent sur lequel est majoritairement ce pays, soit le nom du continent possedant le plus grand pourcentage du pays  
  member function continentPrincipal return VARCHAR2 is
   continent varchar2(20 Byte);
   begin
      begin
        select c.name into continent 
        from LesContinents c
        where self.code = c.codepays and c.percentage >= all(select c.percentage from LesContinents c where self.code = c.codepays);
      end;
      return continent;
    end;
    
-- Fonction blength : retourne la longueur totale de la frontière du pays, c'est-a-dire la somme des longueurs des frontières avec chacun de ses voisins.

   member function blength return Number is
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
   tmpborder T_ensBorder;
   
   begin
      -- Comme dans la DTD l'element country a pour fils geo, peak? et contCountries il y a nécessairement au moins 2 fils de types differents et il peut avoir un fils de type peak (le ? signifiant 0 ou 1)
      -- <!ATTLIST country name CDATA #REQUIRED continent CDATA #REQUIRED blength CDATA #REQUIRED>
      output := XMLType.createxml('<country name = "'||name||'" continent = "'||continentPrincipal()||'" blength = "'||Blength()||'"/>');
      -- Creation du fils geo
      output := XMLType.appendchildxml(output,'country', T_Geo(self.code).toXML());
      
      -- Creation du possible fils peak
      if peak() != 0 then -- si peak() est différent de 0 alors il existe au moins une montagne dans le pays
        output := XMLType.appendchildxml(output,'country', XMLType('<peak height = "'||Peak()||'"/>'));
      end if;
      
      -- Creation du fils contCountries
      output := XMLType.appendchildxml(output,'country', XMLType('<contCountries/>')); 
      
      -- Creation des fils borders de contCountries
      
      select value(b) bulk collect into tmpborder
      from LesBorders b, LesContinents c
      where (self.code = b.country1 and c.codepays = b.country2 and self.continentPrincipal() = c.name) or (self.code = b.country2 and c.codepays = b.country1 and self.continentPrincipal() = c.name);  
      -- on ajoute dans la liste des pays frontaliers du pays seulement les pays frontaliers du même continent
      
      if tmpborder.COUNT != 0 then -- S'il n'y a pas de border a ce pays (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils border (le pays aura donc un fils contCountries vide)

        for indx IN 1..tmpborder.COUNT
        loop
           if self.code = tmpborder(indx).country1 then
              -- Par défaut, la donnée BOOLEAN de T_Border vaut 1 et donc on peut directement appeler la methode toXML de T_Border sans avoir a repreciser lequel des deux pays est en cours de traitement  
              output := XMLType.appendchildxml(output,'country/contCountries', tmpborder(indx).toXML()); -- Comme contCountries a pour fils (border*), on ajoute un noeud fils border sur le chemin 'country/contCountries', et ce autant de fois que necessaire (c'est-a-dire pour chaque objet border dans tmpborder)
           else
              tmpborder(indx).boolean := 2;-- On met le boolean a 2 afin de signaler que le pays en cours de traitement est le pays 2 dans T_Border et qu'il faut par consequent afficher le premier pays (et non le deuxieme qui est le pays courant dont on cherche les voisins)
              output := XMLType.appendchildxml(output,'country/contCountries', tmpborder(indx).toXML()); -- Comme contCountries a pour fils (border*), on ajoute un noeud fils border sur le chemin 'country/contCountries', et ce autant de fois que necessaire (c'est-a-dire pour chaque objet border dans tmpborder)
           end if;
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
      -- Comme dans la DTD l'element mondial a pour fils country+, il n'a qu'un seul type de noeud fils
      output := XMLType.createxml('<ex2/>');
      select value(p) bulk collect into tmpcountry
      from LesPays p; -- Le monde contient tous les pays
      for indx IN 1..tmpcountry.COUNT
      loop
         output := XMLType.appendchildxml(output,'ex2', tmpcountry(indx).toXML());   
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

insert into LesMontagnes
  select T_Montagne(m.NAME, m.MOUNTAINS, m.HEIGHT, m.TYPE, g.COUNTRY)
  from MOUNTAIN m, GEO_MOUNTAIN g
  where g.MOUNTAIN = m.NAME;
  
insert into LesDeserts
  select T_Desert(d.NAME, d.AREA, g.COUNTRY) 
  from DESERT d, GEO_DESERT g
  where g.DESERT = d.NAME;
  
insert into LesIslands
  select T_Island(i.NAME, i.ISLANDS, i.AREA, i.HEIGHT, i.TYPE,T_Coordinates(i.COORDINATES.LATITUDE, i.COORDINATES.LONGITUDE), g.COUNTRY)  
  from ISLAND i, GEO_ISLAND g
  where g.ISLAND = i.NAME;

insert into LesContinents
  select T_Continent(c.NAME, c.AREA, e.COUNTRY, e.PERCENTAGE)  
  from CONTINENT c, ENCOMPASSES e
  where c.NAME = e.CONTINENT;
  
insert into LesBorders
 select T_Border(b.COUNTRY1, b.COUNTRY2, b.LENGTH,1)  -- Par défaut, la donnée BOOLEAN de T_Border vaut 1, c'est-a-dire que country1 est le pays dont on cherche les voisins
 from Borders b;
       
-- exporter le resultat dans un fichier
WbExport -type=text
         -file='exercice2.xml'
         -createDir=true
         -encoding=UTF-8
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/
select m.toXML().getClobVal() 
from LesMondials m;
