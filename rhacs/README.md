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
$ oc apply -f tasks/
$ oc apply -f pipeline/
```

### Build Container images used in python steps

```shell
$ oc new-build --name python3-with-requests --binary --strategy docker
$ oc patch bc/python3-with-requests -p '{"spec":{"strategy":{"dockerStrategy":{"dockerfilePath":"Containerfile"}}}}'
$ oc start-build python3-with-requests --from-dir=./python-with-requests --follow
```

The image is now available in the internal registry `image-registry.openshift-image-registry.svc:5000/default/python3-with-requests:latest`.

It is used in steps that run Python code and require the `requests` module.