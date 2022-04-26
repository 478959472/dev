#!/bin/bash
############################################# 配置环境变量开始 #############################################
# 告诉 bash 如果任何语句的执行结果不是 true 则应该退出
set -e
# 设置请求协议
REQUEST_PROTOCOL=https
# 设置 Harbor 服务器地址和端口号
HARBOR_URL=192.169.2.237:8004
# 设置访问 Harbor 服务器的用户名
HARBOR_USER=admin
# 设置访问 Harbor 服务器的密码
HARBOR_PASSWD=Harbor12345
############################################# 配置环境变量结束 #############################################

############################################# 配置运行参数开始 #############################################
# 需要推送的项目名称
REPOSITY_NAME=$1
# 需要推送的镜像名称
IMAGE_NAME=$2
# JENKINS构建项目路径
WORKSPACE=$3
# 组装镜像全称
FULL_IMAGE_PATH="${REPOSITY_NAME}/${IMAGE_NAME}"
if [ $# != 3 ] ; then
	echo "请求参数不符合规范，请参考源码进行调用！（参考格式:sh xxx.sh rms-platform rms-gateway JENKINS构建项目的路径变量）"
	exit 0
fi
echo "本次程序调用请求参数：REPOSITY_NAME=${REPOSITY_NAME}，IMAGE_NAME=${IMAGE_NAME}，WORKSPACE=${WORKSPACE}"
############################################# 配置运行参数开始 #############################################

############################################# 构建镜像前置准备 #############################################
# 创建临时构建文件夹
# cd /var/lib/jenkins/workspace/01-rms-gateway-docker
cd ${WORKSPACE}
if [ -d "build" ]; then
  rm -rf build
fi
mkdir -p build/tools/linux
# 收集构建资源
cp ../build/rms-console/require/* build/ && cp rms-system/target/*.jar build/ && cp rms-system/target/classes/Dockerfile build/ && cp -R tools/linux/VideoEncoder build/tools/linux/ && cp -R config build/
# 获取构建后最新的应用版本号
cd build/
for filename in $(ls $PWD)
do
	# 以后项目名称采用中杠的时候，此处可以优化为：if [[ "${filename}" == ${IMAGE_NAME}* ]];
	if [[ "${filename}" =~ rms* ]];
	then
		echo "当前处理的应用程序文件全称：${filename}"
		appname=${filename}
		substr=${filename##*-}
		buildversion=${substr%.*}
	fi
done
echo "本次计划构建的版本号为：${buildversion}"
# 业务阻断判断
if [ ! -n "${buildversion}" ]; then
	echo "未能正确截取应用程序的版本号，请确定 POM 文件打包格式的正确性，本次构建过程已终止！"
	# 删除临时目录
	cd ../ && rm -rf build
	exit 0
fi
############################################# 构建镜像前置准备 #############################################

############################################# 构建镜像流程开始 #############################################
# 构建 Docker 镜像
docker build -t ${HARBOR_URL}/${FULL_IMAGE_PATH}:${buildversion} .
############################################# 构建镜像流程结束 #############################################

############################################# 推送镜像流程开始 #############################################
# 登录 Harbor 仓库
echo "${HARBOR_PASSWD}" | docker login ${HARBOR_URL} --username ${HARBOR_USER} --password-stdin

# 推送镜像到仓库
docker push ${HARBOR_URL}/${FULL_IMAGE_PATH}:${buildversion}

# 8. 删除本地构建镜像
docker rmi ${HARBOR_URL}/${FULL_IMAGE_PATH}:${buildversion}

# 9. 删除本地临时构建文件夹
cd ../ && rm -rf build
echo "项目打包完成，推送镜像仓库：'${FULL_IMAGE_PATH}'，推送镜像版本：'${buildversion}'。"
############################################# 推送镜像流程结束 #############################################
