# 1.	Ajouter une colonne à la table rides qui affiche le nombre de total courses effectuées par le conducteur de 
#la course.
# (Indice : il faut joindre la table member_car a rides pour pouvoir y répondre, puis, faire une Window Fonction)


select *,  count(*) over(PARTITION by member_id)
from rides r
inner join member_car USING(member_car_id)


# 2.Créer un classement des conducteurs en fonction du nombre de courses.
# (Indice : pour vous faciliter la tâche : vous pouvez créer une VIEW qui affiche le nombre de courses par conducteurs 
# avant de faire le classement)

create view nb_rid_tables as(
SELECT mc.member_id ,count(*) as nb_rides
from rides r
join member_car mc 
  on mc.member_car_id = r.member_car_id
group by mc.member_id)

SELECT * , RANK() OVER(ORDER BY nb_rides DESC) Rank
from nb_rid_tables



# 3.	Sans créer de VIEW, affichez le % des recettes des rides par conducteur.
# (Indice : Tu peux utiliser la fonction WITH).
# Lorsque vous aurez réussi, stockez le résultat dans une VIEW, vous en aurez besoin pour la question suivante.

SELECT member_id, count(*) as nb_riders, 
from rides
join member_car USING(member_car_id)
group by member_id


#4.	Reprenez la table créée dans la question précédente et faites un classement des conducteurs en fonction du % de 
# recettes, puis n’affichez que top 10% des conducteurs en fonction de leurs % de participation aux recettes. 
# (Indice : le classement est une des étapes qui vous permet d’extraire les 10% des conducteurs en fonction de leurs
# participations aux recettes).




# 5.Créer une nouvelle colonne dans la table rides qui combine la date de départ et l’horaire de départ de 
# chaque course, stockez les résultats dans une VIEW Puis, ajoutez une colonne à cette table qui renseigne le 
# temps écoulé entre chaque course.


