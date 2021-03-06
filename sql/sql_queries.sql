/*
Запросы, которые отобразят  всю  информацию по каждому платежу, включая
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
                        SELECT pmNumber, pmSum FROM payments
                        UNION ALL
                        SELECT trfPayment, -trfSum FROM transfers
                    ) as tr GROUP BY pmNumber) as rest
USING (pmNumber);


-- Подходит для обеих разработанных струтур данных.
SELECT pmid, pmnumber, pmdate, pmsum, (pmSum-(COALESCE(t, 0))) as pmRest
FROM payments LEFT JOIN
(SELECT trfpayment, sum(trfSum) as t FROM transfers GROUP BY trfpayment) as tr ON pmnumber=trfpayment;


-- Запрос для базы данных со структурой описанной в файле
-- db_structure_additional_pmRest_trAccrual.sql
SELECT * FROM payments;

