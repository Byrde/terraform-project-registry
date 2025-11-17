# Terraform Project Registry

Collection of reusable Terraform project patterns for deploying common applications and services on GCP infrastructure.

## Project Structure
Each project follows a consistent structure:
```
projects/
├── project-name/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars
│   └── README.md
```

## Using Projects from GitHub
Projects in this registry can be sourced directly from GitHub using standard Terraform syntax.

**Basic GitHub Source Syntax:**
```hcl
module "example" {
  source = "github.com/byrde/terraform-project-registry//projects/project-name?ref=v1.0.0"
  # ... project variables
}
```

The `//projects/project-name` syntax specifies the subdirectory path within the repository, and `?ref=` allows you to pin to a specific version, tag, or branch.

## Usage
Example of consuming a project from this registry:

```hcl
module "n8n" {
  source = "github.com/byrde/terraform-project-registry//projects/n8n?ref=v1.0.0"

  project_id = "prj-n8n-example-001"
  region     = "northamerica-northeast1"
  timezone   = "America/Toronto"
  
  # ... additional configuration
}
```

Refer to each project's README for detailed documentation on available variables and outputs.