-- Основная часть
-- перечислить все таблицы и первичные ключи в базе данных. 

-- |Имя таблицы	  | Первичный ключ
------------------------------------------
-- |actor 	      | actor_id
-- |address	      | address_id
-- |category 	  | category_id
-- |city 	      | city_id
-- |country 	  | country_id
-- |customer 	  | customer_id
-- |film 	      | film_id
-- |film_actor 	  | actor_id, film_id
-- |film_category |	film_id,  category_id
-- |inventory 	  | inventory_id
-- |language 	  | language_id
-- |payment 	  | payment_id
-- |rental 	      | rental_id
-- |staff 	      | staff_id
-- |store 	      | store_id


-- Вывести всех неактивных покупателей
select customer_id, last_name, first_name, email 
from customer 
where active = 0
order by last_name, first_name; 

-- вывести все фильмы, выпущенные в 2006 году
select title, description, release_year 
from film 
where release_year = 2006
order by title;

-- вывести 10 последних платежей за прокат фильмов.
select payment_id, customer_id, amount, payment_date 
from payment 
order by payment_date desc
limit 10;

-- Дополнительная часть
-- вывести первичные ключи через запрос. Для написания простого запроса можете воспользоваться information_schema.table_constraints
select tc.table_name, kc.column_name
from information_schema.table_constraints tc
  join information_schema.key_column_usage kc 
    on kc.table_name = tc.table_name and kc.constraint_name = tc.constraint_name
where tc.constraint_type = 'PRIMARY KEY'
order by tc.table_name;
        
-- расширить запрос с первичными ключами, добавив информацию по типу данных information_schema.columns
select tc.table_name, kc.column_name, ic.data_type 
from information_schema.table_constraints tc
  join information_schema.key_column_usage kc 
    on kc.table_name = tc.table_name and kc.constraint_name = tc.constraint_name
  join information_schema.columns ic 
    on tc.table_name = ic.table_name and kc.column_name = ic.column_name 
where tc.constraint_type = 'PRIMARY KEY'
order by tc.table_name;
