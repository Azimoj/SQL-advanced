SELECT *,
CASE WHEN lt.type = 'petit' THEN 'gratuit'
	ELSE 'payant'
	END AS price
FROM luggage_types lt;

SELECT COUNT(ride_id),
	(
	CASE 
	WHEN r.contribution_per_passenger < 10 THEN 'cheap'
	WHEN r.contribution_per_passenger BETWEEN 10 AND 20 THEN 'medium'
	ELSE 'premium'
	END
	) AS price_category
	FROM rides r 
	GROUP BY price_category


SELECT now();  -- Timestamp
SELECT DATE(now()); -- Date
SELECT DATE(now()) > '2017-12-31';
SELECT now() > '2017-12-31'; 

SELECT DATEDIFF(DATE(now()), DATE("2017-06-15"));
SELECT DATE_ADD("2017-06-15", INTERVAL 10 YEAR);



WITH pet_lovers AS 
(
	SELECT *
	FROM members m
	WHERE pet_preference = 'yes'
)
SELECT member_id,email, birthdate
FROM pet_lovers
WHERE birthdate > DATE('1990-01-01');



-- EXO: créer des tranches d'âge 18-24, 25-39, 40-60, 60+ puis compter le nb de membres par catégorie, et afficher le pourcentage du total
SELECT
		CASE WHEN DATEDIFF(NOW(), birthdate) / 365 < 25 THEN '18-24'
        WHEN DATEDIFF(NOW(), birthdate) / 365 BETWEEN 25 AND 39 THEN '25-39'
        WHEN DATEDIFF(NOW(), birthdate) / 365 BETWEEN 40 AND 60 THEN '40-60'
        ELSE '60+'
        END AS age_category,
        COUNT(*) AS nb_members,
        ROUND(COUNT(*)*100 / (SELECT COUNT(*) from members), 2) AS percentage
FROM members
GROUP BY age_category;


SELECT ride_id, starting_city_id, contribution_per_passenger,
	AVG(contribution_per_passenger) over(PARTITION BY starting_city_id) 
											AS start_city_avg_contribution
	FROM rides r ;


-- TABLE ORDERS 

DROP TABLE IF EXISTS Orders;
CREATE TABLE Orders
(
	order_id INT,
	order_date DATE,
	customer_name VARCHAR(250),
	city VARCHAR(100),	
	order_amount INT
);
 
insert into Orders values ('1001','2017-02-02','David Smith','GuildFord',10000);
insert into Orders values ('1002','2017-02-03','David Jones','Arlington',20000);
insert into Orders values ('1003','2017-02-04','John Smith','Shalford',5000) ;
insert into Orders values ('1004','2017-02-05','Michael Smith','GuildFord',15000) ; 
insert into Orders values ('1005','2017-02-06','David Williams','Shalford',7000);
insert into Orders values ('1006','2017-02-07','Paum Smith','GuildFord',25000);
insert into Orders values ('1007','2017-02-08','Andrew Smith','Arlington',15000);  
insert into Orders values ('1008','2017-02-09','David Brown','Arlington',2000);
insert into Orders values ('1009','2017-02-10','Robert Smith','Shalford',1000);
insert into Orders values ('1010','2017-02-12','Peter Smith','GuildFord',500);

SELECT order_id, order_date, customer_name, city, order_amount ,SUM(order_amount)
OVER(PARTITION BY city) as grand_total
FROM Orders;


SELECT order_id, order_date, customer_name, city, order_amount, AVG(order_amount)
OVER(PARTITION BY city, MONTH(order_date)) as   average_order_amount
FROM Orders;

SELECT order_id,order_date,customer_name,city, order_amount,
ROW_NUMBER() OVER(ORDER BY order_id) row_number_
FROM Orders;


SELECT order_id, order_date, customer_name, city, order_amount
 ,MAX(order_amount) OVER(PARTITION BY city) as maximum_order_amount
FROM Orders;


SELECT order_id,order_date,customer_name,city,
RANK() OVER(ORDER BY order_amount DESC) as rank_
FROM Orders;

SELECT order_id,order_date,customer_name,city,
ROW_NUMBER() OVER(PARTITION BY order_date ORDER BY order_date DESC) as chrono
FROM Orders


SELECT city, order_amount,
ROW_NUMBER() OVER(PARTITION BY city ORDER BY order_amount) AS row_number,
RANK() OVER(PARTITION BY city ORDER BY order_amount) AS rank,
DENSE_RANK() OVER(PARTITION BY city ORDER BY order_amount) AS dense_rank
FROM orders;

SELECT c.city_name, t.*
FROM
(
SELECT ride_id, starting_city_id, contribution_per_passenger,
		ROW_NUMBER() OVER(PARTITION BY starting_city_id
							ORDER BY contribution_per_passenger) as row_number_price
FROM rides rides r
) t
INNER JOIN cities c on c.city_id = t.starting_city_id
WHERE row_number_price <= 30;


SELECT order_id,customer_name,city, order_amount,order_date,
LAG(order_date,1) OVER(ORDER BY order_date) prev_order_date
FROM Orders

SELECT order_id,customer_name,city, order_amount,order_date,
LEAD(order_date,1) OVER(ORDER BY order_date) prev_order_date
FROM Orders


WITH price_type AS 
(
SELECT ride_id, starting_city_id, contribution_per_passenger,
		AVG(contribution_per_passenger) OVER(PARTITION BY starting_city_id) as start_city_avg_contrib
FROM rides r 
)
SELECT ride_id, starting_city_id, contribution_per_passenger,
		CASE 
			WHEN contribution_per_passenger > start_city_avg_contrib THEN 'arnaque'
			WHEN contribution_per_passenger <= start_city_avg_contrib THEN 'aubaine'
		END
		AS price_indication
	FROM price_type


-- Correction EXO 

SELECT city, 
            order_amount, 
            order_date,
            ROUND((order_amount / LAG(order_amount, 1) OVER(PARTITION BY city ORDER BY order_date) - 1) * 100, 2) AS percentage
    FROM Orders

-- si on veut calculer l'évolution moyenne par ville :

WITH percentage_sales_evolution AS
	(
    SELECT city, 
            order_amount, 
            order_date,
            ROUND((order_amount / LAG(order_amount, 1) OVER(PARTITION BY city ORDER BY order_date) - 1) * 100, 2) AS percentage
    FROM Orders
  	)
SELECT city, AVG(percentage) AS avg_percentage
FROM percentage_sales_evolution
GROUP BY city;
	



-- Si on veut filtrer uniquement sur aubaine 

WITH 
	price_type AS
        (
        SELECT ride_id, 
                starting_city_id, 
                contribution_per_passenger,
                AVG(contribution_per_passenger) OVER(PARTITION BY starting_city_id) city_avg_contrib
        FROM rides
        ),
    contrib_algorithm AS
    	(
        SELECT ride_id, 
                starting_city_id, 
                contribution_per_passenger, 
                case 
                    when contribution_per_passenger > city_avg_contrib THEN 'arnaque'
                    ELSE 'aubaine'
                END AS price_indication
        FROM price_type
        )
SELECT * 
FROM contrib_algorithm
WHERE price_indication = 'aubaine';



