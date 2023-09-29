
SELECT*
FROM orders

# 2.quelle est les chifre d'affer total des villes
select *, sum(order_amount) 
over(partition by city) as tot_amnt_per_city
from orders



# 3.caculer average en fonction de la vile et mois?
SELECT order_id, order_date, customer_name,city, order_amount, avg(order_amount)
over(PARTITION by city, month(order_date)) as avr_order_amnt
from orders

SELECT*, avg(order_amount)
over (partition by city, month(order_date)) as avg_order_amut
from orders

#4.Montrer le nom de ligne
SELECT order_id, order_date, order_amount, customer_name,
row_number() over(partition by order_id) as chronu
from orders