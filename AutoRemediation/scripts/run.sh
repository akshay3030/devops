#! /bin/bash

MNTVER='5.25.2'
MNTLOG='/var/log/monit.log'
MNTDIR='/opt/monit'
MNTBDIR="${MNTDIR}/bin"
MNTCDIR="${MNTDIR}/conf"
MNTBNRY='monit'
MNTCNFG='monitrc'
MMNTVER='3.7.2'
MMNTDIR='/opt/mmonit'
MNTECDIR="${MNTDIR}/monit.d"
CNSLCDIR='/etc/consul.d'
CNSLCWARN=${CONSUL_CPU_WARN:-80}
CNSLCCRIT=${CONSUL_CPU_CRIT:-90}
CNSLDWARN=${CONSUL_DISK_WARN:-80}
CNSLDCRIT=${CONSUL_DISK_CRIT:-90}
MNTDCENBL=${MONIT_DISK_CLEANUP:-yes}

exitOnErr() {
  local date=$($DATE)
  echo " Error: <$date> $1, exiting ..."
  exit 1
}

patchMntCnfgs() {

  if [[ "${MMONIT_ENABLED}" = 'true' ]]
  then
    cat << EOF | tee "${MNTECDIR}/mmonit"
  check process mmonit with pidfile "${MMNTDIR}/logs/mmonit.pid"
    start program = "${MMNTDIR}/bin/mmonit"
    stop program = "${MMNTDIR}/bin/mmonit stop"
EOF
  fi

  if [[ ! -z "${MMONIT_ADDR}" ]]
  then
    IP=$(echo "${MMONIT_ADDR}"|awk -F":" '{print $1}')
    PORT=$(echo "${MMONIT_ADDR}"|awk -F":" '{print $2}')

    if [[ -z "${IP}" ]] || [[ -z "${PORT}" ]]
    then
      exitOnErr "empty MMonit IP or PORT (required format <IP>:<PORT>)"
    else
      if ! sed -i -e "/MMONITIP/s/^ *#//" \
                  -e "s/MMONITIP/${IP}/" \
                  -e "s/MMONITPORT/${PORT}/" \
                     "${MNTCDIR}/${MNTCNFG}"
      then
        exitOnErr "MMonit ip/port substitution failed"
      fi
    fi
  fi

  if [[ ! -z "${MAIL_SERVERS}" ]]
  then
    cat << EOF | tee "${MNTECDIR}/mailservers"
    set mailserver ${MAIL_SERVERS}
EOF
  fi

  if [[ ! -z "${ALERTS_RECEPIENT}" ]]
  then
    cat << EOF | tee "${MNTECDIR}/alerts"
    set alert ${ALERTS_RECEPIENT}
EOF
  fi

  if [[ ${CNSLDWARN} -gt ${CNSLDCRIT} ]]
  then
    exitOnErr "Disk warn watermark should not exceed crit watermark"
  else
    if ! sed -i "s/CNSLDCRIT/${CNSLDCRIT}/g" \
              "${MNTECDIR}/spaceinode"
    then
      exitOnErr "Disk warn/crit watermarks substitution for Monit failed"
    fi
  fi

  if [[ "${MNTDCENBL}" != "yes" ]] && \
     [[ "${MNTDCENBL}" != "no" ]]
  then
    exitOnErr "Monit Disk cleanup choice should either be yes or no"
  else
    if [[ "${MNTDCENBL}" = "yes" ]]
    then
      if ! sed -i 's/alert/exec\ "\/usr\/local\/bin\/watches_handler.sh\ critical"/' \
           "${MNTECDIR}/spaceinode"
      then
        exitOnErr "Disk cleanup script substitution for Monit failed"
      fi
    fi
  fi

}

patchCnslCnfgs() {

  if [[ ${MNTDCENBL} = "yes" ]]
  then
    rm -fv "${CNSLCDIR}/watches.json"
  fi

#if [[ ! -z "${CONSUL_CPU_WARN}" ]]
#then
  sed -i "s/CNSLCWARN/${CNSLCWARN}/g" "${CNSLCDIR}/syschecks.json"
#else
#  sed -i "s/CNSLCWARN/80/g" "${CNSLCDIR}/syschecks.json"
#fi

#if [[ ! -z "${CONSUL_CPU_CRIT}" ]]
#then
  sed -i "s/CNSLCCRIT/${CNSLCCRIT}/g" "${CNSLCDIR}/syschecks.json"
#else
#  sed -i "s/CNSLCCRIT/90/g" "${CNSLCDIR}/syschecks.json"
#fi

#if [[ ! -z "${CONSUL_DISK_WARN}" ]]
#then
  sed -i "s/CNSLDWARN/${CNSLDWARN}/g" "${CNSLCDIR}/syschecks.json"
#else
#  sed -i "s/CNSLDWARN/80/g" "${CNSLCDIR}/syschecks.json"
#fi

#if [[ ! -z "${CONSUL_DISK_CRIT}" ]]
#then
  sed -i "s/CNSLDCRIT/${CNSLDCRIT}/g" "${CNSLCDIR}/syschecks.json"
#else
#  sed -i "s/CNSLDCRIT/90/g" "${CNSLCDIR}/syschecks.json"
#fi

}

main() {

  patchMntCnfgs
  patchCnslCnfgs

  pushd "${MNTDIR}"
  "${MNTBDIR}/${MNTBNRY}" -c "${MNTCDIR}/${MNTCNFG}"
  sleep 5
  tail -f "${MNTLOG}"

}

main 2>&1
