# Upload CSV to S3
The python script **upload-csv-to-s3.py** will upload th CSV files generated in the [first step](/1-generate-csv/)

## How to Use
1. To follow Principle of Least Privilege, create a new user responsible only for the uploads to a specific S3 bucket
   1. Create a [new user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) in your AWS account with programmatic access
   1. The file **custom-upload-policy.json** can be used to create a custom policy that only allows this user to upload (PutObject) to a specific **BucketName**
   Click [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html) for more info on creating custom IAM policies
   1. Update the shared **credentials** file with the aws_access_key_id and aws_secret_access_key of the newly created user
   Click [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) for more information on using the shared credential file
1. Install Boto3 [here](https://github.com/boto/boto3) for python
1. Edit **upload-csv-to-s3.py** to set parameters for **Directory** and **Bucket** before running (see below)
1. Run (or schedule) script after CSV files are generated

### Input Parameters
* Directory
* Bucket
* FileType
