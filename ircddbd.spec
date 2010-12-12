#
#
# ircddbd daemon
#
# Copyright (C) 2010   Michael Dirska, DL1BFF (dl1bff@mdx.de)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#



Name: ircddbd
Version: 1.2
Release: 1
License: GPLv2
Group: Networking/Daemons
Summary: ircDDB daemon
URL: http://ircddb.net
Packager: Michael Dirska DL1BFF <dl1bff@mdx.de>
Requires: curl >= 7
Source0: dl1bff-ircddbd-v1.2-0-g4888657.tar.gz
BuildRoot: %{_tmppath}/%{name}-root

%description
The ircDDB daemon downloads the latest JAR files
and starts the ircDDB java program.


%prep
%setup -n dl1bff-ircddbd-4888657


%build
make CFLAGS="$RPM_OPT_FLAGS"


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{_sbindir}
cp ircddbd %{buildroot}/%{_sbindir}/%{name}
mkdir -p %{buildroot}/etc/default
cp etc_default_ircddbd %{buildroot}/etc/default/%{name}
mkdir -p %{buildroot}/var/run/%{name}
mkdir -p %{buildroot}/var/cache/%{name}
mkdir -p %{buildroot}/var/log/%{name}
mkdir -p %{buildroot}/etc/init.d
cp centos_etc_initd_ircddbd %{buildroot}/etc/init.d/%{name}
mkdir -p %{buildroot}/etc/%{name}
cp ircDDB.keystore %{buildroot}/etc/%{name}
cp ircDDB.policy %{buildroot}/etc/%{name}
cp ircDDB.properties %{buildroot}/etc/%{name}
mkdir -p %{buildroot}/etc/logrotate.d
cp logrotate.%{name} %{buildroot}/etc/logrotate.d/%{name}

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root)
%config /etc/default/%{name}
%config /etc/%{name}/ircDDB.properties
/etc/%{name}/ircDDB.policy
/etc/%{name}/ircDDB.keystore
/etc/logrotate.d/%{name}
%attr(755,root,root) %{_sbindir}/%{name}
%attr(755,ircddb,root) %dir /var/run/%{name}
%attr(755,ircddb,root) %dir /var/cache/%{name}
%attr(755,ircddb,root) %dir /var/log/%{name}
%attr(755,root,root) /etc/init.d/%{name}
%doc README COPYING LICENSE


%pre
grep -q "^ircddb:" /etc/passwd || useradd -s /sbin/nologin ircddb

%preun
/sbin/service %{name} stop
/sbin/chkconfig --del %{name}


%post
/sbin/chkconfig --add %{name}



