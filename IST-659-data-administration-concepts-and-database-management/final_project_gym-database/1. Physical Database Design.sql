/*
	Course: IST 659
	Term: Fall 2020
*/

-- optional wipe tables clause
drop table if exists set_workout_T
drop table if exists lift_T
drop table if exists set_T
drop table if exists workout_T
drop table if exists gym_T
drop table if exists measurement_log_T
drop table if exists measurement_T
drop table if exists nutrition_log_T
drop table if exists food_item_T
drop table if exists client_T
drop procedure if exists addworkout
drop procedure if exists addset
drop view if exists bench_progression_V
drop view if exists weekly_cals_V


-- start create client table
-- COMPLIES WITH BUSINESS RULE 1 --
create table client_T (
client_id int identity,
first_name varchar(30) not null,
last_name varchar(30) not null,
birth_date date not null,
status varchar(10) not null,
constraint PK_client_T primary key (client_id),
constraint CK_client_T check (status in ('active', 'inactive')))
go -- end create client table


-- start create food item table
create table food_item_T (
food_item_id int identity,
food_item_name varchar(100) not null,
serving_size varchar(30) not null,
calories_per_serving int not null,
fat_per_serving int not null,
carbohydrate_per_serving int not null,
protein_per_serving int not null,
price_per_serving float not null,
food_category varchar(30) not null,
constraint PK_food_item_T primary key (food_item_id))
go -- end create food item table


-- start create nutrition log table
create table nutrition_log_T (
nutrition_log_record_id int identity,
client_id int not null,
nutrition_log_date date not null,
food_item_id int not null,
servings_consumed float not null,
constraint PK_nutrition_log_T primary key (nutrition_log_record_id),
constraint FK1_nutrition_log_T foreign key (food_item_id) references food_item_T(food_item_id),
constraint FK2_nutrition_log_T foreign key (client_id) references client_T(client_id),
constraint U1_nutrition_log_T unique (nutrition_log_date, food_item_id, servings_consumed))
go -- end create nutrition log table


-- start create measurement table
-- COMPLIES WITH BUSINESS RULE 8 --
create table measurement_T (
measurement_id int identity,
measurement_name varchar(30) not null,
unit_of_measurement char(2) not null,
constraint PK_measurement_T primary key (measurement_id),
constraint C1_measurement_T check (unit_of_measurement in ('cm', 'lb')))
go -- end create measurement table


-- start create measurement log table
--  COMPLIES WITH BUSINESS RULE 7 --
create table measurement_log_T (
measurement_log_record_id int identity,
client_id int not null,
measurement_id int not null,
recorded_value float not null,
date_taken_on date not null,
time_taken_on time not null,
constraint PK_measurement_log_T primary key (measurement_log_record_id),
constraint FK1_measurement_log_T foreign key (measurement_id) references measurement_T(measurement_id),
constraint FK2_measurement_log_T foreign key (client_id) references client_T(client_id),
constraint U1_measurement_log_T unique (client_id, measurement_id, date_taken_on))
go -- end create measurement log table


-- start create gym table
create table gym_T (
gym_id int identity,
gym_name varchar(50) not null,
city varchar(50) not null,
state char(2) not null,
constraint PK_gym_T primary key (gym_id))
go -- end create gym table


-- start create workout table
-- COMPLIANT WITH BUSINESS RULE 9 --
create table workout_T (
workout_id int identity,
client_id int not null,
workout_date date not null,
start_time time not null,
end_time time not null,
duration int not null,
gym_id int not null,
constraint PK_workout_T primary key (workout_id),
constraint FK1_workout_T foreign key (gym_id) references gym_T(gym_id),
constraint FK2_workout_T foreign key (client_id) references client_T(client_id),
constraint U1_workout_T unique (client_id, workout_date))
go -- end create workout table


