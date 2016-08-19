#! /bin/bash
set -u

HCTLSLOC='/usr/local/bin'
HCTLSURL='https://releases.hashicorp.com'
declare -A HCTLSVER
HCTLS="consul \
       nomad \
       otto \
       packer \
       terraform \
       vault"
HCTLSVER[consul]='0.6.4'
HCTLSVER[nomad]='0.4.1'
HCTLSVER[otto]='0.2.0'
HCTLSVER[packer]='0.10.1'
HCTLSVER[terraform]='0.7.0'
HCTLSVER[vault]='0.6.0'
NDJSVER='6.4.0'
NDJSURL='https://nodejs.org'
GCPSVER='122.0.0'
GCPSURL='https://dl.google.com/dl/cloudsdk/channels/rapid/downloads'


exitOnErr() {

    local date=$($date)
    echo " Error: <$date> $1, exiting ..."
    exit 1

}

sudo apt-key adv --keyserver \
  hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo

sudo apt-get update && \
sudo apt-get install -y --no-install-recommends \
  unzip \
  apt-transport-https \
  ca-certificates
echo

echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main'| \
  sudo tee /etc/apt/sources.list.d/docker.list
echo

sudo apt-get update && \
  sudo apt-get purge lxc-docker
echo

apt-cache policy docker-engine
echo

sudo apt-get update && \
sudo apt-get install -y --no-install-recommends \
  linux-image-extra-$(uname -r) \
  apparmor
echo

sudo apt-get update && \
sudo apt-get install -y --no-install-recommends \
  docker-engine
echo

sudo usermod -aG docker ubuntu
echo

sudo docker info
echo

sudo apt-get install -y --no-install-recommends \
  linux-image-extra-$(uname -r) \
  build-essential \
  libssl-dev \
  libffi-dev \
  python-dev \
  python-pip \
  git
echo

sudo pip install -U fabric \
  requests \
  boto \
  bottle \
  cryptography
echo

if uname -v | grep -i darwin 2>&1 > /dev/null
then
  OS='darwin'
  HCTLSLOC='~/Development/Cloud/Works'
else
  OS='linux'
fi

for t in $HCTLS
do
  if ! wget -P /tmp --tries=5 -q -L "$HCTLSURL/$t/${HCTLSVER[$t]}/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip"
  then
    exitOnErr "wget -P /tmp $HCTLSURL/$t/${HCTLSVER[$t]}/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip failed"
  else
    if ! sudo unzip -o "/tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip" -d "$HCTLSLOC"
    then
      exitOnErr "unzip /tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip -d $HCTLSLOC"
    else
      rm -fv "/tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip"
      eval "$t" version
    fi
  fi
done

pushd /opt
if ! sudo wget -P /opt --tries=5 -q -L "${NDJSURL}/dist/v${NDJSVER}/node-v${NDJSVER}-${OS}-x64.tar.xz" 2>&1 > /dev/null
then
  exitOnErr "wget -P /opt ${NDJSURL}/dist/v${NDJSVER}/node-v${NDJSVER}-${OS}-x64.tar.xz failed"
else
  if ! sudo tar Jxf "node-v${NDJSVER}-${OS}-x64.tar.xz" 2>&1 > /dev/null
  then
    exitOnErr "tar Jxf node-v${NDJSVER}-${OS}-x64.tar.xz failed"
  else
    sudo rm "node-v${NDJSVER}-${OS}-x64.tar.xz"
    sudo mv "node-v${NDJSVER}-${OS}-x64" nodejs
    sudo ln -s "/opt/nodejs/bin/node" /usr/local/bin/node
    sudo ln -s "/opt/nodejs/bin/npm" /usr/local/bin/npm 
  fi
fi

if ! sudo wget -P /opt --tries=5 -q -L "${GCPSURL}/google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz" 2>&1 > /dev/null
then
  exitOnErr "wget -P /opt ${GCPSURL}/google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz failed"
else
  if ! sudo tar zxf "google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz" 2>&1 > /dev/null
  then
    exitOnErr "tar google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz failed"
  else
    sudo google-cloud-sdk/install.sh -q
    sudo ln -s "/opt/google-cloud-sdk/bin/gcloud" /usr/local/bin/gcloud
    sudo gcloud -q components install kubectl
  fi
fi

pip list|grep -Ei '(boto|requests|bottle|cryptography)'
fab -V
node -v
npm -v
gcloud components list
