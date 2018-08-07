#!/bin/bash

# setup file for bblwrap project found here:
# git clone https://github.com/scottbri/bblwrap

# check cli tools
echo -n "checking if yq is installed... "
which yq > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install YQ"
    echo "OSX: brew install yq"
    echo "Ubuntu: snap install yq"
else
    echo "yes"
fi

echo -n "checking if jq is installed... "
which jq > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install JQ"
    echo "OSX: brew install jq"
    echo "Ubuntu: sudo apt-get install jq"
    echo ""
else
    echo "yes"
fi

echo -n "checking if azure-cli is installed... "
which az > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install AZ cli"
    echo "OSX: brew update && brew install azure-cli"
    echo "Ubuntu: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest"
    echo ""
else
    echo "yes"
fi

echo -n "checking if gcloud-cli is installed... "
which gcloud > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install gcloud cli"
    echo "OSX: https://cloud.google.com/sdk/docs/quickstart-macos"
    echo "Ubuntu: https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu"
    echo ""
else
    echo "yes"
fi

echo -n "checking if terraform is installed... "
which terraform > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install terraform"
    echo "https://www.terraform.io/downloads.html"
    echo ""
else
    echo "yes"
fi

echo -n "checking if ruby is installed... "
which ruby > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install ruby"
else
    echo "yes"
fi


echo -n "checking if bosh-cli is installed... "
which bosh > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install bosh cli"
    echo "OSX: brew install cloudfoudry/tap/bosh-cli"
    echo "Ubuntu:  https://bosh.io/docs/cli-v2-install"
    echo ""
else
    echo "yes"
fi

echo -n "checking if bbl cli is installed... "
which bbl > /dev/null
if [ "$?" -ne "0" ]; then
    echo "no."
    echo "please install bbl cli"
    echo "OSX: brew install cloudfoundry/tap/bbl"
    echo "Ubuntu:  https://github.com/cloudfoundry/bosh-bootloader/releases"
    echo ""
else
    echo "yes"
fi

echo "Install bosh build environment dependencies... "
echo "make sure you've installed the dependencies here"
echo "https://bosh.io/docs/cli-v2-install/#additional-dependencies"
echo ""

echo ""
