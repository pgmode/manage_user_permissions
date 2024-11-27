%global debug_package %{nil}

%{!?pg_version: %global pg_version 15}

%{!?sql_version: %global sql_version 1.0}

Name:           manage_user_permissions
Version:        %{sql_version}
Release:        1.pg%{pg_version}%{?dist}
Summary:        PostgreSQL extension for managing user permissions

License:        GPL
URL:            https://github.com/wasiualhasib/manage_user_permissions
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  postgresql%{pg_version}-devel
Requires:       postgresql%{pg_version}

%description
This package provides the manage_user_permissions extension for PostgreSQL,
which allows for advanced user management capabilities within the database system.

%prep
%setup -c -T
echo "Building for PostgreSQL version: %{pg_version}"
tar -xzvf %{_sourcedir}/%{name}-%{version}.tar.gz -C %{_builddir}
sed -i "s/pgsql-[0-9]*/pgsql-%{pg_version}/" %{_builddir}/%{name}-%{version}/Makefile
sed -i "s/manage_user_permissions--[0-9]\+\.[0-9]\+\.sql/manage_user_permissions--%{sql_version}.sql/" %{_builddir}/%{name}-%{version}/Makefile
sed -i "s/^default_version = '.*'/default_version = '%{sql_version}'/"  %{_builddir}/%{name}-%{version}/manage_user_permissions.control

# Dynamically rename the SQL file inside the extracted directory
old_file_name="manage_user_permissions--[0-9]\+\.[0-9]\+\.sql"
new_file_name="manage_user_permissions--%{sql_version}.sql"

# Find and rename the file
find %{_builddir}/%{name}-%{version}/ -type f -name "manage_user_permissions--*.sql" -exec mv {} %{_builddir}/%{name}-%{version}/$new_file_name \;


%build
# Assuming no compilation is needed, only file preparation or no operation here.
# If the extension needs compiling or additional preparation, add those commands here.
echo "Building extension for PostgreSQL %{pg_version}"

%install
#rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/pgsql-%{pg_version}/share/extension
install -m 644 %{_builddir}/%{name}-%{version}/manage_user_permissions--%{sql_version}.sql %{buildroot}/usr/pgsql-%{pg_version}/share/extension
install -m 644 %{_builddir}/%{name}-%{version}/manage_user_permissions.control %{buildroot}/usr/pgsql-%{pg_version}/share/extension

%files
/usr/pgsql-%{pg_version}/share/extension/manage_user_permissions--%{sql_version}.sql
/usr/pgsql-%{pg_version}/share/extension/manage_user_permissions.control

%changelog
* Fri Nov 22 2024 Your Name Sheikh Wasiu Al Hasib - %{sql_version}-1
- Initial RPM release of manage_user_permissions PostgreSQL extension.

