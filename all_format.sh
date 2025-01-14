#!/bin/bash

#主菜单
show_menu() {
    echo "-------------------"
    echo "1)  肥羊allinone选项    "
    echo "2)  allinone_format选项   "
    echo "0)      退出       "
    echo "     [ Ctrl+C ]    "
    echo "-------------------"
}

#肥羊allinone选项
allinone_cd(){
    echo "    allinone选项：  "
    echo "~~~~~~~~~~~~~~~~~~~"
    echo "1) 部署肥羊allinone"
    echo "2) 卸载肥羊allinone"
    echo "0)   返回主菜单     "
    echo "~~~~~~~~~~~~~~~~~~~"
}

#allinone_format选项
format_cd(){
    echo "======================"
    echo "    format选项：  "
    echo "~~~~~~~~~~~~~~~~~~~~~"
    echo "1) 部署allinone_format"
    echo "2) 卸载allinone_format"
    echo "0)   返回主菜单     "
    echo "~~~~~~~~~~~~~~~~~~~~~"
}
#安装肥羊allinone
allinone_ins() {
#查询是否存在allinone容器，及容器所使用的镜像名
existing_container=$(docker ps -a --filter "name=allinone" --format "{{.Names}}")
image_name=$(docker inspect --format '{{.Config.Image}}' allinone 2>/dev/null)
if [ -n "$existing_container" ]; then
local tv
local aesKey
local userid
local token
    while true; do
                read -p "allinone容器已存在，是否重新部署？(y/n): " all_id
        case $all_id in
            [yY])
                docker stop allinone
                docker rm allinone
                docker rmi $image_name
                break
                ;;
            [nN])
                echo "你选择不重新部署,返回菜单。"
                break
                ;;
            *)
                echo "输入有误，请输入y或n 。"
                ;;
        esac
    done
else
        echo "没有检测到allinone容器，继续进行部署。"
    # 获取 -tv 参数
    while true; do
        read -p "请选择是否开启直播（输入 y 或 n）：" tv_input
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
                echo "输入有误，请输入 y 或 n。"
                ;;
        esac
    done

    # 获取 -aesKey 参数
    while true; do
        read -p "请输入你的aesKey ：" aesKey
        if [[ $aesKey =~ ^[a-zA-Z0-9]{32}$ ]]; then
            break
        else
            echo "输入有误，请输入正确的aesKey。"
        fi
    done

    # 获取 -userid 参数
    while true; do
        read -p "请输入你的userid ：" userid
        if [[ $userid =~ ^[0-9]+$ ]]; then
            break
        else
            echo "输入有误，请输入正确的userid。"
        fi
    done

    # 获取 -token 参数
    while true; do
        read -p "请输入你的token ：" token
        if [[ $token =~ ^[a-zA-Z0-9]{142}$ ]]; then
            break
        else
            echo "输入有误，请输入正确的token。"
        fi
    done
    global_tv=$tv
    global_aesKey=$aesKey
    global_userid=$userid
    global_token=$token
        while true; do
        echo "请选择 docker 容器的网络模式：1. 旁路由模式(openwrt做旁路由时推荐使用)。 2.主路由模式。"
        read -p "请输入选项（1 或 2）：" network_choice
        case $network_choice in
            1)
                container_id=$(docker run -d --restart always --net=host --privileged=true --name allinone youshandefeiyang/allinone "-tv=$global_tv" "-aesKey=$global_aesKey" "-userid=$global_userid" "-token=$global_token")
                break
                ;;
            2)
                container_id=$(docker run -d --restart always --privileged=true -p 35455:35455 --name allinone youshandefeiyang/allinone "-tv=$global_tv" "-aesKey=$global_aesKey" "-userid=$global_userid" "-token=$global_token")
                break
                ;;
            *)
                echo -e "输入有误，请输入 1 或 2。"
                ;;
        esac
    done
        while true; do
        local_ip=$(ip -4 addr show scope global | grep -oP 'inet \K[\d.]+' | head -n 1)
        log_output=$(docker logs $container_id 2>/dev/null)
                if [[ $log_output == *"Custom AES key set successfully."* ]]; then
                        echo "容器启动成功，你的直播源地址是：http://$local_ip:35455/tv.m3u"
                else
                        echo "容器启动失败，请检查各项参数后重新运行本脚本。"
                fi
                exit 0
        done
fi
}

