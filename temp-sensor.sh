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


# A simple shell script that measures room temperature using the DS18B20 (waterproof) sensor.
# Moreover, it creates an RRDatabase and stores the measurements taken in it.
#
# You can add this script as a cron job by executing:
# root@raspberrypi:~# crontab -e
#
# and adding the following line:
# @reboot /root/bin/temp-sensor.sh
#
# Make sure to save changes.


create_rrdb () {
rrdtool create ${BASEDIR}/temperature.rrd \
	--start now \
	--step 1 \
	--no-overwrite \
	DS:temp:GAUGE:5:U:U \
	RRA:AVERAGE:0.5:1:32140800 # 12months * 31days * 24hours * 60min * 60sec
}


read_raw_data () {
	# Modify the following command at your discretion.
	RAW_DATA=$(cat /sys/bus/w1/devices/28-04146dd116ff/w1_slave)
}


setup_webpage () {
	if [ -e ${BASEDIR}/index.html ]
	then
		return
	fi

cat > ${BASEDIR}/index.html << __EOF__
<!DOCTYPE html>
<head>
	<title>Graph Report</title>
	<meta charset="UTF-8">
	<style>
	html {
		text-align: center;
		background: radial-gradient(circle, #DCDFEF, #7886C4);
	}

	body {
		width: 910px;
		margin: auto;
	}
	</style>
</head>
<body>
	<h2>Temperature Graph Report</h2><br>
	<img src="./00-temp-1h.png"  alt="00-temp-1h.png">
	<img src="./01-temp-2h.png"  alt="01-temp-2h.png">
	<img src="./02-temp-4h.png"  alt="02-temp-4h.png">
	<img src="./03-temp-12h.png" alt="03-temp-12h.png">
	<img src="./04-temp-24h.png" alt="04-temp-24h.png">
	<img src="./05-temp-1w.png"  alt="05-temp-1w.png">
	<img src="./06-temp-4w.png"  alt="06-temp-4w.png">
	<img src="./07-temp-12w.png" alt="07-temp-12w.png">
</body>
</html>
__EOF__
}


main () {
	BASEDIR="/var/www/temp-sensor" # Modify at your own discretion.

	if [ ! -d ${BASEDIR} ]
	then
		mkdir ${BASEDIR}
	fi

	create_rrdb
	setup_webpage

	modprobe w1-gpio
	modprobe w1-therm

	while true
	do
		read_raw_data
		while [ "${RAW_DATA}/YES" == "${RAW_DATA}" ]
		do
			sleep 0.1
			read_raw_data
		done
		SENSOR_TEMP=$(awk "BEGIN{print ${RAW_DATA##*=}/1000}")
		rrdtool update ${BASEDIR}/temperature.rrd $(date +%s):${SENSOR_TEMP}
		sleep 1
	done
}


# Calling main function.
main

