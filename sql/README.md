### Задание 2. Пояснительная записка.
##### 2.1) Предложите решение по хранению данных об оплатах, возможную структуру дополнительных полей/таблиц.

Для реализации структур баз данных и тестирования запросов была выбрана СУБД **PostgreSQL 9.5.6**.

 В ходе выполнения задания заключающегося в разработке решения по хранению данных об оплатах,  
для получения необходимых данных по платежам,  
было разработано две возможные структуры баз данных.  
Структуры баз данных представлены в соответствующих файлах:  
- **db_structure_additional_pmRest_trAccrual.sql**  
- **db_structure_without_additional_fields.sql**      

В обеих структурах данных была введена дополнительная таблица transfers,  
обеспечивающая связь "многое ко многим" между таблицей сделок и таблицей платежей.  

Структура таблицы определяет следующие поля:   
  * _trfPayment_ - ссылка на платеж, с которого было произведено списание.
  * _trfTransaction_ - ссылка на сделку, на которую было произведено начисление.  
  * _trfSum_ - хранит данные о сумме перечисления.

Главное отличие структур - наличие дополнительных полей _trAccrual_ и _pmRest_ в
таблицах **transactions** и **payments** соответственно.

##### Структура с дополнительными полями представлена в файле db_structure_additional_pmRest_trAccrual.sql.

Поле **pmRest** предназначено для хранения суммы остатка, не распределенного по сделкам.    
Поле **trAccrual** хранит информацию о сумме начисленных средств по сделке.  

Данное решение обеспечивает некоторую избыточность данных,
но зато обеспечивает более быструю и прозрачную работу с данными.  
_(Далее будет предложено исследование эффективности возможных запросов,
направленных на полученье данных о платежах)_  
Для того чтобы поддерживать актуальную информацию о сумме остатка в поле pmRest(и поле trAccrual),
была введена система функций и триггеров. Так же были добавлены логически целесообразные ограничения на
допустимые изменения данных в полях pmRest и trAccrual *(значение поля pmRest не может быть меньше 0,
значение trAccrual не должно превышать сумму по сделке).*
Система функций и ограничений автоматически вычисляет информацию о нераспределенном остатке по платежу
и общей начисленной сумме по сделке. Это позволяет пользователю не заботиться о дополнительной актуализации
данных при добавлении, изменении, удалении переводов между платежами и сделками.  

##### Структура с дополнительными полями представлена в файле db_structure_without_additional_fields.sql.  

При данной структуре данных информация о нераспределенной сумме остатка в таблице не хранится,
а вычисляется непосредственно при выполнении соответствующего запроса.
Для поддержания логически целесообразных данных в структуре была введена система триггеров, функций
и ограничений. Выражаясь неформально, система вычисляет сумму не распределенного остатка по платежу
(и сумму всех начислений по сделке) при каждой попытке добавить(изменить) перевод между сделкой и платежом и не позволит выполнить соответствующее действие, если сумма перевода будет превышать сумму не распределенного остатка
(либо сумма перевода при зачислении будет больше суммы необходимой для полной оплаты по сделке).

**Ограничения для обеих структур данных описанные ранее были введены исходя из логических соображений
и являются опциональными.**  

##### 2.2) SQL-запросы, которые отображают  всю  информацию по каждому платежу.  

###### Для получения данных предлагается 4 возможных запроса.  

1. Универсальный, подходит для обоих разработанных струтур данных.  

  SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest
  FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber;


2. Универсальный, подходит для обоих разработанных струтур данных.  

  SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum) FROM transfers
                                          WHERE pmNumber=trfPayment GROUP BY trfPayment), 0)) AS pmRest
  FROM payments;


3. Подходит для обоих разработанных струтур данных.  

  SELECT pmId, pmNumber, pmDate, pmSum, rest.pmRest
  FROM payments JOIN (SELECT pmNumber, sum(pmSum) AS pmRest
                      FROM(
                          SELECT pmId, pmNumber, pmDate, pmSum FROM payments
                          UNION ALL
                          SELECT trfId, trfPayment, tfrDate, -trfSum FROM transfers
                      ) as tr GROUP BY pmNumber) as rest
  USING (pmNumber);


4. Запрос для базы данных со структурой описанной в файле **db_structure_additional_pmRest_trAccrual.sql**  

  SELECT * FROM payments;


###### Результат выполнения запросов(фрагмент):  
  
  
      pmid  | pmnumber |                          pmdate               |  pmsum  | pmrest    
    ----------+----------------+------------------------------------------+-------------+---------   
     10009 | 10000          | 2017-04-27 14:03:25.754615 |  124.00    |   30.49  
     10010 | 10001          | 2017-04-27 14:03:25.754615 |  25.00      |   25.00  
     10011 | 10002          | 2017-04-27 14:03:25.754615 |  732.00    |    6.53  
     10012 | 10003          | 2017-04-27 14:03:25.754615 |  336.00    |  133.11  
     10013 | 10004          | 2017-04-27 14:03:25.754615 |  450.00    |   63.05   
     10014 | 10005          | 2017-04-27 14:03:25.754615 |  420.00    |   42.25  
     10015 | 10006          | 2017-04-27 14:03:25.754615 |  333.00    |  143.75   
     10016 | 10007          | 2017-04-27 14:03:25.754615 |  948.00    |  222.24  
     10017 | 10008          | 2017-04-27 14:03:25.754615 |  830.00    |  470.18  
     10018 | 10009          | 2017-04-27 14:03:25.754615 |  598.00    |  157.07  
      


