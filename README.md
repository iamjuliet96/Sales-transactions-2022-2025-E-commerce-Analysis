# Sales Transaction 2022-2025 E-Commerce Analysis
## Table Of Contents
-	[Project Overview](#project-overview)
-	[Dashboard screenshot](#dashboard-screenshot)
-	[Live Dashboard](#live-dashboard)
-	[Business Problem](#business-problem)
-	[Dataset](#dataset)
-	[Tools](#tools)
-	[Data-Cleaning-Process](#data-cleaning-process)
-	[Method notes](#method-notes)
-	[Key Findings](#key-findings)
-	[Recommendations](#recommendations)
-	[Limitations](#limitations)
-	[How to Reproduce](#how-to-reproduce)

### Project Overview
This is an End-to-end data analysis project covering data cleaning, SQL analysis, and an interactive Power BI dashboard, built on the  sales transaction 2022-2025 E-Commerce public dataset.

### Dashboard screenshot
<img width="921" height="528" alt="sales_transaction Screenshot " src="https://github.com/user-attachments/assets/be23ea66-8a79-40e7-a159-86e873920436" />

### Live Dashboard
[View the interactive Power BI dashboard](https://drive.google.com/file/d/1XHe2riUybWv_ObXF59mzXkvnzS72pI_K/view?usp=sharing)
(If the link above doesn't load, see the screenshots above or the dashboard screenshot file.)

### Business Problem
This is a synthetic data set of a retailer selling through four channels (Online, Retail Store, B2B Portal, Phone Order) in six countries and he wants to know:
1. Which countries, regions and sales channels generate the most revenue and profit, and where is the profit margin weakest relative to sales?
2. At what discount level do transactions become unprofitable, and how much profit do discounts above that level give away?
3. Which product categories and subcategories have the highest return rates, and which return reasons cost the most revenue?
4. How have revenue, profit, order volume and average order value trended by month and year from 2022 to 2025, and is there seasonality?
5. Do delivery time and shipping method affect customer ratings and returns? 
  
### Dataset
Orignal dataset: sales_transaction_2022_2025, originally sourced from kaggle.
File used for this project: sales_transaction_2022_2025.csv
[Download dataset here] (https://drive.google.com/file/d/16vKNjR-B7H3OB6E5Nvn1cyMsgYpomveK/view?usp=sharing) 
Raw CSVs are not included in this repo due to file size and dataset licensing.

### Tools
- **SQL Server / SSMS** — data cleaning,  analysis queries
- **Power BI** — (DAX for measures), data modeling (star schema) and interactive dashboard
- **Excel** — initial exploration

### Data Cleaning Process
Full sql scripts are in data cleaninf file
1. **Grain identification** —  Transaction_ID is the key. Order_ID is not reliable (it repeats across different transactions), so orders are   never counted with COUNT(DISTINCT Order_ID).
2. **Profile	Checks** - for nulls, blanks, placeholders, trailing spaces, duplicates, impossible values
3. **Duplicate checks** —  45 exact duplicates were removed using a window function.
4. **Null handling** — nulls were evaluated individually, not dropped by default
5. Data types were changed, data were sandardized  and hidden label variant removed
6. **Recover**	- Missing customer and product attributes filled from other rows with the same ID
7. **Validate** - Impossible ages set to NULL

### Method notes
- Net revenue excludes Cancelled and Returned orders.
- Margin is always SUM(ProfitReported) / SUM(SalesAmount), never an average of row margins.
- Return rates exclude cancelled lines, because those never shipped.
- Rates use 1.0 * or 100.0 * to avoid SQL Server integer division.

### key Findings
**1. Revenue and profit by segment**
The US brings in 42.5% of net revenue, online brings in 37.5% while England by region brings 16.0% of net revenue  but margin is almost identical everywhere (19.7%–20.4% by country, 19.8%–20.2% by channel and 19.7%-20.4% by region). The one clear weak spot is US Midwest, B2B Portal at 17.07%, about 2.9 points below the 19.95% overall margin.

**2. Discounts**
Margin falls from 25.1% with no discount to 0.6% above 20%. About 29% of lines at a 25% discount lose money, and customers do not buy larger quantities when discounted (average quantity stays at about 2.1–2.2).

**3. Returns**
Appliances (kitchen) have the highest return rate (13.53%), even though Electronics generated the highest amount revenue lost(284k). Changed my mind return reason generated the most revenue loss of 154k

**4. Trend and seasonality**
Net revenue dipped in 2023 (−1.7%) and 2024 (−4.8%), then grew 21.4% in 2025. November and December run about 35% above the average month; January and February about 25% below.

**5. Delivery speed and shipping method**
Delivery time and shipping method has essentially no clear or consistent relationship with customer rating and return rate. Ratings stay near 3.0 for standard, Express and pick up and 4.0 for next day, while return rate stayed at a narrow range of 10.44% to 12.35% regardless of shipping method and delivery time.

### Recommendations 
**1.** Cap discounts at 15% and require approval above that. Margin drops from 25.1% (no discount) to 11.9% at 15% and 6.2% at 20%. Lines discounted 20% or more brought in about 463k of revenue but only about 23k of profit (4.9% margin), and 10.5% of 20% lines and 28.7% of 25% lines lose money. Discounted customers do not buy more per line, so the deeper discounts are not buying volume.

**2.** Review pricing and discounts on US Midwest B2B. It is the clearest weak segment (17.07% margin vs 19.95% overall, roughly 2.9k of profit below the average margin). Check whether large B2B orders there are being discounted more heavily than elsewhere.

**3.** Attack the logistics causes of returns first.  Changed my mind caused the largest revenue lost followed by late delivery. Defective and damaged goods together make up 32.41% and these are fixable through accurate product information, improve delivery reliability  and strenthened quality control control and packaging. Prioritise Electronics (laptops) which accounts for about 34.59% of total returned revenue.

**4.** Plan around the seasonal peak. November and December run about 35% above the average month and October about 17% above; January and February run about 25% below. Align stock and staffing to the peak, and use light, capped promotions to clear slow stock and keep traffic to lift the January–February dip. Also use non-discount levers such as bundles, free delivery and better product pages for january-febuary.

**5** Do not expect faster shipping to raise satisfaction. Delivery time shows no relationship with ratings. Investigate other drivers of the rating, such as product quality and returns experience, before investing in speed.


### Limitations
- Order-level analysis is not possible because Order_ID is unreliable; everything is at product-line grain.
- Margins are unusually uniform across countries and channels, which is consistent with a simulated dataset, so segment differences should be read cautiously.
- Discount and delivery findings are observational associations across transactions, not casual or controlled tests results.
  
### How to Reproduce
Download the dataset from link above.
Run the SQL scripts in `/sql` in order (01 → 05) against a SQL Server database.
Open the google drive above in Power BI Desktop, connect it to your database, and refresh.

