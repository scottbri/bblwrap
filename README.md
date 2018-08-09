# bblwrap.sh
bblwrap is a human interactive wrapper script for the Bosh Boot Loader (aka: bbl).  
Since `bbl` is pronounced *("bubble")*, welcome to *("bubble wrap")*

`bblwrap.sh` currently supports GCP, Microsoft Azure, and is stubbed but as yet nonfunctional for AWS, and vSphere.

## Docs 
To really know what's going on, first head over to the [bosh-bootloader](https://github.com/cloudfoundry/bosh-bootloader) github repo and explore what exactly bbl is attempting to achieve.

To get complete novices up to speed quicker, and to enable lazy Pivots to not have to think too much, `bblwrap.sh` was created to guide the user in the setup of `bbl` which in turn eases the deployment of BOSH.

Be a bit careful with `bblwrap.sh`.  It will reach out and interrogate your IAAS to determine the proper environment variables and credentials needed for a successful `bbl up`.  It will automatically create service accounts and set permissions needed for a successful `bbl up`.

In short, `bblwrap.sh` will make changes on your targeted IAAS environment, but it'll try to be nice while doing so.  You take all responsibility for knowing how this relatively simple script works!  No warranty is provided or implied by me.  

## Prerequisites

### Install Dependencies

A convenient helper script `check-installed-tools.sh` is provided that will look for dependencies and guide you to installing them.
- [yq](https://github.com/mikefarah/yq)
- [jq](https://github.com/stedolan/jq)
- [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)
- [gcloud cli](https://cloud.google.com/sdk/docs/quickstarts)
- [bbl](https://github.com/cloudfoundry/bosh-bootloader/releases)
- [bosh-cli](https://bosh.io/docs/cli-v2.html)
- [bosh create-env dependencies](https://bosh.io/docs/cli-env-deps.html)
- [terraform](https://www.terraform.io/downloads.html) >= 0.11.0
- ruby (necessary for bosh create-env)

### Install bblwrap by cloning this repo

```sh
$ git clone https://github.com/scottbri/bblwrap
```

## Usage

```sh
$ git clone https://github.com/scottbri/bblwrap
$ cd bblwrap
$ ./check-installed-tools.sh 		# remediate any dependencies you see
$ ./bblwrap.sh				# follow the prompts
```

## What to do next
Now your IAAS should have proper credentials set and you should be ready to use bbl to create a bosh environment.

### What you should do now
```sh
source $BBL_ENVIRONMENT_VARS		# to enable bbl with the required environment vars
bbl -h					# familiarize yourself with bbl generally
bbl plan -h				# familiarize yourself with the bbl plan command line options
bbl up -h				# familiarize yourself with the bbl up command line options
bbl plan --lb-type concourse --debug	# this will create lots of structures in $BBL_STATE_DIRECTORY
```
After executing bbl plan, now you can go into '$BBL_STATE_DIRECTORY` and make edits and customizations. This bosh boot loader [documentation](https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/customization.md) provides good insights on what can be changed.
```sh
bbl up --lb-type concourse --debug	# this will execute the plan with customizations on your IAAS
```


In the future, after you bbl up a new environment, you should have a functional BOSH environment
including a jumpbox and credhub.

### What you should do after bbl up
In case you lose your environment variables, execute these commands to get them back
```sh
export $BBL_STATE_DIRECTORY=<path to your bblwrap/state/<IAAS>/<ENV-NAME>/> folder"
source $BBL_STATE_DIRECTORY/*-ENV-VARS.sh	# to enable bbl with the required environment vars
eval "$(bbl print-env)"			# this will enable the bosh command with required env vars

bosh alias-env $BBL_IAAS-$BBL_ENV_NAME	# this will create a bosh environment alias for future use
bosh -e $BBL_IAAS-$BBL_ENV_NAME log-in	# this will test your login ability to this bosh environment
bbl ssh --jumpbox			# this is how to ssh into the jumpbox in your bosh environment
bbl ssh --director			# this is how to ssh into the bosh director

# The following is how to create an SSH tunnel through the jumpbox to credhub
bbl ssh-key > /tmp/jumpbox.key
chmod 0700 /tmp/jumpbox.key
ssh -4 -D 5000 -fNC jumpbox@`bbl jumpbox-address` -i /tmp/jumpbox.key
export http_proxy=socks5://localhost:5000
credhub login
credhub find -n \'cf_admin_password\'	# you might not have cf installed in this example query
```

Don't forget to upload stemcells suitable for any deployments you're considering.
The list of available stemcells is here:  https://bosh.cloudfoundry.org/stemcells/

Uploading stemcells looks like the following (this version may not be suitable for your deployment):
```sh
bosh upload-stemcell --sha1 7fec9feec30ce85784b8c0a2de465379a5882e8f \
      https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-trusty-go_agent?v=3586.27

bosh upload-stemcell --sha1 c32675c378994b86c7122a79466074e7a0bac434 \
    https://bosh.io/d/stemcells/bosh-azure-hyperv-ubuntu-trusty-go_agent?v=3586.27

bosh upload-stemcell --sha1 e1ab7bd57784cfcc790c41765aaad2b50b41bd8b \
  https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3586.27
```

Thanks for using bblwrap!
