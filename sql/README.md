## Задание 2. Пояснительная записка.
### 2.1) Предложите решение по хранению данных об оплатах, возможную структуру дополнительных полей/таблиц.

Для реализации структур баз данных и тестирования запросов была выбрана СУБД **PostgreSQL 9.5.6**.

 В ходе выполнения задания, заключающегося в разработке решения по хранению данных об оплатах,  
для получения необходимых данных по платежам,  
было разработано две структуры баз данных.  
Структуры баз данных представлены в соответствующих файлах:  
- **db_structure_additional_pmRest_trAccrual.sql**  
- **db_structure_without_additional_fields.sql**      

В обеих структурах данных была введена дополнительная таблица transfers,  
обеспечивающая связь "многое ко многим" между таблицей сделок и таблицей платежей.  

Структура таблицы определяет следующие  поля:   
  * _trfPayment_ - ссылка на платеж, с которого было произведено списание.
  * _trfTransaction_ - ссылка на сделку, на которую было произведено начисление.  
  * _trfSum_ - хранит данные о сумме перечисления.  
  * _trfNumber_ - номер операции.  
  * _tfrDate_ - дата операции.  
  * _trfId_ - id операции.  

Главное отличие структур - наличие дополнительных полей _trAccrual_ и _pmRest_ в
таблицах **transactions** и **payments** соответственно.

#### Структура с дополнительными полями представлена в файле db_structure_additional_pmRest_trAccrual.sql.

Поле **pmRest** предназначено для хранения суммы остатка, не распределенного по сделкам.    
Поле **trAccrual** хранит информацию о сумме начисленных средств по сделке.  

Данное решение обеспечивает некоторую избыточность данных,
но зато обеспечивает более быструю и прозрачную работу с данными.  
_(Далее будет предложено исследование эффективности возможных запросов,
направленных на полученье данных о платежах)_  
Для того чтобы поддерживать актуальную информацию о сумме остатка в поле pmRest(и поле trAccrual),
введена система функций и триггеров. И добавлены логически целесообразные ограничения на
допустимые изменения данных в полях pmRest и trAccrual *(значение поля pmRest не может быть меньше 0,
значение trAccrual не должно превышать сумму по сделке).*
Система функций и ограничений автоматически вычисляет информацию о нераспределенном остатке по платежу
и общей начисленной сумме по сделке. Это позволяет пользователю не заботиться о дополнительной актуализации
данных при добавлении, изменении, удалении переводов между платежами и сделками.  

#### Структура без дополнительных полей представлена в файле db_structure_without_additional_fields.sql.  

При данной структуре данных информация о нераспределенной сумме остатка в таблице не хранится,
а вычисляется непосредственно при выполнении соответствующего запроса.
Для поддержания логически целесообразных данных в структуре была введена система триггеров, функций
и ограничений. Выражаясь неформально, система вычисляет сумму не распределенного остатка по платежу
(и сумму всех начислений по сделке) при каждой попытке добавить(изменить) перевод между сделкой и платежом.  
 И не позволит выполнить соответствующее действие, если сумма перевода будет превышать сумму не распределенного остатка
(либо сумма перевода при зачислении будет больше суммы необходимой для полной оплаты по сделке).

**Ограничения для обеих структур данных описанные ранее были введены исходя из логических соображений
и являются опциональными.**  

### 2.2) SQL-запросы, которые отображают  всю  информацию по каждому платежу.  

###### Для получения данных предлагается 5 возможных запросов.  

1. Подходит для обеих разработанных структур данных.


        SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest
        FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber;


2. Подходит для обеих разработанных структур данных.  


         SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum) FROM transfers
                                              WHERE pmNumber=trfPayment GROUP BY trfPayment), 0)) AS pmRest
         FROM payments;


