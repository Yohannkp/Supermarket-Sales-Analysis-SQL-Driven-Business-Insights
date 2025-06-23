-- Renommer les tables pour des noms plus explicites
ALTER TABLE annex1 RENAME TO items;
ALTER TABLE annex2 RENAME TO sales;
ALTER TABLE annex3 RENAME TO wholesale_prices;
ALTER TABLE annex4 RENAME TO loss_rates;

-- Vérifier les nouveaux noms de tables
SELECT name FROM sqlite_master WHERE type='table';


------------------------------ANALYSE DES VENTES-------------------------------

-- TOP 10 des produits les plus vendus en poids
SELECT s.Item_Code, i.Item_Name, SUM(s.Quantity_Sold) AS total_weight_kg
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
GROUP BY s.Item_Code, i.Item_Name
ORDER BY total_weight_kg DESC
LIMIT 10;

-- TOP 10 des produits les plus rentables (marge totale = (prix de vente - prix de gros) * quantité vendue)
SELECT 
  s.Item_Code, 
  i.Item_Name, 
  SUM((s.Unit_Selling_Price - wp.Wholesale_Price) * s.Quantity_Sold) AS total_margin
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
LEFT JOIN wholesale_prices wp ON s.Item_Code = wp.Item_Code AND s.Date = wp.Date
GROUP BY s.Item_Code, i.Item_Name
ORDER BY total_margin DESC
LIMIT 10;

-- Évolution du chiffre d’affaires par mois
SELECT 
  SUBSTR(Date, 1, 7) AS month,
  SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY month
ORDER BY month;

-- Analyse des ventes avec ou sans remise
SELECT 
  Discount,
  COUNT(*) AS nb_ventes,
  SUM(Quantity_Sold) AS total_quantite,
  SUM(Quantity_Sold * Unit_Selling_Price) AS chiffre_affaires
FROM sales
GROUP BY Discount;





-----------------------------------ANALYSE DES PERTES---------------------------------

-- Taux de perte total estimé par catégorie
SELECT 
  i.Category_Name,
  AVG(lr.Loss_Rate) AS avg_loss_rate
FROM loss_rates lr
LEFT JOIN items i ON lr.Item_Code = i.Item_Code
GROUP BY i.Category_Name
ORDER BY avg_loss_rate DESC;

-- TOP 10 des produits les plus coûteux à stocker (forte perte)
SELECT 
  lr.Item_Code,
  i.Item_Name,
  lr.Loss_Rate
FROM loss_rates lr
LEFT JOIN items i ON lr.Item_Code = i.Item_Code
ORDER BY lr.Loss_Rate DESC
LIMIT 10;


----------------------------------- PRODUITS PROBLEMATIQUES---------------------------------

-- Produits très vendus mais peu rentables
-- On sélectionne les produits dans le TOP 20 des ventes en poids, mais avec une marge totale faible
WITH ventes AS (
  SELECT s.Item_Code, i.Item_Name, SUM(s.Quantity_Sold) AS total_weight_kg
  FROM sales s
  LEFT JOIN items i ON s.Item_Code = i.Item_Code
  GROUP BY s.Item_Code, i.Item_Name
),
marges AS (
  SELECT s.Item_Code, SUM((s.Unit_Selling_Price - wp.Wholesale_Price) * s.Quantity_Sold) AS total_margin
  FROM sales s
  LEFT JOIN wholesale_prices wp ON s.Item_Code = wp.Item_Code AND s.Date = wp.Date
  GROUP BY s.Item_Code
)
SELECT v.Item_Code, v.Item_Name, v.total_weight_kg, m.total_margin
FROM ventes v
LEFT JOIN marges m ON v.Item_Code = m.Item_Code
ORDER BY v.total_weight_kg DESC, m.total_margin ASC
LIMIT 10;

-- Produits souvent retournés
SELECT 
  s.Item_Code,
  i.Item_Name,
  COUNT(*) AS nb_retours,
  SUM(s.Quantity_Sold) AS total_retourne
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
WHERE s.Sale_or_Return = 'return'
GROUP BY s.Item_Code, i.Item_Name
ORDER BY nb_retours DESC, total_retourne DESC
LIMIT 10;

-- Produits toujours vendus avec remise
SELECT 
  s.Item_Code,
  i.Item_Name,
  COUNT(*) AS nb_ventes_remise,
  SUM(s.Quantity_Sold) AS total_vendu_remise
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
WHERE s.Discount = 'Yes'
GROUP BY s.Item_Code, i.Item_Name
HAVING COUNT(*) = (
  SELECT COUNT(*) FROM sales s2 WHERE s2.Item_Code = s.Item_Code
)
ORDER BY nb_ventes_remise DESC;


----------------------------------- INSIGHTS COMMERCIAUX---------------------------------
-- Jours de la semaine générant le plus de chiffre d'affaires
SELECT 
    strftime('%w', Date) AS day_of_week,
    CASE strftime('%w', Date)
        WHEN '0' THEN 'Dimanche'
        WHEN '1' THEN 'Lundi'
        WHEN '2' THEN 'Mardi'
        WHEN '3' THEN 'Mercredi'
        WHEN '4' THEN 'Jeudi'
        WHEN '5' THEN 'Vendredi'
        WHEN '6' THEN 'Samedi'
    END AS jour_semaine,
    SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY day_of_week, jour_semaine
ORDER BY total_revenue DESC;

-- Heures générant le plus de chiffre d'affaires (top 5 heures)
SELECT 
    SUBSTR(Time, 1, 2) AS hour,
    SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY hour
ORDER BY total_revenue DESC
LIMIT 5;

-- Catégorie la plus performante (chiffre d'affaires total)
SELECT 
  i.Category_Name,
  SUM(s.Quantity_Sold * s.Unit_Selling_Price) AS total_revenue
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
GROUP BY i.Category_Name
ORDER BY total_revenue DESC
LIMIT 1;


-- Corrélation entre discount et vente (volume et chiffre d'affaires)
SELECT 
  Discount,
  AVG(Quantity_Sold) AS avg_quantity_sold,
  SUM(Quantity_Sold) AS total_quantity_sold,
  AVG(Quantity_Sold * Unit_Selling_Price) AS avg_revenue,
  SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY Discount;