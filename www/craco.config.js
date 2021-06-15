const path = require('path')

module.exports = {
  eslint: {
    enable: false,
  },
  webpack: {
    // We need to set the `public_html` as build folder to have it properly served by `heroku-buildpack-static`
    // See `How can I override the build directory?` https://github.com/gsoft-inc/craco/issues/104
    configure: (webpackConfig, { env, paths }) => {
      paths.appBuild = webpackConfig.output.path =
        path.resolve('build/public_html')
      return webpackConfig
    },
  },
}