-- start create set table
-- COMPLIES WITH BUSINESS RULE 6 --
create table set_T (
set_id int identity,
set_number int not null,
repetitions int not null,
resistance int not null,
RPE int not null,
constraint PK_set_T primary key (set_id),
constraint C1_set_T check (set_number in (1, 2, 3)),
constraint C2_set_T check (repetitions > 0),
constraint C3_set_T check (RPE in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)))
go -- end create set table


-- start create lift table
-- COMPLIES WITH BUSINESS RULE 2 --
create table lift_T (
lift_id int identity,
lift_name varchar(50) not null,
constraint PK_lift_T primary key (lift_id),
constraint C1_lift_T check (lift_name not like ('%cardio%')))
go -- end create lift table


-- start create set workout table
create table set_workout_T (
set_workout_id int identity,
lift_id int not null,
set_id int not null,
workout_id int not null,
constraint PK_set_workout_T primary key (set_workout_id),
constraint FK1_set_workout_T foreign key (lift_id) references lift_T(lift_id),
constraint FK2_set_workout_T foreign key (set_id) references set_T(set_id),
constraint FK3_set_workout_T foreign key (workout_id) references workout_T(workout_id))
go -- end create set workout table


/*--------------------------STORED PROCEDURE FOR ENTERING A WORKOUT--------------------------*/
							 --COMPLIES WITH BUSINESS RULES 1,3,4--


/* start create stored procedure for entering a workout into the database*/
	create procedure addworkout (
	@client_id		int,
	@workout_date	date,
	@start_time		time,
	@end_time		time,
	@duration		int,
	@gym_id			int)
	as begin
/* store the last workout date for the client as a variable in the procedure*/
	declare			@lastworkout date
	set				@lastworkout = (
	select			max(workout_date)
	from			workout_T
	where			client_id = @client_id)
/* store # of workouts over last 7 days for the client as a variable in the procedure*/
	declare			@numworkout int
	set				@numworkout = (
	select			count(workout_id)
	from			workout_T
	where			client_id = 1 
	and				workout_date >= dateadd(day, -7, @workout_date))
/* store the status of the client as a variable in the procedure*/
	declare			@status varchar(10)
	set				@status = (
	select			[status]
	from			client_T
	where			client_id = @client_id)
/*refer back to the lastworkout date to ensure that it complies with business rules*/
	if @workout_date > dateadd(day, 1, @lastworkout) --	BUSINESS RULE 3
	and @numworkout < 3 -- BUSINESS RULE 4
	and @status = 'active' -- BUSINESS RULE 1
	begin
	insert into workout_T (client_id, workout_date, start_time, end_time, duration, gym_id)
	values (@client_id, @workout_date, @start_time, @end_time, @duration, @gym_id)
	end
	else
	print 'Date does not work'
	end 
go -- end create stored procedure for entering a workout into the database


/*----------------------------STORED PROCEDURE FOR ENTERING A SET----------------------------*/
						     --COMPLIES WITH BUSINESS RULES 1,5,6--


/* start create stored procedure for entering a set into the database*/
	create procedure addset (
	@client_id		int,
	@workout_id		int,
	@set_number		int,
	@reptitions		int,
	@resistance		int,
	@RPE			int,
	@lift_id		int)
	as begin
/* store the last lift date for the client as a variable in the procedure*/
	declare			@lastlift date
	set				@lastlift = (
	select			max(workout_date) from
	(select			set_T.set_id, set_workout_T.lift_id, workout_T.workout_date, client_T.client_id
	from			set_T
	join			set_workout_T on set_workout_T.set_id = set_T.set_id
	join			workout_T on workout_T.workout_id = set_workout_T.workout_id
	join			client_T on client_T.client_id = workout_T.client_id) sub
	where			client_id = @client_id
	and				lift_id = @lift_id)
/* store the workout date as looked up by the workout id parameter as a variable in the procedure*/
	declare			@workout_date date
	set				@workout_date = (
	select			workout_T.workout_date
	from			workout_T
	where			workout_T.workout_id = @workout_id)
