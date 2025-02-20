#!/bin/bash
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"
mkdir -p  /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件 yml传入环境变量ENABLE_PPPOE等 写入配置文件 供99-custom.sh读取
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings
# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译..."



# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl uci"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-opkg-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
# 加入 coreutils 相关组件
PACKAGES="$PACKAGES coreutils"
PACKAGES="$PACKAGES coreutils-base64 coreutils-basename coreutils-cat coreutils-chgrp"
PACKAGES="$PACKAGES coreutils-chmod coreutils-chown coreutils-cp coreutils-cut"
PACKAGES="$PACKAGES coreutils-date coreutils-dd coreutils-df coreutils-dir coreutils-du"
PACKAGES="$PACKAGES coreutils-echo coreutils-env coreutils-expr coreutils-factor"
PACKAGES="$PACKAGES coreutils-false coreutils-fold coreutils-head coreutils-hostid"
PACKAGES="$PACKAGES coreutils-id coreutils-ln coreutils-ls coreutils-md5sum"
PACKAGES="$PACKAGES coreutils-mkdir coreutils-mktemp coreutils-mv coreutils-nice"
PACKAGES="$PACKAGES coreutils-nohup coreutils-nproc coreutils-paste coreutils-printenv"
PACKAGES="$PACKAGES coreutils-pwd coreutils-readlink coreutils-realpath coreutils-rm"
PACKAGES="$PACKAGES coreutils-rmdir coreutils-sha256sum coreutils-shuf coreutils-sleep"
PACKAGES="$PACKAGES coreutils-sort coreutils-split coreutils-stat coreutils-stty"
PACKAGES="$PACKAGES coreutils-tail coreutils-tee coreutils-test coreutils-touch"
PACKAGES="$PACKAGES coreutils-tr coreutils-true coreutils-truncate coreutils-tty"
PACKAGES="$PACKAGES coreutils-uname coreutils-uniq coreutils-uptime coreutils-users"
PACKAGES="$PACKAGES coreutils-wc coreutils-whoami"

PACKAGES="$PACKAGES openssh-sftp-server"
# 增加几个必备组件 方便用户安装iStore
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
