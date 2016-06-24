// ---------------------------------------------------------------------------------------------------------------------
// init system
// ---------------------------------------------------------------------------------------------------------------------

var three = THREE.Bootstrap({
		plugins: ['core', 'controls', 'cursor'],
		controls: {
			klass: THREE.OrbitControls
			//~ klass: THREE.FirstPersonControls
      }
	  });
	  
    // Alter controls
    three.controls.rotateSpeed = 1.0;

var scene=three.scene, camera=three.camera,renderer=three.renderer;
	  
// ---------------------------------------------------------------------------------------------------------------------
// Config renderer, camera, lights  ...
// ---------------------------------------------------------------------------------------------------------------------
	  
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.setClearColor( 0x8888ff );

camera.fov=20;

camera.position.set(0, 12, 20);

var ambient = new THREE.AmbientLight( 0x555555 );
				scene.add( ambient );


var light = new THREE.SpotLight( 0xffffff, 1, 0, Math.PI / 2 );
				light.position.set( 100, 150, 100 );
				light.target.position.set( 0, 0, 0 );
				light.castShadow = true;
				light.shadow = new THREE.LightShadow( new THREE.PerspectiveCamera( 20, 1, 50, 500 ) );
				light.shadow.bias = 0.0001;
				light.shadow.mapSize.width = 1024;
				light.shadow.mapSize.height = 1024;
				scene.add( light );

// ---------------------------------------------------------------------------------------------------------------------
// Define Scene
// ---------------------------------------------------------------------------------------------------------------------
	  
var floor_height=3.0,wall_thickness=0.1

var abs=Math.abs
	  
make_color_material=function(color=0xFFFFFF){
	return new THREE.MeshPhongMaterial({ color: color });
}

make_box=function(fx,fy,fz, 	tx,ty,tz,	color=0xFFFFFF){
	var geo=new THREE.CubeGeometry(abs(tx-fx), abs(ty-fy), abs(tz-fz));
	var mat=make_color_material(color);
	var box=new THREE.Mesh(geo,mat);
	box.position.set((fx+tx)*0.5,(fy+ty)*0.5,(fz+tz)*0.5);
	box.castShadow = true;
	box.receiveShadow = true;
	return box;
}

make_ground=function(west,east,north,south,height,color=0xFFFFFF,offset=0.3, thickness=wall_thickness){
	return make_box(west-offset,height-thickness,north-offset, 	east+offset,height+thickness,south+offset, 	color);
}
	  
make_wall_west_to_east=function(west,east, bottom,top,  pos, color=0x880000,thickness=wall_thickness){
	return make_box(west,bottom,pos-thickness, 	east,top,pos+thickness, 	color);
}

make_wall_north_to_south=function(north,south,  bottom,top,  pos,  color=0x880000, thickness=wall_thickness){
	return make_box(pos-thickness,bottom,north, 	pos+thickness,top,south, 	color);
}

set_matrix=function(obj,n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44){
	obj.matrix.set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44);
	obj.matrixWorldNeedsUpdate=true;
	obj.matrixAutoUpdate=false;
	return obj
}

make_stick_east_to_west=function(fx,fy, tx, ty, z,  color=0xFFFFFF){
	var sx=abs(tx-fx),sy=0.5,sz=0.2;
	var geo=new THREE.CubeGeometry(abs(tx-fx), 0.5, 0.2 );
	var mat=make_color_material(color);
	var box=new THREE.Mesh(geo,mat);
	set_matrix(box,
		1,0,0,(fx+tx)*0.5,
		(ty-fy)/(tx-fx),1,0,(fy+ty)*0.5,
		0,0,1,z,
		0,0,0,1
	);
	box.castShadow = true;
	box.receiveShadow = true;
	return box;
}

make_stand_stick=function(x,y,z,height=1.2,hsize=0.02,color=0x0000FF){
	return make_box(x-hsize,y,z-hsize,x+hsize,y+height,z+hsize,color);
}

