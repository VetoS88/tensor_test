/*
 Команды для наполнения таблиц данными.
*/

INSERT INTO transactions (trNumber, trSum)
SELECT generate_series, round(random()*1000) FROM generate_series(1,15000);

INSERT INTO payments (pmNumber,pmSum)
SELECT generate_series, round(random()*1000) FROM generate_series(1,15000);

CREATE OR REPLACE FUNCTION make_random_transfers()
RETURNS int AS $$
DECLARE
r record;
transfersCount int;
trfNumber VARCHAR(64);
trfTransaction VARCHAR(64);
trfPayment VARCHAR(64);
trfSum NUMERIC(9,2);
BEGIN
transfersCount := 0;
FOR r IN SELECT * FROM generate_series(1,15000)
LOOP
    trfNumber := round(random()*150000);
    trfTransaction := round(random()*15000);
    trfPayment := round(random()*15000);
    trfSum := round(cast(random()*1000 as numeric), 2);
    BEGIN
        INSERT INTO transfers (trfNumber, trfTransaction, trfPayment, trfSum) VALUES
        (trfNumber, trfTransaction, trfPayment, trfSum);
        EXCEPTION
            WHEN others THEN
                CONTINUE;
    END;
    transfersCount := transfersCount+1;
END LOOP;
RETURN transfersCount;
END;
$$ LANGUAGE  plpgsql;

SELECT make_random_transfers();