3. Подходит для обеих разработанных структур данных.  


        SELECT pmId, pmNumber, pmDate, pmSum, rest.pmRest
        FROM payments JOIN (SELECT pmNumber, sum(pmSum) AS pmRest
                            FROM(
                                SELECT pmNumber, pmSum FROM payments
                                UNION ALL
                                SELECT trfPayment, -trfSum FROM transfers
                            ) as tr GROUP BY pmNumber) as rest
        USING (pmNumber);


4. Подходит для обеих разработанных структур данных.


        SELECT pmid, pmnumber, pmdate, pmsum, (pmSum-(COALESCE(t, 0))) as pmRest
        FROM payments LEFT JOIN
        (SELECT trfpayment, sum(trfSum) as t FROM transfers GROUP BY trfpayment) as tr ON pmnumber=trfpayment;



5. Запрос для базы данных со структурой описанной в файле **db_structure_additional_pmRest_trAccrual.sql**  


        SELECT * FROM payments;

-------------------------------------------------------------------------------------------------------------

###### Результат выполнения запросов(фрагмент):  
  
    Таблица payments
                
     pmid  | pmnumber |           pmdate           |  pmsum  | pmrest  
    -------+----------+----------------------------+---------+---------
      5246 | 5237     | 2017-04-27 14:03:25.754615 |  506.00 |  115.07
       238 | 229      | 2017-04-27 14:03:25.754615 |  456.00 |  456.00
      4195 | 4186     | 2017-04-27 14:03:25.754615 |  668.00 |  297.68
      9525 | 9516     | 2017-04-27 14:03:25.754615 |  288.00 |  139.05
     12451 | 12442    | 2017-04-27 14:03:25.754615 |  987.00 |  142.89
      9187 | 9178     | 2017-04-27 14:03:25.754615 |  237.00 |  183.10
      7431 | 7422     | 2017-04-27 14:03:25.754615 |  724.00 |   41.44
     11907 | 11898    | 2017-04-27 14:03:25.754615 |  661.00 |  228.46
        71 | 62       | 2017-04-27 14:03:25.754615 |  442.00 |   30.51
      9326 | 9317     | 2017-04-27 14:03:25.754615 |  263.00 |  117.78
      4257 | 4248     | 2017-04-27 14:03:25.754615 |  884.00 |  421.13
      4956 | 4947     | 2017-04-27 14:03:25.754615 |  930.00 |  170.96
      7373 | 7364     | 2017-04-27 14:03:25.754615 |  807.00 |  214.77
      7846 | 7837     | 2017-04-27 14:03:25.754615 |  564.00 |  310.815
  
Выполенные операции

     trfid  | trfnumber |          tfrdate           | trfpayment | trftransaction | trfsum 
    --------+-----------+----------------------------+------------+----------------+--------
     105461 | 6141      | 2017-04-27 16:02:20.862305 | 4248       | 8318           |  27.89
     105809 | 14976     | 2017-04-27 16:02:20.862305 | 5237       | 13945          | 390.93
     105846 | 3723      | 2017-04-27 16:02:20.862305 | 4186       | 14118          | 370.32
     105939 | 14239     | 2017-04-27 16:02:20.862305 | 9516       | 8444           | 148.95
     106078 | 14900     | 2017-04-27 16:02:20.862305 | 9178       | 12399          |  53.90
     106314 | 5299      | 2017-04-27 16:02:20.862305 | 62         | 3089           | 411.49
     106605 | 10639     | 2017-04-27 16:02:20.862305 | 7837       | 12655          | 253.19
     107195 | 12557     | 2017-04-27 16:02:20.862305 | 4947       | 5915           | 294.65
     107196 | 10551     | 2017-04-27 16:02:20.862305 | 7422       | 6375           | 170.13
     108108 | 5856      | 2017-04-27 16:02:20.862305 | 11898      | 12112          | 180.68
     108115 | 10602     | 2017-04-27 16:02:20.862305 | 9317       | 7373           |  97.17
     108230 | 8179      | 2017-04-27 16:02:20.862305 | 7364       | 4647           | 279.63
     121205 | 8956      | 2017-04-27 16:03:49.333364 | 7422       | 13400          | 512.43
     150718 | 9245      | 2017-04-27 16:06:03.284679 | 4947       | 11738          | 464.39
     122308 | 7908      | 2017-04-27 16:03:49.333364 | 9317       | 11280          |  48.05
     123494 | 12308     | 2017-04-27 16:03:49.333364 | 4248       | 1073           | 434.98
     125199 | 14259     | 2017-04-27 16:03:49.333364 | 7364       | 6650           | 312.60
     127935 | 2930      | 2017-04-27 16:03:49.333364 | 12442      | 9085           | 680.46
     211315 | 88698     | 2017-04-27 16:10:11.835598 | 11898      | 8624           | 246.02
     147182 | 2633      | 2017-04-27 16:04:08.398347 | 11898      | 14423          |   5.84
     195629 | 10365     | 2017-04-27 16:07:41.381314 | 12442      | 14854          | 163.65



