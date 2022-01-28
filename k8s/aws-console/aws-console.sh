# full instructions here: https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
kubectl apply -f eks-console-full-access.yaml

kubectl edit -n kube-system configmap/aws-auth
kubectl describe configmap -n kube-system aws-auth

# see k8s\aws-console\auth.sample.yaml