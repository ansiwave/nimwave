#include <emscripten.h>

EM_JS(char*, nimwave_get_innerhtml, (const char* selector), {
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

EM_JS(void, nimwave_set_innerhtml, (const char* selector, const char* html), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.innerHTML = UTF8ToString(html);
});

EM_JS(void, nimwave_set_position, (const char* selector, int left, int top), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.style.left = left + "px";
  elem.style.top = top + "px";
});

EM_JS(void, nimwave_set_size, (const char* selector, int width, int height), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.style.width = width + "px";
  elem.style.height = height + "px";
});

EM_JS(int, nimwave_get_client_width, (), {
  return document.documentElement.clientWidth;
});

EM_JS(int, nimwave_get_client_height, (), {
  return document.documentElement.clientHeight;
});

EM_JS(void, nimwave_set_display, (const char* selector, const char* display), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.style.display = UTF8ToString(display);
});

EM_JS(void, nimwave_set_style, (const char* selector, const char* style), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.style.cssText = UTF8ToString(style);
});

EM_JS(void, nimwave_focus, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return;
  elem.focus();
});

EM_JS(void, nimwave_scroll_down, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (elem) {
    elem.scrollTop = elem.scrollHeight;
  }
});

EM_JS(int, nimwave_get_scroll_top, (const char* selector), {
  var elem = document.querySelector(UTF8ToString(selector));
  if (!elem) return 0;
  return elem.scrollTop;
});

EM_JS(void, nimwave_open_new_tab, (const char* url), {
  window.open(UTF8ToString(url), "_blank");
});

EM_JS(char*, nimwave_get_hash, (), {
  var hash = window.location.hash.slice(1);
  var lengthBytes = lengthBytesUTF8(hash)+1;
  var stringOnWasmHeap = _malloc(lengthBytes);
  stringToUTF8(hash, stringOnWasmHeap, lengthBytes);
  return stringOnWasmHeap;
});

EM_JS(void, nimwave_set_hash, (const char* hash), {
  window.location.hash = UTF8ToString(hash);
});

EM_JS(void, nimwave_update_grid, (const char* selector, const char* actions_json), {
  var contentSel = UTF8ToString(selector);
  var actions = JSON.parse(UTF8ToString(actions_json));
  var content = document.querySelector(contentSel);
  if (!content) return;
  for (var i in actions)
  {
    var action = actions[i];
    switch (action["kind"])
    {
      case "Insert":
        var sel = contentSel + " .row" + action["y"];
        var row = document.querySelector(sel);
        if (!row) {
          content.insertAdjacentHTML("beforeend", "<div class='row" + action["y"] + "'></div>");
        }
        row = document.querySelector(sel);
        row.insertAdjacentHTML("beforeend", action["html"]);
        break;
      case "Update":
        var sel = contentSel + " .row" + action["y"] + " .col" + action["x"];
        var block = document.querySelector(sel);
        block.insertAdjacentHTML("afterend", action["html"]);
        block.remove();
        break;
      case "Remove":
        var sel = contentSel + " .row" + action["y"] + " .col" + action["x"];
        var block = document.querySelector(sel);
        block.remove();
        break;
    }
  }
});
