class LoadFile{
  
  // Begin Variables
  private String fileName;
  private String[] file;
  private int NVertices;
  private int NFaces;
  private float[][] vertex;
  private int[][] faces;
  // End Variables

  // Begin Constructors
  LoadFile(  ){
    this( "bird.ply" );
  }
  
  LoadFile( String fileName ){
    this.fileName = fileName;
    load( );
  }
  // End Constructors

  // Begin getters
  int vertexSize( ){
    return NVertices;
  }
  int facesSize(){
    return NFaces;
  }
  float[][] vertex(){
    return vertex;
  }
  int[][] faces(){
    return faces;
  }
  // End getters

  // Begin Methods
  void load( ){
    try{
      file = loadStrings( fileName );
    }catch( Exception e ){
      println( "Please, include a valid file name or save valid file \"bird.ply\"." );
      exit( );
    }
    
    try{
      String[] line;
      int init = 0;
      // Read the header of file and get the number of NVertices and NFaces
      for( int i = 0, j = 0; j < 3; i++ ){
        line = split( file[i], ' ' );
        if( line[0].equals( "element" ) ){
          if( line[1].equals( "vertex" ) ){
            NVertices = Integer.parseInt( line[2] );
            j++;
          }else if( line[1].equals( "face" ) ){
            NFaces = Integer.parseInt( line[2] );
            j++;
          }
        }else if( line[0].equals( "end_header" ) ){
          init = i + 1;
          j = 3;
        }
      }
      // Read the vertices and faces
      vertex = new float[NVertices][3];
      for( int i = 0; i < NVertices; i++ ){
        line = split( file[i + init], ' ' );
        vertex[i][0] = Float.parseFloat( line[0] );
        vertex[i][1] = Float.parseFloat( line[1] );
        vertex[i][2] = Float.parseFloat( line[2] );
      }
      init += NVertices;
      faces = new int[NFaces][3];
      for( int i = 0; i < NFaces; i++ ){
        line = split( file[i + init], ' ' );
        faces[i][0] = Integer.parseInt( line[1] );
        faces[i][1] = Integer.parseInt( line[2] );
        faces[i][2] = Integer.parseInt( line[3] );
      }

    }catch( Exception e ){
      println( "Please save a valid structure of plain text." );
      println( "For more information read the README file." );
      exit( );
    }
/*// BEGIN DEBUG
String[] aux = new String[NVertices];
for( int i = 0; i < NVertices; i++ ){
  aux[i] = str( vertex[i][0] ) + ' ' + str( vertex[i][1] ) + ' ' + str( vertex[i][2] );
}
saveStrings( "vertex.txt", aux );
aux = new String[NFaces];
for( int i = 0; i < NFaces; i++ ){
  aux[i] = str( faces[i][0] ) + ' ' + str( faces[i][1] ) + ' ' + str( faces[i][2] ) + ' ' + str( faces[i][3] );
}
saveStrings( "faces.txt", aux );
println( "End of load data." );
// END DEBUG*/
  }
  
  void free( ){
    vertex = null;
    faces = null;
  }
  // End Methods
  
}