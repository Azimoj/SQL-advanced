--Niveau Difficile


--3.1 Show trip information for trips that started in Toulouse, Lyon or Bordeaux

-- Ici, nous voulons les informations contenus dans la table rides
-- Cependant les noms de villes ne sont pas stockés directement dans la table, on peut les retrouver dans la table city
-- il faut donc à nouveau réaliser une jointure 
-- Le point commun entre les deux tables et autour duquel on veut joindre est l'id pour la table city et starting_city_id pour la table rides
-- la commande WHERE ne portera donc pas sur la table rides mais sur la table City dans laquelle on peut spécifier les noms de villes

-- Final : 

SELECT *
FROM rides
INNER JOIN cities
	ON cities.city_id = rides.starting_city_id
WHERE cities.city_name  IN ('Toulouse', 'Lyon', 'Bordeaux');


--3.2 The number of accepted rides? Pending? Refused?

-- Pour comprendre, il faut bien lire la documentation de la base de données, la table requests comporte un attribut request_status 
-- Il existe aussi une table request_status, avec seulement  3 lignes et 2 colonnes  d'ID 1,2 et 3 auquel correspond le type de requete: pending, Approved, Rejected

-- On veut le nombre de rides de différents statuts, on peut à priori raisonner avec uniquement la table request qui comporte l'attribut request_status
-- Nous l'avons déjà fait, on veut grouper les requêtes selon leur request_status puis compter les éléments de chaque groupe, count(*) et group by sont nos amis

SELECT count(*), request_status
FROM requests 
GROUP BY request_status;

