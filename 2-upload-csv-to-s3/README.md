# Upload CSV to S3
This python script will upload th CSV files generated in the [first step](/1-generate-csv/)

## How to Use
1. Setup user permissions in IAM
   1. New user link
   1. Custom Policy json code
   1. Set default shared credentials link
1. Install boto3 link
1. Set input parameters for directory (see below)
1. Run (or schedule) after CSV files are generated

### Input Parameters
* Directory
* Bucket
* FileType
