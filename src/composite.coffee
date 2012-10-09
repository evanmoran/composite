
# composite
# ====================================================================

contextProperties = 'fillStyle strokeStyle shadowColor shadowBlur shadowOffsetX shadowOffsetY lineCap lineJoin lineWidth miterLimit font textAlign textBaseline width height data globalAlpha globalCompositeOperation'.split ' '

contextMethods = 'createLinearGradient createPattern createRadialGradient addColorStop rect fillRect strokeRect clearRect fill stroke beginPath moveTo closePath lineTo clip quadraticCurveTo bezierCurveTo arc arcTo isPointInPath fillText strokeText measureText drawImage createImageData getImageData putImageData createEvent getContext toDataURL'.split ' '

inheritedContextProperties = 'fillStyle strokeStyle lineCap lineJoin lineWidth miterLimit font textAlign textBaseline'.split ' '

contextMatrixMethods = 'save restore scale rotate translate transform setTransform'.split ' '

# Composite class
# ---------------------------------------------------------------------
class Composite
  constructor: (contextOrCanvas) ->
    if contextOrCanvas instanceof HTMLCanvasElement
      context = contextOrCanvas.getContext '2d'
    else
      context = contextOrCanvas
    @_contexts = [context];
    @_matrices = new MatrixStack()
    @_matrices.setContextTransform @context

  beginLayer: (options = {}) ->
    context = _getContext @context.canvas.width, @context.canvas.height, @context
    @_matrices.setContextTransform context
    @_contexts.push context

  endLayer: ->
    throw 'composite: unbalanced endLayer' if @_contexts.length <= 1
    childContext = @context
    @_contexts.pop()
    # Draw childContext into @context
    @context.save()
    @context.setTransform 1,0,0,1,0,0               # reset transform
    @context.drawImage childContext.canvas, 0, 0
    @context.restore()
    _releaseContext childContext

  layer: (options, fn) ->
    if not fn
      fn = options
      options = {}
    @beginLayer(options)
    fn()
    @endLayer()

# Make `@context` a property to top of context stack
Object.defineProperty Composite.prototype, 'context',
  get: -> @_contexts[@_contexts.length-1]

# Add context methods
for m in contextMethods
  do(m) ->
    Composite.prototype[m] = ->
      @context[m].apply @context, arguments

# Add context properties
for p in contextProperties
  do(p) ->
    Object.defineProperty Composite.prototype, p,
      get: -> @context[p]
      set: (v) -> @context[p] = v

# Add context matrix methods
for m in contextMatrixMethods
  do(m) ->
    Composite.prototype[m] = ->
      @_matrices[m].apply @_matrices, arguments
      @_matrices.setContextTransform @context
      #@context[m].apply @context, arguments

_freeContexts = []
_getContext = (width, height, parentContext) ->
  if _freeContexts.length
    context = _freeContexts.pop()
    canvas = context.canvas
    if canvas.width != width or canvas.height != height
      canvas.width = width
      canvas.height = height
    context.beginPath()
    context.clearRect 0, 0, width, height
  else
    canvas = document.createElement 'canvas'
    canvas.width = width
    canvas.height = height
    context = canvas.getContext '2d'
  context.save()

  # Copy state from parentContext
  if parentContext
    for p in inheritedContextProperties
      context[p] = parentContext[p]

  context

_releaseContext = (context) ->
  context.restore()
  _freeContexts.push context


# MatrixStack class
# ---------------------------------------------------------------------
matrixMethods = 'multiply scale translate rotate projectPoint setContextTransform scale rotate translate transform setTransform'.split ' '

class MatrixStack
  constructor: (matrix = Matrix.Identity()) ->
    @_stack = [matrix]

  clone: ->
    stack = []
    for m in @_stack
      stack.push m.clone()
    s = new MatrixStack
    s._stack = stack

  save: ->
    @_stack.push @matrix.clone()

  restore: ->
    @_stack.pop()

