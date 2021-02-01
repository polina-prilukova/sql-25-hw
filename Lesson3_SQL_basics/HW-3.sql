--Основная часть:
--выведите магазины, имеющие больше 300-от покупателей
select s.store_id, count(c.customer_id) 
from store s
inner join customer c on c.store_id = s.store_id 
group by s.store_id
having count(c.customer_id) > 300

--выведите у каждого покупателя город в котором он живет
select concat(c.last_name, ' ', c.first_name) full_name, city.city 
from customer c 
inner join address a on c.address_id = a.address_id 
inner join city on a.city_id = city.city_id 
order by c.last_name 


--Дополнительная часть:
--выведите ФИО сотрудников и города магазинов, имеющих больше 300-от покупателей
select s2.last_name FIO, city.city
from store s 
join address a on s.address_id = a.address_id 
join city on a.city_id = city.city_id
join staff s2 on s2.store_id = s.store_id 
where s.store_id in 
	(select s.store_id
	from store s
	inner join customer c on c.store_id = s.store_id 
	group by s.store_id
	having count(c.customer_id) > 300) 
	
-- выведите количество актеров, снимавшихся в фильмах, которые сдаются в аренду за 2,99
select fa.film_id, count(a.actor_id) actors_number
from actor a 
inner join film_actor fa on a.actor_id = fa.actor_id 
inner join 
	(select f.film_id
	from film f 
	where f.rental_rate = 2.99) as f2 on fa.film_id = f2.film_id
group by fa.film_id	
order by fa.film_id 
