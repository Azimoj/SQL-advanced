-- MISSION 2

-- Saisonnalité 
SELECT loo.year
		, loo.Month 
		, sum(amount) as total_sales
from list_of_orders loo
INNER join order_details od 
	on loo.order_id = od.order_id
 group by 1, 2
 order by 1, 2
 
 -- Catégories 
SELECT Category
		, od."sub-category"
		, sum(amount) as total_sales
        , sum(profit) as total_profit
from list_of_orders loo
INNER join order_details od 
	on loo.order_id = od.order_id
 group by 1, 2




 -- MISSION 3

 -- Meilleurs clients (on peut remplacer customername par state pour les états)
SELECT customername
		, count(distinct loo.order_id) as nb_orders
		, sum(amount) as total_sales
        , sum(profit) as total_profit
from list_of_orders loo
INNER join order_details od 
	on loo.order_id = od.order_id
 group by 1
 order by 3 desc


   -- Panier moyen 
with sales_per_order as 
    (
    select od.order_id
      		, loo.month
      		, loo.year
            , sum(amount) as total_price
    from list_of_orders loo
	INNER join order_details od 
		on loo.order_id = od.order_id
    group by 1
    )
select sales_per_order.year
		, sales_per_order.month
        , round(avg(total_price), 2) as average_basket
from sales_per_order
group by 1, 2


 -- MISSION 4 



 -- Évolution des profits 
SELECT loo.YEAR
        , loo.month
        -- , target
		-- , sum(amount) as total_sales
        , sum(profit)
from list_of_orders loo
INNER join order_details od 
	on loo.order_id = od.order_id
group by 1, 2



-- sous catégories non rentables 
SELECT "sub-category"
		, count(distinct loo.order_id) as nb_orders
		, sum(amount) as total_sales
        , sum(profit) as total_profit
from list_of_orders loo
INNER join order_details od 
	on loo.order_id = od.order_id
 group by 1
having total_profit < 0

-- évolution rentabilité sous-catégories
SELECT "sub-category"
		, loo.year
        , loo.month
		, count(distinct loo.order_id) as nb_orders
		, sum(amount) as total_sales
        , sum(profit) as total_profit
from list_of_orders loo
INNER join order_details od 
	on loo.order_id = od.order_id
 group by 1, 2, 3


-- MISSION 5


WITH table_sales_target AS 
      (
      SELECT od.category
              , loo.YEAR
              , loo.month
              , target
              , sum(amount) as total_sales
      from list_of_orders loo
      INNER join order_details od 
          on loo.order_id = od.order_id
      inner join sales_target st
          on od.category = st.category
          and loo.month = st.month
          AND loo.year = st.year 
      group by 1, 2, 3, 4
      ), 
    table_diff_target AS 
    (
      select *
            , case 
                  when total_sales between target*0.97 and target*1.03 then 'on_target'
                  when total_sales > target*1.03 THEN 'above_target'
                  ELSE 'below_target'
                END AS diff_w_target
      from table_sales_target
      )
select category
		, diff_w_target
        , count(*) as nb_months
from table_diff_target
group by 1, 2