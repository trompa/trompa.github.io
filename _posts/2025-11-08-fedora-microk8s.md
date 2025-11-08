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
sudo dnf install snapd

# Create symbolic link for snap
sudo ln -s /var/lib/snapd/snap /snap
```

After installing Snap, it's recommended to1 restart your system to ensure all paths and services are properly initialized:

```bash
sudo reboot
```

## Installing MicroK8s

With Snap installed, we can now install MicroK8s [[2](#references)]:

```bash
# Install MicroK8s using snap
sudo snap install microk8s --classic

# Add your user to the microk8s group
sudo usermod -a -G microk8s $USER

# Create .kube directory
mkdir -p ~/.kube

# Change ownership of the .kube directory
sudo chown -R $USER ~/.kube

# Create symbolic link for kubectl configuration
sudo microk8s config > ~/.kube/config
```



You'll need to log out and log back in for the group changes to take effect. After logging back in, verify and manage MicroK8s:

```bash
# Check the current status
microk8s status

# Start MicroK8s
microk8s start

# Wait for MicroK8s to be ready
microk8s status --wait-ready

# Stop MicroK8s if needed
microk8s stop
```

By default, MicroK8s runs with strict confinement. To use it effectively, you can enable some common addons:

```bash
# Enable common addons
microk8s enable dns
microk8s enable hostpath-storage
```

Important: MicroK8s remembers its last state when your system reboots. If MicroK8s was running when you shut down your system, it will automatically start on the next boot. Conversely, if it was stopped before shutdown, it will remain stopped after reboot.

To ensure MicroK8s always starts on boot, verify its status and start it if needed before shutting down your system:

```bash
# Check current status and start if needed
microk8s status && microk8s start
```

All good till here, it seems straight forward. We can start using it right away.
Lets use kubectl to look at our cluster:

```bash
alias kubectl='microk8s kubectl'
microk8s kubectl get all --all-namespaces
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