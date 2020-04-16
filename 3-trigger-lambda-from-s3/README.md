# Trigger Lambda from S3
This code and setup will copy the CSV from S3 into your Redshift cluster.  You need to already have a cluster [setup](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/event-publishing-redshift-cluster.html).  When setting up the cluster or if it's already setup make sure the role you attached it has permissions to access S3.  See *custom-redshift-policy.json* in the *policies* folder for the setup.

## How to Use
1. Run the **setup-redshift-import.sql** script in your Redshift cluster.  This will create the necessary tables and stored procedures used by the Python Lambda function:
* **indicator_staging** - table used to stage CSV before inserting into the result table
* **indicator_result** - table that holds the final processed rows
* **process_staging** - stored procedure that imports new records from indicator_staging
* **delete_processed** - stored procedure that removes rows from indicator_staging that are already processed
* **calculate_wins** - (default) stored procedure to determine if a long or short signal has "won" (more details in the [next step](https://github.com/timsgrignoli/forex-technical-indicators/tree/master/4-calculate-wins))
2. Create a [new user](https://docs.aws.amazon.com/redshift/latest/dg/t_adding_redshift_user_cmd.html) with full access to indicator_staging and execute permissions on the 3 stored procedures
3. Create a new Lambda function in the same region as your Redshift cluster and S3 bucket.  Under *Choose or create an execution role* choose *Create a new role with basic Lambda permissions* we'll add permissions later.
4. Download the *src* folder and zip it up (*psycopg2* is necessary to communicate to Redshift using python).  Upload the zip to Lambda in the **Function code** section by changing *Code entry type* to *Upload a .zip file* (see below).  Also, make sure the Handler matches. ![Lambda Setup](/images/lambda-zip-handler.png)
5. Change values at the top of the **import-csv-from-s3.py**
* **iam_role** - role attached to Redshift database
* **db_database** - database name
* **db_user** - user created above
* **db_password** - password for user above
* **db_port** - default 5439 or change for custom setup
* **db_host** - host of cluster

*For more help on connection string values look [here](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/event-publishing-redshift-cluster-connect.html).*

6. Edit **Basic Setting** change *Timeout* to at least 3 minutes (this may need to be adjusted based on the size of your loads).  At the very bottom click *View the nameOfYourFunction-role-kjkscd role* to bring up in IAM console.  Attach Policy *AWSLambdaExecute* which allows the function access to logs and S3 for the event triggered.  Then create a policy to allow to connect to Redshift see *custom-lambda-policy.json* in the *policies* folder.
7. Click **Add trigger**.  Select S3, select the **Bucket**, choose *All object create events* for **Event type**, enter **Prefix** or **Suffix** (if applicable).
