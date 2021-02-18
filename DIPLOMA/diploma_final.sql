-- 1. В каких городах больше одного аэропорта?

/* Потребуется таблица airports. 
 * Здесь достаточно сделать группировку по city и поставить условие, в котором количество сгруппированных по городу записей будет больше 1*/

select a.city
from airports a 
group by a.city 
having count(*)>1

--Execution Time: 0.129 ms

-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

/* Потребуются таблицы: aircrafts, flights, airports. 
 * В подзапросе выбираю самолет, у которого дальность перелета (атрибут "range") максимальная,
 * для этого использую еще один маленький подзапрос, чтобы сравнивать дальности каждого самолета с максимальной из имеющихся.
 * Результат выполнения подзапроса - код самолета с максимальной допустимой дальностью. 
 * Чтобы получить аэропорт, в котором есть рейсы с этим самолетом, связываю таблицу airports с flights.
 * Т.к. нас устроит и аэропорт прибытия, и аэропорт отправления, использую ИЛИ в соединении.
 * Накладываю условие: код самолета f.aircraft_code, задействованного в рейсе, равен результату из подзапроса */

 
select distinct concat(a.airport_name, ' (', a.airport_code, ')') airport 
from airports a
join flights f on f.arrival_airport = a.airport_code or f.departure_airport = a.airport_code 
where f.aircraft_code = (
	select a.aircraft_code 
	from aircrafts a
	where a."range" = (select max(a2."range") from aircrafts a2))
order by airport	

--Execution Time: 22.263 ms


-- 3. Вывести 10 рейсов с максимальным временем задержки вылета

/* Потребуется таблица flights.
 * Чтобы иметь возможность посчитать время задержки как разницу между фактическим и запланированным временем вылета, 
 * выбираю те записи, у которых sheduled_departure и actual_departure не есть null.
 * Добавляю столбец с разницей actual_departure и sheduled_departure, 
 * сортирую таблицу по убыванию значений этого столбца, с помощью limit оставляю необходимые 10 записей
 */


select f.flight_id, f.flight_no, f.actual_departure - f.scheduled_departure delay_time
from flights f
where f.actual_departure is not null and f.scheduled_departure is not null
order by delay_time desc limit 10

--Execution Time: 11.778 ms


-- 4. Были ли брони, по которым не были получены посадочные талоны?

/* Потребуются таблицы: boarding_passes, bookings, tickets.
 * Можно однозначно определить бронирования, по которым посадочные талоны есть, соединив через inner join таблицы boarding_passes и tickets, 
 * в которой храниится информация в том числе и об идентификаторе бронирования. Помещаю эту конструкцию в подзапрос.
 * Соответственно, бронирования, по которым посадочных талонов нет в силу любых причин - это все остальные бронирования. 
 * Их мы можно получить, соединив с помощью left join таблицу bookings и подзапрос с условием, что идентификатор бронирования из подзапроса есть null.
 * Так мы из множества всех бронирований без исключения уберем бронирования с посадочными талонами, и останется то, что требуется.
 * */

select b.book_ref 
from bookings b
left join 
	(select distinct t.book_ref 
	from tickets t
	inner join boarding_passes bp on t.ticket_no = bp.ticket_no) bb
on b.book_ref = bb.book_ref
where bb.book_ref is null
order by b.book_ref

--Execution Time: 2070.000 ms


-- 5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.

/* Потребуются таблицы: boarding_passes, flights, seats
 * Чтобы найти свободные места для каждого рейса, необходимо знать, на сколько мест рассчитана модель самолета, выполняющего перелет, и на сколько мест выданы посадочные талоны.
 * Чтобы узнать, сколько мест в определенной модели самолета, обращаюсь к таблице seats, выполняю группировку по полю aircraft_code.
 * Помещаю эту конструкцию в подзапрос (sts)
 * Чтобы узнать, на сколько мест выданы посадочные талоны, соединяю таблицы boarding_passes и flights, 
 * через группировку считаю общее количество мест из всех посадочных талонов на каждый flight_id.
 * Использую в соединении inner join, чтобы получить именно те рейсы, для которых нашлись посадочные талоны, т.е. расчетное количество занятых мест будет больше 0.
 * Помещаю эту конструкцию в подзапрос (bkd) 
 * Соединяю таблицу flights и подзапрос bkd по flight_id, flights и подзапрос sts по aircraft_code.
 * Теперь для каждого flight_id рассчитывается количество свободных мест sts.seats_cnt - bkd.seats_booked as empty_seats
 * и процент свободных мест round(((sts.seats_cnt - bkd.seats_booked)::numeric/sts.seats_cnt)*100, 2) as percent_empty_seats.
 * Т.к. как количество мест - это целое число, привожу его к типу numeric, чтобы функция round отработала корректно.
 * Чтобы получить суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день, создаю оконную функцию, 
 * которая будет рассчитывать сумму seats_booked - количество занятых пассажирами мест на рейсе, оно рассчитано для каждого рейса в подзапросе bkd
 * Группировка в окне производится по столбцам departure_airport и actual_departure, причем от момента вылета с помощью date() оставлена только дата без указания времени
 * Сортировка в окне производится по моменту вылета actual_departure (здесь оставлена дата с указанием времени).*/

