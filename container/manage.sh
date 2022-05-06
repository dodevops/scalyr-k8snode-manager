#!/usr/bin/env bash

# Manages Scalyr agent installation on k8s nodes
# Supported environment variables:
#
# METHOD=<nsenter or ssh>
# SCALYR_VERSION=<valid scalyr agent version>
# SCALYR_SERVER=<Scalyr server to use>
# SCALYR_APIKEY=<Scalyr API key>
# SCALYR_CONFIG_PATH=<Scalyr configuration files to use. All .json-files in that directory will be copied>
# SSH_KEY_PATH=<Path to the ssh private key>
# SSH_PASSPHRASE=<Passphrase of the SSH key>
# SSH_USER=<Username to use for connecting to the node>
# SFTP_SERVER=Path to the sftp-server executable on the node [/usr/libexec/openssh/sftp-server]
# USE_SUDO=true/false Whether to use sudo on the commands
#
# If the nodes will be accessed using SSH, a valid SSH private key should be mounted into the
# container.
#
# All configuration files will be preprocessed using [Mo](https://github.com/tests-always-included/mo), so all
# environment variables will be available as a template context.
# Additionally, the environment variable "NODE" contains the current node

COMMAND=("kubectl" "node-shell")
if [[ "X${METHOD}X" == "XsshX" ]]
then
  COMMAND=("setsid" "ssh")
  rm -rf ~/.ssh &>/dev/null
  mkdir ~/.ssh
  chmod 0700 ~/.ssh
  cat "${SSH_KEY_PATH}" > ~/.ssh/id_rsa
  chmod 0600 ~/.ssh/id_rsa
  echo "#!/usr/bin/env sh" > /usr/local/bin/sshkey
  echo "echo '${SSH_PASSPHRASE}'" >> /usr/local/bin/sshkey
  chmod +x /usr/local/bin/sshkey
  export SSH_ASKPASS=/usr/local/bin/sshkey

  # use DISPLAY and setsid to work around ssh scripting limitations
  # (https://unix.stackexchange.com/questions/83986/tell-ssh-to-use-a-graphical-prompt-for-key-passphrase)
  export DISPLAY=:0.0
  setsid ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub

  echo -e "Host *\n  User ${SSH_USER}\n  UserKnownHostsFile=/dev/null\n  StrictHostKeyChecking=no\n" > /root/.ssh/config;
else
  # Create context for kubectl node-shell
  kubectl config set-cluster cluster --server="https://${KUBERNETES_SERVICE_HOST}" --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt
  kubectl config set-credentials serviceaccount --token="$(cat /run/secrets/kubernetes.io/serviceaccount/token)"
  kubectl config set-context local --cluster=cluster --namespace=default --user=serviceaccount
  kubectl config use-context local
fi

SUDO_COMMAND=""

if [[ "X${USE_SUDO}X" == "XtrueX" ]]
then
  SUDO_COMMAND="sudo "
fi

for NODE in $(kubectl get nodes -o custom-columns=name:metadata.name --no-headers)
do
  echo "Managing node ${NODE}"
  echo "Downloading Scalyr agent installer"
  if ! OUTPUT=$("${COMMAND[@]}" "${NODE}" -- "${SUDO_COMMAND}"curl -sO https://www.scalyr.com/install-agent.sh 2>&1)
  then
    echo -e "Can't download Scalyr installer:\n ${OUTPUT}"
    exit 1
  fi
  echo "Installing Scalyr"
  if ! OUTPUT=$("${COMMAND[@]}" "${NODE}" -- "${SUDO_COMMAND}"bash install-agent.sh --set-api-key "${SCALYR_APIKEY}" --version "${SCALYR_VERSION}" --set-scalyr-server "${SCALYR_SERVER}" 2>&1)
  then
    echo -e "Can't install Scalyr:\n ${OUTPUT}"
    exit 1
  fi
  export NODE
  TEMPDIR=$(mktemp -d)
  for CONFIG in "${SCALYR_CONFIG_PATH}"/*.json
  do
    CONFIGFILE=$(basename "${CONFIG}")
    echo "Processing configuration ${CONFIGFILE}"
    if ! /usr/local/bin/mo < "${CONFIG}" > "${TEMPDIR}/${CONFIGFILE}"
    then
      echo -e "Can't process ${CONFIGFILE}:\n $(cat "${TEMPDIR}/${CONFIGFILE}")"
      exit 1
    fi
    echo "Uploading configuration ${CONFIGFILE}"
    if [[ "X${METHOD}X" == "XsshX" ]]
    then
      if ! OUTPUT=$(echo "put \"${TEMPDIR}/${CONFIGFILE}\" /etc/scalyr-agent-2/agent.d" | setsid sftp -s "${SUDO_COMMAND}${SFTP_SERVER:-/usr/libexec/openssh/sftp-server}" "${NODE}" 2>&1)
      then
        echo -e "Can't copy configuration:\n ${OUTPUT}"
        exit 1
      fi
    else
      if ! OUTPUT=$(kubectl node-shell "${NODE}" -- cat > "/etc/scalyr-agent-2/agent.d/${CONFIGFILE}" <"${TEMPDIR}/${CONFIGFILE}" 2>&1)
      then
        echo -e "Can't copy configuration:\n ${OUTPUT}"
        exit 1
      fi
    fi
  done
  rm -rf "${TEMPDIR}"
  echo "Starting Scalyr Agent"
  if ! OUTPUT=$("${COMMAND[@]}" "${NODE}" -- "${SUDO_COMMAND}"systemctl restart scalyr-agent-2 2>&1)
  then
    echo -e "Can't start scalyr agent:\n ${OUTPUT}"
    exit 1
  fi
done
