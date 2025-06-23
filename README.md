# Rapport de Projet – Analyse des Ventes Supermarché

## Présentation du projet
Ce projet vise à analyser les ventes, la rentabilité et les pertes d’un supermarché à partir de plusieurs fichiers CSV, intégrés dans une base de données SQLite. L’objectif est de fournir des indicateurs clés et des insights commerciaux pour optimiser la gestion des produits.

## Structure des données
- **items** : Détails des articles (code, nom, catégorie)
- **sales** : Historique des ventes (date, heure, quantité, prix, remise, retour)
- **wholesale_prices** : Prix de gros par article et date
- **loss_rates** : Taux de perte par article

## Méthodologie
1. Importation des fichiers CSV dans SQLite
2. Création de tables et renommage pour plus de clarté
3. Rédaction et exécution de requêtes SQL pour l’analyse

## Documentation des requêtes SQL

### 1. Liste des tables
```sql
SELECT name FROM sqlite_master WHERE type='table';
```
Affiche toutes les tables présentes dans la base de données.

### 2. TOP 10 des produits les plus vendus en poids
```sql
SELECT s.Item_Code, i.Item_Name, SUM(s.Quantity_Sold) AS total_weight_kg
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
GROUP BY s.Item_Code, i.Item_Name
ORDER BY total_weight_kg DESC
LIMIT 10;
```
Permet d’identifier les produits les plus populaires en volume.

**Résultat obtenu :**
![alt text](<images/top 10 des produits les plus vendu.png>)
On constate que les légumes-feuilles, choux, poivrons et champignons dominent largement les ventes en poids, ce qui reflète leur popularité et leur importance dans l’assortiment du supermarché.

### 3. TOP 10 des produits les plus rentables
```sql
SELECT s.Item_Code, i.Item_Name, SUM((s.Unit_Selling_Price - wp.Wholesale_Price) * s.Quantity_Sold) AS total_margin
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
LEFT JOIN wholesale_prices wp ON s.Item_Code = wp.Item_Code AND s.Date = wp.Date
GROUP BY s.Item_Code, i.Item_Name
ORDER BY total_margin DESC
LIMIT 10;
```
Classe les produits selon la marge totale générée.

**Résultat obtenu :**
![alt text](<images/top 10 produits rentables.png>)
On observe que les produits les plus rentables sont principalement des légumes frais, avec une forte marge générée par le brocoli, les champignons et les poivrons. Cela indique une bonne gestion des prix de vente par rapport aux prix de gros pour ces références.

### 4. Évolution du chiffre d’affaires par mois
```sql
SELECT SUBSTR(Date, 1, 7) AS month, SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY month
ORDER BY month;
```
Suit la progression du chiffre d’affaires mois par mois.

