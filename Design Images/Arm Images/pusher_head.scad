
// Module names are of the form poly_<inkscape-path-id>().  As a result,
// you can associate a polygon in this OpenSCAD program with the corresponding
// SVG element in the Inkscape document by looking for the XML element with
// the attribute id="inkscape-path-id".

// fudge value is used to ensure that subtracted solids are a tad taller
// in the z dimension than the polygon being subtracted from.  This helps
// keep the resulting .stl file manifold.
fudge = 0.1;

module poly_path3186(h)
{
  scale([25.4/90, -25.4/90, 1]) union()
  {
    //linear_extrude(height=h)
      polygon([[44.291250,15.938750],[44.074280,18.074021],[43.452441,20.066074],[42.469343,21.871301],[41.168594,23.446094],[39.593801,24.746843],[37.788574,25.729941],[35.796521,26.351780],[33.661250,26.568750],[-33.661250,26.568750],[-35.796521,26.351780],[-37.788574,25.729941],[-39.593801,24.746843],[-41.168594,23.446094],[-42.469343,21.871301],[-43.452441,20.066074],[-44.074280,18.074021],[-44.291250,15.938750],[-44.291250,-15.938750],[-44.074280,-18.074021],[-43.452441,-20.066074],[-42.469343,-21.871301],[-41.168594,-23.446094],[-39.593801,-24.746843],[-37.788574,-25.729941],[-35.796521,-26.351780],[-33.661250,-26.568750],[33.661250,-26.568750],[35.796521,-26.351780],[37.788574,-25.729941],[39.593801,-24.746843],[41.168594,-23.446094],[42.469343,-21.871301],[43.452441,-20.066074],[44.074280,-18.074021],[44.291250,-15.938750],[44.291250,15.938750]]);
  }
}

module poly_path3188(h)
{
  scale([25.4/90, -25.4/90, 1]) union()
  {
    //linear_extrude(height=h)
      polygon([[1.772250,9.035250],[-1.771500,9.035250],[-1.771500,-9.034750],[1.772250,-9.034750],[1.772250,9.035250]]);
  }
}

module pusher_head() {
  difference() {
    poly_path3186(4);
    poly_path3188(4);
    
  }

}

pusher_head();
