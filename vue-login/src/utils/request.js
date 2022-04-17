import axios from "axios";

// 创建axios 实例
const service = axios.create({
    baseURL: "/",
    timeout: 15000,
})

export default service
