use Retail_Ecommerce_Project

select * from customers

select * from products

select * from sales

-- 1. Retrieve the total number of unique products sold.

select count(distinct product_key) as Unique_Product_Sold
from sales

------------------------------------------------------------------

-- 2. Find the total sales amount for each product category.

select p.category, sum(s.sales_amount) as Sales from
products p left outer join sales s
on p.product_key = s.product_key
where p.category is not null
group by p.category

-------------------------------------------------------------------------

-- 3. List the top 5 customers by total sales amount.

-- Using TOP
select top 5 c.customer_key, 
		c.first_name, 
		c.last_name, 
		sum(s.sales_amount) as amount 
from 
customers c inner join sales s
on c.customer_key = s.customer_key
group by c.customer_key, c.first_name, c.last_name
order by amount desc


-- Using CTE
with ranked_customer as(
	select c.customer_key,
			c.first_name,
			c.last_name,
			sum(s.sales_amount) as amount,
			row_number() over (order by sum(s.sales_amount) desc) as ranking
	from
	customers c inner join sales s
	on c.customer_key = s.customer_key	
	group by c.customer_key, c.first_name, c.last_name
)
select customer_key, first_name, last_name, amount
from ranked_customer
where ranking < 6

------------------------------------------------------------------------------

-- 4. Find the total quantity of each product sold, sorted in descending order.

select s.product_key,
		p.product_name,
		sum(s.quantity) as quantity
from
products p inner join sales s
on p.product_id = s.product_key
group by s.product_key, p.product_name
order by quantity desc

------------------------------------------------------------------------------

-- 5. Identify the most common shipping date.

select top 1 shipping_date, count(*) as count
from sales
group by shipping_date
order by count desc

------------------------------------------------------------------------------

-- 6. Find the total revenue generated per country.

select country, sum(sales_amount) as amount
from
customers c inner join sales s
on c.customer_key = s.customer_key
group by country
order by amount desc

------------------------------------------------------------------------------------

-- 7. List all orders where the sales amount is greater than the average sales amount.

select * from sales
where sales_amount > (select avg(sales_amount) as Average_Sale
						from sales)
order by sales_amount desc

-------------------------------------------------------------------------------------

-- 8. Find customers who placed more than 5 orders.

select c.customer_key, c.first_name, c.last_name, count(s.order_number) as Number_of_Orders
from
customers c inner join sales s
on c.customer_key = s.customer_key
group by c.customer_key, c.first_name, c.last_name
order by Number_of_Orders desc

----------------------------------------------------------------------------------------

-- 9. Retrieve the total sales amount for each month.

select datename(year, order_date) as year, 
		datename(month, order_date) as month,
		sum(sales_amount) as sales_amount
from sales
group by datename(year, order_date), datename(month, order_date), month(order_date)
order by year, month(order_date)

--------------------------------------------------------------------------------------------

-- 10. List the top 3 most sold product categories.

-- Using TOP
select top 3 p.category, 
		count(s.order_number) as Number_of_products
from
products p inner join sales s
on p.product_key = s.product_key
group by p.category
order by Number_of_products desc


-- Using CTE
with Category_sales_count as(
	select p.category,
			count(s.order_number) as Number_of_products,
			row_number() over (order by count(s.order_number) desc) as ranking
	from
	products p inner join sales s
	on p.product_key = s.product_key
	group by p.category
)
select category, Number_of_products
from Category_sales_count
where ranking < 4

---------------------------------------------------------------------------------------

-- 11. Find the average order value per customer.

select 
    customer_key, 
    sum(sales_amount) / count(order_number) as avg_order_value
from sales
group by customer_key

--------------------------------------------------------------------------

-- 12. Count the number of male and female customers.

select gender, count(*) as count
from customers
group by gender

--------------------------------------------------------------------------

-- 13. Find the most frequently sold product.

select top 1 s.product_key,
		p.product_name,
		sum(s.quantity) as quantity
from
products p inner join sales s
on p.product_id = s.product_key
group by s.product_key, p.product_name
order by quantity desc

-----------------------------------------------------------------------------

-- 14. Retrieve orders where the quantity ordered is more than 2.

select * 
from products p inner join sales s
on p.product_key = s.product_key
where quantity > 2

--------------------------------------------------------------------------------

-- 15. Calculate the total revenue from married vs. single customers.

select marital_status, 
		sum(sales_amount) as revenue