#安装allinone_format容器
format_ins(){
    existing_container=$(docker ps -a --filter "name=allinone_format" --format "{{.Names}}")
    image_name=$(docker inspect --format '{{.Config.Image}}' allinone_format 2>/dev/null)
    if [ -n "$existing_container" ]; then
        while true; do
            read -p "allinone_format容器已存在，是否重新安装？(y/n): " format_id
            case $format_id in
                [yY])
                    docker rm -f allinone_format
                    docker rmi $image_name
					echo "已成功删除旧容器和镜像。"
                    format_path
                    break
                    ;;
                [nN])
                    echo "你选择不重新部署，返回。"
                    break
                    ;;
                *)
                    echo "输入有误，请输入y或n 。"
                    ;;
            esac
        done
        else
        echo  "没有检测到allinone_format容器，继续执行部署。"
        format_path
        fi
        }
    #定义配置文件路径
        format_path(){
        while true; do
            echo "请选择配置文件路径："
            echo "1. 使用默认路径（./config）"
            echo "2. 输入自定义路径"
            read -p "请输入选择：" path_choice
            case $path_choice in
                1)
                    path="./config"
					echo "你选择了默认配置文件路径。"
                    break
                    ;;
                2)
                    read -p "请输入自定义路径：" custom_path
                    if [ -d "$custom_path" ]; then
                        path="$custom_path"
						echo "你输入的配置文件路径是：" "$custom_path"
                        break
                    else
                        echo "输入的路径不存在，请重新输入。"
                    fi
                    ;;
                *)
                    echo "输入有误，请输入 1 或 2。"
                    ;;
            esac
        done
                format_net
        }

        #选择容器网络模式
format_net(){
    while true; do
        echo -e "请选择 docker 容器的网络模式："
        echo "1. 旁路由模式。"
        echo "2. 主路由模式。"
        read -p "请输入选择：" network_id
        case $network_id in
            1)  
                echo "正在为你拉取镜像......"
                # 拉取镜像
                docker pull yuexuangu/allinone_format:latest
                # 检查拉取结果
                if [ $? -eq 0 ]; then
                    echo "镜像拉取成功，正在使用命令部署容器。"
                    container_id=$(docker run -d --restart=unless-stopped --pull=always --net=host -v "$path:/app/config" --name allinone_format yuexuangu/allinone_format:latest)
                    break
                else
                    echo "镜像拉取失败，请检查网络连接是否正常。"
                    continue
                fi
                ;;
            2)
                echo "正在为你拉取镜像......"
                # 拉取镜像
                docker pull yuexuangu/allinone_format:latest
                # 检查拉取结果
                if [ $? -eq 0 ]; then
                    echo "镜像拉取成功，正在使用命令部署容器。"
                    container_id=$(docker run -d --restart=unless-stopped --pull=always -v "$path:/app/config" -p 35456:35456 --name allinone_format yuexuangu/allinone_format:latest)
                    break
                else
                    echo "镜像拉取失败，请检查网络连接是否正常。"
                    continue
                fi
                ;;
            *)
                echo "输入有误，请输入 1 或 2。"
                ;;
        esac
    done
    format_url
}
        #检查容器是否启动成功，并输出访问路径
        format_url(){
        while true; do
            local_ip=$(ip -4 addr show scope global | grep -oP 'inet \K[\d.]+' | head -n 1)
            log_output=$(docker inspect --format '{{.State.Running }}' allinone_format)
            if [[ $log_output == *"true"* ]]; then
                echo "容器启动成功，访问地址：http://$local_ip:35456"
            else
                echo "容器启动失败，请检查各项参数后重新运行本脚本。"
            fi
            break
        done
                }


#卸载肥羊allinone
allinone_un(){
#查询是否存在allinone容器，及容器所使用的镜像名
existing_container=$(docker ps -a --filter "name=allinone" --format "{{.Names}}")
image_name=$(docker inspect --format '{{.Config.Image}}' allinone 2>/dev/null)
        if [ -n "$existing_container" ]; then
                while true; do
        read -p "请确认是否卸载allinone容器？(y/n): " choice
                case $choice in
            [yY])
                docker rm -f allinone
                break
                ;;
            [nN])
                echo -e "你选择不卸载allinone容器，退出脚本。"
                exit 0
                ;;
            *)
                echo -e "输入有误，请输入y或n 。"
                ;;
        esac
                done

                while true; do
        read -p "请确认是否删除allinone镜像？(y/n): " choice
                case $choice in
            [yY])
                docker rmi -f $image_name
                break
                ;;
            [nN])
                echo -e "你选择不删除allinone镜像，退出脚本。"
                exit 0
                ;;
            *)
                echo -e "输入有误，请输入y或n 。"
                ;;
        esac
                done
        fi
}

# 主循环
while true; do
    show_menu
    read -p "请选择操作: " id
    case "$id" in
        1)  # 安装肥羊allinone
            while true; do
                allinone_cd
                read -p "请输入选项 (0-2): " allinone_id
                case "$allinone_id" in
                    1) allinone_ins ;;
                    2) allinone_un ;;
                    0) echo "返回主菜单。" ; break ;;
                    *) echo "无效的选项，请输入 0-2。" ;;
                esac
            done
            ;;
        2)  # 安装allinone_format容器
            while true; do
                format_cd
                read -p "请输入选项 (0-2): " fourgtv_id
                case "$fourgtv_id" in
                    1) format_ins ;;
                    2) format_un ;;
                    0) echo "返回主菜单。" ; break ;;
                    *) echo "无效的选项，请输入 0-2。" ;;
                esac
            done
            ;;
        0) echo "退出脚本。"; exit 0 ;;
        *) echo "无效的选项，请输入 0-2。" ;;
    esac
done
