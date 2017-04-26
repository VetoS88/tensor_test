/*
Запросы, которые отобразят  всю  информацию по каждому платежу включая
дополнительное поле pmRest - сумму нераспределенного на оплаты остатка по этому платежу.  
*/

-- Универсальный, подходит для обоих разработанных струтур данных.
SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest
FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber;


-- Универсальный, подходит для обоих разработанных струтур данных.
SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum) FROM transfers
                                        WHERE pmNumber=trfPayment GROUP BY trfPayment), 0)) AS pmRest
FROM payments;


-- Подходит для обоих разработанных струтур данных.
SELECT pmId, pmNumber, pmDate, pmSum, rest.pmRest
FROM payments JOIN (SELECT pmNumber, sum(pmSum) AS pmRest
                    FROM(
                        SELECT pmId, pmNumber, pmDate, pmSum FROM payments
                        UNION ALL
                        SELECT trfId, trfPayment, tfrDate, -trfSum FROM transfers
                    ) as tr GROUP BY pmNumber) as rest
USING (pmNumber);



-- Запрос для базы данных со структурой описанной в файле
-- db_structure_additional_pmRest_trAccrual.sql
SELECT * FROM payments;



/*
Анализ выполнения для db_structure_additional_pmRest_trAccrual.sql
EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest
FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber;

 HashAggregate  (cost=13.54..13.67 rows=9 width=33) (actual time=0.190..0.204 rows=9 loops=1)
   Group Key: payments.pmnumber
   ->  Hash Right Join  (cost=1.20..13.49 rows=9 width=33) (actual time=0.073..0.121 rows=13 loops=1)
         Hash Cond: ((transfers.trfpayment)::text = (payments.pmnumber)::text)
         ->  Seq Scan on transfers  (cost=0.00..11.60 rows=160 width=160) (actual time=0.005..0.018 rows=10 loops=1)
         ->  Hash  (cost=1.09..1.09 rows=9 width=19) (actual time=0.050..0.050 rows=9 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Seq Scan on payments  (cost=0.00..1.09 rows=9 width=19) (actual time=0.015..0.028 rows=9 loops=1)
 Planning time: 0.226 ms
 Execution time: 0.295 ms


Результат запроса.
SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest
FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber ORDER BY pmnumber;
 pmid | pmnumber |           pmdate           | pmsum  | pmrest
------+----------+----------------------------+--------+--------
    3 | 100      | 2017-04-25 13:26:20.739363 | 918.00 | 318.00
    4 | 25       | 2017-04-25 13:26:20.739363 | 588.00 |  88.00
    6 | 45       | 2017-04-25 13:26:20.739363 | 652.00 | 152.00
    7 | 55       | 2017-04-25 13:26:20.739363 | 949.00 | 949.00
    2 | 59       | 2017-04-25 13:26:20.739363 | 574.00 | 474.00
    1 | 7        | 2017-04-25 13:26:20.739363 | 968.00 | 968.00
    9 | 72       | 2017-04-25 13:26:20.739363 | 744.00 | 344.00
    8 | 8        | 2017-04-25 13:26:20.739363 | 965.00 | 415.00
    5 | 86       | 2017-04-25 13:26:20.739363 | 806.00 | 806.00
(9 rows)

*/

/*
Анализ выполнения для db_structure_additional_pmRest_trAccrual.sql
EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum)
                                        FROM transfers
                                        WHERE pmNumber=trfPayment GROUP BY trfPayment), 0)) AS pmRest
FROM payments;

 Seq Scan on payments  (cost=0.00..11.55 rows=9 width=19) (actual time=0.037..0.179 rows=9 loops=1)
   SubPlan 1
     ->  GroupAggregate  (cost=0.00..1.16 rows=2 width=7) (actual time=0.012..0.013 rows=1 loops=9)
           Group Key: transfers.trfpayment
           ->  Seq Scan on transfers  (cost=0.00..1.12 rows=2 width=7) (actual time=0.004..0.006 rows=1 loops=9)
                 Filter: ((payments.pmnumber)::text = (trfpayment)::text)
                 Rows Removed by Filter: 9
 Planning time: 0.958 ms
 Execution time: 0.251 ms
(9 rows)


Результат запроса.
SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum)
                                        FROM transfers
                                        WHERE pmNumber=trfPayment GROUP BY trfPayment), 0)) AS pmRest
FROM payments ORDER BY pmnumber;

 pmid | pmnumber |           pmdate           | pmsum  | pmrest
------+----------+----------------------------+--------+--------
    3 | 100      | 2017-04-25 13:26:20.739363 | 918.00 | 318.00
    4 | 25       | 2017-04-25 13:26:20.739363 | 588.00 |  88.00
    6 | 45       | 2017-04-25 13:26:20.739363 | 652.00 | 152.00
    7 | 55       | 2017-04-25 13:26:20.739363 | 949.00 | 949.00
    2 | 59       | 2017-04-25 13:26:20.739363 | 574.00 | 474.00
    1 | 7        | 2017-04-25 13:26:20.739363 | 968.00 | 968.00
    9 | 72       | 2017-04-25 13:26:20.739363 | 744.00 | 344.00
    8 | 8        | 2017-04-25 13:26:20.739363 | 965.00 | 415.00
    5 | 86       | 2017-04-25 13:26:20.739363 | 806.00 | 806.00

(9 rows)
*/

