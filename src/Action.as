/**
 * Created by leandro on 6/19/2015.
 */
package {
import flash.geom.Point;

public class Action {

    public var owner:Unit;
    public var unitCreated:String;
    public var move:Boolean;
    public var damage:Boolean;
    public var cooldown:int = 0;
    public var attack:Boolean;

    private var cooldownTimer:CustomTimer;

    public function Action(cooldown:int = 0) {
        this.cooldown = cooldown;
        if(cooldown > 0) {
            cooldownTimer = new CustomTimer(cooldown, 1, false);
        }
    }

    public function update(time:Number):void{
        if(cooldownTimer) {
            cooldownTimer.update(time);
        }
    }

    public function runPoint(point:Point):void{
        if(!cooldownTimer || !cooldownTimer.running) {
            if(move){
                var distance:Point = new Point(point.x - owner.x, point.y - owner.y);
                if(distance.length <= owner.speed){
                    distance.normalize(owner.speed);
                    owner.x = point.x;
                    owner.y = point.y;
                } else {
                    distance.normalize(owner.speed);
                    owner.x += distance.x;
                    owner.y += distance.y;
                }
                owner.velX = distance.x;
                owner.velY = distance.y;
                owner.rotation = getAngle(0, 0, distance.x, distance.y);
            }
        }
    }

    public function runUnit(unit:Unit):void{
        if(!cooldownTimer || !cooldownTimer.running) {
            if(damage){
                unit.hp -= owner.damage;
                if (unit.hp <= 0) {
                    unit.dead = true;
                }
                if(owner.aoe){
                    for each(var unitView:UnitView in Main.instance.units[unit.player.team]) {
                        if (!unitView.owner.dead && unitView.owner != unit) {
                            if (Point.distance(new Point(owner.x, owner.y), new Point(unitView.owner.x, unitView.owner.y)) <= owner.aoe) {
                                unitView.owner.hp -= owner.damage;
                                if (unitView.owner.hp <= 0) {
                                    unitView.owner.dead = true;
                                }
                            }
                        }
                    }
                }
            }
            if(cooldownTimer){
                cooldownTimer.start();
            }
        }
    }

    public function getAngle (x1:Number, y1:Number, x2:Number, y2:Number):Number
    {
        var dx:Number = x2 - x1;
        var dy:Number = y2 - y1;
        return Math.atan2(dy,dx);
    }

    public function run():void{
        if(!cooldownTimer || !cooldownTimer.running){
            if(unitCreated){
                if(owner.squadronPoints) {
                    if (owner.maxUnits == 0 || owner.unitsCreated < owner.maxUnits) {
                        for (var i:int = 0; i < owner.squadronPoints.length; i++) {
                            var unit:UnitView = Main.instance.createBuilding(owner.x, owner.y, unitCreated, owner.player, owner);
                            unit.owner.squadronPos = i;
                        }
                    }
                } else {
                    Main.instance.createBuilding(owner.x, owner.y, unitCreated, owner.player, owner);
                }
                owner.unitsCreated++;
            }
            if(cooldownTimer){
                cooldownTimer.start();
            }
        }
    }
}
}
