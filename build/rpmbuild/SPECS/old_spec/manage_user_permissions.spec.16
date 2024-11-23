Name:           manage_user_permissions
Version:        1.1
Release:        1%{?dist}
Summary:        PostgreSQL extension for managing user permissions

License:        GPL
URL:            http://example.com/your_project_homepage
Source0:        %{name}-%{version}.tar.gz
#Source1:        manage_user_permissions--1.0.sql

BuildRequires:  postgresql16-devel
Requires:       postgresql

%description
This package provides the manage_user_permissions extension for PostgreSQL,
which allows for advanced user management capabilities within the database system.


%build
# Assuming no compilation is needed, only file preparation or no operation here.
# If the extension needs compiling or additional preparation, add those commands here.

%prep
%setup -c -T
tar -xzvf %{_sourcedir}/%{name}-%{version}.tar.gz -C %{_builddir}/%{name}-%{version}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/pgsql-16/share/extension
install -m 644 ./%{name}-%{version}/manage_user_permissions--1.1.sql %{buildroot}/usr/pgsql-16/share/extension
install -m 644 ./%{name}-%{version}/manage_user_permissions.control %{buildroot}/usr/pgsql-16/share/extension

%files
/usr/pgsql-16/share/extension/manage_user_permissions--1.1.sql
/usr/pgsql-16/share/extension/manage_user_permissions.control

%changelog
* Wed Nov 22 2024 Your Name Sheikh Wasiu Al Hasib - 1.1-1
- Initial RPM release of manage_user_permissions PostgreSQL extension.

