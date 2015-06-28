/**
 * Created by leandro on 6/19/2015.
 */
package {

import flash.geom.Point;

public class Unit {
    public var parent:Unit;
    public var children:Vector.<Unit>;
    public var x:Number=0;
    public var y:Number=0;
    public var dead:Boolean = false;
    public var entityType:String;
    public var type:String;
    public var team:int;
    public var actions:Array = new Array();
    public var path:Array;
    public var unitsCreated:int = 0;
    public var maxUnits:int = 0;
    public var speed:Number;
    public var hp:Number = 1;
    public var radius:Number;
    public var player:Player;
    public var id:int;
    public var velX:Number = 0;
    public var velY:Number = 0;
    public var moveAction:Action;
    public var behaviors:Array = new Array();
    public var damage:Number = 0;
    public var currentPathPoint:int = 0;

    private var _mode:String;

    protected function getParentMode():String{
        if(!_mode){
            if(parent) {
                return parent.getParentMode();
            }
        }
        return _mode;
    }

    public function get mode():String{
        return _mode;
    }

    public function set mode(value:String):void{
        _mode = value;
        if(children) {
            for each(var unit:Unit in children) {
                unit.mode = value;
            }
        }
    }

    public function addChild(unit:Unit):void{
        if(!children){
            children = new Vector.<Unit>();
        }
        children.push(unit);
        unit.parent = this;
    }

    public function removeChild(unit:Unit):void{
        Utils.deleteUnit(children, children.indexOf(unit));
        unit.parent = null;
    }

    public function Unit() {
    }

    public function init():void{
        _mode = getParentMode();
    }

    public function update(time:Number){
        if(!dead) {
            for each(var action:Action in actions){
                action.update(time);
                action.run();
            }

            for each(var behavior:Behavior in behaviors){
                behavior.update(time);
            }
/*
            if(maxUnits > 0 && unitsCreated >= maxUnits){
                if (type == "spawner" && Math.random() < .2) {
                    var destruct:Boolean = true;
                    for each(var unit:UnitView in Main.instance.units) {
                        if (unit.owner.parent == this) {
                            destruct = false;
                            break;
                        }
                    }
                    if(destruct) {
                        //dead = true;
                    }
                }
            }*/

/*if(!dontTween && speed > 0*//* && TweenLite.getTweensOf(this).length == 0*//*)
            TweenLite.to(this, .5, {x:targetPosition.x, y:targetPosition.y});*/
        }
    }

    public function curvePath(path:Array):Array{
        var startX:Number =x;
        var startY:Number=y;

        var endX:Number=path[path.length-1].x;
        var endY:Number=path[path.length-1].y;

        var bezierX:Number=100+Math.random()*100;
        var bezierY:Number=100+Math.random()*100;

        var newPath:Array = new Array();
        for(var t:Number=0;t<=1;t+=0.2)
        {
            var newX:Number = (1-t)*(1-t)*startX + 2*(1-t)*t*bezierX+t*t*endX + Math.sin(t*10) *20;
            var newY:Number = (1-t)*(1-t)*startY + 2*(1-t)*t*bezierY+t*t*endY;

            newPath.push(new Point(newX, newY));
        }

        return newPath;
    }
}
}