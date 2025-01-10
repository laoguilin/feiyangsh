#!/bin/bash

# 定义颜色变量
RED='\033[0;31m'
GRE='\033[0;32m'
NC='\033[0m' # 重置颜色
PROXY_IMG="docker.zhai.cm/youshandefeiyang/allinone" #设置代理加速拉取镜像

# 定义信号处理函数
trap_ctrl_c() {
    echo -e "\n${NC}"
    exit 1
}

# 捕获 SIGINT 信号
trap trap_ctrl_c SIGINT

echo -e "${RED}本脚本在ubuntu环境运行正常，其它系统请自行测试。按任意键继续执行或按Ctrl+c退出脚本。${NC}"
image_name=$(docker inspect --format '{{.Config.Image}}' allinone 2>/dev/null)
read -n 1 -s -r -p ""
echo ""

# 检测是否存在名称为allinone的容器
existing_container=$(docker ps -a --filter "name=allinone" --format "{{.Names}}")
if [ -n "$existing_container" ]; then
    while true; do
        echo -e ${RED}
        read -p "allinone容器已存在，是否重新部署？(y/n): " choice
        echo -e ${NC}
        case $choice in
            [yY])
                docker rm -f allinone
                docker rmi $image_name:latest
                break
                ;;
            [nN])
                echo -e "${RED}你选择不重新部署，退出脚本。${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}输入有误，请输入y或n 。${NC}"
                ;;
        esac
    done
fi

# 获取 -tv 参数
while true; do
echo -e ${GRE}
    read -p "请选择是否开启直播（输入 y 或 n）：" tv_input
echo -e ${NC}
    case $tv_input in
        [yY])
            tv="true"
            break
            ;;
        [nN])
            tv="false"
            break
            ;;
        *)
            echo -e "${RED}输入有误，请输入 y 或 n。${NC}"
            ;;
    esac
done

# 获取 -aesKey 参数
while true; do
echo -e ${GRE}
    read -p "请输入你的aesKey ：" aesKey
echo -e ${NC}
    if [[ $aesKey =~ ^[a-zA-Z0-9]{32}$ ]]; then
        break
    else
        echo -e "${RED}输入有误，请输入正确的aesKey。${NC}"
    fi
done

# 获取 -userid 参数
while true; do
echo -e ${GRE}
    read -p "请输入你的userid ：" userid
echo -e ${NC}
    if [[ $userid =~ ^[0-9]+$ ]]; then
        break
    else
        echo -e "${RED}输入有误，请输入正确的userid。${NC}"
    fi
done

# 获取 -token 参数
while true; do
echo -e ${GRE}
    read -p "请输入你的token ：" token
echo -e ${NC}
    if [[ $token =~ ^[a-zA-Z0-9]{142}$ ]]; then
        break
    else
        echo -e "${RED}输入有误，请输入正确的token。${NC}"
    fi
done

# 选择网络模式
while true; do
    echo -e "${RED}请选择 docker 容器的网络模式：1. 旁路由模式(openwrt做旁路由时推荐使用)。 2.主路由模式。${NC}"
echo -e ${GRE}
    read -p "请输入选项（1 或 2）：" network_choice
echo -e ${NC}
    case $network_choice in
        1)
            container_id=$(docker run -d --restart always --net=host --privileged=true --name allinone $PROXY_IMG "-tv=$tv" "-aesKey=$aesKey" "-userid=$userid" "-token=$token")
            break
            ;;
        2)
            container_id=$(docker run -d --restart always --privileged=true -p 35455:35455 --name allinone $PROXY_IMG "-tv=$tv" "-aesKey=$aesKey" "-userid=$userid" "-token=$token")
            break
            ;;
        *)
            echo -e "${RED}输入有误，请输入 1 或 2。${NC}"
            ;;
    esac
done

# 获取本机IP
local_ip=$(ip -4 addr show scope global | grep -oP 'inet \K[\d.]+' | head -n 1)

# 查看容器日志并判断启动状态
log_output=$(docker logs $container_id 2>/dev/null)
if [[ $log_output == *"Custom AES key set successfully."* ]]; then
    echo -e "${GRE}容器启动成功，你的直播源地址是：http://$local_ip:35455/tv.m3u${NC}"
else
    echo -e "${RED}容器启动失败，请检查各项参数后重新运行本脚本。${NC}"
fi

exit 0
