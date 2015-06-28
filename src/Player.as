/**
 * Created by leandro on 6/19/2015.
 */
package {
import com.greensock.TweenLite;
import com.greensock.easing.Linear;

import flash.events.TimerEvent;
import flash.geom.Point;
import flash.ui.Keyboard;

public class Player {
    public var enemyPlayer:Player;
    public var main:Unit;
    public var team:int;
    public var gold:int;
    public var type:String;
    public var npc:Boolean;
    public var remote:Boolean;
    private var unitToPutLines:UnitView;
    private var linesToPlace:Array;
    private var buildingSelected:String;
    private var selectedUnit:UnitView;
    private var stateMachine:StateMachine = new StateMachine();

    private var placeTimer:CustomTimer = new CustomTimer(500);
    private var lineTimer:CustomTimer = new CustomTimer(200);

    public function Player() {
        stateMachine.state = "waitingAction";
        stateMachine.defineStateRelation("waitingAction", "placingBuilding", "place");
        stateMachine.defineStateRelation("placingBuilding", "selectingPath", "placed");
        stateMachine.defineStateRelation("selectingPath", "waitingAction", "selected");

        placeTimer.addEventListener(TimerEvent.TIMER, onPlaceTimer);
        lineTimer.addEventListener(TimerEvent.TIMER, onLineTimer);
    }

    public function update():void{
        if(!remote){
            if((Main.instance.stateMachine.state == "turn0" && team == 0) || (Main.instance.stateMachine.state == "turn1" && team == 1)) {
                if(npc) {
                    if (!placeTimer.running && !lineTimer.running) {
                        placeTimer.start();
                    }
                } else {
                    switch(stateMachine.state){
                        case "waitingAction":
                            buildingSelected = null;
                            if (Main.instance.pressedKeys[Keyboard.Q]) {
                                Main.instance.releaseKey(Keyboard.Q);
                                buildingSelected = "spawner";
                            }
                            if (Main.instance.pressedKeys[Keyboard.W]) {
                                Main.instance.releaseKey(Keyboard.W);
                                buildingSelected = "heavySpawner";
                            }
                            if (buildingSelected && gold > 0) {
                                unitToPutLines = Main.instance.createPlaceView(Main.instance.mousePos.x, Main.instance.mousePos.y, buildingSelected, this);
                                stateMachine.dispatchEvent("place");
                            } else if(Main.instance.pressedKeys[Keyboard.ESCAPE]){
                                Main.instance.releaseKey(Keyboard.ESCAPE);
                                placeTimer.stop();
                                Main.instance.passTurn();
                            }
                            break;
                        case "placingBuilding":
                            TweenLite.to(unitToPutLines.view, .15, {x:Main.instance.mousePos.x, y:Main.instance.mousePos.y, ease:Linear.easeNone});
                            if(Main.instance.mousePressed) {
                                Main.instance.releaseMouse();
                                stateMachine.dispatchEvent("placed");
                                selectedUnit = buyBuilding(unitToPutLines.view.x, unitToPutLines.view.y, buildingSelected);
                                unitToPutLines.view.parent.removeChild(unitToPutLines.view);
                            }
                            break;
                        case "selectingPath":
                            if (Main.instance.pressedKeys[Keyboard.SPACE]) {
                                Main.instance.releaseKey(Keyboard.SPACE);
                                Main.instance.drawFromBuildingLine(selectedUnit, Main.instance.mousePos.x, Main.instance.mousePos.y);
                            }
                            if (Main.instance.pressedKeys[Keyboard.ENTER]) {
                                Main.instance.releaseKey(Keyboard.ENTER);
                                stateMachine.dispatchEvent("selected");
                            }
                            break;
                    }
                }
            }
        }
    }

    private function onPlaceMoveComplete():void{
        var unit:UnitView;
        unit = buyBuilding(unitToPutLines.view.x, unitToPutLines.view.y, buildingSelected);
        if(Math.random() < .3){
            unit.owner.mode = "moveOnly";
        }

        unitToPutLines.view.parent.removeChild(unitToPutLines.view);
        if(unit){

            var mainPos:Point;
            for each(var otherUnit:UnitView in Main.instance.units[team == 0 ? 1 : 0]){
                if(otherUnit.owner.type == "main" && otherUnit.owner.team != team){
                    mainPos = new Point(otherUnit.owner.x, otherUnit.owner.y);
                    break;
                }
            }
            if(mainPos){
                linesToPlace = unit.owner.curvePath([mainPos]);
                placeTimer.stop();
                lineTimer.start();
                unitToPutLines = unit;
            }

        }
    }

    private function onPlaceTimer(e:TimerEvent):void{
        var buttonPressed:int = 2 * Math.random();

        buildingSelected = ["spawner", "heavySpawner"][buttonPressed];

        if (gold <= 0) {
            placeTimer.stop();
            Main.instance.passTurn();
        } else {
            if (team == 0) {
                unitToPutLines = Main.instance.createPlaceView(Main.instance.stage.stageWidth * Math.random(), 25 + ((Main.instance.stage.stageHeight / 2) - 50) * Math.random(), buildingSelected, this);
                TweenLite.to(unitToPutLines.view, placeTimer.duration/2000, {x:Main.instance.stage.stageWidth * Math.random(), y:25 + ((Main.instance.stage.stageHeight / 2) - 50) * Math.random(), onComplete:onPlaceMoveComplete});
            } else {
                unitToPutLines = Main.instance.createPlaceView(Main.instance.stage.stageWidth * Math.random(), Main.instance.stage.stageHeight - 25 - ((Main.instance.stage.stageHeight / 2) - 50) * Math.random(), buildingSelected, this);
                TweenLite.to(unitToPutLines.view, placeTimer.duration/2000, {x:Main.instance.stage.stageWidth * Math.random(), y:Main.instance.stage.stageHeight - 25 - ((Main.instance.stage.stageHeight / 2) - 50) * Math.random(), onComplete:onPlaceMoveComplete});
            }
        }
    }

    private function onLineTimer(e:TimerEvent):void{
        if(linesToPlace.length > 0) {
            var currentPathPoint:Point = linesToPlace.shift();
            Main.instance.drawFromBuildingLine(unitToPutLines, currentPathPoint.x, currentPathPoint.y);
        } else {
            lineTimer.stop();
            placeTimer.start();
        }
    }

    private function buyBuilding(x:Number, y:Number, type:String):UnitView{
        if(gold >= 1){
            gold--;
            return Main.instance.createBuilding(x, y, type, this);
        }
        return null;
    }
}
}
