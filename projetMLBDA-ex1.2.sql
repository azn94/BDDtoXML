-- DTD2

-- CREATION DES TYPES ET TABLES

-- DROP TABLE


drop table LesBorders;
/
drop table LesLanguages;
/
drop table LesCountries;
/
drop table LesOrganizations;
/
drop table LesMondials;
/

-- On a decide de ne pas modeliser de type pour headquarter etant donne que toute l'information est deja presente dans T_Organization

-- On a decide de ne pas modeliser de type pour borders etant donne que toute l'information est deja presente dans T_Border. En effet, comme l'element borders n'a pas d'attribut mais n'a que des fils qui sont des elements border, on a choisi de modeliser l'element borders directement dans T_Country a partir du type T_Border defini comme suit (puisque country est le seul element de la DTD qui utilise borders).

-- BORDER
drop type T_Border force;
/

create or replace  type T_Border as object (
   COUNTRY1     VARCHAR2(4 Byte),
   COUNTRY2     VARCHAR2(4 Byte),
   LENGTH       NUMBER,
   BOOLEAN      NUMBER,-- Ajoute pour sa methode toXML afin de savoir lequel des deux pays afficher
  
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

-- LANGUAGE
drop type T_Language force;
/

create or replace  type T_Language as object (
   COUNTRY      VARCHAR2(4 Byte), -- Utilise dans la methode toXML de T_Country
   NAME         VARCHAR2(50 Byte),
   PERCENTAGE   NUMBER,
   
   member function toXML return XMLType
)
/

create or replace type T_ensLanguage as table of T_Language; -- Necessaire pour la methode toXML de T_Country qui necessite un ensemble de langues.
/

create or replace type body T_Language as
 member function toXML return XMLType is
   output XMLType;
   begin 
      -- Comme dans la DTD l'element language est EMPTY, pas de noeud fils
      -- <!ATTLIST language language CDATA #REQUIRED percent  CDATA #REQUIRED >
      output := XMLType.createxml('<language language = "'||name||'" percent = "'||percentage||'"/>');
      return output;
   end;
end;
/

create table LesLanguages of T_Language; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD 
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
   POPULATION   NUMBER,
   ORGANIZATION VARCHAR2(12 Byte), -- Ajoute pour la methode toXML de T_Organization, afin de connaitre le pays dans lequel une organisation s'est etablie

   member function toXML return XMLType
)
/

create or replace type T_ensCountry as table of T_Country; -- Necessaire pour la methode toXML de T_Organization qui necessite un ensemble de pays.
/

