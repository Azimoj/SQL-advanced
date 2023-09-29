
-- NIVEAU 3 
-- 3.1. Using REGEX, get the time column from rides into an appropriable format

-- Commençons par jeter un oeil à cette colonne 
SELECT departure_time
from rides
-- Très lisible pour un oeil humain ce n'est pas le format d'heures standard qui permet de faire des opérations 
-- La séparation entre heures et minutes doit être un ':' pour être lue par les instructions SQL
-- on peut donc utiliser la fonction REPLACE(Nom_colonne, text,text) prend les éléments de la colonne et remplace le text renseigné au départ par celui renseigné ensuite
-- Changeons le 'h' en ':'
SELECT REPLACE(departure_time , 'h', ':') as TIME
FROM rides;

-- SQL peut maintenant lire l'heure, mais ce n'en est pas une pour autant, il faut encore la transtyper, pour que le type de la colonne ne soit plus du texte mais bien le forme TIME utilisé par SQL : 
-- FINAL : 

SELECT CAST(REPLACE(departure_time , 'h', ':') as TIME) as hour_TIME
FROM rides;
 
-- 3.2. Create a RANK of drivers by the number of rides they have done using a Window function

-- Nous devons commencer par compter le nombre de courses par driver , on l'a déjà fait à l'aide de rides et member_car
select mc.member_ID, count(r.ride_id) as nb_rides
	from rides r 
	left join member_car mc 
	on mc.member_car_id = r.member_car_id
	group by mc.member_id

-- Dans les window functions, nous connaissons RANK() qui permet de classer les différents éléments , nous voulons classer selon nb_rides
-- Pour simplifier la lecture, intégrons la requête que nous venons de faire à un WITH 
-- Ensuite, classons les conducteurs à l'aide de RANK() que nous utilisons sur l'attribut nb_rides disponible dans la "table" générée par le WITH
-- Profitons en pour joindre la table Member pour avoir le nom des conducteurs plutot que leur ID 


-- FINAL :

WITH rides_count as 
	(
    SELECT m.member_id, m.last_name, COUNT(*) AS nb_rides
    FROM rides r
    JOIN member_car mc
        ON r.member_car_id = mc.member_car_id
    JOIN members m
        ON mc.member_id = m.member_id
    GROUP BY m.member_id
    )
SELECT *
FROM 
	(SELECT rides_count.member_id, 
     		rides_count.last_name,
     		nb_rides,
     		RANK() OVER(ORDER BY nb_rides DESC) AS rk 
     FROM rides_count) AS driver_ranking
WHERE rk < 10;

-- 3.3 Compute the median contribution per passenger using window functions (take the average contribution asked by each car on all its rides, compute the median of this average ranking)

-- Pour calculer la médiane, l'idée est de classer les différentes contributions, puis de prendre la valeur correspondant à la médiane dans le classement obtenu
--commençons donc par classer les contributions (en groupant par ensemble member_car)

SELECT r.member_car_id ,AVG(contribution_per_passenger) AS prix_moy_depart 
,rank() OVER(ORDER BY AVG(contribution_per_passenger)) as rank_contrib
FROM rides AS r
INNER JOIN cities AS c
	ON r.starting_city_id = c.city_id
GROUP BY r.member_car_id

-- il faut maintenant trouver un calcul astucieux pour obtenir la médiane à partir de ce résultat
-- l'idée du calcul de médiane est de prendre la ligne du classement qui est au milieu du total de lignes (si le nombre de lignes est impair)
-- si le nombre de lignes est pair on peut prendre la ligne au milieu de la série
-- Imaginons une colonne avec 27 lignes, on prend la 14eme ; une colonne de 26 lignes : on prend le 13eme
-- on se rend compte que 13/26 = 0.5 et 14/27 > 0.5
-- l'idée du calcul est donc de prendre la première ligne qui respecte la condition n_ligne / nb_total_lignes >= 0.5
-- ce calcul est faisable, mais souvenez vous de notre première requête, nous avons classé les lignes, pas obtenu le numéro de la ligne
-- on peut donc avoir des doublons au mauvais endroit ! Commençons par change notre requête pour classer nos valeurs sans classement redondant avec ROW_NUMBER()


