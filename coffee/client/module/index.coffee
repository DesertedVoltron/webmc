
scene=null;materials=null;parameters=null;canvas=null;renderer=null;camera=null;world=null;cursor=null;FPC=null;socket=null;stats=null;worker=null;playerObject=null;inv_bar=null;params=null
import * as THREE from './build/three.module.js'
import {SkeletonUtils} from './jsm/utils/SkeletonUtils.js'
import Stats from './jsm/libs/stats.module.js'
import {World} from './World/World.js'
import {FirstPersonControls} from './FirstPersonControls.js'
import {gpuInfo} from './gpuInfo.js'
import {AssetLoader} from './AssetLoader.js'
import {InventoryBar} from './InventoryBar.js'
import {RandomNick} from './RandomNick.js'
import {GUI} from './jsm/libs/dat.gui.module.js'

init = ()->
	#Płótno,renderer,scena i kamera
	canvas=document.querySelector '#c'
	renderer=new THREE.WebGLRenderer {
		canvas
		PixelRatio:window.devicePixelRatio
	}
	scene=new THREE.Scene
	camera = new THREE.PerspectiveCamera 100, 2, 0.1, 1000
	camera.rotation.order = "YXZ"
	camera.position.set 26, 26, 26

	#Skybox
	rt = new THREE.WebGLCubeRenderTarget al.get("skybox").image.height
	rt.fromEquirectangularTexture renderer, al.get "skybox"
	scene.background = rt

	#Światła
	ambientLight=new THREE.AmbientLight 0xcccccc
	scene.add ambientLight
	directionalLight = new THREE.DirectionalLight 0x333333, 2
	directionalLight.position.set(1, 1, 0.5).normalize()
	scene.add directionalLight

	#Informacja o gpu komputera
	console.warn gpuInfo()

	#Chmury
	clouds=al.get "clouds"
	clouds.scale.x=0.1
	clouds.scale.y=0.1
	clouds.scale.z=0.1
	clouds.position.y=170
	scene.add clouds

	#FPSy
	stats = new Stats()
	stats.showPanel 0
	document.body.appendChild stats.dom

	#Utworzenie klasy świat
	world=new World({
		toxelSize:27
		cellSize:16
		scene
		camera
		al
	})

	#komunikacja z serwerem websocket
	socket=io.connect "#{al.get("host")}:#{al.get("websocket-port")}"
	socket.on "connect",()->
		console.log "Połączono z serverem!"
		$('.loadingText').text "Za chwilę dołączysz do gry..."
		nick=document.location.hash.substring(1,document.location.hash.length)
		if nick is ""
			nick=RandomNick()
			document.location.href="\##{nick}"
		console.log "User nick: 	#{nick}"
		socket.emit "initClient", {
			nick:nick
		}
		return
	socket.on "blockUpdate",(block)->
		world.setBlock block[0],block[1]+16,block[2],block[3]
		return
	socket.on "spawn", (sections,x,z,biomes)->
		console.log "Gracz dołączył do gry!"
		$(".initLoading").css "display","none"
	socket.on "mapChunk", (sections,x,z,biomes)->
		world._computeSections sections,x,z,biomes
	socket.on "hp",(points)->
		inv_bar.setHp(points)
	socket.on "food",(points)->
		inv_bar.setFood(points)
	socket.on "msg",(msg)->
		$(".chat").append(msg+"<br>")
	socket.on "xp",(xp)->
		$(".player_xp").text(xp.level)
		$(".progress-bar").css("width",xp.progress*100+"%")
	socket.on "move", (pos)->
		to={x:pos.x-0.5,y:pos.y+17,z:pos.z-0.5}
		new TWEEN.Tween camera.position
			.to to, 100
			.easing TWEEN.Easing.Quadratic.Out
			.start()

	#Utworzenie inventory
	inv_bar = new InventoryBar({
		boxSize: 60
		padding: 4
		div: ".inventoryBar"
	}).setBoxes([
		"assets/images/grass_block.png",
		"assets/images/stone.png",
		"assets/images/oak_planks.png",
		"assets/images/smoker.gif",
		"assets/images/anvil.png",
		"assets/images/brick.png",
		"assets/images/furnace.png",
		"assets/images/bookshelf.png",
		"assets/images/tnt.png"
	]).setFocusOnly(1).listen()

	#Kontrolki gracza
	FPC = new FirstPersonControls {
		canvas
		camera
		micromove: 0.3
		socket
	}

	#Kursor raycastowania
	cursor=new THREE.LineSegments(
		new THREE.EdgesGeometry(
			new THREE.BoxGeometry 1, 1, 1
		),
		new THREE.LineBasicMaterial {
			color: 0x000000,
			linewidth: 0.5
		}
	)
	scene.add cursor

	#Mgła
	color = new THREE.Color "#adc8ff"
	near = 3*16-13
	far = 3*16-3
	scene.fog = new THREE.Fog color, near, far

	#Interfejs dat.gui
	gui = new GUI()
	params={
		fog:true
		chunkdist:4
	}
	gui.add( params, 'fog' ).name( 'Enable fog' ).listen().onChange ()->
		if params.fog
			scene.fog = new THREE.Fog color, near, far
		else
			scene.fog = null
	gui.add( world.material, 'wireframe' ).name( 'Wireframe' ).listen()
	gui.add( params, 'chunkdist',0,10,1).name( 'Render distance' ).listen()

	#Wprawienie w ruch funkcji animate
	animate()
	return

#Renderowanie
render = ->
	#Automatyczne zmienianie rozmiaru renderera
	width=window.innerWidth
	height=window.innerHeight
	if canvas.width isnt width or canvas.height isnt height
		canvas.width=width
		canvas.height=height
		renderer.setSize width,height,false
		camera.aspect = width / height
		camera.updateProjectionMatrix()

	#Raycastowany block
	rayBlock=world.getRayBlock()
	if rayBlock
		pos=rayBlock.posBreak
		pos[0]=Math.floor pos[0]
		pos[1]=Math.floor pos[1]
		pos[2]=Math.floor pos[2]
		cursor.position.set pos...
		cursor.visible=true
	else
		cursor.visible=false

	#Updatowanie komórek wokół gracza
	world.updateCellsAroundPlayer camera.position,params.chunkdist

	#Updatowanie sceny i animacji TWEEN
	TWEEN.update();
	renderer.render scene, camera
	return

#Funkcja animate
animate = ->
	try
		stats.begin()
		render()
		stats.end()
	requestAnimationFrame animate
	return

#AssetLoader
al=new AssetLoader
$.get "assets/assetLoader.json", (assets)->
	al.load assets,()->
		console.log "AssetLoader: done loading!"
		init()
		return
	,al
	return