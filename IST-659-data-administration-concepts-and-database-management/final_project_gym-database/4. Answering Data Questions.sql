/*
	Course: IST 659
	Term: Fall 2020
*/

-- 1. How did your 1 rep max of each lift change over time

/* Logic: pull a table that shows each lift by date and the 
estimated 1RM, used a generic formula to calculate the 1RM.
This is only for first sets, since that is the set that reflects
true strength to the best degree when using reverse pyramid style*/

select top 1000 client_T.first_name+' '+client_T.last_name as clientname,
set_T.set_id, lift_T.lift_name, set_T.repetitions, set_T.resistance, set_T.RPE, workout_T.workout_date,
cast(set_T.resistance / (1.0278 - 0.0278 * set_T.repetitions) as int) as estimated_1rm
from set_T
join set_workout_T on set_workout_T.set_id = set_T.set_id
join workout_T on workout_T.workout_id = set_workout_T.workout_id
join client_T on client_T.client_id = workout_T.client_id
join lift_T on lift_T.lift_id = set_workout_T.lift_id
where set_T.set_number = 1

-- 2. How much body weight did you lose or gain

/*pull a table to show body weight measurements by date. further analysis
on this will be explored in the front end tool.*/

select  measurement_log_T.date_taken_on, measurement_log_T.recorded_value
from measurement_log_T
join measurement_T on measurement_T.measurement_id = measurement_log_T.measurement_id
where client_id = 1 and measurement_log_T.measurement_id = 1

-- 3. How much did the size of your muscle groups increase or decrease by

/*pull a table to show the measurements by date. Combined the recorded value and 
unit of measurement fields into one for the sake of aesthetics*/

select  measurement_T.measurement_name, measurement_log_T.date_taken_on,
concat(cast(measurement_log_T.recorded_value as varchar), ' ',
cast(measurement_T.unit_of_measurement as char)) as recordedvalue
from measurement_log_T
join measurement_T on measurement_T.measurement_id = measurement_log_T.measurement_id
where client_id = 1 and measurement_log_T.measurement_id <> 1
order by measurement_T.measurement_name, measurement_log_T.date_taken_on

-- 4. How much money did you spend on average per day on food

/*used a sub query approach to pull together a table that shows
the total spend per day calculated by using the cost for food items
according to the data that is stored in the database*/

select top 1000 nutrition_log_date, sum(totalspend) as totalspend from
(select top 1000 nutrition_log_T.nutrition_log_date, nutrition_log_T.food_item_id,
food_item_T.food_item_name, nutrition_log_T.servings_consumed,
food_item_T.price_per_serving,
sum(food_item_T.price_per_serving * servings_consumed) as totalspend
from nutrition_log_T
join food_item_T on food_item_T.food_item_id = nutrition_log_T.food_item_id
where client_id = 1
group by nutrition_log_T.nutrition_log_date, nutrition_log_T.food_item_id,
food_item_T.food_item_name, nutrition_log_T.servings_consumed,
food_item_T.price_per_serving
order by nutrition_log_T.nutrition_log_date) sub
group by nutrition_log_date order by nutrition_log_date

-- 5. What kinds of foods did you eat the most

/*Pulled a table that shows both the count of how many times a particular
food category was logged as well as the the total cals and most importantly
the percentage of the total amount that the food category makes up in aggregate*/

select food_category,
sum(logcount) as logcount,
sum(totalcals) as totalcals,
sum(totalcals)/
(select sum(nutrition_log_T.servings_consumed *
food_item_T.calories_per_serving)
from nutrition_log_T
join food_item_T on food_item_T.food_item_id = nutrition_log_T.food_item_id)
as percenttotal from
	(select food_item_t.food_category,
	count(food_item_T.food_category) as logcount,
	sum(nutrition_log_T.servings_consumed * food_item_T.calories_per_serving) as totalcals
	from nutrition_log_T
	join food_item_T on food_item_T.food_item_id = nutrition_log_T.food_item_id
	group by food_item_T.food_category) sub
group by food_category
order by percenttotal desc