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
// Helper functions
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
		if(h1 || h2){
			if(h1 && h1>bottom){parent.add(make_wall_from_xz(from[0],from[1],to[0],to[1],h1,bottom,color));}
			if(h2 && h2<top){parent.add(make_wall_from_xz(from[0],from[1],to[0],to[1],top,h2,color));}
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

append_stairs_from_points3d=function(parent,points3d,increase,N=8,width=0.5,color=0xFFFFFF){
	var from=points3d[0],to,n,w,dy;
	for ( i=1; i<points3d.length; i++ ) {
		to=points3d[i];
		n=from[3] || N;
		w=from[4] || width;
		dy=0;
		if(abs(to[1]-from[1])<0.001){ n=1; dy=wall_thickness;}
		if(abs(to[0]-from[0])<0.001){
			append_stairs_z(parent,from[0]-w,from[1]-dy,from[2],to[0]+w,to[1]+dy,to[2],n,color);
		}else if(abs(to[2]-from[2])<0.001){
			append_stairs_x(parent,from[0],from[1]-dy,from[2]-w,to[0],to[1]+dy,to[2]+w,n,color);
		}else{
			parent.add(make_box(from[0],from[1]-dy,from[2],to[0],to[1]+dy,to[2],color));
		}
		from=to;
	}
	return parent;
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

make_bar_x=function(fx,fy,fz,  tx, ty, tz, color=0xFFFFFF){
	var geo=new THREE.CubeGeometry(abs(tx-fx), 0.3, 0.2 );
	var mat=make_color_material(color);
	var box=new THREE.Mesh(geo,mat);
	set_matrix(box,
		1,0,0,(fx+tx)*0.5,
		(ty-fy)/(tx-fx),1,0,(fy+ty)*0.5,
		0,0,1,(tz+fz)*0.5,
		0,0,0,1
	);
	box.castShadow = true;
	box.receiveShadow = true;
	return box;
}

make_bar_z=function(fx,fy,fz, tx, ty, tz, color=0xFFFFFF){
	var geo=new THREE.CubeGeometry(0.2, 0.3, abs(tz-fz) );
	var mat=make_color_material(color);
	var box=new THREE.Mesh(geo,mat);
	set_matrix(box,
		1,0,0,(fx+tx)*0.5,
		0,1,(ty-fy)/(tz-fz),(fy+ty)*0.5,
		0,0,1,(fz+tz)*0.5,
		0,0,0,1
	);
	box.castShadow = true;
	box.receiveShadow = true;
	return box;
}

append_stand_sticks_x=function(parent, fx,fy,fz,tx,ty,tz, n=1,height=1.5, size=0.1,color=0x0000FF){
	var dx=(tx-fx)/n, dy=(ty-fy)/n,z=(fz+tz)/2;
	while(n--){
		parent.add(make_box(fx-size+dx/2,fy,z-size,fx+size+dx/2,fy+height,z+size,color));
		fx+=dx,fy+=dy;
	}
	return parent;
}

append_stand_sticks_z=function(parent, fx,fy,fz,tx,ty,tz, n=1,height=1.5, size=0.1,color=0x0000FF){
	var dz=(tz-fz)/n, dy=(ty-fy)/n, x=(fx+tx)/2;
	while(n--){
		parent.add(make_box(x-size,fy,fz-size+dz/2,x+size,fy+height,fz+size+dz/2,color));
		fz+=dz,fy+=dy;
	}
	return parent;
}

append_armrest_form_points3d=function(parent,points3d,increase,stick_color=0x0000FF,bar_color=0xFFFFFF,N=8,height=1,size=0.02){
	var from=points3d[0],to,h,n,s;
	for ( i=1; i<points3d.length; i++ ) {
		to=points3d[i];
		if(increase){to[0]+=from[0]; to[1]+=from[1]; to[2]+=from[2];	}
		h=from[3] || height;
		n=from[4] || N;
		s=from[5] || size;
		if(abs(to[0]-from[0])<0.001){
			parent.add(make_bar_z(from[0],from[1]+h,from[2],to[0],to[1]+h,to[2],bar_color));
			append_stand_sticks_z(parent,from[0],from[1],from[2],to[0],to[1],to[2],n,h,s,stick_color);
		}else if(abs(to[2]-from[2]<0.001)){
			parent.add(make_bar_x(from[0],from[1]+h,from[2],to[0],to[1]+h,to[2],bar_color));
			append_stand_sticks_x(parent,from[0],from[1],from[2],to[0],to[1],to[2],n,h,s,stick_color);
		}
		from=to;
	}
	return parent;
}


// ---------------------------------------------------------------------------------------------------------------------
// Define Scene
// ---------------------------------------------------------------------------------------------------------------------

var buildings=[]

var ground_size=40
buildings.push(make_ground(-ground_size,ground_size, -ground_size,ground_size, -wall_thickness, 0x008800)); // ground

buildings.push(function(h=0,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(1,h,0);
	group.add(make_ground( -1,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[-1,0],[4.5,0,0,2],[6.5,0],[11,0],[11,-8],[-1,-8],[-1,0]]);
	return group;
}()); // floor 1

buildings.push(function(h=floor_height,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(1,h,0);
	group.add(make_ground( -1,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-5],[-1,-5],[-1,0],[0,0],[11,0],[11,-8],[0,-8],[0,-6]]);
	return group;
}());// floor 2

buildings.push(function(h=2*floor_height,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(1,h,0);
	group.add(make_ground( 0,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-5],[-1,-5],[-1,0],[0,0],[11,0],[11,-8],[0,-8],[0,-6]]);
	// append outdoor stairs
	var x=-0.8,y=0,z=-5;
	append_stairs_from_points3d(group,[[x,y,z],[x,y,z-1],[x,y-1.5,z-3],[x,y-1.5,z-4]]);
	x+=0.5,z-=3.5,y-=1.5;
	append_stairs_from_points3d(group,[[x,y,z],[x+2,y-1.5,z],[x+3,y-1.5,z]]);
	x+=3,y-=1.5,z-=1;
	append_stairs_from_points3d(group,[[x,y,z],[x-1,y,z],[x-3,y-1.5,z],[x-5,y-1.5,z]]);
	x-=4,y-=1.5;z-=0.5;
	append_stairs_from_points3d(group,[[x,y,z,8,1],[x,y-1.5,z-2]]);
	// append armrests
	x=-0.3,y=0,z=-5;
	append_armrest_form_points3d(group,[[x,y,z],[-1,0,0],[0,0,-1],[0,-1.5,-2],[0,0,-1],[1,0,0],[2,-1.5,0],[-2,-1.5,0],[-2,0,0]],true);
	x=2.5,y=-3,z=-8;
	append_armrest_form_points3d(group,[[x,y,z],[0,0,-2],[-1,0,0],[-2,-1.5,0],[0,-1.5,-2]],true);
	return group;
}());// floor 3

buildings.push(function(h=3*floor_height,color_ground=0xFFFFFF,color_wall=0x880000){
	var group=new THREE.Group(); 
	group.position.set(1,h,0);
	group.add(make_ground( -1,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[0,-5],[-1,-5],[-1,0],[0,0],[11,0],[11,-8],[0,-8],[0,-6]]);
	return group;
}());// floor 4

buildings.push(function(h=4*floor_height,color_ground=0xFFFFFF){
	var group=new THREE.Group(); 
	group.position.set(1,h,0);
	group.add(make_ground( -1,11,	-8,0, 	0,	  color_ground));
	append_walls_from_points2d(group,[[-1,-8],[11,-8],[11,0],[-1,0],[-1,-8]],1.0,0,0xFFFFFF);
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