append_stairs_north_south=function(parent, n, bottom, top, north, south, west, east, color ){
	var dy=(top-bottom)/n,dz=(south-north)/n;
	while (n-- ) {
		parent.add(make_stand_stick(west,bottom,north+dz/2));
		parent.add(make_stand_stick(east,bottom,north+dz/2));
		parent.add(make_box(west,bottom,north,   east,bottom+dy,north+dz, color   ));
		bottom+=dy;
		north+=dz;
	}
	return parent;
}

append_stairs_west_east=function(parent, n, bottom, top, north, south, west, east, color ){
	var dy=(top-bottom)/n,dx=(east-west)/n;
	parent.add(make_stick_east_to_west(west,bottom+1.5, 	east, top+1.5, north	));
	parent.add(make_stick_east_to_west(west,bottom+1.5, 	east, top+1.5, south	));
	while (n-- ) {
		parent.add(make_stand_stick(west+dx/2,bottom,north));
		parent.add(make_stand_stick(west+dx/2,bottom,south));
		parent.add(make_box(west,bottom,north,   west+dx,bottom+dy,south, color   ));
		bottom+=dy;
		west+=dx;
	}
	return parent;
}

var buildings=[]

var ground_size=40
buildings.push(make_ground(-ground_size,ground_size, -ground_size,ground_size, -3, 0x008800)); // ground

buildings.push(function(h=0,color_ground=0xFFFFFF,color_wall=0x880000){
	var floor=make_ground( -5,5,	-4,4, 	h,	  color_ground);
	floor.add(make_wall_west_to_east(-5,5,  0,floor_height ,  -4, color_wall));
	floor.add(make_wall_west_to_east(-5,-4,  0,floor_height ,  4, color_wall));
	floor.add(make_wall_west_to_east(-3,5,  0,floor_height ,  4, color_wall));
	
	floor.add(make_wall_north_to_south(-4,4,  0,floor_height ,  5, color_wall));
	floor.add(make_wall_north_to_south(-4,4,  0,floor_height ,  -5, color_wall));
	
	append_stairs_north_south(floor, 10,  0, -3,   4,7,    -4,-3  );
	append_stairs_north_south(floor, 10,  0, -3,   -4,-7,    -4,-3  );
	
	append_stairs_west_east(floor, 10,  0, -3,   -1,1,    -5,-8  );
	append_stairs_west_east(floor, 10,  0, -3,   -1,1,    5,8  );
	
	return floor;
}()); // floor 1

buildings.push(function(h=floor_height,color_ground=0xFFFFFF,color_wall=0x880000){
	var floor=make_ground( -5,5,	-4,4, 	h,	  color_ground);
	floor.add(make_wall_west_to_east(-5,5,  0,floor_height ,  -4, color_wall));
	floor.add(make_wall_west_to_east(-5,-4,  0,floor_height ,  4, color_wall));
	floor.add(make_wall_west_to_east(-3,5,  0,floor_height ,  4, color_wall));
	floor.add(make_wall_north_to_south(-4,4,  0,floor_height ,  5, color_wall));
	floor.add(make_wall_north_to_south(-4,4,  0,floor_height ,  -5, color_wall));
	return floor;
}());// floor 2

buildings.push(function(h=2*floor_height,color_ground=0xFFFFFF){
	var floor=make_ground( -5,5,	-4,4, 	h,	  color_ground);
	var wall_height=0.7;
	floor.add(make_wall_west_to_east(-5,5,  0,wall_height ,  -4, color_ground));
	floor.add(make_wall_west_to_east(-5,5,  0,wall_height ,  4, color_ground));
	floor.add(make_wall_north_to_south(-4,4,  0,wall_height ,  5, color_ground));
	floor.add(make_wall_north_to_south(-4,4,  0,wall_height ,  -5, color_ground));
	return floor;
}()); // roof

for ( x in buildings ) {	scene.add(buildings[x]);}

toggle_property=function(obj,key){	obj[key]=!obj[key];}

var onKeyDown=function (event) {
	var ch=event.charCode;
	switch ( ch ) {
		case 115: // 's' pressed
			toggle_property(light,"castShadow");
			break;
		default:
			ch-=48;
			if(ch>=0 && ch<buildings.length) { toggle_property(buildings[ch],"visible"); }
			break;
	}
}

window.addEventListener( 'keypress', onKeyDown, false );


