locals {
  config = yamldecode(file("./config.yaml"))

  # Transform YAML format into `for_each` friendly map
  iam = {
    for x in flatten([
      for sa in local.config.serviceAccounts : [
        for rule in sa.iam : [
          for role in rule.roles : {
            "sa"   = sa.name
            "type" = rule.type
            "name" = rule.name
            "role" = role
          }
        ]
      ]
    ]) : join("-", [x.sa, x.name, x.role]) => x
  }
}

