locals {
  control_plane_nodepools = [
    {
      name        = "control-plane-fsn1",
      server_type = "cax11",
      location    = "fsn1",
      labels      = [ "svccontroller.k3s.cattle.io/enablelb=true" ],
      taints      = [],
      count       = 3

      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    },
  ]

}
module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token

  # Fix "Waiting for the k3s server to start..." error on creation
  postinstall_exec = ["restorecon -v /usr/local/bin/k3s"]

  # Then fill or edit the below values. Only the first values starting with a * are obligatory; the rest can remain with their default values, or you
  # could adapt them to your needs.

  # * For local dev, path to the git repo
  # source = "../../kube-hetzner/"
  # If you want to use the latest master branch
  # source = "github.com/kube-hetzner/terraform-hcloud-kube-hetzner"
  # For normal use, this is the path to the terraform registry
  source = "kube-hetzner/kube-hetzner/hcloud"

  # You can optionally specify a version number
  # version = "1.2.0"

  # Note that some values, notably "location" and "public_key" have no effect after initializing the cluster.
  # This is to keep Terraform from re-provisioning all nodes at once, which would lose data. If you want to update
  # those, you should instead change the value here and manually re-provision each node. Grep for "lifecycle".

  # Customize the SSH port (by default 22)
  # ssh_port = 2222

  # * Your ssh public key
  ssh_public_key = file("~/.ssh/id_ed25519.pub")
  # * Your private key must be "ssh_private_key = null" when you want to use ssh-agent for a Yubikey-like device authentification or an SSH key-pair with a passphrase.
  # For more details on SSH see https://github.com/kube-hetzner/kube-hetzner/blob/master/docs/ssh.md
  ssh_private_key = file("~/.ssh/id_ed25519")
  # You can add additional SSH public Keys to grant other team members root access to your cluster nodes.
  # ssh_additional_public_keys = []

  # You can also add additional SSH public Keys which are saved in the hetzner cloud by a label.
  # See https://docs.hetzner.cloud/#label-selector
  # ssh_hcloud_key_label = "role=admin"

  # If you use SSH agent and have issues with SSH connecting to your nodes, you can increase the number of auth tries (default is 2)
  # ssh_max_auth_tries = 10

  # If you want to use an ssh key that is already registered within hetzner cloud, you can pass its id.
  # If no id is passed, a new ssh key will be registered within hetzner cloud.
  # It is important that exactly this key is passed via `ssh_public_key` & `ssh_private_key` variables.
  # hcloud_ssh_key_id = ""

  # These can be customized, or left with the default values
  # * For Hetzner locations see https://docs.hetzner.com/general/others/data-centers-and-connection/
  network_region = "eu-central" # change to `us-east` if location is ash

  # If you must change the network CIDR you can do so below, but it is highly advised against.
  # network_ipv4_cidr = "10.0.0.0/8"

  # Using the default configuration you can only create a maximum of 42 agent-nodepools.
  # This is due to the creation of a subnet for each nodepool with CIDRs being in the shape of 10.[nodepool-index].0.0/16 which collides with k3s' cluster and service IP ranges (defaults below).
  # Furthermore the maximum number of nodepools (controlplane and agent) is 50, due to a hard limit of 50 subnets per network, see https://docs.hetzner.com/cloud/networks/faq/.
  # So to be able to create a maximum of 50 nodepools in total, the values below have to be changed to something outside that range, e.g. `10.200.0.0/16` and `10.201.0.0/16` for cluster and service respectively.

  # If you must change the cluster CIDR you can do so below, but it is highly advised against.
  # The cluster CIDR must be a part of the network CIDR!
  # cluster_ipv4_cidr = "10.42.0.0/16"

  # If you must change the service CIDR you can do so below, but it is highly advised against.
  # The service CIDR must be a part of the network CIDR!
  # service_ipv4_cidr = "10.43.0.0/16"

  # For the control planes, at least three nodes are the minimum for HA. Otherwise, you need to turn off the automatic upgrades (see README).
  # **It must always be an ODD number, never even!** Search the internet for "splitbrain problem with etcd" or see https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/
  # For instance, one is ok (non-HA), two is not ok, and three is ok (becomes HA). It does not matter if they are in the same nodepool or not! So they can be in different locations and of various types.

  # Of course, you can choose any number of nodepools you want, with the location you want. The only constraint on the location is that you need to stay in the same network region, Europe, or the US.
  # For the server type, the minimum instance supported is cpx11 (just a few cents more than cx11); see https://www.hetzner.com/cloud.

  # IMPORTANT: Before you create your cluster, you can do anything you want with the nodepools, but you need at least one of each, control plane and agent.
  # Once the cluster is up and running, you can change nodepool count and even set it to 0 (in the case of the first control-plane nodepool, the minimum is 1).
  # You can also rename it (if the count is 0), but do not remove a nodepool from the list.

  # You can safely add or remove nodepools at the end of each list. That is due to how subnets and IPs get allocated (FILO).
  # The maximum number of nodepools you can create combined for both lists is 50 (see above).
  # Also, before decreasing the count of any nodepools to 0, it's essential to drain and cordon the nodes in question. Otherwise, it will leave your cluster in a bad state.

  # Before initializing the cluster, you can change all parameters and add or remove any nodepools. You need at least one nodepool of each kind, control plane, and agent.
  # The nodepool names are entirely arbitrary, you can choose whatever you want, but no special characters or underscore, and they must be unique; only alphanumeric characters and dashes are allowed.

  # If you want to have a single node cluster, have one control plane nodepools with a count of 1, and one agent nodepool with a count of 0.

  # Please note that changing labels and taints after the first run will have no effect. If needed, you can do that through Kubernetes directly.

  # ⚠️ When choosing ARM cax* server types, for the moment they are only available in fsn1.
  # Muli-architecture clusters are OK for most use cases, as container underlying images tend to be multi-architecture too.

  # * Example below:

  control_plane_nodepools = local.control_plane_nodepools

  agent_nodepools = [
    {
      name        = "agent-small-arm",
      server_type = "cax11",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 0

      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    },
    # # Egress nodepool useful to route egress traffic using Hetzner Floating IPs (https://docs.hetzner.com/cloud/floating-ips)
    # # used with Cilium's Egress Gateway feature https://docs.cilium.io/en/stable/gettingstarted/egress-gateway/
    # # See the https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner#examples for an example use case.
    # {
    #   name        = "egress",
    #   server_type = "cax11",
    #   location    = "fsn1",
    #   labels = [
    #     "node.kubernetes.io/role=egress"
    #   ],
    #   taints = [
    #     "node.kubernetes.io/role=egress:NoSchedule"
    #   ],
    #   floating_ip = true
    #   count = 1
    # },
  ]
  # Add custom control plane configuration options here.
  # E.g to enable monitoring for etcd, proxy etc:
  # control_planes_custom_config = {
  #  etcd-expose-metrics = true,
  #  kube-controller-manager-arg = "bind-address=0.0.0.0",
  #  kube-proxy-arg ="metrics-bind-address=0.0.0.0",
  #  kube-scheduler-arg = "bind-address=0.0.0.0",
  # }

  # You can enable encrypted wireguard for the CNI by setting this to "true". Default is "false".
  # FYI, Hetzner says "Traffic between cloud servers inside a Network is private and isolated, but not automatically encrypted."
  # Source: https://docs.hetzner.com/cloud/networks/faq/#is-traffic-inside-hetzner-cloud-networks-encrypted
  # It works with all CNIs that we support.
  # Just note, that if Cilium with cilium_values, the responsability of enabling of disabling Wireguard falls on you.
  # enable_wireguard = true

  # * LB location and type, the latter will depend on how much load you want it to handle, see https://www.hetzner.com/cloud/load-balancer
  # load_balancer_type     = "lb11"
  # load_balancer_location = "fsn1"

  # Disable IPv6 for the load balancer, the default is false.
  # load_balancer_disable_ipv6 = true

  # Disables the public network of the load balancer. (default: false).
  # load_balancer_disable_public_network = true

  # Specifies the algorithm type of the load balancer. (default: round_robin).
  # load_balancer_algorithm_type = "least_connections"

  # Specifies the interval at which a health check is performed. Minimum is 3s (default: 15s).
  # load_balancer_health_check_interval = "5s"

  # Specifies the timeout of a single health check. Must not be greater than the health check interval. Minimum is 1s (default: 10s).
  # load_balancer_health_check_timeout = "3s"

  # Specifies the number of times a health check is retried before a target is marked as unhealthy. (default: 3)
  # load_balancer_health_check_retries = 3

  ### The following values are entirely optional (and can be removed from this if unused)

  # You can refine a base domain name to be use in this form of nodename.base_domain for setting the reserve dns inside Hetzner
  # base_domain = "k8s.kuhn.cloud"

  # Cluster Autoscaler
  # Providing at least one map for the array enables the cluster autoscaler feature, default is disabled
  # By default we set a compatible version with the default initial_k3s_channel, to set another one,
  # have a look at the tag value in https://github.com/kubernetes/autoscaler/blob/master/charts/cluster-autoscaler/values.yaml
  # ⚠️ Based on how the autoscaler works with this project, you can only choose either x86 instances or ARM server types for ALL autocaler nodepools.
  # Also, as mentioned above, for the time being ARM cax* instances are only available in fsn1.
  # If you are curious, it's ok to have a multi-architecture cluster, as most underlying container images are multi-architecture too.
  # * Example below:
  autoscaler_nodepools = [
    {
      name        = "autoscaled-arm-small"
      server_type = "cax11",
      location    = "fsn1"
      min_nodes   = 0
      max_nodes   = 5
    }
  ]

  # Add extra labels on nodes started by the Cluster Autoscaler
  # This argument is not used if autoscaler_nodepools is not set, because the Cluster Autoscaler is installed only if autoscaler_nodepools is set
  # autoscaler_labels = [
  #   "node.kubernetes.io/role=peak-workloads"
  # ]

  # Add extra taints on nodes started by the Cluster Autoscaler
  # This argument is not used if autoscaler_nodepools is not set, because the Cluster Autoscaler is installed only if autoscaler_nodepools is set
  # autoscaler_taints = [
  #   "node.kubernetes.io/role=specific-workloads:NoExecute"
  # ]

  # Configuration of the Cluster Autoscaler binary
  #
  # These arguments and variables are not used if autoscaler_nodepools is not set, because the Cluster Autoscaler is installed only if autoscaler_nodepools is set.
  #
  # Image and version of Kubernetes Cluster Autoscaler for Hetzner Cloud:
  #   - cluster_autoscaler_image: Image of Kubernetes Cluster Autoscaler for Hetzner Cloud to be used.
  #   - cluster_autoscaler_version: Version of Kubernetes Cluster Autoscaler for Hetzner Cloud. Should be aligned with Kubernetes version.
  #
  # Logging related arguments are managed using separate variables:
  #   - cluster_autoscaler_log_level: Controls the verbosity of logs (--v)
  #   - cluster_autoscaler_log_to_stderr: Determines whether to log to stderr (--logtostderr)
  #   - cluster_autoscaler_stderr_threshold: Sets the threshold for logs that go to stderr (--stderrthreshold)
  #
  # Example (using the default values):
  #
  # cluster_autoscaler_image = "registry.k8s.io/autoscaling/cluster-autoscaler"
  # cluster_autoscaler_version = "v1.26.2"
  # cluster_autoscaler_log_level = 4
  # cluster_autoscaler_log_to_stderr = true
  # cluster_autoscaler_stderr_threshold = "WARNING"

  # Additional Cluster Autoscaler binary configuration
  #
  # cluster_autoscaler_extra_args can be used for additional arguments. The default is an empty array.
  #
  # Please note that following arguments are managed by terraform-hcloud-kube-hetzner or the variables above and should not be set manually:
  #   - --v=${var.cluster_autoscaler_log_level}
  #   - --logtostderr=${var.cluster_autoscaler_log_to_stderr}
  #   - --stderrthreshold=${var.cluster_autoscaler_stderr_threshold}
  #   - --cloud-provider=hetzner
  #   - --nodes ...
  #
  # See the Cluster Autoscaler FAQ for the full list of arguments: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-parameters-to-ca
  #
  # Example:
  #
  # cluster_autoscaler_extra_args = [
  #   "--ignore-daemonsets-utilization=true",
  #   "--enforce-node-group-min-size=true",
  # ]

  # Enable etcd snapshot backups to S3 storage.
  # Just provide a map with the needed settings (according to your S3 storage provider) and backups to S3 will
  # be enabled (with the default settings for etcd snapshots).
  # Cloudflare's R2 offers 10GB, 10 million reads and 1 million writes per month for free.
  # For proper context, have a look at https://docs.k3s.io/datastore/backup-restore.
  # etcd_s3_backup = {
  #   etcd-s3-endpoint        = "xxxx.r2.cloudflarestorage.com"
  #   etcd-s3-access-key      = "<access-key>"
  #   etcd-s3-secret-key      = "<secret-key>"
  #   etcd-s3-bucket          = "k3s-etcd-snapshots"
  # }

  # To enable Hetzner Storage Box support, you can enable csi-driver-smb, default is "false".
  enable_csi_driver_smb = true

  # To use local storage on the nodes, you can enable Longhorn, default is "false".
  # See a full recap on how to configure agent nodepools for longhorn here https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/discussions/373#discussioncomment-3983159
  # Also see Longhorn best practices here https://gist.github.com/ifeulner/d311b2868f6c00e649f33a72166c2e5b
  # enable_longhorn = true

  # By default, longhorn is pulled from https://charts.longhorn.io.
  # If you need a version of longhorn which assures compatibility with rancher you can set this variable to https://charts.rancher.io.
  # longhorn_repository = "https://charts.rancher.io"

  # The namespace for longhorn deployment, default is "longhorn-system".
  # longhorn_namespace = "longhorn-system"

  # The file system type for Longhorn, if enabled (ext4 is the default, otherwise you can choose xfs).
  # longhorn_fstype = "xfs"

  # how many replica volumes should longhorn create (default is 3).
  # longhorn_replica_count = 1

  # When you enable Longhorn, you can go with the default settings and just modify the above two variables OR you can add a longhorn_values variable
  # with all needed helm values, see towards the end of the file in the advanced section.
  # If that file is present, the system will use it during the deploy, if not it will use the default values with the two variable above that can be customized.
  # After the cluster is deployed, you can always use HelmChartConfig definition to tweak the configuration.

  # Also, you can choose to use a Hetzner volume with Longhorn. By default, it will use the nodes own storage space, but if you add an attribute of
  # longhorn_volume_size (⚠️ not a variable, just a possible agent nodepool attribute) with a value between 10 and 10000 GB to your agent nodepool definition, it will create and use the volume in question.
  # See the agent nodepool section for an example of how to do that.

  # To disable Hetzner CSI storage, you can set the following to "true", default is "false".
  disable_hetzner_csi = true

  # If you want to use a specific Hetzner CCM and CSI version, set them below; otherwise, leave them as-is for the latest versions.
  # hetzner_ccm_version = ""
  # hetzner_csi_version = ""

  # If you want to specify the Kured version, set it below - otherwise it'll use the latest version available.
  # kured_version = ""

  # If you want to enable the Nginx ingress controller (https://kubernetes.github.io/ingress-nginx/) instead of Traefik, you can set this to "nginx". Default is "traefik".
  # By the default we load optimal Traefik and Nginx ingress controller config for Hetzner, however you may need to tweak it to your needs, so to do,
  # we allow you to add a traefik_values and nginx_values, see towards the end of this file in the advanced section.
  # After the cluster is deployed, you can always use HelmChartConfig definition to tweak the configuration.
  # If you want to disable both controllers set this to "none"
  # ingress_controller = "nginx"

  # You can change the number of replicas for selected ingress controller here. The default 0 means autoselecting based on number of agent nodes (1 node = 1 replica, 2 nodes = 2 replicas, 3+ nodes = 3 replicas)
  # ingress_replica_count = 1

  # Use the klipperLB (similar to metalLB), instead of the default Hetzner one, that has an advantage of dropping the cost of the setup.
  # Automatically "true" in the case of single node cluster (as it does not make sense to use the Hetzner LB in that situation).
  # It can work with any ingress controller that you choose to deploy.
  # Please note that because the klipperLB points to all nodes, we automatically allow scheduling on the control plane when it is active.
  enable_klipper_metal_lb = "true"

  # If you want to configure additional arguments for traefik, enter them here as a list and in the form of traefik CLI arguments; see https://doc.traefik.io/traefik/reference/static-configuration/cli/
  # They are the options that go into the additionalArguments section of the Traefik helm values file.
  # Example:
  # traefik_additional_options = ["--log.level=DEBUG", "--tracing=true"]

  # By default traefik is configured to redirect http traffic to https, you can set this to "false" to disable the redirection.
  # The default is true.
  # traefik_redirect_to_https = false

  # Enable or disable Horizontal Pod Autoscaler for traefik.
  # The default is true.
  # traefik_autoscaling = false

  # Enable or disable pod disruption budget for traefik. Values are maxUnavailable: 33% and minAvailable: 1.
  # The default is true.
  # traefik_pod_disruption_budget = false

  # Enable or disable default resource requests and limits for traefik. Values requested are 100m & 50Mi and limits 300m & 150Mi.
  # The default is true.
  # traefik_resource_limits = false

  # If you want to configure additional ports for traefik, enter them here as a list of objects with name, port, and exposedPort properties.
  # Example:
  # traefik_additional_ports = [{name = "example", port = 1234, exposedPort = 1234}]

  # If you want to disable the metric server set this to "false". Default is "true".
  enable_metrics_server = true

  # If you want to allow non-control-plane workloads to run on the control-plane nodes, set this to "true". The default is "false".
  # True by default for single node clusters, and when enable_klipper_metal_lb is true. In those cases, the value below will be ignored.
  allow_scheduling_on_control_plane = true

  # If you want to disable the automatic upgrade of k3s, you can set below to "false".
  # Ideally, keep it on, to always have the latest Kubernetes version, but lock the initial_k3s_channel to a kube major version,
  # of your choice, like v1.25 or v1.26. That way you get the best of both worlds without the breaking changes risk.
  # For production use, always use an HA setup with at least 3 control-plane nodes and 2 agents, and keep this on for maximum security.

  # The default is "true" (in HA setup i.e. at least 3 control plane nodes & 2 agents, just keep it enabled since it works flawlessly).
  # automatically_upgrade_k3s = false

  # The default is "true" (in HA setup it works wonderfully well, with automatic roll-back to the previous snapshot in case of an issue).
  # IMPORTANT! For non-HA clusters i.e. when the number of control-plane nodes is < 3, you have to turn it off.
  # automatically_upgrade_os = false

  # If you need more control over kured and the reboot behaviour, you can pass additional options to kured.
  # For example limiting reboots to certain timeframes. For all options see: https://kured.dev/docs/configuration/
  # The default options are: `--reboot-command=/usr/bin/systemctl reboot --pre-reboot-node-labels=kured=rebooting --post-reboot-node-labels=kured=done --period=5m`
  # Defaults can be overridden by using the same key.
  # kured_options = {
  #   "reboot-days": "su"
  #   "start-time": "3am"
  #   "end-time": "8am"
  #   "time-zone": "Local"
  # }

  # Allows you to specify either stable, latest, testing or supported minor versions.
  # see https://rancher.com/docs/k3s/latest/en/upgrades/basic/ and https://update.k3s.io/v1-release/channels
  # ⚠️ If you are going to use Rancher addons for instance, it's always a good idea to fix the kube version to latest - 0.01,
  # ⚠️ Rancher currently only supports v1.25 and earlier versions: https://github.com/rancher/rancher/issues/41113
  # The default is "v1.26".
  # initial_k3s_channel = "stable" 

  # The cluster name, by default "k3s"
  # cluster_name = ""

  # Whether to use the cluster name in the node name, in the form of {cluster_name}-{nodepool_name}, the default is "true".
  # use_cluster_name_in_node_name = false

  # Extra k3s registries. This is useful if you have private registries and you want to pull images without additional secrets.
  # Or if you want to proxy registries for various reasons like rate-limiting.
  # It will create the registries.yaml file, more info here https://docs.k3s.io/installation/private-registry.
  # Note that you do not need to get this right from the first time, you can update it when you want during the life of your cluster.
  # The default is blank.
  /* k3s_registries = <<-EOT
    mirrors:
      hub.my_registry.com:
        endpoint:
          - "hub.my_registry.com"
    configs:
      hub.my_registry.com:
        auth:
          username: username
          password: password
  EOT */

  # Additional environment variables for the host OS on which k3s runs. See for example https://docs.k3s.io/advanced#configuring-an-http-proxy .
  # additional_k3s_environment = {
  #   "CONTAINERD_HTTP_PROXY" : "http://your.proxy:port",
  #   "CONTAINERD_HTTPS_PROXY" : "http://your.proxy:port",
  #   "NO_PROXY" : "127.0.0.0/8,10.0.0.0/8,",
  # }

  # Additional commands to execute on the host OS before the k3s install, for example fetching and installing certs.
  # preinstall_exec = [
  #   "curl https://somewhere.over.the.rainbow/ca.crt > /root/ca.crt",
  #   "trust anchor --store /root/ca.crt",
  # ]

  # Additional flags to pass to the k3s server command (the control plane).
  # k3s_exec_server_args = "--kube-apiserver-arg enable-admission-plugins=PodTolerationRestriction,PodNodeSelector"

  # Additional flags to pass to the k3s agent command (every agents nodes, including autoscaler nodepools).
  # k3s_exec_agent_args = "--kubelet-arg kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=1Gi"

  # If you want to allow all outbound traffic you can set this to "false". Default is "true".
  restrict_outbound_traffic = false

  # Allow access to the Kube API from the specified networks. The default is ["0.0.0.0/0", "::/0"].
  # Allowed values: null (disable Kube API rule entirely) or a list of allowed networks with CIDR notation.
  # For maximum security, it's best to disable it completely by setting it to null. However, in that case, to get access to the kube api,
  # you would have to connect to any control plane node via SSH, as you can run kubectl from within these.
  #firewall_kube_api_source = null

  # Allow SSH access from the specified networks. Default: ["0.0.0.0/0", "::/0"]
  # Allowed values: null (disable SSH rule entirely) or a list of allowed networks with CIDR notation.
  # Ideally you would set your IP there. And if it changes after cluster deploy, you can always update this variable and apply again.
  # firewall_ssh_source = ["1.2.3.4/32"]

  # Adding extra firewall rules, like opening a port
  # More info on the format here https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall
  # extra_firewall_rules = [
  #   {
  #     description = "For Postgres"
  #     direction       = "in"
  #     protocol        = "tcp"
  #     port            = "5432"
  #     source_ips      = ["0.0.0.0/0", "::/0"]
  #     destination_ips = [] # Won't be used for this rule
  #   },
  #   {
  #     description = "To Allow ArgoCD access to resources via SSH"
  #     direction       = "out"
  #     protocol        = "tcp"
  #     port            = "22"
  #     source_ips      = [] # Won't be used for this rule
  #     destination_ips = ["0.0.0.0/0", "::/0"]
  #   }
  # ]

  # If you want to configure a different CNI for k3s, use this flag
  # possible values: flannel (Default), calico, and cilium
  # As for Cilium, we allow infinite configurations via helm values, please check the CNI section of the readme over at https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/#cni.
  # Also, see the cilium_values at towards the end of this file, in the advanced section.
  # cni_plugin = "cilium"

  # You can choose the version of Cilium that you want. By default we keep the version up to date and configure Cilium with compatible settings according to the version.
  # cilium_version = "v1.14.0"

  # Set native-routing mode ("native") or tunneling mode ("tunnel"). Default: tunnel
  # cilium_routing_mode = "native"

  # Used when Cilium is configured in native routing mode. The CNI assumes that the underlying network stack will forward packets to this destination without the need to apply SNAT. Default: value of "cluster_ipv4_cidr"
  # cilium_ipv4_native_routing_cidr = "10.0.0.0/8"

  # Enables egress gateway to redirect and SNAT the traffic that leaves the cluster. Default: false
  # cilium_egress_gateway_enabled = true

  # You can choose the version of Calico that you want. By default, the latest is used.
  # More info on available versions can be found at https://github.com/projectcalico/calico/releases
  # Please note that if you are getting 403s from Github, it's also useful to set the version manually. However there is rarely a need for that!
  # calico_version = "v3.25.0"

  # If you want to disable the k3s default network policy controller, use this flag!
  # Both Calico and Ciliun cni_plugin values override this value to true automatically, the default is "false".
  # disable_network_policy = true

  # If you want to disable the automatic use of placement group "spread". See https://docs.hetzner.com/cloud/placement-groups/overview/
  # We advise to not touch that setting, unless you have a specific purpose.
  # The default is "false", meaning it's enabled by default.
  # placement_group_disable = true

  # By default, we allow ICMP ping in to the nodes, to check for liveness for instance. If you do not want to allow that, you can. Just set this flag to true (false by default).
  # block_icmp_ping_in = true

  # You can enable cert-manager (installed by Helm behind the scenes) with the following flag, the default is "true".
  # enable_cert_manager = false

  # IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner, defaults to ["1.1.1.1", "8.8.8.8", "9.9.9.9"].
  # The number of different DNS servers is limited to 3 by Kubernetes itself.
  # dns_servers = []

  # When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability.
  # The default is false.
  # use_control_plane_lb = true

  # When the above use_control_plane_lb is enabled, you can change the lb type for it, the default is "lb11".
  # control_plane_lb_type = "lb21"

  # When the above use_control_plane_lb is enabled, you can change to disable the public interface for control plane load balancer, the default is true.
  # control_plane_lb_enable_public_interface = false

  # Let's say you are not using the control plane LB solution above, and still want to have one hostname point to all your control-plane nodes.
  # You could create multiple A records of to let's say cp.cluster.my.org pointing to all of your control-plane nodes ips.
  # In which case, you need to define that hostname in the k3s TLS-SANs config to allow connection through it. It can be hostnames or IP addresses.
  # additional_tls_sans = ["cp.cluster.my.org"]

  # lb_hostname Configuration:
  # 
  # Purpose:
  # The lb_hostname setting optimizes communication between services within the Kubernetes cluster 
  # when they use domain names instead of direct service names. By associating a domain name directly 
  # with the Hetzner Load Balancer, this setting can help reduce potential communication delays.
  # 
  # Scenario:
  # If Service B communicates with Service A using a domain (e.g., `a.mycluster.domain.com`) that points 
  # to an external Load Balancer, there can be a slowdown in communication.
  # 
  # Guidance:
  # - If your internal services use domain names pointing to an external LB, set lb_hostname to a domain 
  #   like `mycluster.domain.com`.
  # - Create an A record pointing `mycluster.domain.com` to your LB's IP.
  # - Create a CNAME record for `a.mycluster.domain.com` (or xyz.com) pointing to `mycluster.domain.com`.
  # 
  # Technical Note:
  # This setting sets the `load-balancer.hetzner.cloud/hostname` in the Hetzner LB definition, suitable for 
  # both Nginx and Traefik ingress controllers.
  # 
  # Recommendation:
  # This setting is optional. If services communicate using direct service names, you can leave this unset.
  # For inter-namespace communication, use `.service_name` as per Kubernetes norms.
  # 
  # Example:
  # lb_hostname = "mycluster.domain.com"

  # You can enable Rancher (installed by Helm behind the scenes) with the following flag, the default is "false".
  # ⚠️ Rancher currently only supports Kubernetes v1.25 and earlier, you will need to set initial_k3s_channel to a supported version: https://github.com/rancher/rancher/issues/41113
  # When Rancher is enabled, it automatically installs cert-manager too, and it uses rancher's own self-signed certificates.
  # See for options https://rancher.com/docs/rancher/v2.0-v2.4/en/installation/resources/advanced/helm2/helm-rancher/#choose-your-ssl-configuration
  # The easiest thing is to leave everything as is (using the default rancher self-signed certificate) and put Cloudflare in front of it.
  # As for the number of replicas, by default it is set to the numbe of control plane nodes.
  # You can customized all of the above by adding a rancher_values variable see at the end of this file in the advanced section.
  # After the cluster is deployed, you can always use HelmChartConfig definition to tweak the configuration.
  # IMPORTANT: Rancher's install is quite memory intensive, you will require at least 4GB if RAM, meaning cx21 server type (for your control plane).
  # ALSO, in order for Rancher to successfully deploy, you have to set the "rancher_hostname".
  # enable_rancher = true

  # If using Rancher you can set the Rancher hostname, it must be unique hostname even if you do not use it.
  # If not pointing the DNS, you can just port-forward locally via kubectl to get access to the dashboard.
  # If you already set the lb_hostname above and are using a Hetzner LB, you do not need to set this one, as it will be used by default.
  # But if you set this one explicitly, it will have preference over the lb_hostname in rancher settings.
  # rancher_hostname = "rancher.xyz.dev"

  # When Rancher is deployed, by default is uses the "latest" channel. But this can be customized.
  # The allowed values are "stable" or "latest".
  # rancher_install_channel = "stable"

  # Finally, you can specify a bootstrap-password for your rancher instance. Minimum 48 characters long!
  # If you leave empty, one will be generated for you.
  # (Can be used by another rancher2 provider to continue setup of rancher outside this module.)
  # rancher_bootstrap_password = ""

  # Separate from the above Rancher config (only use one or the other). You can import this cluster directly on an
  # an already active Rancher install. By clicking "import cluster" choosing "generic", giving it a name and pasting
  # the cluster registration url below. However, you can also ignore that and apply the url via kubectl as instructed
  # by Rancher in the wizard, and that would register your cluster too.
  # More information about the registration can be found here https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/
  # rancher_registration_manifest_url = "https://rancher.xyz.dev/v3/import/xxxxxxxxxxxxxxxxxxYYYYYYYYYYYYYYYYYYYzzzzzzzzzzzzzzzzzzzzz.yaml"

  # Extra commands to be executed after the `kubectl apply -k` (useful for post-install actions, e.g. wait for CRD, apply additional manifests, etc.).
  # extra_kustomize_deployment_commands=""

  # Extra values that will be passed to the `extra-manifests/kustomization.yaml.tpl` if its present.
  extra_kustomize_parameters = {
    inwx_email : var.inwx_email,
    inwx_user : var.inwx_user,
    inwx_pass : var.inwx_pass,
    smb_user : var.smb_user,
    smb_pass : var.smb_pass,
  }

  # See an working example for just a manifest.yaml, a HelmChart and a HelmChartConfig examples/kustomization_user_deploy/README.md

  # It is best practice to turn this off, but for backwards compatibility it is set to "true" by default.
  # See https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/issues/349
  # When "false". The kubeconfig file can instead be created by executing: "terraform output --raw kubeconfig > cluster_kubeconfig.yaml"
  # Always be careful to not commit this file!
  create_kubeconfig = true

  # Don't create the kustomize backup. This can be helpful for automation.
  # create_kustomization = false

  # MicroOS snapshot IDs to be used. Per default empty, the most recent image created using createkh will be used.
  # We recommend the default, but if you want to use specific IDs you can.
  # You can fetch the ids with the hcloud cli by running the "hcloud image list --selector 'microos-snapshot=yes'" command.
  # microos_x86_snapshot_id = "1234567"
  # microos_arm_snapshot_id = "1234567"

  ### ADVANCED - Custom helm values for packages above (search _values if you want to located where those are mentioned upper in this file)
  # ⚠️ Inside the _values variable below are examples, up to you to find out the best helm values possible, we do not provide support for customized helm values.
  # Please understand that the indentation is very important, inside the EOTs, as those are proper yaml helm values.
  # We advise you to use the default values, and only change them if you know what you are doing!

  # Cilium, all Cilium helm values can be found at https://github.com/cilium/cilium/blob/master/install/kubernetes/cilium/values.yaml
  # Be careful when maintaining your own cilium_values, as the choice of available settings depends on the Cilium version used. See also the cilium_version setting to fix a specific version.
  # The following is an example, please note that the current indentation inside the EOT is important.
  /*   cilium_values = <<EOT
ipam:
  mode: kubernetes
k8s:
  requireIPv4PodCIDR: true
kubeProxyReplacement: true
routingMode: native
ipv4NativeRoutingCIDR: "10.0.0.0/8"
endpointRoutes:
  enabled: true
loadBalancer:
  acceleration: native
bpf:
  masquerade: true
encryption:
  enabled: true
  type: wireguard
MTU: 1450
  EOT */

  # Cert manager, all cert-manager helm values can be found at https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  # The following is an example, please note that the current indentation inside the EOT is important.
  /*   cert_manager_values = <<EOT
installCRDs: true
replicaCount: 3
webhook:
  replicaCount: 3
cainjector:
  replicaCount: 3
  EOT */

  # csi-driver-smb, all csi-driver-smb helm values can be found at https://github.com/kubernetes-csi/csi-driver-smb/blob/master/charts/latest/csi-driver-smb/values.yaml
  # The following is an example, please note that the current indentation inside the EOT is important.
  /*   csi_driver_smb_values = <<EOT
controller:
  name: csi-smb-controller
  replicas: 1
  runOnMaster: false
  runOnControlPlane: false
  resources:
    csiProvisioner:
      limits:
        memory: 300Mi
      requests:
        cpu: 10m
        memory: 20Mi
    livenessProbe:
      limits:
        memory: 100Mi
      requests:
        cpu: 10m
        memory: 20Mi
    smb:
      limits:
        memory: 200Mi
      requests:
        cpu: 10m
        memory: 20Mi
  EOT */

  # Longhorn, all Longhorn helm values can be found at https://github.com/longhorn/longhorn/blob/master/chart/values.yaml
  # The following is an example, please note that the current indentation inside the EOT is important.
  /*   longhorn_values = <<EOT
defaultSettings:
  defaultDataPath: /var/longhorn
persistence:
  defaultFsType: ext4
  defaultClassReplicaCount: 3
  defaultClass: true
  EOT */

  # Traefik, all Traefik helm values can be found at https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml
  # The following is an example, please note that the current indentation inside the EOT is important.
  /*   traefik_values = <<EOT
deployment:
  replicas: 1
globalArguments: []
service:
  enabled: true
  type: LoadBalancer
  annotations:
    "load-balancer.hetzner.cloud/name": "k3s"
    "load-balancer.hetzner.cloud/use-private-ip": "true"
    "load-balancer.hetzner.cloud/disable-private-ingress": "true"
    "load-balancer.hetzner.cloud/location": "nbg1"
    "load-balancer.hetzner.cloud/type": "lb11"
    "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"

ports:
  web:
    redirectTo: websecure

    proxyProtocol:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
    forwardedHeaders:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
  websecure:
    proxyProtocol:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
    forwardedHeaders:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
  EOT */

  # Nginx, all Nginx helm values can be found at https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml
  # You can also have a look at https://kubernetes.github.io/ingress-nginx/, to understand how it works, and all the options at your disposal.
  # The following is an example, please note that the current indentation inside the EOT is important.
  /*   nginx_values = <<EOT
controller:
  watchIngressWithoutClass: "true"
  kind: "DaemonSet"
  config:
    "use-forwarded-headers": "true"
    "compute-full-forwarded-for": "true"
    "use-proxy-protocol": "true"
  service:
    annotations:
      "load-balancer.hetzner.cloud/name": "k3s"
      "load-balancer.hetzner.cloud/use-private-ip": "true"
      "load-balancer.hetzner.cloud/disable-private-ingress": "true"
      "load-balancer.hetzner.cloud/location": "nbg1"
      "load-balancer.hetzner.cloud/type": "lb11"
      "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
  EOT */

  # Rancher, all Rancher helm values can be found at https://rancher.com/docs/rancher/v2.5/en/installation/install-rancher-on-k8s/chart-options/
  # The following is an example, please note that the current indentation inside the EOT is important.
  /*   rancher_values = <<EOT
ingress:
  tls:
    source: "rancher"
hostname: "rancher.example.com"
replicas: 1
bootstrapPassword: "supermario"
  EOT */
}

terraform {
  required_version = ">= 1.4.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.41.0"
    }
  }
}

output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}

output "num_control_plane_nodes" {
  value = sum([for pool in local.control_plane_nodepools: pool.count])
  
}
output "ingress_public_ipv4" {
  value = module.kube-hetzner.ingress_public_ipv4 == module.kube-hetzner.control_planes_public_ipv4[0] ? module.kube-hetzner.control_planes_public_ipv4 : [ module.kube-hetzner.ingress_public_ipv4 ]
}

output "ingress_public_ipv6" {
  value = module.kube-hetzner.ingress_public_ipv6 == null ? [] : [ module.kube-hetzner.ingress_public_ipv6 ] 
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}


variable "inwx_user" {
  type = string
}
variable "inwx_pass" {
  type      = string
  sensitive = true
}
variable "inwx_email" {
  type = string
}

variable "smb_user" {
  type = string
}
variable "smb_pass" {
  type      = string
  sensitive = true
}