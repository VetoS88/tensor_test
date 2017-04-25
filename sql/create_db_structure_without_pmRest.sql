CREATE TABLE transactions(
trId SERIAL,
trNumber VARCHAR(64) UNIQUE NOT NULL PRIMARY KEY,
trDate TIMESTAMP DEFAULT now(),
trSum NUMERIC(9,2) NOT NULL CHECK(trSum >= 0));

CREATE TABLE payments(
pmId SERIAL,
pmNumber VARCHAR(64) UNIQUE NOT NULL PRIMARY KEY,
pmDate TIMESTAMP DEFAULT now(),
pmSum NUMERIC(9,2) NOT NULL CHECK(pmSum >= 0));

CREATE TABLE transfers(
trfId SERIAL,
trfNumber VARCHAR(64) UNIQUE NOT NULL PRIMARY KEY,
tfrDate TIMESTAMP DEFAULT now(),
trfPayment VARCHAR(64) REFERENCES payments,
trfTransaction VARCHAR(64) REFERENCES transactions,
trfSum NUMERIC(9,2) CHECK(trfSum >= 0));


CREATE OR REPLACE FUNCTION check_valid_sum() RETURNS trigger AS $$
DECLARE
pmRest NUMERIC(9,2);
trAccrual NUMERIC(9,2);
BEGIN
SELECT (pmSum-sum(COALESCE(trfSum, 0))) INTO pmRest
FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment
WHERE pmNumber = NEW.trfPayment GROUP BY pmNumber;
IF (pmRest - NEW.trfSum) < 0 THEN
    RAISE INFO 'pmRest after transaction = %  ', (pmRest-NEW.trfSum);
    RAISE EXCEPTION 'not enough rest ';
END IF;
SELECT (trSum-sum(COALESCE(trfSum, 0))) INTO trAccrual
FROM transactions LEFT JOIN transfers  ON trNumber=trfTransaction
WHERE trNumber = NEW.trfTransaction GROUP BY trNumber;
IF (trAccrual - NEW.trfSum) < 0 THEN
    RAISE INFO 'trAccrual after transaction = % ', (trAccrual-NEW.trfSum);
    RAISE EXCEPTION 'оver tranfer sum';
END IF;
RETURN NEW;
END;
$$ LANGUAGE  plpgsql;

CREATE TRIGGER execute_tranfer
BEFORE INSERT ON transfers FOR EACH ROW
EXECUTE PROCEDURE check_valid_sum();

CREATE OR REPLACE FUNCTION check_valid_sum_on_update() RETURNS trigger AS $$
DECLARE
pmRest NUMERIC(9,2);
trAccrual NUMERIC(9,2);
BEGIN
SELECT (pmSum-sum(COALESCE(trfSum, 0))) INTO pmRest
FROM payments LEFT JOIN transfers  ON pmNumber=trfPayment
WHERE pmNumber = NEW.trfPayment GROUP BY pmNumber;
IF (NEW.trfPayment = OLD.trfPayment) THEN
    IF (pmRest + OLD.trfSum - NEW.trfSum) < 0 THEN
        RAISE INFO 'pmRest after transaction = %  ', (pmRest + OLD.trfSum - NEW.trfSum);
        RAISE EXCEPTION 'not enough rest ';
    END IF;
ELSE
    IF (pmRest - NEW.trfSum) < 0 THEN
        RAISE INFO 'pmRest after transaction = %  ', (pmRest-NEW.trfSum);
        RAISE EXCEPTION 'not enough rest ';
    END IF;
END IF;
SELECT (trSum-sum(COALESCE(trfSum, 0))) INTO trAccrual
FROM transactions LEFT JOIN transfers  ON trNumber=trfTransaction
WHERE trNumber = NEW.trfTransaction GROUP BY trNumber;
IF (NEW.trfTransaction = OLD.trfTransaction) THEN
    IF (trAccrual + OLD.trfSum - NEW.trfSum) < 0 THEN
        RAISE INFO 'trAccrual after transaction = % ', (trAccrual + OLD.trfSum -NEW.trfSum);
        RAISE EXCEPTION 'оver tranfer sum';
    END IF;
ELSE
     IF (trAccrual - NEW.trfSum) < 0 THEN
        RAISE INFO 'trAccrual after transaction = % ', (trAccrual-NEW.trfSum);
        RAISE EXCEPTION 'оver tranfer sum';
    END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE  plpgsql;

CREATE TRIGGER update_tranfer
BEFORE UPDATE ON transfers FOR EACH ROW
EXECUTE PROCEDURE check_valid_sum_on_update();