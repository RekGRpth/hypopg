-- Creating real and hypothetical tables
-- =====================================
-- Real tables
-- ------------
-- 1. Range partitioning for hypothetical index
DROP TABLE IF EXISTS part_range;
CREATE TABLE part_range (id integer, val text) PARTITION BY RANGE (id);
CREATE TABLE part_range_1_10000 PARTITION OF part_range FOR VALUES FROM (1) TO (10000);
CREATE TABLE part_range_10000_20000 PARTITION OF part_range FOR VALUES FROM (10000) TO (20000);
CREATE TABLE part_range_20000_30000 PARTITION OF part_range FOR VALUES FROM (20000) TO (30000);
INSERT INTO part_range SELECT i, 'line ' || i FROM generate_series(1, 29999) i;

-- Hypothetical tables
-- -------------------
-- 0. Dropping any hypothetical object
SELECT * FROM hypopg_reset_index();
SELECT * FROM hypopg_reset_table();
-- 1. Range partitioning for hypothetical index
DROP TABLE IF EXISTS hypo_part_range;
CREATE TABLE hypo_part_range (id integer, val text);
INSERT INTO hypo_part_range SELECT i, 'line ' || i FROM generate_series(1, 29999) i;
SELECT * FROM hypopg_partition_table('hypo_part_range', 'PARTITION BY RANGE (id)');
SELECT tablename FROM hypopg_add_partition('hypo_part_range_1_10000', 'PARTITION OF hypo_part_range FOR VALUES FROM (1) TO (10000)');
SELECT tablename FROM hypopg_add_partition('hypo_part_range_10000_20000', 'PARTITION OF hypo_part_range FOR VALUES FROM (10000) TO (20000)');
SELECT tablename FROM hypopg_add_partition('hypo_part_range_20000_30000', 'PARTITION OF hypo_part_range FOR VALUES FROM (20000) TO (30000)');

-- Maintenance
-- -----------
VACUUM ANALYZE;
SELECT * FROM hypopg_analyze('hypo_part_range',100);


-- Test hypothetical indexes on hypothetical partitioning behavior
-- ===============================================================

-- Create Indexes
-- --------------
SELECT COUNT(*) AS nb FROM hypopg_create_index('CREATE INDEX ON part_range (id)');
SELECT COUNT(*) AS nb FROM hypopg_create_index('CREATE INDEX ON hypo_part_range(id)');

-- Test on real tables
-- -------------------
SELECT COUNT(*) FROM do_explain ('SELECT * FROM part_range WHERE id = 42') e
WHERE e ~ 'Index.*<\d+>btree.*part_range_1_10000';
SELECT COUNT(*) FROM do_explain ('SELECT * FROM part_range WHERE id > 28000') e
WHERE e ~ 'Index.*<\d+>btree.*part_range_20000_30000';

-- Test on hypothetical tables
-- ---------------------------
SELECT COUNT(*) FROM do_explain ('SELECT * FROM hypo_part_range WHERE id = 42') e
WHERE e ~ 'Index.*<\d+>btree.*hypo_part_range_1_10000';
SELECT COUNT(*) FROM do_explain ('SELECT * FROM hypo_part_range WHERE id > 28000') e
WHERE e ~ 'Index.*<\d+>btree.*hypo_part_range_20000_30000';