SELECT mc.car_id 
,AVG(contribution_per_passenger) AS prix_moy_depart 
,ROW_NUMBER() OVER(ORDER BY AVG(contribution_per_passenger)) as rw_nb
FROM rides AS r
INNER JOIN member_car AS mc
	ON r.member_car_id = mc.member_car_id
GROUP BY mc.car_id;

-- voilà, on peut intégrer cette requête à un WITH comme on a désormais l'habitude de le faire, puis faire un calcul sur les numéros de ligne en appelant le with : 
-- pour comprendre le calcul à effectuer : on prend toutes les lignes dont le rapport numéro_de_ligne / nombre_lignes est >= 0.5
-- on prend ensuite la plus petite de ces lignes (le MIN) : c'est notre valeur médiane 


-- FINAL 


WITH rk_table AS 
    (
    SELECT mc.car_id, 
            AVG(contribution_per_passenger) AS avg_contrib,
            ROW_NUMBER() OVER(ORDER BY avg_contrib) AS rw_nb
    FROM rides r
    JOIN member_car mc
        ON r.member_car_id = mc.member_car_id
    GROUP BY mc.car_id
    )

SELECT *
FROM rk_table
WHERE rw_nb = (SELECT MIN(rw_nb)
               FROM (
                 	SELECT *, rw_nb / (SELECT MAX(rw_nb) FROM rk_table) AS percentage
                 	FROM rk_table
                 	HAVING percentage >= 0.5
                 	) AS sb);



-- Q3.4 Compute the average time between two rides 

-- Procédons par étapes : 
--  Comme base de travail nous avons le jour de départ (departure_date) et l'heure de départ (departure_time)
--  Pour calculer le temps moyen entre deux courses, il nous faut classer chaque course selon le jour et l'heure de départ
--  Pour cela on doit d'abord trouver un moyen réunir la date et l'heure de départ en un seule élément au bon format
--  Ensuite il faut prendre l'écart entre chaque course, puis utiliser AVG() sur ces écarts

-- La première chose à régler c'est donc réunir la date et l'heure au bon format 
SELECT timestamp(timestamp(departure_date)+time(REGEXP_REPLACE(departure_time,'h',':')))
FROM rides; 
-- Pour comprendre, on a déjà dans un exo précédent retoucher departure_time pour le mettre au bon format
-- La fonction timestamp, elle permet de reformater des format DATE et TIME en format complet DATETIME à utiliser 
-- Ainsi timestamp (departure_date) crée un objet DATETIME, comme l'heure n'est pas renseignée dans departure_date, c'est 00h00mn qui est attibué par défaut
-- On rajoute donc l'heure de Departure time

-- Ensuite : on classe l'heure et date obtenu grâce à ORDER BY  
-- Pour calculer l'écart entre deux courses : on peut dès lors penser à la fonction lag, qui permet de reproduire une colonne existante avec un décalage choisi
SELECT timestamp(timestamp(departure_date)+time(REGEXP_REPLACE(departure_time,'h',':'))) as t1
	, LAG(timestamp(timestamp(departure_date)+time(REGEXP_REPLACE(departure_time,'h',':'))), 1) OVER() as t2

from rides r
ORDER BY t1
-- Dès lors, sur chaque ligne le jour et heure de départ d'une course fait face au jour et à l'heure de départ de la course précédente
-- on peut ensuite utiliser TIMEDIFF()pour calculer l'écart entre les deux dates et heures sur chaque ligne 
-- Malheureusement on ne peut utiliser AVG() sur cet écart car AVG() ne gère pas les calculs sur des dates et heures
-- On peut donc transforme donc notre différence en secondes grâce à TIME_TO_SEC(), on a donc une série de nombres sur lesquels on peut appliquer AVG()

-- Final : 

WITH time_table AS (
	select ride_id
	,timestamp(timestamp(departure_date)+time(REGEXP_REPLACE(departure_time,'h',':'))) as t1
	, LAG(timestamp(timestamp(departure_date)+time(REGEXP_REPLACE(departure_time,'h',':'))), 1) OVER(ORDER BY t1) as t2
	from rides r
	order by t1)
SELECT avg(TIME_TO_SEC(timediff(timestamp(t1),timestamp(t2))))/3600 as Hours -- Pour retrouver le nombre d'heures correspondent on divise nos secondes /3600 pour avoir 
FROM time_table																	-- un résultat plus lisible
-- Les plus courageux pourront reformater le résultat décimal obtenu en nombre d'heures pour retrouver un format TIME.


