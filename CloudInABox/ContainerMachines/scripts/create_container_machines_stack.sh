#! /bin/bash

OPTN=${1}
OPTNTST=${2}
NUMOPTNMX=3
DLYTOMSTL=5
CMPSFLDIR='.'
ANSBLEDIR='../ansible'
FTLSCTDIR='/var/lib/footloose'
ASBLCMTEST='ansible_test.yml'
ASBLCMDCKR='ansible_docker.yml'
FTLSCMPSCT='footloose_create.yml'
FTLSCMPSDL='footloose_delete.yml'
RQRDCMNDS="awk
           cat
           chmod
           date
           docker
           docker-compose
           grep"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
    fi
  done

  export COMPOSE_IGNORE_ORPHANS=1

}

exitOnErr() {

  echo " Error: <$(date)> $1, exiting ..."
  exit 1

}

printUsage() {

  cat <<EOF
 Usage: $(basename $0) < create|buildcreate|show|
                         test [ping|docker]|delete|cleandelete >"
EOF
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "create" ]] && \
     [[ "${OPTN}" != "buildcreate" ]] && \
     [[ "${OPTN}" != "show" ]] && \
     [[ "${OPTN}" != "test" ]] && \
     [[ "${OPTN}" != "delete" ]] &&
     [[ "${OPTN}" != "cleandelete" ]]

  then
    printUsage
  fi

}

showFTLStack() {

  if ! docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
                           -v $(pwd)/footloose.yaml:/tmp/footloose.yaml:ro \
            footloose show
  then
    exitOnErr 'docker run footloose show failed'
  fi

}

createASBLInv() {

  if ! docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
                          -v $(pwd)/footloose.yaml:/tmp/footloose.yaml:ro \
           footloose show | \
       grep -v NAME | awk -F '  +' '{ if ( $2~"^ubuntu" ) {print $4,"ansible_python_interpreter=/usr/bin/python3"} else {print $4} }'> "${ANSBLEDIR}/hosts"
  then
    exitOnErr "docker run footloose show > ${ANSBLEDIR}/hosts failed"
  fi

}

copyPrivKey() {

  if ! docker cp "footloosecreate:${FTLSCTDIR}/cluster-key" "${ANSBLEDIR}"
  then
    exitOnErr "docker cp footloosecreate:${FTLSCTDIR}/cluster-key ${ANSBLEDIR} failed"
  else
    if ! chmod +r "${ANSBLEDIR}/cluster-key"
    then
      exitOnErr "chmod +r ${ANSBLEDIR}/cluster-key failed"
    fi
  fi

}

testASBLRun() {

  if [[ ! -z "${1}" ]] && \
     [[ "${1}" != "ping" ]] && \
     [[ "${1}" != "docker" ]]

  then
    printUsage
  fi

  createASBLInv
  copyPrivKey

  if [[ -z "${1}" ]] || [[ "${1}" = "ping" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMTEST}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMTEST}" up --build failed"
    fi

  elif [[ "${1}" = "docker" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDCKR}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDCKR}" up --build failed"
    fi

  fi

}

showAndTest() {

  showFTLStack
  sleep "${DLYTOMSTL}"
  echo
  testASBLRun "${1}"

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "create" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" up -d
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "buildcreate" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" up --build -d
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "delete" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" up
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" down
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" down
    showFTLStack
  elif [[ "${OPTN}" = "cleandelete" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" up
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" down -v
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" down
    showFTLStack
  elif [[ "${OPTN}" = "test" ]]
  then
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "show" ]]
  then
    showFTLStack
  fi

}

main 2>&1