### 2.3) Исследование эффективности запросов.  

Исследование эффективности запросов проводилось на СУБД PostgreSQL 9.5.6.

Количество записей в таблице transfers - 14418.  
Количество записей в таблице payments - 15000.  
Количество записей в таблице transactions - 


Наиболее эффективным является запрос № 5.

Судить об этом можно основываясь на плане запроса, 
генерируемом планировщиком базы данных для заданного оператора.

    EXPLAIN(ANALYZE) SELECT * FROM payments;  

                                                     QUERY PLAN 
    Seq Scan on payments  (cost=0.00..344.00 rows=15000 width=27) (actual time=0.017..20.101 rows=15000 loops=1)  
    Planning time: 0.307 ms  
    Execution time: 38.679 ms  
    (3 rows)


Поскольку запрос № 5 не применим к структуре без дополнительных полей,    
есть необходимость рассмотреть запросы под номерами 4, 3, 2, 1.  

Зарос № 2 является самым неэффективным поскольку для каждой выводимой строки требуется совершать подзапрос,   
искать строку и вычислять значение поля, это требует дополнительного количества   
(равное количеству записей в таблице payments) операций по выборке из таблицы transfers.   
Об этом можно судить основываясь на фрагменте плана запроса:  

        Seq Scan on transfers  (cost=0.00..330.23 rows=2 width=11) (actual time=2.141..3.413 rows=1 loops=15000)
                             Filter: ((payments.pmnumber)::text = (trfpayment)::text)
                             Rows Removed by Filter: 14417

Весь план для запроса № 2:  
        
        EXPLAIN (ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum) FROM transfers
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


Далее представлены планы для запросов № 4, 3 и 1;  

Запрос №4.


        EXPLAIN (ANALYZE) SELECT pmid, pmnumber, pmdate, pmsum, (pmSum-(COALESCE(t, 0))) as pmRest
        FROM payments LEFT JOIN                                                         
        (SELECT trfpayment, sum(trfSum) as t FROM transfers GROUP BY trfpayment) as tr ON pmnumber=trfpayment;
        
        
                                                                QUERY PLAN                                                         
        Hash Right Join  (cost=897.77..1280.66 rows=15000 width=53) (actual time=102.028..166.892 rows=15000 loops=1)
               Hash Cond: ((transfers.trfpayment)::text = (payments.pmnumber)::text)
               ->  HashAggregate  (cost=366.27..485.37 rows=9528 width=11) (actual time=52.640..74.685 rows=9528 loops=1)
                     Group Key: transfers.trfpayment
                     ->  Seq Scan on transfers  (cost=0.00..294.18 rows=14418 width=11) (actual time=0.007..19.590 rows=14418 loops=1)
               ->  Hash  (cost=344.00..344.00 rows=15000 width=21) (actual time=49.241..49.241 rows=15000 loops=1)
                     Buckets: 16384  Batches: 1  Memory Usage: 1014kB
                     ->  Seq Scan on payments  (cost=0.00..344.00 rows=15000 width=21) (actual time=0.024..24.581 rows=15000 loops=1)
         Planning time: 0.277 ms
         Execution time: 187.261 ms
            (10 rows)



