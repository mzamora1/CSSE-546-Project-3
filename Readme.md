1. Create S3 buckets.
2. Change S3 buckets name in all the python files.
3. Make sure your enviornment have these variables with corresponding values stored.
AWS_ACCESS_KEY_ID="Your access key without quotes"
AWS_SECRET_ACCESS_KEY=B"Your secret access key without quotes"
AWS_DEFAULT_REGION="Your region without quotes"
3. Run "populate_dynamo_db.py" to create and populate table in dunamoDB.
4. Change AWS keys and Region in Dockerfile on these lines.
ARG AWS_ACCESS_KEY_ID="Your access key without quotes"
ARG AWS_SECRET_ACCESS_KEY=B"Your secret access key without quotes"
ARG AWS_DEFAULT_REGION="Your region without quotes"
5. Go to amazon ECR, create a new reposetory and push the docker image to it via push commands goven in the console(you will need to login to aws docker account, you will get the command by simple google search of error).
6. Create a lambda function via docker image in ECR.
7. In general configuration of lambda function, set Timeout to 15 mins. and memory to 2048 MB.
8. Go to Triggers and add a triger to call lambda function on object creation in S3 input bucket.
9. Run "workload.py"
10. After some time, output bucket should have 100 object, check this and then run "checkMapping.py" to validate the outputs.
