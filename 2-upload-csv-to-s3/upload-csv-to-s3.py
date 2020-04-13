import boto3
import os
import sys

# absolute path to source directory where files are located
# include trailing slash
# example:
# Directory = "/home/user/files/"
Directory = ""

# s3 destination bucket, can support an optional SubDirectory inside a bucket
# include trailing slash
# example(s):
# Bucket = "BucketName/"
# Bucket = "BucketName/SubDirectory/"
Bucket = ""

# check parameters set
if Directory == "":
    sys.exit("ERROR Directory not set! Edit the input parameter!")

if Bucket == "":
    sys.exit("ERROR Bucket not set! Edit the input parameter!")

# FileType extension to find files
# must be exact; no expressions i.e. Test*.csv won't work
FileType = ".csv"

# initialize s3 client using shared credentials
s3 = boto3.client("s3")

# get list of filenames for all files with filetype
allFiles = [x for x in os.listdir(Directory) if x.endswith(FileType)]
totalFilesFound = len(allFiles)

# upload all files to s3 bucket
numFiles = 0
baseBucket, subBucket = Bucket.split("/", 1)
for filename in allFiles:
    path = Directory + filename
    print("Uploading " + filename + " file from " + path)
    s3.upload_file(path, baseBucket, subBucket + filename)
    numFiles += 1

print("Uploaded " + str(numFiles) + " of " + str(totalFilesFound) + " files found")

