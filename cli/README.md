# Causely CLI

The Causely CLI wraps [Helm](https://helm.sh/) so you can install and manage the Causely agent in Kubernetes from your terminal. For the full product guide (prerequisites, storage, OpenShift, and next steps), see **[CLI Installation](https://docs.causely.ai/installation/cli/)** in the Causely documentation.

## Prerequisites

Before you install the agent, your environment should meet the requirements described in the docs, including:

- **Kubernetes** 1.18+
- **Helm** 3.8+
- **Persistent volumes**: the platform needs permission to create and bind PVCs for Mediator and VictoriaMetrics storage (default `StorageClass`, or a pre-provisioned volume if dynamic provisioning is disabled)

Details on storage, OpenShift, and custom `StorageClass` options are on the [CLI Installation](https://docs.causely.ai/installation/cli/) page.

## Install the CLI

Download and install the official binary using the install script from Causely:

```bash
bash -c "$(curl -fksSL https://install.causely.ai/install.sh)"
```

The CLI is a thin wrapper around Helm. If you prefer, you can use Helm directly; see [Helm installation](https://docs.causely.ai/installation/helm/) in the docs.

If `causely` is not on your `PATH`, invoke it with an absolute path (for example `~/bin/causely`).

## Install the Causely agent

### 1. Get an access token

1. Open [https://portal.causely.app](https://portal.causely.app) and sign in.
2. In the sidebar, open **Mediators**.
3. Use **Add** and copy the access token for the next step.

### 2. Run the install command

Replace `<my_token>` with your mediator access token:

```bash
causely agent install --token <my_token>
```

This targets the cluster for your current **kubectl** context. To pick another context or tune the chart, use the flags in [Agent install options](#agent-install-options) below.

### 3. Verify discovery

In the portal, check **Integrations → Agents** and **Topology** to confirm the agent registered and entities appear. Root causes will show in **Root Cause** as the platform analyzes your environment.

## Authentication (optional)

If you omit `--token`, the CLI can try to fetch the default mediator token from the Causely API using credentials stored after login. That path is intended for users who can obtain that token via the API (for example organization administrators).

1. Log in (you will be prompted for username and password if you omit flags):

   ```bash
   causely auth login --user you@example.com
   ```

2. Run install without `--token` (you can pass `--mediator` if you need a specific mediator):

   ```bash
   causely agent install
   ```

Tokens are saved under `~/.causely/auth.json`. If the API returns an authentication error, run `causely auth login` again.

## Commands overview

| Command | Purpose |
|--------|---------|
| `causely version` | Print the CLI version. |
| `causely auth login` | Sign in and store API credentials under `~/.causely/`. |
| `causely agent install` | `helm upgrade --install` the Causely chart with mediator settings. |
| `causely agent uninstall` | Remove the Helm release from the cluster. |

Use `--help` on any command for the full flag list (for example `causely agent install --help`).

## Agent install options

Common flags (defaults match the CLI implementation in this repository):

| Flag | Description |
|------|-------------|
| `--token` | Mediator access token from the portal. If omitted, the CLI uses `causely auth login` credentials to request a default token (see [Authentication](#authentication-optional)). |
| `--namespace` | Kubernetes namespace for the release (default `causely`). |
| `--repository` | OCI registry path for images/chart (default `us-docker.pkg.dev/public-causely/public`). |
| `--tag` | Image/chart version tag (defaults to the CLI build version when set at build time). |
| `--cluster-name` | Value for `global.cluster_name` in Helm. If omitted, the CLI tries `kubectx --current`, then `kubectl ctx --current`. |
| `--kube-context` | Passed through to Helm as `--kube-context`. |
| `--values` | Extra Helm values file (`--values` for `helm upgrade`). |
| `--mediator` | When fetching the default token via the API, optional mediator selector (query parameter). |
| `--domain` | API and gateway host base (default `causely.app`); gateway is set to `gw.<domain>`. |
| `--dry-run` | Log the Helm command without executing it. |

Example with several options:

```bash
causely agent install \
  --token <my_token> \
  --namespace causely \
  --repository us-docker.pkg.dev/public-causely/public \
  --tag <version> \
  --cluster-name my-cluster \
  --kube-context my_ctx \
  --values causely-values.yaml
```

## Uninstall

```bash
causely agent uninstall [--namespace causely] [--kube-context <context>]
```

## Next steps

- Customize the deployment: [Customize your installation](https://docs.causely.ai/installation/customize/)
- Connect telemetry: [Telemetry sources](https://docs.causely.ai/telemetry-sources/overview/)
- Push insights into workflows: [Workflows](https://docs.causely.ai/workflows/overview/)

## Developing this CLI

From this directory, with Go installed:

```bash
go build -o causely .
./causely version
```

The built binary’s default chart/image tag may show as `dev` unless you set `-ldflags` at build time to inject a version string.
