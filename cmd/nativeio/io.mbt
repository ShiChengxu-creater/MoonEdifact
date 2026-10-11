///|
pub(all) enum FileError {
  IoFailure
  TooLarge
  InvalidLimit
} derive(Debug, Eq)

///|
pub extend FileError with @debug.Debug::{to_repr}

///|
pub extend FileError with Eq::{equal, not_equal}

///|
#borrow(path)
extern "C" fn open_readonly(path : Bytes) -> Int64 = "moonedifact_open_readonly"

///|
extern "C" fn file_size(handle : Int64) -> Int64 = "moonedifact_file_size"

///|
#borrow(buffer)
extern "C" fn read_chunk(handle : Int64, buffer : Bytes, count : Int) -> Int = "moonedifact_read_chunk"

///|
extern "C" fn close_file(handle : Int64) -> Int = "moonedifact_close_file"

///|
#borrow(message)
extern "C" fn stderr_bytes(message : Bytes) -> Unit = "moonedifact_stderr"

///|
extern "C" fn exit_process(code : Int) -> Unit = "moonedifact_exit"

///|
/// Read one regular file with at most max_bytes + one probe byte from the open handle.
/// Oversized files are rejected before full allocation. Every result closes the handle.
pub fn read_file(
  path : StringView,
  max_bytes~ : Int,
) -> Result[Bytes, FileError] {
  if max_bytes <= 0 {
    return Err(InvalidLimit)
  }
  let handle = open_readonly(@utf8.encode(path))
  if handle == 0L {
    return Err(IoFailure)
  }
  let size = file_size(handle)
  if size < 0L {
    ignore(close_file(handle))
    return Err(IoFailure)
  }
  if size > max_bytes.to_int64() {
    ignore(close_file(handle))
    return Err(TooLarge)
  }
  let buffer = Bytes::make(4096, b'\x00')
  let output = @buffer.Buffer(size_hint=(4096).min(max_bytes))
  let mut used = 0
  while true {
    let remaining = max_bytes - used
    let count = if remaining < 4096 { remaining + 1 } else { 4096 }
    let read = read_chunk(handle, buffer, count)
    if read < 0 || read > count {
      ignore(close_file(handle))
      return Err(IoFailure)
    }
    if read == 0 {
      if close_file(handle) != 0 {
        return Err(IoFailure)
      }
      return Ok(output.to_bytes())
    }
    if read > remaining {
      ignore(close_file(handle))
      return Err(TooLarge)
    }
    output.write_bytes(buffer[:read])
    used = used + read
  } nobreak {
    Err(IoFailure)
  }
}

///|
/// Write a static CLI error or help string to standard error.
pub fn stderr(message : StringView) -> Unit {
  stderr_bytes(@utf8.encode(message))
}

///|
/// Terminate the native CLI with its documented status code.
pub fn exit(code : Int) -> Unit {
  exit_process(code)
}
