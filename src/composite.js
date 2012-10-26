// Generated by CoffeeScript 1.3.3
(function() {
  var Composite, Matrix, MatrixStack, composite, contextMatrixMethods, contextMethods, contextProperties, exports, inheritedContextProperties, m, matrixMethods, p, root, _fn, _fn1, _fn2, _fn3, _freeContexts, _getContext, _i, _identityMatrix, _j, _k, _l, _len, _len1, _len2, _len3, _matrixInvert, _matrixMultiply, _matrixProjectPoint, _matrixRotate, _matrixScale, _matrixTranslate, _releaseContext, _rotationMatrix, _scalingMatrix, _translationMatrix;

  contextProperties = 'canvas fillStyle strokeStyle shadowColor shadowBlur shadowOffsetX shadowOffsetY lineCap lineJoin lineWidth miterLimit font textAlign textBaseline width height data globalAlpha globalCompositeOperation'.split(' ');

  contextMethods = 'createLinearGradient createPattern createRadialGradient addColorStop rect fillRect strokeRect clearRect fill stroke beginPath moveTo closePath lineTo clip quadraticCurveTo bezierCurveTo arc arcTo isPointInPath fillText strokeText measureText drawImage createImageData getImageData putImageData createEvent getContext toDataURL'.split(' ');

  inheritedContextProperties = 'fillStyle strokeStyle lineCap lineJoin lineWidth miterLimit font textAlign textBaseline'.split(' ');

  contextMatrixMethods = 'save restore scale rotate translate transform setTransform'.split(' ');

  Composite = (function() {

    function Composite(contextOrCanvas) {
      var context;
      if (contextOrCanvas instanceof HTMLCanvasElement) {
        context = contextOrCanvas.getContext('2d');
      } else {
        context = contextOrCanvas;
      }
      this._contexts = [context];
      this._matrices = new MatrixStack();
      this._matrices.setContextTransform(this.context);
      this._globals = [];
    }

    Composite.prototype.beginLayer = function(options) {
      var alpha, compositeOperation, context, force, parentContext;
      if (options == null) {
        options = {};
      }
      parentContext = this.context;
      compositeOperation = options.compositeOperation != null ? options.compositeOperation : parentContext.globalCompositeOperation;
      alpha = options.alpha != null ? options.alpha : parentContext.globalAlpha;
      force = options.force;
      this.saveGlobals();
      this._matrices.save();
      if ((compositeOperation !== 'source-over') || (alpha !== 1) || force) {
        if (alpha !== null) {
          parentContext.globalAlpha = alpha;
        }
        if (compositeOperation !== null) {
          parentContext.globalCompositeOperation = compositeOperation;
        }
        context = _getContext(parentContext.canvas.width, parentContext.canvas.height, parentContext);
        this._matrices.setContextTransform(context);
      } else {
        context = parentContext;
      }
      return this._contexts.push(context);
    };

    Composite.prototype.endLayer = function() {
      var childContext, parentContext;
      if (this._contexts.length <= 1) {
        throw 'composite: unbalanced endLayer';
      }
      childContext = this.context;
      this._contexts.pop();
      parentContext = this.context;
      if (parentContext !== childContext) {
        this._drawContext(childContext, parentContext);
        _releaseContext(childContext);
      }
      this.restoreGlobals();
      return this._matrices.restore();
    };

    Composite.prototype._drawContext = function(childContext, parentContext, x, y) {
      if (parentContext == null) {
        parentContext = this.context;
      }
      if (x == null) {
        x = 0;
      }
      if (y == null) {
        y = 0;
      }
      parentContext.save();
      parentContext.setTransform(1, 0, 0, 1, 0, 0);
      parentContext.drawImage(childContext.canvas, x, y);
      return parentContext.restore();
    };

    Composite.prototype.createCacheableLayer = function() {
      var childContext, parentContext;
      parentContext = this.context;
      childContext = _getContext(parentContext.canvas.width, parentContext.canvas.height, parentContext);
      return composite(childContext);
    };

    Composite.prototype.drawCacheableLayer = function(ctx, x, y) {
      if (x == null) {
        x = 0;
      }
      if (y == null) {
        y = 0;
      }
      if (!(ctx instanceof Composite) || ctx._contexts.length === 1) {
        this._drawContext(ctx.context, this.context, x, y);
      }
      if (ctx._contexts.length < 1) {
        throw new Error("composite: can't draw released cacheable layer.");
      } else if (ctx._contexts.length > 1) {
        throw new Error("composite: drawing incomplete cacheable layer.");
      }
    };

    Composite.prototype.releaseCacheableLayer = function(ctx) {
      var c, _i, _len, _ref;
      if (ctx instanceof Composite) {
        _ref = ctx._contexts;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          c = _ref[_i];
          _releaseContext(c);
        }
        return ctx._contexts = [];
      } else {
        throw new Error("composite: not a cacheable layer: " + ctx + ".");
      }
    };

    Composite.prototype.layer = function(options, fn) {
      if (!fn) {
        fn = options;
        options = {};
      }
      this.beginLayer(options);
      fn();
      return this.endLayer();
    };

    Composite.prototype.saveGlobals = function() {
      return this._globals.push({
        alpha: this.context.globalAlpha,
        compositeOperation: this.context.globalCompositeOperation
      });
    };

    Composite.prototype.restoreGlobals = function() {
      var globalRecord;
      if (!this._globals.length) {
        throw new Error('composite: restoreGlobals called without saveGlobals');
      }
      globalRecord = this._globals.pop();
      this.context.globalAlpha = globalRecord.alpha;
      return this.context.globalCompositeOperation = globalRecord.compositeOperation;
    };

    return Composite;

  })();

  Object.defineProperty(Composite.prototype, 'context', {
    get: function() {
      return this._contexts[this._contexts.length - 1];
    }
  });

  Object.defineProperty(Composite.prototype, 'matrix', {
    get: function() {
      return this._matrices.top.clone();
    },
    set: function(m) {
      this._matrices.top.set(m);
      return m.setContextTransform(this.context);
    }
  });

  Object.defineProperty(Composite.prototype, 'getTransform', {
    get: function() {
      return this.matrix._values.slice(0);
    }
  });

  _fn = function(m) {
    return Composite.prototype[m] = function() {
      return this.context[m].apply(this.context, arguments);
    };
  };
  for (_i = 0, _len = contextMethods.length; _i < _len; _i++) {
    m = contextMethods[_i];
    _fn(m);
  }

  _fn1 = function(p) {
    return Object.defineProperty(Composite.prototype, p, {
      get: function() {
        return this.context[p];
      },
      set: function(v) {
        return this.context[p] = v;
      }
    });
  };
  for (_j = 0, _len1 = contextProperties.length; _j < _len1; _j++) {
    p = contextProperties[_j];
    _fn1(p);
  }

  _fn2 = function(m) {
    return Composite.prototype[m] = function() {
      this._matrices[m].apply(this._matrices, arguments);
      return this._matrices.setContextTransform(this.context);
    };
  };
  for (_k = 0, _len2 = contextMatrixMethods.length; _k < _len2; _k++) {
    m = contextMatrixMethods[_k];
    _fn2(m);
  }

  _freeContexts = [];

  _getContext = function(width, height, parentContext) {
    var canvas, context, _l, _len3;
    if (_freeContexts.length) {
      context = _freeContexts.pop();
      canvas = context.canvas;
      if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
      }
      context.beginPath();
      context.clearRect(0, 0, width, height);
    } else {
      canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      context = canvas.getContext('2d');
    }
    context.save();
    context.globalAlpha = 1;
    context.globalCompositeOperation = 'source-over';
    if (parentContext) {
      for (_l = 0, _len3 = inheritedContextProperties.length; _l < _len3; _l++) {
        p = inheritedContextProperties[_l];
        context[p] = parentContext[p];
      }
    }
    return context;
  };

  _releaseContext = function(context) {
    context.restore();
    return _freeContexts.push(context);
  };

  matrixMethods = 'multiply scale translate rotate projectPoint setContextTransform scale rotate translate transform setTransform'.split(' ');

  MatrixStack = (function() {

    function MatrixStack(matrix) {
      if (matrix == null) {
        matrix = Matrix.Identity();
      }
      this._stack = [matrix];
    }

    MatrixStack.prototype.clone = function() {
      var s, stack, _l, _len3, _ref;
      stack = [];
      _ref = this._stack;
      for (_l = 0, _len3 = _ref.length; _l < _len3; _l++) {
        m = _ref[_l];
        stack.push(m.clone());
      }
      s = new MatrixStack;
      return s._stack = stack;
    };

    MatrixStack.prototype.save = function() {
      return this._stack.push(this.top.clone());
    };

    MatrixStack.prototype.restore = function() {
      return this._stack.pop();
    };

    return MatrixStack;

  })();

  Object.defineProperty(MatrixStack.prototype, 'top', {
    get: function() {
      return this._stack[this._stack.length - 1];
    }
  });

  _fn3 = function(m) {
    return MatrixStack.prototype[m] = function() {
      return this.top[m].apply(this.top, arguments);
    };
  };
  for (_l = 0, _len3 = matrixMethods.length; _l < _len3; _l++) {
    m = matrixMethods[_l];
    _fn3(m);
  }

  Matrix = (function() {

    function Matrix(values) {
      if (values == null) {
        values = _identityMatrix();
      }
      this._values = values.slice(0);
    }

    Matrix.prototype.clone = function() {
      return new Matrix(this._values);
    };

    Matrix.prototype.set = function(other) {
      return this._values = other._values.slice(0);
    };

    Matrix.prototype.multiply = function(other) {
      return this._values = _matrixMultiply(this._values, other_.values);
    };

    Matrix.prototype.scale = function(sx, sy) {
      return this._values = _matrixScale(this._values, sx, sy);
    };

    Matrix.prototype.translate = function(x, y) {
      return this._values = _matrixTranslate(this._values, x, y);
    };

    Matrix.prototype.rotate = function(angle) {
      return this._values = _matrixRotate(this._values, angle);
    };

    Matrix.prototype.projectPoint = function(x, y) {
      return _matrixProjectPoint(this._values, x, y);
    };

    Matrix.prototype.setTransform = function() {
      return this._values = Array.prototype.slice.call(arguments, 0);
    };

    Matrix.prototype.transform = function() {
      var values;
      values = Array.prototype.slice.call(arguments, 0);
      return this._values = _matrixMultiply(this._values, values);
    };

    Matrix.prototype.inverse = function() {
      return new Matrix(_matrixInvert(this._values));
    };

    Matrix.prototype.setContextTransform = function(context) {
      return context.setTransform.apply(context, this._values);
    };

    return Matrix;

  })();

  Matrix.Identity = function() {
    return new Matrix(_identityMatrix());
  };

  Matrix.Rotation = function(angle) {
    return new Matrix(_rotationMatrix(angle));
  };

  Matrix.Translation = function(x, y) {
    return new Matrix(_translationMatrix(x, y));
  };

  Matrix.Scale = function(sx, sy) {
    return new Matrix(_scalingMatrix(sx, sy));
  };

  _matrixMultiply = function(m1, m2) {
    var dx, dy, m11, m12, m21, m22;
    m11 = m1[0] * m2[0] + m1[2] * m2[1];
    m12 = m1[1] * m2[0] + m1[3] * m2[1];
    m21 = m1[0] * m2[2] + m1[2] * m2[3];
    m22 = m1[1] * m2[2] + m1[3] * m2[3];
    dx = m1[0] * m2[4] + m1[2] * m2[5] + m1[4];
    dy = m1[1] * m2[4] + m1[3] * m2[5] + m1[5];
    return [m11, m12, m21, m22, dx, dy];
  };

  _matrixRotate = function(m, angle) {
    var c, dx, dy, m11, m12, m21, m22, s;
    c = Math.cos(angle);
    s = Math.sin(angle);
    m11 = m[0] * c + m[2] * s;
    m12 = m[1] * c + m[3] * s;
    m21 = m[0] * -s + m[2] * c;
    m22 = m[1] * -s + m[3] * c;
    dx = m[4];
    dy = m[5];
    return [m11, m12, m21, m22, dx, dy];
  };

  _matrixTranslate = function(m1, x, y) {
    m = m1.slice(0);
    m[4] += m1[0] * x + m1[2] * y;
    m[5] += m1[1] * x + m1[3] * y;
    return m;
  };

  _matrixScale = function(m1, sx, sy) {
    m = m1.slice(0);
    m[0] *= sx;
    m[1] *= sx;
    m[2] *= sy;
    m[3] *= sy;
    return m;
  };

  _identityMatrix = function() {
    return [1, 0, 0, 1, 0, 0];
  };

  _rotationMatrix = function(angle) {
    var c, s;
    c = Math.cos(angle);
    s = Math.sin(angle);
    return [c, s, -s, c, 0, 0];
  };

  _translationMatrix = function(x, y) {
    return [1, 0, 0, 1, x, y];
  };

  _scalingMatrix = function(sx, sy) {
    return [sx, 0, 0, sy, 0, 0];
  };

  _matrixProjectPoint = function(m, x, y) {
    return [x * m[0] + y * m[2] + m[4], x * m[1] + y * m[3] + m[5]];
  };

  _matrixInvert = function(m) {
    var d;
    d = 1 / (m[0] * m[3] - m[1] * m[2]);
    return [m[3] * d, -m[1] * d, -m[2] * d, m[0] * d, d * (m[2] * m[5] - m[3] * m[4]), d * (m[1] * m[4] - m[0] * m[5])];
  };

  composite = function(context) {
    return new Composite(context);
  };

  composite.version = '0.0.3';

  root = this;

  if (typeof module !== 'undefined') {
    exports = module.exports = composite;
  } else {
    root['composite'] = composite;
  }

}).call(this);
