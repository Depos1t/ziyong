#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Aria2
#	Version: 1.1.0
#	Author: Toyo
#	Blog: https://doub.io/shell-jc4/
#=================================================
sh_ver="1.1.0"
file="/root/.aria2"
aria2_conf="/root/.aria2/aria2.conf"
aria2_log="/root/.aria2/aria2.log"
Folder="/usr/local/aria2"
aria2c="/usr/bin/aria2c"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 没有安装，请检查 !" && exit 1
	[[ ! -e ${aria2_conf} ]] && echo -e "${Error} Aria2 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}
check_pid(){
	PID=`ps -ef| grep "aria2c"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_new_ver(){
	aria2_new_ver=$(wget -qO- "https://github.com/q3aql/aria2-static-builds/tags"| grep "/q3aql/aria2-static-builds/releases/tag/"| head -n 1| awk -F "/tag/v" '{print $2}'| sed 's/\">//')
	if [[ -z ${aria2_new_ver} ]]; then
		echo -e "${Error} Aria2 最新版本获取失败，请手动获取最新版本号[ https://github.com/q3aql/aria2-static-builds/releases ]"
		stty erase '^H' && read -p "请输入版本号 [ 格式如 1.33.1 ] :" aria2_new_ver
		[[ -z "${aria2_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 检测到 Aria2 最新版本为 [ ${aria2_new_ver} ]"
	fi
}
Download_aria2(){
	cd "/usr/local"
	if [[ ${bit} == "x86_64" ]]; then
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-64bit-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-64bit-build1"
	else
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-32bit-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-32bit-build1"
	fi
	[[ ! -e "${Aria2_Name}.tar.bz2" ]] && echo -e "${Error} Aria2 压缩包下载失败 !" && exit 1
	tar jxvf "${Aria2_Name}.tar.bz2"
	[[ ! -e "/usr/local/${Aria2_Name}" ]] && echo -e "${Error} Aria2 解压失败 !" && rm -rf "${Aria2_Name}.tar.bz2" && exit 1
	mv "/usr/local/${Aria2_Name}" "${Folder}"
	[[ ! -e "${Folder}" ]] && echo -e "${Error} Aria2 文件夹重命名失败 !" && rm -rf "${Aria2_Name}.tar.bz2" && rm -rf "/usr/local/${Aria2_Name}" && exit 1
	rm -rf "${Aria2_Name}.tar.bz2"
	cd "${Folder}"
	make install
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 主程序安装失败！" && rm -rf "${Folder}" && exit 1
	chmod +x aria2c
	echo -e "${Info} Aria2 主程序安装完毕！开始下载配置文件..."
}
Download_aria2_conf(){
	mkdir "${file}" && cd "${file}"
	wget --no-check-certificate -N "http://ozxlj8ku3.bkt.clouddn.com/aria2.conf"
	[[ ! -s "aria2.conf" ]] && echo -e "${Error} Aria2 配置文件下载失败 !" && rm -rf "${file}" && exit 1
	wget --no-check-certificate -N "http://ozxlj8ku3.bkt.clouddn.com/dht.dat"
	[[ ! -s "dht.dat" ]] && echo -e "${Error} Aria2 DHT文件下载失败 !" && rm -rf "${file}" && exit 1
	echo '' > aria2.session
}
Service_aria2(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate http://ozxlj8ku3.bkt.clouddn.com/aria2_centos -O /etc/init.d/aria2; then
			echo -e "${Error} Aria2服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/aria2
		chkconfig --add aria2
		chkconfig aria2 on
	else
		if ! wget --no-check-certificate http://ozxlj8ku3.bkt.clouddn.com/aria2_debian /etc/init.d/aria2; then
			echo -e "${Error} Aria2服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/aria2
		update-rc.d -f aria2 defaults
	fi
	echo -e "${Info} Aria2服务 管理脚本下载完成 !"
}
Installation_dependency(){
	if [[ ${release} = "centos" ]]; then
		yum update
		yum -y groupinstall "Development Tools"
	else
		apt-get update
		apt-get install build-essential -y
	fi
}
Install_aria2(){
	[[ -e ${aria2c} ]] && echo -e "${Error} Aria2 已安装，请检查 !" && exit 1
	check_sys
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装 主程序..."
	check_new_ver
	Download_aria2
	echo -e "${Info} 开始下载/安装 配置文件..."
	Download_aria2_conf
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_aria2
	Read_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_aria2
}
Start_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Aria2 正在运行，请检查 !" && exit 1
	/etc/init.d/aria2 start
}
Stop_aria2(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Aria2 没有运行，请检查 !" && exit 1
	/etc/init.d/aria2 stop
}
Restart_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/aria2 stop
	/etc/init.d/aria2 start
}
Set_aria2(){
	check_installed_status
	vim ${aria2_conf}
	Restart_aria2
}
Read_config(){
	[[ ! -e ${aria2_conf} ]] && echo -e "${Error} Aria2 配置文件不存在 !" && exit 1
	conf_text=$(cat ${aria2_conf}|grep -v '#')
	aria2_dir=$(echo -e "${conf_text}"|grep "dir="|awk -F "=" '{print $NF}')
	aria2_rpc_port=$(echo -e "${conf_text}"|grep "rpc-listen-port="|awk -F "=" '{print $NF}')
	aria2_rpc_secret=$(echo -e "${conf_text}"|grep "rpc-secret="|awk -F "=" '{print $NF}')
}
View_Log(){
	[[ ! -e ${aria2_log} ]] && echo -e "${Error} Aria2 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo
	tail -f ${aria2_log}
}
Uninstall_aria2(){
	check_installed_status "un"
	echo "确定要卸载 Aria2 ? (y/N)"
	echo
	stty erase '^H' && read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		Save_iptables
		cd "${Folder}"
		make uninstall
		cd ..
		rm -rf "${Folder}"
		rm -rf "${file}"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del aria2
		else
			update-rc.d -f aria2 remove
		fi
		rm -rf "/etc/init.d/aria2"
		echo && echo "Aria2 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${aria2_rpc_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${aria2_rpc_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${aria2_rpc_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${aria2_rpc_port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Update_Shell(){
	echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/aria2.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 检测最新版本失败 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(默认: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/aria2.sh && chmod +x aria2.sh
			echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "当前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
echo && echo -e " Aria2 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc4 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 Aria2
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 Aria2
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 Aria2
 ${Green_font_prefix}4.${Font_color_suffix} 停止 Aria2
 ${Green_font_prefix}5.${Font_color_suffix} 重启 Aria2
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 修改 配置文件
 ${Green_font_prefix}7.${Font_color_suffix} 查看 日志信息
————————————" && echo
if [[ -e ${aria2c} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
stty erase '^H' && read -p " 请输入数字 [0-7]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_aria2
	;;
	2)
	Uninstall_aria2
	;;
	3)
	Start_aria2
	;;
	4)
	Stop_aria2
	;;
	5)
	Restart_aria2
	;;
	6)
	Set_aria2
	;;
	7)
	View_Log
	;;
	*)
	echo "请输入正确数字 [0-7]"
	;;
esac