select f.departure_airport, date(f.actual_departure), f.flight_id, 
sts.seats_cnt - bkd.seats_booked as empty_seats,
round(((sts.seats_cnt - bkd.seats_booked)::numeric/sts.seats_cnt)*100, 2) as percent_empty_seats,
bkd.seats_booked,
sum(bkd.seats_booked) over (partition by  date(f.actual_departure), f.departure_airport order by f.actual_departure) as cum_total_seats
from flights f 
join (select f.flight_id, count(bp.seat_no) as seats_booked
	from boarding_passes bp 
	join flights f on f.flight_id = bp.flight_id 
	group by f.flight_id) as bkd
on f.flight_id = bkd.flight_id
join (select s.aircraft_code, count(*) as seats_cnt 
	from seats s 
	group by s.aircraft_code) as sts
on sts.aircraft_code = f.aircraft_code

--Execution Time: 461.995 ms

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.

/* Потребуются таблицы: aircrafts, flights
 * Обращаюсь к таблице aircrafts, чтобы учесть все модели самолетов, даже те, по которым возможно нет записей во flights
 * Чтобы рассчитать процент, надо узнать количество перелетов, совершенных этой моделью и общее количество перелетов. 
 * Общее количество считаю подзапросом (select count(*) from flights f) 
 * Количество перелетов конкретной модели - подзапросом select count(*) from flights f where f.aircraft_code = a.aircraft_code,
 * и здесь в условии where указываю aircraft_code из внешнего запроса.
 * Т.к. количество мест - это целое число, привожу его к типу numeric, чтобы функция round отработала корректно*/

select a.aircraft_code,
	round(((select count(*) from flights f where f.aircraft_code = a.aircraft_code)::numeric/(select count(*) from flights f))*100, 2) as percent_aircraft_flights
from aircrafts a
order by a.aircraft_code

--Execution Time: 62.212 ms


-- 7. Были ли города, в которые можно  добраться бизнес-классом дешевле, чем эконом-классом в рамках перелета?

/* Потребуются таблицы: ticket_flights, flights, airports
 * Создаю СТЕ cte_business - здесь будут собраны данные о идентификаторах и стоимостях перелетов бизнес-классом.
 * Создаю СТЕ cte_economy - здесь будут собраны данные о идентификаторах и стоимостях перелетов эконом-классом. 
 * Соединяю 2 таблицы из этих СТЕ по условию совпадения flight_id и условию cte_economy.amount > cte_business.amount.
 * Т.е. в результат должны попасть идентификаторы тех перелетов, для каждого из которых найдены такие стоимости билетов, что бизнес-класс стоит меньше эконома в рамках 1го перелета.
 * Далее соединяю результат с таблицей flights, чтобы получить код аэропорта прибытия,
 * и с таблицей airports, чтобы для кода аэропорта прибытия получить город, в котором он расположен.
 * Как результат вывожу список уникальных значений полученых городов. 
 * Конкретно в этом примере список получается пустой, т.е. ответ на поставленный вопрос - таких городов не было.
 * */

