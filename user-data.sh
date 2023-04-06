
  #!/bin/bash
  echo DB_USERNAME='${aws_db_instance.rds_cloud_database.username}' >>  /home/ec2-user/webapp/.env
  echo DB_DNAME='${aws_db_instance.rds_cloud_database.db_name}' >>  /home/ec2-user/webapp/.env
  echo DB_PASSWORD='${aws_db_instance.rds_cloud_database.password}'>>  /home/ec2-user/webapp/.env
  echo DB_HOSTNAME='${aws_db_instance.rds_cloud_database.address}'>>  /home/ec2-user/webapp/.env
  echo S3_BUCKETNAME='${aws_s3_bucket.s3Bucket.bucket}'>>  /home/ec2-user/webapp/.env
  echo S