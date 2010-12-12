#!/bin/sh
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


comment_out() {

  RETVAL=0

  echo "  looking for '$2' in file $1"

  if grep -q "^[[:space:]]*$2" "$1"
  then
    echo "  commenting out '$2'"
    echo -e ",s/^[[:space:]]*\\($2\\)/# \\1\nwq" | ed -s "$1"
    RETVAL=1
  else
    echo "  '$2' not found in file $1"
  fi
  
  return $RETVAL
}

transfer_value() {

  RETVAL=0

  if [ $# != 4 ]
  then
    return $RETVAL
  fi

  echo " - $1($2) -> $3($4)"

  if [ ! -f "$1" ]
  then
    echo "   $1 does not exists"
    return $RETVAL
  fi

  if [ ! -f "$3" ]
  then
    echo "   $3 does not exists"
    return $RETVAL
  fi

  if ! grep -q "^[[:space:]]*${2}[[:space:]]*=[[:space:]]*[[:graph:]][[:graph:]]*" "$1"
  then
    echo "   $1 does not contain $2 property"
    return $RETVAL
  fi

  VALUE=` gawk '
   /^[[:space:]]*'"$2"'[[:space:]]*=[[:space:]]*[[:graph:]][[:graph:]]*/ {
     match( $0, "^[[:space:]]*'"$2"'[[:space:]]*=[[:space:]]*([[:graph:]][[:graph:]]*)", a)
     print a[1]
     exit
   } ' < "$1" `

  if [ "x$VALUE" = "x" ]
  then
    echo "   could not read property $2 from file $1"
    return $RETVAL
  fi

  if grep -q "^[[:space:]]*${4}[[:space:]]*=[[:space:]]*[[:graph:]][[:graph:]]*" "$3"
  then
    if grep -q "^[[:space:]]*${4}[[:space:]]*=[[:space:]]*${VALUE}[[:space:]]*$" "$3"
    then
      echo "   $3 already has ${4}=$VALUE"
    else
      echo "   setting ${4}=$VALUE in file $3"

      echo -e ",s/^[[:space:]]*${4}[[:space:]]*=[[:space:]]*[[:graph:]][[:graph:]]*/${4}=$VALUE/\nwq" | ed -s "$3"
      RETVAL=1
    fi
  else
    echo "   adding ${4}=$VALUE to file $3"
    echo "${4}=$VALUE" >> "$3"
  fi

  return $RETVAL
}




echo "*** ircDDB auto config script"

IRCDDBD_CONFIG_CHANGED=0
IRCDDBMHD_CONFIG_CHANGED=0

echo ""
echo "* looking for ircDDB parameters that can be set automatically:"

transfer_value /etc/default/ircddbmhd MHEARD_UDP_PORT /etc/ircddbd/ircDDB.properties mheard_udp_port

if [ "$?" = 1 ]
then
  IRCDDBD_CONFIG_CHANGED=1
fi

transfer_value /opt/products/dstar/dstar_gw/dsipsvd/dsipsvd.conf ZR_CALLSIGN /etc/ircddbd/ircDDB.properties rptr_call

if [ "$?" = 1 ]
then
  IRCDDBD_CONFIG_CHANGED=1
fi

transfer_value /opt/ircDDB/ircDDB.properties irc_password /etc/ircddbd/ircDDB.properties irc_password

if [ "$?" = 1 ]
then
  IRCDDBD_CONFIG_CHANGED=1
fi

transfer_value /opt/products/dstar/dstar_gw/dsgwd/dsgwd.conf ZR_ADDR /etc/default/ircddbmhd ZR_ADDR

if [ "$?" = 1 ]
then
  IRCDDBMHD_CONFIG_CHANGED=1
fi

transfer_value /opt/products/dstar/dstar_gw/dsgwd/dsgwd.conf ZR_PORT /etc/default/ircddbmhd ZR_PORT

if [ "$?" = 1 ]
then
  IRCDDBMHD_CONFIG_CHANGED=1
fi


echo ""
echo "* DStarMonitor config cleanup"

if [ -d /opt/dstarmon ]
then

  D=/opt/dstarmon/dstarmonitor.properties
  if [ -f $D ]
  then
    config_changed=FALSE

    PARAM_SUFFIX=` gawk '
	 /^[[:space:]]*LHURI[0-9]=jdbc:postgresql:.*ircddb/ { gsub("^[[:space:]]*", ""); print substr($0, 6, 1) } ' < $D `

    if [ "x$PARAM_SUFFIX" != "x" ]
    then
	for i in $PARAM_SUFFIX
	do
	  comment_out $D "LHURI${i}="
	  comment_out $D "LHDriver${i}="
	  comment_out $D "LHParameters${i}="
	  config_changed=TRUE
	done
    fi

    if grep -q "^[[:space:]]*LHURI=jdbc:postgresql:.*ircddb" $D
    then
	comment_out $D "LHURI="
	comment_out $D "LHDriver="
	comment_out $D "LHParameters="
	config_changed=TRUE
    fi

    if [ "$config_changed" = "TRUE" ]
    then
	echo "  the configuration file $D was changed, restarting DStarMonitor"
	if [ -x /etc/init.d/dsm ]
	then
	  /etc/init.d/dsm restart
	fi
    else
	echo "  no old ircDDB config lines found"
    fi
  else
    echo "  file $D does not exist"
  fi
else
  echo "  DStarMonitor not found"
fi

echo ""
echo "* dstar_gw startup script cleanup"

D=/etc/init.d/dstar_gw

if [ -f $D ]
then
  config_changed=FALSE

  if grep -q "^[[:space:]]*killall -q -u ircddb" $D
  then
    comment_out $D "killall -q -u ircddb"
    config_changed=TRUE
  fi

  if grep -q "^[[:space:]]*[[:graph:]]*.start.sh 2>.1 > .dev.null" $D
  then
    comment_out $D "[[:graph:]]*.start.sh 2>.1 > .dev.null"
    config_changed=TRUE
  fi

  if [ "$config_changed" = "FALSE" ]
  then
    echo "  no old ircDDB config lines found"
  fi
else
  echo "  dstar_gw startup script could not be found"
fi

echo ""
echo "* ircDDB password"

D=/etc/ircddbd/ircDDB.properties

if [ -f $D ]
then
  if grep -q "irc_password=IRCDDB_PASSWORD" $D
  then
    if [ $# != 1 ]
    then
      echo "#######################################"
      echo "# please run this script again with   #"
      echo "# the ircDDB password as command line #"
      echo "# argument:                           #"
      echo "# /usr/sbin/ircddbconfig pAsSwOrD     #"
      echo "#######################################"
      exit
    else
      TMP=` /bin/mktemp `
      echo "irc_password=$1" > "$TMP"
      transfer_value "$TMP" irc_password $D irc_password
      /bin/rm -f "$TMP"
      IRCDDBD_CONFIG_CHANGED=1
      IRCDDBMHD_CONFIG_CHANGED=1
    fi
  else
    echo "  a password is set in $D"
  fi
else
  echo "  $D not found"
fi

echo ""
echo "* repeater callsign check"

if [ -f $D ]
then
  if grep -q "rptr_call=CALLSIGN" $D
  then
    echo "#######################################"
    echo "# The repeater callsign could not be  #"
    echo "# determined automatically. Please    #"
    echo "# edit /etc/ircddbd/ircDDB.properties #"
    echo "#######################################"
  else
    echo "  a repeater callsign is set in $D"

    if [ "$IRCDDBD_CONFIG_CHANGED" = 1 ]
    then
      echo "  restarting ircddbd service"
      service ircddbd stop
      service ircddbd start
    fi

    if [ "$IRCDDBMHD_CONFIG_CHANGED" = 1 ]
    then
      echo "  restarting ircddbmhd service"
      service ircddbmhd stop
      service ircddbmhd start
    fi
  fi
else
  echo "  $D not found"
fi




