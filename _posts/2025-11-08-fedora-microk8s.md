---
title: "Installing microk8s in Fedora"
date: 2025-11-08
layout: post
tags: [microk8s, fedora, automation]
---

Kubernetes has become the de facto standard for container orchestration, enabling developers and operators to manage complex applications at scale. For those looking to experiment or run lightweight clusters locally, MicroK8s offers a streamlined Kubernetes experience. MicroK8s is a minimal, single-package Kubernetes distribution maintained by Canonical, designed to be easy to install and use.

MicroK8s is distributed via Snap, a universal package manager that provides self-contained software packages. Snap packages include all their dependencies, siming to make them work consistently across different Linux distributions. While this approach ensures compatibility, installing MicroK8s on Fedora requires a few specific steps.

In this post, I'll walk through the process I followed to successfully install and run MicroK8s on Fedora, highlighting the challenges and solutions along the way.  
If you already have MicroK8s installed and are experiencing DNS issues, you can skip directly to [Fixing DNS](#fixing-dns) section. 


## Prerequisites

Before proceeding with the installation, ensure your system meets these requirements:
- Fedora 35 or later
- At least 4GB of RAM
- At least 20GB of available disk space
- Admin (sudo) privileges

## Installing Snap

First, we need to install Snap on Fedora [[1](#references)]. The Snap daemon (snapd) is available in the official Fedora repositories:

```bash
# Install snapd package
$ sudo dnf install snapd

# Create symbolic link for snap
$ sudo ln -s /var/lib/snapd/snap /snap
```

After installing Snap, it's recommended to1 restart your system to ensure all paths and services are properly initialized:

```bash
$ sudo reboot
```

## Installing MicroK8s

With Snap installed, we can now install MicroK8s [[2](#references)]:

```bash
# Install MicroK8s using snap
$ sudo snap install microk8s --classic

# Add your user to the microk8s group
$ sudo usermod -a -G microk8s $USER

# Create .kube directory
$ mkdir -p ~/.kube

# Change ownership of the .kube directory
$ sudo chown -R $USER ~/.kube

# Create symbolic link for kubectl configuration
$ sudo microk8s config > ~/.kube/config
```



You'll need to log out and log back in for the group changes to take effect. After logging back in, verify and manage MicroK8s:

```bash
# Check the current status
$ microk8s status

# Start MicroK8s
$ microk8s start

# Wait for MicroK8s to be ready
$ microk8s status --wait-ready

# Stop MicroK8s if needed
$ microk8s stop
```

By default, MicroK8s runs with strict confinement. To use it effectively, you can enable some common addons:

```bash
# Enable common addons
$ microk8s enable dns
$ microk8s enable hostpath-storage
```

Important: MicroK8s remembers its last state when your system reboots. If MicroK8s was running when you shut down your system, it will automatically start on the next boot. Conversely, if it was stopped before shutdown, it will remain stopped after reboot.

To ensure MicroK8s always starts on boot, verify its status and start it if needed before shutting down your system:

```bash
# Check current status and start if needed
$ microk8s status && microk8s start
```

All good till here, it seems straight forward. We can start using it right away.
Lets use kubectl to look at our cluster:

```bash
$ alias kubectl='microk8s kubectl'
$ microk8s kubectl get all --all-namespaces
```

But, what happens when we want a pod to see other?

Let's try a simple example with a pod and a service pointing to it:

```yaml
# pod1.yml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-pod1
  labels:
    app: ubuntu1
spec:
  containers:
  - name: ubuntu
    image: ubuntu:latest
    command: ["/bin/sleep", "3650d"]

---
# service1.yml
apiVersion: v1
kind: Service
metadata:
  name: ubuntu-service
spec:
  selector:
    app: ubuntu1
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80

```

When you apply these configurations:

```bash
$ microk8s kubectl apply -f pods.yml

    pod/ubuntu-pod1 created
    service/ubuntu-service created
```

we can now see our 2 pods and service:

```bash
$ kubectl get pods -o wide

NAME                                  READY   STATUS    RESTARTS       AGE     IP             NODE     NOMINATED NODE   READINESS GATES
ubuntu-pod1                           1/1     Running   0              2m33s   10.1.124.253   fedora   <none>           <none>
ubuntu-pod2                           1/1     Running   0              97s     10.1.124.233   fedora   <none>           <none>

$ kubectl get service -o wide
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)            AGE     SELECTOR
kubernetes           ClusterIP   10.152.183.1     <none>        443/TCP            3d3h    <none>
ubuntu-service       ClusterIP   10.152.183.187   <none>        80/TCP             4m28s   app=ubuntu1
```

lets now spin a shell up and try to resolve our new service:

```bash
$ kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot

nslookup ubuntu-service
;; communications error to 10.152.183.10#53: timed out
;; communications error to 10.152.183.10#53: timed out
;; communications error to 10.152.183.10#53: timed out
;; no servers could be reached

```

It doesnt work! 

```bash
nslookup ubuntu-service
;; Got recursion not available from 10.152.183.10
Server:		10.152.183.10
Address:	10.152.183.10#53

Name:	ubuntu-service.default.svc.cluster.local
Address: 10.152.183.44
;; Got recursion not available from 10.152.183.10
```

### Fixing DNS

#### TODO: FILL

```bash
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload
```


## Kubernetes Dashboard

```bash
sudo vim /var/snap/microk8s/common/addons/core/addons/dashboard/enable
```

```bash
$HELM upgrade --install kubernetes-dashboard kubernetes-dashboard \
  --repo "${REPO}" --version "${VERSION}" \
  --create-namespace --namespace "kubernetes-dashboard" \
  --set kong.env.dns_order="LAST\,A\,CNAME\,SRV" \
  --set kong.env.ADMIN_LISTEN="0.0.0.0:8444 http2 ssl"
```

```bash
kubectl create token default
```

```bash
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard-kong-proxy 10443:443
```

## References

1. [Installing Snap on Fedora](https://snapcraft.io/docs/installing-snap-on-fedora)
2. [Getting Started with MicroK8s](https://microk8s.io/docs/getting-started)