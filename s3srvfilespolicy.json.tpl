{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "${sid}",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "${s3_arn}/*"
      ]
    }
  ]
}