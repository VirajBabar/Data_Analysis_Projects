
Select * from artworks_cleaned
select * from Artists_staging

-- KPIs

-- 1. Total Number of Unique Artist
select Count(*) from Artists_staging
-- 15636


-- 2. Total Number of Artworks
select count(distinct ObjectID) from artworks_cleaned
-- 157630


-- 3. Gender Distribution
select Gender, count(*) as Count_of_gender
from Artists_staging
group by Gender
order by Count_of_gender desc




-------------------------------------------------------------------------------------------------------------------



-- 1. HOW MODERN ARE THE ARTWORKS AT THE MUSEUM?

-- first lets check the range of the years of artworks

select min(cleaned_date)
from artworks_cleaned

select max(cleaned_date)
from artworks_cleaned

select max(cleaned_date) - min(cleaned_date)
from artworks_cleaned

-- we will categorise the year in to 5 categories
-- before 1800 - Pre-1800
-- 1800 to 1899 - 19th Century
-- 1900 to 1945 - Early Modern
-- 1946 to 1980 - Post war
-- 1981 to present - Contemporary

select 
	case
		when cleaned_date < 1800 then 'Pre-1800 (before 1800)'
		when cleaned_date between 1800 and 1899 then '19th Century (1800 to 1899)'
		when cleaned_date between 1900 and 1945 then 'Early Modern (1900 to 1945)'
		when cleaned_date between 1946 and 1980 then 'Post war (1946 to 1980)'
		when cleaned_date >= 1981 then 'Contemporary (after 1981)'
		else 'Unknown'
	end as [Period],
	count(distinct(ObjectID)) as Artwork_count
from artworks_cleaned
group by 
		case
			when cleaned_date < 1800 then 'Pre-1800 (before 1800)'
			when cleaned_date between 1800 and 1899 then '19th Century (1800 to 1899)'
			when cleaned_date between 1900 and 1945 then 'Early Modern (1900 to 1945)'
			when cleaned_date between 1946 and 1980 then 'Post war (1946 to 1980)'
			when cleaned_date >= 1981 then 'Contemporary (after 1981)'
			else 'Unknown'
		end
order by Artwork_count desc



-- lets calculate the percentage of modern Artwork 
go
with ArtworkPeriod as(
select 
	case
		when cleaned_date < 1800 then 'Pre-1800 (before 1800)'
		when cleaned_date between 1800 and 1899 then '19th Century (1800 to 1899)'
		when cleaned_date between 1900 and 1945 then 'Early Modern (1900 to 1945)'
		when cleaned_date between 1946 and 1980 then 'Post war (1946 to 1980)'
		when cleaned_date >= 1981 then 'Contemporary (after 1981)'
		else 'Unknown'
	end as [Period],
	count(distinct(ObjectID)) as Artwork_count
from artworks_cleaned
group by 
		case
			when cleaned_date < 1800 then 'Pre-1800 (before 1800)'
			when cleaned_date between 1800 and 1899 then '19th Century (1800 to 1899)'
			when cleaned_date between 1900 and 1945 then 'Early Modern (1900 to 1945)'
			when cleaned_date between 1946 and 1980 then 'Post war (1946 to 1980)'
			when cleaned_date >= 1981 then 'Contemporary (after 1981)'
			else 'Unknown'
		end
)

select 'Modern Artwork (1900 and after)' as Category,
		sum(Artwork_count) as TotalModernArtworks,
		round(100.0 * sum(Artwork_count) / (select sum(Artwork_count) from ArtworkPeriod), 2) as PercentageOfModernArtwork
from ArtworkPeriod
where [Period] in ('Early Modern (1900 to 1945)', 'Post war (1946 to 1980)', 'Contemporary (after 1981)')


-----------------------------------------------------------------------------------------------------------------------------------------------------


-- 2. WHICH ARTIST ARE FEATURED THE MOST?

select * from artworks_cleaned

-- overall top 10 Artist by total artwork.
go
with artist_cte as(
select ar.DisplayName, 
		count(ObjectID) as total_artwork,
		rank() over (order by count(ObjectID) desc) as ranking 
from artworks_cleaned aw
inner join Artists_staging ar
on aw.ConstituentID = ar.ConstituentID
group by ar.DisplayName
--order by total_artwork desc
)