Запрос №3.  

      EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, rest.pmRest  
      FROM payments JOIN (SELECT pmNumber, sum(pmSum) AS pmRest  
                        FROM(  
                            SELECT pmNumber, pmSum FROM payments  
                            UNION ALL  
                            SELECT trfPayment, -trfSum FROM transfers  
                        ) as tr GROUP BY pmNumber) as rest  
      USING (pmNumber);  
      
      
                                                     QUERY PLAN  
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


Запрос №1.  

    EXPLAIN(ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-sum(COALESCE(trfSum, 0))) as pmRest  
    FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment GROUP BY pmNumber;  
    
    
                                                     QUERY PLAN 
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

Как видно из плана запроса № 3, для вычисления суммы остатка требуется дополнительный перебор
таблицы _payments_ .

     ->  Seq Scan on payments payments_1  (cost=0.00..344.00 rows=15000 width=9) (actual time=0.010..21.017 rows=15000 loops=1)  

В запросе №1 агрегирование осуществляется по большему количеству строк.

    -> HashAggregate  (cost=1098.93..1323.93 rows=15000 width=27) (actual time=182.229..213.442 rows=15000 loops=1)

Вследствии этого запрос № 4

        SELECT pmid, pmnumber, pmdate, pmsum, (pmSum-(COALESCE(t, 0))) as pmRest
        FROM payments LEFT JOIN                                                         
        (SELECT trfpayment, sum(trfSum) as t FROM transfers GROUP BY trfpayment) as tr ON pmnumber=trfpayment;

**является наиболее эффективным**, что подтверждается фактическим временем выполнения  
(Execution time): 187.261 ms    
по сравнению с дугими запросами 231.393 ms(№1), 311.093 ms (№3), 51750.457 ms (№2).


Вывод
-------------------------------------------------------
Структура базы данных, представленная в фале **db_structure_additional_pmRest_trAccrual.sql**
и предполагающая введение дополнительных полей _pmRest_ и _trAccrual_, является наиболее  
эффективной и прозрачной с точки зрения выполнения запросов на получение данных.
Т.к. при такой структуре есть возможность совершать наиболее эффективный запрос

        SELECT * FROM payments;

Если же по каким-то причинам введение дополнительных полей невозможно, то с точки зрения скорости выполнения  
можно воспользоваться запросом 

        SELECT pmid, pmnumber, pmdate, pmsum, (pmSum-(COALESCE(t, 0))) as pmRest
        FROM payments LEFT JOIN
        (SELECT trfpayment, sum(trfSum) as t FROM transfers GROUP BY trfpayment) as tr ON pmnumber=trfpayment;



Дополнительно
-------------------------------------------------------
### Индексы.

С целью повышения эффективности запросов была предпринята попытка ввести индексы на целевые колонки    
_pmNumber_ и _trfPayment_, по которым происходит сопоставление таблиц.  


        CREATE INDEX pmNumber_payments ON payments (pmNumber);
        CREATE INDEX trfPayment_transfers ON transfers (trfPayment);
        
Тем не менее планировщик, не использовал индексы при выполнении запроса.  


        EXPLAIN (ANALYZE) SELECT pmid, pmnumber, pmdate, pmsum, (pmSum-(COALESCE(t, 0))) as pmRest
        FROM payments LEFT JOIN                                                         
        (SELECT trfpayment, sum(trfSum) as t FROM transfers GROUP BY trfpayment) as tr ON pmnumber=trfpayment;
                                                                
                                                                QUERY PLAN                                                         
         Hash Right Join  (cost=897.77..1280.66 rows=15000 width=53) (actual time=102.028..166.892 rows=15000 loops=1)
           Hash Cond: ((transfers.trfpayment)::text = (payments.pmnumber)::text)
           ->  HashAggregate  (cost=366.27..485.37 rows=9528 width=11) (actual time=52.640..74.685 rows=9528 loops=1)
                 Group Key: transfers.trfpayment
                 ->  Seq Scan on transfers  (cost=0.00..294.18 rows=14418 width=11) (actual time=0.007..19.590 rows=14418 loops=1)
           ->  Hash  (cost=344.00..344.00 rows=15000 width=21) (actual time=49.241..49.241 rows=15000 loops=1)
                 Buckets: 16384  Batches: 1  Memory Usage: 1014kB
                 ->  Seq Scan on payments  (cost=0.00..344.00 rows=15000 width=21) (actual time=0.024..24.581 rows=15000 loops=1)
         Planning time: 0.277 ms
         Execution time: 187.261 ms
        (10 rows)


