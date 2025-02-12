This is how you deploy the pods to the namespace.

## Deploy

### Step 1: Set Context (Optional)

If you wish to not pass the namespace name for each command, run the following to set the namespace context:

```
kubectl config set-context nautilus --namespace=sdsu-tend-lab
```

Note: All the example below still include the `-n NAMESPACE` for reference. 

### Step 2: Create Personal Volume/PVC (skip this if you already have storage configured for your pod)

IMPORTANT TODO: Create a copy of the volume.yaml file and modify the "volume-{change name}" name in the file (line 5) replacing "username" with your username. If you don't do this, you will not have your own volume/PVC where your files are stored.

```
kubectl create -f volume.yaml -n sdsu-tend-lab
```

Run the following to see your new volume/PVC:

```
kubectl get pvc -n sdsu-tend-lab
```

### Step 3: Create the Pod

IMPORTANT TODO: Create a copy of the afni-deployment.yaml file and modify the "afni-deployment-{username}" name in the file (line 5) 

Change the command on line 39 ```["sh", "-c", "sleep infinity"]``` to the command you want. An example is on line 38. 

Optional: If you need your own personal volume/storage, and "jupyter-volume-{change-name}" (line 63) replacing "{change-name}" with your username. If you don't do this, you may conflict with someone else using the default name.

Create pod:

```
kubectl create -f afni-deployment.yaml -n sdsu-tend-lab
```

## Access to the pod using bash

Get pod and ensure it's running:

```
kubectl get pods -n sdsu-tend-lab
```

`Note: Replace "username" with your username in the example below.`

Look for the pod with your username in it. Once running, collect your pod's logs:

```
kubectl -n sdsu-tend-lab  exec -it afni-deployment-{username} -- bash
```

## Running Jupyterlab
If you want to run an instance of Jupyterlab, following the steps above in "Access to the pod using bash". Inside the bash terminal, run "jupyter lab". It will generate and output. From the output, copy the URL to the clipboard that starts with http://127.0.0.1./. 

Open a second terminal window and run the following command to set up port forwarding between your computer and the container running Jupyter.

```
kubectl port-forward jupyterpod-{username} -n sdsu-tend-lab 8888:8888
```

*Note*: If you get an error message indicating port 8888 is already taken, simply change the port number on the left side of the colon in the above command i.e. `8889:8888`.
Then when you paste the URL from the output, make sure to update the port from 8888 to 8889, or whatever number you chose.
This issue can arise if you have a local instance of Jupyter Lab already running on port 8888.

You should now be able to access the URL you copied to the clipboard in your web browser.

## Shutdown / Cleanup

When done, delete your pod:

```
kubectl delete -f afni-deployment.yaml -n sdsu-tend-lab
```

`Note: Your volume will persist so you can start the pod again and have acecss to your data.`
