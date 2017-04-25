/*
    Структура данных об оплатах состоит из трех таблиц:
        transactions - таблица сделок. Таблица для хранения сделок требующих оплаты.
        payments - таблица платежей. Таблица для хранения платежей поступивших в систему.
        transfers - таблица переводов.
        Таблица для хранения информации о перечислениях между поступившими платежами
        и сделками.
    Данная структура подразумевает введение дополнительнительных полей:
        Поле trAccrual в таблице transactions хранит всю сумму перечислений
        полученных из разных переводов.
        Поле pmRest в таблице payments хранит информацию о сумме остатка на данном платеже.
    Для регулирования списаниями с поля pmRest и начислениями в поле trAccrual, были введены
    ограничения и триггеры, которые автоматически регулируют суммы в соответствующих полях.
 */

CREATE TABLE transactions(
trId SERIAL,
trNumber VARCHAR(64) UNIQUE NOT NULL PRIMARY KEY,
trDate TIMESTAMP DEFAULT now(),
trSum NUMERIC(9,2) NOT NULL CHECK(trSum >= 0),
trAccrual NUMERIC(9,2) DEFAULT(0) CHECK(trAccrual >= 0),
-- На поле trAccrual(суммы всех начислений) было введено ограничение.
-- Значение в поле не может быть больше значения в поле trSum, требуемого для погашения сделки.
CONSTRAINT valid_tr_balance CHECK(trSum-trAccrual >= 0));

CREATE TABLE payments(
pmId SERIAL,
pmNumber VARCHAR(64) UNIQUE NOT NULL PRIMARY KEY,
pmDate TIMESTAMP DEFAULT now(),
pmSum NUMERIC(9,2) NOT NULL CHECK(pmSum >= 0),
pmRest NUMERIC(9,2) NOT NULL CHECK(pmRest >= 0),
-- На поле pmRest(сумма всех списаний платежа) было введено ограничение.
-- Значение в поля не может быть больше значения в поле trSum, суммы внесенного платежа.
CONSTRAINT valid_pm_balance CHECK(pmSum-pmRest >= 0));

CREATE TABLE transfers(
trfId SERIAL,
trfNumber VARCHAR(64) UNIQUE NOT NULL PRIMARY KEY,
tfrDate TIMESTAMP DEFAULT now(),
trfPayment VARCHAR(64) REFERENCES payments,
trfTransaction VARCHAR(64) REFERENCES transactions,
trfSum NUMERIC(9,2) CHECK(trfSum >= 0));

/*
    Функция для автозаполения суммы остатка по платежу.
    При добавлении нового платежа сумма остатка автоматически устанавливается равной
    сумме внесенного платежа.
*/
CREATE FUNCTION set_payment_rest_like_sum() RETURNS trigger AS '
BEGIN
NEW.pmRest=NEW.pmSum;
return NEW;
END;
' LANGUAGE  plpgsql;

-- Триггер на добавление нового платежа.
CREATE TRIGGER set_rest
BEFORE INSERT ON payments FOR EACH ROW
EXECUTE PROCEDURE set_payment_rest_like_sum();

/*
    Функция для автоматического зачисления оплаты в поле trAccrual и списания с поля pmRest.
    При добавлении нового перевода производятся действия по вычислению суммы остатка (pmRest)
    указанного платежа и суммы начислений(trAccrual) указанной сделки.
*/
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

-- Триггер на добавление нового перевода.
CREATE TRIGGER execute_tranfer
BEFORE INSERT ON transfers FOR EACH ROW
EXECUTE PROCEDURE сalculate_balance_with_transfer();

/*
    Функция для автоматического изменения суммы в поле trAccrual и суммы в поле pmRest.
    При изменении существующего перевода.
*/
CREATE OR REPLACE FUNCTION сalculate_balance_when_modify_transfer() RETURNS trigger AS '
BEGIN
UPDATE transactions
        SET trAccrual = trAccrual - OLD.trfSum
        WHERE trNumber = OLD.trfTransaction;
UPDATE transactions
    SET trAccrual = trAccrual + NEW.trfSum
    WHERE trNumber = NEW.trfTransaction;
UPDATE payments
        SET pmRest = pmRest + OLD.trfSum
        WHERE pmNumber = OLD.trfPayment;
UPDATE payments
        SET pmRest = pmRest - NEW.trfSum
        WHERE pmNumber = NEW.trfPayment;
return NEW;
END;
' LANGUAGE  plpgsql;

-- Триггер на изменение перевода.
CREATE TRIGGER modify_tranfer
BEFORE UPDATE ON transfers FOR EACH ROW
EXECUTE PROCEDURE сalculate_balance_when_modify_transfer();

-- Функция для автоматического изменения сумм при удалении  перевода.
CREATE OR REPLACE FUNCTION сalculate_balance_when_remove_transfer() RETURNS trigger AS '
BEGIN
UPDATE transactions
        SET trAccrual = trAccrual - OLD.trfSum
        WHERE trNumber = OLD.trfTransaction;
UPDATE payments
        SET pmRest = pmRest + OLD.trfSum
        WHERE pmNumber = OLD.trfPayment;
return OLD;
END;
' LANGUAGE  plpgsql;

-- Триггер на удаление перевода.
CREATE TRIGGER remove_tranfer
BEFORE DELETE ON transfers FOR EACH ROW
EXECUTE PROCEDURE сalculate_balance_when_remove_transfer();
