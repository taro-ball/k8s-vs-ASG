kubectl top nodes
kubectl get hpa
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --sort-by=.spec.nodeName
PATH="/usr/local/bin:$PATH"