import paranim/opengl, paranim/glm
import paranim/gl, paranim/gl/uniforms, paranim/gl/attributes
from paranim/gl/entities import crop, color
import paratext, paratext/gl/text
from math import nil
import tables
from strutils import format
import unicode
from ./colors import nil
from illwave as iw import nil
from terminal import nil

const
  version = "330"
  instancedTextVertexShader = staticRead("shaders/vertex.glsl").format(version)
  instancedTextFragmentShader = staticRead("shaders/fragment.glsl").format(version)
  charRanges* = [
    (32'i32, 331'i32),
    (333'i32, 340'i32),
    (342'i32, 383'i32),
    (398'i32, 398'i32),
    (402'i32, 402'i32),
    (416'i32, 417'i32),
    (431'i32, 432'i32),
    (501'i32, 501'i32),
    (506'i32, 511'i32),
    (583'i32, 583'i32),
    (699'i32, 700'i32),
    (706'i32, 708'i32),
    (710'i32, 721'i32),
    (728'i32, 733'i32),
    (736'i32, 740'i32),
    (748'i32, 748'i32),
    (750'i32, 750'i32),
    (768'i32, 884'i32),
    (886'i32, 887'i32),
    (891'i32, 893'i32),
    (895'i32, 895'i32),
    (900'i32, 906'i32),
    (908'i32, 908'i32),
    (910'i32, 929'i32),
    (931'i32, 990'i32),
    (1015'i32, 1103'i32),
    (1105'i32, 1119'i32),
    (1162'i32, 1236'i32),
    (1238'i32, 1295'i32),
    (2305'i32, 2305'i32),
    (5760'i32, 5788'i32),
    (7682'i32, 7683'i32),
    (7690'i32, 7691'i32),
    (7710'i32, 7711'i32),
    (7729'i32, 7729'i32),
    (7743'i32, 7745'i32),
    (7748'i32, 7749'i32),
    (7764'i32, 7769'i32),
    (7776'i32, 7777'i32),
    (7786'i32, 7787'i32),
    (7808'i32, 7813'i32),
    (7868'i32, 7869'i32),
    (7922'i32, 7923'i32),
    (8211'i32, 8213'i32),
    (8215'i32, 8222'i32),
    (8224'i32, 8226'i32),
    (8230'i32, 8230'i32),
    (8240'i32, 8240'i32),
    (8242'i32, 8243'i32),
    (8249'i32, 8252'i32),
    (8254'i32, 8255'i32),
    (8260'i32, 8260'i32),
    (8267'i32, 8267'i32),
    (8270'i32, 8270'i32),
    (8273'i32, 8273'i32),
    (8308'i32, 8308'i32),
    (8316'i32, 8316'i32),
    (8319'i32, 8319'i32),
    (8355'i32, 8356'i32),
    (8359'i32, 8359'i32),
    (8362'i32, 8362'i32),
    (8364'i32, 8364'i32),
    (8411'i32, 8412'i32),
    (8453'i32, 8454'i32),
    (8467'i32, 8467'i32),
    (8470'i32, 8471'i32),
    (8482'i32, 8482'i32),
    (8486'i32, 8487'i32),
    (8494'i32, 8494'i32),
    (8523'i32, 8523'i32),
    (8528'i32, 8544'i32),
    (8548'i32, 8548'i32),
    (8553'i32, 8553'i32),
    (8556'i32, 8560'i32),
    (8564'i32, 8564'i32),
    (8569'i32, 8569'i32),
    (8572'i32, 8575'i32),
    (8585'i32, 8587'i32),
    (8592'i32, 8603'i32),
    (8606'i32, 8609'i32),
    (8616'i32, 8618'i32),
    (8623'i32, 8623'i32),
    (8656'i32, 8656'i32),
    (8658'i32, 8658'i32),
    (8672'i32, 8681'i32),
    (8693'i32, 8693'i32),
    (8704'i32, 8723'i32),
    (8725'i32, 8725'i32),
    (8727'i32, 8735'i32),
    (8743'i32, 8747'i32),
    (8766'i32, 8766'i32),
    (8776'i32, 8776'i32),
    (8781'i32, 8781'i32),
    (8800'i32, 8802'i32),
    (8804'i32, 8805'i32),
    (8810'i32, 8811'i32),
    (8834'i32, 8835'i32),
    (8838'i32, 8839'i32),
    (8847'i32, 8858'i32),
    (8861'i32, 8861'i32),
    (8866'i32, 8869'i32),
    (8888'i32, 8888'i32),
    (8900'i32, 8902'i32),
    (8910'i32, 8910'i32),
    (8942'i32, 8942'i32),
    (8962'i32, 8962'i32),
    (8968'i32, 8971'i32),
    (8976'i32, 8976'i32),
    (8984'i32, 8986'i32),
    (8988'i32, 8993'i32),
    (8996'i32, 8999'i32),
    (9003'i32, 9003'i32),
    (9014'i32, 9082'i32),
    (9095'i32, 9099'i32),
    (9109'i32, 9109'i32),
    (9146'i32, 9149'i32),
    (9166'i32, 9167'i32),
    (9192'i32, 9192'i32),
    (9211'i32, 9214'i32),
    (9216'i32, 9250'i32),
    (9252'i32, 9252'i32),
    (9472'i32, 9472'i32),
    (9474'i32, 9474'i32),
    (9484'i32, 9484'i32),
    (9488'i32, 9488'i32),
    (9492'i32, 9492'i32),
    (9496'i32, 9496'i32),
    (9500'i32, 9500'i32),
    (9508'i32, 9508'i32),
    (9516'i32, 9516'i32),
    (9524'i32, 9524'i32),
    (9532'i32, 9532'i32),
    (9552'i32, 9584'i32),
    (9588'i32, 9591'i32),
    (9600'i32, 9633'i32),
    (9642'i32, 9644'i32),
    (9646'i32, 9646'i32),
    (9650'i32, 9652'i32),
    (9654'i32, 9654'i32),
    (9658'i32, 9658'i32),
    (9660'i32, 9662'i32),
    (9668'i32, 9668'i32),
    (9670'i32, 9670'i32),
    (9674'i32, 9675'i32),
    (9679'i32, 9679'i32),
    (9688'i32, 9689'i32),
    (9698'i32, 9702'i32),
    (9716'i32, 9719'i32),
    (9724'i32, 9724'i32),
    (9733'i32, 9733'i32),
    (9774'i32, 9775'i32),
    (9785'i32, 9788'i32),
    (9792'i32, 9794'i32),
    (9824'i32, 9831'i32),
    (9834'i32, 9835'i32),
    (9863'i32, 9863'i32),
    (9873'i32, 9873'i32),
    (9875'i32, 9875'i32),
    (9998'i32, 9998'i32),
    (10003'i32, 10008'i32),
    (10010'i32, 10010'i32),
    (10033'i32, 10033'i32),
    (10044'i32, 10044'i32),
    (10060'i32, 10060'i32),
    (10067'i32, 10067'i32),
    (10094'i32, 10095'i32),
    (10140'i32, 10140'i32),
    (10149'i32, 10150'i32),
    (10204'i32, 10204'i32),
    (10216'i32, 10219'i32),
    (10226'i32, 10227'i32),
    (10548'i32, 10551'i32),
    (10570'i32, 10571'i32),
    (10629'i32, 10630'i32),
    (10747'i32, 10747'i32),
    (11014'i32, 11015'i32),
    (11096'i32, 11096'i32),
    (11104'i32, 11108'i32),
    (11136'i32, 11139'i32),
    (11218'i32, 11218'i32),
    (11816'i32, 11817'i32),
    (12557'i32, 12557'i32),
    (43882'i32, 43883'i32),
    (57504'i32, 57506'i32),
    (57520'i32, 57523'i32),
    (57595'i32, 57598'i32),
    (57707'i32, 57714'i32),
    (61696'i32, 61696'i32),
    (64257'i32, 64258'i32),
    (65280'i32, 65381'i32),
    (65504'i32, 65518'i32),
    (65532'i32, 65534'i32),
  ]
  codepointToGlyph* = block:
    var
      t: Table[int32, int32]
      glyphIndex = 0'i32
    for (first, last) in charRanges:
      for cp in first..last:
        t[cp] = glyphIndex
        glyphIndex += 1
    t

  # dark colors
  blackColor* = glm.vec4(0f, 0f, 0f, 1f)
  redColor* = glm.vec4(1f, 0f, 0f, 1f)
  greenColor* = glm.vec4(0f, 128f/255f, 0f, 1f)
  yellowColor* = glm.vec4(1f, 1f, 0f, 1f)
  blueColor* = glm.vec4(0f, 0f, 1f, 1f)
  magentaColor* = glm.vec4(1f, 0f, 1f, 1f)
  cyanColor* = glm.vec4(0f, 1f, 1f, 1f)
  whiteColor* = glm.vec4(1f, 1f, 1f, 1f)

  # bright colors
  brightRedColor* = glm.vec4(238f/255f, 119f/255f, 109f/255f, 1f)
  brightGreenColor* = glm.vec4(141f/255f, 245f/255f, 123f/255f, 1f)
  brightYellowColor* = glm.vec4(255f/255f, 250f/255f, 127f/255f, 1f)
  brightBlueColor* = glm.vec4(103f/255f, 118f/255f, 246f/255f, 1f)
  brightMagentaColor* = glm.vec4(238f/255f, 131f/255f, 248f/255f, 1f)
  brightCyanColor* = glm.vec4(141f/255f, 250f/255f, 253f/255f, 1f)

