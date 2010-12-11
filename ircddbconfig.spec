#
#
# ircDDB auto config script
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



Name: ircddbconfig
Version: 1.0
Release: 2
License: GPLv2
Group: Applications/System
Summary: ircDDB auto config script
URL: http://ircddb.net
Packager: Michael Dirska DL1BFF <dl1bff@mdx.de>
Requires: ed >= 0.2, gawk >= 3
Source0: ircddbconfig.sh
BuildRoot: %{_tmppath}/%{name}-root
BuildArch: noarch

%description
This script tries to remove old versions of ircDDB from the computer and
configures the various parts of a DSTAR repeater automatically.


%build
cp %{SOURCE0} %{name}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{_sbindir}
cp %{name} %{buildroot}/%{_sbindir}/%{name}

%clean
rm -rf %{buildroot}


%files
%attr(755,root,root) %{_sbindir}/%{name}


%post
echo ""
echo "##############################################################################"
echo "# Start the automatic configuration with this command: %{_sbindir}/%{name}"
echo "##############################################################################"

