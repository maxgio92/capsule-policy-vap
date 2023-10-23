# Capsule policy with Validating Admission Policy

> **IMPORTANT**: this is a work in progress.

## Quickstart

Create a local Kubernetes cluster with `ValidatingAdmissionPolicy` feature gate enabled, and `admissionregistration.k8s.io/v1beta1` API enabled:

```shell
kind create cluster --config kind.yaml
```

Install Capsule CRDs:

```shell
kubectl apply -k ./crds
```

Create a Tenant and a Tenant owner:

```shell
kubectl apply -f ./oil-tenant.yaml
kubectl apply -f ./alice-tenant-owner-rolebinding.yaml
```

Install a Validating Admission Policy with Binding:

```shell
kubectl apply -f ./ingressclasses-validatingadmissionpolicy.yaml
```

As Tenant owner, create Ingress of denied class:

```shell
kubectl --as "alice" --as-group "capsule.clastix.io" apply -f ./ingress-silver.yaml
```

As Tenant owner, create Ingress of allowed class:

```shell
kubectl --as "alice" --as-group "capsule.clastix.io" apply -f ./ingress-bronze.yaml
```

## End-to-end test

```shell
make e2e
```

## Debug requests

Configure a `MutatingAdmissionWebhookConfiguration` (they're executed before validating webhooks) with an exposed web server like [`ngrok`](https://ngrok.com/):

```yml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: aaa-ingressclass-validating-policy
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    url: <YOUR WEB SERVER URL HERE>
  name: ingresses.vap.capsule.clastix.io
  rules:
  - apiGroups: ["networking.k8s.io"]
    apiVersions: ["v1"]
    operations: ["CREATE", "UPDATE"]
    resources: ["ingresses"]
  sideEffects: None
```

> You can run `ngrok` locally with `ngrok http 8080`.

Open your browser to `http://localhost:4040` and make a request:

```shell
kubectl --as "alice" --as-group "capsule.clastix.io" create -f ./ingress-silver.yaml
```

You can analyse the request with the `AdmissionReview` sent by the API server. You can find example of a `AdmissionReview` of a request made impersonating *Alice* `User` and *capsule.clastix.io* `Group`, in [this sample](./sample-tenant-owner-impersonation-admissionreview.yaml).

## References

- [CEL playground](https://playcel.undistro.io/)
- [CEL language spec](https://github.com/google/cel-spec/blob/master/doc/langdef.md)
- [Kubernetes Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy)

