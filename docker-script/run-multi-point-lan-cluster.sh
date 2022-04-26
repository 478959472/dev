#!/bin/bash
# Exit immediately if a simple command exits with a non-zero status.
set -e

printf "\e[1;31m#########################################################################################################\e[0m \n"
printf "\e[1;31m### Desc:         多节点局域网集群自动化容器部署脚本 —— 适用于本地、开发、测试、预发布、生产环境      ###\e[0m \n"
printf "\e[1;31m### Date:         2021-06-03                                                                          ###\e[0m \n"
printf "\e[1;31m### Author:       Rambo                                                                               ###\e[0m \n"
printf "\e[1;31m### E-Mail:       1071553975@qq.com                                                                   ###\e[0m \n"
printf "\e[1;31m### Version:      V1.0                                                                                ###\e[0m \n"
printf "\e[1;31m#########################################################################################################\e[0m \n\n"

############################################# 项目标准约定开始 #############################################
printf "\e[1;32m=======>多节点局域网集群自动化容器部署脚本调用入参说明（每组入参请采用空格隔开）：\e[0m \n"
printf "\e[1;32m=======>第一组必传入参：需要操作的 仓库全路径:版本号（示例：192.169.2.237:8004/rms-platform-test/rms-gateway:V1.1.0.3） \e[0m \n"
printf "\e[1;32m=======>第二组必传入参：自定义应用程序的容器名，单点部署建议采用镜像名，单点集群可随意命名（示例：rms-gateway） \e[0m \n"
printf "\e[1;32m=======>第三组必传入参：应用程序 外部响应:内部暴露端口号集合，多组采用英文逗号隔开（示例：9000:9000） \e[0m \n"
printf "\e[1;32m=======>第四组必传入参：应用程序除日志、个性配置文件夹以外的自定义映射路径集合，多组采用英文逗号隔开（示例：/opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data） \e[0m \n"
printf "\e[1;32m=======>第五组必传入参：应用程序部署配置文件概要环境（示例：dev、test、pre、prod） \e[0m \n"
printf "\e[1;32m=======>第六组必传入参：远程部署机器 USER@IP:SSH-PORT，多组采用英文逗号隔开（示例：root@100.100.100.202:22,root@100.100.100.203:22） \e[0m \n"
printf "\e[1;32m=======>第七组必传入参：本地自动化容器启动脚本绝对路径（示例：/opt/java/.run-latest.sh） \e[0m \n"
printf "\e[1;31m=======> >>>>>本多节点局域网集群自动化容器部署脚本建议置于 /opt/java 文件夹下，请确保当前执行自动化脚本的节点可以免密登录各个部署节点并赋予操作用户的文件操作权限。<<<<< \e[0m \n"
printf "\e[1;31m=======> >>>>>首次执行该局域网集群部署脚本，请确保目标服务器已手动创建相应的文件夹和个性化配置文件，本自动化脚本不会创建文件夹和个性化配置文件！！！<<<<< \e[0m \n\n"
############################################# 项目标准约定结束 #############################################

