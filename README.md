# TeamMapper Helm chart

Helm chart for deploying [TeamMapper](https://github.com/b310-digital/teammapper)
with a Zalando PostgreSQL Operator database.

## Requirements

- Kubernetes 1.25+
- Helm 3 or 4
- Zalando PostgreSQL Operator (`postgresqls.acid.zalan.do`)
- an Ingress controller when Ingress is enabled
- cert-manager when certificate annotations are configured

## Render and validate

```bash
helm lint . --strict --values values.sion2k.yaml
bash tests/render.sh
helm template teammapper . --namespace teammapper --values values.sion2k.yaml
```

## Required application secret

The chart deliberately does not create secrets. Before the first Argo CD sync,
create a strong JWT secret in the destination namespace:

```bash
kubectl create namespace teammapper --dry-run=client -o yaml | kubectl apply -f -
kubectl -n teammapper create secret generic teammapper-app \
  --from-literal=jwt-secret="$(openssl rand -base64 48)"
```

The PostgreSQL Operator creates the database credentials secret automatically.

## Argo CD

After creating the application secret, bootstrap the project and application:

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml
```

Argo CD tracks `main`, automatically reconciles drift, and prunes resources
removed from the chart. The PostgreSQL resource is protected against pruning;
its persistent storage must be removed explicitly if the installation is ever
decommissioned.

## Upgrades

Change the TeamMapper tag and digest together, run the validation suite, and
merge the change to `main`. Argo CD applies the resulting chart revision.

## Data retention

`values.sion2k.yaml` configures `DELETE_AFTER_DAYS=365`. TeamMapper deletes old
maps according to this setting, so review it before using this values file in
another environment.