-- Dommage, on a presque ce qu'on veut, mais l'attribut request_status de la table requests n'est qu'un chiffre, on ne sait pas s'il correspond à une demande acceptée, refusée..
-- La documentation de la base nous renseigne, cette information est contenue dans la table (à ne pas confondre avec l'attribut) request_status, à l'attribut Status
-- Il faut donc réaliser un inner join entre l'id de la table request_status et l'attribut request_status de la table requests
-- Pensez à mettre des alias à vos tables pour facilier la compréhension du code 


-- Final : 
SELECT COUNT(*), rs.Status 
FROM requests r
INNER JOIN request_status rs
	ON r.request_status = rs.request_status_id 
GROUP BY r.request_status;

--3.3 Show the average price per passenger per city of arrival, order by ascending number

-- Le cas de figure ressemble, on sait qu'on va devoir utiliser la fonction d'agrégation AVG() sur l'attribut contribution_per_passenger 
-- On sait aussi qu'on doit faire la moyenne par villes d'arrivée, on doit donc séparer la table en groupe de villes d'arrivée distinctes
-- On doit aussi classer le résultat obtenu, on se rappelle de la commande ORDER BY 
-- On peut donc écrire notre patron de requête : 

SELECT AVG(contribution_per_passenger) AS prix_moy, destination_city_id
FROM rides
GROUP by destination_city_id
ORDER by AVG(contribution_per_passenger);

-- On se retrouve avec un problème similaire, pour plus de lisibilité on veut le nom de la ville et pas son ID
-- Le nom de la ville n'est pas disponible dans la table rides, il faut aller le chercher par jointure dans la table cities :

-- Final : 

SELECT AVG(contribution_per_passenger) AS prix_moy, destination_city_id, city_name
FROM rides
INNER JOIN cities
	ON cities.city_id = rides.destination_city_id
GROUP BY destination_city_id
ORDER BY AVG(contribution_per_passenger);


--3.4 Show the average price per passenger per city of departure

-- On sait le faire, la seule chose qui change et que l'on raisonne à partir de la ville de départ, qui nous est renseigné par l'attribut starting_city_id dans la table rides
-- On comprend l'intérêt d'avoir mis les noms de villes dans une table séparée : 
-- On aurait pu créer la table rides de façon lourde avec les attributs : starting_city_id, StartingCityName, destination_city_id, DestinationCityName
-- en créant une nouvelle table et à l'aide de jointures, les informations propres aux villes ne sont stockées qu'une fois dans une table dédiée


-- Final : 

SELECT AVG(contribution_per_passenger) AS prix_moy, starting_city_id, city_name
FROM rides
INNER JOIN cities
	ON cities.city_id = rides.starting_city_id
GROUP BY starting_city_id, city_name;



--3.5 Compute the average price of a ride from Paris to Bruxelles

-- La difficulté de cette question n'est pas le calcul de la moyenne, maintenant on sait bien le faire
-- La difficulté est la suivante : la table rides contient les attributs starting_city_id et destination_city_id, comme avant il manque les noms de ville
-- Cette fois-ci on veut une condition sur les noms des villes. En plus de cela on a besoin deux fois de la table cities pour obtenir les noms de villes de départ et d'arrivée.
-- On peut donc découper le problème : commençons par calculer le prix moyen d'une course au départ de paris (il nous faut une jointure comme avant mais aussi un WHERE):

SELECT AVG(contribution_per_passenger) AS prix_moy
FROM rides
INNER JOIN cities as c
	ON c.city_id = rides.starting_city_id
WHERE c.city_name = 'Paris';

-- C'est déjà bien, maintenant on ne veut garder que les courses dont le point d'arrivée est Bruxelles
-- On aurait donc besoin d'une autre jointure avec notre chère table cities, mais on en a déjà fait une !
-- En fait ce n'est pas grave, on peut faire une 2eme jointure, toujours sur cities.id d'un côté mais sur destination_city_id pour la table rides
-- Cependant on a un problème de nom, on est obligé de faire un alias lors de la jointure pour pouvoir construire notre requête en distinguant la 1ere jointure de la 2eme.
-- Sans oublier de rajouter une spécificité au WHERE, on peut donc construire notre requête finale : 
-- Rappelons-nous qu'une jointure , c'est la création éphémère d'une table avec les colonnes de plusieurs tables existantes, tant que l'on peut distinguer nos colonnes
-- on peut faire de multiples jointures avec les mêmes tables (donc sous réserve d'utiliser un alias)

-- Final : 

SELECT AVG(contribution_per_passenger) AS prix_moy
FROM rides
INNER JOIN cities as ct1
	ON ct1.city_id = rides.starting_city_id
INNER JOIN cities as ct2
	ON ct2.city_id = rides.destination_city_id
WHERE ct1.city_name = 'Paris' AND ct2.city_name = 'Bruxelles';

--3.6 Show all the rides made with a Chrisler

-- On veut les informations des courses qui ont été faites avec un certain modèle
-- Notre problème : Les informations de courses sont dans la table rides, les informations de modèle dans la table cars
-- On voit qu'il n'existe pas de lien direct entre ces deux tables par clef étrangère (cf. documentation), à la place il y a une table intermédiaire members_car
-- Pour avoir accès à nos informations, il faut donc réaliser une jointure entre les tables cars et member_car, puis une jointure entre les tables member_car et rides
-- A la fin il n'existera plus qu'une seule table résultant des deux jointures qui ont été réalisées successivement à la lecture de la requête par l'ordinateur
-- Cette jointure permet de gérer le cas où une voiture est détenue par plusieurs personnes, ou une personne détenant plusieurs voitures (avec duplicates)


--Final : 

SELECT *
FROM rides r 
INNER JOIN member_car
	ON member_car.car_id = r.member_car_id
INNER JOIN cars 
	ON cars.car_id = member_car.car_id
WHERE maker = 'Chrisler';


--3.7 Show all the rides from Versailles with a big luggage available

-- La question ressemble à la 3.5, on a deux spécificités pour les courses à afficher, le type de bagage et la vile de départ
-- Comme les informations permettant de respecter ces spécificités sont dans les tables cities et luggage_types, on réalise les deux jointures adéquates 

-- Final : 

SELECT *
FROM rides r 
INNER JOIN luggage_types 
	ON luggage_types.luggage_type_id = r.luggage_id
INNER JOIN cities 
	ON cities.city_id = r.starting_city_id 
WHERE cities.city_name = 'Versailles' AND  luggage_types.type = 'gros';

--3.8 Show all comments sent by a ‘Jeanine’

-- On veut afficher les commentaires situés dans la table ratings, envoyés par des membres avec prénom spécifique
-- Les prénoms sont dans la table members, on peut donc joindre les deux tables pour obtenir le résultat
-- Attention de faire la jointure sur l'attribut rating_giver_ID et non sur rating_receiver_id, on veut les commentaires envoyés par les 'Jeanine', pas reçus..

-- Final : 

SELECT comments
FROM ratings r
INNER JOIN `members` as m
	ON m.member_id = r.rating_giver_ID 
WHERE m.first_name ='Jeanine' AND r.comments != ''; -- on voit dans la doc que l'absence de commentaires n'est pas un NULL mais une chaîne de caractères vide
													-- on évite donc d'afficher les commentaires 'vides' avec l'opérateur logique != (pas égal à)


--3.9 Select all trips that took place in France

-- Comme en 3.5, l'idée est de joindre la table rides deux fois avec la table cities, mais cette fois pour spécifier le pays de départ et d'arrivée dans le WHERE
-- Attention à ne pas oublier les Alias

-- Final : 

SELECT DISTINCT * 
FROM rides
INNER JOIN cities as ct1
	ON ct1.city_id = rides.starting_city_id 
INNER JOIN cities as ct2
	ON ct2.city_id = rides.destination_city_id
WHERE ct1.country = 'France' AND ct2.country = 'France';

--3.10 Show all customers between 20 and 45 years old?

-- Nous avons accès à la date de naissance des membres
-- Nous verrons plus en détails les fonctions permettant de gérer les dates un peu plus tard,
-- Aujourd'hui on peut utiliser la fonction DATE_SUB
-- La fonction DATE_SUB prend différents arguements : DATE_SUB(date, INTERVAL value interval), par exemple :
DATE_SUB("2018-04-01", INTERVAL 10 YEAR) -- calcule la différence entre la date entrée après la pérenthèse et l'intervalle précisé après
NOW() -- est une fonction qui renvoie la date et l'heure au moment où la requête est exécutée
-- Avec ces deux fonctions utilisées dans un WHERE il est possible d'écrire la requête : (plus d'info ici https://www.w3schools.com/sql/func_mysql_date_sub.asp)

SELECT *
FROM members
WHERE  birthdate < DATE_SUB(NOW(), INTERVAL 20 YEAR) 
	AND birthdate > DATE_SUB(NOW(), INTERVAL 45 YEAR) ;


-- 3.11 Does the type of luggage affect the mean rating that members are giving to their rides?

-- Quelles jointures faut-il réaliser pour obtenir ce résultat ?
-- L'information 'taille de bagage' est disponible dans la table luggage_types 
-- Les notes des membres sont disponibles dans la table ratings
-- D'après les liens entre les tables, pour lier les deux il faut joindre également la table rides, member_car et members en prêtant attention aux Ids.
-- Attention à la jointure entre members et Ratings, 
-- Pour le calcul, il suffit d'utiliser la fonciton AVG() en groupant par l'id de la table luggage_types car c'est dans l'id que réside l'information du type de bagage
select lt.`type`, avg(r2.grades) as avg_grade
from luggage_types lt
	inner join rides r
	on r.luggage_id = lt.luggage_type_id
		left join member_car mc
		on mc.member_car_id = r.member_car_id
			left join `members` m2
			on mc.member_id = m2.member_id
				inner join ratings r2
				on r2.rating_giver_id = m2.member_id
group by lt.luggage_type_id; -- answer no it does not have influence on members' grades

-- 3.12 What is the most hyped destination city for each starting city?

-- Pour trouver la réponse à cette question, on a besoin de la table rides, et deux fois de la table cities pour trouver les noms correspondants aux Ids des villes
SELECT *
from rides r
	inner join cities c1 on c1.city_id = r.starting_city_id
	inner join cities c2 on c2.city_id = r.destination_city_id
-- On a l'habitude des questions où on groupe par un type de ville (de départ ou d'arrivée), puis où l'on compte ou calcule quelque chose
-- Or ici, pour pour trouver les destinations les plus prisés à partir de chaque ville de départ, il faut compter chaque couple (villes de départ, villes d'arrivée)
-- L'idée est donc de grouper notre table par couple de villes, puis de compter le nombre de valeurs de chaque groupe
-- C'est aussi possible avec un group by, on peut réaliser des groupes portant sur plusieurs colonnes et non une seule 
select c1.city_name as dep , c2.city_name as ar, count(c2.city_name) as counter
from rides r
	inner join cities c1 on c1.city_id = r.starting_city_id
	inner join cities c2 on c2.city_id = r.destination_city_id
group by c1.city_name , c2.city_name; 

-- Enfin il s'agit d'ordonner notre résultat, on veut pour chaque ville la destinations la plus prisée, on ne peut donc écrire simplement
ORDER BY counter DESC
-- car cela ne donnera pas les résultats ville par ville, rappelez vous qu'il est aussi possible d'ORDER BY plusieurs colonnes :

-- Final : 

select c1.city_name as dep , c2.city_name as ar, count(c2.city_name) as counter
from rides r
	inner join cities c1 on c1.city_id = r.starting_city_id
	inner join cities c2 on c2.city_id = r.destination_city_id
group by c1.City_name , c2.City_name
order by dep,counter DESC;

-- 3.13 What car brand receives the greatest number of messages?

-- On a besoin d'informations de cars et de messages, 
--on doit donc joindre ces deux tables avec member_car car il n'existe pas de clef étrangère permettant de relier les deux tables qui nous intéresse directement
-- il faut grouper la table par maker , le modèle de voitures, et on compte chaque Id de message par groupe
-- Final 


SELECT maker, COUNT(msg.message_id) AS nb_messages
FROM cars c
LEFT JOIN member_car mc
	ON c.car_id = mc.car_id
LEFT JOIN messages msg
	ON mc.member_id = msg.receiver_id
GROUP BY maker
ORDER BY nb_messages DESC;

-- 3.14 Each car has a C02_code, can you show the repartition (as a percentage) of each CO2_code in the ride pool of blablavoiture ? 

-- Nous n'avons pas vu l'attribut C02_code pour le moment, il s'agit simplement d'une information complémentaire dans la table cars
-- La question stipule que nous voulons la répartition de ce codeC02 sur l'ensemble des courses réalisées sur la plateforme, et non sur l'ensemble des voitures enregistrées
-- Le calcul est donc à faire à partir de la table rides, auquel on rajoute l'information C02_code par jointure 

select *
from cars c
inner join member_car mc on mc.car_ID = c.car_id
inner join rides r on r.member_car_id = mc.member_car_id;

-- Il nous suffit maintenant de faire le calcul de proportion, l'idée est d'abord de grouper par C02_code.
-- il nous restera plusieurs lignes surlesquelles effectuer nos opérations, on sait désormais que l'on peut effectuer de tels calculs dans le SELECT
-- Pour calculer la proportion, il faut compter le nombre de lignes dans chaque groupe et le diviser par le nombre total de références de courses
-- On pense à ordonner son résultat :

-- Final : 
 
select c.CO2_code, 
		count(*) AS nb_rides,
		count(*)*100/(SELECT Count(*) FROM rides) as percentage
from cars c
join member_car mc 
	on mc.car_ID = c.car_id
join rides r 
	on r.member_car_id = mc.member_car_id
group by c.CO2_code
order by percentage DESC;

-- 3.15	What rows intersect between the inner join of members and ratings and the Left Join of the same two tables?

-- On veut comparer deux jointures, commençons par écrire les deux :
select *
from members m1 
left join ratings r
	on r.rating_giver_ID = m1.member_id

select *
from members m2 
inner join ratings r
	on r.rating_giver_ID = m2.member_id

-- Pour afficher uniquement l'intersection de deux tables jointes, on peut penser à la commande EXISTS 
-- Elle s'utilise dans une clause conditionnelle (WHERE) la requête principale ne renvoie des valeurs que lorsque le sous requête utilisée dans EXISTS renvoie une valeur
-- il suffit donc de tester l'existence de deux lignes égales entre les deux tables u3 et u2, on affiche ensuite cette ligne

--Final : 
	 
select *
from members m1 
left join ratings r
	on r.rating_giver_ID = m1.member_id
where EXISTS (select *
			  	from members m2 
				inner join ratings r
					on r.rating_giver_ID = m2.member_id
			  	where m1.member_id = m2.member_id); -- Correlated subquery


