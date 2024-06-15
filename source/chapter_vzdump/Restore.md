# 16.6. 恢复

可以在Web GUI或通过如下命令恢复备份文档。

`pct restore` 容器恢复命令

`qm restore` 虚拟机恢复命令

详情可查看相应的手册。


## 16.4.1恢复限速

恢复大型备份文件是非常耗费资源的，特别是从读取备份存储和写入目标存储的操作，会给存储带来很大压力，并挤占其他虚拟机对存储的访问请求，影响其他虚拟机的正常运行。

为避免该问题，可以对备份任务设置限速。Proxmox VE为备份恢复提供了两种限速：

- 读限速：用于限制从备份存储读取的最大速度。

- 写限速：用于限制向指定存储写入的最大速度。

读限速间接影响写限速，因为备份恢复过程中，写入数据量不可能超出读取数据量。因此较低的读限速将覆盖较高的写限速。只有在目标存储设置了`Data.Allocate`权限时，较高的读限速才会覆盖写限速。

在恢复命令行中可以使用`‘—bwlimit <integer>’`参数来设置特定恢复任务的限速。限度单位为Kibit/s，也就是说，设置为10240时相当于读限速10MiB/s，剩余带宽可供其他虚拟机使用，从而确保正常运行。

**注意**

可以设置bwlimit为’0’，禁用限速。这可以帮助你尽快恢复重要虚拟机。（存储需要设置‘Data.Allocate’权限）

大多数情况下，存储可用读写带宽是保持不变的。所以可以为每个存储设置默认限速。参考命令如下：

```
# pvesm set STORAGEID --bwlimit KIBs
```


## 16.6.2. 实时还原

恢复一个大型的备份，会占用很大的时间，且在此期间无法访问虚拟机。存储在备份服务器上的备份可以通过实时还原选项来减少等待时间。

在GUI中勾选`实时还原`或者使用`qm restore --live-restore`会时虚拟机在还原开始后，立即启动。并在后台复制数据，优先处理 VM 正在主动访问的区块。

注意，这有两个警告：

- 在实时还原期间，VM 将以有限的磁盘读取速度运行，因为数据必须从备份服务器加载（加载后，它立即在目标存储上可用，因此访问数据两次只会在第一次产生性能损失）。写入速度基本上不受影响。

- 只要实时还原失败，VM 将处于未定义状态————也就是说，数据可能没有从备份中完整复制过来，并且很可能丢失在还原期间写入的任何数据。

这种还原模式对于大型 VM 特别有用，其中初始操作只需要少量数据，例如 Web 服务器————一旦操作系统和必要的服务启动，VM 即可运行，其他数据会在后台继续复制。

## 16.6.3. 文件还原

在GUI的`备份`选项中，点击`文件还原`按钮可直接浏览备份包中的文件。此功能只在Proxmox 备份服务器后端有效。

对于容器，第一层是pxar压缩存档，可以自由打开和浏览。

对于虚拟机，第一层展现的是可打开的磁盘映像列表。在最基本的情况下，这将是一个名为`part`的条目，表示一个分区表，其中包含在磁盘映像上上找到的每个分区列表。注意，并非所有数据都可以访问（如，不支持文件系统，存储技术等）

可以点击`下载`按钮下载目录或者文件，随后会被压缩成一个zip文档。

若要对包含不安全数据的VM映像进行安全访问，将启动临时 VM（不作为来宾可见）。这并不意味着从此类存档下载的数据本质上是安全的，但它避免了将虚拟机管理程序系统暴露在危险之中。VM 将在超时后自行停止。从用户的角度来看，整个过程都是透明的。


