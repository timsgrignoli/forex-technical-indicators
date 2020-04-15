from __future__ import print_function

import urllib
import psycopg2

iam_role = ""
db_database = ""
db_user = ""
db_password = ""
db_port = ""
db_host = ""


def handler(event, context):

	# get bucket name and object name (key)
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.unquote_plus(event['Records'][0]['s3']['object']['key'].encode('utf8'))

	# connect to Redshift
    try:
        conn = psycopg2.connect("dbname='" + db_database + "' user='" + db_user + "' password='" + db_password + "' port='" + db_port + "' host='" + db_host + "'")
        conn.autocommit = True
    except Exception as e:
        print("Error connecting to database")
        raise e

	# run SQL
    try:
        cursor = conn.cursor()

		# check file wasn't already processed to make idempotent
        print("Check file imported for {}/{}".format(bucket, key))
        if already_uploaded_query(bucket, key, cursor):
            return "Already imported! {}/{}".format(bucket, key)

		# start copy command from S3 bucket
        print("start copy for {}/{}".format(bucket, key))
        copy_to_redshift(bucket, key, cursor)
        print("finished copy for {}/{}".format(bucket, key))

        # import staging to result table
        print("start process staging")
        process_staging(cursor)
        print("finished process staging")

        # delete processed rows from staging table
        print("start delete processed")
        delete_processed(cursor)
        print("finished delete processed")

        # run calculate wins for result
        print("start calculate wins")
        calculate_wins(cursor)
        print("finished calculate wins")

		# close database
        cursor.close()
        conn.commit()
        conn.close()
        return "Success for {}/{}".format(bucket, key)
    except Exception as e:
        print("Error executing SQL")
        raise e

def already_uploaded_query(bucket, key, cur):
    query = "select count(1) as total from stl_load_commits where filename = 's3://{}/{}';".format(bucket, key)
    cur.execute(query)
    count = cur.fetchone()
    return count[0] > 0

def copy_to_redshift(bucket, key, cur):
    query = "copy indicator_staging from 's3://{}/{}' credentials 'aws_iam_role={}' csv;".format(bucket, key, iam_role)
    cur.execute(query)

def process_staging(cur):
    query = "call process_staging();"
    cur.execute(query)

def delete_processed(cur):
    query = "call delete_processed();"
    cur.execute(query)

def calculate_wins(cur):
    query = "call calculate_wins();"
    cur.execute(query)