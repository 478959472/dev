import request from '@/utils/request'

export function login(username, password){
    return request({
        url: '/api/admin/login',
        method: 'post',
        data: {
            username, password
        }
    })
}
