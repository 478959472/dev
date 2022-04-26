#!/bin/bash
# Exit immediately if a simple command exits with a non-zero status.
set -e

# 示例： sh run-latest.sh rms-console-test/rms-ccc-console rms-ccc-console 8088:8088 /opt/java/rms-ccc-console/mon_data:/opt/java/rms-ccc-console/mon_data dev 1 host

printf "\e[1;31m#########################################################################################################\e[0m \n"
printf "\e[1;31m### Desc:         自动化容器启动脚本 —— 适用于本地、开发、测试、预发布、生产环境		                      ###\e[0m \n"
printf "\e[1;31m### Date:         2021-05-10           								      ###\e[0m \n"
printf "\e[1;31m### Author:       Rambo                								      ###\e[0m \n"
printf "\e[1;31m### Updator:      Lianghj                								      ###\e[0m \n"
printf "\e[1;31m### E-Mail:       1071553975@qq.com    								      ###\e[0m \n"
printf "\e[1;31m### Version:      V4.0                 								      ###\e[0m \n"
printf "\e[1;31m#########################################################################################################\e[0m \n\n"

############################################# 项目标准约定开始 #############################################
APP_BASE_PATH=/opt/java
LOGS_BASE_PATH=/opt/java/logs
CONFIG_FOLDER=config
printf "\e[1;33m=======>项目标准规范约定：\e[0m \n"
printf "\e[1;33m=======>1、应用程序默认部署根目录： /opt/java \e[0m \n"
printf "\e[1;33m=======>2、应用程序默认日志根目录（无需手动挂载，容器启动默认挂载）： /opt/java/logs/container_name \e[0m \n"
printf "\e[1;33m=======>3、应用程序个性配置文件夹（无需手动挂载，容器启动默认挂载）： /opt/java/container_name/config \e[0m \n"
printf "\e[1;31m=======> >>>>>标准规范约定，日志目录和 Dockerfile 脚本非此标准设置则不适用于本自动化容器启动脚本<<<<< \e[0m \n\n"

printf "\e[1;32m=======>自动化容器启动脚本调用入参说明（每组入参请采用空格隔开）：\e[0m \n"
printf "\e[1;32m=======>第一组必传入参：需要操作的仓库项目名/仓库镜像名（示例：rms-platform/rms-gateway） \e[0m \n"
printf "\e[1;32m=======>第二组必传入参：自定义应用程序的容器名，单点部署建议采用镜像名，单点集群可随意命名（示例：rms-gateway） \e[0m \n"
printf "\e[1;32m=======>第三组必传入参：应用程序 外部响应:内部暴露端口号集合，多组采用英文逗号隔开（示例：9000:9000） \e[0m \n"
printf "\e[1;32m=======>第四组必传入参：应用程序除日志、个性配置文件夹以外的自定义映射路径集合，多组采用英文逗号隔开（示例：/opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data） \e[0m \n"
printf "\e[1;32m=======>第五组必传入参：应用程序部署配置文件概要环境（示例：dev、test、pre、prod） \e[0m \n"
printf "\e[1;32m=======>第六组必传入参：JVM启动参数，原参数（是否删除旧镜像）示例为0或1，为兼容原参数，若填入0或1，则不配置JVM参数，非0和1则视为设置JVM参数。(示例：-Xmn2G -Xms4G -Xmx8G -XX:SurvivorRatio=8) \e[0m \n"
printf "\e[1;32m=======>第七组必传入参：应用程序网络模式，示例：host、none、bridge、container。host：使用 --net=host 指定；none：使用 --net=none 指定；bridge：使用 --net=bridge 指定；container：使用 --net=container:NAME_or_ID 指定。 \e[0m \n"
printf "\e[1;32m=======>第八组非必传参：指定容器启动的镜像版本号。不传参则每次拉取镜像仓库中最新版本镜像并启动容器，传参则采用启动该版本的镜像应用容器 \e[0m \n"
printf "\e[1;31m=======> >>>>>本自动化容器启动脚本建议置于 /opt/java 文件夹下。<<<<< \e[0m \n\n"
############################################# 项目标准约定结束 #############################################

