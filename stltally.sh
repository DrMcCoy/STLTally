#!/bin/bash

# STLTally - A simple STL volume and print time adder
# Copyright (c) 2020 Sven Hesse <drmccoy@drmccoy.de>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

set -euo pipefail

LAYERHEIGHT="0.05" # mm

EXPOSURE="12" # s
LIFT="8" # mm
LIFTSPEED="65" # mm/min
RETRACTSPEED="150" # mm/min

BOTTOMLAYERCOUNT="8" # number of bottom layers
BOTTOMEXPOSURE="70" # s
BOTTOMLIFT="60" # mm
BOTTOMLIFTSPEED="150" # mm/min
BOTTOMRETRACTSPEED="150" # mm/min

roundup() {
	echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.9999999)/(10^$2)" | bc))
};

s_to_dhhmmss() {
	num=$1
	min=0
	hour=0
	day=0
	if ((num>59)); then
		((sec=num%60))
		((num=num/60))
		if ((num>59)); then
			((min=num%60))
			((num=num/60))
			if ((num>23)); then
				((hour=num%24))
				((day=num/24))
			else
				((hour=num))
			fi
			else
				((min=num))
		fi
	else
		((sec=num))
	fi

	printf "%d:%02d:%02d:%02d" $day $hour $min $sec
}

s_to_hhmmss() {
	num=$1
	min=0
	hour=0
	if ((num>59)); then
		((sec=num%60))
		((num=num/60))
		if ((num>59)); then
			((min=num%60))
			((num=num/60))
			((hour=num))
		else
				((min=num))
		fi
	else
		((sec=num))
	fi

	printf "%02d:%02d:%02d" $hour $min $sec
}

collect() {
	TOTALTIME=0
	TOTALVOLUME=0

	while(($# > 0))
	do
		FILE="$1"
		echo "$FILE" >&2

		if [ -f "$FILE" ]; then
			OUTPUT=$(admesh "$FILE" 2>/dev/null)
			VOLUME=$(roundup $(echo $(echo "$OUTPUT" | grep " Volume *: " | sed -e 's/.* Volume *: *//')" / 1000" | bc -l) 0)
			HEIGHT=$(echo "$OUTPUT" | grep " Max Z = " | sed -e 's/.* Max Z = *//')

			LAYERCOUNT=$(roundup $(echo "$HEIGHT/$LAYERHEIGHT" | bc -l) 0)
			TOPLAYERCOUNT=$(echo "$LAYERCOUNT-$BOTTOMLAYERCOUNT" | bc -l)

			TOPTIME=$(echo "$TOPLAYERCOUNT*$LAYERTIME" | bc -l)
			PRINTTIME=$(roundup $(echo "$BOTTOMTIME+$TOPTIME" | bc -l) 0)

			PRINTTIMEHHMMSS=$(s_to_hhmmss "$PRINTTIME")
			echo "$FILE,$VOLUME,$PRINTTIMEHHMMSS"

			TOTALTIME=$(echo "$TOTALTIME+$PRINTTIME" | bc -l)
			TOTALVOLUME=$(echo "$TOTALVOLUME+$VOLUME" | bc -l)
		fi

		shift
	done

	TOTALTIMEDHHMMSS=$(s_to_dhhmmss "$TOTALTIME")
	echo "Total,$TOTALVOLUME,$TOTALTIMEDHHMMSS"
}

LIFTTIME=$(echo "$LIFT/$LIFTSPEED*60" | bc -l)
RETRACTTIME=$(echo "$LIFT/$RETRACTSPEED*60" | bc -l)
OFFTIME=$(echo "$LIFTTIME+$RETRACTTIME" | bc -l)
LAYERTIME=$(echo "$EXPOSURE+$OFFTIME" | bc -l)

BOTTOMLIFTTIME=$(echo "$BOTTOMLIFT/$BOTTOMLIFTSPEED*60" | bc -l)
BOTTOMRETRACTTIME=$(echo "$BOTTOMLIFT/$BOTTOMRETRACTSPEED*60" | bc -l)
BOTTOMOFFTIME=$(echo "$BOTTOMLIFTTIME+$BOTTOMRETRACTTIME" | bc -l)
BOTTOMLAYERTIME=$(echo "$BOTTOMEXPOSURE+$BOTTOMOFFTIME" | bc -l)
BOTTOMTIME=$(echo "$BOTTOMLAYERCOUNT*$BOTTOMLAYERTIME" | bc -l)

TABLE=$(collect "$@" | column -N "File,Volume (ml),Time" -R 2,3 -o " | " -t -s, | sed -e 's/^/| /;s/$/ |/')

TABLEHEAD=$(echo "$TABLE" | head -n1)
TABLETAIL=$(echo "$TABLE" | tail -n1)
TABLECONT=$(echo "$TABLE" | head -n-1 | tail -n+2)

SPACER=$(echo "$TABLEHEAD" | sed -e 's/[^|]/-/g')

echo "$SPACER" | sed -e 's/|/./g'
echo "$TABLEHEAD"
echo "$SPACER"
echo "$TABLECONT"
echo "$SPACER"  | sed -e 's/-/=/g'
echo "$TABLETAIL"
echo "$SPACER" | sed -e 's/|/'\''/g'
