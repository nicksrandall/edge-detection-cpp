#include "emscripten/bind.h"
#include "emscripten/val.h"
#include "opencv2/imgproc/imgproc.hpp"
#include <string>
#include <math.h>
#include <zbar.h>

using namespace emscripten;
using namespace cv;

Mat src, dst;
zbar::ImageScanner scanner;
zbar::Image *img;

emscripten::val detect(std::string buffer, int width, int height)
{
  src = Mat(height, width, 24, (void *)buffer.data(), 0);
  cvtColor(src, dst, CV_RGBA2GRAY);
  // blur(src_g ray, src_gray, Size(3, 3));
  // dst = Mat();
  Canny(dst, dst, 150, 300, 3);
  uchar *input = dst.data;
  uchar *output = src.data;
  const int channels = dst.channels();
  const int length = width * height;
  for (int i = 0, j = 0; i < length; i += channels, j += 4)
  {
    if (input[i] == 0xff)
    {
      output[j] = 0xff;
      output[j + 1] = 0x9E;
      output[j + 2] = 0x24;
      output[j + 3] = 0xff;
    }
  }
  return emscripten::val(emscripten::memory_view<unsigned char>(length * 4, output));
}

std::string scan(std::string buffer, int width, int height)
{
  src = Mat(height, width, 24, (void *)buffer.data(), 0);
  cvtColor(src, dst, CV_RGBA2GRAY);
  if (img)
  {
    delete img;
  }
  img = new zbar::Image(dst.cols, dst.rows, "Y800", (uchar *)dst.data, dst.cols * dst.rows);
  int n = scanner.scan(*img);
  std::string output;
  for (zbar::Image::SymbolIterator symbol = img->symbol_begin(); symbol != img->symbol_end(); ++symbol)
  {
    output += symbol->get_data() + "|";
  }
  return output;
}

void release()
{
  src.release();
  dst.release();
}

EMSCRIPTEN_BINDINGS(my_module)
{
  function("detect", &detect);
  function("scan", &scan);
  function("release", &release);
}

int main(int argc, char **argv)
{
  scanner.set_config(zbar::ZBAR_QRCODE, zbar::ZBAR_CFG_ENABLE, 1);
}
