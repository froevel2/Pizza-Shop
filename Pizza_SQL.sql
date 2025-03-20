
SELECT 
    od.order_details_id,
    od.order_id,
    od.pizza_id,
    od.quantity,
    o.date,
    o.time,
    pt.name AS pizza_name, -- Usamos la columna 'name' de la tabla 'pizza_types'
    p.price,
    pt.category,
    pt.ingredients
FROM 
    order_details od
JOIN 
    orders o
ON 
    od.order_id = o.order_id
JOIN 
    pizzas p
ON 
    od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt
ON 
    p.pizza_type_id = pt.pizza_type_id;


SELECT 
    od.order_details_id,
    od.order_id,
    od.pizza_id,
    od.quantity,
    o.date,
    o.time,
    pt.name AS pizza_name,
    p.price,
    pt.category,
    pt.ingredients
INTO 
    full_orders -- Nombre de la nueva tabla
FROM 
    order_details od
JOIN 
    orders o
ON 
    od.order_id = o.order_id
JOIN 
    pizzas p
ON 
    od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt
ON 
    p.pizza_type_id = pt.pizza_type_id;

--Total Revenue

SELECT 
    SUM(p.price * od.quantity) AS total_revenue
FROM 
    order_details od
JOIN 
    pizzas p
ON 
    od.pizza_id = p.pizza_id;


SELECT 
    pizza_id, 
    price 
FROM 
    pizzas
WHERE 
    price = (SELECT MAX(price) FROM pizzas);


SELECT 
    MAX(CAST(price AS DECIMAL(10, 2))) AS max_price
FROM pizzas;

EXEC sp_columns pizzas;

ALTER TABLE pizzas
ALTER COLUMN price DECIMAL(10, 2);

SELECT 
    pizza_id, 
    price 
FROM pizzas
WHERE price = 35.95;

UPDATE pizzas
SET price = price / 100.0;

SELECT 
    pizza_id, 
    price 
FROM pizzas
WHERE price = 35.95;


SELECT 
    pizza_id,
    price
FROM (
    SELECT 
        pizza_id,
        price,
        RANK() OVER (ORDER BY price DESC) AS rank
    FROM 
        pizzas
) ranked_pizzas
WHERE rank = 1;


SELECT TOP 5
    pt.name AS pizza_type,
    SUM(cast(od.quantity as int)) AS total_quantity
FROM 
    order_details od
JOIN 
    pizzas p
ON 
    od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt
ON 
    p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.name
ORDER BY 
    total_quantity DESC;



SELECT quantity
FROM order_details
WHERE ISNUMERIC(quantity) = 0;


SELECT 
    pt.category AS pizza_category,
    SUM(od.quantity) AS total_quantity
FROM 
    order_details od
JOIN 
    pizzas p
ON 
    od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt
ON 
    p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.category
ORDER BY 
    total_quantity DESC;



EXEC sp_columns 'order_details';

ALTER TABLE order_details
ALTER COLUMN quantity INT;



SELECT 
    DATEPART(HOUR, CAST(time AS TIME)) AS order_hour, 
    COUNT(*) AS total_orders
FROM 
    orders
GROUP BY 
    DATEPART(HOUR, CAST(time AS TIME))
ORDER BY 
    total_orders
	desc;


SELECT 
    category, 
    COUNT(DISTINCT pizza_type_id) AS [No of pizzas]
FROM 
    pizza_types
GROUP BY 
    category
ORDER BY 
    [No of pizzas];


SELECT 
    COUNT(order_id) * 1.0 / COUNT(DISTINCT date) AS avg_pizzas_per_day
FROM 
    orders;


WITH cte AS (
    SELECT 
        orders.date AS Date, 
        SUM(order_details.quantity) AS Total_Pizza_Ordered_That_Day
    FROM 
        order_details
    JOIN 
        orders 
    ON 
        order_details.order_id = orders.order_id
    GROUP BY 
        orders.date
)
SELECT 
    AVG(Total_Pizza_Ordered_That_Day) AS Avg_Number_of_Pizzas_Ordered_Per_Day 
FROM 
    cte;


SELECT TOP 3 
    pt.name AS pizza_type, -- Pizza Name
    SUM(od.quantity * p.price) AS total_revenue -- Calcula los ingresos totales.
FROM 
    order_details od
JOIN 
    pizzas p
ON 
    od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt
ON 
    p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.name
ORDER BY 
    total_revenue DESC;


WITH total_revenue AS (
    SELECT 
        SUM(order_details.quantity * pizzas.price) AS total
    FROM 
        order_details
    JOIN 
        pizzas ON pizzas.pizza_id = order_details.pizza_id
)
SELECT 
    pizza_types.name,
    CONCAT(
        CAST(
            (SUM(order_details.quantity * pizzas.price) / total_revenue.total) * 100 AS DECIMAL(10, 2)
        ), '%'
    ) AS revenue_contribution_percentage
FROM 
    order_details
JOIN 
    pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN 
    pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
CROSS JOIN 
    total_revenue
GROUP BY 
    pizza_types.name, total_revenue.total
ORDER BY 
    revenue_contribution_percentage DESC;



-- Analyze the cumulative revenue generated over time
WITH cte AS (
    SELECT 
        orders.date AS Date,
        CAST(SUM(order_details.quantity * pizzas.price) AS DECIMAL(10, 2)) AS Revenue
    FROM 
        order_details
    JOIN 
        orders ON order_details.order_id = orders.order_id
    JOIN 
        pizzas ON pizzas.pizza_id = order_details.pizza_id
    GROUP BY 
        orders.date
)
SELECT 
    Date, 
    Revenue, 
    SUM(Revenue) OVER (ORDER BY Date) AS Cumulative_Sum
FROM 
    cte
ORDER BY 
    Date;


WITH revenue_per_pizza AS (
    SELECT 
        pt.category AS pizza_category,
        pt.name AS pizza_type,
        SUM(od.quantity * p.price) AS total_revenue
    FROM 
        order_details od
    JOIN 
        pizzas p ON od.pizza_id = p.pizza_id
    JOIN 
        pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY 
        pt.category, pt.name
),
ranked_pizzas AS (
    SELECT 
        pizza_category,
        pizza_type,
        total_revenue,
        RANK() OVER (PARTITION BY pizza_category ORDER BY total_revenue DESC) AS rank
    FROM 
        revenue_per_pizza
)
SELECT 
    pizza_category,
    pizza_type,
    total_revenue
FROM 
    ranked_pizzas
WHERE 
    rank <= 3
ORDER BY 
    pizza_category, rank;