Однако даже принудительное указание на сканирование по индексу результат не улучшило.  

        SET enable_seqscan TO off;
        
        
        EXPLAIN (ANALYZE) SELECT pmid, pmnumber, pmdate, pmsum, (pmSum-(COALESCE(t, 0))) as pmRest
        FROM payments LEFT JOIN
        (SELECT trfpayment, sum(trfSum) as t FROM transfers GROUP BY trfpayment) as tr ON pmnumber=trfpayment;
                                                                               
                                                                               QUERY PLAN                                                                       
         Merge Right Join  (cost=0.57..2625.13 rows=15000 width=53) (actual time=0.106..202.980 rows=15000 loops=1)
           Merge Cond: ((transfers.trfpayment)::text = (payments.pmnumber)::text)
           ->  GroupAggregate  (cost=0.29..1175.74 rows=9528 width=11) (actual time=0.069..87.488 rows=9528 loops=1)
                 Group Key: transfers.trfpayment
                 ->  Index Scan using trfpayment_transfers on transfers  (cost=0.29..984.55 rows=14418 width=11) (actual time=0.035..41.598 rows=14418 loops=1)
           ->  Index Scan using pmnumber_payments on payments  (cost=0.29..1160.01 rows=15000 width=21) (actual time=0.019..46.662 rows=15000 loops=1)
         Planning time: 0.380 ms
         Execution time: 222.862 ms
        (8 rows)

Аналогичная ситуация наблюдалась и в запросах 1, 3.  

А вот для запроса №2 был в следствии ввода индекса был выбран другой план   
и эффективность существенно выросла.

        EXPLAIN (ANALYZE) SELECT pmId, pmNumber, pmDate, pmSum, (pmSum-COALESCE((SELECT sum(trfSum) FROM transfers
                                              WHERE pmNumber=trfPayment GROUP BY trfPayment), 0)) AS pmRest
        FROM payments;
                                                                  
                                                                  
                                                                  QUERY PLAN                                                                   
         Seq Scan on payments  (cost=10000000000.00..10000175396.70 rows=15000 width=21) (actual time=0.110..373.342 rows=15000 loops=1)
           SubPlan 1
             ->  GroupAggregate  (cost=4.30..11.67 rows=2 width=11) (actual time=0.019..0.020 rows=1 loops=15000)
                   Group Key: transfers.trfpayment
                   ->  Bitmap Heap Scan on transfers  (cost=4.30..11.63 rows=2 width=11) (actual time=0.012..0.013 rows=1 loops=15000)
                         Recheck Cond: ((payments.pmnumber)::text = (trfpayment)::text)
                         Heap Blocks: exact=14379
                         ->  Bitmap Index Scan on trfpayment_transfers  (cost=0.00..4.30 rows=2 width=0) (actual time=0.008..0.008 rows=1 loops=15000)
                               Index Cond: ((payments.pmnumber)::text = (trfpayment)::text)
         Planning time: 0.266 ms
         Execution time: 392.490 ms


Это происходит потому, что для запросов № 1, 3, 4 в обоих случаях требуется просмотреть всю таблицу  
и обращение дополнительно еще и к индексу даже ухудшает результат.   
Для запроса №2 происходит одиночный поиск строки и индекс позволяет осуществить его намного быстрее.