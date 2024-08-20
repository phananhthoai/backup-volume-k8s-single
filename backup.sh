#!/usr/bin/env bash
set -euo pipefail

if [ $(id -un) != root ]; then
  sudo -u root -EH ${0} "${@}"
  exit 0
fi

namespace=${1:?}

sudo mkdir -p /mnt/backups/${namespace}

microk8s kubectl get pv -o json | jq -r ".items[] | select(.spec.claimRef.namespace == \"${namespace}\") | .spec.hostPath.path" | while read line; do
  name=$(basename "${line}" | sed -E 's/-pvc-.+$//' | sed -E "s/^${namespace}-//")

  pods_name=$(microk8s kubectl get -n ${namespace} pods -o json | jq -r ".items | map(select(.spec.volumes | map(select(.persistentVolumeClaim.claimName == \"${name}\")) | select(length > 0)) | .metadata.name) | join(\",\")")
  if ! [ -z "${pods_name}" ]; then
    echo "WARNING: PVC ${namespace}/${name} con duoc tham chieu boi ${pods_name} pods !!!"
    continue
  fi
  if [ -f "/mnt/backups/${namespace}/${name}.tar" ]; then
    echo "File exist !!!"
    continue
  else
    pushd "${line}"
    tar -cvf "/mnt/backups/${namespace}/${name}.tar" .
    popd
  fi
done

echo OK
