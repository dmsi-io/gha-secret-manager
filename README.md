# gha-secret-manager

The purpose of this GitHub Action is to automate the retrieval of environment-level secrets from GCP Secret Manager API.

### Usage

```yaml
steps:
  - name: Retrieve Environment Secrets
    id: secrets # use as ${{ steps.secrets.outputs.[key] }}
    uses: dmsi-io/gha-secret-manager@v1
    with:
      GCP_SA_KEY: ${{ secrets.GCP_SECRET_MANAGER_KEY }}
      GHA_ACCESS_USER: ${{ secrets.GHA_ACCESS_USER }}
      GHA_ACCESS_TOKEN: ${{ secrets.GHA_ACCESS_TOKEN }}
      secrets: GCP_PROJECT_ID, GCP_SA_KEY, GCP_ZONE, GKE_CLUSTER_NAME, TOP_LEVEL_DOMAIN

  - name: Example Usage
    uses: dmsi-io/gha-k8s-namespace@v1
    with:
      GCP_SA_KEY: ${{ steps.secrets.outputs.GCP_SA_KEY }}
      GKE_CLUSTER_NAME: ${{ steps.secrets.outputs.GKE_CLUSTER_NAME }}
      GCP_ZONE: ${{ steps.secrets.outputs.GCP_ZONE }}
      GCP_PROJECT_ID: ${{ steps.secrets.outputs.GCP_PROJECT_ID }}
      TLD: ${{ steps.secrets.outputs.TOP_LEVEL_DOMAIN }}
```


### Required Inputs

#### GCP Service Account Key

This service account should have its permissions limited to *read-only* access using the following IAM Roles:

```
- Secret Manager Secret Accessor

- Secret Manager Viewer
```

```yaml
  with:
    GCP_SA_KEY: ${{ secrets.GCP_SECRET_MANAGER_KEY }}
```

#### Secrets

Secrets will be managed by GCP Secret Manager and must follow a strict naming scheme. 

```
Production Secrets: PROD_[key]

Develop Secrets: DEVELOP_[key]
```

> There must exist both named versions of each key. 

When requesting a desired key from this action, the key must not include the environment prefix. This action will handle the checks and balances to determine which prefix to append to the requested keys (based on branch/tag names) and will always append an environment prefix.

The general rules are that `main` and `release/*` branches are provided the `PROD` prefix. Tags where the tagged commit sha exists within a `main` or `release/*` branch will also receive the `PROD` prefix. All other branches or tags will receive the `DEVELOP` prefix.

> All outputted secrets will be masked from console logs.

```yaml
  with:
    secrets: KEY

  # multiple secrets can be supplied as a comma-separated list
  with:
    secrets: KEY, OTHER_KEY
```