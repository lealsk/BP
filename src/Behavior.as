/**
 * Created by leandro on 6/28/2015.
 */
package {
import flash.geom.Point;

public class Behavior {

    private var stateMachine:StateMachine = new StateMachine();
    public var unit:Unit;

    public function Behavior() {

    }

    public function init():void{
        stateMachine.state = "goingToDestination";
        stateMachine.defineStateRelation("goingToDestination", "attackingEnemy", "enemyAtRange");
        stateMachine.defineStateRelation("attackingEnemy", "goingToDestination", "enemyDestroyed");
    }

    public function update(time:Number):void{
        switch(stateMachine.state){
            case "goingToDestination":
                if(unit.path && unit.speed > 0) {
                    var destination:Point = unit.path[unit.currentPathPoint];
                    var distance:Point = new Point(destination.x - unit.x, destination.y - unit.y);
                    if(distance.length < 10){
                        if(unit.currentPathPoint < unit.path.length - 1) {
                            unit.currentPathPoint++;
                        }
                    }
                    unit.moveAction.runPoint(destination);

                    if(unit.mode == "moveAndAttack") {
                        for each(var unitView:UnitView in Main.instance.units[unit.player.enemyPlayer.team]) {
                            if (!unitView.owner.dead) {
                                if (Point.distance(new Point(unit.x, unit.y), new Point(unitView.owner.x, unitView.owner.y)) < unit.radius + unitView.owner.radius) {
                                    stateMachine.dispatchEventWithParam("enemyAtRange", unitView.owner);
                                    break;
                                }
                            }
                        }
                    } else if(unit.mode == "moveOnly"){
                        if(unit.currentPathPoint == unit.path.length - 1) {
                            if (Point.distance(new Point(unit.x, unit.y), new Point(unit.player.enemyPlayer.main.x, unit.player.enemyPlayer.main.y)) < unit.radius + unit.player.enemyPlayer.main.radius) {
                                stateMachine.dispatchEventWithParam("enemyAtRange", unit.player.enemyPlayer.main);
                            }
                        }
                    }
                }
                break;
            case "attackingEnemy":
                var enemy:Unit = stateMachine.eventParam as Unit;
                enemy.hp -= unit.damage;
                unit.hp -= enemy.damage;
                if (enemy.hp <= 0) {
                    enemy.dead = true;
                    stateMachine.dispatchEvent("enemyDestroyed");
                }
                if (unit.hp <= 0) {
                    unit.dead = true;
                }
                break;
        }
    }
}
}
