# Kubernetes Install for PGC

## Setup Bastion/Controller

When we install Kubernetes we use a central system to interface with it for security reasons. It makes sense to use this instance to build out the cluster initially.

First we need to create a AWS IAM Role to allow this instance to administer certain services in AWS and permit it to create the entire Kubernetes environment for you. So create a new role, something like "k8s-Management" or something you will remember. Then attach the following policies:

KOPS requirements:
- AmazonEC2FullAccess
- AmazonRoute53FullAccess
- AmazonS3FullAccess
- IAMFullAccess
- AmazonVPCFullAccess
- CloudWatchLogsFullAccess # This is to run the PGC scripts to create the log groups.

Launch an EC2 instance, it doesn't have to be powerful, t2.micro or the like is fine. When creating the instance, use the userdata.txt as the userdata script. Make sure you either create a new security group specifically for this instance, or lock down an existing one. Anyone that gets access to this system can fully manage your Kubernetes environment, so lock it down to ssh from your IP or trusted IP's only. Also generate a new KeyPair just for this system.

userdata.txt:

```bash
#!/bin/bash
yum update -y
yum upgrade -y
yum install git -y
cd /home/ec2-user
su ec2-user -c "ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''"
su ec2-user -c "git clone https://github.com/UniversalDevicesInc/pgc_kops.git"
```

** NOTE: This is for an Amazon Linux AMI

This updates the base system, then generates a ssh key that will be used as the imported keypair for the Kubernetes instances that are created. It then clones this repository on to the machine for quick access to the scripts and Kubernetes YAML templates.

You should now be able to login to the instance and see the pgc_kops folder in your home directory.

## Kubernetes install

I have included a script that will install the entire cluster for you based on the template you choose. You MUST modify a template and make sure it fits your requirements. This includes adding the cluster name and modifying the S3 bucked ACL and Kops State Store that is created by the kops_install.sh. Here is an overview of the steps.

### DNS Prep

You MUST have DNS set up properly. This typically requires either an existing domain in Route53 on AWS, or delgating a subdomain to this AWS account. Follow this guide:
<https://github.com/kubernetes/kops/blob/master/docs/aws.md#configure-dns>

### kops_install Usage

`Usage: ./kops_install.sh <cluster name> <template.yaml>`

The cluster name should be a FQDN that is in the subdomain you configured above. You do NOT have to configure any DNS records for it. Kops will do that for you.

For example: k8s.aws.yourdomain.com

Secondly copy and modify the template provided in cloud42/pgcdev.yaml and update the 5 references to the cluster name. Replace "pgcdev.aws.cloud42.dev" with your domain from above. Change the 1 reference to the state store, this is made in the kops_install.sh script, so open it and define what you want the name to be, then make sure that name is reflected in the pgcdev.yaml. Keep in mind you can have multiple clusters in a single S3 state store bucket, so this does not have to be specific to this cluster. The kops_install.sh will create this bucket for you automatically, so you simple need to change the name in both places before you run it. Lastly the script creates an S3 bucket for nodeserver logs. This bucket is the cluster name replacing dots with dashes and ends with -ns-logs. So 'pgcdev.aws.cloud42.dev' becomes 'pgcdev-aws-cloud42-dev-ns-logs'. Go ahead and update the policies in pgcdev.yaml with the correct bucket names.

You can also modify the node and master sizes, number of nodes and masters, and what availability zones they reside in from this file.

    **TODO: I need to automate the editing of the pgcdev.yaml**

Everything below this line in this section just explains what the kops_install.sh is doing.

1. Sets the environment variables

    - NAME=cluster
    - KOPS_STATE_STORE=s3://state store bucket

    These are required for KOPS to function and know what cluster you are working with.

2. Installs all the environment variables into your ~/.bashrc so it's set automatically on login for you.

3. Creates the ns-logs and kops_state_store bucket you defined in kops_install.sh

4. Creates the CloudWatch Logs log groups based on the cluster name.

5. Installs kubectl, the management utility for Kubernetes

6. Installs KOPS itself.

7. Turns on tab completion of kubectl and kops commands in your shell.

8. Creates the configuration elements for the cluster inside KOPS based on the template we provided pgcdev.yaml

9. Creates a secret in KOPS that contains our KeyPair we generated (this will be the keypair that is used on all Kubernetes instances for SSH access). We generated a new one in the userdata.txt when we started the management instance.

10. We use the configuration elements we created in 8 and 9 and create them in AWS.

Once these steps are done. Log out of the console, then log back in. Bash is a pain in the ass about setting parent environment variables from within a script, so you will need to do this before trying to manage the cluster.

## Kubernetes cluster removal

To remove the cluster for whatever reason. Login to your controller bastion.

`kops delete cluster ${NAME} --yes`

Then delete the entries from ~/.bashrc. You will have to manually delete the S3 buckets and CloudWatch log groups. I didn't want to automate that for security reasons.

## Install Accessories

### Install Namespaces and ServiceAccounts

PGC uses several service accounts and namespaces inside Kubernetes to work. This template is provided for you in the shared/namespaces_and_serviceaccount.yaml.

Run the `install_accessories.sh` inside the shared folder to install them and the Kubernetes GUI (Dashboard). No modification is necessary here, but look over the yaml file and make sure you understand what it is creating. If you do not wish to install the dashboard, you still must install the namespaces_and_serviceaccount.yaml. To do so run `kubectl apply -f ./namespaces_and_serviceaccount.yaml` instead of running the full `install_accessories.sh` script.

### Create pgc-core secret

kubectl create secret -n pgc-core generic pgc-secret --from-literal=AWS_ACCESS_KEY_ID='key' --from-literal=AWS_SECRET_ACCESS_KEY='secret'

### Prometheus/Grafana/AlertManager

I have provided a custom install of the monitoring stack customized. Modifying the custom stack is outside the scope of this document, but it should work for everything you need.

To install:

```bash
cd custom-prometheus
kubectl apply -f manifests/
```

Once this install is complete, give it a few minutes to spin up, you should be able to access the web interfaces of all thre applications.

### Run pods on the master

```bash
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
```

### Make dashboard accessible

Edit the kubernetes-dashboard service and change it from ClusterIP to NodePort

```bash
kubectl -n kube-system edit service kubernetes-dashboard

grep 'client-certificate-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> nonprod.crt

grep 'client-key-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> nonprod.key

openssl pkcs12 -export -clcerts -inkey nonprod.key -in nonprod.crt -out nonprod.p12 -name "kubernetes-client"

kubectl config view --raw -o json | jq -r '.clusters[0].cluster."certificate-authority-data"' | tr -d '"' | base64 --decode > nonprod.crt
```

Take the .p12 file and install it as a user client certificate in windows.

Take the .crt and install it as a trusted root

Access the dashboard via:

<https://api.CLUSTERNAME/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login>

Get the token to login by getting the list of secrets and then describing the admin-user-token secret.

```bash
kubectl -n kube-system get secret
kubectl -n kube-system describe secrets admin-user-token-8kjtq
```