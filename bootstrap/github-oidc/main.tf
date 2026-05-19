resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

resource "aws_iam_role" "github_terraform" {
  name               = "github-terraform-secure-platform-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}