with cte_business as (
	select tf.flight_id, tf.ticket_no, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Business'),
cte_economy as (
	select tf.flight_id, tf.ticket_no, tf.amount 
	from ticket_flights tf 
	where tf.fare_conditions = 'Economy')
select distinct a.city
from cte_business 
join cte_economy on cte_business.flight_id = cte_economy.flight_id and cte_economy.amount > cte_business.amount
join flights f on cte_business.flight_id = f.flight_id 
join airports a on f.arrival_airport = a.airport_code

--Execution Time: 3388.420 ms

-- 8. Между какими городами нет прямых рейсов?

/* Потребуются таблицы: flights, airports
 * Чтобы узнать, между какими городами нет прямых рейсов, необходимо получить все возможные комбинации 2х городов, каждый с каждым, и из эттих пар городов убрать те, 
 * между которыми найдутся связующие рейсы в таблице flights.
 * Создаю представление direct_flights, в котором из каждой записи flights беру город аэропорта отправления и город аэропорта прибытия. 
 * Сделав группировку по этм городам получаю уникальные пары всех возможных прямых маршрутов.
 */

create view direct_flights as
	select a1.city dep_city, a2.city arr_city
	from flights f 
	join airports a1 on f.departure_airport = a1.airport_code 
	join airports a2 on f.arrival_airport = a2.airport_code
	group by dep_city, arr_city
	order by dep_city, arr_city
	
/* Чтобы получить все возможные пары городов, использую декартово произведение во from, сопостовляю города из таблицы airports.
 * Добавляю условие, которое выкинет пары с одинаковыми городами, они не несут смысла для текущей задачи.
 * С помощью except исключаю записи с прямыми рейсами, полученными из представления
 */

select a1.city dep_city, a2.city arr_city
from airports a1, airports a2 
where a1.city != a2.city 
except 
select df.dep_city, df.arr_city from direct_flights df 
order by dep_city, arr_city

--Execution Time: 118.293 ms

-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов в самолетах, обслуживающих эти рейсы
-- d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}
-- L = d·R, где R = 6371 км — средний радиус земного шара


/* Потребуются таблицы: flights, airports, aircrafts.
 * Вначале в подзапросе из таблицы flights получаю коды аэропортов отправления и прибытия на прямых рейсах, 
 * а так же из присоединенной таблицы aircrafts беру код модели самолета, осуществляющего перелет и его допустимую дальность полета.
 * Возможны ситуации, когда одинаковый маршрут (например Владикавказ - Москва) осуществляется разными моделями самолетов.
 * С учетом этого подзапрос собирает все возможные различные комбинации прямых рейсов и самолетов, которые их совершают.
 * Чтобы получить широту и долготу для расчета расстояния между городами, связываю подзапрос с таблицей airports. 
 * Т.к. одна строка в подзапросе содержит два различных внешних ключа из airports, соединяю подзапрос с airports дважды. Получаю координаты конечных точек каждого маршрута.
 * Географические широта и долгота представлены в градусах, поэтому в формуле использую функции sind и cosd, которые принимают как аргумент значение в градуах, а не в радианах.
 * для каждого рейса рассчитываю по формуле расстояние между городами, привожу к типу данных numeric для округления через round(), округляю значение.
 * Рассчитываю значение разности между допустимой дальностью перелета и полученным расстоянием.
 * Чтобы сравнить расстояние между аэропортами с допустимыми значениями перелета добавлю столбец over_range_limit со значениями типа boolean: 
 * если расстояние больше допустимого значения перелета, записываю в over_range_limit значение True, иначе False
 * */
 
select 
	a1.city dep_city, a2.city arr_city, 
	round((acos(sind(a1.latitude)*sind(a2.latitude) + cosd(a1.latitude)*cosd(a2.latitude)*cosd(a1.longitude - a2.longitude))*6341)::numeric, 2) distance,
	aa.aircraft_code, aa."range",
	aa."range" - round((acos(sind(a1.latitude)*sind(a2.latitude) + cosd(a1.latitude)*cosd(a2.latitude)*cosd(a1.longitude - a2.longitude))*6341)::numeric, 2) difference,
	case 
		when aa."range" - round((acos(sind(a1.latitude)*sind(a2.latitude) + cosd(a1.latitude)*cosd(a2.latitude)*cosd(a1.longitude - a2.longitude))*6341)::numeric, 2) >= 0 then false
		when aa."range" - round((acos(sind(a1.latitude)*sind(a2.latitude) + cosd(a1.latitude)*cosd(a2.latitude)*cosd(a1.longitude - a2.longitude))*6341)::numeric, 2) < 0 then true
	end as over_range_limit	
from
	(select 
	f.departure_airport dep_air, f.arrival_airport arr_air, a3.aircraft_code, a3."range"
	from flights f 
	join aircrafts a3 on a3.aircraft_code = f.aircraft_code
	group by f.departure_airport, f.arrival_airport, a3.aircraft_code, a3."range") aa
join airports a1 on aa.dep_air = a1.airport_code 
join airports a2 on aa.arr_air = a2.airport_code
order by dep_city, arr_city

-- Execution Time: 42.656 ms
	

