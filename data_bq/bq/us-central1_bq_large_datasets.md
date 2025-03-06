# Analyzing Large Datasets with BigQuery

In this lab guide, we will be exploring the power of BigQuery when it comes to analyzing huge datasets. 

## Sample Query 1
- Data processed: 965GB
- Number of tables queried: 7
- Aggregation on multiple columns

Copy and paste the following query into the BigQuery Editor:
```sql
SELECT
  i_item_id,
  ca_country,
  ca_state,
  ca_county,
  AVG( CAST(cs_quantity AS FLOAT64)) agg1,
  AVG( CAST(cs_list_price AS FLOAT64)) agg2,
  AVG( CAST(cs_coupon_amt AS FLOAT64)) agg3,
  AVG( CAST(cs_sales_price AS FLOAT64)) agg4,
  AVG( CAST(cs_net_profit AS FLOAT64)) agg5,
  AVG( CAST(c_birth_year AS FLOAT64)) agg6,
  AVG( CAST(cd1.cd_dep_count AS FLOAT64)) agg7
FROM
  cloud-ai-take-off.tpcds_10T.catalog_sales,
  cloud-ai-take-off.tpcds_10T.customer_demographics cd1,
  cloud-ai-take-off.tpcds_10T.customer_demographics cd2,
  cloud-ai-take-off.tpcds_10T.customer,
  cloud-ai-take-off.tpcds_10T.customer_address,
  cloud-ai-take-off.tpcds_10T.date_dim,
  cloud-ai-take-off.tpcds_10T.item
WHERE
  cs_sold_date_sk = d_date_sk
  AND cs_item_sk = i_item_sk
  AND cs_bill_cdemo_sk = cd1.cd_demo_sk
  AND cs_bill_customer_sk = c_customer_sk
  AND cd1.cd_gender = 'M'
  AND cd1.cd_education_status = 'College'
  AND c_current_cdemo_sk = cd2.cd_demo_sk
  AND c_current_addr_sk = ca_address_sk
  AND c_birth_month IN (9,
    5,
    12,
    4,
    1,
    10)
  AND d_year = 2001
  AND ca_state IN ('ND',
    'WI',
    'AL',
    'NC',
    'OK',
    'MS',
    'TN')
GROUP BY
  ROLLUP (i_item_id,
    ca_country,
    ca_state,
    ca_county)
ORDER BY
  ca_country,
  ca_state,
  ca_county,
  i_item_id
LIMIT
  100;
```

## Sample Query 2
- Data processed: 4TB
- Number of tables queried: 1
- Uses regex, scan heavy

Copy and paste the following query into the BigQuery Editor:

```sql
SELECT
  title, language,
  SUM(views) AS views
FROM
  `cloud-ai-take-off.wikipedia_benchmark.Wiki100B`
WHERE
  REGEXP_CONTAINS(title,"G.*o.*o.*g")
GROUP BY
  1, 2
ORDER BY
  views DESC;
```
