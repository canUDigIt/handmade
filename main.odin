package main

import win "core:sys/windows"
import "core:encoding/endian"

ERROR_SUCCESS :: 0
ERROR_DEVICE_NOT_CONNECTED :: 1167
XUSER_MAX_COUNT :: 4

XINPUT_STATE :: struct {
  dwPacketNumber: u32,
  Gamepad: XINPUT_GAMEPAD,
}

XINPUT_GAMEPAD :: struct {
  wButtons: u16,
  bLeftTrigger: u8,
  bRightTrigger: u8,
  sThumbLX: i16,
  sThumbLY: i16,
  sThumbRX: i16,
  sThumbRY: i16,
}

XINPUT_VIBRATION :: struct {
  wLeftMotorSpeed: u16,
  wRightMotorSpeed: u16,
}

XInputGetStateType :: proc "stdcall" (dw_user_index: win.DWORD, p_state: ^XINPUT_STATE) -> win.DWORD
xInputGetStateStub :: proc "stdcall" (_: win.DWORD, _: ^XINPUT_STATE) -> win.DWORD {
    return ERROR_DEVICE_NOT_CONNECTED;
}
xinput_get_state: XInputGetStateType = xInputGetStateStub;

XInputSetStateType :: proc "stdcall" (dw_user_index: win.DWORD, p_vibration: ^XINPUT_VIBRATION) -> win.DWORD
xInputSetStateStub :: proc "stdcall" (_: win.DWORD, _: ^XINPUT_VIBRATION) -> win.DWORD {
    return ERROR_DEVICE_NOT_CONNECTED;
}
xinput_set_state: XInputSetStateType = xInputSetStateStub;

win32_load_xinput :: proc() {
  x_input_library: win.HMODULE = win.LoadLibraryW(win.utf8_to_wstring("xinput1_4.dll"));
  if x_input_library == nil {
    x_input_library = win.LoadLibraryW(win.utf8_to_wstring("xinput1_3.dll"))
  }
  if x_input_library != nil {
    xinput_get_state = XInputGetStateType(win.GetProcAddress(x_input_library, "XInputGetState"))
    xinput_set_state = XInputSetStateType(win.GetProcAddress(x_input_library, "XInputSetState"))
  }
}

DS_OK :: 0

WAVE_FORMAT_PCM :: 1
DSBCAPS_PRIMARYBUFFER :: 1
DSSCL_PRIORITY :: 0x00000002

WAVEFORMATEX :: struct {
  wFormatTag: u16,
  nChannels: u16,
  nSamplesPerSec: u32,
  nAvgBytesPerSec: u32,
  nBlockAlign: u16,
  wBitsPerSample: u16,
  cbSize: u16,
}

DSBUFFERDESC :: struct {
  dwSize: u32,
  dwFlags: u32,
  dwBufferBytes: u32,
  dwReserved: u32,
  lpwfxFormat: ^WAVEFORMATEX,
  guid3DAlgorithm: win.GUID,
}

DSCAPS :: struct {
  dwSize: win.DWORD,
  dwFlags: win.DWORD,
  dwMinSecondarySampleRate: win.DWORD,
  dwMaxSecondarySampleRate: win.DWORD,
  dwPrimaryBuffers: win.DWORD,
  dwMaxHwMixingAllBuffers: win.DWORD,
  dwMaxHwMixingStaticBuffers: win.DWORD,
  dwMaxHwMixingStreamingBuffers: win.DWORD,
  dwFreeHwMixingAllBuffers: win.DWORD,
  dwFreeHwMixingStaticBuffers: win.DWORD,
  dwFreeHwMixingStreamingBuffers: win.DWORD,
  dwMaxHw3DAllBuffers: win.DWORD,
  dwMaxHw3DStaticBuffers: win.DWORD,
  dwMaxHw3DStreamingBuffers: win.DWORD,
  dwFreeHw3DAllBuffers: win.DWORD,
  dwFreeHw3DStaticBuffers: win.DWORD,
  dwFreeHw3DStreamingBuffers: win.DWORD,
  dwTotalHwMemBytes: win.DWORD,
  dwFreeHwMemBytes: win.DWORD,
  dwMaxContigFreeHwMemBytes: win.DWORD,
  dwUnlockTransferRateHwBuffers: win.DWORD,
  dwPlayCpuOverheadSwBuffers: win.DWORD,
  dwReserved1: win.DWORD,
  dwReserved2: win.DWORD,
}

