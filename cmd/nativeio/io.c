/* Original native adapter. The parser and reports are implemented in MoonBit. */
#ifndef _WIN32
#define _POSIX_C_SOURCE 200809L
#define _FILE_OFFSET_BITS 64
#endif
#include "moonbit.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#ifdef _WIN32
#include <windows.h>
#include <io.h>
#else
#include <fcntl.h>
#include <unistd.h>
#endif

/* Handles are private to the MoonBit adapter; all byte arguments are borrowed. */
MOONBIT_FFI_EXPORT int64_t moonedifact_open_readonly(moonbit_bytes_t path) {
  int32_t length = Moonbit_array_length(path);
  if (length <= 0 || length > 65535 || memchr(path, 0, (size_t)length)) return 0;
  FILE *file = NULL;
#ifdef _WIN32
  int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                            (const char *)path, length, NULL, 0);
  if (n <= 0) return 0;
  wchar_t *wide = (wchar_t *)malloc(((size_t)n + 1) * sizeof(wchar_t));
  if (!wide) return 0;
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                          (const char *)path, length, wide, n) != n) {
    free(wide);
    return 0;
  }
  wide[n] = 0;
  file = _wfopen(wide, L"rb");
  free(wide);
  if (!file) return 0;
  struct _stat64 info;
  if (_fstat64(_fileno(file), &info) != 0 ||
      (info.st_mode & _S_IFMT) != _S_IFREG) {
    fclose(file);
    return 0;
  }
#else
  char *name = (char *)malloc((size_t)length + 1);
  if (!name) return 0;
  memcpy(name, path, (size_t)length);
  name[length] = 0;
  int descriptor = open(name, O_RDONLY | O_NONBLOCK);
  free(name);
  if (descriptor < 0) return 0;
  struct stat info;
  if (fstat(descriptor, &info) != 0 || !S_ISREG(info.st_mode)) {
    close(descriptor);
    return 0;
  }
  file = fdopen(descriptor, "rb");
  if (!file) {
    close(descriptor);
    return 0;
  }
#endif
  return (int64_t)(intptr_t)file;
}

MOONBIT_FFI_EXPORT int64_t moonedifact_file_size(int64_t handle) {
  if (!handle) return -1;
  FILE *file = (FILE *)(intptr_t)handle;
#ifdef _WIN32
  struct _stat64 info;
  if (_fstat64(_fileno(file), &info) != 0) return -1;
#else
  struct stat info;
  if (fstat(fileno(file), &info) != 0) return -1;
#endif
  return (int64_t)info.st_size;
}

MOONBIT_FFI_EXPORT int32_t moonedifact_read_chunk(
    int64_t handle, moonbit_bytes_t buffer, int32_t count) {
  if (!handle || count < 0 || count > Moonbit_array_length(buffer)) return -1;
  FILE *file = (FILE *)(intptr_t)handle;
  size_t got = fread(buffer, 1, (size_t)count, file);
  if (got < (size_t)count && ferror(file)) return -1;
  return (int32_t)got;
}

MOONBIT_FFI_EXPORT int32_t moonedifact_close_file(int64_t handle) {
  return handle ? fclose((FILE *)(intptr_t)handle) : -1;
}

MOONBIT_FFI_EXPORT void moonedifact_stderr(moonbit_bytes_t message) {
  fwrite(message, 1, (size_t)Moonbit_array_length(message), stderr);
  fputc('\n', stderr);
}

MOONBIT_FFI_EXPORT void moonedifact_exit(int32_t code) { exit(code); }
