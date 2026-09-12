# Linux storage filesystem options

Checked 2026-09-14 for one empty 8 TB internal WD HDD on CachyOS. Research only; no formatting, package installation, or mount configuration was performed. Existing `docs/*.md` research-note conventions were followed. `MISTAKES.md` was read; this documentation change does not touch a listed implementation category.

## Recommendation

For general Linux-only storage, **Btrfs is the strongest default when checksums and snapshots are useful; ext4 is the simplest choice; ZFS is reasonable when deliberately building a managed storage pool or planning replication/mirroring**. XFS is attractive for large-file workloads without native snapshot/compression requirements. These are workload-dependent recommendations, not benchmark results.

| Filesystem | Useful features | Main tradeoff for this disk |
| --- | --- | --- |
| ext4 | Established journaling filesystem; online growth and offline shrinking | No native filesystem snapshots or transparent compression; ordinary file contents lack automatic filesystem data checksumming |
| XFS | Journaling, scalable allocation, reflink copies | No native whole-filesystem snapshots or transparent compression; metadata checksums do not checksum ordinary file contents; cannot shrink |
| Btrfs | Data/metadata checksums, snapshots, compression, send/receive, grow/shrink | More space/snapshot management; copy-on-write workload tradeoffs |
| OpenZFS | Data/metadata checksums, datasets, snapshots, compression, replication, native encryption, pools | Separate kernel module, pool administration, and version compatibility to maintain |

Sources: [CachyOS filesystem comparison](https://wiki.cachyos.org/installation/filesystem/), [ext4 metadata checksums](https://docs.kernel.org/filesystems/ext4/checksums.html), [XFS kernel documentation](https://docs.kernel.org/admin-guide/xfs.html), [Btrfs features](https://btrfs.readthedocs.io/en/latest/Introduction.html), [ZFS properties](https://openzfs.github.io/openzfs-docs/man/master/7/zfsprops.7.html).

## What ZFS buys on one disk

Checksums detect corrupted blocks on reads and during scrubs. Repair requires another valid copy. A normal single-disk pool cannot reconstruct damaged single-copy file data, though redundant metadata can help recover metadata damage. `copies=2` stores additional data copies at a capacity cost, but copies on the same disk do not survive complete disk failure. [ZFS checksums](https://openzfs.github.io/openzfs-docs/Basic%20Concepts/Data%20Storage/Checksums.html), [scrub](https://openzfs.github.io/openzfs-docs/man/master/8/zpool-scrub.8.html), [copies and redundant metadata](https://openzfs.github.io/openzfs-docs/man/master/7/zfsprops.7.html).

Snapshots preserve an earlier state and initially share existing blocks. Changed/deleted data retained by snapshots consumes space. They do not provide an independent copy against loss of the pool. Incremental send/receive can transfer snapshot changes to another ZFS pool for backups. [Snapshot semantics](https://openzfs.github.io/openzfs-docs/man/master/7/zfsprops.7.html), [ZFS send](https://openzfs.github.io/openzfs-docs/man/master/8/zfs-send.8.html).

A second suitable disk can later be attached to the existing single-device vdev to create a mirror; redundancy becomes available after resilvering finishes. A mirror trades the second disk's capacity for redundancy rather than doubling usable space. Adding an independent disk vdev instead creates a different failure topology; it is not equivalent to attaching a mirror. [ZFS attach](https://openzfs.github.io/openzfs-docs/man/master/8/zpool-attach.8.html), [pool layout](https://openzfs.github.io/openzfs-docs/man/master/7/zpoolconcepts.7.html).

## CachyOS and memory

CachyOS provides precompiled matching ZFS kernel modules, so ZFS does not inherently require users to rebuild DKMS modules after each kernel update. It remains outside the upstream Linux kernel; installed kernel, module, and userspace versions must work together. Current distribution documentation excludes real-time kernels. Upstream release support is bounded by its supported kernel range. [CachyOS kernel modules](https://wiki.cachyos.org/features/kernel/#prebuilt-kernel-modules), [filesystem requirements](https://wiki.cachyos.org/installation/filesystem/), [OpenZFS kernel compatibility](https://openzfs.github.io/openzfs-docs/Project%20and%20Community/FAQ.html#supported-linux-kernels).

OpenZFS suggests 8 GB or more for best performance, but documents operation with 2 GB or less; ECC is recommended rather than mandatory. This is not a fixed RAM-per-terabyte requirement. ARC is a tunable cache, and deduplication is a separate, potentially expensive feature. Recommendation: leave deduplication disabled for ordinary storage. [Hardware FAQ](https://openzfs.github.io/openzfs-docs/Project%20and%20Community/FAQ.html#hardware-requirements), [ARC limits](https://openzfs.github.io/openzfs-docs/man/master/4/zfs.4.html#zfs_arc_max), [deduplication guidance](https://openzfs.github.io/openzfs-docs/man/master/7/zfsprops.7.html#dedup).

## Btrfs integrity caveat

Btrfs likewise needs another verified copy to repair corruption. Disabling copy-on-write with `chattr +C` also disables file-data checksumming; it should not be applied broadly while expecting full scrub protection. Monthly scrubs are the upstream recommendation, with scheduling appropriate to the HDD workload. [Btrfs scrub documentation](https://btrfs.readthedocs.io/en/latest/btrfs-scrub.html).

No speed ranking was measured on this HDD. The final decision should reflect whether its contents are replaceable media/downloads, active VM/database data, or irreplaceable archives needing separate backups.