IDirectSound :: struct {
  #subtype iunknown: win.IUnknown,
  using idirectsound_vtable: ^IDirectSound_VTable,
}

IDirectSound_VTable :: struct {
  using iunknown_vtable: win.IUnknown_VTable,
  CreateSoundBuffer: proc "system" (this: ^IDirectSound, pcDSBufferDesc: ^DSBUFFERDESC, ppDSBuffer: ^^IDirectSoundBuffer, pUnkOuter: win.LPUNKNOWN) -> win.HRESULT,
  GetCaps: proc "system" (this: ^IDirectSound, pDSCaps: ^DSCAPS) -> win.HRESULT,
  DuplicateSoundBuffer: proc "system" (this: ^IDirectSound, pDSBufferOriginal: ^IDirectSoundBuffer, ppDSBufferDuplicate: ^^IDirectSoundBuffer) -> win.HRESULT,
  SetCooperativeLevel: proc "system" (this: ^IDirectSound, hwnd: win.HWND, dwLevel: win.DWORD) -> win.HRESULT,
  Compact: proc "system" (this: ^IDirectSound) -> win.HRESULT,
  GetSpeakerConfig: proc "system" (this: ^IDirectSound, pdwSpeakerConfig: win.LPDWORD) -> win.HRESULT,
  SetSpeakerConfig: proc "system" (this: ^IDirectSound, dwSpeakerConfig: win.DWORD) -> win.HRESULT,
  Initialize: proc "system" (this: ^IDirectSound, pcGuidDevice: win.LPCGUID) -> win.HRESULT,
}

IDirectSoundBuffer :: struct {
  #subtype iunknown: win.IUnknown,
  using idirectsoundbuffer_vtable: ^IDirectSoundBuffer_VTable,
}

IDirectSoundBuffer_VTable :: struct {
  using iunknown_vtable: win.IUnknown_VTable,
  SetFormat: proc "system" (this: ^IDirectSoundBuffer, pcfxFormat: ^WAVEFORMATEX) ->win.HRESULT,
}

DirectSoundCreateFn :: proc "stdcall" (lpGuid: win.LPGUID, ppDS: ^^IDirectSound, pUnkOuter: win.LPUNKNOWN) -> win.HRESULT
win32_init_dsound :: proc (window: win.HWND, samples_per_second: u32, buffer_size: u32) {
    //NOTE(tracy): Load the library
    dsound_library: win.HMODULE = win.LoadLibraryW(win.utf8_to_wstring("dsound.dll"))

    if dsound_library != nil {
        //NOTE(tracy): Get a DirectSound object! - cooperative
        DirectSoundCreate: DirectSoundCreateFn = DirectSoundCreateFn(win.GetProcAddress(dsound_library, "DirectSoundCreate"));
        direct_sound: ^IDirectSound
        if (DirectSoundCreate(nil, &direct_sound, nil) == DS_OK) {
          channels :: 2;
          bits_per_sample :: 16;
          block_align :: (channels * bits_per_sample) / 8;
          wave_format: WAVEFORMATEX = {}
          wave_format.cbSize = size_of(WAVEFORMATEX)
          wave_format.wFormatTag = WAVE_FORMAT_PCM
          wave_format.nChannels = channels
          wave_format.wBitsPerSample = bits_per_sample
          wave_format.nSamplesPerSec = samples_per_second
          wave_format.nBlockAlign = block_align
          wave_format.nAvgBytesPerSec = samples_per_second * block_align

            if direct_sound->SetCooperativeLevel(window, DSSCL_PRIORITY) == DS_OK {
              buffer_description: DSBUFFERDESC = {}
              buffer_description.dwSize = size_of(DSBUFFERDESC)
              buffer_description.dwFlags = DSBCAPS_PRIMARYBUFFER

              //NOTE(tracy): "Create" a primary buffer
              primary_buffer: ^IDirectSoundBuffer
              if direct_sound->CreateSoundBuffer(&buffer_description, &primary_buffer, nil) == DS_OK {
                if primary_buffer->SetFormat(&wave_format) == DS_OK {
                    // NOTE(tracy): We have finally set the format!
                } else {
                    // TODO(tracy): Diagnostic
                }
              }
            } else {}

            //NOTE(tracy): "Create" a secondary buffer
            buffer_description: DSBUFFERDESC = {}
            buffer_description.dwSize = size_of(DSBUFFERDESC)
            buffer_description.dwFlags = 0
            buffer_description.dwBufferBytes = buffer_size
            buffer_description.lpwfxFormat = &wave_format

            secondary_buffer: ^IDirectSoundBuffer
            if direct_sound->CreateSoundBuffer(&buffer_description, &secondary_buffer, nil) == DS_OK {
                if secondary_buffer->SetFormat(&wave_format) == DS_OK {
                    // NOTE(tracy): We have finally set the format!
                } else {
                    // TODO(tracy): Diagnostic
                }
            }
            //NOTE(tracy): Start it playing!
        } else {}
    } else {
        // TODO(tracy): Diagnostic
    }
}