from 
customers c inner join sales s
on c.customer_key = s.customer_key
group by marital_status

----------------------------------------------------------------------------------

-- 16. Find the most expensive product sold.

select distinct(product_name), price
from 
products p inner join sales s
on p.product_key = s.product_key
where price = (select max(price) from sales)

-----------------------------------------------------------------------------

-- 17. Retrieve orders where the shipping date is later than the due date.

Select order_number, customer_key, order_date, due_date, shipping_date
from sales
where shipping_date > due_date

----------------------------------------------------------------------------------

-- 18. Find customers who have purchased at least one product from each category.

select c.customer_key, c.first_name, c.last_name
from customers c
inner join sales s on c.customer_key = s.customer_key
inner join products p on p.product_key = s.product_key
group by c.customer_key, c.first_name, c.last_name
having count(distinct p.category) = (select count(distinct category) from products);

---------------------------------------------------------------------------------------

-- 19. Retrieve the top 5 products with the highest revenue-to-cost ratio.

select p.product_name, sum(s.sales_amount)/sum(s.quantity * s.price) as revenue_to_cost_ratio 
from
products p inner join sales s
on p.product_key = s.product_key
group by p.product_name
order by revenue_to_cost_ratio desc

----------------------------------------------------------------------------------------------------

-- 20. Identify customers who have placed orders in every year since their first purchase.

select c.customer_key, c.first_name, c.last_name
from
customers c inner join sales s
on c.customer_key = s.customer_key
group by c.customer_key, c.first_name, c.last_name
having count(distinct year(s.order_date)) = year(max(s.order_date)) - year(min(s.order_date)) + 1

----------------------------------------------------------------------------------------------------

-- 21. Find the most profitable product category based on sales revenue minus cost.

select p.category, 
		sum(s.sales_amount) as sales, 
		sum(s.price * s.quantity) as cost,  
		(sum(s.sales_amount)-sum(s.price * s.quantity)) as profit
from
products p inner join sales s
on p.product_key = s.product_key
group by p.category

--------------------------------------------------------------------------------------

-- 22. Determine the percentage contribution of each product category to total revenue.

select p.category, 
		sum(s.sales_amount) as category_sales_amount,
		(select sum(sales_amount) from sales) as Total_sales_amount,
		format(round(100.0 * sum(s.sales_amount)/(select sum(sales_amount) from sales),2), 'N2') as Percentage_contribution
from
products p inner join sales s
on p.product_key = s.product_key
group by p.category
order by Percentage_contribution desc

----------------------------------------------------------------------------------------------------------------------------

-- 23. Identify customers who placed multiple orders but have never ordered the same product twice.

select s.order_number, c.first_name, c.last_name
from
customers c inner join sales s
on c.customer_key = s.customer_key
group by s.order_number, c.first_name, c.last_name
having count(distinct s.product_key) > 1 and
		count(distinct s.product_key) = count(s.product_key)

------------------------------------------------------------------------------------------------------

-- 24. Find the product with the highest price variation over different orders.

select  
    p.product_name, 
    max(s.price) - min(s.price) as price_variation
from sales s
join products p on s.product_key = p.product_key
group by p.product_name
order by price_variation desc

----------------------------------------------------------------------------------------

-- 25. Calculate the cumulative sales amount for each month.

select year(order_date) as sales_year,
	datename(month, order_date) as sales_month,
		sum(sales_amount) as sales_amount_Per_month,
		sum(sum(sales_amount)) over (partition by year(order_date) order by year(order_date), month(order_date)) as cumulative_sales_amount
from sales
group by year(order_date), datename(month, order_date), month(order_date) 
order by sales_year, month(order_date)

-----------------------------------------------------------------------------------------------

-- 26. Find the average number of products per order.

select sum(quantity)/count(order_number) as avg_products_per_order	
from sales

------------------------------------------------------------------------

-- 27. Identify the customer with the highest lifetime value.

-- Customer Lifetime Value (CLV) is the total revenue a customer generates over their entire relationship
-- with a business.

select customer_key, sum(sales_amount) as total_revenue
from sales
group by customer_key
order by total_revenue desc

-----------------------------------------------------------------------------------------------

-- 28. Determine which country has the highest average order value.

select c.country,
		sum(sales_amount)/count(order_number) as avg_sales_by_country
from
customers c inner join sales s
on c.customer_key = s.customer_key
group by country
order by avg_sales_by_country desc
