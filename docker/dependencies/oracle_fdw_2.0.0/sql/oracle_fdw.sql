/*
 * Install the extension and define the tables.
 * All the foreign tables defined refer to the same Oracle table.
 */

SET client_min_messages = WARNING;

CREATE EXTENSION oracle_fdw;

-- TWO_TASK or ORACLE_HOME and ORACLE_SID must be set in the server's environment for this to work
CREATE SERVER oracle FOREIGN DATA WRAPPER oracle_fdw OPTIONS (dbserver '');

CREATE USER MAPPING FOR PUBLIC SERVER oracle OPTIONS (user 'SCOTT', password 'tiger');

-- Oracle table TYPETEST1 must be created for this one
CREATE FOREIGN TABLE typetest1 (
   id  integer OPTIONS (key 'yes') NOT NULL,
   q   double precision,
   c   character(10),
   nc  character(10),
   vc  character varying(10),
   nvc character varying(10),
   lc  text,
   r   bytea,
   u   uuid,
   lb  bytea,
   lr  bytea,
   b   boolean,
   num numeric(7,5),
   fl  float,
   db  double precision,
   d   date,
   ts  timestamp with time zone,
   ids interval,
   iym interval
) SERVER oracle OPTIONS (table 'TYPETEST1');
ALTER FOREIGN TABLE typetest1 DROP q;

-- a table that is missing some fields
CREATE FOREIGN TABLE shorty (
   id  integer OPTIONS (key 'yes') NOT NULL,
   c   character(10)
) SERVER oracle OPTIONS (table 'TYPETEST1');

-- a table that has some extra fields
CREATE FOREIGN TABLE longy (
   id  integer OPTIONS (key 'yes') NOT NULL,
   c   character(10),
   nc  character(10),
   vc  character varying(10),
   nvc character varying(10),
   lc  text,
   r   bytea,
   u   uuid,
   lb  bytea,
   lr  bytea,
   b   boolean,
   num numeric(7,5),
   fl  float,
   db  double precision,
   d   date,
   ts  timestamp with time zone,
   ids interval,
   iym interval,
   x   integer
) SERVER oracle OPTIONS (table 'TYPETEST1');

/*
 * Empty the table and INSERT some samples.
 */

DELETE FROM typetest1;

INSERT INTO typetest1 (id, c, nc, vc, nvc, lc, r, u, lb, lr, b, num, fl, db, d, ts, ids, iym) VALUES (
   1,
   'fixed char',
   'nat''l char',
   'varlena',
   'nat''l var',
   'character large object',
   bytea('\xDEADBEEF'),
   uuid('055e26fa-f1d8-771f-e053-1645990add93'),
   bytea('\xDEADBEEF'),
   bytea('\xDEADBEEF'),
   TRUE,
   3.14159,
   3.14159,
   3.14159,
   '1968-10-20',
   '2009-01-26 15:02:54.893532 PST',
   '1 day 2 hours 30 seconds 1 microsecond',
   '-6 months'
);

INSERT INTO shorty (id, c) VALUES (2, NULL);

INSERT INTO typetest1 (id, c, nc, vc, nvc, lc, r, u, lb, lr, b, num, fl, db, d, ts, ids, iym) VALUES (
   3,
   E'a\u001B\u0007\u000D\u007Fb',
   E'a\u001B\u0007\u000D\u007Fb',
   E'a\u001B\u0007\u000D\u007Fb',
   E'a\u001B\u0007\u000D\u007Fb',
   E'a\u001B\u0007\u000D\u007Fb ABC' || repeat('X', 9000),
   bytea('\xDEADF00D'),
   uuid('055f3b32-a02c-4532-e053-1645990a6db2'),
   bytea('\xDEADF00DDEADF00DDEADF00D'),
   bytea('\xDEADF00DDEADF00DDEADF00D'),
   FALSE,
   -2.71828,
   -2.71828,
   -2.71828,
   '0044-03-15 BC',
   '0044-03-15 12:00:00 BC',
   '-2 days -12 hours -30 minutes',
   '-2 years -6 months'
);

INSERT INTO typetest1 (id, c, nc, vc, nvc, lc, r, u, lb, lr, b, num, fl, db, d, ts, ids, iym) VALUES (
   4,
   'short',
   'short',
   'short',
   'short',
   'short',
   bytea('\xDEADF00D'),
   uuid('0560ee34-2ef9-1137-e053-1645990ac874'),
   bytea('\xDEADF00D'),
   bytea('\xDEADF00D'),
   NULL,
   0,
   0,
   0,
   NULL,
   NULL,
   '23:59:59.999999',
   '3 years'
);

/*
 * Test SELECT, UPDATE ... RETURNING, DELETE and transactions.
 */

-- simple SELECT
SELECT id, c, nc, vc, nvc, length(lc), r, u, length(lb), length(lr), b, num, fl, db, d, ts, ids, iym, x FROM longy ORDER BY id;
-- mass UPDATE
WITH upd (id, c, lb, d, ts) AS
   (UPDATE longy SET c = substr(c, 1, 9) || 'u',
                    lb = lb || bytea('\x00'),
                    lr = lr || bytea('\x00'),
                     d = d + 1,
                    ts = ts + '1 day'
   WHERE id < 3 RETURNING id + 1, c, lb, d, ts)
