#!/usr/bin/python
# encoding:utf-8

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

print('''
=======>自动化容器启动脚本调用入参说明（每组入参请采用空格隔开）：
=======>第一组必传入参：需要操作的仓库项目名/仓库镜像名（示例：rms-platform/rms-gateway）
=======>第二组必传入参：自定义应用程序的容器名，单点部署建议采用镜像名，单点集群可随意命名（示例：rms-gateway）
=======>第三组必传入参：应用程序 外部响应:内部暴露端口号集合，多组采用英文逗号隔开（示例：9000:9000）
=======>第四组必传入参：应用程序除日志、个性配置文件夹以外的自定义映射路径集合，多组采用英文逗号隔开（示例：/opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data）
=======>第五组必传入参：应用程序部署配置文件概要环境（示例：dev、test、pre、prod）
=======>第六组必传入参：是否需要从仓库拉取最新镜像。不管构建版本的本地镜像是否存在（0：不拉取最新镜像，1:拉取仓库最新镜像）
=======>第七组非必传参：指定容器启动的镜像版本号。不传参则每次拉取镜像仓库中最新版本镜像并启动容器，传参则采用启动该版本的镜像应用容器
=======> >>>>>本自动化容器启动脚本建议置于 /opt/java 文件夹下。参数六和参数七不互斥，如果需要拉取最新镜像，不管参数七传入的版本，本地是否存在，都会去仓库拉取最新镜像版本<<<<<

''')
# 接收参数

if len(sys.argv) < 7:
    print(sys.argv)
    print("参数错误，请检查参数个数")
print(sys.argv)
image_name, container_name, host_container_port, path_mapping, environment, get_last = sys.argv[1:7]

version = ""
if len(sys.argv) > 7:
    version = sys.argv[7]

str = '''
=======>调用自动化容器启动脚本请求参数：
=======>应用镜像仓库：{0}
=======>应用容器名称：{1}
=======>应用端口集合：{2}
=======>应用挂载集合：{3}
=======>应用配置概要：{4}
=======>是否最新镜像：{5}
=======>指定镜像版本：{6}
'''.format(image_name, container_name, host_container_port, path_mapping, environment, get_last, version)

print(str)

# 登录拉取镜像
harbor_url = "rep-rms.monyun.cn:9261"
# 设置访问 Harbor 服务器的用户名
harbor_user = "admin"
# 设置访问 Harbor 服务器的密码
harbor_passwd = "Montnets@2020"

command = 'echo hello'
process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
print(process.communicate())