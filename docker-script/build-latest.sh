#!/bin/bash
# Exit immediately if a simple command exits with a non-zero status.
# ./.build-latest.sh 5g-platform-test 5g-ccc-console ${WORKSPACE}
# ./build-latest.sh 5g-platform-test 5g-aim-editor /home/montnets/chenyun/workspase
set -e

printf "\e[1;31m#########################################################################################################\e[0m \n"
printf "\e[1;31m### Desc:         自动化镜像构建脚本 —— 适用于本地、开发环境					              ###\e[0m \n"
printf "\e[1;31m### Date:         2021-05-10                                                                          ###\e[0m \n"
printf "\e[1;31m### Author:       Rambo                                                                               ###\e[0m \n"
printf "\e[1;31m### E-Mail:       1071553975@qq.com                                                                   ###\e[0m \n"
printf "\e[1;31m### Version:      V2.0                                                                                ###\e[0m \n"
printf "\e[1;31m#########################################################################################################\e[0m \n\n"

############################################# 项目标准约定开始 #############################################
printf "\e[1;33m=======>项目标准规范约定：\e[0m \n"
printf "\e[1;33m=======>1、应用程序名称、日志文件根目录、镜像名称三者必须保持一致 \e[0m \n"
printf "\e[1;33m=======>2、自动化镜像构建脚本的镜像名称入参必须和上述命名保持一致 \e[0m \n"
printf "\e[1;33m=======>3、Dockerfile 的 WORKDIR 必须是 /opt/java/application-name/ 下 \e[0m \n"
printf "\e[1;31m=======> >>>>>标准规范约定，日志目录和 Dockerfile 脚本非此标准设置则不适用于本自动化容器构建脚本<<<<< \e[0m \n\n"

printf "\e[1;32m=======>自动化镜像构建脚本调用入参说明（每组入参请采用空格隔开）：\e[0m \n"
printf "\e[1;32m=======>第一组必传入参：目标 Harbor 仓库项目名称（示例：rms-platform） \e[0m \n"
printf "\e[1;32m=======>第二组必传入参：目标 Harbor 仓库镜像名称（示例：rms-gateway） \e[0m \n"
printf "\e[1;32m=======>第三组必传入参：JENKINS 项目空间构建路径（示例：\${WORKSPACE}） \e[0m \n"
printf "\e[1;31m=======> >>>>>>>自动化镜像构建脚本必须置于 JENKINS 的 WORKSPACE 文件夹下，非此目录则不适用该自动化镜像构建脚本！<<<<<<< \e[0m \n\n"
############################################# 项目标准约定结束 #############################################

