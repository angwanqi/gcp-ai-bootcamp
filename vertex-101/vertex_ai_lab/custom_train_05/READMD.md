# Run custom training job for online prediction

### Build the image with python source code
Run the shell script to create the artifact registry and build/push the image to the registry
```bash
chmod +x build.sh
./build.sh
```

### Run the training job from terminal
You need to provide the dataset id `--ds`. You can also provide persistent resource through argument `--ps`. 
If you have no such resource, ignore it and it will get available resources
```bash
python run.py --ps <persistent_resource_id> --ds <dataset_id>
```

### Deploy to endpoint for online prediction
Model id is required, if you do not know the id, run below command to identify:
```bash
gcloud ai models list
```

After running the deployment, you can use the same method to load the endpoint and make prediction.
```bash
python deploy.py --model <model_id>
```