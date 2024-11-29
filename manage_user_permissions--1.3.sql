CREATE OR REPLACE FUNCTION manage_user_permissions(action TEXT)
RETURNS TEXT AS $$
BEGIN
    IF action = 'help' THEN
        RETURN 'Usage of manage_user_permissions:
    Syntax:
        manage_user_permissions(user_name TEXT, database_name TEXT, permissions TEXT, action TEXT, schema_name TEXT DEFAULT ''public'')
    Parameters:
        user_name: The name of the user for whom permissions are being managed.
        database_name: The name of the database in which the permissions are applied.
        permissions: The type of permissions to grant or revoke. Supported values are:
	    - create_db --This will allow to create database and database owner.
            - data_loader -- This will allow or revoke user to export and import data to and from files.
            - data_read  -- This will allow or revoke  user to read.
            - data_write -- This will allow or revoke user to give write permission.
            - data_update_only -- This will allow or revoke user only update and read permission.
            - data_monitor  -- This will give user to monitor or disallow.
            - user_login  -- This will allow or revoke login.
            - connect_schema -- This will grant or revoke schema connect
            - all -- All permission
        action: Specify ''grant'', ''revoke'', or ''help'' (this menu). -- You can allow or disallow using grant and revoke
        schema_name: The schema to apply permissions (default is ''public''). -- Here default is public , if not you need to mentions it.
    Example:
        SELECT manage_user_permissions(''help'');  -- To get help 
        SELECT manage_user_permissions(''user_name'',''db_name''); -- To create database and owner
        SELECT manage_user_permissions(''test_user'', ''test_db'', ''data_read'', ''grant'', ''public''); -- To give other user permission.
    ';
    ELSE
        RAISE EXCEPTION 'Unsupported action for help function: %. Please use ''help''.', action;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION manage_user_permissions(
    user_name TEXT,
    database_name TEXT
) RETURNS TEXT AS $$
DECLARE
    db_exists BOOLEAN;
    user_exists BOOLEAN;
    random_password TEXT;
    connection_string TEXT;
    server_port TEXT;
BEGIN
    -- Get the current PostgreSQL port dynamically
    SELECT current_setting('port') INTO server_port;

    -- Check if the database exists
    SELECT EXISTS (
        SELECT 1 FROM pg_database WHERE datname = database_name
    ) INTO db_exists;

    IF  db_exists THEN
        RETURN format('Database "%s" already exist. Please check the database first.', database_name);
    END IF;

    -- Check if the user exists
    SELECT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = user_name
    ) INTO user_exists;

    IF user_exists THEN
        RETURN format('User "%s" already exist.', user_name);
    END IF;

    -- Generate a random password
    random_password := substr(md5(random()::text || clock_timestamp()::text), 1, 16);

    -- Define the dblink connection string with the dynamic port
    connection_string := 'dbname=postgres user=postgres password=yourpassword host=localhost port=' || server_port;

    -- Create the user with the random password using dblink
    PERFORM dblink_exec(
        connection_string,
        'CREATE USER ' || quote_ident(user_name) || ' WITH PASSWORD ' || quote_literal(random_password) || ';'
    );

    -- Create the database with the new user as owner using dblink
    PERFORM dblink_exec(
        connection_string,
        'CREATE DATABASE ' || quote_ident(database_name) || ' OWNER ' || quote_ident(user_name) || ';'
    );

    -- Return the generated password for the created user
    RETURN random_password;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION manage_user_permissions(
    user_name TEXT,
    database_name TEXT ,
    permissions TEXT, -- Specify the type of permissions
    action TEXT, -- Mandatory parameter to specify 'grant' or 'revoke'
    schema_name TEXT DEFAULT 'public' -- Schema parameter with default to 'public'
) RETURNS VOID AS $$
DECLARE
    db_exists BOOLEAN;
    user_exists BOOLEAN;
    connection_string TEXT;
    current_port INT;
    db_owner TEXT;
