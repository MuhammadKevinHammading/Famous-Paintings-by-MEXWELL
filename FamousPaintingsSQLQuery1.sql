
select top(10)*
from painting..artist

select top(10)*
from painting..canvas_size

select top(10)*
from painting..image_link

select top(10)*
from painting..museum

select top(10)*
from painting..museum_hours

select top(10)*
from painting..product_size

select top(10)*
from painting..subject

select top(10)*
from painting..work

-- Q1: Are there paintings that are not displayed on any museums?
select * 
from painting..work 
where museum_id is null


-- Q2: Are there museums without any paintings?
select * 
from painting..museum m
where not exists (
	select 1 
	from painting..work w
	where w.museum_id = m.museum_id)


-- Q3: How many paintings have an asking price of more than their regular price? 
select * 
from painting..product_size
where sale_price > regular_price

-- Q4: Identify the paintings whose asking price is less than 50% of its regular price
select * 
from painting..product_size
where sale_price < (regular_price*0.5)

-- Q5: Which canva size costs the most?
select label as canva, sale_price
from (
	select *,
	rank() over(order by sale_price desc) as rnk 
	from painting..product_size) ps
join painting..canvas_size cs 
on cs.size_id=ps.size_id
where ps.rnk=1					 

-- Q6: Delete duplicate records from work, product_size, subject and image_link tables
with cte as (
	select *, 
	row_number() over (partition by work_id, name, artist_id, style, museum_id order by work_id) as rnumber
	from painting..work)
delete
from cte
where rnumber > 1

with cte as (
	select *, 
	row_number() over (partition by work_id, size_id, sale_price, regular_price order by work_id) as rnumber
	from painting..product_size)
delete
from cte
where rnumber > 1


with cte as (
	select *, 
	row_number() over (partition by work_id, subject order by work_id) as rnumber
	from painting..subject)
delete
from cte
where rnumber > 1

with cte as (
	select *, 
	row_number() over (partition by work_id, url, thumbnail_small_url, thumbnail_large_url order by work_id) as rnumber
	from painting..image_link)
delete
from cte
where rnumber > 1

-- Q7: Identify the museums with invalid city information in the given dataset
select *
from painting..museum 
where isnumeric(city) = 1

-- Q8: Museum_Hours table has 1 invalid entry. Identify it and remove it.
select museum_id, day, [open], [close], count(*) as row_count
from painting..museum_hours
group by museum_id, day, [open], [close]
having count(*) > 1

with cte as (
	select *, 
	row_number() over (partition by museum_id, day order by museum_id) as rnumber
	from painting..museum_hours)
delete 
from cte
where rnumber > 1

-- Q9: Fetch the top 10 most famous painting subject
select * 
from (
	select subject, count(*) as no_of_paintings,
	rank() over(order by count(*) desc) as ranking
	from painting..work w
	join painting..subject s 
	on s.work_id = w.work_id
	group by subject) x
where ranking <= 10

-- Q10: Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select distinct m.name as museum_name, m.city, m.state,m.country
from painting..museum_hours mh 
join painting..museum m 
on m.museum_id = mh.museum_id
where day = 'Sunday'
and exists (
			select 1 
			from painting..museum_hours mh2 
			where mh2.museum_id = mh.museum_id 
			and mh2.day = 'Monday')

-- Q11: How many museums are open every single day?
select count(museum_count) as museum_count
from (
	select museum_id, 
	count(*) as museum_count
	from painting..museum_hours
	group by museum_id
	having count(1) = 7) x

-- Q12: Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
select name as museum, city, country, no_of_paintings
from (
	select m.museum_id, count(*) as no_of_paintings,
	rank() over(order by count(*) desc) as rnk
	from painting..work w
	join painting..museum m 
	on m.museum_id = w.museum_id
	group by m.museum_id) x
join painting..museum m 
on m.museum_id = x.museum_id
where x.rnk <= 5

-- Q13: Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select full_name as artist, nationality, no_of_paintings
from (
	select a.artist_id, count(*) as no_of_paintings
	, rank() over(order by count(*) desc) as rnk
	from painting..work w
	join painting..artist a 
	on a.artist_id = w.artist_id
	group by a.artist_id) x
join painting..artist a 
on a.artist_id = x.artist_id
where x.rnk <= 5

-- Q14: Display the 3 least popular canva sizes
select label, ranking, no_of_paintings
from (
	select cs.size_id, label, count(*) as no_of_paintings,
	dense_rank() over(order by count(*) asc) as ranking
	from painting..work w
	join painting..product_size ps 
	on ps.work_id = w.work_id
	join painting..canvas_size cs 
	on cast(cs.size_id as varchar(max)) = ps.size_id
	group by cs.size_id, label) x
