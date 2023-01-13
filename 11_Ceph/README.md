# Ceph

## Ceph Object Store

    RESTful Interface
    S3- and Swift-compliant APIs
    S3-style subdomains
    Unified S3/Swift namespace
    User management
    Usage tracking
    Striped objects
    Cloud solution integration
    Multi-site deployment
    Multi-site replication

## Ceph Block Device

    Thin-provisioned
    Images up to 16 exabytes
    Configurable striping
    In-memory caching
    Snapshots
    Copy-on-write cloning
    Kernel driver support
    KVM/libvirt support
    Back-end for cloud solutions
    Incremental backup
    Disaster recovery (multisite asynchronous replication)

## Ceph File System

    POSIX-compliant semantics
    Separates metadata from data
    Dynamic rebalancing
    Subdirectory snapshots
    Configurable striping
    Kernel driver support
    FUSE support
    NFS/CIFS deployable
    Use with Hadoop (replace HDFS)

## Ceph Storage Cluster Komponenten

- Ceph Monitor
- Ceph Manager
- Ceph OSD (Object Storage Daemon)
- Ceph MDS (Metadata Server) (für Ceph FS)

## Installation

    apt install -y ceph-base

Weiter geht es mit [HA in Diensten](../12_HA_in_Services)