proc fgColorToVec4(ch: iw.TerminalChar, defaultColor: glm.Vec4[GLfloat]): glm.Vec4[GLFloat] =
  result =
    case ch.fg.kind:
    of iw.SimpleColor:
      if terminal.styleBright in ch.style:
        case ch.fg.simpleColor:
        of terminal.fgBlack: colors.blackColor
        of terminal.fgRed: colors.brightRedColor
        of terminal.fgGreen: colors.brightGreenColor
        of terminal.fgYellow: colors.brightYellowColor
        of terminal.fgBlue: colors.brightBlueColor
        of terminal.fgMagenta: colors.brightMagentaColor
        of terminal.fgCyan: colors.brightCyanColor
        of terminal.fgWhite: colors.whiteColor
        of terminal.fgDefault, terminal.fg8Bit: defaultColor
      else:
        case ch.fg.simpleColor:
        of terminal.fgBlack: colors.blackColor
        of terminal.fgRed: colors.redColor
        of terminal.fgGreen: colors.greenColor
        of terminal.fgYellow: colors.yellowColor
        of terminal.fgBlue: colors.blueColor
        of terminal.fgMagenta: colors.magentaColor
        of terminal.fgCyan: colors.cyanColor
        of terminal.fgWhite: colors.whiteColor
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
        of terminal.bgBlack: colors.blackColor
        of terminal.bgRed: colors.brightRedColor
        of terminal.bgGreen: colors.brightGreenColor
        of terminal.bgYellow: colors.brightYellowColor
        of terminal.bgBlue: colors.brightBlueColor
        of terminal.bgMagenta: colors.brightMagentaColor
        of terminal.bgCyan: colors.brightCyanColor
        of terminal.bgWhite: colors.whiteColor
        of terminal.bgDefault, terminal.bg8Bit: defaultColor
      else:
        case ch.bg.simpleColor:
        of terminal.bgBlack: colors.blackColor
        of terminal.bgRed: colors.redColor
        of terminal.bgGreen: colors.greenColor
        of terminal.bgYellow: colors.yellowColor
        of terminal.bgBlue: colors.blueColor
        of terminal.bgMagenta: colors.magentaColor
        of terminal.bgCyan: colors.cyanColor
        of terminal.bgWhite: colors.whiteColor
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

