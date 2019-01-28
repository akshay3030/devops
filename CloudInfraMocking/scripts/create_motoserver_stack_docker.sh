#! /bin/bash

OPTN=${1}
NUMOPTNMX=2
CMPSFLDIR='.'
CMPSEFILE='moto_server_stack.yml'
RQRDCMNDS="docker
           docker-compose"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
    fi
  done

}

printUsage() {

  echo " Usage: $(basename $0) < up|buildup|ps|logs|down|test|cleandown >"
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "up" ]] && \
     [[ "${OPTN}" != "ps" ]] && \
     [[ "${OPTN}" != "logs" ]] && \
     [[ "${OPTN}" != "down" ]] && \
     [[ "${OPTN}" != "test" ]] && \
     [[ "${OPTN}" != "cleandown" ]] && \
     [[ "${OPTN}" != "buildup" ]]
  then
    printUsage
  fi

}

testAwsCli() {

  docker-compose -f moto_server_stack.yml exec motoserver \
    sh -c 'AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=foo aws --endpoint-url=http://localhost:5000 --region=us-east-1 ec2 describe-instances'

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
    testAwsCli
  elif [[ "${OPTN}" = "test" ]]
  then
    testAwsCli
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    testAwsCli
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