############################################# 处理调用参数开始 #############################################
if [ ${#} != 3 ] ; then
	printf "\e[1;31m=======>调用自动化镜像构建脚本请求参数不符合规范，本次构建异常终止！！！ \e[0m \n"
	printf "\e[1;32m=======>调用参考格式：sh xxx.sh 仓库项目名称 应用程序镜像名称 JENKINS 项目空间构建路径 \e[0m \n"
	printf "\e[1;32m=======>调用参考示例：sh .build-latest.sh rms-platform rms-gateway \${WORKSPACE} \e[0m \n\n"
	exit 1
fi
PROJECT_NAME=${1}
IMAGE_NAME=${2}
WORKSPACE=${3}
printf "\e[1;32m=======>调用自动化镜像构建脚本请求参数：\n=======>目标 Harbor 仓库项目名称：${PROJECT_NAME}\n=======>目标 Harbor 仓库镜像名称：${IMAGE_NAME}\n=======>JENKINS 项目空间构建路径：${WORKSPACE} \e[0m\n\n"
############################################# 处理调用参数结束 #############################################

############################################# 配置环境变量开始 #############################################
REQUEST_PROTOCOL=https
REPOSITORY_URL=192.169.2.237:8004
REPOSITORY_USER=admin
REPOSITORY_PWD=Harbor12345
printf "\e[1;34m=======>自动化镜像构建脚本操作目标镜像仓库，采用 ${REPOSITORY_USER} 用户进行登录认证，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} 。\e[0m\n\n"
############################################# 配置环境变量结束 #############################################

############################################# 构建前置准备开始 #############################################
TEMP_FOLDER=build
cd ${WORKSPACE}
if [[ -d ${TEMP_FOLDER} ]]; then
  rm -rf ${TEMP_FOLDER}
fi
mkdir ${TEMP_FOLDER}
cp -r ../build/common/* ${TEMP_FOLDER}/ && cp target/*.jar ${TEMP_FOLDER}/ && cp target/classes/Dockerfile ${TEMP_FOLDER}/ 
cd ${WORKSPACE}/${TEMP_FOLDER}

for FILE_NAME in $(ls ${PWD})
do
	if [[ "${FILE_NAME}" =~ ${IMAGE_NAME}* ]]; then
		SUB_STR=${FILE_NAME##*-}
		BUILD_VERSION=${SUB_STR%.*}
		break
	fi
done
if [ ! -n "${BUILD_VERSION}" ]; then
	printf "\e[1;31m=======>未能正确获取应用程序版本号，可能原因：\n=======>1、POM 文件中打包标签 <finalName></finalName> 设置应用包名格式不正确（强制约定 JAR 包规定格式：IMAGE-NAME-VERSION.jar）。\n=======>2、打包后的应用程序文件名称和脚本第二个参数镜像名称不一致（示例：程序名称 rms-gateway-V1.0.0.1.jar，第二个参数名称 rms-gateway）。\n=======>请检查以上两点提示，修复后再重新构建，本次构建异常终止！！！\e[0m \n\n"
	cd ../ && rm -rf ${TEMP_FOLDER}
	exit 2
fi
printf "\e[1;35m=======>本次计划构建镜像的应用程序文件全称：${FILE_NAME}，计划构建的版本号为：${BUILD_VERSION} 。\e[0m \n\n"
############################################# 构建前置准备结束 #############################################

############################################# 构建镜像流程开始 #############################################
docker build -t ${REPOSITORY_URL}/${PROJECT_NAME}/${IMAGE_NAME}:${BUILD_VERSION} .
printf "\e[1;36m=======>本地镜像 ${IMAGE_NAME} 构建成功！ \e[0m \n\n"
cd ../ && rm -rf ${TEMP_FOLDER}
############################################# 构建镜像流程结束 #############################################

############################################# 推送镜像流程开始 #############################################
echo "${REPOSITORY_PWD}" | docker login ${REPOSITORY_URL} --username ${REPOSITORY_USER} --password-stdin
printf "\e[1;36m=======>采用 ${REPOSITORY_USER} 用户进行登录认证，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，Harbor 仓库登录成功！\e[0m \n"

docker push ${REPOSITORY_URL}/${PROJECT_NAME}/${IMAGE_NAME}:${BUILD_VERSION}
printf "\e[1;36m=======>本地镜像 ${IMAGE_NAME} 推送至 ${PROJECT_NAME} 仓库项目成功！ \e[0m \n"

docker rmi  ${REPOSITORY_URL}/${PROJECT_NAME}/${IMAGE_NAME}:${BUILD_VERSION}
printf "\e[1;36m=======>本地镜像 ${IMAGE_NAME} 删除成功！ \e[0m \n"

docker logout ${REPOSITORY_URL}
printf "\e[1;36m=======>采用 ${REPOSITORY_USER} 用户进行登录认证，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，Harbor 仓库登出成功！\e[0m \n"

printf "\e[1;35m=======>镜像仓库：${PROJECT_NAME}/${IMAGE_NAME}，镜像版本：${BUILD_VERSION}，已成功推送至：${REQUEST_PROTOCOL}://${REPOSITORY_URL} 仓库项目中，自动化镜像构建脚本运行完成！\e[0m \n\n"
############################################# 推送镜像流程结束 #############################################
