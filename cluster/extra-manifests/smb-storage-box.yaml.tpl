apiVersion: v1
kind: Secret
metadata:
  name: smb-credentials
stringData:
  username: ${smb_user}
  password: ${smb_pass}
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: smb
provisioner: smb.csi.k8s.io
parameters:
  source: "//${smb_user}.your-storagebox.de/backup"
  # if csi.storage.k8s.io/provisioner-secret is provided, will create a sub directory
  # with PV name under source
  csi.storage.k8s.io/provisioner-secret-name: "smb-credentials"
  csi.storage.k8s.io/provisioner-secret-namespace: "default"
  csi.storage.k8s.io/node-stage-secret-name: "smb-credentials"
  csi.storage.k8s.io/node-stage-secret-namespace: "default"
reclaimPolicy: Delete  # available values: Delete, Retain
volumeBindingMode: Immediate
mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=1001
  - gid=1001