##### 2.3) Исследование эффективности запросов.  

Исследование эффективности запросов проводилось на СУБД PostgreSQL 9.5.6.

Количество записей в таблице transfers - 14418.
Количество записей в таблице payments - 15000.
Количество записей в таблице transactions - 15000.


Наиболее эффективный запросом является запрос № 4.

Судить об этом можно основываясь на плане запроса, 
генерируемом планировщиком бызы данных для заданного оператора.

  EXPLAIN(ANALYZE) SELECT * FROM payments;  


    Seq Scan on payments  (cost=0.00..344.00 rows=15000 width=27) (actual time=0.017..20.101 rows=15000 loops=1)  
    Planning time: 0.307 ms  
    Execution time: 38.679 ms  
    (3 rows)

Далее представленны планы для других запросов;

Запрос №3.

  EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, rest.pmRest  
  FROM payments JOIN (SELECT pmNumber, sum(pmSum) AS pmRest  
                    FROM(  
                        SELECT pmId, pmNumber, pmDate, pmSum FROM payments  
                        UNION ALL  
                        SELECT trfId, trfPayment, tfrDate, -trfSum FROM transfers  
                    ) as tr GROUP BY pmNumber) as rest  
  USING (pmNumber);  

    Hash Join  (cost=1316.77..1324.02 rows=200 width=53) (actual time=219.429..293.105 rows=15000 loops=1)  
    Hash Cond: ((payments_1.pmnumber)::text = (payments.pmnumber)::text)  
    ->  HashAggregate  (cost=785.27..787.77 rows=200 width=23) (actual time=173.065..201.286 rows=15000 loops=1)  
         Group Key: payments_1.pmnumber  
         ->  Append  (cost=0.00..638.18 rows=29418 width=23) (actual time=0.015..113.173 rows=29418 loops=1)  
               ->  Seq Scan on payments payments_1  (cost=0.00..344.00 rows=15000 width=9) (actual time=0.010..21.017 rows=15000 loops=1)  
               ->  Seq Scan on transfers  (cost=0.00..294.18 rows=14418 width=37) (actual time=0.024..22.272 rows=14418 loops=1)  
    ->  Hash  (cost=344.00..344.00 rows=15000 width=21) (actual time=46.297..46.297 rows=15000 loops=1)  
         Buckets: 16384  Batches: 1  Memory Usage: 1014kB  
         ->  Seq Scan on payments  (cost=0.00..344.00 rows=15000 width=21) (actual time=0.019..23.411 rows=15000 loops=1)  
    Planning time: 0.495 ms  
    Execution time: 311.093 ms  
    (12 rows)


Запрос №2.  
    
  SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum) FROM transfers  
                                          WHERE pmNumber=trfPayment GROUP BY trfPayment), 0)) AS pmRest  
  FROM payments;
  
       Seq Scan on payments  (cost=0.00..4954281.50 rows=15000 width=21) (actual time=4.521..51724.016 rows=15000 loops=1)
       SubPlan 1
         ->  GroupAggregate  (cost=0.00..330.26 rows=2 width=11) (actual time=3.431..3.432 rows=1 loops=15000)
               Group Key: transfers.trfpayment
               ->  Seq Scan on transfers  (cost=0.00..330.23 rows=2 width=11) (actual time=2.141..3.413 rows=1 loops=15000)
                     Filter: ((payments.pmnumber)::text = (trfpayment)::text)
                     Rows Removed by Filter: 14417
     Planning time: 0.304 ms
     Execution time: 51750.457 ms
    (9 rows)


Запрос №1.

  EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest  
  FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber;  
  
       HashAggregate  (cost=1098.93..1323.93 rows=15000 width=27) (actual time=182.229..213.442 rows=15000 loops=1)
       Group Key: payments.pmnumber
       ->  Hash Right Join  (cost=531.50..1023.93 rows=15000 width=27) (actual time=49.014..133.000 rows=19890 loops=1)
             Hash Cond: ((transfers.trfpayment)::text = (payments.pmnumber)::text)
             ->  Seq Scan on transfers  (cost=0.00..294.18 rows=14418 width=11) (actual time=0.006..22.147 rows=14418 loops=1)
             ->  Hash  (cost=344.00..344.00 rows=15000 width=21) (actual time=48.813..48.813 rows=15000 loops=1)
                   Buckets: 16384  Batches: 1  Memory Usage: 1014kB
                   ->  Seq Scan on payments  (cost=0.00..344.00 rows=15000 width=21) (actual time=0.031..24.208 rows=15000 loops=1)
     Planning time: 0.567 ms
     Execution time: 231.393 ms
    (10 rows)
