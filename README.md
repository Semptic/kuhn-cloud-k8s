# kuhn-cloud

This uses [Kube-Hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner) to setup the k8s cluster on hetzner cloud.

To get started you need to copy `secrets.auto.tfvars.example` to `secrets.auto.tfvars` and fill the secrets.

## Dashboards

### Kubernetes Dashboard

You need to create a token to get access:

```sh
kubectl -n kube-system create token admin-user
```
### Longhorn

Bla

## Setup

## Install

You need to have [opentofu](https://opentofu.org/) and [kubectl](https://kubernetes.io/docs/reference/kubectl/) installed.

## Update images

```sh
export HCLOUD_TOKEN=$(echo "nonsensitive(var.hcloud_token)" | terraform console -var-file secrets.auto.tfvars | sed -e 's/^"//' -e 's/"$//')

cd cluster/kube
curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/packer-template/hcloud-microos-snapshots.pkr.hcl -o "hcloud-microos-snapshots.pkr.hcl"
packer init hcloud-microos-snapshots.pkr.hcl
packer build hcloud-microos-snapshots.pkr.hcl
```

## Run

### OpenTofu

```sh
tofu init --upgrade
tofu validate
tofu apply -auto-approve
```

### kubectl

Normally the kube config is created automatically. Otherwise you can get it via 
```sh
terraform output --raw kubeconfig > k3s_kubeconfig.yaml
```

Now you can use kubectl like this:
```sh
export KUBECONFIG="$(pwd)/k3s_kubeconfig.yaml"

kubectl version
```

#### Setup

To setup the base line of cluster services like monitoring, storange, etc. you need to run `setup.sh` to make sure all are setup and installed in the correct order.

#### Secrets

Unfortunately it's not possible to provide the secrets to all places via the kubernetes secrets. Therefore the with_secrets.sh script exists which populates the secrets correctly. The secrets have to be stored in secrets.env. Copy .secrets.env.example and fill it with the correct secrets. 

Now you can create those via

```sh
./with_secrets.sh apply service/hello
```

and delete them via

```sh
./with_secrets.sh delete service/hello
```