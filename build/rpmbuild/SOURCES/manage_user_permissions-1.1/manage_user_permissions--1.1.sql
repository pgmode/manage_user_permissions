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
   IF action = 'help' THEN
        RAISE NOTICE 'Usage of manage_user_permissions:';
        RAISE NOTICE '    user_name: The name of the user for whom permissions are being managed.';
        RAISE NOTICE '    database_name: The name of the database in which the permissions are applied.';
        RAISE NOTICE '    permissions: The type of permissions to grant or revoke. Supported values are:';
        RAISE NOTICE '        - data_loader';
        RAISE NOTICE '        - data_read';
        RAISE NOTICE '        - data_write';
        RAISE NOTICE '        - data_update_only';
        RAISE NOTICE '        - data_monitor';
        RAISE NOTICE '        - user_login';
        RAISE NOTICE '        - connect_schema';
        RAISE NOTICE '        - all';
        RAISE NOTICE '    action: Specify "grant", "revoke", or "help" (this menu).';
        RAISE NOTICE '    schema_name: The schema to apply permissions (default is "public").';
        RETURN;
    END IF;



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

