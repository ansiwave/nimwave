import paranim/opengl, paranim/glm
import paranim/gl, paranim/gl/uniforms, paranim/gl/attributes
from paranim/gl/entities import crop, color
import paratext, paratext/gl/text
from math import nil
import tables
from strutils import format
import unicode
from ./constants import nil
from illwave as iw import nil
from terminal import nil

const version = "330"

const
  monoFontRaw = staticRead("assets/3270-Regular.ttf")
  instancedTextVertexShader = staticRead("shaders/vertex.glsl").format(version)
  instancedTextFragmentShader = staticRead("shaders/fragment.glsl").format(version)

let
  monoFont* = initFont(ttf = monoFontRaw, fontHeight = 80,
                       ranges = constants.x3270Ranges,
                       bitmapWidth = 2048, bitmapHeight = 2048, charCount = constants.x3270CharCount)
  monoFontWidth* = monoFont.chars[0].xadvance

proc fgColorToVec4(ch: iw.TerminalChar, defaultColor: glm.Vec4[GLfloat]): glm.Vec4[GLFloat] =
  result =
    case ch.fg.kind:
    of iw.SimpleColor:
      if terminal.styleBright in ch.style:
        case ch.fg.simpleColor:
        of terminal.fgBlack: constants.blackColor
        of terminal.fgRed: constants.brightRedColor
        of terminal.fgGreen: constants.brightGreenColor
        of terminal.fgYellow: constants.brightYellowColor
        of terminal.fgBlue: constants.brightBlueColor
        of terminal.fgMagenta: constants.brightMagentaColor
        of terminal.fgCyan: constants.brightCyanColor
        of terminal.fgWhite: constants.whiteColor
        of terminal.fgDefault, terminal.fg8Bit: defaultColor
      else:
        case ch.fg.simpleColor:
        of terminal.fgBlack: constants.blackColor
        of terminal.fgRed: constants.redColor
        of terminal.fgGreen: constants.greenColor
        of terminal.fgYellow: constants.yellowColor
        of terminal.fgBlue: constants.blueColor
        of terminal.fgMagenta: constants.magentaColor
        of terminal.fgCyan: constants.cyanColor
        of terminal.fgWhite: constants.whiteColor
        of terminal.fgDefault, terminal.fg8Bit: defaultColor
    of iw.TrueColor:
      let (r, g, b) = iw.fromColor(ch.fg.trueColor)
      glm.vec4(r.GLFloat/255f, g.GLFloat/255f, b.GLFloat/255f, 1.GLfloat)
  if ch.cursor:
    result[3] = 0.7

proc bgColorToVec4(ch: iw.TerminalChar, defaultColor: glm.Vec4[GLfloat]): glm.Vec4[GLfloat] =
  result =
    case ch.bg.kind:
    of iw.SimpleColor:
      if terminal.styleBright in ch.style:
        case ch.bg.simpleColor:
        of terminal.bgBlack: constants.blackColor
        of terminal.bgRed: constants.brightRedColor
        of terminal.bgGreen: constants.brightGreenColor
        of terminal.bgYellow: constants.brightYellowColor
        of terminal.bgBlue: constants.brightBlueColor
        of terminal.bgMagenta: constants.brightMagentaColor
        of terminal.bgCyan: constants.brightCyanColor
        of terminal.bgWhite: constants.whiteColor
        of terminal.bgDefault, terminal.bg8Bit: defaultColor
      else:
        case ch.bg.simpleColor:
        of terminal.bgBlack: constants.blackColor
        of terminal.bgRed: constants.redColor
        of terminal.bgGreen: constants.greenColor
        of terminal.bgYellow: constants.yellowColor
        of terminal.bgBlue: constants.blueColor
        of terminal.bgMagenta: constants.magentaColor
        of terminal.bgCyan: constants.cyanColor
        of terminal.bgWhite: constants.whiteColor
        of terminal.bgDefault, terminal.bg8Bit: defaultColor
    of iw.TrueColor:
      let (r, g, b) = iw.fromColor(ch.bg.trueColor)
      glm.vec4(r.GLFloat/255f, g.GLFloat/255f, b.GLFloat/255f, 1.GLfloat)
  if ch.cursor:
    result[3] = 0.7