/*
Анализ выполнения для db_structure_additional_pmRest_trAccrual.sql
EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, rest.pmRest
FROM payments JOIN (SELECT pmNumber, sum(pmSum) AS pmRest
                    FROM(
                        SELECT pmId, pmNumber, pmDate, pmSum FROM payments
                        UNION ALL
                        SELECT trfId, trfPayment, tfrDate, -trfSum FROM transfers
                    ) as tr GROUP BY pmNumber) as rest
USING (pmNumber);

 Hash Join  (cost=3.49..4.08 rows=9 width=51) (actual time=0.204..0.244 rows=9 loops=1)
   Hash Cond: ((payments_1.pmnumber)::text = (payments.pmnumber)::text)
   ->  HashAggregate  (cost=2.29..2.52 rows=19 width=21) (actual time=0.138..0.152 rows=9 loops=1)
         Group Key: payments_1.pmnumber
         ->  Append  (cost=0.00..2.19 rows=19 width=21) (actual time=0.005..0.090 rows=19 loops=1)
               ->  Seq Scan on payments payments_1  (cost=0.00..1.09 rows=9 width=7) (actual time=0.003..0.014 rows=9 loops=1)
               ->  Seq Scan on transfers  (cost=0.00..1.10 rows=10 width=34) (actual time=0.009..0.023 rows=10 loops=1)
   ->  Hash  (cost=1.09..1.09 rows=9 width=19) (actual time=0.050..0.050 rows=9 loops=1)
         Buckets: 1024  Batches: 1  Memory Usage: 9kB
         ->  Seq Scan on payments  (cost=0.00..1.09 rows=9 width=19) (actual time=0.014..0.024 rows=9 loops=1)
 Planning time: 12.134 ms
 Execution time: 0.334 ms
(12 rows)


Результат запроса.
SELECT pmId, pmNumber, pmDate, pmSum, rest.pmRest
FROM payments JOIN (SELECT pmNumber, sum(pmSum) AS pmRest
                    FROM(
                        SELECT pmId, pmNumber, pmDate, pmSum FROM payments
                        UNION ALL
                        SELECT trfId, trfPayment, tfrDate, -trfSum FROM transfers
                    ) as tr GROUP BY pmNumber) as rest
USING (pmNumber);
 pmid | pmnumber |           pmdate           | pmsum  | pmrest
------+----------+----------------------------+--------+--------
    3 | 100      | 2017-04-25 13:26:20.739363 | 918.00 | 318.00
    4 | 25       | 2017-04-25 13:26:20.739363 | 588.00 |  88.00
    6 | 45       | 2017-04-25 13:26:20.739363 | 652.00 | 152.00
    7 | 55       | 2017-04-25 13:26:20.739363 | 949.00 | 949.00
    2 | 59       | 2017-04-25 13:26:20.739363 | 574.00 | 474.00
    1 | 7        | 2017-04-25 13:26:20.739363 | 968.00 | 968.00
    9 | 72       | 2017-04-25 13:26:20.739363 | 744.00 | 344.00
    8 | 8        | 2017-04-25 13:26:20.739363 | 965.00 | 415.00
    5 | 86       | 2017-04-25 13:26:20.739363 | 806.00 | 806.00
*/


/*
Анализ выполнения для db_structure_additional_pmRest_trAccrual.sql
EXPLAIN(ANALYZE) SELECT * FROM payments;
 Seq Scan on payments  (cost=0.00..1.09 rows=9 width=24) (actual time=0.015..0.026 rows=9 loops=1)
 Planning time: 0.071 ms
 Execution time: 0.074 ms

Результат запроса.
SELECT * FROM payments ORDER BY pmnumber;
 pmid | pmnumber |           pmdate           | pmsum  | pmrest
------+----------+----------------------------+--------+--------
    3 | 100      | 2017-04-25 13:26:20.739363 | 918.00 | 318.00
    4 | 25       | 2017-04-25 13:26:20.739363 | 588.00 |  88.00
    6 | 45       | 2017-04-25 13:26:20.739363 | 652.00 | 152.00
    7 | 55       | 2017-04-25 13:26:20.739363 | 949.00 | 949.00
    2 | 59       | 2017-04-25 13:26:20.739363 | 574.00 | 474.00
    1 | 7        | 2017-04-25 13:26:20.739363 | 968.00 | 968.00
    9 | 72       | 2017-04-25 13:26:20.739363 | 744.00 | 344.00
    8 | 8        | 2017-04-25 13:26:20.739363 | 965.00 | 415.00
    5 | 86       | 2017-04-25 13:26:20.739363 | 806.00 | 806.00
*/