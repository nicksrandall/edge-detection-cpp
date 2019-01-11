let wasmUrl;
if (process.env.NODE_ENV === 'production') {
  wasmUrl = require('./detect.br.wasm');
} else {
  wasmUrl = require('./detect.wasm');
}
const Detect = require('./detect');

export default new Promise(resolve => {
  const detect = new Detect({
    locateFile(url) {
      // Redirect the request for the wasm binary to whatever webpack gave us.
      if (url.endsWith('.wasm')) return wasmUrl;
      return url;
    },
    onRuntimeInitialized() {
      delete detect.then;
      console.log('runtime init');
      resolve(detect);
    },
  });
});
