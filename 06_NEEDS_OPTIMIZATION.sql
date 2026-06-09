SELECT 
    c.CustomerName,
    SUM(o.TotalAmount) AS TotalSpent
FROM `DB_SRCD2.Customers` AS c
JOIN `${SRC_DB}.Orders` AS o 
  ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY 1
ORDER BY TotalSpent DESC;
