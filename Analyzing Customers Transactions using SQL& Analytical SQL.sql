--Viewing the data 

select * from tableretail
where rownum<=20;


---What is the number of orders per year?

with invoicedate_year as (
    select to_char(to_date(substr(invoicedate,1,instr(invoicedate,' ')-1),'MM/DD/YYYY'),'yyyy') as invoice_year,invoice ----since invoice date is varchar , we took the date and convert it into date and then to char to find the year
    from tableretail
)
select distinct(invoice_year) ,count(invoice) over(partition by invoice_year ) as Num_orders ---number of orders per year
from invoicedate_year;


--What is the total sales per  year?
with sales_over_years as (
    select to_char(to_date(substr(invoicedate,1,instr(invoicedate,' ')-1),'MM/DD/YYYY'),'yyyy') as invoice_year,----since invoice date is varchar , we took the date and convert it into date and then to char to find the year
    quantity*price as Sales ---sales is the quantity * price
    from tableretail
)
select distinct(invoice_year),sum(sales) over(partition by invoice_year) as Sales --total sales per year
from sales_over_years;

--Avg price for product over the years?
with invoicedate_year as (
    select to_char(to_date(substr(invoicedate,1,instr(invoicedate,' ')-1),'MM/DD/YYYY'),'yyyy') as invoice_year,invoice,stockcode,price ----since invoice date is varchar , we took the date and convert it into date and then to char to find the year
    from tableretail
), price as (
    select stockcode,invoice_year ,avg(price) as Avg_price
    from invoicedate_year
    group by stockcode,invoice_year
    )
select * from( (select stockcode,invoice_year,avg_price from price)
    pivot (
    avg(avg_price) for invoice_year in (2010,2011)
    )
);



--Top 50 products in their sales 

with products_sales as (
    select quantity*price as Sales ,---sales is the quantity * price
    stockcode
    from tableretail
),
ranked_products as(
    select stockcode,sales ,rank() over(order by sales desc) as product_rank ---ordering products based on their sales  from largest to smallest
    from products_sales
)
select * from ranked_products
where product_rank<=50;


--When was the last time each customer made an order ?
with customers_sales as (
    select to_date(substr(invoicedate,1,instr(invoicedate,' ')-1),'MM/DD/YYYY')as invoice_date,----since invoice date is varchar , we took the date and convert it into date and then to char to find the year
    quantity*price as Sales , ---sales is the quantity * price
    customer_id
    from tableretail
),
Last_purchase as (
    select distinct(customer_id),last_value(invoice_date) over(partition by customer_id order by invoice_date rows between unbounded preceding and unbounded following) as last_invoice_date,sales
    from customers_sales
)
select customer_id,last_invoice_date,sum(sales) as total_sales from Last_purchase
group by customer_id,last_invoice_date;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Q2: Monetary model
with invoicedateformatted as (
    select to_date(substr(invoicedate,1,instr(invoicedate,' ')-1),'MM/DD/YYYY') as  invoice_date ,to_char(to_date(substr(invoicedate,1,instr(invoicedate,' ')-1),'MM/DD/YYYY'),'yyyy') as invoice_year
    from tableretail
)
select max(invoice_date) as most_recent_purchase from invoicedateformatted; ----This query is used to obtain the most recent purchase in the data


with customer_behaviours as (---In this query , we are calculating recency which is difference between most recent purchase date and invoice date, frequency  which is number of purchases and monetary which is price * quantity
    select customer_id,max(to_date('12/9/2011','MM/DD/YYYY')-to_date(substr(invoicedate,1,instr(invoicedate,' ')-1),'MM/DD/YYYY')) as Recency, count(invoice) as Frequency, sum(price*quantity) as Monetary
    from tableretail
    group by customer_id--grouping all measures by customer_id
    ),
scores as(
    select customer_id,Recency as recency_score,ntile(5) over(order by Recency) as Recency,Frequency,ntile(5) over(order by Frequency) as Frequency_group ,Monetary ,(Frequency+Monetary)/2 as FM
    from customer_behaviours ----Here we are dividing customers into 5 groups based on recency score , and the same for frequency  and calculating fm as avg of frequency and monetary
    ),
    customer_groups as(
    select customer_id,Recency,recency_score,Frequency_group,Monetary,fm,ntile(5) over(order by fm) as FM_score---dividing fm into 5 groups 
        
     from scores
    )
    select customer_id,Recency,Frequency_group,FM_score,
    case when Recency=5 and FM_score =5 then 'Champions'  
    when  recency=5 and FM_score =4 then 'Champions'  
    when  recency=4 and FM_score =5 then 'Champions'  
    when  recency=5 and FM_score =2 then 'Potential Loyalists'  
    when  recency=4 and FM_score =2 then 'Potential Loyalists'
    when  recency=3 and FM_score =3 then 'Potential Loyalists'  
    when  recency=4 and FM_score =3 then 'Potential Loyalists'    
    when  recency=5 and FM_score =3 then 'Loyal Customers'  
    when  recency=4 and FM_score =4 then 'Loyal Customers' 
   when  recency=3 and FM_score =5 then 'Loyal Customers' 
   when  recency=3 and FM_score =4 then 'Loyal Customers' 
   when  recency=5 and FM_score =1 then 'Recent Customers' 
   when  recency=4 and FM_score =1 then 'Promising' 
   when  recency=3 and FM_score =1 then 'Promising'
   when  recency=3 and FM_score =2 then 'Customers Needing Attention'
   when  recency=2 and FM_score =3 then 'Customers Needing Attention'
   when  recency=2 and FM_score =2 then 'Customers Needing Attention'
   when  recency=2 and FM_score =5 then 'Customers at Risk'
   when  recency=2 and FM_score =4 then 'Customers at Risk'
   when  recency=1 and FM_score =3 then 'Customers at Risk'
   when  recency=1 and FM_score =5 then 'Cant Lose Them'
   when  recency=1 and FM_score =4 then 'Cant Lose Them'
   when  recency=1 and FM_score =2 then 'Hibernating'
   when  recency=1 and FM_score =1 then 'Lost'
    else 'other'
    End as Customer_segment
    from customer_groups
;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Table Creation
/*
create table customers (
    Cust_Id number(20) primary key,
    Calendar_Dt  Date ,
    Amt_LE  number(10)
    );
commit;  
*/




select  from customers;

---What is the maximum number of consecutive days a customer made purchases?
with next_purchase as (
    select cust_id,calendar_dt,row_number() over(partition by cust_id order by calendar_dt) as ranked_order----ordering transactions based on date
    from customers
) , prev_purchase as (
    select cust_id , count(*) over(partition by cust_id , calendar_dt-ranked_order  ) as consecutive_days ---finding consecutive days as days with number of dates comming from date - rank which will yield same date in case of consecutive transcations
    from next_purchase
)
select cust_id ,max(consecutive_days) ---finding the max
from prev_purchase
group by cust_id
order by cust_id ;


--------On average, How many days/transactions does it take a customer to reach a spent threshold of 250 L.E?
with total_amount  as (
    select cust_id, calendar_dt,sum(amt_le) over(partition by cust_id order by calendar_dt) as total_spent_amout --running total of amount paid grouped by customer and ordered by date
    from customers
    order by cust_id
), threshold as (
select cust_id,min(calendar_dt) as start_trans,max(calendar_dt) as last_trans ---using min and max to find start and end date
from total_amount
where total_spent_amout>=250 ---filtering only rows>=250
group by cust_id
)
select avg(last_trans-start_trans) as avg_days_threshold ---to find avg number of days
from threshold;
