# This is the bucket used to save the backed up data, you could also use it to store the terraform state file 
resource "aws_s3_bucket" "Migrate_s3" {
  bucket = "${var.S3_Bucket_Name}"

  tags = {
    Name        = "var.S3_Bucket_Name"
    Environment = "Production"
  }
}

resource "aws_secretsmanager_secret" "EC2_Secret" {
  name = "WindowsPwd"
}

resource "aws_iam_role" "Migration_Instance_Role" {
  name = "Migration_Instance_Role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMPatchAssociation", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })


  inline_policy {
    name = "S3AccessPolicy"
  
 policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.S3_Bucket_Name}",
                "arn:aws:s3:::${var.S3_Bucket_Name}/*"
            ]
        }
    ]
}
EOF
  }


  tags = {
    tag-key = "Instance_Profile_policy"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "Migration_Instance_Profile"
  role = aws_iam_role.Migration_Instance_Role.name
}

resource "aws_secretsmanager_secret" "name" {
  
}