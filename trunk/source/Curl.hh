#include <string>
#include <fstream>
#include <sstream>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

class CurlException {};
class TimeoutException : public CurlException {};
class UnsupportedProtocolException : public CurlException {};
class MalformedUrlException : public CurlException {};
class ConnectErrorException : public CurlException {};
class AccessDeniedException : public CurlException {};
class DoesNotExistException : public CurlException {};

class CurlWrapper
{
public:
  CurlWrapper () {
    SetConnectTimeout(20);
    SetMaxTime(-1);
    char* templ=strdup("/tmp/curl_downloadXXXXXX");
    mkstemp(templ);
    filename=templ;
    free(templ);
  }

  void SetConnectTimeout (int value) {connect_timeout = value;}
  void SetMaxTime (int value) {max_time = value;}

  void Download (std::string url) {
    GenParamString ();
    params << " " << url;
    //    std::cout << params.str () << std::endl;
    ExecCurl ();
  }

  void Download (std::string url, unsigned int start, unsigned int end);

  std::string GetCommand () {
    return params.str();
  }

  void SetFile (std::string name) {filename=name;}

  std::ifstream* OpenFile () {
    std::ifstream* r=new std::ifstream();
    r -> open(filename.c_str());
    return r;
  }

  void RemoveFile () {unlink (filename.c_str());}

private:

  void ExecCurl () {
    int ret=system(GetCommand().c_str());
    if (ret != 0)
      switch (ret) {
      case 1:
	throw UnsupportedProtocolException();
      case 3:
      case 4:
      case 49:
	throw MalformedUrlException();
      case 5:
      case 6:
      case 7:
      case 35:
	throw ConnectErrorException();
      case 9:
      case 10:
      case 46:
	throw AccessDeniedException();
      case 22:
	throw DoesNotExistException();
      case 28:
	throw TimeoutException();
      default:
	throw CurlException();
      }
  }

  void GenParamString () {
    std::string empty("");
    params.rdbuf() -> str(empty);
    params << "curl -o " << filename;
    if (connect_timeout > 0)
      params << " --connect-timeout " << connect_timeout;
    if (max_time > 0)
      params << " --max-time " << max_time;
  }

  int connect_timeout;
  int max_time;
  std::string filename;

  std::stringstream params;
};
