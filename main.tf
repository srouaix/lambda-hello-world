


data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = var.vpc_tags
  }
}

data "aws_subnets" "this" {
  filter {
    name = "vpc-id"
    values = [
      data.aws_vpc.this.id
    ]
  }
  tags = { "network:subnet:type" = "private" }
}

resource "aws_security_group" "aws_security_group_lambda" {
  name        = "lambda-sgp-test"
  description = "Lambda sgp"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "aws_vpc_security_group_ingress_rule_lambda" {
  security_group_id            = aws_security_group.aws_security_group_lambda.id
  referenced_security_group_id = aws_security_group.aws_security_group_lambda.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "aws_vpc_security_group_egress_rule_lambda" {
  security_group_id = aws_security_group.aws_security_group_lambda.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lambda_function" "test_lambda" {
  filename         = var.source_path_zip_file
  source_code_hash = try(filebase64sha256(var.source_path_zip_file), false)
  function_name    = "test_lambda"
  role             = "${aws_iam_role.iam_for_lambda_tf.arn}"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
    
  vpc_config {
    security_group_ids = [aws_security_group.aws_security_group_lambda.id]
    subnet_ids         = data.aws_subnets.this.ids

  }
}

resource "aws_iam_role" "iam_for_lambda_tf" {
  name = "iam_for_lambda_tf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
    role       = aws_iam_role.iam_for_lambda_tf.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
