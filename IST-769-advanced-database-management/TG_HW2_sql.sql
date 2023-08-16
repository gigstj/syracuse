/* Question 1 */

/* Use built in SQL functions to write an SQL Select statement on fudgemart_products which
   derives a product_category column by extracting the last word in the product name. For
   example for a product named ‘Leather Jacket’ the product category would be ‘Jacket. b.
   for a product named ‘Straight Claw Hammer’ the category would be ‘Hammer’. Your select
   statement should include product id, product name, product category and product department. */

use fudgemart_v3
go

-- multiple sub queries to get to the end product category
select
	product_id,
	product_name,
	substring(product_category, charindex(' ', product_category) + 1, 50) as product_category,
	product_department
from (
	-- start sub query
	select
		product_id,
		product_name,
		substring(product_category, charindex(' ', product_category) + 1, 50) as product_category,
		product_department
	from (
		-- start subquery
		select
			product_id,
			product_name,
			substring(product_name, charindex(' ', product_name) + 1, 50) as product_category,
			product_department
		from
			fudgemart_products
		-- end subquery
		) sub
	-- end subquery
	) sub
go

/* Question 2 */

/* Write a user defined function called f_total_vendor_sales which calculates the sum of the
wholesale price * quantity of all products sold for that vendor. There should be one number
associated with each vendor id, which is the input into the function.  Demonstrate the function
works by executing an SQL select statement over all vendors calling the function. */

use fudgemart_v3
go

drop function if exists dbo.f_total_vendor_sales
go

create function dbo.f_total_vendor_sales(
	@vendor_id as int -- user input
	) returns int as
begin
	declare @revenue int -- revenue = qty * price
	set @revenue = (select sum(product_wholesale_price * order_qty)
					from fudgemart_order_details
					join fudgemart_products on fudgemart_products.product_id = fudgemart_order_details.product_id 
					join fudgemart_vendors on fudgemart_vendors.vendor_id = fudgemart_products.product_vendor_id
					where vendor_id = @vendor_id)
	return @revenue
end
go

select
	vendor_id,
	vendor_name,
	cast(isnull(dbo.f_total_vendor_sales(vendor_id), 0) as money) as revenue -- format
from
	fudgemart_vendors
go

/* Question 3 */

/* Write a stored procedure called p_write_vendor which when given a required vendor name, phone
and optional website, will look up the vendor by name first. If the vendor exists, it will update
the phone and website. If the vendor does not exist, it will add the info to the table.  Write code
to demonstrate the procedure works by executing the procedure twice so that it adds a new vendor
and then updates that vendor’s information. */

use fudgemart_v3 
go

drop procedure if exists dbo.p_write_vendor
go

create procedure dbo.p_write_vendor(
	@vendor_name varchar(50),
	@vendor_phone varchar(20),
	@vendor_website varchar(1000) = NULL
)as
begin
	if exists (select vendor_name from fudgemart_vendors where vendor_name = @vendor_name)
	begin
		update fudgemart_vendors set vendor_phone = @vendor_phone where vendor_name = @vendor_name 
		update fudgemart_vendors set vendor_website = @vendor_website where vendor_name = @vendor_name 
	end
	else
	begin
		insert into fudgemart_vendors (vendor_name, vendor_phone, vendor_website)
		values (@vendor_name, @vendor_phone, @vendor_website)
	end
end
go

exec
	dbo.p_write_vendor @vendor_name = 'goodvendor', @vendor_phone = '999-5552'
go

exec
	dbo.p_write_vendor @vendor_name = 'goodvendor', @vendor_phone = '966-5812', @vendor_website = 'www.goodvendor.com'
go

/* Question 4 */

/* Create a view based on the logic you completed in question 1 or 2. Your SQL script should be
programmed so that the entire script works every time, dropping the view if it exists, and then
re-creating it. */ 

use fudgemart_v3
go

drop view if exists dbo.myview
go

create view dbo.myview as

select
	t1.product_id,
	t1.product_category,
	t1.vendor_id,
	t2.revenue as vendor_revenue
from 
(select
	product_id,
	vendor_id,
	substring(product_category, charindex(' ', product_category) + 1, 50) as product_category
from (
	select
		product_id,
		vendor_id,
		substring(product_category, charindex(' ', product_category) + 1, 50) as product_category
	from (
		select
			product_id,
			vendor_id,
			substring(product_name, charindex(' ', product_name) + 1, 50) as product_category
		from
			fudgemart_products
			join fudgemart_vendors on fudgemart_vendors.vendor_id = fudgemart_products.product_vendor_id
		) sub
	) sub
) t1

left join

(select
	vendor_id,
	cast(isnull(dbo.f_total_vendor_sales(vendor_id), 0) as money) as revenue
from
	fudgemart_vendors
) t2

on t1.vendor_id = t2.vendor_id

go

select * from dbo.myview 
go

/* Question 5 */

/* Write a table valued function f_employee_timesheets which when provided an employee_id
will output the employee id, name, department, payroll date, hourly rate on the timesheet,
hours worked, and gross pay (hourly rate times hours worked). */

use fudgemart_v3
go

drop function if exists dbo.f_employee_timesheets
go

create function dbo.f_employee_timesheets(
	@employee_id as int
) returns table as
return(
	select
		fudgemart_employees.employee_id,
		fudgemart_employees.employee_firstname,
		fudgemart_employees.employee_lastname,
		fudgemart_employees.employee_department,
		fudgemart_employee_timesheets.timesheet_payrolldate,
		fudgemart_employee_timesheets.timesheet_hourlyrate,
		fudgemart_employee_timesheets.timesheet_hours,
		fudgemart_employee_timesheets.timesheet_hourlyrate * fudgemart_employee_timesheets.timesheet_hours as grosspay
	from
		fudgemart_employees 
		join fudgemart_employee_timesheets on fudgemart_employee_timesheets.timesheet_employee_id = fudgemart_employees.employee_id 
	where
		fudgemart_employees.employee_id = @employee_id
)
go

select * from dbo.f_employee_timesheets(10)
go