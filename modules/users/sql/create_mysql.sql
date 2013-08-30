CREATE TABLE blocks_users (
	id			INT NOT NULL AUTO_INCREMENT,
	person_id		INT NOT NULL REFERENCES blocks_people(id),
	username		TEXT,
	password_hash		VARCHAR(41),
	
);

CREATE TABLER blocks_sessions (
	session_key1		VARCHAR(41),
	session_key2		VARCHAR(41),
	created			TIMESTAMP NOT NULL DEFAULT NOW(),	
	user_id			INT NOT NULL REFERENCES blocks_users(id),
	


CREATE TABLE blocks_people (
	id			INT NOT NULL AUTO_INCREMENT,

CREATE TABLE blocks_resource (
	id			INT NOT NULL AUTO_INCREMENT,
	name			TEXT
	
);

CREATE TABLE blocks_roles (
	id			INT NOT NULL AUTO_INCREMENT,
	name			TEXT
	
);

CREATE TABLE blocks_capabilities (
	id			INT NOT NULL AUTO_INCREMENT,
	name			TEXT
);

CREATE TABLE blocks_role_has_capability_on_resource (
	role_id			INT NOT NULL REFERENCES blocks_roles(id),
	capability_id		INT NOT NULL REFERENCES blocks_capabilities(id),
	resource_id		INT NOT NULL REFERENCES blocks_resources(id)
);

DELIMITER $$
CREATE FUNCTION session2user_id(
	session_key1_		VARCHAR(41),
	session_key2_		VARCHAR(41)
)
BEGIN
	DECLARE user_id_ 	INT;
	SET user_id_ = 0;

	SELECT id 
	FROM blocks_sessions s
	WHERE s.session_key1 = session_key1_ AND s.sesion_key2 = session_key2_
	INTO user_id_;

	RETURN user_id_;
END;
$$
DELIMITER ;


