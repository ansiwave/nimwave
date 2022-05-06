#include <emscripten.h>

EM_JS(char*, ansiweb_get_innerhtml, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  var content = "";
  if (elem) {
    content = elem.innerHTML;
  }
  var lengthBytes = lengthBytesUTF8(content)+1;
  var stringOnWasmHeap = _malloc(lengthBytes);
  stringToUTF8(content, stringOnWasmHeap, lengthBytes);
  return stringOnWasmHeap;
});

EM_JS(void, ansiweb_set_innerhtml, (const char* selector, const char* html), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.innerHTML = UTF8ToString(html);
});

EM_JS(void, ansiweb_set_location, (const char* selector, int left, int top), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.style.left = left + "px";
  elem.style.top = top + "px";
});

EM_JS(void, ansiweb_set_size, (const char* selector, int width, int height), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.style.width = width + "px";
  elem.style.height = height + "px";
});

EM_JS(int, ansiweb_get_client_width, (), {
  return document.documentElement.clientWidth;
});

EM_JS(int, ansiweb_get_client_height, (), {
  return document.documentElement.clientHeight;
});

EM_JS(void, ansiweb_set_display, (const char* selector, const char* display), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.style.display = UTF8ToString(display);
});

EM_JS(void, ansiweb_focus, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.focus();
});

EM_JS(void, ansiweb_scroll_down, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (elem) {
    elem.scrollTop = elem.scrollHeight;
  }
});

EM_JS(int, ansiweb_get_scroll_top, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return 0;
  return elem.scrollTop;
});

EM_JS(int, ansiweb_get_cursor_line, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;

  function uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  var selection = document.getSelection();
  if (selection.rangeCount < 1) {
    return -1;
  }
  var range = selection.getRangeAt(0);
  range.collapse(true);
  var span = document.createElement('span');
  var id = uuidv4();
  span.appendChild(document.createTextNode(id));
  range.insertNode(span);

  var text = elem.innerText;
  var newLines = 0;
  var lastNewline = null;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '\n' && lastNewline != i - 1) {
      newLines += 1;
      lastNewline = i;
    } else {
      if (text.substring(i).startsWith(id)) break;
    }
  }

  span.remove();
  return newLines;
});
