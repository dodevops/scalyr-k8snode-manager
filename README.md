# scalyr-k8snode-manager

[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/scalyr-k8snode-manager)](https://artifacthub.io/packages/search?repo=scalyr-k8snode-manager) ![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: latest](https://img.shields.io/badge/AppVersion-latest-informational?style=flat-square)

## Introduction

This helm chart installs a CronJob into a Kubernetes cluster, which periodically runs a pod that connects to all
Kubernetes nodes via SSH, installs or updates the Scalyr agent and deploys Scalyr configuration files.

This chart is not affiliated with Scalyr, Inc. in any way. For support, please open an issue in this
project's [issue tracker](https://github.com/dodevops/scalyr-k8snode-manager/issues).

## Installation

Use

    helm install <name of release> scalyr-agent --repo https://dodevops.io/scalyr-k8snode-manager

to install this chart.

## Configuration

Theses basic configuration keys have to be set up for managing Scalyr agents on the Kubernetes nodes:

* config.sshKey: The private key data of the SSH key used to connect to the Kubernetes nodes. Be sure that the
    public part of that keypair is allowed to connect to the node.
* config.sshPassPhrase: The passphrase of the private key used to connect to the Kubernetes nodes.
* config.sshUser: The remote user connecting to the Kubernetes nodes (e.g. ec2-user on EKS managed nodegroups)
* env: Additional environment variables (useful for templating; see below)
* config.scalyr.server: The name of the Scalyr api server (defaults to scalyr.com)
* config.scalyr.apiKey: The api key used to authenticate to the Scalyr api server
* config.scalyr.version: The version to install (defaults to the latest version)
* config.scalyr.config: The Scalyr configuration

The scalyr configuration is done using the
[configuration map approach](https://app.scalyr.com/help/scalyr-agent-k8s#modify-config). This is basically a key/value
hash. The keys refer to the configuration file name for grouping monitors. The value is the Scalyr json configuration
for each monitor.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| config.cronSchedule | string | `"0 0 * * *"` | Schedule to use for the CronJob |
| config.env | list | `[]` | Additional environment variables to set in the PodSpec Env-form (list of objects with name and value keys) |
| config.scalyr.apiKey | string | `""` | The Scalyr API key to use |
| config.scalyr.base64Config | bool | `true` | As Helm is currently [unable to correctly pass JSON strings](https://github.com/helm/helm/issues/5618), this can be set to true so all values of scalyr.config are expected to be base64 encoded and will be decoded in the chart |
| config.scalyr.config | object | `{}` | A hash of configuration files and their content as documented in the [Scalyr agent configmap configuration documentation](https://app.scalyr.com/help/scalyr-agent-k8s#modify-config) |
| config.scalyr.server | string | `"scalyr.com"` | The Scalyr server to send logs to |
| config.scalyr.version | string | `""` | Version of Scalyr to use |
| config.sftpServer | string | `"/usr/libexec/openssh/sftp-server"` | Path to the SFTP-Server binary on the node |
| config.sshKey | string | `""` | SSH private key data to use |
| config.sshPassPhrase | string | `""` | SSH passphrase for the key |
| config.sshUser | string | `""` | User to use when connecting to the node |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"dodevops/scalyr-k8snode-manager"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| restartPolicy | string | `"OnFailure"` |  |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

