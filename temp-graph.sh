#!/usr/bin/env bash

#+-----------------------------------------------------------------------+
#|              Copyright (C) 2016-2019 George Z. Zachos                 |
#+-----------------------------------------------------------------------+
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Contact Information:
# Name: George Z. Zachos
# Email: gzzachos <at> gmail.com


# Description:
# A simple shell script that creates PNG files containing a graphical 
# representation of the temperature measurements stored in an RRDatabase.
#
# You can add this script as a cron job by executing:
# root@raspberrypi:~# crontab -e
#
# and adding the following line:
# * * * * * /root/bin/temp-graph.sh > /dev/null 2>&1
#
# Make sure to save changes.


# Creates a specific temperature graph.
# (Parameters:	$1 -> Graph index [00-07],
#		$2 -> Time interval {1h, 2h, 4h, 12h, 24h, 1w, 4w, 1y},
#		$3 -> Graph title,
#		$4 -> Additional arguments {--lazy})
generate_rrdgraph () {
	rrdtool graph /var/www/temp-sensor/0${INDEX}-temp-${2}.png \
		--start -${2} \
		--title "${3} Log" \
		--vertical-label "Temperature ºC" \
		--width 600 \
		--height 200 \
		--color GRID#C2C2D6 \
		--color MGRID#E2E2E6 \
		--dynamic-labels \
		--grid-dash 1:1 \
		--font TITLE:10 \
		--font UNIT:9 \
		--font LEGEND:8 \
		--font AXIS:8 \
		--font WATERMARK:8 \
		--lazy \
		--watermark "Raspberry Pi Temperature Monitoring // ${WTM_DATE} // George Z. Zachos" \
		DEF:temp=/var/www/temp-sensor/temperature.rrd:temp:AVERAGE \
		AREA:temp#FF0000AA:"GZ home" \
		LINE2:temp#FF0000
}


# Creates all the graphs
main () {
	INDEX=0
	INTERVALS="1h 2h 4h 12h 24h 1w 4w 12w"
	TITLES=('1 Hour' '2 Hour' '4 Hour' '12 Hour' '24 Hour' '1 Week' '1 Month' '3 Month')
	WTM_DATE=$(date -R)
	for interval in ${INTERVALS}
	do
		generate_rrdgraph "${INDEX}" "${interval}" "${TITLES[$INDEX]}"
		((INDEX += 1))
	done
}


# Calling main function.
main