create or replace type body T_Country as
 member function toXML return XMLType is
   output XMLType;
   
    -- Utilisation des types ensemblistes precedemment definis rien que pour cette methode
   tmplanguage T_ensLanguage;
   tmpborder T_ensBorder;
   
   begin
      -- Comme dans la DTD l'element country a pour fils (language*, borders), on peut avoir jusqu'a deux types de noeuds differents
      -- <!ATTLIST country code CDATA #IMPLIED name CDATA #REQUIRED population CDATA #REQUIRED > 
      if self.code is not null then -- si code n'est pas une valeur nulle, on l'affiche normalement
        output := XMLType.createxml('<country code = "'||self.code||'" name = "'||name||'" population = "'||population||'"/>');
      else  -- si code est une valeur nulle, on ne l'affiche pas (code est implied)
        output := XMLType.createxml('<country name = "'||name||'" population = "'||population||'"/>');
      end if;
      
      -- Creation des fils language 
      
      select value(l) bulk collect into tmplanguage
      from LesLanguages l 
      where self.code = l.country ;  
      if tmplanguage.COUNT != 0 then -- S'il n'y a pas de langue dans ce pays (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils langue 
        for indx IN 1..tmplanguage.COUNT
        loop
           output := XMLType.appendchildxml(output,'country', tmplanguage(indx).toXML());   
        end loop;
      end if;    
      
      -- Creation des fils borders
      
      select value(b) bulk collect into tmpborder
      from LesBorders b
      where self.code = b.country1 or self.code = b.country2;  
      
      -- Comme country a pour fils borders, on cree un noeud borders afin de respecter la DTD
      output := XMLType.appendchildxml(output,'country', XMLType('<borders/>') );
        
      if tmpborder.COUNT != 0 then -- S'il n'y a pas de frontiere a ce pays (ce n'est pas grave, la DTD l'accepte), on n'ajoute pas de fils border (le pays aura donc un fils borders vide)
        for indx IN 1..tmpborder.COUNT
        loop
           if self.code = tmpborder(indx).country1 then 
              -- Par défaut, la donnée BOOLEAN de T_Border vaut 1 et donc on peut directement appeler la methode toXML de T_Border sans avoir a repreciser lequel des deux pays est en cours de traitement
              output := XMLType.appendchildxml(output,'country/borders', tmpborder(indx).toXML());  -- Comme borders a pour fils (border*), on ajoute un noeud fils border sur le chemin 'country/borders', et ce autant de fois que necessaire (c'est-a-dire pour chaque objet border dans tmpborder)
              else
              tmpborder(indx).boolean := 2;  -- On met le boolean a 2 afin de signaler que le pays en cours de traitement est le pays 2 dans T_Border et qu'il faut par consequent afficher le premier pays (et non le deuxieme qui est le pays courant dont on cherche les voisins)
              output := XMLType.appendchildxml(output,'country/borders', tmpborder(indx).toXML());  -- Comme borders a pour fils (border*), on ajoute un noeud fils border sur le chemin 'country/borders', et ce autant de fois que necessaire (c'est-a-dire pour chaque objet border dans tmpborder)
           end if;
        end loop;
      end if;
      return output;
   end;
end;
/

create table LesCountries of T_Country; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD  
/

-- ORGANIZATION

drop type T_Organization force;
/
create or replace  type T_Organization as object (
   ABREVIATION  VARCHAR2(12 Byte),
   NAME         VARCHAR2(80 Byte),-- Inutile pour cet exercice
   CITY         VARCHAR2(35 Byte), -- Inutile pour cet exercice
   COUNTRY      VARCHAR2(4 Byte), -- Inutile pour cet exercice
   PROVINCE     VARCHAR2(35 Byte), -- Inutile pour cet exercice
   ESTABLISHED  DATE,-- Inutile pour cet exercice
   
   member function toXML return XMLType
)
/

create or replace type T_ensOrganization as table of T_Organization; -- Necessaire pour la methode toXML de T_Mondial qui necessite un ensemble d'organisations.
/

create or replace type body T_Organization as
 member function toXML return XMLType is
   output XMLType;
   
   -- Utilisation des types ensemblistes precedemment definis rien que pour cette methode
   tmpcountry T_ensCountry;
   
   begin
      -- Comme dans la DTD l'element organization a pour fils (country+, headquarter), on a deux types de noeuds differents
      output := XMLType.createxml('<organization/>');
      
      -- Creation des fils country
      
      select value(c) bulk collect into tmpcountry
      from LesCountries c
      where self.abreviation = c.organization; -- -- Ajoute pour la methode toXML de T_Organization, afin de connaitre les pays membres d'une organisation
      -- On a en effet choisi de compresser l'information et d'exprimer la relation Pays-Organisation dans T_Country
      -- Par consequent, pour chaque relation Pays-Organisation, on aura un element de type T_Country

      for indx IN 1..tmpcountry.COUNT
      loop
         output := XMLType.appendchildxml(output,'organization', tmpcountry(indx).toXML());   
      end loop;
      
      -- Creation du fils headquarter
      
       -- Comme on l'a specifie plus haut, on a trouve inutile de creer un type juste pour recuperer la ville dans laquelle est etablie le headquater alors que l'on y a acces directement depuis T_Organization. 
       -- On a par consequent simplement cree un fils headquarter ayant pour attribut name, le nom de la ville dans laquelle est etablie le QG de l’association. On a directement cette information dans T_Organization puisque c’est la donnee city.

      output := XMLType.appendchildxml(output,'organization', XMLType('<headquarter name="'||city||'"/>'));

    return output;
   end;
end;
/

create table LesOrganizations of T_Organization; -- Necessaire de creer une table pour y inserer les n-uplets voulus afin de coller a la DTD   
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
   tmporganization T_ensOrganization;
   
   begin
      -- Comme dans la DTD l'element mondial a pour fils organization+, on a un seul type de noeuds fils
      output := XMLType.createxml('<mondial/>');
      
      select value(o) bulk collect into tmporganization
      from LesOrganizations o; -- Le monde contient toutes les organisations
      for indx IN 1..tmporganization.COUNT
      loop
         output := XMLType.appendchildxml(output,'mondial', tmporganization(indx).toXML());   
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

insert into LesOrganizations
  select T_Organization(o.ABBREVIATION, o.NAME, o.CITY, o.COUNTRY, o.PROVINCE, o.ESTABLISHED)
  from ORGANIZATION  o
  where o.COUNTRY is not null; -- Etant donne que la DTD demande a ce que l'element organization ait au moins un fils country (puisque le + signifie 1 ou plus), on ne considere que les tuples avec une valeur country non nulle, c'est-a-dire que les organisations qui ont une donnee country non nulle

insert into LesCountries
 select T_Country(c.NAME, c.CODE, c.CAPITAL, c.PROVINCE, c.AREA, c.POPULATION,i.ORGANIZATION)
   from  COUNTRY c, ISMEMBER i
   where c.CODE = i.COUNTRY;
   
insert into LesLanguages
 select T_Language(l.COUNTRY, l.NAME, l.PERCENTAGE)
   from LANGUAGE l;
   
insert into LesBorders
 select T_Border(b.COUNTRY1, b.COUNTRY2, b.LENGTH,1) -- Par défaut, la donnée BOOLEAN de T_Border vaut 1, c'est-a-dire que country1 est le pays dont on cherche les voisins
 from BORDERS b;
   
-- exporter le resultat dans un fichier 
WbExport -type=text
         -file='mondial2.xml'
         -createDir=true
         -encoding=UTF-8
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/

select m.toXML().getClobVal() 
from LesMondials m;

