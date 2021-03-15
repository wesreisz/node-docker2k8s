# From scratch, create a project and deploy it to kind. Use contour to expose the route.


Using docker let's build and run an image.
1. Create an index.js file from the commandline:
```
cat <<EOF > index.js
const http = require("http");
  http
   .createServer(function(request, response){
       console.log("request received");
       response.end("Hello World", "utf-8")
   })
   .listen(3000)
  console.log("server running: localhost:3000");
EOF
```

1. Run it

`node index.js`

1. Create a docker file, dockerize it, & run it in docker:
```
cat <<EOF > Dockerfile
FROM node:12-stretch
COPY index.js index.js
CMD ["node", "index.js"]
EOF
```

build it: `docker build -t wesreisz/hello-node:v1 .`

run it: `docker run -p 3000:3000 hello-node:v1`

Worth Mentioning: https://12factor.net/build-release-run

1. Push it to dockerhub:
```
docker login
docker push wesreisz/hello-node:v1
```


Now that we have an image, let's build and run it in a k8s environment. We'll start with kind (kubernetes in docker).

1. Define a cluster:
```
cat <<EOF > cluster.yaml
# Save to 'cluster.yaml'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 443
    listenAddress: "0.0.0.0"
EOF
```

1. Create the cluster:
```
kind create cluster --config create-cluster.yaml --name hello-kubernetes
```

1. Build deployment descriptor
```
cat <<EOF > deployment.yaml
# Save to 'deployment.yaml'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-kubernetes
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-kubernetes
  template:
    metadata:
      labels:
        app: hello-kubernetes
    spec:
      containers:
      - name: hello-kubernetes
        image: wesreisz/hello-node:v1
        ports:
        - containerPort: 3000
EOF
```

1. Deploy the deployment
```
kubectl apply -f deployment.yaml
```

1. Create clusterip service
```
cat <<EOF > service.yaml
# Save to 'service.yaml'
apiVersion: v1
kind: Service
metadata:
  name: hello-kubernetes
spec:
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: hello-kubernetes
EOF
```

1. Deploy the service
```
kubectl apply -f service.yaml
```

Install an ingress controller... we'll use contour:
1. Google install contour:
```
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```

1. Create ingress
```
cat <<EOF > ingress.yaml
# Save to 'ingress.yaml'
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: hello-kubernetes
  labels:
    app: hello-kubernetes
spec:
  backend:
    serviceName: hello-kubernetes
    servicePort: 80
EOF
```

1. Deploy the service
```
kubectl apply -f service.yaml
```

1. add enty to host file to point to 127.0.0.1

1. Load it in a browser


