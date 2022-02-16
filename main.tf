# ---------------------------------------------------------------------------------------------------------------------
# Firewall Policy
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_networkfirewall_firewall_policy" "anfw_policy" {
  name = "anfw-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow_domains.arn
    }

  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Firewall (Stateful) Rule Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "allow_domains" {
  capacity = 100
  name     = "allow-domains"
  type     = "STATEFUL"

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [
            aws_vpc.protected_vpc_a.cidr_block,
            aws_vpc.protected_vpc_b.cidr_block
          ]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".amazon.com", ".aviatrix.com"]
      }
    }
  }

}