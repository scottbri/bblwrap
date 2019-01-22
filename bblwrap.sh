#!/bin/bash

DEBUG=0
DEBUGFILE="initialize_iaas.log"

# A little function to ask a user for input
# always returns 0, but echo's the user's sanitized response for capture as a string by the caller
askUser() {
	read -p "$1"": " __val
	# first, strip underscores
	CLEAN=${__val//_/}
	# next, replace spaces with underscores
	CLEAN=${CLEAN// /_}
	# now, clean out anything that's not alphanumeric or an underscore or a hyphen
	CLEAN=${CLEAN//[^a-zA-Z0-9_-]/}
	echo "${CLEAN}"

	return 0
}

# A little more function based on askUser() to specifically ask a yes or no question
# returns 0 for Yes or 1 for "not yes"
askYes() {
	CLEAN="$(askUser "$1 (Y|y) ")"
	if [ "$CLEAN" == "${CLEAN#[Yy]}" ]; then
		return 1
	else
		return 0
	fi
}	

BBL_IAAS="$(askUser "Please pick a target IAAS: gcp, aws, azure, or vsphere? ")"
BBL_ENV_NAME="$(askUser "Decide on a short subdomain name (like \"pcf\") for the environment? ")"
BBL_STATE_DIRECTORY="$PWD/state/$BBL_IAAS/$BBL_ENV_NAME"
BBL_ENVIRONMENT_VARS="$BBL_STATE_DIRECTORY/$BBL_ENV_NAME-ENV-VARS.sh"
mkdir -p "$BBL_STATE_DIRECTORY"

if [ $BBL_IAAS == "gcp" ]; then
	BBL_GCP_SERVICE_ACCOUNT_KEY="${BBL_GCP_SERVICE_ACCOUNT_KEY:-UNSET}"
	BBL_GCP_REGION="${BBL_GCP_REGION:-UNSET}"
	
	echo "Here are how the required environment variables to bbl up on $BBL_IAAS are currently set:"
	echo "BBL_IAAS=$BBL_IAAS"
	echo "BBL_ENV_NAME=$BBL_ENV_NAME"
	echo "BBL_GCP_REGION=$BBL_GCP_REGION"
	echo "BBL_GCP_SERVICE_ACCOUNT_KEY=$BBL_GCP_SERVICE_ACCOUNT_KEY"
	echo "BBL_STATE_DIRECTORY=$BBL_STATE_DIRECTORY"
		
	echo ""; askYes "Would you like to continue and get help populating these values?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Ok then.  Good luck bbl-ing up on $BBL_IAAS!"; exit 0; fi

	sleep 1; echo ""; echo "Great!  Let's continue."
	echo ""; echo "Let's determine your GCP Project ID"
	echo "gcloud projects list"
	GCP_PROJECTS="`gcloud projects list | grep -v "PROJECT_NUMBER" | awk '{print $1}'`"
	if [ `echo $GCP_PROJECTS | wc -w` == "1" ]; then
		GCP_PROJECT_ID=$GCP_PROJECTS
		echo "Since you only have access to a single GCP project.  We'll use it for this deployment"
		echo "GCP_PROJECT_ID=$GCP_PROJECT_ID"
	else
		echo "You seem to have access to these GCP projects:"
		echo "$GCP_PROJECTS"
		GCP_PROJECT_ID="$(askUser "Please enter one of the above GCP Project ID's for this deployment")"
	fi

	echo ""; echo "Creating a new service account in GCP that will own the BOSH deployment"
	GCP_SERVICE_ACCOUNT_NAME="`echo $BBL_ENV_NAME | awk '{print tolower($0)}'`""serviceaccount"
	echo "$ gcloud iam service-accounts create $GCP_SERVICE_ACCOUNT_NAME"
	gcloud iam service-accounts create $GCP_SERVICE_ACCOUNT_NAME
	RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Hmmm.  You may need to execute a \"gcloud init\" if you're having issues with permissions."; exit 1; fi
	

	sleep 1; echo ""; echo "Here is a list of regions where BOSH can be deployed"
	echo "$ gcloud compute regions list"
	gcloud compute regions list
	BBL_GCP_REGION="$(askUser "Please input the name of one of these regions for the deployment")"

	sleep 1; echo ""; echo "Now I need to create a service account key. I'll store it here:"
	BBL_GCP_SERVICE_ACCOUNT_KEY="$BBL_STATE_DIRECTORY/$BBL_IAAS-$BBL_ENV_NAME-$GCP_SERVICE_ACCOUNT_NAME.key.json"
	echo "$BBL_GCP_SERVICE_ACCOUNT_KEY"
	touch $BBL_GCP_SERVICE_ACCOUNT_KEY;  chmod 700 $BBL_GCP_SERVICE_ACCOUNT_KEY
	echo "$ gcloud iam service-accounts keys create --iam-account=\"${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com\" $BBL_GCP_SERVICE_ACCOUNT_KEY"
	askYes "Are you good with me issuing the above command?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Bailing out now!  Good luck bbl-ing up on $BBL_IAAS!"; exit 1; fi
	gcloud iam service-accounts keys create --iam-account="${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" $BBL_GCP_SERVICE_ACCOUNT_KEY
	RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Hmmm.  You may need to execute a \"gcloud init\" if you're having issues with permissions."; exit 1; fi


	sleep 1; echo ""; echo "Binding the service account to the project with editor role"
	echo "gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member=\"serviceAccount:${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com\" --role='roles/owner'"
	askYes "Are you good with me issuing the above command?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Bailing out now!  Good luck bbl-ing up on $BBL_IAAS!"; exit 1; fi
	gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --role='roles/owner'
	RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Hmmm.  You may need to execute a \"gcloud init\" if you're having issues with permissions."; exit 1; fi

	echo ""; echo "Finished!  Here are the environment variables you need to set for bbl to deploy BOSH on $BBL_IAAS:"
	echo "Copy and paste them into your shell and then run bbl .  Also, archive these for posterity!"
	echo ""
	{
	echo "export BBL_IAAS=$BBL_IAAS"
	echo "export BBL_ENV_NAME=$BBL_ENV_NAME"
	echo "export BBL_STATE_DIRECTORY=$BBL_STATE_DIRECTORY"
	echo "export BBL_GCP_REGION=$BBL_GCP_REGION"
	echo "export BBL_GCP_SERVICE_ACCOUNT_KEY=$BBL_GCP_SERVICE_ACCOUNT_KEY"
	echo "export GCP_PROJECT_ID=$GCP_PROJECT_ID"
	echo "export GCP_SERVICE_ACCOUNT_NAME=$GCP_SERVICE_ACCOUNT_NAME"
	} | tee $BBL_ENVIRONMENT_VARS

elif [ $BBL_IAAS == "aws" ]; then
	echo "$BBL_IAAS not implemented yet"
	exit 1

elif [ $BBL_IAAS == "vsphere" ]; then
	echo "$BBL_IAAS not implemented yet"
	exit 1

elif [ $BBL_IAAS == "azure" ]; then
	BBL_AZURE_REGION="${BBL_AZURE_REGION:-UNSET}"
	BBL_AZURE_SUBSCRIPTION_ID="${BBL_AZURE_SUBSCRIPTION_ID:-UNSET}"
	BBL_AZURE_TENANT_ID="${BBL_AZURE_TENANT_ID:-UNSET}"
	BBL_AZURE_CLIENT_ID="${BBL_AZURE_CLIENT_ID:-UNSET}"
	BBL_AZURE_CLIENT_SECRET="${BBL_AZURE_CLIENT_SECRET:-UNSET}"
	
	echo "Here are how the required environment variables to bbl up on $BBL_IAAS are currently set:"
	echo "BBL_IAAS=$BBL_IAAS"
	echo "BBL_ENV_NAME=$BBL_ENV_NAME"
	echo "BBL_AZURE_REGION=$BBL_AZURE_REGION"
	echo "BBL_AZURE_SUBSCRIPTION_ID=$BBL_AZURE_SUBSCRIPTION_ID"
	echo "BBL_AZURE_TENANT_ID=$BBL_AZURE_TENANT_ID"
	echo "BBL_AZURE_CLIENT_ID=$BBL_AZURE_CLIENT_ID"
	echo "BBL_AZURE_CLIENT_SECRET=$BBL_AZURE_CLIENT_SECRET"
	echo "BBL_STATE_DIRECTORY=$BBL_STATE_DIRECTORY"
		
	echo ""; askYes "Would you like to continue and get help populating these values?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Ok then.  Good luck bbl-ing up on $BBL_IAAS!"; exit 0; fi

	sleep 1; echo ""; echo "Great!  Let's continue."
	BBL_AZURE_CLIENT_SECRET="$(askUser "Please enter a complex secret alphanumeric password for your new Active Directory application")"
		
	sleep 1; echo "Thanks!  Now we'll make sure you're logged into Azure.  Please follow the prompts to login:"
	echo "=========="
	echo '$ az login'
	az login 2>&1
	sleep 1; echo ""; echo "=========="; echo "... and we're back"

	sleep 1; echo ""; echo "Here is a list of locations (regions) where BOSH can be deployed"
	echo '$ az account list-locations | jq -r .[].name'
	az account list-locations | jq -r .[].name
	AZURE_REGION="$(askUser "Please input the name of one of these regions for the deployment")"

	sleep 1; echo ""; echo "I'm querying Azure for your default Subscription ID and Tenant ID"
	echo '$ az account list --all'
	AZ_ACCOUNT_LIST="`az account list --all`"
	export BBL_AZURE_SUBSCRIPTION_ID="`echo \"$AZ_ACCOUNT_LIST\" | jq -r '.[] | select(.isDefault) | .id'`"
	echo "Your BBL_AZURE_SUBSCRIPTION_ID is $BBL_AZURE_SUBSCRIPTION_ID:"

	export BBL_AZURE_TENANT_ID="`echo \"$AZ_ACCOUNT_LIST\" | jq -r '.[] | select(.isDefault) | .tenantId'`"
	echo "Your BBL_AZURE_TENANT_ID is $BBL_AZURE_TENANT_ID"
	if [ $DEBUG ]; then echo "$AZ_ACCOUNT_LIST" >> $DEBUGFILE; fi
	

	AZURE_SP_DISPLAY_NAME="Service Principal for BOSH"
	AZURE_SP_HOMEPAGE="http://BOSHAzureCPI"
	AZURE_SP_IDENTIFIER_URI="http://BOSHAzureCPI-$RANDOM"
	AZURE_OUTPUTFILE_JSON="service-principal.json"

	echo ""; echo "Creating an Active Directory application to generate a new Application ID"
	echo "$ az ad app create --display-name \"$AZURE_SP_DISPLAY_NAME\" \\"
	echo "	--password \"$BBL_AZURE_CLIENT_SECRET\" --homepage \"$AZURE_SP_HOMEPAGE\" \\"
	echo "	--identifier-uris \"$AZURE_SP_IDENTIFIER_URI\""
	askYes "Are you good with me issuing the above command?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Bailing out now!  Good luck bbl-ing up on $BBL_IAAS!"; exit 1; fi
	AZ_AD_APP_CREATE="`az ad app create --display-name \"$AZURE_SP_DISPLAY_NAME\" \
		--password \"$BBL_AZURE_CLIENT_SECRET\" --homepage \"$AZURE_SP_HOMEPAGE\" \
		--identifier-uris \"$AZURE_SP_IDENTIFIER_URI\"`"
	export BBL_AZURE_CLIENT_ID="`echo \"$AZ_AD_APP_CREATE\" | jq -r '.appId'`"
	echo "Your BBL_AZURE_CLIENT_ID is $BBL_AZURE_CLIENT_ID"
	if [ $DEBUG ]; then echo "$AZ_AD_APP_CREATE" >> $DEBUGFILE; fi

	echo ""; echo "Creating the Service Principal corresponding to the new Application"
	echo "$ az ad sp create --id $BBL_AZURE_CLIENT_ID"
	askYes "Are you good with me issuing the above command?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Bailing out now!  Good luck bbl-ing up on $BBL_IAAS!"; exit 1; fi
	AZ_AD_SP_CREATE="`az ad sp create --id $BBL_AZURE_CLIENT_ID`"
	if [ $DEBUG ]; then echo "$AZ_AD_SP_CREATE" >> $DEBUGFILE; fi

	echo ""; echo "Sleeping 45 seconds to let Azure AD catch up before proceeding"
	sleep 45
	echo ""; echo "Assigning the Service Principal to the Contributor Role"
	echo "$ az role assignment create --assignee $BBL_AZURE_CLIENT_ID --role Contributor --scope /subscriptions/$BBL_AZURE_SUBSCRIPTION_ID"
	askYes "Are you good with me issuing the above command?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Bailing out now!  Good luck bbl-ing up on $BBL_IAAS!"; exit 1; fi
	AZ_ROLE_ASSIGNMENT_CREATE="`az role assignment create --assignee $BBL_AZURE_CLIENT_ID --role Contributor --scope /subscriptions/$BBL_AZURE_SUBSCRIPTION_ID`"
	if [ $DEBUG ]; then echo "$AZ_ROLE_ASSIGNMENT_CREATE" >> $DEBUGFILE; fi

	echo ""; echo "Registering the Subscription with Microsoft Storage, Network, and Compute"
	echo "$ az provider register --namespace Microsoft.Storage"
	echo "$ az provider register --namespace Microsoft.Network"
	echo "$ az provider register --namespace Microsoft.Compute"
	askYes "Are you good with me issuing the above three (3) commands?"; RETVAL=$?
	if [[ $RETVAL -eq 1 ]]; then echo "Bailing out now!  Good luck bbl-ing up on $BBL_IAAS!"; exit 1; fi
	az provider register --namespace Microsoft.Storage
	az provider register --namespace Microsoft.Network
	az provider register --namespace Microsoft.Compute
	
	echo "Finished!  Here are the environment variables you need to set for bbl to deploy BOSH on Azure:"
	echo "Copy and paste them into your shell and then run bbl .  Also, archive these for posterity!"
	echo ""
	{
	echo "export BBL_IAAS=$BBL_IAAS"
	echo "export BBL_ENV_NAME=$BBL_ENV_NAME"
	echo "export BBL_STATE_DIRECTORY=$BBL_STATE_DIRECTORY"
	echo "export BBL_AZURE_REGION=$AZURE_REGION"
	echo "export BBL_AZURE_SUBSCRIPTION_ID=$BBL_AZURE_SUBSCRIPTION_ID"
	echo "export BBL_AZURE_TENANT_ID=$BBL_AZURE_TENANT_ID"
	echo "export BBL_AZURE_APPLICATION_ID=$BBL_AZURE_CLIENT_ID"
	echo "export BBL_AZURE_CLIENT_ID=$BBL_AZURE_CLIENT_ID"
	echo "export BBL_AZURE_CLIENT_SECRET=$BBL_AZURE_CLIENT_SECRET"
	} | tee $BBL_ENVIRONMENT_VARS
else
	echo "ERROR:  IAAS provider $BBL_IAAS is unknown"
	exit 1
fi

echo "";echo ""
echo "Now your IAAS should be set and ready to use bbl to create a bosh environment."
echo ""; echo "What you should do now:"
echo "# The following will enable the bbl command by sourcing the required env vars"
echo "source $BBL_ENVIRONMENT_VARS"
echo "bbl -h                        # familiarize yourself with bbl generally"
echo "bbl plan -h                    # familiarize yourself with the bbl plan command line options"
echo "bbl up -h                    # familiarize yourself with the bbl up command line options"
echo "bbl plan --lb-type concourse --debug        # this will create lots of structures in \$BBL_STATE_DIRECTORY"
echo "";echo "# after executing bbl plan, now you can go into \$BBL_STATE_DIRECTORY and make edits and customizations"
echo "";echo "bbl up --lb-type concourse --debug        # this will execute the plan with customizations on your IAAS"

echo "";echo ""
echo "Checkout the README.md for additional next steps.  Thanks for using bblwrap!"
