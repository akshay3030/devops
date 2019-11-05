#! /bin/bash
set -uo pipefail

DEBUG="${DEBUG_FLAG:-0}"
DCKRFL="${DOCKER_FILE:-Dockerfile}"
DCKRIMG="${DOCKER_IMAGE:-none}"
CSTCNFG='config.yaml'
LBLVNDRK="${LABEL_VENDORK:-com.richnusgeeks.vendor}"
LBLVNDRV="${LABEL_VENDORV:-richnusgeeks}"
LBLCTGRK="${LABEL_CATEGORYK:-com.richnusgeeks.category}"
LBLCTGRV="${LABEL_CATEGORYV:-none}"
SCHMVER='2.0.0'
RQRDCMNDS="awk
           cat
           container-structure-test
           date
           docker
           echo
           grep
           sed
           tee
           xargs"

exitOnErr() {

  echo " <$(date)> Error: ${1}, exiting ..."
  exit 1

}

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      exitOnErr "required command ${c} not found, exiting ..."
    fi
  done

  if [[ ${DEBUG} -ne 0 ]] && [[ ${DEBUG} -ne 1 ]]
  then
    exitOnErr 'DEBUG_FLAG should be either 0 or 1'
  fi

  if [[ ! -f "${DCKRFL}" ]]
  then
    exitOnErr "required ${DCKRFL} not found"
  fi

}

crteCstCnfg() {

  local cmd=$(grep CMD "${DCKRFL}"|grep -v '^ *#'|sed 's/^ *CMD *//')
  if ! echo ${cmd} | grep '[][]' > /dev/null 2>&1
  then
    if [[ ! -z "${cmd}" ]]
    then
      cmd=\[\'${cmd}\'\]
    else
      cmd=\[\'/dev/null\'\]
    fi
  else
    cmd=${cmd}
  fi

  local wrkdir=$(grep WORKDIR "${DCKRFL}"|grep -v '^ *#'|tail -1|sed 's/^ *WORKDIR *//')
  if [[ -z "${wrkdir}" ]]
  then
    wrkdir='/dev/null'
  fi

  local expsdprts=$(grep EXPOSE "${DCKRFL}"|grep -v '^ *#'|sed 's/^ *EXPOSE *//g'|xargs|sed -e 's/ \{1,\}/,/g' -e 's/,/","/g' -e 's/^ */["/' -e 's/$/"]/')
  if [[ "${expsdprts}" = '[""]' ]]
  then
    expsdprts='["-1"]'
  fi
  
  local entrypoint=$(grep ENTRYPOINT "${DCKRFL}"|grep -v '^ *#'|sed 's/^ *ENTRYPOINT *//')
  if [[ -z "${entrypoint}" ]]
  then
    entrypoint='["/sbin/tini","--"]'
  fi

  local category=$(grep "${LBLCTGRK}" "${DCKRFL}"|awk -F"=" '{print $NF}'|sed -e 's/"//g' -e "s/'//")
  if [[ ! -z "${category}" ]]
  then
    if [[ "${category}" = 'base' ]] || [[ "${category}" = 'utility' ]] || [[ "${category}" = 'service' ]]
    then
      LBLCTGRV="${category}"
    fi
  fi

  if [[ ${DEBUG} -eq 0 ]]
  then
  cat <<EOF > "/tmp/${CSTCNFG}"
schemaVersion: ${SCHMVER}

commandTests:
  - name: "dump tini version"
    command: "/sbin/tini"
    args: ["--version"]

fileExistenceTests:
  - name: "tini existence"
    path: "/sbin/tini"
    shouldExist: true

metadataTest:
  labels:
    - key: '${LBLVNDRK}'
      value: '${LBLVNDRV}'
    - key: '${LBLCTGRK}'
      value: '${LBLCTGRV}'

  cmd: ${cmd}
  exposedPorts: ${expsdprts}
  entrypoint: ${entrypoint}
  workdir: ${wrkdir}
EOF

  elif [[ ${DEBUG} -eq 1 ]]
  then
  cat <<EOF | tee "/tmp/${CSTCNFG}"
schemaVersion: ${SCHMVER}

commandTests:
  - name: "dump tini version"
    command: "/sbin/tini"
    args: ["--version"]

fileExistenceTests:
  - name: "tini existence"
    path: "/sbin/tini"
    shouldExist: true

metadataTest:
  labels:
    - key: '${LBLVNDRK}'
      value: '${LBLVNDRV}'

  cmd: ${cmd}
  exposedPorts: ${expsdprts}
  entrypoint: ${entrypoint}
  workdir: '${wrkdir}'
EOF

  fi

  if [[ "${category}" = 'base' ]] || [[ "${category}" = 'utility' ]]
  then
    if ! sed -i '/^ *exposedPorts/d' "/tmp/${CSTCNFG}"
    then
      exitOnErr "sed -i '/^ *exposedPorts/d' /tmp/${CSTCNFG}"
    fi
  fi

}

runCntnrStst() {

  container-structure-test test --image "${DCKRIMG}" \
                                --config "/tmp/${CSTCNFG}"

}

main() {

  preReq
  crteCstCnfg
  runCntnrStst  

}

main 2>&1
