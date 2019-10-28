#  radar.sh
#  
#  Copyright 2016 Pedro Pavan <pedro.pavan@linuxmail.org>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  
#!/usr/bin/env bash
#===============================================================
# Changes history:
#
#  Date     |    By       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      02-08-2016    Initial release
# Pedro	      04-16-2016    New Parser
#===============================================================

#http://www.gps-coordinates.net/

WWWDUMP="lynx -dump -nolist -width=300 -accept_all_cookies -display_charset=UTF-8"
WWWRADAR="http://www.saocarlosoficial.com.br/_fonte/transitoradar.asp"
WWWDATA="$(mktemp radar.tmp.XXXXXXXXXX)"
WWWFILTER="$(date --date='tomorrow' +'%d/%m')"

SQL_TODAY="$(date +'%D %T')"
SQL_FILE="radar_daily.sql"

TODAY="$(date +%a)"
#WWWDATA="radar.data"

if [ $(echo ${TODAY} | egrep -c 'Fri|Sat') -eq 1 ]; then
        WWWFILTER="Segunda-Feira"
fi

${WWWDUMP} ${WWWRADAR} | sed 's/^[ \t]*//' | egrep -A4 ${WWWFILTER} | egrep '^Radar' > ${WWWDATA}
echo -e "\n-- ${SQL_TODAY}" >> ${SQL_FILE}

if [ ! -s ${WWWDATA} ]; then
	echo "> Radar working for ${WWWFILTER}: 0"
else
	echo "> Radar working for ${WWWFILTER}: $(egrep -c '^Radar' ${WWWDATA})"
fi

while read line; do    
	STREET=$(echo $line | cut -d '-' -f 2 | cut -d '(' -f 1 | sed 's/^[ \t]*//' | sed 's/ *$//')
	DIRECTION=$(echo $line | cut -d '(' -f 2 | cut -d ')' -f 1)
	SPEEDY=$(echo $line | awk -F ' ' '{ print $(NF-1) }')
	
	echo "insert into table values ('${STREET}', '${DIRECTION}', ${SPEEDY});" >> ${SQL_FILE}
done < ${WWWDATA}

#mv ${WWWDATA} radar.data
rm ${WWWDATA}
