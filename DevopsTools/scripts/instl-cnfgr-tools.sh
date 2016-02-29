#! /usr/bin/env bash
############################################################################
# File name : instl-cnfgr-tools.sh
# Purpose   : Install and configure Hashicorp tools, Ansible, Fabric etc.
# Usages    : ./instl-cnfgr-tools.sh <-i|--instl|-r|--remove|-d|--dump>
#             (make it executable using chmod +x)
# Start date : 11/27/2015
# End date   : 11/xx/2015
# Author : Ankur Kumar
# Download link :
# License :
# Version : 0.0.1
# Modification history :
# Notes :
############################################################################

RM='rm'
LN=$(which ln)
CAT=$(which cat)
TEE=$(which tee)
SED=$(which sed)
ECHO=$(which echo)
GREP=$(which grep)
DATE=$(which date)
WGET=$(which wget)
UNME=$(which uname)
UNZIP=$(which unzip)
BSNME=$(which basename)
MKDIR=$(which mkdir)
SLEEP=$(which sleep)
UNZIP=$(which unzip)
CHMOD=$(which chmod)
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
SDLY=5
SWTCH="$1"
NUMARG=$#
INSTL=false
RMVE=false
DUMP=false
HCTLSLOC='/opt'
HCTLSURL='https://releases.hashicorp.com'
declare -A HCTLSVER
HCTLS="consul \
       nomad \
       otto \
       packer \
       terraform \
       vault"
HCTLSVER[consul]='0.6.3'
HCTLSVER[nomad]='0.3.0'
HCTLSVER[otto]='0.2.3'
HCTLSVER[packer]='0.9.0'
HCTLSVER[terraform]='0.6.12'
HCTLSVER[vault]='0.5.1'

exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-r|--remove|-d|--dump>"
    "$ECHO" "        -i|--install Install DevOps tools,"
    "$ECHO" "        -r|--remove  Configure DevOps tools,"
    "$ECHO" "        -d|--dump    Dump various DevOps tools related info,"
    exit 0

}

parseArgs() {

  if [ $NUMARG -ne 1 ]
  then
    prntUsage
  fi

  if [ "$SWTCH" = "-i" ] || [ "$SWTCH" = "--install" ]
  then
    INSTL=true
  elif [ "$SWTCH" = "-r" ] ||  [ "$SWTCH" = "--remove" ]
  then
    RMVE=true
  elif [ "$SWTCH" = "-d" ] ||  [ "$SWTCH" = "--dump" ]
  then
    DUMP=true
  else
    prntUsage
  fi

}

instlDvopsTls() {

  if "$UNME" -v | "$GREP" -i darwin 2>&1 > /dev/null
  then
    OS='darwin'
    HCTLSLOC='~/Development/Cloud/Works'
  else
    OS='linux'
  fi

  for t in $HCTLS
  do
    if ! "$WGET" -P /tmp --tries=5 -q "$HCTLSURL/$t/${HCTLSVER[$t]}/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip"
    then
      exitOnErr "$WGET -P /tmp $HCTLSURL/$t/${HCTLSVER[$t]}/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip failed"
    else
      if ! "$UNZIP" "/tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip" -d "$HCTLSLOC/${t}_${HCTLSVER[$t]}"
      then
        exitOnErr "$UNZIP /tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip -d $HCTLSLOC/${t}_${HCTLSVER[$t]}"
      else
        if ! "$LN" -s "$HCTLSLOC/${t}_${HCTLSVER[$t]}/$t" "/usr/local/bin/$t"
        then
          exitOnErr "$LN -s $HCTLSLOC/${t}_${HCTLSVER[$t]}/$t /usr/local/bin/$t failed"
        fi
      fi
      "$RM" -fv "/tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip"
    fi
  done

}

rmveDvopsTls() {

  for t in $HCTLS
  do
    "$RM" -rfv "$HCTLSLOC/${t}_${HCTLSVER[$t]}" "$t"
  done

}

dumpDvopsTls() {

  for t in $HCTLS
  do
    ls -lhrt "$HCTLSLOC/${t}_${HCTLSVER[$t]}/"
    ls -lhrt "/usr/local/bin/$t"
    "$t" version
  done

}

main() {

  parseArgs

  if $INSTL
  then
    instlDvopsTls
    dumpDvopsTls
  fi

  if $RMVE
  then
    rmveDvopsTls
    dumpDvopsTls
  fi

  if $DUMP
  then
    dumpDvopsTls
  fi

}

set -u
main 2>&1
