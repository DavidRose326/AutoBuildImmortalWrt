#!/bin/sh
# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
# 设置默认防火墙规则，方便虚拟机首次访问 WebUI
uci set firewall.@zone[1].input='ACCEPT'

# 设置主机名映射，解决安卓原生 TV 无法联网的问题
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"


# 计算网卡数量
count=0
for iface in /sys/class/net/*; do
  iface_name=$(basename "$iface")
  # 检查是否为物理网卡（排除回环设备和无线设备）
  if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
    count=$((count + 1))
  fi
done

# 检查配置文件pppoe-settings是否存在 该文件由build.sh动态生成
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "PPPoE settings file not found. Skipping." >> $LOGFILE
else
   # 读取pppoe信息($enable_pppoe、$pppoe_account、$pppoe_password)
   . "$SETTINGS_FILE"
fi

# 网络设置
uci set network.lan.ipaddr='192.168.1.2'
uci set network.gateway='192.168.1.1'
uci del dhcp.lan.ra_slaac
uci set dhcp.lan.limit='100'
uci set dhcp.lan.netmask='255.255.255.0'
uci set network.lan.dns='223.5.5.5 223.6.6.6 8.8.8.8'
uci set network.lan.broadcast='192.168.1.255'
uci add_list dhcp.lan.dhcp_option='6,192.168.1.2'
uci set dhcp.lan.force='1'
uci set dhcp.lan.ra='server'
uci set dhcp.lan.dhcpv6='server'

# /etc/config/firewall
uci del firewall.@zone[-1].network
uci add_list firewall.@zone[-1].network='lan'
uci add_list firewall.@zone[-1].network='ipv6'

# /etc/config/network
uci set network.ipv6=interface
uci set network.@interface[-1].proto='dhcpv6'
uci set network.@interface[-1].device='br-lan'
uci set network.@interface[-1].reqaddress='try'
uci set network.@interface[-1].reqprefix='auto'

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface

# 设置所有网口可连接 SSH
uci set dropbear.@dropbear[0].Interface=''
uci commit

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Compiled by wukongdaily"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
