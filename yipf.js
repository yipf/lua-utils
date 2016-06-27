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
				light.position.set( -100, 100, 100 );
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

make_wall_from_xz=function(fx,fz,tx,tz,top,bottom,color=0x880000){
	if(abs(tx-fx)<wall_thickness){
		return make_box(fx-wall_thickness,bottom,fz,tx+wall_thickness,top,tz,color);
	}else if(abs(tz-fz)<wall_thickness){
		return make_box(fx,bottom,fz-wall_thickness,tx,top,tz+wall_thickness,color);
	}
	return make_box(fx,bottom,fz,tx,top,tz,color);
}

append_walls_from_points2d=function(parent,points2d,top=floor_height,bottom=0.0,color=0x880000){
	var from=points2d[0],to,h1,h2;
	for ( i=1; i<points2d.length; i++ ) {
		to=points2d[i];
		h1=from[2];
		h2=from[3];
		if(h1 && h2){
			if(h1>bottom){parent.add(make_wall_from_xz(from[0],from[1],to[0],to[1],h1,bottom,color));}
			if(h2<top){parent.add(make_wall_from_xz(from[0],from[1],to[0],to[1],top,h2,color));}
		}else{
			parent.add(make_wall_from_xz(from[0],from[1],to[0],to[1],top,bottom,color));
		}
		from=to;
	}
	return parent;
}

append_stairs_x=function(parent,fx,fy,fz,tx,ty,tz,n,color){
	var dx=(tx-fx)/n,dy=(ty-fy)/n;
	while(n--){
		parent.add(make_box(fx,fy,fz,fx+dx,fy+dy,tz,color));
		fx+=dx;
		fy+=dy;
	}
	return parent;
}

append_stairs_z=function(parent,fx,fy,fz,tx,ty,tz,n,color){
	var dz=(tz-fz)/n,dy=(ty-fy)/n;
	while(n--){
		parent.add(make_box(fx,fy,fz,tx,fy+dy,fz+dz,color));
		fz+=dz;
		fy+=dy;
	}
	return parent;
}

append_stairs_from_points3d=function(parent,points3d,N=8,width=0.5,color=0xFFFFFF){
	var from=points3d[0],to,n,w;
	for ( i=1; i<points3d.length; i++ ) {
		to=points3d[i];
		n=from[3] || N;
		w=from[4] || width;
		dy=0;
		if(abs(to[1]-from[1])<0.001){ n=1; dy=wall_thickness;}
				alert("n:"+n+"w:"+w);
		if(abs(to[0]-from[0])<0.001){
			append_stairs_z(parent,from[0],from[1]-dy,from[2]-w,to[0],to[1]+dy,to[2]+w,n,color);
		}else if(abs(to[2]-from[2])<0.001){
			append_stairs_x(parent,from[0]-w,from[1]-dy,from[2],to[0]+w,to[1]+dy,to[2],n,color);
		}else{
			parent.add(make_box(from[0],from[1]-dy,from[2],to[0],to[1]+dy,to[2],color));
		}
		from=to;
	}
	return parent;
}

append_armrest_form_points3d=function(parent,points3d,sitck_color=0x0000FF,bar_color=0xFFFFFF){
	
}
make_ground=function(west,east,north,south,height,color=0xFFFFFF,offset=0.3, thickness=wall_thickness){
	return make_box(west-offset,height-thickness,north-offset, 	east+offset,height+thickness,south+offset, 	color);
}

set_matrix=function(obj,n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44){
	obj.matrix.set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44);
	obj.matrixWorldNeedsUpdate=true;
	obj.matrixAutoUpdate=false;
	return obj
}

make_stand_stick=function(x,y,z,height=1.2,hsize=0.02,color=0x0000FF){
	return make_box(x-hsize,y,z-hsize,x+hsize,y+height,z+hsize,color);
}

