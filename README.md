composite.js
============

A compositor for canvas.

Usage
-----

    context = composite(canvas)

`context` behaves like the html `canvas.getContext('2d')`

    context = composite(canvas)

    context.globalAlpha = 0.3;            # Make everything transparent
    context.fillStyle = 'red';            # Fill with red

    context.fillRect(30, 30, 80, 80);     # Create first red rectangle
    context.fillRect(10, 10, 80, 80);     # Create second red rectangle overlapping the first

output:

![Transparency Without Layer](https://raw.github.com/evanmoran/composite/master/docs/images/transparency_without_layer.png)

What composite does is add a notion of layers:

    context = composite(canvas)

    context.globalAlpha = 0.3;
    context.fillStyle = 'red';

    context.beginLayer();                 # <--- Begin layer with composite

    context.fillRect(30, 30, 80, 80);
    context.fillRect(10, 10, 80, 80);

    context.endLayer();                   # <--- End layer with composite

output:

![Transparency With Layer](https://raw.github.com/evanmoran/composite/master/docs/images/transparency_with_layer.png)

Shadows are another good example:

    context = composite(canvas)

    context.shadowColor = 'black';
    context.shadowOffsetX = 1;
    context.shadowOffsetY = 1;
    context.shadowBlur = 10;

    context.fillRect(30, 30, 80, 80);
    context.fillRect(10, 10, 80, 80);
output:

![Shadow Without Layer](https://raw.github.com/evanmoran/composite/master/docs/images/shadow_without_layer.png)

Now with layers:

    context = composite(canvas)

    context.shadowColor = 'black';
    context.shadowOffsetX = 1;
    context.shadowOffsetY = 1;
    context.shadowBlur = 10;

    context.beginLayer();                 # <--- Begin layer with composite

    context.fillRect(30, 30, 80, 80);
    context.fillRect(10, 10, 80, 80);

    context.endLayer();                   # <--- End layer with composite

output:

![Shadow With Layer](https://raw.github.com/evanmoran/composite/master/docs/images/shadow_with_layer.png)

That's it. Hope it helps!