############################################# 处理调用参数开始 #############################################
if [[ ${#} != 7 ]]; then
	printf "\e[1;31m=======>调用多节点局域网集群自动化容器部署脚本请求参数不符合规范，本次操作异常终止！！！ \e[0m \n"
	printf "\e[1;32m=======>调用格式：sh xxx.sh 仓库全路径:版本号 应用容器名称 外部响应:内部暴露端口号集合（多个采用英文逗号隔开） 应用程序自定义映射路径集合（多个采用英文逗号隔开） 配置文件概要 远程部署机器 USER@IP:SSH-PORT（多组采用英文逗号隔开）。 \e[0m \n"
	# sh run-multi-point-lan-cluster.sh 192.169.2.237:8004/rms-platform-test/rms-gateway:V1.0.1.2 rms-gateway 9000:9000 /opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data dev root@100.100.100.202:22 /opt/java/.run-latest.sh
	printf "\e[1;32m=======>调用示例：sh run-multi-point-lan-cluster.sh 192.169.2.237:8004/rms-platform-test/rms-gateway:V1.1.0.3 rms-gateway 9000:9000 /opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data dev root@100.100.100.202:22,root@100.100.100.203:22。\e[0m \n\n"
	exit 1
fi
REPOSITORY_TAG=${1}
CONTAINER_NAME=${2}
APP_PORTS=${3}
VOLUME_PATHS=${4}
APP_PROFILES_ACTIVE=${5}
REMOTE_ADDRESSES=${6}
RUN_COMMAND_PATH=${7}

RUN_COMMAND=${RUN_COMMAND_PATH##*/}
ALL_IMAGE_PATH=${REPOSITORY_TAG%:*}
FULL_IMAGE_PATH=${ALL_IMAGE_PATH#*/}
IMAGE_NAME=${REPOSITORY_TAG##*/}
IAMGE_NAME=${IMAGE_NAME%%:*}
IMAGE_VERSION=${REPOSITORY_TAG##*:}
if [[ -z "${IAMGE_NAME}" || -z "${IMAGE_VERSION}" ]]; then
	printf "\e[1;31m=======>仓库全路径:版本号输入不符合规范，请按照参考示例修改后重试（示例：192.169.2.237:8004/rms-platform-test/rms-gateway:V1.1.0.3），本次操作异常终止！！！ \e[0m \n"
	exit 2
fi
ARCHIVE_FILE_NAME=${IAMGE_NAME}-${IMAGE_VERSION}.tar
APP_BASE_PATH=/opt/java
TEMP_LOCAL_WORKSPACE=${APP_BASE_PATH}/${IAMGE_NAME}/image
TEMP_REMOTE_WORKSPACE=${APP_BASE_PATH}/${IAMGE_NAME}/image
############################################# 处理调用参数结束 #############################################

############################################# 配置环境变量开始 #############################################
if [[ -d ${TEMP_LOCAL_WORKSPACE} ]]; then
	rm -rf ${TEMP_LOCAL_WORKSPACE}
fi
mkdir -p ${TEMP_LOCAL_WORKSPACE} && cd ${TEMP_LOCAL_WORKSPACE}

printf "\e[1;36m=======>正在保存本地镜像：${REPOSITORY_TAG} 为 TAR 格式压缩文件...... \e[0m \n"
# docker save -o rms-gateway.tar 192.169.2.237:8004/rms-platform-test/rms-gateway:V1.1.0.3
docker save -o ${ARCHIVE_FILE_NAME} ${REPOSITORY_TAG}
if [[ ! -f ${TEMP_LOCAL_WORKSPACE}/${ARCHIVE_FILE_NAME} ]]; then
	printf "\e[1;31m=======>本地镜像保存失败，请确保镜像地址是否正确，第一个入参正确格式示例：192.169.2.237:8004/rms-platform-test/rms-gateway:V1.1.0.3，本次操作异常终止！！！ \e[0m \n"
	exit 3
else
	printf "\e[1;36m=======>本地镜像：${REPOSITORY_TAG} 已成功保存为：${ARCHIVE_FILE_NAME} 文件。 \e[0m \n\n"
fi
############################################# 配置环境变量结束 #############################################

############################################# 资源远程传输开始 #############################################
CONNECTIONS_ARRAY=(${REMOTE_ADDRESSES//\,/ })
for CONNECTION in "${!CONNECTIONS_ARRAY[@]}"; do
	SSH_USER=${CONNECTIONS_ARRAY[CONNECTION]%%@*}
	CONNECTION_INFO=${CONNECTIONS_ARRAY[CONNECTION]%%:*}
	SSH_IP=${CONNECTION_INFO##*@}
	SSH_PORT=${CONNECTIONS_ARRAY[CONNECTION]##*:}
	
	ssh -Tq ${SSH_IP} -p ${SSH_PORT} << REMOTEFOLDER
	printf "\e[1;35m=======>已成功登录服务器：${SSH_IP}，开始创建资源部署文件夹 ... ... \e[0m \n"
	if [[ ! -d "${APP_BASE_PATH}/${IAMGE_NAME}" ]]; then
		mkidr -p ${APP_BASE_PATH}/${IAMGE_NAME}
		printf "\e[1;35m=======>${SSH_IP}=>本节点为第一次集群部署，项目规约根目录：${APP_BASE_PATH}/${IAMGE_NAME} 创建完成。 \e[0m \n"
	else
		printf "\e[1;35m=======>${SSH_IP}=>本节点非第一次集群部署，项目规约根目录已存在，无需再次创建项目规约根目录。 \e[0m \n"
	fi

	if [[ ! -d "${TEMP_REMOTE_WORKSPACE}" ]]; then
		mkdir -p ${TEMP_REMOTE_WORKSPACE}
		printf "\e[1;35m=======>${SSH_IP}=>临时资源文件夹：${TEMP_REMOTE_WORKSPACE} 创建完成。 \e[0m \n"
	else
		printf "\e[1;35m=======>${SSH_IP}=>临时资源文件夹已存在，无需再次创建。 \e[0m \n"
	fi
	exit
# REMOTEFOLDER 必须顶格，请勿手痒去按 TAB 键
REMOTEFOLDER
	printf "\e[1;35m=======>已成功登出服务器：${SSH_IP}。 \e[0m \n\n"
	
	printf "\e[1;36m=======>本地镜像压缩文件：${ARCHIVE_FILE_NAME} ，目标服务器：${SSH_IP}，远程传输开始... ... \e[0m \n"
	scp -r -P ${SSH_PORT} ${TEMP_LOCAL_WORKSPACE}/${ARCHIVE_FILE_NAME} ${CONNECTION_INFO}:${TEMP_REMOTE_WORKSPACE}
	printf "\e[1;36m=======>本地镜像压缩文件：${ARCHIVE_FILE_NAME} ，目标服务器：${SSH_IP}，远程传输完成。 \e[0m \n\n"
	
	printf "\e[1;36m=======>本地容器启动脚本文件：${RUN_COMMAND} ，目标服务器：${SSH_IP}，远程传输开始... ... \e[0m \n"
	scp -r -P ${SSH_PORT} ${RUN_COMMAND_PATH} ${CONNECTION_INFO}:${APP_BASE_PATH}
	printf "\e[1;36m=======>本地容器启动脚本文件：${RUN_COMMAND} ，目标服务器：${SSH_IP}，远程传输完成。 \e[0m \n\n"
	
	printf "\e[1;33m=======>个性化配置，如：bootstrap.properties、需要手动挂载的外部文件 等，需要运维手动在目标部署节点事先创建！！！ \e[0m \n\n"
	
	ssh -p ${SSH_PORT} -Tq ${SSH_IP} << REMOTEFILE
	cd ${TEMP_REMOTE_WORKSPACE}
	if [[ ! -f "${TEMP_REMOTE_WORKSPACE}/${ARCHIVE_FILE_NAME}" ]]; then
		printf "\e[1;31m=======>镜像文件：${ARCHIVE_FILE_NAME} 不存在或丢失，远程服务器节点：${SSH_IP} 将停止本次部署。 \e[0m \n"
		exit
	fi
	printf "\e[1;35m=======>已成功登录服务器：${SSH_IP}，开始解压镜像：${REPOSITORY_TAG} ... ... \e[0m \n"
	docker load -i ${ARCHIVE_FILE_NAME}
	printf "\e[1;35m=======>${SSH_IP}=>镜像：${REPOSITORY_TAG} 已经解压完成。 \e[0m \n"
	
	printf "\e[1;35m=======>${SSH_IP}=>调用自动化容器启动脚本开始启动容器：${CONTAINER_NAME} ... ... \e[0m \n"
	cd ${APP_BASE_PATH}
	
	# 执行启动脚本
	# 参数一：镜像仓库项目名/镜像名
	# 参数二：容器名称
	# 参数三：端口号集合，多组逗号隔开
	# 参数四：挂载路径集合，多组逗号隔开
	# 参数五：配置环境概要
	# 参数六：是否每次拉取最新镜像（0 否，1 是）
	# 参数七：指定构建版本号（非必填）
	sh ${RUN_COMMAND} \
	${FULL_IMAGE_PATH} \
	${CONTAINER_NAME} \
	${APP_PORTS} \
	${VOLUME_PATHS} \
	${APP_PROFILES_ACTIVE} \
	0 \
	${IMAGE_VERSION}

	printf "\e[1;35m=======>${SSH_IP}=>容器：${CONTAINER_NAME} 执行启动完成，请根据启动日志判断应用是否启动成功。 \e[0m \n\n"
	
	if [[ -d "${TEMP_REMOTE_WORKSPACE}" ]]; then
		rm -rf ${TEMP_REMOTE_WORKSPACE}
	fi
	
	LOCAL_IMAGE_IDS=$(docker images -a | grep ${FULL_IMAGE_PATH} | grep -v grep | grep -v ${0} | awk '{print $3}')
	if [[ -z "${LOCAL_IMAGE_IDS}" ]]; then
		printf "\e[1;31m=======>本地镜像：${ALL_IMAGE_PATH}:${TAG} 在服务器节点：${SSH_IP} 消失了，请运维人员检查该服务器节点的容器的健康情况！！！ \e[0m \n"
	elif [[ "${#LOCAL_IMAGE_IDS}" != 12 ]]; then
		LOCAL_IMAGE_IDS_ARRAY=(${LOCAL_IMAGE_IDS//\ / })
		if [[ "${#LOCAL_IMAGE_IDS_ARRAY[@]}" > 1 ]]; then
			LOCAL_IMAGE_TAGS=$(docker images -a | grep ${ALL_IMAGE_PATH} | grep -v grep | grep -v ${0} | awk '{print $2}')
			LOCAL_IMAGE_TAGS_ARRAY=(${LOCAL_IMAGE_TAGS//\ / })
			if [[ "${#LOCAL_IMAGE_TAGS_ARRAY[@]}" > 1 ]]; then
				for TAG in "${!LOCAL_IMAGE_TAGS_ARRAY[@]}"; do
					IS_RUNNING=$(docker ps -a | grep ${ALL_IMAGE_PATH}:${TAG} | grep -v grep | grep -v ${0} | awk '{print $1}')
					if [[ -z "${IS_RUNNING}" ]]; then
						printf "\e[1;35m=======>本地镜像：${ALL_IMAGE_PATH}:${TAG} 在服务器节点：${SSH_IP} 未被实例化过，开始删除... ... \e[0m \n"
						docker rmi $(docker images -a | grep ${ALL_IMAGE_PATH}:${TAG} | grep -v grep | grep -v ${0} | awk '{print $3}')
						printf "\e[1;35m=======>本地镜像：${ALL_IMAGE_PATH}:${TAG} 在服务器节点：${SSH_IP} 已成功删除。 \e[0m \n"
					fi
				done
			fi
		fi	
	fi
	exit
# REMOTEFILE 必须顶格，请勿手痒去按 TAB 键
REMOTEFILE
	printf "\e[1;35m=======>已成功登出服务器：${SSH_IP}。 \e[0m \n\n"
done
############################################# 资源远程传输结束 #############################################

############################################# 自动化集群化开始 #############################################
# 删除临时文件
if [[ -d "${TEMP_LOCAL_WORKSPACE}" ]]; then
	rm -rf ${TEMP_LOCAL_WORKSPACE}
fi
printf "\e[1;32m=======>基础镜像：${REPOSITORY_TAG}，多节点局域网集群自动化容器部署完成。 \e[0m \n"
############################################# 自动化集群化结束 #############################################