type
  AnsiwaveTextEntityUniforms = tuple[
    u_matrix: Uniform[Mat3x3[GLfloat]],
    u_image: Uniform[Texture[GLubyte]],
    u_char_counts: Uniform[seq[GLint]],
    u_start_line: Uniform[GLint],
    u_start_column: Uniform[GLint],
    u_font_height: Uniform[GLfloat],
    u_alpha: Uniform[GLfloat],
    u_show_blocks: Uniform[GLuint],
  ]
  AnsiwaveTextEntityAttributes = tuple[
    a_position: Attribute[GLfloat],
    a_translate_matrix: Attribute[GLfloat],
    a_scale_matrix: Attribute[GLfloat],
    a_texture_matrix: Attribute[GLfloat],
    a_color: Attribute[GLfloat],
  ]
  AnsiwaveTextEntity* = object of InstancedEntity[AnsiwaveTextEntityUniforms, AnsiwaveTextEntityAttributes]
  UncompiledAnsiwaveTextEntity = object of UncompiledEntity[AnsiwaveTextEntity, AnsiwaveTextEntityUniforms, AnsiwaveTextEntityAttributes]

proc initInstancedEntity*(entity: UncompiledTextEntity, font: PackedFont): UncompiledAnsiwaveTextEntity =
  let e = gl.copy(entity) # make a copy to prevent unexpected problems if `entity` is changed later
  result.vertexSource = instancedTextVertexShader
  result.fragmentSource = instancedTextFragmentShader
  result.uniforms.u_matrix = e.uniforms.u_matrix
  result.uniforms.u_image = e.uniforms.u_image
  result.uniforms.u_char_counts.disable = true
  result.uniforms.u_start_column.data = 0
  result.uniforms.u_font_height.data = font.height
  result.uniforms.u_alpha.data = 1.0
  result.uniforms.u_show_blocks.data = 0
  result.attributes.a_translate_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_translate_matrix.data)
  result.attributes.a_scale_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_scale_matrix.data)
  result.attributes.a_texture_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_texture_matrix.data)
  result.attributes.a_color = Attribute[GLfloat](disable: true, divisor: 1, size: 4, iter: 1)
  new(result.attributes.a_color.data)
  result.attributes.a_position = e.attributes.a_position

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      attr.data[].add(uni.data.row(r)[c])
  attr.disable = false

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    attr.data[].add(uni.data[x])
  attr.disable = false

proc addInstanceAttr[T](attr: var Attribute[T], attr2: Attribute[T]) =
  attr.data[].add(attr2.data[])
  attr.disable = false

proc addInstanceUni[T](uni: var Uniform[seq[T]], uni2: Uniform[seq[T]]) =
  uni.data.add(uni2.data)
  uni.disable = false

proc setInstanceAttr[T](attr: var Attribute[T], i: int, uni: Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      attr.data[r*3+c+i*9] = uni.data.row(r)[c]
  attr.disable = false

proc setInstanceAttr[T](attr: var Attribute[T], i: int, uni: Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    attr.data[x+i*4] = uni.data[x]
  attr.disable = false

proc getInstanceAttr[T](attr: Attribute[T], i: int, uni: var Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      uni.data[r][c] = attr.data[r*3+c+i*9]
  uni.data = uni.data.transpose()
  uni.disable = false

proc getInstanceAttr[T](attr: Attribute[T], i: int, uni: var Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    uni.data[x] = attr.data[x+i*4]
  uni.disable = false

proc cropInstanceAttr[T](attr: var Attribute[T], i: int, j: int) =
  let
    size = attr.size * attr.iter
    data = attr.data
  new(attr.data)
  attr.data[] = data[][i*size ..< j*size]
  attr.disable = false

proc cropInstanceUni[T](uni: var Uniform[seq[T]], i: int, j: int) =
  uni.data = uni.data[i ..< j]
  uni.disable = false

proc add*(instancedEntity: var UncompiledAnsiwaveTextEntity, entity: UncompiledTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.uniforms.u_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.uniforms.u_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.uniforms.u_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.uniforms.u_color)
  # instanceCount will be computed by the `compile` proc

proc add*(instancedEntity: var AnsiwaveTextEntity, entity: UncompiledTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.uniforms.u_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.uniforms.u_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.uniforms.u_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.uniforms.u_color)
  instancedEntity.instanceCount += 1

proc add*(instancedEntity: var AnsiwaveTextEntity, entity: AnsiwaveTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.attributes.a_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.attributes.a_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.attributes.a_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.attributes.a_color)
  addInstanceUni(instancedEntity.uniforms.u_char_counts, entity.uniforms.u_char_counts)
  instancedEntity.instanceCount += entity.instanceCount

proc `[]`*(instancedEntity: AnsiwaveTextEntity or UncompiledAnsiwaveTextEntity, i: int): UncompiledTextEntity =
  result.attributes.a_position = instancedEntity.attributes.a_position
  result.attributes.a_position.disable = false
  result.uniforms.u_image = instancedEntity.uniforms.u_image
  result.uniforms.u_image.disable = false
  getInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, result.uniforms.u_translate_matrix)
  getInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, result.uniforms.u_scale_matrix)
  getInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, result.uniforms.u_texture_matrix)
  getInstanceAttr(instancedEntity.attributes.a_color, i, result.uniforms.u_color)

proc `[]=`*(instancedEntity: var AnsiwaveTextEntity, i: int, entity: UncompiledTextEntity) =
  setInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, entity.uniforms.u_translate_matrix)
  setInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, entity.uniforms.u_scale_matrix)
  setInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, entity.uniforms.u_texture_matrix)
  setInstanceAttr(instancedEntity.attributes.a_color, i, entity.uniforms.u_color)

