class Boid {
  Node node;
  int grabsMouseColor;
  int avatarColor;
  // fields
  Vector position, velocity, acceleration, alignment, cohesion, separation; // position, velocity, and acceleration in
  // a vector datatype
  float neighborhoodRadius; // radius in which it looks for fellow boids
  float maxSpeed = 4; // maximum magnitude for the velocity vector
  float maxSteerForce = .1f; // maximum magnitude of the steering vector
  float sc = 3; // scale factor for the render of the boid
  float flap = 0;
  float t = 0;
  // Load Data
  LoadFile load;
  float[][] vertex;
  int[][] faces;
  // PShape for retained mode
  PShape[] shapeFV;
  PShape[] shapeVV;
  HashMap graph;
  HashMap colorVertex;

  Boid(Vector inPos) {
    grabsMouseColor = color(0, 0, 255);
    avatarColor = color(255, 255, 0);
    position = new Vector();
    position.set(inPos);
    // load vertex and faces
    load = new LoadFile( );
    vertex = load.vertex( );
    faces = load.faces( );
    load.free( );
    graph( );
    retainedMode( );
    node = new Node(scene){
      // Note that within visit() geometry is defined at the
      // node local coordinate system.
      @Override
      public void visit() {
        if (animate)
          run(flock);
        render();
      }

      // Behaviour: tapping over a boid will select the node as
      // the eye reference and perform an eye interpolation to it.
      @Override
      public void interact(TapEvent event) {
        if (avatar != this && scene.eye().reference() != this) {
          avatar = this;
          scene.eye().setReference(this);
          scene.interpolateTo(this);
        }
      }
    };
    node.setPosition(new Vector(position.x(), position.y(), position.z()));
    velocity = new Vector(random(-1, 1), random(-1, 1), random(1, -1));
    acceleration = new Vector(0, 0, 0);
    neighborhoodRadius = 100;
  }

  public void run(ArrayList<Boid> boids) {
    t += .1;
    flap = 10 * sin(t);
    // acceleration.add(steer(new Vector(mouseX,mouseY,300),true));
    // acceleration.add(new Vector(0,.05,0));
    if (avoidWalls) {
      acceleration.add(Vector.multiply(avoid(new Vector(position.x(), flockHeight, position.z())), 5));
      acceleration.add(Vector.multiply(avoid(new Vector(position.x(), 0, position.z())), 5));
      acceleration.add(Vector.multiply(avoid(new Vector(flockWidth, position.y(), position.z())), 5));
      acceleration.add(Vector.multiply(avoid(new Vector(0, position.y(), position.z())), 5));
      acceleration.add(Vector.multiply(avoid(new Vector(position.x(), position.y(), 0)), 5));
      acceleration.add(Vector.multiply(avoid(new Vector(position.x(), position.y(), flockDepth)), 5));
    }
    flock(boids);
    move();
    checkBounds();
  }

  Vector avoid(Vector target) {
    Vector steer = new Vector(); // creates vector for steering
    steer.set(Vector.subtract(position, target)); // steering vector points away from
    steer.multiply(1 / sq(Vector.distance(position, target)));
    return steer;
  }

  //-----------behaviors---------------

  void flock(ArrayList<Boid> boids) {
    //alignment
    alignment = new Vector(0, 0, 0);
    int alignmentCount = 0;
    //cohesion
    Vector posSum = new Vector();
    int cohesionCount = 0;
    //separation
    separation = new Vector(0, 0, 0);
    Vector repulse;
    for (int i = 0; i < boids.size(); i++) {
      Boid boid = boids.get(i);
      //alignment
      float distance = Vector.distance(position, boid.position);
      if (distance > 0 && distance <= neighborhoodRadius) {
        alignment.add(boid.velocity);
        alignmentCount++;
      }
      //cohesion
      float dist = dist(position.x(), position.y(), boid.position.x(), boid.position.y());
      if (dist > 0 && dist <= neighborhoodRadius) {
        posSum.add(boid.position);
        cohesionCount++;
      }
      //separation
      if (distance > 0 && distance <= neighborhoodRadius) {
        repulse = Vector.subtract(position, boid.position);
        repulse.normalize();
        repulse.divide(distance);
        separation.add(repulse);
      }
    }
    //alignment
    if (alignmentCount > 0) {
      alignment.divide((float) alignmentCount);
      alignment.limit(maxSteerForce);
    }
    //cohesion
    if (cohesionCount > 0)
      posSum.divide((float) cohesionCount);
    cohesion = Vector.subtract(posSum, position);
    cohesion.limit(maxSteerForce);

    acceleration.add(Vector.multiply(alignment, 1));
    acceleration.add(Vector.multiply(cohesion, 3));
    acceleration.add(Vector.multiply(separation, 1));
  }