/* store the set_id as the max of set id's +1 as a variable in the procedure*/
	declare			@set_id int
	set				@set_id = (
	select			max(set_id) +1 from
	(select			set_T.set_id, set_workout_T.lift_id, workout_T.workout_date, client_T.client_id
	from			set_T
	join			set_workout_T on set_workout_T.set_id = set_T.set_id
	join			workout_T on workout_T.workout_id = set_workout_T.workout_id
	join			client_T on client_T.client_id = workout_T.client_id) sub)
/* store the status of the client as a variable in the procedure*/
	declare			@status varchar(10)
	set				@status = (
	select			[status]
	from			client_T
	where			client_id = @client_id)
/* store the current number of sets that are in for a lift on a day as a variable in the procedure*/
	declare			@numsets int
	set				@numsets = (
	select			count(set_id) from
	(select			set_T.set_id, set_workout_T.lift_id, workout_T.workout_id, workout_T.workout_date, client_T.client_id
	from			set_T
	join			set_workout_T on set_workout_T.set_id = set_T.set_id
	join			workout_T on workout_T.workout_id = set_workout_T.workout_id
	join			client_T on client_T.client_id = workout_T.client_id) sub
	where			client_id = @client_id
	and				lift_id = @lift_id
	and				workout_id = @workout_id)
/*refer back to the lastlift date to ensure that it complies with business rules*/
	if @workout_date >= dateadd(day, 6, @lastlift) -- BUSINESS RULE 5
	and @status = 'active' -- BUSINESS RULE 1
	and @numsets < 3  -- BUSINESS RULE 6
	begin
	begin transaction
	insert into set_T (set_number, repetitions, resistance, RPE)
	values (@set_number, @reptitions, @resistance, @RPE)
	insert into set_workout_T (lift_id, set_id, workout_id)
	values (@lift_id, @set_id, @workout_id)
	commit transaction
	begin transaction
	end
	else
	print 'Date does not work'
	end 
go -- end create stored procedure for entering a set into the database


-- start create bench press progression view
create view bench_progression_V as
select top 1000 client_T.first_name+' '+client_T.last_name as clientname,
set_T.set_id, lift_T.lift_name, set_T.repetitions, set_T.resistance, set_T.RPE, workout_T.workout_date,
cast(set_T.resistance / (1.0278 - 0.0278 * set_T.repetitions) as int) as estimated_1rm
from set_T
join set_workout_T on set_workout_T.set_id = set_T.set_id
join workout_T on workout_T.workout_id = set_workout_T.workout_id
join client_T on client_T.client_id = workout_T.client_id
join lift_T on lift_T.lift_id = set_workout_T.lift_id
where set_T.set_number = 1
and set_workout_T.lift_id = 1
order by workout_date asc
go -- end create bench press progression view


----------------------------------------------------------------------------------
-------------------------- start avg cals by week view ---------------------------
create view weekly_cals_V as                                                    --
select datepart(year, nutrition_log_date) as log_year,					   	    --
datepart(week, nutrition_log_date) as log_week,					   	            --
sum(total_calories)/7 as avg_daily_cals from					   	            --
------------------------------ start sub query 1 ---------------------------------
/**/ (select nutrition_log_T.nutrition_log_date, nutrition_log_T.food_item_id,  --
/**/ nutrition_log_T.servings_consumed, food_item_T.calories_per_serving,       --
/**/ servings_consumed*calories_per_serving as total_calories					--
/**/ from nutrition_log_T					   	                                --
/**/ join food_item_T on food_item_T.food_item_id = nutrition_log_T.food_item_id--
/**/ where nutrition_log_T.client_id =1 					   	                --
/**/ group by nutrition_log_T.nutrition_log_date, nutrition_log_T.food_item_id, --
/**/ nutrition_log_T.servings_consumed,food_item_T.calories_per_serving) sub    --
------------------------------ start sub query 1 ---------------------------------
group by datepart(year, nutrition_log_date), datepart(week, nutrition_log_date) --
-------------------------- end avg cals by day view ------------------------------
----------------------------------------------------------------------------------