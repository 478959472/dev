#!/usr/bin/python
# encoding:utf-8
import os
import requests
import json
import sys
import subprocess

print('''\033[31m

#########################################################################################################
### Desc:         自动化容器启动脚本 —— 适用于本地、开发、测试、预发布、生产环境                        
### Date:         2022-04-24                                                                          
### Author:       chneyun                                                                             
### E-Mail:       478959472@qq.com                                                                    
### Version:      V1.0                                                                                
#########################################################################################################

\033[0m''')

print('''\033[33m
=======>项目标准规范约定：
=======>1、应用程序默认部署根目录： /opt/java
=======>2、应用程序默认日志根目录（无需手动挂载，容器启动默认挂载）： /opt/java/logs/container_name
=======>3、应用程序个性配置文件夹（无需手动挂载，容器启动默认挂载）： /opt/java/container_name/config\033[0m
\033[31m=======> >>>>>标准规范约定，日志目录和 Dockerfile 脚本非此标准设置则不适用于本自动化容器启动脚本<<<<<\033[0m
''')

print('''\033[32m
=======>自动化容器启动脚本调用入参说明（每组入参请采用空格隔开）： 
=======>第一组必传入参：需要操作的仓库项目名/仓库镜像名（示例：rms-platform/rms-gateway）  
=======>第二组必传入参：自定义应用程序的容器名，单点部署建议采用镜像名，单点集群可随意命名（示例：rms-gateway）  
=======>第三组必传入参：应用程序 外部响应:内部暴露端口号集合，多组采用英文逗号隔开（示例：9000:9000）  
=======>第四组必传入参：应用程序除日志、个性配置文件夹以外的自定义映射路径集合，多组采用英文逗号隔开（示例：/opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data）  
=======>第五组必传入参：应用程序部署配置文件概要环境（示例：dev、test、pre、prod）  
=======>第六组必传入参：JVM启动参数，原参数（是否删除旧镜像）示例为0或1，为兼容原参数，若填入0或1，则不配置JVM参数，非0和1则视为设置JVM参数。(示例：-Xmn2G -Xms4G -Xmx8G -XX:SurvivorRatio=8)  
=======>第七组必传入参：应用程序网络模式，示例：host、none、bridge、container。host：使用 --net=host 指定；none：使用 --net=none 指定；bridge：使用 --net=bridge 指定；container：使用 --net=container:NAME_or_ID 指定。  
=======>第八组非必传参：指定容器启动的镜像版本号。不传参则每次拉取镜像仓库中最新版本镜像并启动容器，传参则采用启动该版本的镜像应用容器  
=======> >>>>>本自动化容器启动脚本建议置于 /opt/java 文件夹下。<<<<<  
\033[0m
''')
# 接收参数

if len(sys.argv) < 8:
    print(sys.argv)
    print('''\033[31m
=======>调用自动化容器启动脚本请求参数不符合规范，本次构建异常终止！！！ \033[0m \033[32m
=======>调用格式：sh xxx.sh 仓库项目名称/应用镜像名称 应用容器名称 外部响应:内部暴露端口号集合（多个采用英文逗号隔开） 应用程序自定义映射路径集合（多个采用英文逗号隔开） 配置文件概要 是否每次拉取最新镜像 指定镜像版本启动容器。  
=======>调用示例：sh run-latest.sh rms-platform/rms-gateway rms-gateway 9000:9000 /opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data dev '-Xmn2G -Xms4G -Xmx8G -XX:SurvivorRatio=8' V1.0.1.2 bridge。 
\033[0m    
    ''')
    sys.exit(0)
print(sys.argv)
FULL_IMAGE_PATH, CONTAINER_NAME, APP_PORTS, VOLUME_PATHS, APP_PROFILES_ACTIVE, JVM_STARTUP_PARAM, NETWORK_MODE = sys.argv[
                                                                                                                 1:8]

DETERMINE_VERSION = ""
if len(sys.argv) > 8:
    DETERMINE_VERSION = sys.argv[8]

APP_BASE_PATH = "/opt/java"
LOGS_BASE_PATH = "/opt/java/logs"
CONFIG_FOLDER = "config"

REQUEST_PROTOCOL = "https"
REPOSITORY_URL = "192.169.2.237:8004"
REPOSITORY_USER = "admin"
REPOSITORY_PWD = "Harbor12345"
IMAGE_TAGS = None

JVM_FLAG = 0
if JVM_STARTUP_PARAM == 0 or JVM_STARTUP_PARAM == 1:
    JVM_FLAG = 1
    print ("\033[31m=======>调用自动化容器启动脚本JVM参数为:[{0}]，为0或1JVM参数默认配置4G内存（-Xmx4G）。\033[0m".format(JVM_STARTUP_PARAM))

str = '''\033[32m
=======>调用自动化容器启动脚本请求参数：
=======>应用镜像仓库：{0}
=======>应用容器名称：{1}
=======>应用端口集合：{2}
=======>应用挂载集合：{3}
=======>应用配置概要：{4}
=======>JVM启动参数：{5}
=======>网络模式：   {6}
=======>指定镜像版本：{7} 
\033[0m
'''.format(FULL_IMAGE_PATH, CONTAINER_NAME, APP_PORTS, VOLUME_PATHS, APP_PROFILES_ACTIVE, JVM_STARTUP_PARAM,
           NETWORK_MODE, DETERMINE_VERSION)
print(str)
# 配置环境变量结束

# 操作前置准备开始
# url = "{0}://{1}/api/repositories/{2}/tags"\
#     .format(REQUEST_PROTOCOL, REPOSITORY_URL, FULL_IMAGE_PATH)
# print "Harbor 服务器地址：" + url
# headers = {
#     'cache-control': 'no-cache',
#     'content-type': 'application/json',
# }
# # ,  cert='/etc/pki/ca-trust/source/anchors/ca.crt', verify='path_rootCA'
# response = requests.post(url, headers=headers,  auth=(REPOSITORY_USER, REPOSITORY_PWD), cert='/etc/pki/ca-trust/source/anchors/mycert.pem')
# print response

harbor_url = "{0}://{1}/api/repositories/{2}/tags".format(REQUEST_PROTOCOL, REPOSITORY_URL, FULL_IMAGE_PATH)


def run_cmd(cmd_str):
    process = subprocess.Popen(cmd_str.split(), stdout=subprocess.PIPE)
    communicate = process.communicate()
    if process.returncode == 0:
        return communicate[0] + ""
    else:
        print '命令执行错误：{0}'.format(process.stderr)
        sys.exit(0)


if DETERMINE_VERSION == '':
    cmd = "curl -s -k -u {0}:{1} ".format(REPOSITORY_USER, REPOSITORY_PWD) + harbor_url
    res = run_cmd(cmd)
    html_json = json.loads(res)
    last = html_json[-1]
    try:
        IMAGE_TAGS = last["name"]
        print IMAGE_TAGS
    except:
        print ("版本获取失败")
        sys.exit(0)

curent = run_cmd("pwd")
TEMP_FOLDER = "${PWD}/${CONTAINER_NAME}/temp"

run_cmd