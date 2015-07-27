package {

import com.emibap.textureAtlas.DynamicAtlas;
import com.greensock.TweenLite;

import flash.desktop.NativeApplication;

import flash.display.Bitmap;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.display.Sprite;

import flash.display.Sprite;
import flash.display.StageQuality;
import flash.filters.BitmapFilterQuality;
import flash.filters.BlurFilter;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Rectangle;

import org.osmf.elements.HTMLElement;

import starling.core.Starling;

import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import flash.events.TimerEvent;
import flash.geom.Point;

import starling.events.KeyboardEvent;

import starling.events.Touch;

import starling.events.TouchEvent;
import starling.events.TouchPhase;

import starling.textures.Texture;
import starling.textures.TextureAtlas;

public class Main extends Sprite {

    public static const ORIENTATION:String = "topDown";
    //public static const ORIENTATION:String = "leftRight";

    public static const STAGE_WIDTH:Number = 800;
    public static const STAGE_HEIGHT:Number = 600;

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

    [Embed(source="../assets/u1.png")]
    public static var U1Png:Class;
    [Embed(source="../assets/u2.png")]
    public static var U2Png:Class;
    [Embed(source="../assets/u3.png")]
    public static var U3Png:Class;
    [Embed(source="../assets/u4.png")]
    public static var U4Png:Class;
    [Embed(source="../assets/u5.png")]
    public static var U5Png:Class;
    [Embed(source="../assets/u6.png")]
    public static var U6Png:Class;
    [Embed(source="../assets/u7.png")]
    public static var U7Png:Class;

    private var terrainPng:Bitmap = new (ORIENTATION == "topDown" ? TerrainPng : TerrainPng)();
    
    public static var assetClasses:Vector.<Class> = new <Class>[ORIENTATION == "topDown" ? TerrainPng : TerrainPng, APng, BPng, CPng, DPng, U1Png, U2Png, U3Png, U4Png, U5Png, U6Png, U7Png];

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
        var terrainBmpd:BitmapData = new BitmapData(STAGE_WIDTH, STAGE_HEIGHT, false);
        var matrix:Matrix = new Matrix();
        matrix.scale(STAGE_WIDTH/terrainPng.width, STAGE_HEIGHT/terrainPng.height);
        terrainBmpd.draw(terrainPng, matrix, null, null, null, true);
        terrainPng.bitmapData = terrainBmpd;

        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        stateMachine.state = "initMenues";
        stateMachine.defineStateRelation("initMenues", "mainMenu", "complete");
        stateMachine.defineStateRelation("mainMenu", "quit", "quit");

        if(NETGAME){
            stateMachine.state = "connect";
            stateMachine.defineStateRelation("mainMenu", "connect", "start");
            stateMachine.defineStateRelation("connect", "connecting", "next");
            stateMachine.defineStateRelation("connecting", "waitingForPlayers", "complete");
            stateMachine.defineStateRelation("waitingForPlayers", "init", "complete");
        } else {
            stateMachine.state = "init";
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

        //stateMachine.state = "test";
    }

    private function onAddedToStage(e:Event):void{

        instance = this;

        atlas = DynamicAtlas.fromClassVector(assetClasses);
        lineBmpd = new BitmapData(STAGE_WIDTH, STAGE_HEIGHT, true, 0x0);

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
            for each(var unitView:UnitView in units[player.team]) {
                player.gold += unitView.owner.income;
            }
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

    private function test():void{

    }

    private function onEnterFrame(e:Event):void{

        switch(stateMachine.state){
            case "test":
                test();
                stateMachine.state = "none";
                break;

            case "initMenues":
                createUIElement(100, 200, 100, 50, 0xffffffff, "PLAY", startGame, menuLayer);
                createUIElement(100, 260, 100, 50, 0xffffffff, "QUIT", quitGame, menuLayer);
                stateMachine.dispatchEvent("complete");
                break;

            case "connect":
                netConnect.connect();
                stateMachine.dispatchEvent("next");
                break;

            case "init":

                menuLayer.visible = false;

                ingameTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onIngameTimerComplete);
                terrain = new Image(Texture.fromColor(STAGE_WIDTH, STAGE_HEIGHT, 0x100617));
                spaceLayer.addChild(terrain);

                var player1:Player = new Player();
                player1.team = 0;
                player1.type = "a";
                player1.hud = createUIElement(STAGE_WIDTH - 101, 1, 100, 50, 0x55555555, "gold: 0", null, placeBuildingLayer);
                player1.gold = 10;
                players.push(player1);
                units[player1.team] = new Vector.<UnitView>();

                var player2:Player = new Player();
                player2.team = 1;
                player2.type = "b";
                player2.hud = createUIElement(1, STAGE_HEIGHT - 51, 100, 50, 0x55555555, "gold: 0", null, placeBuildingLayer);
                player2.gold = 10;
                players.push(player2);
                units[player2.team] = new Vector.<UnitView>();

                player1.enemyPlayer = player2;
                player2.enemyPlayer = player1;


                switch(ORIENTATION){
                    case "topDown":
                        createBuilding(STAGE_WIDTH / 2, 60, "main", player1);
                        createBuilding(STAGE_WIDTH / 2, STAGE_HEIGHT - 60, "main", player2);
                        break;
                    case "leftRight":
                        createBuilding(60, STAGE_HEIGHT / 2, "main", player1);
                        createBuilding(STAGE_WIDTH - 60, STAGE_HEIGHT / 2, "main", player2);
                        break;
                }

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

                for each(var player:Player in players){
                    var newText:String = "gold: " + player.gold.toString();
                    if(newText != player.hud.textField.text) {
                        player.hud.textField.text = newText;
                    }
                }

                logicCounter += FPS_LOGIC;

                if(logicCounter < FPS_GRAPHICS) {
                    for each(var _units:Vector.<UnitView> in units){
                        for each(var unit:UnitView in _units) {
                            unit.owner.x += unit.owner.velX;
                            unit.owner.y += unit.owner.velY;
                        }
                    }
                } else {

                    for each(var _units:Vector.<UnitView> in units){
                        for each(var unit:UnitView in _units) {
                            if(unit.view) {
                                if (stateMachine.state == "turn0" && unit.owner.team == 1) {
                                    if (unit.view.alpha != .3) unit.view.alpha = .3;
                                } else if (stateMachine.state == "turn1" && unit.owner.team == 0) {
                                    if (unit.view.alpha != .3) unit.view.alpha = .3;
                                } else if (stateMachine.state == "ingame" || !unit.owner.player.remote) {
                                    if (unit.view.alpha != 1) unit.view.alpha = 1;
                                } else {
                                    if (unit.view.alpha != .3) unit.view.alpha = .3;
                                }
                            }
                        }
                    }

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
                                    if(unit.view) {
                                        unit.view.parent.removeChild(unit.view);
                                    }
                                }
                            }
                            if(unit.view) {
                                unit.view.x = unit.owner.x;
                                unit.view.y = unit.owner.y;
                                unit.view.rotation = unit.owner.rotation + Math.PI / 2;
                            }
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

    private function getImageByName(name:String, scaleX:Number, scaleY:Number, color:uint):Sprite{

        var unitImg:Sprite = new Sprite();
        var image:Image;
        image = new Image(atlas.getTexture(name));
        image.scaleX = scaleX;
        image.scaleY = scaleY;
        if(image) {
            image.x = -image.width / 2;
            image.y = -image.height / 2;
            unitImg.addChild(image);
            image.color = color;
            return unitImg;
        } else {
            return null;
        }
    }

    private function getUnitImageByType(type:String, player:Player, data:Object):Sprite{
        var image:Sprite;
        var color:uint;
        if (player.team == 0) {
            color = 0xffff0000;
        } else {
            color = 0xff00ff00;
        }
        image = getImageByName("Main_"+data.asset+"_00000", data.scaleX, data.scaleY, color);

        return image;
    }

    public function createPlaceView(x:Number, y:Number, type:String, player:Player):UnitView{
        var unitImg:Sprite = getUnitImageByType(type, player, Utils.getDefinitionByType(type));
        unitImg.alpha = .5;
        unitImg.x = x;
        unitImg.y = y;
        if(player.team){
            unitImg.rotation = 0;
        } else {
            unitImg.rotation = Math.PI;
        }
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

    public function createUIElement(x:Number, y:Number, w:Number, h:Number, color:uint, text:String, callback:Function, layer:Sprite):UIElementView{
        var element:UIElement = new UIElement();
        element.x = x;
        element.y = y;
        element.w = w;
        element.h = h;
        element.color = color;
        element.text = text;

        var elementView:UIElementView = new UIElementView(element);
        layer.addChild(elementView.view);
        elementView.view.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent){
            var touch:Touch = e.touches[0];
            if(touch.phase == TouchPhase.ENDED){
                callback();
            }
        });
        return elementView;
    }

    private function getLayerByEntityType(entityType:String):Sprite{
        switch(entityType){
            case "building":
                return buildingLayer;
            case "unit":
                return unitLayer;
        }
        return null;
    }

    public function createBuilding(x:Number, y:Number, type:String, player:Player, parent:Unit = null):UnitView{

        var data:Object = Utils.getDefinitionByType(type);
        var layer:Sprite;
        var unitImg:Sprite = getUnitImageByType(type, player, data);
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

        unit.hp = data.hp;
        unit.radius = data.radius;
        unit.range = data.range;
        unit.speed = data.speed;
        unit.damage = data.damage;
        unit.aoe = data.aoe;
        unit.entityType = data.entityType;
        unit.maxUnits = data.maxUnits;
        unit.income = data.income;

        if(player.team){
            unit.rotation = -Math.PI / 2;
        } else {
            unit.rotation = Math.PI / 2;
        }

        layer = getLayerByEntityType(unit.entityType);

        for each(var act:String in data.actions){
            var actionData:Object = Utils.getDefinitionByType(act);
            var action:Action = new Action(actionData.cooldown);
            action.owner = unit;
            if(actionData.hasOwnProperty("unitSummoned")){
                action.unitCreated = actionData.unitSummoned;
            }
            unit.actions.push(action);
        }

        var behavior:Behavior = new Behavior();
        if(unit.speed > 0){
            behavior = new Behavior();
            behavior.unit = unit;
            behavior.init("followPath");
            var action:Action = new Action();
            action.owner = unit;
            action.move = true;
            unit.moveAction = action;
            unit.path = parent.path;
        }
        if(data.hasOwnProperty("damage") && data.hasOwnProperty("attackCooldown")){
            if(!behavior){
                behavior = new Behavior();
                behavior.unit = unit;
                behavior.init("wait");
            }
            var action:Action = new Action(data.attackCooldown);
            action.owner = unit;
            action.damage = true;
            unit.attackAction = action;
            unit.mode = "moveAndAttack";
        }
        if(behavior){
            unit.behaviors.push(behavior);
        }
        switch(type){
            case "main":
                player.main = unit;
                break;
            /*case "spawner":
                unit.squadronCounts = [4,2,2];
                var action:Action = new Action(5000);
                action.owner = unit;
                action.unitCreated = "squadron";
                unit.actions.push(action);
                unit.mode = "moveAndAttack";
                break;*/
            case "squadron":

                var action:Action = new Action(5000);
                action.owner = unit;
                action.unitCreated = "unit";
                unit.actions.push(action);

                var behavior:Behavior = new Behavior();
                behavior.unit = unit;
                behavior.init("followPath");
                unit.behaviors.push(behavior);
                var action:Action = new Action();
                action.owner = unit;
                action.move = true;
                unit.moveAction = action;
                unit.path = parent.path;

                unit.squadronPoints = unit.buildPointsByCounts(unit.parent.squadronCounts);

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

        if(unitImg) {
            unitImg.x = unit.x;
            unitImg.y = unit.y;
            layer.addChild(unitImg);
        }

        unit.init();

        units[unit.team].push(unitView);

        return unitView;
    }
}
}
