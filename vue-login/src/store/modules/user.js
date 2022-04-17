import {login} from '@/api/login'


const user = {
    actions: {
        //登录
        Login({commit}, userInfo){
            const username = userInfo.username.trim()
            return new Promise((resolve, reject) => {// 封装一个promise
                login(username, userInfo.password).then(response => {
                    commit('') //提交一个mutation ，通知状态改变
                    resolve(response) // 将结果封装进 promise
                }).catch(error => {
                    reject(error)
                })
            })
        }
    }
}
export default user