**Résultat obtenu :**
![alt text](<images/evolution chiffre d'affaire par mois.png>)
On observe une forte saisonnalité du chiffre d’affaires, avec des pics notables en février 2021 et janvier 2023, probablement liés à des événements ou fêtes saisonnières. Les mois d’été et d’automne présentent généralement un CA plus faible.

### 5. Analyse des ventes avec ou sans remise
```sql
SELECT Discount, COUNT(*) AS nb_ventes, SUM(Quantity_Sold) AS total_quantite, SUM(Quantity_Sold * Unit_Selling_Price) AS chiffre_affaires
FROM sales
GROUP BY Discount;
```
Compare le volume et le CA des ventes avec ou sans remise.

**Résultat obtenu :**
![alt text](<images/analyse des ventes avec ou sans remise.png>)

On constate que la grande majorité des ventes (en volume et en chiffre d’affaires) sont réalisées sans remise. Les ventes avec remise représentent une faible part du total, ce qui peut indiquer une politique de promotion limitée ou ciblée.

### 6. Taux de perte total estimé par catégorie
```sql
SELECT i.Category_Name, AVG(lr.Loss_Rate) AS avg_loss_rate
FROM loss_rates lr
LEFT JOIN items i ON lr.Item_Code = i.Item_Code
GROUP BY i.Category_Name
ORDER BY avg_loss_rate DESC;
```
Évalue les pertes moyennes par catégorie de produits.

**Résultat obtenu :**
![alt text](<images/Taux de perte total estimée par catégorie.png>)

On constate que la catégorie "Cabbage" présente le taux de perte moyen le plus élevé (14,1%), suivie des légumes aquatiques et tubéreux, puis des légumes-feuilles. Les champignons et les solanacées affichent les taux de perte les plus faibles, ce qui peut orienter les efforts de réduction des pertes.

### 7. TOP 10 des produits les plus coûteux à stocker
```sql
SELECT lr.Item_Code, i.Item_Name, lr.Loss_Rate
FROM loss_rates lr
LEFT JOIN items i ON lr.Item_Code = i.Item_Code
ORDER BY lr.Loss_Rate DESC
LIMIT 10;
```
Identifie les produits avec le taux de perte le plus élevé.

**Résultat obtenu :**
![alt text](<images/TOP 10 des produits les plus coûteux à stocker.png>)

On remarque que certains légumes comme le High Melon, le Chuncai ou le Purple Cabbage présentent des taux de perte très élevés (jusqu’à 29%). Ces produits sont donc particulièrement coûteux à stocker et nécessitent une attention particulière pour limiter les pertes.

### 8. Produits très vendus mais peu rentables
```sql
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
```
Repère les produits populaires mais peu rentables.

**Résultat obtenu :**
![alt text](<images/Produits très vendus mais peu rentables.png>)

On constate que certains produits, bien qu’ils soient très vendus en poids, génèrent une marge relativement faible. Cela peut indiquer une forte concurrence sur les prix ou des coûts d’approvisionnement élevés, et invite à revoir la stratégie de tarification ou d’achat pour ces références.

### 9. Produits souvent retournés
```sql
SELECT s.Item_Code, i.Item_Name, COUNT(*) AS nb_retours, SUM(s.Quantity_Sold) AS total_retourne
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
WHERE s.Sale_or_Return = 'return'
GROUP BY s.Item_Code, i.Item_Name
ORDER BY nb_retours DESC, total_retourne DESC
LIMIT 10;
```
Liste les produits les plus fréquemment retournés.

**Résultat obtenu :**
![alt text](<images/Produits souvent retournés.png>)

On remarque que certains produits très populaires comme le Wuhu Green Pepper ou le Broccoli sont aussi ceux qui font l’objet du plus grand nombre de retours, ce qui peut signaler des problèmes de qualité, de conservation ou d’adéquation à la demande.

### 10. Produits toujours vendus avec remise
```sql
SELECT s.Item_Code, i.Item_Name, COUNT(*) AS nb_ventes_remise, SUM(s.Quantity_Sold) AS total_vendu_remise
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
WHERE s.Discount = 'Yes'
GROUP BY s.Item_Code, i.Item_Name
HAVING COUNT(*) = (
  SELECT COUNT(*) FROM sales s2 WHERE s2.Item_Code = s.Item_Code
)
ORDER BY nb_ventes_remise DESC;
```
Montre les produits pour lesquels toutes les ventes ont été faites avec remise.

**Résultat obtenu :**
![alt text](<images/Produits toujours vendus avec remise.png>)

On observe que seuls quelques produits sont systématiquement vendus avec remise, ce qui peut correspondre à des stratégies de déstockage ou à des produits difficiles à écouler au prix fort.

### 11. Jour et heure générant le plus de chiffre d’affaires
```sql
-- Jour
SELECT Date, SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY Date
ORDER BY total_revenue DESC
LIMIT 1;
-- Heure
SELECT SUBSTR(Time, 1, 2) AS hour, SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY hour
ORDER BY total_revenue DESC
LIMIT 1;
```
Permet d’identifier les pics de chiffre d’affaires par jour et par heure.

**Résultat obtenu :**


![alt text](<images/heure la plus performante.png>)
![alt text](<images/jour ayant le plus haut CA.png>)
- Le jour ayant généré le plus de chiffre d’affaires est le 2021-02-10 avec 28 736,51 RMB.
- L’heure la plus performante est 10h, avec un chiffre d’affaires cumulé de 468 435,96 RMB.

Ces pics peuvent correspondre à des événements particuliers (fêtes, promotions) ou à des habitudes d’achat spécifiques (affluence en matinée).

### 12. Heures générant le plus de chiffre d'affaires (top 5)
```sql
SELECT 
    SUBSTR(Time, 1, 2) AS hour,
    SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY hour
ORDER BY total_revenue DESC
LIMIT 5;
```
Permet d’identifier les créneaux horaires les plus porteurs en chiffre d’affaires.

**Résultat obtenu :**
![alt text](<images/Heure generant le plus de CA.png>)

On constate que la tranche 10h-11h est de loin la plus performante, suivie de près par 11h, puis les créneaux de fin d’après-midi (16h-18h). Cela reflète probablement les pics d’achats en matinée et en fin de journée, typiques des habitudes de consommation en supermarché.

### 13. Jours de la semaine générant le plus de chiffre d’affaires
```sql
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
```
Permet d’identifier les jours de la semaine les plus porteurs en chiffre d’affaires.

**Résultat obtenu :**
![alt text](<images/jour_semaine_ca.png>)

On observe que le samedi et le dimanche sont les jours générant le plus de chiffre d’affaires, suivis du vendredi. Cela traduit une forte affluence en fin de semaine, probablement liée aux achats du week-end. Les jours de semaine présentent un chiffre d’affaires plus modéré.

### 14. Catégorie la plus performante (chiffre d'affaires total)
```sql
SELECT 
  i.Category_Name,
  SUM(s.Quantity_Sold * s.Unit_Selling_Price) AS total_revenue
FROM sales s
LEFT JOIN items i ON s.Item_Code = i.Item_Code
GROUP BY i.Category_Name
ORDER BY total_revenue DESC
LIMIT 1;
```
Affiche la catégorie ayant généré le plus de chiffre d’affaires.

**Résultat obtenu :**
![alt text](<images/Catégorie la plus performante.png>)
- La catégorie la plus performante est "Flower/Leaf Vegetables" avec un chiffre d’affaires total de 1 079 069,80 RMB.

Cela montre l’importance de cette catégorie dans le mix produit du supermarché.

### 15. Corrélation entre discount et vente (volume et chiffre d'affaires)
```sql
SELECT 
  Discount,
  AVG(Quantity_Sold) AS avg_quantity_sold,
  SUM(Quantity_Sold) AS total_quantity_sold,
  AVG(Quantity_Sold * Unit_Selling_Price) AS avg_revenue,
  SUM(Quantity_Sold * Unit_Selling_Price) AS total_revenue
FROM sales
GROUP BY Discount;
```
Analyse l’impact des remises sur le volume et le chiffre d’affaires.

**Résultat obtenu :**
![alt text](<images/Corrélation entre discount et vente.png>)
- Sans remise : volume moyen par vente 0,53 kg, CA moyen 3,86 RMB, total 3 208 647 RMB.
- Avec remise : volume moyen par vente 0,67 kg, CA moyen 3,40 RMB, total 161 119 RMB.

Les ventes avec remise sont plus importantes en volume par transaction, mais génèrent un chiffre d’affaires moyen plus faible, ce qui reflète l’effet attendu des promotions.

---

## Conclusion
Ce rapport synthétise les principales analyses réalisées sur les ventes, la rentabilité et les pertes. Il peut être enrichi selon vos besoins (visualisations, analyses croisées, etc.).