proc add*(instancedEntity: var AnsiwaveTextEntity, entity: UncompiledTextEntity, font: PackedFont, codepointToGlyph: Table[int32, int32], fontColor: glm.Vec4[GLfloat], text: seq[iw.TerminalChar], startPos: float): float =
  let lineNum = instancedEntity.uniforms.u_char_counts.data.len - 1
  result = startPos
  var i = 0
  for tchar in text:
    let
      ch = tchar.ch
      bakedChar =
        if codepointToGlyph.hasKey(ch.int32):
          font.chars[codepointToGlyph[ch.int32]]
        else: # if char isn't found, use a default one
          font.chars[codepointToGlyph[9633]]
    let
      bgColor = bgColorToVec4(tchar, fontColor)
      fgColor = fgColorToVec4(tchar, fontColor)
    if not (tchar.bg.kind == iw.SimpleColor and tchar.bg.simpleColor == terminal.bgDefault):
      let blockCharIndex = codepointToGlyph["█".toRunes[0].int32]
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

proc addLine*(instancedEntity: var AnsiwaveTextEntity, entity: UncompiledTextEntity, font: PackedFont, codepointToGlyph: Table[int32, int32], fontColor: glm.Vec4[GLfloat], text: seq[iw.TerminalChar]): float =
  instancedEntity.uniforms.u_char_counts.data.add(0)
  instancedEntity.uniforms.u_char_counts.disable = false
  add(instancedEntity, entity, font, codepointToGlyph, fontColor, text, 0f)

proc updateUniforms*(e: var AnsiwaveTextEntity, startLine: int, startColumn: int, showBlocks: bool) =
  e.uniforms.u_start_line.data = startLine.int32
  e.uniforms.u_start_line.disable = false
  e.uniforms.u_start_column.data = startColumn.int32
  e.uniforms.u_start_column.disable = false
  e.uniforms.u_show_blocks.data = if showBlocks: 1 else: 0
  e.uniforms.u_show_blocks.disable = false
