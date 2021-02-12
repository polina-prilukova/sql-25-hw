
-- создаем таблицы справочники. В каждой таблице будет суррогатный первичный ключ и поле с наименованием сущности. 
-- для наименований имеет смысл поставить ограничение not null - это поле должно быть заполнено. 
-- если таблицы останутся в таком виде, каждая из двух столбцов, можно было бы поставить на поля name ограничение unique, но если в дальнейшем
-- будем дополнять таблицы, то это ограничение может стать лишним 
-- например, если добавить в "народность" столбец "подгруппа" и создать записи вида ("name", "group"): (славяне, западные) и (славяне, южные)

create table lang(
language_id serial primary key,
language_name varchar(50) not null);

create table nationality(
nation_id serial primary key,
nation_name varchar(50) not null);

create table country(
country_id serial primary key,
country_name varchar(150) not null);

--создаем таблицы со связями
create table nation_country(
nation_id integer references nationality(nation_id),
country_id integer references country(country_id),
primary key(nation_id, country_id));

create table language_nation(
nation_id integer references nationality(nation_id),
language_id integer references lang(language_id),
primary key(nation_id, language_id));

-- заполним таблицы данными 
insert into lang (language_name)
select unnest(array['Русский','Немецкий','Эстонский','Итальянский','Финнский']);

insert into nationality (nation_name)
select unnest(array['Славяне','Германцы','Балты','Романцы','Финно-угры']);

insert into country (country_name)
select unnest(array['Россия','Австрия','Эстония','Швейцария','Финляндия']);

insert into nation_country (nation_id, country_id)
select unnest(array[1, 5, 2, 1, 3, 1, 4, 2, 5, 2]),
       unnest(array[1, 1, 2, 2, 3, 3, 4, 4, 5, 5]);

insert into language_nation (nation_id, language_id)
select unnest(array[1, 2, 3, 2, 3, 1, 4, 5]),
       unnest(array[1, 1, 1, 2, 3, 3, 4, 5]);
       
-- можно убедиться, что соблюдены заданные правила
-- 1. на одном языке может говорить несколько народностей
      
select l.language_name, count(ln2.nation_id) nation_count 
from lang l 
inner join language_nation ln2 on l.language_id = ln2.language_id
group by l.language_id; 

-- 2. одна народность может входить в несколько стран
select n.nation_name, count(nc.country_id) country_count
from nationality n 
inner join nation_country nc on n.nation_id = nc.nation_id 
group by n.nation_id; 

--3. каждая страна может состоять из нескольких народностей
select c.country_name, n.nation_name 
from country c 
inner join nation_country nc on c.country_id = nc.country_id 
inner join nationality n on nc.nation_id  = n.nation_id
order by c.country_name; 


-- добавим некоторые атрибуты в наши таблицы. Пусть в таблицу "Страна" будет добавлен признак "EUR" типа boolean, который будет показывать, перешла ли страна на евро или нет
-- Пусть в таблицу "Народность" будет добавлен признак "subgroup" типа text[], в котором будут перечислены некоторые подгруппы этой народности

alter table country add column EUR boolean;

update country 
set EUR = true 
where country_id in (2, 3, 5);

update country 
set EUR = false 
where country_id in (1, 4);

select * from country;

alter table nationality add column subgroup text[];

update nationality 
set subgroup = array['русские', 'украинцы']
where nation_id = 1;

update nationality 
set subgroup = array['немцы', 'скандинавы']
where nation_id = 2;

update nationality 
set subgroup = array['испанцы', 'итальянцы']
where nation_id = 4;

select * from nationality;