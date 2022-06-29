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

## Spinning up an Atlas cluster through the MongoDB Atlas operator
This can be done in a few and easy steps. I you want the full description refer to [the MongoDB Atlas operator Quick Start Guide](https://www.mongodb.com/docs/atlas/reference/atlas-operator/ak8so-quick-start/#std-label-ak8so-quick-start-ref)
```
kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-atlas-kubernetes/main/deploy/all-in-one.yaml
```
This will install the latest operator. It's possible to install earlier versions. The approach is described in the quick guide. Verify that the operator is running.

Next we will setup Atlas to allow working with an existing project, where the Atlas cluster will run. In Atlas create an API key for your Atlas Project to use and assign the key the 'Project Owner' role. Make note of the private/public key. Also find your OrganizationId.
Now create a secret for these values
```
kubectl create secret generic mongodb-atlas-operator-api-key \
    --from-literal="orgId=<atlas_organization_id>" \
    --from-literal="publicApiKey=<atlas_api_public_key>" \
    --from-literal="privateApiKey=<atlas_api_private_key>" \
    -n mongodb-atlas-system
kubectl label secret mongodb-atlas-operator-api-key atlas.mongodb.com/type=credentials -n mongodb-atlas-system
```
With that in place you are ready to spin up your Atlas cluster. In the code below replace k8s-demo with your Atlas project name and run the script.
```
cat > atlas-project.yml << EOF 
apiVersion: atlas.mongodb.com/v1
kind: AtlasProject
metadata:
  name: my-project
spec:
  name: Jacob Borella
  projectIpAccessList:
    - ipAddress: "0.0.0.0/0"
      comment: "Allowing access to database from everywhere (only for Demo!)"
EOF
cat > atlas-cluster.yml << EOF
apiVersion: atlas.mongodb.com/v1
kind: AtlasDeployment
metadata:
  name: my-atlas-cluster
spec:
  projectRef:
    name: my-project
  deploymentSpec:
    name: "Test-cluster"
    providerSettings:
      instanceSizeName: M10
      providerName: AWS
      regionName: US_EAST_1
EOF
kubectl create namespace my-mongo-atlas
kubectl apply -f atlas-project.yml -n my-mongo-atlas
kubectl apply -f atlas-cluster.yml -n my-mongo-atlas
```

Now a database will be provisioned. You can also setup a user for access to the DB
```
kubectl create secret generic the-user-password --from-literal="password=P@@sword%" -n my-mongo-atlas
kubectl label secret the-user-password atlas.mongodb.com/type=credentials -n my-mongo-atlas
cat > user.yml << EOF
apiVersion: atlas.mongodb.com/v1
kind: AtlasDatabaseUser
metadata:
  name: my-database-user
spec:
  roles:
    - roleName: "readWriteAnyDatabase"
      databaseName: "admin"
  projectRef:
    name: my-project
  username: student
  passwordSecretRef:
    name: the-user-password
EOF
kubectl apply -f user.yml -n my-mongo-atlas
```
Finally when the cluster is fully started you can get the connect url with
```
kubectl get secret jacob-borella-test-cluster-student -o json -n my-mongo-atlas | jq -r '.data | with_entries(.value |= @base64d)'
```
When you are done with the environment, you can delete the ressources with
```
kubectl delete -f user.yml -n my-mongo-atlas
kubectl delete -f atlas-cluster.yml -n my-mongo-atlas
# be careful this command will delete your Atlas project kubectl delete -f atlas-project.yml -n my-mongo-atlas
```
## Verifying the connection
For verifying your connection, I've made a small service, which can fetch movies from the database.

To build and run the service in minikube issue the following commands
```
#setup docker to point to the minikube env
eval $(minikube docker-env)

#build your image into the minikube repo
docker build -t mongovalidate .

#create the connect string to mongodb as a secret
kubectl create secret generic mongo-connect-uri --from-literal=uri=$(kubectl get secret jacob-borella-test-cluster-student -o json -n my-mongo-atlas | jq -r '.data | with_entries(.value |= @base64d)' | jq -r '.connectionStringStandard') -n my-mongo-atlas

#create the config file for the pod & deploy it
cat > mongovalidate.yml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: mongo-validate
  labels:
    name: mongo-validate
spec:
  containers:
  - name: envar-demo-container
    image: mongovalidate
    imagePullPolicy: Never
    env:
    - name: DB_URI
      valueFrom:
        secretKeyRef:
          name: mongo-connect-uri
          key: uri
          optional: false
EOF
kubectl apply -f mongovalidate.yml  -n my-mongo-atlas

#expose the service
kubectl expose pod mongo-validate  --type="NodePort" --port 8080 -n my-mongo-atlas

#access the endpoint. this call should list the databases available
curl $(minikube service --url mongo-validate -n my-mongo-atlas)/movie
```
If you want to se an actual movie load the sample dataset into your database. Then run
```
curl $(minikube service --url mongo-validate -n my-mongo-atlas)/movie/Frida
```