CREATE TABLE transactions(
trId SERIAL,
trNumber CHAR(64) UNIQUE NOT NULL PRIMARY KEY,
trDate TIMESTAMP DEFAULT now(),
trSum NUMERIC(9,2) NOT NULL CHECK(trSum >= 0),
trAccrual NUMERIC(9,2) DEFAULT(0) CHECK(trAccrual >= 0),
CONSTRAINT valid_tr_balance CHECK(trSum-trAccrual >= 0));

CREATE TABLE payments(
pmId SERIAL,
pmNumber CHAR(64) UNIQUE NOT NULL PRIMARY KEY,
pmDate TIMESTAMP DEFAULT now(),
pmSum NUMERIC(9,2) NOT NULL CHECK(pmSum >= 0),
pmRest NUMERIC(9,2) NOT NULL CHECK(pmRest >= 0),
CONSTRAINT valid_pm_balance CHECK(pmSum-pmRest >= 0));

CREATE TABLE transfers(
trfId SERIAL,
trfNumber CHAR(64) UNIQUE NOT NULL PRIMARY KEY,
tfrDate TIMESTAMP DEFAULT now(),
trfPayment CHAR(64) REFERENCES payments,
trfTransaction CHAR(64) REFERENCES transactions,
trfSum NUMERIC(9,2) CHECK(trfSum >= 0));

CREATE FUNCTION set_payment_rest_like_sum() RETURNS trigger AS '
BEGIN
NEW.pmRest=NEW.pmSum;
return NEW;
END;
' LANGUAGE  plpgsql;

CREATE TRIGGER set_rest
BEFORE INSERT ON payments FOR EACH ROW
EXECUTE PROCEDURE set_payment_rest_like_sum();

CREATE OR REPLACE FUNCTION сalculate_balance_with_transfer() RETURNS trigger AS '
BEGIN
UPDATE transactions
        SET trAccrual = trAccrual + NEW.trfSum
        WHERE trNumber = NEW.trfTransaction;
UPDATE payments
        SET pmRest = pmRest - NEW.trfSum
        WHERE pmNumber = NEW.trfPayment;
return NEW;
END;
' LANGUAGE  plpgsql;

CREATE TRIGGER execute_tranfer сalculate_balance_with_transfer
BEFORE INSERT ON transfers FOR EACH ROW
EXECUTE PROCEDURE сalculate_balance_with_transfer();


