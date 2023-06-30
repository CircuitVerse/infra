# Running ActiveStorage on AWS S3

### Configuring Credentials

Add credentials of `circuitverse-images-dev` to your enviornment(either in shell profile or in .env file)

NOTE: If you are using your own S3 bucket for development, you need to edit `region` and `bucket` field in 
[config/storage.yml](https://github.com/CircuitVerse/CircuitVerse/blob/master/config/storage.yml)

```bash
export AWS_S3_DEV_ACCESS_KEY_ID=""
export AWS_S3_DEV_SECRET_ACCESS_KEY=""
```

Alternativly these can also be added to the shell profile:

```bash
vim ~/.bashrc 
# Add export statements in .bashrc
source ~/.bashrc

vim ~/.zshrc
# Add export statements in .zshrc
source ~/.zshrc
```

#### Interacting with S3 bucket using aws cli

Set up AWS credentials, Access key and secret access key.

```bash
aws configure
```

Listing Objects in bucket:

```bash
aws s3 ls s3://circuitverse-images-dev
```

Removing Objects from bucket
```bash
aws s3 rm s3://circuitverse-images-dev/<filename>
# example - /keyname
aws s3 rm s3://circuitverse-images-dev/1orgi1an1hgp3es4nx8x5nf7hrjl
```

For more cli commands refer official AWS docs [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3-commands.html#using-s3-commands-listing-buckets)

