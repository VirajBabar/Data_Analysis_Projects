
select * from Artworks_staging

-- Droping Artist, ArtistBio, Nationality, BeginDate, EndDate, Gender columns
-- as they are already present in Artist table.
alter table Artworks_staging
drop column Artist, ArtistBio, Nationality, BeginDate, EndDate, Gender;



-- Droping few more columns which are irrelevant to our analysis.
alter table Artworks_staging
drop column Dimensions, CreditLine, AccessionNumber, Cataloged, ImageURL, OnView,
			Circumference_cm, Depth_cm, Diameter_cm, Length_cm, Weight_kg, Seat_Height_cm



-- Handling NULL values in Title Column.
Update Artworks_staging
set Title = 'Untitled'
where Title is null or Title = '-'



-- Removing leading and trailing spaces in title column.
Update Artworks_staging
set Title = trim(Title)

select * from Artworks_staging



-- Handling NULL values in ConstituentID column.
Update Artworks_staging
set ConstituentID = 0
where ConstituentID is null



-- There are some values in ConstituentID column which have multiple constitutentID lets put each of them in new rows
select 
    Title, 
    TRY_CAST(TRIM(value) AS INT) AS ConstituentID,
    [Date], 
    [Medium],
	[Classification],
	Department,
	DateAcquired,
	ObjectID,
	[URL],
	Height_cm,
	Width_cm,
	Duration_sec
into
    artworks_cleaned
from
    Artworks_staging
cross apply string_split(Artworks_staging.ConstituentID, ',');



select * from Artworks_staging
where Title = 'En Bloc'

select * from artworks_cleaned
where Title = 'En Bloc'

select * from Artworks_staging


-- Cleaning Date column
-- It contains string with year in it, so lets create a new column cleaned_date and extract only the year

select 
    [Date],
	substring([Date], patindex('%[1-2][0-9][0-9][0-9]%', [Date]), 4) as CleanedYear
from artworks_cleaned;

-- adding new column which extract 4 digit year part from Date Column.
alter table artworks_cleaned
add cleaned_date int

-- getting only 4 digit year part from the Date column.
update artworks_cleaned
set cleaned_date = try_cast(substring([Date], patindex('%[1-2][0-9][0-9][0-9]%', [Date]), 4) as int)

-- checking if the string pattern like Jan-29 is being converted to null as it doesnt have 4 digit year.
select * from artworks_cleaned
where ConstituentID = 24500

select * from artworks_cleaned
where cleaned_date is null

-- there is pattern in date column like jan-29.
-- we want to extract year part which is 29 that is 1929.

-- let us first trim extra spaces in date column
update artworks_cleaned
set [Date] = rtrim([Date])


select [Date],
	1900 + try_cast(right([date],2) as int)
from artworks_cleaned
where cleaned_date is null

update artworks_cleaned
set cleaned_date = 1900 + try_cast(right([date],2) as int)
where cleaned_date is null and [Date] like '%-[0-9][0-9]'


-- checking how many unique values in Medium column.
select count(distinct([Medium]))
from artworks_cleaned
-- I think it doesnt make any sense to clean the medium column. lets drop it.


-- cleaning Classification column
select * from artworks_cleaned
where [Classification] = 'not assigned'

update artworks_cleaned
set [Classification] = replace([Classification], '(', '')

update artworks_cleaned
set [Classification] = replace([Classification], ')', '')


-- lets clean ObjectID column
-- checking for nulls
select * from artworks_cleaned
where ObjectID is null

-- checking for duplicates
Select ObjectID, count(*)
from artworks_cleaned
group by ObjectID
having count(*) > 1

select * 
from artworks_cleaned
where ObjectID in(
	Select ObjectID
	from artworks_cleaned
	group by ObjectID
	having count(*) > 1
)
-- there are duplicate records in ObjectID column because preiously we have separated the values in constituentID column.


select * from artworks_cleaned


-- Checking for null in URL columns.
update artworks_cleaned
set [URL] = 'Not Available'
where [URL] is null


-- Dropping Date and medium Column

alter table artworks_cleaned
drop column [Date], [Medium]


--=========================================================================================================================================

-- Cleaning Artists_staging table

select * from artworks_cleaned
where ConstituentID = '0'

select * from Artists_staging


-- Dropping Wiki_QID and ULAN columns as they dont add much value and has more than 60% of missing data

alter table Artists_staging
drop column Wiki_QID, ULAN


-- previously we have replaced nulls in constituentID with zeros because the artwork didnt have the constituentID
-- lets add dummy row in Artists_staging wih constituentID = 0 and DisplayName = Unknown ...

insert into Artists_staging (ConstituentID, DisplayName, ArtistBio, Nationality, Gender, BeginDate, EndDate)
values (0, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 0, 0)

select * from Artists_staging


-- nationality has some missing values but we have country name is artistbio column.
-- we will try to extract country from artistbio column

alter table Artists_staging
add Extract_country nvarchar(max)

-- Checking if it correctly extract country or not
select ArtistBio,
	case 
    when charindex(',', ArtistBio) > 0 
		and charindex(' ', left(ArtistBio, charindex(',', ArtistBio) - 1)) = 0
		and charindex('-', left(ArtistBio, charindex(',', ArtistBio) - 1)) = 0
		and charindex('–', left(ArtistBio, charindex(',', ArtistBIo) - 1)) = 0
         then left(ArtistBio, charindex(',', ArtistBio) - 1)
    else null
  end
	as country
from Artists_staging
where Nationality is null
and ArtistBio is not null

-- extracting Country from ArtistBio columns in the new column
update Artists_staging
set Extract_country = left(ArtistBio, charindex(',', ArtistBio) - 1)
where Nationality is null
and ArtistBio is not null
and charindex(',', ArtistBio) > 0 
and charindex(' ', left(ArtistBio, charindex(',', ArtistBio) - 1)) = 0
and charindex('-', left(ArtistBio, charindex(',', ArtistBio) - 1)) = 0
and charindex('–', left(ArtistBio, charindex(',', ArtistBIo) - 1)) = 0


select * from Artists_staging
where Extract_country is not null

-- Finally extracting country from ArtistBio and upadating Nationality column

update Artists_staging
set Nationality = left(ArtistBio, charindex(',', ArtistBio) - 1)
where Nationality is null
and ArtistBio is not null
and charindex(',', ArtistBio) > 0 
and charindex(' ', left(ArtistBio, charindex(',', ArtistBio) - 1)) = 0
and charindex('-', left(ArtistBio, charindex(',', ArtistBio) - 1)) = 0
and charindex('–', left(ArtistBio, charindex(',', ArtistBIo) - 1)) = 0


select * from Artists_staging

-- we will drop artistbio column as it doesnt contain much information 
-- and whatever is there in artistsio is already there in nationality, begindate and enddate column

alter table Artists_staging
drop column ArtistBio


-- replacing Null values in Nationality column to 'unknown'

update Artists_staging
set Nationality = 'Unknown'
where Nationality is null


-- replacing Null values in Gender column to 'unknown'

update Artists_staging
set Gender = 'Unknown'
where Gender is null

select * from Artists_staging


-- replacing zeros in BirthYear and DeathYear column to null
update Artists_staging
set BirthYear = null
where BirthYear = '0'

alter table Artists_staging
alter column BirthYear int Null

alter table Artists_staging
alter column DeathYear int Null

update Artists_staging
set Deathyear = null
where DeathYear = '0'

alter table Artists_staging
drop column Extract_country

select * from artworks_cleaned
select * from Artists_staging