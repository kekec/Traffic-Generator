#!/bin/sh

#Copyright 2011 Paul Wiegele
#
#This file is part of Traffic Generator
#
#Traffic Generator is free software: you can redistribute it and/or modify 
#it under the terms of the GNU General Public License as published by the 
#Free Software Foundation, either version 3 of the License, or 
#(at your option) any later version.
#
#Traffic Generator is distributed in the hope that it will be useful, but 
#WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
#or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License along with Foobar. If not, see http://www.gnu.org/licenses/.

# The jarfile AXMLPrinter2.jar is o convert the binary manifestfile to ascii
axml="../AXMLPrinter2.jar"
tf="tmp/anma.xml"
activity="tmp/activity.txt"

#########################################################################
# Warning make sure PATH variable includes the android 'platform-tools' #
# and the 'tools' directory                                             #
#########################################################################

#########################################################################
# A new virtual device for the emulator can be generated using          #
# 'android create avd -n <name> -t 1' (where <name> is the name of the  #
# image you like to create.                                             #
# In order to create a new virtual device you have to install at least  #
# Andriod SDK Platform Andriod 1.5 or higher.                           #
#########################################################################

#check of there is exactly one argument
if [ $# -ne 1 ]
then
    echo "Usage - $0  [dir] (replace dir with the folder containing apps)"
    exit 1
fi

#make sure that the given argument is an existing folder
if [ ! -d $1 ]
then
    echo "Sorry, $1 folder does not exist"
    exit 1
fi

#check if AXMLPrinter2.jar file exists
if [ ! -f AXMLPrinter2.jar ]
then
    echo "AXMLPrinter2.jar not found!"
    exit 1
fi

cd $1

#TODO: check here if at least one apps was found here
#sth like ls *.apk | wc -l

#TODO: check if there are any whitespace in the filenames of the apk's

#if there is an existing tmp filder delete it
if [ -d "tmp" ]
then 
    echo "there is a folder tmp that i will delete"
    rm -rf tmp
fi

mkdir tmp

#loop over all files *apk within this dir
for f in *.apk
do
    unzip -o $f -d tmp/ > /dev/null #unpack current file to tmp folder
    java -jar $axml tmp/AndroidManifest.xml > $tf #convert from binary to ascii encoding
    chmod 755 $tf
    package_name=$(cat $tf | grep package | awk 'BEGIN { FS="\""};{print $2}') #get string within apostrophys
    echo "pkg name is: $package_name"
    emulator -tcpdump $f.cap -avd test& #here I assume that the emulator profile test exists
    sleep 35 # wait for the emulator to boot
    echo "going to install the app"
    adb install $f
    #parse the anma.xml file and extract the attribute andriod:name field of the first activity
    xpath -e "//manifest/application/activity[1]/@android:name" $tf | awk 'BEGIN {FS="\""};{print $2}' > $activity
    chmod 755 $activity
    activity_class=$(cat $activity)
    echo "activity class is $activity_class"
    adb shell am start -a android.intent.action.MAIN -n $package_name/$activity_class
    sleep 10 #sleep for 10 sec
    adb shell rm data/app/$package_name.apk
    kill $(ps -A | grep emulator | awk '{print $1}') # kill the emulator
    rm -rf tmp/*
    break
done

#move the generate pcap files
cd ..
if [ ! -d "pcap_dumps" ]
then 
    mkdir pcap_dumps
fi
mv $1/*.cap pcap_dumps