make_bar_east_to_west=function(fx,fy, tx, ty, z, color=0xFFFFFF){
	var geo=new THREE.CubeGeometry(abs(tx-fx), 0.3, 0.2 );
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

append_armrest_west_to_east=function(parent=scene, west, east, h_west, h_east,  pos, n,stick_height=1.5, color_bar=0xFFFFFF, color_stick=0x0000FF){
	parent.add(make_bar_east_to_west(west,h_west+stick_height, 	east, h_east+stick_height, pos	));
	var dx=(east-west)/n, dy=(h_east-h_west)/n
	while(n--){
		parent.add(make_stand_stick(west+dx/2,h_west,pos,stick_height));
		west+=dx;
		h_west+=dy;
	}
	return parent;
}

make_bar_north_to_south=function(fz,fy, tz, ty, x, color=0xFFFFFF){
	var geo=new THREE.CubeGeometry(0.2, 0.3, abs(tz-fz) );
	var mat=make_color_material(color);
	var box=new THREE.Mesh(geo,mat);
	set_matrix(box,
		1,0,0,x,
		0,1,(ty-fy)/(tz-fz),(fy+ty)*0.5,
		0,0,1,(fz+tz)*0.5,
		0,0,0,1
	);
	box.castShadow = true;
	box.receiveShadow = true;
	return box;
}

append_armrest_north_to_south=function(parent=scene, north, south, h_north, h_south, pos, n, stick_height=1.5, color_bar=0xFFFFFF, color_stick=0x0000FF){
	parent.add(make_bar_north_to_south(north,h_north+stick_height, 	south, h_south+stick_height, pos	));
	var dz=(south-north)/n, dy=(h_south-h_north)/n;
	while(n--){
		parent.add(make_stand_stick(pos,h_north,north+dz/2,stick_height));
		north+=dz;
		h_north+=dy;
	}
	return parent;
}


append_stairs_north_to_south=function(parent, n, bottom, top, north, south, west, east, color=0xFFFFFF ){
	var dy=(top-bottom)/n,dz=(south-north)/n;
	while (n-- ) {
		parent.add(make_box(west,bottom,north,   east,bottom+dy,north+dz, color   ));
		bottom+=dy;
		north+=dz;
	}
	return parent;
}

append_stairs_west_to_east=function(parent, n, bottom, top, north, south, west, east, color=0xFFFFFF ){
	var dy=(top-bottom)/n,dx=(east-west)/n;
	while (n-- ) {
		parent.add(make_box(west,bottom,north,   west+dx,bottom+dy,south, color   ));
		bottom+=dy;
		west+=dx;
	}
	return parent;
}


append_outdoor_stairs=function(parent=scene,x,y,z){
	var dx=2.5, dy=1.5,dz=1.0; 
	
	parent.add(make_box(x-0.1,y,z-1, x+0.1, y+2, z));
	
	parent.add(make_box(x-1,y+2.6,z-1, x+1, y+3, z+1));
	parent.add(make_box(x-1,y,z-1, x+1, y+3, z-1.1));
	parent.add(make_box(x+1,y,z-1, x+1.1, y+3, z));
	
	parent.add(make_ground(x-1,x+1,z-1,z,y,0xFFFFFF,0));

	append_stairs_north_to_south(parent, 8, y, y-dy, z,z+2, x-1,x+1);
	append_armrest_north_to_south(parent,z,z+2,y,y-dy,x,8);
	//~ append_armrest_north_to_south(parent,z,z+2,y,y-dy,x-1,8);
	z+=2;
	y-=dy;
	parent.add(make_ground(x-1,x+1,z,z+1,y,0xFFFFFF,0));
	append_armrest_north_to_south(parent,z,z+1,y,y,x,4);
	append_armrest_west_to_east(parent,x-1,x+1,y,y,z+dz,8);
	x-=1;
	append_stairs_west_to_east(parent, 8, y-dy, y, z,z+dz, x-dx, x);
	append_armrest_west_to_east(parent,x-dx,x,y-dy,y,z+dz,8);
	x-=dx;
	y-=dy;
	z+=dz;
	parent.add(make_ground(x-1,x,z-1,z+1,y,0xFFFFFF,0));
	//~ append_armrest_west_to_east(parent,x-1,x,y,y,z-1,4);
	append_armrest_west_to_east(parent,x-1,x,y,y,z+dz,4);
	append_armrest_north_to_south(parent,z-1,z+dz,y,y,x-1,8);
	append_stairs_west_to_east(parent, 8, y, y-dy, z,z+dz, x, x+dx);
	append_armrest_west_to_east(parent,x,x+dx,y,y-dy,z+dz,8);
	append_armrest_west_to_east(parent,x,x+dx,y,y-dy,z,8);
	x+=dx+1;
	y-=dy;
	z+=dz;
	parent.add(make_ground(x-1,x+1,z-1,z,y,0xFFFFFF,0));
	append_armrest_west_to_east(parent,x-1,x+1,y,y,z-1,8);
	append_armrest_north_to_south(parent,z,z+2,y,y-dy,x-1,8);
	append_stairs_north_to_south(parent,8,y,y-dy, z, z+2, x-1, x+1);
	
	return parent;
}


var buildings=[]

var ground_size=40
buildings.push(make_ground(-ground_size,ground_size, -ground_size,ground_size, -wall_thickness, 0x008800)); // ground

buildings.push(function(h=0,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(0,h,0);
	group.add(make_ground( 0,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-1.5],[0,0],[11,0],[11,-8],[0,-8],[0,-2.5]]);
	return group;
}()); // floor 1

buildings.push(function(h=floor_height,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(0,h,0);
	group.add(make_ground( 0,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-1.5],[0,0],[11,0],[11,-8],[0,-8],[0,-2.5]]);
	return group;
}());// floor 2

buildings.push(function(h=2*floor_height,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(0,h,0);
	group.add(make_ground( 0,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-1.5],[0,0,1,2],[11,0],[11,-8],[0,-8],[0,-2.5]]);
	//~ append_outdoor_stairs(group,1,0,-1.5);
	var x=-1,z=-1.5;
	append_stairs_from_points3d(group,[[x,h,z],[x,h,z-1],[x,h-1.5,z-2]]);
	
	
	return group;
}());// floor 3

buildings.push(function(h=3*floor_height,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(0,h,0);
	group.add(make_ground( 0,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-1.5],[0,0],[11,0],[11,-8],[0,-8],[0,-2.5]]);
	return group;
}());// floor 4

buildings.push(function(h=4*floor_height,color_ground=0xFFFFFF){
	var group=new THREE.Group(); 
	group.position.set(0,h,0);
	group.add(make_ground( 0,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-8],[11,-8],[11,0],[0,0],[0,-8]],1.0,0,0xFFFFFF);
	return group;
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


