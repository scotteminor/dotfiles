#!/bin/bash

echo " Setting Command History ..."

echo " Setting history timeformat .."
grep -q "HISTTIMEFORMAT=" /etc/profile || echo "export HISTTIMEFORMATION=\"%y.%m.%d %T  - \""

echo " Setting history Size .."
grep "HISTSIZE" /etc/profile

https://github.com/rediculum/RHEL8_Lockdown/blob/master/rhel8.sh
