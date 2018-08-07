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
