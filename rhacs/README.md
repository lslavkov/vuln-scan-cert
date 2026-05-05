# Vulnerability scanner certification pipeline for RHACS

## Pre-requisites 

### Deploy OCP cluster

Requirements TBD

### Install OpenShift Pipelines operator (Tekton)

### Red Hat SSO Service Account

- Follow this link to create a Red Hat Service Account: https://console.redhat.com/iam/service-accounts/
- Save Client ID and Client Secret
```shell
$ export CLIENT_ID=<my-client-id>
$ export CLIENT_SECRET=<my-client-secret>
```
- Create Kubernetes Secret
```shell
$ envsubst < rh-openid-credentials/rh-openid-credentials.template.yaml | oc apply -f -
```

### Apply RHACS Tasks and Pipeline definitions

```shell
oc apply -f tasks/
oc apply -f pipeline/
```


