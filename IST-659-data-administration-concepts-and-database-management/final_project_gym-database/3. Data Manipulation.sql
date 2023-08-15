/*
	Course: IST 659
	Term: Fall 2020
*/

/*--------------------------------------------------------------------------------------------------*/
/*                             DEMONSTRATE UNSUCCESSFUL UPDATE ATTEMPTS                             */
/*--------------------------------------------------------------------------------------------------*/


/*-----------------VIOLATION OF BUSINESS RULE 1: a client must be 'active' or 'inactive'------------*/
insert into client_T (first_name, last_name, birth_date, status) values
('Nick', 'Budsworth', '4-20-1970', 'not active')


/*-----------------VIOLATION OF BUSINESS RULE 2: a client cannot enter cardio as a lift-------------*/
insert into lift_T (lift_name) values ('cardio')


/*-----------VIOLATION OF BUSINESS RULE 9: a client can't have two workouts on the same date--------*/
insert into workout_T (client_id, workout_date, start_time, end_time, duration, gym_id) values
(1, '12-02-2020', '18:30', '19:05', 35, 1)


/*---------------VIOLATION OF BUSINESS RULE 3: a client can't workout two days in a row-------------*/
-- from the query result you can see that this record was not added to the table
declare @return_value1 int
exec @return_value1 = addworkout
1, '12-01-2020', '18:30', '19:05', 35, 1
select 'Return Value' = @return_value1
select * from workout_T where client_id = 1 and workout_date = '12-01-2020'


/*---------------VIOLATION OF BUSINESS RULE 5: a client can't do a lift out of rotation-------------*/

-- first add a workout to the database so the set can be linked to it
declare @return_value2 int
exec @return_value2 = addworkout
1, '12-08-2020', '18:30', '19:05', 35, 1
select 'Return Value' = @return_value2
select * from workout_T where client_id = 1 and workout_date = '12-08-2020'
-- from the query result you can see that this record was added to the table

-- now try to add a set of bench when bench was also done on the last workout
declare @return_value3 int
exec @return_value3 = addset
1, 25, 1, 10, 200, 8, 1
select 'Return Value' = @return_value3
select	set_T.set_id, set_workout_T.lift_id, lift_T.lift_name, workout_T.workout_id, workout_T.workout_date, client_T.client_id 
from set_T
join set_workout_T on set_workout_T.set_id = set_T.set_id
join workout_T on workout_T.workout_id = set_workout_T.workout_id
join client_T on client_T.client_id = workout_T.client_id
join lift_T on lift_T.lift_id = set_workout_T.lift_id
order by workout_date desc
-- from the query result you can see that this record was not added to the table


/*--------------------------------------------------------------------------------------------------*/
/*                       DEMONSTRATE SUCCESSFUL UPDATES, INSERTS, AND DELETES                       */
/*--------------------------------------------------------------------------------------------------*/

-- delete the workout that was just added
delete workout_T where workout_id = 25
select * from workout_T order by workout_date desc
-- from the query result you can see that this record was deleted from the table

-- correcting end time and duration for workout 5
update workout_T set end_time ='17:00' where workout_id = 5
update workout_T set duration = 30 where workout_id = 5
select * from workout_T where workout_id = 5
-- from the query result you can see that this record was updated in the table

-- pull up some tables to assist in the subsequent entry of data
select * from food_item_T order by food_item_name asc
select * from nutrition_log_T
select nutrition_log_T.nutrition_log_date, nutrition_log_T.food_item_id, food_item_T.food_item_name, servings_consumed, calories_per_serving
from nutrition_log_T
join food_item_T on food_item_T.food_item_id = nutrition_log_T.food_item_id
order by nutrition_log_date desc

-- log a couple of days worth of nutrition data
insert into food_item_T (food_item_name, serving_size, calories_per_serving, fat_per_serving, carbohydrate_per_serving, protein_per_serving, price_per_serving, food_category) values
('neils elk', '4 oz', 150, 5, 0, 21, 0, 'meat'),
('organic white wine generic', '6 oz', 120, 0, 20, 0, 2.50, 'alcohol'),
('salsa generic', '1 serving', 10, 0, 2, 1, .10, 'vegetable')

insert into nutrition_log_T (client_id, nutrition_log_date, food_item_id, servings_consumed) values
(1, '2020-12-07', 29, 6),
(1, '2020-12-07', 9, 2),
(1, '2020-12-07', 58, 4),
(1, '2020-12-07', 79, 1),
(1, '2020-12-07', 18, 1),
(1, '2020-12-07', 10, 2),
(1, '2020-12-07', 50, 1.5),
(1, '2020-12-07', 24, 5),
(1, '2020-12-07', 83, 4),
(1, '2020-12-08', 79, 1),
(1, '2020-12-08', 18, 1),
(1, '2020-12-08', 62, 6),
(1, '2020-12-08', 74, 2),
(1, '2020-12-08', 82, 3),
(1, '2020-12-08', 51, 3),
(1, '2020-12-08', 56, 1),
(1, '2020-12-08', 84, 1),
(1, '2020-12-09', 18, 1),
(1, '2020-12-09', 79, 1),
(1, '2020-12-09', 29, 6),
(1, '2020-12-09', 9, 4),
(1, '2020-12-09', 8, 1),
(1, '2020-12-09', 67, 8),
(1, '2020-12-09', 85, 1),
(1, '2020-12-09', 74, 1),
(1, '2020-12-09', 48, 2),
(1, '2020-12-09', 58, 6),
(1, '2020-12-10', 29, 6),
(1, '2020-12-10', 8, 1),
(1, '2020-12-10', 9, 2),
(1, '2020-12-10', 70, 5),
(1, '2020-12-10', 67, 4),
(1, '2020-12-10', 58, 4),
(1, '2020-12-10', 77, 0.5)