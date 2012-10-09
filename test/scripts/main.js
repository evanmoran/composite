function main()
{

  example1($('canvas#example1')[0]);
  example2($('canvas#example2')[0]);
  example3($('canvas#example3')[0]);
  example4($('canvas#example4')[0]);
}

function example1(canvas)
{
  context = canvas.getContext('2d');
  compositor = composite(context);

  compositor.fillStyle = 'red';
  compositor.globalAlpha = 0.3;
  compositor.fillRect(30, 30, 80, 80);
  compositor.fillRect(10, 10, 80, 80);

  compositor.beginLayer();
  compositor.fillRect(120, 30, 80, 80);
  compositor.fillRect(100, 10, 80, 80);
  compositor.endLayer();
}

function example2(canvas)
{
  compositor = composite(canvas);

  compositor.fillStyle = 'red';
  compositor.shadowColor = 'black';
  compositor.shadowOffsetX = 1;
  compositor.shadowOffsetY = 1;
  compositor.shadowBlur = 10;

  compositor.fillRect(30, 30, 80, 80);
  compositor.fillRect(10, 10, 80, 80);

  compositor.beginLayer();
  compositor.fillRect(120, 30, 80, 80);
  compositor.fillRect(100, 10, 80, 80);
  compositor.endLayer();
}

function example3(canvas)
{
  compositor = composite(canvas);

  compositor.translate(20, 60);

  compositor.fillStyle = 'red';
  compositor.globalAlpha = 0.3;
  compositor.fillRect(30, 30, 80, 80);
  compositor.fillRect(10, 10, 80, 80);

  compositor.beginLayer();
  compositor.fillRect(120, 30, 80, 80);
  compositor.fillRect(100, 10, 80, 80);
  compositor.endLayer();
}

/**
 * Ensure path is not inherited when starting a new group. This should produce a stroked square, dispite the call to fill.
 */
function example4(canvas)
{
  compositor = composite(canvas);

  compositor.beginLayer();
  compositor.beginPath();
  compositor.moveTo(10, 10);
  compositor.lineTo(90, 10);
  compositor.lineTo(90, 90);
  compositor.lineTo(10, 90);
  compositor.lineTo(10, 10);
  compositor.stroke();
  compositor.endLayer();

  compositor.beginLayer();
  compositor.fill();
  compositor.endLayer();
}