# Add '@matrix' property to refer to top matrix
Object.defineProperty MatrixStack.prototype, 'matrix', get: -> @_stack[@_stack.length-1]

# Pass through methods of Matrix
for m in matrixMethods
  do (m) ->
    MatrixStack.prototype[m] = ->
      throw Error('FUUU') unless @ instanceof MatrixStack
      @matrix[m].apply @matrix, arguments


# Matrix class
# ---------------------------------------------------------------------
class Matrix
  constructor: (values = _identityMatrix()) ->
    @_values = values.slice 0

  clone: ->
    new Matrix @_values

  multiply: (other) ->
    @_values = (_matrixMultiply @_values, other_.values)

  scale: (sx, sy) ->
    @_values = (_matrixScale @_values, sx, sy)

  translate: (x, y) ->
    @_values = (_matrixTranslate @_values, x, y)

  rotate: (angle) ->
    @_values = (_matrixRotate @_values, angle)

  projectPoint: (x, y) ->
    _matrixProjectPoint @_values, x, y

  setTransform: () ->
    @_values = Array.prototype.slice.call arguments, 0

  transform: () ->
    values = Array.prototype.slice.call arguments, 0
    @_values = _matrixMultiply @_values, values

  setContextTransform: (context) ->
    context.setTransform.apply context, @_values

Matrix.Identity = -> new Matrix _identityMatrix()
Matrix.Rotation = (angle) -> new Matrix _rotationMatrix(angle)
Matrix.Translation = (x, y) -> new Matrix _translationMatrix(x, y)
Matrix.Scale = (sx, sy) -> new Matrix _scalingMatrix(sx, sy)

_matrixMultiply = (m1, m2) ->
  m11 = m1[0]*m2[0] + m1[2]*m2[1]
  m12 = m1[1]*m2[0] + m1[3]*m2[1]

  m21 = m1[0]*m2[2] + m1[2]*m2[3]
  m22 = m1[1]*m2[2] + m1[3]*m2[3]

  dx = m1[0]*m2[4] + m1[2]*m2[5] + m1[4]
  dy = m1[1]*m2[4] + m1[3]*m2[5] + m1[5]

  [m11, m12, m21, m22, dx, dy]

_matrixRotate = (m, angle) ->
  c = Math.cos(angle)
  s = Math.sin(angle)
  m11 = m[0]*c + m[2]*s
  m12 = m[1]*c + m[3]*s
  m21 = m[0]*-s + m[2]*c
  m22 = m[1]*-s + m[3]*c
  dx = m[4]
  dy = m[5]
  [m11, m12, m21, m22, dx, dy]

_matrixTranslate = (m1, x, y) ->
  m = m1.slice 0
  m[4] += m1[0]*x + m1[2]*y
  m[5] += m1[1]*x + m1[3]*y
  m

_matrixScale = (m1, sx, sy) ->
  m = m1.slice 0
  m[0] *= sx
  m[1] *= sx
  m[2] *= sy
  m[3] *= sy
  m

_identityMatrix = ->
  [1, 0 ,0, 1, 0, 0]

_rotationMatrix = (angle) ->
  c = Math.cos(angle)
  s = Math.sin(angle)
  [ c, s, -s, c, 0, 0 ]

_translationMatrix = (x, y) ->
  [ 1, 0, 0, 1, x, y ]

_scalingMatrix = (sx, sy) ->
  [ sx, 0, 0, sy, 0, 0 ]

_matrixProjectPoint = (m, x, y) ->
  [
    x*m[0] + y*m[2] + m[4],
    x*m[1] + y*m[3] + m[5]
  ]


# composite function
# ---------------------------------------------------------------------
composite = (context) ->
  new Composite context

# Version
# ---------------------------------------------------------------------
composite.version = '0.0.1'

# Export
# ---------------------------------------------------------------------

root = @

if typeof module != 'undefined'
  exports = module.exports = composite
else
  root['composite'] = composite


