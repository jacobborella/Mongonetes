# Mongonetes
This repo provides all the steps to spin up a minikube with mongodb running in it.
## Creating an AWS instance
To provision a machine on AWS with the latest version of minikube, first sign in with your AWS cli, using your preferred method. Then run
```
./create_k8s_test_env.sh
```
Wait until you see the text
```
Host is ready. Access with: 
ssh ec2-user@xxx.xxx.xxx.xxx
```
Once signed in, you can use
```
minikube start
kubectl get po -A
```
to start and verify your environment. Now you are ready to install MongoDB