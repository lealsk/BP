/**
 * Created by leandro on 6/19/2015.
 */
package {
import flash.geom.Point;

public class Action {

    public var owner:Unit;
    public var unitCreated:String;
    public var move:Boolean;
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
                distance.normalize(owner.speed);
                owner.x += distance.x;
                owner.y += distance.y;
                owner.velX = distance.x;
                owner.velY = distance.y;
            }
        }
    }

    public function run():void{
        if(!cooldownTimer || !cooldownTimer.running){
            if(unitCreated){
                if(owner.maxUnits == 0 || owner.unitsCreated < owner.maxUnits) {
                    Main.instance.createBuilding(owner.x, owner.y, unitCreated, owner.player, owner);
                    owner.unitsCreated++;
                }
            }
            if(cooldownTimer){
                cooldownTimer.start();
            }
        }
    }
}
}
