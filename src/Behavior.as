/**
 * Created by leandro on 6/28/2015.
 */
package {
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Point;

public class Behavior {

    private var stateMachine:StateMachine = new StateMachine();
    public var unit:Unit;

    public function Behavior() {

    }

    public function init(mode:String):void{
        switch(mode){
            case "wait":
                stateMachine.state = "waiting";
                stateMachine.defineStateRelation("waiting", "attackingEnemy", "enemyAtRange");
                stateMachine.defineStateRelation("attackingEnemy", "waiting", "enemyDestroyed");
                break;
            case "followPath":
                stateMachine.state = "followingPath";
                stateMachine.defineStateRelation("followingPath", "attackingEnemy", "enemyAtRange");
                stateMachine.defineStateRelation("attackingEnemy", "followingPath", "enemyDestroyed");
                break;
            case "followSquadron":
                stateMachine.state = "followingSquadron";
                stateMachine.defineStateRelation("followingSquadron", "attackingEnemy", "enemyAtRange");
                stateMachine.defineStateRelation("attackingEnemy", "followingSquadron", "enemyDestroyed");
                break;
        }
    }

    private function attackNearestUnit(unit:Unit):void{
        for each(var unitView:UnitView in Main.instance.units[unit.player.enemyPlayer.team]) {
            if (!unitView.owner.dead) {
                if (Point.distance(new Point(unit.x, unit.y), new Point(unitView.owner.x, unitView.owner.y)) < unit.radius + unitView.owner.radius + unit.range) {
                    stateMachine.dispatchEventWithParam("enemyAtRange", unitView.owner);
                    break;
                }
            }
        }
    }

    private function attackUnit(unit:Unit, target:Unit):void{
        if(unit.currentPathPoint == unit.path.length - 1) {
            if (Point.distance(new Point(unit.x, unit.y), new Point(target.x, target.y)) < unit.radius + target.radius) {
                stateMachine.dispatchEventWithParam("enemyAtRange", target);
            }
        }
    }

    public function update(time:Number):void{
        switch(stateMachine.state){
            case "waiting":
                attackNearestUnit(unit);
                break;
            case "followingPath":
                if(unit.path && unit.speed > 0) {
                    var destination:Point = unit.path[unit.currentPathPoint];
                    var distance:Point = new Point(destination.x - unit.x, destination.y - unit.y);
                    if(distance.length < 10){
                        if(unit.currentPathPoint < unit.path.length - 1) {
                            unit.currentPathPoint++;
                        }
                    }
                    unit.moveAction.runPoint(destination);
                }

                if(unit.mode == "moveAndAttack") {
                    attackNearestUnit(unit);
                } else if(unit.mode == "moveOnly"){
                    attackUnit(unit, unit.player.enemyPlayer.main);
                }
                break;
            case "followingSquadron":
                if(unit.speed > 0) {
                    var matrix:Matrix = new Matrix();
                    var p:Point = unit.parent.squadronPoints[unit.squadronPos].clone();
                    matrix.rotate(unit.parent.rotation + Math.PI / 2);
                    p = matrix.transformPoint(p);

                    unit.moveAction.runPoint(new Point(unit.parent.x + p.x, unit.parent.y + p.y));

                }
                break;
            case "attackingEnemy":
                var enemy:Unit = stateMachine.eventParam as Unit;
                if (Point.distance(new Point(unit.x, unit.y), new Point(enemy.x, enemy.y)) < unit.radius + enemy.radius + unit.range) {
                    unit.attackAction.runUnit(enemy);
                } else {
                    stateMachine.dispatchEvent("enemyDestroyed");
                }
                if (enemy.dead) {
                    stateMachine.dispatchEvent("enemyDestroyed");
                }
                break;
        }

    }
}
}
