#!/usr/bin/env bash
set -euo pipefail

namespace=${1:?}

microk8s kubectl get pv -o json | jq -r ".items[] | select(.spec.claimRef.namespace == \"${namespace}\") | .spec.hostPath.path" | while read line; do
  name=$(basename "${line}" | sed -E 's/-pvc-.+$//' | sed -E "s/^${namespace}-//")

  pods_name=$(microk8s kubectl get -n ${namespace} pods -o json | jq -r ".items | map(select(.spec.volumes | map(select(.persistentVolumeClaim.claimName == \"${name}\")) | select(length > 0)) | .metadata.name) | join(\",\")")
  if ! [ -z "${pods_name}" ]; then
    echo "WARNING: PVC ${namespace}/${name} con duoc tham chieu boi ${pods_name} pods !!!"
    continue
  fi
  sudo rm -rf "${line}"
  sudo mkdir "${line}"
  pushd "${line}"
  sudo tar -xvf "/home/khanh/atlassian-system/${name}.tar"
  popd
done

echo OK
