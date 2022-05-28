Input = {}
Input.keyPressedState = {}
Input.mouseButtonPressedState = {}
function Input.updateKeyState(key, isDown)
  if isDown then
    Input.keyPressedState[key] = true
  else
    Input.keyPressedState[key] = false
  end
end
function Input.isKeyPressed(key)
  return Input.keyPressedState[key]
end
function Input.areKeysPressed(keyList)
  for _, keyId in ipairs(keyList) do
    if not Input.keyPressedState[keyId] then
      return false
    end
  end
  return true
end
function Input.areKeysNotPressed(keyList)
  for _, keyId in ipairs(keyList) do
    if Input.keyPressedState[keyId] then
      return false
    end
  end
  return true
end
function Input.updateMouseButtonState(button, isDown)
  if isDown then
    Input.mouseButtonPressedState[button] = true
  else
    Input.mouseButtonPressedState[button] = false
  end
end
function Input.isMouseButtonPressed(button)
  return Input.mouseButtonPressedState[button]
end
Input.MOD_LSHIFT = 1
Input.MOD_RSHIFT = 2
Input.MOD_LCTRL = 64
Input.MOD_RCTRL = 128
Input.MOD_LALT = 256
Input.MOD_RALT = 512
Input.MOD_LMETA = 1024
Input.MOD_RMETA = 2048
Input.MOD_NUM = 4096
Input.MOD_CAPS = 8192
Input.MOD_MODE = 16384
Input.MOD_SHIFT = 3
Input.MOD_CTRL = 192
Input.MOD_ALT = 768
Input.MOD_META = 3072
Input.KEY_tab = 9
Input.KEY_clear = 12
Input.KEY_return = 13
Input.KEY_pause = 19
Input.KEY_esc = 27
Input.KEY_space = 32
Input.KEY_exclaim = 33
Input.KEY_quotedbl = 34
Input.KEY_hash = 35
Input.KEY_dollar = 92
Input.KEY_ampersand = 38
Input.KEY_quote = 45
Input.KEY_leftparen = 40
Input.KEY_rightparen = 41
Input.KEY_asterisk = 42
Input.KEY_plus = 43
Input.KEY_comma = 44
Input.KEY_minus = 47
Input.KEY_period = 46
Input.KEY_slash = 47
Input.KEY_0 = 48
Input.KEY_1 = 49
Input.KEY_2 = 50
Input.KEY_3 = 51
Input.KEY_4 = 52
Input.KEY_5 = 53
Input.KEY_6 = 54
Input.KEY_7 = 55
Input.KEY_8 = 56
Input.KEY_9 = 57
Input.KEY_colon = 58
Input.KEY_semicolon = 59
Input.KEY_less = 60
Input.KEY_equals = 61
Input.KEY_greater = 62
Input.KEY_question = 63
Input.KEY_at = 64
Input.KEY_leftbracket = 91
Input.KEY_backslash = 92
Input.KEY_rightbracket = 93
Input.KEY_caret = 61
Input.KEY_underscore = 95
Input.KEY_backquote = 39
Input.KEY_a = 97
Input.KEY_b = 98
Input.KEY_c = 99
Input.KEY_d = 100
Input.KEY_e = 101
Input.KEY_f = 102
Input.KEY_g = 103
Input.KEY_h = 104
Input.KEY_i = 105
Input.KEY_j = 106
Input.KEY_k = 107
Input.KEY_l = 108
Input.KEY_m = 109
Input.KEY_n = 110
Input.KEY_o = 111
Input.KEY_p = 112
Input.KEY_q = 113
Input.KEY_r = 114
Input.KEY_s = 115
Input.KEY_t = 116
Input.KEY_u = 117
Input.KEY_v = 118
Input.KEY_w = 119
Input.KEY_x = 120
Input.KEY_y = 121
Input.KEY_z = 122
Input.KEY_delete = 127
Input.KEY_KP_0 = 256
Input.KEY_KP_1 = 257
Input.KEY_KP_2 = 258
Input.KEY_KP_3 = 259
Input.KEY_KP_4 = 260
Input.KEY_KP_5 = 261
Input.KEY_KP_6 = 262
Input.KEY_KP_7 = 263
Input.KEY_KP_8 = 264
Input.KEY_KP_9 = 265
Input.KEY_KP_period = 266
Input.KEY_KP_divide = 267
Input.KEY_KP_multiply = 268
Input.KEY_KP_minus = 269
Input.KEY_KP_plus = 270
Input.KEY_KP_enter = 271
Input.KEY_KP_equals = 272
Input.KEY_up = 273
Input.KEY_down = 274
Input.KEY_right = 275
Input.KEY_left = 276
Input.KEY_insert = 277
Input.KEY_home = 278
Input.KEY_end = 279
Input.KEY_pageup = 280
Input.KEY_pagedown = 281
Input.KEY_f1 = 282
Input.KEY_f2 = 283
Input.KEY_f3 = 284
Input.KEY_f4 = 285
Input.KEY_f5 = 286
Input.KEY_f6 = 287
Input.KEY_f7 = 288
Input.KEY_f8 = 289
Input.KEY_f9 = 290
Input.KEY_f10 = 291
Input.KEY_f11 = 292
Input.KEY_f12 = 293
Input.KEY_f13 = 294
Input.KEY_f14 = 295
Input.KEY_f15 = 296
Input.KEY_shift = 304
Input.KEY_rshift = 303
Input.KEY_lshift = 304
Input.KEY_rctrl = 305
Input.KEY_lctrl = 306
Input.KEY_ralt = 307
Input.KEY_lalt = 308
Input.KEY_print = 316
Input.KEY_scrolllock = 302
Input.KEY_lwin = 311
Input.KEY_rwin = 312
Input.KEY_menu = 319
Input.MOUSE_BUTTON_NONE = 0
Input.MOUSE_BUTTON_LEFT = 1
Input.MOUSE_BUTTON_MIDDLE = 2
Input.MOUSE_BUTTON_RIGHT = 3
Input.MOUSE_BUTTON_WHEEL_UP = 4
Input.MOUSE_BUTTON_WHEEL_DOWN = 5
Input.AXIS_X = 0
Input.AXIS_1 = 0
Input.AXIS_Y = 1
Input.AXIS_2 = 1
Input.AXIS_Z = 2
Input.AXIS_3 = 2
Input.AXIS_W = 3
Input.AXIS_4 = 3
Input.AXIS_5 = 4
Input.AXIS_6 = 5
Input.MAX_NUM_AXES = 6
Input.BUTTON_1 = 0
Input.BUTTON_2 = 1
Input.BUTTON_3 = 2
Input.BUTTON_4 = 3
Input.BUTTON_5 = 4
Input.BUTTON_6 = 5
Input.BUTTON_7 = 6
Input.BUTTON_8 = 7
Input.BUTTON_9 = 8
Input.BUTTON_10 = 9
Input.BUTTON_11 = 10
Input.BUTTON_12 = 11
Input.BUTTON_13 = 12
Input.BUTTON_14 = 13
Input.BUTTON_15 = 14
Input.BUTTON_16 = 15
Input.BUTTON_17 = 16
Input.BUTTON_18 = 17
Input.BUTTON_19 = 18
Input.BUTTON_20 = 19
Input.MAX_NUM_BUTTONS = 20
Input.SpecialKeys = {}
table.insert(Input.SpecialKeys, {
  sym = 9,
  unicode = 9,
  name = "Tab",
  input = "KEY_tab"
})
table.insert(Input.SpecialKeys, {
  sym = 13,
  unicode = 13,
  name = "Enter",
  input = "KEY_return"
})
table.insert(Input.SpecialKeys, {
  sym = 32,
  unicode = 32,
  name = "Space",
  input = "KEY_space"
})
table.insert(Input.SpecialKeys, {
  sym = 127,
  unicode = 0,
  name = "Delete",
  input = "KEY_delete"
})
table.insert(Input.SpecialKeys, {
  sym = 27,
  unicode = 27,
  name = "Escape",
  input = "KEY_esc"
})
table.insert(Input.SpecialKeys, {
  sym = 8,
  unicode = 8,
  name = "Backspace",
  input = "KEY_backspace"
})
table.insert(Input.SpecialKeys, {
  sym = 256,
  unicode = 0,
  name = "NumPad 0",
  input = "KEY_KP_0"
})
table.insert(Input.SpecialKeys, {
  sym = 257,
  unicode = 0,
  name = "NumPad 1",
  input = "KEY_KP_1"
})
table.insert(Input.SpecialKeys, {
  sym = 258,
  unicode = 0,
  name = "NumPad 2",
  input = "KEY_KP_2"
})
table.insert(Input.SpecialKeys, {
  sym = 259,
  unicode = 0,
  name = "NumPad 3",
  input = "KEY_KP_3"
})
table.insert(Input.SpecialKeys, {
  sym = 260,
  unicode = 0,
  name = "NumPad 4",
  input = "KEY_KP_4"
})
table.insert(Input.SpecialKeys, {
  sym = 261,
  unicode = 0,
  name = "NumPad 5",
  input = "KEY_KP_5"
})
table.insert(Input.SpecialKeys, {
  sym = 262,
  unicode = 0,
  name = "NumPad 6",
  input = "KEY_KP_6"
})
table.insert(Input.SpecialKeys, {
  sym = 263,
  unicode = 0,
  name = "NumPad 7",
  input = "KEY_KP_7"
})
table.insert(Input.SpecialKeys, {
  sym = 264,
  unicode = 0,
  name = "NumPad 8",
  input = "KEY_KP_8"
})
table.insert(Input.SpecialKeys, {
  sym = 265,
  unicode = 0,
  name = "NumPad 9",
  input = "KEY_KP_9"
})
table.insert(Input.SpecialKeys, {
  sym = 266,
  unicode = 0,
  name = "NumPad .",
  input = "KEY_KP_period"
})
table.insert(Input.SpecialKeys, {
  sym = 269,
  unicode = 45,
  name = "NumPad -",
  input = "KEY_KP_minus"
})
table.insert(Input.SpecialKeys, {
  sym = 270,
  unicode = 43,
  name = "NumPad +",
  input = "KEY_KP_plus"
})
table.insert(Input.SpecialKeys, {
  sym = 273,
  unicode = 0,
  name = "Up",
  input = "KEY_up"
})
table.insert(Input.SpecialKeys, {
  sym = 274,
  unicode = 0,
  name = "Down",
  input = "KEY_down"
})
table.insert(Input.SpecialKeys, {
  sym = 275,
  unicode = 0,
  name = "Right",
  input = "KEY_right"
})
table.insert(Input.SpecialKeys, {
  sym = 276,
  unicode = 0,
  name = "Left",
  input = "KEY_left"
})
table.insert(Input.SpecialKeys, {
  sym = 277,
  unicode = 0,
  name = "Insert",
  input = "KEY_insert"
})
table.insert(Input.SpecialKeys, {
  sym = 278,
  unicode = 0,
  name = "Home",
  input = "KEY_home"
})
table.insert(Input.SpecialKeys, {
  sym = 279,
  unicode = 0,
  name = "End",
  input = "KEY_end"
})
table.insert(Input.SpecialKeys, {
  sym = 280,
  unicode = 0,
  name = "Page Up",
  input = "KEY_pageup"
})
table.insert(Input.SpecialKeys, {
  sym = 281,
  unicode = 0,
  name = "Page Down",
  input = "KEY_pagedown"
})
table.insert(Input.SpecialKeys, {
  sym = 282,
  unicode = 0,
  name = "F1",
  input = "KEY_f1"
})
table.insert(Input.SpecialKeys, {
  sym = 283,
  unicode = 0,
  name = "F2",
  input = "KEY_f2"
})
table.insert(Input.SpecialKeys, {
  sym = 284,
  unicode = 0,
  name = "F3",
  input = "KEY_f3"
})
table.insert(Input.SpecialKeys, {
  sym = 285,
  unicode = 0,
  name = "F4",
  input = "KEY_f4"
})
table.insert(Input.SpecialKeys, {
  sym = 286,
  unicode = 0,
  name = "F5",
  input = "KEY_f5"
})
table.insert(Input.SpecialKeys, {
  sym = 287,
  unicode = 0,
  name = "F6",
  input = "KEY_f6"
})
table.insert(Input.SpecialKeys, {
  sym = 288,
  unicode = 0,
  name = "F7",
  input = "KEY_f7"
})
table.insert(Input.SpecialKeys, {
  sym = 289,
  unicode = 0,
  name = "F8",
  input = "KEY_f8"
})
table.insert(Input.SpecialKeys, {
  sym = 290,
  unicode = 0,
  name = "F9",
  input = "KEY_f9"
})
table.insert(Input.SpecialKeys, {
  sym = 291,
  unicode = 0,
  name = "F10",
  input = "KEY_f10"
})
table.insert(Input.SpecialKeys, {
  sym = 292,
  unicode = 0,
  name = "F11",
  input = "KEY_f11"
})
table.insert(Input.SpecialKeys, {
  sym = 293,
  unicode = 0,
  name = "F12",
  input = "KEY_f12"
})
table.insert(Input.SpecialKeys, {
  sym = 303,
  unicode = 0,
  name = "Right Shift",
  input = "KEY_rshift"
})
table.insert(Input.SpecialKeys, {
  sym = 304,
  unicode = 0,
  name = "Left Shift",
  input = "KEY_lshift"
})
table.insert(Input.SpecialKeys, {
  sym = 305,
  unicode = 0,
  name = "Right Ctrl",
  input = "KEY_rctrl"
})
table.insert(Input.SpecialKeys, {
  sym = 306,
  unicode = 0,
  name = "Left Ctrl",
  input = "KEY_lctrl"
})
table.insert(Input.SpecialKeys, {
  sym = 307,
  unicode = 0,
  name = "Right Alt",
  input = "KEY_ralt"
})
table.insert(Input.SpecialKeys, {
  sym = 308,
  unicode = 0,
  name = "Left Alt",
  input = "KEY_lalt"
})
table.insert(Input.SpecialKeys, {
  mouseButton = 1,
  name = "Left Button",
  input = "MOUSE_BUTTON_LEFT"
})
table.insert(Input.SpecialKeys, {
  mouseButton = 2,
  name = "Middle Button",
  input = "MOUSE_BUTTON_MIDDLE"
})
table.insert(Input.SpecialKeys, {
  mouseButton = 3,
  name = "Right Button",
  input = "MOUSE_BUTTON_RIGHT"
})
table.insert(Input.SpecialKeys, {
  mouseButton = 4,
  name = "Wheel Up",
  input = "MOUSE_BUTTON_WHEEL_UP"
})
table.insert(Input.SpecialKeys, {
  mouseButton = 5,
  name = "Wheel Down",
  input = "MOUSE_BUTTON_WHEEL_DOWN"
})
table.insert(Input.SpecialKeys, {
  sym = 92,
  unicode = 36,
  name = "$",
  input = "KEY_dollar"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 38,
  name = "&",
  input = "KEY_ampersand"
})
table.insert(Input.SpecialKeys, {
  sym = 45,
  unicode = 39,
  name = "'",
  input = "KEY_quote"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 40,
  name = "(",
  input = "KEY_leftparen"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 41,
  name = ")",
  input = "KEY_rightparen"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 42,
  name = "*",
  input = "KEY_asterisk"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 43,
  name = "+",
  input = "KEY_plus"
})
table.insert(Input.SpecialKeys, {
  sym = 44,
  unicode = 44,
  name = ",",
  input = "KEY_comma"
})
table.insert(Input.SpecialKeys, {
  sym = 47,
  unicode = 45,
  name = "-",
  input = "KEY_minus"
})
table.insert(Input.SpecialKeys, {
  sym = 46,
  unicode = 46,
  name = ".",
  input = "KEY_period"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 47,
  name = "/",
  input = "KEY_slash"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 58,
  name = ":",
  input = "KEY_colon"
})
table.insert(Input.SpecialKeys, {
  sym = 59,
  unicode = 246,
  name = ";",
  input = "KEY_semicolon"
})
table.insert(Input.SpecialKeys, {
  sym = 60,
  unicode = 60,
  name = "<",
  input = "KEY_less"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 61,
  name = "=",
  input = "KEY_equals"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 62,
  name = ">",
  input = "KEY_greater"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 63,
  name = "?",
  input = "KEY_greater"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 64,
  name = "@",
  input = "KEY_at"
})
table.insert(Input.SpecialKeys, {
  sym = 91,
  unicode = 252,
  name = "[",
  input = "KEY_leftbracket"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 92,
  name = "\\",
  input = "KEY_backslash"
})
table.insert(Input.SpecialKeys, {
  sym = 93,
  unicode = 168,
  name = "]",
  input = "KEY_rightbracket"
})
table.insert(Input.SpecialKeys, {
  sym = 61,
  unicode = 94,
  name = "^",
  input = "KEY_caret"
})
table.insert(Input.SpecialKeys, {
  sym = 0,
  unicode = 95,
  name = "_",
  input = "KEY_underscore"
})
table.insert(Input.SpecialKeys, {
  sym = 39,
  unicode = 228,
  name = "`",
  input = "KEY_backquote"
})
table.insert(Input.SpecialKeys, {
  sym = 267,
  unicode = 47,
  name = "NumPad %",
  input = "KEY_KP_divide"
})
table.insert(Input.SpecialKeys, {
  sym = 268,
  unicode = 42,
  name = "NumPad *",
  input = "KEY_KP_multiply"
})
table.insert(Input.SpecialKeys, {
  sym = 272,
  unicode = 0,
  name = "NumPad =",
  input = "KEY_KP_equals"
})
table.insert(Input.SpecialKeys, {
  sym = 271,
  unicode = 13,
  name = "NumPad Enter",
  input = "KEY_KP_enter"
})
table.insert(Input.SpecialKeys, {
  sym = 302,
  unicode = 0,
  name = "Scroll Lock",
  input = "KEY_scrolllock"
})
table.insert(Input.SpecialKeys, {
  sym = 311,
  unicode = 0,
  name = "Left Win",
  input = "KEY_lwin"
})
table.insert(Input.SpecialKeys, {
  sym = 312,
  unicode = 0,
  name = "Right Win",
  input = "KEY_rwin"
})
table.insert(Input.SpecialKeys, {
  sym = 319,
  unicode = 0,
  name = "Menu",
  input = "KEY_menu"
})
table.insert(Input.SpecialKeys, {
  sym = 316,
  unicode = 0,
  name = "Print",
  input = "KEY_print"
})
Input.AxesMapping = {}
table.insert(Input.AxesMapping, {
  axisNumber = 0,
  name = "Axis 1",
  input = "AXIS_1"
})
table.insert(Input.AxesMapping, {
  axisNumber = 1,
  name = "Axis 2",
  input = "AXIS_2"
})
table.insert(Input.AxesMapping, {
  axisNumber = 2,
  name = "Axis 3",
  input = "AXIS_3"
})
table.insert(Input.AxesMapping, {
  axisNumber = 3,
  name = "Axis 4",
  input = "AXIS_4"
})
table.insert(Input.AxesMapping, {
  axisNumber = 4,
  name = "Axis 5",
  input = "AXIS_5"
})
table.insert(Input.AxesMapping, {
  axisNumber = 5,
  name = "Axis 6",
  input = "AXIS_6"
})
