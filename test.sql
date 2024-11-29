CREATE OR REPLACE FUNCTION manage_user_permissions(
    action TEXT,
    user_name TEXT DEFAULT NULL,
    database_name TEXT DEFAULT NULL,
    permissions TEXT DEFAULT NULL,
    schema_name TEXT DEFAULT 'public'
) RETURNS TEXT AS $$
    # Import necessary Python libraries
    import random
    import string

    # Define a helper function to generate a random password
    def generate_random_password(length=16):
        characters = string.ascii_letters + string.digits + string.punctuation
        return ''.join(random.choice(characters) for i in range(length))

    # Action 'help'
    if action == 'help':
        return '''Usage of manage_user_permissions:
    Syntax:
        manage_user_permissions(action, user_name, database_name, permissions, schema_name)
    Parameters:
        action: 'grant', 'revoke', or 'help'.
        user_name: The PostgreSQL user for whom permissions are managed.
        database_name: The name of the database.
        permissions: Supported values:
            - data_loader
            - data_read
            - data_write
            - data_update_only
            - data_monitor
            - user_login
            - connect_schema
            - all
        schema_name: The schema (default: 'public').
    Example:
        SELECT manage_user_permissions('grant', 'test_user', 'test_db', 'data_read', 'public');
        SELECT manage_user_permissions('help');
    '''
    
    # Action validation
    if action not in ['grant', 'revoke']:
        raise Exception(f"Invalid action: {action}. Supported actions are 'grant', 'revoke', and 'help'.")

    # Generate a random password for new users (optional logic for creating users)
    random_password = generate_random_password()

    # Check if the database exists
    result = plpy.execute(f"SELECT 1 FROM pg_database WHERE datname = '{database_name}'")
    if len(result) == 0:
        return f"Database '{database_name}' does not exist. Please create it first."

    # Check if the user exists
    result = plpy.execute(f"SELECT 1 FROM pg_roles WHERE rolname = '{user_name}'")
    if len(result) == 0:
        return f"User '{user_name}' does not exist. Please create it first."

    # Construct and execute SQL commands dynamically
    commands = []
    grant_or_revoke = 'GRANT' if action == 'grant' else 'REVOKE'

    if permissions == 'data_loader':
        commands = [
            f"{grant_or_revoke} CONNECT ON DATABASE {database_name} TO {user_name}",
            f"{grant_or_revoke} USAGE ON SCHEMA {schema_name} TO {user_name}",
            f"{grant_or_revoke} pg_read_server_files TO {user_name}",
            f"{grant_or_revoke} pg_write_server_files TO {user_name}",
            f"{grant_or_revoke} SELECT, INSERT ON ALL TABLES IN SCHEMA {schema_name} TO {user_name}"
        ]
    elif permissions == 'data_read':
        commands = [
            f"{grant_or_revoke} CONNECT ON DATABASE {database_name} TO {user_name}",
            f"{grant_or_revoke} USAGE ON SCHEMA {schema_name} TO {user_name}",
            f"{grant_or_revoke} pg_read_all_data TO {user_name}"
        ]
    elif permissions == 'all':
        commands = [
            f"{grant_or_revoke} CONNECT ON DATABASE {database_name} TO {user_name}",
            f"{grant_or_revoke} USAGE ON SCHEMA {schema_name} TO {user_name}",
            f"{grant_or_revoke} pg_read_all_data TO {user_name}",
            f"{grant_or_revoke} pg_write_all_data TO {user_name}"
        ]
    else:
        return f"Unsupported permissions type: {permissions}"

    # Execute all SQL commands
    for command in commands:
        plpy.execute(command)

    return f"{action.capitalize()} action completed for user '{user_name}' on database '{database_name}' with permissions '{permissions}'."
$$ LANGUAGE plpython3u;

