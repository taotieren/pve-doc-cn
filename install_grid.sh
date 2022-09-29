#!/bin/bash
#https://pve-doc-cn.readthedocs.io/zh_CN/pve-nvidia-vgpu/
nvidia_version="510.85.03"
nvidia_pkg="NVIDIA-Linux-x86_64-$nvidia_version-vgpu-kvm.run"
nvidia_url="https://foxi.buduanwang.vip/pan/foxi/Virtualization/vGPU/$nvidia_pkg"
grub_check(){
    if [ -e /etc/kernel/proxmox-boot-uuids ]
    then
    echo "引导为Systemd-boot"
    echo "正在修改cmdline"
    edit_cmdline
    else
    echo "引导为grub"
    echo "正在修改grub"    
    edit_grub
    fi
}

modiy_modules(){
    echo "正在修改内核参数"
    cp /etc/modules /opt/foxi_backup/modules_$(date +%s)
    echo vfio >> /etc/modules
    echo vfio_iommu_type1 >> /etc/modules
    echo vfio_pci >> /etc/modules
    echo vfio_virqfd >> /etc/modules
    sed -i '/nvidia/d' /etc/modprobe.d/*
    echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf 
    update-initramfs -u > /dev/null 2>&1
    echo "内核参数修改完成"
}

edit_cmdline(){
    cp /etc/kernel/cmdline /opt/foxi_backup/cmdline_$(date +%s)
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"' > /etc/kernel/cmdline
    proxmox-boot-tool refresh > /dev/null 2>&1
    echo "cmdline修改完成"
}

edit_grub(){
    cp /etc/default/grub  /opt/foxi_backup/grub_$(date +%s)
    sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/d' /etc/default/grub
    sed -i '/GRUB_CMDLINE_LINUX/i GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"' /etc/default/grub
    update-grub > /dev/null 2>&1
    echo "grub修改完成"
}

pkg_install(){
    apt update 
    apt install dkms build-essential  pve-headers-`uname -r` -y
    wget -P /tmp/ http://ftp.br.debian.org/debian/pool/main/m/mdevctl/mdevctl_0.81-1_all.deb
    dpkg -i /tmp/mdevctl_0.81-1_all.deb
}

unbind_nouveau(){
    for i in `ls /sys/bus/pci/drivers/nouveau/ |grep ":"`; 
       do
       echo $i > /sys/bus/pci/drivers/nouveau/unbind;
    done
}

install_grid(){
    cd /tmp/
    curl -L -O $nvidia_url 
    sh $nvidia_pkg --dkms -s 
    echo "drivers in install ok"
    rm /tmp/$nvidia_pkg
}


echo "这是一个自动配置Nvidia-vGPU的脚本"
echo "本脚本不检测硬件类型，请自己确保符合条件"

read -p "请按y/Y继续" configure
if [ $configure -eq "y" ] || [ $configure -eq "Y" ] 
then
echo "开始检测引导类型"
mkdir /opt/foxi_backup > /dev/null 2>&1
grub_check
else
echo "输入错误，脚本退出"
exit 0
fi
modiy_modules
pkg_install
unbind_nouveau
install_grid


echo "脚本执行完成，请重启"
echo "其中grub和modules文件已经备份到/opt/foxi_backup目录下"
echo "重启之后，请运行命令 lsmod|grep nvidia 有输出即代表成功"