SELECT * FROM upd ORDER BY id;
-- transactions
BEGIN;
DELETE FROM shorty WHERE id = 2;
SAVEPOINT one;
-- will cause an error
INSERT INTO shorty (id, c) VALUES (1, 'c');
ROLLBACK TO one;
INSERT INTO shorty (id, c) VALUES (2, 'c');
ROLLBACK TO one;
COMMIT;
-- see if the correct data are in the table
SELECT id, c FROM typetest1 ORDER BY id;
-- try to update the nonexistant column (should cause an error)
UPDATE longy SET x = NULL WHERE id = 1;
-- check that UPDATES work with "date" in Oracle and "timestamp" in PostgreSQL
BEGIN;
ALTER FOREIGN TABLE typetest1 ALTER COLUMN d TYPE timestamp(0) without time zone;
UPDATE typetest1 SET d = '1968-10-10 12:00:00' WHERE id = 1 RETURNING d;
ROLLBACK;
-- test if "IN" or "= ANY" expressions are pushed down correctly
SELECT id FROM typetest1 WHERE vc = ANY (ARRAY['short', (SELECT 'varlena'::varchar)]) ORDER BY id;
EXPLAIN (COSTS off) SELECT id FROM typetest1 WHERE vc = ANY (ARRAY['short', (SELECT 'varlena'::varchar)]) ORDER BY id;

/*
 * Test EXPLAIN support.
 */

EXPLAIN (COSTS off) UPDATE typetest1 SET lc = current_timestamp WHERE id < 4 RETURNING id + 1;
EXPLAIN (VERBOSE on, COSTS off) SELECT * FROM shorty;
-- this should fetch all columns from the foreign table
EXPLAIN (COSTS off) SELECT typetest1 FROM typetest1;

/*
 * Test parameters.
 */

PREPARE stmt(integer, date, timestamp) AS SELECT d FROM typetest1 WHERE id = $1 AND d < $2 AND ts < $3;
-- six executions to switch to generic plan
EXECUTE stmt(1, '2011-03-09', '2011-03-09 05:00:00');
EXECUTE stmt(1, '2011-03-09', '2011-03-09 05:00:00');
EXECUTE stmt(1, '2011-03-09', '2011-03-09 05:00:00');
EXECUTE stmt(1, '2011-03-09', '2011-03-09 05:00:00');
EXECUTE stmt(1, '2011-03-09', '2011-03-09 05:00:00');
EXPLAIN (COSTS off) EXECUTE stmt(1, '2011-03-09', '2011-03-09 05:00:00');
EXECUTE stmt(1, '2011-03-09', '2011-03-09 05:00:00');
DEALLOCATE stmt;
-- test NULL parameters
SELECT id FROM typetest1 WHERE vc = (SELECT NULL::text);

/*
 * Test current_timestamp.
 */
SELECT id FROM typetest1
   WHERE d < current_date
     AND ts < now()
     AND ts < current_timestamp
     AND ts < 'now'::timestamp
ORDER BY id;

/*
 * Test foreign table based on SELECT statement.
 */

CREATE FOREIGN TABLE qtest (
   id  integer OPTIONS (key 'yes') NOT NULL,
   vc  character varying(10),
   num numeric(7,5)
) SERVER oracle OPTIONS (table '(SELECT id, vc, num FROM typetest1)');

-- INSERT works with simple "view"
INSERT INTO qtest (id, vc, num) VALUES (5, 'via query', -12.5);

ALTER FOREIGN TABLE qtest OPTIONS (SET table '(SELECT id, SUBSTR(vc, 1, 3), num FROM typetest1)');

-- SELECT and DELETE should also work with derived columns
SELECT * FROM qtest ORDER BY id;
DELETE FROM qtest WHERE id = 5;

/*
 * Test triggers on foreign tables.
 */

-- trigger function
CREATE FUNCTION shorttrig() RETURNS trigger LANGUAGE plpgsql AS
$$BEGIN
   RAISE WARNING 'trigger % % OLD row: id = %, c = %', TG_WHEN, TG_OP, OLD.id, OLD.c;
   RAISE WARNING 'trigger % % NEW row: id = %, c = %', TG_WHEN, TG_OP, NEW.id, NEW.c;
   RETURN NEW;
END;$$;

-- test BEFORE trigger
CREATE TRIGGER shorttrig BEFORE UPDATE ON shorty FOR EACH ROW EXECUTE PROCEDURE shorttrig();
BEGIN;
UPDATE shorty SET id = id + 1 WHERE id = 4;
ROLLBACK;

-- test AFTER trigger
DROP TRIGGER shorttrig ON shorty;
CREATE TRIGGER shorttrig AFTER UPDATE ON shorty FOR EACH ROW EXECUTE PROCEDURE shorttrig();
BEGIN;
UPDATE shorty SET id = id + 1 WHERE id = 4;
ROLLBACK;

/*
 * Test ORDER BY pushdown.
 */

-- don't push down string data types
EXPLAIN (COSTS off) SELECT id FROM typetest1 ORDER BY id, vc;
-- push down complicated expressions
EXPLAIN (COSTS off) SELECT id FROM typetest1 ORDER BY length(vc), CASE WHEN vc IS NULL THEN 0 ELSE 1 END, ts DESC NULLS FIRST FOR UPDATE;
SELECT id FROM typetest1 ORDER BY length(vc), CASE WHEN vc IS NULL THEN 0 ELSE 1 END, ts DESC NULLS FIRST FOR UPDATE;