where x.ranking <= 3

-- Q15: Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
select name as museum_name, state, duration_time, day
from (
	select museum_id, day, 
	format(try_cast(stuff([open], 6, 1, ' ')as datetime), 'hh:mm tt') as open_time,
	format(try_cast(stuff([close], 6, 1, ' ')as datetime), 'hh:mm tt') as close_time,
	format(try_cast(stuff([close], 6, 1, ' ')as datetime)-try_cast(stuff([open], 6, 1, ' ')as datetime), 'hh:mm') as duration_time,
	rank() over (order by (format(try_cast(stuff([close], 6, 1, ' ')as datetime)-try_cast(stuff([open], 6, 1, ' ')as datetime), 'hh:mm')) desc) as rnk
	from painting..museum_hours) bq
join painting..museum m
on bq.museum_id = m.museum_id
where rnk = 1

-- Q16: Which museum has the most no of most popular painting style?
with pop_style as (
		select style, 
		count(*) as style_count,
		rank() over(order by count(*) desc) as rnk
		from painting..work
		group by style),
	pop_museum as (
		select w.museum_id, m.name as museum_name, ps.style, 
		count(*) as painting_count,
		rank() over (order by count(*) desc) as rnk
		from painting..work w
		join painting..museum m
		on w.museum_id = m.museum_id
		join pop_style ps
		on w.style = ps.style
		where w.museum_id is not null and ps.rnk = 1
		group by w.museum_id, m.name, ps.style)
select museum_id, museum_name, style, painting_count
from pop_museum
where rnk = 1

-- Q17: Identify the artists whose paintings are displayed in multiple countries
select artist, count(*) as no_of_painting
from (
	select distinct full_name as artist, country
	from painting..work w
	join painting..museum m
	on w.museum_id = m.museum_id
	join painting..artist a
	on w.artist_id = a.artist_id) bq
group by artist
having count(*) > 1
order by 2 desc

-- Q18: Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
with country as (
	select country, count(*) as museum_count,
	rank() over (order by count(*) desc) as rnk_country
	from painting..museum
	group by country),
city as (
	select city, count(*) as city_count,
	rank() over (order by count(*) desc) as rnk_city
	from painting..museum
	group by city)
select country, 
string_agg(ci.city,', ') as city
from country co
cross join city ci
where rnk_country = 1
and rnk_city = 1
group by country

-- Q19: Identify the artist and the museum where the most expensive and least expensive painting is placed. Display the artist name, sale_price, painting name, museum name, museum city and canvas label
with cte as (
	select *, 
	rank() over(order by sale_price desc) as rnk_desc, 
	rank() over(order by sale_price ) as rnk_asc
	from painting..product_size)
select distinct w.name as painting, sale_price, a.full_name as artist, m.name as museum, m.city, cs.label as canvas
from cte
join painting..work w on w.work_id = cte.work_id
join painting..museum m on m.museum_id=w.museum_id
join painting..artist a on a.artist_id=w.artist_id
join painting..canvas_size cs on cast(cs.size_id as varchar(max)) = cte.size_id
where rnk_desc = 1 or rnk_asc = 1

-- Q20: Which country has the 5th highest no of paintings?
with cte as (
	select country, count(*) as no_of_Paintings,
	rank() over(order by count(*) desc) as rnk
	from painting..work w
	join painting..museum m 
	on m.museum_id = w.museum_id
	group by m.country)
select country, no_of_Paintings
from cte 
where rnk = 5

-- Q21: Which are the 3 most popular and 3 least popular painting styles?
with cte as 
	(select style, count(*) as pop_count,
	rank() over(order by count(*) desc) rnk,
	count(*) over() as no_of_records
	from painting..work
	where style is not null
	group by style)
select style,
case when rnk <= 3 then 'Most Popular' else 'Least Popular' end as remarks 
from cte
where rnk <= 3 or rnk > no_of_records - 3

-- Q22: Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
select full_name as artist_name, nationality, no_of_paintings
from (
	select full_name, nationality,
	count(*) as no_of_paintings,
	rank() over(order by count(*) desc) as rnk
	from painting..work w
	join painting..artist a on a.artist_id = w.artist_id
	join painting..subject s on s.work_id = w.work_id
	join painting..museum m on m.museum_id = w.museum_id
	where subject = 'Portraits'
	and country != 'USA'
	group by full_name, nationality) x
where rnk = 1	
