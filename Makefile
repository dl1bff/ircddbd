# 
# 
# ircddbd daemon
# 
# Copyright (C) 2011   Michael Dirska, DL1BFF (dl1bff@mdx.de)
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


all: ircddbd


pidfile.o: libutil.h

flopen.o: libutil.h

ircddbd.o: libutil.h ircddbd_version.h


ircddbd: ircddbd.o pidfile.o flopen.o


ircddbd_version.h:
	touch ircddbd_version.h

clean:
	rm -f *.o

dist-clean: clean
	rm -f ircddbd

rpm:
	rpmbuild -ba ircddbd.spec