proc `[]=`*(instancedEntity: var UncompiledAnsiwaveTextEntity, i: int, entity: UncompiledTextEntity) =
  setInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, entity.uniforms.u_translate_matrix)
  setInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, entity.uniforms.u_scale_matrix)
  setInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, entity.uniforms.u_texture_matrix)
  setInstanceAttr(instancedEntity.attributes.a_color, i, entity.uniforms.u_color)

proc cropLines*(instancedEntity: var AnsiwaveTextEntity, startLine: int, endLine: int) =
  let
    # startLine and endLine could be temporarily too big if LineCount hasn't been updated yet
    startLine = min(startLine, instancedEntity.uniforms.u_char_counts.data.len)
    endLine = min(endLine, instancedEntity.uniforms.u_char_counts.data.len)
    prevLines = instancedEntity.uniforms.u_char_counts.data[0 ..< startLine]
    currLines = instancedEntity.uniforms.u_char_counts.data[startLine ..< endLine]
    i = math.sum(prevLines)
    j = i + math.sum(currLines)
  cropInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, j)
  cropInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, j)
  cropInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, j)
  cropInstanceAttr(instancedEntity.attributes.a_color, i, j)
  cropInstanceUni(instancedEntity.uniforms.u_char_counts, startLine, endLine)
  instancedEntity.instanceCount = int32(j - i)

proc cropLines*(instancedEntity: var AnsiwaveTextEntity, startLine: int) =
  cropLines(instancedEntity, startLine, instancedEntity.uniforms.u_char_counts.data.len)

const
  notFoundCharIndex = constants.codepointToGlyph[9633]
  blockCharIndex = constants.codepointToGlyph["█".toRunes[0].int32]

let blockWidth* = monoFont.chars[blockCharIndex].xadvance

proc add*(instancedEntity: var AnsiwaveTextEntity, entity: UncompiledTextEntity, font: PackedFont, fontColor: glm.Vec4[GLfloat], text: seq[iw.TerminalChar], startPos: float): float =
  let lineNum = instancedEntity.uniforms.u_char_counts.data.len - 1
  result = startPos
  var i = 0
  for tchar in text:
    let
      ch = tchar.ch
      bakedChar =
        if constants.codepointToGlyph.hasKey(ch.int32):
          font.chars[constants.codepointToGlyph[ch.int32]]
        else: # if char isn't found, use a default one
          font.chars[notFoundCharIndex]
    let
      bgColor = bgColorToVec4(tchar, fontColor)
      fgColor = fgColorToVec4(tchar, fontColor)
    if not (tchar.bg.kind == iw.SimpleColor and tchar.bg.simpleColor == terminal.bgDefault):
      var bg = entity
      bg.crop(font.chars[blockCharIndex], result, font.baseline)
      bg.color(bgColor)
      instancedEntity.add(bg)
      instancedEntity.uniforms.u_char_counts.data[lineNum] += 1
    var fg = entity
    fg.crop(bakedChar, result, font.baseline)
    fg.color(fgColor)
    instancedEntity.add(fg)
    instancedEntity.uniforms.u_char_counts.data[lineNum] += 1
    result += bakedChar.xadvance

proc addLine*(instancedEntity: var AnsiwaveTextEntity, entity: UncompiledTextEntity, font: PackedFont, fontColor: glm.Vec4[GLfloat], text: seq[iw.TerminalChar]): float =
  instancedEntity.uniforms.u_char_counts.data.add(0)
  instancedEntity.uniforms.u_char_counts.disable = false
  add(instancedEntity, entity, font, fontColor, text, 0f)

proc updateUniforms*(e: var AnsiwaveTextEntity, startLine: int, startColumn: int, showBlocks: bool) =
  e.uniforms.u_start_line.data = startLine.int32
  e.uniforms.u_start_line.disable = false
  e.uniforms.u_start_column.data = startColumn.int32
  e.uniforms.u_start_column.disable = false
  e.uniforms.u_show_blocks.data = if showBlocks: 1 else: 0
  e.uniforms.u_show_blocks.disable = false
