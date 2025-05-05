# Nutanix VM Disk Image Preparation Guide

*This document outlines the standardized process for preparing a generalized disk image for Nutanix VMs, including container mounting, disk identification, conversion, sysprep, and upload.*

## **1\. Mount the Nutanix Container**

### **1.1 Verify NFS Export Availability**

```bash
showmount -e 10.169.28.147 | grep default-container-45667019721350
```

****Expected Output:****

`/default-container-45667019721350 [accessible]`

### **1.2 Mount the Container**

```bash
sudo mount -t nfs 10.169.28.147:/default-container-45667019721350 /mnt/test
```

### ****Verify Mount:****

```bash
df -h /mnt/test
```

******Output:******

`Filesystem Size Used Avail Use% Mounted on`  
`10.169.28.147:/default-container-45667019721350 4.6T 2.8T 1.8T 61% /mnt/test`

* * *

## **2\. VM Disk Identification**

### **2.1 Locate VM Disks Using Nutanix CLI**

```bash
acli vm.get r-shield include_vmdisk_paths=true | grep -w vmdisk_nfs_path
```

****Output:****

`vmdisk_nfs_path: "/default-container-45667019721350/.acropolis/vmdisk/39d4acd8-c22b-4f7d-9826-08121f706ed5"`

### **2.2 Identify Primary Disk**

```bash
acli vm.disk_get r-shield disk_addr="scsi.0" | grep -w vmdisk_uuid
```

****Output:****

`vmdisk_uuid: "39d4acd8-c22b-4f7d-9826-08121f706ed5"`

* * *

## **3\. Disk Image Preparation**

### **3.1 Set Up Local Storage**

```bash
sudo mkdir /mnt/image  
sudo mount /dev/sdb1 /mnt/image  
lsblk | grep /mnt/image
```

****Output:****

`└─sdb1 8:17 0 500G 0 part /mnt/image`

### **3.2 Copy Disk Image Locally**

```bash
sudo rsync -avh --progress /mnt/test/.acropolis/vmdisk/39d4acd8-c22b-4f7d-9826-08121f706ed5 /mnt/image/
```

### **3.3 Convert RAW to QCOW2 Format**

```bash
sudo qemu-img convert -p -f raw -O qcow2 \  
-o cluster_size=4k \  
/mnt/image/39d4acd8-c22b-4f7d-9826-08121f706ed5 \  
/mnt/image/hycu-r-shield-image_v1.qcow2
```

### **3.4 Sysprep (Generalize Image)**

```bash
sudo virt-sysprep -a /mnt/image/hycu-r-shield-image_v1.qcow2 \
  --operations defaults,bash-history,logfiles,tmp-files,machine-id,user-account \
  --keep-user-accounts hycu \
  --firstboot-command '
    systemctl enable --now NetworkManager || true
    for iface in $(nmcli -t -f DEVICE,TYPE device status | grep -E "ethernet|enp|ens" | cut -d: -f1); do
      nmcli connection add type ethernet ifname "$iface" \
        con-name "Auto-$iface" \
        connection.autoconnect yes \
        ipv4.method auto \
        ipv6.method auto 2>/dev/null || true
    done
    {
      echo "Network ready at $(date)"
      nmcli device show
    } > /var/log/network-firstboot.log
    if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
      dpkg-reconfigure openssh-server
    fi
    systemctl enable --now ssh
    if command -v ufw >/dev/null; then
      ufw allow ssh
    fi
  '
```

### **3.5 Verify Image Integrity**

****List `/etc/` Contents:****

```bash
sudo virt-ls -a /mnt/image/hycu-r-shield-image_v1.qcow2 /etc/
```

******QCOW2 Integrity Check:******

```bash
sudo qemu-img check /mnt/image/hycu-r-shield-image_v1.qcow2
```

* * *

## **4\. Compress the Image**

```bash
sudo virt-sparsify --tmp /dev/shm --compress \
  /mnt/image/hycu-r-shield-image_v1.qcow2 \
  /mnt/image/hycu-rshield-5.1.0-418.qcow2
```

****Verify Checksum:****

```bash
sha256sum /mnt/image/hycu-rshield-5.1.0-418.qcow2
```

******Output:******

`f4030c235400fb1a2b6b1884b09092aedbc388c28f575d63be394b6abdab442a hycu-rshield-5.1.0-418.qcow2`

* * *

## **5\. Upload Image to Nutanix**

### **5.1 Copy Image to Nutanix Container**

```bash
sudo rsync -avh --progress /mnt/image/hycu-rshield-5.1.0-418.qcow2 /mnt/test/
```

### **5.2 Register Image via `acli`**

```bash
acli image.create hycu-rshield-5.1.0-418 \
  image_type=kDiskImage \
  source_url=nfs://10.169.28.147/default-container-45667019721350/hycu-rshield-5.1.0-418.qcow2 \
  container=default-container-45667019721350
```

* * *

## **6\. Helpful Commands**

### **6.1 Network Debugging**

```bash
sudo journalctl -u systemd-networkd -u dhclient -b --no-pager | grep -i "dhcp\|ens3"
```

****DHCP Lease Renewal:****

```bash
sudo dhclient -r ens3  # Release lease  
sudo dhclient -v ens3  # Request new lease  
```

### **6.2 Disk Space Optimization (Pre-Sparsify)**

```bash
sudo dd if=/dev/zero of=/zero.fill bs=1M || true  
sudo rm -f /zero.fill  
sync  
```

### **6.3 Check NFS Exports**

```bash
showmount -e 10.169.28.147 | grep -v <Scanner_IP>
```

* * *

&nbsp;
