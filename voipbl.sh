URL="http://www.voipbl.org/update/"

# Check if chain exists and create one if required
if [ `/sbin/iptables -L -n | grep -c "Chain voipBL"` -lt 1 ]; then
  echo "Adding voipBL log-drop Chain"
  /sbin/iptables -N voipBL
  /sbin/iptables -A voipBL -m limit --limit 60/minute -j LOG --log-prefix "voipBL: " --log-tcp-options --log-ip-options
  /sbin/iptables -A voipBL -j DROP
fi

if [ `/sbin/iptables -L -n | grep -c "Chain drop-rules-INPUT"` -lt 1 ]; then
  echo "Set up drop-rules-INPUT, jump there from INPUT after RELATED, ESTABLISHED acceptance"
  /sbin/iptables -N drop-rules-INPUT
  /sbin/iptables -I INPUT 1  -m state --state RELATED,ESTABLISHED -j ACCEPT
  /sbin/iptables -I INPUT 2 -p all -j drop-rules-INPUT
fi

rm /tmp/voipbl*.* -f

set -e
echo "Downloading rules from VoIP Blacklist"
wget -qO - $URL -O /tmp/voipbl.txt
date
NUM_IPS=`wc -l /tmp/voipbl.txt | cut -f 1 -d ' '`
NUM_SETS=$(( $NUM_IPS < 35000 ? 1 : ($NUM_IPS < 70000 ? 2 : ($NUM_IPS < 105000 ? 3 : 4)) ))
echo "Done. There are $NUM_IPS lines in the voipbl.txt file, we need $NUM_SETS ipsets to store them! Create ipset voipbl, if not already existing..."
# Check if rule set exists and create one if required
if ! $(/usr/sbin/ipset list voipbl > /dev/null 2>&1) ; then
  time /sbin/ipset -N voipbl iphash
  echo "Created voipbl ipset"
fi
if [ $NUM_SETS -gt 1 ] ; then
  echo "num sets is greater than 1"
  if ! $(/usr/sbin/ipset list voipbl2 > /dev/null 2>&1); then
    time /sbin/ipset -N voipbl2 iphash
    echo "Created voipbl2 ipset"
  fi
fi
echo "Done with voipbl2"
if [ $NUM_SETS -gt 2 ] ; then
  if ! $(/usr/sbin/ipset list voipbl3 > /dev/null 2>&1); then
    time /sbin/ipset -N voipbl3 iphash
    echo "Created voipbl3 ipset"
  fi
fi
echo "Done with voipbl3"
if [ $NUM_SETS -gt 3 ] ; then
  if ! $(/usr/sbin/ipset list voipbl4 > /dev/null 2>&1); then
    time /sbin/ipset -N voipbl4 iphash
    echo "Created voipbl4 ipset"
  fi
fi

echo "Done. create match-set iptables rule, if not already existing..."
 
declare -i MS1=`/sbin/iptables -n -L drop-rules-INPUT | grep -c 'voipbl src'`
declare -i MS3=`/sbin/iptables -n -L drop-rules-INPUT | grep -c 'voipbl3 src'`
declare -i MS4=`/sbin/iptables -n -L drop-rules-INPUT | grep -c 'voipbl4 src'`
declare -i MS2=`/sbin/iptables -n -L drop-rules-INPUT | grep -c 'voipbl2 src'`

#Check if rule in iptables
if [ $MS1 -lt 1 ] ; then
 /sbin/iptables -I drop-rules-INPUT 1 -m set --match-set voipbl src -j voipBL
 echo "Created match-set rule for voipbl"
fi

if [ $NUM_SETS -gt 1 ] ; then
  if [ $MS2 -lt 1 ] ; then
    /sbin/iptables -I drop-rules-INPUT 2 -m set --match-set voipbl2 src -j voipBL
    echo "Created match-set rule for voipbl2"
  fi
fi

if [ $NUM_SETS -gt 2 ] ; then
  if [ $MS3 -lt 1 ] ; then
    /sbin/iptables -I drop-rules-INPUT 3 -m set --match-set voipbl3 src -j voipBL
    echo "Created match-set rule for voipbl3"
  fi
fi

if [ $NUM_SETS -gt 3 ] ; then
  if [ $MS4 -lt 1 ] ; then
    /sbin/iptables -I drop-rules-INPUT 4 -m set --match-set voipbl4 src -j voipBL
    echo "Created match-set rule for voipbl4"
  fi
fi

split --numeric-suffixes --suffix-length=1 --lines=35000   /tmp/voipbl.txt /tmp/voipbl
echo "Split the /tmp/voipbl.txt into 35,000 line chunks"

echo "Loading set 1"
/sbin/ipset destroy voipbl_temp || true
/sbin/ipset -N voipbl_temp iphash || true
tail -n +2 /tmp/voipbl0 | awk '{ print "/usr/sbin/ipset add voipbl_temp \""$1"\""}' | sh
/sbin/ipset swap voipbl_temp voipbl

if [ $NUM_SETS -gt 1 ] ; then
  echo "Loading set 2"
  /sbin/ipset destroy voipbl_temp || true
  /sbin/ipset -N voipbl_temp iphash || true
  cat /tmp/voipbl1 | awk '{ print "/usr/sbin/ipset add voipbl_temp \""$1"\""}' | sh
  /sbin/ipset swap voipbl_temp voipbl2
fi
if [ $NUM_SETS -gt 2 ] ; then
  echo "Loading set 3"
  /sbin/ipset destroy voipbl_temp || true
  /sbin/ipset -N voipbl_temp iphash || true
  cat /tmp/voipbl2 | awk '{ print "/usr/sbin/ipset add voipbl_temp \""$1"\""}' | sh
  /sbin/ipset swap voipbl_temp voipbl3
fi
if [ $NUM_SETS -gt 3 ] ; then
  echo "Loading set 4"
  /sbin/ipset destroy voipbl_temp || true
  /sbin/ipset -N voipbl_temp iphash || true
  cat /tmp/voipbl3 | awk '{ print "/usr/sbin/ipset add voipbl_temp \""$1"\""}' | sh
  /sbin/ipset swap voipbl_temp voipbl4
fi

/sbin/ipset destroy voipbl_temp

echo "Exporting config for restarts"
/sbin/ipset save > /etc/ipset.conf

echo "Done!!!"



