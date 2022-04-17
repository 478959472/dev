
module.exports = {
  transpileDependencies: true,
  lintOnSave: false,
  // ...
  devServer: {
    port: 8003,
    proxy: {
      '/api': {
        target: 'http://192.169.5.16:3002/cy-tool',
        ws: true,
        changeOrigin: true,
        pathRewrite: {
          '^/api': 'api'
        }
      }
    }
  }
}
