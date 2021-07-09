# Configuration oriented Terraform code

This article demonstrates an opinionated pattern for organizing Terraform code.
The pattern follows the principles listed in the initial article of this series.

Before reading this article, it may be useful to familiarize yourself with how the Terraform documentation suggests we organize our code:

- https://learn.hashicorp.com/tutorials/terraform/organize-configuration
- https://www.hashicorp.com/blog/structuring-hashicorp-terraform-configuration-for-production



### Directory structure
If we want to create a Terraform project with some home-made modules, across two environments (`dev` and `prod`), the directory layout would look something like this:

```
└── my-project
    ├── live
    │   ├── dev
    │   │   ├── modules.tf
    │   │   ├── providers.tf
    │   │   └── terraform.tf
    │   └── prod
    │       ├── modules.tf
    │       ├── providers.tf
    │       └── terraform.tf
    └── modules
        ├── module-a
        │   └── main.tf
        └── module-b
            └── main.tf
```
Each `modules.tf` file would look something like this:

```
# ./live/*/modules.tf

module "a" {
  source  = "../../modules/module-a"
  
  var1 = <some input value>
  var2 = <some input value>
  var3 = <some input value>
}

module "b" {
  source  = "../../modules/module-b"
  
  var1 = <some input value>
  var2 = <some input value>
  var3 = <some input value>
}
```

### Passing input values

At this point, we need a strategy for forwarding input values, hereby referred to as *configuration*, into these module blocks.

###### Option 1: Add configuration directly to `modules.tf`
The simplest approach would be to replace `<some input value>`, and just hardcode the desired configuration straight into the `modules.tf` files.
This has several drawbacks, some notable examples being:
- You can't reuse a single input value across multiple modules.
- If there are a lot of modules, you'll want to spread them across multiple `*.tf` files; your configuration ends up scattered.
- You can't copy + paste `modules.tf` between `live/dev` and `live/prod`, so implementing change in both environments becomes a bit fiddly.

###### Option 2: Terraform module variables
The textbook approach would be to use `variable` blocks.
In my opinion, this should only be necessary in the child modules (`./modules/*/variables.tf`), not in the root modules (`./live/*/variables.tf`).
The reason I don't like this approach is that you have to declare every input value in the root module:
```
# ./modules/module-a/variables.tf

variable "var1" {
  type = string
  description = "Input for something something cloud.."
  default = "whatever"
}
```
```
# ./live/*/modules.tf

module "a" {
  source = "../../modules/module-a"

  # Without this line, the active value will be "whatever"
  var1 = var.var1 
}
```
```
# ./live/*/variables.tf

variable "var1" {
  type = string
  description = "Used with module.a, but not necessarily module.b"
  default = "derp"
}
```
```
#./live/*/config.auto.tfvars

# Without this line, the active value will be either "derp" or "whatever"
var1 = "cauliflower" 
```
The example above involves seven files across `dev` and `prod`.
Each of the files displayed above represent a place where the active value for `module.a` might be defined.
When somebody is trying to figure out how some resource in `prod` is configured, that person might have to traverse four files to find the active value.
This can be alleviated with good and consistent Terraform coding style, but I feel that there is too much potential for confusion.

