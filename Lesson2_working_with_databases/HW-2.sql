-- �������� �����
-- ����������� ��� ������� � ��������� ����� � ���� ������. 

-- |��� �������	  | ��������� ����
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


-- ������� ���� ���������� �����������
select customer_id, last_name, first_name, email 
from customer 
where active = 0
order by last_name, first_name; 

-- ������� ��� ������, ���������� � 2006 ����
select title, description, release_year 
from film 
where release_year = 2006
order by title;

-- ������� 10 ��������� �������� �� ������ �������.
select payment_id, customer_id, amount, payment_date 
from payment 
order by payment_date desc
limit 10;

-- �������������� �����
-- ������� ��������� ����� ����� ������. ��� ��������� �������� ������� ������ ��������������� information_schema.table_constraints
select tc.table_name, kc.column_name
from information_schema.table_constraints tc
  join information_schema.key_column_usage kc 
    on kc.table_name = tc.table_name and kc.constraint_name = tc.constraint_name
where tc.constraint_type = 'PRIMARY KEY'
order by tc.table_name;
        
-- ��������� ������ � ���������� �������, ������� ���������� �� ���� ������ information_schema.columns
select tc.table_name, kc.column_name, ic.data_type 
from information_schema.table_constraints tc
  join information_schema.key_column_usage kc 
    on kc.table_name = tc.table_name and kc.constraint_name = tc.constraint_name
  join information_schema.columns ic 
    on tc.table_name = ic.table_name and kc.column_name = ic.column_name 
where tc.constraint_type = 'PRIMARY KEY'
order by tc.table_name;
