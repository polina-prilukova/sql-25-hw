-- Основная часть
-- 1. Сделайте запрос к таблице rental. 
-- Используя оконую функцию добавьте колонку с порядковым номером аренды для каждого пользователя (сортировать по rental_date)

select r.rental_id , r.rental_date, r.customer_id,
row_number() over (partition by r.customer_id order by r.rental_date) as row_n
from rental r;

--2. Для каждого пользователя подсчитайте сколько он брал в аренду фильмов со специальным атрибутом Behind the Scenes
-- 2.1 напишите этот запрос
-- 2.2 создайте материализованное представление с этим запросом
-- 2.3 обновите материализованное представление
-- 2.4 напишите три варианта условия для поиска Behind the Scenes

-- 2.1 запрос. Чтобы учесть всех пользователей, в том числе тех, которые возможно не брали фильмы с атрибутом Behind the Scenes
-- берем все customer_id из таблицы customer и соединим с подзапросом, в котором считается количество нужных фильмов

select c.customer_id, concat(c.last_name,' ', c.first_name) FIO, 
case 
	when ff.film_cnt is not null then ff.film_cnt
	else 0
end film_cnt
from customer c 
left join 
	(select r.customer_id , count(i.film_id) film_cnt
	from rental r
	join inventory i on r.inventory_id  = i.inventory_id
	where i.film_id in (
		select f.film_id  
		from film f
		where array_position(f.special_features, 'Behind the Scenes') is not null)
	group by r.customer_id) as ff
on c.customer_id = ff.customer_id
order by c.customer_id 

-- Execution time: 12.964 ms


-- 2.2 Создаем материализованное представление

create materialized view customers_with_BHS_film as
	select c.customer_id, concat(c.last_name,' ', c.first_name) FIO, 
	case 
		when ff.film_cnt is not null then ff.film_cnt
		else 0
	end film_cnt
	from customer c 
	left join 
		(select r.customer_id , count(i.film_id) film_cnt
		from rental r
		join inventory i on r.inventory_id  = i.inventory_id
		where i.film_id in (
			select f.film_id  
			from film f
			where array_position(f.special_features, 'Behind the Scenes') is not null)
		group by r.customer_id) as ff
	on c.customer_id = ff.customer_id
	order by c.customer_id
with no data

-- 2.3 обновим материализованное представление 
refresh materialized view customers_with_BHS_film

select * from customers_with_BHS_film

-- 2.4 три варианта условия для поиска Behind the Scenes

-- 1) использованный в запросе
where array_position(f.special_features, 'Behind the Scenes') is not null)
 
-- 2)
select f.film_id, f.title, f.special_features  
from film f
where 'Behind the Scenes' = any(f.special_features)

-- 3)
select f.film_id, f.title, f.special_features  
from film f
where  special_features @> array['Behind the Scenes']