############################################# 处理调用参数开始 #############################################
if [[ ${#} < 7 ]] ; then
	printf "\e[1;31m=======>调用自动化容器启动脚本请求参数不符合规范，本次构建异常终止！！！ \e[0m \n"
	printf "\e[1;32m=======>调用格式：sh xxx.sh 仓库项目名称/应用镜像名称 应用容器名称 外部响应:内部暴露端口号集合（多个采用英文逗号隔开） 应用程序自定义映射路径集合（多个采用英文逗号隔开） 配置文件概要 是否每次拉取最新镜像 指定镜像版本启动容器。 \e[0m \n"
	printf "\e[1;32m=======>调用示例：sh run-latest.sh rms-platform/rms-gateway rms-gateway 9000:9000 /opt/java/rms-gateway/mon_data:/opt/java/rms-gateway/mon_data dev '-Xmn2G -Xms4G -Xmx8G -XX:SurvivorRatio=8' V1.0.1.2 bridge。\e[0m \n\n"
	exit 1
fi
FULL_IMAGE_PATH=${1}
CONTAINER_NAME=${2}
APP_PORTS=${3}
VOLUME_PATHS=${4}
APP_PROFILES_ACTIVE=${5}
JVM_STARTUP_PARAM=${6}
NETWORK_MODE=${7}
DETERMINE_VERSION=${8}
JVM_FLAG=0
if [[ "${JVM_STARTUP_PARAM}" == 0 || "${JVM_STARTUP_PARAM}" == 1 ]] ; then
    JVM_FLAG=1
    printf "\e[1;31m=======>调用自动化容器启动脚本JVM参数为:[${JVM_STARTUP_PARAM}]，为0或1JVM参数默认配置4G内存（-Xmx4G）。 \e[0m \n"
fi

printf "\e[1;32m=======>调用自动化容器启动脚本请求参数：\n=======>应用镜像仓库：${FULL_IMAGE_PATH}\n=======>应用容器名称：${CONTAINER_NAME}\n=======>应用端口集合：${APP_PORTS}\n=======>应用挂载集合：${VOLUME_PATHS}\n=======>应用配置概要：${APP_PROFILES_ACTIVE}\n=======>JVM启动参数：${JVM_STARTUP_PARAM}\n=======>网络模式：${NETWORK_MODE}\n=======>指定镜像版本：${DETERMINE_VERSION} \e[0m\n\n"
############################################# 处理调用参数结束 #############################################

############################################# 配置环境变量开始 #############################################
REQUEST_PROTOCOL=https
REPOSITORY_URL=192.169.2.237:8004
REPOSITORY_USER=admin
REPOSITORY_PWD=Harbor12345
printf "\e[1;34m=======>自动化容器启动脚本操作目标镜像仓库，采用 ${REPOSITORY_USER} 用户进行登录认证，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} 。\e[0m\n\n"
############################################# 配置环境变量结束 #############################################

############################################# 操作前置准备开始 #############################################
if [[ -z "${DETERMINE_VERSION}" ]]; then
	HTML_INFO=$(curl -s -k -u ${REPOSITORY_USER}:${REPOSITORY_PWD} ${REQUEST_PROTOCOL}://${REPOSITORY_URL}/api/repositories/${FULL_IMAGE_PATH}/tags)
	if [[ -z "${HTML_INFO}" ]]; then
		printf "\e[1;31m=======>Harbor 服务器异常，请检查仓库服务器是否健康或仓库地址配置是否正确，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，本次容器启动异常结束！\e[0m\n"
		exit 2
	elif [[ "${HTML_INFO}" == "[]" ]]; then
		printf "\e[1;31m=======>Harbor 服务器正常，镜像名称错误，请检查镜像是否在 Harbor 仓库项目中存在，仓库+镜像名称：${FULL_IMAGE_PATH}，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，本次容器启动异常结束！\e[0m\n"
		exit 3
	elif [[ ${#HTML_INFO} -lt 200 && $(echo "${HTML_INFO}" | jq 'has("code")') && $(echo "${HTML_INFO}" | jq '.code') -eq 404 ]]; then
		printf "\e[1;31m=======>Harbor 服务器正常，仓库项目名称错误，请检查仓库项目是否在 Harbor 仓库中存在，仓库+镜像名称：${FULL_IMAGE_PATH}，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，本次容器启动异常结束！\e[0m\n"
		exit 4
	fi
	IMAGE_TAGS=$(echo "${HTML_INFO}" | jq '.[]' | jq -r '.name')

	TEMP_FOLDER=${PWD}/${CONTAINER_NAME}/temp
	if [[ -d ${TEMP_FOLDER} ]]; then
	  rm -rf ${TEMP_FOLDER}
	fi
	mkdir -p ${TEMP_FOLDER}
	echo "${IMAGE_TAGS}" > ${TEMP_FOLDER}/tags.txt
	sort -rV ${TEMP_FOLDER}/tags.txt | sed '/p-/d' > ${TEMP_FOLDER}/sort_tags.txt
	LATEST_IMAGE_VERSION=`sed -n '1p' ${TEMP_FOLDER}/sort_tags.txt`
	rm -rf ${TEMP_FOLDER}
else
	LATEST_IMAGE_VERSION=${DETERMINE_VERSION}
fi

if [[ -z "${LATEST_IMAGE_VERSION}" && -z "${DETERMINE_VERSION}" ]]; then
	printf "\e[1;31m=======>Harbor 仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，仓库镜像：'${FULL_IMAGE_PATH}' 镜像版本存在异常，请确保镜像版本号符合规范（示例：V1.0.0.1），本次容器启动异常结束！ \e[0m\n"
	exit 5
fi
printf "\e[1;35m=======>本次自动化容器启动脚本实例化应用程序的镜像：${FULL_IMAGE_PATH}，计划启动应用程序的容器镜像版本号：${LATEST_IMAGE_VERSION} 。\e[0m \n\n"
############################################# 操作前置准备结束 #############################################

############################################# 停止运行容器开始 #############################################
RUNNING_CONTAINER_IMAGE=$(docker ps -a | grep ${CONTAINER_NAME}$ | awk '{print $2}')
RUNNING_IMAGE_VERSION=${RUNNING_CONTAINER_IMAGE##*:}
IMAGE_DELETE_FLAG=0
if [[ -z "${RUNNING_CONTAINER_IMAGE}" ]]; then
	printf "\e[1;35m=======>本次自动化容器启动脚本启动容器的镜像：${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION} 为该服务器节点首次启动，当前没有运行中的容器，准备从 Harbor 仓库中拉取应用程序镜像。\e[0m\n"
else
	LIVE_CONTAINER_IDS=$(docker ps -a | grep ${FULL_IMAGE_PATH}:${RUNNING_IMAGE_VERSION} | awk '{print $1}')
	if [[ -z "${LIVE_CONTAINER_IDS}" ]]; then
		printf "\e[1;31m=======>当前节点本地镜像：${FULL_IMAGE_PATH}:${RUNNING_IMAGE_VERSION} 未能找到已实例化的容器，本次运行容器：${CONTAINER_NAME} 存在未知错误，请运维人员介入检查！ \e[0m \n"
		exit 6
	elif [[ "${#LIVE_CONTAINER_IDS}" != 12 ]]; then
		printf "\e[1;35m=======>当前节点本地镜像：${FULL_IMAGE_PATH}:${RUNNING_IMAGE_VERSION} 以单点集群方式部署，目前还存在正在运行的容器，容器 ID 列表为：${LIVE_CONTAINER_IDS} ，所以本地镜像不会被删除！ \e[0m \n"
	elif [[ "${#LIVE_CONTAINER_IDS}" == 12 ]]; then
		IMAGE_DELETE_FLAG=1
	fi
	docker stop $(docker ps -a | grep -w ${CONTAINER_NAME}$ | awk '{print $1}')
	printf "\e[1;35m=======>已成功停止当前正在运行的 ${CONTAINER_NAME} 容器，被停止的容器镜像版本号：${RUNNING_IMAGE_VERSION} \e[0m \n"
	docker rm -f $(docker ps -a | grep -w ${CONTAINER_NAME}$ | awk '{print $1}')
	printf "\e[1;35m=======>已成功删除当前正在运行的 ${CONTAINER_NAME} 容器，被删除的容器镜像版本号：${RUNNING_IMAGE_VERSION} \e[0m \n"
fi


if [[ "${IMAGE_DELETE_FLAG}" == 1 ]]; then
    LOCAL_IMAGE_IDS=$(docker images -a | grep ${FULL_IMAGE_PATH} | awk '{print $3}')
    if [[ -z "${LOCAL_IMAGE_IDS}" ]]; then
        printf "\e[1;31m=======>当前节点本地镜像：${FULL_IMAGE_PATH} 可能在该代码片段执行前已经被外部人员或者程序主动删除，此场景不影响后续业务，自动化容器启动脚本代码继续执行！ \e[0m \n"
    elif [[ "${#LOCAL_IMAGE_IDS}" != 12 ]]; then
        printf "\e[1;31m=======>当前节点本地镜像：${FULL_IMAGE_PATH} 已经出现了基于相同镜像仓库镜像的不同版本同时被实例化的场景，正在采用当前实例化后容器的镜像版本来筛选需要删除的本地镜像 \e[0m \n"
        LOCAL_IMAGE_IDS_ARRAY=(${LOCAL_IMAGE_IDS//\ / })
        if [[ "${#LOCAL_IMAGE_IDS_ARRAY[@]}" > 1 ]]; then
            LOCAL_IMAGE_TAGS=$(docker images -a | grep ${FULL_IMAGE_PATH} | awk '{print $2}')
            LOCAL_IMAGE_TAGS_ARRAY=(${LOCAL_IMAGE_TAGS//\ / })
            if [[ "${#LOCAL_IMAGE_TAGS_ARRAY[@]}" > 1 ]]; then
                for TAG in "${!LOCAL_IMAGE_TAGS_ARRAY[@]}"; do
                    if [[ "${LOCAL_IMAGE_TAGS_ARRAY[TAG]}" == "${RUNNING_IMAGE_VERSION}" ]]; then
                        docker rmi -f $(docker images -a | grep -E "(${FULL_IMAGE_PATH} | ' ')" | grep -E "(${LOCAL_IMAGE_TAGS_ARRAY[TAG]} | ' ')" | awk '{print $3}')
                        printf "\e[1;35m=======>单点集群场景 => 基于该基础镜像：${FULL_IMAGE_PATH} 的镜像版本 ${LOCAL_IMAGE_TAGS_ARRAY[TAG]} 的容器已经停止并删除，当前镜像也相应被成功删除。非该版本的镜像和容器未受影响！ \e[0m \n"
                        break
                    fi
                done
            fi
        fi
    elif [[ "${#LOCAL_IMAGE_IDS}" == 12 ]]; then
        docker rmi -f ${LOCAL_IMAGE_IDS}
        printf "\e[1;35m=======>单点部署场景 => 基于该基础镜像：${FULL_IMAGE_PATH}:${RUNNING_IMAGE_VERSION} 的容器已经全部停止并删除，当前镜像也相应被成功删除！ \e[0m \n"
    fi
fi

############################################# 停止运行容器结束 #############################################

############################################# 运行新版容器开始 #############################################
PULL_IMAGE_FLAG=$(docker images -a | grep -E "(${FULL_IMAGE_PATH} | ' ')" | grep -E "(${LATEST_IMAGE_VERSION} | ' ')" | awk '{print $3}')
if [[ ! -z "${PULL_IMAGE_FLAG}" ]]; then
	printf "\e[1;36m=======>本次启动为大于一个容器实例的单机集群场景或者指定不删除本地镜像的场景，基础镜像：${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION}，容器名称：${CONTAINER_NAME}，镜像无需从 Harbor 服务器再次拉取！\e[0m \n\n"
else
	echo "${REPOSITORY_PWD}" | docker login ${REPOSITORY_URL} --username ${REPOSITORY_USER} --password-stdin
	printf "\e[1;36m=======>采用 ${REPOSITORY_USER} 用户进行登录认证，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，Harbor 仓库登录成功！\e[0m \n"
	docker pull ${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION}
	printf "\e[1;36m=======>远程仓库镜像：${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION} 拉取至本地成功！ \e[0m \n"
	docker logout ${REPOSITORY_URL}
	printf "\e[1;36m=======>采用 ${REPOSITORY_USER} 用户进行登录认证，仓库地址：${REQUEST_PROTOCOL}://${REPOSITORY_URL} ，Harbor 仓库登出成功！\e[0m \n\n"
fi

# PID 挂载非 守护进程 --init 20211201  添加容器网络模式 --net  20220113
APP_BASE_COMMAND="docker run --init -d --net=${NETWORK_MODE} --name"
PORTS_ARRAY=(${APP_PORTS//\,/ })
for PORTS in "${!PORTS_ARRAY[@]}"; do
    if [[ -z "${APP_PORTS_COMMAND}" ]]; then
    	APP_PORTS_COMMAND="-p ${PORTS_ARRAY[PORTS]}"
    else
    	APP_PORTS_COMMAND="${APP_PORTS_COMMAND} -p ${PORTS_ARRAY[PORTS]}"
    fi
done

APP_VOLUME_COMMAND="-v ${LOGS_BASE_PATH}/${CONTAINER_NAME}:${LOGS_BASE_PATH}/${FULL_IMAGE_PATH##*/}"
APP_VOLUME_COMMAND="${APP_VOLUME_COMMAND} -v ${APP_BASE_PATH}/${CONTAINER_NAME}/${CONFIG_FOLDER}:${APP_BASE_PATH}/${FULL_IMAGE_PATH##*/}/${CONFIG_FOLDER}"
PATHS_ARRAY=(${VOLUME_PATHS//\,/ })
for PATHS in "${!PATHS_ARRAY[@]}"; do
    APP_VOLUME_COMMAND="${APP_VOLUME_COMMAND} -v ${PATHS_ARRAY[PATHS]}"
done

PRINT_CONTAINER_COMMAND="${APP_BASE_COMMAND} ${CONTAINER_NAME} \ \n${APP_PORTS_COMMAND} \ \n${APP_VOLUME_COMMAND} \ \n-e \"SPRING_PROFILES_ACTIVE=${APP_PROFILES_ACTIVE}\"  \ \n-e \"JAVA_OPTS='${JVM_STARTUP_PARAM}'\" \ \n${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION}"
printf "\e[1;36m>>>>>>>本次执行启动容器脚本<<<<<<<\e[0m \n"
printf "\e[1;36m${PRINT_CONTAINER_COMMAND}\e[0m \n"
printf "\e[1;36m>>>>>>>本次执行启动容器脚本<<<<<<<\e[0m \n\n"

# 启动应用程序容器，-e 概要配置不能以变量的形式存在，不然应用启动后有异常 不配置JVM参数则默认配置4G内存
if [[ "${JVM_FLAG}" == 0 ]]; then
    ${APP_BASE_COMMAND} ${CONTAINER_NAME} ${APP_PORTS_COMMAND} ${APP_VOLUME_COMMAND} -e "SPRING_PROFILES_ACTIVE=${APP_PROFILES_ACTIVE}" -e "JAVA_OPTS=${JVM_STARTUP_PARAM}" ${APP_PROFILES_COMMAND} ${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION}
else
    ${APP_BASE_COMMAND} ${CONTAINER_NAME} ${APP_PORTS_COMMAND} ${APP_VOLUME_COMMAND} -e "SPRING_PROFILES_ACTIVE=${APP_PROFILES_ACTIVE}" -e "JAVA_OPTS=-Xmx4G" ${APP_PROFILES_COMMAND} ${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION}
fi
printf "\e[1;36m=======>根据调用参数组装容器启动命令成功！ \e[0m \n"

printf "\e[1;36m=======>基于镜像仓库：${FULL_IMAGE_PATH}，镜像版本：${LATEST_IMAGE_VERSION}，启动容器 ${CONTAINER_NAME} 成功，自动化启动脚本运行完成！ \e[0m \n\n"
############################################# 运行新版容器结束 #############################################

############################################# 备份还原记录开始 #############################################
BAK_FLODER_NAME=bak-command
SEARCH_FILE_NAME=.search
CURRENT_TIME=$(date '+%Y-%m-%d')
BAK_ROOT_PATH=${APP_BASE_PATH}/${CONTAINER_NAME}/${BAK_FLODER_NAME}
SEARCH_VERSION_FILE=${BAK_ROOT_PATH}/${SEARCH_FILE_NAME}
BAK_FOLDER_PATH=${BAK_ROOT_PATH}/${CURRENT_TIME}

SAVE_BAK_COMMAND="======================= $(date '+%Y-%m-%d %H:%M:%S') =======================\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}# 1、停止名为 ${CONTAINER_NAME} 的容器\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}docker stop ${CONTAINER_NAME}\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}# 2、删除名为 ${CONTAINER_NAME} 的容器\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}docker rm ${CONTAINER_NAME}\n"
if [[ -z "${RUNNING_IMAGE_VERSION}" ]]; then
	SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}# 3、删除 ${LATEST_IMAGE_VERSION} 版本的镜像（如果是单点集群的场景，请勿删除该镜像）\n"
	SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}docker rmi ${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION}\n"
else
	SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}# 3、删除 ${RUNNING_IMAGE_VERSION} 版本的镜像（如果是单点集群的场景，请勿删除该镜像）\n"
	SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}docker rmi ${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${RUNNING_IMAGE_VERSION}\n"	
fi
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}# 4、拉取 ${LATEST_IMAGE_VERSION} 版本的镜像\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}docker pull ${REPOSITORY_URL}/${FULL_IMAGE_PATH}:${LATEST_IMAGE_VERSION}\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}# 5、启动 ${LATEST_IMAGE_VERSION} 版本的容器\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}${PRINT_CONTAINER_COMMAND}\n"
SAVE_BAK_COMMAND="${SAVE_BAK_COMMAND}===================================================================\n"

if [[ ! -d "${BAK_FOLDER_PATH}" ]]; then
	mkdir -p ${BAK_FOLDER_PATH}
fi
echo -e "${SAVE_BAK_COMMAND}" >> ${BAK_FOLDER_PATH}/${LATEST_IMAGE_VERSION}.txt

if [[ -f "${SEARCH_VERSION_FILE}" ]]; then
	SEARCH_RECORDS=$(cat ${SEARCH_VERSION_FILE} | sort -urt "#" -k 1)
	RECORDS_ARRAY=(${SEARCH_RECORDS//\ / })
	for RECORDS in "${!RECORDS_ARRAY[@]}"; do
    	VERSION=${RECORDS_ARRAY[RECORDS]##*#}
    	if [[ ! -z "${RUNNING_IMAGE_VERSION}" && "${RUNNING_IMAGE_VERSION}" == "${VERSION}" ]]; then
    		RECOVER_TIME_FOLDER=${RECORDS_ARRAY[RECORDS]%%#*}
			SHOW_BAK_COMMAND=${BAK_ROOT_PATH}/${RECOVER_TIME_FOLDER}/${RUNNING_IMAGE_VERSION}.txt
			if [[ -f "${SHOW_BAK_COMMAND}" ]]; then
				printf "\e[1;31m>>>>>>>请选择执行如下脚本回滚到指定的历史构建版本<<<<<<<\n$(cat ${SHOW_BAK_COMMAND}) \e[0m \n\n"
			fi
    		break
    	fi
	done
else
	touch ${SEARCH_VERSION_FILE}
fi

echo -e "${CURRENT_TIME}#${LATEST_IMAGE_VERSION}" >> ${SEARCH_VERSION_FILE}
############################################# 备份还原记录结束 #############################################

############################################# 打印实时日志开始 #############################################
docker logs -f ${CONTAINER_NAME} & PID=${!}; { sleep 15; kill ${PID}; }
############################################# 打印实时日志结束 #############################################