  void move() {
    velocity.add(acceleration); // add acceleration to velocity
    velocity.limit(maxSpeed); // make sure the velocity vector magnitude does not
    // exceed maxSpeed
    position.add(velocity); // add velocity to position
    node.setPosition(position);
    node.setRotation(Quaternion.multiply(new Quaternion(new Vector(0, 1, 0), atan2(-velocity.z(), velocity.x())),
      new Quaternion(new Vector(0, 0, 1), asin(velocity.y() / velocity.magnitude()))));
    acceleration.multiply(0); // reset acceleration
  }

  void checkBounds() {
    if (position.x() > flockWidth)
      position.setX(0);
    if (position.x() < 0)
      position.setX(flockWidth);
    if (position.y() > flockHeight)
      position.setY(0);
    if (position.y() < 0)
      position.setY(flockHeight);
    if (position.z() > flockDepth)
      position.setZ(0);
    if (position.z() < 0)
      position.setZ(flockDepth);
  }

  void retainedMode(){
    // Create the polygon mesh in retained mode with vertex-vertex representation
    shapeVV = new PShape[load.vertexSize()];
    for( int i = 0; i < load.vertexSize( ); i++){
      shapeVV[i] = createShape(  );
    }
    for( int i = 0; i < load.vertexSize( ); i++){
      
      visitorRetained( 0, (HashMap) graph.get( 0 ) );
      
      shapeVV[i].setFill( color( 255, 0, 0, 125 ) );
      shapeVV[i].setStroke( color( 0, 255, 0 ) );
      shapeVV[i].setStrokeWeight( 2 );
    }
    // Create the polygon mesh in retained mode with face-vertex representation
    shapeFV = new PShape[load.facesSize()];
    for( int i = 0; i < load.facesSize( ); i++ ){
      shapeFV[i] = createShape( );
      shapeFV[i].beginShape( );
      for( int j = 0; j < 3; j++ ){
        shapeFV[i].vertex( vertex[faces[i][j]][0] * sc, vertex[faces[i][j]][1] * sc, vertex[faces[i][j]][2] * sc );
      }
      shapeFV[i].endShape( );
      shapeFV[i].setFill( color( 255, 0, 0, 125 ) );
      shapeFV[i].setStroke( color( 0, 255, 0 ) );
      shapeFV[i].setStrokeWeight( 2 );
    }
  }

  void graph( ){
    graph = new HashMap();
    colorVertex = new HashMap();
    for( int i = 0; i < load.vertexSize( ); i++ ){
      graph.put( i, new HashMap( ) );
      colorVertex.put( i, "w" );
    }
    for( int i = 0; i < load.facesSize( ); i++ ){
      ((HashMap) graph.get( faces[i][0] )).put( faces[i][1], null );
      ((HashMap) graph.get( faces[i][0] )).put( faces[i][2], null );
      ((HashMap) graph.get( faces[i][1] )).put( faces[i][0], null );
      ((HashMap) graph.get( faces[i][1] )).put( faces[i][2], null );
      ((HashMap) graph.get( faces[i][2] )).put( faces[i][0], null );
      ((HashMap) graph.get( faces[i][2] )).put( faces[i][1], null );
    }
  }

