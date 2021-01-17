/*
  Hinge mockup for 

  Aaron Ciuffo aaron. ciuffo 2 gmail com
*/

/*[Dimensions]*/
plateX=18.8;
plateY=25.6;
plateZ=1.8;
hingeDia=3.8;
hingeRad=hingeDia/2;
holeDia=3.3;
holeRad=holeDia/2;
pilotHoleDia=1.5;
pilotHoleRad=pilotHoleDia/3;
holeEX=1.6;
holeEY=3.6;

/*
plateX=15.3;
plateY=18.2;
plateZ=0.5;
hingeDia=2.3;
hingeRad=hingeDia/2;
holeDia=2.6;
holeRad=holeDia/2;
pilotHoleDia=1;
pilotHoleRad=pilotHoleDia/2;
holeEX=2;
holeEY=3.6;
*/
  
$fn=36;


module drawPlate() {
  difference() {
    union() {
      cube([plateX, plateY, plateZ], center=true);
      rotate([90, 0, 0]) translate([0, hingeRad-plateZ/2, 0])
        cylinder(h=plateY, r=hingeRad, center=true);
    }
    holes(mir=1);
    holes(mir=-1);
  }
}

module holes(mir=1, project=false) {
  
  locRad= project==true ? pilotHoleRad : holeRad; 

  translate([mir*(plateX/2-holeRad-holeEX), mir*(plateY/2-holeRad-holeEY), 0])
    cylinder(r=locRad, h=plateZ*5, center=true);
  translate([mir*(plateX/2-holeRad-holeEX), mir*(-plateY/2+holeRad+holeEY), 0])
    cylinder(r=locRad, h=plateZ*5, center=true);

}

module circles(mir=1) {
  
  locRad=pilotHoleRad;
  translate([mir*(plateX/2-holeRad-holeEX), mir*(plateY/2-holeRad-holeEY), 0])
    circle(r=locRad, center=true);
  translate([mir*(plateX/2-holeRad-holeEX), mir*(-plateY/2+holeRad+holeEY), 0])
    circle(r=locRad, center=true);
}

module hinge(project=false) {
  if (project==false) {
    drawPlate();
  } else {
//    holes(project=true);
//    holes(mir=-1, project=true);
      circles(mir=1);
      circles(mir=-1);
  }
}

hinge(project=true);
hinge(project=false);
