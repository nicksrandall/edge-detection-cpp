let wasmUrl;
let memUrl;

if (process.env.NODE_ENV === "production") {
  wasmUrl = require("./detect-threads.br.wasm");
  memUrl = require("./detect-threads.js.br.mem");
} else {
  wasmUrl = require("./detect-threads.wasm");
  memUrl = require("./detect-threads.js.mem");
}
const pthreadUrl = require("file-loader!./pthread-main.js");

export default new Promise(resolve => {
  self.detect = {
    locateFile(url) {
      // Redirect the request for the wasm binary to whatever webpack gave us.
      switch (url) {
        case "detect-threads.wasm":
          return wasmUrl;
        case "detect-threads.js.mem":
          return memUrl;
        case "pthread-main.js":
          return pthreadUrl;
        default:
          console.log("not found url", url);
          return url;
      }
    },
    mainScriptUrlOrBlob: "#", // this is a weird hack that makes the module loding works.
    onRuntimeInitialized() {
      delete self.detect.then;
      resolve(self.detect);
    }
  };

  require("./detect-threads");
});