BEGIN


    -- Get the current port from pg_settings
    SELECT current_setting('port')::INT INTO current_port;

    -- Check if the database exists
    SELECT EXISTS (
        SELECT 1 FROM pg_database WHERE datname = database_name
    ) INTO db_exists;

    IF NOT db_exists THEN
        RAISE NOTICE 'Database "%" does not exist. Please create the database first.', database_name;
        RETURN;
    END IF;

    -- Check if the user exists
    SELECT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = user_name
    ) INTO user_exists;

    IF NOT user_exists THEN
        RAISE NOTICE 'User "%" does not exist.', user_name;
        RETURN;
    END IF;

    -- Construct the dynamic connection string for dblink
    connection_string := format('host=localhost port=%s dbname=%s', current_port, database_name);

    SELECT result INTO db_owner FROM dblink( connection_string, 'SELECT pg_catalog.pg_get_userbyid(datdba) FROM pg_catalog.pg_database WHERE datname = current_database()') AS t(result TEXT);


    -- Handle grant or revoke action based on the action parameter
    CASE action
        WHEN 'grant' THEN
            CASE permissions
                WHEN 'data_loader' THEN
                    PERFORM dblink_exec(connection_string, 'GRANT CONNECT ON DATABASE ' || quote_ident(database_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT USAGE ON SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_read_server_files TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_write_server_files TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                WHEN 'data_read' THEN
                    PERFORM dblink_exec(connection_string, 'GRANT CONNECT ON DATABASE ' || quote_ident(database_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT USAGE ON SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_read_all_data TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'ALTER DEFAULT PRIVILEGES FOR ROLE '||  quote_ident(db_owner)  || ' IN SCHEMA ' ||quote_ident(schema_name) ||' GRANT SELECT ON TABLES TO '||quote_ident(user_name) ||';');
                WHEN 'data_write' THEN
                    PERFORM dblink_exec(connection_string, 'GRANT CONNECT ON DATABASE ' || quote_ident(database_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT USAGE ON SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_read_all_data TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_write_all_data TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'ALTER DEFAULT PRIVILEGES FOR ROLE '||  quote_ident(db_owner)  || ' IN SCHEMA ' ||quote_ident(schema_name) ||' GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO '||quote_ident(user_name) ||';');
                WHEN 'data_update_only' THEN
                    PERFORM dblink_exec(connection_string, 'GRANT CONNECT ON DATABASE ' || quote_ident(database_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT USAGE ON SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT SELECT, UPDATE ON ALL TABLES IN SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'ALTER DEFAULT PRIVILEGES FOR ROLE '||  quote_ident(db_owner)  || ' IN SCHEMA ' ||quote_ident(schema_name) ||' GRANT SELECT, UPDATE ON TABLES TO '||quote_ident(user_name) ||';');
                WHEN 'data_monitor' THEN
                    PERFORM dblink_exec(connection_string, 'GRANT CONNECT ON DATABASE ' || quote_ident(database_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT USAGE ON SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_stat_scan_tables TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_read_all_stats TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_read_all_settings TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_monitor TO ' || quote_ident(user_name) || ';');
                WHEN 'user_login' THEN
                    PERFORM dblink_exec(connection_string, 'ALTER USER ' || quote_ident(user_name) || ' WITH LOGIN;');
                WHEN 'connect_schema' THEN
                    PERFORM dblink_exec(connection_string, 'GRANT CONNECT ON DATABASE ' || quote_ident(database_name) || ' TO ' || quote_ident(schema_name) || ';');
                WHEN 'all' THEN
                    -- Revoke schema usage and all privileges
                    PERFORM dblink_exec(connection_string, 'GRANT USAGE ON SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    -- Revoke database connect
                    PERFORM dblink_exec(connection_string, 'GRANT CONNECT ON DATABASE ' || quote_ident(database_name) || ' TO ' || quote_ident(user_name) || ';');
                    -- Revoke all privileges on tables, sequences, and functions
                    PERFORM dblink_exec(connection_string, 'GRANT pg_read_all_data TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT pg_write_all_data TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ' || quote_ident(schema_name) || ' TO ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'ALTER DEFAULT PRIVILEGES FOR ROLE '||  quote_ident(db_owner)  || ' IN SCHEMA ' ||quote_ident(schema_name) ||' GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO '||quote_ident(user_name) ||';');
                ELSE
                    RAISE NOTICE 'Unsupported permissions type: %.', permissions;
            END CASE;

        WHEN 'revoke' THEN
            CASE permissions
                WHEN 'data_loader' THEN
                    PERFORM dblink_exec(connection_string, 'REVOKE USAGE ON SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE pg_read_server_files FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE pg_write_server_files FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE SELECT, INSERT ON ALL TABLES IN SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                WHEN 'data_read' THEN
                    PERFORM dblink_exec(connection_string, 'REVOKE USAGE ON SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE pg_read_all_data FROM ' || quote_ident(user_name) || ';');
                WHEN 'data_write' THEN
                    PERFORM dblink_exec(connection_string, 'REVOKE USAGE ON SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    -- PERFORM dblink_exec(connection_string, 'REVOKE pg_read_all_data FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE pg_write_all_data FROM ' || quote_ident(user_name) || ';');
                WHEN 'data_update_only' THEN
                    PERFORM dblink_exec(connection_string, 'REVOKE USAGE ON SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE pg_read_all_data FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE SELECT, UPDATE ON ALL TABLES IN SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                WHEN 'user_login' THEN
                    PERFORM dblink_exec(connection_string, 'ALTER USER ' || quote_ident(user_name) || ' WITH NOLOGIN;');
                    -- Reassign and drop ownership
                    -- PERFORM dblink_exec(connection_string, 'REASSIGN OWNED BY ' || quote_ident(user_name) || ' TO postgres;');
                    -- PERFORM dblink_exec(connection_string, 'DROP OWNED BY ' || quote_ident(user_name) || ';');
                WHEN 'connect_schema' THEN
                    PERFORM dblink_exec(connection_string, 'REVOKE CONNECT ON DATABASE ' || quote_ident(database_name) || ' FROM ' || quote_ident(user_name) || ';');
                WHEN 'all' THEN
                    -- Revoke schema usage and all privileges
                    PERFORM dblink_exec(connection_string, 'REVOKE USAGE ON SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    -- Revoke database connect
                    PERFORM dblink_exec(connection_string, 'REVOKE CONNECT ON DATABASE ' || quote_ident(database_name) || ' FROM ' || quote_ident(user_name) || ';');
                    -- Revoke all privileges on tables, sequences, and functions
                    PERFORM dblink_exec(connection_string, 'REVOKE pg_read_all_data FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE pg_write_all_data FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ' || quote_ident(schema_name) || ' FROM ' || quote_ident(user_name) || ';');
                    PERFORM dblink_exec(connection_string, 'ALTER DEFAULT PRIVILEGES FOR ROLE '||  quote_ident(db_owner)  || ' IN SCHEMA ' ||quote_ident(schema_name) ||' REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM '||quote_ident(user_name) ||';');

                ELSE
                    RAISE NOTICE 'Unsupported permissions type: %.', permissions;
            END CASE;

        ELSE
            RAISE NOTICE 'Unsupported action: %. Please provide "grant" or "revoke".', action;
            RETURN;
    END CASE;

    RAISE NOTICE 'Action "%" successfully completed for user "%" in schema "%" of database "%".', action, user_name, schema_name, database_name;
END;
$$ LANGUAGE plpgsql;

