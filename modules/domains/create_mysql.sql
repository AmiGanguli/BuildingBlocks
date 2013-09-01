-- Domains are used to support multi-tenant databases.
--
-- You can ignore the existance of domains by providing -1
-- everywhere where a domain id is required.  This will
-- use the root domain for everything.
--
DROP TABLE IF EXISTS blocks_domains;
CREATE TABLE blocks_domains (
	id			INT NOT NULL AUTO_INCREMENT,
	name			TEXT,
	PRIMARY KEY (id),
	KEY (name(16))
);

-- Our first domain is always the root domain.
--
INSERT INTO blocks_domains (id, name)
VALUES (-1, "root");

-- A list of installed tables is needed for the cloning 
-- procedure.  We'll find the tables we want to clone here.
-- Modules that add more tables which should be cloned, can
-- register those tables by inserting records here.
--
DROP TABLE IF EXISTS blocks_installed_tables;
CREATE TABLE blocks_installed_tables (
	id			INT NOT NULL AUTO_INCREMENT,
	name			TEXT,
	module_name		TEXT,
	is_public		BOOL NOT NULL,
	PRIMARY KEY (id),
	KEY (module_name(16))
);

-- Capabilities define what a role is allowed to do with a 
-- resource.
--
DROP TABLE IF EXISTS blocks_capabilities;
CREATE TABLE blocks_capabilities (
	id			INT NOT NULL AUTO_INCREMENT,
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	name			TEXT,
	PRIMARY KEY (id, domain_id),
	KEY (domain_id, name(16))
);

-- Register the capabilities table.
--
INSERT INTO blocks_installed_tables (name, module_name, is_public) 
VALUES ('blocks_capabilities', 'capabilities', TRUE);

-- Create standard capabilities that should always be present.
--
INSERT INTO blocks_capabilities (domain_id, name)
VALUES (-1, 'admin'), (-1, 'create'), (-1, 'read'), (-1, 'update'), (-1, 'delete');


DELIMITER $$

-- Clone the records for a given domain within a specific table.
--
DROP PROCEDURE IF EXISTS blocks_table_clone;
CREATE PROCEDURE blocks_table_clone(
	IN old_domain_id_	INT,
	IN new_domain_id_	INT,
	IN table_name_		TEXT
)
BEGIN
	-- Extract the records from the old_domain/table into a temporary table.
	--
	DROP TEMPORARY TABLE IF EXISTS clone_temp;
	SET @statement_ = CONCAT('CREATE TEMPORARY TABLE clone_temp SELECT * FROM ', table_name_, ' WHERE domain_id=', old_domain_id_);
	PREPARE extract_statement FROM @statement_;
	EXECUTE extract_statement;
	DEALLOCATE PREPARE extract_statement;

	-- Change the domain_id.
	--
	UPDATE clone_temp SET domain_id = new_domain_id_;

	-- Load the modified records back into the original table.
	--
	SET @statement_ = CONCAT('INSERT INTO ', table_name_, ' SELECT * FROM clone_temp');
	PREPARE load_statement FROM @statement_;
	EXECUTE load_statement;
	DEALLOCATE PREPARE load_statement;

	DROP TEMPORARY TABLE clone_temp;
END;
$$

DROP PROCEDURE IF EXISTS blocks_domain_clone;
CREATE PROCEDURE blocks_domain_clone(
	IN template_id_		INT,
	IN name_ 		TEXT,
	OUT id_			INT,
	OUT status_ 		INT
)
SQL SECURITY DEFINER
BEGIN
	DECLARE table_name_	TEXT;
	DECLARE done_ 		INT;
	DECLARE select_tables_	CURSOR FOR SELECT name FROM blocks_installed_tables;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_ = TRUE;

	START TRANSACTION;
		SELECT id
		FROM blocks_domains
		WHERE name = name_
		INTO id_;

		IF id_ IS NULL THEN
			INSERT INTO blocks_domains (name)
			VALUES (name_);
			SET id_ := LAST_INSERT_ID();
			SET status_ := 1;
			SET done_ := FALSE;

			OPEN select_tables_;
			clone_loop: LOOP
				FETCH select_tables_ INTO table_name_;
				IF done_ THEN
					CLOSE select_tables_;
					LEAVE clone_loop;
				END IF;
				CALL blocks_table_clone(template_id_, id_, table_name_);
			END LOOP;
		ELSE
			SET status_ := 2;
		END IF;

	COMMIT;
END;
$$

DROP PROCEDURE IF EXISTS blocks_create_db_user;
CREATE PROCEDURE blocks_create_db_user(
	IN name_ 		TEXT,
	IN host_		TEXT,
	IN password_		TEXT
)
SQL SECURITY DEFINER
BEGIN
	DECLARE table_name_	TEXT;
	DECLARE is_public_	BOOL;
	DECLARE done_ 		INT;
	DECLARE select_tables_	CURSOR FOR SELECT name, is_public FROM blocks_installed_tables;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_ = TRUE;

	OPEN select_tables_;
	grant_loop: LOOP
		FETCH select_tables_ INTO table_name_, is_public_;
		IF done_ THEN
			CLOSE select_tables_;
			LEAVE grant_loop;
		END IF;
		IF is_public_ THEN
			SET @statement_ := CONCAT(
				'GRANT INSERT, SELECT, UPDATE, DELETE ON ', 
				DATABASE(), '.', table_name_, 
				' TO ', QUOTE(name_), '@', QUOTE(host_), ' IDENTIFIED BY ', QUOTE(password_)
			);
			PREPARE load_statement FROM @statement_;
			EXECUTE load_statement;
			DEALLOCATE PREPARE load_statement;
		END IF;
	END LOOP;
	FLUSH PRIVILEGES;
END;
$$

DELIMITER ;