  void render() {
    pushStyle();

    // uncomment to draw boid axes
    //scene.drawAxes(10);

    int kind = TRIANGLES;
    strokeWeight(2);
    stroke(color(0, 255, 0));
    fill(color(255, 0, 0, 125));

    // visual modes
    switch(mode) {
    case 1:
      noFill();
      break;
    case 2:
      noStroke();
      break;
    case 3:
      strokeWeight(3);
      kind = POINTS;
      break;
    }

    // highlight boids under the mouse
    if (node.track(mouseX, mouseY)) {
      noStroke();
      fill(grabsMouseColor);
    }

    // highlight avatar
    if (node == avatar) {
      noStroke();
      fill(avatarColor);
    }

    //draw boid
    if( representation == 0 )
      faceVertex( );
    else if( representation == 1 )
      vertexVertex( );
    else
      edgeVertex( );

    popStyle();
  }

  void faceVertex(  ){

    if( retainedMode ){
      for( int i = 0; i < load.facesSize( ); i++ )
        shape( shapeFV[i] );
    }else{
      for( int i = 0; i < load.facesSize( ); i++ ){
        beginShape( );
        for( int j = 0; j < 3; j++ )
          vertex( vertex[faces[i][j]][0] * sc, vertex[faces[i][j]][1] * sc, vertex[faces[i][j]][2] * sc );
        endShape();
      }
    }

  }

  void edgeVertex( ){

    for( int i = 0; i < load.vertexSize(); i++ ){
      HashMap node =  ((HashMap)graph.get( i ));
      Integer[] nodes = (Integer[])((node.keySet( )).toArray( new Integer[0] ));
      beginShape( TRIANGLE_STRIP );
      for( int j = 0; j < node.size( ); j++ ){
        vertex( vertex[i][0] * sc, vertex[i][1] * sc, vertex[i][2] * sc );
        vertex( vertex[nodes[j]][0] * sc, vertex[nodes[j]][1] * sc, vertex[nodes[j]][2] * sc );
      }
      endShape( );
    }

  }

  void vertexVertex( ){

    if( retainedMode ){
      for( int i = 0; i < load.facesSize( ); i++ )
        shape( shapeFV[i] );
    }else{
      beginShape( TRIANGLE_STRIP );
      visitor( 0, (HashMap) graph.get( 0 ) );
      endShape( );
      for( int i = 0; i < load.vertexSize( ); i++ ){
        colorVertex.put( i, "w" );
      }
    }

  }

  void visitor( int key, HashMap node ){
    colorVertex.replace( key, "g" );
    Integer[] nodes = (Integer[])((node.keySet( )).toArray( new Integer[0] ));
    for( int i = 0; i < nodes.length; i++ ){;
      if( colorVertex.get( nodes[i] ).equals( "b" ) ){
        vertex( vertex[nodes[i]][0] * sc, vertex[nodes[i]][1] * sc, vertex[nodes[i]][2] * sc );
        vertex( vertex[key][0] * sc, vertex[key][1] * sc, vertex[key][2] * sc );
      }else if( colorVertex.get( nodes[i] ).equals( "w" ) ){
        visitor( nodes[i], (HashMap) graph.get( nodes[i] ) );
      }
    }
    colorVertex.replace( key, "b" );
  }
  
  void visitorRetained( int key, HashMap node ){
    colorVertex.replace( key, "g" );
    Integer[] nodes = (Integer[])((node.keySet( )).toArray( new Integer[0] ));
    shapeVV[key].beginShape( TRIANGLE_STRIP );
    for( int i = 0; i < nodes.length; i++ ){;
      if( colorVertex.get( nodes[i] ).equals( "b" ) ){
        shapeVV[key].vertex( vertex[nodes[i]][0] * sc, vertex[nodes[i]][1] * sc, vertex[nodes[i]][2] * sc );
        shapeVV[key].vertex( vertex[key][0] * sc, vertex[key][1] * sc, vertex[key][2] * sc );
      }else if( colorVertex.get( nodes[i] ).equals( "w" ) ){
        visitor( nodes[i], (HashMap) graph.get( nodes[i] ) );
      }
    }
    shapeVV[key].endShape( );
    colorVertex.replace( key, "b" );
  }

}