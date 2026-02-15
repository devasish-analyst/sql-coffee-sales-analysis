
-- Monday Coffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis

--Q.1 Which cities contribute the most to total revenue and what % of overall revenue do they contribute?

SELECT
    ci.city_name,
    SUM(s.total) AS city_revenue,
    ROUND(
        SUM(s.total) * 100.0 / SUM(SUM(s.total)) OVER (),
        2
    ) AS revenue_percentage
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY city_revenue DESC;

--Q2. Top 5 Customers by Lifetime Value
--Who are the highest revenue-generating customers?

SELECT
    c.customer_id,
    c.customer_name,
    SUM(s.total) AS lifetime_value
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_value DESC
LIMIT 5;


--Q3. Repeat vs One-Time Customers
--How many customers purchased more than once vs only once?

SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS customers
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM sales
    GROUP BY customer_id
) t
GROUP BY customer_type;

--Q4. Monthly Revenue Trend
--How does revenue change month over month?

SELECT
    EXTRACT(YEAR FROM sale_date) AS year,
    EXTRACT(MONTH FROM sale_date) AS month,
    SUM(total) AS monthly_revenue
FROM sales
GROUP BY year, month
ORDER BY year, month;

--Q5. Month-over-Month Growth %
--Calculate MoM growth in revenue.

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', sale_date) AS month,
        SUM(total) AS revenue
    FROM sales
    GROUP BY month
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 /
        LAG(revenue) OVER (ORDER BY month),
        2
    ) AS growth_percentage
FROM monthly_sales
WHERE LAG(revenue) OVER (ORDER BY month) IS NOT NULL;

--Q6. Best-Selling Products (by Orders)
--Which products are ordered most frequently?

SELECT
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;


--Q7. Top 3 Products per City
--What are the top 3 products in each city by number of orders?

SELECT *
FROM (
    SELECT
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS orders,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name
            ORDER BY COUNT(s.sale_id) DESC
        ) AS rank
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY ci.city_name, p.product_name
) ranked
WHERE rank <= 3;

--Q8. Average Revenue per Customer by City
--Which cities have higher spending customers on average?

SELECT
    ci.city_name,
    ROUND(
        SUM(s.total) / COUNT(DISTINCT s.customer_id),
        2
    ) AS avg_revenue_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY avg_revenue_per_customer DESC;


--Q9. Cities with Highest Market Potential
--Compare actual customers vs estimated coffee consumers (25% population).

WITH actual_customers AS (
    SELECT
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS actual_customers
    FROM city ci
    LEFT JOIN customers c ON ci.city_id = c.city_id
    LEFT JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY ci.city_name
)
SELECT
    ci.city_name,
    ci.population,
    ROUND(ci.population * 0.25) AS estimated_coffee_consumers,
    ac.actual_customers
FROM city ci
JOIN actual_customers ac ON ci.city_name = ac.city_name
ORDER BY estimated_coffee_consumers DESC;


--Q10. Identify Low-Performing Cities
--Which cities have customers but low revenue?

SELECT
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS customers,
    COALESCE(SUM(s.total), 0) AS revenue
FROM city ci
LEFT JOIN customers c ON ci.city_id = c.city_id
LEFT JOIN sales s ON c.customer_id = s.customer_id
GROUP BY ci.city_name
HAVING COALESCE(SUM(s.total), 0) < 50000
ORDER BY revenue;

