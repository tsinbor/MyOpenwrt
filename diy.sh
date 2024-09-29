#!/bin/bash

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../feeds/luci/applications
  cd .. && rm -rf $repodir
}
# 修改默认IP
sed -i 's/192.168.31.3/192.168.1.1/g' package/base-files/files/bin/config_generate

#tailscale
rm -rf package/luci-app-tailscale
git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale
sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile


#重新安装openclash及内核
rm -rf feeds/luci/applications/luci-app-openclash
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

CLASH_TUN_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/contents/master/premium\?ref\=core | grep download_url | grep amd64 | awk -F '"' '{print $4}' | grep -v 'v3')
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64-v3.tar.gz"
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"

mkdir feeds/luci/applications/luci-app-openclash/root/etc/openclash/core
wget -qO- $CLASH_TUN_URL | gunzip -c > feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_tun
wget -qO- $CLASH_META_URL | tar xOvz > feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_meta
wget -qO- $GEOIP_URL > feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoIP.dat
wget -qO- $GEOSITE_URL > feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoSite.dat

chmod +x feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash*

#添加ADguardHome
rm -rf package/luci-app-adguardhome
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
mkdir -p files/usr/bin/AdGuardHome

AGH_CORE=$(curl -sL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | grep /AdGuardHome_linux_${1} | awk -F '"' '{print $4}')

wget -qO- $AGH_CORE | tar xOvz > files/usr/bin/AdGuardHome/AdGuardHome

chmod +x files/usr/bin/AdGuardHome/AdGuardHome

./scripts/feeds update -a
./scripts/feeds install -a
