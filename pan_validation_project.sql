-- Use Database PAN;

-- Create the stage table to store original given dataset

drop table if exists public.pan_dataset;
create table public.pan_dataset
(
	pan_number text
);

select * from public.pan_dataset;

-- 1. Data Cleaning and Preprocessing:

-- 1.1 Identify and handle missing data: PAN numbers may have missing values.
--		These missing values need to be handled appropriately, either by
--		removing rows or imputing values (depending on the context).

 select * from public.pan_dataset where pan_number is not null or pan_number <> '';



-- 1.2 Check for duplicates: Ensure there are no duplicate PAN numbers. If
--		duplicates exist, remove them.

 select distinct pan_number from public.pan_dataset where pan_number is not null or pan_number <> '';



-- 1.3 Handle leading/trailing spaces: PAN numbers may have extra spaces
--		before or after the actual number. Remove any such spaces.

 select distinct trim (pan_number) as pan_number from public.pan_dataset where pan_number is not null or pan_number <> '';



-- 1.4 Correct letter case: Ensure that the PAN numbers are in uppercase letters
--		(if any lowercase letters are present).

 select distinct TRIM(UPPER(pan_number)) as pan_number from public.pan_dataset where pan_number is not null or pan_number <> '';
 
 
 
 
 --	2. PAN Format Validation: A valid PAN number follows the format:

-- 2.1 It is exactly 10 characters long

with cte as (
select distinct TRIM(UPPER(pan_number)) as pan_number from public.pan_dataset where pan_number is not null or pan_number <> ''
)
select * from cte where length(pan_number) = 10;


--	2.2 The format is as follows: AAAAA1234A

with cte as (
select distinct TRIM(UPPER(pan_number)) as pan_number from public.pan_dataset where pan_number is not null or pan_number <> ''
)
select * from cte where length(pan_number) = 10 and pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$';


-- 2.2.1 The first five characters should be alphabetic (uppercase letters).
-- 1 Adjacent characters(alphabets) cannot be the same (like AABCD is invalid; AXBCD is valid)
-- 2 . All five characters cannot form a sequence (like: ABCDE, BCDEF is invalid; ABCDX is valid)

-- 2.2.2 The next four characters should be numeric (digits).
-- 1. Adjacent characters(digits) cannot be the same (like 1123 is invalid; 1923 is valid)
-- 2. All four characters cannot form a sequence (like: 1234, 2345). last character should be alphabetic (uppercase letter).

-- Example of a valid PAN: AHGVE1276F

create or replace function public.fn_check_adj_charactes (p_str text)
returns boolean
language plpgsql
as $$
begin
	for i in 1 .. (length(p_str) - 1)
	loop
		if substring(p_str, i, 1) = substring(p_str, i+1, 1)
		then 
			return true;
		end if;
	end loop;
	return false;
end;
$$

select public.fn_check_adj_charactes('ABCDE');



create or replace function public.fn_check_seq_charactes (p_str text)
returns boolean
language plpgsql
as $$
begin
	for i in 1 .. (length(p_str) - 1)
	loop
		if ascii(substring(p_str, i+1, 1)) - ascii(substring(p_str, i, 1)) <> 1
		then 
			return false;
		end if;
	end loop;
	return true;
end;
$$

select public.fn_check_seq_charactes('ABCDE');



-- 3. Categorisation:
-- Valid PAN: If the PAN number matches the above format.
-- Invalid PAN: If the PAN number does not match the correct format, is incomplete, or contains any non-alphanumeric characters.

-- Final Query

with clean_pan as (
	select distinct TRIM(UPPER(pan_number)) as pan_number 
	from public.pan_dataset 
	where pan_number is not null or pan_number <> ''
),
valid_pan as (
	select *
	from clean_pan
	where public.fn_check_adj_charactes(pan_number) = false
	and public.fn_check_seq_charactes(substring(pan_number, 1, 5)) = false
	and public.fn_check_seq_charactes(substring(pan_number, 6, 4)) = false
	and length(pan_number) = 10 and pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
)
select clean_pan.pan_number,
case when valid_pan.pan_number is not null then 'Valid'
	 else 'Invalid'
end
from clean_pan 
left join valid_pan on clean_pan.pan_number = valid_pan.pan_number;


-- 4. Tasks:
-- Validate the PAN numbers based on the format mentioned above.
-- Create two separate categories:
-- Valid PAN
-- Invalid PAN

-- Create a summary report that provides the following:
-- Total records processed
-- Total valid PANs
-- Total invalid PANs
-- Total missing or incomplete PANs (if applicable)


with valid_invalid_pan as (
	with clean_pan as (
		select distinct TRIM(UPPER(pan_number)) as pan_number 
		from public.pan_dataset 
		where pan_number is not null or pan_number <> ''
	),
	valid_pan as (
		select *
		from clean_pan
		where public.fn_check_adj_charactes(pan_number) = false
		and public.fn_check_seq_charactes(substring(pan_number, 1, 5)) = false
		and public.fn_check_seq_charactes(substring(pan_number, 6, 4)) = false
		and length(pan_number) = 10 and pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
	)
	select clean_pan.pan_number,
	case when valid_pan.pan_number is not null then 'Valid'
		 else 'Invalid'
	end as status
	from clean_pan 
	left join valid_pan on clean_pan.pan_number = valid_pan.pan_number
),
cte as (
	select 
		(select count(*) from public.pan_dataset) as total_processed_records,
		count(*) filter(where status = 'Valid') as valid_count,
		count(*) filter(where status = 'Invalid') as invalid_count
	from valid_invalid_pan 
)
select total_processed_records, valid_count, invalid_count
, total_processed_records - (valid_count+invalid_count) as missing_incomplete_PANS
from cte;






