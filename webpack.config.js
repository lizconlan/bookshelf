const path = require('path');
const resolve = file => path.resolve(__dirname, file);

module.exports = {
  mode: "development",
  devtool: "inline-source-map",
  entry: {
    "index": "./app/src"
  },
  output: {
    path: path.resolve(__dirname, "./assets/script"),
    filename: "application.js"
  },
  resolve: {
    extensions: [".ts", ".js"],
    alias:{
      controllers: path.resolve( __dirname, 'app', 'src', 'controllers' )
    },
  },
  module: {
    rules: [
      {
        loader: "ts-loader",
        options: {
          transpileOnly: true
        }
      }
    ]
  }
}