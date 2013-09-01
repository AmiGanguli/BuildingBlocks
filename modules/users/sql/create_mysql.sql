DROP TABLE IF EXISTS blocks_people CASCADE;
CREATE TABLE blocks_people (
	id			INT NOT NULL AUTO_INCREMENT,
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	firstname		TEXT,
	lastname		TEXT,
	PRIMARY KEY (id, domain_id),
	KEY (domain_id, lastname(16))
);

DROP TABLE IF EXISTS blocks_resources CASCADE;
CREATE TABLE blocks_resources (
	id			INT NOT NULL AUTO_INCREMENT,
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	name			TEXT,
	PRIMARY KEY (id, domain_id),
	KEY (domain_id, name(16))
);

DROP TABLE IF EXISTS blocks_roles CASCADE;
CREATE TABLE blocks_roles (
	id			INT NOT NULL AUTO_INCREMENT,
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	name			TEXT,
	PRIMARY KEY (id, domain_id),
	KEY (domain_id, name(16))
);

DROP TABLE IF EXISTS blocks_users CASCADE;
CREATE TABLE blocks_users (
	id			INT NOT NULL AUTO_INCREMENT,
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	person_id		INT NOT NULL,
	username		TEXT,
	password_hash		VARCHAR(41),
	created			TIMESTAMP NOT NULL DEFAULT NOW(),	
	active			BOOL,
	password_failures	INT,
	PRIMARY KEY (id, domain_id),
	KEY (domain_id, username(16)),
	KEY (domain_id, person_id),
	FOREIGN KEY (person_id, domain_id) REFERENCES blocks_people(id, domain_id)
	
);

DROP TABLE IF EXISTS blocks_sessions CASCADE;
CREATE TABLE blocks_sessions (
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	session_key1		VARCHAR(41),
	session_key2		VARCHAR(41),
	created			TIMESTAMP NOT NULL DEFAULT NOW(),	
	user_id			INT NOT NULL,
	expires_at		TIMESTAMP,
	KEY (domain_id, session_key1),
	KEY (domain_id, created),
	FOREIGN KEY (user_id, domain_id) REFERENCES blocks_users(id, domain_id)
);

DROP TABLE IF EXISTS blocks_role_has_capability_on_resource CASCADE;
CREATE TABLE blocks_role_has_capability_on_resource (
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	role_id			INT NOT NULL,
	capability_id		INT NOT NULL,
	resource_id		INT NOT NULL,
	KEY (role_id),
	KEY (capability_id),
	KEY (resource_id),
	FOREIGN KEY (role_id, domain_id) REFERENCES blocks_roles(id, domain_id),
	FOREIGN KEY (capability_id, domain_id) REFERENCES blocks_capabilities(id, domain_id),
	FOREIGN KEY (resource_id, domain_id) REFERENCES blocks_resources(id, domain_id)
);

DROP TABLE IF EXISTS blocks_user_has_role CASCADE;
CREATE TABLE blocks_user_has_role (
	domain_id		INT NOT NULL REFERENCES blocks_domains(id),
	role_id			INT NOT NULL,
	user_id			INT NOT NULL,
	KEY (role_id),
	KEY (user_id),
	FOREIGN KEY (role_id, domain_id) REFERENCES blocks_roles(id, domain_id),
	FOREIGN KEY (user_id, domain_id) REFERENCES blocks_users(id, domain_id)
);

INSERT INTO blocks_installed_tables 
	(name, 						module_name, 	is_public) 
VALUES 
	('blocks_people', 				'users', 	TRUE),
	('blocks_resources', 				'users', 	TRUE),
	('blocks_roles', 				'users', 	TRUE),
	('blocks_users', 				'users', 	FALSE),
	('blocks_sessions', 				'users', 	FALSE),
	('blocks_role_has_capability_on_resource', 	'users', 	TRUE),
	('blocks_role_has_user', 			'users', 	TRUE)
	;

DELIMITER $$

DROP FUNCTION IF EXISTS blocks_session2user$$
CREATE FUNCTION blocks_session2user(
	domain_id_		INT,
	session_key1_		VARCHAR(41),
	session_key2_		VARCHAR(41)
) RETURNS INT
BEGIN
	DECLARE user_id_ 	INT DEFAULT 0;

	SELECT s.id 
	FROM blocks_sessions s
	WHERE 
		s.session_key1 = session_key1_ 
		AND s.session_key2 = session_key2_
	INTO user_id_;

	RETURN user_id_;
END;
$$

-- Status codes:
--	1	0k
--	3	Username exists
--
DROP PROCEDURE IF EXISTS blocks_create_user$$
CREATE PROCEDURE blocks_create_user(
	IN domain_id_		INT,
	IN firstname_		TEXT,
	IN lastname_		TEXT,
	IN username_		TEXT,
	IN password_		TEXT,
	OUT user_id_		INT,
	OUT status_		INT
)
BEGIN
		
END;
$$

	
DROP PROCEDURE IF EXISTS blocks_login;
CREATE PROCEDURE blocks_login(
	IN username_ 		TEXT,
	IN password_ 		TEXT,
	IN expires_at_		TIMESTAMP,
	OUT session_key1_ 	TEXT,
	OUT session_key2_ 	TEXT,
	OUT firstname_		TEXT,
	OUT lastname_		TEXT,
	OUT status_ 		INT
)
SQL SECURITY DEFINER
BEGIN
	DECLARE	user_id_	BIGINT;

	SELECT p.firstname, p.lastname, p.user_id
	FROM blocks_people p, blocks_users u
	WHERE 
		    u.username = username_
		AND u.password_hash = PASSWORD( CONCAT( password_, u.id, u.created) )
--		AND u.
		AND u.person_id = p.id
	INTO firstname_, lastname_, user_id_;

	
	
END;
$$

DELIMITER ;

