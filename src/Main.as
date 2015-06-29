package {

import com.emibap.textureAtlas.DynamicAtlas;

import flash.desktop.NativeApplication;

import flash.display.Bitmap;

import flash.display.BitmapData;
import flash.display.BlendMode;

import flash.display.Sprite;
import flash.display.StageQuality;
import flash.filters.BitmapFilterQuality;
import flash.filters.BlurFilter;
import flash.system.System;

import starling.core.Starling;

import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;

import starling.events.KeyboardEvent;

import starling.events.Touch;

import starling.events.TouchEvent;
import starling.events.TouchPhase;

import starling.textures.Texture;
import starling.textures.TextureAtlas;

public class Main extends Sprite {

    public static const FPS_GRAPHICS:int = 60;
    public static const FPS_LOGIC:int = 60;

    public static const NPC_PLAYER:Boolean = true;
    public static const NPC_OPONENT:Boolean = true;
    public static const NETGAME:Boolean = false;
    public static const CROSSED_TURNS:Boolean = true;

    [Embed(source="../assets/terrain.png")]
    public static var TerrainPng:Class;
    [Embed(source="../assets/a.png")]
    public static var APng:Class;
    [Embed(source="../assets/b.png")]
    public static var BPng:Class;
    [Embed(source="../assets/c.png")]
    public static var CPng:Class;
    [Embed(source="../assets/d.png")]
    public static var DPng:Class;

    private var terrainPng:Bitmap = new TerrainPng();
    
    public static var assetClasses:Vector.<Class> = new <Class>[TerrainPng, APng, BPng, CPng, DPng];

    public static var instance:Main;

    public var logicCounter:int = 0;

    public var players:Array = new Array();
    public var units:Vector.<Vector.<UnitView>> = new Vector.<Vector.<UnitView>>();
    public var uiElements:Vector.<UIElementView> = new <UIElementView>[];
    public var stateMachine:StateMachine = new StateMachine();

    private var ingameTimer:CustomTimer = new CustomTimer(5000, 1);

    public var menuLayer:Sprite = new Sprite();
    public var spaceLayer:Sprite = new Sprite();
    public var buildingLayer:Sprite = new Sprite();
    public var unitLayer:Sprite = new Sprite();
    public var placeBuildingLayer:Sprite = new Sprite();
    private var buildingId:int = 0;
    public var netConnect:NetConnect = new NetConnect();
    public var atlas:TextureAtlas;
    public var lineBmpd:BitmapData;
    public var terrain:Image;

    public var pressedKeys:Array = new Array(200);
    public var mousePos:Point = new Point();
    public var mousePressed:Boolean = false;

    public function Main() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        stateMachine.state = "initMenues";
        stateMachine.defineStateRelation("initMenues", "mainMenu", "complete");
        stateMachine.defineStateRelation("mainMenu", "quit", "quit");

        if(NETGAME){
            stateMachine.defineStateRelation("mainMenu", "connect", "start");
            stateMachine.defineStateRelation("connect", "waitingForPlayers", "complete");
            stateMachine.defineStateRelation("waitingForPlayers", "init", "complete");
        } else {
            stateMachine.defineStateRelation("mainMenu", "init", "start");
        }
        if(CROSSED_TURNS){
            stateMachine.defineStateRelationWithParam("init", null, "turn0", "forward", "complete");
            stateMachine.defineStateRelationWithParam("turn0", "forward", "turn1", "forward", "passed");
            stateMachine.defineStateRelationWithParam("turn1", "forward", "ingame", "forward", "passed");
            stateMachine.defineStateRelationWithParam("ingame", "forward", "turn1", "backward", "complete");
            stateMachine.defineStateRelationWithParam("turn1", "backward", "turn0", "backward", "passed");
            stateMachine.defineStateRelationWithParam("turn0", "backward", "ingame", "backward", "passed");
            stateMachine.defineStateRelationWithParam("ingame", "backward", "turn0", "forward", "complete");
        } else {
            stateMachine.defineStateRelation("init", "turn0", "complete");
            stateMachine.defineStateRelation("turn0", "turn1", "passed");
            stateMachine.defineStateRelation("turn1", "ingame", "passed");
            stateMachine.defineStateRelation("ingame", "turn0", "complete");
        }
        stateMachine.defineStateRelation("ingame", "end", "finish");
    }

    private function onAddedToStage(e:Event):void{

        instance = this;

        atlas = DynamicAtlas.fromClassVector(assetClasses);
        lineBmpd = new BitmapData(stage.stageWidth, stage.stageHeight, true, 0x0);

        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        stage.addEventListener(TouchEvent.TOUCH, onTouch);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyReleased);

        addChild(spaceLayer);
        addChild(unitLayer);
        addChild(buildingLayer);
        addChild(placeBuildingLayer);
        addChild(menuLayer);

    }

    public function moveMouse(x:Number, y:Number):void{
        mousePos.x = x;
        mousePos.y = y;
    }

    public function pressMouse():void{
        mousePressed = true;
    }

    public function releaseMouse():void{
        mousePressed = false;
    }

    private function onTouch(e:TouchEvent):void{
        var touch:Touch = e.touches[0];
        moveMouse(touch.globalX, touch.globalY);
        switch(touch.phase){
            case TouchPhase.BEGAN:
                pressMouse();
                break;
            case TouchPhase.ENDED:
                releaseMouse();
                break;
        }
    }

    public function pressKey(keyCode:int):void{
        pressedKeys[keyCode] = true;
    }

    public function releaseKey(keyCode:int):void{
        pressedKeys[keyCode] = false;
    }

    private function onKeyPressed(e:KeyboardEvent):void{
        pressKey(e.keyCode);
    }

    private function onKeyReleased(e:KeyboardEvent):void{
        releaseKey(e.keyCode);
    }

    private function onIngameTimerComplete(e:TimerEvent):void{

        for each(var player:Player in players){
           player.gold += 1;
        }
        for each(var _units:Vector.<UnitView> in units){
            for each(var unit:UnitView in _units){
                unit.owner.velX = 0;
                unit.owner.velY = 0;
            }
        }
        stateMachine.dispatchEvent("complete");
    }

    private function startGame():void{
        stateMachine.dispatchEvent("start");
    }

    private function quitGame():void{
        NativeApplication.nativeApplication.exit();
    }

    private function onEnterFrame(e:Event):void{

        switch(stateMachine.state){
            case "initMenues":
                createUIElement(100, 100, 100, 50, 0xffffffff, "PLAY", startGame);
                createUIElement(100, 160, 100, 50, 0xffffffff, "QUIT", quitGame);
                stateMachine.dispatchEvent("complete");
                break;

            case "init":
                menuLayer.visible = false;

                ingameTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onIngameTimerComplete);
                terrain = new Image(atlas.getTexture("Main_TerrainPng_00000"));
                spaceLayer.addChild(terrain);

                if(NETGAME) {
                    netConnect.connect();
                }

                var player1:Player = new Player();
                player1.team = 0;
                player1.type = "a";
                player1.gold = 1;
                players.push(player1);
                units[player1.team] = new Vector.<UnitView>();

                var player2:Player = new Player();
                player2.team = 1;
                player2.type = "b";
                player2.gold = 1;
                players.push(player2);
                units[player2.team] = new Vector.<UnitView>();

                player1.enemyPlayer = player2;
                player2.enemyPlayer = player1;

                createBuilding(stage.stageWidth / 2, 60, "main", player1);
                createBuilding(stage.stageWidth / 2, stage.stageHeight - 60, "main", player2);

                if (NETGAME) {
                    player1.remote = netConnect.nearId > netConnect.farId ? true : false;
                    player2.remote = netConnect.nearId > netConnect.farId ? false : true;
                    player1.npc = NPC_PLAYER;
                    player2.npc = NPC_OPONENT;
                } else {
                    player1.npc = NPC_PLAYER;
                    player2.npc = NPC_OPONENT;
                }

                stateMachine.dispatchEvent("complete");
                break;

            default:


                logicCounter += FPS_LOGIC;

                if(logicCounter < FPS_GRAPHICS) {
                    for each(var _units:Vector.<UnitView> in units){
                        for each(var unit:UnitView in _units) {
                            unit.owner.x += unit.owner.velX;
                            unit.owner.y += unit.owner.velY;
                        }
                    }
                } else {
                    logicCounter = 0;

                    var timeStep:Number = 1000 / FPS_LOGIC;

                    for each(var timer:CustomTimer in CustomTimer.instances) {
                        timer.update(timeStep);
                    }


                    var unit:UnitView;
                    var unitsLength:int;
                    for each(var _units:Vector.<UnitView> in units){
                        unitsLength = _units.length;
                        for(var i:int = 0; i < unitsLength; i++){
                            unit = _units[i];
                            if (stateMachine.state == "ingame") {
                                unit.owner.update(timeStep);
                                if (unit.owner.dead) {
                                    if (unit.owner.type == "main") {
                                        ingameTimer.stop();
                                        stateMachine.dispatchEvent("finish");
                                    }
                                    Utils.deleteUnitView(_units, i);
                                    if(unit.owner.parent){
                                        unit.owner.parent.removeChild(unit.owner);
                                    }

                                    unitsLength--;
                                    unit.view.parent.removeChild(unit.view);
                                }
                            }
                            unit.view.x = unit.owner.x;
                            unit.view.y = unit.owner.y;
                        }
                    }
                    for each(var player:Player in players) {
                        player.update();
                    }
                    if (stateMachine.state == "ingame") {
                        if (!ingameTimer.running) {
                            ingameTimer.duration += 1000;
                            ingameTimer.start();
                        }
                    }
                }

                break;
        }
    }

    private function getUnitImageByType(type:String, player:Player):Sprite{
        var unitImg:Sprite = new Sprite();
        var image:Image;
        switch(type){
            case "main":
                image = new Image(atlas.getTexture(player.type == "a" ? "Main_DPng_00000" : "Main_DPng_00000"));
                image.scaleX = 1.5;
                image.scaleY = 1.5;
                break;
            case "spawner":
                image = new Image(atlas.getTexture(player.type == "a" ? "Main_CPng_00000" : "Main_CPng_00000"));
                image.scaleX = 1;
                image.scaleY = 1;
                break;
            case "unit":
                image = new Image(atlas.getTexture(player.type == "a" ? "Main_APng_00000" : "Main_BPng_00000"));
                image.scaleX = .5;
                image.scaleY = .5;
                break;
            case "heavySpawner":
                image = new Image(atlas.getTexture(player.type == "a" ? "Main_CPng_00000" : "Main_CPng_00000"));
                image.scaleX = 1.25;
                image.scaleY = 1.25;
                break;
            case "heavyUnit":
                image = new Image(atlas.getTexture(player.type == "a" ? "Main_APng_00000" : "Main_BPng_00000"));
                image.scaleX = .75;
                image.scaleY = .75;
                break;
        }
        image.x =  - image.width / 2;
        image.y =  - image.height / 2;
        unitImg.addChild(image);
        return unitImg;
    }

    public function createPlaceView(x:Number, y:Number, type:String, player:Player):UnitView{
        var unitImg:Sprite = getUnitImageByType(type, player);
        unitImg.alpha = .5;
        unitImg.x = x;
        unitImg.y = y;
        placeBuildingLayer.addChild(unitImg);
        var unitView:UnitView = new UnitView(null, unitImg);
        return unitView;
    }

    public function passTurn(){
        stateMachine.dispatchEvent("passed");
        netConnect.sendMessage({action:"passTurn"});
    }

    public function drawFromBuildingLine(unit:UnitView, x:Number, y:Number):void{
        unit.lines.graphics.lineTo(x - unit.owner.x, y - unit.owner.y);
        unit.owner.path.push(new Point(x,y));
        if(!unit.owner.player.remote) {
            netConnect.sendMessage({action: "lines", id: unit.owner.id, x: x, y: y});
        }

        //lineBmpd.copyPixels(terrainPng.bitmapData, terrainPng.bitmapData.rect, new Point());
        lineBmpd.fillRect(lineBmpd.rect, 0x0);
        for each(var _units:Vector.<UnitView> in units) {
            for each(var unit:UnitView in _units) {
                if(unit.lines){
                    lineBmpd.drawWithQuality(unit.lines, unit.lines.transform.matrix, null, BlendMode.ADD, null, false, StageQuality.BEST);
                }
            }
        }
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), "==", 0x00FF00FF, 0xff00ff00, 0x00ff00ff);
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), ">", 0x00000000, 0xff0000ff, 0x000000ff);
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), ">", 0x00000000, 0xffff0000, 0x00ff0000);
        lineBmpd.applyFilter(lineBmpd, lineBmpd.rect, new Point(), new BlurFilter(12, 12, BitmapFilterQuality.HIGH));
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), "<=", 0x88000000, 0x00000000, 0xff000000);
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), ">", 0x00005500, 0xff00ff00, 0x0000ff00);
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), ">", 0x00000055, 0xff0000ff, 0x000000ff);
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), ">", 0x00550000, 0xffff0000, 0x00ff0000);
        lineBmpd.threshold(lineBmpd, lineBmpd.rect, new Point(), "==", 0x0000ff00, 0xff9900cc, 0x0000ff00);

        lineBmpd.merge(terrainPng.bitmapData, lineBmpd.rect, new Point(), 0xd0, 0xd0, 0xd0, 0xff)

        terrain.texture.dispose();
        terrain.texture = Texture.fromBitmapData(lineBmpd);
    }

    public function createUIElement(x:Number, y:Number, w:Number, h:Number, color:uint, text:String, callback:Function):UIElementView{
        var element:UIElement = new UIElement();
        element.x = x;
        element.y = y;
        element.w = w;
        element.h = h;
        element.color = color;
        element.text = text;

        var elementView:UIElementView = new UIElementView(element);
        menuLayer.addChild(elementView.view);
        elementView.view.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent){
            var touch:Touch = e.touches[0];
            if(touch.phase == TouchPhase.ENDED){
                callback();
            }
        });
        return elementView;
    }

    public function createBuilding(x:Number, y:Number, type:String, player:Player, parent:Unit = null):UnitView{


        var layer:Sprite;
        var unitImg:Sprite = getUnitImageByType(type, player);
        var unit:Unit = new Unit();
        var unitView:UnitView = new UnitView(unit, unitImg);
        if(parent){
            parent.addChild(unit);
        }
        unit.x = x;
        unit.y = y;
        unit.team = player.team;
        unit.type = type;
        unit.player = player;
        switch(type){
            case "main":
                unit.entityType = "building";
                layer = buildingLayer;
                unit.hp = 100;
                unit.radius = 30;
                player.main = unit;
                break;
            case "spawner":
                unit.entityType = "building";
                var action:Action = new Action(2000);
                action.owner = unit;
                action.unitCreated = "unit";
                unit.actions.push(action);
                layer = buildingLayer;
                unit.maxUnits = 0;
                unit.hp = 10;
                unit.radius = 30;
                unit.mode = "moveAndAttack";
                break;
            case "heavySpawner":
                unit.entityType = "building";
                var action:Action = new Action(3000);
                action.owner = unit;
                action.unitCreated = "heavyUnit";
                unit.actions.push(action);
                layer = buildingLayer;
                unit.maxUnits = 0;
                unit.hp = 10;
                unit.radius = 30;
                unit.mode = "moveAndAttack";
                break;
            case "unit":
                unit.entityType = "unit";
                var behavior:Behavior = new Behavior();
                behavior.unit = unit;
                behavior.init();
                unit.behaviors.push(behavior);
                var action:Action = new Action();
                action.owner = unit;
                action.move = true;
                unit.moveAction = action;
                unit.path = parent.path;
                unit.speed = .75;
                unit.hp = 1;
                unit.radius = 15;
                unit.damage = .01;
                layer = unitLayer;
                break;
            case "heavyUnit":
                unit.entityType = "unit";
                var behavior:Behavior = new Behavior();
                behavior.unit = unit;
                behavior.init();
                unit.behaviors.push(behavior);
                var action:Action = new Action();
                action.owner = unit;
                action.move = true;
                unit.moveAction = action;
                unit.path = parent.path;
                unit.hp = 2;
                unit.speed = .5;
                layer = unitLayer;
                unit.radius = 20;
                unit.damage = .01;
                break;

        }

        switch(unit.entityType){
            case "building":
                unit.id = buildingId++;
                var lines:flash.display.Sprite = new flash.display.Sprite();
                lines.x = unit.x;
                lines.y = unit.y;
                lines.graphics.lineStyle(10, unit.team == 0 ? 0xff0000 : 0x0000ff);
                unitView.lines = lines;
                unit.path = new Array();

                break;
        }

        if(unit.entityType == "building" && type != "main" && !player.remote){
            netConnect.sendMessage({action:"place", x:unit.x, y:unit.y, type:unit.type, team:unit.team});
        }

        unitImg.x = unit.x;
        unitImg.y = unit.y;
        layer.addChild(unitImg);

        unit.init();

        units[unit.team].push(unitView);

        return unitView;
    }
}
}
