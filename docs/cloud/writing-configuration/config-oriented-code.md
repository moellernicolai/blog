# Configuration oriented code

If we want to provision Virtual Machines in the cloud, we just communicate this desire to our cloud providers.
If we want to deploy some app, we just communicate this desire to our clusters.
DevOps people are generally expected to declare *'what'* they want, while the imperative *'how'* aspect often gets abstracted away by other peoples' software.

## Time forgets

![https://abstrusegoose.com/432](https://abstrusegoose.com/strips/you_down_wit_OPC-yeah_you_know_me.png)

I think the image above will resonate with most developers, and it's not an experience limited to *other* peoples' code.
Understanding what's actually happening within some repository requires a lot of cognitive calories.
Being configuration oriented is all about making declarative code easier to understand.
Taking a configuration oriented approach means centralizing the most important declarative information, and presenting it in a way that's easy to read.
If we do this well, we are left with something that almost feels like documentation.
Functional documentation.
Documentation that dictates what happens when the code is executed.

Sounds like a lot of work.
But then again, writing and maintaining code *is* a lot of work.
The effort you exert toward being configuration oriented should be thought of as an investment.
You do some extra work upfront, and if you pull it off, you'll save yourself a lot of trouble in the future.
To better understand this, we will categorize the process of writing code into two *phases*; the *initial phase*, and the *long-term*.

## The initial phase, and the long-term
At no point in time will you understand your own code better than the moment you wrote it.
We will refer to this moment, and the moments immediately following, as the initial phase.
In this phase, you are bootstrapping your repository, writing code, solving problems, and doing what you do.
A common mistake developers make during the initial phase is to overestimate their own memory.
If you write code that relies memory to be understood, you will manifest the scenario illustrated above.
I would therefore argue that it is wise to focus on the long-term during the initial phase of writing code.

In the long-term, there are two reasons why you might revisit the code you wrote in the initial phase; to understand what's happening, or to modify what's happening.
Writing code for the long term means that we strive to make things *easy* to understand, and *easy* to modify; simply writing code that works is not sufficient.

## Configuration oriented principles
One of the central ideas behind what I refer to as being configuration oriented, is to minimize the number of files developers are likely to interact with in the long-term.
Ideally, configuration oriented code should have one configuration file per environment (eg. `prod.yaml`, `dev.yaml`, etc.).
These files should be structured in a way that maximises how informative they are from the perspective of a developer who has no idea what the code actually does.
The way we accomplish this in the Cloud team at Bulder Bank, is to write our configuration as YAML files, and prioritize readability.
We can choose any structure we want, the price we pay is that the configuration must be imparatively parsed (or translated if you will) into the input formats expected by whatever tool we are working with.
Long story short, being configuration oriented means that we allow extra complexity into our code for the sake of an eye-friendly configuration file.
Writing code during the initial phase becomes more difficult, while managing that code in the long term becomes a whole lot easier.

### Plan for the future, anticipate change
During the initial phase, the developer must continually question what modifications people are likely to need in the future.
For example, if we're dealing with a Terraform repository for assigning IAM roles to users, people will likely want to add new IAM rules over time.
In that case, the Terraform code should be structured in a way where this can be accomplished by simply updating the configuration; it should not be necessary to modify the underlying Terraform code (the `for_each` loop is your friend).

Planning for the future is tricky.
A common trap is to overthink it, and spend far too much time implementing configuration-driven features that nobody will ever use.
Experience, and a solid understanding of the underlying problem is as crucial as ever when anticipating future demands on some code repository.

### Minimize the number of files you're likely to care about in the long term
Experienced DevOps people will agree that the complexity of Infrastructure as Code projects skyrocket when you introduce the requirement for multiple environments.
For example, if you are required to maintain a production environment, a staging environment, and a development environment, the initial phase of writing code becomes a lot more challanging, regardless of your approach.
This seems to be a fundamental problem within Infrastructure as Code, and it seems like every DevOps team has their own unique approach to solving the problem.
From a configuration oriented point of view, this problem should be solved by isolating differences into environment's respective configuration files.
Each environment gets its own configuration, while the code that consumes this configuration should be as environmentally agnostic as possible.

Anyone who has tried to implement this kind of pattern will appreciate that it's a difficult thing to accomplish.
Part of the reason why this is so difficult, is that there are countless ways to approach the problem, and not a whole lot of non-trivial online examples to learn from.
Nevertheless, it is a worthwhile problem to solve as it  simplifies long-term code interaction, and makes pull requests a lot more concise.

### Make configuration files as informative as possible
Consider the following examples for Terraform input values. 
Which do you find more intuitive, and which do you think would fare better if we added hundreds of additional lines in the same format:

###### Example 1
```yaml
# ./config.yaml

iam:
  - email: friend@org.com
    membership:
      - role: roles/compute.viewer
        project: project-b

  - email: buddy@org.com
    membership:
      - role: roles/container.viewer
        project: project-a

  - email: guy@org.com
    membership:
      - role: roles/dns.admin
        project: project-a
      - role: roles/storage.admin
        project: project-b
```

###### Example 2
```bash
# ./iam.tfvars

friend_email = "friend@org.com"
friend_role_1 = "roles/compute.viewer"
friend_project_1 = "project-b"

buddy_email = "buddy@org.com"
buddy_role_1 = "roles/container.viewer"
buddy_project_1 = "project-a"

guy_email  = "guy@org.com"
guy_role_1 = "roles/dns.admin"
guy_project_1 = "project-a"
guy_role_2 = "roles/storage.admin"
guy_project_2 = "project-b"
```

Some subjective observations on the above:

- Example 1 is more readable (assuming the reader has seen YAML before).
- Example 1 is more difficult to transform into a format that Terraform understands.
- Example 2 makes the initial phase a lot less complicated.

In my opinion, Example 1 prioritizes the long-term in a configuration oriented fashion, while Example 2 prioritizes simplicity in the initial phase.
Example 1 is a configuration oriented approach, Example 2 is not.

If you feel that Example 1 is no more readable than Example 2, my bet is that you would feel differently if we threw a bunch of other resources types into the mix.
You may also be wondering why I use YAML instead of HCL in Example 1.
If either of these apply to you, please refer to the subsequent article in this series, *Configuration oriented Terraform code*.

### Parse the configuration imperatively when needed
Configuration oriented approaches usually require custom imperative logic.
This is to be expected; it's the main reason why the initial phase of development becomes more challenging when adopting a configuration oriented approach.

To illustrate, lets build on the Terraform examples:
Assume you have some module that creates IAM rules based on input values from your configuration file.
We'll start with Example 2, as this will be more familiar to most Terraform users.

```bash
# Example 2 approach
# ./iam.tf

variable "friend_email" {}
variable "friend_project_1" {}
variable "friend_role_1" {}
variable "friend_project_2" {}
variable "friend_role_2" {}
# etc...

module "iam_friend_1" {
  source  = "/path/to/module/"

  email   = var.friend_email
  project = var.friend_project_1
  role    = var.friend_role_1 
}

module "iam_friend_2" {
  source  = "/path/to/module/"

  email   = var.buddy_email
  project = var.buddy_project_1
  role    = var.buddy_role_1 
}

# etc...
```

This is not a good approach, yet this is probably how most beginners write their first lines of Terraform code. 
It is the simplest way to get the job done, and there are plenty of scenarios where it's fine to keep things simple.

The problem with this approach it lacks readability, and it doesn't scale well.
You would have to modify a lot of code, across multiple files, to make simple adjustments (eg. removing an existing IAM role), and understanding what the code does becomes more tedious than it needs to be.

For a configuration oriented approach using the input values from Example 1, we need to put some imperative logic inside a `locals` block to translate our YAML into something Terraform understands.
The code might look a bit daunting, but you will rarely need to concern yourself with this imperative logic in the long term.
Once you've figured out how to wrangle your configuration into a suitable format, you will never need to revisit the `locals` block unless you decide to change the structure of your `config.yaml` file.

```bash
# Example 1 approach
# ./iam.tf

locals {
  # Make `config.yaml` available to Terraform
  config = yamldecode(file("./config.yaml"))

  # Convert `local.config.iam` into a `for_each` map:
  # {
  #   <project>-<role>-<email> = {
  #     email   = <email>
  #     project = <project>
  #     role    = <role>
  #   }
  # }
  iam = {
    for rule in flatten([
      for person in local.config.iam : [
        for roles in person.membership : {
          email   = person.email
          role    = roles.role
          project = roles.project
        }
      ]
    ]) : join("-", [rule.project, rule.role, rule.email]) => rule
  }
}

module "iam" {
  source   = "/path/to/module/"
  for_each = local.iam

  email    = each.value.email
  project  = each.value.project
  role     = each.value.role
}
```

Loops in Terraform v1.0 leave a lot to desired, but but the ability to manipulate the structure of input values is invaluable.
Notice the trade-off eluded to earlier, between configuration readability and the complexity of the `for_each` loop.

# Concluding remarks
Like most things in DevOps, there is no single *best* solution for organizing declarative code.
Putting emphasis on configuration is just another style; I hope that some of you will find it helpful.
