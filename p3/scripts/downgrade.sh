#!/bin/sh
cd ~/stamim-config && sed -i 's/wil42\/playground\:v2/wil42\/playground\:v1/g' k8s/deployment.yaml
cd ~/stamim-config && git add . && git commit -m "v1" && git push origin master