###### Option 3: Use locals
Terraform comes with [local values](https://www.terraform.io/docs/language/values/locals.html), and a nice set of functions for decoding common file structures, like YAML and JSON.
In other words, it's possible to do this:

```
# ./live/*/config.yaml

module-a:
  var1: "x"
  var2: "y"
  var3: "z"

module-b:
  var1: "a"
  var2: "b"
  var3: "c"
```
```
# ./live/*/locals.tf

locals {
  config = yamldecode(file("./config.yaml")) 
}
```
```
# ./live/*/modules.tf

module "a" {
  source  = "../../modules/module-a"
  
  var1 = local.config.module-a.var1
  var2 = local.config.module-a.var2
  var3 = local.config.module-a.var2
}

module "b" {
  source  = "../../modules/module-b"
  
  var1 = local.config.module-b.var1
  var2 = local.config.module-b.var2
  var3 = local.config.module-b.var3
}
```
The most significant difference between Options 2 and 3, is that there is no need for the `./live/*/variables.tf` files.
They are replaced with `./live/*/locals.tf`, and unlike the `variables.tf` files, these do not need to be modified when you define new values in `config.yaml`.
This is an enormous advantage.
Picture what the `./live/*/variables.tf` files from Option 2 would look like if we added all six input varibles for `module.a` and `module.b`; that's a lot of code.
With the Option 3 pattern, we no longer need to declare root level variables, anything you declare in `config.yaml` will automatically be available under the `local.config` map.

At the time of writing, my preferred approach is to combine Option 1 and Option 3. 
If a value will vary between environments, or if it is important with respect to understanding what the code does, it ends up in `config.yaml`.
Values that will not vary between environments, and that are unlikely to change over time, get hardcoded straight into the `module` blocks.

> It is important to note that Option 3 should only be employed in the root modules (`./live/*`), not in the child modules (`./modules/*`).

### YAML vs. HCL
Option 3 can easily be accomplished with the HCL file format instead of YAML.
We just prefer YAML because it is easier to read (and write).

One of the core ideas behind this pattern is that the configuration should be the most informative file within an environment directory.
Using YAML makes this file easier to interpret, and the project becomes more accessible to developers who are not familiar with HCL.

### Practical example
In this section we will walk through the process of writing a configuration oriented Terraform project covering multiple environments.

##### The task
Create a Terraform structure for Google Cloud Platform that provisions service accounts, and assigns them IAM roles.
There should be two environments `dev` and `prod`.
Assume that the Google Cloud Projects for these environments, `dev-project` and `prod-project` already exist.
It should be possible to assign IAM roles at the project level, and for storage buckets.
Furthermore, it should be possible to assign IAM roles for any GCP project, and any storage bucket.
The service accounts will live in `dev-project` and `prod-project`, but should be granted some IAM roles in another pre-existing project; `shared-project`.

##### The approach
I always start with the directory layout and the `config.yaml` files.
I focus on `dev`, and write my code in a way where most of the files can be copy + pasted into `prod`.
We will use the same directory layout illustrated earlier.
When writing your `config.yaml` file; ask yourself what the most intuitive structure would look like.
For this particular problem, I would want `config.yaml` to look something like this:
```
# ./live/dev/config.yaml

gcpProvider: 
  project: dev-project
  region: europe-west1

# Create service accounts in `dev-project`, and assign IAM roles
serviceAccounts:

  - name: sa-number-one
    iam:
      # Assign `sa-number-one` project-level IAM roles in `dev-project`
      - type: project
        name: dev-project
        roles: 
          - roles/storage.admin
          - roles/secretmanager.admin

  - name: sa-number-two
    iam:
      # Assign `sa-number-two` project-level IAM roles in `shared-project`
      - type: project
        name: shared-project
        roles:
          - roles/storage.objectViewer
    
      # Assign `sa-number-two` bucket-level IAM roles to a Google Container Registry in `shared-project`
      - type: bucket
        name: eu.artifacts.shared-project.appspot.com
        roles:
          -  roles/storage.admin

```
This YAML layout gives me a foundation to build on.
The goal is to end up with a strucure where service accounts and IAM roles can be created, destroyed or modified through the `config.yaml` file.

The next step would be to write the root and child modules.
The child modules will just contain normal Terraform code, while the root module will have to contain some imperative logic that translates my YAML into the input values expected by the child modules.

Please refer to [https://github.com/bulderbank/blog/attachments/terraform-yaml-example/](https://github.com/bulderbank/blog/attachments/terraform-yaml-example/) for a complete example based on the YAML configuration depicted above.

Some notes on the example:

- Every file except for `config.yaml` is identical between `dev` and `prod`, so it's easy to copy + paste. Usually, `terraform.tf` will also differ because the environments have different remote state storage locations.
- All `resource` blocks are contained within modules, even though the modules are very simple. We do this because it is arguably cleaner than putting `resource` blocks directly into the `./live/*` directories (try running `terraform state list`).
- The `for` loops are difficult to understand, but one never has to modify them unless there is a need to modify the structure of `config.yaml`; developers will seldom be interested in these loops in the long-term.
