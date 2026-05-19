# LAB-08-B — Cross-Region Disaster Recovery (Terraform)

**Source of truth**: Chapter 08 — `08-backup-dr-pitr.mdx`  
**Supported substrates**: `terraform-aws`, `terraform-gcp`  
**What you'll learn**:
- How to provision a 3-node Patroni cluster in AWS or GCP with Terraform.
- How to configure a cloud storage bucket for pgBackRest backups.
- How the infrastructure layer supports a cross-region DR workflow (bucket replication + multi-region cluster rebuild).

---

## Prerequisites

| Component | Version / Requirement |
|---|---|
| Terraform | >= 1.7 |
| AWS CLI | Latest stable (if using AWS) |
| gcloud CLI | Latest stable (if using GCP) |
| Cloud credentials | IAM permissions to create VPC, EC2/GCE, S3/GCS, IAM roles |

**Estimated cloud cost**: ~$2–4 USD for a 2-hour lab run.

---

## Architecture

```text
+----------------------------------------+    +----------------------------------------+
|  Primary Region (AWS / GCP)            |    |  DR Region (separate Terraform apply)  |
|                                        |    |                                        |
|  node-1 (Leader)                       |    |  dr-node-1 (restored from repo2)       |
|  node-2 (Replica)                      |===>|  dr-node-2 (replica)                   |
|  node-3 (Replica)                      |    |  dr-node-3 (replica)                   |
|                                        |    |                                        |
|  S3 / GCS bucket (repo1)               |===>|  S3 / GCS bucket (repo2)               |
|  pgBackRest archive + base backups     |    |  Cross-region replicated backups       |
+----------------------------------------+    +----------------------------------------+
```

This lab provisions the **primary region** infrastructure. In a full DR drill you would:
1. Run this module in the primary region.
2. Provision an identical module in the DR region with a separate `terraform.tfvars`.
3. Enable bucket replication (AWS S3 CRR or GCP Object Versioning + dual-region).
4. Configure pgBackRest with `repo1` (primary) and `repo2` (DR).

---

## Files

| File | Purpose |
|---|---|
| `main.tf` | Top-level entry point; delegates to `modules/aws` or `modules/gcp` |
| `variables.tf` | Provider selection, region, instance type, key/SSH vars |
| `outputs.tf` | Cluster node IPs, backup bucket name |
| `modules/aws/main.tf` | AWS VPC, subnet, IGW, security group, 3x EC2, S3 bucket |
| `modules/gcp/main.tf` | GCP VPC, subnet, firewall rules, 3x GCE, Cloud Storage bucket |
| `Makefile` | `setup`, `validate`, `teardown` |
| `.env.example` | Template for cloud credentials (never commit real keys) |

---

## Quick Start

### 1. Prerequisites

**AWS**:
- Ensure the AWS CLI is configured (`aws configure` or env vars).
- Create or import an EC2 key pair in your target region.

**GCP**:
- Ensure `gcloud auth application-default login` is run.
- Have an SSH key pair ready (`ssh-keygen -t rsa -f ~/.ssh/lab-08-b -C ubuntu`).

### 2. Provider Selection

Create `terraform.tfvars` in this directory:

**AWS example** (`terraform.tfvars`):

```hcl
provider      = "aws"
region        = "us-east-1"
instance_type = "t3.medium"
key_name      = "my-ec2-keypair"
cluster_name  = "lab-08-b-primary"
```

**GCP example** (`terraform.tfvars`):

```hcl
provider      = "gcp"
region        = "us-central1"
zone          = "us-central1-a"
instance_type = "e2-medium"
ssh_key       = "ssh-rsa AAAAB3... ubuntu"
cluster_name  = "lab-08-b-primary"
```

> **Security**: Never commit `terraform.tfvars` to git. It is listed in `.gitignore` by convention.

### 3. Validate

```bash
make validate
```

Runs `terraform validate` and `terraform plan` so you can review the resources before creation.

### 4. Deploy

```bash
make setup
```

Runs `terraform init` and `terraform apply`. You will be prompted to confirm before any resources are created.

After apply completes, note the outputs:

```bash
terraform output
# cluster_endpoints    = ["3.91.123.45", "54.175.67.89", ...]
# backup_bucket_name = "lab-08-b-primary-backups-7a3f2b1c"
```

### 5. Configure pgBackRest (on the provisioned nodes)

Once the instances are running, SSH into `node-1` and install/configure Patroni + pgBackRest. The Terraform layer only provisions the **infrastructure**; the Patroni cluster is configured with Ansible or cloud-init in a subsequent step.

Example `/etc/pgbackrest/pgbackrest.conf` for a primary-region node:

```ini
[global]
repo1-type=s3
repo1-s3-bucket=<backup_bucket_name from terraform output>
repo1-s3-region=us-east-1
repo1-s3-endpoint=s3.amazonaws.com
repo1-cipher-type=aes-256-cbc
repo1-retention-full=4
repo1-retention-full-type=count

[main]
pg1-path=/var/lib/postgresql/16/main
pg1-port=5432
pg1-user=postgres
```

For a cross-region DR configuration (Chapter 08), add `repo2` pointing to the DR-region bucket:

```ini
repo2-type=s3
repo2-s3-bucket=<dr_backup_bucket>
repo2-s3-region=us-west-2
repo2-cipher-type=aes-256-cbc
```

### 6. Teardown

```bash
make teardown
```

Runs `terraform destroy` and removes all provisioned resources. You will be prompted to confirm.

> **Warning**: S3/GCS buckets are created with `force_destroy = true` so the destroy succeeds even if objects exist. Do **not** use `force_destroy = true` in production.

---

## Manual Commands (without Make)

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
terraform destroy -var-file="terraform.tfvars"
```

---

## Extending to Cross-Region DR

This module deploys a single-region cluster. To practice the full LAB-08-B workflow from Chapter 08:

1. **Provision primary**: Run this module with `cluster_name = "lab-08-b-primary"`.
2. **Provision DR**: Copy `terraform.tfvars`, change `region` to your DR region (e.g., `us-west-2`), and set `cluster_name = "lab-08-b-dr"`. Run `terraform apply` in a separate workspace.
3. **Enable bucket replication**: Use the AWS `aws_s3_bucket_replication_configuration` or GCP dual-region bucket to sync backups.
4. **Simulate outage**: Terminate primary-region instances (see Chapter 08 "Break It on Purpose").
5. **Activate DR**: Restore from `repo2` on the DR primary node and reinitialize replicas.

---

## What This Tells You About Production

- **Infrastructure as code**: All VPC, subnet, firewall, and IAM rules are explicit in Terraform. Review every `ingress` block during peer review — a misconfigured security group can expose PostgreSQL to the internet.
- **State file hygiene**: Use a remote backend (S3 + DynamoDB for AWS, GCS for GCP) for Terraform state. Local state files are fine for this lab but are a single point of failure in production.
- **Force destroy**: The `force_destroy = true` flag on buckets makes teardown painless for a lab. In production, remove this flag and use lifecycle policies to transition backups to cheaper storage classes before manual deletion.