select Displayname,
		total_artwork
from artist_cte
where ranking <= 10


-- Classification wise top 3 artist by total artwork
go
with Top_artist_by_classification_cte as (
select aw.[Classification],
		ar.DisplayName,
		count(ObjectID) as total_artwork,
		row_number() over (partition by aw.[Classification] order by count(ObjectID) desc) as ranking
from artworks_cleaned aw
inner join Artists_staging ar
on aw.ConstituentID = ar.ConstituentID
group by aw.[Classification], ar.DisplayName
)

select *
from Top_artist_by_classification_cte
where ranking <= 3


-- Department wise top 3 artist by total artwork
go
with Top_artist_by_department_cte as (
select aw.Department,
		ar.DisplayName,
		count(*) as total_artwork,
		row_number() over (partition by aw.Department order by count(*) desc) as ranking
from artworks_cleaned aw
inner join Artists_staging ar
on aw.ConstituentID = ar.ConstituentID
group by aw.Department, ar.DisplayName
)

select *
from Top_artist_by_department_cte
where ranking <= 3


-------------------------------------------------------------------------------------------------------------------------------------------------------


-- 3. ARE THERE ANY TRENDS IN THE DATES OF ACQUISITION

select count(*) as null_count
from artworks_cleaned
where DateAcquired is null

select min(DateAcquired)
from artworks_cleaned

select max(DateAcquired)
from artworks_cleaned

-- Year wise artwork acquired

select 
    acquisition_year,
    count(*) as total_acquired
from (
    select distinct 
        ObjectID,
        year(DateAcquired) as acquisition_year
    from artworks_cleaned
    where DateAcquired is not null
) as distinct_artworks
group by acquisition_year
order by acquisition_year;


-- decade wise artwork acquired

select 
    Decade,
    count(*) as Total_Acquired
from (
    select distinct 
        ObjectID,
        (year(DateAcquired) / 10) * 10 as Decade
    from artworks_cleaned
    where DateAcquired IS NOT NULL
) as distinct_artworks
group by Decade
order by Decade;




-------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 4. WHAT TYPES OF ARTWORK ARE MOST COMMON

-- classification wise
select [Classification],
	count(*) as total_artwork
from (
    select distinct 
        ObjectID,
        [Classification]
    from artworks_cleaned
) as distinct_artworks
group by [Classification]
order by total_artwork desc


-- department wise
select Department,
	count(*) as total_artwork
from (
    select distinct 
        ObjectID,
        Department
    from artworks_cleaned
) as distinct_artworks
group by Department
order by total_artwork desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 5. TOP 5 NATIONALITY WHICH HAS MOST ARTWORK PER DECADE
-- incorrect query
go
with top_nationality_artwrok_cte as(
select (cast(year(DateAcquired) as int) / 10) * 10 as Decade,
		ar.Nationality,
		count(aw.ObjectID) as Artwork_count,
		row_number() over (partition by (cast(year(DateAcquired) as int) / 10) * 10 order by count(aw.ObjectID) desc) as ranking
from artworks_cleaned aw
inner join Artists_staging ar
on aw.ConstituentID = ar.ConstituentID
group by (cast(year(DateAcquired) as int) / 10) * 10, ar.Nationality
having (cast(year(DateAcquired) as int) / 10) * 10 is not null
)

select Decade, nationality, Artwork_count
from top_nationality_artwrok_cte
where ranking <= 5


-- Null check
select ObjectID
from artworks_cleaned
where ObjectID is null

-- Null check
select DateAcquired
from artworks_cleaned
where DateAcquired is null

-- correct query
go
with Unique_Artwork_CTE as(
select distinct
		(cast(year(DateAcquired)as int) / 10) * 10 as decade, 
		Nationality,
		ObjectID
from artworks_cleaned aw
inner join Artists_staging ar
on aw.ConstituentID = ar.ConstituentID
where DateAcquired is not null
),

Top_nationalities_CTE as(
select decade,
		Nationality,
		count(*) as total_artwork,
		row_number() over (partition by decade order by count(*) desc) as ranking
from Unique_Artwork_CTE
group by decade, Nationality
)

select decade, Nationality, total_artwork
from Top_nationalities_CTE
where ranking <= 5