
# composite
# ====================================================================

contextProperties = 'canvas fillStyle strokeStyle shadowColor shadowBlur shadowOffsetX shadowOffsetY lineCap lineJoin lineWidth miterLimit font textAlign textBaseline width height data globalAlpha globalCompositeOperation'.split ' '

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
    @_globals = []

  beginLayer: (options = {}) ->
    parentContext = @context
    compositeOperation = if options.compositeOperation? then options.compositeOperation else parentContext.globalCompositeOperation
    alpha = if options.alpha? then options.alpha else parentContext.globalAlpha
    force = options.force

    @saveGlobals()
    @_matrices.save()
    if (compositeOperation != 'source-over') or (alpha != 1) or (force)
      if alpha != null
        parentContext.globalAlpha = alpha
      if compositeOperation != null
        parentContext.globalCompositeOperation = compositeOperation
      context = _getContext parentContext.canvas.width, parentContext.canvas.height, parentContext
      @_matrices.setContextTransform context
    else
      context = parentContext
    @_contexts.push context

  endLayer: ->
    throw 'composite: unbalanced endLayer' if @_contexts.length <= 1
    childContext = @context
    @_contexts.pop()
    parentContext = @context
    # Draw childContext into @context
    if parentContext != childContext
      @_drawContext(childContext, parentContext)
      _releaseContext childContext
    @restoreGlobals()
    @_matrices.restore()

  _drawContext: (childContext, parentContext = @context, x = 0, y = 0) ->
    parentContext.save()
    parentContext.setTransform 1,0,0,1,0,0               # reset transform
    parentContext.drawImage childContext.canvas, x, y
    parentContext.restore()

  createCacheableLayer: ->
    parentContext = @context
    childContext = _getContext parentContext.canvas.width, parentContext.canvas.height, parentContext
    composite childContext

  drawCacheableLayer: (ctx, x = 0, y = 0) ->
    if !(ctx instanceof Composite) or ctx._contexts.length == 1
      @_drawContext ctx.context, @context, x, y
    if ctx._contexts.length < 1
      throw new Error "composite: can't draw released cacheable layer."
    else if ctx._contexts.length > 1
      throw new Error "composite: drawing incomplete cacheable layer."

  releaseCacheableLayer: (ctx) ->
    if ctx instanceof Composite
      for c in ctx._contexts
        _releaseContext c
      ctx._contexts = []
    else
      throw new Error "composite: not a cacheable layer: #{ctx}."

  layer: (options, fn) ->
    if not fn
      fn = options
      options = {}
    @beginLayer(options)
    fn()
    @endLayer()

  saveGlobals: ->
    @_globals.push alpha: @context.globalAlpha, compositeOperation: @context.globalCompositeOperation

  restoreGlobals: ->
    throw (new Error 'composite: restoreGlobals called without saveGlobals') unless @_globals.length
    globalRecord = @_globals.pop()
    @context.globalAlpha = globalRecord.alpha
    @context.globalCompositeOperation = globalRecord.compositeOperation

Object.defineProperty Composite.prototype, 'context',
  get: -> @_contexts[@_contexts.length-1]

Object.defineProperty Composite.prototype, 'matrix',
  get: -> @_matrices.top.clone()
  set: (m) ->
    @_matrices.top.set m
    m.setContextTransform @context

Object.defineProperty Composite.prototype, 'getTransform',
  get: -> @matrix._values.slice 0

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

  # Start with full opacity and normal composition
  context.globalAlpha = 1
  context.globalCompositeOperation = 'source-over'

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
    @_stack.push @top.clone()

  restore: ->
    @_stack.pop()

Object.defineProperty MatrixStack.prototype, 'top', get: -> @_stack[@_stack.length-1]

# Pass through methods of Matrix
for m in matrixMethods
  do (m) ->
    MatrixStack.prototype[m] = ->
      @top[m].apply @top, arguments

# Matrix class
# ---------------------------------------------------------------------
class Matrix
  constructor: (values = _identityMatrix()) ->
    @_values = values.slice 0

  clone: ->
    new Matrix @_values

  set: (other) ->
    @_values = other._values.slice 0

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

  inverse: () ->
    new Matrix (_matrixInvert @_values)

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

_matrixInvert = (m) ->
    d = 1 / (m[0]*m[3] - m[1]*m[2])
    [
      m[3]*d, -m[1]*d,
      -m[2]*d, m[0]*d,
      d*(m[2]*m[5] - m[3]*m[4]), d*(m[1]*m[4] - m[0]*m[5])
    ]

# composite function
# ---------------------------------------------------------------------
composite = (context) ->
  new Composite context

# Version
# ---------------------------------------------------------------------
composite.version = '0.0.4'

# Export
# ---------------------------------------------------------------------

root = @

if typeof module != 'undefined'
  exports = module.exports = composite
else
  root['composite'] = composite