Win32OffscreenBuffer :: struct {
  info: win.BITMAPINFO,
  memory: [^]u8,
  width, height, pitch, bytes_per_pixel: i32,
}

global_backbuffer: Win32OffscreenBuffer = {}

win32_get_window_dimensions :: proc "stdcall" (wnd: win.HWND) -> (i32, i32) {
  client_rect: win.RECT
  win.GetClientRect(wnd, &client_rect)
  width := client_rect.right - client_rect.left 
  height := client_rect.bottom - client_rect.top
  return width, height
}

render_weird_gradiant :: proc "stdcall" (buffer: ^Win32OffscreenBuffer, blue_offset: i32, green_offset: i32) {
  if buffer.memory != nil {
    for y: i32 = 0; y < buffer.height; y += 1 {
      start := y
      row := buffer.memory[start * buffer.pitch:][:buffer.pitch]
      for x: i32 = 0; x < buffer.width; x += 1 {
        // Pixels in memory: RR GG BB xx
        // 0x xxRRGGBB - little endian
        blue := x + blue_offset
        green := y + green_offset
        color := ((green) << 8) | blue
        pixel_start := (x * 4)
        endian.put_i32(row[pixel_start:][:4], .Little, color)
      }
    }
  }
}

win32_resize_dib_section :: proc "stdcall" (buffer: ^Win32OffscreenBuffer, width, height: i32) {
  if buffer.memory != nil {
    win.VirtualFree(buffer.memory, 0, win.MEM_RELEASE)
  }

  buffer.width = width
  buffer.height = height
  buffer.bytes_per_pixel = 4

  buffer.info.bmiHeader.biSize = size_of(buffer.info.bmiHeader)
  buffer.info.bmiHeader.biWidth = width
  buffer.info.bmiHeader.biHeight = -height
  buffer.info.bmiHeader.biPlanes = 1
  buffer.info.bmiHeader.biBitCount = 32
  buffer.info.bmiHeader.biCompression = win.BI_RGB

  // NOTE(tracy): Thank you to Chris Hecker of Spy Part fame
  // for clarifying the deal with StretchDIBits and BitBlt!
  // No more DC for us.
  bitmap_memory_size : uint = uint((width * height) * buffer.bytes_per_pixel)
  buffer.memory = ([^]u8)(win.VirtualAlloc(
      nil,
      bitmap_memory_size,
      win.MEM_RESERVE | win.MEM_COMMIT,
      win.PAGE_READWRITE,
  ))

  buffer.pitch = (width * buffer.bytes_per_pixel)
  // TODO(tracy): Probably clear this to black
}

