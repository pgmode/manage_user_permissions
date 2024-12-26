# Manage User Permissions PostgreSQL Extension

The `manage_user_permissions` PostgreSQL extension simplifies the process of creating users, databases, and managing permissions dynamically. This extension provides functions to handle common tasks such as creating databases, granting or revoking permissions, and helping with usage details.

---

## Features

1. **Create Databases and Users Dynamically**  
   - Automatically creates a database and its owner with a secure, randomly generated password.

2. **Grant or Revoke Permissions**  
   - Assign or revoke fine-grained permissions such as data reading, writing, updating, monitoring, schema connection, and more.

3. **Help Functionality**  
   - Provides detailed usage instructions for all supported operations.

---

## Functions

### 1. **Help Function**
   ```sql
   SELECT manage_user_permissions('help');
   ```
   Provides usage details, including supported operations, parameters, and examples.

---

### 2. **Create User and Database**
   ```sql
   SELECT manage_user_permissions('user_name', 'database_name');
   ```
   - Automatically creates a user with a secure random password.
   - Creates the specified database with the user as the owner.
   - Returns the generated password for the created user.

---

### 3. **Grant or Revoke Permissions**
   ```sql
   SELECT manage_user_permissions(
       'user_name',
       'database_name',
       'permissions',
       'action',
       'schema_name'
   );
   ```
   - **Permissions**: `data_loader`, `data_read`, `data_write`, `data_update_only`, `data_monitor`, `user_login`, `connect_schema`, `all`.
   - **Actions**: `grant` or `revoke`.
   - **Schema Name**: Defaults to `public` if not specified.

---

## Installation

### Step 1: Install the RPM Package

1. Download the latest version of the RPM from your repository or local source it also support PostgreSQL 13 or later:
   ```
   manage_user_permissions-1.4-1.pg13.el9.x86_64.rpm
   manage_user_permissions-1.4-1.pg14.el9.x86_64.rpm
   manage_user_permissions-1.4-1.pg15.el9.x86_64.rpm
   manage_user_permissions-1.4-1.pg16.el9.x86_64.rpm
   ```

2. Install the RPM package:
   ```bash
   sudo rpm -ivh manage_user_permissions-1.4-1.pg13.el9.x86_64.rpm
   sudo rpm -ivh manage_user_permissions-1.4-1.pg14.el9.x86_64.rpm
   sudo rpm -ivh manage_user_permissions-1.4-1.pg15.el9.x86_64.rpm
   sudo rpm -ivh manage_user_permissions-1.4-1.pg16.el9.x86_64.rpm
   ```

3. Verify installation:
   ```bash
   rpm -q manage_user_permissions
   ```

---

### Step 2: Enable the Extension

1. Connect to your PostgreSQL instance:
   ```bash
   psql -U postgres
   ```

2. Enable the extension in your database:
   ```sql
   CREATE EXTENSION manage_user_permissions;
   ```

3. Verify the extension is enabled:
   ```sql
   \dx
   ```

---

## Usage Examples

1. **Get Help**:
   ```sql
   SELECT manage_user_permissions('help');
   ```

2. **Create a User and Database**:
   ```sql
   SELECT manage_user_permissions('test_user', 'test_db');
   ```

3. **Grant Data Read Permission**:
   ```sql
   SELECT manage_user_permissions(
       'test_user',
       'test_db',
       'data_read',
       'grant',
       'public'
   );
   ```

4. **Revoke User Login**:
   ```sql
   SELECT manage_user_permissions(
       'test_user',
       'test_db',
       'user_login',
       'revoke',
       'public'
   );
   ```

---

## Notes

- Ensure the `dblink` extension is installed and enabled on your PostgreSQL instance:
   ```sql
   CREATE EXTENSION dblink;
   ```

- Replace `yourpassword` with a secure password for the `postgres` user in the scripts.

- Manage access to the generated user passwords securely.

---

## Contributing

If you encounter issues or have feature requests, feel free to open an issue or contribute to the GitHub repository.
