var canvas_element,
     ctx,
     circle,
     i,
     cr,
     points;
 //setup
 canvas = document.getElementById('example_canvas_image');
 canvas.setAttribute('width','500px');
 canvas.setAttribute('height','500px');
 ctx = canvas.getContext('2d');
 cr = 2*Math.PI;
 //variables
 center_x = (canvas.width/2);
 center_y = (canvas.height/2);
 //primitives
 circle = function(cx,cy,r){
   ctx.beginPath();
   ctx.arc(cx,cy,r,0,cr,false);
   ctx.lineWidth = 0.2;
   ctx.strokeStyle = "rgba(0,0,0,0.1)";
   ctx.fillStyle = "rgba(0,0,0,0.8)";
   ctx.stroke();          
 }
 

 //Create random point array
 points = [];        
 for (i=0; i<100; i++) {
   var ccx,ccy;
   ccx = Math.random()*520;
   ccy = Math.random()*520;
   points.push({ x: ccx, y:ccy });
 }

 ctx.globalCompositeOperation = 'destination-over';  
 
 drawField = function(){
 
   ctx.clearRect(0,0,500,500); // clear canvas
 
   //Draw Points and Lines between closest ones
   for (i=0; i<points.length; i++) {
     var point, isCloseEnough, close_points;
     point = points[i];
             
     circle(point.x,point.y,3);
     ctx.fill();
     
     //Link close points
     isCloseEnough = function(element,index,array){
       var p;
       p = 80;
       return ((point.x - element.x) <= p && (point.x - element.x) >= -p && (point.y - element.y) <= p && (point.y - element.y) >= -p);
     }
     close_points = points.filter(isCloseEnough);
     for (ci=0; ci<close_points.length; ci++) {
         ctx.beginPath();
         ctx.moveTo(point.x,point.y);
         ctx.lineTo(close_points[ci].x,close_points[ci].y);
         ctx.stroke();
     }
     
     //movePoints
     point.x = point.x+(Math.random()-0.5);
     point.y = point.y+(Math.random()-0.5);
    

    
   }
 
  // setInterval(drawField,1000);                  
 
 }

 drawField();