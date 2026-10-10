# terraform-azure

Terraform configuration for provisioning Windows Server VMs (and the supporting
networking) in Azure, built as a reusable module plus environment-specific
configurations.

## Repository layout

```
.
├── modules/
│   └── azure_vm/          # Reusable module: resource group, VNet/subnet, NSG,
│                          # public IPs, NICs, and Windows VMs
└── environments/
    └── azure-dev/         # Dev environment: wires the module up with concrete
                           # variable values and a local state backend
```

### `modules/azure_vm`

Provisions, per role (e.g. `web`, `app`):

- Optionally, a resource group (`create_resource_group`)
- Optionally, a VNet + subnet + NSG with RDP (3389) allowed from a configured
  CIDR **and** from whatever public IP is applying the config (auto-detected
  via `icanhazip.com`)
- A public IP per instance (when `associate_public_ip_address` is true)
- A NIC per instance
- An `azurerm_windows_virtual_machine` per instance, named
  `<site_name>-<environment>-<app_short_name>-<role>-<NN>`

See [modules/azure_vm/variables.tf](modules/azure_vm/variables.tf) and
[modules/azure_vm/outputs.tf](modules/azure_vm/outputs.tf) for the full
input/output contract.

### `environments/azure-dev`

A single environment that calls `modules/azure_vm` with the values in
[environments/azure-dev/terraform.tfvars](environments/azure-dev/terraform.tfvars).
State is stored locally (`backend.tf`) as `terraform.tfstate`.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.3.0`
- An Azure subscription and the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli),
  authenticated via `az login` (the `azurerm` provider uses your CLI/environment
  context — there are no credentials in this repo)

## Secrets

`admin_password` (the local administrator password for the Windows VMs) is
**not** stored in `terraform.tfvars` or committed anywhere in this repo.

Set it locally, before running `plan`/`apply`, using one of:

- A gitignored `secrets.auto.tfvars` file in `environments/azure-dev/`:

  ```hcl
  admin_password = "<your strong password>"
  ```

  Terraform loads any `*.auto.tfvars` file automatically — no extra flags
  needed. This file (along with `secrets.*`, `*.auto.tfvars`, `.env*`, and all
  Terraform state/vars files) is excluded via [.gitignore](.gitignore).

- Or an environment variable, which avoids writing the password to disk at all:

  ```bash
  export TF_VAR_admin_password='<your strong password>'
  ```

Password must be at least 12 characters and should meet Azure's complexity
rules (at least 3 of: uppercase, lowercase, digit, special character).

**Never commit real secrets.** Local Terraform state also stores
`admin_password` in plaintext (this is normal Terraform behavior, not a bug in
this repo) — state files are gitignored, and the files in
`environments/azure-dev/` are `chmod 600` locally. Treat anything under
`environments/*/terraform.tfstate*` as sensitive.

## Usage

```bash
cd environments/azure-dev

# One-time: provider plugins and backend
terraform init

# Review the plan
terraform plan

# Apply
terraform apply
```

Adjust `terraform.tfvars` for non-secret settings (region, network ranges,
VM roles/sizes/counts, tags, etc.) and `allowed_rdp_cidr` for the static RDP
allow rule — the current value is a documentation/placeholder CIDR
(`203.0.113.10/32`, RFC 5737) and should be replaced with a real trusted range
before you rely on it. (RDP access from whoever runs `apply` is already
granted automatically via the "Allow-RDP-From-Home" rule.)

To tear everything down:

```bash
terraform destroy
```

## Adding a new environment

Copy `environments/azure-dev` to a new directory (e.g. `environments/azure-prod`),
update `terraform.tfvars` and `backend.tf` (point `path` at a different state
file, or move to a remote backend), and supply its own `admin_password` via
`secrets.auto.tfvars` or `TF_VAR_admin_password`.