win32_copy_buffer_to_window :: proc "stdcall" (
  device_context: win.HDC,
  window_width,
  window_height: i32,
  buffer: ^Win32OffscreenBuffer,
  x, y: i32,
  width, height: i32
) {
  win.StretchDIBits(
    device_context,
    // x, y, width, height
    // x, y, width, height
    0, 0, window_width, window_height,
    0, 0, i32(buffer.width), i32(buffer.height),
    buffer.memory,
    &buffer.info,
    win.DIB_RGB_COLORS,
    win.SRCCOPY
  )
}


win32_main_window_callback :: proc "stdcall" (wnd: win.HWND, msg: win.UINT, wparam: win.WPARAM, lparam: win.LPARAM) -> win.LRESULT {
  result: win.LRESULT
  switch(msg) {
  case win.WM_DESTROY:
    global_running = false
    win.OutputDebugStringA("WM_DESTROY\n")

  case win.WM_CLOSE:
    global_running = false
    win.OutputDebugStringA("WM_CLOSE\n")

  case win.WM_PAINT:
    dwidth, dheight := win32_get_window_dimensions(wnd)
    ps: win.PAINTSTRUCT
    device_context := win.BeginPaint(wnd, &ps)
    x := ps.rcPaint.left
    y := ps.rcPaint.top
    width := ps.rcPaint.right - ps.rcPaint.left
    height := ps.rcPaint.bottom - ps.rcPaint.top
    win32_copy_buffer_to_window(
      device_context,
      dwidth,
      dheight,
      &global_backbuffer,
      x,
      y,
      width,
      height
    )
    win.EndPaint(wnd, &ps)

  case:
    result = win.DefWindowProcW(wnd, msg, wparam, lparam)
  }
  return result
}

global_running := false

main :: proc() {
  win32_load_xinput()
  win32_resize_dib_section(&global_backbuffer, 1280, 720)

  instance: win.HINSTANCE = win.HINSTANCE(win.GetModuleHandleA(nil))

  window_class := win.WNDCLASSW{}
  window_class.style = win.CS_HREDRAW | win.CS_VREDRAW
  window_class.lpfnWndProc = win32_main_window_callback
  window_class.hInstance = instance
  window_class.lpszClassName = win.utf8_to_wstring("HandmadeHeroWindowClass")

  if win.RegisterClassW(&window_class) != 0 {
    window_handle := win.CreateWindowW(
      window_class.lpszClassName,
      win.utf8_to_wstring("Handmade Hero"),
      win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
      win.CW_USEDEFAULT,
      win.CW_USEDEFAULT,
      win.CW_USEDEFAULT,
      win.CW_USEDEFAULT,
      nil,
      nil,
      instance,
      nil)

    if window_handle != nil {
      x_offset: i32= 0
      y_offset: i32= 0

      win32_init_dsound(window_handle, 48_000, 48_000 * size_of(i16) * 2)

      global_running = true
      for global_running {
        message: win.MSG
        for win.PeekMessageW(&message, nil, 0, 0, win.PM_REMOVE) {
          if message.message == win.WM_QUIT {
            global_running = false
          }

          win.TranslateMessage(&message)
          win.DispatchMessageW(&message)
        }

        for i in 0..<XUSER_MAX_COUNT {
          controller_state: XINPUT_STATE
          if xinput_get_state(u32(i), &controller_state) == ERROR_SUCCESS {
            // NOTE(tracy): This controller is plugged in
            // TODO(tracy): See if controllerState.dwPacketNumber increments too rapidly
            pad: XINPUT_GAMEPAD = controller_state.Gamepad;

            // x_offset += i32(pad.sThumbLX)
            // y_offset += i32(pad.sThumbLY)
            x_offset += 1 if pad.sThumbLX > 0 else 0
            y_offset += 1 if pad.sThumbLY > 0 else 0
          }
        }

        render_weird_gradiant(&global_backbuffer, x_offset, y_offset)

        dc := win.GetDC(window_handle)
        width, height := win32_get_window_dimensions(window_handle)
        win32_copy_buffer_to_window(
          dc,
          width,
          height,
          &global_backbuffer,
          0,
          0,
          width,
          height
        )
      }
    }
  }
  else {
    // TODO(tracy): Logging
  }
}
