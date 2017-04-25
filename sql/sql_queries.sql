/*
Запросы, которые отобразят  всю  информацию по каждому платежу включая
дополнительное поле pmRest - сумму нераспределенного на оплаты остатка по этому платежу.  
*/

-- Универсальный, подходит для обоих разработанных струтур данных.
SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest
FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber ORDER BY pmid;




-- Запрос для базы данных со структурой описанной в файле
-- db_structure_additional_pmRest_trAccrual.sql


SELECT * FROM payments;

/*
Результат выполнения для db_structure_additional_pmRest_trAccrual.sql
EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest
FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber;

HashAggregate  (cost=13.54..13.67 rows=9 width=33) (actual time=0.136..0.150 rows=9 loops=1)
   Group Key: payments.pmnumber
   ->  Hash Right Join  (cost=1.20..13.49 rows=9 width=33) (actual time=0.075..0.097 rows=10 loops=1)
         Hash Cond: ((transfers.trfpayment)::text = (payments.pmnumber)::text)
         ->  Seq Scan on transfers  (cost=0.00..11.60 rows=160 width=160) (actual time=0.003..0.007 rows=2 loops=1)
         ->  Hash  (cost=1.09..1.09 rows=9 width=19) (actual time=0.049..0.049 rows=9 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Seq Scan on payments  (cost=0.00..1.09 rows=9 width=19) (actual time=0.013..0.024 rows=9 loops=1)
 Planning time: 0.276 ms
 Execution time: 0.262 ms
*/


/*
Результат выполнения для db_structure_additional_pmRest_trAccrual.sql
EXPLAIN(ANALYZE) SELECT * FROM payments;

Seq Scan on payments  (cost=0.00..1.09 rows=9 width=24) (actual time=0.013..0.025 rows=9 loops=1)
 Planning time: 0.071 ms
 Execution time: 0.074 ms
*/